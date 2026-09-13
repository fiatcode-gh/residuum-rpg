# M2Q Quality of Life Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the crawl comfortable on a phone — bigger tap targets, a pack that
explains itself, feedback when a walk is refused, gear you can wear in town, and a
potion count — without changing a single game rule.

**Architecture:** Four of the five items are pure app-layer presentation and need no
core change at all. The fifth (town equip) extracts the dungeon's existing wear rule
into one shared pure module that both `step` and the town transactions call, so the two
contexts cannot drift. The camera is a second origin computation on the existing
`GridGeometry` value; the pan lives in `GameViewState, which makes snap-back a
consequence of the bloc's existing habit of building fresh view states.

**Tech Stack:** Dart 3 / Flutter 3.47.0 (no fvm), `flutter_bloc,`equatable` (core
only), `test` / `flutter_test` / `bloc_test`.

**Spec:** `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m2-qol-spec-M2Q.md`
(recon: `m2-qol-recon.md, same directory; game design spec:
`docs/superpowers/specs/2026-08-20-dungeon-game-design.md`; conventions:`CLAUDE.md`)

## Global Constraints

- Dependency rule `app -> content -> core`. `core` and `content` never import Flutter.
- Game state is immutable; the only mutation is
  `(GameState, List<GameEvent>) step(GameState, GameAction)`.
- No global randomness. An unseeded `Random()` in `core` or `content` is a bug.
- No body comments anywhere. Dartdoc `///` only, and only on public API of `core` and
  `content`.
- Ubiquitous language: the spec's words exactly — `temper,`affix, `beat,`rumor, `residue,`wear, `take off`.
- Accessibility is non-negotiable: state, rarity and category encode by shape, marking,
  position, or a word. Never hue alone. Every screen reads in greyscale.
- Tests: strict red -> green -> refactor. Bodies structured `// arrange` / `// act` /
  `// assert`. No mocks in core. App tests are BLoC-level or pure unit tests only — no
  widget or page tests.
- Every commit's exit state is green across all three packages. Conventional commits.
- Forbidden balance levers (architect ruling required): bestiary hp/attack/speed/pierce,
  hero base stats, drop/spawn tables, prices, the xp curve. `packages/content` must be
  entirely untouched — `git diff main -- packages/content` stays empty.
- Forbidden features: no pinch zoom, no recenter button, no change to fog/glyph
  rendering rules, no new dependency in core.
- Baseline: 352 core + 95 content + 67 app = 514 green at `8596adb`; survivability
  25/40 won, stalled 0. Re-measured fresh this session and confirmed.
- Never commit anything under `docs/epic/` (gitignored ledger).

## File Structure

**Create**

- `packages/core/lib/src/loot/wear.dart` — the one home of the wear rule: refusal
  reasons, the equip mutation with its displacement order, the take-off mutation, and
  the hit point clamp. Pure; no events, no `GameState`.
- `packages/core/test/loot/wear_test.dart` — the rule in isolation.
- `packages/app/lib/game/item_presentation.dart` — stat lines, stack keys, pack
  sections, worn deltas. Pure functions and small value objects; no widgets.
- `packages/app/lib/town/gear_screen.dart` — the town gear room.
- `packages/app/test/item_presentation_test.dart` — pure unit tests, following the
  `grid_geometry_test.dart` precedent.

**Modify**

- `packages/core/lib/src/engine/step.dart` — delegate equip/unequip validation and
  mutation to `wear.dart`. Event order and refusal wording byte-identical.
- `packages/core/lib/src/town/town.dart` — `equipItem,`unequipItem`.
- `packages/core/lib/core.dart` — export `wear.dart`.
- `packages/app/lib/game/grid_geometry.dart` — `cameraCellSize` constant plus
  `GridGeometry.camera`.
- `packages/app/lib/game/glyph_grid.dart` — use the camera; add the pan gesture.
- `packages/app/lib/game/game_bloc.dart` — `pan` field, `MapPanned` event, `enemiesInSight,`potionCount, the refusal log line; delete
  `_somethingIsWatching`.
- `packages/app/lib/game/game_screen.dart` — Engaged indicator, potion count.
- `packages/app/lib/game/inventory_screen.dart` — stats, sections, stacks, deltas.
- `packages/app/lib/town/town_bloc.dart` — `WearPressed,`TakeOffPressed`.
- `packages/app/lib/town/town_screen.dart` — the Gear door.
- `packages/app/test/grid_geometry_test.dart,`packages/app/test/game_bloc_test.dart, `packages/app/test/town_bloc_test.dart,`packages/core/test/town/town_test.dart` —
  new behavior.

**Already committed (`9ae8b2e`)**

- `packages/core/test/engine/step_wear_characterization_test.dart` — C2 plus the hit
  point asymmetry.
- The `GameBloc under a watching eye` group in `packages/app/test/game_bloc_test.dart` —
  C1, to be deleted in Task 6 per sequencing trap S1.

---

### Task 1: Camera geometry

**Files:**

- Modify: `packages/app/lib/game/grid_geometry.dart`
- Test: `packages/app/test/grid_geometry_test.dart`

**Interfaces:**

- Consumes: nothing.
- Produces: `const double cameraCellSize` (36.0);
  `GridGeometry.camera(Size size, int columns, int rows, Position focus, Offset pan)`.
  `topLeftOf,`positionAt, `cellSize,`origin` unchanged in meaning.

The origin per axis, independently. For x, with `extent = cameraCellSize * columns`:
if `extent <= size.width` the axis is centred at `(size.width - extent) / 2` and the pan
is ignored; otherwise it is
`(size.width / 2 - (focus.x + 0.5) * cameraCellSize + pan.dx)` clamped into
`[size.width - extent, 0]`. Same for y with `rows,`size.height, `focus.y,`pan.dy`.

- [ ] **Step 1: Write the failing tests**

```dart
group('GridGeometry.camera', () {
  test('uses the fixed cell size however small the viewport', () {
    // arrange
    const size = Size(200, 400);

    // act
    final geometry = GridGeometry.camera(size, 40, 40, const Position(20, 20));

    // assert
    expect(geometry.cellSize, cameraCellSize);
  });

  test('centres an axis whose whole extent fits', () {
    // arrange
    const size = Size(400, 400);

    // act
    final geometry = GridGeometry.camera(size, 5, 5, const Position(0, 0));

    // assert
    expect(geometry.origin, const Offset(110, 110));
  });

  test('ignores pan on an axis whose whole extent fits', () {
    // arrange
    const size = Size(400, 400);

    // act
    final panned = GridGeometry.camera(
      size,
      5,
      5,
      const Position(0, 0),
      const Offset(90, 90),
    );

    // assert
    expect(panned.origin, const Offset(110, 110));
  });

  test('treats an extent exactly filling the viewport as fitting', () {
    // arrange
    const size = Size(cameraCellSize * 5, cameraCellSize * 5);

    // act
    final geometry = GridGeometry.camera(
      size,
      5,
      5,
      const Position(4, 4),
      const Offset(50, 50),
    );

    // assert
    expect(geometry.origin, Offset.zero);
  });

  test('centres the focus cell on an overflowing axis', () {
    // arrange
    const size = Size(360, 360);

    // act
    final geometry = GridGeometry.camera(size, 40, 40, const Position(20, 20));

    // assert
    expect(geometry.topLeftOf(20, 20), const Offset(162, 162));
  });

  test('clamps at the near edges rather than showing void', () {
    // arrange
    const size = Size(360, 360);

    // act
    final geometry = GridGeometry.camera(size, 40, 40, const Position(0, 0));

    // assert
    expect(geometry.origin, Offset.zero);
  });

  test('clamps at the far edges rather than showing void', () {
    // arrange
    const size = Size(360, 360);
    const extent = cameraCellSize * 40;

    // act
    final geometry = GridGeometry.camera(size, 40, 40, const Position(39, 39));

    // assert
    expect(geometry.origin, const Offset(360 - extent, 360 - extent));
  });

  test('shifts by the pan before clamping', () {
    // arrange
    const size = Size(360, 360);
    final unpanned = GridGeometry.camera(size, 40, 40, const Position(20, 20));

    // act
    final panned = GridGeometry.camera(
      size,
      40,
      40,
      const Position(20, 20),
      const Offset(30, -30),
    );

    // assert
    expect(panned.origin, unpanned.origin + const Offset(30, -30));
  });

  test('a pan past the edge clamps instead of running off', () {
    // arrange
    const size = Size(360, 360);

    // act
    final geometry = GridGeometry.camera(
      size,
      40,
      40,
      const Position(20, 20),
      const Offset(9999, 9999),
    );

    // assert
    expect(geometry.origin, Offset.zero);
  });

  test('positionAt inverts topLeftOf under an arbitrary camera', () {
    // arrange
    final geometry = GridGeometry.camera(
      const Size(357, 411),
      40,
      40,
      const Position(17, 23),
      const Offset(13, -29),
    );

    // act
    final corner = geometry.topLeftOf(19, 21);
    final position = geometry.positionAt(corner + const Offset(1, 1));

    // assert
    expect(position, const Position(19, 21));
  });
});
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd packages/app && flutter test test/grid_geometry_test.dart`
Expected: FAIL — `camera` and `cameraCellSize` are not defined.

- [ ] **Step 3: Write the implementation**

```dart
/// The cell size the camera always draws at, in logical pixels.
///
/// Fixed rather than fitted because fitting the whole floor on screen made the
/// cells shrink with depth: a depth-five floor is 32 by 20 tiles, which on a
/// phone left ~12dp cells against a 48dp touch guideline, and a tap that has to
/// be aimed is not a tap. A fixed cell means the deepest floor is as playable as
/// the first one, and what a bigger floor costs is visibility rather than
/// accuracy — which is what panning is for.
const double cameraCellSize = 36;

/// The grid as a camera would frame it: fixed cell size, focus centred, panned,
/// then held inside the map's edges.
///
/// Each axis decides for itself, because a floor is wider than it is tall and a
/// phone is the other way round, so one axis routinely fits while the other does
/// not. **A fitting axis ignores [pan] entirely**: it has nothing hidden to
/// reveal, so panning it could only uncover void, and a viewport that can be
/// dragged off its own content teaches the player that the controls are broken.
///
/// An extent exactly equal to the viewport counts as fitting. Nothing is hidden
/// at equality either.
factory GridGeometry.camera(
  Size size,
  int columns,
  int rows,
  Position focus, [
  Offset pan = Offset.zero,
]) => GridGeometry(
  cellSize: cameraCellSize,
  origin: Offset(
    _axisOrigin(size.width, columns, focus.x, pan.dx),
    _axisOrigin(size.height, rows, focus.y, pan.dy),
  ),
  columns: columns,
  rows: rows,
);

static double _axisOrigin(double viewport, int cells, int focus, double pan) {
  final extent = cameraCellSize * cells;
  if (extent <= viewport) return (viewport - extent) / 2;
  final centred = viewport / 2 - (focus + 0.5) * cameraCellSize;
  return (centred + pan).clamp(viewport - extent, 0);
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd packages/app && flutter test test/grid_geometry_test.dart`
Expected: PASS, existing `fit` tests included.

- [ ] **Step 5: Commit**

```bash
git add packages/app/lib/game/grid_geometry.dart packages/app/test/grid_geometry_test.dart
git commit -m "feat: a camera origin at a fixed cell size"
```

---

### Task 2: Pan in the view state, and the camera on screen

**Files:**

- Modify: `packages/app/lib/game/game_bloc.dart,`packages/app/lib/game/glyph_grid.dart`
- Test: `packages/app/test/game_bloc_test.dart`

**Interfaces:**

- Consumes: `GridGeometry.camera,`cameraCellSize` from Task 1.
- Produces: `GameViewState.pan` (`Offset, defaults`Offset.zero`);
  `final class MapPanned extends GameBlocEvent { const MapPanned(this.delta); final Offset delta; }`.

`GameViewState` gains `this.pan = Offset.zero` as a named optional. No other handler
passes it — that omission *is* snap-back, and it is load-bearing.

- [ ] **Step 1: Write the failing tests**

```dart
group('GameBloc panning', () {
  blocTest<GameBloc, GameViewState>(
    'a pan accumulates across drags',
    build: () => walker(arenaGame(heroAt: const Position(3, 2))),
    act: (bloc) => bloc
      ..add(const MapPanned(Offset(10, 5)))
      ..add(const MapPanned(Offset(-4, 6))),
    verify: (bloc) => expect(bloc.state.pan, const Offset(6, 11)),
  );

  blocTest<GameBloc, GameViewState>(
    'a fresh crawl starts unpanned',
    build: () => walker(arenaGame(heroAt: const Position(3, 2))),
    act: (bloc) {},
    verify: (bloc) => expect(bloc.state.pan, Offset.zero),
  );

  blocTest<GameBloc, GameViewState>(
    'a hero action snaps the camera back',
    build: () => walker(arenaGame(heroAt: const Position(3, 2))),
    act: (bloc) => bloc
      ..add(const MapPanned(Offset(40, 40)))
      ..add(const TileTapped(Position(4, 2))),
    verify: (bloc) {
      expect(bloc.state.game.hero.position, const Position(4, 2));
      expect(bloc.state.pan, Offset.zero);
    },
  );

  blocTest<GameBloc, GameViewState>(
    'reaching into the pack snaps the camera back',
    build: () => walker(
      arenaGame(
        heroAt: const Position(3, 2),
        inventory: [_item('kit-1', _sword)],
      ),
    ),
    act: (bloc) => bloc
      ..add(const MapPanned(Offset(40, 40)))
      ..add(const EquipPressed('kit-1')),
    verify: (bloc) => expect(bloc.state.pan, Offset.zero),
  );

  blocTest<GameBloc, GameViewState>(
    'a pan does not cancel a walk in progress',
    build: () => walker(arenaGame(heroAt: const Position(1, 1))),
    act: (bloc) async {
      bloc.add(const TileTapped(Position(5, 3)));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const MapPanned(Offset(12, 12)));
    },
    wait: const Duration(milliseconds: 100),
    verify: (bloc) => expect(bloc.state.game.hero.position, const Position(5, 3)),
  );
});
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd packages/app && flutter test test/game_bloc_test.dart`
Expected: FAIL — `MapPanned` and `pan` are not defined.

- [ ] **Step 3: Write the implementation**

Add to `game_bloc.dart`: `import 'dart:ui' show Offset;, the`MapPanned` event class, `pan` on `GameViewState` with the dartdoc below, `on<MapPanned>(_onMapPanned)` in the
constructor, and the handler. The handler carries `autoPath` and `walkId` through, so a
pan is not a hero action and does not stop a walk.

```dart
/// How far the player has dragged the view from where the camera would put it.
///
/// The rule is that **any new game state resets the camera**, and it is enforced
/// by construction rather than by code: every other handler builds a fresh
/// [GameViewState] without naming this field, so it falls back to
/// [Offset.zero]. A future handler that helpfully copies the pan forward would
/// break snap-back silently, and no test of that handler would notice.
final Offset pan;
```

```dart
void _onMapPanned(MapPanned event, Emitter<GameViewState> emit) => emit(
  GameViewState(
    game: state.game,
    log: state.log,
    autoPath: state.autoPath,
    walkId: state.walkId,
    pan: state.pan + event.delta,
  ),
);
```

In `glyph_grid.dart, swap`GridGeometry.fit` for
`GridGeometry.camera(size, state.game.map.width, state.game.map.height, state.game.hero.position, state.pan)`
and add `onPanUpdate: (details) => onPan(details.delta)` beside the existing `onTapUp,
with a new `final ValueChanged<Offset> onPan;` constructor field. `GameScreen` wires it
to `context.read<GameBloc>().add(MapPanned(delta))`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd packages/app && flutter test`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add packages/app/lib/game packages/app/test/game_bloc_test.dart
git commit -m "feat: a camera that follows the hero and pans by hand"
```

---

### Task 3: The wear rule, extracted

**Files:**

- Create: `packages/core/lib/src/loot/wear.dart,`packages/core/test/loot/wear_test.dart`
- Modify: `packages/core/lib/src/engine/step.dart,`packages/core/lib/core.dart`

**Interfaces:**

- Consumes: `Equipment,`Item, `EquipSlot,`Loadout, `Actor,`inventoryCap`.
- Produces:

```dart
String? wearRefusal(Loadout loadout, List<Item> inventory, String itemId);
String? takeOffRefusal(Equipment equipment, List<Item> inventory, EquipSlot slot);
class Worn { const Worn(this.equipment, this.inventory, this.displaced);
  final Equipment equipment; final List<Item> inventory;
  final List<(Item, EquipSlot)> displaced; }
Worn wear(Equipment equipment, List<Item> inventory, String itemId);
Worn takeOff(Equipment equipment, List<Item> inventory, EquipSlot slot);
Actor clampedToMaxHp(Actor hero, Loadout loadout);
```

`displaced` is in the order `step` must emit `ItemUnequipped` for: the occupied target
slot first, then the off hand when a two-hander claims both.

Refusal strings, verbatim from `step`: `'you are not carrying that',`'${item.base.name} is not worn', `'both hands are on the weapon', `'nothing is on your ${slot.name}', `'your hands are too full to stow it'`.

- [ ] **Step 1: Write the failing tests**

`packages/core/test/loot/wear_test.dart` covers, each `// arrange` / `// act` /
`// assert`:

- `wearRefusal` returns null for a carried wearable; `'you are not carrying that'` for an
  id not in the pack; `'Healing Potion is not worn'` for a potion; `'both hands are on
  the weapon'` for a shield while a two-hander is held; and **null for a two-hander
  while a shield is held** (the asymmetry).
- `wear` puts the item in its slot and drops it from the pack.
- `wear` displaces an occupied slot into the pack, reporting it in `displaced`.
- `wear` of a two-hander over weapon plus shield reports `displaced` as main hand then
  off hand, in that order, and leaves the pack one longer than it started.
- `takeOffRefusal` returns null for an occupied slot; `'nothing is on your head'` for an
  empty one; `'your hands are too full to stow it'` at `inventoryCap`.
- `takeOff` moves the piece to the end of the pack.
- `clampedToMaxHp` lowers hit points to the ceiling, leaves them alone below it, and
  floors at one.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd packages/core && flutter test test/loot/wear_test.dart`
Expected: FAIL — `wear.dart` does not exist.

- [ ] **Step 3: Write `wear.dart`**

The dartdoc carries three arguments the spec requires in documentation: the asymmetric
exclusion (moved from `_equip, verbatim), the preserved cap-overflow quirk with why it
is preserved, and the equip/take-off clamp asymmetry recorded in Task 0's
characterization tests.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd packages/core && flutter test test/loot/wear_test.dart`
Expected: PASS.

- [ ] **Step 5: Delegate from `step, changing no existing test**

