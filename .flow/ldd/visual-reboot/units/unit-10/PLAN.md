# Unit 10 — Authored Art Integration: Execution Plan

Status: **execution-grade; planning only.** This artifact does not authorize
production implementation. The user approves the plan separately before any
executor runs.

Derived from the user-approved `CONTRACT.md` (approval and decisions D1/D2/D3
recorded at `../../LEDGER.md:1533-1551`), `units/unit-10/recon.md`, the Unit 10
intake at `../../LEDGER.md:1487-1551`, the epic's locked cross-unit contracts,
`AGENTS.md`, and the planner's own source and asset recon recorded below.

## Source base and dirty-state assumption

The source base is `4bf865c` on `main` — the merged Unit 9 head. Every source
line this plan depends on was re-read at that revision by the planner; the
recon's references were confirmed rather than trusted, and the corrections
below are the planner's own.

`packages/` is **clean** at that base. The worktree is dirty only in
architect-owned authority and unversioned art: modified
`.flow/ldd/visual-reboot/LEDGER.md` and `RESUME.md`, untracked
`.flow/ldd/visual-reboot/external/unit-10-chatgpt-handoff/`, untracked
`.flow/ldd/visual-reboot/units/unit-10/` (contract, recon, this plan, its task
briefs), and untracked `art/` holding the 31 approved masters plus their
provenance text. Executors preserve every one of those bytes: never stash,
revert, commit, move, re-derive over, or edit them. `art/visual-reboot/**` is
**read-only input** to this unit.

A changed app revision requires targeted revalidation of the named seams below,
not automatic replanning.

## Execution boundary and dependency graph

Implementation is **prohibited on `main`**. After explicit user approval of this
plan, use one non-isolated feature checkout branched from `4bf865c`, by house
convention `residuum-visual-reboot-10`.

```text
01-asset-pipeline-and-catalogue
  -> 02-environment-illustrations
  -> 03-authored-dungeon-materials
  -> 04-icon-language-and-control-row
  -> Main integrated gates (format / analyze / full flutter test / scope audit)
  -> integrated acceptance review and corrections
  -> user-started Medium_Phone device gate (capsules A-E)
```

**Four tasks, strictly sequential, no concurrency.** Task 01 is the shared
prerequisite: it creates the LFS configuration, the derivation script, the
shipped assets, the `assets:` declaration, the typed catalogue and the decode
owner. Tasks 02, 03 and 04 each consume that catalogue and are file-disjoint
from one another, but they are **not** run concurrently, for two reasons that
both bind:

- every task's proof includes `flutter analyze` and the full `flutter test` for
  `packages/app`; concurrent writers in one checkout make those report each
  other's half-finished edits;
- 02, 03 and 04 all add entries to the same `pubspec.yaml` asset surface's
  consumers and all three are proved partly by suites that pump whole screens.

Each task is one Red -> Green proof cluster that reaches a valid handoff state
on its own:

- **01** ends with the pipeline provable in isolation (catalogue resolution,
  declaration coverage, LFS attribute split) and no consumer. That is not
  scaffold: criteria 1 and 2 are entirely about the pipeline, and they are
  provable without a single pixel on screen. Folding it into any consumer task
  would make the other two invent their own asset plumbing.
- **02** ends with three screens carrying an illustration and the three
  load-bearing layout suites still green.
- **03** ends with the authored material and overlay layer inside the existing
  `MaterialPlan` projection, with every existing pixel assertion green.
- **04** ends with the control row re-laid-out and both icon surfaces carrying
  icons.

**03 is not split into material-then-overlays.** Both halves live in the same
`_PreparedMaterialCell.from` factory and the same `MaterialComponent` render
order, both are gated off the same `MaterialMark`, and both are proved by one
render harness. Splitting them would mean two passes over one factory and two
constructions of the same synthetic-image proof, with an intermediate state
whose only distinguishing fact is a half-populated `DungeonArt`.

**04 is not split into shelf-then-controls.** Both surfaces are in
`game_screen.dart`, both take the same `ActionIcon` catalogue and the same
`Image.asset` recipe, and the shelf half is a three-callsite propagation of the
control half's mechanism — a neighbouring deliverable, not an independent
slice.

Only `packages/app`, the repository root `.gitattributes`, and a new root
`tool/` may change. **Nothing under `packages/core` or `packages/content` may
change.** Save code/data, `main.dart` beyond one added call, dependencies,
`pubspec.lock`, generated files, the world/roster/character/merchant/bank/inn/
alchemist screens, `LogDrawer`/`LogPeek`, `CrawlStatus`, `BattleDock`, the
death overlay, `.github/workflows/ci.yml` and LDD authority are out of scope.

## Revalidated source seams

All read at `4bf865c`. Line numbers in `CONTRACT.md` section E were taken from
the pre-Unit-9 file and have shifted; the current numbers are authoritative
here.

