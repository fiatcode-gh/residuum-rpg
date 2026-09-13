# Build prompt — `m3-battle` (story M3U, unit A of the battle overhaul)

You are the build session for unit `m3-battle`. Read this prompt in full
before working; the spec it names is the contract, and this prompt tells you
how to work and how to talk to the architect.

## Your standing mailbox watch — start it FIRST, before reading anything else

After `cd <worktree> && pwd` (below), your **first action** is to start this
watch, **before reading the spec, before recon, before any work** — a
post-dispatch correction must be able to land from minute zero.

First, evaluate this condition **against your own tool list**: does your
harness offer a way to run a background task that re-invokes the session when
the task exits (an agent-launched background command, by whatever name)? You
resolve this yourself; nobody else can.

- **If yes**, run this as a background task, from the channel directory:

      timeout --foreground 3600 sh -c '[ -f .worker-mail-delivered ] || touch -t 197001010000 .worker-mail-delivered; until [ dispatcher.md -nt .worker-mail-delivered ]; do sleep 30; done; touch .worker-mail-delivered'

  On a wake: **restart the watch first**, then read `dispatcher.md` in full
  and dispose of the new entry: if it changes the task you are on, stop and
  adjust; if it locks or corrects a decision, follow it from here on;
  otherwise acknowledge it in your next `worker.md` entry and keep building.
  While this watch is standing and verified alive, a blocked worker ends its
  turn instead of foreground-polling — the wake replaces the poll.
- **If not**, you are on the floor: use the bounded poll (below) and task-
  boundary checks.

**A claimed watch carries a liveness duty.** Harnesses have dropped a
completion wake and reported a dead watch as running. Where a watch is your
promptness story, every task-boundary check also verifies the watch process
is genuinely alive (it exists and is older than one poll tick). Dead or
unverifiable means you are on the floor: say so in your next entry and rely
on boundary checks and the poll until a relaunch proves stable.

**Every `timeout` in this protocol carries `--foreground`.** Without it, GNU
timeout moves itself into a new process group and survives directed kills
that should reach it.

**Closing a watch means stop restarting, never trusting a kill.** When the
dispatcher closes the mailbox, stop restarting and let the final instance
expire on its own timeout. If a kill is attempted anyway, "killed" may be
claimed only from the kill's confirmed result; otherwise report "left to
expire".

**The delivery markers record delivery, not reading.** No boundary check, no
freshness question, no done-decision may consult them; unread-or-not is
always the sequence comparison against your own disposed-through cursor.

## Worktree and working directory

- Worktree: `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-battle`
  — **already created, branch `m3-battle` off `main` @ `8168861`. Do NOT
  create it.**
- **First command: `cd /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-battle && pwd` — confirm the output.**
  A fresh session's shell does not reliably inherit the intended directory.
  Prefer git invocations from inside the worktree after the cd. **No sibling
  worktree exists right now**, but a commit landing in the parent repository
  is a real failure mode — verify with `git rev-parse --show-toplevel` that
  you are where you think you are.
- Baseline commit: `8168861`. Your commits land on branch `m3-battle` only.

## The spec

- Spec (contract): `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-battle-spec-M3U.md`
- Recon (background; read when a spec claim looks wrong):
  `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-battle-recon.md`
- Both are absolute paths in the MAIN repo — `docs/epic/` is gitignored and
  absent from your worktree. **Never commit anything under `docs/`.** A plan
  file you write goes in the MAIN repo's `docs/plans/` and stays UNTRACKED;
  every commit stages explicit paths only. No plan file may ever be committed.

## What the work is, in one paragraph

Combat gains three ruled changes, measured by the existing survivability bot
with a documented band trail: an ambush opening (a monster newly in reach on
the hero swings in this turn's monster phase, once, spending its opening —
the chase gets teeth), explicit cast targeting (`CastSpellAction` may name a
visible target; the nearest-enemy rule becomes the fallback), and a `reach`
stat with one new ranged creature — the spitter, crypt depths 1–2 — that
stands and shoots from up to three tiles within line of sight. The band
lines will MOVE and are re-pinned through a measured trail; the casting-bot
line (a third build with a Firebolt book) is built as the instrument that
judges the new fights. Save v3 stands (omit-on-default encoding); the
suspend theorem, road fights, and boss placement all hold.

