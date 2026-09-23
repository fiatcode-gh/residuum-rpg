# U16.5 — ASCII Crawl Full Parity: execution plan

Status: **execution-grade; approved by the user 2026-09-23; amended by A1
(below), which overrides every conflicting number in this plan and its task
briefs.** Governing WHAT/WHY:
[CONTRACT.md](CONTRACT.md), approved 2026-09-23. Plan derived from
`2c073b7c8ff6ce2d6ea6bfbbe2a91a5eac131c5d` on `residuum-visual-reboot-16`.
Dirty state at planning: `.flow/ldd/visual-reboot/LEDGER.md` and `RESUME.md`
modified (architect-owned, not touched by any task). `packages/`, `docs/`,
`AGENTS.md`, `.github/` clean. A head change before Task 01 needs targeted
revalidation of the seams named in each brief, not replanning.

Visual authority (appearance only, never facts):
`../../external/unit-16-ascii-crawl-parity-handoff/reference/{ascii-atmosphere-art-bible,ascii-exploration-mock,ascii-combat-targeting-mock,ascii-expanded-log-mock}.png`.

U16 plan decisions are superseded where they conflict (36 dp cell, ink-only
light, gradient-only backdrop, no parallax, unchanged chrome/action row, 104 dp
peek, 600 dp ceiling, `_fitFor`).

## Amendment A1 — 16 × 20 cell and 48 dp touch targets (user, 2026-09-23)

After seeing 13 × 16 on the phone, the user judged it too small to read and
tap, citing Android's 48 dp minimum touch-target guidance. **A1 overrides every
conflicting number below and in `plan-tasks/`.**

- G1: `mapCellWidth = 16`, `mapCellHeight = 20`. Glyph centre `(8, 10)`, badge
  anchor `(15.5, 0.5)`.
- G2: `mapGlyphStyle` fontSize **21** (same 17:16 line-box-to-cell ratio
  as before), `mapBadgeStyle` fontSize **10**. The Task 02 ruling holds: the
  line box may exceed the cell by at most 1.2 dp per side.
- G5: torch pool radius stays `6 · mapCellWidth` (now 96 dp). Bloom stays
  `1.6 · mapCellWidth` (now 25.6 dp). The fog lattice is unchanged (screen
  space).
- G6: reticle rect `Rect.fromLTWH(0.75, 0.75, 14.5, 18.5)`, tick and bracket
  arms 4.3 dp, strokes unchanged.
- G7: `mapTouchRadius = 24` (a 48 dp target). Every `22` becomes `24`. The
  step rule divides by `mapCellWidth` / `mapCellHeight` (the constants, not
  literals). Radius edge tests use 23.9 / 24.1 dp.
- Acceptance and §6 checklist: about 24 columns on the 393 dp phone. The
  accepted mock delta is "16 × 20 cell (mock ≈ 10–12 × 12–15)".
- Map floors (45% / 35%) and chrome G8 are unchanged. More map rows are simply
  hidden behind the pan.

## 1. How the mocks were measured

Pixel analysis of the 941×1672 originals (numpy over luminance profiles; rule,
band and column detectors; colour sampling of the brightest 5 % of a box).

- Screen span: x = 86…852 px (766 px, includes the renderer's black inner
  ring, which reads as an 8 dp screen gutter), y = 36…1624 px (1588 px).
  Scale **1.949 px/dp** (766 px ↔ 393 dp). In the 882-wide display this is
  x ≈ 81…798; panels span display x ≈ 98…782, i.e. original 104…834, an 8–9 dp
  gutter each side.
- Region shares below are **frame height ÷ 1588 px**, compared on the target
  against **875.6 dp** (vivo I2219, 392.7 × 875.6 dp, density 440). Target
  post-SafeArea height is planned at **813.8 dp** (assumed insets 37.8 dp top,
  24.0 dp bottom — Main replaces with the logcat `WindowInsets` reading at
  Checkpoint A; the floors hold with margin even under a 48 dp three-button
  bar).
- Mock map pitch measured **≈19.5 × 24.2 px = 10.0 × 12.4 dp** (≈38 columns).
  The contract's settled 13 × 16 dp cell (≈30 columns) is kept; glyph-to-cell
  proportions are copied instead ('#' ink ≈ 0.74 cell wide, ≈ 0.78 tall).
- IBM Plex Mono metrics (from the font): advance 0.600 em, cap 0.698 em,
  x-height 0.516 em, hhea 1.025/−0.275. '#' ink 0.568 × 0.698 em. '·' U+00B7
  sits at mid-x-height.

| mock measurement | px | dp | share of 1588 px |
|---|---:|---:|---:|
| wordmark cap height / ink width | 29 / 318 | 14.9 / 163 | — |
| wordmark cap top → chip bottom (expl.) | 145→278 = 133 | 68.2 | 8.4 % |
| status chips height | 37 | 19.0 | — |
| map region, exploration (chips → panel) | 278→1036 = 758 | 389 | 47.7 % |
| character panel frame | 1036→1236 = 200 | 102.6 | 12.6 % |
| recent-events frame (expl.) | 1250→1421 = 171 | 87.7 | 10.8 % |
| action slots (expl.) | 1436→1552 = 116 | 59.5 | 7.3 % |
| slot width / gap | 133 / 14 | 68.2 / 7.2 | — |
| timeline label top → pill bottom | 302→366 = 64 | 32.8 | 4.0 % |
| timeline pill height | 45 | 23.1 | — |
| map region, battle | 366→969 = 603 | 309 | 38.0 % |
| combat panel frame | 969→1216 = 247 | 126.7 | 15.6 % |
| recent-events frame (battle) | 1231→1414 = 183 | 93.9 | 11.5 % |
| action slots (battle) | 1428→1552 = 124 | 63.6 | 7.8 % |
| expanded-log sheet frame | 795→1421 = 626 | 321 | 39.4 % |
| sheet header (top → rule) | 795→857 = 62 | 31.8 | 3.9 % |
| panel column splits (hero) | 304 / 237 / 189 | 41.6 / 32.5 / 25.9 % | — |
| panel column splits (combat) | 280 / 154 / 296 | 38.4 / 21.1 / 40.5 % | — |

