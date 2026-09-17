# Unit 11 — Fresh Recon

Observed 2026-09-17 against GitHub `main`.

## Repository freshness

- PR #20, `feat: authored art integration (visual reboot unit 10)`, is merged.
- Current observed merge commit: `0692bbcce7570df988f6daab9b357a2557e58b39`.
- The checked-in `RESUME.md` still says PR #20 is open and the high-level
  `LEDGER.md` state shown through the connector still describes Unit 10 as open
  at intake. Treat those passages as stale and reconcile them locally before
  starting Unit 11.
- Do not assume a local worktree is clean from this GitHub observation. The
  executor must inspect branch and worktree before editing.

## Current renderer facts

### `packages/app/lib/game/dungeon_scene_material.dart`

- `dungeonVoid` is already near-black.
- One `MaterialComponent` owns the material canvas layer.
- Render order is currently:
  1. per-cell base rects;
  2. one visible-light pass;
  3. authored floor/wall soft-light passes;
  4. per-cell decoration.
- The visible-light pass is one radial gradient clipped to all visible material
  together. It therefore gives floors and walls the same local-light field
  before later edge/detail work.
- `visibleSurfaceMask` can already separate floor/stairs from wall.
- Authored floor/wall material is one world-space `ImageShader` field per
  surface, `TileMode.mirror`, currently scaled by `0.5`.
- Material sheets are composited with `BlendMode.softLight`.
- Crack/rubble art is currently selected in the prepared-cell plan and drawn
  into the owning cell.
- `_WallFaces` / wall-edge preparation already exists and is the preferred
  authority seam for stronger structural wall presentation. Do not introduce
  a second topology interpretation from raw map/image data.
- Plan adoption rebuilds prepared cell paths/paints; the frame loop should stay
  allocation-light.

### `packages/app/lib/game/dungeon_palette.dart`

- Each region owns `rememberedStone`, `visibleStone`, `edgeInk`, `detailInk`,
  `lightInk`, `maxLightLift` and `maxTintMix`.
- Lowland road remains a first-class procedural palette/material and has no
  authored image surface.
- Any new value hierarchy should be expressed through presentation style /
  surface response, not by altering content or core state.

### `packages/app/lib/game/dungeon_scene.dart`

- Terrain glyphs are suppressed above material except explicit stair facts.
- `_GlyphComponent` uses a text component centered in a fixed
  `cameraCellSize` square.
- Base glyph font size is currently exactly `cameraCellSize`, then
  `GlyphMarkTreatment.scale` is applied.
- Hero scale is currently greater than 1, and the hero has a circular halo.
  This explains the observed `@` consuming most of / spilling visually beyond
  the cell.
- Target outline is a cell-sized square; selection is a near-cell-sized circle.
- Actor badge is positioned at the cell's top-right and uses the same ink.

### `packages/app/lib/game/glyph_marks.dart`

Current pure scale grammar:

- hero `1.16`;
- monster `1.08`;
- semantic terrain `1.04`;
- node `1.0`;
- litter `0.92`;
- hero-only halo;
- target = square;
- selected = circle.

The pure treatment seam is suitable for pinning a smaller cell-contained glyph
hierarchy without changing actor identity.

## Current test seams

Existing focused suites include:

- `test/game/dungeon_authored_material_test.dart`;
- `test/game/dungeon_material_paint_test.dart`;
- `test/game/dungeon_material_test.dart`;
- `test/game/dungeon_scene_test.dart`;
- `test/game/engine_boundary_test.dart`;
- `test/game/glyph_marks_test.dart`;
- `test/game/glyph_plan_test.dart`;
- `test/game/armed_targets_test.dart`.

Prefer adding narrow pure decision tests and extending the renderer suites over
introducing screenshot-golden tests as the primary contract. Phone screenshots
remain the subjective parity gate.

## Evidence from the Unit 10 review in this chat

Observed screenshots expose these concrete visual defects:

1. floor and wall read at similar value, so topology is visually flat;
2. authored slab scale is too dominant and reads as a material photograph;
3. rubble clusters look stamped onto cells;
4. visible terrain is broadly exposed instead of compositionally lit;
5. hero/enemy glyphs are too large relative to cells;
6. the dungeon visual gap is distinct from the crawl UI / lavender-button gap.

Only items 1–5 belong to Unit 11. UI composition belongs to the next unit.

## Planning correction

Unit 11 should not create a new dungeon structural asset kit yet. Existing
topology facts, wall-face preparation, procedural edges, material sources and
lighting must first be recomposed. New authored structural vocabulary is a
later evidence-backed decision only if this unit still cannot reach the target
hierarchy.
