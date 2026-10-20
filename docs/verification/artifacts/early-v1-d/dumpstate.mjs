import { connectDriver, summarizeSave } from '../res1d2-natural-mouse-driver.mjs';

const CDP_PORT = Number(process.env.CDP_PORT || 9240);
const HTTP_PORT = Number(process.env.HTTP_PORT || 4380);
const api = await connectDriver({ cdpPort: CDP_PORT, matchPort: HTTP_PORT, debugPrinter: () => {} });
const raw = await api.readSaveRaw();
console.log('slot', raw.slot, 'indexed', raw.indexed);
const env = raw.env || {};
console.log('schema', env.schema_version, 'game', env.game_version, 'rules', env.rules_version, 'rev', env.revision);
const st = env.state || {};
console.log('state keys', JSON.stringify(Object.keys(st)));
console.log('resourceKeys', JSON.stringify(Object.keys(st.resources || {})));
console.log('resources', JSON.stringify(st.resources));
console.log('summary', JSON.stringify(summarizeSave(await api.readSave())));
await api.close();
process.exit(0);
