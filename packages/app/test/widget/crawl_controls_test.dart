import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/crawl_action_row.dart';
import 'package:residuum_app/game/dungeon_palette.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/game_screen.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../support/phone.dart';

/// A plain walled room, wide enough to carry a hero and its loot.
const _dungeonArena = '''
#######
#.....#
#.....#
#######''';

/// An unwalled patch of road: floor runs to both x edges, so a hero at
/// column zero is on the outermost ring without a wall in the way.
const _roadArena = '''
.......
.......
.......''';

Actor _hero(Position at, {int hp = 20}) => Actor(
  id: 'hero',
  name: 'you',
  glyph: '@',
  position: at,
  hp: hp,
  maxHp: 20,
  attackMin: 4,
  attackMax: 4,
  speed: 10,
  energy: actThreshold,
);

List<Item> _twoPotions() => const [
  Item(id: 'potion-1', base: healingPotion, rarity: Rarity.common),
  Item(id: 'potion-2', base: healingPotion, rarity: Rarity.common),
];

/// The bottom-floor stairs scene: standing on `stairsUp`, loot underfoot,
/// two potions carried — the five-control density the width arithmetic is
/// argued against (`Pick up`, `Drink` ×2, `Pack` ×2, `Ascend <`, `Finish`).
GameState _stairsScene() {
  final map = FloorMap.parse(_dungeonArena);
  const heroAt = Position(1, 1);
  final visible = computeFov(map, heroAt, fovRadius);
  return GameState(
    map: map,
    hero: _hero(heroAt),
    monsters: const [],
    rng: Rng(1),
    lootRng: Rng(2),
    visible: visible,
    explored: {...visible},
    buildFloor: (depth) => throw StateError('no floor below'),
    depth: deepestDepth,
    stairsUp: heroAt,
    groundItems: {
      heroAt: [
        const Item(id: 'floor-loot', base: ironSword, rarity: Rarity.common),
      ],
    },
    inventory: _twoPotions(),
  );
}

/// The outermost-ring road scene: a live monster not holding reach, loot
/// underfoot, two potions carried — the road's own five-control density
/// (`Pick up`, `Drink` ×2, `Pack` ×2, `Wait`, `Flee`).
GameState _roadScene() {
  final map = FloorMap.parse(_roadArena);
  const heroAt = Position(0, 1);
  final visible = computeFov(map, heroAt, fovRadius);
  return GameState(
    map: map,
    hero: _hero(heroAt),
    monsters: [
      Actor(
        id: 'ghoul-1',
        name: 'the ghoul',
        glyph: 'g',
        position: const Position(5, 1),
        hp: 10,
        maxHp: 10,
        attackMin: 3,
        attackMax: 3,
        speed: 10,
        energy: actThreshold,
      ),
    ],
    rng: Rng(1),
    lootRng: Rng(2),
    visible: visible,
    explored: {...visible},
    buildFloor: (depth) => throw StateError('no floor below'),
    isEncounter: true,
    groundItems: {
      heroAt: [
        const Item(id: 'road-loot', base: ironSword, rarity: Rarity.common),
      ],
    },
    inventory: _twoPotions(),
  );
}

/// A bare landing on `stairsDown`, staged only to put `Descend >` on the row.
GameState _stairsDownScene() {
  final map = FloorMap.parse(_dungeonArena);
  const heroAt = Position(1, 1);
  final visible = computeFov(map, heroAt, fovRadius);
  return GameState(
    map: map,
    hero: _hero(heroAt),
    monsters: const [],
    rng: Rng(1),
    lootRng: Rng(2),
    visible: visible,
    explored: {...visible},
    buildFloor: (depth) => throw StateError('no floor below'),
    stairsDown: heroAt,
  );
}

