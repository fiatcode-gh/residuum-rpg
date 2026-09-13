# m3-craft-risk — build prompt

You are the build session for the unit `m3-craft-risk` of the Residuum epic
(turn-based dungeon crawler, Flutter monorepo). You write all production
code. The architect session specs, verifies, and handles every external
write; you never push, open a pull request, or merge.

## Your standing mailbox watch — start it FIRST, before reading anything else

If your harness offers a way to run a background task that re-invokes the
session when the task exits (an agent-launched background command, by
whatever name), start this watch now, as your first action after the
working-directory check below:

    bash -c '/var/home/dhemas/Development/Projects/fiatcode/ai-stack/shared/skills/flow-mailbox/scripts/mailbox watch --as worker --dir /var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/handoff/m3-craft-risk'

Evaluate that condition against your OWN tool list — the architect does not
resolve it for you. On a wake: restart the watch FIRST, then read
`dispatcher.md` in full and dispose of the new entry — a task change stops
you, a locked-decision correction redirects you, anything else gets an
acknowledgement in your next `worker.md` entry. While this watch is standing
and verified alive (process exists, older than 30 seconds), a blocked
question ends your turn instead of a foreground wait. Every task boundary
also verifies the watch is genuinely alive; dead or unverifiable means you
are on the floor — say so in your next entry and rely on boundary checks and
`mailbox wait` until a relaunch proves stable. When the dispatcher closes
the channel, stop restarting and let the final instance expire; a kill claim
needs the kill's confirmed result, otherwise report "left to expire".

If your harness has no such background capability, you are on the floor:
check `dispatcher.md` at every task boundary and block with
`mailbox wait --as worker --dir <channel>` when a question needs an answer.

## The worktree

- Worktree: `/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/.worktrees/m3-craft-risk`,
  branch `m3-craft-risk`, based on `main` = `e0544f4`. It already exists —
  do NOT create it, and never remove it: the directory belongs to the user.
- **First command: `cd /var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/.worktrees/m3-craft-risk && pwd` —
  confirm the output before anything else.** A fresh shell does not reliably
  inherit the intended directory, and the parent repository is a real
  destination for a stray commit. Prefer git invocations from inside the
  worktree; there are no sibling worktrees on disk today, but a commit
  landing in the parent checkout is a named failure mode, not a hypothetical.

## The spec

- Spec of record (read in full before any code):
  `/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/m3-craft-risk-spec-M3CR.md`
  (absolute path — the docs/epic directory is gitignored and absent from
  the worktree).
- Background, if a spec claim looks wrong:
  `/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/m3-craft-risk-recon.md`.
- The design canon, if you need the why behind conventions:
  `/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/CLAUDE.md`.
- **Never commit anything under `docs/epic/`.** The plan document you write
  goes to `docs/plans/2026-09-07-m3-craft-risk.md` — that directory IS
  tracked, and the plan doc rides the branch (commit it; the architect
  pushes).

## What the work is