## Be adversarial about the spec

Attacking these claims by measurement is your job, not a nuisance — build
sessions routinely find real architect errors, and finding one in the open
while course changes are still free is the single best check in the method:

1. The ambush energy arithmetic — the spec claims the opening swing spends
   the monster's action so it never double-swings. Prove or refute at the
   seed level; the exact energy arithmetic is yours to pin.
2. Omit-on-default codec keeping golden save documents byte-identical.
3. The spitter's stat line against `designed_difficulty_test.dart`'s depth
   requirement (the spec claims depths 1–2 placement keeps it outside the
   deep-creature rule — verify by reading the test, not by trusting it).
4. The claim that reach defaults preserve all fourteen existing creatures
   behaviorally — one counterexample kills item 1's contract.
5. The LoS-reuse claim (`state.visible` + Chebyshev ≤ reach is a correct
   "can shoot from here" test) — look for an asymmetric-sight hole.
6. The seed-4242 door pin (`dungeon_door_characterization_test.dart`) — the
   spec predicts which pins move when the crypt d1/d2 tables change;
   enumerate every pin that moves and check the list is complete.

**Pre-declare deviations before code.** Any intended departure from the
spec's shape goes into the mailbox as a `worker.md` entry BEFORE you start
building that piece, and you wait for the architect's ack on holds. Locked-
decision changes are promoted to the ledger before you continue. A
deviation surfaced in the verification block afterwards is a failed
declaration, not a disclosure. Invite yourself to disagree in the open —
that is expected behaviour, not a nuisance.

## Method

1. **Characterization tests first**, and they must pass against the
   **unmodified** base commit before anything changes. If they do not, your
   understanding of current behaviour is wrong — that is a stop-and-report,
   not a thing to work around.
2. Then the change, test-first (red → green → refactor). **Every commit's
   exit state is green** — no reviewable unit is left red. The goldens
   control runs before AND after the codec change.
3. **A written plan first** (`flow-writing-plans` if available): this unit
   is far past the thirty-line threshold. Execute test-first per task; close
   with `flow-verification` (run the commands, quote the output, before
   claiming anything passes). State which execution phases ran and argue any
   named phase you skip — a silent drop is the one form of disagreement the
   method does not allow.
4. House method details (binding): analyze from the WORKTREE ROOT with pwd
   quoted; mutation reds as NAMED SETS never counts; goldens BY HAND with
   old values quoted in the same commit; every suite count re-derived from
   your own result files, never inherited; band pins re-set by hand with old
   values quoted in the same commit; refusal/behavior fixtures as their own
   commit BEFORE any codec change where the spec orders it.

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
  `--bg` session stalls on it silently). (Unit A is headless — no AVD pass.)