/// A game-over dungeon scene, staged only to prove a disabled control reads
/// as it does today.
GameState _gameOverScene() {
  final map = FloorMap.parse(_dungeonArena);
  const heroAt = Position(1, 1);
  final visible = computeFov(map, heroAt, fovRadius);
  return GameState(
    map: map,
    hero: _hero(heroAt, hp: 0),
    monsters: const [],
    rng: Rng(1),
    lootRng: Rng(2),
    visible: visible,
    explored: {...visible},
    buildFloor: (depth) => throw StateError('no floor below'),
    isGameOver: true,
    inventory: _twoPotions(),
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

Finder _chip(String id) => find.byKey(ValueKey(id));

void _expectAction(String id, {required String label, String? metadata}) {
  final chip = _chip(id);
  expect(chip, findsOneWidget, reason: id);
  expect(
    find.descendant(of: chip, matching: find.text(label)),
    findsOneWidget,
    reason: label,
  );
  if (metadata != null) {
    expect(
      find.descendant(of: chip, matching: find.text(metadata)),
      findsOneWidget,
      reason: metadata,
    );
  }
}

void _expectIcon(String id, {required String label, String? metadata}) {
  _expectAction(id, label: label, metadata: metadata);
  expect(
    find.descendant(of: _chip(id), matching: find.byType(Image)),
    findsOneWidget,
    reason: id,
  );
}

void _expectNoIcon(String id, {required String label}) {
  _expectAction(id, label: label);
  expect(
    find.descendant(of: _chip(id), matching: find.byType(Image)),
    findsNothing,
    reason: id,
  );
}

/// The stable id of every chip under [actionRowKey], in layout order
/// (ascending top, then ascending left).
List<String> _controlOrder(WidgetTester tester) {
  final ids = [
    'drink',
    'pack',
    'pick-up',
    'gather',
    'wait',
    'flee',
    'move-on',
    'ascend',
    'descend',
    'leave-dungeon',
    'spells-overflow',
  ];
  final visibleIds = ids.where((id) => _chip(id).evaluate().isNotEmpty);
  final positioned = [
    for (final id in visibleIds) (id, tester.getTopLeft(_chip(id))),
  ];
  positioned.sort((one, other) {
    final byDy = one.$2.dy.compareTo(other.$2.dy);
    return byDy != 0 ? byDy : one.$2.dx.compareTo(other.$2.dx);
  });
  return [for (final entry in positioned) entry.$1];
}

void main() {
  group('the crawl control row at its worst real density', () {
    testWidgets('the worst dungeon density fits a phone un-ellipsised', (
      tester,
    ) async {
      // arrange
      final game = _stairsScene();

      // act
      await _openCrawl(tester, game);

      // assert
      _expectAction('pick-up', label: 'Pick up');
      _expectAction('drink', label: 'Drink', metadata: '×2');
      _expectAction('pack', label: 'Pack', metadata: '×2');
      _expectAction('ascend', label: 'Ascend <');
      _expectAction('leave-dungeon', label: doneControl);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the worst road density fits a phone un-ellipsised', (
      tester,
    ) async {
      // arrange
      final game = _roadScene();

      // act
      await _openCrawl(tester, game);

      // assert
      _expectAction('pick-up', label: 'Pick up');
      _expectAction('drink', label: 'Drink', metadata: '×2');
      _expectAction('pack', label: 'Pack', metadata: '×2');
      _expectAction('wait', label: 'Wait');
      _expectAction('flee', label: 'Flee');
      expect(tester.takeException(), isNull);
    });
  });

  group('the icon language on the control row', () {
    testWidgets('every icon-bearing control carries its icon and its word', (
      tester,
    ) async {
      // arrange - the stairs scene carries Drink, Pack and Ascend, plus two
      // text-only controls
      final stairs = _stairsScene();

      // act
      await _openCrawl(tester, stairs);

      // assert
      _expectIcon('drink', label: 'Drink', metadata: '×2');
      _expectIcon('pack', label: 'Pack', metadata: '×2');
      _expectIcon('ascend', label: 'Ascend <');
      _expectNoIcon('pick-up', label: 'Pick up');
      _expectNoIcon('leave-dungeon', label: doneControl);

      // arrange - the road scene is the only staged scene with Wait and Flee
      final road = _roadScene();

      // act
      await _openCrawl(tester, road);

      _expectIcon('wait', label: 'Wait');
      _expectNoIcon('flee', label: 'Flee');

      // arrange - a third scene, staged only to reach Descend >
      final descend = _stairsDownScene();

      // act
      await _openCrawl(tester, descend);

      _expectIcon('descend', label: 'Descend >');
    });

    testWidgets('an icon-bearing control announces itself', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        // arrange
        final game = _stairsScene();

        // act
        await _openCrawl(tester, game);

        // assert
        expect(find.bySemanticsLabel('Drink ×2'), findsOneWidget);
        expect(find.bySemanticsLabel('Pack ×2'), findsOneWidget);
        expect(find.bySemanticsLabel('Ascend <'), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('a disabled control reads as it does today', (tester) async {
      // arrange
      final game = _gameOverScene();

      // act
      await _openCrawl(tester, game);

      final drink = _chip('drink');
      expect(drink, findsOneWidget);
      _expectAction('drink', label: 'Drink', metadata: '×2');
      final inkWell = tester.widget<InkWell>(
        find.descendant(of: drink, matching: find.byType(InkWell)),
      );
      expect(inkWell.onTap, isNull);
      expect(
        find.descendant(of: drink, matching: find.byType(Image)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(actionRowKey),
          matching: find.textContaining('Underfoot:'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(actionRowKey),
          matching: find.textContaining('Here:'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(actionRowKey),
          matching: find.text(doneAtTheBottom),
        ),
        findsNothing,
      );
    });
  });

  group('the control set stays frozen', () {
    testWidgets('no control is added, removed, renamed or reordered', (
      tester,
    ) async {
      // arrange - the three staged scenes above, each with its own frozen
      // set and order
      final scenes = <String, (GameState, List<String>)>{
        'stairs': (
          _stairsScene(),
          ['pick-up', 'drink', 'pack', 'ascend', 'leave-dungeon'],
        ),
        'road': (_roadScene(), ['pick-up', 'drink', 'pack', 'wait', 'flee']),
        'stairs down': (
          _stairsDownScene(),
          ['pack', 'descend', 'leave-dungeon'],
        ),
      };

      for (final entry in scenes.entries) {
        final (game, expectedOrder) = entry.value;

        // act
        await _openCrawl(tester, game);

        // assert
        expect(
          _controlOrder(tester).toSet(),
          expectedOrder.toSet(),
          reason: entry.key,
        );
        expect(_controlOrder(tester), expectedOrder, reason: entry.key);
      }
    });
  });
}
