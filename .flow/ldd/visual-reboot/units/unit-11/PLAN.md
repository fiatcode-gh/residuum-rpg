# Unit 11 — Dungeon Scene Recomposition: Execution Plan

Status: **execution-grade; planning only.** The Unit 11 contract is approved,
but the user must separately approve this plan before production execution.

Source base: `main` at
`0692bbcce7570df988f6daab9b357a2557e58b39` (Unit 10 merge).

Planning dirty-state assumption observed on 2026-09-17: production source is at
that revision; only architect-owned canonical LDD updates and the untracked Unit
11 intake/planning bundle are present. Those changes are user-owned and must be
preserved. A revision change requires targeted revalidation of the named seams,
not ritual replanning.

Derived from accepted `CONTRACT.md`, `recon.md`, the current renderer/tests, the
Unit 10 art/decode architecture and the approved visual reboot mock.

## Freshness, authority and checkout

Before Task 01:

1. inspect branch, HEAD and worktree without discarding/stashing user work;
2. confirm production ancestry includes `0692bbcce7570df988f6daab9b357a2557e58b39`;
3. confirm the accepted contract, this approved plan and canonical LDD status
   are present;
4. use one suitable non-isolated Unit 11 feature checkout for all three tasks;
5. never implement directly on `main`.

If the named renderer or test seams materially differ from this source
assumption, return to the architect. Executors may not silently adapt an
interface, ownership boundary or behavior.

`MaterialPlan` remains authoritative for known topology/material projection.
`GlyphCell` remains authoritative for semantic marks. The approved masters and
Unit 10's one-time `DungeonArt` decode ownership remain read-only and intact.

## Strict execution graph

```text
01 structural light + wall mass
  -> accepted Task 01 repository state + receipt
02 material scale + decoration
  -> accepted Task 02 repository state + receipt
03 semantic glyph composition
  -> accepted Task 03 repository state + receipt
integrated format/analyze/full app tests + scope audit
  -> integrated COR/TTC/CRF acceptance review + corrections
  -> rerun evidence stale from any correction
Medium_Phone save backup -> install -> evidence capsules
  -> at most one bounded constants-only tuning pass
  -> affected proof + scoped acceptance rerun -> recapture
restore both save slots byte-identically
  -> user acceptance / integration decision
```

The tasks are strictly sequential and use three fresh
`flow-plan-executor` sessions on the same checkout. They are not parallel:
Task 02 calibrates against Task 01's environment hierarchy, and Task 03
calibrates against the completed environment. Repository state and accepted
receipts carry forward; executor conversation does not.

Each task may commit independently or hand off a precisely reported dirty
tree. Either way, its changed behavior and package gates must be green before
the next task starts.

## Scope and ownership

Allowed production surface:

- new `packages/app/lib/game/dungeon_render_style.dart`;
- `packages/app/lib/game/dungeon_scene_material.dart`;
- `packages/app/lib/game/dungeon_palette.dart` only if presentation
  multipliers cannot remain in the new style seam;
- `packages/app/lib/game/dungeon_scene.dart`;
- `packages/app/lib/game/glyph_marks.dart`;
- focused tests under `packages/app/test/game/`;
- `packages/app/test/art/material_sampling_test.dart`.

Conditional only after escalation and architect confirmation:

- `tool/derive-visual-assets.sh`;
- derived dungeon images under `packages/app/assets/visual/dungeon/`.

The default and planned route is shader-side scaling/strength plus prepared
placement using existing approved images. Executors must not enter the
conditional asset route merely because it is possible.

Forbidden:

- `packages/core/**`, `packages/content/**`;
- `packages/app/lib/game/dungeon_material.dart` or `MaterialPlan` shape;
- `game_bloc.dart`, interaction, hit-test, FOV, topology, targeting, camera,
  timeline identity, RNG, balance, generator or save behavior;
- package/dependency/CI changes;
- authored masters or new dungeon art;
- crawl controls/status/log/sheets, town/management UI or road art;
- per-frame/per-cell image decode, resampling or full-bitmap tile draws.

