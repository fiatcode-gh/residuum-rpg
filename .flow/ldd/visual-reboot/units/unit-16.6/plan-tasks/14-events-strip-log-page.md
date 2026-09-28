# 14 — Events strip over the map, the full log page, and no step line

Governing: `../CONTRACT.md` (amended 2026-09-28) settled decision 12, scope
§1 item 2, scope §4a, the protected-boundary exception (the hero's step
writes no line), acceptance 1, 8, 9; `../PLAN.md` §10 (G15, 10.1 figures,
10.6 defaults D9–D13), G10, G11. Work from `packages/app`.

## Starting repository state

Branch `residuum-visual-reboot-16.6` with Task 13 committed (`feat(app):
move moment actions into an ACTIONS bar below the map`). Check:
`git diff --stat 7d99bea -- packages` shows only Task 13's paths
(`action_bar.dart`, `game_screen.dart`, `map_overlays.dart`,
`map_overlay_layout.dart`, `crawl_style.dart` and their tests); anything
else → escalate. The user's untracked `tmp1.png` is not yours.

What exists after Task 13:

- `game_screen.dart`: `PopScope(onPopInvokedWithResult → SystemBackPressed)`;
  Column `[CrawlHud, Expanded(LayoutBuilder → Stack[Column[Expanded(key:
  dungeonSceneSlotKey, … Stack[DungeonSceneHost, MapOverlays]),
  SizedBox(crawlPanelGap), LogRow(key: logRowKey), SizedBox(crawlPanelGap)],
  if extent != peek: Positioned(LogDrawer, half = crawlLogSheetHeight × s
  or full)]), ActionBar(key: actionBarKey), SizedBox(crawlGap), CrawlMenu,
  SizedBox(crawlBottomGap)]`, then `_DeathOverlay` on game over.
- `log_row.dart`: `logRowKey`, `LogRow` (104 × s, `LogPeek`).
- `log_drawer.dart`: `logPeekKey`, `logHandleKey`, `logDrawerKey`,
  `logCloseKey`, `logUnreadKey`, `logPictogram`, `logTint`, `LogPeek`
  (framed, `RECENT EVENTS`, `N entries`, last 4 lines), `_LogRow`,
  `LogDrawer` (+ `_LogDrawerState` follow/jump/unread), `_HandlePill`.
- `log_line.dart`: `LogCategory`, `enum LogDrawerExtent { peek, half, full }`,
  `LogLine`.
- `game_bloc.dart`: `LogDrawerHandlePulled` (cycles peek → half → full →
  peek, inert on game-over, clears inspection), `LogDrawerClosed`,
  `LogFollowBroken`, `LogFollowResumed`; `GameViewState(logDrawerExtent,
  logFollowing, logUnread)` with `_followsAt`; every handler passes
  `logDrawerExtent: state.logDrawerExtent`.
- `map_overlay_layout.dart`: `recenterRect(Size map)` (bottom-right
  square), `targetCardArea({map, strip})`; `map_overlays.dart` computes the
  turn-order strip rect inline (top band, flipped to `H − height` with width
  `W − 64` when the hero overlaps the top band).
- `event_messages.dart:23-24`: `ActorMoved` for the hero → `You step <dir>.`;
  `_bearing` at the end of the file has no other caller.
- `crawl_style.dart`: `crawlLogLine = 15`, `crawlLogRowHeight = 104`,
  `crawlLogSheetHeight = 345`, `crawlLogSheetHeader = 40`,
  `crawlLogRowPadding`, `crawlLogPictogram`.

## Owned files

- `git mv lib/game/log_drawer.dart lib/game/event_log.dart`;
  `git rm lib/game/log_row.dart`
- `lib/game/log_line.dart`, `lib/game/game_bloc.dart`,
  `lib/game/game_screen.dart`, `lib/game/map_overlays.dart`,
  `lib/game/map_overlay_layout.dart`, `lib/game/crawl_style.dart`,
  `lib/game/event_messages.dart`
- `git mv test/widget/log_drawer_test.dart test/widget/event_log_test.dart`;
  `git mv test/game/log_drawer_state_test.dart test/game/event_log_state_test.dart`;
  `git rm test/widget/log_row_test.dart`
