# Unit 13 — visual parity matrix

One row per frame area. Gap IDs refer to `PARITY-AUDIT.md`. Evidence is in
`.flow/evidence/visual-reboot/unit-13-parity/`.

| Frame | Area | Mock establishes | Current state | Gap | Ownership | Required decision / asset / code | Evidence | Future unit |
|---|---|---|---|---|---|---|---|---|
| 1 Stonebridge | Header | Full-bleed painting, title + subtitle under art, gear over art, no back | 140 dp inset strip mid-list, `AppBar` + back, title above status block | 1.1, 1.6 | CODE | Illustration header component; root screens lose the back arrow | `pair-01-town` | U17 |
| 1 | Type | Display roman caps, serif body | monospace 20/5 and 14 | 1.2 | CODE + ASSET | Font family; type roles | `pair-01-town` | U14 |
| 1 | Rows | Medallion + serif title + purpose + chevron + hairline | Text-only `TextButton`, `Divider(rule)` | 1.3, 1.4, 1.8 | CODE + ASSET | Shared framed row; 5 town medallions | `pair-01-town` | U15, U16 |
| 1 | Content | No numbers on the town screen | Health/Carried/Banked + MATERIALS block | 1.5 | CODE | Move the numeric block off the title region | `pair-01-town` | U17 |
| 1 | Doors | Five doors | Seven real destinations | 1.7 | INTENTIONAL DEVIATION | Keep all seven; adopt the row form | `pair-01-town` | U15 |
| 2 Exploration | Stone value | Dark stone, wall mass by value + texture | Bright floor slab on black, wall indistinguishable from void | 2.1, 2.4 | CODE | Palette/treatment rework; raise authored-texture presence | `pair-02-explore`, `-grey` | U18 |
| 2 | Light | Torch in a niche with a real pool; fog closes the lit edge | One hero-centred radial gradient, hard black boundary | 2.2, 2.3 | CODE | Placed light sources; edge falloff | `pair-02-explore` | U18 |
| 2 | Structure | Stair prop, debris scatter, wall niche | `<`/`>` glyph, no props | 2.5 | CODE + ASSET | Terrain kinds + prop art per biome | `pair-02-explore` | U19 |
| 2 | Actors | Drawn creature with a letter label | Gold letter only | 2.6 | CODE + ASSET | Creature art + label retention | `pair-02-explore` | U20 |
| 2 | Status | Two labelled meters always present, hue fill + number | HP bar + condition word; mana absent outside battle | 2.7, 2.8 | CODE | Meter pair component; hue as reinforcement | `pair-02-explore` | U14, U21 |
| 2 | Log peek | Three prose lines filling the panel | 104 dp box, one line, dead space, prose also outside | 2.9 | CODE | Peek sizing and single prose home | `pair-02-explore` | U21 |
| 2 | Shelf | One row of equal icon-over-label chips | Two wrapped rows, counts inline, most chips iconless | 2.10, 2.11 | CODE + ASSET | Chip geometry + full verb icon set | `pair-02-explore` | U15, U16 |
| 2 | Map density | ~14 rows at ~36 dp cells | 36 dp fixed cell, comparable rows | 2.13 | ALREADY ACCEPTABLE | none | `pair-02-explore` | — |
| 3 Combat | Timeline | Short serif word per token, borderless band, hotter token for the dangerous actor | `the giant rat¹` shrunk to fit, bordered panel, uniform tokens | 3.1, 3.2, 3.3 | CODE | Short display name; band framing; token weight ladder | `pair-03-combat` | U21 |
| 3 | Actors | Creature art, letter as label, plate behind the dangerous one | Gold letters | 3.4 | CODE + ASSET | Creature art | `pair-03-combat` | U20 |
| 3 | Shelf | Five chips, one row, `+3` overflow | Seven chips, two rows, cost in label, `…`/`+1` overflow | 3.5, 3.6 | CODE | Cost placement; overflow chip form | `pair-03-combat` | U15 |
| 4 Targeting | Target marks | Corner-bracket reticle on the target, filled cells elsewhere | 1 dp hairline square on each legal target | 4.1 | CODE | Reticle + cell marking language | `pair-04-targeting`, `-grey` | U21 |
| 4 | Armed chip | Lit border, no caption | 2 dp border + `— armed` caption | 4.2 | CODE | Armed skin | `pair-04-targeting` | U15 |
| 4 | Range cells | Three cells between hero and target | No range or path feedback exists | 4.3 | INTENTIONAL DEVIATION | Settled 2026-09-18: a mock flourish; the map marks the legal targets and nothing else | `pair-04-targeting` | — |
| 5 Expanded log | Marks | Authored pictogram, no container | Text glyph in a bordered 20 dp well | 5.1 | CODE + ASSET | Ten category pictograms | `pair-05-log` | U16 |
| 5 | Rhythm | ~60 px rows, wrapped lines indented to the text column | 3 dp rhythm, wraps return to the mark column | 5.2 | CODE | Row rhythm and wrap indent | `pair-05-log` | U21 |
| 5 | Sheet | Stops below the status row | Covers the screen at `heightFactor` 1.0 | 5.3 | CODE | Full extent stops under status | `pair-05-log` | U21 |
| 5 | Type | Serif sentences | monospace 13 | 5.4 | CODE + ASSET | Font family | `pair-05-log` | U14 |
| 6 Character | Navigation | Framed rows, medallion, chevron | Four default-lavender M3 `FilledButton`s | 6.1, 6.6 | CODE + ASSET | Town-side theme + framed row + 4 medallions | `pair-06-character` | U14, U15, U16 |
| 6 | Identity | Framed painted portrait, name at display size, level, epithet | Nothing names the hero | 6.2, 6.3 | CODE + ASSET | Portrait art + identity block | `pair-06-character` | U17 |
| 6 | Meters | HP/Mana pair under the portrait | Health/Mana as text inside a stat panel | 6.4 | CODE | Shared meter pair | `pair-06-character` | U14 |
| 6 | Attributes | Label left, value right, hairline rows | Fenced monospace panel | 6.5 | CODE | Attribute row | `pair-06-character` | U15 |
| 6 | Vocabulary | Strength/Dexterity/Will/Lore, `Equipment`, `Progress` | Attack/Armour/Dodge/Speed, `Gear`, `Skills`, `Pack` | 6.7, 6.8 | INTENTIONAL DEVIATION | Keep the game's words | `pair-06-character` | — |
| 7 Spells | Rows | Inset framed row, medallion, chevron | Unframed, glyph, no chevron | 7.1, 7.2, 7.3 | CODE + ASSET | Framed row + one medallion per spell | `pair-07-spells` | U15, U16 |
| 7 | Locked | `Locked Spells` section + padlock row | No locked section | 7.4 | CODE | Locked section and row skin | `pair-07-spells` | U15 |
| 7 | Copy | Flavour description | School · mana · damage · marking | 7.6 | INTENTIONAL DEVIATION | Mechanical line stays | `pair-07-spells` | — |
| 8 Pack | Filters | Custom chips, selected by fill + border | Stock `ChoiceChip` with M3 fill and checkmark | 8.1 | CODE | Own filter chip | `pair-08-pack` | U15 |
| 8 | Item art | Per-item painted art in a square medallion | None; rarity glyph only | 8.2 | CODE + ASSET | Item art family | `pair-08-pack` | U16 |
| 8 | Rows | Framed row, serif title with `× 2`, chevron | Unframed, monospace, buttons stacked below | 8.3, 8.5, 8.6 | CODE | Framed row + quantity in title + action affordance | `pair-08-pack` | U15 |
| 8 | Empty state | Absent categories simply do not appear | Five headings each with a prose apology | 8.4 | CODE | Hide empty sections in the `All` view | `pair-08-pack` | U15 |
| 9 Forge | Header | Full-bleed art + serif tagline | 120 dp strip, no tagline | 9.1, 9.2 | CODE | Illustration header | `pair-09-forge` | U17 |
| 9 | Actions | Three framed doors with medallions | Inline console + lavender primary button | 9.3, 9.4 | CODE + ASSET | Door-and-room split; 3 medallions | `pair-09-forge` | U15, U16 |
| 9 | Composition | Room is a menu; work happens behind a door | Room is one long console | 9.7 | CODE | Accept the mock's split | `pair-09-forge` | U15 |
| 10 Tavern | Header | Full-bleed art + tagline over its lower edge | 120 dp strip, no tagline | 10.1, 10.2 | CODE | Illustration header | `pair-10-tavern` | U17 |
| 10 | Actions | `Rest`/`Listen`/`Leave` framed rows with medallions | `Ask 15` lavender pill, `[!]` literal mark | 10.3, 10.5, 10.6 | CODE + ASSET | Framed row + medallions | `pair-10-tavern` | U15, U16 |
| 10 | Row set | Rest and Leave present | Rest lives at the Inn; Leave is the back arrow | 10.4 | INTENTIONAL DEVIATION | Keep the game's structure | `pair-10-tavern` | — |

