import '../dungeon/floor_map.dart';
import 'actor.dart';
import 'position.dart';
import 'rng.dart';

/// The whole state of one crawl.
///
/// Every field is immutable except [rng], which is carried by reference and
/// advances as rolls are drawn. That is a deliberate, documented exception to
/// the immutable-state rule: threading a fresh generator out of every combat
/// roll would put a return value on every rule function for no gain in
/// testability. Determinism survives it, because determinism here means "the
/// same seed plus the same sequence of actions produces the same game" — the
/// generator advances once per roll, in rule order, so a replayed action
/// sequence draws the same numbers. Nothing relies on re-reading an earlier
/// roll after a *different* action sequence, and nothing may start to.
class GameState {
  GameState({
    required this.map,
    required this.hero,
    required List<Actor> monsters,
    required this.rng,
    required Set<Position> visible,
    required Set<Position> explored,
    this.isGameOver = false,
  }) : monsters = List.unmodifiable(monsters),
       visible = Set.unmodifiable(visible),
       explored = Set.unmodifiable(explored);

  final FloorMap map;
  final Actor hero;

  /// Living monsters only. The dead are removed, not flagged.
  final List<Actor> monsters;

  final Rng rng;

  /// What the hero can see from where it now stands.
  final Set<Position> visible;

  /// Every tile the hero has ever seen, drawn dimmed when out of sight.
  final Set<Position> explored;

  final bool isGameOver;

  /// The living monster standing on [position], or null when none does.
  Actor? monsterAt(Position position) {
    for (final monster in monsters) {
      if (monster.position == position) return monster;
    }
    return null;
  }

  GameState copyWith({
    Actor? hero,
    List<Actor>? monsters,
    Set<Position>? visible,
    Set<Position>? explored,
    bool? isGameOver,
  }) => GameState(
    map: map,
    hero: hero ?? this.hero,
    monsters: monsters ?? this.monsters,
    rng: rng,
    visible: visible ?? this.visible,
    explored: explored ?? this.explored,
    isGameOver: isGameOver ?? this.isGameOver,
  );
}
