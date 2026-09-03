import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

/// What a duplicate id does at the dungeon half, after the m3-itemids flip.
///
/// These tests were written first as characterization against unmodified
/// `a567c19` — where one tap took EVERY match, and where they passed — then
/// flipped with the change. The pre-flip reds are on the record: run against
/// `a567c19`, every remove-one assertion here failed, which is what proved the
/// defect and proved the fix bites. The mint's own record lives in
/// [item_mint_test.dart]; this file keeps the removal contract.
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

Item _twin(BaseItem base) =>
    Item(id: 'drop-1', base: base, rarity: Rarity.common);

const _here = Position(3, 1);

/// A crawl holding two items that share one id — the shape an un-migrated
/// legacy save can still arrive in. Nothing the game mints any more.
GameState _duplicated({
  List<Item> inventory = const [],
  int heroHp = 20,
  Map<Position, List<Item>> groundItems = const {},
  Map<String, Spell> spells = const {},
}) => crawl(
  ascii: _room,
  heroAt: _here,
  heroHp: heroHp,
  inventory: inventory,
  groundItems: groundItems,
  spells: spells,
);

int _held(List<Item> inventory, String id) =>
    inventory.where((item) => item.id == id).length;

void main() {
  group('drinking a duplicate id takes exactly one', () {
    test('the first twin is drunk, the sibling survives', () {
      // arrange
      final first = _twin(_potion);
      final second = _twin(_potion);
      final game = _duplicated(inventory: [first, second], heroHp: 10);

      // act
      final (after, events) = step(game, const DrinkAction('drop-1'));

      // assert
      expect(_held(after.inventory, 'drop-1'), 1);
      expect(events.whereType<PotionDrunk>().single.item, first);
      expect(after.hero.hp, 18);
    });
  });

  group('reading a duplicate id takes exactly one', () {
    test('the first twin is read, the sibling survives', () {
      // arrange
      final first = _twin(_book);
      final second = _twin(_book);
      final game = _duplicated(
        inventory: [first, second],
        spells: const {'firebolt': _firebolt},
      );

      // act
      final (after, events) = step(game, const ReadAction('drop-1'));

      // assert
      expect(_held(after.inventory, 'drop-1'), 1);
      expect(events.whereType<SpellLearned>().single.book, first);
      expect(after.knownSpells, contains('firebolt'));
    });
  });

  group('dropping a duplicate id takes exactly one', () {
    test('the first match is the one put down, the sibling survives', () {
      // arrange
      final first = _twin(_sword);
      final second = _twin(_sword);
      final game = _duplicated(inventory: [first, second]);

      // act
      final (after, events) = step(game, const DropAction('drop-1'));

      // assert
      expect(_held(after.inventory, 'drop-1'), 1);
      expect(events.whereType<ItemDropped>().single.item, first);
      expect(after.groundItems[_here]!.single, first);
    });
  });

  group('pickup re-ids at the pack door (the m3-itemids flip)', () {
    test('the taken item leaves its litter id on the ground', () {
      // arrange
      final litter = Item(
        id: 'floor-3-2',
        base: _potion,
        rarity: Rarity.common,
      );
      final game = _duplicated(
        groundItems: {
          _here: [litter],
        },
      );

      // act
      final (after, events) = step(game, const PickUpAction());

      // assert
      expect(events.whereType<ItemPickedUp>().single.item.id, 'item-1');
      expect(after.inventory.single.id, 'item-1');
      expect(after.groundItems[_here], isNull);
    });
  });
}
