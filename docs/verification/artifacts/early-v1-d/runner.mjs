import fs from 'node:fs';
import path from 'node:path';
import { connectDriver, summarizeSave, sleep } from '../res1d2-natural-mouse-driver.mjs';

const CDP_PORT = process.env.CDP_PORT || '9240';
const HTTP_PORT = process.env.HTTP_PORT || '4380';
const STEP_DIR = process.env.STEP_DIR || 'docs/verification/artifacts/early-v1-d';
const SAVE_DIR = path.join(STEP_DIR, 'saves');
const EVENTS_FILE = path.join(STEP_DIR, 'events.jsonl');
const GAME_URL = 'http://127.0.0.1:' + HTTP_PORT + '/index.html';
const RESET_SAVE = (process.env.RESET_SAVE || '1') !== '0';
const RUN_STEPS = process.env.RUN_STEPS || '';
const CLICK_INTERVAL_MS = Number(process.env.CLICK_INTERVAL_MS || 20000);
const SHOT_EVERY = Number(process.env.SHOT_EVERY_ATTEMPTS || 6);
const BUDGET_SCALE = Number(process.env.BUDGET_SCALE || 1);
const READY_TIMEOUT_MS = Number(process.env.READY_TIMEOUT_MS || 240000) * BUDGET_SCALE;
const ERA1_BUDGET_MS = Math.round(Number(process.env.ERA1_BUDGET_MS || 3000000) * BUDGET_SCALE);
const ERA2_BUDGET_MS = Math.round(Number(process.env.ERA2_BUDGET_MS || 5400000) * BUDGET_SCALE);
const SHORT_BUDGET_MS = Math.round(Number(process.env.SHORT_BUDGET_MS || 300000) * BUDGET_SCALE);
const CRAFT_BUDGET_MS = Math.round(Number(process.env.CRAFT_BUDGET_MS || 1500000) * BUDGET_SCALE);
const LIFESPAN_BUDGET_MS = Math.round(Number(process.env.LIFESPAN_BUDGET_MS || 50000000) * BUDGET_SCALE);

fs.mkdirSync(STEP_DIR, { recursive: true });
fs.mkdirSync(SAVE_DIR, { recursive: true });

let shotCounter = 0;
let eventsWritten = 0;
const eventStream = fs.createWriteStream(EVENTS_FILE, { flags: 'a' });
const consoleLines = [];

function record(type, data) {
  const ev = { utc: new Date().toISOString(), type, data: data || {} };
  eventStream.write(JSON.stringify(ev) + '\n');
  eventsWritten++;
}
function out(line) {
  process.stdout.write(line + '\n');
  record('stdout_line', { line });
}
function consoleHas(sub) {
  return consoleLines.some(l => typeof l === 'string' && l.includes(sub));
}

async function shot(driver, label) {
  shotCounter++;
  const file = path.join(STEP_DIR, 'step-' + String(shotCounter).padStart(3, '0') + '-' + label + '.png');
  try {
    await driver.screenshot(file);
    record('screenshot', { file, label });
    return file;
  } catch (e) {
    record('screenshot_error', { label, error: String(e && e.message ? e.message : e) });
    return null;
  }
}

function parseRunSteps() {
  if (!RUN_STEPS) return null;
  const keep = new Set();
  for (const token of RUN_STEPS.split(',')) {
    if (!token) continue;
    const m = token.match(/^(\d+)-(\d+)$/);
    if (m) { for (let i = Number(m[1]); i <= Number(m[2]); i++) keep.add(i); }
    else keep.add(Number(token));
  }
  return keep;
}

function game(cond) { return sum => Boolean(sum && !sum.empty && cond(sum)); }

function cycleOf(save) { return Number((save && save.state && save.state.reincarnation_count) || 0); }

function describeState(sum, save) {
  if (!sum || sum.empty) return 'empty';
  return 'era=' + sum.era + ' lv=' + sum.level + ' rev=' + sum.revision
    + ' cycle=' + cycleOf(save)
    + ' lingli=' + (sum.helpers ? sum.helpers.lingliVal.toFixed(0) : '?') + '/' + (sum.helpers ? sum.helpers.lingliCap.toFixed(0) : '?')
    + ' hut=' + (sum.buildings ? (sum.buildings.hut ?? '-') : '-');
}

