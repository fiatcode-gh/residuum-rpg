import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/battle_view.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/game_screen.dart';
import 'package:residuum_app/game/dungeon_palette.dart';
import 'package:residuum_app/game/dungeon_scene.dart';
import 'package:residuum_app/game/grid_geometry.dart';
import 'package:residuum_app/town/town_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import 'support/log_sentences.dart';

/// The battle dock: activation timeline, skill bar, and the gestures that
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

Future<GameBloc> _pushGame(
  WidgetTester tester,
  GameState game, {
  TextScaler? textScaler,
}) async {
  final town = TownBloc(profile: newProfile(worldSeed: 5));
  final bloc = GameBloc(game: game, stepDelay: Duration.zero);
  final app = MaterialApp(
    home: Builder(
      builder: (context) => TextButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MultiBlocProvider(
              providers: [
                BlocProvider.value(value: town),
                BlocProvider.value(value: bloc),
              ],
              child: const GameScreen(palette: DungeonPalette.crypt),
            ),
          ),
        ),
        child: const Text('down'),
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
  await tester.tap(find.text('down'));
  await tester.pumpAndSettle();
  return bloc;
}

/// Taps one tile of the map, through the scene's own geometry.
///
/// Both axes of the test arena fit any surface this suite pumps, so the camera
/// centres them and ignores its focus and pan; the hero position passed here is
/// only the state the suite ever taps from.
Future<void> _tapTile(WidgetTester tester, Position tile) async {
  final scene = find.byKey(dungeonSceneKey);
  final size = tester.getSize(scene);
  final geometry = GridGeometry.camera(size, 7, 5, const Position(1, 1));
  final local =
      geometry.topLeftOf(tile.x, tile.y) +
      Offset(geometry.cellSize / 2, geometry.cellSize / 2);
  await tester.tapAt(tester.getTopLeft(scene) + local);
}

