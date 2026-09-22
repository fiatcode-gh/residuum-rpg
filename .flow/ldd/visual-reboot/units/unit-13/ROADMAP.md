# Visual reboot — the recut roadmap

The old roadmap is retired. `Dungeon Structural Asset Expansion` survives as
two units (U18, U19) rather than one, and the rest is derived from
`PARITY-MATRIX.md` instead of from subsystem numbering.

Each unit below is an independently acceptable visual slice: it moves named
frames measurably toward the approved mock, it can be shipped and judged on
its own, and its evidence gate is a re-shot frame rather than a green suite.

Ordering is by **dependency and cost**, not by which gap is biggest. U14 is
first among the visual units because every other one consumes its tokens, and
because it is the cheapest large win in the epic — a font, a sibling theme,
and the lavender dies on four frames at once. U13.1 precedes it because a
defect in the seam U18 and U21 will rewrite should not be inherited.

**Approved by the user 2026-09-18, as ordered: U13.1, then U14 → U21.**
The font choice is Spectral for text and EB Garamond for display; the shared
token module plus sibling per-screen themes is approved; frame 4's three
intermediate cells are a mock flourish and no range feedback will be built;
the world map and the roster inherit the vocabulary **and gain an evidence
gate**.

---

## U14 — Type, palette and surface authority

**Frames** all ten. **Ownership** CODE + ASSET.

Two authored font faces land and the two type roles from `VISUAL-SYSTEM.md`
section 1 replace `fontFamily: 'monospace'` **everywhere** — monospace is
retired outright, including for numbers, because the mock uses none. Numeric
alignment comes from tabular figures and the fixed-width slots the town
already uses. The two duplicate palettes in `crawl_style.dart` and
`town_style.dart` collapse into one shared token module, and the town and
world screens get a sibling theme so no stock Material control renders
unthemed. The HP/Mana meter pair becomes one component used by the crawl
status, the character screen and anywhere else a resource is shown.

**Depends on** nothing outstanding: the font choice (Spectral text, EB
Garamond display) and the shared-seam supersession are both settled
(`VISUAL-SYSTEM.md` sections 1, 8 and 9).
**Protected** greyscale legibility; no hue-only state; no implicit global
restyle — each screen root opts in.
**Gate** every screen re-shot in colour and greyscale — **including the world
map and the roster**, which have no baseline anywhere in this epic and get
their first one here; the crawl's dp budget re-measured, because type metrics
move chrome height.
**Inherited duty** U14's capsule list must include the **ceiling-density
crawl**. U13.1's AC7 was amended on 2026-09-18 to drop its own emulator pass,
because that fix lands at the game's own render call and is proved headlessly
there; its confirmation on real hardware is owed here instead. If U14's
device pass shows the dock covered at the ceiling, U13.1 reopens.

## U15 — Row, control and chip grammar

**Frames** 1, 2, 3, 4, 6, 7, 8, 9, 10. **Ownership** CODE.

Nine bespoke row anatomies become one framed row with a medallion slot, a
title, a detail line and a trailing affordance. The pack's filter chips stop
being stock `ChoiceChip`s. The action shelf's geometry moves toward the
mock's one-row discipline: cost leaves the label, the overflow chip becomes a
plain `+N`, and the fit rule keeps its measure-then-pick behaviour. The
spells screen gains its `Locked Spells` section. The Forge splits into a
menu of doors with the console behind them. Empty pack sections stop
apologising in prose.

**Depends on** U14's tokens. The medallion slot ships **empty-ready** so U16
can fill it without touching layout.
**Protected** action vocabulary and counts; the eleven-chip ceiling; melee
map-first; the four-region rule; `Flee` never inside a crawl.
**Gate** every list screen re-shot; the chip row proved at worst legal
density against the 600 dp ceiling.

## U16 — Authored icon and art families

**Frames** 1, 5, 6, 7, 8, 9, 10. **Ownership** ASSET, with thin CODE.

The asset families in `VISUAL-SYSTEM.md` section 5 are authored and wired:
verb icons for every shelf verb, medallions for every room door and every
spell in `packages/content`, item art by family, and ten log pictograms that
retire the text-glyph marks. The code side is widening the asset enums and
adding item/spell icon resolution — no layout changes, because U15 already
left the slots.

**Depends on** U15's medallion slot.
**Protected** the art bible's tone, multitone untinted masters, greyscale
legibility per asset; the `LogCategory` accessibility words stay.
**Gate** an icon contact sheet plus each consuming screen, colour and
greyscale.

## U17 — Illustration headers and hero portrait

**Frames** 1, 6, 9, 10. **Ownership** CODE + ASSET.

The 120–140 dp inset illustration strips become full-bleed headers with the
title set on or under the art. The town's numeric status block leaves the
title region. The character screen gains the identity block the app has
never had: framed portrait, name at display size, level, epithet.

