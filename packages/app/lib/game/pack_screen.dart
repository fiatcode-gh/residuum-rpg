import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../style/surfaces.dart';
import '../style/tokens.dart'
    show
        armedFill,
        hairline,
        ink,
        panel,
        radius,
        raised,
        residuumTheme,
        rule,
        tapTarget,
        textBody,
        textLabel,
        textLabelStrong;
import '../town/town_style.dart' show Heading, MaterialRows, NothingHere;
import 'game_bloc.dart';
import 'item_presentation.dart';

class CrawlPackScreen extends StatelessWidget {
  const CrawlPackScreen({super.key});

  @override
  Widget build(BuildContext context) => Theme(
    data: residuumTheme,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Pack'),
        backgroundColor: panel,
        foregroundColor: ink,
      ),
      body: BlocBuilder<GameBloc, GameViewState>(
        builder: (context, state) {
          final bloc = context.read<GameBloc>();
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              PackContents(
                inventory: state.game.inventory,
                equipment: state.game.equipment,
                materials: state.materials,
                readRefusalFor: state.readRefusalFor,
                onDrink: (id) => bloc.add(DrinkPressed(id)),
                onRead: (id) => bloc.add(ReadPressed(id)),
                onWear: (id) => bloc.add(EquipPressed(id)),
                onDrop: (id) => bloc.add(DropPressed(id)),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    ),
  );
}

class PackContents extends StatefulWidget {
  const PackContents({
    required this.inventory,
    required this.equipment,
    required this.materials,
    required this.readRefusalFor,
    this.wearRefusalFor,
    this.onDrink,
    this.onRead,
    this.onWear,
    this.onDrop,
    this.showBookTeaching = false,
    super.key,
  });

  final List<Item> inventory;
  final Equipment equipment;
  final Map<MaterialId, int> materials;
  final String? Function(String itemId) readRefusalFor;
  final String? Function(String itemId)? wearRefusalFor;
  final ValueChanged<String>? onDrink;
  final ValueChanged<String>? onRead;
  final ValueChanged<String>? onWear;
  final ValueChanged<String>? onDrop;
  final bool showBookTeaching;

  @override
  State<PackContents> createState() => _PackContentsState();
}

enum _PackFilter {
  all('All'),
  weapons('Weapons', PackSection.weapons),
  armour('Armour', PackSection.armour),
  potions('Potions', PackSection.potions),
  books('Books', PackSection.books),
  materials('Materials');

  const _PackFilter(this.label, [this.section]);