## Cross-cutting decisions

| System concern | Evidence across frames | Current rule | Settled rule | Status |
|---|---|---|---|---|
| Typography | every frame | `fontFamily: 'monospace'` only, in two duplicate seams | Three roles: a display roman for titles/captions, a serif text face for names and prose, monospace retained **only** for numeric and mechanical columns | settled, pending font choice |
| Colour / value | 2, 3, 4, 6 | one ink, one dim, four surface values, no hue anywhere | Hue permitted as **redundant reinforcement** on resources and target marks; never the sole carrier; no red-versus-green pair anywhere | settled |
| Frames / surfaces | 1, 6, 7, 8, 9, 10 | `Divider(rule)` separation; two flat panel fills | Inset framed row is the default list unit: panel fill, 1 dp rule border, 6 dp radius | settled |
| Ornament | all | none | None beyond hairlines and medallion rings. The mock has no ornament either; it reads rich because of art and type, not decoration | settled |
| Action controls | 1, 2, 3, 4, 6, 8, 9, 10 | crawl has its own chip; town inherits bare M3 and leaks lavender | One control family for both seams; no stock `FilledButton`, `TextButton` or `ChoiceChip` renders unthemed anywhere | settled |
| List rows | 1, 6, 7, 8, 9, 10 | nine bespoke row anatomies | One row: medallion slot, title, purpose/detail, trailing affordance, hairline | settled |
| Icons | 1, 2, 3, 5, 6, 7, 8, 9, 10 | 8 authored icons; everything else a text glyph | Authored families: verb icons, room/door medallions, spell medallions, item art, log pictograms | settled, asset work scoped in U16 |
| Dungeon structural assets | 2, 3, 4 | 18 tiles across 3 biomes; no props, no doors, no stair art | Expand to a structural kit: stair art, door kind, per-biome prop family, placed light sources | settled |
| Actor representation | 2, 3, 4 | monospace glyph, gold ink, superscript ordinal | Creature art carries identity; the letter label and ordinal **stay** as the accessible identity | settled |
| Screen composition | 1, 6, 9, 10 | illustration as a 120–140 dp mid-list strip | Illustration is a full-bleed header with the title set on or under it | settled |
| Range / path feedback | 4 | none | None. The mock's three cells are a flourish; no mechanic is implied and none will be built | settled 2026-09-18 |
| Unframed screens | world, roster, merchant, bank, inn, alchemist, gear, skills | bespoke | Inherit the vocabulary; no new frames commissioned. The world map and the roster additionally get a device shot in their owning unit, colour and greyscale | settled 2026-09-18 |

