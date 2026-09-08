import 'dart:async';

import 'package:flutter/material.dart';

import '../notice/notice.dart';

import 'package:residuum_core/core.dart';

const Color ink = Color(0xFFE6EAF0);
const Color dim = Color(0xFF8A919E);
const Color panel = Color(0xFF15181F);
const Color rule = Color(0xFF2A2E38);

const TextStyle mono = TextStyle(
  fontFamily: 'monospace',
  fontSize: 14,
  color: ink,
);

const TextStyle monoDim = TextStyle(
  fontFamily: 'monospace',
  fontSize: 12,
  color: dim,
);

/// A section title above a list.
///
/// The town screens tell their two lists apart by this heading and by the order
/// they sit in, never by colour. Carried above banked, for sale above your
/// pack: the same order on every screen, so the position itself is information.
class Heading extends StatelessWidget {
  const Heading(this.text, {super.key});

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
            color: dim,
          ),
        ),
        const Divider(color: rule, height: 9),
      ],
    ),
  );
}

/// One line saying there is nothing in the list above.
class NothingHere extends StatelessWidget {
  const NothingHere(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(text, style: monoDim),
  );
}

/// One item, its rarity marking, and a button that does the one thing this
/// screen does with it.
///
/// The marking column is a glyph rather than a hue, and the tier word is
/// already the first word of the item's own name, so the row reads in
/// greyscale and it reads aloud.
class ItemRow extends StatelessWidget {
  const ItemRow({
    required this.marking,
    required this.name,
    required this.action,
    required this.onPressed,
    this.reason,
    super.key,
  });

  final String marking;
  final String name;

  /// What the button says, price included: `Buy 24`, `Sell 12`, `Bank`.
  final String action;

  final VoidCallback? onPressed;

  /// Why the button is dead, drawn only while it is.
  ///
  /// **A dead control that says nothing is a control the player thinks is
  /// broken.** The row already has the gear screen's two-line grammar to borrow,
  /// so the reason goes under the name where the eye already is — and it goes
  /// away the moment the control works, because a sentence explaining a button
  /// that does what it says is noise.
  ///
  /// A sentence rather than a marking, so the row reads in greyscale and reads
  /// aloud.
  final String? reason;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(marking, style: monoDim, textAlign: TextAlign.center),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: mono,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (onPressed == null && reason != null)
                Text(reason!, style: monoDim),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 104,
          child: FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            ),
            child: Text(
              action,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
      ],
    ),
  );
}

/// The purse, as both screens that spend from it print it.
class Purse extends StatelessWidget {
  const Purse({required this.carried, required this.banked, super.key});

  final int carried;
  final int banked;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: panel,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Carried  $carried gold', style: mono),
        Text('Banked   $banked gold', style: mono),
      ],
    ),
  );
}

/// What the hero has gathered, in a fixed order with no gaps.
///
/// Every material has a row even at zero, because the position of a row is
/// information the player relies on and a row that came and went would move the
/// ones below it under a thumb already reaching for one.
///
/// The mark, the word and the number are three readings of one fact, so the rows
/// are legible in greyscale and read aloud.
///
/// **Laid out in fixed-width columns rather than by padding the text.** The
/// markings are not all one cell wide in the device's monospace font — the ingot
/// bar is wider than the ore diamond — so a padded string aligns on the desktop
/// and steps sideways on the phone. A device pass caught exactly that.
class MaterialRows extends StatelessWidget {
  const MaterialRows({required this.materials, super.key});

  final Map<MaterialId, int> materials;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final id in MaterialId.values)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Row(
            children: [
              SizedBox(width: 28, child: Text(id.marking, style: mono)),
              SizedBox(width: 84, child: Text(id.word, style: mono)),
              Text('${materials[id] ?? 0}', style: mono),
            ],
          ),
        ),
    ],
  );
}

/// [MaterialRows] inside a panel, for the rooms that spend them.
///
/// [Purse]'s sibling: the two panels sit one above the other at the top of the
/// forge and the alchemist, so what a transaction costs and what the hero has to
/// pay it with are read in one glance.
class MaterialsPanel extends StatelessWidget {
  const MaterialsPanel({required this.materials, super.key});