## Cross-task interfaces

### Pure surface treatment — established by Task 01

Reuse existing `MaterialSurface.floor` and `.wall`. Do not add a duplicate
surface enum.

```dart
class DungeonSurfaceTreatment {
  const DungeonSurfaceTreatment({
    required this.foundationDarken,
    required this.lightLiftScale,
    required this.tintScale,
    required this.authoredScale,
    required this.authoredStrength,
    required this.boundaryShadow,
  });

  final double foundationDarken;
  final double lightLiftScale;
  final double tintScale;
  final double authoredScale;
  final double authoredStrength;
  final double boundaryShadow;
}

DungeonSurfaceTreatment dungeonSurfaceTreatment(
  DungeonPalette palette,
  MaterialSurface surface,
);
```

Semantics:

- `foundationDarken`: `0..1` interpolation from `visibleStone` to
  `dungeonVoid` for visible base material;
- `lightLiftScale`: multiplier on `maxLightLift`;
- `tintScale`: multiplier on `maxTintMix`;
- `authoredScale`: world-space `ImageShader` matrix scale;
- `authoredStrength`: `0..1` intensity/alpha of the existing `softLight` pass;
- `boundaryShadow`: `0..1` value-only prepared known-face response.

Change `stoneLitColor` to consume the treatment as well as palette/light.
Its `light == 0` result is the treated foundation; `light == 1` adds only the
scaled lift and tint. The cached split gradients use those two endpoints, so
an opaque light pass cannot erase the wall foundation hierarchy.

Task 01 initial constants:

| surface | foundation | lift | tint | authored scale | authored strength | boundary |
|---|---:|---:|---:|---:|---:|---:|
| floor | 0 | 1 | 1 | 0.5 | 1 | 0 |
| wall | 0.24 | 0.42 | 0.55 | 0.5 | 1 | 0.22 |

The table applies to Crypt, Sea-Cave and Ruined Keep. For
`RegionMaterial.lowlandRoad`, both surfaces keep compatibility response:
`foundationDarken 0`, `lightLiftScale 1`, `tintScale 1`, `authoredScale 0.5`,
`authoredStrength 1`, and `boundaryShadow 0`. The catalogue still supplies no
road authored surface/overlay.

The palette still supplies regional colors and maxima. Stairs use the floor
treatment. Remembered material bypasses visible treatment entirely.

Task 02 changes only `authoredScale` to `0.32` and `authoredStrength` to `0.55`
for dungeon floor/wall. It does not fork or replace this interface.

### Prepared known-neighbour fact — established by Task 01

Add one immutable local fact derived only from `MaterialPlan.cells`:

```dart
class KnownMaterialNeighbours {
  const KnownMaterialNeighbours({
    required this.north,
    required this.east,
    required this.south,
    required this.west,
  });

  final MaterialTileKind? north;
  final MaterialTileKind? east;
  final MaterialTileKind? south;
  final MaterialTileKind? west;
}

KnownMaterialNeighbours knownMaterialNeighbours(
  Position position,
  Map<Position, MaterialCell> knownCells,
);
```

`null` means absent/unknown; it never means floor. Build `knownCells` once per
`_rebuildRenderPlan()`, then prepare one neighbour value per cell. This is an
ephemeral render-plan fact, not a second scene/topology model.

Promote the existing private face carrier to the shared pure contract:

```dart
class DungeonWallFaces {
  const DungeonWallFaces({
    required this.north,
    required this.east,
    required this.south,
    required this.west,
  });

  final bool north;
  final bool east;
  final bool south;
  final bool west;
}

DungeonWallFaces dungeonWallFaces(
  MaterialCell cell,
  KnownMaterialNeighbours neighbours,
);
```

Its truth table is binding:

| current/neighbor | face |
|---|---|
| current is not wall | false |
| known wall | false |
| known floor/stair | true |
| `null` absent/unknown | false |

