# Unit 13 recon — what the presentation layer actually is, at `907a4a8`

Three read-only scouts mapped the three presentation territories
(`agent://TownScreensRecon`, `agent://CrawlSeamRecon`, `agent://DungeonArtRecon`).
Every load-bearing constant below was re-read by the architect at source; the
claims the audit leans on hardest — the two style seams, the missing
town-side theme, `cameraCellSize`, the log marks, the asset inventory — were
verified by hand, not taken from a report.

## There are two style seams, not one, and they duplicate the palette

- `packages/app/lib/game/crawl_style.dart:3-12` declares `crawlInk` `#E6EAF0`,
  `crawlDim` `#8A919E`, `crawlPanel` `#15181F`, `crawlRule` `#2A2E38`,
  `crawlVoid` `#0E1014`, plus `crawlRaised` `#1B1F27`, `crawlRecessed`
  `#11141A`, `crawlArmedFill` `#262B35`, `crawlDisabledRule` `#1E222A`,
  `crawlScrim` `#CC0E1014`.
- `packages/app/lib/town/town_style.dart:9-12` declares `ink` `#E6EAF0`,
  `dim` `#8A919E`, `panel` `#15181F`, `rule` `#2A2E38` — **the same four
  values, again**, with no shared source.
- Neither seam owns a typeface beyond `fontFamily: 'monospace'`. Every text
  style in both files sets it (`crawl_style.dart:38-145`,
  `town_style.dart:14-49`).

## The lavender is the absence of a town-side theme

- `main.dart:81-85` and `main.dart:169-172` build the only `MaterialApp`
  themes: `ThemeData(brightness: dark, scaffoldBackgroundColor: #0E1014,
  useMaterial3: true)`. Nothing else is set, so Material 3 supplies its
  default lavender `primary`.
- The crawl escapes it: `crawl_style.dart:146-176` builds a local
  `crawlTheme` singleton with icon, progress, text-button, bottom-sheet and
  dialog themes, applied inside the crawl.
- The town and side screens have **no equivalent**, so every stock
  `FilledButton` and `ChoiceChip` renders in default M3 lavender. This is
  visible on the Character, Forge, Tavern and Pack frames and on no crawl
  frame. It is a missing theme, not a styling choice.

## Row grammar is per-screen, not shared

`TownScreensRecon` found nine different row anatomies with no common
container: `ItemRow` (`town_style.dart:102-145`, 28 dp mark column, 104 dp
trailing button), `_SkillRow` (`skills_screen.dart:29-65`), `_GearRow`
(`gear_screen.dart:46-105`), `_PackItemRow` (`game/pack_screen.dart:241-304`),
`SpellRow` (`game/spell_row.dart:43-75`), `_TemperRow`
(`forge_screen.dart:151-206`), `_Door` (`town_screen.dart:161-185`),
`_HeroRow` (`roster_screen.dart:265-326`), and the stock `ChoiceChip`
(`game/pack_screen.dart:95-107`). None has a leading icon slot, none has a
trailing chevron, and separation is `Divider(color: rule)` only.

The crawl, by contrast, does have one grammar: `CrawlPill` and `CrawlPanel`
(`crawl_surfaces.dart:11-61`) and `_ActionChip`
(`crawl_action_row.dart:236-305`), all fed from the seam's tokens.

## Typography inventory

| Role | Family | Size | Weight | Tracking | File:line |
|---|---|---|---|---|---|
| Place (crawl) | monospace | 15 | w500 | 3 | `crawl_style.dart:38-44` |
| Place (town) | monospace | 20 | — | 5 | `town_style.dart:34-40` |
| Room (town) | monospace | 15 | — | 4 | `town_style.dart:43-49` |
| Body | monospace | 14 | — | — | `crawl_style.dart:42-47`, `town_style.dart:14-22` |
| Body dim | monospace | 12 | — | — | `crawl_style.dart:48-52`, `town_style.dart:25-29` |
| Region label / heading | monospace | 11 | w600 | 2 | `crawl_style.dart:53-59`, `town_style.dart:54-64` |
| Panel title | monospace | 13 | w600 | 2 | `crawl_style.dart:60-66` |
| Log line | monospace | 13 | — | — | `crawl_style.dart:67-78` |
| Glyph / token | monospace | 18 | — | — | `crawl_style.dart:80-89` |
| Chip label | monospace | 12 | w400/w500/w600 by state | — | `crawl_style.dart:102-135` |

