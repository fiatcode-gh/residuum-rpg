# Story spec — M2L "Loot" — unit `m2-loot` (second of three M2 units)

Canonical sources (read all, in this order):
- The existing code on `main` (`961dc46`) — all of `packages/core` and
  `packages/content, plus `packages/app/lib/game/`. This story builds on M2E's
  actual interfaces; read them before planning.
- Code conventions: `CLAUDE.md` at the worktree root.
- Game design spec (sections 3.3 randomness, 5 combat, 6 skills, 7 loot):
  `docs/superpowers/specs/2026-08-20-dungeon-game-design.md` (in the worktree).
- Ledger decisions binding here: D8 (unit split), D9 (balance figures), D11
  (slots/affixes/healing forks) — restated below so you need no ledger access.

## Goal

Things to find, wear, swing, and drink: monsters and floors drop items with
rarities and affixes; the hero carries an inventory, equips six slots, trains
four skills by using them, and heals with potions — and with all of that, a
1→5 descent becomes genuinely survivable, which M2E measured it is not today.
Measurable effect: suites green (baseline fresh 2026-08-21: 156 core + 29
content + 27 app = 212), loot is deterministic per seed and independent of
fight order, and an automated survivability simulation wins a bounded majority
of seeded runs (see Test plan).

## Locked scope decisions (ledger D8/D9/D11 — do not re-litigate)

- Slots: exactly `mainHand, offHand, head, chest, hands, feet`. No jewelry.
- Affixes now; rarity controls affix count. All five rarity tiers defined
  (Common/Fine/Rare/Epic/Legendary); Legendary has weight 0 in M2L drop
  tables (sets arrive M4) but the type exists.
- Healing: potions only. No regen, no resting, no mid-dungeon safe point
  (that is logged follow-up 8, not yours).
- Four skills, exactly: Arms, Might, Bulwark, Fleetfoot. Learn-by-doing, no
  perks (perks are M4), no other skills.
- **Binding balance mandate (D9):** with the loot/healing this story adds, a
  1→5 descent must be survivable. Measured inputs from M2E: one corridor
  ghoul costs 16→6 hp; depth 2 holds ~40 damage vs a 20 hp hero; a dire wolf
  costs ~10 hp; ~29 monsters across floors; speed-20 wolves cannot be outrun.
  Preferred levers: potion frequency, armor, affix magnitudes. Fallback lever
  (explicitly allowed): depth-1-2 spawn tables. Hero base stats and monster
  stats may be tuned only with a report of before/after.
- Towns, gold, merchants, banking, death penalty: NOT in this unit (m2-town).

## Shape

Follow the merged code's idioms, read from it: value objects with equatable
mixins and explicit toString; pure derivation functions like `computeFov`
(inputs in, value out, dartdoc carries the argument); content as consts plus
factory functions (`bestiary.dart, `spawn_tables.dart` are the models);
events for everything the log narrates; feature folders (`loot/` and `skills/`
are new siblings of `dungeon/`). `step.dart` stays the single entry point;
new action handling extends its switch without turning it into a god function.

## New files

```
packages/core/
  lib/src/loot/equip_slot.dart       # EquipSlot enum
  lib/src/loot/rarity.dart           # Rarity enum + affix counts
  lib/src/loot/item.dart             # BaseItem, Affix, Item
  lib/src/loot/loadout.dart          # Equipment map + effective-stat derivations
  lib/src/loot/drop.dart             # rollDrop(): base+rarity+affixes from an Rng
  lib/src/skills/skill.dart          # SkillId, SkillState, training math
  test/loot/... test/skills/...      # mirroring

packages/content/
  lib/src/armory.dart                # base items (weapons, armor, potion)
  lib/src/affix_pool.dart            # the affix definitions
  lib/src/drop_tables.dart           # per-depth rarity weights, drop chances,
                                     # floor-item counts, potion weighting

packages/app/
  lib/game/inventory_screen.dart     # inventory + equipment UI
  (game_screen gains: pickup control, potion quick-use, skill readout)
```

## Changed files

