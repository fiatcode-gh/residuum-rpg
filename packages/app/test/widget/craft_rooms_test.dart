import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/town/alchemist_screen.dart';
import 'package:residuum_app/town/forge_screen.dart';
import 'package:residuum_app/town/town_bloc.dart';
import 'package:residuum_app/town/town_screen.dart';
import 'package:residuum_app/world/world_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

/// A phone-sized viewport, which is where seven doors have to fit.
const Size _phone = Size(360, 640);

Item _gear(String id, BaseItem base, {int temper = 0}) =>
    Item(id: id, base: base, rarity: Rarity.common).tempered(temper);

Profile _hero({
  List<Item> inventory = const [],
  Equipment equipment = const {},
  Map<MaterialId, int> materials = const {},
  int gold = 0,
  int blacksmith = 0,
}) => newProfile(worldSeed: 4).copyWith(
  inventory: inventory,
  equipment: equipment,
  materials: materials,
  gold: gold,
  skills: {
    ...untrainedSkills,
    SkillId.blacksmith: SkillState(level: blacksmith),
  },
);

/// One town room, under a real town bloc and a real world bloc.
Future<TownBloc> _openRoom(
  WidgetTester tester,
  Widget room,
  Profile profile,
) async {
  final town = TownBloc(profile: profile);
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
        child: room,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return town;
}

