# Task 02 — Material Scale and Decoration Integration

Owner: one fresh `flow-plan-executor` on the same non-isolated feature
checkout, after Task 01 is accepted.

Read `../CONTRACT.md`, `../recon.md`, `../PLAN.md`, this brief, the accepted
Task 01 completion receipt, and the resulting
`dungeon_render_style.dart` / `dungeon_scene_material.dart`. Inherit repository
state, not the previous executor's session.

## Starting condition

- the checkout is not `main` and its production ancestry includes
  `0692bbcce7570df988f6daab9b357a2557e58b39`;
- Task 01's accepted repository state is present;
- Task 01 focused proof, format, analyze and full `packages/app` tests are
  green;
- `DungeonSurfaceTreatment` has the six locked fields from Task 01;
- separate visible floor/wall light passes and the exact known-neighbour truth
  table are present;
- authored material still uses Unit 10 values
  (`authoredScale 0.5`, `authoredStrength 1.0`);
- glyph sizing is still Unit 10 behavior.

Inspect branch, HEAD, worktree and Task 01 diff/receipt. If any condition is
false, or Task 01 invariants cannot be reproduced from the current files, stop
and report.

## Behavioral slice

Make approved authored material subordinate to the Task 01 structure and make
cracks/rubble sparse, cell-contained, deterministic and grounded. Preserve the
floor/wall value hierarchy and do not touch semantic glyph composition.

## Owned files

Expected:

- `packages/app/lib/game/dungeon_render_style.dart`;
- `packages/app/lib/game/dungeon_scene_material.dart`;
- `packages/app/test/game/dungeon_render_style_test.dart`;
- `packages/app/test/art/material_sampling_test.dart`;
- `packages/app/test/game/dungeon_authored_material_test.dart`;
- `packages/app/test/game/dungeon_material_paint_test.dart` only for an
  integrated renderer invariant.

Do not touch glyph sizing, crawl UI, `dungeon_material.dart`,
`packages/core`, `packages/content`, package configuration or approved masters.
Do not edit `tool/derive-visual-assets.sh` or derived images without escalation:
shader-side scale/strength and prepared placement are the approved first route.

## Locked decisions

### Authored surface treatment

- Keep one `ImageShader` field per `(region, MaterialSurface)` with
  `TileMode.mirror`, deterministic regional phase and the existing `softLight`
  composition.
- Read scale and strength only from `DungeonSurfaceTreatment`; do not add a
  parallel constant path.
- Set the initial `authoredScale` to `0.32` for dungeon floor and wall
  treatments. Because Unit 10 is `0.5`, this makes apparent source features
  64% of Unit 10 size, inside the accepted 55–70% envelope.
- Set initial `authoredStrength` to `0.55`. Strength is the alpha/intensity of
  the shader paint, not a palette or source-bitmap mutation.
- Preserve Task 01 foundation/light/boundary fields exactly.
- The lowland road continues to resolve no `MaterialArt` and no authored
  overlay, even if a test supplies a fully populated `DungeonArt`.
- Never draw a full source bitmap once per cell and never decode, resample or
  derive an image in the frame loop.

### Pure decoration plan

Add `DungeonDecorationPlacement` to the pure render-style seam with:

- `draw`;
- `destination`: a normalized cell-local `Rect` in `[0,1]`;
- `quarterTurns`: integer `0..3`;
- `mirrorX`;
- `opacity`;
- `groundShadowOpacity`.

Add the exact pure `decorationPlacement` signature from `PLAN.md`. Existing
`MaterialCellPaint`/mark logic first selects zero or one `OverlayKind` and
passes it as nullable `candidate`; the planner also receives the authoritative
`MaterialCell`, its `MaterialMark`, `DungeonPalette`,
`KnownMaterialNeighbours`, and `DungeonWallFaces`. It must not duplicate asset
eligibility, collapse unknown into floor/open, or receive `GameState`, gameplay
RNG, time, camera/pan state, pixels, glyphs or decoded image contents.

The placement decision may suppress or place the one candidate; it must not
create a second overlay or new semantic category.

Binding placement rules:

- null candidate, remembered cells and `RegionMaterial.lowlandRoad` return the
  canonical suppressed value from `PLAN.md` (`draw == false`, `Rect.zero`, no
  transform and zero opacities);
- identical inputs return equal placements;
- presentation variation uses only position, `themeSalt`, kind/mark and
  prepared known adjacency through the existing deterministic presentation
  hashing family;
