# Task 04 — correct the chip fit rule and prove AC14 honestly

Execution-grade brief. One fresh `flow-plan-executor` session, no conversation
history required. Read `../PLAN.md` § **Correction C1** first: it holds the
measured evidence, the decision, the rejected alternatives and the revised
budget this brief implements. Read § **D. The action grammar — Task 03** for
the region it corrects.

This is a **bounded correction** to work that is already implemented and green.
It reopens region D's fit maths and nothing else.

## Starting condition

Branch `residuum-visual-reboot-12`, base commit
`60909e60ec3150cf9b590e6641a8ae51efca775c`. Tasks 01–03 are implemented and
**uncommitted**; the whole unit is in the working tree. Expect exactly this
shape from `git status --porcelain` (order aside):

```text
 M .flow/ldd/visual-reboot/LEDGER.md
 M .flow/ldd/visual-reboot/RESUME.md
 M packages/app/lib/game/battle_view.dart
 M packages/app/lib/game/crawl_status.dart
 M packages/app/lib/game/game_screen.dart
 M packages/app/lib/game/log_drawer.dart
 M packages/app/test/battle_view_test.dart
 M packages/app/test/widget/battle_shelf_icons_test.dart
 M packages/app/test/widget/craft_surfaces_test.dart
 M packages/app/test/widget/crawl_controls_test.dart
 M packages/app/test/widget/log_drawer_test.dart
?? .flow/ldd/visual-reboot/units/unit-12/
?? packages/app/lib/game/crawl_action_row.dart
?? packages/app/lib/game/crawl_style.dart
?? packages/app/lib/game/crawl_surfaces.dart
?? packages/app/test/widget/crawl_action_row_test.dart
?? packages/app/test/widget/crawl_layout_test.dart
?? packages/app/test/widget/crawl_surfaces_test.dart
```

Every change in that list is Unit 12's own work and is user-owned: do not
stash, reset, check out, clean or revert anything. Do not commit. Never
implement on `main`. If the working tree differs materially from the list above
— a file missing, a foreign modified file, a committed Unit 12 — stop and
escalate before editing.

There is no root pubspec. Every command in this brief runs from
`packages/app`.

## Owned files

| file | change |
|---|---|
| `packages/app/lib/game/crawl_action_row.dart` | rewrite `_RowFit`, `_fitFor`, `_labelLines` and the label/caption slots of `_ActionChip` |
| `packages/app/lib/game/crawl_style.dart` | `crawlChipMaxLabelLines` 2 → 3; delete `crawlChipLabelLineHeight` |
| `packages/app/test/widget/crawl_action_row_test.dart` | new AC14 fixture, corrected AC14 assertions, three new proofs, replace the vacuous no-clip helper |
| `packages/app/test/widget/crawl_controls_test.dart` | extend `_expectNoSqueeze` coverage to `_stairsDownScene` |

**Non-goals — do not touch:** `game_screen.dart` (the public interface of
`crawl_action_row.dart` does not change, so its call site does not either),
`crawl_surfaces.dart`, `battle_view.dart`, `log_drawer.dart`,
`crawl_status.dart`, `action_icon.dart`, `spell_row.dart`, anything under
`packages/core` or `packages/content`, any other test file, `CONTRACT.md`,
`recon.md`, briefs 01–03. No new file. No new asset. No player-facing string
changes: `✳ Firebolt 2`, `Drink (n)`, `Pack (n)`, `Ascend <`, `Descend >`,
`Finish`, `Leave`, `Wait`, `— armed` and every other label stay exactly as they
are.

## The defect, in one paragraph

`_fitFor` returns the **first** column count whose worst label fits within
`crawlChipMaxLabelLines`. Wrap count is not monotonic in width — at content
76.4 dp `✳ Firebolt 2` lays out in 2 lines, at 109.1 dp in 3 — so first-fit is
unsound: a legal four-spell combat scene including `Frost Lance` collapses the
row to two columns, six runs and **808 dp of chrome**, while a four-spell set
without it takes four columns, three runs and 559 dp. The 2-line result at
76.4 dp is only reachable by splitting the word `Firebolt` (96.0 dp wide),
which `_labelLines`' `painter.width <= content` guard cannot detect because
Skia break-all keeps the rendered width inside the box. Five further faults in
the same code — unapplied `crawlChipPadding`, a guessed 15 dp line box, an
unmeasured `— armed` caption, the wrong label style, no `TextScaler` — are
enumerated with measurements in `../PLAN.md` § Correction C1 § "The defect".

