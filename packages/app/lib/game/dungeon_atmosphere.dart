import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../style/tokens.dart' show crawlBackground, crawlHero, crawlTorch;
import 'dungeon_scene.dart' show DungeonSceneSnapshot;
import 'grid_geometry.dart';

/// Fraction of camera-origin movement the backdrop's fog layer follows
/// (PLAN.md G5). Small on purpose: the backdrop reads as distant, so it
/// should barely move against a pan that moves the whole map.
const double parallaxFactor = 0.12;

/// The largest distance, in dp, the fog layer may drift from its resting
/// position in either axis.
const double parallaxLimit = 40;

/// Per-axis parallax drift for the fog layer, bounded to
/// [-parallaxLimit, parallaxLimit] (PLAN.md G5).
Offset backdropDrift(Offset cameraOrigin) => Offset(
  (cameraOrigin.dx * parallaxFactor).clamp(-parallaxLimit, parallaxLimit),
  (cameraOrigin.dy * parallaxFactor).clamp(-parallaxLimit, parallaxLimit),
);

/// Fixed salt for the fog field's hash so it never depends on gameplay
/// `Rng` (PLAN.md G5, contract "Determinism").
const int fogSalt = 0x5E5D1DE;

/// A deterministic pseudo-random value in `[0, 1)` for one fog lattice
/// point's channel, hashed from screen-space coordinates and [fogSalt]
/// only — never from gameplay state (PLAN.md G5).
double fogHash(int ix, int iy, int channel) {
  var h =
      ((ix * 0x27d4eb2d) ^
          (iy * 0x165667b1) ^
          (channel * 0x9e3779b9) ^
          fogSalt) &
      0xFFFFFFFF;
  h = ((h ^ (h >> 15)) * 0x2c1b3c6d) & 0xFFFFFFFF;
  h = ((h ^ (h >> 12)) * 0x297a2d39) & 0xFFFFFFFF;
  h ^= h >> 15;
  return (h & 0xFFFFFF) / 0x1000000;
}

const double _fogLatticeSpacing = 56;
const double _fogDiscRadius = 72.8;
const double _torchPoolRadius = 6 * mapCellWidth;
const double _heroBloomRadius = 1.6 * mapCellWidth;
const Color _vignetteColor = Color(0xFF020406);

/// The map viewport's backdrop: near-black base, deterministic fog, and a
/// vignette (PLAN.md G5, contract settled decision 4). Painted beneath the
/// Flame surface via `GameWidget.backgroundBuilder`, so it never draws a
/// glyph, edge or shape — only size, `fog` and camera facts feed it, never
/// tiles, visibility, monsters or items, which is what keeps unknown cells
/// void no matter how the light or fog changes.
class DungeonAtmosphere extends StatefulWidget {
  const DungeonAtmosphere({
    required this.snapshot,
    required this.fog,
    super.key,
  });

  final DungeonSceneSnapshot snapshot;
  final Color fog;

  @override
  State<DungeonAtmosphere> createState() => _DungeonAtmosphereState();
}

class _DungeonAtmosphereState extends State<DungeonAtmosphere> {
  ui.Picture? _fogField;
  Size? _fogFieldSize;
  Color? _fogFieldFog;

  @override
  void dispose() {
    _fogField?.dispose();
    super.dispose();
  }

  /// The recorded fog field for the current `(size, fog)`, recording it
  /// once and reusing it across paints that share those inputs; the old
  /// picture is disposed the moment either input changes.
  ui.Picture _fogFieldFor(Size size, Color fog) {
    final cached = _fogField;
    if (cached != null && _fogFieldSize == size && _fogFieldFog == fog) {
      return cached;
    }
    cached?.dispose();
    final recorded = _recordFogField(size, fog);
    _fogField = recorded;
    _fogFieldSize = size;
    _fogFieldFog = fog;
    return recorded;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = constraints.biggest;
      final geometry = GridGeometry.camera(
        size,
        widget.snapshot.columns,
        widget.snapshot.rows,
        widget.snapshot.focus,
        widget.snapshot.pan,
      );
      final drift = MediaQuery.disableAnimationsOf(context)
          ? Offset.zero
          : backdropDrift(geometry.origin);
      final heroCentre = geometry.centreOf(widget.snapshot.heroPosition);
      return IgnorePointer(
        child: ExcludeSemantics(
          child: CustomPaint(
            painter: DungeonBackdropPainter(
              fogField: _fogFieldFor(size, widget.fog),
              drift: drift,
            ),
            foregroundPainter: TorchLightPainter(heroCentre: heroCentre),
            child: const SizedBox.expand(),
          ),
        ),
      );
    },
  );
}

