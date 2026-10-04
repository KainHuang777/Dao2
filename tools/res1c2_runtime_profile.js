// Loaded only by the isolated /profile.html development endpoint.
// GDScript durations are microseconds; JS end timestamps use performance.now().
// Includes timing overhead, excludes GPU/rendering and bridge/JSON emission time.
(() => {
  let rows = [], active = false, dropped = 0;
  window.dao2RuntimeProfile = {
    record(totalUs, spansJson) {
      if (!active) return;
      const endMs = performance.now();
      if (rows.length >= 10000) { dropped++; return; }
      rows.push({endMs, totalUs, spans:JSON.parse(spansJson)});
    },
    start() { rows=[]; dropped=0; active=true; },
    stop() {
      active=false;
      return {version:1,unit:'microseconds',clock:'performance.now endMs; includes JS bridge entry latency',
        note:'Nested inclusive spans; do not add hud_total/view_build or save_total/encode/commit. CPU _process only; no GPU attribution.',
        dropped,rows};
    }
  };
})();
