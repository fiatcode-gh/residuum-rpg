import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/item_presentation.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

const _sword = BaseItem(
  id: 'iron-sword',
  name: 'Iron Sword',
  glyph: ')',
  slot: EquipSlot.mainHand,
  hands: WeaponHands.one,
  attackMin: 3,
  attackMax: 5,
);

const _club = BaseItem(
  id: 'club',
  name: 'Club',
  glyph: ')',
  slot: EquipSlot.mainHand,
  hands: WeaponHands.one,
  attackMin: 2,
  attackMax: 2,
);

const _shield = BaseItem(
  id: 'kite-shield',
  name: 'Kite Shield',
  glyph: '[',
  slot: EquipSlot.offHand,
  armor: 2,
  heavy: true,
);

const _cap = BaseItem(
  id: 'leather-cap',
  name: 'Leather Cap',
  glyph: '[',
  slot: EquipSlot.head,
  armor: 1,
);

const _boots = BaseItem(
  id: 'boots',
  name: 'Boots',
  glyph: '[',
  slot: EquipSlot.feet,
  armor: 1,
);

const _potion = BaseItem(
  id: 'healing-potion',
  name: 'Healing Potion',
  glyph: '!',
  heal: 8,
);

const _vigour = Affix(
  id: 'of-vigour',
  affixName: 'of Vigour',
  isPrefix: false,
  maxHp: 4,
);

const _swift = Affix(id: 'swift', affixName: 'Swift', isPrefix: true, speed: 1);

const _keen = Affix(
  id: 'keen',
  affixName: 'Keen',
  isPrefix: true,
  attackMin: 1,
  attackMax: 1,
);

Item _item(String id, BaseItem base, {List<Affix> affixes = const []}) => Item(
  id: id,
  base: base,
  rarity: Rarity.values[affixes.length],
  affixes: affixes,
);

