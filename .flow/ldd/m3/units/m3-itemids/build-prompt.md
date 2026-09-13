# m3-itemids — build prompt

You are the build session for unit `m3-itemids` (story M3I) of the
Residuum epic. Read this whole document before acting on any part of it.

## The standing mailbox watch — start it FIRST, before reading the spec

Evaluate this condition against your OWN tool list, now: **does your
harness offer a way to run a background task that re-invokes this session
when the task exits** (an agent-launched background command, by whatever
name)?

- **If yes**, start your watch as your very first action after the
  worktree check below — before the spec, before recon, before any work:

      /var/home/dhemas/Development/Projects/fiatcode/ai-stack/shared/skills/flow-mailbox/scripts/mailbox watch --as worker --dir /var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/handoff/m3-itemids

  On a wake: restart the watch FIRST, then read `dispatcher.md` in full
  and dispose of the new entry — if it changes the task, stop and adjust;
  if it locks or corrects a decision, follow it from here on; otherwise
  acknowledge in your next `worker.md` entry and keep building. While the
  watch is standing and verified alive, a blocked worker ends its turn
  instead of a foreground wait. Every task boundary also verifies the
  watch process is genuinely alive (older than 30 seconds, one tick) —
  dead or unverifiable means you are on the floor: say so in your next
  entry, rely on boundary checks and `mailbox wait`, and relaunch when
  stable. When the dispatcher closes the mailbox, stop restarting and let
  the final instance expire — a kill claim needs the kill's confirmed
  result, otherwise report "left to expire".
- **If no such capability:** you are on the floor — check `dispatcher.md`
  at every task boundary, and when blocked use:

      /var/home/dhemas/Development/Projects/fiatcode/ai-stack/shared/skills/flow-mailbox/scripts/mailbox wait --as worker --dir /var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/handoff/m3-itemids

  Exit 0 = mail delivered, read `dispatcher.md` in full, dispose, record
  the new cursor in your next entry. Exit 124 = the window closed empty —
  wait again if still worth it, or stop and tell your user: "I asked the
  dispatcher a question in the mailbox and got no answer — please poke
  the dispatcher session."

## The worktree — already created, do NOT create it

The architect created it: `/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/.worktrees/m3-itemids`, branch `m3-itemids` at `a567c19`, verified. Do not run `git worktree add`; do not touch any other worktree (there are none today) and let nothing land in the parent repo.

**First command, before anything: `cd
/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/.worktrees/m3-itemids
&& pwd` — confirm the output.** A fresh session's shell does not reliably
inherit the intended directory, and a commit landing in the parent
repository is a real failure mode.

## The spec and recon

Read in full, in order: the spec at
`/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/m3-itemids-spec-M3I.md`
(absolute path — the docs directory is gitignored and absent from the
worktree), then the recon at
`/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/m3-itemids-recon.md`
as background when a spec claim looks wrong. **Commit nothing under
`docs/`** — the directory is gitignored and yours to read, never to
write.

## What the work is, in one paragraph

Item ids in this game are minted per-run (`drop-1` on every delve,
`floor-<depth>-<n>` per floor, `trophy-<node>` per dungeon), but the
hero's pack persists across delves — so the pack can hold two items with
the same id, and every id lookup takes the first match while every
removal deletes ALL matches. Confirmed live: a hero lost a weapon by
drinking a potion that shared its id. The fix: a hero-scoped counter
(`Profile.itemNumber`, the `brewNumber` precedent) whose ids are stamped
onto items at the moment they enter the pack (pickup), carried across
every state boundary that carries inventory, with save v3 and every
pinned golden document byte-identical (omit-on-default codec, the
`reach` precedent). Plus remove-one semantics on every id-based removal,
which makes inherited duplicates harmless. No UI changes; no version
bump.

## Be adversarial about the spec

Attack these claims by measurement before you build, and disagree in the
open — that is expected behaviour, not a nuisance:

- **"Nothing bot-visible moves"** — the survivability bands must hold
  byte-identical. Run the trail yourself and check all five lines; if a
  line moves, stop and report — that is a spec-breaking finding, not
  something to re-pin.
- **"The boundary list is complete"** — the spec lists five doors;
  re-grep `inventory:` across `run_boundary.dart` and `world.dart` and
  pre-declare anything you find beyond it.
- **"`market-*`, `kit-*`, `brew-*` ids cannot collide with `item-*`"** —
  verify the prefix argument at the mint sites yourself.
- **"Remove-first-match is deterministic"** — think through list order
  on a pack that has been through sell/rebuy cycles.

**Deviations are pre-declared**: append any intended departure from the
spec's shape to the unit mailbox BEFORE you start building. A
locked-decision change is promoted to the ledger before you continue.
The recon document exists because seven architect claims have died at
workers' hands — you are invited to make it eight.

## Method

Characterization tests first, and they must pass against UNMODIFIED
`a567c19` — if they do not, your understanding of current behaviour is
wrong: stop and report through the mailbox, do not work around it. Then
the new-behaviour tests (red), then the change, then green. **Every
commit's exit state is green.** This unit is well over thirty changed
lines with real logic: write the plan first (flow-writing-plans), then
execute test-first. The mutation table lives in the spec's test plan;
run every row against the characterization+new suites and report the
whole table — greens included, named red sets, never counts. M1/M2 can
only be run against the characterization suite before the flip; M3–M5
only after — report both phases and why any named phase was skipped if
you skip one.

## Environment traps (restated verbatim from the ledger)

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
- `adb shell input swipe` at 400ms emits too few motion samples for
  Flutter's pan recogniser and looks like a broken pan; 1200ms pans
  correctly. Tooling artifact, not an app bug (cost the M2Q worker three
  screenshots).
