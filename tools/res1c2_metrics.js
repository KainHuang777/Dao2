// Test-only observer injected by the isolated server; never edits economy/state.
(() => {
  const panel = document.createElement('aside');
  panel.style.cssText = 'position:fixed;right:4px;top:4px;z-index:9999;background:#fff;color:#123;font:12px sans-serif;padding:6px;max-width:260px';
  panel.innerHTML = '<button id="sample" style="min-height:44px">量測15秒幀間隔</button><button id="collapse" style="min-height:44px">收起報告</button><button id="hide-metrics" style="min-height:44px">隱藏量測工具</button><pre id="metrics" style="white-space:pre-wrap;max-height:260px;overflow:auto">等待 ABODE_READY</pre>';
  document.body.appendChild(panel);
  const report = document.getElementById('metrics');
  let frames = [], active = false, previous = 0, started = 0, startedBeforeReady = false;
  let sampleSequence = 0, sampleEnvironment = null, sampleChanges = [], frameEnds = [];
  let settlementActive = false, settlementPrevious = 0, settlementGaps = [];
  const workload = location.pathname === '/raf-baseline' ? 'raf_control' : 'game';
  const evidence = {kind:'c2_browser_metrics',measurementVersion:3,workload,url:location.href,userAgent:navigator.userAgent,
    viewport:[innerWidth,innerHeight],dpr:devicePixelRatio,
    note:'Browser rAF callback gaps; not GPU profiler or physical-device evidence'};
  function persist() {
    evidence.loadedAudioResources = performance.getEntriesByType('resource').filter(r=>new URL(r.name).pathname.includes('/audio/bgm/')).map(r=>({name:new URL(r.name).pathname,transferBytes:r.transferSize,encodedBytes:r.encodedBodySize,decodedBytes:r.decodedBodySize,durationMs:r.duration}));
    report.textContent = JSON.stringify(evidence,null,2);
    fetch('/metrics-evidence',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(evidence)});
  }
  function environment() {
    return {viewport:[innerWidth,innerHeight],dpr:devicePixelRatio,visible:document.visibilityState};
  }
  function recordChange(type) {
    if (active) sampleChanges.push({type,atMs:performance.now()-started,...environment()});
  }
  document.addEventListener('visibilitychange',()=>recordChange('visibility'));
  window.addEventListener('resize',()=>recordChange('resize'));
  const original = console.log;
  console.log = function(...args) {
    original.apply(console,args);
    if (args.join(' ').includes('OFFLINE_SETTLEMENT_BEGIN')) {
      evidence.settlementBeginMs = performance.now(); settlementActive = true;
    }
    if (args.join(' ').includes('OFFLINE_SETTLEMENT_END:')) {
      settlementActive = false;
      const sorted = settlementGaps.slice().sort((a,b)=>a-b);
      evidence.settlement = {durationMs:performance.now()-evidence.settlementBeginMs,
        intervals:sorted.length,p95Ms:sorted[Math.ceil(sorted.length*.95)-1] ?? null,
        maxMs:sorted.at(-1) ?? null,visible:document.visibilityState,frameGapsMs:settlementGaps};
    }
    if (args.join(' ').includes('ABODE_READY:') && evidence.readyMs === undefined) {
      evidence.readyMs = performance.now();
      evidence.resources = performance.getEntriesByType('resource').filter(r=>/index\.(wasm|pck|js)$/.test(new URL(r.name).pathname)).map(r=>({name:new URL(r.name).pathname,transferBytes:r.transferSize,encodedBytes:r.encodedBodySize,decodedBytes:r.decodedBodySize,durationMs:r.duration}));
      evidence.jsHeapAtReady = performance.memory?.usedJSHeapSize ?? null;
      persist();
    }
  };
  function frame(t) {
    if (settlementActive && settlementPrevious) settlementGaps.push(t-settlementPrevious);
    settlementPrevious = settlementActive ? t : 0;
    if (active && previous) { frames.push(t-previous); frameEnds.push(t); }
    previous = active ? t : 0;
    if (active && t-started >= 15000) {
      active = false;
      const sorted = frames.slice().sort((a,b)=>a-b);
      const intervalDurationMs = frames.reduce((sum,gap)=>sum+gap,0);
      const endEnvironment = environment();
      const invalidReasons = [];
      if (sampleEnvironment.visible !== 'visible' || endEnvironment.visible !== 'visible' || sampleChanges.some(c=>c.type==='visibility')) invalidReasons.push('visibility_changed_or_hidden');
      if (sampleChanges.some(c=>c.type==='resize') || JSON.stringify(sampleEnvironment.viewport)!==JSON.stringify(endEnvironment.viewport) || sampleEnvironment.dpr!==endEnvironment.dpr) invalidReasons.push('viewport_or_dpr_changed');
      if (workload==='game' && startedBeforeReady) invalidReasons.push('game_not_ready_at_start');
      if (!frames.length || frames.some(g=>!Number.isFinite(g)||g<=0)) invalidReasons.push('invalid_intervals');
      evidence.frameSample = {sampleSequence,sampledAtUtc:new Date().toISOString(),workload,
        valid:invalidReasons.length===0,invalidReasons,startEnvironment:sampleEnvironment,endEnvironment,changes:sampleChanges,
        count:frames.length,durationMs:t-started,intervalDurationMs,
        fps:1000*frames.length/intervalDurationMs,rawWindowFps:1000*frames.length/(t-started),
        medianMs:sorted[Math.ceil(sorted.length*.5)-1],p95Ms:sorted[Math.ceil(sorted.length*.95)-1],
        p99Ms:sorted[Math.ceil(sorted.length*.99)-1],maxMs:sorted.at(-1),
        over20Ms:frames.filter(g=>g>20).length,over33_34Ms:frames.filter(g=>g>33.34).length,frameGapsMs:frames,
        visible:document.visibilityState,startedBeforeReady,endedAfterReady:evidence.readyMs !== undefined,
        jsHeapBytes:performance.memory?.usedJSHeapSize ?? null};
      if (window.dao2RuntimeProfile) {
        evidence.frameSample.runtimeProfile = window.dao2RuntimeProfile.stop();
        evidence.frameSample.frameEndsMs = frameEnds;
      }
      persist();
    }
    requestAnimationFrame(frame);
  }
  document.getElementById('sample').onclick = () => {
    if (active) return; // Do not silently discard an unfinished sample on double click.
    frames=[]; frameEnds=[]; previous=0; started=performance.now(); active=true;
    if (window.dao2RuntimeProfile) window.dao2RuntimeProfile.start();
    sampleSequence++; sampleEnvironment=environment(); sampleChanges=[];
    startedBeforeReady = evidence.readyMs === undefined;
    report.textContent='取樣15秒，請保持本頁可見';
  };
  document.getElementById('collapse').onclick = () => {
    report.hidden=!report.hidden;
    document.getElementById('collapse').textContent=report.hidden?'展開報告':'收起報告';
  };
  document.getElementById('hide-metrics').onclick = () => { panel.hidden=true; };
  requestAnimationFrame(frame);
})();
