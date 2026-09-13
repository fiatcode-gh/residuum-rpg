# m3-town-ux — build prompt (story M3TUX)

Dispatched to a pi worker session over the unit mailbox
`docs/epic/handoff/m3-town-ux/`. Spec:
`/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/m3-town-ux-spec-M3TUX.md`
Recon (background, read if a spec claim looks wrong):
`/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/m3-town-ux-recon.md`

## Your watch — start it before anything else

If your harness offers a way to run a background task that re-invokes the
session when the task exits — an agent-launched background command, by
whatever name — start your standing mailbox watch NOW, before reading the
spec, before recon, before any work. You evaluate this condition against
YOUR OWN tool list; the architect does not resolve it for you.

    /var/home/dhemas/Development/Projects/fiatcode/ai-stack/shared/skills/flow-mailbox/scripts/mailbox watch --as worker --dir /var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/handoff/m3-town-ux

On a wake: restart the watch FIRST, then read `dispatcher.md` in full and
dispose of the new entry — if it changes the task, stop and adjust; if it
locks or corrects a decision, follow it from here on; otherwise acknowledge
in your next `worker.md` entry and keep building. While this watch is
standing and verified alive, a blocked worker ends its turn instead of
waiting in the foreground. **A claimed watch carries a liveness duty:** at
every task boundary verify the watch process is genuinely alive (older than
one watch tick, 30 seconds). Dead or unverifiable means you are on the
floor: say so in your next entry and rely on boundary checks and `mailbox
wait` until a relaunch proves stable. Closing the watch means stop
restarting, never trusting a kill: when the unit closes, stop restarting and
let the final instance expire — a kill claim needs the kill's confirmed
result. No background capability in your harness? Then you are on the floor:
check `dispatcher.md` at every task boundary, and when blocked use
`mailbox wait` (its exit-124 branch: wait again if still worth it, or stop
and tell your user the dispatcher did not answer).

## The channel

Your ordinary printed output reaches nobody. **Printing is not replying.**
The dispatcher converses with you only through
`/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/handoff/m3-town-ux/`
— append entries to `worker.md`, read answers from `dispatcher.md`.

The mailbox tool (absolute path — resolve nothing yourself):

    /var/home/dhemas/Development/Projects/fiatcode/ai-stack/shared/skills/flow-mailbox/scripts/mailbox

It performs every mechanic; **every write goes through it** — never an
anchored edit, never a redirection, never a hand-typed timestamp. Commands:

    mailbox append --as worker --dir <channel> --disposed-through <N|none> [--file <path>]
    mailbox check  --as worker --dir <channel>
    mailbox wait   --as worker --dir <channel> [--timeout 570]
    mailbox watch  --as worker --dir <channel> [--timeout 3600]

`append` reads the body from stdin or `--file`. Entries are appended as:

    ## <seq> — worker — <ISO timestamp>
    <body>

    disposed through dispatcher entry <N>

Rules: the cursor is stated on EVERY entry (the other side's entry number
you have dealt with, or `none`); no body line may be a level-two heading at
column 0 (indent it or deepen it to `### `); an entry, once appended, is
never edited — a correction is a new entry; a tool refusal (exit 2) means
nothing landed — fix the input and retry, never work around it by hand; a
corrupt file is a STOP, never a hand repair. "New mail" is a sequence
comparison against your disposed-through cursor, never a timestamp test.
`mailbox wait` belongs to the blocked worker only. Exit codes: 0 ok/delivered,
1 no new mail, 2 refused, 124 timeout (window closed, nothing arrived — wait
again if worth it, or stop and tell your user).

Write to the channel when: a spec claim looks wrong, an inherited gate turns
out not real, or you are blocked on a decision the spec does not cover.
Otherwise decide, proceed, and report at the end.

**REPORT.md:** at the end, mirror your full verification block to `REPORT.md`
in the channel directory. The report is on disk unconditionally — the
architect may be compacted or not listening when you finish.

## The worktree

The worktree is ALREADY CREATED at
`/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/.worktrees/m3-town-ux`
(branch `m3-town-ux`, off `bd848f7`). Do NOT create a worktree; NEVER remove
it — the directory belongs to the user. First command, output confirmed:

    cd /var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/.worktrees/m3-town-ux && pwd

A fresh shell does not reliably inherit the directory, and a commit landing
in the parent repository is a real failure mode. Write git as
`cd <worktree> && git <cmd>` — `git -C <repo> <cmd>` does NOT match this
machine's sandbox exclusion patterns. No sibling worktrees exist today; the
parent checkout at `/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg`
is on `main` and must receive no commits.

