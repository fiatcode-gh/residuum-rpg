# 04 — HUD replaces the wordmark header; hero and combat panels removed

Governing: `../CONTRACT.md` settled decision 7, scope §1.1 and "Removed from
the crawl", acceptance 1–2; `../PLAN.md` §1, §2 G5, G7, G11. Work from
`packages/app`.

## Starting repository state

Checkpoint A accepted; Tasks 01–03 committed. `GameScreen` column:
`CrawlHeader` (88: wordmark, gold rule, meta, chips), battle `BattleDock`,
`Expanded(Stack[Column[map slot, 6, isBattleOpen ? CombatPanel (124) : HeroPanel (102), 7, LogPeek (96), 7], drawer])`,
`CrawlActionBar` (60), 6. `GameBloc` carries `heroLabel` (only `HeroPanel`
reads it; `main.dart` passes it at two sites, ~421 and ~587).
`test/support/phone.dart::onTheTargetPhone` is the vivo I2219 with bars
(1080 × 2408 @ 2.75, padding top 38.2 / bottom 17.8 dp).

Main supplies the Checkpoint A cut-out inset `T` (dp) in the dispatch
message; if absent use `T = 24.0`.

## Owned files

`git mv lib/game/crawl_header.dart lib/game/crawl_hud.dart` (rewritten),
new `lib/game/crawl_meter.dart`, `lib/game/game_screen.dart`,
`lib/game/crawl_style.dart`, `lib/game/game_bloc.dart` (`heroLabel` only),
`lib/main.dart` (the two `heroLabel:` arguments only), `lib/style/tokens.dart`
(orphan deletions only); delete `lib/game/hero_panel.dart`,
`lib/game/combat_panel.dart`, `test/widget/hero_panel_test.dart`,
`test/widget/combat_panel_test.dart`; `git mv test/widget/crawl_header_test.dart test/widget/crawl_hud_test.dart`
(rewritten); `test/widget/crawl_layout_test.dart` (rewritten);
`test/support/phone.dart`; `test/style/type_authority_test.dart` (role
table rows of deleted tokens); any test that referenced the deleted
widgets/keys.

Non-goals: log peek, action bar, timeline dock, callout, pack screen.

## Locked decisions

1. `CrawlHud` exactly per PLAN G7, keyed `crawlHudKey`; keeps
   `depthPairKey`, `crawlChipBattleKey`, `crawlChipConditionKey`,
   `crawlChipWardKey`, `ChipMark`, `ChipMarkPainter`, `_MetaLine`,
   `_ChipsRow`, `_battleChip`, `_conditionChip`, `_placeName`,
   `_StatusChip` unchanged; adds `hpMeterKey`, `manaMeterKey` (moved from
   `hero_panel.dart`) and `crawlGoldKey`. `crawlHudHeight = 80` in
   `crawl_style.dart`.
2. `crawl_meter.dart`: public `CrawlMeter({required String label, required int value, required int ceiling, required Color fill, double barHeight = 6, super.key})`
   — today's `_CrawlMeter` body with the gap set to 3 and the bar height
   parameterised.
3. `GameScreen` column becomes `CrawlHud`, battle `BattleDock` (unchanged
   for now), `Expanded(Stack[Column[map slot, SizedBox(crawlPanelGap), LogPeek, SizedBox(crawlGap)], drawer])`,
   `CrawlActionBar`, `SizedBox(crawlBottomGap)`.
4. Delete `HeroPanel`, `CombatPanel`, `ColumnDivider`, `crawlHeaderHeight`,
   `crawlHeroPanelHeight`, `crawlCombatPanelHeight`, `GameBloc.heroLabel`
   (constructor parameter, field, dartdoc) and the two `main.dart`
   arguments; delete every token left with no `lib/` consumer (grep each
   of `displayWordmark`, `crawlGoldRule`, `monoFigure`, `monoFigureCold`,
   `displayNameCold`; remove their rows from `type_authority_test.dart`).
5. `onTheTargetPhone` becomes the vivo I2505 full-screen profile:
   `physicalSize (1080, 2392)`, `devicePixelRatio 2.75`,
   `padding = FakeViewPadding(top: T * 2.75)`, bottom 0; its dartdoc is
   deleted (test support is app code).

## Proof (Red first)

- `crawl_hud_test.dart` (rewrite; delete wordmark/gold-rule/88 dp/114.4 dp
  literal tests — they pin the retired header): no `RESIDUUM` text in the
  crawl; HP reads `HP a/b` with `a` clamped at 0 for a dead hero; mana
  meter present iff a spell is known, and the gold rect is identical with
  and without spells; gold shows `game.gold`; HUD height is
  `crawlHudHeight × crawlScale` at text scale 1.0 and 1.3 with no overflow;
  meta line and chip facts as before (Engaged/Watched/condition/ward words
  and shapes, depth omitted on the road).
- `crawl_layout_test.dart` (rewrite at `onTheTargetPhone`; delete the
  45 %/35 % floor and panel-height tests): regions top → bottom HUD, map,
  log peek, bar, each inside the safe body; the HUD rect and the HP, mana
  and gold rects are identical in exploration, Watched, battle and armed
  (`SkillArmed` dispatched directly); the map rect is identical in
  exploration, Watched and armed (battle differs only by the dock until
  Task 09 — assert that difference equals the dock's height, so the test
  documents it).
- Migrated facts from the deleted panel tests that are still true (HP/mana
  keys, clamp) live in `crawl_hud_test.dart`; target facts stay covered by
  `map_callout_test.dart` and the `targetActor` bloc tests.
Expected Red: `RESIDUUM` found; `HeroPanel` makes the exploration map rect
differ from battle by more than the dock.
Green: full `flutter test`, `dart format <touched>`, `flutter analyze`.

## Executor discretion

Internal widget split of the HUD; fixture helpers; how the four states are
staged (reuse existing crawl fixtures).

## Escalate when

A test outside the crawl breaks because of `onTheTargetPhone` or a token
deletion; a deleted token still has a `lib` consumer outside the removed
widgets; the HUD cannot fit its rows at scale 1.3 in 80·s.

## Completion receipt

Red output, Green command/exit, format/analyze exits, deleted files/tokens
list, widget-level map heights for exploration and battle (labelled widget
dp). Commit: `feat(app): replace the crawl header and panels with a fixed HUD`.
