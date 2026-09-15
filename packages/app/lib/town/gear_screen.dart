import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:residuum_core/core.dart';

import '../game/item_presentation.dart';
import 'town_bloc.dart';
import 'town_style.dart';

class GearScreen extends StatelessWidget {
  const GearScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TownBloc>();
    return BlocBuilder<TownBloc, TownViewState>(
      builder: (context, state) => TownRoom(
        title: 'Gear',
        children: [
          for (final slot in EquipSlot.values)
            _GearRow(
              key: Key('gear-slot-${slot.name}'),
              slot: slot,
              item: state.profile.equipment[slot],
              refusal: state.profile.equipment[slot] == null
                  ? null
                  : state.takeOffReason(slot),
              onTakeOff: () => bloc.add(TakeOffPressed(slot)),
            ),
        ],
      ),
    );
  }
}

class _GearRow extends StatelessWidget {
  const _GearRow({
    required this.slot,
    required this.item,
    required this.refusal,
    required this.onTakeOff,
    super.key,
  });

  final EquipSlot slot;
  final Item? item;
  final String? refusal;
  final VoidCallback onTakeOff;

  @override
  Widget build(BuildContext context) {
    final worn = item;
    final stats = worn == null ? '' : statLine(worn);
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
                Text(worn?.displayName ?? '—', style: mono),
                if (stats.isNotEmpty) Text(stats, style: monoDim),
                if (refusal != null) Text(refusal!, style: monoDim),
              ],
            ),
          ),
          if (worn != null) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 104,
              child: FilledButton(
                key: Key('gear-take-off-${slot.name}'),
                onPressed: refusal == null ? onTakeOff : null,
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
        ],
      ),
    );
  }
}
