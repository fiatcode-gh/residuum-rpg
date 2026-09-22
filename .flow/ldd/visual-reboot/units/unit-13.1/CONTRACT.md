# Unit 13.1 — The map bleed

Status: **drafted, awaiting explicit user approval**
Type: defect. Root-cause diagnosis under `flow-debugging`, then the smallest
correct fix.
Base: `main` at `907a4a83e7c592d4f6dd0c55e6f30c3b1b8bc49b`
Position: **first** in the roadmap approved 2026-09-18, before U14 and well
before U18 and U21, which both rewrite this seam.
Evidence:
`.flow/evidence/visual-reboot/unit-12.5-device/u125-g-battledock-bleed-color.png`
and `-grey.png`, plus `u125-g-ceiling-color.png` and the capsule G receipt.

## The defect

At worst-legal-battle density the dungeon's Flame canvas paints roughly
144 px — about 55 dp — **above its own top hairline**, outside the `Expanded`
box it was given. Because the map is a later sibling in the crawl's `Column`
than `BattleDock`, that overflow covers the dock opaquely: both activation
ring tokens are cut in half and the actor words behind them are hidden.

Unit 12's AC6 therefore **fails visually at the ceiling while its logic
passes** — the queue is correct, the rendering hides it. The user chose to
merge Unit 12 as-is and fix this afterwards; this is that unit.

## Why it runs first

U18 rewrites this viewport's lighting and U21 re-measures this exact seam's
dp budget. Both would inherit the bug and both would make it harder to
attribute. The defect is also the only thing in the epic that makes a
*correct* implementation look broken.

## Outcome

The dungeon canvas paints only inside the box it owns. `BattleDock` is never
covered. The number of dungeon rows the player can see is unchanged, or
changed only by an amount the unit measures and states.

## Boundaries

May change: `packages/app/lib/game/game_screen.dart`,
`dungeon_scene.dart`, `dungeon_scene_material.dart`, `grid_geometry.dart`,
and the app tests that cover them.

May not change: any file in `packages/core` or `packages/content`; the save
schema; `cameraCellSize`; the crawl's region order; anything the visual
system contract assigns to U14–U21. This unit fixes a defect; it does not
begin parity work.

## Traps

- **Do not reach for a `ClipRect` first.** If the Flame viewport is rendering
  more rows than its box owns, a clip hides the overflow while the camera
  keeps showing rows the box does not own — which silently invalidates the
  measured 7.93-rows-of-sight figure and turns a visible bug into an
  invisible one. Diagnose why the canvas exceeds its constraints, then decide
  whether clipping is part of the answer.
- One lead worth checking first, from the architect's read of
  `game_screen.dart:96-135`: the map sits in a `LayoutBuilder` → `Stack`
  whose only non-positioned child is `DungeonSceneHost`. `RenderStack` skips
  its clip layer when it detects no visual overflow, and a non-positioned
  child sized by the incoming constraints never reports any — so a child that
  *paints* beyond its reported size is painted unclipped. That is a
  hypothesis to test, not a diagnosis, and it does not explain **why** the
  canvas paints 55 dp beyond its box. Find that first.
- The reproduction is density-dependent. It appears at the worst legal
  battle, not in a quiet corridor, so the fixture matters:
  `unit-12.5-device/u125-g-fixture.json` is the scene that produced the
  evidence.

## Diagnosis, settled 2026-09-18

**Root cause.** Flame's default `MaxViewport.clip()` is an explicit no-op —
`flame-1.38.2/lib/src/camera/viewports/max_viewport.dart:26`, with the class
dartdoc stating "This viewport does not perform any clipping" — and
`GameRenderBox.paint` (`game_render_box.dart:146-151`) calls `game.render`
with no clip of its own. The scene's world always holds every tile in
visible ∪ explored (`dungeon_material.dart:171`'s own documented invariant),
routinely taller than the camera's window, and every tile paints wherever the
camera transforms it, inside the box or not. The disregarded constraint is the
viewport's own reported size: it positions the camera but is never enforced as
a paint boundary.

Nothing downstream catches it. `GameRenderBox` is `sizedByParent` with
`computeDryLayout` returning `constraints.biggest`, so it always reports the
correct box size no matter what it paints;
`RenderStack._hasVisualOverflow` is set only from a `Positioned` child's
geometry, and the map `Stack` at `game_screen.dart:99` has exactly one
non-positioned child — so the `Stack`'s default `Clip.hardEdge` never
installs a clip layer.

**The trap does not apply.** Measured at the reproduction, the `Expanded`
box, `game.canvasSize`, `camera.viewport.size` and `game.size` agree to
float32 precision. The camera's window already equals the box, so no fix
considered here can cost the player a row. The architect's second lead — a
stale canvas size near `BattleDock`'s height — is ruled out by that
measurement.

**Row count.** The ledger's 7.93 rows of sight stands uncorrected. The
diagnosis's narrower synthetic figure (5.79) is a `flutter_test` font-metric
artifact that packed the same 11 chips into 4 runs instead of the device's 3.

**Proof.** `packages/app/test/widget/dungeon_scene_bleed_test.dart` renders
the live game onto a sentinel-filled canvas 200 dp larger on each side and
asserts the pixel one dp beyond each edge stays sentinel. It reads a real
floor tile today. Both setup assertions pass first.

**Fix chosen by the user, 2026-09-18: clip inside the scene.** A `MaxViewport`
subclass overriding `clip`, `containsLocalPoint` and `onViewportResize` —
`FixedSizeViewport`'s three members — while inheriting `MaxViewport`'s
canvas-size tracking. It fixes the layer the diagnosis names, keeps the proof
valid and headless, adds no Flutter compositing layer, and travels with the
scene when U18 and U21 recompose the crawl. A widget-level `ClipRect` was
rejected: it would leave the game painting outside its box, relying on an
outer clip that a later recomposition can drop, and it would invalidate the
proof above.

## Acceptance criteria

1. The root cause is named in terms of a specific widget, render object or
   Flame component and the exact constraint it disregards — not as "the map
   overflows".
2. A reproduction exists that fails before the fix and passes after it, at
   the layer that owns the behaviour. If the overflow cannot be observed in a
   widget test, the unit says so plainly and proves it on device instead.
3. `BattleDock` is fully visible at the capsule G density: both ring tokens
   whole, both actor words readable.
4. The visible dungeon row count at the same density is **measured** before
   and after. If it changed, the unit states the new figure and why the
   change is correct; the 7.93-rows-of-sight figure in the ledger is updated
   rather than quietly contradicted.
5. Determinism is untouched: the same seed still produces the same floor and
   the same decoration.
6. `dart format`, `flutter analyze` and the full `flutter test` suite pass
   from `packages/app`.
7. ~~Device evidence at the capsule G density~~ — **amended 2026-09-18 by the
   user.** The fix lands at the game's own render call, which is exactly the
   layer the headless pixel proof observes, so a dedicated emulator pass with
   its save backup-and-restore ritual buys one screenshot and nothing else.
   **Confirmation on hardware moves to U14's device gate**, whose capsule list
   must include the ceiling-density crawl for this purpose.

## Non-goals

No lighting change, no palette change, no new asset, no chrome
recomposition, no type change, no log or timeline redesign. Every one of
those belongs to a later unit with its own contract.
