import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/event_messages.dart' show skillName;
import 'package:residuum_app/town/character_screen.dart';
import 'package:residuum_app/town/town_bloc.dart';
import 'package:residuum_app/world/world_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

/// A phone-sized viewport, which is where the screen has to read.
const Size _phone = Size(360, 640);

Profile _hero({
  List<Item> inventory = const [],
  Equipment equipment = const {},
  Set<String> knownSpells = const {},
  Map<MaterialId, int> materials = const {},
  Map<SkillId, SkillState> skills = untrainedSkills,
}) => newProfile(worldSeed: 4).copyWith(
  inventory: inventory,
  equipment: equipment,
  knownSpells: knownSpells,
  materials: materials,
  skills: skills,
  gold: 25,
);

/// A hero carrying one of everything the pack reads: a weapon, an armour
/// piece, a potion and a book, with a chest piece worn, one spell learned,
/// one material gathered, and one trained school.
Profile _stocked() => _hero(
  inventory: [
    Item(id: 'sword-1', base: rustySword, rarity: Rarity.common),
    Item(id: 'cap-1', base: leatherCap, rarity: Rarity.fine),
    Item(id: 'potion-1', base: healingPotion, rarity: Rarity.common),
    Item(id: 'book-1', base: bookOfMend, rarity: Rarity.common),
  ],
  equipment: {
    EquipSlot.chest: Item(
      id: 'jerkin-1',
      base: leatherJerkin,
      rarity: Rarity.common,
    ),
  },
  knownSpells: {firebolt.id},
  materials: const {MaterialId.ore: 2},
  skills: {
    ...untrainedSkills,
    SkillId.wrath: const SkillState(level: 1, xp: 2),
  },
);

/// The character room, under a real town bloc and a real world bloc.
Future<TownBloc> _openRoom(WidgetTester tester, Profile profile) async {
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
        child: const CharacterScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return town;
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 100);
  await tester.pumpAndSettle();
}

