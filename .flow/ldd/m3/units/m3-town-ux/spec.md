# m3-town-ux — story spec (M3TUX)

Unit: `m3-town-ux` · verdicts V3+V5+V6+V7 (playtest verdicts, D63 block;
scope locked D98, as amended D103). Recon: `m3-town-ux-recon.md`, measured
fresh on `bd848f7`. THE FIRST unit under the amended D113 widget-driven
method. Fork rulings locked by the user this session (2026-09-08): pending
count + one commit button; brew cap clamps at herbs AND pack room; the
shared phone helper is adopted only by files this unit touches.

## Goal

The town's benches and lists finish the grammar the playtest asked for: the
forge price is always visible with the refusal word beside it, the craft
notice stops following the hero to the character screen, the one-press
benches and the fixed bank become counted work (stepper + MAX + tap-and-
hold, committed in one press), the forge bench says worn from carried by
position, and the merchant's shelves stack duplicates into one row. App-side
only — zero core changes, save v3 stands, goldens byte-identical.

## Precedent

- The locked rulings of record: D63 block (V3/V5/V6/V7 words verbatim), D98
  scope, D113 widget method. No re-fork.
- The forge's dead-row rule (inn's rule): a control goes dead with its
  sentence beside it, never vanishing, never going grey (`forge_screen.dart`
  dartdoc :15-18). Every new dead control follows it.
- The stacked label grammar is `ItemStack.label`'s (`Name ×$count`,
  item_presentation.dart:50-61) — already shipped in the pack; the merchant
  adopts the same words.
- Position carries worn-ness, the bank's grammar (D63 ruling): sections are
  the sentence; the "(worn)" suffix retires.

## Central contract: the pending count is view state, the transaction loop is app-side

The benches take counted work, but the game's transactions are unchanged.
The pending amount lives in the screen's own state — it is view state, not
game state, and dies with the screen. Committing calls the EXISTING core
transaction once per unit of work, in a loop in `town_bloc`:

- **Smelt n**: `smeltOre` called n times. Smelting never fails and cannot
  refuse (the cap clamps at ore÷2), so every call succeeds; the notice
  clears exactly as today; a Blacksmith level-up during the batch still
  speaks its sentence (the existing `_crafted` mechanism, one sentence for
  the whole batch — compare levels before and after).
- **Brew n**: `brewPotion` called n times — n draws, one per attempt, the
  craft stream advancing exactly once per unit of work (M3CR's doctrine
  holds: one attempt, one advance). Failures lose 3 herbs each and produce
  nothing. The slot holds one sentence, so the batch aggregates (ruling
  below).
- **Gold n**: `depositGold`/`withdrawGold` called ONCE with n — the core
  already takes an amount. The clamped pending amount can never refuse; the
  commit button is dead at n = 0.
- **Temper**: not counted — one press, one item, exactly today's shape. The
  risk draw and the loss line are M3CR's, untouched.

The cap clamps at actual resources (locked ruling): smelt cap = ore ÷
`smeltCost` floor; brew cap = min(herbs ÷ `brewCost`, free pack slots); bank
caps = `gold` and `bankedGold`. The pending value re-clamps whenever state
changes — a commit or any other town action that shrinks the resources pulls
the dial down. No keyboard ever appears.

### The brew batch notice (spec ruling)

The town slot holds ONE sentence; a batch of five brews can fail twice. The
slot tells the truth in one line, built from the per-attempt answers the
bloc actually received:

- **All n succeed** → the notice clears (as `_settled` with a null answer
  does today); a Herbcraft level-up over the whole batch speaks instead.
- **f ≥ 1 failures**: f = 1 renders the answer's own reason verbatim ("the
  brew fails and takes 3 herbs"); f ≥ 2 renders "f of n brews fail and take
  3·f herbs" — same rule voice, true counts. A level-up in the same batch
  does NOT override it: the loss sentence wins the notice slot (D123
  ruling 3, standing).
- This aggregate is a sanctioned UI-local wording, dartdoc'd in the bloc
  beside bank's two shared sentences — the words come from the loss
  grammar, never invented per screen.

## Shape

