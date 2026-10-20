import { connectDriver, sleep } from '../res1d2-natural-mouse-driver.mjs';

const driver = await connectDriver({ cdpPort: 9240, matchPort: '4380', debugPrinter: l => console.log('[drv]', l) });
console.log('before clear, ls:', await driver.evaluate('localStorage.length'));
const cleared = await driver.evaluate('(()=>{for(let i=localStorage.length-1;i>=0;i--)localStorage.removeItem(localStorage.key(i));return localStorage.length;})()');
console.log('cleared ->', cleared);
await driver.reload();
console.log('reloaded, waiting for ABODE_READY...');
for (let i = 0; i < 60; i++) {
  await sleep(2000);
  const ready = driver.consoleLines.some(l => l.text.includes('ABODE_READY:'));
  if (i % 5 === 0 || ready) console.log(i * 2 + 's ready=' + ready + ' consoleN=' + driver.consoleLines.length + ' tail=' + JSON.stringify(driver.consoleLines.slice(-1).map(l => l.text.slice(0, 90))));
  if (ready) break;
}
const st = await driver.evaluate(`(()=>{let ls=0;try{ls=localStorage.length}catch(e){}return {href:location.href, ls};})()`);
console.log('final', JSON.stringify(st));
await driver.close();
