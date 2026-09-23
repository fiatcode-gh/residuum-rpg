import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/grid_geometry.dart';
import 'package:residuum_app/game/map_touch.dart';
import 'package:residuum_core/core.dart';

/// A fixed viewport, per PLAN.md §7 (05) and the widget proof it shares a
/// geometry with: large enough to hold the open floor below without any
/// axis needing to pan, so the camera origin is the same for every test.
const _size = Size(390, 440);
const _mapSpan = 9;

Actor _heroAt(Position position) => Actor(
  id: 'hero',
  name: 'you',
  glyph: '@',
  position: position,
  hp: 20,
  maxHp: 20,
  attackMin: 4,
  attackMax: 4,
  speed: 10,
  energy: actThreshold,
);

Actor _monsterAt(Position position, {String id = 'ghoul-1'}) => Actor(
  id: id,
  name: 'the ghoul',
  glyph: 'g',
  position: position,
  hp: 10,
  maxHp: 10,
  attackMin: 3,
  attackMax: 3,
  speed: 10,
  energy: actThreshold,
);

/// A hand-built state: [monsters] are "known" exactly where [visible]
/// names, independent of field of view, so every test controls knowledge
/// directly rather than through `computeFov`.
GameViewState _state({
  required Position hero,
  List<Actor> monsters = const [],
  required Set<Position> visible,
  String? armedSpellId,
}) => GameViewState(
  game: GameState(
    map: FloorMap.parse(List.filled(_mapSpan, '.' * _mapSpan).join('\n')),
    hero: _heroAt(hero),
    monsters: monsters,
    rng: Rng(1),
    lootRng: Rng(2),
    visible: visible,
    explored: visible,
    buildFloor: (depth) => throw StateError('no floor below'),
  ),
  log: const [],
  armedSpellId: armedSpellId,
);

GridGeometry _geometry() =>
    GridGeometry.camera(_size, _mapSpan, _mapSpan, const Position(4, 4));

Matcher _cell(Position position) =>
    isA<MapTouchCell>().having((t) => t.position, 'position', position);

Matcher _inspect(String actorId) =>
    isA<MapTouchInspect>().having((t) => t.actor.id, 'actor id', actorId);

const _nothing = TypeMatcher<MapTouchNothing>();

