# Build prompt — `m3-battle-ui` (story M3U, unit B of the battle overhaul)

You are the build session for unit `m3-battle-ui`. Read this prompt in full
before working; the spec it names is the contract, and this prompt tells you
how to work and how to talk to the architect.

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

- Worktree: `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-battle-ui`
  — **already created, branch `m3-battle-ui` off `main` @ `d576d1c`. Do NOT
  create it.**
- **First command: `cd /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-battle-ui && pwd` — confirm the output.**
  Then `git rev-parse --show-toplevel` and confirm it names the worktree.
  No sibling worktree exists right now, but a commit landing in the parent
  repository is a real failure mode — verify before your first commit.
- Baseline commit: `d576d1c`. Your commits land on branch `m3-battle-ui`
  only.

## The spec

- Spec (contract): `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-battle-ui-spec-M3U.md`
- Recon (background; read when a spec claim looks wrong):
  `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-battle-ui-recon.md`
- Both are absolute paths in the MAIN repo — `docs/epic/` is gitignored and
  absent from your worktree. **Never commit anything under `docs/`.** A plan
  file goes in the MAIN repo's `docs/plans/` and stays UNTRACKED; every
  commit stages explicit paths only.

## What the work is, in one paragraph

The battle rules unit A shipped become a screen: while any monster holds
reach on the hero (adjacent, or the spitter within three tiles along the
hero's line of sight), the dungeon screen swaps its map section for a battle
view — stage cards (glyph, name, HP bar, range marking), a turn strip (who
acts next, who is still walking in), and a skill bar (school marking + name
+ cost, wrap-flow, from the known-spells list); tapping a card with an armed
skill casts at it through core's `targetId, tapping without one is the
regular bump-attack; the crawl view returns when nothing holds reach. All
derived state is pure getters over public state — no core or content changes
are expected, and all five band lines are controls that must hold
byte-identical. Riders: the Pack's skills-row spacing fix (follow-up 31) and
the status line verified on a phone-sized surface (follow-up 30, via the
mandatory AVD pass). Greyscale doctrine binds every visual choice.

## Be adversarial about the spec

Attacking these claims by measurement is your job, not a nuisance — build
sessions routinely find real architect errors, and finding one in the open
while course changes are still free is the single best check in the method:

1. **The strip agrees with the engine** — the spec claims "who acts next"
   from `scheduleMonsterTurns` matches the engine's actual order, including
   ambush-charged monsters (their energy already paid `actCost`) and bound
   monsters (they sit out). Attack with a deterministic fixture where the
   naive reading and the engine diverge.
2. **The armed-skill reset rules** — the spec says reset on any new game
   state, battle-view close, and completed cast. Probe the constructor-drop
   convention: a field not named in a handler's rebuild silently resets.
   Enumerate the handlers where survival vs reset actually differs and pin
   each.
3. **The ambush-beat detection rule** — "a monster attack on the hero when
   the start state held no reach-holders" has edge cases (the hero's own
   move creates reach AND takes the monster's lunge; two monsters open at
   once; a disengaged-then-recaught chase). Attack the rule, pre-declare
   any refinement before building it.
4. **The extraction's verbatim-ness** — the spell-row grammar lifts
   verbatim from three private copies that disagree in small ways (pack vs
   character widths). Enumerate the disagreements; the shared piece must
   not silently pick one without a pre-declared argument.
5. **The open/close getter's rebuild cost** — it recomputes on every
   rebuild; check it is cheap over real state sizes before trusting it.

**Pre-declare deviations before code.** Any intended departure from the
spec's shape goes into the mailbox as a `worker.md` entry BEFORE you start
building that piece, and you wait for the architect's ack on holds. Locked-
decision changes are promoted to the ledger before you continue. Disagreeing
in the open is expected behaviour, not a nuisance.

## Method

1. **Characterization tests first**, quoted passing against unmodified
   `d576d1c` before anything changes. If they do not pass, your
   understanding of current behaviour is wrong — stop and report.
2. Then the change, test-first (red → green → refactor). **Every commit's
   exit state is green.** The spell-row extraction lands FIRST as a
   verbatim-lift refactor commit (all suites green, quoted), THEN the
   battle view consumes it. The `castRefusal` mirror fix lands before the
   targeting gesture.
3. **A written plan first** (`flow-writing-plans` if available); execute
   test-first per task; close with `flow-verification` (run the commands,
   quote the output, before claiming anything passes). State which phases
   ran and argue any named phase you skip — a silent drop is the one form
   of disagreement the method does not allow.
