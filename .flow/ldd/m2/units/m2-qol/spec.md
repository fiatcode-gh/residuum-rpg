# Story spec — M2Q "Quality of life" (unit `m2-qol`)

Decided in ledger D19. Recon: `m2-qol-recon.md` (same directory). Base:
`main` @ `8596adb, 514 tests (352 core + 95 content + 67 app), measured
fresh 2026-08-21.

## Goal

The crawl becomes comfortable to play on a phone without any rule changing:
tap targets grow from ~12dp to ~36dp via a camera-follow viewport, the pack
explains items instead of only naming them (stats, grouping, stacks,
worn-comparison), the game says when and why free walking is locked, gear
bought in town can be worn in town, and the potion button shows a count.
Measurable effect: all five D19 items visible in play; zero balance movement —
the survivability run returns exactly 25/40.

## Shape — precedents to follow, read from this repo

- **Camera**: `GridGeometry.fit` (`packages/app/lib/game/grid_geometry.dart`)
  — a pure value computed from sizes, unit-tested in
  `packages/app/test/grid_geometry_test.dart`. The camera is a second factory
  on the same value: only the origin computation changes; `topLeftOf` and
  `positionAt` already work origin-relative.
- **Town transactions**: `Transacted = (Profile, TownRefusal?)` pure
  functions in `packages/core/lib/src/town/town.dart, wrapped one-per-event
  in `TownBloc`. New equip/unequip transactions copy this shape exactly.
- **Equip rules**: validation `step.dart:181-202` and `_equip`
  (`step.dart:310`). These move to a shared module; `step` keeps emitting its
  events in the same order.
- **View derivations**: `GameViewState` getters (`game_bloc.dart:67-129`) —
  new derived values (`enemiesInSight, `potionCount`) join them.
- **Greyscale encoding**: `InventoryScreen`'s dartdoc and rarity marking
  column — every new indicator is a word, shape, or number, never hue alone.

## New files

- `packages/core/lib/src/loot/wear.dart` — the shared equip rule.
- `packages/app/lib/game/item_presentation.dart` — stat lines, grouping,
  stacking, worn-deltas (pure functions + small value objects).
- `packages/app/lib/town/gear_screen.dart` — the town gear screen.
- Tests mirroring each (`packages/core/test/loot/wear_test.dart, `packages/core/test/town/` additions, app test files).

## Changed files

- `packages/core/lib/src/engine/step.dart` — delegate equip validation and
  mutation to `wear.dart`; behavior and event order byte-identical.
- `packages/core/lib/src/town/town.dart` — `equipItem, `unequipItem`.
- `packages/core/lib/core.dart` (exports as needed).
- `packages/app/lib/game/grid_geometry.dart` — camera factory + fixed cell
  constant.
- `packages/app/lib/game/glyph_grid.dart` — use camera geometry; pan gesture.
- `packages/app/lib/game/game_bloc.dart` — camera pan in `GameViewState, `MapPanned` event, refusal log line, `enemiesInSight, `potionCount`.
- `packages/app/lib/game/game_screen.dart` — Engaged chip, potion count.
- `packages/app/lib/game/inventory_screen.dart` — stats, groups, stacks,
  deltas.
- `packages/app/lib/town/town_bloc.dart, `town_screen.dart` — gear screen
  entry + wear/take-off events.

## Per-item contract

### 1. Camera-follow viewport (D19 fork: fixed zoom, free pan, snap-back)

- One constant, one home: the camera cell size, ~36 logical dp. The worker
  may tune it on device and must report the shipped value.