Sampled colours: near wall `#D4B984`–`#D9B77D`, mid wall `#848076`, far wall
`#454746`–`#4A4B47`, ghost wall `#161A1B`, near floor `#A4926A`, pool on
ground ≈ `#5B4B2C` (torch at ≈0.30 α), hero `#FDFDF8`, background
`#050A0D`–`#0D1417`, fog puffs to `#10171A`, panel fill `#090F11`, slot fill
`#111A1C`, frame `#2E3A3F`, divider `#1F272C`, chip border `#666869`,
HP bar `#FA4D40`, mana bar `#27A1E1`, bar track `#131C1E`, section title
`#EACF99`–`#FBE3A7`, labels `#9BA1A4`, values `#D8DBDD`, target name `#F84D42`,
spell name `#A6E1FA`, NOW frame bright gold, NEXT frame `#494F53`.

## 2. Locked global decisions (every task inherits these)

### G1 Map cell and projection

- `grid_geometry.dart`: `const double mapCellWidth = 13;`
  `const double mapCellHeight = 16;` replace `cameraCellSize`.
  `GridGeometry` carries `cellWidth`, `cellHeight`; `GridGeometry.fit` is
  deleted (no lib consumer). New members: `Offset centreOf(Position)`,
  `Rect rectOf(Position)`. `_axisOrigin` takes the axis cell extent.
  `positionAt` floors per axis. `heroOffScreen` uses both extents.
  `GridGeometry` remains the only projection/hit-test authority.
- Map glyph role: `mapGlyphStyle(Color ink)` — IBM Plex Mono 17 dp, w400,
  height 1.0; badge `mapBadgeStyle(Color ink)` — 8 dp. Both are functions in
  `tokens.dart` (the only non-const styles; ink is continuous).
- Glyph centred in its cell (`Anchor.center` at `(6.5, 8)`); badge anchored
  top-right at `(12.5, 0.5)`. Scale hierarchy unchanged (hero 1.08, monster
  1.04, terrain/node 1.0, litter 0.94).
- Floor glyph becomes `·` (U+00B7); walls `#`, stairs `<` `>`, hero `@`,
  existing monster/item/node glyphs. Unknown cells draw nothing (unchanged
  `glyphPlan` visibility rule).

### G2 Type roles (all `inherit: false`, explicit `height`, `textBaseline: alphabetic`, `fontFeatures` incl. `tabularFigures`, display roles also `liningFigures`)

`const String monoFace = 'IBM Plex Mono';` Files: `IBMPlexMono-Regular.ttf`
(weight 400) and `IBMPlexMono-SemiBold.ttf` (600) from
`https://raw.githubusercontent.com/google/fonts/main/ofl/ibmplexmono/`, with
`OFL.txt` saved as `assets/fonts/OFL-IBMPlexMono.txt`. SHA-256 at planning:
Regular `6a3412f058c7d8dfd9170c41e85ade48e5156ecb89356110ca57a0a27734af46`,
SemiBold `d3c38e55c78f5b0f28009fddba4834ec503278936a5986032424c9bd2d23aa46`,
OFL `7e6b2818edbd8f6a01ae80641cc8f16a51080d08fb4e532be3a0b6f74adb07da`.
Plex Mono covers all printable ASCII, `·`, `–`, `—`, `×`, `⁰¹²³⁴⁵⁶⁷⁸⁹`, `†`,
`§`, `←`, `→`, `↓`, `›`; it lacks every geometric mark (`◎⇅✕■▲◆✖◉△◇`, school
markings), so no mark is drawn in mono — marks become Material icons or
code-drawn shapes.

| role | face | size | weight | height | tracking | colour |
|---|---|---:|---:|---:|---:|---|
| `displayWordmark` | EB Garamond | 23 | 500 | 1.0 | 6 | `crawlHero` |
| `displaySection` | EB Garamond | 12.5 | 500 | 1.12 | 3 | `crawlGold` |
| `displaySheetTitle` | EB Garamond | 15 | 500 | 1.1 | 4 | `crawlGold` |
| `displayLabel` | EB Garamond | 9.5 | 500 | 1.16 | 2 | `crawlTextDim` |
| `displayName` | EB Garamond | 15 | 500 | 1.13 | 0.3 | `crawlEnemy` |
| `displayNameCold` | EB Garamond | 15 | 500 | 1.13 | 0.3 | `crawlCold` |
| `textSlot` | Spectral | 12.5 | 400 | 1.12 | 0 | `crawlText` |
| `textSlotArmed` | Spectral | 12.5 | 600 | 1.12 | 0 | `crawlText` |
| `textSlotDisabled` | Spectral | 12.5 | 400 | 1.12 | 0 | `crawlTextDim` |
| `monoMeta` | Plex Mono | 11 | 400 | 1.27 | 0.3 | `crawlTextDim` |
| `monoMetaCold` | Plex Mono | 11 | 400 | 1.27 | 0.3 | `crawlCold` |
| `monoChip` | Plex Mono | 11 | 400 | 1.0 | 0.2 | `crawlText` |
| `monoData` | Plex Mono | 11.5 | 400 | 1.13 | 0 | `crawlText` |
| `monoDataDim` | Plex Mono | 11.5 | 400 | 1.13 | 0 | `crawlTextDim` |
| `monoItem` | Plex Mono | 10.5 | 400 | 1.24 | 0 | `crawlText` |
| `monoLog` / `monoLogHostile` / `monoLogCold` / `monoLogTorch` | Plex Mono | 10.5 | 400 | 1.43 | 0 | `crawlText` / `crawlEnemy` / `crawlCold` / `crawlTorch` |
| `monoFigure` / `monoFigureCold` | Plex Mono | 20 | 600 | 1.1 | 0 | `crawlHero` / `crawlCold` |
| `monoToken` / `monoTokenHostile` | Plex Mono | 11 | 400 | 1.0 | 0 | `crawlHero` / `crawlEnemy` |
| `monoSlotMeta` | Plex Mono | 9 | 400 | 1.11 | 0 | `crawlTextDim` |
| `mapGlyphStyle(ink)` / `mapBadgeStyle(ink)` | Plex Mono | 17 / 8 | 400 | 1.0 | 0 | argument |

