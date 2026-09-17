import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/crawl_action_row.dart';
import 'package:residuum_app/game/dungeon_palette.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/game_screen.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

const _arena = '''
#######
#.....#
#.....#
#######''';

/// An open battle: the hero and one live ghoul stand adjacent, so
/// `isBattleOpen` is true and the shelf renders.
GameState _battleGame({
  Set<String> knownSpells = const {},
  int mana = 10,
  List<Item> inventory = const [],
}) {
  final map = FloorMap.parse(_arena);
  const heroAt = Position(1, 1);
  final visible = computeFov(map, heroAt, fovRadius);
  return GameState(
    map: map,
    hero: Actor(
      id: 'hero',
      name: 'you',
      glyph: '@',
      position: heroAt,
      hp: 20,
      maxHp: 20,
      attackMin: 4,
      attackMax: 4,
      speed: 10,
      energy: actThreshold,
    ),
    monsters: [
      Actor(
        id: 'ghoul-1',
        name: 'the ghoul',
        glyph: 'g',
        position: const Position(1, 2),
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
    spells: spellsById,
    knownSpells: knownSpells,
    mana: mana,
    inventory: inventory,
  );
}

Future<GameBloc> _openBattle(WidgetTester tester, GameState game) async {
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

/// A [label] on the action row itself — never a crawl overlay, which could
/// carry the same word in a different surface.
Finder _shelfText(String label) =>
    find.descendant(of: find.byKey(actionRowKey), matching: find.text(label));

/// The chip carrying [label], scoped to the action row so a same-worded
/// surface elsewhere never satisfies this finder by accident.
Finder _shelfButton(String label) => find.descendant(
  of: find.byKey(actionRowKey),
  matching: find.byKey(ValueKey(label)),
);

/// The rendered border a chip's [Material] currently carries — read from the
/// widget the crawl actually painted, never a hex literal.
BorderSide _borderOf(WidgetTester tester, Finder chip) {
  final material = tester.widget<Material>(
    find.descendant(of: chip, matching: find.byType(Material)),
  );
  return (material.shape! as RoundedRectangleBorder).side;
}

void main() {
  group('the icon language on the battle shelf', () {
    testWidgets('every icon-bearing shelf action keeps its word', (
      tester,
    ) async {
      // arrange
      final game = _battleGame(
        knownSpells: const {'firebolt', 'frost-lance', 'mend', 'banish'},
        inventory: const [
          Item(id: 'potion-1', base: healingPotion, rarity: Rarity.common),
        ],
      );

      // act
      await _openBattle(tester, game);

      // assert - every word, count and marking survives
      expect(_shelfText('Drink (1)'), findsOneWidget);
      expect(_shelfText('Wait'), findsOneWidget);
      expect(_shelfText('+1'), findsOneWidget);
      expect(_shelfText('✳ Firebolt 2'), findsOneWidget);
      expect(_shelfText('✚ Mend 3'), findsOneWidget);

      // assert - the five with an exact asset each carry one icon
      for (final label in [
        'Drink (1)',
        'Wait',
        '+1',
        '✳ Firebolt 2',
        '✚ Mend 3',
      ]) {
        final button = _shelfButton(label);
        expect(button, findsOneWidget, reason: label);
        expect(
          find.descendant(of: button, matching: find.byType(Image)),
          findsOneWidget,
          reason: label,
        );
      }

      // assert - frost lance has no exact asset and stays text-only
      final frostLance = find.byKey(const ValueKey('✳ Frost Lance 4'));
      expect(frostLance, findsOneWidget);
      expect(
        find.descendant(of: frostLance, matching: find.byType(Image)),
        findsNothing,
      );
    });

    testWidgets('arming still reads by border and word', (tester) async {
      // arrange
      final game = _battleGame(knownSpells: const {'firebolt'});
      await _openBattle(tester, game);
      final firebolt = find.byKey(const ValueKey('✳ Firebolt 2'));
      final wait = find.byKey(const ValueKey('Wait'));
      final unarmedBorder = _borderOf(tester, wait);

      // act
      await tester.tap(firebolt);
      await tester.pumpAndSettle();

      // assert - the word gains its own armed line, the border is heavier
      // than an unarmed sibling's, and the icon is still there
      expect(find.text('✳ Firebolt 2'), findsOneWidget);
      expect(find.text('— armed'), findsOneWidget);
      expect(
        _borderOf(tester, firebolt).width,
        greaterThan(unarmedBorder.width),
      );
      expect(
        find.descendant(of: firebolt, matching: find.byType(Image)),
        findsOneWidget,
      );
    });

    testWidgets('a spell with no asset stays text-only in the overflow too', (
      tester,
    ) async {
      // arrange
      final game = _battleGame(
        knownSpells: const {'firebolt', 'frost-lance', 'mend', 'banish'},
      );
      await _openBattle(tester, game);

      // act
      await tester.tap(find.byKey(const ValueKey('+1')));
      await tester.pumpAndSettle();

      // assert - not even the two spells with an exact asset carry an icon
      // here; the overflow is untouched by this unit
      for (final id in ['firebolt', 'frost-lance', 'mend', 'banish']) {
        final row = find.byKey(Key('overflow-$id'));
        expect(row, findsOneWidget, reason: id);
        expect(
          find.descendant(of: row, matching: find.byType(Image)),
          findsNothing,
          reason: id,
        );
      }
    });
  });
}
