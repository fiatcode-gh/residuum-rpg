# M2L Loot Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> This plan is executed inline with `superpowers:executing-plans`. The executing
> session carries a standing constraint against dispatching subagents unless its
> own user asks for them, so there is no per-task reviewer; the mutation table at
> Task 15 carries the adversarial load instead.

**Goal:** Items with rarities and affixes drop from monsters and floors; the hero
carries, equips, drinks and trains — and a 1→5 descent becomes survivable, proven
by a deterministic bot winning 50–95% of ≥30 seeded runs.

**Architecture:** Two new `core` feature folders, `loot/` and `skills/, siblings
of`dungeon/`. Effective hero stats are **pure derivations** over a`Loadout`
(equipment + skills) rather than mutated `Actor` fields, so unequipping cannot
leave a stale bonus behind. `Actor.attackMin/attackMax/maxHp/speed` become the
hero's *unarmed base* and every gear and skill bonus is **additive** on top —
which is exactly what keeps the 212-test characterization layer green. Drop
rolls draw from a new `lootRng` stream so fight order can never reshuffle loot.
Drop tables are immutable data carried on `GameState`; floor building stays a
closure, as it already is.

**Tech Stack:** Dart 3.9 (`core,`content`), Flutter 3.47 + flutter_bloc
(`app`),`test` / `bloc_test`. No new dependencies.

**Spec:** `/var/home/dhemas/Development/Projects/_temp/residuum/docs/epic/m2-loot-spec-M2L.md`
(architect's gitignored ledger — never commit it). Design spec context:
`docs/superpowers/specs/2026-08-20-dungeon-game-design.md` sections 3.3, 5, 6, 7.

## Global Constraints

- Dependency rule `app → content → core`. `core` and `content` never import Flutter.
- Game state is immutable. `(GameState, List<GameEvent>) step(GameState, GameAction)`
  is the only way the game changes. New behaviour emits events.
- No global randomness. Every random decision draws from an `Rng` carried in state.
- **No body comments.** Dartdoc `///` only, and only on public API of `core`/`content`.
- Ubiquitous language: `affix,`temper, `beat,`rumor, `residue`. No synonyms.
- Accessibility (non-negotiable): rarity and every category encoded by shape,
  marking, position or a word — never hue alone. Every screen reads in greyscale.
- Slots are exactly `mainHand, offHand, head, chest, hands, feet`. No jewelry.
- Rarity tiers are exactly Common/Fine/Rare/Epic/Legendary. Legendary weight 0.
- Healing is potions only. Skills are exactly Arms, Might, Bulwark, Fleetfoot.
- Inventory cap 20. Dodge cap 30%. Skill levels 0–100.
- Every commit's exit state is green. Conventional commits. Never push, never open a PR.
- Out of scope, resist: towns, gold, merchants, death penalty, jewelry, set
  bonuses, resting, regen, damage types, resistances, torches, perks.

## Approved deviations from the story spec

Approved by the architect before implementation:

1. Derivations are pure over `(Actor, Loadout), not`(GameState)`. Skills train
   *during* the monster phase, so a level-up must change armor and dodge for the
   next monster's hit in the same turn — those trained skills are in no
   `GameState` yet. `GameState.loadout` is the caller-facing getter.
2. `Actor` stats are the unarmed base; gear and skills are additive.
3. A hero with 0 dodge percent does not roll for dodge at all. An unconditional
   roll would advance `state.rng` once per monster attack and reshuffle every
   seeded fight in the game. **This argument goes in dartdoc where the skip
   happens** (architect rider).
4. Item ids use split namespaces, `floor-<depth>-<n>` and `drop-<n>, because
   content's`buildFloor` closure and core's drop roller are independent id
   sources. The contract is uniqueness per crawl; `item-<n>` was illustrative.
5. Drop tables are immutable data on `GameState, not a closure. A table is not
   behaviour.

## The one pre-existing test that changes

`packages/content/test/content_validation_test.dart:334` —
`expect((hero.attackMin, hero.attackMax), (3, 5))`. Under the additive baseline
the hero's *Actor* carries fists `(1, 2)` and the rusty sword supplies `+2/+3,
so the derived attack is still`(3, 5)`. The assertion is **strengthened, not
deleted**: it asserts fists on the Actor *and*`(3, 5)` from `heroAttack`.

Four `GameState` construction sites gain the now-required `lootRng` argument with
no assertion changes: `packages/core/test/support/fixtures.dart` (`crawl`), `packages/app/test/game_bloc_test.dart` (`arenaGame`), `packages/content/test/content_validation_test.dart` (the 1→5 descent test), and
`packages/content/lib/src/new_game.dart`. No other pre-existing test is touched.

---

## File structure

```
packages/core/lib/src/loot/equip_slot.dart   EquipSlot enum
packages/core/lib/src/loot/rarity.dart       Rarity enum + affixCount + marking
packages/core/lib/src/loot/item.dart         WeaponHands, BaseItem, Affix, Item
packages/core/lib/src/loot/loadout.dart      Loadout + the five derivations
packages/core/lib/src/loot/drop.dart         Weighted, DropTable, rollDrop
packages/core/lib/src/skills/skill.dart      SkillId, SkillState, xpToNext, train
packages/core/lib/src/engine/game_state.dart + lootRng, groundItems, inventory,
                                             equipment, skills, dropTables,
                                             nextDropNumber
packages/core/lib/src/engine/action.dart     + 5 actions
packages/core/lib/src/engine/event.dart      + 8 events
packages/core/lib/src/engine/step.dart       new actions; armor, dodge, training
packages/core/lib/src/engine/actor.dart      + dropChance
packages/core/lib/src/dungeon/floor.dart     Floor carries groundItems
packages/core/lib/src/dungeon/generator.dart + itemSpawns
packages/content/lib/src/armory.dart         14 base items
packages/content/lib/src/affix_pool.dart     8 affixes, weapon and armour pools
packages/content/lib/src/drop_tables.dart    per-depth tables
packages/content/lib/src/bestiary.dart       + dropChance per creature
packages/content/lib/src/new_game.dart       fists + starting kit; floor items
packages/app/lib/game/inventory_screen.dart  inventory + equipment + skills UI
packages/app/lib/game/game_bloc.dart         new actions, inventory view state
packages/app/lib/game/event_messages.dart    new event renderings
packages/app/lib/game/glyph_grid.dart        ground-item glyphs under fog rules
packages/app/lib/game/game_screen.dart       pick-up, quick-drink, inventory entry
```

## The numbers (draft — Task 12 tunes them and reports the trail)

**Base items.** Weapon `attackMin/attackMax` are additive over fists 1–2.

| id | name | glyph | slot | hands | atk | armor | heavy |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `rusty-sword` | Rusty Sword | `)` | mainHand | one | +2/+3 | – | – |
| `iron-sword` | Iron Sword | `)` | mainHand | one | +3/+5 | – | – |
| `war-axe` | War Axe | `)` | mainHand | one | +4/+7 | – | – |
| `greatsword` | Greatsword | `)` | mainHand | two | +6/+9 | – | – |
| `maul` | Maul | `)` | mainHand | two | +7/+11 | – | – |
| `kite-shield` | Kite Shield | `[` | offHand | – | – | 2 | yes |
| `iron-helm` | Iron Helm | `[` | head | – | – | 1 | yes |
| `leather-cap` | Leather Cap | `[` | head | – | – | 1 | no |
| `mail-hauberk` | Mail Hauberk | `[` | chest | – | – | 3 | yes |
| `leather-jerkin` | Leather Jerkin | `[` | chest | – | – | 1 | no |
| `iron-gauntlets` | Iron Gauntlets | `[` | hands | – | – | 1 | yes |
| `iron-greaves` | Iron Greaves | `[` | feet | – | – | 1 | yes |
| `leather-boots` | Leather Boots | `[` | feet | – | – | 1 | no |
| `healing-potion` | Healing Potion | `!` | – | – | – | – | heal 8 |

**Affixes.** Four for weapons, four for armour, so an Epic draws 3 of 4 and even
a Legendary's 4 fits — `affixes.length == rarity.affixCount` holds at every tier.

| id | affixName | prefix | pool | bonuses |
| --- | --- | --- | --- | --- |
| `keen` | Keen | yes | weapon | attackMax +2 |
| `vicious` | Vicious | yes | weapon | attackMin +2, attackMax +3 |
| `of-embers` | of Embers | no | weapon | attackMin +1, attackMax +2 |
| `of-fury` | of Fury | no | weapon | attackMax +1, speed +1 |
| `sturdy` | Sturdy | yes | armour | armor +1 |
| `reinforced` | Reinforced | yes | armour | armor +2 |
| `of-vigour` | of Vigour | no | armour | maxHp +4 |
| `of-swiftness` | of Swiftness | no | armour | speed +2 |

**Rarity weights by depth** (common/fine/rare/epic/legendary):
1 → 70/25/5/0/0 · 2 → 60/28/10/2/0 · 3 → 50/30/15/5/0 ·
4 → 40/32/20/8/0 · 5 → 30/33/25/12/0.

**Creature drop chance (percent):** rat 25, wolf 30, ghoul 40, skeleton 50,
wight 60.

**Floor items per depth:** 2–4.

**Skill curve:** `xpToNext(level) = 8 + 4 * level`; 1 xp per trigger. Passives:
Arms and Might each `+level ~/ 2` to both attack ends, and **only the one
matching the held weapon applies** (Arms for one-handed and fists, Might for
two-handed); Bulwark `+level ~/ 2` armor; Fleetfoot `min(30, level * 3)` dodge
percent.

---

### Task 1: EquipSlot and Rarity

**Files:**

- Create: `packages/core/lib/src/loot/equip_slot.dart`
- Create: `packages/core/lib/src/loot/rarity.dart`
- Modify: `packages/core/lib/core.dart`
- Test: `packages/core/test/loot/rarity_test.dart`

**Interfaces:**

- Consumes: nothing.
- Produces: `enum EquipSlot { mainHand, offHand, head, chest, hands, feet }`;
  `enum Rarity { common, fine, rare, epic, legendary }` with
  `int get affixCount` and `String get marking`.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

void main() {
  group('Rarity', () {
    test('affix count is the definition of a tier', () {
      // arrange
      const tiers = Rarity.values;

      // act
      final counts = [for (final tier in tiers) tier.affixCount];

      // assert
      expect(counts, [0, 1, 2, 3, 4]);
    });

    test('every tier carries a marking that survives greyscale', () {
      // arrange
      const tiers = Rarity.values;

      // act
      final markings = [for (final tier in tiers) tier.marking];

      // assert
      expect(markings, ['·', '+', '++', '※', '★']);
      expect(markings.toSet(), hasLength(tiers.length));
    });

    test('the tier word names the item', () {
      // arrange
      const tier = Rarity.fine;

      // act
      final word = tier.word;

      // assert
      expect(word, 'Fine');
    });
  });

  group('EquipSlot', () {
    test('is exactly the six slots the milestone locks', () {
      // arrange
      const slots = EquipSlot.values;

      // act
      final names = [for (final slot in slots) slot.name];

      // assert
      expect(names, [
        'mainHand',
        'offHand',
        'head',
        'chest',
        'hands',
        'feet',
      ]);
    });
  });
}
```

- [ ] **Step 2: Run it and confirm it fails**

Run: `cd packages/core && dart test test/loot/rarity_test.dart`
Expected: FAIL — `Rarity` and `EquipSlot` are undefined.

- [ ] **Step 3: Implement**

`equip_slot.dart`:

```dart
/// Where an item goes when the hero wears it.
///
/// Exactly six slots this milestone. Jewelry arrives with M3, so a seventh
/// entry here is a scope error rather than a feature.
enum EquipSlot { mainHand, offHand, head, chest, hands, feet }
```

`rarity.dart`:

```dart
/// How much an item was blessed on the way out of the dungeon.
///
/// A tier *is* its affix count: that is the whole definition, and every other
/// difference between a Common and an Epic follows from how many affixes got
/// rolled onto the same base item.
///
/// [marking] exists because the author is deuteranomalous and hue alone must
/// never carry a category. A list of items reads correctly in greyscale, on a
/// monochrome display, and to a screen reader, because the tier is a glyph and
/// [word] is in the item's own name.
enum Rarity {
  common(affixCount: 0, marking: '·', word: 'Common'),
  fine(affixCount: 1, marking: '+', word: 'Fine'),
  rare(affixCount: 2, marking: '++', word: 'Rare'),
  epic(affixCount: 3, marking: '※', word: 'Epic'),
  legendary(affixCount: 4, marking: '★', word: 'Legendary');

  const Rarity({
    required this.affixCount,
    required this.marking,
    required this.word,
  });

  /// How many affixes an item of this tier rolls.
  final int affixCount;

  /// The non-hue mark a list draws beside an item of this tier.
  final String marking;

  /// The tier word that opens the item's display name.
  final String word;
}
```

Add both to `core.dart` exports.

- [ ] **Step 4: Run and confirm green**

Run: `cd packages/core && dart test`
Expected: PASS, 156 + 3 = 159.

- [ ] **Step 5: Commit**

```bash
git add packages/core/lib/src/loot packages/core/lib/core.dart packages/core/test/loot
git commit -m "feat(loot): equip slots and rarity tiers"
```

---

### Task 2: BaseItem, Affix, Item

**Files:**

- Create: `packages/core/lib/src/loot/item.dart`
- Modify: `packages/core/lib/core.dart`
- Test: `packages/core/test/loot/item_test.dart`

**Interfaces:**

- Consumes: `EquipSlot,`Rarity`.
- Produces: `enum WeaponHands { one, two }`; `class BaseItem` with
  `id, name, glyph, slot, hands, attackMin, attackMax, armor, heavy, heal`
  and getters `isWeapon,`isArmour, `isPotion,`isEquippable`;
  `class Affix` with `id, affixName, isPrefix, attackMin, attackMax, armor,
  maxHp, speed`;`class Item` with `id, base, rarity, affixes` and
  `displayName, plus summed getters `attackMin, attackMax, armor, maxHp,
  speed`.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

const _sword = BaseItem(
  id: 'iron-sword',
  name: 'Iron Sword',
  glyph: ')',
  slot: EquipSlot.mainHand,
  hands: WeaponHands.one,
  attackMin: 3,
  attackMax: 5,
);

const _keen = Affix(
  id: 'keen',
  affixName: 'Keen',
  isPrefix: true,
  attackMax: 2,
);

const _ofEmbers = Affix(
  id: 'of-embers',
  affixName: 'of Embers',
  isPrefix: false,
  attackMin: 1,
  attackMax: 2,
);

void main() {
  group('Item.displayName', () {
    test('a common item is the tier word and the base name', () {
      // arrange
      const item = Item(id: 'drop-1', base: _sword, rarity: Rarity.common);

      // act
      final name = item.displayName;

      // assert
      expect(name, 'Common Iron Sword');
    });

    test('a prefix lands before the base name and a suffix after it', () {
      // arrange
      const item = Item(
        id: 'drop-2',
        base: _sword,
        rarity: Rarity.rare,
        affixes: [_ofEmbers, _keen],
      );

      // act
      final name = item.displayName;

      // assert
      expect(name, 'Rare Keen Iron Sword of Embers');
    });
  });

  group('Item stats', () {
    test('sums the base item and every affix', () {
      // arrange
      const item = Item(
        id: 'drop-3',
        base: _sword,
        rarity: Rarity.rare,
        affixes: [_keen, _ofEmbers],
      );

      // act
      final range = (item.attackMin, item.attackMax);

      // assert
      expect(range, (4, 9));
    });
  });

  group('BaseItem kinds', () {
    test('a potion has no slot and cannot be equipped', () {
      // arrange
      const potion = BaseItem(
        id: 'healing-potion',
        name: 'Healing Potion',
        glyph: '!',
        heal: 8,
      );

      // act
      final kinds = (potion.isPotion, potion.isEquippable, potion.isWeapon);

      // assert
      expect(kinds, (true, false, false));
    });

    test('a shield is armour, not a weapon', () {
      // arrange
      const shield = BaseItem(
        id: 'kite-shield',
        name: 'Kite Shield',
        glyph: '[',
        slot: EquipSlot.offHand,
        armor: 2,
        heavy: true,
      );

      // act
      final kinds = (shield.isArmour, shield.isWeapon, shield.isEquippable);

      // assert
      expect(kinds, (true, false, true));
    });
  });

  group('Item equality', () {
    test('two rolls with the same id and contents are equal', () {
      // arrange
      const one = Item(id: 'drop-4', base: _sword, rarity: Rarity.fine,
          affixes: [_keen]);
      const other = Item(id: 'drop-4', base: _sword, rarity: Rarity.fine,
          affixes: [_keen]);

      // act
      final same = one == other;

      // assert
      expect(same, isTrue);
    });

    test('a different roll of the same base is not equal', () {
      // arrange
      const one = Item(id: 'drop-5', base: _sword, rarity: Rarity.fine,
          affixes: [_keen]);
      const other = Item(id: 'drop-5', base: _sword, rarity: Rarity.fine,
          affixes: [_ofEmbers]);

      // act
      final same = one == other;

      // assert
      expect(same, isFalse);
    });
  });
}
```

- [ ] **Step 2: Run it and confirm it fails**

Run: `cd packages/core && dart test test/loot/item_test.dart`
Expected: FAIL — `BaseItem,`Affix, `Item,`WeaponHands` undefined.

- [ ] **Step 3: Implement**

```dart
import 'package:equatable/equatable.dart';

import 'equip_slot.dart';
import 'rarity.dart';

/// How many hands a weapon needs.
enum WeaponHands { one, two }

/// One kind of thing that can be found, before any affix is rolled onto it.
///
/// Content-defined and identified by [id]. A base item is a template: the thing
/// the hero actually carries is an [Item], which is this plus a [Rarity] and
/// the affixes that tier bought.
///
/// The stat fields are additive contributions, not totals. A weapon's
/// [attackMin] and [attackMax] are what it adds to the hero's bare fists, so a
/// hero who drops every weapon still punches rather than dealing zero.
class BaseItem extends Equatable {
  const BaseItem({
    required this.id,
    required this.name,
    required this.glyph,
    this.slot,
    this.hands,
    this.attackMin = 0,
    this.attackMax = 0,
    this.armor = 0,
    this.heavy = false,
    this.heal = 0,
  });

  final String id;
  final String name;

  /// The single character this item draws as on the floor: `), `[` or `!`.
  final String glyph;

  /// Where it is worn, or null when it is not worn at all.
  final EquipSlot? slot;

  /// Weapons only; null otherwise.
  final WeaponHands? hands;

  final int attackMin;
  final int attackMax;
  final int armor;

  /// Whether wearing this trains Bulwark rather than Fleetfoot.
  final bool heavy;

  /// Potions only; how much one restores.
  final int heal;

  bool get isWeapon => hands != null;

  bool get isArmour => slot != null && hands == null;

  bool get isPotion => heal > 0;

  bool get isEquippable => slot != null;

  @override
  List<Object?> get props => [
    id,
    name,
    glyph,
    slot,
    hands,
    attackMin,
    attackMax,
    armor,
    heavy,
    heal,
  ];

  @override
  String toString() => 'BaseItem($id)';
}

