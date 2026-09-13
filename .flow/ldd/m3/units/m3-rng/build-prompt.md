# Build prompt — unit `m3-rng` (story M3R "A generator that can be saved")

You are the build session for M3R. You write the code; the architect session
("[arch] residuum-rpg") decides, verifies, and merges via PR.

## 1. Worktree

`/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-rng`
on branch `m3-rng, base `472e62b`. **Already created — do NOT create it.**

## 2. Working directory — first command, no exceptions

```
cd /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-rng && pwd
```

Confirm the output before anything else. The parent repository at
`/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg` must never
receive a commit from you. `git rev-parse --show-toplevel` must print the
worktree path.

## 3. The spec

Read in full before planning:

- Spec: `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-rng-spec-M3R.md`
- Recon (background): `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-rng-recon.md`
- Code conventions (binding): `CLAUDE.md` at the repo root.

`docs/epic/` is gitignored — **never commit anything under it**; cite its
files by absolute path.

## 4. The work, in one paragraph

Replace `Rng`'s `dart:math.Random` core with a splitmix64-class generator
whose whole state is one exportable int (`state` / `Rng.fromState`), keeping
the constructor, `rollRange`'s inclusive semantics, and the ArgumentError
exactly as they are. Every seeded artifact re-rolls once: re-pin the
seeded-outcome tests honestly, keep the determinism double-run tests
unchanged and green, and record the new survivability rate inside the 50–95%
band — that number becomes the epic's exact baseline, replacing 25/40.

## 5. Be adversarial about the spec

Disagreeing in the open is expected behavior, not a nuisance. Every prior
unit found at least one real architect error. Claims most worth attacking:

- **The recon's claim that only seeded-outcome literals re-roll.** Fixtures
  or bloc tests may pin rolls transitively. Enumerate the breakage by
  running the suites at the first red commit, not by trusting the recon's
  file list.
- **The band-will-probably-hold assumption.** If survivability falls
  outside 50–95%, STOP and message the architect with the histogram before
  touching any lever. Content tables are the only levers, and tuning ships
  with a before/after trail.
- **Mutation row 3's control is declared unknown on purpose** — report what
  actually happens to the golden stream, both halves.
- **Pre-declare shape deviations before writing code** (house pattern): a
  different generator within the splitmix64 class, an extra named
  constructor, anything the spec's API contract does not name — message the
  architect first.

## 6. Method

- Characterization first: run the determinism double-run tests at base and
  quote the output (spec C1). They must pass before AND after — they are
  the cross-generator contract.
- Then strict TDD (red → green → refactor). Test bodies as
  `// arrange` / `// act` / `// assert`. No mocks. Every commit's exit
  state is green across all three packages.
- Conventional commits.
- No body comments; dartdoc only on public API, carrying the spec's
  documentation arguments (why hand-rolled, the bias argument, the VM/AOT
  64-bit constraint).

## 7. Environment traps (verbatim from the ledger)

- Sandbox: `git -C <repo> <cmd>` does NOT match the sandbox exclusion patterns —
  always write git as `cd <repo> && git <cmd>`.
- `find` inside the Bash tool is bfs 4.1.1, not GNU findutils: `-newermt` takes
  ISO 8601 only; relative strings like `'15 minutes ago'` error (and read as
  empty with stderr suppressed). GNU find is at `/usr/bin/find`.
- Subagents dispatched into a git worktree do not inherit cwd — force an
  explicit `cd <worktree> && pwd` first or they commit in the parent repo.
- No fvm in this repo: plain `flutter` / `dart` (system Flutter 3.47.0).
- The ledger directory `docs/epic/` is gitignored — build sessions must never
  commit anything under `docs/epic/` and cite its files by absolute path.
- Commits use the personal persona:.
- Device nodes are hidden inside sandboxed Bash: `/dev/kvm` reads as missing
  while it exists on the host — hardware probes lie under sandbox. Emulator,
  adb, and `flutter run` need unsandboxed commands (permission prompt; a
  `--bg` session stalls on it silently).