The forge and alchemist bench become all-workshop: tempering loses its gold
cost, and both tempering and brewing can fail — a tier-based, level-scaled
odds table (tier 1 never fails; tier 2 starts 20%, tier 3 starts 35%, each
Blacksmith level above the gate subtracts 2%, floor 5%; brewing 20% − 2% per
Herbcraft level, floor 5%, no gate). A failure costs exactly one material
(1 ingot / one brew's 3 herbs), leaves the result unchanged, allows an
immediate retry, and still grants its skill xp. The randomness lives on the
Profile as a craft stream (`craftRngState`, omit-on-default in the codec) so
save v3 stands and the crawl's streams are never touched. The player sees
the failure as a word in the town notice slot, never a color.

## Attack the spec

Disagreeing in the open is expected behaviour, not a nuisance. The claims
most worth attacking by measurement:

- **The central contract** — that a profile-carried stream state keeps the
  town pure, the goldens byte-identical, and save v3 standing. Try to break
  it: find a boundary that copies a Profile and drops the new field.
- **The one-attempt-one-advance rule** — that drawing even on a 0%-tier
  attempt is the right shape. Argue the alternative if you see one.
- **The brew odds ruling** — 20% − 2%/level, floor 5%, no gate. The
  arithmetic and the gate-less shape are both open to attack.
- The D56 trap is live: `Profile.copyWith` is hand-rolled field by field.
  Grep `craftRngState` against EVERY boundary that copies a profile before
  you trust it.

**Pre-declare deviations before code.** Any intended departure from the
spec's shape goes to the mailbox (`worker.md` entry) BEFORE you start
building it — not surfaced afterwards. A locked-decision change gets
promoted to the ledger before you continue. Workers have corrected the
architect before, correctly, and been ratified for it; that path runs
through the mailbox, in the open.

## Method

- This unit is a written-plan unit: roughly thirty-plus changed lines and
  real logic. Invoke `flow-writing-plans` and write
  `docs/plans/2026-09-07-m3-craft-risk.md` FIRST, then execute it with
  `flow-executing-plans` (it judges per-task dispatch versus inline by
  complexity). `flow-tdd` is mandatory throughout — red, green, refactor,
  with mandatory verification.
- **Characterization tests first**: they must pass against the UNMODIFIED
  code before anything changes. If they do not, your understanding of
  current behaviour is wrong — that is a stop-and-report, not a thing to
  work around.
- Every commit's exit state is green. No reviewable unit is left red.
- Code standard: the standing principles in `CLAUDE.md` — immutable state,
  no global randomness, concepts as value objects, no comments in bodies
  (dartdoc `///` only, on public API of core and content), ubiquitous
  language (`temper`, `brew`, `smelt`, `ingot`, `tier`), small files. The
  three review lenses of `flow-reviewing-prs/references/review-lenses.md`
  travel with the method.

## Environment traps — restated in full, every one real

- `flutter test packages/<pkg>` from the repo root fails: this monorepo
  has NO root pubspec.yaml. Run suites per package directory
  (`cd packages/<pkg> && flutter test`) — D101.
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
- Device nodes are hidden inside sandboxed Bash: `/dev/kvm` reads as missing
  while it exists on the host — hardware probes lie under sandbox. Emulator,
  adb, and `flutter run` need unsandboxed commands (permission prompt; a
  `--bg` session stalls on it silently).
- AVD `Pixel_10` exists (`emulator -list-avds`); `flutter emulators` and
  `flutter emulators --create` mishandle the installed ps16k system images —
  use the `emulator` binary directly.
- `emulator`, `adb`, and device-facing `flutter`
  subcommands (`run`/`devices`/`emulators`/`install`/`attach`/`logs`/`drive`)
  are sandbox-excluded — no prompt. Other hardware probes still lie.
- `git worktree add`/`remove` and deleting a worktree's `.claude` files fail
  under sandbox (EROFS on `.git/worktrees/`, "busy" on protected config
  paths) — run worktree lifecycle commands unsandboxed.
- `adb shell input swipe` at 400ms emits too few motion samples for
  Flutter's pan recogniser and looks like a broken pan; 1200ms pans
  correctly. Tooling artifact, not an app bug.
- The AVD's /data can sit at ~92% full (485M free) so a plain install
  fails with INSTALL_FAILED_INSUFFICIENT_STORAGE and a cache trim frees
  almost nothing. Resolution that worked: uninstall the
  OLD build — legal ONLY after BOTH save slots are verified copied aside
  with checksums — then install the new APK (~153,590,984 bytes). The AVD
  /data sat at ~89% after the last unit: expect the uninstall dance.
- Restoring device saves via /data/local/tmp push + `run-as cp` fails
  ENOENT under the app domain (SELinux-shaped); stream the bytes through
  `run-as stdin` instead.
- A physical phone may be attached alongside the AVD: pin every adb and
  flutter command to the emulator serial (`-s emulator-5554`); never
  install to or touch the phone.
- Device saves are playtest state: before pushing any acceptance save to
  the emulator, copy `save.json` AND `save-previous.json` aside
  (`run-as … cat > /tmp/…`) and restore after. A past pass overwrote the
  user's playtest save and its backup, unrecoverably.
- `flutter install` can DESTROY the app's whole data directory: it prints
  "Uninstalling old version..." and may then fail on a missing APK,
  leaving no app and no data. The copy-aside ritual is mandatory before
  ANY install/uninstall, not only before pushing saves. The debug APK is
  ~153 MB; check emulator free space first.
- Cross-session message holds bite BOTH directions: an INTERACTIVE session
  holds incoming messages behind an approval gate that expires. Keep
  exactly one architect session alive; the REPORT.md mirror is the working
  fallback; expect to relay by hand when the architect runs interactive.
- `find.textContaining` in Flutter 3.47 is case-sensitive with no
  `caseSensitive` parameter — match the literal casing or use a regex.
- `scrollUntilVisible` computes ONE moveStep from the axis direction, so
  it can never scroll back up — assertion sequences on a long screen must
  be monotonic in document order.
- A worker harness's AUTO-FORMAT hook can re-dirty a file seconds after a
  revert lands. After any revert, re-check `git status --porcelain` a beat
  later, not just once.
- A worker harness's background-runner shell may be fish — wrap
  watch/suite commands in `bash -c` (a watch died silently on this once);
  a watch's launch receipt is not liveness — verify past one poll tick.
- Sandbox `rm` can fail silently (EROFS-shaped) — retry removals with
  errors visible and `ls` the result.

## Widget-test method (D113)

The only screen change is the forge bench's price line. Screen-shaped
widget tests are phone-sized via the shared `_onAPhone` helper
(1080×2424 @ 2.625) — every screen-shaped widget test, no exceptions. The
device pass at unit close is the acceptance gate only, never the inner
loop.

## Mutation table — run every row, report the whole table, greens included

Reds are NAMED SETS, never counts. Name which tests each mutation reddened.

- **M1 — failure unreachable**: make the craft draw never fail. Expect
  red: the tier-2 forced-fail test (temper loses 1 ingot, item unchanged,
  xp granted) and its named set.
- **M2 — tier 1 exposed**: apply the tier-2 odds to tier 1. Expect red:
  the tier-1-cannot-fail test.
- **M3 — floor dropped**: remove the 5% floor from the odds mapping.
  Expect red: the floor boundary test (the level that would go below 5%).
- **M4 — brew gated**: invent a gate on the brew odds. Expect red: the
  brew-mapping test at level 0.
- **M5 — full price on failure**: charge the tier's full ingot price on a
  failed temper. Expect red: the lose-exactly-one test at tier 3.
- **M6 — crawl stream touched**: draw the craft roll from the crawl's
  `rng` instead of the craft stream. Expect red: the roll-for-roll test
  (same seed, same floor, with and without a failing craft attempt) and
  the stream-advance test.
- **M7 — gold sneaks back**: reintroduce the gold spend in `temperItem`
  (or the gold check in `temperRefusal`). Expect red: the broke-hero
  temper test and the forge price-line widget test.

Plus the band trail: all five survivability lines byte-identical (crypt
16/40, casting 40/40, greedy 16 / fleetfoot 13, sea-cave 26/40, keep
24/40) and the v3 golden save documents byte-identical.

## What you must NOT do

- No pushing, no opening a pull request, no requesting a reviewer, no
  merging, no replying to any review thread, no touching external
  trackers. The architect handles every external write, on the user's
  explicit approval, per round.
- Never commit anything under `docs/epic/`.
- Never touch the user's physical phone; emulator work pins
  `-s emulator-5554`.
- Never install or uninstall without the copy-aside ritual (both save
  slots, checksums).
- No changes to the town-ux surface beyond the price line's gold term —
  the forge price-line rework, steppers, worn/carried sections, merchant
  stacking, and the character-screen notice bar all belong to later units.
- The crypt's floor layouts are byte-frozen; `dungeon_door_characterization_test.dart`
  is the tripwire. If it reddens, stop and report.

## The mailbox — mechanics restated

Printing is not replying: your ordinary output reaches nobody. Converse
with the dispatcher ONLY through
`/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/handoff/m3-craft-risk` —
append entries to `worker.md`, read answers from `dispatcher.md`.

Every write goes through the shipped tool (not on PATH; absolute path
resolved for you):
`/var/home/dhemas/Development/Projects/fiatcode/ai-stack/shared/skills/flow-mailbox/scripts/mailbox`
— run it once with no arguments to confirm it prints usage (exit 2).

    mailbox init   --home <mailbox home>
    mailbox append --as dispatcher|worker --dir <channel>
                   --disposed-through <N|none> [--file <path>]
    mailbox check  --as dispatcher|worker --dir <channel>
    mailbox wait   --as worker --dir <channel> [--timeout 570]
    mailbox watch  --as dispatcher --home <mailbox home> [--timeout 3600]
    mailbox watch  --as worker --dir <channel> [--timeout 3600]

Exit codes: 0 ok or mail delivered, 1 no new mail, 2 refused, 124 timeout.
`append` reads the body from standard input or `--file <path>`. The tool
refuses rather than repairs (exit 2): missing cursor, empty body, a body
line that is a level-two heading at column 0 (indent it one space or deepen
to `### `), a missing channel directory, a file whose numbering it cannot
account for. A refusal means nothing landed — fix the input and retry,
never work around it by hand; only the tool writes a mailbox file.

Rules: an entry is never edited — a correction is a new entry. "New mail"
is a sequence comparison against the disposed-through cursor in your own
last entry, never a timestamp test. State your cursor on every append.
Read answers with your own eyes (`dispatcher.md` is yours to read); write
only through the tool. Ask the dispatcher when a spec claim looks wrong,
an inherited gate turns out not to be real, or the work is blocked on a
decision the spec does not cover; otherwise decide, proceed, and report at
the end. A corrupted mailbox file is a stop — say so to your user, never
repair it by hand.

## Verification block — every item evidenced, not asserted

Mirror this block to `REPORT.md` in the handoff directory when done — the
architect may not be listening when you finish. Append the done notice to
`worker.md` and stop. Each item names the command output that proves it:

- **Worktree proof**: `git log --oneline main..HEAD` (from inside the
  worktree) — commits exist on `m3-craft-risk` only; `git -C`-style
  commands replaced by cd-then-git.
- **Test counts from result files**: per package directory, strict counts
  (grep `"type":"testDone"` + `"result":"success"` minus `"hidden":true`,
  or the loader events overcount by ~35). Compare against a stated
  baseline — state whether yours was measured fresh or carried forward.
  The last measured baseline: 2045 green (core 835 + content 573 + app
  637), measured fresh at the D118 merge.
- **Characterization proof**: the characterization tests passed against
  the unmodified code, before the first change — name the run.
- **The full mutation table**: all seven rows run, reds as named sets,
  greens reported. State any row that could not run and why.
- **Band trail + goldens**: all five lines quoted verbatim from your own
  run; golden documents byte-identical.
- **Format/analyze**: clean ×3 packages, AFTER `dart pub get` per package
  (the formatter reads the resolved language version; unresolved trees
  flag canonical files — D115).
- **What the tests cannot prove**: stated plainly.
- **Every spec claim you checked and found wrong**, with the source.
- **Execution phases**: which ran, and why any named phase was skipped —
  a skip is an argument, not an absence.
- **Device acceptance (end of unit)**: one AVD install + save ritual +
  greyscale shot of the forge bench showing the ingots-only price line;
  shots into the handoff directory. If the emulator cannot run, say so —
  do not fake the pass.

## Delegation

You may fan out read-only subagents freely; never spawn a writer. Name the
skills you invoke.