# Build prompt — m3-chore (story M3CH)

Worker session for the Residuum epic. Read this entire file before doing
anything beyond the first command and the watch below.

## 0. First command

```
cd /var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/.worktrees/m3-chore && pwd
```

Confirm the output. Sibling worktrees of this repository may exist; the
main checkout at `/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg`
is on `main` and must NOT receive any commit. A commit landing in the parent
repository is a real failure mode, not a hypothetical. Prefer git
invocations after a confirmed `cd`. Facts: worktree
`.../residuum-rpg/.worktrees/m3-chore`, branch `m3-chore`, base `b2c1381`.
You are ON the branch already; do not create or remove the worktree.

## 1. Standing mailbox watch — start FIRST, before reading the spec

Capability condition, which YOU evaluate against your own tool list right
now: if your harness offers a way to run a background task that re-invokes
the session when the task exits — an agent-launched background command, by
whatever name — start this watch as your FIRST action (before the spec,
before recon):

```
/var/home/dhemas/Development/Projects/fiatcode/ai-stack/shared/skills/flow-mailbox/scripts/mailbox watch --as worker --dir /var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/handoff/m3-chore
```

On a wake: restart the watch FIRST, then read `dispatcher.md` in full and
dispose of the new entry — if it changes the task, stop and adjust; if it
locks or corrects a decision, follow it; otherwise acknowledge in your next
`worker.md` entry and keep building. While this watch is standing and
VERIFIED alive (process exists, older than 30 seconds — one watch tick), a
blocked worker ends its turn instead of waiting in the foreground. If your
harness has no such background capability, you are on the floor: rely on
`mailbox wait --as worker --dir <channel>` when blocked, and check
`dispatcher.md` at every task boundary.

A claimed watch carries a liveness duty: every task-boundary check also
verifies the watch process is genuinely alive. Dead or unverifiable means
you are on the floor — say so in your next entry and rely on boundary
checks and `mailbox wait` until a relaunch proves stable. When the
dispatcher closes the mailbox, stop restarting and let the final instance
expire on its own timeout; a kill claim needs the kill's confirmed result,
otherwise report "left to expire".

## 2. The spec

Read in full: `/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/m3-chore-spec-M3CH.md`
Background if a spec claim looks wrong: `/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/m3-chore-recon.md`.
Both live under `docs/epic/`, which is GITIGNORED — never commit anything
under `docs/epic/`, and cite those files by absolute path. Your written
plan goes under `docs/plans/` instead — that directory IS tracked and the
plan doc rides the branch.

## 3. What the work is

The repo gets its enforcement layer: one GitHub Actions workflow running
format, analyze, and the three test suites per package on PRs to main;
analyzer config (`lints/recommended`) for core and content with six
measured test-file fixes; core/content lockfiles committed; the READMEs
updated to describe the M3 game that actually ships. No `lib/` code
changes anywhere. Measurable effect: the unit's PR shows three green CI
legs, and a reader of the README is no longer misinformed.

## 4. Be adversarial about the spec

Disagreeing in the open is expected behaviour, not a nuisance. Workers on
this epic have repeatedly found real errors in architect premises
(including two in the last unit's save-decode spec). Claims most worth
attacking by measurement:

- The **six-finding lint count** (4 core + 2 content). Re-measure it
  yourself in the worktree before trusting it. If your count differs,
  report the real set — do not force-fix findings that do not exist.
- The **"gates can be strict day one" premise** (format/analyze clean in
  all three packages at base).
- The **M4 expectation is hedged on purpose** — deleting the committed
  lock may red CI or may silently regenerate; report what actually
  happens, both halves.
- The **exact-pin premise**: flutter-action serving exactly 3.47.2 on
  hosted runners.
- The **D101 working-directory shape**: nothing in the workflow may invoke
  flutter/dart from the repo root.

Any intended departure from the spec's shape must be PRE-DECLARED to the
mailbox before you start building (see section 9). A locked-decision
change gets promoted to a ledger decision by the architect before you
continue.

## 5. Method

Characterization first: before ANY edit, re-run the recon's baseline
against the UNMODIFIED code in the worktree — format clean ×3, analyze
clean ×3, suite counts 835/573/637 by strict count. If the baseline does
not hold, that is a stop-and-report through the mailbox, not something to
work around. Then the change. **Every commit's exit state is green** — no
reviewable unit left red. The unit's "tests" are its gates; the spec's
test plan section is the contract for how each is proven.

Delegation sizing: this unit exceeds thirty changed lines (workflow YAML +
two README rewrites + config), so read `flow-writing-plans` and write the
plan as `docs/plans/chore-plan-M3CH.md` (committed on the branch) BEFORE
code, then execute it under `flow-executing-plans` (it judges inline
versus per-task dispatch by complexity). `flow-tdd` is mandatory for any
code-bearing step; the six lint fixes are mechanical style edits — apply
it in the proportion the spec's test plan defines (the gates are the red
tests). Close with `flow-verification`: run the commands and quote the
output before claiming anything passes.