- AVD `Pixel_10` exists (`emulator -list-avds`); `flutter emulators` and
  `flutter emulators --create` mishandle the installed ps16k system images —
  use the `emulator` binary directly.
- UPDATE 2026-08-20 (D8): `emulator, `adb, and device-facing `flutter`
  subcommands (`run`/`devices`/`emulators`/`install`/`attach`/`logs`/`drive`)
  are now sandbox-excluded — no prompt. Other hardware probes still lie.
- `git worktree add`/`remove` and deleting a worktree's `.claude` files fail
  under sandbox (EROFS on `.git/worktrees/, "busy" on protected config
  paths) — run worktree lifecycle commands unsandboxed.
- Cross-session message holds bite BOTH directions: an INTERACTIVE session
  holds incoming messages behind an approval gate that expires. If your
  reply to the architect is not acknowledged, assume it was held —
  BUILD-REPORT.md is the working fallback.
- NOTE: the Bash sandbox is currently DISABLED machine-wide (user trial).
  The sandbox-shaped traps above are dormant; they stay listed because
  re-enabling is one boolean.

## 8. Mutation table

Run every row of the spec's table (rows 1–5 including the control) and
report the WHOLE table — greens included — naming which tests each mutation
reddened. Extend it if you find a hazard it misses; extensions have caught
real defects in two prior units.

## 9. What you must NOT do

- No pushing, no pull requests, no merging, no external trackers. The
  architect pushes and opens the PR on the user's approval.
- No commits under `docs/epic/`.
- **Forbidden levers**: bestiary hp/attack/speed/pierce, hero base stats.
  Content tables are free ONLY if the survivability band fails, only after
  messaging the architect, and only with a before/after trail.
- No test deleted or loosened to dodge a re-pin. The band assertion
  (50–95%, stalled 0) stays byte-identical.
- No new dependencies anywhere; no `dart:math` left in `rng.dart`.

## 10. Verification block — every item evidenced, not asserted

1. `git rev-parse --show-toplevel` and `git log --oneline main..HEAD`.
2. All three suites: per-package counts against the baseline (389/95/129 =
   613, measured fresh by the architect 2026-08-21 at `472e62b` —
   re-measure yourself before your first commit and say so).
3. C1 quoted at base (determinism tests green against unmodified code) and
   again at HEAD, unchanged.
4. The full mutation table, both halves, with test names — including what
   actually happened on row 3's control.
5. Survivability output: the new X/40 line + died-at histogram; band green.
6. The full list of re-pinned tests, each with old → new literal.
7. `flutter analyze, `dart format --set-exit-if-changed ., and
   `git diff main --stat -- packages/content` (empty, or the approved
   trail).
8. Hygiene greps: no body comments, no unseeded `Random(, and
   `grep dart:math packages/core/lib/src/engine/rng.dart` empty.
9. AVD smoke run: enter dungeon, one fight, one descent; note anything odd.
10. **What the tests cannot prove**, stated plainly (at minimum: the
    statistical quality of the generator beyond the pinned properties).
11. **Every spec claim you checked and found wrong**, with the source.
12. **Which execution phases ran, and why any named phase was skipped.**

Mirror this block to `BUILD-REPORT.md` in the worktree root (commit that
file — it lives in the worktree, not under `docs/epic/`).

## 11. Delegation

Real logic: write a plan first with the `writing-plans` skill, then execute
test-first with `test-driven-development`. Inline execution with the
mutation table carrying the adversarial load is the accepted precedent
(ledger D9); per-task reviewer subagents may be skipped, but argue the skip
in your report. Any subagent you dispatch must `cd` into the worktree and
prove it with `pwd`.

## 12. Reporting back

🔴 Printing is not replying. To reach the architect, use the SendMessage
tool addressed to the sender of your kickoff message ("[arch]
residuum-rpg"). Message when: a spec claim looks wrong, the band fails, or
you are blocked on a decision the spec does not cover. Otherwise decide,
proceed, and report at the end with the verification block. If messaging is
held, BUILD-REPORT.md is the channel and the user will relay.
