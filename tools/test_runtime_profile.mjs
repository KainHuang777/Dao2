import {readFileSync} from 'node:fs';
import vm from 'node:vm';
import assert from 'node:assert/strict';
const context = {window:{}, performance:{now:()=>123.5}};
vm.runInNewContext(readFileSync(new URL('./res1c2_runtime_profile.js',import.meta.url),'utf8'),context);
const probe=context.window.dao2RuntimeProfile;
probe.record(100,'{}');
assert.equal(probe.stop().rows.length,0);
probe.start();
probe.record(200,'{"save_total":150,"save_encode":100}');
let result=probe.stop();
assert.equal(result.rows[0].endMs,123.5);
assert.equal(result.rows[0].spans.save_encode,100);
assert.equal(result.rows[0].totalUs,200);
probe.record(100,'{}');
assert.equal(probe.stop().rows.length,1);
probe.start();
for(let i=0;i<10001;i++) probe.record(1,'{}');
result=probe.stop();
assert.equal(result.rows.length,10000);
assert.equal(result.dropped,1);
probe.start();
assert.equal(probe.stop().rows.length,0);
console.log('PASS: runtime profile inactive/start/stop/reset/timestamps/nested spans/bounded buffer');
let now = 100, callback, queued=[];
class MockObserver {
  static supportedEntryTypes=['longtask'];
  constructor(fn) { callback=fn; }
  observe() {}
  takeRecords() { const result=queued; queued=[]; return result; }
}
const taskContext={window:{},performance:{now:()=>now},PerformanceObserver:MockObserver};
vm.runInNewContext(readFileSync(new URL('./res1c2_runtime_profile.js',import.meta.url),'utf8'),taskContext);
const taskProbe=taskContext.window.dao2RuntimeProfile;
queued=[{startTime:0,duration:60,name:'stale'}];
taskProbe.start();
now=250;
callback({getEntries:()=>[{startTime:10,duration:60,name:'before'}, {startTime:90,duration:100,name:'cross-start'}]});
queued=[{startTime:200,duration:70,name:'pending'}];
result=taskProbe.stop();
assert.equal(result.longTasksSupported,true);
assert.equal(result.longTasks.length,2);
assert.equal(result.longTasks[0].name,'cross-start');
assert.equal(result.longTasks[1].name,'pending');
taskProbe.start();
assert.equal(taskProbe.stop().longTasks.length,0);
assert.equal(probe.stop().longTasksSupported,false);
console.log('PASS: long-task unsupported/filter/cross-start/pending-stop/reset contracts');
let animationCallback, animationQueued=[];
class AnimationObserver {
  static supportedEntryTypes=['long-animation-frame'];
  constructor(fn) { animationCallback=fn; }
  observe() {}
  takeRecords() { const entries=animationQueued; animationQueued=[]; return entries; }
}
const animationContext={window:{},performance:{now:()=>now},PerformanceObserver:AnimationObserver};
vm.runInNewContext(readFileSync(new URL('./res1c2_runtime_profile.js',import.meta.url),'utf8'),animationContext);
const animationProbe=animationContext.window.dao2RuntimeProfile;
const loaf={startTime:90,duration:100,blockingDuration:40,renderStart:95,styleAndLayoutStart:188,
  scripts:[{startTime:95,duration:90,executionStart:95,forcedStyleAndLayoutDuration:0,pauseDuration:0,
    invoker:'Window.requestAnimationFrame',invokerType:'user-callback',sourceURL:'index.js',
    sourceFunctionName:'loop',sourceCharPosition:12,windowAttribution:'self',window:{circular:true}}]};
now=100; animationQueued=[loaf]; animationProbe.start(); now=250;
animationCallback({getEntries:()=>[{...loaf,startTime:0,duration:60},loaf,{...loaf,startTime:300}]});
animationQueued=[{...loaf,startTime:200}];
result=animationProbe.stop();
assert.equal(result.longAnimationFramesSupported,true);
assert.equal(result.longAnimationFrames.length,2);
assert.equal(result.longAnimationFrames[0].scripts[0].sourceFunctionName,'loop');
assert.equal('window' in result.longAnimationFrames[0].scripts[0],false);
JSON.stringify(result);
assert.equal(probe.stop().longAnimationFramesSupported,false);
animationProbe.start(); now=500;
assert.equal(animationProbe.stop().longAnimationFrames.length,0);
animationProbe.start(); now=700;
animationCallback({getEntries:()=>Array(1001).fill({...loaf,startTime:600})});
result=animationProbe.stop();
assert.equal(result.longAnimationFrames.length,1000);
assert.equal(result.longAnimationFrameDropped,1);
console.log('PASS: animation-frame unsupported/filter/pending/reset/scalar attribution/bounded buffer');