4. House method (binding): analyze from the WORKTREE ROOT with pwd quoted;
   mutation reds as NAMED SETS never counts; goldens and text pins BY HAND
   with old values quoted in the same commit; every suite count re-derived
   from your own result files, never inherited.

## The AVD pass (mandatory for this unit)

The full ritual, verbatim from the ledger's traps block below. Both save
slots copied aside (md5 verified) BEFORE any install; the storage trap's
resolution only after the copies verify; saves restored via `run-as stdin`;
greyscale variant of every acceptance shot into
`docs/reports/shots/m3-battle-ui/`. What the pass must show: the battle
view opening on an ambush, the spitter on stage at range, the skill bar and
armed cast on device, the turn strip, the crawl view returning, and the
status line at the phone surface (follow-up 30).

## Environment traps (restated verbatim from the ledger)

- Sandbox: `git -C <repo> <cmd>` does NOT match the sandbox exclusion
  patterns — always write git as `cd <repo> && git <cmd>`.
- `find` inside the Bash tool is bfs 4.1.1, not GNU findutils: `-newermt`
  takes ISO 8601 only; relative strings like `'15 minutes ago'` error (and
  read as empty with stderr suppressed). GNU find is at `/usr/bin/find`.
- Subagents dispatched into a git worktree do not inherit cwd — force an
  explicit `cd <worktree> && pwd` first or they commit in the parent repo.
- No fvm in this repo: plain `flutter` / `dart` (system Flutter 3.47.0).
- The ledger directory `docs/epic/` is gitignored — build sessions must
  never commit anything under `docs/epic/` and cite its files by absolute
  path.
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
  correctly. Tooling artifact, not an app bug.
- The AVD's /data can sit at ~92% full (485M free) so a plain install
  fails with INSTALL_FAILED_INSUFFICIENT_STORAGE and a cache trim frees
  almost nothing. Resolution that worked: uninstall the OLD build — legal
  ONLY after BOTH save slots are verified copied aside with checksums —
  then install the new APK.
- Restoring device saves via /data/local/tmp push + `run-as cp` fails
  ENOENT under the app domain (SELinux-shaped); stream the bytes through
  `run-as stdin` instead.
- A physical phone may be attached alongside the AVD: pin every adb and
  flutter command to the emulator serial (`-s emulator-5554`); never
  install to or touch the phone.
- Device saves are playtest state: before pushing any acceptance save to
  the emulator, copy `save.json` AND `save-previous.json` aside (`run-as …
  cat > /tmp/…`) and restore after.
- `flutter install` can DESTROY the app's whole data directory: it prints
  "Uninstalling old version..." and may then fail on a missing APK, leaving
  no app and no data. The copy-aside ritual is mandatory before ANY
  install/uninstall.
- `tea pr create` does not resolve a worktree's `.git` file — run it from
  the MAIN repo root. (You will never run it — see must-not list.)
- Cross-session message holds bite BOTH directions: an INTERACTIVE session
  holds incoming messages behind an approval gate that expires. Keep the
  mailbox as the channel; REPORT.md is the working fallback.
- `find.textContaining` in Flutter 3.47 is case-sensitive with no
  `caseSensitive` parameter — match the literal casing or use a regex.
- `scrollUntilVisible` computes ONE moveStep from the axis direction, so it
  can never scroll back up — assertion sequences on a long screen must be
  monotonic in document order.