/// A bonus rolled onto a base item.
///
/// One word each, so a display name reads as English: a prefix before the base
/// name, a suffix after it.
class Affix extends Equatable {
  const Affix({
    required this.id,
    required this.affixName,
    required this.isPrefix,
    this.attackMin = 0,
    this.attackMax = 0,
    this.armor = 0,
    this.maxHp = 0,
    this.speed = 0,
  });

  final String id;
  final String affixName;
  final bool isPrefix;
  final int attackMin;
  final int attackMax;
  final int armor;
  final int maxHp;
  final int speed;

  @override
  List<Object?> get props => [
    id,
    affixName,
    isPrefix,
    attackMin,
    attackMax,
    armor,
    maxHp,
    speed,
  ];

  @override
  String toString() => 'Affix($id)';
}

/// One rolled item: a base, a tier, and the affixes that tier bought.
///
/// [id] is unique within a crawl. It has two namespaces on purpose —
/// `floor-<depth>-<n>` for items a floor was built with and `drop-<n>` for
/// items a kill produced — because the floor builder is a content closure and
/// the drop roller lives in the rules, and threading one shared counter between
/// them would put mutable state inside the closure for no gain.
class Item extends Equatable {
  const Item({
    required this.id,
    required this.base,
    required this.rarity,
    this.affixes = const [],
  });

  final String id;
  final BaseItem base;
  final Rarity rarity;

  /// Always exactly [Rarity.affixCount] long.
  final List<Affix> affixes;

  /// What the log and the inventory call this item.
  ///
  /// The tier word opens the name so rarity is legible without any colour at
  /// all: 'Rare Keen Iron Sword of Embers'.
  String get displayName {
    final prefixes = affixes.where((affix) => affix.isPrefix);
    final suffixes = affixes.where((affix) => !affix.isPrefix);
    return [
      rarity.word,
      for (final affix in prefixes) affix.affixName,
      base.name,
      for (final affix in suffixes) affix.affixName,
    ].join(' ');
  }

  int get attackMin => _sum(base.attackMin, (affix) => affix.attackMin);

  int get attackMax => _sum(base.attackMax, (affix) => affix.attackMax);

  int get armor => _sum(base.armor, (affix) => affix.armor);

  int get maxHp => _sum(0, (affix) => affix.maxHp);

  int get speed => _sum(0, (affix) => affix.speed);

  int _sum(int from, int Function(Affix) of) =>
      affixes.fold(from, (total, affix) => total + of(affix));

  @override
  List<Object?> get props => [id, base, rarity, affixes];

