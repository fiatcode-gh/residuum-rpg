# U16 Source Recon

Observed 2026-09-23 at `374ee775e6fd1c29519dab8fe9d597dd38650593` (`main`). The worktree was clean before intake. The external U16 handoff validator passed, and every listed artifact/reference SHA-256 receipt matched. The handoff targets this repository and `visual-reboot` epic. It carries no implementation authorization.

## Reference review

Inspected all four bundled references:

- `external/unit-16-ascii-crawl-parity-handoff/reference/ascii-atmosphere-art-bible.png`
- `external/unit-16-ascii-crawl-parity-handoff/reference/ascii-exploration-mock.png`
- `external/unit-16-ascii-crawl-parity-handoff/reference/ascii-combat-targeting-mock.png`
- `external/unit-16-ascii-crawl-parity-handoff/reference/ascii-expanded-log-mock.png`

The art bible's three-layer model is semantic ASCII, visibility-clipped lighting, and a non-semantic depth field. The screen mocks emphasize the map, compact factual chrome, event log, and one action shelf; the combat mock adds a compact activation timeline and distinct target/selection treatment. Illustrative `Torch`, `Hungry`, `Clear`, `Seed`, `Auto-walk`, `Help`, sample equipment/stats, and dotted paths are not product requirements. Treat references as visual targets only; current application state/action behavior is authoritative.

## Verified source seams

- `game/glyph_plan.dart`: terrain already maps wall/floor/stairs to `#`, `.`, `>`, `<`; visible cells use full opacity, explored cells use `rememberedOpacity`, unknown cells are omitted. Monsters are projected only in visible cells; existing entities/nodes remain glyph marks.
- `game/dungeon_scene.dart`: `DungeonSceneSnapshot` holds glyph projection, `MaterialPlan`, camera focus and pan. Flame scene owns tap/drag/long-press callbacks and `GridGeometry.camera`; glyph overlays contain actors, badges, selection and target geometry. `cameraCellSize` remains the 36 dp input/projection contract.
- `game/dungeon_scene_material.dart`: `MaterialComponent` currently paints material bases, visible-only light, authored surfaces, and per-cell grit/pattern/overlay decoration. Its current authored-image and structural-material path is the active map visual targeted for replacement. Actor/target rendering is separately owned by `_GlyphComponent`.
- `game/game_screen.dart`: `GameScreen` composes `CrawlStatus`, conditional `BattleDock`, an `Expanded` map slot, `LogPeek`, and the single `CrawlActionRow`; `LogDrawer` overlays without reflowing the map. Input dispatch remains in the existing bloc/tap paths.
- `game/crawl_status.dart`, `game/activation_timeline.dart`, `game/log_drawer.dart`, and `game/crawl_action_row.dart` own status facts, timeline, log presentation, and actions respectively. Their behavior/identity boundaries must remain intact.
- `art/dungeon_art.dart` and `main.dart`: `warmUpArt()` currently decodes every `MaterialArt` and `TerrainOverlayArt` at app launch, then precaches environment illustrations. The active scene supplies `dungeonArt` to its material component. Stop unnecessary dungeon decoding only if the plan confirms it is within the clean cutover; retain environment precaching and historical asset masters unless separately authorized.
- U15 action identities, current shortest-legal fit search, reserved armed geometry, and existing 44/36 dp `FramedRow` medallion are already implemented. Do not invent additional art wells just because an image contains icons.

## Existing proof seams

- `packages/app/test/game/dungeon_scene_test.dart`, `dungeon_material_paint_test.dart`, `dungeon_authored_material_test.dart`, `dungeon_render_style_test.dart`, `material_sampling_test.dart`, and root `packages/app/test/grid_geometry_test.dart` cover projection, material pixels, visibility, texture/material behavior, and grid geometry.
- `test/widget/crawl_layout_test.dart`, `crawl_status_test.dart`, `crawl_action_row_test.dart`, `crawl_controls_test.dart`, and `log_drawer_test.dart` cover screen allocation, real crawl facts, action layout/dispatch, and log transitions/semantics. In particular, log drawer tests pin map rectangle stability; U16 must preserve this invariant.
- `test/art/warm_up_test.dart` and `art_catalogue_test.dart` currently prove asset catalog and warm-up behavior; any active-decode cutover changes these contracts.

## Reconciled authority and forward pointer

The canonical `RESUME.md` and the ledger's last state still described U15 against the older PR #23 revision. Git truth now verifies PR #24's merge at the handoff's observed SHA; U15 is complete and integrated. Append-only ledger history remains untouched. The external proposal is accepted as U16 design evidence, subject to the locally governing contract approval. Its implementation strategy is explicitly partial; fresh local execution-grade planning must resolve renderer seams, geometry, placeholders, proof and task briefs. No production code, asset generation, plan dispatch, or implementation is authorized by this intake.
