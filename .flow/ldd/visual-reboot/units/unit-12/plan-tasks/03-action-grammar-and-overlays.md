# Task 03 — Action Grammar: One Chip Row, Chip States, Crawl Overlays

Owner: one fresh `flow-plan-executor` on the Unit 12 feature checkout.

Read `../CONTRACT.md`, `../recon.md`, `../PLAN.md`, then
`packages/app/lib/game/game_screen.dart`,
`packages/app/lib/game/crawl_style.dart`,
`packages/app/lib/game/crawl_surfaces.dart`,
`packages/app/lib/game/action_icon.dart`,
`packages/app/lib/game/spell_row.dart`,
`packages/app/lib/game/battle_view.dart` (`showEnemyInfo` and
`_EnemyInfoLine` only), `packages/app/lib/game/game_bloc.dart` view getters,
and these tests: `test/widget/crawl_controls_test.dart`,
`test/widget/battle_shelf_icons_test.dart`,
`test/widget/craft_surfaces_test.dart`, `test/widget/suspend_door_test.dart`,
`test/battle_view_test.dart`. Look at frames 2–4 of
`.flow/evidence/visual-reboot/residuum_visual_reboot_approved_mock.png`.

All commands run from `packages/app`.

## Starting condition

- the Unit 12 feature checkout with Tasks 01 and 02 accepted;
- `crawl_style.dart` holds Task 01's and Task 02's membership; the chip type,
  the chip-state table and the overlay colours are **absent**;
- `crawl_surfaces.dart` holds `CrawlPill`, `CrawlPanel` and
  `CrawlRegionLabel`; `showCrawlSheet` and `showCrawlConfirm` are **absent**;
- `GameScreen`'s `Column` is `CrawlStatus → BattleDock → Expanded map →
  LogPeek → BattleShelf → _Controls`, and its `Scaffold` is wrapped in
  `Theme(data: crawlTheme, …)`;
- `game_screen.dart` still declares `shelfKey`, `overflowKey`, `shelfWaitKey`,
  `controlsKey`, `_Controls`, `_Control`, `BattleShelf`, `_ShelfButton`,
  `_OverflowRow`, `_DeathOverlay`, `_confirmCompletion`, `doneControl`,
  `doneAtTheBottom`;
- `format`, `analyze` and the full `packages/app` suite were green at Task 02's
  handoff.

Inspect branch, HEAD and worktree before editing. If any of the above is false,
stop and report rather than adapting.

## Behavioral slice

The crawl shows **one** action row in every scene. Exploration controls and the
combat shelf become one chip vocabulary — icon above word, even widths, rounded
surface, hairline border — where available, disabled and armed are
distinguishable without reading colour, every verb that applies is visible
exactly once, and every visibility rule, availability rule and dispatched
action is unchanged. No crawl-reachable surface renders as stock Material.

## Owned files

- `packages/app/lib/game/crawl_style.dart` — append this task's members;
- `packages/app/lib/game/crawl_surfaces.dart` — append `showCrawlSheet` and
  `showCrawlConfirm`;
- new `packages/app/lib/game/crawl_action_row.dart`;
- `packages/app/lib/game/game_screen.dart`;
- `packages/app/lib/game/battle_view.dart` — `showEnemyInfo` and
  `_EnemyInfoLine` only;
- `packages/app/test/widget/crawl_controls_test.dart`;
- `packages/app/test/widget/battle_shelf_icons_test.dart`;
- `packages/app/test/widget/craft_surfaces_test.dart`;
- `packages/app/test/widget/log_drawer_test.dart` — the `controlsKey` →
  `actionRowKey` rename only;
- `packages/app/test/widget/crawl_layout_test.dart` — the `controlsKey` →
  `actionRowKey` rename, and dropping the temporary-shelf slot from its order
  assertion, only;
- `packages/app/test/battle_view_test.dart` — the `BattleShelf` sites only;
- new `packages/app/test/widget/crawl_action_row_test.dart`;
- new `packages/app/test/widget/crawl_surfaces_test.dart`.

Do not touch `crawl_status.dart`, `log_drawer.dart`, `action_icon.dart`,
`spell_row.dart`, `activation_timeline.dart`, `log_line.dart`,
`game_bloc.dart`, `pack_screen.dart`, `main.dart`, `town_style.dart`, Unit 11's
renderer, `packages/core` or `packages/content`.

## Locked decisions

### Appended to `crawl_style.dart`

```dart
const Color crawlArmedFill = Color(0xFF262B35);
const Color crawlDisabledRule = Color(0xFF1E222A);
const Color crawlScrim = Color(0xCC0E1014);

