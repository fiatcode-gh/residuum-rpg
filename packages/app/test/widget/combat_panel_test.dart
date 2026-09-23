import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/combat_panel.dart';
import 'package:residuum_app/game/crawl_status.dart';
import 'package:residuum_app/game/dungeon_palette.dart';
import 'package:residuum_app/game/dungeon_scene.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/game_screen.dart';
import 'package:residuum_app/game/hero_panel.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../support/phone.dart';

const _arena = '''
#######
#.....#
#.....#
#.....#
#######''';

const _heroAt = Position(3, 2);
const _targetAt = Position(3, 1);

/// A monster with a fact for every line the panel draws: a stated reach
/// (defaulting to melee, so fact line B reads `Adjacent`), a resistance and
/// a vulnerability, so `Resists`/`Burns at` both have a word to print.
Actor _ghoulTarget({
  int hp = 6,
  int attackMin = 2,
  int attackMax = 4,
  int speed = 12,
  int reach = 1,
}) => Actor(
  id: 'ghoul-1',
  name: 'the ghoul',
  glyph: 'g',
  position: _targetAt,
  hp: hp,
  maxHp: 10,
  attackMin: attackMin,
  attackMax: attackMax,
  speed: speed,
  energy: actThreshold,
  reach: reach,
  resists: const {DamageType.fire},
  vulnerableTo: const {DamageType.frost},
);

GameState _game({
  Actor? target,
  Set<String> knownSpells = const {'firebolt', 'bind'},
  int mana = 4,
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
      hp: 20,
      maxHp: 20,
      attackMin: 4,
      attackMax: 6,
      speed: 10,
      energy: actThreshold,
    ),
    monsters: [target ?? _ghoulTarget()],
    rng: Rng(1),
    lootRng: Rng(2),
    visible: visible,
    explored: {...visible},
    buildFloor: (depth) => throw StateError('this arena has no floor below'),
    spells: spellsById,
    knownSpells: knownSpells,
    mana: mana,
  );
}

/// The panel alone, over a bare [GameViewState] — no bloc, exactly like
/// `hero_panel_test.dart`'s own pump helper: nothing here dispatches, so a
/// bloc would test nothing the constructor's facts do not already carry.
Future<void> _pumpPanel(WidgetTester tester, GameViewState state) async {
  await onTheTargetPhone(tester);
  await tester.pumpWidget(
    MaterialApp(
      home: Material(
        child: Align(
          alignment: Alignment.topLeft,
          child: CombatPanel(state: state),
        ),
      ),
    ),
  );
}

