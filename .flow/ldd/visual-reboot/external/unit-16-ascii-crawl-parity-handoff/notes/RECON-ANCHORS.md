# U16 Recon Anchors — observed at `374ee775e6fd1c29519dab8fe9d597dd38650593`

These anchors are evidence for local freshness recon, not a replacement for it.

## Git truth

- `main = 374ee775e6fd1c29519dab8fe9d597dd38650593`
- PR #24 is merged.
- PR #24 title: `feat: establish row control chip grammar`
- PR verification reported:
  - formatter clean;
  - analyzer clean;
  - 1,127 app tests;
  - worst legal device chrome 591.238 dp;
  - armed/unarmed map rectangle unchanged;
  - save restores MATCH.

`RESUME.md` is stale and still says U15 is active / awaiting integration.

## U15 production facts now present

### `packages/app/lib/style/surfaces.dart`

`FramedRow` exists with:

- 44×44 dp leading envelope (`tapTarget`);
- centered 36×36 dp circular medallion well;
- transparent fill;
- `rule`/`hairline` ring;
- null content remains measurable;
- supplied medallion is clipped/centered.

### `packages/app/lib/game/crawl_action_row.dart`

`CrawlAction` now has:

- stable `id`;
- visible `label`;
- separate `metadata`;
- optional icon;
- armable/armed state.

The row:

- asserts id uniqueness;
- keys chips by id;
- retains measure-all-candidates / shortest-legal behavior;
- still reserves metadata and armed-caption height;
- still uses an 18 dp current `ActionIconImage` slot;
- still reserves common chip geometry.

### `packages/app/lib/game/dungeon_scene.dart`

- Flame remains scene-only and input remains intent-based.
- `_ClippedMaxViewport` protects the map allocation.
- `GridGeometry.camera(...)` remains the hit-test/camera authority.
- `cameraCellSize` remains 36 dp.
- material + glyph layers synchronize separately.
- pan/tap/long-press are already routed through stable grid geometry.

### Current active dungeon material stack

`packages/app/lib/game/dungeon_scene_material.dart` and `dungeon_material.dart` still implement:

- per-cell material fills;
- authored floor/wall surface masks;
- authored material image sampling;
- deterministic grit/crack/speck/pattern decisions;
- hero-local light clipped to visible material.

`packages/app/lib/art/art_assets.dart` still declares dungeon MaterialArt and TerrainOverlayArt assets.

U16's visual pivot targets this active picture, not the game-state model.

### Crawl chrome

`crawl_style.dart` currently includes:

- timeline token sizes;
- 104 dp log peek;
- chip spacing/padding;
- max 5 columns;
- state skins.

`crawl_status.dart` currently renders:

- place;
- battle glyph/word;
- depth pair;
- HP and conditional Mana resource meters.

`log_drawer.dart` currently renders:

- 104 dp compact peek;
- expanded `MESSAGE LOG`;
- text-glyph category marks in 20 dp wells;
- follow/unread behavior.

These are eligible for U16 presentation recomposition while semantics remain locked.

## Existing asset boundary

Already-shipped action icons exist for only a subset of actions/spells. U16 does not generate missing ones.

The old dungeon texture assets may remain on disk even if active rendering stops using them. Cleanup/deletion is a separate decision unless fresh planning proves warm-up/decode must change to avoid runtime waste.

## Reference images bundled with this handoff

- ASCII atmosphere bible
- exploration mock
- combat/targeting mock
- expanded-log mock

Use them as visual references; use source as gameplay truth.