- `test/widget/crawl_layout_test.dart`, `test/widget/action_bar_test.dart`
  (regions only), `test/game/map_overlay_layout_test.dart`,
  `test/widget/target_card_test.dart`, `test/game_bloc_test.dart`
  (lines ≈ 288–297, ≈ 2879–2896, ≈ 1410–1428), `test/game/log_line_test.dart`,
  `test/game/dungeon_scene_test.dart` (≈ 962), `test/turn_order_strip_test.dart`
  (≈ 248, ≈ 580), and any other test the full suite shows depending on the
  drawer, the peek, the log row or a hero step line
- `.flow/ldd/visual-reboot/units/unit-13/VISUAL-SYSTEM.md`, one blockquote
  (locked decision 10)

Non-goals: `packages/core`, `packages/content`, the action bar, verbs,
`cardVerbsFor`/`placeFacts`, map touch, the camera, the turn-order strip's
content, the target card's content, `LogCategory` values and every other
log sentence, the town and world screens.

## Locked decisions

1. **Composition** (`game_screen.dart`): Column `[CrawlHud,
   Expanded(key: dungeonSceneSlotKey, child: LayoutBuilder → Stack[
   DungeonSceneHost, MapOverlays]), SizedBox(crawlPanelGap),
   ActionBar(key: actionBarKey), SizedBox(crawlGap), CrawlMenu(key:
   crawlMenuKey), SizedBox(crawlBottomGap)]`; the outer Stack becomes
   `[Column, if (state.logOpen) Positioned.fill(child: LogPage(key:
   logPageKey, state: state, bloc: bloc)), if (game over) _DeathOverlay]`.
   The drawer `LayoutBuilder`/inner `Stack`, `LogRow` and its two gaps are
   deleted.
2. **Bloc** (`game_bloc.dart`, `log_line.dart`): delete `LogDrawerExtent`.
   `GameViewState` takes `bool logOpen = false`, stored as
   `logOpen = !game.isGameOver && logOpen`; `_followsAt(GameState game, bool
   open, bool following) => following || game.isGameOver || !open`; the
   `logFollowing`/`logUnread` initialisers keep their shape on it. Rename
   the field at every construction site (`logDrawerExtent:
   state.logDrawerExtent` → `logOpen: state.logOpen`). Events:
   `final class LogOpened extends GameBlocEvent` (handler: return on
   game-over or when already open; else emit the same carry-through state
   today's handle emits — game, log, autoPath, walkId, pan, armedSpellId,
   hasFled, actorIdentity, selectedActorId, follow, unread — with `logOpen:
   true` and no `inspectedActorId`); `final class LogClosed extends
   GameBlocEvent` (return when closed; else emit with `logOpen: false`).
   `LogDrawerHandlePulled`, `LogDrawerClosed` and their handlers are
   deleted; `LogFollowBroken`, `LogFollowResumed`, `_unreadAfter`
   unchanged. Stale dartdoc on the renamed/removed members is deleted, not
   rewritten (G11).
3. **Strip** (`event_log.dart`): `const eventsStripKey =
   Key('events-strip');`
   `EventsStrip({required GameViewState state, required GameBloc bloc,
   super.key})`: shown lines = last `min(3, log.length)` entries, oldest
   first; `Semantics(button: true, enabled: !gameOver, label: 'Open the
   message log') → GestureDetector(behavior: opaque, onTap: gameOver ? null
   : () => bloc.add(const LogOpened())) → DecoratedBox(decoration:
   crawlEventsStripDecoration) → Padding(fromLTRB(8, crawlEventsStripTop,
   8, crawlEventsStripBottom)) → Column(mainAxisAlignment: end, stretch)` of
   `SizedBox(height: crawlLogLine × s, Opacity(opacity:
   crawlEventsFade[age], Text(sentence, maxLines: 1, ellipsis, style:
   logTint(category))))` where `age = shown.length − 1 − index` (0 =
   newest, bottom). No title, count, icon or border.
4. **Constants** (`crawl_style.dart`): add `crawlEventsLines = 3`,
   `crawlEventsStripTop = 6`, `crawlEventsStripBottom = 4`,
   `const List<double> crawlEventsFade = [1.0, 0.7, 0.45]`,
   `const BoxDecoration crawlEventsStripDecoration = BoxDecoration(gradient:
   LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
   colors: [Color(0x000B1215), crawlCalloutFill]))`. Delete
   `crawlLogRowHeight`, `crawlLogSheetHeight`, `crawlLogSheetHeader`.
