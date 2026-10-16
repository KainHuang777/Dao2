import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import http from 'node:http';

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, '..');
const outDir = path.join(root, 'docs', 'verification', 'artifacts', 'd2-natural-20261016', 'restore');
const envelope = fs.readFileSync(path.join(outDir, 'restore_envelope.json'), 'utf8').trim();
const indexPayload = fs.readFileSync(path.join(outDir, 'restore_index.json'), 'utf8').trim();

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

const result = { utc: new Date().toISOString(), steps: [], error: '' };
try {
  const version = await httpJson(9237, '/json/version');
  result.browserVersion = version.Browser;
  const targets = await httpJson(9237, '/json/list');
  const page = targets.find(t => t.type === 'page' && t.url.includes(':4306'));
  if (!page) throw new Error('no 4306 page target: ' + JSON.stringify(targets.map(t => t.type + ' ' + t.url)));
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
    }
  });
  const send = (method, params = {}) => new Promise((resolve, reject) => {
    const id = ++msgId;
    const timer = setTimeout(() => { pending.delete(id); reject(new Error('CDP timeout: ' + method)); }, 20000);
    pending.set(id, { resolve: v => { clearTimeout(timer); resolve(v); }, reject, method });
    ws.send(JSON.stringify({ id, method, params }));
  });
  const evaluate = async expression => {
    const r = await send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true });
    if (r.exceptionDetails) throw new Error('page eval error: ' + JSON.stringify(r.exceptionDetails).slice(0, 600));
    return r.result.value;
  };
  await send('Page.enable');
  await send('Runtime.enable');
  await send('Emulation.setFocusEmulationEnabled', { enabled: true });
  await send('Emulation.setDeviceMetricsOverride', { width: 1280, height: 720, deviceScaleFactor: 1, mobile: false });

  const before = await evaluate('JSON.stringify(Object.keys(localStorage))');
  result.steps.push({ step: 'keys_before', keys: JSON.parse(before) });

  const setMain = await evaluate(`(() => { localStorage.setItem('dao2_saves:save_main', ${JSON.stringify(envelope)}); return localStorage.getItem('dao2_saves:save_main').length; })()`);
  const setIndex = await evaluate(`(() => { localStorage.setItem('dao2_saves:save_index', ${JSON.stringify(indexPayload)}); return localStorage.getItem('dao2_saves:save_index'); })()`);
  result.steps.push({ step: 'injected', mainLength: setMain, index: JSON.parse(setIndex) });

  await send('Page.reload', { ignoreCache: false });
  await sleep(12000);

  const afterCheck = await evaluate(`(() => {
    const main = localStorage.getItem('dao2_saves:save_main') || '';
    let parsed = null, err = '';
    try { parsed = JSON.parse(main); } catch (e) { err = String(e); }
    return JSON.stringify({
      length: main.length,
      hasChecksum: !!(parsed && parsed.checksum),
      revision: parsed ? parsed.revision : null,
      era: parsed && parsed.state ? parsed.state.era_id : null,
      level: parsed && parsed.state ? parsed.state.level : null,
      totalElapsed: parsed && parsed.state ? parsed.state.total_elapsed_seconds : null,
      parseError: err,
      keys: Object.keys(localStorage)
    });
  })()`);
  result.afterReload = JSON.parse(afterCheck);
  fs.writeFileSync(path.join(outDir, 'inject_result.json'), JSON.stringify(result, null, 2));
  console.log(JSON.stringify(result));
  process.exit(0);
} catch (e) {
  result.error = String(e && e.message ? e.message : e);
  try { fs.writeFileSync(path.join(outDir, 'inject_result.json'), JSON.stringify(result, null, 2)); } catch {}
  console.log(JSON.stringify(result));
  process.exit(1);
}
