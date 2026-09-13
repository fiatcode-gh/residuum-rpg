# m3-fixes — Recon (M3F)

## VERDICT

Both playtest defects are real and mechanically understood: the road-encounter
builder predates M3M/M3C and omits three profile fields (plus mana), and
gathering nodes render only inside live FOV so the remembered map erases them.
Both are untested today. The town character menu is a strong reuse story: the
dungeon Pack screen already contains every section it needs. No band, no
fingerprint, no save shape moves.

## State verified before measuring

`main` = `54ec315` (PR #12 merged 2026-08-29; suites re-run green this session:
762 core + 530 content + 498 app = 1790; all four band lines byte-identical to
the D58 baseline, quoted in D62). No worktrees, no branches in flight. All
measurements below were taken on `54ec315` by the architect (own reads) and
two read-only recon agents, with the architect re-reading the sharpest
claims at source.

## The measurements

**Road-encounter boundary (defect 1).** `startRoadEncounter`
(`packages/content/lib/src/world.dart:390-425`) constructs the ambush
`GameState` from the m3-world-era field list: `gold, `inventory, `equipment, `skills, `visit` are carried; `spells` (default `const {}, `game_state.dart:57`), `knownSpells` (`:59`... actually `:58-59` region:
`knownSpells = const {}`), `materials` (`const {}`), and `mana` (`0, `game_state.dart:62`) are NOT — they default. `endRun`
(`run_boundary.dart:113-124`) then copies `knownSpells` and `materials` (and
everything else) back into the profile — carrying the encounter's empty
defaults home. Consequences, all verified at source:

1. Any road fight wipes the profile's learned spells and gathered materials.
2. Casting is impossible during road fights (empty `spells` map, mana 0).
3. A book read during a road fight is refused ("written in a hand you cannot
   read", `read.dart:37` gates on the `spells` map).

The correct treatment already exists one door over: `startDungeonRunAt`
(`dungeons.dart:379-386`) passes `spells: spellsById` into `startRun, and
`startRun` itself (`run_boundary.dart:92-94`) carries
`knownSpells: profile.knownSpells, `materials: profile.materials, `mana: heroMaxMana(profile.loadout)`. `spellsById` lives in content
(`spells.dart:118-119`), the same package as `startRoadEncounter`.

**Remembered node rendering (defect 2).** `gatherNodesOn`
(`gathering.dart:106-131`) places `rng.rollRange(band.fewest, band.most)`
nodes per floor from the salted stream `seed ^ gatherSalt` (`0x6A1E`);
bands are `fewest: 1, most: 3` for all three dungeons; "Never zero" is an
explicit dartdoc invariant (`gathering.dart:44`). Both floor builders call
it last (`new_game.dart:109-113, `dungeons.dart:358-363`). Candidate pool is
plain `Tile.floor` minus hero spawn; connectivity is generator-guaranteed.
Save codec round-trips nodes (`run_codec.dart:50/135/159/177, `craft_codec`).
**Spawn is NOT defective.** The defect is presentation: `_GlyphPainter.paint`
(`glyph_grid.dart`) draws terrain at `_rememberedOpacity = 0.4` when
explored-but-not-visible (`:218-221` region), but the node loop
(`:179-182`) is `if (!game.visible.contains(node.key)) continue;` — a
remembered node renders as plain floor. Compounding: nodes are deliberately
painted UNDER litter and monsters (`:136-145` dartdoc), floors are 24×16 to
36×22 against a fixed viewport, and gathering demands standing on the tile
(`canGather => nodeUnderfoot != null, `game_bloc.dart:249`). The painter's
own doctrine contradicts the code: "a vein is part of the place — it is not
going anywhere" (`:136-138`).

