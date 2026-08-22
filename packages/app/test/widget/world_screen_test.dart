import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/game_screen.dart';
import 'package:residuum_app/town/town_bloc.dart';
import 'package:residuum_app/world/world_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../support/pumped_app.dart';
import '../support/standing.dart';
import '../support/world_nav.dart';

SaveDocument _oneHero(
  Profile profile, {
  Whereabouts? world,
  GameState? run,
  bool inside = false,
}) => SaveDocument.one(
  id: 'hero-1',
  label: 'Hero 1',
  profile: profile,
  world: world,
  run: run,
  inside: inside,
);

/// A hero who has heard of everywhere, standing at home.
Whereabouts _knowingAll() => newWhereabouts().hearingOf(northgate);

/// The bloc driving whatever crawl or fight is on screen.
GameBloc _fightOnScreen(WidgetTester tester) =>
    BlocProvider.of<GameBloc>(tester.element(find.byType(GameScreen)));

/// A road fight already in progress, pushed over a world exactly as the session
/// pushes one.
///
/// Built by hand rather than reached by travelling, because what is under test
/// is the wiring at the ends of a fight and not the road that produced it.
/// Walking to an edge through live monsters would make the test's outcome
/// depend on how the fight went.
Future<(TownBloc, WorldBloc)> _pushRoadFight(
  WidgetTester tester, {
  required Profile profile,
  Whereabouts? world,
  bool dead = false,
  Position? heroAt,
}) async {
  final fight = startRoadEncounter(profile, day: 4);
  final placed = heroAt == null
      ? fight
      : fight.copyWith(hero: fight.hero.copyWith(position: heroAt));
  final town = TownBloc(profile: profile, suspended: null);
  final worldBloc = WorldBloc(
    world: world ?? _knowingAll(),
    worldSeed: profile.worldSeed,
    dayDelay: Duration.zero,
  );
  final game = GameBloc(
    game: dead
        ? placed.copyWith(hero: placed.hero.copyWith(hp: 0), isGameOver: true)
        : placed,
    stepDelay: Duration.zero,
  );
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => MultiBlocProvider(
                providers: [
                  BlocProvider.value(value: town),
                  BlocProvider.value(value: worldBloc),
                  BlocProvider.value(value: game),
                ],
                child: const GameScreen(),
              ),
            ),
          ),
          child: const Text('out there'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('out there'));
  await tester.pumpAndSettle();
  return (town, worldBloc);
}

