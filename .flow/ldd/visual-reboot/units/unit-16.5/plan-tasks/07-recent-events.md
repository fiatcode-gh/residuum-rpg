# 07 — Recent events peek and expanded log sheet

Governing: `../CONTRACT.md` scope items 4.6 and "Expanded log", acceptance
8; `../PLAN.md` §2 G8 (recent events, expanded log), G10, §7 E3. Work from
`packages/app`.

## Starting repository state

Task 06 committed: skeleton with inner `Stack[Column[map, 7, LogPeek, 7], LogDrawer?]`
and `CrawlActionBar` outside it. `log_drawer.dart::LogPeek` is 104 dp
(`crawlLogPeekHeight`) with a heading and a reverse `ListView`;
`LogDrawer` is `FractionallySizedBox` 0.45/1.0 with handle pill, title +
count + close `CrawlPill`, `_LogRow` (mark well + sentence,
newest `textLine`, older `textLineDim`), follow/unread via
`ScrollController`, unread `CrawlPill`. `LogCategory` has `mark` and `word`.

## Owned files

`lib/game/log_drawer.dart`, `lib/game/log_line.dart` (delete `mark` only),
`lib/game/crawl_style.dart` (log constants), `lib/game/game_screen.dart`
(drawer positioning inside the inner Stack only); tests
`test/widget/log_drawer_test.dart`, `test/game/log_line_test.dart`,
`test/game/log_drawer_state_test.dart` (only if it references marks),
`test/style/type_authority_test.dart` (drop absent-mark entries whose only
consumer was `log_line.dart`/`crawl_status.dart` **only if** you removed that
consumer — `crawl_status.dart` marks stay until Task 10),
`test/widget/crawl_layout_test.dart` (peek/drawer geometry assertions).

Non-goals: bloc log reducers (`LogDrawerHandlePulled`, `LogDrawerClosed`,
`LogFollowBroken/Resumed`, unread counting) and log text — unchanged.

## Locked decisions

1. Constants: `crawlEventsHeight = 96`, `crawlLogLine = 15`,
   `crawlLogSheetHeight = 345`, `crawlLogSheetHeader = 40`,
   `crawlLogRowPadding = 1.5`, `crawlLogPictogram = 15`; delete
   `crawlLogPeekHeight`, `crawlMarkColumn`, `crawlMarkWell`,
   `crawlLogRowRhythm` if unused.
2. `logPictogram(LogCategory)` and `logTint(LogCategory)` per PLAN G10
   (exhaustive switches in `log_drawer.dart`).
3. `LogPeek` (keyed `logPeekKey`, semantics button "Open the message log",
   tap → `LogDrawerHandlePulled`, inert on game over): height
   `crawlEventsHeight × crawlScale`; frame fill `crawlPanelFill`, 1 dp
   `crawlFrame`, radius 6, horizontal margin `crawlGutter`; internals PLAN G8
   "Recent events internals": header row (`RECENT EVENTS` `displaySection`;
   right `${state.log.length} entries` `monoMeta` + `Icons.unfold_more` 16
   `crawlTextDim`), rule, then four fixed 15 dp slots, bottom-aligned:
   the last `min(4, log.length)` lines oldest→newest, `maxLines: 1`,
   `TextOverflow.ellipsis`, style `logTint(category)`, older lines in
   `Opacity(0.72)`. No category pictogram in the peek. No timestamps.
4. `LogDrawer` positioned in the inner Stack by `GameScreen`:
   `Positioned(left: 0, right: 0, bottom: 0, top: extent == full ? 0 : null, child: extent == half ? SizedBox(height: min(345·scale, overlayHeight)) : …)`
   (use a `LayoutBuilder` on the inner Stack for `overlayHeight`). Sheet:
   fill `crawlPanelFill`, top border 1 dp `crawlFrame`, top radius 6,
   horizontal margin `crawlGutter`. Header 40: a 32 × 3 `crawlTextDim` pill
   centred at y 3; left `RECENT EVENTS` `displaySheetTitle` inside a
   `GestureDetector` keyed `logHandleKey` (semantics "Resize the message
   log", tap → `LogDrawerHandlePulled`) spanning the header except the close
   control; right `${log.length} entries` `monoMeta`, gap 12, close
   control keyed `logCloseKey` (semantics "Close the message log",
   40 × 40, `Icons.close` 18 `crawlTextDim`) → `LogDrawerClosed`. Rule 1 dp
   `crawlDivider`. List: chronological (oldest first), rows
   `Row[SizedBox(24, child: Icon(logPictogram, 15, color: tint colour)), Expanded(Text(sentence, style: logTint))]`
   with vertical padding 1.5, wrapping allowed; non-newest rows at
   `Opacity(0.78)`; semantics `'${category.word}. ${sentence}'` with the
   row's visuals excluded. `RawScrollbar(controller, thumbVisibility: true, thickness: 3, radius: Radius.circular(1.5), thumbColor: Color(0x809CA3AF))`.
   Follow/unread logic, `_followTolerance`, unread `CrawlPill` keyed
   `logUnreadKey` with `'↓ N new'` unchanged.
5. Delete `LogCategory.mark` and every use.

## Proof (Red first)

`log_drawer_test.dart` on `onTheTargetPhone`:
- peek: height 96; header reads `RECENT EVENTS` and the true entry count;
  with a 6-entry log whose last sentence is 54 characters, exactly the last
  four sentences are present in order oldest→newest top→bottom, each
  `Text` has `maxLines == 1`, and every line's rect lies inside the peek
  frame (no vertical clipping); newest opacity 1, older 0.72; empty and
  one-line logs render without exception.
- drawer: half height 345 (or overlay height when smaller), bottom edge at
  the inner Stack bottom (action bar still hit-testable: tap a slot while
  the drawer is open → its action dispatches), full extent top = map slot
  top; handle cycles peek → half → full → peek; close collapses from full;
  every `LogCategory` row shows `find.byIcon(logPictogram(c))` with the
  sentence in `logTint(c)` and semantics word; follow/unread/resume tests
  keep their existing assertions.
- map slot and peek rects unchanged at every extent.
Expected Red: peek height 104, no count, no pictograms.
Green: `flutter test test/widget/log_drawer_test.dart test/game test/widget/crawl_layout_test.dart test/style/type_authority_test.dart`,
`dart format <touched>`, `flutter analyze`.

## Executor discretion

Widget decomposition inside `log_drawer.dart`; whether the four peek slots
are a `Column` of `SizedBox`es or a fixed-extent list.

## Escalate when

Four lines cannot fit in 96 dp with the locked roles on the test surface;
follow/unread needs a reducer change; the drawer overlay blocks the action
bar; a category needs a colour-only distinction.

## Completion receipt

Red output, Green command/exit, analyzer/format exits, measured peek line
rects. Commit: `feat(app): restyle recent events and the expanded log`.
