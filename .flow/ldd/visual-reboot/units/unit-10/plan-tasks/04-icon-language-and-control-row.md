# Task 04 — Icon language, and the crawl control row re-laid-out

Owner: one fresh `flow-plan-executor` on the Unit 10 feature checkout. Read
`../PLAN.md` and `../CONTRACT.md` before editing. Tasks 01-03 have landed and
been accepted; you inherit their repository state, not their sessions.

## Expected starting repository condition

- The `residuum-visual-reboot-10` checkout, branched from `4bf865c`, with tasks
  01, 02 and 03 present and green.
- `packages/app/lib/art/art_assets.dart` exposes
  `ActionIcon { potion, pack, wait, ascend, descend, more, firebolt, mend }`
  with a `path` getter and `static ActionIcon? forSpell(String spellId)`.
- The eight icons exist at 72x72 under `packages/app/assets/visual/icons/` and
  are declared in `pubspec.yaml`.
- `packages/app/lib/game/action_icon.dart` does not exist.
- `packages/app/lib/game/game_screen.dart` is 749 lines. `_Controls` is at
  `:210-358` with its button `Row` at `:265-353`; `_Control` is at `:498-520`;
  `BattleShelf` is at `:575-689` with `_shelfButton` at `:592-613` and `build`'s
  `Wrap` at `:659-687`; `_ShelfButton` is at `:691-709`.
- `test/support/phone.dart` provides `onAPhone` at 411.4 x 923.4 logical pixels.
- Architect-owned `.flow/**` records and the untracked `art/` masters may be
  dirty. Preserve those bytes exactly.

Inspect branch and worktree before editing. Implementation on `main` is
forbidden. If any named seam differs from `../PLAN.md`, stop and report rather
than adapting silently.

Every command below runs from `packages/app`.

## Behavioural slice

Give the crawl's controls and the battle shelf an icon beside their existing
word, and re-lay-out the control row so that at its worst real density every
action word and live count is fully visible at 411.4 dp with no ellipsis —
retiring the inherited `Drink (…)` truncation proved on device at both
`2b0e0a4` and `4bf865c`. The control set, its order, its wording, its gates and
what each control dispatches are frozen.

Files:

- `packages/app/lib/game/action_icon.dart` (new);
- `packages/app/lib/game/game_screen.dart` (`_Controls`' row, `_Control`,
  `_shelfButton`, `_ShelfButton`, three shelf call sites);
- `packages/app/test/widget/crawl_controls_test.dart` (new);
- `packages/app/test/widget/battle_shelf_icons_test.dart` (new).

Do not touch `game_bloc.dart`, any event, `GameScreen.build`, `PopScope`,
`DungeonSceneHost`, `CrawlStatus`, `BattleDock`, `LogPeek`, `LogDrawer`,
`_DeathOverlay`, `_OverflowRow`, `SpellRow`, `doneControl`, `doneAtTheBottom`,
`_confirmCompletion`, `leaveDungeon`, `suspendDungeon`, `leaveEncounter`,
`_onMapTap`, `_onMapLongPress`, `lib/art/**`, `lib/town/**`, `lib/save/**`,
`packages/core`, `packages/content`, or **any existing test file**.

## Locked implementation

`../PLAN.md` section 6 is the recipe, including the density enumeration and the
width arithmetic. Where this brief and the plan differ, the plan wins; where the
plan and `../CONTRACT.md` differ, stop and report.

### 1. `lib/game/action_icon.dart`

```dart
const double actionIconSize = 18;

class ActionIconImage extends StatelessWidget {
  const ActionIconImage(this.icon, {super.key});

  final ActionIcon icon;

  @override
  Widget build(BuildContext context) => Image.asset(
    icon.path,
    width: actionIconSize,
    height: actionIconSize,
    filterQuality: FilterQuality.medium,
  );
}
```

One shared widget because two surfaces need the same 18 dp recipe. Imports
`package:flutter/material.dart` and `../art/art_assets.dart` only.

**Not `ImageIcon`.** `ImageIcon` replaces every pixel with the `IconTheme`
colour and reduces authored multitone art to a silhouette; the contract's own
words presume multitone masters and make greyscale legibility the acceptance
question instead. The planner checked all eight derived icons at 48 px over the
M3 dark `FilledButton` container (`#D0BCFF`) and over the shelf's dark
scaffold, in colour and in greyscale: every one reads by shape alone. If the
device gate finds one that does not, that is an **escalation with the frame
attached**, not a licence to tint the set.

