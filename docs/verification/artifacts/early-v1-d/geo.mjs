import { connectDriver, summarizeSave } from '../res1d2-natural-mouse-driver.mjs';

const d = await connectDriver({
  cdpPort: Number(process.env.CDP_PORT || 9240),
  matchPort: process.env.HTTP_PORT || '4380'
});
console.log('page=' + d.pageUrl);
try {
  const g = await d.geo();
  console.log('geo=' + JSON.stringify(g));
} catch (e) {
  console.log('geo_error=' + String(e && e.message ? e.message : e));
}
try {
  const s = await d.readSave();
  const sum = summarizeSave(s);
  console.log('summary=' + JSON.stringify(sum));
  console.log('cycle=' + (s.state && s.state.reincarnation_count));
  console.log('elapsed=' + (s.state && s.state.total_elapsed_seconds));
  console.log('talents=' + JSON.stringify(s.state && s.state.talents));
  console.log('pill_effects=' + JSON.stringify(s.state && s.state.pill_effects));
} catch (e) {
  console.log('save_error=' + String(e && e.message ? e.message : e));
}
await d.close();
