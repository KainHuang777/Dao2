import { connectDriver, sleep } from '../res1d2-natural-mouse-driver.mjs';

const d = await connectDriver({
  cdpPort: Number(process.env.CDP_PORT || 9240),
  matchPort: process.env.HTTP_PORT || '4380'
});
const dump = () => d.evaluate(`(()=>{
  const c=document.getElementById('canvas');
  const r=c?c.getBoundingClientRect():null;
  return JSON.stringify({iw:innerWidth,ih:innerHeight,dpr:devicePixelRatio,iw2:window.visualViewport?window.visualViewport.width:null,canvas:c?{styleW:c.style.width,styleH:c.style.height,bufW:c.width,bufH:c.height,rectW:r?Math.round(r.width):null,rectH:r?Math.round(r.height):null}:null});
})()`);
console.log('PRE_RELOAD ' + await dump());
await d.reload();
await d.waitFor(() => d.evaluate('document.readyState').then(v => v === 'complete'), 60000, 500, 'reload');
await d.waitABODE_READY(120000);
await sleep(2000);
console.log('POST_RELOAD ' + await dump());
await d.screenshot('docs/verification/artifacts/early-v1-d/probe8-pinned.png');
await d.close();
