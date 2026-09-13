# Build prompt — m3-battle-flow (story M3BF)

You are the worker session for the unit `m3-battle-flow`. This prompt is
your binding instruction set. Read it in full before doing anything beyond
the first two commands.

## Start here

1. First command: `cd /var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/.worktrees/m3-battle-flow && pwd` — confirm the output names the worktree path. The worktree is **already created** on branch `m3-battle-flow` off `main` @ `6a1500a` — do NOT create it, do NOT create a branch. The sibling worktree set is otherwise empty; the parent repository at `/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg` is on `main` and must receive no commits from you. A commit landing in the parent repo is a real, observed failure mode — run `git rev-parse --show-toplevel` and confirm it names the worktree before your first commit. Prefer git invocations typed after a confirmed `cd` into the worktree; never `git -C`.
2. Start your standing mailbox watch (next section) BEFORE reading further.
3. Baseline: `main` @ `6a1500a` is 1941 green (core 828, content 550, app 563 — verified post-merge by the architect at `594bc80`; the `6a1500a` delta is a `.gitignore` line only). Suites run PER PACKAGE DIRECTORY: `cd packages/core && flutter test`, same for `content` and `app` — there is NO root pubspec and `flutter test packages/<pkg>` from the repo root fails with "No pubspec.yaml". Measure your own fresh baseline on unmodified `6a1500a` before changing anything and state the counts in your kickoff entry.

## Your standing watch — start it now, before the spec

Does your harness offer a way to run a background task that re-invokes this session when the task exits (an agent-launched background command, by whatever name)? Evaluate this against your own tool list — nobody else resolves it for you. If yes, start the watch as your harness's background task (this is the worker watch; keep it for the whole unit):

    /var/home/dhemas/Development/Projects/fiatcode/ai-stack/shared/skills/flow-mailbox/scripts/mailbox watch --as worker --dir /var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/handoff/m3-battle-flow

On a wake: restart the watch FIRST (same command), then read `dispatcher.md` in full and dispose of the new entry — if it changes the task, stop and adjust; if it locks or corrects a decision, follow it from here on; otherwise acknowledge it in your next `worker.md` entry and keep building. While this watch is standing and VERIFIED alive (process exists, older than 30 seconds — verify it, do not recall it), a blocked moment ends your turn instead of a foreground wait; dead or unverifiable means you are on the floor: say so in your next entry and rely on boundary checks plus the wait below until a relaunch proves stable. If the shell is fish or anything non-POSIX, wrap the command in `bash -c '...'`.

If your harness has NO such background capability, you are on the floor: check `dispatcher.md` at every task boundary and use the blocked wait (below) whenever you must wait for an answer.

## The work, in one paragraph

The battle interaction is rebuilt from playtest verdicts V1/V2/V8/V9 (locked D97/D98, spec rulings ratified by the user): the dim "N turns out" strip becomes NOW/IN-N turn-order chips on a translucent dark backing panel covering the whole dock header; every action (attack included) arms first from the skill bar and its legal targets are marked on stage cards and the map, a marked-card tap applies the action, the bump-attack on a bare card tap retires in favor of an enemy info panel, map tap-to-attack retires into the watched-refusal branch; a core wait verb (`WaitAction`) lets the hero hold ground in any fight while the world ticks; and the status line gains a two-state glyph (eye = watched, crossed marks = engaged) beside the word. Measurable effect: every action in a fight is two taps, the dock reads over any map tile, watched vs engaged are distinguishable at a glance, and waiting is a real option. App-side except one no-op core verb + one event; nothing bot-visible moves.

## The spec and the recon

- Spec (contract): `/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/m3-battle-flow-spec-M3BF.md`
- Recon (background — read when a spec claim looks wrong): `/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/m3-battle-flow-recon.md`
- The ledger's traps and conventions: `/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/CLAUDE.md` at the repo root (worktree copy is identical).
- NEVER commit anything under `docs/`. Your plan document goes in `docs/plans/` and stays UNCOMMITTED — the architect commits the plan doc when the PR opens.