void main() {
  group('the town door column', () {
    testWidgets('offers all seven doors on a phone', (tester) async {
      // arrange
      tester.view.physicalSize = _phone;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // act
      await _openRoom(tester, const TownScreen(), _hero());

      // assert - a door a player cannot reach is a door that is not there, and
      // the fork that overflowed a 600-pixel screen by 45 pixels is on record
      for (final door in [
        'Merchant',
        'Bank',
        'Inn',
        'Character',
        'Tavern',
        'Forge',
        'Alchemist',
      ]) {
        await tester.scrollUntilVisible(find.text(door), 100);
        await tester.pumpAndSettle();
        expect(find.text(door), findsOneWidget, reason: door);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('says what the hero has gathered, mark and word and count', (
      tester,
    ) async {
      // arrange
      final profile = _hero(materials: const {MaterialId.ore: 5});

      // act
      await _openRoom(tester, const TownScreen(), profile);

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
  });

  group('the forge', () {
    testWidgets('offers Smelt only when there is ore for it', (tester) async {
      // arrange
      final short = _hero(materials: const {MaterialId.ore: 1});

      // act
      await _openRoom(tester, const ForgeScreen(), short);

      // assert
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Smelt'),
      );
      expect(button.onPressed, isNull);
      expect(find.textContaining('takes 2 ore'), findsOneWidget);
    });

    testWidgets('smelting from the screen moves the counters', (tester) async {
      // arrange
      final ready = _hero(materials: const {MaterialId.ore: 2});
      final bloc = await _openRoom(tester, const ForgeScreen(), ready);

      // act
      await tester.tap(find.widgetWithText(FilledButton, 'Smelt'));
      await tester.pumpAndSettle();

      // assert
      expect(bloc.state.profile.materials, const {MaterialId.ingot: 1});
      expect(find.text(MaterialId.ingot.marking), findsOneWidget);
      expect(find.text('Ingot'), findsOneWidget);
    });

    testWidgets('says there is no steel for the bench when there is none', (
      tester,
    ) async {
      // arrange
      final bare = newProfile(worldSeed: 4)
          .copyWith(inventory: const [], equipment: const {});

      // act
      await _openRoom(tester, const ForgeScreen(), bare);

      // assert
      expect(find.text('You have no steel for the bench.'), findsOneWidget);
    });

    testWidgets('a dead row carries the reason rather than going grey', (
      tester,
    ) async {
      // arrange - a hero holding a sword already at +1, four levels short of
      // the gate the next tier needs
      final gated = _hero(
        inventory: [_gear('drop-1', ironSword, temper: 1)],
        materials: const {MaterialId.ingot: 9},
        gold: 500,
        blacksmith: 4,
      );

      // act
      await _openRoom(tester, const ForgeScreen(), gated);

      // assert - the sentence is temperRefusal's own, so the screen and the
      // transaction can never come to disagree
      expect(find.text('that needs Blacksmith 5'), findsOneWidget);
      final button = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Temper'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('names the price of the next tier when it is open', (
      tester,
    ) async {
      // arrange
      final ready = _hero(
        inventory: [_gear('drop-1', ironSword)],
        materials: const {MaterialId.ingot: 2},
        gold: 500,
      );

      // act
      await _openRoom(tester, const ForgeScreen(), ready);

      // assert
      expect(find.text('Next tier: 1 ingot and 10 gold.'), findsOneWidget);
    });

    testWidgets('a worn piece says it is worn', (tester) async {
      // arrange
      final dressed = _hero(
        equipment: {EquipSlot.chest: _gear('drop-2', mailHauberk)},
        materials: const {MaterialId.ingot: 2},
        gold: 500,
      );

      // act
      await _openRoom(tester, const ForgeScreen(), dressed);

      // assert - the marking column is spoken for by the tier, so worn is a word
      expect(find.textContaining('(worn)'), findsOneWidget);
    });

    testWidgets('tempering from the screen shows the temper in the row', (
      tester,
    ) async {
      // arrange
      final ready = _hero(
        inventory: [_gear('drop-1', ironSword)],
        materials: const {MaterialId.ingot: 2},
        gold: 500,
      );
      final bloc = await _openRoom(tester, const ForgeScreen(), ready);

      // act
      await tester.tap(find.widgetWithText(TextButton, 'Temper'));
      await tester.pumpAndSettle();

      // assert
      expect(bloc.state.profile.inventory.single.temper, 1);
      expect(find.textContaining('temper'), findsWidgets);
    });

    testWidgets('offers no potion for the bench at all', (tester) async {
      // arrange
      final profile = _hero(
        inventory: [_gear('kit-2', healingPotion)],
        materials: const {MaterialId.ingot: 9},
        gold: 500,
      );

      // act
      await _openRoom(tester, const ForgeScreen(), profile);

      // assert - only steel reaches the bench, so the refusal never has to be
      // read on this screen
      expect(find.text('You have no steel for the bench.'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Temper'), findsNothing);
    });
  });

  group('the alchemist', () {
    testWidgets('offers Brew only when there are herbs for it', (tester) async {
      // arrange
      final short = _hero(materials: const {MaterialId.herb: 2});

      // act
      await _openRoom(tester, const AlchemistScreen(), short);

      // assert
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Brew'),
      );
      expect(button.onPressed, isNull);
      expect(find.textContaining('takes 3 herbs'), findsOneWidget);
    });

    testWidgets('brewing from the screen puts a potion in the pack', (
      tester,
    ) async {
      // arrange
      final ready = _hero(materials: const {MaterialId.herb: 3});
      final bloc = await _openRoom(tester, const AlchemistScreen(), ready);

      // act
      await tester.tap(find.widgetWithText(FilledButton, 'Brew'));
      await tester.pumpAndSettle();

      // assert
      expect(bloc.state.profile.inventory.last.base, healingPotion);
      expect(bloc.state.profile.materials, isEmpty);
    });

    testWidgets('says what the shelf would charge for the same potion', (
      tester,
    ) async {
      // arrange
      final profile = _hero();

      // act
      await _openRoom(tester, const AlchemistScreen(), profile);

      // assert - read off the merchant's own arithmetic, so brewing and buying
      // cannot come to be worth different things
      final worth = buyPriceOf(
        const Item(id: 'x', base: healingPotion, rarity: Rarity.common),
      );
      expect(find.textContaining('$worth gold'), findsOneWidget);
    });
  });
}
