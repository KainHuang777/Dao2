// Test-only CDP driver: natural tab-hide freeze + refocus recovery on real Edge guest.
// Uses browser-level Target.createTarget/activateTarget so the game tab is naturally hidden
// (rAF stops) and only wall-clock refocus logic can recover it. Isolated origin + test fixture.
const http = require('http');
const fs = require('fs');

const CDP_PORT = process.env.CDP_PORT || '9225';
const GAME_PORT = process.env.GAME_PORT || '4199';
const HIDDEN_MS_1 = parseInt(process.env.HIDDEN_MS_1 || '120000', 10);
const HIDDEN_MS_2 = parseInt(process.env.HIDDEN_MS_2 || '45000', 10);
const ARTIFACT = process.env.ARTIFACT || '';
const NAMESPACE = 'dao2_saves';

const events = [];
function record(type, data) {
  const ev = { utc: new Date().toISOString(), type, data };
  events.push(ev);
  process.stdout.write(JSON.stringify(ev) + '\n');
  if (ARTIFACT) { try { fs.appendFileSync(ARTIFACT, JSON.stringify(ev) + '\n'); } catch {} }
}

function getJson(path, method = 'GET') {
  return new Promise((resolve, reject) => {
    const req = http.request({ host: '127.0.0.1', port: CDP_PORT, path, method }, res => {
      let data = '';
      res.on('data', d => data += d);
      res.on('end', () => { try { resolve(JSON.parse(data)); } catch (e) { reject(e); } });
    });
    req.on('error', reject);
    req.end();
  });
}

function wsConnect(url) {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket(url);
    ws.addEventListener('open', () => resolve(ws), { once: true });
    ws.addEventListener('error', () => reject(new Error('ws connect error')), { once: true });
  });
}

let msgId = 0;
function send(ws, method, params = {}) {
  const id = ++msgId;
  return new Promise((resolve, reject) => {
    const onMsg = ev => {
      const m = JSON.parse(ev.data);
      if (m.id === id) {
        ws.removeEventListener('message', onMsg);
        if (m.error) reject(new Error(method + ': ' + JSON.stringify(m.error)));
        else resolve(m.result);
      }
    };
    ws.addEventListener('message', onMsg);
    ws.send(JSON.stringify({ id, method, params }));
  });
}

const sleep = ms => new Promise(r => setTimeout(r, ms));

async function waitUntil(fn, timeoutMs, pollMs, label) {
  const start = Date.now();
  for (;;) {
    const v = await fn();
    if (v) return v;
    if (Date.now() - start > timeoutMs) throw new Error('timeout: ' + label);
    await sleep(pollMs);
  }
}

