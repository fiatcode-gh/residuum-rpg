# Task 02 — Town Character overview and focused routes

Owner: second fresh sequential executor in the same non-isolated
`residuum-visual-reboot-6` checkout after task 01 is green. Read `../PLAN.md`,
`../CONTRACT.md`, `../recon.md`, and
`01-filtered-crawl-pack.md` before editing.

## Expected starting repository condition

Task 01 has landed and supplied focused Green:

- `packages/app/lib/game/pack_screen.dart` exports `CrawlPackScreen` and the
  exact `PackContents` constructor locked in the plan;
- `inventory_screen.dart`, `magic_surfaces_test.dart`, and
  `skills_row_spacing_test.dart` no longer exist;
- `GameScreen` opens `CrawlPackScreen` and crawl Pack has six local filters;
- `slotLabel` lives in `item_presentation.dart`;
- `character_screen.dart` still renders the old town long page but imports
  `slotLabel` from its new owner;
- `pack_screen_test.dart` proves crawl filtering/no-turn/action/refusal behavior;
- `battle_characterization_test.dart` still contains only the old embedded
  Character spell-row characterization plus unrelated crawl characterization.

Before editing, inspect branch/status and read the task 01 completion receipt.
If task 01’s public interface or proof is absent, or any planned file has
unexplained changes, do not improvise or discard work; stop and report the
contradiction. Preserve architect-owned uncommitted `.flow` files.

## Behavioral slice and scope

This task atomically converts the one existing town Character room into a
compact overview and all four locked routes, consuming task 01’s Pack seam. It
finishes Unit 6 local implementation and leaves the repository ready for Main’s
broad gates/review/device evidence.

Touch only:

- rewrite `packages/app/lib/town/character_screen.dart`;
- add `packages/app/lib/town/gear_screen.dart`;
- add `packages/app/lib/town/spells_screen.dart`;
- add `packages/app/lib/town/skills_screen.dart`;
- add `packages/app/lib/town/pack_screen.dart`;
- update `packages/app/lib/town/town_bloc.dart` only with the three pure refusal
  getters named below; existing events/handlers/construction stay unchanged;
- update `packages/app/lib/game/spell_row.dart` with the shared known-spell
  ordering helper;
- update `packages/app/lib/game/game_bloc.dart` only to delegate
  `GameViewState.knownSpells` to that helper;
- rewrite `packages/app/test/widget/character_screen_test.dart`;
- extend `packages/app/test/widget/pack_screen_test.dart` with town context;
- update `packages/app/test/battle_characterization_test.dart` to remove the
  obsolete embedded Character spell-row group/helper/imports.

Do not alter `PackContents` or weaken task 01's crawl assertions unless the
repository proves the locked interface cannot support town. Do not modify
`town_screen.dart`,
`town_style.dart`, any existing TownBloc event/handler, Unit 3 shelf/game screen,
`battle_view_test.dart`, `town_bloc_test.dart`, `packages/core`,
`packages/content`, save/autosaver code, dependency files, or LDD authority.

## Locked implementation

### `CharacterScreen`: facts and routes only

Keep `CharacterScreen` as the exact target of the existing TownScreen
`Character` door. Its `BlocBuilder<TownBloc, TownViewState>` builds
`TownRoom(title: 'Character')` with only:

1. the existing derived fact panel:
   - `Attack   <min>-<max>` from `heroAttack(profile.hero, profile.loadout)`;
   - `Armour   <n>` from `heroArmor(profile.loadout)`;
   - `Dodge    <n>%` from `heroDodgePercent(profile.loadout)`;
   - `Speed    <n>` from `heroSpeed(profile.hero, profile.loadout)`;
   - `Health   <current>/<max>` from `profile.hero.hp/profile.maxHp`;
   - `Mana     <max>` from `heroMaxMana(profile.loadout)` (town has no current
     mana, so do not invent one);