- a drawn destination is fully inside `[0,1]` and each dimension is
  `0.45..0.70`, strictly smaller than a cell;
- opacity is `0.35..0.60`; optional value-only ground shadow is `0..0.18`;
- only quarter-turn rotation and optional horizontal mirror are allowed;
- wall cracks use only proven known-open faces; unknown is never an anchor;
- floor rubble prefers a known adjacent wall/corner; open-floor candidates are
  suppressed more often rather than forced;
- over a canonical `32 x 32` eligible-position fixture, no more than 25% draw,
  at least one draws, and the anchored draw rate is greater than the open-floor
  draw rate;
- the renderer converts the normalized destination to the owning cell once
  during `_rebuildRenderPlan()` and clips defensively to that cell.

Prepare destination, transform values, paint and optional shadow once. The
frame loop may issue canvas save/transform/draw/restore calls but performs no
hashing and creates no `Rect`, path, paint, matrix or placement object per
frame. Authored art replaces its procedural counterpart; it is not additive.

## Red proof

Add the tests first and run from `packages/app`:

```text
flutter test test/game/dungeon_render_style_test.dart test/art/material_sampling_test.dart test/game/dungeon_authored_material_test.dart test/game/dungeon_material_paint_test.dart
```

The focused proof must cover:

1. dungeon treatments use scale `0.32` and strength `0.55`, while road still
   has no authored art;
2. sampling the same world position produces identical bytes when adjacent
   cell membership changes, proving bounds-independent world-space anchoring;
3. equal placement inputs are equal and a presentation-salt/position change
   may change placement only, never tile knowledge/kind;
4. remembered, road and ineligible inputs suppress drawing;
5. every drawn normalized destination and rendered overlay remains inside its
   owning cell under all four quarter-turns and both mirror states;
6. the canonical density fixture meets the locked sparse/anchored bounds;
7. an authored overlay replaces, rather than stacks over, its procedural mark;
8. Task 01's wall/floor luminance hierarchy, remembered-unlit behavior and
   unknown void remain unchanged.

Expected Red: Task 01 still exposes Unit 10 authored scale/strength and has no
placement API, so items 1 and 3–6 fail. World-space continuity,
replacement-not-addition, Task 01 hierarchy, remembered/unknown and road are
compatibility regressions that must remain green.

Use synthetic test images and pure decisions; do not pin private source text or
add screenshot goldens.

## Green proof and package gates

Implement only this slice, rerun the focused command until green, then from
`packages/app` run:

```text
dart format --set-exit-if-changed --output=none lib test
flutter analyze
flutter test
```

After those gates, one local developer preview is allowed only to catch an
obvious scale/transform defect. It is not `Medium_Phone` acceptance, does not
authorize numeric drift, and must not install to or mutate the acceptance
device.

## Executor discretion

- Exact private prepared-cell fields and canvas transform mechanics.
- Which existing presentation-hash salt values drive density, rotation and
  mirroring, provided each decision uses a distinct stable salt and satisfies
  the pure tests.
- Destination size/offset, opacity and shadow within the locked bounds.
- Whether a grounding shadow is omitted (`0`) when it does not improve the
  local preview.

Do not alter Task 01 structural constants. Final bounded numeric tuning occurs
only in the integrated/device sequence defined by `PLAN.md`.

## Escalate when

- Task 01 state or proof is missing/contradictory;
- continuous world-space scale or strength cannot be expressed through the
  locked treatment seam;
- satisfying the visual contract appears to require derived assets, a new
  master, palette/content changes, or more than one overlay per cell;
- placement needs unknown geometry, gameplay RNG/state, glyph parsing, image
  analysis, or frame-time allocation;
- the sparse fixture cannot coexist with regional cues or the existing overlay
  catalogue;
- required proof can pass only by weakening Task 01, road, memory/unknown or
  one-time-decode invariants.

## Completion receipt

Return one compact receipt containing:

- `STATUS: COMPLETE` or `BLOCKED`;
- starting and resulting revision/dirty-state summary;
- changed paths;
- Red command and behavioral failure observed;
- focused Green command plus format/analyze/full-app-test results;
- final treatment and placement constants/salts;
- confirmation of continuity, density, containment, replacement-not-addition,
  road, Task 01 hierarchy, no-RNG/no-decode and scope invariants;
- local preview result, if run;
- residual findings and exact next action: Task 03 may start only when this
  repository state and receipt are accepted.
