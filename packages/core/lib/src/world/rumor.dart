import 'package:equatable/equatable.dart';

import '../town/profile.dart';
import '../town/town.dart';
import 'node.dart';
import 'whereabouts.dart';

/// One thing a tavern has to say, and the place saying it uncovers.
///
/// A core type filled by content, following [DropTable]: what a rumor *is* — a
/// sentence and the place it points at — is a rule about how the map is
/// uncovered, while which sentences exist and where they point is content's.
class Rumor extends Equatable {
  const Rumor({required this.line, required this.reveals});

  /// Written to be read aloud in the tavern, not parsed.
  final String line;

  /// The place hearing this tells the hero about.
  final NodeId reveals;

  @override
  List<Object?> get props => [line, reveals];

  @override
  String toString() => 'Rumor(${reveals.value})';
}

/// What asking at the tavern came to: the hero after, the map they know after,
/// and what they were told.
///
/// Three outcomes and the shape says which is which. Told something: [rumor] is
/// it, the gold is gone, the map is wider. Told nothing because there is nothing
/// left to tell: [rumor] and [refusal] are both null and the purse is untouched
/// — that is not a refusal, because nothing was wrong with the asking. Refused:
/// [refusal] says why and nothing moved.
class Rumored extends Equatable {
  const Rumored({
    required this.profile,
    required this.whereabouts,
    this.rumor,
    this.refusal,
  });

  final Profile profile;
  final Whereabouts whereabouts;

  /// What the hero was told, or null when they were told nothing.
  final Rumor? rumor;

  /// Why nothing was bought, or null when something was or when there was
  /// nothing to buy.
  final TownRefusal? refusal;

  @override
  List<Object?> get props => [profile, whereabouts, rumor, refusal];

  @override
  String toString() => 'Rumored(${rumor ?? refusal ?? 'nothing to tell'})';
}

/// Buys one rumor out of [pool] for [price].
///
/// **Never a place the hero already knows, and never a charge for one.** A
/// tavern that sold the location of the town you are standing in would be a
/// tavern that takes money for nothing, so the pool is read for the first entry
/// pointing somewhere unheard-of and a pool with none left tells the hero so and
/// charges nothing. That is the whole of ruling five, in the order it has to be
/// checked in: whether there is anything to sell comes before whether the hero
/// can pay for it, because a shop with empty shelves does not get to refuse you
/// for being poor.
///
/// The pool's own order decides which place is uncovered first, rather than a
/// roll. A world this small has one place to find and a draw would be
/// theatre — and content writing the order down means the uncovering is paced
/// on purpose rather than by whichever way a set happened to iterate.
///
/// Returns both halves because the purchase moves both: gold is the hero's and
/// the map is the world's, they live in different owners, and a function that
/// returned one of them would leave the caller to invent the other.
Rumored buyRumor(
  Profile profile,
  Whereabouts where,
  List<Rumor> pool,
  int price,
) {
  final untold = _firstUntold(pool, where);
  if (untold == null) {
    return Rumored(profile: profile, whereabouts: where);
  }
  if (profile.gold < price) {
    return Rumored(
      profile: profile,
      whereabouts: where,
      refusal: const TownRefusal('you cannot afford that'),
    );
  }
  return Rumored(
    profile: profile.copyWith(gold: profile.gold - price),
    whereabouts: where.hearingOf(untold.reveals),
    rumor: untold,
  );
}

Rumor? _firstUntold(List<Rumor> pool, Whereabouts where) {
  for (final rumor in pool) {
    if (!where.discovered.contains(rumor.reveals)) return rumor;
  }
  return null;
}