2. `Spells known    ${profile.knownSpells.length}`;
3. `Skills trained  $trained/${SkillId.values.length}`, where `trained` counts
   only `profile.skills[id]?.level ?? 0` values greater than zero; and
4. four full-width `FilledButton`s, in this order and with these keys/labels:
   - `Key('character-route-gear')`, `Gear`;
   - `Key('character-route-spells')`, `Spells`;
   - `Key('character-route-skills')`, `Skills`;
   - `Key('character-route-pack')`, `Pack`.

The overview contains no `SpellRow`, slot/item/material/skill-progress row,
item transaction control, tab/tab controller, generic dashboard shell, name,
portrait, character level, attribute, quest, favorite, or unsupported fact.
Delete the old private `_WornRow`, `_CarriedRow`, `_SkillRow`, empty-section
helper, and all imports made obsolete by that deletion. Keep a small private
stats widget if useful; do not extract a generic overview framework.

A private `_open(BuildContext, Widget)` captures
`context.read<TownBloc>()` and pushes `MaterialPageRoute<void>` whose child is
`BlocProvider.value(value: town, child: screen)`. It dispatches no event and
does not pass `WorldBloc`, because Gear/Spells/Skills/Pack read only TownBloc.
Do not change `TownScreen._open`; the existing town door already supplies both
blocs to Character.

### Pure refusal projections on `TownViewState`

Add exactly these public methods beside the existing view-state rule projections
(`smeltReason`, `brewReason`, `temperReason`):

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

Dartdoc each as a rule-owned reason/null projection and state that the screen
asks the rule instead of duplicating it. Do not cache a reason, add state, add an
event, call `equipItem`/`unequipItem`/`readBook` speculatively, or build a
sentence in app code.

Do not change these existing action paths:

```text
WearPressed(itemId)       -> equipItem(state.profile, itemId)
TakeOffPressed(slot)      -> unequipItem(state.profile, slot)
ReadBookPressed(itemId)   -> readBook(state.profile, itemId, spellsById)
```

They must continue through `_transacted`/`_settled`, carrying town, stock,
merchant visit and suspended crawl and exposing any core transaction answer as
the existing notice. Eligible UI presses still send these events; the getters
only make known unavailability visible before a disabled press.

### `GearScreen`

`GearScreen extends StatelessWidget` with `const GearScreen({super.key})`. It
uses one `BlocBuilder<TownBloc, TownViewState>` and
`TownRoom(title: 'Gear')`. Render every `EquipSlot.values` member once and in
that exact order, using `slotLabel`, with row key
`Key('gear-slot-${slot.name}')`.

Each row shows the slot word, `—` when empty, otherwise `displayName` plus
`statLine` when non-empty. An empty row has no action. For a worn item, call
`state.takeOffReason(slot)`:

- null: show enabled `Take off`, keyed `gear-take-off-${slot.name}`, dispatching
  `TakeOffPressed(slot)` on the existing bloc;
- non-null: show the exact sentence beside a disabled `Take off` control.

Never add Wear to Gear, because carried items live in Pack. Never hide a worn
item because the pack is full. Successful take-off must rebuild from the emitted
TownViewState so the slot becomes `—` and the exact item appears in profile
inventory.

### Known-spell ordering and `SpellsScreen`

Add this one presentation helper beside `SpellRow`/`effectOf` in
`game/spell_row.dart`:

```dart
List<Spell> knownSpellsInOrder(
  Set<String> ids,
  Map<String, Spell> spells,
)
```

It returns a fresh list containing only ids resolved by the supplied map,
sorted by `spell.school.index`, then `spell.name`. Preserve the exact current
`GameViewState.knownSpells` behavior by replacing only its private list/sort
body with a call to this helper. Do not alter `GameState`, the known id set,
content, readied count, shelf, overflow, or cast/refusal logic.