const TextStyle crawlChipLabel = TextStyle(
  fontFamily: 'monospace',
  fontSize: 12,
  fontWeight: FontWeight.w500,
  color: crawlInk,
);
const TextStyle crawlChipLabelDisabled = TextStyle(
  fontFamily: 'monospace',
  fontSize: 12,
  fontWeight: FontWeight.w400,
  color: crawlDim,
);
const TextStyle crawlChipLabelArmed = TextStyle(
  fontFamily: 'monospace',
  fontSize: 12,
  fontWeight: FontWeight.w600,
  color: crawlInk,
);
const TextStyle crawlCaption = TextStyle(
  fontFamily: 'monospace',
  fontSize: 11,
  fontWeight: FontWeight.w600,
  color: crawlInk,
);
const TextStyle crawlDetail = TextStyle(
  fontFamily: 'monospace',
  fontSize: 11,
  color: crawlDim,
);
const TextStyle crawlHeadline = TextStyle(
  fontFamily: 'monospace',
  fontSize: 28,
  color: crawlInk,
);

const double crawlChipSpacing = 6;
const double crawlChipRunSpacing = 4;
const double crawlChipPadding = 8;
const double crawlChipVerticalPadding = 6;
const double crawlChipLabelLineHeight = 15;
const int crawlChipMaxColumns = 5;
const int crawlChipMaxLabelLines = 2;
const double crawlDisabledIconOpacity = 0.45;

enum CrawlChipState { available, disabled, armed }

class CrawlChipSkin {
  const CrawlChipSkin({
    required this.fill,
    required this.border,
    required this.borderWidth,
    required this.label,
    required this.iconOpacity,
  });

  final Color fill;
  final Color border;
  final double borderWidth;
  final TextStyle label;
  final double iconOpacity;
}

CrawlChipSkin crawlChipSkin(CrawlChipState state);
```

`crawlChipSkin`'s table is binding:

| state | fill | border | borderWidth | label | iconOpacity |
|---|---|---|---:|---|---:|
| `available` | `crawlRaised` | `crawlRule` | `crawlHairline` | `crawlChipLabel` | 1.0 |
| `disabled` | `crawlRecessed` | `crawlDisabledRule` | `crawlHairline` | `crawlChipLabelDisabled` | `crawlDisabledIconOpacity` |
| `armed` | `crawlArmedFill` | `crawlInk` | `crawlHairline * 2` | `crawlChipLabelArmed` | 1.0 |

Also complete `crawlTheme`'s two fields Task 01 deliberately left open:
`bottomSheetTheme.modalBarrierColor: crawlScrim`,
`dialogTheme.titleTextStyle: crawlPanelTitle` and
`dialogTheme.contentTextStyle: crawlLine`.

### `crawl_action_row.dart`

```dart
class CrawlAction {
  const CrawlAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.armable = false,
    this.armed = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final ActionIcon? icon;
  final bool armable;
  final bool armed;
}

class CrawlActionRow extends StatelessWidget {
  const CrawlActionRow({
    required this.notes,
    required this.actions,
    super.key,
  });

  final List<String> notes;
  final List<CrawlAction> actions;
}

