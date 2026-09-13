# Story spec — M2T "Town" — unit `m2-town` (last of three M2 units)

Canonical sources (read all, in this order):
- The existing code on `main` (`69d55e4`) — all of `packages/core` and
  `packages/content, plus `packages/app/lib/game/`. M2L's `Loadout, `GameState` (inventory/equipment/skills/dropTables/lootRng), items and the
  seven actions are the extension points; read them before planning.
- Code conventions: `CLAUDE.md` at the worktree root.
- Game design spec (sections 2 death model, 9 towns): `docs/superpowers/specs/2026-08-20-dungeon-game-design.md`.
- Ledger decisions binding here: D8 (unit split), D14 (exit model, death cost,
  pierce) — restated below.

## Goal

The loop closes: a run starts in town, the hero enters the dungeon, descends
or ascends between persistent floors, returns to town at any stairs with the
haul — or dies and loses everything unbanked — then sells, banks, rests, and
re-enters a reshuffled dungeon. Deeper monsters pierce armor so mid-depth
fights stay decisions. Measurable effect: suites green (baseline fresh
2026-08-21: 273 core + 69 content + 42 app = 384), the survivability band
holds 50–95% WITH pierce in the bestiary, and a human can play the full
banked-loot loop on the AVD including dying and re-entering.

## Locked scope decisions (D8/D14 — do not re-litigate)

- **Exit model:** stairs-down tiles offer Descend or Return-to-town;
  stairs-up tiles (new, on floors 2–5, at the descent arrival point) offer
  Ascend or Return-to-town. Floor 1 has no stairs-up tile; Return-to-town
  from any stairs is the exit.
- **Floor persistence within a run:** revisiting a floor restores its exact
  state (tiles are static; monsters, ground items, explored/visible are
  snapshotted). Monsters are frozen while the hero is elsewhere. Reshuffle
  (visit++) happens on every dungeon ENTRY and every death — never mid-run.
- **Death penalty:** carried inventory and carried gold are lost; equipped
  gear and skills survive; banked items and banked gold survive; the hero
  wakes in town at full hp; the dungeon reshuffles.
- **Pierce:** creatures gain a `pierce` stat; effective armor against that
  creature = `max(0, heroArmor - pierce)`; the floor-of-1 rule is unchanged.
  Content: pierce 0 on shallow creatures; meaningful pierce on depth-3+
  creatures (numbers worker-tunable, survivability band binding).
- **Economy:** gold exists; monsters do NOT drop gold — selling items to the
  merchant is the gold source. Merchant sells potions and a small rotating
  stock of gear. Inn rest heals to full for gold. Bank stores items and gold.
- **Rename:** `EquipRefused` → `ActionRefused` (follow-up 11), since it
  already carries pick-up refusals. Mechanical, one commit.
- NOT in scope: quests, rumors, multiple dungeons/towns, overworld (M3);
  safe points (follow-up 8); the QOL backlog (follow-up 12); set bonuses,
  perks (M4).

## Shape

Follow the merged idioms: value objects with equatable; pure functions over
values (the `Loadout` derivations are the model — town transactions should
read the same way); events for everything the dungeon log narrates; content
as consts + factories; feature folders (`town/` joins `loot/` and `skills/`).
The architectural line this story draws: **`step()` stays dungeon-only.**
Town is not a `GameAction` — town transactions are pure functions over a new
`Profile` value, and the dungeon run begins and ends by explicit conversion
(`startRun` / `endRun`). The app owns which screen is showing.

## New files

```
packages/core/
  lib/src/town/profile.dart      # Profile — the hero between runs
  lib/src/town/town.dart         # buy/sell/rest/deposit/withdraw transactions
  lib/src/town/run_boundary.dart # startRun(), endRun()
  test/town/...

packages/content/
  lib/src/economy.dart           # prices, inn cost, merchant stock rolling
  (bestiary gains pierce; drop/spawn tables retuned as needed)

packages/app/
  lib/town/town_screen.dart      # menu: Merchant, Bank, Inn, Enter Dungeon
  lib/town/merchant_screen.dart
  lib/town/bank_screen.dart
  (a top-level bloc or two owning the town<->run flow — worker's plan decides)
```