`SpellsScreen extends StatelessWidget` with `const SpellsScreen({super.key})`.
It uses `knownSpellsInOrder(profile.knownSpells, spellsById)` once per TownBloc
build and `TownRoom(title: 'Spells')`.

- If empty, render exactly `You have not learned any spell yet.` through
  `NothingHere`.
- Otherwise render every resolved known spell once through
  `SpellRow(spell: spell, style: mono, dimStyle: monoDim, detail:
  effectOf(spell))`.
- Supply neither `reason` nor `trailing`. Do not render Cast, arm, favorite,
  unavailable/locked, learn, mana-current, or target state.

The row therefore shows the existing non-hue school mark and word, name, mana
cost, and effect facts. This dedicated route is read-only. The actionful Unit 3
shelf/overflow remains untouched and exhaustive.

### `SkillsScreen`

`SkillsScreen extends StatelessWidget` with `const SkillsScreen({super.key})`.
It uses one TownBloc builder and `TownRoom(title: 'Skills')`. Render every
`SkillId.values` member once in enum order, regardless of level, with
`profile.skills[id] ?? const SkillState()` and row key
`Key('skill-${skill.name}')`.

Each row preserves the old factual grammar: `skillName(skill)`, numeric level,
non-hue progress bar with `value == xp / xpToNext(level)` clamped to `[0, 1]`,
and text `${state.xp}/$cost`. Preserve a readable gap between the name and level
columns at phone size. Do not add character level, skill points, perk controls,
training advice, category color, or filtering.

### `TownPackScreen`

`TownPackScreen extends StatelessWidget` with
`const TownPackScreen({super.key})`. It uses one TownBloc builder and
`TownRoom(title: 'Pack')`, with the task 01 `PackContents` as its only substantive
child:

```dart
PackContents(
  inventory: state.profile.inventory,
  equipment: state.profile.equipment,
  materials: state.materials,
  readRefusalFor: state.readReason,
  wearRefusalFor: state.wearReason,
  onRead: (id) => bloc.add(ReadBookPressed(id)),
  onWear: (id) => bloc.add(WearPressed(id)),
  showBookTeaching: true,
)
```

Do not provide `onDrink` or `onDrop`; town has no such transactions. Do not add
Take off here; it belongs to Gear. `PackContents` keeps its local filter across
TownBloc rebuilds and resets when this route is popped/reopened.

A town Wear/Read refusal is rendered verbatim beside its disabled action from
the getter above. Eligible presses still dispatch the exact existing event and
update the observed profile. There is no need to render `state.notice` in this
route, which avoids carrying a stale forge/merchant notice into Character;
preflight and handler use the same core refusal functions.

## Red/Green behavioral proof

Follow test-first ordering against the task 01 repository. Drive the existing
TownScreen→Character door and current CharacterScreen by visible controls; do
not import undefined new screen classes to manufacture a compile error.

Establish behavioral Red:

1. On the existing Character page, assert keyed `FilledButton`s for Gear,
   Spells, Skills and Pack exist in order, and assert a stocked hero’s specific
   worn item, carried item, material word, known spell, and trained skill name
   are absent from the overview. Expected Red: no route buttons exist and all
   duplicated detail rows are embedded.
2. Tap each required route button and assert the route title/owned facts, then
   pop back. Expected Red: the first button cannot be found; Green requires all
   four real routes, not placeholder screens.

After that Red, perform the atomic source cutover and add the following focused
proofs.

### `character_screen_test.dart`

Rewrite the old long-page tests into one group per owner:

1. **Town door and concise overview.** Enter through the real `TownScreen`
   Character door on `onAPhone`. Assert the six exact combat/health facts, exact
   `Spells known` and `Skills trained N/M` values, four route buttons in order,
   no `TabBar`, and absence of the stocked hero’s detail values. Seed one
   uncommitted town notice and assert it is not rendered in Character or a detail
   route before an action.
