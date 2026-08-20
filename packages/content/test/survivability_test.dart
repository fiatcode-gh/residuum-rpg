import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

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
    required this.alive,
    required this.ranOut,
    required this.turns,
    required this.skills,
  });

  final int depth;
  final bool alive;

  /// Whether the run hit the turn budget rather than finishing either way.
  final bool ranOut;

  final int turns;
  final Map<SkillId, SkillState> skills;

  bool get won => depth >= deepestDepth && alive;
}

/// The most turns one run is allowed before it counts as a loss.
///
/// Generous: a five-floor descent that picks up and equips as it goes takes a
/// few hundred turns, and a budget that bites would measure the budget instead
/// of the dungeon.
const int _turnBudget = 4000;

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
_Outcome _botCrawl({required int worldSeed, _Build build = _Build.greedy}) {
  var game = newGame(worldSeed: worldSeed);
  var turns = 0;

  while (turns < _turnBudget) {
    if (game.isGameOver) break;
    if (game.depth >= deepestDepth) break;
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

  final junk = _junk(game);
  if (game.inventory.length >= inventoryCap && junk != null) {
    return DropAction(junk.id);
  }

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

/// Anything carried that is neither a potion nor an upgrade: the first thing to
/// go when the pack is full.
Item? _junk(GameState game) {
  for (final item in game.inventory) {
    if (!item.base.isPotion) return item;
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
      expect(rate, greaterThanOrEqualTo(0.50), reason: 'still unfair: $rate');
      expect(rate, lessThanOrEqualTo(0.95), reason: 'trivial: $rate');
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
    });
  });
}

/// How many runs ended on each depth, for the balance report.
String _deathDepths(List<_Outcome> outcomes) {
  final byDepth = <int, int>{};
  for (final outcome in outcomes) {
    byDepth[outcome.depth] = (byDepth[outcome.depth] ?? 0) + 1;
  }
  final depths = byDepth.keys.toList()..sort();
  return [for (final depth in depths) '$depth:${byDepth[depth]}'].join(' ');
}