## Roadmap derivation

| Proposed unit | Mock frames | Gaps closed | Asset work | Code work | Locked semantics | Evidence gate |
|---|---|---|---|---|---|---|
| U14 Type, palette and surface authority | all ten | 1.2, 2.8, 5.4, 6.4, 7.5, 9.5, 10.7 | font files (2 faces) | one shared token module; a town/world sibling theme; meter pair; type roles | no `MaterialApp`-wide restyle; greyscale legibility; no hue-only state | every screen re-shot, colour + greyscale |
| U15 Row, control and chip grammar | 1, 2, 3, 4, 6, 7, 8, 9, 10 | 1.3–1.4, 1.7, 3.5–3.6, 4.2, 6.1, 6.5–6.6, 7.1–7.4, 8.1, 8.3–8.6, 9.3–9.4, 9.7, 10.3, 10.5 | none | framed row, filter chip, action chip geometry, locked section, Forge door split | action vocabulary and counts; melee map-first; four-region rule | chip ceiling at worst legal density; every list screen |
| U16 Authored icon and art families | 1, 5, 6, 7, 8, 9, 10 | 1.3, 2.11, 5.1, 6.6, 7.2, 8.2, 10.6 | ~40 icons: verbs, door medallions, spell medallions, item art, 10 log pictograms | widen the asset enums; item and spell icon resolution | art bible tone and greyscale rules; untinted multitone masters | icon sheet + each consuming screen, colour + greyscale |
| U17 Illustration headers and hero portrait | 1, 6, 9, 10 | 1.1, 1.5, 1.6, 6.2, 6.3, 9.1, 9.2, 10.1, 10.2 | hero portrait; optional art for unillustrated rooms | header component; identity block; status block relocation | save compatibility; room vocabulary | four screens, colour + greyscale |
| U18 Dungeon light and stone value | 2, 3, 4 | 2.1, 2.2, 2.3, 2.4 | none | palette and treatment rework; placed light sources; edge falloff | determinism; fixed 36 dp cell; no gameplay RNG for decoration | same seed before/after, three biomes, colour + greyscale |
| U19 Dungeon structure and props | 2, 3 | 2.5 | stair art, door art, per-biome prop family | terrain kinds; prop placement, deterministic | determinism; engine authority; save compatibility | three biomes at one seed, colour + greyscale |
| U20 Actor representation | 2, 3, 4 | 2.6, 3.4 | creature art per monster family | sprite layer under the existing glyph label | hidden-actor secrecy; ordinal identity; greyscale legibility | a crowded floor, colour + greyscale |
| U21 Combat chrome density | 2, 3, 4, 5 | 2.7, 2.9, 3.1–3.3, 4.1, 5.2, 5.3 | none | short display names; timeline band; peek sizing; log rhythm; sheet extent; reticle | timeline = time, log = causality; activation repetition | worst legal density, dp budget re-measured |
| U13.1 Map bleed (defect) | 2, 3 | carried debt | none | root-cause diagnosis of the Flame viewport exceeding its box | 7.93-rows-of-sight figure must survive the fix | the Unit 12.5 ceiling scene reproduced clean |
| Save-read candidate (defect, non-visual) | — | carried debt | none | reproduce `decodeSave` refusal of a post-death autosave | save compatibility | a failing reproduction, then a passing one |
