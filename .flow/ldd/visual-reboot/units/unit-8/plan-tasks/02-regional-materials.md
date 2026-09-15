# Task 02 — Deterministic regional materials

Owner: second fresh `flow-plan-executor` on the Unit 8 feature checkout. Read
`../PLAN.md` and `../CONTRACT.md` before editing. Start from repository state,
not the prior executor's transcript.

## Expected starting repository condition

- The non-`main` `residuum-visual-reboot-8` checkout descends from `f322d78`.
- Task 01 is accepted: `world_route_diagram.dart` exists and world tests are
  green. Task 01's files are read-only for this task.
- `dungeon_palette.dart` still has three palettes and nullable `paletteFor`;
  `dungeon_scene_material.dart` still uses global Crypt surface/light colours;
  no explicit lowland road material exists.
- `.flow/**` may contain architect-owned dirty records. Preserve them exactly.

Inspect branch and worktree before editing; never implement on `main`. If task
01 is incomplete, a planned game/test file has unexplained changes, Crypt's
current constants/algorithms differ from `../PLAN.md`, or the source revision no
longer matches the plan, stop and report the contradiction.

## Behavioral slice and file ownership

Extend the existing material pipeline so four explicit palette contexts produce
four deterministic material/light identities while preserving Unit 2 geometry,
knowledge, caching, input, and Crypt output. This task proves the renderer in
isolation; it does not wire any `GameScreen` or session route.

Touch only:

- `packages/app/lib/game/dungeon_palette.dart`;
- `packages/app/lib/game/dungeon_material.dart`;
- `packages/app/lib/game/dungeon_scene_material.dart`;
- `packages/app/test/widget/palette_test.dart`;
- `packages/app/test/game/dungeon_material_test.dart`;
- `packages/app/test/game/dungeon_material_paint_test.dart`;
- `packages/app/test/game/dungeon_scene_test.dart`, only for constructor
  migrations forced by `MaterialPlan.palette` and any direct proof named below.

Do not edit `dungeon_scene.dart`, `glyph_plan.dart`, `game_screen.dart`,
`game_bloc.dart`, `main.dart`, world/town/save code, other tests, dependencies,
assets/generated files, core/content, or LDD authority. Task 03 owns all screen
and session wiring.

## Locked implementation

### Complete `DungeonPalette`

Apply `../PLAN.md` section 3 exactly:

- add `RegionMaterial` with exactly `cryptStone`, `seaCaveStone`,
  `ruinedKeepMasonry`, and `lowlandRoad`;
- retain required `wall`, `floor`, `stairs`, `themeSalt`;
- add required `material`, `rememberedStone`, `visibleStone`, `edgeInk`,
  `detailInk`, `lightInk`, `maxLightLift`, `maxTintMix`;
- define static const `crypt`, `seaCave`, `ruinedKeep`, and `lowlandRoad` with
  the exact initial anchors/salts/lift/tint in the plan table;
- keep `litterInk` and `nodeInk` unchanged.

Crypt's glyph colours, salt, remembered/visible/edge/detail/light colours,
light lift/tint, existing mark values, and resulting render must remain the Unit
2 baseline. Do not tune any initial anchor in this task.

Delete `paletteFor(NodeId?)`; do not alias or deprecate it. Add strict
`paletteForDungeon(NodeId)` and `paletteForRoad(Route)`. Match route endpoints
with `Route.joins`, never route object identity, ordering, node names, creature
table, glyph, or nullable dungeon state. Map exactly the three dungeons and five
shipped routes listed in the plan; throw `ArgumentError.value` for a town passed
as a dungeon and for any unrecognized route pair. The three lowland routes map
to `lowlandRoad`, not Crypt.

### Material plan

Make `MaterialPlan` require and expose immutable `DungeonPalette palette`.
`materialPlan(game, palette)` stores that same const context while retaining
unmodifiable copies of cells/marks/masonry and the existing hero position.
Update every direct constructor in owned tests explicitly; no optional/default
palette.

Make `MaterialMark` require `double pattern` and compare/hash it. It is a 0..1
deterministic phase for regional surface work; that constraint is recorded here
and pinned by tests, **not** by Dartdoc — `AGENTS.md` allows `///` only on the
public API of `core` and `content`, so no new app Dartdoc is written (architect
correction of U8-AR-3, 2026-09-15). Preserve the existing `grit`, `speck`,
`crack`, and `edge` formulas and exact salt literals. Add only:

```dart
pattern: remembered
    ? 0.0
    : _unit01(_hash(position, palette.themeSalt ^ 0x5555, kind.index))
```

Do not change cell membership/order, knowledge, masonry, `_kindOf`, `_hash`, or
`_unit01`. No unknown neighbor, game RNG, clock, frame, or mutable global may
feed a mark. Manual test plans set `pattern: 0` unless the case explicitly tests
a pattern.

### Paint decisions and prepared renderer

Move the existing Crypt surface/light constants into `DungeonPalette` use while
keeping exported `dungeonVoid = Color(0xFF050607)` global and identical. Add
`SurfacePattern { none, tideStrata, ashlarFracture, roadWear }`.

