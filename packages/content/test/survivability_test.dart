import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import 'support/kit.dart';

/// How the bot decides what to wear.
enum _Build {
  /// Wear whatever is strictly better. What a first-time player does.
  greedy,

  /// Stay bare until Fleetfoot is worth having, then armour up and keep the
  /// dodge. The exploit the dodge-then-armour pipeline invites.
  fleetfootFirst,
}

/// What became of one seeded run.
class _Outcome {
  const _Outcome({
    required this.depth,
    required this.deepest,
    required this.alive,
    required this.ranOut,
    required this.turns,
    required this.skills,
  });

  final int depth;

  /// How deep the delve this run was played in went.
  ///
  /// Read off the opening state rather than off a constant, because a themed
  /// delve rolls its own bottom: a bot that stopped at the crypt's five would
  /// count a seven-deep keep as won two floors early, and would walk a four-deep
  /// cave in circles forever looking for a sixth floor that was never laid.
  final int deepest;

  final bool alive;

  /// Whether the run hit the turn budget rather than finishing either way.
  final bool ranOut;

  final int turns;
  final Map<SkillId, SkillState> skills;

  bool get won => depth >= deepest && alive;
}

/// The most turns one run is allowed before it counts as a loss.
///
/// Generous: a five-floor descent that picks up and equips as it goes takes a
/// few hundred turns, and a budget that bites would measure the budget instead
/// of the dungeon.
const int _turnBudget = 4000;

/// Where the forty crypt runs end, and how many end there.
///
/// **The figure was a printed line for two milestones, and printing is not
/// asserting.** The band above it (fifty to ninety-five percent) is wide enough
/// to swallow a crypt that moved by six runs in either direction, so anything
/// that quietly reshuffled the shipped dungeon would have left the suite green
/// and the report unread. These are the numbers the crypt has always produced;
/// pinning them is what makes the two new dungeons landing beside it provably
/// additive rather than probably additive.
///
/// Twenty of the forty reach depth five alive, which is the same twenty the
/// win count reads — the bot stops on arrival at the bottom, so a run that
/// ends at five is a run that won.
///
/// **The old pin was `{1: 1, 2: 9, 3: 6, 5: 24}` and it died by design.** The
/// crypt's deep floors stopped dealing a universal one point of damage, and
/// what the histogram shows is where that landed: the shallow floors are
/// exactly where they were — one and nine, the same two numbers — and the
/// dying spread down across floors three and four, which is where the skeleton
/// and the wight now are. That is the shape the rebalance was asked for: the
/// first half teaches, the second half bites.
const Map<int, int> _cryptDepths = {1: 1, 2: 9, 3: 4, 4: 6, 5: 20};

/// Where the forty sea-cave runs end, with [survivabilityKit]'s gear.
///
/// Pinned beside the band for the crypt's reason, and the ordering test below is
/// the other half: the band alone would let the cave drift past the keep and
/// call it balanced.
///
/// **The keys are final depths in a variable band, not floors of one fixed
/// dungeon.** A delve rolls four, five or six floors, so a run that ends at four
/// may have won a four-floor cave or died on the fourth floor of a six-floor
/// one, and only the win count separates them. The first pin — `{3: 5, 5: 35}` —
/// died with the roll rather than with a regression: every cave used to be five
/// floors deep, so every winner keyed at five.
///
/// **The pin before this one was `{3: 5, 4: 15, 5: 9, 6: 11}` at 34/40.** The
/// cave was the one dungeon the loot cut could not touch — a graduate walks in
/// with four potions and Fine mail, so what the floor gives up was never what
/// decided its runs. What moved it was bodies and kill drops: two more creatures
/// on every floor, and fifteen points off every drop chance.
const Map<int, int> _seaCaveDepths = {2: 1, 3: 7, 4: 13, 5: 10, 6: 9};

/// Where the forty keep runs end, with the same gear.
///
/// The first pin was `{2: 6, 3: 3, 5: 31}`; the one before this was
/// `{2: 6, 3: 3, 5: 14, 6: 8, 7: 9}` at 31/40. The keep took the rebalance
/// almost entirely on the chin — deeper pierce and a notch on the deep attack
/// ceilings cost it three runs — because it was already the hardest walk and
/// the hardest floor. What the new histogram shows that the old one did not is
/// four runs ending on depth one: the keep now has a first floor that can kill
/// a graduate who walks in carelessly.
const Map<int, int> _keepDepths = {1: 4, 2: 6, 3: 1, 4: 1, 5: 13, 6: 9, 7: 6};