void main() {
  group('armed tap', () {
    test('23.9 dp from a legal monster in an empty cell resolves to its '
        'cell', () {
      final monster = _monsterAt(const Position(2, 2));
      final state = _state(
        hero: const Position(6, 6),
        monsters: [monster],
        visible: {const Position(2, 2), const Position(6, 6)},
        armedSpellId: 'bolt',
      );
      final geometry = _geometry();
      final local = geometry.centreOf(monster.position) + const Offset(23.9, 0);

      expect(resolveMapTap(state, geometry, local), _cell(monster.position));
    });

    test('24.1 dp from a legal monster resolves to the cell under the '
        'finger', () {
      final monster = _monsterAt(const Position(2, 2));
      final state = _state(
        hero: const Position(6, 6),
        monsters: [monster],
        visible: {const Position(2, 2), const Position(6, 6)},
        armedSpellId: 'bolt',
      );
      final geometry = _geometry();
      final local = geometry.centreOf(monster.position) + const Offset(24.1, 0);
      final under = geometry.positionAt(local)!;

      expect(resolveMapTap(state, geometry, local), _cell(under));
    });

    test('two legal monsters equidistant in the same column resolve to the '
        'upper one', () {
      final upper = _monsterAt(const Position(2, 1), id: 'upper');
      final lower = _monsterAt(const Position(2, 3), id: 'lower');
      final state = _state(
        hero: const Position(6, 6),
        monsters: [upper, lower],
        visible: {
          const Position(2, 1),
          const Position(2, 3),
          const Position(6, 6),
        },
        armedSpellId: 'bolt',
      );
      final geometry = _geometry();
      final local = Offset.lerp(
        geometry.centreOf(upper.position),
        geometry.centreOf(lower.position),
        0.5,
      )!;

      expect(resolveMapTap(state, geometry, local), _cell(upper.position));
    });

    test('two legal monsters equidistant in the same row resolve to the '
        'left one', () {
      final left = _monsterAt(const Position(1, 2), id: 'left');
      final right = _monsterAt(const Position(3, 2), id: 'right');
      final state = _state(
        hero: const Position(6, 6),
        monsters: [left, right],
        visible: {
          const Position(1, 2),
          const Position(3, 2),
          const Position(6, 6),
        },
        armedSpellId: 'bolt',
      );
      final geometry = _geometry();
      final local = Offset.lerp(
        geometry.centreOf(left.position),
        geometry.centreOf(right.position),
        0.5,
      )!;

      expect(resolveMapTap(state, geometry, local), _cell(left.position));
    });

    test('a touch on a legal monster own cell wins over the tie-broken '
        'neighbour', () {
      final under = _monsterAt(const Position(6, 5), id: 'under');
      final tieBreakWinner = _monsterAt(const Position(5, 5), id: 'tie');
      final state = _state(
        hero: const Position(0, 0),
        monsters: [under, tieBreakWinner],
        visible: {const Position(6, 5), const Position(5, 5)},
        armedSpellId: 'bolt',
      );
      final geometry = _geometry();

      /// Exactly on the shared boundary: equidistant from both centres,
      /// but `positionAt` floors it onto `under`'s cell.
      final local =
          geometry.centreOf(tieBreakWinner.position) +
          Offset(geometry.cellWidth / 2, 0);
      expect(geometry.positionAt(local), under.position);

      expect(resolveMapTap(state, geometry, local), _cell(under.position));
    });
  });

  group('unarmed tap', () {
    test('touch on an orthogonally adjacent monster cell resolves to the '
        'cell (melee)', () {
      const hero = Position(4, 4);
      final monster = _monsterAt(const Position(5, 4));
      final state = _state(
        hero: hero,
        monsters: [monster],
        visible: {hero, monster.position},
      );
      final geometry = _geometry();
      final local = geometry.centreOf(monster.position);

      expect(resolveMapTap(state, geometry, local), _cell(monster.position));
    });

    test('touch on a far known monster cell resolves to inspect', () {
      const hero = Position(4, 4);
      final monster = _monsterAt(const Position(7, 4));
      final state = _state(
        hero: hero,
        monsters: [monster],
        visible: {hero, monster.position},
      );
      final geometry = _geometry();
      final local = geometry.centreOf(monster.position);

      expect(resolveMapTap(state, geometry, local), _inspect(monster.id));
    });

    test('20 dp from a far monster in an empty non-neighbour cell resolves to '
        'inspect', () {
      const hero = Position(4, 4);
      final monster = _monsterAt(const Position(7, 4));
      final state = _state(
        hero: hero,
        monsters: [monster],
        visible: {hero, monster.position},
      );
      final geometry = _geometry();
      final local = geometry.centreOf(monster.position) + const Offset(20, 0);
      final under = geometry.positionAt(local)!;
      expect(under.isOrthogonallyAdjacentTo(hero), isFalse);
      expect(under, isNot(monster.position));

      expect(resolveMapTap(state, geometry, local), _inspect(monster.id));
    });

    test('23.9 dp from a known monster in an empty cell resolves to '
        'inspect', () {
      final monster = _monsterAt(const Position(2, 2));
      final state = _state(
        hero: const Position(6, 6),
        monsters: [monster],
        visible: {const Position(2, 2), const Position(6, 6)},
      );
      final geometry = _geometry();
      final local = geometry.centreOf(monster.position) + const Offset(23.9, 0);
      final under = geometry.positionAt(local)!;
      expect(under.isOrthogonallyAdjacentTo(const Position(6, 6)), isFalse);
      expect(under, isNot(monster.position));

      expect(resolveMapTap(state, geometry, local), _inspect(monster.id));
    });

    test('24.1 dp from a known monster resolves to the cell under the '
        'finger, not inspect', () {
      final monster = _monsterAt(const Position(2, 2));
      final state = _state(
        hero: const Position(6, 6),
        monsters: [monster],
        visible: {const Position(2, 2), const Position(6, 6)},
      );
      final geometry = _geometry();
      final local = geometry.centreOf(monster.position) + const Offset(24.1, 0);
      final under = geometry.positionAt(local)!;
      expect(under.isOrthogonallyAdjacentTo(const Position(6, 6)), isFalse);

      expect(resolveMapTap(state, geometry, local), _cell(under));
    });

    test('a monster two cells east: touch on the east neighbour cell resolves '
        'to that cell (step-cell guard)', () {
      const hero = Position(4, 4);
      final monster = _monsterAt(const Position(6, 4));
      final state = _state(
        hero: hero,
        monsters: [monster],
        visible: {hero, monster.position},
      );
      final geometry = _geometry();
      const neighbour = Position(5, 4);
      final local = geometry.centreOf(neighbour);

      expect(resolveMapTap(state, geometry, local), _cell(neighbour));
    });

    test('a touch in a diagonal neighbour within 24 dp of the hero steps the '
        'dominant axis, horizontal winning an exact diagonal', () {
      const hero = Position(4, 4);
      final state = _state(hero: hero, visible: {hero});
      final geometry = _geometry();
      final heroCentre = geometry.centreOf(hero);
      final local =
          heroCentre + Offset(0.9 * mapCellWidth, 0.9 * mapCellHeight);
      final under = geometry.positionAt(local)!;
      expect(under, const Position(5, 5));
      expect((local - heroCentre).distance, lessThanOrEqualTo(24));

      expect(
        resolveMapTap(state, geometry, local),
        _cell(const Position(5, 4)),
      );
    });

    test('a touch 23.9 dp from the hero on the diagonal steps the dominant '
        'axis', () {
      const hero = Position(4, 4);
      final state = _state(hero: hero, visible: {hero});
      final geometry = _geometry();
      final heroCentre = geometry.centreOf(hero);
      final local = heroCentre + Offset.fromDirection(math.pi / 4, 23.9);
      final under = geometry.positionAt(local)!;
      expect(under.isOrthogonallyAdjacentTo(hero), isFalse);
      expect((local - heroCentre).distance, lessThanOrEqualTo(mapTouchRadius));

      expect(
        resolveMapTap(state, geometry, local),
        _cell(hero.step(Direction.east)),
      );
    });

    test('a touch 24.1 dp from the hero on the same diagonal falls through '
        'to the cell under the finger instead of stepping', () {
      const hero = Position(4, 4);
      final state = _state(hero: hero, visible: {hero});
      final geometry = _geometry();
      final heroCentre = geometry.centreOf(hero);
      final local = heroCentre + Offset.fromDirection(math.pi / 4, 24.1);
      final under = geometry.positionAt(local)!;
      expect(under.isOrthogonallyAdjacentTo(hero), isFalse);
      expect((local - heroCentre).distance, greaterThan(mapTouchRadius));
      expect(under, isNot(hero.step(Direction.east)));

      expect(resolveMapTap(state, geometry, local), _cell(under));
    });

    test('the hero at the map west edge: a touch 15 dp west of it falls '
        'through instead of stepping out of bounds', () {
      const hero = Position(0, 5);
      final state = _state(hero: hero, visible: {hero});
      final geometry = _geometry();
      final local = geometry.centreOf(hero) + const Offset(-15, 0);
      expect(geometry.positionAt(local), isNull);

      expect(resolveMapTap(state, geometry, local), _nothing);
    });

    test('a touch 30 dp east of the hero resolves to the cell under the '
        'finger', () {
      const hero = Position(0, 5);
      final state = _state(hero: hero, visible: {hero});
      final geometry = _geometry();
      final local = geometry.centreOf(hero) + const Offset(30, 0);
      final under = geometry.positionAt(local)!;

      expect(resolveMapTap(state, geometry, local), _cell(under));
    });

    test('an unknown, not-visible monster within 5 dp is ignored: the tap '
        'resolves as an ordinary cell tap', () {
      const hero = Position(4, 4);
      final unknown = _monsterAt(const Position(6, 6));
      final state = _state(
        hero: hero,
        monsters: [unknown],

        /// The monster's own tile is deliberately excluded, so it is not
        /// known even though it stands there.
        visible: {hero},
      );
      final geometry = _geometry();
      final local = geometry.centreOf(unknown.position) + const Offset(5, 0);
      final under = geometry.positionAt(local)!;
      expect(under, unknown.position);

      expect(resolveMapTap(state, geometry, local), _cell(unknown.position));
    });

    test('a touch outside the grid with nothing within 24 dp resolves to '
        'nothing', () {
      const hero = Position(4, 4);
      final state = _state(hero: hero, visible: {hero});
      final geometry = _geometry();
      const local = Offset(5, 5);
      expect(geometry.positionAt(local), isNull);

      expect(resolveMapTap(state, geometry, local), _nothing);
    });
  });

  group('long-press', () {
    test('under a known monster resolves to inspect', () {
      const hero = Position(6, 6);
      final monster = _monsterAt(const Position(2, 2));
      final state = _state(
        hero: hero,
        monsters: [monster],
        visible: {hero, monster.position},
      );
      final geometry = _geometry();
      final local = geometry.centreOf(monster.position);

      expect(resolveMapLongPress(state, geometry, local), _inspect(monster.id));
    });

    test('the nearest known monster within 24 dp resolves to inspect', () {
      const hero = Position(6, 6);
      final monster = _monsterAt(const Position(2, 2));
      final state = _state(
        hero: hero,
        monsters: [monster],
        visible: {hero, monster.position},
      );
      final geometry = _geometry();
      final local = geometry.centreOf(monster.position) + const Offset(23.9, 0);

      expect(resolveMapLongPress(state, geometry, local), _inspect(monster.id));
    });

    test('24.1 dp from the nearest known monster resolves to nothing', () {
      const hero = Position(6, 6);
      final monster = _monsterAt(const Position(2, 2));
      final state = _state(
        hero: hero,
        monsters: [monster],
        visible: {hero, monster.position},
      );
      final geometry = _geometry();
      final local = geometry.centreOf(monster.position) + const Offset(24.1, 0);

      expect(resolveMapLongPress(state, geometry, local), _nothing);
    });
  });
}