## Locked decisions

### L1 — the rule

`CrawlActionRow` measures, then minimises. In order:

1. Build **one** `TextPainter` per action, in **the heaviest style that action
   can ever render** — `crawlChipLabelArmed` when `action.armable`,
   `crawlChipLabel` otherwise — and the ambient `TextScaler` from
   `MediaQuery.textScalerOf(context)`. No `maxLines` on the measuring painter.
   Measuring `crawlChipSkin(_stateOf(action)).label` — the style the chip
   renders *right now* — is wrong: on any face where weight changes advance,
   arming a chip would change the row's measured height and reflow the
   `Expanded` map under the player's thumb, which is precisely what the
   reserved caption line exists to prevent. `crawlChipLabel` (w500) covers the
   disabled state too, since `crawlChipLabelDisabled` is w400.
2. Build one more painter for the armed caption in `crawlCaption`, iff any
   action in the row is armable.
3. Lay every painter out **once at unbounded width** and record, per label, its
   `minIntrinsicWidth` (the widest unbreakable word) and, for the caption, its
   single-line `width`. `minIntrinsicWidth` is only trustworthy from an
   unbounded layout — after a bounded break-all layout it reports the widest
   rendered fragment (`Leave` reports 12.0 dp at content 56.7 dp). Take
   `widestWord` as the maximum over all labels and the caption's single-line
   width.
4. For `columns` from `crawlChipMaxColumns` down to 1:
   - `width = (available - crawlChipSpacing * (columns - 1)) / columns`;
   - `content = width - crawlChipPadding * 2`; skip when `content <= 0`;
   - **word guard:** skip when `content + 0.5 < widestWord`. A candidate that
     would break a word or wrap the caption is not a candidate.
   - re-lay every label painter out at `maxWidth: content`; skip the candidate
     if any label's `computeLineMetrics().length > crawlChipMaxLabelLines`;
   - `labelBlock` = the greatest measured `painter.height` over the labels;
     `captionHeight` = the caption painter's measured height, or 0;
   - `chipHeight = crawlChipVerticalPadding * 2 + actionIconSize +
     crawlRhythm + labelBlock + captionHeight`;
   - `runs = (actions.length / columns).ceil()`;
   - `total = runs * chipHeight + (runs - 1) * crawlChipRunSpacing`;
   - keep this candidate only if `total` is **strictly** less than the best so
     far. Iterating columns descending plus strict improvement means a tie
     keeps the larger column count; that is the intended tie-break.
5. Degenerate case — no candidate passed the word guard: one column at the full
   `available` width, `chipHeight` from a layout at that content width. A label
   that cannot fit even there is an escalation (see E4), not a layout bug.
   Reachable in principle only under a very large text scale.
6. Dispose every painter in a `finally`. One painter per label per row build,
   reused across candidates; no painter is ever allocated per chip.

### L2 — measurement and render must agree

- The label and the armed caption are wrapped in
  `Padding(padding: EdgeInsets.symmetric(horizontal: crawlChipPadding))`, so
  the width the rule measured is the width the chip renders. This is what
  `crawlChipPadding` was always for.
- `_ActionChip` keeps its fixed `SizedBox(width:, height:)`; `height` is
  `chipHeight` from L1 and is identical for every chip in the row (AC4).
- The armed-line reserve becomes the **measured** caption height: the armed
  chip renders `Text(_armedCaption, style: crawlCaption)` and every other chip
  in an armable row renders `SizedBox(height: captionHeight)`.
- Introduce `const String _armedCaption = '— armed';` in
  `crawl_action_row.dart` and use it in both the measurement and the render, so
  the two cannot drift. The rendered string is unchanged.
- `_ActionChip._state` keeps today's precedence unchanged — armed, then null
  `onPressed` → disabled, else available — and stays the only place a chip's
  rendered state is decided. `_fitFor` does not need it: it measures by
  `action.armable`, which does not change when a chip is armed.
- The label `Text` keeps `textAlign: TextAlign.center` and
  `maxLines: crawlChipMaxLabelLines`, and gains no `overflow`/`TextOverflow`
  setting: nothing may ellipsise.

### L3 — the interface

```dart
/// One row layout: what every chip in the row measures, and the reserve the
/// armed word needs, both measured rather than assumed.
class _RowFit {
  const _RowFit({
    required this.width,
    required this.chipHeight,
    required this.captionHeight,
  });

  final double width;
  final double chipHeight;
  /// 0 when no action in the row is armable.
  final double captionHeight;
}

_RowFit _fitFor(
  double available,
  List<CrawlAction> actions,
  TextScaler textScaler,
);
```