| Seam | Current fact | Planned consequence |
| --- | --- | --- |
| `packages/app/pubspec.yaml:59-68` | `flutter:` carries `uses-material-design: true` and a commented-out `assets:` example. | Gains three directory entries under `assets:`. Nothing else in the file changes; `pubspec.lock` is not touched. |
| repository root | No `.gitattributes`. `.gitignore` excludes `.flow/evidence/`, `.worktrees/`, `.dart_tool/`, `build/`, `.superpowers/`, `.omp/` — nothing that would hide an asset directory. No `tool/`. | New root `.gitattributes` with exactly one LFS pattern; new `tool/derive-visual-assets.sh`. |
| `.github/workflows/ci.yml:18` | `actions/checkout@v4` with no `lfs:` input, so CI checkouts contain LFS **pointer files**, not blobs. | This is the reason derived assets must not be LFS-tracked. It is also the standing proof of criterion 2's "a checkout without LFS still builds": CI is already exactly that checkout. |
| `art/visual-reboot/**` | 31 PNGs, all 1254x1254 8-bit sRGB, 48.1 MB, verified byte-identical to `SHA256SUMS.txt` by the architect. `MANIFEST.txt:54` states the material sources are **not guaranteed seamless**. | Read-only input to `tool/derive-visual-assets.sh`. Never shipped, never edited. |
| `lib/game/dungeon_scene_material.dart:278-287` | `render()` draws every cell's flat base, then `_drawVisibleLight()`, then every cell's decoration. | Gains one pass — `_drawAuthoredMaterial()` — between the light and the decoration. See "Where the authored fill actually goes". |
| `dungeon_scene_material.dart:268-274, 293-300` | `_visibleLight` is a `Paint` whose `RadialGradient` runs from `stoneLitColor(palette, 1)` to `stoneLitColor(palette, 0)`. **Both are fully opaque**, and `_drawVisibleLight` draws the mask bounds as a filled rect. | **Correction 1 — the recon's proposed seam is wrong.** A visible cell's `basePaint` fill is entirely overpainted by the opaque light pass; only remembered cells (outside the mask) ever show their base fill. An authored texture drawn in `_drawCellBase` would be invisible. The authored pass therefore goes **after** the light. |
| `dungeon_scene_material.dart:289-291` | `_drawCellBase` is one `drawRect` per cell with `cell.basePaint`. | **Unchanged.** It remains the remembered region's flat fill and the visible region's continuity floor. |
| `dungeon_scene_material.dart:97-111` | `visibleMaterialMask(plan)` adds a rect per visible cell; unknown cells are absent from `plan.cells` so they can never enter it. | **Unchanged**, still the light's clip. A second, kind-filtered mask builder is added beside it. |
| `dungeon_scene_material.dart:118-199` | `materialCellPaint` decides fill/edge/grit/speck/crack/pattern per cell; remembered returns `rememberedStone`, `pattern: none`, `crackStrength: 0`. | **Unchanged, entirely.** The authored layer reads `MaterialCellPaint` and `MaterialMark`; it never changes a decision. This is what keeps `dungeon_material_paint_test.dart`'s 30-odd decision assertions valid without edit. |
| `dungeon_scene_material.dart:302-323` | `_drawCellDecoration` returns early on `!cell.hasDecoration`, then `clipRect(cell.rect)` and draws grit, pattern, speck, crack, edge. | The authored overlay is drawn first inside that same clip; `hasDecoration` accounts for it. Clipping, order and every existing pass stay. |
| `dungeon_scene_material.dart:344-481` | `_PreparedMaterialCell.from` builds every Paint/Path/Rect once per plan adoption; nothing is allocated per frame. | Gains the authored overlay image/paint/rect in the same factory. The frame path stays allocation-free. |
| `dungeon_scene_material.dart:207-216, 234-275` | `MaterialComponent(MaterialPlan)` is the only constructor; `adopt()` rebuilds the render plan only on a non-identical plan. | Gains an **optional named** `art` parameter. Every one of the existing `MaterialComponent(plan)` call sites in `dungeon_material_paint_test.dart` and `dungeon_scene_test.dart` stays valid and keeps rendering the procedural output. |
| `lib/game/dungeon_material.dart:149-163` | `_hash(position, salt, extra)` is splitmix-style over position, salt and extra; `_unit01` normalizes. Both private. | One new public pure function, `materialPhase`, exposes the same grammar to the scene layer. No new hashing, no new randomness. |
| `dungeon_material.dart:234-277` | `_markFor` derives `grit`, `speck`, `crack`, `edge`, `pattern` from `themeSalt ^ 0x1111 .. ^ 0x5555`. `crack > 0` only on visible exposed walls; `speck` only on visible floors; both `0`/`false` when remembered. | **Unchanged.** Authored overlay selection and density are read straight off these marks, which is why remembered cells structurally cannot carry an overlay. The authored texture phase uses two fresh salts, `^ 0x6666` and `^ 0x7777`. |
| `lib/game/dungeon_palette.dart:5, 23-95` | `RegionMaterial` has four values; `themeSalt` is `0x0C7`/`0x5EA`/`0x10E`/`0x10A`; `visibleStone`/`rememberedStone`/`edgeInk`/`detailInk`/`lightInk` own every hue. | The authored layer supplies **value texture only**; hue stays the palette's. `lowlandRoad` has no authored surface, so criterion 9 is structural rather than tested-into-place. |
| `lib/game/grid_geometry.dart:16` | `cameraCellSize = 36`, fixed at every depth. | The authored material is a world-space field at 2 source pixels per world unit; a cell shows a 36-unit window of it, never a whole bitmap. |
| `lib/game/dungeon_scene.dart:202-216, 309-317` | `_DungeonScene.onLoad` awaits `super.onLoad()` then `_synchronizeComponents()`; `_synchronizeMaterial()` constructs `MaterialComponent(material)` once and `adopt`s thereafter. | `_synchronizeMaterial` passes `dungeonArt`. **`onLoad` stays synchronous in its art handling** — see "Decode ownership and lifetime" for why awaiting a load here would break two existing widget tests. |
| `lib/main.dart:24-27` | `main()` builds the `SaveStore` then `runApp(await guardedBoot(...))`. | Gains exactly one line: `await warmUpArt();` before `runApp`, **outside** `guardedBoot`, so boot's one-door failure semantics are untouched. |
| `lib/main.dart:166-170` | `ThemeData(brightness: dark, useMaterial3: true)` — no `colorScheme` override, so `FilledButton` is baseline M3 dark: light lavender container, dark label. | Icons sit on a **light** button in the crawl row and on the dark scaffold in the shelf. Both were checked against the real masters; see "Icon language". |
| `lib/town/town_screen.dart:83-84` | `Notice(state.notice)` then `const Spacer()` then seven `_Door`s, inside `SingleChildScrollView -> ConstrainedBox(minHeight) -> IntrinsicHeight -> Column`, under `Padding(EdgeInsets.all(20))`. | The Stonebridge illustration is inserted between those two lines. Content width is 371.4 dp at phone width. The column already scrolls, so an illustration cannot make a door unreachable — it can only make it scrolled-to, which the existing test already exercises. |
| `town_screen.dart:71, 152` | `_titleFor(state.town)` reads `residuumWorld.nodeAt(town).name`; `package:residuum_content/content.dart` is already imported. | `state.town == stonebridge` is available with no new import and no new bloc field. |
| `lib/town/town_bloc.dart:229, 424-425, 456-472` | `TownViewState.town` is a `NodeId`; `TownBloc({required profile, NodeId? town, ...})` defaults to `newWhereabouts().at`. | Tests can pump Northgate by passing `town: northgate`. No production gate exists today; this unit introduces exactly one. |
| `lib/town/forge_screen.dart:54-57` | `TownRoom.children` begins `Purse`, `Notice(state.notice)`, `Heading('Materials')`. | Illustration inserted between `Notice` and the first `Heading`, ungated (D3). |
| `lib/town/tavern_screen.dart:28-31` | `TownRoom.children` begins `Purse`, `Notice(...)`, `Heading('What they are saying')`. | Same seam, same rule. |
| `lib/town/town_style.dart:389-407` | `TownRoom` is `Scaffold + AppBar + ListView(padding: fromLTRB(20, 4, 20, 8))`. | Untouched. Content width 371.4 dp. The `ListView` scrolls natively, so a room illustration cannot displace anything. |
| `lib/world/world_route_diagram.dart:136-143, 162-167, 233-241` | Decorative content is `Semantics(container/button, label: ..., child: ExcludeSemantics(child: ...))`. | The precedent for both the illustration's `ExcludeSemantics` and `_Control`'s new `Semantics` wrapper. |
| `lib/game/game_screen.dart:265-353` | `_Controls`' button row is one `Row` of `Expanded` children: `Pick up`, `node.verb`, `Drink (n)`, `Pack (n)`, `Wait`, `Flee`, `Move on`, `Ascend <`, `Descend >`, `Leave`/`Finish`. Above it sit up to three conditional 20 dp sentence rows. | The `Row` becomes a `Wrap`; the `Expanded` wrappers are deleted. The control set, order, wording, gates and dispatches are frozen. |
| `game_screen.dart:498-520` | `_Control` is `Padding(horizontal: 3) -> FilledButton(padding: symmetric(horizontal: 4, vertical: 12)) -> Text(label, maxLines: 1, overflow: ellipsis, monospace 12)`. No `Semantics`. | Gains an optional icon and a `Semantics` wrapper; **loses `maxLines` and `overflow`**; loses its own horizontal `Padding` to the `Wrap`'s `spacing`. |
| `game_screen.dart:592-613, 654-688, 691-709` | `BattleShelf.build` is `Wrap(spacing: 6, runSpacing: 4)` holding `_ShelfButton('Drink (n)')`, `_shelfButton(spell)` per readied spell, `_ShelfButton('+N', key: overflowKey)`, `_ShelfButton('Wait', key: shelfWaitKey)`. `_shelfButton` writes `'<marking> <name> <cost>'` and appends `' — armed'`. | Three icon additions and one spell-icon lookup. No label, marking, count, cost, border or `— armed` word changes. The `Wrap` already reflows, so no geometry change. |
| `packages/content/lib/src/spells.dart:16, 34, 52, 69, 85, 100` | Spell ids are `firebolt`, `frost-lance`, `mend`, `ward`, `bind`, `banish`. | Exactly `firebolt` and `mend` have an asset. The other four stay text-only; no generic stand-in. |
| `packages/content/lib/src/gathering.dart:111-135` | Node candidate tiles are `Tile.floor` only — "plain floor rather than walkable floor is what keeps nodes off both flights of stairs". | **`canGather` and `canAscend`/`canDescend` are mutually exclusive.** This settles the worst-density enumeration below. |
| `lib/game/game_bloc.dart:339, 351-362, 373-374, 378-392, 445, 450-463, 475-484` | `wayOut`/`canFlee` are `isEncounter`-only; `Wait` needs `isEncounter && !isRoadClear && !isBattleOpen`; `Move on` needs `isRoadClear`; `canLeave == canDescend \|\| canAscend`. | See the density enumeration. All gates frozen. |
| `test/support/phone.dart:9-13` | `onAPhone` sets 1080x2424 at DPR 2.625 — **411.4 x 923.4 logical pixels** — and restores on teardown. | The control-row proof runs here and nowhere else. The default 800x600 surface is what hid the inherited `Drink (…)` defect. |
| `test/widget/town_shell_test.dart:27-29, 97-139` | Deliberately uses the default 800x600 surface; `seven doors, in order, and no eighth` pins door order by Y; `the last door is reachable on a 600-pixel-tall screen` scrolls to each of the seven and asserts `takeException()` is null. | **Stays untouched and must stay green.** It is criterion 4's town half. |
| `test/widget/craft_rooms_test.dart:483-517` | `lays out purse, notice, materials, smelting and the bench in that order` pins ten forge rows by ascending Y. | **Stays untouched and must stay green.** Inserting between `Notice` and `Heading('Materials')` preserves every pairwise order. |
| `test/widget/tavern_screen_test.dart:85-132, 142-187` | `the last six lines, newest first` and `the notice comes from either bloc, and sits above the offer` (notice Y < `WHAT THEY ARE SAYING` Y). | **Stay untouched and must stay green**, for the same structural reason. |
| `test/game/dungeon_material_paint_test.dart:56-122` | Renders `MaterialComponent(plan)` straight to a `PictureRecorder` at 12x36 by 5x36 and samples raw RGBA. Pixel assertions include `remembered == palette.rememberedStone`, `unknown == dungeonVoid`, per-palette byte inequality, and byte equality across two identical plans. | **No edit.** With the optional `art` parameter defaulted to absent these all keep asserting the procedural output, which is still exactly what they assert today. New authored behaviour goes in a new file. |
| `test/game/dungeon_scene_test.dart:421-464, 466-520` | Pump `DungeonSceneHost` and read `game.world.children` after a **single** `tester.pump()`. | **The reason art must not be awaited in `onLoad`.** An awaited asset load there would leave the world empty at the first pump and break both tests. |
| `test/widget/craft_surfaces_test.dart:81-163` | `find.widgetWithText(FilledButton, 'Mine' \| 'Gather' \| 'Pick up')`, one tap, and `expect(tester.takeException(), isNull)`. | Stays green unchanged: `Mine`/`Gather`/`Pick up` gain no icon, and a `FilledButton` inside a `Wrap` is still a `FilledButton` with a `Text` descendant. |
| `test/widget/log_drawer_test.dart:122-124` | Asserts `logPeekKey` top < `controlsKey` top. | Relative, unaffected by `Row -> Wrap`. |
| `test/battle_characterization_test.dart:119`, `test/battle_view_test.dart` | Pin `Pack (0)`, `Wait`, `✳ Firebolt 2`, `✳ Frost Lance 4`, `✚ Mend 3`. | Stay green unchanged under icon-**plus**-label. |

## Locked architecture and interfaces

### 1. Asset pipeline — what is tracked, what is derived, what is shipped

**Root `.gitattributes`, new file, one pattern:**

```gitattributes
art/visual-reboot/**/*.png filter=lfs diff=lfs merge=lfs -text
```

Deliberately excluded, each for a stated reason:

- **`packages/app/assets/**` is never matched.** Derived assets are ordinary git
  objects so a checkout without LFS still builds a correct app. CI is precisely
  such a checkout (`actions/checkout@v4`, no `lfs:` input), which is why this is
  a live requirement and not a hypothetical. The pattern is scoped to
  `art/visual-reboot/` so it cannot catch an app asset even if someone later
  adds a PNG there.
- **`art/visual-reboot/MANIFEST.txt`, `SHA256SUMS.txt`, `EXTRACT-NOTE.md` are
  never matched.** They are the bundle's provenance record and must stay
  diffable text.
- **`UI-P0-006_melee.png` and `UI-P0-010_back.png` are tracked as masters but
  never derived or shipped.** The masters are the approved bundle and stay
  whole; the contract's non-goals forbid a melee button and a custom back icon,
  and an asset existing is not scope.

LFS filters are machine-level configuration. The executor verifies
`git config --get filter.lfs.clean` is set and, if it is not, runs
`git lfs install --local` — repository-local only, never `--global`, never
`--system`. Staging and committing are Main's and the user's integration step,
not the executor's.

**`tool/derive-visual-assets.sh`, new file.** Bash, `set -euo pipefail`, requires
`magick` on `PATH`, run from the repository root, idempotent, prints every file
it writes. It reads only `art/visual-reboot/` and writes only
`packages/app/assets/visual/`. It is never run by CI — CI's checkout has
pointer files, not masters. The commands below were **run by the planner
against the real masters** with ImageMagick 7.1.2-27; the byte sizes and image
statistics are measured, not estimated.