const ERA_LIFESPAN_YEARS = { 1: 80, 2: 120, 3: 540 };
function lifespanCap(state) {
  if (!state) return 0;
  const era = Number(state.era_id || 1);
  let years = 0;
  for (let i = 1; i <= era; i++) years += (ERA_LIFESPAN_YEARS[i] !== undefined ? ERA_LIFESPAN_YEARS[i] : (i === 1 ? 80 : i * 100));
  const talents = state.talents || {};
  const pillEffects = state.pill_effects || {};
  const talentBonus = Number(talents.lifespan_extension || 0) * 0.1;
  const pillBonus = Number(pillEffects.lifespan_bonus_years || 0);
  return Math.floor(years * (1 + talentBonus) + pillBonus) * 60;
}
function elapsedSeconds(state) {
  if (!state) return 0;
  return Number(state.total_elapsed_seconds || 0);
}

async function dumpSave(driver, tag) {
  try {
    const save = await driver.readSave();
    const file = path.join(STEP_DIR, 'save-dump-' + tag + '.json');
    fs.writeFileSync(file, JSON.stringify(save, null, 2), 'utf8');
    record('save_dump', { file });
    return save;
  } catch (e) {
    record('save_dump_error', { tag, error: String(e && e.message ? e.message : e) });
    return null;
  }
}

async function exportSave(driver, tag) {
  try {
    const raw = await driver.evaluate(`(()=>{const ns='dao2_saves';let idx=null;try{idx=JSON.parse(localStorage.getItem(ns+':save_index')||'null')}catch(e){}const slot=(idx&&idx.active_slot)||'save_main';return {index:localStorage.getItem(ns+':save_index'), main:localStorage.getItem(ns+':'+slot), slot:slot};})()`);
    const file = path.join(SAVE_DIR, tag + '.json');
    fs.writeFileSync(file, raw.main || '', 'utf8');
    fs.writeFileSync(path.join(SAVE_DIR, tag + '.index.json'), raw.index || '', 'utf8');
    fs.writeFileSync(path.join(SAVE_DIR, 'latest.json'), raw.main || '', 'utf8');
    record('save_export', { file, tag, slot: raw.slot, bytes: (raw.main || '').length });
  } catch (e) {
    record('save_export_error', { tag, error: String(e && e.message ? e.message : e) });
  }
}

async function dismissModals(driver) {
  const candidates = [WAYPOINTS.popup_offline_close, WAYPOINTS.modal_collapse];
  for (const c of candidates) {
    try { await driver.click(c); } catch (e) { /* ignore */ }
    await sleep(400);
  }
}

async function recoverInput(driver, tag) {
  record('input_recovery', { tag });
  out('EARLYV1D: info detail=input_recovery tag=' + tag);
  try { await driver.bringToFront(); } catch (e) { /* ignore */ }
  await driver.reload();
  await driver.waitABODE_READY(90000);
  await sleep(5000);
  for (let i = 0; i < 3; i++) {
    try { await driver.click(WAYPOINTS.popup_offline_close); } catch (e) { /* ignore */ }
    await sleep(3000);
  }
  try { await driver.click(WAYPOINTS.modal_collapse); } catch (e) { /* ignore */ }
  await sleep(1500);
  await shot(driver, 'recovered-' + tag);
}

function makeStallTracker(tag) {
  let lastSig = '';
  let lastStall = Date.now();
  let reloads = 0;
  return {
    cleared() { lastStall = Date.now(); reloads = 0; },
    async poll(driver, sum) {
      const sig = describeState(sum).replace(/ rev=\d+/, '');
      if (sig !== lastSig) { lastSig = sig; lastStall = Date.now(); reloads = 0; return; }
      if (Date.now() - lastStall > 150000 && reloads < 6) {
        reloads++;
        lastStall = Date.now();
        await recoverInput(driver, tag + '-r' + reloads);
      }
    }
  };
}

