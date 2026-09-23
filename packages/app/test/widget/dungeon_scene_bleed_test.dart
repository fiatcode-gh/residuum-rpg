import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/crawl_action_row.dart';
import 'package:residuum_app/game/dungeon_palette.dart';
import 'package:residuum_app/game/dungeon_scene.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/game_screen.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../support/phone.dart';

// A room far taller and wider than any viewport this unit's chrome can leave
// for the map: 14 floor columns (504dp of floor at cameraCellSize=36, wider
// than a phone) and 30 floor rows (1080dp tall). The point is not the room's
// shape — it is that most of it always sits outside the camera's window, at
// every chrome density, so a camera that paints the whole world rather than
// clipping to its own box always has real tile content to leak.
const _interiorWidth = 14;
const _interiorHeight = 30;
const _totalWidth = _interiorWidth + 2;
const _heroAt = Position(8, 16);
const _ghoulAt = Position(9, 16);

String _bigArena() {
  final rows = <String>[
    '#' * _totalWidth,
    for (var i = 0; i < _interiorHeight; i++) '#${'.' * _interiorWidth}#',
    '#' * _totalWidth,
  ];
  return rows.join('\n');
}

Actor _hero() => const Actor(
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
);

Actor _ghoul() => const Actor(
  id: 'ghoul-1',
  name: 'the ghoul',
  glyph: 'g',
  position: _ghoulAt,
  hp: 10,
  maxHp: 10,
  attackMin: 3,
  attackMax: 3,
  speed: 10,
  energy: actThreshold,
);

/// The worst-legal-battle density from the contract's own evidence (every
/// spell known, the pack short of its cap, a gather node and loot underfoot,
/// the deepest floor's own stairs up) reproduced on a floor tall and wide
/// enough that most of it never fits in any viewport this chrome leaves —
/// which is the missing ingredient the small arenas in the sibling action-row
/// tests never supply.
GameState _worstLegalBattleOnATallFloor() {
  final map = FloorMap.parse(_bigArena());
  final visible = computeFov(map, _heroAt, fovRadius);
  return GameState(
    map: map,
    hero: _hero(),
    monsters: [_ghoul()],
    rng: Rng(1),
    lootRng: Rng(2),
    visible: visible,
    explored: {...visible},
    buildFloor: (depth) => throw StateError('no floor below'),
    depth: deepestDepth,
    spells: spellsById,
    knownSpells: spellsById.keys.toSet(),
    mana: 20,
    stairsUp: _heroAt,
    nodes: {_heroAt: GatherKind.herbPatch},
    groundItems: {
      _heroAt: [
        const Item(id: 'floor-loot-1', base: ironSword, rarity: Rarity.common),
        const Item(
          id: 'floor-loot-2',
          base: bookOfFrostLance,
          rarity: Rarity.common,
        ),
      ],
    },
    inventory: [
      for (var index = 0; index < 12; index++)
        Item(id: 'potion-$index', base: healingPotion, rarity: Rarity.common),
      for (var index = 0; index < 7; index++)
        Item(id: 'gear-$index', base: ironSword, rarity: Rarity.common),
    ],
  );
}

Future<GameBloc> _openCrawl(WidgetTester tester, GameState game) async {
  await onAPhone(tester);
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

/// How many separate `dy` bands the action row's chips fall into — one band
/// per wrapped run.
int _actionRowRunCount(WidgetTester tester) {
  final chips = find.descendant(
    of: find.descendant(
      of: find.byKey(actionRowKey),
      matching: find.byType(Wrap),
    ),
    matching: find.byWidgetPredicate(
      (widget) => widget.key is ValueKey<String>,
    ),
  );
  final tops = [
    for (var index = 0; index < chips.evaluate().length; index++)
      tester.getTopLeft(chips.at(index)).dy,
  ]..sort();
  final runs = <double>[];
  for (final top in tops) {
    if (runs.isEmpty || (top - runs.last).abs() >= 1) runs.add(top);
  }
  return runs.length;
}

/// Renders the live [game] in isolation, on a canvas taller than its own
/// reported box by [marginAbove]/[marginBelow] on each side, with every
/// pixel pre-filled with a sentinel colour no dungeon palette ever produces.
/// A non-sentinel pixel above row [marginAbove] or below
/// `marginAbove + boxHeight` proves the game painted outside the box its
/// widget was actually given — the same [FlameGame.render] call
/// `GameRenderBox.paint` makes in the real tree, just recorded onto a larger
/// surface so the overflow itself becomes an observable pixel instead of
/// being cropped away by the very screenshot that would otherwise hide it.
Future<ui.Image> _renderWithMargin(
  FlameGame game, {
  required Size box,
  required double marginAbove,
  required double marginBelow,
}) async {
  const sentinel = Color(0xFFFF00FF);
  final width = box.width.round();
  final height = (marginAbove + box.height + marginBelow).round();
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder)
    ..drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()..color = sentinel,
    )
    ..translate(0, marginAbove);
  game.render(canvas);
  final picture = recorder.endRecording();
  try {
    return await picture.toImage(width, height);
  } finally {
    picture.dispose();
  }
}