Environments — crop a 2.5:1 band, then resize. The band offsets were chosen by
inspecting each master and verified by viewing the result:

```sh
magick art/visual-reboot/environments/ENV-001_stonebridge.png \
  -crop 1254x502+0+251 +repage -resize 1080x432! \
  -quality 82 -sampling-factor 4:2:0 -strip \
  packages/app/assets/visual/environments/stonebridge.jpg
```

`ENV-002_forge` and `ENV-003_tavern` use `+0+439` and are otherwise identical.
`+0+251` keeps Stonebridge's lit cathedral and the bridge arches while dropping
the empty sky; `+0+439` keeps the forge's fire and anvil, and the tavern's
fireplace, bar and archway, while dropping the rafters and the extreme
foreground. Measured output: 91 KB, 119 KB, 117 KB.

**JPEG, not PNG, and only here.** The same crops as PNG measure 757 KB, 816 KB
and 784 KB — 8.7x larger for three opaque photographic illustrations with no
alpha channel and no exact-value requirement. Material sheets, overlays and
icons stay PNG because they need exact grey values or an alpha channel.

Material sheets — greyscale, gradient-removed, mean-centred:

```sh
magick <master>.png -colorspace Gray -resize 576x576! \
  \( +clone -blur 0x24 \) \
  -compose Mathematics -define compose:args='0,-1,1,0.5' -composite \
  -function polynomial "1.6,-0.3" -depth 8 -strip \
  packages/app/assets/visual/dungeon/<region>_<surface>.png
```

The `Mathematics` composite computes `source - blurred + 0.5`, which removes
every low-frequency component — including any baked lighting — and re-centres
the result on mid-grey. The polynomial then scales the remaining deviation by
1.6 about 0.5. Measured on the crypt floor master: `mean = 0.5054`,
`std = 0.0872`; on the sea-cave floor master: `mean = 0.4991`, `std = 0.1182`.
Six sheets, 255-288 KB each, ~1.6 MB total. **Mid-grey is the identity element
of the blend this layer is drawn with**, so a mean of 0.5 is not a cosmetic
detail: it is what makes criterion 6's "no baked lighting double-exposure"
true by construction rather than by inspection.

Overlays — greyscale with alpha preserved:

```sh
magick <master>.png -colorspace Gray -resize 144x144 -strip \
  packages/app/assets/visual/dungeon/<region>_<kind>.png
```

Verified: `-colorspace Gray` keeps the alpha channel (crypt crack A retains
`alpha_mean = 0.0262`). 144 = 4 x `cameraCellSize`, which covers a 36 dp cell at
DPR 2.625 with headroom. Greyscale because the terrain layer's hue belongs to
`DungeonPalette`; an overlay carrying its own hue would be the single place in
the dungeon where regional colour came from an image.

Icons — the only class shipped in full colour:

```sh
magick <master>.png -background none -resize 72x72 -strip \
  packages/app/assets/visual/icons/<name>.png
```

72 = 4 x the 18 dp render size, covering DPR 3 with no upscale. **No resolution
variants** (`2.0x/`, `3.0x/`): a 72x72 RGBA image decodes to 20 KB, so variants
would triple the file count to save nothing. Eight icons, 1.9-8.2 KB each.

Shipped totals: **~2.3 MB on disk, ~14.7 MB decoded resident** (6 sheets at
1.33 MB, 12 overlays at 83 KB, 3 environments at 1.87 MB, 8 icons at 20 KB),
against 48.1 MB and ~186 MB for the masters.

### 2. Asset root, declaration shape, and the catalogue

Shipped root: **`packages/app/assets/visual/`**, in three flat directories —
`environments/`, `dungeon/`, `icons/`. Shipped names are derived and readable
(`stonebridge.jpg`, `crypt_floor.png`, `crypt_crack_a.png`, `potion.png`); the
`DNG-001_`/`UI-P0-001_` catalogue ids are bundle provenance and stay in
`MANIFEST.txt` and in `tool/derive-visual-assets.sh`, which is the master ->
derived mapping.

`pubspec.yaml` declares **directories, not files**:

```yaml
  assets:
    - assets/visual/environments/
    - assets/visual/dungeon/
    - assets/visual/icons/
```

Three lines that never drift, instead of 29 that do. The hole a directory
declaration opens — a stray file ships silently — is closed from the other side
by the catalogue test, which asserts the three directories contain **exactly**
the catalogue's files. Decision and proof are paired; neither stands alone.

**The catalogue: `packages/app/lib/art/art_assets.dart`.** The only file in the
repository that contains an asset path string.

```dart
enum EnvironmentArt {
  stonebridge('environments/stonebridge.jpg'),
  forge('environments/forge.jpg'),
  tavern('environments/tavern.jpg');

  const EnvironmentArt(this._file);
  final String _file;
  String get path => '$_visualRoot$_file';
}

enum ActionIcon {
  potion('icons/potion.png'),
  pack('icons/pack.png'),
  wait('icons/wait.png'),
  ascend('icons/ascend.png'),
  descend('icons/descend.png'),
  more('icons/more.png'),
  firebolt('icons/firebolt.png'),
  mend('icons/mend.png');
  // ... same shape

  /// The icon a readied spell carries, or null when no asset matches it
  /// exactly.
  static ActionIcon? forSpell(String spellId) => switch (spellId) {
    'firebolt' => ActionIcon.firebolt,
    'mend' => ActionIcon.mend,
    _ => null,
  };
}

enum MaterialSurface { floor, wall }

enum MaterialArt {
  cryptFloor(RegionMaterial.cryptStone, MaterialSurface.floor,
      'dungeon/crypt_floor.png'),
  cryptWall(RegionMaterial.cryptStone, MaterialSurface.wall,
      'dungeon/crypt_wall.png'),
  seaCaveFloor(...), seaCaveWall(...),
  ruinedKeepFloor(...), ruinedKeepWall(...);

  final RegionMaterial region;
  final MaterialSurface surface;

  static MaterialArt? of(RegionMaterial region, MaterialSurface surface) { ... }
}

enum OverlayKind { crackA, crackB, rubbleSmall, rubbleMedium }

enum TerrainOverlayArt {
  cryptCrackA(RegionMaterial.cryptStone, OverlayKind.crackA,
      'dungeon/crypt_crack_a.png'),
  // ... 12 entries, four kinds x three regions

  final RegionMaterial region;
  final OverlayKind kind;

  static TerrainOverlayArt? of(RegionMaterial region, OverlayKind kind) { ... }
}
```

Locked consequences:

- **`RegionMaterial.lowlandRoad` has no `MaterialArt` and no
  `TerrainOverlayArt`.** `MaterialArt.of` and `TerrainOverlayArt.of` return
  null for it. Criterion 9 — lowland roads visually unchanged — is therefore
  structural: there is no code path that could paint a road differently.
- **There is no `melee` and no `back` value.** An enum value would be the
  invitation the contract's non-goals forbid.
- **Ruined Keep's `fracture_overlay_a/b` masters map onto
  `OverlayKind.crackA/crackB`.** The recon recorded the same role under two
  naming generations; the ubiquitous word is `crack`, because
  `MaterialMark.crack` is the gate that selects them.
- Use sites take enum values. `Image.asset` needs a string, so exactly two
  widgets and one loader call `.path`, and no other file in `packages/app`
  contains an asset path literal. A repository-wide search for
  `assets/visual` must find only `art_assets.dart`, `pubspec.yaml` and
  `tool/derive-visual-assets.sh`.

### 3. Decode ownership and lifetime

**`packages/app/lib/art/dungeon_art.dart`** owns every `ui.Image` the renderer
uses.

```dart
class DungeonArt {
  const DungeonArt({required this.surfaces, required this.overlays});
  const DungeonArt.none() : surfaces = const {}, overlays = const {};

  final Map<MaterialArt, ui.Image> surfaces;
  final Map<TerrainOverlayArt, ui.Image> overlays;

  ui.Image? surfaceFor(RegionMaterial region, MaterialSurface surface);
  ui.Image? overlayFor(RegionMaterial region, OverlayKind kind);
}

/// The decoded dungeon art this process loaded at launch, or none.
DungeonArt get dungeonArt => _loaded;

/// Decodes every shipped dungeon image and both precaches the three
/// illustrations, once per process.
Future<void> warmUpArt() async { ... }
```

Locked consequences:

- **`DungeonArt.none()` is a const value, not a null.** `MaterialComponent`'s
  new parameter defaults to it, so every existing `MaterialComponent(plan)` call
  site keeps compiling and keeps rendering the procedural output, and the
  renderer has no nullable art field to guard.
- **`warmUpArt()` never throws.** Each asset is loaded inside its own
  try/catch; a failure leaves that entry absent and the renderer degrades to
  the procedural layer. It is called from `main()` **before** `runApp` and
  **outside** `guardedBoot`, so a missing asset can neither open the boot
  failure screen nor show a black frame. Decoding before the first frame is the
  point: criterion 17 forbids a scene-entry or crawl-render hitch, and the only
  way to guarantee that is to have paid for the decode before any scene exists.
  Measured cost is a device-gate observation, not a guess.
- **Images are never disposed.** They live for the process, exactly as
  Flutter's own `ImageCache` entries do. Refcounting them across scene
  lifetimes would buy back 8 MB at the cost of a decode on every delve, which
  is the hitch this design exists to avoid.
- **`dungeonArt` is a library-level getter over a process-wide value.** That is
  deliberate and narrow: it is a decoded-image cache with no gameplay meaning,
  no mutation after warm-up, and no bloc involvement — the same category as
  `ImageCache` or `residuumWorld`. Threading it from `main()` through
  `_Session`, `GameScreen` and `DungeonSceneHost` would add a constructor
  parameter to four widgets to express "the process decoded its images".
  `AGENTS.md`'s no-global-randomness rule is about `Rng`, not caches.
- **Tests never touch the global.** `main()` is not run by the suite, so
  `dungeonArt` is `DungeonArt.none()` in every existing test — which is what
  keeps `dungeon_material_paint_test.dart` and `dungeon_scene_test.dart`
  deterministic and unedited. New authored tests build a `DungeonArt` with the
  public constructor from images they decode themselves. There is no test-only
  constructor and no injection seam.
