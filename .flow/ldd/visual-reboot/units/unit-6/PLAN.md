# Unit 6 — Character, Spells, and Pack: Execution Plan

Status: **execution-grade; planning only.** This artifact does not authorize
production implementation.

Derived from `CONTRACT.md`, `recon.md`, the Unit 6 record in
`../../LEDGER.md`, `AGENTS.md`, and the approved design specification at
`docs/specs/2026-08-20-dungeon-game-design.md`. The source base is
`55a226dc04b712f2c5f7b62364a84ecf9c6d1b40` (`55a226d`) on
`residuum-visual-reboot-6`, the merged Unit 5 `main` head named by the contract.
At planning time the worktree was intentionally dirty only in architect-owned
LDD authority: modified `LEDGER.md` and `RESUME.md`, plus the untracked Unit 6
directory containing `CONTRACT.md` and `recon.md`. `packages/app` was clean
relative to `55a226d`; this plan treats those authority changes as user-owned
and does not overwrite them. A changed app source revision requires targeted
revalidation of the seams below, not automatic redesign.

## Execution boundary and dependency graph

Use the current non-main, non-isolated `residuum-visual-reboot-6` checkout. Run
one fresh `flow-plan-executor` per brief, sequentially, so repository state and
named proof—not executor memory—carry the handoff:

```text
01-filtered-crawl-pack
  -> 02-town-character-and-routes
  -> Main final gates, acceptance review, and phone evidence
```

1. `plan-tasks/01-filtered-crawl-pack.md` owns the shared Pack presentation
   seam, the crawl Pack cutover, the six local filters, and crawl action/refusal
   preservation.
2. `plan-tasks/02-town-character-and-routes.md` consumes that exact seam and
   atomically replaces the town long page with the Character overview plus
   Gear, Spells, Skills, and town Pack routes.

This is the smallest valid graph. Crawl Pack is an independently usable and
provable slice and can land while the existing town Character remains intact.
The town cutover is one task even though it creates four routes: there is no
honest intermediate Character hub that may omit one locked route, keep one old
embedded list, or point a button at a placeholder. Adding unreachable detail
screens in separate tasks would be dead code rather than a behavioral handoff.
Within task 02, its route tests form one Red→Green cluster around the atomic
replacement of `CharacterScreen`.

Each executor owns its behavioral Red/Green, touched-file formatter, focused
file analysis, and focused tests. Neither executor runs the full analyzer,
full suite, an app build, an emulator, or an external write. Main owns the
broader gates after task 02.

## Revalidated source seams

All paths below were read at `55a226d`; line numbers are evidence anchors, not
edit instructions.

