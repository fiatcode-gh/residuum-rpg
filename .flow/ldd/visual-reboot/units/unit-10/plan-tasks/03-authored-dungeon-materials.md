# Task 03 — Authored dungeon materials and overlays

Owner: one fresh `flow-plan-executor` on the Unit 10 feature checkout. Read
`../PLAN.md` and `../CONTRACT.md` before editing. Tasks 01 and 02 have landed
and been accepted; you inherit their repository state, not their sessions.

## Expected starting repository condition

- The `residuum-visual-reboot-10` checkout, branched from `4bf865c`, with tasks
  01 and 02 present and green.
- `packages/app/lib/art/art_assets.dart` exposes `MaterialSurface`,
  `MaterialArt` (six values, `of(region, surface)`), `OverlayKind` and
  `TerrainOverlayArt` (twelve values, `of(region, kind)`), all returning null
  for `RegionMaterial.lowlandRoad`.
- `packages/app/lib/art/dungeon_art.dart` exposes `DungeonArt` with a public
  `const DungeonArt({required surfaces, required overlays})`, a
  `const DungeonArt.none()`, `surfaceFor`, `overlayFor`, and the library getter
  `dungeonArt` which is `none()` unless `warmUpArt()` has run.
- The 6 material sheets (576x576 grey PNG) and 12 overlays (144x144 grey+alpha
  PNG) exist under `packages/app/assets/visual/dungeon/` and are declared.
- `dungeon_scene_material.dart` is 566 lines; `render()` at `:278-287` draws
  bases, then `_drawVisibleLight()`, then decorations.
  `MaterialComponent`'s only constructor is at `:208`.
  `_PreparedMaterialCell.from` is at `:361-466`.
- `dungeon_material.dart` is 277 lines; `_hash` at `:149-161`, `_unit01` at
  `:163`, `_markFor` at `:234-277`.
- `dungeon_scene.dart:309-317` constructs `MaterialComponent(material)`.
- Architect-owned `.flow/**` records and the untracked `art/` masters may be
  dirty. Preserve those bytes exactly.

Inspect branch and worktree before editing. Implementation on `main` is
forbidden. If any named seam differs from `../PLAN.md`, stop and report rather
than adapting silently.

Every command below runs from `packages/app`.

## Behavioural slice

Paint Crypt, Sea-Cave and Ruined Keep floors and walls from the authored
material sources, and decorate known terrain with authored cracks and rubble —
entirely inside the existing `MaterialPlan` projection, with topology,
knowledge, visibility, local light, hit testing, camera geometry, stairs, items,
resource nodes, actors, target marks and lowland roads all unchanged, and with
no decode or allocation on the per-cell or per-frame path.

Files:

- `packages/app/lib/game/dungeon_material.dart` (one new public function);
- `packages/app/lib/game/dungeon_scene_material.dart` (one new mask function,
  one new render pass, one optional constructor parameter, overlay fields in
  the prepared-cell factory);
- `packages/app/lib/game/dungeon_scene.dart` (one call-site argument);
- `packages/app/test/art/material_sampling_test.dart` (new);
- `packages/app/test/game/dungeon_authored_material_test.dart` (new).

Do not touch `MaterialCell`, `MaterialMark`, `MaterialPlan`, `materialPlan`,
`_markFor`, `_masonryMass`, `MaterialCellPaint`, `materialCellPaint`,
`visibleMaterialMask`, `stoneLitColor`, `_crackPath`, `_patternPath`,
`_WallFaces`, `dungeon_palette.dart`, `glyph_plan.dart`, `glyph_marks.dart`,
`grid_geometry.dart`, `game_bloc.dart`, `game_screen.dart`, `lib/art/**`,
`lib/town/**`, `packages/core`, `packages/content`, or **any existing test
file**.

## Locked implementation

`../PLAN.md` section 5 is the recipe, including its correction of the recon's
proposed seam. Where this brief and the plan differ, the plan wins; where the
plan and `../CONTRACT.md` differ, stop and report.

### 1. `dungeon_material.dart` — one new public function

```dart
/// A presentation-stable 0..1 draw from the material layer's own hashing.
double materialPhase(Position position, int salt, int extra) =>
    _unit01(_hash(position, salt, extra));
```

That is the entire change to this file. No new field, no new salt inside
`_markFor`, no change to any existing function, no new randomness.

### 2. `dungeon_scene_material.dart`

#### The kind-filtered mask

```dart
/// The visible-only clip for one authored material surface.
Path visibleSurfaceMask(MaterialPlan plan, MaterialSurface surface)
```

