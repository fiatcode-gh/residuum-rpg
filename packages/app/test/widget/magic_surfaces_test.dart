import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/inventory_screen.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

const _arena = '''
#######
#.....#
#.....#
#######''';

Item _book(String id, BaseItem base) =>
    Item(id: id, base: base, rarity: Rarity.common);

Actor _ghoul(Position at) => Actor(
  id: 'ghoul-1',
  name: 'the ghoul',
  glyph: 'g',
  position: at,
  hp: 10,
  maxHp: 10,
  attackMin: 1,
  attackMax: 1,
  speed: 10,
  energy: actThreshold,
);

GameState _crawl({
  List<Item> inventory = const [],
  Set<String> knownSpells = const {},
  List<Actor> monsters = const [],
  int mana = 10,
  Map<SkillId, SkillState> skills = untrainedSkills,
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
    monsters: monsters,
    rng: Rng(1),
    lootRng: Rng(2),
    visible: visible,
    explored: {...visible},
    buildFloor: (depth) => throw StateError('no floor below'),
    inventory: inventory,
    skills: skills,
    spells: spellsById,
    knownSpells: knownSpells,
    mana: mana,
  );
}

/// The pack screen, opened on a crawl, with nothing else on the stack.
Future<GameBloc> _openPack(WidgetTester tester, GameState game) async {
  final bloc = GameBloc(game: game, stepDelay: Duration.zero);
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider.value(value: bloc, child: const InventoryScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return bloc;
}

void main() {
  group('the Spells section', () {
    testWidgets('is not there at all for a hero who knows nothing', (
      tester,
    ) async {
      // arrange
      final game = _crawl();

      // act
      await _openPack(tester, game);

      // assert
      expect(find.text('SPELLS'), findsNothing);
    });

    testWidgets('names every spell with its school in a word and a mark', (
      tester,
    ) async {
      // arrange
      final game = _crawl(knownSpells: const {'firebolt', 'mend'});

      // act
      await _openPack(tester, game);

      // assert - the school is legible twice over, so the row reads in
      // greyscale and reads aloud
      expect(find.text('SPELLS'), findsOneWidget);
      expect(find.text('Firebolt'), findsOneWidget);
      expect(find.text('Mend'), findsOneWidget);
      expect(find.textContaining('Wrath'), findsWidgets);
      expect(find.text(SkillId.wrath.schoolMarking), findsOneWidget);
    });

    testWidgets('says why a cast is refused rather than going quietly grey', (
      tester,
    ) async {
      // arrange - nothing to throw a bolt at
      final game = _crawl(knownSpells: const {'firebolt'});

      // act
      await _openPack(tester, game);

      // assert
      expect(find.text('no enemy in sight'), findsOneWidget);
      final cast = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Cast'),
      );
      expect(cast.onPressed, isNull);
    });

    testWidgets('offers Cast with no reason once something is in sight', (
      tester,
    ) async {
      // arrange
      final game = _crawl(
        knownSpells: const {'firebolt'},
        monsters: [_ghoul(const Position(4, 1))],
      );

      // act
      await _openPack(tester, game);

      // assert
      expect(find.text('no enemy in sight'), findsNothing);
      final cast = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Cast'),
      );
      expect(cast.onPressed, isNotNull);
    });

    testWidgets('says when the pool is short', (tester) async {
      // arrange
      final game = _crawl(
        knownSpells: const {'firebolt'},
        monsters: [_ghoul(const Position(4, 1))],
        mana: 1,
      );

      // act
      await _openPack(tester, game);

      // assert
      expect(find.text('not enough mana'), findsOneWidget);
    });
  });

  group('the Books section', () {
    testWidgets('offers Read rather than Drink', (tester) async {
      // arrange
      final game = _crawl(inventory: [_book('kit-4', bookOfFirebolt)]);

      // act
      await _openPack(tester, game);

      // assert - the section fall-through used to file a book under Potions
      expect(find.text('BOOKS'), findsOneWidget);
      expect(find.text('POTIONS'), findsNothing);
      expect(find.text('Read'), findsOneWidget);
      expect(find.text('Drink'), findsNothing);
    });

    testWidgets('a potion is not told it cannot be read', (tester) async {
      // arrange - the shared rule answers about a potion perfectly truthfully,
      // and the answer is nonsense under a Drink button
      final game = _crawl(
        inventory: [
          const Item(id: 'kit-2', base: healingPotion, rarity: Rarity.common),
        ],
      );

      // act
      await _openPack(tester, game);

      // assert
      expect(find.text('Drink'), findsOneWidget);
      expect(find.textContaining('is not something to read'), findsNothing);
    });

    testWidgets('a locked book carries the gate as a sentence', (tester) async {
      // arrange
      final game = _crawl(inventory: [_book('kit-5', bookOfWard)]);

      // act
      await _openPack(tester, game);

      // assert
      expect(find.text('needs Mending 3'), findsOneWidget);
      final read = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Read'),
      );
      expect(read.onPressed, isNull);
    });

    testWidgets('reading it puts the spell in the Spells section', (
      tester,
    ) async {
      // arrange
      final game = _crawl(inventory: [_book('kit-4', bookOfFirebolt)]);

      // act
      await _openPack(tester, game);
      await tester.tap(find.text('Read'));
      await tester.pumpAndSettle();

      // assert
      expect(find.text('BOOKS'), findsNothing);
      expect(find.text('SPELLS'), findsOneWidget);
      expect(find.text('Firebolt'), findsOneWidget);
    });
  });

  group('the mana readout', () {
    testWidgets('is on the pack screen as a word and two numbers', (
      tester,
    ) async {
      // arrange
      final game = _crawl(knownSpells: const {'firebolt'}, mana: 3);

      // act
      await _openPack(tester, game);

      // assert
      expect(find.text('Mana     3/$baseMana'), findsOneWidget);
    });

    testWidgets('shows a ward only while one stands', (tester) async {
      // arrange - a caster who knows Mend, so nothing else on the screen is
      // called Ward and the readout is the only thing that could say it
      final bare = _crawl(knownSpells: const {'mend'});

      // act
      await _openPack(tester, bare);

      // assert
      expect(find.textContaining('Ward'), findsNothing);
    });

    testWidgets('names the ward when one does stand', (tester) async {
      // arrange
      final game = _crawl(knownSpells: const {'mend'}).copyWith(warded: 4);

      // act
      await _openPack(tester, game);

      // assert
      expect(find.text('Ward     4 held'), findsOneWidget);
    });
  });

  group('the skill list', () {
    testWidgets('has a row for every school, named in words', (tester) async {
      // arrange
      final game = _crawl();

      // act
      await _openPack(tester, game);
      await tester.scrollUntilVisible(find.text('Binding'), 200);
      await tester.pumpAndSettle();

      // assert
      expect(find.text('Wrath'), findsOneWidget);
      expect(find.text('Mending'), findsOneWidget);
      expect(find.text('Binding'), findsOneWidget);
    });
  });
}
