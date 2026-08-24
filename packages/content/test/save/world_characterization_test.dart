import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import 'support/standing.dart';

/// A crawl with the hero standing on the stairs down, ready to be walked out of.
GameState _onTheStairs(Profile profile, [NodeId? node]) {
  final run = startDungeonRunAt(node ?? cryptNode, profile);
  return run.copyWith(hero: run.hero.copyWith(position: run.stairsDown));
}

/// A one-hero document, written and read back the way the app writes one.
SaveDocument _roundTrip(SaveDocument document) =>
    decodeSave(encodeSave(document)) as SaveDocument;

/// A plain one-hero document as text, for the tests that break one field of it.
///
/// Encoded rather than written out by hand, because these tests are about what
/// the decoder refuses and not about the format's bytes — the goldens are what
/// pin those, and a second hand-written copy here would be a second thing to
/// keep in step.
String _oneHero() => encodeSave(
  SaveDocument.one(
    id: 'hero-1',
    label: 'Hero 1',
    profile: newProfile(worldSeed: 909),
  ),
);

void main() {
  group('the boot fork, pinned at the document', () {
    test('a hero killed mid-crawl is written down as standing in it', () {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final document = SaveDocument.one(
        id: 'hero-1',
        label: 'Hero 1',
        profile: profile,
        world: atTheCrypt(),
        run: startDungeonRunAt(cryptNode, profile),
        dungeon: cryptNode,
        inside: true,
      );

      // act
      final read = _roundTrip(document);

      // assert
      expect(read.inside, isTrue);
      expect(read.run, isNotNull);
    });

    test('a hero camped away from a crawl is written down as out of it', () {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final camp = _onTheStairs(profile);
      final document = SaveDocument.one(
        id: 'hero-1',
        label: 'Hero 1',
        profile: suspendRun(profile, camp),
        world: atTheCrypt(),
        run: camp,
        dungeon: cryptNode,
        inside: false,
      );

      // act
      final read = _roundTrip(document);

      // assert
      expect(read.inside, isFalse);
      expect(read.run, isNotNull);
      expect(read.run!.depth, camp.depth);
    });

    test('a hero with no crawl at all is neither', () {
      // arrange
      final document = SaveDocument.one(
        id: 'hero-1',
        label: 'Hero 1',
        profile: newProfile(worldSeed: 909),
      );

      // act
      final read = _roundTrip(document);

      // assert
      expect(read.inside, isFalse);
      expect(read.run, isNull);
    });

    test('a document claiming to be inside a crawl it has not is refused', () {
      // arrange
      final written = encodeSave(
        SaveDocument.one(
          id: 'hero-1',
          label: 'Hero 1',
          profile: newProfile(worldSeed: 909),
        ),
      ).replaceFirst('"inside":false', '"inside":true');

      // act
      final read = decodeSave(written);

      // assert
      expect(read, isA<SaveFailure>());
      expect((read as SaveFailure).reason, contains('"inside" a crawl'));
    });
  });

  group('the world block is required, and checked', () {
    test('a document without one is refused by name', () {
      // arrange
      final written = _oneHero().replaceFirst(
        RegExp(r'"world":\{[^}]*"journey":null\},'),
        '',
      );

      // act
      final read = decodeSave(written);

      // assert
      expect(read, isA<SaveFailure>());
      expect((read as SaveFailure).reason, contains('"world"'));
    });

    test('a hero standing nowhere this world has is refused by name', () {
      // arrange
      final written = _oneHero().replaceFirst(
        '"at":"stonebridge"',
        '"at":"atlantis"',
      );

      // act
      final read = decodeSave(written);

      // assert
      expect(
        (read as SaveFailure).reason,
        contains('"atlantis", which is nowhere in this world'),
      );
    });

    test('a hero standing somewhere they never heard of is refused', () {
      // arrange
      final written = _oneHero().replaceFirst(
        '"discovered":["crypt","stonebridge"]',
        '"discovered":["crypt"]',
      );

      // act
      final read = decodeSave(written);

      // assert
      expect((read as SaveFailure).reason, contains('never heard of'));
    });

    test('a hero who calls a dungeon home is refused by name', () {
      // arrange
      final written = _oneHero().replaceFirst(
        '"home":"stonebridge"',
        '"home":"crypt"',
      );

      // act
      final read = decodeSave(written);

      // assert
      expect((read as SaveFailure).reason, contains('which is not a town'));
    });

    test('a day before the first one is refused', () {
      // arrange
      final written = _oneHero().replaceFirst('"day":0', '"day":-3');

      // act
      final read = decodeSave(written);

      // assert
      expect((read as SaveFailure).reason, contains('day zero'));
    });

    test(
      'a missing day is refused by name rather than assumed to be nought',
      () {
        // arrange
        final written = _oneHero().replaceFirst('"day":0,', '');

        // act
        final read = decodeSave(written);

        // assert
        expect((read as SaveFailure).reason, contains('"day"'));
      },
    );
  });

  group('a hero on the road', () {
    test('rides out a round trip with their legs intact', () {
      // arrange
      final travelling = Whereabouts(
        at: stonebridge,
        home: stonebridge,
        discovered: {stonebridge, northgate, cryptNode},
        day: 12,
        journey: Journey(from: stonebridge, to: northgate, daysLeft: 2),
      );

      // act
      final read = _roundTrip(
        SaveDocument.one(
          id: 'hero-1',
          label: 'Hero 1',
          profile: newProfile(worldSeed: 909),
          world: travelling,
        ),
      );

      // assert
      expect(read.world, travelling);
      expect(read.world.journey!.from, stonebridge);
      expect(read.world.journey!.to, northgate);
      expect(read.world.journey!.daysLeft, 2);
      expect(read.world.day, 12);
    });

    test('a road this world does not have is refused by name', () {
      // arrange
      final written = encodeSave(
        SaveDocument.one(
          id: 'hero-1',
          label: 'Hero 1',
          profile: newProfile(worldSeed: 909),
          world: Whereabouts(
            at: stonebridge,
            home: stonebridge,
            discovered: {stonebridge, northgate, cryptNode},
            journey: Journey(from: stonebridge, to: northgate, daysLeft: 1),
          ),
        ),
      ).replaceFirst('"to":"northgate"', '"to":"stonebridge"');

      // act
      final read = decodeSave(written);

      // assert
      expect((read as SaveFailure).reason, contains('which this world does'));
    });

    test('a leg with nothing left on it is not a leg, and is refused', () {
      // arrange
      final written = encodeSave(
        SaveDocument.one(
          id: 'hero-1',
          label: 'Hero 1',
          profile: newProfile(worldSeed: 909),
          world: Whereabouts(
            at: stonebridge,
            home: stonebridge,
            discovered: {stonebridge, northgate, cryptNode},
            journey: Journey(from: stonebridge, to: northgate, daysLeft: 1),
          ),
        ),
      ).replaceFirst('"daysLeft":1', '"daysLeft":0');

      // act
      final read = decodeSave(written);

      // assert
      expect((read as SaveFailure).reason, contains('at least a day left'));
    });

    test('cannot be inside a crawl at the same time', () {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final written =
          encodeSave(
            SaveDocument.one(
              id: 'hero-1',
              label: 'Hero 1',
              profile: profile,
              world: atTheCrypt(),
              run: startDungeonRunAt(cryptNode, profile),
              dungeon: cryptNode,
              inside: true,
            ),
          ).replaceFirst(
            '"journey":null',
            '"journey":{"from":"crypt","to":"stonebridge","daysLeft":1}',
          );

      // act
      final read = decodeSave(written);

      // assert
      expect(
        (read as SaveFailure).reason,
        contains('on the road at the same time'),
      );
    });
  });

  group('the merchant block says which town it remembers', () {
    test('a shop remembered without its town is refused by name', () {
      // arrange
      final written = encodeSave(
        SaveDocument.one(
          id: 'hero-1',
          label: 'Hero 1',
          profile: newProfile(worldSeed: 909),
          merchant: MerchantVisit(
            bought: const ['market-stonebridge-0-potion-1'],
            town: stonebridge,
          ),
        ),
      ).replaceFirst('"town":"stonebridge"', '"town":null');

      // act
      final read = decodeSave(written);

      // assert
      expect(
        (read as SaveFailure).reason,
        contains('without remembering which town'),
      );
    });

    test('a missing town is refused by name rather than left null', () {
      // arrange
      final written = _oneHero().replaceFirst(',"town":null', '');

      // act
      final read = decodeSave(written);

      // assert
      expect((read as SaveFailure).reason, contains('"town"'));
    });

    test('a remembered shop rides a round trip with its town', () {
      // arrange
      final visit = MerchantVisit(
        bought: const ['market-northgate-0-gear-1'],
        town: northgate,
      );

      // act
      final read = _roundTrip(
        SaveDocument.one(
          id: 'hero-1',
          label: 'Hero 1',
          profile: newProfile(worldSeed: 909),
          merchant: visit,
        ),
      );

      // assert
      expect(read.merchant.town, northgate);
      expect(read.merchant.bought, ['market-northgate-0-gear-1']);
    });
  });

  group('being inside a crawl says something about where you stand', () {
    test('a hero inside a crawl while standing in a town is refused', () {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final written = encodeSave(
        SaveDocument.one(
          id: 'hero-1',
          label: 'Hero 1',
          profile: profile,
          world: atTheCrypt(),
          run: startDungeonRunAt(cryptNode, profile),
          dungeon: cryptNode,
          inside: true,
        ),
      ).replaceFirst('"at":"crypt"', '"at":"stonebridge"');

      // act
      final read = decodeSave(written);

      // assert
      expect((read as SaveFailure).reason, contains('has no dungeon under it'));
    });

    test('a hero camped away from a crawl may stand in a town', () {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final camp = _onTheStairs(profile);

      // act
      final read = _roundTrip(
        SaveDocument.one(
          id: 'hero-1',
          label: 'Hero 1',
          profile: suspendRun(profile, camp),
          world: atNorthgate(),
          run: camp,
          dungeon: cryptNode,
        ),
      );

      // assert
      expect(read.inside, isFalse);
      expect(read.world.at, northgate);
      expect(read.run, isNotNull);
    });
  });

  group('the camp a hero can walk back into', () {
    test(
      'suspending leaves the profile and the camp agreeing on the visit',
      () {
        // arrange
        final profile = newProfile(worldSeed: 909);
        final camp = _onTheStairs(profile);

        // act
        final home = suspendRun(profile, camp);

        // assert
        expect(home.visit, camp.visit);
      },
    );

    test('a camp survives being written down and read back', () {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final camp = _onTheStairs(profile);

      // act
      final read = _roundTrip(
        SaveDocument.one(
          id: 'hero-1',
          label: 'Hero 1',
          profile: suspendRun(profile, camp),
          run: camp,
          dungeon: cryptNode,
        ),
      );

      // assert
      expect(read.run!.hero.position, camp.hero.position);
      expect(read.run!.rng.state, camp.rng.state);
      expect(read.run!.lootRng.state, camp.lootRng.state);
      expect(read.profile.visit, read.run!.visit);
    });
  });

  group('which dungeon the crawl is in', () {
    test('rides a round trip beside the run, not inside it', () {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final camp = _onTheStairs(profile, seaCave);

      // act
      final read = _roundTrip(
        SaveDocument.one(
          id: 'hero-1',
          label: 'Hero 1',
          profile: suspendRun(profile, camp),
          run: camp,
          dungeon: seaCave,
        ),
      );

      // assert
      expect(read.dungeon, seaCave);
    });

    test('a document that does not say which is refused by name', () {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final written = encodeSave(
        SaveDocument.one(
          id: 'hero-1',
          label: 'Hero 1',
          profile: profile,
          world: atTheCrypt(),
          run: startDungeonRunAt(cryptNode, profile),
          dungeon: cryptNode,
          inside: true,
        ),
      ).replaceFirst(',"dungeon":"crypt"', '');

      // act
      final read = decodeSave(written);

      // assert
      expect((read as SaveFailure).reason, contains('"dungeon"'));
    });

    test('a crawl with no dungeon named is refused by name', () {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final written = encodeSave(
        SaveDocument.one(
          id: 'hero-1',
          label: 'Hero 1',
          profile: profile,
          world: atTheCrypt(),
          run: startDungeonRunAt(cryptNode, profile),
          dungeon: cryptNode,
          inside: true,
        ),
      ).replaceFirst('"dungeon":"crypt"', '"dungeon":null');

      // act
      final read = decodeSave(written);

      // assert
      expect(
        (read as SaveFailure).reason,
        contains('a crawl without saying which dungeon'),
      );
    });

    test('a dungeon named without a crawl to be in is refused by name', () {
      // arrange
      final written = _oneHero().replaceFirst(
        '"dungeon":null',
        '"dungeon":"crypt"',
      );

      // act
      final read = decodeSave(written);

      // assert
      expect(
        (read as SaveFailure).reason,
        contains('names a dungeon it has no crawl in'),
      );
    });

    test('a dungeon this world has never had is refused by name', () {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final written = encodeSave(
        SaveDocument.one(
          id: 'hero-1',
          label: 'Hero 1',
          profile: profile,
          world: atTheCrypt(),
          run: startDungeonRunAt(cryptNode, profile),
          dungeon: cryptNode,
          inside: true,
        ),
      ).replaceFirst('"dungeon":"crypt"', '"dungeon":"moria"');

      // act
      final read = decodeSave(written);

      // assert
      expect(
        (read as SaveFailure).reason,
        contains('"moria", which is nowhere in this world'),
      );
    });

    test('a town named as the dungeon is refused by name', () {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final written = encodeSave(
        SaveDocument.one(
          id: 'hero-1',
          label: 'Hero 1',
          profile: profile,
          world: atTheCrypt(),
          run: startDungeonRunAt(cryptNode, profile),
          dungeon: cryptNode,
          inside: true,
        ),
      ).replaceFirst('"dungeon":"crypt"', '"dungeon":"northgate"');

      // act
      final read = decodeSave(written);

      // assert
      expect(
        (read as SaveFailure).reason,
        contains('which has no dungeon under it'),
      );
    });
  });

  group('a camp in a themed dungeon', () {
    test('comes back roll for roll in the sea-cave', () {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final camp = _onTheStairs(profile, seaCave);

      // act
      final read = _roundTrip(
        SaveDocument.one(
          id: 'hero-1',
          label: 'Hero 1',
          profile: suspendRun(profile, camp),
          run: camp,
          dungeon: seaCave,
        ),
      );

      // assert
      expect(read.run!.map.toAscii(), camp.map.toAscii());
      expect(read.run!.rng.state, camp.rng.state);
      expect(read.run!.lootRng.state, camp.lootRng.state);
      expect(
        read.run!.monsters.map((monster) => (monster.id, monster.position)),
        camp.monsters.map((monster) => (monster.id, monster.position)),
      );
      expect(read.run!.dropTables, seaCaveDropTables);
    });

    test('comes back roll for roll in the ruined keep', () {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final camp = _onTheStairs(profile, ruinedKeep);

      // act
      final read = _roundTrip(
        SaveDocument.one(
          id: 'hero-1',
          label: 'Hero 1',
          profile: suspendRun(profile, camp),
          run: camp,
          dungeon: ruinedKeep,
        ),
      );

      // assert
      expect(read.run!.map.toAscii(), camp.map.toAscii());
      expect(read.run!.rng.state, camp.rng.state);
      expect(read.run!.lootRng.state, camp.lootRng.state);
      expect(read.run!.dropTables, ruinedKeepDropTables);
    });

    test('walks on down the floors of the dungeon it was camped in', () {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final camp = _onTheStairs(profile, seaCave);

      // act
      final read = _roundTrip(
        SaveDocument.one(
          id: 'hero-1',
          label: 'Hero 1',
          profile: suspendRun(profile, camp),
          run: camp,
          dungeon: seaCave,
        ),
      );
      final next = read.run!.buildFloor(2);
      final expected = themedFloor(
        theSeaCave,
        2,
        worldSeed: 909,
        visit: camp.visit,
        deepest: delveDepth(seaCave, 909, camp.visit),
      );

      // assert
      expect(next.map.toAscii(), expected.map.toAscii());
      expect(
        next.monsters.map((monster) => monster.id),
        expected.monsters.map((monster) => monster.id),
      );
    });

    test('a crypt camp still walks on down the crypt', () {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final camp = _onTheStairs(profile);

      // act
      final read = _roundTrip(
        SaveDocument.one(
          id: 'hero-1',
          label: 'Hero 1',
          profile: suspendRun(profile, camp),
          run: camp,
          dungeon: cryptNode,
        ),
      );

      // assert
      expect(
        read.run!.buildFloor(2).map.toAscii(),
        buildFloor(2, worldSeed: 909, visit: camp.visit).map.toAscii(),
      );
      expect(read.run!.dropTables, dropTables);
    });
  });
}