| Seam | Current fact | Planned consequence |
| --- | --- | --- |
| `packages/app/lib/game/inventory_screen.dart:25-100` | `InventoryScreen` is a single crawl `ListView`: stats, castable learned spells, worn slots, carried sections, materials, then skills. | Replace the file/class cleanly with `game/pack_screen.dart`, `CrawlPackScreen`, and shared `PackContents`; no compatibility `InventoryScreen` remains. |
| `inventory_screen.dart:160-215` | Worn rows dispatch `UnequipPressed`. | Worn rows leave crawl Pack. The existing bloc event/core action remain untouched, but Unit 6 adds no hidden crawl Gear surface; the approved crawl Pack action set is drink/read/wear/drop. |
| `inventory_screen.dart:227-309` | A stack acts through `stack.item.id`; potion→`DrinkPressed`, book→`ReadPressed`, equippable→`EquipPressed`, and every row→`DropPressed`. Only a book receives `readRefusalFor`. | Preserve this dispatch table and first-item stack identity exactly. Filter selection never substitutes an id or dispatches a bloc event. |
| `inventory_screen.dart:312-338` and `town/town_style.dart:177-212` | Two material-row renderers exist; `MaterialRows` is already the town-wide fixed `MaterialId.values` implementation. | Delete the private crawl material row and make shared Pack content reuse `MaterialRows`, retaining zero rows and fixed order. |
| `packages/app/lib/game/item_presentation.dart:49-111` | `ItemStack.item` is the first represented item; `packSections` returns Weapons, Armour, Potions, Books in enum order and preserves empty sections; stack/sort semantics live here. | Pack renders only this map; no filtering, restacking, alternate sorting, or id grouping is added. Move only `slotLabel` here when its old file is removed. |
| `packages/app/lib/game/spell_row.dart:19-88` | `SpellRow` owns school mark+word, name, mana cost, optional effect/refusal/trailing grammar; `effectOf` owns supported effect text. | Dedicated Spells reuses this row with `effectOf` and no reason/trailing action. Update stale Pack-Cast documentation; do not fork the row. |
| `packages/app/lib/game/game_bloc.dart:506-574` | `GameViewState.knownSpells` orders by school then name; `readRefusalFor` delegates to core `readRefusal`. | Extract only the known-spell ordering expression into `knownSpellsInOrder` beside `SpellRow`, and have both `GameViewState` and town Spells call it. Crawl Pack keeps the existing read-refusal getter. |
| `game_bloc.dart:587-624, 757-779` | `EquipPressed`, `DrinkPressed`, `DropPressed`, `ReadPressed`, and `CastPressed` are registered; item handlers forward ids to `EquipAction`, `DrinkAction`, `DropAction`, and `ReadAction`. | Do not rename or wrap these events. Crawl Pack callbacks dispatch them exactly. `CastPressed` remains for Unit 3 shelf/self-casts only, never Pack or dedicated Spells. |
| `packages/app/lib/game/game_screen.dart:455-466` | The contextual shelf opens `InventoryScreen` with the live `GameBloc`. | Change only this route target to `CrawlPackScreen`; the Pack control, count, provider identity, and Unit 3 shelf stay otherwise unchanged. |
| `game_screen.dart:729-914` | `BattleShelf` shows three ordered known spells and `+N`; overflow lists every known spell and acts through the existing arm/cast path. | Preserve byte-for-behavior Unit 3 spell access. Existing exhaustive shelf/overflow tests remain Main/focused gates; no second cast route is added. |
| `packages/app/lib/town/character_screen.dart:27-107` | `CharacterScreen` directly repeats stats, spells, worn, every carried category/material, and skills. | Replace atomically with a short stats/progression overview and four route buttons. No old list is hidden or retained. |
| `character_screen.dart:163-217` | Town worn rows dispatch `TakeOffPressed`; six slots are `EquipSlot.values` and use `slotLabel`. | Move rows to `GearScreen`, preserve enum order, stat lines, eligible dispatch, and rule-owned refusal. |
| `character_screen.dart:227-324` | Town carried rows show existing item facts, book teaching, stat delta, inline read refusal, and dispatch `WearPressed`/`ReadBookPressed`; potions have no action. | Move these facts/actions into `TownPackScreen` through shared `PackContents`; no town Drink or Drop is introduced. |
| `packages/app/lib/town/town_bloc.dart:151-172, 405-428, 773-780` | `WearPressed`→`equipItem`, `TakeOffPressed`→`unequipItem`, `ReadBookPressed`→`readBook`; `_transacted` carries stock/merchant/crawl and exposes exact core refusal as `SentenceNotice`. | Keep events and handlers byte-for-behavior. Add pure `TownViewState` refusal getters that delegate to `wearRefusal`, `takeOffRefusal`, and `readRefusal`; widgets never duplicate a rule sentence. |
| `town_bloc.dart:317-323` | `TownViewState.materials` returns every material in enum order with zero counts. | Town Pack passes this map to shared `PackContents`; no save or profile mutation occurs. |
| `packages/app/lib/town/town_screen.dart:89-105, 144-163` | The existing Character door pushes `CharacterScreen` while providing the existing bloc instances. | Keep the town door unchanged. Character’s own detail-route helper forwards only the existing `TownBloc`; none of its detail routes needs `WorldBloc`. |
| `packages/app/test/widget/character_screen_test.dart` | Pins every section of the old town long page plus live Wear/Take-off/Read actions. | Rewrite around the overview/routes and move each factual/action assertion to its owning detail route. |
| `packages/app/test/battle_characterization_test.dart:137-201` | Pins Pack Cast/refusal and the old embedded Character spell row. | Delete those obsolete layout contracts; keep unrelated crawl characterization. New Pack/Spells tests own the replacement behavior. |
| `packages/app/test/widget/magic_surfaces_test.dart` | Entire file pins learned spells/mana/skills inside crawl Pack plus book behavior. | Delete after moving still-valid book/refusal behavior to `pack_screen_test.dart`; do not re-pin Pack Cast/stats/skills. |
| `packages/app/test/widget/craft_surfaces_test.dart:175-272` | Pins materials and skills inside crawl Pack. | Keep the node/control group; move material behavior to Pack proof and delete the obsolete Pack skill group. |
| `packages/app/test/widget/skills_row_spacing_test.dart` | Pins geometry of the crawl Pack’s soon-removed private skill row. | Delete; the new Skills route gets consumer-visible progression/phone overflow proof, not an implementation-geometry transplant. |
| `packages/app/test/item_presentation_test.dart:236-349, 460-518` | Proves category order, sorting, stacking, book classification, and first-item stack action identity. | Leave behavior intact and run it in task 01 focused proof. |
| `packages/app/test/battle_view_test.dart:851-926` | Proves readied-three/overflow and that overflow lists and acts through a non-readied known spell. | Preserve and run after both tasks; this discharges exhaustive crawl spell access without a Pack cast test. |

