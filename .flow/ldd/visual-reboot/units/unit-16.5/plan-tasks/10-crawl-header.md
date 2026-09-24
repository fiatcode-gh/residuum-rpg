# 10 — Crawl header: wordmark, meta line, status chips; world-day run constant

Governing: `../CONTRACT.md` scope item 4.1–4.3; `../PLAN.md` §2 G8 (header
internals), G9 (chip shapes), G11 (depth, place, day, chips), §7 E4. Work
from `packages/app`.

## Starting repository state

Task 09 committed. `lib/game/crawl_status.dart::CrawlStatus` (framed place /
battle glyph+word / depth pair row plus an unkeyed HP/mana row) is the
first child of the `GameScreen` column; `depthPairKey` is on its depth pair;
`_placeName`, `_battleWord`, `_condition` live there. `GameBloc` has
`dungeon` and `heroLabel` run constants. `main.dart` knows
`_world.state.world.day` at both `GameBloc(` sites.

## Owned files

new `lib/game/crawl_header.dart`; delete `lib/game/crawl_status.dart`
(move `_placeName`/`_condition` logic, `depthPairKey`, `hpMeterKey`,
`manaMeterKey` declarations to their new owners — meters' keys to
`hero_panel.dart`); `lib/game/game_bloc.dart` (`day` field only);
`lib/main.dart` (two `GameBloc(` sites); `lib/game/game_screen.dart`
(header slot); `lib/game/crawl_style.dart` (`crawlHeaderHeight = 88`);
`test/widget/crawl_status_test.dart` → rename to
`test/widget/crawl_header_test.dart`; `test/style/type_authority_test.dart`
(remove `✖` `◉` from the absent set if no consumer remains);
`test/widget/world_screen_test.dart`, `test/widget/crawl_layout_test.dart`
finders.

Non-goals: timeline (Task 11); no menu/settings/seed/torch/hunger.

## Locked decisions

1. `GameBloc` gains `final int? day;`; `main.dart` passes
   `day: _world.state.world.day` at both sites. Before coding, grep
   `WorldBloc` handlers: if any can change `world.day` while a crawl route is
   open, stop and escalate (PLAN §7 E4).
2. `CrawlHeader({required GameViewState state, required NodeId? dungeon, required int? day})`
   keyed `crawlHeaderKey`, height `88 × crawlScale`, internals exactly PLAN
   G8 "Header internals":
   - `RESIDUUM` `displayWordmark`, centred; 1 dp `crawlGoldRule` rule with
     `crawlGutter` side margins; no buttons.
   - meta `Row` centred, `monoMeta`: `Depth ${state.depth}/${state.deepest}`
     (keyed `depthPairKey`, omitted on encounters), `The Road` on encounters
     else `residuumWorld.nodeAt(dungeon!).name` (title case as stored),
     `Day $day` when non-null; separators `  |  ` in `monoMeta`.
   - chips `Row` centred, spacing 8, in order battle, condition, ward
     (keys `crawlChipBattleKey`, `crawlChipConditionKey`, `crawlChipWardKey`);
     words `Engaged N`/`Watched N`, `Steady`/`Wounded`/`Critical`/`Dead`
     (thresholds of the old `_condition`), `Ward N`; each with its G9 shape
     drawn by one private `CustomPainter` taking an enum.
3. `GameScreen` first child becomes `CrawlHeader`; `CrawlStatus` is deleted.
   Semantics: the chips row reads each chip's word; the wordmark is
   excluded from semantics (brand, not state).

## Proof (Red first)

`test/widget/crawl_header_test.dart` (port every behaviour the old
`crawl_status_test.dart` proved, not its layout pins):
- the crypt reads `Depth 1/5 | The Crypt | Day 3` (fixture `day: 3`); the
  sea-cave and keep read their own depths; a road fight reads
  `The Road | Day 3` and `depthPairKey` is absent; with `day: null` the day
  segment is absent;
- battle → `Engaged 2` chip with the diamond shape; watched → `Watched 1`
  with the ring; neither → no battle chip; HP 4/20 → `Critical`; 10/20 →
  `Wounded`; 20/20 → `Steady`; 0 → `Dead`; warded 3 → `Ward 3`; not warded →
  no ward chip;
- header height 88 in exploration and battle; at text scale 1.3 it is
  114.4 and nothing overflows (replaces the old "legible at 1.3x" test);
- negatives: no `Seed`, `Torch`, `Hungry`, `Clear`, menu or settings icon.
Expected Red: `CrawlHeader` missing.
Green: `flutter test test/widget/crawl_header_test.dart test/widget test/game_bloc_test.dart test/style/type_authority_test.dart`,
`dart format <touched>`, `flutter analyze`.

## Executor discretion

Shape painter geometry within an 8 dp box; row widget split; how separators
are rendered.

## Escalate when

The day can change during a crawl; any place name is not reachable without
core; chips overflow 376.7 dp at scale 1.0 with the longest words
(`Engaged 9`, `Critical`, `Ward 12`).

## Completion receipt

Red output, Green command/exit, analyzer/format exits, WorldBloc day
finding (file:line), measured header rect. Commit:
`feat(app): add the crawl wordmark header and status chips`.
