import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/battle_view.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/game_screen.dart';
import 'package:residuum_app/game/glyph_grid.dart';
import 'package:residuum_app/game/grid_geometry.dart';
import 'package:residuum_app/town/town_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

/// The battle dock: stage cards, turn strip, skill bar, and the gestures that
/// carry an armed cast through core's `targetId`.
///
/// Every test pumps the real [GameScreen] over a real [GameBloc] — the dock's
/// presence over an always-visible map is the unit's subject, and a fake screen
/// would test the test. Neither bloc is closed, per the suite's standing rule:
/// the widget test's clock is fake and the bloc closes itself on the event loop.

const _arena = '''
#######
#.....#
#.....#
#.....#
#######''';

/// A phone-sized viewport, which is where the screen has to read.
final Size _phone = Size(1080, 2424);

Actor ghoulAt(
  Position at, {
  String id = 'ghoul-1',
  int hp = 10,
  int speed = 10,
  int energy = actThreshold,
  Set<DamageType> resists = const {},
  Set<DamageType> vulnerableTo = const {},
}) => Actor(
  id: id,
  name: 'the ghoul',
  glyph: 'g',
  position: at,
  hp: hp,
  maxHp: 10,
  attackMin: 3,
  attackMax: 3,
  speed: speed,
  energy: energy,
  resists: resists,
  vulnerableTo: vulnerableTo,
);

Actor spitterAt(Position at) => Actor(
  id: 'spitter-1',
  name: 'the spitter',
  glyph: 'p',
  position: at,
  hp: 4,
  maxHp: 4,
  attackMin: 2,
  attackMax: 3,
  speed: 5,
  energy: 0,
  reach: 3,
);

GameState battleGame({
  Position heroAt = const Position(1, 1),
  List<Actor> monsters = const [],
  Set<String> knownSpells = const {},
  int mana = 0,
  Set<Position>? visible,
  bool isEncounter = false,
}) {
  final map = FloorMap.parse(_arena);
  final seen = visible ?? computeFov(map, heroAt, fovRadius);
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
    visible: seen,
    explored: {...seen},
    buildFloor: (depth) => throw StateError('no floor below'),
    spells: spellsById,
    knownSpells: knownSpells,
    mana: mana,
    isEncounter: isEncounter,
  );
}

Future<GameBloc> _pushGame(WidgetTester tester, GameState game) async {
  final town = TownBloc(profile: newProfile(worldSeed: 5));
  final bloc = GameBloc(game: game, stepDelay: Duration.zero);
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => MultiBlocProvider(
                providers: [
                  BlocProvider.value(value: town),
                  BlocProvider.value(value: bloc),
                ],
                child: const GameScreen(),
              ),
            ),
          ),
          child: const Text('down'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('down'));
  await tester.pumpAndSettle();
  return bloc;
}

/// Taps one tile of the map, through the grid's own geometry.
///
/// Both axes of the test arena fit any surface this suite pumps, so the camera
/// centres them and ignores its focus and pan; the hero position passed here is
/// only the state the suite ever taps from.
Future<void> _tapTile(WidgetTester tester, Position tile) async {
  final grid = find.byType(GlyphGrid);
  final size = tester.getSize(grid);
  final geometry = GridGeometry.camera(size, 7, 5, const Position(1, 1));
  final local =
      geometry.topLeftOf(tile.x, tile.y) +
      Offset(geometry.cellSize / 2, geometry.cellSize / 2);
  await tester.tapAt(tester.getTopLeft(grid) + local);
}