## Locked architecture and interfaces

### 1. Shared Pack seam

Task 01 replaces `inventory_screen.dart` with
`packages/app/lib/game/pack_screen.dart`. It exports exactly two public widgets:

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

No generic action object, controller, repository, route shell, inherited widget,
or bloc adapter is introduced. `CrawlPackScreen` owns the crawl `Scaffold`,
title and `BlocBuilder<GameBloc, GameViewState>`. `PackContents` owns only Pack
layout plus its local filter. `TownPackScreen` in task 02 owns the town bloc
binding and `TownRoom` and consumes this interface.

`PackContents` returns one `Column`; route wrappers own scrolling. It imports and
reuses `Heading`, `NothingHere`, `MaterialRows`, `mono`, and `monoDim` from the
existing `town_style.dart` presentation vocabulary rather than retaining the
private crawl copies. The existing game layer already imports the same palette
from `town_style.dart`; this does not create a new package dependency.

The optional callbacks encode only context availability:

| Item kind | Crawl callbacks | Town callbacks |
| --- | --- | --- |
| Potion | Drink + Drop | none |
| Spell book | Read + Drop | Read |
| Equippable weapon/armour | Wear + Drop | Wear |

`Drop` is independent of the primary action and appears on every crawl stack.
No callback means no control; it never means a disabled invented action.
`showBookTeaching` is false in crawl and true in town, preserving the existing
town-only source-backed “school mark + school word + teaches spell” line without
adding a new crawl item detail. The existing fallback for an unknown taught
spell remains `teaches nothing this build knows`.

For every rendered stack, every callback receives `stack.item.id`, never a
base id, stack key, index, or all represented ids. After one action, the bloc
state rebuilds the stacks and the next represented item becomes the row’s
first item naturally.

### 2. Filter ownership and rendering

A private enum in `game/pack_screen.dart` owns exactly, in this order:
`all`, `weapons`, `armour`, `potions`, `books`, `materials`. Its labels are
exactly `All`, `Weapons`, `Armour`, `Potions`, `Books`, `Materials`.

`_PackContentsState` initializes to `all`. A `Wrap` of six `ChoiceChip`s is the
only filter control. Each chip has `Key('pack-filter-${filter.name}')`, a visible
label, and `showCheckmark: true`; selection is therefore carried by a check
mark, word, position, and semantics—not hue. Selecting a chip calls only local
`setState`; it dispatches no `GameBlocEvent`, `TownBlocEvent`, core action, save,
or autosaver write. Selecting the current chip is a local no-op.

- `All` renders all four `PackSection.values` headings in their enum order,
  including an explicit category-specific empty sentence, followed by
  `Materials` and all `MaterialId.values` rows.
- An item filter renders only its one existing `PackSection` heading and its
  `packSections(inventory)[section]` rows, or the same empty sentence.
- `Materials` renders only its heading and `MaterialRows`.
- Filtering never builds a new item order beyond selecting one existing list;
  it never calls `stacked` itself.
- An action that empties the selected category leaves that filter selected and
  displays its empty sentence. It does not jump to All.
- A bloc rebuild while the route is open preserves the state object and current
  filter. Popping and reopening the route constructs a new `PackContents` and
  therefore defaults to All. Nothing is restored after app/session restart.

Use `Key('pack-stack-${stack.item.id}')` for each represented row and
`Key('pack-drink-${item.id}')`, `pack-read-…`, `pack-wear-…`, and `pack-drop-…`
for controls. Keys identify the actual represented item and make “exactly one”
a behavioral proof; they are not persisted identity.

### 3. Refusal ownership

No widget composes, normalizes, capitalizes, or paraphrases a refusal.