const actionRowKey = Key('crawl-action-row');
const int readiedSpellCount = 3;
```

`CrawlActionRow` owns pixels only. It renders `notes` as `crawlBodyDim` rows,
each with `EdgeInsets.only(bottom: crawlRhythm)`, then the chips, inside
`Padding(horizontal: crawlGutter, vertical: crawlRhythm)`.

It asserts its own invariant in debug:

```dart
assert(
  actions.map((action) => action.label).toSet().length == actions.length,
  'a verb must appear once',
);
```

That assert is the structural guard behind AC3.

**Chip keys.** Each chip is keyed `ValueKey(action.label)`. That is the row's
only test handle, and the assert above guarantees uniqueness. `shelfKey`,
`shelfWaitKey`, `overflowKey` and `controlsKey` are deleted from
`game_screen.dart`; `actionRowKey` replaces `controlsKey`.

**Chip state** is `action.armed ? CrawlChipState.armed : action.onPressed ==
null ? CrawlChipState.disabled : CrawlChipState.available`.

**Chip anatomy.** `SizedBox(width: chipWidth, height: chipHeight)` holding
`Material(color: skin.fill, shape: RoundedRectangleBorder(side:
BorderSide(color: skin.border, width: skin.borderWidth), borderRadius:
BorderRadius.circular(crawlRadius)))` → `InkWell(onTap: action.onPressed,
borderRadius: …)` → a centred `Column`:

1. the icon slot, always `actionIconSize` tall: `ActionIconImage(icon)` when
   the action has one, otherwise `SizedBox(height: actionIconSize)` so every
   word in the row sits on one baseline. A disabled chip wraps it in
   `Opacity(opacity: skin.iconOpacity)` — alpha, never a colour filter, so the
   multitone master is not flattened and the `Image` stays in the tree;
2. `SizedBox(height: crawlRhythm)`;
3. `Text(action.label, textAlign: TextAlign.center, maxLines:
   crawlChipMaxLabelLines, style: skin.label)`;
4. the armed line: `Text('— armed', style: crawlCaption)` on the armed chip,
   and reserved empty space of `crawlChipLabelLineHeight` on **every** chip in
   a row where `actions.any((action) => action.armable)`.

`ActionIconImage` and `actionIconSize` are consumed unchanged: still
`Image.asset`, still `excludeFromSemantics: true`, never `ImageIcon`, never
tinted. `action_icon.dart` is not edited.

Each chip is wrapped in `Semantics(button: true, enabled: action.onPressed !=
null, label: action.label, onTap: action.onPressed)` + `ExcludeSemantics`,
exactly as `_Control` does today at `game_screen.dart:496-501`.

**The fit maths.** The chips sit in a `LayoutBuilder`; one column count is
chosen for the whole row:

```dart
for (var columns = crawlChipMaxColumns; columns >= 1; columns--) {
  final width = (available - crawlChipSpacing * (columns - 1)) / columns;
  final content = width - crawlChipPadding * 2;
  if (content <= 0) continue;
  final lines = <int>[for (final a in actions) _labelLines(a.label, content)]
      .reduce(math.max);
  if (lines >= 1 && lines <= crawlChipMaxLabelLines) {
    return (columns, width, lines);
  }
}
// degenerate guard: one column at the full available width
```

`_labelLines(label, content)` lays a `TextPainter` out over `crawlChipLabel`
with `textAlign: TextAlign.center`, `textDirection: TextDirection.ltr` and
`layout(maxWidth: content)`, then returns
`painter.width <= content + 0.5 ? painter.computeLineMetrics().length :
crawlChipMaxLabelLines + 1` — a column count that would break an unbreakable
word is rejected rather than clipped. Dispose every painter. The measurement
runs once per row build over at most a dozen short strings; the chips
themselves allocate no painters.

All chips then take that one `width` and that one `lines`, laid out in
`Wrap(spacing: crawlChipSpacing, runSpacing: crawlChipRunSpacing, alignment:
WrapAlignment.center)` of fixed-width children — even widths, even heights.

```text
chipHeight = crawlChipVerticalPadding * 2
           + actionIconSize
           + crawlRhythm
           + lines * crawlChipLabelLineHeight
           + (anyArmable ? crawlChipLabelLineHeight : 0)
