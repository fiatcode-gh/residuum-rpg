# Task 03 — Semantic Glyph Composition

Owner: one fresh `flow-plan-executor` on the same non-isolated feature
checkout, after Tasks 01 and 02 are accepted.

Read `../CONTRACT.md`, `../recon.md`, `../PLAN.md`, this brief, both accepted
completion receipts, and the resulting renderer/style files. Inherit repository
state, not either prior executor's session.

## Starting condition

- the checkout is not `main` and its production ancestry includes
  `0692bbcce7570df988f6daab9b357a2557e58b39`;
- accepted Task 01 and Task 02 repository states are both present;
- their focused proof, format, analyze and full `packages/app` tests are green;
- the structural hierarchy, authored-material scale/strength and deterministic
  decoration plan are complete;
- `dungeon_scene.dart` and `glyph_marks.dart` still have Unit 10 glyph sizing
  behavior except for unrelated preserved user work;
- no integrated review or `Medium_Phone` acceptance capture has started.

Inspect branch, HEAD, worktree and both receipts. Stop and report if any
condition is false or if an earlier invariant is missing.

## Behavioral slice

Bring actors and semantic terrain marks into the completed environment without
changing identity, interaction or camera geometry. Glyphs, badge, halo and
state outlines remain inside the owning cell with visible negative space;
semantic prominence comes from contrast and shape rather than spill.

## Owned files

Expected:

- `packages/app/lib/game/dungeon_scene.dart`;
- `packages/app/lib/game/glyph_marks.dart`;
- `packages/app/test/game/glyph_marks_test.dart`;
- `packages/app/test/game/dungeon_scene_test.dart`;
- `packages/app/test/game/glyph_plan_test.dart` or
  `packages/app/test/game/armed_targets_test.dart` only to preserve an
  observable identity/target contract if the existing coverage is insufficient.

Do not touch `game_bloc.dart`, actor identity allocation, `GlyphCell` data,
target selection, timeline, controls, bottom sheets, material/style code,
core/content, saves, assets or package configuration.

## Locked decisions

- Add `glyphBaseFontScale` in `glyph_marks.dart` with initial value `0.73`.
  `_GlyphComponent` keeps its cell-sized position/hit box but its `TextPaint`
  font size becomes `cameraCellSize * glyphBaseFontScale`.
- `GlyphMarkTreatment.scale` remains a relative presentation multiplier with
  exact initial values:
  - hero `1.08`;
  - monster `1.04`;
  - semantic terrain/stairs `1.02`;
  - node `1.00`;
  - litter `0.94`;
  - non-semantic terrain `1.00` (still suppressed by the material composition).
- The nominal largest actor size is therefore
  `0.73 * 1.08 == 0.7884` cell, leaving negative space. No treatment may reach
  or exceed one cell.
- Hero alone keeps the halo. Set its radius to `0.32 * cameraCellSize`; preserve
  the existing low-alpha value-only treatment and centre it in the cell.
- Reduce badge font size to `0.30 * cameraCellSize`; keep the stable badge text
  and top-right attribution, and adjust only its inset if needed to prove its
  painted bounds are inside the cell.
- Target remains a square and selection remains a circle. Keep their current
  one-pixel stroke and in-cell geometry unless the containment proof requires a
  larger inset; never encode either state by hue alone.
- Stairs remain selected from `MaterialPlan` facts and rendered above material.
- `_GlyphComponent` cell size, priority, map position and gesture projection do
  not change. Actor IDs, duplicate badges, `marked`, `selected`, camera focus,
  hit testing and synchronization semantics do not change.

## Red proof

Add/adjust tests first, then run from `packages/app`:

```text
flutter test test/game/glyph_marks_test.dart test/game/dungeon_scene_test.dart test/game/glyph_plan_test.dart test/game/armed_targets_test.dart
```

The new containment tests must initially fail against Unit 10 sizing. Prove:

1. the locked base and relative scales produce
   `hero > monster > node > litter`, semantic stairs remain deliberate, and
   every nominal final scale is `< 1`;
2. pumped hero, monster and stair text painted/scaled bounds stay inside their
   owning cell with non-zero inset on every side;
3. halo, square target, circular selection and a simultaneous target+selection
   pair remain inside the owning cell;
4. a duplicate badge's painted bounds remain inside the top/right cell bounds
   before and after component synchronization;
5. stairs remain above material, while ordinary floor/wall glyphs remain
   suppressed;
6. existing `GlyphCell` identity, duplicate badges, selected actor and armed
   target facts remain unchanged.

Expected Red: `glyphBaseFontScale` and the locked relative values do not exist,
and Unit 10's hero/monster painted bounds exceed the containment envelope.
Shape, stairs, badge identity and armed/selected assertions are compatibility
regressions and must remain green.

Assert public treatment values and observable Flame component bounds/state.
Do not pin private source text, use screenshot goldens, or weaken existing
identity/interaction tests.

## Green proof and package gates

Implement only this slice, rerun the focused command until green, then from
`packages/app` run:

```text
dart format --set-exit-if-changed --output=none lib test
flutter analyze
flutter test
```

Do not run the device gate in this task. Integrated review must accept the
three-task tree first.

## Executor discretion

- Exact private helper used to calculate text/badge paint and test component
  bounds.
- A larger outline inset if required for reliable containment, provided square
  versus circle remains visually strong and both retain the one-pixel stroke.
- Badge inset within the top-right cell corner.

The base scale, relative scale values, halo radius and badge font scale are
locked initial values. Later adjustment is only the bounded integrated/device
tuning path in `PLAN.md`.

## Escalate when

- Task 01/02 state or evidence is missing/contradictory;
- Flame's reported glyph metrics cannot prove containment without changing the
  locked nominal scale envelope;
- badge containment would require changing badge text, actor identity or
  attribution;
- semantic stairs cannot remain findable without changing `MaterialPlan` or
  parsing glyph characters;
- any change would affect hit testing, camera geometry, targeting/selection
  semantics, timeline identity, interaction, saves, core/content or assets;
- a required test can pass only by asserting private wiring or suppressing a
  pre-existing behavior contract.

## Completion receipt

Return one compact receipt containing:

- `STATUS: COMPLETE` or `BLOCKED`;
- starting and resulting revision/dirty-state summary;
- changed paths;
- Red command and behavioral failure observed;
- focused Green command plus format/analyze/full-app-test results;
- final glyph, halo, badge and outline constants;
- confirmation of component containment, stairs, square/circle, duplicate
  identity, target/selection, hit/camera and scope invariants;
- residual findings and exact next action: controller runs the integrated gates
  and acceptance review before any device install/evidence.