  @override
  String toString() => 'Item($id, $displayName)';
}
```

Export `item.dart` from `core.dart`.

- [ ] **Step 4: Run and confirm green**

Run: `cd packages/core && dart test`
Expected: PASS, 159 + 7 = 166.

- [ ] **Step 5: Commit**

```bash
git add packages/core/lib/src/loot/item.dart packages/core/lib/core.dart packages/core/test/loot/item_test.dart
git commit -m "feat(loot): base items, affixes and rolled items"
```

---

### Task 3: Skills

**Files:**

- Create: `packages/core/lib/src/skills/skill.dart`
- Modify: `packages/core/lib/core.dart`
- Test: `packages/core/test/skills/skill_test.dart`

**Interfaces:**

- Consumes: nothing.
- Produces: `enum SkillId { arms, might, bulwark, fleetfoot }`;
  `const int maxSkillLevel = 100`; `int xpToNext(int level)`;
  `class SkillState { int level; int xp; SkillState trained(); }`;
  `const Map<SkillId, SkillState> untrainedSkills`.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

void main() {
  group('xpToNext', () {
    test('rises with every level, so later levels cost more', () {
      // arrange
      const levels = [0, 1, 2, 3, 4];

      // act
      final costs = [for (final level in levels) xpToNext(level)];

      // assert
      expect(costs, [8, 12, 16, 20, 24]);
    });

    test('is monotonically increasing all the way to the cap', () {
      // arrange
      final costs = [
        for (var level = 0; level < maxSkillLevel; level++) xpToNext(level),
      ];

      // act
      final rising = [
        for (var index = 1; index < costs.length; index++)
          costs[index] > costs[index - 1],
      ];

      // assert
      expect(rising, everyElement(isTrue));
    });
  });

  group('SkillState.trained', () {
    test('banks one experience point short of the next level', () {
      // arrange
      const skill = SkillState();

      // act
      final after = skill.trained();

      // assert
      expect((after.level, after.xp), (0, 1));
    });

    test('levels up when the cost is met and spends the experience', () {
      // arrange
      const skill = SkillState(level: 0, xp: 7);

      // act
      final after = skill.trained();

      // assert
      expect((after.level, after.xp), (1, 0));
    });

    test('carries surplus experience into the new level', () {
      // arrange
      const skill = SkillState(level: 0, xp: 8);

      // act
      final after = skill.trained();

      // assert
      expect((after.level, after.xp), (1, 1));
    });

    test('stops at the cap and stops banking experience there', () {
      // arrange
      const skill = SkillState(level: maxSkillLevel, xp: 0);

      // act
      final after = skill.trained();

      // assert
      expect(after, skill);
    });

    test('reports whether that training levelled the skill', () {
      // arrange
      const ready = SkillState(level: 0, xp: 7);
      const notReady = SkillState(level: 0, xp: 0);

      // act
      final levelled = (
        ready.trained().level > ready.level,
        notReady.trained().level > notReady.level,
      );

      // assert
      expect(levelled, (true, false));
    });
  });

  group('untrainedSkills', () {
    test('holds all four skills at level zero', () {
      // arrange
      const skills = untrainedSkills;

      // act
      final ids = skills.keys.toSet();

      // assert
      expect(ids, SkillId.values.toSet());
      expect(skills.values, everyElement(const SkillState()));
    });
  });
}
```

- [ ] **Step 2: Run it and confirm it fails**

Run: `cd packages/core && dart test test/skills/skill_test.dart`
Expected: FAIL — `SkillId,`SkillState, `xpToNext,`untrainedSkills` undefined.

- [ ] **Step 3: Implement**

```dart
import 'package:equatable/equatable.dart';

/// The four skills this milestone trains.
///
/// Learn-by-doing: there are no skill points to spend. Arms and Might come from
/// swinging one-handed and two-handed weapons, Bulwark from being hit in heavy
/// armour, Fleetfoot from being hit or dodging without any.
enum SkillId { arms, might, bulwark, fleetfoot }

/// The highest level any skill reaches.
const int maxSkillLevel = 100;

/// The experience it costs to leave [level] behind.
///
/// Strictly rising, so the twentieth level of a skill is a real investment and
/// the first is nearly free. Linear rather than exponential because the whole
/// curve has to be walkable inside a five-floor crawl: at one point per
/// trigger, reaching level five costs eighty hits, which is roughly a full
/// descent's worth of swinging.
int xpToNext(int level) => 8 + 4 * level;

/// How far one skill has come.
class SkillState extends Equatable {
  const SkillState({this.level = 0, this.xp = 0});

  final int level;

  /// Experience banked toward the next level, always below [xpToNext].
  final int xp;

  /// This skill after one more use of it.
  ///
  /// Surplus experience carries into the new level rather than being discarded,
  /// so a level-up never silently throws away a trigger. At [maxSkillLevel]
  /// training stops entirely: banking experience that can never be spent would
  /// leave the state growing forever for no visible effect.
  SkillState trained() {
    if (level >= maxSkillLevel) return this;
    final banked = xp + 1;
    final cost = xpToNext(level);
    if (banked < cost) return SkillState(level: level, xp: banked);
    return SkillState(level: level + 1, xp: banked - cost);
  }

  @override
  List<Object?> get props => [level, xp];

  @override
  String toString() => 'SkillState($level, $xp xp)';
}

/// All four skills, untouched. Every crawl starts here.
const Map<SkillId, SkillState> untrainedSkills = {
  SkillId.arms: SkillState(),
  SkillId.might: SkillState(),
  SkillId.bulwark: SkillState(),
  SkillId.fleetfoot: SkillState(),
};
```

Export `skill.dart` from `core.dart`.

- [ ] **Step 4: Run and confirm green**

Run: `cd packages/core && dart test`
Expected: PASS, 166 + 7 = 173.

- [ ] **Step 5: Commit**

```bash
git add packages/core/lib/src/skills packages/core/lib/core.dart packages/core/test/skills
git commit -m "feat(skills): learn-by-doing levels and the rising cost curve"
```

---

### Task 4: Loadout and the effective-stat derivations

**Files:**

- Create: `packages/core/lib/src/loot/loadout.dart`
- Modify: `packages/core/lib/core.dart`
- Test: `packages/core/test/loot/loadout_test.dart`

**Interfaces:**

- Consumes: `EquipSlot,`Item, `SkillId,`SkillState, `Actor,`WeaponHands`.
- Produces: `typedef Equipment = Map<EquipSlot, Item>`;
  `const int dodgeCapPercent = 30`;
  `class Loadout { Equipment equipment; Map<SkillId, SkillState> skills;
   int levelOf(SkillId); Item? get weapon; bool get wearsHeavy;
   bool get wieldsTwoHanded; Loadout withEquipment(Equipment);
   Loadout withSkills(Map<SkillId, SkillState>); }`;
  `(int, int) heroAttack(Actor hero, Loadout loadout)`;
  `int heroArmor(Loadout loadout)`; `int heroDodgePercent(Loadout loadout)`;
  `int heroMaxHp(Actor hero, Loadout loadout)`;
  `int heroSpeed(Actor hero, Loadout loadout)`.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

const _fists = Actor(
  id: 'hero',
  name: 'you',
  glyph: '@',
  position: Position(1, 1),
  hp: 20,
  maxHp: 20,
  attackMin: 1,
  attackMax: 2,
  speed: 10,
  energy: actThreshold,
);

const _sword = BaseItem(
  id: 'iron-sword',
  name: 'Iron Sword',
  glyph: ')',
  slot: EquipSlot.mainHand,
  hands: WeaponHands.one,
  attackMin: 3,
  attackMax: 5,
);

const _maul = BaseItem(
  id: 'maul',
  name: 'Maul',
  glyph: ')',
  slot: EquipSlot.mainHand,
  hands: WeaponHands.two,
  attackMin: 7,
  attackMax: 11,
);

const _hauberk = BaseItem(
  id: 'mail-hauberk',
  name: 'Mail Hauberk',
  glyph: '[',
  slot: EquipSlot.chest,
  armor: 3,
  heavy: true,
);

const _jerkin = BaseItem(
  id: 'leather-jerkin',
  name: 'Leather Jerkin',
  glyph: '[',
  slot: EquipSlot.chest,
  armor: 1,
);

const _vigour = Affix(
  id: 'of-vigour',
  affixName: 'of Vigour',
  isPrefix: false,
  maxHp: 4,
);

const _swiftness = Affix(
  id: 'of-swiftness',
  affixName: 'of Swiftness',
  isPrefix: false,
  speed: 2,
);

const _keen = Affix(
  id: 'keen',
  affixName: 'Keen',
  isPrefix: true,
  attackMax: 2,
);

Loadout _wearing(List<Item> items, {Map<SkillId, SkillState>? skills}) =>
    Loadout(
      equipment: {for (final item in items) item.base.slot!: item},
      skills: skills ?? untrainedSkills,
    );

Item _rolled(BaseItem base, {List<Affix> affixes = const []}) => Item(
  id: 'drop-1',
  base: base,
  rarity: Rarity.values[affixes.length],
  affixes: affixes,
);

void main() {
  group('heroAttack', () {
    test('a bare hero swings its fists', () {
      // arrange
      final loadout = _wearing(const []);

      // act
      final range = heroAttack(_fists, loadout);

      // assert
      expect(range, (1, 2));
    });

    test('a weapon adds to the fists rather than replacing them', () {
      // arrange
      final loadout = _wearing([_rolled(_sword)]);

      // act
      final range = heroAttack(_fists, loadout);

      // assert
      expect(range, (4, 7));
    });

    test('stacked affixes all count', () {
      // arrange
      final loadout = _wearing([
        _rolled(_sword, affixes: const [_keen]),
        _rolled(_hauberk, affixes: const [_vigour]),
      ]);

      // act
      final range = heroAttack(_fists, loadout);

      // assert
      expect(range, (4, 9));
    });

    test('Arms trains the one-handed swing and Might leaves it alone', () {
      // arrange
      final trained = _wearing(
        [_rolled(_sword)],
        skills: const {
          SkillId.arms: SkillState(level: 6),
          SkillId.might: SkillState(level: 40),
        },
      );

      // act
      final range = heroAttack(_fists, trained);

      // assert
      expect(range, (7, 10));
    });

    test('Might trains the two-handed swing and Arms leaves it alone', () {
      // arrange
      final trained = _wearing(
        [_rolled(_maul)],
        skills: const {
          SkillId.arms: SkillState(level: 40),
          SkillId.might: SkillState(level: 6),
        },
      );

      // act
      final range = heroAttack(_fists, trained);

      // assert
      expect(range, (11, 16));
    });

    test('bare fists are trained by Arms', () {
      // arrange
      final trained = _wearing(
        const [],
        skills: const {SkillId.arms: SkillState(level: 4)},
      );

      // act
      final range = heroAttack(_fists, trained);

      // assert
      expect(range, (3, 4));
    });
  });

  group('heroArmor', () {
    test('is zero with nothing on', () {
      // arrange
      final loadout = _wearing(const []);

      // act
      final armor = heroArmor(loadout);

      // assert
      expect(armor, 0);
    });

    test('sums every worn piece and its affixes', () {
      // arrange
      final loadout = _wearing([
        _rolled(_hauberk, affixes: const [_swiftness]),
      ]);

      // act
      final armor = heroArmor(loadout);

      // assert
      expect(armor, 3);
    });

    test('Bulwark adds half its level', () {
      // arrange
      final loadout = _wearing(
        [_rolled(_hauberk)],
        skills: const {SkillId.bulwark: SkillState(level: 5)},
      );

      // act
      final armor = heroArmor(loadout);

      // assert
      expect(armor, 5);
    });
  });

  group('heroDodgePercent', () {
    test('is zero untrained, so an unskilled hero never rolls to dodge', () {
      // arrange
      final loadout = _wearing(const []);

      // act
      final dodge = heroDodgePercent(loadout);

      // assert
      expect(dodge, 0);
    });

    test('rises three points per Fleetfoot level', () {
      // arrange
      final loadout = _wearing(
        const [],
        skills: const {SkillId.fleetfoot: SkillState(level: 4)},
      );

      // act
      final dodge = heroDodgePercent(loadout);

      // assert
      expect(dodge, 12);
    });

    test('is capped, so dodge can never crowd out armour entirely', () {
      // arrange
      final loadout = _wearing(
        const [],
        skills: const {SkillId.fleetfoot: SkillState(level: 90)},
      );

      // act
      final dodge = heroDodgePercent(loadout);

      // assert
      expect(dodge, dodgeCapPercent);
    });
  });

  group('heroMaxHp and heroSpeed', () {
    test('base values come from the hero itself', () {
      // arrange
      final loadout = _wearing(const []);

      // act
      final derived = (heroMaxHp(_fists, loadout), heroSpeed(_fists, loadout));

      // assert
      expect(derived, (20, 10));
    });

    test('affixes add to both', () {
      // arrange
      final loadout = _wearing([
        _rolled(_hauberk, affixes: const [_vigour, _swiftness]),
      ]);

      // act
      final derived = (heroMaxHp(_fists, loadout), heroSpeed(_fists, loadout));

      // assert
      expect(derived, (24, 12));
    });
  });

  group('Loadout', () {
    test('knows whether anything worn is heavy', () {
      // arrange
      final heavy = _wearing([_rolled(_hauberk)]);
      final light = _wearing([_rolled(_jerkin)]);
      final bare = _wearing(const []);

      // act
      final wearsHeavy = (heavy.wearsHeavy, light.wearsHeavy, bare.wearsHeavy);

      // assert
      expect(wearsHeavy, (true, false, false));
    });

    test('knows whether the held weapon needs both hands', () {
      // arrange
      final twoHanded = _wearing([_rolled(_maul)]);
      final oneHanded = _wearing([_rolled(_sword)]);
      final empty = _wearing(const []);

      // act
      final both = (
        twoHanded.wieldsTwoHanded,
        oneHanded.wieldsTwoHanded,
        empty.wieldsTwoHanded,
      );

      // assert
      expect(both, (true, false, false));
    });

    test('reads a missing skill as untrained rather than throwing', () {
      // arrange
      const loadout = Loadout(equipment: {}, skills: {});

      // act
      final level = loadout.levelOf(SkillId.arms);

      // assert
      expect(level, 0);
    });
  });
}
```

- [ ] **Step 2: Run it and confirm it fails**

Run: `cd packages/core && dart test test/loot/loadout_test.dart`
Expected: FAIL — `Loadout` and the derivations are undefined.

- [ ] **Step 3: Implement**

```dart
import 'package:equatable/equatable.dart';

