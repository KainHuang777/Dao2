# EARLY-V1-A Current Quantified Baseline

Generated: 2026-10-18T13:43:09 UTC

Engine: 4.7.2-stable (official) | Project: 0.1.0 | Rules: core-flow-12-skills-p1 | Save schema: 4

Content version: `c1b7f1520764d30194af498e0b0c9a12683f53c182716283dd3742ecfde67384+res1-d-2+skills-p1`

## Scope and method

- Real GameSession commands only; no direct resource, building, era or training assignment.
- Isolated new-game state; no player save is read or written.
- Era1 gathering is modelled at 2 clicks per second with 0.5 simulated seconds per gather.
- Simulated seconds come from state.total_elapsed_seconds; wall time is headless machine time.
- After Era3 Lv10 the bot advances time until the lifespan is exhausted because no live early-reincarnation building exists.
- Observation command: tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/early_v1a_observation.gd; log: build/early-v1-a-observation.log; recorded run exit 0 with no SCRIPT ERROR.

This is a mechanical observation matrix, not a full human playthrough or a UI/device pass.

## Current pacing audit (regenerated 2026-10-18)

- Report: `docs/verification/early-pacing-baseline.md` (2026-10-18, current rules)
- Command: `tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/early_pacing_audit.gd`
- Exit code: 0; log: `build/early-v1-a-pacing-audit.log`; no SCRIPT ERROR
- Findings: { "C1": "FAIL 26/92", "C2": "WARN 60/92", "C3": "WARN 13/92", "C4": "WARN 65/92", "C5": "WARN 1/92", "C6": "WARN 15/92", "C7": "OK 4.13x", "C8": "WARN 88% (69/78)", "C9": "OK 52%/64%", "C10": "WARN" }
- Chain training seconds: { "era1": 1007.15051676797, "era2": 2495.8682112, "era3": 5440.8030540339 }
- Era1 simulation: active 1286.0s / idle 2700.0s

Old 2026-10-11 C1-C10 values are historical comparison only and are archived under `docs/verification/artifacts/early-v1-a/pre-v2-baseline/`: { "report_date": "2026-10-11", "C1": "FAIL 42/92", "C2": "WARN 68/92", "C3": "WARN 57/92", "C4": "WARN 68/92", "C5": "WARN 1/92", "C6": "WARN 12/92", "C7": "OK 4.00x", "C8": "WARN 88%", "C9": "OK 60%/72%", "C10": "WARN", "era1_lv10_active_wall_minutes": 17.9, "era1_lv10_idle_wall_minutes": 45.0 }

## Observation matrix

| Variant | Status | Peak era/lv | End era/lv | Sim s | Wall s | Peak lifespan s | Dao heart | Skill pts | Talents | Skills | Waits >=600s |
| --- | --- | --- | --- | ---: | ---: | ---: | --- | ---: | --- | --- | ---: |
| V1_first_life_no_talents_no_skills | DONE | 3/10 | 1/1 | 44400.0 | 9.606 | 44400 | 20 | 0.0 | {  } | {  } | 0 |
| V1b_rebuild_to_era2 | DONE | 2/1 | 2/1 | 1243.0 | 1.094 | 12000 | 20 | 0.0 | {  } | {  } | 0 |
| V2_first_affordable_talent | DONE | 3/10 | 3/10 | 11206.0 | 6.506 | 44400 | 15 | 0.0 | { "resource_inheritance": 1 } | {  } | 0 |
| V3_skill_path | DONE | 3/10 | 3/10 | 10863.0 | 5.844 | 44400 | 20 | 200.0 | {  } | { "basic_meditation": 1 } | 0 |

V1 ends at Era1 Lv1 because the recorded run includes the real reincarnation reset; its peak before rebirth is read from the milestone log. V1b measures rebuild from that rebirth to Era2 Lv1.

## Milestones