No `color`, no `colorBlendMode`, no `semanticLabel` — the label lives on the
button's `Semantics` wrapper.

### 2. `_Controls`' button row: `Row` -> `Wrap`

Replace the `Row` at `:265-353` with:

```dart
Wrap(
  spacing: 6,
  runSpacing: 4,
  alignment: WrapAlignment.center,
  children: [
    if (state.canPickUp)
      _Control(label: 'Pick up', onPressed: () => bloc.add(const PickUpPressed())),
    if (state.canGather)
      _Control(label: node!.verb, onPressed: () => bloc.add(const GatherPressed())),
    if (potion != null)
      _Control(
        label: 'Drink (${state.potionCount})',
        icon: ActionIcon.potion,
        onPressed: state.game.isGameOver
            ? null
            : () => bloc.add(const QuickDrinkPressed()),
      ),
    _Control(
      label: 'Pack (${state.game.inventory.length})',
      icon: ActionIcon.pack,
      onPressed: () => Navigator.of(context).push(/* unchanged */),
    ),
    if (state.isEncounter && !state.isRoadClear && !state.isBattleOpen)
      _Control(
        label: 'Wait',
        icon: ActionIcon.wait,
        onPressed: () => context.read<GameBloc>().add(const WaitPressed()),
      ),
    if (state.canFlee)
      _Control(label: 'Flee', onPressed: /* unchanged */),
    if (state.isRoadClear)
      _Control(label: 'Move on', onPressed: /* unchanged */),
    if (state.canAscend)
      _Control(
        label: 'Ascend <',
        icon: ActionIcon.ascend,
        onPressed: () => bloc.add(const AscendPressed()),
      ),
    if (state.canDescend)
      _Control(
        label: 'Descend >',
        icon: ActionIcon.descend,
        onPressed: () => bloc.add(const DescendPressed()),
      ),
    if (state.canLeave)
      _Control(label: ending ? doneControl : 'Leave', onPressed: /* unchanged */),
  ],
)
```

Every `Expanded` wrapper is deleted. **Every gate, label expression, order
position and `onPressed` body is carried over verbatim** — including the
`isGameOver` guard on Drink, the `node!.verb` label, the `ending ? doneControl :
'Leave'` label and the pack's `MaterialPageRoute` with its `BlocProvider.value`.
The three conditional sentence rows above the row (`:226-264`) are untouched.

Icon-to-control mapping, exactly five: `Drink (n)` -> `potion`,
`Pack (n)` -> `pack`, `Wait` -> `wait`, `Ascend <` -> `ascend`,
`Descend >` -> `descend`. `Pick up`, `Mine`/`Gather`, `Flee`, `Move on` and
`Leave`/`Finish` stay text-only, with **no reserved icon gap**.

Why `Wrap`, and why it will reach two runs at five controls: at 411.4 dp the
content width is 387.4 dp, and the five-control stairs scene needs about
`58.4 + 96.8 + 89.6 + 89.6 + 51.2 = 385.6` dp of buttons plus 24 dp of spacing,
about 22 dp over. Shrinking the icon to 16 dp and the gap to 4 dp saves 12 dp
and still does not fit. One run is arithmetically impossible at five controls
with icons, which is why the contract permits reflow and why equal-width
`Expanded` cells with silent ellipsis is not acceptable. `WrapAlignment.center`
matches the centred sentence rows already in the same `Column`.

### 3. `_Control`

```dart
class _Control extends StatelessWidget {
  const _Control({required this.label, required this.onPressed, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final ActionIcon? icon;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onPressed != null,
    label: label,
    onTap: onPressed,
    child: ExcludeSemantics(
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          minimumSize: const Size(0, 40),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              ActionIconImage(icon!),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
}
```

Binding details a reviewer will check:

- **`maxLines: 1` and `overflow: TextOverflow.ellipsis` are deleted**, and no
  `Text` in `_Controls` may set `overflow`, `maxLines` or `softWrap` after this
  unit. They are the defect this task exists to retire.
- **`minimumSize: const Size(0, 40)`.** The default `FilledButton` minimum is
  `Size(64, 40)`; removing the width floor is what lets `Mine` and `Finish` take
  their natural width. The height floor stays 40 — today's row height — so one
  run costs no map height.
- **`padding: symmetric(horizontal: 4, vertical: 12)` is unchanged from today**,
  deliberately: every dp of horizontal padding is width the labels need.
