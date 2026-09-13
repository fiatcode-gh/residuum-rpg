# M3CH report — worker session

Date: 2026-09-07. Worktree: `.../residuum-rpg/.worktrees/m3-chore`, branch
`m3-chore`, base `b2c1381`. All numbers below are quoted from commands run in
this session. Spec: `docs/epic/m3-chore-spec-M3CH.md` (absolute:
`/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/m3-chore-spec-M3CH.md`),
amended by ledger decisions D115 (ci.yml resolution step) and D116 (step.dart
brace fix authorized as one named lib/ exception).

## 1. Branch proof

`cd /var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/.worktrees/m3-chore && pwd`
→ `/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/.worktrees/m3-chore`

`git log main..m3-chore --oneline` → 9 commits, all on `m3-chore`:

```
53b68f1 docs: record whole-branch review minors in M3CH plan
1ae03e1 docs: untick plan Task 7 until REPORT.md lands
c563a38 docs: check off executed M3CH plan tasks
306f4b0 docs: READMEs describe the M3 game that ships
cec2abe ci: per-package format/analyze/test gates on PRs to main
fdfd452 chore: content analyzer config (lints/recommended), lockfile, test-file lint fixes
3494700 chore: core analyzer config (lints/recommended), lockfile, test-file lint fixes
9fb0777 fix: brace the DrinkAction early return (lints/recommended curly_braces)
7ddb71f docs: fold D116 step.dart ruling into M3CH plan
f90f661 docs: M3CH chore plan (CI, lints, lockfiles, README)
```

Nothing committed to the parent checkout on `main`.

## 2. Characterization baseline (re-run against UNMODIFIED code at b2c1381)

Measured before any edit, in the worktree, after per-package `dart pub get`
(resolution is load-bearing — see item 10):

- `dart format --set-exit-if-changed --output=none .` — core "Formatted 104
  files (0 changed)" exit 0; content "Formatted 54 files (0 changed)" exit 0;
  app "Formatted 71 files (0 changed)" exit 0.
- `dart analyze` core → "No issues found!"; `dart analyze` content → "No
  issues found!"; `flutter analyze` app → "No issues found!".
- Strict suite counts (one run per package directory, `flutter test
  --machine`, result files `/tmp/m3chore-baseline-{core,content,app}.json`,
  counting `testDone` ∧ `"result":"success"` minus `"hidden":true`):
  **core 835 + content 573 + app 637 = 2045**, zero failures, zero error
  events. (My first counting pass used a wrong field — `"success":true`,
  0 hits by definition; the correct field is `"result":"success"`.)
- Baseline origin: measured fresh by the architect at `b2c1381` (recon,
  2026-09-08) and re-measured by me before editing. One correction to the
  baseline origin per dispatcher entry 2: the recon's format/analyze ran with
  resolution present; the spec's characterization step means "after
  per-package pub get".

## 3. Post-change gates

- `dart format --set-exit-if-changed --output=none .` — core/content/app all
  exit 0, 0 changed (re-run after the last commit).
- `dart analyze` core → "No issues found!" under
  `include: package:lints/recommended.yaml` (lints 6.1.0).
- `dart analyze` content → "No issues found!" under the same config.
- `flutter analyze` app → "No issues found! (ran in 3.1s)".
- Six findings fixed, named: core `curly_braces_in_flow_control_structures`
  ×3 at `test/dungeon/generator_items_test.dart:58/60/62` + ×1 at
  `lib/src/engine/step.dart:467` (D116-authorized, own commit, brace-wrap
  only); content `curly_braces` ×1 at
  `test/content_validation_test.dart:1387` +
  `no_leading_underscores_for_local_identifiers` ×1 (`_spoilsOverManyDays`
  → `spoilsOverManyDays`, declaration + 3 call sites, all in-file).
- Final suites (post-change proof): core 835 strict-green / 0 failed,
  content 573 / 0, app 637 / 0 — result files
  `/tmp/m3chore-final-{core,content,app}.json`. 2045 total.

## 4. Band lines (D79 pins), from my own run

Captured from the content suite's machine-reporter print events
(`/tmp/m3chore-content-task3.json`), byte-consistent with D79:

