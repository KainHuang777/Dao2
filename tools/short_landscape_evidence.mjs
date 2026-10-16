import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import http from 'node:http';

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, '..');
const outDir = path.join(root, 'docs', 'verification', 'artifacts', 'd2-natural-20261016');

const sleep = ms => new Promise(r => setTimeout(r, ms));

function httpJson(cdpPort, requestPath, timeoutMs = 8000) {
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

const wsConnect = url => new Promise((resolve, reject) => {
  const ws = new WebSocket(url);
  ws.addEventListener('open', () => resolve(ws), { once: true });
  ws.addEventListener('error', () => reject(new Error('ws connect error ' + url)), { once: true });
});

const result = { utc: new Date().toISOString(), steps: [], consoleIssues: [], error: '' };
try {
  const version = await httpJson(9237, '/json/version');
  result.browserVersion = version.Browser;
  const targets = await httpJson(9237, '/json/list');
  const page = targets.find(t => t.type === 'page' && t.url.includes(':4306'));
  if (!page) throw new Error('no 4306 page target');
  result.targetUrl = page.url;
  const ws = await wsConnect(page.webSocketDebuggerUrl);
  let msgId = 0;
  const pending = new Map();
  ws.addEventListener('message', ev => {
    const m = JSON.parse(ev.data);
    if (m.id && pending.has(m.id)) {
      const p = pending.get(m.id);
      pending.delete(m.id);
      if (m.error) p.reject(new Error(m.method + ': ' + JSON.stringify(m.error)));
      else p.resolve(m.result);
    } else if (m.method === 'Runtime.consoleAPICalled') {
      const type = m.params.type;
      if (type === 'error' || type === 'warning') {
        result.consoleIssues.push({ source: 'consoleAPICalled', type, text: m.params.args.map(a => a.value !== undefined ? String(a.value) : (a.description || a.type)).join(' ').slice(0, 500) });
      }
    } else if (m.method === 'Runtime.exceptionThrown') {
      const d = m.params.exceptionDetails;
      result.consoleIssues.push({ source: 'exceptionThrown', type: 'exception', text: ((d.exception && d.exception.description) || d.text || '').slice(0, 500) });
    } else if (m.method === 'Log.entryAdded') {
      const e = m.params.entry;
      if (e.level === 'error' || e.level === 'warning') {
        result.consoleIssues.push({ source: 'Log.entryAdded', type: e.level, text: (e.text || '').slice(0, 500) });
      }
    }
  });
  const send = (method, params = {}) => new Promise((resolve, reject) => {
    const id = ++msgId;
    const timer = setTimeout(() => { pending.delete(id); reject(new Error('CDP timeout: ' + method)); }, 30000);
    pending.set(id, { resolve: v => { clearTimeout(timer); resolve(v); }, reject, method });
    ws.send(JSON.stringify({ id, method, params }));
  });
  const evaluate = async expression => {
    const r = await send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true });
    if (r.exceptionDetails) throw new Error('page eval error: ' + JSON.stringify(r.exceptionDetails).slice(0, 600));
    return r.result.value;
  };
  const shot = async name => {
    const r = await send('Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(path.join(outDir, name), Buffer.from(r.data, 'base64'));
    result.steps.push({ step: 'screenshot', file: name });
  };
  await send('Page.enable');
  await send('Runtime.enable');
  await send('Log.enable');
  await send('Emulation.setFocusEmulationEnabled', { enabled: true });

  const setViewport = async (w, h) => {
    await send('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: 1, mobile: false });
    await sleep(12000);
    const dims = await evaluate('JSON.stringify({w: window.innerWidth, h: window.innerHeight, dpr: window.devicePixelRatio})');
    result.steps.push({ step: 'viewport', w, h, dims: JSON.parse(dims) });
  };

  await setViewport(844, 390);
  await shot('113-short-landscape-844.png');
  const saveInfo = await evaluate(`(() => {
    const main = localStorage.getItem('dao2_saves:save_main') || '';
    let parsed = null;
    try { parsed = JSON.parse(main); } catch (e) {}
    return JSON.stringify({
      revision: parsed ? parsed.revision : null,
      era: parsed && parsed.state ? parsed.state.era_id : null,
      level: parsed && parsed.state ? parsed.state.level : null
    });
  })()`);
  result.saveAtShortLandscape = JSON.parse(saveInfo);

  await setViewport(800, 360);
  await shot('114-short-landscape-800.png');

  await setViewport(1280, 720);
  await shot('115-back-desktop-1280.png');

  fs.writeFileSync(path.join(outDir, 'short-landscape-evidence.json'), JSON.stringify(result, null, 2));
  console.log(JSON.stringify({ ok: true, consoleIssueCount: result.consoleIssues.length, save: result.saveAtShortLandscape }));
  process.exit(0);
} catch (e) {
  result.error = String(e && e.message ? e.message : e);
  try { fs.writeFileSync(path.join(outDir, 'short-landscape-evidence.json'), JSON.stringify(result, null, 2)); } catch {}
  console.log(JSON.stringify(result));
  process.exit(1);
}
