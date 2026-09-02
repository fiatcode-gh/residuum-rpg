import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:residuum_core/core.dart';

import 'event_messages.dart';
import 'game_bloc.dart';
import 'item_presentation.dart';
import 'spell_row.dart';

const _ink = Color(0xFFE6EAF0);
const _dim = Color(0xFF8A919E);
const _panel = Color(0xFF15181F);
const _rule = Color(0xFF2A2E38);
const _mono = TextStyle(fontFamily: 'monospace', fontSize: 13, color: _ink);
const _monoDim = TextStyle(fontFamily: 'monospace', fontSize: 11, color: _dim);

/// The pack, the six slots, the derived stats, the spells and the nine skills.
///
/// Nothing on this screen is told apart by colour. Rarity is the tier word in
/// the item's own name plus a marking column; an empty slot is a dash; skill
/// progress is a bar's length and a number. What an item does is a line of
/// labelled signed numbers, and what wearing it would change is an arrow shape
/// plus a signed number per stat. The whole screen reads in greyscale, which is
/// the standing rule and not a preference.
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
      builder: (context, state) {
        final sections = packSections(state.game.inventory);
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          children: [
            _DerivedStats(state: state),
            if (state.knownSpells.isNotEmpty) ...[
              const _Heading('Spells'),
              for (final spell in state.knownSpells)
                SpellRow(
                  spell: spell,
                  style: _mono,
                  dimStyle: _monoDim,
                  detail: effectOf(spell),
                  reason: state.castRefusal(spell),
                  trailing: TextButton(
                    onPressed: state.castRefusal(spell) == null
                        ? () => context.read<GameBloc>().add(
                            CastPressed(spell.id),
                          )
                        : null,
                    child: const Text(
                      'Cast',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                ),
            ],
            const _Heading('Worn'),
            for (final slot in EquipSlot.values)
              _SlotRow(slot: slot, item: state.game.equipment[slot]),
            if (state.game.inventory.isEmpty) ...[
              const _Heading('Carried'),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Nothing.', style: _mono),
              ),
            ],
            for (final section in PackSection.values)
              if (sections[section]!.isNotEmpty) ...[
                _Heading(section.title),
                for (final stack in sections[section]!)
                  _CarriedRow(
                    stack: stack,
                    equipment: state.game.equipment,
                    readReason: stack.item.base.isSpellBook
                        ? state.readRefusalFor(stack.item.id)
                        : null,
                  ),
              ],
            const _Heading('Materials'),
            for (final entry in state.materials.entries)
              _MaterialRow(material: entry.key, count: entry.value),
            const _Heading('Skills'),
            for (final skill in SkillId.values)
              _SkillRow(
                skill: skill,
                state: state.game.skills[skill] ?? const SkillState(),
              ),
            const SizedBox(height: 24),
          ],
        );
      },
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
          Text('Mana     ${state.mana}/${state.maxMana}', style: _mono),
          if (state.warded > 0)
            Text('Ward     ${state.warded} held', style: _mono),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              slotLabel(slot),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: _dim,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  worn == null ? '—' : worn.displayName,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: worn == null ? _dim : _ink,
                  ),
                ),
                if (worn != null && statLine(worn).isNotEmpty)
                  Text(statLine(worn), style: _monoDim),
              ],
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
}

/// What the six slots are called, in the player's words rather than Dart's.
String slotLabel(EquipSlot slot) => switch (slot) {
  EquipSlot.mainHand => 'main hand',
  EquipSlot.offHand => 'off hand',
  EquipSlot.head => 'head',
  EquipSlot.chest => 'chest',
  EquipSlot.hands => 'hands',
  EquipSlot.feet => 'feet',
};

class _CarriedRow extends StatelessWidget {
  const _CarriedRow({
    required this.stack,
    required this.equipment,
    this.readReason,
  });

  final ItemStack stack;
  final Equipment equipment;

  /// Why this book cannot be read, or null when it can.
  ///
  /// **Null for everything that is not a book**, and the caller is what makes it
  /// so. Asking the shared rule about a potion gets a perfectly true sentence —
  /// "Healing Potion is not something to read" — and printing it under a Drink
  /// button is nonsense the player has to work past. A refusal only belongs on a
  /// row whose action it refuses.
  final String? readReason;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<GameBloc>();
    final item = stack.item;
    final slot = item.base.slot;
    final stats = statLine(item);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 28, child: Text(item.rarity.marking, style: _mono)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stack.label, style: _mono),
                if (stats.isNotEmpty) Text(stats, style: _monoDim),
                if (readReason != null) Text(readReason!, style: _monoDim),
                if (slot != null)
                  Text(
                    deltaLine(wornDeltas(item, equipment[slot])),
                    style: _monoDim,
                  ),
              ],
            ),
          ),
          if (item.base.isPotion)
            TextButton(
              onPressed: () => bloc.add(DrinkPressed(item.id)),
              child: const Text(
                'Drink',
                style: TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            )
          else if (item.base.isSpellBook)
            TextButton(
              onPressed: readReason == null
                  ? () => bloc.add(ReadPressed(item.id))
                  : null,
              child: const Text(
                'Read',
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

/// One material the hero is carrying: its mark, its word, and how much.
///
/// **Every material has a row even at zero**, which is [packSections]' rule: the
/// position of a row is information the player relies on, so a row that came and
/// went would move the two below it under a thumb already reaching for one.
///
/// The mark, the word and the number are three separate readings of the same
/// fact, so the panel is legible in greyscale, on a monochrome screen, and read
/// aloud.
class _MaterialRow extends StatelessWidget {
  const _MaterialRow({required this.material, required this.count});

  final MaterialId material;
  final int count;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(width: 28, child: Text(material.marking, style: _mono)),
        SizedBox(width: 84, child: Text(material.word, style: _mono)),
        Text('$count', style: count == 0 ? _monoDim : _mono),
      ],
    ),
  );
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
          const SizedBox(width: 8),
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
