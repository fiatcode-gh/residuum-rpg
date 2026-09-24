# 04 — Viewport-only nonsemantic depth

Start: Task 03's tested visible-only light on the Task 01 ASCII scene and Task 02 decode cutover, with no U16 depth field; suitable feature checkout, approved `../CONTRACT.md` and `../PLAN.md` plus four named images. Own `packages/app/lib/game/dungeon_scene.dart`, new `packages/app/lib/game/dungeon_depth.dart`, `packages/app/test/game/dungeon_scene_test.dart` and `packages/app/test/widget/dungeon_scene_bleed_test.dart`. No chrome, world/topology/gesture or asset change; Task 05 follows.

## Locked decisions

- `DungeonDepthPainter` is a viewport-only `CustomPainter` in `game/dungeon_depth.dart`, installed as `GameWidget.backgroundBuilder` in `_DungeonSceneHostState.build` under `IgnorePointer` and `ExcludeSemantics`, below Flame rendering and inside the 36dp map viewport. Render flat charcoal base and two **broad, soft radial value fields** (cool blue-charcoal and subdued warm charcoal), confined to `Size` and never keyed by map, cells, visibility, floor seed, actor, selected target or pan. No topological streaks, tile-aligned marks, props or symbols; unknown map positions may show *only this same* background, never terrain. `shouldRepaint` false for constant painter; cache shaders/paints per `Size` or prepare them in paint without per-cell/per-frame work. Paint is strictly behind existing glyph/outline canvas and must not mask readable marks.
- **No parallax:** absent entirely, not a zero-velocity second transform. Do not alter `_DungeonScene._geometry`, camera viewfinder, `_ClippedMaxViewport`, pointer callbacks, world child positions or `GameScreen`'s `Expanded` slot. Keep `dungeonVoid` as the game's own solid background. Flame 1.38.2 `GameWidget` inserts `backgroundBuilder` before its render widget. If the real scene renders opaque over the background, switch *only* the painter placement to a clipped viewport draw before `super.render` in `_DungeonScene.render`; report the observed proof and keep all content/geometry identical.

## Red → Green and proof

1. Add focused scene test first: rendered viewport on otherwise unknown cells must differ in broad values at separated sample positions while two renders with the same `Size` are byte-identical; sampling a scene with two different hidden map topologies but the same visible/explored projection must yield the same **background-only** pixels. Red is the current uniform void. Use a painter surface or scene-background render to isolate the nonsemantic layer; do not assert its private gradient stops or one screenshot golden.
2. Green implementation: verify background remains unchanged by hero step, pan and selected actor if viewport size is equal. Extend `dungeon_scene_test.dart` pan/focus/tap/long-press proof with the background mounted and compare returned logical tile positions before/after; use `dungeon_scene_bleed_test.dart` sentinel beyond viewport to prove no haze escapes into chrome. Assert no pointer/semantics node from background and foreground `#`, `.`, hero and target outlines remain visible.
3. From `packages/app`: `flutter test test/game/dungeon_scene_test.dart test/widget/dungeon_scene_bleed_test.dart test/grid_geometry_test.dart test/widget/crawl_layout_test.dart`; `dart format <touched Dart paths>`; `flutter analyze`. Record Red and Green output/exits; Main later owns device composition and final gates.

## Executor discretion

Exact low-level Flutter gradient/paint construction, cache lifetime keyed by viewport size, broad gradient centre and stop values **within** nonsemantic/subordinate requirement. No procedural noise seeded from gameplay state, no path-like shapes, animation controller or time dependence. If a technically necessary paint hook change is needed, use the locked placement fallback, not a world component.

## Escalate when

Backdrop cannot be observed beneath Flame; background paint needs a world-space transform or new pointer layer; shader leaks through the clipped map boundary; no visual depth is visible without semantic-looking topology or harmful contrast; repeat renders/unknown topology produce different background decisions.

## Handoff receipt

Red cause/exit, focused Green/format/analyzer exits, background-only comparison and equal-size determinism, topology-independence, unchanged hit coordinates and map bleed result; note any Flame placement fallback. Handoff is a deterministic atmospheric ASCII scene without parallax and with untouched chrome.