Future<Color> _pixelAt(ui.Image image, int x, int y) async {
  final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final offset = (y * image.width + x) * 4;
  return Color.fromARGB(
    rgba!.getUint8(offset + 3),
    rgba.getUint8(offset),
    rgba.getUint8(offset + 1),
    rgba.getUint8(offset + 2),
  );
}

void main() {
  testWidgets(
    'the dungeon canvas paints only inside the box the Column gives it, '
    'even at worst-legal-battle density on a floor taller than the viewport',
    (tester) async {
      // arrange - the exact density the contract names: battle open, the
      // action row wrapped to more than one run, on a floor that cannot fit
      // in any viewport this chrome leaves.
      await _openCrawl(tester, _worstLegalBattleOnATallFloor());

      expect(
        find.byKey(const Key('dock-backing')),
        findsOneWidget,
        reason:
            'BattleDock must be mounted for this to be the contract\'s '
            'worst-legal-battle density',
      );
      expect(
        _actionRowRunCount(tester),
        greaterThan(1),
        reason:
            'the action row must wrap to more than one run for this to '
            'be the worst-legal-battle density',
      );

      final mapRect = tester.getRect(find.byKey(dungeonSceneSlotKey));
      final depthPaint = find.descendant(
        of: find.byKey(dungeonSceneKey),
        matching: find.byType(CustomPaint),
      );
      expect(depthPaint, findsOneWidget);
      expect(tester.getRect(depthPaint), mapRect);
      final game = tester
          .widget<GameWidget<FlameGame>>(find.byKey(dungeonSceneKey))
          .game!;

      // act - render the live game in isolation on a canvas 200dp taller
      // than its own reported box on each side, sentinel-filled first.
      const margin = 200.0;
      final image = await tester.runAsync(
        () => _renderWithMargin(
          game,
          box: mapRect.size,
          marginAbove: margin,
          marginBelow: margin,
        ),
      );
      addTearDown(() => image!.dispose());

      // assert - nothing painted above the box's own top edge (row
      // `margin - 1`, i.e. one pixel above local y=0) or below its own
      // bottom edge (row `margin + box.height`, i.e. one pixel below local
      // y=box.height). The box's own centre column is used because the
      // 14-column, 504dp-wide room is clamped flush to the viewport's left
      // edge and fills it entirely, so every column of the box sees real
      // floor content once the camera's window is exceeded.
      const sentinel = Color(0xFFFF00FF);
      final x = (mapRect.width / 2).round();
      final abovePixel = await tester.runAsync(
        () => _pixelAt(image!, x, (margin - 1).round()),
      );
      final belowPixel = await tester.runAsync(
        () => _pixelAt(image!, x, (margin + mapRect.height).round()),
      );

      expect(
        abovePixel,
        sentinel,
        reason:
            'the dungeon canvas painted a real tile one pixel above its own '
            'top edge (mapRect height ${mapRect.height}dp) instead of '
            'leaving the sentinel background untouched',
      );
      expect(
        belowPixel,
        sentinel,
        reason:
            'the dungeon canvas painted a real tile one pixel below its own '
            'bottom edge (mapRect height ${mapRect.height}dp) instead of '
            'leaving the sentinel background untouched',
      );
    },
  );
}
