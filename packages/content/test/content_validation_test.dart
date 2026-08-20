import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

void main() {
  group('the first floor', () {
    test('parses and is twenty by twelve', () {
      // arrange
      const ascii = firstFloorAscii;

      // act
      final map = FloorMap.parse(ascii);

      // assert
      expect((map.width, map.height), (20, 12));
    });

    test('every spawn stands on walkable ground', () {
      // arrange
      final map = FloorMap.parse(firstFloorAscii);
      final spawns = [heroSpawn, ...ghoulSpawns];

      // act
      final walkable = spawns.map(map.isWalkable);

      // assert
      expect(walkable, everyElement(isTrue));
    });

    test('no two actors share a spawn tile', () {
      // arrange
      final spawns = [heroSpawn, ...ghoulSpawns];

      // act
      final unique = spawns.toSet();

      // assert
      expect(unique, hasLength(spawns.length));
    });

    test('has two rooms joined by a corridor, not one open cave', () {
      // arrange
      final map = FloorMap.parse(firstFloorAscii);

      // act
      final corridor = map.isWalkable(const Position(10, 5));
      final aboveCorridor = map.isWalkable(const Position(10, 4));
      final belowCorridor = map.isWalkable(const Position(10, 6));

      // assert
      expect(corridor, isTrue);
      expect(aboveCorridor, isFalse);
      expect(belowCorridor, isFalse);
    });
  });

  group('newGame', () {
    test('arms the hero with the rusty sword', () {
      // arrange
      final game = newGame();

      // act
      final hero = game.hero;

      // assert
      expect(hero.id, 'hero');
      expect(hero.glyph, '@');
      expect(hero.position, heroSpawn);
      expect((hero.hp, hero.maxHp), (20, 20));
      expect((hero.attackMin, hero.attackMax), (3, 5));
    });

    test('places three ghouls with distinct ids', () {
      // arrange
      final game = newGame();

      // act
      final monsters = game.monsters;

      // assert
      expect(monsters, hasLength(3));
      expect(monsters.map((m) => m.id).toSet(), hasLength(3));
      expect(monsters.map((m) => m.glyph).toSet(), {'g'});
      expect(monsters.map((m) => m.hp).toSet(), {10});
      expect(monsters.map((m) => (m.attackMin, m.attackMax)).toSet(), {(2, 4)});
    });

    test(
      'starts with the hero seeing its own tile and nothing more explored',
      () {
        // arrange
        final game = newGame();

        // act
        final visible = game.visible;

        // assert
        expect(visible, contains(heroSpawn));
        expect(game.explored, visible);
        expect(game.isGameOver, isFalse);
      },
    );

    test('hides every ghoul at the start, so the dark has something in it', () {
      // arrange
      final game = newGame();

      // act
      final seen = ghoulSpawns.where(game.visible.contains);

      // assert
      expect(seen, isEmpty);
    });

    test('a ghoul reaches the hero and draws blood', () {
      // arrange
      var game = newGame();

      // act
      for (var turn = 0; turn < 60; turn++) {
        final (next, _) = step(game, const MoveAction(Direction.north));
        game = next;
        if (game.isGameOver) break;
      }

      // assert
      expect(game.hero.hp, lessThan(20));
    });

    test('the same seed produces the same crawl', () {
      // arrange
      final one = newGame(seed: 7);
      final another = newGame(seed: 7);

      // act
      final first = _play(one, 12);
      final second = _play(another, 12);

      // assert
      expect(first, second);
    });
  });
}

List<String> _play(GameState start, int turns) {
  final log = <String>[];
  var game = start;
  for (var turn = 0; turn < turns; turn++) {
    final (next, events) = step(game, const MoveAction(Direction.east));
    log.addAll(events.map((event) => event.toString()));
    game = next;
  }
  return log;
}