`_refuse`'s `EquipAction` and `UnequipAction` cases return
`ActionRefused(reason: ...)` around the shared refusal, and the `EquipAction` /
`UnequipAction` mutation cases call `wear` / `takeOff, emitting`ItemUnequipped` per
entry of `displaced` in order and then `ItemEquipped`. Delete`_equip, `_Worn` and
`_clampedToMaxHp`. Export `wear.dart` from `core.dart`.

C3 is this step's gate: the existing equip and unequip suites must pass **unchanged**.

- [ ] **Step 6: Run every core test**

Run: `cd packages/core && flutter test`
Expected: PASS, 352 plus the new `wear_test.dart` and characterization counts.

- [ ] **Step 7: Commit**

```bash
git add packages/core/lib packages/core/test/loot/wear_test.dart
git commit -m "refactor: one home for the wear rule"
```

---

### Task 4: Town wear and take off

**Files:**

- Modify: `packages/core/lib/src/town/town.dart`
- Test: `packages/core/test/town/town_test.dart`

**Interfaces:**

- Consumes: `wearRefusal,`takeOffRefusal, `wear,`takeOff, `clampedToMaxHp` from
  Task 3; `Transacted,`TownRefusal, `Profile`.
- Produces: `Transacted equipItem(Profile profile, String itemId),`Transacted unequipItem(Profile profile, EquipSlot slot)`.

- [ ] **Step 1: Write the failing tests**

Covering: wearing a carried weapon moves it out of the pack and into the slot; each
refusal reason, matched against the shared string so a divergence fails here; a
two-hander over weapon plus shield displacing both and pushing a full pack over the cap
(the mirrored quirk); taking off into a full pack refused; the hit point clamp on both
paths; the floor of one; and a refusal returning the profile unchanged and `==` to the
input.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd packages/core && flutter test test/town/town_test.dart`
Expected: FAIL — `equipItem` is not defined.

