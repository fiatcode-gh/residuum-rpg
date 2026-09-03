import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

/// What duplicate ids do to the town half today, pinned before m3-itemids
/// changes it.
///
/// Every test here states CURRENT behaviour on a hand-built duplicate-id pack.
/// The unit flips `_without` and `temperItem` to first-match-only; these tests
/// are the record of what that flip walks away from.
const _potion = BaseItem(
  id: 'healing-potion',
  name: 'Healing Potion',
  glyph: '!',
  heal: 8,
);

const _cap = BaseItem(
  id: 'leather-cap',
  name: 'Leather Cap',
  glyph: '[',
  slot: EquipSlot.head,
  armor: 1,
);

const _book = BaseItem(
  id: 'spellbook',
  name: 'Spellbook',
  glyph: '?',
  teaches: 'firebolt',
);

const _firebolt = Spell(
  id: 'firebolt',
  name: 'Firebolt',
  school: SkillId.wrath,
  manaCost: 2,
  requiredLevel: 0,
  kind: SpellKind.bolt,
  type: DamageType.fire,
  min: 2,
  max: 4,
);

Item _twin(BaseItem base) =>
    Item(id: 'drop-1', base: base, rarity: Rarity.common);

Profile _townie({
  int gold = 0,
  List<Item> inventory = const [],
  List<Item> bank = const [],
  Equipment equipment = const {},
  Set<String> knownSpells = const {},
}) => Profile(
  hero: hero(const Position(0, 0)),
  worldSeed: 1,
  gold: gold,
  inventory: inventory,
  bank: bank,
  equipment: equipment,
  knownSpells: knownSpells,
);

int _held(List<Item> items, String id) =>
    items.where((item) => item.id == id).length;

void main() {
  group('characterization: selling a duplicate id', () {
    test('sells every match out of the pack', () {
      // arrange
      final profile = _townie(inventory: [_twin(_potion), _twin(_potion)]);

      // act
      final (after, refusal) = sellItem(profile, 'drop-1', 9);

      // assert
      expect(refusal, isNull);
      expect(
        _held(after.inventory, 'drop-1'),
        0,
        reason: 'current behaviour: one sale takes every match',
      );
    });

    test('prices the sale off the first match', () {
      // arrange
      final profile = _townie(inventory: [_twin(_potion), _twin(_potion)]);

      // act
      final (after, refusal) = sellItem(profile, 'drop-1', 9);

      // assert
      expect(refusal, isNull);
      expect(
        after.gold,
        9,
        reason: 'current behaviour: one price, every match',
      );
    });
  });

  group('characterization: depositing a duplicate id', () {
    test('moves every match into the vault', () {
      // arrange
      final profile = _townie(inventory: [_twin(_potion), _twin(_potion)]);

      // act
      final (after, refusal) = depositItem(profile, 'drop-1');

      // assert
      expect(refusal, isNull);
      expect(
        _held(after.inventory, 'drop-1'),
        0,
        reason: 'current behaviour: one deposit takes every match',
      );
    });
  });

  group('characterization: withdrawing a duplicate id', () {
    test('moves every match out of the vault', () {
      // arrange
      final profile = _townie(bank: [_twin(_potion), _twin(_potion)]);

      // act
      final (after, refusal) = withdrawItem(profile, 'drop-1');

      // assert
      expect(refusal, isNull);
      expect(
        _held(after.bank, 'drop-1'),
        0,
        reason: 'current behaviour: one withdrawal takes every match',
      );
    });
  });

  group('characterization: reading a duplicate id in town', () {
    test('consumes every book and learns the spell once', () {
      // arrange
      final profile = _townie(inventory: [_twin(_book), _twin(_book)]);

      // act
      final (after, refusal) = readBook(profile, 'drop-1', const {
        'firebolt': _firebolt,
      });

      // assert
      expect(refusal, isNull);
      expect(
        _held(after.inventory, 'drop-1'),
        0,
        reason: 'current behaviour: one read takes every match',
      );
      expect(after.knownSpells, contains('firebolt'));
    });
  });

  group('characterization: tempering a duplicate id', () {
    test('works every carried match up one tier', () {
      // arrange
      final profile = _townie(inventory: [_twin(_cap), _twin(_cap)], gold: 100);
      final ingots = temperPriceFrom(_twin(_cap).temper).ingots;

      // act
      final (after, refusal) = temperItem(
        profile.copyWith(materials: {MaterialId.ingot: ingots}),
        'drop-1',
      );

      // assert
      expect(refusal, isNull);
      expect(
        after.inventory
            .where((item) => item.id == 'drop-1')
            .map((i) => i.temper),
        everyElement(1),
        reason: 'current behaviour: one temper works every match',
      );
    });

    test('works every worn match up one tier', () {
      // arrange
      final twin = _twin(_cap);
      final profile = _townie(
        equipment: {EquipSlot.head: twin},
        gold: 100,
      ).copyWith(inventory: [_twin(_cap)]);
      final ingots = temperPriceFrom(twin.temper).ingots;

      // act
      final (after, refusal) = temperItem(
        profile.copyWith(materials: {MaterialId.ingot: ingots}),
        'drop-1',
      );

      // assert
      expect(refusal, isNull);
      expect(after.equipment[EquipSlot.head]!.temper, 1);
      expect(
        after.inventory.first.temper,
        1,
        reason: 'current behaviour: the carried twin is worked too',
      );
    });
  });
}