Task 01 uses it for structural faces. Task 02 consumes the same neighbour/face
facts; it does not query glyphs, pixels or hidden map cells.

### Pure decoration placement — added by Task 02

```dart
class DungeonDecorationPlacement {
  const DungeonDecorationPlacement({
    required this.draw,
    required this.destination,
    required this.quarterTurns,
    required this.mirrorX,
    required this.opacity,
    required this.groundShadowOpacity,
  });

  final bool draw;
  final Rect destination; // normalized cell-local coordinates
  final int quarterTurns;
  final bool mirrorX;
  final double opacity;
  final double groundShadowOpacity;
}

DungeonDecorationPlacement decorationPlacement({
  required MaterialCell cell,
  required MaterialMark mark,
  required OverlayKind? candidate,
  required DungeonPalette palette,
  required KnownMaterialNeighbours neighbours,
  required DungeonWallFaces faces,
});
```

`DungeonSurfaceTreatment`, `KnownMaterialNeighbours`, `DungeonWallFaces` and
`DungeonDecorationPlacement` are immutable field-value types with matching
`==` / `hashCode`; tests compare values, not object identity.

The decision uses only existing presentation facts and deterministic
presentation hashing. Existing `MaterialCellPaint`/mark logic selects zero or
one `OverlayKind` before this call and passes it as `candidate`; the placement
planner must not duplicate eligibility or choose a second asset. It may
suppress or place that candidate.

Binding output:

- `candidate == null`, remembered or road input returns the canonical
  suppressed value: `draw == false`, `destination == Rect.zero`,
  `quarterTurns == 0`, `mirrorX == false`, and both opacities zero;
- drawn destination lies wholly in `[0,1]`, with width/height `0.45..0.70`;
- `quarterTurns` is `0..3`; only horizontal mirroring is allowed;
- opacity is `0.35..0.60`; value-only shadow is `0..0.18`;
- identical inputs produce equal output;
- known wall/corner context is preferred, unknown is never an anchor;
- a canonical `32 x 32` all-eligible fixture draws at least once and at most
  25%, with anchored rate greater than open-floor rate.

The renderer resolves the normalized destination and all paints/transforms
during rebuild. Render-time canvas save/transform/draw/restore calls are
allowed; per-frame hashing/object construction is not.

### Glyph composition — added by Task 03

`glyph_marks.dart` owns:

```dart
const double glyphBaseFontScale = 0.73;
```

`GlyphMarkTreatment.scale` stays relative:

| mark | scale |
|---|---:|
| hero | 1.08 |
| monster | 1.04 |
| semantic terrain/stairs | 1.02 |
| node | 1.00 |
| litter | 0.94 |
| non-semantic terrain | 1.00 |

The renderer uses
`cameraCellSize * glyphBaseFontScale * treatment.scale`; the component's cell
size, position and interaction geometry do not change. Hero halo radius becomes
`0.32 * cameraCellSize`; badge font size becomes `0.30 * cameraCellSize`.
Target remains square and selection remains circular, both in-cell.

## Render-plan and lifetime rules

`MaterialComponent._rebuildRenderPlan()` owns all lookup, adjacency, masks,
bounds, shaders, paths, paints, placement hashing and cell-local transform
preparation. `adopt(identicalPlan)` remains a no-op. A real projection rebuilds
once. Pan-only reuse and repeated render calls do not allocate prepared
material data or decode images.

Render order remains:

1. known-cell bases;
2. separately clipped visible floor and wall light passes;
3. continuous authored floor and wall `softLight` passes;
4. prepared structural/decorative detail;
5. semantic glyph components above material.

Unknown has no `MaterialCell`. Remembered cells are base-only and outside
light, authored-surface and authored-decoration passes.

## Task slices and handoffs

### Task 01 — structural light and wall mass

Owns the full surface-treatment interface, prepared known-neighbour/face fact,
split floor/wall light, structural wall foundation/faces, remembered/unknown
preservation and road regression. It leaves authored fields at Unit 10 values
and does not change decoration placement or glyph sizing.