- Crawl book rows call existing `GameViewState.readRefusalFor` only for books;
  the exact non-null sentence is shown beside a disabled Read control. Potions
  are never asked for a read refusal.
- Crawl Wear remains enabled whenever the represented item is equippable and
  dispatches `EquipPressed` exactly as before. A core refusal continues through
  `GameBloc._act` into the log; task 01 must prove the sentence and unchanged
  equipment/inventory. Do not preflight it into a new presentation rule.
- Town Pack supplies `TownViewState.wearReason` and `readReason`. A non-null
  core sentence is printed beside the action and disables only that action.
  An eligible press still dispatches the existing `WearPressed` or
  `ReadBookPressed` event.
- Gear calls `TownViewState.takeOffReason` for a worn slot. A full-pack refusal
  is visible and disables Take off; an eligible press dispatches
  `TakeOffPressed(slot)`.

Task 02 adds these pure getters to `TownViewState`, with no cached result and no
new state:

```dart
String? wearReason(String itemId) =>
    wearRefusal(profile.loadout, profile.inventory, itemId);

String? takeOffReason(EquipSlot slot) =>
    takeOffRefusal(profile.equipment, profile.inventory, slot);

String? readReason(String itemId) => readRefusal(
  profile.loadout,
  profile.inventory,
  profile.knownSpells,
  spellsById,
  itemId,
);
```

Their handler counterparts remain exactly
`equipItem(state.profile, event.itemId)`,
`unequipItem(state.profile, event.slot)`, and
`readBook(state.profile, event.itemId, spellsById)`. This preserves stock,
merchant visit, suspended crawl, notice, profile/save, and core transaction
semantics through `_transacted`/`_settled`.

### 4. Character and detail routes

`CharacterScreen` remains the target of the existing town Character door. Its
body is one `BlocBuilder<TownBloc, TownViewState>` and a `TownRoom(title:
'Character')`. It shows:

1. the existing town-derived Attack, Armour, Dodge, Speed, current Health, and
   maximum Mana facts (no invented current-town mana);
2. `Spells known    N`, where `N == profile.knownSpells.length`;
3. `Skills trained  N/M`, where `M == SkillId.values.length` and `N` counts
   entries whose current `SkillState.level > 0`; and
4. four `FilledButton`s in order: Gear, Spells, Skills, Pack, keyed
   `character-route-gear`, `character-route-spells`,
   `character-route-skills`, and `character-route-pack`.

It contains no item row, material row, slot row, spell row, skill progress row,
tab, portrait/name placeholder, character-level aggregate, attribute, quest,
or action button. Navigation captures the existing `TownBloc` and pushes a
`MaterialPageRoute<void>` wrapped in `BlocProvider.value`; it dispatches no bloc
or core event and mutates no profile/RNG/save state. `WorldBloc` is not forwarded
because none of these routes reads it.

Task 02 adds:

- `town/gear_screen.dart` — `GearScreen`, six `EquipSlot.values` rows in enum
  order, item display/stat line, rule-owned Take-off refusal, and eligible
  `TakeOffPressed` dispatch. Empty slots show `—` and no button.
- `town/spells_screen.dart` — `SpellsScreen`, every resolvable known spell once
  in existing school/name order through `SpellRow(detail: effectOf(spell))`.
  It supplies neither `reason` nor `trailing`; there is no locked/unavailable
  state and no Cast control. Empty known set shows one plain empty sentence.
- `town/skills_screen.dart` — `SkillsScreen`, every `SkillId.values` row once,
  using `profile.skills[id] ?? const SkillState()`, existing `skillName`, level,
  `xp/xpToNext(level)`, and the non-hue progress bar. Rows are keyed
  `skill-${skill.name}`.
- `town/pack_screen.dart` — `TownPackScreen`, the town `BlocBuilder`, and
  `PackContents` with `showBookTeaching: true`, town Wear/Read refusals and
  events, and no Drink/Drop callbacks.

`slotLabel` moves from deleted `inventory_screen.dart` to
`item_presentation.dart`; all six current labels and `EquipSlot.values` order
stay unchanged. `knownSpellsInOrder(Set<String>, Map<String, Spell>)` is added
beside `SpellRow`; it preserves the current behavior of ignoring unresolved ids
and sorting resolvable spells by `school.index`, then `name`. Both
`GameViewState.knownSpells` and `SpellsScreen` use it, so Unit 3 shelf and the
read-only route cannot drift in ordering.

## Migration and removal inventory

Task 01:

