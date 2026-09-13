import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:residuum_core/core.dart';

import 'dungeon_material.dart';
import 'dungeon_palette.dart';
import 'dungeon_scene_material.dart';
import 'game_bloc.dart';
import 'glyph_marks.dart';
import 'glyph_plan.dart';
import 'grid_geometry.dart';

const dungeonSceneKey = Key('dungeon-scene');
const dungeonSceneHostKey = Key('dungeon-scene-host');
const dungeonSceneSlotKey = Key('dungeon-scene-slot');

class DungeonSceneSnapshot {
  DungeonSceneSnapshot._({
    required this.columns,
    required this.rows,
    required this.cells,
    required this.material,
    required this.focus,
    required this.pan,
  });

  factory DungeonSceneSnapshot.fromViewState(
    GameViewState state,
    DungeonPalette palette,
  ) => DungeonSceneSnapshot._(
    columns: state.game.map.width,
    rows: state.game.map.height,
    cells: List.unmodifiable(
      glyphPlan(state.game, palette, markedIds: state.armedTargets),
    ),
    material: materialPlan(state.game, palette),
    focus: state.game.hero.position,
    pan: state.pan,
  );

  DungeonSceneSnapshot withViewport({
    required int columns,
    required int rows,
    required Position focus,
    required Offset pan,
  }) => DungeonSceneSnapshot._(
    columns: columns,
    rows: rows,
    cells: cells,
    material: material,
    focus: focus,
    pan: pan,
  );

  final int columns;
  final int rows;
  final List<GlyphCell> cells;

  /// The deterministic material layer beneath the glyph actors.
  final MaterialPlan material;

  final Position focus;
  final Offset pan;
}

class DungeonSceneHost extends StatefulWidget {
  const DungeonSceneHost({
    required this.state,
    required this.palette,
    required this.onTap,
    required this.onPan,
    super.key,
  });

  final GameViewState state;
  final DungeonPalette palette;
  final ValueChanged<Position> onTap;
  final ValueChanged<Offset> onPan;

  @override
  State<DungeonSceneHost> createState() => _DungeonSceneHostState();
}

class _DungeonSceneHostState extends State<DungeonSceneHost> {
  late final _DungeonScene _scene;
  late DungeonSceneSnapshot _snapshot;
  late GameState _projectionGame;
  late DungeonPalette _projectionPalette;
  late ArmedAction? _projectionArmedAction;

  @override
  void initState() {
    super.initState();
    _snapshot = DungeonSceneSnapshot.fromViewState(
      widget.state,
      widget.palette,
    );
    _rememberProjectionInputs();
    _scene = _DungeonScene(
      snapshot: _snapshot,
      onTap: widget.onTap,
      onPan: widget.onPan,
    );
  }

  @override
  void didUpdateWidget(DungeonSceneHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    _snapshot = _reusesProjection
        ? _snapshot.withViewport(
            columns: widget.state.game.map.width,
            rows: widget.state.game.map.height,
            focus: widget.state.game.hero.position,
            pan: widget.state.pan,
          )
        : DungeonSceneSnapshot.fromViewState(widget.state, widget.palette);
    _rememberProjectionInputs();
    _scene.synchronize(_snapshot, onTap: widget.onTap, onPan: widget.onPan);
  }

  bool get _reusesProjection =>
      identical(_projectionGame, widget.state.game) &&
      _projectionPalette == widget.palette &&
      _projectionArmedAction == widget.state.armedAction;

  void _rememberProjectionInputs() {
    _projectionGame = widget.state.game;
    _projectionPalette = widget.palette;
    _projectionArmedAction = widget.state.armedAction;
  }

  @override
  Widget build(BuildContext context) =>
      GameWidget(key: dungeonSceneKey, game: _scene);
}

class _DungeonScene extends FlameGame with TapCallbacks, DragCallbacks {
  _DungeonScene({
    required this._snapshot,
    required this._onTap,
    required this._onPan,
  });

  DungeonSceneSnapshot _snapshot;
  ValueChanged<Position> _onTap;
  ValueChanged<Offset> _onPan;
  final Map<GlyphRenderId, _GlyphComponent> _glyphs = {};

  MaterialComponent? _material;

