import 'package:flame/camera.dart' show MaxViewport;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:residuum_core/core.dart';

import '../style/tokens.dart'
    show crawlBackground, crawlEnemyHigh, mapBadgeStyle, mapGlyphStyle;
import 'actor_presentation.dart';
import 'dungeon_palette.dart';

import 'game_bloc.dart';
import 'glyph_marks.dart';
import 'glyph_plan.dart';
import 'grid_geometry.dart';
import 'dungeon_depth.dart';

const dungeonSceneKey = Key('dungeon-scene');
const dungeonSceneHostKey = Key('dungeon-scene-host');
const dungeonSceneSlotKey = Key('dungeon-scene-slot');

class DungeonSceneSnapshot {
  DungeonSceneSnapshot._({
    required this.columns,
    required this.rows,
    required this.cells,
    required this.focus,
    required this.pan,
    required this.heroPosition,
  });

  factory DungeonSceneSnapshot.fromViewState(GameViewState state) =>
      DungeonSceneSnapshot._(
        columns: state.game.map.width,
        rows: state.game.map.height,
        cells: List.unmodifiable(
          glyphPlan(
            state.game,
            markedIds: state.armedTargets,
            actorPresentations: state.actorIdentity.knownActors,
            selectedActorId: state.selectedActor?.id,
          ),
        ),

        focus: state.cameraFocus,
        heroPosition: state.game.hero.position,
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
    focus: focus,
    pan: pan,
    heroPosition: heroPosition,
  );

  final int columns;
  final int rows;
  final List<GlyphCell> cells;

  final Position focus;
  final Offset pan;
  final Position heroPosition;
}

class DungeonSceneHost extends StatefulWidget {
  const DungeonSceneHost({
    required this.state,
    required this.palette,
    required this.onTap,
    required this.onPan,
    required this.onLongPress,
    super.key,
  });

  final GameViewState state;
  final DungeonPalette palette;
  final ValueChanged<Position> onTap;
  final ValueChanged<Offset> onPan;

  /// The tile a completed long-press landed on: the inspect gesture.
  final ValueChanged<Position> onLongPress;

  @override
  State<DungeonSceneHost> createState() => _DungeonSceneHostState();
}

class _DungeonSceneHostState extends State<DungeonSceneHost> {
  late final _DungeonScene _scene;
  late DungeonSceneSnapshot _snapshot;
  late GameState _projectionGame;
  late ActorIdentityContext _projectionActorIdentity;
  late String? _projectionSelectedActorId;
  late String? _projectionArmedSpellId;

  @override
  void initState() {
    super.initState();
    _snapshot = DungeonSceneSnapshot.fromViewState(widget.state);
    _rememberProjectionInputs();
    _scene = _DungeonScene(
      snapshot: _snapshot,
      onTap: widget.onTap,
      onPan: widget.onPan,
      onLongPress: widget.onLongPress,
    );
  }

  @override
  void didUpdateWidget(DungeonSceneHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    _snapshot = _reusesProjection
        ? _snapshot.withViewport(
            columns: widget.state.game.map.width,
            rows: widget.state.game.map.height,
            focus: widget.state.cameraFocus,
            pan: widget.state.pan,
          )
        : DungeonSceneSnapshot.fromViewState(widget.state);
    _rememberProjectionInputs();
    _scene.synchronize(
      _snapshot,
      onTap: widget.onTap,
      onPan: widget.onPan,
      onLongPress: widget.onLongPress,
    );
  }

  bool get _reusesProjection =>
      identical(_projectionGame, widget.state.game) &&
      _projectionArmedSpellId == widget.state.armedSpellId &&
      identical(_projectionActorIdentity, widget.state.actorIdentity) &&
      _projectionSelectedActorId == widget.state.selectedActorId;

  void _rememberProjectionInputs() {
    _projectionGame = widget.state.game;
    _projectionActorIdentity = widget.state.actorIdentity;
    _projectionSelectedActorId = widget.state.selectedActorId;
    _projectionArmedSpellId = widget.state.armedSpellId;
  }

  @override
  Widget build(BuildContext context) => GameWidget(
    key: dungeonSceneKey,
    game: _scene,
    backgroundBuilder: (_) => IgnorePointer(
      ignoring: true,
      child: ExcludeSemantics(
        child: CustomPaint(
          painter: const DungeonDepthPainter(),
          child: const SizedBox.expand(),
        ),
      ),
    ),
  );
}

/// The default [MaxViewport] fills all available space, exactly like this
/// one, but its own dartdoc admits it "does not perform any clipping" — nor
/// does Flame's `GameRenderBox.paint` clip on its behalf. Nothing in
/// Flame's render pipeline confines a game's paint to the viewport's own
/// reported size; it is only ever used to position the camera.
/// `_DungeonScene`'s [World] holds the glyph-plan cells in the current
/// floor's `visible ∪ explored` set, which is routinely taller than the box
/// the crawl's `Column` gives the map. This subclass adds exactly the clip
/// [MaxViewport] omits — nothing else about its size tracking changes.
class _ClippedMaxViewport extends MaxViewport {
  Rect _clipRect = Rect.zero;

