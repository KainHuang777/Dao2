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
    req.setTimeout(timeoutMs, () => req.destroy(new Error('http timeout')));
    req.end();
  });
}
const wsConnect = url => new Promise((resolve, reject) => {
  const ws = new WebSocket(url);
  ws.addEventListener('open', () => resolve(ws), { once: true });
  ws.addEventListener('error', () => reject(new Error('ws connect error')), { once: true });
});

const result = { utc: new Date().toISOString(), error: '' };
try {
  const targets = await httpJson(9237, '/json/list');
  const page = targets.find(t => t.type === 'page' && t.url.includes(':4306'));
  if (!page) throw new Error('no 4306 page target');
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
    const timer = setTimeout(() => { pending.delete(id); reject(new Error('CDP timeout: ' + method)); }, 30000);
    pending.set(id, { resolve: v => { clearTimeout(timer); resolve(v); }, reject, method });
    ws.send(JSON.stringify({ id, method, params }));
  });
  const shot = async name => {
    const r = await send('Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(path.join(outDir, name), Buffer.from(r.data, 'base64'));
  };
  const click = async (x, y) => {
    await send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', clickCount: 1 });
    await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', clickCount: 1 });
  };
  await send('Page.enable');
  await send('Runtime.enable');
  await send('Emulation.setFocusEmulationEnabled', { enabled: true });
  await send('Emulation.setDeviceMetricsOverride', { width: 844, height: 390, deviceScaleFactor: 1, mobile: false });
  await sleep(4000);
  await click(295, 262);
  await sleep(3000);
  await shot('113-short-landscape-844-closed.png');
  await send('Emulation.setDeviceMetricsOverride', { width: 800, height: 360, deviceScaleFactor: 1, mobile: false });
  await sleep(8000);
  await shot('114-short-landscape-800-closed.png');
  await send('Emulation.setDeviceMetricsOverride', { width: 1280, height: 720, deviceScaleFactor: 1, mobile: false });
  await sleep(8000);
  await shot('115-back-desktop-1280.png');
  console.log(JSON.stringify({ ok: true }));
  process.exit(0);
} catch (e) {
  result.error = String(e && e.message ? e.message : e);
  console.log(JSON.stringify(result));
  process.exit(1);
}
