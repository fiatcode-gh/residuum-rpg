# Proposed U16 Contract — ASCII Atmospheric Crawl Parity

## Status

- WHAT: **approved by the user**
- Unit type: parity implementation / dungeon presentation pivot
- Implementation HOW: requires local execution-grade planning
- Asset generation: **prohibited in this unit**
- Authorization: **not carried**

## Outcome

The primary crawl screen reads as a deliberate modern ASCII roguelike rather than a textured tile scene surrounded by UI.

The semantic map is pure glyph language. Atmosphere comes from code-driven light, darkness, depth and restrained camera-relative movement. Exploration, combat/targeting, recent events and expanded-log states move substantially toward the supplied ASCII mocks without inventing mock-only gameplay.

Future authored UI assets have stable, documented consumer dimensions, but remain neutral placeholders in U16.

## Scope

### 1. Pure ASCII dungeon terrain

Replace the active textured dungeon terrain/material picture with typographic terrain:

- walls: `#`;
- floor: dot field (`.` or a settled typographic dot with identical semantic meaning);
- stairs: `<` / `>`;
- actors: current glyph identities;
- semantic item/material marks: current authoritative marks.

No dungeon texture image, tile sprite, creature sprite, rubble image or wall/floor overlay may be necessary to understand or render the active dungeon map.

Existing Unit 10 dungeon image assets may remain in the repository for history/cleanup, but the U16 active crawl renderer must not depend on them. Local planning should decide whether stopping their warm-up/decode is part of the clean cutover; deleting historical masters is not required.

Road/encounter terrain must use the same ASCII-first doctrine where the same renderer applies.

### 2. Knowledge-state presentation

Preserve authoritative visibility:

- visible terrain may receive full glyph value/light;
- remembered terrain is dimmer and unlit/less lit;
- unknown terrain reveals nothing.

The ASCII renderer must not infer topology from visual neighbors beyond already-known terrain.

### 3. Atmospheric lighting

Use code-driven lighting over the ASCII layer.

Requirements:

- current game/FOV state remains authoritative;
- lighting never becomes a second FOV or shadow simulation;
- no hidden cell is revealed by glow;
- hue is reinforcement, not the sole carrier;
- hero-centered local light is allowed as presentation;
- any additional ambient light must not imply nonexistent interactable torches/objects or hidden topology;
- same state/camera inputs produce stable results.

The visual target is warm local illumination, readable falloff and deep darkness — not textured masonry.

### 4. Non-semantic depth backdrop

Add a separate backdrop behind the semantic map using code-only treatment such as:

- fog/noise fields;
- soft value masses;
- distant haze;
- subtle vignette/depth gradients.

It must:

- contain no gameplay topology;
- contain no doors, chests, actors, stairs or interactable-looking props;
- never alter hit testing;
- never leak unseen geometry;
- remain visually subordinate to the ASCII map.

### 5. Restrained parallax

A small camera-relative offset may move only the non-semantic depth backdrop.

The semantic ASCII map, target marks and hit-test geometry stay fixed to world/grid projection.

Parallax must be:

- low amplitude;
- driven by camera focus/pan, not arbitrary autonomous motion;
- disabled or reduced when platform motion settings require it if such a setting is already exposed by Flutter;
- incapable of changing simulation or input mapping.

If local planning finds parallax creates ambiguity or excessive implementation risk, static depth remains acceptable; the visual depth effect is required, parallax itself is not allowed to damage readability.

### 6. Main-screen composition

Move the crawl composition toward the new references.

Targets include:

- stronger display hierarchy at the top;
- compact dungeon/location/depth facts from real game state only;
- resources/status presented in the U14/U15 visual language;
- combat timeline compact and subordinate;
- map as the dominant region;
- compact Recent Events/log peek with several useful lines where density allows;
- action shelf visually close to the new mock while preserving all real actions and U15's fit algorithm;
- expanded log visually consistent with the new mock.

The global word `RESIDUUM` may be used as non-interactive branding if local planning proves the dp budget, but fake hamburger/settings controls must not be introduced without real routes/actions.

Mock-only `Torch`, `Hungry`, `Clear`, `Seed`, `Auto-walk`, `Help`, or other facts/actions are not added unless current source already has an equivalent authoritative fact/action.

### 7. Combat and targeting state

Bring battle/targeting presentation toward the supplied combat mock using current mechanics:

- compact activation timeline;
- clear selected/current token hierarchy;
- ASCII actor identities remain;
- target reticle remains code-drawn and readable without hue;
- selected/targeted distinction remains;
- armed action remains visually obvious without changing row height;
- target inspection may use current real actor facts only.

