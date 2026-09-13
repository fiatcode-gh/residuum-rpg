# m3-town-ux Implementation Plan

> Execute with flow-executing-plans, task by task.

**Goal:** The town's benches and lists finish the grammar verdicts V3+V5+V6+V7
asked for: the forge price always visible beside its refusal word, the notice
stops following the hero to the character screen, counted work on the benches
and the bank (stepper + MAX + tap-and-hold, committed in one press), the forge
bench split into WORN STEEL and CARRIED STEEL, and the merchant's three lists
stacked into one row per stack with every tap moving exactly one item.

**Spec:** `/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/m3-town-ux-spec-M3TUX.md`

## Global constraints

- App-side only: a diff touching `packages/core` or `packages/content` is a
  scope breach — stop and report.
- `flutter test` runs per package directory (`cd packages/<pkg> && flutter
  test`); this monorepo has NO root pubspec.yaml.
- Git as `cd <worktree> && git <cmd>`; never commit anything under `docs/epic/`.
- Save v3 stands; zero new profile fields; goldens byte-identical.
- Every screen-shaped widget test pumps through `onAPhone` (1080×2424 @ 2.625).
- Accessibility: state by shape, marking, position, or word — never hue alone;
  every screen reads in greyscale.
- Dartdoc `///` on public app API only where it argues a decision; no comments
  in bodies; ubiquitous language (temper, affix, beat, rumor, residue).
- `dart pub get` per package before any format/analyze claim; analyze from the
  WORKTREE ROOT, three runs each.
- Characterization tests pass against unmodified `bd848f7` before any behavior
  change; each is flipped in the same commit as the change it pins.
- Mutation reds are named sets, never counts. Every commit's suite state is
  green.

### Measured facts this plan stands on (bd848f7)

- `wear()` removes the worn piece from inventory (`withoutFirst`, wear.dart),
  ids unique by design → a worn piece appears exactly once; the
  WORN/CARRIED split is the existing two halves of `temperable`.
- `depositGold`/`withdrawGold` take an `int amount`; refusals are ≤ 0 and
  shortage only — a clamped pending amount can never refuse.
- `smeltRefusal` = ore < 2; `brewRefusal` = herbs < 3 then pack full
  (`inventoryCap`, a core export already used app-side in `game_bloc.dart:428`).
  Brew cap = min(herbs ÷ 3, 20 − inventory.length); neither cap can make a
  clamped batch refuse mid-way (herbs only fall by 3 per attempt; the pack
  grows only on a success ≤ room).
- `stackKey` covers every price input of `sellPriceOf` (base fields, temper,
  rarity.affixCount, teaches — all keyed by base.id/rarity/temper) → same key
  ⇒ same price. Measured shelf probe: Stonebridge seed 4 visit 1 = 3 identical
  potions (Buy 20) + 1 helm (Buy 24).
- Bloc moves already move exactly one item per press (ids unique; `_find`
  first-match, `sellItem`/`buyItem` single). A stacked row tap stays one item.
- Stonebridge shelf always carries `stockedPotions` = 3 identical potions, so
  the For-sale list has a forced duplicate for tests.

## Task 1: Characterization baseline (test-only, green at bd848f7)

**Files:**
- `packages/app/test/support/phone.dart` (new)
- `packages/app/test/widget/craft_rooms_test.dart`
- `packages/app/test/widget/character_screen_test.dart`
- `packages/app/test/widget/bank_screen_test.dart` (new)
- `packages/app/test/widget/merchant_screen_test.dart` (new)

- [x] Write the tests pinning today's behaviour:
  - forge: a gate-refused row HIDES the next tier's price
    (`find.text('Next tier: 2 ingots.')` → findsNothing); a ceiling row says
    so and names no price (stays green through the change — M1 control).
  - forge/alchemist: ONE press spends exactly one unit (ore 4 → tap Smelt →
    `{ore: 2, ingot: 1}`; herbs 9 → tap Brew → 1 potion, 6 herbs).
  - character screen: a notice in state renders `— the forge speaks.`.
  - bank: the four fixed buttons `Bank 10` / `Bank all` / `Take 10` /
    `Take all` exist; one press moves exactly 10 / the whole purse.
  - merchant: three shelf potions render three `Buy 20` rows; three sold
    items render three `Buy back 10` rows; three carried potions render three
    `Sell 10` rows; `×` appears nowhere.
- [x] Run `cd packages/app && flutter test test/widget/` — all green against
  UNMODIFIED bd848f7.
