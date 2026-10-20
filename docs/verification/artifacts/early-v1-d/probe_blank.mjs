import fs from 'node:fs';
import path from 'node:path';
import { connectDriver, summarizeSave, sleep } from '../res1d2-natural-mouse-driver.mjs';

const CDP_PORT = Number(process.env.CDP_PORT || '9241');
const HTTP_PORT = Number(process.env.HTTP_PORT || '4380');
const DIR = process.env.DIR || 'docs/verification/artifacts/early-v1-d/probe-blank';
fs.mkdirSync(DIR, { recursive: true });

const driver = await connectDriver({ cdpPort: CDP_PORT, matchPort: HTTP_PORT, debugPrinter: () => {} });
const out = [];
function rec(type, data) { const line = JSON.stringify({ utc: new Date().toISOString(), type, data: data || {} }); out.push(line); console.log(line); }

try {
  driver.onConsoleLine(() => {});
  await driver.bringToFront();
  await driver.reload();
  await sleep(1000);
  const ready = await driver.waitFor(() => driver.consoleLines.some(l => l.text.includes('ABODE_READY:')), 90000, 1000, 'ABODE_READY').then(() => true).catch(e => { rec('ready_error', { error: String(e) }); return false; });
  rec('ready', { ready });
  await sleep(2000);
  const offlineLines = driver.consoleLines.filter(l => l.text.includes('OFFLINE_SETTLEMENT') || l.text.includes('STORAGE_STARTUP_FAILED')).map(l => l.text);
  rec('offline_console', { offlineLines });
  const raw = await driver.readSaveRaw();
  const env = raw.env || {};
  rec('envelope_keys', { keys: Object.keys(env), revision: env.revision, schema_version: env.schema_version, settled: env.settled_until_utc_ms, meta: env.meta || null });
  const sum = summarizeSave(await driver.readSave());
  rec('summary', sum);
  await driver.screenshot(path.join(DIR, 'probe-blank.png'));
  const rect = await driver.geo();
  rec('geo', { scale: rect.scale, rect: rect.rect });
} catch (e) {
  rec('probe_error', { error: String(e && e.stack ? e.stack : e) });
  try { await driver.screenshot(path.join(DIR, 'probe-error.png')); } catch {}
} finally {
  fs.writeFileSync(path.join(DIR, 'probe.jsonl'), out.join('\n') + '\n', 'utf8');
  await driver.close().catch(() => {});
  process.exit(0);
}
