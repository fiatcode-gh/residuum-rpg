# 13 — The action card leaves the map: an `ACTIONS` bar in its own row

Governing: `../CONTRACT.md` (amended 2026-09-28) settled decision 8, scope
§1 item 3, scope §4, acceptance 4, 7, 8; `../PLAN.md` §10 (superseded locks,
G14, 10.1 figures), G6 ids and labels, G10 (target card, turn-order strip,
recenter), G11 conventions. Work from `packages/app`.

## Starting repository state

Branch `residuum-visual-reboot-16.6`, app code as of `7d99bea` (later
commits are `.flow/` docs only). Check: `git diff --stat 7d99bea --
packages` must be empty; anything else → escalate. The user's untracked
`tmp1.png` at the repo root is not yours: never stage, move or delete it.

What exists now:

- `lib/game/action_card_verbs.dart`: `enum CardVerb` (ids `pick-up`,
  `gather`, `move-on`, `ascend`, `descend`, `leave-dungeon`, `flee`,
  `wait`), `cardVerbsFor(GameViewState)`, `placeFacts(GameViewState)`
  (with the Q7 `inventoryFullSentence` line). **Unchanged by this task.**
- `lib/game/action_card.dart`: `actionCardKey`, `actionCardLeaderKey`,
  `actionCardHeight(state, scale)`, `ActionCard(bloc, state, width)` (facts,
  then 4-per-row `CrawlSlot` buttons; `_button` holds the eight
  label/mark/dispatch arms).
- `lib/game/map_overlays.dart`: `MapOverlays` places the turn-order strip,
  the action card (`placeActionCard`), its leader (`actionCardLeader`,
  `LeaderPainter`), the `TargetCard` (`area: targetCardArea(map, hero,
  actionCard, strip)`, `avoid: [?recenter]`) and the recenter pill
  (`recenterRect(size, actionCard: cardRect)`).
- `lib/game/map_overlay_layout.dart`: `heroBlock`, `placeMapOverlay`,
  `placeActionCard`, `targetCardArea`, `actionCardLeader`, `recenterRect`.
- `lib/game/game_screen.dart`: Column `[CrawlHud, Expanded(LayoutBuilder →
  Stack[Column[Expanded(key: dungeonSceneSlotKey …), SizedBox(crawlPanelGap),
  LogRow(key: logRowKey), SizedBox(crawlGap)], drawer overlay]), CrawlMenu,
  SizedBox(crawlBottomGap)]`.
- `lib/game/crawl_style.dart`: `crawlActionCardGap = 6`,
  `crawlCalloutDecoration`, `crawlFrameDecoration`, `crawlCalloutLineHeight
  = 14`, `crawlTouchTarget = 48`, `crawlGutter = 8`.

## Owned files

- `git mv lib/game/action_card.dart lib/game/action_bar.dart`
- `lib/game/game_screen.dart`, `lib/game/map_overlays.dart`,
  `lib/game/map_overlay_layout.dart`, `lib/game/crawl_style.dart`
- `git mv test/widget/action_card_test.dart test/widget/action_bar_test.dart`
- `test/game/map_overlay_layout_test.dart`, `test/widget/crawl_layout_test.dart`,
  `test/widget/target_card_test.dart`, `test/widget/crawl_verbs_test.dart`,
  `test/widget/battle_shelf_icons_test.dart`, and any other test the full
  suite shows reading the action card, its key, its placement or its leader
- `.flow/ldd/visual-reboot/units/unit-13/VISUAL-SYSTEM.md`, three
  blockquotes (locked decision 8)

Non-goals: `action_card_verbs.dart` (no rename, no guard change),
`game_bloc.dart`, `log_row.dart`, `log_drawer.dart`, the events strip, the
full log page and the step line (Task 14), `crawl_slot.dart`,
`crawl_menu.dart`, `target_card.dart` content, map touch, the camera. No
"block" action or hook.

## Locked decisions

