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

  /// The crawl this hero has waiting, or null when they have none.
  GameState? get run => document.run;

  /// Whether the hero is standing in [run] rather than camped away from it.
  ///
  /// The question `run != null` used to answer by itself. Once a hero can walk
  /// out at the stairs and leave the crawl standing, a run on disk means either
  /// "the app died mid-fight" or "there is a dungeon to go back to", and the two
  /// open opposite screens: guessing wrong either drops a shopping hero into a
  /// fight or strands a hero in town with one paused.
  bool get inside => document.inside;

  /// What the merchant remembers of the active hero's visit.
  MerchantVisit get merchant => document.merchant;
}

/// The label a hero is offered when nobody has typed one.
///
/// Derived from how many heroes there already are rather than stored, so the
/// suggestion is always the next number and the word `Hero` appears in exactly
/// one place. A hero who has never been named still has one, so the roster never
/// has a blank row to explain.
String heroLabelFor(int existingHeroes) => 'Hero ${existingHeroes + 1}';

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
    label: heroLabelFor(0),
    profile: newProfile(worldSeed: stamp),
  );
  await store.save(document);
  return Boot(document: document, notice: loaded.report);
}

/// The roster [was] with one more hero on a world of their own, played, and
/// written down before they are played.
///
/// Written first for the same reason a fresh install is: the world they rolled
/// has to outlive the first crash, or a player killed by the task switcher on
/// the way to their first fight comes back to a different dungeon and never
/// knows one was lost.
Future<Boot> createHero(
  SaveStore store,
  SaveDocument was, {
  required String label,
  required int Function() rollWorldSeed,
}) async {
  final stamp = rollWorldSeed();
  final document = was.addingHero(
    id: unusedHeroIdFrom(stamp, was.heroes.keys),
    label: label,
    profile: newProfile(worldSeed: stamp),
  );
  await store.save(document);
  return Boot(document: document);
}

/// The roster [was] with [id] the hero being played, written down.
///
/// Saved before the session is rebuilt rather than after: the rebuild tears the
/// autosaver down, so a switch that had not landed on disk first would be undone
/// by the next launch while the player was already looking at the other hero.
Future<Boot> switchHero(SaveStore store, SaveDocument was, String id) async {
  final document = was.playing(id);
  await store.save(document);
  return Boot(document: document);
}

/// The roster [was] without the hero [id], or null when [id] is the only hero.
///
/// Null is not a failure to report to the player: it is the roster's own rule
/// arriving here, and the caller answers it by creating the next hero instead.
/// Nothing is written in that case, so the document on disk never holds an empty
/// roster, not even for the length of one save.
Future<Boot?> deleteHero(SaveStore store, SaveDocument was, String id) async {
  if (was.without(id) case final SaveDocument left) {
    await store.save(left);
    return Boot(document: left);
  }
  return null;
}

/// The roster [was] — one hero, being played — with that hero given up and a
/// named one in their place on a new world.
///
/// **The game never has zero heroes.** Deleting the only hero is a replacement
/// rather than a removal: a roster with nobody in it has no game to open, the
/// decoder refuses such a document, and a player who reached it would be looking
/// at a screen with nothing behind it. So that delete flows straight into
/// creating the next hero, and the two edits are one write.
Future<Boot> replaceOnlyHero(
  SaveStore store,
  SaveDocument was, {
  required String label,
  required int Function() rollWorldSeed,
}) async {
  final stamp = rollWorldSeed();
  final document = was.replacingActiveWithNewHero(
    id: unusedHeroIdFrom(stamp, was.heroes.keys),
    label: label,
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
