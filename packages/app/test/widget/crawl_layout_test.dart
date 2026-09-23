import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/combat_panel.dart';
import 'package:residuum_app/game/crawl_action_row.dart';
import 'package:residuum_app/game/crawl_header.dart';
import 'package:residuum_app/game/crawl_style.dart';
import 'package:residuum_app/game/dungeon_palette.dart';
import 'package:residuum_app/game/dungeon_scene.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/game_screen.dart';
import 'package:residuum_app/game/grid_geometry.dart';
import 'package:residuum_app/game/hero_panel.dart';
import 'package:residuum_app/game/log_drawer.dart';
import 'package:residuum_app/game/map_callout.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../support/phone.dart';

const _arena = '''
#######
#.....#
#.....#
#.....#
#######''';

const _heroAt = Position(2, 2);
const _adjacentToHero = Position(3, 2);

Actor _actor(String id, Position at, {String glyph = '@', int speed = 10}) =>
    Actor(
      id: id,
      name: id,
      glyph: glyph,
      position: at,
      hp: 20,
      maxHp: 20,
      attackMin: 4,
      attackMax: 4,
      speed: speed,
      energy: actThreshold,
    );

/// A quiet room with nothing nearby, so `isBattleOpen` is false and the
/// action bar's only slot is Pack.
GameState _exploringGame() {
  final map = FloorMap.parse(_arena);
  final visible = computeFov(map, _heroAt, fovRadius);
  return GameState(
    map: map,
    hero: _actor('hero', _heroAt),
    monsters: const [],
    rng: Rng(1),
    lootRng: Rng(2),
    buildFloor: (depth) => throw StateError('this arena has no floor below'),
    visible: visible,
    explored: {...visible},
  );
}

/// The hero and one live ghoul stand adjacent, so `isBattleOpen` is true.
GameState _battleGame({
  int ghoulSpeed = 10,
  Map<String, Spell> spells = const {},
  Set<String> knownSpells = const {},
  int mana = 0,
}) {
  final map = FloorMap.parse(_arena);
  final visible = computeFov(map, _heroAt, fovRadius);
  return GameState(
    map: map,
    hero: _actor('hero', _heroAt),
    monsters: [
      _actor('ghoul-1', _adjacentToHero, glyph: 'g', speed: ghoulSpeed),
    ],
    rng: Rng(1),
    lootRng: Rng(2),
    buildFloor: (depth) => throw StateError('this arena has no floor below'),
    visible: visible,
    explored: {...visible},
    spells: spells,
    knownSpells: knownSpells,
    mana: mana,
  );
}

/// A visible ghoul two cells away, outside engagement range — known but not
/// adjacent, so tapping it inspects rather than bumps.
GameState _watchedGame() => _exploringGame().copyWith(
  monsters: [_actor('ghoul-1', const Position(4, 2), glyph: 'g')],
);

/// [_exploringGame] plus a gather node underfoot — the note-invariance
/// proof's other half.
GameState _noteScene() =>
    _exploringGame().copyWith(nodes: {_heroAt: GatherKind.oreVein});

const _openArena = '''
...
...
...''';

/// The bar's own worst case, lit all at once: drink, the three readied
/// spells, the overflow, wait, pick up, gather, pack, flee, descend and
/// leave — twelve slots deep, none of which the map floor may ever answer
/// to.
GameState _twelveActionScene() {
  final map = FloorMap.parse(_openArena);
  const heroAt = Position(0, 0);
  final visible = computeFov(map, heroAt, fovRadius);
  return GameState(
    map: map,
    hero: _actor('hero', heroAt),
    monsters: [_actor('ghoul-1', const Position(1, 0), glyph: 'g')],
    rng: Rng(1),
    lootRng: Rng(2),
    buildFloor: (depth) => throw StateError('this arena has no floor below'),
    visible: visible,
    explored: {...visible},
    isEncounter: true,
    stairsDown: heroAt,
    nodes: {heroAt: GatherKind.oreVein},
    groundItems: {
      heroAt: [
        const Item(id: 'floor-loot', base: ironSword, rarity: Rarity.common),
      ],
    },
    inventory: const [
      Item(id: 'potion-1', base: healingPotion, rarity: Rarity.common),
    ],
    spells: spellsById,
    knownSpells: const {'firebolt', 'mend', 'ward', 'bind'},
    mana: 10,
  );
}