`MaterialCellPaint` gains required `SurfacePattern pattern` and
`double patternStrength`; include both in value equality/hash. Change the pure
APIs to:

```dart
Color stoneLitColor(DungeonPalette palette, double light)

MaterialCellPaint materialCellPaint(
  MaterialCell cell, {
  required DungeonPalette palette,
  required bool masonry,
})
```

`stoneLitColor` starts at `palette.visibleStone`, mixes
`palette.lightInk` by `palette.maxTintMix * light`, then adds
`palette.maxLightLift * light` to HSL lightness. Preserve clamping. Tests must
show increasing light changes luminance more than saturation for all four
palettes.

Implement the visible treatment table in `../PLAN.md` exactly. Keep remembered
cells flat/unlit/pattern-free/no-speck/no-crack, using each palette's
`rememberedStone`, with lower grit and edge response than that palette's visible
cells. Stairs share the ordinary-floor fill and edge and are excluded from
speck and all regional patterns; stair identity remains the glyph layer's job.

Extend `_PreparedMaterialCell.from` only as needed to receive palette, cell kind,
and the deterministic mark phase. Cache all new `Path` and `Paint` objects in
`_rebuildRenderPlan`; `render` must not allocate collections, components,
paths, gradients, shaders, or paints. Use:

- Sea-Cave: two shallow broken horizontal strata strokes, rounded caps and
  phase-shifted safe insets; no curved/angular crack. Apply stronger strata to
  walls and quieter strata to ordinary floors.
- Ruined Keep: a short right-angle ashlar joint on visible walls plus a
  deterministic two-segment angular fracture on eligible exposed walls;
  ordinary-floor fractures are sparse and angular. Butt/square caps.
- Lowland road: two short parallel diagonal scuffs on eligible ordinary floors,
  with neutral inks; no speck or crack. Walls retain a quiet neutral edge.
- Crypt: the existing grit, floor speck, known-face edge, and exposed-wall
  quadratic crack path/paint/caps remain output-equivalent; `SurfacePattern.none`.

Pattern phase may choose only an inset/segment variant and strength gate. It
must not choose material membership, inspect neighbor topology, alter camera or
`GridGeometry`, or draw a route/dungeon gameplay fact. Keep every path inside a
known cell by safe inset and clip each decoration pass to that cell's rect;
anti-aliased stroke must not touch an adjacent unknown pixel. Edge faces still
come only from the set of known walls and remain inset. Use
`palette.detailInk` for grit/pattern, `palette.edgeInk` for edge/speck, and
`dungeonVoid` for cracks at bounded alpha.

The single cached radial shader remains centered on `plan.heroPosition`, uses
`(fovRadius + 1) * cameraCellSize`, and is clipped by the unchanged
`visibleMaterialMask(plan)`. Remembered and unknown cells receive no light. A
pan hands the identical plan to `MaterialComponent.adopt` and stays a no-op;
only a new projection or palette rebuilds prepared work.

Do not add a second FOV/shadow model, image/static/generated asset, animation,
per-tile Flame component, `Random`, gameplay `Rng`, package dependency, or
alternate renderer.

## Red/Green behavioral proof

Work test-first.

### `palette_test.dart`

Delete the obsolete test whose contract is “roads in the Crypt's” and the
`paletteFor(null)` assertion; do not retain it under new wording. Add:

1. strict dungeon mapping for all three dungeon ids and rejection of both town
   ids;
2. strict unordered route mapping for all five shipped edges, including a
   reconstructed reversed spur, and rejection of an invented route;
3. four-palette value hierarchy: floor < wall < stairs for glyph ink, remembered
   < visible for material, actor/node/litter contrasts remain readable, and
   lowland colours have low saturation relative to the two regional palettes;
4. all four salts/material identities and visible/remembered/edge anchors are
   distinct where the plan requires them; Crypt exact constants remain pinned.

Expected Red: lowland/strict functions/material anchors do not exist and null
still silently chooses Crypt.

### `dungeon_material_test.dart`

Keep existing material-cell, ownership, stable Crypt numbers, RNG, masonry, and
unknown-neighbor tests. Update helpers to accept a palette with Crypt default
only in the test helper (not production). Add:

1. identical game + identical palette yields identical cells, masonry, marks and
   pattern phases for every palette;
2. same game across palettes yields identical cell/knowledge/masonry/hero facts
   but distinct mark maps and stored material identities;
3. remembered cells have pattern zero; visible pattern depends only on
   position/kind/knowledge/theme salt;
4. both gameplay RNG streams (`rng` and `lootRng`) are byte/state-identical before
   and after building every palette plan;
5. the twin-world hidden-wall-vs-hidden-floor and remembered-neighbor proofs run
   for every palette, establishing no regional pattern leaks geometry.

Expected Red: plans do not carry a palette/pattern and current material behavior
cannot distinguish the four structural identities.

### `dungeon_material_paint_test.dart`

Migrate all direct constructors/calls to explicit palette/pattern. Preserve the
existing Crypt tests and exact output semantics. Add/expand:

