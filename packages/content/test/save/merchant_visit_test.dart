import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

Item _gear(String id) => Item(id: id, base: ironSword, rarity: Rarity.common);

void main() {
  group('what the merchant remembers of a visit', () {
    test('a fresh visit remembers nothing', () {
      // arrange
      const visit = MerchantVisit.none;

      // act
      final shelf = visit.stillOnTheShelf([_gear('a'), _gear('b')]);

      // assert
      expect(visit.bought, isEmpty);
      expect(visit.sold, isEmpty);
      expect(shelf.map((item) => item.id), ['a', 'b']);
    });

    test('what was bought is off the shelf', () {
      // arrange
      const visit = MerchantVisit(bought: ['b']);

      // act
      final shelf = visit.stillOnTheShelf([_gear('a'), _gear('b')]);

      // assert
      expect(shelf.map((item) => item.id), ['a']);
    });

    test('a bought id that is not on this shelf takes nothing off it', () {
      // arrange
      const visit = MerchantVisit(bought: ['market-9-gear-1']);

      // act
      final shelf = visit.stillOnTheShelf([_gear('a'), _gear('b')]);

      // assert
      expect(shelf.map((item) => item.id), ['a', 'b']);
    });

    test('buying and selling append, and buying back removes', () {
      // arrange
      const visit = MerchantVisit.none;

      // act
      final after = visit
          .withBought('a')
          .withSold(_gear('kept'))
          .withSold(_gear('taken'))
          .withoutSold('taken');

      // assert
      expect(after.bought, ['a']);
      expect(after.sold.map((item) => item.id), ['kept']);
    });

    test('two visits with the same lists are the same value', () {
      // arrange
      final one = MerchantVisit.none.withSold(_gear('a')).withBought('b');
      final other = MerchantVisit.none.withSold(_gear('a')).withBought('b');

      // act
      final same = one == other;

      // assert
      expect(same, isTrue);
      expect(one, isNot(MerchantVisit.none));
    });
  });
}