Valid handoff: focused proof and all package gates green; interface/truth table
present; Task 01 receipt accepted.

### Task 02 — material scale and decoration

Consumes, but does not redesign, Task 01 interfaces. Owns world-space authored
scale/strength and the pure deterministic placement plan plus prepared renderer
application. It preserves structural constants and does not change glyphs.

Valid handoff: focused proof and all package gates green; continuity, density,
containment, road and Task 01 hierarchy proven; Task 02 receipt accepted.

### Task 03 — semantic glyph composition

Consumes the completed environment. Owns base glyph size, relative hierarchy,
halo, badge size/inset and in-cell outline containment. It does not change
material, identity or interaction.

Valid handoff: focused proof and all package gates green; containment and
identity/state regressions proven; Task 03 receipt accepted.

Detailed fresh-executor capsules:

- `plan-tasks/01-structural-light-and-wall-mass.md`;
- `plan-tasks/02-material-scale-and-decoration.md`;
- `plan-tasks/03-semantic-glyph-composition.md`.

## Red/Green proof map

Each task creates a behavioral Red before production change and records the
failure reason. Screenshot goldens and source-text assertions are forbidden.

Task 01:

- pure treatment ordering for all three dungeon palettes;
- rendered equal-distance wall luminance below floor;
- floor/wall/stairs mask classification;
- known-floor face versus known-wall/unknown no-face truth table;
- remembered-unlit, unknown-void and road-no-authored regression.

Task 02:

- exact initial shader scale/strength;
- same world-position sampling independent of neighboring plan membership;
- deterministic placement, suppression and normalized containment;
- sparse canonical density with stronger known-anchor rate;
- all rotation/mirror containment;
- authored overlay replaces procedural counterpart;
- Task 01 hierarchy and road remain unchanged.

Task 03:

- exact base/relative hierarchy and final nominal scale `< 1`;
- actual Flame text, badge, halo and outline bounds inside cell;
- square target/circular selection, including simultaneous state;
- stairs remain above material;
- duplicate actor badge/identity and armed/selected facts remain stable.

Focused commands and expected handoff receipts are in each task brief.

## Package and scope gates

Every task runs its focused command, then from `packages/app`:

```text
dart format --set-exit-if-changed --output=none lib test
flutter analyze
flutter test
```

After Task 03, the controller reruns those three commands on the integrated
tree and audits the complete diff:

- no `packages/core` / `packages/content` / save / dependency changes;
- no gameplay RNG, topology/FOV, hit-test, camera, interaction or identity
  changes;
- no asset/master/decode ownership changes unless the conditional route was
  explicitly re-approved;
- no frame-loop construction of plans, paths, paints, matrices or hashes.

Do not claim integration green from task receipts alone.

## Integrated acceptance and correction barrier

After integrated gates, perform one independent acceptance review:

- **COR:** authority/knowledge boundaries, render order, deterministic lifetime,
  road, stairs, identity and interaction invariants;
- **TTC:** each changed behavior has the named observable Red/Green proof; no
  private-wiring, source-text or padded tests;
- **CRF:** pure decisions remain outside the canvas loop, the dense material
  renderer does not absorb a second scene model, and there is no duplicated
  surface/adjacency/placement path;
- **SEC:** skipped unless implementation introduces an external/file/network
  trust boundary, which this plan forbids.

Close every must-fix finding before device installation. Any later production,
asset or build-affecting correction reopens the affected package proof and a
scoped acceptance review before device evidence may be accepted.

## Device gate and bounded tuning

Use the standing `Medium_Phone` procedure only after integrated acceptance:

1. back up both save slots and record byte hashes;
2. install the accepted build;
3. capture all required color/greyscale capsules;
4. if needed, perform at most one constants-only tuning pass;
5. rerun all focused/package evidence traversed by those constants and a scoped
   acceptance review, then recapture affected capsules;
