// Bounded UI-only level sequence for the already-observed 1280x720 header.
// Data is read from the committed game content and isolated browser save only.
import fs from 'node:fs';
import {connectDriver,sleep} from '../docs/verification/artifacts/res1d2-natural-mouse-driver.mjs';
const dir='docs/verification/artifacts/d2-natural-20261016';
const era=Number(process.env.D2_ERA||1);
fs.writeFileSync(dir+'/levels-era'+era+'.pid',String(process.pid));
const def=JSON.parse(fs.readFileSync('content/eras/era'+era+'.json','utf8'))[0];
const d=await connectDriver({cdpPort:9237,matchPort:'4306'});
const started=Date.now(); let lastReport=0;
const record=(tag,data)=>fs.appendFileSync(dir+'/levels.jsonl',JSON.stringify({utc:new Date().toISOString(),tag,...data})+'\n');
try {
  await d.send('Emulation.setFocusEmulationEnabled',{enabled:true});
  d.onConsoleLine(line=>fs.appendFileSync(dir+'/levels-console.jsonl',JSON.stringify(line)+'\n'));
  for(;;) {
    const save=await d.readSave(), s=save.state;
    if(!s || s.era_id!==era) throw new Error('unexpected era/state');
    if(s.level>=10) {record('complete',{save});console.log('LEVEL_SEQUENCE_COMPLETE era='+era);break;}
    if(Date.now()-started>3600000) throw new Error('one-hour bounded sequence budget exhausted');
    const req=def.level_up_requirements;
    const costs={...req.resources};
    for(const tier of req.graded_resources||[]) if(s.level>=tier.from_level)
      for(const [key,val] of Object.entries(tier.resources)) costs[key]=(costs[key]||0)+val;
    if(s.level===9 && req.lv9_item) costs[req.lv9_item.type]=req.lv9_item.amount;
    const time=req.base_time*Math.pow(req.time_multiplier,s.level-1);
    const missing=Object.entries(costs).filter(([key,v])=>Number(s.resources[key]?.value||0)<v);
    if(Date.now()-lastReport>55000) {
      console.log(JSON.stringify({era,level:s.level,training:s.training_seconds,required:time,missing}));
      record('waiting',{save,required:time,costs,missing});lastReport=Date.now();
    }
    if(s.training_seconds+0.00001>=time && missing.length===0) {
      const tag='era'+era+'-level'+s.level+'-to-'+(s.level+1);
      await d.screenshot(dir+'/'+tag+'-before.png');
      record('click',{before:save,costs,required:time,point:{x:300,y:68}});
      await d.click({x:300,y:68});
      await sleep(12000); // Real-time complete animation; never skip or accelerate.
      const after=await d.readSave();
      await d.screenshot(dir+'/'+tag+'-after.png');
      record('result',{after});
      if(after.state?.level!==s.level+1) throw new Error('header click did not produce expected next level');
      console.log('LEVEL_VERIFIED '+era+':'+after.state.level);
    }
    await sleep(5000);
  }
} catch(e) {
  record('failure',{error:String(e)});console.error(e);process.exitCode=1;
} finally {await d.close();}
