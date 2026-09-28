# 09 — Turn-order strip over the map; dock row removed; final layout invariants

Governing: `../CONTRACT.md` settled decision 9, scope §1.2, §5 (turn-order
strip), acceptance 1, 2, 3, 9; `../PLAN.md` §1, §2 G5, G10 (strip), G11.
Work from `packages/app`.

## Starting repository state

Task 08 committed. `GameScreen` column: `CrawlHud`, `if (isBattleOpen) BattleDock(state, onActorSelected: TimelineActorSelected)`
(58·s, NOW/NEXT columns with labels above 24 dp pills, NEXT in a horizontal
`SingleChildScrollView` that clips with no cue), `Expanded(… map slot with
MapOverlays (place pop-up, target card, recenter) …, LogRow)`, `CrawlMenu`.
`lib/game/battle_view.dart` holds `BattleDock`, `_TimelineColumn`,
`_TimelineDivider`, `_TimelineToken`, `_TimelinePill`. `crawl_layout_test`
documents battle map rect = exploration − dock height.

## Owned files

`git mv lib/game/battle_view.dart lib/game/turn_order_strip.dart`
(rewritten), `lib/game/map_overlays.dart`, `lib/game/game_screen.dart`,
`lib/game/crawl_style.dart`; tests `git mv test/battle_view_test.dart test/turn_order_strip_test.dart`
only if the file's remaining content is about the strip (otherwise keep the
name and migrate), `test/widget/crawl_layout_test.dart` (final form),
`test/battle_characterization_test.dart`, `test/widget/dungeon_scene_bleed_test.dart`,
`test/widget/crawl_surfaces_test.dart`, `test/widget/map_touch_wiring_test.dart`
(dock references), new `test/game/turn_order_fit_test.dart`.

Non-goals: activation schedule/identity/secrecy (`activationQueue`,
`projectActivationQueue`), selection semantics, card content.

## Locked decisions

1. `TurnOrderStrip({required GameViewState state, required ValueChanged<Actor> onActorSelected})`
   exactly per PLAN G10 strip: one line, `crawlStripHeight = 48` × s, fill
   `crawlCalloutFill`, hairline `crawlFrame` edge, `NOW` + pill, divider,
   `NEXT` + visible pills, `+N` cue keyed `turnOrderMoreKey`; pills keep
   `timeline-current-hero`, `timeline-next-hero`,
   `timeline-actor-<id>-<index>` keys, glyph/word/style/current border and
   semantics; each token's tap area is the full strip height and ≥ 48 wide;
   no scroll view.
2. Pure `int tokensThatFit(List<double> widths, double available, double spacing, double Function(int hidden) cueWidth)`
   in `turn_order_strip.dart`; widths from `TextPainter` measurement (PLAN
   G10), painters disposed. NOW is always shown.
3. `MapOverlays` owns the strip: top edge by default; when the hero cell
   overlaps the top strip rect, bottom edge with a 64 dp right inset. The
   strip rect joins the avoid lists of the place pop-up and the target card.
4. `GameScreen` removes the `BattleDock` row; `crawlTimelineHeight` and the
   `dock-backing` key are deleted.

## Proof (Red first)

- `turn_order_fit_test.dart`: all fit → all, no cue; one too many → k with
  cue width reserved; cue width growing with hidden count (1 → 9 → 10)
  never lets the row exceed `available`; zero NEXT tokens.
- Strip widget test at `onTheTargetPhone`: 1 actor → NOW `@ You`, NEXT
  `@ You`, no cue; 4+ visible actors (hero + dire wolf + two giant rats + a
  ghoul) → every shown pill's rect lies fully inside the strip, the cue
  reads `+N` with N = hidden count, no overflow error; a hidden actor ends
  the queue (secrecy unchanged); tapping a pill selects that actor and the
  target card names it; the strip never overlaps the hero cell (centred and
  panned-to-top cases → flipped to the bottom).
- `crawl_layout_test.dart` final: at `onTheTargetPhone` the map rect is
  identical in exploration, Watched, battle and armed; the HUD and its HP,
  mana and gold rects are identical in all four; the log row rect is
  identical in all four; the menu shows Quests, Spells, Quick, Hero in all
  four; regions top → bottom HUD, map, log row, menu inside the safe body
  with the gesture clearance; nothing overflows at text scale 1.3.
Expected Red: battle map rect ≠ exploration (dock row); the fourth pill
clips with no cue.
Green: full `flutter test`, `dart format <touched>`, `flutter analyze`.

## Executor discretion

Strip widget decomposition; how the measured widths are cached per build;
which existing battle fixtures stage four actors.

## Escalate when

The strip cannot show NOW plus the cue in the map width at text scale 1.3;
an activation/secrecy test changes; the flip rule conflicts with the place
pop-up or card placement at the target size.

## Completion receipt

Red output, Green command/exit, format/analyze exits, the four-state map
rect (widget dp), fit test cases, migrated/deleted tests. Commit:
`feat(app): float the turn order over the map and fix the map rectangle`.
