# EARLY-V1-B Reincarnation Talent Observation (fixture-driven)

Engine: 4.7.2-stable (official) | Project: 0.1.0 | Rules: core-flow-12-skills-p1 | Save schema: 4

Content version: `c1b7f1520764d30194af498e0b0c9a12683f53c182716283dd3742ecfde67384+res1-d-2+skills-p1`

Deterministic artifact: no wall-clock values; every recorded second is a simulated second from state and rule values.

## Scope and method

- Real GameSession submit commands for learn_talent and reincarnate; no direct talent, era, resource, building or time mutation during measured steps.
- Fixture setup per isolated session is declared and is not earned play: era 3, level 10, buildings rebirth_lotus = 1, previous lingli stock 777, dao heart 20000, money and wood unlocked.
- rebirth_lotus has no live content entry in this build (no content/*.json reference); it is fixture setup only and is NOT claimed as reachable content.
- One isolated session per variant; three talents x levels 0/1/2/5/10; official learn_talent purchases; official reincarnate with mode normal.
- All recorded seconds are simulated seconds from state and rule values; this matrix is fixture-driven and is not a human or Web session.
- era1_lv1_next_required_seconds comes from the post-reincarnation view; era3_lv10_required_seconds comes from Cultivation.next_level_required_seconds(content.era(3), 10, 0, 1.0) because the era3 level10 view shows the breakthrough panel instead of a next level.
- Start amounts follow ReincarnationRules on the fresh era1 state: only onboarding-unlocked basic resources receive floor(cap x 10% x inheritance level); at a fresh era1 start with cleared buildings only lingli is unlocked.

## Variant matrix (one isolated session per row)

| Talent | Lv | Cost spent | DH before | DH after buy | DH after rebirth | lingli start | Other basic zero+locked | Max lifespan s | Speed bonus | Era1 lv1 req s | Era3 lv10 req s |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- | ---: | ---: | ---: | ---: |
| resource_inheritance (資源傳承) | 0 | 0 | 20000 | 20000 | 20020 | 0.0 | yes | 4800.0 | 0.00 | 60.0 | 1437.0 |
| resource_inheritance (資源傳承) | 1 | 5 | 20000 | 19995 | 20015 | 10.0 | yes | 4800.0 | 0.00 | 60.0 | 1437.0 |
| resource_inheritance (資源傳承) | 2 | 15 | 20000 | 19985 | 20005 | 20.0 | yes | 4800.0 | 0.00 | 60.0 | 1437.0 |
| resource_inheritance (資源傳承) | 5 | 155 | 20000 | 19845 | 19865 | 50.0 | yes | 4800.0 | 0.00 | 60.0 | 1437.0 |
| resource_inheritance (資源傳承) | 10 | 5115 | 20000 | 14885 | 14905 | 100.0 | yes | 4800.0 | 0.00 | 60.0 | 1437.0 |
| lifespan_extension (長生久視) | 0 | 0 | 20000 | 20000 | 20020 | 0.0 | yes | 4800.0 | 0.00 | 60.0 | 1437.0 |
| lifespan_extension (長生久視) | 1 | 10 | 20000 | 19990 | 20010 | 0.0 | yes | 5280.0 | 0.00 | 60.0 | 1437.0 |
| lifespan_extension (長生久視) | 2 | 30 | 20000 | 19970 | 19990 | 0.0 | yes | 5760.0 | 0.00 | 60.0 | 1437.0 |
| lifespan_extension (長生久視) | 5 | 310 | 20000 | 19690 | 19710 | 0.0 | yes | 7200.0 | 0.00 | 60.0 | 1437.0 |
| lifespan_extension (長生久視) | 10 | 10230 | 20000 | 9770 | 9790 | 0.0 | yes | 9600.0 | 0.00 | 60.0 | 1437.0 |
| innate_dao_body (先天道體) | 0 | 0 | 20000 | 20000 | 20020 | 0.0 | yes | 4800.0 | 0.00 | 60.0 | 1437.0 |
| innate_dao_body (先天道體) | 1 | 15 | 20000 | 19985 | 20005 | 0.0 | yes | 4800.0 | 0.10 | 60.0 | 1437.0 |
| innate_dao_body (先天道體) | 2 | 45 | 20000 | 19955 | 19975 | 0.0 | yes | 4800.0 | 0.20 | 60.0 | 1437.0 |
| innate_dao_body (先天道體) | 5 | 465 | 20000 | 19535 | 19555 | 0.0 | yes | 4800.0 | 0.50 | 60.0 | 1437.0 |
| innate_dao_body (先天道體) | 10 | 15345 | 20000 | 4655 | 4675 | 0.0 | yes | 4800.0 | 1.00 | 60.0 | 1437.0 |

## Delta versus level 0 (same talent)

| Talent | Lv | Cumulative cost | lingli start delta | Lifespan delta s | Speed bonus delta | Era1 lv1 req delta | Era3 lv10 req delta |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| resource_inheritance | 1 | 5 | 10.0 | 0.0 | 0.00 | 0.0 | 0.0 |
| resource_inheritance | 2 | 15 | 20.0 | 0.0 | 0.00 | 0.0 | 0.0 |
| resource_inheritance | 5 | 155 | 50.0 | 0.0 | 0.00 | 0.0 | 0.0 |
| resource_inheritance | 10 | 5115 | 100.0 | 0.0 | 0.00 | 0.0 | 0.0 |
| lifespan_extension | 1 | 10 | 0.0 | 480.0 | 0.00 | 0.0 | 0.0 |
| lifespan_extension | 2 | 30 | 0.0 | 960.0 | 0.00 | 0.0 | 0.0 |
| lifespan_extension | 5 | 310 | 0.0 | 2400.0 | 0.00 | 0.0 | 0.0 |
| lifespan_extension | 10 | 10230 | 0.0 | 4800.0 | 0.00 | 0.0 | 0.0 |
| innate_dao_body | 1 | 15 | 0.0 | 0.0 | 0.10 | 0.0 | 0.0 |
| innate_dao_body | 2 | 45 | 0.0 | 0.0 | 0.20 | 0.0 | 0.0 |
| innate_dao_body | 5 | 465 | 0.0 | 0.0 | 0.50 | 0.0 | 0.0 |
| innate_dao_body | 10 | 15345 | 0.0 | 0.0 | 1.00 | 0.0 | 0.0 |

## First two rebirths: dao heart income versus talent cost

- first rebirth income: **20** dao heart; hypothetical second rebirth income: **15**; first-two-rebirth total: **35**.
- basis: era3 fixture building sum 1 -> max(floor(1/10), era3 floor 20); rebuilt era2 fixture -> max(floor(1/10), era2 floor 15); natural income only, fixture dao heart 20000 excluded; all values are rule-derived simulated-state numbers, not a human or Web session.

| Talent | Lv | Cumulative cost | Covered by first rebirth | Covered by first two rebirths |
| --- | ---: | ---: | --- | --- |
| resource_inheritance | 1 | 5 | yes | yes |
| resource_inheritance | 2 | 15 | yes | yes |
| resource_inheritance | 5 | 155 | no | no |
| resource_inheritance | 10 | 5115 | no | no |
| lifespan_extension | 1 | 10 | yes | yes |
| lifespan_extension | 2 | 30 | no | yes |
| lifespan_extension | 5 | 310 | no | no |
| lifespan_extension | 10 | 10230 | no | no |
| innate_dao_body | 1 | 15 | yes | yes |
| innate_dao_body | 2 | 45 | no | no |
| innate_dao_body | 5 | 465 | no | no |
| innate_dao_body | 10 | 15345 | no | no |

All seconds above are simulated seconds; the fixture (era 3, level 10, rebirth_lotus = 1, previous lingli stock 777, dao heart 20000) is declared setup, and rebirth_lotus has no live content entry in this build, so nothing here is a human or Web session claim.

## Checks

- Checks: 145
- Failures: []
