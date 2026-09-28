# 02 — 24 × 30 map cell, glyph scale, hero-centred camera, bounded pan, recenter

Governing: `../CONTRACT.md` settled decision 11, architect proposals, scope
§6, acceptance 10; `../PLAN.md` §2 G2, G3. Work from `packages/app`.

## Starting repository state

Task 01 committed. `lib/game/grid_geometry.dart`: `mapCellWidth = 16`,
`mapCellHeight = 20`; `_axisOrigin` centres an axis whose floor extent fits
and ignores pan on it, else clamps `centred + pan` to `[viewport − extent, 0]`.
`lib/style/tokens.dart`: `mapGlyphStyle` 21, `mapBadgeStyle` 10.
`lib/game/dungeon_scene.dart`: `_ReticleComponent._rect = Rect.fromLTWH(0.75, 0.75, 14.5, 18.5)`,
`_armLength = 4.3`; `onDragUpdate` forwards the raw delta.
`lib/game/dungeon_atmosphere.dart`: pool/bloom derive from `mapCellWidth`.
`GameScreen` shows the recenter `CrawlPill` at the map's top-right.
`lib/game/crawl_surfaces.dart::CrawlPill` icon branch is a `tapTarget` (44)
square.

## Owned files

`lib/game/grid_geometry.dart`, `lib/style/tokens.dart` (two font sizes),
`lib/game/dungeon_scene.dart` (reticle constants, drag clamp),
`lib/game/crawl_surfaces.dart` (`CrawlPill.extent`),
`lib/game/crawl_style.dart` (`crawlTouchTarget = 48`),
`lib/game/game_screen.dart` (recenter position/extent only); tests
`test/grid_geometry_test.dart`, `test/game/hero_off_screen_test.dart`,
`test/game/dungeon_scene_test.dart`, `test/widget/dungeon_scene_bleed_test.dart`,
and any other test that breaks because it assumed the fitting-axis rule or
16 × 20 literals (fix by deriving from `GridGeometry`/constants, never by
re-pinning).

Non-goals: `map_touch.dart` rules (Task 03), chrome, bloc.

## Locked decisions

1. `mapCellWidth = 24`, `mapCellHeight = 30`; stale dartdoc on them and on
   `GridGeometry`/`GridGeometry.camera` that describes 16 × 20 or the
   fitting rule is deleted (no replacement dartdoc).
2. Camera exactly PLAN G3: private `_centred`, `_clampAxisPan`, public
   static `clampPan`; `_axisOrigin` = `_centred + _clampAxisPan`.
   `heroOffScreen` unchanged.
3. `mapGlyphStyle` fontSize 31.5, `mapBadgeStyle` fontSize 15; nothing else
   in either style changes.
4. Reticle `_rect = Rect.fromLTWH(0.75, 0.75, mapCellWidth - 1.5, mapCellHeight - 1.5)`,
   `_armLength = 6.5`.
5. `_DungeonScene`: field `Offset _dragPan`, set from `snapshot.pan` in the
   constructor and in `synchronize`; `onDragUpdate` computes
   `allowed = GridGeometry.clampPan(Size(canvasSize.x, canvasSize.y), _snapshot.columns, _snapshot.rows, _snapshot.focus, _dragPan + delta)`,
   calls `_onPan(allowed - _dragPan)` only when non-zero, then
   `_dragPan = allowed`.
6. `CrawlPill` gains `this.extent = tapTarget` used for the icon branch's
   square; `crawlTouchTarget = 48`; the recenter pill is
   `Positioned(right: 8, bottom: 8)` with `extent: crawlTouchTarget`, same
   key/label/icon/event/visibility predicate.

## Proof (Red first)

- `grid_geometry_test.dart` (rewrite the fitting-axis tests; they pin the
  retired rule): at viewport 392.7 × 568.8 on a 24 × 16 floor with the hero
  at (3, 2), (23, 15) and (12, 8), `centreOf(hero)` equals the viewport
  centre ± 0.01 at zero pan; pan (+100, +50) on that fitting floor moves the
  origin by exactly (+100, +50); a pan of (+10 000, −10 000) clamps so the
  viewport centre lies on the floor's edge (origin.dx = w/2, origin.dy =
  h/2 − extentY); `clampPan` returns the effective pan; on a 32 × 20 floor
  (depth 5) with the hero at the centre every cell within 7 columns and 8
  rows of the hero is fully inside the viewport (the lit area stays on
  screen); `positionAt` round-trips `centreOf` for every cell.
- `hero_off_screen_test.dart`: a pan that moves the hero cell past an edge
  reports off-screen; zero pan never does, near every floor edge.
- `dungeon_scene_test.dart`: glyph/badge bounds stay inside the cell (± the
  existing 0.075 × height allowance) at the new size; reticle ticks/brackets
  stay inside the cell; a drag far past a bound followed by a reverse drag
  moves the camera on the first reverse update (no dead travel); a drag at
  a bound dispatches nothing.
- Recenter: the pill's rect is 48 × 48 at the map's bottom-right inset 8.
Expected Red: centring at a floor edge fails (clamped today); pan on a
fitting axis is ignored; glyph size tests fail on literals.
Green: full `flutter test`, `dart format <touched>`, `flutter analyze`.

## Executor discretion

Test fixture construction; helper extraction inside test files; how the
depth-5 floor size is built in tests (`GameMap` of 32 × 20, no core change).

## Escalate when

A widget/tap test elsewhere cannot be made to pass by deriving positions from
`GridGeometry` (a real behaviour change, not a literal); the glyph ink
exceeds the cell allowance at 31.5; atmosphere tests need anything beyond
the derived radii.

## Completion receipt

Red output, Green command/exit, format/analyze exits, the list of tests
rewritten or deleted with the retired rule each pinned. Commit:
`feat(app): centre the camera on the hero with 24 by 30 map cells`.
