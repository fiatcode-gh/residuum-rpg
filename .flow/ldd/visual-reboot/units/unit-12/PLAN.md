# Unit 12 — Crawl Interface Visual Grammar: Execution Plan

Status: **execution-grade; planning only.** The Unit 12 contract is approved,
but the user must separately approve this plan before production execution.

Source base: `main` at `60909e60ec3150cf9b590e6641a8ae51efca775c`.

Planning dirty-state assumption, recorded 2026-09-17: production source is at
that revision; the only working-tree change is the untracked architect-owned
`.flow/ldd/visual-reboot/units/unit-12/` bundle, which is user-owned and must
be preserved. The base revision is taken from the architect's brief; this
planner performed no git operation (excluded by its assignment) and verified
every named seam by reading the current files instead. A revision change
requires targeted revalidation of the seams named below, not replanning.

Derived from the approved `CONTRACT.md`, architect-verified `recon.md`, frames
2–5 of `.flow/evidence/visual-reboot/residuum_visual_reboot_approved_mock.png`,
and first-hand reads of `game_screen.dart`, `crawl_status.dart`,
`battle_view.dart`, `log_drawer.dart`, `action_icon.dart`, `spell_row.dart`,
`activation_timeline.dart`, `log_line.dart`, `town_style.dart`, `main.dart`,
`game_bloc.dart` view getters, `art_assets.dart`, `content/src/spells.dart`,
and every crawl test file that pins crawl presentation.

## Findings the architect must read before approving

Three source facts refine `recon.md`. None changes an acceptance criterion;
none is a contract contradiction. No part of this plan works around them.

1. **Only `Drink` is duplicated in combat, not `Drink` and `Wait`.** The
   contract's rationale (inherited locks, §D) and `recon.md:28-30` say combat
   shows Drink and Wait on both rows. `_Controls`' Wait is gated
   `state.isEncounter && !state.isRoadClear && !state.isBattleOpen`
   (`game_screen.dart:302-304`), so it is hidden while a battle is open, and
   `battle_view_test.dart:627` already asserts exactly one `Wait` in an open
   battle. AC3 stands and is still violated today — by Drink. The merge keeps
   both verbs single-sourced (Task 03, "one guard per verb").
2. **Three more presentation-pinning test sites exist beyond the recon's three
   families**, and AC3/AC6 force all three to change:
   - `battle_view_test.dart:338-357` pins the exact `Text` inventory under
     `Key('dock-backing')` as `['@ YOU','›','g¹','›','g¹','›','g²','›','@ YOU']`.
     AC6's `NOW`/`NEXT` captions and actor words necessarily change it.
   - `battle_view_test.dart:305,556` pin `find.byType(BattleShelf)`. AC3's one
     row removes that type.
   - `craft_surfaces_test.dart:82,83,95,107,132,136,159,160` pin
     `find.widgetWithText(FilledButton, …)` on the crawl's Mine/Gather/Pick up
     controls. A chip redesign changes that widget type.
   All three are rewritten to the behaviour they defend under the contract's
   verification disposition, never re-pinned to new literals or new types.
3. **A latent lock:** `battle_view_test.dart:307,558` assert
   `find.byType(ListView), findsOneWidget` across the whole crawl. `LogPeek`
   owns that one `ListView`. The timeline must stay a
   `SingleChildScrollView` + `Row`, and the action row a `Wrap`; the crawl
   column may gain no second `ListView`.

## Freshness, authority and checkout

Before Task 01:

1. inspect branch, HEAD and worktree without discarding or stashing user work;
2. confirm production ancestry includes
   `60909e60ec3150cf9b590e6641a8ae51efca775c`;
3. confirm the approved contract, this approved plan and canonical LDD status
   are present;
4. use one suitable non-isolated Unit 12 feature checkout for all three tasks;
5. never implement directly on `main`.

`packages/app` is the only package that changes. There is no root pubspec:
every command runs from `packages/app`.

If a named seam materially differs from this plan, return to the architect.
Executors may not silently adapt an interface, ownership boundary or behaviour.

## Strict execution graph

```text
01 crawl style seam, scoped theme, mock column order, map framing
  -> accepted Task 01 repository state + receipt
02 information hierarchy: timeline panel, log peek and drawer
  -> accepted Task 02 repository state + receipt
03 action grammar: one chip row, chip states, crawl overlays
  -> accepted Task 03 repository state + receipt
integrated format/analyze/full app tests + style-leak and scope audit
  -> integrated COR/TTC/CRF acceptance review + corrections
  -> rerun evidence stale from any correction
Medium_Phone save backup -> install -> evidence capsules
  -> at most one bounded constants-only tuning pass
  -> affected proof + scoped acceptance rerun -> recapture
restore both save slots byte-identically
  -> user acceptance / integration decision
```

Strictly sequential, three fresh `flow-plan-executor` sessions on the same
non-isolated checkout. They are **not** parallelisable: Tasks 02 and 03 both
append to `crawl_style.dart` and both touch `battle_view.dart` (Task 02 the
timeline, Task 03 the enemy sheet), and Task 03's chip row consumes Task 01's
seam and the vertical budget Task 02 has already spent. Repository state and
accepted receipts carry forward; executor conversation does not.

This preserves the external strategy's dependency shape — visual
foundation/shell, then information hierarchy, then action grammar and
overlays — with one deliberate ownership change stated up front: **the column
reorder belongs to Task 01 and the collapse of combat's two action rows into
one belongs to Task 03.** Reordering is a shell decision that every later task
measures against; merging the rows is inseparable from the chip vocabulary that
makes one row legible, because both rewrite the same two widget trees.

## Scope and ownership

Allowed production surface:

- new `packages/app/lib/game/crawl_style.dart`;
- new `packages/app/lib/game/crawl_surfaces.dart`;
- new `packages/app/lib/game/crawl_action_row.dart`;
- `packages/app/lib/game/game_screen.dart`;
- `packages/app/lib/game/crawl_status.dart`;
- `packages/app/lib/game/battle_view.dart`;
- `packages/app/lib/game/log_drawer.dart`;
- tests under `packages/app/test/` named per task.

Forbidden:

- `packages/core/**`, `packages/content/**`, save schema, balance, generation,
  RNG;
- `packages/app/lib/main.dart` and the global `MaterialApp` theme;
- `packages/app/lib/town/town_style.dart` and every `lib/town/**`,
  `lib/world/**`, `lib/save/**`, `lib/notice/**` file;
- `packages/app/lib/game/pack_screen.dart` (the crawl pack route is an explicit
  contract non-goal and keeps its town appearance);
- Unit 11's renderer: `dungeon_scene.dart`, `dungeon_scene_material.dart`,
  `dungeon_render_style.dart`, `glyph_marks.dart`, `dungeon_material*.dart`,
  `glyph_plan.dart`, `dungeon_palette.dart`;
- `action_icon.dart` and `spell_row.dart` (both already correct: icons stay
  untinted `Image.asset`, spell-row styles are parameters);
- new assets of any kind, a font asset, a `ThemeExtension`, an
  `InheritedWidget`, or any app-wide design system;
- new verbs, a melee control, direct casting, or any change to what an action
  dispatches;
- golden-image tests.

### File ownership matrix

| file | Task 01 | Task 02 | Task 03 |
|---|---|---|---|
| `crawl_style.dart` | create: colours, foundation metrics, base type, `crawlTheme` | append: panel/log/timeline type + metrics | append: chip type, chip-state table, overlay colours |
| `crawl_surfaces.dart` | create: `CrawlPill` | append: `CrawlPanel`, `CrawlRegionLabel` | append: `showCrawlSheet`, `showCrawlConfirm` |
| `crawl_action_row.dart` | — | — | create: `CrawlAction`, `CrawlActionRow` |
| `game_screen.dart` | column order, map framing, recenter pill, theme wrap, note rows | — | action-row merge, deletions, overlays |
| `crawl_status.dart` | type + rhythm | — | — |
| `battle_view.dart` | — | timeline panel, folds `dockBacking` | `showEnemyInfo` only |
| `log_drawer.dart` | — | peek + drawer, folds all four private colours | — |

Each task appends to `crawl_style.dart` only members it consumes in that task,
so no handoff leaves a declared-but-unused seam member. The complete expected
membership, with its owning task, is specified below so no executor invents a
name. **AC1 closes at Task 03**, not earlier: Task 03 rewrites the shelf,
control-row and overlay trees wholesale, so folding their inline styles earlier
would be work Task 03 deletes.

## Cross-task interfaces

### The crawl style seam — `crawl_style.dart`

One plain file of `const` values plus one lazily-initialised `ThemeData`. A
sibling to `town_style.dart` in shape: not a `ThemeExtension`, not an
`InheritedWidget`, not a change to the global theme. It carries **no widgets**;
shared crawl widgets live in `crawl_surfaces.dart`.

Colours:

| name | value | owner | meaning |
|---|---|---|---|
| `crawlInk` | `0xFFE6EAF0` | 01 | the crawl's brightest ink |
| `crawlDim` | `0xFF8A919E` | 01 | subordinate ink |
| `crawlPanel` | `0xFF15181F` | 01 | panel and sheet surface |
| `crawlRule` | `0xFF2A2E38` | 01 | hairline and meter track |
| `crawlVoid` | `0xFF0E1014` | 01 | the crawl's ground |
| `crawlRaised` | `0xFF1B1F27` | 01 | an available control's fill |
| `crawlRecessed` | `0xFF11141A` | 01 | a dead control's fill, a mark well |
| `crawlArmedFill` | `0xFF262B35` | 03 | an armed control's fill |
| `crawlDisabledRule` | `0xFF1E222A` | 03 | a dead control's border |
| `crawlScrim` | `0xCC0E1014` | 03 | the death overlay's scrim |

