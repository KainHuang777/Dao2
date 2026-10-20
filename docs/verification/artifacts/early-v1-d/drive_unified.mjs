import fs from 'node:fs';
import path from 'node:path';
import { connectDriver, summarizeSave, sleep } from '../res1d2-natural-mouse-driver.mjs';

// Single uninterrupted session: blank save -> era1 Lv10 -> era2 (islands+shipping) -> era3 golden core Lv2.
// Real CDP mouse only. No reload during the milestone, no Debug, no resource/time injection.

const CDP_PORT = Number(process.env.CDP_PORT || '9242');
const HTTP_PORT = process.env.HTTP_PORT || '4380';
const DIR = process.env.DIR || 'docs/verification/artifacts/early-v1-d/unified-run';
const MAX_MS = Number(process.env.MAX_MS || 7200000);
const T0 = Date.now();
fs.mkdirSync(DIR, { recursive: true });
const log = fs.createWriteStream(path.join(DIR, 'events.jsonl'), { flags: 'a' });
function rec(type, data) {
  const line = JSON.stringify({ utc: new Date().toISOString(), t: Math.round((Date.now() - T0) / 1000), type, data: data || {} });
  log.write(line + '\n');
  console.log(line);
}

const P = {
  offline_close: { x: 278, y: 287 },
  tutorial_collapse: { x: 799, y: 448 },
  dock_home: { x: 85, y: 666 },
  dock_management: { x: 175, y: 666 },
  ribbon_full: { x: 286, y: 272 },
  level_up_era1: { x: 323, y: 75 },
  level_up: { x: 278, y: 82 },
  breakthrough_era1: { x: 252, y: 112 },
  breakthrough_era2: { x: 254, y: 114 },
  cinematic_skip: { x: 1200, y: 84 },
  summary_restart: { x: 582, y: 650 },
  summary_done: { x: 700, y: 650 },
};
const GATHER = {
  lingli: { x: 298, y: 326 },
  money: { x: 298, y: 393 },
  wood: { x: 298, y: 456 },
  stone_low: { x: 298, y: 519 },
};
const BUILD_TAB = { all: { x: 754, y: 214 }, produce: { x: 960, y: 214 }, storage: { x: 1161, y: 214 } };
const BUILD_BTN = {
  hut: { x: 908, y: 328 }, storage_lingli: { x: 1214, y: 297 }, wooden_house: { x: 908, y: 451 },
  forest_farm: { x: 1212, y: 451 }, stone_mine: { x: 905, y: 573 }, herb_farm: { x: 1213, y: 573 },
};
const NEEDS = [['hut', 2], ['wooden_house', 2], ['forest_farm', 3], ['stone_mine', 3], ['herb_farm', 3], ['storage_lingli', 1]];
const COSTS = {
  hut: { lingli: 20 }, wooden_house: { money: 20, lingli: 30 }, forest_farm: { money: 20, lingli: 20 },
  stone_mine: { wood: 10, money: 20 }, herb_farm: { stone_low: 10, wood: 20 }, storage_lingli: { money: 50, wood: 20 },
};
const CF = { hut: 1.5, wooden_house: 1.45, forest_farm: 1.5, stone_mine: 1.5, herb_farm: 1.7, storage_lingli: 1.2 };
const PREREQ = { wooden_house: { hut: 2 }, forest_farm: { wooden_house: 2 }, stone_mine: { forest_farm: 3 }, herb_farm: { stone_mine: 3 }, storage_lingli: { herb_farm: 3 } };
const TABS = {
  buildings: { buildings: 770, outposts: 875, manufacturing: 951, transport: 1038 },
  outposts: { buildings: 770, outposts: 875, manufacturing: 951, transport: 1038 },
  manufacturing: { buildings: 519, outposts: 630, manufacturing: 697, transport: 782 },
  transport: { buildings: 297, outposts: 391, manufacturing: 479, transport: 558 },
};
const ISLAND_TAB = { home: 916, wood: 988, ore: 1053, herb: 1132 };
const OPEN_BTN = [{ x: 1070, y: 436 }, { x: 1063, y: 428 }, { x: 1070, y: 424 }, { x: 1070, y: 448 }];
const CAT = { all: { x: 758, y: 214 }, produce: { x: 950, y: 214 }, storage: { x: 1154, y: 214 } };
const RESERVOIR_BUILD = { x: 909, y: 543 };
const MFG = { all: { x: 1010, y: 127 }, refine: { x: 1095, y: 127 }, combine: { x: 1155, y: 127 } };
const MODE_DD = { x: 855, y: 468 };
const MODE_REPEAT = { x: 560, y: 596 };
const START_X = 848;
const START_YS = [577, 560, 600, 620, 640, 540, 660, 512, 690];