async function clickLoop(driver, milestoneName, pointsIn, condFn, opts) {
  const pointList = Array.isArray(pointsIn) ? pointsIn : [pointsIn];
  const label = pointList.map(p => p && (p.log ? p.log : p.x + ',' + p.y)).join('|');
  const budgetMs = (opts && opts.budgetMs) || SHORT_BUDGET_MS;
  const intervalMs = (opts && opts.intervalMs) || CLICK_INTERVAL_MS;
  const wheel = (opts && opts.wheel) || null;
  const wheelEvery = (opts && opts.wheelEvery) || 0;
  const passive = !!(opts && opts.passive);
  const tracker = passive ? null : makeStallTracker(milestoneName);
  const start = Date.now();
  let attempt = 0;
  let polls = 0;
  for (;;) {
    const save = await driver.readSave();
    const sum = summarizeSave(save);
    if (condFn(sum, save)) {
      record('condition_met', { label: milestoneName, attempt, waitedMs: Date.now() - start, state: describeState(sum) });
      return sum;
    }
    if (Date.now() - start > budgetMs) {
      await shot(driver, milestoneName + '-timeout');
      await dumpSave(driver, milestoneName + '-timeout');
      throw new Error('budget exhausted: ' + milestoneName + ' waited=' + Math.round((Date.now() - start) / 1000) + 's last=' + describeState(sum));
    }
    polls++;
    if (tracker) await tracker.poll(driver, sum);
    if (polls % 4 === 0) {
      out('EARLYV1D: progress step=' + milestoneName + ' waited=' + Math.round((Date.now() - start) / 1000) + 's ' + describeState(sum));
      record('wait_progress', { step: milestoneName, waitedMs: Date.now() - start, attempt, state: describeState(sum) });
    }
    if (!passive) {
      attempt++;
      const p = pointList[(attempt - 1) % pointList.length];
      if (attempt === 1 || attempt % SHOT_EVERY === 0) await shot(driver, milestoneName + '-click' + attempt);
      record('click_attempt', { step: milestoneName, attempt, point: p, waitedMs: Date.now() - start });
      try {
        await driver.click(p);
      } catch (e) {
        record('click_error', { step: milestoneName, attempt, error: String(e && e.message ? e.message : e) });
      }
      if (wheelEvery > 0 && wheel && attempt % wheelEvery === 0) {
        try { await driver.wheel(wheel.point, wheel.delta); } catch (e) {
          record('wheel_error', { step: milestoneName, attempt, error: String(e && e.message ? e.message : e) });
        }
      }
      if (attempt % 10 === 0) await dismissModals(driver);
    }
    const rest = Math.min(intervalMs, 4000);
    await sleep(rest);
    if (intervalMs - rest > 0) await sleep(intervalMs - rest);
  }
}

const WAYPOINTS = {
  header_level_up: { x: 300, y: 67, log: 'CALIBRATED 2026-10-14 修為晉階 (identity card right button)' },
  header_breakthrough: { x: 352, y: 70, log: 'CALIBRATED 2026-10-16 natural run: breakthrough button at ~(352,70) produced era3 lv1 (own identity-card button 104x44)' },
  modal_collapse: { x: 882, y: 441, log: 'CALIBRATED 2026-10-14 system_modal 收起 button center' },
  dock_home: { x: 68, y: 627, log: 'CALIBRATED dock row y=627' },
  dock_management: { x: 164, y: 627, log: 'CALIBRATED dock row y=627' },
  dock_cultivation: { x: 264, y: 627, log: 'CALIBRATED dock row y=627 (修行 group -> 輪迴天賦 page)' },
  dock_journey: { x: 360, y: 627, log: 'CALIBRATED dock row y=627' },
  popup_offline_close: { x: 260, y: 284, log: 'CALIBRATED 2026-10-14 offline-summary-modal 關閉' },
  mini_gather: { x: 298, y: 362, log: 'CALIBRATED 2026-10-14 lingli-only row' },
  gather_lingli_rows: [ { x: 307, y: 289, log: 'fresh 3-row lingli chip' }, { x: 298, y: 362, log: '1-row lingli 採集' } ],
  gather_money: { x: 300, y: 336, log: 'CALIBRATED 3-row 金錢 採集 chip' },
  gather_wood: { x: 307, y: 378, log: 'CALIBRATED 3-row 靈木 採集 chip' },
  catalog_zhulingtan_build: { x: 1212, y: 317, log: 'ESTIMATE 聚靈壇 card build button' },
  catalog_muwu_build: { x: 995, y: 475, log: 'ESTIMATE 木屋 card build button' },
  panel_qty_tab: { x: 205, y: 317, log: 'CALIBRATED floating_panel_tab_數量' },
  world_hut_slot: { x: 517, y: 194, log: 'CALIBRATED world ghost-hut marker' },
  world_hut_banner: { x: 527, y: 291, log: 'CALIBRATED ghost-hut banner fallback' },
  nav_buildings: { x: 822, y: 46, log: 'management tab1' },
  nav_islands: { x: 906, y: 46, log: 'management tab2' },
  nav_manufacturing: { x: 990, y: 46, log: 'management tab3' },
  nav_transport: { x: 1074, y: 46, log: 'management tab4' },
  catalog_card_build_hut: { x: 902, y: 433, log: 'ESTIMATE core_row1_col1 build/upgrade button' },
  catalog_hut_upgrade: { x: 982, y: 311, log: 'CALIBRATED 茅屋卡升級' },
  catalog_card_upgrade_lingli: { x: 1196, y: 433, log: 'ESTIMATE storage_lingli upgrade' },
  catalog_storage_candidates: [
    { x: 902, y: 433, log: 'storage_col1_a' },
    { x: 902, y: 477, log: 'storage_col1_b' },
    { x: 902, y: 521, log: 'storage_col1_c' },
    { x: 902, y: 565, log: 'storage_col1_d' }
  ],
  island_selector_wood: { x: 926, y: 160, log: 'island selectors' },
  island_selector_ore: { x: 1026, y: 160, log: 'island selectors' },
  island_selector_herb: { x: 1126, y: 160, log: 'island selectors' },
  island_actions: [
    { x: 1070, y: 214, log: 'island body row1 open/activate' },
    { x: 1070, y: 258, log: 'island body row2' },
    { x: 1070, y: 302, log: 'island body row3' }
  ],
  island_wheel: { point: { x: 1070, y: 420 }, delta: 240 },
  catalog_wheel: { point: { x: 946, y: 400 }, delta: 240 },
  manufacturing_wheel: { point: { x: 850, y: 400 }, delta: 240 },
  transport_wheel: { point: { x: 620, y: 400 }, delta: 240 },
  manufacturing_action_scan: [
    { x: 1188, y: 190, log: 'recipe action a' },
    { x: 1188, y: 240, log: 'recipe action b' },
    { x: 1188, y: 390, log: 'recipe action c' },
    { x: 1188, y: 540, log: 'recipe action d' },
    { x: 800, y: 240, log: 'recipe title fallback' },
    { x: 800, y: 390, log: 'recipe title fallback postwheel' }
  ],
  transport_route_scan: [
    { x: 928, y: 232, log: 'route row actions' },
    { x: 928, y: 354, log: 'route row b' },
    { x: 928, y: 476, log: 'route row c' },
    { x: 928, y: 598, log: 'route row d' }
  ],
  transport_save_scan: [
    { x: 400, y: 540, log: 'route save button' },
    { x: 400, y: 596, log: 'route save low' }
  ],
  reincarnate_action: { x: 640, y: 600, log: 'COMPUTED panel bounds=(300,84,680,556); footer bottom-center action button (入定轉世/確認轉世) ~ (640,600)' },
  sequence_skip: { x: 1208, y: 46, log: 'COMPUTED ReincarnationSequence skip button top-right (margin24, 96x44)' },
  sequence_finish: { x: 640, y: 438, log: 'COMPUTED result-card finish button 重聚仙靈 center-bottom of centered box' }
};

