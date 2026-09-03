# m3-itemids Implementation Plan

> Execute with flow-executing-plans discipline, task by task, in this build
> session (the build prompt orders execution here; it overrides the skill's
> stop-for-approval step).

**Goal:** every item entering the hero's pack carries a hero-scoped id
`item-<n>` minted at pickup from a never-resetting counter, and every
id-based removal removes exactly one item — with save v3 and every golden
document byte-identical.

**Spec:** `/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/m3-itemids-spec-M3I.md`

## Global constraints

- Worktree `.worktrees/m3-itemids`, branch `m3-itemids`, base `a567c19`.
  Every commit's exit state is green.
- No commits under `docs/` (build prompt standing rule — plan files stay
  uncommitted).
- `saveVersion` stays 3. No new refusal path. No version bump. No UI
  changes. No device operations.
- Omit-on-default codec shape: encode `if (x != 1) 'x': x`, decode
  `containsKey ? intAt : 1` (the `reach` precedent, `actor_codec.dart:66/118`).
- `brewNumber` codec shape untouched (unconditional encode, required
  decode). `nextDropNumber` machinery untouched.
- Equatable: `itemNumber` goes into Profile's props; NOT into Item's props.
- Floor litter / trophy / market / kit id formats untouched; floor content
  byte-frozen. `dungeon_door_characterization_test.dart` must stay green
  untouched.
- Bands byte-identical: crypt 16/40 `{1:1,2:9,3:8,4:6,5:16}`, casting 40/40,
  greedy 16 / fleetfoot 13, sea-cave 26/40, keep 24/40. A moved line is a stop.
- Plain `dart`/`flutter`, no fvm. Analyze from the worktree root, pwd quoted.
- Sandbox: `cd <repo> && git <cmd>`, never `git -C`.

## Design decisions (locked by the spec)

- Mint at pickup: `PickUpAction` re-ids the taken item to
  `item-<state.itemNumber>` and increments once per item. Ground ids
  (`floor-*`, `drop-*`, `trophy-*`) never change.
- Buy (market ids), withdraw (banked ids), brew (brewNumber) do not re-id.
- Remove-one everywhere an id picks a removal target: Drink/Read/Drop in
  `step`, town `_without` (sell/deposit/withdraw/readBook), `temperItem`
  replace-first, `wear` remove-first. First match in list order = oldest.
- Counter ride: `itemNumber` flows across startRun, endRun (both endings via
  `carried`), suspendRun, resumeRun (`max(profile, suspended)`),
  `startRoadEncounter`.
- `Item` gains a narrow re-id constructor on the `tempered` model.

## Task 1: Characterization suite (green on unmodified a567c19)

**Files:** `packages/core/test/engine/duplicate_id_test.dart`,
`packages/core/test/town/duplicate_id_test.dart`,
`packages/core/test/loot/wear_duplicate_test.dart`.

- [ ] Write characterization tests, all asserting CURRENT behaviour:
  - drink/read/drop remove ALL duplicate-id matches; the event carries the
    first match (constructed Items, one hand-built GameState).
  - pickup takes `here.last` and keeps the ground id.
  - town sell/deposit/withdraw/readBook remove ALL matches from the list
    they touch; sell prices the first match; temper replaces ALL matches in
    inventory and equipment.
  - `wearRefusal` on a duplicate-id pack names the first match's base;
    `wear` removes all matches.
  - brewNumber round-trips through the profile codec (existing pins cover
    the golden documents — cite, do not duplicate).
- [ ] Run the three new files — all green on unmodified code.
- [ ] Commit `test: duplicate-id characterization for m3-itemids`.

## Task 2: Pre-flip mutation phase (M1, M2)

No commit. Run against the characterization suite + the not-yet-green new
suites:

- [ ] M1 (pickup keeps ground id = current code): run the new mint tests
  against unmodified code — expect RED (named), proving they bite; the
  characterization pickup test green.
- [ ] M2 (drink remove-all = current code): run the remove-one drink test
  against unmodified code — expect RED (named); single-potion drink tests
  (control) green.
- [ ] Also run the floor/litter content tests (control green for M1) —
  `dungeon_door_characterization_test.dart`, `themed_floor_characterization_test.dart`.
- [ ] Record both phases; after the flip M1/M2 are meaningless (spec).

## Task 3: The counter fields and the re-id constructor

**Files:** `packages/core/lib/src/town/profile.dart`,
`packages/core/lib/src/engine/game_state.dart`,
`packages/core/lib/src/loot/item.dart`,
`packages/core/test/town/profile_test.dart` (or the duplicate suite).

- [ ] Failing test: `Profile(itemNumber: 5)` round-trips copyWith; default 1;
  props include it (value semantics).
- [ ] `Profile`: field `int itemNumber = 1` beside `brewNumber`, copyWith
  param, props entry, dartdoc stating the contract (hero-scoped, never
  resets, mints `item-<n>` at pickup).
- [ ] `GameState`: field `int itemNumber = 1` beside `nextDropNumber`
  (default, decl, copyWith).
- [ ] `Item.withId(String id)` on the `tempered` model (narrow constructor,
  same fields, new id; props untouched).
- [ ] Green; commit `feat: hero-scoped itemNumber counter and Item.withId`.

## Task 4: Codec rides (omit-on-default)

**Files:** `packages/content/lib/src/save/profile_codec.dart`,
`packages/content/lib/src/save/run_codec.dart`,
`packages/content/test/save/item_number_codec_test.dart` (new).

- [ ] Failing tests: default profile encodes WITHOUT `itemNumber`;
  non-default encodes it; decode absent → 1; decode present → value; run
  codec the same; no new refusal (a document without the key loads).