- **`_Control`'s own `Padding(horizontal: 3)` is deleted** — the `Wrap`'s
  `spacing: 6` replaces it exactly.
- **`Semantics(button:, enabled:, label:, onTap:) -> ExcludeSemantics`** follows
  `world_route_diagram.dart:233-241`. `onTap` is what keeps the node
  activatable rather than merely described; `enabled` follows `onPressed` so the
  reading matches the behaviour. `_Control` has no label today and needs one
  now that an icon sits inside the button.
- **Disabled reads exactly as it does today**: `onPressed: null`, no word
  change, no icon change, no added sentence, no colour rule of its own.
- `FilledButton.icon` is not used: its internal gap and `.icon`-specific
  padding defaults would silently own two numbers this plan locks.

### 4. The battle shelf — three icons and one lookup

`_ShelfButton` gains `final ActionIcon? icon;` and renders it with the same
`ActionIconImage` + `SizedBox(width: 6)` prefix inside its existing
`TextButton`, before the existing `Text`. `_shelfButton(Spell spell)` does the
same, taking `ActionIcon.forSpell(spell.id)`.

Call sites, in `BattleShelf.build` (`:659-687`):

- `Drink (${state.potionCount})` gains `icon: ActionIcon.potion`;
- `+$overflowCount` (`key: overflowKey`) gains `icon: ActionIcon.more`;
- `Wait` (`key: shelfWaitKey`) gains `icon: ActionIcon.wait`.

`_shelfButton` gains its icon from `forSpell`, which resolves only `firebolt`
and `mend`. `frost-lance`, `ward`, `bind` and `banish` stay text-alone — **no
generic stand-in**.

Untouched: the `Wrap(spacing: 6, runSpacing: 4)` geometry, every label string,
the `'${marking} ${name} ${cost}'` composition, the `' — armed'` suffix, the
armed `side: BorderSide(color: ink)`, `readiedSpellCount`, `_onSpell`,
`_openOverflow`, the overflow sheet's `Spells` title, and `_OverflowRow`.

## Red/Green proof

Establish Red before the production edits. Write both new test files first: the
phone-width tests fail on ellipsised text and the no-squeeze loop under the
current `Row`, and the icon tests fail on `findsNothing` for `Image`
descendants.

### New suite — `packages/app/test/widget/crawl_controls_test.dart`

Stage real blocs and the real `GameScreen`, following
`test/widget/craft_surfaces_test.dart:1-70` and
`test/battle_characterization_test.dart:39-71` for fixtures. `GameState.copyWith`
accepts `hero`, `monsters`, `visible`, `depth`, `groundItems`, `nodes`,
`inventory` but **not `deepest`**, which is carried — use
`copyWith(depth: game.deepest)` for the bottom floor. Do not edit core to make
staging easier. Bodies structured `// arrange` / `// act` / `// assert`.

1. **the worst dungeon density fits a phone un-ellipsised** — `onAPhone`, hero
   standing on `stairsUp` on the bottom floor, one item underfoot, two potions
   carried: `find.text('Pick up')`, `find.text('Drink (2)')`,
   `find.text('Pack (n)')` for the staged `n`, `find.text('Ascend <')` and
   `find.text(doneControl)` each findsOneWidget; `tester.takeException()` is
   null; and the no-squeeze loop below passes.
2. **the worst road density fits a phone un-ellipsised** — `onAPhone`, an
   encounter with the hero on the outermost ring, a live monster not holding
   reach, one item underfoot, two potions carried: `Pick up`, `Drink (2)`,
   `Pack (n)`, `Wait`, `Flee` each findsOneWidget; same exception and
   no-squeeze assertions.
3. **every icon-bearing control carries its icon and its word** — in scene 1 and
   scene 2 between them, each of `Drink (2)`, `Pack (n)`, `Wait`, `Ascend <` has
   exactly one `Image` descendant under its own `FilledButton`, and each of
   `Pick up`, `Flee`, `doneControl` has none. Stage a third scene with the hero
   on `stairsDown` to cover `Descend >`.
4. **an icon-bearing control announces itself** — with `tester.ensureSemantics()`
   active: `find.bySemanticsLabel('Drink (2)')`,
   `find.bySemanticsLabel('Ascend <')` and the staged `Pack (n)` label each
   findsOneWidget.
5. **a disabled control reads as it does today** — a game-over state with a
   potion carried: the `Drink (n)` `FilledButton`'s `onPressed` is null, its
   label text and its `Image` descendant are still present, and no additional
   sentence appears in `_Controls`.