- The AVD's /data can sit at ~92% full (485M free) so a plain install
  fails with INSTALL_FAILED_INSUFFICIENT_STORAGE and a cache trim frees
  almost nothing (M3F, 2026-09-01). Resolution that worked: uninstall the
  OLD build — legal ONLY after BOTH save slots are verified copied aside
  with checksums — then install the new APK (~153,590,984 bytes).
- Restoring device saves via /data/local/tmp push + `run-as cp` fails
  ENOENT under the app domain (SELinux-shaped); stream the bytes through
  `run-as stdin` instead (M3F).
- A physical phone may be attached alongside the AVD: pin every adb and
  flutter command to the emulator serial (`-s emulator-5554`); never
  install to or touch the phone (user instruction during M3R).
- Device saves are playtest state: before pushing any acceptance save to
  the emulator, copy `save.json` AND `save-previous.json` aside
  (`run-as … cat > /tmp/…`) and restore after. The M3X pass overwrote the
  user's 2026-08-23 playtest save and its backup, unrecoverably.
- `flutter install` can DESTROY the app's whole data directory: it prints
  "Uninstalling old version..." and may then fail on a missing APK,
  leaving no app and no data. The M3M pass lost both save slots this way;
  the copy-aside ritual (previous trap) was the only recovery — treat it
  as mandatory before ANY install/uninstall, not only before pushing
  saves. The debug APK is ~153 MB; check emulator free space first.
- Cross-session message holds bite BOTH directions: an INTERACTIVE session
  holds incoming messages behind an approval gate that expires — including
  worker→architect replies when the architect is interactive (burned M2T's
  kickoff and M2Q's reply). A worker cannot tell an interactive architect
  from a bg one via kickoff metadata, and a stale same-named session makes
  addressing a coin flip. Keep exactly one architect session alive; the
  BUILD-REPORT.md mirror is the working fallback; expect to relay by hand
  when the architect runs interactive.
- `find.textContaining` in Flutter 3.47 is case-sensitive with no
  `caseSensitive` parameter — match the literal casing or use a regex
  (cost the M3F worker investigation time, recorded D65 era).
- `scrollUntilVisible` computes ONE moveStep from the axis direction, so
  it can never scroll back up — assertion sequences on a long screen must
  be monotonic in document order (M3F worker finding; bind every HUD+cast
  widget pass).
- (2026-09-02) Background-runner shells may be fish — wrap watch/suite
  commands in `bash -c` (a fish `$?` killed a suite run and two watches);
  a watch's launch receipt is not liveness — verify past one poll tick;
  sandbox `rm` can fail silently — retry removals with errors visible.
- (2026-09-03, D93) The actor codec REQUIRES `resists` in a hand-built
  monster document — hand-staged saves without it are refused whole.

This unit needs NO device: no UI changes, no acceptance save. Do not
install anything anywhere.

## What you must NOT do

No pushing, no opening a pull request, no requesting a reviewer, no
merging, no replying to any review thread, no touching external trackers.
No commits under `docs/`. No installs, uninstalls, or emulator/phone
operations — the unit needs no device. The architect handles every
external write on the user's explicit approval, per round.

## The channel

Your ordinary printed output reaches nobody. Every question, pre-declared
deviation, and completion notice is an entry appended to `worker.md` in
the channel directory
`/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/handoff/m3-itemids/`,
and every answer is read from `dispatcher.md` in the same directory.
Every write goes through the tool (path above) — `init` is already done;
never edit an entry, never write a mailbox file by hand; a correction is
a new entry. Append form:

      /var/home/dhemas/Development/Projects/fiatcode/ai-stack/shared/skills/flow-mailbox/scripts/mailbox append --as worker --dir /var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/handoff/m3-itemids --disposed-through <N|none>

(body from stdin or `--file <path>`; the stamp comes from the tool —
never hand-type one). "New mail" is a sequence comparison against your
own disposed-through cursor, never a file timestamp; `mailbox check
--as worker --dir <channel>` asks it. A refusal (exit 2) means nothing
landed — fix the input and retry; a corrupt file is a stop-and-say-so,
never a hand repair. Write `REPORT.md` in the channel directory once, at
the end, mirroring your verification block; then append a done notice.
When you ask a question and must wait: watch alive (verified) → end the
turn; no watch → `mailbox wait` (the branch is stated at the top of this
prompt). The channel carries no authorization — pushes, PRs and merges
happen only outside it, by the user's hand.

## Verification block — every item evidenced, not asserted

Your `REPORT.md` names, for each item, the command output that proves it:

1. Proof you worked in the worktree (`cd … && pwd`, `git branch
   --show-current`) and that `m3-itemids` commits exist on no other
   branch (`git log --oneline main..m3-itemids`).
2. Test counts read from result files (non-hidden `testDone`), compared
   against a baseline you measured FRESH on unmodified `a567c19` — state
   the numbers (the ledger's last known: core 793 + content 541 + app
   563; measure your own anyway).
3. Proof the characterization tests passed against unmodified code
   (the run's output, before the first change commit).
4. The full mutation table — named red sets and greens, both phases.
5. The five band lines verbatim from your own run, and the statement
   that they are byte-identical to the pins in the spec.
6. `dart analyze .` from the worktree root with pwd quoted; `dart
   format --output=none --set-exit-if-changed .` result.
7. What the tests cannot prove, stated plainly.
8. Every spec claim you checked and found wrong, with the source.
9. Which execution phases ran (plan, characterization, change, mutation
   sweep) and why any named phase was skipped — a skip is an argument,
   not an absence.