- [ ] **Step 3: Write the implementation**

```dart
Transacted equipItem(Profile profile, String itemId) {
  final refusal = wearRefusal(profile.loadout, profile.inventory, itemId);
  if (refusal != null) return (profile, TownRefusal(refusal));
  final worn = wear(profile.equipment, profile.inventory, itemId);
  return (_reloaded(profile, worn), null);
}
```

with `unequipItem` the same shape around `takeOffRefusal` / `takeOff, and a shared
private`_reloaded` applying equipment, inventory and `clampedToMaxHp` together so
neither path can forget the clamp.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd packages/core && flutter test`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add packages/core/lib/src/town/town.dart packages/core/test/town/town_test.dart
git commit -m "feat: wear and take off gear in town"
```

---

### Task 5: Item presentation

**Files:**

- Create: `packages/app/lib/game/item_presentation.dart,`packages/app/test/item_presentation_test.dart`

**Interfaces:**

- Consumes: `Item,`BaseItem, `Affix,`Rarity, `EquipSlot` from core.
- Produces:

```dart
String statLine(Item item);
String stackKey(Item item);
class ItemStack { const ItemStack(this.item, this.count);
  final Item item; final int count; String get label; }
enum PackSection { weapons, armour, potions; String get title; }
Map<PackSection, List<ItemStack>> packSections(List<Item> items);
class StatDelta { const StatDelta(this.label, this.amount);
  final String label; final int amount; String get text; }
List<StatDelta> wornDeltas(Item item, Item? worn);
String deltaLine(List<StatDelta> deltas);
```