6. restore both slots and verify the restored bytes match the pre-install
   hashes using the same comparison scheme.

The one tuning pass may adjust only existing presentation constants, without
interface/asset/behavior changes, inside these envelopes:

- wall foundation `0.18..0.32`, lift `0.30..0.55`, tint `0.40..0.70`,
  boundary `0.12..0.28`; floor structural constants stay fixed;
- authored scale `0.275..0.35` (55–70% of Unit 10), strength `0.40..0.65`;
- decoration destination/opacity/shadow remain inside the Task 02 bounds and
  density remains `<= 25%`;
- glyph base `0.70..0.76`, hero `1.04..1.10`, monster below hero, node below
  monster, litter below node, largest nominal mark `< 0.85` cell; halo
  `0.28..0.35`, badge `0.26..0.34`.

Record final constants in the acceptance receipt. Any need outside these
envelopes, any second tuning pass, or any structural/interface/asset change is
an escalation, not executor discretion.

### Capsule A — Crypt structure / knowledge

Wall-heavy Crypt scene containing visible floor, visible wall mass, remembered
terrain, unknown void, hero and at least one decoration. Capture color and
greyscale.

### Capsule B — Crypt stairs regression

Comparable stair/landing scene. Stairs remain findable, hero stays contained,
decoration does not compete and wall/floor hierarchy survives. Capture color
and greyscale.

### Capsule C — Sea-Cave combat / targeting

Multiple actors, duplicate badge if reachable, armed targeted spell, square
target marks and a selected actor if practical. Capture color and greyscale.

### Capsule D — Ruined Keep structure

Wall-heavy room/corridor junction showing subordinate authored material and
accepted ashlar/fracture identity. Capture color and greyscale.

### Capsule E — Lowland road regression

One road fight proving the procedural fallback retained its accepted identity
and gained no authored dungeon surface. Capture greyscale where hue could carry
state.

Compare A–D beside the approved mock and record PASS/FINDING for topology
readability, wall mass/floor recession, darkness/local focus, material
subordination, decoration integration, semantic prominence, target/selection
shape and greyscale state preservation. The mock is directional, not a pixel
target.

If structural authored vocabulary is still the blocker, do not add assets.
Record evidence for a later asset-expansion decision.

## Completion and integration boundary

After final acceptance, the controller may update canonical LDD records. PR,
push, review publication, merge and other remote/integration actions still
require explicit user approval.

Suggested separable implementation commits remain:

1. `feat: recompose dungeon structure and light`;
2. `feat: integrate dungeon material detail`;
3. `feat: refine dungeon semantic marks`.

Commit wording is discretionary; task boundaries are not.

## Plan quality gate

- **COR — PASS:** authoritative inputs, known/unknown truth table, render order,
  lifetime/allocation ownership, cross-task interfaces, road/stairs/identity
  invariants, correction barrier and device-save restoration are explicit.
- **TTC — PASS:** every changed behavior maps to named focused Red/Green proof,
  package-native gates and final device evidence; negative, boundary,
  determinism, compatibility and containment cases are included.
- **CRF — PASS:** three independently provable sequential slices are retained;
  Task 01 establishes one shared style/adjacency seam, Task 02 consumes it, and
  Task 03 stays in glyph ownership. No duplicate topology or speculative asset
  abstraction is planned.
- **SEC — SKIP:** presentation-only offline rendering adds no trust boundary.
  Any file/network/external input would contradict scope and trigger
  escalation.

Residual risks deliberately left to implementation evidence:

- final artistic balance and font raster metrics are device/platform-sensitive,
  bounded by the single constants-only pass and containment/device evidence;
- a reachable device fixture may not naturally contain a duplicate badge, so
  automated identity/synchronization proof remains mandatory even if Capsule C
  cannot show one;
- derived assets remain an escalation-only fallback; inability to meet the
  mock with shader/placement composition blocks the unit rather than expanding
  scope silently.

## Authorization

The contract is approved. **This plan does not authorize production
implementation until the user separately approves it.**