- add `packages/app/lib/game/pack_screen.dart`;
- remove `packages/app/lib/game/inventory_screen.dart` with no alias/re-export;
- move `slotLabel` to `item_presentation.dart` and update the still-old town
  Character import until task 02 replaces that screen;
- point `GameScreen` at `CrawlPackScreen`;
- add `packages/app/test/widget/pack_screen_test.dart`;
- remove obsolete Pack-cast characterization from
  `battle_characterization_test.dart`;
- delete `magic_surfaces_test.dart` after migrating book/refusal behavior;
- retain only the crawl node/control group in `craft_surfaces_test.dart` and
  migrate its material assertions;
- delete `skills_row_spacing_test.dart` rather than re-pin a removed private
  layout;
- update stale `SpellRow` documentation that names Pack as a casting surface.

Task 02:

- rewrite `town/character_screen.dart`;
- add `town/gear_screen.dart`, `town/spells_screen.dart`,
  `town/skills_screen.dart`, and `town/pack_screen.dart`;
- add the three pure refusal getters to `TownViewState` without changing any
  event or handler;
- add `knownSpellsInOrder` to `spell_row.dart` and delegate
  `GameViewState.knownSpells` to it;
- rewrite `character_screen_test.dart`, extend `pack_screen_test.dart` with the
  town context, and remove the now-obsolete embedded Character spell
  characterization from `battle_characterization_test.dart`.

Do not leave an `InventoryScreen`, a hidden old Character body, a Pack learned
spell list, a Pack/grimoire Cast button, duplicate material/skill/slot row,
compatibility constructor, deprecated alias, or test that asserts the retired
long-page layout.

## Explicit non-goals and forbidden expansion

- No edit under `packages/core`, `packages/content`, save/autosaver code, save
  document/version, RNG, balance, item ids, content values, or rules.
- No change to Unit 3 shelf/overflow behavior, `CastPressed`, targeting,
  readied count/order, quick-drink, timeline, log drawer, map, Flame, camera, or
  combat.
- No crawl Gear route, no town Cast/Drink/Drop, no bank/merchant action in Pack,
  no item detail route, no new category/sort/stack/capacity rule.
- No name, portrait, character level, attribute, quest/favorite/prepared-kit,
  spell lock state, skill point/perk selection, tab bar, generic management
  shell, route registry, or persistence for filters/navigation.
- No new package dependency, asset, icon language, static art, HUD/town/world
  redesign, analytics, telemetry, or external write.

## Integrated proof ownership

The task briefs name exact Red/Green and focused commands. After both tasks are
green, Main runs from `packages/app`:

```sh
dart format --set-exit-if-changed --output=none \
  lib/game/item_presentation.dart lib/game/pack_screen.dart \
  lib/game/game_screen.dart lib/game/game_bloc.dart lib/game/spell_row.dart \
  lib/town/character_screen.dart lib/town/gear_screen.dart \
  lib/town/spells_screen.dart lib/town/skills_screen.dart \
  lib/town/pack_screen.dart lib/town/town_bloc.dart \
  test/battle_characterization_test.dart test/item_presentation_test.dart \
  test/battle_view_test.dart test/game_bloc_test.dart test/town_bloc_test.dart \
  test/widget/character_screen_test.dart test/widget/pack_screen_test.dart \
  test/widget/craft_surfaces_test.dart test/widget/craft_rooms_test.dart
flutter analyze
flutter test
```

Main then verifies the final diff is confined to the planned `packages/app`
source/tests plus architect-owned Unit 6 LDD records, with no `packages/core`,
`packages/content`, save/autosaver, generated, or dependency-file change. Main
runs one integrated acceptance review against `CONTRACT.md`; plan compliance is
not a substitute for correctness.

For criterion 10, Main uses the current user-started phone AVD (the established
`Medium_Phone` may not be launched successfully from a tool shell). Before any
install or save-clearing action, copy both device `save.json` and
`save-previous.json` to the untracked Unit 6 evidence directory, record their
SHA-256 values, and after the session restore both exact bytes and verify both
hashes. Run/install only after that backup exists.

The normal-colour and greyscale evidence set must show the compact Character
overview; Gear with all six slots; Spells with mark, word, cost and effect and no
Cast; Skills with full progress rows; town Pack with all six filter choices and
town-only actions; and crawl Pack reached from the existing shelf with its
context actions. Exercise All and every individual filter at least once. Record
before/after visible hero facts and log/position around navigation/filter-only
interactions so no turn or transaction is observed. The selected filter must
remain identifiable by check mark/label/position in greyscale. Action/refusal
proof remains primarily the deterministic widget/bloc evidence; device work
confirms reachability, fit, and non-hue presentation without bending content or
adding fixtures.