The previously settled decision still stands: the mock's intermediate dotted path/range cells are a flourish and do not create a new path/range mechanic.

### 8. Recent events / expanded log

The log remains causality.

U16 may recompose:

- log peek title/rhythm;
- visible line count;
- category placeholder slot;
- expanded sheet framing;
- row indents and spacing;
- extent relative to crawl header/status.

Do not change:

- LogCategory semantics;
- event ordering;
- follow/unread behavior;
- causal content.

Future pictograms remain placeholders; U16 does not generate them.

### 9. Exact-dimension future-asset placeholders

Any UI art that the new composition expects but does not already have an approved production asset must use a neutral placeholder host with final geometry.

Examples may include:

- action-icon wells;
- log-category pictogram wells;
- status/utility icon wells;
- future small symbols used by main-screen chrome.

Local execution planning must settle exact logical dimensions and padding **before implementation authorization** and record them in the unit's placeholder-slot artifact.

Placeholder requirements:

- neutral geometry only;
- no fake illustrative art;
- transparent-capable host;
- stable alignment/padding/safe area;
- no layout shift when future art arrives;
- semantics carried by adjacent text/state, never by placeholder shape.

These real consumers become inputs to a later `flow-assets` unit.

## Protected boundaries

No changes to:

- `packages/core` gameplay rules unless local recon proves a renderer-only enum seam is impossible — that would be an escalation, not implicit scope;
- `packages/content` balance/content;
- save schema;
- encounter generation;
- RNG outcomes;
- map topology;
- FOV/visibility rules;
- action vocabulary/counts;
- melee map-first;
- targeted spell arm → map target → tap;
- hidden-actor secrecy;
- stable encounter ordinals;
- `readiedSpellCount == 3`;
- U15 stable action identity;
- action-fit measure-all-candidates / shortest-legal algorithm;
- fixed `cameraCellSize == 36 dp`;
- map as an `Expanded` allocation unless a separately approved contract explicitly changes that interaction geometry.

## Asset boundary

### Prohibited

- no image generation;
- no semantic image editing;
- no new dungeon textures;
- no wall/floor tile art;
- no creature sprites;
- no stair/door/prop art;
- no new UI icon family;
- no log pictograms;
- no generated background image.

### Allowed

- code-drawn shapes;
- glyphs/text;
- gradients;
- deterministic/procedural value/noise/fog fields;
- existing already-shipped non-dungeon UI/environment art when untouched;
- neutral fixed-size placeholders.

## Acceptance criteria

1. Active dungeon terrain is legible as pure ASCII/glyph terrain and no longer visually depends on dungeon wall/floor texture images.
2. `#`, floor dots, stairs and actor/item glyph semantics remain authoritative and testable.
3. Visible/remembered/unknown boundaries are preserved with no geometry leak.
4. Atmospheric light improves focus/depth while revealing no hidden cell.
5. A code-only non-semantic depth backdrop is visible but cannot be mistaken for gameplay geometry.
6. If parallax ships, only the depth layer moves and input/world projection remains unchanged.
7. Exploration composition is materially closer to `ascii-exploration-mock.png`.
8. Combat/targeting composition is materially closer to `ascii-combat-targeting-mock.png` without adding mock-only mechanics.
9. Expanded log is materially closer to `ascii-expanded-log-mock.png` while preserving log behavior.
10. Mock-only controls/facts are not invented.
11. Real action vocabulary and dispatch remain unchanged.
12. Armed/unarmed transitions do not change map allocation.
13. Worst legal crawl chrome remains below the locked 600 dp target-device ceiling.
14. `cameraCellSize` remains 36 dp and map taps/long-press/pan resolve to the same logical positions.
15. No authored production asset is generated or semantically edited.
16. Every future art slot introduced by U16 has a final documented rendered envelope/padding/alignment and a neutral fallback.
17. Existing save restoration procedure still passes byte-identically.
18. Formatter, analyzer and full app tests pass.
19. Target-device evidence covers exploration, combat, targeting, expanded log and worst legal density.
20. The unit records which old dungeon-art pipeline paths became unused and routes cleanup separately rather than silently deleting historical assets.

## Evidence standard

Use the supplied mocks as composition/appearance targets and the repository as gameplay truth.

Acceptance should compare:

- map dominance;
- ASCII readability;
- darkness/value hierarchy;
- local light quality;
- depth/backdrop separation;
- chrome compactness;
- timeline hierarchy;
- recent-event usefulness;
- action-shelf rhythm;
- targeting clarity.

Do not fail parity merely because current game facts differ from mock-only copy. Do fail if the implementation reintroduces textured terrain or uses placeholders as fake finished assets.