import '../engine/actor.dart';
import '../skills/skill.dart';
import 'equip_slot.dart';
import 'item.dart';

/// What the hero is wearing, by slot.
typedef Equipment = Map<EquipSlot, Item>;

/// The most dodge Fleetfoot can ever buy, in percent.
///
/// A cap exists because dodge multiplies with armour instead of adding to it:
/// an uncapped dodge chance would eventually make every other defensive
/// decision irrelevant, and a hero who is simply never hit is not playing the
/// combat system any more.
const int dodgeCapPercent = 30;

/// The gear and the training every effective hero stat derives from.
///
/// This is deliberately *not* a set of mutated fields on [Actor], and that is
/// the single most important design decision in this file. If equipping a
/// helmet added two to `Actor.armor, then unequipping it would have to
/// subtract exactly two — and the moment armour also comes from a skill level,
/// from an affix, and from a set bonus, "exactly two" becomes a running total
/// that some code path will eventually fail to keep. Deriving on read makes
/// the equipment map the single source of truth, so an unequip cannot leave a
/// stale bonus behind: there is no stored total to go stale.
///
/// It is a value object rather than a view over [GameState] because skills
/// train *during* a turn. A level-up in the middle of the monster phase has to
/// change armour and dodge for the very next monster's swing, and those trained
/// skills are not in any game state yet.
class Loadout extends Equatable {
  const Loadout({required this.equipment, required this.skills});

  final Equipment equipment;
  final Map<SkillId, SkillState> skills;

  /// How far [skill] has come, reading an absent entry as untrained.
  int levelOf(SkillId skill) => skills[skill]?.level ?? 0;

  /// What is in the hero's main hand, or null for bare fists.
  Item? get weapon => equipment[EquipSlot.mainHand];

  /// Whether any worn piece is heavy, which is what Bulwark trains on.
  bool get wearsHeavy =>
      equipment.values.any((item) => item.base.heavy);

  /// Whether the held weapon claims both hands, which excludes a shield.
  bool get wieldsTwoHanded => weapon?.base.hands == WeaponHands.two;

  Loadout withEquipment(Equipment equipment) =>
      Loadout(equipment: equipment, skills: skills);

  Loadout withSkills(Map<SkillId, SkillState> skills) =>
      Loadout(equipment: equipment, skills: skills);

  @override
  List<Object?> get props => [equipment, skills];

  @override
  String toString() =>
      'Loadout(${equipment.length} worn, ${skills.length} skills)';
}

/// The damage range one hero swing rolls between.
///
/// The hero's own [Actor.attackMin] and [Actor.attackMax] are its bare fists;
/// a weapon and its affixes add on top, so a hero who drops everything still
/// punches instead of dealing nothing.
///
/// Only the skill matching the held weapon applies — Arms for one-handed
/// weapons and for fists, Might for two-handed. Adding both would mean
/// training a greatsword sharpened the hero's dagger, which is neither what the
/// training triggers say nor what a player would expect.
(int, int) heroAttack(Actor hero, Loadout loadout) {
  final weapon = loadout.weapon;
  final mastery = loadout.wieldsTwoHanded ? SkillId.might : SkillId.arms;
  final bonus = loadout.levelOf(mastery) ~/ 2;
  return (
    hero.attackMin + (weapon?.attackMin ?? 0) + bonus,
    hero.attackMax + (weapon?.attackMax ?? 0) + bonus,
  );
}

/// How much a hit against the hero is reduced by, before the floor of one.
int heroArmor(Loadout loadout) {
  final worn = loadout.equipment.values.fold(
    0,
    (total, item) => total + item.armor,
  );
  return worn + loadout.levelOf(SkillId.bulwark) ~/ 2;
}

/// The chance in a hundred that a hit against the hero misses entirely.
///
/// Fleetfoot alone feeds this, which is what stops dodge and armour compounding
/// without limit: Fleetfoot only trains while the hero wears nothing heavy and
/// Bulwark only while it does, so the two defences are alternatives rather than
/// a stack — see [dodgeCapPercent] for the ceiling on what is left.
int heroDodgePercent(Loadout loadout) {
  final trained = loadout.levelOf(SkillId.fleetfoot) * 3;
  return trained > dodgeCapPercent ? dodgeCapPercent : trained;
}

/// The hero's hit point ceiling: its own base plus every worn affix.
int heroMaxHp(Actor hero, Loadout loadout) =>
    hero.maxHp +
    loadout.equipment.values.fold(0, (total, item) => total + item.maxHp);

/// How fast the hero acts on the speed clock: its own base plus worn affixes.
int heroSpeed(Actor hero, Loadout loadout) =>
    hero.speed +
    loadout.equipment.values.fold(0, (total, item) => total + item.speed);
```

Export `loadout.dart` from `core.dart`.

- [ ] **Step 4: Run and confirm green**

Run: `cd packages/core && dart test`
Expected: PASS, 173 + 17 = 190.

- [ ] **Step 5: Commit**

```bash
git add packages/core/lib/src/loot/loadout.dart packages/core/lib/core.dart packages/core/test/loot/loadout_test.dart
git commit -m "feat(loot): derive effective hero stats from gear and training"
```

---

### Task 5: Drop tables and rollDrop

**Files:**

- Create: `packages/core/lib/src/loot/drop.dart`
- Modify: `packages/core/lib/core.dart`
- Test: `packages/core/test/loot/drop_test.dart`

**Interfaces:**

- Consumes: `BaseItem,`Affix, `Item,`Rarity, `Rng`.
- Produces: `class Weighted<T> { T value; int weight; }`;
  `class DropTable { List<Weighted<BaseItem>> items;
   List<Weighted<Rarity>> rarities; List<Affix> weaponAffixes;
   List<Affix> armourAffixes; int minFloorItems; int maxFloorItems; }`;
  `Item rollDrop(DropTable table, Rng rng, String id)`;
  `int rollFloorItemCount(DropTable table, Rng rng)`.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

const _sword = BaseItem(
  id: 'iron-sword',
  name: 'Iron Sword',
  glyph: ')',
  slot: EquipSlot.mainHand,
  hands: WeaponHands.one,
  attackMin: 3,
  attackMax: 5,
);

const _hauberk = BaseItem(
  id: 'mail-hauberk',
  name: 'Mail Hauberk',
  glyph: '[',
  slot: EquipSlot.chest,
  armor: 3,
  heavy: true,
);

const _potion = BaseItem(
  id: 'healing-potion',
  name: 'Healing Potion',
  glyph: '!',
  heal: 8,
);

const _weaponAffixes = [
  Affix(id: 'keen', affixName: 'Keen', isPrefix: true, attackMax: 2),
  Affix(id: 'vicious', affixName: 'Vicious', isPrefix: true, attackMin: 2),
  Affix(id: 'of-embers', affixName: 'of Embers', isPrefix: false, attackMin: 1),
  Affix(id: 'of-fury', affixName: 'of Fury', isPrefix: false, speed: 1),
];

const _armourAffixes = [
  Affix(id: 'sturdy', affixName: 'Sturdy', isPrefix: true, armor: 1),
  Affix(id: 'reinforced', affixName: 'Reinforced', isPrefix: true, armor: 2),
  Affix(id: 'of-vigour', affixName: 'of Vigour', isPrefix: false, maxHp: 4),
  Affix(id: 'of-swiftness', affixName: 'of Swiftness', isPrefix: false, speed: 2),
];

DropTable _table({
  List<Weighted<BaseItem>>? items,
  List<Weighted<Rarity>>? rarities,
}) => DropTable(
  items: items ?? const [Weighted(_sword, 1)],
  rarities: rarities ?? const [Weighted(Rarity.common, 1)],
  weaponAffixes: _weaponAffixes,
  armourAffixes: _armourAffixes,
  minFloorItems: 2,
  maxFloorItems: 4,
);

void main() {
  group('rollDrop', () {
    test('takes its base item and tier from the table', () {
      // arrange
      final table = _table();

      // act
      final item = rollDrop(table, Rng(1), 'drop-1');

      // assert
      expect(item.id, 'drop-1');
      expect(item.base, _sword);
      expect(item.rarity, Rarity.common);
      expect(item.affixes, isEmpty);
    });

    test('rolls exactly as many affixes as the tier defines', () {
      // arrange
      final table = _table(rarities: const [Weighted(Rarity.epic, 1)]);

      // act
      final item = rollDrop(table, Rng(3), 'drop-2');

      // assert
      expect(item.affixes, hasLength(Rarity.epic.affixCount));
    });

    test('never rolls the same affix twice onto one item', () {
      // arrange
      final table = _table(rarities: const [Weighted(Rarity.legendary, 1)]);

      // act
      final ids = [
        for (var seed = 0; seed < 40; seed++)
          rollDrop(table, Rng(seed), 'drop-$seed').affixes
              .map((affix) => affix.id)
              .toList(),
      ];

      // assert
      expect(
        ids,
        everyElement(predicate<List<String>>((list) =>
            list.toSet().length == list.length)),
      );
    });

    test('draws weapon affixes for a weapon and armour affixes for armour', () {
      // arrange
      final weaponTable = _table(
        items: const [Weighted(_sword, 1)],
        rarities: const [Weighted(Rarity.legendary, 1)],
      );
      final armourTable = _table(
        items: const [Weighted(_hauberk, 1)],
        rarities: const [Weighted(Rarity.legendary, 1)],
      );

      // act
      final onWeapon = rollDrop(weaponTable, Rng(7), 'drop-3').affixes;
      final onArmour = rollDrop(armourTable, Rng(7), 'drop-4').affixes;

      // assert
      expect(onWeapon.toSet(), _weaponAffixes.toSet());
      expect(onArmour.toSet(), _armourAffixes.toSet());
    });

    test('a potion is always common, because an affix on it would do nothing',
        () {
      // arrange
      final table = _table(
        items: const [Weighted(_potion, 1)],
        rarities: const [Weighted(Rarity.epic, 1)],
      );

      // act
      final item = rollDrop(table, Rng(5), 'drop-5');

      // assert
      expect(item.rarity, Rarity.common);
      expect(item.affixes, isEmpty);
    });

    test('the same seed rolls the same item', () {
      // arrange
      final table = _table(
        items: const [Weighted(_sword, 1), Weighted(_hauberk, 1)],
        rarities: const [
          Weighted(Rarity.common, 1),
          Weighted(Rarity.rare, 1),
        ],
      );

      // act
      final one = rollDrop(table, Rng(42), 'drop-6');
      final other = rollDrop(table, Rng(42), 'drop-6');

      // assert
      expect(one, other);
    });

    test('weight zero is never drawn', () {
      // arrange
      final table = _table(
        items: const [Weighted(_sword, 1), Weighted(_hauberk, 0)],
      );

      // act
      final bases = [
        for (var seed = 0; seed < 50; seed++)
          rollDrop(table, Rng(seed), 'drop-$seed').base,
      ];

      // assert
      expect(bases, everyElement(_sword));
    });
  });

  group('rollFloorItemCount', () {
    test('stays inside the table bounds', () {
      // arrange
      final table = _table();

      // act
      final counts = [
        for (var seed = 0; seed < 50; seed++)
          rollFloorItemCount(table, Rng(seed)),
      ];

      // assert
      expect(counts, everyElement(inInclusiveRange(2, 4)));
    });
  });
}
```

