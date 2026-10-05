// Loaded only by the isolated /profile.html development endpoint.
// GDScript durations are microseconds; JS end timestamps use performance.now().
// Includes timing overhead, excludes GPU/rendering and bridge/JSON emission time.
(() => {
  let rows = [], active = false, dropped = 0;
  let tasks = [], startedMs = 0, taskDropped = 0;
  let animationFrames = [], animationDropped = 0;
  const animationSupported = typeof PerformanceObserver !== 'undefined' && PerformanceObserver.supportedEntryTypes?.includes('long-animation-frame');
  function collectAnimation(entries, endMs = performance.now()) {
    if (!active) return;
    for (const e of entries) {
      if (e.startTime >= endMs || e.startTime + e.duration <= startedMs) continue;
      if (animationFrames.length >= 1000) { animationDropped++; continue; }
      // Copy scalar fields only; Window objects are circular and not evidence.
      animationFrames.push({startMs:e.startTime,durationMs:e.duration,
        blockingDurationMs:e.blockingDuration,renderStartMs:e.renderStart,
        styleAndLayoutStartMs:e.styleAndLayoutStart,
        scripts:Array.from(e.scripts ?? [], s => ({startMs:s.startTime,durationMs:s.duration,
          executionStartMs:s.executionStart,forcedStyleAndLayoutDurationMs:s.forcedStyleAndLayoutDuration,
          pauseDurationMs:s.pauseDuration,invoker:s.invoker,invokerType:s.invokerType,
          sourceURL:s.sourceURL,sourceFunctionName:s.sourceFunctionName,
          sourceCharPosition:s.sourceCharPosition,windowAttribution:s.windowAttribution}))});
    }
  }
  const animationObserver = animationSupported ? new PerformanceObserver(list => collectAnimation(list.getEntries())) : null;
  animationObserver?.observe({type:'long-animation-frame',buffered:false});
  const supported = typeof PerformanceObserver !== 'undefined' && PerformanceObserver.supportedEntryTypes?.includes('longtask');
  function collect(entries, endMs = performance.now()) {
    if (!active) return;
    for (const entry of entries) {
      if (entry.startTime >= endMs || entry.startTime + entry.duration <= startedMs) continue;
      if (tasks.length >= 1000) { taskDropped++; continue; }
      tasks.push({startMs:entry.startTime,durationMs:entry.duration,name:entry.name});
    }
  }
  const observer = supported ? new PerformanceObserver(list => collect(list.getEntries())) : null;
  observer?.observe({type:'longtask',buffered:false});
  window.dao2RuntimeProfile = {
    record(totalUs, spansJson) {
      if (!active) return;
      const endMs = performance.now();
      if (rows.length >= 10000) { dropped++; return; }
      rows.push({endMs, totalUs, spans:JSON.parse(spansJson)});
    },
    start() { observer?.takeRecords(); animationObserver?.takeRecords(); rows=[]; tasks=[]; animationFrames=[]; dropped=0; taskDropped=0; animationDropped=0; startedMs=performance.now(); active=true; },
    stop() {
      if (active) collect(observer?.takeRecords() ?? []);
      if (active) collectAnimation(animationObserver?.takeRecords() ?? []);
      active=false;
      return {version:2,unit:'microseconds',clock:'performance.now endMs; includes JS bridge entry latency',
        note:'Nested inclusive GDScript spans; do not add hud_total/view_build or save_total/encode/commit. Browser LongTasks are elapsed task durations, not CPU samples or call stacks. No GPU attribution.',
        dropped,rows,longTasksSupported:Boolean(supported),longTaskDropped:taskDropped,longTasks:tasks,
        longAnimationFramesSupported:Boolean(animationSupported),longAnimationFrameDropped:animationDropped,longAnimationFrames:animationFrames};
    }
  };
})();
