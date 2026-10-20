import fs from 'node:fs';
import path from 'node:path';
import { connectDriver, summarizeSave, sleep } from '../res1d2-natural-mouse-driver.mjs';

const CDP_PORT = Number(process.env.CDP_PORT || '9242');
const HTTP_PORT = Number(process.env.HTTP_PORT || '4380');
const DIR = process.env.DIR || 'docs/verification/artifacts/early-v1-d/unified-run';
const BASE_URL = 'http://127.0.0.1:' + HTTP_PORT + '/index.html';
const GAP_MS = Number(process.env.GAP_MS || 90000);
fs.mkdirSync(DIR, { recursive: true });
const log = fs.createWriteStream(path.join(DIR, 'probe-offline.jsonl'), { flags: 'a' });
function rec(type, data) { const line = JSON.stringify({ utc: new Date().toISOString(), type, data: data || {} }); log.write(line + '\n'); console.log(line); }

const driver = await connectDriver({ cdpPort: CDP_PORT, matchPort: HTTP_PORT });
const consoleLines = [];
driver.onConsoleLine(l => { consoleLines.push(l); if (/OFFLINE_SETTLEMENT/.test(l.text)) rec('console', { text: l.text.slice(0, 300) }); });

try {
  await driver.bringToFront();
  const env0 = await driver.readSaveRaw();
  const e0 = env0.env || {};
  const s0 = summarizeSave(await driver.readSave());
  rec('before', { revision: e0.revision, settled_until_utc_ms: e0.settled_until_utc_ms, era: s0.era, level: s0.level });
  fs.writeFileSync(path.join(DIR, 'probe-offline-before.json'), JSON.stringify(e0, null, 2), 'utf8');

  rec('navigate_away', {});
  await driver.navigate('about:blank');
  const awayStart = Date.now();
  await sleep(GAP_MS);
  const awayReal = Date.now() - awayStart;

  rec('navigate_back', { awayReal });
  await driver.navigate(BASE_URL);
  await driver.waitFor(() => driver.evaluate('document.readyState').then(v => v === 'complete'), 60000, 500, 'readyState');
  await driver.waitABODE_READY(120000).catch(e => rec('abode_ready_timeout', { error: String(e) }));
  await sleep(4000);
  await driver.screenshot(path.join(DIR, 'probe-offline-modal.png'));

  const env1 = await driver.readSaveRaw();
  const e1 = env1.env || {};
  const rep = e1.last_offline_report || null;
  rec('after', { revision: e1.revision, settled_until_utc_ms: e1.settled_until_utc_ms, report: rep });
  fs.writeFileSync(path.join(DIR, 'probe-offline-after.json'), JSON.stringify(e1, null, 2), 'utf8');
  rec('verify', {
    away_ms: rep && rep.away_ms, expect_at_least: GAP_MS - 5000,
    effective_ms: rep && rep.effective_ms, forfeited_ms: rep && rep.forfeited_ms,
    cap_applied: rep && rep.cap_applied, bootstrap: rep && rep.bootstrap, rollback: rep && rep.rollback,
    ok: !!(rep && rep.away_ms >= GAP_MS - 10000)
  });
} catch (e) {
  rec('probe_error', { error: String(e && e.stack ? e.stack : e) });
} finally {
  await driver.close().catch(() => {});
  log.end();
  process.exit(0);
}