`stackKey` joins `base.id,`rarity.name` and each affix id in order — never `item.id`.
`StatDelta.text` is `'▲+2 arm'` / `'▼-1 atk'`: a shape, a sign and a number,
no hue.`deltaLine` of an empty list is `'same as worn'`.

- [ ] **Step 1: Write the failing tests**

Covering: `statLine` keeps only nonzero parts and joins with `' · '`; collapses an
equal attack range to one number; a potion reads its heal; an item with nothing to say
returns the empty string. `stackKey` matches across differing ids and differs on base,
rarity, or affix list. `packSections` puts each base in its section, orders sections
weapons then armour then potions, sorts by slot then rarity best-first then name, and
stacks identical items with `count` while `label` shows `×N` only above one.
`wornDeltas` against a better, worse, mixed, and identical piece and against an empty
slot; splits into `atk min` / `atk max` when the two move differently. `deltaLine`
returns `'same as worn'` on empty.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd packages/app && flutter test test/item_presentation_test.dart`
Expected: FAIL — the module does not exist.

- [ ] **Step 3: Write the implementation**

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd packages/app && flutter test`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add packages/app/lib/game/item_presentation.dart packages/app/test/item_presentation_test.dart
git commit -m "feat: read an item's numbers, grouped and stacked"
```

