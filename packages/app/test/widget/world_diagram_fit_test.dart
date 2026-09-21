import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/style/surfaces.dart';
import 'package:residuum_app/style/tokens.dart' as tokens;
import 'package:residuum_app/world/world_route_diagram.dart';
import 'package:residuum_app/world/world_screen.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../support/phone.dart';
import '../support/pumped_app.dart';

/// Built once, from a bare Material 3 dark theme with nothing else set — the
/// same shape `main.dart` builds today. No lavender hex is ever written down
/// here: if the framework's default palette ever moves, this reference moves
/// with it and the "must not equal" assertions below stay honest.
final ThemeData m3 = ThemeData(brightness: Brightness.dark, useMaterial3: true);

/// Every node the shipped world has. Discovering all five at once is what
/// puts the longest name, `The Ruined Keep`, on screen beside every other
/// state the diagram can print.
final Set<NodeId> _allNodes = {
  stonebridge,
  northgate,
  cryptNode,
  seaCave,
  ruinedKeep,
};

SaveDocument _oneHero(
  Profile profile, {
  Whereabouts? world,
  GameState? run,
  NodeId? dungeon,
}) => SaveDocument.one(
  id: 'hero-1',
  label: 'Hero 1',
  profile: profile,
  world: world,
  run: run,
  dungeon: run == null ? null : (dungeon ?? cryptNode),
  campDay: run == null ? null : 0,
);

/// A hero standing at the sea-cave, having heard of it, of Northgate and of
/// the ruined keep. The same shape `world_screen_test.dart`'s `_atTheSeaCave`
/// builds, reconstructed here because that helper is private to its file.
Whereabouts _atTheSeaCave() => newWhereabouts()
    .hearingOf(northgate)
    .hearingOf(seaCave)
    .hearingOf(ruinedKeep)
    .arrivingAt(residuumWorld, northgate)
    .arrivingAt(residuumWorld, seaCave);

/// The `Material` every stock button and dialog paints itself onto:
/// [Material.color] is the rendered fill and [Material.textStyle]'s colour is
/// the rendered foreground, both resolved by the framework from the active
/// theme rather than typed in by this test.
Material _materialOf(WidgetTester tester, Finder control) =>
    tester.widget<Material>(
      find.descendant(of: control, matching: find.byType(Material)).first,
    );

Color _fillOf(WidgetTester tester, Finder control) =>
    _materialOf(tester, control).color!;

Color _foregroundOf(WidgetTester tester, Finder control) =>
    _materialOf(tester, control).textStyle!.color!;

/// Every `RenderParagraph` the route diagram paints — one loop over the five
/// node-shape keys, plus everything else the diagram renders that is not one
/// of those (the route labels) — asserted against F8's clip box and recorded
/// against it, rather than asserted per node.
///
/// [didExceedMaxLines] is the real proof: every label in the diagram carries
/// `maxLines: 1`, so a paragraph that needed a second line to hold its text
/// reports it here regardless of the `TextOverflow.clip` sitting beside it.
void _expectNoClipping(WidgetTester tester, {required String reason}) {
  final nodeElements = <Element>{};
  var widestNode = 0.0;
  for (final id in _allNodes) {
    final finder = find.descendant(
      of: find.byKey(ValueKey('world-node-${id.value}-shape')),
      matching: find.byType(RichText),
    );
    nodeElements.addAll(finder.evaluate());
    for (final paragraph in tester.renderObjectList<RenderParagraph>(finder)) {
      expect(paragraph.didExceedMaxLines, isFalse, reason: '$reason (node)');
      widestNode = math.max(widestNode, paragraph.size.width);
    }
  }

  final diagramElements = find
      .descendant(
        of: find.byType(WorldRouteDiagram),
        matching: find.byType(RichText),
      )
      .evaluate()
      .toSet();
  var widestRoute = 0.0;
  for (final element in diagramElements.difference(nodeElements)) {
    final paragraph = element.renderObject! as RenderParagraph;
    expect(
      paragraph.didExceedMaxLines,
      isFalse,
      reason: '$reason (route label)',
    );
    widestRoute = math.max(widestRoute, paragraph.size.width);
  }

  expect(tester.takeException(), isNull, reason: reason);
  debugPrint(
    '$reason — widest node-shape paragraph '
    '${widestNode.toStringAsFixed(2)} dp against a 120 dp box; widest '
    'route-label paragraph ${widestRoute.toStringAsFixed(2)} dp against a '
    '128 dp box',
  );
}

