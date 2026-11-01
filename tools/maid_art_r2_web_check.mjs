import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { connectDriver, sleep } from '../docs/verification/artifacts/res1d2-natural-mouse-driver.mjs';

const cdpPort = Number(process.env.CDP_PORT || 9250);
const httpPort = Number(process.env.HTTP_PORT || 48350);
const baseUrl = process.env.BASE_URL || `http://127.0.0.1:${httpPort}/index.html`;
const fixturePath = process.env.FIXTURE || 'docs/verification/artifacts/maid-art-r2-l3-fixture.json';
const outDir = process.env.OUT_DIR || 'docs/verification/artifacts/maid-art-r2-l3-web';
const namespace = process.env.SAVE_NAMESPACE || 'dao2_saves';
const vp = (process.env.VIEWPORTS || '1280x720,844x390,800x360').split(',').map(v => v.split('x').map(Number));
const fullFlow = (process.env.FULL_FLOW || '1280x720').split(',');

// Compact viewports use canvas-space clicks calibrated from real screenshots
// because the panel switches to its responsive layout (no 1280x720 scaling).
const COMPACT = {
  '844x390': {
    closeSummary: [475, 69], dock: [361, 342],
    chips: { qingheng: [75, 215], nuomeizi: [175, 215], danxia: [263, 215] },
    portrait: [150, 300], viewerClose: [790, 35],
    tabs: { meeting: [175, 165], work: [263, 165], bond: [363, 165] },
    panelClose: [723, 100], scroll: [400, 250],
  },
  '800x360': {
    closeSummary: [446, 68], dock: [343, 316],
    chips: { qingheng: [62, 195], nuomeizi: [157, 195], danxia: [246, 195] },
    portrait: [120, 270], viewerClose: [747, 32],
    tabs: { meeting: [160, 148], work: [246, 148], bond: [344, 148] },
    panelClose: [689, 88], scroll: [380, 235],
  },
};

fs.mkdirSync(outDir, { recursive: true });
const envelope = JSON.parse(fs.readFileSync(fixturePath, 'utf8'));
const revision = envelope.revision ?? 0;
const results = { ok: false, utc: new Date().toISOString(), url: baseUrl, screens: [], checks: {}, errors: [] };
const driver = await connectDriver({ cdpPort, matchPort: httpPort, namespace });

function check(name, ok, detail = '') {
  results.checks[name] = { ok: !!ok, detail };
  if (!ok) results.errors.push(name + (detail ? ': ' + detail : ''));
  console.log((ok ? 'PASS ' : 'FAIL ') + name + (detail ? ' ' + detail : ''));
}

async function viewport(w, h) {
  await driver.send('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: 1, mobile: false });
}

async function metrics() {
  return driver.evaluate(`(()=>{const c=document.querySelector('canvas');if(!c)return null;const r=c.getBoundingClientRect();return {inner:[window.innerWidth,window.innerHeight],dpr:window.devicePixelRatio,canvas:[r.left,r.top,r.width,r.height],buffer:[c.width,c.height],doc:[document.documentElement.scrollWidth,document.documentElement.scrollHeight],body:[document.body.scrollWidth,document.body.scrollHeight]};})()`);
}

async function dispatchClick(vx, vy) {
  await driver.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: vx, y: vy, buttons: 0, pointerType: 'mouse' });
  await sleep(60);
  await driver.send('Input.dispatchMouseEvent', { type: 'mousePressed', x: vx, y: vy, button: 'left', buttons: 1, clickCount: 1, pointerType: 'mouse' });
  await sleep(80);
  await driver.send('Input.dispatchMouseEvent', { type: 'mouseReleased', x: vx, y: vy, button: 'left', buttons: 0, clickCount: 1, pointerType: 'mouse' });
}

async function clickLogical(x, y, label) {
  const m = await metrics();
  const scale = Math.min(m.canvas[2] / 1280, m.canvas[3] / 720);
  const vx = m.canvas[0] + x * scale;
  const vy = m.canvas[1] + y * scale;
  await dispatchClick(vx, vy);
  return { label, logical: [x, y], css: [vx, vy], scale };
}