- **New files**
  - `packages/app/test/support/phone.dart` — the shared phone-sizing helper:
    `onAPhone(WidgetTester tester)` (1080×2424 @ 2.625, `addTearDown`
    reset), moved verbatim from `world_screen_test.dart:1245-1249` with its
    dartdoc. Every test file this unit touches pumps screens through it.
  - `packages/app/test/widget/merchant_screen_test.dart` — the merchant
    screen's first widget tests (V7 stacking, price words, one-per-tap).
  - `packages/app/test/widget/bank_screen_test.dart` — the bank screen's
    first widget tests (gold dials, retired fixed buttons, item rows
    unchanged).
- **Changed files**
  - `packages/app/lib/town/town_style.dart` — the `CountStepper` widget:
    − / value / + / MAX, tap-and-hold auto-repeat on − and + (first repeat
    after ~400ms, then ~120ms cadence — a constant, dartdoc'd), dead − at 0,
    dead + and MAX at the cap, value rendered as a word. Reads in greyscale
    by construction (glyphs, a number, a word).
  - `packages/app/lib/town/forge_screen.dart` — V3 price grammar (refused
    rows render the price AND the reason as separate lines; ceiling rows
    render the ceiling sentence and no price line); WORN STEEL / CARRIED
    STEEL sections from `temperable`'s two halves, "(worn)" suffix and the
    id-based `_isWorn` retire; the smelt stepper replaces the one-press
    button.
  - `packages/app/lib/town/town_bloc.dart` — `SmeltPressed` and `BrewPressed`
    gain a count (no longer const); batch handlers loop the core
    transactions; the brew notice aggregate; `temperable` splits into the
    worn-first and carried halves (worn steel = equipment slots in slot
    order, carried steel = inventory in order — the getter's existing two
    halves, now named); gold events unchanged.
  - `packages/app/lib/town/alchemist_screen.dart` — the brew stepper with
    the double cap; the pack-cap sentence stays for the genuinely full pack.
  - `packages/app/lib/town/bank_screen.dart` — the four fixed buttons become
    two dials (bank side, take side), each with its own commit; the :19-28
    dartdoc rewritten to argue the new shape honestly (the number-pad
    argument is retired by user ruling and said so).
  - `packages/app/lib/town/merchant_screen.dart` — all three lists stack by
    `stackKey`; a row's label gains `×$count` when count > 1; price words
    unchanged and per-item; every action moves exactly one item.
  - `packages/app/lib/town/character_screen.dart` — the notice bar retires
    (line :52). Nothing else on the screen moves.
  - `packages/app/test/widget/world_screen_test.dart` — `_onAPhone` moves to
    the shared helper; the file imports it.
  - Test files this unit touches adopt the shared helper:
    `craft_rooms_test.dart`, `craft_surfaces_test.dart`,
    `character_screen_test.dart`, `disabled_controls_test.dart` (where it
    pumps the touched screens), plus the two new files.
- **NO core or content file changes.** A diff touching `packages/core` or
  `packages/content` is a scope breach — stop and report.

## Per-item contract

- **V3**: a refused forge row renders its refusal reason AND, when a next
  tier exists, the price line `Next tier: N ingots.` — both visible, the
  reason separate from the price. A ceiling row renders the ceiling
  sentence and no price line (there is no next tier to price). A workable
  row renders exactly the price line it renders today. The temper button's
  dead/gated behavior is untouched.
- **V5**: the character screen renders no notice row, ever. The notice
  mechanism, the town screens' notice rows, and the tavern's
  `town.notice ?? world.notice` fallback are untouched.
- **V6**: every counted bench reads − / value / + / MAX; no keyboard; the
  cap clamps at actual resources (smelt: ore÷2; brew: min(herbs÷3, pack
  room); bank: purse/vault); the pending count is view state and re-clamps
  on every state change; one commit press performs the whole pending count
  as one-attempt-per-unit work. The bank's four fixed buttons retire. The
  forge bench reads WORN STEEL then CARRIED STEEL, by position, no "(worn)".
- **V7**: all three merchant lists (For sale / Sold this visit / Your pack)
  stack by `stackKey`; a stack of n ≥ 2 labels `Name ×n`; the price word is
  the per-item price; every tap — stacked or not — moves exactly one item;
  dead-row reasons (cannotAfford) unchanged.
- **What none of these may do**: change a core transaction, add a profile
  field, move a save byte, or tell anything apart by hue alone.

## Behaviour arguments that must land in documentation

- **Why the pending count is view state** (not game state): it is a dial, a
  thing the player is about to do, not something that happened; a screen
  that dies with its dial cannot corrupt a save or a resume.
- **Why the commit loops the existing transactions** instead of a new batch
  API: the transactions are pure and self-contained; n calls IS n units of
  work, each with its own risk draw — the determinism story stays "one
  attempt, one advance", just n times. A core batch function would be a
  second way to do the same work.
- **Why the brew notice aggregates** (the one-sentence slot vs the n-draw
  batch) — the paragraph above, dartdoc'd at the aggregate's construction.
- **The retired bank dartdoc**: the fixed-buttons argument is retired BY
  USER RULING (D63), not refuted — the new dartdoc says the dial replaced
  it by ruling and says why the cap clamp keeps the "one button says it"
  property that argument was defending.
- **Why position carries worn-ness** (forge sections): the suffix was a word
  patching a merged list; the split makes the list tell the truth by
  position, the bank's grammar — and it retires the id-based `_isWorn`,
  whose id-match was the only thing a duplicated-id edge could have confused.

## Test plan (TDD; widget-driven per D113)

**Characterization first (against unmodified `bd848f7`):** the refused-row
hides-the-price behavior, the character screen's notice bar presence, the
one-press smelt/brew buttons, the four fixed bank buttons, and the merchant's
three unstacked lists — each pinned by a test that passes BEFORE the change
and is then flipped to the new expectation in the same commit as the change.
(The forge's existing craft_rooms tests already pin parts; extend rather than
duplicate.)

All new widget tests run through the shared `onAPhone` helper. Bloc-level
tests for the batch semantics live in `town_bloc_test.dart` (state in, state
out — no widget needed).

- **M1 — the forge price line is always visible**: a gate-refused row shows
  BOTH "that needs Blacksmith 5" AND "Next tier: 2 ingots."; a
  missing-ingots row shows the take sentence and its price; a workable row
  shows the price; a ceiling row shows "that is worked as far as it goes"
  and NO price line. Mutation: revert the row to the `reason ??` single
  slot → reddens {a refused forge row keeps the price of its next tier
  visible}. Controls: the workable-row and ceiling-row tests stay green —
  they render identically before and after the mutant.
- **M2 — the character screen drops the notice**: a notice in state renders
  on the forge (control) and NOT on the character screen. Mutation:
  re-add `Notice(state.notice)` → reddens {the character screen does not
  carry the town's notice}. Control: the forge's notice test stays green.
- **M3 — the stepper counts and clamps**: + / − move the value; MAX jumps
  to the cap; + is dead at the cap; − is dead at 0; the smelt cap is
  ore÷2. Mutation: break the ore cap (cap becomes the ore count itself) →
  reddens {the smelt stepper cannot dial past the ore} AND {MAX takes the
  count to the cap}. Control: single-tap tests stay green.
- **M4 — tap-and-hold repeats**: press-and-hold advances the value past
  one step (pump the repeat cadence). Mutation: remove the auto-repeat
  timer → reddens {holding the stepper's + button advances the count}.
  Control: a single-tap test stays green.
- **M5 — the commit spends the whole pending count**: Smelt n moves ore by
  −2n and ingots by +n in one press; a brew of n calls the transaction n
  times (craft stream advances n times — asserted via a forced stream and
  the loss tally); the gold dials move the exact amount. Mutation: make
  the commit perform one unit regardless of the pending count → reddens
  {the smelt commit spends the whole pending count} and {the gold dial
  banks exactly the dialed amount}. Controls: the n = 1 commit tests stay
  green.
- **M6 — the brew cap clamps at the pack**: herbs for 6, room for 3 → MAX
  dials 3, and the commit succeeds 3 without touching the pack refusal.
  Mutation: the cap ignores pack room → reddens {the brew cap clamps at
  the pack's room}. Control: the herbs-side cap test stays green.
- **M7 — the brew batch notice tells the truth**: a batch with one failure
  renders the CraftLoss reason verbatim; a batch with two failures of five
  renders "2 of 5 brews fail and take 6 herbs"; a clean batch clears the
  notice; a level-up beside a loss does not override the loss (D123
  ruling 3). Mutation: the notice reports only the LAST attempt's answer →
  reddens {a brew batch says how many brews failed}. Controls: the
  clean-batch and verbatim-single-loss tests stay green.
- **M8 — the bench splits by position**: the worn piece renders under
  WORN STEEL, the carried copy under CARRIED STEEL, and "(worn)" appears
  nowhere on the screen. Mutation: render both rows under one heading →
  reddens {the forge bench splits into worn steel and carried steel}.
  Control: the temper rows' price/refusal tests stay green.
- **M9 — the merchant stacks and taps move one**: three healing potions on
  the shelf render as `Healing potion ×3` with the per-item price; a Buy
  tap removes exactly one from stock; a Sell tap sells exactly one; a
  buy-back tap buys back exactly one. Mutation: a stacked tap moves the
  whole stack → reddens {a stacked buy tap buys exactly one} (+ sell and
  buy-back variants). Controls: the single-item row tests stay green.
- **M10 — the fixed bank buttons retire**: "Bank 10" / "Bank all" /
  "Take 10" / "Take all" appear nowhere on the bank screen; the dials
  carry the work. Mutation: re-render one fixed button → reddens {the
  bank's fixed gold buttons are gone}.
- **Band trail** (content suite): all five lines byte-identical — crypt
  16/40, casting 40/40, greedy 16 / fleetfoot 13, sea-cave 26/40, keep
  24/40. The bot never visits town screens and no core file changes; the
  trail is the proof, not an assumption.
- **Goldens**: v3 save documents byte-identical.

Mutation reds are recorded as named sets, never counts (house method).
**Sequencing traps:** none — no mutation deletes code the change itself
removes before the change (M1/M2/M10 re-introduce old or new shapes that
can run at any commit). Report both halves per row: the named red set AND
the named controls that stayed green.

## Hazards

- **D113 first run**: the build loop is `flutter test` per package directory
  (D101), NEVER the emulator. The AVD pass happens ONCE at unit close (one
  install + save ritual + scripted taps + greyscale shots). Paint-timing and
  real-disk defect classes stay device-pinned — if a widget test cannot see
  a defect class, it belongs to the AVD pass, not to more widget tests.
- **`_onAPhone` on every screen-shaped widget test** — a default-surface
  (800×600) assertion measures a screen no player has (follow-up 26).
- `find.textContaining` is case-sensitive with no parameter — match literal
  casing or regex (standing trap).
- `scrollUntilVisible` scrolls ONE way — assertion sequences on a long
  screen must be monotonic in document order (standing trap).
- Tap-and-hold in widget tests: pump the cadence with `tester.pump(const
  Duration(...))` — real timers, not fake async shortcuts; a repeat that
  only fires on real wall-clock time is untestable and wrong for CI.
- **The D56 lesson, restated**: no new profile fields — grep any new field
  against every boundary that copies a profile. This unit expects ZERO new
  profile fields; if the build finds itself adding one, stop and report.
- The brew batch advances the craft stream once per unit of work — a batch
  is NOT atomic and its draws are state-carried; a determinism test pins
  same-seed-same-pending-count → identical outcome.
- Format/analyze premises need resolution first (D115): `dart pub get` per
  package before any format or analyze claim; analyze from the WORKTREE
  ROOT with pwd quoted.
- The harness auto-format hook can re-dirty a file seconds after a revert —
  re-check `git status --porcelain` a beat later (D115).
- Background-runner shells may be fish — wrap watch/suite commands in
  `bash -c`. This monorepo has NO root pubspec (D101). Never commit
  anything under `docs/epic/`.
- **Worktree anomaly (D126):** verify the worktree exists right after
  creating it AND again at dispatch.
- Accessibility binds every visual fork: state by shape, marking, position,
  or word — never hue; every screen must read in greyscale (the author's
  eye is the final authority).

## Follow-ups to log

- Bank item-list stacking (follow-up 16's other half) stays open — V7's
  ruling names the merchant lists only.
- The tavern's dual-source notice (`town.notice ?? world.notice`) is
  untouched by V5 and unchanged.
- The other hand-rolled phone sizings (world, battle, roster, boot files)
  migrate to the shared helper opportunistically in a later unit.

## Definition of done

- Suites green per package directory (no root pubspec — D101), counts
  stated from result files with the hidden-filter arithmetic; the app suite
  carries the new merchant/bank widget tests and the shared phone helper.
- All five band lines verbatim from the architect's own run; goldens
  byte-identical; save v3 stands; NO core/content diff.
- Format clean ×3, analyze clean ×3, resolution first, worktree root.
- Mutation rows re-run by the architect's own edit, reds as named sets,
  controls named and green.
- The AVD acceptance pass at close: one install + save ritual (BOTH slots
  aside FIRST, checksums) + scripted taps + greyscale shots read in pixels.
- `docs/plans/` plan doc rides the branch; nothing under `docs/epic/`
  committed, ever.