# Task 08 — The Rename Leaf: One Name Per Value

Owner: one fresh executor on the Unit 14 feature checkout. **`sonic` recommended
after architect amendment A7** — see "Which agent — revised after A7" below;
an earlier version of this brief recommended `flow-plan-executor` and A7
removed the reason.

Architect amendment A4, 2026-09-18. Read `../PLAN.md` §"Task 08 — the rename
leaf" and §"The alias strategy — the migration mechanism, and why it is
transitional", then `packages/app/lib/style/tokens.dart`,
`packages/app/lib/game/crawl_style.dart` and
`packages/app/lib/town/town_style.dart` before editing.

All commands run from `packages/app`.

## Starting condition

- Tasks 01–07 are accepted. Every screen and both style seams render from the
  shared tokens; `residuumTheme` is applied at six roots; no stock Material
  control renders in the Material 3 default palette; `'monospace'` greps to
  nothing; the CI type authority gate is in place; **AC2 is closed**;
- `crawl_style.dart` holds 26 alias declarations plus 14 real crawl metrics,
  5 kept type declarations and the chip-state table;
- `town_style.dart` holds 8 alias declarations plus `markColumn` and its
  widgets, and imports `tokens.dart` **under a prefix** (Task 04 added it to
  resolve the `ink`/`dim`/`panel`/`rule` name collision);
- the full suite is green and `flutter analyze` is clean.

Inspect branch, HEAD and worktree before editing. If either seam file's
membership differs from the tables below, stop and report — the difference means
an earlier task deviated and this task's count-based acceptance would hide it.

## Behavioral slice

**Nothing changes at runtime.** Every shared value has exactly one name, every
consumer reads that name, and a seam declaration survives only where the seam
has something of its own to say. The seven units that follow inherit one name
per value instead of three.

The correctness argument is therefore not a new test: it is `flutter analyze`
clean plus **the full suite green with no test edited except by the rename and
its imports**.

## Owned files

Both seam files, plus every file the rename touches:

- `packages/app/lib/game/crawl_style.dart` — delete 26 aliases, keep the rest;
- `packages/app/lib/town/town_style.dart` — delete 8 aliases, keep
  `markColumn` and the widgets, drop the import prefix;
- every other file under `packages/app/lib/` and `packages/app/test/` that the
  language-server rename and the subsequent import repoint reach — roughly
  fifty, and `flutter analyze` names each one;
- `packages/app/test/widget/crawl_surfaces_test.dart` — the comment correction
  at `:297-300`, which is required, not optional.

**Do not** change any value, any widget tree, any string, any key, any test
expectation, any import that is still needed, `tokens.dart`, `surfaces.dart`,
`.github/workflows/ci.yml`, `AGENTS.md`, `packages/core` or `packages/content`.

## Locked decisions

### The decidable rule

> If deleting the name and using the shared token in its place loses no
> meaning, delete it. If the name says something the token does not, keep it —
> and give it a one-line dartdoc saying what.

### What goes — 35 declarations

| file | deleted | count |
|---|---|---:|
| `crawl_style.dart` colours | `crawlInk`, `crawlDim`, `crawlPanel`, `crawlRule`, `crawlVoid`, `crawlRaised`, `crawlRecessed`, `crawlArmedFill`, `crawlDisabledRule`, `crawlScrim` | 10 |
| `crawl_style.dart` metrics | `crawlGutter`, `crawlRhythm`, `crawlRadius`, `crawlHairline`, `crawlTapTarget` | 5 |
| `crawl_style.dart` type | `crawlPlace`, `crawlBody`, `crawlBodyDim`, `crawlRegionLabel`, `crawlPanelTitle`, `crawlLine`, `crawlLineOlder`, `crawlGlyph`, `crawlTokenWord`, `crawlDetail`, `crawlHeadline` | 11 |
| `crawl_style.dart` type (A7) | `crawlChevron` — now a `const` alias of `textGlyphDim`, so the rule deletes it | 1 |
| `town_style.dart` colours | `ink`, `dim`, `panel`, `rule` | 4 |
| `town_style.dart` type | `mono`, `monoDim`, `placeName`, `roomName` | 4 |
| | | **35** |

Each maps to its shared token by the tables in `../PLAN.md` — the colour ladder
table and the two type-role tables. **Read the mapping from the plan, not from
the alias's right-hand side**, then check the two agree: a disagreement means an
earlier task mis-aliased, which is an escalation and exactly the kind of defect
this task could otherwise cement.

Note that `crawlBodyDim` and `crawlLineOlder` both alias `textLineDim`, and
`crawlTokenWord` and `crawlDetail` both alias `textDetail`. Those are two
names collapsing onto one rung, which is correct and expected.

**`crawlChevron` was on the keep list in an earlier version of this brief, as
its headline example of a name that looks like an alias and is not. Architect
amendment A7 removed that.** A7 made `crawlChevron` a `const` alias of the new
eighteenth role `textGlyphDim`, because `textGlyph.copyWith(color: dim)` is not
const-evaluable and all four of its consumers sit in `const` contexts — the
package did not compile. It is now a pure re-naming like any other, the rule
deletes it, and **there is no longer any name on the keep list that the rule
would wrongly delete.** That has a consequence for who should run this task;
see the closing section.

