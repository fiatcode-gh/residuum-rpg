# Recon — 2026-08-20 — M1 baseline

## VERDICT

The repository is empty of code (docs only), the toolchain can scaffold and
test Dart packages headlessly in the sandbox, and the only live Flutter device
is Chrome. M1 can be built and test-verified entirely headless; visual
verification needs Chrome or the user's phone.

## State verified before measuring

- Repo `/var/home/dhemas/Development/Projects/_temp/residuum, branch `main,
  4 commits, tracked files: `CLAUDE.md, `.gitignore, the design spec. No code.
- No fvm pinning (`.fvmrc` absent).

## Measurements (all fresh this session)

- Flutter 3.47.0 stable, Dart 3.13.0 (`flutter --version, `dart --version`).
- `dart create -t package` + `dart test` in scratchpad: works, pub.dev
  reachable, tests pass (probe ran end to end).
- `flutter doctor`: Android SDK 36.1.0 ✓, Chrome ✓, Linux desktop toolchain ✗.
- `flutter devices`: Chrome only. `flutter emulators`: none defined.

## Inherited gates

None — first story of the epic.

## Findings that change the spec

- No Linux desktop target: the app package must not assume a desktop run;
  Chrome is the automated-adjacent visual target.
- No emulator: manual on-phone verification is the user's step, after handoff.

## Proposed shape of the work

One unit, branch `m1-crawl, one build session. Core → content → app ordering
inside the unit; the build session writes its own task plan from the spec.

## Hazards to carry into the spec

- First `flutter create` in the repo generates platform folders; keep scope to
  what M1 needs (android + web is enough).
- An Android gradle build downloads gigabytes on first run — not needed for M1
  verification; `flutter test` + Chrome run suffices.

## What this recon did NOT check

- `flutter create` + `flutter test` inside a *Flutter* (not pure Dart) package
  in this sandbox — probed dart-only.
- An actual Android build/deploy.
- Physical device connectivity (no phone attached during recon).