/// The real [GameScreen] over a real [GameBloc] — the panel swap and the
/// map rect's stability under arming are wiring the panel alone cannot
/// prove.
Future<GameBloc> _pumpBattle(WidgetTester tester, {GameState? game}) async {
  await onTheTargetPhone(tester);
  final bloc = GameBloc(game: game ?? _game(), stepDelay: Duration.zero);
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

void main() {
  testWidgets(
    'battle opens a 124 dp combat panel in place of the hero panel, and '
    'arming a spell moves the map rect not at all',
    (tester) async {
      final bloc = await _pumpBattle(tester);

      expect(find.byType(HeroPanel), findsNothing);
      final panel = tester.getRect(find.byKey(combatPanelKey));
      expect(panel.height, closeTo(124, 0.5));
      final unarmedMapRect = tester.getRect(find.byKey(dungeonSceneSlotKey));

      await tester.tap(find.byKey(const Key('spell:firebolt')));
      await tester.pumpAndSettle();

      expect(bloc.state.armedSpellId, 'firebolt');
      expect(tester.getRect(find.byKey(dungeonSceneSlotKey)), unarmedMapRect);
    },
  );

  group('TARGET', () {
    testWidgets('names the nearest monster, its wounds and its facts', (
      tester,
    ) async {
      final state = GameViewState(game: _game(), log: const []);

      await _pumpPanel(tester, state);

      expect(find.text('The ghoul'), findsOneWidget);
      expect(find.text('HP 6/10'), findsOneWidget);
      expect(find.text('ATK 2–4  SPD 12'), findsOneWidget);
      expect(
        find.text('Adjacent · Resists fire · Burns at frost'),
        findsOneWidget,
      );
    });

    testWidgets('names a ranged target by its stated reach', (tester) async {
      final state = GameViewState(
        game: _game(target: _ghoulTarget(reach: 3)),
        log: const [],
      );

      await _pumpPanel(tester, state);

      expect(
        find.text('Reach 3 · Resists fire · Burns at frost'),
        findsOneWidget,
      );
    });

    testWidgets('says so when nothing is in sight', (tester) async {
      final state = GameViewState(
        game: _game().copyWith(monsters: const []),
        log: const [],
      );

      await _pumpPanel(tester, state);

      expect(find.text('TARGET'), findsOneWidget);
      expect(find.text('No target in sight'), findsOneWidget);
    });
  });

  group('DAMAGE', () {
    testWidgets("shows the hero's own attack and 'melee' unarmed", (
      tester,
    ) async {
      final state = GameViewState(game: _game(), log: const []);

      await _pumpPanel(tester, state);

      expect(find.text('4–6'), findsOneWidget);
      expect(find.text('melee'), findsOneWidget);
    });

    testWidgets(
      "shows the bolt's own range and 'spell' when Firebolt is armed, and "
      'the melee range again once Bind is armed instead',
      (tester) async {
        final bolted = GameViewState(
          game: _game(),
          log: const [],
          armedSpellId: 'firebolt',
        );
        await _pumpPanel(tester, bolted);
        expect(find.text('2–4'), findsOneWidget);
        expect(find.text('spell'), findsOneWidget);

        final bound = GameViewState(
          game: _game(),
          log: const [],
          armedSpellId: 'bind',
        );
        await _pumpPanel(tester, bound);
        expect(find.text('4–6'), findsOneWidget);
        expect(find.text('melee'), findsOneWidget);
      },
    );
  });

  group('SPELL', () {
    testWidgets('unarmed shows the first readied spell', (tester) async {
      final state = GameViewState(game: _game(), log: const []);

      await _pumpPanel(tester, state);

      expect(find.text('READIED SPELL'), findsOneWidget);
      expect(find.text('Firebolt'), findsOneWidget);
      expect(find.text('Mana Cost 2'), findsOneWidget);
      expect(find.text('fire bolt 2–4'), findsOneWidget);
      expect(find.text('Fire | Wrath | Targeted'), findsOneWidget);
    });

    testWidgets('armed shows what is armed instead, self-cast tags included', (
      tester,
    ) async {
      final state = GameViewState(
        game: _game(knownSpells: const {'firebolt', 'mend'}),
        log: const [],
        armedSpellId: 'mend',
      );

      await _pumpPanel(tester, state);

      expect(find.text('ARMED SPELL'), findsOneWidget);
      expect(find.text('Mend'), findsOneWidget);
      expect(find.text('Mana Cost 3'), findsOneWidget);
      expect(find.text('Heals 8'), findsOneWidget);
      expect(find.text('Mending | Self'), findsOneWidget);
    });

    testWidgets('says so with nothing known', (tester) async {
      final state = GameViewState(
        game: _game(knownSpells: const {}, mana: 0),
        log: const [],
      );

      await _pumpPanel(tester, state);

      expect(find.text('READIED SPELL'), findsOneWidget);
      expect(find.text('No spell known'), findsOneWidget);
    });
  });

  group('YOU', () {
    testWidgets('shows the hero\'s own vitals under the meter keys', (
      tester,
    ) async {
      final state = GameViewState(game: _game(), log: const []);

      await _pumpPanel(tester, state);

      expect(tester.widget<Text>(find.byKey(hpMeterKey)).data, 'HP 20/20');
      expect(tester.widget<Text>(find.byKey(manaMeterKey)).data, 'Mana 4/4');
    });

    testWidgets('omits the mana row with nothing known', (tester) async {
      final state = GameViewState(
        game: _game(knownSpells: const {}, mana: 0),
        log: const [],
      );

      await _pumpPanel(tester, state);

      expect(find.byKey(manaMeterKey), findsNothing);
      expect(tester.widget<Text>(find.byKey(hpMeterKey)).data, 'HP 20/20');
    });
  });

  group('what the panel never draws', () {
    testWidgets('no percent, no to-hit figure, no flavour text', (
      tester,
    ) async {
      final state = GameViewState(
        game: _game(),
        log: const [],
        armedSpellId: 'firebolt',
      );

      await _pumpPanel(tester, state);

      expect(find.textContaining('%'), findsNothing);
      expect(find.textContaining('TO HIT'), findsNothing);
      expect(find.textContaining('to hit'), findsNothing);
    });
  });
}
