import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/game_screen.dart';
import 'package:residuum_app/game/pack_screen.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../support/phone.dart';

import 'package:residuum_app/town/pack_screen.dart';
import 'package:residuum_app/town/town_bloc.dart';

const _arena = '''
#######
#.....#
#.....#
#######''';

Item _item(String id, BaseItem base) =>
    Item(id: id, base: base, rarity: Rarity.common);

GameState _crawl({
  List<Item> inventory = const [],
  Set<String> knownSpells = const {},
  Map<MaterialId, int> materials = const {},
  Map<SkillId, SkillState> skills = untrainedSkills,
  Equipment equipment = const {},
  int heroHp = 20,
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
      hp: heroHp,
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
    inventory: inventory,
    equipment: equipment,
    materials: materials,
    skills: skills,
    spells: spellsById,
    knownSpells: knownSpells,
    mana: 10,
  );
}

Future<GameBloc> _openPack(WidgetTester tester, GameState game) async {
  final bloc = GameBloc(game: game, stepDelay: Duration.zero);
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider.value(value: bloc, child: const CrawlPackScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return bloc;
}

Future<GameBloc> _openCrawlAndPack(WidgetTester tester, GameState game) async {
  final bloc = GameBloc(game: game, stepDelay: Duration.zero);
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider.value(value: bloc, child: const GameScreen()),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Pack (${game.inventory.length})'));
  await tester.pumpAndSettle();
  return bloc;
}

ChoiceChip _filter(WidgetTester tester, String name) =>
    tester.widget<ChoiceChip>(find.byKey(Key('pack-filter-$name')));

List<String> _inventoryIds(GameState game) => [
  for (final item in game.inventory) item.id,
];

List<String> _logSentences(GameViewState state) => [
  for (final line in state.log) line.sentence,
];

Profile _townProfile({
  List<Item> inventory = const [],
  Equipment equipment = const {},
  Set<String> knownSpells = const {},
  Map<MaterialId, int> materials = const {},
  Map<SkillId, SkillState> skills = untrainedSkills,
}) => newProfile(worldSeed: 4).copyWith(
  inventory: inventory,
  equipment: equipment,
  knownSpells: knownSpells,
  materials: materials,
  skills: skills,
  gold: 25,
);

Future<TownBloc> _openTownPack(WidgetTester tester, Profile profile) async {
  final bloc = TownBloc(profile: profile);
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider.value(value: bloc, child: const TownPackScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return bloc;
}

void main() {
  testWidgets(
    'starts with six local filters and no duplicate management lists',
    (tester) async {
      // arrange
      final bloc = await _openPack(
        tester,
        _crawl(knownSpells: const {'firebolt'}),
      );
      addTearDown(bloc.close);
      final gameBefore = bloc.state.game;
      final logBefore = bloc.state.log;
      final allFilter = find.byKey(const Key('pack-filter-all'));
      final semanticsBefore = tester.getSemantics(allFilter);
      expect(semanticsBefore.flagsCollection.isSelected, ui.Tristate.isTrue);
      expect(semanticsBefore.flagsCollection.isEnabled, ui.Tristate.isTrue);
      final sectionLabels = const [
        'WEAPONS',
        'ARMOUR',
        'POTIONS',
        'BOOKS',
        'Materials',
      ];
      for (final section in sectionLabels) {
        expect(find.text(section), findsOneWidget);
      }

      // act
      await tester.tap(allFilter);
      await tester.pump();

      // assert
      expect(find.byKey(const Key('pack-filter-all')), findsOneWidget);
      expect(find.byKey(const Key('pack-filter-weapons')), findsOneWidget);
      expect(find.byKey(const Key('pack-filter-armour')), findsOneWidget);
      expect(find.byKey(const Key('pack-filter-potions')), findsOneWidget);
      expect(find.byKey(const Key('pack-filter-books')), findsOneWidget);
      expect(find.byKey(const Key('pack-filter-materials')), findsOneWidget);
      expect(find.byType(ChoiceChip).first, findsOneWidget);
      expect(_filter(tester, 'all').selected, isTrue);
      final selectedSemantics = tester.getSemantics(
        find.byKey(const Key('pack-filter-all')),
      );
      expect(selectedSemantics.flagsCollection.isSelected, ui.Tristate.isTrue);
      expect(selectedSemantics.flagsCollection.isEnabled, ui.Tristate.isTrue);
      for (final filter in const [
        'weapons',
        'armour',
        'potions',
        'books',
        'materials',
      ]) {
        expect(_filter(tester, filter).selected, isFalse);
      }
      for (final section in const [
        'WEAPONS',
        'ARMOUR',
        'POTIONS',
        'BOOKS',
        'Materials',
      ]) {
        expect(find.text(section), findsOneWidget);
      }
      expect(find.text('Attack   4-4'), findsNothing);
      expect(find.text('SPELLS'), findsNothing);
      expect(find.text('WORN'), findsNothing);
      expect(find.text('SKILLS'), findsNothing);
      expect(find.text('Cast'), findsNothing);
      expect(find.text('Take off'), findsNothing);
      expect(bloc.state.game, same(gameBefore));
      expect(bloc.state.log, same(logBefore));
    },
  );

  testWidgets(
    'filters Books and Materials without rebuilding item categories',
    (tester) async {
      // arrange
      final bloc = await _openPack(
        tester,
        _crawl(
          inventory: [
            _item('sword', ironSword),
            _item('potion', healingPotion),
            _item('book', bookOfFirebolt),
          ],
          materials: const {MaterialId.ore: 2},
        ),
      );
      addTearDown(bloc.close);

      // act
      await tester.tap(find.byKey(const Key('pack-filter-books')));
      await tester.pump();

      // assert
      expect(find.text('BOOKS'), findsOneWidget);
      expect(find.text('Common Book of Firebolt'), findsOneWidget);
      expect(find.text('WEAPONS'), findsNothing);
      expect(find.text('POTIONS'), findsNothing);
      expect(find.text('MATERIALS'), findsNothing);

      // act
      await tester.tap(find.byKey(const Key('pack-filter-materials')));
      await tester.pump();

      // assert
      expect(find.text('MATERIALS'), findsOneWidget);
      expect(find.text('Common Book of Firebolt'), findsNothing);
      expect(find.text('Common Iron Sword'), findsNothing);
      expect(find.text('Common Healing Potion'), findsNothing);
      for (final material in MaterialId.values) {
        expect(find.text(material.word), findsOneWidget);
      }
    },
  );

  testWidgets('filter and navigation are transient and spend no turn', (
    tester,
  ) async {
    // arrange
    final bloc = await _openCrawlAndPack(tester, _crawl());
    addTearDown(bloc.close);
    final gameBefore = bloc.state.game;
    final logBefore = bloc.state.log;

    // act
    await tester.tap(find.byKey(const Key('pack-filter-books')));
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pack (0)'));
    await tester.pumpAndSettle();

    // assert
    expect(_filter(tester, 'all').selected, isTrue);
    expect(bloc.state.game, same(gameBefore));
    expect(bloc.state.log, same(logBefore));
  });

  testWidgets(
    'All preserves source section order, stacking and zero materials',
    (tester) async {
      // arrange
      final bloc = await _openPack(
        tester,
        _crawl(
          inventory: [
            _item('shield', kiteShield),
            _item('potion-1', healingPotion),
            _item('potion-2', healingPotion),
            _item('sword', ironSword),
            _item('book', bookOfFirebolt),
          ],
          materials: const {MaterialId.ore: 3},
        ),
      );
      addTearDown(bloc.close);

      // act
      final headings = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data)
          .whereType<String>()
          .where(
            (text) => const {
              'WEAPONS',
              'ARMOUR',
              'POTIONS',
              'BOOKS',
              'MATERIALS',
            }.contains(text),
          )
          .toList();

      // assert
      expect(headings, ['WEAPONS', 'ARMOUR', 'POTIONS', 'BOOKS', 'MATERIALS']);
      expect(find.text('Common Healing Potion ×2'), findsOneWidget);
      for (final material in MaterialId.values) {
        expect(find.text(material.word), findsOneWidget);
      }
      expect(find.text('0'), findsWidgets);

      // act
      await tester.tap(find.byKey(const Key('pack-filter-weapons')));
      await tester.pump();

      // assert
      expect(find.text('WEAPONS'), findsOneWidget);
      expect(find.text('Common Iron Sword'), findsOneWidget);
      expect(find.text('ARMOUR'), findsNothing);
      expect(find.text('POTIONS'), findsNothing);
      expect(find.text('BOOKS'), findsNothing);
      expect(find.text('MATERIALS'), findsNothing);

      // act
      await tester.tap(find.byKey(const Key('pack-filter-armour')));
      await tester.pump();

      // assert
      expect(find.text('ARMOUR'), findsOneWidget);
      expect(find.text('Common Kite Shield'), findsOneWidget);
      expect(find.text('WEAPONS'), findsNothing);

      // act
      await tester.tap(find.byKey(const Key('pack-filter-potions')));
      await tester.pump();

      // assert
      expect(find.text('POTIONS'), findsOneWidget);
      expect(find.text('Common Healing Potion ×2'), findsOneWidget);
      expect(find.text('BOOKS'), findsNothing);

      // act
      await tester.tap(find.byKey(const Key('pack-filter-books')));
      await tester.pump();

      // assert
      expect(find.text('BOOKS'), findsOneWidget);
      expect(find.text('Common Book of Firebolt'), findsOneWidget);
      expect(find.text('POTIONS'), findsNothing);

      // act
      await tester.tap(find.byKey(const Key('pack-filter-materials')));
      await tester.pump();

      // assert
      expect(find.text('MATERIALS'), findsOneWidget);
      expect(find.text('Common Book of Firebolt'), findsNothing);
      expect(find.text('Common Healing Potion ×2'), findsNothing);
      for (final material in MaterialId.values) {
        expect(find.text(material.word), findsOneWidget);
      }
    },
  );

  testWidgets('Drink acts on exactly the first represented potion', (
    tester,
  ) async {
    // arrange
    final first = _item('potion-1', healingPotion);
    final second = _item('potion-2', healingPotion);
    final bloc = await _openPack(
      tester,
      _crawl(inventory: [first, second, _item('sword', ironSword)], heroHp: 5),
    );
    addTearDown(bloc.close);
    expect(find.text('Common Healing Potion ×2'), findsOneWidget);

    // act
    await tester.tap(find.byKey(const Key('pack-drink-potion-1')));
    await tester.pumpAndSettle();

    // assert
    expect(bloc.state.game.hero.hp, 15);
    expect(_inventoryIds(bloc.state.game), ['potion-2', 'sword']);
    expect(
      _logSentences(bloc.state).last,
      contains('drink Common Healing Potion'),
    );
    expect(find.text('Common Healing Potion ×2'), findsNothing);
    expect(find.byKey(const Key('pack-stack-potion-2')), findsOneWidget);
  });

  testWidgets('Drop acts on exactly the first represented stack item', (
    tester,
  ) async {
    // arrange
    final first = _item('sword-1', ironSword);
    final second = _item('sword-2', ironSword);
    final bloc = await _openPack(
      tester,
      _crawl(inventory: [first, second, _item('potion', healingPotion)]),
    );

    // act
    await tester.tap(find.byKey(const Key('pack-drop-sword-1')));
    await tester.pumpAndSettle();

    // assert
    expect(_inventoryIds(bloc.state.game), ['sword-2', 'potion']);
    expect(bloc.state.itemsUnderfoot.map((item) => item.id), ['sword-1']);
    addTearDown(bloc.close);
  });

  testWidgets('Read success empties the selected Books section', (
    tester,
  ) async {
    // arrange
    final bloc = await _openPack(
      tester,
      _crawl(inventory: [_item('book', bookOfFirebolt)]),
    );
    addTearDown(bloc.close);
    await tester.tap(find.byKey(const Key('pack-filter-books')));
    await tester.pump();

    // act
    await tester.tap(find.byKey(const Key('pack-read-book')));
    await tester.pumpAndSettle();

    // assert
    expect(bloc.state.game.knownSpells, {'firebolt'});
    expect(bloc.state.game.inventory, isEmpty);
    expect(find.text('BOOKS'), findsOneWidget);
    expect(find.text('You are carrying nothing to read.'), findsOneWidget);
  });

  testWidgets('a gated book refuses Read but leaves Drop available', (
    tester,
  ) async {
    // arrange
    final bloc = await _openPack(
      tester,
      _crawl(inventory: [_item('book', bookOfWard)]),
    );
    addTearDown(bloc.close);

    // act
    final read = tester.widget<TextButton>(
      find.byKey(const Key('pack-read-book')),
    );
    final drop = tester.widget<TextButton>(
      find.byKey(const Key('pack-drop-book')),
    );

    // assert
    expect(find.text('needs Mending 3'), findsOneWidget);
    expect(read.onPressed, isNull);
    expect(drop.onPressed, isNotNull);
    expect(bloc.state.game.inventory, hasLength(1));
  });

  testWidgets('a potion is never asked for a read refusal', (tester) async {
    // arrange
    final bloc = await _openPack(
      tester,
      _crawl(inventory: [_item('potion', healingPotion)]),
    );
    addTearDown(bloc.close);

    // act

    // assert
    expect(find.byKey(const Key('pack-drink-potion')), findsOneWidget);
    expect(find.textContaining('is not something to read'), findsNothing);
  });

  testWidgets('Wear success updates equipment through the crawl event', (
    tester,
  ) async {
    // arrange
    final bloc = await _openPack(
      tester,
      _crawl(inventory: [_item('sword', ironSword)]),
    );
    addTearDown(bloc.close);

    // act
    await tester.tap(find.byKey(const Key('pack-wear-sword')));
    await tester.pumpAndSettle();

    // assert
    expect(bloc.state.game.equipment[EquipSlot.mainHand]?.id, 'sword');
    expect(bloc.state.game.inventory, isEmpty);
    expect(
      _logSentences(bloc.state).last,
      contains('put on Common Iron Sword'),
    );
  });

  testWidgets(
    'core equip refusal stays in the log while Drop remains enabled',
    (tester) async {
      // arrange
      final worn = _item('maul', maul);
      final shield = _item('shield', kiteShield);
      final bloc = await _openPack(
        tester,
        _crawl(inventory: [shield], equipment: {EquipSlot.mainHand: worn}),
      );
      addTearDown(bloc.close);
      final gameBefore = bloc.state.game;

      // act
      await tester.tap(find.byKey(const Key('pack-wear-shield')));
      await tester.pumpAndSettle();

      // assert
      expect(bloc.state.game, same(gameBefore));
      expect(bloc.state.game.equipment[EquipSlot.mainHand]?.id, 'maul');
      expect(bloc.state.game.inventory.single.id, 'shield');
      expect(_logSentences(bloc.state).last, 'Both hands are on the weapon.');
      expect(
        tester
            .widget<TextButton>(find.byKey(const Key('pack-drop-shield')))
            .onPressed,
        isNotNull,
      );
    },
  );

  testWidgets('the crawl Pack fits every local filter on a phone', (
    tester,
  ) async {
    // arrange
    await onAPhone(tester);
    final bloc = await _openPack(
      tester,
      _crawl(
        inventory: [
          _item('greatsword', greatsword),
          _item('shield', kiteShield),
          _item('potion', healingPotion),
          _item('book', bookOfWard),
        ],
      ),
    );
    addTearDown(bloc.close);

    // act
    for (final filter in const [
      'all',
      'weapons',
      'armour',
      'potions',
      'books',
      'materials',
    ]) {
      await tester.tap(find.byKey(Key('pack-filter-$filter')));
      await tester.pump();
    }
    await tester.tap(find.byKey(const Key('pack-filter-all')));
    await tester.pump();

    // assert
    expect(find.byKey(const Key('pack-wear-greatsword')), findsOneWidget);
    expect(find.byKey(const Key('pack-drop-greatsword')), findsOneWidget);
    expect(find.text('needs Mending 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('Town Pack route', () {
    testWidgets('offers only town-valid actions', (tester) async {
      // arrange
      final town = await _openTownPack(
        tester,
        _townProfile(
          inventory: [
            _item('potion', healingPotion),
            _item('book', bookOfFirebolt),
            _item('sword', ironSword),
            _item('shield', kiteShield),
          ],
        ),
      );
      addTearDown(town.close);

      // act

      // assert
      expect(find.byKey(const Key('pack-wear-sword')), findsOneWidget);
      expect(find.byKey(const Key('pack-wear-shield')), findsOneWidget);
      expect(find.byKey(const Key('pack-read-book')), findsOneWidget);
      expect(find.byKey(const Key('pack-drink-potion')), findsNothing);
      expect(find.byKey(const Key('pack-drop-potion')), findsNothing);
      expect(find.byKey(const Key('pack-drop-book')), findsNothing);
      expect(find.text('Take off'), findsNothing);
      expect(find.text('Cast'), findsNothing);
      for (final filter in const [
        'all',
        'weapons',
        'armour',
        'potions',
        'books',
        'materials',
      ]) {
        expect(find.byKey(Key('pack-filter-$filter')), findsOneWidget);
      }
    });

    testWidgets('wear succeeds and retains the selected filter', (
      tester,
    ) async {
      // arrange
      final town = await _openTownPack(
        tester,
        _townProfile(inventory: [_item('sword', ironSword)]),
      );
      addTearDown(town.close);
      await tester.tap(find.byKey(const Key('pack-filter-weapons')));
      await tester.pump();

      // act
      await tester.tap(find.byKey(const Key('pack-wear-sword')));
      await tester.pumpAndSettle();

      // assert
      expect(town.state.profile.equipment[EquipSlot.mainHand]?.id, 'sword');
      expect(town.state.profile.inventory, isEmpty);
      expect(_filter(tester, 'weapons').selected, isTrue);
    });

    testWidgets('wear refusal is exact and does not invent crawl actions', (
      tester,
    ) async {
      // arrange
      final profile = _townProfile(
        inventory: [_item('shield', kiteShield)],
        equipment: {EquipSlot.mainHand: _item('maul', maul)},
      );
      final town = await _openTownPack(tester, profile);
      addTearDown(town.close);
      final before = town.state;
      final wear = tester.widget<TextButton>(
        find.byKey(const Key('pack-wear-shield')),
      );

      // act

      // assert
      expect(find.text('both hands are on the weapon'), findsOneWidget);
      expect(wear.onPressed, isNull);
      expect(town.state, same(before));
      expect(find.byKey(const Key('pack-drink-shield')), findsNothing);
      expect(find.byKey(const Key('pack-drop-shield')), findsNothing);
    });

    testWidgets('read success and refusal retain Books context', (
      tester,
    ) async {
      // arrange
      final town = await _openTownPack(
        tester,
        _townProfile(
          inventory: [
            _item('book', bookOfFirebolt),
            _item('gated', bookOfFrostLance),
            _item('potion', healingPotion),
          ],
        ),
      );
      addTearDown(town.close);
      await tester.tap(find.byKey(const Key('pack-filter-books')));
      await tester.pump();
      expect(find.textContaining('teaches Firebolt'), findsOneWidget);

      // act
      await tester.tap(find.byKey(const Key('pack-read-book')));
      await tester.pumpAndSettle();

      // assert
      expect(town.state.profile.knownSpells, contains(firebolt.id));
      expect(
        town.state.profile.inventory.map((item) => item.id),
        isNot(contains('book')),
      );
      expect(_filter(tester, 'books').selected, isTrue);
      expect(find.text('needs Wrath 4'), findsOneWidget);
      final gatedRead = tester.widget<TextButton>(
        find.byKey(const Key('pack-read-gated')),
      );
      expect(gatedRead.onPressed, isNull);
      expect(find.byKey(const Key('pack-drink-potion')), findsNothing);
    });

    testWidgets('filters are transient and do not mutate town state', (
      tester,
    ) async {
      // arrange
      final town = await _openTownPack(
        tester,
        _townProfile(
          inventory: [_item('sword', ironSword)],
          materials: const {MaterialId.ore: 2},
        ),
      );
      addTearDown(town.close);
      final beforeState = town.state;
      final beforeProfile = town.state.profile;

      // act
      for (final filter in const [
        'all',
        'weapons',
        'armour',
        'potions',
        'books',
        'materials',
      ]) {
        await tester.tap(find.byKey(Key('pack-filter-$filter')));
        await tester.pump();
      }

      // assert
      expect(town.state, same(beforeState));
      expect(town.state.profile, same(beforeProfile));
      expect(town.state.profile.materials, const {MaterialId.ore: 2});
      expect(tester.takeException(), isNull);
    });
  });
}
