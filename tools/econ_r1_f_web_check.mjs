import { connectDriver, sleep } from '../docs/verification/artifacts/res1d2-natural-mouse-driver.mjs';

const CDP_PORT = Number(process.env.CDP_PORT || 9252);
const HTTP_PORT = String(process.env.HTTP_PORT || 4182);
const BASE_URL = process.env.BASE_URL || `http://127.0.0.1:${HTTP_PORT}/index.html`;
const OUT_DIR = process.env.OUT_DIR || '.test-output/econ-r1-f-web-check';
const VIEWPORTS = (process.env.VIEWPORTS || '1280x720,844x390,800x360').split(',').map(s => s.trim()).filter(Boolean);

import fs from 'node:fs';
import path from 'node:path';

fs.mkdirSync(OUT_DIR, { recursive: true });

const checks = [];
const consoleErrors = [];
const shots = [];
function check(name, ok, detail) {
  checks.push({ name, ok: !!ok, detail: detail == null ? null : String(detail) });
  console.log(`[check] ${ok ? 'PASS' : 'FAIL'} ${name}${detail != null ? ' :: ' + detail : ''}`);
}

async function setRealViewport(w, h) {
  // Emulation.setDeviceMetricsOverride blocks Input.dispatchMouseEvent delivery;
  // resize the real OS window instead (converge inner size to the target).
  try { await driver.send('Emulation.clearDeviceMetricsOverride', {}); } catch (e) { /* ignore */ }
  const win = await driver.send('Browser.getWindowForTarget', {});
  const windowId = win.windowId;
  await driver.send('Browser.setWindowBounds', { windowId, bounds: { windowState: 'normal' } });
  await sleep(400);
  for (let i = 0; i < 8; i += 1) {
    const g = await driver.evaluate('JSON.stringify([innerWidth, innerHeight])');
    const [iw, ih] = JSON.parse(g);
    if (Number.isFinite(iw) && Math.abs(iw - w) <= 2 && Math.abs(ih - h) <= 2) {
      await driver.bringToFront();
      return true;
    }
    const boundsNow = (await driver.send('Browser.getWindowForTarget', {})).bounds || {};
    await driver.send('Browser.setWindowBounds', {
      windowId,
      bounds: { width: (boundsNow.width || w) + (w - iw), height: (boundsNow.height || h) + (h - ih) },
    });
    await sleep(700);
  }
  return false;
}

const METRICS_JS = `(() => {
  const c = document.querySelector('canvas');
  const r = c ? c.getBoundingClientRect() : null;
  return {
    canvas: r ? { x: r.x, y: r.y, w: r.width, h: r.height } : null,
    canvas_hw: c ? { width: c.width, height: c.height } : null,
    inner: { w: window.innerWidth, h: window.innerHeight },
    dpr: window.devicePixelRatio,
    doc: { w: document.documentElement.scrollWidth, h: document.documentElement.scrollHeight },
  };
})()`;

async function metrics() {
  return await driver.evaluate(METRICS_JS);
}

async function frameMarker() {
  return await driver.evaluate('window.__dao2_frame_marker = (window.__dao2_frame_marker || 0) + 1; window.__dao2_frame_marker');
}

function freshReadySince(start) {
  return driver.consoleLines.slice(start).some(l => /ABODE_READY/.test(l.text || ''));
}

let driver = await connectDriver({ cdpPort: CDP_PORT, matchPort: HTTP_PORT, debugPrinter: () => {} });
driver.onConsoleLine(line => {
  if (/SCRIPT ERROR|Uncaught|TypeError|JavaScript error/.test(line.text || '')) {
    consoleErrors.push(line.text);
  }
});

async function waitReadySince(start, timeoutMs = 180000) {
  return driver.waitFor(
    () => driver.consoleLines.slice(start).some(l => /ABODE_READY/.test(l.text || '')),
    timeoutMs, 1000, 'ABODE_READY'
  );
}

async function editionLine(start) {
  const matched = driver.consoleLines.slice(start)
    .filter(l => /ABODE_EDITION:\s*(\S+)/.test(l.text || ''));
  const m = matched.length ? /ABODE_EDITION:\s*(\S+)/.exec(matched[matched.length - 1].text) : null;
  return m ? m[1] : null;
}

async function waitEditionSince(start, timeoutMs = 60000) {
  return driver.waitFor(() => editionLine(start) != null, timeoutMs, 1000, 'ABODE_EDITION');
}

