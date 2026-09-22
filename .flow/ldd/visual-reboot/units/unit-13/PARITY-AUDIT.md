# Unit 13 — ten-frame parity audit

Mock: `.flow/evidence/visual-reboot/residuum_visual_reboot_approved_mock.png`,
SHA-256 `0dd2a752…094ed`, byte-identical to the bundle's
`reference/approved-visual-reboot-mock.png`. Ten frames, 2 rows of 5.

Current state: device shots from Unit 12.5 (`unit-12.5-device/`) for frames
1–8 and from Unit 10 (`unit-10-device/`) for frames 9–10, because Units 11 and
12 touched only the dungeon renderer and the crawl seam — no Forge or Tavern
production code changed between them, so the Unit 10 shots are still current
for those two screens.

Side-by-side and greyscale renders of every pair are in
`.flow/evidence/visual-reboot/unit-13-parity/` as `pair-NN-<name>.png` and
`pair-NN-<name>-grey.png`, with the isolated mock frames as `mock-NN-*.png`.

Ownership vocabulary: `CODE`, `ASSET`, `CODE + ASSET`,
`INTENTIONAL DEVIATION`, `ALREADY ACCEPTABLE`.

---

## 1 — Stonebridge (town)

Evidence: `pair-01-town.png` (mock | `u125-f-town-color.png`).

**The mock establishes.** A full-bleed environment painting filling the top
~45% of the frame, bleeding to the panel's own rounded edge with no inset and
no visible container; a gear affordance floating over the art, top right; no
back affordance at all, because the town is a root. Under the art, centred,
the place name in **letterspaced roman capitals at display size** and a
smaller all-caps subtitle, "A QUIET PLACE, FOR NOW." Then five action rows,
each: a circular authored icon medallion with a hairline ring, a serif title,
a serif dim purpose line, a right chevron, and a hairline separator between
rows. No numbers anywhere on the screen.

**The current app shows.** An `AppBar` with a stock back arrow; the place name
in monospace 20/5 and the subtitle in monospace dim; then a **numeric status
block** (Health 20/20, Carried 0 gold, Banked 0 gold), a `MATERIALS` heading,
and three material rows with text-glyph marks; then the Stonebridge painting
as a **140 dp inset strip in the middle of the list** with 8 dp padding and a
2 dp corner radius; then seven door rows — monospace title, monospace dim
purpose, `Divider(rule)` above each, no icon, no chevron.

**Material gaps.**

| # | Gap | Ownership |
|---|---|---|
| 1.1 | Illustration is a 140 dp mid-list strip, not a full-bleed header; title and subtitle do not sit on or under the art | CODE |
| 1.2 | Titles and body are monospace; mock is display roman + serif | CODE + ASSET |
| 1.3 | Rows carry no icon medallion | CODE + ASSET |
| 1.4 | Rows carry no trailing chevron, so no row reads as a door | CODE |
| 1.5 | Numeric status block and materials list occupy the mock's title region; the mock's town has no numbers | CODE |
| 1.6 | Gear affordance absent; back arrow present on a root screen | CODE |
| 1.7 | Seven doors against the mock's five (Merchant, Bank, Inn are real destinations the mock omits) | INTENTIONAL DEVIATION |
| 1.8 | Row separators are `Divider(rule)` hairlines, as the mock draws them | ALREADY ACCEPTABLE |

The painting itself is the mock's painting. The asset is not the gap; its
placement and scale are.

---

## 2 — Dungeon exploration

Evidence: `pair-02-explore.png` (mock | `u125-a-explore-color.png`).

**The mock establishes.** Place name and depth on one line. Two labelled
meters side by side — HP with a red fill and `14/20`, Mana with a blue fill
and `3/5` — in a dedicated band. Then a dungeon that is **dark**: black-brown
stone, a torch burning in a wall niche with a real pool of warm light around
it, wall masses that read as mass through texture and value, bone and rubble
scatter, an isometric staircase prop, and soft fog closing the edges of the
lit region. The hero is `@` in a small dark disc. Roughly 14 rows of map are
visible. Then a three-line prose panel with a chevron, and a shelf of exactly
three chips — authored icon over a serif label, hairline border, equal widths
filling the row.

