import fs from 'node:fs';
import path from 'node:path';
import { connectDriver, summarizeSave, sleep } from '../res1d2-natural-mouse-driver.mjs';

const CDP_PORT = Number(process.env.CDP_PORT || '9242');
const HTTP_PORT = Number(process.env.HTTP_PORT || '4380');
const DIR = process.env.DIR || 'docs/verification/artifacts/early-v1-d/unified-run';
const MAX_MS = Number(process.env.MAX_MS || 7200000);
const BASE_URL = 'http://127.0.0.1:' + HTTP_PORT + '/index.html';
fs.mkdirSync(DIR, { recursive: true });
const log = fs.createWriteStream(path.join(DIR, 'events.jsonl'), { flags: 'a' });
function rec(type, data) { const line = JSON.stringify({ utc: new Date().toISOString(), type, data: data || {} }); log.write(line + '\n'); console.log(line); }
const t0 = Date.now();
const elapsed = () => ((Date.now() - t0) / 1000).toFixed(0);

const P = {
  offline_close: { x: 278, y: 287 },
  dock_home: { x: 85, y: 666 },
  dock_management: { x: 175, y: 666 },
  ribbon_full: { x: 286, y: 272 },
  level_up_era1: { x: 323, y: 75 },
  level_up: { x: 278, y: 82 },
  breakthrough_era1: { x: 252, y: 112 },
  breakthrough_era2: { x: 254, y: 114 },
  cinematic_skip: { x: 1200, y: 84 },
  summary_restart: { x: 582, y: 650 },
  summary_done: { x: 700, y: 650 }
};
const TAB_Y = 46;
const TABS_FROM_BUILDINGS = { buildings: 770, outposts: 875, manufacturing: 951, transport: 1038 };
const TO_BUILDINGS_X = [297, 519, 770];
const BUILD_TAB_ERA2 = { all: { x: 950, y: 214 }, produce: { x: 1064, y: 214 }, storage: { x: 1182, y: 214 } };
const LINGLI_UPGRADE = { x: 1214, y: 427 };
const RESERVOIR_BUILD = { x: 1214, y: 510 };
const ISLAND_TAB = { home: { x: 908, y: 177 }, wood: { x: 986, y: 177 }, ore: { x: 1064, y: 177 }, herb: { x: 1152, y: 177 } };
const OPEN_BTN = { x: 1062, y: 429 };
const ROUTE_BTN = {
  wood_ore: { x: 470, y: 277 }, ore_wood: { x: 877, y: 291 },
  timber_home: { x: 470, y: 429 }, bronze_home: { x: 877, y: 429 },
  grass_home: { x: 470, y: 555 }, herb_home: { x: 877, y: 555 },
  liquid_home: { x: 470, y: 680 }
};
async function enableRoute(rid) {
  const routes0 = (await st()).economy.routes || {};
  if (routes0[rid] && routes0[rid].enabled) { rec('route_already', { rid }); return true; }
  for (let attempt = 0; attempt < 6; attempt++) {
    await gotoPage('transport');
    const b = ROUTE_BTN[rid];
    for (const dy of [0, -14, 14, -28, 28]) {
      const cur = (await st()).economy.routes || {};
      if (cur[rid] && cur[rid].enabled) { rec('route_enable', { rid, attempt, dy }); return true; }
      await click({ x: b.x, y: b.y + dy }, 1000);
    }
  }
  rec('route_enable_failed', { rid });
  return false;
}
const MFG_CAT = { all: { x: 1004, y: 126 }, refine: { x: 1100, y: 126 }, combine: { x: 1164, y: 126 } };
const TITLE = {
  bronze_essence_ore: { x: 614, y: 223 }, spirit_timber_wood: { x: 986, y: 223 },
  liquid_home: { x: 616, y: 424 }, stone_mid_home: { x: 988, y: 424 },
  formation_core_home: { x: 614, y: 223 }
};
const MODE_DD = { x: 855, y: 468 };
const MODE_REPEAT = { x: 560, y: 596 };
const START_X = 848;
const START_YS = [574, 577, 602, 586, 560, 610, 620, 590, 640, 660, 690, 700];
const ERA3_TITLE = {
  formation_core: [{ x: 614, y: 223 }, { x: 986, y: 223 }],
  stone_mid: [{ x: 986, y: 464 }, { x: 986, y: 424 }, { x: 1006, y: 488 }, { x: 986, y: 444 }]
};