`_labelLines` disappears; its job splits between the unbounded pass and the
per-candidate pass of L1. `_ActionChip` takes `captionHeight` instead of
`reserveArmedLine` and reserves the armed line iff `captionHeight > 0`.

**Unchanged and public:** `CrawlAction`, `CrawlActionRow`'s constructor and
fields, `actionRowKey`, `readiedSpellCount`, the duplicate-label `assert`, the
`Wrap(spacing:, runSpacing:, alignment: WrapAlignment.center)`, the notes
block, the `Semantics`/`ExcludeSemantics` wrapper, `Material` + `InkWell` +
`crawlChipSkin`, the icon slot including `Opacity(crawlDisabledIconOpacity)`
for a dead chip and the `SizedBox(height: actionIconSize)` for a word-only
verb, and `Text(action.label, …)` as the only label widget.

### L4 — the seam

- `crawlChipMaxLabelLines`: **2 → 3**, with its doc rewritten to say it is a
  clipping ceiling the search must respect, not a design preference. Measured,
  three lines at three columns cost 336 dp of chips at worst density where two
  lines at two columns cost 434 dp.
- `crawlChipLabelLineHeight`: **deleted**. The line box it guessed (15 dp) is
  neither the suite's (12.0 dp) nor a real monospace's (~15.8 dp at 12 px) and
  is now measured. Nothing else references it — confirm with
  `grep -rn "crawlChipLabelLineHeight" lib test` before finishing; the answer
  must be empty.
- Every other chip metric keeps its value: `crawlChipSpacing` 6,
  `crawlChipRunSpacing` 4, `crawlChipPadding` 8, `crawlChipVerticalPadding` 6,
  `crawlChipMaxColumns` 5, `crawlDisabledIconOpacity` 0.45.

## Executor discretion

- The internal shape of the candidate loop: a local record, a small private
  class, or a fold. Only L1's semantics are binding.
- Whether the unbounded pass and the candidate pass share one painter list or
  two, provided each label is measured only in the style L1.1 assigns it and
  every painter is disposed.
- Private names, doc wording, and where the helpers sit in the file.
- The exact text-scale factor in the T4 proof (1.25–1.4), provided the Red it
  produces on the current tree is a clip or overflow caused by unscaled
  measurement, and the Green is clean.
- The item base used for the `Here:` note in the worst fixture, provided it is
  the longest `displayName` you find in `packages/content` and the receipt says
  which it was.
- Whether the run-capacity proof (T2.4) counts runs by grouping chip top-`dy`
  values or by rect intersection.

## The AC14 fixture rule — and why the delivered one is not evidence

The delivered `_combatWorstScene` uses `knownSpells: {'firebolt','mend','ward','bind'}`.
That set measures 559 dp against the old 560 dp cap. It is green, and it is
**not AC14 evidence**: a legal four-spell set including `Frost Lance` measures
808 dp on the same tree. A fixture that was kept because it passes proves
nothing about the worst case. Delete it and build the worst scene by rule.

**Rule — maximise every independently maximisable term of the row's own
arithmetic, at a density the game's rules can produce:**

1. `knownSpells` = every id in `spellbook` (all six). This is the legal maximum
   and it is forced, not chosen: `knownSpellsInOrder`
   (`lib/game/spell_row.dart:80`) sorts by school index then name, so the
   readied three are `Firebolt`, `Frost Lance`, `Mend` and the overflow chip is
   `+3`. That set contains the game's longest chip label (`✳ Frost Lance 4`, 15
   characters) and its longest single word (`Firebolt`, 8). No shorter set may
   be substituted.
2. Every guard that can hold at the same time as an open battle holds: one
   monster holding reach (`isBattleOpen`); an item underfoot with
   `inventory.length < inventoryCap` so `canPickUp` is true; a gather node
   underfoot with the longer verb — `GatherKind.herbPatch` → `Gather`; the
   hero on `stairsUp` on the deepest floor so `canAscend`, `canLeave` and
   `isAtTheBottom` all hold and the label is `doneControl`; a pack of 19 items
   of which 12 are potions, so the labels are `Pack (19)` and `Drink (12)` —
   the widest legal counts that still leave `canPickUp` true.