  @override
  Color backgroundColor() => dungeonVoid;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.anchor = Anchor.topLeft;
    _synchronizeComponents();
  }

  @override
  void update(double dt) {
    super.update(dt);
    pauseEngine();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) _updateCamera();
  }

  void synchronize(
    DungeonSceneSnapshot snapshot, {
    required ValueChanged<Position> onTap,
    required ValueChanged<Offset> onPan,
  }) {
    final projectionChanged = !identical(_snapshot.cells, snapshot.cells);
    _snapshot = snapshot;
    _onTap = onTap;
    _onPan = onPan;
    if (isLoaded && projectionChanged) {
      _synchronizeComponents();
    } else if (isLoaded) {
      _updateCamera();
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    final position = _geometry.positionAt(
      Offset(event.canvasPosition.x, event.canvasPosition.y),
    );
    if (position != null) _onTap(position);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    _onPan(Offset(event.canvasDelta.x, event.canvasDelta.y));
  }

  GridGeometry get _geometry => GridGeometry.camera(
    Size(canvasSize.x, canvasSize.y),
    _snapshot.columns,
    _snapshot.rows,
    _snapshot.focus,
    _snapshot.pan,
  );

  void _synchronizeComponents() {
    _synchronizeMaterial();

    final cellsById = {
      for (final cell in _snapshot.cells)
        if (cell.layer != GlyphLayer.terrain) cell.renderId: cell,
    };
    final removed = <_GlyphComponent>[
      for (final entry in _glyphs.entries)
        if (!cellsById.containsKey(entry.key)) entry.value,
    ];
    world.removeAll(removed);
    _glyphs.removeWhere((id, _) => !cellsById.containsKey(id));

    final added = <_GlyphComponent>[];
    for (final cell in cellsById.values) {
      final existing = _glyphs[cell.renderId];
      if (existing == null) {
        final component = _GlyphComponent(cell);
        _glyphs[cell.renderId] = component;
        added.add(component);
      } else {
        existing.synchronize(cell);
      }
    }
    world.addAll(added);
    _updateCamera();
    if (isMounted) processLifecycleEvents();
  }

  void _synchronizeMaterial() {
    final material = _snapshot.material;
    if (_material == null) {
      _material = MaterialComponent(material);
      world.add(_material!);
    } else {
      _material!.adopt(material);
    }
  }

  void _updateCamera() {
    final origin = _geometry.origin;
    camera.viewfinder.position = Vector2(-origin.dx, -origin.dy);
    if (isAttached) renderBox.markNeedsPaint();
  }
}

class _GlyphComponent extends PositionComponent {
  _GlyphComponent(GlyphCell cell)
    : _cell = cell,
      super(
        position: _mapPosition(cell),
        size: Vector2.all(cameraCellSize),
        priority: cell.layer.index,
      ) {
    _text = TextComponent(
      text: cell.glyph,
      textRenderer: _textPaint(cell),
      anchor: Anchor.center,
      position: Vector2.all(cameraCellSize / 2),
    );
    _applyTreatment(cell);
    _updateMark(cell);
    if (glyphMarkTreatment(cell).halo) add(_halo);
    add(_text);
  }

  GlyphCell _cell;
  late final TextComponent _text;
  RectangleComponent? _mark;

  /// The hero's very small halo — a soft value contrast behind the mark so
  /// the hero reads against the stone at a glance. Shape, not hue: the halo
  /// is the cell's own ink at a whisper of alpha.
  CircleComponent get _halo => CircleComponent(
    radius: cameraCellSize * 0.42,
    position: Vector2.all(cameraCellSize / 2),
    anchor: Anchor.center,
    paint: Paint()
      ..color = _cell.ink.withValues(alpha: 0.10 + 0.06 * _cell.opacity),
  );

  void synchronize(GlyphCell cell) {
    final before = _cell;
    _cell = cell;
    position.setFrom(_mapPosition(cell));
    if (before.glyph != cell.glyph ||
        before.ink != cell.ink ||
        before.opacity != cell.opacity) {
      _text
        ..text = cell.glyph
        ..textRenderer = _textPaint(cell);
    }
    _applyTreatment(cell);
    if (before.marked != cell.marked || before.ink != cell.ink) {
      _updateMark(cell);
    }
  }

  void _applyTreatment(GlyphCell cell) {
    final treatment = glyphMarkTreatment(cell);
    _text.scale = Vector2.all(treatment.scale);
  }

  static Vector2 _mapPosition(GlyphCell cell) => Vector2(
    cell.position.x * cameraCellSize,
    cell.position.y * cameraCellSize,
  );

  static TextPaint _textPaint(GlyphCell cell) => TextPaint(
    style: TextStyle(
      color: cell.ink.withValues(alpha: cell.opacity),
      fontSize: cameraCellSize,
      fontFamily: 'monospace',
      height: 1,
    ),
  );

  void _updateMark(GlyphCell cell) {
    if (cell.marked) {
      _mark ??= RectangleComponent(
        position: Vector2.all(1),
        size: Vector2.all(cameraCellSize - 2),
        paint: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      _mark!.paint.color = cell.ink;
      if (_mark!.parent == null) add(_mark!);
    } else {
      _mark?.removeFromParent();
      _mark = null;
    }
  }
}
