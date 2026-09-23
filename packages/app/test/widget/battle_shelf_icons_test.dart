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

/// A [label] rendered inside the keyed action chip.
Finder _shelfText(String id, String label) =>
    find.descendant(of: _shelfButton(id), matching: find.text(label));

/// The chip carrying [id], scoped to the action row so a same-worded surface
/// elsewhere never satisfies this finder by accident.
Finder _shelfButton(String id) => find.descendant(
  of: find.byKey(actionRowKey),
  matching: find.byKey(ValueKey(id)),
);

Finder _shelfMetadata(String id, String metadata) =>
    find.descendant(of: _shelfButton(id), matching: find.text(metadata));

void _expectShelfAction(String id, {required String label, String? metadata}) {
  expect(_shelfButton(id), findsOneWidget, reason: id);
  expect(_shelfText(id, label), findsOneWidget, reason: label);
  if (metadata != null) {
    expect(_shelfMetadata(id, metadata), findsOneWidget, reason: metadata);
  }
}

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

      // assert - every verb, count and marking survives as separate fields
      _expectShelfAction('drink', label: 'Drink', metadata: '×1');
      _expectShelfAction('wait', label: 'Wait');
      _expectShelfAction('spells-overflow', label: '+1');
      _expectShelfAction(
        'spell:firebolt',
        label: '✳ Firebolt',
        metadata: '2 mana',
      );
      _expectShelfAction('spell:mend', label: '✚ Mend', metadata: '3 mana');

      // assert - the five with an exact asset each carry one icon
      for (final id in ['drink', 'wait', 'spell:firebolt', 'spell:mend']) {
        final button = _shelfButton(id);
        expect(
          find.descendant(of: button, matching: find.byType(Image)),
          findsOneWidget,
          reason: id,
        );
      }

      // assert - frost lance has no exact asset and stays text-only
      final frostLance = _shelfButton('spell:frost-lance');
      expect(frostLance, findsOneWidget);
      expect(_shelfText('spell:frost-lance', '✳ Frost Lance'), findsOneWidget);
      expect(_shelfMetadata('spell:frost-lance', '4 mana'), findsOneWidget);
      expect(
        find.descendant(of: frostLance, matching: find.byType(Image)),
        findsNothing,
      );
    });

    testWidgets('arming still reads by border and word', (tester) async {
      // arrange
      final game = _battleGame(knownSpells: const {'firebolt'});
      await _openBattle(tester, game);
      final firebolt = _shelfButton('spell:firebolt');
      final wait = _shelfButton('wait');
      final unarmedBorder = _borderOf(tester, wait);

      // act
      await tester.tap(firebolt);
      await tester.pumpAndSettle();

      // assert - the word gains its own armed line, the border is heavier
      // than an unarmed sibling's, and the icon is still there
      _expectShelfAction(
        'spell:firebolt',
        label: '✳ Firebolt',
        metadata: '2 mana',
      );
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
      await tester.tap(_shelfButton('spells-overflow'));
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
