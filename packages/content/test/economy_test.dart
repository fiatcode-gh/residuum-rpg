import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

/// One of every base item at every tier, which is the whole price space.
List<Item> _everything() => [
  for (final base in armory)
    for (final rarity in Rarity.values)
      Item(
        id: '${base.id}-${rarity.name}',
        base: base,
        rarity: rarity,
        affixes: [
          for (var n = 0; n < rarity.affixCount; n++)
            (base.isWeapon ? weaponAffixes : armourAffixes)[n],
        ],
      ),
];

void main() {
  group('prices', () {
    test('buying always costs more than selling gets back', () {
      // arrange
      final everything = _everything();

      // act
      final arbitrage = [
        for (final item in everything)
          if (buyPriceOf(item) <= sellPriceOf(item)) item.displayName,
      ];

      // assert
      expect(arbitrage, isEmpty);
    });

    test('every price is a positive number of coins', () {
      // arrange
      final everything = _everything();

      // act
      final prices = [
        for (final item in everything) ...[sellPriceOf(item), buyPriceOf(item)],
      ];

      // assert
      expect(prices, everyElement(greaterThan(0)));
    });

    test('a richer tier of the same base is worth more', () {
      // arrange
      const common = Item(id: 'a', base: ironSword, rarity: Rarity.common);
      const rare = Item(
        id: 'b',
        base: ironSword,
        rarity: Rarity.rare,
        affixes: [keen, vicious],
      );

      // act
      final richer = sellPriceOf(rare) > sellPriceOf(common);

      // assert
      expect(richer, isTrue);
    });

    test('a better base is worth more at the same tier', () {
      // arrange
      const plain = Item(id: 'a', base: rustySword, rarity: Rarity.common);
      const better = Item(id: 'b', base: greatsword, rarity: Rarity.common);

      // act
      final dearer = sellPriceOf(better) > sellPriceOf(plain);

      // assert
      expect(dearer, isTrue);
    });

    test('a bed costs something and does not cost a fortune', () {
      // arrange
      const price = innPrice;

      // act
      final sane = price > 0 && price < 100;

      // assert
      expect(sane, isTrue);
    });

    test('a bed costs less than the potion it competes with', () {
      // arrange
      const potion = Item(id: 'a', base: healingPotion, rarity: Rarity.common);

      // act
      final cheaper = innPrice < buyPriceOf(potion);

      // assert
      expect(cheaper, isTrue);
    });
  });

  group('merchantStock', () {
    test('is the same stock twice for one world and one visit', () {
      // arrange
      const worldSeed = 9;

      // act
      final one = merchantStock(worldSeed, 3, stonebridge);
      final other = merchantStock(worldSeed, 3, stonebridge);

      // assert
      expect(
        one.map((item) => (item.id, item.displayName)),
        other.map((item) => (item.id, item.displayName)),
      );
    });

    test('restocks between visits', () {
      // arrange
      const worldSeed = 9;

      // act
      final one = merchantStock(worldSeed, 1, stonebridge);
      final other = merchantStock(worldSeed, 2, stonebridge);

      // assert
      expect(
        one.map((item) => item.displayName).toList(),
        isNot(other.map((item) => item.displayName).toList()),
      );
    });

    test('always has potions on the shelf', () {
      // arrange
      final stocks = [
        for (var visit = 1; visit <= 12; visit++)
          merchantStock(9, visit, stonebridge),
      ];

      // act
      final potions = [
        for (final stock in stocks)
          stock.where((item) => item.base.isPotion).length,
      ];

      // assert
      expect(potions, everyElement(greaterThanOrEqualTo(stockedPotions)));
    });

    test('every item on the shelf is a real base item with its own id', () {
      // arrange
      final stock = merchantStock(9, 4, stonebridge);

      // act
      final ids = stock.map((item) => item.id).toSet();

      // assert
      expect(ids.length, stock.length);
      for (final item in stock) {
        expect(baseItemById(item.base.id), item.base);
      }
    });

    test('carries a few pieces of gear, not a warehouse', () {
      // arrange
      final counts = [
        for (var visit = 1; visit <= 20; visit++)
          merchantStock(
            9,
            visit,
            stonebridge,
          ).where((item) => !item.base.isPotion).length,
      ];

      // act
      final inRange = counts.every((count) => count >= 1 && count <= 3);

      // assert
      expect(inRange, isTrue, reason: 'gear counts were $counts');
    });

    test('two worlds stock different shelves', () {
      // act
      final one = merchantStock(1, 1, stonebridge);
      final other = merchantStock(2, 1, stonebridge);

      // assert
      expect(
        one.map((item) => item.displayName).toList(),
        isNot(other.map((item) => item.displayName).toList()),
      );
    });

    test('never stocks a tier the game does not hand out', () {
      // arrange
      final stocks = [
        for (var visit = 1; visit <= 30; visit++)
          merchantStock(3, visit, stonebridge),
      ];

      // act
      final tiers = {
        for (final stock in stocks)
          for (final item in stock) item.rarity,
      };

      // assert
      expect(tiers, isNot(contains(Rarity.legendary)));
    });

    test('the shelf is affordable to a hero who cleared one floor', () {
      // arrange
      final stock = merchantStock(9, 1, stonebridge);

      // act
      final cheapest = stock
          .map(buyPriceOf)
          .reduce((one, other) => one < other ? one : other);

      // assert
      expect(cheapest, lessThan(60));
    });
  });

  group('what a temper is worth', () {
    test('a tempered item never sells for its untempered price', () {
      // arrange
      final everything = _everything().where(
        (item) => item.base.isWeapon || item.base.isArmour,
      );

      // act
      final unmoved = [
        for (final item in everything)
          if (sellPriceOf(item.tempered(1)) == sellPriceOf(item))
            item.displayName,
      ];

      // assert - sellPriceOf reads base.* by design, so temper is the one thing
      // it would silently not see; a forge that changed nothing about a price
      // would be a laundering hole in reverse
      expect(unmoved, isEmpty);
    });

    test('a tier is worth two, which is what two of those stats cost', () {
      // arrange
      final sword = Item(id: 'drop-1', base: ironSword, rarity: Rarity.common);
      final mail = Item(id: 'drop-2', base: mailHauberk, rarity: Rarity.common);

      // act
      final swordGain = sellPriceOf(sword.tempered(1)) - sellPriceOf(sword);
      final mailGain = sellPriceOf(mail.tempered(1)) - sellPriceOf(mail);

      // assert - worth weighs attackMin and attackMax at one each and armour at
      // two, so one tier is exactly two either way: a weapon gains a point at
      // both ends, and a piece of armour gains a doubled point of armour. Any
      // other multiplier would price a temper differently from the way the same
      // stats are priced when a dungeon hands them over
      expect(swordGain, 2);
      expect(mailGain, 2);
    });

    test('the tier multiplies with the rarity, as every other stat does', () {
      // arrange
      final rare = Item(
        id: 'drop-1',
        base: ironSword,
        rarity: Rarity.rare,
        affixes: const [keen, ofEmbers],
      );

      // act
      final gain = sellPriceOf(rare.tempered(2)) - sellPriceOf(rare);

      // assert - two tiers at two apiece, through a Rare's threefold multiplier
      expect(gain, 12);
    });

    test('buying a tempered piece still costs twice selling it', () {
      // arrange
      final everything = _everything();

      // act
      final arbitrage = [
        for (final item in everything)
          for (var tier = 1; tier <= 3; tier++)
            if (buyPriceOf(item.tempered(tier)) !=
                sellPriceOf(item.tempered(tier)) * 2)
              item.displayName,
      ];

      // assert
      expect(arbitrage, isEmpty);
    });

    test('a potion and a book are worth no more for being worked', () {
      // arrange
      final potion = Item(
        id: 'drop-1',
        base: healingPotion,
        rarity: Rarity.common,
      );
      final book = Item(
        id: 'drop-2',
        base: bookOfFirebolt,
        rarity: Rarity.common,
      );

      // act
      // assert - only steel takes a temper, and the price has to agree with the
      // refusal rather than quietly disagree with it
      expect(sellPriceOf(potion.tempered(3)), sellPriceOf(potion));
      expect(sellPriceOf(book.tempered(3)), sellPriceOf(book));
    });
  });

  group('the shelf and materials', () {
    test('the merchant deals in no material at all', () {
      // arrange
      final words = {for (final id in MaterialId.values) id.name};

      // act
      final sold = {
        for (final weighted in marketTable.items) weighted.value.id,
      };

      // assert - materials are counters and never items, so there is nothing
      // here for a shelf to carry; pinned because the day one is added is the
      // day the shelf golden has to be re-pinned knowingly
      expect(sold.intersection(words), isEmpty);
    });

    test('nothing in the armory is a material either', () {
      // arrange
      final words = {for (final id in MaterialId.values) id.name};

      // act
      final bases = {for (final base in armory) base.id};

      // assert
      expect(bases.intersection(words), isEmpty);
    });
  });
}