  final Map<MaterialId, int> materials;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: panel,
      borderRadius: BorderRadius.circular(4),
    ),
    child: MaterialRows(materials: materials),
  );
}

/// The last notice, printed where the eye already is.
///
/// Every variant of the sealed type renders the same way today — the town's
/// frame, one sentence — and exists as types so the day one must render
/// differently it can, without anyone working out which string meant what.
class Notice extends StatelessWidget {
  const Notice(this.notice, {super.key});

  final SaveNotice? notice;

  @override
  Widget build(BuildContext context) {
    if (notice == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text('— ${notice!.sentence}.', style: monoDim),
    );
  }
}

/// A counted control: − / value / + / MAX, with tap-and-hold auto-repeat.
///
/// Counted work is dialled here and committed elsewhere — the stepper holds no
/// power of its own, and every change it makes is a callback the owning screen
/// turns into its pending count. The edges are dead, not gone: − at zero and
/// + and MAX at the cap stay on the row, dimmed, so the control never vanishes
/// and never needs a sentence of its own — the value word says where the dial
/// stands. Glyphs, a number and a word, so the control reads in greyscale and
/// reads aloud.
class CountStepper extends StatefulWidget {
  const CountStepper({
    required this.value,
    required this.cap,
    required this.onChanged,
    super.key,
  });

  /// The count as it stands. The owner owns it; this renders and moves it.
  final int value;

  /// What the actual resources allow. The dial never offers past it.
  final int cap;

  final ValueChanged<int> onChanged;

  @override
  State<CountStepper> createState() => _CountStepperState();
}

class _CountStepperState extends State<CountStepper> {
  /// How long a held edge waits before repeating, and the cadence after.
  ///
  /// **Constants, not feel.** A widget test pumps the same clock a thumb
  /// rides (`tester.pump`), so the cadence is part of the widget's contract
  /// and CI never waits on wall-clock time.
  static const Duration holdFirstRepeat = Duration(milliseconds: 400);
  static const Duration holdCadence = Duration(milliseconds: 120);

  Timer? _repeat;

  @override
  void dispose() {
    _repeat?.cancel();
    super.dispose();
  }

  void _step(int by) {
    final next = (widget.value + by).clamp(0, widget.cap);
    if (next != widget.value) widget.onChanged(next);
  }

  void _pressDown(int by) {
    _step(by);
    _repeat?.cancel();
    _repeat = Timer(holdFirstRepeat, () {
      _step(by);
      _repeat = Timer.periodic(holdCadence, (_) => _step(by));
    });
  }

  void _release() {
    _repeat?.cancel();
    _repeat = null;
  }

  @override
  Widget build(BuildContext context) {
    Widget edge(String glyph, int by) {
      final dead = widget.value + by < 0 || widget.value + by > widget.cap;
      final glyph_ = Text(glyph, style: dead ? monoDim : mono);
      return GestureDetector(
        onTapDown: dead ? null : (_) => _pressDown(by),
        onTapUp: dead ? null : (_) => _release(),
        onTapCancel: dead ? null : _release,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: glyph_,
        ),
      );
    }

    final capped = widget.value >= widget.cap;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        edge('−', -1),
        SizedBox(
          width: 56,
          child: Text(
            '${widget.value}',
            textAlign: TextAlign.center,
            style: mono,
          ),
        ),
        edge('+', 1),
        GestureDetector(
          onTapDown: capped ? null : (_) => widget.onChanged(widget.cap),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Text('MAX', style: capped ? monoDim : mono),
          ),
        ),
      ],
    );
  }
}

/// The scaffold every town room shares.
class TownRoom extends StatelessWidget {
  const TownRoom({required this.title, required this.children, super.key});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(title, style: const TextStyle(fontFamily: 'monospace')),
      backgroundColor: panel,
      foregroundColor: ink,
    ),
    body: ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      children: [...children, const SizedBox(height: 24)],
    ),
  );
}