## Be adversarial about the spec

Attack these claims by measurement before you build; disagreeing in the open is expected behavior, not a nuisance — a worker has caught real architect errors in seven separate units:

1. "The bump-attack has exactly two dispatch sites" — the `directionTo` branch in `_onTileTapped` and the adjacent branch of `_onStageCardTapped`. Re-grep and PROVE there is no third path that can swing at a monster (auto-walk stepping into a monster included — what does the engine do when an auto-walk path ends at a monster?).
2. "Attack's legal targets are orthogonally adjacent monsters." Verify the geometry end to end: does `directionTo` reach diagonal tiles, and can the CURRENT map bump-attack strike diagonally while the card gate cannot? If the two surfaces disagree today, that is a finding, not a thing to paper over — report it with the source lines before choosing the armed-attack target set.
3. "The wait verb changes nothing bot-visible." The bands are the instrument — but ALSO check: does anything in the content bot's step loop construct actions from an exhaustive switch over `GameAction` that a new subtype would break to compile-silently wrong behavior?
4. "NOW chip = `upNext.first` is clock-correct." Check `scheduleMonsterTurns` and the `upNext` getter (hero energy − actCost replay) against the D86 formula; the arrival chips' counts and the NOW chip's owner must agree with what the engine actually does after a wait.
5. "The armed-state widening breaks no invariant." Enumerate every consumer of `armedSpellId` (getters, `copyWith`-shaped rebuilds, tests) before changing its shape; the armed lifecycle pins at `game_bloc_test.dart` ~:2039 are the tripwire.

Pre-declare EVERY intended shape deviation (naming, widget structure, enum vs sentinel, sheet vs dialog) in `worker.md` and wait for my ack on holds before building the affected piece. A worker pre-declaring nothing all unit is normal; a worker silently deviating is not.

## Method

- Strict TDD, characterization first: write the tests that pin what this unit FLIPS (far-tap sentence, bump-on-bare-tap, strip texts, Engaged suffix, non-caster-no-bar, map-tap-to-attack, watched-refusal reuse) and run them GREEN against unmodified `6a1500a` before any change. If they do not pass there, your understanding of current behavior is wrong — stop and report, do not work around.
- Then build. Every commit's exit state is green — no reviewable unit left red. Existing text pins move only in the commit that moves them, old values quoted in that commit's message.
- A written plan first (`flow-writing-plans` shape): this unit is well past thirty changed lines with real logic. Then execute test-first. The plan document lives at `docs/plans/2026-09-03-m3-battle-flow.md`, uncommitted.
- Save-copy ritual: if the AVD pass touches a device that holds saves, copy BOTH save slots aside first and verify checksums — treat it as mandatory before ANY install; prefer the emulator (`-s emulator-5554`) and never install to or uninstall from a phone.

## Mutation table (from the spec; extend by measurement)

| Row | Mutation | Expected named reds |
|---|---|---|
| M1 | wait's monster-phase fall-through removed | the ranged-shoots-a-waiting-hero test + the clock tests |
| M2 | the monster-tile map gate reverted | the map-tap-attack-retired test |
| M3 | the stage-card target mark removed | the marking test |
| M4 | chip order/words reverted | the chip test |

Run every row, report the WHOLE table (greens included), name the reddened tests — reds are a NAMED SET, never a count. Revert after each; prove the tree clean after the last revert. Pre-flip rows (characterization reds against `594bc80`/`6a1500a` behavior) belong in the report too, named.

## The mailbox — the only channel, both directions

Printing is not replying: your ordinary output reaches nobody. All conversation goes through the channel directory `/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/handoff/m3-battle-flow/` — you append entries to `worker.md`, you read answers from `dispatcher.md`. Every write goes through the tool; there is NO by-hand write path (no edits, no redirections, no heredocs into the files):

    /var/home/dhemas/Development/Projects/fiatcode/ai-stack/shared/skills/flow-mailbox/scripts/mailbox append --as worker --dir <channel> --disposed-through <N|none> [--file <path>]
    /var/home/dhemas/Development/Projects/fiatcode/ai-stack/shared/skills/flow-mailbox/scripts/mailbox check  --as worker --dir <channel>
    /var/home/dhemas/Development/Projects/fiatcode/ai-stack/shared/skills/flow-mailbox/scripts/mailbox wait   --as worker --dir <channel> [--timeout 570]

