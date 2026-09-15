# Task 01 — Shared filtered Pack and crawl cutover

Owner: first fresh sequential executor in the current non-isolated
`residuum-visual-reboot-6` checkout. Read `../PLAN.md`, `../CONTRACT.md`, and
`../recon.md` before editing. This brief carries implementation instructions;
the LDD artifacts themselves remain architect-owned.

## Expected starting repository condition

HEAD/source base is `55a226d`. `packages/app` is unchanged from that revision.
`packages/app/lib/game/inventory_screen.dart` still defines the long
`InventoryScreen`; `game_screen.dart` still pushes it; the town
`CharacterScreen` is still the old long page. Unit 6 contract/recon/plan files
and the epic ledger/resume may be uncommitted architect-owned changes.

Before editing, inspect branch and status. If any planned `packages/app` file has
changes not described by this starting condition, treat them as user-owned: do
not reset, stash, overwrite, or discard them. Stop and report the contradiction.
Do not edit any `.flow` file, `packages/core`, `packages/content`, save/autosaver
code, dependency file, or generated output.

## Behavioral slice and scope

This task leaves town Character behavior intact except for its import of moved
`slotLabel`. It ends with a complete filtered crawl Pack and the final shared
Pack interface task 02 will consume.

Touch only:

- add `packages/app/lib/game/pack_screen.dart`;
- remove `packages/app/lib/game/inventory_screen.dart`;
- update `packages/app/lib/game/game_screen.dart`;
- update `packages/app/lib/game/item_presentation.dart` only to move
  `slotLabel` from the removed file;
- update `packages/app/lib/game/spell_row.dart` documentation that still calls
  Pack a casting surface; do not change row behavior in this task;
- update `packages/app/lib/town/character_screen.dart` only to import
  `slotLabel` from `item_presentation.dart`; do not redesign town here;
- add `packages/app/test/widget/pack_screen_test.dart`;
- update `packages/app/test/battle_characterization_test.dart`;
- update `packages/app/test/widget/craft_surfaces_test.dart`;
- delete `packages/app/test/widget/magic_surfaces_test.dart` after migrating its
  still-valid book/refusal contracts;
- delete `packages/app/test/widget/skills_row_spacing_test.dart`.

Do not edit `game_bloc.dart`, any town bloc/event/handler, `town_screen.dart`,
`battle_view_test.dart`, or `item_presentation_test.dart`. Those existing tests
are focused evidence to run, not files to reshape.

## Locked implementation

### Clean rename/cutover

`InventoryScreen` and `inventory_screen.dart` are retired, not wrapped.
`game_screen.dart` imports `pack_screen.dart` and the existing Pack control at
`game_screen.dart:455-466` pushes:

```dart
BlocProvider.value(value: bloc, child: const CrawlPackScreen())
```

Keep the `MaterialPageRoute<void>`, live `GameBloc` identity, `Pack (N)` label,
and surrounding controls unchanged. Do not leave an alias, re-export,
deprecated constructor, or second route.

Move the existing public `slotLabel(EquipSlot)` function verbatim to
`item_presentation.dart`. Keep all six labels and enum mapping unchanged. The
still-old town Character imports it from that file so this task hands off a
green repository.

Update `SpellRow` dartdoc to describe an optional trailing action generically
and name the Unit 3 shelf overflow—not Pack—as the current actionful consumer.
Do not change its constructor, layout, `effectOf`, or action behavior.

### Public shared Pack interface

`game/pack_screen.dart` exports exactly:

```dart
class CrawlPackScreen extends StatelessWidget {
  const CrawlPackScreen({super.key});
}

class PackContents extends StatefulWidget {
  const PackContents({
    required this.inventory,
    required this.equipment,
    required this.materials,
    required this.readRefusalFor,
    this.wearRefusalFor,
    this.onDrink,
    this.onRead,
    this.onWear,
    this.onDrop,
    this.showBookTeaching = false,
    super.key,
  });

  final List<Item> inventory;
  final Equipment equipment;
  final Map<MaterialId, int> materials;
  final String? Function(String itemId) readRefusalFor;
  final String? Function(String itemId)? wearRefusalFor;
  final ValueChanged<String>? onDrink;
  final ValueChanged<String>? onRead;
  final ValueChanged<String>? onWear;
  final ValueChanged<String>? onDrop;
  final bool showBookTeaching;
}
```