2. **Navigation is presentation-only.** Capture the identical `TownViewState`
   and `Profile`, visit each route and pop without acting, then assert bloc state
   and profile are the same objects and no profile/save-backed field changed.
3. **Gear facts and success.** Assert the six keyed slot rows appear in
   `EquipSlot.values` order, empty rows show `—`, a worn item shows its stat line,
   and eligible Take off moves exactly that item to inventory and empties the
   slot through the live TownBloc.
4. **Gear refusal.** With `inventory.length == inventoryCap` and one worn item,
   assert exact `your hands are too full to stow it`, disabled keyed Take off,
   unchanged equipment/inventory, and no stale incoming notice. This proves the
   getter and handler share core semantics without dispatching an unavailable
   action.
5. **Read-only Spells.** Seed multiple known spells across schools. Assert every
   resolved known spell exactly once, school/name order, school marking and
   word, cost and `effectOf` detail, and no Cast/action/locked/unavailable text.
   An empty profile gets the exact empty sentence. Do not weaken the existing
   `battle_view_test.dart` shelf/overflow proof.
6. **Skills completeness.** Assert one keyed row for every `SkillId.values`,
   enum order, default zero rows, and a trained row’s exact level and `xp/cost`
   descendants. Run on `onAPhone`, scroll to the final skill, and assert no
   exception/overflow.

### Town group in `pack_screen_test.dart`

Reuse task 01’s shared Pack/filter fixture and add:

7. **Exact action set.** A town Pack with potion, book, weapon and armour has
   Wear only on equippable stacks and Read only on books; it has no Drink, Drop,
   Take off, or Cast anywhere. The six shared filters/default/order/zero
   materials remain intact.
8. **Wear success.** Tap the keyed town Wear for an eligible represented stack;
   assert `TownBloc.profile.equipment` receives exactly its first item id,
   inventory removes exactly one represented item, and the selected filter is
   retained across the bloc rebuild.
9. **Wear refusal.** With a two-handed main weapon and carried shield, assert
   exact lower-case core sentence `both hands are on the weapon`, keyed Wear is
   disabled, profile/inventory/equipment are unchanged, and no Drink/Drop is
   invented.
10. **Read success and refusal.** An eligible book shows its existing teaching
    line, dispatches `ReadBookPressed`, joins `knownSpells`, and removes exactly
    that represented book while retaining Books filter. A gated book shows exact
    `needs Wrath 4`, has disabled Read, and remains carried. A potion is never
    asked for/read refusal and gets no action.
11. **Transient/no transaction.** Select every town filter without acting;
    assert TownViewState/Profile identity and every profile field are unchanged.
    Pop/reopen and assert All defaults again.

Use real blocs and observable state, `// arrange` / `// act` / `// assert`, and
teardown close. Do not add mock blocs, callback-spy tests, source-text assertions,
or tests of mere field forwarding.

### Existing characterization cutover

Delete the obsolete Character spell group, `_openCharacter`, and now-unused
imports from `battle_characterization_test.dart`. Its old assertion omitted
spell effects and directly embedded the row in Character; the new
`character_screen_test.dart` Spells route is the stronger consumer contract.
Keep every unrelated crawl/timeline/map characterization.

Existing `town_bloc_test.dart` remains unchanged and is focused Green proof for
successful/refused Wear/Take-off/Read plus transaction carry semantics. Existing
`battle_view_test.dart:851-926` remains unchanged and proves every known spell
is reachable and actionful only through Unit 3 shelf/overflow. Existing
`game_bloc_test.dart` remains unchanged and guards `GameViewState.knownSpells`
ordering/cast behavior after delegation.

Expected Green has no test expecting spell, slot, pack/material or skill rows
inside Character itself; no dedicated Spells Cast control; and no duplicate
town item-row implementation outside shared `PackContents`.

## Focused proof commands

From `packages/app`, after Green:

