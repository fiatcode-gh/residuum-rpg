import 'dart:ui' as ui;

import 'package:flame/game.dart' hide Route;
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/crawl_status.dart';
import 'package:residuum_app/game/glyph_marks.dart';
import 'package:residuum_app/game/glyph_plan.dart';
import 'package:residuum_app/game/dungeon_palette.dart';
import 'package:residuum_app/game/dungeon_atmosphere.dart';
import 'package:residuum_app/game/dungeon_scene.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/game_screen.dart';
import 'package:residuum_app/game/grid_geometry.dart';
import 'package:residuum_app/game/log_line.dart';
import 'package:residuum_app/style/surfaces.dart';
import 'package:residuum_app/town/town_bloc.dart';
import 'package:residuum_app/world/world_bloc.dart';
import 'package:residuum_app/world/world_route_diagram.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../support/phone.dart';
import '../support/pumped_app.dart';
import '../support/standing.dart';
import '../support/world_nav.dart';

SaveDocument _oneHero(
  Profile profile, {
  Whereabouts? world,
  GameState? run,
  NodeId? dungeon,
  bool inside = false,
  int campDay = 0,
}) => SaveDocument.one(
  id: 'hero-1',
  label: 'Hero 1',
  profile: profile,
  world: world,
  run: run,
  dungeon: run == null ? null : (dungeon ?? cryptNode),
  campDay: run == null || inside ? null : campDay,
  inside: inside,
);

/// A hero standing at the crypt on [day], which is what a camp's age is
/// measured against.
Whereabouts _atTheCryptOn(int day) {
  final walked = newWhereabouts().arrivingAt(residuumWorld, cryptNode);
  return Whereabouts(
    at: walked.at,
    home: walked.home,
    discovered: walked.discovered,
    day: day,
  );
}

/// A hero who has heard of everywhere, standing at home.
Whereabouts _knowingAll() => newWhereabouts()
    .hearingOf(northgate)
    .hearingOf(seaCave)
    .hearingOf(ruinedKeep);

Profile _fullyTrainedProfile() => newProfile(worldSeed: 909).copyWith(
  skills: {
    ...untrainedSkills,
    for (final skill in SkillId.values) skill: const SkillState(level: 8),
  },
);

/// A hero standing at the sea-cave, having heard of it and walked there.
Whereabouts _atTheSeaCave() => _knowingAll()
    .arrivingAt(residuumWorld, northgate)
    .arrivingAt(residuumWorld, seaCave);

/// A hero standing at the ruined keep.
Whereabouts _atTheKeep() => _knowingAll()
    .arrivingAt(residuumWorld, northgate)
    .arrivingAt(residuumWorld, ruinedKeep);

Whereabouts _atNorthgate() =>
    _knowingAll().arrivingAt(residuumWorld, northgate);

/// The bloc driving whatever crawl or fight is on screen.
GameBloc _fightOnScreen(WidgetTester tester) =>
    BlocProvider.of<GameBloc>(tester.element(find.byType(GameScreen)));

typedef _TerrainGlyph = ({
  Position position,
  String glyph,
  Color ink,
  double opacity,
});

Map<Position, _TerrainGlyph> _liveTerrainGlyphs(WidgetTester tester) {
  final game = tester
      .widget<GameWidget<FlameGame>>(find.byKey(dungeonSceneKey))
      .game!;
  final terrain = game.world.children.whereType<PositionComponent>().where(
    (component) => component.priority == GlyphLayer.terrain.index,
  );
  return Map.fromEntries(
    terrain.map((component) {
      final text = component.children.whereType<TextComponent>().single;
      final colour = (text.textRenderer as TextPaint).style.color!;
      final position = Position(
        (component.position.x / mapCellWidth).round(),
        (component.position.y / mapCellHeight).round(),
      );
      return MapEntry(position, (
        position: position,
        glyph: text.text,
        ink: colour.withValues(alpha: 1),
        opacity: colour.a,
      ));
    }),
  );
}

Map<Position, _TerrainGlyph> _plannedTerrainGlyphs(GameViewState state) => {
  for (final cell in glyphPlan(state.game))
    if (cell.layer == GlyphLayer.terrain)
      cell.position: (
        position: cell.position,
        glyph: cell.glyph,
        ink: glyphInk(cell, state.game.hero.position).withValues(alpha: 1),
        opacity: glyphInk(cell, state.game.hero.position).a,
      ),
};

/// Road-fight terrain ink is the same warm stone everywhere now (PLAN.md
/// G3); the regional difference moved to fog (Task 04). This only proves the
/// live scene renders exactly the planned glyph projection.
Future<
  ({Map<Position, _TerrainGlyph> actual, Map<Position, _TerrainGlyph> expected})
>
_navigationTerrainGlyphs(WidgetTester tester) async {
  final state = _fightOnScreen(tester).state;
  return (
    actual: _liveTerrainGlyphs(tester),
    expected: _plannedTerrainGlyphs(state),
  );
}

/// A road fight already in progress, pushed over a world exactly as the session
/// pushes one.
///
/// Built by hand rather than reached by travelling, because what is under test
/// is the wiring at the ends of a fight and not the road that produced it.
/// Walking to an edge through live monsters would make the test's outcome
/// depend on how the fight went.
Future<(TownBloc, WorldBloc)> _pushRoadFight(
  WidgetTester tester, {
  required Profile profile,
  Whereabouts? world,
  Route? road,
  bool dead = false,
  Position? heroAt,
}) async {
  final route = road ?? residuumWorld.routeBetween(stonebridge, cryptNode)!;
  final fight = startRoadEncounter(profile, day: 4, road: route);
  final placed = heroAt == null
      ? fight
      : fight.copyWith(hero: fight.hero.copyWith(position: heroAt));
  final town = TownBloc(profile: profile);
  final worldBloc = WorldBloc(
    world: world ?? _knowingAll(),
    worldSeed: profile.worldSeed,
    dayDelay: Duration.zero,
  );
  final game = GameBloc(
    game: dead
        ? placed.copyWith(hero: placed.hero.copyWith(hp: 0), isGameOver: true)
        : placed,
    stepDelay: Duration.zero,
  );
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => MultiBlocProvider(
                providers: [
                  BlocProvider.value(value: town),
                  BlocProvider.value(value: worldBloc),
                  BlocProvider.value(value: game),
                ],
                child: GameScreen(palette: paletteForRoad(route)),
              ),
            ),
          ),
          child: const Text('out there'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('out there'));
  await tester.pumpAndSettle();
  return (town, worldBloc);
}

