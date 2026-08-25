import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

const _cap = BaseItem(
  id: 'leather-cap',
  name: 'Leather Cap',
  glyph: '[',
  slot: EquipSlot.head,
  armor: 1,
);

const _vigour = Affix(
  id: 'of-vigour',
  affixName: 'of Vigour',
  isPrefix: false,
  maxHp: 6,
);

Profile _townie() => Profile(hero: hero(const Position(0, 0)), worldSeed: 1);

void main() {
  group('Profile', () {
    test('derives its ceiling from the gear it wears', () {
      // arrange
      final profile = Profile(
        hero: hero(const Position(0, 0)),
        worldSeed: 1,
        equipment: {
          EquipSlot.head: const Item(
            id: 'worn-1',
            base: _cap,
            rarity: Rarity.fine,
            affixes: [_vigour],
          ),
        },
      );

      // act
      final ceiling = profile.maxHp;

      // assert
      expect(ceiling, 26);
    });

    test('two profiles built the same way are equal', () {
      // arrange
      final one = Profile(hero: hero(const Position(0, 0)), worldSeed: 3);
      final other = Profile(hero: hero(const Position(0, 0)), worldSeed: 3);

      // act
      final same = one == other;

      // assert
      expect(same, isTrue);
    });

    test('a wounded hero is not the same profile as a whole one', () {
      // arrange
      final whole = Profile(hero: hero(const Position(0, 0)), worldSeed: 3);
      final hurt = Profile(
        hero: hero(const Position(0, 0), hp: 4),
        worldSeed: 3,
      );

      // act
      final same = whole == hurt;

      // assert
      expect(same, isFalse);
    });

    test('copyWith replaces only what it is given', () {
      // arrange
      final profile = Profile(
        hero: hero(const Position(0, 0)),
        worldSeed: 3,
        gold: 40,
        bankedGold: 10,
      );

      // act
      final richer = profile.copyWith(gold: 55);

      // assert
      expect((richer.gold, richer.bankedGold, richer.worldSeed), (55, 10, 3));
    });

    test('defensively copies the collections handed to it', () {
      // arrange
      final carried = <Item>[];
      final profile = Profile(
        hero: hero(const Position(0, 0)),
        worldSeed: 1,
        inventory: carried,
      );

      // act
      carried.add(const Item(id: 'late', base: _cap, rarity: Rarity.common));

      // assert
      expect(profile.inventory, isEmpty);
    });

    test('starts on visit zero with an empty vault and an empty purse', () {
      // arrange
      final profile = Profile(hero: hero(const Position(0, 0)), worldSeed: 1);

      // act
      final opening = (profile.visit, profile.gold, profile.bankedGold);

      // assert
      expect(opening, (0, 0, 0));
      expect(profile.bank, isEmpty);
      expect(profile.inventory, isEmpty);
    });
  });

  group('what the hero has learned to cast', () {
    test('a fresh profile knows no spells', () {
      // arrange
      // act
      final profile = _townie();

      // assert
      expect(profile.knownSpells, isEmpty);
    });

    test('is part of what makes two profiles the same profile', () {
      // arrange
      final plain = _townie();

      // act
      final learned = plain.copyWith(knownSpells: const {'firebolt'});

      // assert - a hero who has read a book is not the hero who has not
      expect(learned, isNot(plain));
      expect(learned.knownSpells, const {'firebolt'});
    });

    test('cannot be added to behind the profile\'s back', () {
      // arrange
      final profile = _townie().copyWith(knownSpells: const {'mend'});

      // act
      learn() => profile.knownSpells.add('ward');

      // assert
      expect(learn, throwsUnsupportedError);
    });
  });
}
