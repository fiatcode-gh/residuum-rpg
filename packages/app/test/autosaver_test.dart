import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/save/autosaver.dart';
import 'package:residuum_app/save/boot.dart';
import 'package:residuum_app/save/save_files.dart';
import 'package:residuum_app/save/save_store.dart';
import 'package:residuum_app/town/town_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import 'support/memory_save_files.dart';

/// The crawl [run] would be with something standing next to the hero.
///
/// A save test that only walks proves nothing about the streams: the first floor
/// of a given world may have nothing within reach, and a hero who never swings
/// never rolls — so a decoder that re-seeded from the world seed instead of
/// resuming would look exactly right. Putting a monster in arm's reach is what
/// makes the stream state a number the test can hold the codec to.
GameState _withSomethingToFight(GameState run) {
  final direction = Direction.values.firstWhere(
    (way) => run.map.isWalkable(run.hero.position.step(way)),
  );
  return run.copyWith(
    monsters: [
      Actor(
        id: 'ghoul-1',
        name: 'the ghoul',
        glyph: 'g',
        position: run.hero.position.step(direction),
        hp: 40,
        maxHp: 40,
        attackMin: 1,
        attackMax: 2,
        speed: 10,
        energy: actThreshold,
      ),
    ],
  );
}

SaveDocument _onDisk(MemorySaveFiles files) =>
    decodeSave(files.contents[currentSlot]!) as SaveDocument;

/// A one-hero boot, which is what every test here that is not about the roster
/// is about.
Boot _boot(Profile profile, {GameState? run}) => Boot(
  document: SaveDocument.one(
    id: 'hero-1',
    label: 'Hero 1',
    profile: profile,
    run: run,
  ),
);

