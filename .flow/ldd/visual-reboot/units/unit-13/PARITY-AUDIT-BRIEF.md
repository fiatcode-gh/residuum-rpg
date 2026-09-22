# Unit 13 — Parity Audit Brief

For every approved frame answer:

1. What does the mock actually establish?
2. What does the current application actually show?
3. What is the material gap?
4. Who owns it: code, asset, both, deliberate deviation, or already acceptable?

Avoid vague labels such as `polish` when the discrepancy can be named precisely.

## Per-frame focus

### 1 — Stonebridge
Hero/place framing, illustration integration, title/subtitle type, navigation composition, iconography, row density, border/ornament language, palette/value hierarchy.

### 2 — Dungeon exploration
HUD compactness, resources, dungeon architecture, wall/floor depth, lighting, props/debris, actor representation, log-peek size, action shelf, viewport-to-chrome balance.

### 3 — Combat
Timeline compactness, actor token treatment, action hierarchy, combat density, map readability under chrome.

### 4 — Targeting
Armed-state language, target visualization, path/range feedback if truly established by the mock, and map/shelf relationship. Do not invent gameplay mechanics from a visual cue without a design decision.

### 5 — Expanded log
Overlay composition, typography, category marks/icons, density, framing/handle/close treatment, relationship to underlying crawl.

### 6 — Character
Portrait requirement, stat composition, meters, navigation rows, icon vocabulary, hierarchy/density.

### 7 — Spells
Spell icon family, row density, known/locked grouping, descriptive hierarchy, framing.

### 8 — Pack
Filter treatment, item art/icon requirements, row structure, quantities, secondary descriptions, density.

### 9 — Forge
Environment-art integration, title/header composition, action rows/icons, copy hierarchy, framing.

### 10 — Tavern
Same categories as Forge, plus environmental atmosphere and action composition.

## Cross-frame synthesis

Derive cross-cutting gap families only after frame audits. Test, rather than assume:

- typography;
- palette/value;
- frame/surface/ornament;
- action/list-row grammar;
- iconography;
- portraits/item/spell art;
- dungeon structural kit;
- actor/monster representation;
- screen composition.

## Roadmap rule

Future units should be independently acceptable visual slices. Each must state target frame(s), current evidence, exact parity-gap family, asset dependencies, code dependencies, protected semantics, and evidence gate.

Prefer vertical slices that visibly move a frame toward the approved mock over broad refactors whose visual payoff cannot be judged.