```
survivability: 16/40 won (40.0%), stalled 0, died at 1:1 2:9 3:8 4:6 5:16
casting build: 40/40 won
greedy build: 16/40 won; fleetfoot-first build: 13/40 won
sea-cave: 26/40 won (65.0%), stalled 0, died at 2:3 3:7 4:14 5:11 6:5
ruined keep: 24/40 won (60.0%), stalled 0, died at 1:5 2:5 3:3 4:2 5:13 6:7 7:5
sea-cave 26/40 vs ruined keep 24/40
```

All five expected lines present: crypt 16/40, casting 40/40, greedy 16 /
fleetfoot 13, sea-cave 26/40, keep 24/40.

## 5. Mutation table — both halves of every row

| Row | Red half (observed) | Green half (controls, observed) |
|---|---|---|
| M1 | Un-braced one fixed if in `generator_items_test.dart` → core `dart analyze`: exactly 1 finding, `curly_braces_in_flow_control_structures`, `test/dungeon/generator_items_test.dart:58:13` | content analyze "No issues found!", app analyze "No issues found!" |
| M2 | Re-underscored the renamed local (declaration + call sites) in `world_test.dart` → content `dart analyze`: exactly 1 finding, `no_leading_underscores_for_local_identifiers`, `test/world_test.dart:868:16` | core analyze "No issues found!" |
| M3 | SKIPPED — pending push authorization (scratch-branch CI red needs a push; user approves per round) | — |
| M4 | SKIPPED — pending push authorization (same sequencing trap) | — |

Both local mutations were reverted (`git restore`) after recording; tree
clean after each. First M2 attempt mutated only the call sites — wrong
mutation (4 undefined_function + 1 unused_element); redone with declaration
included, as recorded. M3/M4 are a named skip per build prompt section 7;
the architect picks them up during verification after the user-approved push.

## 6. Lockfile proof

- `git check-ignore -v packages/core/pubspec.lock packages/content/pubspec.lock`
  → prints nothing, exit 1 (not ignored).
- Fresh `dart pub get` in both packages after the commits →
  `git status --porcelain` empty (committed locks diff-clean, matching the
  committed pubspecs).
- Both committed locks pin `lints 6.1.0` matching `lints: ^6.1.0` in both
  pubspecs; `.gitignore` lines 6–7 dropped (commit 3494700).

## 7. Workflow proof

`.github/workflows/ci.yml` in full:

```yaml
name: ci

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  gates:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        package: [core, content, app]
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: 3.47.2
          channel: stable
      - name: resolve (dart pub get)
        if: matrix.package != 'app'
        working-directory: packages/${{ matrix.package }}
        run: dart pub get
      - name: resolve (flutter pub get)
        if: matrix.package == 'app'
        working-directory: packages/${{ matrix.package }}
        run: flutter pub get
      - name: format
        working-directory: packages/${{ matrix.package }}
        run: dart format --set-exit-if-changed --output=none .
      - name: analyze
        working-directory: packages/${{ matrix.package }}
        run: ${{ matrix.package == 'app' && 'flutter analyze' || 'dart analyze' }}
      - name: test
        working-directory: packages/${{ matrix.package }}
        run: ${{ matrix.package == 'app' && 'flutter test' || 'dart test' }}
```

- Exact pin present: `git grep -n "flutter-version: 3.47.2" .github/workflows/ci.yml`
  → `.github/workflows/ci.yml:19: flutter-version: 3.47.2`.
- No root-level invocation (D101): `git grep -n "working-directory: \." ...`
  → nothing (exit 1). Every gate step carries
  `working-directory: packages/${{ matrix.package }}`.
- No artifacts/upload: grep for `artifacts|upload` → nothing.
- Triggers: `pull_request` → `main`, `push` → `main` only.
- D115 amendment in place: resolution step per package BEFORE the gates.

## 8. README proof

- `grep -n "514\|Four skills\|M2 complete" README.md` → nothing (exit 1).
- `grep -in "getting started" packages/app/README.md` → nothing (exit 1).
- Root README: M3 current state (nine skills named: arms, might, bulwark,
  fleetfoot, wrath, mending, binding, herbcraft, blacksmith; three themed
  dungeons; road encounters; spell books; gathering and crafting; saves and
  roster; rebuilt battle flow), roadmap M3 shipped / M4 The Story next,
  Tests section keeps the command block + the CI-enforcement sentence, band
  sentence updated to the D79 band of record. No CLAUDE.md touch, no
  comment-policy restatement anywhere.
- App README: real prose about the Flutter shell (screens, BLoC, glyph
  renderer — no game rules), run command, where tests live, directory map
  (game/world/town/save/notice — verified against `ls packages/app/lib`),
  CLAUDE.md pointer.