5. **Placement** (`map_overlay_layout.dart`, pure):
   - `Rect eventsStripRect(Size map, double scale)`: `h =
     crawlEventsStripTop + crawlEventsLines × crawlLogLine × scale +
     crawlEventsStripBottom`; `Rect.fromLTWH(0, map.height − h, map.width,
     h)` (55.0 at 1.0, 68.5 at 1.3).
   - `Rect recenterRect(Size map, {required Rect events})` =
     `Rect.fromLTWH(map.width − 8 − crawlTouchTarget, events.top − 8 −
     crawlTouchTarget, crawlTouchTarget, crawlTouchTarget)`.
   - `({Rect rect, bool flipped}) turnOrderStripRect({required Size map,
     required double height, required Rect hero, required Rect events})`:
     `top = Rect.fromLTWH(0, 0, map.width, height)`; `flipped =
     top.overlaps(hero)`; flipped rect `Rect.fromLTWH(0, events.top −
     height, map.width − 64, height)`, else `top`.
   - `Rect targetCardArea({required Size map, required Rect events, Rect?
     strip})`: `stripAtTop = strip != null && strip.center.dy < map.height /
     2`; `top = stripAtTop ? strip.bottom : 0`; `bottom = strip != null &&
     !stripAtTop ? strip.top : events.top`.
6. **Overlays** (`map_overlays.dart`): `events = eventsStripRect(size,
   crawlScale(context))`; strip rect/flip from `turnOrderStripRect(…,
   height: crawlStripHeight × s, …)`; recenter from `recenterRect(size,
   events: events)`. Children in paint order, each `Positioned`: turn-order
   strip (battle; `flipped:` passed as today); `if (state.log.isNotEmpty)
   Positioned.fromRect(rect: events, child: EventsStrip(key: eventsStripKey,
   …))`; `Positioned.fill(TargetCard(area: targetCardArea(map: size, events:
   events, strip: stripRect), avoid: [?recenter]))`; recenter pill.
7. **Page** (`event_log.dart`): `const logPageKey = Key('log-page');`
   `LogPage` is today's `LogDrawer` renamed (state class `_LogPageState`),
   keeping `_followTolerance`, the controller, `initState`/`didUpdateWidget`/
   `_maybeJumpToNewest`/`_jumpToNewest`/`_onScroll`, the `RawScrollbar` +
   `ListView.builder` of `_LogRow`, and the `logUnreadKey` pill verbatim.
   Its frame becomes `BlockSemantics(child: Material(color: crawlPanelFill,
   child: Padding(horizontal: gutter, Column[header, hairline divider,
   Expanded(list stack)])))`. Header: `SizedBox(height: crawlTouchTarget,
   Row(center)[Text('RECENT EVENTS', displaySheetTitle), Spacer,
   Text('$count entries', monoMeta), SizedBox(gutter), Semantics(button,
   label: 'Close the message log', GestureDetector(key: logCloseKey,
   behavior: opaque, onTap: LogClosed, SizedBox(48 × 48,
   Icon(Icons.close, 18, crawlTextDim))))])`. `_HandlePill`, the handle
   gesture, `logHandleKey` and the sheet's rounded top are deleted.
8. **Back** (`game_screen.dart` `PopScope`): `if (didPop) return; final
   bloc = context.read<GameBloc>(); bloc.add(bloc.state.logOpen ? const
   LogClosed() : const SystemBackPressed());`.
9. **Step line** (`event_messages.dart`): delete the `ActorMoved(...) when
   actorId == heroId` arm and `_bearing`. `ActorMoved() => null` stays.
