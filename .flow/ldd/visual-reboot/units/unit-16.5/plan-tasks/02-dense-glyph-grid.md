# 02 — Dense 13 × 16 mono glyph grid and target reticles

Governing: `../CONTRACT.md` settled decision 1, scope items 2–3 (projection
only), `../PLAN.md` §2 G1, G6. Work from `packages/app`.

## Starting repository state

Task 01 committed: `monoFace`, `mapGlyphStyle`, `mapBadgeStyle`, palette
tokens exist in `lib/style/tokens.dart`; Plex fonts load in tests.
`lib/game/grid_geometry.dart` still has `cameraCellSize = 36`, square
`cellSize`, `GridGeometry.fit`; `dungeon_scene.dart::_GlyphComponent` sizes
by `cameraCellSize`, draws Spectral via inline `TextStyle(fontFamily: textFace)`,
halo `CircleComponent`, square `RectangleComponent` target outline, circle
selected outline; `glyph_marks.dart` has `glyphBaseFontScale` and
`GlyphOutlineShape`; `glyph_plan.dart::terrainGlyph(Tile.floor) == '.'`.

## Owned files

`lib/game/grid_geometry.dart`, `lib/game/dungeon_scene.dart`,
`lib/game/glyph_marks.dart`, `lib/game/glyph_plan.dart` (floor glyph only),
`lib/game/game_screen.dart` (only if `_heroOffScreen` needs the new API),
`.github/workflows/ci.yml` (type gate step only); tests that reference
`cameraCellSize`, `cellSize`, `GridGeometry.fit`, `glyphBaseFontScale`,
`GlyphOutlineShape`, the floor `'.'` glyph or outline components:
`test/grid_geometry_test.dart`, `test/game/hero_off_screen_test.dart`,
`test/game/dungeon_scene_test.dart`, `test/game/glyph_marks_test.dart`,
`test/game/glyph_plan_test.dart`, `test/widget/dungeon_scene_bleed_test.dart`,
`test/widget/world_screen_test.dart`, `test/battle_view_test.dart`,
`test/battle_flow_characterization_test.dart` (find others with grep for the
listed symbols).

Non-goals: inks/falloff (Task 03), atmosphere/halo removal (Task 04), touch
resolution (Task 05). Tap semantics stay "cell under the finger".

## Locked decisions

1. Geometry API exactly as PLAN G1: `mapCellWidth = 13`,
   `mapCellHeight = 16`; `GridGeometry({required cellWidth, required cellHeight, required origin, required columns, required rows})`;
   `GridGeometry.camera(size, columns, rows, focus, [pan])` with
   `_axisOrigin(viewport, cells, focus, pan, cellExtent)` keeping today's
   per-axis rule (fits → centred and ignores pan; else hero-centred + pan,
   clamped to `[viewport − extent, 0]`); `topLeftOf`, `centreOf(Position)`,
   `rectOf(Position)`, `positionAt` (per-axis floor; null outside);
   `heroOffScreen` uses `cellWidth`/`cellHeight`. Delete `cameraCellSize`
   and `GridGeometry.fit` (and its test group). Rewrite the class dartdoc to
   describe the dense cell and intent-based aiming (no body comments).
2. `_GlyphComponent`: `size = Vector2(mapCellWidth, mapCellHeight)`,
   position `(x·13, y·16)`, glyph `TextComponent` anchor centre at
   `(6.5, 8)` with `TextPaint(style: mapGlyphStyle(ink.withValues(alpha: cell.opacity)))`;
   badge `mapBadgeStyle(...)`, anchor top-right at `(12.5, 0.5)`. Halo stays
   for now with radius `mapCellWidth * 0.5`, centred (removed in Task 04).
   Treatment scales unchanged.
3. Replace `GlyphOutlineShape`/`targetOutline`/`selectedOutline` with
   `enum GlyphTargetMark { ticks, brackets }` and
   `GlyphMarkTreatment.targetMark` = `cell.selected ? brackets : cell.marked ? ticks : null`.
   One `_ReticleComponent extends PositionComponent` (size = cell) whose
   `render` draws PLAN G6 in `crawlEnemyHigh`: ticks = four corner L's (arm
   3.5, stroke 1.0) on `Rect.fromLTWH(0.75, 0.75, 11.5, 14.5)`; brackets =
   left and right full-height verticals with 3.5 dp top/bottom arms, stroke
   1.75, same rect. `Paint` objects are fields, not per-render allocations.
4. Delete `glyphBaseFontScale`. `dungeonVoid` becomes `crawlBackground`.
   `dungeon_scene.dart` no longer contains `fontFamily:`.
5. `terrainGlyph(Tile.floor) == '·'` (U+00B7).
6. CI type gate step becomes:
   ```sh
   if grep -rn "fontFamily:" lib --include='*.dart' | grep -v '^lib/style/tokens.dart:'; then
     echo "a style declares its own font family outside lib/style/tokens.dart"
     exit 1
   fi
   ```
   (the monospace grep and the literal-quote grep are removed; this gate
   subsumes the latter).
7. Test helpers that tapped `topLeftOf(x, y) + Offset(cellSize / 2, cellSize / 2)`
   use `geometry.centreOf(Position(x, y))`. Assertions that pinned 36 dp
   become 13/16; no behavioural expectation changes.

## Proof (Red first)

1. `test/grid_geometry_test.dart`: new tests — camera cells are 13 × 16 on
   every viewport; an axis that fits centres with its own extent (e.g.
   `Size(200, 400)`, 10 × 10 map → origin `(35, 120)`); `positionAt` inverts
   `centreOf` and `topLeftOf` for a panned, clamped camera on a 40 × 30 map
   including the last row/column; a point one dp past the right/bottom edge
   is null; `rectOf` equals `topLeftOf & Size(13, 16)`. Red: symbols missing /
   square-cell math.
2. `test/game/dungeon_scene_test.dart`: glyph components sit at `(x·13, y·16)`,
   size 13 × 16, text style `fontFamily == monoFace`, `fontSize == 17`;
   a marked monster carries one reticle with `ticks`, a selected one
   `brackets` (and no ticks); every child (text, badge, halo, reticle) stays
   inside `0…13 × 0…16`; tap/long-press at `centreOf` still reports that
   position.
3. `test/game/hero_off_screen_test.dart` rewritten for 13 × 16 extents
   (right-edge and bottom-edge cases; partial cell counts as on screen).
4. Run the CI gate block locally from `packages/app` (exit 0).
Green: `flutter test test/grid_geometry_test.dart test/game test/widget/dungeon_scene_bleed_test.dart test/widget/world_screen_test.dart test/battle_view_test.dart test/battle_flow_characterization_test.dart`
(plus any other file you touched), `dart format <touched>`, `flutter analyze`.

## Executor discretion

Reticle path construction details within the locked geometry; private
helper names; test fixture sizes.

## Escalate when

An existing interaction test fails for a reason other than pinned 36 dp
arithmetic; Flame text anchoring cannot centre within 0.5 dp; any glyph child
cannot be contained in the cell; the CI gate matches anything besides
`tokens.dart`.

## Completion receipt

Red assertion, Green command/exit, gate script output, analyzer/format exits,
list of migrated tests with the one-line reason each changed. Commit:
`feat(app): render the crawl on a dense 13x16 mono glyph grid`.