---

### Task 6: Engaged, the refusal line, and the potion count

**Files:**

- Modify: `packages/app/lib/game/game_bloc.dart,`packages/app/lib/game/game_screen.dart`
- Test: `packages/app/test/game_bloc_test.dart`

**Interfaces:**

- Consumes: nothing new.
- Produces: `GameViewState.enemiesInSight` (int), `GameViewState.potionCount` (int).

Sequencing trap S1: the C1 test `'a refused walk says nothing at all'` is **deleted** in
this task's commit and replaced by `'a refused walk says why'`. It is not weakened.

- [ ] **Step 1: Write the failing tests, and delete C1**

```dart
blocTest<GameBloc, GameViewState>(
  'a refused walk says why and takes no step',
  build: () => walker(
    arenaGame(
      heroAt: const Position(1, 1),
      monsters: [ghoul(const Position(5, 3))],
    ),
  ),
  act: (bloc) => bloc.add(const TileTapped(Position(5, 1))),
  verify: (bloc) {
    expect(bloc.state.log, ['Something is watching. You walk no further.']);
    expect(bloc.state.isWalking, isFalse);
    expect(bloc.state.game.hero.position, const Position(1, 1));
  },
);
```

Plus: `enemiesInSight` counts only monsters inside `game.visible` (a monster in an
unlit room counts zero); it counts two when two are lit; a walk **does** start with a
monster out of sight (this is row 5's second red half); `potionCount` counts carried
potions only and reads zero with none.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd packages/app && flutter test test/game_bloc_test.dart`
Expected: FAIL — no log line is appended; `enemiesInSight` is not defined.

