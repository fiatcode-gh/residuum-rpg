# M3CH Chore Implementation Plan

> Execute with flow-executing-plans, task by task.

**Goal:** The repo gets CI enforcement (format/analyze/test per package on PRs
to main), `lints/recommended` analyzer configs for core and content, committed
lockfiles, and READMEs that describe the M3 game that ships. No `lib/` code
changes anywhere.

**Spec:** `/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/m3-chore-spec-M3CH.md`
(amended by ledger decision D115; see Global constraints)

## Global constraints

- No changes to any package's `lib/` directory EXCEPT the one D116-authorized
  fix: brace-wrap the DrinkAction early return at
  `lib/src/engine/step.dart:466-467` to match its braced sibling two lines
  below. Nothing else in lib/ moves. The fix gets its OWN commit, separate
  from the test-file lint fixes (D116); after that commit core suites re-run
  (835 strict-green) and all five band lines re-verify (D56).
- Every commit's exit state is green: the step.dart commit lands with the
  analyzer configs stashed (analyze clean under the absent old config), then
  the config+test-fix commit brings the new config up with its findings fixed.
- Every commit's exit state is green: format clean x3, analyze clean x3,
  suites green.
- Suites run per package directory (D101: no root pubspec).
- `lints` must be in dev_dependencies before `analysis_options.yaml`
  references it, or analyze errors with `include_file_not_found`.
- Lockfiles regenerated with `dart pub get` in the same commit as the pubspec
  change they match.
- Nothing under `docs/epic/` is ever committed.
- No pushing, no PR, no GitHub settings changes by the worker; M3/M4 need
  user-approved push via the mailbox.
- Commits use the personal persona (no `--author`, no GIT_AUTHOR_EMAIL).
- Band lines byte-identical after any content test edit (D56): crypt 16/40,
  casting 40/40, greedy 16 / fleetfoot 13, sea-cave 26/40, keep 24/40.
- Characterization baseline (measured, worktree `m3-chore` at `b2c1381`,
  after per-package `dart pub get`): format clean x3 (core 104/0, content
  54/0, app 71/0 — exit 0 each); analyze clean x3; strict suite counts
  835 core + 573 content + 637 app = 2045, zero failures, from
  `/tmp/m3chore-baseline-{core,content,app}.json` (field: `"result":"success"`,
  `"hidden":true` excluded).

## Amended contract (D115)

`ci.yml` gains an explicit resolution step per package BEFORE the gates:
`dart pub get` (core, content), `flutter pub get` (app). Ordering is
load-bearing: resolution affects both `dart analyze` and the formatter's
language-version behavior (format is only canonical after `pub get`).

## Measured lint set (supersedes the spec's table)

`lints 6.1.0`, `analysis_options.yaml` = `include: package:lints/recommended.yaml`
only. Measured in the resolved worktree 2026-09-07:

- core (4): `test/dungeon/generator_items_test.dart:58:13`, `:60:13`, `:62:13`
  (`curly_braces_in_flow_control_structures`) + `lib/src/engine/step.dart:467:9`
  (`curly_braces_in_flow_control_structures` — LIB/, blocked on ruling).
- content (2): `test/content_validation_test.dart:1387:11` (`curly_braces`)
  - `test/world_test.dart:868:16` (`no_leading_underscores_for_local_identifiers`,
  rename `_spoilsOverManyDays` → `spoilsOverManyDays`, local scope only).

The recon's "4 all in generator_items_test.dart" was wrong on both axes; this
is the real set. Total is still six, split 3 test + 1 lib + 2 test.

### Task 1: Plan doc on the branch

**Files:** `docs/plans/chore-plan-M3CH.md`

- [x] Write this plan.
- [x] Commit: `cd /var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/.worktrees/m3-chore && git add docs/plans/chore-plan-M3CH.md && git commit -m "docs: M3CH chore plan (CI, lints, lockfiles, README)"`

### Task 2: Core — analyzer config, lints, test fixes, lockfile

**Files:** `.gitignore`, `packages/core/pubspec.yaml`,
`packages/core/analysis_options.yaml`, `packages/core/pubspec.lock`,
`packages/core/test/dungeon/generator_items_test.dart`

- [x] `cd packages/core && dart pub add dev:lints` (done: `lints: ^6.1.0` at
      pubspec line 11).
- [x] Write `packages/core/analysis_options.yaml` containing exactly:
      `include: package:lints/recommended.yaml` (done).
- [x] Brace the three ifs at lines 58/60/62 of
      `packages/core/test/dungeon/generator_items_test.dart`:
      ```dart
      if (!floor.map.isWalkable(spawn)) {
        problems.add('$spawn is not walkable');
      }
      if (spawn == floor.heroSpawn) {
        problems.add('$spawn is under the hero');
      }
      if (spawn == floor.stairsDown) {
        problems.add('$spawn is on the stairs');
      }
      ```
- [x] STEP COMMIT (D116, own commit): stash the analyzer-config files
      (`git stash push --include-untracked -- packages/core/pubspec.yaml
      packages/core/analysis_options.yaml packages/content/pubspec.yaml
      packages/content/analysis_options.yaml`), then wrap the unbraced if at
      `lib/src/engine/step.dart:466-467`:
      ```dart
      if (item == null) {
        return const ActionRefused(reason: 'you are not carrying that');
      }
      ```
      Gates: format exit 0; `dart analyze` no issues; full core suite
      835 strict-green. Commit ONLY step.dart:
      `git add packages/core/lib/src/engine/step.dart && git commit -m "fix: brace the DrinkAction early return (lints/recommended curly_braces)"`
      then pop the stash. Band lines re-verified after the content commit
      (chronologically after the step.dart commit, satisfying D116.3).
