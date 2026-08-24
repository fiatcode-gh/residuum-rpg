import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import 'support/small_world.dart';

/// A pool with one rumor for each place a hero could be told about.
List<Rumor> _pool() => [
  Rumor(line: 'They say a ridge town trades to the north.', reveals: ridge),
  Rumor(
    line: 'They say the crypt has a door that still opens.',
    reveals: crypt,
  ),
];

Profile _withGold(int gold) => Profile(
  hero: const Actor(
    id: 'hero',
    name: 'you',
    glyph: '@',
    position: Position(0, 0),
    hp: 20,
    maxHp: 20,
    attackMin: 1,
    attackMax: 2,
    speed: 10,
    energy: 100,
  ),
  worldSeed: 1,
  gold: gold,
);

void main() {
  group('buying a rumor', () {
    test('the hero is told of somewhere they had not heard of', () {
      // arrange
      final profile = _withGold(50);
      final where = atHome();

      // act
      final told = buyRumor(profile, where, _pool(), 10);

      // assert
      expect(told.rumor!.reveals, ridge);
      expect(told.whereabouts.discovered, contains(ridge));
      expect(told.refusal, isNull);
    });

    test('it costs what the tavern charges', () {
      // arrange
      final profile = _withGold(50);

      // act
      final told = buyRumor(profile, atHome(), _pool(), 10);

      // assert
      expect(told.profile.gold, 40);
    });

    test('a rumor never names a place the hero already knows', () {
      // arrange
      final profile = _withGold(50);
      final where = atHome();

      // act
      final told = buyRumor(profile, where, _pool(), 10);

      // assert
      expect(where.discovered, contains(crypt));
      expect(told.rumor!.reveals, isNot(crypt));
    });

    test('walking somewhere leaves the tavern something to sell', () {
      // arrange
      final profile = _withGold(50);
      final where = atHome().arrivingAt(smallWorld(), crypt);

      // act
      final told = buyRumor(profile, where, _pool(), 10);

      // assert
      expect(told.rumor!.reveals, ridge);
    });

    test('a tavern with nothing left to tell charges nothing', () {
      // arrange
      final profile = _withGold(50);
      final where = atHome().hearingOf(ridge);

      // act
      final told = buyRumor(profile, where, _pool(), 10);

      // assert
      expect(told.rumor, isNull);
      expect(told.profile.gold, 50);
      expect(told.whereabouts, where);
      expect(told.refusal, isNull);
    });

    test('a purse that cannot cover it buys nothing and says why', () {
      // arrange
      final profile = _withGold(3);
      final where = atHome();

      // act
      final told = buyRumor(profile, where, _pool(), 10);

      // assert
      expect(told.refusal!.reason, 'you cannot afford that');
      expect(told.profile.gold, 3);
      expect(told.whereabouts, where);
      expect(told.rumor, isNull);
    });

    test('a broke hero with nothing to learn is told so, not charged at', () {
      // arrange
      final profile = _withGold(0);
      final where = atHome().hearingOf(ridge);

      // act
      final told = buyRumor(profile, where, _pool(), 10);

      // assert
      expect(told.rumor, isNull);
      expect(told.refusal, isNull);
    });

    test('an empty pool tells nothing rather than throwing', () {
      // arrange
      final profile = _withGold(50);

      // act
      final told = buyRumor(profile, atHome(), const [], 10);

      // assert
      expect(told.rumor, isNull);
      expect(told.profile.gold, 50);
    });

    test('the pool decides the order the world is uncovered in', () {
      // arrange
      final profile = _withGold(50);
      final where = Whereabouts(
        at: harbour,
        home: harbour,
        discovered: {harbour},
      );

      // act
      final told = buyRumor(profile, where, _pool(), 10);

      // assert
      expect(told.rumor!.reveals, ridge);
    });

    test('buying twice uncovers the second place as well', () {
      // arrange
      final profile = _withGold(50);
      final where = Whereabouts(
        at: harbour,
        home: harbour,
        discovered: {harbour},
      );

      // act
      final first = buyRumor(profile, where, _pool(), 10);
      final second = buyRumor(first.profile, first.whereabouts, _pool(), 10);

      // assert
      expect(second.rumor!.reveals, crypt);
      expect(second.whereabouts.discovered, {harbour, ridge, crypt});
      expect(second.profile.gold, 30);
    });

    test('what the hero is told is a sentence, not an id', () {
      // arrange
      final profile = _withGold(50);

      // act
      final told = buyRumor(profile, atHome(), _pool(), 10);

      // assert
      expect(told.rumor!.line, 'They say a ridge town trades to the north.');
    });
  });
}
