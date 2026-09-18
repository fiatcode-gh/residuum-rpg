# Unit 13 — the visual system contract

What the remaining visual-reboot units build against. Every rule here is
derived from the approved mock and from what the source actually is
(`recon.md`), not from taste.

## 1. Typography

The monospace-only identity is **superseded**. It was a legitimate early
choice — it gave the roguelike a terminal honesty — but the approved mock
does not use it for anything except numbers, and every frame in the audit
pays for that gap twice: the type is wrong and the density is wrong, because
monospace at a legible size eats horizontal room that serif does not.

Three roles:

| Role | Used for | Mock evidence |
|---|---|---|
| **Display** | place names, screen titles, taglines, section captions — letterspaced roman capitals | `STONEBRIDGE`, `THE FORGE`, `CHARACTER`, `COMBAT LOG`, `GOOD COMPANY LASTS LONGER.` |
| **Text** | row titles, purposes, prose, log sentences, chip labels — a serif with a tall x-height and real small sizes | `Leave Town` / `Venture into the depths.`, every log line, every item and spell row |
| **Mechanical** | numbers, meters, ordinals, stat columns, seeds, prices — monospace, retained deliberately so columns align | `14/20`, `3 / 5`, `Strength 8`, `r¹` |

Font assets are therefore **required**, and two faces is the whole budget. A
libre face is preferred over a commissioned one: this is an unbudgeted
personal project and a libre serif with a matching caps treatment gets the
whole way there. The candidates in the mock's register were:

- **EB Garamond** — closest to the mock's letterforms; a true old-style serif
  with real small caps, and its caps letterspace well. Heaviest at small
  sizes on a phone.
- **Spectral** — designed for screens, holds up at 12–13 px far better, less
  antique in the caps.
- **Cormorant** — the most decorative and the most fragile; beautiful titles,
  poor body.

**Settled 2026-09-18 by the user: Spectral for text, EB Garamond for
display.** Every density failure in the audit lives at 12–13 px, which is
where a decorative face breaks; Spectral holds that size and EB Garamond's
letterspaced caps carry the display register.

Monospace stays for the mechanical role, so no glyph coverage is lost for
ordinals and marks.

## 2. Colour and value

The lock stands in its true form: **no important state may depend on hue
alone, and every screen must read in greyscale.** What was over-read from it
is the conclusion that the app must be monochrome. The mock is not
monochrome, and it still passes: `pair-04-targeting-grey.png` shows the
mock's blue range cells and red target reticle staying completely
distinguishable in greyscale, because one is a filled rounded square and the
other is four corner marks. The HP and Mana meters carry a hue **and** a
number **and** a label.

Rules:

- Hue is reinforcement, never the carrier. Remove the colour and the meaning
  must survive: by shape, position, marking, value or a word.
- **No red-versus-green pair anywhere**, for any state distinction. The
  author is deuteranomalous; the mock's own palette is amber/warm against
  cold blue, which is safe.
- The value ladder stays as it is (`#0E1014` void, `#11141A` recessed,
  `#15181F` panel, `#1B1F27` raised, `#2A2E38` rule, `#8A919E` dim,
  `#E6EAF0` ink). It matches the mock; it is not what is wrong.
- Permitted hue accents, from the mock: warm amber for light, fire and gold;
  cold blue for mana, frost and range marking; a hot red for mortal danger
  and the armed target reticle. Nothing else.
- Every unit's evidence gate includes a greyscale render. That is already how
  this epic works and it does not change.

## 3. Surfaces, framing and ornament

- The **inset framed row** is the default list unit: panel fill `#15181F`,
  1 dp `#2A2E38` border, 6 dp radius, and a hairline between rows where the
  mock draws one.
- The **medallion** is a circular or square well with a hairline ring holding
  authored art, at the row's leading edge, with a fixed column width so rows
  never step sideways.
- Panels carry no elevation, no shadow, no gradient. The mock has none.
- **Ornament is prohibited.** The mock reads rich because of painted art and
  type, not because of corner flourishes. Anyone reaching for a decorative
  border has misread the target.
- Screen headers are **full-bleed illustration** with the title set on or
  directly under the art, not an inset strip inside a scrolling list.

## 4. Control state grammar

One family for both seams. States and their non-hue cues, carried forward
from the crawl because it already got this right:

| State | Fill | Border | Label | Icon |
|---|---|---|---|---|
| available | raised | 1 dp rule | normal weight | full opacity |
| armed / selected | armed fill | 2 dp ink | heavier weight | full opacity |
| disabled | recessed | 1 dp disabled rule | lighter weight | 0.45 opacity |

No stock `FilledButton`, `TextButton`, `ChoiceChip` or `Chip` may render
unthemed on any screen. The lavender in frames 6, 8, 9 and 10 is the
absence of a town-side theme, not a choice, and it is the cheapest large
visual win in the epic.

## 5. Asset authority

New authored assets are **permitted and necessary**. The audit names the
families; nothing outside them is pre-authorized.