async function main() {
  const version = await getJson('/json/version');
  const browserWs = await wsConnect(version.webSocketDebuggerUrl);
  const targets = await getJson('/json/list');
  const page = targets.find(t => t.type === 'page' && t.webSocketDebuggerUrl);
  if (!page) throw new Error('no page target: ' + JSON.stringify(targets.map(t => t.type + ' ' + t.url)));
  const gameWs = await wsConnect(page.webSocketDebuggerUrl);
  const gameId = page.id;
  await send(gameWs, 'Page.enable');
  await send(gameWs, 'Runtime.enable');

  const consoleLines = [];
  gameWs.addEventListener('message', ev => {
    try {
      const m = JSON.parse(ev.data);
      if (!m.id && m.method === 'Runtime.consoleAPICalled' && m.params.type === 'log') {
        const text = (m.params.args || []).map(a => a.value != null ? String(a.value) : a.description || '').join(' ');
        if (text.trim()) {
          const line = { utc: new Date().toISOString(), text: text.slice(0, 400) };
          consoleLines.push(line);
          if (ARTIFACT) { try { fs.appendFileSync(ARTIFACT, JSON.stringify({ utc: line.utc, type: 'console', data: line }) + '\n'); } catch {} }
        }
      }
    } catch {}
  });

  const evaluate = async expr => {
    const r = await send(gameWs, 'Runtime.evaluate', { expression: expr, returnByValue: true, awaitPromise: true });
    if (r.exceptionDetails) throw new Error('page eval error: ' + JSON.stringify(r.exceptionDetails).slice(0, 800));
    return r.result.value;
  };

  const readState = () => evaluate(`(()=>{
    const idxRaw = localStorage.getItem('${NAMESPACE}:save_index');
    let idx = null; try { idx = JSON.parse(idxRaw); } catch {}
    const mainRaw = localStorage.getItem('${NAMESPACE}:save_main');
    let cursor = null; try { const env = JSON.parse(mainRaw); cursor = env.settled_until_utc_ms ?? (env.meta && env.meta.settled_until_utc_ms) ?? null; } catch {}
    return { visibility: document.visibilityState, revision: idx ? idx.revision : null, cursor };
  })()`);

  const base = 'http://127.0.0.1:' + GAME_PORT;
  await send(gameWs, 'Page.navigate', { url: base + '/launcher' });
  await waitUntil(() => evaluate('document.readyState').then(v => v === 'complete'), 20000, 500, 'launcher load');
  const cleared = await evaluate(`(()=>{
    for (let i = localStorage.length - 1; i >= 0; i--) localStorage.removeItem(localStorage.key(i));
    return 'cleared';
  })()`);
  record('origincleared', { cleared });
  const seeded = await evaluate(`(async()=>{
    const raw = await (await fetch('/fixture')).text();
    const saved = JSON.parse(raw);
    localStorage.setItem('${NAMESPACE}:save_main', raw);
    localStorage.setItem('${NAMESPACE}:save_index', JSON.stringify({ active_slot: 'save_main', revision: saved.revision, commit_sequence: 1 }));
    return 'seeded revision=' + saved.revision;
  })()`);
  record('fixtureseeded', { seeded });

  await send(gameWs, 'Page.navigate', { url: base + '/index.html' });
  await waitUntil(() => evaluate('document.readyState').then(v => v === 'complete'), 20000, 500, 'game load');
  await waitUntil(() => consoleLines.some(l => l.text.includes('ABODE_READY:')), 180000, 1000, 'ABODE_READY console');
  record('ready', { atMs: Date.now() });

  // Let any startup settle finish and revision stabilize before baselining.
  let prev = await readState();
  let stableCount = 0, stableStart = Date.now();
  for (;;) {
    if (Date.now() - stableStart > 180000) throw new Error('timeout: save stabilization');
    await sleep(2000);
    const cur = await readState();
    if (cur.revision === prev.revision && cur.cursor === prev.cursor) { stableCount++; if (stableCount >= 4) { prev = cur; break; } }
    else { stableCount = 0; stableStart = Date.now(); prev = cur; }
  }
  record('baseline', { afterMs: Date.now(), ...prev });
  const lastSettleBeginEnd = consoleLines.filter(l => /OFFLINE_SETTLEMENT_(BEGIN|END)/.test(l.text)).length;

  // Freeze cycle helper: hide game tab, verify, hold, restore, verify recovery.
  async function freezeCycle(label, hiddenMs) {
    const frozenTarget = await send(browserWs, 'Target.createTarget', { url: 'about:blank' });
    await sleep(1500);
    await send(browserWs, 'Target.activateTarget', { targetId: frozenTarget.targetId });
    await sleep(1500);
    const hidden = await readState();
    record('hiddenentered', { label, hiddenMs, ...hidden });
    if (hidden.visibility !== 'hidden') throw new Error(label + ': expected hidden, got ' + hidden.visibility);
    const hideTime = Date.now();

    // Drive the blank tab a bit: keep it in the foreground, wait the full hidden window.
    const hiddenStart = hideTime;
    const preRev = hidden.revision;
    while (Date.now() - hiddenStart < hiddenMs) {
      await sleep(5000);
      const st = await readState();
      if (st.visibility !== 'hidden') record('unexpectedvisibility', { label, ...st });
      if (st.revision !== preRev) record('unexpectedrevisionduringhidden', { label, expected: preRev, ...st });
    }
    const actualHiddenMs = Date.now() - hideTime;

    await send(browserWs, 'Target.activateTarget', { targetId: gameId });
    await sleep(1500);
    const shown = await readState();
    record('refocused', { label, actualHiddenMs, ...shown });
    if (shown.visibility !== 'visible') throw new Error(label + ': expected visible after refocus, got ' + shown.visibility);

    // Wait for recovery settle: revision must change (unless hidden slice < save cadence).
    const rev0 = shown.revision;
    const cursor0 = shown.cursor;
    const t0 = Date.now();
    let changed = null;
    while (Date.now() - t0 < 90000) {
      const st = await readState();
      if (st.revision !== rev0 || st.cursor !== cursor0) { changed = st; changed.recoverMs = Date.now() - t0; break; }
      await sleep(1000);
    }
    record('recoverycheck', { label, changed });
    if (!changed) throw new Error(label + ': no save revision/cursor advance after refocus');
    const advance = (changed.cursor != null) ? changed.cursor - cursor0 : null;
    const diffSec = advance == null ? null : (advance - actualHiddenMs) / 1000;
    record('recoveryadvance', { label, actualHiddenMs, cursorAdvanceMs: advance, hiddenMinusAdvanceSec: diffSec });
    if (changed.revision === rev0 && advance === 0) throw new Error(label + ': neither revision nor cursor advanced');

    // Idle visible for 8s: revision should hold (no double settle churn).
    const revAfter = changed.revision;
    await sleep(8000);
    const idle = await readState();
    record('idleafterrestore', { label, revisionBeforeIdle: revAfter, ...idle });
    if (idle.revision !== revAfter) record('revisionshuffledwhileidle', { label, revAfter, idleRev: idle.revision });
    return { actualHiddenMs, changed, idle, rec: { label, actualHiddenMs, cursorAdvanceMs: advance } };
  }

  const c1 = await freezeCycle('freeze1', HIDDEN_MS_1);
  const c2 = await freezeCycle('freeze2', HIDDEN_MS_2);

  const failLines = consoleLines.filter(l => l.text.includes('WEB_BACKGROUND_SAVE_FAILED'));
  record('consolediagnostic', {
    settlementPrints: consoleLines.filter(l => /OFFLINE_SETTLEMENT|WEB_BACKGROUND/.test(l.text)).map(l => l),
    failureLines: failLines,
  });
  if (failLines.length) throw new Error('WEB_BACKGROUND_SAVE_FAILED observed: ' + JSON.stringify(failLines));

  record('done', { cycles: [c1.rec, c2.rec] });
}
main().catch(e => {
  record('fatal', { error: String(e && e.message ? e.message : e) });
  process.exit(1);
});