void main() {
  group('the dock', () {
    testWidgets('the map stays on screen while the dock is up', (tester) async {
      // arrange - the D90 standoff: a spitter holding reach three tiles out
      final game = battleGame(monsters: [spitterAt(const Position(4, 1))]);

      // act
      await _pushGame(tester, game);

      // assert - map and stage card visible in one pump
      expect(find.byType(GlyphGrid), findsOneWidget);
      expect(find.text('the spitter'), findsOneWidget);
    });

    testWidgets(
      'a floor tile one step toward the spitter moves the hero while the dock '
      'is up',
      (tester) async {
        // arrange - the D90 standoff
        final game = battleGame(monsters: [spitterAt(const Position(4, 1))]);
        final bloc = await _pushGame(tester, game);

        // act - tap the floor between hero and spitter
        await _tapTile(tester, const Position(2, 1));
        await tester.pumpAndSettle();

        // assert - the hero walked, the fight still holds, the map stayed
        expect(bloc.state.game.hero.position, const Position(2, 1));
        expect(find.byType(GlyphGrid), findsOneWidget);
        expect(find.text('the spitter'), findsOneWidget);
      },
    );

    testWidgets(
      'a far stage-card tap with nothing armed opens the enemy info',
      (tester) async {
        // arrange - the D90 standoff: the spitter three tiles out
        final game = battleGame(
          monsters: [
            Actor(
              id: 'spitter-1',
              name: 'the spitter',
              glyph: 'p',
              position: const Position(4, 1),
              hp: 4,
              maxHp: 4,
              attackMin: 2,
              attackMax: 3,
              speed: 5,
              energy: actThreshold,
              reach: 3,
              resists: const {DamageType.fire},
              vulnerableTo: const {DamageType.frost},
            ),
          ],
        );
        final bloc = await _pushGame(tester, game);
        final logBefore = bloc.state.log.length;

        // act
        await tester.tap(find.text('the spitter'));
        await tester.pumpAndSettle();

        // assert - the numbers on a sheet; nothing else happened
        expect(find.text('the spitter'), findsWidgets);
        expect(find.text('p'), findsWidgets);
        expect(find.text('4 / 4'), findsWidgets);
        expect(find.text('2–3'), findsOneWidget);
        expect(find.text('strikes at range 3'), findsOneWidget);
        expect(find.text('Speed 5'), findsOneWidget);
        expect(find.text('Resists fire'), findsOneWidget);
        expect(find.text('Burns at frost'), findsOneWidget);
        expect(bloc.state.log.length, logBefore);
        expect(bloc.state.game.hero.position, const Position(1, 1));
        expect(bloc.state.game.monsters.single.hp, 4);
        expect(bloc.state.armedAction, isNull);
      },
    );

    testWidgets('the dock rows leave when the last reach-holder dies', (
      tester,
    ) async {
      // arrange - three clean swings put the ten-hit ghoul down
      final game = battleGame(monsters: [ghoulAt(const Position(1, 2))]);
      final bloc = await _pushGame(tester, game);

      // act - the armed flow swings, one arm per swing: a step disarms
      for (var swing = 0; swing < 3; swing++) {
        bloc.add(const AttackArmed());
        await tester.pumpAndSettle();
        bloc.add(StageCardTapped(bloc.state.game.monsters.single));
        await tester.pumpAndSettle();
      }

      // assert
      expect(bloc.state.game.monsters, isEmpty);
      expect(find.byType(BattleDock), findsNothing);
      expect(find.byType(GlyphGrid), findsOneWidget);
    });

    testWidgets('the screen fits a phone with the dock up and with it down', (
      tester,
    ) async {
      // arrange - a caster in a fight, at the phone surface
      tester.view.physicalSize = _phone;
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final game = battleGame(
        monsters: [ghoulAt(const Position(1, 2))],
        knownSpells: const {'firebolt'},
        mana: 10,
      );
      final bloc = await _pushGame(tester, game);

      // assert - dock up: map, stage, bar, HP and log all on one screen
      expect(tester.takeException(), isNull);
      expect(find.byType(GlyphGrid), findsOneWidget);
      expect(find.text('the ghoul'), findsOneWidget);
      expect(find.text('✳ Firebolt 2'), findsOneWidget);
      expect(find.textContaining('Engaged'), findsOneWidget);
      await tester.tap(find.text('Attack'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('the ghoul'));
      await tester.pumpAndSettle();
      expect(find.textContaining('You hit the ghoul for 4.'), findsOneWidget);

      // act - two more swings end the fight, one arm per swing
      for (var swing = 0; swing < 2; swing++) {
        bloc.add(const AttackArmed());
        bloc.add(StageCardTapped(bloc.state.game.monsters.single));
        await tester.pumpAndSettle();
      }

      // assert - dock down: the crawl, unchanged; the log row still speaks
      expect(bloc.state.game.monsters, isEmpty);
      expect(bloc.state.log.last, 'The ghoul dies.');
      expect(find.byType(BattleDock), findsNothing);
      expect(find.byType(BattleSkillBar), findsNothing);
      expect(find.byType(GlyphGrid), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('the stage', () {
    testWidgets('the stage names, numbers and marks what holds reach', (
      tester,
    ) async {
      // arrange - adjacent wounded ghoul, spitter two tiles out along the sight line
      final game = battleGame(
        monsters: [
          ghoulAt(const Position(1, 2), hp: 6),
          spitterAt(const Position(3, 1)),
        ],
        visible: {
          const Position(1, 1),
          const Position(1, 2),
          const Position(3, 1),
        },
      );

      // act
      await _pushGame(tester, game);

      // assert - name and hit points by bar and number, range by word
      expect(find.text('the ghoul'), findsOneWidget);
      expect(find.text('6 / 10'), findsOneWidget);
      expect(find.text('the spitter'), findsOneWidget);
      expect(find.text('4 / 4'), findsOneWidget);
      expect(find.text('at range'), findsOneWidget);
      final bars = tester.widgetList<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bars.map((bar) => bar.value), contains(closeTo(6 / 10, 0.001)));
    });

    testWidgets('the chip row names NOW first, then arrivals as IN n', (
      tester,
    ) async {
      // arrange - the adjacent ghoul owes the next turn; a second ghoul walks
      // in from four tiles down the corridor
      final game = battleGame(
        monsters: [
          ghoulAt(const Position(1, 2)),
          ghoulAt(const Position(5, 1), id: 'ghoul-2'),
        ],
        visible: {
          const Position(1, 1),
          const Position(1, 2),
          const Position(5, 1),
        },
      );

      // act
      await _pushGame(tester, game);

      // assert - NOW first, then the arrivals by count; the words carry the
      // state, never dim-on-map
      expect(find.text('NOW — the ghoul'), findsOneWidget);
      expect(find.text('IN 4 — the ghoul'), findsOneWidget);
    });

    testWidgets('the dock header backs the cards and the chips in one panel', (
      tester,
    ) async {
      // arrange
      final game = battleGame(
        monsters: [ghoulAt(const Position(1, 2))],
        visible: {const Position(1, 1), const Position(1, 2)},
      );
      await _pushGame(tester, game);

      // act
      final backing = find.byKey(const Key('dock-backing'));

      // assert - one translucent dark panel holds the stage and the chips
      expect(backing, findsOneWidget);
      final container = tester.widget<Container>(backing);
      final color =
          container.color ?? (container.decoration! as BoxDecoration).color!;
      expect(color.a, lessThan(1.0));
      expect(
        find.descendant(of: backing, matching: find.text('the ghoul')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: backing, matching: find.text('NOW — the ghoul')),
        findsOneWidget,
      );
    });

    testWidgets('the stage reads on a phone-sized surface', (tester) async {
      // arrange
      tester.view.physicalSize = _phone;
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final game = battleGame(
        monsters: [
          ghoulAt(const Position(1, 2)),
          spitterAt(const Position(3, 1)),
        ],
        visible: {
          const Position(1, 1),
          const Position(1, 2),
          const Position(3, 1),
        },
      );

      // act
      await _pushGame(tester, game);

      // assert - nothing overflows: the dock, the chips, the bar and the word all render
      expect(find.byType(BattleDock), findsOneWidget);
      expect(find.text('the ghoul'), findsOneWidget);
      expect(find.text('the spitter'), findsOneWidget);
      expect(find.text('at range'), findsOneWidget);
      expect(find.text('NOW — the ghoul'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('the skill bar', () {
    testWidgets('the bar lists marking, name and cost, school first', (
      tester,
    ) async {
      // arrange - two known spells across two schools
      final game = battleGame(
        monsters: [ghoulAt(const Position(1, 2))],
        knownSpells: const {'firebolt', 'mend'},
        mana: 10,
      );

      // act
      await _pushGame(tester, game);

      // assert - school order first (Wrath before Mending), then name
      expect(find.text('✳ Firebolt 2'), findsOneWidget);
      expect(find.text('✚ Mend 3'), findsOneWidget);
    });

    testWidgets('a non-caster sees the bar: Attack and Wait', (tester) async {
      // arrange - the bar renders for every hero now; no spells to list
      final game = battleGame(monsters: [ghoulAt(const Position(1, 2))]);

      // act
      await _pushGame(tester, game);

      // assert
      expect(find.text('Attack'), findsOneWidget);
      expect(find.text('Wait'), findsOneWidget);
      expect(find.textContaining('Firebolt'), findsNothing);
    });

    testWidgets('tapping a skill arms it, marked by a word', (tester) async {
      // arrange
      final game = battleGame(
        monsters: [ghoulAt(const Position(1, 2))],
        knownSpells: const {'firebolt'},
        mana: 10,
      );
      final bloc = await _pushGame(tester, game);

      // act
      await tester.tap(find.text('✳ Firebolt 2'));
      await tester.pumpAndSettle();

      // assert
      expect(bloc.state.armedAction, const ArmedSpell('firebolt'));
      expect(find.text('✳ Firebolt 2 — armed'), findsOneWidget);
    });

    testWidgets('an armed cast at a stage card names the target', (
      tester,
    ) async {
      // arrange - the ghoul adjacent; the spitter holds reach further out
      final game = battleGame(
        monsters: [
          ghoulAt(const Position(1, 2)),
          spitterAt(const Position(3, 1)),
        ],
        knownSpells: const {'firebolt'},
        mana: 10,
        visible: {
          const Position(1, 1),
          const Position(1, 2),
          const Position(3, 1),
        },
      );
      final bloc = await _pushGame(tester, game);

      // act - arm, then tap the adjacent ghoul's card; a card beyond one step
      // is the walk sentence now, so the named cast lives on the adjacent card
      await tester.tap(find.text('✳ Firebolt 2'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('the ghoul'));
      await tester.pumpAndSettle();

      // assert - the shot landed on the named target, not the further one
      expect(
        bloc.state.log.where(
          (line) => line.startsWith('Firebolt burns the ghoul'),
        ),
        isNotEmpty,
      );
    });

    testWidgets('tapping Attack arms it, marked by a word', (tester) async {
      // arrange
      final game = battleGame(
        monsters: [ghoulAt(const Position(1, 2))],
        knownSpells: const {'firebolt'},
        mana: 10,
      );
      final bloc = await _pushGame(tester, game);

      // act
      await tester.tap(find.text('Attack'));
      await tester.pumpAndSettle();

      // assert
      expect(bloc.state.armedAction, const ArmedAttack());
      expect(find.text('Attack — armed'), findsOneWidget);
    });

    testWidgets('tapping armed Attack again disarms it', (tester) async {
      // arrange
      final game = battleGame(
        monsters: [ghoulAt(const Position(1, 2))],
        knownSpells: const {'firebolt'},
        mana: 10,
      );
      final bloc = await _pushGame(tester, game);

      // act
      await tester.tap(find.text('Attack'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Attack — armed'));
      await tester.pumpAndSettle();

      // assert
      expect(bloc.state.armedAction, isNull);
      expect(find.text('Attack'), findsOneWidget);
    });

    testWidgets('the bar reads Attack, the spells, then Wait', (tester) async {
      // arrange
      final game = battleGame(
        monsters: [ghoulAt(const Position(1, 2))],
        knownSpells: const {'firebolt'},
        mana: 10,
      );
      await _pushGame(tester, game);

      // act + assert - document order: Attack before the spell before Wait
      final labels = find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data != null &&
            const ['Attack', '✳ Firebolt 2', 'Wait'].contains(widget.data),
      );
      final texts = labels.evaluate().map((element) {
        final text = element.widget as Text;
        return text.data;
      }).toList();
      expect(texts, ['Attack', '✳ Firebolt 2', 'Wait']);
    });

    testWidgets('a bare card tap opens the enemy info, never the bump', (
      tester,
    ) async {
      // arrange - the ghoul adjacent; nothing armed
      final game = battleGame(
        monsters: [
          ghoulAt(
            const Position(1, 2),
            resists: const {DamageType.fire},
            vulnerableTo: const {DamageType.frost},
          ),
        ],
        knownSpells: const {'firebolt'},
        mana: 10,
      );
      final bloc = await _pushGame(tester, game);

      // act
      await tester.tap(find.text('the ghoul'));
      await tester.pumpAndSettle();

      // assert - the sheet, and the turn unbought: no swing, no claws
      expect(find.text('strikes adjacent'), findsOneWidget);
      expect(find.text('3–3'), findsOneWidget);
      expect(find.text('Resists fire'), findsOneWidget);
      expect(find.text('Burns at frost'), findsOneWidget);
      expect(find.textContaining('You hit the ghoul'), findsNothing);
      expect(bloc.state.game.monsters.single.hp, 10);
      expect(bloc.state.game.hero.hp, 20);
      expect(bloc.state.armedAction, isNull);
    });

    testWidgets('armed Attack and a marked card tap is the bump', (
      tester,
    ) async {
      // arrange
      final game = battleGame(
        monsters: [ghoulAt(const Position(1, 2))],
        knownSpells: const {'firebolt'},
        mana: 10,
      );
      final bloc = await _pushGame(tester, game);

      // act - arm attack, then tap the adjacent ghoul's card
      await tester.tap(find.text('Attack'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('the ghoul'));
      await tester.pumpAndSettle();

      // assert - the bump fired through the armed flow
      expect(find.text('You hit the ghoul for 4.'), findsOneWidget);
      expect(bloc.state.armedAction, isNull);
    });

    testWidgets(
      'armed Attack at an unmarked card says walk and keeps the arm',
      (tester) async {
        // arrange - the spitter holds reach three tiles out: a stage card,
        // but not an attack target
        final game = battleGame(
          monsters: [spitterAt(const Position(4, 1))],
          knownSpells: const {'firebolt'},
          mana: 10,
        );
        final bloc = await _pushGame(tester, game);

        // act
        await tester.tap(find.text('Attack'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('the spitter'));
        await tester.pumpAndSettle();

        // assert - the sentence, and the arm stays for the next tap
        expect(bloc.state.log.last, 'the spitter is out of reach. Walk to it.');
        expect(bloc.state.armedAction, const ArmedAttack());
        expect(bloc.state.game.hero.position, const Position(1, 1));
      },
    );

    testWidgets('arming the attack disarms the spell and the other way', (
      tester,
    ) async {
      // arrange
      final game = battleGame(
        monsters: [ghoulAt(const Position(1, 2))],
        knownSpells: const {'firebolt'},
        mana: 10,
      );
      final bloc = await _pushGame(tester, game);

      // act
      await tester.tap(find.text('✳ Firebolt 2'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Attack'));
      await tester.pumpAndSettle();

      // assert - one armed slot at a time
      expect(bloc.state.armedAction, const ArmedAttack());
      expect(find.text('Attack — armed'), findsOneWidget);
      expect(find.text('✳ Firebolt 2 — armed'), findsNothing);
    });

    testWidgets('mend casts on the hero without a card tap', (tester) async {
      // arrange
      final game = battleGame(
        heroAt: const Position(1, 1),
        monsters: [ghoulAt(const Position(1, 2))],
        knownSpells: const {'mend'},
        mana: 10,
      );
      final bloc = await _pushGame(tester, game);

      // act - cast from the bar directly, no card tap
      bloc.add(const CastPressed('mend'));
      await tester.pumpAndSettle();

      // assert - the pool paid for it and no target was needed
      expect(bloc.state.game.mana, 7);
      expect(
        bloc.state.log.where((line) => line.startsWith('You mend')),
        isNotEmpty,
      );
    });

    testWidgets('a refused armed cast speaks in the log', (tester) async {
      // arrange - the pool cannot pay for the shot
      final game = battleGame(
        monsters: [ghoulAt(const Position(1, 2))],
        knownSpells: const {'firebolt'},
        mana: 1,
      );
      final bloc = await _pushGame(tester, game);

      // act - arm and cast anyway; the button stays tappable
      await tester.tap(find.text('✳ Firebolt 2'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('the ghoul'));
      await tester.pumpAndSettle();

      // assert
      expect(find.text('not enough mana'), findsNothing);
      expect(
        bloc.state.log.where((line) => line.startsWith('Not enough mana')),
        isNotEmpty,
      );
    });
  });

  group('the wait surfaces', () {
    testWidgets('the bar offers Wait and tapping it holds ground', (
      tester,
    ) async {
      // arrange - a caster in a fight
      final game = battleGame(
        monsters: [ghoulAt(const Position(1, 2))],
        knownSpells: const {'firebolt'},
        mana: 10,
      );
      final bloc = await _pushGame(tester, game);

      // act
      await tester.tap(find.text('Wait'));
      await tester.pumpAndSettle();

      // assert - the sentence and the turn: the ghoul answered
      expect(find.text('You hold your ground.'), findsOneWidget);
      expect(bloc.state.game.hero.position, const Position(1, 1));
      expect(bloc.state.game.hero.hp, lessThan(20));
    });

    testWidgets('a live road encounter offers Wait in its control row', (
      tester,
    ) async {
      // arrange - an encounter-flagged arena, nothing holding reach
      final game = battleGame(
        monsters: [ghoulAt(const Position(5, 1), speed: 1)],
        isEncounter: true,
      );
      await _pushGame(tester, game);

      // act + assert - the row's Wait exists while the fight is live
      expect(find.text('Wait'), findsOneWidget);
    });

    testWidgets('a cleared road has no Wait control', (tester) async {
      // arrange - an encounter with every monster gone
      final game = battleGame(isEncounter: true);
      await _pushGame(tester, game);

      // assert
      expect(find.text('Wait'), findsNothing);
    });

    testWidgets('a crawl with no fight live has no Wait control', (
      tester,
    ) async {
      // arrange
      final game = battleGame();
      await _pushGame(tester, game);

      // assert - the bar is closed and the row is the crawl's own
      expect(find.text('Wait'), findsNothing);
    });
  });
}
