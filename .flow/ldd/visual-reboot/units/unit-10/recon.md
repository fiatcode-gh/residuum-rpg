# Unit 10 recon — authored art integration

Architect-owned. Verified at `main` = `4bf865c` (Unit 9 code `92fd4aa`) on
2026-09-16. The external ChatGPT bundle is evidence only and lives at
`../../external/unit-10-chatgpt-handoff/`.

## Intake validation of the external bundle

- `git merge-base --is-ancestor 92fd4aa… HEAD` → true, and
  `git diff --stat 92fd4aa… HEAD -- packages/` is empty. The bundle's
  `observed_ref` tree is exactly the app tree on `main`, so every source claim
  it made was checked against an unchanged surface.
- **The bundle FAILS the shipped validator** (`exit 2`,
  `invalid handoff: declared artifact is missing:
  .flow/ldd/visual-reboot/units/unit-10/HANDOFF.md`). Its `artifacts` entries
  are repository-root-relative, while schema v1 requires paths relative to the
  bundle root. The bundle was not repaired: it is **unvalidated external
  evidence**, reconciled here by reading the artifacts directly. Its paths are
  additionally stale after the relocation below.
- `design_status: partial`, `implementation_strategy: partial`,
  `authorization: not-carried`. No execution-grade plan was supplied, matching
  the bundle's own statement.
- The bundle's internal cross-references (`proposed-units/unit-10.md`,
  `asset-inventory.md`, `proposed-ledger-delta.md`) do not match its own
  filenames (`CONTRACT.md`, `ASSET-INVENTORY.md`, `LEDGER-DELTA.md`). Content
  was matched by subject, not by name.

## Restructuring performed (user-authorized, 2026-09-16)

- Authored masters moved `packages/app/assets/visual/` →
  **`art/visual-reboot/`**. They are 1254 x 1254 production masters, not
  shippable Flutter assets; leaving them in the app asset root would have made
  the first `assets:` declaration point at 48 MB of source art, and it mixed
  bundle provenance text files into a runtime asset root.
- Bundle provenance (`MANIFEST.txt`, `SHA256SUMS.txt`, `EXTRACT-NOTE.md`) moved
  with the masters and is unmodified.
- External bundle moved `units/unit-10/` → `external/unit-10-chatgpt-handoff/`,
  matching the `external/unit-2-chatgpt-handoff/` precedent. `units/unit-10/`
  now holds only architect-owned canonical records.
- Nothing under `packages/` was touched; `packages/app/assets/` no longer
  exists and is recreated only by the implementation with derived assets.

## Verified asset inventory (replaces the bundle's logical inventory)

All 31 PNGs verified byte-identical to `SHA256SUMS.txt` after the move, plus
`MANIFEST.txt` itself. The checksum file prefixes paths with `wave1/`/`wave2/`,
which the extraction flattened; matching is by suffix and is unambiguous
(31 files, 31 png entries, zero mismatches, zero ambiguities).

**Every asset is 1254 x 1254, 8-bit PNG.** Total 48.1 MB on disk.

| Group | Files | Colour | Alpha | Disk |
|---|---|---|---|---|
| `environments/ENV-001_stonebridge`, `ENV-002_forge`, `ENV-003_tavern` | 3 | RGB8 | opaque | 7.0 MB |
| `dungeon/crypt/DNG-001_floor_base`, `DNG-002_wall_base` | 2 | RGB8 | opaque | 6.3 MB |
| `dungeon/crypt/DNG-003/004_crack_overlay_a/b`, `DNG-005/006_rubble_small/medium` | 4 | RGBA8 | alpha | 3.7 MB |
| `dungeon/sea_cave/DNG-SC-001/002_floor/wall_material_source` | 2 | RGB8 | opaque | 5.5 MB |
| `dungeon/sea_cave/DNG-SC-003/004_crack_overlay_a/b`, `DNG-SC-005/006_rubble_small/medium` | 4 | RGBA8 | alpha | 5.0 MB |
| `dungeon/ruined_keep/DNG-RK-001/002_floor/wall_material_source` | 2 | RGB8 | opaque | 6.6 MB |
| `dungeon/ruined_keep/DNG-RK-003/004_fracture_overlay_a/b`, `DNG-RK-005/006_rubble_small/medium` | 4 | RGBA8 | alpha | 5.6 MB |
| `ui/icons/UI-P0-001…010` (potion, pack, wait, ascend, descend, melee, firebolt, mend, more, back) | 10 | RGBA8 | alpha | 8.8 MB |

### Facts that change the proposal

