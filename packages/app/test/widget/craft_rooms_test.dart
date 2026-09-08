import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/town/alchemist_screen.dart';
import 'package:residuum_app/town/forge_screen.dart';
import 'package:residuum_app/town/town_bloc.dart';
import 'package:residuum_app/town/town_screen.dart';
import 'package:residuum_app/notice/notice.dart';
import 'package:residuum_app/world/world_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../support/phone.dart';

Item _gear(String id, BaseItem base, {int temper = 0}) =>
    Item(id: id, base: base, rarity: Rarity.common).tempered(temper);

/// A craft-stream state whose next [brews] rolls all succeed at the 5% floor.
///
/// The 5% floor arrives at Herbcraft 8, so the pattern holds however many
/// level-ups the batch itself earns.
int _stateBrewing(int brews) {
  for (var state = 1; state < 2000000; state++) {
    final rng = Rng.fromState(state);
    var clean = true;
    for (var i = 0; i < brews; i++) {
      if (rng.rollRange(0, 99) < 5) {
        clean = false;
        break;
      }
    }
    if (clean) return state;
  }
  throw StateError('no state brews clean');
}

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
  await onAPhone(tester);
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

    testWidgets('one press commits exactly the pending count', (tester) async {
      // arrange
      final ready = _hero(materials: const {MaterialId.ore: 4});
      final bloc = await _openRoom(tester, const ForgeScreen(), ready);

      // act - dial one and commit: the n = 1 shape
      await tester.tap(find.text('+'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Smelt'));
      await tester.pumpAndSettle();

      // assert
      expect(bloc.state.profile.materials, const {
        MaterialId.ore: 2,
        MaterialId.ingot: 1,
      });
    });

    testWidgets('one press commits the whole pending count', (tester) async {
      // arrange
      final ready = _hero(materials: const {MaterialId.ore: 4});
      final bloc = await _openRoom(tester, const ForgeScreen(), ready);

      // act - dial two, commit once
      await tester.tap(find.text('+'));
      await tester.pump();
      await tester.tap(find.text('+'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Smelt'));
      await tester.pumpAndSettle();

      // assert - the commit spends the whole pending count as one-attempt-per-
      // unit work, not one unit
      expect(bloc.state.profile.materials, const {MaterialId.ingot: 2});
    });

    testWidgets('the smelt stepper cannot dial past the ore', (tester) async {
      // arrange - five ore make two ingots, and no more
      final ready = _hero(materials: const {MaterialId.ore: 5});
      await _openRoom(tester, const ForgeScreen(), ready);

      // act
      await tester.tap(find.text('+'));
      await tester.pump();
      await tester.tap(find.text('+'));
      await tester.pump();
      await tester.tap(find.text('+'));
      await tester.pump();

      // assert - the cap clamps at the actual resources: 5 ore ÷ 2 = 2
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('MAX takes the count to the cap', (tester) async {
      // arrange - seven ore make three ingots
      final ready = _hero(materials: const {MaterialId.ore: 7});
      await _openRoom(tester, const ForgeScreen(), ready);

      // act
      await tester.tap(find.text('MAX'));
      await tester.pump();

      // assert
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('a held + button advances the count', (tester) async {
      // arrange - a hold has room to repeat
      final ready = _hero(materials: const {MaterialId.ore: 40});
      await _openRoom(tester, const ForgeScreen(), ready);

      // act - press down, then pump the cadence. Inside the room's scroll
      // view the tap recogniser first rides out its own press timeout, then
      // the dial's hold window runs: 100ms to the step, 400ms to the first
      // repeat, 120ms to the next.
      final plus = tester.getCenter(find.text('+'));
      final gesture = await tester.startGesture(plus);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('1'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('2'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 120));
      await gesture.up();
      await tester.pump();

      // assert
      expect(find.text('3'), findsOneWidget);
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

    testWidgets("the forge still carries the town's notice", (tester) async {
      // arrange - the notice mechanism stays on the town screens; only the
      // character screen stops reading it
      final bloc = TownBloc(
        profile: _hero(),
        notice: const SentenceNotice('the fire is banked'),
      );
      final world = WorldBloc(world: newWhereabouts(), worldSeed: 4);
      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: bloc),
              BlocProvider.value(value: world),
            ],
            child: const ForgeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // assert
      expect(find.text('— the fire is banked.'), findsOneWidget);
      addTearDown(bloc.close);
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

    testWidgets(
      'a refused forge row keeps the price of its next tier visible',
      (tester) async {
        // arrange - a hero four Blacksmith levels short of the gate the next
        // tier needs
        final gated = _hero(
          inventory: [_gear('drop-1', ironSword, temper: 1)],
          materials: const {MaterialId.ingot: 9},
          gold: 500,
          blacksmith: 4,
        );
        // act
        await _openRoom(tester, const ForgeScreen(), gated);

        // assert - the reason and the price are two lines, both visible: a hero
        // four levels short can read exactly what the tier will cost
        expect(find.text('that needs Blacksmith 5'), findsOneWidget);
        expect(find.text('Next tier: 2 ingots.'), findsOneWidget);
      },
    );

    testWidgets('a ceiling row says so and names no price', (tester) async {
      // arrange - a sword already at the last tier
      final done = _hero(
        inventory: [_gear('drop-1', ironSword, temper: 3)],
        materials: const {MaterialId.ingot: 9},
        gold: 500,
        blacksmith: 10,
      );
      // act
      await _openRoom(tester, const ForgeScreen(), done);

      // assert - there is no next tier to price, so no price line
      expect(find.text('that is worked as far as it goes'), findsOneWidget);
      expect(find.textContaining('Next tier'), findsNothing);
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
      expect(find.text('Next tier: 1 ingot.'), findsOneWidget);
    });

    testWidgets('the bench splits into worn steel and carried steel', (
      tester,
    ) async {
      // arrange - the same steel both ways: one on the hip, one in the pack
      final dressed = _hero(
        equipment: {EquipSlot.chest: _gear('drop-2', mailHauberk)},
        inventory: [_gear('drop-1', ironSword)],
        materials: const {MaterialId.ingot: 2},
        gold: 500,
      );

      // act
      await _openRoom(tester, const ForgeScreen(), dressed);

      // assert - position says what a word used to: sections are the sentence
      expect(find.text('WORN STEEL'), findsOneWidget);
      expect(find.text('CARRIED STEEL'), findsOneWidget);
      expect(find.textContaining('(worn)'), findsNothing);
      final worn = find.textContaining('Mail Hauberk');
      final carried = find.textContaining('Iron Sword');
      expect(
        tester.getTopLeft(worn).dy,
        lessThan(tester.getTopLeft(find.text('CARRIED STEEL')).dy),
      );
      expect(
        tester.getTopLeft(carried).dy,
        greaterThan(tester.getTopLeft(find.text('CARRIED STEEL')).dy),
      );
    });

    testWidgets('each half of the bench says so when it is empty', (
      tester,
    ) async {
      // arrange - one carried sword, nothing worn
      final armed = _hero(
        inventory: [_gear('drop-1', ironSword)],
        materials: const {MaterialId.ingot: 2},
        gold: 500,
      );

      // act
      await _openRoom(tester, const ForgeScreen(), armed);

      // assert
      expect(find.text('WORN STEEL'), findsOneWidget);
      expect(find.text('You are wearing no steel.'), findsOneWidget);
      expect(find.text('CARRIED STEEL'), findsOneWidget);
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

    testWidgets('one press commits exactly the pending count', (tester) async {
      // arrange
      final ready = _hero(materials: const {MaterialId.herb: 9});
      final bloc = await _openRoom(tester, const AlchemistScreen(), ready);

      // act - dial one and commit
      await tester.tap(find.text('+'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Brew'));
      await tester.pumpAndSettle();

      // assert - one attempt: three herbs, one draw, one potion
      expect(bloc.state.profile.inventory.single.base, healingPotion);
      expect(bloc.state.profile.materials, const {MaterialId.herb: 6});
    });

    testWidgets("the brew cap clamps at the pack's room", (tester) async {
      // arrange - herbs for six, room for three
      final cramped =
          _hero(
            materials: const {MaterialId.herb: 18},
            inventory: [
              for (var made = 0; made < 17; made++)
                _gear('kit-$made', healingPotion),
            ],
          )
          // a craft stream whose next three rolls all brew clean
          .copyWith(craftRngState: _stateBrewing(3));
      final bloc = await _openRoom(tester, const AlchemistScreen(), cramped);

      // act
      await tester.tap(find.text('MAX'));
      await tester.pump();

      // assert - MAX dials three, and the dial says so before the commit
      expect(find.text('3'), findsOneWidget);

      // act
      await tester.tap(find.widgetWithText(FilledButton, 'Brew'));
      await tester.pumpAndSettle();

      // assert - the commit succeeds three, and the pack refusal never speaks
      expect(
        bloc.state.profile.inventory
            .where((item) => item.id.startsWith('brew-'))
            .length,
        3,
      );
      expect(bloc.state.notice, isNull);
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
