import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../game/event_messages.dart' show skillName;
import '../game/inventory_screen.dart' show slotLabel;
import '../game/item_presentation.dart';
import 'town_bloc.dart';
import 'town_style.dart';

/// The hero, as the Pack reads them, at the camp fire.
///
/// **The character menu is the Pack's twin, not a new design.** One grammar
/// for hero state everywhere: the same sections in the same order, the same
/// marking column, the same dash for an empty slot. The only differences are
/// the driver — the town profile rather than a live crawl — and the absence of
/// a cast action, because there is no fight to spend a spell on here.
///
/// Everything is read off [TownViewState]'s profile, and nothing here decides
/// a rule: the numbers are the core's derivations, the refusals are the core's
/// own sentences, and the screen only lays them out. Nothing on this screen is
/// told apart by colour — the worn list is six named slots, an empty one is a
/// dash, rarity is a marking and a tier word, and the whole thing reads in
/// greyscale and aloud.
class CharacterScreen extends StatelessWidget {
  const CharacterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TownBloc>();
    return BlocBuilder<TownBloc, TownViewState>(
      builder: (context, state) {
        final profile = state.profile;
        final sections = packSections(profile.inventory);
        final known =
            [
              for (final id in profile.knownSpells)
                if (spellsById[id] case final Spell spell) spell,
            ]..sort((one, other) {
              final bySchool = one.school.index.compareTo(other.school.index);
              return bySchool != 0 ? bySchool : one.name.compareTo(other.name);
            });
        final (attackMin, attackMax) = heroAttack(
          profile.hero,
          profile.loadout,
        );
        return TownRoom(
          title: 'Character',
          children: [
            Notice(state.notice),
            _Stats(
              attackMin: attackMin,
              attackMax: attackMax,
              armor: heroArmor(profile.loadout),
              dodge: heroDodgePercent(profile.loadout),
              speed: heroSpeed(profile.hero, profile.loadout),
              hp: profile.hero.hp,
              maxHp: profile.maxHp,
              mana: heroMaxMana(profile.loadout),
            ),
            const Heading('Spells'),
            if (known.isEmpty)
              const NothingHere('You have not learned any spell yet.'),
            for (final spell in known) _SpellRow(spell: spell),
            const Heading('Worn'),
            for (final slot in EquipSlot.values)
              _WornRow(
                slot: slot,
                item: profile.equipment[slot],
                onTakeOff: () => bloc.add(TakeOffPressed(slot)),
              ),
            const Heading('Carried'),
            for (final section in PackSection.values) ...[
              Heading(section.title),
              if (sections[section]!.isEmpty) NothingHere(_nothingIn(section)),
              for (final stack in sections[section]!)
                _CarriedRow(
                  stack: stack,
                  worn: profile.equipment[stack.item.base.slot],
                  readReason: stack.item.base.isSpellBook
                      ? readRefusal(
                          profile.loadout,
                          profile.inventory,
                          profile.knownSpells,
                          spellsById,
                          stack.item.id,
                        )
                      : null,
                  onWear: () => bloc.add(WearPressed(stack.item.id)),
                  onRead: () => bloc.add(ReadBookPressed(stack.item.id)),
                ),
            ],
            const Heading('Materials'),
            MaterialRows(materials: state.materials),
            const Heading('Skills'),
            for (final skill in SkillId.values)
              _SkillRow(
                skill: skill,
                state: profile.skills[skill] ?? const SkillState(),
              ),
          ],
        );
      },
    );
  }

  static String _nothingIn(PackSection section) => switch (section) {
    PackSection.weapons => 'You are carrying nothing you could swing.',
    PackSection.armour => 'You are carrying nothing you could wear.',
    PackSection.potions => 'You are carrying nothing you could drink.',
    PackSection.books => 'You are carrying nothing to read.',
  };
}

/// The hero's numbers, read off the profile the way a delve start would.
class _Stats extends StatelessWidget {
  const _Stats({
    required this.attackMin,
    required this.attackMax,
    required this.armor,
    required this.dodge,
    required this.speed,
    required this.hp,
    required this.maxHp,
    required this.mana,
  });

  final int attackMin;
  final int attackMax;
  final int armor;
  final int dodge;
  final int speed;
  final int hp;
  final int maxHp;