- `git worktree add`/`remove` and deleting a worktree's `.claude` files fail
  under sandbox (EROFS on `.git/worktrees/, "busy" on protected config
  paths) — run worktree lifecycle commands unsandboxed.
- `adb shell input swipe` at 400ms emits too few motion samples for
  Flutter's pan recogniser and looks like a broken pan; 1200ms pans
  correctly. Tooling artifact, not an app bug. (Not expected to bite here.)
- The AVD's /data can sit at ~92% full (485M free) so a plain install fails
  with INSTALL_FAILED_INSUFFICIENT_STORAGE and a cache trim frees almost
  nothing. Resolution that worked: uninstall the OLD build — legal ONLY
  after BOTH save slots are verified copied aside with checksums — then
  install the new APK. (Unit A: no installs.)
- Restoring device saves via /data/local/tmp push + `run-as cp` fails
  ENOENT under the app domain (SELinux-shaped); stream the bytes through
  `run-as stdin` instead. (Unit A: no device work.)
- A physical phone may be attached alongside the AVD: pin every adb and
  flutter command to the emulator serial (`-s emulator-5554`); never install
  to or touch the phone. (Unit A: no device work.)
- Device saves are playtest state: before pushing any acceptance save to the
  emulator, copy `save.json` AND `save-previous.json` aside (`run-as … cat >
  /tmp/…`) and restore after. (Unit A: no device work.)
- `flutter install` can DESTROY the app's whole data directory: it prints
  "Uninstalling old version..." and may then fail on a missing APK, leaving
  no app and no data. The copy-aside ritual is mandatory before ANY
  install/uninstall. (Unit A: no device work.)
- `tea pr create` does not resolve a worktree's `.git` file — run it from
  the MAIN repo root. (Unit A: you will never run it — see must-not list.)
- Cross-session message holds bite BOTH directions: an INTERACTIVE session
  holds incoming messages behind an approval gate that expires. Keep the
  mailbox as the channel; BUILD-REPORT.md is the working fallback.
- `find.textContaining` in Flutter 3.47 is case-sensitive with no
  `caseSensitive` parameter — match the literal casing or use a regex.
- `scrollUntilVisible` computes ONE moveStep from the axis direction, so it
  can never scroll back up — assertion sequences on a long screen must be
  monotonic in document order.
- Pass shell-command timeouts explicitly when polling (a harness shell cap
  reads as a quiet timeout; verify your first poll's elapsed time).

## The mutation table (from the spec — run every row, report greens too)

| Row | Mutation (sed on committed code) | Expected red (named set) | Expected green control |
|---|---|---|---|
| M1 | delete the ambush pre-charge condition in `step()` | the ambush reds (a) and (b); `step_monsters_test` adjacent-claw stays green | arrival-safety test green (arrival never ambushes, before or after) |
| M2 | ranged branch `<= reach` → `< reach` | spitter tests at exactly distance 3 red; distance-2 tests green | adjacent-attack tests green |
| M3 | drop `visible.contains` from the reach test | "cannot shoot without LoS" reds | open-LoS shot tests green |
| M4 | codec: encode reach unconditionally | golden save test reds (bytes move) | decode-default test green |
| M5 | swap mana/unknown order in `_castRefusal` | refusal-order test reds | happy-path cast green |
| M6 | spitter `reach: 3` → `1` | spitter shoot tests red | `hasLength` content pins green |

Reds are NAMED SETS, never counts. A row that reddens nothing is a hole, not
a pass. Mutate the branch the test pins — not a shared constant (the D69
lesson: mutating the shared opacity constant instead of the node branch
flipped which tests reddened). Revert and verify the tree clean after each
row. Report both halves of every row.

## What you must NOT do

- No pushing, no opening a pull request, no requesting a reviewer, no
  merging, no replying to any review thread, no touching external trackers,
  no `tea` commands. The architect handles every external write on the
  user's explicit approval, per round.
- No commits under `docs/` (epic artifacts and plans stay untracked).
- No device/emulator work of any kind — this unit is headless.
- No bestiary/stat changes beyond the spec's named spitter and table rows
  (the tiered lever rule: bestiary and hero stats need a ruling; you have
  the spitter ruling and nothing else).
- Do not touch the app package's mirrored `castRefusal`/`_needsATarget`
  (`packages/app/lib/game/game_bloc.dart`) — unit B owns it; the optional
  parameter keeps existing call sites compiling. Do not "fix the drift".

## The mailbox channel

Your channel: `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/handoff/m3-battle/`
— append entries to `worker.md, read answers from `dispatcher.md`. **Your
ordinary printed output reaches nobody** — printing is not replying.

Entry format, appended to the bottom of `worker.md`:

    ## <seq> — worker — <ISO timestamp>
    <body>

- Take the timestamp from the clock (`date -Is` run inside the appending
  command), never typed from memory — hand-typed stamps have drifted
  minutes in the field, and the close-out fold sorts by them.
- Every entry carries the cursor: state `disposed through dispatcher entry
  N` (or `none yet`) in each entry you append.
- "New mail" means: `dispatcher.md` holds an entry with a higher sequence
  number than your disposed-through cursor — count the `## ` headers,
  never trust file timestamps.
- No body line may be shaped like an entry header (`## N — role — stamp`);
  indent a quoted header by one space and it is prose again.
- An entry, once appended, is never edited — a correction is a new entry.
- Append means a true append primitive (`>>`), never an anchored edit; after
  writing, confirm your entry is the last header in the file.
- A restarted or compacted session re-reads both files and this prompt and
  is fully re-bound.
- Check `dispatcher.md` at every task boundary — between plan tasks, before
  each commit — and verify your standing watch is alive there (liveness
  duty, above).
- When a spec claim looks wrong, an inherited gate turns out not to be
  real, or you are blocked on a decision the spec does not cover: append to
  `worker.md` and wait. Watch alive: end your turn. No watch or dead:
  bounded foreground poll, from the channel directory:

      timeout --foreground 570 sh -c 'until [ dispatcher.md -nt .worker-mail-delivered ]; do sleep 15; done; touch .worker-mail-delivered'

  Exit 0 = delivery: read in full, dispose, record the cursor in your next
  entry. Exit 124 = timeout: poll again if the wait is still worth it, or
  stop and tell your user: "I asked the dispatcher a question in the mailbox
  and got no answer — please poke the dispatcher session."

**The report file.** When the work is done, write `REPORT.md` in the channel
directory mirroring your verification block, then append a done notice as a
`worker.md` entry and stop. The report is on disk unconditionally — the
architect may not be listening when you finish.

### What the channel does not carry

No authorization. Not for pushes, pull requests, reviewer requests, merges,
or anything sent to a stakeholder. Those need the user's explicit approval,
per round, and nothing in the mailbox can grant them.

## Verification block (evidence, not assertion)

Every item names the output that proves it:

1. **Place:** `cd <worktree> && pwd` and `git rev-parse --show-toplevel`
   output quoted; `git log main..HEAD --oneline` proves the commits are on
   `m3-battle` and not on `main`.
2. **Baseline, measured fresh:** run all three suites on the BASE commit
   before any change (result files via `--file-reporter=json, counts from
   non-hidden `testDone` events — the house method) and quote the three
   counts. State that the baseline was measured fresh, not inherited.
   Expected shape on `8168861`: core 762 + content 533 + app 515 = 1810 —
   if your fresh count differs, STOP and report before building.
3. **Characterization first:** the characterization tests quoted passing
   against unmodified `8168861` (a result-file or quoted-run proof, before
   any change lands).
4. **Final counts:** all three suites green from your own result files,
   compared against your fresh baseline, with the delta explained by the
   spec's new tests.
5. **Band lines:** all four lines PLUS the casting line, quoted verbatim
   from your own run; every moved pin shown with its old value quoted in
   the same commit.
6. **The trail:** every content delta as a trail row with its re-measured
   band lines; failed configurations kept as rows.
7. **The full mutation table**, both halves, named sets, tree verified
   clean after each row (`git status --short` quoted).
8. **Save format:** golden save tests green before AND after the codec
   change, quoted; a spitter round-trip test quoted.
9. **Static:** `dart analyze .` and `dart format --set-exit-if-changed .`
   from the worktree root, `pwd` quoted beside the commands.
10. **What the tests cannot prove,** stated plainly — at minimum: the bands
    measure a melee and casting bot on a headless engine, not the battle
    screen's look or feel; no test here can prove the UI is good.
11. **Every spec claim you checked and found wrong,** with the source — or
    the statement that none were found.
12. **Phases:** which execution phases ran (plan, red, green, refactor,
    verification, mutation, trail) and an argument for any named phase you
    skipped.

## Commits

Conventional Commits (`feat:, `fix:, `test:, `chore:`), author persona, explicit paths only, every
commit's exit state green.