1. **Composition** (`game_screen.dart`). The inner drawer Stack keeps its
   Column, which becomes `[Expanded(key: dungeonSceneSlotKey …),
   SizedBox(crawlPanelGap), LogRow(key: logRowKey), SizedBox(crawlPanelGap)]`
   (the trailing gap changes from `crawlGap` 7 to `crawlPanelGap` 6). After
   the `Expanded` that holds that Stack, and before `CrawlMenu`:
   `ActionBar(key: actionBarKey, bloc: bloc, state: state)`, then
   `SizedBox(height: crawlGap)`. The drawer overlay therefore covers the map
   and the log row, never the bar. Top to bottom: HUD, map, 6, log row, 6,
   bar, 7, menu, 6.
2. **Widget** (`action_bar.dart`): `const actionBarKey = Key('action-bar');`
   `const actionBarIdle = 'Nothing to do here.';`
   `double actionBarHeight(double scale)` =
   `2 * crawlActionBarPadding + crawlActionBarTitleRow * scale +
   crawlActionBarTitleGap + crawlActionBarFactLines * crawlCalloutLineHeight
   * scale + crawlActionBarGap + crawlTouchTarget` (= `70 + 58 × scale`).
   `ActionBar({required GameBloc bloc, required GameViewState state, super.key})`
   builds `Padding(horizontal: crawlGutter) → SizedBox(height:
   actionBarHeight(crawlScale(context))) → DecoratedBox(crawlFrameDecoration)
   → Padding(all: crawlActionBarPadding) → LayoutBuilder → Column(start)`:
   - `SizedBox(height: crawlActionBarTitleRow × s)` with
     `Text('ACTIONS', style: displaySection, maxLines: 1)` left-aligned;
   - `SizedBox(height: crawlActionBarTitleGap)`;
   - `SizedBox(height: crawlActionBarFactLines × crawlCalloutLineHeight × s)`
     holding a `Column(start)` of fact lines, each `SizedBox(height:
     crawlCalloutLineHeight × s, Text(line, monoMeta, maxLines: 1, ellipsis))`;
     lines = `placeFacts(state)` when it has ≤ 3 entries, else
     `[f[0], f[1], f.sublist(2).join(' · ')]`; when `cardVerbsFor(state)`
     and `placeFacts(state)` are both empty the only line is `actionBarIdle`;
   - `SizedBox(height: crawlActionBarGap)`;
   - `SizedBox(height: crawlTouchTarget)` holding a `Row(start)` of buttons:
     `n = max(4, verbs.length)`, `buttonWidth = (constraints.maxWidth − (n −
     1) × crawlActionBarGap) / n`, gap `crawlActionBarGap` between buttons,
     each `CrawlSlot(key: ValueKey(verb.id), label, mark, onPressed, width:
     buttonWidth, height: crawlTouchTarget)`. The `_button` switch moves
     verbatim from `ActionCard` (labels, marks, dispatch unchanged).
   No `GestureDetector` absorber (the bar is off the map).
3. **Constants** (`crawl_style.dart`): rename `crawlActionCardGap` →
   `crawlActionBarGap` (6); add `crawlActionBarPadding = 6`,
   `crawlActionBarTitleRow = 16`, `crawlActionBarTitleGap = 4`,
   `crawlActionBarFactLines = 3`. Keep `crawlCalloutDecoration` (the target
   card uses it).
4. **Placement** (`map_overlay_layout.dart`): delete `placeActionCard` and
   `actionCardLeader`. `recenterRect(Size map)` returns the bottom-right
   48 dp square at margin 8 (the `actionCard` parameter and lift are
   deleted). `targetCardArea({required Size map, Rect? strip})` =
   `Rect.fromLTRB(0, top, map.width, bottom)`, `stripAtTop = strip != null
   && strip.center.dy < map.height / 2`, `top = stripAtTop ? strip.bottom :
   0`, `bottom = strip != null && !stripAtTop ? strip.top : map.height`
   (the `hero` and `actionCard` parameters are deleted). `heroBlock` and
   `placeMapOverlay` unchanged.
5. **Overlays** (`map_overlays.dart`): children, each `Positioned` or
   `Positioned.fill` (ledger trap): turn-order strip (rect and flip rule
   unchanged); `Positioned.fill(TargetCard(state, size, area:
   targetCardArea(map: size, strip: stripRect), avoid: [?recenter]))`;
   recenter pill at `recenterRect(size)` when `_heroOffScreen`. No action
   card, no leader.