## 9. What the tests cannot prove

Nothing here proves the workflow's behavior ON GitHub: that flutter-action
serves exactly 3.47.2 on hosted runners, that the three legs pass there, or
that M3/M4's scratch-branch proofs behave as expected. Those are M3/M4 plus
the unit's own PR run — after the user-approved push. M3/M4 remain named
skips until then.

## 10. Every spec claim checked and found wrong

1. **The six-finding lint count's attribution** (recon): "4 × curly_braces,
   all in generator_items_test.dart" was wrong on both axes. Measured real
   set: core 3 test findings + 1 lib finding (`step.dart:467`, missed by the
   recon); content 2 as claimed. Dispatcher owned the recon error and
   promoted my measurement as the number of record (D116).
2. **The "format clean day one" premise** — true ONLY with resolution
   present. Without `.dart_tool/` (fresh worktree), `dart format` defaults
   to the latest language version and flags ~6+6 files; with `dart pub get`,
   format is canonical at the committed shape. My first causal story
   (dart_style #1809) was wrong; the dispatcher corrected it (D115). The
   spec's characterization step is understood as "after per-package pub get".
3. **The ci.yml step list omitted resolution** — `dart analyze` does not
   resolve implicitly; without a pub-get step every leg reds out on day one.
   Accepted as a spec amendment (D115).

## 11. Execution phases, and any named skip

- flow-mailbox standing watch: started before the spec (first action), kept
  alive and verified at task boundaries. One incident: the FIRST watch
  instance died silently (bg-runner shell is fish; the script is sh) —
  relaunched wrapped in `bash -c`, verified via process tree; later watches
  use the same wrapper. Two spurious wakes handled (no new mail; progress
  sent as the expected entry instead).
- Characterization baseline: run in full against unmodified code BEFORE any
  edit (item 2 above).
- flow-writing-plans: `docs/plans/chore-plan-M3CH.md` committed (f90f661),
  amended for D116 (7ddb71f), checkboxes maintained (c563a38, 1ae03e1).
- flow-executing-plans: DIRECT mode chosen (small mechanical plan, judged by
  complexity). Setup: worktree path taken from the dispatcher, MERGE_BASE
  b2c1381 recorded. Per-task commits, each verified green.
- flow-tdd: applied in the proportion the spec's test plan defines — the
  gates are the red tests (a lint finding is the red, the brace the green);
  safety-net baselines run before each touching step; the D116 lib/ fix ran
  with the full core suite as its safety net (835 strict-green before its
  commit).
- Mutations M1/M2 recorded; M3/M4 named skip (item 5).
- flow-verification: every claim above carries the command and its output,
  run fresh in this session.
- Whole-branch review: ONE reviewer over b2c1381..HEAD → **APPROVED**, 3
  Minor findings (none blocking), recorded in the plan doc (53b68f1):
  generator_items_test brace density (cosmetic), Task-7 tick/untick commit
  hygiene (net state correct), ci.yml missing trailing newline (valid YAML).
- flow-finishing: INTEGRATION STEPS JUDGED NOT MINE — push/PR/merge are
  external writes needing the user's explicit approval per round; the
  architect handles them. The worker's part of flow-finishing (verify,
  report, stop) is what this report and the done notice fulfill.

## Incident log

- One accidental real `dart format` run (no `--output=none`) touched
  `packages/core/lib/src/dungeon/generator.dart`; reverted immediately and
  re-verified clean (dispatcher entry 2, item 4). The harness auto-format
  hook re-dirtied the file once afterwards; second revert stuck; status
  re-checked at boundaries since.
- The mailbox watch needed a `bash -c` wrapper (fish bg-runner vs sh script).

## Definition of done — status

- ci.yml in the contracted matrix shape with the exact pin; nothing from the
  repo root. DONE.
- analyze clean in core/content under lints/recommended; flutter analyze
  clean in app; format clean ×3. DONE (quoted above).
- Both locks tracked, .gitignore updated, locks diff-clean vs fresh pub get.
  DONE.
- Suites green: 2045 (835/573/637), zero failures. DONE.
- All five band lines byte-consistent with the D79 pins. DONE.
- READMEs: no stale claim, no hardcoded count; app README real prose. DONE.
- M3 red-proof on a scratch branch: PENDING — needs the user-approved push.
- Unit's PR showing three green legs + user-enabling branch protection:
  AFTER the push; not worker-executable.