```sh
flutter test test/widget/character_screen_test.dart \
  test/widget/pack_screen_test.dart \
  test/battle_characterization_test.dart \
  test/town_bloc_test.dart \
  test/town/town_crawl_carry_test.dart \
  test/game_bloc_test.dart \
  test/battle_view_test.dart \
  test/widget/craft_rooms_test.dart

dart format lib/town/character_screen.dart lib/town/gear_screen.dart \
  lib/town/spells_screen.dart lib/town/skills_screen.dart \
  lib/town/pack_screen.dart lib/town/town_bloc.dart \
  lib/game/spell_row.dart lib/game/game_bloc.dart \
  test/widget/character_screen_test.dart \
  test/widget/pack_screen_test.dart \
  test/battle_characterization_test.dart

dart analyze lib/town/character_screen.dart
dart analyze lib/town/gear_screen.dart
dart analyze lib/town/spells_screen.dart
dart analyze lib/town/skills_screen.dart
dart analyze lib/town/pack_screen.dart
dart analyze lib/town/town_bloc.dart
dart analyze lib/game/spell_row.dart
dart analyze lib/game/game_bloc.dart
dart analyze test/widget/character_screen_test.dart
dart analyze test/widget/pack_screen_test.dart
dart analyze test/battle_characterization_test.dart
```

Re-run the focused test command after formatting or static correction. These
widget/test invocations compile and exercise every new route; no separate
leaf APK/build is warranted. Do not run the full suite, whole-package
`flutter analyze`, whole-tree formatter, emulator, or device install. Main owns
those final gates once this task hands off.

## Executor discretion

You may choose private row/stats/helper names, local file-private widget splits,
and padding/spacing consistent with `TownRoom`, `Heading`, `mono`, `monoDim`,
`panel`, and `rule`. You may choose how tests measure vertical order (widget
sequence or rects) and where fixtures live.

You may not change public screen names, route labels/order/keys, summary labels
or arithmetic, known-spell ordering/signature, refusal getter names/bodies,
Gear/Skills row keys, Pack constructor/binding, action availability, existing
event/handler behavior, source ownership, or removals. Do not extract a generic
route tile, detail shell, action model, progress service, or character view
model.

## Escalate when

- task 01’s `PackContents` interface cannot express town actions/refusals
  without modification;
- one of the three named core refusal functions is absent, differs from the
  handler transaction, or requires mutation/RNG to evaluate;
- `CharacterScreen` cannot push all four routes with the existing TownBloc
  without changing `TownScreen` or session wiring;
- an unresolved known spell must be displayed rather than ignored to preserve
  current behavior, or sorting by school/name differs from Unit 3 shelf order;
- a required detail fact/action needs a new profile field, event, core rule,
  content value, save field, or persistence;
- any test indicates Unit 3 shelf/overflow, TownBloc transaction carry, item id,
  refusal sentence, or save behavior changed;
- phone fit requires hiding a route/filter/action, a tabbed dashboard, or a
  hue-only distinction;
- another writer has touched a planned file or a required fix crosses the
  explicit scope.

## Handoff state and completion receipt

Task 02 is complete only when Character is compact, all four real routes are
reachable and presentation-only, each focused screen owns only its locked facts
and actions, town Pack consumes the shared filter surface with town-only
semantics, old duplicate code/tests are gone, and all focused tests/format/static
commands are green. The resulting tree is not accepted until Main runs the
broader gates, integrated review, and normal/greyscale phone evidence in
`../PLAN.md`.

Report to Main in at most eight prose lines:

- the behavioral Red observed for the missing route hub/embedded duplicates;
- the focused test command and pass count;
- the four route/navigation no-mutation proof;
- Gear/Spells/Skills completeness and the exact tested refusal/effect facts;
- town Pack Wear/Read success/refusal and confirmation no Drink/Drop/Cast exists;
- files added/changed/removed and confirmation no forbidden path changed;
- formatter/static commands and results;
- any escalation or residual item for Main’s broad/device gates.
