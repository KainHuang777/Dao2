// Deterministic observer-contract test. This does not stand in for browser FPS.
import {readFileSync} from 'node:fs';
import vm from 'node:vm';
import assert from 'node:assert/strict';
const source = readFileSync(new URL('./res1c2_metrics.js', import.meta.url), 'utf8');
function run({control=false, ready=true, change=null, doubleClick=false, profile=false, seconds=15, normalSeconds=15}={}) {
  const elements = {}, listeners = {}, records = [];
  let nextFrame, now=0;
  const document = {visibilityState:'visible', body:{appendChild(){}},
    createElement:()=>({style:{}}), getElementById:id=>elements[id]??=( {} ),
    addEventListener:(name,fn)=>listeners[name]=fn};
  const context = {document,window:{addEventListener:(name,fn)=>listeners[name]=fn},
    location:{href:'http://test/'+(control?'raf-baseline':'metrics.html')+'?profileSeconds='+seconds+'&sampleSeconds='+normalSeconds,pathname:control?'/raf-baseline':'/metrics.html'},
    navigator:{userAgent:'contract-test'},innerWidth:1280,innerHeight:720,devicePixelRatio:1,
    performance:{now:()=>now,getEntriesByType:()=>[]},console:{log(){}},URL,Date,
    fetch:(_url,options)=>records.push(JSON.parse(options.body)),requestAnimationFrame:fn=>nextFrame=fn};
  if(profile) context.window.dao2RuntimeProfile={start(){},stop(){return {rows:[],dropped:0};}};
  vm.runInNewContext(source,context);
  if (ready && !control) context.console.log('ABODE_READY:');
  elements.sample.onclick();
  const expectedSeconds=profile ? (seconds===60 ? 60 : 15) : ([60,300].includes(normalSeconds) ? normalSeconds : 15);
  for(let i=1;i<=Math.ceil(expectedSeconds*1000/16.67)+1;i++) {
    now=i*16.67;
    if(i===400) {
      if(doubleClick) elements.sample.onclick();
      if(change==='visibility') {document.visibilityState='hidden';listeners.visibilitychange();document.visibilityState='visible';listeners.visibilitychange();}
      if(change==='resize') {context.innerWidth=844;listeners.resize();}
    }
    nextFrame(now);
  }
  return records.at(-1).frameSample;
}
assert.equal(run().valid,true);
assert.equal(run({control:true}).valid,true);
assert.equal(run({ready:false}).invalidReasons[0],'game_not_ready_at_start');
assert.equal(run({change:'visibility'}).invalidReasons[0],'visibility_changed_or_hidden');
assert.equal(run({change:'resize'}).invalidReasons[0],'viewport_or_dpr_changed');
assert.equal(run({doubleClick:true}).count,run().count);
assert.equal(run({seconds:60}).requestedDurationMs,15000);
assert.equal(run({profile:true,seconds:60}).requestedDurationMs,60000);
assert.equal(run({profile:true,seconds:120}).requestedDurationMs,15000);
assert.equal(run({normalSeconds:60}).requestedDurationMs,60000);
assert.equal(run({normalSeconds:300}).requestedDurationMs,300000);
assert.equal(run({normalSeconds:120}).requestedDurationMs,15000);
assert.equal(run({profile:true,normalSeconds:300}).requestedDurationMs,15000);
console.log('PASS: 13 observer contract cases (ready/control/visibility/resize/double-click/normal60-300/profile duration)');
