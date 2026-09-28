import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/action_bar.dart';
import 'package:residuum_app/game/crawl_style.dart';
import 'package:residuum_app/game/dungeon_palette.dart';
import 'package:residuum_app/game/dungeon_scene.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/game_screen.dart';
import 'package:residuum_app/game/grid_geometry.dart';
import 'package:residuum_app/game/target_card.dart';
import 'package:residuum_app/game/turn_order_strip.dart';
import 'package:residuum_app/style/tokens.dart';
import 'package:residuum_app/town/town_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import 'support/phone.dart';

const _arena = '''
#######
#.....#
#.....#
#.....#
#######''';

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

Future<void> _tapTile(WidgetTester tester, Position tile) async {
  final scene = find.byKey(dungeonSceneKey);
  final size = tester.getSize(scene);
  final geometry = GridGeometry.camera(size, 7, 5, const Position(1, 1));
  final local = geometry.centreOf(tile);
  await tester.tapAt(tester.getTopLeft(scene) + local);
}

void main() {
  group('the strip', () {
    testWidgets('the map stays on screen while the strip is up', (
      tester,
    ) async {
      final game = battleGame(monsters: [spitterAt(const Position(4, 1))]);

      await _pushGame(tester, game);

      expect(find.byType(DungeonSceneHost), findsOneWidget);
      expect(find.byType(TurnOrderStrip), findsOneWidget);
    });

    testWidgets(
      'a floor tile one step toward the spitter moves the hero while the '
      'strip is up',
      (tester) async {
        final game = battleGame(monsters: [spitterAt(const Position(4, 1))]);
        final bloc = await _pushGame(tester, game);

        await _tapTile(tester, const Position(2, 1));
        await tester.pumpAndSettle();

        expect(bloc.state.game.hero.position, const Position(2, 1));
        expect(find.byType(DungeonSceneHost), findsOneWidget);
        expect(find.byType(TurnOrderStrip), findsOneWidget);
      },
    );

    testWidgets('the strip disappears when the last reach-holder dies', (
      tester,
    ) async {
      final game = battleGame(monsters: [ghoulAt(const Position(1, 2))]);
      final bloc = await _pushGame(tester, game);

      for (var swing = 0; swing < 3; swing++) {
        bloc.add(TileTapped(bloc.state.game.monsters.single.position));
        await tester.pumpAndSettle();
      }

      expect(bloc.state.game.monsters, isEmpty);
      expect(find.byType(TurnOrderStrip), findsNothing);
      expect(find.byType(DungeonSceneHost), findsOneWidget);
    });

    testWidgets('the Flame scene survives the turn-order strip closing', (
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

      expect(find.byType(TurnOrderStrip), findsNothing);
      expect(
        tester.widget<GameWidget<FlameGame>>(find.byKey(dungeonSceneKey)).game,
        same(before),
      );
    });

    testWidgets('the screen fits a phone with the strip up and with it down', (
      tester,
    ) async {
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

      expect(tester.takeException(), isNull);
      expect(find.byType(TurnOrderStrip), findsOneWidget);
      expect(find.textContaining('Engaged'), findsOneWidget);
      await _tapTile(tester, const Position(1, 2));
      await tester.pumpAndSettle();
      expect(find.text('You hit the ghoul for 4.'), findsOneWidget);

      for (var swing = 0; swing < 2; swing++) {
        bloc.add(TileTapped(bloc.state.game.monsters.single.position));
        await tester.pumpAndSettle();
      }

      expect(bloc.state.game.monsters, isEmpty);
      expect(find.byType(TurnOrderStrip), findsNothing);
      expect(find.text('Wait'), findsNothing);
      expect(find.byType(DungeonSceneHost), findsOneWidget);
      expect(find.byKey(actionBarKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the strip reads at elevated text scale without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = _phone;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      final game = battleGame(monsters: [ghoulAt(const Position(1, 2))]);

      await _pushGame(tester, game, textScaler: const TextScaler.linear(2.0));

      expect(tester.takeException(), isNull);
      expect(find.byType(TurnOrderStrip), findsOneWidget);
    });
  });

  group('the turn order tokens', () {
    testWidgets('shows literal repeated occurrences and the closing hero', (
      tester,
    ) async {
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

      await _pushGame(tester, game);

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
      final semanticsHandle = tester.ensureSemantics();
      try {
        final currentSemantics = tester.getSemantics(
          find.byKey(const Key('timeline-current-hero')),
        );
        expect(currentSemantics.label, 'You, current activation');
        final firstActorSemantics = tester.getSemantics(
          find.byKey(const Key('timeline-actor-ghoul-1-1')),
        );
        expect(firstActorSemantics.label, 'the ghoul¹');
        expect(firstActorSemantics.flagsCollection.isButton, isTrue);
        final secondActorSemantics = tester.getSemantics(
          find.byKey(const Key('timeline-actor-ghoul-2-3')),
        );
        expect(secondActorSemantics.label, 'the ghoul²');
        expect(secondActorSemantics.flagsCollection.isButton, isTrue);
        expect(
          tester
              .getSemantics(find.byKey(const Key('timeline-next-hero')))
              .label,
          'You, next activation',
        );
      } finally {
        semanticsHandle.dispose();
      }
      expect(find.textContaining('IN '), findsNothing);
      final digit = RegExp('[0-9]');
      for (final text in tester.widgetList<Text>(
        find.descendant(
          of: find.byType(TurnOrderStrip),
          matching: find.byType(Text),
        ),
      )) {
        expect(digit.hasMatch(text.data ?? ''), isFalse, reason: text.data);
      }
    });

    testWidgets(
      "the current pill is 24 dp on the strip's own full-height hit row, "
      'gold-bordered and filled, unlike a future pill',
      (tester) async {
        await _pushGame(
          tester,
          battleGame(monsters: [ghoulAt(const Position(1, 2))]),
        );

        Container pillOf(Key key) => tester.widget<Container>(
          find
              .descendant(of: find.byKey(key), matching: find.byType(Container))
              .first,
        );

        final currentPill = pillOf(const Key('timeline-current-hero'));
        final nextPill = pillOf(const Key('timeline-actor-ghoul-1-1'));
        final currentDecoration = currentPill.decoration as BoxDecoration;
        final nextDecoration = nextPill.decoration as BoxDecoration;

        expect(
          tester.getSize(find.byKey(const Key('timeline-current-hero'))).height,
          crawlTokenHeight,
        );
        expect(
          tester
              .getSize(find.byKey(const Key('timeline-actor-ghoul-1-1')))
              .height,
          crawlTokenHeight,
        );
        final currentHitRow = find
            .ancestor(
              of: find.byKey(const Key('timeline-current-hero')),
              matching: find.byType(SizedBox),
            )
            .first;
        expect(tester.getSize(currentHitRow).height, crawlStripHeight);

        expect(currentDecoration.border!.top.width, 1.5);
        expect(currentDecoration.border!.top.color, crawlGold);
        expect(currentDecoration.color, isNotNull);
        expect(nextDecoration.border!.top.width, 1);
        expect(nextDecoration.border!.top.color, crawlChipBorder);
        expect(nextDecoration.color, isNull);
      },
    );

    testWidgets(
      "the pill sits centred in the strip's own hit row, not pinned to "
      'the top',
      (tester) async {
        await _pushGame(
          tester,
          battleGame(monsters: [ghoulAt(const Position(1, 2))]),
        );

        final hitRowTop = tester
            .getTopLeft(
              find
                  .ancestor(
                    of: find.byKey(const Key('timeline-current-hero')),
                    matching: find.byType(SizedBox),
                  )
                  .first,
            )
            .dy;
        final pillTop = tester
            .getTopLeft(find.byKey(const Key('timeline-current-hero')))
            .dy;

        expect(
          pillTop - hitRowTop,
          closeTo((crawlStripHeight - crawlTokenHeight) / 2, 0.5),
        );
      },
    );

    testWidgets(
      'a duplicate survivor keeps its suffix in the strip after a sibling '
      'dies',
      (tester) async {
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
            of: find.byType(TurnOrderStrip),
            matching: find.text('g²'),
          ),
          findsOneWidget,
        );

        bloc.add(const TileTapped(Position(1, 2)));
        await tester.pumpAndSettle();

        expect(bloc.state.game.monsters.map((actor) => actor.id), ['ghoul-2']);
        expect(bloc.state.presentationOf('ghoul-2')?.glyphLabel, 'g²');
        expect(
          find.descendant(
            of: find.byType(TurnOrderStrip),
            matching: find.text('g²'),
          ),
          findsOneWidget,
        );
        await tester.tap(
          find.ancestor(
            of: find.descendant(
              of: find.byType(TurnOrderStrip),
              matching: find.text('g²'),
            ),
            matching: find.byType(InkWell),
          ),
        );
        await tester.pumpAndSettle();
        expect(bloc.state.selectedActorId, 'ghoul-2');
        expect(find.byType(BottomSheet), findsNothing);
        expect(find.byKey(targetCardKey), findsOneWidget);
      },
    );

    testWidgets('truncates at a hidden due actor without a placeholder', (
      tester,
    ) async {
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

      await _pushGame(tester, game);

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

    testWidgets('the strip shows a +N cue rather than a scrollbar for a truly '
        'overflowing legal queue on a phone', (tester) async {
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

      final bloc = await _pushGame(
        tester,
        game,
        textScaler: const TextScaler.linear(2),
      );

      expect(
        find.descendant(
          of: find.byType(TurnOrderStrip),
          matching: find.byType(Scrollable),
        ),
        findsNothing,
      );
      expect(find.byKey(turnOrderMoreKey), findsOneWidget);
      final cueText = tester.widget<Text>(
        find
            .descendant(
              of: find.byKey(turnOrderMoreKey),
              matching: find.byType(Text),
            )
            .first,
      );
      expect(cueText.data, startsWith('+'));
      final cueSemantics = tester.widget<Semantics>(
        find
            .ancestor(
              of: find.byKey(turnOrderMoreKey),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(cueSemantics.properties.label, endsWith('more in the turn order'));

      final visiblePill = find.byKey(const Key('timeline-actor-ghoul-1-1'));
      expect(visiblePill, findsOneWidget);
      await tester.tap(visiblePill);
      await tester.pumpAndSettle();

      expect(bloc.state.selectedActorId, 'ghoul-1');
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byKey(targetCardKey), findsOneWidget);
      expect(find.byType(DungeonSceneHost), findsOneWidget);
      expect(find.text('Wait'), findsOneWidget);
      expect(find.textContaining('Engaged'), findsOneWidget);
      expect(find.byKey(actionBarKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('the strip at the target phone', () {
    String tallArena(int rows) => List.generate(
      rows,
      (row) => row == 0 || row == rows - 1 ? '#######' : '#.....#',
    ).join('\n');

    Actor tallGhoul(String id, Position at) => Actor(
      id: id,
      name: 'the ghoul',
      glyph: 'g',
      position: at,
      hp: 10,
      maxHp: 10,
      attackMin: 3,
      attackMax: 3,
      speed: 10,
      energy: actThreshold,
    );

    testWidgets(
      '1 actor holding reach but not yet due keeps NOW and NEXT both "@ '
      'You", with no cue',
      (tester) async {
        await onTheTargetPhone(tester);
        final quiet = Actor(
          id: 'ghoul-1',
          name: 'the ghoul',
          glyph: 'g',
          position: const Position(1, 2),
          hp: 10,
          maxHp: 10,
          attackMin: 3,
          attackMax: 3,
          speed: 1,
          energy: 0,
        );
        final bloc = await _pushGame(tester, battleGame(monsters: [quiet]));

        expect(bloc.state.isBattleOpen, isTrue);
        expect(bloc.state.activationQueue, hasLength(2));
        expect(find.byKey(const Key('timeline-current-hero')), findsOneWidget);
        expect(find.byKey(const Key('timeline-next-hero')), findsOneWidget);
        expect(find.byKey(turnOrderMoreKey), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'with a dire wolf, two giant rats and a ghoul all holding reach, '
      'every shown pill sits fully inside the strip, the cue counts the '
      'rest, and a shown pill still selects its actor on the card',
      (tester) async {
        await onTheTargetPhone(tester);
        const heroAt = Position(2, 2);
        final direWolf = Actor(
          id: 'dire-wolf',
          name: 'the dire wolf',
          glyph: 'w',
          position: const Position(1, 2),
          hp: 14,
          maxHp: 14,
          attackMin: 4,
          attackMax: 6,
          speed: 10,
          energy: actThreshold,
        );
        final rat1 = Actor(
          id: 'rat-1',
          name: 'a giant rat',
          glyph: 'r',
          position: const Position(3, 2),
          hp: 6,
          maxHp: 6,
          attackMin: 1,
          attackMax: 2,
          speed: 10,
          energy: actThreshold,
        );
        final rat2 = Actor(
          id: 'rat-2',
          name: 'a giant rat',
          glyph: 'r',
          position: const Position(2, 1),
          hp: 6,
          maxHp: 6,
          attackMin: 1,
          attackMax: 2,
          speed: 10,
          energy: actThreshold,
        );
        final ghoul = ghoulAt(const Position(2, 3));
        final game = battleGame(
          heroAt: heroAt,
          monsters: [direWolf, rat1, rat2, ghoul],
          visible: {
            heroAt,
            const Position(1, 2),
            const Position(3, 2),
            const Position(2, 1),
            const Position(2, 3),
          },
        );

        final bloc = await _pushGame(tester, game);

        expect(tester.takeException(), isNull);
        expect(find.byKey(turnOrderMoreKey), findsOneWidget);

        final strip = tester.getRect(find.byType(TurnOrderStrip));
        const candidateKeys = [
          Key('timeline-current-hero'),
          Key('timeline-actor-dire-wolf-1'),
          Key('timeline-actor-rat-1-2'),
          Key('timeline-actor-rat-2-3'),
          Key('timeline-actor-ghoul-1-4'),
        ];
        var shown = 0;
        for (final key in candidateKeys) {
          final finder = find.byKey(key);
          if (!tester.any(finder)) continue;
          shown++;
          final pillRect = tester.getRect(finder);
          expect(strip.left, lessThanOrEqualTo(pillRect.left + 0.5));
          expect(strip.top, lessThanOrEqualTo(pillRect.top + 0.5));
          expect(strip.right, greaterThanOrEqualTo(pillRect.right - 0.5));
          expect(strip.bottom, greaterThanOrEqualTo(pillRect.bottom - 0.5));
        }
        expect(shown, greaterThanOrEqualTo(1));
        expect(shown, lessThan(candidateKeys.length));

        await tester.tap(find.byKey(const Key('timeline-actor-dire-wolf-1')));
        await tester.pumpAndSettle();

        expect(bloc.state.selectedActorId, 'dire-wolf');
        final card = find.byKey(targetCardKey);
        expect(card, findsOneWidget);
        expect(
          find.descendant(of: card, matching: find.text('The dire wolf')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'the strip sits at the top while the hero stays centred, and flips '
      'to the bottom, inset from the recenter pill, once a distant '
      'selection puts the hero under the top edge',
      (tester) async {
        await onTheTargetPhone(tester);
        const rows = 61;
        const heroAt = Position(2, 30);
        const adjacentAt = Position(3, 30);
        final map = FloorMap.parse(tallArena(rows));

        GameState gameSelecting(int selectedRow) {
          final selectedAt = Position(2, selectedRow);
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
              tallGhoul('ghoul-1', adjacentAt),
              tallGhoul('ghoul-2', selectedAt),
            ],
            rng: Rng(1),
            lootRng: Rng(2),
            visible: {heroAt, adjacentAt, selectedAt},
            explored: {heroAt, adjacentAt, selectedAt},
            buildFloor: (depth) => throw StateError('no floor below'),
          );
        }

        final probe = GameBloc(
          game: gameSelecting(heroAt.y + 1),
          stepDelay: Duration.zero,
        );
        addTearDown(probe.close);
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider.value(
              value: probe,
              child: const GameScreen(palette: DungeonPalette.crypt),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(probe.state.isBattleOpen, isTrue);
        final stripAtTop = tester.getRect(find.byType(TurnOrderStrip));
        final mapRectBefore = tester.getRect(find.byKey(dungeonSceneSlotKey));
        expect(stripAtTop.top, closeTo(mapRectBefore.top, 0.5));

        final mapSize = tester.getSize(find.byKey(dungeonSceneSlotKey));
        var focusRow = heroAt.y + 1;
        Rect heroRect;
        final topBand = Rect.fromLTWH(0, 0, mapSize.width, crawlStripHeight);
        do {
          focusRow++;
          final geometry = GridGeometry.camera(
            mapSize,
            5,
            rows,
            Position(2, focusRow),
          );
          heroRect = geometry.rectOf(heroAt);
        } while (!topBand.overlaps(heroRect) && focusRow < rows - 1);
        expect(
          topBand.overlaps(heroRect),
          isTrue,
          reason:
              'could not find a focus row that puts the hero under the '
              'strip on this surface',
        );

        final bloc = GameBloc(
          game: gameSelecting(focusRow),
          stepDelay: Duration.zero,
        );
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
        bloc.add(const TimelineActorSelected('ghoul-2'));
        await tester.pumpAndSettle();

        final mapRectAfter = tester.getRect(find.byKey(dungeonSceneSlotKey));
        final stripFlipped = tester.getRect(find.byType(TurnOrderStrip));
        expect(stripFlipped.bottom, closeTo(mapRectAfter.bottom - 55.0, 0.5));
        expect(stripFlipped.top, greaterThan(mapRectAfter.top));
        expect(mapRectAfter.right - stripFlipped.right, closeTo(64, 0.5));
      },
    );
  });
}