- **The environments are precached, the icons are not.** Three 1080x432 JPEGs
  are ~1.87 MB decoded each and would pop in visibly on first paint;
  `const AssetImage(path).resolve(ImageConfiguration.empty)` awaited to its
  first frame puts them in `ImageCache` before the town is built, with no
  `BuildContext` needed. A 72x72 icon decodes in well under a millisecond, so
  precaching eight of them would add launch work for no observable gain.
- `Image.asset` at the two widget use sites resolves through `ImageCache`, so
  each image decodes once per process however many widgets show it.

### 4. Environment illustrations

**`packages/app/lib/town/illustration.dart`**, new file:

```dart
const townIllustrationKey = Key('town-illustration');
const forgeIllustrationKey = Key('forge-illustration');
const tavernIllustrationKey = Key('tavern-illustration');

const double townIllustrationHeight = 140;
const double roomIllustrationHeight = 120;

class Illustration extends StatelessWidget {
  const Illustration(this.art, {required this.height, super.key});

  final EnvironmentArt art;
  final double height;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Image.asset(
            art.path,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, _, _) => const SizedBox.expand(),
          ),
        ),
      ),
    ),
  );
}
```

Insertion points, exactly three:

| Screen | Seam | Gate |
| --- | --- | --- |
| `town_screen.dart`, between `:83` `Notice(state.notice)` and `:84` `const Spacer()` | `if (state.town == stonebridge) const Illustration(EnvironmentArt.stonebridge, height: townIllustrationHeight, key: townIllustrationKey)` | Stonebridge only. Northgate gets nothing and no substitute. |
| `forge_screen.dart`, between `:56` `Notice(state.notice)` and `:57` `const Heading('Materials')` | `const Illustration(EnvironmentArt.forge, height: roomIllustrationHeight, key: forgeIllustrationKey)` | Ungated (D3). |
| `tavern_screen.dart`, between `:30` `Notice(...)` and `:31` `const Heading('What they are saying')` | `const Illustration(EnvironmentArt.tavern, height: roomIllustrationHeight, key: tavernIllustrationKey)` | Ungated (D3). |

Locked consequences:

- **The box is the authority and `BoxFit.cover` absorbs the mismatch.** The
  shipped asset is one shape for all three (2.5:1), so the 140 dp town box
  crops ~6% vertically and the 120 dp room box ~19%, both from an already
  deliberately cropped band. Coupling the shipped aspect ratio exactly to each
  box height would make a later 10 dp adjustment a re-derivation.
- **No `AspectRatio`.** A square source under `AspectRatio` at 371.4 dp is
  411 dp tall — 45% of the phone. The height is the budget, so the height is
  what the widget states.
- **140 dp in the town, 120 dp in a room.** The town illustration goes into
  slack that already exists: the `Spacer` at `:84` gravitates the doors to the
  bottom, so on a 923.4 dp phone the illustration consumes space nothing else
  was using. On a 600 dp surface the column scrolls, exactly as it already does
  for seven doors, which is why `town_shell_test.dart`'s 600 dp test is
  **unchanged and must stay green**: it scrolls to each door and asserts no
  exception, and that is criterion 4's town half in full. Rooms are `ListView`s
  and scroll natively, so the 120 dp is a taste choice inside a surface that
  cannot overflow.
- **Section order is preserved by position, not by height.** Inserting a child
  between `Notice` and the first `Heading` keeps every pairwise Y relation that
  `craft_rooms_test.dart:483-517` and `tavern_screen_test.dart:142-187` assert.
  Neither test is touched, and **neither may be weakened**: if an illustration
  ever fails one of them, the illustration is wrong.
- **`ExcludeSemantics` is the outermost widget**, following
  `world_route_diagram.dart:143`. No `semanticLabel`, no `Semantics` wrapper,
  no tooltip, no `alt` text anywhere in the subtree. An illustration that
  announced itself would be an image with a voice, which is exactly what
  criterion 5 forbids.
- **`errorBuilder` returns an empty expanded box.** A missing or corrupt asset
  must leave a hole, never a Flutter error widget in the middle of a town. This
  is production error semantics, decided here, and it also removes the one
  harness risk in this task: whatever the test bundle does with a JPEG, the
  screen never throws into `tester.takeException()`.
- **`ClipRRect` radius 2** is the house value (`_Meter`, `_SkillRow`); the 8 dp
  vertical padding keeps the town's existing rhythm.

### 5. Authored dungeon materials

#### Where the authored fill actually goes

The recon proposed `_drawCellBase`. That is wrong at source, and the correction
is load-bearing: `_visibleLight` runs between two **fully opaque** colours
(`stoneLitColor` lerps opaque palette colours and `HSLColor.withLightness`
preserves alpha), and `_drawVisibleLight` fills the whole mask bounds with it.
Every visible cell's base fill is therefore already overpainted; only
remembered cells, which lie outside the mask, ever show `basePaint`. An
authored texture in `_drawCellBase` would be invisible on exactly the cells it
is meant to decorate.

The render order becomes:

```dart
@override
void render(Canvas canvas) {
  super.render(canvas);
  for (final cell in _cells) {
    _drawCellBase(canvas, cell);      // unchanged
  }
  _drawVisibleLight(canvas);          // unchanged
  _drawAuthoredMaterial(canvas);      // new
  for (final cell in _cells) {
    _drawCellDecoration(canvas, cell); // unchanged pass order, overlay added at its head
  }
}
```

#### The authored pass

Two draws for the entire layer, not one per cell:

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

`_AuthoredSurfacePass` is a private holder of `Path mask`, `Rect bounds` and
`Paint paint`, built once per plan adoption in `_rebuildRenderPlan` and null
when the palette has no authored surface or the masked set is empty. Nothing is
allocated per frame; two clip-and-fill operations replace what a per-cell loop
would have cost.

The mask comes from a new pure function beside the existing one:

```dart
/// The visible-only clip for one authored material surface.
///
/// Floors, both flights of stairs and unknown space are decided exactly as
/// [visibleMaterialMask] decides them: unknown cells are absent from the plan,
/// and remembered cells are absent from this mask.
Path visibleSurfaceMask(MaterialPlan plan, MaterialSurface surface)
```

`MaterialSurface.floor` accepts `floor`, `stairsDown` and `stairsUp`;
`MaterialSurface.wall` accepts `wall`. Stairs take the floor field because
`materialCellPaint` already puts them in the continuous stone field with
`pattern: none`, and the stair identity is a glyph component drawn above the
terrain layer (`dungeon_scene.dart:25-41`, `glyphCellsAboveMaterial`) — so
criterion 8's "no stairs presentation change" holds: the marking above the
stone is untouched.

Three invariants fall out of the mask rather than being tested into place:

- **unknown stays unpainted** — unknown positions have no `MaterialCell`, so
  they cannot enter any mask;
- **remembered stays flat and unlit** — the mask is visible-only, so the
  authored field never reaches a remembered cell, which keeps its flat
  `rememberedStone` fill exactly as today;
- **the authored layer cannot leak geometry** — it is clipped to the same
  authoritative visible set the light already is.

#### The texture: one continuous mirror-tiled field

```dart
ui.ImageShader(
  image,
  TileMode.mirror,
  TileMode.mirror,
  (Matrix4.identity()
        ..translate(phase.dx, phase.dy)
        ..scale(0.5))
      .storage,
)
```

with `Paint()..shader = shader..blendMode = BlendMode.softLight
..filterQuality = FilterQuality.medium`.

Locked consequences, each answering a contract requirement:

- **"One bitmap per cell repeated wholesale is prohibited."** This is one
  world-space field. At `scale(0.5)` a 576 px sheet covers 288 world units —
  eight cells — so each cell shows a distinct 36-unit window and adjacent cells
  show adjacent windows. The stone is continuous across cell boundaries, which
  is also what keeps a 36 dp grid from appearing: per-cell crops would have
  turned Unit 2's continuous material into a checkerboard.
- **"The masters are not guaranteed seamless."** `TileMode.mirror` on both axes
  makes any image tile without a seam: the field is value-continuous at every
  repeat boundary by construction. Mirroring a high-passed, mean-centred noise
  field is invisible; no seamlessness guarantee is needed from the source.
- **"Sampling is keyed only by presentation-stable inputs, reusing the existing
  `_hash`/`themeSalt` grammar."** The per-surface phase is

  ```dart
  Offset _texturePhase(DungeonPalette palette, MaterialSurface surface) => Offset(
    materialPhase(const Position(0, 0), palette.themeSalt ^ 0x6666, surface.index) * 288,
    materialPhase(const Position(0, 0), palette.themeSalt ^ 0x7777, surface.index) * 288,
  );
  ```

  where `materialPhase` is one new public function in `dungeon_material.dart`
  wrapping the existing private `_unit01(_hash(...))`. The salts `0x6666` and
  `0x7777` extend the `0x1111..0x5555` series without colliding. Per-cell
  determinism needs no hashing at all: a world-space field is a pure function of
  position, which is strictly stronger than per-cell sampling across rebuilds,
  revisits and pans.
- **There is deliberately no per-floor variation.** `MaterialPlan` carries
  `cells`, `marks`, `masonry`, `heroPosition` and `palette` — and
  `heroPosition` changes with every step, so the only floor-stable input
  available is the palette. Adding a floor identity to the plan would change a
  projection this unit is forbidden to touch. Every floor of a region therefore
  shares one phase, which no player can observe and which keeps the plan's
  shape untouched. **A request for per-floor variety is an escalation, not an
  implementation choice.**
- **`BlendMode.softLight`, and mid-grey is why.** softLight leaves the
  destination unchanged where the source is exactly 0.5, darkens below and
  lightens above. The derived sheets measure `mean ≈ 0.50`, so the authored
  layer contributes **texture with no net luminance shift**: the mask-clipped
  radial gradient underneath keeps owning brightness, the palette keeps owning
  hue, and there is no baked-lighting double-exposure to argue about. A
  multiply or alpha blend would have darkened the whole dungeon by the sheet's
  mean and put the authored art in competition with the light.