- [ ] **Step 2: Run it and confirm it fails**

Run: `cd packages/core && dart test test/loot/drop_test.dart`
Expected: FAIL — `Weighted,`DropTable, `rollDrop` undefined.

- [ ] **Step 3: Implement**

```dart
import 'package:equatable/equatable.dart';

import '../engine/rng.dart';
import 'item.dart';
import 'rarity.dart';

/// One entry of a weighted table: a [value] and its share of the draw.
///
/// A weight of zero is never drawn. That is how [Rarity.legendary] can exist as
/// a tier this milestone without ever appearing in a drop: sets arrive with M4
/// and until then a Legendary would be an Epic wearing a better word.
class Weighted<T> extends Equatable {
  const Weighted(this.value, this.weight);

  final T value;
  final int weight;

  @override
  List<Object?> get props => [value, weight];

  @override
  String toString() => 'Weighted($value, $weight)';
}

/// What one depth of the dungeon can give up.
///
/// A table is data, not behaviour, which is why the game state carries these
/// directly instead of a closure the way it carries its floor builder: nothing
/// about choosing an item needs to know where the numbers came from.
class DropTable extends Equatable {
  const DropTable({
    required this.items,
    required this.rarities,
    required this.weaponAffixes,
    required this.armourAffixes,
    required this.minFloorItems,
    required this.maxFloorItems,
  });

  final List<Weighted<BaseItem>> items;
  final List<Weighted<Rarity>> rarities;

  /// Drawn onto weapons. Kept apart from [armourAffixes] so a helmet never
  /// rolls a bonus that reads as a weapon's.
  final List<Affix> weaponAffixes;

  final List<Affix> armourAffixes;

  final int minFloorItems;
  final int maxFloorItems;

  @override
  List<Object?> get props => [
    items,
    rarities,
    weaponAffixes,
    armourAffixes,
    minFloorItems,
    maxFloorItems,
  ];

  @override
  String toString() => 'DropTable(${items.length} items)';
}

/// One item rolled off [table], drawing every decision from [rng].
///
/// The order of draws is fixed — base item, then tier, then affixes — because
/// that order is part of the seed contract: two crawls on one world seed that
/// kill the same monsters in the same order must find the same loot, and a
/// reordered draw would break that as surely as a different seed.
///
/// Affixes are drawn without replacement, so no item carries the same affix
/// twice. Each table's pools therefore need at least [Rarity.legendary]'s affix
/// count of entries; content tests pin that.
///
/// A potion is forced to [Rarity.common]. Affixes on a consumable would be
/// bonuses on a thing that is never worn — a 'Rare Healing Potion of Vigour'
/// promises the player something the rules cannot deliver.
Item rollDrop(DropTable table, Rng rng, String id) {
  final base = _draw(table.items, rng);
  if (base.isPotion) {
    return Item(id: id, base: base, rarity: Rarity.common);
  }
  final rarity = _draw(table.rarities, rng);
  final pool = [
    ...base.isWeapon ? table.weaponAffixes : table.armourAffixes,
  ];
  final affixes = <Affix>[];
  for (var rolled = 0; rolled < rarity.affixCount && pool.isNotEmpty; rolled++) {
    affixes.add(pool.removeAt(rng.rollRange(0, pool.length - 1)));
  }
  return Item(id: id, base: base, rarity: rarity, affixes: affixes);
}

/// How many items this depth scatters on the floor before the hero arrives.
int rollFloorItemCount(DropTable table, Rng rng) =>
    rng.rollRange(table.minFloorItems, table.maxFloorItems);

T _draw<T>(List<Weighted<T>> entries, Rng rng) {
  final total = entries.fold(0, (sum, entry) => sum + entry.weight);
  var roll = rng.rollRange(1, total);
  for (final entry in entries) {
    if (entry.weight == 0) continue;
    roll -= entry.weight;
    if (roll <= 0) return entry.value;
  }
  return entries.last.value;
}
```

- [ ] **Step 4: Run and confirm green**

Run: `cd packages/core && dart test`
Expected: PASS, 190 + 8 = 198.

- [ ] **Step 5: Commit**

```bash
git add packages/core/lib/src/loot/drop.dart packages/core/lib/core.dart packages/core/test/loot/drop_test.dart
git commit -m "feat(loot): weighted drop tables and the roll that reads them"
```

---

### Task 6: State, actions and events

**Files:**

- Modify: `packages/core/lib/src/engine/game_state.dart`
- Modify: `packages/core/lib/src/engine/action.dart`
- Modify: `packages/core/lib/src/engine/event.dart`
- Modify: `packages/core/lib/src/engine/actor.dart`
- Modify: `packages/core/test/support/fixtures.dart`
- Test: `packages/core/test/engine/game_state_loot_test.dart`

**Interfaces:**

- Consumes: everything from Tasks 1–5.
- Produces: `GameState` gains required `lootRng` and optional `groundItems,`inventory, `equipment,`skills, `dropTables,`nextDropNumber, plus
  `Loadout get loadout` and `List<Item> itemsAt(Position)`; `copyWith` gains
  every new field. `Actor` gains `dropChance` (default 0) and `copyWith` keeps
  it. Actions: `PickUpAction,`EquipAction(String itemId), `UnequipAction(EquipSlot slot),`DrinkAction(String itemId), `DropAction(String itemId)`. Events: `ItemDropped(Item item, Position at),`ItemPickedUp(Item item), `InventoryFull(),`ItemEquipped(Item, EquipSlot), `ItemUnequipped(Item, EquipSlot),`EquipRefused(String reason), `PotionDrunk(Item, int healed),`AttackDodged(String attackerId), `SkillLevelledUp(SkillId skill, int level)`.
  `const int inventoryCap = 20`.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

const _sword = BaseItem(
  id: 'iron-sword',
  name: 'Iron Sword',
  glyph: ')',
  slot: EquipSlot.mainHand,
  hands: WeaponHands.one,
  attackMin: 3,
  attackMax: 5,
);

const _room = '''
#####
#...#
#...#
#####''';