Built exactly like `visibleMaterialMask` (`:97-111`) — a rect per cell at
`cameraCellSize` — but skipping any cell whose `knowledge` is not `visible` and
any cell whose kind the surface does not accept. `MaterialSurface.floor`
accepts `MaterialTileKind.floor`, `stairsDown` and `stairsUp`;
`MaterialSurface.wall` accepts `MaterialTileKind.wall`.

Stairs take the floor field because `materialCellPaint:192-197` already puts
them in the continuous stone field with `pattern: none`, `speck: false`,
`crackStrength: 0` and `edge: 0`, and the stair identity is a glyph component
drawn above the terrain layer (`dungeon_scene.dart:25-41`). Criterion 8's "no
stairs presentation change" holds because the marking above the stone is never
touched.

`visibleMaterialMask` is **not** modified, not given an optional parameter, and
not reimplemented in terms of the new function.

#### The constructor

```dart
MaterialComponent(MaterialPlan initialPlan, {this.art = const DungeonArt.none()})
```

with `final DungeonArt art;`. **The default is what keeps roughly twenty
existing `MaterialComponent(plan)` call sites in
`dungeon_material_paint_test.dart` and `dungeon_scene_test.dart` compiling and
rendering exactly the output they assert today.** Do not make it positional, do
not make it required, do not make it nullable.

#### The render order

```dart
@override
void render(Canvas canvas) {
  super.render(canvas);
  for (final cell in _cells) {
    _drawCellBase(canvas, cell);
  }
  _drawVisibleLight(canvas);
  _drawAuthoredMaterial(canvas);
  for (final cell in _cells) {
    _drawCellDecoration(canvas, cell);
  }
}
```

**The authored pass goes after the light, and this is not negotiable.**
`_visibleLight` (`:268-274`) runs between two fully opaque colours —
`stoneLitColor` lerps opaque palette colours and `HSLColor.withLightness`
preserves alpha — and `_drawVisibleLight` (`:293-300`) fills the whole mask
bounds with it. Every visible cell's `basePaint` fill is therefore already
overpainted; only remembered cells, which lie outside the mask, ever show it.
An authored texture in `_drawCellBase` would be invisible on exactly the cells
it is meant to decorate. `_drawCellBase` and `_drawVisibleLight` are unchanged.

#### The authored pass

```dart
void _drawAuthoredMaterial(Canvas canvas) {
  _drawAuthoredSurface(canvas, _authoredFloor);
  _drawAuthoredSurface(canvas, _authoredWall);
}

void _drawAuthoredSurface(Canvas canvas, _AuthoredSurfacePass? pass) {
  if (pass == null) return;
  canvas
    ..save()
    ..clipPath(pass.mask)
    ..drawRect(pass.bounds, pass.paint)
    ..restore();
}
```

`_AuthoredSurfacePass` is a private holder of `final Path mask`,
`final Rect bounds` and `final Paint paint`. Both passes are built once per plan
adoption in `_rebuildRenderPlan` (`:240-275`), beside `_visibleMask`, and are
null when the palette has no authored surface for that kind or when the mask's
bounds are empty. **Two clip-and-fill operations for the whole layer, not a
per-cell loop**, and nothing allocated per frame.

The paint:

```dart
Paint()
  ..blendMode = BlendMode.softLight
  ..filterQuality = FilterQuality.medium
  ..shader = ui.ImageShader(
    image,
    TileMode.mirror,
    TileMode.mirror,
    (Matrix4.identity()
          ..translate(phase.dx, phase.dy)
          ..scale(0.5))
        .storage,
  );
```

with

```dart
const double _texturePeriod = 288; // 576 source px at scale 0.5

Offset _texturePhase(DungeonPalette palette, MaterialSurface surface) => Offset(
  materialPhase(const Position(0, 0), palette.themeSalt ^ 0x6666, surface.index) *
      _texturePeriod,
  materialPhase(const Position(0, 0), palette.themeSalt ^ 0x7777, surface.index) *
      _texturePeriod,
);
```

Binding details a reviewer will check:

- **`BlendMode.softLight`, not multiply, modulate, overlay or alpha.** The
  derived sheets are mean-centred on mid-grey, which is softLight's identity
  element, so the authored layer contributes texture with no net luminance
  shift: the mask-clipped radial gradient keeps owning brightness and the
  palette keeps owning hue. That is what makes criterion 6's "no baked lighting
  double-exposure" true rather than argued.
- **`TileMode.mirror` on both axes.** The masters are explicitly not guaranteed
  seamless (`art/visual-reboot/MANIFEST.txt:54`); mirroring makes any image tile
  without a seam by construction.
