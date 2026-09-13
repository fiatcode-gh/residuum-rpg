# Build prompt — `m3-dock` (story M3V — the dock fix)

You are the build session for unit `m3-dock`. Read this prompt in full
before working; the spec it names is the contract, and this prompt tells
you how to work and how to talk to the architect.

## Your standing mailbox watch — start it FIRST, before reading anything else

After `cd <worktree> && pwd` (below), your **first action** is to start this
watch, **before reading the spec, before recon, before any work** — a
post-dispatch correction must be able to land from minute zero.

First, evaluate this condition **against your own tool list**: does your
harness offer a way to run a background task that re-invokes the session when
the task exits (an agent-launched background command, by whatever name)? You
resolve this yourself; nobody else can. Note the field finding from the last
unit: **a background runner shell may be fish, not sh/bash** — wrap the
command in `bash -c '...'` if so, and verify the watch is genuinely alive
past one poll tick (a launch receipt is not a liveness proof; a watch died
at 49 ms that way once).

- **If yes**, run this as a background task, from the channel directory:

      timeout --foreground 3600 sh -c '[ -f .worker-mail-delivered ] || touch -t 197001010000 .worker-mail-delivered; until [ dispatcher.md -nt .worker-mail-delivered ]; do sleep 30; done; touch .worker-mail-delivered'

  On a wake: **restart the watch first**, then read `dispatcher.md` in full
  and dispose of the new entry: if it changes the task you are on, stop and
  adjust; if it locks or corrects a decision, follow it from here on;
  otherwise acknowledge it in your next `worker.md` entry and keep building.
  While this watch is standing and verified alive, a blocked worker ends its
  turn instead of foreground-polling.
- **If not**, you are on the floor: use the bounded poll (below) and task-
  boundary checks.

**A claimed watch carries a liveness duty.** Every task-boundary check also
verifies the watch process is genuinely alive (it exists and is older than
one poll tick). Dead or unverifiable means you are on the floor: say so in
your next entry and rely on boundary checks and the poll until a relaunch
proves stable.

**Every `timeout` in this protocol carries `--foreground`.** Closing a watch
means stop restarting, never trusting a kill: report "left to expire" unless
you hold the kill's confirmed result. The delivery markers record delivery,
not reading; freshness is always the sequence comparison against your own
disposed-through cursor.

## Worktree and working directory

- Worktree:
  `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-dock`
  — **already created, branch `m3-dock` off `main` @ `fda107f`. Do NOT
  create it.**
- **First command: `cd /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-dock && pwd` — confirm the output.**
  Then `git rev-parse --show-toplevel` and confirm it names the worktree.
  No sibling worktree exists right now, but a commit landing in the parent
  repository is a real failure mode — verify before your first commit.
- Baseline commit: `fda107f`. Your commits land on branch `m3-dock` only.

## The spec

- Spec (contract):
  `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-dock-spec-M3V.md`
- Recon (background; read when a spec claim looks wrong):
  `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-dock-recon.md`
- Both are absolute paths in the MAIN repo — `docs/epic/` is gitignored and
  absent from your worktree. **Never commit anything under `docs/`.** A plan
  file goes in the MAIN repo's `docs/plans/` and stays UNTRACKED; every
  commit stages explicit paths only.

## What the work is, in one paragraph

The battle screen the last unit shipped replaces the map while a fight
holds — and a spitter that shoots from three tiles never comes adjacent,
so the player was trapped on a screen whose only tappable surface did
nothing. The fix, ruled by the user (D91): the map NEVER leaves the
screen. The stage cards and turn strip dock above the map slot, the
skill bar below it, and the crawl map stays rendered and tappable
through the whole fight; the dock rows appear exactly while
`isBattleOpen` and leave when nothing holds reach. A stage card tapped
beyond one step says so in the log (name the monster, say walk) instead
of doing nothing silently. App-only; core and content untouched; all
five band lines are controls that must hold byte-identical.

## Be adversarial about the spec

Attack the spec's central claims by measurement before you build. The
ones most worth attacking:

- **"The dock fits a phone."** The Column gains rows and the map slot
  shrinks. Measure the phone-sized surface (T7) EARLY, not last — if
  the dock-up screen cannot fit map + HP + controls + log without
  overflow, that is a spec-level finding, not a detail.
- **"The far card tap needs no derived state."** The spec claims the
  widget can decide adjacent-vs-far from what it already holds. If the
  hero's position is not reachable from the view state the card sees,
  say so and pre-declare the shape you need.
- **"The D89 grammar carries unchanged."** If re-pointing the skill bar
  at a dock row changes any contract it had (order, wrap, refusal),
  that contradicts the spec — attack it.
- Disagreeing in the open is expected behaviour, not a nuisance. Any
  intended departure from the spec's shape — file layout, widget split,
  a test you believe is wrong — is appended to the mailbox as a
  pre-declared deviation BEFORE you start building that part. The
  architect answers in `dispatcher.md`; the mailbox is the record.

