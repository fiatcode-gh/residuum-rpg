# Build prompt — unit `m1-crawl` — story M1 "The Crawl"

## 1. Worktree

`/var/home/dhemas/Development/Projects/_temp/residuum/.worktrees/m1-crawl,
branch `m1-crawl` — **already created — do NOT create it.**

## 2. Working directory — first command, before anything else

```
cd /var/home/dhemas/Development/Projects/_temp/residuum/.worktrees/m1-crawl && pwd
```

Confirm the output is exactly that path. Your shell does not reliably inherit
it, and the parent checkout `/var/home/dhemas/Development/Projects/_temp/residuum`
(branch `main`) is the worktree's grandparent directory — a commit landing
there is a real failure mode.
Do not touch the parent checkout. Prefer `cd <worktree> && git <cmd>` for every
git invocation (see traps: `git -C` breaks the sandbox exclusion).

## 3. The documents

Read all three in full, in this order, before writing anything:

1. Story spec (your contract):
   `/var/home/dhemas/Development/Projects/_temp/residuum/docs/epic/m1-crawl-spec-M1.md`
2. Game design spec (context; M1 scope is only what the story spec says):
   `/var/home/dhemas/Development/Projects/_temp/residuum/docs/superpowers/specs/2026-08-20-dungeon-game-design.md`
   — also readable inside your worktree at `docs/superpowers/specs/`.
3. Code conventions (binding): `CLAUDE.md` at the worktree root.

Background, read only if a spec claim looks wrong:
`/var/home/dhemas/Development/Projects/_temp/residuum/docs/epic/RECON-2026-08-20.md`

**Never commit anything under any `docs/epic/` path.** It is the architect's
gitignored ledger.

## 4. The work

From an empty repository, build Milestone 1: a three-package Flutter monorepo
(`packages/core, `packages/content, `packages/app`) delivering a playable
turn-based crawl on one hardcoded floor — colored glyphs, fog of war,
tap-adjacent to move, bump to attack, three ghouls that chase and claw, HP,
death, restart. Measurable effect: all `dart test` / `flutter test` suites
green, analyze and format clean, and a human can play a full
live-die-restart loop via `flutter run -d chrome`.

## 5. Be adversarial about the spec

Disagreeing in the open is expected behaviour, not a nuisance. The claims most
worth attacking:

- The greedy monster chase rule (step 3 of the `step` contract): check it
  cannot oscillate or walk a monster onto another monster; if the tie-break
  "prefer x axis" produces visibly dumb chasing on the real floor, say so.
- The FOV contract: "walls bordering a visible floor tile are visible" — if
  your shadowcasting implementation makes this rule awkward, propose the
  variant you can implement cleanly rather than forcing it.
- The claim that `bloc_test`-level tests suffice for tap mapping — if the
  tap-coordinate→Position mapping in `glyph_grid.dart` turns out to hold real
  logic, extract it into a plain testable function and test it; do not leave
  logic untested because it lives near a widget.
- The hero stat line (20 hp, attack 3–5 vs three ghouls 10 hp, attack 2–4):
  if that is unwinnable or trivial in play, tune the numbers and report the
  change — the spec's numbers are first guesses, not sacred.

If a spec claim is wrong, message the architect (section 9) — do not silently
work around it.

## 6. Method

- **Characterization tests: none** — empty repository; the spec says so
  explicitly. Do not hunt for them.
- This is well past thirty lines and full of real logic. **Required phases, in
  order:** invoke `superpowers:writing-plans` to write the implementation plan
  from the story spec, then execute it with
  `superpowers:subagent-driven-development` (fallback:
  `superpowers:executing-plans` inline), with strict
  `superpowers:test-driven-development` red-green-refactor per task.
- Per task, run both reviews — spec compliance, then code quality — before
  moving on. Trivial one-or-two-line tasks may be bundled, per the global
  workflow rules.
- Build order: core → content → app (the dependency rule makes anything else
  unbuildable).
- **Every commit's exit state is green.** No reviewable unit is left red.
  Conventional commits.
- Close with `superpowers:verification-before-completion`: run the commands,
  quote the output, then claim.

## 7. Environment traps (verbatim from the ledger)

- Sandbox: `git -C <repo> <cmd>` does NOT match the sandbox exclusion patterns —
  always write git as `cd <repo> && git <cmd>`.
- `find` inside the Bash tool is bfs 4.1.1, not GNU findutils: `-newermt` takes
  ISO 8601 only; relative strings like `'15 minutes ago'` error (and read as
  empty with stderr suppressed). GNU find is at `/usr/bin/find`.
- Subagents dispatched into a git worktree do not inherit cwd — force an
  explicit `cd <worktree> && pwd` first or they commit in the parent repo.
- No fvm in this repo: plain `flutter` / `dart` (system Flutter 3.47.0).
- The ledger directory `docs/epic/` is gitignored — never commit anything under
  `docs/epic/`; cite its files by absolute path.
- Commits use the personal persona:.
- Device nodes are hidden inside sandboxed Bash: `/dev/kvm` reads as missing
  while it exists on the host — hardware probes lie under sandbox. Emulator,
  adb, and `flutter run` need unsandboxed commands (permission prompt).
- AVD `Pixel_10` exists (`emulator -list-avds`); `flutter emulators` and
  `flutter emulators --create` mishandle the installed ps16k system images —
  use the `emulator` binary directly.
- No Linux desktop toolchain. Visual verification target is the Android
  emulator: ask the user (via SendMessage to the architect) to launch
  `Pixel_10` when you reach that step, then `flutter run -d <device-id from
  adb devices>` unsandboxed. The first gradle build downloads dependencies —
  allow several minutes and do not treat the wait as a hang.
- `flutter create` should use `--platforms=android,web --project-name residuum_app`.

## 8. Mutation table — run every row at the end, report the whole table

Run against the finished implementation, one mutation at a time, reverting
each before the next. Report greens as well as reds, naming which tests each
mutation reddened.

| # | Mutation (revert after checking) | Expected to fail | Expected to stay green (control) |
|---|---|---|---|
| 1 | `Tile.wall` made walkable | floor-map walkability, step blocked-move test | position, rng tests |
| 2 | monster phase deleted from `step` | chase + monster-attack + hero-death tests | hero move/bump tests |
| 3 | damage hardcoded to 0 | bump-attack, monster-attack, death tests | movement, fov, floor tests |
| 4 | `computeFov` returns all positions | occlusion + radius tests | step movement tests |
| 5 | bloc ignores `TileTapped` entirely | adjacent-tap bloc test | non-adjacent-tap test |

Sequencing trap (from the spec): mutation 2 only makes sense once the monster
phase exists — run the table after the build, never mid-build.

## 9. Communication

Message the architect session — the sender of the message that pointed you
here — using the SendMessage tool, when:

- a spec claim looks wrong,
- you are blocked on a decision the spec does not cover,
- you are done (send the verification block).

🔴 **Printing is not replying.** Your ordinary output is invisible to other
sessions; an answer composed in your own transcript reaches nobody. Use
SendMessage, addressed to the architect session ("[arch] residuum"), every
time. Otherwise: decide, proceed, and report at the end.

## 10. You must NOT

- Push to any remote, open a pull request, request a reviewer, or merge.
- Touch the parent checkout at `.../residuum, its `main` branch, or any
  `docs/epic/` directory.
