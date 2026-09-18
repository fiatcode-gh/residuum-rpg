# Task 02 — Information Hierarchy: Timeline Panel, Log Peek and Drawer

Owner: one fresh `flow-plan-executor` on the Unit 12 feature checkout.

Read `../CONTRACT.md`, `../recon.md`, `../PLAN.md`, then
`packages/app/lib/game/battle_view.dart`,
`packages/app/lib/game/log_drawer.dart`,
`packages/app/lib/game/activation_timeline.dart`,
`packages/app/lib/game/log_line.dart`,
`packages/app/lib/game/crawl_style.dart`,
`packages/app/lib/game/crawl_surfaces.dart`,
`packages/app/test/battle_view_test.dart` and
`packages/app/test/widget/log_drawer_test.dart` before editing. Look at frames
3–5 of `.flow/evidence/visual-reboot/residuum_visual_reboot_approved_mock.png`.

All commands run from `packages/app`.

## Starting condition

- the Unit 12 feature checkout with Task 01's repository state accepted;
- `lib/game/crawl_style.dart` exists and holds Task 01's membership only:
  `crawlInk`, `crawlDim`, `crawlPanel`, `crawlRule`, `crawlVoid`,
  `crawlRaised`, `crawlRecessed`, `crawlGutter`, `crawlRhythm`, `crawlRadius`,
  `crawlHairline`, `crawlTapTarget`, `crawlPlace`, `crawlBody`,
  `crawlBodyDim`, `crawlTheme`;
- `lib/game/crawl_surfaces.dart` exists and holds `CrawlPill` only;
- `GameScreen`'s `Column` is `CrawlStatus → BattleDock → Expanded map →
  LogPeek → BattleShelf → _Controls`, and its `Scaffold` is wrapped in
  `Theme(data: crawlTheme, …)`;
- `battle_view.dart` and `log_drawer.dart` are untouched by Unit 12:
  `dockBacking` still exists at `battle_view.dart:15`, and
  `log_drawer.dart:12-28` still declares `_logBacking`, `_logNewest`,
  `_logOlder`, `_logHandle`, `_newestRowStyle`, `_olderRowStyle`, `_rowStyle`;
- `format`, `analyze` and the full `packages/app` suite were green at Task 01's
  handoff.

Inspect branch, HEAD and worktree before editing. If any of the above is false,
stop and report rather than adapting.

## Behavioral slice

Time and causality each read as a deliberate region. The activation timeline
becomes the mock's panel — `NOW` and `NEXT` as region captions, ringed tokens,
the actor's word beneath each token, chevrons between — while order, literal
repetition, badge identity, silent truncation and the no-turn-cost inspect stay
exactly as they are. The log peek gains a surface and an explicit expand
affordance; the expanded drawer gains the mock's handle, title, hairline rule,
line rhythm and inset mark well, with contents, ordering, the extent cycle,
follow, unread and `↓ N new` unchanged.

This task does **not** touch the action row, the chips, the overlays or the
enemy info sheet.

## Owned files

- `packages/app/lib/game/crawl_style.dart` — append this task's members;
- `packages/app/lib/game/crawl_surfaces.dart` — append `CrawlPanel` and
  `CrawlRegionLabel`;
- `packages/app/lib/game/battle_view.dart` — `BattleDock` and `_TimelineToken`
  only; do not touch `showEnemyInfo` or `_EnemyInfoLine`, which are Task 03's;
- `packages/app/lib/game/log_drawer.dart`;
- `packages/app/test/battle_view_test.dart` — the named sites only;
- `packages/app/test/widget/log_drawer_test.dart`.

Do not touch `game_screen.dart`, `crawl_status.dart`,
`activation_timeline.dart`, `log_line.dart`, `game_bloc.dart`,
`action_icon.dart`, `spell_row.dart`, `pack_screen.dart`, `main.dart`,
`town_style.dart`, Unit 11's renderer, `packages/core` or `packages/content`.

## Locked decisions

### Appended to `crawl_style.dart`

```dart
const TextStyle crawlRegionLabel = TextStyle(
  fontFamily: 'monospace',
  fontSize: 11,
  letterSpacing: 2,
  fontWeight: FontWeight.w600,
  color: crawlDim,
);
const TextStyle crawlPanelTitle = TextStyle(
  fontFamily: 'monospace',
  fontSize: 13,
  letterSpacing: 2,
  fontWeight: FontWeight.w600,
  color: crawlInk,
);
const TextStyle crawlLine = TextStyle(
  fontFamily: 'monospace',
  fontSize: 13,
  color: crawlInk,
);
const TextStyle crawlLineOlder = TextStyle(
  fontFamily: 'monospace',
  fontSize: 13,
  color: crawlDim,
);
const TextStyle crawlGlyph = TextStyle(
  fontFamily: 'monospace',
  fontSize: 18,
  color: crawlInk,
);
const TextStyle crawlTokenWord = TextStyle(
  fontFamily: 'monospace',
  fontSize: 11,
  color: crawlDim,
);
const TextStyle crawlChevron = TextStyle(
  fontFamily: 'monospace',
  fontSize: 18,
  color: crawlDim,
);

