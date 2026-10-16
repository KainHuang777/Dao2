import http from 'node:http';
import fs from 'node:fs';
const driverEnv = typeof process === 'undefined' ? {} : process.env;

export const sleep = ms => new Promise(r => setTimeout(r, ms));

export function httpJson(cdpPort, requestPath, timeoutMs = 8000) {
  return new Promise((resolve, reject) => {
    const req = http.request({ host: '127.0.0.1', port: cdpPort, path: requestPath, method: 'GET' }, res => {
      let data = '';
      res.on('data', d => data += d);
      res.on('end', () => { try { resolve(JSON.parse(data)); } catch (e) { reject(e); } });
    });
    req.on('error', reject);
    req.setTimeout(timeoutMs, () => req.destroy(new Error('http timeout ' + requestPath)));
    req.end();
  });
}

export function wsConnect(url) {
  return new Promise((resolve, reject) => {
    if (typeof WebSocket === 'undefined') {
      reject(new Error('global WebSocket missing; run with node --experimental-websocket (Node 21+, stable 22+)'));
      return;
    }
    const ws = new WebSocket(url);
    ws.addEventListener('open', () => resolve(ws), { once: true });
    ws.addEventListener('error', () => reject(new Error('ws connect error ' + url)), { once: true });
  });
}

