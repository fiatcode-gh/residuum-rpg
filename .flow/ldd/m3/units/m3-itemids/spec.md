# m3-itemids spec — story M3I

Recon: `docs/epic/m3-itemids-recon.md` (read when a claim here looks
wrong — it carries the file:line evidence). Locked decision: D97/D98 —
hero-scoped mint, remove-one semantics, save v3 stands, rides the
post-playtest wave FIRST.

## Goal

Every item that enters the hero's pack or bank carries an id minted from
a hero-scoped counter that never resets, and every id-consuming action
removes exactly one item. Measurable effect: the duplicate-id defect —
verified live on the user's phone (a weapon deleted by drinking a
potion) — becomes impossible to mint and harmless to inherit, with save
v3 and every golden document byte-identical.

## Shape (precedents, read from the codebase)

- **Hero-scoped counter**: `Profile.brewNumber` (`profile.dart:35`) —
  lives on the profile, never resets, codecs round-trip it. The new
  counter is its sibling.
- **Omit-on-default codec field**: `actor_codec.dart:66/118` (`reach`) —
  encode `if (x != 1) 'x': x`, decode `containsKey ? intAt : 1`. The
  docstring there is the reason: an unconditional encode rewrites every
  golden document.
- **Run-ride machinery**: `GameState.nextDropNumber` — default at
  `game_state.dart:64`, increments at `step.dart:98/156`, write-back at
  `:215`, run codec round-trip. The new counter mirrors this exactly.
- **The boundary rule**: `startRoadEncounter`'s dartdoc
  (`content/world.dart:393-402`): "A field the profile gains later goes
  on this list the day it lands." The new field rides every boundary
  that carries `inventory` — no exceptions, no relying on copyWith.

## New files

None expected. If the worker finds a file wants splitting (CLAUDE.md:
files stay small), pre-declare it.

## Changed files (expected — deviations pre-declared, per doctrine)

- `packages/core/lib/src/town/profile.dart` — new field `itemNumber`
  (int, default 1), copyWith, props. Dartdoc on the model of
  brewNumber's, stating the contract it serves.
- `packages/core/lib/src/engine/game_state.dart` — new field
  `itemNumber` (int, default 1), copyWith.
- `packages/core/lib/src/engine/step.dart` — PickUpAction re-ids the
  taken item; Drink/Read/Drop removals become remove-one.
- `packages/core/lib/src/town/town.dart` — `_without` becomes
  remove-first-match-only; `temperItem`'s rebuild becomes replace-first.
- `packages/core/lib/src/loot/wear.dart` — `wear`'s carried rebuild
  removes the first match only.
- `packages/core/lib/src/town/run_boundary.dart` — `itemNumber` rides
  every boundary that carries inventory: startRun seeds it from the
  profile; endRun (alive), suspendRun, and the death/road paths write it
  back; resumeRun seeds `max(profile, suspended)`.
