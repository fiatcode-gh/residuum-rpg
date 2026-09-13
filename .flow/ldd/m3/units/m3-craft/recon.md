# Recon — m3-craft (M3C): gathering nodes, forge, alchemist, tempering

Date: 2026-08-25, architect session, on `main` @ `83b5336`. Four read-only
agents (save/skills, floor/tiles, town/camp/economy, item/temper/materials);
load-bearing claims re-read at source by this architect. Paths repo-relative
under `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/`.

## VERDICT

The unit is buildable at effort M **if** materials are counters and gathering
stays off the item tables — then every band line holds byte-identical as a
control, truthfully this time (nothing touches a drop table, a weight total,
or the combat/loot streams; the M3M failure mechanism is absent by
construction). The two real decisions: the save format must break again (two
new skills collide with save v2's own "this is the last break" dartdoc — and
zero version-2 saves with progress exist, so a v3 bump today is free), and
scope (the milestone's letter includes basic gear forging and camp brewing;
both are deferrable with reasons).

## State verified before measuring

`main` = `83b5336` (M3M merge, PR #11), clean, no worktrees, no branches,
nothing in flight. Baseline measured this session at D58: **1570 green**
(657/472/441), all four band lines verbatim (quoted in D58).

## Is each inherited gate real?

1. **D20 scope "gathering nodes, forge, alchemist, tempering" — real,** plus
   two skills the D20 line does not name: Herbcraft and Blacksmith enter
   `SkillId` (the enum's own dartdoc at `skill.dart:12-18` names them as
   deliberately absent "until the mechanics that train them exist" — this
   unit is those mechanics). Append after `binding, never insert.
2. **"v2 is the last break" (`save_codec.dart:30-33`) — cannot hold, again.**
   Adding two skills reproduces byte-for-byte the situation that forced v2:
   `decodeSkills` builds only from the document (`item_codec.dart:77-83,
   re-read), so a v2 document reads the new skills as silently level 0 —
   the exact quiet degradation the v2 dartdoc forbids in its own words.
   The doctrine, not the code, forces the break. Mitigating fact: **the
   playtest was deferred, so no version-2 save with any progress exists
   anywhere** — a v3 bump today costs nothing real. Second fact: m3-quests
   will add quest state and break it AGAIN; declaring each break "the last"
   has now failed twice (campDay at D53, v2 at D55). The honest rule is
   follow-up 20's actual wording: the version freezes at the first SHIPPED
   build; until ship, breaks are sanctioned per-unit, and no dartdoc should
   claim finality.