Type ladder — every entry carries `fontFamily: 'monospace'`; deviation 2 stands
and no font asset is added:

| name | size | letterSpacing | weight | colour | owner | used by |
|---|---:|---:|---|---|---|---|
| `crawlPlace` | 15 | 3 | w500 | ink | 01 | the place name |
| `crawlBody` | 14 | — | — | ink | 01 | status facts, meters, depth pair, battle word |
| `crawlBodyDim` | 12 | — | — | dim | 01 | `Underfoot:`, `Here:`, `doneAtTheBottom` |
| `crawlRegionLabel` | 11 | 2 | w600 | dim | 02 | `NOW`, `NEXT` |
| `crawlPanelTitle` | 13 | 2 | w600 | ink | 02 | `MESSAGE LOG`, `Spells` |
| `crawlLine` | 13 | — | — | ink | 02 | newest log sentence and its mark, sheet lines |
| `crawlLineOlder` | 13 | — | — | dim | 02 | older log sentence and its mark |
| `crawlGlyph` | 18 | — | — | ink | 02 | timeline token glyph, enemy-sheet glyph |
| `crawlTokenWord` | 11 | — | — | dim | 02 | the actor word beneath a token |
| `crawlChevron` | 18 | — | — | dim | 02 | timeline separator, log-peek expand mark |
| `crawlChipLabel` | 12 | — | w500 | ink | 03 | an available chip's word |
| `crawlChipLabelDisabled` | 12 | — | w400 | dim | 03 | a dead chip's word |
| `crawlChipLabelArmed` | 12 | — | w600 | ink | 03 | an armed chip's word |
| `crawlCaption` | 11 | — | w600 | ink | 03 | the `— armed` line |
| `crawlDetail` | 11 | — | — | dim | 03 | the overflow row's cost/effect line |
| `crawlHeadline` | 28 | — | — | ink | 03 | `You died.` |

Metrics:

| name | value | owner |
|---|---:|---|
| `crawlGutter` | 12 | 01 |
| `crawlRhythm` | 4 | 01 |
| `crawlRadius` | 6 | 01 |
| `crawlHairline` | 1 | 01 |
| `crawlTapTarget` | 44 | 01 |
| `crawlPanelPadding` | 8 | 02 |
| `crawlTokenCell` | 44 | 02 |
| `crawlTokenWidth` | 76 | 02 |
| `crawlLogPeekHeight` | 104 | 02 |
| `crawlMarkColumn` | 24 | 02 |
| `crawlMarkWell` | 20 | 02 |
| `crawlLogRowRhythm` | 3 | 02 |
| `crawlChipSpacing` | 6 | 03 |
| `crawlChipRunSpacing` | 4 | 03 |
| `crawlChipPadding` | 8 | 03 |
| `crawlChipVerticalPadding` | 6 | 03 |
| `crawlChipLabelLineHeight` | 15 | 03 |
| `crawlChipMaxColumns` | 5 | 03 |
| `crawlChipMaxLabelLines` | 2 | 03 |
| `crawlDisabledIconOpacity` | 0.45 | 03 |

What each existing duplicate folds into:

| today | folds into | task |
|---|---|---|
| `town_style.dart` `ink`/`dim` imported by `game_screen.dart:19` | `crawlInk`/`crawlDim` | 01, 03 |
| `crawl_status.dart:6` whole-file `town_style` import (`mono`, `rule`, `ink`) | `crawlBody`, `crawlRule`, `crawlInk`, `crawlPlace` | 01 |
| `game_screen.dart:233-264` three inline note `TextStyle`s with a `0xFF8A919E` literal | `crawlBodyDim` | 01 |
| `battle_view.dart:15` `dockBacking` `0xB30E1015` | `crawlPanel` (the timeline is a panel in the column now, not a wash over the map) | 02 |
| `battle_view.dart:50-54,100,121-125` inline token/separator styles | `crawlChevron`, `crawlGlyph` | 02 |
| `log_drawer.dart:12-15` `_logBacking`, `_logNewest`, `_logOlder`, `_logHandle` | `crawlPanel`, `crawlInk`, `crawlDim`, `crawlDim` | 02 |
| `log_drawer.dart:17-28` `_newestRowStyle`/`_olderRowStyle`/`_rowStyle` | `crawlLine`/`crawlLineOlder`, one local selector kept | 02 |
| `log_drawer.dart:219-223` `MESSAGE LOG` inline style | `crawlPanelTitle` | 02 |
| `game_screen.dart:433-453` confirm-dialog inline styles | `crawlPanelTitle`, `crawlLine` | 03 |
| `game_screen.dart:517,619-624,734-739,760-765` chip/shelf/overflow inline styles | `crawlChipLabel*`, `crawlLine`, `crawlDetail` | 03 |
| `game_screen.dart:533,540-553` death-overlay literals | `crawlScrim`, `crawlHeadline`, `crawlBodyDim` | 03 |
| `battle_view.dart:157-172,208` enemy-sheet inline styles | `crawlGlyph`, `crawlLine` | 03 |

`town_style.dart` keeps everything it has and is not edited. It stays the
town's authority; `markColumn`, `placeName`, `roomName`, `mono`, `monoDim`,
`Heading`, `ItemRow`, `Purse`, `MaterialRows`, `Notice`, `CountStepper`,
`Commit` and `TownRoom` remain town-owned and are not reached from the crawl
after this unit. The crawl's `crawlInk`/`crawlDim`/`crawlPanel`/`crawlRule`
repeat town's four values deliberately: the two screens agree today, and one
seam owning each side is what lets either move later.

**The no-leak rule, checkable by grep at the end of Task 03:**

1. inside `packages/app/lib/game/`, only `pack_screen.dart` imports
   `town_style.dart`;
2. no file outside `packages/app/lib/game/` imports `crawl_style.dart`,
   `crawl_surfaces.dart` or `crawl_action_row.dart`;
3. `packages/app/lib/main.dart` is unchanged, so town, world, character,
   spells, roster and pack screens render from exactly the theme and styles
   they render from today.

### The scoped theme — `crawlTheme`

```dart
final ThemeData crawlTheme = ThemeData(
  brightness: Brightness.dark,
  useMaterial3: true,
  scaffoldBackgroundColor: crawlVoid,
  ...
);
```

A top-level `final`, so Dart initialises it once on first access and no build
allocates a `ThemeData`. It is built from scratch, never by `copyWith` on the
ambient theme, so it cannot inherit a future global change.

It configures exactly these Material surfaces, which are the only stock
Material defaults reachable from the crawl:

| sub-theme | value | why |
|---|---|---|
| `bottomSheetTheme` | `backgroundColor: crawlPanel`, `surfaceTintColor: Colors.transparent`, `elevation: 0`, `modalBarrierColor: crawlScrim`, top-rounded `crawlRadius`, `showDragHandle: false` | the spells overflow and enemy-info sheets |
| `dialogTheme` | `backgroundColor: crawlPanel`, `surfaceTintColor: Colors.transparent`, rounded `crawlRadius` with a `crawlRule` side, `titleTextStyle: crawlPanelTitle`, `contentTextStyle: crawlLine` | the completion confirm |
| `textButtonTheme` | `foregroundColor: crawlInk`, `overlayColor: crawlRaised` | dialog and sheet text actions that survive |
| `iconTheme` | `color: crawlInk`, `size: 18` | the recenter affordance's Material icon |
| `splashColor` / `highlightColor` | `crawlRaised` at reduced alpha | timeline token and log-peek ink response |
| `progressIndicatorTheme` | `color: crawlInk`, `linearTrackColor: crawlRule` | the status meters, so they no longer pass colours per call site |

That table is the theme's **final** state. Task 01 wires every row except
three fields whose values do not exist yet — `bottomSheetTheme.
modalBarrierColor` needs `crawlScrim` (Task 03), and
`dialogTheme.titleTextStyle` / `contentTextStyle` need `crawlPanelTitle` /
`crawlLine` (Task 02). Task 03 fills all three. No placeholder value is
invented for them in between.

`crawlTheme` is applied in exactly two places, and both are deliberate:

1. Task 01 wraps `GameScreen`'s `Scaffold` in `Theme(data: crawlTheme, …)` —
   covering everything in the crawl column, both overlays, and the recenter
   affordance;
2. Task 03's `showCrawlSheet` and `showCrawlConfirm` wrap their own content in
   `Theme(data: crawlTheme, …)` as well.

The second wrap is not redundant defence-in-depth theatre: it removes the
plan's dependence on Flutter's `InheritedTheme` capture behaviour for routes
pushed onto the root navigator, so sheet and dialog appearance is correct by
construction and provable without reasoning about framework internals.

**Why it cannot leak.** The crawl pack route is pushed with
`MaterialPageRoute` onto the root navigator from `game_screen.dart:293-300`,
so it is mounted as a sibling of `GameScreen`, not a descendant of its
`Theme`; every other screen is reached from the town or world route, which are
below the crawl in the stack and outside this subtree entirely. The global
`MaterialApp` theme in `main.dart:81-85,169-173` is untouched, and AC12 is
proved by that plus the grep rule above.

### `CrawlPill` — `crawl_surfaces.dart`, Task 01

```dart
class CrawlPill extends StatelessWidget {
  const CrawlPill({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
}
```

One tappable crawl surface for every affordance that is not an action chip:
`crawlRaised` fill, `crawlHairline` `crawlRule` border, `crawlRadius` corners,
built as `Material(color:, shape: RoundedRectangleBorder(side:, borderRadius:))`
wrapping an `InkWell`, so the ink response lands on the pill and not on the
`Scaffold` behind it. `onPressed == null` renders `crawlRecessed` with
`crawlDisabledRule` and no ink response.

