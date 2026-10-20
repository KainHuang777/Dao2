# EARLY-V1-C Skill Observation

Rules: `core-flow-12-skills-p1` | Content: `c1b7f1520764d30194af498e0b0c9a12683f53c182716283dd3742ecfde67384+res1-d-2+skills-p1` | Time basis: simulated seconds only

## Method

- Official GameSession commands; no direct resource, era, level or training injection on the earned path.
- fixture-driven items are labelled: sect contribution/wood setup after official join_sect, rebirth_lotus eligibility flag (no live content entry, SKS-P1 precedent).
- library rates are the Production formula 1 x pow(level,1.5) multiplied by the Era2 resource multiplier 2; caps are the Production/SkillSystem formulas measured through get_view.

## Library point rates and caps

| library level | rate per s (Era2) | skill_point cap |
| --- | ---: | ---: |
| 1 | 2.000000 | 200 |
| 2 | 5.656854 | 200 |
| 3 | 10.392305 | 200 |

Scripture hall cap: **6200** (base 200 + 6000 = 6200 (no storage bonus))

Measured in the earned Era2 session: view rate 2.000/s, library-only cap 200 (stuck at 200), scripture cap 6200, bank filled to 6200 in 630 simulated seconds.

## Era2 skills

| skill | era | cost | max | effect | amount | acq s @Lv1 rate | acq s @Lv3 rate |
| --- | --- | ---: | --- | --- | ---: | ---: | ---: |
| basic_meditation | 2 | 90 | 5 | lingli_multiplier | 1.1 | 45.0 | 8.7 |
| qi_condensation | 2 | 1800 | 5 | lingli_rate | 2.0 | 900.0 | 173.2 |
| foundation_building | 2 | 3600 | 5 | money_multiplier | 1.2 | 1800.0 | 346.4 |
| qi_storage_1 | 2 | 120 | 1 | lingli_max | 200.0 | 60.0 | 11.5 |
| body_strengthening_1 | 2 | 1000 | 1 | money_max | 2000.0 | 500.0 | 96.2 |
| building_mastery_1 | 2 | 200 | 1 | building_level_cap | 10.0 | 100.0 | 19.2 |

## golden_core_formation

- era 3, cost 7650, max 5, effect `time_multiplier` amount 0.9, prerequisite foundation_building >= 1
- acquisition at library Lv1 rate: 3825.0 simulated seconds

### Era3 Lv10 training reductions (derived formula, simulated seconds)

| golden level | required s | cumulative saved s |
| --- | ---: | ---: |
| 1 | 1293.279 | 143.698 |
| 2 | 1163.951 | 416.723 |
| 3 | 1047.556 | 806.144 |
| 4 | 942.800 | 1300.320 |
| 5 | 848.520 | 1888.777 |

## Golden reachability and the 7650 vs 6200 gap

- cost 7650 exceeds the base library+scripture cap 6200 by **1450 points**; without a storage bonus accumulation is provably stuck at 6200, so golden cannot be learned from the base cap.
- official storage path: sect `storage_talisman` adds +10% of every storage cap per level (max 10); at Lv3 the measured skill_point cap is 8060.000 (6200 x 1.3), enough for 7650.
- derived minimum talisman level to fit 7650: 3; derived cap at talisman Lv10: 12400.
- official path reached golden: **true** (fixture-driven setup limited to sect contribution/wood after the official join_sect; purchases and learns are official commands).

## Save and reload

- roundtrip preserves skills: true | unknown skill rejected: true

## Reincarnation clear

- cleared: true | skills empty: true | skill_point 0.0 unlocked=false | library 0 scripture_hall 0 | talents after: {  } | dao_heart after: 15

## Checks

- checks: 12
- failures: []

## Source hashes

| Path | SHA-256 |
| --- | --- |
| `content/skills/era2.json` | `255bb0154bbd9d7cf7329801516f9fb889ea1cde549209fe91e9e49092badc37` |
| `content/skills/era3.json` | `8fd785fc170db581a92fc72984986b5be613f1055d78edf896aa1de8348d61aa` |
| `content/buildings/study.json` | `5507afd1377f2d270274d5e0f77295334fdd4803e5f764aa0e2650c3c43b6a21` |
| `src/simulation/skill_system.gd` | `be69a094061af432ec1541b946b94f7276a77fb008151d558ce06a6bb5327c9f` |
| `src/simulation/production.gd` | `adc4842b3de6468e786621ae316c059f94303364090dc8eb20183d8f98a1ce8d` |
| `src/simulation/sect_system.gd` | `efc165c56e7df93afbbbd60bbc424cb99ca0fa8863d8cf36b39ff651d36456cf` |
| `src/simulation/time_advancer.gd` | `d2579f4593fbcec09d012bec7b7a9d4b12c5894d8dc75fa0bd832f4793f6c991` |
| `src/persistence/save_codec.gd` | `f41b324f2ed7d8f64a3df8fad289ba0055fbff3c93f817cd6695015efb89b4e4` |
| `src/application/game_session.gd` | `a6a127776d3aa8edf589ef542ef1c4783f1111ba2e2729eaafab742874d314d7` |
| `tests/early_v1c_skills_runner.gd` | `53c1623624b000add59910f531658e4c4bf1855c81bd3e820aa9eecee45b5375` |
| `tools/early_v1c_skill_observation.gd` | `7c687e8af51e93aba86a98b2dd7d2525550ed693c2abb565d3c8fed866a8cb0f` |