/// Records the fog field once for `(size, fog)` (PLAN.md G5): a jittered
/// lattice of soft discs covering the viewport plus the parallax and disc
/// margins, so drift never uncovers a bare edge.
ui.Picture _recordFogField(Size size, Color fog) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const s = _fogLatticeSpacing;
  const r = _fogDiscRadius;
  final minX = -parallaxLimit - r;
  final maxX = size.width + parallaxLimit + r;
  final minY = -parallaxLimit - r;
  final maxY = size.height + parallaxLimit + r;
  final startIx = (minX / s).floor();
  final endIx = (maxX / s).ceil();
  final startIy = (minY / s).floor();
  final endIy = (maxY / s).ceil();
  for (var ix = startIx; ix <= endIx; ix++) {
    for (var iy = startIy; iy <= endIy; iy++) {
      final k = fogHash(ix, iy, 3);
      if (k < 0.35) continue;
      final jx = (fogHash(ix, iy, 1) - 0.5) * 0.8 * s;
      final jy = (fogHash(ix, iy, 2) - 0.5) * 0.8 * s;
      final centre = Offset(ix * s + jx, iy * s + jy);
      final alpha = 0.10 + 0.30 * (k - 0.35) / 0.65;
      final shader = ui.Gradient.radial(centre, r, [
        fog.withValues(alpha: alpha),
        fog.withValues(alpha: 0),
      ]);
      canvas.drawCircle(centre, r, Paint()..shader = shader);
    }
  }
  return recorder.endRecording();
}

/// Base, fog and vignette (PLAN.md G5). Only the fog layer moves, by
/// [drift]; the base fill and vignette stay fixed in screen space.
class DungeonBackdropPainter extends CustomPainter {
  const DungeonBackdropPainter({required this.fogField, required this.drift});

  final ui.Picture fogField;
  final Offset drift;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final bounds = Offset.zero & size;
    canvas.drawRect(bounds, Paint()..color = crawlBackground);

    canvas.save();
    canvas.translate(drift.dx, drift.dy);
    canvas.drawPicture(fogField);
    canvas.restore();

    final radius =
        math.sqrt(size.width * size.width + size.height * size.height) / 2;
    final vignette = ui.Gradient.radial(
      bounds.center,
      radius,
      [
        _vignetteColor.withValues(alpha: 0),
        _vignetteColor.withValues(alpha: 0.85),
      ],
      const [0.55, 1.0],
    );
    canvas.drawRect(bounds, Paint()..shader = vignette);
  }

  @override
  bool shouldRepaint(covariant DungeonBackdropPainter oldDelegate) =>
      oldDelegate.drift != drift || !identical(oldDelegate.fogField, fogField);
}

/// Torch pool and hero bloom (PLAN.md G5), centred on [heroCentre]. Follows
/// the hero's screen position only — it never reads map state, so it cannot
/// reveal an unknown cell.
class TorchLightPainter extends CustomPainter {
  const TorchLightPainter({required this.heroCentre});

  final Offset heroCentre;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final poolShader = ui.Gradient.radial(
      heroCentre,
      _torchPoolRadius,
      [
        crawlTorch.withValues(alpha: 0.30),
        crawlTorch.withValues(alpha: 0.15),
        crawlTorch.withValues(alpha: 0.05),
        crawlTorch.withValues(alpha: 0),
      ],
      const [0, 0.35, 0.70, 1.0],
    );
    canvas.drawCircle(
      heroCentre,
      _torchPoolRadius,
      Paint()..shader = poolShader,
    );

    final bloomShader = ui.Gradient.radial(heroCentre, _heroBloomRadius, [
      crawlHero.withValues(alpha: 0.28),
      crawlHero.withValues(alpha: 0),
    ]);
    canvas.drawCircle(
      heroCentre,
      _heroBloomRadius,
      Paint()..shader = bloomShader,
    );
  }

  @override
  bool shouldRepaint(covariant TorchLightPainter oldDelegate) =>
      oldDelegate.heroCentre != heroCentre;
}