**The current app shows.** A status line with `Watched 1` and a monochrome HP
bar plus the word `Wounded`; mana is not shown out of battle. The map is
**value-inverted against the mock**: a bright warm-grey floor slab on pure
black, faint tile texture, no torch, no light pool, no props, no visible wall
mass — unknown space and wall space are both black. A gold `W` marks a
monster. The log peek is a 104 dp bordered box holding one line with dead
space above it, and three centred dim lines sit outside it. Six action chips
wrap onto two rows with monospace labels carrying counts inline —
`Drink (2)`, `Pack (7)`, `Ascend <`, `Finish`.

**Material gaps.**

| # | Gap | Ownership |
|---|---|---|
| 2.1 | Lit floor sits far lighter than the mock's and the black void reads as equal to wall, so the room has no mass | CODE |
| 2.2 | No placed light source; one hero-centred radial gradient is the whole lighting model | CODE |
| 2.3 | No fog or vignette closing the lit region; the boundary is a hard black edge | CODE |
| 2.4 | Authored floor/wall texture is present but invisible at `authoredScale` 0.32 under `softLight` | CODE |
| 2.5 | No props: no debris scatter, no wall niche, no stair art (stairs are a `<`/`>` glyph) | CODE + ASSET |
| 2.6 | Monsters are a gold letter; the mock draws a creature with the letter as its label | CODE + ASSET |
| 2.7 | Mana is absent from the exploration status; the mock shows both meters always | CODE |
| 2.8 | Meters are monochrome with a condition word; the mock uses a hue fill plus the number | CODE |
| 2.9 | Log peek's fixed 104 dp leaves dead space, and prose sits both inside and outside the panel | CODE |
| 2.10 | Action shelf wraps to two rows with count suffixes in the label; the mock holds one row of equal chips | CODE |
| 2.11 | Chips have no icon for most verbs (only 8 icons exist) | ASSET |
| 2.12 | Hero `@` in a faint halo, mock has `@` in a disc | ALREADY ACCEPTABLE |
| 2.13 | 36 dp fixed cell, ~14 rows visible — matches the mock's density closely | ALREADY ACCEPTABLE |

---

## 3 — Combat (your turn)

Evidence: `pair-03-combat.png` (mock | `u125-b-combat-color.png`).

**The mock establishes.** The same status band, then a timeline band:
`NOW`/`NEXT` in letterspaced small caps, circular hairline tokens 44-ish dp
with the actor glyph inside, a short serif word under each (`You`, `Rat`,
`Rat`, `Ghoul`, `You`), `›` separators, and a trailing chevron. The ghoul's
token is drawn hotter than the rats'. The map holds two drawn rats and a drawn
ghoul, each with a red letter label (`r¹`, `r²`, `g¹`) beside it; the ghoul
carries a dark plate behind its label. Three prose lines, then five equal
chips: `Potion`, `Mend`, `Firebolt`, `+3`, `Wait`.

**The current app shows.** The structure is right — `NOW`/`NEXT`, circular
44 dp tokens, `›` separators, `@`/`r¹`/`r²` glyphs — inside a bordered
`CrawlPanel`. But each token's word is the **full lowercase name**,
`the giant rat¹`, shrunk by a `FittedBox` to fit 76 dp. The map shows two gold
`r` letters and nothing else; no creature, no plate, no label distinction. The
log peek is nearly empty. Seven chips wrap to two rows, with mana costs
appended to labels (`Firebolt 2`, `Frost Lance 4`, `Banish 4`).

**Material gaps.**

| # | Gap | Ownership |
|---|---|---|
| 3.1 | Timeline words are full sentences-worth of name, auto-shrunk; the mock uses a short display name | CODE |
| 3.2 | Timeline sits in a bordered panel; the mock's band is borderless with a hairline below | CODE |
| 3.3 | No value or weight distinction between hero, minor and dangerous tokens | CODE |
| 3.4 | Monsters on the map are letters, not creatures with letter labels | CODE + ASSET |
| 3.5 | Chips carry cost in the label and wrap to two rows against the mock's one | CODE |
| 3.6 | Overflow renders as `…` over `+1`; the mock's is a plain `+3` chip | CODE |
| 3.7 | `NOW`/`NEXT` captions, token size, separator glyph | ALREADY ACCEPTABLE |
| 3.8 | Superscript ordinals for same-type monsters | ALREADY ACCEPTABLE |

