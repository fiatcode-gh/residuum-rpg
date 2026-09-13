# m3-craft-risk — story spec (M3CR)

Unit: `m3-craft-risk` · verdict V4 (craft economy) · wave position 5 of 6
(D98, as amended D103). Recon: `m3-craft-risk-recon.md`, measured fresh on
`e0544f4`.

## Goal

The forge and the alchemist become workshops all the way through: no gold,
and the balancer is training, not the purse. A temper can fail and cost one
ingot; a brew can fail and cost its herbs. Skill level is what tames the
odds. The tier-1 temper never fails — the teaching tier stays free of the
mechanic that would punish the hero it is meant to teach.

## Precedent

- V4 rulings LOCKED by the user (ledger, playtest #2): free benches,
  tier-based level-scaled odds, lose-one-on-fail, xp on failure.
- D98 locks this unit's scope and position; no re-fork.
- `run_boundary.dart` doctrine: town transactions are pure functions over
  `Profile`. V4 does not reopen that door — see the central contract.
- Save v3 stands (D59 doctrine, follow-up 20): this unit adds no version
  bump and rewrites no golden.

## Central contract: the craft stream lives on the Profile

The failure draw is the first random decision in town. The house rule binds:
every random decision draws from an `Rng` carried in state, and the crawl's
two streams must never feel it (`GatherAction`'s argument, one door over).
The shape that keeps the town pure AND the save at v3:

- `Profile` gains one field, `craftRngState` (int, the exported state of a
  splitmix64 `Rng`).
- Seeded lazily: on the first draw of a hero whose field still reads
  default, the transaction constructs `Rng(profile.worldSeed ^
  craftSeedSalt)`, draws, and writes the advanced state back. Old saves
  without the key boot clean; no migration.
- `craftSeedSalt` is a core constant beside the odds table, chosen by
  collision sweep against the loot stream's early sequence on the fixture
  heroes (house method, `lootSeedSalt`'s precedent).
- The transaction signatures do not change: `temperItem(profile, itemId)`
  and `brewPotion(profile, potion)` construct the stream from the profile,
  draw once, and return the profile with the advanced state — the same pure
  shape they have today. `town_bloc` touches nothing new.
- **One attempt, one advance.** Every temper and brew attempt draws exactly
  once, including attempts the 0% tier cannot fail — stream consumption is
  a fact about the attempt, not the outcome, and the determinism story
  stays one sentence long.
- Codec: `craftRngState` encodes omit-on-default on the `itemNumber`
  precedent (`profile_codec.dart:44`), decodes by `containsKey`. Absent
  key = default = lazy seed. Save v3 stands; the goldens do not move.

## The odds

Where `level` is the relevant skill's level and `gate` the tier's
Blacksmith gate (5 for tier 2, 10 for tier 3):

- Temper tier 1: **never fails** (0%).
- Temper tier 2: **20% − 2% × (level − 5)**, floor 5%.
- Temper tier 3: **35% − 2% × (level − 10)**, floor 5%.
- Brew (the spec-time ruling D98 left to the architect): **20% − 2% ×
  level**, floor 5%, no gate. Herbcraft has no tiers and no gate today;
  inventing one would gate the only thing herbs are for behind training the
  hero has no reason to have started. Level 0 brews at 20%; the floor
  arrives at level 8.

## The transaction shapes

- **Failed temper**: exactly 1 ingot is lost. The item is unchanged. The
  skill trains (`trainedIn` — practice is practice, locked ruling). The
  bench says so: a notice line in the town slot, worded with the loss, not
  a color.
- **Succeeded temper**: the tier's full ingots are spent, the item gains
  its tier, the skill trains. Gold changes hands nowhere.
- **Failed brew**: the brew's 3 herbs are lost. No potion. The skill
  trains. A notice line, same rule.
- **Succeeded brew**: unchanged from today.
- Smelting never fails — it is not a risk, it is a conversion.

## Retired things

- `TemperPrice.gold` and the 10/25/50 column; `temperRefusal`'s gold check
  and its "you cannot afford that" sentence.
- `forge_screen.dart`'s gold term in the price line ("… and 25 gold.")
  becomes the ingots-only line. The full price-line grammar (always
  visible, refusal word separate) is m3-town-ux's and is NOT built here.
- `temper.dart`'s dartdoc arithmetic that argues in gold ("Twelve ore and
  eighty-five gold takes a piece all the way") — rewritten to the new
  economics, in the same commits as the code.

## Test plan (TDD; core strict red → green → refactor)

Controls (prove the mechanic can fail to detect):

- **M1 — failure is reachable and tier-shaped**: at the tier-2 gate with a
  forced-fail stream state, a temper loses 1 ingot, leaves the item at
  +0, and trains Blacksmith. Mutation: make the draw never fail → this
  test and only its named set redden.
- **M2 — tier 1 cannot fail**: a forced-fail stream state at tier 1
  tempers clean, spending the full 1 ingot, no loss line. Mutation: apply
  the tier-2 odds to tier 1 → reddens.
- **M3 — level scaling**: odds at level 5 vs level 13 differ by the
  2%-per-level table, floor clamps at 5% (boundary: the level that would
  go below it). Mutation: drop the floor → the boundary test reddens.
- **M4 — brew mapping**: level 0 → 20%, level 8 → 5% (floor), one
  boundary either side. Mutation: gate the brew odds → reddens.
- **M5 — lose-exactly-one**: a failure at tier 3 (price 3 ingots) costs 1,
  not 3. Mutation: charge the full price on failure → reddens.
- **M6 — stream discipline**: the crawl's streams are untouched by a
  craft attempt with a failure in it (same seed, same floor, roll for roll
  with a no-craft run); the craft stream advances exactly once per
  attempt, 0% tier included; the state round-trips the codec; a save
  without the key decodes and lazy-seeds. Mutation: draw from `rng`
  instead of the craft stream → the roll-for-roll test reddens.
- **M7 — gold retires**: `temperRefusal` no longer refuses a broke hero
  with ingots in hand; the forge price line renders without gold.
- **Band trail** (content suite): all five lines byte-identical — crypt
  16/40, casting 40/40, greedy 16 / fleetfoot 13, sea-cave 26/40, keep
  24/40. The bot never crafts; this is the proof, not an assumption.
- **Goldens**: v3 save documents byte-identical (omit-on-default carries
  it).

Mutation reds are recorded as named sets, never counts (house method).

## Hazards

- **The D56 trap, restated**: `craftRngState` must be added to
  `Profile.copyWith`'s parameter list, `props`, and every constructor
  path — grep the field against every boundary that copies a profile
  (`endRun`, `suspendRun`, `resumeRun` go through `copyWith`, so copyWith
  is the one door; `resumeRun` builds `GameState` field by field and does
  not carry the craft stream, correctly — it is town-side).
- **Never draw from the crawl's streams.** The town is reachable mid-run
  (camped); a craft draw from `rng` or `lootRng` would corrupt the suspend
  theorem's roll-for-roll guarantee on resume.
- **Format/analyze premises need resolution first** (D115): `dart pub get`
  per package before any format or analyze claim.
- Accessibility: the failure is a word in the notice slot, never a hue.

## Definition of done

- Suites green per package directory (no root pubspec — D101), counts
  stated from result files with the hidden-filter arithmetic.
- All five band lines verbatim from the architect's own run.
- Goldens byte-identical; save v3 stands.
- Format clean ×3, analyze clean ×3, resolution first.
- Mutation rows re-run by the architect's own edit, reds as named sets.
- `docs/plans/` plan doc rides the branch; nothing under `docs/epic/`
  committed, ever.