10. **Docs** (`VISUAL-SYSTEM.md`, the blockquote starting
    `**Superseded by Unit 16.6 (2026-09-24):** the chrome is one fixed`,
    ≈ line 224 before Task 13's rewrap): heading `(2026-09-24, amended
    2026-09-28)`; "(HUD, map, log row, bottom menu)" → "(HUD, map with the
    events strip over its bottom edge, action bar, bottom menu)". Nothing
    else.
11. **Deleted** (zero hits in `lib` and `test` at handoff): `LogDrawerExtent`,
    `logDrawerExtent`, `LogDrawerHandlePulled`, `LogDrawerClosed`,
    `LogDrawer`, `logDrawerKey`, `LogPeek`, `logPeekKey`, `logHandleKey`,
    `_HandlePill`, `LogRow`, `logRowKey`, `log_row.dart`, `log_drawer.dart`,
    `crawlLogRowHeight`, `crawlLogSheetHeight`, `crawlLogSheetHeader`,
    `_bearing`, `You step`. No new dartdoc or body comments in
    `packages/app`.

## Proof (Red first; behaviour and geometry, never retired presentation)

Expectations come from the map slot rect, the menu and bar rects, the
SafeArea body, `GridGeometry`, the literal margins (8), the literal strip
height `10 + 45 × s` (55.0 / 68.5) and the literal fades — **never from
`eventsStripRect`, `recenterRect` or `turnOrderStripRect`** in widget tests.

**Red (record before any production edit), all compiling at the Task 13
head via literals:** `find.byKey(const Key('events-strip'))` findsOneWidget
over a seeded log (fails: absent); `find.byKey(const Key('log-row'))`
findsNothing (fails: present); tapping the strip literal key then
`find.byKey(const Key('log-page'))` findsOneWidget (fails); the rewritten
bloc test "a tap on an adjacent tile moves the hero and writes nothing to
the log" (fails with `['You step east.']`). Record the output. After Green
the literals may be replaced by the constants.

- `event_log_state_test.dart` (migrated): fresh → closed, following, 0;
  `LogOpened` opens and a second is silent; `LogClosed` closes and a second
  is silent; the carry-through test uses `LogOpened`, `LogFollowBroken`,
  `LogClosed`; follow holds while open; follow off counts exactly the
  appended lines; resume clears; closing while follow is off resumes and
  clears; a turn does not close the page; a lethal turn closes it, resumes
  follow, clears the count, and `LogOpened` after death emits nothing; the
  constructor invariant holds for `logOpen: true` on game-over. The cycle
  test and the "cycling back to peek" test are deleted (no cycle exists).
- `event_log_test.dart` (migrated from `log_drawer_test.dart`, same
  `_pushGame` harness, `onTheTargetPhone`):
  - strip geometry: map-local rect `left 0`, `width == map.width`,
    `bottom == map.height`, height `closeTo(55.0, 0.01)` at 1.0 and
    `closeTo(68.5, 0.01)` at 1.3; identical in exploration, Watched and
    battle.
  - lines: with 5 seeded lines, exactly the last three sentences appear
    inside `eventsStripKey`, top-to-bottom oldest → newest; their `Opacity`
    ancestors read 0.45, 0.7, 1.0; each `Text.style == logTint(category)`;
    with 1 line it sits in the bottom slot; no `RECENT EVENTS`, no
    `entries` text and no `DecoratedBox` whose decoration has a border
    inside the strip; at 1.3 the three lines are unclipped (natural-height
    check kept from the peek test).
  - input: empty log → `eventsStripKey` findsNothing, and a tap at the
    centre of the map's bottom 55 dp band on a floor cell reaches the map
    (hero steps or walks per G4); with lines, a tap inside the strip opens
    the page and leaves the hero in place; a tap on the floor cell just
    above `strip.top` next to the hero steps; a drag that starts above the
    strip pans; game over → the strip's tap is inert.
  - page: `logPageKey` rect equals the SafeArea body (top `closeTo(34.9,
    0.5)`, bottom `closeTo(surface − 18, 0.5)`, full width) and covers the
    HUD, bar and menu rects; a tap on the map area while open does not move
    the hero; close control is ≥ 48 × 48 and closes; system back
    (`tester.binding.handlePopRoute()`) while open closes and appends no
    line; system back while closed appends the refusal (existing
    back-guard sentence); the map, bar and menu rects are identical before,
    during and after the page. Pictogram, row layout, follow, unread pill
    and empty/one-line render tests migrate from the drawer to the page
    (open via the strip or `LogOpened`), bodies otherwise unchanged. The
    half-extent geometry test and the "action row stays hit-testable while
    the drawer is open" test are deleted (retired surfaces).
- `map_overlay_layout_test.dart`: `eventsStripRect` literal rects at 1.0 and
  1.3; `recenterRect(events:)` `bottom == events.top − 8`, `right ==
  map.width − 8`; `turnOrderStripRect` top when clear, flipped with `bottom
  == events.top` and `width == map.width − 64` when the hero is in the top
  band, and the flipped rect never overlaps `recenterRect`; `targetCardArea`
  literal cases (no strip → `bottom == events.top`; top strip; flipped
  strip). Sweep on the final map: target-card heights for 2–4 lines at
  s 1.0 and 1.3, maps `392.7 × (probe s 1.0)`, `392.7 × (probe s 1.3)` and
  `392.7 × 545.8` (device estimate), strips from `turnOrderStripRect` and
  `eventsStripRect`. Assert at **both** scales: misses the turn-order strip,
  the events strip, the hero cell and the target cell. D1 case updated to
  the final map with the events strip.
- `crawl_layout_test.dart`: regions → HUD, map, 6, bar, 7, menu, bottom gap
  (no log row); the four-state identity test drops the log row; the
  log-extent cycling test becomes "opening and closing the log page leaves
  the map, bar and menu rects unchanged"; the crowded 1.3 battle still has
  no exception. `action_bar_test.dart` regions assertion becomes
  `map.bottom + 6 == bar.top`.
- `target_card_test.dart`: a monster two rows above the map's bottom edge,
  inspected, with a seeded log → the card misses the events strip and the
  hero block; the F3 test also asserts no overlap with `eventsStripKey`.
- `game_bloc_test.dart`: the adjacent-tap test expects an empty log; the
  ambush test expects `[The ghoul gets the drop on you., The ghoul claws you
  for 3.]`; "pulling the log handle clears the inspected actor" → "opening
  the log clears the inspected actor" with `LogOpened`.
- `log_line_test.dart`: "refusal is distinguished from movement" drops the
  hero `ActorMoved` (five events, `[refused, moved, moved, refused,
  refused]`); "the three silent variants" → "the four silent variants stay
  silent" adding the hero's `ActorMoved`. The totality test is unchanged.
- `dungeon_scene_test.dart` (`withDrawerOpen` → `logOpen: true`),
  `turn_order_strip_test.dart` (`logPeekKey` presence → `actionBarKey`
  presence): mechanical.
- Any other suite failure from the missing step line: rewrite the test to
  its behaviour (seed the log, or use `WaitPressed`, which logs), never
  re-add a step sentence.

**Mutation witnesses (required, after Green).** `sha256sum` snapshot of
`lib/game/map_overlay_layout.dart`, `lib/game/event_log.dart`,
`lib/game/map_overlays.dart` and `lib/game/game_screen.dart` (copies
outside the tree), then one at a time: M1 `eventsStripRect` ignores `scale`
→ the 1.3 strip-height test fails; M2 `recenterRect` ignores `events` →
the recenter test and the widget page/strip test fail; M3 `targetCardArea`
bottom `= map.height` → the sweep and the target-card widget test fail; M4
strip lines newest first → the order test fails; M5 strip shown for an
empty log → the empty-log tap test fails; M6 back always
`SystemBackPressed` → the back-closes-page test fails; M7 flipped strip at
`map.height − height` → the flip test fails. Restore each from its
snapshot copy (never from git); show restored hashes equal the snapshot.
A surviving mutant means a missing assertion: add it before handoff.

**Green:** `dart format <touched Dart files>`, `flutter analyze`, full
`flutter test`. Map, bar and strip figures and the sweep map sizes come
from an **untracked** probe, deleted afterwards (`git status --short
packages/app/test` shows no untracked file).

## Executor discretion

Widget decomposition in `event_log.dart`; the order of mechanical renames
in `game_bloc.dart` (an AST or sed pass is fine, then read the diff);
fixture helpers; which floor cell and pan prove the above-strip tap and
drag, as long as the precondition (the cell's rect is above `strip.top`) is
asserted.

## Escalate when

- the start-state diff has anything beyond Task 13's paths;
- keeping follow/unread semantics would need a change to `_unreadAfter` or
  to when lines are appended;
- the final-map sweep finds any hit at either scale (report map, scale,
  lines, hero rect, card rect, which obstacle);
- a test outside the owned list needs a hero step sentence to mean
  something (e.g. a characterization or balance fixture pins it);
- the page cannot cover the HUD and menu inside the `SafeArea` without
  changing `SafeArea` or `crawlGestureClear`;
- any verb, the action bar's rect, or the map touch rules would change.

## Commit and receipt

Never `git stash`. Stage only your paths (both sides of each `git mv`, the
`git rm`s) and commit with an explicit pathspec:
`git commit -m 'feat(app): float recent events over the map and open the log as a page' -- <paths>`.

Receipt: Red output (the four literal/value failures), Green command and
exit, format and analyze exits, M1–M7 with before/after hashes, the
migrated/rewritten/deleted test list, probe figures (map height, bar rect,
strip rect at s 1.0 and 1.3, widget dp), sweep sizes, the zero-hit grep for
locked decision 11, and the commit hash.
