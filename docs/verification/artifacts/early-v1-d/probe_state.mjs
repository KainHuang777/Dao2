import { connectDriver, summarizeSave } from '../res1d2-natural-mouse-driver.mjs';
const api = await connectDriver({ cdpPort: Number(process.env.CDP_PORT || 9240), httpPort: Number(process.env.HTTP_PORT || 4380), debugPrinter: () => {} });
try {
  const s = await api.readSave();
  const sum = summarizeSave(s);
  const st = s.state || {};
  console.log(JSON.stringify({
    era: sum.era, level: sum.level, totalSeconds: sum.totalSeconds, revision: sum.revision,
    jobs: sum.economy.jobs, routes: sum.economy.routes,
    stone_mid: sum.resources.stone_mid, stone_low: sum.resources.stone_low, liquid: sum.resources.liquid,
    formation_core: sum.resources.formation_core, spirit_timber: sum.resources.spirit_timber,
    bronze_essence: sum.resources.bronze_essence, lingli: sum.resources.lingli, money: sum.resources.money,
    wood: sum.resources.wood, black_copper: sum.resources.black_copper,
    islands: Object.fromEntries(Object.entries(sum.economy.islands).map(([k, v]) => [k, v.opened])),
  }, null, 0));
} finally { await api.close().catch(() => {}); }
process.exit(0);