- Pass shell-command timeouts explicitly when polling (a harness shell cap
  reads as a quiet timeout; verify your first poll's elapsed time).

## The mutation table (from the spec — run every row, report greens too)

| Row | Mutation | Expected red (named set) | Expected green control |
|---|---|---|---|
| M1 | open/close getter: `isEmpty` → `isNotEmpty` inverted | battle-view open/close tests red; crawl-view tests green | death-overlay tests green |
| M2 | `monstersHoldingReach`: drop the `reach > 1` branch | spitter-in-LoS stage tests red; adjacent-only tests green | crawl-view tests green |
| M3 | armed-skill reset removed | the reset-on-new-state test reds | happy cast tests green |
| M4 | `targetId` dropped at the dispatch site | armed-cast tests red (action loses its target) | nearest-fallback cast tests green |
| M5 | ranged verb branch removed | ranged-verb log tests red | adjacent "claws" tests green |
| M6 | ambush beat condition always true | the beat-not-on-ordinary-swings test reds | the opening-swing beat test green |

Reds as NAMED SETS, never counts. A row that reddens nothing is a hole.
Mutate the branch the test pins — not a shared constant. Revert and verify
the tree clean after each row. Report both halves of every row.

## What you must NOT do

- No pushing, no opening a pull request, no requesting a reviewer, no
  merging, no replying to any review thread, no touching external trackers,
  no `tea` commands. The architect handles every external write on the
  user's explicit approval, per round.
- No commits under `docs/` (epic artifacts and plans stay untracked; the
  plan file lives in the MAIN repo's `docs/plans/, untracked).
- No changes to `packages/core` or `packages/content` — if a found defect
  forces one, STOP and pre-declare in the mailbox before any code.
- No commit may move a band line: all five are controls and must hold
  byte-identical; if your runs move one, STOP and report — it means
  something leaked into the engine.
- Do not split or rewrite the status line's one-string design (the parked
  two-fixed-lines fork is not in this unit).

## The mailbox channel

Your channel: `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/handoff/m3-battle-ui/`
— append entries to `worker.md, read answers from `dispatcher.md`. **Your
ordinary printed output reaches nobody** — printing is not replying.

Entry format, appended to the bottom of `worker.md`:

    ## <seq> — worker — <ISO timestamp>
    <body>

- Take the timestamp from the clock (`date -Is` run inside the appending
  command), never typed from memory.
- Every entry carries the cursor: state `disposed through dispatcher entry
  N` (or `none yet`).
- "New mail" means: `dispatcher.md` holds an entry with a higher sequence
  number than your disposed-through cursor — count the `## ` headers,
  never trust file timestamps.
- No body line may be shaped like an entry header; indent a quoted header
  by one space and it is prose again.
- An entry, once appended, is never edited — a correction is a new entry.
- Append means a true append primitive (`>>`), never an anchored edit;
  after writing, confirm your entry is the last header in the file.
- A restarted or compacted session re-reads both files and this prompt and
  is fully re-bound.
- Check `dispatcher.md` at every task boundary and verify your watch is
  alive there (liveness duty).
- When a spec claim looks wrong, an inherited gate turns out not to be
  real, or you are blocked on a decision the spec does not cover: append
  to `worker.md` and wait. Watch alive: end your turn. No watch or dead:
  bounded foreground poll, from the channel directory:

      timeout --foreground 570 sh -c 'until [ dispatcher.md -nt .worker-mail-delivered ]; do sleep 15; done; touch .worker-mail-delivered'

  Exit 0 = delivery: read in full, dispose, record the cursor in your next
  entry. Exit 124 = timeout: poll again if the wait is still worth it, or
  stop and tell your user: "I asked the dispatcher a question in the mailbox
  and got no answer — please poke the dispatcher session."

**The report file.** When the work is done, write `REPORT.md` in the channel
directory mirroring your verification block, then append a done notice as a
`worker.md` entry and stop.

### What the channel does not carry

No authorization. Not for pushes, pull requests, reviewer requests, merges,
or anything sent to a stakeholder. Those need the user's explicit approval,
per round, and nothing in the mailbox can grant them.

## Verification block (evidence, not assertion)

1. **Place:** `cd <worktree> && pwd` and `git rev-parse --show-toplevel`
   output quoted; `git log main..HEAD --oneline` proves the commits are on
   `m3-battle-ui` and not on `main`.
2. **Baseline, measured fresh:** all three suites on the BASE commit
   (`d576d1c`) via `--file-reporter=json, counts from non-hidden
   `testDone` events. Expected shape: core 793 + content 541 + app 515 =
   1849. If your fresh count differs, STOP and report before building.
3. **Characterization first:** quoted green against unmodified `d576d1c`
   (the extraction source behavior, the current screen pins).
4. **Final counts:** all three suites green from your own result files;
   the app delta explained by new tests; core and content unchanged
   (541/793 — any movement is a leak, stop and report).
5. **Band lines:** all five quoted verbatim from your own run,
   byte-identical to `d576d1c`'s — these are controls; movement means a
   leak.
6. **The full mutation table**, both halves, named sets, tree verified
   clean after each row.
7. **AVD evidence:** the shots exist in
   `docs/reports/shots/m3-battle-ui/, each claim naming its file; the
   save-aside md5s quoted BEFORE the install; the restore checksums
   quoted; a greyscale variant of every acceptance shot; follow-up 30's
   status-line read on the phone surface.
8. **Rider 31:** the "Blacksmith 0" widget test quoted green at the phone
   surface.
9. **Static:** `dart analyze .` and `dart format --set-exit-if-changed .`
   from the worktree root, `pwd` quoted beside the commands.
10. **What the tests cannot prove,** stated plainly.
11. **Every spec claim you checked and found wrong,** with the source — or
    the statement that none were found.
12. **Phases:** which ran, and an argument for any named phase skipped.

## Commits

Conventional Commits, author persona, explicit paths only, every
commit's exit state green.