import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:residuum_core/core.dart';

import '../style/surfaces.dart';
import '../style/tokens.dart';
import 'gear_screen.dart';
import 'pack_screen.dart';
import 'skills_screen.dart';
import 'spells_screen.dart';
import 'town_bloc.dart';
import 'town_style.dart';

/// A handle onto the character screen's health meter for tests: the row
/// itself carries no other stable identity now that it is a
/// [ResourceMeter] rather than a pinned string.
const characterHealthMeterKey = Key('character-health-meter');

class CharacterScreen extends StatelessWidget {
  const CharacterScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TownBloc, TownViewState>(
      builder: (context, state) {
        final profile = state.profile;
        final (attackMin, attackMax) = heroAttack(
          profile.hero,
          profile.loadout,
        );
        final trained = SkillId.values
            .where((id) => (profile.skills[id]?.level ?? 0) > 0)
            .length;
        return TownRoom(
          title: 'Character',
          children: [
            _Stats(
              attackMin: attackMin,
              attackMax: attackMax,
              armour: heroArmor(profile.loadout),
              dodge: heroDodgePercent(profile.loadout),
              speed: heroSpeed(profile.hero, profile.loadout),
              hp: profile.hero.hp,
              maxHp: profile.maxHp,
              mana: heroMaxMana(profile.loadout),
            ),
            const SizedBox(height: 12),
            LabelledValue(
              label: 'Spells known',
              value: '${profile.knownSpells.length}',
            ),
            LabelledValue(
              label: 'Skills trained',
              value: '$trained/${SkillId.values.length}',
            ),
            const SizedBox(height: 12),
            FramedRow(
              key: const Key('character-route-gear'),
              title: 'Gear',
              medallionKey: const Key('character-route-gear-medallion'),
              onPressed: () => _open(context, const GearScreen()),
            ),
            FramedRow(
              key: const Key('character-route-spells'),
              title: 'Spells',
              medallionKey: const Key('character-route-spells-medallion'),
              onPressed: () => _open(context, const SpellsScreen()),
            ),
            FramedRow(
              key: const Key('character-route-skills'),
              title: 'Skills',
              medallionKey: const Key('character-route-skills-medallion'),
              onPressed: () => _open(context, const SkillsScreen()),
            ),
            FramedRow(
              key: const Key('character-route-pack'),
              title: 'Pack',
              medallionKey: const Key('character-route-pack-medallion'),
              onPressed: () => _open(context, const TownPackScreen()),
            ),
          ],
        );
      },
    );
  }

  static void _open(BuildContext context, Widget screen) {
    final town = context.read<TownBloc>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(value: town, child: screen),
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({
    required this.attackMin,
    required this.attackMax,
    required this.armour,
    required this.dodge,
    required this.speed,
    required this.hp,
    required this.maxHp,
    required this.mana,
  });
  final int attackMin;
  final int attackMax;
  final int armour;
  final int dodge;
  final int speed;
  final int hp;
  final int maxHp;
  final int mana;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: panel,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabelledValue(label: 'Attack', value: '$attackMin-$attackMax'),
        LabelledValue(label: 'Armour', value: '$armour'),
        LabelledValue(label: 'Dodge', value: '$dodge%'),
        LabelledValue(label: 'Speed', value: '$speed'),
        ResourceMeter(
          key: characterHealthMeterKey,
          label: 'Health',
          value: hp,
          ceiling: maxHp,
          tint: MeterTint.health,
        ),
        LabelledValue(label: 'Mana capacity', value: '$mana'),
      ],
    ),
  );
}
