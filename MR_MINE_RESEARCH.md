# Mr. Mine progression and systems research

Research note prepared 6 October 2026 for adapting the broad progression patterns to *Taşın Altı*. The game is actively updated: the official Steam announcement lists v47 (13 May 2026), including a higher early mineral-deposit spawn rate, a reworked quest sequence, and new tutorials. Many exact tables on the community wiki still say they were updated for v0.45. Treat those tables as a detailed reference snapshot and verify exact numbers against the current game before encoding them. ([Official v47 notes](https://steamcommunity.com/app/1397920/allnews/); [Materials](https://mrmine.fandom.com/wiki/Materials); [Blueprints](https://mrmine.fandom.com/wiki/Blueprints))

This file records game-system facts and design patterns. It does not call for reusing Mr. Mine's names, dialogue, art, or other expressive content in this project.

## Main loop and drill math

- The starting layer gives the player a drill, Sell Center, Hire Center, Craft Center, quests, and tickets. The drill adds a new mineshaft for each kilometer drilled; each shaft then contributes resources. ([Milestones](https://mrmine.fandom.com/wiki/Milestones); [Drill](https://mrmine.fandom.com/wiki/Drill))
- The four replaceable drill parts are engine, fan/cooling, drill bit, and cargo. Fan and bit contribute base watts; the engine adds its base watts and applies a multiplier; cargo changes how much ore can be held before selling. The developer's example is `(fan 1,000 + bit 700 + engine base 10) × engine multiplier 10 = 17,100 W`. Drill time for a depth is `fixed depth difficulty / total drill watts`. The difficulty rises with depth and is described as a fixed per-depth value, not as a public closed-form curve. ([Official developer blog: drill blueprints](https://blog.mrmine.com/drill-blueprints-elevate-your-mining-in-mr-mine/); [Drill](https://mrmine.fandom.com/wiki/Drill))
- Drill blueprints are crafted or found, then replace the part in that slot; they do not stack. The wiki lists 43 levels each for engine, fan, and bit and 16 for cargo. It explicitly encourages skipping tiers when a better blueprint becomes available. ([Blueprints](https://mrmine.fandom.com/wiki/Blueprints))
- Early blueprint examples illustrate the resource-and-cash sink: Engine Lv. 3 costs `$3,500 + 2,000 coal + 300 copper + 100 silver`; bit Lv. 3 costs `$5,500 + 1,000 coal + 300 silver + 50 gold`; Fan Lv. 3 costs `$15,000 + 900 copper + 200 silver`; Cargo Lv. 2 costs `$1,400 + 200 copper + 1 silver`. By later tiers, recipes require isotopes, oil, and world-specific resources, while the engine multiplier grows substantially. ([Blueprints](https://mrmine.fandom.com/wiki/Blueprints))
- Blueprint access is deliberately gated: Craft Center provides early Earth parts; Golem at 50 km and Broken Robot at 225 km sell later tiers; later parts come from chests, traders, world Craft Centers, and deeper robots. Current wiki mapping: Earth Craft Center Lv. 1–5; Golem Lv. 6–9; Broken Robot Lv. 10–13; chests/trading for Lv. 14–17; Moon starts at 1,032 km with Lv. 18–20; Robot Mk2 at 1,257 km sells Lv. 24–26; Titan starts at 1,814 km with Lv. 33–36, and Robot Mk3 at W3+225 km sells Lv. 37–40. ([Blueprints](https://mrmine.fandom.com/wiki/Blueprints); [Milestones](https://mrmine.fandom.com/wiki/Milestones))

## Miners, storage, and the cash economy

- Each hired miner is added to every newly revealed mineshaft. Earth has 10 miners; after all 10 are hired, 10 tool-efficiency upgrades become available. Miner hiring and upgrades cost cash. Hiring costs on Earth rise from `$50` to `$10 million` across ten slots; tool upgrades rise from `$10 million` to `$100 trillion`. The Moon and Titan each add their own Hire Center and separate, much more expensive worker roster. ([Miners](https://mrmine.fandom.com/wiki/Miners); [Hire Center](https://mrmine.fandom.com/wiki/Hire_Center))
- The wiki's per-shaft production accounting gives each hired miner `+5 percentage points` of base production. The first six tool upgrades add `+7.5 points` each, upgrade seven adds `+5`, and upgrades eight through ten add `+5 points` each, for a listed maximum efficiency of 115% with all miners and upgrades. Marginal gains decline: adding the second miner doubles 5% to 10%, while the tenth moves 45% to 50%, an 11.11% relative gain. ([Hire Center](https://mrmine.fandom.com/wiki/Hire_Center))
- Minerals/isotopes are sold for cash or held for blueprints and trades. Reaching capacity halts miner production until capacity is freed. The player can lock resources so “sell all” preserves materials needed later. ([Materials](https://mrmine.fandom.com/wiki/Materials))
- Cargo is therefore a production constraint, not just a quality-of-life stat: increasing cargo reduces how often the player must intervene, while selling opens capacity and finances cash-only purchases. The official description emphasizes an idle miner crew plus drill upgrades; this capacity loop is documented in the wiki. ([Official Steam page](https://store.steampowered.com/app/1397920/MrMine/); [Blueprints](https://mrmine.fandom.com/wiki/Blueprints); [Materials](https://mrmine.fandom.com/wiki/Materials))

### Earth worker costs (wiki snapshot)

| Slot | Hire cost | Tool-upgrade cost |
|---:|---:|---:|
| 1 | $50 | $10 million |
| 2 | $500 | $50 million |
| 3 | $2,000 | $200 million |
| 4 | $10,000 | $1 billion |
| 5 | $25,000 | $6 billion |
| 6 | $75,000 | $40 billion |
| 7 | $150,000 | $350 billion |
| 8 | $500,000 | $1 trillion |
| 9 | $3 million | $10 trillion |
| 10 | $10 million | $100 trillion |

Source: [Hire Center](https://mrmine.fandom.com/wiki/Hire_Center). The same page says a Pay Cut relic reduces these costs by 5/8/10% by rarity, capped at 80% total reduction.

## Resource unlocks and world progression

The wiki records resource thresholds by mineshaft depth (km), plus a separate “mineral-rich” interval where the resource is more available. This is more nuanced than a simple one-time unlock: a material can become mineable at one depth and become common later. ([Materials](https://mrmine.fandom.com/wiki/Materials))

### Earth minerals

| Mineral | Sell value | First depth (km) | Rich interval (km) |
|---|---:|---:|---:|
| Coal | $1 | 0 | 0–14 |
| Copper | $2 | 4 | 7–19 |
| Silver | $4 | 13 | 18–24 |
| Gold | $16 | 17 | 24–41 |
| Platinum | $32 | 21 | 41–55 |
| Diamond | $64 | 30 | 48–71 |
| Coltan | $500 | 45 | 72–80 |
| Painite | $1,000 | 60 | 81–102 |
| Black Opal | $2,000 | 79 | 103–199 |
| Red Diamond | $10,000 | 80 | 200–300 |
| Blue Obsidian | $20,000 | 93 | 301–400 |
| Californium | $100,000 | 305 | 401–1,000 |

Earth isotopes are additional, rarer resources rather than ore tiers: Uranium starts at 24 km, Plutonium at 34 km, and Polonium at 54 km, with three grades each. They are needed for many blueprints and later systems, so selling them can block progression. ([Materials](https://mrmine.fandom.com/wiki/Materials); [Isotopes](https://mrmine.fandom.com/wiki/Isotopes))

### Worlds and thematic layer sets

| World | Depth span | Progression notes |
|---|---:|---|
| Earth | 0–1,000 km | Starting world; Earth minerals, three isotope families, milestones and bosses. |
| Space transition | 1,000–1,032 km | Short gap; UFO event. |
| Moon | 1,032–1,782 km | Moon minerals/isotopes, own Sell/Hire Centers and Trading Post; Reactor and Buff Lab; bosses every 100 km. |
| Space transition | 1,782–1,814 km | Gap before Titan. |
| Titan | 1,814 km onward | New mineral/isotope pool, own Sell/Hire Centers and Trading Post, later Robot Mk3 and additional bosses. Wiki milestone page lists the current last kilometer at 2,566 km; the Titan page says 2,564 km, so confirm the live cap in-game. |

Sources: [Earth](https://mrmine.fandom.com/wiki/Earth), [Moon](https://mrmine.fandom.com/wiki/Moon), [Titan](https://mrmine.fandom.com/wiki/Titan), [Milestones](https://mrmine.fandom.com/wiki/Milestones), [Worlds](https://mrmine.fandom.com/wiki/Category:Worlds). The pages define worlds and resource pools, not a per-kilometer texture rule. As a visual-design inference, the important biome handoffs are Earth rock → space gap → Moon surface/rock → space gap → Titan ice/rock; detailed single-kilometer art is not specified by the wiki.

Moon and Titan unlocks use large regional depth gates, not the current project's 50-km wall-tint scheme. First mineral depths from the wiki snapshot:

| World | Material (sell value) | First depth |
|---|---|---:|
| Moon | Carbon ($500,000), Iron ($1,000,000), Aluminum ($2,000,000), Magnesium ($5,000,000) | 1,032; 1,041; 1,042; 1,125 km |
| Moon | Titanium ($750,000,000), Silicon ($100,000,000), Promethium ($1.4 billion), Neodymium ($10 billion), Ytterbium ($50 billion) | 1,211; 1,333; 1,462; 1,562; 1,605 km |
| Titan | Tin ($500 billion), Sulfur ($2.5 trillion), Lithium ($10 trillion), Manganese ($750 trillion), Mercury ($7.5 quadrillion) | 1,814; 1,854; 1,878; 2,015; 2,142 km |
| Titan | Nickel ($75 quadrillion), Alexandrite ($1.2 quintillion), Benitoite ($12.5 quintillion), Cobalt ($60 quintillion) | 2,242; 2,317; 2,414; 2,500 km |

Source: [Materials](https://mrmine.fandom.com/wiki/Materials). Moon isotope production begins at specific depths/shafts; later isotopes Einsteinium and Fermium are produced by the Reactor rather than mined directly. Titan introduces Hydrogen and Oxygen isotope families. ([Isotopes](https://mrmine.fandom.com/wiki/Isotopes); [Reactor](https://mrmine.fandom.com/wiki/Reactor))

## Milestones and feature unlocks

| Depth | Unlock / event |
|---:|---|
| 0 km | Drill, Sell/Hire/Craft Centers, quests, tickets |
| 10 km | Super Miners |
| 15 km | Trading Post |
| 45 km | Cave building and drones; clickable caves begin appearing at 46 km |
| 50 km | Golem drill-part shop; scientists/excavations and relics |
| 100 km | Chest Collector (automatic chest storage) |
| 225 km | Broken Robot, higher drill parts |
| 300–305 km | Underground City: Oil Pump, Gem Forge, quests, monsters and weapons/combat |
| 501 km | The Core, sacrificing materials/relics/scientists for a chance at rewards |
| 700 km | Chest Compressor |
| 1,000 / 1,032 km | Earth end / Moon begins; Moon resources and worker center |
| 1,047 km | Moon Trading Post |
| 1,133–1,135 km | Reactor, then Buff Lab |
| 1,257 km | Robot Mk2 |
| 1,782 / 1,814 km | Moon end / Titan begins |
| 1,829 km | Titan Trading Post |
| 2,039 km | Robot Mk3 |
| 2,566 km | Wiki-listed Titan end (cross-check against in-game cap) |

Source: [Milestones](https://mrmine.fandom.com/wiki/Milestones). The official v47 update also says early-game quests were reorganized, deposit spawn rates increased, and starter tutorials were added. ([Official v47 notes](https://steamcommunity.com/app/1397920/allnews/))

## Clickables, caves, scientists, and automation

- Clickable mineral deposits add active interaction alongside passive miners. Deposits are depth-gated and the official v47 update raised early-game spawn rates; this is a version-sensitive system, so use the current patch behavior rather than copying a historical rate blindly. ([Official v47 notes](https://steamcommunity.com/app/1397920/allnews/); [Materials](https://mrmine.fandom.com/wiki/Materials))
- Caves unlock at 45 km and start spawning at 46 km. They are real-time mini-games with a collapse timer; drones navigate branching rooms, collect rewards, and need enough health/fuel to survive hazards. Timelapses do not speed cave timers. Rewards include money, minerals, Building Materials, tickets, chests, buffs, scientists, and timelapses. ([Caves](https://mrmine.fandom.com/wiki/Caves))
- Drones have complementary roles: Basic clears boulders and carries items; Magnetic collects/pulls rewards; Aerial sees farther and ignores boulders/mud/lava but has tradeoffs in fuel/health; Healing supports nearby drones. Radiation damages all drones; mud slows ground drones; boulders block ground paths; lava appears from deeper caves. Drone fuel and drone-specific stats can be upgraded with cash, materials, oil, and later-world resources. ([Caves](https://mrmine.fandom.com/wiki/Caves))
- Scientists unlock at 50 km when the next basic chest is opened. A scientist runs a timed excavation; the player chooses between two mission offers across Easy/Medium/Hard/Nightmare, with increasing duration and death risk. Rewards can include relics, minerals, money, Building Materials, souls, and time boosts. ([Scientists](https://mrmine.fandom.com/wiki/Scientists); [Excavations](https://mrmine.fandom.com/wiki/Excavations))
- Super Miners unlock at 10 km. They are chest-earned specialists with passive or triggered jobs (ore/isotope production, drill speed, auto-selling, chest spawn, buffs, deposit spawn, rewards, etc.) and level using Super Miner Souls. ([Super Miners](https://mrmine.fandom.com/wiki/Super_Miners); [Official Steam page](https://store.steampowered.com/app/1397920/MrMine/))
- Offline automation is gated behind the Manager upgrade: the wiki lists 25% production for up to 12 hours at level 1, 50%/24 hours at level 2, and 100%/48 hours at level 3. Offline chests and monster fights are excluded. ([Manager](https://mrmine.fandom.com/wiki/Manager))
- The Metal Detector helps find chest clickables from the start; at 100 km a Chest Collector stores chests automatically, then a 700-km Chest Compressor converts stored lower-tier chests. ([Metal Detector](https://mrmine.fandom.com/wiki/Metal_Detector); [Milestones](https://mrmine.fandom.com/wiki/Milestones); [Chest Collector](https://mrmine.fandom.com/wiki/Chest_Collector); [Chest Compressor](https://mrmine.fandom.com/wiki/Chest_Compressor))

## Trading, refining, research, and combat

- Trading Posts unlock at 15 km on Earth, 1,047 km on the Moon, and 1,829 km on Titan. Traders rotate offers; upgrades reduce the wait for the next trade. An offer may exchange money or stockpiled resources for needed materials, rewards, or blueprints; trade value varies and isn't guaranteed profitable. ([Trading Post](https://mrmine.fandom.com/wiki/Trading_post); [Milestones](https://mrmine.fandom.com/wiki/Milestones))
- Building Materials are a separate upgrade currency, mainly earned from caves, chests, and excavations. Craft Center structure upgrades consume these plus other materials/money to increase utility systems (trade refresh, manager, storage/chest handling, caves, oil, forge, reactor/buffs). ([Building Materials](https://mrmine.fandom.com/wiki/Building_Materials); [Craft Center](https://mrmine.fandom.com/wiki/Craft_Center); [Upgrades](https://mrmine.fandom.com/wiki/Upgrades))
- The Underground City opens around 300–303 km. Oil Pump produces oil over time and has a finite capacity; upgrade cost increases from `$100 billion + 5 Building Materials` at its first level to `$600 quintillion + 1,000 Building Materials` at level 16 in the wiki snapshot. Oil is also available as chest/excavation rewards and is spent on blueprints and crafting. ([Oil Pump](https://mrmine.fandom.com/wiki/Oil_Pump); [Oil](https://mrmine.fandom.com/wiki/Oil))
- Gem Forge workload is an explicit production-allocation mechanic. Since v0.45, allocated workload crafts gems automatically; documented crafting time is `(slot count / workload) × (base time / 60)`. Example base durations range from 0.05 hours for red gems to 280 hours for yellow gems; assigning more workload shortens time. Gems feed combat upgrades in the current system. ([Forge](https://mrmine.fandom.com/wiki/Forge); [Underground City](https://mrmine.fandom.com/wiki/Underground_City))
- Monsters begin in the Underground City/deeper shafts. The v0.45+ combat system uses weapons from battle chests and gem-funded combat stats; combat was substantially changed in 2024, so older guides to the original weapon-cooldown system are stale. ([Weapons](https://mrmine.fandom.com/wiki/Weapons); [Underground City](https://mrmine.fandom.com/wiki/Underground_City); [Official Steam update archive](https://steamcommunity.com/app/1397920/allnews/))
- At 501 km, The Core introduces a reset-like sacrifice/reward system for minerals, relics, or scientists, intended to exchange current assets for long-term progression chances. ([Milestones](https://mrmine.fandom.com/wiki/Milestones); [Relics](https://mrmine.fandom.com/wiki/Relics))

## What is confirmed, and what remains uncertain

- Confirmed at design level: depth drives mineshaft creation and feature unlocks; drill power drives depth time; workers drive passive output; storage can stop output; cash/materials fund blueprints and structures; increasingly distinct active side systems unlock at milestones.
- Not confirmed as a formula: the exact per-depth difficulty curve. Mr. Mine's own wiki says the values are fixed in game code and do not follow a known fixed generation formula. The current public browser bundle does expose the complete lookup table, so this project now copies those values directly instead of approximating them. ([Drill](https://mrmine.fandom.com/wiki/Drill); [Official developer blog](https://blog.mrmine.com/drill-blueprints-elevate-your-mining-in-mr-mine/); [current official drill source](https://mrmine.com/game/desktop/Shared/staticvalues.js))
- Not confirmed by the wiki: a per-kilometer art/biome schedule within a world. It defines three world identities, their resources, and their transition depths. Thus “Earth/Moon/Titan” is a verified broad art progression; smaller visual bands would be a new design decision.
- Version caveat: exact resource values, blueprint recipes, probabilities, and special-system costs are wiki tables marked for v0.45 in places; official v47 is newer. Validate those exact numbers in a live client before treating them as a current balance target. ([Official v47 notes](https://steamcommunity.com/app/1397920/allnews/); [Materials](https://mrmine.fandom.com/wiki/Materials); [Blueprints](https://mrmine.fandom.com/wiki/Blueprints))

## Primary / reference source index

- [Official Mr. Mine site](https://mrmine.com/)
- [Official Steam store page](https://store.steampowered.com/app/1397920/MrMine/)
- [Official Steam news and patch notes](https://steamcommunity.com/app/1397920/allnews/)
- [Official developer blog: drill blueprints](https://blog.mrmine.com/drill-blueprints-elevate-your-mining-in-mr-mine/)
- [Official developer blog: beginner progression guide](https://blog.mrmine.com/drilling-games-mr-mine-beginners-guide/)
- Community-maintained [Mr. Mine Wiki index](https://mrmine.fandom.com/wiki/Mr._Mine_Wiki), especially [Milestones](https://mrmine.fandom.com/wiki/Milestones), [Materials](https://mrmine.fandom.com/wiki/Materials), [Blueprints](https://mrmine.fandom.com/wiki/Blueprints), [Hire Center](https://mrmine.fandom.com/wiki/Hire_Center), [Caves](https://mrmine.fandom.com/wiki/Caves), and [Scientists](https://mrmine.fandom.com/wiki/Scientists). The wiki is the detailed source for tabular game values; where it conflicts with newer first-party patch notes or the live game, the newer game behavior takes precedence.

## Local Dr Miner project audit

The local project at `D:\github\dr. miner` is a separate Flutter/Flame implementation. Its source code is more authoritative than its `technical_gdd.md` where they disagree.

| Dr Miner source | Observed behavior | Adaptation here |
|---|---|---|
| `lib/services/drill_service.dart`, `lib/models/drill_model.dart` | Drill power is `(fan watts + bit watts) × engine multiplier + engine base watts × engine multiplier`. Upgrade code scales bit watts/cost by `2.2×/3×`, fan by `2×/2.8×`, and engine base/multiplier/cost by `2×/1.5×/3.5×`. | The same combined-power relationship is used by this project's drill assembly. Mr. Mine's published component recipes/prices and depth gates supply the progression data where available. |
| `lib/models/game_state_model.dart` | Drill time is fixed depth difficulty divided by total watts. Earth difficulty is `500 + 800d + 50d²`, where `d` is depth in km. The 1,000–1,032 km gap uses `100,000,000 + 5,000,000 × (d−1000)`. At and beyond 1,032 km the code uses `500,000,000 + 10,000,000 × (d−1032) + 50,000 × (d−1032)²`. | This is Dr Miner's own authored curve. On 2026-10-06 this project replaced that pacing curve with Mr. Mine's live `depthDifficultyTable` and drill-watt formula from its public browser sources; see `MrMineDrillDifficulty` and `GameState.drillRateMetersPerSecond`. |
| `lib/core/constants/game_constants.dart` | Supplies the Earth depth difficulty function used by `GameStateModel`. | The function is documented above for traceability; it is not imported into the target game. |
| `lib/game/components/mineshaft_component.dart`, `lib/game/layers/background_layer.dart` | Renders its own repeating shaft segments and switches world art by depth. | The target keeps its stronger existing art and uses fixed 1 km visual tiles with seams aligned to tile boundaries. The Mr. Mine wiki defines Earth/Moon/Titan worlds, not a per-kilometre image schedule. |
| `technical_gdd.md` | Describes a cloned game and lists Titan at 1,782 km. | That conflicts with the local implementation's lunar formula and with the Mr. Mine wiki's Titan start at 1,814 km. This project follows the Mr. Mine 1,814 km transition and keeps the 1,782–1,814 km space gap. |

The target already has counterparts for the broader loop—miners and mineshafts, managers/offline production, Super Miners, caves/drones, scientists/relics, chests, trading, the Underground City, reactor, and buffs. The 2026-10-07 audit aligned the drill's watt and depth difficulty inputs, level rarity rows, blueprint recipes, 16 cargo tiers, Moon/Titan sale values, and source-driven first-discovery depth lookups with current public browser data. Project-specific side systems and legacy-only ores remain adapted, so this is a close mechanics port rather than a claim that every current Mr. Mine system and balance value has been reproduced. The target still stores cash and sale values as Dart `double`, while the source uses `BigNumber`; high-value transactions therefore lose integer precision, and source relic-based isotope decay plus source-specific blueprint acquisition are not yet represented one-to-one.