/// Plays one crawl on [worldSeed] with a fixed policy and reports what happened.
///
/// The policy, in order: attack anything adjacent; drink under forty percent of
/// the derived maximum if a potion is held; take what is underfoot; wear a
/// strict upgrade; otherwise walk one step toward the stairs and take them on
/// arrival.
///
/// **The bot knows the whole floor.** It paths on the real map rather than on
/// what the hero has explored, which makes it a better navigator than a human
/// and no better a tactician. That is deliberate: the win rate then measures
/// the content — how much the dungeon hits for and how much loot it gives back
/// — rather than measuring how well a bot explores in the dark.
///
/// **A full pack stops collecting rather than making room, and the rule it
/// replaces was a loop.** The policy used to drop the first non-potion whenever
/// the pack was full — but a drop lands under the hero and the pick-up rule
/// takes whatever is under the hero, so the bot put the same item down and took
/// it back forever, and the run ended on the turn budget instead of in the
/// dungeon. It never bit while floors were thin. It bites the moment there is
/// enough on the ground to fill twenty slots, which is exactly what measuring a
/// crowded floor requires. Making room where you are standing makes none.
_Outcome _botCrawl({required int worldSeed, _Build build = _Build.greedy}) =>
    _botPlay(newGame(worldSeed: worldSeed), build);

/// Plays one crawl of the dungeon at [node] with the mid-progression kit.
///
/// **A different door on purpose.** The crypt's bot walks in through [newGame]
/// at visit zero, which is the door the shipped figure was measured through and
/// the one thing about it that must not move. A themed dungeon has no such door
/// and no legacy figure to protect, so it enters the way a player does — through
/// [startDungeonRunAt], on the bumped visit — carrying [survivabilityKit]'s
/// gear.
_Outcome _themedCrawl({
  required NodeId node,
  required int worldSeed,
  _Build build = _Build.greedy,
}) => _botPlay(startDungeonRunAt(node, survivabilityKit(worldSeed)), build);

_Outcome _botPlay(GameState opening, _Build build) {
  var game = opening;
  var turns = 0;

  while (turns < _turnBudget) {
    if (game.isGameOver) break;
    if (game.depth >= opening.deepest) break;
    turns++;

    final action = _decide(game, build);
    final (after, _) = step(game, action);
    if (identical(after, game)) {
      final nudge = _anyStep(game);
      if (nudge == null) break;
      final (moved, _) = step(game, nudge);
      game = moved;
      continue;
    }
    game = after;
  }

  return _Outcome(
    depth: game.depth,
    deepest: opening.deepest,
    alive: !game.isGameOver,
    ranOut: turns >= _turnBudget,
    turns: turns,
    skills: game.skills,
  );
}

GameAction _decide(GameState game, _Build build) {
  final adjacent = _adjacentMonster(game);
  if (adjacent != null) {
    return MoveAction(game.hero.position.directionTo(adjacent.position)!);
  }

  final ceiling = heroMaxHp(game.hero, game.loadout);
  if (game.hero.hp * 5 < ceiling * 2) {
    final potion = _firstPotion(game);
    if (potion != null) return DrinkAction(potion.id);
  }

  if (game.itemsAt(game.hero.position).isNotEmpty &&
      game.inventory.length < inventoryCap) {
    return const PickUpAction();
  }

  final upgrade = _bestUpgrade(game, build);
  if (upgrade != null) return EquipAction(upgrade.id);

  final stairs = game.stairsDown;
  if (stairs != null) {
    final path = findPath(game.map, game.hero.position, stairs);
    if (path.isEmpty) return const DescendAction();
    final direction = game.hero.position.directionTo(path.first);
    if (direction != null) return MoveAction(direction);
  }
  return const DescendAction();
}

Actor? _adjacentMonster(GameState game) {
  for (final monster in game.monsters) {
    if (monster.position.isOrthogonallyAdjacentTo(game.hero.position)) {
      return monster;
    }
  }
  return null;
}

Item? _firstPotion(GameState game) {
  for (final item in game.inventory) {
    if (item.base.isPotion) return item;
  }
  return null;
}

