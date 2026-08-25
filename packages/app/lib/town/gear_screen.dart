import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../game/inventory_screen.dart';
import '../game/item_presentation.dart';
import 'town_bloc.dart';
import 'town_style.dart';

/// The wardrobe: what the hero is wearing above, what it could wear below, and
/// the books it is carrying below that.
///
/// Gear bought at the merchant lands in the pack, and until now the only place
/// to put it on was a corridor. Dressing is a decision worth making somewhere
/// safe, and it costs no gold and no turn, so it is its own room rather than a
/// counter.
///
/// **Books are here for the same reason and one more.** This room used to build
/// its list from weapons and armour alone, so a book carried home was invisible
/// in town — the hero could see it in a corridor and not at the camp fire, which
/// is exactly backwards for a thing whose whole use is a quiet moment. Reading
/// costs no gold either; the merchant is elsewhere.
///
/// Nothing here is told apart by colour. The worn list is six slots in a fixed
/// order, each named in words, and an empty one is a dash. Every carried piece
/// carries its own numbers plus a comparison against what is in its slot, drawn
/// as an arrow shape and a signed number. The room reads in greyscale, and it
/// reads aloud.
class GearScreen extends StatelessWidget {
  const GearScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TownBloc>();
    return BlocBuilder<TownBloc, TownViewState>(
      builder: (context, state) {
        final equipment = state.profile.equipment;
        final sections = packSections(state.profile.inventory);
        final wearable = [
          ...sections[PackSection.weapons]!,
          ...sections[PackSection.armour]!,
        ];
        final books = sections[PackSection.books]!;
        return TownRoom(
          title: 'Gear',
          children: [
            Notice(state.notice),
            const Heading('Worn'),
            for (final slot in EquipSlot.values)
              _WornRow(
                slot: slot,
                item: equipment[slot],
                onTakeOff: () => bloc.add(TakeOffPressed(slot)),
              ),
            const Heading('In your pack'),
            if (wearable.isEmpty)
              const NothingHere('You are carrying nothing you could wear.'),
            for (final stack in wearable)
              _WearableRow(
                stack: stack,
                worn: equipment[stack.item.base.slot],
                onWear: () => bloc.add(WearPressed(stack.item.id)),
              ),
            const Heading('Books'),
            if (books.isEmpty)
              const NothingHere('You are carrying nothing to read.'),
            for (final stack in books)
              _BookRow(
                stack: stack,
                reason: readRefusal(
                  state.profile.loadout,
                  state.profile.inventory,
                  state.profile.knownSpells,
                  spellsById,
                  stack.item.id,
                ),
                onRead: () => bloc.add(ReadBookPressed(stack.item.id)),
              ),
          ],
        );
      },
    );
  }
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

class _WearableRow extends StatelessWidget {
  const _WearableRow({
    required this.stack,
    required this.worn,
    required this.onWear,
  });

  final ItemStack stack;
  final Item? worn;
  final VoidCallback onWear;

  @override
  Widget build(BuildContext context) {
    final item = stack.item;
    final stats = statLine(item);
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
                Text(deltaLine(wornDeltas(item, worn)), style: monoDim),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 104,
            child: FilledButton(
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
          ),
        ],
      ),
    );
  }
}

/// One carried book: what it teaches, and either Read or the reason it cannot
/// be.
///
/// Built in [_WearableRow]'s shape rather than through [ItemRow], because a
/// book's row has the same three-line grammar its neighbours do — a marking, a
/// name, and a line saying what taking the action would get you.
///
/// **A reason, never a greyed-out row.** "Needs Wrath 4" tells the player what
/// to go and do; a dimmed control tells them to guess.
class _BookRow extends StatelessWidget {
  const _BookRow({
    required this.stack,
    required this.reason,
    required this.onRead,
  });

  final ItemStack stack;

  /// Why this book cannot be read, or null when it can.
  final String? reason;

  final VoidCallback onRead;

  @override
  Widget build(BuildContext context) {
    final locked = reason != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Text(
              stack.item.rarity.marking,
              style: monoDim,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stack.label, style: mono),
                Text(_teaches(stack.item), style: monoDim),
                if (locked) Text(reason!, style: monoDim),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 104,
            child: FilledButton(
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