| Run | Milestone | Era/lv | Sim s | Wall ms | Dao heart | Skill pts |
| --- | --- | --- | ---: | ---: | --- | ---: |
| V1_first_life_no_talents_no_skills | era1_build_chain_complete | 1/1 | 324.0 | 527 | 0 | 0.0 |
| V1_first_life_no_talents_no_skills | era1_lv10 | 1/10 | 1274.0 | 685 | 0 | 0.0 |
| V1_first_life_no_talents_no_skills | era2_reached | 2/1 | 1274.0 | 688 | 0 | 0.0 |
| V1_first_life_no_talents_no_skills | era2_islands_ready | 2/1 | 1624.0 | 828 | 0 | 0.0 |
| V1_first_life_no_talents_no_skills | era2_lv10 | 2/10 | 4062.0 | 1708 | 0 | 0.0 |
| V1_first_life_no_talents_no_skills | era3_reached | 3/1 | 4062.0 | 1721 | 0 | 0.0 |
| V1_first_life_no_talents_no_skills | era3_islands_ready | 3/1 | 4244.0 | 1785 | 0 | 0.0 |
| V1_first_life_no_talents_no_skills | era3_lv2 | 3/2 | 4995.0 | 2140 | 0 | 0.0 |
| V1_first_life_no_talents_no_skills | era3_lv3 | 3/3 | 5816.0 | 2873 | 0 | 0.0 |
| V1_first_life_no_talents_no_skills | era3_lv4 | 3/4 | 6637.0 | 3600 | 0 | 0.0 |
| V1_first_life_no_talents_no_skills | era3_lv5 | 3/5 | 7448.0 | 4303 | 0 | 0.0 |
| V1_first_life_no_talents_no_skills | era3_lv6 | 3/6 | 8269.0 | 5156 | 0 | 0.0 |
| V1_first_life_no_talents_no_skills | era3_lv7 | 3/7 | 9088.0 | 5862 | 0 | 0.0 |
| V1_first_life_no_talents_no_skills | era3_lv8 | 3/8 | 9910.0 | 6450 | 0 | 0.0 |
| V1_first_life_no_talents_no_skills | era3_lv9 | 3/9 | 10876.0 | 6958 | 0 | 0.0 |
| V1_first_life_no_talents_no_skills | era3_lv10 | 3/10 | 12054.0 | 7466 | 0 | 0.0 |
| V1_first_life_no_talents_no_skills | lifespan_exhausted | 3/10 | 44400.0 | 9591 | 0 | 0.0 |
| V1_first_life_no_talents_no_skills | reincarnated | 1/1 | 0.0 | 9596 | 20 | 0.0 |
| V1b_rebuild_to_era2 | era1_build_chain_complete | 1/1 | 293.0 | 687 | 20 | 0.0 |
| V1b_rebuild_to_era2 | era1_lv10 | 1/10 | 1243.0 | 1077 | 20 | 0.0 |
| V1b_rebuild_to_era2 | era2_reached | 2/1 | 1243.0 | 1081 | 20 | 0.0 |
| V1b_rebuild_to_era2 | refoundation_era2 | 2/1 | 1243.0 | 1086 | 20 | 0.0 |
| V2_first_affordable_talent | resource_inheritance_learned | 1/1 | 0.0 | 1 | 15 | 0.0 |
| V2_first_affordable_talent | era1_build_chain_complete | 1/1 | 296.0 | 642 | 15 | 0.0 |
| V2_first_affordable_talent | era1_lv10 | 1/10 | 1246.0 | 1027 | 15 | 0.0 |
| V2_first_affordable_talent | era2_reached | 2/1 | 1246.0 | 1036 | 15 | 0.0 |
| V2_first_affordable_talent | era2_islands_ready | 2/1 | 1576.0 | 1184 | 15 | 0.0 |
| V2_first_affordable_talent | era2_lv10 | 2/10 | 3984.0 | 2229 | 15 | 0.0 |
| V2_first_affordable_talent | era3_reached | 3/1 | 3984.0 | 2246 | 15 | 0.0 |
| V2_first_affordable_talent | era3_islands_ready | 3/1 | 4166.0 | 2331 | 15 | 0.0 |
| V2_first_affordable_talent | era3_lv2 | 3/2 | 4847.0 | 2677 | 15 | 0.0 |
| V2_first_affordable_talent | era3_lv3 | 3/3 | 5508.0 | 3130 | 15 | 0.0 |
| V2_first_affordable_talent | era3_lv4 | 3/4 | 6199.0 | 3659 | 15 | 0.0 |
| V2_first_affordable_talent | era3_lv5 | 3/5 | 6890.0 | 4186 | 15 | 0.0 |
| V2_first_affordable_talent | era3_lv6 | 3/6 | 7581.0 | 4680 | 15 | 0.0 |
| V2_first_affordable_talent | era3_lv7 | 3/7 | 8270.0 | 5080 | 15 | 0.0 |
| V2_first_affordable_talent | era3_lv8 | 3/8 | 9062.0 | 5491 | 15 | 0.0 |
| V2_first_affordable_talent | era3_lv9 | 3/9 | 10028.0 | 5987 | 15 | 0.0 |
| V2_first_affordable_talent | era3_lv10 | 3/10 | 11206.0 | 6495 | 15 | 0.0 |
| V3_skill_path | era1_build_chain_complete | 1/1 | 293.0 | 684 | 20 | 0.0 |
| V3_skill_path | era1_lv10 | 1/10 | 1243.0 | 1057 | 20 | 0.0 |
| V3_skill_path | era2_reached | 2/1 | 1243.0 | 1061 | 20 | 0.0 |
| V3_skill_path | era2_islands_ready | 2/1 | 1573.0 | 1220 | 20 | 0.0 |
| V3_skill_path | library_built | 2/1 | 1573.0 | 1233 | 20 | 0.0 |
| V3_skill_path | era2_lv10 | 2/10 | 3971.0 | 2276 | 20 | 200.0 |
| V3_skill_path | basic_meditation_learned | 2/10 | 3971.0 | 2285 | 20 | 110.0 |
| V3_skill_path | era3_reached | 3/1 | 3971.0 | 2302 | 20 | 110.0 |
| V3_skill_path | era3_islands_ready | 3/1 | 4153.0 | 2370 | 20 | 200.0 |
| V3_skill_path | era3_lv2 | 3/2 | 4834.0 | 2693 | 20 | 200.0 |
| V3_skill_path | era3_lv3 | 3/3 | 5415.0 | 3045 | 20 | 200.0 |
| V3_skill_path | era3_lv4 | 3/4 | 6036.0 | 3436 | 20 | 200.0 |
| V3_skill_path | era3_lv5 | 3/5 | 6657.0 | 3853 | 20 | 200.0 |
| V3_skill_path | era3_lv6 | 3/6 | 7278.0 | 4295 | 20 | 200.0 |
| V3_skill_path | era3_lv7 | 3/7 | 7927.0 | 4666 | 20 | 200.0 |
| V3_skill_path | era3_lv8 | 3/8 | 8719.0 | 5040 | 20 | 200.0 |
| V3_skill_path | era3_lv9 | 3/9 | 9685.0 | 5406 | 20 | 200.0 |
| V3_skill_path | era3_lv10 | 3/10 | 10863.0 | 5834 | 20 | 200.0 |

