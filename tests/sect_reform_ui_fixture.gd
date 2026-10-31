extends RefCounted
## Synthetic funded UI scenario; never player progression or natural pacing evidence.
static func create(content: GameContent) -> GameState:
 var s := GameSession.create_new_game(content, 31)
 s.state.reincarnation_count = 1
 StoryProgress.next_life(s.state)
 s.state.life_ledger = {}
 LifeLedger.initialize(s.state)
 s.state.era_id = 3
 s.state.highest_era = 3
 IslandProgression.command(content, s.state, "activate_islands", {})
 s.state.economy.islands.herb.opened = true
 SectSystem.ensure_sect_state(s.state)
 s.state.sect.unlocked = true
 SectIdentity.write(s.state.sect, "taixu_sect")
 s.state.sect.contribution = "10000"
 s.state.resources.stone_low.value = AmountCompat.from_number(1000)
 s.state.resources.spirit_grass_low.value = AmountCompat.from_number(10000)
 s.state.dao_heart = AmountCompat.from_number(100)
 var state := SectReformRelease.prepare(s.state, "isolated-ui-seed", "sect-ui-review")
 state.sect.guardian.guardian_tokens = 24
 state.sect.lineage.completed_lives.taixu_sect = 1
 state.sect.available_tasks = []
 state.sect.active_expedition = null
 SectSystem.refresh_tasks(state)
 AchievementSystem.check_achievements(state, content)
 return state