- **Greyscale safety is structural.** The sheets carry no hue at all, so the
  authored material cannot become a place where regional identity is read by
  colour.
- **Every accepted regional cue survives untouched.** `tideStrata`,
  `ashlarFracture`, `roadWear`, wall edge strokes, grit and the light pass are
  all drawn by unchanged code, and decoration draws *after* the authored pass.
  Criterion 13 is preserved by not touching the code that satisfies it.

#### Authored overlays

The overlay is drawn at the head of `_drawCellDecoration`, inside the existing
`clipRect(cell.rect)`, from fields the existing `_PreparedMaterialCell.from`
factory computes once per adoption:

| Gate (unchanged from today) | Authored overlay | Variant |
| --- | --- | --- |
| `paint.crackStrength > 0 && mark.crack > 0` — visible exposed wall, ~18% of them | `OverlayKind.crackA` / `crackB` | `crackB` iff `mark.crack >= 0.3` (crack is `(0, 0.6]`, so a near-even split) |
| `paint.speck && mark.speck` — visible non-stairs floor, ~14% of them | `OverlayKind.rubbleSmall` / `rubbleMedium` | `rubbleMedium` iff `mark.grit >= 0.2` (floor grit is `(0, 0.4]`) |

Locked consequences:

- **At most one authored overlay per cell**, because the crack gate requires a
  wall and the speck gate requires a floor. One nullable image field, not two.
- **When an authored overlay draws, the procedural mark it replaces does not.**
  The authored crack replaces `_crackPath`'s stroke; the authored rubble
  replaces the 1.6 px `speck` circle. Drawing both would double one decorative
  fact and make the cell noisy. Density, sparsity and determinism are inherited
  exactly, because the gates are the ones already tuned and already tested.
- **Remembered cells can never carry an overlay**, because `_markFor` sets
  `crack: 0` and `speck: false` for remembered geometry. No extra condition is
  needed and none is added.
- **Drawn into `cell.rect` at `overlayOpacity = 0.55`**, via
  `Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: overlayOpacity)
  ..filterQuality = FilterQuality.medium`. The measured alpha coverage of the
  rubble masters is 0.23 (small) and 0.41 (medium), which at full opacity would
  read as an object rather than as surface debris. Bounded device correction is
  allowed in 0.35-0.75; the gates, the variants and the clip are not correction
  surface.
- **Unconfusable, structurally.** Overlays are greyscale debris and hairline
  cracks drawn in the terrain layer, beneath every glyph component — resource
  nodes (`◆`, `❀`), items, stair markings, actors and the target mark are all
  bright glyph characters drawn above, by untouched code. Overlays are
  non-interactive: hit testing reads `GridGeometry.positionAt`, which never
  consults them. They replace marks that already existed and have never been
  confusable with anything.

#### Signature changes, in full

```dart
// dungeon_material.dart — one new public function, nothing else
double materialPhase(Position position, int salt, int extra);

// dungeon_scene_material.dart
Path visibleSurfaceMask(MaterialPlan plan, MaterialSurface surface);

class MaterialComponent extends PositionComponent {
  MaterialComponent(MaterialPlan initialPlan, {this.art = const DungeonArt.none()});
  final DungeonArt art;
  // every existing member unchanged
}

// dungeon_scene.dart — one call site
_material = MaterialComponent(material, art: dungeonArt);
```

`MaterialCell`, `MaterialMark`, `MaterialPlan`, `materialPlan`,
`MaterialCellPaint`, `materialCellPaint`, `visibleMaterialMask`,
`stoneLitColor`, `DungeonPalette` and `RegionMaterial` are **not changed** — not
a field, not a parameter, not a default.

### 6. Icon language and the crawl control row

#### Worst real density, enumerated from the gates

| Scene | Controls that can co-occur | Count |
| --- | --- | --- |
| Dungeon, on stairs, loot underfoot, potion carried | `Pick up`, `Drink (n)`, `Pack (n)`, `Ascend <` or `Descend >`, `Finish`/`Leave` | **5** |
| Dungeon, on a node, loot underfoot, potion carried | `Pick up`, `Mine`/`Gather`, `Drink (n)`, `Pack (n)` | 4 |
| Road fight, loot underfoot, potion carried, at the edge | `Pick up`, `Drink (n)`, `Pack (n)`, `Wait` or `Move on`, `Flee` | **5** |

The enumeration is closed by three source facts: `gatherNodesOn`
(`packages/content/lib/src/gathering.dart:111-135`) draws candidates from
`Tile.floor` only, so **a node and a flight of stairs can never share a tile**
and gather never co-occurs with ascend/descend/leave; `wayOut`
(`game_bloc.dart:351-359`) is `isEncounter`-only, so `Flee` never appears in a
crawl; `Wait` requires `!isRoadClear` and `Move on` requires `isRoadClear`, so
those two are exclusive. `canLeave == canDescend || canAscend` contributes one
control, not two.

**The chosen geometry is density-agnostic, so the answer does not depend on the
enumeration being exactly five.** The enumeration is what makes the height
argument below concrete; the layout would be correct at seven.

#### The replacement geometry

`_Controls`' `Row` of `Expanded` children becomes a `Wrap`, and each control
loses its `Expanded` wrapper and its own horizontal `Padding`:

```dart
Wrap(
  spacing: 6,
  runSpacing: 4,
  alignment: WrapAlignment.center,
  children: [
    if (state.canPickUp)
      _Control(label: 'Pick up', onPressed: () => bloc.add(const PickUpPressed())),
    // ... every existing control, in its existing order, with its existing
    // gate, label and dispatch, plus `icon:` where an asset matches
  ],
)
```

```dart
class _Control extends StatelessWidget {
  const _Control({required this.label, required this.onPressed, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final ActionIcon? icon;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onPressed != null,
    label: label,
    onTap: onPressed,
    child: ExcludeSemantics(
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          minimumSize: const Size(0, 40),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Image.asset(
                icon!.path,
                width: 18,
                height: 18,
                filterQuality: FilterQuality.medium,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
}
```

Icon-to-control mapping, exactly five:

| Control | Icon |
| --- | --- |
| `Drink (n)` | `ActionIcon.potion` |
| `Pack (n)` | `ActionIcon.pack` |
| `Wait` | `ActionIcon.wait` |
| `Ascend <` | `ActionIcon.ascend` |
| `Descend >` | `ActionIcon.descend` |

`Pick up`, `Mine`/`Gather`, `Flee`, `Move on` and `Leave`/`Finish` stay
text-only. No control is added, removed, renamed, reordered or rewired, and no
gate changes.

Locked consequences:

- **`maxLines: 1` and `overflow: TextOverflow.ellipsis` are deleted.** They are
  the inherited defect, proved on device at `2b0e0a4` and again at `4bf865c`.
  No `Text` in `_Controls` may set `overflow`, `maxLines` or `softWrap` after
  this unit.
- **`minimumSize: Size(0, 40)`.** The default `FilledButton` minimum is
  `Size(64, 40)`; removing the 64 dp width floor is what lets `Mine` and
  `Finish` take their natural width. The height floor stays 40 — the same
  height the row has today — so this change costs no map height at one run.
- **`padding: horizontal 4, vertical 12` is unchanged from today**, deliberately:
  every dp of horizontal padding is width the labels need.
- **`Wrap`, and it will reach two runs at five controls.** At 411.4 dp the
  content width is 387.4 dp. At the device monospace advance (~7.2 dp per
  character at 12 px), the five-control stairs scene needs
  `58.4 + 96.8 + 89.6 + 89.6 + 51.2 = 385.6` dp of buttons plus 24 dp of
  spacing — 409.6 dp, about 22 dp over. Shrinking the icon to 16 dp and the gap
  to 4 dp saves 12 dp and still does not fit. **One run is arithmetically
  impossible at five controls with icons**, which is precisely why the contract
  permits reflow and why equal-width `Expanded` cells with silent ellipsis is
  not acceptable.
- **The height cost, argued against inherited lock 3.** A second run costs 44 dp
  (40 dp button + 4 dp `runSpacing`) out of the `Expanded` map, and only in the
  scenes that already grow: `_Controls` today adds a 20 dp sentence row for
  `doneAtTheBottom`, another for `Underfoot:` and another for `Here:`
  (`game_screen.dart:226-264`), so the bottom-floor-with-loot scene already
  spends 40-60 dp of map on chrome. The five-control case is a standing-still
  decision moment — on a stairs landing, or on the road with a way out — not a
  combat frame; `Wait` is hidden while `isBattleOpen`. The device gate measures
  the delta and the bounded correction is `spacing`/`runSpacing`, never the
  structure and never a restored ellipsis.
- **`WrapAlignment.center`** matches the centred sentence rows already in the
  same `Column`, so a partially filled second run sits under the first rather
  than hanging off one edge. The `Wrap` still breaks runs at the full incoming
  387.4 dp.
- **`Semantics(button:, enabled:, label:, onTap:) -> ExcludeSemantics`** follows
  `world_route_diagram.dart:233-241` exactly. `_Control` has no semantics label
  today; with an icon inside the button it needs one, and `onTap` is what keeps
  the node activatable rather than merely described. Widget finders are
  unaffected — `find.widgetWithText(FilledButton, 'Mine')` and `tester.tap`
  both work on the widget tree, not the semantics tree.
- **Disabled reads exactly as it does today**: `onPressed: null`, no word
  change, no icon change, no added sentence. `Semantics.enabled` follows it so
  the reading matches the behaviour.
- **The icons are shipped multitone, untinted.** `ImageIcon` would replace every
  pixel with the `IconTheme` colour and reduce authored art to a silhouette; the
  contract's own words presume multitone masters and make legibility the
  acceptance question. The planner checked all eight derived icons at 48 px over
  the M3 dark `FilledButton` container (`#D0BCFF`) and over the shelf's dark
  scaffold, in colour and in greyscale: every one reads by shape alone — bottle,
  backpack, hourglass, stairs-with-up-arrow, stairs-with-down-arrow, flame,
  cross, three dots. Ascend and descend differ by both arrow direction and stair
  direction, never by hue. If the device gate finds an icon that does not read
  on its button background, the **named bounded correction** is a per-icon
  derivation change (contrast, or an alpha-only silhouette rendered through
  `ImageIcon`); silently tinting the set is not a correction, it is a design
  change and an escalation.

