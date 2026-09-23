import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/notice/notice.dart';
import 'package:residuum_app/style/surfaces.dart';
import 'package:residuum_app/town/town_bloc.dart';
import 'package:residuum_app/town/town_screen.dart';
import 'package:residuum_app/world/world_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

Profile _hero({
  List<Item> inventory = const [],
  Map<MaterialId, int> materials = const {},
  int gold = 0,
  int bankedGold = 0,
  int visit = 0,
}) => newProfile(worldSeed: 4).copyWith(
  inventory: inventory,
  materials: materials,
  gold: gold,
  bankedGold: bankedGold,
  visit: visit,
);

/// The town shell, under a real town bloc and a real world bloc.
///
/// The default 800x600 test surface is deliberate, not an oversight: it is
/// the exact geometry that once overflowed the door column by 45 pixels, and
/// this file's whole job is to prove that trap stays closed.
Future<TownBloc> _openTown(
  WidgetTester tester,
  Profile profile, {
  SaveNotice? notice,
}) async {
  final town = TownBloc(profile: profile, notice: notice);
  final world = WorldBloc(
    world: newWhereabouts(),
    worldSeed: profile.worldSeed,
  );
  await tester.pumpWidget(
    MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: town),
          BlocProvider.value(value: world),
        ],
        child: const TownScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(town.close);
  addTearDown(world.close);
  return town;
}

/// The seven doors, in their locked order.
const _doors = [
  ('town-door-merchant', 'Merchant', 'Buy, sell, and buy back'),
  ('town-door-bank', 'Bank', 'Gold and gear, safe from death'),
  ('town-door-inn', 'Inn', 'A bed for the night'),
  ('town-door-character', 'Character', 'Gear, spells, skills, and pack'),
  ('town-door-tavern', 'Tavern', 'Ask about the roads'),
  ('town-door-forge', 'Forge', 'Smelt ore, temper steel'),
  ('town-door-alchemist', 'Alchemist', 'Brew herbs into potions'),
];

void main() {
  group('the town shell', () {
    testWidgets('every door says what it is for', (tester) async {
      // act
      await _openTown(tester, _hero());

      // assert - each purpose line is on screen exactly once
      for (final (_, _, purpose) in _doors) {
        expect(find.text(purpose), findsOneWidget, reason: purpose);
      }
    });

    testWidgets('the place and its standing read together', (tester) async {
      // arrange
      final profile = _hero(visit: 2);

      // act
      await _openTown(tester, profile);

      // assert - the header replaces the AppBar title rather than doubling
      // it, and every door carries a label and a purpose line under it
      expect(find.text('Stonebridge'), findsOneWidget);
      expect(find.text('You have gone down twice.'), findsOneWidget);
      for (final (_, label, purpose) in _doors) {
        expect(find.text(label), findsOneWidget, reason: label);
        expect(find.text(purpose), findsOneWidget, reason: purpose);
      }
    });

    testWidgets('seven doors, in order, and no eighth', (tester) async {
      // act
      await _openTown(tester, _hero());

      // assert - each row carries its own label and purpose under its own
      // key, and the rows read top to bottom in the locked order
      final positions = <double>[];
      for (final (key, label, purpose) in _doors) {
        final row = find.byKey(Key(key));
        expect(row, findsOneWidget, reason: key);
        expect(
          find.descendant(of: row, matching: find.text(label)),
          findsOneWidget,
          reason: label,
        );
        expect(
          find.descendant(of: row, matching: find.text(purpose)),
          findsOneWidget,
          reason: purpose,
        );
        final medallion = find.byKey(Key('$key-medallion'));
        expect(medallion, findsOneWidget, reason: '$key medallion');
        expect(tester.getSize(medallion), const Size(44, 44));
        expect(
          find.descendant(of: medallion, matching: find.byType(Image)),
          findsNothing,
        );
        expect(
          find.descendant(of: medallion, matching: find.byType(Icon)),
          findsNothing,
        );
        expect(
          find.descendant(of: medallion, matching: find.byType(Text)),
          findsNothing,
        );
        positions.add(tester.getTopLeft(row).dy);
      }
      for (var i = 1; i < positions.length; i++) {
        expect(positions[i], greaterThan(positions[i - 1]));
      }
      expect(find.text('Heroes'), findsNothing);
    });

    testWidgets('the last door is reachable on a 600-pixel-tall screen', (
      tester,
    ) async {
      // act - a door a player cannot reach is a door that is not there, and
      // the fork that overflowed a 600-pixel screen by 45 pixels is on record
      await _openTown(tester, _hero());

      // assert
      for (final (_, label, _) in _doors) {
        await tester.scrollUntilVisible(find.text(label), 100);
        await tester.pumpAndSettle();
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('every door opens its own room', (tester) async {
      // arrange
      await _openTown(tester, _hero());

      // act & assert - each door opens the room its label names, including
      // the tavern, which reads WorldBloc and would throw without it
      for (final (_, label, _) in _doors) {
        await tester.scrollUntilVisible(find.text(label), 100);
        await tester.pumpAndSettle();
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(find.text(label), findsOneWidget, reason: label);
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
    });

    testWidgets('says what the hero has gathered, mark and word and count', (
      tester,
    ) async {
      // arrange
      final profile = _hero(materials: const {MaterialId.ore: 5});

      // act
      await _openTown(tester, profile);

      // assert
      for (final material in MaterialId.values) {
        expect(
          find.textContaining(material.word),
          findsWidgets,
          reason: material.name,
        );
      }
      expect(find.text(MaterialId.ore.marking), findsOneWidget);
      expect(find.text('5'), findsWidgets);
    });

    testWidgets('the status block states the figures and the notice', (
      tester,
    ) async {
      // arrange
      final profile = _hero(gold: 12, bankedGold: 40);
      const notice = SentenceNotice('the well runs cold');

      // act
      await _openTown(tester, profile, notice: notice);

      // assert - health renders through the shared meter: the label, both
      // figures and the fill fraction, not a padded string
      final meter = find.byKey(townHealthMeterKey);
      expect(meter, findsOneWidget);
      expect(
        find.descendant(
          of: meter,
          matching: find.text('Health ${profile.hero.hp} / ${profile.maxHp}'),
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
        profile.hero.hp / profile.maxHp,
      );

      // assert - carried and banked gold each render as a label beside its
      // value, not as one padded string
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

      // assert - the label column holds still: a fixed-width slot, not a
      // padded string that only ever aligned in monospace
      expect(
        tester.getTopLeft(carriedValue).dx,
        tester.getTopLeft(bankedValue).dx,
      );

      expect(find.text('— the well runs cold.'), findsOneWidget);
    });

    testWidgets('the exact descents sentence for every named visit count', (
      tester,
    ) async {
      for (final MapEntry(key: visit, value: sentence) in const {
        0: 'You have not gone down yet.',
        1: 'You have gone down once.',
        2: 'You have gone down twice.',
        5: 'You have gone down 5 times.',
      }.entries) {
        // act
        await _openTown(tester, _hero(visit: visit));

        // assert
        expect(find.text(sentence), findsOneWidget, reason: '$visit');
      }
    });
  });
}