- **`scale(0.5)` — two source pixels per world unit.** A 576 px sheet covers 288
  world units, eight cells, so each 36-unit cell shows a distinct window and
  adjacent cells show adjacent windows. The field is continuous across cell
  boundaries: this is one world-space field, **not one bitmap per cell**, which
  the contract prohibits, and it is what keeps the 36 dp grid from appearing.
- **Salts `0x6666` and `0x7777`** extend the `0x1111..0x5555` series in
  `_markFor` without colliding. Do not reuse an existing salt and do not invent
  a third.
- **There is deliberately no per-floor variation.** `MaterialPlan` carries no
  floor identity, and `heroPosition` changes with every step. Every floor of a
  region shares one phase. **Wanting per-floor variety is an escalation**, not
  an implementation choice — it would require changing a projection this unit
  may not touch.
- `RegionMaterial.lowlandRoad` resolves to null through `MaterialArt.of`, so
  both passes are null for a road and the road renders byte-identically to
  `4bf865c`. Do not add a road branch, a road fallback or a road asset.

#### The authored overlay

Drawn at the **head** of `_drawCellDecoration` (`:302-323`), inside the existing
`clipRect(cell.rect)` and before the grit pass. Its image, paint and destination
rect are computed once in `_PreparedMaterialCell.from` (`:361-466`) from
`mark`, `paint`, `palette` and the component's `art`, which the factory now
takes as a parameter.

Selection, using the gates that already exist — do not invent new ones:

| Gate (identical to today's) | Overlay | Variant |
| --- | --- | --- |
| `paint.crackStrength > 0 && mark.crack > 0` (today's `crackPath != null` condition, `:380-382`) | `OverlayKind.crackA` / `crackB` | `crackB` iff `mark.crack >= 0.3` |
| `paint.speck && mark.speck` (today's `speck` condition, `:417`) | `OverlayKind.rubbleSmall` / `rubbleMedium` | `rubbleMedium` iff `mark.grit >= 0.2` |

Binding details:

- **At most one overlay per cell.** The crack gate requires a visible exposed
  wall and the speck gate requires a visible non-stairs floor, so they are
  mutually exclusive by kind. Use one nullable `ui.Image? overlayImage` field,
  not two.
- **When an authored overlay draws, the procedural mark it replaces does not.**
  If `overlayImage != null` for a crack-gated cell, `crackPath`/`crackPaint`
  are null for that cell; likewise the `speck` circle. Drawing both would double
  one decorative fact.
- **Remembered cells can never carry an overlay**, because `_markFor:256-261`
  gives remembered geometry `crack: 0` and `speck: false`. Do not add a
  knowledge check — the absence is already structural, and an added check would
  suggest the mark could say otherwise.
- **Destination is `cell.rect`**, source is the whole image, paint is
  `Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: overlayOpacity)
  ..filterQuality = FilterQuality.medium` with
  `const double overlayOpacity = 0.55;`. The measured alpha coverage of the
  rubble masters is 0.23 (small) and 0.41 (medium); at full opacity they would
  read as objects rather than surface debris.
- **`hasDecoration` accounts for the overlay**, so a cell whose only decoration
  is an authored overlay still enters the clip and draws.
- The clip, the pass order and every existing decoration pass are otherwise
  unchanged.

### 3. `dungeon_scene.dart`

One argument at `:312`:

```dart
_material = MaterialComponent(material, art: dungeonArt);
```

plus `import '../art/dungeon_art.dart';` in the existing import order.

**`onLoad` must stay exactly as it is** (`:205-210`): `await super.onLoad()`,
set the anchor, `_synchronizeComponents()`. **Do not await an asset load
there.** `dungeon_scene_test.dart:421-464` and `:466-520` pump
`DungeonSceneHost` and read `game.world.children` after a *single*
`tester.pump()`; an awaited load would leave the world empty at that pump and
break both tests. The art is decoded at boot by `warmUpArt()` and read
synchronously here. Nothing else in this file changes.

## Red/Green proof

Establish Red before the production edits. Write both new test files against the
interfaces above first: `material_sampling_test.dart` fails to compile on the
missing `visibleSurfaceMask` and `materialPhase`, and
`dungeon_authored_material_test.dart` fails on byte-equality between the
art-loaded and no-art renders because no authored pass exists yet.

### Synthetic images — no asset involved

```dart
Future<ui.Image> twoTone(int size) {
  final pixels = Uint8List(size * size * 4);
  for (var i = 0; i < size * size; i++) {
    final value = (i ~/ size) < size ~/ 2 ? 0x40 : 0xC0;
    pixels[i * 4] = pixels[i * 4 + 1] = pixels[i * 4 + 2] = value;
    pixels[i * 4 + 3] = 0xFF;
  }
  final done = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    pixels, size, size, ui.PixelFormat.rgba8888, done.complete,
  );
  return done.future;
}
```

**The sheet must be two-tone, not uniform.** A uniform mid-grey sheet is
`softLight`'s identity element and would render byte-identically to no art at
all, turning tests 1 and 7 below green for the wrong reason. Build overlay
images the same way with a non-zero alpha region and a fully transparent
remainder. Whether this helper lives in the test file or `test/support/` is
yours.

### New suite — `packages/app/test/art/material_sampling_test.dart`

Pure tests, `// arrange` / `// act` / `// assert`.

1. **the surface mask follows visibility and kind** — build a plan with a
   visible floor, a visible wall, a visible `stairsDown`, a remembered floor and
   an unexplored position. `visibleSurfaceMask(plan, MaterialSurface.floor)`
   contains the visible floor's and the stairs' centres and not the wall's, the
   remembered cell's or the unknown position's;
   `visibleSurfaceMask(plan, MaterialSurface.wall)` is the complement.
2. **the same inputs give the same phase** — `materialPhase` twice over equal
   inputs is equal; changing the salt or the `extra` changes it; the result is
   in `[0, 1]`.
3. **each region draws its own phase** — the six `(palette, surface)` phases are
   pairwise distinct and stable across repeated calls.

### New suite — `packages/app/test/game/dungeon_authored_material_test.dart`

Reuse `dungeon_material_paint_test.dart:12-122`'s harness shape — the `_arena`
string, `_heroAt`, `_game`, `_renderMaterial`, `_rgba`, `_pixel`, `_bytes`,
`_at`, `_singleCellPlan`, and a 12x36 by 5x36 render target. Copy what you need
into the new file; **do not edit the existing file to share helpers.**

1. **authored material changes visible stone** — a crypt plan rendered with a
   two-tone sheet differs from the same plan rendered with
   `const DungeonArt.none()` in at least one visible-floor pixel.
2. **remembered stays exactly flat under authored art** — with art loaded, the
   remembered cell's centre pixel is exactly `palette.rememberedStone` — the
   same assertion `dungeon_material_paint_test.dart:1018` makes without art.
3. **unknown stays void under authored art** — with art loaded, an unexplored
   cell's pixel is exactly `dungeonVoid`.
4. **the light still owns brightness** — with a **mean-0.5** synthetic sheet, a
   visible cell near the hero has greater luminance than a visible cell far from
   it. This is the no-double-exposure proof.
5. **identical state renders identically** — two renders of one plan and one
   `DungeonArt` are byte-equal, and a second `materialPlan` built from the same
   `GameState` renders byte-equal to the first.
6. **the road is untouched by authored art** — a `DungeonPalette.lowlandRoad`
   plan renders byte-equal with a fully populated `DungeonArt` and with
   `const DungeonArt.none()`.
7. **an authored overlay replaces its procedural mark** — stage a plan with one
   visible exposed wall whose `MaterialMark` has `crack > 0` under
   `DungeonPalette.crypt`: with overlay art the cell's pixels differ from the
   no-art render, and the procedural crack stroke is gone (sample a point on
   `_crackPath`'s locus and assert it no longer matches the no-art render's
   value there).
8. **an ungated cell draws no overlay** — a visible wall whose `mark.crack` is 0
   renders byte-equal with and without overlay art.
9. **an overlay never leaves its cell** — a single-overlay-cell plan leaves every
   pixel outside that cell's rect equal to the no-art render.

Do not assert source text, field copies, or paint-object identity. No golden
images (`AGENTS.md`).

### Existing tests: zero changes, all must stay green

Every `MaterialComponent(plan)` call site leaves `art` at
`const DungeonArt.none()`, so all of these still assert exactly the procedural
output they assert today:

- `test/game/dungeon_material_paint_test.dart` (1067 lines) — every pixel,
  byte-equality and paint-decision assertion, including
  `remembered == rememberedStone` (`:284-285`, `:1018`),
  `unknown == dungeonVoid` (`:229`, `:1020`), per-palette byte inequality
  (`:895-897`), pattern-interior-only (`:901-950`) and stroke-containment
  (`:1022-1034`);
- `test/game/dungeon_material_test.dart` (621 lines) — mark determinism and
  decoration preconditions;
- `test/game/dungeon_scene_test.dart` (860 lines) — component adoption,
  stairs-above-material, tap/pan projection.

If any of them fails, **the implementation is wrong** — in particular a failure
in the remembered, unknown, void-containment or byte-equality assertions means
the art leaked past a mask. Stop and report; do not adjust the test.

## Proof commands

From `packages/app`, after Red and after Green:

```sh
flutter test test/art/material_sampling_test.dart \
  test/game/dungeon_authored_material_test.dart \
  test/game/dungeon_material_paint_test.dart \
  test/game/dungeon_material_test.dart \
  test/game/dungeon_scene_test.dart

dart format --set-exit-if-changed --output=none \
  lib/game/dungeon_material.dart lib/game/dungeon_scene_material.dart \
  lib/game/dungeon_scene.dart \
  test/art/material_sampling_test.dart \
  test/game/dungeon_authored_material_test.dart

flutter analyze
flutter test
```

`flutter analyze` and the final full `flutter test` are in scope: you are the
only writer at this point in the sequence, and changing the renderer's pass
order has a blast radius wider than the focused list. Main re-runs the same
gate afterwards; that is acceptance, not duplication. Do not run an app build,
an emulator, a device install, a `git commit`, a `git push`, or any external
write.

## Executor discretion

Yours: the names of `_AuthoredSurfacePass`, `_drawAuthoredMaterial`,
`_drawAuthoredSurface`, `_texturePhase` and any private field or local; whether
`_texturePeriod` and `overlayOpacity` are file-private constants or private
statics; where the synthetic-image helper lives; the exact fixture staging
(seeds, positions, hand-built `MaterialMark` values) for the new tests; import
ordering; whether the new public functions carry dartdoc.

Not yours: the render-pass order or the decision to draw after the light;
`BlendMode.softLight`; `TileMode.mirror` on both axes; `scale(0.5)` and the
288-unit period; the `0x6666`/`0x7777` salts; the no-per-floor-variation rule;
`visibleSurfaceMask`'s signature or its floor/stairs/wall kind filter; the
decision not to modify `visibleMaterialMask`; `MaterialComponent`'s optional
named `art` with a const `none()` default; the two overlay gates, the two
variant thresholds, the replace-not-add rule, `overlayOpacity`, or the per-cell
clip; the requirement that `onLoad` stays synchronous; any verdict in the
"existing tests" section.

## Escalate when

- the authored pass cannot be drawn after the light without disturbing the
  mask-clipped gradient, or a palette visibly double-lights;
- `ui.ImageShader` with `TileMode.mirror` is unavailable or behaves differently
  from the plan's assumption on the pinned Flutter version;
- a mirror repeat is visible in a render test, or the eight-cell period produces
  an obvious tile;
- per-floor texture variation appears to be needed;
- an authored overlay cannot be kept inside its own cell rect, or cannot be told
  apart from a resource node, item, stair marking, actor or target mark;
- any existing pixel, byte-equality, determinism or containment assertion fails
  — report it as a leak, never adjust the test;
- the material sheets' means make `softLight` visibly darken or brighten the
  dungeon (a derivation fault, escalate to Main with the measured means);
- a fix would require `MaterialCell`/`MaterialMark`/`MaterialPlan`/
  `materialCellPaint`/`_markFor`, `dungeon_palette.dart`, `game_bloc.dart`,
  `packages/core`, `packages/content`, an asset change, a `git commit`, or
  implementation on `main`.

Report; do not redesign the contract.

## Handoff state and completion receipt

The task is complete when: `materialPhase` and `visibleSurfaceMask` exist with
exactly the locked signatures; `MaterialComponent` takes an optional `art` with
a const `none()` default; the authored pass sits between the light and the
decoration and is two clip-and-fill draws for the whole layer; the authored
overlay is gated off the existing marks and replaces the mark it stands in for;
`dungeon_scene.dart` passes `dungeonArt` and `onLoad` is unchanged; the twelve
focused tests are green; all three existing dungeon suites are green
**unchanged**; `flutter analyze` is clean; the full `flutter test` passes with
no suite regressed; formatting is clean on touched files; and nothing outside
the named files changed.

Report to Main in at most eight prose lines:

- branch and base revision, and the Red you observed;
- the two new public signatures and the new constructor parameter's default;
- where the authored pass sits in `render()` and how many draw calls it makes;
- which of the twelve focused tests cover criteria 6, 7, 8 and 9, and which
  covers the no-double-exposure claim;
- explicit confirmation that `dungeon_material_paint_test.dart`,
  `dungeon_material_test.dart` and `dungeon_scene_test.dart` are byte-unchanged
  and green;
- the results of the four proof commands;
- anything a device pass must settle (whether strata, ashlar fracture and wall
  edges still read under texture; whether the mirror period or the overlay
  opacity needs bounded correction);
- any escalation left open for Main's acceptance review.