/// The carried item worth putting on, or null when nothing is.
///
/// "Worth" is strict: a weapon must swing harder in total than the one in hand,
/// and a piece of armour must beat what is in its slot on armour plus hit
/// points. A shield is never offered while a two-hander is held, because the
/// rules would refuse it and the bot would spin.
Item? _bestUpgrade(GameState game, _Build build) {
  final loadout = game.loadout;
  for (final item in game.inventory) {
    if (!item.base.isEquippable) continue;
    final slot = item.base.slot!;
    if (slot == EquipSlot.offHand && loadout.wieldsTwoHanded) continue;
    if (build == _Build.fleetfootFirst &&
        item.base.heavy &&
        loadout.levelOf(SkillId.fleetfoot) < 10) {
      continue;
    }
    final worn = loadout.equipment[slot];
    if (item.base.isWeapon) {
      final held = (worn?.attackMin ?? 0) + (worn?.attackMax ?? 0);
      if (item.attackMin + item.attackMax > held) return item;
      continue;
    }
    final held = (worn?.armor ?? 0) + (worn?.maxHp ?? 0);
    if (item.armor + item.maxHp > held) return item;
  }
  return null;
}

/// Any legal step, for the rare turn where the policy asks for something the
/// rules refuse and the bot would otherwise stand still forever.
GameAction? _anyStep(GameState game) {
  for (final direction in Direction.values) {
    if (game.map.isWalkable(game.hero.position.step(direction))) {
      return MoveAction(direction);
    }
  }
  return null;
}

