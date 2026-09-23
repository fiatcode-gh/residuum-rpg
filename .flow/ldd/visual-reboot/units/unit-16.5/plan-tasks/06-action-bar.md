# 06 — Five-slot action bar, action marks, crawl screen skeleton

Governing: `../CONTRACT.md` settled decision 3, scope item 4.7, acceptance
6–7; `../PLAN.md` §2 G8 (skeleton, action bar, notes), G9. Work from
`packages/app`.

## Starting repository state

Task 05 committed. `GameScreen` column: `CrawlStatus`, battle `BattleDock`,
`Expanded` map slot (foreground hairline top/bottom border), `LogPeek`
(104 dp), `CrawlActionRow(notes, actions)` whose `_fitFor` picks a column
count and grows with action count; `CrawlAction.icon` is `ActionIcon?`;
`_actionsFor` order/ids/dispatch as in `game_screen.dart`.

## Owned files

`lib/game/crawl_action_row.dart` (rewritten as the bar; keep the file name
and `actionRowKey`, `readiedSpellCount`, `CrawlAction`), `lib/game/action_icon.dart`,
`lib/game/crawl_style.dart` (retire chip constants, add bar/skeleton
constants and `crawlScale`), `lib/game/game_screen.dart` (skeleton,
`_actionsFor` marks, notes overlay); tests
`test/widget/crawl_action_row_test.dart`, `test/widget/crawl_controls_test.dart`,
`test/widget/battle_shelf_icons_test.dart`, `test/widget/craft_surfaces_test.dart`,
`test/widget/crawl_layout_test.dart` (only what the skeleton breaks), plus
any test asserting chip sizes/columns/fit, new
`test/support/phone.dart::onTheTargetPhone`.

Non-goals: header, timeline, panels, log (later tasks keep their current
widgets in the new skeleton).

## Locked decisions

1. Skeleton (PLAN G8) in `GameScreen`, inside `SafeArea` and
   `MediaQuery.withClampedTextScaling(maxScaleFactor: 1.3)`:
   `Stack[Column[CrawlStatus (unchanged for now), if battle BattleDock (unchanged), Expanded(Stack[Column[Expanded(map slot keyed dungeonSceneSlotKey, no border decoration), SizedBox(7), LogPeek (unchanged), SizedBox(7)], if extent != peek LogDrawer]), CrawlActionBar, SizedBox(6)], if game over _DeathOverlay]`.
   (Tasks 08/09 insert the panel + 6 dp gap above the peek.) The
   `LogDrawer` keeps its current internals; it now overlays only the inner
   Stack, so the bar stays visible.
2. `crawl_style.dart`: delete `crawlChip*` constants, `CrawlChipState`,
   `CrawlChipSkin`, `crawlChipSkin`, `crawlChipLabel*`, `crawlCaption`
   (move any surviving consumer to a G2 role). Add
   `crawlGutter = 8`, `crawlGap = 7`, `crawlBottomGap = 6`,
   `crawlActionBarHeight = 60`, `crawlSlotGap = 7`, `crawlSlotPeek = 18`,
   `crawlSlotMark = 22`, and
   `double crawlScale(BuildContext context) => (MediaQuery.textScalerOf(context).scale(12) / 12).clamp(1.0, 1.3);`
   plus `enum CrawlSlotState { available, disabled, armed }`.
3. `action_icon.dart`: `sealed class ActionMark`, `ShippedMark(ActionIcon icon)`,
   `FontMark(IconData icon)`, `ActionMarkView(ActionMark mark, {double size})`
   (shipped → current `Image.asset` rule, untinted, `excludeFromSemantics`;
   font → `Icon(icon, size, color: crawlGold)` inside `ExcludeSemantics`),
   `ActionMark spellMark(Spell spell)` per PLAN G9. `ActionIconImage` and
   `actionIconSize` are removed if no consumer remains (grep).
4. `CrawlAction`: `id`, `label`, `onPressed`, `metadata`, **required
   `mark`**, `armable`, `armed`. `_actionsFor` keeps every guard, id, label,
   metadata and dispatch byte-for-byte and assigns marks per PLAN G9
   (gather mark by `state.nodeUnderfoot`: oreVein `hardware`, herbPatch
   `spa`; leave-dungeon `flag` when `ending` else `logout`).
5. `CrawlActionBar({required List<CrawlAction> actions})` keyed
   `actionRowKey`, height `crawlActionBarHeight × crawlScale`, horizontal
   padding `crawlGutter`, geometry and slot states exactly PLAN G8 action
   bar (≤5: equal slots + empty frames; >5: 64.7 dp slots, 18 dp peek,
   `SingleChildScrollView` + `ClampingScrollPhysics`). Slot = `Semantics(button, enabled, label: label[ + ' ' + metadata], onTap)` over `ExcludeSemantics(Material + InkWell)`; keyed `ValueKey(action.id)`; duplicate-id assert kept. Metadata line shows `— armed` when armed.
6. Notes: `CrawlActionBar` no longer takes notes; `_notesFor(state)` renders
   as the G8 notes overlay inside the map slot's Stack (top-left,
   `IgnorePointer`), texts and order unchanged.
7. `test/support/phone.dart` adds
   `Future<void> onTheTargetPhone(WidgetTester tester)`: `physicalSize (1080, 2408)`,
   `devicePixelRatio 2.75`, `tester.view.padding = FakeViewPadding(top: 104, bottom: 66)`,
   reset on tear-down (Main may update the padding after Checkpoint A).

## Proof (Red first)

In `crawl_action_row_test.dart` (rewrite; delete fit/600 dp/cap/text-scale
reservation tests — they pin the retired algorithm):
- the bar height is 60 at scale 1.0 for 1, 3, 5 and 12 actions, and the
  map slot rect is identical across 1 and 12 actions (`onTheTargetPhone`);
- ≤5 actions: slot width `(W − 28)/5` ± 0.5 and `5 − n` inert frames that
  are absent from semantics and do not respond to taps;
- 12 actions: slots 1–5 fully inside the bar, slot 6 visible for exactly
  18 ± 0.5 dp at scroll 0; after `tester.drag` to the end, the last slot is
  fully visible and tapping it dispatches its action;
- arming a spell slot: frame colour `crawlCold`, label role `textSlotArmed`,
  metadata text `— armed`; map rect unchanged armed vs unarmed;
- ids unique (assert), labels/metadata/ids/dispatch identical to the
  pre-change `_actionsFor` for the three staged scenes in
  `crawl_controls_test.dart` ("no control is added, removed, renamed or
  reordered" stays green);
- each action shows its G9 mark (`find.byIcon` / shipped `Image` path);
  a game-over Drink slot is disabled but visible with its word and mark;
- notes render inside the map slot rect and the map rect does not change
  when a note appears.
Expected Red: `CrawlActionBar`/`ActionMark` missing; the old row grows with
action count.
Green: `flutter test test/widget test/battle_view_test.dart test/battle_characterization_test.dart test/battle_flow_characterization_test.dart`,
`dart format <touched>`, `flutter analyze`.

## Executor discretion

Slot widget decomposition; how the inert frames are drawn; test fixture
construction; whether the skeleton keys new `SizedBox` gaps.

## Escalate when

Any action's guard/label/id/dispatch would have to change; a label cannot
fit even scaled down to 0.7; the inner-Stack drawer steals taps from the
bar; an existing non-crawl test changes.

## Completion receipt

Red output, Green command/exit, analyzer/format exits, measured slot widths
and peek at 12 actions, deleted-test list with reasons. Commit:
`feat(app): replace the fitted chip row with a fixed five-slot action bar`.