---

## 4 — Targeting (Firebolt armed)

Evidence: `pair-04-targeting.png`, `pair-04-targeting-grey.png`.

**The mock establishes.** Three **rounded-square cells** drawn in blue along
the line between hero and ghoul, and the ghoul itself inside a **red
corner-bracket reticle**. The armed `Firebolt` chip has a blue border and a
blue glow. The prose reads "Firebolt ready. / Tap a target to cast. / (Long
press for details.)". In greyscale the blue cells and the red brackets remain
completely distinguishable: one is a filled rounded square, the other is four
corner marks.

**The current app shows.** Both rats get a thin gold square outline, 1 dp,
inset 1 dp. The armed chip gets a 2 dp `crawlInk` border, a heavier label and
the caption `— armed`. Prose is the three-line note above the shelf.

**Material gaps.**

| # | Gap | Ownership |
|---|---|---|
| 4.1 | Target marking is a hairline square; the mock uses a corner-bracket reticle on the chosen target and filled cells for the rest | CODE |
| 4.2 | Armed chip signals with border weight and the word `— armed`; the mock uses a lit border and no caption | CODE |
| 4.3 | The mock's three intermediate cells suggest range or path feedback the game does not implement | INTENTIONAL DEVIATION |
| 4.4 | Circle-for-selection vs square-for-targeting distinction survives greyscale in both | ALREADY ACCEPTABLE |

4.3 was put to the user rather than inferred from a picture. **Settled
2026-09-18: a mock flourish.** No range or path feedback is implied and none
will be built; the map marks the legal targets, as it does today. U21 rebuilds
the reticle language without adding cells.

---

## 5 — Expanded combat log

Evidence: `pair-05-log.png` (mock | `u125-d-full-color.png`).

**The mock establishes.** A sheet that **leaves the crawl's status row
visible** above it, with a handle pill, `COMBAT LOG` in letterspaced small
caps, an `✕` close glyph with no box, a hairline under the title, then fourteen
rows. Each row is an **authored pictogram** — skull, crossed blades, a
walking figure, a lightning bolt, a stair, a candle, a doorway — followed by a
serif sentence, on a generous rhythm of roughly 60 px per row, with no box
around the mark and no fill behind the row.

**The current app shows.** A drawer at `heightFactor` 1.0 that covers the
whole screen, `MESSAGE LOG` in monospace, close in a bordered `CrawlPill`,
then rows whose mark is a **text glyph in a 20 dp recessed well** with a
hairline border and 4 dp radius, followed by a monospace sentence, on a 3 dp
rhythm. Long sentences wrap and the wrap is not indented to the text column.

**Material gaps.**

| # | Gap | Ownership |
|---|---|---|
| 5.1 | Category marks are text glyphs in bordered wells; the mock uses authored pictograms with no container | CODE + ASSET |
| 5.2 | Row rhythm is far tighter than the mock's and wrapped lines return to the mark column | CODE |
| 5.3 | Full extent covers the status row; the mock's sheet stops below it | CODE |
| 5.4 | Sentences are monospace | CODE + ASSET |
| 5.5 | Close affordance is a bordered pill against the mock's bare glyph | CODE |
| 5.6 | Handle pill, title case and tracking, hairline under title | ALREADY ACCEPTABLE |
| 5.7 | Ten categories with distinct marks and accessibility words | ALREADY ACCEPTABLE |

---

## 6 — Character

Evidence: `pair-06-character.png` (mock | `u125-f-character-color.png`).

**The mock establishes.** A header row: back chevron, `CHARACTER` in
letterspaced caps, gear. Then a **framed portrait** of the hero — a painted
hooded figure, square with a hairline frame — beside the hero's name at
display size, `Level 3`, and an epithet, `The Seeker`. Then the HP/Mana meter
pair. Then four attribute rows, label left and value right-aligned. Then four
navigation rows with authored medallions and chevrons: `Spells` with
`6 known` under it, `Equipment`, `Progress`, `Statistics`.

**The current app shows.** An `AppBar` with a back arrow, `Character` in
monospace; a panel box listing Attack, Armour, Dodge%, Speed, Health, Mana;
two lines of counts; then **four stock Material 3 `FilledButton`s in default
lavender** — Gear, Spells, Skills, Pack.