6. **Map rectangle** is identical in exploration, Watched, battle and armed
   and with or without verbs (it is an `Expanded` above fixed rows).
7. **Deleted** (zero hits in `lib` and `test` at handoff): `ActionCard`,
   `actionCardKey`, `actionCardLeaderKey`, `actionCardHeight`,
   `placeActionCard`, `actionCardLeader`, `crawlActionCardGap`, the
   `actionCard:` parameters of `recenterRect`/`targetCardArea`, the
   `hero:` parameter of `targetCardArea`, and `import 'action_card.dart'`.
   `LeaderPainter` stays (the target card uses it). No new dartdoc or body
   comments in `packages/app` (G11); stale dartdoc on a touched symbol is
   deleted.
8. **Docs** (`VISUAL-SYSTEM.md`): in the three Unit 16.6 blockquotes at
   lines 144–146, 182–186 and 193–196, change the heading to
   `(2026-09-24, amended 2026-09-25 and 2026-09-28)` and "the action card"
   → "the action bar" (three occurrences). Nothing else.

## Proof (Red first; behaviour and geometry, never retired presentation)

Expectations come from the map slot rect (`dungeonSceneSlotKey`), the menu
rect, the literal gaps (6, 7), and the literal bar height `70 + 58 × s`
(128.0 at 1.0, 145.4 at 1.3) — **never from `actionBarHeight`**.

**Red (record before any production edit).** Write the new bar cases below
with literal finders — `find.byKey(const Key('action-bar'))`,
`find.text('ACTIONS')`, `find.text('Nothing to do here.')`, and
`find.descendant(of: find.byKey(dungeonSceneSlotKey), matching:
find.byKey(const ValueKey('pick-up')))` — and run them at `7d99bea`: they
compile and fail on value (bar absent, no title, no quiet line, Pick up
inside the map slot). Record the output. After Green the literals may be
replaced by `actionBarKey` and `actionBarIdle`.

- `action_bar_test.dart` (migrated, same fixtures and `_openCrawl`):
  - content cases kept, finders scoped to `actionBarKey`: nothing but the
    title and the quiet line on a bare floor (no verb key); Pick up; Mine;
    Ascend + Leave; Move on; Finish + `doneAtTheBottom`; `doneAtTheBottom`
    nowhere else; full pack → `Here:` fact + `inventoryFullSentence`, no
    Pick up, **no quiet line**; Wait alone while Watched (no quiet line);
    Flee alone; Flee + Wait. `ACTIONS` shows in every case.
  - dispatch cases kept (Pick up, Descend, Leave, Finish confirm, Move on,
    Wait appends `You hold your ground.`, Flee sets `hasFled`).
  - geometry: bar rect identical across bare floor, loot, Watched, battle,
    road edge and bottom stairs at s 1.0, and across the same states at
    s 1.3; its height `closeTo(128.0, 0.01)` at 1.0 and `closeTo(145.4,
    0.01)` at 1.3; `logRow.bottom + 6 == bar.top` and `bar.bottom + 7 ==
    menu.top`; no `CardVerb` id key is a descendant of `dungeonSceneSlotKey`
    in any state.
  - s 1.3, the largest fixture (the existing loot + node on the bottom-floor
    up stairs while Watched: 3 facts, 5 buttons): `takeException()` null;
    each of the five buttons ≥ 48 × 48 and inside the bar's frame rect; a
    4-fact fixture (the same plus a full pack) shows a third line
    containing both `Here:` and `inventoryFullSentence`.
  - the map rect is identical with and without verbs; a tap on each
    orthogonal neighbour steps the hero with verbs shown (kept); a drag on
    the map pans (kept).
  - delete as retired presentation: edge-pinned rect, top fallback, below
    strip, leader, tap-inside-card, recenter-vs-card.