### What stays, and the dartdoc each gains

| kept | one-line dartdoc must say |
|---|---|
| `crawlChipLabel`, `crawlChipLabelDisabled`, `crawlChipLabelArmed`, `crawlCaption` | `_fitFor` measures these exact objects and names the heaviest explicitly (`crawl_action_row.dart:154-163`); the seam owning the names is what lets U15 retune the ladder without touching a shared role |
| `crawlPanelPadding`, `crawlTokenCell`, `crawlTokenWidth`, `crawlLogPeekHeight`, `crawlMarkColumn`, `crawlMarkWell`, `crawlLogRowRhythm`, `crawlChipSpacing`, `crawlChipRunSpacing`, `crawlChipPadding`, `crawlChipVerticalPadding`, `crawlChipMaxColumns`, `crawlChipMaxLabelLines`, `crawlDisabledIconOpacity` | nothing — these were never aliases and already carry what they need. `crawlChipMaxLabelLines` keeps its existing dartdoc verbatim |
| `CrawlChipState`, `CrawlChipSkin`, `crawlChipSkin` | nothing — U15's chip vocabulary, unchanged |
| `markColumn` | nothing — keeps its existing device-metric dartdoc, reworded in Task 07. `labelColumn` is a different job at a different width |

### The procedure

This is **not** a rename in the language-server sense: the target name already
exists, so a naive rename produces `const Color ink = ink;`. The operation is
rename-then-delete, and it has two shapes. **Doing shape 2 as shape 1 is the
predictable way to break this task.**

