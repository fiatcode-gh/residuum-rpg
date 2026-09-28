import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:residuum_core/core.dart';

import '../art/art_assets.dart';
import '../style/tokens.dart';
import 'action_icon.dart';
import 'crawl_style.dart';
import 'crawl_surfaces.dart';
import 'game_bloc.dart';

typedef PotionKind = ({Item item, int count});

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

Future<void> openQuickPopup(BuildContext anchor, GameBloc bloc) =>
    showCrawlPopup<void>(
      anchor,
      builder: (context) => _QuickPopupBody(bloc: bloc),
    );

class _QuickPopupBody extends StatelessWidget {
  const _QuickPopupBody({required this.bloc});

  final GameBloc bloc;

  @override
  Widget build(BuildContext context) => BlocBuilder<GameBloc, GameViewState>(
    bloc: bloc,
    builder: (context, state) {
      final kinds = potionKinds(state.game.inventory);
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
    },
  );
}

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
        for (final current in potionKinds(bloc.state.game.inventory)) {
          if (current.item.displayName == item.displayName) {
            bloc.add(DrinkPressed(current.item.id));
            return;
          }
        }
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