void main() {
  group('statLine', () {
    test('reads a weapon as its damage range', () {
      // arrange
      final sword = _item('kit-1', _sword);

      // act
      final line = statLine(sword);

      // assert
      expect(line, '+3-5 atk');
    });

    test('collapses a range whose ends are equal to one number', () {
      // arrange
      final club = _item('kit-1', _club);

      // act
      final line = statLine(club);

      // assert
      expect(line, '+2 atk');
    });

    test('keeps only the parts that are not zero', () {
      // arrange
      final shield = _item('kit-1', _shield);

      // act
      final line = statLine(shield);

      // assert
      expect(line, '+2 arm');
    });

    test('joins several parts in a fixed order', () {
      // arrange
      final sword = _item('kit-1', _sword, affixes: [_vigour, _swift]);

      // act
      final line = statLine(sword);

      // assert
      expect(line, '+3-5 atk · +4 hp · +1 spd');
    });

    test('reads a potion as what it restores', () {
      // arrange
      final potion = _item('kit-1', _potion);

      // act
      final line = statLine(potion);

      // assert
      expect(line, '+8 heal');
    });

    test('says nothing about an item with nothing to say', () {
      // arrange
      const nothing = BaseItem(id: 'rag', name: 'Rag', glyph: '[');
      final rag = _item('kit-1', nothing);

      // act
      final line = statLine(rag);

      // assert
      expect(line, '');
    });

    test('counts the affixes into the damage range', () {
      // arrange
      final sword = _item('kit-1', _sword, affixes: [_keen]);

      // act
      final line = statLine(sword);

      // assert
      expect(line, '+4-6 atk');
    });
  });

  group('stackKey', () {
    test('two items of the same make and tier share a key', () {
      // arrange
      final one = _item('kit-1', _potion);
      final other = _item('floor-2-7', _potion);

      // act
      final keys = (stackKey(one), stackKey(other));

      // assert
      expect(keys.$1, keys.$2);
    });

    test('a different base does not share a key', () {
      // act
      final keys = (
        stackKey(_item('kit-1', _potion)),
        stackKey(_item('kit-2', _sword)),
      );

      // assert
      expect(keys.$1, isNot(keys.$2));
    });

    test('a different tier does not share a key', () {
      // arrange
      final common = _item('kit-1', _sword);
      final fine = _item('kit-2', _sword, affixes: [_keen]);

      // act
      final keys = (stackKey(common), stackKey(fine));

      // assert
      expect(keys.$1, isNot(keys.$2));
    });

    test('a different affix list does not share a key', () {
      // arrange
      final keen = _item('kit-1', _sword, affixes: [_keen]);
      final swift = _item('kit-2', _sword, affixes: [_swift]);

      // act
      final keys = (stackKey(keen), stackKey(swift));

      // assert
      expect(keys.$1, isNot(keys.$2));
    });
  });

  group('ItemStack', () {
    test('names a single item without a count', () {
      // arrange
      final stack = ItemStack(_item('kit-1', _potion), 1);

      // act
      final label = stack.label;

      // assert
      expect(label, 'Common Healing Potion');
    });

    test('names several alike with a count', () {
      // arrange
      final stack = ItemStack(_item('kit-1', _potion), 3);

      // act
      final label = stack.label;

      // assert
      expect(label, 'Common Healing Potion ×3');
    });
  });

  group('packSections', () {
    test('offers all three sections even when the pack is empty', () {
      // act
      final sections = packSections(const []);

      // assert
      expect(sections.keys, PackSection.values);
      expect(sections.values.every((rows) => rows.isEmpty), isTrue);
    });

    test('sends each item to the section it belongs in', () {
      // arrange
      final pack = [
        _item('kit-1', _potion),
        _item('kit-2', _sword),
        _item('kit-3', _shield),
      ];

      // act
      final sections = packSections(pack);

      // assert
      expect(sections[PackSection.weapons]!.single.item.id, 'kit-2');
      expect(sections[PackSection.armour]!.single.item.id, 'kit-3');
      expect(sections[PackSection.potions]!.single.item.id, 'kit-1');
    });

    test('orders armour by the slot it goes in', () {
      // arrange
      final pack = [
        _item('kit-1', _boots),
        _item('kit-2', _cap),
        _item('kit-3', _shield),
      ];

      // act
      final rows = packSections(pack)[PackSection.armour]!;

      // assert
      expect(rows.map((row) => row.item.id), ['kit-3', 'kit-2', 'kit-1']);
    });

    test('puts the better tier first inside one slot', () {
      // arrange
      final pack = [
        _item('kit-1', _sword),
        _item('kit-2', _sword, affixes: [_keen, _swift]),
        _item('kit-3', _sword, affixes: [_keen]),
      ];

      // act
      final rows = packSections(pack)[PackSection.weapons]!;

      // assert
      expect(rows.map((row) => row.item.id), ['kit-2', 'kit-3', 'kit-1']);
    });

    test('falls back to the name when slot and tier tie', () {
      // arrange
      final pack = [_item('kit-1', _sword), _item('kit-2', _club)];

      // act
      final rows = packSections(pack)[PackSection.weapons]!;

      // assert
      expect(rows.map((row) => row.item.displayName), [
        'Common Club',
        'Common Iron Sword',
      ]);
    });

    test('gathers items that are alike into one row with a count', () {
      // arrange
      final pack = [
        _item('kit-1', _potion),
        _item('kit-2', _potion),
        _item('kit-3', _potion),
      ];

      // act
      final rows = packSections(pack)[PackSection.potions]!;

      // assert
      expect(rows, hasLength(1));
      expect(rows.single.count, 3);
      expect(rows.single.label, 'Common Healing Potion ×3');
    });

    test('keeps items that only differ by affix in rows of their own', () {
      // arrange
      final pack = [
        _item('kit-1', _sword, affixes: [_keen]),
        _item('kit-2', _sword, affixes: [_swift]),
      ];

      // act
      final rows = packSections(pack)[PackSection.weapons]!;

      // assert
      expect(rows, hasLength(2));
      expect(rows.every((row) => row.count == 1), isTrue);
    });

    test('a stack acts through one item of itself', () {
      // arrange
      final pack = [_item('kit-1', _potion), _item('kit-2', _potion)];

      // act
      final rows = packSections(pack)[PackSection.potions]!;

      // assert
      expect(rows.single.item.id, 'kit-1');
    });
  });

  group('wornDeltas', () {
    test('reads an empty slot as a comparison against nothing', () {
      // arrange
      final shield = _item('kit-1', _shield);

      // act
      final deltas = wornDeltas(shield, null);

      // assert
      expect(deltas.map((delta) => delta.text), ['▲+2 arm']);
    });

    test('marks a better piece with a rising arrow', () {
      // arrange
      final worn = _item('kit-0', _cap);
      final better = _item('kit-1', _shield);

      // act
      final deltas = wornDeltas(better, worn);

      // assert
      expect(deltas.map((delta) => delta.text), ['▲+1 arm']);
    });

    test('marks a worse piece with a falling arrow', () {
      // arrange
      final worn = _item('kit-0', _shield);
      final worse = _item('kit-1', _cap);

      // act
      final deltas = wornDeltas(worse, worn);

      // assert
      expect(deltas.map((delta) => delta.text), ['▼-1 arm']);
    });

    test('says both halves of a mixed trade', () {
      // arrange
      final worn = _item('kit-0', _cap, affixes: [_vigour]);
      final trade = _item('kit-1', _shield);

      // act
      final deltas = wornDeltas(trade, worn);

      // assert
      expect(deltas.map((delta) => delta.text), ['▲+1 arm', '▼-4 hp']);
    });

    test('says nothing at all about an identical piece', () {
      // arrange
      final worn = _item('kit-0', _cap);
      final same = _item('kit-1', _cap);

      // act
      final deltas = wornDeltas(same, worn);

      // assert
      expect(deltas, isEmpty);
    });

    test('collapses an attack change that moves both ends alike', () {
      // arrange
      final worn = _item('kit-0', _sword);
      final keen = _item('kit-1', _sword, affixes: [_keen]);

      // act
      final deltas = wornDeltas(keen, worn);

      // assert
      expect(deltas.map((delta) => delta.text), ['▲+1 atk']);
    });

    test('splits an attack change whose ends move differently', () {
      // arrange
      final worn = _item('kit-0', _club);
      final sword = _item('kit-1', _sword);

      // act
      final deltas = wornDeltas(sword, worn);

      // assert
      expect(deltas.map((delta) => delta.text), ['▲+1 atk min', '▲+3 atk max']);
    });
  });

  group('deltaLine', () {
    test('says a piece is no change at all in words', () {
      // act
      final line = deltaLine(const []);

      // assert
      expect(line, 'same as worn');
    });

    test('joins the markers it was given', () {
      // arrange
      final deltas = wornDeltas(
        _item('kit-1', _shield),
        _item('kit-0', _cap, affixes: [_vigour]),
      );

      // act
      final line = deltaLine(deltas);

      // assert
      expect(line, '▲+1 arm · ▼-4 hp');
    });
  });

  group('the Books section', () {
    Item book(String id, BaseItem base) =>
        Item(id: id, base: base, rarity: Rarity.common);

    test('a spell book is read in Books, never in Potions', () {
      // arrange
      final pack = [book('kit-4', bookOfFirebolt)];

      // act
      final sections = packSections(pack);

      // assert - the fall-through used to file every unknown kind as a drink,
      // which would have offered the player a Drink button on a book
      expect(sections[PackSection.books], hasLength(1));
      expect(sections[PackSection.potions], isEmpty);
    });

    test('the four sections are always present, in their fixed order', () {
      // arrange
      // act
      final sections = packSections(const []);

      // assert - position is information the player relies on, so an empty
      // section keeps its place rather than closing the gap
      expect(sections.keys, [
        PackSection.weapons,
        PackSection.armour,
        PackSection.potions,
        PackSection.books,
      ]);
      expect(sections.values, everyElement(isEmpty));
    });

    test('two copies of one book stack into a single row', () {
      // arrange
      final pack = [
        book('kit-4', bookOfFirebolt),
        book('kit-5', bookOfFirebolt),
      ];

      // act
      final rows = packSections(pack)[PackSection.books]!;

      // assert
      expect(rows, hasLength(1));
      expect(rows.single.count, 2);
      expect(rows.single.label, contains('2'));
    });

    test('two different books are two rows', () {
      // arrange
      final pack = [book('kit-4', bookOfFirebolt), book('kit-5', bookOfMend)];

      // act
      final rows = packSections(pack)[PackSection.books]!;

      // assert
      expect(rows, hasLength(2));
    });

    test('a book has no stat line to show, and says nothing rather than 0', () {
      // arrange
      final page = book('kit-4', bookOfFirebolt);

      // act
      final line = statLine(page);

      // assert
      expect(line, isEmpty);
    });
  });

  group('a tempered item on the screen', () {
    test('the stat line says the word, the mark and the number', () {
      // arrange
      final sword = _item('kit-1', _sword).tempered(2);

      // act
      final line = statLine(sword);

      // assert - the damage has already moved, and the temper says why
      expect(line, '+5-7 atk · ‡+2 temper');
    });

    test('an untempered item says nothing about temper at all', () {
      // arrange
      final sword = _item('kit-1', _sword);

      // act
      final line = statLine(sword);

      // assert
      expect(line, isNot(contains('temper')));
    });

    test('the mark is not a rarity mark or a delta arrow', () {
      // arrange
      final marks = {
        for (final rarity in Rarity.values) rarity.marking,
        '▲',
        '▼',
      };

      // act
      final line = statLine(_item('kit-1', _sword).tempered(1));
      final mark = line.substring(line.length - '‡+1 temper'.length)[0];

      // assert - the rarity column already spends `+` and `++`, so a naked plus
      // here would be two categories wearing one shape
      expect(marks, isNot(contains(mark)));
      expect(mark, '‡');
    });

    test('a tempered piece of armour reads as armour', () {
      // arrange
      final shield = _item('kit-1', _shield).tempered(1);

      // act
      final line = statLine(shield);

      // assert
      expect(line, '+3 arm · ‡+1 temper');
    });

    test('two tempers of one sword are two rows, not one', () {
      // act
      final keys = (
        stackKey(_item('kit-1', _sword)),
        stackKey(_item('kit-2', _sword).tempered(2)),
      );

      // assert - a merged row would offer one action for two different swords
      // and reach whichever of them happened to come first
      expect(keys.$1, isNot(keys.$2));
    });

    test('two swords worked to the same tier still share a row', () {
      // act
      final keys = (
        stackKey(_item('kit-1', _sword).tempered(2)),
        stackKey(_item('kit-2', _sword).tempered(2)),
      );

      // assert
      expect(keys.$1, keys.$2);
    });

    test('the worn deltas count the temper the player is about to gain', () {
      // arrange
      final worn = _item('kit-1', _sword);
      final worked = _item('drop-3', _sword).tempered(2);

      // act
      final deltas = wornDeltas(worked, worn);

      // assert - both ends moved by the same amount, so it reads as one entry
      expect(deltas.map((delta) => delta.text), ['▲+2 atk']);
    });

    test('the worn deltas count a temper the player is about to give up', () {
      // arrange
      final worn = _item('kit-1', _shield).tempered(3);
      final plain = _item('drop-3', _shield);

      // act
      final deltas = wornDeltas(plain, worn);

      // assert
      expect(deltas.map((delta) => delta.text), ['▼-3 arm']);
    });
  });
}
