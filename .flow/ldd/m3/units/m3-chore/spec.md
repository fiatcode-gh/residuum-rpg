# Spec — m3-chore (story M3CH): CI, analyzer config, lockfiles, README

Precedent: audit `docs/reports/2026-09-03-audit-residuum-rpg.md` group 2
(TTC-3, SEC-7, SEC-8, DST-1, DST-5) — routing D102, scope locked D102
group 2 / follow-ups 41–42. Recon: `m3-chore-recon.md` (this directory).
Forks ruled by the user 2026-09-08, locked as D114.

## Goal

The repo stops depending on a human remembering three commands in three
directories. A GitHub Actions workflow runs format, analyze, and the test
suite per package on every PR to main; core/content get an analyzer config
matching their strictest-in-repo status; their lockfiles are committed so
CI and local runs resolve identically; the READMEs describe the M3 game
that actually ships instead of the M2 one. No `lib/` code changes anywhere.

## Shape

Read from the codebase, not by analogy: `packages/app/analysis_options.yaml`
is the existing analyzer-config precedent (an `include:` line plus rules);
core/content mirror its minimalism with `package:lints/recommended.yaml`
(pure Dart packages — NOT flutter_lints). The CI matrix shape is the one
previewed and ruled (D114). Suites run per package directory per D101.

## New files

- `.github/workflows/ci.yml`
- `packages/core/analysis_options.yaml`
- `packages/content/analysis_options.yaml`

## Changed files

- `.gitignore` — drop the two lockfile lines (6–7)
- `packages/core/pubspec.yaml`, `packages/content/pubspec.yaml` — add
  `lints` as a dev-dependency (must resolve BEFORE the analysis_options
  include can work)
- `packages/core/pubspec.lock`, `packages/content/pubspec.lock` —
  regenerated fresh, committed
- `packages/core/test/dungeon/generator_items_test.dart` — 4 ×
  `curly_braces_in_flow_control_structures` fixes
- `packages/content/test/content_validation_test.dart` — 1 ×
  `curly_braces` fix (line ~1387)
- `packages/content/test/world_test.dart` — 1 ×
  `no_leading_underscores_for_local_identifiers` fix (rename
  `_spoilsOverManyDays` → `spoilsOverManyDays`, local scope only)
- `README.md` — Current state refreshed to M3 shipped reality
- `packages/app/README.md` — boilerplate replaced with a real description

## Per-item contract

**ci.yml.** `on: pull_request` targeting `main`, plus `push` to `main`
only. One job, `strategy.matrix.package: [core, content, app]`. Steps:
checkout (whole repo — content reaches core via `../core`); flutter-action
pinned to EXACTLY `3.47.2`, never `stable`; then per package with
`working-directory: packages/<pkg>`:
`dart format --set-exit-if-changed --output=none .` → `dart analyze`
(core, content) / `flutter analyze` (app) → `dart test` (core, content) /
`flutter test` (app). MUST NOT: invoke anything from the repo root (D101),
run on pushes to other branches, upload artifacts, or float the Flutter
version. No AVD — widget tests are headless (D113 alignment).

**analysis_options (core, content).** Exactly one line of content beyond
prose: `include: package:lints/recommended.yaml`. No excludes, no extra
rules, no flutter_lints. If a recommended lint would demand lib/ changes,
STOP and report instead of adding excludes — the measured cost is six
test-file findings and nothing more.

**Lockfiles.** `dart pub get` fresh in each package immediately before
commit so the lock matches the committed pubspec; then commit. CI resolves
from the lock (dart/flutter test use it by default).

**README.md.** Current state describes the shipped M3 game: nine skills
named, magic/craft/world travel/multiple dungeons/saves/roster/the rebuilt
battle flow; "M2 complete" gone; NO hardcoded test count anywhere — the
Tests section keeps the command block and adds one sentence: the suites
are enforced by CI on every PR to main. Roadmap updated (M3 done, M4 The
Story next). The balance-band sentence stays, updated to the current band
of record (D79-pinned). Do NOT touch CLAUDE.md (follow-up 43 needs the
author) and do NOT restate the comment policy.

**packages/app/README.md.** Replace the boilerplate: what the package is
(the Flutter shell: screens, BLoC, glyph renderer — no game rules), how to
run it (`cd packages/app && flutter run`), where the tests are, and the
CLAUDE.md pointer. No "Getting Started" Flutter tutorial content.

## Behaviour arguments that must land in documentation