- Commit generated Android/iOS/web scaffolding beyond what `flutter create
  --platforms=android,web` produces and the app needs.
- Add dependencies beyond: `flutter_bloc` (app), `bloc_test` + `flutter_test`
  (app dev), `test` (core/content dev). Anything else needs an architect
  message first.
- Write body comments (conventions: dartdoc on public API only).
- Attempt an Android/gradle build.

## 11. Verification block — every item evidenced, not asserted

Send this back via SendMessage, each item with the command output that proves
it:

1. `cd <worktree> && pwd` output, and `git log --oneline main..m1-crawl | head`
   proving commits are on `m1-crawl, not `main` (also quote
   `cd <worktree> && git branch --show-current`).
2. Test counts from `dart test` in `core` and `content` and `flutter test` in
   `app, quoted. Baseline is **zero tests, measured fresh this epoch** (empty
   repo) — so every passing test is new.
3. `flutter analyze` output for all three packages (zero errors, zero
   warnings) and `dart format --set-exit-if-changed .` exit status.
4. The full mutation table with observed results, greens included.
5. Confirmation a human-playable run happened on the Android emulator
   (`Pixel_10`): quote `adb devices` output, and state what you observed —
   floor rendered, fog of war revealing, a ghoul killed, hero died, restart
   worked. (You cannot prove feel — state what you observed.)
6. **What the tests cannot prove**, stated plainly — at minimum: visual
   rendering correctness, touch ergonomics, fun.
7. **Every spec claim you checked and found wrong**, with the source — or
   "none".
8. **Which execution phases ran** (plan → subagent execution → per-task
   reviews → TDD → mutation table → verification) **and why any named phase
   was skipped.** A skip must be an argument, not an absence.
