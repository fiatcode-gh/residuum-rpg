# m3-craft-risk — recon (fresh, 2026-09-07)

Measured at source on `main` = `e0544f4`. No number inherited from D98 or
the V4 verdict text; every claim below was read in the tree this session.

## The terrain

- **Town transactions are pure functions over `Profile`** — the doctrine is
  written at `packages/core/lib/src/town/run_boundary.dart:31` ("Town is not
  a `GameAction`"): no clock, no map, and — the sentence that V4 collides
  with — *"nothing random about paying a stated price."* Crafting runs in
  the app's `town_bloc.dart:765-774` calling `smeltOre` / `brewPotion` /
  `temperItem` directly. **No `Rng` is in reach anywhere on this path.**
  This is the unit's central design question: where the failure draw lives.
- **Money paths today** (`craft.dart`, `temper.dart`, `town.dart`):
  - `smeltOre`: free (2 ore → 1 ingot), trains Blacksmith. No change.
  - `brewPotion`: free (3 herbs → 1 healing potion, `brewCost = 3`),
    trains Herbcraft. Already gold-free; V4 adds failure only.
  - `temperItem`: spends the tier's ingots **and gold**
    (`gold: profile.gold - price.gold`, town.dart:305), trains Blacksmith.
    V4 retires the gold term entirely.
- **The price table lives in core, not content**: `temperPrices` in
  `temper.dart:58` — gates Blacksmith 0/5/10, ingots 1/2/3, gold 10/25/50.
  M3C shipped it in core; the failure-odds table belongs beside it.
- **Refusal order is a contract** (`temperRefusal`, temper.dart:96): held →
  steel → ceiling → training → ingots → gold. The gold check and its
  sentence ("you cannot afford that") retire with the gold price.
- **Xp grant**: `trainedIn` (skill.dart:96) is the whole learn-by-doing
  grant; `xpToNext = 4 + 2·level`. Failure grants xp by calling the same
  helper on the failure branch.
- **The omit-on-default worked example is in the codec already**:
  `profile_codec.dart:44` — `if (profile.itemNumber != 1) 'itemNumber': ...`,
  with the argument in the dartdoc. A new profile field copies this shape
  and save v3 stands.
- **The gather precedent**: `GatherAction` "draws no random number
  whatsoever" (action.dart:112) because drawing would have shifted the
  crawl's streams. Crafting failure is the first town-side draw in the
  game; it needs its own stream, never the crawl's.
- **Stream salts**: `lootRng = Rng(profile.worldSeed ^ lootSeedSalt)` at
  `run_boundary.dart:74`, salt supplied by content. House method: salts
  chosen by collision sweep.
- **Forge screen** renders `'Next tier: ${price.ingots} … and
  ${price.gold} gold.'` at `forge_screen.dart:140` — the gold term retires
  THIS unit (the full price-line rework is m3-town-ux's, per D98's
  ordering note).
- **`Profile.copyWith` is hand-rolled field by field** (profile.dart:126).
  Every new Profile field must be added to it or every `copyWith` call in
  the codebase silently drops the field — the D56 trap, restated.
- **The balance bot never crafts.** Bands are expected byte-identical;
  proven by running the trail, not assumed.

## Rulings already locked (D98, restated as measured)

- Free benches: tempering loses its gold cost; brewing already free.
- Failure odds: tier 1 0%, tier 2 20%, tier 3 35%; each Blacksmith level
  above the tier's gate (5, 10) subtracts 2%; floor 5%.
- Failed attempt costs exactly ONE material (1 ingot / one brew's 3 herbs),
  result unchanged, retry allowed.
- Failure still grants its skill xp.

## What recon did not check

- Nothing on a device or emulator; no widget surface exercised.
- The merchant/bank/vault flows beyond confirming they do not touch
  `temperPrices` or the craft functions.
- The spec-time brew-odds ruling is the architect's to settle in the spec
  (D98 sanctions this); recon only confirmed Herbcraft has no tiers or
  gates today (`SkillId.herbcraft` appears with no gate anywhere in core).