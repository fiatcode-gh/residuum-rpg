# 03 — Warm stone inks, value falloff, remembered value, region fog

Governing: `../CONTRACT.md` scope items 1–2 (palette, value hierarchy),
`../PLAN.md` §2 G3, G4. Work from `packages/app`.

## Starting repository state

Task 02 committed: 13 × 16 grid, mono glyphs, reticles, floor `·`.
`glyph_plan.dart::glyphPlan(game, palette, …)` tints terrain by
`DungeonPalette.{wall,floor,stairs}`; `rememberedOpacity = 0.4`;
`_heroInk #FFFFFF`, `_monsterInk #D9A227`; `dungeon_palette.dart` has four
per-region terrain palettes, `litterInk #7FC8B8`, `nodeInk #A87BC0`;
`glyph_marks.dart::terrainPresentationInk` lerps toward `#E8C58A` within
d² ≤ 25; renderer applies `ink.withValues(alpha: cell.opacity)`.

## Owned files

`lib/game/glyph_plan.dart`, `lib/game/glyph_marks.dart`,
`lib/game/dungeon_palette.dart`, `lib/game/dungeon_scene.dart` (ink call
site, snapshot/palette reuse only); tests: `test/game/glyph_marks_test.dart`,
`test/game/glyph_plan_test.dart`, `test/game/armed_targets_test.dart`,
`test/game/dungeon_scene_test.dart`, `test/widget/palette_test.dart`,
`test/widget/world_screen_test.dart`, and any other caller of `glyphPlan(` or
`terrainPresentationInk`.

Non-goals: backdrop/pool/bloom/parallax (Task 04), chrome.

## Locked decisions

1. `dungeon_palette.dart`: `class DungeonPalette { const DungeonPalette({required this.fog}); final Color fog; }`
   with `crypt #1A2430`, `seaCave #152A3A`, `ruinedKeep #221F2A`,
   `lowlandRoad #1D2327`; `paletteForDungeon`/`paletteForRoad` unchanged.
   Public stone consts: `stoneWallLit #DCC08A`, `stoneWallShade #8F8C82`,
   `stoneFloorLit #B39B6C`, `stoneFloorShade #6B665B`,
   `stoneStairsLit #FFE3A0`, `stoneStairsShade #B8B09A`.
   `litterInk = crawlCold`; `nodeInk` stays `#A87BC0`.
2. `GlyphCell` gains `final Color shade;` via constructor `Color? shade` and
   initializer `shade = shade ?? ink` (const-compatible). Terrain cells:
   `ink` = lit, `shade` = shade via `terrainInk(Tile)` / `terrainShade(Tile)`
   (no palette). `glyphPlan(GameState game, {markedIds, actorPresentations, selectedActorId})`
   — the palette parameter is removed. Hero ink `crawlHero`, monster ink
   `crawlEnemy`. `rememberedOpacity = 0.24`. Draw order, visibility rules and
   ids unchanged.
3. `glyph_marks.dart`: delete `terrainPresentationInk`; add
   `Color glyphInk(GlyphCell cell, Position hero)` implementing PLAN G4
   exactly (terrain visible: `Color.lerp(shade, ink, light)` at alpha
   `0.55 + 0.45·light`, `light = (1 − t)²`, `t = clamp(d / fovRadius, 0, 1)`;
   terrain or node remembered: `shade` at `rememberedOpacity`; everything
   else: `ink` at alpha `cell.opacity`). The result already carries alpha.
4. Renderer: `mapGlyphStyle(glyphInk(cell, heroPosition))` for glyph and
   badge; recompute on projection or hero-position change only (pan reuse
   unchanged). `DungeonSceneSnapshot.fromViewState(GameViewState state)` (no
   palette); `_reusesProjection` drops the palette comparison;
   `DungeonSceneHost` keeps its `palette` parameter (Task 04 reads `fog`).

## Proof (Red first)

1. `glyph_marks_test.dart`: `glyphInk` for a visible wall at the hero is
   `stoneWallLit` at alpha 1.0; at distance 8 (t = 1) it is `stoneWallShade`
   at alpha 0.55; at distance 4 it is `Color.lerp(shade, lit, 0.25)` at alpha
   `0.6625`; value strictly decreases with distance along a row; a remembered
   wall is `stoneWallShade` at 0.24 and dimmer than the t = 1 visible wall;
   node/litter/monster/hero are their ink at their opacity. Red: symbol
   missing.
2. `glyph_plan_test.dart`: floor cells carry `stoneFloorLit`/`stoneFloorShade`
   in every region (plan no longer takes a palette); remembered opacity 0.24;
   unknown cells still absent; node/litter/monster/hero inks as locked.
3. `palette_test.dart`: rewrite to the new invariants — three dungeon and
   one road palette map exactly as before; four distinct `fog` values; stone
   value ladders `floor < wall < stairs` for both lit and shade
   (`HSVColor.value`); `litterInk`, `nodeInk`, `crawlEnemy` pairwise distinct
   hue; delete assertions that pin retired per-region terrain inks.
4. `world_screen_test.dart`: road-fight terrain inks now equal the stone
   inks for every route (the regional difference moves to fog, asserted in
   Task 04); keep its navigation/flow assertions.
5. `dungeon_scene_test.dart`: rendered text colour equals `glyphInk(cell, hero)`;
   remembered text alpha `closeTo(0.24, 0.001)`; recolour on hero move, not
   on pan (existing test, migrated).
Green: `flutter test test/game test/widget/palette_test.dart test/widget/world_screen_test.dart`,
`dart format <touched>`, `flutter analyze`.

## Executor discretion

Whether `terrainInk`/`terrainShade` are two switches or one returning a
record; test helper shapes.

## Escalate when

`fovRadius` is not exported/usable from app; encounter visibility is not
bounded by it (then report the observed radius); a const-constructor issue
blocks `shade ?? ink`; any test shows a glyph for an unknown cell.

## Completion receipt

Red assertion, Green command/exit, analyzer/format exits, table of the
five sampled `glyphInk` values you asserted. Commit:
`feat(app): light crawl terrain with warm stone and value falloff`.
