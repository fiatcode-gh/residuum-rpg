# Visual Reboot — Dungeon Material Art Bible

Status: **user-approved direction, 2026-09-13**  
Scope: dungeon/material subset needed by Visual Reboot Unit 2.  
Authority boundary: this locks presentation direction; it does not authorize production implementation.

## Identity

Residuum's dungeon is an **etched dark-fantasy diagram**: physical material underneath clean symbolic actors.

It is not:
- a conventional pixel-art tilemap;
- terminal text with prettier colors;
- painterly fantasy illustration;
- an orange/sepia screen.

The dominant impression is **cold charcoal stone illuminated by restrained warm amber**. Most of the frame remains near-black or neutral charcoal. Warmth reads as light falling onto cold stone.

## Value ladder

The value hierarchy matters more than exact color values:

1. unknown void — near black;
2. remembered material — very dark, flat, reduced detail;
3. visible material — readable charcoal stone;
4. structural edges / selected marks;
5. high-value actor glyphs and important symbols.

The dungeon must remain legible in greyscale.

Reference anchors, subject to device evidence tuning:

- void: `#050607`
- deep stone: `#101315`
- remembered stone: `#1A1E20`
- visible stone: `#292A27`
- stone edge: `#48463F`
- warm ink: `#D4B77B`
- hot light: `#E8C58A`
- ivory glyph: `#E8E2D4`

These are visual anchors, not a requirement to create a large token system in Unit 2.

## Material rules

### Floor

Floors are a continuous stone field, not 36×36 illustrated tiles.

Use sparse, deterministic:
- grit;
- scratches;
- chips;
- tiny stones;
- subtle local value variation.

Large quiet regions are intentional. A tile should read as stone before its individual decoration becomes noticeable.

### Walls

Walls carry stronger structure than floors:
- masonry/block suggestions;
- chipped edges;
- occasional hairline cracks;
- stronger silhouette/edge response.

Logical tile boundaries are input geometry, not visible UI-cell borders. Adjacent known walls should read as one masonry mass where practical.

### Texture density

Low-to-medium.

Do not decorate every cell. Avoid visual noise that competes with actor glyphs, targeting, or path reading.

### Determinism

Every procedural imperfection is derived from stable presentation inputs such as coordinate, theme, tile kind, and fixed salts.

Presentation variation:
- must survive rebuilds and revisits unchanged;
- must not consume core/gameplay RNG;
- must not animate or flicker merely because a frame repaints.

## Knowledge, fog, and lighting

### Unknown

Unknown space is essentially black.

No:
- wall silhouette;
- crack;
- grit;
- texture speck;
- light bleed;
- ambient gradient;
- neighboring topology hint

may reveal unknown geometry.

### Remembered

Remembered geometry remains readable but is:
- substantially darker;
- flatter;
- cooler/neutral;
- lower-detail;
- unlit.

It carries remembered terrain/node semantics only. Actors and litter remain subject to existing knowledge rules.

### Visible

Visible material receives the full material response and presentation lighting.

The core/app visibility set remains authoritative. Unit 2 may smooth lighting **inside** authoritative visible space but must never run a second gameplay FOV or shadowcasting model.

Recommended conceptual render order:

1. unknown void;
2. remembered material;
3. visible material;
4. rule-exposed nodes/litter;
5. actors;
6. clipped local illumination treatment;
7. targeting/transient presentation marks.

### Lighting

Use warm light in a cool-dark world.

Light should alter **value first, hue second**. Avoid bright game-like radial glow.

A smooth local gradient may be centered around the hero/presentation light source, but it must be clipped to currently visible geometry so it cannot disclose unknown cells.

No realistic second shadow simulation is required in Unit 2.

## Graphical glyphs

Actors retain their semantic glyph identity (`@`, current creature glyphs, stairs and existing content symbols) but render as deliberate graphical marks rather than terminal cells.

Preferred qualities:
- crisp silhouette;
- restrained outline/shadow;
- subtle scale hierarchy;
- optional very small halo for hero/significant marks;
- strong value separation from terrain.

Glow never substitutes for visibility or targeting state.

Terrain gains physicality; actors retain abstraction. This contrast is part of Residuum's identity.

## Engraving language

Use:
- fine irregular strokes;
- shallow etched marks;
- occasional broken edges;
- restrained archaeological/diagrammatic ornament.

Avoid:
- ornate Celtic/fantasy frames;
- glossy fantasy-card chrome;
- dense decorative filigree.

## Realism

Target roughly **30% stylized material realism**: enough variation to feel like stone, not enough to become illustration or noisy texture art.

## Motion

Material is static in Unit 2.

Do not introduce texture crawl, flicker, particle ambience, or decorative animation as an acceptance requirement. Subtle lighting motion may be considered later only if it preserves deterministic readability and brings clear value.

## Accessibility and contrast

No important state relies on hue alone.

Visible / remembered / unknown differ by value and detail. Target marks remain recognizable by shape/position in greyscale. Actor identity derives from glyph/shape, not color.

The approved phone evidence must include a greyscale pass.

## Deferred art-bible extensions

This Unit 2 lock settles dungeon material language.

Portrait framing, generated static-art composition, and a full non-dungeon icon family remain deliberately deferred. They must be locked before Unit 7 performs bulk/static art work; Unit 2 must not pre-empt them through an asset pipeline.
