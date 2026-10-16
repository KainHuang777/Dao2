import fs from 'node:fs';
import path from 'node:path';
import { connectDriver, summarizeSave, sleep } from './res1d2-natural-mouse-driver.mjs';

const CDP_PORT = process.env.CDP_PORT || '9225';
const HTTP_PORT = process.env.HTTP_PORT || '4277';
const STEP_DIR = process.env.STEP_DIR || 'docs/verification/artifacts/res1d2-natural-mouse';
const EVENTS_FILE = path.join(STEP_DIR, 'res1d2-natural-mouse-events.jsonl');
const GAME_URL = 'http://127.0.0.1:' + HTTP_PORT + '/index.html';
const RESET_SAVE = (process.env.RESET_SAVE || '1') !== '0';
const RUN_STEPS = process.env.RUN_STEPS || '';
const CLICK_INTERVAL_MS = Number(process.env.CLICK_INTERVAL_MS || 20000);
const SHOT_EVERY = Number(process.env.SHOT_EVERY_ATTEMPTS || 6);
const BUDGET_SCALE = Number(process.env.BUDGET_SCALE || 1);
const READY_TIMEOUT_MS = Number(process.env.READY_TIMEOUT_MS || 180000) * BUDGET_SCALE;
const ERA1_BUDGET_MS = Math.round(Number(process.env.ERA1_BUDGET_MS || 2000000) * BUDGET_SCALE);
const ERA2_BUDGET_MS = Math.round(Number(process.env.ERA2_BUDGET_MS || 3400000) * BUDGET_SCALE);
const SHORT_BUDGET_MS = Math.round(Number(process.env.SHORT_BUDGET_MS || 240000) * BUDGET_SCALE);
const CRAFT_BUDGET_MS = Math.round(Number(process.env.CRAFT_BUDGET_MS || 1200000) * BUDGET_SCALE);

fs.mkdirSync(STEP_DIR, { recursive: true });

let shotCounter = 0;
let eventsWritten = 0;
const eventStream = fs.createWriteStream(EVENTS_FILE, { flags: 'a' });