1. **Size is a hard constraint, not a detail.** One 1254² RGBA image decodes to
   **6.0 MB** of memory; the full set is ~186 MB resident. Icons are square
   masters for a roughly 24 dp target — a ~52x downscale. Shipping the masters
   as-is would add 48 MB to the APK and risk the hitch that acceptance
   criterion 13 forbids. Derived, size-appropriate assets are required, and
   ImageMagick (`/usr/bin/magick`) is available locally to produce them.
2. **Environment art is square (1:1)**, not a wide banner. Every screen seam
   must therefore decide a crop/fit, and a 1:1 image at phone width is ~411 dp
   tall — roughly 45% of the 923.4 dp phone height. Uncropped placement would
   displace controls.
3. **Icons are multitone** by the manifest's own words, so greyscale legibility
   of each icon is an acceptance question, not an assumption.
4. **Material sources are explicitly not guaranteed seamless** (manifest), and
   the crypt files are named `_base` while Sea-Cave/Ruined Keep are named
   `_material_source` — the same role, different naming generation.
5. **Exactly three environments exist** (Stonebridge, Forge, Tavern) and **no
   road material exists**, matching the contract's road exclusion.
6. A `melee` and a `back` icon exist even though the bundle excludes both from
   the first slice; assets existing is not scope.
7. There is no licensing/provenance metadata in the bundle beyond `MANIFEST.txt`.

## Source seams at `4bf865c`

### Dungeon material renderer — confirmed, `agent://DungeonRenderSeams`

All three external claims (a)/(b)/(c) confirmed at source.

- Authoritative per-cell input is `MaterialCell` (`dungeon_material.dart:25-44`):
  `position`, `kind` (wall/floor/stairsDown/stairsUp), `knowledge`
  (visible/remembered). **The cell carries no light**; light is a separate
  mask-clipped radial gradient.
- Unknown cells are **absent from `MaterialPlan.cells`**
  (`dungeon_material.dart:174-176`), so the renderer structurally cannot leak
  them. `visibleMaterialMask()` (`dungeon_scene_material.dart:102-114`) builds
  the visible-only clip path; `_drawVisibleLight()` (`:181-186`) clips the
  gradient to it.
- Remembered cells differ from visible by **both** flat darker fill
  (`palette.rememberedStone`) **and** absence of light, with
  `pattern: 0.0` — not hue alone (`materialCellPaint`, `:127-133`).
- Determinism: `_hash(position, salt, extra)` (`dungeon_material.dart:141-151`)
  is splitmix-style over position, `palette.themeSalt`, a per-variant salt and
  `kind.index`; `_markFor` (`:186-212`) yields grit/speck/crack/edge/pattern.
  `Random` is unreachable from the render path.
- Regional identity: `RegionMaterial` (`dungeon_palette.dart:3`) with
  `cryptStone`, `seaCaveStone`, `ruinedKeepMasonry`, `lowlandRoad`; palettes and
  `themeSalt` at `:9-72`; selection via `paletteForDungeon()`/`paletteForRoad()`
  (`:75-92`). Patterns `tideStrata`/`ashlarFracture`/`roadWear` chosen in
  `materialCellPaint` (`:138-153`).
- **Seams**: `materialCellPaint()` is the sole cell-to-paint decision point;
  `_PreparedMaterialCell` (`:234-419`) caches Paint/Path/Rect off the frame
  path; `_drawCellBase()` (`:178`) owns the fill and `_drawCellDecoration()`
  (`:182-208`) owns marks. An authored base texture belongs in `_drawCellBase`,
  authored overlays at the head of `_drawCellDecoration`.
- **No image loading exists anywhere in `packages/app/lib`** — no `AssetImage`,
  `Image.asset`, `rootBundle`, `instantiateImageCodec` or `decodeImageFromList`.
  Unit 10 introduces the first one.
- Existing proof surface: `dungeon_material_test.dart` (621 lines, mark
  determinism and decoration preconditions), `dungeon_scene_test.dart` (860
  lines, component adoption, pixel output, remembered-unlit, mask clipping),
  `dungeon_material_paint_test.dart` (1067 lines, per-palette paint decisions,
  per-cell decoration clipping). Pixel-level assertions already exist, so
  authored textures will move real assertions.
- **Hazard named by recon**: if authored variant selection introduces any new
  randomness it breaks determinism; variants must hash from the same inputs as
  marks. If an authored image carries baked-in lighting it double-lights against
  the existing gradient.

### Town rooms — confirmed with two corrections, `agent://RoomScreenSeams`