const double crawlPanelPadding = 8;
const double crawlTokenCell = 44;
const double crawlTokenWidth = 76;
const double crawlLogPeekHeight = 104;
const double crawlMarkColumn = 24;
const double crawlMarkWell = 20;
const double crawlLogRowRhythm = 3;
```

Append nothing else. Do not add the chip type, chip-state table or overlay
colours — those are Task 03's.

### Appended to `crawl_surfaces.dart`

```dart
class CrawlPanel extends StatelessWidget {
  const CrawlPanel({
    required this.child,
    this.padding = const EdgeInsets.all(crawlPanelPadding),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
}

class CrawlRegionLabel extends StatelessWidget {
  const CrawlRegionLabel(this.word, {super.key});

  final String word;
}
```

`CrawlPanel`: `crawlPanel` fill, `BorderRadius.circular(crawlRadius)`,
`Border.all(color: crawlRule, width: crawlHairline)`, `padding` inside. It
takes **no margin** — callers supply their own so the column's rhythm stays one
decision per slot. `CrawlRegionLabel` renders `Text(word, style:
crawlRegionLabel)` and nothing else: it is a region caption, never per-entry
prose.

### The timeline panel

`BattleDock`'s build becomes:

```text
Padding(horizontal: crawlGutter, vertical: crawlRhythm)
  CrawlPanel(key: const Key('dock-backing'), padding: all(crawlPanelPadding))
    Column(mainAxisSize: min, crossAxisAlignment: start)
      Row(  SizedBox(width: crawlTokenWidth, child: Center(CrawlRegionLabel('NOW'))),
            SizedBox(width: <chevron gap>),
            if (hasRemainder) CrawlRegionLabel('NEXT')  )
      SizedBox(height: crawlRhythm)
      Row(  <cell for queue[0]>,
            if (hasRemainder) Text('›', style: crawlChevron),
            if (hasRemainder)
              Expanded(SingleChildScrollView(scrollDirection: horizontal,
                Row(mainAxisSize: min, <cells for queue[1..] joined by '›'>)))  )
```

Locked properties:

- `Key('dock-backing')` moves to the `CrawlPanel`, so
  `battle_view_test.dart`'s descendant and scroll-extent assertions keep their
  anchor. `dockBacking`'s `Color(0xB30E1015)` constant is deleted: the timeline
  is a panel in the column now, not a translucent wash over the map.
- **`queue[0]` is pinned outside the scroller.** It is always the current hero
  (`projectActivationQueue` at `activation_timeline.dart:23`), so `NOW` labels
  a cell that cannot scroll away and `NEXT` labels exactly the scrolling
  remainder.
- **`hasRemainder` is `queue.length > 1`.** When the queue truncates to the
  current hero alone, the panel shows `NOW`, that one cell, and nothing else:
  no `NEXT` over emptiness, no chevron, no scroller, no placeholder, no
  ellipsis. That is how the caption coexists with the silence rule.
- the scroller stays a `SingleChildScrollView` + `Row`. **Do not introduce a
  `ListView` anywhere:** `battle_view_test.dart:307,558` assert the crawl
  holds exactly one, and it is `LogPeek`'s. It also stays the panel's only
  `Scrollable`, so the overflow-and-drag proof at `:530-550` keeps working.
- one **cell** is `SizedBox(width: crawlTokenWidth)` holding a `Column`:
  - the ring: `Container(width: crawlTokenCell, height: crawlTokenCell,
    decoration: BoxDecoration(shape: BoxShape.circle, color: crawlRaised,
    border: Border.all(color: crawlRule, width: crawlHairline)), alignment:
    Alignment.center)` with the glyph in `crawlGlyph`;
  - the word: `SizedBox(width: crawlTokenWidth, child: FittedBox(fit:
    BoxFit.scaleDown, child: Text(word, style: crawlTokenWord)))`. `FittedBox`,
    not `TextOverflow.ellipsis` — no label may ellipsise, and this is the same
    idiom `crawl_status.dart` already uses.
- the hero cell's glyph is `'@'` and its word is `'You'`. The single literal
  `'@ YOU'` at `battle_view.dart:99` is gone; its two facts are composed
  instead.
- the actor cell's glyph is `presentation.glyphLabel` verbatim, in a `Text`, so
  `find.text('g²')` still resolves; its word is
  `presentation.displayName` verbatim. `presentation == null` still returns
  `const SizedBox.shrink()`.
- unchanged: `Key('timeline-current-hero')`, `Key('timeline-next-hero')`,
  `Key('timeline-actor-${actor.id}-$queueIndex')`, the `InkWell` ancestor on
  actor cells and its `onTap: () => onActorSelected(actor)`, the `Semantics`
  labels `'You, current activation'`, `'You, next activation'` and
  `presentation.displayName`, and `button: true` on actor cells only.
- both cell `Semantics` gain `excludeSemantics: true`, so the ring glyph and
  the word do not double-announce. The declared `label` and `button`
  properties the tests read are untouched.
- **no per-token current or selected visual state is added.** The current hero
  is distinguished by key, by semantic label and by sitting under `NOW`;
  `state.selectedActorId` continues to have no visual effect. The mock's
  brighter NOW ring is deliberately not adopted: AC7 freezes the
  current/selected distinction.
- `projectActivationQueue`, `state.activationQueue`, `TimelineActorSelected`
  and `showEnemyInfo` are not edited.

### The log peek

`crawlLogPeekHeight` (104) stays the **slot** height, so the reorder costs the
map nothing:

```text
Semantics(button: true, enabled: !isGameOver, label: 'Open the message log')
  GestureDetector(behavior: opaque, onTap: isGameOver ? null : LogDrawerHandlePulled)
    SizedBox(key: logPeekKey, height: crawlLogPeekHeight, width: infinity)
      Padding(horizontal: crawlGutter, vertical: crawlRhythm)
        CrawlPanel(padding: symmetric(horizontal: crawlPanelPadding, vertical: crawlRhythm))
          Row(  Expanded(<reverse ListView of sentences>),
                SizedBox(width: crawlRhythm),
                Text('›', style: crawlChevron)  )
```

- the `_HandlePill` is dropped from the peek and the mock's explicit expand
  affordance replaces it: the trailing chevron, vertically centred, outside the
  list. `_HandlePill` stays private and is still used by the drawer.
- the `ListView` keeps `reverse: true`, `itemCount: state.log.length`, the
  `state.log[state.log.length - 1 - index]` indexing, and `_rowStyle(index ==
  0)` — newest last, newest brighter, no category marks.
- `logPeekKey` stays on the outermost tappable widget so
  `log_drawer_test.dart`'s peek-rect stability assertions keep working.
- the `'Open the message log'` label, the game-over inert rule and
  `LogDrawerHandlePulled` are unchanged.

### The expanded drawer

`LogDrawer`'s `Align`/`FractionallySizedBox` geometry, its 0.45/1.0 extents,
`logDrawerKey`, `logHandleKey`, the `_HandlePill`, the `ScrollController`,
`_followTolerance = 8`, `_lastLogLength`, `initState`, `didUpdateWidget`,
`dispose`, `_maybeJumpToNewest`, `_jumpToNewest`, `_onScroll`,
`LogFollowBroken`, `LogFollowResumed` and `LogDrawerClosed` are all unchanged.
It gains:

- the title in `crawlPanelTitle`, still reading `MESSAGE LOG` (deviation 4 —
  the mock's `COMBAT LOG` is rejected because the log is not combat-only);
- a `crawlHairline` `crawlRule` rule beneath the title row, inset by
  `crawlGutter`;
- `_LogRow` padding `EdgeInsets.symmetric(vertical: crawlLogRowRhythm)`;
- the category mark in an inset well: `SizedBox(width: crawlMarkColumn)`
  holding a `crawlMarkWell` square, `crawlRecessed` fill,
  `Border.all(color: crawlRule, width: crawlHairline)`, 4 dp corners, mark
  centred. **The mark's `Text` takes the row's own style**, so a mark still
  shares its sentence's colour and hue never carries the category. The
  `Semantics(label: '${line.category.word}. ${line.sentence}')` +
  `ExcludeSemantics` wrapper is unchanged;
- `logCloseKey` becomes `CrawlPill(key: logCloseKey, label: 'Close the message
  log', icon: Icons.close, onPressed: () => bloc.add(const
  LogDrawerClosed()))`;
- `logUnreadKey` becomes `CrawlPill(key: logUnreadKey, label: '↓
  ${widget.state.logUnread} new', onPressed: …)` with the same body — dispatch
  `LogFollowResumed` then `_jumpToNewest()` — still shown iff
  `!logFollowing && logUnread > 0`, still `Positioned(right: 12, bottom: 12)`.

All four private colours (`_logBacking`, `_logNewest`, `_logOlder`,
`_logHandle`) and both private row styles are deleted; `_rowStyle(bool newest)`
survives as the one local selector returning `crawlLine` or `crawlLineOlder`.
`log_line.dart` is not edited: the marks and words stay exactly as they are
(deviation 3 — no new asset family).

## Red proof

Write the test changes first.

### `test/battle_view_test.dart`

Rewrite `:338-357`. The exact-label inventory
`['@ YOU','›','g¹','›','g¹','›','g²','›','@ YOU']` is presentation pinning that
AC6 necessarily breaks. Replace it with the behaviour it defends: read the
queue's cells left to right by their existing keys and assert that each carries
the right glyph **and** the right word —
`timeline-current-hero` → `'@'` + `'You'`, `timeline-actor-ghoul-1-1` → `'g¹'`
+ `'the ghoul¹'`, `timeline-actor-ghoul-1-2` → the same pair again (literal
repetition), `timeline-actor-ghoul-2-3` → `'g²'` + `'the ghoul²'`,
`timeline-next-hero` → `'@'` + `'You'`. Keep the four semantic-label
assertions, the two `button: true` assertions and
`expect(find.textContaining('IN '), findsNothing)` exactly as they are.

Add to the same group:

- `NOW` and `NEXT` each render exactly once while the queue has a remainder;
- in the truncation scene at `:465-498`, `NOW` and `timeline-current-hero`
  render, `find.text('NEXT')` finds nothing, and the existing `'…'`, `'...'`,
  `'IN '` and `'NOW —'` absence assertions still hold;
- in the overflow scene at `:500-560`, dragging the remainder leaves
  `timeline-current-hero`'s rect unchanged.

Rewrite `find.byType(BattleShelf)`? **No** — `:305` and `:556` are Task 03's.
Leave them.

### `test/widget/log_drawer_test.dart`

Rewrite `:223-258`. The four literal-hex assertions become relative:

```dart
expect(
  newestSentence.style!.color!.computeLuminance(),
  greaterThan(olderSentence.style!.color!.computeLuminance()),
);
expect(newestMark.style!.color, newestSentence.style!.color);
expect(olderMark.style!.color, olderSentence.style!.color);
```

Do not re-pin to a new hex and do not compare against `crawlInk`/`crawlDim`
here: the behaviour is "newest reads brighter, a mark shares its sentence's
colour", and relative comparison is what states it.

Add:

- the peek renders an expand affordance and still shows no category mark
  (`find.descendant(of: find.byKey(logPeekKey), matching:
  find.text(LogCategory.struck.mark))` finds nothing);
- in the expanded drawer, a row's mark sits left of its sentence and inside the
  gutter: the mark's rect right edge is at or left of the sentence's left edge,
  and the mark's rect width is at most `crawlMarkColumn`.

Run:

```text
flutter test test/battle_view_test.dart test/widget/log_drawer_test.dart
```

Expected Red: the caption, word-beneath, pinned-cell and mark-well assertions
fail against the flat dock and the flat gutter; the glyph/word pair assertions
fail because `'@ YOU'` is one string today. The relative-contrast rewrite and
the truncation, extent-cycle, follow, unread, empty-log, one-line-log and
death-collapse assertions pass before and after — they are the regression that
proves the fold of `_logNewest`/`_logOlder` changed no reading.

Also green at handoff:

```text
flutter test test/widget/crawl_layout_test.dart test/widget/crawl_status_test.dart test/game/log_drawer_state_test.dart test/game/activation_timeline_test.dart test/battle_characterization_test.dart test/battle_flow_characterization_test.dart
```

## Green proof and package gates

Implement only this slice, rerun the focused commands until green, then from
`packages/app`:

```text
dart format --set-exit-if-changed --output=none lib test
flutter analyze
flutter test
```

Record the Red failures and every Green exit status. Run no device gate.

## Executor discretion

- private widget and helper names; whether a cell is one private widget or two;
- the chevron gap in the caption row inside 8–20 dp, and the gap between the
  peek's list and its chevron;
- the mark well's corner radius inside 3–5 dp;
- how the pinned cell and the scroller share the token-building helper;
- fixture staging in the new assertions.

Not discretionary: the appended seam members and values, the panel structure,
the `hasRemainder` rule, `Key('dock-backing')`'s new home, the absence of any
`ListView` outside `LogPeek`, the absence of a current/selected visual state,
`FittedBox` over ellipsis, the 104 dp peek slot, or any string, key, event,
semantic label or extent behaviour.

## Escalate when

- repository reality contradicts the starting condition;
- `Key('dock-backing')` on the panel cannot keep `battle_view_test`'s scroll
  and descendant assertions meaningful;
- `NOW`/`NEXT` cannot be region labels without becoming per-entry prose, or the
  truncated queue cannot render without a placeholder;
- the widened cell makes the timeline unusable at phone width in a way the
  scroller cannot absorb;
- the peek cannot keep a 104 dp slot with a surface and a chevron;
- an existing log or timeline behaviour can be kept green only by changing a
  key, an event, a string or a semantic label;
- meeting the slice would require editing `game_bloc.dart`,
  `activation_timeline.dart`, `log_line.dart`, `game_screen.dart` or anything
  outside the owned list;
- following a locked decision here would knowingly ship a defect.

## Completion receipt

Return one compact receipt containing:

- `STATUS: COMPLETE` or `BLOCKED`;
- starting and resulting revision plus dirty-state summary;
- changed and added paths;
- the Red command and the behavioural failures observed;
- focused Green command plus format, analyze and full-suite results;
- the measured chrome height at phone size in an open battle, and the timeline
  panel's measured height;
- how many activations are visible in the panel before scrolling at phone
  width;
- confirmation that: `dockBacking`, `_logBacking`, `_logNewest`, `_logOlder`
  and `_logHandle` are gone, no new `ListView` exists, `NEXT` is absent on a
  truncated queue, no current/selected visual state was added, the peek slot is
  still 104 dp, and every timeline and log key, event, string and semantic
  label is unchanged;
- residual findings and the exact next action: Task 03 may start only when this
  repository state and receipt are accepted.