void main() {
  group('GameState loot fields', () {
    test('a fresh crawl carries no loot and all four skills untrained', () {
      // arrange
      final game = crawl(ascii: _room, heroAt: const Position(2, 2));

      // act
      final loadout = game.loadout;

      // assert
      expect(game.inventory, isEmpty);
      expect(game.groundItems, isEmpty);
      expect(game.equipment, isEmpty);
      expect(loadout.skills, untrainedSkills);
      expect(game.nextDropNumber, 1);
    });

    test('reads the items lying on a tile, newest last', () {
      // arrange
      const first = Item(id: 'drop-1', base: _sword, rarity: Rarity.common);
      const second = Item(id: 'drop-2', base: _sword, rarity: Rarity.fine);
      final game = crawl(
        ascii: _room,
        heroAt: const Position(2, 2),
        groundItems: const {
          Position(1, 1): [first, second],
        },
      );

      // act
      final here = game.itemsAt(const Position(1, 1));

      // assert
      expect(here, [first, second]);
      expect(game.itemsAt(const Position(2, 2)), isEmpty);
    });

    test('the loot stream is separate from the combat stream', () {
      // arrange
      final game = crawl(ascii: _room, heroAt: const Position(2, 2));

      // act
      final same = game.rng == game.lootRng;

      // assert
      expect(same, isFalse);
    });

    test('copyWith carries every loot field it was not given', () {
      // arrange
      const item = Item(id: 'drop-1', base: _sword, rarity: Rarity.common);
      final game = crawl(
        ascii: _room,
        heroAt: const Position(2, 2),
        inventory: const [item],
        equipment: const {EquipSlot.mainHand: item},
        skills: const {SkillId.arms: SkillState(level: 3)},
        groundItems: const {
          Position(1, 1): [item],
        },
      );

      // act
      final after = game.copyWith(depth: 2);

      // assert
      expect(after.inventory, game.inventory);
      expect(after.equipment, game.equipment);
      expect(after.skills, game.skills);
      expect(after.groundItems, game.groundItems);
      expect(after.dropTables, game.dropTables);
      expect(after.nextDropNumber, game.nextDropNumber);
    });

    test('copyWith replaces the loot fields it is given', () {
      // arrange
      const item = Item(id: 'drop-1', base: _sword, rarity: Rarity.common);
      final game = crawl(ascii: _room, heroAt: const Position(2, 2));

      // act
      final after = game.copyWith(
        inventory: const [item],
        equipment: const {EquipSlot.mainHand: item},
        skills: const {SkillId.might: SkillState(level: 1)},
        groundItems: const {
          Position(1, 1): [item],
        },
        nextDropNumber: 4,
      );

      // assert
      expect(after.inventory, [item]);
      expect(after.equipment[EquipSlot.mainHand], item);
      expect(after.skills[SkillId.might], const SkillState(level: 1));
      expect(after.itemsAt(const Position(1, 1)), [item]);
      expect(after.nextDropNumber, 4);
    });
  });

  group('Actor.dropChance', () {
    test('defaults to nothing, so the hero never drops itself', () {
      // arrange
      final game = crawl(ascii: _room, heroAt: const Position(2, 2));

      // act
      final chance = game.hero.dropChance;

      // assert
      expect(chance, 0);
    });

    test('survives copyWith', () {
      // arrange
      const monster = Actor(
        id: 'ghoul-1',
        name: 'the ghoul',
        glyph: 'g',
        position: Position(1, 1),
        hp: 10,
        maxHp: 10,
        attackMin: 2,
        attackMax: 4,
        speed: 10,
        energy: actThreshold,
        dropChance: 40,
      );

      // act
      final after = monster.copyWith(hp: 3);

      // assert
      expect(after.dropChance, 40);
    });
  });

  group('loot events', () {
    test('are value objects', () {
      // arrange
      const item = Item(id: 'drop-1', base: _sword, rarity: Rarity.common);

      // act
      final pairs = [
        (
          const ItemPickedUp(item: item),
          const ItemPickedUp(item: item),
        ),
        (const InventoryFull(), const InventoryFull()),
        (
          const ItemEquipped(item: item, slot: EquipSlot.mainHand),
          const ItemEquipped(item: item, slot: EquipSlot.mainHand),
        ),
        (
          const ItemUnequipped(item: item, slot: EquipSlot.mainHand),
          const ItemUnequipped(item: item, slot: EquipSlot.mainHand),
        ),
        (
          const EquipRefused(reason: 'both hands are full'),
          const EquipRefused(reason: 'both hands are full'),
        ),
        (
          const PotionDrunk(item: item, healed: 5),
          const PotionDrunk(item: item, healed: 5),
        ),
        (
          const AttackDodged(attackerId: 'ghoul-1'),
          const AttackDodged(attackerId: 'ghoul-1'),
        ),
        (
          const SkillLevelledUp(skill: SkillId.arms, level: 2),
          const SkillLevelledUp(skill: SkillId.arms, level: 2),
        ),
        (
          const ItemDropped(item: item, at: Position(1, 1)),
          const ItemDropped(item: item, at: Position(1, 1)),
        ),
      ];

      // assert
      for (final (one, other) in pairs) {
        expect(one, other, reason: one.toString());
      }
    });

    test('events with different fields are not equal', () {
      // arrange
      const one = SkillLevelledUp(skill: SkillId.arms, level: 2);
      const other = SkillLevelledUp(skill: SkillId.arms, level: 3);

      // act
      final same = one == other;

      // assert
      expect(same, isFalse);
    });
  });
}
```

- [ ] **Step 2: Run it and confirm it fails**

Run: `cd packages/core && dart test test/engine/game_state_loot_test.dart`
Expected: FAIL — the new fields, actions and events are undefined.

- [ ] **Step 3: Implement**

`actor.dart`: add

```dart
  /// The chance in a hundred that killing this actor yields an item. Zero for
  /// the hero, which is why it defaults to nothing.
  final int dropChance;
```

to the constructor (`this.dropChance = 0`), the fields and `copyWith`.

`game_state.dart`: extend the class dartdoc's carried-by-reference argument to
name `lootRng` alongside `rng` and `buildFloor, and add:

```dart
  /// The stream every drop roll draws from, kept apart from [rng].
  ///
  /// Loot has to be a property of the world, not of how a fight went. If drops
  /// shared the combat stream, then two players on one world seed who killed
  /// the same monsters in a different order — or who missed one extra swing on
  /// the way — would find different loot, and a shared seed would stop
  /// describing a shared dungeon. Splitting the streams is what makes "seed 7,
  /// depth 3, the axe is in the north room" a sentence one player can say to
  /// another.
  final Rng lootRng;

  /// What is lying on the floor, by tile. A tile with nothing on it has no
  /// entry rather than an empty list.
  final Map<Position, List<Item>> groundItems;

  /// What the hero is carrying but not wearing. Never longer than
  /// [inventoryCap].
  final List<Item> inventory;

  final Equipment equipment;

  /// All four skills, always present.
  final Map<SkillId, SkillState> skills;

  /// What each depth can give up. Empty means this crawl has no loot in it,
  /// which is what most rule tests want.
  final Map<int, DropTable> dropTables;

  /// The number the next kill's item id is built from.
  final int nextDropNumber;

  /// The gear and training every effective hero stat derives from.
  Loadout get loadout => Loadout(equipment: equipment, skills: skills);

  /// What is lying on [position], oldest first.
  List<Item> itemsAt(Position position) => groundItems[position] ?? const [];
```

Constructor: `required this.lootRng, and the rest optional with
`groundItems = const {}, `inventory = const [],`equipment = const {}, `Map<SkillId, SkillState>? skills,`dropTables = const {}, `nextDropNumber = 1`; wrap the collections with `Map.unmodifiable` /
`List.unmodifiable` in the initialiser list the way `monsters` already is, and
default `skills` to `untrainedSkills`. `copyWith` gains all of them plus
`lootRng` carried by reference.

`action.dart`: add the five actions, each with the dartdoc line the spec's
contract gives it.

`event.dart`: add the nine events, each `extends GameEvent with Equatable,
matching the existing style exactly (props + explicit`toString`).

`inventoryCap` goes in `game_state.dart` next to the state it constrains.

`fixtures.dart`: `crawl` gains `lootSeed,`groundItems, `inventory,`equipment, `skills,`dropTables` parameters, all defaulted, and passes
`lootRng: Rng(lootSeed)`. Hero's`attack` default stays 4 so every existing
test keeps its numbers.

- [ ] **Step 4: Run and confirm green**

Run: `cd packages/core && dart test`
Expected: PASS, 198 + 9 = 207. The 156 pre-existing core tests are untouched.

- [ ] **Step 5: Commit**

```bash
git add packages/core
git commit -m "feat(engine): carry loot, gear and skills in the game state"
```

---

### Task 7: Armor, dodge and skill training in the damage math

**Files:**

- Modify: `packages/core/lib/src/engine/step.dart`
- Test: `packages/core/test/engine/step_combat_test.dart`

**Interfaces:**

- Consumes: `Loadout` derivations, `SkillState.trained, the new events.
- Produces: `step` uses `heroAttack` for the hero's swing, subtracts
  `heroArmor` from monster damage with a floor of 1, rolls dodge from
  `state.rng` only when `heroDodgePercent > 0, trains Arms/Might on hits
  landed and Bulwark/Fleetfoot on hits taken or dodged, emits
  `AttackDodged` and `SkillLevelledUp, and clamps hp to `heroMaxHp`.

- [ ] **Step 1: Write the failing test**

Tests to write, each `// arrange` / `// act` / `// assert`:

```dart
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

const _hall = '''
#######
#.....#
#.....#
#######''';

const _sword = BaseItem(
  id: 'iron-sword',
  name: 'Iron Sword',
  glyph: ')',
  slot: EquipSlot.mainHand,
  hands: WeaponHands.one,
  attackMin: 3,
  attackMax: 5,
);

const _maul = BaseItem(
  id: 'maul',
  name: 'Maul',
  glyph: ')',
  slot: EquipSlot.mainHand,
  hands: WeaponHands.two,
  attackMin: 7,
  attackMax: 11,
);

const _hauberk = BaseItem(
  id: 'mail-hauberk',
  name: 'Mail Hauberk',
  glyph: '[',
  slot: EquipSlot.chest,
  armor: 3,
  heavy: true,
);

const _jerkin = BaseItem(
  id: 'leather-jerkin',
  name: 'Leather Jerkin',
  glyph: '[',
  slot: EquipSlot.chest,
  armor: 1,
);

Item _worn(BaseItem base) =>
    Item(id: 'worn-${base.id}', base: base, rarity: Rarity.common);

void main() {
  group('armour reduces monster damage', () {
    test('subtracts armour from the roll', () {
      // arrange — a ghoul that always rolls 4, against 3 armour
      final game = crawl(
        ascii: _hall,
        heroAt: const Position(2, 1),
        monsters: [ghoul('ghoul-1', const Position(3, 1), attack: 4)],
        equipment: {EquipSlot.chest: _worn(_hauberk)},
      );

      // act
      final (_, events) = step(game, const MoveAction(Direction.west));

      // assert
      final taken = events
          .whereType<AttackHit>()
          .where((event) => event.targetId == 'hero');
      expect(taken.single.damage, 1);
    });

    test('never reduces a hit below one', () {
      // arrange
      final game = crawl(
        ascii: _hall,
        heroAt: const Position(2, 1),
        monsters: [ghoul('ghoul-1', const Position(3, 1), attack: 2)],
        equipment: {EquipSlot.chest: _worn(_hauberk)},
        skills: const {SkillId.bulwark: SkillState(level: 40)},
      );

      // act
      final (after, events) = step(game, const MoveAction(Direction.west));

      // assert
      final taken = events
          .whereType<AttackHit>()
          .where((event) => event.targetId == 'hero');
      expect(taken.single.damage, 1);
      expect(after.hero.hp, 19);
    });
  });

  group('dodge', () {
    test('an untrained hero never draws from the combat stream to dodge', () {
      // arrange
      GameState fresh({required bool armoured}) => crawl(
        ascii: _hall,
        heroAt: const Position(2, 1),
        monsters: [
          Actor(
            id: 'ghoul-1',
            name: 'the ghoul',
            glyph: 'g',
            position: const Position(3, 1),
            hp: 10,
            maxHp: 10,
            attackMin: 2,
            attackMax: 4,
            speed: 10,
            energy: actThreshold,
          ),
        ],
        seed: 5,
        equipment: armoured ? {EquipSlot.chest: _worn(_jerkin)} : const {},
      );

      // act
      final (_, bare) = step(fresh(armoured: false),
          const MoveAction(Direction.west));
      final (_, dressed) = step(fresh(armoured: true),
          const MoveAction(Direction.west));

      // assert — same seed, same roll: gear that grants no dodge cannot shift
      // the stream
      final bareDamage = bare.whereType<AttackHit>()
          .where((event) => event.targetId == 'hero').single.damage;
      final dressedDamage = dressed.whereType<AttackHit>()
          .where((event) => event.targetId == 'hero').single.damage;
      expect(dressedDamage, bareDamage - 1);
    });

    test('a fully trained hero dodges and takes no damage', () {
      // arrange
      final game = crawl(
        ascii: _hall,
        heroAt: const Position(2, 1),
        monsters: [ghoul('ghoul-1', const Position(3, 1), attack: 4)],
        skills: const {SkillId.fleetfoot: SkillState(level: 100)},
        seed: 3,
      );

      // act — over several turns at the cap, at least one swing misses
      var current = game;
      final dodged = <AttackDodged>[];
      for (var turn = 0; turn < 40; turn++) {
        final (next, events) = step(current, const MoveAction(Direction.west));
        dodged.addAll(events.whereType<AttackDodged>());
        current = next;
        if (current.isGameOver) break;
      }

      // assert
      expect(dodged, isNotEmpty);
      expect(dodged.first.attackerId, 'ghoul-1');
    });
  });

  group('skill training', () {
    test('Arms trains on a hit landed with one hand', () {
      // arrange
      final game = crawl(
        ascii: _hall,
        heroAt: const Position(2, 1),
        monsters: [ghoul('ghoul-1', const Position(3, 1), hp: 200)],
        equipment: {EquipSlot.mainHand: _worn(_sword)},
      );

      // act
      final (after, _) = step(game, const MoveAction(Direction.east));

      // assert
      expect(after.skills[SkillId.arms], const SkillState(xp: 1));
      expect(after.skills[SkillId.might], const SkillState());
    });

    test('fists train Arms too', () {
      // arrange
      final game = crawl(
        ascii: _hall,
        heroAt: const Position(2, 1),
        monsters: [ghoul('ghoul-1', const Position(3, 1), hp: 200)],
      );

      // act
      final (after, _) = step(game, const MoveAction(Direction.east));

      // assert
      expect(after.skills[SkillId.arms], const SkillState(xp: 1));
    });

    test('Might trains on a hit landed with two hands', () {
      // arrange
      final game = crawl(
        ascii: _hall,
        heroAt: const Position(2, 1),
        monsters: [ghoul('ghoul-1', const Position(3, 1), hp: 200)],
        equipment: {EquipSlot.mainHand: _worn(_maul)},
      );

      // act
      final (after, _) = step(game, const MoveAction(Direction.east));

      // assert
      expect(after.skills[SkillId.might], const SkillState(xp: 1));
      expect(after.skills[SkillId.arms], const SkillState());
    });

    test('Bulwark trains on a hit taken in heavy armour', () {
      // arrange
      final game = crawl(
        ascii: _hall,
        heroAt: const Position(2, 1),
        monsters: [ghoul('ghoul-1', const Position(3, 1), attack: 1)],
        equipment: {EquipSlot.chest: _worn(_hauberk)},
      );

      // act
      final (after, _) = step(game, const MoveAction(Direction.west));

      // assert
      expect(after.skills[SkillId.bulwark], const SkillState(xp: 1));
      expect(after.skills[SkillId.fleetfoot], const SkillState());
    });

    test('Fleetfoot trains on a hit taken wearing nothing heavy', () {
      // arrange
      final game = crawl(
        ascii: _hall,
        heroAt: const Position(2, 1),
        monsters: [ghoul('ghoul-1', const Position(3, 1), attack: 1)],
        equipment: {EquipSlot.chest: _worn(_jerkin)},
      );

      // act
      final (after, _) = step(game, const MoveAction(Direction.west));

      // assert
      expect(after.skills[SkillId.fleetfoot], const SkillState(xp: 1));
      expect(after.skills[SkillId.bulwark], const SkillState());
    });

    test('a level-up reaches the log', () {
      // arrange
      final game = crawl(
        ascii: _hall,
        heroAt: const Position(2, 1),
        monsters: [ghoul('ghoul-1', const Position(3, 1), hp: 2000)],
        skills: const {SkillId.arms: SkillState(level: 0, xp: 7)},
      );

      // act
      final (after, events) = step(game, const MoveAction(Direction.east));

      // assert
      expect(
        events,
        contains(const SkillLevelledUp(skill: SkillId.arms, level: 1)),
      );
      expect(after.skills[SkillId.arms]?.level, 1);
    });
  });

  group('derived max hp', () {
    test('the hero can be healed up to its geared maximum', () {
      // arrange
      const vigour = Affix(
        id: 'of-vigour',
        affixName: 'of Vigour',
        isPrefix: false,
        maxHp: 4,
      );
      final game = crawl(
        ascii: _hall,
        heroAt: const Position(2, 1),
        equipment: {
          EquipSlot.chest: const Item(
            id: 'worn-1',
            base: _hauberk,
            rarity: Rarity.fine,
            affixes: [vigour],
          ),
        },
      );

      // act
      final max = heroMaxHp(game.hero, game.loadout);

      // assert
      expect(max, 24);
    });
  });
}
```