## 6. Environment traps (restated verbatim from the ledger)

- `flutter test packages/<pkg>` from the repo root fails: this monorepo
  has NO root pubspec.yaml. Run suites per package directory
  (`cd packages/<pkg> && flutter test`) — D101.
- Sandbox: `git -C <repo> <cmd>` does NOT match the sandbox exclusion
  patterns — always write git as `cd <repo> && git <cmd>`.
- `find` inside the Bash tool is bfs 4.1.1, not GNU findutils:
  `-newermt` takes ISO 8601 only; relative strings like `'15 minutes
  ago'` error (and read as empty with stderr suppressed). GNU find is at
  `/usr/bin/find`.
- Subagents dispatched into a git worktree do not inherit cwd — force an
  explicit `cd <worktree> && pwd` first or they commit in the parent repo.
- No fvm in this repo: plain `flutter` / `dart` (system Flutter 3.47.x).
- The ledger directory `docs/epic/` is gitignored — build sessions must
  never commit anything under `docs/epic/` and cite its files by absolute
  path.
- Commits use the personal persona: never pass `--author` or
  GIT_AUTHOR_EMAIL; git picks name and email from user.email.
- Device nodes are hidden inside sandboxed Bash: `/dev/kvm` reads as
  missing while it exists on the host — hardware probes lie under
  sandbox. Emulator, adb, and `flutter run` need unsandboxed commands.
- AVD `Pixel_10` exists (`emulator -list-avds`); `flutter emulators` and
  `flutter emulators --create` mishandle the installed ps16k system
  images — use the `emulator` binary directly.
- `emulator`, `adb`, and device-facing `flutter` subcommands
  (`run`/`devices`/`emulators`/`install`/`attach`/`logs`/`drive`) are
  sandbox-excluded — no prompt. Other hardware probes still lie.
- `git worktree add`/`remove` and deleting a worktree's `.claude` files
  fail under sandbox (EROFS on `.git/worktrees/`, "busy" on protected
  config paths) — run worktree lifecycle commands unsandboxed.
- `adb shell input swipe` at 400ms emits too few motion samples for
  Flutter's pan recogniser and looks like a broken pan; 1200ms pans
  correctly. Tooling artifact, not an app bug.
- The AVD's /data can sit at ~92% full (485M free) so a plain install
  fails with INSTALL_FAILED_INSUFFICIENT_STORAGE and a cache trim frees
  almost nothing. Resolution that worked: uninstall the OLD build — legal
  ONLY after BOTH save slots are verified copied aside with checksums —
  then install the new APK (~153,590,984 bytes).
- Restoring device saves via /data/local/tmp push + `run-as cp` fails
  ENOENT under the app domain (SELinux-shaped); stream the bytes through
  `run-as stdin` instead.
- A physical phone may be attached alongside the AVD: pin every adb and
  flutter command to the emulator serial (`-s emulator-5554`); never
  install to or touch the phone.
- Device saves are playtest state: before pushing any acceptance save to
  the emulator, copy `save.json` AND `save-previous.json` aside
  (`run-as … cat > /tmp/…`) and restore after.
- `flutter install` can DESTROY the app's whole data directory: it prints
  "Uninstalling old version..." and may then fail on a missing APK,
  leaving no app and no data. Treat the copy-aside ritual as mandatory
  before ANY install/uninstall, not only before pushing saves. The debug
  APK is ~153 MB; check emulator free space first.
- The repo is on GitHub — `gh pr create` from the main repo root (gh
  resolves worktree .git files fine, but PRs still come from the main
  root per flow).