6. **the control set is frozen** — in each of the three staged scenes, the set of
   label strings on `FilledButton`s inside `find.byKey(controlsKey)` equals
   exactly the expected set for that scene. No eleventh control, no renaming, no
   reordering (assert order by ascending `getTopLeft().dy` then `dx`).

**The no-squeeze assertion**, Unit 9's, reused verbatim because it fits: every
`Text` in the new `Wrap` is laid out at its intrinsic width — nothing is
`Expanded`, nothing is `FittedBox`-scaled, nothing sets `overflow` — so a
squeezed or ellipsised paragraph fails the comparison.

```dart
final paragraphs = tester.renderObjectList<RenderParagraph>(
  find.descendant(of: find.byKey(controlsKey), matching: find.byType(Text)),
);
for (final paragraph in paragraphs) {
  expect(
    paragraph.size.width + 0.5,
    greaterThanOrEqualTo(paragraph.getMaxIntrinsicWidth(double.infinity)),
  );
}
```

If `getMaxIntrinsicWidth` proves unusable in the harness, fall back to
exception-plus-exact-text assertions and **report the weakened proof** rather
than silently dropping it.

**Every control-row test runs at `onAPhone`.** The default 800x600 harness
surface is wider than any phone in portrait, which is exactly why the inherited
`Drink (…)` defect shipped twice (`test/support/phone.dart:6-8`). A control-row
assertion at the default surface proves nothing.

### New suite — `packages/app/test/widget/battle_shelf_icons_test.dart`

1. **every icon-bearing shelf action keeps its word** — a hero who knows
   firebolt, frost lance, mend and banish (so `+1` overflow appears) with a
   potion carried, in an open battle: `find.text('Drink (n)')`,
   `find.text('Wait')`, `find.text('+1')`, `find.text('✳ Firebolt 2')` and
   `find.text('✚ Mend 3')` each findsOneWidget; the Drink, Wait, `+1`, Firebolt
   and Mend buttons each have exactly one `Image` descendant; the Frost Lance
   button has none.
2. **arming still reads by border and word** — arm the firebolt: its button's
   text is `'✳ Firebolt 2 — armed'`, its `TextButton.style`'s resolved `side` is
   non-null, and it still carries its icon.
3. **a spell with no asset stays text-only in the overflow too** — open the
   overflow sheet and assert no `Image` appears inside any `_OverflowRow`'s
   trailing button.

Use real blocs and the real `GameScreen`, never a mock. Do not assert source
text, widget counts as a layout proxy, or a field copy. No golden images
(`AGENTS.md`).

### Existing tests: zero changes, all must stay green

The planner swept every suite that observes a touched surface and found no
assertion requiring a verdict change:

- `test/widget/craft_surfaces_test.dart:81-163` —
  `find.widgetWithText(FilledButton, 'Mine' | 'Gather' | 'Pick up')`, one tap,
  and `expect(tester.takeException(), isNull)`. All three controls gain no icon,
  and `find.widgetWithText` and `tester.tap` are widget-tree operations
  unaffected by `Wrap`, `Semantics` or `ExcludeSemantics`. The comment at
  `:157-158` ("neither is ellipsised into nonsense") becomes strictly more true.
- `test/battle_characterization_test.dart:119` — `Pack (0)`.
- `test/battle_view_test.dart` — `Wait`, `✳ Firebolt 2`, `✳ Frost Lance 4`,
  `✚ Mend 3`, and the engaged/watched assertions.
- `test/widget/log_drawer_test.dart:122-124` — `logPeekKey` above `controlsKey`,
  a relative assertion.
- `test/widget/world_screen_test.dart`, `suspend_door_test.dart`,
  `boot_wiring_test.dart`, `crawl_status_test.dart`, `pack_screen_test.dart`,
  `back_guard_test.dart`.

If any of them fails, **the implementation is wrong** — a tap that no longer
lands means the `Semantics`/`ExcludeSemantics` wrapper is misplaced, and a
missing label means a control was renamed. Stop and report; do not adjust the
test.

## Proof commands

From `packages/app`, after Red and after Green:

```sh
flutter test test/widget/crawl_controls_test.dart \
  test/widget/battle_shelf_icons_test.dart \
  test/widget/craft_surfaces_test.dart \
  test/battle_view_test.dart \
  test/battle_characterization_test.dart \
  test/widget/log_drawer_test.dart \
  test/widget/crawl_status_test.dart \
  test/widget/pack_screen_test.dart

dart format --set-exit-if-changed --output=none \
  lib/game/action_icon.dart lib/game/game_screen.dart \
  test/widget/crawl_controls_test.dart \
  test/widget/battle_shelf_icons_test.dart

flutter analyze
flutter test
```