## Global escalation boundary

Stop the affected task and return to the architect if:

- current app source no longer matches a revalidated seam or another writer has
  changed a planned file;
- a locked route cannot be delivered without a missing product decision;
- `PackContents` cannot represent both contexts without a generic action model
  or a rule in a widget;
- any item action would need a different event, id, refusal sentence, turn cost,
  sorting/stacking rule, or save shape;
- a town refusal getter cannot delegate directly to the named core refusal
  function or disagrees with the existing transaction handler;
- preserving every known spell in Unit 3 shelf/overflow requires changing that
  shelf, its readied rule, targeting, or `CastPressed`;
- a required proof needs `packages/core`, `packages/content`, a save/autosaver
  edit, mock-only content, or a new dependency;
- the six chips or item actions cannot fit a phone without hiding a choice or
  carrying selection by hue alone.

Executor discretion is limited to private helper names, local widget splitting,
padding/spacing within the existing town/game visual vocabulary, and test
fixture placement. It does not include public class/constructor names, keys,
route/filter order, displayed facts, action/refusal ownership, file ownership,
or migration removals locked above.

## Plan quality gate

- **COR — PASS.** State ownership is explicit: blocs/core retain facts and
  transactions, route/filter state is local Flutter state, and the shared Pack
  view receives only immutable facts plus context-valid callbacks. The
  first-item stack id, fixed category/material order, filter lifetime, empty
  category behavior, rule-owned refusal path, and every town/crawl action are
  fixed. Character’s four-route cutover is atomic; Unit 3 remains the sole crawl
  casting path. No hidden old surface or fallback survives.
- **TTC — PASS.** Task 01 names behavioral Red for missing filters, duplicated
  Pack content, filter lifetime, and no-turn state; it preserves all four crawl
  actions, first-item stacks, book and equip refusals, fixed order, and zero
  materials. Task 02 names behavioral Red for the absent route hub and old long
  page; it proves every route, compact absence, six Gear slots and take-off,
  factual read-only spells, every skill/progress row, town Pack action/refusal
  limits, and navigation/filter no-mutation. Existing bloc suites prove handler
  semantics; `battle_view_test.dart` proves exhaustive shelf/overflow access.
  Main owns formatter, analyzer, full suite, scope audit, review, and device
  acceptance.
- **CRF — PASS.** One shared focused `PackContents` replaces two copied item and
  material implementations without becoming a generic management shell.
  `packSections`, `MaterialRows`, `SpellRow`/`effectOf`, stat/delta helpers,
  `slotLabel`, and `knownSpellsInOrder` each have one owner. Four small town
  screens own four distinct concerns. Old classes/tests are removed rather than
  wrapped or aliased; no controller/service/route framework or persisted filter
  is planned.
- **SEC — SKIP (no new trust boundary).** Unit 6 is local Flutter presentation
  over existing immutable state and core actions. It adds no network,
  deserialization, persistence, privilege, external input, secret, or asset
  boundary. Refusal text is produced by existing rule functions and rendered,
  never parsed into authority.

Residual risks deliberately left to implementation evidence: six `ChoiceChip`s
and two-action crawl rows must fit the real phone without overflow; Android font
and theme rendering must keep the selected check mark visible in greyscale; and
the route-local filter must retain state across live bloc rebuilds while
resetting after route disposal. The named widget proofs and final device gate
own those risks; none requires an unresolved product decision.

## Planner receipt

- **STATUS:** READY — execution-grade; implementation remains separately
  authorized.
- **Source/dirty assumption:** `55a226d` on `residuum-visual-reboot-6`;
  `packages/app` clean, architect-owned `LEDGER.md`, `RESUME.md`,
  `unit-6/CONTRACT.md`, and `unit-6/recon.md` dirty/untracked and preserved.
- **Tasks:** `01-filtered-crawl-pack.md` →
  `02-town-character-and-routes.md` → Main gates.
- **Quality:** COR/TTC/CRF PASS; SEC SKIP for no trust-boundary change.
- **Next action:** Main validates this receipt and, only with implementation
  authorization, dispatches task 01 to a fresh non-isolated
  `flow-plan-executor` in the current feature checkout.