## Changed files

```
packages/core/lib/src/engine/game_state.dart   # + gold, floors (snapshots), stairsUp
packages/core/lib/src/engine/action.dart       # + AscendAction
packages/core/lib/src/engine/event.dart        # + Ascended; EquipRefused -> ActionRefused
packages/core/lib/src/engine/step.dart         # ascend/descend snapshot swap; pierce in _defend
packages/core/lib/src/loot/... (if pierce touches derivations)  # effective armor vs attacker
packages/core/lib/src/dungeon/generator.dart   # GeneratedFloor gains stairsUp placement (floors 2+)
packages/core/lib/src/dungeon/tile.dart        # + stairsUp tile ('<')
packages/core/lib/src/dungeon/floor_map.dart   # parse/support '<'
packages/content/lib/src/bestiary.dart         # pierce values
packages/content/lib/src/new_game.dart         # newGame -> newProfile + startRun split
packages/app/lib/game/...                      # stairs controls (Descend/Ascend/Leave), death screen -> town
```

Never touch `docs/epic/`.

## Per-item contract

### Profile (town/profile.dart)

```dart
class Profile {            // value object; everything that survives between runs
  final Actor hero;        // base body: hp=maxHp in town, base stats
  final Equipment equipment;
  final Map<SkillId, SkillState> skills;
  final List<Item> inventory;   // carried
  final int gold;               // carried
  final List<Item> bank;        // banked items
  final int bankedGold;
  final int worldSeed;
  final int visit;              // total dungeon entries so far
}
```

### Run boundary (town/run_boundary.dart)

```dart
GameState startRun(Profile profile);
// visit is bumped BY startRun (the entry reshuffles); carries equipment,
// skills, inventory, gold into the run; floor 1 generated fresh.

Profile endRun(GameState state, {required bool died});
// died=false (left via stairs): everything carried comes home; hp NOT healed.
// died=true: inventory=[], gold=0; equipment+skills kept; hp restored to
// derived max (the hero wakes in town); bank untouched either way.
```

Both are pure. Determinism: two `startRun` calls on equal Profiles produce
identical runs.

### Floor persistence (game_state.dart + step.dart)

```dart
class FloorMemory {   // value object: everything a floor keeps while you're away
  final FloorMap map;
  final List<Actor> monsters;
  final Map<Position, List<Item>> groundItems;
  final Set<Position> explored;
  final Position? stairsDown;
  final Position stairsUp;      // floors 2+; the arrival tile
}
// GameState gains: Map<int, FloorMemory> floors (inactive floors only),
// Position? stairsUp (active floor; null on floor 1), int gold.
```

- `DescendAction` (on stairs-down): snapshot the active floor into `floors`;
  if `floors[depth+1]` exists, restore it exactly; else generate floor
  `depth+1` fresh. Hero arrives on the target floor's stairs-up tile
  (generation contract below). Emits `Descended` as today.
- `AscendAction` (on stairs-up, depth ≥ 2): same swap upward, hero arrives on
  the target floor's stairs-DOWN tile. Emits `Ascended(newDepth)`. On floor 1
  or off the stairs-up tile: `ActionRefused, no turn consumed.
- Restored floors are exact: a monster wounded to 3 hp is still at 3 hp, a
  dropped item is where it fell, explored stays explored. Monster energy is
  restored as saved (frozen time).
- FOV recomputes on arrival; `explored` is per-floor (moves into the
  snapshot), not global.

### Generator (stairs-up)

`GeneratedFloor` gains `stairsUp: Position?` — null on depth 1, else placed
where `heroSpawn` is today (the arrival tile becomes a real '<' tile, drawn
and walkable). Guarantees extended: stairs-up and stairs-down are distinct
tiles, both reachable (flood-fill), on every floor 2–4; floor 5 has stairs-up
only; floor 1 has stairs-down only.

### Pierce

- `Creature` gains `pierce` (default 0). Damage pipeline in `_defend`:
  `reduced = roll - max(0, heroArmor(loadout) - attacker.pierce), floor 1
  unchanged. Dodge unaffected.