This is the worst frame in the set. The lavender pills are not a design
decision; they are `main.dart`'s bare `ThemeData` showing through
(`recon.md`, "The lavender is the absence of a town-side theme").

**Material gaps.**

| # | Gap | Ownership |
|---|---|---|
| 6.1 | Navigation is four default-lavender Material pills | CODE |
| 6.2 | No hero portrait, framed or otherwise | CODE + ASSET |
| 6.3 | No name / level / epithet hierarchy; the screen never says who you are | CODE |
| 6.4 | No HP/Mana meter pair; health is a text pair inside the stat box | CODE |
| 6.5 | Attributes render as a fenced panel, not label-left/value-right rows | CODE |
| 6.6 | Navigation rows have no medallion and no chevron | CODE + ASSET |
| 6.7 | Mock's attributes are Strength/Dexterity/Will/Lore; the game's are Attack/Armour/Dodge/Speed — the game's vocabulary is authoritative | INTENTIONAL DEVIATION |
| 6.8 | Mock's rows say `Equipment`/`Progress`/`Statistics`; the game says `Gear`/`Skills`/`Pack` — ubiquitous language wins | INTENTIONAL DEVIATION |

---

## 7 — Spells

Evidence: `pair-07-spells.png` (mock | `u125-f-spells-color.png`).

**The mock establishes.** Six spell rows, each an **inset framed row** — panel
fill, hairline border, small radius — carrying a circular authored spell
medallion (a cross-staff for Mend, a bolt for Firebolt, a shield for Ward, a
rayed sigil for Banish, an eye for Reveal, a snowflake for Frost), a serif
name, a serif dim one-line description, and a chevron. Then a `Locked Spells`
section heading and one locked row: padlock medallion, dim "More secrets
await…".

**The current app shows.** Four unframed rows: a green `✳` school glyph in a
28 dp column, a monospace name, and a monospace dim mechanical line —
`Wrath · 2 mana · 2-4 fire △`. No medallion, no frame, no chevron, and no
locked section at all.

**Material gaps.**

| # | Gap | Ownership |
|---|---|---|
| 7.1 | Rows are unframed; the mock's are inset framed rows | CODE |
| 7.2 | No spell medallions — only `firebolt` and `mend` have any art, and neither is used here | CODE + ASSET |
| 7.3 | No chevron, so a row does not read as openable | CODE |
| 7.4 | No `Locked Spells` section or locked row treatment | CODE |
| 7.5 | Monospace name and description | CODE + ASSET |
| 7.6 | Current shows school, cost, damage and marking where the mock shows flavour prose — mechanical truth stays | INTENTIONAL DEVIATION |
| 7.7 | School marked by a distinct glyph per school, legible in greyscale | ALREADY ACCEPTABLE |

---

## 8 — Pack (inventory)

Evidence: `pair-08-pack.png` (mock | `u125-f-pack-color.png`).

**The mock establishes.** Four filter chips — `All` selected as a darker fill
with a brighter border, the rest outlined. Six item rows as inset framed rows,
each with **authored item art** in a square medallion (a red potion bottle, a
blue potion bottle, a dagger, a leather cuirass, a lit torch, an ore chunk), a
serif name with the quantity as `× 2`, a serif dim description, and a chevron.
Empty categories are simply absent.

**The current app shows.** Six filter chips as stock `ChoiceChip`s with a
checkmark and default M3 selected fill. Then **five section headings that are
all empty** — `You are carrying nothing you could swing.` and so on — and a
materials block of text-glyph rows. No item art anywhere; rarity is a `‡`-class
glyph in a 28 dp column; actions are `TextButton`s in a `Wrap`.

**Material gaps.**

| # | Gap | Ownership |
|---|---|---|
| 8.1 | Filter chips are stock `ChoiceChip`s with M3 selected colour and a checkmark | CODE |
| 8.2 | No item art of any kind | CODE + ASSET |
| 8.3 | Rows are unframed and have no chevron | CODE |
| 8.4 | Empty sections are rendered with prose; the mock shows a flat list of what you have | CODE |
| 8.5 | Quantity is `×2` inline in a monospace label; the mock sets it as part of the serif title | CODE |
| 8.6 | Actions are stock text buttons stacked under the row | CODE |
| 8.7 | Rarity marking glyph in a fixed 28 dp column, greyscale-legible | ALREADY ACCEPTABLE |
| 8.8 | Category filters exist at all, and cover more categories than the mock's four | INTENTIONAL DEVIATION |

