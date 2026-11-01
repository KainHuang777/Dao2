import fs from 'node:fs';
import path from 'node:path';
import { connectDriver, sleep } from '../docs/verification/artifacts/res1d2-natural-mouse-driver.mjs';

const cdpPort = Number(process.env.CDP_PORT || 9243);
const httpPort = Number(process.env.HTTP_PORT || 48343);
const baseUrl = process.env.BASE_URL || `http://127.0.0.1:${httpPort}/index.html`;
const fixturePath = process.env.FIXTURE || 'docs/verification/artifacts/maid-ui2-duty-fixture.json';
const outDir = process.env.OUT_DIR || 'docs/verification/artifacts/maid-ui2-20261101';
const namespace = process.env.SAVE_NAMESPACE || 'dao2_saves';
const num = (name, fallback) => Number(process.env[name] || fallback);

fs.mkdirSync(outDir, { recursive: true });
const envelope = JSON.parse(fs.readFileSync(fixturePath, 'utf8'));
const revision = envelope.revision ?? 0;
const results = { ok: false, steps: [], console: [], checks: {}, errors: [] };
const driver = await connectDriver({ cdpPort, matchPort: httpPort, namespace });

function check(name, ok, detail = '') {
  results.checks[name] = { ok: !!ok, detail };
  results.steps.push({ name, ok: !!ok, detail });
  if (!ok) results.errors.push(name + (detail ? ': ' + detail : ''));
  console.log((ok ? 'PASS ' : 'FAIL ') + name + (detail ? ' ' + detail : ''));
}

async function shoot(name) {
  const file = path.join(outDir, name + '.png');
  await driver.screenshot(file);
  return file;
}

try {
  await driver.bringToFront();
  await driver.evaluate(`(()=>{const ns='${namespace}';const drop=[];for(let i=0;i<localStorage.length;i++){const k=localStorage.key(i);if(k&&k.startsWith(ns+':'))drop.push(k);}for(const k of drop)localStorage.removeItem(k);return drop.length;})()`);
  await driver.evaluate(`(()=>{localStorage.setItem('${namespace}:save_main', ${JSON.stringify(JSON.stringify(envelope))});localStorage.setItem('${namespace}:save_index', ${JSON.stringify(JSON.stringify({ active_slot: 'save_main', revision, commit_sequence: 1 }))});return true;})()`);
  await driver.navigate(baseUrl + '?r=' + Date.now());
  await driver.waitABODE_READY();
  await driver.waitFor(async () => { try { return (await driver.geo()).rect.height > 500; } catch { return false; } }, 60000, 500, 'canvas-ready');
  await sleep(2500);
  results.steps.push({ name: 'screenshot-01-offline-summary', file: await shoot('01-offline-summary') });

  const raw = await driver.readSaveRaw();
  const env = raw.env || {};
  const maid = (env.last_offline_report || {}).maid || {};
  check('offline-report-maid-actions', Number(maid.actions || 0) > 0, 'actions=' + String(maid.actions));
  const state = env.state || {};
  check('save-qingheng-recruited', !!(state.maid && state.maid.maids && state.maid.maids.qingheng && state.maid.maids.qingheng.recruited));

  await driver.click({ x: num('CLOSE_X', 439), y: num('CLOSE_Y', 79) });
  await sleep(900);
  results.steps.push({ name: 'screenshot-02-world', file: await shoot('02-world') });

  await driver.click({ x: num('DOCK_X', 360), y: num('DOCK_Y', 664) });
  await sleep(900);
  results.steps.push({ name: 'screenshot-03-characters', file: await shoot('03-characters') });

  const tabY = num('TAB_Y', 161);
  const tabXs = (process.env.TAB_XS || '940,1025,1122,1215').split(',').map(v => Number(v));
  await driver.click({ x: tabXs[2], y: tabY });
  await sleep(900);
  results.steps.push({ name: 'screenshot-04-work', file: await shoot('04-work') });

  await driver.click({ x: tabXs[3], y: tabY });
  await sleep(900);
  results.steps.push({ name: 'screenshot-05-bond', file: await shoot('05-bond') });

  const consoleErrors = driver.consoleLines.filter(l => /error|Error|SCRIPT ERROR/.test(l.text));
  results.console = driver.consoleLines.slice(-200);
  check('console-no-script-error', !driver.consoleLines.some(l => l.text.includes('SCRIPT ERROR')), 'lines=' + driver.consoleLines.length);
  results.ok = results.errors.length === 0;
  fs.writeFileSync(path.join(outDir, 'maid-ui2-web-check.json'), JSON.stringify(results, null, 2));
  console.log((results.ok ? 'MAID-UI2-WEB PASS' : 'MAID-UI2-WEB FAIL') + ' errors=' + JSON.stringify(results.errors));
  await driver.close();
  process.exit(results.ok ? 0 : 1);
} catch (error) {
  results.errors.push(String(error && error.stack ? error.stack : error));
  try { results.steps.push({ name: 'screenshot-99-failure', file: await shoot('99-failure') }); } catch {}
  try { results.console = driver.consoleLines.slice(-200); } catch {}
  fs.writeFileSync(path.join(outDir, 'maid-ui2-web-check.json'), JSON.stringify(results, null, 2));
  console.log('MAID-UI2-WEB FAIL ' + String(error));
  try { await driver.close(); } catch {}
  process.exit(1);
}
