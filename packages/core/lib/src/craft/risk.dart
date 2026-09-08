import 'dart:math';

import '../engine/rng.dart';
import '../town/profile.dart';
import 'temper.dart';

/// What the craft stream's seed is offset by, so it never runs in step with
/// the crawl's two streams or the loot stream.
///
/// A literal rather than a derived value, for the reason the loot stream's own
/// salt is one: a world seed has to describe the same craft odds to every
/// player who types it in, including one running a build compiled years apart
/// from another's. Chosen by collision sweep against the loot stream's early
/// sequence on the fixture heroes — the sweep lives in content's test suite,
/// where both salts are visible.
const int craftSeedSalt = 0x0C7A;

/// The percent chance a temper of [tier] fails for a hero at [blacksmithLevel].
///
/// Tier 1 never fails — the teaching tier stays free of the mechanic that
/// would punish the hero it is meant to teach. The other tiers start at their
/// table odds and take off two points per Blacksmith level past the tier's
/// gate, floored at five: training tames the odds and never kills them.
int temperFailChance(int tier, int blacksmithLevel) => switch (tier) {
  1 => 0,
  2 => _tabled(20, blacksmithLevel - temperPrices[1].blacksmith),
  3 => _tabled(35, blacksmithLevel - temperPrices[2].blacksmith),
  _ => throw RangeError.value(tier, 'tier', 'no temper reaches $tier'),
};

/// The percent chance a brew fails for a hero at [herbcraftLevel].
///
/// No gate, because Herbcraft has no tiers a gate could hang on — inventing
/// one would lock the only thing herbs are for behind training a new hero has
/// no reason to have started. Level 0 brews at twenty; the floor arrives at
/// level 8.
int brewFailChance(int herbcraftLevel) => _tabled(20, herbcraftLevel);

int _tabled(int start, int levelsPast) => max(5, start - 2 * levelsPast);

/// Draws the craft roll for one attempt: [profile] with the stream advanced
/// once, and whether the attempt failed.
///
/// **One attempt, one advance**, 0% tiers included — stream consumption is a
/// fact about the attempt, not the outcome. A field still reading its default
/// lazy-seeds off the world seed, so an old save without the key boots clean.
(Profile, bool) craftDraw(Profile profile, int failChance) {
  final rng = profile.craftRngState == 0
      ? Rng(profile.worldSeed ^ craftSeedSalt)
      : Rng.fromState(profile.craftRngState);
  final failed = rng.rollRange(0, 99) < failChance;
  return (profile.copyWith(craftRngState: rng.state), failed);
}