Display roles also carry `fontVariations: [FontVariation('wght', 500)]` like
the existing display roles. Existing roles are untouched.

### G3 Palette tokens (`tokens.dart`)

| token | value | use |
|---|---|---|
| `crawlTorch` | `#FFD27A` | torch pool, discovery/loot log tint, Watched mark |
| `crawlHero` | `#FFF4D6` | `@`, bloom, wordmark, figures, hero token |
| `crawlEnemy` | `#FF5B5B` | monster glyphs, hostile log, HP fills, target name |
| `crawlEnemyHigh` | `#FF3B3B` | target reticles (marked and selected) |
| `crawlCold` | `#4FC3FF` | mana fill, litter glyphs, spell/item log, armed slot glow |
| `crawlGold` | `#D6C280` | section titles, Material marks, NOW frame |
| `crawlText` | `#E6E1D6` | primary chrome text |
| `crawlTextDim` | `#9CA3AF` | labels, meta, secondary text |
| `crawlBackground` | `#0A0F14` | map base, replaces `dungeonVoid` |
| `crawlFog` | `#1A2430` | crypt fog (default region fog) |
| `crawlPanelFill` | `#0B1215` | panel/sheet fill |
| `crawlSlotFill` | `#10181B` | action slot fill |
| `crawlFrame` | `#2E3A3F` | 1 dp panel/slot frames |
| `crawlDivider` | `#1F272C` | column dividers, disabled frames |
| `crawlChipBorder` | `#4A5054` | chip and NEXT-pill outline |
| `crawlMeterTrack` | `#131C1E` | bar tracks |
| `crawlGoldRule` | `#47D6C280` (α 0.28) | wordmark rule, hero-name rule |
| `crawlCalloutFill` | `#F00B1215` | callout card |

Stone inks (public consts in `dungeon_palette.dart`), identical in every
region including road fights: wall lit `#DCC08A` / shade `#8F8C82`; floor lit
`#B39B6C` / shade `#6B665B`; stairs lit `#FFE3A0` / shade `#B8B09A`.
`litterInk` becomes `crawlCold` (the old teal `#7FC8B8` sat next to enemy red —
a red-vs-green-adjacent pair); `nodeInk` stays `#A87BC0`. `DungeonPalette`
holds only `fog`: crypt `#1A2430`, seaCave `#152A3A`, ruinedKeep `#221F2A`,
lowlandRoad `#1D2327`. `paletteForDungeon`/`paletteForRoad` unchanged.
No red-vs-green pair exists anywhere; every category also has a glyph, shape
or word.

### G4 Light and value (`glyph_marks.dart::glyphInk(GlyphCell cell, Position hero) → Color` incl. alpha)

`GlyphCell` gains `final Color shade` (constructor `Color? shade` →
`shade ?? ink`); terrain cells set `ink` = lit ink, `shade` = shade ink.

- `d = sqrt(dx² + dy²)` in cells from `hero`; `t = clamp(d / fovRadius, 0, 1)`
  (`fovRadius` = 8, exported by core); `light = (1 − t)²`.
- visible terrain (`opacity == fullOpacity`): colour
  `Color.lerp(cell.shade, cell.ink, light)` at alpha `0.55 + 0.45·light`.
- remembered terrain and remembered nodes: `cell.shade` at alpha
  `rememberedOpacity`, which becomes **0.24**.
- visible node, litter, monster, hero: `cell.ink` at alpha 1.
- hero ink `crawlHero`; monster ink `crawlEnemy`.
- Checks: t = 1 wall → ≈ `#535249` on base (mock far visible `#4A4B47`);
  t = 0 → `#DCC08A` (mock near `#D9B77D`); remembered wall ≈ `#29292A`
  (mock ghost `#161A1B`–`#2A2A28`, "clearly dimmer").

### G5 Atmosphere (`dungeon_atmosphere.dart`, replaces `dungeon_depth.dart`)

Drawn by `GameWidget.backgroundBuilder` beneath the transparent Flame surface,
`IgnorePointer` + `ExcludeSemantics`, filling the map viewport only.
Bottom → top: base, fog, vignette, torch pool, hero bloom, then Flame glyphs.

- `geometry = GridGeometry.camera(size, snapshot.columns, snapshot.rows, snapshot.focus, snapshot.pan)` (the same authority as input).
- **Parallax:** `drift = MediaQuery.disableAnimationsOf(context) ? Offset.zero : Offset((origin.dx·0.12).clamp(−40, 40), (origin.dy·0.12).clamp(−40, 40))` where `origin = geometry.origin`. Only the fog layer moves by `drift`; base, vignette, pool, bloom and glyphs never do.
- **Base:** fill `crawlBackground`.
- **Fog:** lattice spacing `S = 56` dp in backdrop space covering
  `[−40 − R, width + 40 + R] × [−40 − R, height + 40 + R]`; per lattice point
  `(ix, iy)`: jitter `jx = (fogHash(ix, iy, 1) − 0.5)·0.8·S`,
  `jy = (fogHash(ix, iy, 2) − 0.5)·0.8·S`; `k = fogHash(ix, iy, 3)`; skip when
  `k < 0.35`; otherwise a radial gradient disc radius `R = 72.8` from
  `palette.fog` at α `0.10 + 0.30·(k − 0.35)/0.65` to α 0. The field is
  recorded once into a `ui.Picture` per `(size, fog)` and painted translated
  by `drift`.
  ```dart
  const int fogSalt = 0x5E5D1DE;
  double fogHash(int ix, int iy, int channel) {
    var h = ((ix * 0x27d4eb2d) ^ (iy * 0x165667b1) ^ (channel * 0x9e3779b9) ^ fogSalt) & 0xFFFFFFFF;
    h = ((h ^ (h >> 15)) * 0x2c1b3c6d) & 0xFFFFFFFF;
    h = ((h ^ (h >> 12)) * 0x297a2d39) & 0xFFFFFFFF;
    h ^= h >> 15;
    return (h & 0xFFFFFF) / 0x1000000;
  }
  ```
