import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

/// Remove-one: an id-based removal takes exactly one item — the first match
/// in the list's order — and the sibling survives with its id.
const _room = '''
#######
#.....#
#.....#
#######''';

const _potion = BaseItem(
  id: 'healing-potion',
  name: 'Healing Potion',
  glyph: '!',
  heal: 8,
);

const _book = BaseItem(
  id: 'spellbook',
  name: 'Spellbook',
  glyph: '?',
  teaches: 'firebolt',
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

const _here = Position(3, 1);

Item _twin(BaseItem base) =>
    Item(id: 'drop-1', base: base, rarity: Rarity.common);

GameState _crawl({
  List<Item> inventory = const [],
  Map<Position, List<Item>> groundItems = const {},
  Map<String, Spell> spells = const {},
}) => crawl(
  ascii: _room,
  heroAt: _here,
  heroHp: 10,
  inventory: inventory,
  groundItems: groundItems,
  spells: spells,
);

int _held(List<Item> items, String id) =>
    items.where((item) => item.id == id).length;

void main() {
  group('remove-one at the dungeon half', () {
    test('drinking a duplicate id takes exactly one, the sibling survives', () {
      // arrange
      final game = _crawl(inventory: [_twin(_potion), _twin(_potion)]);

      // act
      final (after, _) = step(game, const DrinkAction('drop-1'));

      // assert
      expect(_held(after.inventory, 'drop-1'), 1);
    });

    test('reading a duplicate id takes exactly one, the sibling survives', () {
      // arrange
      final game = _crawl(
        inventory: [_twin(_book), _twin(_book)],
        spells: const {'firebolt': _firebolt},
      );

      // act
      final (after, _) = step(game, const ReadAction('drop-1'));

      // assert
      expect(_held(after.inventory, 'drop-1'), 1);
      expect(after.knownSpells, contains('firebolt'));
    });

    test('dropping removes the first match only, and drops that one', () {
      // arrange
      final game = _crawl(inventory: [_twin(_sword), _twin(_sword)]);

      // act
      final (after, events) = step(game, const DropAction('drop-1'));

      // assert
      expect(_held(after.inventory, 'drop-1'), 1);
      expect(events.whereType<ItemDropped>().single.item, _twin(_sword));
      expect(after.groundItems[_here]!.single.id, 'drop-1');
    });
  });
}
