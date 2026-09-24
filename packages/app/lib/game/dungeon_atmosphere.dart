import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../style/tokens.dart' show crawlBackground, crawlTorch;
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

/// The second fog octave's own salt (gap 4): XORed off [fogSalt] so its
/// lattice points never land on the first octave's, which is what makes the
/// combined field read as mottled cloud rather than one smooth blob.
const int _fogOctave2Salt = fogSalt ^ 0x9E37;

/// A deterministic pseudo-random value in `[0, 1)` for one fog lattice
/// point's channel, hashed from screen-space coordinates and [salt]
/// only — never from gameplay state (PLAN.md G5).
double fogHash(int ix, int iy, int channel, [int salt = fogSalt]) {
  var h =
      ((ix * 0x27d4eb2d) ^ (iy * 0x165667b1) ^ (channel * 0x9e3779b9) ^ salt) &
      0xFFFFFFFF;
  h = ((h ^ (h >> 15)) * 0x2c1b3c6d) & 0xFFFFFFFF;
  h = ((h ^ (h >> 12)) * 0x297a2d39) & 0xFFFFFFFF;
  h ^= h >> 15;
  return (h & 0xFFFFFF) / 0x1000000;
}

const double _fogLatticeSpacing = 56;
const double _fogDiscRadius = 96;
const double _fogOctave2Spacing = 28;
const double _fogOctave2Radius = 40;
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

/// Fills one fog octave's discs into [canvas] (PLAN.md G5, gap 4): its own
/// lattice spacing, disc radius and hash salt, so the two octaves never
/// land on the same points — which is what turns one smooth blob into
/// mottled cloud. Covers the viewport plus the parallax and disc margins,
/// so drift never uncovers a bare edge.
void _paintFogOctave(
  Canvas canvas,
  Size size,
  Color fog, {
  required double spacing,
  required double discRadius,
  required int salt,
  required double skipBelow,
  required double Function(double k) alphaOf,
}) {
  final minX = -parallaxLimit - discRadius;
  final maxX = size.width + parallaxLimit + discRadius;
  final minY = -parallaxLimit - discRadius;
  final maxY = size.height + parallaxLimit + discRadius;
  final startIx = (minX / spacing).floor();
  final endIx = (maxX / spacing).ceil();
  final startIy = (minY / spacing).floor();
  final endIy = (maxY / spacing).ceil();
  for (var ix = startIx; ix <= endIx; ix++) {
    for (var iy = startIy; iy <= endIy; iy++) {
      final k = fogHash(ix, iy, 3, salt);
      if (k < skipBelow) continue;
      final jx = (fogHash(ix, iy, 1, salt) - 0.5) * 0.8 * spacing;
      final jy = (fogHash(ix, iy, 2, salt) - 0.5) * 0.8 * spacing;
      final centre = Offset(ix * spacing + jx, iy * spacing + jy);
      final shader = ui.Gradient.radial(centre, discRadius, [
        fog.withValues(alpha: alphaOf(k)),
        fog.withValues(alpha: 0),
      ]);
      canvas.drawCircle(centre, discRadius, Paint()..shader = shader);
    }
  }
}

/// Records the fog field once for `(size, fog)` (PLAN.md G5, gap 4): two
/// jittered lattices of soft discs — a broad, sparser octave and a smaller,
/// denser one on a different salt — into the same picture, so dark gaps show
/// between puffs instead of one smooth, too-light blob.
ui.Picture _recordFogField(Size size, Color fog) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  _paintFogOctave(
    canvas,
    size,
    fog,
    spacing: _fogLatticeSpacing,
    discRadius: _fogDiscRadius,
    salt: fogSalt,
    skipBelow: 0.55,
    alphaOf: (k) => 0.08 + 0.52 * (k - 0.55) / 0.45,
  );
  _paintFogOctave(
    canvas,
    size,
    fog,
    spacing: _fogOctave2Spacing,
    discRadius: _fogOctave2Radius,
    salt: _fogOctave2Salt,
    skipBelow: 0.70,
    alphaOf: (k) => 0.06 + 0.24 * (k - 0.70) / 0.30,
  );
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
    canvas.save();
    canvas.clipRect(bounds);
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
    canvas.restore();
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
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final poolShader = ui.Gradient.radial(
      heroCentre,
      _torchPoolRadius,
      [
        crawlTorch.withValues(alpha: 0.34),
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
      crawlTorch.withValues(alpha: 0.18),
      crawlTorch.withValues(alpha: 0),
    ]);
    canvas.drawCircle(
      heroCentre,
      _heroBloomRadius,
      Paint()..shader = bloomShader,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant TorchLightPainter oldDelegate) =>
      oldDelegate.heroCentre != heroCentre;
}