`label` is both the word and the semantic label; the pill is wrapped in
`Semantics(button: true, enabled: onPressed != null, label: label, onTap:)` +
`ExcludeSemantics`, matching `_Control`'s existing pattern. When `icon` is
non-null the pill renders `Icon(icon)` instead of the word at a fixed
`crawlTapTarget` square, and `label` carries the announcement alone.

Consumers: the recenter affordance (Task 01), the log's `↓ N new` affordance
and close affordance (Task 02), the death overlay's button and the confirm
dialog's two actions (Task 03).

### `CrawlPanel` and `CrawlRegionLabel` — `crawl_surfaces.dart`, Task 02

```dart
class CrawlPanel extends StatelessWidget {
  const CrawlPanel({
    required this.child,
    this.padding = const EdgeInsets.all(crawlPanelPadding),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
}

class CrawlRegionLabel extends StatelessWidget {
  const CrawlRegionLabel(this.word, {super.key});

  final String word;
}
```

`CrawlPanel` is `crawlPanel` fill, `crawlHairline` `crawlRule` border,
`crawlRadius` corners. It takes no margin; callers supply their own so the
column's rhythm stays one decision per slot. `CrawlRegionLabel` renders `word`
in `crawlRegionLabel` — a region caption, never per-entry prose.

Consumers: the timeline panel and the log peek's surface (Task 02); the spells
overflow sheet, the enemy-info sheet and the confirm dialog (Task 03).

### `CrawlAction` and `CrawlActionRow` — `crawl_action_row.dart`, Task 03

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
```

`CrawlActionRow` owns pixels only: it renders `notes` as `crawlBodyDim` rows,
then the chips. Which verbs apply stays in `game_screen.dart`, where the state,
the bloc, the navigation doors (`suspendDungeon`, `_confirmCompletion`,
`leaveEncounter`) and the overflow sheet already live — so there is no import
cycle and no second place that decides what a control does.

`shelfKey`, `shelfWaitKey`, `overflowKey` and `controlsKey` are deleted.
`actionRowKey` replaces `controlsKey`. **Each chip's key is
`ValueKey(action.label)`**, which is the row's only test handle and is
guaranteed unique — a debug `assert` in `CrawlActionRow` checks that the
labels are distinct, which is also the structural guard behind AC3.

## Region specifications

### B. The mock column order — Task 01

`GameScreen`'s `Column` (`game_screen.dart:66-129`) becomes, in order:

1. `CrawlStatus(state:, dungeon:)`;
2. `if (state.isBattleOpen) BattleDock(state:, onActorSelected:)`;
3. `Expanded(key: dungeonSceneSlotKey, child: <map slot>)`;
4. `LogPeek(key: logPeekKey, state:, bloc:)`;
5. the action row.

The `Stack`'s two overlays (`LogDrawer` when the extent is not peek,
`_DeathOverlay` on game over) and the `PopScope`/`BlocListener`/`Scaffold`/
`SafeArea`/`BlocBuilder` spine are unchanged.

`BattleShelf` is a **deliberately temporary fifth slot** in Task 01, placed
immediately above the action row, so Task 01 has a valid handoff state without
owning the merge. AC3 is not met until Task 03. `shelfKey` and `controlsKey`
survive Task 01 unchanged so `battle_shelf_icons_test` and
`crawl_controls_test` keep working; both keys die in Task 03.

**Map framing.** The `EdgeInsets.all(8)` padding is removed: the map slot spans
the full width, as frames 2–4 draw it, and meets the chrome above and below
through a `crawlHairline` `crawlRule` top and bottom border on the slot. The
renderer's own output is untouched — `DungeonSceneHost`, `LayoutBuilder`,
`GridGeometry.camera`, the tap/pan/long-press callbacks and
`_heroOffScreen` keep their exact wiring; only the box they are given changes,
which is what AC13 permits. This returns 16 dp of width and 16 dp of height to
the map and pays for part of the chrome budget below.

The recenter affordance keeps `recenterKey`, its `Positioned(top: 8, right: 8)`
placement and its `RecenterPressed` dispatch, and becomes
`CrawlPill(label: 'Recenter on the hero', icon: Icons.center_focus_strong,
onPressed:)` instead of `FloatingActionButton.small` — the last stock Material
surface over the map.

### C. The timeline panel — Task 02

`BattleDock` becomes a panel in the column rather than a translucent wash over
the map:

```text
CrawlPanel(                                   // margin: crawlGutter h, crawlRhythm v
  Column(
    Row(  SizedBox(crawlTokenWidth, CrawlRegionLabel('NOW')),
          SizedBox(width: crawlChevronGap),
          if (hasNext) CrawlRegionLabel('NEXT') ),
    SizedBox(height: crawlRhythm),
    Row(  <pinned current-hero cell>,
          Text('›', crawlChevron),
          Expanded(SingleChildScrollView(horizontal, Row(<remaining cells>))) ),
  ),
)
```

- `Key('dock-backing')` moves to the outer `CrawlPanel` so the existing scroll
  and descendant assertions keep their anchor.
- **The first token is pinned outside the scroller.** It is always the current
  hero, so `NOW` labels a cell that cannot scroll away, and `NEXT` labels
  exactly the scrolling remainder. The scroller remains the panel's one
  `Scrollable`, so `battle_view_test.dart:530-550`'s overflow-and-drag proof
  keeps working.
- **`NEXT` renders only when the scroller holds at least one token.** When
  `projectActivationQueue` truncates to the current hero alone, the panel shows
  `NOW`, that one token, and nothing else: no caption over emptiness, no
  placeholder, no ellipsis. That is how the silence rule survives a caption.
- One **cell** is `SizedBox(width: crawlTokenWidth /* 76 */)` holding a ringed
  token above the actor's word:
  - ring: a `crawlTokenCell` circle, `crawlRaised` fill, `crawlHairline`
    `crawlRule` border, glyph centred in `crawlGlyph`;
  - word: `crawlTokenWord`, in a `FittedBox(fit: BoxFit.scaleDown)` so a long
    name shrinks and never ellipsises — the same idiom `crawl_status.dart`
    already uses for the place name and the meters.
- The hero cell's glyph is `'@'` and its word is `'You'`. The literal `'@ YOU'`
  disappears; its two facts are composed instead. Both hero keys
  (`timeline-current-hero`, `timeline-next-hero`), the actor key
  `timeline-actor-<id>-<queueIndex>`, the `Semantics` labels
  `'You, current activation'` / `'You, next activation'` /
  `presentation.displayName`, `button: true` on actor cells, the `InkWell`
  ancestor and the glyph `Text` carrying exactly `presentation.glyphLabel` are
  all unchanged.
- Both token `Semantics` gain `excludeSemantics: true`, so the ring glyph and
  the word beneath do not double-announce. The declared `label`/`button`
  properties the tests read are untouched.
- **No per-token current or selected visual state is added.** The current hero
  is distinguished by key, by semantic label and by sitting under `NOW`;
  `selectedActorId` continues to have no visual effect. The mock's brighter NOW
  ring is deliberately not adopted — AC7 freezes the current/selected
  distinction, and `NOW` as a region label already carries it.
- Order, literal repeated tokens, duplicate superscript badges, silent
  truncation, and the tap that opens `showEnemyInfo` at no turn cost are
  untouched. `activation_timeline.dart` and
  `game_bloc.dart:315-337` are not edited.

### C. The log surfaces — Task 02

**Peek.** `crawlLogPeekHeight` (104) stays the *slot* height, so the reorder
costs the map nothing: inside it, a `CrawlPanel` with `crawlGutter` horizontal
and `crawlRhythm` vertical margin renders the same reverse `ListView` of
sentences. The drag pill is dropped here and the mock's explicit expand
affordance replaces it: a trailing `Text('›', crawlChevron)` centred
vertically at the panel's right edge, outside the list. The whole strip stays
one tap target, `logPeekKey` stays on the outermost `Semantics`/
`GestureDetector`, the `'Open the message log'` label, the game-over inert
rule and `LogDrawerHandlePulled` are unchanged, and no category marks appear.

**Drawer.** `LogDrawer` keeps its `Align`/`FractionallySizedBox` geometry, its
0.45/1.0 extents, `logDrawerKey`, `logHandleKey`, the `_HandlePill`, the
`ScrollController`, the 8 px follow tolerance, `LogFollowBroken`/
`LogFollowResumed`/`LogDrawerClosed`, `_maybeJumpToNewest` and
`_jumpToNewest` exactly as they are. It gains:

- the title in `crawlPanelTitle`, still reading `MESSAGE LOG` (deviation 4);
- a `crawlHairline` `crawlRule` rule under the title row, inset by
  `crawlGutter`;
- row rhythm `crawlLogRowRhythm` vertical padding per `_LogRow`;
- the category mark in an inset well: a `crawlMarkWell` square inside the
  `crawlMarkColumn` gutter, `crawlRecessed` fill, `crawlHairline` `crawlRule`
  border, 4 dp corners, the mark centred **in the row's own style** so the mark
  still shares its sentence's colour and hue never carries the category;
- `logCloseKey` becomes `CrawlPill(label: 'Close the message log', icon:
  Icons.close, onPressed:)`, and `logUnreadKey` becomes
  `CrawlPill(label: '↓ ${unread} new', onPressed:)` — the text stays exactly
  `↓ N new`, shown iff `!logFollowing && logUnread > 0`.

Contents, ordering, causality, the peek→half→full→peek cycle, follow, unread
and the death collapse are unchanged; `game_bloc.dart` is not edited.

### D. The action grammar — Task 03

**One row, one guard per verb.** `game_screen.dart` builds a single
`List<CrawlAction>` and hands it to one `CrawlActionRow(key: actionRowKey)`.
`_Controls`, `_Control`, `BattleShelf` and `_ShelfButton` are deleted;
`_OverflowRow`, `doneControl`, `doneAtTheBottom`, `_confirmCompletion`,
`leaveDungeon`, `suspendDungeon`, `leaveEncounter` and `_DeathOverlay` stay in
`game_screen.dart` so no test import moves.

Action order — battle verbs first, then the exploration verbs that still
apply, which is the mock's reading order and leaves every exploration-only
scene's set and order bit-identical to today:

| # | chip | guard | dispatch |
|---:|---|---|---|
| 1 | `Drink (n)` | `isBattleOpen && firstPotion != null` | `QuickDrinkPressed`, `onPressed: null` when `isGameOver` |
| 2–4 | `<schoolMarking> <name> <manaCost>` | `isBattleOpen`, `knownSpells.take(3)` | `CastPressed` for mend/ward, else `SkillArmed` toggle |
| 5 | `+n` | `isBattleOpen && knownSpells.length > 3` | opens the overflow sheet |
| 6 | `Wait` | `isBattleOpen` | `WaitPressed` |
| 7 | `Pick up` | `canPickUp` | `PickUpPressed` |
| 8 | `node.verb` | `canGather` | `GatherPressed` |
| 9 | `Drink (n)` | `!isBattleOpen && firstPotion != null` | `QuickDrinkPressed`, `onPressed: null` when `isGameOver` |
| 10 | `Pack (n)` | always | pushes `CrawlPackScreen` |
| 11 | `Wait` | `isEncounter && !isRoadClear && !isBattleOpen` | `WaitPressed` |
| 12 | `Flee` | `canFlee` | `FleePressed` |
| 13 | `Move on` | `isRoadClear` | `leaveEncounter(cleared)` |
| 14 | `Ascend <` | `canAscend` | `AscendPressed` |
| 15 | `Descend >` | `canDescend` | `DescendPressed` |
| 16 | `Leave` / `Finish` | `canLeave` | `suspendDungeon` / `_confirmCompletion` |

Rows 9 and 11 are the merge's whole mechanism: **the exploration Drink gains
`&& !state.isBattleOpen`**, exactly the guard the exploration Wait already
carries at `game_screen.dart:302-304`. Rows 1/9 and 6/11 are therefore
mutually exclusive, so Drink and Wait each render exactly once, from exactly
one guard, and no other visibility or availability rule changes: every guard
above is the guard that file uses today, Pack stays the always-on exception,
disabled Drink stays visible and inert, and every dispatched event is the same
event. Labels are unchanged strings — no verb is renamed, shortened or hidden,
and the mock's shorter chip words are read as illustration, not instruction.
Readied spell order stays `state.knownSpells.take(BattleShelf.readiedSpellCount)`
(`readiedSpellCount = 3` moves to `crawl_action_row.dart` as
`readiedSpellCount`); the mock's Mend-before-Firebolt ordering is illustrative
and school-then-name order is kept.

`notes` is the same three conditional sentences in the same order and under the
same conditions: `doneAtTheBottom` when `canLeave && isAtTheBottom`,
`'Underfoot: ${node.marking} ${node.word}'` when `nodeUnderfoot != null`, and
the `Here:` sentence when `itemsUnderfoot.isNotEmpty`. They keep wrapping onto
a second line by design.

**Chip anatomy.** One chip is
`SizedBox(width: chipWidth, height: chipHeight)` holding
`Material(color: skin.fill, shape: RoundedRectangleBorder(side:
BorderSide(color: skin.border, width: skin.borderWidth), borderRadius:
BorderRadius.circular(crawlRadius)))` → `InkWell(onTap: action.onPressed,
borderRadius:)` → centred `Column`:

1. the icon slot, always `actionIconSize` tall: `ActionIconImage(icon)` when
   the action has one, otherwise a `SizedBox(height: actionIconSize)` so every
   word in the row sits on the same baseline. `ActionIconImage` is not edited:
   it stays `Image.asset` at `actionIconSize`, `excludeFromSemantics: true`,
   never `ImageIcon` and never tinted. A dead chip wraps it in
   `Opacity(opacity: crawlDisabledIconOpacity)` — alpha, not a colour filter,
   so the multitone master is not flattened and the `Image` is still present
   in the tree;
2. `SizedBox(height: crawlRhythm)`;
3. the label: `Text(action.label, textAlign: TextAlign.center, maxLines:
   crawlChipMaxLabelLines, style: skin.label)`;
4. the armed line: `Text('— armed', style: crawlCaption)` on the armed chip,
   and reserved empty space of the same height on every chip in a row that
   contains an armable action.

**Even widths, no ellipsis, no reflow — the fit maths.** `CrawlActionRow` wraps
its chips in a `LayoutBuilder` and picks one column count for the whole row:

```dart
for (var columns = crawlChipMaxColumns; columns >= 1; columns--) {
  final width = (available - crawlChipSpacing * (columns - 1)) / columns;
  final content = width - crawlChipPadding * 2;
  if (content <= 0) continue;
  final lines = <int>[for (final a in actions) _labelLines(a.label, content)]
      .reduce(math.max);
  if (lines >= 1 && lines <= crawlChipMaxLabelLines) return (columns, width, lines);
}
// degenerate guard: one column at full width
```

`_labelLines(label, content)` lays a `TextPainter` out over `crawlChipLabel`
with `textAlign: TextAlign.center` and `maxWidth: content`, and returns
`painter.width <= content + 0.5 ? painter.computeLineMetrics().length :
crawlChipMaxLabelLines + 1` — so a column count that would break an unbreakable
word is rejected rather than clipped. Every painter is disposed. The
measurement runs once per row build over at most a dozen short strings; the
chips themselves allocate no painters.

All chips then take that one `width` and the resulting `lines`, laid out in a
`Wrap(spacing: crawlChipSpacing, runSpacing: crawlChipRunSpacing, alignment:
WrapAlignment.center)` of fixed-width children — so widths are even, heights
are even, and the row never scrolls: it grows and the `Expanded` map pays.

`chipHeight = crawlChipVerticalPadding * 2 + actionIconSize + crawlRhythm +
lines * crawlChipLabelLineHeight + (anyArmable ? crawlChipLabelLineHeight : 0)`.

Two consequences are deliberate and load-bearing:

- **the `— armed` word is a line of its own, not an inline suffix.** Appending
  ` — armed` to `✳ Firebolt 2` would push that label from 12 to 20 characters,
  drop the row's column count, and reflow the whole action row — and therefore
  the `Expanded` map and the Flame viewport — under the player's thumb at the
  moment they arm. The caption line, reserved for every chip in a row that has
  an armable action, keeps arming free of reflow while keeping the border and
  the word AC5 requires;
- **the reserve is row-scoped, not global.** Exploration rows contain no
  armable action, so they pay nothing for a state they cannot enter.

At the phone's 411.4 dp the arithmetic lands on 4 columns with 76.5 dp of
label width: `Firebolt` (the longest unbreakable word) measures about 58 dp,
`Descend >` fits one line, and `✳ Firebolt 2` / `✳ Frost Lance 4` take two.
Those are estimates from a 0.6 em monospace advance and are **not** locked;
the measured column count and chip height belong in the Task 03 receipt.

**Chip states.** `crawl_style.dart` gains the control-state table, so one
switch owns the whole vocabulary and a greyscale test can read it directly:

```dart
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

