import 'package:equatable/equatable.dart';
import 'package:residuum_core/core.dart';

import 'merchant_visit.dart';

/// What reading a save document produced: the document, or why there is none.
///
/// Sealed rather than a nullable pair, so a caller cannot reach for the document
/// without having answered the question of whether there is one. The subtypes
/// share this file because Dart restricts subtyping a sealed class to the library
/// that declares it.
sealed class SaveRead {
  const SaveRead();
}

/// One hero in the roster: what to call them, who they are, and where they are.
///
/// The label lives here rather than on [Profile] because a name is a thing the
/// roster screen shows, not a thing any rule reads — and `core` stays untouched.
/// A hero who has never been named still has one, so the roster never has a
/// blank row to explain.
class SavedHero extends Equatable {
  const SavedHero({
    required this.label,
    required this.profile,
    this.run,
    this.merchant = MerchantVisit.none,
  });

  /// What the roster calls this hero.
  final String label;

  /// The hero as they stand between runs, or as they stood walking in.
  final Profile profile;

  /// The crawl to drop this hero straight back into, or null in town.
  ///
  /// **Per hero, not per document.** Every hero is somewhere: one may be
  /// suspended three floors down while another is in town, and a save that held
  /// only one run between them would have to end somebody's crawl to switch.
  final GameState? run;

  /// What the merchant remembers of this hero's current visit.
  ///
  /// Per hero for the same reason [run] is: two heroes are two visits, and a
  /// shop that remembered one purchase for everybody would put another hero's
  /// item on this hero's shelf — or take it off.
  final MerchantVisit merchant;

  /// This hero, brought up to date.
  SavedHero broughtUpToDate(
    Profile profile,
    GameState? run,
    MerchantVisit merchant,
  ) => SavedHero(label: label, profile: profile, run: run, merchant: merchant);

  @override
  List<Object?> get props => [label, profile, run, merchant];

  @override
  String toString() =>
      'SavedHero($label, ${run == null ? 'in town' : 'in a crawl'})';
}

/// One save, decoded: every hero this install has, and which one is being played.
///
/// **One document, not a file per hero.** Mid-run the profile on disk is the one
/// that walked in, and the run references it — so two files can disagree the
/// moment the app is killed between writing them, and the pair that disagrees is
/// unrecoverable, because neither half knows it is the stale one. A single
/// document cannot desync with itself, and that argument only gets stronger with
/// a roster: N heroes across N files is N chances to half-write.
///
/// [active] is written down rather than implied by position. A roster read in
/// storage order would make "which hero am I playing" depend on how a map
/// happened to serialize, and the first reorder would silently switch heroes.
final class SaveDocument extends SaveRead {
  const SaveDocument({required this.active, required this.heroes});

  /// A document holding exactly one hero, which is what a fresh install is.
  SaveDocument.one({
    required String id,
    required String label,
    required Profile profile,
    GameState? run,
  }) : active = id,
       heroes = {id: SavedHero(label: label, profile: profile, run: run)};

  /// The id of the hero being played. Always a key of [heroes].
  final String active;

  /// Every hero, by the id they were created under.
  final Map<String, SavedHero> heroes;

  /// The hero being played.
  ///
  /// Never null: the decoder refuses a document whose [active] names no hero, so
  /// by the time one of these exists the lookup cannot fail.
  SavedHero get hero => heroes[active]!;

  /// The active hero's profile — what booting reads.
  Profile get profile => hero.profile;

  /// The active hero's suspended crawl, or null when they are in town.
  GameState? get run => hero.run;

  /// What the merchant remembers of the active hero's visit.
  MerchantVisit get merchant => hero.merchant;

  /// This document with the active hero moved on, and every other hero as it was.
  ///
  /// The whole roster is rewritten on every save, so this is what keeps a hero
  /// nobody is playing from being written out of existence by the hero who is.
  SaveDocument replacingActive(
    Profile profile,
    GameState? run,
    MerchantVisit merchant,
  ) => SaveDocument(
    active: active,
    heroes: {
      for (final entry in heroes.entries)
        entry.key: entry.key == active
            ? entry.value.broughtUpToDate(profile, run, merchant)
            : entry.value,
    },
  );

  /// This document with one more hero in it, and that hero being played.
  ///
  /// Creating a hero switches to them. A roster that made a hero and then left
  /// the player looking at somebody else would be asking for two presses to
  /// carry out one intention.
  SaveDocument addingHero({
    required String id,
    required String label,
    required Profile profile,
  }) => SaveDocument(
    active: id,
    heroes: {
      ...heroes,
      id: SavedHero(label: label, profile: profile),
    },
  );

  /// This document with [id] the hero being played, and nothing else moved.
  ///
  /// Switching hero is one field. Everything about the hero being left — their
  /// profile, their suspended crawl, what the merchant remembers of their visit —
  /// stays exactly as it was, which is what makes coming back to them the same
  /// as never having left.
  SaveDocument playing(String id) => SaveDocument(active: id, heroes: heroes);

  /// This document without the hero [id], or null when that would empty it.
  ///
  /// **Null rather than an empty roster.** A document with nobody in it is not a
  /// state the game has — the decoder refuses one — and a player who deleted
  /// their way to it would be looking at a screen with no game behind it.
  /// Deleting the only hero is therefore a replacement rather than a removal,
  /// and [replacingActiveWithNewHero] is the operation that does it.
  ///
  /// Deleting the hero being played moves play to the first hero left, in the
  /// document's own key order — which the encoder sorts, so it is the same hero
  /// however the roster was assembled.
  SaveDocument? without(String id) {
    final left = {
      for (final entry in heroes.entries)
        if (entry.key != id) entry.key: entry.value,
    };
    if (left.length == heroes.length) return this;
    if (left.isEmpty) return null;
    return SaveDocument(
      active: id == active ? left.keys.first : active,
      heroes: left,
    );
  }

  /// This document with the hero being played replaced by a new one.
  ///
  /// The old entry goes: this is the one operation in the game that deletes a
  /// hero, and leaving the corpse in the roster would make it a rename. It exists
  /// for the roster's last delete — deleting the only hero flows straight into
  /// creating the next one, because the game never has zero heroes — and every
  /// other hero is untouched, because giving up one hero is not giving up all of
  /// them.
  SaveDocument replacingActiveWithNewHero({
    required String id,
    required String label,
    required Profile profile,
  }) => SaveDocument(
    active: id,
    heroes: {
      for (final entry in heroes.entries)
        if (entry.key != active) entry.key: entry.value,
      id: SavedHero(label: label, profile: profile),
    },
  );
}

/// Why a save could not be read, in a sentence meant to be shown to the player.
///
/// Follows [TownRefusal]: a failure is a value, never an exception escaping to
/// the interface. Nothing throws past the codec, so a truncated file is a notice
/// on the town screen rather than a crash on launch.
final class SaveFailure extends SaveRead with Equatable {
  const SaveFailure(this.reason);

  /// Written to be read aloud on the screen, not parsed.
  final String reason;

  @override
  List<Object?> get props => [reason];

  @override
  String toString() => 'SaveFailure($reason)';
}