const driver = await connectDriver({ cdpPort: CDP_PORT, matchPort: HTTP_PORT, debugPrinter: () => {} });
driver.onConsoleLine(l => { if (l.text.includes('OFFLINE_SETTLEMENT') || l.text.includes('STORAGE_') || l.text.includes('ABODE_READY')) rec('console', { text: l.text.slice(0, 200) }); });

const save = async () => summarizeSave(await driver.readSave());
function rv(s, id) { const r = s.resources[id]; return r ? Number(r.value) : 0; }
async function shot(label) { try { await driver.screenshot(path.join(DIR, 'shot-' + label + '.png')); } catch (e) {} }
async function exportSave(tag) {
  try {
    const r = await driver.evaluate(`(()=>{const ns='dao2_saves';let idx=null;try{idx=JSON.parse(localStorage.getItem(ns+':save_index')||'null')}catch(e){}const slot=(idx&&idx.active_slot)||'save_main';return {index:localStorage.getItem(ns+':save_index'),main:localStorage.getItem(ns+':'+slot)};})()`);
    fs.writeFileSync(path.join(DIR, tag + '.json'), r.main || '', 'utf8');
    fs.writeFileSync(path.join(DIR, tag + '.index.json'), r.index || '', 'utf8');
    const m = JSON.parse(r.main || '{}');
    return { revision: m.revision, settled_until_utc_ms: m.settled_until_utc_ms, report: m.last_offline_report };
  } catch (e) { rec('export_error', { tag, error: String(e) }); return null; }
}
async function rawMeta() {
  const r = await driver.evaluate(`(()=>{const ns='dao2_saves';let idx=null;try{idx=JSON.parse(localStorage.getItem(ns+':save_index')||'null')}catch(e){}const slot=(idx&&idx.active_slot)||'save_main';const m=localStorage.getItem(ns+':'+slot);const o=m?JSON.parse(m):{};return {slot,revision:o.revision,settled:o.settled_until_utc_ms,report:o.last_offline_report};})()`);
  return r;
}
async function dismissAll() { for (let i = 0; i < 3; i++) { try { await driver.click(P.offline_close); } catch (e) {} await sleep(300); } }
async function settleCinematics() { for (const p of [P.cinematic_skip, P.summary_done, P.summary_restart]) { try { await driver.click(p); } catch (e) {} await sleep(400); } }

let page = null;
async function openMgmt(target) {
  await dismissAll();
  await driver.click(P.dock_management); await sleep(1300);
  if (page === null) page = 'buildings';
  if (target !== page) {
    const x = TABS[page][target];
    await driver.click({ x, y: 46 }); await sleep(1100);
    page = target;
  }
}
async function goHome() { await driver.click(P.dock_home); await sleep(1000); }

async function clickUntil(pred, points, opts = {}) {
  const { triesPerPoint = 2, timeoutMs = 60000, label = 'clickUntil', afterEach = null } = opts;
  const end = Date.now() + timeoutMs;
  let i = 0;
  while (Date.now() < end) {
    const pt = points[i % points.length];
    await driver.click(pt); await sleep(700);
    if (afterEach) await afterEach();
    const s = await save();
    if (pred(s)) return s;
    i++;
    if (i > points.length * triesPerPoint * 3) break;
  }
  rec('clickUntil_fail', { label });
  return null;
}