  final String label;
  final PackSection? section;
}

class _PackFilterControl extends StatelessWidget {
  const _PackFilterControl({
    required this.label,
    required this.selected,
    required this.onPressed,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(
        color: selected ? ink : rule,
        width: selected ? 2 : hairline,
      ),
    );
    return Semantics(
      container: true,
      button: true,
      enabled: true,
      selected: selected,
      child: Material(
        color: selected ? armedFill : raised,
        shape: shape,
        child: InkWell(
          onTap: onPressed,
          customBorder: shape,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: tapTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: Text(
                  selected ? '✓ $label' : label,
                  style: selected ? textLabelStrong : textLabel,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PackContentsState extends State<PackContents> {
  _PackFilter _filter = _PackFilter.all;

  @override
  Widget build(BuildContext context) {
    final sections = packSections(widget.inventory);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 2,
          children: [
            for (final filter in _PackFilter.values)
              _PackFilterControl(
                key: Key('pack-filter-${filter.name}'),
                label: filter.label,
                selected: _filter == filter,
                onPressed: () {
                  if (filter == _filter) return;
                  setState(() => _filter = filter);
                },
              ),
          ],
        ),
        const SizedBox(height: 4),
        if (_filter == _PackFilter.all)
          ..._allSections(sections)
        else if (_filter == _PackFilter.materials)
          ..._materials()
        else
          ..._itemSection(sections, _filter.section!),
      ],
    );
  }

  List<Widget> _allSections(Map<PackSection, List<ItemStack>> sections) => [
    for (final section in PackSection.values)
      if (sections[section]!.isNotEmpty) ...[
        Heading(section.title),
        for (final stack in sections[section]!) _itemRow(stack),
      ],
    ..._materials(),
  ];

  List<Widget> _itemSection(
    Map<PackSection, List<ItemStack>> sections,
    PackSection section,
  ) => [
    Heading(section.title),
    if (sections[section]!.isEmpty)
      NothingHere(_emptySentence(section))
    else
      for (final stack in sections[section]!) _itemRow(stack),
  ];

  List<Widget> _materials() => [
    const Heading('Materials'),
    MaterialRows(materials: widget.materials),
  ];

  Widget _itemRow(ItemStack stack) => _PackItemRow(
    key: Key('pack-stack-${stack.item.id}'),
    stack: stack,
    equipment: widget.equipment,
    readRefusalFor: widget.readRefusalFor,
    wearRefusalFor: widget.wearRefusalFor,
    onDrink: widget.onDrink,
    onRead: widget.onRead,
    onWear: widget.onWear,
    onDrop: widget.onDrop,
    showBookTeaching: widget.showBookTeaching,
  );
}

String _emptySentence(PackSection section) => switch (section) {
  PackSection.weapons => 'You are carrying nothing you could swing.',
  PackSection.armour => 'You are carrying nothing you could wear.',
  PackSection.potions => 'You are carrying nothing you could drink.',
  PackSection.books => 'You are carrying nothing to read.',
};

class _PackItemRow extends StatelessWidget {
  const _PackItemRow({
    required this.stack,
    required this.equipment,
    required this.readRefusalFor,
    this.wearRefusalFor,
    this.onDrink,
    this.onRead,
    this.onWear,
    this.onDrop,
    required this.showBookTeaching,
    super.key,
  });

  final ItemStack stack;
  final Equipment equipment;
  final String? Function(String itemId) readRefusalFor;
  final String? Function(String itemId)? wearRefusalFor;
  final ValueChanged<String>? onDrink;
  final ValueChanged<String>? onRead;
  final ValueChanged<String>? onWear;
  final ValueChanged<String>? onDrop;
  final bool showBookTeaching;

  @override
  Widget build(BuildContext context) {
    final item = stack.item;
    final slot = item.base.slot;
    final readRefusal = item.base.isSpellBook ? readRefusalFor(item.id) : null;
    final wearRefusal = item.base.isEquippable && wearRefusalFor != null
        ? wearRefusalFor!(item.id)
        : null;
    final stats = statLine(item);
    String? refusal;
    Widget? primaryButton;
    if (item.base.isPotion && onDrink != null) {
      primaryButton = _actionButton(
        key: Key('pack-drink-${item.id}'),
        label: 'Drink',
        onPressed: () => onDrink!(item.id),
      );
    } else if (item.base.isSpellBook && onRead != null) {
      refusal = readRefusal;
      primaryButton = _actionButton(
        key: Key('pack-read-${item.id}'),
        label: 'Read',
        onPressed: readRefusal == null ? () => onRead!(item.id) : null,
      );
    } else if (item.base.isEquippable && onWear != null) {
      refusal = wearRefusal;
      primaryButton = _actionButton(
        key: Key('pack-wear-${item.id}'),
        label: 'Wear',
        onPressed: wearRefusal == null ? () => onWear!(item.id) : null,
      );
    }
    final details = <String>[
      if (stats.isNotEmpty) stats,
      if (showBookTeaching && item.base.isSpellBook) _teachingLine(item),
      if (slot != null) deltaLine(wornDeltas(item, equipment[slot])),
      ?refusal,
    ];
    final trailing = primaryButton == null && onDrop == null
        ? null
        : SizedBox(
            width: 104,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ?primaryButton,
                if (onDrop != null)
                  _actionButton(
                    key: Key('pack-drop-${item.id}'),
                    label: 'Drop',
                    onPressed: () => onDrop!(item.id),
                  ),
              ],
            ),
          );
    return FramedRow(
      title: stack.label,
      details: details,
      medallionKey: Key('pack-stack-${item.id}-medallion'),
      medallion: Text(item.rarity.marking, style: textBody),
      trailing: trailing,
    );
  }

  Widget _actionButton({
    required Key key,
    required String label,
    required VoidCallback? onPressed,
  }) => TextButton(
    key: key,
    onPressed: onPressed,
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    ),
    child: Text(label),
  );
}

String _teachingLine(Item book) {
  final spell = spellOrNull(book.base.teaches!);
  if (spell == null) return 'teaches nothing this build knows';
  return '${spell.school.schoolMarking} ${spell.school.schoolWord} · teaches '
      '${spell.name}';
}
