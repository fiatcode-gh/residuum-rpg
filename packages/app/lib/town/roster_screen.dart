import 'package:flutter/material.dart';
import 'package:residuum_content/content.dart';

import '../save/boot.dart';
import 'town_style.dart';

/// What the player asked the roster to do.
///
/// A value popped back rather than a callback handed in, because every one of
/// these ends with the whole bloc tree being rebuilt: the screen that asked has
/// to be off the stack before that happens, and a screen that both popped itself
/// and called back would be doing half of the navigation from underneath the
/// thing doing the other half. Sealed, so the session cannot forget a case.
sealed class RosterChoice {
  const RosterChoice();
}

/// Play this hero instead. Nondestructive, so nothing was confirmed.
final class PlayHero extends RosterChoice {
  const PlayHero(this.id);

  final String id;

  @override
  bool operator ==(Object other) => other is PlayHero && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'PlayHero($id)';
}

/// Begin a hero called [label], on a world nobody has chosen yet.
///
/// [replacing] names the hero this one takes the place of, which happens only on
/// the delete of the last hero: the game never has zero heroes, so that delete
/// is a replacement and the two edits are one write.
final class MakeHero extends RosterChoice {
  const MakeHero(this.label, {this.replacing});

  final String label;
  final String? replacing;

  @override
  bool operator ==(Object other) =>
      other is MakeHero && other.label == label && other.replacing == replacing;

  @override
  int get hashCode => Object.hash(label, replacing);

  @override
  String toString() => 'MakeHero($label, replacing: $replacing)';
}

/// Delete this hero. Only ever reached through the confirmation.
final class DropHero extends RosterChoice {
  const DropHero(this.id);

  final String id;

  @override
  bool operator ==(Object other) => other is DropHero && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'DropHero($id)';
}

/// Every hero on this install, and the three things that can be done about them.
///
/// **It reads the save document, not any bloc.** Blocs exist only for the hero
/// being played, so every other row's health, gold, visits and depth are in the
/// document and nowhere else. Reading the document is also what makes this screen
/// a pure function of one value, which is what lets it be tested by pumping it.
///
/// Nothing here is told apart by colour. The hero being played carries the word
/// `playing`, and where each hero is standing is the last clause of their own
/// line.
class RosterScreen extends StatelessWidget {
  const RosterScreen({required this.document, super.key});

  final SaveDocument document;

  @override
  Widget build(BuildContext context) => TownRoom(
    title: 'Heroes',
    children: [
      for (final id in document.heroes.keys)
        _HeroRow(
          hero: document.heroes[id]!,
          playing: id == document.active,
          onPlay: id == document.active
              ? null
              : () => Navigator.of(context).pop(PlayHero(id)),
          onDelete: () => _confirmDelete(context, id),
        ),
      const SizedBox(height: 18),
      FilledButton(
        onPressed: () => _create(context),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text(
          'New hero',
          style: TextStyle(fontFamily: 'monospace', fontSize: 15),
        ),
      ),
    ],
  );

  /// Asks once, in words, before a hero and their world are deleted.
  ///
  /// Deleting is the only way a rolled world ends and closing the app cannot undo
  /// it, so the row does not do it — this does, and only after a person has read
  /// a sentence and pressed the word in it. When that hero is standing in a crawl
  /// the sentence says the crawl dies with them, because a suspended run is the
  /// thing a player would most expect to survive and it does not.
  ///
  /// Deleting the only hero flows straight into creating the next one, because
  /// **the game never has zero heroes**: a roster with nobody in it has no game
  /// to open, the save format refuses such a document, and a player who reached
  /// it would be looking at a screen with nothing behind it.
  Future<void> _confirmDelete(BuildContext context, String id) async {
    final hero = document.heroes[id]!;
    final last = document.heroes.length == 1;
    final given = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(
          'Delete ${hero.label}?',
          style: const TextStyle(fontFamily: 'monospace'),
        ),
        content: Text(
          _deletionWarning(hero, last: last),
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: const Text(
              'Keep this hero',
              style: TextStyle(fontFamily: 'monospace'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: const Text(
              'Delete this hero',
              style: TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
    if (!(given ?? false) || !context.mounted) return;
    if (last) {
      await _create(context, replacing: id);
      return;
    }
    Navigator.of(context).pop(DropHero(id));
  }

  /// Asks a name, and answers with the hero to begin.
  ///
  /// An empty answer falls back to the label that was offered rather than making
  /// a hero with no name: the roster has a row for every hero, and a blank row is
  /// something the player would have to work out.
  Future<void> _create(BuildContext context, {String? replacing}) async {
    final offered = heroLabelFor(document.heroes.length);
    final named = await showDialog<String>(
      context: context,
      builder: (dialog) => _NameDialog(offered: offered),
    );
    if (named == null || !context.mounted) return;
    final label = named.trim();
    Navigator.of(context)
        .pop(MakeHero(label.isEmpty ? offered : label, replacing: replacing));
  }

  static String _deletionWarning(SavedHero hero, {required bool last}) => [
    'Everything ${hero.label} carried, banked and learned is deleted, and '
        'their world is gone.',
    if (hero.run case final crawl?)
      'The crawl they are standing in, depth ${crawl.depth} down, dies with '
          'them.',
    if (last) 'A new hero begins in a new world.',
    'This cannot be undone.',
  ].join(' ');
}

/// One hero's row, as words and numbers.
///
/// Every part is a label and a number, and the last clause is where the hero is
/// standing, so the line reads in greyscale and it reads aloud. A hero in town
/// says `in town` rather than saying nothing about it: the absence of a depth is
/// something the player would have to notice and then interpret, while a clause
/// that states its own case does not have to be noticed at all.
String rosterLine(SavedHero hero) => [
  '${hero.profile.hero.hp}/${hero.profile.maxHp} hp',
  '${hero.profile.gold} carried',
  '${hero.profile.bankedGold} banked',
  _visits(hero.profile.visit),
  if (hero.run case final crawl?) 'below (depth ${crawl.depth})' else 'in town',
].join(' · ');

String _visits(int visit) => switch (visit) {
  0 => 'no visits yet',
  1 => '1 visit',
  _ => '$visit visits',
};

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.offered});

  final String offered;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _typed = TextEditingController(
    text: widget.offered,
  );

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text(
      'Name your hero',
      style: TextStyle(fontFamily: 'monospace'),
    ),
    content: TextField(
      controller: _typed,
      autofocus: true,
      style: mono,
      decoration: const InputDecoration(border: OutlineInputBorder()),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Not yet', style: TextStyle(fontFamily: 'monospace')),
      ),
      TextButton(
        onPressed: () => Navigator.of(context).pop(_typed.text),
        child: const Text('Begin', style: TextStyle(fontFamily: 'monospace')),
      ),
    ],
  );
}

class _HeroRow extends StatelessWidget {
  const _HeroRow({
    required this.hero,
    required this.playing,
    required this.onPlay,
    required this.onDelete,
  });

  final SavedHero hero;
  final bool playing;
  final VoidCallback? onPlay;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: onPlay,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(hero.label, style: mono),
                      if (playing) ...[
                        const SizedBox(width: 10),
                        const Text('playing', style: monoDim),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(rosterLine(hero), style: monoDim),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 88,
          child: FilledButton(
            onPressed: onDelete,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            ),
            child: const Text(
              'Delete',
              maxLines: 1,
              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
      ],
    ),
  );
}