| Family | Count | Consumers |
|---|---|---|
| Verb icons | ~12 beyond the current 8: gather, pick up, finish, flee, listen, rest, ask, smelt, upgrade, craft, temper, read | action shelf, room doors |
| Room / door medallions | ~11: leave town, forge, tavern, inn, merchant, bank, character, pack, spells, skills, gear | town and room screens |
| Spell medallions | one per spell in `packages/content` | spells screen, action shelf |
| Item art | one per item family (potion, weapon, armour, book, material, torch) with rarity carried by marking, **not** by a separate painting | pack, merchant, bank, forge, gear |
| Log pictograms | 10, one per `LogCategory` | expanded log, log peek |
| Hero portrait | 1 per playable archetype, framed square | character screen, roster |
| Dungeon structure | stair art, door art, per-biome prop family (3 biomes × ~4 props), placed light-source art | dungeon renderer |
| Creature art | one per monster family in `packages/content` | dungeon renderer |

Pipeline rules from `unit-2/ART-BIBLE.md` are unchanged and binding: authored
masters are multitone and untinted; `assets/visual/<family>/`;
`{subject}_{variant}.png`; cold charcoal stone against warm amber light; ~30%
stylized realism; greyscale legibility proved per asset; decoration placement
deterministic from coordinate and theme salt, never gameplay `Rng`.

## 6. Composition freedom

Layout proportion, placement, row density, illustration integration, frame
treatment and control geometry are all **open** and may be rebuilt where the
mock requires it. Two specific consequences the audit found:

- The town screen's numeric status block does not belong in the title region.
- The Forge (and any room with a console) becomes a **menu of doors** with the
  mechanical work behind them, as the mock shows. This costs one level of
  navigation depth and is the approved frame's shape.

## 7. Locks that parity may not reopen

Behaviour and accessibility, unchanged:

- engine authority and determinism; no unseeded `Random()` in `core` or
  `content`; same seed, same floor, same rolls;
- save compatibility, unless a separate approved defect unit changes it;
- the four-region rule: map = space and targets, timeline = time, log =
  causality, action shelf = verbs, no concern duplicated; combat has one
  action row;
- melee is map-first; a targeted spell is `arm → map target → tap`;
- circle means selection, square means targeting — shape, never hue;
- activation repetition and hidden-actor secrecy;
- authoritative action vocabulary and counts; `readiedSpellCount` is 3, so
  eleven chips is the true row ceiling and `Flee` never appears in a crawl;
- the game's own words win over the mock's caption text: `Gear` not
  `Equipment`, the real attribute set, the real door set;
- no important state by hue alone; every screen reads in greyscale;
- `cameraCellSize` stays fixed at 36 dp — fitting it shrank cells to ~12 dp
  on the deepest floor and a tap that must be aimed is not a tap;
- the map is `Expanded`: chrome is paid for in map height, and the measured
  dp budget (exploration 331.1, typical combat 438.1, worst legal 580.95
  against a 600 ceiling) is the real constraint on every chrome change.

## 8. Superseded

- **Monospace-only identity** — superseded by section 1.
- **Colour avoidance** — superseded by section 2. The lock was never "avoid
  colour".
- **Material-derived geometry and stock controls** — superseded by section 4.
- **Compositions are near-fixed** — superseded by section 6.
- **Authored assets are a late optional possibility** — superseded by
  section 5.
- **Unit 12.5 AC17's conclusion**, that dungeon viewport output is not a
  dominant remaining parity gap and that framing dominates — superseded.
  The full ten-frame evidence shows two dominant gap families of comparable
  size: the dungeon's material/light/structure/actor rendering (frames 2–4)
  and the application-wide type/surface/control/art absence (frames 1, 5–10).
  Neither dominates the other. The ordering in `ROADMAP.md` is by dependency
  and cost, not by dominance.
- **"Never an application-wide design system"** — **superseded 2026-09-18 by
  the user.** The carry-forward lock was written when the epic's scope was
  the crawl seam, and it forbade a global `MaterialApp` theme change for a
  good reason: an implicit global restyle would have dragged every unaudited
  screen with it. The epic's scope is now all ten frames, and the two seams
  already duplicate the same four colours with no shared source. The
  approved shape is **one shared token module plus sibling per-screen
  themes** — exactly the shape `crawlTheme` already has, extended so the
  town and world screens have one too. The lock's intent survives verbatim:
  nothing is restyled implicitly, and every screen root opts in. A
  `MaterialApp`-wide `ThemeData` that restyles stock Material controls
  application-wide remains prohibited.

## 9. Settled by the user, 2026-09-18

- **Fonts**: Spectral text, EB Garamond display. Section 1.
- **Shared token module plus sibling themes**: approved. Section 8.
- **Frame 4's three intermediate cells are a mock flourish.** No range or
  path feedback is implied and none will be built. The map marks the legal
  targets, as it does today. U21 rebuilds the reticle language without
  adding cells.
- **The world map and the roster inherit the vocabulary and gain an evidence
  gate.** They get no frame of their own, but each owning unit must capture a
  device shot of both, in colour and greyscale, so they stop being the only
  unevidenced surfaces in the epic.
- **Roadmap approved as ordered**, U13.1 first. See `ROADMAP.md`.