- `map_overlay_layout_test.dart`:
  - delete the `placeActionCard` and `actionCardLeader` groups and the
    `recenterRect` lift cases; keep the base-square case.
  - `targetCardArea`: full map with no strip; strip rows removed at the top;
    flipped strip rows removed at the bottom (literal rects as today, no
    `hero`/`actionCard` arguments).
  - D1 case rewritten without the action card: map `Size(392.7, 423.9)`
    (10.1, the Task 13 widget figure — replace with the probe figure), hero
    centred and low, strip at the top, card clear of the strip and the hero
    block.
  - sweep rewritten without the action-card axis: target-card heights for
    2, 3, 4 lines at s 1.0 and 1.3 (the real card heights); maps
    `392.7 × (probe s 1.0 height)` and `392.7 × (probe s 1.3 height)`; strip
    per the flip rule. Assert at both scales: misses the strip and the hero
    cell; at s 1.0 also the target cell. At s 1.3 the target cell is **not**
    asserted in this task (intermediate map; Task 14 asserts it on the final
    map). Delete `dirty520`/`dirty489`.
- `crawl_layout_test.dart`: regions test → HUD, map, 6, log row, 6, bar, 7,
  menu, bottom gap; the four-state identity test adds the bar rect; the
  "note over the map" test finds `Underfoot:` inside `actionBarKey`, not
  inside the map slot.
- `target_card_test.dart`: the two action-card coexistence tests keep their
  fixtures and hero-block assertions and drop the action-card overlap
  assertion (retired surface); names say "with loot underfoot". The F3
  test (hero panned low, 1.3) is unchanged and must stay green.
- `crawl_verbs_test.dart`: `_cardVerb` scoped to `actionBarKey`; names say
  "the action bar". `battle_shelf_icons_test.dart`: `_shelfButton` scoped to
  `actionBarKey`.

**Mutation witnesses (required, after Green).** `sha256sum` snapshot of
`lib/game/action_bar.dart`, `lib/game/map_overlay_layout.dart` and
`lib/game/game_screen.dart` (copies outside the tree), then one at a time:
M1 omit the button-row `SizedBox` when `verbs` is empty → a bar-rect
identity test fails; M2 show `actionBarIdle` whenever `verbs` is empty →
the full-pack no-quiet-line case fails; M3 `targetCardArea` returns
`Offset.zero & map` → the D1 case and the sweep fail; M4 fixed `n = 4` →
the 1.3 five-button case fails; M5 `crawlGap` instead of `crawlPanelGap`
after the log row → the regions test fails. Restore each from the snapshot
copy (never from git) and show restored hashes equal the snapshot. A
surviving mutant means a missing assertion: add it before handoff.

**Green:** `dart format <touched Dart files>`, `flutter analyze`, full
`flutter test`. Map and bar figures for the receipt and the sweep sizes
come from an **untracked** probe (e.g. `test/widget/zz_probe_test.dart`),
deleted afterwards; `git status --short packages/app/test` shows no
untracked file. Never print from a tracked test.

## Executor discretion

Widget decomposition inside `action_bar.dart`; helper names; whether the
fact-line join is a private function; fixture helper names; probe layout.

## Escalate when

- `git diff --stat 7d99bea -- packages` is non-empty at start;
- any verb's guard, id, label, mark or dispatch would change;
- the bar at s 1.3 overflows with the largest fixture, or a button falls
  under 48 dp;
- the s 1.0 sweep finds any target-card hit on the strip, hero cell or
  target cell (report map, lines, hero rect, card rect);
- a flow test (suspend, door re-entry, world road) needs a verb where the
  bar cannot put it;
- the bar's measured height differs from `70 + 58 × s` by more than 0.01.

## Commit and receipt

Never `git stash`. Stage only your paths (both sides of each `git mv`) and
commit with an explicit pathspec:
`git commit -m 'feat(app): move moment actions into an ACTIONS bar below the map' -- <paths>`.

Receipt: Red output (the literal-finder failures), Green command and exit,
format and analyze exits, M1–M5 with before/after hashes, migrated/rewritten/
deleted test list, probe figures (map height and bar rect at s 1.0 and 1.3,
widget dp), sweep sizes used, the zero-hit grep for locked decision 7, and
the commit hash.
