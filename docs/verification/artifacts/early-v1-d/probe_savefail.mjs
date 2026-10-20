import fs from 'node:fs';
import path from 'node:path';
import { connectDriver, summarizeSave, sleep } from '../res1d2-natural-mouse-driver.mjs';

const CDP_PORT = Number(process.env.CDP_PORT || '9242');
const HTTP_PORT = Number(process.env.HTTP_PORT || '4380');
const DIR = process.env.DIR || 'docs/verification/artifacts/early-v1-d/unified-run';
fs.mkdirSync(DIR, { recursive: true });
const log = fs.createWriteStream(path.join(DIR, 'probe-savefail.jsonl'), { flags: 'a' });
function rec(type, data) { const line = JSON.stringify({ utc: new Date().toISOString(), type, data: data || {} }); log.write(line + '\n'); console.log(line); }

const driver = await connectDriver({ cdpPort: CDP_PORT, matchPort: HTTP_PORT });
driver.onConsoleLine(l => { if (/SAVE|STORAGE|保存|失敗|失败/.test(l.text)) rec('console', { text: l.text.slice(0, 300) }); });

try {
  await driver.bringToFront();
  const e0 = (await driver.readSaveRaw()).env || {};
  rec('before', { revision: e0.revision, era: summarizeSave(await driver.readSave()).era });

  // Install a failing setItem for save payload keys (keep save_index writable so slot logic still runs)
  const installed = await driver.evaluate(`(()=>{if(window.__sfInstalled)return 'already';window.__origSetItem=window.Storage.prototype.setItem;window.Storage.prototype.setItem=function(k,v){if(typeof k==='string'&&k.indexOf('dao2_saves:save')===0)throw new DOMException('quota exceeded (injected)','QuotaExceededError');return window.__origSetItem.call(this,k,v);};window.__sfInstalled=true;return 'installed';})()`);
  rec('inject', { installed });

  // Trigger saves: wait for autosave (15s) and nudge an action
  await driver.click({ x: 278, y: 82 }).catch(() => {});
  await sleep(6000);
  await driver.screenshot(path.join(DIR, 'probe-savefail-1.png'));
  await sleep(14000);
  await driver.screenshot(path.join(DIR, 'probe-savefail-2.png'));
  const eFail = (await driver.readSaveRaw()).env || {};
  rec('during_fail', { revision: eFail.revision });

  // Restore storage and confirm recovery (autosave should succeed again, revision advances)
  const restored = await driver.evaluate(`(()=>{if(window.__origSetItem){window.Storage.prototype.setItem=window.__origSetItem;}window.__sfInstalled=false;return 'restored';})()`);
  rec('restore', { restored });
  let recovered = false; let rev = eFail.revision;
  for (let i = 0; i < 20; i++) {
    await sleep(3000);
    const e = (await driver.readSaveRaw()).env || {};
    if (e.revision > eFail.revision) { recovered = true; rev = e.revision; break; }
  }
  await driver.screenshot(path.join(DIR, 'probe-savefail-3-recovered.png'));
  rec('verify', { recovered, revision_after: rev, revision_during_fail: eFail.revision, ok: recovered });
} catch (e) {
  rec('probe_error', { error: String(e && e.stack ? e.stack : e) });
} finally {
  try { await driver.evaluate(`(()=>{if(window.__origSetItem){window.Storage.prototype.setItem=window.__origSetItem;}return true;})()`); } catch {}
  await driver.close().catch(() => {});
  log.end();
  process.exit(0);
}
