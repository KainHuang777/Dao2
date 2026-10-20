import fs from 'node:fs';
import path from 'node:path';
import { connectDriver, summarizeSave, sleep } from '../res1d2-natural-mouse-driver.mjs';
const CDP_PORT = Number(process.env.CDP_PORT || '9242');
const HTTP_PORT = Number(process.env.HTTP_PORT || '4380');
const DIR = 'docs/verification/artifacts/early-v1-d/unified-run';
fs.mkdirSync(DIR, { recursive: true });
const log = fs.createWriteStream(path.join(DIR, 'crosscheck.jsonl'), { flags: 'a' });
const rec = (type, data) => { const l = JSON.stringify({ utc: new Date().toISOString(), type, data: data || {} }); log.write(l + '\n'); console.log(l); };
const driver = await connectDriver({ cdpPort: CDP_PORT, matchPort: HTTP_PORT });
const num = v => { if (v == null) return 0; if (typeof v === 'object') v = v.value; return Number(v) || 0; };
async function snap(tag) {
  const env = await driver.readSave(); const st = env.state; const e = st.economy || {};
  const inv = {};
  for (const id of Object.keys(e.islands || {})) {
    const o = {}; const src = (e.islands[id] || {}).inventory || {};
    for (const k of Object.keys(src)) o[k] = num(src[k]);
    inv[id] = { opened: !!(e.islands[id] || {}).opened, inventory: o };
  }
  const trips = {}; for (const k of Object.keys(e.trips || {})) trips[k] = e.trips[k];
  const routes = {}; for (const k of Object.keys(e.routes || {})) routes[k] = { enabled: !!e.routes[k].enabled, target: e.routes[k].target, level: e.routes[k].level };
  const jobs = {}; for (const k of Object.keys(e.jobs || {})) jobs[k] = { recipe: e.jobs[k].recipe_id, remaining: e.jobs[k].remaining, repeat: e.jobs[k].repeat, status: e.jobs[k].status };
  const home = {}; for (const k of Object.keys(st.resources || {})) { const r = st.resources[k]; if (r.unlocked) home[k] = num(r.value); }
  const row = { tag, era: st.era_id, level: st.level, revision: env.revision, total_elapsed_seconds: st.total_elapsed_seconds, home, islands: inv, routes, trips, jobs };
  rec('snap', row);
  fs.writeFileSync(path.join(DIR, 'crosscheck-' + tag + '.json'), JSON.stringify({ envelope_revision: env.revision, settled_until_utc_ms: (await driver.readSaveRaw()).env.settled_until_utc_ms, state: st }, null, 0));
  return row;
}
function rv(r, id) { return r.home[id] || 0; }
try {
  await driver.bringToFront();
  for (let i = 0; i < 3; i++) { try { await driver.click({ x: 278, y: 287 }); } catch {} await sleep(300); }
  const a = await snap('t0');
  await driver.screenshot(path.join(DIR, 'cc-hud-t0.png'));
  // outposts page: island stocks
  await driver.click({ x: 85, y: 666 }); await sleep(800);
  await driver.click({ x: 175, y: 666 }); await sleep(1400);
  await driver.click({ x: 875, y: 46 }); await sleep(1400);           // 空島
  await driver.screenshot(path.join(DIR, 'cc-outposts-home.png'));
  await driver.click({ x: 986, y: 177 }); await sleep(900);           // 青木島
  await driver.screenshot(path.join(DIR, 'cc-outposts-wood.png'));
  await driver.click({ x: 1064, y: 177 }); await sleep(900);          // 玄礦島
  await driver.screenshot(path.join(DIR, 'cc-outposts-ore.png'));
  await driver.click({ x: 1152, y: 177 }); await sleep(900);          // 丹霞島
  await driver.screenshot(path.join(DIR, 'cc-outposts-herb.png'));
  await driver.click({ x: 1038, y: 46 }); await sleep(1400);          // 運輸
  await driver.screenshot(path.join(DIR, 'cc-transport.png'));
  // wait and resample to show growth / shipping over time
  await sleep(90000);
  const b = await snap('t1');
  await sleep(90000);
  const c = await snap('t2');
  rec('delta_home', { dt: Math.round((c.total_elapsed_seconds - a.total_elapsed_seconds)), spirit_timber: rv(c, 'spirit_timber') - rv(a, 'spirit_timber'), bronze_essence: rv(c, 'bronze_essence') - rv(a, 'bronze_essence'), stone_mid: rv(c, 'stone_mid') - rv(a, 'stone_mid'), lingli: rv(c, 'lingli') - rv(a, 'lingli') });
  rec('done', {});
} catch (e) { rec('error', { error: String(e && e.stack ? e.stack : e) }); }
finally { await driver.close().catch(() => {}); log.end(); process.exit(0); }