void main() {
  group('no diagram label is clipped', () {
    testWidgets(
      'every discovered node and every route label lays out inside its box '
      'with a journey in progress',
      (tester) async {
        // arrange — every node discovered, and a journey under way so that
        // TRAVEL IN PROGRESS (the widest node state) and ON THIS ROAD (the
        // widest route line) both render, on every node including the
        // longest name in the world, The Ruined Keep.
        await onAPhone(tester);
        final app = PumpedApp(
          _oneHero(
            newProfile(worldSeed: 909),
            world: Whereabouts(
              at: stonebridge,
              home: stonebridge,
              discovered: _allNodes,
              journey: Journey(from: stonebridge, to: northgate, daysLeft: 1),
            ),
          ),
        );

        // act
        await app.pump(tester);

        // assert
        _expectNoClipping(
          tester,
          reason: 'TRAVEL IN PROGRESS and ON THIS ROAD, every node discovered',
        );
      },
    );

    testWidgets(
      'every discovered node and every route label lays out inside its box '
      'standing still',
      (tester) async {
        // arrange — the complementary state: no journey, so the nodes read
        // HERE (Stonebridge), REACHABLE (the crypt and Northgate, both a
        // direct road away) and NO ROAD FROM HERE (the sea-cave and the
        // ruined keep, reachable only through Northgate) — the three states
        // a journey in progress cannot produce.
        await onAPhone(tester);
        final app = PumpedApp(
          _oneHero(
            newProfile(worldSeed: 909),
            world: Whereabouts(
              at: stonebridge,
              home: stonebridge,
              discovered: _allNodes,
            ),
          ),
        );

        // act
        await app.pump(tester);

        // assert
        _expectNoClipping(
          tester,
          reason:
              'HERE, REACHABLE and NO ROAD FROM HERE, every node discovered',
        );
      },
    );
  });

  group('the world screen renders no Material 3 default', () {
    testWidgets("WorldDoor's rendered fill equals raised, not M3 primary", (
      tester,
    ) async {
      // arrange
      final app = PumpedApp(_oneHero(newProfile(worldSeed: 909)));

      // act
      await app.pump(tester);

      // assert
      final door = find.widgetWithText(FilledButton, 'Heroes');
      expect(_fillOf(tester, door), tokens.raised);
      expect(_fillOf(tester, door), isNot(m3.colorScheme.primary));
    });

    testWidgets('the travel dialog renders panel and ink, not M3 defaults', (
      tester,
    ) async {
      // arrange
      final app = PumpedApp(_oneHero(newProfile(worldSeed: 909)));
      await app.pump(tester);

      // act
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

      // assert
      final dialog = find.byType(Dialog);
      expect(_fillOf(tester, dialog), tokens.panel);
      expect(_fillOf(tester, dialog), isNot(m3.colorScheme.surface));
      for (final label in ['Stay here', 'Set out']) {
        final action = find.widgetWithText(TextButton, label);
        final foreground = _foregroundOf(tester, action);
        expect(foreground, tokens.ink, reason: label);
        expect(foreground, isNot(m3.colorScheme.primary), reason: label);
      }
    });

    testWidgets(
      'the give-up-the-camp dialog renders panel and ink, not M3 defaults',
      (tester) async {
        // arrange — a camp at the crypt, the hero standing at the sea-cave,
        // so entering it asks whether to give the crypt camp up.
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
        final dialog = find.byType(Dialog);
        expect(_fillOf(tester, dialog), tokens.panel);
        expect(_fillOf(tester, dialog), isNot(m3.colorScheme.surface));
        for (final label in ['Keep the crawl', 'Give it up']) {
          final action = find.widgetWithText(TextButton, label);
          final foreground = _foregroundOf(tester, action);
          expect(foreground, tokens.ink, reason: label);
          expect(foreground, isNot(m3.colorScheme.primary), reason: label);
        }
      },
    );
  });

  group("the world's health meter and two value rows", () {
    testWidgets(
      'the meter carries the figures and the fraction, and carried and '
      'banked gold each render as a label beside a value',
      (tester) async {
        // arrange
        final base = newProfile(worldSeed: 909);
        final profile = base.copyWith(
          hero: base.hero.copyWith(hp: 13),
          gold: 12,
          bankedGold: 40,
        );
        final app = PumpedApp(_oneHero(profile));

        // act
        await app.pump(tester);

        // assert — health renders through the shared meter: the label, both
        // figures and the fill fraction, not a padded string
        final meter = find.byKey(worldHealthMeterKey);
        expect(meter, findsOneWidget);
        expect(
          find.descendant(
            of: meter,
            matching: find.text('Health 13 / ${profile.maxHp}'),
          ),
          findsOneWidget,
        );
        expect(
          tester
              .widget<LinearProgressIndicator>(
                find.descendant(
                  of: meter,
                  matching: find.byType(LinearProgressIndicator),
                ),
              )
              .value,
          13 / profile.maxHp,
        );

        // assert — carried and banked gold each render as a label beside its
        // value, not as one padded string, and hold at the same left edge
        final carried = find.widgetWithText(LabelledValue, 'Carried');
        final banked = find.widgetWithText(LabelledValue, 'Banked');
        expect(carried, findsOneWidget);
        expect(banked, findsOneWidget);
        final carriedValue = find.descendant(
          of: carried,
          matching: find.text('12 gold'),
        );
        final bankedValue = find.descendant(
          of: banked,
          matching: find.text('40 gold'),
        );
        expect(carriedValue, findsOneWidget);
        expect(bankedValue, findsOneWidget);
        expect(
          tester.getTopLeft(carriedValue).dx,
          tester.getTopLeft(bankedValue).dx,
        );
      },
    );
  });
}
