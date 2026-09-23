import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/item_presentation.dart';
import 'package:residuum_app/town/alchemist_screen.dart';
import 'package:residuum_app/town/forge_screen.dart';
import 'package:residuum_app/town/town_bloc.dart';
import 'package:residuum_app/town/town_style.dart';
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

/// A craft stream whose next rolls fail exactly where [failed] says true.
int _stateRolling(List<bool> failed) {
  for (var state = 1; state < 2000000; state++) {
    final rng = Rng.fromState(state);
    var matches = true;
    for (final want in failed) {
      if ((rng.rollRange(0, 99) < 5) != want) {
        matches = false;
        break;
      }
    }
    if (matches) return state;
  }
  throw StateError('no state rolls that pattern');
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

/// One town room under a bloc the caller built directly, for tests that need
/// a starting notice or a craft stream the room's own transaction stream
/// would not otherwise produce.
Future<void> _openWithBloc(
  WidgetTester tester,
  TownBloc bloc,
  Widget room,
) async {
  await onAPhone(tester);
  final world = WorldBloc(
    world: newWhereabouts(),
    worldSeed: bloc.state.profile.worldSeed,
  );
  await tester.pumpWidget(
    MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: bloc),
          BlocProvider.value(value: world),
        ],
        child: room,
      ),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(bloc.close);
}

Future<void> _enterForgeRoute(WidgetTester tester, String route) async {
  await tester.tap(find.byKey(ValueKey<String>(route)));
  await tester.pumpAndSettle();
}