void main() {
  group('the dock', () {
    testWidgets('the map stays on screen while the dock is up', (tester) async {
      // arrange - the D90 standoff: a spitter holding reach three tiles out
      final game = battleGame(monsters: [spitterAt(const Position(4, 1))]);

      // act
      await _pushGame(tester, game);

      // assert - map and timeline token visible in one pump
      expect(find.byType(DungeonSceneHost), findsOneWidget);
      expect(find.byType(BattleDock), findsOneWidget);
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
        expect(find.byType(DungeonSceneHost), findsOneWidget);
        expect(find.byType(BattleDock), findsOneWidget);
      },
    );

    testWidgets(
      'a timeline actor token with nothing armed opens the enemy info',
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
              speed: 20,
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
        await tester.tap(find.byKey(const Key('timeline-actor-spitter-1-1')));
        await tester.pumpAndSettle();

        // assert - the numbers on a sheet; nothing else happened
        expect(find.text('the spitter'), findsWidgets);
        expect(find.text('Wounds 4 / 4'), findsOneWidget);
        expect(find.text('2–3'), findsOneWidget);
        expect(find.text('Speed 20'), findsOneWidget);
        expect(find.text('Resists fire'), findsOneWidget);
        expect(find.text('Burns at frost'), findsOneWidget);
        expect(bloc.state.log.length, logBefore);
        expect(bloc.state.game.hero.position, const Position(1, 1));
        expect(bloc.state.game.monsters.single.hp, 4);
        expect(bloc.state.armedSpellId, isNull);
      },
    );

    testWidgets('the dock rows leave when the last reach-holder dies', (
      tester,
    ) async {
      // arrange - three clean swings put the ten-hit ghoul down
      final game = battleGame(monsters: [ghoulAt(const Position(1, 2))]);
      final bloc = await _pushGame(tester, game);

      // act - the map tap swings, once per turn
      for (var swing = 0; swing < 3; swing++) {
        bloc.add(TileTapped(bloc.state.game.monsters.single.position));
        await tester.pumpAndSettle();
      }

      // assert
      expect(bloc.state.game.monsters, isEmpty);
      expect(find.byType(BattleDock), findsNothing);
      expect(find.byType(DungeonSceneHost), findsOneWidget);
    });

    testWidgets('the Flame scene survives the battle dock closing', (
      tester,
    ) async {
      final bloc = await _pushGame(
        tester,
        battleGame(monsters: [ghoulAt(const Position(1, 2))]),
      );
      final before = tester
          .widget<GameWidget<FlameGame>>(find.byKey(dungeonSceneKey))
          .game;

      for (var swing = 0; swing < 3; swing++) {
        bloc.add(TileTapped(bloc.state.game.monsters.single.position));
        await tester.pumpAndSettle();
      }

      expect(find.byType(BattleDock), findsNothing);
      expect(
        tester.widget<GameWidget<FlameGame>>(find.byKey(dungeonSceneKey)).game,
        same(before),
      );
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

      // assert - dock up: map, timeline, bar, HP and log all on one screen
      expect(tester.takeException(), isNull);
      expect(find.byType(DungeonSceneHost), findsOneWidget);
      expect(find.byType(BattleDock), findsOneWidget);
      expect(find.text('✳ Firebolt 2'), findsOneWidget);
      expect(find.textContaining('Engaged'), findsOneWidget);
      await _tapTile(tester, const Position(1, 2));
      await tester.pumpAndSettle();
      expect(find.textContaining('You hit the ghoul for 4.'), findsOneWidget);

      // act - two more swings end the fight, one arm per swing
      for (var swing = 0; swing < 2; swing++) {
        bloc.add(TileTapped(bloc.state.game.monsters.single.position));
        await tester.pumpAndSettle();
      }

      // assert - dock down: the crawl, unchanged; the log row still speaks
      expect(bloc.state.game.monsters, isEmpty);
      expect(logSentences(bloc.state).last, 'The ghoul dies.');
      expect(find.byType(BattleDock), findsNothing);
      expect(find.text('✳ Firebolt 2'), findsNothing);
      expect(find.text('Wait'), findsNothing);
      expect(find.byType(DungeonSceneHost), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'the caption row reads at elevated text scale without overflow',
      (tester) async {
        // arrange - a simple battle to show the activation timeline
        tester.view.physicalSize = _phone;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        final game = battleGame(monsters: [ghoulAt(const Position(1, 2))]);

        // act - render the dock at 2.0x text scale
        await _pushGame(tester, game, textScaler: TextScaler.linear(2.0));

        // assert - no overflow exception raised
        expect(tester.takeException(), isNull);
        expect(find.byType(BattleDock), findsOneWidget);
      },
    );
  });

  group('the activation timeline', () {
    testWidgets('shows literal repeated occurrences and the closing hero', (
      tester,
    ) async {
      // arrange - a speed-20 duplicate is owed twice before the next hero.
      final game = battleGame(
        monsters: [
          ghoulAt(const Position(1, 2), id: 'ghoul-1', speed: 20),
          ghoulAt(const Position(3, 1), id: 'ghoul-2', energy: 50),
        ],
        visible: {
          const Position(1, 1),
          const Position(1, 2),
          const Position(3, 1),
        },
      );

      // act
      await _pushGame(tester, game);

      // assert - current hero, each owed occurrence, then next hero.
      expect(find.byKey(const Key('timeline-current-hero')), findsOneWidget);
      expect(find.byKey(const Key('timeline-actor-ghoul-1-1')), findsOneWidget);
      expect(find.byKey(const Key('timeline-actor-ghoul-1-2')), findsOneWidget);
      expect(find.byKey(const Key('timeline-actor-ghoul-2-3')), findsOneWidget);
      expect(find.byKey(const Key('timeline-next-hero')), findsOneWidget);
      void expectCell(Key key, String glyph, String word) {
        expect(
          find.descendant(of: find.byKey(key), matching: find.text(glyph)),
          findsOneWidget,
        );
        expect(
          find.descendant(of: find.byKey(key), matching: find.text(word)),
          findsOneWidget,
        );
      }

      expectCell(const Key('timeline-current-hero'), '@', 'You');
      expectCell(const Key('timeline-actor-ghoul-1-1'), 'g¹', 'the ghoul¹');
      expectCell(const Key('timeline-actor-ghoul-1-2'), 'g¹', 'the ghoul¹');
      expectCell(const Key('timeline-actor-ghoul-2-3'), 'g²', 'the ghoul²');
      expectCell(const Key('timeline-next-hero'), '@', 'You');
      expect(find.text('NOW'), findsOneWidget);
      expect(find.text('NEXT'), findsOneWidget);
      final currentSemantics = tester.widget<Semantics>(
        find
            .ancestor(
              of: find.byKey(const Key('timeline-current-hero')),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(currentSemantics.properties.label, 'You, current activation');
      final firstActorSemantics = tester.widget<Semantics>(
        find
            .ancestor(
              of: find.byKey(const Key('timeline-actor-ghoul-1-1')),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(firstActorSemantics.properties.label, 'the ghoul¹');
      expect(firstActorSemantics.properties.button, isTrue);
      final secondActorSemantics = tester.widget<Semantics>(
        find
            .ancestor(
              of: find.byKey(const Key('timeline-actor-ghoul-2-3')),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(secondActorSemantics.properties.label, 'the ghoul²');
      expect(secondActorSemantics.properties.button, isTrue);
      expect(
        tester
            .widget<Semantics>(
              find
                  .ancestor(
                    of: find.byKey(const Key('timeline-next-hero')),
                    matching: find.byType(Semantics),
                  )
                  .first,
            )
            .properties
            .label,
        'You, next activation',
      );
      expect(find.textContaining('IN '), findsNothing);
    });
    testWidgets(
      'the NEXT caption sits over the token it labels, not a guessed gap',
      (tester) async {
        // arrange - same scene as the row above, so the first "next" token
        // is `timeline-actor-ghoul-1-1`.
        final game = battleGame(
          monsters: [
            ghoulAt(const Position(1, 2), id: 'ghoul-1', speed: 20),
            ghoulAt(const Position(3, 1), id: 'ghoul-2', energy: 50),
          ],
          visible: {
            const Position(1, 1),
            const Position(1, 2),
            const Position(3, 1),
          },
        );

        // act
        await _pushGame(tester, game);

        // assert - the caption's left edge lands on the token it names,
        // never on a gap guessed from the chevron glyph's own advance.
        final nextDx = tester.getTopLeft(find.text('NEXT')).dx;
        final firstNextTokenDx = tester
            .getTopLeft(find.byKey(const Key('timeline-actor-ghoul-1-1')))
            .dx;
        expect(nextDx, closeTo(firstNextTokenDx, 0.5));
      },
    );
    testWidgets(
      'a duplicate survivor keeps its suffix in the timeline and inspect after '
      'a sibling dies',
      (tester) async {
        // arrange - both identities are visible before a lethal map action.
        final bloc = await _pushGame(
          tester,
          battleGame(
            monsters: [
              ghoulAt(const Position(1, 2), hp: 4),
              ghoulAt(const Position(2, 1), id: 'ghoul-2'),
            ],
            visible: {
              const Position(1, 1),
              const Position(1, 2),
              const Position(2, 1),
            },
          ),
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('dock-backing')),
            matching: find.text('g²'),
          ),
          findsOneWidget,
        );

        // act - the first sibling dies through the normal battle state path.
        bloc.add(const TileTapped(Position(1, 2)));
        await tester.pumpAndSettle();

        // assert - the fixed suffix survives in state, timeline, and inspect.
        expect(bloc.state.game.monsters.map((actor) => actor.id), ['ghoul-2']);
        expect(bloc.state.presentationOf('ghoul-2')?.glyphLabel, 'g²');
        expect(
          find.descendant(
            of: find.byKey(const Key('dock-backing')),
            matching: find.text('g²'),
          ),
          findsOneWidget,
        );
        await tester.tap(
          find.ancestor(
            of: find.descendant(
              of: find.byKey(const Key('dock-backing')),
              matching: find.text('g²'),
            ),
            matching: find.byType(InkWell),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.text('the ghoul²'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.text('g²'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('truncates at a hidden due actor without a placeholder', (
      tester,
    ) async {
      // arrange - the hidden due actor comes before the visible actor.
      final hidden = ghoulAt(
        const Position(5, 1),
        id: 'ghoul-hidden',
        speed: 20,
      );
      final visible = ghoulAt(const Position(1, 2), id: 'ghoul-visible');
      final game = battleGame(
        monsters: [hidden, visible],
        visible: {const Position(1, 1), const Position(1, 2)},
      );

      // act
      await _pushGame(tester, game);

      // assert - only the truthful current hero prefix is rendered.
      expect(find.byKey(const Key('timeline-current-hero')), findsOneWidget);
      expect(find.byKey(const Key('timeline-next-hero')), findsNothing);
      expect(
        find.byKey(const Key('timeline-actor-ghoul-hidden-1')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('timeline-actor-ghoul-visible-1')),
        findsNothing,
      );
      expect(find.text('…'), findsNothing);
      expect(find.text('...'), findsNothing);
      expect(find.textContaining('IN '), findsNothing);
      expect(find.textContaining('NOW —'), findsNothing);
      expect(find.text('NOW'), findsOneWidget);
      expect(find.text('NEXT'), findsNothing);
    });

    testWidgets('the dock scrolls a truly overflowing legal queue on a phone', (
      tester,
    ) async {
      // arrange - six speed-20 actors each owe two turns before the hero.
      tester.view.physicalSize = _phone;
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final game = battleGame(
        monsters: [
          ghoulAt(const Position(1, 2), speed: 20),
          ghoulAt(const Position(2, 1), id: 'ghoul-2', speed: 20),
          ghoulAt(const Position(3, 1), id: 'ghoul-3', speed: 20),
          ghoulAt(const Position(4, 1), id: 'ghoul-4', speed: 20),
          ghoulAt(const Position(5, 1), id: 'ghoul-5', speed: 20),
          ghoulAt(const Position(2, 2), id: 'ghoul-6', speed: 20),
        ],
        visible: {
          const Position(1, 1),
          const Position(1, 2),
          const Position(2, 1),
          const Position(3, 1),
          const Position(4, 1),
          const Position(5, 1),
          const Position(2, 2),
        },
      );

      // act
      final bloc = await _pushGame(tester, game);
      final dock = find.byKey(const Key('dock-backing'));
      final scrollable = find.descendant(
        of: dock,
        matching: find.byType(Scrollable),
      );
      final laterToken = find.byKey(const Key('timeline-actor-ghoul-6-12'));
      final currentHero = find.byKey(const Key('timeline-current-hero'));
      final currentHeroRectBefore = tester.getRect(currentHero);

      // assert - a real queue exceeds the phone, then drag reaches its end.
      final position = tester.state<ScrollableState>(scrollable).position;
      expect(position.maxScrollExtent, greaterThan(0));
      expect(
        tester.getRect(laterToken).left,
        greaterThan(tester.getRect(dock).right),
      );
      await tester.drag(scrollable, const Offset(-1000, 0));
      await tester.pumpAndSettle();
      expect(position.pixels, greaterThan(0));
      expect(tester.getRect(currentHero), currentHeroRectBefore);
      expect(
        tester.getRect(laterToken).right,
        lessThanOrEqualTo(tester.getRect(dock).right),
      );
      await tester.tap(laterToken);
      await tester.pumpAndSettle();
      expect(bloc.state.selectedActorId, 'ghoul-6');
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('the ghoul⁶'),
        ),
        findsOneWidget,
      );
      expect(find.byType(DungeonSceneHost), findsOneWidget);
      expect(find.text('Wait'), findsOneWidget);
      expect(find.textContaining('Engaged'), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('the target mark on the map', () {
    testWidgets(
      'an armed spell marks every visible monster, not the timeline',
      (tester) async {
        // arrange - the ghoul adjacent and a far spitter in the sight line
        final game = battleGame(
          monsters: [
            ghoulAt(const Position(1, 2)),
            spitterAt(const Position(4, 1)),
          ],
          knownSpells: const {'firebolt'},
          mana: 10,
          visible: {
            const Position(1, 1),
            const Position(1, 2),
            const Position(4, 1),
          },
        );
        final bloc = await _pushGame(tester, game);

        // act - arm the spell from the shelf
        await tester.tap(find.text('✳ Firebolt 2'));
        await tester.pumpAndSettle();

        // assert - the sight rule marks both; the timeline remains view-only.
        expect(bloc.state.armedTargets, {'ghoul-1', 'spitter-1'});
        expect(
          find.byKey(const Key('timeline-actor-ghoul-1-1')),
          findsOneWidget,
        );
      },
    );
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

    testWidgets('a non-caster sees the shelf, with no Attack row', (
      tester,
    ) async {
      // arrange - the shelf renders for every hero; no spells to list
      final game = battleGame(monsters: [ghoulAt(const Position(1, 2))]);

      // act
      await _pushGame(tester, game);

      // assert
      expect(find.text('Attack'), findsNothing);
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
      expect(bloc.state.armedSpellId, 'firebolt');
      expect(find.text('✳ Firebolt 2'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('✳ Firebolt 2')),
          matching: find.text('— armed'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('an armed cast at a visible monster names the target', (
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

      // act - arm from the shelf, then tap the adjacent ghoul's tile on the map
      await tester.tap(find.text('✳ Firebolt 2'));
      await tester.pumpAndSettle();
      await _tapTile(tester, const Position(1, 2));
      await tester.pumpAndSettle();

      // assert - the shot landed on the named target, not the further one
      expect(
        logSentences(bloc.state)
            .where((line) => line.startsWith('Firebolt burns the ghoul')),
        isNotEmpty,
      );
    });

    testWidgets('tapping the armed spell again disarms it', (tester) async {
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
      await tester.tap(find.text('✳ Firebolt 2'));
      await tester.pumpAndSettle();

      // assert
      expect(bloc.state.armedSpellId, isNull);
      expect(find.text('✳ Firebolt 2'), findsOneWidget);
    });

    testWidgets('the shelf reads the spell first, then Wait', (tester) async {
      // arrange
      final game = battleGame(
        monsters: [ghoulAt(const Position(1, 2))],
        knownSpells: const {'firebolt'},
        mana: 10,
      );
      await _pushGame(tester, game);

      // act + assert - one shelf; no Attack row anywhere on it
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
      expect(texts, ['✳ Firebolt 2', 'Wait']);
    });

    testWidgets('a timeline actor token opens enemy info, never the bump', (
      tester,
    ) async {
      // arrange - the ghoul adjacent; nothing armed
      final game = battleGame(
        monsters: [
          ghoulAt(
            const Position(1, 2),
            speed: 20,
            resists: const {DamageType.fire},
            vulnerableTo: const {DamageType.frost},
          ),
        ],
        knownSpells: const {'firebolt'},
        mana: 10,
      );
      final bloc = await _pushGame(tester, game);
      final gameBefore = bloc.state.game;
      final logBefore = bloc.state.log;

      // act
      await tester.tap(find.byKey(const Key('timeline-actor-ghoul-1-1')));
      await tester.pumpAndSettle();

      // assert - the sheet and selection are view-only: no swing, no claws
      expect(bloc.state.selectedActorId, 'ghoul-1');
      expect(bloc.state.cameraFocus, const Position(1, 2));
      expect(bloc.state.game, same(gameBefore));
      expect(bloc.state.log, same(logBefore));
      expect(find.text('strikes adjacent'), findsOneWidget);
      expect(find.text('3–3'), findsOneWidget);
      expect(find.text('Resists fire'), findsOneWidget);
      expect(find.text('Burns at frost'), findsOneWidget);
      expect(find.textContaining('You hit the ghoul'), findsNothing);
      expect(bloc.state.game.monsters.single.hp, 10);
      expect(bloc.state.game.hero.hp, 20);
      expect(bloc.state.armedSpellId, isNull);
    });

    testWidgets('armed Attack and a marked map tap is the bump', (
      tester,
    ) async {
      // arrange
      final game = battleGame(
        monsters: [ghoulAt(const Position(1, 2))],
        knownSpells: const {'firebolt'},
        mana: 10,
      );
      final bloc = await _pushGame(tester, game);

      // act - tap the monster's tile on the map
      await _tapTile(tester, const Position(1, 2));
      await tester.pumpAndSettle();

      // assert - the bump fired through the map tap
      expect(find.text('You hit the ghoul for 4.'), findsOneWidget);
      expect(bloc.state.armedSpellId, isNull);
    });

    testWidgets('arming one spell puts down the other', (tester) async {
      // arrange
      final game = battleGame(
        monsters: [ghoulAt(const Position(1, 2))],
        knownSpells: const {'firebolt', 'bind'},
        mana: 10,
      );
      final bloc = await _pushGame(tester, game);

      // act
      await tester.tap(find.text('✳ Firebolt 2'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('⛒ Bind 3'));
      await tester.pumpAndSettle();

      // assert - one armed slot at a time
      expect(bloc.state.armedSpellId, 'bind');
      expect(find.text('⛒ Bind 3'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('⛒ Bind 3')),
          matching: find.text('— armed'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('✳ Firebolt 2')),
          matching: find.text('— armed'),
        ),
        findsNothing,
      );
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
        logSentences(bloc.state).where((line) => line.startsWith('You mend')),
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
      await _tapTile(tester, const Position(1, 2));
      await tester.pumpAndSettle();

      // assert
      expect(find.text('not enough mana'), findsNothing);
      expect(
        logSentences(bloc.state)
            .where((line) => line.startsWith('Not enough mana')),
        isNotEmpty,
      );
    });
  });

  group('the combat shelf', () {
    testWidgets('the shelf lists the readied three and the overflow', (
      tester,
    ) async {
      // arrange - six known spells: three readied, three behind +3
      final game = battleGame(
        monsters: [ghoulAt(const Position(1, 2))],
        knownSpells: const {
          'firebolt',
          'frost-lance',
          'mend',
          'ward',
          'bind',
          'banish',
        },
        mana: 10,
      );
      await _pushGame(tester, game);

      // assert - the shelf shows the readied three and counts the overflow
      expect(find.text('✳ Firebolt 2'), findsOneWidget);
      expect(find.text('✳ Frost Lance 4'), findsOneWidget);
      expect(find.text('✚ Mend 3'), findsOneWidget);
      expect(find.text('+3'), findsOneWidget);
      expect(find.text('⛒ Bind 3'), findsNothing);
    });

    testWidgets('the overflow sheet lists every known spell', (tester) async {
      // arrange - a phone surface, where the shelf is tapped; four known
      // spells, three readied and one behind +1
      tester.view.physicalSize = _phone;
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final game = battleGame(
        monsters: [ghoulAt(const Position(1, 2))],
        knownSpells: const {'firebolt', 'mend', 'ward', 'bind'},
        mana: 10,
      );
      await _pushGame(tester, game);
      await tester.pumpAndSettle();

      // act
      await tester.tap(find.byKey(const ValueKey('+1')));
      await tester.pumpAndSettle();

      // assert - every spell is reachable from the sheet, cost-free
      expect(find.text('Firebolt'), findsOneWidget);
      expect(find.text('Mend'), findsOneWidget);
      expect(find.text('Ward'), findsOneWidget);
      expect(find.text('Bind'), findsOneWidget);
    });

    testWidgets('the overflow arms a spell not on the shelf', (tester) async {
      // arrange - a phone surface; four known spells, Bind behind +1
      tester.view.physicalSize = _phone;
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final game = battleGame(
        monsters: [ghoulAt(const Position(1, 2))],
        knownSpells: const {'firebolt', 'mend', 'ward', 'bind'},
        mana: 10,
      );
      final bloc = await _pushGame(tester, game);
      await tester.pumpAndSettle();

      // act
      await tester.tap(find.byKey(const ValueKey('+1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('overflow-bind')));
      await tester.pumpAndSettle();

      // assert - the sheet closed and the spell armed
      expect(bloc.state.armedSpellId, 'bind');
    });

    testWidgets('a self-cast spell casts straight from the shelf', (
      tester,
    ) async {
      // arrange
      final game = battleGame(
        monsters: [ghoulAt(const Position(1, 2))],
        knownSpells: const {'mend'},
        mana: 10,
      );
      final bloc = await _pushGame(tester, game);

      // act
      await tester.tap(find.text('✚ Mend 3'));
      await tester.pumpAndSettle();

      // assert - cast immediately, no arming
      expect(bloc.state.mana, 7);
      expect(bloc.state.armedSpellId, isNull);
    });
  });

  group('map inspect and recenter', () {
    testWidgets('a tap on a distant monster opens the enemy info', (
      tester,
    ) async {
      // arrange - the spitter three tiles out, nothing armed
      final game = battleGame(monsters: [spitterAt(const Position(4, 1))]);
      final bloc = await _pushGame(tester, game);
      final logBefore = bloc.state.log.length;

      // act
      await _tapTile(tester, const Position(4, 1));
      await tester.pumpAndSettle();

      expect(find.text('strikes at range 3'), findsOneWidget);
      expect(bloc.state.log.length, logBefore);
      expect(bloc.state.game.hero.position, const Position(1, 1));
    });

    testWidgets('a long-press on a monster opens the enemy info', (
      tester,
    ) async {
      // arrange - the spitter three tiles out
      final game = battleGame(monsters: [spitterAt(const Position(4, 1))]);
      final bloc = await _pushGame(tester, game);
      final logBefore = bloc.state.log.length;

      // act - long-press the monster's tile on the map
      final scene = find.byKey(dungeonSceneKey);
      final size = tester.getSize(scene);
      final geometry = GridGeometry.camera(size, 7, 5, const Position(1, 1));
      final local =
          geometry.topLeftOf(4, 1) +
          Offset(geometry.cellSize / 2, geometry.cellSize / 2);
      await tester.longPressAt(tester.getTopLeft(scene) + local);
      await tester.pumpAndSettle();

      expect(find.text('strikes at range 3'), findsOneWidget);
      expect(bloc.state.log.length, logBefore);
    });

    testWidgets('the recenter affordance resets the pan', (tester) async {
      // arrange - a floor wider than the default test surface, panned so the
      // hero has been dragged off the right edge of the glass
      const wideArena = '''
##############################
#............................#
##############################''';
      final map = FloorMap.parse(wideArena);
      final seen = computeFov(map, const Position(1, 1), fovRadius);
      final game = GameState(
        map: map,
        hero: Actor(
          id: 'hero',
          name: 'you',
          glyph: '@',
          position: const Position(1, 1),
          hp: 20,
          maxHp: 20,
          attackMin: 4,
          attackMax: 4,
          speed: 10,
          energy: actThreshold,
        ),
        monsters: const [],
        rng: Rng(1),
        lootRng: Rng(2),
        visible: seen,
        explored: {...seen},
        buildFloor: (depth) => throw StateError('no floor below'),
        spells: spellsById,
      );
      final bloc = await _pushGame(tester, game);
      bloc.add(const MapPanned(Offset(-2000, 0)));
      await tester.pumpAndSettle();
      // act + assert - the affordance appears and resets the pan
      expect(find.byKey(recenterKey), findsOneWidget);
      await tester.tap(find.byKey(recenterKey));
      await tester.pumpAndSettle();
      expect(bloc.state.pan, Offset.zero);
      expect(find.byKey(recenterKey), findsNothing);
    });
    testWidgets(
      'a distant selected actor makes recenter return focus to the hero',
      (tester) async {
        const wideArena = '''
########################################
#......................................#
########################################''';
        final map = FloorMap.parse(wideArena);
        const heroPosition = Position(1, 1);
        const actorPosition = Position(18, 1);
        final monster = ghoulAt(actorPosition);
        final seen = {heroPosition, actorPosition};
        final game = GameState(
          map: map,
          hero: Actor(
            id: 'hero',
            name: 'you',
            glyph: '@',
            position: heroPosition,
            hp: 20,
            maxHp: 20,
            attackMin: 4,
            attackMax: 4,
            speed: 10,
            energy: actThreshold,
          ),
          monsters: [monster],
          rng: Rng(1),
          lootRng: Rng(2),
          visible: seen,
          explored: seen,
          buildFloor: (depth) => throw StateError('no floor below'),
          spells: spellsById,
        );
        final bloc = await _pushGame(tester, game);
        final gameBefore = bloc.state.game;
        final logBefore = bloc.state.log;
        bloc.add(const TimelineActorSelected('ghoul-1'));
        await tester.pumpAndSettle();

        expect(bloc.state.selectedActorId, 'ghoul-1');
        expect(bloc.state.cameraFocus, actorPosition);
        expect(find.byKey(recenterKey), findsOneWidget);

        await tester.tap(find.byKey(recenterKey));
        await tester.pumpAndSettle();

        expect(bloc.state.selectedActorId, isNull);
        expect(bloc.state.cameraFocus, heroPosition);
        expect(bloc.state.game, same(gameBefore));
        expect(bloc.state.log, same(logBefore));
        expect(find.byKey(recenterKey), findsNothing);
      },
    );
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