let driver, page = 'home';
const shot = async (label) => { try { const f = path.join(DIR, 'shot-' + label + '.png'); await driver.screenshot(f); return f; } catch (e) { return null; } };
const rawEnv = () => driver.readSave();
const sum = async () => summarizeSave(await rawEnv());
const rv = (s, id) => { const r = s.resources[id]; return r ? Number(r.value) : 0; };
const st = async () => (await rawEnv()).state || {};

async function exportSave(tag) {
  try {
    const r = await driver.evaluate(`(()=>{const ns='dao2_saves';let idx=null;try{idx=JSON.parse(localStorage.getItem(ns+':save_index')||'null')}catch(e){}const slot=(idx&&idx.active_slot)||'save_main';return {index:localStorage.getItem(ns+':save_index'),main:localStorage.getItem(ns+':'+slot)};})()`);
    fs.writeFileSync(path.join(DIR, tag + '.json'), r.main || '', 'utf8');
    fs.writeFileSync(path.join(DIR, tag + '.index.json'), r.index || '', 'utf8');
    let meta = null;
    try { const e = JSON.parse(r.main); meta = { revision: e.revision, settled_until_utc_ms: e.settled_until_utc_ms, saved_at_utc_ms: e.saved_at_utc_ms, report: e.last_offline_report }; } catch {}
    rec('export', { tag, revision: meta && meta.revision, settled_until: meta && meta.settled_until_utc_ms, report_away_ms: meta && meta.report && meta.report.away_ms });
    return meta;
  } catch (e) { rec('export_error', { tag, error: String(e) }); return null; }
}

async function dismissAll() { for (let i = 0; i < 3; i++) { try { await driver.click(P.offline_close); } catch {} await sleep(350); } }
async function settleCinematics() { for (const p of [P.cinematic_skip, P.summary_done, P.summary_done, P.cinematic_skip]) { try { await driver.click(p); } catch {} await sleep(800); } }

async function click(p, d = 700) { await driver.click(p); await sleep(d); }
async function gotoBuildings() {
  await driver.bringToFront();
  await click(P.dock_home, 900);
  await click(P.dock_management, 1500);
  for (const x of TO_BUILDINGS_X) { await click({ x, y: TAB_Y }, 700); }
  page = 'buildings';
}
async function gotoPage(target) {
  if (target === 'buildings') { await gotoBuildings(); return; }
  await gotoBuildings();
  await click({ x: TABS_FROM_BUILDINGS[target], y: TAB_Y }, 1500);
  page = target;
}
async function goHome() { await click(P.dock_home, 900); page = 'home'; }
async function synthScroll(times = 14) {
  await driver.evaluate(`(()=>{const c=document.querySelector('canvas');for(let i=0;i<${times};i++){c.dispatchEvent(new WheelEvent('wheel',{deltaY:120,deltaX:0,bubbles:true,cancelable:true}));}return true;})()`);
  await sleep(700);
}
async function clickUntil(point, pred, { maxTries = 12, delay = 1400, label = '' } = {}) {
  for (let i = 0; i < maxTries; i++) {
    await driver.click(point); await sleep(delay);
    const s = await sum();
    if (pred(s)) { rec('click_ok', { label, tries: i + 1 }); return s; }
  }
  rec('click_fail', { label, point });
  return await sum();
}

