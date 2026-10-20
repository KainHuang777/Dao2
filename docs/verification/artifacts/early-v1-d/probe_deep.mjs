import { connectDriver, summarizeSave } from '../res1d2-natural-mouse-driver.mjs';
const api = await connectDriver({ cdpPort: Number(process.env.CDP_PORT || 9240), httpPort: Number(process.env.HTTP_PORT || 4380), debugPrinter: () => {} });
try {
  const s = await api.readSave();
  const st = s.state || {};
  const scalars = {};
  for (const k of Object.keys(st)) {
    const v = st[k];
    if (v === null || typeof v === 'number' || typeof v === 'string' || typeof v === 'boolean') scalars[k] = v;
  }
  console.log('SCALARS ' + JSON.stringify(scalars));
  const flat = (o, p) => Object.entries(o || {}).flatMap(([k, v]) => (v && typeof v === 'object' ? flat(v, p + '.' + k) : [[p + '.' + k, v]]));
  console.log('MATCH ' + JSON.stringify(flat(st, '').filter(([k]) => /level|progress|timer|upgrade|cultivat|breakthrough/i.test(k))));
  console.log('SUMMARY ' + JSON.stringify(summarizeSave(s)));
} finally { await api.close().catch(() => {}); }
process.exit(0);
