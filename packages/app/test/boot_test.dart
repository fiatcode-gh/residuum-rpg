import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/save/boot.dart';
import 'package:residuum_app/save/save_files.dart';
import 'package:residuum_app/save/save_store.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import 'support/memory_save_files.dart';

/// A one-hero document, for seeding the store before a boot.
SaveDocument _one(Profile profile, {GameState? run, bool inside = false}) =>
    SaveDocument.one(
      id: 'hero-1',
      label: 'Hero 1',
      profile: profile,
      run: run,
      inside: inside,
    );

void main() {
  group('booting', () {
    test('a fresh install rolls its own world and is not seed one', () async {
      // arrange
      final files = MemorySaveFiles();
      final store = SaveStore(files);

      // act
      final booted = await bootFrom(store, rollWorldSeed: () => 987654321);

      // assert
      expect(booted.profile.worldSeed, 987654321);
      expect(booted.profile.worldSeed, isNot(1));
      expect(booted.run, isNull);
      expect(booted.notice, isNull);
    });

    test('a fresh install saves before it is played, so a crash keeps the '
        'world', () async {
      // arrange
      final files = MemorySaveFiles();
      final store = SaveStore(files);

      // act
      await bootFrom(store, rollWorldSeed: () => 987654321);

      // assert
      expect(files.contents.containsKey(currentSlot), isTrue);
      final reread = await bootFrom(store, rollWorldSeed: () => 5);
      expect(reread.profile.worldSeed, 987654321);
    });

    test('a saved hero in town boots into town on their own world', () async {
      // arrange
      final files = MemorySaveFiles();
      final store = SaveStore(files);
      await store.save(_one(newProfile(worldSeed: 424242).copyWith(gold: 51)));

      // act
      final booted = await bootFrom(store, rollWorldSeed: () => 1);

      // assert
      expect(booted.profile.worldSeed, 424242);
      expect(booted.profile.gold, 51);
      expect(booted.run, isNull);
      expect(booted.notice, isNull);
    });

    test('a saved crawl boots with the crawl to resume', () async {
      // arrange
      final files = MemorySaveFiles();
      final store = SaveStore(files);
      final profile = newProfile(worldSeed: 909);
      final run = startDungeonRun(profile);
      await store.save(_one(profile, run: run));

      // act
      final booted = await bootFrom(store, rollWorldSeed: () => 1);

      // assert
      expect(booted.run, isNotNull);
      expect(booted.run!.rng.state, run.rng.state);
      expect(booted.run!.hero.position, run.hero.position);
      expect(booted.run!.visit, run.visit);
    });

    test('a corrupt save boots the older one and carries the report', () async {
      // arrange
      final files = MemorySaveFiles();
      final store = SaveStore(files);
      await store.save(_one(newProfile(worldSeed: 11).copyWith(gold: 3)));
      await store.save(_one(newProfile(worldSeed: 11).copyWith(gold: 4)));
      files.contents[currentSlot] = 'truncated';

      // act
      final booted = await bootFrom(store, rollWorldSeed: () => 1);

      // assert
      expect(booted.profile.gold, 3);
      expect(booted.notice, contains('an older one was restored'));
    });

    test(
      'both slots corrupt begins a fresh hero and carries the report',
      () async {
        // arrange
        final files = MemorySaveFiles();
        final store = SaveStore(files);
        await store.save(_one(newProfile(worldSeed: 11)));
        await store.save(_one(newProfile(worldSeed: 11).copyWith(gold: 4)));
        files.contents[currentSlot] = 'truncated';
        files.contents[previousSlot] = 'also truncated';

        // act
        final booted = await bootFrom(store, rollWorldSeed: () => 777);

        // assert
        expect(booted.profile.worldSeed, 777);
        expect(booted.profile.gold, 0);
        expect(booted.notice, contains('a new hero begins'));
      },
    );

    test('the clock roll gives something other than seed one', () {
      // arrange
      const forbidden = 1;

      // act
      final rolled = rollWorldSeedFromClock();

      // assert
      expect(rolled, isNot(forbidden));
      expect(rolled, greaterThan(0));
    });
  });

  group('booting a roster', () {
    test('the active hero is the one the game opens on', () async {
      // arrange
      final files = MemorySaveFiles();
      final store = SaveStore(files);
      await store.save(
        SaveDocument(
          active: 'hero-2',
          heroes: {
            'hero-1': SavedHero(
              label: 'Ilse',
              profile: newProfile(worldSeed: 111).copyWith(gold: 40),
            ),
            'hero-2': SavedHero(
              label: 'Bram',
              profile: newProfile(worldSeed: 222).copyWith(gold: 7),
            ),
          },
        ),
      );

      // act
      final booted = await bootFrom(store, rollWorldSeed: () => 1);

      // assert
      expect(booted.document.active, 'hero-2');
      expect(booted.profile.worldSeed, 222);
      expect(booted.profile.gold, 7);
      expect(booted.document.heroes, hasLength(2));
    });

    test('a fresh install begins with one hero, labelled and filed', () async {
      // arrange
      final files = MemorySaveFiles();
      final store = SaveStore(files);

      // act
      final booted = await bootFrom(store, rollWorldSeed: () => 987654321);

      // assert
      expect(booted.document.heroes, hasLength(1));
      expect(booted.document.active, 'hero-987654321');
      expect(booted.document.hero.label, heroLabelFor(0));
      expect(booted.profile.worldSeed, 987654321);
    });

    test('a hero id is never reused, even inside one millisecond', () {
      // arrange
      const taken = ['hero-555', 'hero-555-2'];

      // act
      final fresh = unusedHeroIdFrom(555, taken);

      // assert
      expect(heroIdFrom(555), 'hero-555');
      expect(fresh, 'hero-555-3');
      expect(unusedHeroIdFrom(556, taken), 'hero-556');
    });
  });

  group('the four edits a roster makes', () {
    test('a label is suggested from how many heroes there already are', () {
      // arrange
      const existing = 2;

      // act
      final suggested = heroLabelFor(existing);

      // assert
      expect(heroLabelFor(0), 'Hero 1');
      expect(suggested, 'Hero 3');
    });

    test('a created hero is named, played, and written down first', () async {
      // arrange
      final files = MemorySaveFiles();
      final store = SaveStore(files);
      final was = SaveDocument.one(
        id: 'hero-1',
        label: 'Hero 1',
        profile: newProfile(worldSeed: 111),
      );
      await store.save(was);

      // act
      final after = await createHero(
        store,
        was,
        label: 'Ilse',
        rollWorldSeed: () => 555,
      );
      final reread = await bootFrom(store, rollWorldSeed: () => 9);

      // assert
      expect(after.document.active, 'hero-555');
      expect(after.document.hero.label, 'Ilse');
      expect(after.profile.worldSeed, 555);
      expect(after.run, isNull);
      expect(reread.document.heroes.keys.toList()..sort(), [
        'hero-1',
        'hero-555',
      ]);
      expect(reread.document.active, 'hero-555');
    });

    test('a created hero never takes an id already in the roster', () async {
      // arrange
      final files = MemorySaveFiles();
      final store = SaveStore(files);
      final was = SaveDocument.one(
        id: 'hero-555',
        label: 'Hero 1',
        profile: newProfile(worldSeed: 555),
      );

      // act
      final after = await createHero(
        store,
        was,
        label: 'Ilse',
        rollWorldSeed: () => 555,
      );

      // assert
      expect(after.document.active, 'hero-555-2');
      expect(after.document.heroes.keys.toList()..sort(), [
        'hero-555',
        'hero-555-2',
      ]);
    });

    test(
      'switching lands on the other hero, crawl and visit and all',
      () async {
        // arrange
        final files = MemorySaveFiles();
        final store = SaveStore(files);
        final suspended = startDungeonRun(newProfile(worldSeed: 111));
        final was = SaveDocument(
          active: 'hero-2',
          heroes: {
            'hero-1': SavedHero(
              label: 'Ilse',
              profile: newProfile(worldSeed: 111),
              run: suspended,
              merchant: const MerchantVisit(bought: ['market-0-potion-1']),
            ),
            'hero-2': SavedHero(
              label: 'Bram',
              profile: newProfile(worldSeed: 222),
            ),
          },
        );
        await store.save(was);

        // act
        final after = await switchHero(store, was, 'hero-1');
        final reread = await bootFrom(store, rollWorldSeed: () => 9);

        // assert
        expect(after.document.active, 'hero-1');
        expect(after.profile.worldSeed, 111);
        expect(after.run!.rng.state, suspended.rng.state);
        expect(after.merchant.bought, ['market-0-potion-1']);
        expect(reread.document.active, 'hero-1');
      },
    );

    test('deleting the played hero lands on the first one left', () async {
      // arrange
      final files = MemorySaveFiles();
      final store = SaveStore(files);
      final was = SaveDocument(
        active: 'hero-2',
        heroes: {
          'hero-1': SavedHero(
            label: 'Ilse',
            profile: newProfile(worldSeed: 111).copyWith(gold: 40),
          ),
          'hero-2': SavedHero(
            label: 'Bram',
            profile: newProfile(worldSeed: 222),
          ),
        },
      );
      await store.save(was);

      // act
      final after = await deleteHero(store, was, 'hero-2');
      final reread = await bootFrom(store, rollWorldSeed: () => 9);

      // assert
      expect(after!.document.active, 'hero-1');
      expect(after.profile.gold, 40);
      expect(reread.document.heroes.keys.toList(), ['hero-1']);
    });

    test('deleting the only hero is refused rather than written', () async {
      // arrange
      final files = MemorySaveFiles();
      final store = SaveStore(files);
      final was = SaveDocument.one(
        id: 'hero-1',
        label: 'Hero 1',
        profile: newProfile(worldSeed: 111).copyWith(gold: 40),
      );
      await store.save(was);

      // act
      final after = await deleteHero(store, was, 'hero-1');
      final reread = await bootFrom(store, rollWorldSeed: () => 9);

      // assert
      expect(after, isNull);
      expect(reread.document.heroes.keys.toList(), ['hero-1']);
      expect(reread.profile.gold, 40);
    });

    test(
      'the only hero is replaced by a named one on their own world',
      () async {
        // arrange
        final files = MemorySaveFiles();
        final store = SaveStore(files);
        final was = SaveDocument.one(
          id: 'hero-1',
          label: 'Hero 1',
          profile: newProfile(worldSeed: 111),
        );
        await store.save(was);

        // act
        final after = await replaceOnlyHero(
          store,
          was,
          label: 'Cato',
          rollWorldSeed: () => 555,
        );
        final reread = await bootFrom(store, rollWorldSeed: () => 9);

        // assert
        expect(after.document.heroes.keys.toList(), ['hero-555']);
        expect(after.document.hero.label, 'Cato');
        expect(after.profile.worldSeed, 555);
        expect(reread.document.heroes.containsKey('hero-1'), isFalse);
      },
    );
  });

  group('booting a hero who has a crawl', () {
    test('a camped hero boots with their crawl and out of it', () async {
      // arrange
      final store = SaveStore(MemorySaveFiles());
      final profile = newProfile(worldSeed: 424242);
      await store.save(_one(profile, run: startDungeonRun(profile)));

      // act
      final booted = await bootFrom(store, rollWorldSeed: () => 1);

      // assert
      expect(booted.run, isNotNull);
      expect(booted.inside, isFalse);
    });

    test('a hero killed mid-crawl boots back inside it', () async {
      // arrange
      final store = SaveStore(MemorySaveFiles());
      final profile = newProfile(worldSeed: 424242);
      await store.save(
        _one(profile, run: startDungeonRun(profile), inside: true),
      );

      // act
      final booted = await bootFrom(store, rollWorldSeed: () => 1);

      // assert
      expect(booted.inside, isTrue);
      expect(booted.run, isNotNull);
    });

    test('a fresh install is in town, not in a crawl', () async {
      // arrange
      final store = SaveStore(MemorySaveFiles());

      // act
      final booted = await bootFrom(store, rollWorldSeed: () => 987654321);

      // assert
      expect(booted.run, isNull);
      expect(booted.inside, isFalse);
    });

    test('a hero created by the roster is in town', () async {
      // arrange
      final store = SaveStore(MemorySaveFiles());
      final was = _one(newProfile(worldSeed: 111));

      // act
      final booted = await createHero(
        store,
        was,
        label: 'Ilse',
        rollWorldSeed: () => 222,
      );

      // assert
      expect(booted.inside, isFalse);
      expect(booted.run, isNull);
    });

    test('switching to a camped hero boots out of their crawl', () async {
      // arrange
      final store = SaveStore(MemorySaveFiles());
      final camper = newProfile(worldSeed: 111);
      final was = SaveDocument(
        active: 'hero-2',
        heroes: {
          'hero-1': SavedHero(
            label: 'Ilse',
            profile: camper,
            run: startDungeonRun(camper),
          ),
          'hero-2': SavedHero(
            label: 'Bram',
            profile: newProfile(worldSeed: 222),
          ),
        },
      );

      // act
      final booted = await switchHero(store, was, 'hero-1');

      // assert
      expect(booted.run, isNotNull);
      expect(booted.inside, isFalse);
    });
  });
}
