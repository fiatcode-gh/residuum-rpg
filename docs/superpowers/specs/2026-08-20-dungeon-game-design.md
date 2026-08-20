# Residuum — Design Specification

Date: 2026-08-20
Status: Approved design, pending implementation plan
Working title: **Residuum** (renameable at any time; named after the dead god's residue in the story premise)

## 1. Vision

A single-player, offline-first, turn-based dungeon crawler for the phone, built in Flutter.
The player is one persistent hero in a medieval fantasy world (dragons, ghouls, giants).
The core loop: enter a seeded dungeon, fight on a grid, loot, train skills by using them,
bank the loot in town, push deeper. Around that core: free-roam travel on a world map with
random encounters, towns with quests and merchants, and a hand-authored main story with a
plot twist and an open ending that feeds late-game grinding.

### Goals, in priority order

1. A game the author actually plays for fun on their own phone.
2. A learning and portfolio project (clean architecture, test-driven).
3. A long-term hobby garden — extensible, no pressure to "finish".
4. Optionally, an app-store release — only if the game earns it.

Scope decisions always favor goal 1: fastest path to a fun loop.

### Non-goals (for now)

- Real-time action combat.
- Walkable town maps (towns are menu screens first).
- Branching dialogue trees (sequential dialogue pages first).
- Multiplayer, accounts, servers, cloud saves — never.

## 2. Decided fundamentals

| Decision | Choice |
| --- | --- |
| Moment-to-moment gameplay | Turn-based on a tile grid (classic roguelike movement and combat) |
| Visuals | Colored glyphs on a grid first; renderer designed so a 16x16 pixel-tile atlas can replace glyphs later without gameplay changes |
| Platform | Phone, touch-first, portrait. Desktop/keyboard is a possible later ring |
| Death model | Persistent hero. Death returns you to the last town, loses unbanked loot from the run, keeps skills and equipped gear, and reshuffles the dungeon (new floor seeds) |
| Engine | Plain Flutter. No Flame at first (turn-based needs no real-time loop). Flame may be added later strictly as a renderer |
| Story authorship | AI-written prose, author-steered direction. Longer main arc: 3 acts, 12–18 beats |
| Offline | Everything local. JSON snapshot saves. No network dependency |

## 3. Architecture

### 3.1 Package layout

Monorepo with three Dart packages:

```
residuum/
  packages/
    core/       # pure Dart, zero Flutter imports — all rules and state
    content/    # pure Dart data: creatures, items, skills, quests, story text
    app/        # the Flutter app — rendering, input, screens, save files
```

- **core** knows *how* the game works: turn resolution, combat math, generation
  algorithms, skill training, loot rolling, quest state machine. It never knows what a
  "ghoul" is. It is headless: a full dungeon crawl can run inside a unit test.
- **content** knows *what exists*: creature stats, items, affixes, spells, armor sets,
  dungeon themes, quest beats, story text. Mostly declarative data.
- **app** draws state and forwards input. It contains no game rules. A rule appearing in
  a widget is a bug by definition.

Adding a monster, item, or quest touches only content. Mass-generating content later
(with AI assistance) is safe because logic is untouched.

### 3.2 Testing strategy

- **core**: behavior tests, test-driven development. Examples: "seed 42, floor 3 is fully
  connected and contains exactly one stairway", "a ghoul dies in 3 hits at Arms 30".
- **content**: validation tests. Examples: "every item ID referenced by a loot table
  exists", "every quest beat has a trigger", "every spell's school is a real skill".
- **app**: presentation kept thin; verified manually on device (consistent with the
  author's BLoC-projects convention of no widget tests).

### 3.3 Determinism and randomness

One **world seed** is chosen at new-game time (or typed in by hand — shareable worlds).
Everything derives hierarchically:

```
worldSeed
 ├─ dungeonSeed(locationId)      # each dungeon's identity
 │   └─ floorSeed(depth, visit)  # each floor's layout; `visit` bumps on death reshuffle
 ├─ encounterSeed(travel step)   # overworld random encounters
 └─ lootStream, combatStream     # per-run random-number streams
```

Rules, enforced by convention and tests:

1. **No global randomness.** Every function needing randomness receives an `Rng` object.
   An unseeded `Random()` never appears in core or content.
2. **Layout is a pure function of seed.** `generateFloor(floorSeed, depth, theme)` always
   returns the identical floor. Loot and combat rolls use separate streams so acting in a
   different order never reshuffles the map.

## 4. Dungeons

- **Model:** a floor is a tile grid (wall, floor, door, stairs up/down, water, trap,
  chest) plus an entity list (monsters, ground items). Field of view and fog of war.
- **Generation:** rooms-and-corridors via binary space partition, connected corridors,
  full-connectivity guaranteed by a flood-fill check. Proven and simple. Fancier
  generators (cellular-automata caves, ruins) arrive later as theme variants.
- **Themes:** each dungeon location has a theme (crypt, sea-cave, ruined keep, giant
  camp) selecting generator flavor, monster palette, loot bias, and glyph colors.
  Themes are content, not code.
- **Structure:** each dungeon is a named node on the world map with fixed personality
  (theme, depth range, boss) but floors reshuffled per visit-after-death. Bottom floor
  holds a boss, a guaranteed rare drop, and often a quest beat.

## 5. Combat

- **Turn model:** speed clock. Every actor has a speed stat; faster actors act more
  often. Each action (move, attack, cast, drink, wait) costs time. Speed is a meaningful
  gear stat.
- **Combat math:** readable, no opaque formulas. Attack = weapon base + skill bonus +
  gear bonus, versus defense = armor + Shieldcraft. Damage types: slash, pierce, blunt,
  fire, frost, shock, poison. Monsters have resistances, making weapon choice matter
  (skeletons shrug off arrows; ghouls burn well).
- **Tactical depth from the grid:** corridors to fight one enemy at a time, doors to
  break line of sight, water that slows, traps that can be lured onto enemies. Cheap
  tile rules, big tactical payoff.
- **Overworld encounters reuse this engine** on small single-floor open maps.

## 6. Skills (learn by doing)

- No skill points. Using a thing trains it: swinging a one-handed weapon raises Arms,
  getting hit in heavy armor raises Bulwark, casting an offensive spell raises Wrath.
- Levels 0–100, rising experience cost per level. Each level gives a small passive bonus.
  Milestone levels (25/50/75/100) grant a **perk** chosen from 2–3 options — light build
  decisions without a giant tree.
- **Character level** derives from skill levels; it gates story beats and dungeon
  difficulty tiers.
- **The thirteen starter skills** (each a content entry: name, training trigger,
  per-level bonus, milestone perks):

| Skill | Trains by |
| --- | --- |
| Arms | striking with one-handed weapons |
| Might | striking with two-handed weapons |
| Marksmanship | ranged hits |
| Shieldcraft | blocking with a shield |
| Bulwark | being hit in heavy armor |
| Fleetfoot | being hit / dodging in light armor |
| Wrath | offensive spells |
| Mending | healing and warding spells |
| Binding | summoning and control spells |
| Shadowing | moving unseen near enemies |
| Larceny | opening locks, disarming traps |
| Herbcraft | gathering herbs, brewing potions |
| Blacksmith | mining ore, smelting, forging, tempering |

Weapon mastery is intentionally folded into these skills rather than a separate
per-weapon-type track. Per-weapon-type mastery can be an additive later ring.

## 7. Loot and equipment

- **Rarity tiers:** Common / Fine / Rare / Epic / Legendary. Rarity controls the number
  and strength of affixes rolled onto a base item ("Fine Iron Sword of Embers: +2 slash,
  +3 fire"). Base items and affixes are content; the generator combines them, so a small
  content file yields thousands of distinct drops.
- **Color-blind accessibility (author is deuteranomalous):** rarity is encoded by border
  shape/marking plus a prefix word, never by hue alone. Every screen must stay legible in
  greyscale. This applies to all state and category encodings in the UI, not just rarity.
- **Slots:** head, chest, hands, feet, main hand, off hand, amulet, two rings.
  Off hand holds a shield, a torch (extends light radius — light versus a free hand is a
  real decision under fog of war), or nothing.
- **Armor sets:** named sets (content) with 2-piece and 4-piece bonuses. Set pieces drop
  only in specific dungeons — grinding gets a destination.
- **Spell books are consumables:** read once, learn the spell permanently, book is gone.
  Each spell requires a school skill level to learn (e.g. "needs Wrath 25"), so rare
  books found early become goals. Specific books drop in specific dungeons, like sets.
- **Economy:** merchants buy junk; gold buys potions, lockpicks, gap-filler gear. The
  town bank stores loot; only banked loot survives death.

### 7.1 Crafting (Blacksmith and Herbcraft)

Design guard: **crafting serves loot, it never competes with it.** Skyrim's Smithing
broke its own loot game by letting crafted-and-tempered gear beat every dungeon reward;
Residuum explicitly avoids that.

- **Gathering:** ore veins and herb nodes appear as tiles in dungeons (and in some
  travel events). Mining trains Blacksmith; gathering herbs trains Herbcraft. Monsters
  and chests can also drop ingots and reagents.
- **Stations:** smelting and forging happen at the town forge; brewing happens at the
  town alchemist (basic potions also brewable at camp). No portable forge — town trips
  stay meaningful. Towns gain a Forge button.
- **Recipes are loot.** Common recipes (basic gear, minor potions) are known from the
  start. Better recipes drop in dungeons — crafting power is itself loot. Crafted gear
  caps at **Epic** via rare recipes. **Legendary items and armor-set pieces are never
  craftable** — found only.
- **Tempering (the star of Blacksmith):** spend ingots to upgrade a *found* item's stats
  by tiers (+1/+2/+3), gated by Blacksmith level. Milestone perks: cheaper tempering,
  higher tiers, set-piece tempering at 75+. Best-in-slot is always a found item you
  invested in, so drops stay exciting.
- **Herbcraft mirrors this:** gather → brew at a station → advanced recipes as dungeon
  drops. Potions are consumables, so Herbcraft never threatens the gear loot loop.

## 8. Overworld

- **Node graph, not a walkable grid.** Locations (towns, dungeons, landmarks) are nodes;
  roads and wilderness routes are edges with travel cost in days. Tap a destination;
  travel advances day by day.
- **Random encounters (classic Fallout style):** each travel day rolls against the
  route's danger table from `encounterSeed`. Most days pass quietly. Combat encounters
  drop into a small generated map using the dungeon combat engine. Non-combat events:
  merchant caravans, shrines, travelers with rumors.
- **Discovery:** the map starts mostly hidden. Rumors, quest beats, and adjacency reveal
  routes and locations. Free roam, but the world unfolds.
- Rendered with plain Flutter widgets — a stylized map screen.

## 9. Towns and quests

- **Towns are menu screens, not maps:** arrive → buttons for Merchant, Alchemist, Tavern
  (rumors and side quests), Quest giver, Bank, Rest. Walkable towns are a possible later
  ring.
- **Side quests are procedural templates:** clear dungeon X to floor N, kill named beast,
  fetch item, deliver package — rolled from town and world state, paying gold and
  reputation. No prose burden, infinite supply, directs the grind.
- **Main quests are hand-authored beats** unlocked by triggers: character level, dungeon
  cleared, item found. Dialogue is sequential pages (no branching trees at first).

## 10. Story

Prose is AI-written and author-steered. Shape (steerable):

- **Premise:** the dead god whose residue is the source of all magic is not entirely
  dead. Dungeons are wounds in the world where residue pools — which is why they refill
  with monsters. The death-reshuffle mechanic is thereby a story fact, not a gamey
  excuse. The player starts as a nobody scavenging dungeon scraps.
- **Act 1 — establish:** scavenger to somebody; first contact with the residue's voice.
- **Act 2 — complicate:** the factions "protecting" the world from the residue are
  farming it; twist seeds planted.
- **Act 3 — twist and open ending:** the final choice changes the player's relationship
  to the grind rather than ending the world; the post-ending world keeps generating
  dungeons — that is the late game.
- 12–18 beats total, roughly 3 acts. Dragons, giants, and ghouls get lore hooks into the
  residue so the bestiary feels authored.
- Environmental lore everywhere it is cheap: item flavor text, dungeon names, boss
  intros, tavern one-liners.

## 11. Saves and offline

- Save = JSON snapshot of core game state (character, world flags, quest states, stash),
  written by the app package. No server, no accounts.
- Autosave on floor change, town arrival, and app pause. Three manual slots.
- Core state objects implement `toJson`/`fromJson` with round-trip tests.
- A save-version field exists from day one so future saves can be migrated, not broken.

## 12. Milestones (each ends playable on a phone)

1. **M1 — The Crawl.** One hardcoded dungeon, glyph renderer, tap-to-move and
   tap-to-attack, one weapon, one monster type, HP, death. The moment of truth: is
   walking a dungeon fun?
2. **M2 — The Loop.** Seeded generation, ~5 monster types, loot with rarities, inventory
   and equipment slots, 4 starter skills training by use, town screen with merchant and
   bank, death penalty.
3. **M3 — The World.** Overworld node map, 3 themed dungeons, travel encounters, rumors,
   side-quest templates, all 13 skills, spell books and first spells, gathering nodes,
   town forge and alchemist with basic (recipe-free) crafting and tempering, saves
   hardened.
4. **M4 — The Story.** Act 1 beats, armor sets, boss floors, milestone perks.
5. **M5+ — The Garden.** Acts 2–3, recipe drops (Epic crafting, advanced potions), more
   themes/sets/spells, pixel-tile renderer swap, balance passes. The hobby-garden ring,
   indefinitely.

## 13. Error handling and robustness

- Generation is validated post-hoc (connectivity flood-fill, stair reachability); a
  failed validation regenerates with a derived retry seed and logs the original — the
  player never sees a broken floor.
- Save loading validates the version field and structure; a corrupt save falls back to
  the previous autosave rather than crashing, and reports what happened.
- Content validation tests run in continuous integration so a bad content entry fails
  the build, not the game.