1. decision-table tests over representative visible wall, floor, stair, masonry,
   exposed wall, and remembered cells for each `RegionMaterial`, asserting the
   locked `SurfacePattern`, relative strengths, crack eligibility, and
   remembered suppression;
2. deterministic rendered-byte equality for two equal plans under each palette,
   plus rendered-byte inequality among Crypt, Sea-Cave, Keep, and lowland for the
   same known geometry;
3. actual pixel/path evidence that cave strata, keep right-angle/fracture, and
   road wear each change at least one interior pixel while a known neighboring
   control pixel remains base material; avoid whole-frame goldens;
4. parameterized visible-light clipping, remembered-unlit, unknown-void, and
   exposed-stroke-outside-known-cell checks across all four palettes;
5. value-first light growth for all palettes and `remembered < visible < lit`
   luminance order; no assertion relies only on hue;
6. `MaterialComponent.adopt` retains cached output for identical-plan/pan reuse
   and rebuilds output for a different palette/new plan.

Expected Red: every continuous surface uses Crypt's global constants and there
is no regional pattern.

### `dungeon_scene_test.dart`

Update the one manual `MaterialPlan` to provide `DungeonPalette.crypt` and every
manual `MaterialMark` to provide `pattern: 0`. Add at most one direct snapshot
assertion if needed: same `GameViewState` under two palettes keeps columns, rows,
cell positions, focus, and pan while material palette/marks differ. All existing
scene tap/pan/long-press, semantic stair, retained component, camera and pan-only
reuse tests must otherwise pass unchanged. A failure is a renderer-boundary
regression, not permission to rewrite the test.

Use `// arrange` / `// act` / `// assert`. No golden, screenshot, source-text
assertion, random fixture, mock, or behavior-free field-forwarding test.

## Focused proof commands

Record the named Reds before production edits. After Green, run from
`packages/app`:

```sh
flutter test test/widget/palette_test.dart \
  test/game/dungeon_material_test.dart \
  test/game/dungeon_material_paint_test.dart \
  test/game/dungeon_scene_test.dart \
  test/game/glyph_plan_test.dart \
  test/game/engine_boundary_test.dart

dart format lib/game/dungeon_palette.dart lib/game/dungeon_material.dart \
  lib/game/dungeon_scene_material.dart \
  test/widget/palette_test.dart test/game/dungeon_material_test.dart \
  test/game/dungeon_material_paint_test.dart test/game/dungeon_scene_test.dart

dart analyze lib/game/dungeon_palette.dart
dart analyze lib/game/dungeon_material.dart
dart analyze lib/game/dungeon_scene_material.dart
dart analyze test/widget/palette_test.dart
dart analyze test/game/dungeon_material_test.dart
dart analyze test/game/dungeon_material_paint_test.dart
dart analyze test/game/dungeon_scene_test.dart
```

Re-run focused tests after formatting/static correction. Do not run the full
suite/analyzer, whole-tree formatter, app build, emulator, or device install.
`glyph_plan_test.dart` and `engine_boundary_test.dart` must pass without edits.

## Executor discretion

You may choose private renderer helper/path names, private test helper names,
fixture positions that deterministically exercise each pattern. You may not add
new app Dartdoc. You may choose which safe phase threshold
selects a sparse floor fracture/wear mark, provided the test fixture proves at
least one occurrence and the density remains sparse.

You may not change public names/signatures, the palette table, strict mappings,
RegionMaterial/SurfacePattern categories, existing Crypt hashes/paint, visible
treatment strengths, knowledge/light boundaries, prepared-render lifetime,
pattern geometry category, RNG ownership, or file scope. Device tuning is not
this task's discretion.

## Escalate when

- preserving exact Crypt behavior conflicts with the required regional model;
- any pattern/edge/light result depends on unknown geometry, a remembered
  neighbor for a visible decision, game RNG, time, render order, or camera pan;
- anti-aliasing cannot be contained to known cells without erasing the locked
  regional pattern;
- route/dungeon mapping requires a nullable fallback, mutable/global context,
  creature/glyph inference, or core/content changes;
- new prepared material allocates per frame or requires per-cell components;
- any unchanged scene/glyph/engine-boundary test fails;
- work appears to require game/world/main wiring, save/dependency/assets, a new
  codepoint, Unit 9 HUD work, or edits to task 01 files.

## Handoff state and completion receipt

Task 02 is complete when the strict four-context palette API exists, material
plans carry deterministic pattern context, the renderer visibly and repeatedly
produces the four locked identities without geometry/light/RNG leakage, Crypt is
preserved, all focused proofs pass, and no screen/session is wired yet. Task 03
must be able to consume only the public palette functions and required
`GameScreen` interface planned in `../PLAN.md`.

Report to Main in at most eight prose lines:

- branch and named Red evidence;
- strict dungeon/road mapping result and obsolete nullable fallback deletion;
- four-theme deterministic/value/pattern/render-byte proof result;
- RNG, unknown-neighbor, visible-mask, unknown-pixel, and pan-cache results;
- Crypt baseline and unchanged scene/glyph/engine test results;
- files changed and confirmation no forbidden path changed;
- formatter/analyzer commands and results;
- any escalation or device-tuning residual.