const savedPts = {};
async function startJob(island, titlePts, cat, wantRepeat = true) {
  for (let attempt = 0; attempt < 3; attempt++) {
    await gotoPage('manufacturing');
    if (cat) { await click(MFG_CAT[cat], 1200); }
    for (const tp of titlePts) {
      await click(tp, 2500);
      await click(MODE_DD, 1300);
      await click(MODE_REPEAT, 1300);
      for (const y of START_YS) {
        await click({ x: START_X, y }, 1200);
        const s2 = await st();
        const job = s2.economy && s2.economy.jobs && s2.economy.jobs[island];
        if (job) {
          rec('job_started', { island, title: tp, startY: y, wantRepeat, repeat: job.repeat, job });
          if (!wantRepeat || job.repeat) return true;
          rec('job_repeat_missing', { island, attempt });
          break;
        }
      }
      rec('job_start_miss', { island, title: tp });
    }
  }
  rec('job_start_failed', { island });
  return !!(await st()).economy.jobs[island];
}

async function stopJob(island, pts) {
  for (let a = 0; a < 3; a++) {
    await gotoPage('manufacturing');
    for (const p of pts) {
      const j0 = (await st()).economy.jobs[island];
      if (!j0) return true;
      await click(p, 1300);
      const j1 = (await st()).economy.jobs[island];
      if (!j1 || j1.repeat === false) { rec('job_stop', { island, p }); return true; }
    }
  }
  rec('job_stop_failed', { island });
  return false;
}