void main() {
  group('survivability', () {
    test('a one to five descent is survivable but not a formality', () {
      // arrange
      const seeds = 40;

      // act
      final outcomes = [
        for (var seed = 1; seed <= seeds; seed++) _botCrawl(worldSeed: seed),
      ];
      final wins = outcomes.where((outcome) => outcome.won).length;
      final rate = wins / seeds;
      final stalled = outcomes.where((outcome) => outcome.ranOut).length;

      // assert
      print(
        'survivability: $wins/$seeds won (${(rate * 100).toStringAsFixed(1)}%), '
        'stalled $stalled, died at ${_deathDepths(outcomes)}',
      );
      expect(stalled, 0, reason: 'the bot stalled rather than played');
      expect(rate, greaterThanOrEqualTo(0.45), reason: 'still unfair: $rate');
      expect(rate, lessThanOrEqualTo(0.80), reason: 'trivial: $rate');
      expect(wins, 20, reason: 'the crypt moved');
      expect(_depthsReached(outcomes), _cryptDepths, reason: 'the crypt moved');
    });

    test('a run is decided by the dungeon, not by the turn budget', () {
      // arrange
      const seeds = 40;

      // act
      final outcomes = [
        for (var seed = 1; seed <= seeds; seed++) _botCrawl(worldSeed: seed),
      ];

      // assert
      expect(outcomes.map((outcome) => outcome.ranOut), everyElement(isFalse));
    });

    test('the same seed plays out the same way twice', () {
      // arrange
      const seed = 7;

      // act
      final one = _botCrawl(worldSeed: seed);
      final other = _botCrawl(worldSeed: seed);

      // assert
      expect(
        (one.depth, one.alive, one.turns),
        (other.depth, other.alive, other.turns),
      );
    });

    test('the bot trains what it uses, so learn-by-doing is reachable', () {
      // arrange
      const seeds = 20;

      // act
      final best = <SkillId, int>{for (final id in SkillId.values) id: 0};
      for (var seed = 1; seed <= seeds; seed++) {
        final outcome = _botCrawl(worldSeed: seed);
        for (final id in SkillId.values) {
          final level = outcome.skills[id]?.level ?? 0;
          if (level > best[id]!) best[id] = level;
        }
      }

      // assert — a descent has to be long enough to move the skills the hero is
      // actually using, or learn-by-doing is decoration
      expect(best[SkillId.arms], greaterThan(0));
      expect(best[SkillId.bulwark]! + best[SkillId.fleetfoot]!, greaterThan(0));
    });
  });

  group('the Fleetfoot-first build', () {
    test('is measured against the greedy one, and reported', () {
      // arrange
      const seeds = 40;

      // act
      final greedy = [
        for (var seed = 1; seed <= seeds; seed++)
          _botCrawl(worldSeed: seed, build: _Build.greedy),
      ];
      final exploiting = [
        for (var seed = 1; seed <= seeds; seed++)
          _botCrawl(worldSeed: seed, build: _Build.fleetfootFirst),
      ];
      final greedyWins = greedy.where((outcome) => outcome.won).length;
      final exploitWins = exploiting.where((outcome) => outcome.won).length;

      // assert — no band on the exploit build: this test exists to put a number
      // on it. Train Fleetfoot bare, then wear heavy, and the dodge levels stay
      // while the armour arrives — the question m2-town has to answer is
      // whether that needs a rule, and this is the measurement it answers from.
      print(
        'greedy build: $greedyWins/$seeds won; '
        'fleetfoot-first build: $exploitWins/$seeds won',
      );
      expect(greedyWins, greaterThan(0));
      expect(exploitWins, greaterThanOrEqualTo(0));
      expect(greedyWins, 20, reason: 'the crypt moved');
      expect(exploitWins, 14, reason: 'the exploit moved');
    });
  });

  group('the sea-cave', () {
    test('is survivable with a crypt graduate\'s kit, but not a formality', () {
      // arrange
      const seeds = 40;

      // act
      final outcomes = [
        for (var seed = 1; seed <= seeds; seed++)
          _themedCrawl(node: seaCave, worldSeed: seed),
      ];
      final wins = outcomes.where((outcome) => outcome.won).length;
      final rate = wins / seeds;
      final stalled = outcomes.where((outcome) => outcome.ranOut).length;

      // assert
      print(
        'sea-cave: $wins/$seeds won (${(rate * 100).toStringAsFixed(1)}%), '
        'stalled $stalled, died at ${_deathDepths(outcomes)}',
      );
      expect(stalled, 0, reason: 'the bot stalled rather than played');
      expect(rate, greaterThanOrEqualTo(0.45), reason: 'still unfair: $rate');
      expect(rate, lessThanOrEqualTo(0.80), reason: 'trivial: $rate');
      expect(wins, 31, reason: 'the sea-cave moved');
      expect(_depthsReached(outcomes), _seaCaveDepths);
    });

    test('plays out the same way twice on one seed', () {
      // arrange
      const seed = 7;

      // act
      final one = _themedCrawl(node: seaCave, worldSeed: seed);
      final other = _themedCrawl(node: seaCave, worldSeed: seed);

      // assert
      expect(
        (one.depth, one.alive, one.turns),
        (other.depth, other.alive, other.turns),
      );
    });
  });

  group('the ruined keep', () {
    test('is the hardest walk and the hardest floor, and still winnable', () {
      // arrange
      const seeds = 40;

      // act
      final outcomes = [
        for (var seed = 1; seed <= seeds; seed++)
          _themedCrawl(node: ruinedKeep, worldSeed: seed),
      ];
      final wins = outcomes.where((outcome) => outcome.won).length;
      final rate = wins / seeds;
      final stalled = outcomes.where((outcome) => outcome.ranOut).length;

      // assert
      print(
        'ruined keep: $wins/$seeds won (${(rate * 100).toStringAsFixed(1)}%), '
        'stalled $stalled, died at ${_deathDepths(outcomes)}',
      );
      expect(stalled, 0, reason: 'the bot stalled rather than played');
      expect(rate, greaterThanOrEqualTo(0.45), reason: 'still unfair: $rate');
      expect(rate, lessThanOrEqualTo(0.80), reason: 'trivial: $rate');
      expect(wins, 28, reason: 'the ruined keep moved');
      expect(_depthsReached(outcomes), _keepDepths);
    });

    test('plays out the same way twice on one seed', () {
      // arrange
      const seed = 7;

      // act
      final one = _themedCrawl(node: ruinedKeep, worldSeed: seed);
      final other = _themedCrawl(node: ruinedKeep, worldSeed: seed);

      // assert
      expect(
        (one.depth, one.alive, one.turns),
        (other.depth, other.alive, other.turns),
      );
    });

    test('is harder than the sea-cave with the same kit', () {
      // arrange
      const seeds = 40;

      // act
      final cave = [
        for (var seed = 1; seed <= seeds; seed++)
          _themedCrawl(node: seaCave, worldSeed: seed),
      ].where((outcome) => outcome.won).length;
      final keep = [
        for (var seed = 1; seed <= seeds; seed++)
          _themedCrawl(node: ruinedKeep, worldSeed: seed),
      ].where((outcome) => outcome.won).length;

      // assert — the ordering rather than the gap, because the gap is a tuning
      // number and the ordering is the design: two days out has to cost
      // something the one-day trip does not
      print('sea-cave $cave/$seeds vs ruined keep $keep/$seeds');
      expect(keep, lessThan(cave));
    });
  });
}

/// How many runs ended on each depth, for the balance report.
String _deathDepths(List<_Outcome> outcomes) {
  final byDepth = _depthsReached(outcomes);
  final depths = byDepth.keys.toList()..sort();
  return [for (final depth in depths) '$depth:${byDepth[depth]}'].join(' ');
}

/// How many runs ended on each depth, as the figure rather than the sentence.
Map<int, int> _depthsReached(List<_Outcome> outcomes) {
  final byDepth = <int, int>{};
  for (final outcome in outcomes) {
    byDepth[outcome.depth] = (byDepth[outcome.depth] ?? 0) + 1;
  }
  return byDepth;
}
