# 06 — On-map place pop-up and the map overlay layout owner

Governing: `../CONTRACT.md` settled decision 8, scope §4, acceptance 4, 8;
`../PLAN.md` §2 G6, G10 (placement, place pop-up), G11; §7 Q2, Q4. Work
from `packages/app`.

## Starting repository state

Task 05 committed. `_actionsFor` still offers `pick-up`, `gather`,
`move-on`, `ascend`, `descend`, `leave-dungeon` (label `Leave` or
`doneControl`, `_confirmCompletion` when `canLeave && isAtTheBottom`) plus
drink, spells, overflow, pack. `_notesFor` + `_NotesOverlay` render
`doneAtTheBottom`, `Underfoot: …`, `Here: …` at the map's top-left.
`leaveDungeon`, `suspendDungeon`, `leaveEncounter`, `_confirmCompletion`,
`doneControl`, `doneAtTheBottom` live in `game_screen.dart`. The recenter
pill is positioned in `game_screen.dart` (bottom-right, 48 dp). `MapCallout`
positions itself.

## Owned files

new `lib/game/place_actions.dart`, `lib/game/place_popup.dart`,
`lib/game/map_overlay_layout.dart`, `lib/game/map_overlays.dart`,
`lib/game/crawl_exits.dart`; `lib/game/game_screen.dart`;
`lib/game/crawl_style.dart`; tests new `test/game/place_actions_test.dart`,
`test/game/map_overlay_layout_test.dart`, `test/widget/place_popup_test.dart`,
and every test that found these verbs or notes under `actionRowKey` or the
notes overlay, or imported the moved functions (`crawl_controls_test`,
`crawl_layout_test`, `crawl_surfaces_test`, `craft_surfaces_test`,
`door_reentry_test`, `suspend_door_test`, `pack_screen_test`,
`world_screen_test`, `crawl_action_row_test`, `game_bloc_test` if it
imports `doneControl`).

Non-goals: menu, drink/spells, callout (moves into `MapOverlays` in Task 08),
strip, bloc handlers.

## Locked decisions

1. `place_actions.dart`: `enum PlaceVerb { pickUp, gather, moveOn, ascend, descend, leave }`
   with `String get id` = `pick-up`, `gather`, `move-on`, `ascend`,
   `descend`, `leave-dungeon`;
   `List<PlaceVerb> placeVerbsFor(GameViewState s)` = in enum order, each
   iff `s.canPickUp`, `s.canGather`, `s.isRoadClear`, `s.canAscend`,
   `s.canDescend`, `s.canLeave`; `List<String> placeFacts(GameViewState s)`
   = today's `_notesFor` body verbatim (same texts, same order). No other
   code evaluates these guards.
2. `crawl_exits.dart` receives `leaveDungeon`, `suspendDungeon`,
   `leaveEncounter`, `confirmCompletion` (was `_confirmCompletion`, now
   public for the pop-up), `doneControl`, `doneAtTheBottom` verbatim minus
   dartdoc; imports updated everywhere (`_DeathOverlay` included).
   `doneControl` stays `Finish` (Q2 default).
3. `place_popup.dart`: `PlacePopup` renders PLAN G10 place pop-up exactly
   (width, padding, fact lines, button grid, height formula, button visuals,
   keys `ValueKey(verb.id)`); labels/marks/dispatch per verb: pickUp
   `Pick up` `FontMark(Icons.back_hand)` `PickUpPressed`; gather
   `node.verb` `FontMark(oreVein ? Icons.hardware : Icons.spa)`
   `GatherPressed`; moveOn `Move on` `FontMark(Icons.hiking)`
   `leaveEncounter(context, state, EncounterEnding.cleared)`; ascend
   `Ascend <` `ShippedMark(ActionIcon.ascend)` `AscendPressed`; descend
   `Descend >` `ShippedMark(ActionIcon.descend)` `DescendPressed`; leave
   `ending ? doneControl : 'Leave'`, `FontMark(ending ? Icons.flag : Icons.logout)`,
   `ending ? confirmCompletion : suspendDungeon` where
   `ending = s.canLeave && s.isAtTheBottom`. Fill `crawlCalloutFill`, 1 dp
   `crawlFrame`, radius 6. Constants: `crawlPlacePopupWidth = 300`,
   `crawlPlaceButtonHeight = 48`, `crawlPlaceButtonGap = 6`,
   `crawlOverlayMargin = 8`.
4. `map_overlay_layout.dart`: `heroBlock` and `placeMapOverlay` exactly per
   PLAN G10 (candidate order, clamping, four passes, `Rect.overlaps`), plus
   `Rect recenterRect(Size map)` =
   `Rect.fromLTWH(map.width - 8 - crawlTouchTarget, map.height - 8 - crawlTouchTarget, crawlTouchTarget, crawlTouchTarget)`.
5. `map_overlays.dart`: `MapOverlays({required GameViewState state, required Size size})`
   returns a `Stack` of `Positioned` children: the place pop-up (preferred
   below then above the hero block; avoid: `recenterRect` when the recenter
   pill shows) and the recenter pill (moved from `GameScreen`, same
   predicate/key/event). The hero cell comes from
   `GridGeometry.camera(size, …, state.cameraFocus, state.pan).rectOf(hero)`.
   It is the only widget that positions map overlays from now on.
6. `GameScreen`: map slot `Stack[DungeonSceneHost, MapCallout (unchanged), MapOverlays]`;
   `_actionsFor` loses the six place entries; `_notesFor` and
   `_NotesOverlay` are deleted.

## Proof (Red first)

- `place_actions_test.dart` (state in, list out): each verb appears exactly
  when its getter holds — items underfoot with room / with a full pack (no
  pickUp, fact kept), ore vein vs herb patch, road cleared vs not, stairs
  up, stairs down, bottom stairs (`leave` with the ending), game over (none);
  facts identical to the old notes for the same fixtures.
- `map_overlay_layout_test.dart`: preferred wins when clear; clamping at
  each edge; pass 1 skips a candidate hitting an avoid rect; pass 2 when
  every candidate hits an avoid rect; pass 3/4 on a tiny map; the result
  never overlaps `heroBlock` at 392.7 × 568.8 for the hero at the centre,
  each corner, and each edge midpoint (sweep).
- `place_popup_test.dart` at `onTheTargetPhone`: the pop-up appears on
  items/node/stairs/road-clear and not elsewhere; one button per verb with
  its word; tapping each dispatches its existing effect (pick-up adds to the
  pack, Descend changes depth, Leave suspends, Finish opens the confirm,
  Move on ends the road fight); the pop-up rect never overlaps the hero
  block; with the pop-up shown, a tap on each orthogonal neighbour cell
  steps the hero and a drag outside the pop-up pans the map; the map rect
  is identical with and without the pop-up; `doneAtTheBottom` shows only on
  the bottom stairs.
Expected Red: the verbs are found under `actionRowKey`; no pop-up exists.
Green: full `flutter test`, `dart format <touched>`, `flutter analyze`.

## Executor discretion

Widget decomposition inside `place_popup.dart`; whether `MapOverlays`
computes the geometry once and passes rects down; fixture helpers.

## Escalate when

Any verb's guard, label, id or dispatch would change; a flow test (suspend,
door re-entry, world road) needs the verb at a location the pop-up cannot
give it; the pop-up cannot fit four buttons plus three facts in the map at
text scale 1.3 without overlapping the hero block (report the numbers).

## Completion receipt

Red output, Green command/exit, format/analyze exits, migrated/deleted test
list, the placement sweep result. Commit:
`feat(app): offer place actions in an on-map pop-up`.
