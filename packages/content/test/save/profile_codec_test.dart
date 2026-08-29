import 'package:residuum_content/content.dart';
import 'package:residuum_content/src/save/profile_codec.dart';
import 'package:residuum_content/src/save/save_json.dart';
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

Profile _lived() => newProfile(worldSeed: 9007199254740993).copyWith(
  hero: newProfile().hero.copyWith(hp: 11),
  equipment: {
    EquipSlot.mainHand: const Item(
      id: 'drop-3',
      base: warAxe,
      rarity: Rarity.rare,
      affixes: [keen, ofEmbers],
    ),
    EquipSlot.chest: const Item(
      id: 'drop-4',
      base: mailHauberk,
      rarity: Rarity.fine,
      affixes: [sturdy],
    ),
  },
  inventory: const [
    Item(id: 'kit-2', base: healingPotion, rarity: Rarity.common),
  ],
  bank: const [
    Item(id: 'drop-1', base: ironSword, rarity: Rarity.common),
    Item(
      id: 'drop-2',
      base: kiteShield,
      rarity: Rarity.epic,
      affixes: [sturdy, reinforced, ofVigour],
    ),
  ],
  gold: 41,
  bankedGold: 380,
  visit: 6,
  skills: const {
    SkillId.arms: SkillState(level: 12, xp: 5),
    SkillId.might: SkillState(),
    SkillId.bulwark: SkillState(level: 3, xp: 1),
    SkillId.fleetfoot: SkillState(xp: 2),
  },
);

Profile _reread(Profile profile) =>
    decodeProfile({'profile': encodeProfile(profile)}, 'profile');

void main() {
  group('profile codec', () {
    test('a lived-in profile round-trips whole', () {
      // arrange
      final before = _lived();

      // act
      final after = _reread(before);

      // assert
      expect(after, before);
    });

    test('a fresh profile round-trips whole', () {
      // arrange
      final before = newProfile(worldSeed: 3);

      // act
      final after = _reread(before);

      // assert
      expect(after, before);
    });

    test('a full-width world seed survives exactly', () {
      // arrange
      final before = _lived();

      // act
      final after = _reread(before);

      // assert
      expect(before.worldSeed, 9007199254740993);
      expect(after.worldSeed, before.worldSeed);
    });

    test('the world seed is written as a quoted string', () {
      // arrange
      final before = _lived();

      // act
      final written = encodeProfile(before);

      // assert
      expect(written['worldSeed'], '9007199254740993');
    });

    test('only earned fields are written — the base body is not', () {
      // arrange
      final before = _lived();

      // act
      final written = encodeProfile(before);

      // assert
      expect(written.keys, [
        'hp',
        'gold',
        'bankedGold',
        'worldSeed',
        'visit',
        'equipment',
        'inventory',
        'bank',
        'skills',
        'knownSpells',
        'materials',
        'brewNumber',
      ]);
    });

    test("the hero rebuilds on this build's own base body", () {
      // arrange
      final inflated = newProfile().copyWith(
        hero: const Actor(
          id: 'hero',
          name: 'you',
          glyph: '@',
          position: Position(4, 4),
          hp: 11,
          maxHp: 999,
          attackMin: 500,
          attackMax: 600,
          speed: 99,
          energy: 7,
        ),
      );

      // act
      final after = _reread(inflated);

      // assert
      expect(after.hero.hp, 11);
      expect(after.hero.maxHp, newProfile().hero.maxHp);
      expect(after.hero.attackMin, newProfile().hero.attackMin);
      expect(after.hero.attackMax, newProfile().hero.attackMax);
      expect(after.hero.speed, newProfile().hero.speed);
    });

    test('a missing earned field is refused by name', () {
      // arrange
      final written = encodeProfile(_lived())..remove('bankedGold');

      // act
      void act() => decodeProfile({'profile': written}, 'profile');

      // assert
      expect(
        act,
        throwsA(
          isA<SaveMalformed>().having(
            (malformed) => malformed.reason,
            'reason',
            contains('bankedGold'),
          ),
        ),
      );
    });
  });

  group('what the hero learned to cast', () {
    test('survives a round trip', () {
      // arrange
      final before = _lived().copyWith(knownSpells: const {'firebolt', 'mend'});

      // act
      final after = decodeProfile({
        'profile': encodeProfile(before),
      }, 'profile');

      // assert
      expect(after.knownSpells, const {'firebolt', 'mend'});
    });

    test('is written as sorted ids, so one hero is one document', () {
      // arrange
      final before = _lived().copyWith(knownSpells: const {'mend', 'bind'});

      // act
      final written = encodeProfile(before);

      // assert
      expect(written['knownSpells'], ['bind', 'mend']);
    });

    test('is written even by a hero who has read nothing', () {
      // arrange
      final before = _lived();

      // act
      final written = encodeProfile(before);

      // assert - present and empty, never absent
      expect(written['knownSpells'], isEmpty);
    });

    test('a spell this build never heard of is refused by name', () {
      // arrange
      final written = encodeProfile(_lived());
      written['knownSpells'] = ['telekinesis'];

      // act
      call() => decodeProfile({'profile': written}, 'profile');

      // assert
      expect(call, throwsA(isA<SaveMalformed>()));
    });

    test('a missing key is refused rather than read as knowing nothing', () {
      // arrange
      final written = encodeProfile(_lived())..remove('knownSpells');

      // act
      call() => decodeProfile({'profile': written}, 'profile');

      // assert - never repair: a hero who quietly lost a spell could not tell
      expect(call, throwsA(isA<SaveMalformed>()));
    });
  });
}