Do not add an action enum/model, controller, bloc adapter, generic management
shell, inherited widget, or route registry. `CrawlPackScreen` owns the Scaffold,
Pack title, ListView and `BlocBuilder<GameBloc, GameViewState>`. `PackContents`
returns a Column and owns only Pack presentation/local filter, allowing task 02
to place the same contents inside `TownRoom`.

Crawl binds the interface exactly:

```dart
PackContents(
  inventory: state.game.inventory,
  equipment: state.game.equipment,
  materials: state.materials,
  readRefusalFor: state.readRefusalFor,
  onDrink: (id) => bloc.add(DrinkPressed(id)),
  onRead: (id) => bloc.add(ReadPressed(id)),
  onWear: (id) => bloc.add(EquipPressed(id)),
  onDrop: (id) => bloc.add(DropPressed(id)),
)
```

Do not supply `wearRefusalFor` or `showBookTeaching` in crawl. Crawl equip
refusals continue through the real `EquipPressed` → `EquipAction` → log path,
and the town-only teaching detail is not introduced into crawl.

Reuse `Heading`, `NothingHere`, `MaterialRows`, `mono`, and `monoDim` from
`../town/town_style.dart`. Reuse `packSections`, `statLine`, `wornDeltas`, and
`deltaLine` from `item_presentation.dart`. Delete the private duplicate heading,
stats, slots, materials, and skills widgets with the old file.

### Filter

Declare one private enum in this source order:

```text
all       -> All
weapons   -> Weapons
armour    -> Armour
potions   -> Potions
books     -> Books
materials -> Materials
```

The enum may carry its label and nullable `PackSection`; it carries no persisted
or gameplay value. `_PackContentsState` begins at `all`. Render the six controls
as a wrapping sequence of `ChoiceChip`s, each with its exact label,
`showCheckmark: true`, and `Key('pack-filter-${filter.name}')`. The check mark,
label, stable position, and selected semantics are the non-hue selection
language. Do not use a hue-only chip, icon-only category, tab bar, dropdown, or
horizontal control that hides choices off-screen.

A tap only calls local `setState`. It must not read/add to either bloc, invoke a
core action, change a log, consume RNG, write a save, or close the route. A tap
on the already-selected chip may return without `setState`.

Build sections from one `final sections = packSections(widget.inventory)` per
PackContents build:

- All: render all four `PackSection.values` headings in order, including each
  empty heading with a category-specific sentence, then Materials and
  `MaterialRows`.
- One item filter: render only that section heading and its existing stacks, or
  its empty sentence.
- Materials: render only Materials and `MaterialRows`.

Use the current empty sentences:

```text
Weapons: You are carrying nothing you could swing.
Armour: You are carrying nothing you could wear.
Potions: You are carrying nothing you could drink.
Books: You are carrying nothing to read.
```

Do not sort/filter raw `Item`s yourself, call `stacked`, omit an empty section
under All, or drop zero material rows. If an item action empties a selected
category, keep that category selected and render its empty sentence. A live bloc
rebuild retains the State object/filter; popping and reopening creates a new
State and resets to All.

### Item rows and exact action semantics

Render one row per existing `ItemStack`, keyed
`Key('pack-stack-${stack.item.id}')`. Preserve:

- rarity marking plus `stack.label` (the tier word is already in the label);
- `statLine` when non-empty;
- `deltaLine(wornDeltas(item, equipment[slot]))` for equippable items;
- a rule-owned refusal only beside the action it refuses;
- one primary context-valid action plus the independent crawl Drop action.

The primary action is selected by existing item facts in this precedence:
potion → Drink; spell book → Read; equippable → Wear. The callback always gets
`stack.item.id`. Keys are `pack-drink-<id>`, `pack-read-<id>`,
`pack-wear-<id>`, and `pack-drop-<id>`.

For a book, call `readRefusalFor(item.id)`, render the exact returned sentence
when non-null, and set only Read’s callback to null. Never ask that getter about
a potion/gear row. `showBookTeaching` is implemented now for the dependent town
consumer: when true, show the old source-backed line
`<school mark> <school word> · teaches <spell name>`, preserving the current
unknown-spell fallback `teaches nothing this build knows`; when false, show no
teaching detail. It does not affect action/refusal selection.

