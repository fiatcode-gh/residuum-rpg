# Build prompt — m3-save-hardening (story M3SH)

You are the worker session for the unit `m3-save-hardening`. This prompt is
your binding instruction set. Read it in full before doing anything beyond
the first two commands.

## Start here

1. First command: `cd /var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/.worktrees/m3-save-hardening && pwd` — confirm the output names the worktree path. The worktree is **already created** on branch `m3-save-hardening` off `main` @ `d2b78be` — do NOT create it, do NOT create a branch. The sibling worktree set is otherwise empty; the parent repository at `/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg` is on `main` and must receive no commits from you. A commit landing in the parent repo is a real, observed failure mode — run `git rev-parse --show-toplevel` and confirm it names the worktree before your first commit. Prefer git invocations typed after a confirmed `cd` into the worktree; never `git -C`.
2. Start your standing mailbox watch (next section) BEFORE reading further.
3. Baseline: `main` @ `d2b78be` is **1974 green** (core 835, content 550, app 589 — verified post-merge by the architect; the tree is content-identical to the verified `bf8bcb6` after the D107 re-squash). Suites run PER PACKAGE DIRECTORY: `cd packages/core && flutter test`, same for `content` and `app` — there is NO root pubspec and `flutter test packages/<pkg>` from the repo root fails with "No pubspec.yaml". Measure your own fresh baseline on unmodified `d2b78be` before changing anything and state the counts in your kickoff entry.

## Your standing watch — start it now, before the spec

Does your harness offer a way to run a background task that re-invokes this session when the task exits (an agent-launched background command, by whatever name)? Evaluate this against your own tool list — nobody else resolves it for you. If yes, start the watch as your harness's background task (this is the worker watch; keep it for the whole unit):

    /var/home/dhemas/Development/Projects/fiatcode/ai-stack/shared/skills/flow-mailbox/scripts/mailbox watch --as worker --dir /var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/handoff/m3-save-hardening

On a wake: restart the watch FIRST (same command), then read `dispatcher.md` in full and dispose of the new entry — if it changes the task, stop and adjust; if it locks or corrects a decision, follow it from here on; otherwise acknowledge it in your next `worker.md` entry and keep building. While this watch is standing and VERIFIED alive (process exists, older than 30 seconds — verify it, do not recall it), a blocked moment ends your turn instead of a foreground wait; dead or unverifiable means you are on the floor: say so in your next entry and rely on boundary checks plus the wait below until a relaunch proves stable. If the shell is fish or anything non-POSIX, wrap the command in `bash -c '...'`.

If your harness has NO such background capability, you are on the floor: check `dispatcher.md` at every task boundary and use the blocked wait (below) whenever you must wait for an answer.

## The work, in one paragraph