try {
  rec('run_start', { cdp: CDP_PORT, http: HTTP_PORT });
  await driver.bringToFront();
  await driver.waitABODE_READY(180000);
  const head = await rawMeta();
  rec('head', head);
  await exportSave('save-head');
  let s = await save();
  rec('state_initial', { era: s.era, level: s.level, revision: s.revision, empty: s.empty });
  await shot('000-head');

  // ---- Phase 1: Era1 build chain to Lv10, then breakthrough ----
  await driver.click(P.tutorial_collapse); await sleep(600); // collapse onboarding text if present
  await openMgmt('buildings');
  let tick = 0, lastExport = 0, lastShot = 0;
  for (;;) {
    if (Date.now() - T0 > MAX_MS) { rec('era1_budget_exit', {}); break; }
    tick++;
    s = await save();
    if (s.era >= 2) { rec('era1_done', { era: s.era, level: s.level }); break; }
    if (tick % 20 === 0) rec('era1_tick', { tick, lv: s.level, lingli: rv(s, 'lingli'), money: rv(s, 'money'), wood: rv(s, 'wood'), stone_low: rv(s, 'stone_low'), buildings: Object.fromEntries(Object.entries(s.buildings).filter(([k, v]) => v > 0)) });

    if (s.level >= 10) {
      // breakthrough attempt
      await goHome(); await sleep(300);
      await driver.click(P.breakthrough_era1); await sleep(1200);
      await settleCinematics();
      const s2 = await save();
      if (s2.era >= 2) { rec('era1_breakthrough_ok', { era: s2.era }); s = s2; break; }
      await openMgmt('buildings');
      continue;
    }

    await driver.click(P.ribbon_full); await sleep(250);
    await driver.click(BUILD_TAB.all); await sleep(250);
    let need = null;
    for (const [id, lv] of NEEDS) { if ((s.buildings[id] || 0) < lv) { need = [id, lv]; break; } }
    if (need) {
      const [id] = need; const cur = s.buildings[id] || 0;
      const cost = {}; for (const [r, v] of Object.entries(COSTS[id])) cost[r] = Math.floor(v * Math.pow(CF[id], cur));
      const pre = PREREQ[id] || {};
      const preMet = Object.entries(pre).every(([b, n]) => (s.buildings[b] || 0) >= n);
      const afford = Object.entries(cost).every(([r, v]) => rv(s, r) >= v);
      if (preMet && afford) {
        await driver.click(BUILD_BTN[id]); await sleep(650);
        rec('era1_build', { id, from: cur });
      } else {
        let best = null, bestFrac = Infinity;
        for (const r of Object.keys(cost)) {
          if (!GATHER[r]) continue;
          const have = rv(s, r); const frac = cost[r] > 0 ? have / cost[r] : Infinity;
          if (frac < bestFrac) { bestFrac = frac; best = r; }
        }
        if (best) { await driver.click(GATHER[best]); await sleep(220); }
      }
    } else {
      await driver.click(GATHER.lingli); await sleep(220); // capacity-boost phase: keep lingli for level-up costs
    }
    await driver.click(P.level_up_era1); await sleep(300);

    if (Date.now() - lastShot > 60000) { lastShot = Date.now(); await shot('era1-' + tick); }
    if (Date.now() - lastExport > 300000) { lastExport = Date.now(); await exportSave('save-era1-' + tick); }
    await sleep(180);
  }
  await exportSave('save-001-era2-enter');
  await shot('010-era2-enter');
  if (s.era < 2) throw new Error('era1 did not complete');

  // ---- Phase 2: Era2 islands + shipping + foundation_reservoir + Lv10 + breakthrough ----
  rec('era2_begin', { level: s.level, economyVersion: s.economy.version });
  // open islands wood then ore
  for (const island of ['wood', 'ore']) {
    s = await save();
    if (s.economy.islands[island] && s.economy.islands[island].opened) continue;
    await openMgmt('outposts');
    await driver.click({ x: ISLAND_TAB[island], y: 179 }); await sleep(900);
    const got = await clickUntil(x => x.economy.islands[island] && x.economy.islands[island].opened, OPEN_BTN, { label: 'open_' + island, timeoutMs: 90000 });
    rec('open_island', { island, ok: !!got });
    await goHome();
  }
  s = await save();
  rec('era2_islands', { islands: s.economy.islands, version: s.economy.version });

  // enable routes for cross-check: ore_wood (stone to wood), timber_home (timber to home), bronze_home (bronze to home)
  await openMgmt('transport');
  const routeBtn = { left: 467, right: 865, y1: 251, y2: 377, y3: 501 };
  const routePlan = [['ore_wood', routeBtn.right, routeBtn.y1], ['timber_home', routeBtn.left, routeBtn.y2], ['bronze_home', routeBtn.right, routeBtn.y2], ['wood_ore', routeBtn.left, routeBtn.y1]];
  for (const [rid, x, y] of routePlan) {
    const has = await save();
    if (has.economy.routes.includes(rid)) { rec('route_already', { rid }); continue; }
    const got = await clickUntil(r => r.economy.routes.includes(rid), [{ x, y }, { x, y: y - 20 }, { x, y: y + 20 }, { x: x + 30, y: y - 20 }], { label: 'route_' + rid, timeoutMs: 60000 });
    rec('route_enable', { rid, ok: !!got });
  }
  await exportSave('save-002-routes');
  await shot('020-routes');
  await goHome();

  // manufacturing: build reservoir L1->L2, start continuous timber@wood + bronze@ore
  await openMgmt('buildings');
  await driver.click(BUILD_TAB.storage); await sleep(900);
  for (let i = 0; i < 40; i++) {
    s = await save();
    if ((s.buildings.foundation_reservoir || 0) >= 2) break;
    await driver.click(RESERVOIR_BUILD); await sleep(700);
    await driver.click({ x: RESERVOIR_BUILD.x, y: RESERVOIR_BUILD.y + 60 }); await sleep(700);
  }
  rec('reservoir', { level: (await save()).buildings.foundation_reservoir });

  async function startContinuous(recipe, titleX, titleY, island) {
    for (let attempt = 0; attempt < 4; attempt++) {
      let cur = await save();
      if (cur.economy.jobs[island] !== undefined && cur.economy.jobs[island] >= 0) { rec('job_present', { island }); return true; }
      await openMgmt('manufacturing');
      await driver.click({ x: titleX, y: titleY }); await sleep(1300);
      await driver.click(MODE_DD); await sleep(800);
      await driver.click(MODE_REPEAT); await sleep(800);
      for (const y of START_YS) {
        await driver.click({ x: START_X, y }); await sleep(1100);
        cur = await save();
        if (cur.economy.jobs[island] !== undefined) { rec('job_started', { island, recipe, y }); return true; }
      }
      await goHome();
    }
    rec('job_start_failed', { island, recipe });
    return false;
  }
  await startContinuous('spirit_timber', 1006, 220, 'wood');
  await startContinuous('bronze_essence', 613, 220, 'ore');
  // stop home liquid if running (keep home line for later stone_mid)
  await goHome();

  // cross-check loop during era2 passive: verify island stock grows, trips deliver to home
  const checkStart = await save();
  rec('xcheck_begin', {
    woodInv: checkStart.economy ? null : null,
    jobs: checkStart.economy.jobs, routes: checkStart.economy.routes,
    trips: checkStart.economy.trips,
  });
  lastExport = 0; lastShot = 0;
  let era2Start = Date.now();
  for (;;) {
    if (Date.now() - T0 > MAX_MS) { rec('era2_budget_exit', {}); break; }
    tick++;
    s = await save();
    if (s.era >= 3) { rec('era2_done', { era: s.era, level: s.level }); break; }
    await driver.click(P.level_up); await sleep(350);

    if (s.level >= 10 && s.era === 2) {
      await goHome(); await sleep(300);
      await driver.click(P.breakthrough_era2); await sleep(1400);
      await settleCinematics();
      const s2 = await save();
      if (s2.era >= 3) { rec('era2_breakthrough_ok', { era: s2.era }); s = s2; break; }
      rec('era2_breakthrough_blocked', { level: s2.level, ecoVer: s2.economy.version });
      await sleep(1500);
      continue;
    }

    if (tick % 40 === 0) {
      const raw = await rawMeta();
      rec('era2_tick', { tick, lv: s.level, lingli: rv(s, 'lingli'), money: rv(s, 'money'), jobs: s.economy.jobs, routes: s.economy.routes, trips: s.economy.trips, woodTimber: (s.economy.islands.wood ? 'iso' : ''), rev: raw.revision });
      // restart missing jobs
      if (s.economy.jobs.wood === undefined) await startContinuous('spirit_timber', 1006, 220, 'wood');
      if (s.economy.jobs.ore === undefined) await startContinuous('bronze_essence', 613, 220, 'ore');
      await goHome();
    }
    if (Date.now() - lastShot > 90000) { lastShot = Date.now(); await shot('era2-' + tick); }
    if (Date.now() - lastExport > 300000) { lastExport = Date.now(); await exportSave('save-era2-' + tick); }
    await sleep(1600);
  }
  await exportSave('save-003-era3-enter');
  await shot('030-era3-enter');
  if (s.era < 3) throw new Error('era2 did not complete');

  // ---- Phase 3: Era3 formation_core x1 + stone_mid >= 50 + level to 2 ----
  s = await save();
  rec('era3_begin', { level: s.level, formation_core: rv(s, 'formation_core'), stone_mid: rv(s, 'stone_mid'), liquid: rv(s, 'liquid') });
  async function craftOnce(titleX, titleY, island, mode) {
    for (let attempt = 0; attempt < 4; attempt++) {
      let cur = await save();
      if (cur.economy.jobs[island] !== undefined) { rec('job_present', { island }); return true; }
      await openMgmt('manufacturing');
      await driver.click({ x: titleX, y: titleY }); await sleep(1300);
      if (mode === 'repeat') { await driver.click(MODE_DD); await sleep(800); await driver.click(MODE_REPEAT); await sleep(800); }
      for (const y of START_YS) {
        await driver.click({ x: START_X, y }); await sleep(1100);
        cur = await save();
        if (cur.economy.jobs[island] !== undefined) { rec('craft_started', { island, y, mode }); return true; }
      }
      await goHome();
    }
    return false;
  }
  if (rv(s, 'formation_core') < 1) {
    await craftOnce(613, 220, 'home', 'single');
    await clickUntil(x => rv(x, 'formation_core') >= 1 || x.economy.jobs.home === undefined, [{ x: 700, y: 400 }], { label: 'wait_formation', timeoutMs: 120000, afterEach: async () => {} }).catch(() => {});
    await goHome();
  }
  rec('formation_core', { value: rv(await save(), 'formation_core') });
  await exportSave('save-004-formation');
  if (rv(await save(), 'stone_mid') < 50) {
    await craftOnce(1006, 488, 'home', 'repeat');
  }
  for (;;) {
    if (Date.now() - T0 > MAX_MS) break;
    s = await save();
    if (rv(s, 'stone_mid') >= 50) { rec('stone_mid_ready', { value: rv(s, 'stone_mid') }); break; }
    if (s.economy.jobs.home === undefined) { await craftOnce(1006, 488, 'home', 'repeat'); }
    await sleep(3000);
  }
  await exportSave('save-005-stone_mid');
  await shot('040-stone_mid');
  await goHome();

  // ensure liquid >= 1 (produce at home if recipe available, else it may already exist)
  s = await save();
  if (rv(s, 'liquid') < 1) { rec('liquid_low', { value: rv(s, 'liquid') }); }

  // level up era3 L1 -> L2
  lastExport = 0; lastShot = 0;
  for (;;) {
    if (Date.now() - T0 > MAX_MS) { rec('era3_budget_exit', {}); break; }
    s = await save();
    if (s.era === 3 && s.level >= 2) break;
    await driver.click(P.level_up); await sleep(400);
    if (tick % 15 === 0) { const raw = await rawMeta(); rec('era3_tick', { tick, lv: s.level, lingli: rv(s, 'lingli'), money: rv(s, 'money'), stone_mid: rv(s, 'stone_mid'), formation_core: rv(s, 'formation_core'), liquid: rv(s, 'liquid'), rev: raw.revision }); }
    if (Date.now() - lastExport > 120000) { lastExport = Date.now(); await exportSave('save-era3-' + tick); }
    tick++;
    await sleep(1800);
  }
  s = await save();
  rec('milestone', { era: s.era, level: s.level, lingli: rv(s, 'lingli'), money: rv(s, 'money'), stone_mid: rv(s, 'stone_mid'), formation_core: rv(s, 'formation_core'), liquid: rv(s, 'liquid'), routes: s.economy.routes, trips: s.economy.trips });
  await exportSave('save-final');
  await shot('999-milestone');

  const tail = await rawMeta();
  rec('tail', tail);
  rec('run_end_ok', {});
} catch (e) {
  rec('run_error', { error: String(e && e.stack ? e.stack : e) });
  await shot('999-error');
} finally {
  await driver.close().catch(() => {});
  log.end();
  process.exit(0);
}