3. **The milestone letter (spec section 12): "gathering nodes, town forge
   and alchemist with basic (recipe-free) crafting and tempering" — partly
   deferrable.** Basic gear forging duplicates the merchant's gap-filler
   role and brushes the section 7.1 design guard ("crafting serves loot,
   it never competes with it"); recipes-as-loot is M5 explicitly. Camp
   brewing is a section 7.1 parenthetical, not on the M3 line. Both can
   defer with reasons; the user decides.
4. **Effort M — holds only for the lean scope.** Full letter (gear forging
   + camp brewing + kill-drop materials) is L.

## Findings that change the spec

1. **Materials must be counters, not items.** As `BaseItem`s they hit six
   pack-cap enforcement sites (cap 20, stacking is display-only —
   15 ore + 10 herbs literally does not fit), the `_sectionOf` fall-through
   (ore offered a Drink button — the pre-M3M book bug reborn), the closed
   glyph set, the 1-gold price hole (`sellPriceOf` reads `base.*, re-read
   at `economy.dart:50-59`), the bot's take-everything-then-stop-collecting
   policy, and — via `_draw`'s weight-sum — all four band lines plus the
   merchant shelf golden. As `Map<MaterialId, int>` mirrored on
   `Profile`/`GameState` (the gold precedent: `gold` + `GameState.gold,
   lost on death) they cost four mechanical edits, one sorted save key with
   three existing idioms to copy (`encodeSkills, `encodeSpellIds, `_encodeBound`), and a `Purse`-shaped panel — and move nothing the bands
   measure.
2. **Gathering nodes must be neither tiles nor items.** `Tile` is a closed
   4-case enum (re-read, `tile.dart:1-6`); a fifth case changes `toAscii()`
   and reddens every map-byte golden, and a non-walkable tile reshuffles
   flow-fields and stairs placement entirely. Nodes as items ride
   `groundItems` and move the litter pins and the bot. The clean shape:
   **`Map<Position, NodeKind>` on `GameState` + `FloorMemory` + `Floor`**,
   modelled field-for-field on `groundItems` (snapshot/restore at
   `_snapshot`/`_built`/`_arriveOn, `step.dart:727-814`), positions drawn
   from a **separate salted Rng** (the `lootSaltFor`/`dungeonSalt` + purpose
   -slot precedent, `dungeons.dart:121-143, `new_game.dart:8-14`; add the
   new salt to the disjointness pins at `dungeons_test.dart:60` and
   `world_test.dart:893`). Under those three conditions the rng-state pins
   (`dungeon_door_characterization_test.dart:84-85` — the sharpest tripwire
   in the repo), every map-byte golden, and the 2000-floor border sweep all
   hold by construction. Depletion (a mined node) lives per-floor per-run,
   exactly as groundItems does; the floors save block gains a key.
3. **Mine/Gather is an underfoot action refused like `PickUpAction`**, not
   blocked like `DescendAction` (`step.dart:391-407` shows both shapes and
   the doctrine that assigns them): the button appears only when a node is
   underfoot, so a stray tap must cost nothing. Two-tier refusal
   (`AscendAction` template): no node here / already worked. Training: one
   xp per successful mine (Blacksmith) or gather (Herbcraft) via `_train` —
   the M3M cast precedent.
4. **Temper is one `int` on `Item, and its blast radius is enumerated.**
   The five stat getters (`item.dart:190-201`) are the ONLY composition
   site — every consumer reads through them, so an additive temper term
   lands once and flows everywhere: `heroAttack`/`heroArmor`/`heroMaxHp`/
   `heroSpeed, `statLine, `wornDeltas, the bot's `_bestUpgrade`.
   Additive, not multiplicative (`maxHp`/`speed` seed from 0). Must also
   touch: `props` (else differently-tempered items compare equal and
   `stackKey` merges them — an action on the stack then reaches an
   arbitrary one), `stackKey` itself, `displayName` or a second column
   (word + marking; a naked `+`/`++` collides with the Fine/Rare markings —
   pick a distinct form), the item codec (one new key; three golden
   documents rewritten by hand), and **`sellPriceOf, the one consumer that
   would silently NOT see it** (reads `base.*`) — a tempered item must not
   sell for its untempered price, or tempering is a gold-laundering hole in
   reverse; add a temper term beside the book term.
5. **Tempering an equipped item must re-clamp hit points** through
   `_dressed` (`town.dart:161-167`) exactly as equip does — the single
   easiest correctness miss in the unit. Temper never changes
   `wearsHeavy`/`wieldsTwoHanded` (they read `base.*`) — correct by
   construction.
6. **Kill-drop materials would re-roll every band.** Any new entry in any
   drop table changes `_draw`'s weight total (the D56 mechanism), and any
   extra `lootRng` draw on the kill path shifts every subsequent drop. The
   spec's "monsters and chests CAN also drop ingots" is permission, not
   requirement; chests do not exist in the codebase at all. Materials from
   gathering only, this unit, keeps the bands as truthful controls.
7. **Camp is a state, not a place.** The only camp UI is the
   Resume/Delve-anew pair at the camp's own dungeon node
   (`world_screen.dart:359-396`) — the one seam where `TownBloc` is in
   scope and "you have a camp here" is already true. Camp brewing, if
   in scope, is a third door there; if not, it defers cleanly.
8. **Forge and Alchemist as town-blind doors in BOTH towns.** The door
   list is a hard-coded five (`town_screen.dart:75-94, "five doors and a
   purse"); the scroll wrapper already exists for overflow, but the phone
   pass must check it (door-count overflow is a known device-catch class).
   A one-town forge has real friction: Northgate starts undiscovered (a
   fresh hero could not temper at all), Stonebridge-only parks the forge
   at the cheap end. Per-town differentiation stays the shelf's job.
9. **Transactions follow the existing shapes exactly:** `temperItem` =
   `equipItem` (shared `temperRefusal` in core, wrapped as `TownRefusal`
   and readable by the widget for dead-row reasons — the `readRefusal`
   precedent); `smeltOre`/`brewPotion` = `buyItem`-shaped, and brewing
   produces an ITEM (a potion) so it inherits the pack-cap refusal in the
   same sentence. Gold sinks anchor: inn 12, rumor 15, cheapest shelf
   item < 60.
10. **Road danger sums ALL skill levels** (`world.dart:320-327,
    deliberate per its dartdoc) — two new trainable skills mean forge
    grinding taxes travel. Defensible (a tempered hero IS stronger), but
    no existing test would catch the feel change; the spec must rule
    explicitly and pin the choice with a test either way.
11. **`heroMaxMana` is immune** (filters by `isSchool, an explicit
    three-way check) — craft skills contribute zero mana. The natural
    place to pin that is `mana_test.dart:44-57`.
12. **Enum-append blast radius is enumerated** (from the save/skills
    agent): one hard-fail test (`skill_test.dart:6-22` asserts
    `values.skip(4)`), the `_skillName` exhaustive switch (compile error —
    good tripwire), three golden documents gaining two entries in five
    skills blocks, several stale dartdoc/test names ("seven skills", "all
    four skills start untrained"), and the kit/fixtures which stay
    partial maps legally. `magic_surfaces_test` already scrolls to reach
    the bottom skill row; nine rows need the same care.

## Proposed shape of the work

One unit, `m3-craft` (M3C), effort **M** at the lean scope:

- Two skills appended; **saveVersion → 3** (materials key on profile +
  run, nodes key in the floors block, temper key on items, nine-skill
  blocks; goldens rewritten by hand, old strings quoted; the "last break"
  dartdoc rewritten to follow-up 20's honest wording — the version freezes
  at first ship, no finality claims).
- Gathering: ore veins + herb nodes as `Map<Position, NodeKind>` state on
  a separate salted stream, MineAction/GatherAction underfoot (one action
  or two — worker's shape call), one xp per success, counts per node kind
  tunable with a trail; nodes deplete per floor per run.
- Materials: counters (`ore, `ingot, `herb` to start) on
  Profile/GameState mirroring gold (lost on death, not banked this unit).
- Forge (both towns): smelt N ore → ingot (trains Blacksmith), temper a
  found item +1/+2/+3 gated by Blacksmith level (costs ingots + gold),
  through `_dressed`.
- Alchemist (both towns): brew herbs → healing potion (trains Herbcraft),
  pack-cap aware.
- DEFERRED with reasons: basic gear forging (merchant-overlap +
  crafting-serves-loot guard; arrives with M5 recipes), camp brewing
  (section 7.1 parenthetical; the world-screen camp door seam is mapped
  for it), kill-drop/chest materials (band-preserving; chests do not
  exist), material banking (gold's split exists if wanted later).
- **All four band lines byte-identical as controls** — truthful this time:
  no drop table touched, no weight moved, no new draw on `rng`/`lootRng,
  nodes and counters invisible to the bot by construction. Plus the
  designed-difficulty pin, crypt layout goldens, shelf golden, and both
  formula copies untouched.

## Hazards to carry into the spec

- The three node conditions (separate Rng, not a Tile, not an Item) are
  each individually load-bearing; violating any one moves goldens or
  bands. The rng-state integer pins are the tripwire — quote them in the
  build prompt.
- Temper × `sellPriceOf` (finding 4) and temper × `_dressed` (finding 5).
- `props`/`stackKey` on temper, or stacks silently merge.
- The economy shelf tests: materials never enter `marketTable` this unit
  (nothing to re-pin); if the user wants merchant-sold materials later it
  re-pins the shelf golden knowingly.
- Goldens by hand; enum appended; v1 AND v2 refusal fixtures (the v2
  golden becomes the new refusal fixture — capture it BEFORE rewriting,
  the M3M sequencing trap again).
- Device pass: seven doors on a phone (overflow class), node glyphs in
  greyscale, nine skill rows scroll.
- Analyze from the worktree root; mutation reds as named sets; suites
  from package dirs.

## What this recon did NOT check

- Whether node counts/material yields produce a satisfying pace — no
  numbers exist yet; the worker tunes with a trail against... nothing (no
  instrument measures gathering; it is human-judged like magic —
  follow-up 29's shape widens again).
- The app widget internals beyond the files quoted; no device state.
- M4 perk interactions (tempering perks are M4; the +1/+2/+3 tiers here
  must not foreclose them — gating by Blacksmith level is the spec's own
  design, kept).
- Whether "both towns" doors overflow a real phone (emulator-only check
  planned; follow-up 30's class).
- The exact material-kind list against later M5 recipes (reagents
  deferred deliberately).
