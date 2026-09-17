# Task 01 — Structural Light and Wall Mass

Owner: one fresh `flow-plan-executor` on the Unit 11 feature checkout.

Read `../CONTRACT.md`, `../recon.md`, `../PLAN.md`,
`packages/app/lib/game/dungeon_scene_material.dart`,
`packages/app/lib/game/dungeon_material.dart`, and the focused tests named
below before editing.

## Starting condition

- the checkout is a non-isolated feature checkout, not `main`;
- its production source descends from
  `0692bbcce7570df988f6daab9b357a2557e58b39`;
- the approved Unit 11 contract and plan are present and implementation has
  explicit user approval;
- Unit 10 is merged and no Unit 11 production implementation is present;
- any pre-existing planning / canonical LDD changes are preserved as
  user-owned work;
- approved masters and all decoded-art ownership remain unchanged.

Inspect branch, HEAD and worktree before editing. If the named renderer seams
have materially changed, or Task 01 production changes are already present but
have no accepted receipt, stop and report rather than adapting silently.

## Behavioral slice

Make authoritative dungeon topology read structurally at phone density before
changing authored-material frequency, decoration density or glyph size. At
equal light distance, a visible wall must receive a darker, lower-lift response
than a visible floor in Crypt, Sea-Cave and Ruined Keep. Remembered terrain
stays flat and unlit; unknown terrain remains absent.

## Owned files

Expected:

- new `packages/app/lib/game/dungeon_render_style.dart`;
- `packages/app/lib/game/dungeon_scene_material.dart`;
- new `packages/app/test/game/dungeon_render_style_test.dart`;
- `packages/app/test/game/dungeon_material_paint_test.dart`;
- `packages/app/test/art/material_sampling_test.dart` only for an existing
  mask/sampling assertion that belongs there.

`packages/app/lib/game/dungeon_palette.dart` is allowed only if the style seam
cannot express presentation multipliers without changing palette meaning.
Do not edit `dungeon_material.dart`, `dungeon_scene.dart`, `glyph_marks.dart`,
authored or derived assets, `packages/core`, or `packages/content`.

## Locked decisions

### Pure style contract

Reuse the existing `MaterialSurface.floor` / `.wall`; do not add a duplicate
surface enum. Add a pure `DungeonSurfaceTreatment` selected by
`dungeonSurfaceTreatment(DungeonPalette, MaterialSurface)`. Its fields and
semantics are:

- `foundationDarken`: `0..1` interpolation from `palette.visibleStone` toward
  `dungeonVoid`, applied only to visible base material;
- `lightLiftScale`: multiplier on `palette.maxLightLift`;
- `tintScale`: multiplier on `palette.maxTintMix`;
- `authoredScale`: world-space `ImageShader` matrix scale;
- `authoredStrength`: `0..1` strength of the existing `softLight` pass;
- `boundaryShadow`: `0..1` value-only strength for prepared known wall faces.

Update `stoneLitColor` to consume the treatment: light zero returns the
treated foundation and light one adds only scaled lift/tint. Use those
endpoints for both cached gradients so the opaque light draw cannot erase wall
darkening.

Task 01 wires all six fields so Task 02 does not redesign the seam. For Task
01, `authoredScale == 0.5` and `authoredStrength == 1.0` preserve Unit 10
authored-material behavior. For Crypt, Sea-Cave and Ruined Keep:

- floor: `foundationDarken 0`, `lightLiftScale 1`, `tintScale 1`,
  `boundaryShadow 0`;
- wall: `foundationDarken 0.24`, `lightLiftScale 0.42`, `tintScale 0.55`,
  `boundaryShadow 0.22`.

For `RegionMaterial.lowlandRoad`, both surfaces keep the Unit 10 compatibility
response: foundation `0`, lift/tint `1`, authored scale/strength `0.5/1`, and
boundary `0`; the catalogue still provides no road authored art.

Do not move these fields into gameplay/content state. Region identity continues
to come from `DungeonPalette`.

### Authoritative prepared adjacency

Retain one projection: `MaterialPlan`. During `_rebuildRenderPlan()`, build one
position-to-`MaterialCell` lookup and derive a small immutable prepared
neighbour fact for each cell. It may live beside the treatment types, but it is
not a second map or retained scene model.
Implement the exact `KnownMaterialNeighbours`, `knownMaterialNeighbours`,
`DungeonWallFaces`, and `dungeonWallFaces` contracts declared in `PLAN.md`.
`KnownMaterialNeighbours` stores the four nullable `MaterialTileKind` values;
`null` is absent/unknown and is never coerced to floor.