- [ ] **Step 3: Write the implementation**

```dart
/// How many monsters the hero can see right now.
///
/// The single home of "something is watching": the Engaged indicator and the
/// walk refusal both read this one getter. Two expressions of the same question
/// would eventually disagree, and then the interface would refuse a walk while
/// showing the player an empty room — the UI lying about the rules is worse than
/// either answer alone.
int get enemiesInSight =>
    game.monsters.where((monster) => game.visible.contains(monster.position)).length;

/// How many potions are in the pack, for the quick-drink control to count.
int get potionCount => game.inventory.where((item) => item.base.isPotion).length;
```

Replace `if (_somethingIsWatching(game)) return;` with a guard that appends the line and
emits, and delete `_somethingIsWatching`. In `game_screen.dart,`_HitPoints` gains
`Engaged N` when `state.enemiesInSight > 0` and the quick-drink label becomes
`'Drink potion (${state.potionCount})'`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd packages/app && flutter test`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add packages/app/lib/game packages/app/test/game_bloc_test.dart
git commit -m "feat: say when something is watching, and count the potions"
```

---

### Task 7: The pack screen reads its items

**Files:**

- Modify: `packages/app/lib/game/inventory_screen.dart`

**Interfaces:**

- Consumes: everything from Task 5.
- Produces: nothing other tasks read.

Presentation only, and app convention forbids widget tests, so this task's gate is
`flutter analyze` plus the AVD playthrough. Worn slot rows gain their `statLine`;
carried rows render in `packSections` order with `ItemStack.label,`statLine, and
`deltaLine(wornDeltas(item, state.game.equipment[slot]))` on equippables. Actions apply
to `stack.item.id, one item of the stack.