## Waits and bottlenecks

All waits are recorded in the JSON. The table below shows the 40 longest simulated segments.

| Run | Kind | Label | Sim s | Wall ms | Actionable | >=600s | Detail |
| --- | --- | --- | ---: | ---: | --- | --- | --- |
| V1_first_life_no_talents_no_skills | lifecycle | lifecycle:lifespan_runout | 32346.0 | 2116 | false | false |  |
| V1_first_life_no_talents_no_skills | craft | craft:stone_midx55 | 550.0 | 197 | true | false | stone_mid |
| V2_first_affordable_talent | craft | craft:stone_midx55 | 550.0 | 254 | true | false | stone_mid |
| V3_skill_path | craft | craft:stone_midx55 | 550.0 | 235 | true | false | stone_mid |
| V1_first_life_no_talents_no_skills | level | training_level:9 | 537.0 | 214 | true | false |  |
| V2_first_affordable_talent | level | training_level:9 | 537.0 | 161 | true | false |  |
| V3_skill_path | level | training_level:9 | 537.0 | 121 | true | false |  |
| V2_first_affordable_talent | level | level:9->10 | 516.0 | 184 | true | false | [] |
| V1_first_life_no_talents_no_skills | level | level:9->10 | 516.0 | 157 | true | false | [] |
| V3_skill_path | level | level:9->10 | 516.0 | 181 | true | false | [] |
| V2_first_affordable_talent | craft | craft:stone_midx50 | 500.0 | 255 | true | false | stone_mid |
| V1_first_life_no_talents_no_skills | craft | craft:stone_midx50 | 500.0 | 218 | true | false | stone_mid |
| V1_first_life_no_talents_no_skills | craft | craft:stone_midx50 | 500.0 | 267 | true | false | stone_mid |
| V3_skill_path | craft | craft:stone_midx50 | 500.0 | 242 | true | false | stone_mid |
| V2_first_affordable_talent | craft | craft:stone_midx50 | 500.0 | 229 | true | false | stone_mid |
| V1_first_life_no_talents_no_skills | craft | craft:stone_midx50 | 500.0 | 253 | true | false | stone_mid |
| V3_skill_path | craft | craft:stone_midx50 | 500.0 | 235 | true | false | stone_mid |
| V2_first_affordable_talent | craft | craft:stone_midx50 | 500.0 | 211 | true | false | stone_mid |
| V3_skill_path | craft | craft:stone_midx50 | 500.0 | 232 | true | false | stone_mid |
| V1_first_life_no_talents_no_skills | craft | craft:stone_midx50 | 500.0 | 234 | true | false | stone_mid |
| V2_first_affordable_talent | craft | craft:stone_midx50 | 500.0 | 240 | true | false | stone_mid |
| V3_skill_path | craft | craft:stone_midx50 | 500.0 | 225 | true | false | stone_mid |
| V2_first_affordable_talent | craft | craft:stone_midx50 | 500.0 | 230 | true | false | stone_mid |
| V3_skill_path | craft | craft:stone_midx50 | 500.0 | 223 | true | false | stone_mid |
| V1_first_life_no_talents_no_skills | craft | craft:stone_midx50 | 500.0 | 228 | true | false | stone_mid |
| V3_skill_path | craft | craft:stone_midx50 | 500.0 | 216 | true | false | stone_mid |
| V1_first_life_no_talents_no_skills | craft | craft:stone_midx50 | 500.0 | 232 | true | false | stone_mid |
| V1_first_life_no_talents_no_skills | craft | craft:stone_midx50 | 500.0 | 226 | true | false | stone_mid |
| V2_first_affordable_talent | craft | craft:stone_midx50 | 500.0 | 233 | true | false | stone_mid |
| V3_skill_path | craft | craft:stone_midx50 | 500.0 | 242 | true | false | stone_mid |
| V1_first_life_no_talents_no_skills | craft | craft:stone_midx50 | 500.0 | 229 | true | false | stone_mid |
| V2_first_affordable_talent | craft | craft:stone_midx50 | 500.0 | 210 | true | false | stone_mid |
| V3_skill_path | craft | craft:stone_midx50 | 500.0 | 227 | true | false | stone_mid |
| V2_first_affordable_talent | craft | craft:stone_midx50 | 500.0 | 259 | true | false | stone_mid |
| V1_first_life_no_talents_no_skills | level | level:8->9 | 430.0 | 123 | true | false | [] |
| V3_skill_path | level | level:8->9 | 430.0 | 185 | true | false | [] |
| V2_first_affordable_talent | level | level:8->9 | 430.0 | 159 | true | false | [] |
| V2_first_affordable_talent | level | training_level:8 | 425.0 | 175 | true | false |  |
| V3_skill_path | level | training_level:8 | 425.0 | 85 | true | false |  |
| V1_first_life_no_talents_no_skills | level | training_level:8 | 425.0 | 227 | true | false |  |

