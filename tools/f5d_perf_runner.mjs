import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT = path.resolve(__dirname, '..');

const CDP_PORT = 9226;
const WEB_PORT = 4188;
const ARTIFACT_DIR = path.join(ROOT, 'docs', 'verification', 'artifacts', 'uix-r7-f5d');
fs.mkdirSync(ARTIFACT_DIR, { recursive: true });

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

function httpJson(port, requestPath, timeoutMs = 8000) {
  return new Promise((resolve, reject) => {
    const req = http.request({ host: '127.0.0.1', port, path: requestPath, method: 'GET' }, res => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try { resolve(JSON.parse(data)); } catch (e) { reject(e); }
      });
    });
    req.on('error', reject);
    req.setTimeout(timeoutMs, () => req.destroy(new Error('http timeout ' + requestPath)));
    req.end();
  });
}

function wsConnect(url) {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket(url);
    ws.addEventListener('open', () => resolve(ws), { once: true });
    ws.addEventListener('error', () => reject(new Error('ws connect error: ' + url)), { once: true });
  });
}

async function main() {
  console.log('[F5-D Runner] Checking if test server is running on port ' + WEB_PORT + '...');
  let serverRunning = false;
  try {
    await httpJson(WEB_PORT, '/fixture');
    serverRunning = true;
    console.log('[F5-D Runner] Existing server detected on port ' + WEB_PORT);
  } catch (e) {
    console.log('[F5-D Runner] Starting island_preview_server.py on port ' + WEB_PORT + '...');
  }

  let serverProc = null;
  if (!serverRunning) {
    serverProc = spawn('python', [
      path.join(ROOT, 'tools', 'island_preview_server.py'),
      '--port', String(WEB_PORT),
      '--normal-build',
      '--review-fixture',
      '--metrics-log', 'uix-r7-f5d-metrics.jsonl'
    ], { stdio: 'inherit', cwd: ROOT });
    await sleep(3000);
  }

  const edgeUserData = path.join(ROOT, 'build', 'f5d_edge_user');
  fs.mkdirSync(edgeUserData, { recursive: true });

  const edgeExe = "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe";
  console.log('[F5-D Runner] Launching Edge with remote debugging port ' + CDP_PORT + '...');
  const edgeProc = spawn(edgeExe, [
    '--guest',
    '--user-data-dir=' + edgeUserData,
    '--remote-debugging-port=' + CDP_PORT,
    '--window-size=1280,760',
    '--no-first-run',
    '--no-default-browser-check',
    `http://127.0.0.1:${WEB_PORT}/metrics.html?sampleSeconds=60`
  ], { stdio: 'ignore' });

  await sleep(4000);

  let msgId = 0;
  const pending = new Map();
  let ws;

  async function send(method, params = {}) {
    const id = ++msgId;
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        pending.delete(id);
        reject(new Error('CDP timeout: ' + method));
      }, 60000);
      pending.set(id, {
        resolve: res => { clearTimeout(timer); resolve(res); },
        reject: err => { clearTimeout(timer); reject(err); },
        method
      });
      ws.send(JSON.stringify({ id, method, params }));
    });
  }

  try {
    const targets = await httpJson(CDP_PORT, '/json/list');
    const page = targets.find(t => t.type === 'page' && t.url.includes(':' + WEB_PORT));
    if (!page) throw new Error('Game page target not found in ' + JSON.stringify(targets));

    console.log('[F5-D Runner] Connecting to WebSocket: ' + page.webSocketDebuggerUrl);
    ws = await wsConnect(page.webSocketDebuggerUrl);
    ws.addEventListener('message', ev => {
      const m = JSON.parse(ev.data);
      if (m.id && pending.has(m.id)) {
        const p = pending.get(m.id);
        pending.delete(m.id);
        if (m.error) p.reject(new Error(m.method + ': ' + JSON.stringify(m.error)));
        else p.resolve(m.result);
      }
    });

    await send('Page.enable');
    await send('Runtime.enable');
    await send('Emulation.setFocusEmulationEnabled', { enabled: true });
    await send('Emulation.setDeviceMetricsOverride', { width: 1280, height: 720, deviceScaleFactor: 1, mobile: false });

    async function evaluate(expression) {
      const res = await send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true });
      if (res.exceptionDetails) {
        throw new Error('Eval error: ' + JSON.stringify(res.exceptionDetails));
      }
      return res.result.value;
    }

    console.log('[F5-D Runner] Seeding fixture into localStorage...');
    await send('Page.navigate', { url: `http://127.0.0.1:${WEB_PORT}/launcher` });
    await sleep(2000);
    await evaluate(`(async () => {
      localStorage.clear();
      const raw = await (await fetch('/fixture')).text();
      const saved = JSON.parse(raw);
      localStorage.setItem('dao2_saves:save_main', raw);
      localStorage.setItem('dao2_saves:save_index', JSON.stringify({ active_slot: 'save_main', revision: saved.revision, commit_sequence: 1 }));
    })()`);
    console.log('[F5-D Runner] Fixture seeded successfully.');

    console.log('[F5-D Runner] Navigating to 60s sample metrics page...');
    await send('Page.navigate', { url: `http://127.0.0.1:${WEB_PORT}/metrics.html?sampleSeconds=60` });

    console.log('[F5-D Runner] Waiting for ABODE_READY in game...');
    let ready = false;
    for (let i = 0; i < 90; i++) {
      const reportText = await evaluate('document.getElementById("metrics")?.textContent || ""');
      if (reportText && !reportText.includes('等待 ABODE_READY')) {
        ready = true;
        break;
      }
      await sleep(1000);
    }
    if (!ready) throw new Error('Timeout waiting for ABODE_READY');
    console.log('[F5-D Runner] Game is ABODE_READY!');

    // Let the game stabilize for 3 seconds
    await sleep(3000);

    // --- TEST 1: 60s Baseline Performance ---
    console.log('[F5-D Runner] Starting 60s baseline performance measurement...');
    await evaluate('document.getElementById("sample").click()');
    
    // Wait for 60s sample completion
    console.log('[F5-D Runner] Sampling for 62 seconds...');
    await sleep(62000);

    let baselineReport = await evaluate('document.getElementById("metrics")?.textContent || ""');
    console.log('[F5-D Runner] 60s Sample 1 Result snippet: ' + baselineReport.slice(0, 300));
    fs.writeFileSync(path.join(ARTIFACT_DIR, 'sample-60s-baseline.json'), baselineReport);

    // Capture screenshot
    const shot1 = await send('Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(path.join(ARTIFACT_DIR, 'web-baseline-1280x720.png'), Buffer.from(shot1.data, 'base64'));
    console.log('[F5-D Runner] Baseline screenshot saved.');

    // --- TEST 2: 300s (5-minute) Sustained Performance Measurement ---
    console.log('[F5-D Runner] Navigating to 300s sample url...');
    await send('Page.navigate', { url: `http://127.0.0.1:${WEB_PORT}/metrics.html?sampleSeconds=300` });
    
    console.log('[F5-D Runner] Waiting for ABODE_READY on 300s run...');
    await sleep(5000);
    ready = false;
    for (let i = 0; i < 90; i++) {
      const reportText = await evaluate('document.getElementById("metrics")?.textContent || ""');
      if (reportText && !reportText.includes('等待 ABODE_READY')) {
        ready = true;
        break;
      }
      await sleep(1000);
    }
    if (!ready) throw new Error('Timeout waiting for ABODE_READY on 300s page');
    console.log('[F5-D Runner] Game is ABODE_READY for 300s test!');
    await sleep(3000);

    console.log('[F5-D Runner] Starting 300s (5-minute) sustained performance measurement...');
    await evaluate('document.getElementById("sample").click()');

    // Wait for 305 seconds with heartbeats
    for (let sec = 0; sec < 305; sec += 30) {
      console.log(`[F5-D Runner] Sampling in progress... ${sec}/300 seconds elapsed`);
      await sleep(30000);
    }
    await sleep(5000);

    let sustainedReport = await evaluate('document.getElementById("metrics")?.textContent || ""');
    console.log('[F5-D Runner] 300s Sustained Sample Result snippet: ' + sustainedReport.slice(0, 300));
    fs.writeFileSync(path.join(ARTIFACT_DIR, 'sample-300s-sustained.json'), sustainedReport);

    const shot2 = await send('Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(path.join(ARTIFACT_DIR, 'web-sustained-1280x720.png'), Buffer.from(shot2.data, 'base64'));
    console.log('[F5-D Runner] Sustained screenshot saved.');

    console.log('[F5-D Runner] All browser measurements completed successfully!');
  } finally {
    if (ws) {
      try { ws.close(); } catch {}
    }
    try {
      edgeProc.kill();
    } catch {}
    if (serverProc) {
      try { serverProc.kill(); } catch {}
    }
  }
}

main().catch(err => {
  console.error('[F5-D Runner] Error:', err);
  process.exit(1);
});
