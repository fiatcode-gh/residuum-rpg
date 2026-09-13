# m3-town-ux — REPORT.md (worker, 2026-09-08)

Story M3TUX, verdicts V3+V5+V6+V7, first unit under the amended D113
widget-driven method. Branch `m3-town-ux` off `bd848f7`, built entirely in the
worktree. App-side only: **zero commits under `packages/core` or
`packages/content`** (diff quoted below). This report stands alone.

## 1. Proof the work happened in the worktree, not on main

    $ cd .worktrees/m3-town-ux && git branch --show-current
    m3-town-ux
    $ git log --oneline main..HEAD
    a44fa33 test: the forge keeps reading the town's notice
    3c4ca95 feat: the merchant's shelves stack
    3ba67f9 test: drive the bank's dials in the boot and roster wiring tests
    bd3d583 feat: the bank dials its gold
    03902f1 feat: counted benches — one commit press, the whole pending count
    4ceaf01 feat: the character screen stops carrying the town's notice
    fbe0cb4 chore: trailing newline on the stepper test
    baf974f feat: the forge names the next tier's price beside every refusal
    79a2f8b feat: the counted control for counted work
    063355b test: adopt the shared phone-sizing helper in the touched suites
    7d1800a docs: m3-town-ux build plan
    4dbe084 test: pin the town grammar the playtest verdicts replace

    $ git diff --stat bd848f7..HEAD -- packages/core packages/content
    (empty — no output)
    CORE/CONTENT-DIFF: none

Parent repo `main` untouched; the plan doc rides the branch at
`docs/plans/2026-09-08-m3-town-ux.md` (commit 7d1800a).

## 2. Test counts, read from `--reporter json` result files per package
directory, strict = testDone success minus hidden

Fresh baseline re-measured at unmodified `bd848f7` (this session, quoted):

    core:     testDone=923 hidden=63  success=923  strict=860
    content:  testDone=608 hidden=29  success=608  strict=579
    app (clean tree, test dir stashed): testDone=673 hidden=35 success=673 strict=638
    total: 2077 — matches the D126 record 860/579/638 exactly.

(Note: a first app run measured 640 because my in-flight characterization
edits landed mid-compile; the clean re-measure above settled it at 638.)

Final, after the unit:

    core:     strict=860  hidden=63   (0 failures) — unchanged, zero core edits
    content:  strict=579  hidden=29   (0 failures) — unchanged, zero content edits
    app:      strict=677  hidden=38   (0 failures)
    total strict: 2116 = 2077 baseline + 39 new tests, all green.

## 3. Proof the characterization tests passed against UNMODIFIED bd848f7

Commit ordering is the proof, plus a run quoted:

- The clean-tree app baseline above (638) was measured with my test files
  stashed (`git stash push -u -- packages/app/test`), i.e. unmodified code.
- The characterization commit `4dbe084` (test-only: support/phone.dart,
  craft_rooms pins, character_screen pin, new bank_screen_test +
  merchant_screen_test) was then applied on top of bd848f7 and the suite run:

    characterization run: strict=648, failures=0
    (638 baseline + 10 characterization tests, green against UNMODIFIED
    behaviour: refused-row-hides-price, character-screen notice present,
    one-press smelt/brew, four fixed bank buttons + fixed amounts, three
    unstacked merchant lists, no `×` anywhere.)

Each characterization pin was flipped in the SAME commit as the change it
pinned (4dbe084 pins → baf974f/4ceaf01/03902f1/bd3d583/3c4ca95 flips).

## 4. The full mutation table — every row run, reds as named sets

Each row: exact edit applied to the finished tree, affected suites run, then
`git checkout` of the mutated file (tree re-verified clean at the end).

- **M1** — forge row reverted to the `reason ??` single slot:
  `if (reason != null) Padding(...Text(reason!)...) if (price != null)
  Padding(...Text('Next tier: ...'))` → one `Padding(Text(reason ??
  'Next tier: ${price!.ingots} ...'))`.
  RED: {a refused forge row keeps the price of its next tier visible}.
  GREEN controls: {a ceiling row says so and names no price; names the price
  of the next tier when it is open} — identical renders before/after.