Segments at or above 600 simulated seconds: 0. See `over_600s` in the JSON for the exact list.

### Longest actionable bottleneck per label

| Run | Kind | Label | Sim s | Detail |
| --- | --- | --- | ---: | --- |
| V2_first_affordable_talent | craft | craft:stone_midx55 | 550.0 | stone_mid |
| V1_first_life_no_talents_no_skills | craft | craft:stone_midx55 | 550.0 | stone_mid |
| V3_skill_path | craft | craft:stone_midx55 | 550.0 | stone_mid |
| V2_first_affordable_talent | level | training_level:9 | 537.0 |  |
| V1_first_life_no_talents_no_skills | level | training_level:9 | 537.0 |  |
| V3_skill_path | level | training_level:9 | 537.0 |  |
| V2_first_affordable_talent | level | level:9->10 | 516.0 |  |
| V1_first_life_no_talents_no_skills | level | level:9->10 | 516.0 |  |
| V3_skill_path | level | level:9->10 | 516.0 |  |
| V1_first_life_no_talents_no_skills | craft | craft:stone_midx50 | 500.0 | stone_mid |
| V3_skill_path | craft | craft:stone_midx50 | 500.0 | stone_mid |
| V2_first_affordable_talent | craft | craft:stone_midx50 | 500.0 | stone_mid |

