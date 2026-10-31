extends SceneTree
## Synthetic beast2 candidates only: no user saves or premature migration.
var content: GameContent
var checks := 0
var failures: Array[String] = []
func _init() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); print("FAIL: ", label)
func fresh(id: String = "") -> GameState:
	var state := GameSession.create_new_game(content, 20261030).state
	state.era_id = 3
	state.beast_version = GuardianBeasts.VERSION
	state.economy = {"islands": {"herb": {"opened": true}}}
	state.resources.spirit_grass_low.value = AmountCompat.from_number(10000)
	state.beasts = {"active": {}, "cooldown_remaining": 0.0}
	if not id.is_empty(): state.beasts.active = {"id": id, "stage": "egg", "exp": 0}
	return state
func same(a: GameState, b: GameState) -> bool:
	return JSON.stringify(a.to_snapshot_dict()) == JSON.stringify(b.to_snapshot_dict())
func talent(id: String, tier: int) -> String:
	return String(GuardianBeasts.SPECIES[id][1]) + GuardianBeasts.SUFFIXES[tier - 1]
func stage(state: GameState, xp: int) -> void:
	state.beasts.active.exp = xp
	state.beasts.active.stage = "egg" if xp < 100 else "young" if xp < 500 else "growing" if xp < 1000 else "mature"
