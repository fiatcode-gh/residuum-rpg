import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/world/world_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import 'support/standing.dart';

/// A world bloc on the shipped map, walking with no pause between days.
WorldBloc _bloc({Whereabouts? world, int worldSeed = 909}) => WorldBloc(
  world: world ?? newWhereabouts(),
  worldSeed: worldSeed,
  dayDelay: Duration.zero,
);

/// A hero who has heard of everywhere, so the tavern has nothing left to sell.
Whereabouts _knowingAll() => newWhereabouts().hearingOf(northgate);

void main() {
  group('setting out', () {
    blocTest<WorldBloc, WorldViewState>(
      'a road the hero has heard of is walked',
      build: _bloc,
      act: (bloc) => bloc.add(TravelRequested(cryptNode)),
      verify: (bloc) {
        expect(bloc.state.world.at, cryptNode);
        expect(bloc.state.isTravelling, isFalse);
      },
    );

    blocTest<WorldBloc, WorldViewState>(
      'a place the hero has not heard of is refused in the rules own words',
      build: _bloc,
      act: (bloc) => bloc.add(TravelRequested(northgate)),
      verify: (bloc) {
        expect(bloc.state.notice, 'you have not heard of that place');
        expect(bloc.state.world, newWhereabouts());
      },
    );

    blocTest<WorldBloc, WorldViewState>(
      'setting out says so in the log, with the days it will take',
      build: () => _bloc(world: _knowingAll()),
      act: (bloc) => bloc.add(TravelRequested(northgate)),
      verify: (bloc) {
        expect(bloc.state.log.first, 'You set out for Northgate, 2 days away.');
      },
    );

    blocTest<WorldBloc, WorldViewState>(
      'a one day road says a day rather than one days',
      build: _bloc,
      act: (bloc) => bloc.add(TravelRequested(cryptNode)),
      verify: (bloc) {
        expect(bloc.state.log.first, 'You set out for The Crypt, a day away.');
      },
    );
  });

  group('walking there', () {
    blocTest<WorldBloc, WorldViewState>(
      'the days walk themselves until the hero arrives',
      build: () => _bloc(world: _knowingAll()),
      act: (bloc) => bloc.add(TravelRequested(northgate)),
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.world.at, northgate);
        expect(bloc.state.world.day, 2);
        expect(bloc.state.isTravelling, isFalse);
        expect(bloc.state.walking, isFalse);
      },
    );

    blocTest<WorldBloc, WorldViewState>(
      'arriving in a town makes it the place the hero wakes at',
      build: () => _bloc(world: _knowingAll()),
      act: (bloc) => bloc.add(TravelRequested(northgate)),
      wait: const Duration(milliseconds: 10),
      verify: (bloc) => expect(bloc.state.world.home, northgate),
    );

    blocTest<WorldBloc, WorldViewState>(
      'arriving uncovers what the place is next to',
      build: _bloc,
      act: (bloc) => bloc.add(TravelRequested(cryptNode)),
      wait: const Duration(milliseconds: 10),
      verify: (bloc) =>
          expect(bloc.state.world.discovered, contains(northgate)),
    );

    blocTest<WorldBloc, WorldViewState>(
      'every day walked leaves a line behind it',
      build: () => _bloc(world: _knowingAll()),
      act: (bloc) => bloc.add(TravelRequested(northgate)),
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.log, hasLength(greaterThanOrEqualTo(3)));
        expect(bloc.state.log.last, contains('You reach Northgate.'));
      },
    );

    blocTest<WorldBloc, WorldViewState>(
      'a hero already on a road cannot set out again',
      build: () => _bloc(world: _knowingAll()),
      act: (bloc) async {
        bloc.add(TravelRequested(northgate));
        await bloc.stream.first;
        bloc.add(TravelRequested(cryptNode));
      },
      verify: (bloc) =>
          expect(bloc.state.notice, 'you are already on the road'),
    );
  });

  group('something on the road', () {
    blocTest<WorldBloc, WorldViewState>(
      'stops the walk and asks for a fight',
      build: () => _bloc(worldSeed: _dangerousWorld),
      act: (bloc) => bloc.add(TravelRequested(cryptNode)),
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.fight, isNotNull);
        expect(bloc.state.isTravelling, isTrue);
        expect(bloc.state.log.last, contains('out of the scrub'));
      },
    );

    blocTest<WorldBloc, WorldViewState>(
      'costs the day and none of the distance',
      build: () => _bloc(worldSeed: _dangerousWorld),
      act: (bloc) => bloc.add(TravelRequested(cryptNode)),
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.world.day, 1);
        expect(bloc.state.world.journey!.daysLeft, 1);
      },
    );

    blocTest<WorldBloc, WorldViewState>(
      'walking away from it picks the journey back up',
      build: () => _bloc(worldSeed: _dangerousWorld),
      act: (bloc) async {
        bloc.add(TravelRequested(cryptNode));
        await bloc.stream.firstWhere((state) => state.fight != null);
        bloc.add(const RoadFightOver(EncounterEnding.fled));
      },
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        expect(
          bloc.state.log,
          contains('You get away, no further along than you were.'),
        );
        expect(bloc.state.world.at, cryptNode);
      },
    );

    blocTest<WorldBloc, WorldViewState>(
      'clearing it picks the journey back up too',
      build: () => _bloc(worldSeed: _dangerousWorld),
      act: (bloc) async {
        bloc.add(TravelRequested(cryptNode));
        await bloc.stream.firstWhere((state) => state.fight != null);
        bloc.add(const RoadFightOver(EncounterEnding.cleared));
      },
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        expect(bloc.state.log, contains('The road is yours again.'));
        expect(bloc.state.world.at, cryptNode);
        expect(bloc.state.isTravelling, isFalse);
      },
    );

    blocTest<WorldBloc, WorldViewState>(
      'dying on it wakes the hero at home, off the road',
      build: () => _bloc(worldSeed: _dangerousWorld),
      act: (bloc) async {
        bloc.add(TravelRequested(cryptNode));
        await bloc.stream.firstWhere((state) => state.fight != null);
        bloc.add(const RoadFightOver(EncounterEnding.died));
      },
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        expect(bloc.state.world.at, stonebridge);
        expect(bloc.state.isTravelling, isFalse);
        expect(bloc.state.log.last, contains('You wake in Stonebridge'));
      },
    );

    blocTest<WorldBloc, WorldViewState>(
      'dying far from home wakes the hero at the town they last slept in',
      build: () => _bloc(
        world: _knowingAll().arrivingAt(residuumWorld, northgate),
        worldSeed: _dangerousWorld,
      ),
      act: (bloc) async {
        bloc.add(TravelRequested(cryptNode));
        await bloc.stream.firstWhere((state) => state.fight != null);
        bloc.add(const RoadFightOver(EncounterEnding.died));
      },
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        expect(bloc.state.world.home, northgate);
        expect(bloc.state.world.at, northgate);
      },
    );

    blocTest<WorldBloc, WorldViewState>(
      'dying wakes the hero at the town they slept in, not where they set out',
      build: () => _bloc(
        world: _knowingAll().arrivingAt(residuumWorld, cryptNode),
        worldSeed: _dangerousFromTheCrypt,
      ),
      act: (bloc) async {
        bloc.add(TravelRequested(northgate));
        await bloc.stream.firstWhere((state) => state.fight != null);
        bloc.add(const RoadFightOver(EncounterEnding.died));
      },
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        expect(bloc.state.world.at, stonebridge);
        expect(bloc.state.world.at, isNot(cryptNode));
        expect(bloc.state.world.at, isNot(northgate));
      },
    );

    blocTest<WorldBloc, WorldViewState>(
      'a fight is never asked for twice on one day',
      build: () => _bloc(worldSeed: _dangerousWorld),
      act: (bloc) async {
        bloc.add(TravelRequested(cryptNode));
        await bloc.stream.firstWhere((state) => state.fight != null);
        bloc.add(const RoadFightOver(EncounterEnding.fled));
      },
      wait: const Duration(milliseconds: 20),
      verify: (bloc) => expect(bloc.state.fight, isNull),
    );
  });

  group('what a tavern is worth', () {
    test('offers the place the hero has not heard of', () {
      // arrange
      final bloc = _bloc();

      // act
      final offered = bloc.state.rumorOnOffer(rumorPool);

      // assert
      expect(offered!.reveals, northgate);
    });

    test('offers nothing once the map is uncovered', () {
      // arrange
      final bloc = _bloc(world: _knowingAll());

      // act
      final offered = bloc.state.rumorOnOffer(rumorPool);

      // assert
      expect(offered, isNull);
    });

    blocTest<WorldBloc, WorldViewState>(
      'a rumor told widens the map and says what was said',
      build: _bloc,
      act: (bloc) => bloc.add(
        RumorHeard(
          buyRumor(
            newProfile(worldSeed: 909).copyWith(gold: 100),
            bloc.state.world,
            rumorPool,
            rumorPrice,
          ),
        ),
      ),
      verify: (bloc) {
        expect(bloc.state.world.discovered, contains(northgate));
        expect(bloc.state.log.single, rumorPool.first.line);
      },
    );

    blocTest<WorldBloc, WorldViewState>(
      'a purse that cannot cover it leaves the map alone and says why',
      build: _bloc,
      act: (bloc) => bloc.add(
        RumorHeard(
          buyRumor(
            newProfile(worldSeed: 909),
            bloc.state.world,
            rumorPool,
            rumorPrice,
          ),
        ),
      ),
      verify: (bloc) {
        expect(bloc.state.world.discovered, isNot(contains(northgate)));
        expect(bloc.state.notice, 'you cannot afford that');
        expect(bloc.state.log, isEmpty);
      },
    );

    blocTest<WorldBloc, WorldViewState>(
      'a tavern with nothing left to say says nothing and charges nothing',
      build: () => _bloc(world: _knowingAll()),
      act: (bloc) => bloc.add(
        RumorHeard(
          buyRumor(
            newProfile(worldSeed: 909).copyWith(gold: 100),
            bloc.state.world,
            rumorPool,
            rumorPrice,
          ),
        ),
      ),
      verify: (bloc) {
        expect(bloc.state.log, isEmpty);
        expect(bloc.state.notice, isNull);
      },
    );
  });

  group('where the hero could go from here', () {
    test('is every discovered place one road away', () {
      // arrange
      final bloc = _bloc(world: _knowingAll());

      // act
      final where = bloc.state.destinationsFrom(residuumWorld);

      // assert
      expect(where.map((node) => node.id), [northgate, cryptNode]);
    });

    test('leaves out what the hero has not heard of', () {
      // arrange
      final bloc = _bloc();

      // act
      final where = bloc.state.destinationsFrom(residuumWorld);

      // assert
      expect(where.map((node) => node.id), [cryptNode]);
    });

    test('never offers the place the hero is standing on', () {
      // arrange
      final bloc = _bloc(world: atTheCrypt());

      // act
      final where = bloc.state.destinationsFrom(residuumWorld);

      // assert
      expect(where.map((node) => node.id), isNot(contains(cryptNode)));
    });
  });
}

/// A world whose first day out of the crypt, bound for Northgate, is a fight.
///
/// The crypt is the one place a hero can set out from that is not their home, so
/// it is the only journey whose origin and whose waking-place are different
/// nodes — which makes it the only one that can tell "wake at home" apart from
/// "wake where you set out from". Every other test here starts at a town, where
/// the two are the same node and the distinction is invisible.
const int _dangerousFromTheCrypt = 2;

/// A world whose first day out of Stonebridge is a fight.
///
/// Swept off the shipped derivation rather than chosen: day one of world 10
/// rolls under the Stonebridge-to-crypt road's danger of 15. World 909, which
/// every other test here walks, rolls 35 and 83 on its first two days and so
/// walks both of them quietly.
const int _dangerousWorld = 10;