Future<GameBloc> _openCrawl(WidgetTester tester, GameState game) async {
  await onTheTargetPhone(tester);
  final bloc = GameBloc(game: game, stepDelay: Duration.zero);
  addTearDown(bloc.close);
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

double _surfaceWidth(WidgetTester tester) =>
    tester.view.physicalSize.width / tester.view.devicePixelRatio;

/// Taps one tile of the exploration arena, through the scene's own geometry.
Future<void> _tapTile(WidgetTester tester, Position tile) async {
  final scene = find.byKey(dungeonSceneKey);
  final size = tester.getSize(scene);
  final geometry = GridGeometry.camera(size, 7, 5, _heroAt);
  final local = geometry.centreOf(tile);
  await tester.tapAt(tester.getTopLeft(scene) + local);
}

void main() {
  testWidgets(
    'exploration renders header, map, hero panel and peek in the mock '
    'order, each at its own fixed height, and the map clears its floor',
    (tester) async {
      await _openCrawl(tester, _exploringGame());

      final header = tester.getRect(find.byType(CrawlHeader));
      final map = tester.getRect(find.byKey(dungeonSceneSlotKey));
      final heroPanel = tester.getRect(find.byType(HeroPanel));
      final peek = tester.getRect(find.byKey(logPeekKey));
      final bar = tester.getRect(find.byKey(actionRowKey));
      debugPrint(
        'U16.5 Task 11 exploration header=$header map=$map '
        'heroPanel=$heroPanel peek=$peek bar=$bar',
      );

      expect(header.height, closeTo(88, 0.01));
      expect(heroPanel.height, closeTo(102, 0.01));
      expect(peek.height, closeTo(96, 0.01));
      expect(bar.height, closeTo(60, 0.01));
      expect(map.height, greaterThanOrEqualTo(394.0));

      expect(header.bottom, closeTo(map.top, 0.01));
      expect(map.bottom + crawlPanelGap, closeTo(heroPanel.top, 0.01));
      expect(heroPanel.bottom + crawlGap, closeTo(peek.top, 0.01));
      expect(peek.bottom + crawlGap, closeTo(bar.top, 0.01));
    },
  );

  testWidgets(
    'battle renders header, timeline, map, combat panel and peek in the '
    'mock order, each at its own fixed height, and the map still clears its '
    'floor',
    (tester) async {
      await _openCrawl(tester, _battleGame());

      final header = tester.getRect(find.byType(CrawlHeader));
      final dock = tester.getRect(find.byKey(const Key('dock-backing')));
      final map = tester.getRect(find.byKey(dungeonSceneSlotKey));
      final combatPanel = tester.getRect(find.byType(CombatPanel));
      final peek = tester.getRect(find.byKey(logPeekKey));
      final bar = tester.getRect(find.byKey(actionRowKey));
      debugPrint(
        'U16.5 Task 11 battle header=$header dock=$dock map=$map '
        'combatPanel=$combatPanel peek=$peek bar=$bar',
      );

      expect(header.height, closeTo(88, 0.01));
      expect(dock.height, closeTo(58, 0.01));
      expect(combatPanel.height, closeTo(124, 0.01));
      expect(peek.height, closeTo(96, 0.01));
      expect(bar.height, closeTo(60, 0.01));
      expect(map.height, greaterThanOrEqualTo(306.5));

      expect(header.bottom, closeTo(dock.top, 0.01));
      expect(dock.bottom, closeTo(map.top, 0.01));
      expect(map.bottom + crawlPanelGap, closeTo(combatPanel.top, 0.01));
      expect(combatPanel.bottom + crawlGap, closeTo(peek.top, 0.01));
      expect(peek.bottom + crawlGap, closeTo(bar.top, 0.01));
    },
  );

  testWidgets(
    'the map spans the full width and the timeline is inset by the gutter '
    'on both sides',
    (tester) async {
      await _openCrawl(tester, _battleGame());
      final width = _surfaceWidth(tester);
      final map = tester.getRect(find.byKey(dungeonSceneSlotKey));
      final dock = tester.getRect(find.byKey(const Key('dock-backing')));

      expect(map.left, 0);
      expect(map.right, closeTo(width, 0.01));
      expect(dock.left, closeTo(crawlGutter, 0.01));
      expect(dock.right, closeTo(width - crawlGutter, 0.01));
    },
  );

  testWidgets('arming a spell from the bar never moves the map', (
    tester,
  ) async {
    final bloc = await _openCrawl(
      tester,
      _battleGame(
        spells: spellsById,
        knownSpells: const {'firebolt'},
        mana: 10,
      ),
    );
    final unarmedMapRect = tester.getRect(find.byKey(dungeonSceneSlotKey));

    bloc.add(const SkillArmed('firebolt'));
    await tester.pumpAndSettle();

    expect(bloc.state.armedSpellId, 'firebolt');
    expect(tester.getRect(find.byKey(dungeonSceneSlotKey)), unarmedMapRect);
  });

  testWidgets(
    'the action row\'s own legal-action count never moves the map, from the '
    'battle floor of wait and pack to all twelve slots lit',
    (tester) async {
      await _openCrawl(tester, _battleGame());
      final fewActionsMapRect = tester.getRect(find.byKey(dungeonSceneSlotKey));
      expect(find.byKey(const ValueKey('wait')), findsOneWidget);
      expect(find.byKey(const ValueKey('pack')), findsOneWidget);
      expect(find.byKey(const ValueKey('drink')), findsNothing);

      await _openCrawl(tester, _twelveActionScene());
      final twelveActionMapRect = tester.getRect(
        find.byKey(dungeonSceneSlotKey),
      );
      for (final id in [
        'drink',
        'spell:firebolt',
        'spell:mend',
        'spell:ward',
        'spells-overflow',
        'wait',
        'pick-up',
        'gather',
        'pack',
        'flee',
        'descend',
        'leave-dungeon',
      ]) {
        expect(find.byKey(ValueKey(id)), findsOneWidget, reason: id);
      }

      expect(twelveActionMapRect, fewActionsMapRect);
    },
  );

  testWidgets(
    'cycling the log extent peek, half, full and back leaves the map slot '
    'and the peek unchanged',
    (tester) async {
      await _openCrawl(tester, _exploringGame());

      final mapRect = tester.getRect(find.byKey(dungeonSceneSlotKey));
      final peekRect = tester.getRect(find.byKey(logPeekKey));

      await tester.tap(find.byKey(logPeekKey));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(dungeonSceneSlotKey)), mapRect);
      expect(tester.getRect(find.byKey(logPeekKey)), peekRect);

      await tester.tap(find.byKey(logHandleKey));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(dungeonSceneSlotKey)), mapRect);
      expect(tester.getRect(find.byKey(logPeekKey)), peekRect);

      await tester.tap(find.byKey(logHandleKey));
      await tester.pumpAndSettle();
      expect(find.byKey(logDrawerKey), findsNothing);
      expect(tester.getRect(find.byKey(dungeonSceneSlotKey)), mapRect);
      expect(tester.getRect(find.byKey(logPeekKey)), peekRect);
    },
  );

  testWidgets('a note over the map never resizes it', (tester) async {
    await _openCrawl(tester, _exploringGame());
    final mapRectNoNotes = tester.getRect(find.byKey(dungeonSceneSlotKey));

    await _openCrawl(tester, _noteScene());
    final mapRect = tester.getRect(find.byKey(dungeonSceneSlotKey));
    expect(mapRect, mapRectNoNotes);

    final note = find.descendant(
      of: find.byKey(dungeonSceneSlotKey),
      matching: find.textContaining('Underfoot:'),
    );
    expect(note, findsOneWidget);
  });

  testWidgets(
    'inspecting a far monster opens the map callout without moving the map',
    (tester) async {
      await _openCrawl(tester, _exploringGame());
      final mapRectNoInspect = tester.getRect(find.byKey(dungeonSceneSlotKey));

      await _openCrawl(tester, _watchedGame());
      final mapRectBefore = tester.getRect(find.byKey(dungeonSceneSlotKey));
      expect(mapRectBefore, mapRectNoInspect);

      await _tapTile(tester, const Position(4, 2));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byKey(mapCalloutKey), findsOneWidget);
      expect(tester.getRect(find.byKey(dungeonSceneSlotKey)), mapRectBefore);
    },
  );
}