```

**The row never scrolls.** It grows and the `Expanded` map pays. Do not add a
`ListView`, a `SingleChildScrollView` or an overflow menu:
`battle_view_test.dart:307,558` assert the crawl holds exactly one `ListView`,
and it is `LogPeek`'s.

**Why the armed word is its own line, not an inline suffix.** Appending
` — armed` to `✳ Firebolt 2` takes the label from 12 to 20 characters, drops the
row's column count, and reflows the action row — and therefore the `Expanded`
map and the Flame viewport — under the player's thumb at the moment they arm.
The reserved caption line keeps arming reflow-free while keeping the border and
the word. The reserve is row-scoped, so exploration rows pay nothing for a
state they cannot enter. Do not "simplify" this by inlining the suffix.

### The merged row in `game_screen.dart`

Delete `_Controls`, `_Control`, `BattleShelf` and `_ShelfButton`. Keep
`_OverflowRow`, `_DeathOverlay`, `_confirmCompletion`, `leaveDungeon`,
`suspendDungeon`, `leaveEncounter`, `doneControl`, `doneAtTheBottom`,
`recenterKey` and `_onSpell`'s logic — five test files import
`game_screen.dart` for those names and none of them moves.

`BattleShelf.readiedSpellCount` moves to `crawl_action_row.dart` as
`readiedSpellCount`.

The `Column`'s last two slots collapse to one:

```text
CrawlActionRow(key: actionRowKey, notes: <notes>, actions: <actions>)
```

`actions` is built in this exact order:

| # | label | guard | onPressed | icon | armable/armed |
|---:|---|---|---|---|---|
| 1 | `Drink (${state.potionCount})` | `isBattleOpen && firstPotion != null` | `QuickDrinkPressed`, `null` when `isGameOver` | `potion` | — |
| 2–4 | `'${spell.school.schoolMarking} ${spell.name} ${spell.manaCost}'` | `isBattleOpen`, `state.knownSpells.take(readiedSpellCount)` | `CastPressed` for `mend`/`ward`, else `SkillArmed(armedSpellId == id ? null : id)` | `ActionIcon.forSpell(spell.id)` | `armable: true`, `armed: armedSpellId == spell.id` |
| 5 | `'+$overflowCount'` | `isBattleOpen && knownSpells.length > readiedSpellCount` | opens the overflow sheet | `more` | — |
| 6 | `'Wait'` | `isBattleOpen` | `WaitPressed` | `wait` | — |
| 7 | `'Pick up'` | `state.canPickUp` | `PickUpPressed` | — | — |
| 8 | `node!.verb` | `state.canGather` | `GatherPressed` | — | — |
| 9 | `Drink (${state.potionCount})` | `!isBattleOpen && firstPotion != null` | `QuickDrinkPressed`, `null` when `isGameOver` | `potion` | — |
| 10 | `Pack (${state.game.inventory.length})` | always | pushes `CrawlPackScreen` | `pack` | — |
| 11 | `'Wait'` | `state.isEncounter && !state.isRoadClear && !state.isBattleOpen` | `WaitPressed` | `wait` | — |
| 12 | `'Flee'` | `state.canFlee` | `FleePressed` | — | — |
| 13 | `'Move on'` | `state.isRoadClear` | `leaveEncounter(cleared)` | — | — |
| 14 | `'Ascend <'` | `state.canAscend` | `AscendPressed` | `ascend` | — |
| 15 | `'Descend >'` | `state.canDescend` | `DescendPressed` | `descend` | — |
| 16 | `ending ? doneControl : 'Leave'` | `state.canLeave` | `ending ? _confirmCompletion : suspendDungeon` | — | — |

**Rows 9 and 11 are the merge's whole mechanism.** Row 9 adds
`&& !state.isBattleOpen` to today's Drink guard — the exact gate row 11 already
carries at `game_screen.dart:302-304`. Rows 1/9 and 6/11 are therefore mutually
exclusive, so Drink and Wait each render exactly once, from exactly one guard.

Note this source fact, which refines `recon.md`: only Drink is duplicated
today. The control-row Wait is already hidden while a battle is open, and
`battle_view_test.dart:627` asserts exactly one `Wait` in an open battle. Do
not "fix" a Wait duplication that does not exist by removing a guard.

Everything else about the sixteen rows is frozen: every guard is the guard that
file uses today, Pack stays the always-on exception, disabled Drink stays
visible and inert, every dispatched event is the same event, and **no label is
renamed, shortened, lengthened or hidden.** The mock's shorter chip words
(`Potion`, `Firebolt`) are illustration, not instruction. Readied spell order
stays `state.knownSpells.take(readiedSpellCount)`; the mock's
Mend-before-Firebolt order is illustrative and school-then-name order is kept.

`notes` is the same three conditional sentences in the same order under the
same conditions: `doneAtTheBottom` when `state.canLeave &&
state.isAtTheBottom`, `'Underfoot: ${node.marking} ${node.word}'` when
`state.nodeUnderfoot != null`, and the one-or-many `Here:` sentence when
`state.itemsUnderfoot.isNotEmpty`. They keep wrapping onto a second line.

### The overlays

Append to `crawl_surfaces.dart`:

```dart
Future<T?> showCrawlSheet<T>(
  BuildContext context, {
  required List<Widget> Function(BuildContext) children,
});