The save pipeline stops failing silently (audit group 1, locked D102/D103/D108). The save write path reports failure to nobody — the discarded `save()` bool, the renames outside the failure handling, the poisonable autosave queue, hero creation advancing on a save that did not land; boot is unguarded with a thrown-read fallback bypass and no failure screen; the decoder accepts engine-lethal and rule-breaking values (`speed: 0` loops the scheduler forever, `hp > maxHp`, out-of-range skill levels, assert-only `reach`, unbounded energy, and — per the user's D108 amended ruling — repeated item ids, now refused); `IoSaveFiles`, the only adapter touching real player data, is untested because its base directory is not injectable; the door-opening flow can hang on a silent refusal and double-fire on a double tap; and the TownViewState crawl fields are four nullable fields guarded by prose. The unit lands: a sealed notice type with save-write/resume-refusal variants, a boot failure screen with a Begin-fresh door, decode range checks in the house `SaveMalformed` style, an engine-boundary guard (a `step` ArgumentError becomes a refusal), temp-directory coverage of `IoSaveFiles`, a door in-flight guard, the sealed crawl value, and the two test-hygiene riders (deep-decoder totality fixtures; `SavedHero` invariant tests). Save format stays **v3**; no golden document and no band line may move.

## The spec and the recon

- Spec (contract): `/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/m3-save-hardening-spec-M3SH.md`
- Recon (background — read when a spec claim looks wrong): `/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/m3-save-hardening-recon.md`
- Conventions: `/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/CLAUDE.md` at the repo root (worktree copy is identical).
- NEVER commit anything under `docs/epic/` or `docs/reports/` (both gitignored — cite them by absolute path only). Your plan document goes in `docs/plans/` and stays UNCOMMITTED — the architect commits it when the PR opens.

## Be adversarial about the spec

Attack these claims by measurement before you build; disagreeing in the open is expected behavior, not a nuisance — workers have caught real architect errors across this epic:

1. "Every golden passes every proposed check." Re-verify each golden value against each new check yourself (speed, energy, hp, levels, ids, reach). A check that would move a pinned golden or band is a STOP-AND-REPORT, not a clamp.
2. The energy bound's arithmetic and the proposed bound of 1000: E/actCost is the worst-case turn count per monster. Sweep the content tables for the REAL maximum monster energy; if any legal monster can exceed the bound, the bound is wrong — report with sources before picking the value.
3. "A thrown read is reachable." `IoSaveFiles.read` maps `FileSystemException` to null already; the throw paths are `_path`'s `getApplicationDocumentsDirectory()` and whatever `existsSync`/`readAsString` can raise outside the caught type. Determine what can ACTUALLY throw, and whether `_readable`'s try belongs there or the adapter's read-null contract is the whole fix. If you conclude the store-side guard is dead code, say so before building it.
4. The door reentrancy timing window was never reproduced on device (audit said "verified statically"). Try to reproduce it by test (the silent-refusal + later-unrelated-emission sequence is testable at the bloc/widget level); if you cannot, prove the guard by the test you CAN write and say what remains unproven.
5. "Refuse-to-advance strands no one." Read the roster flow (`main.dart:_rosterChose`, the roster screen) and state what state the user is left in when a create/switch save fails — is there a way forward, or does the refusal need its own notice sentence saying what DID happen?
6. Profile-side hp check: the recon claims `decodeProfile` rebuilds maxHp from the baseline so `hp ≤ maxHp` is checkable there. Verify by reading `profile_codec.dart` — if maxHp is read from the document instead, the profile check needs a different home, and that is a finding.
7. Duplicate-id refusal versus the version-gate snapshots: confirm the pre-v3 captured documents (which stop at the version gate) are unaffected by the new checks, and that the check sits AFTER the gate so the gate's refusal reason is unchanged.

Pre-declare EVERY intended shape deviation (naming, widget structure, sealed-variant shape, where a check lives) in `worker.md` and wait for my ack on holds before building the affected piece. A worker pre-declaring nothing all unit is normal; a worker silently deviating is not.

## Method

- Strict TDD, characterization first: write the tests that pin what this unit FLIPS (queue poisoning, thrown-read bypass, silent door refusal, speed-0 decode, the discarded bool) and run them GREEN against unmodified `d2b78be` before any change. If they do not pass there, your understanding of current behavior is wrong — stop and report, do not work around.
- The codec refusal fixtures (speed 0, hp > maxHp, bad level, bad reach, repeated id, bad energy — all as failing tests) are their OWN COMMIT before the codec change that makes them green. The codec-change commit quotes the refusal sentences.
- Every commit's exit state is green — no reviewable unit left red. Existing text pins move only in the commit that moves them, old values quoted in that commit's message.
- A written plan first (`flow-writing-plans` shape): this unit is well past thirty changed lines with real logic across two packages. Then execute test-first (`flow-tdd` shape). The plan document lives at `docs/plans/2026-09-03-m3-save-hardening.md`, uncommitted.
- Save-copy ritual: if the AVD pass touches a device that holds saves, copy BOTH save slots aside first and verify checksums — treat it as mandatory before ANY install; prefer the emulator (`-s emulator-5554`) and never install to or uninstall from a phone.

## Environment traps (restated from the ledger; all binding)

- `flutter test packages/<pkg>` from the repo root fails: this monorepo has NO root pubspec.yaml. Run suites per package directory (`cd packages/<pkg> && flutter test`) — D101.
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
- The AVD's /data can sit at ~92% full (485M free) so a plain install fails with INSTALL_FAILED_INSUFFICIENT_STORAGE and a cache trim frees almost nothing (M3F, 2026-09-01). Resolution that worked: uninstall the OLD build — legal ONLY after BOTH save slots are verified copied aside with checksums — then install the new APK (~153,590,984 bytes).
- Restoring device saves via /data/local/tmp push + `run-as cp` fails ENOENT under the app domain (SELinux-shaped); stream the bytes through `run-as stdin` instead.
- A physical phone may be attached alongside the AVD: pin every adb and flutter command to the emulator serial (`-s emulator-5554`); never install to or touch the phone.
- Device saves are playtest state: before pushing any acceptance save to the emulator, copy `save.json` AND `save-previous.json` aside (`run-as … cat > /tmp/…`) and restore after.
- `flutter install` can DESTROY the app's whole data directory: it prints "Uninstalling old version..." and may then fail on a missing APK, leaving no app and no data. The copy-aside ritual is mandatory before ANY install/uninstall, not only before pushing saves. The debug APK is ~153 MB; check emulator free space first.
- Cross-session message holds bite BOTH directions: an INTERACTIVE session holds incoming messages behind an approval gate that expires. Keep exactly one architect session alive; the REPORT.md mirror is the working fallback; expect to relay by hand when the architect runs interactive.
- `find.textContaining` in Flutter 3.47 is case-sensitive with no `caseSensitive` parameter — match the literal casing or use a regex.
- `scrollUntilVisible` computes ONE moveStep from the axis direction, so it can never scroll back up — assertion sequences on a long screen must be monotonic in document order.
- New-screen units size at least one widget test like a phone (`_onAPhone, 1080×2424 @ 2.625`) — the failure screen is a new screen.

## Mutation table (from the spec; extend by measurement, report greens too)

| Row | Mutation | Expected named reds | Expected green (control) | Why |
|---|---|---|---|---|
| M1 | Delete the speed check | the speed refusal test; the totality deep-decoder fixture | goldens; band suite | check is decode-only |
| M2 | Delete the id-uniqueness check | the uniqueness refusal test | goldens (all ids distinct); remove-one tests | golden ids never repeat |
| M3 | Delete the hp ≤ maxHp check | the hp refusal test | goldens (13/20, 5/12); band suite | golden hp is sane |
| M4 | Delete the level range check | the skill refusal test | goldens (max level 3) | golden levels sane |
| M5 | Move renames back outside the try | the rename-throw test on `save()` | verify-then-rotate tests | only the throw path changes |
| M6 | Delete the queue error sink | the poison characterization (flipped to fixed) | ordering tests; no-op emission tests | sink only touches the failure path |
| M7 | Revert `_rosterChose` to ignore the bool | the refuse-to-advance test | happy-path roster tests | gate only fires on false |
| M8 | Delete the boot guard try | the failure-screen widget test | boot happy-path tests | guard only on throw |
| M9 | Revert `_readable` to no try | the thrown-read fallback test | returned-null fallback tests | the two paths are distinct |
| M10 | Delete the step-boundary catch | the engine-boundary test (bloc emits refusal) | normal action tests | catch only on ArgumentError |
| M11 | Delete the door in-flight guard | the double-tap test | single-open tests | guard only on second event |
| M12 | Delete the resume-refusal emit | the door-refusal test | happy resume tests | notice only on refusal |
| M13 | Make `IoSaveFiles.read` throw again | the temp-dir read tests | store-level tests (they run on the fake) | adapter is below the seam |
| M14 | Collapse the sealed crawl value's camp variant | the table-driven carry test | boot/resume tests with legal shapes | only the illegal shape becomes representable |

Sequencing traps: the poison, thrown-read, and door characterizations describe TODAY's behaviour — write them first, watch them pass, then let the fix flip the assertion. M5 runs on the working tree before that piece lands and is reverted after — say so in the report. M1–M4 run BEFORE the codec change (they are the refusal-fixture commit's reds) — report the red sets at fixture time and the greens after.

