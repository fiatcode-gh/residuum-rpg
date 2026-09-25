import 'package:flutter/material.dart';
import 'package:residuum_core/core.dart';

import '../art/art_assets.dart';
import '../style/tokens.dart';
import 'action_icon.dart';
import 'crawl_style.dart';
import 'crawl_surfaces.dart';
import 'game_bloc.dart';

/// One kind of potion carried, grouped by [Item.displayName] (PLAN.md G9):
/// [item] is the first of its kind the pack holds, and [count] is how many
/// answer to that name. Today the pack carries one kind at most — the
/// Healing Potion — but a second consumable would group the same way rather
/// than earning the Quick pop-up a second code path.
typedef PotionKind = ({Item item, int count});

/// Every potion kind the pack carries, in first-appearance order — the same
/// order the Quick pop-up lists them in. Books and gear never qualify:
/// [BaseItem.isPotion] is what "a drink" means throughout the crawl.
List<PotionKind> potionKinds(List<Item> inventory) {
  final order = <String>[];
  final byName = <String, PotionKind>{};
  for (final item in inventory) {
    if (!item.base.isPotion) continue;
    final name = item.displayName;
    final existing = byName[name];
    if (existing == null) {
      order.add(name);
      byName[name] = (item: item, count: 1);
    } else {
      byName[name] = (item: existing.item, count: existing.count + 1);
    }
  }
  return [for (final name in order) byName[name]!];
}

/// Opens the Quick pop-up anchored on the menu's own Quick slot (PLAN.md
/// G9): every potion kind carried, or the reason there is nothing to drink.
/// Reading `bloc.state` through a live [BlocBuilder] — rather than the
/// snapshot [potionKinds] was called with to dim the slot — means a pack
/// that changes while the pop-up is open (draining the last potion mid-turn)
/// never leaves a stale row behind.
Future<void> openQuickPopup(BuildContext anchor, GameBloc bloc) =>
    showCrawlPopup<void>(
      anchor,
      builder: (context) => _QuickPopupBody(bloc: bloc),
    );

class _QuickPopupBody extends StatelessWidget {
  const _QuickPopupBody({required this.bloc});

  final GameBloc bloc;

  @override
  Widget build(BuildContext context) {
    final kinds = potionKinds(bloc.state.game.inventory);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: crawlPanelPadding),
          child: Text('QUICK', style: displaySection),
        ),
        if (kinds.isEmpty)
          const Text('You carry nothing to drink.', style: textLineDim)
        else
          for (final kind in kinds) _QuickRow(kind: kind, bloc: bloc),
      ],
    );
  }
}

/// One carried kind: its mark, name and count, keyed by the item it would
/// drink first (PLAN.md G9). Tapping pops the pop-up, then dispatches —
/// the same order every crawl choice reads its state and acts in.
class _QuickRow extends StatelessWidget {
  const _QuickRow({required this.kind, required this.bloc});

  final PotionKind kind;
  final GameBloc bloc;

  @override
  Widget build(BuildContext context) {
    final item = kind.item;
    return InkWell(
      key: ValueKey('drink:${item.id}'),
      onTap: () {
        Navigator.of(context).pop();
        bloc.add(DrinkPressed(item.id));
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: crawlPopupRowMinHeight),
        child: Row(
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: ActionMarkView(ShippedMark(ActionIcon.potion), size: 22),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.displayName, style: textSlot),
                  Text(
                    '×${kind.count} · heals ${item.base.heal}',
                    style: monoSlotMeta,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