For an equippable item, call `wearRefusalFor` only when that optional function
is supplied. A non-null result is shown verbatim and disables only Wear. Crawl
supplies no function, so Wear always dispatches the existing event and any rule
refusal lands in the existing GameBloc log. Drop remains available beside a
disabled Read/Wear in crawl, exactly because it is a separate valid action.

Callbacks being absent means the action is not valid in that context and its
button is absent. Never draw a disabled town Drink/Drop placeholder. This task’s
crawl supplies all four callback kinds. No row offers Take off or Cast.

## Red/Green behavioral proof

Follow test-first ordering. Start `pack_screen_test.dart` against the existing
`InventoryScreen`, using the real `GameBloc` and the real Pack route/control;
do not begin with an undefined `CrawlPackScreen` import. Establish behavioral
Red before renaming production:

1. Assert six keyed chips exist, All is selected, the other five are not, and
   no old Stats/Spells/Worn/Skills content is present. Expected Red at
   `55a226d`: no filter chips exist and the duplicate content is present.
2. Tap Books and assert item/material/other-category rows disappear while book
   rows remain; tap Materials and assert every material including zeros appears
   and every item disappears. Expected Red: the controls cannot be found.
3. Through `GameScreen`, open Pack, select a non-All filter, pop, reopen, and
   assert All is selected. Capture `bloc.state.game` and `bloc.state.log` before
   filter/navigation taps and assert identical objects/values afterward.
   Expected Red: the filter is absent; Green proves transient/no-turn behavior.

After observing that Red, implement the source rename and update the test import
and class name. Add the preservation proofs below; these may be green against
the old page before the cutover, because their purpose is to stop the new layout
from dropping existing behavior:

4. **All/order/stacking.** With at least two categories, two identical items,
   and one non-zero material, assert headings occur in Weapons→Armour→Potions→
   Books→Materials vertical order; the identical items render one `×2` row;
   every material word/mark/count row exists, including zero. Switch to each of
   the six filters and assert only its owned content remains. Keep
   `item_presentation_test.dart` as the pure sorting/first-item proof.
5. **Exactly one represented item.** Carry two identical potions. Tap the keyed
   Drink button for the first represented id and assert exactly one potion is
   consumed, HP/log reflect `DrinkPressed`, the surviving stack count changes
   from `×2` to one, and no other category moves. Repeat the first-item identity
   proof with Drop on a two-item stack, asserting one item is underfoot and one
   remains carried.
6. **Read success and refusal.** Reading an eligible book through the keyed
   control learns its spell, removes exactly that represented book, and changes
   the visible selected Books section to its correct remaining/empty state. A
   gated book shows exact `needs Mending 3`, has `onPressed == null`, remains
   carried, and Drop stays enabled. A potion never shows “is not something to
   read”.
7. **Wear success and core refusal.** Wear an eligible carried item and assert
   equipment/inventory update through `EquipPressed`. In a separate state with
   a two-handed main weapon and carried shield, tap the enabled crawl Wear and
   assert equipment/inventory are unchanged and the real log gains
   `Both hands are on the weapon.` (match the existing log sentence/casing,
   derived from core rather than hard-coded in production). Drop remains
   available.
8. **Ownership negatives.** A known spell, non-zero mana/ward, worn item, and
   trained skill in state do not cause Pack to render a learned-spell list,
   Cast, Attack/Armour/Health/Mana/Ward stats, Worn/Take off, or Skills. The Unit
   3 shelf remains the cast path.
9. **Phone fit.** Run the Pack on `onAPhone`, visit every filter, and assert
   `tester.takeException()` is null with the longest available item/refusal and
   both crawl action buttons present.

Use `// arrange` / `// act` / `// assert`. Assert consumer-visible behavior and
real bloc state, not source text, constructor forwarding, or callback echoes.
Close created blocs in teardown.

### Existing test migration

- In `battle_characterization_test.dart`, delete the two-test “pack spell row”
  group, `_openPack` if no longer used, and its Pack import. Those tests require
  a Pack Cast and directly contradict the contract. Keep the Character spell
  group for task 02 and all unrelated crawl characterization.
