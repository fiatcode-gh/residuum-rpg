# Task 02 — The Crawl Seam onto the Tokens, and the dp Re-measurement

Owner: one fresh `flow-plan-executor` on the Unit 14 feature checkout.

Read `../CONTRACT.md`, `../PLAN.md` (findings F5 and F6, "Cross-task
interfaces", and the whole "The dp gate" section), then
`packages/app/lib/style/tokens.dart`,
`packages/app/lib/game/crawl_style.dart`,
`packages/app/lib/game/crawl_surfaces.dart`,
`packages/app/lib/game/game_screen.dart`,
`packages/app/lib/game/crawl_action_row.dart` and
`packages/app/test/widget/crawl_action_row_test.dart` before editing.

All commands run from `packages/app`.

## Starting condition

- Task 01's repository state is accepted: `lib/style/tokens.dart` exists and
  exports the two families, the ten ladder colours, the five rhythm values, the
  seventeen roles and `residuumTheme`; `assets/fonts/` holds three font files
  and two `OFL.txt`; `pubspec.yaml` declares both families;
  `test/flutter_test_config.dart` registers them; `main.dart` is migrated;
  `test/style/type_authority_test.dart` is green;
- `crawl_style.dart:3-12` still declares ten `Color` literals, `:39-138` still
  declares sixteen `TextStyle`s each with `fontFamily: 'monospace'`, and
  `:146-183` still declares `crawlTheme`;
- Task 01's receipt lists any full-suite metric shift it handed forward. **Read
  that list**: any entry naming a crawl test is this task's to resolve.

Inspect branch, HEAD and worktree before editing. If a named seam differs
materially, stop and report.

## Behavioral slice

The crawl renders from the shared tokens with no colour literal and no
`TextStyle` of its own, opts into `residuumTheme` at the three sites that used
`crawlTheme`, and **the crawl's chrome is re-measured at the three named
densities against a budget that now means something**, because the same face
resolves in the test host and on device.

Every fact, control, key, string, dispatch, guard and geometry on the crawl is
unchanged. This task does not touch the meter (Task 03), the town, the world, or
`dungeon_scene.dart`.

## Owned files

- `packages/app/lib/game/crawl_style.dart`;
- `packages/app/lib/game/game_screen.dart`;
- `packages/app/lib/game/crawl_surfaces.dart`;
- `packages/app/lib/game/battle_view.dart` — the dartdoc at `:229` only;
- `packages/app/test/widget/crawl_action_row_test.dart`.

**Do not edit** `crawl_action_row.dart`, `crawl_status.dart`, `log_drawer.dart`,
`spell_row.dart`, `action_icon.dart`, `item_presentation.dart`,
`log_line.dart`, `actor_presentation.dart`, `activation_timeline.dart`,
`game_bloc.dart`, `pack_screen.dart`, any renderer file, `main.dart`,
`tokens.dart`, anything under `lib/town/` or `lib/world/`, `packages/core` or
`packages/content`. Verified at `5ac1a49`: none of those files holds an inline
`TextStyle` or colour literal, so the aliases below carry every one of them
untouched.

## Locked decisions

### `crawl_style.dart` becomes aliases plus the crawl's own three

`import 'package:residuum_app/style/tokens.dart';` — or the relative path the
file's neighbours use. Then:

**Colours.** The seven that duplicate the shared ladder become aliases; the
three crawl-only values are **gone**, because all three are now shared tokens:

```dart
const Color crawlInk = ink;
const Color crawlDim = dim;
const Color crawlPanel = panel;
const Color crawlRule = rule;
const Color crawlVoid = ground;
const Color crawlRaised = raised;
const Color crawlRecessed = recessed;
const Color crawlArmedFill = armedFill;
const Color crawlDisabledRule = disabledRule;
const Color crawlScrim = scrim;
```

No `Color(0x` literal survives in this file. The names survive because
`crawl_surfaces_test.dart:237,252,267` compares rendered colours against
`crawlPanel`, `crawl_action_row_test.dart:442-471` reads `crawlChipSkin`'s
fields, and six `lib/game/` files import these names. **Aliasing is the end
state, not scaffolding** — it is the crawl seam consuming the shared ladder,
which is what the contract asks for.

**Metrics.** `crawlGutter`, `crawlRhythm`, `crawlRadius`, `crawlHairline`,
`crawlTapTarget` become aliases of `gutter`, `rhythm`, `radius`, `hairline`,
`tapTarget`. Every other metric — `crawlPanelPadding`, `crawlTokenCell`,
`crawlTokenWidth`, `crawlLogPeekHeight`, `crawlMarkColumn`, `crawlMarkWell`,
`crawlLogRowRhythm`, `crawlChipSpacing`, `crawlChipRunSpacing`,
`crawlChipPadding`, `crawlChipVerticalPadding`, `crawlChipMaxColumns`,
`crawlChipMaxLabelLines`, `crawlDisabledIconOpacity` — is **crawl-specific and
unchanged**, including its dartdoc at `:32-36`. Those are U15's chip metrics and
this task does not move one of them.

**Type.** All sixteen `TextStyle` declarations at `:39-138` become aliases:

| was | becomes |
|---|---|
| `crawlPlace` (15/ls3/w500) | `displayRoom` |
| `crawlBody` (14) | `textBody` |
| `crawlBodyDim` (12/dim) | `textLineDim` |
| `crawlRegionLabel` (11/ls2/w600/dim) | `displayCaption` |
| `crawlPanelTitle` (13/ls2/w600) | `displayPanel` |
| `crawlLine` (13) | `textLine` |
| `crawlLineOlder` (13/dim) | `textLineDim` |
| `crawlGlyph` (18) | `textGlyph` |
| `crawlTokenWord` (11/dim) | `textDetail` |
| `crawlChevron` (18/dim) | `textGlyph.copyWith(color: dim)` |
| `crawlChipLabel` (12/w500) | `textLabel` |
| `crawlChipLabelDisabled` (12/w400/dim) | `textLabelDim` |
| `crawlChipLabelArmed` (12/w600) | `textLabelStrong` |
| `crawlCaption` (11/w600) | `textCaption` |
| `crawlDetail` (11/dim) | `textDetail` |
| `crawlHeadline` (28) | `textHeadline` |

`crawlChevron` is the only one needing `copyWith`, and it varies **colour
only** — the plan's standing rule. It must be a `final`, not a `const`, because
`copyWith` is not const-evaluable; that is fine and allocates once.

`crawlLineOlder` and `crawlBodyDim` both alias `textLineDim`, and `crawlDetail`
and `crawlTokenWord` both alias `textDetail`. That is correct: the old scale had
two rungs where the new one has one, and the names stay so no consumer moves.

**Keep** the `inherit: false` dartdoc at `:96-100` — reword it to say the
invariant now lives in `tokens.dart` and applies to every role, so the object
`_fitFor` measures is still the object `Text` paints. That reason is
load-bearing for the fit rule and must not be deleted with the styles.

**`crawlTheme` is deleted**, along with its dartdoc at `:140-145`. There is one
`ThemeData` in the application now and it lives in `tokens.dart`; a
`crawl_style.dart` alias of it would be a name with no content. `CrawlChipState`,
`CrawlChipSkin` and `crawlChipSkin` at `:186-231` are **unchanged** — they are
U15's chip vocabulary and they already read from the aliased names.

### The three theme sites

- `game_screen.dart:57` — `data: crawlTheme` becomes `data: residuumTheme`.
  The `Theme` wrap's position (inside `BlocListener`, outside `Scaffold`) and
  everything else in the file is unchanged.
- `crawl_surfaces.dart:116` and `:146` — the same substitution inside
  `showCrawlSheet` and `showCrawlConfirm`. The second wrap is **not** redundant:
  both are pushed on the root navigator and are therefore siblings of
  `GameScreen`, not descendants of its `Theme`. Keep both.
- `crawl_surfaces.dart:105`'s dartdoc says "both already set on `crawlTheme`" —
  reword to name `residuumTheme`, keeping the reason.
- `crawl_surfaces.dart:144` passes `barrierColor: crawlScrim` explicitly.
  `residuumTheme.dialogTheme` now carries `barrierColor: scrim`, so the explicit
  argument is redundant — **remove it**, since a clean cutover leaves no
  duplicate source for one value. The rendered barrier is unchanged.

### `battle_view.dart:229`

The dartdoc reads "One line of the enemy sheet, monospace and dim." Reword so
the word does not survive — "One line of the enemy sheet, in the text face and
dim" — and change nothing else in the file. The three `Text('›', style:
crawlChevron)` sites at `:55`, `:70`, `:84` are carried by the alias.

### The three chrome caps

`crawl_action_row_test.dart:501-540` asserts widget-test chrome
`≤ 360 / ≤ 560 / ≤ 720` dp for `_explorationWorstScene`,
`_combatTypicalScene` and `_combatWorstLegalScene`. Those ceilings were sized
against Ahem's 1.000 em metrics and now prove nothing.

**Re-derive all three from this task's own measurements**: each cap is the
measured value rounded up to the next 10 dp, plus 20 dp of headroom. Keep the
test's structure, its three scenes, its `_expectLegalRow` calls and its
`_expectRunCapacity` call exactly as they are; change only the three numbers and
the `reason:` strings so the measured figure is printed with each.

`_chromeHeight` (`:376-381`), `_expectLegalRow` (`:314-333`) and
`_expectRunCapacity` (`:339-374`) are **not** edited. They are the regression
proving the new metrics broke no word, clipped no paragraph and left the runs
even.

## Executor discretion

Yours without asking:

- the declaration order inside `crawl_style.dart`, and whether the alias block
  keeps the file's current grouping or is regrouped;
- whether `crawlChevron` is a `final` beside the `const`s or lives at the end
  of the type block;
- the exact wording of the reworded `inherit: false` and `crawl_surfaces.dart`
  dartdocs, so long as each keeps its reason;
- the `reason:` strings on the three re-derived caps, so long as each
  interpolates its measured chrome;
- which of the tuning constants in `../PLAN.md`'s envelope table to reach for
  first if a `takeException` fires, and by how much inside the envelope.

Not yours: which name aliases which role, the deletion of `crawlTheme`, any
chip metric constant, the fit algorithm, the three scenes, `_chromeHeight`,
`_expectLegalRow` or `_expectRunCapacity`.

## Red proof

There is no new behaviour here, so the Red is the **measurement**, and it is
recorded rather than asserted-into-existence:

1. before any production edit, run

   ```text
   flutter test test/widget/crawl_action_row_test.dart
   ```

   and record the three caps' current pass margins by temporarily reading the
   `reason:` output — the existing assertions already interpolate the measured
   chrome. **Record all three Ahem-era figures in the receipt.** These are the
   "before" half of the dp gate's agreement evidence;
2. make the production change;
3. rerun and record the three Spectral-era figures. **Both sets go in the
   receipt**, because Gate A and Gate C compare against them and the difference
   between them is the evidence that finding F4's divergence closed.

Expected direction, from `../PLAN.md`'s arithmetic: flat to roughly −10 dp at
every density, with the action row possibly reaching **five columns** where four
was previously the best legal count, because `Firebolt` in `textLabelStrong`
measures ≈ 47.6 dp against monospace's 57.6 dp. A **rise** of more than 10 dp at
any density means a role lost its explicit `height` — check that first.

### Must stay green

```text
flutter test test/widget/crawl_status_test.dart test/widget/crawl_layout_test.dart test/widget/crawl_controls_test.dart test/widget/battle_shelf_icons_test.dart test/widget/craft_surfaces_test.dart test/widget/crawl_surfaces_test.dart test/widget/log_drawer_test.dart test/widget/disabled_controls_test.dart test/widget/dungeon_scene_bleed_test.dart test/widget/back_guard_test.dart test/widget/suspend_door_test.dart test/widget/door_reentry_test.dart test/battle_view_test.dart test/battle_characterization_test.dart test/battle_flow_characterization_test.dart
```

Three of these are the regressions that prove the fold changed no reading:

- `log_drawer_test.dart:256-260` compares the newest sentence's luminance
  against an older one's and each mark's colour against its own sentence's —
  relative, so it passes before and after and proves the colour aliases are
  faithful;
- `crawl_status_test.dart:350-366` is the worst-case no-squeeze loop over every
  `RenderParagraph` — it proves no status string clips under the new metrics;
- `crawl_surfaces_test.dart:224-267` compares each overlay's rendered surface
  against `crawlPanel` — it proves the theme substitution kept every sheet and
  dialog on the right surface.

**A `takeException(), isNull` failure in any of these is a real overflow**, not
a test problem, and it is this task's to fix inside the tuning envelopes in
`../PLAN.md`'s dp gate. If `crawl_status_test.dart`'s no-squeeze loop fails on
`displayRoom`'s tracking, reduce `displayRoom`'s `letterSpacing` toward 2 in
`tokens.dart` — the existing `FittedBox`es should absorb it. Do not remove a
`FittedBox` and do not change a status string.

## Green proof and package gates

```text
flutter test test/widget/crawl_action_row_test.dart
dart format --set-exit-if-changed --output=none lib test
flutter analyze
flutter test
```

Then the scoped audit, recorded in the receipt:

```text
grep -n "Color(0x"    lib/game/crawl_style.dart
grep -n "TextStyle("  lib/game/crawl_style.dart
grep -n "crawlTheme"  lib test
grep -rn "monospace"  lib/game
```

Expected: the first three return nothing; the fourth returns only
`dungeon_scene.dart:432` and `:441`, which are Task 07's.

## Acceptance

- `crawl_style.dart` declares no colour literal, no `TextStyle` and no
  `ThemeData`; every one of its sixteen type names and ten colour names still
  exports, as an alias;
- the three `crawlTheme` sites read `residuumTheme`, and
  `crawl_surfaces.dart`'s redundant `barrierColor` argument is gone;
- `crawl_action_row.dart`, `crawl_status.dart`, `log_drawer.dart` and
  `battle_view.dart` (beyond one dartdoc) are **unedited**, and the diff proves
  it;
- the three chrome caps are re-derived from measurement, with the Ahem-era and
  Spectral-era figures for all three densities in the receipt;
- every test in the must-stay-green list passes;
- all three package gates green.

## Escalate, do not decide

- worst legal combat chrome above 600 dp — a stop-and-escalate, not a tuning
  target, and none of the remedies (shrinking `crawlLogPeekHeight`, scrolling
  the row, hiding a verb, shortening a label, ellipsising, changing
  `crawlChipMaxColumns` or `crawlChipMaxLabelLines`) is yours;
- any need to change `_fitFor`, `_RowFit`, `_ActionChip` or a chip metric
  constant — U15 owns the fit rule;
- any need to change a type role's size, weight, family or tracking beyond the
  envelopes in `../PLAN.md`'s dp gate;
- a `takeException` failure you cannot clear inside those envelopes;
- an existing test whose rewrite would change **what it defends** rather than
  which number it names.

## Receipt

Report: the Ahem-era and Spectral-era chrome for all three densities and the
three re-derived caps; the column count and run count the action row now
chooses at worst legal density; whether any role's `height` or tracking was
tuned and to what; the four audit greps; the must-stay-green list's result; and
the three package gates.
