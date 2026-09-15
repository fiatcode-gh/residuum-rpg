import 'package:flutter/material.dart' hide Route;
import 'package:flutter/semantics.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../town/town_style.dart';

class WorldRouteDiagram extends StatelessWidget {
  const WorldRouteDiagram({
    required this.map,
    required this.whereabouts,
    required this.destinations,
    required this.dangerFor,
    required this.onDestination,
    super.key,
  });

  final WorldMap map;
  final Whereabouts whereabouts;
  final Set<NodeId> destinations;
  final int Function(Route) dangerFor;
  final ValueChanged<WorldNode> onDestination;

  static const _height = 430.0;
  static const _nodeWidth = 120.0;
  static const _nodeHeight = 72.0;
  static final _nodeIds = [
    seaCave,
    ruinedKeep,
    northgate,
    cryptNode,
    stonebridge,
  ];

  @override
  Widget build(BuildContext context) {
    _validateMap();
    final nodes = {for (final node in map.nodes) node.id: node};
    final projectedRoutes = <_ProjectedRoute>[];
    final journey = whereabouts.journey;
    for (final route in map.routes) {
      if (!whereabouts.discovered.contains(route.from) ||
          !whereabouts.discovered.contains(route.to)) {
        continue;
      }
      final from = nodes[route.from];
      final to = nodes[route.to];
      if (from == null || to == null) {
        throw StateError('world route endpoint is missing from the map');
      }
      final labelCenter = _routeLabelCenter(route);
      final danger = dangerFor(route);
      projectedRoutes.add(
        _ProjectedRoute(
          route: route,
          from: from,
          to: to,
          danger: danger,
          labelCenter: labelCenter,
          active: journey != null && route.joins(journey.from, journey.to),
        ),
      );
    }

    return SizedBox(
      height: _height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 430.0;
          final size = Size(width, _height);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _RoutePainter(projectedRoutes)),
              ),
              for (final projected in projectedRoutes)
                _routeLabel(projected, size),
              for (var index = 0; index < _nodeIds.length; index++)
                _nodeSlot(map.nodeAt(_nodeIds[index]), size, index),
            ],
          );
        },
      ),
    );
  }

  Widget _routeLabel(_ProjectedRoute projected, Size size) {
    final center = _offset(projected.labelCenter, size);
    final dayWord = projected.route.days == 1 ? 'DAY' : 'DAYS';
    final active = projected.active;
    final visible = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${projected.route.days} $dayWord',
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            color: ink,
          ),
          maxLines: 1,
          overflow: TextOverflow.clip,
        ),
        if (active)
          const Text(
            'ON THIS ROAD',
            style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: ink),
            maxLines: 1,
          ),
        Text(
          'DANGER ${projected.danger}/100',
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            color: dim,
          ),
          maxLines: 1,
          overflow: TextOverflow.clip,
        ),
      ],
    );
    final days = projected.route.days;
    final from = projected.from.name;
    final to = projected.to.name;
    final journey = whereabouts.journey;
    final journeyText = active && journey != null
        ? ' You are on this road. ${journey.daysLeft} day(s) remain.'
        : '';
    return Positioned(
      left: center.dx - 64,
      top: center.dy - 24,
      width: 128,
      height: 48,
      child: Semantics(
        container: true,
        sortKey: OrdinalSortKey(_routeOrder(projected.route).toDouble()),
        label:
            'Route from $from to $to. $days day(s). Current danger '
            '${projected.danger} in 100.$journeyText',
        child: ExcludeSemantics(child: Center(child: visible)),
      ),
    );
  }

  Widget _nodeSlot(WorldNode node, Size size, int index) {
    final discovered = whereabouts.discovered.contains(node.id);
    final center = _offset(_nodeCenter(node.id), size);
    final rect = Rect.fromCenter(
      center: center,
      width: _nodeWidth,
      height: _nodeHeight,
    );
    if (!discovered) {
      return Positioned(
        key: ValueKey('world-node-${node.id.value}'),
        left: rect.left,
        top: rect.top,
        width: _nodeWidth,
        height: _nodeHeight,
        child: Semantics(
          container: true,
          sortKey: OrdinalSortKey((index + 10).toDouble()),
          label: 'Unknown location. Not discovered.',
          child: const ExcludeSemantics(child: _UnknownMarker()),
        ),
      );
    }

    final journey = whereabouts.journey;
    final here = journey == null && node.id == whereabouts.at;
    final reachable = destinations.contains(node.id);
    final state = journey != null
        ? 'TRAVEL IN PROGRESS'
        : here
        ? 'HERE'
        : reachable
        ? 'REACHABLE'
        : 'NO ROAD FROM HERE';
    final enabled = journey == null && reachable;
    final label =
        '${_kindLabel(node.kind)} ${node.name}. ${_stateLabel(state)}.';
    final activate = enabled ? () => onDestination(node) : null;
    final child = GestureDetector(
      onTap: activate,
      child: _MarkerShape(
        key: ValueKey('world-node-${node.id.value}-shape'),
        kind: node.kind,
        selected: here,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _kindWord(node.kind),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                color: dim,
              ),
            ),
            Text(
              node.name,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: ink,
              ),
              maxLines: 1,
              overflow: TextOverflow.clip,
            ),
            Text(
              state,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                color: dim,
              ),
              maxLines: 1,
              overflow: TextOverflow.clip,
            ),
          ],
        ),
      ),
    );
    return Positioned(
      key: ValueKey('world-node-${node.id.value}'),
      left: rect.left,
      top: rect.top,
      width: _nodeWidth,
      height: _nodeHeight,
      child: Semantics(
        button: true,
        enabled: enabled,
        selected: here,
        sortKey: OrdinalSortKey((index + 10).toDouble()),
        label: label,
        onTap: activate,
        child: ExcludeSemantics(child: child),
      ),
    );
  }

  void _validateMap() {
    final ids = map.nodes.map((node) => node.id).toSet();
    if (ids.length != _nodeIds.length ||
        !_nodeIds.every(ids.contains) ||
        map.nodes.length != _nodeIds.length) {
      throw StateError('world route diagram requires the shipped five nodes');
    }
    if (map.routes.length != _routeOrders.length ||
        map.routes.map(_routeOrder).toSet().length != _routeOrders.length ||
        !_routeOrders.every(
          (order) => map.routes.any((route) => _routeOrder(route) == order),
        )) {
      throw StateError('world route diagram requires the shipped five routes');
    }
  }

  static const _routeOrders = {0, 1, 2, 3, 4};

  static String _kindWord(NodeKind kind) => switch (kind) {
    NodeKind.town => 'TOWN',
    NodeKind.dungeon => 'DUNGEON',
  };
  static String _kindLabel(NodeKind kind) => switch (kind) {
    NodeKind.town => 'Town',
    NodeKind.dungeon => 'Dungeon',
  };
  static String _stateLabel(String state) => switch (state) {
    'HERE' => 'Here',
    'REACHABLE' => 'Reachable',
    'NO ROAD FROM HERE' => 'No road from here',
    'TRAVEL IN PROGRESS' => 'Travel in progress',
    _ => throw StateError('world route diagram has an unknown node state'),
  };

  static Offset _nodeCenter(NodeId id) => switch (id.value) {
    'sea-cave' => const Offset(0.20, 0.12),
    'ruined-keep' => const Offset(0.80, 0.12),
    'northgate' => const Offset(0.50, 0.39),
    'crypt' => const Offset(0.74, 0.68),
    'stonebridge' => const Offset(0.26, 0.84),
    _ => throw StateError('world route diagram has an unknown node id'),
  };

  static int _routeOrder(Route route) {
    final key = {route.from.value, route.to.value};
    if (key.contains('sea-cave') && key.contains('northgate')) return 0;
    if (key.contains('ruined-keep') && key.contains('northgate')) return 1;
    if (key.contains('stonebridge') && key.contains('northgate')) return 2;
    if (key.contains('northgate') && key.contains('crypt')) return 3;
    if (key.contains('stonebridge') && key.contains('crypt')) return 4;
    throw StateError('world route diagram has an unknown route');
  }

  static Offset _routeLabelCenter(Route route) => switch (_routeOrder(route)) {
    0 => const Offset(0.33, 0.24),
    1 => const Offset(0.67, 0.24),
    2 => const Offset(0.37, 0.58),
    3 => const Offset(0.63, 0.54),
    4 => const Offset(0.56, 0.82),
    _ => throw StateError('world route diagram has an unknown route'),
  };

  static Offset _offset(Offset fraction, Size size) =>
      Offset(fraction.dx * size.width, fraction.dy * size.height);
}

