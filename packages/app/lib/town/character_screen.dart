import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:residuum_core/core.dart';

import 'gear_screen.dart';
import 'pack_screen.dart';
import 'skills_screen.dart';
import 'spells_screen.dart';
import 'town_bloc.dart';
import 'town_style.dart';

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
            Text('Spells known    ${profile.knownSpells.length}', style: mono),
            Text(
              'Skills trained  $trained/${SkillId.values.length}',
              style: mono,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('character-route-gear'),
                  onPressed: () => _open(context, const GearScreen()),
                  child: const Text('Gear'),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('character-route-spells'),
                  onPressed: () => _open(context, const SpellsScreen()),
                  child: const Text('Spells'),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('character-route-skills'),
                  onPressed: () => _open(context, const SkillsScreen()),
                  child: const Text('Skills'),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('character-route-pack'),
                  onPressed: () => _open(context, const TownPackScreen()),
                  child: const Text('Pack'),
                ),
              ),
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
        Text('Attack   $attackMin-$attackMax', style: mono),
        Text('Armour   $armour', style: mono),
        Text('Dodge    $dodge%', style: mono),
        Text('Speed    $speed', style: mono),
        Text('Health   $hp/$maxHp', style: mono),
        Text('Mana     $mana', style: mono),
      ],
    ),
  );
}
