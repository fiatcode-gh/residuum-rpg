import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/action_bar.dart';
import 'package:residuum_app/game/crawl_hud.dart';
import 'package:residuum_app/game/crawl_menu.dart';
import 'package:residuum_app/game/crawl_style.dart';
import 'package:residuum_app/game/dungeon_palette.dart';
import 'package:residuum_app/game/dungeon_scene.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/game_screen.dart';
import 'package:residuum_app/game/grid_geometry.dart';
import 'package:residuum_app/game/log_drawer.dart';
import 'package:residuum_app/game/log_row.dart';
import 'package:residuum_app/game/target_card.dart';
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
GameState _exploringGame({
  Map<String, Spell> spells = const {},
  Set<String> knownSpells = const {},
  int mana = 0,
}) {
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
    spells: spells,
    knownSpells: knownSpells,
    mana: mana,
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
GameState _watchedGame({
  Map<String, Spell> spells = const {},
  Set<String> knownSpells = const {},
  int mana = 0,
}) => _exploringGame(
  spells: spells,
  knownSpells: knownSpells,
  mana: mana,
).copyWith(monsters: [_actor('ghoul-1', const Position(4, 2), glyph: 'g')]);

/// [_exploringGame] plus a gather node underfoot — the note-invariance
/// proof's other half.
GameState _noteScene() =>
    _exploringGame().copyWith(nodes: {_heroAt: GatherKind.oreVein});

Future<GameBloc> _openCrawl(
  WidgetTester tester,
  GameState game, {
  TextScaler? textScaler,
}) async {
  await onTheTargetPhone(tester);
  final bloc = GameBloc(game: game, stepDelay: Duration.zero);
  addTearDown(bloc.close);
  final app = MaterialApp(
    home: BlocProvider.value(
      value: bloc,
      child: const GameScreen(palette: DungeonPalette.crypt),
    ),
  );
  await tester.pumpWidget(
    textScaler == null
        ? app
        : MediaQuery(
            data: MediaQueryData(textScaler: textScaler),
            child: app,
          ),
  );
  await tester.pumpAndSettle();
  return bloc;
}

/// The hero engaged by four monsters at once — the worst case the strip's
/// own `+N` cue exists for.
GameState _crowdedBattleGame({
  Map<String, Spell> spells = const {},
  Set<String> knownSpells = const {},
  int mana = 0,
}) => _exploringGame(spells: spells, knownSpells: knownSpells, mana: mana)
    .copyWith(
      monsters: [
        _actor('ghoul-1', const Position(1, 2), glyph: 'g'),
        _actor('ghoul-2', const Position(3, 2), glyph: 'g'),
        _actor('ghoul-3', const Position(2, 1), glyph: 'g'),
        _actor('ghoul-4', const Position(2, 3), glyph: 'g'),
      ],
    );

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
    'regions run HUD, map, log row, bar, menu top to bottom, each clear of '
    'the safe body',
    (tester) async {
      await _openCrawl(tester, _exploringGame());

      final hud = tester.getRect(find.byKey(crawlHudKey));
      final map = tester.getRect(find.byKey(dungeonSceneSlotKey));
      final logRow = tester.getRect(find.byKey(logRowKey));
      final bar = tester.getRect(find.byKey(actionBarKey));
      final menu = tester.getRect(find.byKey(crawlMenuKey));
      final surfaceHeight =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;

      expect(hud.top, closeTo(34.9, 0.5));
      expect(hud.bottom, closeTo(map.top, 0.01));
      expect(map.bottom + crawlPanelGap, closeTo(logRow.top, 0.01));
      expect(logRow.bottom + crawlPanelGap, closeTo(bar.top, 0.01));
      expect(bar.bottom + crawlGap, closeTo(menu.top, 0.01));
      expect(
        menu.bottom + crawlBottomGap,
        closeTo(surfaceHeight - crawlGestureClear, 0.5),
      );
    },
  );

  testWidgets(
    'the HUD, map, log row, bar and menu rects are identical, and the menu '
    'order unchanged, in exploration, armed, Watched and battle',
    (tester) async {
      const knownSpells = {'firebolt'};
      final bloc = await _openCrawl(
        tester,
        _exploringGame(spells: spellsById, knownSpells: knownSpells, mana: 10),
      );
      final hud = tester.getRect(find.byKey(crawlHudKey));
      final hp = tester.getRect(find.byKey(hpMeterKey));
      final mana = tester.getRect(find.byKey(manaMeterKey));
      final gold = tester.getRect(find.byKey(crawlGoldKey));
      final map = tester.getRect(find.byKey(dungeonSceneSlotKey));
      final logRow = tester.getRect(find.byKey(logRowKey));
      final bar = tester.getRect(find.byKey(actionBarKey));
      final menu = tester.getRect(find.byKey(crawlMenuKey));
      const menuSlotIds = [
        'menu-quests',
        'menu-spells',
        'menu-quick',
        'menu-hero',
      ];
      final menuOrder = [
        for (final id in menuSlotIds)
          tester.getTopLeft(find.byKey(ValueKey(id))).dx,
      ];

      void expectSameLayout() {
        expect(tester.getRect(find.byKey(crawlHudKey)), hud);
        expect(tester.getRect(find.byKey(hpMeterKey)), hp);
        expect(tester.getRect(find.byKey(manaMeterKey)), mana);
        expect(tester.getRect(find.byKey(crawlGoldKey)), gold);
        expect(tester.getRect(find.byKey(dungeonSceneSlotKey)), map);
        expect(tester.getRect(find.byKey(logRowKey)), logRow);
        expect(tester.getRect(find.byKey(actionBarKey)), bar);
        expect(tester.getRect(find.byKey(crawlMenuKey)), menu);
        expect([
          for (final id in menuSlotIds)
            tester.getTopLeft(find.byKey(ValueKey(id))).dx,
        ], menuOrder);
      }

      bloc.add(const SkillArmed('firebolt'));
      await tester.pumpAndSettle();
      expectSameLayout();

      await _openCrawl(
        tester,
        _watchedGame(spells: spellsById, knownSpells: knownSpells, mana: 10),
      );
      expectSameLayout();

      await _openCrawl(
        tester,
        _battleGame(spells: spellsById, knownSpells: knownSpells, mana: 10),
      );
      expectSameLayout();
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

    expect(
      find.descendant(
        of: find.byKey(dungeonSceneSlotKey),
        matching: find.textContaining('Underfoot:'),
      ),
      findsNothing,
    );
    final note = find.descendant(
      of: find.byKey(actionBarKey),
      matching: find.textContaining('Underfoot:'),
    );
    expect(note, findsOneWidget);
  });

  testWidgets(
    'inspecting a far monster opens the target card without moving the map',
    (tester) async {
      await _openCrawl(tester, _exploringGame());
      final mapRectNoInspect = tester.getRect(find.byKey(dungeonSceneSlotKey));

      await _openCrawl(tester, _watchedGame());
      final mapRectBefore = tester.getRect(find.byKey(dungeonSceneSlotKey));
      expect(mapRectBefore, mapRectNoInspect);

      await _tapTile(tester, const Position(4, 2));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byKey(targetCardKey), findsOneWidget);
      expect(tester.getRect(find.byKey(dungeonSceneSlotKey)), mapRectBefore);
    },
  );

  testWidgets('a crowded battle with every spell readied fits the screen at an '
      'ambient text scale the crawl clamps down to 1.3', (tester) async {
    await _openCrawl(
      tester,
      _crowdedBattleGame(
        spells: spellsById,
        knownSpells: spellsById.keys.toSet(),
        mana: 20,
      ),
      textScaler: const TextScaler.linear(2),
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(crawlHudKey), findsOneWidget);
    expect(find.byKey(crawlMenuKey), findsOneWidget);
  });
}