## Ten-minute policy boundary

- User-named white-body Era1 Lv9->10: 184.0 simulated seconds; below the 600-second limit.
- Actionable single waits at or above 600 simulated seconds: 0.
- Longest actionable single wait: 550.0 simulated seconds (craft:stone_midx55).
- The multi-thousand-second lifespan runout segment is tagged lifecycle/non-actionable in the JSON and is not a resource wait.

## Reincarnation and rebuild

Reincarnation was reached by natural lifespan exhaustion; `rebirth_lotus` and `void_mirror` have no live content entry. Reward, granted resources and rebuild duration are in the variant and milestone tables.

## Talents and skills

V2 learns `resource_inheritance` at level 1 for 5 dao heart. Its inheritance effect applies only at a future reincarnation, so V2 does not realize that effect; the observed production multiplier is the dao-heart bonus from holding 15 dao heart, not the talent's inheritance grant. V3 builds `library`, waits for 90 skill points and learns `basic_meditation`. Other talents, skill combinations and Era3 `golden_core_formation` are intentionally not claimed.

## Uncovered and not claimed

- Only resource_inheritance talent level 1 is observed; other talents and higher talent levels are not replayed.
- Only basic_meditation is learned; skill combinations, qi_condensation, foundation_building, building_mastery_1 and golden_core_formation are not replayed.
- The bot drives commands directly; HUD, building markers, island presentation, input hit areas and animation timing are not observed.
- Wall-clock values here are headless machine time, not a human play session; real-player rhythm, reading time and misclicks are not modelled.
- Touch, phone/tablet, high-DPR, rotation, GPU and cold-start behaviour remain deferred and are not claimed.
- Save/load and offline settlement are not re-run here; res1d2/res1d and other runners own those contracts.
- There is no live content entry for rebirth_lotus or void_mirror, so early reincarnation is unreachable by normal building play in this build; reincarnation was reached by lifespan exhaustion.
- The observation does not judge total-run minutes; it only records segment waits and the 600-second boundary.

## Source hashes