```
packages/core/lib/src/engine/game_state.dart  # + lootRng, groundItems, inventory, equipment, skills
packages/core/lib/src/engine/action.dart      # + PickUpAction, EquipAction, UnequipAction, DrinkAction, DropAction
packages/core/lib/src/engine/event.dart       # + loot/skill events (contract below)
packages/core/lib/src/engine/step.dart        # new actions; damage math gains armor & dodge & skill training
packages/core/lib/src/dungeon/generator.dart  # floors also yield item spawn positions
packages/core/lib/src/dungeon/floor.dart      # Floor carries starting ground items
packages/content/lib/src/new_game.dart        # hero = fists + starting kit (below); floor items rolled
packages/content/lib/src/bestiary.dart        # creatures gain a dropChance
packages/app/lib/game/game_bloc.dart          # new actions wired; inventory view state
packages/app/lib/game/event_messages.dart     # new event renderings
packages/app/lib/game/glyph_grid.dart         # ground-item glyphs under fog rules
```

Never touch `docs/epic/`.

## Per-item contract

### Rarity

```dart
enum Rarity { common, fine, rare, epic, legendary }
// affixCount: 0, 1, 2, 3, 4    — the definition of rarity in this game
```

Display rule (accessibility, non-negotiable): rarity is shown as the tier
word in the item name ("Fine Iron Sword") plus a non-hue marking in lists
(e.g. `·`/`+`/`++`/`※` prefix or border weight). Color may be added but never
alone; greyscale-legible.

### BaseItem / Affix / Item

```dart
enum WeaponHands { one, two }

class BaseItem {          // content-defined, identity by id
  final String id;        // 'iron-sword'
  final String name;      // 'Iron Sword'
  final String glyph;     // ')' weapons, '[' armor, '!' potion
  final EquipSlot? slot;  // null for potions
  final WeaponHands? hands;    // weapons only
  final int attackMin, attackMax;   // weapons; 0 otherwise
  final int armor;              // armor pieces; 0 otherwise
  final bool heavy;             // armor: heavy (Bulwark) vs light (Fleetfoot)
  final int heal;               // potions; 0 otherwise
}

class Affix {             // content-defined
  final String id;
  final String affixName; // 'of Embers' / 'Keen' — suffix or prefix, one word each
  final bool isPrefix;
  final int attackMin, attackMax, armor, maxHp, speed;  // additive bonuses, most zero
}

class Item {              // a rolled instance; value object
  final String id;        // unique per crawl: 'item-<n>'
  final BaseItem base;
  final Rarity rarity;
  final List<Affix> affixes;   // length == rarity.affixCount
  String get displayName;      // 'Rare Keen Iron Sword of Embers'
}
```

Content pool for M2L: ~10 base items (3 weapons one-hand, 2 two-hand, shield,
head/chest/hands/feet armor in heavy and light variants where sensible, healing
potion) and 6–8 affixes. Exact stats are the worker's to draft; the spec binds
shapes, not numbers — report the table.

### Equipment rules (loadout.dart)

```dart
typedef Equipment = Map<EquipSlot, Item>;

(int min, int max) heroAttack(GameState state);  // fists 1–2 + weapon + Arms/Might bonus + affixes
int heroArmor(GameState state);                  // sum of armor + Bulwark bonus + affixes
int heroDodgePercent(GameState state);           // Fleetfoot-derived, capped (state the cap)
int heroMaxHp(GameState state);                  // base 20 + affix bonuses
int heroSpeed(GameState state);                  // base 10 + affix bonuses
```

- Equipping a two-handed weapon unequips the shield (both events emitted);
  equipping a shield while a two-hander is held is refused with an event.
- Equip/unequip/drink/pick-up each consume a turn (monsters act); a refused
  action does not.
- Unequipped and displaced items return to inventory; inventory cap 20 —
  a pick-up into a full inventory is refused with `InventoryFull`.
- `Actor.hp` may exceed the old max when +maxHp gear is removed — clamp hp to
  the new max at unequip, never kill the hero by undressing (hp floor 1).

### Damage math (changes step.dart, both directions)

