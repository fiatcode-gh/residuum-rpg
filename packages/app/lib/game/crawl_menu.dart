import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../art/art_assets.dart';
import '../style/tokens.dart';
import 'action_icon.dart';
import 'crawl_slot.dart';
import 'crawl_style.dart';
import 'crawl_surfaces.dart';
import 'game_bloc.dart';
import 'pack_screen.dart';
import 'quick_popup.dart';
import 'spells_popup.dart';

const crawlMenuKey = Key('crawl-menu');

class CrawlMenu extends StatelessWidget {
  const CrawlMenu({required this.state, required this.bloc, super.key});

  final GameViewState state;
  final GameBloc bloc;

  @override
  Widget build(BuildContext context) {
    final height = crawlMenuHeight * crawlScale(context);
    final kinds = potionKinds(state.game.inventory);
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: crawlGutter),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - crawlSlotGap * 3) / 4;
            return Row(
              children: [
                _MenuSlot(
                  id: 'menu-quests',
                  label: 'Quests',
                  mark: const FontMark(Icons.assignment),
                  dimmed: true,
                  width: width,
                  height: height,
                  onOpen: _openQuestsPopup,
                ),
                const SizedBox(width: crawlSlotGap),
                _MenuSlot(
                  id: 'menu-spells',
                  label: 'Spells',
                  mark: const FontMark(Icons.auto_awesome),
                  dimmed: state.knownSpells.isEmpty,
                  armed: state.armedSpellId != null,
                  width: width,
                  height: height,
                  onOpen: (anchor) => openSpellsPopup(anchor, bloc),
                ),
                const SizedBox(width: crawlSlotGap),
                _MenuSlot(
                  id: 'menu-quick',
                  label: 'Quick',
                  mark: const ShippedMark(ActionIcon.potion),
                  dimmed: kinds.isEmpty,
                  width: width,
                  height: height,
                  onOpen: (anchor) => openQuickPopup(anchor, bloc),
                ),
                const SizedBox(width: crawlSlotGap),
                _MenuSlot(
                  id: 'menu-hero',
                  label: 'Hero',
                  mark: const FontMark(Icons.person),
                  width: width,
                  height: height,
                  onOpen: (anchor) => Navigator.of(anchor).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BlocProvider.value(
                        value: bloc,
                        child: const CrawlPackScreen(),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MenuSlot extends StatelessWidget {
  const _MenuSlot({
    required this.id,
    required this.label,
    required this.mark,
    required this.width,
    required this.height,
    required this.onOpen,
    this.dimmed = false,
    this.armed = false,
  });

  final String id;
  final String label;
  final ActionMark mark;
  final double width;
  final double height;
  final bool dimmed;
  final bool armed;
  final void Function(BuildContext anchor) onOpen;

  @override
  Widget build(BuildContext context) => Builder(
    builder: (anchorContext) => CrawlSlot(
      key: ValueKey(id),
      label: label,
      mark: mark,
      dimmed: dimmed,
      armed: armed,
      width: width,
      height: height,
      onPressed: () => onOpen(anchorContext),
    ),
  );
}

Future<void> _openQuestsPopup(BuildContext anchor) => showCrawlPopup<void>(
  anchor,
  builder: (context) => const Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: EdgeInsets.only(bottom: crawlPanelPadding),
        child: Text('QUESTS', style: displaySection),
      ),
      Text('Quests are coming soon.', style: textLineDim),
    ],
  ),
);
