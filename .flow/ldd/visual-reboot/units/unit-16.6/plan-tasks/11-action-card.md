# 11 — One action card for place actions, Wait and Flee; the log row holds only the log

Governing: `../CONTRACT.md` (amended 2026-09-25) settled decisions 6 and 8,
scope §1 item 3, scope §4, acceptance 4, 7, 8; `../PLAN.md` §9 (G12, the
superseded locks), G6 ids and labels, G10 (target card, strip, recenter), G11.
Work from `packages/app`.

## Starting repository state

Branch `residuum-visual-reboot-16.6`, app code as of `4de51c3` (later commits
are `.flow/` docs only). Check with
`git diff --stat 4de51c3 -- packages/app`: it must be empty, or show only
Task 12's paths (`crawl_slot.dart`, `crawl_menu.dart` and their tests) if
Task 12 ran first. Anything else means escalate.

What exists now:

- `lib/game/place_actions.dart`: `enum PlaceVerb {pickUp, gather, moveOn,
  ascend, descend, leave}` with `id`; `placeVerbsFor(GameViewState)`;
  `placeFacts(GameViewState)`.
- `lib/game/place_popup.dart`: `placePopupKey`, `placePopupHeight`,
  `PlacePopup` (a two-column grid of hand-built buttons, anchored beside the
  hero by `MapOverlays`).
- `lib/game/log_row.dart`: `LogRow` = `Row[Expanded(LogPeek), _SideControls]`.
  `_SideControls` holds the Wait and Flee `CrawlSlot`s, read from
  `state.offersWait` and `state.canFlee`.
- `lib/game/map_overlays.dart`: `MapOverlays` puts the strip, the place pop-up
  (`placeMapOverlay` with preferred offsets below and above `heroBlock`), the
  `TargetCard` (`Positioned.fill`, `avoid: [popupRect, recenter, strip]`) and
  the recenter pill (`right: 8, bottom: 8`) in a Stack.
- `lib/game/map_overlay_layout.dart`: `heroBlock`,
  `placeMapOverlay({Size map, …})`, `recenterRect(Size)`.
- `lib/game/target_card.dart`: the card's `BoxDecoration` and a private
  `_LeaderPainter`.
- `lib/game/crawl_style.dart`: `crawlSideControlWidth`, `crawlSideControlGap`,
  `crawlPlacePopupWidth`, `crawlPlaceButtonHeight`, `crawlPlaceButtonGap`.

## Owned files

- `git mv lib/game/place_actions.dart lib/game/action_card_verbs.dart`
- `git mv lib/game/place_popup.dart lib/game/action_card.dart`
- `lib/game/map_overlay_layout.dart`, `lib/game/map_overlays.dart`,
  `lib/game/target_card.dart`, `lib/game/crawl_surfaces.dart`,
  `lib/game/crawl_style.dart`, `lib/game/log_row.dart`
- `git mv test/game/place_actions_test.dart test/game/action_card_verbs_test.dart`
- `git mv test/widget/place_popup_test.dart test/widget/action_card_test.dart`
- `test/game/map_overlay_layout_test.dart`, `test/widget/log_row_test.dart`,
  `test/widget/target_card_test.dart`, `test/widget/crawl_verbs_test.dart`,
  `test/widget/battle_shelf_icons_test.dart`, `test/widget/log_drawer_test.dart`
  (one test name only), and any other test the full suite shows reading
  Wait, Flee or a place verb from the log row or the place pop-up
- `.flow/ldd/visual-reboot/units/unit-13/VISUAL-SYSTEM.md`, three blockquotes
  (step 9)

Non-goals: `game_bloc.dart` (no availability change), `game_screen.dart`
(it keeps `LogRow(state, bloc)` and `MapOverlays(bloc, state, size)`),
`crawl_slot.dart` and `crawl_menu.dart` (Task 12), the strip, the target
card's content, map touch, the log drawer, the camera. Do not add a
"block" action or any hook for one.

## Locked decisions

