# 04 — Atmosphere: fog, vignette, parallax, torch pool, hero bloom

Governing: `../CONTRACT.md` settled decision 4, scope item 2 (pool,
backdrop), acceptance 2–3; `../PLAN.md` §2 G5. Work from `packages/app`.
This is the last task before **Checkpoint A** (Main device capture).

## Starting repository state

Task 03 committed: stone inks and falloff; `DungeonPalette` has only `fog`;
`DungeonSceneHost(state, palette, onTap, onPan, onLongPress)` builds
`GameWidget(backgroundBuilder: … CustomPaint(painter: const DungeonDepthPainter()))`
from `lib/game/dungeon_depth.dart`; hero glyph still has a halo
`CircleComponent`; `GlyphMarkTreatment.halo` exists.

## Owned files

new `lib/game/dungeon_atmosphere.dart`; delete `lib/game/dungeon_depth.dart`;
`lib/game/dungeon_scene.dart` (backgroundBuilder, halo removal);
`lib/game/glyph_marks.dart` (drop `halo`); tests
`test/game/dungeon_scene_test.dart`, `test/game/glyph_marks_test.dart`,
`test/widget/world_screen_test.dart` (road fog), and any test referencing
`DungeonDepthPainter` or the halo.

Non-goals: any chrome; input.

## Locked decisions

1. `dungeon_atmosphere.dart` exports:
   - `const double parallaxFactor = 0.12; const double parallaxLimit = 40;`
   - `Offset backdropDrift(Offset cameraOrigin)` = per-axis
     `(origin · 0.12).clamp(−40, 40)`.
   - `const int fogSalt = 0x5E5D1DE;` and `double fogHash(int ix, int iy, int channel)`
     exactly as PLAN G5.
   - `class DungeonAtmosphere extends StatefulWidget` —
     `DungeonAtmosphere({required DungeonSceneSnapshot snapshot, required Color fog})`.
     `build`: `LayoutBuilder` → `size`; `geometry = GridGeometry.camera(size, snapshot.columns, snapshot.rows, snapshot.focus, snapshot.pan)`;
     `drift = MediaQuery.disableAnimationsOf(context) ? Offset.zero : backdropDrift(geometry.origin)`;
     `heroCentre = geometry.centreOf(snapshot.heroPosition)`;
     `IgnorePointer(child: ExcludeSemantics(child: CustomPaint(painter: DungeonBackdropPainter(fogField: <cached picture>, drift: drift), foregroundPainter: TorchLightPainter(heroCentre: heroCentre), child: const SizedBox.expand())))`.
     The state caches the fog field `ui.Picture` for the current
     `(Size, Color fog)`, disposing the old one on change and in `dispose`.
   - `DungeonBackdropPainter` paints: base `crawlBackground`; fog picture
     translated by `drift`; vignette (radius = half diagonal,
     `#020406` α 0 at 0.55 → α 0.85 at 1.0). `shouldRepaint` when
     drift or picture identity changes.
   - fog field recording: lattice `S = 56`, disc `R = 72.8`, coverage
     `[−40 − R, w + 40 + R] × [−40 − R, h + 40 + R]`, jitter/threshold/alpha
     exactly as PLAN G5, colour `fog`.
   - `TorchLightPainter` paints the pool (radius 78, `crawlTorch` α
     0.30/0.15/0.05/0 at 0/0.35/0.70/1) and bloom (radius 20.8, `crawlHero`
     α 0.28 → 0) at `heroCentre`; `shouldRepaint` when `heroCentre` changes.
   Painter/widget inputs never include tiles, visibility, monsters or items.
2. `DungeonSceneHost.build`: `backgroundBuilder: (_) => DungeonAtmosphere(snapshot: _snapshot, fog: widget.palette.fog)`.
   Flame `backgroundColor()` stays `crawlBackground`.
3. Remove the halo component and `GlyphMarkTreatment.halo`; the bloom is the
   hero's only emphasis besides scale.
4. No change to `GridGeometry`, input callbacks or glyph projection.

## Proof (Red first) — pixel tests reuse the existing `_renderPixels` / `_renderBackgroundOnly` harness in `dungeon_scene_test.dart`

1. Determinism + variation: two renders of the same state are byte-equal;
   two probe pixels in blank unknown space far from the hero differ (fog is
   visible); rendering `DungeonBackdropPainter` alone (PictureRecorder, as
   the existing `_renderDepth` does) over an empty fog picture gives a
   corner pixel darker than the centre pixel (vignette).
2. **Secrecy (AC2):** states identical in hero/visible/explored but with
   different tiles and a monster in unknown cells render byte-identical
   background **and** full scene (`_renderScene`); the glyph plan has no
   cell at any unknown position.
3. Pool follows the hero: moving the hero one cell changes background
   pixels near the old and new hero centres; the pixel at the hero centre is
   warmer (R − B larger) than a pixel 120 dp away.
4. **Parallax (AC3):** a pan that moves the camera origin changes background
   pixels farther than 80 dp from both the old and the new hero centre; with
   `MediaQuery(data: …copyWith(disableAnimations: true))` the same pan leaves
   every pixel farther than 80 dp from both hero centres equal to the
   unpanned render (only the pool and bloom follow the hero's screen
   position); `backdropDrift` clamps at ±40 for origins of ±1000.
5. Projection unaffected (AC3): with and without reduced motion and at two
   pans, a tap at `geometry.centreOf(p)` reports `p` and every glyph
   component position is identical.
6. `world_screen_test.dart`: a road fight's backdrop uses
   `paletteForRoad(route).fog` (read the `DungeonAtmosphere.fog` of the
   mounted widget).
Expected Red: symbols missing / old painter pixels invariant to pan.
Green: `flutter test test/game test/widget/world_screen_test.dart test/widget/dungeon_scene_bleed_test.dart`,
`dart format <touched>`, `flutter analyze`.

## Executor discretion

Gradient construction (`ui.Gradient.radial` vs `RadialGradient.createShader`);
lattice loop bounds rounding; private names; probe-pixel coordinates.

## Escalate when

`backgroundBuilder` content is not visible through the Flame surface in a
live render; fog picture recording is too slow to keep a drag at frame rate
in a widget benchmark you can observe (>16 ms per frame in the test host is
not proof — report and continue); any proof requires the atmosphere to read
map state.

## Completion receipt

Red assertion, Green command/exit, analyzer/format exits, the probe pixel
values used. Then STOP: Main performs Checkpoint A (PLAN §4) before Task 05.
Commit: `feat(app): add crawl fog, vignette, parallax and torchlight`.