void main() {
  group('the world screen', () {
    testWidgets('boot lands on it, at the hero own node', (tester) async {
      // arrange
      final app = PumpedApp(_oneHero(newProfile(worldSeed: 909)));

      // act
      await app.pump(tester);

      // assert
      expect(find.text('RESIDUUM'), findsOneWidget);
      expect(find.text('At Stonebridge'), findsOneWidget);
      expect(find.text('Day 0.'), findsOneWidget);
    });

    testWidgets('draws every kind of place by shape and word, not by hue', (
      tester,
    ) async {
      // arrange
      final app = PumpedApp(_oneHero(newProfile(worldSeed: 909)));

      // act
      await app.pump(tester);

      // assert
      expect(find.text('[T]'), findsOneWidget);
      expect(find.text('(D)'), findsOneWidget);
      expect(find.text('[?]'), findsOneWidget);
      expect(find.text('Somewhere you have not heard of'), findsOneWidget);
    });

    testWidgets('says which place the hero is standing on, in words', (
      tester,
    ) async {
      // arrange
      final app = PumpedApp(_oneHero(newProfile(worldSeed: 909)));

      // act
      await app.pump(tester);

      // assert
      expect(find.text('Stonebridge — you are here'), findsOneWidget);
      expect(find.text('Here'), findsOneWidget);
    });

    testWidgets('a place the hero has heard of becomes a row of its own', (
      tester,
    ) async {
      // arrange
      final app = PumpedApp(
        _oneHero(newProfile(worldSeed: 909), world: _knowingAll()),
      );

      // act
      await app.pump(tester);

      // assert
      expect(find.text('Northgate'), findsOneWidget);
      expect(find.text('[?]'), findsNothing);
      expect(find.text('[T]'), findsNWidgets(2));
    });

    testWidgets('the Heroes door is here rather than in a town', (
      tester,
    ) async {
      // arrange
      final app = PumpedApp(_oneHero(newProfile(worldSeed: 909)));

      // act
      await app.pump(tester);
      await enterTown(tester, 'Stonebridge');

      // assert
      expect(find.text('Heroes'), findsNothing);
      await backToTheWorld(tester);
      expect(find.text('Heroes'), findsOneWidget);
    });

    testWidgets('switching hero from here lands cleanly on the world', (
      tester,
    ) async {
      // arrange
      final app = PumpedApp(
        SaveDocument(
          active: 'hero-1',
          heroes: {
            'hero-1': SavedHero(
              label: 'Ilse',
              profile: newProfile(worldSeed: 111),
            ),
            'hero-2': SavedHero(
              label: 'Bram',
              profile: newProfile(worldSeed: 222).copyWith(gold: 7),
              world: atNorthgate(),
            ),
          },
        ),
      );
      await app.pump(tester);

      // act
      await tester.tap(find.text('Heroes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bram'));
      await tester.pumpAndSettle();

      // assert
      expect(find.text('At Northgate'), findsOneWidget);
      expect(find.text('Carried  7 gold'), findsOneWidget);
      expect(find.text('Enter Northgate'), findsOneWidget);
      expect(app.saved!.active, 'hero-2');
    });
  });

  group('walking the world', () {
    testWidgets('a day on the road is a day on the counter and a line in the '
        'log', (tester) async {
      // arrange
      final app = PumpedApp(_oneHero(newProfile(worldSeed: 909)));
      await app.pump(tester);

      // act
      await walkTo(tester, 'The Crypt');

      // assert
      expect(find.text('At The Crypt'), findsOneWidget);
      expect(find.text('Day 1.'), findsOneWidget);
      expect(find.textContaining('The road is quiet.'), findsOneWidget);
    });

    testWidgets('the walk is confirmed before any day is spent', (
      tester,
    ) async {
      // arrange
      final app = PumpedApp(_oneHero(newProfile(worldSeed: 909)));
      await app.pump(tester);

      // act
      final row = find.ancestor(
        of: find.text('The Crypt'),
        matching: find.byType(Row),
      );
      await tester.tap(find.descendant(of: row, matching: find.text('Walk')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stay here'));
      await tester.pumpAndSettle();

      // assert
      expect(find.text('At Stonebridge'), findsOneWidget);
      expect(find.text('Day 0.'), findsOneWidget);
    });

    testWidgets('arriving writes the journey down as finished', (tester) async {
      // arrange
      final app = PumpedApp(_oneHero(newProfile(worldSeed: 909)));
      await app.pump(tester);

      // act
      await walkTo(tester, 'The Crypt');

      // assert
      expect(app.saved!.world.at, cryptNode);
      expect(app.saved!.world.journey, isNull);
      expect(app.saved!.world.day, 1);
    });

    testWidgets('arriving at a town makes it the place the hero wakes at', (
      tester,
    ) async {
      // arrange
      final app = PumpedApp(
        _oneHero(newProfile(worldSeed: 909), world: _knowingAll()),
      );
      await app.pump(tester);

      // act
      await walkTo(tester, 'Northgate');

      // assert
      expect(find.text('At Northgate'), findsOneWidget);
      expect(app.saved!.world.home, northgate);
      expect(app.saved!.world.day, 2);
    });

    testWidgets('the journey is written down while it is being walked', (
      tester,
    ) async {
      // arrange
      final app = PumpedApp(
        _oneHero(newProfile(worldSeed: 909), world: _knowingAll()),
      );
      await app.pump(tester);
      final row = find.ancestor(
        of: find.text('Northgate'),
        matching: find.byType(Row),
      );

      // act
      await tester.tap(find.descendant(of: row, matching: find.text('Walk')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Set out'));
      await tester.pump(const Duration(milliseconds: 1));
      final midJourney = app.saved!;
      for (var day = 0; day < 4; day++) {
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
      }

      // assert
      expect(midJourney.world.isTravelling, isTrue);
      expect(midJourney.world.journey!.to, northgate);
      expect(midJourney.world.day, 1);
    });

    testWidgets('a hero killed mid-journey boots back onto the road', (
      tester,
    ) async {
      // arrange
      final onTheRoad = _oneHero(
        newProfile(worldSeed: 909),
        world: Whereabouts(
          at: stonebridge,
          home: stonebridge,
          discovered: {stonebridge, northgate, cryptNode},
          day: 1,
          journey: Journey(from: stonebridge, to: northgate, daysLeft: 1),
        ),
      );
      final app = PumpedApp(onTheRoad);

      // act
      await app.pump(tester);

      // assert
      expect(find.textContaining('On the road to Northgate'), findsOneWidget);
      expect(find.text('Day 1. one day still to walk.'), findsOneWidget);
      expect(find.text('Walk on'), findsOneWidget);
      expect(app.saved!.world.journey!.to, northgate);
    });

    testWidgets('and nothing walks them until they say so', (tester) async {
      // arrange
      final onTheRoad = _oneHero(
        newProfile(worldSeed: 909),
        world: Whereabouts(
          at: stonebridge,
          home: stonebridge,
          discovered: {stonebridge, northgate, cryptNode},
          day: 1,
          journey: Journey(from: stonebridge, to: northgate, daysLeft: 1),
        ),
      );
      final app = PumpedApp(onTheRoad);
      await app.pump(tester);

      // act
      for (var day = 0; day < 4; day++) {
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
      }

      // assert
      expect(app.saved!.world.day, 1);
      expect(app.saved!.world.journey!.daysLeft, 1);
    });

    testWidgets('pressing Walk on finishes the journey', (tester) async {
      // arrange
      final app = PumpedApp(
        _oneHero(
          newProfile(worldSeed: 909),
          world: Whereabouts(
            at: stonebridge,
            home: stonebridge,
            discovered: {stonebridge, northgate, cryptNode},
            day: 1,
            journey: Journey(from: stonebridge, to: northgate, daysLeft: 1),
          ),
        ),
      );
      await app.pump(tester);

      // act
      await tester.tap(find.text('Walk on'));
      await tester.pumpAndSettle();
      for (var day = 0; day < 4; day++) {
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
      }

      // assert
      expect(find.text('At Northgate'), findsOneWidget);
      expect(app.saved!.world.at, northgate);
      expect(app.saved!.world.day, 2);
    });
  });

  group('the tavern', () {
    testWidgets('sells the place nobody has heard of', (tester) async {
      // arrange
      final app = PumpedApp(
        _oneHero(newProfile(worldSeed: 909).copyWith(gold: 100)),
      );
      await app.pump(tester);

      // act
      await enterTown(tester, 'Stonebridge');
      await tester.tap(find.text('Tavern'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ask $rumorPrice'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await backToTheWorld(tester);

      // assert
      expect(find.text('Northgate'), findsOneWidget);
      expect(find.text('[?]'), findsNothing);
      expect(app.saved!.world.discovered, contains(northgate));
      expect(app.saved!.profile.gold, 100 - rumorPrice);
    });

    testWidgets('says so and charges nothing when it is out of places', (
      tester,
    ) async {
      // arrange
      final app = PumpedApp(
        _oneHero(
          newProfile(worldSeed: 909).copyWith(gold: 100),
          world: _knowingAll(),
        ),
      );
      await app.pump(tester);

      // act
      await enterTown(tester, 'Stonebridge');
      await tester.tap(find.text('Tavern'));
      await tester.pumpAndSettle();

      // assert
      expect(find.textContaining('anything left to tell'), findsOneWidget);
      expect(find.text('Ask $rumorPrice'), findsNothing);
      expect(app.saved!.profile.gold, 100);
    });

    testWidgets('a purse that cannot cover it widens nothing', (tester) async {
      // arrange
      final app = PumpedApp(_oneHero(newProfile(worldSeed: 909)));
      await app.pump(tester);

      // act
      await enterTown(tester, 'Stonebridge');
      await tester.tap(find.text('Tavern'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ask $rumorPrice'));
      await tester.pumpAndSettle();

      // assert
      expect(find.textContaining('cannot afford'), findsOneWidget);
      expect(app.saved!.world.discovered, isNot(contains(northgate)));
    });
  });

  group('two towns, two shelves', () {
    testWidgets('the other town is holding different things', (tester) async {
      // arrange
      final app = PumpedApp(
        _oneHero(
          newProfile(worldSeed: 909).copyWith(gold: 500),
          world: _knowingAll(),
        ),
      );
      await app.pump(tester);

      // act
      await enterTown(tester, 'Stonebridge');
      await tester.tap(find.text('Merchant'));
      await tester.pumpAndSettle();
      final here = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data)
          .whereType<String>()
          .where(
            (line) => line.startsWith('Common ') || line.startsWith('Fine '),
          )
          .toList();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await backToTheWorld(tester);
      await walkTo(tester, 'Northgate');
      await enterTown(tester, 'Northgate');
      await tester.tap(find.text('Merchant'));
      await tester.pumpAndSettle();
      final there = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data)
          .whereType<String>()
          .where(
            (line) => line.startsWith('Common ') || line.startsWith('Fine '),
          )
          .toList();

      // assert
      expect(here, isNotEmpty);
      expect(there, isNotEmpty);
      expect(here, isNot(there));
    });

    testWidgets('what one town remembers the other one does not', (
      tester,
    ) async {
      // arrange
      final app = PumpedApp(
        _oneHero(
          newProfile(worldSeed: 909).copyWith(gold: 500),
          world: _knowingAll(),
        ),
      );
      await app.pump(tester);

      // act
      await enterTown(tester, 'Stonebridge');
      await tester.tap(find.text('Merchant'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Buy ').first);
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await backToTheWorld(tester);
      await walkTo(tester, 'Northgate');

      // assert
      expect(app.saved!.merchant, MerchantVisit.none);
      expect(app.saved!.world.at, northgate);
    });
  });

  group('a camp survives the walk to town and back', () {
    testWidgets('the crawl is still on disk the whole way round', (
      tester,
    ) async {
      // arrange
      final profile = newProfile(worldSeed: 909).copyWith(gold: 200);
      final camp = startDungeonRun(profile).copyWith(depth: 3);
      final app = PumpedApp(
        _oneHero(
          suspendRun(profile, camp),
          world: newWhereabouts()
              .hearingOf(northgate)
              .arrivingAt(residuumWorld, cryptNode),
          run: camp,
        ),
      );
      await app.pump(tester);

      // act
      await walkTo(tester, 'Stonebridge');
      final home = app.saved!;
      await enterTown(tester, 'Stonebridge');
      await tester.tap(find.text('Inn'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await backToTheWorld(tester);
      await walkTo(tester, 'The Crypt');

      // assert
      expect(home.run!.depth, 3);
      expect(app.saved!.run!.depth, 3);
      expect(app.saved!.inside, isFalse);
      expect(find.text('Resume the crawl (depth 3)'), findsOneWidget);
    });
  });

  group('a fight on the road', () {
    testWidgets('is opened over the world when the day rolls one', (
      tester,
    ) async {
      // arrange
      final app = PumpedApp(_oneHero(newProfile(worldSeed: _dangerousWorld)));
      await app.pump(tester);

      // act
      await walkTo(tester, 'The Crypt');

      // assert
      expect(find.byType(GameScreen), findsOneWidget);
      expect(find.text('The road'), findsOneWidget);
      expect(find.textContaining('Depth'), findsNothing);
    });

    testWidgets('writes nothing at all to disk while it is in flight', (
      tester,
    ) async {
      // arrange
      final app = PumpedApp(_oneHero(newProfile(worldSeed: _dangerousWorld)));
      await app.pump(tester);
      await walkTo(tester, 'The Crypt');
      final beforeTheFight = Map<String, String>.from(app.files.contents);

      // act
      final fight = _fightOnScreen(tester);
      final hero = fight.state.game.hero.position;
      fight.add(TileTapped(Position(hero.x, hero.y + 1)));
      await tester.pumpAndSettle();
      fight.add(TileTapped(Position(hero.x, hero.y + 2)));
      await tester.pumpAndSettle();

      // assert
      expect(fight.state.game.isEncounter, isTrue);
      expect(app.files.contents, beforeTheFight);
      expect(app.saved!.inside, isFalse);
      expect(app.saved!.run, isNull);
    });

    testWidgets('never lands the hero in the crawl on the next launch', (
      tester,
    ) async {
      // arrange
      final app = PumpedApp(_oneHero(newProfile(worldSeed: _dangerousWorld)));
      await app.pump(tester);

      // act
      await walkTo(tester, 'The Crypt');
      final onDisk = app.saved!;

      // assert
      expect(onDisk.inside, isFalse);
      expect(onDisk.run, isNull);
      expect(onDisk.world.isTravelling, isTrue);
    });
  });

  group('the ends of a road fight', () {
    testWidgets('the way out is a control, because a tap cannot reach it', (
      tester,
    ) async {
      // arrange
      await _pushRoadFight(
        tester,
        profile: newProfile(worldSeed: 909),
        heroAt: const Position(0, 5),
      );

      // act
      final tapped = _fightOnScreen(tester).state.game.hero.position;

      // assert
      expect(find.text('Flee'), findsOneWidget);
      expect(tapped, const Position(0, 5));
    });

    testWidgets('there is no control until the hero reaches an edge', (
      tester,
    ) async {
      // arrange
      await _pushRoadFight(
        tester,
        profile: newProfile(worldSeed: 909),
        heroAt: const Position(7, 5),
      );

      // assert
      expect(find.text('Flee'), findsNothing);
    });

    testWidgets('pressing it closes the fight and keeps the journey', (
      tester,
    ) async {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final (town, world) = await _pushRoadFight(
        tester,
        profile: profile,
        heroAt: const Position(0, 5),
      );

      // act
      await tester.tap(find.text('Flee'));
      await tester.pumpAndSettle();

      // assert
      expect(find.byType(GameScreen), findsNothing);
      expect(world.state.log.last, contains('no further along'));
      expect(town.state.profile.gold, profile.gold);
    });

    testWidgets('every edge of the ground is a way out', (tester) async {
      // arrange
      final edges = {
        'west': const Position(0, 5),
        'east': const Position(encounterWidth - 1, 5),
        'north': const Position(7, 0),
        'south': const Position(7, encounterHeight - 1),
      };

      // act
      final closed = <String>[];
      for (final edge in edges.entries) {
        await _pushRoadFight(
          tester,
          profile: newProfile(worldSeed: 909),
          heroAt: edge.value,
        );
        await tester.tap(find.text('Flee'));
        await tester.pumpAndSettle();
        if (find.byType(GameScreen).evaluate().isEmpty) closed.add(edge.key);
      }

      // assert
      expect(closed, edges.keys.toList());
    });

    testWidgets('a cleared road offers the way on rather than taking it', (
      tester,
    ) async {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final (_, world) = await _pushRoadFight(tester, profile: profile);
      final fight = _fightOnScreen(tester);

      // act
      fight.emit(
        GameViewState(
          game: fight.state.game.copyWith(monsters: const []),
          log: const [],
        ),
      );
      await tester.pumpAndSettle();

      // assert
      expect(find.text('Move on'), findsOneWidget);
      await tester.tap(find.text('Move on'));
      await tester.pumpAndSettle();
      expect(find.byType(GameScreen), findsNothing);
      expect(world.state.log.last, 'The road is yours again.');
    });

    testWidgets('dying wakes the hero at home, stripped of what they carried', (
      tester,
    ) async {
      // arrange
      final profile = newProfile(worldSeed: 909).copyWith(gold: 90);
      final (town, world) = await _pushRoadFight(
        tester,
        profile: profile,
        world: _knowingAll().arrivingAt(residuumWorld, cryptNode),
        dead: true,
      );

      // act
      expect(find.text('Wake at home'), findsOneWidget);
      await tester.tap(find.text('Wake at home'));
      await tester.pumpAndSettle();

      // assert
      expect(find.byType(GameScreen), findsNothing);
      expect(town.state.profile.gold, 0);
      expect(town.state.profile.inventory, isEmpty);
      expect(town.state.profile.hero.hp, town.state.profile.maxHp);
      expect(world.state.world.at, stonebridge);
      expect(world.state.world.at, isNot(cryptNode));
      expect(world.state.isTravelling, isFalse);
    });

    testWidgets('the back button is refused, and says where the way out is', (
      tester,
    ) async {
      // arrange
      await _pushRoadFight(tester, profile: newProfile(worldSeed: 909));

      // act
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      // assert
      expect(find.byType(GameScreen), findsOneWidget);
      expect(_fightOnScreen(tester).state.log, [
        'You can only leave by walking off the edge of the road.',
      ]);
    });

    testWidgets('there are no stairs on a road', (tester) async {
      // arrange
      await _pushRoadFight(tester, profile: newProfile(worldSeed: 909));

      // assert
      expect(find.text('Descend >'), findsNothing);
      expect(find.text('Ascend <'), findsNothing);
      expect(find.text('Leave'), findsNothing);
    });
  });
}

/// A world whose first day out of Stonebridge is a fight.
///
/// Swept off the shipped derivation: day one of world 10 rolls under the
/// Stonebridge-to-crypt road's danger of 15.
const int _dangerousWorld = 10;
