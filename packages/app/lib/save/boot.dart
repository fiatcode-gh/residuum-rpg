import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import 'save_store.dart';

/// What the app opens onto.
class Boot {
  const Boot({required this.document, this.notice});

  /// Every hero on this install, and which one is being played.
  ///
  /// The whole roster travels rather than just the active hero, because the
  /// autosaver has to write the others back out untouched on every save.
  final SaveDocument document;

  /// What to tell the player about the save that was read, or null when there is
  /// nothing to say.
  final String? notice;

  /// The hero being played.
  Profile get profile => document.profile;

  /// The crawl to drop straight back into, or null to open on the town.
  GameState? get run => document.run;
}

/// The label a hero gets before anything has named them.
const String defaultHeroLabel = 'Hero 1';

/// Reads [store], falls back, or begins a hero on a world of their own.
///
/// A fresh hero is written down before they are played, so the world they rolled
/// outlives the first crash. Without that write, a player killed by the task
/// switcher on the way to their first fight would come back to a different
/// dungeon and never know one had been lost.
Future<Boot> bootFrom(
  SaveStore store, {
  required int Function() rollWorldSeed,
}) async {
  final loaded = await store.load();
  if (loaded.document case final SaveDocument document) {
    return Boot(document: document, notice: loaded.report);
  }
  final stamp = rollWorldSeed();
  final document = SaveDocument.one(
    id: heroIdFrom(stamp),
    label: defaultHeroLabel,
    profile: newProfile(worldSeed: stamp),
  );
  await store.save(document);
  return Boot(document: document, notice: loaded.report);
}

/// The roster [was], with the hero being played given up and a new one in their
/// place, written down before it is played.
///
/// Abandoning replaces one slot rather than the file. Wiping both save slots was
/// simpler and was what this did while a document could hold only one hero — but
/// it would now delete every hero the player did not ask about, which is the
/// opposite of what the button says.
Future<Boot> abandonActiveHero(
  SaveStore store,
  SaveDocument was, {
  required int Function() rollWorldSeed,
}) async {
  final stamp = rollWorldSeed();
  final document = was.replacingActiveWithNewHero(
    id: unusedHeroIdFrom(stamp, was.heroes.keys),
    label: defaultHeroLabel,
    profile: newProfile(worldSeed: stamp),
  );
  await store.save(document);
  return Boot(document: document);
}

/// A world seed nobody chose.
///
/// **The one sanctioned unseeded roll in the game, and it lives here.** Core and
/// content are forbidden it, because a rule that reads a clock is a rule no test
/// can pin. A new hero's world still has to come from somewhere outside the game
/// or every install plays the same dungeon — so the app rolls it once, at the one
/// moment there is no state to be deterministic about, and writes it down. From
/// then on it is a saved number like any other.
int rollWorldSeedFromClock() => DateTime.now().millisecondsSinceEpoch;

/// The id a hero created at [stamp] is filed under.
///
/// Derived from the same clock reading as the world seed rather than from a
/// second one, so a hero's id and their world are two halves of one moment.
String heroIdFrom(int stamp) => 'hero-$stamp';

/// [heroIdFrom], moved along until it collides with none of [taken].
///
/// An id is never reused, and the clock alone cannot promise that: two heroes
/// made inside one millisecond would answer to the same name, and the second
/// would quietly replace the first in the roster. Two taps that close together
/// is not a thing a person does, which is exactly why it would never be found by
/// playing.
String unusedHeroIdFrom(int stamp, Iterable<String> taken) {
  final used = taken.toSet();
  final first = heroIdFrom(stamp);
  if (!used.contains(first)) return first;
  for (var next = 2; ; next++) {
    final candidate = '$first-$next';
    if (!used.contains(candidate)) return candidate;
  }
}