(The same binary also has `init` and `watch` forms, shown above.) Entries look like:

    ## <seq> — worker — <timestamp>
    <body>

    disposed through dispatcher entry <N>

Rules that are not negotiable: the timestamp is the tool's, never hand-typed; the cursor (`disposed through`) names the last dispatcher entry you have dealt with, `none` before there is one; "new mail" is a sequence-number comparison against your own cursor, never a file timestamp; a body line must never be shaped like an entry header (indent any quoted `## ` line by one space); a refusal (exit 2) means nothing landed — fix the input and retry; a corrupt file (duplicated headers, stray delimiters) is a STOP — say so to your user, never repair by hand. When you ask a question: append it, then — standing watch verified alive? end your turn and let the wake resume you. No watch or a dead one? `mailbox wait --as worker --dir <channel>`; exit 0 = delivered (read `dispatcher.md` in full, dispose, record the new cursor in your next entry), exit 124 = the window closed quiet — wait again if it is still worth it, else stop and tell your user: "I asked the dispatcher a question in the mailbox and got no answer — please poke the dispatcher session." Write to the mailbox when a spec claim looks wrong, an inherited gate turns out not to be real, or you are blocked on a decision the spec does not cover; otherwise decide, proceed, and report at the end. Check `dispatcher.md` at every task boundary (between plan tasks, before each commit) even with the watch alive — and re-verify the watch's liveness at those boundaries too (older than one 30-second tick, or you are on the floor). Closing: when the unit closes, stop RESTARTING the watch and let the final instance expire on its timeout; a kill claim needs the kill's confirmed result, else report "left to expire".

Append your kickoff acknowledgment as your entry 1 (worktree confirmed, watch status, fresh baseline counts), then begin.

## What you must NOT do

- No pushing, no pull requests, no reviewer requests, no merging, no replies to any review thread, no issue or tracker writes. The architect owns every external write, on the user's explicit approval, per round.
- No commits under `docs/` (the plan doc in `docs/plans/` stays uncommitted; I commit it at PR time).
- No installs, uninstalls, or save pushes on ANY physical phone; the AVD pass pins the emulator serial. Save-copy ritual before any install.
- No golden re-pins, no band re-pins: the five band lines and the golden save documents are byte-identical CONTROLS. A moved band line is a stop-and-report, not a re-pin.
- Nothing outside the three packages: `packages/core`, `packages/content`, `packages/app` (plus your uncommitted plan file).

## Environment traps (restated verbatim from the ledger)