Future<bool> showCrawlConfirm(
  BuildContext context, {
  required String title,
  required String body,
  required String dismiss,
  required String confirm,
});
```

`showCrawlSheet` is implemented with `showModalBottomSheet` — **not** a custom
route, because `battle_view_test.dart:457` asserts
`find.byType(BottomSheet)`. Its builder returns
`Theme(data: crawlTheme, child: SafeArea(child: CrawlPanel(padding:
EdgeInsets.all(crawlGutter + crawlRhythm), child:
SingleChildScrollView(child: Column(mainAxisSize: min, crossAxisAlignment:
start, children: children(sheetContext))))))`, with a top-rounded shape. The
explicit `Theme` wrap is deliberate: it removes any dependence on Flutter's
`InheritedTheme` capture for root-navigator routes, so the sheet's appearance
is correct by construction.

`showCrawlConfirm` uses `showDialog<bool>` with `barrierColor: crawlScrim` and
a builder returning `Theme(data: crawlTheme, child: Dialog(…))`: `crawlPanel`
surface, `crawlRadius` corners with a `crawlRule` hairline side, `title` in
`crawlPanelTitle`, `body` in `crawlLine`, and two `CrawlPill`s — `dismiss`
popping `false`, `confirm` popping `true`. It returns `false` when dismissed.

Apply them:

| surface | change |
|---|---|
| spells overflow (`game_screen.dart:630-667`) | `showCrawlSheet`; heading `'Spells'` in `crawlPanelTitle`; one `_OverflowRow` per `state.knownSpells`, unchanged; the sheet still pops before `_onSpell` |
| `_OverflowRow` | `SpellRow` styles become `crawlLine` and `crawlDetail`; its trailing action keeps `Key('overflow-${spell.id}')`, keeps `armed ? '— armed' : spell.school.schoolMarking`, and takes the armed chip skin's border weight and colour. `spell_row.dart` is not edited |
| enemy info (`battle_view.dart:138-195`) | `showCrawlSheet`; glyph in `crawlGlyph`, name and `_EnemyInfoLine`s in `crawlLine`; every string unchanged |
| completion confirm (`game_screen.dart:424-461`) | `showCrawlConfirm(title: 'The delve is done. Leave with your spoils?', body: <the existing sentence, verbatim>, dismiss: 'Stay down here', confirm: 'Leave with them')`; the `!(done ?? false) || !context.mounted` guard and `leaveDungeon(died: false)` are unchanged |
| `_DeathOverlay` | `ColoredBox(color: crawlScrim)`; `'You died.'` in `crawlHeadline`; the second sentence in `crawlBodyDim`; the button becomes `CrawlPill` with the same `state.isEncounter ? 'Wake at home' : 'Return to town'` label and the same dispatch |

Every player-facing string is unchanged. `suspend_door_test.dart` taps
`find.text(doneControl)`, `'Stay down here'` and `'Leave with them'`;
`world_screen_test.dart:1261` taps `'Wake at home'`;
`log_drawer_test.dart:464` taps `'Return to town'`.

## Red proof

Write the test changes first.

### Rewrites

**`test/widget/crawl_controls_test.dart`.** Replace `_button`,
`_expectIcon`, `_expectNoIcon` and `_controlOrder`'s finder with a chip finder:

```dart
Finder _chip(String label) => find.byKey(ValueKey(label));
```

`_controlOrder` reads each chip's label `Text` and sorts by `getTopLeft` dy
then dx as it does today. `_expectNoSqueeze` becomes a **no-clip** proof over
every chip label `RenderParagraph` under `actionRowKey`:

```dart
expect(paragraph.didExceedMaxLines, isFalse);
expect(
  paragraph.size.width + 0.5,
  greaterThanOrEqualTo(paragraph.getMinIntrinsicWidth(double.infinity)),
);
```

`getMinIntrinsicWidth` is the widest unbreakable word, which is what "no label
ellipsises" means once labels may wrap onto two lines. If `didExceedMaxLines`
proves awkward to reach, assert instead that the paragraph's height
accommodates its line count at `crawlChipLabelLineHeight`; either form proves
the same thing. Keep the loop scoped to the chips, not the note rows — the
notes wrap by design.

Keep verbatim: all three frozen set-and-order scenes and their expected lists,
the `find.text` assertions for every label, the semantic-label assertions, and
the disabled-Drink case (word present, `Image` present, tap null, no note rows).
Read the disabled tap through the chip's `InkWell` or its `Semantics`
`enabled`, not through `FilledButton`.

**`test/widget/battle_shelf_icons_test.dart`.** `_shelfText` and `_shelfButton`
scope to `actionRowKey`; `Key('shelf-spell-<id>')` becomes
`ValueKey('<label>')`; `find.byKey(overflowKey)` becomes
`find.byKey(const ValueKey('+1'))`. Rewrite the armed assertion at `:152-162`:
the armed chip still shows `'✳ Firebolt 2'`, **additionally** shows the word
`'— armed'`, still carries its `Image`, and has a heavier border than an
unarmed sibling chip — border and word, never a widget type and never a hex.
Keep the icon-presence loop and the frost-lance text-only assertion.

**`test/widget/craft_surfaces_test.dart`.** The eight
`find.widgetWithText(FilledButton, …)` sites become `find.byKey(ValueKey(…))`.
Every behaviour is unchanged: Mine only over a vein, Gather only over a patch,
neither offered elsewhere on the floor, working it takes the control away and
the material up, Mine and Pick up share the row.

**`test/battle_view_test.dart`.** `find.byType(BattleShelf)` at `:305` and
`:556` becomes the observable it defends: at `:305`, once the fight ends the
readied spell chip and the `Wait` chip are gone; at `:556`, the `Wait` chip is
present while it runs. Leave `find.text('✳ Firebolt 2')` at `:289,584,612,641`
and `find.text('Wait'), findsOneWidget` at `:627` exactly as they are — the
last is now an AC3 guard.

**`test/widget/log_drawer_test.dart:123`.** `controlsKey` → `actionRowKey`.

**`test/widget/crawl_layout_test.dart`.** `controlsKey` → `actionRowKey`, and
the combat order assertion drops the temporary shelf slot: the column is now
status → timeline → map → peek → action row, with nothing between the peek and
the row. Keep the full-bleed map-width and extent-cycle assertions verbatim.

### New `test/widget/crawl_action_row_test.dart`

At phone size via `onAPhone`:

1. **AC3** — in an open battle with a potion carried and spells known,
   `find.text('Drink (${count})')` finds exactly one widget and
   `find.text('Wait')` finds exactly one; `find.byKey(actionRowKey)` finds one;
   `find.byKey(const Key('battle-shelf'))` finds nothing;
2. **AC4** — in one row, every chip's rect has the same width and the same
   height; for every icon-bearing chip, the `Image`'s rect top is above its
   label `Text`'s rect top;
3. **AC5, property** — `crawlChipSkin(disabled).fill.computeLuminance() <
   crawlChipSkin(available).fill.computeLuminance() <
   crawlChipSkin(armed).fill.computeLuminance()`; the armed border width is
   greater than the available border width and its colour differs; the disabled
   label colour's luminance is below the available label colour's; the armed
   label's `fontWeight` is heavier than the available label's;
4. **AC5, rendered** — arming a spell chip adds the word `'— armed'` to that
   chip, gives it a heavier rendered border than an unarmed sibling, and
   **leaves `getRect(dungeonSceneSlotKey)` unchanged**;
5. **AC14, testable half** — chrome height (surface height minus the map slot's
   height) is at most 360 dp in an exploration scene at typical density
   (`Pick up`, `Drink (2)`, `Pack (2)`, `Ascend <`, `Finish`) and at most
   560 dp in the densest legal battle scene: a stairs-up landing with a gather
   node and items underfoot, two potions carried, four known spells and one
   adjacent monster holding reach. In both scenes, no chip label paragraph
   exceeds `crawlChipMaxLabelLines` and none is clipped;
6. **AC9** — in a game-over scene the Drink chip is still present, still shows
   its word and its `Image`, and is inert.

Chrome height, not map height, because the widget-test surface has no system
insets and `Medium_Phone` has about 79 dp of them; chrome is the same number on
both.

### New `test/widget/crawl_surfaces_test.dart`

7. **AC11** — open the spells overflow sheet, the enemy info sheet and the
   completion confirm in turn, and assert each renders its surface on
   `crawlPanel`, read from the rendered `Material`'s colour inside the
   `BottomSheet` / `Dialog`, and **not** on the surface a bare
   `ThemeData(brightness: Brightness.dark, useMaterial3: true)` would supply.
   Assert the death overlay renders on `crawlScrim`. Compare against the seam's
   named constants, never a hex literal;
8. **AC12** — push the crawl pack route from the crawl and assert the pack
   screen still renders on the town's `panel`/`ink`, proving the scoped theme
   does not escape the crawl subtree.

Run:

```text
flutter test test/widget/crawl_action_row_test.dart test/widget/crawl_surfaces_test.dart test/widget/crawl_controls_test.dart test/widget/battle_shelf_icons_test.dart test/widget/craft_surfaces_test.dart test/battle_view_test.dart test/widget/log_drawer_test.dart test/widget/suspend_door_test.dart
```

Expected Red: AC3's single-Drink assertion fails because both rows render one
today; the even-width, icon-above-word, armed-caption and chip-state
assertions fail because no chip exists; AC11 fails on the Material-3 default
sheet and dialog surfaces; the chrome-height assertions fail or pass by
accident and must be re-observed after the merge. The frozen set and order,
the label texts, the semantic labels, the disabled-Drink case, AC12 and
`suspend_door_test` pass before and after — they are the regression that
proves the merge changed no rule.

Also green at handoff:

```text
flutter test test/widget/crawl_layout_test.dart test/widget/crawl_status_test.dart test/battle_characterization_test.dart test/battle_flow_characterization_test.dart test/widget/back_guard_test.dart test/widget/door_reentry_test.dart test/widget/world_screen_test.dart test/widget/pack_screen_test.dart test/widget/boot_wiring_test.dart
```

## Green proof, closing audit and package gates

Implement only this slice, rerun the focused commands until green, then run the
AC1 style-leak audit from `packages/app` and record its output:

```text
grep -n "TextStyle(" lib/game/game_screen.dart lib/game/crawl_status.dart lib/game/battle_view.dart lib/game/log_drawer.dart lib/game/crawl_action_row.dart lib/game/crawl_surfaces.dart lib/game/action_icon.dart lib/game/spell_row.dart
grep -n "Color(0x" lib/game/game_screen.dart lib/game/crawl_status.dart lib/game/battle_view.dart lib/game/log_drawer.dart lib/game/crawl_action_row.dart lib/game/crawl_surfaces.dart lib/game/action_icon.dart lib/game/spell_row.dart
grep -rn "town_style" lib/game/
grep -rn "crawl_style\|crawl_surfaces\|crawl_action_row" lib/ --include=*.dart
```

Expected: the first two return nothing; the third returns only
`pack_screen.dart`; the fourth returns only files under `lib/game/`.
`dungeon_palette.dart`, `dungeon_scene.dart`, `dungeon_scene_material.dart` and
`glyph_plan.dart` are Unit 11's renderer and are excluded from the first two
lists by design.

Then:

```text
dart format --set-exit-if-changed --output=none lib test
flutter analyze
flutter test
```

Record the Red failures, the audit output and every Green exit status. Run no
device gate in this task; the device pass is the controller's.

## Executor discretion

- private widget, record and helper names inside `crawl_action_row.dart`;
- whether the fit maths returns a record, a small private value type or three
  locals;
- the chip's inner `Column` alignment details and the exact `InkWell`
  `borderRadius` inset;
- `showCrawlSheet`'s exact padding inside `crawlGutter`–`crawlGutter + 8`;
- the confirm dialog's action-row spacing and whether its pills sit in a `Row`
  or a `Wrap`;
- fixture staging in the new tests, and whether they share helpers with
  existing files;
- constants-only tuning inside the plan's envelopes if a cap is breached by a
  small margin: `crawlChipVerticalPadding` 4–8,
  `crawlChipLabelLineHeight` 14–16, `crawlCaption` size 10–12,
  `crawlChipMaxColumns` 4–6.

Not discretionary: the seam's member names and values, the chip-state table,
the sixteen-row order and its guards, any label string, any key, any dispatched
event, the `ValueKey(label)` chip-key rule, the row-scoped armed reserve, the
`— armed` word on its own line, the absence of scrolling in the action row, the
absence of a second `ListView`, or `ActionIconImage`'s untinted `Image.asset`.

## Escalate when

- repository reality contradicts the starting condition;
- the measured chrome height exceeds a cap by more than the tuning envelopes
  can close, or the map falls below about 280 dp on a `Medium_Phone`-equivalent
  surface at worst density;
- even-width chips cannot fit the longest real label without ellipsis at
  any column count — including one — so a label would have to be shortened;
- the merge cannot preserve a guard, a dispatch, a label, a key or a semantic
  label exactly;
- the armed state cannot read in greyscale through fill, border, weight and
  word, or arming still reflows the map;
- a sheet or dialog cannot take the crawl surface without a custom route, or
  the scoped theme reaches the pack screen;
- an existing test can be kept green only by re-pinning a literal, a widget
  type, or by weakening the frozen control set and order;
- meeting the slice would require editing `game_bloc.dart`,
  `action_icon.dart`, `spell_row.dart`, `pack_screen.dart`, `main.dart`,
  `town_style.dart`, the renderer, `packages/core` or `packages/content`;
- following a locked decision here would knowingly ship a defect.

## Completion receipt

Return one compact receipt containing:

- `STATUS: COMPLETE` or `BLOCKED`;
- starting and resulting revision plus dirty-state summary;
- changed, added and deleted paths, and the deleted symbols
  (`_Controls`, `_Control`, `BattleShelf`, `_ShelfButton`, `shelfKey`,
  `shelfWaitKey`, `overflowKey`, `controlsKey`);
- the Red command and the behavioural failures observed;
- focused Green command plus format, analyze and full-suite results;
- the verbatim output of the four audit greps;
- **measured** at phone size: the chip column count and chip height in
  exploration and in combat, the chip count in the densest battle scene, and
  the chrome height and map slot height for exploration typical, exploration
  worst-notes, combat typical and combat worst;
- confirmation that: exactly one action row renders in every scene, Drink and
  Wait each render once, the frozen control set and order is unchanged for all
  three exploration scenes, arming does not change the map slot rect, no chip
  label exceeds two lines or is clipped, every overlay renders on the crawl's
  surface, the pack screen is unchanged, and `main.dart` and `town_style.dart`
  are untouched;
- residual findings and the exact next action: the controller's integrated
  gates, scope audit, acceptance review and then the `Medium_Phone` device
  pass.