- **Vignette:** radial gradient centred on the viewport, radius = half the
  viewport diagonal, `#020406` α 0 at stop 0.55 → α 0.85 at stop 1.0 (darker
  than the base, so it also dims fog toward the edges).
- **Torch pool:** centre `geometry.centreOf(snapshot.heroPosition)`, radius
  `6 · mapCellWidth = 78` dp, `crawlTorch` α 0.30 / 0.15 / 0.05 / 0 at stops
  0 / 0.35 / 0.70 / 1.0.
- **Hero bloom:** same centre, radius `1.6 · mapCellWidth = 20.8` dp,
  `crawlHero` α 0.28 → 0. Replaces the per-glyph halo (removed).
- Inputs are only size, `palette.fog`, drift and hero screen centre — never
  tiles, visibility, monsters or items — so unknown cells cannot be revealed.
  Same state + camera ⇒ identical frame.

### G6 Target geometry (inside the 13 × 16 cell, so glyph children stay contained)

Reticle rect `Rect.fromLTWH(0.75, 0.75, 11.5, 14.5)`, colour `crawlEnemyHigh`.
- **marked** (legal armed target, not selected): four corner ticks, arm 3.5 dp,
  stroke 1.0 dp.
- **selected** (`GlyphCell.selected`): left and right full-height brackets
  (`[ ]`), stroke 1.75 dp, arms 3.5 dp; supersedes the ticks on that cell.
- Shape and weight separate the two; hue is identical.

### G7 Touch resolution (`map_touch.dart`)

```dart
const double mapTouchRadius = 24;
sealed class MapTouch { const MapTouch(); }
final class MapTouchCell extends MapTouch { const MapTouchCell(this.position); final Position position; }
final class MapTouchInspect extends MapTouch { const MapTouchInspect(this.actor); final Actor actor; }
final class MapTouchNothing extends MapTouch { const MapTouchNothing(); }
MapTouch resolveMapTap(GameViewState state, GridGeometry geometry, Offset local);
MapTouch resolveMapLongPress(GameViewState state, GridGeometry geometry, Offset local);
```
Definitions: `under = geometry.positionAt(local)`; `dist(p) = (local − geometry.centreOf(p)).distance`;
*known* = monsters with `state.inspectTargetAt(m.position) != null`;
*legal* = monsters whose id is in `state.armedTargets`;
`nearest(set)` = member with `dist ≤ 22`, minimum `dist`, ties by
`byRowThenColumn(position)` then `id.compareTo`; none → null.

Tap, armed (`state.armedSpellId != null`), first match wins:
1. `under` holds a legal monster → `MapTouchCell(under)`.
2. `nearest(legal)` → `MapTouchCell(its position)`.
3. `under != null` → `MapTouchCell(under)` (the bloc disarms, as today).
4. otherwise `MapTouchNothing`.

