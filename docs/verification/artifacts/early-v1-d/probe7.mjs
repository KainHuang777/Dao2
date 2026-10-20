import { connectDriver, sleep } from '../res1d2-natural-mouse-driver.mjs';

const d = await connectDriver({
  cdpPort: Number(process.env.CDP_PORT || 9240),
  matchPort: process.env.HTTP_PORT || '4380'
});
function dump(label) {
  return d.evaluate(`(()=>{
    const cs=Array.from(document.querySelectorAll('canvas')).map(c=>({id:c.id,styleW:c.style.width,styleH:c.style.height,bufW:c.width,bufH:c.height,rectW:Math.round(c.getBoundingClientRect().width),rectH:Math.round(c.getBoundingClientRect().height)}));
    return JSON.stringify({label:${JSON.stringify(label)},iw:innerWidth,ih:innerHeight,ow:outerWidth,oh:outerHeight,dpr:devicePixelRatio,docW:document.documentElement.clientWidth,docH:document.documentElement.clientHeight,canvases:cs});
  })()`);
}
console.log('BEFORE ' + await dump('before'));
await d.send('Emulation.setDeviceMetricsOverride', { width: 1280, height: 720, deviceScaleFactor: 1, mobile: false });
await sleep(1000);
console.log('AFTER_OVERRIDE ' + await dump('after_override'));
await d.evaluate(`window.dispatchEvent(new Event('resize'))`);
await sleep(1500);
console.log('AFTER_RESIZE ' + await dump('after_resize'));
await d.screenshot('docs/verification/artifacts/early-v1-d/probe7-pinned.png');
await d.close();