**Depends on** U14.
**Protected** save compatibility; room vocabulary; root screens have no back
affordance.
**Gate** four screens re-shot, colour and greyscale.

## U18 — Dungeon light and stone value

**Frames** 2, 3, 4. **Ownership** CODE only.

The single largest single-frame gap, and it needs no new art. The lit floor
sits far lighter than the mock's while wall and unknown space are both black,
so a room has no mass. The authored floor and wall textures are already
shipped and effectively invisible at `authoredScale` 0.32 under `softLight`.
The one hero-centred radial gradient becomes a lighting model with placed
sources, and the hard black boundary gains a falloff.

**Depends on** nothing. Could run before U14 if the dungeon matters more than
the chrome — it shares no code with U14–U17.
**Protected** determinism (same seed, same floor, identical decoration from
coordinate and theme salt, never gameplay `Rng`); the fixed 36 dp cell; the
7.93-rows-of-sight figure.
**Gate** the same seed rendered before and after in all three biomes, colour
and greyscale.

## U19 — Dungeon structure and props

**Frames** 2, 3. **Ownership** CODE + ASSET.

Terrain vocabulary is `wall`, `floor`, `stairsUp`, `stairsDown` and nothing
else; stairs are a `<` glyph. This unit adds stair art, a door kind with art,
and a per-biome prop family, all placed deterministically.

**Depends on** U18's lighting, because a prop with no light on it is a
silhouette.
**Protected** determinism; engine authority — a new terrain kind is a `core`
change and goes through `step`, not the renderer; save compatibility.
**Gate** three biomes at one seed, colour and greyscale.

## U20 — Actor representation

**Frames** 2, 3, 4. **Ownership** CODE + ASSET.

Monsters are a gold letter; the mock draws a creature and uses the letter as
its label. Creature art lands as a layer **under** the existing glyph, so the
letter, the superscript ordinal and the accessible identity all survive.

**Depends on** U18.
**Protected** hidden-actor secrecy — art may never reveal an actor the hero
has not seen; ordinal identity; circle-selection versus square-targeting;
greyscale legibility.
**Gate** a crowded floor with same-type monsters, colour and greyscale.

## U21 — Combat chrome density

**Frames** 2, 3, 4, 5. **Ownership** CODE.

The residue, and it is all measurement. Timeline tokens carry a short display
name instead of `the giant rat¹` shrunk to fit. The band loses its panel
border. The log peek stops leaving dead space and prose stops living both
inside and outside it. The expanded log gets the mock's row rhythm, indents
its wraps to the text column, and stops covering the status row. The target
mark becomes the mock's reticle-and-cells language.

**Depends on** U14 and U15; it re-measures what they changed.
**Protected** timeline = time and log = causality; activation repetition; the
dp budget.
**Gate** worst legal density re-measured against 600 dp; frames 2–5 re-shot.

---

## Defects, routed

### U13.1 — the map bleed, before U18

The Flame canvas paints ~144 px (~55 dp) above its own top hairline at
worst-legal-battle density and, being a later sibling in the `Column` than
`BattleDock`, covers the dock opaquely. `game_screen.dart` lines 80–136 wrap
the map in a `Stack` with no `ClipRect`.

Its own small unit, run under `flow-debugging`, **before** U18 — because U18
rewrites the same viewport's lighting and would inherit the bug, and because
U21 re-measures the same seam.

**Do not reach for a `ClipRect` first.** If the viewport renders more rows
than its box owns, a clip hides the overflow while leaving the camera showing
rows the box does not own, which silently invalidates the 7.93-rows-of-sight
figure. Diagnose why the canvas exceeds its constraints.

### The post-death save-read candidate, unscheduled

The app reported *"your last save could not be read; an older one was
restored"* for a post-death autosave whose bytes were readable — the codec
refused the document. Not visual, not in this epic. It needs its own
contract: stage a hero at 1 HP, die, feed the resulting `save.json` to
`decodeSave`. If it is real, a player who dies loses a slot. It does not
block any unit above, and it must not be diagnosed inside one.

### O3, a follow-up, not a defect

Chips are keyed by their composed label, so a mana rebalance in
`packages/content` would break `packages/app` widget tests for a
presentational reason. U15 touches the same chips and may fix it in passing by
giving `CrawlAction` an id; it is not a reason to open a unit. No collision is
reachable today.

---

## Evidence the epic never had, now owed

- **The world map and the roster have no approved frame and no visual
  baseline.** The roster passed Unit 12.5 on internal consistency alone.
  Settled 2026-09-18: they inherit the vocabulary, no frame is commissioned,
  **and U14 owes the first device shot of each, colour and greyscale.** U15
  and U17 re-shoot them when their changes reach those screens. They stop
  being the epic's only unevidenced surfaces.