Future<void> _walkToRegionalFight(WidgetTester tester, String place) async {
  final control = find.ancestor(
    of: find.text(place),
    matching: find.byType(GestureDetector),
  );
  await tester.ensureVisible(control);
  await tester.pumpAndSettle();
  await tester.tap(control);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Set out'));
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
  expect(find.byType(GameScreen), findsOneWidget);
}

void main() {
  group('the world screen', () {
    testWidgets('boot lands on it, at the hero own node', (tester) async {
      // arrange
      final app = PumpedApp(_oneHero(newProfile(worldSeed: 909)));

      // act
      await app.pump(tester);

      // assert
      expect(find.text('RESIDUUM'), findsOneWidget);
      expect(find.text('At Stonebridge'), findsOneWidget);
      expect(find.text('Day 0.'), findsOneWidget);
    });

    testWidgets('fresh discovery keeps unknown places and roads redacted', (
      tester,
    ) async {
      // arrange
      final semantics = tester.ensureSemantics();
      try {
        final profile = newProfile(worldSeed: 909);
        final app = PumpedApp(_oneHero(profile));

        // act
        await app.pump(tester);

        // assert
        expect(find.text('Stonebridge'), findsOneWidget);
        expect(find.text('The Crypt'), findsOneWidget);
        for (final hidden in ['Northgate', 'The Sea-Cave', 'The Ruined Keep']) {
          expect(find.text(hidden), findsNothing);
          expect(
            find.bySemanticsLabel(RegExp(RegExp.escape(hidden))),
            findsNothing,
          );
        }
        expect(find.text('?'), findsNWidgets(3));
        expect(
          find.bySemanticsLabel('Unknown location. Not discovered.'),
          findsNWidgets(3),
        );
        final route = residuumWorld.routeBetween(stonebridge, cryptNode)!;
        final danger = dangerOn(route, profile);
        expect(
          find.bySemanticsLabel(
            'Route from Stonebridge to The Crypt. '
            '1 day(s). Current danger $danger in 100.',
          ),
          findsOneWidget,
        );
        expect(find.text('1 DAY'), findsOneWidget);
        expect(find.text('DANGER $danger/100'), findsOneWidget);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets(
      'rejects an unapproved route pair before discovery projection',
      (tester) async {
        // arrange
        final invalidMap = WorldMap(
          nodes: residuumWorld.nodes,
          routes: [
            ...residuumWorld.routes.where(
              (route) => !route.joins(northgate, seaCave),
            ),
            Route(from: seaCave, to: cryptNode, days: 2),
          ],
        );

        // act
        await tester.pumpWidget(
          MaterialApp(
            home: WorldRouteDiagram(
              map: invalidMap,
              whereabouts: newWhereabouts(),
              destinations: const {},
              dangerFor: (_) => 0,
              onDestination: (_) {},
            ),
          ),
        );
        final exception = tester.takeException();

        // assert
        expect(exception, isA<StateError>());
      },
    );

    testWidgets('fully discovered routes show current danger and controls', (
      tester,
    ) async {
      // arrange
      final semantics = tester.ensureSemantics();
      try {
        final profile = _fullyTrainedProfile();
        final app = PumpedApp(_oneHero(profile, world: _knowingAll()));

        // act
        await app.pump(tester);

        // assert
        for (final node in residuumWorld.nodes) {
          expect(find.text(node.name), findsOneWidget);
        }
        expect(find.text('TOWN'), findsNWidgets(2));
        expect(find.text('DUNGEON'), findsNWidgets(3));
        expect(find.text('1 DAY'), findsNWidgets(2));
        expect(find.text('2 DAYS'), findsNWidgets(3));
        for (final route in residuumWorld.routes) {
          final from = residuumWorld.nodeAt(route.from).name;
          final to = residuumWorld.nodeAt(route.to).name;
          final danger = dangerOn(route, profile);
          expect(
            find.bySemanticsLabel(
              'Route from $from to $to. '
              '${route.days} day(s). Current danger $danger in 100.',
            ),
            findsOneWidget,
          );
          expect(find.text('DANGER $danger/100'), findsWidgets);
        }
        expect(
          tester
              .getSemantics(
                find.bySemanticsLabel(
                  RegExp(
                    r'DUNGEON The Crypt\. REACHABLE',
                    caseSensitive: false,
                  ),
                ),
              )
              .flagsCollection
              .isEnabled,
          ui.Tristate.isTrue,
        );
        expect(
          tester
              .getSemantics(
                find.bySemanticsLabel(
                  RegExp(r'TOWN Northgate\. REACHABLE', caseSensitive: false),
                ),
              )
              .flagsCollection
              .isEnabled,
          ui.Tristate.isTrue,
        );
        for (final hiddenByRoad in ['The Sea-Cave', 'The Ruined Keep']) {
          expect(
            tester
                .getSemantics(
                  find.bySemanticsLabel(
                    RegExp(
                      '${RegExp.escape(hiddenByRoad)}.*NO ROAD FROM HERE',
                      caseSensitive: false,
                    ),
                  ),
                )
                .flagsCollection
                .isEnabled,
            ui.Tristate.isFalse,
          );
        }
      } finally {
        semantics.dispose();
      }
    });

    testWidgets(
      'a reachable node exposes a tap action; blocked and unknown nodes do '
      'not',
      (tester) async {
        // arrange — fully discovered gives one reachable node and one known
        // node with no direct road; a fresh world still hides three slots.
        final semantics = tester.ensureSemantics();
        try {
          final profile = _fullyTrainedProfile();
          final discovered = PumpedApp(_oneHero(profile, world: _knowingAll()));
          await discovered.pump(tester);
          final cryptLabel = RegExp(
            r'DUNGEON The Crypt\. REACHABLE',
            caseSensitive: false,
          );
          final reachable = find.bySemanticsLabel(cryptLabel);
          final blocked = find.bySemanticsLabel(
            RegExp(
              '${RegExp.escape('The Sea-Cave')}.*NO ROAD FROM HERE',
              caseSensitive: false,
            ),
          );

          // act
          final reachableHasTap = tester
              .getSemantics(reachable)
              .getSemanticsData()
              .hasAction(SemanticsAction.tap);
          final blockedHasTap = tester
              .getSemantics(blocked)
              .getSemanticsData()
              .hasAction(SemanticsAction.tap);
          tester.semantics.tap(find.semantics.byLabel(cryptLabel));
          await tester.pumpAndSettle();

          // assert
          expect(reachable, findsOneWidget);
          expect(reachableHasTap, isTrue);
          expect(blockedHasTap, isFalse);
          expect(find.text('Set out'), findsOneWidget);
          expect(find.text('Stay here'), findsOneWidget);

          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
          final fresh = PumpedApp(_oneHero(newProfile(worldSeed: 909)));
          await fresh.pump(tester);
          final unknown = tester.getSemantics(
            find.bySemanticsLabel('Unknown location. Not discovered.').first,
          );
          expect(
            unknown.getSemanticsData().hasAction(SemanticsAction.tap),
            isFalse,
          );
        } finally {
          semantics.dispose();
        }
      },
    );

    testWidgets('rumor discovery fills the fixed Northgate slot', (
      tester,
    ) async {
      // arrange
      final semantics = tester.ensureSemantics();
      try {
        final app = PumpedApp(
          _oneHero(newProfile(worldSeed: 909).copyWith(gold: 100)),
        );
        await app.pump(tester);
        final before = tester.getCenter(
          find.byKey(const Key('world-node-northgate')),
        );
        expect(
          find.bySemanticsLabel('Unknown location. Not discovered.'),
          findsNWidgets(3),
        );

        // act
        await enterTown(tester, 'Stonebridge');
        await openTownDoor(tester, 'Tavern');
        await tester.tap(find.text('Ask $rumorPrice'));
        await tester.pumpAndSettle();
        await tester.pageBack();
        await tester.pumpAndSettle();
        await backToTheWorld(tester);

        // assert
        expect(
          tester.getCenter(find.byKey(const Key('world-node-northgate'))),
          before,
        );
        expect(find.text('Northgate'), findsOneWidget);
        expect(find.text('TOWN'), findsNWidgets(2));
        expect(
          find.bySemanticsLabel('Unknown location. Not discovered.'),
          findsNWidgets(2),
        );
        expect(find.text('1 DAY'), findsOneWidget);
        expect(find.text('2 DAYS'), findsNWidgets(2));
        expect(find.bySemanticsLabel(RegExp('The Sea-Cave')), findsNothing);
        expect(find.bySemanticsLabel(RegExp('The Ruined Keep')), findsNothing);
        expect(
          find.textContaining('Route from Northgate to The Sea-Cave'),
          findsNothing,
        );
        expect(
          find.textContaining('Route from Northgate to The Ruined Keep'),
          findsNothing,
        );
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('a journey marks its road and disables every node', (
      tester,
    ) async {
      // arrange
      final semantics = tester.ensureSemantics();
      try {
        final app = PumpedApp(
          _oneHero(
            newProfile(worldSeed: 909),
            world: Whereabouts(
              at: stonebridge,
              home: stonebridge,
              discovered: {stonebridge, northgate, cryptNode},
              day: 1,
              journey: Journey(from: stonebridge, to: northgate, daysLeft: 1),
            ),
          ),
        );

        // act
        await app.pump(tester);

        // assert
        expect(find.textContaining('On the road to Northgate'), findsOneWidget);
        expect(find.text('Day 1. one day still to walk.'), findsOneWidget);
        expect(find.text('Walk on'), findsOneWidget);
        expect(find.text('ON THIS ROAD'), findsOneWidget);
        expect(
          find.bySemanticsLabel(
            RegExp(r'You are on this road\. 1 day\(s\) remain\.'),
          ),
          findsOneWidget,
        );
        expect(find.text('HERE'), findsNothing);
        for (final name in ['Stonebridge', 'Northgate', 'The Crypt']) {
          expect(
            tester
                .getSemantics(
                  find.bySemanticsLabel(
                    RegExp(
                      '${RegExp.escape(name)}.*TRAVEL IN PROGRESS',
                      caseSensitive: false,
                    ),
                  ),
                )
                .flagsCollection
                .isEnabled,
            ui.Tristate.isFalse,
          );
        }
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('the Heroes door is here rather than in a town', (
      tester,
    ) async {
      // arrange
      final app = PumpedApp(_oneHero(newProfile(worldSeed: 909)));

      // act
      await app.pump(tester);
      await enterTown(tester, 'Stonebridge');

      // assert
      expect(find.text('Heroes'), findsNothing);
      await backToTheWorld(tester);
      expect(find.text('Heroes'), findsOneWidget);
    });

    testWidgets('switching hero from here lands cleanly on the world', (
      tester,
    ) async {
      // arrange
      final app = PumpedApp(
        SaveDocument(
          active: 'hero-1',
          heroes: {
            'hero-1': SavedHero(
              label: 'Ilse',
              profile: newProfile(worldSeed: 111),
            ),
            'hero-2': SavedHero(
              label: 'Bram',
              profile: newProfile(worldSeed: 222).copyWith(gold: 7),
              world: atNorthgate(),
            ),
          },
        ),
      );
      await app.pump(tester);

      // act
      await tester.tap(find.text('Heroes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bram'));
      await tester.pumpAndSettle();

      // assert
      expect(find.text('At Northgate'), findsOneWidget);
      expect(
        find.descendant(
          of: find.widgetWithText(LabelledValue, 'Carried'),
          matching: find.text('7 gold'),
        ),
        findsOneWidget,
      );
      expect(find.text('Enter Northgate'), findsOneWidget);
      expect(app.saved!.active, 'hero-2');
    });
  });

  group('walking the world', () {
    testWidgets('a day on the road is a day on the counter and a line in the '
        'log', (tester) async {
      // arrange
      final app = PumpedApp(_oneHero(newProfile(worldSeed: 909)));
      await app.pump(tester);

      // act
      await walkTo(tester, 'The Crypt');

      // assert
      expect(find.text('At The Crypt'), findsOneWidget);
      expect(find.text('Day 1.'), findsOneWidget);
      await scrollToTheLog(tester);
      expect(find.textContaining('The road is quiet.'), findsOneWidget);
    });

    testWidgets('the walk is confirmed before any day is spent', (
      tester,
    ) async {
      // arrange
      final app = PumpedApp(_oneHero(newProfile(worldSeed: 909)));
      await app.pump(tester);

      // act
      expect(
        find.bySemanticsLabel(
          RegExp(r'DUNGEON The Crypt\. REACHABLE', caseSensitive: false),
        ),
        findsOneWidget,
      );
      final control = find.ancestor(
        of: find.text('The Crypt'),
        matching: find.byType(GestureDetector),
      );
      await tester.scrollUntilVisible(
        control,
        100,
        scrollable: find.byType(Scrollable),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -120));
      await tester.pumpAndSettle();
      await tester.tap(control);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stay here'));
      await tester.pumpAndSettle();

      // assert
      expect(find.text('At Stonebridge'), findsOneWidget);
      expect(find.text('Day 0.'), findsOneWidget);
    });

    testWidgets('arriving writes the journey down as finished', (tester) async {
      // arrange
      final app = PumpedApp(_oneHero(newProfile(worldSeed: 909)));
      await app.pump(tester);

      // act
      await walkTo(tester, 'The Crypt');

      // assert
      expect(app.saved!.world.at, cryptNode);
      expect(app.saved!.world.journey, isNull);
      expect(app.saved!.world.day, 1);
    });

    testWidgets('arriving at a town makes it the place the hero wakes at', (
      tester,
    ) async {
      // arrange
      final app = PumpedApp(
        _oneHero(newProfile(worldSeed: 909), world: _knowingAll()),
      );
      await app.pump(tester);

      // act
      await walkTo(tester, 'Northgate');

      // assert
      expect(find.text('At Northgate'), findsOneWidget);
      expect(app.saved!.world.home, northgate);
      expect(app.saved!.world.day, 2);
    });

    testWidgets('the journey is written down while it is being walked', (
      tester,
    ) async {
      // arrange
      final app = PumpedApp(
        _oneHero(newProfile(worldSeed: 909), world: _knowingAll()),
      );
      await app.pump(tester);
      expect(
        find.bySemanticsLabel(
          RegExp(r'TOWN Northgate\. REACHABLE', caseSensitive: false),
        ),
        findsOneWidget,
      );
      final control = find.ancestor(
        of: find.text('Northgate'),
        matching: find.byType(GestureDetector),
      );
      await tester.scrollUntilVisible(
        control,
        100,
        scrollable: find.byType(Scrollable),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -120));
      await tester.pumpAndSettle();
      await tester.tap(control);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Set out'));
      await tester.pump(const Duration(milliseconds: 1));
      final midJourney = app.saved!;
      for (var day = 0; day < 4; day++) {
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
      }

      // assert
      expect(midJourney.world.isTravelling, isTrue);
      expect(midJourney.world.journey!.to, northgate);
      expect(midJourney.world.day, 1);
    });

    testWidgets('a hero killed mid-journey boots back onto the road', (
      tester,
    ) async {
      // arrange
      final onTheRoad = _oneHero(
        newProfile(worldSeed: 909),
        world: Whereabouts(
          at: stonebridge,
          home: stonebridge,
          discovered: {stonebridge, northgate, cryptNode},
          day: 1,
          journey: Journey(from: stonebridge, to: northgate, daysLeft: 1),
        ),
      );
      final app = PumpedApp(onTheRoad);

      // act
      await app.pump(tester);

      // assert
      expect(find.textContaining('On the road to Northgate'), findsOneWidget);
      expect(find.text('Day 1. one day still to walk.'), findsOneWidget);
      expect(find.text('Walk on'), findsOneWidget);
      expect(app.saved!.world.journey!.to, northgate);
    });

    testWidgets('and nothing walks them until they say so', (tester) async {
      // arrange
      final onTheRoad = _oneHero(
        newProfile(worldSeed: 909),
        world: Whereabouts(
          at: stonebridge,
          home: stonebridge,
          discovered: {stonebridge, northgate, cryptNode},
          day: 1,
          journey: Journey(from: stonebridge, to: northgate, daysLeft: 1),
        ),
      );
      final app = PumpedApp(onTheRoad);
      await app.pump(tester);

      // act
      for (var day = 0; day < 4; day++) {
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
      }

      // assert
      expect(app.saved!.world.day, 1);
      expect(app.saved!.world.journey!.daysLeft, 1);
    });

    testWidgets('pressing Walk on finishes the journey', (tester) async {
      // arrange
      final app = PumpedApp(
        _oneHero(
          newProfile(worldSeed: 909),
          world: Whereabouts(
            at: stonebridge,
            home: stonebridge,
            discovered: {stonebridge, northgate, cryptNode},
            day: 1,
            journey: Journey(from: stonebridge, to: northgate, daysLeft: 1),
          ),
        ),
      );
      await app.pump(tester);

      // act
      await tester.tap(find.text('Walk on'));
      await tester.pumpAndSettle();
      for (var day = 0; day < 4; day++) {
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
      }

      // assert
      expect(find.text('At Northgate'), findsOneWidget);
      expect(app.saved!.world.at, northgate);
      expect(app.saved!.world.day, 2);
    });
  });

  group('the tavern', () {
    testWidgets('sells the place nobody has heard of', (tester) async {
      // arrange
      final app = PumpedApp(
        _oneHero(newProfile(worldSeed: 909).copyWith(gold: 100)),
      );
      await app.pump(tester);

      // act
      await enterTown(tester, 'Stonebridge');
      await openTownDoor(tester, 'Tavern');
      await tester.tap(find.text('Ask $rumorPrice'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await backToTheWorld(tester);

      // assert
      expect(find.text('Northgate'), findsOneWidget);
      expect(app.saved!.world.discovered, contains(northgate));
      expect(app.saved!.world.discovered, isNot(contains(seaCave)));
      expect(app.saved!.profile.gold, 100 - rumorPrice);
    });

    testWidgets('says so and charges nothing when it is out of places', (
      tester,
    ) async {
      // arrange
      final app = PumpedApp(
        _oneHero(
          newProfile(worldSeed: 909).copyWith(gold: 100),
          world: _knowingAll(),
        ),
      );
      await app.pump(tester);

      // act
      await enterTown(tester, 'Stonebridge');
      await openTownDoor(tester, 'Tavern');

      // assert
      expect(find.textContaining('anything left to tell'), findsOneWidget);
      expect(find.text('Ask $rumorPrice'), findsNothing);
      expect(app.saved!.profile.gold, 100);
    });

    testWidgets('a purse that cannot cover it widens nothing', (tester) async {
      // arrange
      final app = PumpedApp(_oneHero(newProfile(worldSeed: 909)));
      await app.pump(tester);

      // act
      await enterTown(tester, 'Stonebridge');
      await openTownDoor(tester, 'Tavern');
      await tester.tap(find.text('Ask $rumorPrice'));
      await tester.pumpAndSettle();

      // assert
      expect(find.textContaining('cannot afford'), findsOneWidget);
      expect(app.saved!.world.discovered, isNot(contains(northgate)));
    });
  });

  group('two towns, two shelves', () {
    testWidgets('the other town is holding different things', (tester) async {
      // arrange
      final app = PumpedApp(
        _oneHero(
          newProfile(worldSeed: 909).copyWith(gold: 500),
          world: _knowingAll(),
        ),
      );
      await app.pump(tester);

      // act
      await enterTown(tester, 'Stonebridge');
      await openTownDoor(tester, 'Merchant');
      final here = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data)
          .whereType<String>()
          .where(
            (line) => line.startsWith('Common ') || line.startsWith('Fine '),
          )
          .toList();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await backToTheWorld(tester);
      await walkTo(tester, 'Northgate');
      await enterTown(tester, 'Northgate');
      await openTownDoor(tester, 'Merchant');
      final there = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data)
          .whereType<String>()
          .where(
            (line) => line.startsWith('Common ') || line.startsWith('Fine '),
          )
          .toList();

      // assert
      expect(here, isNotEmpty);
      expect(there, isNotEmpty);
      expect(here, isNot(there));
    });

    testWidgets('what one town remembers the other one does not', (
      tester,
    ) async {
      // arrange
      final app = PumpedApp(
        _oneHero(
          newProfile(worldSeed: 909).copyWith(gold: 500),
          world: _knowingAll(),
        ),
      );
      await app.pump(tester);

      // act
      await enterTown(tester, 'Stonebridge');
      await openTownDoor(tester, 'Merchant');
      await tester.tap(find.textContaining('Buy ').first);
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await backToTheWorld(tester);
      await walkTo(tester, 'Northgate');

      // assert
      expect(app.saved!.merchant, MerchantVisit.none);
      expect(app.saved!.world.at, northgate);
    });
  });

  group('a camp survives the walk to town and back', () {
    testWidgets('the crawl is still on disk the whole way round', (
      tester,
    ) async {
      // arrange
      final profile = newProfile(worldSeed: 909).copyWith(gold: 200);
      final camp = startDungeonRunAt(cryptNode, profile).copyWith(depth: 3);
      final app = PumpedApp(
        _oneHero(
          suspendRun(profile, camp),
          world: newWhereabouts()
              .hearingOf(northgate)
              .arrivingAt(residuumWorld, cryptNode),
          run: camp,
          dungeon: cryptNode,
        ),
      );
      await app.pump(tester);

      // act
      await walkTo(tester, 'Stonebridge');
      final home = app.saved!;
      await enterTown(tester, 'Stonebridge');
      await openTownDoor(tester, 'Inn');
      await tester.pageBack();
      await tester.pumpAndSettle();
      await backToTheWorld(tester);
      await walkTo(tester, 'The Crypt');

      // assert
      expect(home.run!.depth, 3);
      expect(app.saved!.run!.depth, 3);
      expect(app.saved!.inside, isFalse);
      expect(find.text('Resume the crawl (depth 3 of 5)'), findsOneWidget);
    });
  });

  group('a fight on the road', () {
    testWidgets('is opened over the world when the day rolls one', (
      tester,
    ) async {
      // arrange
      final app = PumpedApp(_oneHero(newProfile(worldSeed: _dangerousWorld)));
      await app.pump(tester);

      // act
      await _walkToRegionalFight(tester, 'The Crypt');

      // assert
      expect(find.byType(GameScreen), findsOneWidget);
      expect(find.text('THE ROAD'), findsOneWidget);
      expect(find.byKey(depthPairKey), findsNothing);
      final bytes = (await tester.runAsync(
        () => _navigationTerrainGlyphs(tester),
      ))!;
      expect(bytes.actual, equals(bytes.expected));
      expect(app.saved!.world.journey, isNotNull);
      expect(app.saved!.run, isNull);
      expect(app.saved!.inside, isFalse);
    });

    testWidgets('a sea-cave spur fight inherits its route palette', (
      tester,
    ) async {
      // arrange
      final profile = newProfile(worldSeed: _dangerousSeaCaveWorld);
      final app = PumpedApp(_oneHero(profile, world: _atNorthgate()));
      await app.pump(tester);

      // act
      await _walkToRegionalFight(tester, 'The Sea-Cave');

      // assert
      expect(find.byType(GameScreen), findsOneWidget);
      expect(find.text('THE ROAD'), findsOneWidget);
      expect(find.byKey(depthPairKey), findsNothing);
      expect(app.saved!.world.journey!.to, seaCave);
      expect(app.saved!.run, isNull);
      expect(app.saved!.inside, isFalse);
      final bytes = (await tester.runAsync(
        () => _navigationTerrainGlyphs(tester),
      ))!;
      expect(bytes.actual, equals(bytes.expected));
    });

    testWidgets('a keep spur fight inherits its route palette', (tester) async {
      // arrange
      final profile = newProfile(worldSeed: _dangerousKeepWorld);
      final app = PumpedApp(_oneHero(profile, world: _atNorthgate()));
      await app.pump(tester);

      // act
      await _walkToRegionalFight(tester, 'The Ruined Keep');

      // assert
      expect(find.byType(GameScreen), findsOneWidget);
      expect(find.text('THE ROAD'), findsOneWidget);
      expect(find.byKey(depthPairKey), findsNothing);
      expect(app.saved!.world.journey!.to, ruinedKeep);
      expect(app.saved!.run, isNull);
      expect(app.saved!.inside, isFalse);
      final bytes = (await tester.runAsync(
        () => _navigationTerrainGlyphs(tester),
      ))!;
      expect(bytes.actual, equals(bytes.expected));
    });

    testWidgets('writes nothing at all to disk while it is in flight', (
      tester,
    ) async {
      // arrange
      final app = PumpedApp(_oneHero(newProfile(worldSeed: _dangerousWorld)));
      await app.pump(tester);
      await walkTo(tester, 'The Crypt');
      final beforeTheFight = Map<String, String>.from(app.files.contents);

      // act
      final fight = _fightOnScreen(tester);
      final hero = fight.state.game.hero.position;
      fight.add(TileTapped(Position(hero.x, hero.y + 1)));
      await tester.pumpAndSettle();
      fight.add(TileTapped(Position(hero.x, hero.y + 2)));
      await tester.pumpAndSettle();

      // assert
      expect(fight.state.game.isEncounter, isTrue);
      expect(app.files.contents, beforeTheFight);
      expect(app.saved!.inside, isFalse);
      expect(app.saved!.run, isNull);
    });

    testWidgets('never lands the hero in the crawl on the next launch', (
      tester,
    ) async {
      // arrange
      final app = PumpedApp(_oneHero(newProfile(worldSeed: _dangerousWorld)));
      await app.pump(tester);

      // act
      await walkTo(tester, 'The Crypt');
      final onDisk = app.saved!;

      // assert
      expect(onDisk.inside, isFalse);
      expect(onDisk.run, isNull);
      expect(onDisk.world.isTravelling, isTrue);
    });
  });

  group('the ends of a road fight', () {
    testWidgets('the way out is a control, because a tap cannot reach it', (
      tester,
    ) async {
      // arrange
      await _pushRoadFight(
        tester,
        profile: newProfile(worldSeed: 909),
        heroAt: const Position(0, 5),
      );

      // act
      final tapped = _fightOnScreen(tester).state.game.hero.position;

      // assert
      expect(find.text('Flee'), findsOneWidget);
      expect(tapped, const Position(0, 5));
    });

    testWidgets('there is no control until the hero reaches an edge', (
      tester,
    ) async {
      // arrange
      await _pushRoadFight(
        tester,
        profile: newProfile(worldSeed: 909),
        heroAt: const Position(7, 5),
      );

      // assert
      expect(find.text('Flee'), findsNothing);
    });

    testWidgets('pressing it closes the fight and keeps the journey', (
      tester,
    ) async {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final (town, world) = await _pushRoadFight(
        tester,
        profile: profile,
        heroAt: const Position(0, 5),
      );

      // act
      await tester.tap(find.text('Flee'));
      await tester.pumpAndSettle();

      // assert
      expect(find.byType(GameScreen), findsNothing);
      expect(world.state.log.last, contains('no further along'));
      expect(town.state.profile.gold, profile.gold);
    });

    testWidgets('every edge of the ground is a way out', (tester) async {
      // arrange
      final edges = {
        'west': const Position(0, 5),
        'east': const Position(encounterWidth - 1, 5),
        'north': const Position(7, 0),
        'south': const Position(7, encounterHeight - 1),
      };

      // act
      final closed = <String>[];
      for (final edge in edges.entries) {
        await _pushRoadFight(
          tester,
          profile: newProfile(worldSeed: 909),
          heroAt: edge.value,
        );
        await tester.tap(find.text('Flee'));
        await tester.pumpAndSettle();
        if (find.byType(GameScreen).evaluate().isEmpty) closed.add(edge.key);
      }

      // assert
      expect(closed, edges.keys.toList());
    });

    testWidgets('a cleared road offers the way on rather than taking it', (
      tester,
    ) async {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final (_, world) = await _pushRoadFight(tester, profile: profile);
      final fight = _fightOnScreen(tester);

      // act
      fight.emit(
        GameViewState(
          game: fight.state.game.copyWith(monsters: const []),
          log: const [],
        ),
      );
      await tester.pumpAndSettle();

      // assert
      expect(find.text('Move on'), findsOneWidget);
      await tester.tap(find.text('Move on'));
      await tester.pumpAndSettle();
      expect(find.byType(GameScreen), findsNothing);
      expect(world.state.log.last, 'The road is yours again.');
    });

    testWidgets('dying wakes the hero at home, stripped of what they carried', (
      tester,
    ) async {
      // arrange
      final profile = newProfile(worldSeed: 909).copyWith(gold: 90);
      final (town, world) = await _pushRoadFight(
        tester,
        profile: profile,
        world: _knowingAll().arrivingAt(residuumWorld, cryptNode),
        dead: true,
      );

      // act
      expect(find.text('Wake at home'), findsOneWidget);
      await tester.tap(find.text('Wake at home'));
      await tester.pumpAndSettle();

      // assert
      expect(find.byType(GameScreen), findsNothing);
      expect(town.state.profile.gold, 0);
      expect(town.state.profile.inventory, isEmpty);
      expect(town.state.profile.hero.hp, town.state.profile.maxHp);
      expect(world.state.world.at, stonebridge);
      expect(world.state.world.at, isNot(cryptNode));
      expect(world.state.isTravelling, isFalse);
    });

    testWidgets('the back button is refused, and says where the way out is', (
      tester,
    ) async {
      // arrange
      await _pushRoadFight(tester, profile: newProfile(worldSeed: 909));

      // act
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      // assert
      expect(find.byType(GameScreen), findsOneWidget);
      expect(_fightOnScreen(tester).state.log, [
        const LogLine(
          'You can only leave by walking off the edge of the road.',
          LogCategory.refused,
        ),
      ]);
    });

    testWidgets('there are no stairs on a road', (tester) async {
      // arrange
      await _pushRoadFight(tester, profile: newProfile(worldSeed: 909));

      // assert
      expect(find.text('Descend >'), findsNothing);
      expect(find.text('Ascend <'), findsNothing);
      expect(find.text('Leave'), findsNothing);
    });

    testWidgets('the backdrop fog matches the road\'s regional palette', (
      tester,
    ) async {
      // arrange
      final route = residuumWorld.routeBetween(stonebridge, cryptNode)!;
      await _pushRoadFight(
        tester,
        profile: newProfile(worldSeed: 909),
        road: route,
      );

      // assert
      final atmosphere = tester.widget<DungeonAtmosphere>(
        find.byType(DungeonAtmosphere),
      );
      expect(atmosphere.fog, paletteForRoad(route).fog);
    });
  });

  group('the doors at a dungeon node', () {
    testWidgets('a hero with no camp is offered the way in, named', (
      tester,
    ) async {
      // arrange
      final app = PumpedApp(
        _oneHero(newProfile(worldSeed: 909), world: _atTheSeaCave()),
      );

      // act
      await app.pump(tester);

      // assert
      expect(find.text('Enter The Sea-Cave'), findsOneWidget);
      expect(find.textContaining('Resume the crawl'), findsNothing);
    });

    testWidgets('entering at a node opens that node\'s dungeon, on disk', (
      tester,
    ) async {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final app = PumpedApp(_oneHero(profile, world: _atTheSeaCave()));
      await app.pump(tester);

      // act
      await tester.tap(find.text('Enter The Sea-Cave'));
      await tester.pumpAndSettle();

      // assert
      expect(app.saved!.dungeon, seaCave);
      expect(
        app.saved!.run!.map.toAscii(),
        startDungeonRunAt(seaCave, profile).map.toAscii(),
      );
      expect(find.text('THE SEA-CAVE'), findsOneWidget);
      final bytes = (await tester.runAsync(
        () => _navigationTerrainGlyphs(tester),
      ))!;
      expect(bytes.actual, equals(bytes.expected));
    });

    testWidgets('the keep is its own dungeon, not the cave\'s', (tester) async {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final app = PumpedApp(_oneHero(profile, world: _atTheKeep()));
      await app.pump(tester);

      // act
      await tester.tap(find.text('Enter The Ruined Keep'));
      await tester.pumpAndSettle();

      // assert
      expect(app.saved!.dungeon, ruinedKeep);
      expect(
        app.saved!.run!.map.toAscii(),
        startDungeonRunAt(ruinedKeep, profile).map.toAscii(),
      );
      expect(find.text('THE RUINED KEEP'), findsOneWidget);
      final bytes = (await tester.runAsync(
        () => _navigationTerrainGlyphs(tester),
      ))!;
      expect(bytes.actual, equals(bytes.expected));
    });

    testWidgets('a camp at this node is the resume-or-delve fork', (
      tester,
    ) async {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final camp = startDungeonRunAt(seaCave, profile).copyWith(depth: 3);

      // act
      final app = PumpedApp(
        _oneHero(
          suspendRun(profile, camp),
          world: _atTheSeaCave(),
          run: camp,
          dungeon: seaCave,
        ),
      );
      await app.pump(tester);

      // assert
      expect(
        find.text('Resume the crawl (depth 3 of ${camp.deepest})'),
        findsOneWidget,
      );
      expect(find.text('Delve anew'), findsOneWidget);
      expect(find.text('Enter The Sea-Cave'), findsNothing);
    });

    testWidgets('a camp three days old is lost, and the door is a plain one', (
      tester,
    ) async {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final camp = startDungeonRunAt(cryptNode, profile).copyWith(depth: 3);

      // act
      final app = PumpedApp(
        _oneHero(
          suspendRun(profile, camp),
          world: _atTheCryptOn(7),
          run: camp,
          dungeon: cryptNode,
          campDay: 4,
        ),
      );
      await app.pump(tester);

      // assert
      expect(
        find.textContaining('the camp at The Crypt is lost'),
        findsOneWidget,
      );
      expect(find.textContaining('Resume the crawl'), findsNothing);
      expect(find.text('Delve anew'), findsNothing);
      expect(find.text('Enter The Crypt'), findsOneWidget);
    });

    testWidgets('a camp two days old is warned about, and still there', (
      tester,
    ) async {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final camp = startDungeonRunAt(cryptNode, profile).copyWith(depth: 3);

      // act
      final app = PumpedApp(
        _oneHero(
          suspendRun(profile, camp),
          world: _atTheCryptOn(6),
          run: camp,
          dungeon: cryptNode,
          campDay: 4,
        ),
      );
      await app.pump(tester);

      // assert
      expect(
        find.text('One more day and the camp is overrun.'),
        findsOneWidget,
      );
      expect(find.text('Resume the crawl (depth 3 of 5)'), findsOneWidget);
    });

    testWidgets('a camp one day old is neither warned about nor lost', (
      tester,
    ) async {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final camp = startDungeonRunAt(cryptNode, profile).copyWith(depth: 3);

      // act
      final app = PumpedApp(
        _oneHero(
          suspendRun(profile, camp),
          world: _atTheCryptOn(5),
          run: camp,
          dungeon: cryptNode,
          campDay: 4,
        ),
      );
      await app.pump(tester);

      // assert
      expect(find.textContaining('overrun'), findsNothing);
      expect(find.text('Resume the crawl (depth 3 of 5)'), findsOneWidget);
    });

    testWidgets('walking into a lost camp bumps the visit as any entry does', (
      tester,
    ) async {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final camp = startDungeonRunAt(cryptNode, profile).copyWith(depth: 3);
      final app = PumpedApp(
        _oneHero(
          suspendRun(profile, camp),
          world: _atTheCryptOn(7),
          run: camp,
          dungeon: cryptNode,
          campDay: 4,
        ),
      );
      await app.pump(tester);

      // act
      await tester.tap(find.text('Enter The Crypt'));
      await tester.pumpAndSettle();

      // assert
      expect(app.saved!.run!.depth, 1);
      expect(app.saved!.run!.visit, camp.visit + 1);
      expect(app.saved!.campDay, isNull);
    });

    testWidgets('a camp somewhere else is never offered a resume here', (
      tester,
    ) async {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final camp = startDungeonRunAt(cryptNode, profile).copyWith(depth: 3);

      // act
      final app = PumpedApp(
        _oneHero(
          suspendRun(profile, camp),
          world: _atTheSeaCave(),
          run: camp,
          dungeon: cryptNode,
        ),
      );
      await app.pump(tester);

      // assert
      expect(find.textContaining('Resume the crawl'), findsNothing);
      expect(find.text('Delve anew'), findsNothing);
      expect(find.text('Enter The Sea-Cave'), findsOneWidget);
    });

    testWidgets('entering with a camp elsewhere asks, and names the camp', (
      tester,
    ) async {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final camp = startDungeonRunAt(cryptNode, profile).copyWith(depth: 3);
      final app = PumpedApp(
        _oneHero(
          suspendRun(profile, camp),
          world: _atTheSeaCave(),
          run: camp,
          dungeon: cryptNode,
        ),
      );
      await app.pump(tester);

      // act
      await tester.tap(find.text('Enter The Sea-Cave'));
      await tester.pumpAndSettle();

      // assert
      expect(
        find.textContaining('abandons your camp at The Crypt'),
        findsOneWidget,
      );
      expect(find.textContaining('depth 3'), findsWidgets);
    });

    testWidgets('keeping the crawl at that question changes nothing', (
      tester,
    ) async {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final camp = startDungeonRunAt(cryptNode, profile).copyWith(depth: 3);
      final app = PumpedApp(
        _oneHero(
          suspendRun(profile, camp),
          world: _atTheSeaCave(),
          run: camp,
          dungeon: cryptNode,
        ),
      );
      await app.pump(tester);

      // act
      await tester.tap(find.text('Enter The Sea-Cave'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep the crawl'));
      await tester.pumpAndSettle();

      // assert
      expect(app.saved!.dungeon, cryptNode);
      expect(app.saved!.run!.depth, 3);
      expect(app.saved!.inside, isFalse);
      expect(find.text('Enter The Sea-Cave'), findsOneWidget);
    });

    testWidgets('giving it up walks into the new dungeon and drops the old', (
      tester,
    ) async {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final camp = startDungeonRunAt(cryptNode, profile).copyWith(depth: 3);
      final app = PumpedApp(
        _oneHero(
          suspendRun(profile, camp),
          world: _atTheSeaCave(),
          run: camp,
          dungeon: cryptNode,
        ),
      );
      await app.pump(tester);

      // act
      await tester.tap(find.text('Enter The Sea-Cave'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Give it up'));
      await tester.pumpAndSettle();

      // assert
      expect(app.saved!.dungeon, seaCave);
      expect(app.saved!.run!.depth, 1);
      expect(app.saved!.run!.visit, camp.visit + 1);
      expect(app.saved!.inside, isTrue);
      expect(find.text('THE SEA-CAVE'), findsOneWidget);
    });

    testWidgets('booting inside a sea-cave crawl lands back in the sea-cave', (
      tester,
    ) async {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final run = startDungeonRunAt(seaCave, profile);

      // act
      final app = PumpedApp(
        _oneHero(
          profile,
          world: _atTheSeaCave(),
          run: run,
          dungeon: seaCave,
          inside: true,
        ),
      );
      await app.pump(tester);

      // assert
      expect(find.text('THE SEA-CAVE'), findsOneWidget);
      expect(app.saved!.dungeon, seaCave);
      expect(find.text('The crawl resumes.'), findsOneWidget);
      final bytes = (await tester.runAsync(
        () => _navigationTerrainGlyphs(tester),
      ))!;
      expect(bytes.actual, equals(bytes.expected));
    });
  });

  group('the crawl status line on a phone-sized screen', () {
    testWidgets('does not overflow with the longest dungeon name and a fight', (
      tester,
    ) async {
      // arrange — a Pixel-sized surface rather than the test default, because
      // the default is wider than a phone and the row that overflowed on a
      // device fitted comfortably on it
      await onAPhone(tester);
      final profile = newProfile(worldSeed: 909);
      final app = PumpedApp(
        _oneHero(
          profile,
          world: _atTheKeep(),
          run: startDungeonRunAt(ruinedKeep, profile),
          dungeon: ruinedKeep,
          inside: true,
        ),
      );

      // act
      await app.pump(tester);

      // assert
      expect(find.text('THE RUINED KEEP'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('reads the same total after a camp is written and read', (
      tester,
    ) async {
      // arrange — a camp two floors into a sea-cave that rolled six, taken
      // through the store so the total comes back off `loadRun` rather than off
      // the state the test built
      await onAPhone(tester);
      const worldSeed = 4242;
      final profile = newProfile(worldSeed: worldSeed);
      final delve = startDungeonRunAt(seaCave, profile);
      final camp = delve.copyWith(
        hero: delve.hero.copyWith(position: delve.stairsDown),
        depth: 2,
      );
      final written = encodeSave(
        _oneHero(
          suspendRun(profile, camp),
          world: _atTheSeaCave(),
          run: camp,
          dungeon: seaCave,
        ),
      );
      final app = PumpedApp(decodeSave(written) as SaveDocument);
      await app.pump(tester);

      // act
      await tester.tap(find.textContaining('Resume the crawl'));
      await tester.pumpAndSettle();

      // assert — the document is decoded before it is pumped, because
      // `PumpedApp` boots the object it is handed: pumping the built camp
      // straight in would never reach `loadRun`, and the total the codec
      // recomputes is exactly what this test is about
      expect(delveDepth(seaCave, worldSeed, camp.visit), 6);
      expect(find.text('2 / 6'), findsOneWidget);
    });

    testWidgets('shows the hit points, the condition and the place at once', (
      tester,
    ) async {
      // arrange
      await onAPhone(tester);
      final profile = newProfile(worldSeed: 909);
      final app = PumpedApp(
        _oneHero(
          profile,
          world: _atTheSeaCave(),
          run: startDungeonRunAt(seaCave, profile),
          dungeon: seaCave,
          inside: true,
        ),
      );

      // act
      await app.pump(tester);

      // assert
      expect(find.text('HP 20 / 20'), findsOneWidget);
      expect(find.text('Steady'), findsOneWidget);
      expect(find.text('THE SEA-CAVE'), findsOneWidget);
      expect(find.text('1 / 4'), findsOneWidget);
      expect(delveDepth(seaCave, 909, 1), 4);
    });
  });
}

/// A world whose first day out of Stonebridge is a fight.
///
/// Swept off the shipped derivation: day one of world 10 rolls under the
/// Stonebridge-to-crypt road's danger of 15.
const int _dangerousWorld = 10;

/// A world whose first day out of Northgate is a Sea-Cave spur fight.
///
/// Swept off the shipped derivation: day one of world 0 rolls under the
/// Northgate-to-Sea-Cave road's danger of 30.
const int _dangerousSeaCaveWorld = 0;

/// A world whose first day out of Northgate is a Ruined-Keep spur fight.
///
/// Swept off the shipped derivation: day one of world 0 rolls under the
/// Northgate-to-Ruined-Keep road's danger of 40.
const int _dangerousKeepWorld = 0;
