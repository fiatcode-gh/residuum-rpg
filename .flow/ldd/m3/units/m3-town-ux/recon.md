# m3-town-ux recon — measured fresh on `bd848f7` (2026-09-08)

**VERDICT:** All four verdicts (V3 forge price line, V5 notice town-only, V6
steppers + Worn/Carried, V7 merchant stacking) are buildable with ZERO core
changes — every needed seam already exists app-side. The one inherited claim
that dissolved: `depositGold`/`withdrawGold` already take an amount, so the
gold stepper needs no new core transaction; the batch-commit model needs a
notice-aggregation ruling because the town slot holds exactly one sentence.
This is the FIRST unit under the amended D113 widget-driven method.

**State verified before measuring:** `main` = `bd848f7` (m3-craft-risk, PR #9
shipped), local tree clean, no worktrees, `handoff/` retired, no dispatcher
watch. Suites of record: 2077 strict green (core 860 + content 579 + app 638).

Read-only fan-out (one Explore agent, seven-section brief) plus the
architect's own reads: `forge_screen.dart` in full, `town_bloc.dart`
(`temperable` :334-342), `wear.dart` (:103-123), `town.dart` gold
transactions (:379-413).

## Verdict V3 — forge price line (the grammar M3CR left half-built)

- `forge_screen.dart:132-140` renders `reason ?? 'Next tier: ${price!.ingots}
  ${price.ingots == 1 ? 'ingot' : 'ingots'}.'` in ONE slot — M3CR made the
  price ingots-only; a refused row still hides the price (reason wins the slot).
- `price = item.temper < maxTemper ? temperPriceFrom(item.temper) : null`
  (:106) — the ceiling case has NO price; it says "that is worked as far as
  it goes" (core refusal vocabulary, `temper.dart:87-100`).