- [x] Commit `test: pin the town grammar the playtest verdicts replace`.

## Task 2: Plan doc + shared phone helper adoption

**Files:**
- `docs/plans/2026-09-08-m3-town-ux.md` (this file, committed ON the branch)
- `packages/app/test/widget/world_screen_test.dart` — `_onAPhone` body moves to
  `support/phone.dart`; the file imports it.
- `packages/app/test/widget/craft_rooms_test.dart`,
  `craft_surfaces_test.dart`, `character_screen_test.dart`,
  `disabled_controls_test.dart` — adopt `onAPhone` where they pump the
  touched screens (craft_rooms' door test and character_screen's tests drop
  their hand-rolled `_phone`).

- [ ] Move the helper; sweep the touched files onto it.
- [ ] Run the app suite; fix any overflow the phone surface exposes (real
  defects the 800×600 default was hiding) or test-ordering breaks.
- [ ] Commit `docs:` plan + `test:` helper adoption separately; plan doc
  message `docs: m3-town-ux build plan`.

## Task 3: CountStepper — the counted control

**Files:**
- `packages/app/lib/town/town_style.dart` — `CountStepper`.
- `packages/app/test/widget/count_stepper_test.dart` (new).

- [ ] Write failing tests: + / − move the value by one; MAX jumps to the cap;
  + dead at the cap; − dead at 0; hold on + advances past one step via
  `tester.pump(const Duration(milliseconds: 400))` then
  `tester.pump(const Duration(milliseconds: 120))`.
- [ ] Implement:

```dart
/// A counted control: − / value / + / MAX, with tap-and-hold auto-repeat.
///
/// ...
class CountStepper extends StatefulWidget { ... }

/// One tap steps once at press-down. A hold repeats: first repeat after
/// [holdFirstRepeat], then every [holdCadence] — the cadence is a constant so
/// a widget test can pump it and CI never waits on wall-clock.
static const Duration holdFirstRepeat = Duration(milliseconds: 400);
static const Duration holdCadence = Duration(milliseconds: 120);
```

  − dead at 0, + and MAX dead at the cap (`onPressed: null`); the value is a
  number, the ± are glyphs, MAX is a word — greyscale by construction.
- [ ] Run, confirm green. Commit `feat: the counted control for counted work`.

## Task 4: Forge — V3 price grammar and the WORN/CARRIED split

**Files:**
- `packages/app/lib/town/town_bloc.dart` — `wornSteel` / `carriedSteel`
  getters (the two named halves; `temperable` = their concatenation).
- `packages/app/lib/town/forge_screen.dart` — refused rows render reason AND
  price as separate lines; ceiling rows the ceiling sentence only; the bench
  reads WORN STEEL then CARRIED STEEL; `(worn)` suffix and `_isWorn` retire.
- `packages/app/test/widget/craft_rooms_test.dart` — flip the gate-refused pin
  to findsOneWidget (price visible beside the reason).

- [ ] Flip the characterization to the new grammar; write failing tests: the
  price line appears on a gate-refused row; WORN STEEL / CARRIED STEEL
  headings; `(worn)` nowhere; worn piece above the CARRIED STEEL heading and
  carried piece below it.
- [ ] Implement the split and the two-line row.
- [ ] Run, confirm green. Commit `feat: the forge names the next tier's price
  beside every refusal`.

## Task 5: Character screen drops the notice

**Files:**
- `packages/app/lib/town/character_screen.dart` — remove `Notice(state.notice)`.
- `packages/app/test/widget/character_screen_test.dart` — flip the pin:
  `findsNothing` with a notice in state.

- [ ] Flip; implement; run; confirm the forge's notice test stays green (M2
  control). Commit `feat: the character screen stops carrying the town's
  notice`.

## Task 6: Counted benches — batch smelt and brew

**Files:**
- `packages/app/lib/town/town_bloc.dart` — `SmeltPressed`/`BrewPressed` gain a
  count; `_onSmelt`/`_onBrew` loop the core transactions; the brew batch
  notice aggregate (dartdoc'd as a sanctioned UI-local wording beside bank's
  two shared sentences in spirit).
- `packages/app/lib/town/forge_screen.dart` — the smelt stepper (cap =
  ore ÷ `smeltCost` floor) replacing the one-press button.
- `packages/app/lib/town/alchemist_screen.dart` — the brew stepper (cap =
  min(herbs ÷ `brewCost`, `inventoryCap − inventory.length`)); the pack-cap
  sentence stays for the genuinely full pack.