1. **One availability owner.** `action_card_verbs.dart`:
   `enum CardVerb { pickUp, gather, moveOn, ascend, descend, leave, flee, wait }`,
   ids `pick-up`, `gather`, `move-on`, `ascend`, `descend`, `leave-dungeon`,
   `flee`, `wait`.
   `List<CardVerb> cardVerbsFor(GameViewState s)` = in enum order, each iff
   `s.canPickUp`, `s.canGather`, `s.isRoadClear`, `s.canAscend`,
   `s.canDescend`, `s.canLeave`, `s.canFlee`, `s.offersWait`.
   `placeFacts` moves unchanged. `PlaceVerb` and `placeVerbsFor` are renamed
   away, not kept as aliases. After this task the only `lib` reads of
   `offersWait` and `canFlee` outside `game_bloc.dart` are in
   `cardVerbsFor`.
2. **Shown iff** `cardVerbsFor(s).isNotEmpty || placeFacts(s).isNotEmpty`
   (the pop-up's rule, PLAN §7 Q4). **Q7 (user):** when `itemsUnderfoot` is
   non-empty and the inventory is at `inventoryCap`, `placeFacts` appends
   `You cannot carry any more.`, the `InventoryFull` sentence from
   `event_messages.dart` read from that one source, not a copied literal.
   Proof: a test with a full pack on an item shows the `Here:` fact and that
   line, and no Pick up button; with one free slot the line is absent.
3. **Card body** (`action_card.dart`): `actionCardKey = Key('action-card')`,
   `actionCardLeaderKey = Key('action-card-leader')`.
   `ActionCard({required GameBloc bloc, required GameViewState state, required double width})`:
   `GestureDetector(key: actionCardKey, behavior: opaque, onTap: () {})` over
   `DecoratedBox(crawlCalloutDecoration)`, padding `crawlCalloutPadding`
   (10), `Column(start, min)`: fact lines exactly as the pop-up (`monoMeta`,
   one line, ellipsis, `crawlCalloutLineHeight × s` tall each), then
   `crawlActionCardGap` (6) when both facts and verbs exist, then the button
   rows. Buttons: `CrawlSlot(key: ValueKey(verb.id), label, mark, onPressed,
   width: buttonWidth, height: crawlTouchTarget)`, four per row,
   `buttonWidth = (width − 2 × 10 − 3 × 6) / 4`, gap 6 between buttons and
   between rows, rows start-aligned. Height function
   `double actionCardHeight(GameViewState s, double scale)` = 0 when hidden,
   else `20 + facts × 14 × scale + (facts > 0 && verbs > 0 ? 6 : 0) +
   rows × 48 + max(rows − 1, 0) × 6`, `rows = (verbs / 4).ceil()`.
   Labels, marks, dispatch: the six place verbs exactly as `PlacePopup._button`
   today (Pick up / `Icons.back_hand` / `PickUpPressed`; `node.verb` /
   `Icons.hardware` or `Icons.spa` / `GatherPressed`; Move on /
   `Icons.hiking` / `leaveEncounter(…cleared)`; `Ascend <` /
   `ActionIcon.ascend` / `AscendPressed`; `Descend >` / `ActionIcon.descend` /
   `DescendPressed`; `Leave` or `doneControl` / `Icons.logout` or
   `Icons.flag` / `suspendDungeon` or `confirmCompletion`), plus Flee /
   `FontMark(Icons.directions_run)` / `FleePressed` and Wait /
   `ShippedMark(ActionIcon.wait)` / `WaitPressed` (the log row's marks).
4. **Shared frame.** `crawl_style.dart` gains
   `const BoxDecoration crawlCalloutDecoration` = fill `crawlCalloutFill`,
   1 dp `crawlFrame` border, radius 6. `TargetCard` and `ActionCard` both use
   it. `_LeaderPainter` moves from `target_card.dart` to `crawl_surfaces.dart`
   as public `LeaderPainter({required Offset from, required Offset to})`,
   body unchanged (line from `from` to `to`, dot at `from`). Both cards use it.
5. **Placement** (`map_overlay_layout.dart`, pure):
   ```dart
   Rect placeActionCard({required Size map, required double height, required Rect hero, Rect? strip});
   ```
   `m = crawlOverlayMargin` (8), `w = map.width − 2m`.
   `stripAtTop = strip != null && strip.center.dy < map.height / 2`.
   `topLimit = stripAtTop ? strip.bottom : 0`;
   `bottomLimit = strip != null && !stripAtTop ? strip.top : map.height`.
   `bottom = Rect.fromLTWH(m, bottomLimit − m − height, w, height)`;
   `top = Rect.fromLTWH(m, topLimit + m, w, height)`; `block = heroBlock(hero)`.
   Return `bottom` if it misses `block`; else `top` if it misses `block`;
   else whichever has the smaller `block` overlap area, ties to `bottom`.
   ```dart
   (Offset, Offset)? actionCardLeader({required Size map, required Rect card, required Rect hero});
   ```
   `null` when `hero` does not overlap `Offset.zero & map`. Otherwise
   `x = hero.center.dx`, `tx = x.clamp(card.left + 6, card.right − 6)`;
   card below the hero (`card.center.dy >= hero.center.dy`) →
   `(Offset(x, hero.bottom), Offset(tx, card.top))`; otherwise
   `(Offset(x, hero.top), Offset(tx, card.bottom))`.
   `recenterRect(Size map, {Rect? actionCard})`: the bottom-right 48 dp square
   as today; when it overlaps `actionCard`, the same square lifted to
   `bottom = actionCard.top − 8`.
   `placeMapOverlay` takes `required Rect area` in place of `required Size map`:
   corners and clamps are computed inside `area` (`[area.left + 8,
   max(area.left + 8, area.right − 8 − size.width)]`, same for y); passes
   1–4 unchanged.
6. **Composition** (`map_overlays.dart`). Strip rect and flip unchanged.
   `showCard = cardVerbsFor(state).isNotEmpty || placeFacts(state).isNotEmpty`;
   `cardRect = placeActionCard(map: size, height: actionCardHeight(state, s), hero: heroRect, strip: stripRect)`;
   `recenter = recenterRect(size, actionCard: cardRect)` when shown;
   target-card `area` = `Rect.fromLTRB(0, 0, W, cardRect.top)` when the card
   is below the hero cell (same test as the leader: `cardRect.center.dy >=
   heroRect.center.dy`), `Rect.fromLTRB(0, cardRect.bottom, W, H)` when
   above it, `Offset.zero & size` with no card; target-card `avoid =
   [?recenter, ?stripRect]`. Stack children, in paint order, **each a
   `Positioned` or `Positioned.fill`** (ledger trap: a bare child collapses the
   Stack): strip; `Positioned.fill(IgnorePointer(CustomPaint(key:
   actionCardLeaderKey, painter: LeaderPainter(from, to))))` when the leader
   is non-null; `Positioned.fromRect(rect: cardRect, child: ActionCard(…))`;
   `Positioned.fill(TargetCard(state, size, area, avoid))`; recenter pill as
   `Positioned.fromRect(rect: recenter, …)` (same key, label, event).
   `TargetCard` gains `final Rect? area` (null = `Offset.zero & size`) passed
   to `placeMapOverlay`.
7. **Log row.** `LogRow` = `SizedBox(height: crawlLogRowHeight × s,
   Padding(horizontal: crawlGutter, LogPeek(key: logPeekKey, …)))`. Height
   104 × s is unchanged, so the map rectangle does not change (§9 G12).
8. **Deleted** (grep `lib` and `test` for zero hits at handoff): `PlaceVerb`,
   `placeVerbsFor`, `PlacePopup`, `placePopupKey`, `placePopupHeight`,
   `_SideControls`, `crawlSideControlWidth`, `crawlSideControlGap`,
   `crawlPlacePopupWidth`, `crawlPlaceButtonHeight`, `crawlPlaceButtonGap`,
   `_LeaderPainter`, the pop-up's preferred-offset code in `MapOverlays`, and
   the target card's inline decoration. No new dartdoc or body comments in
   `packages/app` (G11).
9. **Docs.** In `VISUAL-SYSTEM.md` rewrite only these Unit 16.6 blockquotes,
   heading `(2026-09-24, amended 2026-09-25)`: line 145–146 "the bottom menu,
   the pop-ups and the log-side controls" → "the bottom menu, the pop-ups and
   the action card"; line 183–184 "the log-side Wait/Flee, on-map place
   pop-ups and the map itself" → "the action card (place actions, Wait,
   Flee) and the map itself"; line 194 "Flee sits beside the log whenever
   fleeing is legal" → "Flee sits in the action card whenever fleeing is
   legal".

## Proof (Red first; tests assert behaviour and geometry, never retired presentation)

Expectations in widget tests come from the map slot rect
(`dungeonSceneSlotKey`), `GridGeometry` and the literal margins (8), **never
from `placeActionCard`/`actionCardHeight`** (the Task 06 defect hid behind a
test that reused the implementation's offsets).

- `action_card_verbs_test.dart` (migrated, `CardVerb`/`cardVerbsFor`): every
  place case kept; plus `flee` exactly when `canFlee` (road edge yes, inland
  road no, dungeon no), `wait` exactly when `offersWait` (Watched, battle,
  none while exploring, none when game over), order on a road edge in sight
  = `[flee, wait]`, and on a landing with loot while Watched =
  `[pickUp, …, wait]`.
- `map_overlay_layout_test.dart`:
  - `placeActionCard`: bottom when clear (`left 8`, `width W − 16`,
    `bottom H − 8`); top when the bottom candidate hits the hero block
    (`top 8`); below a top strip (`top strip.bottom + 8`); above a bottom
    (flipped) strip (`bottom strip.top − 8`); both-overlap tie → bottom.
  - Sweep (hero x centred; hero top from 0 to `H − 30` in 0.5 dp steps; strip
    per the flip rule: 48 × s at the top unless the hero overlaps it, then at
    the bottom with width `W − 64`, and also no strip): result never
    overlaps `heroBlock` for (a) 392.7 × 561.9, height 170 (3 facts, 2 rows,
    scale 1.0) and (b) 392.7 × 489.9, height 110.4 (2 facts, 1 row, scale
    1.3). These are the §9 G12 guarantees.
  - `actionCardLeader`: below/above cases and the clamp at a side edge; null
    for a hero cell outside the map.
  - `recenterRect(actionCard:)`: unchanged without overlap, lifted to
    `card.top − 8` with overlap.
  - `placeMapOverlay(area:)`: existing cases migrated to
    `area: Offset.zero & size`; new: with an `area` band and an avoid rect
    covering all of it (pass 1 fails), the result lies inside `area` minus
    the 8 dp margin.
- `action_card_test.dart` (migrated from `place_popup_test.dart`, same
  fixtures, `onTheTargetPhone`): shown/hidden cases for each place verb, plus
  Wait while Watched, Flee alone on a road edge with nothing in sight, Flee
  and Wait together; nothing on a bare floor. Dispatch cases kept (Pick up,
  Descend, Leave, Finish confirm, Move on) plus Wait appends
  `You hold your ground.` and Flee sets `hasFled`. Geometry:
  - card rect (map-local) `left == 8`, `right == map.width − 8`,
    `bottom == map.height − 8` with the hero centred, and misses
    `heroBlock(hero)`;
  - on a floor tall enough to pan (e.g. 7 × 16, hero at row 8), after
    `MapPanned` moves the hero low enough that a bottom card would hit the
    hero block (assert that precondition from the map height, the
    rendered card height and the hero rect), the card's `top == 8`, and it
    misses the hero block; the same in battle with the strip at the top:
    `top == strip.bottom + 8`;
  - the leader exists (`actionCardLeaderKey`) and its painter's `from` lies on
    the hero cell edge facing the card and `to` on the card edge facing the
    hero;
  - at text scale 1.3 with the largest fixture (loot + node on the bottom
    stairs while Watched: 3 facts, 5 buttons) nothing overflows
    (`takeException` null) and each button is ≥ 48 × 48;
  - with the card shown: a tap on each orthogonal neighbour steps the hero,
    a drag outside the card pans, a tap inside the card leaves the hero
    in place; the map rect is identical with and without the card;
  - recenter: hero panned off-screen while the card shows → the pill does
    not overlap the card and tapping it recentres.
- `log_row_test.dart`: rewrite to the row's behaviour: the row rect is
  identical across exploration, Watched, battle and a road edge; the peek
  fills the row less `2 × crawlGutter` in all four; no `wait`/`flee` key
  inside `logRowKey` in any; the peek still opens the drawer. The Wait/Flee
  tests move to `action_card_test.dart` (not duplicated).
- `target_card_test.dart`: the pop-up coexistence test re-keyed to the
  action card; new: a monster two or more rows below the hero in sight,
  inspected, with loot underfoot → the target card and the action card do
  not overlap and the target card misses the hero block; `_pumpCard`
  unchanged (null `area`).
- `crawl_verbs_test.dart`: Wait, Flee and the six place verbs are found as
  descendants of `actionCardKey`; test names say "the action card".
- `battle_shelf_icons_test.dart`: `_shelfButton('wait')` scoped to
  `actionCardKey`; its doc comment updated to say so.
- `log_drawer_test.dart`: rename the test at line 515 to drop "Wait itself
  moved into the log row the drawer covers — PLAN.md G8"; body unchanged.

**Expected Red:** before production edits the migrated tests fail to
compile (`CardVerb`, `actionCardKey`, `placeActionCard`) and the rewritten
`log_row_test` peek-width case fails on value in Watched/battle (peek
narrower by 70 dp). Record both.

**Mutation witnesses (required, after Green).** Snapshot
`lib/game/map_overlay_layout.dart` and `lib/game/map_overlays.dart`
(`sha256sum` before), then one at a time: M1 `placeActionCard` always returns
`bottom` → the top-fallback widget test and the sweep fail; M2 ignore
`strip` → the below-strip test fails; M3 clamp `placeMapOverlay` into the
whole map instead of `area` → the `area` unit test fails; M4 leader from
`hero.top` for a card below → the leader test fails; M5 place the card with
`width: 300` centred on the hero → the edge-pinned rect test fails. Restore
each from the snapshot (not from git), and show the restored hashes equal
the snapshot hashes. A mutant that passes means a missing assertion: add it
before handoff.

**Green:** `dart format <touched Dart files>`, `flutter analyze`, full
`flutter test`. Widget figures for the receipt come from an **untracked**
probe copy (e.g. `test/widget/zz_probe_test.dart`), deleted afterwards
with `git status --short test` showing no untracked file, never from prints in
a tracked test.

## Executor discretion

Widget decomposition inside `action_card.dart`; whether `MapOverlays`
passes precomputed rects; fixture helpers and names; the precise tall
floor and pan used for the top-fallback test, as long as the precondition
is asserted.

## Escalate when

- the diff from `4de51c3` has anything beyond the listed state;
- any verb's guard, id, label, mark or dispatch would change;
- the two sweep guarantees fail at the stated sizes (report the hero top
  and both rects);
- the card at text scale 1.3 overflows or a button falls under 48 dp;
- a flow test (suspend, door re-entry, world road) needs Wait, Flee or a
  place verb somewhere the card cannot put it;
- keeping the map rect unchanged needs a log row height other than
  104 × s.

## Commit and receipt

Never `git stash`. Stage the paths you own (including both sides of each
`git mv`) and commit with an explicit pathspec:
`git commit -m 'feat(app): gather moment actions into one action card' -- <paths>`.

Receipt: Red output (compile + peek width), Green command and exit, format
and analyze exits, M1–M5 results with before/after hashes, the migrated,
rewritten and deleted test list, the probe's map height and card rects at
scale 1.0 and 1.3 (widget dp), the zero-hit grep for the deleted symbols,
and the commit hash.
