# Recon — the chore unit (m3-chore, story M3CH, D102 group 2)

**VERDICT:** The audit's four chore findings all hold and are cheap: no CI
exists; all three packages are already format/analyze-clean so strict gates
can land day one; `lints/recommended` on core/content costs exactly six
trivial test-file fixes; core/content lockfiles are gitignored but exist
locally; the README is stale on every load-bearing number ("M2 complete",
"Four skills" — the enum has nine, "514 tests" — 2045 today) and the app
README is untouched boilerplate.

## State verified before measuring

`main` = `b2c1381` on GitHub, clean checkout, no worktree in flight. Measured
2026-09-08 by the architect. Local toolchain measured fresh: Flutter 3.47.2
stable, Dart 3.13.

## The measurement

- `.github/` does not exist. No hooks, no Makefile/justfile. (Audit TTC-3
  confirmed at source.)
- `dart format --set-exit-if-changed --output=none .` → **clean** in core,
  content, and app.
- `flutter analyze` per package directory → **No issues found** in all three.
- `lints/recommended.yaml` trial (throwaway copies in /tmp, `lints` added as
  a dev-dependency so the include resolves):
  - core: **4 findings**, all `curly_braces_in_flow_control_structures` in
    `test/dungeon/generator_items_test.dart`.
  - content: **2 findings** — `curly_braces_in_flow_control_structures`
    (`test/content_validation_test.dart:1387`) and
    `no_leading_underscores_for_local_identifiers` (`_spoilsOverManyDays`,
    `test/world_test.dart:868`).
  - `lints` is NOT currently resolvable in core/content — the include fails
    until the dev-dependency is added. The app uses `flutter_lints ^6.0.0`.
- `.gitignore:6-7` excludes `packages/core/pubspec.lock` and
  `packages/content/pubspec.lock`; both lockfiles exist locally; app's lock
  is already committed. (Audit SEC-8 confirmed.)
- Analyzer config exists only in app (`flutter_lints` + boilerplate prose).
  Core/content have none. (Audit SEC-7 confirmed.)
- README.md: "M2 complete", "Four skills", "514 tests", roadmap lists M3 as
  future. `SkillId` has nine members (arms, might, bulwark, fleetfoot,
  wrath, mending, binding, herbcraft, blacksmith). Suite counts today:
  2045 (835/573/637). (Audit DST-1 confirmed.)
- `packages/app/README.md` is stock Flutter boilerplate. (Audit DST-5
  confirmed.)
- content's pubspec depends on core via relative path `../core` — CI must
  check out the monorepo whole and run per package (D101: no root pubspec;
  `flutter test packages/<pkg>` from the root fails).

## Is each inherited gate real?

- "No CI" — real, verified.
- "Analyzer config missing for core/content" — real, verified.
- "Lockfiles uncommitted" — real, verified.
- "README stale by a full milestone" — real, and worse than the audit
  states (it cited 1941 tests; main is now 2045).
- One recon non-finding: a `dead_code` warning at
  `test/content_validation_test.dart:1301` appeared in a broken /tmp trial
  (unresolved `../core` path) and does NOT appear against the real tree —
  the real `flutter analyze` is clean. Do not chase it.

## Findings that change the spec

- The lint adoption cost is measured and trivial — six test-file style
  fixes, no lib/ changes. This makes `lints/recommended` safe to promise.
- content → core is a PATH dependency, so the CI matrix must use
  working-directory per package on a full checkout (no sparse checkout,
  no root-level invocation).
- One lint fix renames a local inside `test/world_test.dart` (the band
  sim's file). Behavior-neutral, but the D56 caution binds: the band lines
  must be re-run and proven byte-identical after the content edits.

## Proposed shape of the work

Single unit, single branch (`m3-chore`), no production `lib/` changes:
one workflow file (matrix job, Flutter pinned exact), two
`analysis_options.yaml` files + `lints` dev-deps, two lockfiles committed
with their `.gitignore` lines dropped, six lint fixes in three test files,
README refresh, app README rewrite. PR to main per the D22 flow.

## Hazards to carry into the spec

- D101 (no root pubspec) shapes the CI steps — per-package
  working-directory only.
- flutter-action pin must be EXACT (3.47.2), never `stable`.
- Committing lockfiles: run `dart pub get` fresh in each package first so
  the committed lock matches the committed pubspec.
- D56: nothing bot-visible may move; band lines verified after content
  edits.
- The push/PR/branch-protection sequence is external writes — user
  approval per round; branch protection is the USER's settings-UI action
  (ruled this session, D114).

## What this recon did NOT check

- Hosted-runner behavior of `flutter-action` at exactly 3.47.2, and the
  hosted wall-clock of the content suite's band simulation — the worker
  verifies on the first real CI run.
- Whether `dart test` for core/content could run without the Flutter SDK
  on the runner — moot; the matrix ruled (D114) uses flutter-action
  uniformly.
- Branch-protection mechanics — deliberately deferred; the user enables it
  in the GitHub settings UI after the unit's PR shows the checks.