- Reachable refusals on forge rows are exactly: the Blacksmith gate ("that
  needs Blacksmith N"), missing ingots ("that takes N ingot/ingots"), and
  the ceiling. "You are not holding that" / "only steel takes a temper" are
  unreachable here — `temperable` (:334-342) only lists held/worn temperable
  steel. The button is already dead on refusal (:119) with the reason beside
  it — the inn's rule, in place.

## Verdict V5 — the notice bar's placement

- `town_style.dart:239-249`: `class Notice` reads `SaveNotice? notice`,
  renders `— ${notice!.sentence}.` when set.
- Set on `TownViewState` by: `_noticed` (:804-813), `_settled` (:836-845 —
  every transaction/craft routes here, `SentenceNotice(answer.reason)`),
  `_crafted` (:797-801 — the level-up sentence), resume refusal (:533,
  :552), save failure (:847-849), boot (:376-384, :425-434).
- Consumers: forge :34, character_screen :52, town_screen :87, alchemist
  :36, inn :43, merchant :42, bank :44 — plus tavern :43, which reads
  `town.notice ?? world.notice` (a different source; NOT in this unit).
- **No test asserts the character screen's notice bar** — retirement touches
  no pinned assertion. State-level notice assertions live in
  `town_bloc_test.dart` and are unaffected (the notice mechanism stays; only
  the character screen stops rendering it).

## Verdict V6 — the one-press benches and the fixed bank

- **Smelt** — forge_screen.dart:40-59: one `FilledButton('Smelt')`, gated on
  `state.smeltReason`; consumes 2 ore → 1 ingot (`craft.dart:16`,
  `smeltOre` town.dart:218-231, one ingot per call).
- **Brew** — alchemist_screen.dart:55-71: one `FilledButton('Brew')`, gated
  on `state.brewReason`; consumes 3 herbs → 1 healing potion
  (`craft.dart:25`, `brewPotion`, one potion per call); refusals: "that
  takes 3 herbs" and pack cap "you cannot carry any more" (craft.dart:45-54).
  Brew now carries the risk draw (M3CR: `CraftLoss('the brew fails and takes
  3 herbs')`, town.dart:256).
- **Bank gold** — bank_screen.dart: four fixed buttons `Bank 10` / `Bank all`
  / `Take 10` / `Take all` (:74-97) dispatching `DepositGoldPressed` /
  `WithdrawGoldPressed` (bloc :815-820). `depositGold`/`withdrawGold`
  (town.dart:379-410) take an `int amount`, refuse on ≤0 and shortage — the
  clamped pending amount can never refuse, so the four buttons retire with
  no core change. The dartdoc at :19-28 argues FOR fixed buttons over a
  number pad — retired by the user ruling (D63); the dartdoc must be
  rewritten in the same commits.
- **Forge bench** — `temperable` (town_bloc.dart:334-342) already orders
  WORN pieces first, then carried; the "(worn)" suffix (forge :76-77,
  :115-117) exists because one merged list cannot say it by position. Wear
  removes the piece from inventory (`wear.dart:106-108`, `withoutFirst`), so
  a worn piece appears exactly once — the two sections are the two halves
  the getter already builds, and the id-based `_isWorn` retires with the
  suffix. The bench list source is app-side state (town_bloc), so the split
  is an app-side change.
- No stepper widget exists anywhere in the app; no tap-and-hold precedent
  either — this unit builds both (town_style layer). The repeat timing is a
  spec-time ruling of this unit.

## Verdict V7 — merchant stacking

- Machinery lives app-side in `packages/app/lib/game/item_presentation.dart`
  (NOT core): `stackKey` (:42-47 — base id, rarity, affix ids, temper),
  `ItemStack` (:50-61, `label` renders `Name ×$count` when count > 1),
  `packSections` (:85-94) with `_stacked` (:179-188).
- merchant_screen.dart: three raw `List<Item>` iterations — 'For sale'
  (`Buy ${buyPriceOf(item)}` → `BuyPressed(item.id)`), 'Sold this visit'
  (`Buy back ${sellPriceOf(item)}` → `BuyBackPressed(item.id)`), 'Your pack'
  (`Sell ${sellPriceOf(item)}` → `SellPressed(item.id)`). No stacking today.
  Unaffordable buy rows dead with `cannotAfford` (:12).
- Identical `stackKey` ⇒ identical price (every price input is in the key),
  so a stacked row has ONE price word; a tap moves one item.
- Bank item rows (bank :105-125) have no stacking either — follow-up 16's
  other half stays open; V7's ruling names the merchant lists only.
- NO dedicated widget test file exists for merchant_screen or bank_screen;
  their semantics are pinned state-level in `town_bloc_test.dart` (:766,
  :834). This unit adds the screens' widget tests.

## D113 — the phone-sizing helper

- `_onAPhone` exists ONCE, file-private: `world_screen_test.dart:1245-1249`
  — `physicalSize 1080×2424`, `devicePixelRatio 2.625`, `addTearDown(reset)`.
  Not importable. Six other files hand-roll their own sizing.
- This unit promotes it to a shared test helper; every test file this unit
  touches adopts it (user-ruled scope, 2026-09-08). testWidgets surface:
  202 across 18 files (world_screen_test 47, battle_view_test 28,
  suspend_door_test 20, craft_rooms_test 13, craft_surfaces_test 11, …).

## Greyscale / a11y invariants to preserve

- Forge doctrine (:15-18): nothing told apart by colour; a dead row carries
  its sentence rather than going grey. Materials are mark + word + number.
- `statLine` doc (item_presentation.dart:12-20): "reads in greyscale and it
  reads aloud"; `StatDelta.marker` is ▲/▼ by sign.
- The refusal word always comes from `TownAnswer.reason` / refusal strings —
  never UI-local on the craft screens (bank's two shared sentences and
  merchant's `cannotAfford` are the sanctioned UI-local exceptions).
- New UI (steppers, stacked rows) must read in greyscale and by word —
  counts are words (`×3`), sections are words (WORN STEEL / CARRIED STEEL).

## What this recon did NOT check

- Device-pinned defect classes remain device-only: paint timing, real font
  rendering beyond hit tests, the author's greyscale eye. The AVD pass stays
  the unit's final acceptance gate (D113).
- No instrument measures the bot visiting town screens — the band trail
  (all five lines byte-identical) remains the proof that nothing bot-visible
  moved; this unit changes NO core file, so the trail is the proof, not an
  assumption.
- Whether `Sold this visit` items with equal stackKey can ever differ in
  price was reasoned from the stackKey contents, not measured by a
  brute-force sweep; the key includes every price input, so the claim is
  structural.
- The tap-and-hold auto-repeat's timing constant and its behavior under a
  widget test (pumped clocks) are spec-time rulings, not recon findings.