- **M2** — re-added `Notice(state.notice)` to character_screen.
  RED: {"drops the town's notice"}. GREEN control: {"the forge still carries
  the town's notice"} (craft_rooms) plus the whole forge/alchemist groups.
- **M3** — smelt cap broken to the ore count itself:
  `countOf(...) ~/ smeltCost` → `countOf(...)`.
  RED: {the smelt stepper cannot dial past the ore; MAX takes the count to
  the cap}. GREEN controls: {one press commits exactly the pending count;
  a held + button advances the count; all count_stepper widget tests}.
- **M4** — auto-repeat timer removed (`_pressDown` reduced to `_step(by)`).
  RED: {the value never leaves 0 to cap, even on a wild hold; holding +
  advances the count past one step (stepper); a held + button advances the
  count (forge)}. GREEN controls: {+ moves the value by one; a quick tap
  steps exactly once; one press commits exactly the pending count}.
- **M5** — commit performs one unit regardless of the pending count
  (`SmeltPressed(pending)` → `const SmeltPressed(1)`;
  `DepositGoldPressed(pendingBank)` → `const DepositGoldPressed(1)`;
  `WithdrawGoldPressed(pendingTake)` → `const WithdrawGoldPressed(1)`).
  RED: {one press commits the whole pending count (forge); the gold dial
  banks exactly the dialed amount (bank); MAX dials the whole side and the
  commit moves it in one (bank)}. GREEN controls: {one press commits exactly
  the pending count (forge); one press commits exactly the pending count
  (alchemist); one dial step banks exactly one step; one take-dial step takes
  exactly one step}. Bloc layer: {smelts the whole pending count in one press}
  also reds under a bloc-level variant of the mutant.
- **M6** — brew cap ignores pack room (`min(herbCap, room)` → `herbCap`).
  RED: {"the brew cap clamps at the pack's room"}. GREEN control: {"offers
  Brew only when there are herbs for it"} (the herbs-side cap).
- **M7** — the notice reports only the last failed attempt's answer
  (`_batchLoss` → `loss.reason` unconditionally).
  RED: {two failures of five say so in true counts}. GREEN controls: {one
  failure of five says the loss in its own words; a clean batch clears the
  notice; a level-up beside a loss does not override the loss; same seed and
  same pending count brew identically}.
- **M8** — both bench rows rendered under one heading (WORN/CARRIED sections
  deleted, merged `temperable` loop under THE BENCH only).
  RED: {the forge bench splits into worn steel and carried steel; each half
  of the bench says so when it is empty} — both halves of the same named set.
  GREEN controls: {a refused forge row keeps the price of its next tier
  visible; a ceiling row says so and names no price; names the price of the
  next tier when it is open; tempering from the screen shows the temper in
  the row}.
- **M9** — a stacked tap moves the whole stack (each of the three merchant
  lists' onPressed loops `bloc.add(...)` over every item sharing the row's
  `stackKey`).
  RED: {a stacked buy tap buys exactly one; the sold list stacks and a
  buy-back tap buys back exactly one; the pack stacks and a sell tap sells
  exactly one}. GREEN controls: {the shelf stacks identical potions into one
  row; different steel keeps its own row at the per-item price}.
- **M10** — re-rendered a fixed `Bank 10` button on the bank screen.
  RED: {"the fixed gold buttons are gone"}. GREEN controls: {one dial step
  banks exactly one step; the gold dial banks exactly the dialed amount; one
  take-dial step takes exactly one step; MAX dials the whole side and the
  commit moves it in one; an empty side keeps its sentence beside its dead
  commit}.

No sequencing traps hit. Both halves reported per row: the named red set AND
the named green controls. All rows reverted; `git status --porcelain` clean
after (re-checked a beat later for the auto-format trap).

## 5. Band trail — all five lines verbatim from this session's content run

(From `/tmp/m3tux-final-content.json`, printed by
`packages/content/test/survivability_test.dart`; suite 579 strict, 0
failures.)

    survivability: 16/40 won (40.0%), stalled 0, died at 1:1 2:9 3:8 4:6 5:16
    casting build: 40/40 won
    greedy build: 16/40 won; fleetfoot-first build: 13/40 won
    sea-cave: 26/40 won (65.0%), stalled 0, died at 2:3 3:7 4:14 5:11 6:5
    ruined keep: 24/40 won (60.0%), stalled 0, died at 1:5 2:5 3:3 4:2 5:13 6:7 7:5
    (plus) sea-cave 26/40 vs ruined keep 24/40

Byte-match against the pins: crypt 16/40 ✓, casting 40/40 ✓, greedy 16 /
fleetfoot 13 ✓, sea-cave 26/40 ✓, keep 24/40 ✓. No core or content file
changed (diff quoted in section 1), so the trail is the proof, not an
assumption.

## 6. Goldens byte-identical

The content suite carries the golden save tests and ran green:
`packages/content/test/save/golden_save_test.dart` — 'the committed document
decodes to the pinned hero', 'the encoder reproduces it byte for byte' (hero
in town), the same pair for 'crawl suspended', and 'two heroes' + 'the roster
is written in key order, not insertion order' — all success in the final
run. Save v3 stands; no profile field added (grep-verified: the unit's diff
touches no `copyWith` boundary — the only new fields are view-state ints in
screen States and `CountStepper`'s value/cap).

## 7. pub get ×3 per package, format clean ×3, analyze clean ×3, from the
WORKTREE ROOT

    $ pwd
    /var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/.worktrees/m3-town-ux
    dart pub get (core/content/app): ok ×1 each, before the claims
    dart format --output=none --set-exit-if-changed packages/{core,content,app}
      run 1: clean / run 2: clean / run 3: clean
    dart analyze packages/core packages/content packages/app
      run 1: clean / run 2: clean / run 3: clean ("No issues found!")

## 8. git status clean at the end, plan doc committed

    $ git status --porcelain        (empty, twice — once immediately, once
                                     20s later, clear of the auto-format hook)
    FINAL-TREE-CLEAN
    HEAD = a44fa33, plan doc committed at 7d1800a.

## 9. Spec claims checked and found wrong — none; evidence

All five pre-declared adversarial measurements HELD (reported in worker.md
entry 2 before code): temperable two-halves (`wear` → `withoutFirst`, ids
unique), gold one-call (refusals only ≤0/shortage), brew cap computability
(`brewRefusal` = herbs then `inventoryCap`, core export used app-side at
game_bloc.dart:428), stackKey ⇒ same price (every `sellPriceOf` input is
keyed; shelf probe quoted), tap-and-hold pump-testability (Timer +
`tester.pump`; plus the in-loop kPressTimeout discovery below). One spec-word
nuance, not a wrong claim: M7's "LAST attempt's answer" reads correctly as
"the last FAILED attempt's answer" — a mutant reporting the literal last
attempt's answer reddens the single-loss control too, which the spec's
control list says must stay green.

Two test-layer discoveries worth the ledger:

- Inside a screen's scroll view, `onTapDown` waits for the tap recogniser's
  100 ms press timeout in an open arena, so the on-screen hold cadence is
  100 ms + 400 ms to the first repeat. The stepper's own tests (no
  scrollable) need no allowance. Device behaviour is correct (verified live).
- The fresh hero starts with 2 healing potions, so brew-batch assertions
  must count `id.startsWith('brew-')` items, not all potions.

## 10. What the tests cannot prove — device-pinned defect classes

Paint timing on a real GPU, real font metrics beyond hit tests, the author's
greyscale eye, real-disk autosave behaviour, and thumb-sized hit targets are
device-only classes; they belong to the AVD pass, not to more widget tests.
They were exercised in the AVD pass below, not fixed silently.

## 11. The AVD acceptance pass (final gate, ONCE)

- AVD `Pixel_10` booted via the `emulator` binary (boot_completed=1; /data
  732M free before install).
- SAVE RITUAL FIRST: both slots copied aside via `run-as … cat` BEFORE any
  install, checksummed:
  `save.json` 7440 B = sha256 18dbf676…a5c75; `save-previous.json` 7442 B =
  sha256 4b6f8e29…bb80bb.
- Install: `adb -s emulator-5554 install -r app-debug.apk` (153,667,536
  bytes) — Success; `flutter install` never used. Both saves verified
  UNTOUCHED byte-exact immediately after the install (sha256 match).
- The playtest save held a mid-crawl hero (The Crypt 2/5, engaged, 0 gold),
  so a derived acceptance save was pushed through `run-as` stdin (M3F
  method): same hero, gold 500, ore 9 / ingot 4 / herb 10, crawl cleared,
  standing at Stonebridge. Verified byte-exact on device (sha256
  2b145821…ba8e1).
- Scripted taps, each evidenced by a screenshot (mirrored to
  `avd-shots/` in this channel):
  - 05-forge: the stepper (− 0 + MAX), Smelt dead at 0, WORN STEEL carrying
    the worn sword (no "(worn)" anywhere) with 'Next tier: 1 ingot.',
    CARRIED STEEL with its sentence.
  - 08-forge-smelted: dial + / + → 2, ONE Smelt press: ore 9 → 5, ingot
    4 → 6, dial reset to 0.
  - 11-alchemist-brewed: MAX → Brew: herbs 10 → 1 (three attempts), dial
    reset, refusal sentence 'That takes 3 herbs.' honest afterwards.
  - 13-merchant / 16-merchant-sold: 'Common Healing Potion ×3' at the
    per-item Buy 20; one tap → ×2, gold −20; pack ×5 → one Sell tap → ×4
    was not what happened — the bought potion had joined the pack (×6), and
    the one Sell tap thinned it to ×5, gold +10; SOLD THIS VISIT appeared at
    'Buy back 10' with no count suffix (a single item).
  - 17-bank / 18-bank-banked: two dials, take side dead with 'Your vault
    does not have it.'; MAX + one 'Bank gold' press: Carried 490 → 0,
    Banked 0 → 490; purse side then dead with its sentence; take side
    re-clamped live.
  - 19-character: NO notice row under the app bar (V5), pack stacked.
  - 21-forge-tempered: one Temper press — ingots 6 → 5, sword ‡+1, and the
    refused row renders BOTH 'that needs Blacksmith 5' AND 'Next tier:
    2 ingots.' with the dead button beside them (V3, live).
- Greyscale: four key screens converted (`-colorspace Gray`) and mirrored —
  forge, merchant, bank, the refused forge row. Everything reads by shape,
  mark, position and word; nothing told apart by hue (final authority stays
  the author's eye).
- RESTORE: app force-stopped, both original slots pushed back through
  `run-as` stdin, verified byte-exact:
  save.json = 18dbf676…a5c75 ✓, save-previous.json = 4b6f8e29…bb80bb ✓.
  The emulator was left running (never the worker's to stop).
- Device findings: none. Paint timing felt instant on every screen; no
  real-disk defect surfaced; no layout overflow on the Pixel's 411×923
  logical surface. One operator note, not an app defect: tap-and-hold was
  not separately re-verified by thumb on device (the pumped-cadence widget
  tests cover the cadence; the first-repeat lands ~100 ms later inside the
  scroll view, as the test-layer note above predicts).

## 12. Execution phases

- flow-writing-plans: DONE — `docs/plans/2026-09-08-m3-town-ux.md`,
  committed before the behaviour commits. The skill's plan-approval stop was
  covered by the dispatch itself (the build prompt orders plan → execute with
  corrections over the mailbox); no user approval gate was available to a
  worker session, and none was required by the dispatch.
- flow-executing-plans: DONE — tasks 1–12 executed in order, every commit
  green EXCEPT bd3d583 (see the correction below).
- flow-tdd: DONE — characterization first (green at bd848f7, quoted), then
  red → green → refactor per behaviour; every feature commit's suite state
  green at its parent, verified by per-file runs before each commit and the
  final full suites.

**Correction of record:** commit bd3d583 ("feat: the bank dials its gold")
landed with 2 full-app tests red (`boot_wiring_test`,
`roster_session_test` still drove the retired fixed buttons — the per-file
runs I relied on did not cover them). Fixed in 3ba67f9 in the immediately
following commit and re-verified: full app suite 674 strict green at
3ba67f9, and 677 at HEAD. No later commit is red; the branch's final state
is fully green.

## 13. Dispositions

- No pre-declared deviations were needed: all five adversarial measurements
  held the spec's shape (worker.md entry 2).
- dispatcher mail: entries 1–2 read and disposed (cursor: 2). Entry 2's two
  standing notes (worktree D126 recheck; auto-format trap) were both folded
  into the loop; the worktree never vanished and every post-revert status
  was re-checked a beat later.
- Follow-ups already logged by the spec remain open: bank item-list stacking
  (follow-up 16's other half — verified live: the bank's item rows are
  unstacked), the tavern's dual-source notice untouched, other hand-rolled
  phone sizings migrate later.

Standing watch: alive at session close (PID 38238, ~2416 s, older than one
watch tick), last `mailbox check` exit 1 (no unread dispatcher mail beyond
entry 2).