import 'dart:convert';

import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import 'support/deep_run.dart';
import 'support/standing.dart';

SaveDocument _readOrFail(String written) {
  final read = decodeSave(written);
  return read is SaveDocument
      ? read
      : (throw StateError('expected a document, got $read'));
}

String _reason(String written) {
  final read = decodeSave(written);
  return read is SaveFailure
      ? read.reason
      : (throw StateError('expected a failure, got a document'));
}

SaveDocument _twoHeroes() => SaveDocument(
  active: 'hero-2',
  heroes: {
    'hero-1': SavedHero(
      label: 'Ilse',
      profile: newProfile(worldSeed: 111).copyWith(gold: 40, visit: 2),
      world: atTheCrypt(),
      run: deepRun(worldSeed: 111, depth: 3),
      inside: true,
    ),
    'hero-2': SavedHero(
      label: 'Bram',
      profile: newProfile(worldSeed: 222).copyWith(bankedGold: 90),
    ),
  },
);

void main() {
  group('the roster', () {
    test('two heroes round-trip with their own suspended runs', () {
      // arrange
      final before = _twoHeroes();

      // act
      final after = _readOrFail(encodeSave(before));

      // assert
      expect(after.heroes.keys.toList()..sort(), ['hero-1', 'hero-2']);
      expect(after.heroes['hero-1']!.profile, before.heroes['hero-1']!.profile);
      expect(after.heroes['hero-2']!.profile, before.heroes['hero-2']!.profile);
      expect(after.heroes['hero-1']!.run, isNotNull);
      expect(after.heroes['hero-2']!.run, isNull);
      expect(after.heroes['hero-1']!.run!.depth, 3);
      expect(
        after.heroes['hero-1']!.run!.rng.state,
        before.heroes['hero-1']!.run!.rng.state,
      );
    });

    test('each hero keeps their own world', () {
      // arrange
      final before = _twoHeroes();

      // act
      final after = _readOrFail(encodeSave(before));

      // assert
      expect(after.heroes['hero-1']!.profile.worldSeed, 111);
      expect(after.heroes['hero-2']!.profile.worldSeed, 222);
    });

    test('a label round-trips', () {
      // arrange
      final before = _twoHeroes();

      // act
      final after = _readOrFail(encodeSave(before));

      // assert
      expect(after.heroes['hero-1']!.label, 'Ilse');
      expect(after.heroes['hero-2']!.label, 'Bram');
    });

    test('the active hero is the one the game opens on', () {
      // arrange
      final before = _twoHeroes();

      // act
      final after = _readOrFail(encodeSave(before));

      // assert
      expect(after.active, 'hero-2');
      expect(after.profile, before.heroes['hero-2']!.profile);
      expect(after.run, isNull);
    });

    test('the active id is written, not inferred from order', () {
      // arrange
      final before = _twoHeroes();

      // act
      final written = jsonDecode(encodeSave(before)) as Map<String, Object?>;

      // assert
      expect(written['active'], 'hero-2');
      expect((written['heroes']! as Map<String, Object?>).keys.first, 'hero-1');
    });

    test('a document with no heroes at all is refused', () {
      // arrange
      const written = '{"version":1,"active":"hero-1","heroes":{}}';

      // act
      final reason = _reason(written);

      // assert
      expect(reason, contains('no heroes'));
    });

    test('an active id that names no hero is refused by name', () {
      // arrange
      final written =
          jsonDecode(encodeSave(_twoHeroes())) as Map<String, Object?>;
      written['active'] = 'hero-9';

      // act
      final reason = _reason(jsonEncode(written));

      // assert
      expect(reason, contains('hero-9'));
    });

    test('a hero entry missing its label is refused by name', () {
      // arrange
      final written =
          jsonDecode(encodeSave(_twoHeroes())) as Map<String, Object?>;
      ((written['heroes']! as Map<String, Object?>)['hero-2']!
              as Map<String, Object?>)
          .remove('label');

      // act
      final reason = _reason(jsonEncode(written));

      // assert
      expect(reason, contains('label'));
    });

    test('a hero entry missing its profile is refused by name', () {
      // arrange
      final written =
          jsonDecode(encodeSave(_twoHeroes())) as Map<String, Object?>;
      ((written['heroes']! as Map<String, Object?>)['hero-2']!
              as Map<String, Object?>)
          .remove('profile');

      // act
      final reason = _reason(jsonEncode(written));

      // assert
      expect(reason, contains('profile'));
    });

    test('a hero entry that is not an object is refused', () {
      // arrange
      final written =
          jsonDecode(encodeSave(_twoHeroes())) as Map<String, Object?>;
      (written['heroes']! as Map<String, Object?>)['hero-2'] = 'Bram';

      // act
      final reason = _reason(jsonEncode(written));

      // assert
      expect(reason, isNotEmpty);
    });

    test('replacing the active hero leaves every other hero untouched', () {
      // arrange
      final before = _twoHeroes();
      final moved = before.heroes['hero-2']!.profile.copyWith(gold: 777);

      // act
      final after = before.replacingActive(
        moved,
        null,
        MerchantVisit.none,
        newWhereabouts(),
        inside: false,
      );

      // assert
      expect(after.active, 'hero-2');
      expect(after.heroes['hero-2']!.profile.gold, 777);
      expect(after.heroes['hero-2']!.label, 'Bram');
      expect(after.heroes['hero-1']!.profile, before.heroes['hero-1']!.profile);
      expect(
        after.heroes['hero-1']!.run!.rng.state,
        before.heroes['hero-1']!.run!.rng.state,
      );
    });

    test('replacing the active hero can suspend a crawl on them', () {
      // arrange
      final before = _twoHeroes();
      final run = deepRun(worldSeed: 222, depth: 1);

      // act
      final after = before.replacingActive(
        before.profile,
        run,
        MerchantVisit.none,
        atTheCrypt(),
        inside: true,
      );

      // assert
      expect(after.heroes['hero-2']!.run!.worldSeed, 222);
      expect(after.heroes['hero-1']!.run!.worldSeed, 111);
    });

    test('a hero given up takes their slot with them and nothing else', () {
      // arrange
      final before = _twoHeroes();
      final fresh = newProfile(worldSeed: 333);

      // act
      final after = before.replacingActiveWithNewHero(
        id: 'hero-3',
        label: 'Hero 3',
        profile: fresh,
      );

      // assert
      expect(after.active, 'hero-3');
      expect(after.heroes.keys.toList()..sort(), ['hero-1', 'hero-3']);
      expect(after.heroes.containsKey('hero-2'), isFalse);
      expect(after.heroes['hero-3']!.profile.worldSeed, 333);
      expect(after.heroes['hero-1']!.profile, before.heroes['hero-1']!.profile);
    });

    test('a hero keeps their own visit state through a round trip', () {
      // arrange
      final before = SaveDocument(
        active: 'hero-1',
        heroes: {
          'hero-1': SavedHero(
            label: 'Ilse',
            profile: newProfile(worldSeed: 111),
            merchant: MerchantVisit(
              town: stonebridge,
              bought: ['market-stonebridge-0-gear-1'],
              sold: [
                Item(id: 'drop-3', base: ironSword, rarity: Rarity.common),
              ],
            ),
          ),
          'hero-2': SavedHero(
            label: 'Bram',
            profile: newProfile(worldSeed: 222),
          ),
        },
      );

      // act
      final after = _readOrFail(encodeSave(before));

      // assert
      expect(after.heroes['hero-1']!.merchant.bought, [
        'market-stonebridge-0-gear-1',
      ]);
      expect(after.heroes['hero-1']!.merchant.sold.single.id, 'drop-3');
      expect(
        after.heroes['hero-1']!.merchant.sold.single.displayName,
        'Common Iron Sword',
      );
      expect(after.heroes['hero-2']!.merchant, MerchantVisit.none);
    });

    test('a hero entry missing its merchant block is refused by name', () {
      // arrange
      final written =
          jsonDecode(encodeSave(_twoHeroes())) as Map<String, Object?>;
      ((written['heroes']! as Map<String, Object?>)['hero-2']!
              as Map<String, Object?>)
          .remove('merchant');

      // act
      final reason = _reason(jsonEncode(written));

      // assert
      expect(reason, contains('merchant'));
    });

    test('a bought id that is not text is refused', () {
      // arrange
      final written =
          jsonDecode(encodeSave(_twoHeroes())) as Map<String, Object?>;
      (((written['heroes']! as Map<String, Object?>)['hero-2']!
              as Map<String, Object?>)['merchant']!
          as Map<String, Object?>)['bought'] = [
        7,
      ];

      // act
      final reason = _reason(jsonEncode(written));

      // assert
      expect(reason, contains('bought'));
    });

    test('bringing the active hero up to date carries their visit state', () {
      // arrange
      final before = _twoHeroes();
      final visit = MerchantVisit(
        bought: const ['market-stonebridge-0-potion-1'],
        town: stonebridge,
      );

      // act
      final after = before.replacingActive(
        before.profile,
        null,
        visit,
        newWhereabouts(),
        inside: false,
      );

      // assert
      expect(after.heroes['hero-2']!.merchant, visit);
      expect(after.heroes['hero-1']!.merchant, MerchantVisit.none);
    });

    test(
      'a hero added to the roster is played, and the rest are untouched',
      () {
        // arrange
        final before = _twoHeroes();

        // act
        final after = before.addingHero(
          id: 'hero-3',
          label: 'Cato',
          profile: newProfile(worldSeed: 333),
        );

        // assert
        expect(after.active, 'hero-3');
        expect(after.heroes.keys.toList()..sort(), [
          'hero-1',
          'hero-2',
          'hero-3',
        ]);
        expect(after.heroes['hero-3']!.merchant, MerchantVisit.none);
        expect(after.heroes['hero-1']!.run!.depth, 3);
      },
    );

    test('playing another hero moves nothing but which one is played', () {
      // arrange
      final before = _twoHeroes();

      // act
      final after = before.playing('hero-1');

      // assert
      expect(after.active, 'hero-1');
      expect(after.run!.depth, 3);
      expect(after.heroes, before.heroes);
    });

    test('deleting a hero who is not being played keeps the played one', () {
      // arrange
      final before = _twoHeroes();

      // act
      final after = before.without('hero-1');

      // assert
      expect(after!.active, 'hero-2');
      expect(after.heroes.keys.toList(), ['hero-2']);
    });

    test('deleting the hero being played moves play to the first one left', () {
      // arrange
      final before = _twoHeroes();

      // act
      final after = before.without('hero-2');

      // assert
      expect(after!.active, 'hero-1');
      expect(after.heroes.keys.toList(), ['hero-1']);
    });

    test('deleting the only hero is refused, so no roster is ever empty', () {
      // arrange
      final before = SaveDocument.one(
        id: 'hero-1',
        label: 'Hero 1',
        profile: newProfile(worldSeed: 5),
      );

      // act
      final after = before.without('hero-1');

      // assert
      expect(after, isNull);
    });

    test('deleting a hero who is not there changes nothing', () {
      // arrange
      final before = _twoHeroes();

      // act
      final after = before.without('hero-9');

      // assert
      expect(after, isNotNull);
      expect(after!.heroes.keys.toList()..sort(), ['hero-1', 'hero-2']);
      expect(after.active, 'hero-2');
    });

    test('one hero is the ordinary case and still round-trips', () {
      // arrange
      final before = SaveDocument(
        active: 'hero-1',
        heroes: {
          'hero-1': SavedHero(
            label: 'Hero 1',
            profile: newProfile(worldSeed: 5).copyWith(gold: 3),
          ),
        },
      );

      // act
      final after = _readOrFail(encodeSave(before));

      // assert
      expect(after.heroes, hasLength(1));
      expect(after.profile.gold, 3);
      expect(after.run, isNull);
    });
  });

  group('where a hero is standing', () {
    test('a hero inside their crawl round-trips as inside', () {
      // arrange
      final before = _twoHeroes();

      // act
      final after = _readOrFail(encodeSave(before));

      // assert
      expect(after.heroes['hero-1']!.inside, isTrue);
      expect(after.heroes['hero-2']!.inside, isFalse);
    });

    test('a camped hero keeps their crawl and is not standing in it', () {
      // arrange
      final before = SaveDocument(
        active: 'hero-1',
        heroes: {
          'hero-1': SavedHero(
            label: 'Ilse',
            profile: newProfile(worldSeed: 111),
            run: deepRun(worldSeed: 111, depth: 3),
          ),
        },
      );

      // act
      final after = _readOrFail(encodeSave(before));

      // assert
      expect(after.heroes['hero-1']!.inside, isFalse);
      expect(after.heroes['hero-1']!.run!.depth, 3);
      expect(
        after.heroes['hero-1']!.run!.rng.state,
        before.heroes['hero-1']!.run!.rng.state,
      );
    });

    test('a hero entry missing its inside field is refused by name', () {
      // arrange
      final written =
          jsonDecode(encodeSave(_twoHeroes())) as Map<String, Object?>;
      ((written['heroes']! as Map<String, Object?>)['hero-2']!
              as Map<String, Object?>)
          .remove('inside');

      // act
      final reason = _reason(jsonEncode(written));

      // assert
      expect(reason, contains('inside'));
    });

    test('an inside that is not true or false is refused by name', () {
      // arrange
      final written =
          jsonDecode(encodeSave(_twoHeroes())) as Map<String, Object?>;
      ((written['heroes']! as Map<String, Object?>)['hero-2']!
              as Map<String, Object?>)['inside'] =
          'yes';

      // act
      final reason = _reason(jsonEncode(written));

      // assert
      expect(reason, contains('inside'));
    });

    test('a hero inside a crawl that is not there is refused by name', () {
      // arrange
      final written =
          jsonDecode(encodeSave(_twoHeroes())) as Map<String, Object?>;
      ((written['heroes']! as Map<String, Object?>)['hero-2']!
              as Map<String, Object?>)['inside'] =
          true;

      // act
      final reason = _reason(jsonEncode(written));

      // assert
      expect(reason, contains('inside'));
      expect(reason, contains('hero-2'));
    });

    test('bringing the active hero up to date carries where they stand', () {
      // arrange
      final before = _twoHeroes();
      final run = deepRun(worldSeed: 222, depth: 1);

      // act
      final after = before.replacingActive(
        before.profile,
        run,
        MerchantVisit.none,
        atTheCrypt(),
        inside: true,
      );

      // assert
      expect(after.heroes['hero-2']!.inside, isTrue);
      expect(after.heroes['hero-1']!.inside, isTrue);
      expect(after.heroes['hero-1']!.run!.depth, 3);
    });

    test('a hero brought home from their crawl is no longer in it', () {
      // arrange
      final before = _twoHeroes();

      // act
      final after = before.replacingActive(
        before.profile,
        null,
        MerchantVisit.none,
        newWhereabouts(),
        inside: false,
      );

      // assert
      expect(after.heroes['hero-2']!.inside, isFalse);
      expect(after.heroes['hero-2']!.run, isNull);
    });

    test('a hero the roster has just made is in town', () {
      // arrange
      final before = _twoHeroes();

      // act
      final added = before.addingHero(
        id: 'hero-3',
        label: 'Cato',
        profile: newProfile(worldSeed: 333),
      );
      final replaced = before.replacingActiveWithNewHero(
        id: 'hero-4',
        label: 'Dree',
        profile: newProfile(worldSeed: 444),
      );

      // assert
      expect(added.heroes['hero-3']!.inside, isFalse);
      expect(added.heroes['hero-3']!.run, isNull);
      expect(replaced.heroes['hero-4']!.inside, isFalse);
    });

    test('switching hero moves nobody in or out of their crawl', () {
      // arrange
      final before = _twoHeroes();

      // act
      final after = before.playing('hero-1');

      // assert
      expect(after.hero.inside, isTrue);
      expect(after.heroes['hero-2']!.inside, isFalse);
    });
  });
}