#### The battle shelf

Three additions, no geometry change — the `Wrap` at `:662-685` already reflows:

- `_ShelfButton` gains `ActionIcon? icon`, rendered with the same 18 dp
  `Image.asset` + 6 dp gap recipe inside its existing `TextButton`.
- `Drink (n)` -> `ActionIcon.potion`; `Wait` -> `ActionIcon.wait`;
  `+N` (`overflowKey`) -> `ActionIcon.more`.
- `_shelfButton(spell)` takes `ActionIcon.forSpell(spell.id)` — `firebolt` and
  `mend` only. `frost-lance`, `ward`, `bind` and `banish` stay text-alone; no
  generic stand-in.
- Every label, count, mana cost, school marking, the armed border
  (`side: BorderSide(color: ink)`) and the word `— armed` are untouched. The
  overflow sheet and `_OverflowRow` are untouched.

**`packages/app/lib/game/action_icon.dart`** holds the one shared widget both
surfaces use, so the 18 dp / 6 dp recipe exists once:

```dart
const double actionIconSize = 18;

class ActionIconImage extends StatelessWidget {
  const ActionIconImage(this.icon, {super.key});
  final ActionIcon icon;
  // Image.asset(icon.path, width/height: actionIconSize,
  //             filterQuality: FilterQuality.medium)
}
```

### 7. Edge semantics, decided

| Edge | Rule |
| --- | --- |
| An asset fails to load at warm-up | That entry stays absent. The dungeon renders procedurally, an illustration renders as an empty box, an icon renders as Flutter's broken-image box inside a button whose label is still correct. Nothing throws, boot is unaffected, no sentence changes. |
| `dungeonArt` is empty (every test, and any warm-up failure) | `MaterialComponent` builds no authored pass and no overlay fields; output is byte-identical to `4bf865c`. This is the procedural fallback, and it is the reason no existing pixel test changes. |
| `RegionMaterial.lowlandRoad` | `MaterialArt.of` and `TerrainOverlayArt.of` return null, so a road fight renders byte-identically to `4bf865c` even with art fully loaded. Criterion 9 is structural. |
| Remembered cell with art loaded | Absent from both surface masks; keeps its flat `rememberedStone` fill and its `crack: 0` / `speck: false` marks. Flat and unlit, unchanged. |
| Unknown cell | Absent from `MaterialPlan.cells`, therefore from every mask and every prepared cell. Unpaintable. |
| Stairs cell | Takes the floor field, keeps `pattern: none`, `speck: false`, `crackStrength: 0`, `edge: 0`; the stair glyph is a separate component above the terrain layer and is untouched. |
| Northgate town | No illustration and no substitute — the `if` is absent, not an empty box. |
| Forge or Tavern in Northgate | Illustration present, ungated (D3). |
| A control with no matching asset | `icon: null`, text-only, no placeholder and no reserved icon gap. |
| A readied spell with no exact asset | Text-only. `ActionIcon.forSpell` returns null for `frost-lance`, `ward`, `bind`, `banish`. |
| Disabled control (`onPressed: null`) | Icon and label unchanged; `Semantics.enabled` false. Exactly today's reading. |
| One control on the row | The `Wrap` is one centred run; nothing stretches to fill the width, which is a visible change from today's single `Expanded` cell and is the price of intrinsic sizing. |

## Test plan

`AGENTS.md` makes bloc-level tests the app default and permits widget tests
where a bloc cannot observe the behaviour. Every behaviour in this unit is
presentation: no event, no state, no bloc field changes anywhere. So the proof
is **pure unit tests** for the catalogue, the masks and the hashing, and
**widget/render tests** for everything a canvas or a screen decides. **No
golden images** (`AGENTS.md`).

### New focused tests

Thirty-five tests across five new files, owned per task: **8** by task 01
(`art_catalogue_test.dart`), **6** by task 02 (`town_illustration_test.dart`),
**12** by task 03 (`material_sampling_test.dart` plus
`dungeon_authored_material_test.dart`), and **9** by task 04
(`crawl_controls_test.dart` plus `battle_shelf_icons_test.dart`). Each task
brief carries its own subset with its expected Red.

| # | File | Test | Asserts | Criterion |
| --- | --- | --- | --- | --- |
| 1 | `test/art/art_catalogue_test.dart` | every catalogue entry names a file that exists | for all four enums: `File(path)` under `packages/app` exists | 1, 2 |
| 2 | ” | every catalogue path is declared once | each `path` sits under one of the three declared directories parsed out of `pubspec.yaml`; paths are unique | 1, 2 |
| 3 | ” | the shipped directories carry exactly the catalogue | the set of files in `assets/visual/{environments,dungeon,icons}` equals the set of catalogue paths — no stray, no missing | 1, 2 |
| 4 | ” | masters are not shipped | no shipped file is 1254x1254; the total shipped byte count is under 8 MB; no path contains `DNG-` or `UI-P0-` | 2 |
| 5 | ” | no icon exists for melee or back | `ActionIcon.values` has exactly eight names, none of them `melee` or `back` | 12 |
| 6 | ” | `forSpell` matches exactly and only firebolt and mend | `firebolt`/`mend` map; `frost-lance`, `ward`, `bind`, `banish` and an unknown id return null | 10 |
| 7 | ” | the road has no authored material | `MaterialArt.of(lowlandRoad, *)` and `TerrainOverlayArt.of(lowlandRoad, *)` are null; all three other regions resolve all six lookups | 9 |
| 8 | `test/art/material_sampling_test.dart` | the surface mask follows visibility and kind | `visibleSurfaceMask(plan, floor)` contains a visible floor centre and both stair centres, not a visible wall, not a remembered floor, not an unknown position; `wall` is the complement | 6 |
| 9 | ” | the same inputs give the same phase | `materialPhase` twice over equal inputs is equal; different salts and different `extra` differ; the value is in `[0, 1]` | 7 |
| 10 | ” | each region draws its own phase | the six `(palette, surface)` phases are pairwise distinct and stable across calls | 7 |
| 11 | `test/game/dungeon_authored_material_test.dart` | authored material changes visible stone | a two-tone synthetic sheet makes at least one visible-floor pixel differ from the same plan rendered with `DungeonArt.none()` | 6 |
| 12 | ” | remembered stays exactly flat under authored art | with art loaded, the remembered cell's centre pixel is exactly `palette.rememberedStone` — the same assertion `dungeon_material_paint_test.dart:1018` makes without art | 6 |
| 13 | ” | unknown stays void under authored art | with art loaded, an unexplored cell's pixel is exactly `dungeonVoid` | 6 |
| 14 | ” | the light still owns brightness | with a mean-0.5 synthetic sheet, a visible cell near the hero is more luminous than a visible cell far from it | 6, 13 |
| 15 | ” | identical state renders identically | two renders of one plan+art are byte-equal; a second `materialPlan` built from the same `GameState` renders byte-equal to the first | 7 |
| 16 | ” | the road is untouched by authored art | a `lowlandRoad` plan renders byte-equal with art loaded and with `DungeonArt.none()` | 9 |
| 17 | ” | an authored overlay replaces its procedural mark | a crack-gated wall cell with overlay art draws pixels differing from the no-art render inside the cell, and the procedural crack stroke is gone (`crackPaint` path pixels no longer match the no-art render at the stroke sample) | C, D |
| 18 | ” | an ungated cell draws no overlay | a visible wall whose `mark.crack` is 0 renders byte-equal with and without overlay art | D, 7 |
| 19 | ” | an overlay never leaves its cell | a one-overlay-cell plan leaves every pixel outside that cell's rect equal to the no-art render | D, 8 |
| 20 | `test/widget/town_illustration_test.dart` | Stonebridge carries its illustration | `find.byKey(townIllustrationKey)` findsOneWidget; height is `townIllustrationHeight` | 3 |
| 21 | ” | Northgate carries none, and nothing stands in for it | `TownBloc(town: northgate)`: `townIllustrationKey` findsNothing, `find.byType(Illustration)` findsNothing, `find.byType(Image)` findsNothing | 3 |
| 22 | ” | the forge and the tavern are illustrated in both towns | for `town: stonebridge` and `town: northgate`: `forgeIllustrationKey` and `tavernIllustrationKey` each findsOneWidget | 3 |
| 23 | ” | an illustration displaces nothing in the town | Stonebridge at `onAPhone`: every one of the seven door labels, `Stonebridge`, the health/carried/banked lines and the notice are present; `takeException()` is null | 4 |
| 24 | ” | an illustration sits between the notice and the first heading | forge and tavern: illustration Y is greater than `Notice` Y and less than the first `Heading` Y | 4 |
| 25 | ” | an illustration says nothing | with `ensureSemantics()`: `find.descendant(of: illustration, matching: find.byType(Semantics))` findsNothing on all three screens | 5 |
| 26 | `test/widget/crawl_controls_test.dart` | the worst dungeon density fits a phone un-ellipsised | `onAPhone`, bottom floor on stairs, loot underfoot, two potions carried: `Pick up`, `Drink (2)`, `Pack (n)`, `Ascend <`, `Finish` all found by exact text; `takeException()` null; the no-squeeze loop below over every `Text` inside `controlsKey` | 11 |
| 27 | ” | the worst road density fits a phone un-ellipsised | `onAPhone`, road fight at the map edge with loot and a potion: `Pick up`, `Drink (2)`, `Pack (n)`, `Wait`, `Flee`; same three assertions | 11 |
| 28 | ” | every icon-bearing control carries its icon and its word | the five mapped controls each have exactly one `Image` descendant and their exact label text; `Pick up`, `Mine`, `Flee`, `Move on`, `Finish` have none | 10, 11 |
| 29 | ” | an icon-bearing control announces itself | with `ensureSemantics()`: `find.bySemanticsLabel('Drink (2)')`, `'Pack (n)'`, `'Ascend <'` each findsOneWidget | 11 |
| 30 | ” | a disabled control reads as it does today | game-over state: the `Drink` button's `onPressed` is null, its label and icon are unchanged, and no extra sentence appears | 11 |
| 31 | ” | the control set is frozen | across the two worst-density scenes, the set of `FilledButton` labels inside `controlsKey` is exactly the expected set — no eleventh control, no renaming | 12 |
| 32 | `test/widget/battle_shelf_icons_test.dart` | every icon-bearing shelf action keeps its word | a hero with firebolt, frost lance, mend and banish readied plus a potion: `Drink (n)`, `Wait`, `+1`, `✳ Firebolt 2`, `✚ Mend 3` present; `Drink`, `Wait`, `+1`, Firebolt and Mend buttons each have one `Image`; Frost Lance and the overflow rows have none | 10 |
| 33 | ” | arming still reads by border and word | the armed spell's button keeps `— armed` and a non-null `side`, and still carries its icon | 10 |
| 34 | `test/art/art_catalogue_test.dart` | an unloaded process has no art | `dungeonArt.surfaceFor`/`overlayFor` return null for every region and kind, and `const DungeonArt.none().surfaces` is empty — the procedural-fallback guarantee every other suite depends on | 2, 6 |
| 35 | `test/widget/battle_shelf_icons_test.dart` | a spell with no asset stays text-only in the overflow too | the open overflow sheet has no `Image` inside any `_OverflowRow`'s trailing button | 10 |

