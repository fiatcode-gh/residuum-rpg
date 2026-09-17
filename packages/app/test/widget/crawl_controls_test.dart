import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
/// argued against (`Pick up`, `Drink (2)`, `Pack (2)`, `Ascend <`, `Finish`).
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
/// (`Pick up`, `Drink (2)`, `Pack (2)`, `Wait`, `Flee`).
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

/// Unit 12's no-squeeze proof, scoped to the chip row itself: every chip
/// label `RenderParagraph` under [actionRowKey] fits without exceeding its
/// line cap, and never runs narrower than the longest unbreakable word it
/// carries. Scoped narrower than [actionRowKey] on purpose — the conditional
/// sentence rows above the row (`doneAtTheBottom`, `Underfoot:`, `Here:`) are
/// untouched by this unit and wrap onto a second line by design; that is not
/// the defect this loop is proving against.
///
/// The `didExceedMaxLines` check below is a degenerate-path tripwire, not
/// the clipping proof — `_fitFor`'s own candidate search already discards
/// every column count that would exceed `crawlChipMaxLabelLines`, so it
/// cannot fail on any candidate the search accepts. It only guards the one
/// path that search does not cover: the no-legal-candidate fallback, which
/// lays out at the full available width with no line-count check of its
/// own. The real no-squeeze proof is the intrinsic-width check after it.
void _expectNoSqueeze(WidgetTester tester) {
  final paragraphs = tester.renderObjectList<RenderParagraph>(
    find.descendant(
      of: find.descendant(
        of: find.byKey(actionRowKey),
        matching: find.byType(Wrap),
      ),
      matching: find.byType(Text),
    ),
  );
  for (final paragraph in paragraphs) {
    expect(paragraph.didExceedMaxLines, isFalse);
    expect(
      paragraph.size.width + 0.5,
      greaterThanOrEqualTo(paragraph.getMinIntrinsicWidth(double.infinity)),
    );
  }
}

Finder _chip(String label) => find.byKey(ValueKey(label));

void _expectIcon(String label) {
  final chip = _chip(label);
  expect(chip, findsOneWidget, reason: label);
  expect(
    find.descendant(of: chip, matching: find.byType(Image)),
    findsOneWidget,
    reason: label,
  );
}

void _expectNoIcon(String label) {
  final chip = _chip(label);
  expect(chip, findsOneWidget, reason: label);
  expect(
    find.descendant(of: chip, matching: find.byType(Image)),
    findsNothing,
    reason: label,
  );
}

/// The label of every chip under [actionRowKey], in the order the row lays
/// them out (ascending top, then ascending left).
List<String> _controlOrder(WidgetTester tester) {
  final labels = tester
      .widgetList<Text>(
        find.descendant(
          of: find.descendant(
            of: find.byKey(actionRowKey),
            matching: find.byType(Wrap),
          ),
          matching: find.byType(Text),
        ),
      )
      .map((text) => text.data!)
      .toList();
  final positioned = [
    for (final label in labels) (label, tester.getTopLeft(_chip(label))),
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
      expect(find.text('Pick up'), findsOneWidget);
      expect(find.text('Drink (2)'), findsOneWidget);
      expect(find.text('Pack (2)'), findsOneWidget);
      expect(find.text('Ascend <'), findsOneWidget);
      expect(find.text(doneControl), findsOneWidget);
      expect(tester.takeException(), isNull);
      _expectNoSqueeze(tester);
    });

    testWidgets('the worst road density fits a phone un-ellipsised', (
      tester,
    ) async {
      // arrange
      final game = _roadScene();

      // act
      await _openCrawl(tester, game);

      // assert
      expect(find.text('Pick up'), findsOneWidget);
      expect(find.text('Drink (2)'), findsOneWidget);
      expect(find.text('Pack (2)'), findsOneWidget);
      expect(find.text('Wait'), findsOneWidget);
      expect(find.text('Flee'), findsOneWidget);
      expect(tester.takeException(), isNull);
      _expectNoSqueeze(tester);
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
      _expectIcon('Drink (2)');
      _expectIcon('Pack (2)');
      _expectIcon('Ascend <');
      _expectNoIcon('Pick up');
      _expectNoIcon(doneControl);

      // arrange - the road scene is the only staged scene with Wait and Flee
      final road = _roadScene();

      // act
      await _openCrawl(tester, road);

      // assert
      _expectIcon('Wait');
      _expectNoIcon('Flee');

      // arrange - a third scene, staged only to reach Descend >
      final descend = _stairsDownScene();

      // act
      await _openCrawl(tester, descend);

      // assert
      _expectIcon('Descend >');
      _expectNoSqueeze(tester);
    });

    testWidgets('an icon-bearing control announces itself', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        // arrange
        final game = _stairsScene();

        // act
        await _openCrawl(tester, game);

        // assert
        expect(find.bySemanticsLabel('Drink (2)'), findsOneWidget);
        expect(find.bySemanticsLabel('Pack (2)'), findsOneWidget);
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

      // assert - the word and the icon are unchanged, only the tap is gone
      final drink = _chip('Drink (2)');
      expect(drink, findsOneWidget);
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
          ['Pick up', 'Drink (2)', 'Pack (2)', 'Ascend <', doneControl],
        ),
        'road': (
          _roadScene(),
          ['Pick up', 'Drink (2)', 'Pack (2)', 'Wait', 'Flee'],
        ),
        'stairs down': (_stairsDownScene(), ['Pack (0)', 'Descend >', 'Leave']),
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