| Path | SHA-256 |
| --- | --- |
| `project.godot` | `df65e69e1f2dd782f8c7e0b1911b20c6bfc0e0064156372031544b90e248ebfe` |
| `content/eras/era1.json` | `7f427b127c109125a6ab773573d21187fc903700e51b921c2c82decbfad926d1` |
| `content/eras/era2.json` | `08117dc87d093ebdcdc399a9b3e19e5fc86a22608090ce8ea85cd1e6caea653b` |
| `content/eras/era3.json` | `0ffd94974e4909800663e089098c1750598792c4ec1c742d8a73b5a1617a172e` |
| `content/buildings/era1.json` | `6f9e61d260ff73954c6d165e6eb7d5cb82d66a32699c6da38b9daf293b2bcbf8` |
| `content/buildings/era2.json` | `a7f915849fa546b7f1f57c8f1f4089ad4bf14573f0e582dea4863aae3e00c1e4` |
| `content/buildings/study.json` | `5507afd1377f2d270274d5e0f77295334fdd4803e5f764aa0e2650c3c43b6a21` |
| `content/skills/era2.json` | `255bb0154bbd9d7cf7329801516f9fb889ea1cde549209fe91e9e49092badc37` |
| `content/skills/era3.json` | `8fd785fc170db581a92fc72984986b5be613f1055d78edf896aa1de8348d61aa` |
| `content/recipes/era1_3.json` | `167e2ac7530cbb69b9e8d202be4bcbeb44b5740e14728305bd726af2ff229f32` |
| `content/resources/era1.json` | `fd2252ac4d81c35a85fb90c19081f91a11c99a22b24e406bf86eb123954e9544` |
| `src/application/game_session.gd` | `c46161883893619028ea5b8a8437164f9306e087c3b6ce5dff45579d65e1286e` |
| `src/simulation/command_processor.gd` | `a86d7778ff41beba6ed8974444f43778cc4544df6603e68ccbcfb94d18f18bd6` |
| `src/simulation/skill_system.gd` | `be69a094061af432ec1541b946b94f7276a77fb008151d558ce06a6bb5327c9f` |
| `src/simulation/talent_system.gd` | `b06898d09cc5ecdf7208bb014800ff42887e497d406eae26b9087935a5b7b332` |
| `src/simulation/reincarnation_rules.gd` | `51b7c6669bbf82e8fae5724b099cd4a189083612523e472f3eaa1f501868cb57` |
| `src/simulation/time_advancer.gd` | `d2579f4593fbcec09d012bec7b7a9d4b12c5894d8dc75fa0bd832f4793f6c991` |
| `src/simulation/production.gd` | `adc4842b3de6468e786621ae316c059f94303364090dc8eb20183d8f98a1ce8d` |
| `src/simulation/onboarding.gd` | `52a1f7d417128978d3027ac812a09eba90f8d63a5c3fc6dfe06b8f3800884ac1` |
| `src/simulation/cultivation.gd` | `587a2e96ec00933ac3d6dfa2ab4f21c791e1ea888eb3107c883194f68b435dc9` |
| `src/simulation/lifespan.gd` | `0fb9ab1e33ca96a0da1150a501734dc41a06fb230f12f8ccbe33e405a675bf47` |
| `src/simulation/island_progression.gd` | `c8abaf54121f6a4883c904f893b8cd31697ec2b3024decc14b8004f3c5030bb9` |
| `src/simulation/island_economy.gd` | `930fbe71eb9d66e2f7e3fc6c57f15b5b83bd1e8131098c1587df7c8750a9b08d` |
| `src/simulation/tribulation_rules.gd` | `40ee8772629dde047a3b7c9f3379ef7283fa011831d084211921a4fde475c2e4` |
| `src/persistence/save_codec.gd` | `f41b324f2ed7d8f64a3df8fad289ba0055fbff3c93f817cd6695015efb89b4e4` |
| `src/verification/res1d2_contract.gd` | `2876297982fd47dfd662d1a7fe7112b94c015a1bd6542a1b82de432663c4440a` |
| `tools/early_pacing_audit.gd` | `cc2a57d335dc911e4e039722b768cf488b5e700c26f7cea107308ae4bfc0a02e` |
| `tools/early_pacing_targets.json` | `04749c0834d5f9f738fabd7cd0c91fe03cd5f3b412595d18b91af1139b812e7e` |
| `tools/early_v1a_observation.gd` | `2b54c6b6a5ad49d2187c46d90cd09fc8de59f29a3996d6fdea51679701998d78` |

## Checks

- Command checks: 2845
- Internal failures: []
