import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/event_messages.dart' show skillName;
import 'package:residuum_app/notice/notice.dart';
import 'package:residuum_app/town/town_bloc.dart';
import 'package:residuum_app/town/town_screen.dart';
import 'package:residuum_app/world/world_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../support/phone.dart';

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

Item _item(String id, BaseItem base) =>
    Item(id: id, base: base, rarity: Rarity.common);

Profile _stocked() => _hero(
  inventory: [
    _item('sword-1', rustySword),
    _item('cap-1', leatherCap),
    _item('potion-1', healingPotion),
    _item('book-1', bookOfMend),
  ],
  equipment: {EquipSlot.chest: _item('jerkin-1', leatherJerkin)},
  knownSpells: {firebolt.id},
  materials: const {MaterialId.ore: 2},
  skills: {
    ...untrainedSkills,
    SkillId.wrath: const SkillState(level: 1, xp: 2),
  },
);

Future<TownBloc> _openCharacterDoor(
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
  await tester.tap(find.text('Character'));
  await tester.pumpAndSettle();
  return town;
}

Future<void> _tapRoute(WidgetTester tester, String key, String title) async {
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
  expect(find.text(title), findsOneWidget);
}

void main() {
  group('Town Character overview', () {
    testWidgets('shows only facts and four routes', (tester) async {
      // arrange
      await onAPhone(tester);
      final profile = _stocked();

      // act
      final town = await _openCharacterDoor(
        tester,
        profile,
        notice: const SentenceNotice('the forge speaks'),
      );
      addTearDown(town.close);

      // assert
      final (attackMin, attackMax) = heroAttack(profile.hero, profile.loadout);
      expect(find.text('Attack   $attackMin-$attackMax'), findsOneWidget);
      expect(
        find.text('Armour   ${heroArmor(profile.loadout)}'),
        findsOneWidget,
      );
      expect(
        find.text('Dodge    ${heroDodgePercent(profile.loadout)}%'),
        findsOneWidget,
      );
      expect(
        find.text('Speed    ${heroSpeed(profile.hero, profile.loadout)}'),
        findsOneWidget,
      );
      expect(
        find.text('Health   ${profile.hero.hp}/${profile.maxHp}'),
        findsOneWidget,
      );
      expect(
        find.text('Mana     ${heroMaxMana(profile.loadout)}'),
        findsOneWidget,
      );
      expect(find.text('Spells known    1'), findsOneWidget);
      expect(
        find.text('Skills trained  1/${SkillId.values.length}'),
        findsOneWidget,
      );
      expect(find.byType(TabBar), findsNothing);
      for (final key in const [
        'character-route-gear',
        'character-route-spells',
        'character-route-skills',
        'character-route-pack',
      ]) {
        expect(find.byKey(Key(key)), findsOneWidget);
      }
      expect(find.textContaining('Rusty Sword'), findsNothing);
      expect(find.textContaining('Leather Jerkin'), findsNothing);
      expect(find.text('Firebolt'), findsNothing);
      expect(find.text('Ore'), findsNothing);
      expect(find.text('Wrath'), findsNothing);
      expect(find.textContaining('forge speaks'), findsNothing);
    });

    testWidgets('routes are presentation-only and retain bloc identity', (
      tester,
    ) async {
      // arrange
      await onAPhone(tester);
      final town = await _openCharacterDoor(tester, _stocked());
      addTearDown(town.close);
      final beforeState = town.state;
      final beforeProfile = town.state.profile;

      // act
      for (final route in const [
        ('character-route-gear', 'Gear'),
        ('character-route-spells', 'Spells'),
        ('character-route-skills', 'Skills'),
        ('character-route-pack', 'Pack'),
      ]) {
        await _tapRoute(tester, route.$1, route.$2);
        expect(find.textContaining('forge speaks'), findsNothing);
        await tester.pageBack();
        await tester.pumpAndSettle();
      }

      // assert
      expect(town.state, same(beforeState));
      expect(town.state.profile, same(beforeProfile));
    });
  });

  group('Town Gear route', () {
    testWidgets('shows slots in order and takes off a worn item', (
      tester,
    ) async {
      // arrange
      await onAPhone(tester);
      final town = await _openCharacterDoor(tester, _stocked());
      addTearDown(town.close);
      await _tapRoute(tester, 'character-route-gear', 'Gear');

      // act
      for (final slot in EquipSlot.values) {
        expect(find.byKey(Key('gear-slot-${slot.name}')), findsOneWidget);
      }
      await tester.tap(find.byKey(const Key('gear-take-off-chest')));
      await tester.pumpAndSettle();

      // assert
      expect(town.state.profile.equipment[EquipSlot.chest], isNull);
      expect(
        town.state.profile.inventory.map((item) => item.id),
        contains('jerkin-1'),
      );
      expect(find.text('—'), findsWidgets);
    });

    testWidgets('shows the exact full-pack refusal and disables Take off', (
      tester,
    ) async {
      // arrange
      await onAPhone(tester);
      final carried = [
        for (var index = 0; index < inventoryCap; index++)
          _item('carried-$index', healingPotion),
      ];
      final profile = _hero(
        inventory: carried,
        equipment: {EquipSlot.chest: _item('jerkin-1', leatherJerkin)},
      );
      final town = await _openCharacterDoor(
        tester,
        profile,
        notice: const SentenceNotice('the forge speaks'),
      );
      addTearDown(town.close);
      await _tapRoute(tester, 'character-route-gear', 'Gear');

      // act
      final takeOff = tester.widget<FilledButton>(
        find.byKey(const Key('gear-take-off-chest')),
      );

      // assert
      expect(find.text('your hands are too full to stow it'), findsOneWidget);
      expect(takeOff.onPressed, isNull);
      expect(town.state.profile, same(profile));
      expect(find.textContaining('forge speaks'), findsNothing);
    });
  });

  group('Town Spells route', () {
    testWidgets('orders every known spell and offers no action', (
      tester,
    ) async {
      // arrange
      await onAPhone(tester);
      final town = await _openCharacterDoor(
        tester,
        _hero(knownSpells: {bind.id, mend.id, firebolt.id}),
      );
      addTearDown(town.close);

      // act
      await _tapRoute(tester, 'character-route-spells', 'Spells');

      // assert
      expect(find.text('Firebolt'), findsOneWidget);
      expect(find.text('Mend'), findsOneWidget);
      expect(find.text('Bind'), findsOneWidget);
      expect(
        find.textContaining('Wrath · 2 mana · 2-4 fire △'),
        findsOneWidget,
      );
      expect(find.textContaining('Mending · 3 mana · heals 8'), findsOneWidget);
      expect(
        find.textContaining('Binding · 3 mana · holds 3 turns'),
        findsOneWidget,
      );
      expect(find.text('Cast'), findsNothing);
      expect(find.textContaining('unavailable'), findsNothing);
      expect(find.textContaining('locked'), findsNothing);
    });

    testWidgets('shows the exact empty sentence', (tester) async {
      // arrange
      await onAPhone(tester);
      final town = await _openCharacterDoor(tester, _hero());
      addTearDown(town.close);

      // act
      await _tapRoute(tester, 'character-route-spells', 'Spells');

      // assert
      expect(find.text('You have not learned any spell yet.'), findsOneWidget);
    });
  });

  testWidgets('Town Skills lists every skill and trained progression', (
    tester,
  ) async {
    // arrange
    await onAPhone(tester);
    final town = await _openCharacterDoor(tester, _stocked());
    addTearDown(town.close);

    // act
    await _tapRoute(tester, 'character-route-skills', 'Skills');
    for (final skill in SkillId.values) {
      await tester.scrollUntilVisible(
        find.byKey(Key('skill-${skill.name}')),
        100,
      );
      await tester.pumpAndSettle();
    }

    // assert
    for (final skill in SkillId.values) {
      expect(find.byKey(Key('skill-${skill.name}')), findsOneWidget);
      expect(find.text(skillName(skill)), findsOneWidget);
    }
    expect(find.text('1'), findsWidgets);
    expect(find.text('2/6'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
