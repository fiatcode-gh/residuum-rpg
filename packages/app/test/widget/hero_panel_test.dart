import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/hero_panel.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../support/phone.dart';

const _arena = '''
#####
#...#
#####''';

const _heroAt = Position(1, 1);

/// A weapon whose display name is the contract's own worst case: three
/// affixes' worth of words plus the base name, wrapped by [Rarity.rare]'s
/// two-affix tier.
final _keenIronSwordOfEmbers = Item(
  id: 'kit-1',
  base: ironSword,
  rarity: Rarity.rare,
  affixes: const [
    Affix(id: 'keen', affixName: 'Keen', isPrefix: true),
    Affix(id: 'of-embers', affixName: 'of Embers', isPrefix: false),
  ],
);

final _plainMailHauberk = Item(
  id: 'kit-2',
  base: mailHauberk,
  rarity: Rarity.common,
);

Item _potion(String id) =>
    Item(id: id, base: healingPotion, rarity: Rarity.common);

GameState _game({
  int hp = 12,
  int maxHp = 20,
  int attackMin = 2,
  int attackMax = 3,
  int gold = 40,
  Equipment equipment = const {},
  List<Item> inventory = const [],
  Set<String> knownSpells = const {},
  Map<SkillId, SkillState> skills = untrainedSkills,
  int mana = 0,
}) {
  final map = FloorMap.parse(_arena);
  final visible = computeFov(map, _heroAt, fovRadius);
  return GameState(
    map: map,
    hero: Actor(
      id: 'hero',
      name: 'you',
      glyph: '@',
      position: _heroAt,
      hp: hp,
      maxHp: maxHp,
      attackMin: attackMin,
      attackMax: attackMax,
      speed: 10,
      energy: actThreshold,
    ),
    monsters: const [],
    rng: Rng(1),
    lootRng: Rng(2),
    visible: visible,
    explored: {...visible},
    buildFloor: (depth) => throw StateError('this arena has no floor below'),
    gold: gold,
    equipment: equipment,
    inventory: inventory,
    skills: skills,
    spells: spellsById,
    knownSpells: knownSpells,
    mana: mana,
  );
}

Future<void> _pumpPanel(
  WidgetTester tester,
  GameState game, {
  String? heroLabel = 'Mira',
  TextScaler? textScaler,
}) async {
  await onTheTargetPhone(tester);
  final state = GameViewState(game: game, log: const []);
  final app = MaterialApp(
    home: Material(
      child: Align(
        alignment: Alignment.topLeft,
        child: HeroPanel(state: state, heroLabel: heroLabel),
      ),
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
}

void main() {
  testWidgets(
    'renders the hero label, the three columns in flex order, and every '
    'equipped/carried fact',
    (tester) async {
      // act
      await _pumpPanel(
        tester,
        _game(
          hp: 12,
          maxHp: 20,
          gold: 40,
          equipment: {
            EquipSlot.mainHand: _keenIronSwordOfEmbers,
            EquipSlot.chest: _plainMailHauberk,
          },
          inventory: [_potion('kit-3'), _potion('kit-4'), _potion('kit-5')],
        ),
      );

      // assert
      expect(find.byKey(heroPanelKey), findsOneWidget);
      expect(tester.getSize(find.byKey(heroPanelKey)).height, 102);
      expect(find.text('MIRA'), findsOneWidget);
      expect(find.text('HP 12/20'), findsOneWidget);
      expect(find.text('ATK 5–8  ARM 4  GOLD 40'), findsOneWidget);
      expect(find.text('Rare Keen Iron Sword of Embers'), findsOneWidget);
      expect(find.text('Common Mail Hauberk'), findsOneWidget);
      expect(find.text('Potion ×3'), findsOneWidget);
      expect(find.text('3/20'), findsOneWidget);

      final leftX = tester.getTopLeft(find.text('MIRA')).dx;
      final middleX = tester.getTopLeft(find.text('WEAPON')).dx;
      final rightX = tester.getTopLeft(find.text('QUICK')).dx;
      expect(leftX, lessThan(middleX));
      expect(middleX, lessThan(rightX));
    },
  );

  testWidgets(
    'falls back to bare fists and no armour, and clamps a dead hero at zero',
    (tester) async {
      // act
      await _pumpPanel(tester, _game(hp: -5, maxHp: 20));

      // assert
      expect(find.text('HP 0/20'), findsOneWidget);
      expect(find.text('Bare fists'), findsOneWidget);
      expect(find.text('None'), findsOneWidget);
      expect(find.text('Potion ×0'), findsOneWidget);
      expect(find.text('0/20'), findsOneWidget);
    },
  );

  testWidgets(
    'has no mana row until the hero knows a spell, and the panel height is '
    'unchanged either way',
    (tester) async {
      // act
      await _pumpPanel(tester, _game());
      final withoutSpell = tester.getSize(find.byKey(heroPanelKey)).height;

      // assert
      expect(find.byKey(manaMeterKey), findsNothing);
      expect(find.textContaining('Mana'), findsNothing);
      expect(find.byKey(hpMeterKey), findsOneWidget);

      await _pumpPanel(
        tester,
        _game(
          knownSpells: const {'firebolt'},
          mana: 3,
          skills: {
            ...untrainedSkills,
            SkillId.wrath: const SkillState(level: 2),
          },
        ),
      );
      final withSpell = tester.getSize(find.byKey(heroPanelKey)).height;

      // assert
      expect(find.text('Mana 3/5'), findsOneWidget);
      expect(find.byKey(manaMeterKey), findsOneWidget);
      expect(withSpell, withoutSpell);
    },
  );

  testWidgets('wraps the longest weapon name onto at most two lines without '
      'overflowing, and grows with text scale to 132.6', (tester) async {
    // act
    await _pumpPanel(
      tester,
      _game(equipment: {EquipSlot.mainHand: _keenIronSwordOfEmbers}),
    );

    // assert
    expect(tester.takeException(), isNull);
    final nameText = tester.widget<Text>(
      find.text('Rare Keen Iron Sword of Embers'),
    );
    expect(nameText.maxLines, 2);
    expect(nameText.overflow, TextOverflow.ellipsis);

    // act
    await _pumpPanel(
      tester,
      _game(equipment: {EquipSlot.mainHand: _keenIronSwordOfEmbers}),
      textScaler: TextScaler.linear(1.3),
    );

    // assert
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byKey(heroPanelKey)).height,
      closeTo(132.6, 0.1),
    );
  });

  testWidgets(
    'the wrapped two-line weapon name box stays unclipped at 1.3x text '
    'scale',
    (tester) async {
      // act
      const scaler = TextScaler.linear(1.3);
      await _pumpPanel(
        tester,
        _game(equipment: {EquipSlot.mainHand: _keenIronSwordOfEmbers}),
        textScaler: scaler,
      );

      // assert
      final finder = find.text('Rare Keen Iron Sword of Embers');
      final text = tester.widget<Text>(finder);
      final painter = TextPainter(
        text: TextSpan(text: text.data, style: text.style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: text.maxLines,
      )..layout(maxWidth: tester.getSize(finder).width);
      expect(
        tester.getSize(finder).height,
        greaterThanOrEqualTo(painter.height - 0.5),
      );
    },
  );

  testWidgets('never renders content the contract keeps off the panel', (
    tester,
  ) async {
    // act
    await _pumpPanel(tester, _game());

    // assert
    expect(find.text('WANDERER'), findsNothing);
    expect(find.textContaining('Torch'), findsNothing);
    expect(find.textContaining('Hungry'), findsNothing);
    expect(find.textContaining('Seed'), findsNothing);
  });
}
