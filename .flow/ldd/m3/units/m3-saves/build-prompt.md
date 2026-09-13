# Build prompt — unit `m3-saves` (story M3S "Saves")

You are the build session for M3S. You write the code; the architect session
("[arch] residuum-rpg") decides, verifies, and merges via PR.

## 1. Worktree

`/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-saves`
on branch `m3-saves, base `0656eb1`. **Already created — do NOT create it.**

## 2. Working directory — first command, no exceptions

```
cd /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-saves && pwd
```

Confirm the output before anything else. The parent repository must never
receive a commit from you. `git rev-parse --show-toplevel` must print the
worktree path.

## 3. The spec

Read in full before planning:

- Spec: `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-saves-spec-M3S.md`
- Recon (background): `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-saves-recon.md`
- Game design spec (canonical, section 13 on saves): `docs/superpowers/specs/2026-08-20-dungeon-game-design.md`
- Code conventions (binding): `CLAUDE.md` at the repo root.

`docs/epic/` is gitignored — **never commit anything under it**; cite its
files by absolute path.

## 4. The work, in one paragraph

Closing the app stops losing the game: one versioned JSON save document
(profile always, run block while a crawl is suspended), a content-owned
codec that encodes items as registry references and 64-bit values as
strings, app-side storage with two-slot rotation and atomic verify-then-
rotate writes, autosave on every settled state change (cadence measured on
device, named fallback if it janks), boot-time load with corrupt fallback
and a visible report, resume straight into a suspended crawl roll-for-roll,
a rolled world seed for a fresh hero, and a guarded abandon-hero door.
Measurable: force-stop mid-fight on the AVD, relaunch, the same fight
continues on the same rolls; survivability exactly 24/40, untouched.

## 5. Be adversarial about the spec

Disagreeing in the open is expected behavior, not a nuisance. Every prior
unit corrected the architect at least once. Claims most worth attacking:

- **The field enumeration.** The spec's save-document field list was
  written from reading `game_state.dart` once. Diff it against the
  constructor and every `copyWith` site yourself; a field the codec misses
  is a silent data loss the round-trip tests must be built to catch, not
  assume away.
- **The "suspend theorem" test as specced** assumes replaying actions on a
  decoded state is possible with content-built states in content's test
  package. If the seams fight you, argue the alternative — but stream
  divergence after resume is the one defect this unit exists to prevent,
  so some end-to-end form of that test is non-negotiable.
- **C1's shape.** Boot logic lives in `main.dart` today and may not be
  pinnable at bloc level; if you have to restructure to make boot testable,
  pre-declare the shape.
- **The autosave cadence.** "Every settled state change" is the spec's
  default, not a measurement. Measure at depth 4–5 with full floor
  memories and report the numbers; the named fallback is in the spec, and
  anything else needs pre-declaration.
- **The abandon-hero door is a flagged scope addition** — if it balloons,
  say so instead of gold-plating it. It is one confirmed action and a
  fresh boot.
- **Pre-declare shape deviations before writing code** (house pattern):
  file layout, value-object shapes, any getter you need that core does not
  expose (do NOT quietly edit core — that is a pre-declared deviation or
  it does not happen).

## 6. Method

- Characterization first (C1 per the spec, run and recorded at base).
- Then strict TDD (red → green → refactor). Test bodies as
  `// arrange` / `// act` / `// assert`. No mocks in core or content; the
  app's storage logic is split pure-over-injected-operations precisely so
  it tests without mocks or real files. Every commit's exit state is green
  across all three packages.
- Conventional commits.
- No body comments; dartdoc only on public API, carrying the spec's
  "behaviour arguments that must land in documentation" — all five.

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
  BUILD-REPORT.md is the working fallback and the user will relay.
- A physical device may be attached alongside the AVD: pin every adb and
  flutter command to the emulator serial (`-s emulator-5554` or
  `-d emulator-5554`); never install to or touch the phone.
- NOTE: the Bash sandbox is currently DISABLED machine-wide (user trial).
  The sandbox-shaped traps above are dormant; they stay listed because
  re-enabling is one boolean.

## 8. Mutation table

Run every row of the spec's table (rows 1–9 including the control) and
report the WHOLE table — greens included — naming which tests each mutation
reddened. Honor the spec's sequencing traps (C1 deleted-with-argument in
the boot commit; row 6 needs a >2^53 test value or the row cannot fail).
Extend the table if you find a hazard it misses; extensions have caught
real defects in three prior units.

## 9. What you must NOT do

- No pushing, no pull requests, no merging, no external trackers. The
  architect pushes and opens the PR on the user's approval.
- No commits under `docs/epic/`.
- **Do not touch core** (`packages/core`) — any needed getter is a
  pre-declared deviation first.
- **Forbidden levers**: bestiary values, hero base stats, drop/spawn
  tables, prices, xp curve. Content gains ONLY the save feature and the
  registry lookups. Survivability must print exactly 24/40.
- No unseeded randomness outside the single boot-time world-seed roll in
  the app; no DateTime or dart:io in content.
- Never install anything on the physical phone (trap above).
- The codec never silently repairs a bad document.

## 10. Verification block — every item evidenced, not asserted

1. `git rev-parse --show-toplevel` and `git log --oneline main..HEAD`.
2. All three suites: per-package counts against the baseline (395/95/129 =
   619, measured fresh by the architect 2026-08-21 at `0656eb1` —
   re-measure yourself before your first commit and say so).
3. C1 quoted at base, and the argument for its deletion in the boot commit.
4. The full mutation table, both halves, with test names.
5. Survivability output: exactly 24/40, stalled 0.
6. The autosave cadence measurement (encode+write time at depth 4–5, on
   the AVD) and the cadence shipped, with the fallback argument if used.
7. `flutter analyze, `dart format --set-exit-if-changed ., `git diff main --stat -- packages/core` (must be EMPTY), and the
   content diff showing only save/ + registry lookups.
8. Hygiene greps: no body comments; `grep -rn "dart:io\|DateTime" packages/content/lib` empty; unseeded-randomness sweep with the one sanctioned
   boot-roll site quoted.
9. AVD acceptance evidence, screenshot-paired where the spec says so:
   kill-mid-fight resume; corrupt-file fallback with visible notice;
   both-corrupt fresh hero; death-overlay resume; abandon-hero confirm;
   fresh install rolls a non-1 seed.
10. **What the tests cannot prove**, stated plainly.
11. **Every spec claim you checked and found wrong**, with the source.
12. **Which execution phases ran, and why any named phase was skipped.**

Mirror this block to `BUILD-REPORT.md` in the worktree root (commit it —
it lives in the worktree, not under `docs/epic/`).

## 11. Delegation

This is the epic's largest unit so far: write a plan first with the
`writing-plans` skill, then execute test-first with
`test-driven-development`. Inline execution with the mutation table
carrying the adversarial load is the accepted precedent (ledger D9);
per-task reviewer subagents may be skipped, but argue the skip in your
report. Any subagent you dispatch must `cd` into the worktree and prove it
with `pwd`.

## 12. Reporting back

🔴 Printing is not replying. To reach the architect, use the SendMessage
tool addressed to the sender of your kickoff message ("[arch]
residuum-rpg"). Message when: a spec claim looks wrong, a needed core
getter is missing, the cadence measurement forces the fallback, or you are
blocked on a decision the spec does not cover. Otherwise decide, proceed,
and report at the end with the verification block. If your message is held,
BUILD-REPORT.md is the channel and the user will relay.
