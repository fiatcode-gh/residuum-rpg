import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

final _harbour = WorldNode(
  id: NodeId('harbour'),
  kind: NodeKind.town,
  name: 'Harbour',
);
final _ridge = WorldNode(
  id: NodeId('ridge'),
  kind: NodeKind.town,
  name: 'Ridge',
);
final _crypt = WorldNode(
  id: NodeId('crypt'),
  kind: NodeKind.dungeon,
  name: 'The Crypt',
);

WorldMap _triangle() => WorldMap(
  nodes: [_harbour, _ridge, _crypt],
  routes: [
    Route(from: NodeId('harbour'), to: NodeId('crypt'), days: 1, danger: 20),
    Route(from: NodeId('harbour'), to: NodeId('ridge'), days: 2, danger: 30),
    Route(from: NodeId('ridge'), to: NodeId('crypt'), days: 2, danger: 30),
  ],
);

void main() {
  group('NodeId', () {
    test('two ids spelled the same are the same id', () {
      // arrange
      final one = NodeId('crypt');

      // act
      final other = NodeId('crypt');

      // assert
      expect(one, other);
    });

    test('a name of nothing is not a place', () {
      // arrange
      const blank = '';

      // act
      NodeId make() => NodeId(blank);

      // assert
      expect(make, throwsArgumentError);
    });
  });

  group('Route', () {
    test('a road nobody can walk in a day is not a road', () {
      // arrange
      const days = 0;

      // act
      Route make() => Route(
        from: NodeId('harbour'),
        to: NodeId('crypt'),
        days: days,
        danger: 10,
      );

      // assert
      expect(make, throwsArgumentError);
    });

    test('danger is a chance in a hundred and nothing else', () {
      // arrange
      const tooDangerous = 101;

      // act
      Route make() => Route(
        from: NodeId('harbour'),
        to: NodeId('crypt'),
        days: 1,
        danger: tooDangerous,
      );

      // assert
      expect(make, throwsArgumentError);
    });

    test('a road from a place to itself is not a road', () {
      // act
      Route make() => Route(
        from: NodeId('crypt'),
        to: NodeId('crypt'),
        days: 1,
        danger: 10,
      );

      // assert
      expect(make, throwsArgumentError);
    });

    test('a road runs both ways', () {
      // arrange
      final road = Route(
        from: NodeId('harbour'),
        to: NodeId('crypt'),
        days: 1,
        danger: 20,
      );

      // act
      final joins = road.joins(NodeId('crypt'), NodeId('harbour'));

      // assert
      expect(joins, isTrue);
    });
  });

  group('WorldMap', () {
    test('a route to a place that is not on the map is refused', () {
      // act
      WorldMap make() => WorldMap(
        nodes: [_harbour, _crypt],
        routes: [
          Route(from: NodeId('harbour'), to: NodeId('nowhere'), days: 1),
        ],
      );

      // assert
      expect(make, throwsArgumentError);
    });

    test('two places filed under one id are refused', () {
      // act
      WorldMap make() => WorldMap(
        nodes: [
          _harbour,
          WorldNode(
            id: NodeId('harbour'),
            kind: NodeKind.dungeon,
            name: 'Another Harbour',
          ),
        ],
        routes: [],
      );

      // assert
      expect(make, throwsArgumentError);
    });

    test('a place no road reaches is refused', () {
      // act
      WorldMap make() => WorldMap(
        nodes: [_harbour, _ridge, _crypt],
        routes: [Route(from: NodeId('harbour'), to: NodeId('crypt'), days: 1)],
      );

      // assert
      expect(make, throwsArgumentError);
    });

    test('a world with no places at all is refused', () {
      // act
      WorldMap make() => WorldMap(nodes: [], routes: []);

      // assert
      expect(make, throwsArgumentError);
    });

    test('two roads between the same pair are refused', () {
      // act
      WorldMap make() => WorldMap(
        nodes: [_harbour, _crypt],
        routes: [
          Route(from: NodeId('harbour'), to: NodeId('crypt'), days: 1),
          Route(from: NodeId('crypt'), to: NodeId('harbour'), days: 3),
        ],
      );

      // assert
      expect(make, throwsArgumentError);
    });

    test('the triangle the game ships is sound', () {
      // act
      final map = _triangle();

      // assert
      expect(map.nodes, hasLength(3));
      expect(map.routes, hasLength(3));
    });

    test('a place answers to its id', () {
      // arrange
      final map = _triangle();

      // act
      final node = map.nodeAt(NodeId('crypt'));

      // assert
      expect(node.name, 'The Crypt');
      expect(node.kind, NodeKind.dungeon);
    });

    test('asking for a place that is not there is an error, not a null', () {
      // arrange
      final map = _triangle();

      // act
      WorldNode look() => map.nodeAt(NodeId('nowhere'));

      // assert
      expect(look, throwsArgumentError);
    });

    test('the neighbours of a place are every place one road away', () {
      // arrange
      final map = _triangle();

      // act
      final neighbours = map.adjacentTo(NodeId('crypt'));

      // assert
      expect(neighbours, {NodeId('harbour'), NodeId('ridge')});
    });

    test('the road between two places is the one that joins them', () {
      // arrange
      final map = _triangle();

      // act
      final road = map.routeBetween(NodeId('ridge'), NodeId('harbour'));

      // assert
      expect(road!.days, 2);
      expect(road.danger, 30);
    });

    test('there is no road between a place and itself', () {
      // arrange
      final map = _triangle();

      // act
      final road = map.routeBetween(NodeId('crypt'), NodeId('crypt'));

      // assert
      expect(road, isNull);
    });
  });
}