3. All three note sentences render: `doneAtTheBottom`, the `Underfoot:`
   sentence, and the **plural** `Here: <name> and N more` form, with the
   longest item `displayName` available in `packages/content`.
4. `canDescend` is deliberately absent: on the deepest floor there is no
   `stairsDown`, and one tile cannot legally be both stairs. If a twelfth chip
   were reachable the row would still be four runs at three columns, so the cap
   is unaffected.
5. Where legality is genuinely uncertain — a gather node on a stairs tile, for
   instance — **include** the term. Over-inclusion only tightens the bound. The
   receipt records every term included.

Name it `_combatWorstLegalScene` and document the rule above it in three lines,
so the next reader cannot quietly weaken it. Keep
`_explorationTypicalScene` for the even-width test and add
`_explorationWorstScene` — the same stairs landing plus a gather node and the
plural `Here:` note, six chips, three notes — for the exploration cap.

## Red → Green proof

Write every Red first, run it, record the observed failure, then change
production code. Run only the focused commands in this brief.

### T1 — chrome under the revised caps (`crawl_action_row_test.dart`)

Replace the existing `the chrome stays within its exploration and combat caps`
test. Keep `_chromeHeight`. Three assertions, each with a `reason:` that prints
the measured value:

| scene | cap |
|---|---:|
| `_explorationWorstScene` | 360 |
| a typical combat scene (four known spells including `frost-lance`, potion carried, no stairs, no node, no loot — 7 chips, no notes) | 560 |
| `_combatWorstLegalScene` | 720 |

**Expected Red:** the worst-legal scene measures ~808 dp against 720.
**Expected Green:** ~650–670, ~505, ~314–330 respectively. The margins are
deliberately smaller than one chip run (~85 dp in combat, ~50 dp in
exploration) so that a regression which adds a run breaks its cap, and every
one of them is larger than the 1 dp of slack the delivered 559-against-560
assertion had — a cap a fixture clears by one dp is a coincidence, not a
budget. Record all three measured values in the receipt; a cap without its
measurement is not evidence.

### T2 — the row is laid out legally (`crawl_action_row_test.dart`)

Replace `_expectNoClippedLabels` — as written it asserts only
`didExceedMaxLines`, which is `false` for every label at every candidate width
in this font and therefore can never fail. The replacement takes a `reason` and
asserts, for every chip-label `RenderParagraph` under `actionRowKey`:

1. `didExceedMaxLines` is false;
2. `paragraph.size.width + 0.5 >= paragraph.getMinIntrinsicWidth(double.infinity)`
   — the rendered box is at least as wide as the label's widest unbreakable
   word, which is what "no word is broken and nothing ellipsises" means once
   labels may wrap. This is the same assertion `crawl_controls_test.dart`'s
   `_expectNoSqueeze` already makes; it belongs here too;
3. `tester.takeException()` is null, so no `RenderFlex` overflow hides inside a
   chip.

Call it in T1's three scenes and in T3 and T4. Also assert, once, in
`_combatWorstLegalScene`:

4. **run capacity:** group the chip rects by top `dy`; every run except the
   last holds the same number of chips as the first, and the last holds no
   more. A row that leaves a run short of what its chosen width allows is
   paying for a run it did not need.

**Expected Red for T2.2:** a four-spell combat scene *without* `Frost Lance`
(`{'firebolt','mend','ward','bind'}`) is laid out at four columns today, where
the chip is 92.36 dp wide and `✳ Firebolt 2` has a 96.0 dp widest word — the
rendered paragraph is narrower than its own widest word because `Firebolt` is
split across the two lines. Keep that scene in the test file for exactly this
proof and name it `_combatSplitWordScene`. **Green:** the corrected rule takes
three columns, content 109.1 dp ≥ 96.0 dp, and the word survives.

### T3 — a longer verb costs at most one run (`crawl_action_row_test.dart`)

Measure `_chromeHeight` for `_combatSplitWordScene` and for
`_combatWorstLegalScene` and assert the difference is at most 96 dp — one chip
run at the line ceiling. The row's height must be stable under label content;
that is the invariant the player experiences and the one first-fit broke.

**Expected Red:** 808 − 559 = 249 dp. **Green:** both scenes land at three
columns and four runs, so the difference is ~0–20 dp.

### T4 — the reservation honours the ambient text scale (`crawl_action_row_test.dart`)