---

## 9 — The Forge

Evidence: `pair-09-forge.png` (mock | `unit-10-device/stonebridge-forge-color.png`).

**The mock establishes.** Back chevron, `THE FORGE` in letterspaced caps, gear.
A full-bleed forge painting filling ~48% of the frame, with a centred serif
tagline under it — "Better tools for deeper places." Then three framed action
rows with circular authored medallions: `Smelt` / "Turn ore into ingots.",
`Upgrade Gear` / "Improve your equipment.", `Craft` / "Create new items.",
each with a chevron.

**The current app shows.** `Forge` in monospace; a gold status pair; the forge
painting as a **120 dp inset strip**; then `MATERIALS`, `SMELTING`, a
`2 ore makes 1 ingot.` line, a `− 0 + MAX` stepper, a **lavender `Smelt`
button**, `That takes 2 ore.`, `THE BENCH`, `WORN STEEL`, a temper row, and
`CARRIED STEEL`. It is a working console; it is not the mock's screen.

**Material gaps.**

| # | Gap | Ownership |
|---|---|---|
| 9.1 | Illustration is a 120 dp inset strip, not a full-bleed header | CODE |
| 9.2 | No tagline line under the art | CODE |
| 9.3 | Primary action is a default-lavender Material button | CODE |
| 9.4 | Actions are inline mechanical controls, not framed rows with medallions and chevrons | CODE + ASSET |
| 9.5 | Monospace throughout | CODE + ASSET |
| 9.6 | Section headings are `Heading` + rule, which is close to the mock's own small-caps captions | ALREADY ACCEPTABLE |
| 9.7 | The screen exposes smelting quantity, temper prices and tiers that the mock's three rows hide behind navigation — the mock's rows are doors, the game's are the room | **DECISION: adopt the mock's door-and-room split** |

9.7 is the one real composition question in this frame. The mock's Forge is a
menu of three doors; the app's Forge is one long console. Recommended
resolution: the room becomes the mock's three framed doors and the mechanical
console moves behind them, which costs navigation depth but is what the
approved frame shows.

---

## 10 — The Tavern

Evidence: `pair-10-tavern.png` (mock | `unit-10-device/stonebridge-tavern-color.png`).

**The mock establishes.** The same header shape. A full-bleed tavern painting
with a candle and a tankard, with the tagline "GOOD COMPANY LASTS LONGER." in
letterspaced caps over its lower edge. Then three framed rows with medallions:
`Rest` / "Restore health and mana.", `Listen` / "Hear rumors and stories.",
`Leave` / "Continue your journey."

**The current app shows.** `Tavern` in monospace, a gold status pair, the
tavern painting as a 120 dp inset strip, `WHAT THEY ARE SAYING`, one row
reading `[!]Ask about the roads` with a **lavender `Ask 15` pill**,
`WHAT YOU HAVE BEEN TOLD`, and `Nothing yet.`

**Material gaps.**

| # | Gap | Ownership |
|---|---|---|
| 10.1 | Illustration is a 120 dp inset strip, not a full-bleed header | CODE |
| 10.2 | No tagline over the art | CODE |
| 10.3 | Action is a default-lavender Material pill with a price in the label | CODE |
| 10.4 | No `Rest` or `Leave` row; resting lives at the Inn and leaving is the back arrow | INTENTIONAL DEVIATION |
| 10.5 | No medallions on any row | CODE + ASSET |
| 10.6 | `[!]` literal as a leading mark where the mock has a medallion | CODE + ASSET |
| 10.7 | Monospace throughout | CODE + ASSET |

---

## Screens the mock never framed

`World`, `Roster`, `Merchant`, `Bank`, `Inn`, `Alchemist`, `Gear`, `Skills`
and the crawl's own `Pack` have no approved frame. They must inherit the
vocabulary the framed screens establish rather than invent a third language.
Two of them are load-bearing and unevidenced anywhere in this epic: the world
map and the roster.