export async function connectDriver(options = {}) {
  const cdpPort = options.cdpPort ?? Number(driverEnv.CDP_PORT || 9225);
  const namespace = options.namespace || driverEnv.SAVE_NAMESPACE || 'dao2_saves';
  const baseW = options.baseW || 1280;
  const baseH = options.baseH || 720;
  const debug = options.debugPrinter || (() => {});
  const version = await httpJson(cdpPort, '/json/version');
  const targets = await httpJson(cdpPort, '/json/list');
  const candidates = targets.filter(t => t.type === 'page' && t.webSocketDebuggerUrl);
  const matchPort = options.matchPort || driverEnv.HTTP_PORT || '';
  const page = (matchPort && candidates.find(t => t.url.includes(':' + matchPort))) || candidates[0];
  if (!page) {
    throw new Error('no page target; targets=' + JSON.stringify(targets.map(t => t.type + ' ' + t.url)));
  }
  const ws = await wsConnect(page.webSocketDebuggerUrl);
  let msgId = 0;
  const pending = new Map();
  const consoleListeners = [];
  const consoleLines = [];

  function send(wsTarget, method, params = {}) {
    const wsUse = wsTarget || ws;
    const id = ++msgId;
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        pending.delete(id);
        reject(new Error('CDP timeout: ' + method));
      }, 15000);
      pending.set(id, {
        resolve: value => { clearTimeout(timer); resolve(value); },
        reject: error => { clearTimeout(timer); reject(error); }, method
      });
      wsUse.send(JSON.stringify({ id, method, params }));
    });
  }

  ws.addEventListener('message', ev => {
    try {
      const m = JSON.parse(ev.data);
      if (m.id && pending.has(m.id)) {
        const p = pending.get(m.id);
        pending.delete(m.id);
        if (m.error) p.reject(new Error(p.method + ': ' + JSON.stringify(m.error)));
        else p.resolve(m.result);
      } else if (!m.id && m.method === 'Runtime.consoleAPICalled') {
        const text = (m.params.args || []).map(a => a.value != null ? String(a.value) : (a.description || '')).join(' ');
        if (text.trim()) {
          const line = { utc: new Date().toISOString(), text: text.slice(0, 500) };
          consoleLines.push(line);
          for (const cb of consoleListeners) { try { cb(line); } catch {} }
        }
      }
    } catch {}
  });

  await send(null, 'Page.enable');
  await send(null, 'Runtime.enable');
  const viewWidth = driverEnv.VIEW_W ? Number(driverEnv.VIEW_W) : 0;
  const viewHeight = driverEnv.VIEW_H ? Number(driverEnv.VIEW_H) : 0;
  if (viewWidth > 0 && viewHeight > 0) {
    await send(null, 'Emulation.setDeviceMetricsOverride', {
      width: viewWidth, height: viewHeight, deviceScaleFactor: Number(driverEnv.VIEW_DPR || 1), mobile: false
    });
  }
  const evaluate = async expression => {
    const r = await send(null, 'Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true });
    if (r.exceptionDetails) throw new Error('page eval error: ' + JSON.stringify(r.exceptionDetails).slice(0, 800));
    return r.result.value;
  };

  async function geo() {
    const rect = await evaluate(`(()=>{const c=document.querySelector('canvas');if(!c)return null;const r=c.getBoundingClientRect();return {left:r.left,top:r.top,width:r.width,height:r.height,dpr:window.devicePixelRatio,vw:window.innerWidth,vh:window.innerHeight,scrollX:window.scrollX,scrollY:window.scrollY};})()`);
    if (!rect) throw new Error('no canvas element in page');
    if (rect.height <= 500) {
      throw new Error('canvas CSS height ' + rect.height + ' switches Godot content base to 640x360; driver only derives wide-mode 1280x720 waypoints. Resize viewport and rerun.');
    }
    const scale = Math.min(rect.width / baseW, rect.height / baseH);
    if (!(scale > 0)) throw new Error('invalid canvas scale ' + JSON.stringify(rect));
    return { rect, scale, now: Date.now() };
  }

  function toViewport(point, g) {
    const x = g.rect.left + point.x * g.scale;
    const y = g.rect.top + point.y * g.scale;
    if (!(x >= 0 && y >= 0 && x <= g.rect.left + g.rect.width && y <= g.rect.top + g.rect.height)) {
      throw new Error('waypoint outside canvas: ' + JSON.stringify(point) + ' geo=' + JSON.stringify(g.rect));
    }
    return { x, y };
  }

  const api = {
    cdpPort,
    pageId: page.id,
    pageUrl: page.url,
    consoleLines,
    onConsoleLine(cb) { consoleListeners.push(cb); },
    send(method, params) { return send(null, method, params); },
    evaluate,
    geo,
    bringToFront: async () => { await send(null, 'Page.bringToFront'); },
    navigate: async url => {
      await send(null, 'Page.navigate', { url });
      await api.waitFor(() => evaluate('document.readyState').then(v => v === 'complete'), 30000, 500, 'navigate ' + url);
      return true;
    },
    reload: async () => { await send(null, 'Page.reload', { ignoreCache: false }); },
    latestConsoleText: needle => [...consoleLines].reverse().find(l => l.text.includes(needle)) || null,
    waitFor: async (fn, timeoutMs, pollMs, label) => {
      const start = Date.now();
      for (;;) {
        let v = null, err = null;
        try { v = await fn(); } catch (e) { err = e; }
        if (v) return v;
        if (Date.now() - start > timeoutMs) {
          throw new Error('timeout ' + label + (err ? ' lastError=' + String(err && err.message ? err.message : err) : ''));
        }
        await sleep(pollMs);
      }
    },
    waitABODE_READY: (timeoutMs = 180000) => api.waitFor(() => consoleLines.some(l => l.text.includes('ABODE_READY:')), timeoutMs, 1000, 'ABODE_READY'),
    click: async (point, opts = {}) => {
      const g = await geo();
      const v = toViewport(point, g);
      await send(null, 'Input.dispatchMouseEvent', { type: 'mouseMoved', x: v.x, y: v.y, buttons: 0, pointerType: 'mouse' });
      await sleep(opts.pressDelayMs ?? 60);
      await send(null, 'Input.dispatchMouseEvent', { type: 'mousePressed', x: v.x, y: v.y, button: 'left', buttons: 1, clickCount: 1, pointerType: 'mouse' });
      await sleep(opts.holdMs ?? 80);
      await send(null, 'Input.dispatchMouseEvent', { type: 'mouseReleased', x: v.x, y: v.y, button: 'left', buttons: 0, clickCount: 1, pointerType: 'mouse' });
      return { viewport: v, geo: g, point };
    },
    wheel: async (point, deltaY, deltaX = 0) => {
      const g = await geo();
      const v = toViewport(point, g);
      await send(null, 'Input.dispatchMouseEvent', { type: 'mouseWheel', x: v.x, y: v.y, deltaY: deltaY, deltaX: deltaX, pointerType: 'mouse' });
      return { viewport: v, geo: g };
    },
    screenshot: async filePath => {
      const r = await send(null, 'Page.captureScreenshot', { format: 'png' });
      fs.writeFileSync(filePath, Buffer.from(r.data, 'base64'));
      return filePath;
    },
    readSaveRaw: () => evaluate(`(()=>{
      const ns='${namespace}';
      let idx=null;try{idx=JSON.parse(localStorage.getItem(ns+':save_index')||'null')}catch(e){}
      const slot=(idx&&idx.active_slot)||'save_main';
      const raw=localStorage.getItem(ns+':'+slot);
      let env=null;try{env=JSON.parse(raw||'null')}catch(e){}
      return {slot:slot, indexed:!!idx, env:env};
    })()`),
    readSave: async () => {
      const raw = await api.readSaveRaw();
      const env = raw.env || {};
      const st = env.state || null;
      return { slot: raw.slot, indexed: raw.indexed, schemaVersion: env.schema_version ?? null, revision: env.revision ?? null, state: st };
    },
    close: async () => { try { ws.close(); } catch {} }
  };
  debug('driver connected: pageId=' + page.id + ' url=' + page.url);
  return api;
}