func run() -> void:
	content = ContentLoader.load_directory("res://content").content
	check(IslandProgression.attach_supply(content).ok, "attach supply")
	check(GuardianBeasts.SPECIES.size() == 5 and GuardianBeasts.TALENTS.size() == 20, "five species twenty fixed talents")
	check(BeastSystem.BEAST_CONFIGS.size() == 6 and BeastSystem.BEAST_TALENTS.size() == 24, "live six species unchanged")
	for id in GuardianBeasts.SPECIES:
		var state := fresh()
		var before := state.duplicate_state()
		check(GuardianBeasts.acquire_requirements(state, id, true).ok and same(state, before), "readonly requirements " + id)
		check(not GuardianBeasts.acquire_requirements(state, id, false).ok, "permanent permit required")
		check(not BeastSystem.acquire_beast(state, id).ok and same(state, before), "public acquisition remains closed")
		for reason in ["version", "era", "herb", "occupied", "exhausted"]:
			state = fresh()
			if reason == "version": state.beast_version = 1
			elif reason == "era": state.era_id = 2
			elif reason == "herb": state.economy.islands.herb.opened = false
			elif reason == "occupied": state.beasts.active = {"id": "jade_fox", "stage": "egg", "exp": 0}
			else: state.total_elapsed_seconds = 1e9
			before = state.duplicate_state()
			check(not GuardianBeasts.acquire_requirements(state, id, true).ok and same(state, before), "acquire gate " + reason)
		for rank in range(5):
			state = fresh(id)
			state.beast_souls[id] = 11
			for tier in range(1, rank + 1): check(BeastSystem.unlock_talent(state, talent(id, tier)).ok, "buy same species tier")
			check(state.beast_souls[id] == 11 - [0, 1, 3, 6, 11][rank], "exact 1/2/3/5 soul costs")
			# Legacy memories and feed conservation cannot leak into new species.
			state.talents = {"beast_bond_past_wisdom": 5, "sacred_beast_nurture_memory": 5}
			state.sect.techniques = {"fox_feed_conservation": 5, "sacred_beast_feed_conservation": 5}
			var feeds := 0
			var elapsed := 0
			var expected_xp := 75 if rank == 4 else 65 if rank >= 2 else 50
			var cost := 30 if rank >= 3 else 50
			while state.beasts.active.stage != "mature" and feeds < 21:
				var held: AmountCompat = state.resources.spirit_grass_low.value
				var result := BeastSystem.feed_beast(state)
				check(result.ok and result.get("exp_gained") == expected_xp, "exact species XP, legacy isolation")
				if not result.ok: break
				feeds += 1
				check(is_equal_approx(held.subtract(state.resources.spirit_grass_low.value).to_float(), cost), "exact Amount debit")
				check(int(state.beasts.active.exp) == feeds * expected_xp, "cumulative XP")
				before = state.duplicate_state()
				check(not BeastSystem.feed_beast(state).ok and same(state, before), "cooldown or mature rejects atomically")
				if state.beasts.active.stage != "mature": BeastSystem.tick(state, 300); elapsed += 300
			check(feeds == (14 if rank == 4 else 16 if rank >= 2 else 20), "mature feed count")
			check(elapsed == (3900 if rank == 4 else 4500 if rank >= 2 else 5700), "cooldown intervals")
			check(state.beast_souls[id] == 11 - [0, 1, 3, 6, 11][rank], "feeding grants no souls")
			var soul_before := int(state.beast_souls[id])
			var settled := BeastSystem.on_reincarnate(state)
			check(settled.gained_souls == {id: 1} and state.beast_souls[id] == soul_before + 1, "only held species gains one soul")
			check(BeastSystem.on_reincarnate(state).gained_souls.is_empty(), "second settlement no soul")
			check(state.beast_talents.size() == rank, "soul talents survive reset")
		state = fresh(id)
		for other in GuardianBeasts.SPECIES:
			if other == id: continue
			state.beast_souls[other] = 11
			for tier in range(1, 5): state.beast_talents[talent(other, tier)] = 1
		before = state.duplicate_state()
		check(not BeastSystem.unlock_talent(state, talent(id, 1)).ok and same(state, before), "other souls cannot pay")
		check(GuardianBeasts.feed_xp(state, id) == 50 and GuardianBeasts.feed_costs(state, id).spirit_grass_low == 50, "other trees cannot affect growth or price")
		state.beast_souls[id] = 11
		check(not BeastSystem.unlock_talent(state, talent(id, 2)).ok, "own T1 prerequisite")
		for xp in [0, 99, 100, 499, 500, 999, 1000]:
			stage(state, xp)
			for t1 in [0, 1]:
				state.beast_talents[talent(id, 1)] = t1
				var multiplier: float = 0.0 if xp < 100 else (0.5 if xp < 500 else 0.75 if xp < 1000 else 1.0) + 0.05 * t1
				for axis in ["cultivation", "ore", "herb", "lifespan", "capacity"]:
					var expected: float = float(GuardianBeasts.SPECIES[id][3]) * multiplier if axis == GuardianBeasts.SPECIES[id][2] else 0.0
					check(is_equal_approx(GuardianBeasts.bonus(state, axis), expected), "stage boundary and axis isolation")
		stage(state, 1000)
		state.beast_souls[id] = BeastSystem.MAX_SOULS
		before = state.duplicate_state()
		check(BeastSystem.on_reincarnate(state).get("error") == "BEAST_SOUL_OVERFLOW" and same(state, before), "overflow preserves entire life")
		stage(state, 999)
		check(BeastSystem.on_reincarnate(state).gained_souls.is_empty(), "immature has no soul")
		for reason in ["version", "exhausted", "shortage"]:
			state = fresh(id)
			state.beast_souls[id] = 11
			if reason == "version": state.beast_version = 1
			elif reason == "exhausted": state.total_elapsed_seconds = 1e9
			else: state.resources.spirit_grass_low.value = AmountCompat.from_number(49)
			before = state.duplicate_state()
			check(not BeastSystem.feed_beast(state).ok and same(state, before), "feed rejection " + reason)
			if reason != "shortage": check(not BeastSystem.unlock_talent(state, talent(id, 1)).ok and same(state, before), "talent rejection " + reason)
		state = fresh(id)
		stage(state, 1000)
		check(not SectReformRelease.validate(state).is_empty(), "partial beast2 release still rejected")
		check(not BeastSaveContract.validate(1, state.beasts, {}, {}).is_empty(), "new ID cannot masquerade as beast1")
		check(not BeastSaveContract.validate(1, {}, {}, {talent(id, 1): 1}).is_empty(), "new talent cannot masquerade as beast1")
		check(not GuardianBeasts.unlock(state, String(GuardianBeasts.SPECIES[id][1]) + "_t9_hack").ok, "prefix does not authorize unknown talent")
	check_effects()
	var result := {"runner": "sect_reform_guardian", "checks": checks, "failures": failures}
	var report := FileAccess.open(RunnerResult.output_path("res://docs/verification/artifacts/sect-reform/guardian.json"), FileAccess.WRITE)
	if report == null: check(false, "report write")
	else: report.store_string(JSON.stringify(result, "\t")); report.close()
	print(JSON.stringify(result))
	RunnerResult.finish(self, 0 if failures.is_empty() else 1)