async function clickAt(x, y, label) {
  const m = await metrics();
  const vx = m.canvas[0] + x;
  const vy = m.canvas[1] + y;
  await dispatchClick(vx, vy);
  return { label, logical: [x, y], css: [vx, vy] };
}

async function wheelAt(x, y, deltaY, steps = 3) {
  const m = await metrics();
  const vx = m.canvas[0] + x;
  const vy = m.canvas[1] + y;
  await driver.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: vx, y: vy, buttons: 0, pointerType: 'mouse' });
  await sleep(80);
  for (let i = 0; i < steps; i += 1) {
    await driver.send('Input.dispatchMouseEvent', { type: 'mouseWheel', x: vx, y: vy, deltaX: 0, deltaY, pointerType: 'mouse' });
    await sleep(120);
  }
  return { label: 'wheel', css: [vx, vy], deltaY, steps };
}

function shotHash(file) {
  return crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
}

async function key(name, code, keyCode) {
  await driver.send('Input.dispatchKeyEvent', { type: 'rawKeyDown', key: name, code, windowsVirtualKeyCode: keyCode, nativeVirtualKeyCode: keyCode });
  await sleep(40);
  await driver.send('Input.dispatchKeyEvent', { type: 'keyUp', key: name, code, windowsVirtualKeyCode: keyCode, nativeVirtualKeyCode: keyCode });
}

async function waitReadySince(startLen) {
  await driver.waitFor(() => driver.consoleLines.slice(startLen).some(l => l.text.includes('ABODE_READY:')), 180000, 1000, 'ABODE_READY-fresh');
}

async function shoot(tag, name) {
  const file = path.join(outDir, `${tag}-${name}.png`);
  await driver.screenshot(file);
  return file;
}