- `packages/app/test/town_bloc_test.dart` — batch semantics: smelt n moves
  ore −2n / ingots +n in one press; brew n advances the craft stream n times
  (forced stream, loss tally); 1-of-5 failure renders the reason verbatim;
  2-of-5 renders `2 of 5 brews fail and take 6 herbs`; clean batch clears;
  a level-up beside a loss does not override; same seed + same pending count
  → identical outcome.
- `packages/app/test/widget/craft_rooms_test.dart` — flip the one-press pins
  to stepper + commit semantics (n = 1 commit controls for M5); stepper cap
  tests (M3, M6).

- [ ] Batch handler shape:

```dart
void _onSmelt(SmeltPressed event, Emitter<TownViewState> emit) {
  final before = state.profile;
  var profile = before;
  TownRefusal? refusal;
  for (var i = 0; i < event.count; i++) {
    final (after, answer) = smeltOre(profile);
    if (answer != null) { refusal = answer; break; }
    profile = after;
  }
  // a refusal with nothing done is the honest answer; work done clears or
  // speaks the level-up, compared across the whole batch
  ...
}
```

  Brew counts failures; f = 1 renders the loss reason verbatim, f ≥ 2 renders
  `'$f of ${event.count} brews fail and take ${brewCost * f} herbs'`; a loss
  wins the slot over a level-up (D123 ruling 3).
- [ ] Screens hold the pending count as view state (`StatefulWidget`), clamp
  on every build, commit dispatches `SmeltPressed(clamped)` /
  `BrewPressed(clamped)` once; commit dead at 0; dial re-clamps when state
  shrinks.
- [ ] Run, confirm green. Commit `feat: counted benches — one commit press,
  the whole pending count`.

## Task 7: Bank — two gold dials

**Files:**
- `packages/app/lib/town/bank_screen.dart` — the four fixed buttons become two
  `CountStepper`s (bank side cap = `gold`, take side cap = `bankedGold`), each
  with its own commit calling the core ONCE with the amount; the :19-28
  dartdoc rewritten honestly (fixed buttons retired BY USER RULING, D63; the
  cap clamp keeps the one-button-says-it property).
- `packages/app/test/widget/bank_screen_test.dart` — flip the pins: the four
  labels appear nowhere; the dial banks/takes exactly the dialed amount; MAX
  = the whole side; `purseIsShort` / `vaultIsShort` stay for the empty side.

- [ ] Flip; implement; run. Commit `feat: the bank dials its gold`.

## Task 8: Merchant — three stacked lists

**Files:**
- `packages/app/lib/town/merchant_screen.dart` — all three lists stack by
  `stackKey` (the pack's `_stacked` machinery); a row's label gains `×$count`
  via `ItemStack.label`; price words per-item; every tap moves exactly one.
- `packages/app/test/widget/merchant_screen_test.dart` — flip the pins: three
  potions render one `Healing potion ×3` row with the per-item price; a Buy /
  Sell / Buy-back tap moves exactly one (bloc state asserted).

- [ ] Flip; implement; run. Commit `feat: the merchant's shelves stack`.

## Task 9: Mutation table M1–M10

Run every row against the finished tree; record each row's sed/edit, its
named red set, and its named green controls. Report both halves per row.

## Task 10: Verification

- Suites per package directory, strict counts from `--reporter json` result
  files with the hidden-filter arithmetic, compared to the fresh baseline
  (target: 2077 + the unit's new tests, all green).
- Band trail: five lines byte-identical (crypt 16/40, casting 40/40, greedy
  16 / fleetfoot 13, sea-cave 26/40, keep 24/40).
- Goldens byte-identical; save v3 stands; zero core/content diff.
- `dart pub get` ×3, format clean ×3, analyze clean ×3 from the worktree root.
- `git status --porcelain` clean (re-checked a beat later).

## Task 11: AVD acceptance pass (final gate, ONCE)

Save ritual FIRST (both slots aside, sha256), install, scripted taps through
the new surfaces, greyscale shots, saves restored byte-exact, shots mirrored
to the channel. Paint-timing and real-disk findings are reported, not fixed.

## Task 12: REPORT.md + done notice

Mirror the full verification block to the channel's `REPORT.md`; append the
done notice to `worker.md`.

---

Phase-skip note (flow-writing-plans): the plan-approval stop is covered by
the dispatch itself — the architect's build prompt (user-brokered) orders
this plan written, committed, and executed, with corrections arriving over
the mailbox. Execution happens here in the same session (worker dispatch).