For each direction, the neighbour fact is exactly one of: known wall, known
floor/stair, or absent/unknown. Wall-face truth is:

- current cell is not a wall: no faces;
- adjacent known wall: no face;
- adjacent known floor or stair: face;
- absent/unknown neighbour: no face.

This replaces `_WallFaces`' current “not in known wall set” inference. Task 02
will consume the same prepared neighbour fact for decoration anchoring; it
must not rediscover adjacency from images or glyphs.

### Prepared rendering

- Replace the single visible-light pass with two cached passes built from
  `visibleSurfaceMask`: floor (including both stairs) and wall.
- Both use the existing hero centre and radius; only treatment response differs.
- Keep remembered terrain outside both masks and unknown terrain absent.
- Apply the wall foundation and restrained face/boundary treatment from the
  prepared facts; never inspect pixels or parse glyphs.
- Build masks, bounds, shaders, paths, paints and neighbour facts only in
  `_rebuildRenderPlan()`. `render()` performs draw calls only and allocates no
  per-cell plans, paths, paints or transforms.
- Preserve render order: bases, split light, authored floor/wall passes,
  prepared decoration/structural detail.
- Keep lowland road procedural. No ray casting, gameplay occlusion, FOV change,
  hidden geometry inference, or second topology model.

## Red proof

Add the tests first and run from `packages/app`:

```text
flutter test test/game/dungeon_render_style_test.dart test/game/dungeon_material_paint_test.dart test/art/material_sampling_test.dart
```

The focused proof must cover:

1. for Crypt, Sea-Cave and Ruined Keep, pure wall treatment has greater
   `foundationDarken`, lower `lightLiftScale`, and lower `tintScale` than floor;
2. a rendered visible floor and wall at equal hero distance have lower wall
   luminance in every region;
3. floor/wall masks classify stairs as floor and exclude remembered and absent
   positions;
4. a wall next to a known floor/stair exposes that face, while a wall next to a
   known wall or unknown/absent neighbour does not;
5. remembered pixels are unchanged when hero distance changes, and unknown
   pixels remain `dungeonVoid`;
6. the lowland road uses the exact compatibility treatment and still resolves
   no authored `MaterialArt`.

Expected Red: the treatment API/value ordering and equal-distance wall response
do not exist, and the current absent-neighbour wall face violates item 4.
Mask, remembered/unknown and road assertions are compatibility regressions and
must remain green while the new assertions fail.

Test the public/pure decisions or rendered pixels; do not pin private symbol
names or source text.

## Green proof and package gates

Implement only this slice, then rerun the focused command until green. From
`packages/app`, run:

```text
dart format --set-exit-if-changed --output=none lib test
flutter analyze
flutter test
```

Record the Red failure and all Green exit statuses. Do not run a device gate in
this task.

## Executor discretion

- Exact private names and whether the two cached light passes share a private
  value type.
- Small extraction inside `dungeon_scene_material.dart` that reduces
  duplication without changing the public pure contracts above.
- Pixel fixture coordinates and tolerances, provided they prove the named
  behavior rather than implementation wiring.

Do not tune Task 02 material fields, add decoration placement, or change glyphs.

## Escalate when

- repository reality contradicts the starting condition or named seams;
- the exact known-neighbour truth table cannot be derived from `MaterialPlan`
  without changing it;
- split light cannot preserve remembered/unknown or stairs behavior;
- meeting the slice requires `packages/core`, `packages/content`, assets,
  decoding, gameplay/FOV/topology, save, dependency, or interaction changes;
- a locked initial constant knowingly causes a correctness defect (visual
  tuning alone waits for the bounded integrated/device gate);
- any required test can pass only by asserting private wiring or suppressing an
  existing contract.

## Completion receipt

Return one compact receipt containing:

- `STATUS: COMPLETE` or `BLOCKED`;
- starting and resulting revision/dirty-state summary;
- changed paths;
- Red command and the behavioral failure observed;
- focused Green command plus format/analyze/full-app-test results;
- confirmation of the neighbour truth table, split light, memory/unknown,
  road, no-RNG/no-decode and scope invariants;
- residual findings and exact next action: Task 02 may start only when this
  repository state and receipt are accepted.