export function summarizeSave(save) {
  const st = save.state;
  if (!st) return { slot: save.slot, revision: save.revision, empty: true };
  const res = {};
  for (const key of Object.keys(st.resources || {})) {
    const e = st.resources[key] || {};
    let v = 0, c = 0;
    try { v = Number(e.value); } catch { v = 0; }
    try { c = Number(e.cap); } catch { c = 0; }
    res[key] = { value: Number.isFinite(v) ? v : 0, cap: Number.isFinite(c) ? c : 0, unlocked: !!e.unlocked };
  }
  const cap = key => key in res ? res[key].cap : 0;
  const val = key => key in res ? res[key].value : 0;
  const buildings = {};
  for (const key of Object.keys(st.buildings || {})) buildings[key] = Number(st.buildings[key] || 0);
  const economy = st.economy || {};
  const islands = {};
  for (const key of Object.keys(economy.islands || {})) islands[key] = { opened: !!(economy.islands[key] || {}).opened };
  const trips = {};
  for (const key of Object.keys(economy.trips || {})) trips[key] = Number((economy.trips[key] || {}).cargo || 0);
  const jobs = {};
  for (const key of Object.keys(economy.jobs || {})) jobs[key] = Number((economy.jobs[key] || {}).remaining || 0);
  const routes = Object.keys(economy.routes || {});
  return {
    slot: save.slot, revision: save.revision, schemaVersion: save.schemaVersion, empty: false,
    era: Number(st.era_id || 1), level: Number(st.level || 1),
    totalSeconds: Number(st.total_elapsed_seconds || 0),
    buildings, resources: res, economy: { version: Number(economy.version || 0), islands, jobs, trips, routes },
    helpers: { lingliCap: cap('lingli'), lingliVal: val('lingli'), home: id => val(id) }
  };
}

export function prettySummary(sum) {
  if (sum.empty) return 'empty save';
  const r = sum.resources;
  const parts = [];
  for (const key of Object.keys(r)) {
    if (r[key].unlocked) parts.push(key + '=' + r[key].value.toFixed(1) + '/' + r[key].cap.toFixed(0));
  }
  return 'era=' + sum.era + ' lv=' + sum.level + ' rev=' + sum.revision + ' ' + parts.join(' ');
}