- Delete `magic_surfaces_test.dart` only after its still-valid book
  classification, gated-read sentence, successful read, and “potion is not
  asked for read refusal” behaviors exist in `pack_screen_test.dart`. Do not
  migrate its Pack learned-spell/cast, mana/ward, or skill-list expectations.
- In `craft_surfaces_test.dart`, keep all node/control tests. Remove its Pack
  helper and Materials/skill groups only after zero/material behavior is proven
  in `pack_screen_test.dart`. Do not re-pin skills inside Pack.
- Delete `skills_row_spacing_test.dart`; it tests geometry of a private Pack
  skill row that no longer exists. Task 02 owns a phone proof for the new Skills
  route.

Expected Green includes no test reference/import of `InventoryScreen` or
`inventory_screen.dart`, no Pack `Cast` assertion, and no test expecting stats,
worn gear, learned spells, or skills in crawl Pack.

## Focused proof commands

From `packages/app`, after Green:

```sh
flutter test test/widget/pack_screen_test.dart \
  test/widget/craft_surfaces_test.dart \
  test/battle_characterization_test.dart \
  test/item_presentation_test.dart \
  test/game_bloc_test.dart \
  test/battle_view_test.dart

dart format lib/game/item_presentation.dart lib/game/pack_screen.dart \
  lib/game/game_screen.dart lib/game/spell_row.dart \
  lib/town/character_screen.dart \
  test/widget/pack_screen_test.dart \
  test/widget/craft_surfaces_test.dart \
  test/battle_characterization_test.dart

dart analyze lib/game/item_presentation.dart
dart analyze lib/game/pack_screen.dart
dart analyze lib/game/game_screen.dart
dart analyze lib/game/spell_row.dart
dart analyze lib/town/character_screen.dart
dart analyze test/widget/pack_screen_test.dart
dart analyze test/widget/craft_surfaces_test.dart
dart analyze test/battle_characterization_test.dart
```

Re-run the focused `flutter test` command after formatting or a static fix.
The test command supplies the focused compile/build proof for the changed
surface; no separate app/APK build is warranted at this leaf. Do not run the
full suite, whole-package `flutter analyze`, emulator, or project-wide
formatter; Main owns them after task 02.

## Executor discretion

You may choose private widget/helper names, the internal enum fields, and local
padding/spacing consistent with the existing Pack/town visual vocabulary. You
may split private row/filter widgets inside `pack_screen.dart` to keep build
methods small. Test fixture construction may move within `pack_screen_test.dart`.

You may not change the public widget names/signature, keys, filter labels/order,
All/empty behavior, callback matrix, `stack.item.id` action identity, refusal
ownership, context details, source/test removals, or route target. Do not add a
new file solely for styling/action abstractions.

## Escalate when

- `packSections` no longer returns all four categories or first-item stacks as
  revalidated;
- `MaterialRows` cannot be reused without changing another town screen;
- local `setState` cannot retain the selected filter across a `GameBloc`
  rebuild or cannot reset on route disposal;
- a required crawl action needs an event other than the four named events, or
  the two-handed refusal differs from the existing GameBloc/core path;
- the optional town-facing interface would require task 01 to change TownBloc
  or implement town routing;
- the filter/action row cannot fit `onAPhone` without hidden controls or
  hue-only selection;
- a still-valid behavior in a deleted test cannot be represented in the new
  behavioral proof;
- any fix requires core/content/save/dependency/LDD changes or alters Unit 3
  shelf/overflow.

## Handoff state and completion receipt

Task 01 is complete only when the crawl Pack is the shared filtered surface,
all six local filters and four crawl actions/refusals are proven, the old file
and obsolete tests are gone, focused tests/static checks are green, and town
Character still works as the old page with only its `slotLabel` import moved.
Task 02 starts from the public `PackContents` constructor above and must not
redesign it from memory.

Report to Main in at most eight prose lines:

- the behavioral Red observed for filter/duplicate/no-turn behavior;
- the focused test command and pass count;
- confirmation that filter/navigation retained the identical GameState/log;
- confirmation of Drink/Read/Wear/Drop first-item behavior and the exact tested
  book/equip refusal paths;
- files added/removed/changed and that no forbidden path changed;
- formatter/static commands and results;
- any escalation or residual phone-layout observation for task 02/Main.