try {
  await driver.bringToFront();
  for (const [w, h] of vp) {
    const tag = `${w}x${h}`;
    const screen = { vp: [w, h], clicks: [], shots: [], checks: {} };
    await viewport(w, h);
    await driver.evaluate(`(()=>{const ns='${namespace}';const drop=[];for(let i=0;i<localStorage.length;i++){const k=localStorage.key(i);if(k&&k.startsWith(ns+':'))drop.push(k);}for(const k of drop)localStorage.removeItem(k);return drop.length;})()`);
    await driver.evaluate(`(()=>{localStorage.setItem('${namespace}:save_main', ${JSON.stringify(JSON.stringify(envelope))});localStorage.setItem('${namespace}:save_index', ${JSON.stringify(JSON.stringify({ active_slot: 'save_main', revision, commit_sequence: 1 }))});return true;})()`);
    const startLen = driver.consoleLines.length;
    await driver.navigate(baseUrl + '?r=' + Date.now());
    await waitReadySince(startLen);
    await driver.waitFor(async () => { try { return (await metrics()).canvas[3] > 100; } catch { return false; } }, 60000, 500, 'canvas-ready-' + tag);
    await sleep(3500);
    const m = await metrics();
    const fits = Math.abs(m.canvas[2] - w) <= 2 && Math.abs(m.canvas[3] - h) <= 2;
    const noOverflow = m.doc[0] <= m.inner[0] + 1 && m.doc[1] <= m.inner[1] + 1;
    screen.metrics = m;
    screen.checks.canvas_fits = fits;
    screen.checks.no_page_overflow = noOverflow;
    check(`${tag}-canvas-fits`, fits, `canvas=${m.canvas.map(v => Math.round(v)).join(',')}`);
    check(`${tag}-no-page-overflow`, noOverflow, `doc=${m.doc.join('x')} inner=${m.inner.join('x')}`);
    screen.shots.push(await shoot(tag, '01-offline-summary'));

    const raw = await driver.readSaveRaw();
    const maid = (((raw.env || {}).last_offline_report || {}).maid) || {};
    const restored = Number(maid.actions || 0) > 0 && !!((((raw.env || {}).state || {}).maid || {}).maids || {}).qingheng;
    screen.checks.save_restored = restored;
    check(`${tag}-save-restored`, restored, 'actions=' + String(maid.actions));

    if (!fullFlow.includes(tag)) {
      const coords = COMPACT[tag];
      if (!coords) {
        screen.compact_note = 'canvas/overflow/save only; no calibrated compact waypoints';
        results.screens.push(screen);
        continue;
      }
      screen.clicks.push(await clickAt(coords.closeSummary[0], coords.closeSummary[1], 'close-offline-summary'));
      await sleep(900);
      screen.shots.push(await shoot(tag, '02-world'));

      screen.clicks.push(await clickAt(coords.dock[0], coords.dock[1], 'dock-characters'));
      await sleep(1100);
      screen.shots.push(await shoot(tag, '03-characters'));

      screen.clicks.push(await clickAt(coords.chips.nuomeizi[0], coords.chips.nuomeizi[1], 'select-nuomeizi'));
      await sleep(900);
      const nuo = await shoot(tag, '04-nuomeizi-person');
      screen.shots.push(nuo);

      screen.clicks.push(await clickAt(coords.chips.danxia[0], coords.chips.danxia[1], 'select-danxia'));
      await sleep(900);
      const dan = await shoot(tag, '05-danxia-person');
      screen.shots.push(dan);
      const maidSwitchDiffers = shotHash(nuo) !== shotHash(dan);
      screen.checks.maid_switch_differs = maidSwitchDiffers;
      check(`${tag}-maid-switch-differs`, maidSwitchDiffers, 'nuomeizi vs danxia screenshots');

      screen.clicks.push(await clickAt(coords.chips.qingheng[0], coords.chips.qingheng[1], 'select-qingheng'));
      await sleep(700);

      screen.clicks.push(await clickAt(coords.portrait[0], coords.portrait[1], 'open-art-viewer'));
      await sleep(1000);
      const viewer = await shoot(tag, '06-art-viewer');
      screen.shots.push(viewer);

      screen.clicks.push(await clickAt(coords.viewerClose[0], coords.viewerClose[1], 'close-art-viewer'));
      await sleep(900);
      const viewerClosed = await shoot(tag, '07-art-viewer-closed');
      screen.shots.push(viewerClosed);
      const viewerToggled = shotHash(viewer) !== shotHash(viewerClosed);
      screen.checks.viewer_toggled = viewerToggled;
      check(`${tag}-viewer-open-close-differs`, viewerToggled, 'viewer screenshots');

      screen.clicks.push(await clickAt(coords.tabs.meeting[0], coords.tabs.meeting[1], 'tab-meeting'));
      await sleep(900);
      screen.shots.push(await shoot(tag, '08-meeting'));

      screen.clicks.push(await clickAt(coords.tabs.work[0], coords.tabs.work[1], 'tab-work'));
      await sleep(900);
      const workTop = await shoot(tag, '09-work');
      screen.shots.push(workTop);
      screen.clicks.push(await wheelAt(coords.scroll[0], coords.scroll[1], 300, 3));
      await sleep(800);
      const workScrolled = await shoot(tag, '09b-work-scrolled');
      screen.shots.push(workScrolled);
      const workScrolledDiffers = shotHash(workTop) !== shotHash(workScrolled);
      screen.checks.work_scrolled = workScrolledDiffers;
      check(`${tag}-work-page-scrolls`, workScrolledDiffers, 'wheel over duty page');

      screen.clicks.push(await clickAt(coords.tabs.bond[0], coords.tabs.bond[1], 'tab-bond'));
      await sleep(900);
      const bondTop = await shoot(tag, '10-bond');
      screen.shots.push(bondTop);
      screen.clicks.push(await wheelAt(coords.scroll[0], coords.scroll[1], 300, 3));
      await sleep(800);
      const bondScrolled = await shoot(tag, '10b-bond-scrolled');
      screen.shots.push(bondScrolled);
      const bondScrolledDiffers = shotHash(bondTop) !== shotHash(bondScrolled);
      screen.checks.bond_scrolled = bondScrolledDiffers;
      check(`${tag}-bond-page-scrolls`, bondScrolledDiffers, 'wheel over bond page');

      screen.clicks.push(await clickAt(coords.panelClose[0], coords.panelClose[1], 'close-panel'));
      await sleep(1000);
      screen.shots.push(await shoot(tag, '11-world-after-close'));

      const compactAfter = await driver.readSaveRaw();
      const compactStates = Object.keys((((compactAfter.env || {}).state || {}).resources) || {}).length;
      screen.checks.save_intact = compactStates > 0;
      check(`${tag}-save-intact-after-flow`, compactStates > 0, 'schema=' + String((compactAfter.env || {}).schema_version));
      results.screens.push(screen);
      continue;
    }

    screen.clicks.push(await clickLogical(439, 79, 'close-offline-summary'));
    await sleep(900);
    screen.shots.push(await shoot(tag, '02-world'));

    screen.clicks.push(await clickLogical(360, 664, 'dock-characters'));
    await sleep(1000);
    screen.shots.push(await shoot(tag, '03-characters'));

    screen.clicks.push(await clickLogical(154, 221, 'select-nuomeizi'));
    await sleep(900);
    screen.shots.push(await shoot(tag, '04-nuomeizi-person'));

    screen.clicks.push(await clickLogical(241, 221, 'select-danxia'));
    await sleep(900);
    screen.shots.push(await shoot(tag, '05-danxia-person'));

    screen.clicks.push(await clickLogical(78, 221, 'select-qingheng'));
    await sleep(700);

    screen.clicks.push(await clickLogical(449, 374, 'open-art-viewer'));
    await sleep(1000);
    screen.shots.push(await shoot(tag, '06-art-viewer'));
    await key('Escape', 'Escape', 27);
    await sleep(900);
    screen.shots.push(await shoot(tag, '07-art-viewer-closed'));

    screen.clicks.push(await clickLogical(1027, 170, 'tab-meeting'));
    await sleep(900);
    screen.shots.push(await shoot(tag, '08-meeting'));

    screen.clicks.push(await clickLogical(1122, 170, 'tab-work'));
    await sleep(900);
    screen.shots.push(await shoot(tag, '09-work'));

    screen.clicks.push(await clickLogical(1204, 170, 'tab-bond'));
    await sleep(900);
    screen.shots.push(await shoot(tag, '10-bond'));

    screen.clicks.push(await clickLogical(1166, 101, 'close-panel'));
    await sleep(1000);
    screen.shots.push(await shoot(tag, '11-world-after-close'));

    const after = await driver.readSaveRaw();
    const afterStates = Object.keys((((after.env || {}).state || {}).resources) || {}).length;
    screen.checks.save_intact = afterStates > 0;
    check(`${tag}-save-intact-after-flow`, afterStates > 0, 'schema=' + String((after.env || {}).schema_version));
    results.screens.push(screen);
  }

  const scriptErrors = driver.consoleLines.filter(l => /SCRIPT ERROR|Uncaught|TypeError/.test(l.text));
  check('console-no-script-error', scriptErrors.length === 0, 'lines=' + driver.consoleLines.length);
  results.console = driver.consoleLines.slice(-200);
  results.ok = results.errors.length === 0;
  fs.writeFileSync(path.join(outDir, 'maid-art-r2-web-report.json'), JSON.stringify(results, null, 2));
  console.log((results.ok ? 'MAID-ART-R2-WEB PASS' : 'MAID-ART-R2-WEB FAIL') + ' errors=' + JSON.stringify(results.errors));
  await driver.close();
  process.exit(results.ok ? 0 : 1);
} catch (error) {
  results.errors.push(String(error && error.stack ? error.stack : error));
  try { await shoot('error', 'failure'); } catch {}
  try { results.console = driver.consoleLines.slice(-200); } catch {}
  fs.writeFileSync(path.join(outDir, 'maid-art-r2-web-report.json'), JSON.stringify(results, null, 2));
  console.log('MAID-ART-R2-WEB FAIL ' + String(error));
  try { await driver.close(); } catch {}
  process.exit(1);
}