## Method

- **Characterization tests first.** C1 and C2 in the spec must PASS
  against the UNMODIFIED code (baseline `fda107f`). If they do not,
  your understanding of current behaviour is wrong — stop and report,
  do not work around it.
- Then the change, test-first: T1–T7 with each commit's exit state
  green (no reviewable unit left red).
- Roughly-thirty-lines-or-more of real logic: write a short plan FIRST
  (flow-writing-plans), then execute test-first (flow-tdd). A plan
  document goes in the MAIN repo's `docs/plans/, untracked.
- Commits:. Conventional
  Commits. Every commit stages explicit paths only.

## Environment traps (restated verbatim — they are per-project, not decoration)

- Sandbox: `git -C <repo> <cmd>` does NOT match the sandbox exclusion
  patterns — always write git as `cd <repo> && git <cmd>`.
- `find` inside the Bash tool is bfs 4.1.1, not GNU findutils:
  `-newermt` takes ISO 8601 only; relative strings like `'15 minutes
  ago'` error (and read as empty with stderr suppressed). GNU find is
  at `/usr/bin/find`.
- Subagents dispatched into a git worktree do not inherit cwd — force
  an explicit `cd <worktree> && pwd` first or they commit in the parent
  repo.
- No fvm in this repo: plain `flutter` / `dart` (system Flutter 3.47.0).
- The ledger directory `docs/epic/` is gitignored — build sessions must
  never commit anything under `docs/epic/` and cite its files by
  absolute path.
- Commits use the personal persona:.
- Device nodes are hidden inside sandboxed Bash: `/dev/kvm` reads as
  missing while it exists on the host — hardware probes lie under
  sandbox. Emulator, adb, and `flutter run` need unsandboxed commands
  (permission prompt; a `--bg` session stalls on it silently).
- AVD `Pixel_10` exists (`emulator -list-avds`); `flutter emulators` and
  `flutter emulators --create` mishandle the installed ps16k system
  images — use the `emulator` binary directly.
- UPDATE 2026-08-20 (D8): `emulator, `adb, and device-facing `flutter`
  subcommands (`run`/`devices`/`emulators`/`install`/`attach`/`logs`/
  `drive`) are now sandbox-excluded — no prompt. Other hardware probes
  still lie.
- `git worktree add`/`remove` and deleting a worktree's `.claude` files
  fail under sandbox (EROFS on `.git/worktrees/, "busy" on protected
  config paths) — run worktree lifecycle commands unsandboxed.
- `adb shell input swipe` at 400ms emits too few motion samples for
  Flutter's pan recogniser and looks like a broken pan; 1200ms pans
  correctly. Tooling artifact, not an app bug.
- The AVD's /data can sit at ~92% full (485M free) so a plain install
  fails with INSTALL_FAILED_INSUFFICIENT_STORAGE and a cache trim frees
  almost nothing. Resolution that worked: uninstall the OLD build —
  legal ONLY after BOTH save slots are verified copied aside with
  checksums — then install the new APK (~153,590,984 bytes).
- Restoring device saves via /data/local/tmp push + `run-as cp` fails
  ENOENT under the app domain (SELinux-shaped); stream the bytes through
  `run-as stdin` instead.
- A physical phone may be attached alongside the AVD: pin every adb and
  flutter command to the emulator serial (`-s emulator-5554`); never
  install to or touch the phone.
- Device saves are playtest state: before pushing any acceptance save
  to the emulator, copy `save.json` AND `save-previous.json` aside
  (`run-as … cat > /tmp/…`) and restore after. The M3X pass overwrote
  the user's 2026-08-23 playtest save and its backup, unrecoverably.
- `flutter install` can DESTROY the app's whole data directory: it
  prints "Uninstalling old version..." and may then fail on a missing
  APK, leaving no app and no data. The copy-aside ritual (previous
  trap) is MANDATORY before ANY install/uninstall, not only before
  pushing saves. The debug APK is ~153 MB; check emulator free space
  first.
- `tea pr create` does not resolve a worktree's `.git` file — run it
  from the MAIN repo root. (Not your job anyway — see must-not below.)
- Cross-session message holds bite BOTH directions: keep exactly one
  architect session alive; the BUILD-REPORT.md mirror is the working
  fallback; expect to relay by hand when the architect runs
  interactive.
- `find.textContaining` in Flutter 3.47 is case-sensitive with no
  `caseSensitive` parameter — match the literal casing or use a regex.
- `scrollUntilVisible` computes ONE moveStep from the axis direction,
  so it can never scroll back up — assertion sequences on a long screen
  must be monotonic in document order.

## The mutation table (from the spec — run every row, report the whole table)

Run every row by your own sed and report the NAMED SET of tests each
reddened — never a count — greens included. M2 is a sequencing trap: it
re-inserts code the change removes; run it, report it, then revert to
the dock.

| # | Mutation (by sed) | Expected red | Expected green |
|---|---|---|---|
| M1 | Dock gate: make the stage/strip rows unconditional (drop the `isBattleOpen` gate) | T5, T7 | T1, T2 |
| M2 | Map slot: restore the swap (`isBattleOpen ? BattleView : GlyphGrid`) | T1, T2 | T6 |
| M3 | Guidance sentence: drop the log line from the far card tap | T3 | T4 |
| M4 | Far card tap: emit the plain `TileTapped` with no sentence | T3 | T4 |
| C-1 | Stage card HP-bar length | D89 stage test | T1–T7 |
| C-2 | Skill-bar cost label | D89 skill-bar test | T1–T5 |

## What you must NOT do

- No pushing, no opening a pull request, no requesting a reviewer, no
  merging, no replying to any review thread, no touching external
  trackers. The architect handles every external write, on the user's
  explicit approval, per round.
- No changes under `packages/core/` or `packages/content/` — the band
  lines are controls that must hold byte-identical. A found defect that
  seems to need one: STOP, pre-declare in the mailbox, wait.
- Nothing under `docs/` in any commit; the plan file stays untracked.
- Never install to or touch a physical phone; pin device commands to
  the emulator serial.

## The mailbox — your only channel to the architect

Your ordinary printed output reaches nobody. Append entries to
`worker.md, read answers from `dispatcher.md, in:

    /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/handoff/m3-dock/

The mailbox tool performs every mechanic — its absolute path:

    /var/home/dhemas/Development/Projects/fiatcode/ai-stack/shared/skills/flow-mailbox/scripts/mailbox

Run it once with no arguments to confirm the path (prints usage, exits
2 — by design). Then, from the channel directory:

- `mailbox append --as worker --dir <channel> --disposed-through <N|none>`
  — body on stdin or `--file`. Every entry carries the cursor
  (`disposed through <other side> entry N, or `none yet`).
