import fs from 'node:fs';
import path from 'node:path';
import { connectDriver, summarizeSave, sleep } from '../res1d2-natural-mouse-driver.mjs';

const CDP_PORT = Number(process.env.CDP_PORT || '9240');
const HTTP_PORT = Number(process.env.HTTP_PORT || '4380');
const DIR = process.env.DIR || 'docs/verification/artifacts/early-v1-d/drive-era3';
const MAX_MS = Number(process.env.MAX_MS || 5400000);
fs.mkdirSync(DIR, { recursive: true });
const log = fs.createWriteStream(path.join(DIR, 'events.jsonl'), { flags: 'a' });
function rec(type, data) { const line = JSON.stringify({ utc: new Date().toISOString(), type, data: data || {} }); log.write(line + '\n'); console.log(line); }

const P = { offline_close: { x: 278, y: 287 }, dock_home: { x: 95, y: 668 }, dock_management: { x: 191, y: 668 }, level_up: { x: 278, y: 82 } };
const TAB = { buildings: { x: 770, y: 46 }, manufacturing: { x: 951, y: 46 }, transport: { x: 1038, y: 46 } };
const CAT_REFINE = { x: 1092, y: 126 };
const CAT_COMBINE = { x: 1160, y: 126 };
const MODE_DD = { x: 855, y: 468 };
const MODE_REPEAT = { x: 560, y: 596 };
const START_X = 848;
const START_YS = [577, 560, 600, 620, 640, 540, 660, 512, 690];

const driver = await connectDriver({ cdpPort: CDP_PORT, matchPort: HTTP_PORT, debugPrinter: () => {} });
const shot = async (label) => { try { const f = path.join(DIR, 'shot-' + label + '.png'); await driver.screenshot(f); return f; } catch (e) { return null; } };
const save = async () => summarizeSave(await driver.readSave());
function rv(s, id) { const r = s.resources[id]; return r ? Number(r.value) : 0; }
function exportSave(tag) {
  try {
    return driver.evaluate(`(()=>{const ns='dao2_saves';let idx=null;try{idx=JSON.parse(localStorage.getItem(ns+':save_index')||'null')}catch(e){}const slot=(idx&&idx.active_slot)||'save_main';return {index:localStorage.getItem(ns+':save_index'),main:localStorage.getItem(ns+':'+slot)};})()`).then(r => {
      fs.writeFileSync(path.join(DIR, tag + '.json'), r.main || '', 'utf8');
      fs.writeFileSync(path.join(DIR, tag + '.index.json'), r.index || '', 'utf8');
    }).catch(e => rec('export_error', { tag, error: String(e) }));
  } catch (e) { rec('export_error', { tag, error: String(e) }); return Promise.resolve(); }
}
async function dismiss() { for (let i = 0; i < 3; i++) { try { await driver.click(P.offline_close); } catch (e) {} await sleep(350); } }
async function gotoBuildings() {
  await driver.bringToFront();
  await driver.reload();
  await sleep(6500);
  await driver.bringToFront();
  await dismiss();
  await driver.click(P.dock_management);
  await sleep(1800);
}
async function gotoMfg(cat) { await gotoBuildings(); await driver.click(TAB.manufacturing); await sleep(1600); if (cat) { await driver.click(cat); await sleep(1500); } }

async function craftViaDetail(cat, title, mode) {
  await gotoMfg(cat);
  for (const ty of [title.y, title.y - 12, title.y + 12, title.y - 24, title.y + 24]) {
    await driver.click({ x: title.x, y: ty });
    await sleep(1500);
    if (mode === 'repeat') { await driver.click(MODE_DD); await sleep(1000); await driver.click(MODE_REPEAT); await sleep(1000); }
    for (const y of START_YS) {
      await driver.click({ x: START_X, y });
      await sleep(1300);
      const s = await save();
      if (s.economy.jobs.home !== undefined) { rec('job_started', { mode, titleY: ty, startY: y, job: s.economy.jobs.home }); return true; }
    }
    rec('job_start_failed', { mode, titleY: ty });
    await gotoMfg(cat);
  }
  rec('job_start_failed_all', { mode });
  return false;
}

async function waitFor(pred, ms, label) {
  const end = Date.now() + ms;
  while (Date.now() < end) {
    const s = await save();
    if (pred(s)) return s;
    await sleep(2500);
  }
  rec('wait_timeout', { label });
  return await save();
}

const t0 = Date.now();
let tick = 0;
try {
  driver.onConsoleLine(() => {});
  rec('run_start', {});
  let s = await save();
  rec('state_initial', { era: s.era, level: s.level, jobs: s.economy.jobs, stone_mid: rv(s, 'stone_mid'), formation_core: rv(s, 'formation_core') });
  await exportSave('save-000-initial');

  // Phase A: formation_core x1 (single batch, 20s)
  if (rv(s, 'formation_core') < 1) {
    if (await craftViaDetail(CAT_COMBINE, { x: 613, y: 220 }, 'single')) {
      s = await waitFor(x => rv(x, 'formation_core') >= 1 || x.economy.jobs.home === undefined, 180000, 'formation_core');
      rec('phase_a_done', { formation_core: rv(s, 'formation_core') });
    }
  }
  await exportSave('save-001-formation_core');
  await shot('010-after-formation');

  // Phase B: stone_mid continuous until >= 50
  s = await save();
  if (rv(s, 'stone_mid') < 50) {
    if (await craftViaDetail(CAT_REFINE, { x: 1006, y: 488 }, 'repeat')) {
      rec('phase_b_started', {});
      s = await waitFor(x => rv(x, 'stone_mid') >= 50, MAX_MS, 'stone_mid');
      rec('phase_b_done', { stone_mid: rv(s, 'stone_mid') });
    }
  }
  await exportSave('save-002-stone_mid');
  await shot('020-after-stone_mid');

  // Phase C: level up to era3 L2
  await gotoBuildings();
  await driver.click(P.dock_home);
  await sleep(1200);
  for (;;) {
    if (Date.now() - t0 > MAX_MS) { rec('budget_exit', {}); break; }
    tick++;
    s = await save();
    await driver.click(P.level_up);
    await sleep(400);
    if (tick % 12 === 0) rec('tick', { tick, era: s.era, level: s.level, lingli: rv(s, 'lingli'), money: rv(s, 'money'), stone_mid: rv(s, 'stone_mid'), formation_core: rv(s, 'formation_core'), liquid: rv(s, 'liquid'), jobs: s.economy.jobs });
    if (s.era !== 3 || s.level >= 2) { rec('phase_change', { era: s.era, level: s.level }); break; }
    if (tick % 20 === 0) { await exportSave('save-tick-' + tick); await shot('tick-' + tick); }
    await sleep(2000);
  }
  await exportSave('save-final');
  await shot('999-final');
  rec('run_end', { tick, s: await save().then(x => ({ era: x.era, level: x.level, lingli: rv(x, 'lingli'), money: rv(x, 'money'), stone_mid: rv(x, 'stone_mid'), formation_core: rv(x, 'formation_core'), liquid: rv(x, 'liquid'), jobs: x.economy.jobs })) });
} catch (e) {
  rec('run_error', { error: String(e && e.stack ? e.stack : e) });
  await shot('999-error');
} finally {
  await driver.close().catch(() => {});
  log.end();
  process.exit(0);
}
