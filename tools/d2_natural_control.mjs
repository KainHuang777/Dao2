// Test-only real mouse driver. No game commands, fixture injection, or time scaling.
import fs from 'node:fs';
import readline from 'node:readline';
import { connectDriver, summarizeSave } from '../docs/verification/artifacts/res1d2-natural-mouse-driver.mjs';
const dir = 'docs/verification/artifacts/d2-natural-20261016';
fs.mkdirSync(dir, { recursive: true });
const d = await connectDriver({ cdpPort: 9237, matchPort: '4306' });
console.log('connected');
d.onConsoleLine(line => fs.appendFileSync(dir + '/console.jsonl', JSON.stringify(line) + '\n'));
if (process.argv.includes('--interactive') || process.argv.includes('--queue')) {
  // Keep the headed test page focused while the operator inspects shell evidence.
  // Browser focus emulation changes no game clock, command, resources, or rules.
  await d.send('Emulation.setFocusEmulationEnabled', {enabled:true});
  await d.send('Emulation.setDeviceMetricsOverride', {width:1280,height:720,deviceScaleFactor:1,mobile:false});
  await d.bringToFront();
  async function* queuedCommands() {
    const queue=dir+'/queue'; fs.mkdirSync(queue,{recursive:true});
    for(;;) {
      const files=fs.readdirSync(queue).filter(f=>f.endsWith('.json')).sort();
      for(const f of files) {
        const p=queue+'/'+f; const raw=fs.readFileSync(p,'utf8');
        fs.renameSync(p,p+'.running'); yield raw;
        fs.renameSync(p+'.running',p+'.done');
      }
      await new Promise(r=>setTimeout(r,200));
    }
  }
  const rl = process.argv.includes('--queue') ? queuedCommands() : readline.createInterface({input:process.stdin,terminal:false});
  console.log('CONTROL_READY');
  for await (const line of rl) {
    try {
      const cmd=JSON.parse(line);
      if(cmd.exit) break;
      const before=await d.readSave();
      for(const p of cmd.points||[]) {
        if(p.wheel) await d.wheel(p,p.wheel);
        else for(let i=0;i<(p.count||1);i++) await d.click(p);
      }
      if(cmd.reload) { await d.reload(); await new Promise(r=>setTimeout(r,10000)); }
      await new Promise(r=>setTimeout(r,500));
      const after=await d.readSave();
      const tag=cmd.tag||String(Date.now());
      const ev={utc:new Date().toISOString(),tag,before,after,cmd,geo:await d.geo()};
      fs.writeFileSync(dir+'/'+tag+'.json',JSON.stringify(ev,null,2));
      fs.appendFileSync(dir+'/events.jsonl',JSON.stringify(ev)+'\n');
      await d.screenshot(dir+'/'+tag+'.png');
      console.log(JSON.stringify({tag,era:after.state?.era_id,level:after.state?.level,training:after.state?.training_seconds,buildings:after.state?.buildings,resources:after.state?.resources,economy:after.state?.economy}));
    } catch(e) { console.log('CONTROL_ERROR '+String(e)); }
  }
  await d.close(); process.exit(0);
}
try {
  if (process.env.RESTORE_WINDOW) {
    const win = await d.send('Browser.getWindowForTarget');
    await d.send('Browser.setWindowBounds', {windowId:win.windowId,bounds:{windowState:'normal'}});
  }
  await d.bringToFront();
  console.log('foreground');
  const before = await d.readSave();
  if (process.env.POINTS) {
    for (const p of JSON.parse(process.env.POINTS)) {
      console.log('mouse ' + JSON.stringify(p));
      if (p.wheel) await d.wheel(p, p.wheel);
      else for (let i=0;i<(p.count||1);i++) await d.click(p);
    }
  }
  await new Promise(r => setTimeout(r, 700));
  const after = await d.readSave();
  const tag = process.env.TAG || String(Date.now());
  const evidence = { utc:new Date().toISOString(),tag,points:process.env.POINTS||null,before,after,geo:await d.geo() };
  fs.writeFileSync(dir+'/'+tag+'.json',JSON.stringify(evidence,null,2));
  fs.appendFileSync(dir+'/events.jsonl',JSON.stringify(evidence)+'\n');
  await d.screenshot(dir+'/'+tag+'.png');
  console.log(JSON.stringify({tag,summary:summarizeSave(after),training:after.state?.training_seconds,console:d.consoleLines.slice(-3)}));
} finally { await d.close(); }
