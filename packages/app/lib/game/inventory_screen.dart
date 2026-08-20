import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:residuum_core/core.dart';

import 'event_messages.dart';
import 'game_bloc.dart';

const _ink = Color(0xFFE6EAF0);
const _dim = Color(0xFF8A919E);
const _panel = Color(0xFF15181F);
const _rule = Color(0xFF2A2E38);
const _mono = TextStyle(fontFamily: 'monospace', fontSize: 13, color: _ink);

/// The pack, the six slots, the derived stats and the four skills.
///
/// Nothing on this screen is told apart by colour. Rarity is the tier word in
/// the item's own name plus a marking column; an empty slot is a dash; skill
/// progress is a bar's length and a number. The whole screen reads in
/// greyscale, which is the standing rule and not a preference.
class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Pack', style: TextStyle(fontFamily: 'monospace')),
      backgroundColor: _panel,
      foregroundColor: _ink,
    ),
    body: BlocBuilder<GameBloc, GameViewState>(
      builder: (context, state) => ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _DerivedStats(state: state),
          const _Heading('Worn'),
          for (final slot in EquipSlot.values)
            _SlotRow(slot: slot, item: state.game.equipment[slot]),
          const _Heading('Carried'),
          if (state.game.inventory.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Nothing.',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: _dim,
                ),
              ),
            ),
          for (final item in state.game.inventory) _CarriedRow(item: item),
          const _Heading('Skills'),
          for (final skill in SkillId.values)
            _SkillRow(
              skill: skill,
              state: state.game.skills[skill] ?? const SkillState(),
            ),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            letterSpacing: 2,
            color: _dim,
          ),
        ),
        const Divider(color: _rule, height: 9),
      ],
    ),
  );
}

class _DerivedStats extends StatelessWidget {
  const _DerivedStats({required this.state});

  final GameViewState state;

  @override
  Widget build(BuildContext context) {
    final (min, max) = state.attack;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Attack   $min-$max', style: _mono),
          Text('Armour   ${state.armor}', style: _mono),
          Text('Dodge    ${state.dodgePercent}%', style: _mono),
          Text('Speed    ${state.speed}', style: _mono),
          Text('Health   ${state.game.hero.hp}/${state.maxHp}', style: _mono),
        ],
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({required this.slot, required this.item});

  final EquipSlot slot;
  final Item? item;

  @override
  Widget build(BuildContext context) {
    final worn = item;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(
              _slotLabel(slot),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: _dim,
              ),
            ),
          ),
          Expanded(
            child: Text(
              worn == null ? '—' : worn.displayName,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: worn == null ? _dim : _ink,
              ),
            ),
          ),
          if (worn != null)
            TextButton(
              onPressed: () =>
                  context.read<GameBloc>().add(UnequipPressed(slot)),
              child: const Text(
                'Take off',
                style: TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  static String _slotLabel(EquipSlot slot) => switch (slot) {
    EquipSlot.mainHand => 'main hand',
    EquipSlot.offHand => 'off hand',
    EquipSlot.head => 'head',
    EquipSlot.chest => 'chest',
    EquipSlot.hands => 'hands',
    EquipSlot.feet => 'feet',
  };
}

class _CarriedRow extends StatelessWidget {
  const _CarriedRow({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<GameBloc>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              item.rarity.marking,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: _ink,
              ),
            ),
          ),
          Expanded(child: Text(item.displayName, style: _mono)),
          if (item.base.isPotion)
            TextButton(
              onPressed: () => bloc.add(DrinkPressed(item.id)),
              child: const Text(
                'Drink',
                style: TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            )
          else if (item.base.isEquippable)
            TextButton(
              onPressed: () => bloc.add(EquipPressed(item.id)),
              child: const Text(
                'Wear',
                style: TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          TextButton(
            onPressed: () => bloc.add(DropPressed(item.id)),
            child: const Text(
              'Drop',
              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillRow extends StatelessWidget {
  const _SkillRow({required this.skill, required this.state});

  final SkillId skill;
  final SkillState state;

  @override
  Widget build(BuildContext context) {
    final cost = xpToNext(state.level);
    final progress = cost == 0 ? 0.0 : state.xp / cost;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 88, child: Text(skillName(skill), style: _mono)),
          SizedBox(width: 32, child: Text('${state.level}', style: _mono)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress.clamp(0, 1),
                minHeight: 8,
                backgroundColor: _rule,
                valueColor: const AlwaysStoppedAnimation(_ink),
              ),
            ),
          ),
          SizedBox(
            width: 56,
            child: Text(
              '  ${state.xp}/$cost',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: _dim,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