`flutter analyze` and the final full `flutter test` are in scope: you are the
only writer at this point in the sequence, and `game_screen.dart` is observed by
most of the widget suite. Main re-runs the same gate afterwards; that is
acceptance, not duplication. Do not run an app build, an emulator, a device
install, a `git commit`, a `git push`, or any external write.

## Executor discretion

Yours: private helper and test-helper names; the exact fixture staging (seeds,
stair positions, item and node placement, monster placement, `copyWith` shape)
for the three control scenes and the shelf scene; how the three scenes are
factored into helpers; import ordering; whether `ActionIconImage` carries
dartdoc.

Not yours: `Wrap` versus any other geometry, or its `spacing`, `runSpacing` and
`alignment`; `_Control`'s constructor shape; the deletion of `Expanded`,
`maxLines`, `overflow` and the inner `Padding`; `minimumSize: Size(0, 40)`;
`padding: symmetric(horizontal: 4, vertical: 12)`; `actionIconSize = 18` and the
6 dp gap; the choice of `Image.asset` over `ImageIcon`; the five-control icon
mapping and the three shelf icons; `forSpell`'s two matches; the
`Semantics`/`ExcludeSemantics` shape; the requirement that every control-row
test runs at `onAPhone`; any frozen wording (`doneControl`, `doneAtTheBottom`,
`Underfoot:`, `Here:`, `Pick up`, `Mine`, `Gather`, `Flee`, `Move on`, `Leave`,
`Wait`, `Drink (n)`, `Pack (n)`, `Ascend <`, `Descend >`, `— armed`); any
verdict in the "existing tests" section.

## Escalate when

- the row cannot show every action word and live count at 411.4 dp without an
  ellipsis, at any reachable density;
- the reflow costs materially more than one 44 dp button run of map height, or
  reaches three runs at a reachable density;
- a control would have to be added, removed, renamed, reordered, rewired or
  re-gated, or a label or refusal sentence reworded, to make the row fit;
- an icon does not read on its button background in greyscale — report it with
  the frame; **do not tint the set**;
- `Semantics`/`ExcludeSemantics` around the button breaks tapping, or
  `find.widgetWithText(FilledButton, ...)` stops matching;
- `getMaxIntrinsicWidth` or `takeException` cannot express the no-squeeze proof
  — fall back and **report the weakened proof**;
- a readied spell other than firebolt or mend appears to want an icon, or
  `ActionIcon.forSpell` needs a generic fallback;
- an existing test fails for a preserved behaviour rather than an obsolete
  assumption;
- a fix would require `game_bloc.dart`, an event, `packages/core`,
  `packages/content`, a new asset, a `pubspec.yaml` change, a `git commit`, or
  implementation on `main`.

Report; do not redesign the contract.

## Handoff state and completion receipt

The task is complete when: `action_icon.dart` exists with exactly the locked
surface; `_Controls`' row is a `Wrap` with no `Expanded` child; `_Control`
carries an optional icon and a `Semantics` label and sets no `overflow` or
`maxLines`; the five control icons and three shelf icons are in place with
`forSpell` resolving only firebolt and mend; no control was added, removed,
renamed, reordered or rewired; the nine focused tests are green; every existing
suite is green **unchanged**; `flutter analyze` is clean; the full
`flutter test` passes with no suite regressed; formatting is clean on touched
files; and nothing outside the named files changed.

Report to Main in at most eight prose lines:

- branch and base revision, and the Red you observed (name the exact ellipsised
  label the current `Row` produced at `onAPhone`);
- the new file's public surface and `_Control`'s new signature;
- how many runs the `Wrap` takes in each of the three staged scenes at
  `onAPhone`, and the measured height of `controlsKey` in each;
- which of the nine focused tests cover criteria 10, 11 and 12;
- whether the no-squeeze proof landed as planned or fell back;
- explicit confirmation that `craft_surfaces_test.dart`, `battle_view_test.dart`
  and `battle_characterization_test.dart` are byte-unchanged and green;
- the results of the four proof commands;
- anything a device pass must settle (real monospace advance and therefore the
  real run count; icon legibility at 18 dp on the light container; the map
  height the second run costs), and any escalation left open for Main's
  acceptance review.