const byUrl = {};
for (const vp of VIEWPORTS) {
  const [w, h] = vp.split('x').map(Number);
  for (const edition of [true, false]) {
    const label = `${vp}-${edition ? 'econ-r1' : 'default'}`;
    console.log(`[viewport] ${label}`);
    const resized = await setRealViewport(w, h);
    if (!resized) check(`${label} viewport_reached`, false, `window resize could not converge to ${w}x${h}`);
    await sleep(800);

    // Fresh state: clear all storage of this isolated profile.
    await driver.evaluate(`try { localStorage.clear(); sessionStorage.clear(); } catch (e) {} 'cleared'`);

    const mark = driver.consoleLines.length;
    const url = `${BASE_URL}${edition ? '?edition=econ-r1&' : '?'}r=${Date.now()}`;
    await driver.navigate(url);

    let readyOk;
    const readyMark = driver.consoleLines.length;
    try { await waitReadySince(mark, 30000); readyOk = true; } catch (e) {
      console.log(`[warn] ${label} first ABODE_READY wait: ${e}`);
      // Fresh save boots block on the centered startup dialog; click it
      // (logical 1280x720 coords mapped into canvas css space with letterbox).
      const rect = await driver.evaluate(
        `(() => { const c = document.getElementById('canvas').getBoundingClientRect(); return [c.x, c.y, c.width, c.height]; })()`
      ).catch(() => null);
      if (rect && Array.isArray(rect)) {
        await driver.bringToFront();
        await sleep(400);
        const [rx, ry, rw, rh] = rect;
        // Compact-height windows switch Godot's content base to 640x360
        // (living_abode._adapt_viewport_scale); tall ones stay 1280x720.
        const scale = rh / (rh <= 500 ? 360 : 720);
        const cx = rx + rw / 2;
        for (const off of [0, 20, 40, 60, 80, 100, 120, 140, 160, -20]) {
          const py = ry + rh / 2 + off * scale;
          console.log(`[click] ${label} scan off=${off} -> css(${cx.toFixed(1)},${py.toFixed(1)}) scale=${scale.toFixed(4)}`);
          const ev = (type, extra = {}) => driver.send('Input.dispatchMouseEvent', {
            type, x: cx, y: py, button: 'left',
            buttons: type === 'mouseReleased' ? 0 : 1, clickCount: 1, ...extra,
          });
          await ev('mouseMoved'); await sleep(120);
          await ev('mousePressed'); await sleep(200); await ev('mouseReleased');
          await sleep(4000);
          if (freshReadySince(readyMark)) break;
        }
      }
      try { await waitReadySince(readyMark, 60000); readyOk = true; } catch (e3) { readyOk = false; console.log(`[warn] ${label} ABODE_READY re-wait: ${e3}`); }
    }
    check(`${label} abode_ready`, readyOk, 'ABODE_READY line observed');

    const editionValue = await editionLine(mark).catch(() => null) || await (async () => {
      try { await waitEditionSince(mark); } catch (e) { console.log(`[warn] ${label} ABODE_EDITION wait: ${e}`); }
      return await editionLine(mark).catch(() => null);
    })();
    const claimed = editionValue === 'econ-r1';
    check(`${label} edition_line_${edition ? 'econ_r1' : 'default'}`, edition ? claimed : !claimed, `ABODE_EDITION: ${editionValue || '(none)'}`);

    // Wait for a live canvas above the loading screen.
    try {
      await driver.waitFor(
        async () => {
          const mm = await metrics();
          return mm && mm.canvas && mm.canvas.h > 100;
        },
        30000, 500, 'canvas'
      );
    } catch (e) { console.log(`[warn] ${label} canvas wait: ${e}`); }
    await sleep(3500);

    // Detect page liveness (two distinct frame markers).
    try {
      const markerA = await frameMarker();
      await sleep(700);
      const markerB = await frameMarker();
      check(`${label} page_live`, markerA !== markerB, `markers ${markerA}->${markerB}`);

      const m = await metrics();
      check(
        `${label} canvas_fits`,
        m.canvas && Math.abs(m.canvas.w - w) <= 2 && Math.abs(m.canvas.h - h) <= 2,
        JSON.stringify(m.canvas)
      );
      check(
        `${label} no_page_overflow`,
        m.doc.w <= m.inner.w + 1 && m.doc.h <= m.inner.h + 1,
        JSON.stringify({ doc: m.doc, inner: m.inner })
      );

      const shotPath = path.join(OUT_DIR, `web-${label}.png`).replace(/\\/g, '/');
      await driver.screenshot(shotPath);
      shots.push(shotPath);
      byUrl[label] = { canvas: m.canvas, doc: m.doc, inner: m.inner };
    } catch (e) {
      check(`${label} flow_completed`, false, String(e));
    }
  }
}

const report = {
  base_url: BASE_URL,
  viewports: VIEWPORTS,
  byUrl,
  checks,
  consoleErrors,
  shots,
};
fs.writeFileSync(path.join(OUT_DIR, 'report.json'), JSON.stringify(report, null, 2));
console.log(`[report] ${path.join(OUT_DIR, 'report.json')}`);

const failed = checks.filter(c => !c.ok);
console.log(`[summary] checks=${checks.length} failed=${failed.length} consoleErrors=${consoleErrors.length}`);
if (failed.length || consoleErrors.length) {
  for (const f of failed) console.log(`[failed] ${f.name} :: ${f.detail}`);
  for (const e of consoleErrors) console.log(`[consoleError] ${e}`);
  process.exitCode = 1;
} else {
  console.log('[summary] ALL PASS');
}

driver.close();