class _ProjectedRoute {
  const _ProjectedRoute({
    required this.route,
    required this.from,
    required this.to,
    required this.danger,
    required this.labelCenter,
    required this.active,
  });

  final Route route;
  final WorldNode from;
  final WorldNode to;
  final int danger;
  final Offset labelCenter;
  final bool active;
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter(this.routes);

  static final _neutralPaint = Paint()
    ..color = rule
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke;
  static final _activeOuterPaint = Paint()
    ..color = rule
    ..strokeWidth = 7
    ..style = PaintingStyle.stroke;
  static final _activeInnerPaint = Paint()
    ..color = ink
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke;

  final List<_ProjectedRoute> routes;

  @override
  void paint(Canvas canvas, Size size) {
    for (final projected in routes) {
      final from = WorldRouteDiagram._offset(
        WorldRouteDiagram._nodeCenter(projected.route.from),
        size,
      );
      final to = WorldRouteDiagram._offset(
        WorldRouteDiagram._nodeCenter(projected.route.to),
        size,
      );
      if (projected.active) {
        canvas
          ..drawLine(from, to, _activeOuterPaint)
          ..drawLine(from, to, _activeInnerPaint);
      } else {
        canvas.drawLine(from, to, _neutralPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_RoutePainter oldDelegate) => true;
}

class _UnknownMarker extends StatelessWidget {
  const _UnknownMarker();

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: const ShapeDecoration(
        color: panel,
        shape: CircleBorder(side: BorderSide(color: rule)),
      ),
      child: const Text('?', style: mono),
    ),
  );
}

class _MarkerShape extends StatelessWidget {
  const _MarkerShape({
    required this.kind,
    required this.child,
    this.selected = false,
    super.key,
  });

  final NodeKind kind;
  final Widget child;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    ShapeBorder outline(Color color) => kind == NodeKind.town
        ? RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2),
            side: BorderSide(color: color),
          )
        : StadiumBorder(side: BorderSide(color: color));
    final marker = Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: ShapeDecoration(color: panel, shape: outline(rule)),
      child: child,
    );
    if (!selected) return marker;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: ShapeDecoration(shape: outline(ink)),
      child: marker,
    );
  }
}
