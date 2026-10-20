import { connectDriver, summarizeSave, sleep } from '../res1d2-natural-mouse-driver.mjs';
const api = await connectDriver({ cdpPort: Number(process.env.CDP_PORT || 9240), httpPort: Number(process.env.HTTP_PORT || 4380), debugPrinter: () => {} });
const pick = (st) => ({ total_elapsed: st.total_elapsed_seconds, training_seconds: st.training_seconds, level: st.level, era: st.era_id, revision: st.revision });
try {
  const a = await api.readSave(); console.log('T0 ' + JSON.stringify(pick(a.state)));
  await sleep(45000);
  const b = await api.readSave(); console.log('T1 ' + JSON.stringify(pick(b.state)));
  await api.screenshot('docs/verification/artifacts/early-v1-d/diag-recipe/live-era3-L2.png');
} finally { await api.close().catch(() => {}); }
process.exit(0);