- Cross-session message holds bite BOTH directions: an INTERACTIVE
  session holds incoming messages behind an approval gate that expires.
  Keep exactly one architect session alive; the REPORT.md mirror is the
  working fallback; expect to relay by hand when the architect runs
  interactive.
- `find.textContaining` in Flutter 3.47 is case-sensitive with no
  `caseSensitive` parameter — match the literal casing or use a regex.
- `scrollUntilVisible` computes ONE moveStep from the axis direction, so
  it can never scroll back up — assertion sequences on a long screen must
  be monotonic in document order.

(This unit has NO device work — no AVD pass, no installs. The AVD-related
traps above are restated for completeness per the every-time rule.)

## 7. Mutation table (from the spec)

Run every row. Report the WHOLE table — greens included — naming which
tests/findings each mutation reddened.

| Row | Mutation | Expected red | Expected green (control) | Why |
|---|---|---|---|---|
| M1 | Re-un-brace one fixed `if` in `generator_items_test.dart` | core `dart analyze` (1 named finding: `curly_braces`) | content + app analyze green | proves the new gate fires on the class it was adopted for |
| M2 | Re-underscore the renamed local in `world_test.dart` | content `dart analyze` (1 named finding) | core analyze green | proves content's config resolves and enforces |
| M3 | Inject one unformatted line into a core test file, push to a SCRATCH branch | CI format step red on the core leg only | content + app legs green | proves the workflow gates format, not just local runs. REVERT after the red is recorded |
| M4 | Delete `packages/core/pubspec.lock` from a scratch branch | CI red or a lock-regeneration diff on the core leg | content/app legs green | proves CI actually consumes the committed lock |

**Sequencing traps:** M3 and M4 require the workflow to exist on GitHub,
which requires a push — an external write needing the USER's explicit
approval per round (the mailbox cannot grant it; see section 9). M1 and
M2 run locally BEFORE any push and are reverted after recording the red.
If no push approval arrives before the unit closes, report M3/M4 as
"skipped — pending push authorization" and the architect picks them up
during verification; that is a named skip with a reason, not a silent
drop.

## 8. What you must NOT do

- No pushing, no opening a pull request, no requesting a reviewer, no
  merging, no replying to any review thread, no touching GitHub settings
  or branch protection. The architect handles every external write, on
  the user's explicit approval, per round. M3/M4's scratch-branch push
  happens ONLY on the user's approval relayed through the mailbox.