**Shape 1 — the 31 non-colliding names** (every `crawl*` alias, plus
`town_style.dart`'s `mono`, `monoDim`, `placeName`, `roomName`):

1. language-server **rename symbol** on the alias declaration, to the shared
   token's name. Every consumer's identifier is repointed by the server;
2. the declaration is now self-referential and the analyzer says so. Delete the
   line.

**Shape 2 — the 4 colliding names** (`ink`, `dim`, `panel`, `rule`, whose
`town_style.dart` export already *is* the token's name): **no rename at all.**
Delete the four declarations and drop the prefix from `town_style.dart`'s
`tokens.dart` import, so the file's own widgets resolve the names directly.

**Then, for both shapes:** `flutter analyze` is the worklist. Every file with an
unresolved identifier needs `import 'package:residuum_app/style/tokens.dart';`
(or the relative path its neighbours use) added, and — where it no longer uses
anything from the seam file — that seam import removed. **Analyze-clean is the
completion signal.** That is what makes this decidable rather than a judgement
call per file.

Use the language server. **Not `sed`, not a hand edit, not a regex.** Across 35
names and roughly fifty files a hand edit is exactly where a wrong-value
substitution hides, and a wrong-value substitution is invisible to the type
checker because every one of these names is a `Color` or a `TextStyle` — the
compiler will happily accept `panel` where `raised` was meant. If the language
server cannot rename a symbol, **escalate**; do not hand-edit that one.

### The required comment correction

`crawl_surfaces_test.dart:297-300` asserts
`appBar.backgroundColor == town.panel` and `foregroundColor == town.ink`, under
the comment:

```text
// assert - the town's own panel and ink, hardcoded regardless of the
// ambient theme the crawl scoped over its own subtree
```

After shape 2 the `town.` prefix is gone and the assertion reads
`expect(appBar.backgroundColor, panel)`. There is no longer any way for the code
to express "the town's, not the crawl's", because there is one theme. **Correct
the comment** to say what the test now defends — that the pack route pushed from
the crawl is inside a theme at all and renders on the shared panel surface.

**The assertion itself does not change.** This is the one place in Unit 14 where
a test's stated purpose changes, it is residual R4, and A4 makes fixing it
required here rather than recommended at Gate B.

## Executor discretion

Yours without asking:

- the order the 35 names are processed in, and whether they go one at a time or
  in small batches per file;
- whether the `tokens.dart` import is package-qualified or relative in each
  file, matching that file's neighbours;
- the exact wording of the five kept-declaration dartdocs and of the corrected
  `crawl_surfaces_test.dart` comment;
- whether `flutter analyze` is run per batch or once at the end — but it must be
  clean before the suite is trusted.

Not yours: which names go and which stay, the two-shape procedure, using the
language server rather than text substitution, any value, any test expectation,
or the correction being required.

## Red proof

**There is none, and that is correct.** Behaviour is unchanged, so a new test
would assert nothing a consumer can observe and would be exactly the padding the
repository's doctrine forbids. The proof is the audit plus the unedited suite.

Before starting, record the baseline so the "no substantive test edit" claim is
checkable:

```text
flutter analyze
flutter test
```

Both must already be clean and green. If they are not, stop — this task cannot
distinguish its own breakage from inherited breakage.

## Green proof and package gates

```text
flutter analyze
dart format --set-exit-if-changed --output=none lib test
flutter test
```

Then the audit, recorded verbatim in the receipt:

```text
grep -n  "Color(0x\|const Color"  lib/game/crawl_style.dart lib/town/town_style.dart
grep -n  "TextStyle"              lib/game/crawl_style.dart lib/town/town_style.dart
grep -rn "Color(0x"               lib/game/crawl_style.dart lib/town/town_style.dart lib/main.dart
grep -rn "TextStyle("             lib --include=*.dart
grep -rn "fontFamily: '"          lib --include=*.dart
grep -rn "monospace"              lib --include=*.dart
```

Expected:

1. **nothing** — neither seam declares a colour at all. This closes **AC3**
   more strongly than Task 07's grep did;
2. only the **four** kept crawl declarations: `crawlChipLabel`,
   `crawlChipLabelDisabled`, `crawlChipLabelArmed`, `crawlCaption`. Not
   `crawlChevron` — A7 made it a pure alias and this task deletes it;
3. **nothing**;
4. only `lib/style/tokens.dart` and `lib/game/dungeon_scene.dart`;
5. **nothing** — Task 07's AC2 result, unchanged;
6. **nothing** — Task 07's AC2 result, unchanged.

Greps 3 and 4 are Task 07's closing audit re-run, because this task rewrote
exactly the files they cover. Greps 5 and 6 confirm this task did not disturb
AC2.

## Acceptance

- `crawl_style.dart` declares **no `Color`** and no bare-renaming `TextStyle`;
  it holds 14 metrics, **4** type declarations each with its dartdoc, and the
  chip-state table;
- `town_style.dart` declares **no `Color`** and no `TextStyle`; it holds
  `markColumn` and its widgets, and imports `tokens.dart` without a prefix;
- 35 declarations deleted — state the count in the receipt and reconcile it
  against the table above;
- every kept declaration that points at a shared role carries its dartdoc;
- `crawl_surfaces_test.dart:297-300`'s comment is corrected and its assertion
  is not;
- `flutter analyze` clean;
- **the diff against every file under `test/` contains only identifier
  substitutions and `import` lines — nothing else.** That is the mechanical
  form of "no substantive test edit", and it is checkable by reading the diff
  rather than by judging intent;
- the full suite green;
- all three package gates green;
- the six audit greps return what the table above says.

## Escalate, do not decide

- **any change to a test file that is not an identifier substitution or an
  `import` line.** Do not judge whether it is "substantive" — if the diff
  hunk is anything else, stop and report the file, the hunk and why it seemed
  necessary. A rename that needs a real test edit is a rename that is hiding
  something;
- an alias whose right-hand side disagrees with `../PLAN.md`'s mapping tables —
  an earlier task mis-aliased and this task must not launder it;
- a name collision the analyzer reports against code outside Unit 14's scope
  (a local, a parameter, a `core` or `content` symbol);
- the language server failing to rename a symbol;
- either seam file's membership differing from the tables above;
- any temptation to also tidy something adjacent. This commit is a rename and
  its whole value to a reviewer is that it reads as one.

## Receipt

Report: the deleted count reconciled against the 35-row table; the four kept
declarations with the dartdoc each gained; which names took shape 1 and which
took shape 2; the number of files whose imports were repointed; the corrected
`crawl_surfaces_test.dart` comment, before and after; the six audit greps
verbatim; `flutter analyze` and the full suite result; and **the shape of the
`test/` diff — identifier substitutions and import lines only, or the
escalation.** **State plainly whether AC3 is now closed.**

## Which agent — revised after A7

**`sonic` is now appropriate.** An earlier version of this brief argued for
`flow-plan-executor`, and its strongest reason was `crawlChevron`: a name on
the keep list that looked like an alias and was not, so applying the rule
required reading what each name *said*. **A7 deleted that reason along with the
name.** Defending the original call would be pretending a keep-list trap still
exists, and it does not.

What is left is fully enumerated and needs no judgement:

- **35 names to delete and 20 to keep, both listed exhaustively** in the tables
  above. No name requires reading its meaning. The four kept chip-ladder styles
  are kept by explicit architect ruling (A4), stated in the keep table, not by
  an inference the agent must draw;
- **two procedures, both written out as numbered recipes.** Flattening shape 2
  into shape 1 would produce `const Color ink = ink;` on four declarations, and
  the brief says so at the point of use;
- **the correctness condition is now a diff shape, not a judgement**: the
  `test/` diff may contain only identifier substitutions and import lines. That
  replaced "no substantive edit", which did require judgement and was the last
  real argument for a reasoning agent.

Two things the dispatcher should still supply, because they are the only places
this task is not a single pass:

1. **the import repoint is an analyzer-driven loop**, not one edit: delete →
   `flutter analyze` → add `tokens.dart` imports → analyze → remove
   now-unused seam imports → analyze. Analyze-clean is the termination signal
   and the brief names it, but a leaf agent must be told to iterate rather than
   to run the analyzer once;
2. **Main reads the `test/` diff shape at acceptance.** It is one grep over the
   diff and it is the backstop for the one condition that used to need
   judgement.

If either of those cannot be supplied, `flow-plan-executor` remains a safe
fallback — the task is small enough that the cost of the stronger agent is
low — but it is no longer the recommendation.
