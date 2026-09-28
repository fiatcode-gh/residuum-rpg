# 05 — Log row: Wait and Flee beside the recent-events peek

Governing: `../CONTRACT.md` settled decision 6, scope §1.3, protected
boundaries (the rules decide), acceptance 4, 7, 12; `../PLAN.md` §2 G5, G6,
G8; §7 Q1. Work from `packages/app`.

## Starting repository state

Task 04 committed. `GameScreen` column: `CrawlHud`, battle `BattleDock`,
`Expanded(Stack[Column[map slot, 6, LogPeek (96, own 8 dp horizontal padding), 7], drawer])`,
`CrawlActionBar`, 6. `_actionsFor` offers `wait` when `isBattleOpen` and
again when `isEncounter && !isRoadClear && !isBattleOpen`, and `flee` when
`canFlee`. `crawl_action_row.dart::_ActionSlot` renders slot states.
`GameViewState` has `enemiesInSight`, `isBattleOpen`, `canFlee`; no
`offersWait`.

## Owned files

new `lib/game/log_row.dart`, new `lib/game/crawl_slot.dart`,
`lib/game/crawl_action_row.dart` (use `CrawlSlot`; remove `_ActionSlot`),
`lib/game/log_drawer.dart` (`LogPeek` padding/height only),
`lib/game/game_bloc.dart` (`offersWait` getter only),
`lib/game/game_screen.dart` (`_actionsFor` wait/flee entries removed, `LogRow`
placed), `lib/game/crawl_style.dart`; tests `test/game_bloc_test.dart`
(new group), new `test/widget/log_row_test.dart`, and every test that found
Wait/Flee inside `actionRowKey` (`crawl_controls_test`, `crawl_layout_test`,
`battle_view_test`, `battle_shelf_icons_test`, `log_drawer_test`,
`world_screen_test`, `crawl_action_row_test` — migrate finders to
`logRowKey` / `ValueKey('wait')` / `ValueKey('flee')`).

Non-goals: menu, place verbs, drawer internals, bloc handlers.

## Locked decisions

1. `GameViewState`:
   `bool get offersWait => !game.isGameOver && (isBattleOpen || enemiesInSight > 0);`
   (no dartdoc). The road pre-engagement `wait` entry is removed with no
   replacement (§7 Q1 default).
2. `crawl_slot.dart`: `CrawlSlot` exactly per PLAN G8 (extracted `_ActionSlot`
   visuals; `dimmed`, `armed`, nullable `onPressed`, explicit width/height);
   `crawlSlotMark = 20` (was 22). `CrawlActionBar` renders its slots with
   `CrawlSlot` (its `CrawlAction.onPressed == null` → disabled visuals,
   `armed` → armed) so the bar keeps working until Task 07.
3. `log_row.dart`: `LogRow({required GameViewState state, required GameBloc bloc})`
   keyed by the caller with `logRowKey` (defined here), height
   `crawlLogRowHeight (104) × crawlScale`, padding horizontal `crawlGutter`,
   layout and side column exactly PLAN G8 (`crawlSideControlWidth = 64`,
   `crawlSideControlGap = 6`, Wait top, Flee bottom, each
   `(height − 6) / 2`). Wait: key `ValueKey('wait')`, label `Wait`,
   `ShippedMark(ActionIcon.wait)`, `WaitPressed`. Flee: key
   `ValueKey('flee')`, label `Flee`, `FontMark(Icons.directions_run)`,
   `FleePressed`. Visibility: Wait iff `state.offersWait`, Flee iff
   `state.canFlee`; the side column iff either.
4. `LogPeek`: drops its outer `Padding(horizontal: crawlGutter)` and fixed
   height; it fills the box `LogRow` gives it. `crawlEventsHeight` is
   deleted. Internals, key, semantics and tap behaviour unchanged.
5. `GameScreen` replaces `LogPeek` with `LogRow(key: logRowKey, …)`.

## Proof (Red first)

- `game_bloc_test.dart` group `offersWait`: false with nothing in sight;
  true Watched (visible monster not holding reach); true in battle; false
  on game over; false on a road with monsters none of which is visible (Q1
  default documented by the test name).
- Watched stall (bloc test, the walkthrough's UXW-BAT 27–32 state): a
  dungeon fixture with a visible monster 3+ cells away and not holding
  reach; `WaitPressed` emits a state whose log ends with the monster-phase
  lines after `You hold your ground.` and whose game differs from before
  (the monster moved closer or the fight opened — assert chebyshev distance
  decreased or `isBattleOpen`).
- `log_row_test.dart`: the log row rect is identical with and without the
  side column (exploration vs Watched vs battle vs road edge); Wait visible
  only when `offersWait`; Flee only when `canFlee`, below Wait; tapping Wait
  appends `You hold your ground.`; tapping Flee at a road edge flees
  (`hasFled`); each control ≥ 48 dp tall; the peek still opens the drawer.
- Migrated finders: no `wait`/`flee` key remains under `actionRowKey`.
Expected Red: `offersWait` missing; Watched shows no Wait.
Green: full `flutter test`, `dart format <touched>`, `flutter analyze`.

## Executor discretion

Fixture construction (existing ghoul/crawl helpers); `LogRow` internal
widget split; whether `SideControls` is a private class.

## Escalate when

The Watched fixture cannot make the monster act on a Wait (a core behaviour
question — never change core); a road flow in `world_screen_test` depended
on the pre-engagement Wait for something other than waiting; the drawer
overlay stops covering the peek correctly.

## Completion receipt

Red output, Green command/exit, format/analyze exits, list of migrated
tests, the Watched-stall assertion used. Commit:
`feat(app): move Wait and Flee beside the recent-events log`.