- `packages/content/lib/src/world.dart` — `startRoadEncounter` carries
  `itemNumber` on the carry list (the dartdoc's own rule).
- `packages/content/lib/src/save/profile_codec.dart` — omit-on-default
  encode/decode for `itemNumber` (absent reads as 1; no new refusal).
- `packages/content/lib/src/save/run_codec.dart` — omit-on-default
  encode/decode for `itemNumber` (same pattern; keeps run goldens
  byte-identical).
- `packages/core/lib/src/loot/item.dart` — a public way to re-id an Item
  (the private copy behind `tempered` at `:241-245` suggests the shape);
  if a full copyWith is wrong for the class, the narrow constructor is
  fine.

## Per-item contract

1. **The mint**: when an item leaves the ground and enters the hero's
   inventory, its id becomes `item-<n>` where `<n>` is the run's
   `itemNumber` before increment. Ground items keep their minted ids
   (`floor-*`, `drop-*`, `trophy-*`) — floor content is byte-frozen and
   must not move. Buying from the merchant does NOT re-id (`market-*`
   ids are visit-scoped and prefix-unique — proven in the recon);
   withdrawing from the bank does not re-id (banked ids are already
   hero-scoped); brewing keeps `brewNumber`.
2. **Remove-one**: every id-based removal removes exactly one item —
   the first match in the list's existing order. Legacy saves may hold
   duplicate ids; after this unit they can only lose one item per tap,
   never both. No migration, no version bump.
3. **The ride**: `itemNumber` flows across exactly the boundaries that
   flow `inventory`. A boundary that copies inventory but not
   `itemNumber` is a defect (the road dartdoc's rule). Death strips the
   pack; the counter still rides (uniformity — its value is then
   irrelevant).
4. **What must not change**: `brewNumber`'s codec shape (unconditional
   encode, required decode — legacy saves refuse without it);
   `nextDropNumber`'s machinery; floor litter/trophy/market/kit id
   formats; `saveVersion` 3; every pinned golden document.

## Behaviour arguments that must land in documentation

- **Why mint-at-pickup and not mint-at-drop**: floor content is
  deterministic from the seed and byte-frozen (the crypt layouts are a
  ruled tripwire); re-id-ing at the pack's door leaves every floor
  document untouched while making the pack's namespace hero-unique.
  The ground item's id is transient state; the pack item's id is
  durable identity.
- **Why remove-one is safe**: after the mint, ids are unique by
  construction, so remove-one and remove-all coincide on every pack the
  game can mint. On legacy packs they differ, and remove-one is the
  honest semantics: one tap, one item. This deliberately retires
  follow-up 23's `_find`/`_without` asymmetry.
- **Why omit-on-default**: the reach precedent's own argument — the v3
  goldens must not move. A field absent from every golden document is
  the only shape that proves nothing bot-visible moved.
- **Preserved defect**: `wear()`'s `firstWhere` still throws on an
  absent id (it cannot fire — the refusal guard runs first). Leave as
  is; do not "harden" it in this unit.

## Test plan

Characterization first — each must pass against UNMODIFIED `a567c19`:
- Current remove-ALL behaviour of drink/read/drop and one town path on a
  hand-built duplicate-id pack (constructed Items, two delves not
  required).
- Current first-match pricing/refusal on a duplicate-id pack (sell
  prices the first match; `wearRefusal` names the first match's base —
  the exact sentence the user saw).
- Pickup keeps the ground item's id today.
- `brewNumber` round-trips; a golden document encodes byte-identical
  (the existing pins, untouched, are themselves characterization).

Then the new-behaviour tests (red before the change):
- Duplicate-id pack: drink removes exactly one; the sibling survives
  with its id. Same for read, drop (the dropped item is the FIRST
  match), sell, deposit, withdraw, temper, wear.
- Mint: pickup re-ids to `item-1`, next pickup `item-2`; the counter
  increments once per item, not per tap.
- Ride: startRun seeds from the profile; suspend→resume preserves the
  incremented counter and reconciles with max(); endRun writes back;
  road fight: pickup inside the encounter, then the carry home keeps
  both the item and the counter.
- Codec: default profile encodes WITHOUT `itemNumber` (absent key);
  non-default encodes it; decode absent→1; decode present→value; no new
  refusal path. Run codec the same.
- Legacy safety: a hand-built save-shaped document holding duplicate
  `drop-N` ids decodes, and a remove removes one.

Mutation table (worker runs ALL, reports named red sets and greens):

| Row | Mutation | Expected red | Expected green (control) |
|---|---|---|---|
| M1 | pickup keeps the ground id (delete the re-id) | mint tests | floor/litter content tests — floor ids untouched |
| M2 | drink rebuild reverts to remove-all | duplicate-pair drink test | single-potion drink tests — removing the only match is identical |
| M3 | delete `itemNumber` from suspendRun's copy list | suspend-ride test | endRun-ride test (different door) — both halves reported |
| M4 | profile codec encode becomes unconditional | profile key-set/golden-adjacent test | run codec unchanged |
| M5 (control) | make `brewNumber` encode omit-on-default | the existing profile golden pin — proves the goldens are wired | version gate tests stay green |

Sequencing: M1–M2 mutate code the change replaces — run them against the
characterization suite BEFORE the flip and report; after the flip they
are meaningless. M3–M5 exist only after the change.

## Hazards

- **D56, verbatim**: grep the new field against EVERY boundary that
  copies one — the recon lists five doors; the worker re-greps anyway
  (`inventory:` across `run_boundary.dart` and `world.dart`) and
  pre-declares anything found beyond the spec's list.
- **The crypt tripwire**: `dungeon_door_characterization_test.dart` must
  stay green untouched; floor content is not touched by this unit — if a
  floor test reddens, stop and report, do not re-pin.
- **Bands**: nothing bot-visible may move. The survivability trail runs
  from the worktree and all five band lines must be byte-identical
  (crypt 16/40 `{1:1,2:9,3:8,4:6,5:16}`, casting 40/40, greedy 16 /
  fleetfoot 13, sea-cave 26/40, keep 24/40). A moved line is a stop.
- **Equatable props**: adding `itemNumber` to Profile's props is
  required for value semantics; do NOT add it to `Item`'s props (the id
  is already there).
- **No fvm**; plain `flutter`/`dart`. Analyze from the WORKTREE ROOT
  with pwd quoted. No commits under `docs/`.

## Follow-ups to log (not this unit)

- `market-*` ids are safe today because they are visit-scoped; if a
  future unit makes stock persist across visits differently, re-derive
  that proof. (Already half-covered by follow-up 16's bank stacking.)
- The `Item.affixes` List-in-props identity hazard remains follow-up 18.

## Definition of done

- All three suites green from the worktree root, counts read from result
  files, compared against a FRESH baseline measured on unmodified
  `a567c19` (core 793 + content 541 + app 563).
- All five band lines byte-identical, from the worker's own run.
- Golden save tests green UNTOUCHED (the byte-identical proof).
- Full mutation table reported, named red sets, greens included.
- `dart analyze .` clean from the worktree root, pwd quoted; format 0
  changed.
- `git diff main -- packages/core packages/content` shows only this
  unit's shape; no commits under `docs/`; nothing pushed.