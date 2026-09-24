# 03 — Visible-only terrain light and targeting contrast

Start: Tasks 01/02's buildable ASCII renderer and active decode cutover plus focused Green receipts on a suitable feature checkout; approved `../CONTRACT.md`, `../PLAN.md` and four named images remain governing. Revalidate named source if head differs. Own `packages/app/lib/game/{glyph_marks.dart,dungeon_scene.dart}` and existing `packages/app/test/game/{dungeon_scene_test.dart,glyph_marks_test.dart}`, plus `test/widget/world_screen_test.dart` only to align regional live-ink expectations; no map/core/FOV/content/action UI changes. Task 04 follows.

## Locked decisions

- Public pure `Color terrainPresentationInk(GlyphCell cell, Position hero)` in `glyph_marks.dart`: return `cell.ink` unchanged unless `layer == GlyphLayer.terrain && opacity == fullOpacity`; visible terrain computes squared cell distance from real hero, `strength=max(0,1-d²/25)`, result `Color.lerp(cell.ink, Color(0xFFE8C58A), 0.38*strength)!`. Never change `cell.opacity`; no FOV computation, no wall-neighbor query, no gameplay RNG, clock or camera-focus dependence. Nodes/items/actors and remembered terrain remain original ink; unknown has no `GlyphCell`. The function must not mutate the projection.
- Add `heroPosition` to `DungeonSceneSnapshot.fromViewState`/`withViewport`; source is `state.game.hero.position`, not `state.cameraFocus`. `withViewport` carries it through pan-only reuse. `_GlyphComponent` gets resolved ink on constructor and synchronization; compare the previous resolved colour as well as glyph/opacity so a hero step, palette switch or projection update recolours retained glyphs. It does not recompute shaders/paths per frame. Keep 36dp glyph anchors and unchanged camera/hit geometry. The unchanged `glyphPlan` remains the knowledge authority.
- `_GlyphComponent._updateOutlines`: a marked actor retains square geometry inset 1dp, 2dp stroke and `0xFFE87C70` target accent; selected actor remains circle with existing stroke/shape, both may coexist and glyph/badge remain visible. No reticle/path on unmarked or hidden actor; no new hit target. Red is redundant to shape, armed word/border and actor glyph.

## Red → Green and proof

1. First write behavioral tests for `terrainPresentationInk` at hero/near/outside-radius positions: visible near is warmer/brighter than same terrain far; remembered terrain even adjacent stays exactly base ink/opacity; visible/remembered node and visible monster unchanged; two calls with equal input equal output. Show **Red** from missing function or old unlit output. Add scene test in `dungeon_scene_test.dart` where selected actor is away from hero: light remains centered on hero, and retained glyph changes paint after hero moves but not after pan; marked and selected same actor keep visibly different square/circle outlines. Prefer observable component/text paint and geometry over private field-name assertions. An unknown position stays without component and never receives light.
2. Make Green with only the locked formula/outline change. Adapt Task 01 regional live-ink expected value by calling the pure function on the independently known terrain cell/hero position; do not drop regional difference assertions. Verify `_GlyphComponent` updates on projection replacement rather than only during new component construction.
3. From `packages/app`: `flutter test test/game/glyph_marks_test.dart test/game/glyph_plan_test.dart test/game/dungeon_scene_test.dart test/widget/world_screen_test.dart test/battle_view_test.dart`; `dart format <touched Dart paths>`; `flutter analyze`. Report Red and Green outputs/exits. Main owns final suite and real-device light/target readability.

## Executor discretion

Place pure light cases in existing `glyph_marks_test.dart`; private cache of previously resolved ink and local helper naming are discretionary. No radius/strength/tint redesign, no renderer-wide gradient overlay, no target logic change.

## Escalate when

Hero-centered light cannot be applied without exposing unknown geometry or violating the `GlyphCell` projection semantics; retained components cannot repaint correctly without a material architecture change; target outlines cannot remain simultaneously shape-distinct/within 36dp; changed hardware behaviour requires a formula/geometry change outside the locked values.

## Handoff receipt

Red failing case and exit, Green focused/format/analyzer exits, known/remembered/unknown and hero-vs-selected position findings, targeted+selected outline containment, and changed-file list. Handoff is a deterministic lit ASCII scene with unchanged input and no depth backdrop yet.