function waitHomeLiquid(sum) {
  return Boolean(sum && !sum.empty && sum.resources.liquid && sum.resources.liquid.value >= 1);
}

const STEP_DEFS = [
  { name: 'S00_launch_blank', run: async driver => {
    await driver.bringToFront();
    if (RESET_SAVE) {
      const cleared = await driver.evaluate('(()=>{for(let i=localStorage.length-1;i>=0;i--)localStorage.removeItem(localStorage.key(i));return localStorage.length;})()');
      record('origin_cleared', { remaining: cleared });
      await driver.reload();
    } else {
      out('EARLYV1D: info detail=RESET_SAVE=0 keeping existing localStorage for resume');
      record('origin_kept', {});
    }
    await driver.waitFor(() => driver.evaluate('document.readyState').then(v => v === 'complete'), 60000, 500, 'load');
    await driver.waitABODE_READY(READY_TIMEOUT_MS);
    for (let i = 0; i < 3; i++) { await sleep(3000); try { await driver.click(WAYPOINTS.popup_offline_close); } catch (e) {} await sleep(1200); }
    await shot(driver, 'S00-ready');
    await exportSave(driver, 's00-blank-start');
    const sum = summarizeSave(await driver.readSave());
    if (sum.empty || sum.era !== 1 || sum.level !== 1) {
      await dumpSave(driver, 'S00-not-blank');
      throw new Error('S00 expected blank era1 lv1 state but got ' + describeState(sum));
    }
    out('EARLYV1D: milestone=S00_launch_blank ok ' + describeState(sum));
  } },
  { name: 'S01_hut_build', run: async driver => {
    await driver.click(WAYPOINTS.dock_management);
    await sleep(1500);
    await driver.click(WAYPOINTS.panel_qty_tab);
    await sleep(800);
    await shot(driver, 'S01-catalog-open');
    const start = Date.now();
    let idx = 0;
    while (Date.now() - start < SHORT_BUDGET_MS) {
      const sum = summarizeSave(await driver.readSave());
      if (!sum.empty && (sum.buildings.hut || 0) >= 1) break;
      try {
        if (idx % 4 === 3) await driver.click(WAYPOINTS.world_hut_slot);
        else await driver.click(WAYPOINTS.mini_gather);
      } catch (e) { record('click_error', { step: 'S01_gather', error: String(e && e.message ? e.message : e) }); }
      idx++;
      await sleep(900);
    }
    await shot(driver, 'S01-after-gather');
    const fin = summarizeSave(await driver.readSave());
    if ((fin.buildings.hut || 0) >= 1) { out('EARLYV1D: milestone=S01_hut_build ok hut=1'); await exportSave(driver, 's01-hut'); }
    else throw new Error('S01_hut_build timeout hut=' + (fin.buildings.hut ?? '?'));
  } },
  { name: 'S02_era1_level10', run: async driver => {
    const start = Date.now();
    let attempt = 0;
    let lastShot = 0;
    const tracker = makeStallTracker('S02_era1_level10');
    for (;;) {
      const sum = summarizeSave(await driver.readSave());
      if (!sum.empty && sum.era === 1 && sum.level >= 10) break;
      if (Date.now() - start > ERA1_BUDGET_MS) throw new Error('S02 budget exhausted ' + describeState(sum));
      attempt++;
      const woodVal = sum.resources && sum.resources.wood ? Number(sum.resources.wood.value) : 0;
      const m = attempt % 5;
      let p;
      if (woodVal < (sum.level >= 3 ? 40 : 20)) p = WAYPOINTS.gather_wood;
      else if (m === 0 || m === 1) p = WAYPOINTS.header_level_up;
      else if (m === 2) p = WAYPOINTS.catalog_zhulingtan_build;
      else p = WAYPOINTS.gather_money;
      record('click_attempt', { step: 'S02', attempt, point: p, level: sum.level });
      try { await driver.click(p); } catch (e) { record('click_error', { step: 'S02', error: String(e && e.message ? e.message : e) }); }
      try { await driver.click(WAYPOINTS.gather_lingli_rows[attempt % WAYPOINTS.gather_lingli_rows.length]); } catch (e) {}
      if (attempt % 12 === 0) await dismissModals(driver);
      await tracker.poll(driver, sum);
      if (Date.now() - lastShot > 30000) { await shot(driver, 'S02-progress-' + attempt); lastShot = Date.now(); }
      await sleep(Math.max(CLICK_INTERVAL_MS, 600));
    }
    out('EARLYV1D: milestone=S02_era1_level10 ok');
    await exportSave(driver, 's02-era1-lv10');
  } },
  { name: 'S03_era1_capacity', run: async driver => {
    const points = [WAYPOINTS.catalog_card_upgrade_lingli, WAYPOINTS.catalog_card_build_hut, ...WAYPOINTS.catalog_storage_candidates];
    await driver.click(WAYPOINTS.dock_management);
    await sleep(1500);
    await clickLoop(driver, 'S03_era1_capacity', points, game(s => s.era === 1 && s.helpers.lingliCap >= 500), {
      budgetMs: CRAFT_BUDGET_MS, wheelEvery: 4, wheel: WAYPOINTS.catalog_wheel
    });
  } },
  { name: 'S04_breakthrough_foundation', run: async driver => {
    await shot(driver, 'S04-before-breakthrough');
    await clickLoop(driver, 'S04_breakthrough', WAYPOINTS.header_breakthrough, game(s => s.era >= 2), { budgetMs: SHORT_BUDGET_MS });
    await sleep(12000);
    await shot(driver, 'S04-after-breakthrough');
    await exportSave(driver, 's04-era2');
  } },
  { name: 'S05_era2_capacity', run: async driver => {
    await driver.click(WAYPOINTS.dock_management);
    await sleep(1500);
    await clickLoop(driver, 'S05_storage_lingli2', WAYPOINTS.catalog_card_upgrade_lingli, game(s => (s.buildings.storage_lingli || 0) >= 2), { budgetMs: SHORT_BUDGET_MS });
    await clickLoop(driver, 'S05_foundation_reservoir2', WAYPOINTS.catalog_storage_candidates, game(s => (s.buildings.foundation_reservoir || 0) >= 2), {
      budgetMs: ERA2_BUDGET_MS, wheelEvery: 3, wheel: WAYPOINTS.catalog_wheel
    });
    await clickLoop(driver, 'S05_linglicap_2300', WAYPOINTS.dock_home, game(s => s.helpers.lingliCap >= 2300 && s.helpers.lingliVal >= 2000), { budgetMs: ERA2_BUDGET_MS, intervalMs: 30000, passive: true });
  } },
  { name: 'S06_economy_open_wood_ore', run: async driver => {
    await driver.click(WAYPOINTS.dock_management);
    await sleep(1000);
    await driver.click(WAYPOINTS.nav_islands);
    await sleep(1500);
    await clickLoop(driver, 'S06_economy_enable', WAYPOINTS.island_actions, game(s => s.economy.version > 0), { budgetMs: SHORT_BUDGET_MS });
    const woodPoints = [...WAYPOINTS.island_actions, WAYPOINTS.island_selector_wood, WAYPOINTS.island_actions[0]];
    await clickLoop(driver, 'S06_open_wood', woodPoints, game(s => Boolean(s.economy.islands.wood && s.economy.islands.wood.opened)), { budgetMs: CRAFT_BUDGET_MS });
    const orePoints = [...WAYPOINTS.island_actions, WAYPOINTS.island_selector_ore, WAYPOINTS.island_actions[1]];
    await clickLoop(driver, 'S06_open_ore', orePoints, game(s => Boolean(s.economy.islands.ore && s.economy.islands.ore.opened)), { budgetMs: CRAFT_BUDGET_MS });
    await exportSave(driver, 's06-economy');
  } },
  { name: 'S07_era2_level10', run: async driver => {
    await clickLoop(driver, 'S07_era2_level10', WAYPOINTS.header_level_up, game(s => s.era === 2 && s.level >= 10), { budgetMs: ERA2_BUDGET_MS });
    await exportSave(driver, 's07-era2-lv10');
  } },
  { name: 'S08_breakthrough_gold', run: async driver => {
    await shot(driver, 'S08-before-breakthrough');
    await clickLoop(driver, 'S08_breakthrough_gold', WAYPOINTS.header_breakthrough, game(s => s.era >= 3), { budgetMs: SHORT_BUDGET_MS });
    await sleep(12000);
    await shot(driver, 'S08-after-breakthrough');
    await exportSave(driver, 's08-era3-golden');
  } },
  { name: 'S09_open_herb', run: async driver => {
    await driver.click(WAYPOINTS.dock_management);
    await sleep(1000);
    await driver.click(WAYPOINTS.nav_islands);
    await sleep(1500);
    await driver.click(WAYPOINTS.island_selector_herb);
    await sleep(1200);
    await shot(driver, 'S09-herb-selected');
    await clickLoop(driver, 'S09_open_herb', WAYPOINTS.island_actions, game(s => Boolean(s.economy.islands.herb && s.economy.islands.herb.opened)), {
      budgetMs: CRAFT_BUDGET_MS, wheelEvery: 5, wheel: WAYPOINTS.island_wheel
    });
  } },
  { name: 'S10_route_liquid_home', run: async driver => {
    await driver.click(WAYPOINTS.nav_transport);
    await sleep(1500);
    await shot(driver, 'S10-transport-panel');
    await clickLoop(driver, 'S10_route_liquid_home', [...WAYPOINTS.transport_route_scan, ...WAYPOINTS.transport_save_scan], game(s => s.economy.routes.includes('liquid_home')), {
      budgetMs: CRAFT_BUDGET_MS, wheelEvery: 4, wheel: WAYPOINTS.transport_wheel
    });
  } },
  { name: 'S11_craft_liquid', run: async driver => {
    await driver.click(WAYPOINTS.nav_manufacturing);
    await sleep(1500);
    await shot(driver, 'S11-manufacturing-panel');
    await clickLoop(driver, 'S11_craft_liquid', WAYPOINTS.manufacturing_action_scan, game(s => Boolean(s.economy.jobs.herb) || s.economy.trips.liquid_home > 0), {
      budgetMs: CRAFT_BUDGET_MS, wheelEvery: 4, wheel: WAYPOINTS.manufacturing_wheel
    });
    await clickLoop(driver, 'S11_liquid_delivered', WAYPOINTS.dock_home, game(s => waitHomeLiquid(s)), { budgetMs: CRAFT_BUDGET_MS, intervalMs: 30000, passive: true });
  } },
  { name: 'S12_formation_core_stone_mid', run: async driver => {
    await driver.click(WAYPOINTS.dock_management);
    await sleep(1000);
    await driver.click(WAYPOINTS.nav_manufacturing);
    await sleep(1500);
    await shot(driver, 'S12-manufacturing-home');
    await clickLoop(driver, 'S12_craft_formation_core', WAYPOINTS.manufacturing_action_scan, game(s => s.resources.formation_core && s.resources.formation_core.value >= 1), {
      budgetMs: CRAFT_BUDGET_MS, wheelEvery: 4, wheel: WAYPOINTS.manufacturing_wheel
    });
    await clickLoop(driver, 'S12_craft_stone_mid', WAYPOINTS.manufacturing_action_scan, game(s => s.resources.stone_mid && s.resources.stone_mid.value >= 1), {
      budgetMs: CRAFT_BUDGET_MS, wheelEvery: 4, wheel: WAYPOINTS.manufacturing_wheel
    });
  } },
  { name: 'S13_era3_first_level_up', run: async driver => {
    const before = await dumpSave(driver, 'S13-before');
    const b = summarizeSave(before);
    await clickLoop(driver, 'S13_era3_level_up', WAYPOINTS.header_level_up, game(s => s.era === 3 && s.level > b.level), { budgetMs: ERA2_BUDGET_MS });
    const after = summarizeSave(await driver.readSave());
    const consumed = after.resources.formation_core.value < b.resources.formation_core.value
      || after.resources.liquid.value < b.resources.liquid.value
      || after.resources.stone_mid.value < b.resources.stone_mid.value
      || after.helpers.lingliVal < b.helpers.lingliVal;
    if (!consumed) throw new Error('S13 no consumption before=' + describeState(b) + ' after=' + describeState(after));
    out('EARLYV1D: milestone=S13_golden_first_level_up ok level=' + after.level);
    await exportSave(driver, 's13-golden-first-levelup');
  } },
  { name: 'S14_reload_persistence', run: async driver => {
    const before = summarizeSave(await driver.readSave());
    record('reload_baseline', { state: describeState(before) });
    await driver.reload();
    await driver.waitFor(() => driver.evaluate('document.readyState').then(v => v === 'complete'), 60000, 500, 'reload complete');
    await driver.waitABODE_READY(READY_TIMEOUT_MS);
    const after = summarizeSave(await driver.readSave());
    const ok = Boolean(!after.empty && after.era === before.era && after.level >= before.level && after.revision >= before.revision
      && Boolean(after.economy.islands.herb && after.economy.islands.herb.opened) === Boolean(before.economy.islands.herb && before.economy.islands.herb.opened));
    await shot(driver, 'S14-after-reload');
    if (!ok) { await dumpSave(driver, 'S14-mismatch'); throw new Error('S14 reload mismatch before=' + describeState(before) + ' after=' + describeState(after)); }
    await exportSave(driver, 's14-postreload');
  } },
  { name: 'S15_wait_lifespan_exhaustion', run: async driver => {
    const start = Date.now();
    let lastShot = 0;
    for (;;) {
      const save = await driver.readSave();
      const sum = summarizeSave(save);
      const cap = lifespanCap(save.state);
      const elapsed = elapsedSeconds(save.state);
      if (!sum.empty && cap > 0 && elapsed >= cap) {
        out('EARLYV1D: milestone=S15_lifespan_exhausted ok elapsed=' + elapsed.toFixed(0) + '/' + cap + ' era=' + sum.era);
        break;
      }
      if (Date.now() - start > LIFESPAN_BUDGET_MS) throw new Error('S15 lifespan wait budget exhausted ' + describeState(sum));
      if (Date.now() - lastShot > 120000) {
        out('EARLYV1D: progress step=S15_lifespan waited=' + Math.round((Date.now() - start) / 1000) + 's elapsed=' + elapsed.toFixed(0) + '/' + cap + ' ' + describeState(sum));
        await shot(driver, 'S15-progress');
        await exportSave(driver, 's15-progress');
        lastShot = Date.now();
      }
      await sleep(30000);
    }
    await shot(driver, 'S15-exhausted');
    await exportSave(driver, 's15-exhausted');
  } },
  { name: 'S16_first_reincarnation', run: async driver => {
    await dismissModals(driver);
    try { await driver.click(WAYPOINTS.dock_cultivation); } catch (e) {}
    await sleep(2500);
    await shot(driver, 'S16-panel');
    await clickLoop(driver, 'S16_reincarnate_confirm', WAYPOINTS.reincarnate_action, (s, save) => Boolean(s && !s.empty && cycleOf(save) >= 1), {
      budgetMs: SHORT_BUDGET_MS, intervalMs: 3500
    });
    await sleep(2500);
    await shot(driver, 'S16-sequence');
    for (let i = 0; i < 4; i++) { try { await driver.click(WAYPOINTS.sequence_skip); } catch (e) {} await sleep(1500); }
    await shot(driver, 'S16-result-card');
    for (let i = 0; i < 5; i++) { try { await driver.click(WAYPOINTS.sequence_finish); } catch (e) {} await sleep(1500); }
    try { await driver.click(WAYPOINTS.sequence_finish); } catch (e) {}
    await sleep(2000);
    await driver.reload();
    await driver.waitABODE_READY(READY_TIMEOUT_MS);
    await sleep(4000);
    for (let i = 0; i < 3; i++) { try { await driver.click(WAYPOINTS.popup_offline_close); } catch (e) {} await sleep(1500); }
    await shot(driver, 'S16-after-reincarnation');
    const save = await driver.readSave();
    const sum = summarizeSave(save);
    if (cycleOf(save) < 1 || sum.era !== 1) {
      await dumpSave(driver, 'S16-failed');
      throw new Error('S16 reincarnation not observed: ' + describeState(sum, save));
    }
    out('EARLYV1D: milestone=S16_first_reincarnation ok cycle=' + cycleOf(save));
    await exportSave(driver, 's16-second-life-start');
  } },
  { name: 'S17_second_life_supply', run: async driver => {
    await driver.click(WAYPOINTS.dock_management);
    await sleep(1500);
    await driver.click(WAYPOINTS.panel_qty_tab);
    await sleep(800);
    const start = Date.now();
    let idx = 0;
    while (Date.now() - start < ERA1_BUDGET_MS) {
      const sum = summarizeSave(await driver.readSave());
      if (!sum.empty && sum.era === 1 && (sum.buildings.hut || 0) >= 1) break;
      try {
        if (idx % 4 === 3) await driver.click(WAYPOINTS.world_hut_slot);
        else await driver.click(WAYPOINTS.mini_gather);
      } catch (e) {}
      idx++;
      await sleep(900);
    }
    const fin = summarizeSave(await driver.readSave());
    await shot(driver, 'S17-second-life');
    if ((fin.buildings.hut || 0) < 1) throw new Error('S17 second-life hut not built: ' + describeState(fin));
    out('EARLYV1D: milestone=S17_second_life_supply ok ' + describeState(fin));
    await exportSave(driver, 's17-second-life-operable');
  } },
  { name: 'S18_final_persistence', run: async driver => {
    const bSave = await driver.readSave();
    const before = summarizeSave(bSave);
    await driver.reload();
    await driver.waitABODE_READY(READY_TIMEOUT_MS);
    const aSave = await driver.readSave();
    const after = summarizeSave(aSave);
    await shot(driver, 'S18-final');
    await exportSave(driver, 's18-final');
    if (after.empty || cycleOf(aSave) !== cycleOf(bSave)) {
      await dumpSave(driver, 'S18-mismatch');
      throw new Error('S18 persistence mismatch before=' + describeState(before, bSave) + ' after=' + describeState(after, aSave));
    }
    out('EARLYV1D: milestone=S18_final_persistence ok ' + describeState(after, aSave));
  } }
];