## The mailbox — channel mechanics (verbatim rules)

Tool absolute path (resolve and keep it):

    /var/home/dhemas/Development/Projects/fiatcode/ai-stack/shared/skills/flow-mailbox/scripts/mailbox

Commands (exit codes: 0 ok/mail, 1 none, 2 refused, 124 timeout; append reads the body from stdin or `--file`):

    mailbox init   --home <mailbox home>
    mailbox append --as dispatcher|worker --dir <channel>
                   --disposed-through <N|none> [--file <path>]
    mailbox check  --as dispatcher|worker --dir <channel>
    mailbox wait   --as worker --dir <channel> [--timeout 570]
    mailbox watch  --as dispatcher --home <mailbox home>
    mailbox watch  --as worker --dir <channel> [--timeout 3600]

Rules, binding:

- Entry format (the tool writes it; em dashes are load-bearing): `## <seq> — <side> — <ISO timestamp>`, body, then `disposed through <other side> entry <N>` (or `none yet`). The tool stamps the clock — never hand-type a timestamp.
- "New mail" is a SEQUENCE COMPARISON against your own `disposed-through` cursor — never a file timestamp. State the cursor on every entry.
- Only the tool writes a mailbox file. No anchored edits, no editors, no redirections. A refusal means nothing landed — fix the input and retry. A file the tool cannot parse is a STOP: say so, do not repair by hand.
- No body line may be shaped like an entry header (`## `); indent a quoted header by one space.
- Entries are never edited — a correction is a new entry.
- **Printing is not replying.** Your ordinary output reaches nobody. Every question, pre-declared deviation, and notice goes through `mailbox append --as worker --dir <channel> --disposed-through <N|none>` into `worker.md`; you read answers from `dispatcher.md` in full.
- Mid-flight question: append to `worker.md`, then — if your standing watch is VERIFIED alive, end your turn (the wake resumes you); if dead or unverifiable, `mailbox wait --as worker --dir <channel>`; exit 0 → read and dispose; exit 124 → wait again if still worth it, else tell your user: "I asked the dispatcher a question in the mailbox and got no answer — please poke the dispatcher session."
- Check `dispatcher.md` at every task boundary — between plan tasks, before each commit.
- Write to the mailbox when: a spec claim looks wrong; an inherited gate turns out not real; the work is blocked on a decision the spec does not cover. Otherwise decide, proceed, and report at the end.

