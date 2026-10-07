# Mr. Mine: ore production and inventory research

Research note for the mining and inventory integration. This covers the current public Mr. Mine browser bundle, community wiki sources, and a short hands-on session in the CrazyGames v0.47 build. The CrazyGames session used a separate temporary browser profile and a newly created save; no local project save was changed.

## Source precedence and version caveat

The most concrete formulas below come from the current public browser game's JavaScript bundle. These are live URLs and can change with a game update. The Fandom wiki pages are useful for names and player-facing explanations, but some tables are older: for example, its v0.45 cargo table differs from the current live cargo script. Prefer current official bundle behavior when values disagree.

- [Official browser game](https://mrmine.com/game/desktop/index.html)
- [Mineral management](https://mrmine.com/game/desktop/Shared/mineralmanagement.js)
- [Static values and mineral-by-depth table](https://mrmine.com/game/desktop/Shared/staticvalues.js)
- [Worker management](https://mrmine.com/game/desktop/Shared/workermanagement.js)
- [World initialization](https://mrmine.com/game/desktop/Shared/world.js)
- [Drill and cargo levels](https://mrmine.com/game/desktop/Shared/drillmanagement.js)
- [Player stats and modifiers](https://mrmine.com/game/desktop/Shared/PlayerStats.js)
- [Clickable deposits](https://mrmine.com/game/desktop/Shared/worldclickables.js)
- [Offline progress](https://mrmine.com/game/desktop/Shared/offlineprogress.js)
- [Super Miner behavior](https://mrmine.com/game/desktop/Shared/src/superminers/superMiner.js)
- [Miner Super Miner types](https://mrmine.com/game/desktop/Shared/src/superminers/baseMiners.js)
- [Settings window](https://mrmine.com/game/desktop/popups/SettingsWindow.js)
- [Official release notes](https://steamcommunity.com/app/1397920/allnews/)

Relevant community references:

- [Capacity](https://mrmine.fandom.com/wiki/Capacity)
- [Materials](https://mrmine.fandom.com/wiki/Materials)
- [Clickable deposits](https://mrmine.fandom.com/wiki/Clickable)
- [Hire Center](https://mrmine.fandom.com/wiki/Hire_Center)
- [Miners](https://mrmine.fandom.com/wiki/Miners)
- [Sell Center](https://mrmine.fandom.com/wiki/Sell_Center)
- [Manager](https://mrmine.fandom.com/wiki/Manager)
- [Blueprints](https://mrmine.fandom.com/wiki/Blueprints)
- [Buff Lab](https://mrmine.fandom.com/wiki/Buff_Lab)
- [Japanese community wiki](https://wikiwiki.jp/mrmine/)

## Passive mine production

The mine loop runs every 100 ms. It checks every open mineshaft floor and only attempts a mineral roll when that floor's worker gate passes:

```text
(2 * workersHiredAtDepth + 3 * workerLevelAtDepth) > rand(0, 39)
```

With the game's integer random range, this is a per-tick gate probability of `(2H + 3L) / 40`, capped at 100%, where `H` is that world's hired-worker count and `L` is its worker upgrade level. It gates the resources at that floor; workers are not assigned to individual floors.

For each mineral/isotope defined at that floor, the game then makes an independent rarity roll. The threshold is approximately:

```text
round(rarityWeight * findMultiplier)
```

Success is a random integer in `[0, 999]` below that threshold, yielding one unit (isotope decay can convert a find to a lower isotope tier). Ordinary minerals use `STAT.minerSpeedMultiplier()` plus additive Super Miner mineral bonuses. Isotopes use the isotope-find multiplier and isotope bonuses. Worker levels 8–10 multiply the find multiplier by another 1.05 per level above 7.

Expected rate for one resource at one floor is:

```text
rarityWeight * findMultiplier / 1000 * workerGateProbability * 10
```

The final `10` converts the 100 ms loop to ticks per second. Sum the result over every open floor and every resource listed for that floor in `staticvalues.js`. Resource availability and rarity are therefore depth-table driven, then modified by stats and workers.

Each hired worker adds `2/40 = 5` percentage points to the worker gate at every floor in that world. Worker levels 1–6 add `3/40 = 7.5` points each; level 7 adds `2/40 = 5` points. That reaches a 100% gate at 10 hires plus level 7. Levels 8–10 then each add 5% to the resource find multiplier. Worker hires and upgrades are world-specific, while each world's rate applies across its shafts. Earth begins with zero workers and level 0; Moon and Titan begin with one worker. There are at most 10 hires per world, and worker upgrades unlock after all 10 hires.

The live bundle's UI production estimator appears to apply miner-speed to isotope estimates too, while the actual mining loop uses the isotope-find multiplier for isotope rolls. For implementation, model the actual mining loop rather than copying the displayed estimate unless this is reconciled against in-game observation.

## Global cargo capacity

Cargo capacity is one shared limit, not a separate allowance per mineral or per world. The game sums all resource records flagged `countsTowardsCapacityAndValue`. This includes normal minerals across Earth, Moon, and Titan, plus tier-1 isotopes. Isotope tiers 2 and 3 do not consume cargo capacity. Special materials with their own storage rules are not part of this mineral cargo sum.

```text
max capacity = current cargo item's capacity * cargoCapacityMultiplier
used capacity = sum(count for each resource that counts toward capacity and value)
```

Buffs and relics can modify the multiplier. When used capacity is at or above the maximum, passive mineral production halts globally; drill depth can continue progressing. Chests, excavation, and other direct rewards can take the inventory over capacity. Passive production resumes once inventory drops below the limit.

Current live cargo progression:

| Cargo | Capacity |
|---|---:|
| Junk | 1,500 |
| Nano | 7,500 |
| Micro | 15,000 |
| Small | 50,000 |
| Decent | 150,000 |
| Large | 500,000 |
| Huge | 1,000,000 |
| Giant | 2,000,000 |
| Enormous | 3,500,000 |
| Extreme Industrial | 5,000,000 |
| Gold King | 10,000,000 |
| City | 25,000,000 |
| Country | 100,000,000 |
| Planet | 200,000,000 |
| Vacuum Packed blueprint | 500,000,000 |
| Double Vacuum Packed blueprint | 1,000,000,000 |

The Fandom v0.45 cargo list reports Giant at 1.5m and Enormous at 3m, which conflicts with the current live script's 2m and 3.5m values.

## Clickable mineral deposits

The ordinary mineral-pile path selects the most common non-isotope mineral at a depth. The selected depth is within the last 100 km of progress, and the standard spawn path requires progress beyond 100 km. Current official logic chooses the reward amount using the larger of two estimates, caps the base amount, then applies deposit and depth modifiers:

```text
amount = min(500,000,000, max(A, B))
         * depositMineralMultiplier
         * depthMultiplier

A = random(10 .. max(10, depth / 2)) minutes * that mineral's expected rate per minute
B = total mineral value per second * random(10 .. 20) minutes / selected mineral's sale value
```

The deposit takes five clicks and awards one fifth of its amount per click. Deposit rewards are direct inventory additions and can overfill cargo. The wiki says piles can contain one of the last three mineral types and that amounts are undocumented; the current code instead picks the dominant non-isotope mineral for the selected depth, so the live code is the more precise current reference. The number of simultaneously active piles is capped by the clickable limit and Deposit Super Miner effects.

## Selling, locks, and automated selling

Selling a resource removes:

```text
max(0, owned amount - locked minimum)
```

The lock is a retained minimum, and applies to both individual sale and Sell All. Cash is base sale value times amount times the sell-price stat multiplier. A Midas roll can double the sale operation. Stat bonuses from relics, buffs, and Super Miners are combined through the player-stat system and may have a maximum-impact cap.

There is no universal autosell toggle in the current game. Seller Super Miners sell their selected mineral over time at `floor(rarity.scaleFactor * 10 * level)` units/second; the sale function respects locks. The Legendary Master Mined Super Miner also sells mineral holdings when they exceed twice cargo capacity, subject to the lock. Official release notes say mineral locking is now available from the start (v0.47); the older wiki requirement that a Manager is needed is stale. The v0.46 notes add Lock All.

## Offline progress

The Manager controls offline mining efficiency and duration: level 1 is 25% efficiency up to 12 hours, level 2 is 50% up to 24 hours, and level 3 is 100% up to 48 hours. Effective time is capped by the Manager's duration multiplied by offline-duration stats, then scaled by efficiency. The game simulates a time lapse, so normal drilling/mining and supported auto-sell work progress during that interval. Chest Collector has its own offline collection logic; ordinary chest/cave events are not all replayed as if the player were present.

## Starting state and settings/debug controls

The current browser build starts with 0 money and level-1 Junk Cargo capacity of 1,500; Earth worker count/level start at zero. The official settings window includes manual save (autosave is also noted every 30 seconds), save export, fullscreen when supported, return to main menu, language, music, click/isotope/capacity-warning sounds, visual-effect toggles, event log, help, stats, and a debug-log viewer. It does not include unlimited money, reset, or skip-to-end cheats. Those requested debug controls in Dr. Miner would be new developer features, rather than Mr. Mine mechanics.

## Dr. Miner implementation note

During normal short play ticks, Dr. Miner performs ten 100 ms worker-gate and per-resource rarity rolls across opened shafts, using the source level table and shared cargo limit. Long/offline advances use summed expected rates plus fractional carry so a 48-hour timelapse does not need to replay billions of individual random rolls. This keeps expected yield aligned while offline results are smoother than Mr. Mine's individual random drops.

## CrazyGames hands-on check (v0.47)

- Started a fresh CrazyGames slot, then loaded it from the save list. The displayed game version is v0.47. At the beginning, the cash counter is $0 and there are no hired Earth workers; the Hire Center shows the first hire at $50.
- The opening coal clickable awarded +2 coal per click for five clicks, for 10 coal total. Clicking it again after it disappeared did not add more. This verifies that clickables are a limited set of clicks which award a fraction per click, rather than an unlimited tap-to-mine action. The wiki/live source describes the standard deposit as five equal portions; the opening 0-km coal clickable appears to be a tutorial-specific early exception to the usual >100-km spawn gate.
- The Sell Center has separate **Maden Sat** and **İzotop Sat** tabs, one **SAT** action per resource, lock icons by rows, and **HEPSİNİ SAT** for the active region. The observed coal row priced 10 coal at $10; selling it cleared the owned amount and raised cash by $10. This agrees with the $1/coal rate. Unrevealed resources appear as question-mark rows.
- The HUD shows a single capacity percentage and one capacity total; it did not show per-mineral capacity bars. The small label looked like “15K” in the captured session, while the current shared browser bundle initializes level-1 Junk Cargo at 1,500. Treat that visual reading as unresolved (possible decimal/scale ambiguity or a CrazyGames-only start difference) and use the live `equippedDrillEquips[CARGO_TYPE] = 4` initialization plus the equipped cargo table as the current source of truth unless the game UI can be rechecked at readable scale.
- The settings gear opens tabs for Settings, Event Log, Help, and Statistics. The General tab has save/export, mobile play, return-to-menu, privacy/language controls; music, sound, isotope sound, and full-capacity sound toggles; and visual toggles for miner/resource effects, drill highlights, Super Miner hitboxes, and trade alerts. This is useful reference for the conventional settings menu. The game exposes a debug log, but no unlimited-money/reset/end-depth cheats.
- The drill advanced from 0 km while the Sell Center and Hire Center were closed and before any worker was hired, consistent with drill depth progress being independent of worker production and cargo fullness. The first resource clickable could be collected separately from the passive worker system.

The hands-on session was intentionally limited to the opening loop. Later milestones (isotopes, locked selling, managers, offline progression, and autoselling) are covered by the current live source and wiki facts above; the new game was not artificially advanced into later regions.

The CrazyGames session was played as described above and intentionally stopped after the opening loop. Later progression was read from the current official browser source and cross-checked against the wiki; the save was not artificially advanced into later regions.