void main() {
  group('the forge menu', () {
    testWidgets('offers exactly Smelt and Temper routes', (tester) async {
      await _openRoom(tester, const ForgeScreen(), _hero());

      expect(find.byKey(const ValueKey('forge-route-smelt')), findsOneWidget);
      expect(find.byKey(const ValueKey('forge-route-temper')), findsOneWidget);
      expect(find.text('Smelt'), findsOneWidget);
      expect(find.text('Turn ore into ingots.'), findsOneWidget);
      expect(find.text('Temper'), findsOneWidget);
      expect(find.text('Work carried or worn steel.'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(TextButton), findsNothing);
      expect(find.byType(CountStepper), findsNothing);
      expect(find.text('Craft'), findsNothing);
      expect(find.byKey(const ValueKey('forge-route-craft')), findsNothing);
    });

    testWidgets('routes keep the TownBloc and leave profile state unchanged', (
      tester,
    ) async {
      final bloc = await _openRoom(tester, const ForgeScreen(), _hero());
      final before = bloc.state.profile;

      await _enterForgeRoute(tester, 'forge-route-smelt');
      expect(find.text('SMELTING'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await _enterForgeRoute(tester, 'forge-route-temper');
      expect(find.text('TEMPERING'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(bloc.state.profile, before);
    });
  });
  group('the forge', () {
    testWidgets('offers Smelt only when there is ore for it', (tester) async {
      // arrange
      final short = _hero(materials: const {MaterialId.ore: 1});

      // act
      await _openRoom(tester, const ForgeScreen(), short);
      await _enterForgeRoute(tester, 'forge-route-smelt');

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
      await _enterForgeRoute(tester, 'forge-route-smelt');

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
      await _enterForgeRoute(tester, 'forge-route-smelt');

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
      await _enterForgeRoute(tester, 'forge-route-smelt');

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
      await _enterForgeRoute(tester, 'forge-route-smelt');

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
      await _enterForgeRoute(tester, 'forge-route-smelt');

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
      await _enterForgeRoute(tester, 'forge-route-temper');

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
      await _enterForgeRoute(tester, 'forge-route-temper');

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
        await _enterForgeRoute(tester, 'forge-route-temper');

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
      await _enterForgeRoute(tester, 'forge-route-temper');

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
      await _enterForgeRoute(tester, 'forge-route-temper');

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
      await _enterForgeRoute(tester, 'forge-route-temper');

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
      await _enterForgeRoute(tester, 'forge-route-temper');

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
      await _enterForgeRoute(tester, 'forge-route-temper');

      // act
      await tester.tap(find.widgetWithText(TextButton, 'Temper'));
      await tester.pumpAndSettle();

      // assert
      expect(bloc.state.profile.inventory.single.temper, 1);
      expect(find.textContaining('temper'), findsWidgets);
    });

    testWidgets(
      'a temper that levels Blacksmith shows the forge its own sentence',
      (tester) async {
        // arrange - one xp short of Blacksmith 1, so the temper's own
        // training crosses the level
        final leveling = newProfile(worldSeed: 4).copyWith(
          inventory: [_gear('drop-1', ironSword)],
          equipment: const {},
          materials: const {MaterialId.ingot: 2},
          gold: 500,
          skills: {
            ...untrainedSkills,
            SkillId.blacksmith: SkillState(xp: xpToNext(0) - 1),
          },
        );
        final bloc = await _openRoom(tester, const ForgeScreen(), leveling);
        await _enterForgeRoute(tester, 'forge-route-temper');

        // act
        await tester.tap(find.widgetWithText(TextButton, 'Temper'));
        await tester.pumpAndSettle();

        // assert - read the bloc's own winning sentence off the forge
        // screen rather than re-deriving or hard-coding it
        expect(bloc.state.profile.skills[SkillId.blacksmith]!.level, 1);
        final sentence = bloc.state.notice!.sentence;
        expect(find.text('— $sentence.'), findsOneWidget);
      },
    );

    testWidgets('offers no potion for the bench at all', (tester) async {
      // arrange
      final profile = _hero(
        inventory: [_gear('kit-2', healingPotion)],
        materials: const {MaterialId.ingot: 9},
        gold: 500,
      );

      // act
      await _openRoom(tester, const ForgeScreen(), profile);
      await _enterForgeRoute(tester, 'forge-route-temper');

      // assert - only steel reaches the bench, so the refusal never has to be
      // read on this screen
      expect(find.text('You have no steel for the bench.'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Temper'), findsNothing);
    });

    testWidgets('the notice sits above the materials block', (tester) async {
      // arrange
      final bloc = TownBloc(
        profile: _hero(),
        notice: const SentenceNotice('the fire is banked'),
      );

      // act
      await _openWithBloc(tester, bloc, const ForgeScreen());
      await _enterForgeRoute(tester, 'forge-route-smelt');

      // assert - the notice reads directly under the purse, above the
      // materials heading, matching every other room
      expect(
        tester.getTopLeft(find.byType(Notice)).dy,
        lessThan(tester.getTopLeft(find.text('MATERIALS')).dy),
      );
    });

    testWidgets('the smelting console keeps materials before its own work', (
      tester,
    ) async {
      final bloc = TownBloc(
        profile: _hero(materials: const {MaterialId.ore: 4}),
        notice: const SentenceNotice('the fire is banked'),
      );

      await _openWithBloc(tester, bloc, const ForgeScreen());
      await _enterForgeRoute(tester, 'forge-route-smelt');

      final ys = <double>[
        tester.getTopLeft(find.byType(Purse)).dy,
        tester.getTopLeft(find.byType(Notice)).dy,
        tester.getTopLeft(find.text('MATERIALS')).dy,
        tester.getTopLeft(find.byType(MaterialRows)).dy,
        tester.getTopLeft(find.text('SMELTING')).dy,
        tester.getTopLeft(find.textContaining('ore makes 1 ingot')).dy,
        tester.getTopLeft(find.byType(CountStepper)).dy,
        tester.getTopLeft(find.widgetWithText(FilledButton, 'Smelt')).dy,
        tester.getTopLeft(find.textContaining('ore is ready')).dy,
      ];
      for (var i = 1; i < ys.length; i++) {
        expect(ys[i], greaterThan(ys[i - 1]), reason: 'row $i out of order');
      }
      expect(find.byType(MaterialRows), findsOneWidget);
      expect(find.text('THE BENCH'), findsNothing);
    });

    testWidgets('the tempering console keeps materials before its bench work', (
      tester,
    ) async {
      final bloc = TownBloc(
        profile: _hero(
          equipment: {EquipSlot.chest: _gear('drop-2', mailHauberk)},
          inventory: [_gear('drop-1', ironSword)],
          materials: const {MaterialId.ingot: 2},
        ),
        notice: const SentenceNotice('the fire is banked'),
      );

      await _openWithBloc(tester, bloc, const ForgeScreen());
      await _enterForgeRoute(tester, 'forge-route-temper');

      final ys = <double>[
        tester.getTopLeft(find.byType(Purse)).dy,
        tester.getTopLeft(find.byType(Notice)).dy,
        tester.getTopLeft(find.text('MATERIALS')).dy,
        tester.getTopLeft(find.byType(MaterialRows)).dy,
        tester.getTopLeft(find.text('TEMPERING')).dy,
        tester.getTopLeft(find.text('THE BENCH')).dy,
        tester.getTopLeft(find.text('WORN STEEL')).dy,
        tester.getTopLeft(find.text('CARRIED STEEL')).dy,
      ];
      for (var i = 1; i < ys.length; i++) {
        expect(ys[i], greaterThan(ys[i - 1]), reason: 'row $i out of order');
      }
      expect(find.byType(MaterialRows), findsOneWidget);
    });

    testWidgets('a refused row shows its stat line, reason and next-tier price '
        'together', (tester) async {
      // arrange - four Blacksmith levels short of the next tier's gate
      final item = _gear('drop-1', ironSword, temper: 1);
      final gated = _hero(
        inventory: [item],
        materials: const {MaterialId.ingot: 9},
        gold: 500,
        blacksmith: 4,
      );

      // act
      await _openRoom(tester, const ForgeScreen(), gated);
      await _enterForgeRoute(tester, 'forge-route-temper');

      // assert - a refusal never hides the price of the tier it blocks
      expect(find.text(statLine(item)), findsOneWidget);
      expect(find.text('that needs Blacksmith 5'), findsOneWidget);
      expect(find.text('Next tier: 2 ingots.'), findsOneWidget);
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

    testWidgets('a batch loss wins the notice slot over a level-up', (
      tester,
    ) async {
      // arrange - one xp short of Herbcraft 10, and a batch whose first draw
      // fails
      final leveling = newProfile(worldSeed: 4).copyWith(
        materials: const {MaterialId.herb: 6},
        skills: {
          ...untrainedSkills,
          SkillId.herbcraft: SkillState(level: 9, xp: xpToNext(9) - 2),
        },
        craftRngState: _stateRolling(const [true, false]),
      );
      final bloc = await _openRoom(tester, const AlchemistScreen(), leveling);

      // act
      await tester.tap(find.text('+'));
      await tester.pump();
      await tester.tap(find.text('+'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Brew'));
      await tester.pumpAndSettle();

      // assert - Herbcraft still levels, but the widget shows the bloc's own
      // winning sentence rather than re-deriving the batch loss
      expect(bloc.state.profile.skills[SkillId.herbcraft]!.level, 10);
      final sentence = bloc.state.notice!.sentence;
      expect(find.text('— $sentence.'), findsOneWidget);
      expect(find.textContaining('Herbcraft rises to'), findsNothing);
    });

    testWidgets('lays out purse, notice, materials and brewing in that order', (
      tester,
    ) async {
      // arrange
      final bloc = TownBloc(
        profile: _hero(materials: const {MaterialId.herb: 6}),
        notice: const SentenceNotice('the pot is banked'),
      );

      // act
      await _openWithBloc(tester, bloc, const AlchemistScreen());

      // assert - top to bottom, exactly the locked shape
      final ys = <double>[
        tester.getTopLeft(find.byType(Purse)).dy,
        tester.getTopLeft(find.byType(Notice)).dy,
        tester.getTopLeft(find.text('MATERIALS')).dy,
        tester.getTopLeft(find.byType(MaterialRows)).dy,
        tester.getTopLeft(find.text('BREWING')).dy,
        tester
            .getTopLeft(find.textContaining('herbs make 1 healing potion'))
            .dy,
        tester.getTopLeft(find.textContaining('The shelf asks')).dy,
        tester.getTopLeft(find.byType(CountStepper)).dy,
        tester.getTopLeft(find.widgetWithText(FilledButton, 'Brew')).dy,
        tester.getTopLeft(find.textContaining('you have what it takes')).dy,
      ];
      for (var i = 1; i < ys.length; i++) {
        expect(ys[i], greaterThan(ys[i - 1]), reason: 'row $i out of order');
      }

      // assert - one shared material block, not a second private one
      expect(find.byType(MaterialRows), findsOneWidget);
      expect(find.text('MATERIALS'), findsOneWidget);
    });
  });
}