- Why lockfiles committed: with `publish_to: none` they cost nothing and
  buy identical resolution locally and on CI; a silent pub upgrade must
  never explain a CI-only red.
- Why the version pin is exact: the suites pin seeded behavior; a silent
  Flutter bump could move a widget-test surface. Bumping 3.47.2 is a
  deliberate act (edit the pin, re-run), not a side effect.
- Why no hardcoded test count in the README: counts rot at every merge;
  the command cannot go stale.
- Nothing is deliberately-wrong here; no preserved defects.

## Test plan

This unit's gates ARE its tests; the worker proves each locally before
any push.

1. Characterization (measured in recon, re-run by the worker before
   editing): all three packages `format --set-exit-if-changed` clean;
   `analyze` clean under current configs; 2045 green (835/573/637) —
   strict counts from result files, per package directory.
2. After the lint fixes: `dart analyze` clean in core and content under
   `lints/recommended`; `flutter analyze` clean in app.
3. After the content test-file edits: re-run the band — all five lines
   byte-identical to the D79 pins (crypt 16/40 BY RULING, casting 40/40
   informational, greedy 16 / fleetfoot 13, sea-cave 26/40, keep 24/40).

### Mutation table

| Row | Mutation | Expected red | Expected green (control) | Why |
|---|---|---|---|---|
| M1 | Re-un-brace one fixed `if` in `generator_items_test.dart` | core `dart analyze` (1 named finding: `curly_braces`) | content + app analyze green | proves the new gate fires on the class it was adopted for |
| M2 | Re-underscore the renamed local in `world_test.dart` | content `dart analyze` (1 named finding) | core analyze green | proves content's config resolves and enforces |
| M3 | Inject one unformatted line into `packages/core/lib`/a core test file, push to a SCRATCH branch | CI format step red on the core leg only | content + app legs green | proves the workflow gates format, not just local runs. REVERT after the red is recorded |
| M4 | Delete `packages/core/pubspec.lock` from a scratch branch | CI red or a lock-regeneration diff on the core leg | content/app legs green | proves CI actually consumes the committed lock |

Sequencing traps: M3/M4 require the workflow to exist on GitHub first —
they run against the unit's own scratch branch AFTER the user-approved
push, never before, and never against main. M1/M2 run locally BEFORE any
push. Report both halves of every row.

## Hazards

- D101: no root pubspec. Every CI step uses `working-directory`; a
  root-level `flutter test` fails by design.
- `lints` must be in dev_dependencies before `analysis_options.yaml`
  references it, or analyze errors with `include_file_not_found`.
- The committed lockfiles must be regenerated in the same commit as the
  pubspec changes, or the pin and the manifest disagree.
- D56: content edits are test-file-only; band lines verified after.
- External writes (push, PR, the red-proof scratch branch) need the
  user's approval per round; branch protection is enabled by the USER in
  the GitHub settings UI after the unit's PR shows the three checks
  (D114 ruling). The architect may NOT touch repo settings.
- Background-runner shells may be fish — wrap watch/suite commands in
  `bash -c` where loops appear.
- This unit has no AVD pass (no UI change). The D113 method change does
  not alter close-out for it either: no new screens, no mirror shots
  beyond the README's own content if the worker deems them useful (not
  required).

## Follow-ups to log

- 43 (CLAUDE.md module list + comment policy) and 44 (signing config)
  remain open — deliberately out of scope.
- If the hosted runner's wall-clock hurts (content band sim), cache tuning
  is a follow-up, not this unit's scope.

## Definition of done

- `.github/workflows/ci.yml` exists in the contracted matrix shape with
  the exact version pin; nothing runs from the repo root.
- `dart analyze` clean in core and content under `lints/recommended`;
  `flutter analyze` clean in app; `format --set-exit-if-changed` clean in
  all three.
- `packages/core/pubspec.lock` and `packages/content/pubspec.lock` are
  tracked (git check-ignore empty), `.gitignore` updated, lock content
  matches a fresh `dart pub get`.
- All three suites green: 2045 tests (strict counts, zero failures).
- All five band lines byte-identical to the D79 pins.
- README.md carries no stale claim and no hardcoded test count;
  `packages/app/README.md` is real prose about the actual package.
- The M3 red-proof recorded on a scratch branch (one red leg, controls
  green, reverted).
- The unit's own PR shows three green legs; the user then enables branch
  protection in the settings UI (user-side step, recorded when done).