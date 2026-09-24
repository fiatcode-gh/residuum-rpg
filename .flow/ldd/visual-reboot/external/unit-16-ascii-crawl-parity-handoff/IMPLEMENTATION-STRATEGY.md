# U16 — Proposed Implementation Strategy

## Disposition

**Partial strategy only. Not execution-grade.**

The WHAT is settled. Local `flow-planning` must perform fresh recon and settle exact renderer APIs, placeholder sizes, code-only lighting/depth technique, test seams and task briefs.

## Recommended task graph

A five-task sequence is likely appropriate because renderer truth, atmospheric depth and UI composition have different regression surfaces.

### Task 01 — ASCII terrain renderer

Goal:

- cut active terrain presentation from authored dungeon material images;
- render known terrain as glyph language;
- preserve GridGeometry, camera, hit testing, FOV boundaries and projection reuse;
- leave actors/selection/targeting as the existing semantic overlay layer.

Likely source seams:

- `game/dungeon_scene.dart`
- `game/dungeon_scene_material.dart`
- `game/dungeon_material.dart`
- `game/dungeon_render_style.dart`
- `game/glyph_plan.dart`
- `game/grid_geometry.dart`
- dungeon renderer tests
- art warm-up/decode seam only if necessary to stop unused dungeon texture decoding

Do not delete historical asset masters in this task.

### Task 02 — Lighting and depth backdrop

Goal:

- warm hero/local light over ASCII;
- value falloff without geometry leak;
- deterministic/code-only depth field behind semantic map;
- camera-relative low-amplitude parallax if it survives readability/input proof.

Proof must separately test:

- semantic layer does not move relative to hit testing;
- backdrop does not contain map topology;
- hidden cells remain hidden;
- same state/camera produces stable output decisions.

### Task 03 — Crawl header/status/timeline composition

Goal:

- move top-of-screen hierarchy toward the new mock using actual facts;
- keep real dungeon name/depth/battle state/resources;
- compact timeline presentation in combat;
- do not add fake Torch/Hungry/Clear/Seed/menu/settings functionality.

This task should own dp-budget remeasurement because any added branding/meta rows spend map height.

### Task 04 — Recent events, expanded log and placeholders

Goal:

- recompose log peek / expanded log to the new visual target;
- introduce exact final placeholder wells for future log/status/action art as needed;
- preserve LogCategory, follow/unread and causal text behavior.

Produce/refresh a tracked U16 placeholder-slot table with exact logical dimensions and consumers.

No `flow-assets` generation yet.

### Task 05 — Action shelf / targeting integration and device parity

Goal:

- visually integrate U15 action chips with the new main-screen composition;
- preserve `_fitFor` and stable action ids;
- maintain armed no-reflow;
- make target reticle/selection read cleanly against ASCII terrain;
- integrate any existing action icons or neutral placeholder wells without new art.

Then run full app gates and target-phone evidence.

## Red → Green priorities

### Renderer

Red:
- known terrain glyph classification;
- visible/remembered/unknown projection;
- no authored material-image dependency in active render path;
- fixed cell geometry and hit tests.

Green:
- pure ASCII terrain picture.

### Atmosphere

Red:
- lighting cannot illuminate unknown cells;
- backdrop cannot change `positionAt` or world-to-screen;
- camera pan only offsets backdrop at a bounded fraction if parallax enabled.

Green:
- depth/light pass.

### Chrome

Red:
- real facts only;
- timeline secrecy/repetition;
- log behavior;
- action visibility/dispatch;
- 600 dp ceiling;
- armed map rectangle invariant.

Green:
- new composition.

## Exact placeholder rule

Before production work that introduces a placeholder, the local plan must name:

- consumer file/widget;
- rendered width/height in dp;
- internal safe area;
- alignment;
- whether future art is alpha-backed;
- filtering/tint behavior;
- absent-art fallback;
- semantic owner (adjacent label or state).

If those dimensions are still unknown after recon, planning is not execution-grade.

## Escalation conditions

Stop and return to architect if:

- pure ASCII rendering would require changing core map topology or tile semantics;
- matching the mock appears to require reducing the 36 dp logical camera cell;
- matching the mock requires hiding currently-authoritative actions behind a new interaction model;
- a mock-only fact/action is needed to make the composition work;
- lighting would need its own hidden-geometry/shadow model;
- parallax changes tap/long-press mapping or makes semantic cells visually ambiguous;
- code-only backdrop cannot stay clearly non-semantic;
- the 600 dp chrome ceiling cannot be met without changing action availability/count semantics;
- implementation begins needing generated art.

## Integrated verification

From `packages/app`:

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Then target-device evidence:

- exploration;
- watched/encounter state;
- typical combat;
- armed targeting;
- expanded log;
- worst legal action density;
- pan/parallax before/after if parallax ships;
- same semantic scene with backdrop disabled in a debug/test proof if practical;
- save backup/restore using the standing visual-reboot procedure.

Record:

- total chrome dp;
- resulting map rectangle;
- 36 dp cell confirmation;
- armed/unarmed map rectangle equality;
- placeholder dimensions;
- active dungeon image decode count/path status after the ASCII cutover.