- [ ] Encode: `if (profile.itemNumber != 1) 'itemNumber': profile.itemNumber,`
  / run: same on `itemNumber`. Decode: `containsKey ? intAt : 1`.
- [ ] The why-omit-on-default argument lands beside the encode: the reach
  precedent's own reasoning — absent from every golden document is the
  only shape that proves nothing bot-visible moved.
- [ ] Golden save tests + profile_codec key-set pin stay green untouched.
- [ ] Green; commit `feat: itemNumber rides the save codecs omit-on-default`.

## Task 5: The boundary ride

**Files:** `packages/core/lib/src/town/run_boundary.dart`,
`packages/content/lib/src/world.dart`,
`packages/core/test/town/item_number_ride_test.dart` (new),
`packages/content/test/road_item_carry_test.dart` (new).

- [ ] Failing tests: startRun seeds `itemNumber` from the profile;
  suspend→resume preserves the incremented counter and reconciles
  `max(profile, suspended)`; endRun (alive) writes back; endRun (death)
  writes back with the pack stripped; road fight: pickup inside the
  encounter, `endRun` home carries both the item and the counter.
- [ ] `startRun`: `itemNumber: profile.itemNumber,`.
- [ ] `endRun` `carried`: `itemNumber: state.itemNumber,` (death path
  inherits via `carried`).
- [ ] `suspendRun`: `itemNumber: state.itemNumber,`.
- [ ] `resumeRun`: `itemNumber: profile.itemNumber > suspended.itemNumber
      ? profile.itemNumber : suspended.itemNumber,`.
- [ ] `startRoadEncounter`: `itemNumber: profile.itemNumber,`.
- [ ] Green; commit `feat: itemNumber rides every inventory boundary`.

## Task 6: Mint at pickup

**Files:** `packages/core/lib/src/engine/step.dart`,
`packages/core/test/engine/duplicate_id_test.dart` (mint tests).

- [ ] Mint tests (red against current code — already proven in Task 2):
  first pickup re-ids to `item-1`, next to `item-2`; ground siblings keep
  their ids; counter increments once per item.
- [ ] The why-mint-at-pickup argument lands in `PickUpAction`'s dartdoc or
  the local helper's: floor content is byte-frozen, the ground id is
  transient, the pack id is durable identity.
- [ ] `PickUpAction`: `inventory = [...inventory, taken.withId('item-$itemNumber')]`,
  `itemNumber++` before append (pre-increment value), event carries the
  minted item; local `var itemNumber = state.itemNumber;` beside
  `nextDropNumber`, write-back beside it at the main return.
- [ ] Green; commit `feat: pickup mints hero-unique item ids`.

## Task 7: Remove-one semantics

**Files:** `packages/core/lib/src/engine/step.dart`,
`packages/core/lib/src/town/town.dart`,
`packages/core/lib/src/loot/wear.dart`, existing suites.

- [ ] New-behaviour tests (red first): duplicate-id pack — drink/read/drop
  remove exactly one (the FIRST match; dropped item is the first match);
  sell/deposit/withdraw remove one; temper replaces the first match only;
  wear removes the first match only; sibling survives with its id.
- [ ] `step.dart` Drink/Read/Drop: remove first match only (indexWhere +
  removeAt helper, local to the file or shared — duplicate twice rule).
- [ ] `town.dart` `_without`: remove first match only.
- [ ] `temperItem`: replace first match only — inventory scanned first (the
  `_held` order), else the first matching equipment entry.
- [ ] `wear.dart`: remove first match only.
- [ ] The why-remove-one argument lands in `_without`'s dartdoc: after the
  mint, ids are unique by construction so remove-one ≡ remove-all; on
  legacy packs one tap takes one item. Retires follow-up 23's asymmetry.
- [ ] All existing suites green (single-item packs: remove-one ≡ remove-all).
- [ ] Green; commit `feat: id-based removals take exactly one item`.

## Task 8: Mutation phase M3–M5 (post-flip)

No commit. Named reds and greens:

- [ ] M3: delete `itemNumber` from suspendRun's copy list → suspend-ride
  test RED; endRun-ride test GREEN (different door).
- [ ] M4: profile codec encode becomes unconditional → key-set/golden-
  adjacent test RED; run codec test GREEN.
- [ ] M5 (control): `brewNumber` encode becomes omit-on-default → existing
  profile golden/key-set pin RED (proves the goldens are wired); version
  gate tests GREEN.

## Task 9: Full verification

- [ ] All three suites green from the worktree root; counts read from
  result files, compared against the fresh a567c19 baseline.
- [ ] Survivability trail re-run; all five band lines byte-identical.
- [ ] `dart analyze .` clean from the worktree root (pwd quoted);
  `dart format --output=none --set-exit-if-changed .` exits 0.
- [ ] `git diff main -- packages/core packages/content` shows only this
  unit's shape; no commits under `docs/`; nothing pushed.
- [ ] Reviewer dispatch: spec-compliance + quality review (one reviewer may
  carry both).
- [ ] REPORT.md in the channel directory; done notice appended.

## Verification map (what proves what)

| Claim | Proof |
|---|---|
| Goldens byte-identical | `golden_save_test.dart` + key-set pin green untouched |
| Nothing bot-visible moved | survivability trail, five lines verbatim |
| Remove-one semantics | duplicate-id suites, named tests |
| Mint | pickup mint tests + counter ride tests |
| Legacy saves safe | absent-key decode tests + duplicate-id removal tests |
| Determinism | same seed → identical floors (existing determinism tests green) |