There is no display face, no serif, no second family of any kind.

## Authored asset inventory — the whole of it

`pubspec.yaml:63-66` ships three directories and **no `fonts:` block**:

- `assets/visual/environments/` — `stonebridge.jpg`, `forge.jpg`, `tavern.jpg`.
- `assets/visual/dungeon/` — 18 PNGs: floor + wall for `crypt`,
  `ruined_keep`, `sea_cave`, and four overlays each (`crack_a`, `crack_b`,
  `rubble_small`, `rubble_medium`). `lowlandRoad` has a palette but no
  authored overlays (`dungeon_render_style.dart:219-227`).
- `assets/visual/icons/` — 8 PNGs: `potion`, `pack`, `wait`, `ascend`,
  `descend`, `more`, `firebolt`, `mend`.

`ActionIcon.forSpell` (`art_assets.dart:31`) maps only `firebolt` and `mend`
and returns null otherwise. Illustrations are shown at 140 dp in town and
120 dp in a room (`illustration.dart`), inset with 8 dp padding and a 2 dp
`ClipRRect`.

Everything else is a text glyph: log categories `← → † ◎ ⇅ ✕ ■ ▲ ◆ §`
(`log_line.dart:4-14`), temper `‡` and deltas `▲ ▼`
(`item_presentation.dart:7,40`), world unknown `?`
(`world_route_diagram.dart:359`). There is no item art, no spell art beyond
two, no portrait, no monster sprite, no ornament.

## The dungeon renderer

- Cell size is fixed at **36 dp** (`grid_geometry.dart:16`), deliberately not
  fitted: the dartdoc records that fitting shrank cells to ~12 dp against a
  48 dp touch guideline on the deepest floor. Visibility, not accuracy, is
  what a bigger floor costs.
- Paint order per cell (`dungeon_scene_material.dart:760-819`): base fill →
  hero-centred radial light pass → authored texture at `softLight` and
  `authoredScale` 0.32 → procedural decoration (grit, crack, edge, rubble,
  pattern).
- Lighting is **one** radial gradient centred on the hero, radius
  `(fovRadius + 1) * 36` (`dungeon_scene_material.dart:668-697`). Wall
  surfaces take `lightLiftScale` 0.42 and `tintScale` 0.55 against floor's
  1.0/1.0 (`dungeon_render_style.dart:249-272`). Per-palette `maxLightLift`
  is 0.22–0.30 and `maxTintMix` 0.06–0.12 (`dungeon_palette.dart:15-64`).
  There are no placed light sources and no vignette.
- Walls are flat top-down fill plus a 1.2 dp inset edge stroke at 0.15–0.55
  alpha (`dungeon_scene_material.dart:12-13,820-850`). No face, no height,
  no cap treatment beyond stroke cap by biome.
- Terrain vocabulary is `wall`, `floor`, `stairsUp`, `stairsDown`
  (`dungeon_material.dart:9-11`). Stairs render as `<` / `>` glyphs. There is
  no door, torch, brazier, column, chest or altar — as a kind or as art.
- Actors are monospace glyphs at `36 * 0.73 ≈ 26 px` (`glyph_marks.dart:2`),
  hero white `#FFFFFF`, monsters gold `#D9A227`, litter teal `#7FC8B8`
  (`glyph_plan.dart:48-49`, `dungeon_palette.dart:72`). Selection is a circle
  outline at radius `36 * 0.46`, targeting a square inset by 1 dp
  (`dungeon_scene.dart:385-414`, `glyph_marks.dart:48-51`) — shape, never hue.
- Remembered cells sit at 0.4 opacity with no light pass
  (`glyph_plan.dart:8`, `dungeon_scene_material.dart:791-799`).

## Crawl region budget

`game_screen.dart:62-130`, in order: `CrawlStatus` (intrinsic) → `BattleDock`
when a battle is open (intrinsic) → `Expanded` dungeon scene with 1 dp
`crawlRule` top and bottom borders, mounted at `:101` under a `LayoutBuilder`
→ `LogPeek` fixed **104 dp** (`crawl_style.dart:22`) → `CrawlActionRow`
(intrinsic). `LogDrawer` and `_DeathOverlay` are `Stack` overlays at
`FractionallySizedBox` 0.45 and 1.0.

The action row measures every label in its heaviest style and picks the
shortest legal layout from 5 columns down to 1, with a 3-line label ceiling
(`crawl_action_row.dart:147-230`, `crawl_style.dart:30-35`).