  /// The pool the hero opens any run with — town has no current value, so the
  /// panel says what a fight would start from rather than inventing a half.
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
        Text('Armour   $armor', style: mono),
        Text('Dodge    $dodge%', style: mono),
        Text('Speed    $speed', style: mono),
        Text('Health   $hp/$maxHp', style: mono),
        Text('Mana     $mana', style: mono),
      ],
    ),
  );
}

/// One known spell: what it is and what it costs, with no cast offered.
///
/// The school is a marking and a word, never a colour, in the Pack's own row
/// grammar — read-only here, because a town has nothing to aim at.
class _SpellRow extends StatelessWidget {
  const _SpellRow({required this.spell});

  final Spell spell;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Text(spell.school.schoolMarking, style: mono),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(spell.name, style: mono),
              Text(
                '${spell.school.schoolWord} · ${spell.manaCost} mana',
                style: monoDim,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _WornRow extends StatelessWidget {
  const _WornRow({
    required this.slot,
    required this.item,
    required this.onTakeOff,
  });

  final EquipSlot slot;
  final Item? item;
  final VoidCallback onTakeOff;

  @override
  Widget build(BuildContext context) {
    final worn = item;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 88, child: Text(slotLabel(slot), style: monoDim)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(worn == null ? '—' : worn.displayName, style: mono),
                if (worn != null && statLine(worn).isNotEmpty)
                  Text(statLine(worn), style: monoDim),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 104,
            child: worn == null
                ? const SizedBox.shrink()
                : FilledButton(
                    onPressed: onTakeOff,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 10,
                      ),
                    ),
                    child: const Text(
                      'Take off',
                      maxLines: 1,
                      style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// One carried item in its section: what it is, and the one action town
/// offers on it.
///
/// A wearable is worn here, a book is read here, and a potion is a row with
/// nothing to press — drinking is a corridor's business, and inventing a town
/// event for it would be a new rule where the room is only a window. The row
/// grammar is the Pack's: marking, name, stat line, and what wearing would
/// change.
class _CarriedRow extends StatelessWidget {
  const _CarriedRow({
    required this.stack,
    required this.worn,
    required this.onWear,
    required this.onRead,
    this.readReason,
  });

  final ItemStack stack;
  final Item? worn;
  final VoidCallback onWear;
  final VoidCallback onRead;

  /// Why this book cannot be read, or null when it can.
  ///
  /// Null for everything that is not a book, and the caller is what makes it
  /// so — the same rule the Pack's carried row follows.
  final String? readReason;

  @override
  Widget build(BuildContext context) {
    final item = stack.item;
    final stats = statLine(item);
    final locked = readReason != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Text(
              item.rarity.marking,
              style: monoDim,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stack.label, style: mono),
                if (stats.isNotEmpty) Text(stats, style: monoDim),
                if (item.base.isSpellBook) Text(_teaches(item), style: monoDim),
                if (item.base.slot != null)
                  Text(deltaLine(wornDeltas(item, worn)), style: monoDim),
                if (locked) Text(readReason!, style: monoDim),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 104,
            child: switch (item) {
              _ when item.base.isSpellBook => FilledButton(
                onPressed: locked ? null : onRead,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 10,
                  ),
                ),
                child: const Text(
                  'Read',
                  maxLines: 1,
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
              _ when item.base.isEquippable => FilledButton(
                onPressed: onWear,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 10,
                  ),
                ),
                child: const Text(
                  'Wear',
                  maxLines: 1,
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
              _ => const SizedBox.shrink(),
            },
          ),
        ],
      ),
    );
  }

  static String _teaches(Item book) {
    final spell = spellOrNull(book.base.teaches!);
    if (spell == null) return 'teaches nothing this build knows';
    return '${spell.school.schoolMarking} ${spell.school.schoolWord} · '
        'teaches ${spell.name}';
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
          SizedBox(width: 88, child: Text(skillName(skill), style: mono)),
          SizedBox(width: 32, child: Text('${state.level}', style: mono)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress.clamp(0, 1),
                minHeight: 8,
                backgroundColor: rule,
                valueColor: const AlwaysStoppedAnimation(ink),
              ),
            ),
          ),
          SizedBox(
            width: 56,
            child: Text('  ${state.xp}/$cost', style: monoDim),
          ),
        ],
      ),
    );
  }
}