- [x] Drop `.gitignore` lines 6–7 (`packages/core/pubspec.lock`,
      `packages/content/pubspec.lock` — both lines in this task's commit).
- [x] `cd packages/core && dart pub get` fresh; verify
      `git check-ignore -v packages/core/pubspec.lock` prints nothing;
      `git add packages/core/pubspec.lock`.
- [x] Gates: `dart format --set-exit-if-changed --output=none .` exit 0;
      `dart analyze` "No issues found!"; `flutter test` 835 strict-green.
- [x] Commit: `git add .gitignore packages/core && git commit -m "chore: core analyzer config (lints/recommended), lockfile, test-file lint fixes"`

### Task 3: Content — analyzer config, lints, test fixes, lockfile

**Files:** `packages/content/pubspec.yaml`,
`packages/content/analysis_options.yaml`, `packages/content/pubspec.lock`,
`packages/content/test/content_validation_test.dart`,
`packages/content/test/world_test.dart`

- [x] `cd packages/content && dart pub add dev:lints` (done: `lints: ^6.1.0`
      at pubspec line 16).
- [x] Write `packages/content/analysis_options.yaml` containing exactly:
      `include: package:lints/recommended.yaml` (done).
- [x] Brace the if at `test/content_validation_test.dart:1387`:
      ```dart
      if (weights.any((weight) => weight < 0)) {
        problems.add('negative weight');
      }
      ```
- [x] Rename `_spoilsOverManyDays` → `spoilsOverManyDays` in
      `test/world_test.dart` (declaration + every call site in the file).
- [x] `cd packages/content && dart pub get` fresh; verify
      `git check-ignore -v packages/content/pubspec.lock` prints nothing;
      `git add packages/content/pubspec.lock`.
- [x] Gates: `dart format --set-exit-if-changed --output=none .` exit 0;
      `dart analyze` "No issues found!"; `flutter test` 573 strict-green;
      band line capture —
      `flutter test test/survivability_test.dart --reporter expanded` prints
      all five D79 lines verbatim: crypt 16/40, casting 40/40,
      greedy 16 / fleetfoot 13, sea-cave 26/40, keep 24/40.
- [x] Commit: `git add packages/content && git commit -m "chore: content analyzer config (lints/recommended), lockfile, test-file lint fixes"`

### Task 4: CI workflow

**Files:** `.github/workflows/ci.yml`

- [x] Write `.github/workflows/ci.yml` exactly:
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
- [x] Verify: `git grep -n "working-directory: \." .github/workflows/ci.yml`
      prints nothing (no root-level invocation, D101); the exact pin
      `flutter-version: 3.47.2` present; no artifacts upload.
- [x] Commit: `git add .github && git commit -m "ci: per-package format/analyze/test gates on PRs to main"`

### Task 5: README refresh

**Files:** `README.md`, `packages/app/README.md`

- [x] Root README: replace "M2 complete", "Four skills" (nine:
      arms, might, bulwark, fleetfoot, wrath, mending, binding, herbcraft,
      blacksmith), any hardcoded test count; current state describes M3
      shipped reality (magic/craft/world travel/multiple dungeons/saves/
      roster/rebuilt battle flow); Roadmap: M3 done, M4 The Story next;
      Tests section keeps the command block + one sentence: the suites are
      enforced by CI on every PR to main; balance-band sentence stays,
      updated to the D79-pinned band; no CLAUDE.md touch, no comment-policy
      restatement.
- [x] App README: replace boilerplate with real prose — the Flutter shell
      (screens, BLoC, glyph renderer — no game rules), run via
      `cd packages/app && flutter run`, where tests live, CLAUDE.md pointer.
      No "Getting Started".
- [x] Verify: `grep -n "514\|Four skills\|M2 complete" README.md` prints
      nothing; app README has no "Getting Started".
- [x] Commit: `git add README.md packages/app/README.md && git commit -m "docs: READMEs describe the M3 game that ships"`

### Task 6: Mutations M1/M2 (local, reverted after)

- [x] M1: un-brace one fixed if in `generator_items_test.dart`; expect core
      `dart analyze` exactly 1 finding (`curly_braces_in_flow_control_structures`,
      named line); controls: content + app analyze stay green. Record, then
      `git restore` the file.
- [x] M2: re-underscore the renamed local in `world_test.dart`; expect
      content `dart analyze` exactly 1 finding
      (`no_leading_underscores_for_local_identifiers`); control: core analyze
      green. Record, then `git restore` the file.
- [x] M3/M4: NOT executable without a push — named skip "pending push
      authorization" per build prompt section 7; architect picks them up
      during verification.

### Task 7: Verification + REPORT.md

- [ ] Close with flow-verification: quote every gate output into
      `REPORT.md` in the channel directory; mirror the full verification
      block from the build prompt section 10, including the named M3/M4 skip
      and the step.dart ruling outcome; append done notice to `worker.md`.
