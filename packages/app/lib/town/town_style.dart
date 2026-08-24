import 'package:flutter/material.dart';

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

/// The last refusal, printed where the eye already is.
class Notice extends StatelessWidget {
  const Notice(this.notice, {super.key});

  final String? notice;

  @override
  Widget build(BuildContext context) {
    if (notice == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text('— ${notice!}.', style: monoDim),
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