func check_effects() -> void:
	for id in GuardianBeasts.SPECIES:
		var state := fresh(id)
		state.economy = {}
		stage(state, 1000)
		var reborn := state.duplicate_state()
		reborn.total_elapsed_seconds = Lifespan.for_state(content.era_lifespan_entries(), reborn)
		var rebirth := ReincarnationRules.apply_reincarnation(reborn, content)
		check(rebirth.ok and rebirth.events[0].get("gained_beast_souls", {}) == {id: 1} and reborn.beasts.active.is_empty(), "full reincarnation settles held species " + id)
		var prepared := TimeAdvancer.prepare_advance(state, content)
		var online := state.duplicate_state()
		var offline := state.duplicate_state()
		for _i in range(3): TimeAdvancer.advance(online, content, 1)
		check(OfflineClosedForm.advance(offline, content, 3).ticks_advanced == 3 and same(online, offline), "online offline full snapshot parity " + id)
		if id == "taixu_baize":
			check(is_equal_approx(online.training_seconds, 3.12), "mature Baize additive training")
			state.beast_talents.baize_t1_resonance = 1
			TimeAdvancer.advance(state, content, 1, prepared)
			check(is_equal_approx(state.training_seconds, 1.042), "prepared invalidates own T1 change")
			check(is_equal_approx(BeastSystem.compute_multipliers(state).cultivation_speed_bonus, 0.042), "shared beast multiplier")
		elif id == "wanfo_lotus_elephant":
			var base := state.duplicate_state()
			base.beasts.active = {}
			var years := Lifespan.for_state(content.era_lifespan_entries(), base) / 60
			check(Lifespan.for_state(content.era_lifespan_entries(), state) == floor(years * 1.04) * 60, "shared lifespan helper")
			state.total_elapsed_seconds = Lifespan.for_state(content.era_lifespan_entries(), state)
			state.beast_souls[id] = 11
			var before := state.duplicate_state()
			check(not BeastSystem.unlock_talent(state, "elephant_t1_resonance").ok and same(state, before), "no T1 lifespan resurrection")
			check(ReincarnationRules.check_eligibility(state, content).can_reincarnate and TimeAdvancer.advance(state, content, 1).ticks_advanced == 0, "lifespan consumers agree")
		elif id == "zixiao_star_tapir":
			check(is_equal_approx(SectSpecialization.capacity_bonus(state, "lingli"), 0.08), "tapir only lingli capacity")
			check(SectSpecialization.capacity_bonus(state, "money") == 0 and SectSpecialization.capacity_bonus(state, "lingqi") == 0, "capacity whitelist")
			var caps := Production.pill_caps(state, {"lingli": AmountCompat.from_number(1000)})
			check((caps.lingli as AmountCompat).to_float() == 1080, "authoritative Amount capacity")
		else:
			for island in ["ore", "deep", "herb", "ancient", "home"]:
				for resource in ["stone_low", "black_copper", "refined_iron", "mithril", "cold_iron", "spirit_grass_low", "spirit_grass_100y", "spirit_grass_1000y", "wood", "money"]:
					var eligible: bool = resource in SectSpecialization.GATHER.get(island, []) and (island in ["ore", "deep"] if id == "tianjian_suanni" else island in ["herb", "ancient"])
					check(is_equal_approx(SectSpecialization.gather_bonus(state, island, resource), 0.08 if eligible else 0.0), "exact local whitelist")
		# All five sects may keep any guardian passive. Only the sect-specific
		# methods and lineage switch off when membership changes.
		var axis: String = GuardianBeasts.SPECIES[id][2]
		var native := GuardianBeasts.bonus(state, axis)
		for sect in SectIdentity.NAMES:
			state.sect.unlocked = true
			SectIdentity.write(state.sect, sect)
			check(is_equal_approx(GuardianBeasts.bonus(state, axis), native), "native passive independent of sect")
		if id in ["tianjian_suanni", "piaomiao_jade_hare", "zixiao_star_tapir"]:
			var key := "tianjian" if id == "tianjian_suanni" else "piaomiao" if id == "piaomiao_jade_hare" else "zixiao"
			state.era_id = 5
			SectIdentity.write(state.sect, key + "_sect")
			state.sect.techniques_version = 1
			state.sect.techniques = {"tianjian_ore_vein": 5, "piaomiao_herb_garden": 5, "zixiao_spirit_vessel": 5}
			state.sect.lineage = SectLineage.initial(state)
			state.sect.lineage.learned[key + "_lineage"] = 3
			var combined := SectSpecialization.capacity_bonus(state, "lingli") if key == "zixiao" else SectSpecialization.gather_bonus(state, "ore" if key == "tianjian" else "herb", "stone_low" if key == "tianjian" else "spirit_grass_low")
			check(is_equal_approx(combined, 0.34), "same-axis 20+6+8 additive")