- [ ] **Step 2: Run it and confirm it fails**

Run: `cd packages/core && dart test test/engine/step_combat_test.dart`
Expected: FAIL — armour is not subtracted, no dodge, no training.

- [ ] **Step 3: Implement**

Restructure `step.dart`:

- `_moveHero` rolls `heroAttack(hero, loadout)` instead of
  `hero.attackMin/attackMax, and trains Arms or Might on the hit.
- `_monsterPhase` gains the dodge-then-armour pipeline and the defensive
  training. It threads a mutable local `Loadout` so a mid-phase level-up
  changes the very next swing.
- `_monsterPhase` passes `heroSpeed(hero, loadout)` to `scheduleMonsterTurns`.
- Training is one helper, `_train(SkillId, Map, List<GameEvent>), returning the
  new skills map and emitting`SkillLevelledUp` when the level rose.

The dodge dartdoc, which the architect made a required deliverable:

```dart
/// Whether [attacker]'s swing misses entirely.
///
/// **A hero with no dodge chance does not roll at all**, and that is a
/// determinism rule rather than an optimisation. The dodge roll draws from the
/// combat stream, so rolling it unconditionally would advance that stream once
/// per monster attack for every hero in the game — including every hero with
/// zero chance of dodging. Every seeded fight ever recorded would resolve
/// differently, and a zero-probability roll would have bought exactly nothing
/// in exchange.
```

- [ ] **Step 4: Run and confirm green**

Run: `cd packages/core && dart test`
Expected: PASS, 207 + 11 = 218. **All 156 pre-existing tests must still pass
untouched** — if any reddens, stop and diagnose rather than editing the test.

- [ ] **Step 5: Commit**

```bash
git add packages/core
git commit -m "feat(combat): armour, dodge and learn-by-doing in the damage math"
```

---

### Task 8: The five loot actions

**Files:**

- Modify: `packages/core/lib/src/engine/step.dart`
- Test: `packages/core/test/engine/step_loot_test.dart`

**Interfaces:**

- Consumes: Task 6's actions and events, Task 7's restructured `step`.
- Produces: `step` handles `PickUpAction,`EquipAction, `UnequipAction,`DrinkAction, `DropAction`. A refused action returns the state unchanged
  with exactly one event and **no** monster phase.

Rules, each one a test:

- Pick up takes the **newest** item on the tile (last in the list), one per turn.
- Pick up with nothing underfoot is refused; with a full inventory emits
  `InventoryFull` and is refused.
- Equip moves an item from inventory into its base's slot; whatever was there
  returns to inventory. Non-equippable is refused with `EquipRefused`.
- A two-hander displaces the shield: both `ItemEquipped` and `ItemUnequipped`.
- A shield while a two-hander is held is refused with `EquipRefused`.
- Unequip an empty slot is refused. Unequip clamps hp to the new `heroMaxHp,
  floor 1.
- Drink heals `min(item.base.heal, heroMaxHp - hp)` and consumes the potion.
  Drinking a non-potion is refused. Drinking at full hp still consumes the
  turn and the potion, healing 0 — a wasted potion is a player mistake the
  rules should not undo.
- Drop moves an item from inventory to the hero's tile, appended as newest.
- Every accepted action consumes the turn: monsters act. Every refusal does not.

- [ ] **Step 1: Write the failing tests** (one per rule above, plus a
  `refused actions leave the state identical` test comparing hero energy,
  position and monster positions before and after).

- [ ] **Step 2: Run and confirm they fail**

Run: `cd packages/core && dart test test/engine/step_loot_test.dart`

- [ ] **Step 3: Implement**

Add to `step, before energy is spent:

```dart
  final refusal = _refuse(state, action);
  if (refusal != null) return (state, [refusal]);
```

`_refuse` returns the single event a refused action reports, or null. The switch
in `step` then handles each accepted action, and the shield-exclusion dartdoc
lands on the equip helper:

```dart
/// Puts [item] in its slot, displacing whatever the rules say it cannot share
/// a body with.
///
/// A two-handed weapon and a shield are the one pair that excludes each other,
/// and the exclusion is asymmetric on purpose. Equipping the two-hander
/// **displaces** the shield into the inventory, because the player's intent is
/// unambiguous — they picked the weapon. Equipping a shield while a two-hander
/// is held is **refused** instead, because silently dropping the hero's best
/// weapon to make room for a shield is the kind of help that loses a run.
```

And the unequip clamp:

```dart
/// The hero after taking [slot] off.
///
/// Hit points are clamped down to the new maximum, because +max-hp gear that
/// was carrying the hero above its own ceiling has just gone. The clamp has a
/// floor of one: undressing must never be a way to die. That floor is defence
/// in depth rather than a live rule — the hero's own base maximum is twenty and
/// content forbids a negative max-hp affix, so the clamp can never reach zero —
/// and it stays because the day an affix subtracts hit points is the day this
/// becomes load-bearing, and by then nobody will remember to add it.
```

- [ ] **Step 4: Run and confirm green**

Run: `cd packages/core && dart test`

- [ ] **Step 5: Commit**

```bash
git add packages/core
git commit -m "feat(loot): pick up, equip, unequip, drink and drop"
```

---

### Task 9: Floor items and drops on death

**Files:**

- Modify: `packages/core/lib/src/dungeon/generator.dart`
- Modify: `packages/core/lib/src/dungeon/floor.dart`
- Modify: `packages/core/lib/src/engine/step.dart`
- Test: `packages/core/test/dungeon/generator_items_test.dart`
- Test: `packages/core/test/engine/step_drop_test.dart`

**Interfaces:**

- Consumes: `DropTable,`rollDrop, `Actor.dropChance,`Floor`.
- Produces: `generateFloor` gains `required int itemCount` and
  `GeneratedFloor` gains `List<Position> itemSpawns`; `Floor` gains
  `Map<Position, List<Item>> groundItems`; `_arriveBelow` seeds
  `groundItems` from the new floor; a monster's death rolls
  `state.lootRng` against its `dropChance` and, on success, `rollDrop(table, state.lootRng, 'drop-<n>')` onto the death tile with
  `ItemDropped`.

Rules, each a test:

- `itemSpawns` has exactly `itemCount` distinct walkable positions, none on the
  hero spawn or the stairs. Unlike monster spawns they **may** be in sight when
  the hero arrives: an item you can see is an invitation, not an ambush.
- The same seed yields the same `itemSpawns` (layout determinism extends to
  items).
- A kill with `dropChance` 100 always drops; with 0 never drops.
- The dropped item lands on the tile the monster died on.
- Drop ids increment: `drop-1,`drop-2`.
- No drop table for the depth means no drop, no crash.
- Descending replaces `groundItems` with the new floor's, so items do not
  follow the hero down.

- [ ] **Step 1: Write the failing tests**
- [ ] **Step 2: Run and confirm they fail**
- [ ] **Step 3: Implement**
- [ ] **Step 4: Run and confirm green** (`cd packages/core && dart test`)
- [ ] **Step 5: Commit**

```bash
git add packages/core
git commit -m "feat(loot): floors scatter items and kills drop them"
```

---

### Task 10: Content — armory, affixes, drop tables, starting kit

**Files:**

- Create: `packages/content/lib/src/armory.dart`
- Create: `packages/content/lib/src/affix_pool.dart`
- Create: `packages/content/lib/src/drop_tables.dart`
- Modify: `packages/content/lib/src/bestiary.dart`
- Modify: `packages/content/lib/src/new_game.dart`
- Modify: `packages/content/lib/content.dart`
- Modify: `packages/content/test/content_validation_test.dart` (the one
  strengthened assertion at line 334, and the `lootRng` argument in the 1→5
  descent test)

**Interfaces:**