**Town character menu (item 3).** Dungeon Pack: `InventoryScreen`
(`inventory_screen.dart:24`) — one ListView of sections: derived stats
(attack range, armour, dodge, speed, HP, mana, ward, `:110-128`), Spells
(`_SpellRow`), Worn (six `EquipSlot` rows), Carried (`packSections` from
`item_presentation.dart:85` — weapons/armour/potions/books), Materials
(every material even at zero), Skills (`_SkillRow, all `SkillId` values,
level + XP bar). Town Gear today: `GearScreen` (`gear_screen.dart:30`) — a
`TownRoom` with only Worn, wearables ("In your pack"), and Books; events
`TakeOffPressed` / `WearPressed` / `ReadBookPressed`; state `state.profile`.
Town doors: seven `FilledButton`s at `town_screen.dart:96-121, opened by
pure `Navigator.push` (`_open, `:133`) — no new bloc events needed. Shared
presentation grammar: rarity = `marking` glyph + tier word in a fixed 28px
column, schools = `schoolMarking` + `schoolWord, empty = `—, materials =
mark + word + count (`town_style.dart:108/199, `gear_screen.dart:166,239`).

## Is each inherited gate real?

- "Adding the encounter fields might move a band" — DISSOLVED: the
  survivability bot enters only through `startDungeonRunAt`
  (`survivability_test.dart:147-153`); road seeds are separate
  (`ambushGroundSeed`/`ambushFightSeed, `world.dart:392,404`); the fix adds
  NO rng draws (constructor arguments only). No band can move.
- "`dungeon_door_characterization_test.dart` is the sharpest tripwire" —
  real but UNTOUCHED: zero road/encounter references; the fix does not enter
  its scope.
- "Characterization tests exist for the encounter carry list" — real:
  `world_test.dart` group "walking into a road fight" (`:616+`) pins
  `isEncounter, encounter width, no stairs, first-move energy, and "brings
  the hero as they are, purse and pack and all" (`:632-643, gold/inventory/
  equipment/skills/hp). No test asserts the empty knownSpells/materials or
  mana-0 defaults, so nothing currently pins the defect as correct.
- "Some test would catch the spell/materials wipe" — DISSOLVED (the opposite):
  every `endRun` round-trip test goes through `startRun`
  (`run_boundary_test.dart:387-396, 439-472, 543-638`); the app's
  "coming home off the road" group (`town_bloc_test.dart:470-600`) never
  asserts knownSpells or materials survive. The wipe is untested at every
  layer — red tests are free to write.
- "Node rendering is pinned somewhere" — DISSOLVED: no app test instantiates
  GlyphGrid/CustomPaint; `palette_test.dart:77-111` pins only color
  constants. Remembered-node rendering (and remembered-terrain rendering!)
  has no instrument today.

## Findings that change the spec

1. The fix is FOUR constructor arguments in one content function — but its
   test surface spans three suites (content round-trip, core contract via
   endRun already covered, app bloc "coming home off the road").
2. The node fix needs a NEW instrument: nothing renders the painter today,
   and the repo forbids golden-image tests. The paint plan must become
   observable without screenshots (an extracted plan function, or painter-
   paint onto a recording canvas) — the spec names the requirement, the
   worker picks the seam and pre-declares it.
3. Remembered TERRAIN rendering is also untested; a characterization test
   for it is cheap and belongs in this unit (it passes against unmodified
   code and guards the same 0.4-alpha path the node fix rides).
4. The town character menu has no new bloc surface: it is `GearScreen`
   grown to the Pack shape, one door rename, and the existing three events.
   `craft_rooms_test.dart:68-92` pins the seven doors including `'Gear'` —
   a hand-edited golden (old value quoted in the same commit).
5. The user's current device save holds a hero whose spells/materials were
   already wiped. No migration exists or is wanted (v3 stands; the fix stops
   future wipes only) — the AVD pass states this rather than hiding it.

## Proposed shape of the work

One unit, `m3-fixes` (branch = build session name), off `54ec315, three
items in test-first order: (1) road-encounter carry — content red tests
first, then the four arguments; (2) remembered nodes — characterization
(terrain) then red (nodes) then the painter change; (3) character menu —
widget reds, then the screen. No save bump, no band re-pin, no plan-level
scope beyond the three items.

## Hazards to carry into the spec

- The D56 lesson: no table, no weight, no stream draw may change. Bands are
  controls and must come out byte-identical (all four lines, quoted).
- `world_test.dart` fingerprints (`_fingerprint` at `:9, `map.toAscii()`
  at `:739`) mean the encounter fix must add NO rng draws anywhere.
- Widget tests must size at least one new-screen test like a phone
  (follow-up 26; 1080×2424 precedent in `world_screen_test`).
- The AVD ritual in full: copy BOTH save slots aside BEFORE any install;
  `adb install -r` only (`flutter install` destroys data — burned twice);
  debug APK ~153 MB, check emulator free space; pin adb to `emulator-5554`.
- Greyscale rule: no hue-alone encoding; the Pack grammar carries over.
- No game rule may move into a widget; the character menu stays presentation.

## What this recon did NOT check

- It did not measure whether the road-fight UI exposes Pack reading today
  (whether a book is even reachable mid-ambush in the app) — the spec asks
  the worker to state what the encounter screen offers rather than assume.
- It did not verify the encounter's `bound`/`warded` lifecycle beyond the
  defaults; if a binding spell leaves state behind in a one-fight arena,
  that is the worker's to note, not a defect pre-declared here.
- It did not enumerate every widget test that pumps `GearScreen` beyond
  `craft_rooms_test` and the bloc groups named; the worker sweeps before
  renaming.
- It did not check whether `heroMaxMana` of a hero with no school skills
  (mana 0) makes the mana argument observable for a spell-less hero — the
  red test must school its fixture hero.
- It did not confirm the exact default of `GameState.spells` is `const {}`
  versus `const Spell map` typing beyond the constructor read — verified as
  `Map<String, Spell> spells = const {}` at `game_state.dart:57`; the
  line-number citations above were re-read by the architect and are
  trustworthy, but the worker re-reads them again in situ.