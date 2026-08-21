import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:residuum_core/core.dart';

import '../game/inventory_screen.dart';
import '../game/item_presentation.dart';
import 'town_bloc.dart';
import 'town_style.dart';

/// The wardrobe: what the hero is wearing above, what it could wear below.
///
/// Gear bought at the merchant lands in the pack, and until now the only place
/// to put it on was a corridor. Dressing is a decision worth making somewhere
/// safe, and it costs no gold and no turn, so it is its own room rather than a
/// counter.
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
