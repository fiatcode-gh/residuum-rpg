# 08 — Character (hero) panel and the hero-label run constant

Governing: `../CONTRACT.md` scope item 4.5; `../PLAN.md` §2 G8 (hero panel
internals), G9 (panel marks), G11 (facts), §7 E4. Work from `packages/app`.

## Starting repository state

Task 07 committed. Inner Stack column is `[map, 7, LogPeek(96), 7]`.
`CrawlStatus` (header + HP/mana `ResourceMeter` row keyed `hpMeterKey` /
`manaMeterKey`) still sits at the top. `GameBloc({game, worldSeed, log, dungeon, stepDelay})`;
`main.dart` builds `GameBloc` in `_openRoadFight` (≈ line 415) and the
dungeon opener (≈ line 582), where `_saver.document` is the live
`SaveDocument` (`heroes[id].label`, `active`).

## Owned files

new `lib/game/hero_panel.dart`; `lib/game/crawl_style.dart` (panel
constants + frame decoration); `lib/game/game_bloc.dart` (constructor
field `heroLabel` only); `lib/main.dart` (the two `GameBloc(` sites only);
`lib/game/game_screen.dart` (insert the panel); `lib/game/crawl_status.dart`
(move `hpMeterKey`/`manaMeterKey` off the old resource row — see 5); new
`test/widget/hero_panel_test.dart`; tests broken by the moved keys
(`test/widget/crawl_status_test.dart`, `test/widget/crawl_layout_test.dart`).

Non-goals: combat panel (Task 09 swaps it in for battle), header (Task 10).

## Locked decisions

1. `GameBloc` gains `final String? heroLabel;` (constructor `this.heroLabel`),
   documented beside `dungeon` as a run constant. `main.dart` passes
   `heroLabel: _saver.document.heroes[_saver.document.active]!.label` at both
   construction sites (verify the expression compiles against `SaveDocument`).
2. Constants: `crawlHeroPanelHeight = 102`, `crawlPanelGap = 6`,
   `crawlPanelRadius = 6`, and
   `const BoxDecoration crawlFrameDecoration = BoxDecoration(color: crawlPanelFill, border: Border.fromBorderSide(BorderSide(color: crawlFrame)), borderRadius: BorderRadius.all(Radius.circular(6)));`.
3. `HeroPanel({required GameViewState state, required String? heroLabel})`
   keyed `heroPanelKey`, height `102 × crawlScale`, margin h `crawlGutter`,
   internals exactly PLAN G8 "Hero panel internals" and facts exactly G11
   (hero label upper-cased, blank when null; `HP a/b`, `Mana a/b` only with
   known spells, equal-height `SizedBox` otherwise; stats
   `ATK a–b  ARM n  GOLD g` with labels `monoDataDim`, values `monoData`;
   weapon/armour names `monoItem` max 2 lines ellipsis; `Potion ×N`;
   `n/$inventoryCap`). A private `_CrawlMeter(label, value, ceiling, fill)`
   renders the text row + 6 dp bar (`crawlMeterTrack` track, radius 3) and
   carries the meter key. Marks via `ActionMarkView` (G9: `gavel`/
   `front_hand`, `shield`/`shield_outlined`, shipped potion/pack at 16 dp).
4. `GameScreen` inner Column becomes `[Expanded(map), SizedBox(6), HeroPanel, SizedBox(7), LogPeek, SizedBox(7)]`
   in every mode for now (Task 09 switches battle to the combat panel).
5. Key ownership: `hpMeterKey`/`manaMeterKey` move to the hero panel meters;
   the old `CrawlStatus` resource row keeps rendering its meters without
   keys until Task 10 deletes it (a temporary duplicate display, not a
   duplicate key).

## Proof (Red first)

`test/widget/hero_panel_test.dart` on `onTheTargetPhone`:
- panel height 102; three columns in flex 40/33/27 order (left x < middle x
  < right x); texts: hero label from `GameBloc(heroLabel: 'Mira')` →
  `MIRA`; `HP 12/20` for hp 12 / maxHp 20 (clamped at 0 when dead);
  `Mana 3/5` only when a spell is known (panel height unchanged either
  way); `ATK`, `ARM`, `GOLD` values equal `state.attack`, `state.armor`,
  `state.game.gold`; weapon display name or `Bare fists`; chest display
  name or `None`; `Potion ×2`; `3/20`.
- the long name `Rare Keen Iron Sword of Embers` renders in ≤ 2 lines
  without overflow errors; at text scale 1.3 the panel grows to 132.6 and
  nothing overflows.
- negative: none of `WANDERER`, `Torch`, `Hungry`, `Seed` appear.
- `crawl_status_test.dart`/`crawl_layout_test.dart` keyed-meter tests now
  find the keys in the hero panel (update finders, keep value assertions).
Expected Red: `HeroPanel` missing.
Green: `flutter test test/widget/hero_panel_test.dart test/widget/crawl_status_test.dart test/widget/crawl_layout_test.dart test/game_bloc_test.dart`,
`dart format <touched>`, `flutter analyze`.

## Executor discretion

Private widget split; exact `Row`/`Column` nesting within the locked
y-offsets (±1 dp); test fixture helpers.

## Escalate when

The hero label is not reachable at either `main.dart` site; a fact in G11
has no getter; the panel cannot hold its rows at 102 dp with the locked
roles.

## Completion receipt

Red output, Green command/exit, analyzer/format exits, measured panel rect.
Commit: `feat(app): add the crawl character panel`.