async function main() {
  driver = await connectDriver({ cdpPort: CDP_PORT, matchPort: HTTP_PORT });
  driver.onConsoleLine(l => { if (/OFFLINE_SETTLEMENT|STORAGE_|ABODE_READY|SAVE_|失败|失敗/.test(l.text)) rec('console', { text: l.text.slice(0, 300) }); });
  await driver.bringToFront();
  rec('run_start', { cdp: CDP_PORT, http: HTTP_PORT, url: driver.pageUrl });
  await dismissAll();
  let s = await sum();
  rec('state_initial', { era: s.era, level: s.level, rev: s.revision, islands: s.economy.islands, routes: s.economy.routes, jobs: s.economy.jobs });
  await exportSave('save-resume');
  await shot('000-resume');

  if (s.era === 1) { rec('era1_required', {}); throw new Error('era1 not expected in this run'); }

  if (s.era === 2) {
    rec('phase_era2_begin', { level: s.level });
    // 1. lingli cap: storage_lingli -> 2 then foundation_reservoir -> 2
    await gotoPage('buildings'); await click(BUILD_TAB_ERA2.all, 900);
    s = await clickUntil(LINGLI_UPGRADE, x => (x.buildings.storage_lingli || 0) >= 2, { label: 'storage_lingli2' });
    await shot('010-storage'); await exportSave('save-era2-storage');
    for (let i = 0; i < 10; i++) {
      const b0 = (await sum()).buildings;
      if ((b0.foundation_reservoir || 0) >= 2) break;
      await gotoBuildings();
      await click(BUILD_TAB_ERA2.storage, 1100);
      await click({ x: 1100, y: 620 }, 400);
      await synthScroll(40);
      await shot('011-scroll-' + i);
      let done = false;
      for (const y of [510, 500, 520, 490, 530, 540, 470]) {
        await click({ x: 1212, y }, 1800);
        const b2 = (await sum()).buildings;
        if ((b2.foundation_reservoir || 0) >= 2) { done = true; break; }
      }
      if (done) break;
    }
    s = await sum();
    rec('reservoir_done', { foundation_reservoir: s.buildings.foundation_reservoir, storage_lingli: s.buildings.storage_lingli, era: s.era, level: s.level });
    await shot('012-reservoir'); await exportSave('save-era2-reservoir');

    // 2. open islands wood + ore
    for (const isl of ['wood', 'ore']) {
      s = await sum();
      if (s.economy.islands[isl] && s.economy.islands[isl].opened) { rec('island_already', { isl }); continue; }
      await gotoPage('outposts');
      await click(ISLAND_TAB[isl], 1200);
      await shot('020-island-' + isl);
      s = await clickUntil(OPEN_BTN, x => x.economy.islands[isl] && x.economy.islands[isl].opened, { label: 'open_' + isl });
      rec('island_opened', { isl, ok: !!(s.economy.islands[isl] && s.economy.islands[isl].opened) });
    }

    // 3. enable routes ore_wood, timber_home, bronze_home (skip if already enabled)
    for (const rid of ['ore_wood', 'timber_home', 'bronze_home']) { await enableRoute(rid); }
    await shot('030-transport');
    await exportSave('save-era2-routes');

    // 4a. liquid@home only until >=40, then STOP it (it drains lingli needed for level-ups)
    if (rv(await sum(), 'liquid') < 40) {
      await startJob('home', [TITLE.liquid_home], null);
      for (let i = 0; i < 80; i++) { const ss = await sum(); if (rv(ss, 'liquid') >= 40) break; await sleep(3000); }
      rec('liquid_ready', { v: rv(await sum(), 'liquid') });
    }
    {
      const jh = (await st()).economy.jobs.home;
      if (jh && jh.recipe_id === 'liquid') {
        await stopJob('home', [{ x: 792, y: 424 }, { x: 792, y: 488 }, { x: 792, y: 452 }, { x: 792, y: 516 }, { x: 792, y: 380 }]);
        await shot('040-liquid');
      }
    }
    // 4b. bronze_essence@ore; then spirit_timber@wood after stone_low arrives
    await startJob('ore', [TITLE.bronze_essence_ore], null);
    await shot('041-jobs');
    // wait for stone_low to reach wood island
    for (let i = 0; i < 40; i++) {
      const raw = (await rawEnv()).state;
      const inv = raw.economy.islands.wood.inventory || {};
      const v = Number((inv.stone_low && (inv.stone_low.value !== undefined ? inv.stone_low.value : inv.stone_low)) || 0);
      if (v >= 6) { rec('wood_stone_low_ready', { value: v }); break; }
      await sleep(3000);
    }
    await startJob('wood', [TITLE.spirit_timber_wood], null);
    await shot('042-jobs');
    await exportSave('save-era2-jobs');

    // 5. passive loop to era2 lv10
    let tick = 0; let lastRefresh = 0; let btTries = 0;
    for (;;) {
      if (Date.now() - t0 > MAX_MS) { rec('budget_exit_era2', {}); break; }
      tick++;
      s = await sum();
      if (tick % 20 === 0) rec('tick_era2', { t: elapsed(), tick, era: s.era, level: s.level, lingli: rv(s, 'lingli'), money: rv(s, 'money'), spirit_timber: rv(s, 'spirit_timber'), bronze: rv(s, 'bronze_essence'), liquid: rv(s, 'liquid'), jobs: s.economy.jobs });
      if (s.era !== 2) { rec('era2_change', { era: s.era, level: s.level }); break; }
      if (s.level >= 10) {
        btTries++;
        if (btTries > 30) { rec('era2_breakthrough_giveup', { lingli: rv(s, 'lingli'), building: s.buildings.foundation_reservoir, storage_lingli: s.buildings.storage_lingli }); break; }
        await click(P.breakthrough_era2, 1400);
        await click(P.level_up, 900);
        const s3 = await sum();
        if (s3.era === 3) { rec('era2_breakthrough_ok', { level: s3.level }); await settleCinematics(); break; }
        await sleep(1200); continue;
      }
      await click(P.level_up, 900);
      if (Date.now() - lastRefresh > 20000) {
        lastRefresh = Date.now();
        const routes = (await st()).economy.routes || {};
        for (const rid of ['ore_wood', 'timber_home', 'bronze_home']) if (!(routes[rid] && routes[rid].enabled)) { rec('route_refresh', { rid }); await enableRoute(rid); }
        const jobs = (await st()).economy.jobs || {};
        if (!jobs.ore) await startJob('ore', [TITLE.bronze_essence_ore], null);
        if (!jobs.wood) await startJob('wood', [TITLE.spirit_timber_wood], null);
        await goHome();
        await exportSave('save-era2-tick-' + tick);
        await shot('era2-' + tick);
      }
      await sleep(1500);
    }
    await shot('050-era2-end'); await exportSave('save-era2-end');
  }

  s = await sum();
  if (s.era === 3) {
    rec('phase_era3_begin', { level: s.level });
    // open herb island (丹霞島)
    if (!(s.economy.islands.herb && s.economy.islands.herb.opened)) {
      await gotoPage('outposts'); await click(ISLAND_TAB.herb, 1200); await shot('060-island-herb');
      s = await clickUntil(OPEN_BTN, x => x.economy.islands.herb && x.economy.islands.herb.opened, { label: 'open_herb' });
      rec('island_herb_opened', { ok: !!(s.economy.islands.herb && s.economy.islands.herb.opened) });
    }
    // enable herb routes for four-island cross-check (grass_home, liquid_home)
    for (const rid of ['grass_home', 'liquid_home']) { await enableRoute(rid); }
    await shot('061-transport-era3'); await exportSave('save-era3-routes');

    // formation_core x1 at home (合成)
    s = await sum();
    if (rv(s, 'formation_core') < 1) {
      await gotoPage('manufacturing'); await click(MFG_CAT.combine, 1200);
      for (const tp of ERA3_TITLE.formation_core) {
        await click(tp, 1600);
        for (const y of START_YS) { await click({ x: START_X, y }, 1200); const j = (await st()).economy.jobs || {}; if (j.home) break; }
        const jj = (await st()).economy.jobs || {}; if (jj.home) break;
        await gotoPage('manufacturing'); await click(MFG_CAT.combine, 1200);
      }
      for (let i = 0; i < 60; i++) { const ss = await sum(); if (rv(ss, 'formation_core') >= 1 || !ss.economy.jobs.home) break; await sleep(3000); }
      rec('formation_core', { v: rv(await sum(), 'formation_core') });
    }
    await shot('070-formation'); await exportSave('save-era3-formation');

    // stone_mid >= 50 at home (精鍊)
    await gotoPage('manufacturing'); await click(MFG_CAT.refine, 1200);
    for (const tp of ERA3_TITLE.stone_mid) {
      await click(tp, 1700);
      await click(MODE_DD, 1000); await click(MODE_REPEAT, 1000);
      for (const y of START_YS) { await click({ x: START_X, y }, 1200); const j = (await st()).economy.jobs || {}; if (j.home) { rec('stone_mid_job', { title: tp, y }); break; } }
      const jj = (await st()).economy.jobs || {}; if (jj.home) break;
      await gotoPage('manufacturing'); await click(MFG_CAT.refine, 1200);
    }
    for (let i = 0; i < 320; i++) {
      const ss = await sum();
      if (i % 10 === 0) rec('stone_mid_wait', { t: elapsed(), v: rv(ss, 'stone_mid'), jobs: ss.economy.jobs });
      if (rv(ss, 'stone_mid') >= 55) break;
      await sleep(3000);
    }
    await shot('080-stone_mid'); await exportSave('save-era3-stone_mid');

    // level up to era3 L2 (golden core)
    await goHome();
    let t2 = 0;
    for (;;) {
      if (Date.now() - t0 > MAX_MS) { rec('budget_exit_era3', {}); break; }
      t2++;
      s = await sum();
      if (t2 % 10 === 0) rec('tick_era3', { t: elapsed(), era: s.era, level: s.level, lingli: rv(s, 'lingli'), money: rv(s, 'money'), stone_mid: rv(s, 'stone_mid'), formation_core: rv(s, 'formation_core'), liquid: rv(s, 'liquid') });
      await click(P.level_up, 900);
      const s4 = await sum();
      if (s4.era === 3 && s4.level >= 2) { rec('golden_core_ok', { era: s4.era, level: s4.level }); break; }
      if (t2 % 30 === 0) { await exportSave('save-era3-tick-' + t2); await shot('era3-' + t2); }
      await sleep(2500);
    }
    await shot('090-era3-final'); await exportSave('save-tail');
  }

  // cross-check snapshot
  const envT = await rawEnv();
  rec('final', { era: (await sum()).era, level: (await sum()).level, rev: envT.revision, islands: (await sum()).economy.islands, routes: (await sum()).economy.routes, jobs: (await sum()).economy.jobs });
  rec('run_end', { t: elapsed() });
} 

try { await main(); }
catch (e) { rec('run_error', { error: String(e && e.stack ? e.stack : e) }); try { await shot('999-error'); } catch {} }
finally { try { await driver.close(); } catch {} log.end(); process.exit(0); }