void main() {
  group('the town character room', () {
    testWidgets('shows the derived stats the town knows', (tester) async {
      // arrange
      tester.view.physicalSize = _phone;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // act
      await _openRoom(tester, _stocked());

      // assert — the Pack's stats panel, read off the profile: the attack the
      // body and the worn gear give, not what the pack is carrying
      for (final label in ['Attack', 'Armour', 'Dodge', 'Speed', 'Health']) {
        expect(find.textContaining(label), findsWidgets, reason: label);
      }
    });

    testWidgets('shows the known spells with their school, never a cast', (
      tester,
    ) async {
      // arrange
      tester.view.physicalSize = _phone;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // act
      await _openRoom(tester, _stocked());

      // assert — the school is a marking and a word, and there is no casting
      // in town: the row names the spell and its school and stops there
      await _scrollTo(tester, find.textContaining('Wrath'));
      expect(find.text('Firebolt'), findsWidgets);
      expect(find.textContaining('Wrath'), findsWidgets);
      expect(find.text('Cast'), findsNothing);
    });

    testWidgets('shows the six worn slots in the pack order', (tester) async {
      // arrange
      tester.view.physicalSize = _phone;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // act
      await _openRoom(tester, _stocked());

      // assert
      for (final slot in [
        'main hand',
        'off hand',
        'head',
        'chest',
        'hands',
        'feet',
      ]) {
        await _scrollTo(tester, find.text(slot));
        expect(find.text(slot), findsOneWidget, reason: slot);
      }
      expect(
        find.textContaining('Leather Jerkin', skipOffstage: false),
        findsWidgets,
      );
    });

    testWidgets('carries the whole pack in the pack four sections', (
      tester,
    ) async {
      // arrange
      tester.view.physicalSize = _phone;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // act
      await _openRoom(tester, _stocked());

      // assert — every section present even where empty, in the fixed order,
      // asserted downward because the scroll helper only drags one way
      await _scrollTo(tester, find.text('WEAPONS'));
      expect(
        find.textContaining('Rusty Sword', skipOffstage: false),
        findsWidgets,
      );
      await _scrollTo(tester, find.text('ARMOUR'));
      expect(find.text('ARMOUR'), findsWidgets);
      await _scrollTo(tester, find.textContaining('Leather Cap'));
      expect(
        find.textContaining('Leather Cap', skipOffstage: false),
        findsWidgets,
      );
      await _scrollTo(tester, find.text('POTIONS'));
      expect(find.text('POTIONS'), findsWidgets);
      await _scrollTo(tester, find.textContaining('Healing Potion'));
      expect(
        find.textContaining('Healing Potion', skipOffstage: false),
        findsWidgets,
      );
      await _scrollTo(tester, find.text('BOOKS'));
      expect(find.text('BOOKS'), findsWidgets);
      await _scrollTo(tester, find.textContaining('Book of Mend'));
      expect(
        find.textContaining('Book of Mend', skipOffstage: false),
        findsWidgets,
      );
    });

    testWidgets('gives every material a row even at zero', (tester) async {
      // arrange
      tester.view.physicalSize = _phone;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // act
      await _openRoom(tester, _stocked());

      // assert
      await _scrollTo(tester, find.text('Ore'));
      expect(find.text('Ore'), findsOneWidget);
      expect(find.text('2'), findsWidgets);
      await _scrollTo(tester, find.text('Ingot'));
      expect(find.text('Ingot'), findsOneWidget);
      await _scrollTo(tester, find.text('Herb'));
      expect(find.text('Herb'), findsOneWidget);
    });

    testWidgets('shows every skill with its level', (tester) async {
      // arrange
      tester.view.physicalSize = _phone;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // act
      await _openRoom(tester, _stocked());

      // assert
      for (final skill in SkillId.values) {
        await _scrollTo(tester, find.text(skillName(skill)));
        expect(find.text(skillName(skill)), findsWidgets, reason: skill.name);
      }
      await _scrollTo(tester, find.text('2'));
      expect(find.text('1'), findsWidgets);
    });

    testWidgets('wears a carried piece through WearPressed', (tester) async {
      // arrange
      tester.view.physicalSize = _phone;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final town = await _openRoom(
        tester,
        _hero(
          inventory: [Item(id: 'cap-1', base: leatherCap, rarity: Rarity.fine)],
        ),
      );
      expect(town.state.profile.equipment[EquipSlot.head], isNull);

      // act
      await _scrollTo(tester, find.text('Wear'));
      await tester.tap(find.text('Wear').first);
      await tester.pumpAndSettle();

      // assert
      expect(town.state.profile.equipment[EquipSlot.head], isNotNull);
      expect(
        town.state.profile.inventory.map((item) => item.id),
        isNot(contains('cap-1')),
      );
    });

    testWidgets('takes a worn piece off through TakeOffPressed', (
      tester,
    ) async {
      // arrange
      tester.view.physicalSize = _phone;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final town = await _openRoom(tester, _stocked());
      expect(town.state.profile.equipment[EquipSlot.chest], isNotNull);

      // act
      await _scrollTo(tester, find.text('Take off'));
      await tester.tap(find.text('Take off').first);
      await tester.pumpAndSettle();

      // assert
      expect(town.state.profile.equipment[EquipSlot.chest], isNull);
      expect(
        town.state.profile.inventory.map((item) => item.id),
        contains('jerkin-1'),
      );
    });

    testWidgets('reads a carried book through ReadBookPressed', (tester) async {
      // arrange
      tester.view.physicalSize = _phone;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final town = await _openRoom(tester, _stocked());
      expect(town.state.profile.knownSpells, isNot(contains('mend')));

      // act
      await _scrollTo(tester, find.text('Read'));
      await tester.tap(find.text('Read').first);
      await tester.pumpAndSettle();

      // assert
      expect(town.state.profile.knownSpells, contains('mend'));
      expect(
        town.state.profile.inventory.map((item) => item.id),
        isNot(contains('book-1')),
      );
    });
  });
}