Pump the typical combat scene at `onAPhone` inside a
`MediaQuery(data: MediaQueryData(textScaler: TextScaler.linear(1.3)))` above
`GameScreen` — wrap it where `_openCrawl` builds the `MaterialApp`, or add an
optional `textScaler` parameter to `_openCrawl`. Assert `tester.takeException()`
is null and run the T2 helper.

**Expected Red:** the delivered chip reserves `2 * 15 + 15 = 45` dp for a label
and caption that measure `2 * 15.6 + 14.3 = 45.5` dp at 1.3, so the chip's
`Column` overflows by 0.5 dp and the test surfaces a `RenderFlex` overflow. If
your scale factor yields no overflow, raise it within 1.25–1.4 until the Red is
a clip or overflow, and record the factor. **Green:** the corrected rule
measures with the scaler, chooses two columns, and nothing overflows or clips.

### T5 — regression coverage the plan left open (`crawl_controls_test.dart`)

`_stairsDownScene` is the only scene that puts `Descend >` — the longest
word-bearing exploration label — on the row, and `_expectNoSqueeze` is never
called on it. Add that call to the test that already pumps it
(`_expectIcon('Descend >')`, around `:307-316`). This is **not** a Red: at
today's unpadded 92.36 dp chip the 84.0 dp word fits, and after the correction
three columns give it 109.1 dp. It guards the new rule's word guard against the
padding L2 makes real.

### Regression that must stay green, untouched

`battle_shelf_icons_test.dart` (labels and armed border/word are unchanged),
`craft_surfaces_test.dart`, `crawl_controls_test.dart`'s frozen control set and
order for all three exploration scenes, `crawl_layout_test.dart`,
`crawl_surfaces_test.dart`, `battle_view_test.dart`, `crawl_status_test.dart`,
`log_drawer_test.dart`. If any of them fails, the correction changed something
it does not own — escalate rather than adjusting the test.

## Verification

From `packages/app`, focused first:

```text
flutter test test/widget/crawl_action_row_test.dart
flutter test test/widget/crawl_controls_test.dart
flutter test test/widget/craft_surfaces_test.dart test/widget/battle_shelf_icons_test.dart
grep -rn "crawlChipLabelLineHeight" lib test
```

Then the package gates, once, at the end:

```text
dart format --set-exit-if-changed --output=none lib test
flutter analyze
flutter test
```

`flutter analyze` must be clean of new findings — in particular no unused
import (`dart:math` may become unnecessary; if `math.max` is gone, drop the
import) and no unused private declaration.

## Escalate when

1. **E1** — the working tree does not match the starting condition above.
2. **E2** — a measured chrome height exceeds its cap after the correction, or
   the worst-legal scene cannot reach four runs or fewer at three columns. That
   is the budget being wrong again, and it is the architect's to re-decide.
   Report the measured value, the chosen column count, `labelBlock`,
   `captionHeight`, `chipHeight` and the run count; change no cap yourself.
3. **E3** — a Red does not appear as described, or appears for a different
   reason. The correction rests on those failures; a missing Red means the
   defect is not where this brief says it is.
4. **E4** — the degenerate branch of L1.5 is reachable in any tested scene, or
   any label's widest word exceeds the full row content width.
5. **E5** — a regression listed above fails, or honouring this brief would
   require hiding a verb, shortening a label, ellipsising, scrolling the row,
   shrinking `crawlLogPeekHeight`, dropping the armed reserve or changing a
   player-facing string. Those are contract-level choices; `../PLAN.md`
   § Correction C1 § "AC14 verdict, plainly" lists them and none is authorised
   here.
6. **E6** — the correction cannot keep `game_screen.dart` unedited.

Escalate by stopping and reporting. Do not redesign the rule.

## Completion receipt

Report, compactly:

1. the four owned files and what changed in each;
2. the three measured suite chrome heights, each against its cap, plus the
   chosen column count, `labelBlock`, `captionHeight`, `chipHeight` and run
   count per scene;
3. the T3 difference in dp;
4. the T4 text-scale factor and the Red it produced;
5. the observed Red for T1, T2.2, T3 and T4, verbatim enough to recognise;
6. every term included in `_combatWorstLegalScene`, including the item
   `displayName` chosen for the plural `Here:` note;
7. the result of `grep -rn "crawlChipLabelLineHeight" lib test`;
8. the three package gates' results;
9. confirmation that `game_screen.dart`, every other `lib/` file and every test
   file outside the two owned ones are byte-unchanged by this task, and that
   nothing was committed;
10. whether the `../PLAN.md` § Correction C1 budget tables match what you
    measured, and every figure that differs.
