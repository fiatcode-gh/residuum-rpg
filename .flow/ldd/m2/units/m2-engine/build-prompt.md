# Build prompt — unit `m2-engine` — story M2E "Engine"

## 1. Worktree

`/var/home/dhemas/Development/Projects/_temp/residuum/.worktrees/m2-engine,
branch `m2-engine, based on `main` @ `be1da0a` —
**already created — do NOT create it.**

## 2. Working directory — first command, before anything else

```
cd /var/home/dhemas/Development/Projects/_temp/residuum/.worktrees/m2-engine && pwd
```

Confirm the output is exactly that path. Your shell does not reliably inherit
it, and the parent checkout `/var/home/dhemas/Development/Projects/_temp/residuum`
(branch `main`) is the worktree's grandparent directory — a commit landing
there is a real failure mode. Prefer `cd <worktree> && git <cmd>` for every
git invocation (see traps: `git -C` breaks the sandbox exclusion).

## 3. The documents

Read in full, in this order, before writing anything:

1. Story spec (your contract):
   `/var/home/dhemas/Development/Projects/_temp/residuum/docs/epic/m2-engine-spec-M2E.md`
2. The existing code: all of `packages/core` and `packages/content, plus
   `packages/app/lib/game/` — M1 is merged and this story extends it. It is
   small; read it, do not skim it.
3. Code conventions (binding): `CLAUDE.md` at the worktree root.
4. Game design spec (context; this unit's scope is only what the story spec
   says): `docs/superpowers/specs/2026-08-20-dungeon-game-design.md`
   (in the worktree).

**Never commit anything under any `docs/epic/` path.** It is the architect's
gitignored ledger.

## 4. The work

Replace M1's training wheels with the real engine: speed-clock turn
scheduling, flow-field monster chase (fixes a known freeze defect), seeded
5-floor dungeon generation with stairs and depth-scaled spawns from a 5-type
bestiary, and tap-to-auto-walk with interrupts. Measurable effect: suites
green (baseline 93 tests: 66 core + 10 content + 17 app, measured fresh
today), same-seed runs reproduce floor-for-floor, and a human can descend
floors 1→5 on the AVD.

## 5. Be adversarial about the spec

Disagreeing in the open is expected behaviour, not a nuisance. The claims most
worth attacking:

- **The energy-clock regression claim:** "speed 10 vs 10 reproduces M1's
  alternation exactly." Verify against the existing step tests before
  trusting it — if any M1 test encodes an ordering the clock cannot
  reproduce, stop and report which, rather than bending the clock.
- **The flow-field movement rule:** "strictly smallest neighbor, tie-break
  N/E/S/W, else stand still." Check it cannot oscillate two monsters through
  a 1-wide corridor and cannot deadlock a pack in a doorway; if it can,
  propose the amendment openly.
- **The generator size/count numbers** (~24x16 to ~32x20, spawn counts): if
  they produce cramped or empty floors in practice, tune and report — first
  guesses, not sacred.
- **The auto-walk interrupt list:** if an interrupt is missing that real play
  obviously needs (e.g. standing on stairs), say so rather than silently
  adding behaviour.
- **The bestiary stat lines:** tunable with a report, M1 precedent.

If a spec claim is wrong, message the architect (section 9) — do not silently
work around it.

## 6. Method

- **Characterization layer: the existing 93 tests.** They must pass against
  the unmodified code (run them first — if the baseline is not 93 green,
  stop and report). The spec names the expected casualties (alternation-shaped
  step tests, hardcoded-floor content tests); your plan must list exactly
  which existing tests you will modify and why, before you modify them.
- This is well past thirty lines with real logic. **Required phases, in
  order:** `superpowers:writing-plans` from the story spec, then
  `superpowers:subagent-driven-development` (fallback:
  `superpowers:executing-plans` inline), with strict
  `superpowers:test-driven-development` red-green-refactor per task.
- Per task, run both reviews — spec compliance, then code quality. Trivial
  one-or-two-line tasks may be bundled.
- **Every commit's exit state is green.** Conventional commits.
- Close with `superpowers:verification-before-completion`: run the commands,
  quote the output, then claim.

## 7. Environment traps (verbatim from the ledger, updated 2026-08-20)

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
- `emulator, `adb, and device-facing `flutter` subcommands
  (`run`/`devices`/`emulators`/`install`/`attach`/`logs`/`drive`) are
  sandbox-excluded and run without prompting. `flutter test`/`analyze`/`build`
  and `dart format` stay sandboxed. Any OTHER hardware probe still lies under
  sandbox (`/dev` is masked) — re-run it via the excluded commands before
  concluding hardware is absent.
- AVD `Pixel_10` exists (`emulator -list-avds`); `flutter emulators` mishandles
  the installed ps16k system images — use the `emulator` binary directly. The
  first gradle build downloads dependencies — allow several minutes and do not
  treat the wait as a hang.

## 8. Mutation table — run every row at the end, report the whole table

One mutation at a time, reverting each. Report greens as well as reds, naming
which tests each mutation reddened.

| # | Mutation (revert after checking) | Expected to fail | Expected to stay green (control) |
|---|---|---|---|
| 1 | flow field: allow equal (not strictly smaller) neighbor | corner-rounding / no-oscillation tests | energy scheduling tests |
| 2 | energy: hero tie-break dropped (monsters act first on ties) | hero-first tie test | flow field tests |
| 3 | generator: skip the connectivity flood-fill validation | connectivity/golden tests on the failing-seed path — name which test reddened | findPath tests |
| 4 | generator: emit stairsDown on depth 5 | depth-5-has-no-stairs test | descend hp-persistence test |
| 5 | auto-walk: ignore the monster-became-visible interrupt | that interrupt's bloc test | adjacent-tap and other interrupt tests |

## 9. Communication

Message the architect session — "[arch] residuum", the sender of the message
that pointed you here — using the SendMessage tool, when:

- a spec claim looks wrong,
- you are blocked on a decision the spec does not cover,
- you are done (send the verification block).

🔴 **Printing is not replying.** Your ordinary output is invisible to other
sessions; use SendMessage every time. Known issue: a previous build session's
messages to the architect were held and never delivered — if you get no
acknowledgment within your session, ALSO write your verification block to
`/var/home/dhemas/Development/Projects/_temp/residuum/.worktrees/m2-engine/BUILD-REPORT.md`
(uncommitted) so the architect can read it from disk.

## 10. You must NOT

- Push to any remote, open a pull request, request a reviewer, or merge.
- Touch the parent checkout, its `main` branch, or any `docs/epic/` directory.
- Add any dependency beyond what `main` already has (flutter_bloc, equatable,
  bloc_test, flutter_test, test). Anything else needs an architect message
  first.
- Build loot, items, skills, town, or death-penalty behaviour — those are the
  next two units. Resist the adjacent feature.
- Write body comments (dartdoc on public API only).

## 11. Verification block — every item evidenced, not asserted

Send via SendMessage (and mirror to `BUILD-REPORT.md` per section 9), each
item with the command output that proves it:

1. `cd <worktree> && pwd, `git branch --show-current, and
   `git log --oneline main..m2-engine | head -20`; `git status --porcelain`
   clean.
2. Baseline check: the 93 pre-existing tests ran green on the unmodified
   worktree BEFORE your first change (quote the three suite tails).
3. Final test counts from all three suites, quoted, with a list of every
   pre-existing test you modified or deleted and the reason for each.
4. `flutter analyze` output for all three packages and
   `dart format --set-exit-if-changed .` exit status.
5. The full mutation table with observed results, greens included.
6. Determinism evidence: the golden-seed test output, and the
   layout-independent-of-combat-rolls test.
7. AVD playthrough on `Pixel_10` (quote `adb devices`): descended 1→5, a
   dire wolf double-moved, a monster rounded a corner, auto-walk crossed a
   room and stopped when a monster appeared, HP read "0 / 20" at death.
   State what you observed; you cannot prove feel.
8. **What the tests cannot prove**, stated plainly.
9. **Every spec claim you checked and found wrong**, with the source — or
   "none".
10. **Which execution phases ran** (plan → subagent execution → per-task
    reviews → TDD → mutation table → verification) **and why any named phase
    was skipped** — a skip is an argument, not an absence.
