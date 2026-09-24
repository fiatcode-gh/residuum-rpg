# U16 ASCII Atmospheric Art Direction

This text is the authority for interpreting the supplied generated references.

## Thesis

**Pure glyphs. Deep atmosphere.**

The dungeon itself is ASCII.

No stone photograph, painted floor, masonry sprite, creature portrait or decorative prop is required to make the map readable.

The premium feeling comes from:

- typography;
- value hierarchy;
- light;
- darkness;
- spacing;
- depth;
- restrained colour;
- responsive composition.

## Semantic foreground

Authoritative terrain/entities are glyphs only:

- `#` wall
- `.` / typographic dot floor
- `@` hero
- enemy identity glyphs
- `<` / `>` stairs
- existing item/material marks

Selection/targeting is code-drawn geometry around those glyphs.

## Lighting

Lighting reveals **known** semantic cells more strongly; it never decides what is known.

Preferred look:

- warm ivory/amber center;
- soft falloff;
- deep charcoal edges;
- remembered map visible at a much lower value;
- enemy danger can use hot red as redundant emphasis;
- cold blue can reinforce mana/frost/target-range UI where the game already owns that meaning.

No red-vs-green state pair.

## Depth backdrop

Backdrop is atmosphere, never level structure.

Allowed:

- fog;
- smoke-like soft noise;
- broad shadow masses;
- dim colour haze;
- vignette;
- camera-relative drift.

Forbidden:

- fake corridors;
- fake walls;
- fake doors;
- chests;
- torches;
- stairs;
- monsters;
- props that look interactable.

A player should be able to mentally remove the backdrop and still have the complete game board.

## Parallax

Parallax, if used, belongs only to the backdrop.

The map does not float.

Recommended feel: barely perceptible depth response during pan/recenter, not a scrolling wallpaper.

## Typography

Retain U14 authority:

- EB Garamond = display
- Spectral = text

Map glyph rendering may use the production text face only if glyph metrics remain grid-stable; local planning may define a dedicated map-glyph text role from an already-bundled face, but may not add a new font asset in U16.

## UI

The new mocks show a denser, calmer crawl:

- display hierarchy at top;
- map dominates;
- status is compact;
- timeline exists only when needed;
- recent events are readable without stealing the screen;
- action controls have one consistent geometry.

The mock is not permission to create unsupported gameplay.

## What is deliberately not literal

The generated references contain illustrative facts/actions that are not current product truth, including some combination of:

- Torch
- Hungry
- Clear
- Seed 42
- Wanderer
- Auto-walk
- Help
- dotted target path/range feedback
- exact weapon/armor/pack facts
- exact enemy stats/copy

Use real repository facts instead.

## No dungeon assets

The following visual direction is explicitly superseded for the active map:

- textured floor/wall material images;
- structural dungeon tile-kit generation;
- creature sprite generation;
- authored stair/door/prop art as a requirement for dungeon parity.

Existing files may remain until a later cleanup decision. They are no longer the target presentation.