- Hero → monster: `rng.rollRange(heroAttack(state))` — unchanged shape.
- Monster → hero: first roll dodge (`state.rng, combat stream): dodged →
  `AttackDodged` event, no damage, Fleetfoot trains. Otherwise damage =
  `max(1, roll - heroArmor(state))`; Bulwark trains when any equipped armor
  piece is heavy, Fleetfoot when none is (bare/light).
- Monsters have no armor/dodge in M2L.

### Skills (skills/skill.dart)

```dart
enum SkillId { arms, might, bulwark, fleetfoot }
class SkillState { final int level; final int xp; }   // level 0–100
```

- Training triggers: Arms +xp per hit landed with a one-handed weapon (fists
  count as one-handed); Might per hit with a two-handed weapon; Bulwark per
  hit taken wearing any heavy piece; Fleetfoot per hit taken or dodged wearing
  none.
- Level cost curve: rising — `xpToNext(level)` monotonically increasing;
  document the chosen curve. Level-up emits `SkillLevelledUp(skill, level)`.
- Passive per level (small, linear, documented): Arms/Might feed
  `heroAttack`; Bulwark feeds `heroArmor`; Fleetfoot feeds
  `heroDodgePercent` up to its cap.
- Skills live in `GameState.skills: Map<SkillId, SkillState>, all four
  present from `newGame`.

### Randomness — the loot stream (game spec 3.3 becomes real)

- `GameState` gains `lootRng, seeded `Rng(worldSeed ^ <documented constant>)`
  at `newGame, same carried-by-reference exception as `rng` (extend the
  existing GameState dartdoc argument).
- ALL drop rolls (drop chance, base item, rarity, affixes) draw from
  `lootRng`; combat keeps `rng`. Pinned by test: two crawls on one seed whose
  fights differ get identical floor items, and the same kill sequence gets
  identical drops.
- Floor-placed items (2–4 per floor incl. potions, from drop_tables) are
  rolled inside `buildFloor` from the floor's own generator stream — layout
  determinism extends to starting items.

### Drops

- On `ActorDied` (monster): roll vs the creature's `dropChance`; on success
  `rollDrop(depth, lootRng)` → item lands on the death tile, `ItemDropped`
  emitted. Ground items render by their glyph under fog rules; multiple items
  may share a tile (picked up one per turn, newest first — document).

### New actions / events

```dart
PickUpAction()            // item under hero; refused (no turn) when none/full
EquipAction(itemId)       // from inventory; refused for non-equippable
UnequipAction(slot)       // refused when slot empty
DrinkAction(itemId)       // potions; heals min(heal, missing hp); emits PotionDrunk
DropAction(itemId)        // inventory → hero's tile

ItemDropped(item, at) · ItemPickedUp(item) · InventoryFull()
ItemEquipped(item, slot) · ItemUnequipped(item, slot) · EquipRefused(reason)
PotionDrunk(item, healed) · AttackDodged(attackerId)
SkillLevelledUp(skill, level)
```

Value objects with equatable, like the existing events.

### newGame changes (content)

Hero base becomes fists 1–2 / armor 0; starting kit: rusty sword (one-hand,
+2/+3 → effective 3–5, preserving M1/M2E behavior and most existing tests),
2 healing potions in inventory. Document that equivalence in the test plan.

### App

- Ground item under hero → a Pick up control; standing message lists items.
- Inventory screen: list with rarity markings, tap → equip/drink/drop;
  equipment panel showing six slots; derived stats readout (attack, armor,
  dodge, speed) and the four skill levels with xp bars (value contrast, not
  hue). Bloc-level tests only.
- Potion quick-use button on the main screen (drinks the first potion).
- Log lines for all new events via event_messages.

## Behaviour arguments that must land in documentation (dartdoc)

- loadout.dart: why effective stats are derived functions over state rather
  than mutated Actor fields (single source of truth; unequip cannot leave a
  stale bonus behind).
- The lootRng split: what breaks if drops share the combat stream (fight
  order would reshuffle loot, killing seed-shareability).
- The two-hander/shield exclusion rule and the hp-clamp-on-unequip rule.

## Test plan

- **Characterization layer: the existing 212 tests**, green on the unmodified
  worktree first. Expected casualties are few because the starting kit
  preserves effective 3–5 attack: name them in the plan before touching them
  (likely: content newGame validations, any step test constructing bare
  heroes via fixtures that now need equipment plumbing).
- **Unit tests (core, mock-free, fixed seeds):** rarity affix counts; item
  display-name composition; equip/unequip round-trips; two-hander vs shield
  both directions; inventory cap; hp clamp on unequip; damage reduction floor
  of 1; dodge path; every skill's training trigger and the level curve;
  effective-stat derivations with stacked affixes; drop determinism (both
  pins from the lootRng contract); pick-up/drink/drop turn consumption and
  refusal-consumes-no-turn.
- **Survivability simulation (the balance mandate, in content tests):** a
  deterministic bot — if adjacent monster: attack; else if hp < 40% and
  potion held: drink; else auto-path to stairs, picking up items it crosses
  and equipping strict upgrades; descend on arrival. Over ≥30 consecutive
  world seeds: **wins (reaches depth 5 alive) in 50–95% of runs.** Below 50%
  the game is still unfair; above 95% it is trivial — both fail the test.
  Tune content (levers per the mandate) until it passes; report the final
  win rate and the tuning trail.
- **Content validation:** every affix/base-item id unique; drop tables
  reference real items; every depth has a table; potion present in floor-item
  tables at every depth.
- **App (bloc_test):** pick-up flow; equip from inventory reflects in derived
  stats; quick-drink heals and logs; inventory-full refusal surfaces; skill
  level-up reaches the log.

### Mutation table

| # | Mutation (revert after checking) | Expected to fail | Expected to stay green (control) |
|---|---|---|---|
| 1 | heroArmor ignored in monster damage (armor never subtracted) | damage-reduction + survivability tests | movement/descend tests |
| 2 | affix bonuses dropped from effective-stat derivations | stacked-affix derivation tests | base-item-only equip tests |
| 3 | skill xp never awarded | all four training-trigger tests | equip/unequip tests |
| 4 | two-hander no longer unequips the shield | both exclusion-rule tests | one-hand equip tests |
| 5 | drops rolled from combat `rng` instead of `lootRng` | the two lootRng determinism pins | floor-layout determinism tests |
| 6 | DrinkAction heals 0 | potion tests + survivability | pick-up/drop tests |

Sequencing: run against the finished unit, one row at a time, reverting each.
Row 5's red must be the determinism pins, not a compile error — mutate the
stream choice, not the API.

## Hazards

- Sandbox is currently DISABLED on this machine (user trial) — the ledger's
  sandbox traps are dormant; do not re-enable anything.
- Subagents dispatched into a git worktree do not inherit cwd — force an
  explicit `cd <worktree> && pwd` first or they commit in the parent repo.
- No fvm in this repo: plain `flutter` / `dart` (system Flutter 3.47.0).
- The ledger directory `docs/epic/` is gitignored — never commit anything
  under `docs/epic/`; cite its files by absolute path.
- Commits use the personal persona:.
- AVD `Pixel_10` exists; launch via the `emulator` binary directly (`flutter
  emulators` mishandles the installed ps16k system images). First gradle
  build downloads for minutes; not a hang.
- `find` in the Bash tool may be bfs, not GNU findutils — `-newermt` takes
  ISO 8601 only; GNU find is at `/usr/bin/find`.

## Follow-ups to log (not this story)

1. Town, merchant, bank, gold, death penalty, visit-bump → `m2-town`.
2. Jewelry slots + magic affixes → M3.
3. Mid-dungeon safe point (ledger follow-up 8) → m2-town or M3.
4. Set bonuses, Legendary drops → M4.

## Definition of done (checkable)

- [ ] All three suites green; pre-existing test modifications listed with
      reasons; baseline 212 confirmed green before the first change
- [ ] `flutter analyze` clean ×3; `dart format --set-exit-if-changed .` clean
- [ ] Survivability simulation passing in-band (50–95% over ≥30 seeds), final
      rate and tuning trail reported
- [ ] Loot determinism pins green (fight-order independence + same-seed
      identity)
- [ ] Mutation table executed in full, greens included, reverted
- [ ] AVD playthrough on `Pixel_10`: pick up a drop, equip it, see a derived
      stat change, drink a potion, dodge visibly logged, a skill level-up
      logged, and a 1→5 descent completed by a human using potions
- [ ] Conventional commits, each green, fiatcode author; no body comments;
      dartdoc carries the three documented behaviour arguments