## What the work is

The town's benches and lists finish the grammar playtest verdicts V3+V5+V6+V7
asked for: the forge price is always visible with the refusal word beside it,
the character screen stops carrying the town's notice, the one-press benches
and the fixed bank become counted work (a stepper with MAX and tap-and-hold,
committed in one press), the forge bench splits into WORN STEEL and CARRIED
STEEL so position says what "(worn)" used to say, and the merchant's three
lists stack duplicates into one row where every tap moves exactly one item.
App-side only — zero `packages/core` and `packages/content` changes, save v3
stands, goldens byte-identical. This is the FIRST unit under the amended
D113 widget-driven method: the build loop is `flutter test` per package
directory, NEVER the emulator; the AVD pass runs ONCE at the end as the
acceptance gate.

## Be adversarial about the spec — and pre-declare deviations

Disagreeing with the spec in the open is expected behaviour, not a nuisance.
The claims most worth attacking BY MEASUREMENT (not by reading):

- The `temperable` two-halves assumption: a worn piece appears exactly once
  (wear removes it from inventory — `wear.dart:106-108`). Prove it with the
  actual state before building the WORN/CARRIED split on top.
- The gold "one call" claim: `depositGold`/`withdrawGold` take an amount and
  refuse on ≤0 or shortage (town.dart:379-413) — measure the refusal
  vocabulary and confirm the clamped pending amount can never refuse.
- The pack-room cap computability: `inventoryCap` is a core export already
  used app-side (`game_bloc.dart:428`) — confirm, and confirm the brew cap
  `min(herbs ÷ 3, inventoryCap - inventory.length)` matches what
  `brewPotion` will actually accept.
- The `stackKey ⇒ same price` claim (every price input is in the key) — try
  to find a counterexample in the content tables.
- The brew batch notice aggregate: the wording and the level-up/loss
  precedence are SPEC RULINGS, not recon findings — attack their shape if
  the code says something different.
- The tap-and-hold cadence (~400ms first repeat, ~120ms cadence) must be
  testable with `tester.pump` — verify before building the widget.

**Pre-declared deviations go to the mailbox BEFORE code is written** — an
intended departure from the spec's shape is appended to `worker.md` first,
and the dispatcher answers in `dispatcher.md`. Corrections that change a
locked decision or the spec's shape are promoted to the ledger before you
continue. A worker correction the architect got wrong is welcome history —
eight architect claim errors are on the epic's record, most worker-caught.

## Method

Characterization tests FIRST: the refused-row hides-the-price behavior, the
character screen's notice bar presence, the one-press smelt/brew buttons,
the four fixed bank buttons, and the merchant's three unstacked lists — each
pinned by a test that PASSES against unmodified `bd848f7` before anything
changes. If such a test does not pass, your understanding of current
behaviour is wrong: stop and report, do not work around it. Then the change,
red → green → refactor per behavior (`flow-tdd` mandatory). This unit is
well over thirty changed lines with real logic: write a plan first
(`flow-writing-plans`), execute it (`flow-executing-plans`), and commit the
plan doc at `docs/plans/2026-09-08-m3-town-ux.md` ON the branch before your
final commit. Every commit's exit state is green — no reviewable unit left
red. Code standard: the standing principles in `shared/agents/GLOBAL.md` and
the three review lenses in
`flow-reviewing-prs/references/review-lenses.md`; dartdoc `///` on public
API of core and content only, no comments in bodies — this unit touches
app code, where names carry intent.

## Environment traps (restated verbatim from the ledger)

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
  holds incoming messages behind an approval gate that expires. Keep
  exactly one architect session alive; the REPORT.md mirror is the working
  fallback; expect to relay by hand when the architect runs interactive.
- `find.textContaining` in Flutter 3.47 is case-sensitive with no
  `caseSensitive` parameter — match the literal casing or use a regex.
- `scrollUntilVisible` computes ONE moveStep from the axis direction, so
  it can never scroll back up — assertion sequences on a long screen must
  be monotonic in document order.
- A worker harness's AUTO-FORMAT hook can re-dirty a file seconds after a
  revert lands. After any revert here, re-check `git status --porcelain`
  a beat later, not just once.

## Mutation table

Run EVERY row; report the WHOLE table, greens included, naming which tests
each mutation reddened as a NAMED SET (never a count), plus the named
controls that stayed green and why. Rows and their named red sets:

- **M1** revert the forge row to the `reason ??` single slot → reddens {a
  refused forge row keeps the price of its next tier visible}. Controls:
  workable-row and ceiling-row tests (identical renders before/after).