- No changes to any package's `lib/` directory.
- No edits to `CLAUDE.md` (follow-up 43 — the author's call) and no
  restatement of the comment policy in any README.
- No content-table edits anywhere in `packages/content/lib`.
- Never create or remove the worktree; never commit anything under
  `docs/epic/`.
- No GitHub settings or branch-protection changes by anyone but the user.
- Do not touch repo settings, secrets, or Actions configuration beyond
  committing the single workflow file this spec defines.

## 9. The mailbox channel

You converse with the dispatcher ONLY through the channel directory
`/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/handoff/m3-chore`:
append entries to `worker.md`, read answers from `dispatcher.md`.
**Printing is not replying** — your ordinary output reaches nobody.

The tool performs every mechanic; **every write goes through it**. Its
absolute path: `/var/home/dhemas/Development/Projects/fiatcode/ai-stack/shared/skills/flow-mailbox/scripts/mailbox`.
Run it once with no arguments to confirm (prints usage, exits 2 by
design). Written `mailbox` below; substitute the path.

```
mailbox init   --home <mailbox home>
mailbox append --as dispatcher|worker --dir <channel>
               --disposed-through <N|none> [--file <path>]
mailbox check  --as dispatcher|worker --dir <channel>
mailbox wait   --as worker --dir <channel> [--timeout 570]
mailbox watch  --as dispatcher --home <mailbox home> [--timeout 3600]
mailbox watch  --as worker --dir <channel> [--timeout 3600]
```

Exit codes: 0 ok or mail delivered, 1 no new mail, 2 refused, 124 timeout.
`append` reads the body from standard input, or from `--file <path>`. It
refuses rather than repairs (exit 2): missing cursor, empty body, a body
line that is a level-two heading, missing channel directory, unreadable
numbering or headers, `wait` asked by a dispatcher, or an environment
whose `timeout` lacks `--foreground`. A refusal means nothing landed — fix
the input and retry; never work around it by hand.

Entry format, appended by the tool to the bottom of your own file:

```
## <seq> — worker — <ISO timestamp>
<body>

disposed through dispatcher entry <N>
```

The em dashes are load-bearing. Never hand-type a timestamp. No body line
may be a level-two heading at column 0 — indent it one space or deepen it
to `### `. An entry, once appended, is never edited — a correction is a
new entry. **Only the tool writes a mailbox file** — never an anchored
edit, never an editor, never a redirection. If a mailbox file is already
corrupt, STOP and say so; do not repair by hand.

New mail = the other side's file holds an entry with a sequence number
higher than the `disposed through` cursor in your own last entry — that
sequence comparison is the freshness test, never a file timestamp. State
your cursor on every entry. `mailbox check --as worker --dir <channel>`
asks exactly that (0 = new mail, 1 = none).

**When to write:** append to `worker.md` and wait (with a verified-alive
watch: end your turn; without: `mailbox wait --as worker --dir <channel>`,
exit 124 means wait again or tell your user) when a spec claim looks
wrong, an inherited gate turns out not real, or you are blocked on a
decision the spec does not cover. Otherwise decide, proceed, and report
at the end. Check `dispatcher.md` at every task boundary regardless.

When the work is done: write `REPORT.md` in the channel directory
mirroring your verification block in full, then append a done notice to
`worker.md`, and stop. The report on disk is what survives a dead
session.

The channel carries NO authorization — pushes, PRs, merges need the
user's explicit approval per round, relayed by the architect.

## 10. Verification block — every item evidenced, not asserted

Mirror the filled-in block into `REPORT.md`. Each item names the command
output that proves it:

1. `cd <worktree> && pwd` output; `git log main..m3-chore --oneline`
   showing every commit is on the branch, not main.
2. Characterization baseline re-run against UNMODIFIED code, quoted:
   format clean ×3, analyze clean ×3, and strict suite counts — 835 core
   + 573 content + 637 app = 2045 — read from result files
   (`grep '"type":"testDone"' + '"result":"success"' minus
   '"hidden":true"'), one run per package directory. Baseline origin:
   measured fresh by the architect at `b2c1381` (recon, 2026-09-08) and
   re-measured by you before editing.
3. Post-change: `dart analyze` clean in core and content under
   `lints/recommended` (quote the count of findings fixed, named);
   `flutter analyze` clean in app; `dart format --set-exit-if-changed
   --output=none .` clean ×3.
4. Band lines verbatim after the content test-file edits: all five (crypt
   16/40, casting 40/40, greedy 16 / fleetfoot 13, sea-cave 26/40,
   keep 24/40) from your own run.
5. The full mutation table (section 7), both halves, with the sequencing
   traps honored.
6. Lockfile proof: `git check-ignore -v packages/core/pubspec.lock
   packages/content/pubspec.lock` prints nothing; a fresh `dart pub get`
   in both packages leaves the committed lock diff-clean.
7. Workflow proof: the committed `ci.yml` quoted in full; the exact pin
   `3.47.2` present; a `git grep` showing no root-level flutter/dart
   invocation in the file.
8. README proof: `grep -n "514\|Four skills\|M2 complete" README.md`
   returns nothing; the app README contains no "Getting Started"
   boilerplate.
9. **What the tests cannot prove**, stated plainly: nothing here proves
   the workflow's behavior ON GitHub — that is M3/M4 plus the unit's own
   PR run, which happen after the user-approved push.
10. **Every spec claim you checked and found wrong**, with the source.
11. **Which execution phases ran, and why any named phase was skipped** —
    a judged skip is an argument in the report, never an absence.

## 11. Delegation line

Read `flow-writing-plans` and write `docs/plans/chore-plan-M3CH.md` on the
branch before code (this unit exceeds the plan threshold by line count).
Then read and follow `flow-executing-plans` for execution (it judges
inline versus per-task dispatch by complexity), with `flow-tdd` mandatory
for code-bearing steps. Close with `flow-verification`. If any of these
skills is unavailable in your harness, say so in your first mailbox entry
and proceed with the fallback stated there.