function record(type, data) {
  const ev = { utc: new Date().toISOString(), type, data: data || {} };
  eventStream.write(JSON.stringify(ev) + '\n');
  eventsWritten++;
}
function out(line) {
  process.stdout.write(line + '\n');
  record('stdout_line', { line });
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

function describeState(sum) {
  if (!sum || sum.empty) return 'empty';
  return 'era=' + sum.era + ' lv=' + sum.level + ' rev=' + sum.revision
    + ' lingli=' + (sum.helpers ? sum.helpers.lingliVal.toFixed(0) : '?') + '/' + (sum.helpers ? sum.helpers.lingliCap.toFixed(0) : '?')
    + ' hut=' + (sum.buildings.hut ?? '-') + ' storage_lingli=' + (sum.buildings.storage_lingli ?? '-')
    + ' reservoir=' + (sum.buildings.foundation_reservoir ?? '-');
}

async function dumpSave(driver, tag) {
  try {
    const save = await driver.readSave();
    const file = path.join(STEP_DIR, 'save-dump-' + tag + '.json');
    fs.writeFileSync(file, JSON.stringify(save, null, 2), 'utf8');
    record('save_dump', { file });
  } catch (e) {
    record('save_dump_error', { tag, error: String(e && e.message ? e.message : e) });
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
  out('D2NATURAL: info detail=input_recovery tag=' + tag);
  try { await driver.bringToFront(); } catch (e) { /* ignore */ }
  await driver.reload();
  await driver.waitABODE_READY(60000);
  await sleep(5000);
  for (let i = 0; i < 3; i++) {
    try { await driver.click(WAYPOINTS.popup_offline_close); } catch (e) { /* ignore */ }
    await sleep(3000);
  }
  try { await driver.click(WAYPOINTS.modal_collapse); } catch (e) { /* ignore */ }
  await sleep(1500);
  try { await driver.click(WAYPOINTS.panel_qty_tab); } catch (e) { /* ignore */ }
  await sleep(1000);
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
      if (Date.now() - lastStall > 120000 && reloads < 5) {
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
    if (condFn(sum)) {
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
      out('D2NATURAL: progress step=' + milestoneName + ' waited=' + Math.round((Date.now() - start) / 1000) + 's ' + describeState(sum));
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
      const gatherEvery = (opts && opts.gatherEvery) || 0;
      if (gatherEvery > 0 && attempt % gatherEvery === 0) {
        const gp = WAYPOINTS.gather_lingli_rows[attempt % WAYPOINTS.gather_lingli_rows.length];
        try { await driver.click(gp); } catch (e) { /* ignore */ }
      }
      if (attempt % 10 === 0) await dismissModals(driver);
    }
    await sleep(Math.min(intervalMs, 4000));
    const rest = intervalMs - 4000;
    if (rest > 0) await sleep(rest);
  }
}

const WAYPOINTS = {
  header_level_up: { x: 300, y: 67, log: 'CALIBRATED 2026-10-14 修為晉階 red button right of identity card(prev_176,68_did_noop_inside_card)' },
  header_breakthrough: { x: 284, y: 68, log: 'STALE_ESTIMATE still uncalibrated; verify at S04 with screenshots' },
  modal_collapse: { x: 882, y: 441, log: 'CALIBRATED 2026-10-14 system_modal 收起 button center (preview 1042,521 → ×0.8462); verified collapsed modal into banner after reload' },
  dock_home: { x: 68, y: 627, log: 'CALIBRATED 2026-10-14 observed dock_row_y=627(canvas_css_1257x669_scale_0.9291666)' },
  dock_management: { x: 164, y: 627, log: 'CALIBRATED dock row y=627 spacing ~96' },
  dock_cultivation: { x: 264, y: 627, log: 'CALIBRATED dock row y=627' },
  dock_journey: { x: 360, y: 627, log: 'CALIBRATED dock row y=627 docking overview' },
  popup_offline_close: { x: 260, y: 284, log: 'CALIBRATED 2026-10-14 offline-summary-modal 關閉 clicked_and_closed(prev_256,260_missed_high)' },
  mini_gather: { x: 298, y: 362, log: 'CALIBRATED 2026-10-14 NOTE row y drifts with unlocked resource rows: lingli-only row y=362; with 3 rows lingli 採集 at ~(314,318) — runner should wake panel per state' },
  gather_lingli_rows: [ { x: 307, y: 289, log: 'CALIBRATED 2026-10-14 fresh 3-row layout lingli row1 chip (preview 342 → ×0.8462); noop when 已滿' }, { x: 298, y: 362, log: 'CALIBRATED 1-row layout lingli 採集' } ],
  gather_money: { x: 300, y: 336, log: 'CALIBRATED 2026-10-14 fresh 3-row layout 金錢 採集 chip (preview 395 → ×0.8462) verified money 0→1 receipts 23→24; again later money rose further' },
  gather_wood: { x: 307, y: 378, log: 'CALIBRATED 2026-10-14 fresh 3-row layout 靈木 採集 chip (preview 447 → ×0.8462) verified wood 3→4→5→9 across spaced clicks; wood gather is chunky/cooldown-bound — clicks at <5s spacing often register nothing' },
  catalog_zhulingtan_build: { x: 1212, y: 317, log: 'ESTIMATE 聚靈壇 card top-right button (observed 材料不足 chip zone 1253,299-317; after materials enough becomes 建造) — verify via screenshot' },
  catalog_muwu_build: { x: 995, y: 475, log: 'ESTIMATE 木屋 card button row (needs money20+lingli30)' },
  panel_qty_tab: { x: 205, y: 317, log: 'CALIBRATED 2026-10-14 floating_panel_tab_數量_center(reveal_resource_row)' },
  world_hut_slot: { x: 517, y: 194, log: 'CALIBRATED 2026-10-14 world ghost-hut marker click hut 0→1 (lingli full); old (450,548) noop due modal/or moved camera; known-risk: position may drift with camera' },
  world_hut_banner: { x: 527, y: 291, log: 'CALIBRATED 2026-10-14 「點擊建造茅屋」 banner fallback; also near ghost' },
  nav_buildings: { x: 822, y: 46, log: 'management_bar_nav_width_min(560,1280-320-56)_x704(feature_navigation.gd:350-352)_tabs80min_sep4(358)' },
  nav_islands: { x: 906, y: 46, log: 'management_bar_tab2_outposts' },
  nav_manufacturing: { x: 990, y: 46, log: 'management_bar_tab3_manufacturing' },
  nav_transport: { x: 1074, y: 46, log: 'management_bar_tab4_transport' },
  catalog_scroll_zone: { x: 946, y: 400, log: 'building_catalog_bounds_644,84,620,544(feature_navigation.gd:364-366,width_min(620,1280-280))' },
  gather_lingli: { x: 298, y: 289, log: 'CALIBRATED 2026-10-14 mini_gather_button_floating_panel verified rev+1 lingli+1' },
  gather_stone: { x: 298, y: 289, log: 'CALIBRATED same_floating_row' },
  gather_herb: { x: 298, y: 289, log: 'CALIBRATED same_floating_row' },
  catalog_card_build_hut: { x: 902, y: 433, log: 'core_row1_col1_upgrade_button_64x44_right_of_materials_row(building_catalog.gd:297-372)_first_card_top_403' },
  catalog_hut_upgrade: { x: 982, y: 311, log: 'CALIBRATED 2026-10-14 營造簿全部tab 茅屋卡升級按鈕 (verified hut 1→2, lingli -17.7)' },
  catalog_card_upgrade_lingli: { x: 1196, y: 433, log: 'core_row1_col2_storage_lingli_upgrade' },
  catalog_storage_candidates: [
    { x: 902, y: 433, log: 'storage_col1_estimated_row_position_a' },
    { x: 902, y: 477, log: 'storage_col1_position_b' },
    { x: 902, y: 521, log: 'storage_col1_position_c' },
    { x: 902, y: 565, log: 'storage_col1_position_d' }
  ],
  island_selector_wood: { x: 926, y: 160, log: 'island_panel_bounds_864,84,400,544(feature_navigation.gd:333-334)_selectors_HFlow_buttons_100min(island_management_panel.gd:72-78)' },
  island_selector_ore: { x: 1026, y: 160, log: 'island_selectors_button2' },
  island_selector_herb: { x: 1126, y: 160, log: 'island_selectors_button3' },
  island_actions: [
    { x: 1070, y: 214, log: 'island_body_first_row_activate_open_buttons(island_management_panel.gd:140-145,195-208)' },
    { x: 1070, y: 258, log: 'island_body_row2_candidates' },
    { x: 1070, y: 302, log: 'island_body_row3_candidates' }
  ],
  island_wheel: { point: { x: 1070, y: 420 }, delta: 240 },
  catalog_wheel: { point: { x: 946, y: 400 }, delta: 240 },
  manufacturing_wheel: { point: { x: 850, y: 400 }, delta: 240 },
  transport_wheel: { point: { x: 620, y: 400 }, delta: 240 },
  manufacturing_action_scan: [
    { x: 1188, y: 190, log: 'manufacturing_rect_444,84,820,544(feature_navigation.gd:333-341)_card_action_button_min112_right(manufacturing_panel.gd:78-81)' },
    { x: 1188, y: 240, log: 'recipe_row_scan_b' },
    { x: 1188, y: 390, log: 'recipe_row_scan_c_postwheel' },
    { x: 1188, y: 540, log: 'recipe_row_scan_d_postwheel' },
    { x: 800, y: 240, log: 'recipe_title_select_fallback' },
    { x: 800, y: 390, log: 'recipe_title_select_fallback_postwheel' }
  ],
  transport_route_scan: [
    { x: 928, y: 232, log: 'transport_rect_300,84,680,544(feature_navigation.gd:333-334)_route_row_actions_right_64min(island_transport_panel.gd:84-89)' },
    { x: 928, y: 354, log: 'route_row_scan_b' },
    { x: 928, y: 476, log: 'route_row_scan_c' },
    { x: 928, y: 598, log: 'route_row_scan_d' }
  ],
  transport_save_scan: [
    { x: 400, y: 540, log: 'route_detail_save_button_candidates(island_transport_panel.gd:123-135)' },
    { x: 400, y: 596, log: 'route_detail_save_button_low' }
  ]
};

function waitHomeLiquid(sum) {
  return Boolean(sum && !sum.empty && sum.resources.liquid && sum.resources.liquid.value >= 1);
}

const STEP_DEFS = [
  { name: 'S00_launch', run: async driver => {
    await driver.bringToFront();
    await driver.navigate(GAME_URL);
    if (RESET_SAVE) {
      const cleared = await driver.evaluate('(()=>{for(let i=localStorage.length-1;i>=0;i--)localStorage.removeItem(localStorage.key(i));return localStorage.length;})()');
      record('origin_cleared', { remaining: cleared });
      await driver.reload();
    } else {
      out('D2NATURAL: info detail=RESET_SAVE=0 keeping existing localStorage for resume');
      record('origin_kept', {});
    }
    await driver.waitFor(() => driver.evaluate('document.readyState').then(v => v === 'complete'), 30000, 500, 'load');
    await driver.waitABODE_READY(READY_TIMEOUT_MS);
    await shot(driver, 'S00-ready');
  } },
  { name: 'S01_hut_build', run: async driver => {
    for (let i = 0; i < 3; i++) {
      out('D2NATURAL: info detail=popup_close_iter=' + i);
      await sleep(3000);
      await driver.click(WAYPOINTS.popup_offline_close);
      await sleep(1500);
      await driver.click(WAYPOINTS.popup_offline_close);
      await sleep(800);
      await shot(driver, 'S01-popup-close-' + i);
    }
    await driver.click(WAYPOINTS.dock_management);
    await sleep(1500);
    await driver.click(WAYPOINTS.panel_qty_tab);
    await sleep(800);
    out('D2NATURAL: info detail=popup_sequence_done');
    await shot(driver, 'S01-catalog-open');
    const start = Date.now();
    let idx = 0;
    let lastShot = 0;
    while (Date.now() - start < SHORT_BUDGET_MS) {
      out('D2NATURAL: info detail=gather_iter=' + idx);
      const s = await driver.readSave();
      const sum = summarizeSave(s);
      if (!sum.empty && sum.buildings.hut >= 1) break;
      try {
        if (idx % 4 === 3) await driver.click(WAYPOINTS.world_hut_slot);
        else await driver.click(WAYPOINTS.mini_gather);
      } catch (e) { record('click_error', { step: 'S01_gather', error: String(e && e.message ? e.message : e) }); }
      record('click_attempt', { step: 'S01_gather', idx, rev: s && s.revision });
      idx++;
      if (Date.now() - lastShot > 30000) { await shot(driver, 'S01-progress'); lastShot = Date.now(); }
      await sleep(800);
    }
    await shot(driver, 'S01-after-gather');
    const fin = summarizeSave(await driver.readSave());
    if (!fin.empty && fin.buildings.hut >= 1) out('D2NATURAL: milestone=S01_hut_build ok hut=1');
    else throw new Error('S01_hut_build timeout hut=' + (fin.buildings.hut ?? '?'));
  } },
  { name: 'S02_era1_level10', run: async driver => {
    const start = Date.now();
    let attempt = 0;
    let lastShot = 0;
    let lastShotFile = '';
    const tracker = makeStallTracker('S02_era1_level10');
    for (;;) {
      const sum = summarizeSave(await driver.readSave());
      if (!sum.empty && sum.era === 1 && sum.level >= 10) {
        out('D2NATURAL: milestone=S02_era1_level10 ok level=' + sum.level + ' waited=' + Math.round((Date.now() - start) / 1000) + 's');
        break;
      }
      if (Date.now() - start > ERA1_BUDGET_MS) {
        out('D2NATURAL: milestone=S02_era1_level10 timeout level=' + sum.level + ' waited>=' + Math.round(ERA1_BUDGET_MS / 1000) + 's state=' + describeState(sum));
        throw new Error('S02_era1_level10 budget exhausted before level 10');
      }
      attempt++;
      let p;
      const woodVal = sum.resources && sum.resources.wood ? Number(sum.resources.wood.value) : 0;
      const m = attempt % 5;
      if (woodVal < (sum.level >= 3 ? 40 : 20)) p = WAYPOINTS.gather_wood;
      else if (m === 0 || m === 1) p = WAYPOINTS.header_level_up;
      else if (m === 2) p = WAYPOINTS.catalog_zhulingtan_build;
      else p = WAYPOINTS.gather_money;
      record('click_attempt', { step: 'S02_era1_level10', attempt, point: p, level: sum.level, lingli: sum.resources && sum.resources.lingli ? sum.resources.lingli.value : null, money: sum.resources && sum.resources.money ? sum.resources.money.value : null, wood: sum.resources && sum.resources.wood ? sum.resources.wood.value : null });
      try { await driver.click(p); } catch (e) {
        record('click_error', { step: 'S02_era1_level10', attempt, error: String(e && e.message ? e.message : e) });
      }
      const gp = WAYPOINTS.gather_lingli_rows[attempt % WAYPOINTS.gather_lingli_rows.length];
      try { await driver.click(gp); } catch (e) { /* ignore */ }
      if (attempt % 12 === 0) await dismissModals(driver);
      await tracker.poll(driver, sum);
      if (Date.now() - lastShot > 30000) {
        const after = summarizeSave(await driver.readSave());
        lastShotFile = await shot(driver, 'S02-progress-' + attempt);
        lastShot = Date.now();
        out('D2NATURAL: progress step=S02_era1_level10 waited=' + Math.round((Date.now() - start) / 1000) + 's ' + describeState(after) + ' shot=' + lastShotFile);
      }
      await sleep(Math.max(CLICK_INTERVAL_MS, 600));
    }
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
    await clickLoop(driver, 'S04_breakthrough_foundation', WAYPOINTS.header_breakthrough, game(s => s.era >= 2), { budgetMs: SHORT_BUDGET_MS });
    await sleep(12000);
    await shot(driver, 'S04-after-breakthrough');
  } },
  { name: 'S05_era2_capacity', run: async driver => {
    await driver.click(WAYPOINTS.dock_management);
    await sleep(1500);
    await shot(driver, 'S05-catalog-open');
    await clickLoop(driver, 'S05_storage_lingli2', WAYPOINTS.catalog_card_upgrade_lingli, game(s => (s.buildings.storage_lingli ?? 0) >= 2), { budgetMs: SHORT_BUDGET_MS });
    await clickLoop(driver, 'S05_foundation_reservoir2', WAYPOINTS.catalog_storage_candidates, game(s => (s.buildings.foundation_reservoir ?? 0) >= 2), {
      budgetMs: ERA2_BUDGET_MS, wheelEvery: 3, wheel: WAYPOINTS.catalog_wheel
    });
    await clickLoop(driver, 'S05_linglicap_2300', WAYPOINTS.dock_home, game(s => s.helpers.lingliCap >= 2300 && s.helpers.lingliVal >= 2000), { budgetMs: ERA2_BUDGET_MS, intervalMs: 30000 });
  } },
  { name: 'S06_economy_open_wood_ore', run: async driver => {
    await driver.click(WAYPOINTS.dock_management);
    await sleep(1000);
    await driver.click(WAYPOINTS.nav_islands);
    await sleep(1500);
    await shot(driver, 'S06-island-panel');
    await clickLoop(driver, 'S06_economy_enable', WAYPOINTS.island_actions, game(s => s.economy.version > 0), { budgetMs: SHORT_BUDGET_MS });
    const woodPoints = [...WAYPOINTS.island_actions, WAYPOINTS.island_selector_wood, WAYPOINTS.island_actions[0]];
    await clickLoop(driver, 'S06_open_wood', woodPoints, game(s => Boolean(s.economy.islands.wood && s.economy.islands.wood.opened)), { budgetMs: CRAFT_BUDGET_MS });
    const orePoints = [...WAYPOINTS.island_actions, WAYPOINTS.island_selector_ore, WAYPOINTS.island_actions[1]];
    await clickLoop(driver, 'S06_open_ore', orePoints, game(s => Boolean(s.economy.islands.ore && s.economy.islands.ore.opened)), { budgetMs: CRAFT_BUDGET_MS });
  } },
  { name: 'S07_era2_level10', run: async driver => {
    await clickLoop(driver, 'S07_era2_level10', WAYPOINTS.header_level_up, game(s => s.era === 2 && s.level >= 10), { budgetMs: ERA2_BUDGET_MS });
  } },
  { name: 'S08_breakthrough_gold', run: async driver => {
    await shot(driver, 'S08-before-breakthrough');
    await clickLoop(driver, 'S08_breakthrough_gold', WAYPOINTS.header_breakthrough, game(s => s.era >= 3), { budgetMs: SHORT_BUDGET_MS });
    await sleep(12000);
    await shot(driver, 'S08-after-breakthrough');
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
    await clickLoop(driver, 'S10_route_configured', [...WAYPOINTS.transport_route_scan, ...WAYPOINTS.transport_save_scan], game(s => s.economy.routes.includes('liquid_home')), {
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
  { name: 'S12_t2_formation_core_stone_mid', run: async driver => {
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
  { name: 'S13_era3_level_up_consume', run: async driver => {
    const before = summarizeSave(await driver.readSave());
    await clickLoop(driver, 'S13_era3_level_up', WAYPOINTS.header_level_up, game(s => s.era === 3 && s.level > before.level), { budgetMs: ERA2_BUDGET_MS });
    const after = summarizeSave(await driver.readSave());
    const consumed = after.resources.formation_core.value < before.resources.formation_core.value
      || after.resources.liquid.value < before.resources.liquid.value
      || after.resources.stone_mid.value < before.resources.stone_mid.value
      || after.helpers.lingliVal < before.helpers.lingliVal;
    if (!consumed) {
      await shot(driver, 'S13-no-consume');
      await dumpSave(driver, 'S13-no-consume');
      throw new Error('level up at era3 showed no expected material consumption; before=' + describeState(before) + ' after=' + describeState(after));
    }
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
    if (!ok) {
      await dumpSave(driver, 'S14-reload-mismatch');
      throw new Error('reload mismatch before=' + describeState(before) + ' after=' + describeState(after));
    }
  } }
];

async function main() {
  out('D2NATURAL: start config cdp=' + CDP_PORT + ' http=' + HTTP_PORT + ' stepDir=' + STEP_DIR);
  record('run_start', { cdpPort: CDP_PORT, httpPort: HTTP_PORT, resetSave: RESET_SAVE, runSteps: RUN_STEPS });
  const keep = parseRunSteps();
  const driver = await connectDriver({ cdpPort: Number(CDP_PORT), debugPrinter: line => out('D2NATURAL: info detail=' + line) });
  const runList = STEP_DEFS.map((def, index) => ({ def, index })).filter(x => !keep || keep.has(x.index));
  out('D2NATURAL: info detail=runList=' + runList.map(x => x.def.name).join(','));
  for (const item of runList) {
    const name = item.def.name;
    const t0 = Date.now();
    out('D2NATURAL: info detail=step_begin ' + name);
    record('step_start', { name, index: item.index });
    try {
      await item.def.run(driver);
      const sum = summarizeSave(await driver.readSave());
      out('D2NATURAL: milestone=' + name + ' ok=true detail=done_in=' + Math.round((Date.now() - t0) / 1000) + 's ' + describeState(sum));
      record('step_done', { name, index: item.index, ms: Date.now() - t0 });
    } catch (e) {
      const msg = String(e && e.message ? e.message : e);
      record('step_error', { name, index: item.index, error: msg, ms: Date.now() - t0 });
      try {
        await shot(driver, 'FAIL-' + name);
        await dumpSave(driver, 'FAIL-' + name);
      } catch {}
      out('D2NATURAL: milestone=' + name + ' ok=false detail=' + msg);
      out('D2NATURAL: fatal step=' + name + ' evidence_dir=' + STEP_DIR + ' evidence_events=' + EVENTS_FILE);
      await new Promise(resolve => eventStream.end(resolve));
      process.exit(1);
    }
  }
  record('run_done', { stepsRun: runList.length, events: eventsWritten });
  out('D2NATURAL: done detail=steps=' + runList.length + ' events=' + eventsWritten + ' jsonl=' + EVENTS_FILE);
  await new Promise(resolve => eventStream.end(resolve));
  process.exit(0);
}

main().catch(async e => {
  const msg = String(e && e.message ? e.message : e);
  record('fatal', { error: msg });
  out('D2NATURAL: fatal error=' + msg + ' evidence_dir=' + STEP_DIR);
  await new Promise(resolve => eventStream.end(resolve));
  process.exit(1);
});