Tap, unarmed:
1. `under` holds a known monster `m` → melee/inspect of `m` (below).
2. **step-cell guard:** `under` is orthogonally adjacent to the hero →
   `MapTouchCell(under)` (preserves "tap an adjacent cell to move" when a
   monster stands one cell further; the contract's "every existing behaviour
   stays").
3. `m = nearest(known)` → melee/inspect of `m`.
4. `dist(hero) ≤ 22` and `under != hero`: `u = (local.dx − hc.dx)/13`,
   `v = (local.dy − hc.dy)/16`; `|u| ≥ |v|` → east/west by sign of `u`, else
   south/north by sign of `v`; target = `hero.step(dir)`; if target is inside
   the map bounds → `MapTouchCell(target)`, else fall through.
5. `under != null` → `MapTouchCell(under)` (includes the hero's own cell,
   step, auto-walk and refusal exactly as the bloc decides today).
6. otherwise `MapTouchNothing`.

melee/inspect of `m`: `m.position.isOrthogonallyAdjacentTo(hero)` →
`MapTouchCell(m.position)` (bloc bump); else `MapTouchInspect(m)`.

Long-press: `under` holds a known monster → inspect it; else `nearest(known)`
→ inspect; else nothing.

Movement is 4-way in core (`Direction` has four values), so the contract's
"8-way direction" resolves to the dominant axis with horizontal winning an
exact diagonal (see §7 E1). `GameScreen` maps: `MapTouchCell` →
`TileTapped(position)`; `MapTouchInspect` → inspect presentation (sheet until
Task 12, callout after); `MapTouchNothing` → no game event (after Task 12, it
dispatches `InspectDismissed` only when a callout is open).

### G8 Fixed chrome (dp at text scale 1.0; gutter 8)

Text scaling in the crawl body is clamped by
`MediaQuery.withClampedTextScaling(maxScaleFactor: 1.3)`; every fixed region
height is `base × crawlScale(context)` where
`crawlScale(context) = (MediaQuery.textScalerOf(context).scale(12) / 12).clamp(1.0, 1.3)`.
Floors and proportions are asserted at scale 1.0 (the target phone's font
scale). Inner content is top-aligned natural layout.

`GameScreen` body (inside `SafeArea`):
```
Stack[
  Column[
    CrawlHeader                                  88
    if isBattleOpen: BattleDock (timeline)       58
    Expanded(Stack[
      Column[
        Expanded(map slot, dungeonSceneSlotKey, no border)
        gap 6
        isBattleOpen ? CombatPanel 124 : HeroPanel 102
        gap 7
        LogPeek 96
        gap 7
      ],
      if logDrawerExtent != peek: LogDrawer overlay
    ]),
    CrawlActionBar                               60
    gap 6
  ],
  if game over: death overlay
]
```

**Exploration** (safe height 813.8)

| region | dp | y top | mock dp | mock share | target share | Δ vs mock |
|---|---:|---:|---:|---:|---:|---:|
| header (wordmark cap→chips) | 88 (visual 78) | 0 | 68.2 | 8.4 % | 8.9 % | +6 % |
| map | 441.8 | 88 | 389 | 47.7 % | 50.5 % | +6 % |
| hero panel | 102 | 535.8 | 102.6 | 12.6 % | 11.6 % | −8 % |
| recent events | 96 | 644.8 | 87.7 | 10.8 % | 11.0 % | +2 % |
| action bar | 60 | 747.8 | 59.5 | 7.3 % | 6.9 % | −6 % |

**Battle**

| region | dp | y top | mock dp | mock share | target share | Δ |
|---|---:|---:|---:|---:|---:|---:|
| header | 88 | 0 | 68.2 | 8.4 % | 8.9 % | +6 % |
| timeline (visual label→pill 38) | 58 | 88 | 32.8 | 4.0 % | 4.3 % | +8 % |
| map | 361.8 | 146 | 309 | 38.0 % | 41.3 % | +9 % |
| combat panel | 124 | 513.8 | 126.7 | 15.6 % | 14.2 % | −9 % |
| recent events | 96 | 644.8 | 93.9 | 11.5 % | 11.0 % | −5 % |
| action bar | 60 | 747.8 | 63.6 | 7.8 % | 6.9 % | −12 % |

Floors: exploration map 441.8 ≥ 394.0 (45 %); battle 361.8 ≥ 306.5 (35 %);
with a 48 dp bottom inset: 417.8 / 337.8, still passing. Chrome does not
depend on action count, armed state, log extent, callout or notes.

**Expanded log** (exploration; battle identical from the peek down)

| region | dp | mock dp | mock share | target share | Δ |
|---|---:|---:|---:|---:|---:|
| sheet (half extent) | min(345, overlay height) | 321 | 39.4 % | 39.4 % | 0 % |
| sheet header (handle+title row) | 40 | 31.8 | 3.9 % | 4.6 % | +17 % |
| row pitch | 18 (wraps allowed) | 16 | — | — | — |

Sheet bottom = overlay bottom (7 dp above the action bar), so the bar stays
visible and live; half extent top = `max(0, overlayHeight − 345)`; full
extent top = overlay top (= map top). Peek → half → full → peek cycling and
close are unchanged bloc behaviour.

**Header internals (88):** top 6; `RESIDUUM` `displayWordmark` centred (23);
gap 7; 1 dp `crawlGoldRule` (x 8…384.7); gap 7; meta line `monoMeta` centred
(14); gap 6; chips row centred (20); bottom 4. Chip: height 20, radius 10,
1 dp `crawlChipBorder`, fill `crawlBackground` α 0.5, padding h 9, 8 dp mark,
gap 5, `monoChip` word, spacing 8.

**Timeline internals (58):** two columns, NOW (intrinsic) · divider · NEXT
(Expanded, horizontal scroll). Each: `displayLabel` (11), gap 3, 44 dp hit
row with the 24 dp pill at its top. Divider 1 × 24 `crawlDivider`, margin h 8.
Pill: radius 5, padding h 8, glyph + 5 + word in the actor's hue
(`monoToken` hero, `monoTokenHostile` monsters); current pill 1.5 dp
`crawlGold` border, fill `crawlGold` α 0.08; others 1 dp `crawlChipBorder`,
no fill; spacing 8. No numbers.

**Hero panel internals (102):** frame fill `crawlPanelFill`, 1 dp
`crawlFrame`, radius 6, padding l/r 11, top 10, bottom 8; columns flex
40/33/27 separated by 1 dp `crawlDivider` (inset 8 top/bottom) with 11 dp
either side. Left column rows at y: 0 hero label (`displaySection`, 14);
16 rule 1 dp `crawlGoldRule`; 21 `HP a/b` `monoData` (13, key `hpMeterKey`
on the row+bar group); 35 bar 6 (radius 3, `crawlEnemy` on
`crawlMeterTrack`); 45 `Mana a/b` (13, `manaMeterKey`); 59 bar 6
(`crawlCold`); 71 stats (13). Mana rows are replaced by an equal `SizedBox`
when no spell is known. Middle: 0 `WEAPON` `displayLabel` (11); 14 mark 16 +
6 + name `monoItem` max 2 lines ellipsis (26); 44 `ARMOUR`; 58 mark + name.
Right: 0 `QUICK`; 14 `potion.png` 16 + 6 + `Potion ×N` `monoItem`; 44 `PACK`;
58 `pack.png` + `n/20`.

**Combat panel internals (124):** same frame; padding 10/11; flex 36/24/40.
TARGET: 0 `TARGET` (11); 14 name `displayName` 1 line (17); 35 `HP a/b`
`monoData` (13); 51 bar 5 (`crawlEnemy`); 62 fact line A `monoMeta` (14);
76 fact line B (14). Middle: 0 `YOU` (11); 13 `HP a/b` `monoData`
(`hpMeterKey`); 26 `Mana a/b` `monoDataDim` (`manaMeterKey`, only with
spells); 45 divider; 52 `DAMAGE` (11); 66 figure (`monoFigure`, or
`monoFigureCold` for an armed bolt) + 4 + caption `monoSlotMeta`
(`melee`/`spell`). SPELL: 0 `ARMED SPELL` / `READIED SPELL` (11); 14 mark 18
+ 6 + name `displayNameCold` (17); 36 `Mana Cost` `monoDataDim` + ` N`
`monoData`; 52 effect `monoMeta`; 71 tags `monoMetaCold` (`A | B | C`).

**Recent events internals (96):** frame as panels; padding l/r 12, top 8,
bottom 4; header row 16: `RECENT EVENTS` `displaySection` left, right
`N entries` `monoMeta` + 4 + `Icons.unfold_more` 16 `crawlTextDim`; gap 3;
rule 1 `crawlDivider`; gap 4; four 15 dp line slots, bottom-aligned, the last
four entries oldest→newest top→bottom, one line each
(`maxLines: 1`, `TextOverflow.ellipsis`), category tint (G10), older three at
`Opacity(0.72)`. The whole peek remains the `LogDrawerHandlePulled` button.

**Action bar (60):** width `W = screenWidth − 16` (376.7). `n ≤ 5`: slot
width `(W − 4·7)/5 = 69.7`, `n` slots then `5 − n` empty frames (1 dp
`crawlDivider` α 0.6, no fill, no semantics, no ink). `n > 5`: slot width
`(W − 5·7 − 18)/5 = 64.7`, horizontal `SingleChildScrollView`
(`ClampingScrollPhysics`), so slots 1–5 are whole and slot 6 shows an 18 dp
peek at offset 0. Slot: radius 6; fill `crawlSlotFill`; 1 dp `crawlFrame`;
top 7, mark 22, gap 3, label `textSlot` in a single-line
`FittedBox(scaleDown)` (14), metadata line `monoSlotMeta` (10). States:
available (as above); disabled (fill `crawlPanelFill`, frame `crawlDivider`,
`textSlotDisabled`, mark opacity 0.45); armed (1.5 dp `crawlCold` frame +
`BoxShadow(crawlCold α 0.45, blur 8)`, `textSlotArmed`, metadata line reads
`— armed`). Keys: bar `actionRowKey`, slots `ValueKey(action.id)`.

**Notes** (`_notesFor`): an `IgnorePointer` overlay at the map slot's
top-left (`top 6, left 8, right 60`), each note `textLineDim` on
`crawlBackground` α 0.78, radius 4, padding 6/3 — inside the map rectangle,
never resizing it.

### G9 Marks (Material icons tinted `crawlGold` at the given size; shipped PNGs untinted)

| surface | fact | mark |
|---|---|---|
| action | drink / pack / wait / ascend / descend / spells-overflow | shipped `potion` / `pack` / `wait` / `ascend` / `descend` / `more` |
| action | spell firebolt / mend | shipped `firebolt` / `mend` |
| action | spell frost-lance / ward / bind / banish / other | `ac_unit` / `health_and_safety` / `link` / `blur_on` / `auto_awesome` |
| action | pick-up | `back_hand` |
| action | gather (ore vein / herb patch) | `hardware` / `spa` |
| action | flee / move-on | `directions_run` / `hiking` |
| action | leave-dungeon (Leave / Finish) | `logout` / `flag` |
| hero panel | weapon / bare fists | `gavel` / `front_hand` |
| hero panel | chest piece / none | `shield` / `shield_outlined` |
| hero panel | quick / pack | shipped `potion` / `pack` |
| peek | expand affordance | `unfold_more` |

`action_icon.dart` gains `sealed class ActionMark` with `ShippedMark(ActionIcon)`
and `FontMark(IconData)` and one `ActionMarkView(mark, size)` widget;
`ActionMark spellMark(Spell)`; `CrawlAction.mark` replaces `CrawlAction.icon`
and is required.

Status-chip shapes (code-drawn, 8 dp): Engaged filled diamond `crawlEnemy`;
Watched 1.5 dp ring `crawlTorch`; Steady filled circle `crawlGold`; Wounded
half-filled circle `crawlTorch`; Critical filled triangle `crawlEnemy`; Dead
1.5 dp X `crawlEnemy`; Ward filled square `crawlCold`.

### G10 Log categories (pictogram 15 dp + sentence, both in the tint)

| `LogCategory` | pictogram | tint role |
|---|---|---|
| struck | `heart_broken` | `monoLogHostile` |
| hit | `gavel` | `monoLogHostile` |
| died | `dangerous` | `monoLogTorch` |
| noticed | `visibility` | `monoLogHostile` |
| moved | `directions_walk` | `monoLog` |
| refused | `block` | `monoLog` |
| item | `inventory_2` | `monoLogCold` |
| raised | `trending_up` | `monoLogCold` |
| gathered | `diamond` | `monoLogTorch` |
| reported | `priority_high` | `monoLog` |

Mapping functions live in `log_drawer.dart` (`IconData logPictogram`,
`TextStyle logTint`); `LogCategory.mark` is deleted (no remaining consumer);
`word`, values, order and semantics label `'${word}. ${sentence}'` stay.

### G11 Displayed facts → source

| field | source |
|---|---|
| wordmark | constant `RESIDUUM` (brand, not a fact) |
| depth | `state.depth` / `state.deepest`, omitted when `state.isEncounter` |
| place | encounter `The Road`; else `residuumWorld.nodeAt(bloc.dungeon!).name` |
| day | `bloc.day` (new run constant; `_world.state.world.day` in `main.dart`); omitted when null |
| battle chip | `state.isBattleOpen` → `Engaged ${state.enemiesInSight}`; `enemiesInSight > 0` → `Watched N`; else none |
| condition chip | existing `_condition(hero.hp / state.maxHp)` |
| ward chip | `state.warded > 0` → `Ward ${state.warded}` |
| hero label | `bloc.heroLabel` (new run constant; `_saver.document.heroes[_saver.document.active]!.label`), upper-cased; empty when null |
| HP / Mana | `state.game.hero.hp.clamp(0, state.maxHp)` / `state.maxHp`; `state.mana` / `state.maxMana`, only when `state.knownSpells.isNotEmpty` |
| stats | `ATK ${state.attack.$1}–${state.attack.$2}`, `ARM ${state.armor}`, `GOLD ${state.game.gold}` |
| weapon | `state.game.loadout.weapon?.displayName ?? 'Bare fists'` |
| armour | `state.game.equipment[EquipSlot.chest]?.displayName ?? 'None'` |
| quick | `Potion ×${state.potionCount}` |
| pack | `${state.game.inventory.length}/$inventoryCap` |
| target | `state.targetActor` (new: `inspectedActor ?? selectedActor ?? (isBattleOpen ? nearest known visible by chebyshev, ties byRowThenColumn : null)`); name `presentationOf(id).displayName` with first letter capitalised; `HP ${m.hp}/${m.maxHp}`; line A `ATK a–b  SPD s`; line B `Reach r` or `Adjacent`, then `· Resists <word>` / `· Burns at <word>` per type |
| damage | armed spell with `kind == SpellKind.bolt` → `${spell.min}–${spell.max}` + `spell`; else `state.attack` + `melee` |
| spell | armed spell (`armedSpellId`) else `state.knownSpells.take(readiedSpellCount).firstOrNull`; name; `Mana Cost ${manaCost}`; effect: bolt `${type.word} bolt ${min}–${max}`, mend `Heals ${min}`, ward `Ward holds ${min}`, bind `Binds ${min} turns`, banish `Banishes the target`; tags `[type?.word capitalised, school.schoolWord, bolt/bind/banish ? 'Targeted' : 'Self']` joined ` | `; none known → `No spell known` (`textLineDim`) |
| timeline | `state.activationQueue` (unchanged); glyph `presentation.glyphLabel` / `@`; word `presentation.displayName` / `You` |
| log | `state.log` sentences and categories; count `${state.log.length} entries` |
| callout | `state.inspectedActor` facts as the target lines |

Mock content that stays out (contract list) is not rendered anywhere:
`Torch`, `Hungry`, `Clear`, `Seed`, `Auto-walk`, `Help`, `Inspect` button,
menu/settings buttons, clock timestamps, turn numbers, to-hit %, flavour text
(content has none), doors, water, dotted range path.

## 3. Task graph

Sequential, one fresh `flow-plan-executor` per brief, non-isolated on this
branch, one local Conventional Commit per accepted task.

```
01 mono-type-role
 → 02 dense-glyph-grid
 → 03 stone-light-values
 → 04 atmosphere
 ══ CHECKPOINT A (Main): device capture of exploration vs art bible +
    exploration mock; architect verdict on track / correct before chrome ══
 → 05 touch-resolution
 → 06 action-bar            (also lands the final GameScreen skeleton)
 → 07 recent-events
 → 08 hero-panel            (GameBloc.heroLabel)
 → 09 combat-panel          (GameViewState.targetActor)
 → 10 crawl-header          (GameBloc.day; CrawlStatus retired)
 → 11 activation-timeline   (owns the final crawl_layout_test proofs)
 → 12 map-callout           (inspect state; callout replaces map-originated sheet)
 → 13 direction-docs
 → Main: ledger/RESUME, full gates, acceptance review, final device gate,
         reviewer parity scoring, user sign-off, uninstall + absence proof
```

Why this order: fonts before any consumer; geometry and renderer are one
atomic change (positions and hit-test share the cell constants); inks, then
atmosphere each have separate pixel/unit proof; the checkpoint sees mono
glyphs on 13 × 16 cells with light, falloff, fog, vignette and parallax
before any chrome time is spent. Chrome tasks run bottom-up (bar, log, panels)
so intermediate battle states never starve the map below the height the
existing 7 × 5 tap fixtures (80 dp of rows) need at the 800 × 600 default
surface (≥ 100 dp at every handoff; lowest is ≈108 dp after Task 10, before
the 58 dp timeline replaces the U16 dock). Docs that executors read (AGENTS Type rule) change in
Task 01; the CI gate tightens in Task 02 once the last non-token
`fontFamily:` leaves `dungeon_scene.dart`; historical design docs change last
so they describe the landed state.

## 4. Checkpoint A (Main, after Task 04 is accepted)

1. Write/refresh the recovery checkpoint under `.flow/checkpoints/<head>.md`
   and record it in the ledger (contract item 14). The phone holds the U16
   test install and its test saves; U16.5 may install over it.
2. `flutter build apk --debug` (or the U16 install path) from
   `packages/app`; install over the U16 package on the vivo I2219 only
   (serial from the ignored checkpoint; no AVD).
3. Record `WindowInsets` from logcat; if top/bottom differ from 37.8/24.0 dp,
   update the §2 G8 safe-height figure and `test/support/phone.dart::onTheTargetPhone`
   padding in the next chrome task's brief before dispatch.
4. Capture exploration at a room with visible, remembered and unknown cells,
   one pan and one recenter. Compare with the art bible (sections 2, 4, 5, 6)
   and the exploration mock. Judge: ≈30 mono columns, warm stone, visible pool,
   falloff to dim, remembered clearly dimmer, void unknown, visible fog and
   vignette, parallax on pan, glyph proportion/legibility.
5. Verdict in the ledger: **on track** → dispatch Task 05; **off track** →
   a scoped correction task against Tasks 02–04 (constants in G1/G4/G5 are
   the tuning surface) with fresh proof, then re-capture.

## 5. Verification ownership and final gates

Executors: first failing behavioural proof (record the Red), implement, then
from `packages/app`: `dart format <touched Dart files>`,
`flutter test <owned test files>`, `flutter analyze`. Main does not replace
that; Main verifies additively.

Main, once, on the final tree, from `packages/app`:
```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```
plus the CI type gate block from `.github/workflows/ci.yml` run locally, and
`git diff --stat 2c073b7 -- packages/core packages/content` (must be empty).
Main updates the ledger locked-contract section and RESUME (contract scope
item 5, supersession appended, history not rewritten), runs one independent
acceptance review against this plan and the contract, then the final device
gate: captures for exploration, battle with timeline, armed targeting,
callout, log peek, expanded log, road encounter and densest action state
(>5 actions with peek); each beside its mock, scored by an independent
reviewer with §6, then shown to the user for sign-off. After sign-off,
uninstall `com.example.residuum_app` and verify absence (`pm path` empty),
returning the phone to its pre-U16 state. Any production change after
acceptance reopens scoped acceptance and affected device evidence.

Acceptance criteria → proof:

| AC | proof |
|---|---|
| 1 map look | T02 (columns, mono), T03 (inks/falloff/remembered), T04 (pool), CP-A + final device |
| 2 no unknown leak | T03 plan tests, T04 pixel invariance under unknown-topology change, T09 reticle/target visible-only, T12 callout visible-only |
| 3 fog/vignette/parallax | T04 pixel tests (variation, drift bounded, reduced motion, projection/hit unchanged) + device |
| 4 input | T05 unit + widget tests (radius edge, ties, guard, nothing), existing interaction tests migrated in T02/T05 |
| 5 composition | T06–T11 region tests; T11 final order/height test; final device + §6 |
| 6 map floors / fixed chrome | T11 `crawl_layout_test` at the target surface (45 %/35 %, armed = unarmed, 1 vs 12 actions identical) |
| 7 reachability | T06 (scroll reaches last slot, peek visible, ids/dispatch unchanged) |
| 8 log | T07 (4 unclipped lines, pictogram/tint per category, follow/unread/order) |
| 9 no mock-only facts | T06–T12 negative finds; §6 reviewer |
| 10 docs + CI | T01 (AGENTS), T02 (CI), T13 (spec, VISUAL-SYSTEM), Main (ledger, RESUME) |
| 11 gates | executors per task; Main final |
| 12 early checkpoint | §4 |
| 13 final visual gate | §5 + §6 + user sign-off |
| 14 device state | §4 step 1, §5 uninstall |

## 6. Parity scoring checklist (independent reviewer, per capture vs its mock)

Score each line PASS / FAIL with a one-line reason; any FAIL in A–D blocks.

A. Regions and order — exploration: wordmark+rule, meta, chips, map, hero
panel (3 columns), recent events (4 lines), 5-slot bar. Battle: + timeline
between chips and map, combat panel (3 columns) instead of hero panel.
Expanded log: sheet over the lower map, bar visible.
B. Proportions — measure each framed region on the capture in dp; each within
±20 % of the mock share in §2 G8 (header wordmark-cap→chip-bottom; timeline
label-top→pill-bottom; panels and bar by frame; map by chips-bottom→panel-top).
C. Type roles — display serif for wordmark, section titles, labels, names;
Spectral for slot labels and notes; mono for map, meta, chips, numbers, item
names, log sentences, timeline tokens. No map glyph in a proportional face.
D. Palette — warm stone terrain in every region (road included), enemy red
monsters, ivory hero, cold items/mana, gold titles/marks, near-black field,
no red-vs-green pair, category also by pictogram/shape/word.
E. Light and darkness — pool around `@`, bloom, falloff to dim at FOV edge,
remembered clearly dimmer, void for unknown, visible fog, darker edges,
parallax on pan (off with animations removed).
F. Targeting — thin corner ticks on legal targets, heavy `[ ]` on the target,
callout with leader line in exploration, armed slot cold glow + `— armed`.
G. Facts — nothing from the contract's stay-out list; every value on screen
traceable through §2 G11.
Known, accepted deltas (do not score as FAIL): 13 × 16 cell (mock ≈ 10 × 12);
no timestamps; `N entries` instead of `N new` at peek; `HERO`/roster label
instead of `WANDERER` when unnamed; YOU vitals in place of TO HIT; empty
filler frames when fewer than five actions.

## 7. Escalations and residual decisions for Main

- **E1 (contract text vs core):** contract §3 says the near-hero step goes in
  the tap's 8-way direction; core `Direction` is 4-way and `core` is
  protected. Resolved to the dominant axis (G7 rule 4). Needs Main
  acknowledgement, not a contract change in substance.
- **E2 (precedence refinement):** G7 adds "cell under the finger holds a
  monster wins" and the adjacent step-cell guard ahead of the 22 dp monster
  rule, otherwise "tap the next cell to step toward a monster two cells away"
  would inspect instead — breaking an existing behaviour the contract keeps.
- **E3:** the bloc forces `logUnread == 0` at peek, so the only truthful
  count on the peek is `N entries`.
- **E4:** hero name and world day are app state, not crawl state; plumbed as
  `GameBloc` run constants from `main.dart` (no core change). If a
  `WorldBloc` event can change `world.day` while a crawl lives, Task 10
  escalates and the day is dropped.
- **E5:** hero HP/mana stay visible in battle in the combat panel's middle
  column (in place of the removed TO HIT), keeping the existing tested fact.
- **E6:** text scale ≤ 1.3 grows fixed chrome proportionally; floors are
  asserted at 1.0.
- Residual evidence risks: device inset figures (CP-A), Plex rendering on
  device at 10.5 dp log size, fog performance during drag (picture cache
  planned), font-fallback of school markings in Spectral slot labels
  (pre-existing), no hardware fingertip test of the 22 dp radius (synthetic
  taps only).

## Plan quality gate

- **COR — PASS.** One projection authority (G1) used by renderer,
  atmosphere and input; knowledge secrecy held by construction (atmosphere
  inputs exclude topology; plan, reticles, target, callout read only
  visible+known actors) and proven negatively; fixed chrome makes map rect
  independent of actions/arming/log/callout; bloc reset-by-construction
  carries the callout dismissal; action ids, dispatch, `readiedSpellCount`,
  timeline schedule, log semantics and core untouched. Contract/core
  contradiction (E1) and precedence gap (E2) resolved explicitly.
- **TTC — PASS.** Every task names its first failing proof and expected Red;
  radius edges (21.9/22.1 dp), ties, guard, nothing-resolution, reduced
  motion, drift bound, unknown-topology invariance, 1 vs 12 action layout
  identity, armed = unarmed map rect, four unclipped lines, per-category
  pictogram/tint, glyph coverage and role invariants all have named tests;
  device-only claims are Main's CP-A/final gate.
- **CRF — PASS.** Retires `_fitFor`, `cameraCellSize`, `GridGeometry.fit`,
  `DungeonDepthPainter`, glyph halo, `LogCategory.mark`, `CrawlStatus`,
  per-region terrain inks and the 104 dp peek instead of shimming; one
  `ActionMark` seam, one resolver, one atmosphere widget; fog cached as a
  picture, no per-cell or per-frame allocation added; each brief is one
  independently provable slice (geometry+renderer kept atomic because cell
  constants drive both).
- **SEC — SKIP (no new trust boundary).** Offline presentation; the only
  security-like boundary is hidden-map knowledge, handled under COR/TTC.
  Font download is pinned by SHA-256.
- Residual risks deliberately left to implementation/device evidence: §7.