  @override
  void clip(Canvas canvas) => canvas.clipRect(_clipRect, doAntiAlias: false);

  @override
  bool containsLocalPoint(Vector2 point) =>
      point.x >= 0 && point.x <= size.x && point.y >= 0 && point.y <= size.y;

  @override
  void onViewportResize() {
    _clipRect = Rect.fromLTWH(0, 0, size.x, size.y);
  }
}

class _DungeonScene extends FlameGame
    with TapCallbacks, DragCallbacks, LongPressCallbacks {
  _DungeonScene({
    required this._snapshot,
    required this._onTap,
    required this._onPan,
    required this._onLongPress,
  }) : super(camera: CameraComponent(viewport: _ClippedMaxViewport()));

  DungeonSceneSnapshot _snapshot;
  ValueChanged<Position> _onTap;
  ValueChanged<Offset> _onPan;
  ValueChanged<Position> _onLongPress;
  final Map<GlyphRenderId, _GlyphComponent> _glyphs = {};

  @override
  Color backgroundColor() => crawlBackground;

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
    required ValueChanged<Position> onLongPress,
  }) {
    final projectionChanged = !identical(_snapshot.cells, snapshot.cells);
    final lightOriginChanged = _snapshot.heroPosition != snapshot.heroPosition;
    _snapshot = snapshot;
    _onTap = onTap;
    _onPan = onPan;
    _onLongPress = onLongPress;
    if (isLoaded && (projectionChanged || lightOriginChanged)) {
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

  @override
  void onLongPressStart(LongPressStartEvent event) {
    super.onLongPressStart(event);
    final position = _geometry.positionAt(
      Offset(event.canvasPosition.x, event.canvasPosition.y),
    );
    if (position != null) _onLongPress(position);
  }

  GridGeometry get _geometry => GridGeometry.camera(
    Size(canvasSize.x, canvasSize.y),
    _snapshot.columns,
    _snapshot.rows,
    _snapshot.focus,
    _snapshot.pan,
  );

  void _synchronizeComponents() {
    final cellsById = {for (final cell in _snapshot.cells) cell.renderId: cell};
    final removed = <_GlyphComponent>[
      for (final entry in _glyphs.entries)
        if (!cellsById.containsKey(entry.key)) entry.value,
    ];
    world.removeAll(removed);
    _glyphs.removeWhere((id, _) => !cellsById.containsKey(id));

    final added = <_GlyphComponent>[];
    for (final cell in cellsById.values) {
      final treatment = glyphMarkTreatment(cell);
      final ink = glyphInk(cell, _snapshot.heroPosition);
      final existing = _glyphs[cell.renderId];
      if (existing == null) {
        final component = _GlyphComponent(cell, treatment, ink);
        _glyphs[cell.renderId] = component;
        added.add(component);
      } else {
        existing.synchronize(cell, treatment, ink);
      }
    }
    world.addAll(added);
    _updateCamera();
    if (isMounted) processLifecycleEvents();
  }

  void _updateCamera() {
    final origin = _geometry.origin;
    camera.viewfinder.position = Vector2(-origin.dx, -origin.dy);
    if (isAttached) renderBox.markNeedsPaint();
  }
}

class _GlyphComponent extends PositionComponent {
  _GlyphComponent(GlyphCell cell, GlyphMarkTreatment treatment, Color ink)
    : _cell = cell,
      _ink = ink,
      super(
        position: _mapPosition(cell),
        size: Vector2(mapCellWidth, mapCellHeight),
        priority: cell.layer.index,
      ) {
    _text = TextComponent(
      text: cell.glyph,
      textRenderer: _textPaint(ink),
      anchor: Anchor.center,
      position: Vector2(mapCellWidth / 2, mapCellHeight / 2),
    );
    _applyTreatment(treatment);
    _updateReticle(treatment);
    if (treatment.halo) add(_halo);
    add(_text);
    _updateBadge(cell);
  }

  GlyphCell _cell;
  Color _ink;
  late final TextComponent _text;
  TextComponent? _badge;
  _ReticleComponent? _reticle;

  /// The hero's very small halo — a soft value contrast behind the mark so
  /// the hero reads against the stone at a glance. Shape, not hue: the halo
  /// is the cell's own ink at a whisper of alpha.
  CircleComponent get _halo => CircleComponent(
    radius: mapCellWidth * 0.5,
    position: Vector2(mapCellWidth / 2, mapCellHeight / 2),
    anchor: Anchor.center,
    paint: Paint()
      ..color = _cell.ink.withValues(alpha: 0.10 + 0.06 * _cell.opacity),
  );

  void synchronize(GlyphCell cell, GlyphMarkTreatment treatment, Color ink) {
    final before = _cell;
    final beforeInk = _ink;
    _cell = cell;
    _ink = ink;
    position.setFrom(_mapPosition(cell));
    if (before.glyph != cell.glyph ||
        beforeInk != ink ||
        before.opacity != cell.opacity) {
      _text
        ..text = cell.glyph
        ..textRenderer = _textPaint(ink);
    }
    _applyTreatment(treatment);
    if (before.badge != cell.badge ||
        beforeInk != ink ||
        before.opacity != cell.opacity) {
      _updateBadge(cell);
    }
    if (before.marked != cell.marked || before.selected != cell.selected) {
      _updateReticle(treatment);
    }
  }

  void _applyTreatment(GlyphMarkTreatment treatment) {
    _text.scale = Vector2.all(treatment.scale);
  }

  static Vector2 _mapPosition(GlyphCell cell) =>
      Vector2(cell.position.x * mapCellWidth, cell.position.y * mapCellHeight);

  static TextPaint _textPaint(Color ink) =>
      TextPaint(style: mapGlyphStyle(ink));

  static TextPaint _badgePaint(Color ink) =>
      TextPaint(style: mapBadgeStyle(ink));

  void _updateBadge(GlyphCell cell) {
    final badge = cell.badge;
    if (badge == null) {
      _badge?.removeFromParent();
      _badge = null;
      return;
    }
    _badge ??= TextComponent(
      text: badge,
      textRenderer: _badgePaint(_ink),
      anchor: Anchor.topRight,
      position: Vector2(mapCellWidth - 0.5, 0.5),
    );
    _badge!
      ..text = badge
      ..textRenderer = _badgePaint(_ink);
    if (_badge!.parent == null) add(_badge!);
  }

  void _updateReticle(GlyphMarkTreatment treatment) {
    final mark = treatment.targetMark;
    if (mark == null) {
      _reticle?.removeFromParent();
      _reticle = null;
      return;
    }
    if (_reticle == null) {
      _reticle = _ReticleComponent(mark);
      add(_reticle!);
    } else {
      _reticle!.synchronize(mark);
    }
  }
}

/// Draws the corner-tick or bracket reticle PLAN.md G6 defines, inside the
/// cell so its arms never bleed into the neighbour.
///
/// One component handles both shapes: ticks and brackets never coexist on
/// the same cell (selection supersedes marking), so switching [_mark] is
/// cheaper than swapping components in and out.
class _ReticleComponent extends PositionComponent {
  _ReticleComponent(GlyphTargetMark mark)
    : _mark = mark,
      super(size: Vector2(mapCellWidth, mapCellHeight));

  GlyphTargetMark _mark;

  static const Rect _rect = Rect.fromLTWH(0.75, 0.75, 11.5, 14.5);
  static const double _armLength = 3.5;

  static final Paint _ticksPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0
    ..color = crawlEnemyHigh;
  static final Paint _bracketsPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.75
    ..color = crawlEnemyHigh;

  void synchronize(GlyphTargetMark mark) => _mark = mark;

  @override
  void render(Canvas canvas) {
    switch (_mark) {
      case GlyphTargetMark.ticks:
        canvas.drawPath(_ticksPath(), _ticksPaint);
      case GlyphTargetMark.brackets:
        canvas.drawPath(_bracketsPath(), _bracketsPaint);
    }
  }

  static Path _ticksPath() => Path()
    ..moveTo(_rect.left, _rect.top + _armLength)
    ..lineTo(_rect.left, _rect.top)
    ..lineTo(_rect.left + _armLength, _rect.top)
    ..moveTo(_rect.right - _armLength, _rect.top)
    ..lineTo(_rect.right, _rect.top)
    ..lineTo(_rect.right, _rect.top + _armLength)
    ..moveTo(_rect.right, _rect.bottom - _armLength)
    ..lineTo(_rect.right, _rect.bottom)
    ..lineTo(_rect.right - _armLength, _rect.bottom)
    ..moveTo(_rect.left + _armLength, _rect.bottom)
    ..lineTo(_rect.left, _rect.bottom)
    ..lineTo(_rect.left, _rect.bottom - _armLength);

  static Path _bracketsPath() => Path()
    ..moveTo(_rect.left + _armLength, _rect.top)
    ..lineTo(_rect.left, _rect.top)
    ..lineTo(_rect.left, _rect.bottom)
    ..lineTo(_rect.left + _armLength, _rect.bottom)
    ..moveTo(_rect.right - _armLength, _rect.top)
    ..lineTo(_rect.right, _rect.top)
    ..lineTo(_rect.right, _rect.bottom)
    ..lineTo(_rect.right - _armLength, _rect.bottom);
}