- `GridGeometry.camera(...)` takes the viewport size, map columns/rows, the
  focus position (the hero), and a pan offset. Per axis, independently:
  - If the map's extent at the fixed cell size fits the viewport, that axis
    is centered and ignores pan (exactly `fit`'s centering).
  - Otherwise the origin places the focus cell's center at the viewport
    center, shifted by pan, then clamped so the viewport never shows past
    the map's edge.
- The fixed cell size is used regardless of map or viewport size — the
  factory must never fall back to `fit`'s shrinking.
- Pan lives in `GameViewState` (new field, default `Offset.zero`); a
  `MapPanned(delta)` bloc event accumulates it. Every other event handler
  already constructs a fresh `GameViewState` without carrying it — which IS
  the snap-back-on-next-hero-action rule, by construction. Do not add a pan
  carry-over to any handler.
- Tap semantics unchanged: adjacent tap steps/attacks, far tap auto-paths,
  tap during a walk stops it. `positionAt` must invert the camera correctly.
- What it must NOT do: no pinch zoom, no recenter button, no camera state in
  core, no change to what is painted (fog, glyphs, colors untouched).

### 2. Inventory presentation

- `statLine(Item)` → compact stat string from the existing getters: attack
  range, armor, max hp, speed, heal — nonzero parts only, short labels, ` · ` separated (e.g. `+1-3 atk · +2 arm`).
- Stacking: two items stack when base, rarity, and affix list are all equal
  (ids differ by design — stacking is display-level). A stack row shows
  `<displayName> ×N` (×N only when N > 1) and its actions apply to one item
  of the stack.
- Grouping: carried items render in three fixed sections — Weapons, Armour,
  Potions — each sorted by slot order, then rarity (best first), then name.
- Worn-comparison: an equippable carried row shows signed per-stat deltas
  against the item currently worn in its slot (empty slot compares against
  zeros). Rendering: arrow shape plus signed number per changed stat
  (`▲+2 arm, `▼-1 atk`); when nothing changes, a plain "same as worn". No
  hue-only encoding.
- Worn slot rows also show their `statLine`.
- What it must NOT do: no changes to `Item`/`BaseItem`/`Affix` in core; no
  change to pick-up, drop, or cap rules; `displayName` untouched.

### 3. Battle indicator + refusal feedback

- `GameViewState.enemiesInSight`: count of monsters whose position is in
  `game.visible`. `_somethingIsWatching` must be re-expressed through the
  same single predicate home so the two can never disagree.
- The HP row shows the word `Engaged` plus the count when the count is
  positive, and nothing otherwise. Word + number, no hue-only encoding.
- A tap refused because something is watching appends one short log line
  (wording the worker's, one sentence, plain) and starts no walk. This
  replaces today's silent return at `game_bloc.dart:171`.

### 4. Town equip

- Extract the dungeon equip rule into `wear.dart` as pure functions usable
  by both `step` and town: a refusal check (not carrying / not wearable /
  shield-while-two-hander) and a mutation returning new equipment, new
  inventory, and the displaced items in order. `step` keeps its exact event
  sequence (ItemUnequipped per displaced item, then ItemEquipped) and its
  exact refusal wording.
- **Preserved behavior, do not fix:** equipping a two-hander while wearing
  weapon + shield displaces two items and may push the pack past
  `inventoryCap` (net +1, no cap check). Town equip mirrors this. Pin it
  with a test in both contexts and carry the argument in dartdoc: fixing it
  in one place would fork the rules; fixing it at all is a separate ruling.
- `equipItem(Profile, String itemId)` → `Transacted`: refusals mirror the
  wear refusal reasons in town's lowercase voice; success applies the wear
  mutation and then clamps `hero.hp` to the new loadout ceiling with a floor
  of one (mirror `_clampedToMaxHp, `step.dart:348`).
- `unequipItem(Profile, EquipSlot)` → `Transacted`: refused on an empty slot
  or a full pack; success moves the item to the pack and clamps hp the same
  way.
- App: a Gear screen reachable from town, listing worn slots (take off) and
  carried equippables (wear) using the same presentation helpers (stats,
  stacks, deltas). New `TownBloc` events wrap the two transactions like
  every existing one.
- What it must NOT do: no gold involved; no equipping directly from the
  merchant or the vault (buy → pack → wear; withdraw → pack → wear).

### 5. Potion count

- The crawl screen's quick-drink button reads `Drink potion (N)` from a new
  `GameViewState.potionCount`; the button still appears only when N > 0.

## Behaviour arguments that must land in documentation

- On the camera factory: why the cell size is fixed rather than fitted (the
  fitted map made depth-5 cells ~12dp against a 48dp touch guideline), and
  why pan is ignored on an axis that fits (a fitting axis has nothing to
  reveal; panning it would only uncover void).
- On the snap-back: the rule is "any new game state resets the camera", and
  it is enforced by construction because handlers build fresh view states —
  a future handler that copies the pan forward breaks it silently.
- On `wear.dart`: the asymmetric exclusion argument (moved from `_equip`'s
  dartdoc, kept verbatim or improved), and the preserved cap-overflow quirk
  with the reason it is preserved.
- On `enemiesInSight`: that it is the single home of "watched" for both the
  chip and the walk refusal, and why divergence would make the UI lie.

## Test plan

Characterization tests first — they must pass against the UNMODIFIED code:

- C1 (app bloc): tapping a far explored tile while a monster is visible
  changes nothing — no walk, no log entry. (This inverts later — see
  sequencing trap S1.)
- C2 (core): equipping a two-hander while wearing weapon + shield with a
  pack at `inventoryCap - 1` succeeds and leaves the pack over the cap.
  (Stays green forever — it pins the preserved quirk.)
- C3 (core): the full existing equip/unequip suites are the characterization
  of the extraction — they must not change in the same commit that moves the
  code.

Then unit tests (no mocks anywhere; pure state-in/state-out):

- Camera geometry: fixed cell size regardless of sizes; fitting axis
  centered and pan-deaf; overflowing axis centers the focus; clamping at
  all four map edges; pan shifts then clamps; `positionAt` inverts
  `topLeftOf` under an arbitrary camera.
- Bloc: `MapPanned` accumulates; any action event resets pan to zero;
  refusal log line + no walk; `enemiesInSight` counts only visible monsters;
  `potionCount`.
- Presentation: statLine composition (nonzero-only), stack key (base +
  rarity + affixes, never id), section order and sort, delta signs (better,
  worse, mixed, equal, empty slot).
- Core: wear refusals and mutation (displacement order, exclusion asymmetry);
  `equipItem`/`unequipItem` transactions (success, each refusal, hp clamp on
  both paths, floor of one); step's event order unchanged.
- Town bloc: wear/take-off events → states, refusal notices.

### Mutation table

Run every row; report both halves (reds AND greens) naming the tests.

| # | Mutation (one line, revert after) | Must go red | Must stay green (control) |
|---|---|---|---|
| 1 | Camera factory: derive cellSize with `fit`'s `min()` instead of the constant | camera fixed-size + clamp tests | `fit` tests; all core suites |
| 2 | Camera factory: remove the edge clamp | clamp tests | fitting-axis centering test |
| 3 | Stack key: include `item.id` | stacking tests | statLine tests; core loot tests |
| 4 | Delta: emit absolute values (drop the sign) | delta sign tests | stacking tests |
| 5 | `enemiesInSight`: drop the `visible` filter | engaged-count test AND walk-refusal tests (shared predicate — name both) | core FOV tests |
| 6 | `_onTileTapped`: remove the refusal log append | refusal-log test | walk-interrupt (ActorNoticed) tests |
| 7 | `equipItem` (town): skip the refusal check before mutating | town exclusion/not-carrying tests | step equip refusal tests (mutation is town-side only) |
| 8 | `unequipItem` (town): drop the full-pack refusal | town unequip cap test | `withdrawItem` cap test |
| 9 | `equipItem`/`unequipItem`: drop the hp clamp | town clamp tests | `restAtInn` tests |
| 10 | CONTROL — no mutation: run the content suite | — | survivability exactly 25/40; whole suite green |

### Sequencing traps

- S1: C1 asserts today's silence and is DELETED (not weakened) in the same
  commit that adds the refusal log line, replaced by the new assertion. Run
  and record C1's pass against unmodified code first.
- Row 5's red half depends on the predicate actually being shared; if the
  worker ships two expressions, the row cannot catch the second one — which
  is exactly why the contract forbids two expressions.
- Rows 1–4 target new code and can only run after it exists; row 10 runs
  last, on the finished branch.

## Hazards

- Event order in `step` is observable (message log); the extraction must not
  reorder or rename events. The app's `event_messages` and any test pinning
  log order are your canary.
- `GameViewState` gains fields — check every constructor site; a handler
  that forgets a field silently resets it (that is correct for pan, wrong
  for anything else).
- Pan and tap share a `GestureDetector`; verify on device that a pan does
  not fire a tap (and a tap still cancels a walk).
- The town Gear screen must read in greyscale (standing rule).
- Environment traps are restated in the build prompt; read them there.

## Follow-ups to log

- Stacking for the merchant stock and bank lists (scoped out here).
- The cap-overflow-on-displacement quirk: a candidate for an architect
  ruling later; this unit only pins it.

## Definition of done

- All three suites green; baseline was 352/95/67 (fresh, 2026-08-21, `8596adb`); report new per-package counts.
- `flutter analyze` clean; `dart format --set-exit-if-changed .` clean.
- Mutation table fully run and reported, greens included.
- Survivability run reported: exactly 25/40, stalled 0.
- Forbidden levers untouched: `git diff main -- packages/content` shows no
  bestiary, spawn/drop-table, price, or xp changes (content may be entirely
  untouched by this unit).
- AVD `Pixel_10` playthrough covering: pan away + snap-back on action; a
  surrounded fight won by tapping adjacent enemies at the new cell size;
  Engaged chip appearing/vanishing; a refused walk showing the log line;
  stacked potion row with count; a wear decision made from the delta
  markers; buy in town → wear in town → enter the dungeon wearing it;
  take-off in town refused with a full pack; potion count on the button.
- Greyscale screenshot check of the changed screens (deuteranomaly rule).
- `BUILD-REPORT.md` in the worktree mirrors the verification block.