async function main() {
  out('EARLYV1D: start config cdp=' + CDP_PORT + ' http=' + HTTP_PORT + ' stepDir=' + STEP_DIR);
  record('run_start', { cdpPort: CDP_PORT, httpPort: HTTP_PORT, resetSave: RESET_SAVE, runSteps: RUN_STEPS });
  const keep = parseRunSteps();
  const driver = await connectDriver({
    cdpPort: Number(CDP_PORT),
    debugPrinter: line => out('EARLYV1D: info detail=' + line)
  });
  driver.onConsoleLine(line => { consoleLines.push(String((line && line.text) || line)); if (consoleLines.length > 4000) consoleLines.shift(); });
  try { await driver.send('Emulation.setFocusEmulationEnabled', { enabled: true }); } catch (e) { record('focus_emulation_error', { error: String(e) }); }
  const runList = STEP_DEFS.map((def, index) => ({ def, index })).filter(x => !keep || keep.has(x.index));
  out('EARLYV1D: info detail=runList=' + runList.map(x => x.def.name).join(','));
  for (const item of runList) {
    const name = item.def.name;
    const t0 = Date.now();
    out('EARLYV1D: info detail=step_begin ' + name);
    record('step_start', { name, index: item.index });
    try {
      await item.def.run(driver);
      const sum = summarizeSave(await driver.readSave());
      out('EARLYV1D: milestone=' + name + ' ok=true detail=done_in=' + Math.round((Date.now() - t0) / 1000) + 's ' + describeState(sum));
      record('step_done', { name, index: item.index, ms: Date.now() - t0 });
    } catch (e) {
      const msg = String(e && e.message ? e.message : e);
      record('step_error', { name, index: item.index, error: msg, ms: Date.now() - t0 });
      try { await shot(driver, 'FAIL-' + name); await dumpSave(driver, 'FAIL-' + name); await exportSave(driver, 'FAIL-' + name); } catch {}
      out('EARLYV1D: milestone=' + name + ' ok=false detail=' + msg);
      out('EARLYV1D: fatal step=' + name + ' evidence_dir=' + STEP_DIR + ' events=' + EVENTS_FILE);
      await new Promise(resolve => eventStream.end(resolve));
      process.exit(1);
    }
  }
  record('run_done', { stepsRun: runList.length, events: eventsWritten });
  out('EARLYV1D: done detail=steps=' + runList.length + ' events=' + eventsWritten + ' jsonl=' + EVENTS_FILE);
  await new Promise(resolve => eventStream.end(resolve));
  process.exit(0);
}

main().catch(async e => {
  const msg = String(e && e.message ? e.message : e);
  record('fatal', { error: msg });
  out('EARLYV1D: fatal error=' + msg + ' evidence_dir=' + STEP_DIR);
  await new Promise(resolve => eventStream.end(resolve));
  process.exit(1);
});