- [ ] **Step 1: Write the implementation**

- [ ] **Step 2: Verify the suites and the analyzer**

Run: `cd packages/app && flutter test && flutter analyze`
Expected: PASS, no issues.

- [ ] **Step 3: Commit**

```bash
git add packages/app/lib/game/inventory_screen.dart
git commit -m "feat: a pack that explains what it is carrying"
```

---

### Task 8: The town gear room

**Files:**

- Create: `packages/app/lib/town/gear_screen.dart`
- Modify: `packages/app/lib/town/town_bloc.dart,`packages/app/lib/town/town_screen.dart`
- Test: `packages/app/test/town_bloc_test.dart`

**Interfaces:**

- Consumes: `equipItem,`unequipItem` (Task 4); `packSections, `statLine,`wornDeltas, `deltaLine` (Task 5); `TownRoom,`Heading, `NothingHere,`Notice`
  from `town_style.dart`.
- Produces: `WearPressed(String itemId),`TakeOffPressed(EquipSlot slot)`.

- [ ] **Step 1: Write the failing tests**

`WearPressed` moves a carried piece into its slot; `TakeOffPressed` moves a worn piece
back to the pack; each refusal surfaces as `notice` with the shared wording and leaves
the profile unchanged; a successful transaction clears a previous notice.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd packages/app && flutter test test/town_bloc_test.dart`
Expected: FAIL — `WearPressed` is not defined.

- [ ] **Step 3: Write the implementation**

Two handlers in the one-per-event shape every existing town event uses
(`emit(_transacted(equipItem(state.profile, event.itemId)))`), a `Gear` door on
`TownScreen` beside Merchant, Bank and Inn, and `GearScreen` listing worn slots with a
`Take off` action above carried equippables with a `Wear` action. Its dartdoc records
that the screen reads in greyscale: slot labels are words in a fixed order, an empty
slot is a dash, and every delta is an arrow shape plus a signed number.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd packages/app && flutter test && flutter analyze`
Expected: PASS, no issues.

- [ ] **Step 5: Commit**

```bash
git add packages/app/lib/town packages/app/test/town_bloc_test.dart
git commit -m "feat: a gear room in town"
```

---

### Task 9: Mutation table, formatting, and the report

**Files:**

- Create: `BUILD-REPORT.md`

- [ ] **Step 1: Run `dart format` across all three packages**

Run: `dart format --set-exit-if-changed .` from the worktree root; commit any
reformatting.

- [ ] **Step 2: Run all ten mutation rows**

One mutation at a time, reverted immediately after. Record both halves — which tests
reddened and which stayed green — by name. Row 10 is the control: no mutation, full
content suite, survivability exactly 25/40 with stalled 0.

- [ ] **Step 3: Verify the forbidden levers are untouched**

Run: `git diff main --stat -- packages/content`
Expected: empty output.

- [ ] **Step 4: Hygiene greps**

No body comments and no unseeded `Random()` in the diff. Quote the commands and their
empty output.

- [ ] **Step 5: AVD playthrough**

`Pixel_10, covering every scene in the spec's definition of done, with screenshots and
a greyscale check of each changed screen.

- [ ] **Step 6: Write and commit `BUILD-REPORT.md`**

```bash
git add BUILD-REPORT.md
git commit -m "docs: M2Q build report"
```