- Produces: `const List<BaseItem> armory` plus a named const per item;
  `BaseItem baseItemById(String id)`; `const List<Affix> affixPool,`weaponAffixes, `armourAffixes`; `Map<int, DropTable> dropTables` and
  `DropTable dropTableFor(int depth)`; `CreatureSpec.dropChance`;
  `newGame` supplies `lootRng: Rng(worldSeed ^ lootStreamSalt), the fists
  hero, the starting kit and the floor's items.

Details:

- `const int lootStreamSalt = 0x100D;` in `new_game.dart, dartdoc'd as the
  documented constant the loot stream is offset by. It is a literal so a world
  seed's loot stream is reproducible from the seed alone.
- Hero becomes `attackMin: 1, attackMax: 2` with `maxHp: 20, speed: 10`;
  equipment `{EquipSlot.mainHand: <rusty sword>}`; inventory two healing
  potions. Starting item ids are `kit-1,`kit-2, `kit-3` — a third namespace,
  for the same reason as the other two.
- `buildFloor` rolls the floor's items from the **floor's own** stream (the
  `Rng(seed)` it already has), not from `lootRng, so layout determinism covers
  starting items exactly as the spec requires.

- [ ] **Step 1: Write the failing test** — extend
  `content_validation_test.dart` with the strengthened hero assertion and a
  `newGame carries the starting kit` test.
- [ ] **Step 2: Run and confirm it fails**
- [ ] **Step 3: Implement**
- [ ] **Step 4: Run and confirm green** (all three suites)
- [ ] **Step 5: Commit**

```bash
git add packages/content
git commit -m "feat(content): armory, affix pool, drop tables and the starting kit"
```

---

### Task 11: Content validation

**Files:**

- Modify: `packages/content/test/content_validation_test.dart`

Tests:

- Every base item id is unique; every affix id is unique.
- Every base item's glyph is one of `),`[, `!`.
- A weapon has `hands` and a `mainHand` slot; armour has a slot and no `hands`;
  the potion has neither slot nor hands and a positive `heal`.
- **No affix has a negative `maxHp`** — this is what makes the unequip clamp's
  floor of one unreachable, and it must fail loudly if someone adds one.
- Every depth one through five has a drop table.
- Every drop table's items all appear in `armory, and every affix in
  `affixPool`.
- Every drop table's weapon and armour affix pools each hold at least
  `Rarity.legendary.affixCount` entries, so `affixes.length ==
  rarity.affixCount` can always hold.
- The healing potion has non-zero weight in every depth's table.
- `Rarity.legendary` has weight zero in every depth's table.
- Every creature's `dropChance` is between 0 and 100.
- Rarity weights are non-negative and sum above zero at every depth.

- [ ] **Step 1: Write the tests**
- [ ] **Step 2: Run and confirm any that should fail do**
- [ ] **Step 3: Fix content until green**
- [ ] **Step 4: Run and confirm green**
- [ ] **Step 5: Commit**

```bash
git add packages/content
git commit -m "test(content): validate the armory, affix pools and drop tables"
```

---

### Task 12: The survivability simulation and the tuning trail

**Files:**

- Create: `packages/content/test/survivability_test.dart`
- Modify: `packages/content/lib/src/drop_tables.dart` (tuning)
- Modify: `packages/content/lib/src/armory.dart` (tuning)
- Modify: `packages/content/lib/src/spawn_tables.dart` (fallback lever only)

The bot, exactly as the spec words it:

1. A monster orthogonally adjacent → attack it.
2. Else hp below 40% of `heroMaxHp` and a potion held → drink it.
3. Else standing on items → pick up (one per turn).
4. Else an item in inventory is a strict upgrade → equip it.
5. Else path to the stairs and take one step.
6. On the stairs → descend.
A run is a **win** when it reaches depth 5 alive; a loss on death; a run that
exceeds a turn budget counts as a loss, and the count of those is reported
separately so a stalling bot cannot be mistaken for a hard dungeon.

"Strict upgrade" is: for a weapon, a higher `attackMin + attackMax`; for
armour, a higher `armor + maxHp` in that slot; never a shield while a
two-hander is held.

The bot **knows the whole map** — it paths on the real floor, not on what the
hero has explored. That makes it stronger than a human at navigation and weaker
at tactics, so the win band measures content rather than exploration. Stated in
the test's own dartdoc.

- [ ] **Step 1: Write the simulation and the band assertion**

```dart
test('a 1 to 5 descent is survivable but not a formality', () {
  // arrange
  const seeds = 40;

  // act
  final wins = [
    for (var seed = 1; seed <= seeds; seed++)
      if (_botCrawl(worldSeed: seed).reachedDepthFiveAlive) seed,
  ];
  final rate = wins.length / seeds;

  // assert
  expect(rate, greaterThanOrEqualTo(0.50), reason: 'still unfair: $rate');
  expect(rate, lessThanOrEqualTo(0.95), reason: 'trivial: $rate');
});
```

- [ ] **Step 2: Run it and record the untuned rate**
- [ ] **Step 3: Tune, preferring the spec's levers in order** — potion
  frequency, then armour values, then affix magnitudes; the depth-1-2 spawn
  tables only as the explicit fallback; hero and monster base stats only with a
  before/after report. **Record every change and its measured effect** — that
  table is a required part of the verification block.
- [ ] **Step 4: Add the exploit measurement** (architect rider): a second
  test that runs the same bot with a Fleetfoot-first policy — stay bare until
  Fleetfoot reaches level 10, then wear heavy — and reports its win rate beside
  the ordinary bot's, so `m2-town` can decide whether the switch needs a rule.
- [ ] **Step 5: Run all three suites green and commit**

```bash
git add packages/content
git commit -m "test(content): a bot proves the descent survivable, and the tuning that got it there"
```

---

### Task 13: The app

**Files:**

- Create: `packages/app/lib/game/inventory_screen.dart`
- Modify: `packages/app/lib/game/event_messages.dart`
- Modify: `packages/app/lib/game/game_bloc.dart`
- Modify: `packages/app/lib/game/glyph_grid.dart`
- Modify: `packages/app/lib/game/game_screen.dart`
- Modify: `packages/app/test/game_bloc_test.dart` (the `lootRng` argument in
  `arenaGame`)

Details:

- `event_messages.dart`: a line for each of the nine new events. The switch is
  exhaustive over a sealed class, so a missing case is a compile error, not a
  silent gap.
- `glyph_grid.dart`: ground items draw their `base.glyph` under the same fog
  rules as monsters — visible tiles only — beneath the hero and monsters in
  paint order. A single distinct colour plus the glyph itself carries the
  category, so the grid reads in greyscale.
- `game_bloc.dart`: `PickUpPressed,`EquipPressed(itemId), `UnequipPressed(slot),`DrinkPressed(itemId), `DropPressed(itemId),`QuickDrinkPressed`.`GameViewState` gains `bool get canPickUp` and
  `Item? get firstPotion`. Every one routes through`_afterAction, so the log
  and the walk-cancelling rules stay in one place.
- `inventory_screen.dart`: the equipment panel (six slots, always all six, an
  empty one reading `—`), the inventory list with `rarity.marking` as a leading
  mark and the full `displayName, a derived-stat readout (attack range, armor,
  dodge percent, speed) and the four skill levels with xp bars. **No hue
  carries meaning**: rarity is the marking plus the tier word, and the xp bars
  are value contrast.
- `game_screen.dart`: a Pick up control when `canPickUp, a quick-drink button
  when a potion is held, and an Inventory button opening the screen.

- [ ] **Step 1: Write the failing bloc tests** (Task 14 lists them)
- [ ] **Step 2: Run and confirm they fail**
- [ ] **Step 3: Implement**
- [ ] **Step 4: `flutter test,`flutter analyze, `dart format` all clean**
- [ ] **Step 5: Commit**

```bash
git add packages/app
git commit -m "feat(app): inventory, equipment and skills on screen"
```

---

### Task 14: App bloc tests

**Files:**

- Modify: `packages/app/test/game_bloc_test.dart`

`blocTest` cases:

- Pick-up: an item under the hero, `PickUpPressed` → inventory holds it, the
  log says so.
- Pick-up refused when the inventory is full → the log carries the refusal and
  the hero has not moved.
- Equip from inventory → `heroAttack` on the new state is higher than before.
- Quick-drink heals and logs the amount.
- A skill level-up reaches the log.
- A dodge reaches the log.
- `canPickUp` is false with nothing underfoot and true with something.

- [ ] Steps 1–5 as the pattern above.

```bash
git add packages/app
git commit -m "test(app): loot, equipment and training reach the view"
```

---

### Task 15: Mutation table, formatting and the verification block

**Files:** none committed beyond formatting fixes and `BUILD-REPORT.md`
(uncommitted).

- [ ] **Step 1: `flutter analyze` in all three packages, three times as the
  build prompt asks; `dart format --set-exit-if-changed .` project-wide.**
- [ ] **Step 2: Run all six mutation rows, one at a time, reverting each.**
  For each row record which tests reddened *and* that the named control stayed
  green. Row 5 must redden the determinism pins, not fail to compile — mutate
  which stream `rollDrop` is handed, not its signature.
- [ ] **Step 3: Confirm `git status --porcelain` is clean of mutations.**
- [ ] **Step 4: AVD playthrough on `Pixel_10`** — launch via the `emulator`
  binary directly. Pick up, equip, watch a derived stat change, drink a potion,
  see a dodge logged, see a level-up logged, and walk 1→5.
- [ ] **Step 5: Write `BUILD-REPORT.md` and send the verification block to the
  architect with `SendMessage`.** Eleven items, each evidenced by command
  output rather than asserted, including the Fleetfoot-exploit numbers the
  architect asked for as an explicit item.

---

## Self-review

**Spec coverage.** Rarity/affix counts → Task 1. Display names → Task 2.
Equip/unequip round-trips, two-hander vs shield both directions, inventory cap,
hp clamp → Task 8. Damage floor of 1, dodge path → Task 7. All four training
triggers and the level curve → Tasks 3, 7. Stacked-affix derivations → Task 4.
Drop determinism pins → Tasks 5, 9. Turn consumption and refusal-costs-nothing
→ Task 8. lootRng contract → Tasks 6, 9, 10. Floor items from the floor's own
stream → Tasks 9, 10. Survivability simulation → Task 12. Content validation →
Task 11. App bloc tests → Task 14. Three documented behaviour arguments
(derivation-over-mutation, the lootRng split, two-hander/shield and hp-clamp) →
Tasks 4, 6, 8, plus the architect's fourth (zero-dodge stream preservation) →
Task 7. Mutation table → Task 15.

**Placeholders.** None: every number is in the numbers table, every interface
is named with its types, and the tasks with real logic carry their test code.

**Type consistency.** `Loadout,`Equipment, `heroAttack,`heroArmor, `heroDodgePercent,`heroMaxHp, `heroSpeed,`Weighted, `DropTable,`rollDrop, `rollFloorItemCount,`SkillState.trained, `untrainedSkills,`xpToNext, `inventoryCap,`dodgeCapPercent, `lootStreamSalt` are each
defined once and referred to by the same name everywhere after.

**Known gap, deliberate.** The story spec asks for `heroAttack(GameState)`-shaped
signatures; this plan uses `(Actor, Loadout)` with `GameState.loadout` as the
bridge, approved by the architect before implementation.