- **M2** re-add `Notice(state.notice)` to character_screen → reddens {the
  character screen does not carry the town's notice}. Control: the forge's
  notice test.
- **M3** break the smelt cap (cap = the ore count itself) → reddens {the
  smelt stepper cannot dial past the ore} AND {MAX takes the count to the
  cap}. Control: single-tap tests.
- **M4** remove the auto-repeat timer → reddens {holding the stepper's +
  button advances the count}. Control: single-tap tests.
- **M5** commit performs one unit regardless of the pending count →
  reddens {the smelt commit spends the whole pending count} and {the gold
  dial banks exactly the dialed amount}. Control: n = 1 commit tests.
- **M6** brew cap ignores pack room → reddens {the brew cap clamps at the
  pack's room}. Control: the herbs-side cap test.
- **M7** the notice reports only the LAST attempt's answer → reddens {a
  brew batch says how many brews failed}. Controls: clean-batch and
  verbatim-single-loss tests.
- **M8** render both bench rows under one heading → reddens {the forge
  bench splits into worn steel and carried steel}. Control: the rows'
  price/refusal tests.
- **M9** a stacked tap moves the whole stack → reddens {a stacked buy tap
  buys exactly one} (+ sell and buy-back variants). Control: single-item
  row tests.
- **M10** re-render one fixed bank button → reddens {the bank's fixed gold
  buttons are gone}.

Plus the band trail (content suite, all five lines byte-identical: crypt
16/40, casting 40/40, greedy 16 / fleetfoot 13, sea-cave 26/40, keep 24/40)
and the v3 goldens byte-identical. No sequencing traps this unit — but a
mutation may fail one test layer and stay green in another; report both
halves where it happens.

## What you must NOT do

- No pushing, no pull requests, no reviewer requests, no merging, no
  replying to review threads, no touching external trackers. Every external
  write is the architect's, on the user's explicit approval, per round.
- NO changes under `packages/core/` or `packages/content/` — that is a
  scope breach; stop and report through the channel instead.
- Never commit anything under `docs/epic/`. The plan doc lives at
  `docs/plans/` and rides the branch.
- Do not create or remove any worktree. Do not commit in the parent repo.
- Never install to or touch the user's physical phone; pin every adb and
  flutter device command to `-s emulator-5554`.
- The AVD pass: device saves are playtest state — copy BOTH slots aside
  with checksums BEFORE any install, and restore byte-exact after. Never
  push an acceptance save without the ritual.
- Do not stop the user's emulator or the architect's watch; do not write to
  either side of the mailbox except your own `worker.md` and `REPORT.md`.

## Verification block (every item evidenced, not asserted)

1. Proof the work happened in the worktree and is not on main: `cd
   <worktree> && git log --oneline main..HEAD` and `git branch --show-current`,
   outputs quoted.
2. Test counts read from result files per package directory (core, content,
   app) with the hidden-filter arithmetic (strict count = `testDone` events
   with `"result":"success"` minus `"hidden":true`), compared against a
   stated baseline — 2077 = 860/579/638 at `bd848f7`, carried forward from
   D126; state your own fresh measurement beside it.
3. Proof the characterization tests passed against UNMODIFIED code: quote
   the run (or the commit ordering) that shows them green before the first
   behavior change landed.
4. The full mutation table: every row's named red set and its named green
   controls, with the sed/edit for each row quoted.
5. The band trail: all five lines verbatim from your own run, byte-identical
   to the pins quoted above.
6. Goldens byte-identical: the golden save test green, the diff quoted.
7. `dart pub get` per package, then format clean and analyze clean — three
   runs each, from the WORKTREE ROOT, with `pwd` quoted beside the command.
8. `git status --porcelain` clean at the end (re-checked a beat later — the
   auto-format hook trap), with the plan doc committed.
9. Every spec claim you checked and found wrong, with the source. "None"
   must itself be evidence-backed.
10. What the tests cannot prove, stated plainly — the device-pinned defect
    classes belong to the AVD pass, and you name them.
11. The AVD acceptance pass (final gate, ONCE): AVD booted (the user may
    need to start it — Pixel_10 segfaults under the sandbox), save ritual
    FIRST (both slots aside, sha256), install, scripted taps through the
    new surfaces, greyscale shots, saves restored byte-exact, shots
    mirrored to the channel. Paint-timing and real-disk defects, if any
    surface, are device findings — report them, do not fix them silently.
12. Which execution phases ran (plan, execute, tdd) and why any named
    phase was skipped — a skip is an argument, not an absence.

Read REPORT.md's mirror requirements again before writing it: the report is
the designed fallback when the channel is dead — it must stand alone.