- Sandbox: `git -C <repo> <cmd>` does NOT match the sandbox exclusion patterns — always write git as `cd <repo> && git <cmd>`.
- `find` inside the Bash tool is bfs 4.1.1, not GNU findutils: `-newermt` takes ISO 8601 only; relative strings like `'15 minutes ago'` error (and read as empty with stderr suppressed). GNU find is at `/usr/bin/find`.
- Subagents dispatched into a git worktree do not inherit cwd — force an explicit `cd <worktree> && pwd` first or they commit in the parent repo.
- No fvm in this repo: plain `flutter` / `dart` (system Flutter 3.47.0).
- The ledger directory `docs/epic/` is gitignored — build sessions must never commit anything under `docs/epic/` and cite its files by absolute path.
- Commits use the personal persona.
- Device nodes are hidden inside sandboxed Bash: `/dev/kvm` reads as missing while it exists on the host — hardware probes lie under sandbox. Emulator, adb, and `flutter run` need unsandboxed commands (permission prompt; a `--bg` session stalls on it silently).
- AVD `Pixel_10` exists (`emulator -list-avds`); `flutter emulators` and `flutter emulators --create` mishandle the installed ps16k system images — use the `emulator` binary directly.
- UPDATE 2026-08-20 (D8): `emulator`, `adb`, and device-facing `flutter` subcommands (`run`/`devices`/`emulators`/`install`/`attach`/`logs`/`drive`) are now sandbox-excluded — no prompt. Other hardware probes still lie.
- `git worktree add`/`remove` and deleting a worktree's `.claude` files fail under sandbox (EROFS on `.git/worktrees/`, "busy" on protected config paths) — run worktree lifecycle commands unsandboxed.
- `adb shell input swipe` at 400ms emits too few motion samples for Flutter's pan recogniser and looks like a broken pan; 1200ms pans correctly. Tooling artifact, not an app bug.
- The AVD's /data can sit at ~92% full (485M free) so a plain install fails with INSTALL_FAILED_INSUFFICIENT_STORAGE and a cache trim frees almost nothing. Resolution that worked: uninstall the OLD build — legal ONLY after BOTH save slots are verified copied aside with checksums — then install the new APK (~153,590,984 bytes).
- Restoring device saves via /data/local/tmp push + `run-as cp` fails ENOENT under the app domain (SELinux-shaped); stream the bytes through `run-as stdin` instead.
- A physical phone may be attached alongside the AVD: pin every adb and flutter command to the emulator serial (`-s emulator-5554`); never install to or touch the phone.
- Device saves are playtest state: before pushing any acceptance save to the emulator, copy `save.json` AND `save-previous.json` aside (`run-as … cat > /tmp/…`) and restore after.
- `flutter install` can DESTROY the app's whole data directory: it prints "Uninstalling old version..." and may then fail on a missing APK, leaving no app and no data. The copy-aside ritual is mandatory before ANY install/uninstall, not only before pushing saves. The debug APK is ~153 MB; check emulator free space first.
- Cross-session message holds bite BOTH directions: keep exactly one architect session alive; the BUILD-REPORT.md mirror is the working fallback; expect to relay by hand when the worker runs interactive.
- `find.textContaining` in Flutter 3.47 is case-sensitive with no `caseSensitive` parameter — match the literal casing or use a regex.
- `scrollUntilVisible` computes ONE moveStep from the axis direction, so it can never scroll back up — assertion sequences on a long screen must be monotonic in document order.
- This monorepo has NO root pubspec.yaml — `flutter test packages/<pkg>` from the repo root fails; run suites per package directory (`cd packages/<pkg> && flutter test`).

## Verification block (evidence, not assertions — mirror it into REPORT.md)

1. `cd <worktree> && pwd` output; `git rev-parse --show-toplevel` names the worktree; `git log --oneline main..m3-battle-flow` — the commits exist on no other branch; the parent repo untouched.
2. Test counts read from result files, compared against a FRESHLY MEASURED baseline on unmodified `6a1500a` — state which. Suites per package directory, exits 0.
3. The characterization proof: green runs against unmodified `6a1500a`, before the first change commit.
4. The full mutation table, both phases, named reds AND greens, reverts proven (tree clean after the last).
5. The five band lines verbatim from your own content-suite run — byte-identical to: crypt 16/40 (40.0%) `{1:1,2:9,3:8,4:6,5:16}`, casting 40/40, greedy 16 / fleetfoot 13, sea-cave 26/40 (65.0%), ruined keep 24/40 (60.0%). A moved line is a stop-and-report.
6. `dart analyze .` and `dart format --output=none --set-exit-if-changed .` from the WORKTREE ROOT, pwd quoted.
7. AVD pass evidence: shots of the chips, backing, target outlines, and the glyph in both states, read in pixels; greyscale variants for the author's eye; the save-aside checksums if any install happened.
8. What the tests cannot prove — stated plainly.
9. Every spec claim you checked and found wrong, with the source.
10. Which execution phases ran, and why any named phase was skipped — a skip is an argument, not an absence.

Write `REPORT.md` in the channel directory at the end, append your done notice to `worker.md`, and stop. The report on disk is what survives if nobody is listening.