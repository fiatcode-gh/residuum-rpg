import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

/// Remove-one at the town half: an id-based removal takes exactly one item —
/// the first match in the list's order — and the sibling survives with its id.
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
}) => Profile(
  hero: hero(const Position(0, 0)),
  worldSeed: 1,
  gold: gold,
  inventory: inventory,
  bank: bank,
  equipment: equipment,
);

int _held(List<Item> items, String id) =>
    items.where((item) => item.id == id).length;

void main() {
  group('remove-one at the town half', () {
    test('selling a duplicate id takes exactly one, the sibling survives', () {
      // arrange
      final profile = _townie(inventory: [_twin(_potion), _twin(_potion)]);

      // act
      final (after, refusal) = sellItem(profile, 'drop-1', 9);

      // assert
      expect(refusal, isNull);
      expect(_held(after.inventory, 'drop-1'), 1);
      expect(after.gold, 9, reason: 'one item sold, one price taken');
    });

    test('depositing a duplicate id moves exactly one into the vault', () {
      // arrange
      final profile = _townie(inventory: [_twin(_potion), _twin(_potion)]);

      // act
      final (after, refusal) = depositItem(profile, 'drop-1');

      // assert
      expect(refusal, isNull);
      expect(_held(after.inventory, 'drop-1'), 1);
      expect(_held(after.bank, 'drop-1'), 1);
    });

    test('withdrawing a duplicate id moves exactly one out of the vault', () {
      // arrange
      final profile = _townie(bank: [_twin(_potion), _twin(_potion)]);

      // act
      final (after, refusal) = withdrawItem(profile, 'drop-1');

      // assert
      expect(refusal, isNull);
      expect(_held(after.bank, 'drop-1'), 1);
      expect(_held(after.inventory, 'drop-1'), 1);
    });

    test('reading a duplicate id consumes exactly one book', () {
      // arrange
      final profile = _townie(inventory: [_twin(_book), _twin(_book)]);

      // act
      final (after, refusal) = readBook(profile, 'drop-1', const {
        'firebolt': _firebolt,
      });

      // assert
      expect(refusal, isNull);
      expect(_held(after.inventory, 'drop-1'), 1);
      expect(after.knownSpells, contains('firebolt'));
    });

    test('tempering works the first carried match only', () {
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
      expect(after.inventory.first.temper, 1, reason: 'the first match worked');
      expect(after.inventory.last.temper, 0, reason: 'the sibling untouched');
    });

    test('tempering a worn piece works the worn piece', () {
      // arrange
      final profile = _townie(
        equipment: {EquipSlot.head: _twin(_cap)},
        gold: 100,
      );
      final ingots = temperPriceFrom(_twin(_cap).temper).ingots;

      // act
      final (after, refusal) = temperItem(
        profile.copyWith(materials: {MaterialId.ingot: ingots}),
        'drop-1',
      );

      // assert
      expect(refusal, isNull);
      expect(after.equipment[EquipSlot.head]!.temper, 1);
    });

    test('a worn piece and a carried twin: the carried one is named first', () {
      // arrange
      final profile = _townie(
        equipment: {EquipSlot.head: _twin(_cap)},
        gold: 100,
      ).copyWith(inventory: [_twin(_cap)]);
      final ingots = temperPriceFrom(_twin(_cap).temper).ingots;

      // act
      final (after, refusal) = temperItem(
        profile.copyWith(materials: {MaterialId.ingot: ingots}),
        'drop-1',
      );

      // assert
      expect(refusal, isNull);
      expect(
        after.inventory.single.temper,
        1,
        reason: 'heldItem reads the pack before the worn slots',
      );
      expect(
        after.equipment[EquipSlot.head]!.temper,
        0,
        reason: 'one hammer blow works one piece',
      );
    });
  });
}