## What you must NOT do

- No pushing, no opening a pull request, no requesting a reviewer, no merging, no replying to any review thread, no touching external trackers, no `gh` commands. The architect handles every external write on the user's explicit approval, per round.
- No commits under `docs/epic/` or `docs/reports/`; the plan doc in `docs/plans/` stays uncommitted.
- No version bump on the save format; no edits to golden literals or band pins; no "repairing" clamps in the codec — refusals only.
- No changes to core `step`'s signature; no new `Random(` anywhere; no uninstall/install on any device without the copy-aside ritual.
- Subagents: read-only fan-out is free; never spawn a writer.

## Verification block (evidenced, not asserted — mirror to `REPORT.md`)

Each item names the command output that proves it. Include:

1. Proof of place: `cd <worktree> && pwd`, `git rev-parse --show-toplevel`, `git log --oneline main..HEAD` — commits on `m3-save-hardening` only, parent repo untouched, nothing under `docs/epic/`/`docs/reports/` committed.
2. Test counts read from result files, per package directory, against a stated baseline — say whether the baseline was measured fresh or carried forward.
3. Proof the characterization tests passed against UNMODIFIED `d2b78be` (the commits that carry them precede the fix commits; quote the run output).
4. The full mutation table — every row run, named red sets AND green controls, both halves reported. Rows that can only run before a piece lands: say when you ran and reverted them.
5. Goldens byte-identical: `git diff` over the golden literals is empty; all five band lines verbatim from your own content-suite run against the D79 pins: crypt 16/40 (40.0% BY RULING), casting 40/40 (informational), greedy 16 / fleetfoot 13, sea-cave 26/40, keep 24/40.
6. `dart analyze .` and format exit 0 from the WORKTREE ROOT, pwd quoted.
7. Refusal-fixture commit precedes the codec commit: `git log --oneline` excerpt.
8. What the tests cannot prove, stated plainly — at minimum: the door timing window's on-device reachability, real path_provider failure behaviour, and anything else you did not execute.
9. Every spec claim you checked and found wrong, with the source — even ones already handled in the mailbox.
10. Which execution phases ran (plan, characterization, refusal fixtures, build, mutation rows, AVD pass) and why any named phase was skipped — a skipped phase is an argument, not an absence.
11. AVD pass evidence: the failure screen with Begin-fresh, a save-failure notice, a resume-refusal notice, disabled door buttons while pending — each shot AND its greyscale variant, saved under `/tmp` and listed in the report (the architect mirrors them); state every deviation from the spec the shots reveal.
12. Pre-declared deviations: each with its dispatch-time mailbox entry number and my ack.

Report every spec claim you checked and found wrong with its source — the report is read LAST by the architect, after independent verification; discrepancies between your report and the architect's own instruments are resolved by re-measurement, and honest disclosure is the protocol, not a risk.