- Content: shallow creatures 0; depth-3+ creatures get meaningful pierce
  (worker drafts numbers; the survivability band is the binding constraint,
  same levers policy as M2L — bestiary hp/attack still untouched, pierce and
  tables are the new sanctioned levers).

### Town transactions (town/town.dart) — all pure Profile -> Profile

```dart
Profile buyItem(Profile p, Item item, int price);      // refuses (returns p + reason) when gold < price or inventory full
Profile sellItem(Profile p, String itemId, int price); // item leaves inventory, gold += price
Profile restAtInn(Profile p, int price);               // hp -> derived max; refuses when gold < price or already full
Profile depositItem(Profile p, String itemId);         // inventory -> bank (bank has NO cap)
Profile withdrawItem(Profile p, String itemId);        // bank -> inventory (inventory cap 20 applies)
Profile depositGold(Profile p, int amount);            // carried -> banked; also withdrawGold
```

Refusals: return a `(Profile, TownRefusal?)` shape or sealed result —
worker's plan picks one idiom and uses it consistently; a refused transaction
changes nothing.

### Economy (content/economy.dart)

```dart
int sellPriceOf(Item item);   // derived from base + rarity (+ affix count)
int buyPriceOf(Item item);    // > sellPriceOf — no arbitrage loops, pinned by test
int innPrice;                 // flat, cheap early game
List<Item> merchantStock(int worldSeed, int visit);
// deterministic per (worldSeed, visit): a few potions always, 2-4 gear items
// rolled through the existing rollDrop machinery, restocked per visit
```

Numbers are the worker's to draft and report; the binding constraints are:
no arbitrage (buy > sell for every item, tested), and the survivability sim
still runs WITHOUT town help (the bot never shops — the band measures the
dungeon).

### Rename

`EquipRefused` → `ActionRefused` everywhere (event, emissions, messages,
tests). Keep the payload shape.

### App

- Flow: app starts on the town screen (new Profile or, later, a loaded one —
  saves are still out of scope). Enter Dungeon → `startRun` → the existing
  game screen. On stairs: Descend/Ascend/Return-to-town controls appear by
  tile. Return-to-town and death both land back on the town screen via
  `endRun` (death shows the existing overlay first; its button becomes
  "Return to town").
- Town screen: gold (carried and banked, labeled), buttons Merchant / Bank /
  Inn / Enter Dungeon. Merchant: two lists (stock with buy prices, inventory
  with sell prices). Bank: two lists (carried, banked) with gold
  deposit/withdraw. Inn: one rest button with price and current hp.
- Depth indicator gains context: "Depth 3/5" unchanged; stairs-up control
  labeled "Ascend", stairs-down "Descend", both alongside "Return to town".
- Accessibility rules as everywhere: no hue-only encoding; carried vs banked
  distinguished by label/position, not color.
- Bloc-level tests only, as established.

## Behaviour arguments that must land in documentation (dartdoc)

- run_boundary.dart: why town is not a GameAction (step stays dungeon-only;
  town transactions need no rng, no map, no turn — a Profile function is the
  whole truth) and why `startRun` owns the visit bump (entry = reshuffle, one
  place).
- FloorMemory: why monsters freeze rather than simulate while away (there is
  no fair simulation without the hero on the floor; frozen time is honest and
  deterministic).
- Pierce: why pierce subtracts from armor rather than adding to damage (keeps
  the floor-of-1 rule and the readable subtraction shape; a pierced hit reads
  as "your armor did less", not "the monster hit harder").

## Test plan

- **Characterization layer: the existing 384 tests**, green on the unmodified
  worktree first. Expected casualties: the `EquipRefused` rename (mechanical,
  name-only); `newGame` callers if the newProfile/startRun split changes the
  content API (keep a `newGame` shim if it is cheap, or list every touched
  call site); survivability fixture values where pierce retuning moves
  numbers. List all before modifying.