- `mailbox check --as worker --dir <channel>` — exit 0 new mail, 1
  none, 2 refused.
- `mailbox wait --as worker --dir <channel>` — the bounded poll; your
  floor when the watch is dead or unverifiable.
- `mailbox watch --as worker --dir <channel>` — the standing watch
  (the block at the top of this prompt).
- Freshness is the sequence comparison against your disposed-through
  cursor — count the `## ` headers in the other file — never a file
  timestamp. An appended entry is never edited; a correction is a new
  entry. No body line shaped like an entry header (indent a quoted
  `## ` line by one space). A failed append may have its own garbage
  truncated before retry, disclosed in the replacement entry — never
  hand-repair around the tool.

Write to the mailbox and wait when: a spec claim looks wrong, an
inherited gate turns out not to be real, or you are blocked on a
decision the spec does not cover. Otherwise decide, proceed, and report
at the end. Check `dispatcher.md` at every task boundary — between plan
tasks, before each commit.

**The report file.** At the end, mirror your full verification block to
`REPORT.md` in the channel directory, then append a done notice to
`worker.md` and stop.

## Verification block — every item evidenced, not asserted

Your report names the command output that proves each of these:

1. Proof the work happened in the worktree: `cd <worktree> && pwd` and
   `git rev-parse --show-toplevel` outputs; the commit list
   (`git log --oneline main..HEAD`).
2. Baseline measured FRESH in the worktree before the first change
   (`main` @ `fda107f`): run all three suites from the worktree root
   with pwd quoted, counts read from result files (non-hidden
   testDone). State the baseline number and every later count against
   it. `dart analyze .` from the WORKTREE ROOT with pwd quoted — a
   package-directory run does not reach sibling packages.
3. C1/C2 passed against the UNMODIFIED code, with the evidence.
4. T1–T7 passing, and the D89 swap tests rewritten (not preserved).
5. The full mutation table — every row, named red sets, greens
   included, M2's sequencing trap honoured.
6. `dart format` clean; `git diff main -- packages/core packages/content`
   EMPTY (quote the empty output).
7. What the tests cannot prove, stated plainly — the widget suite does
   not see a phone's thumb reach, the log's readability at dock-up, or
   the ambush's feel; those are the AVD pass and the user's playtest.
8. Every spec claim you checked and found wrong, with the source.
9. Which execution phases ran, and why any named phase was skipped —
   a skip is an argument, not an absence.
10. The AVD pass evidence: install proof, the acceptance shots saved to
    the MAIN repo's `docs/reports/shots/m3-dock/` (dock-up, dock-down,
    greyscale variants), and any device finding fixed or pre-declared.

## Delegation

The change is widget restructuring plus tests — real logic, so: write a
short plan first (flow-writing-plans), then execute test-first
(flow-tdd). Do the work yourself; read-only subagents may fan out for
search, never a writer.