| state | fill | border | width | label | icon opacity |
|---|---|---|---:|---|---:|
| `available` | `crawlRaised` | `crawlRule` | `crawlHairline` | `crawlChipLabel` | 1.0 |
| `disabled` | `crawlRecessed` | `crawlDisabledRule` | `crawlHairline` | `crawlChipLabelDisabled` | `crawlDisabledIconOpacity` |
| `armed` | `crawlArmedFill` | `crawlInk` | `crawlHairline * 2` | `crawlChipLabelArmed` | 1.0 |

A chip's state is `action.armed ? armed : action.onPressed == null ? disabled :
available`. The three fills rise in luminance (`crawlRecessed` <
`crawlRaised` < `crawlArmedFill`), the armed border is twice as heavy and
jumps from `crawlRule` to `crawlInk`, the label moves dim→ink and
w400→w500→w600, and armed adds the `— armed` word. Four independent cues, none
of them hue: the state reads in a greyscale capture, and a property test can
assert the ordering without pinning a hex.

The mock's `More` chip is the existing `+n` battle overflow and gains no new
contextual verbs. Melee stays map-first with no melee control; a targeted
spell still arms from its chip, marks every visible monster through
`armedTargets`, and casts or disarms through `_onTileTapped`. `game_bloc.dart`
is not edited.

### E. The crawl overlays — Task 03

"No stock-Material break" means, concretely, per surface:

| surface | today | after |
|---|---|---|
| spells overflow sheet | `showModalBottomSheet` with Material-3 default surface, elevation tint and barrier; hand-rolled `SafeArea`/`Padding`/`SingleChildScrollView`/`Column` | `showCrawlSheet<void>(context, children: …)`: `crawlTheme`, `crawlPanel` surface, top-rounded `crawlRadius`, zero elevation tint, `crawlScrim` barrier, the `'Spells'` heading passed as the first child in `crawlPanelTitle`, rows in `crawlLine`/`crawlDetail` |
| enemy info sheet | the same duplicated sheet scaffolding in `battle_view.dart:143-194` | the same `showCrawlSheet`, glyph in `crawlGlyph`, name and lines in `crawlLine` |
| completion confirm | `AlertDialog` with default surface, shape, tint and `black54` barrier, and two stock `TextButton`s | `showCrawlConfirm(context, title:, body:, dismiss:, confirm:) → Future<bool>`: `Dialog` on `crawlPanel` with a `crawlRule` hairline border, `crawlPanelTitle` title, `crawlLine` body, two `CrawlPill`s, `crawlScrim` barrier |
| death overlay | `ColoredBox(0xCC0E1014)` with three inline styles and a stock `FilledButton` | `crawlScrim`, `crawlHeadline`, `crawlBodyDim`, one `CrawlPill` |
| recenter affordance | `FloatingActionButton.small` | `CrawlPill` with the same icon and dispatch (Task 01) |
| `↓ N new` and log close | stock `FilledButton` / `IconButton` | `CrawlPill` (Task 02) |

`showCrawlSheet` is implemented with `showModalBottomSheet`, so
`find.byType(BottomSheet)` — which `battle_view_test.dart:457` relies on —
keeps working. Every player-facing string is unchanged:
`'The delve is done. Leave with your spoils?'`, its body sentence,
`'Stay down here'`, `'Leave with them'`, `'Spells'`, `'You died.'`,
`'What you carried is gone. What you wore is not.'`, `'Return to town'`,
`'Wake at home'`, `'Wounds n / n'`, `'strikes adjacent'`, `'Speed n'`,
`'Resists <word>'`, `'Burns at <word>'`. `spell_row.dart` is not edited: it
already takes its styles as parameters, and the overflow row passes crawl
styles in.

The two duplicated sheet scaffolds collapsing into one helper is the only
extraction this unit makes: there are exactly two copies today, which is the
threshold `AGENTS.md` sets.

## The vertical-space budget

The map is `Expanded`: every row of chrome is subtracted from map height. Unit
9 measured one status row at 52 dp on `Medium_Phone`. `Medium_Phone` is
412 × 892 dp with roughly 844 dp inside the `SafeArea`; the widget-test surface
(`test/support/phone.dart`) is 411.4 × 923.4 dp with no system insets, so
**measurements must be expressed as chrome height, not map height** — chrome is
inset-independent and the same number on both surfaces.

Planned chrome, in dp:

| slot | today | planned | note |
|---|---:|---:|---|
| status | 52 | 56 | +1 rhythm step and a hairline |
| timeline (combat only) | 52 | 96 | panel, captions, ringed tokens, words |
| map hairlines | 0 | 2 | replaces 16 dp of padding; the map gains 14 net |
| log peek | 104 | 104 | slot height unchanged by design |
| action row, exploration, no notes | ~48 | ~112 | 5 chips, 4 columns, 2 runs of 50 |
| action row, exploration, 3 notes | ~96 | ~160 | notes wrap by design |
| action row, combat, typical 7 chips | ~176 (two rows) | ~170 | 2 runs of 79 |
| action row, combat, worst ~11 chips | ~176 (two rows) | ~285 | 3 runs of 79 |

Totals, and what they leave the map inside a 844 dp `SafeArea`:

| scene | chrome | map |
|---|---:|---:|
| exploration, typical | ~274 | ~570 (today ~640) |
| exploration, worst notes | ~322 | ~522 |
| combat, typical | ~428 | ~416 (today ~460) |
| combat, worst density | ~543 | ~301 |

**What the plan expects to cost:** roughly 66 dp of map height in exploration
and 44 dp in combat at typical density, because the merged row is taller per
run than two shorter rows were, and the timeline panel is 44 dp taller than the
flat dock — partly repaid by the 14 dp the map framing returns.

**Asserted caps (Task 03, at `onAPhone` size, as chrome height):** 360 dp at
exploration typical density and 560 dp at the worst constructible combat
density. Those correspond to a map of at least 484 dp and 284 dp on
`Medium_Phone`. The caps carry deliberate headroom over the estimates above;
the executor records the *measured* chrome and map height for both scenes in
its receipt rather than reporting "within budget".

**What the executor may tune** (constants only, no structural change):
`crawlChipVerticalPadding` 4–8, `crawlChipLabelLineHeight` 14–16,
`crawlCaption` size 10–12, `crawlTokenWord` size 10–12, `crawlTokenCell`
40–48, `crawlTokenWidth` 68–84, `crawlPanelPadding` 4–8,
`crawlChipMaxColumns` 4–6, `crawlLogRowRhythm` 2–4.

**What escalates:** a measured chrome height above either cap; any need to
shrink `crawlLogPeekHeight`, scroll the action row, hide a verb that applies,
shorten a label, ellipsise anything, or drop the armed reserve. Those are
scope or contract changes, not tuning.

## Task slices and handoffs

### Task 01 — crawl style seam, scoped theme, mock column order

Owns `crawl_style.dart`'s foundation, `crawlTheme` and its one application
site, `CrawlPill`, the column reorder, the map's full-bleed framing and
hairlines, the recenter affordance, `crawl_status.dart`'s type and rhythm, and
the three note rows' styles. It leaves `BattleShelf` as a temporary fifth slot
above the action row and does not touch the timeline, the log, the chips or the
overlays.

Valid handoff: `crawl_layout_test.dart` green, every existing crawl test green,
all three package gates green, `crawl_status.dart` no longer importing
`town_style.dart`, Task 01 receipt accepted.

### Task 02 — information hierarchy

Consumes Task 01's seam and appends its own members. Owns the timeline panel,
the log peek's surface and expand affordance, and the drawer's handle, title,
rule, rhythm and mark well. It does not touch the action row, the chips, the
overlays or the enemy info sheet.

Valid handoff: the rewritten `battle_view_test` label assertions and
`log_drawer_test` contrast assertions green, every timeline and log behaviour
green, all three package gates green, `dockBacking` and all four private log
colours gone, Task 02 receipt accepted.

### Task 03 — action grammar and overlays

Consumes both earlier seams and appends the chip vocabulary. Owns
`crawl_action_row.dart`, the sixteen-row merge in `game_screen.dart`, the chip
state table, the sheet and confirm helpers, the enemy sheet, the death overlay,
and the AC1 closing audit.

Valid handoff: one action row in every scene, Drink and Wait each rendered
once, the frozen control set and order intact, the four audit greps clean, all
three package gates green, the measured chrome and map heights recorded, Task
03 receipt accepted.

Detailed fresh-executor capsules:

- `plan-tasks/01-style-seam-and-column-order.md`;
- `plan-tasks/02-information-hierarchy.md`;
- `plan-tasks/03-action-grammar-and-overlays.md`.

## Red/Green proof map

Every task writes its behavioural Red before production change and records the
observed failure. No golden images, no source-text assertions, no assertion of
a widget type, a literal colour or a field being forwarded. Where a test must
name a presentation value, it compares against the **seam's named constant or
another rendered value**, never a hex literal.

### Task 01

New `packages/app/test/widget/crawl_layout_test.dart`:

1. at phone size, exploring: status top < map top, map bottom ≤ peek top, peek
   top < action row top;
2. at phone size, in an open battle: status top < timeline top < map top;
3. the map slot spans the full surface width (no horizontal inset) and keeps a
   non-zero height in both scenes;
4. the log extent cycle still leaves the map slot rect and the peek rect
   unchanged (the reorder must not reintroduce reflow).

Expected Red: 1 and 2 fail because status and the timeline sit below the map
today; 3 fails because of the 8 dp padding.

Regression that must stay green throughout: `crawl_status_test.dart` (strings,
meter keys, progress values, the worst-case no-squeeze loop),
`log_drawer_test.dart:112-161`, `battle_view_test.dart` `BattleDock`
presence/absence, `hero_off_screen_test.dart`, `back_guard_test.dart`,
`suspend_door_test.dart`, `door_reentry_test.dart`.

### Task 02

Rewritten in `packages/app/test/battle_view_test.dart`:

- the exact-label inventory at `:338-357` becomes: the queue's cells, read
  left to right, carry the glyph and word of the current hero, each owed actor
  occurrence in order with its duplicate badge, then the next hero — asserted
  through the existing token keys and each cell's glyph and word text, with the
  semantic labels and `button` properties still asserted as they are today.

Added there:

- `NOW` and `NEXT` render once each as region captions while a queue has a
  remainder;
- with the queue truncated at a hidden due actor, `NOW` and the current hero
  render, `NEXT` does not, and there is still no `…`, no `IN `, no `NOW —` and
  no next-hero token;
- the pinned current-hero cell does not scroll when the remainder is dragged.

Rewritten in `packages/app/test/widget/log_drawer_test.dart:223-258`: the
literal `0xFFE6EAF0` / `0xFF8A919E` assertions become relative — the newest
sentence's colour has strictly greater `computeLuminance()` than an older
sentence's, and each mark's colour equals its own sentence's colour.

Added there: the peek renders an expand affordance and no category mark; the
drawer's mark sits in a well inside its gutter and the sentence starts after
it; the extent cycle, follow, unread `↓ N new`, close, empty and one-line logs,
and the death collapse all still behave as asserted today.

Expected Red: the caption, pinned-cell, word-beneath and well assertions fail
against the flat dock and the flat gutter; the relative-contrast rewrite passes
before and after by construction and is the regression that proves the fold of
`_logNewest`/`_logOlder` changed no reading.

### Task 03

Rewritten in `packages/app/test/widget/crawl_controls_test.dart`:

- `_button`/`_expectIcon`/`_expectNoIcon`/`_controlOrder` find chips by
  `ValueKey(label)` under `actionRowKey` instead of by `FilledButton`;
- `_expectNoSqueeze` becomes a no-clip proof: for every chip label
  `RenderParagraph`, `didExceedMaxLines` is false and
  `paragraph.size.width + 0.5 >= paragraph.getMinIntrinsicWidth(double.infinity)`
  — the rendered box is at least as wide as the widest unbreakable word, which
  is what "no label ellipsises" means once labels may wrap. If
  `didExceedMaxLines` proves awkward to reach, assert instead that the
  paragraph's height accommodates its line count at
  `crawlChipLabelLineHeight`; either form proves the same thing;
- the frozen control set and order assertions are kept verbatim for all three
  exploration scenes — that is a real contract and the merge must not move it;
- the disabled-Drink case keeps its word, keeps its `Image`, keeps a null tap,
  and still shows no note rows.

Rewritten in `packages/app/test/widget/battle_shelf_icons_test.dart`:

- `_shelfText`/`_shelfButton` scope to `actionRowKey`; `shelf-spell-<id>`
  becomes `ValueKey('<label>')`; `overflowKey` becomes `ValueKey('+n')`;
- `'✳ Firebolt 2 — armed'` as one string becomes: the armed chip still shows
  `'✳ Firebolt 2'`, additionally shows the word `'— armed'`, and carries a
  heavier border than an unarmed sibling — border and word, no widget type, no
  hex.

Rewritten in `packages/app/test/battle_view_test.dart`: `find.byType(
BattleShelf)` at `:305,556` becomes the observable it defends — at `:305`, the
readied spell chip and the `Wait` chip are gone once the fight ends; at
`:556`, the `Wait` chip is present while it runs.

Rewritten in `packages/app/test/widget/craft_surfaces_test.dart`: the eight
`find.widgetWithText(FilledButton, …)` sites become `find.byKey(ValueKey(…))`
chip finders. Every behaviour those tests defend — Mine only over a vein,
Gather only over a patch, neither offered elsewhere, working it takes the
control away and the material up, Mine and Pick up share the row un-ellipsised —
is unchanged.

Added, new `packages/app/test/widget/crawl_action_row_test.dart`:

1. **AC3:** in an open battle with a potion carried, `'Drink (n)'` renders
   exactly once on screen, and `'Wait'` renders exactly once; the row carries
   exactly one `actionRowKey`, and no `shelfKey` exists;
2. **AC4:** in one row, every chip has the same width and the same height, and
   every icon-bearing chip renders its icon above its word (icon top < word
   top);
3. **AC5 (property):** `crawlChipSkin` fills rise in `computeLuminance()` from
   `disabled` through `available` to `armed`; the armed border is heavier than
   the available border and a different colour; the disabled label's colour is
   dimmer than the available label's; the armed chip additionally renders the
   word `— armed`;
4. **AC5 (rendered):** arming a spell changes that chip's rendered border
   weight and adds the word, and **does not change the map slot's rect** — the
   armed reserve's whole purpose;
5. **AC14 (testable half):** at `onAPhone` size, chrome height ≤ 360 dp in an
   exploration scene at typical density and ≤ 560 dp in the densest legal
   battle scene (stairs-up landing, a gather node and items underfoot, two
   potions, four known spells, one adjacent monster), with no chip label
   exceeding `crawlChipMaxLabelLines` and no clipped paragraph;
6. **AC9:** the game-over scene keeps the Drink chip visible and inert.

Added, new `packages/app/test/widget/crawl_surfaces_test.dart`:

7. **AC11:** the spells overflow sheet, the enemy info sheet and the
   completion confirm each render their surface on `crawlPanel` — read from
   the rendered `Material`'s colour inside the `BottomSheet` / `Dialog` — and
   not on the surface a bare
   `ThemeData(brightness: Brightness.dark, useMaterial3: true)` would give
   them; the death overlay renders on `crawlScrim`;
8. **AC12:** pushing the crawl pack route from the crawl leaves the pack screen
   on the town's `panel`/`ink`, proving the scoped theme does not escape the
   crawl subtree.

Closing audit for **AC1** (Task 03, recorded in the receipt):

```text
grep -n "TextStyle(" lib/game/{game_screen,crawl_status,battle_view,log_drawer,crawl_action_row,crawl_surfaces,action_icon,spell_row}.dart
grep -n "Color(0x"   lib/game/{game_screen,crawl_status,battle_view,log_drawer,crawl_action_row,crawl_surfaces,action_icon,spell_row}.dart
grep -rn "town_style" lib/game/
grep -rn "crawl_style\|crawl_surfaces\|crawl_action_row" lib/ --include=*.dart
```

Expected: the first two return nothing; the third returns only
`pack_screen.dart`; the fourth returns only files under `lib/game/`.
`dungeon_palette.dart`, `dungeon_scene.dart`, `dungeon_scene_material.dart`
and `glyph_plan.dart` are Unit 11's renderer and are excluded.

## Package and scope gates

Every task runs its focused command, then from `packages/app`:

```text
dart format --set-exit-if-changed --output=none lib test
flutter analyze
flutter test
```

After Task 03 the controller reruns those three on the integrated tree and
audits the complete diff:

- no `packages/core`, `packages/content`, save, asset, pubspec or CI change;
- no `main.dart` or global-theme change;
- no `game_bloc.dart`, `activation_timeline.dart`, renderer, camera, FOV,
  hit-test, targeting, identity or RNG change;
- no `town_style.dart` or `lib/town/**`, `lib/world/**` change;
- no `action_icon.dart`, `spell_row.dart` or `pack_screen.dart` change;
- no second `ListView` in the crawl column, and no per-build `ThemeData` or
  per-chip `TextPainter` allocation outside the one row measurement.

Do not claim integration green from task receipts alone.

## Integrated acceptance and correction barrier

After integrated gates, one independent acceptance review:

- **COR:** one guard per verb and no verb rendered twice; every visibility and
  availability rule and every dispatched event unchanged; Pack still the
  always-on exception; disabled still inert; truncation still silent and
  caption-free; the current/selected distinction still non-visual; extent,
  follow and unread unchanged; the scoped theme provably confined to the crawl
  subtree; arming free of map reflow.
- **TTC:** every changed behaviour maps to a named Red/Green proof; the six
  rewritten presentation-pinning sites assert behaviour, not literals or types;
  the frozen control set and order survives verbatim; no padded or tautological
  test was added.
- **CRF:** one style seam, one surfaces file, one action-row file, one
  composition site; no `ThemeExtension`, no app-wide design system, no
  declared-but-unused seam member, no third sheet scaffold, no duplicated
  chip-state switch; `game_screen.dart` smaller than it started.
- **SEC — SKIP:** presentation-only, offline, no new input, file, network or
  trust boundary. Any such need contradicts scope and escalates.

Close every must-fix finding before device installation. Any later production
or build-affecting correction reopens the affected package proof and a scoped
acceptance review before device evidence may be accepted.

## Device gate and bounded tuning

Use the standing `Medium_Phone` procedure only after integrated acceptance:

1. back up both save slots and record byte hashes;
2. install the accepted build;
3. capture every capsule below in colour **and** greyscale;
4. if needed, perform at most one constants-only tuning pass inside the
   envelopes named in the budget section;
5. rerun all focused and package evidence traversed by those constants plus a
   scoped acceptance review, then recapture affected capsules;
6. restore both slots and verify the restored bytes match the pre-install
   hashes under the same comparison scheme.

| capsule | scene | settles |
|---|---|---|
| A | exploration, stairs landing, loot and a gather node underfoot, potions carried | AC2, AC4, AC5, AC14 (worst exploration density), map framing |
| B | open combat, four known spells, potion carried | AC2, AC3, AC4, AC6, AC14 (typical combat), timeline hierarchy |
| C | armed targeting, map targets marked | AC5 (armed border and word), AC10, no reflow on arming |
| D | expanded log at half and full | AC8, drawer handle/title/rule/rhythm, mark well |
| E | spells overflow sheet, enemy info sheet, completion confirm, death overlay | AC11 |
| F | town, world, character, spells, roster and pack screens | AC12 |
| G | the densest legal battle density reachable on device | AC14 ceiling, recorded map height |

Record the measured map height for A, B and G, and record whether any label
ellipsised at worst density. Compare A–E against frames 2–5 on hierarchy,
density, rhythm, framing, contrast and action-state clarity — the mock is
directional, not a pixel target.

## Completion and integration boundary

After final acceptance the controller may update canonical LDD records,
including AC17's judgement on whether the dungeon viewport is now the dominant
remaining parity gap. PR, push, review publication, merge and other
remote actions still require explicit user approval.

Suggested separable implementation commits:

1. `feat: give the crawl one visual authority and the mock's order`;
2. `feat: compose the crawl's timeline and log hierarchy`;
3. `feat: collapse the crawl to one chip action row`.

Commit wording is discretionary; task boundaries are not.

## Plan quality gate

- **COR — PASS.** The merge's mechanism is one named guard change with a
  mutual-exclusion argument drawn from the source, not a rewrite of visibility
  rules. Every guard, dispatch, key, semantic label and player-facing string
  that must survive is enumerated. The three latent traps found in the tests —
  the single-`ListView` constraint, the `dock-backing` label inventory, the
  `FilledButton` pins in `craft_surfaces_test` — are named with their owning
  task. The theme's confinement is argued from route topology rather than from
  framework capture behaviour, and the sheet helpers wrap their own theme so
  the argument is not load-bearing. The armed reserve exists to stop an arm
  from reflowing the `Expanded` map.
- **TTC — PASS.** Each of the 17 acceptance criteria maps to either a named
  behavioural proof or a named device capsule, and the split between them is
  explicit in the residual-risk section. Six presentation-pinning sites are
  named with the exact behaviour their rewrite must assert. The rule "compare
  against a seam constant or another rendered value, never a hex" is stated
  once and applied throughout. Expected Red is stated per task.
- **CRF — PASS.** Three sequential slices, each with its own Red→Green cluster
  and its own valid handoff state. One style seam, one surfaces file, one
  action-row file, one composition site; the seam grows only as tasks consume
  it, so no handoff ships a dead member. The only extraction is the sheet
  helper, at the second copy, which is the repository's stated threshold. The
  row measurement allocates once per build over a dozen short strings and the
  theme is a lazily-initialised top-level `final`.
- **SEC — SKIP.** Presentation-only, offline, no new trust boundary. Recorded
  rather than run.

### Residual risks: what tests can prove, and what only the device can

Proved by the suite, and therefore not a device risk: the column order; single
Drink and single Wait; the frozen control set and order; even chip widths and
heights; icon above word; the chip-state luminance/weight/word ordering; no
clipped label at phone width; chrome height under both caps; the timeline's
captions, words, order, badges, silent truncation and no-turn-cost inspect; the
log's contents, extent cycle, follow, unread, relative contrast and shared mark
colour; each overlay's surface; the pack route's town appearance; no map reflow
on arming or on an extent change.

Settled only by the `Medium_Phone` pass:

1. **Whether the map is still large enough to play in.** The suite can cap
   chrome; only the device says whether ~416 dp of map in typical combat and
   ~301 dp at worst density reads as a dungeon rather than a letterbox.
   Capsules B and G; the one bounded tuning pass is the remedy, and a cap
   breach is an escalation.
2. **Real monospace advance width, and therefore the column count.** The 4-column
   arithmetic rests on a 0.6 em advance in the device font. If the device font
   is wider, the row drops to 3 columns, gains a run, and costs roughly 79 dp
   more. The fit maths degrades safely — it never ellipsises — but the height
   cost is real. Capsules A, B, G.
3. **Whether three value steps read as three states in greyscale on a real
   panel.** The property test proves the ordering exists; only the greyscale
   capture proves it is visible at device brightness. Capsules A and C.
4. **Whether `— armed` on its own line reads as well as the inline suffix.**
   A legibility judgement, not a behaviour. Capsule C.
5. **Timeline density.** Cells widen from 44 to 76 dp, so fewer activations are
   visible before scrolling. The scroll proof is automated; whether four
   visible activations are enough is a device judgement. Capsule B.
6. **Whether the full-bleed map reads better than the inset one**, and whether
   the hairlines are enough separation. Capsules A and B.
7. **AC12 by eye.** The grep rule and the pack-route test are strong evidence,
   but only capsule F confirms no other screen moved a pixel.
8. **AC17** is an architect judgement taken after the capsules, not an
   implementation outcome.

## Authorization

The contract is approved. **This plan does not authorize production
implementation until the user separately approves it.**

## Correction C1 — the chip fit rule is unsound, and the budget was wrong

Recorded 2026-09-17, after Tasks 01–03 were implemented and the `packages/app`
suite was green on `residuum-visual-reboot-12` (all work uncommitted; base
`60909e60ec3150cf9b590e6641a8ae51efca775c`). The approved contract and WHAT are
unchanged and are not reopened here. What is corrected is region D's **fit
maths** and this plan's **vertical-space budget**, both of which were this
plan's own decisions and both of which were wrong. The armed caption stays a
reserved line, not an inline suffix; that reasoning is intact.

Executed by `plan-tasks/04-chip-fit-correction.md`. Nothing else in Tasks 01–03
is reopened.

### The defect

`_labelLines` / `_fitFor` (`packages/app/lib/game/crawl_action_row.dart:126-166`)
choose one column count for the whole row by walking `crawlChipMaxColumns` down
to 1 and returning the **first** count whose worst label lays out within
`crawlChipMaxLabelLines`. Wrap count is not monotonic in width, so first-fit is
unsound. Five further faults sit in the same twenty lines; all six are the same
mistake — **the rule estimates what it could measure, and then searches
unsoundly over the estimate.**

1. **First-fit over a non-monotonic function.** A wider chip can need *more*
   lines, so the first accepted count is not the shortest row, and a single
   long verb can drop the row from four columns to two and triple its run
   count.
2. **The broken-word guard is inoperative.** `_labelLines` rejects a candidate
   when `painter.width > content + 0.5`. Skia breaks a word that cannot fit a
   whole line rather than overflowing it, so `painter.width <= content`
   *always* holds and the guard can never fire. The rule therefore permits
   mid-word breaks, and one is on screen today: at four columns
   `✳ Firebolt 2` renders as `✳ Fireb` / `olt 2` (measured: content 76.4 dp,
   `minIntrinsicWidth` of the label 96.0 dp). That is a live AC9 violation in
   a currently green scene.
3. **`crawlChipPadding` is reserved but never applied.** `_fitFor` measures at
   `width - crawlChipPadding * 2`; `_ActionChip` renders the label with no
   horizontal padding, at the full chip width. Measurement and render disagree
   by 16 dp, and the label can touch the hairline border.
4. **Height is estimated by constant.** `chipHeight` uses
   `lines * crawlChipLabelLineHeight` (15 dp). The suite's font has a 12.0 dp
   line box, so the row over-reserves by 3 dp per line; a real monospace at
   12 px has a ~15.8 dp line box (Roboto Mono: 1.319 em), so on device the row
   **under**-reserves and clips the descenders of a two-line label.
5. **The armed caption is never measured.** `— armed` in `crawlCaption` is
   77.0 dp wide in the suite's font. Once the reserved padding of fault 3 is
   actually applied, a four-column row gives the caption 76.4 dp and it wraps
   inside a 15 dp reserve.
6. **The measurement uses a style it cannot vouch for, and ignores text
   scale.** Every label is measured in `crawlChipLabel` (w500) although a
   disabled chip renders w400 and an armed chip w600, so on any face where
   weight changes advance the reserved block is wrong for two of the three
   states; and the painter is built with no `textScaler` while `Text` honours
   the ambient one. Measured at `TextScaler.linear(1.3)`, `✳ Firebolt 2` needs
   3 lines and 48.0 dp where the row reserved 2 lines and 30 dp.

### Measured evidence

Architect measurement at the current tree, `onAPhone` (411.4 × 923.4 dp, no
insets), `crawlChipLabel`, per candidate column count. `w` is the *content*
width `(available − 6·(c−1))/c − 16` with `available = 411.4 − 24`; `n` is the
laid-out line count:

| label | c5 w=56.7 | c4 w=76.4 | c3 w=109.1 | c2 w=174.7 | c1 w=371.4 |
|---|---:|---:|---:|---:|---:|
| `✳ Firebolt 2` | 3 | **2** | **3** | 1 | 1 |
| `✳ Frost Lance 3` | 4 | 4 | **2** | 2 | 1 |
| `✚ Mend 3` | 3 | 2 | 1 | 1 | 1 |
| `Drink (2)` | 3 | 2 | 1 | 1 | 1 |
| `Wait` | 1 | 1 | 1 | 1 | 1 |

Independently reproduced and extended by a throwaway probe outside the
repository (`/tmp/fitprobe`, a bare `flutter_test` package; no repository file
was touched). It settles the mechanism and the numbers the revised budget is
built from:

- the suite's `monospace` fallback is a **1.0 em fixed pitch** face: one glyph
  is 12.0 dp wide and 12.0 dp tall at `fontSize: 12`; `crawlCaption` at
  `fontSize: 11` gives an 11.0 dp line box and a 77.0 dp `— armed`;
- `didExceedMaxLines` is `false` for every label at every candidate width, so
  the delivered `_expectNoClippedLabels` helper cannot fail — it is a vacuous
  assertion;
- `minIntrinsicWidth` (the widest unbreakable word) is only trustworthy when
  read from a layout at **unbounded** width. After a break-all layout it
  reports the widest *rendered* fragment: `Leave` reports 12.0 dp at content
  56.7 dp and 60.0 dp at content 371.4 dp;
- the non-monotonicity is exactly break-all: at c4 `✳ Firebolt 2` reaches two
  lines only by splitting `Firebolt`, while at c3 the word survives whole and
  the label needs three lines;
- at `TextScaler.linear(1.3)` the same label needs 3 lines / 48.0 dp; at 2.0,
  5 lines / 120.0 dp.

**Chrome anchors** measured by the architect on the current tree, and the
decomposition they force. With the delivered formula a chip is
`12 + 18 + 4 + 2·15 + 15 = 79` dp tall and a run adds
`crawlChipRunSpacing = 4`:

| scene | known spells | columns | runs | chip block | chrome |
|---|---|---:|---:|---:|---:|
| four spells without Frost Lance | firebolt, mend, ward, bind | 4 | 3 | 245 | **559** |
| four spells with Frost Lance | firebolt, frost-lance, mend, + 1 | 2 | 6 | 494 | **808** |

`808 − 494 = 559 − 245 = 314`. The **fixed chrome** of an 11-chip combat scene
with three note sentences — status, timeline, the two map hairlines, the log
peek, the action row's own vertical padding and the notes — is therefore
**314 dp**, of which the three notes are ~60 dp and the four other regions plus
the row padding are ~254 dp. Every revised number below is built on that
measured decomposition rather than on the old estimate table, which predicted
~285 dp for the whole worst-density action row and was wrong by roughly a
factor of two.

### Decision — measure the row, then choose the shortest legal layout

Directions 1 and 3 of the correction brief, together, plus the measurement
faults 2–6. One rule:

> `CrawlActionRow` measures every label once at unbounded width in **the
> heaviest style that label can ever render** — `crawlChipLabelArmed` for an
> armable verb, `crawlChipLabel` otherwise — with the ambient `TextScaler`.
> Measuring the label's *current* state instead would make the row's height a
> function of which chip is armed, and on a proportional-weight face arming
> would reflow the `Expanded` map: the same defect the reserved caption line
> exists to prevent. It then
> evaluates **every** candidate column count from `crawlChipMaxColumns` down to
> 1, discards any candidate whose content width cannot hold the widest word of
> any label or the `— armed` caption on one line, discards any candidate that
> pushes a label past `crawlChipMaxLabelLines`, and keeps the survivor with the
> least **measured** total row height — `runs · chipHeight + (runs−1) ·
> crawlChipRunSpacing`, with `chipHeight` built from the measured label block
> and the measured caption rather than from a per-line constant. Ties keep the
> larger column count. `crawlChipPadding` becomes real padding around the label
> so the measured width is the rendered width.

`crawlChipMaxLabelLines` rises from 2 to 3: measured, a three-line label at
three columns costs 336 dp of chips at worst density where a two-line label at
two columns costs 434 dp. The ceiling is a clipping bound, not a design
preference, and raising it is what lets the row degrade by one label line
instead of by three runs. `crawlChipLabelLineHeight` is deleted — the line box
it guessed is now measured.

**Why soundness is load-bearing and not tidiness.** With a minimising rule the
suite's measurement becomes an *upper bound* on the device's: a narrower face
weakly reduces every label's line count at a fixed content width, so every
candidate's height is weakly smaller, so the minimum is weakly smaller. The
suite's fallback is 1.0 em per glyph and no real Latin face — monospace or
proportional — exceeds that per glyph, so the suite bounds the device. Under
first-fit no such bound exists: a *narrower* font can flip first-fit onto a
different, taller branch, which is the same unsoundness that produced 808 dp.

### Rejected alternatives

- **Direction 2, bound the label — rejected on measurement.** Moving the school
  marking and the mana cost out of the wrapping label does not make the
  wrapping text one token: `Frost Lance` is itself two words, and the widest
  word in the game stays `Firebolt` (96.0 dp in the suite's font, 57.6 dp at
  0.6 em), which is what caps the column count. The two forms that could pay
  for themselves both cost more than they save: a fixed marking/cost detail row
  adds a line to *every* chip in *every* scene, including the exploration rows
  that have no spells, and folding the marking and cost into the icon row only
  helps if the name itself then fits one line, which `Frost Lance` does not at
  four columns on either font. Measured, the change is worth 0 dp on device and
  is not worth changing what a chip says.
- **Shrink-to-fit labels (`FittedBox(BoxFit.scaleDown)`, the idiom
  `crawl_status.dart` and the timeline cells use) — rejected.** It would make
  every column count legal, but chip type size would then vary with scene
  density, which contradicts the shared-metrics reading of AC4 and the type
  ladder's authority, and it degrades legibility silently exactly where AC9
  demands it. The idiom is right for a place name that must not ellipsise; it
  is wrong for the row whose job is to be readable under a thumb.
- **Raising the cap and keeping first-fit — rejected.** The 560 dp cap is not
  the error; the search is. Keeping an unsound search would leave the row's
  height a function of which verbs happen to be applicable.
- **A horizontally scrolling or paged action row — rejected.** Already a named
  escalation in this plan and a contract violation (every applicable verb
  visible).

### Revised vertical budget

Chip geometry after the correction:
`chipHeight = 2·crawlChipVerticalPadding (12) + actionIconSize (18) +
crawlRhythm (4) + measured label block + measured caption reserve`.

**Suite figures** (`onAPhone`, 1.0 em fallback face, chrome height = surface −
map slot). `label block` and `caption` are measured line boxes, 12.0 and
11.0 dp:

| scene | chips | notes | cols | label block | caption | chip h | runs | chip block | fixed | chrome |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| exploration, typical | 5 | 2 | 3 | 12 | 0 | 46 | 2 | 96 | 202 | ~298 |
| exploration, worst | 6 | 3 | 3 | 12 | 0 | 46 | 2 | 96 | 218 | ~314 |
| combat, typical | 7 | 0 | 3 | 36 | 11 | 81 | 3 | 251 | 254 | ~505 |
| combat, worst legal | 11 | 3 | 3 | 36 | 11 | 81 | 4 | 336 | 314 | ~650 |

`fixed` is the 254 dp measured decomposition (status + timeline + hairlines +
peek + row padding) minus the ~96 dp timeline in exploration, plus ~60 dp for
three notes and ~44 dp for two. The 96 dp timeline split is this plan's own
estimate and is the one unmeasured term; Task 04 records the measured values
and corrects this table if they differ.

**Asserted suite caps**, with the margin each carries over the figure above and
the height of one chip run in that scene:

| assertion | cap | expected | margin | one run |
|---|---:|---:|---:|---:|
| exploration, worst density | 360 | ~314–330 | ~30–46 | 50 |
| combat, typical density | 560 | ~505 | ~55 | 85 |
| combat, worst legal density | 720 | ~650–670 | ~50–70 | 85 |

Every margin is smaller than one run, so a regression that adds a run breaks
its cap. The caps are set *after* the fixture is chosen by rule, never the
other way round.

**Device figures** (`Medium_Phone`, ~844 dp inside the `SafeArea`), modelled
from a 0.60 em advance and a 1.32 em line box — the Roboto Mono / Droid Sans
Mono class that Android's `monospace` resolves to. These are the numbers AC14
is actually about, and they are the device pass's to measure:

| scene | cols | chip h | runs | chip block | fixed | chrome | map | map rows at 36 dp |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| exploration, worst | 4 | 49.8 | 2 | ~104 | ~217 | **~321** | **~523** | ~14 |
| combat, typical | 4 | 80.1 | 2 | ~164 | ~254 | **~418** | **~426** | ~11 |
| combat, worst legal | 4 | 80.1 | 3 | ~248 | ~313 | **~561** | **~283** | ~7 |

**Device escalation thresholds** (measured, recorded, not asserted by the
suite): exploration worst > 360 dp of chrome, combat typical > 460, combat
worst legal > 600 dp (map < 244 dp). The old 560 dp cap was, by accident, about
right for the *device*; what it could never be is a suite assertion.

**What the executor may still tune** is unchanged except that
`crawlChipLabelLineHeight` leaves the list (it no longer exists) and
`crawlChipMaxLabelLines` joins it with envelope 2–4.

### AC14 verdict, plainly

Worst-density combat **can** show every applicable verb and still leave a
usable map, but ~283 dp is this unit's floor and it is a floor, not comfort: at
`cameraCellSize = 36` that is about 7 rows by 11 columns with the hero centred,
so three tiles of sight above and below. Melee is adjacent and targeting is
centred, so the scene that produces this density is also the scene that needs
the least map. Nothing ellipsises, no word breaks, no verb hides. The scene
itself is rare: the bottom floor, standing on the up stairs, a gather node and
loot underfoot, a full pack, every spell in the game known, and a monster
holding reach.

If capsule G judges ~283 dp unplayable, the remedy is **not** a bigger cap. The
choices are contract-level, in the order this plan would recommend them:

1. **Amend the visibility rule for exploration verbs during an open battle** —
   let `Pick up`, the gather verb, `Ascend`/`Descend` and `Leave`/`Finish`
   stand down while a monster holds reach, or move them behind the existing
   overflow. This drops the worst row from 11 chips to 6, from three runs to
   two on device, and is the only remedy that scales with density. It amends
   the inherited lock "a control appears exactly when it applies" and AC9.
2. **Amend a sibling region's floor** — shrink `crawlLogPeekHeight` from 104,
   or collapse the log peek while a battle is open. That touches AC8 and the
   four-region responsibility lock.
3. **Amend AC4's chip anatomy at density** — drop the 18 dp icon slot when the
   row exceeds two runs, worth ~18 dp per run.
4. **Accept ~283 dp at the rarest density** and record the acceptance.

### What the suite proves, and what only `Medium_Phone` can

The suite proves, font-independently: one column count per row; even chip
widths and heights; no label past the line ceiling; no word broken (rendered
paragraph width ≥ its own `getMinIntrinsicWidth(double.infinity)`); no chip run
left short of the width's capacity; that a longer verb costs at most one run;
that the row survives a text scale the measurement must honour; and chrome
under the three suite caps — which, because the rule minimises measured height
and the suite's face is 1.0 em per glyph, is an **upper bound** on the device's
chrome rather than an estimate of it.

Only the `Medium_Phone` pass settles: the real advance and line box of the
device's `monospace`, and therefore which column count and how many runs the
device actually chooses; whether ~283 dp of map plays as a dungeon; whether the
marking glyphs `✳ ✚ ⛒` and the caption's em dash resolve within one cell in the
device's fallback chain; and whether a three-line label ever appears there at
all (modelled, it does not — it is a suite-font and text-scale artefact).

The device pass must report, per capsule A, B and G: measured chrome and map
height in dp, the chip width and height it observed, the number of runs, the
greatest label line count, whether any word is split across lines, whether any
label touches its border, and the `Drink`/`Pack` counts and known-spell set the
scene actually had.

### Plan quality gate — Correction C1

- **COR — PASS.** All six faults in the rule are named with measured evidence
  and each has a specified remedy; the search is now total over its candidate
  set with an explicit, measured legality predicate; the word guard is read
  from the only layout where it is trustworthy; measurement and render share
  one width, one text scaler and one state-independent style per verb — so
  arming cannot reflow the map; the degenerate case is
  specified and is an escalation rather than a silent clip.
- **TTC — PASS.** Four Red proofs are named with the failure each must show on
  the current tree (chrome 808 > 720; a split `Firebolt`; a 249 dp label-set
  swing; a text-scale overflow), the vacuous `didExceedMaxLines` helper is
  replaced rather than re-pinned, the AC14 fixture is chosen by a stated
  maximality rule instead of by which one passes, and each cap carries a margin
  smaller than one chip run.
- **CRF — PASS.** The correction stays inside `_fitFor`, `_labelLines` and
  `_ActionChip` plus two seam constants; `CrawlActionRow`'s public interface,
  `game_screen.dart` and every player-facing string are untouched; one painter
  per label per build, reused across candidates and disposed; one deleted
  constant, no new abstraction.
- **SEC — SKIP.** Presentation-only, offline, no new input, file, network or
  trust boundary.

Residual risk deliberately left to device evidence: the modelled 0.60 em /
1.32 em device metrics, and the judgement on ~283 dp of map.