- **Unit tests (core, mock-free, fixed seeds):** Profile round-trips for
  every transaction incl. every refusal; endRun died/left matrix (the D14
  table: carried lost/kept, equipped kept, bank untouched, hp rules);
  startRun bumps visit and reshuffles (different floors from a prior run,
  same floors for equal Profiles); floor persistence round-trip (wound a
  monster, drop an item, descend, ascend: both exactly as left; explored
  per-floor); ascend refusals (floor 1, off-tile); stairs-up generation
  guarantees; pierce arithmetic incl. pierce > armor clamps at 0 armor and
  the floor of 1 still binds; no-arbitrage price pin; merchant stock
  determinism per (worldSeed, visit).
- **Survivability (content):** the existing band test stays and must pass
  50–95% WITH pierce in the bestiary; report the re-tuning trail. The bot
  never uses town, never ascends.
- **Content validation:** pierce present and ≥0 on every creature; economy
  prices positive; merchant stock ids resolve.
- **App (bloc_test):** enter-dungeon flow; leave-at-stairs returns to town
  with the haul; death returns to town stripped per the matrix; buy/sell/
  rest/deposit reflect in state; ascend/descend controls appear per tile.

### Mutation table

| # | Mutation (revert after checking) | Expected to fail | Expected to stay green (control) |
|---|---|---|---|
| 1 | pierce ignored in `_defend` | pierce arithmetic tests + retuned survivability | armor-only damage tests |
| 2 | endRun(died: true) keeps inventory and gold | death-penalty matrix tests | leave-alive matrix tests |
| 3 | startRun stops bumping visit | reshuffle-on-entry tests | floor-persistence round-trip tests |
| 4 | AscendAction regenerates instead of restoring the snapshot | persistence round-trip tests | descend-to-NEW-floor generation tests |
| 5 | sellPriceOf returns buyPriceOf (arbitrage) | no-arbitrage pin | bank round-trip tests |
| 6 | depositItem drops the item instead of banking it | bank round-trip tests | merchant tests |

Sequencing: run against the finished unit, one row at a time, reverting each.

## Hazards

- Sandbox remains DISABLED on this machine (user trial) — do not change any
  sandbox or user configuration.
- Subagents dispatched into a git worktree do not inherit cwd — force
  `cd <worktree> && pwd` first, or work inline as the previous units did.
- No fvm: plain `flutter` / `dart` (system Flutter 3.47.0).
- Never commit anything under `docs/epic/`; cite its files by absolute path.
- Commits:.
- AVD `Pixel_10`; launch via the `emulator` binary directly; first gradle
  build downloads for minutes.
- `find` in the Bash tool may be bfs — `-newermt` takes ISO 8601 only;
  GNU find at `/usr/bin/find`.

## Follow-ups to log (not this story)

1. Saves (JSON snapshot of Profile + mid-run state) — game spec section 11,
   scheduled M3 ("saves hardened").
2. QOL backlog (follow-up 12) — collect from the user after this unit.
3. Safe points (follow-up 8), quests/rumors/overworld (M3), sets/perks (M4).

## Definition of done (checkable)

- [ ] All three suites green; pre-existing modifications listed with reasons;
      baseline 384 confirmed green before the first change
- [ ] `flutter analyze` clean ×3; `dart format --set-exit-if-changed .` clean
- [ ] Survivability band 50–95% WITH pierce; re-tuning trail reported
- [ ] Mutation table executed in full, greens included, reverted
- [ ] AVD playthrough on `Pixel_10, the full loop: start in town, enter,
      descend ≥2 floors, ascend one and find it exactly as left, return to
      town at a stairs, sell something, bank something, rest, re-enter a
      RESHUFFLED dungeon, die on purpose, confirm carried items+gold gone and
      equipped+skills+bank kept
- [ ] Conventional commits, each green, fiatcode author; no body comments;
      dartdoc carries the three documented behaviour arguments