**The no-squeeze assertion** is Unit 9's, reused verbatim because it fits
exactly: every `Text` in the new `Wrap` is laid out at its intrinsic width
(nothing is `Expanded`, nothing is `FittedBox`-scaled, nothing sets `overflow`),
so a squeezed or ellipsised paragraph fails the comparison.

```dart
final paragraphs = tester.renderObjectList<RenderParagraph>(
  find.descendant(of: find.byKey(controlsKey), matching: find.byType(Text)),
);
for (final paragraph in paragraphs) {
  expect(
    paragraph.size.width + 0.5,
    greaterThanOrEqualTo(paragraph.getMaxIntrinsicWidth(double.infinity)),
  );
}
```

If `getMaxIntrinsicWidth` proves unusable in the harness, the executor falls
back to exception-plus-exact-text assertions and **reports the weakened proof**
rather than silently dropping it.

Synthetic images for tests 11-19 come from `dart:ui` with no asset involved:

```dart
Future<ui.Image> _twoTone(int size) {
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
all, turning tests 11 and 17 green for the wrong reason.

### Existing tests: what changes

**Nothing.** The planner swept every suite that observes a touched surface and
found no assertion that requires a verdict change:

| File | Why it survives unchanged |
| --- | --- |
| `test/game/dungeon_material_paint_test.dart` (1067 lines) | Every `MaterialComponent(plan)` call leaves `art` at `DungeonArt.none()`, so every pixel, byte-equality and paint-decision assertion still describes the procedural output it describes today. `materialCellPaint` is not touched. |
| `test/game/dungeon_material_test.dart` (621 lines) | `_markFor`, `materialPlan`, `_masonryMass` and `MaterialMark` are unchanged; `materialPhase` only exposes existing internals. |
| `test/game/dungeon_scene_test.dart` (860 lines) | `onLoad` stays synchronous in its art handling, so the single-`pump` component assertions still see a populated world. `glyphCellsAboveMaterial` is untouched. |
| `test/widget/town_shell_test.dart` | Door order and the 600 dp reachability test are position-relative and scroll-based. **Load-bearing and correct; must not be weakened to make art fit.** |
| `test/widget/craft_rooms_test.dart:483-517` | Ten-row forge order by ascending Y; inserting between `Notice` and `Heading('Materials')` preserves every pair. **Load-bearing and correct.** |
| `test/widget/tavern_screen_test.dart:85-132, 142-187` | Six-newest-lines order and notice-above-heading; same reason. **Load-bearing and correct.** |
| `test/widget/craft_surfaces_test.dart:81-163` | `Mine`/`Gather`/`Pick up` gain no icon; `find.widgetWithText(FilledButton, ...)` and `tester.tap` are widget-tree operations unaffected by `Wrap` or `Semantics`. |
| `test/battle_view_test.dart`, `test/battle_characterization_test.dart` | Pin `Wait`, `Pack (0)`, `✳ Firebolt 2`, `✳ Frost Lance 4`, `✚ Mend 3` — all still exact `Text` children under icon-plus-label. |
| `test/widget/log_drawer_test.dart:122-124` | `logPeekKey` above `controlsKey` is relative. |
| `test/widget/world_screen_test.dart`, `suspend_door_test.dart`, `boot_wiring_test.dart`, `roster_session_test.dart`, every `*_bloc_test.dart` | No touched surface. `main()` is never called by the suite, so `warmUpArt` never runs there. |

If any of these fails, the presumption is that **the implementation is wrong**,
not the test. An existing assertion may only change if the executor can show it
pinned an incidental fact — and that is an escalation, reported, not a quiet
edit.

### What only the device can prove

- **Criterion 11's device half.** `onAPhone` gives a real 411.4 dp surface and
  the no-squeeze loop denies paragraph clipping, but `flutter_test` renders with
  its own bundled font, so the actual monospace advance — and therefore whether
  the row takes one run or two in a given scene — is a device fact.
- **The height the second run costs.** The map is `Expanded`, so no widget test
  can fail on crawl height; only a measured comparison against `4bf865c`
  answers inherited lock 3.
- **Criterion 10 and 13's legibility halves.** Whether each multitone icon reads
  at 18 dp on its button, and whether strata, ashlar fracture and wall edges
  still read under the authored texture at phone density, are perceptual facts.
  The planner's inspection of the derived assets is evidence that they *can*;
  the device says whether they *do*.
- **Criterion 5's full accessibility reading.** `ExcludeSemantics` is structural
  and test 25 catches the plausible bug (a label added to the image), but a
  TalkBack pass is the real proof that an illustration is silent.
- **Criterion 17 in full.** Scene-entry and crawl-render smoothness, plus the
  launch cost the boot-time warm-up now carries, are device measurements.
- **Criterion 16's greyscale twins** are device-only by definition.

## Device acceptance capsules

User-started `Medium_Phone` (the AVD segfaults when launched from a tool
shell). Multi-step capture is delegated to bounded `flow-evidence-verifier`
capsules, one per cluster, each returning its own receipt. Greyscale twins
accompany every frame where hue could otherwise carry meaning.

**Standing obligation, before any install and after it (criterion 18):** back up
**both** device save slots from `app_flutter/save.json` — never
`files/save.json` — and prove them byte-identical afterward by SHA-256. The
`before` and `after` digests must be rendered under the same scheme and must
agree; a receipt whose digests disagree or are transcription-damaged is not
MATCH evidence.

| Capsule | Scene cluster | Frames |
| --- | --- | --- |
| **A — towns and rooms** | Stonebridge town; Northgate town; Forge in Stonebridge; Forge in Northgate; Tavern in Stonebridge; Tavern in Northgate | 6 colour + 6 greyscale. Each must show the illustration present or absent as the gate demands, every title/status line/price/refusal/door legible, nothing clipped, the seventh door reachable by scroll. |
| **B — one Crypt delve** | A visible region under authored crypt material; a remembered region beside it; unknown void; an authored crack on a wall and rubble on a floor; a stairs cell; the light gradient | 5 colour + 5 greyscale. Must show remembered flat and unlit, unknown black, the light continuous across cell boundaries, overlays reading as surface debris rather than objects. |
| **C — Sea-Cave and Ruined Keep delves** | One Sea-Cave delve showing tide strata still reading; one Ruined Keep delve showing ashlar fracture and exposed wall edges still reading | 4 colour + 4 greyscale. Criterion 13's whole content. |
| **D — lowland-road fight** | One road fight under authored art loaded | 1 colour + 1 greyscale, compared against the same scene at `4bf865c`. Proves the procedural fallback is untouched. |
| **E — controls and shelf** | Crawl control row at both worst densities, including the five-control bottom-floor stairs scene; a disabled `Drink`; the battle shelf with every icon-bearing action; the `+N` overflow sheet open | 5 colour + 5 greyscale. Every action word and live count fully visible with no ellipsis; every icon reading by shape; the armed border and `— armed` word present. |

Capsule E also records the crawl viewport height in the five-control scene
against `4bf865c`, and capsule B records scene-entry timing, so criterion 17 and
inherited lock 3 have measurements rather than impressions.

## Integrated proof ownership

Each task's executor owns its own Red/Green, its focused tests, formatting of
its touched files, `flutter analyze` and — because the tasks are sequential and
each is the sole writer at its turn — one full `flutter test` from
`packages/app` before handing off. Exact commands are in each brief. No
executor runs an app build, an emulator, a device install, a `git commit`, a
push, or any external write.

After the last task receipt is accepted, Main re-runs the integrated gate from
`packages/app`:

```sh
dart format --set-exit-if-changed --output=none lib test
flutter analyze
flutter test
```

Main then audits the diff: changes confined to root `.gitattributes`,
`tool/derive-visual-assets.sh`, `packages/app/pubspec.yaml`,
`packages/app/assets/visual/**`, `packages/app/lib/art/**`,
`packages/app/lib/town/illustration.dart`, the three town screens,
`packages/app/lib/game/{action_icon.dart, game_screen.dart, dungeon_material.dart,
dungeon_scene_material.dart, dungeon_scene.dart}`, one line of
`packages/app/lib/main.dart`, the five new test files, plus architect-owned
Unit 10 records. Zero changes under `packages/core`, `packages/content`,
`packages/app/lib/save`, `pubspec.lock`, `.github/`, or `art/visual-reboot/`.
Test count is at or above 834 plus the new tests, with no suite deleted.

Main also confirms, independently of any executor claim:

- `git check-attr filter -- art/visual-reboot/environments/ENV-001_stonebridge.png`
  reports `filter: lfs`;
- `git check-attr filter -- packages/app/assets/visual/environments/stonebridge.jpg`
  reports `filter: unspecified`;
- no file under `packages/` references `art/visual-reboot`;
- `assets/visual` appears only in `art_assets.dart`, `pubspec.yaml` and
  `tool/derive-visual-assets.sh`;
- re-running `tool/derive-visual-assets.sh` leaves the shipped assets unchanged.

Main then runs one integrated `flow-acceptance-reviewer` pass against
`CONTRACT.md` — criteria 1-15 item by item, plus the inherited locks, the
frozen control set and the accessibility rule — as a dependency barrier before
any device work. Findings are corrected on the feature checkout with focused
re-proof plus whichever full command the correction's surface traverses. Only a
closed acceptance review proceeds to the device gate.

## Global escalation boundary

Stop and report to Main/the architect rather than improvising if:

- branch/worktree preconditions do not match, or a named seam has changed since
  `4bf865c`;
- a master's bytes differ from `SHA256SUMS.txt`, or `magick` is unavailable, or
  a derivation command produces an image whose measured mean is not near 0.5
  for a material sheet;
- `git lfs` filters cannot be configured repository-locally, or `git check-attr`
  reports LFS on a shipped asset or no LFS on a master;
- the authored material cannot be drawn after the light pass without disturbing
  the mask-clipped gradient, or a palette's texture visibly double-lights;
- per-floor texture variation appears to be needed — `MaterialPlan` carries no
  floor identity and adding one is out of scope;
- an authored overlay cannot be kept inside its own cell rect, or cannot be told
  apart from a resource node, item, stair, actor or target mark;
- an existing pixel, order or reachability assertion fails for a **preserved**
  behaviour rather than an obsolete assumption — in particular
  `town_shell_test.dart`'s 600 dp door test, `craft_rooms_test.dart`'s forge
  order, or `tavern_screen_test.dart`'s notice-above-heading;
- an illustration cannot fit its height budget without displacing a title,
  status line, price, refusal sentence, control or door;
- the control row cannot show every action word and live count at 411.4 dp
  without an ellipsis, or the reflow costs materially more map height than one
  button run;
- a control would have to be added, removed, renamed, reordered or rewired, or
  a label or refusal sentence reworded;
- an icon does not read on its button background in greyscale — report it with
  the frame; do not tint the set;
- `getMaxIntrinsicWidth` or `takeException` cannot express the no-squeeze proof;
- the work appears to require `packages/core`, `packages/content`,
  `pubspec.lock`, a dependency, a save/bloc/event change, a CI change, a
  `git commit`, or implementation on `main`.

Report; do not redesign the contract.

**Executor discretion** covers: private helper, holder-class and test-helper
names; the internal shape of `tool/derive-visual-assets.sh` (loops, arrays,
functions) as long as the recorded per-class commands and their parameters are
the ones executed; import ordering; the exact fixture staging (seeds, monster
and item placement, `copyWith` shape) for the new tests; whether the synthetic
test image helper lives in a test file or `test/support/`; whether dartdoc is
carried on new app-side declarations.

It does **not** cover: the LFS pattern or what it excludes; the shipped asset
root, directory layout, formats, dimensions or derivation parameters; the
`assets:` declaration shape; any catalogue enum's values, names or paths;
`DungeonArt`'s public shape, the `none()` default, the warm-up call site, or the
no-dispose lifetime; the render-pass order or the blend mode; the mask's
kind filter; the phase salts or the no-per-floor-variation rule; the overlay
gates, variants or the replace-not-add rule; the illustration heights, fit,
`ExcludeSemantics`, `errorBuilder` or insertion points; the town gate; the
`Wrap` decision, `minimumSize`, padding, icon size or gap; the icon-to-control
mapping; the `Semantics` wrapper shape; the deletion of `maxLines`/`overflow`;
any frozen wording; or any verdict in the "existing tests" table.

## Plan quality gate

- **COR — PASS.** Ownership is unchanged everywhere: no bloc, event, state
  field, rule, save byte or RNG is touched, and `packages/core` and
  `packages/content` are structurally out of reach. The authored layer consumes
  `MaterialCell` and `MaterialMark` and changes no decision — `materialCellPaint`
  is not edited, which is what keeps the knowledge boundary authoritative. The
  three hard invariants are structural rather than tested-into-place: unknown
  cells are absent from `MaterialPlan.cells`, the authored masks are
  visible-only, and remembered marks already carry `crack: 0` / `speck: false`.
  The recon's proposed `_drawCellBase` seam was checked at source and
  **corrected** — the opaque light pass would have erased it — and the
  correction is what makes the no-double-exposure claim true, together with a
  derivation that measurably centres each sheet on `softLight`'s identity
  element. Error semantics are decided rather than inherited: warm-up never
  throws, a missing asset degrades to the procedural layer or an empty box, and
  boot's one-door failure behaviour is untouched. The worst control density is
  enumerated from the gates and closed by three source facts, and the chosen
  geometry does not depend on the enumeration. Determinism is stronger than the
  contract asks: a world-space field is a pure function of position, and the
  only new hashing reuses the existing grammar with two fresh salts.
- **TTC — PASS.** Expected Red per task is stated in each brief: task 01's
  catalogue tests fail to compile until `art_assets.dart` exists and then fail
  on missing files until the script has run; task 02's tests fail on
  `findsNothing` for keys that do not exist; task 03's tests fail on
  byte-equality between the art and no-art renders because no authored pass
  exists; task 04's phone-width tests fail on the ellipsised text that the
  current `Row` produces. Every criterion maps to at least one named test or a
  named device capsule, and the negative cases are present and load-bearing:
  Northgate with nothing substituted, a road rendered identically with art
  loaded, an ungated cell drawing no overlay, a spell with no asset staying
  text-only, a control with no asset carrying no icon gap, and the shipped
  directories carrying *exactly* the catalogue — which is the only thing closing
  the hole that directory-level `assets:` declarations open. The synthetic sheet
  is specified two-tone precisely because a uniform mid-grey would make two
  tests green for the wrong reason. The limits of widget proof are stated
  rather than proxied, and the one unusual assertion carries a named fallback
  that must be reported if taken.
- **CRF — PASS.** Four new files, each with one responsibility: a catalogue of
  paths, a decoded-image owner, one illustration widget, one icon widget. Two
  new public functions in existing files, both pure. One new optional
  constructor parameter with a const default, which is what keeps roughly
  twenty existing call sites untouched. The authored pass is two clip-and-fill
  draws for the whole layer rather than a per-cell loop, and every Paint, Path,
  Shader and Rect it needs is built once per plan adoption, so the frame path
  stays allocation-free — the same discipline `_PreparedMaterialCell` already
  enforces. No abstraction is introduced for a second implementation that does
  not exist: no theme indirection, no asset-service interface, no injection
  seam, no test-only constructor, no compatibility shim. The 18 dp icon recipe
  lives in exactly one widget because two surfaces need it; the illustration
  recipe lives in one widget because three screens need it. `lowlandRoad`'s
  exclusion is an absent enum value rather than a runtime branch. Resident
  memory is 14.7 MB for the whole authored layer, against 186 MB for the
  masters, and is stated rather than discovered.
- **SEC — SKIP (no new trust boundary).** Every asset is a build-time artefact
  of the repository, bundled into the app and loaded through
  `rootBundle`/`AssetImage`. There is no network fetch, no user-supplied or
  downloaded image, no file-system path derived from input, no deserialization
  of untrusted data, no new persistence, no privilege and no secret. Decoding
  is Flutter's own codec over bytes the build shipped. The masters move into
  Git LFS, which changes how git stores blobs, not what the app trusts. Save
  bytes are touched only by the device gate's backup discipline, over unchanged
  product code.

Residual risks deliberately left to implementation and device evidence:

1. **The control row reaches two runs at five controls**, costing ~44 dp of map
   in those scenes. The arithmetic is worked and the alternative is the
   ellipsis D2 exists to retire, so this is an accepted trade rather than an
   open question — but only the device says whether it reads well. Bounded
   correction: `spacing` and `runSpacing`. Never a restored ellipsis, never a
   reworded label.
2. **Multitone icons on the M3 light `FilledButton` container.** The planner
   checked all eight derived icons over the real container colour in colour and
   in greyscale and every one reads by shape. If one fails on device, the named
   correction is a per-icon derivation change or an alpha-only silhouette
   through `ImageIcon` — and that second option is a design change the
   architect decides, not the executor.
3. **Authored texture over regional patterns.** Strata, ashlar fracture and
   wall edges are drawn by untouched code after the authored pass, and the
   sheets carry no net luminance shift, so the cues cannot be dimmed
   arithmetically. Whether they still *read* at phone density under added
   texture is capsule C's question. Bounded correction: the `softLight`
   amplitude, by re-deriving with a different polynomial. Reducing an accepted
   regional cue is an escalation, per the contract's non-goals.
4. **`overlayOpacity = 0.55`** is chosen from the masters' measured alpha
   coverage, not from a device. Bounded correction 0.35-0.75; the gates,
   variants and clipping are not correction surface.
5. **Mirror tiling at an eight-cell period.** Invisible for high-passed noise by
   construction, but a large floor shows two to four repeats. If a repeat is
   visible on device, the correction is the shader scale — a smaller scale
   lengthens the period at the cost of texture sharpness.
6. **Boot now decodes ~14.7 MB before the first frame.** That is deliberate:
   it is the only way to guarantee criterion 17's no-hitch requirement. Capsule
   B records the launch cost. If it is material, the correction is to defer the
   three illustration precaches (not the dungeon sheets) to first use.

None is an unresolved product or architecture decision.

## Planner receipt

- **STATUS:** READY — execution-grade; implementation remains separately
  unauthorized until explicit user approval of this plan.
- **Source/dirty assumption:** `4bf865c` on `main`; `packages/` clean;
  architect-owned `LEDGER.md`, `RESUME.md`, `units/unit-10/`,
  `external/unit-10-chatgpt-handoff/` and the untracked `art/` masters all
  dirty and preserved. Implementation branches to `residuum-visual-reboot-10`,
  never writes on `main`.
- **Tasks:** `plan-tasks/01-asset-pipeline-and-catalogue.md` ->
  `02-environment-illustrations.md` -> `03-authored-dungeon-materials.md` ->
  `04-icon-language-and-control-row.md`. Strictly sequential; 02/03/04 depend
  on 01's catalogue and decode owner and are file-disjoint from one another but
  are not run concurrently.
- **Quality:** COR/TTC/CRF PASS; SEC SKIP for no trust-boundary change.
- **Next action:** Main validates this receipt, presents the plan for explicit
  user approval, and only after approval creates `residuum-visual-reboot-10`
  from `4bf865c` and dispatches task 01 to a fresh non-isolated
  `flow-plan-executor`.
