import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/notice/notice.dart';
import 'package:residuum_app/town/tavern_screen.dart';
import 'package:residuum_app/town/town_bloc.dart';
import 'package:residuum_app/world/travel_messages.dart';
import 'package:residuum_app/world/world_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../support/phone.dart';

/// A hero who has heard of everywhere, standing at home.
Whereabouts _knowingAll() => newWhereabouts()
    .hearingOf(northgate)
    .hearingOf(seaCave)
    .hearingOf(ruinedKeep);

/// The tavern, under a real town bloc and a real world bloc.
Future<(TownBloc, WorldBloc)> _openTavern(
  WidgetTester tester, {
  Profile? profile,
  SaveNotice? townNotice,
  WorldBloc? world,
}) async {
  await onAPhone(tester);
  final hero = profile ?? newProfile(worldSeed: 4).copyWith(gold: 100);
  final town = TownBloc(profile: hero, notice: townNotice);
  final worldBloc =
      world ?? WorldBloc(world: newWhereabouts(), worldSeed: hero.worldSeed);
  await tester.pumpWidget(
    MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: town),
          BlocProvider.value(value: worldBloc),
        ],
        child: const TavernScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(town.close);
  addTearDown(worldBloc.close);
  return (town, worldBloc);
}

void main() {
  group('the tavern', () {
    testWidgets('both headings and the offer, when a place is undiscovered', (
      tester,
    ) async {
      // act
      await _openTavern(tester);

      // assert
      expect(find.text('WHAT THEY ARE SAYING'), findsOneWidget);
      expect(find.text('WHAT YOU HAVE BEEN TOLD'), findsOneWidget);
      expect(find.text('[!]'), findsOneWidget);
      expect(find.text('Ask about the roads'), findsOneWidget);
      expect(find.text('Ask $rumorPrice'), findsOneWidget);
    });

    testWidgets('the exhausted line, when every place is already discovered', (
      tester,
    ) async {
      // act
      await _openTavern(
        tester,
        world: WorldBloc(world: _knowingAll(), worldSeed: 4),
      );

      // assert
      expect(
        find.text(
          'Nobody here has anything left to tell you. '
          'You have heard of everywhere they know.',
        ),
        findsOneWidget,
      );
      expect(find.text('Ask $rumorPrice'), findsNothing);
    });

    testWidgets('the last six lines, newest first', (tester) async {
      // arrange - three rumors bought and two road fights survived widen the
      // log past six lines
      final teller = newProfile(worldSeed: 4).copyWith(gold: 1000);
      final world = WorldBloc(world: newWhereabouts(), worldSeed: 4);
      for (var bought = 0; bought < 3; bought++) {
        world.add(
          RumorHeard(
            buyRumor(teller, world.state.world, rumorPool, rumorPrice),
          ),
        );
        await world.stream.first;
      }
      world.add(const RoadFightOver(EncounterEnding.fled));
      await world.stream.first;
      world.add(const RoadFightOver(EncounterEnding.cleared));
      await world.stream.first;

      final seaCaveLine = rumorPool[2].line;
      final seaCaveRevealed = describeRevealed(residuumWorld, seaCave);
      final keepLine = rumorPool[3].line;
      final keepRevealed = describeRevealed(residuumWorld, ruinedKeep);
      final northgateLine = rumorPool[0].line;
      final northgateRevealed = describeRevealed(residuumWorld, northgate);

      // act
      await _openTavern(tester, world: world);

      // assert - the six most recent lines are on screen, newest first
      final order = [
        wonOnTheRoad,
        fledOnTheRoad,
        keepRevealed,
        keepLine,
        seaCaveRevealed,
        seaCaveLine,
      ];
      final positions = [
        for (final line in order) tester.getTopLeft(find.text(line)).dy,
      ];
      for (var i = 1; i < positions.length; i++) {
        expect(positions[i], greaterThan(positions[i - 1]), reason: order[i]);
      }

      // assert - the two oldest lines dropped off
      expect(find.text(northgateLine), findsNothing);
      expect(find.text(northgateRevealed), findsNothing);
    });

    testWidgets('Nothing yet., with an empty world log', (tester) async {
      // act
      await _openTavern(tester);

      // assert
      expect(find.text('Nothing yet.'), findsOneWidget);
    });

    testWidgets('the notice comes from either bloc, and sits above the offer', (
      tester,
    ) async {
      // arrange - a refusal from a purse too short to hear anything gives the
      // world its own notice
      final poor = newProfile(worldSeed: 4);
      final world = WorldBloc(world: newWhereabouts(), worldSeed: 4);
      world.add(
        RumorHeard(buyRumor(poor, world.state.world, rumorPool, rumorPrice)),
      );
      await world.stream.first;
      expect(world.state.notice?.sentence, 'you cannot afford that');

      // act + assert - a town notice with no world notice
      await _openTavern(
        tester,
        townNotice: const SentenceNotice('a town matter'),
        world: WorldBloc(world: newWhereabouts(), worldSeed: 4),
      );
      expect(find.text('— a town matter.'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('— a town matter.')).dy,
        lessThan(tester.getTopLeft(find.text('WHAT THEY ARE SAYING')).dy),
      );

      // act + assert - no town notice, a world notice
      await _openTavern(tester, world: world);
      expect(find.text('— you cannot afford that.'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('— you cannot afford that.')).dy,
        lessThan(tester.getTopLeft(find.text('WHAT THEY ARE SAYING')).dy),
      );

      // act + assert - both present, the town's sentence wins
      await _openTavern(
        tester,
        townNotice: const SentenceNotice('a town matter'),
        world: world,
      );
      expect(find.text('— a town matter.'), findsOneWidget);
      expect(find.text('— you cannot afford that.'), findsNothing);
      expect(
        tester.getTopLeft(find.text('— a town matter.')).dy,
        lessThan(tester.getTopLeft(find.text('WHAT THEY ARE SAYING')).dy),
      );
    });

    testWidgets('asking spends once and tells both blocs', (tester) async {
      // arrange
      final (town, world) = await _openTavern(
        tester,
        profile: newProfile(worldSeed: 4).copyWith(gold: 100),
      );
      final goldBefore = town.state.profile.gold;
      final discoveredBefore = world.state.world.discovered.length;

      // act
      await tester.tap(find.text('Ask $rumorPrice'));
      await tester.pumpAndSettle();

      // assert
      expect(town.state.profile.gold, goldBefore - rumorPrice);
      expect(world.state.world.discovered.length, discoveredBefore + 1);
    });
  });
}
