import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/dungeon_palette.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/game_screen.dart';
import 'package:residuum_app/game/log_row.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

const _arena = '''
#######
#.....#
#.....#
#######''';

/// An open battle: the hero and one live ghoul stand adjacent, so
/// `isBattleOpen` is true and the Spells/Quick pop-ups have something to
/// offer.
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

/// The chip carrying [id]: scoped to the log row for `wait`, which sits
/// beside the recent-events peek (PLAN.md G8); every other id is a
/// `spell:<id>`, `drink:<id>` or `spells-overflow` row inside whichever
/// pop-up the test has open, and those ids are unique enough on their own
/// that no scope is needed to tell them apart from anything else on screen.
Finder _shelfButton(String id) => id == 'wait'
    ? find.descendant(
        of: find.byKey(logRowKey),
        matching: find.byKey(ValueKey(id)),
      )
    : find.byKey(ValueKey(id));

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

Future<void> _openSpells(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('menu-spells')));
  await tester.pumpAndSettle();
}

Future<void> _openQuick(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('menu-quick')));
  await tester.pumpAndSettle();
}

void main() {
  group('the icon language in the Spells and Quick pop-ups', () {
    testWidgets('every icon-bearing chip keeps its word', (tester) async {
      // arrange
      final game = _battleGame(
        knownSpells: const {'firebolt', 'frost-lance', 'mend', 'banish'},
        inventory: const [
          Item(id: 'potion-1', base: healingPotion, rarity: Rarity.common),
        ],
      );

      // act
      await _openBattle(tester, game);

      // assert - Wait keeps its word and icon on the log row
      _expectShelfAction('wait', label: 'Wait');
      expect(
        find.descendant(of: _shelfButton('wait'), matching: find.byType(Image)),
        findsOneWidget,
      );

      // assert - the Quick pop-up's row keeps the verb, name and count
      // separate
      await _openQuick(tester);
      _expectShelfAction(
        'drink:potion-1',
        label: 'Common Healing Potion',
        metadata: '×1 · heals 10',
      );
      expect(
        find.descendant(
          of: _shelfButton('drink:potion-1'),
          matching: find.byType(Image),
        ),
        findsOneWidget,
      );
      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();

      // assert - the Spells pop-up's readied rows and the overflow count
      await _openSpells(tester);
      _expectShelfAction('spells-overflow', label: '+1 more spells');
      _expectShelfAction(
        'spell:firebolt',
        label: '✳ Firebolt',
        metadata: '2 mana · 2-4 fire △',
      );
      _expectShelfAction(
        'spell:mend',
        label: '✚ Mend',
        metadata: '3 mana · heals 8',
      );

      // assert - the two spells with an exact asset each carry one icon
      for (final id in ['spell:firebolt', 'spell:mend']) {
        final button = _shelfButton(id);
        expect(
          find.descendant(of: button, matching: find.byType(Image)),
          findsOneWidget,
          reason: id,
        );
      }

      // assert
      final frostLance = _shelfButton('spell:frost-lance');
      expect(frostLance, findsOneWidget);
      expect(_shelfText('spell:frost-lance', '✳ Frost Lance'), findsOneWidget);
      expect(
        _shelfMetadata('spell:frost-lance', '4 mana · 4-7 frost ◇'),
        findsOneWidget,
      );
      expect(
        find.descendant(of: frostLance, matching: find.byType(Image)),
        findsNothing,
      );
      expect(
        find.descendant(of: frostLance, matching: find.byIcon(Icons.ac_unit)),
        findsOneWidget,
      );
    });

    testWidgets('arming still reads by border and word', (tester) async {
      // arrange
      final game = _battleGame(knownSpells: const {'firebolt'});
      await _openBattle(tester, game);
      final unarmedBorder = _borderOf(tester, _shelfButton('wait'));

      // act
      await _openSpells(tester);
      await tester.tap(_shelfButton('spell:firebolt'));
      await tester.pumpAndSettle();

      // assert - the Spells slot itself carries the armed border; the row
      // inside its pop-up reads by word alone
      expect(
        _borderOf(tester, find.byKey(const ValueKey('menu-spells'))).width,
        greaterThan(unarmedBorder.width),
      );
      await _openSpells(tester);
      final firebolt = _shelfButton('spell:firebolt');
      expect(_shelfText('spell:firebolt', '✳ Firebolt'), findsOneWidget);
      expect(_shelfMetadata('spell:firebolt', '— armed'), findsOneWidget);
      expect(_shelfMetadata('spell:firebolt', '2 mana'), findsNothing);
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
      await _openSpells(tester);

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
