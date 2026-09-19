import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/notice/notice.dart';
import 'package:residuum_app/style/surfaces.dart';
import 'package:residuum_app/town/forge_screen.dart';
import 'package:residuum_app/town/illustration.dart';
import 'package:residuum_app/town/tavern_screen.dart';
import 'package:residuum_app/town/town_bloc.dart';
import 'package:residuum_app/town/town_screen.dart';
import 'package:residuum_app/town/town_style.dart';
import 'package:residuum_app/world/world_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../support/phone.dart';

const _doorLabels = [
  'Merchant',
  'Bank',
  'Inn',
  'Character',
  'Tavern',
  'Forge',
  'Alchemist',
];

Profile _hero({int gold = 0}) => newProfile(worldSeed: 4).copyWith(gold: gold);

/// The town shell, under a real town bloc pinned to [town].
Future<void> _openTown(
  WidgetTester tester,
  Profile profile, {
  NodeId? town,
}) async {
  final townBloc = TownBloc(profile: profile, town: town);
  final worldBloc = WorldBloc(
    world: newWhereabouts(),
    worldSeed: profile.worldSeed,
  );
  await tester.pumpWidget(
    MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: townBloc),
          BlocProvider.value(value: worldBloc),
        ],
        child: const TownScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(townBloc.close);
  addTearDown(worldBloc.close);
}

/// One town room, under a real town bloc pinned to [town].
Future<void> _openRoom(
  WidgetTester tester,
  Widget room,
  Profile profile, {
  NodeId? town,
  SaveNotice? notice,
}) async {
  await onAPhone(tester);
  final townBloc = TownBloc(profile: profile, town: town, notice: notice);
  final worldBloc = WorldBloc(
    world: newWhereabouts(),
    worldSeed: profile.worldSeed,
  );
  await tester.pumpWidget(
    MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: townBloc),
          BlocProvider.value(value: worldBloc),
        ],
        child: room,
      ),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(townBloc.close);
  addTearDown(worldBloc.close);
}

void main() {
  group('town illustrations', () {
    testWidgets('Stonebridge carries its illustration', (tester) async {
      // act
      await _openTown(tester, _hero());

      // assert - the key resolves once, states the locked height, and the
      // rendered box is that height, not a guess read off the constructor
      final illustration = find.byKey(townIllustrationKey);
      expect(illustration, findsOneWidget);
      expect(
        tester.widget<Illustration>(illustration).height,
        townIllustrationHeight,
      );
      final sizedBox = find.descendant(
        of: illustration,
        matching: find.byType(SizedBox),
      );
      expect(sizedBox, findsOneWidget);
      expect(tester.getSize(sizedBox).height, townIllustrationHeight);
    });

    testWidgets('Northgate carries none, and nothing stands in for it', (
      tester,
    ) async {
      // act
      await _openTown(tester, _hero(), town: northgate);

      // assert - no key, no type, and no substitute image of any kind
      expect(find.byKey(townIllustrationKey), findsNothing);
      expect(find.byType(Illustration), findsNothing);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('the forge and the tavern are illustrated in both towns', (
      tester,
    ) async {
      for (final town in [stonebridge, northgate]) {
        // act
        await _openRoom(tester, const ForgeScreen(), _hero(), town: town);

        // assert
        final forge = find.byKey(forgeIllustrationKey);
        expect(forge, findsOneWidget, reason: '${town.value} forge');
        expect(
          tester.widget<Illustration>(forge).height,
          roomIllustrationHeight,
          reason: '${town.value} forge height',
        );

        // act
        await _openRoom(tester, const TavernScreen(), _hero(), town: town);

        // assert
        final tavern = find.byKey(tavernIllustrationKey);
        expect(tavern, findsOneWidget, reason: '${town.value} tavern');
        expect(
          tester.widget<Illustration>(tavern).height,
          roomIllustrationHeight,
          reason: '${town.value} tavern height',
        );
      }
    });

    testWidgets('an illustration displaces nothing in the town', (
      tester,
    ) async {
      // arrange
      final profile = _hero(gold: 12);

      // act
      await onAPhone(tester);
      await _openTown(tester, profile);

      // assert - every title, status line, notice and door survives the
      // illustration, scrolling to the later doors exactly as the town
      // shell's own 600-pixel proof does
      expect(find.text('Stonebridge'), findsOneWidget);
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
        find.descendant(
          of: find.widgetWithText(LabelledValue, 'Carried'),
          matching: find.text('12 gold'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.widgetWithText(LabelledValue, 'Banked'),
          matching: find.text('0 gold'),
        ),
        findsOneWidget,
      );
      expect(find.byType(Notice), findsOneWidget);
      for (final label in _doorLabels) {
        await tester.scrollUntilVisible(find.text(label), 100);
        await tester.pumpAndSettle();
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('an illustration sits between the notice and the first '
        'heading', (tester) async {
      const notice = SentenceNotice('the fire is banked');

      // act
      await _openRoom(tester, const ForgeScreen(), _hero(), notice: notice);

      // assert
      final forgeNotice = tester.getTopLeft(find.byType(Notice)).dy;
      final forgeIllustration = tester
          .getTopLeft(find.byKey(forgeIllustrationKey))
          .dy;
      final forgeHeading = tester.getTopLeft(find.text('MATERIALS')).dy;
      expect(forgeIllustration, greaterThan(forgeNotice));
      expect(forgeHeading, greaterThan(forgeIllustration));

      // act
      await _openRoom(tester, const TavernScreen(), _hero(), notice: notice);

      // assert
      final tavernNotice = tester.getTopLeft(find.byType(Notice)).dy;
      final tavernIllustration = tester
          .getTopLeft(find.byKey(tavernIllustrationKey))
          .dy;
      final tavernHeading = tester
          .getTopLeft(find.text('WHAT THEY ARE SAYING'))
          .dy;
      expect(tavernIllustration, greaterThan(tavernNotice));
      expect(tavernHeading, greaterThan(tavernIllustration));
    });

    testWidgets('an illustration says nothing', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        // act
        await _openTown(tester, _hero());

        // assert - the plausible bug this catches is a semanticLabel or a
        // Semantics wrapper reaching the real accessibility tree
        expect(find.semantics.byFlag(SemanticsFlag.isImage), findsNothing);

        // act
        await _openRoom(tester, const ForgeScreen(), _hero());

        // assert
        expect(find.semantics.byFlag(SemanticsFlag.isImage), findsNothing);

        // act
        await _openRoom(tester, const TavernScreen(), _hero());

        // assert
        expect(find.semantics.byFlag(SemanticsFlag.isImage), findsNothing);
      } finally {
        handle.dispose();
      }
    });
  });
}