void main() {
  group('autosaving the town', () {
    test('a transaction is on disk before the next one is made', () async {
      // arrange
      final files = MemorySaveFiles();
      final town = TownBloc(
        profile: newProfile(worldSeed: 5).copyWith(gold: 500),
      );
      final saver = Autosaver(SaveStore(files), from: _boot(town.state.profile))
        ..watchTown(town);

      // act
      town.add(const DepositGoldPressed(120));
      await town.stream.first;
      await saver.settled();

      // assert
      expect(_onDisk(files).profile.bankedGold, 120);
      expect(_onDisk(files).profile.gold, 380);
      await saver.close();
      await town.close();
    });

    test('entering the dungeon suspends the crawl on disk', () async {
      // arrange
      final files = MemorySaveFiles();
      final town = TownBloc(profile: newProfile(worldSeed: 5));
      final saver = Autosaver(SaveStore(files), from: _boot(town.state.profile))
        ..watchTown(town);

      // act
      town.add(const EnterDungeonPressed());
      await town.stream.first;
      await saver.settled();

      // assert
      expect(_onDisk(files).run, isNotNull);
      expect(_onDisk(files).run!.depth, 1);
      await saver.close();
      await town.close();
    });

    test('the run ending clears the run block', () async {
      // arrange
      final files = MemorySaveFiles();
      final profile = newProfile(worldSeed: 5);
      final town = TownBloc(profile: profile);
      final saver = Autosaver(SaveStore(files), from: _boot(profile))
        ..watchTown(town);
      town.add(const EnterDungeonPressed());
      final entered = await town.stream.first;

      // act
      town.add(RunEnded(entered.run!, died: false));
      await town.stream.first;
      await saver.settled();

      // assert
      expect(_onDisk(files).run, isNull);
      expect(_onDisk(files).profile.visit, 1);
      await saver.close();
      await town.close();
    });
  });

  group('autosaving a crawl', () {
    test('every settled step is on disk, streams and all', () async {
      // arrange
      final files = MemorySaveFiles();
      final profile = newProfile(worldSeed: 5);
      final run = _withSomethingToFight(startDungeonRun(profile));
      final game = GameBloc(game: run, stepDelay: Duration.zero);
      final saver = Autosaver(SaveStore(files), from: _boot(profile, run: run))
        ..watchGame(game);

      // act
      for (var swing = 0; swing < 3; swing++) {
        game.add(TileTapped(game.state.game.monsters.single.position));
        await game.stream.first;
      }
      await saver.settled();

      // assert — the stream must have moved, or a decoder that re-seeded from
      // the world seed would look identical to one that resumed
      expect(game.state.game.rng.state, isNot(Rng(5).state));
      final saved = _onDisk(files).run!;
      expect(saved.rng.state, game.state.game.rng.state);
      expect(saved.lootRng.state, game.state.game.lootRng.state);
      expect(saved.hero.position, game.state.game.hero.position);
      expect(saved.hero.energy, game.state.game.hero.energy);
      expect(
        saved.monsters.map((m) => (m.id, m.position, m.hp, m.energy)),
        game.state.game.monsters.map((m) => (m.id, m.position, m.hp, m.energy)),
      );
      await saver.close();
      await game.close();
    });

    test('a change that is not a game-state change writes nothing', () async {
      // arrange
      final files = MemorySaveFiles();
      final profile = newProfile(worldSeed: 5);
      final run = startDungeonRun(profile);
      final game = GameBloc(game: run, stepDelay: Duration.zero);
      final saver = Autosaver(SaveStore(files), from: _boot(profile, run: run))
        ..watchGame(game);

      // act
      game.add(const MapPanned(Offset(4, 4)));
      await game.stream.first;
      await saver.settled();

      // assert
      expect(files.contents, isEmpty);
      await saver.close();
      await game.close();
    });

    test('a crawl that ended in death is saved as it stands', () async {
      // arrange
      final files = MemorySaveFiles();
      final profile = newProfile(worldSeed: 5);
      final run = startDungeonRun(profile);
      final dying = run.copyWith(
        hero: run.hero.copyWith(hp: 0),
        isGameOver: true,
      );
      final saver = Autosaver(
        SaveStore(files),
        from: _boot(profile, run: dying),
      );

      // act
      saver.saveNow();
      await saver.settled();

      // assert
      expect(_onDisk(files).run!.isGameOver, isTrue);
      expect(_onDisk(files).run!.hero.hp, 0);
      await saver.close();
    });

    test('the profile on disk mid-crawl is the one that walked in', () async {
      // arrange
      final files = MemorySaveFiles();
      final profile = newProfile(worldSeed: 5).copyWith(gold: 90, visit: 2);
      final run = startDungeonRun(profile);
      final saver = Autosaver(SaveStore(files), from: _boot(profile, run: run));

      // act
      saver.saveNow();
      await saver.settled();

      // assert
      expect(_onDisk(files).profile.gold, 90);
      expect(_onDisk(files).profile.visit, 2);
      expect(_onDisk(files).run!.visit, 3);
      await saver.close();
    });

    test('two queued saves land in the order they were asked for', () async {
      // arrange
      final files = MemorySaveFiles();
      final profile = newProfile(worldSeed: 5).copyWith(gold: 500);
      final town = TownBloc(profile: profile);
      final saver = Autosaver(SaveStore(files), from: _boot(profile))
        ..watchTown(town);

      // act
      town.add(const DepositGoldPressed(10));
      await town.stream.first;
      town.add(const DepositGoldPressed(20));
      await town.stream.first;
      await saver.settled();

      // assert
      expect(_onDisk(files).profile.bankedGold, 30);
      expect(
        decodeSave(files.contents[previousSlot]!),
        isA<SaveDocument>().having(
          (read) => read.profile.bankedGold,
          'bankedGold',
          10,
        ),
      );
      await saver.close();
      await town.close();
    });

    test('a closed autosaver stops writing', () async {
      // arrange
      final files = MemorySaveFiles();
      final profile = newProfile(worldSeed: 5);
      final run = startDungeonRun(profile);
      final game = GameBloc(game: run, stepDelay: Duration.zero);
      final saver = Autosaver(SaveStore(files), from: _boot(profile, run: run))
        ..watchGame(game);
      await saver.close();

      // act
      game.add(TileTapped(run.hero.position.step(Direction.north)));
      await game.stream.first;

      // assert
      expect(files.contents, isEmpty);
      await game.close();
    });
  });

  group('autosaving with more than one hero', () {
    test('the hero nobody is playing is written back out untouched', () async {
      // arrange
      final files = MemorySaveFiles();
      final idle = SavedHero(
        label: 'Ilse',
        profile: newProfile(worldSeed: 111).copyWith(gold: 40, visit: 2),
        run: startDungeonRun(newProfile(worldSeed: 111)),
      );
      final played = newProfile(worldSeed: 222).copyWith(gold: 500);
      final roster = SaveDocument(
        active: 'hero-2',
        heroes: {
          'hero-1': idle,
          'hero-2': SavedHero(label: 'Bram', profile: played),
        },
      );
      final town = TownBloc(profile: played);
      final saver = Autosaver(SaveStore(files), from: Boot(document: roster))
        ..watchTown(town);

      // act
      town.add(const DepositGoldPressed(120));
      await town.stream.first;
      await saver.settled();

      // assert
      final disk = _onDisk(files);
      expect(disk.heroes.keys.toList()..sort(), ['hero-1', 'hero-2']);
      expect(disk.heroes['hero-1']!.label, 'Ilse');
      expect(disk.heroes['hero-1']!.profile, idle.profile);
      expect(disk.heroes['hero-1']!.run, isNotNull);
      expect(disk.heroes['hero-1']!.run!.rng.state, idle.run!.rng.state);
      expect(disk.active, 'hero-2');
      expect(disk.heroes['hero-2']!.profile.bankedGold, 120);
      expect(disk.heroes['hero-2']!.label, 'Bram');
      await saver.close();
      await town.close();
    });

    test('a crawl is suspended on the active hero only', () async {
      // arrange
      final files = MemorySaveFiles();
      final played = newProfile(worldSeed: 222);
      final roster = SaveDocument(
        active: 'hero-2',
        heroes: {
          'hero-1': SavedHero(
            label: 'Ilse',
            profile: newProfile(worldSeed: 111),
          ),
          'hero-2': SavedHero(label: 'Bram', profile: played),
        },
      );
      final town = TownBloc(profile: played);
      final saver = Autosaver(SaveStore(files), from: Boot(document: roster))
        ..watchTown(town);

      // act
      town.add(const EnterDungeonPressed());
      await town.stream.first;
      await saver.settled();

      // assert
      expect(_onDisk(files).heroes['hero-2']!.run, isNotNull);
      expect(_onDisk(files).heroes['hero-1']!.run, isNull);
      await saver.close();
      await town.close();
    });
  });

  group('autosaving what the merchant remembers', () {
    test('a purchase is still gone from the shelf after a relaunch', () async {
      // arrange
      final files = MemorySaveFiles();
      final store = SaveStore(files);
      final profile = newProfile(worldSeed: 5).copyWith(gold: 500);
      final town = TownBloc(profile: profile);
      final saver = Autosaver(store, from: _boot(profile))..watchTown(town);
      final offered = town.state.stock.first.id;

      // act
      town.add(BuyPressed(offered));
      await town.stream.first;
      await saver.settled();
      final relaunched = await bootFrom(store, rollWorldSeed: () => 1);
      final second = TownBloc(
        profile: relaunched.profile,
        merchant: relaunched.merchant,
      );

      // assert
      expect(relaunched.merchant.bought, [offered]);
      expect(
        second.state.stock.map((item) => item.id),
        isNot(contains(offered)),
      );
      expect(
        second.state.profile.inventory.where((item) => item.id == offered),
        hasLength(1),
      );
      await saver.close();
      await town.close();
      await second.close();
    });

    test(
      'a sale is still on the counter after a relaunch, at its price',
      () async {
        // arrange
        final files = MemorySaveFiles();
        final store = SaveStore(files);
        final profile = newProfile(worldSeed: 5).copyWith(
          gold: 100,
          inventory: const [
            Item(id: 'held-1', base: ironSword, rarity: Rarity.common),
          ],
        );
        final town = TownBloc(profile: profile);
        final saver = Autosaver(store, from: _boot(profile))..watchTown(town);

        // act
        town.add(const SellPressed('held-1'));
        await town.stream.first;
        await saver.settled();
        final relaunched = await bootFrom(store, rollWorldSeed: () => 1);
        final second = TownBloc(
          profile: relaunched.profile,
          merchant: relaunched.merchant,
        );
        second.add(const BuyBackPressed('held-1'));
        await second.stream.first;

        // assert
        expect(relaunched.merchant.sold.single.id, 'held-1');
        expect(second.state.profile.gold, 100);
        expect(second.state.profile.inventory.single.id, 'held-1');
        await saver.close();
        await town.close();
        await second.close();
      },
    );

    test('the hero nobody is playing keeps their own visit state', () async {
      // arrange
      final files = MemorySaveFiles();
      final played = newProfile(worldSeed: 222).copyWith(gold: 500);
      final roster = SaveDocument(
        active: 'hero-2',
        heroes: {
          'hero-1': SavedHero(
            label: 'Ilse',
            profile: newProfile(worldSeed: 111),
            merchant: const MerchantVisit(bought: ['market-0-potion-1']),
          ),
          'hero-2': SavedHero(label: 'Bram', profile: played),
        },
      );
      final town = TownBloc(profile: played);
      final saver = Autosaver(SaveStore(files), from: Boot(document: roster))
        ..watchTown(town);

      // act
      town.add(BuyPressed(town.state.stock.first.id));
      await town.stream.first;
      await saver.settled();

      // assert
      final disk = _onDisk(files);
      expect(disk.heroes['hero-1']!.merchant.bought, ['market-0-potion-1']);
      expect(disk.heroes['hero-2']!.merchant.bought, hasLength(1));
      await saver.close();
      await town.close();
    });

    test('the visit is cleared on disk when the run ends', () async {
      // arrange
      final files = MemorySaveFiles();
      final profile = newProfile(worldSeed: 5).copyWith(gold: 500);
      final town = TownBloc(profile: profile);
      final saver = Autosaver(SaveStore(files), from: _boot(profile))
        ..watchTown(town);
      town.add(BuyPressed(town.state.stock.first.id));
      await town.stream.first;
      town.add(const EnterDungeonPressed());
      final entered = await town.stream.first;

      // act
      town.add(RunEnded(entered.run!, died: false));
      await town.stream.first;
      await saver.settled();

      // assert
      expect(_onDisk(files).merchant, MerchantVisit.none);
      await saver.close();
      await town.close();
    });

    test(
      'the document the autosaver holds is the one it would write',
      () async {
        // arrange
        final files = MemorySaveFiles();
        final profile = newProfile(worldSeed: 5).copyWith(gold: 500);
        final town = TownBloc(profile: profile);
        final saver = Autosaver(SaveStore(files), from: _boot(profile))
          ..watchTown(town);

        // act
        town.add(const DepositGoldPressed(120));
        await town.stream.first;
        await saver.settled();

        // assert
        expect(encodeSave(saver.document), files.contents[currentSlot]);
        expect(saver.document.profile.bankedGold, 120);
        await saver.close();
        await town.close();
      },
    );
  });
}
