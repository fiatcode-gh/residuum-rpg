import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/game_screen.dart';
import 'package:residuum_app/game/dungeon_palette.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../support/phone.dart';

const _arena = '''
#######
#.....#
#.....#
#######''';

const _heroAt = Position(1, 1);

GameState _crawl({
  Map<Position, GatherKind> nodes = const {},
  Map<MaterialId, int> materials = const {},
  Map<Position, List<Item>> groundItems = const {},
  Map<SkillId, SkillState> skills = untrainedSkills,
}) {
  final map = FloorMap.parse(_arena);
  final visible = computeFov(map, _heroAt, fovRadius);
  return GameState(
    map: map,
    hero: const Actor(
      id: 'hero',
      name: 'you',
      glyph: '@',
      position: _heroAt,
      hp: 20,
      maxHp: 20,
      attackMin: 4,
      attackMax: 4,
      speed: 10,
      energy: actThreshold,
    ),
    monsters: const [],
    rng: Rng(1),
    lootRng: Rng(2),
    visible: visible,
    explored: {...visible},
    buildFloor: (depth) => throw StateError('no floor below'),
    nodes: nodes,
    materials: materials,
    groundItems: groundItems,
    skills: skills,
  );
}

Future<GameBloc> _openCrawl(WidgetTester tester, GameState game) async {
  await onAPhone(tester);
  final bloc = GameBloc(game: game, stepDelay: Duration.zero);
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider.value(
        value: bloc,
        child: const GameScreen(palette: DungeonPalette.crypt),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return bloc;
}

void main() {
  group('the control on a node', () {
    testWidgets('is not offered anywhere else on the floor', (tester) async {
      // arrange
      final game = _crawl(nodes: {const Position(4, 2): GatherKind.oreVein});

      // act
      final bloc = await _openCrawl(tester, game);

      // assert - a control that is always there is a control a player taps by
      // mistake, and the rules charge nothing for it precisely because the
      // screen was not supposed to offer it
      expect(find.widgetWithText(FilledButton, 'Mine'), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Gather'), findsNothing);
      addTearDown(bloc.close);
    });

    testWidgets('says Mine over a vein', (tester) async {
      // arrange
      final game = _crawl(nodes: {_heroAt: GatherKind.oreVein});

      // act
      final bloc = await _openCrawl(tester, game);

      // assert
      expect(find.widgetWithText(FilledButton, 'Mine'), findsOneWidget);
      addTearDown(bloc.close);
    });

    testWidgets('says Gather over a patch', (tester) async {
      // arrange
      final game = _crawl(nodes: {_heroAt: GatherKind.herbPatch});

      // act
      final bloc = await _openCrawl(tester, game);

      // assert - you mine a seam and you pick a plant
      expect(find.widgetWithText(FilledButton, 'Gather'), findsOneWidget);
      addTearDown(bloc.close);
    });

    testWidgets('names what is underfoot in a mark and a word', (tester) async {
      // arrange
      final game = _crawl(nodes: {_heroAt: GatherKind.herbPatch});

      // act
      final bloc = await _openCrawl(tester, game);

      // assert
      expect(find.textContaining('herb patch'), findsOneWidget);
      expect(find.textContaining(GatherKind.herbPatch.marking), findsWidgets);
      addTearDown(bloc.close);
    });

    testWidgets('working it takes the control away and the material up', (
      tester,
    ) async {
      // arrange
      final game = _crawl(nodes: {_heroAt: GatherKind.oreVein});
      final bloc = await _openCrawl(tester, game);

      // act
      await tester.tap(find.widgetWithText(FilledButton, 'Mine'));
      await tester.pumpAndSettle();

      // assert
      expect(find.widgetWithText(FilledButton, 'Mine'), findsNothing);
      expect(bloc.state.game.materials, {MaterialId.ore: 1});
      addTearDown(bloc.close);
    });

    testWidgets('shares the row with Pick up without crowding it out', (
      tester,
    ) async {
      // arrange
      final game = _crawl(
        nodes: {_heroAt: GatherKind.oreVein},
        groundItems: {
          _heroAt: [
            const Item(id: 'floor-1-1', base: ironSword, rarity: Rarity.common),
          ],
        },
      );

      // act
      final bloc = await _openCrawl(tester, game);

      // assert - both controls fit, and neither is ellipsised into nonsense;
      // 'Mine' is four letters for exactly this reason
      expect(find.widgetWithText(FilledButton, 'Pick up'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Mine'), findsOneWidget);
      expect(tester.takeException(), isNull);
      addTearDown(bloc.close);
    });
  });
}
