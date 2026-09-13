# Build prompt — unit `m2-qol` (story M2Q "Quality of life")

You are the build session for M2Q. You write the code; the architect session
("[arch] residuum-rpg") decides, verifies, and merges. Everything you need is
in this file and the files it names.

## 1. Worktree

`/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m2-qol`
on branch `m2-qol, base `8596adb`. **Already created — do NOT create it.**

## 2. Working directory — first command, no exceptions

Your shell does not reliably start where you think. Run, and confirm the
output of:

```
cd /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m2-qol && pwd
```

before anything else. The parent repository at
`/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg` must never
receive a commit from you. There are no sibling worktrees. When in doubt, `git rev-parse --show-toplevel` must print the worktree path, not the parent.

## 3. The spec

Read in full before planning:

- Spec: `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m2-qol-spec-M2Q.md`
- Recon (background; read if a spec claim looks wrong):
  `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m2-qol-recon.md`
- Game design spec (canonical): `docs/superpowers/specs/2026-08-20-dungeon-game-design.md`
- Code conventions (binding): `CLAUDE.md` at the repo root.

These docs live under `docs/epic/, which is gitignored. **Never commit
anything under `docs/epic/`.** Cite them by absolute path.

## 4. The work, in one paragraph

Make the crawl comfortable on a phone without changing any rule: a
camera-follow viewport with a fixed ~36dp cell (free pan, snap-back on the
next hero action), item stats/grouping/stacking/worn-comparison in the pack,
an Engaged indicator plus a log line when a walk is refused because something
watches, wear/take-off in town (two new pure Profile transactions reusing the
dungeon's extracted equip rule), and a potion count on the quick-drink
button. Measurable: the five D19 items visible in play, and the survivability
run still exactly 25/40.

## 5. Be adversarial about the spec

Disagreeing in the open is expected behavior, not a nuisance. Every prior
unit found at least one real architect error. Claims most worth attacking:

- **The "exactly 25/40" claim.** It assumes the step-refactor is perfectly
  behavior-preserving and that nothing else feeds the seeded runs. If your
  extraction is faithful and the number still moves, the spec is wrong about
  what feeds the simulation — stop and message the architect.
- **The camera clamp contract.** The per-axis rules (fitting axis centers
  and ignores pan; overflowing axis centers focus, then clamps) may have
  edge cases the architect did not enumerate (a map exactly one cell larger
  than the viewport; pan at a corner). If the contract under-determines a
  case, decide, test it, and report the decision.
- **The preserved cap-overflow quirk.** Verify it exists before pinning it
  (spec C2 describes it from reading, not from a run). If the dungeon
  actually refuses that equip, the recon is wrong — message the architect
  before writing the town mirror.
- **The shared-predicate contract** (`enemiesInSight` feeding both chip and
  refusal). If the refactor fights the bloc's structure, argue an
  alternative — but two copies of the expression is not an acceptable
  alternative.
- **Pre-declare shape deviations before writing code** (house pattern since
  M2L): if your file layout, value-object shape, or state-field placement
  differs from the spec's, message the architect the deviation and the
  reason first, then proceed on approval.

## 6. Method

- Characterization tests first (C1–C3 in the spec). They must pass against
  the UNMODIFIED code. If one fails, your model of current behavior is wrong
  — stop and report; do not work around it.
- Then strict TDD (red → green → refactor) per behavior, per repo
  conventions: `// arrange` / `// act` / `// assert, no mocks in core,
  BLoC-level tests only in app (pure geometry/presentation unit tests follow
  the existing `grid_geometry_test.dart` precedent).
- Every commit's exit state is green across all three packages. Conventional
  conventional commits.
- No body comments; dartdoc only on public API of core, carrying the
  spec's "behaviour arguments that must land in documentation".

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
- NOTE: the Bash sandbox is currently DISABLED machine-wide (user trial).
  The sandbox-shaped traps above are dormant; they stay listed because
  re-enabling is one boolean.

## 8. Mutation table

Run every row of the spec's mutation table (spec section "Mutation table",
rows 1–10 including the control row) and report the WHOLE table — greens
included — naming exactly which tests each mutation reddened. Honor the
spec's sequencing traps (S1: the C1 characterization runs against unmodified
code and is deleted, not weakened, when the refusal log lands). Extend the
table if you find a hazard it misses — extensions caught real defects in
M2T; that is the discipline working.

## 9. What you must NOT do

- No pushing, no pull requests, no reviewer requests, no merging, no
  external trackers. The architect handles every external write, on the
  user's approval, per round.
- No commits under `docs/epic/, ever.
- **Forbidden balance levers** (architect ruling required): bestiary
  hp/attack/speed/pierce, hero base stats, drop/spawn tables, prices, the
  xp curve. This unit should not touch `packages/content` at all.
- No pinch zoom, no recenter button, no changes to fog/glyph rendering
  rules, no new dependencies in core (`equatable` is the only accepted one).
- Do not "fix" the cap-overflow-on-displacement quirk — pin it (spec C2).

## 10. Verification block — every item evidenced, not asserted

Report each with the command output that proves it:

1. `git rev-parse --show-toplevel` and `git log --oneline main..HEAD` —
   work happened in the worktree, commits are on `m2-qol, none on `main`.
2. All three suites: final per-package counts against the stated baseline
   (352 core + 95 content + 67 app = 514, measured fresh by the architect
   on 2026-08-21 at `8596adb` — re-measure yourself before your first
   commit and say so).
3. Proof C1–C3 passed against unmodified code (run them at base, quote the
   output, before the first behavior change lands).
4. The full mutation table, both halves, with test names.
5. Survivability run output: the rate line — must read 25/40, stalled 0.
6. `flutter analyze` and `dart format --set-exit-if-changed .` output.
7. `cd <worktree> && git diff main --stat -- packages/content` — empty.
8. Hygiene: no body comments and no unseeded `Random()` in the diff (quote
   your grep commands and their empty output).
9. AVD playthrough per the spec's definition of done, with screenshots,
   including one greyscale check of each changed screen.
10. **What the tests cannot prove**, stated plainly (at minimum: on-device
    feel of the cell size, pan/tap gesture coexistence — these are why the
    playthrough exists).
11. **Every spec claim you checked and found wrong**, with the source.
12. **Which execution phases ran, and why any named phase was skipped.** A
    skip is an argument, not an absence.
13. The camera cell-size value you shipped, and why, if it is not 36.

Mirror this whole verification block to `BUILD-REPORT.md` in the worktree
root (do commit that file — it is inside the worktree, not under
`docs/epic/`). It is the fallback channel if messaging fails.

## 11. Delegation

This unit has real logic (camera math, equip extraction, transactions):
write a plan first with the `writing-plans` skill, then execute test-first
with the `test-driven-development` skill. Inline execution with the mutation
table carrying the adversarial load is the accepted precedent (ledger D9) —
per-task reviewer subagents may be skipped, but argue the skip in your
report. Do not spawn write-capable subagents into the parent repo; any
subagent you dispatch must `cd` into the worktree and prove it with `pwd`.

## 12. Reporting back

🔴 Printing is not replying. Your ordinary output reaches nobody. To reach
the architect, use the SendMessage tool addressed to the session that sent
you your kickoff message ("[arch] residuum-rpg" — reply to the sender).
Message the architect when: a spec claim looks wrong, an inherited gate is
not real, or you are blocked on a decision the spec does not cover
(pre-declared shape deviations included). Otherwise decide, proceed, and
report at the end with the verification block. If messaging fails, `BUILD-REPORT.md` is the channel.