- `TownScreen` (`town_screen.dart:43-130`) is
  `SingleChildScrollView → ConstrainedBox → IntrinsicHeight → Column`: a fixed
  status block (name, descents, health, gold, materials, notice) to line 102, a
  `Spacer()` at 104, then seven `_Door`s. Seam: between `Notice` (100) and
  `Spacer` (104).
- `ForgeScreen` (`forge_screen.dart:33-95`) and `TavernScreen`
  (`tavern_screen.dart:18-69`) both return `TownRoom` (`town_style.dart:389-408`),
  a `Scaffold + AppBar + ListView` with `EdgeInsets.fromLTRB(20, 4, 20, 8)`.
  Seam: a new entry in `children[]` after `Notice`, before the first `Heading`.
  Usable width is therefore ~371 dp.
- **Correction 1 — there are two towns.** `stonebridge` and `northgate`
  (`packages/content/lib/src/world.dart:66,70`), identified by
  `TownViewState.town` (`town_bloc.dart:145`). No such gate exists in any screen
  today; the architect must introduce it. Only Stonebridge has authored
  environment art.
- **Correction 2 — Forge and Tavern exist in both towns.** They are
  town-scoped in state (per-town profile, materials, gates, purse; the rumor
  pool alone is global), so an ungated room illustration renders in Northgate
  as well. Whether room-typed art is town-neutral is an open contract question,
  not an implementation detail.
- Town screens have **no `Semantics`/`ExcludeSemantics` markup at all**. The
  precedent to follow is `world_route_diagram.dart`, which excludes decorative
  content explicitly.
- Height/order tests are load-bearing and will move: `town_shell_test.dart`
  proves the last of seven doors is reachable on a 600 dp-tall surface;
  `craft_rooms_test.dart:494-520` locks the forge's top-to-bottom section order
  by Y position; `tavern_screen_test.dart:184-223` locks the notice above the
  first heading and the six newest log lines in order. An illustration that is
  too tall or in the wrong slot fails these, and they are correct tests.

### Controls and shelf — confirmed with one scope-changing correction, `agent://ControlIconSeams`

- `pubspec.yaml:43-53`: `flutter:` carries only `uses-material-design: true`;
  the `assets:` block is commented out. Nothing in the repository references an
  app asset directory, and no `.gitignore` entry excludes one.
- Crawl controls: `_Control` (`game_screen.dart:498-520`) is a `FilledButton`
  with a single `Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
  monospace 12)`, each wrapped in `Expanded` inside one `Row`
  (`:237-350`). Disabled state is `onPressed: null` only — no word change.
  No `Semantics` label exists.
- **Correction 3 — the crawl control row is not a safe icon seam.** Equal-width
  `Expanded` children already ellipsise `Drink (…)` at five controls on a real
  phone (the inherited defect recorded at Unit 9's close). An icon costs 16-24 dp
  of the same ~82 dp cell, so icon-plus-label there is strictly worse unless the
  row's layout changes — which is a separate, frozen control surface.
- The battle shelf **is** a safe seam: `Wrap(spacing: 6, runSpacing: 4)`
  (`:604-656`) reflows instead of ellipsising. Actions: readied spells via
  `_shelfButton` (`:619-634`, text `'✳ Firebolt 2'`, armed adds a border **and**
  the word `— armed`), the `+N` overflow button (`:650-655`) opening a full
  sheet, `Drink (n)` and `Wait` via `_ShelfButton` (`:667-693`).
- Melee is a map tap (`_onMapTap` → `TileTapped`, `:203-236`), never a shelf
  button. The `UI-P0-006_melee` asset has no legal home.
- Back is Flutter's automatic `AppBar` leading widget: `pack_screen.dart:16`,
  `town_screen.dart:58` and `town_style.dart:397` (inherited by twelve room
  screens). A custom back icon is a fourteen-file navigation sweep. The crawl
  itself refuses pop entirely (`PopScope`, `:47-52`).
- Tests that pin exact control/action text: `battle_view_test.dart` (`Wait` at
  627/1100/1120/1129/1140; `✳ Firebolt 2`, `✳ Frost Lance 4`, `✚ Mend 3` at
  872-874), `battle_characterization_test.dart:119` (`Pack (0)`),
  `craft_surfaces_test.dart:157-160` (`Pick up`/`Mine` both un-ellipsised).
  These assert observable labels and stay valid under icon-**plus**-label.
- `test/support/phone.dart` sets 1080 x 2424 at DPR 2.625 and documents why:
  the default 800 x 600 surface is wider than a phone, so a row that overflows
  on hardware fits in the harness and the defect ships.
