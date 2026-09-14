# Unit 2 — Graphical Dungeon Language

Status: **proposed for local LDD reconciliation**.  
Dungeon-material art direction was user-approved on 2026-09-13.  
This external handoff carries **no implementation authorization**.

## Goal

Turn the accepted Flame crawl renderer into Residuum's flagship graphical-glyph dungeon language without changing gameplay, interaction, knowledge, camera, balance, content, saves, or authoritative state.

The result should read as a continuous etched stone dungeon in cold charcoal, illuminated by restrained warm local light, with semantic glyph actors above it.

## Product contract

- Flame remains presentation-only. `GameBloc` and core `GameState`/`step` remain authoritative.
- Preserve all Unit 1 interaction behavior exactly. Unit 3 still owns direct map melee, targeting redesign, favorites/overflow, camera easing/recenter, and action-shelf changes.
- Preserve rules-driven FOV and knowledge exactly. Presentation lighting and texture must never disclose unknown geometry.
- Preserve current node/litter/monster/hero exposure rules and semantic draw ordering.
- Procedural texture is deterministic presentation state only and never consumes gameplay RNG.
- The map reads as a continuous material surface, not a grid of individually illustrated 36×36 tiles.
- Actors remain glyph-derived semantic marks rather than sprite characters.
- Unit 2 establishes the Crypt material baseline. Sea-Cave / Ruined Keep theme parity remains Unit 8 work; do not turn Unit 2 into three-theme art production.
- No generated raster asset set or bulk asset pipeline is required.

## Locked visual contract

`ART-BIBLE.md` in the handoff bundle is the Unit 2 material authority.

Key lock:
- cold-neutral charcoal environment;
- restrained warm amber illumination;
- near-black unknown void;
- dark/flat/unlit remembered geometry;
- visible stone with low-to-medium deterministic detail;
- structural walls, quieter floors;
- crisp high-value graphical glyph actors;
- greyscale-safe state communication.

## Presentation architecture

### Separate material from semantic glyph projection

The accepted Unit 1 scene currently consumes `glyphPlan(...)` cells and renders them through `_GlyphComponent` text components.

Unit 2 should stop treating terrain glyphs (`#`, `.`, `<`, `>`) as the material renderer.

Introduce an explicit immutable presentation description for **known terrain**, sufficient to carry:
- position;
- tile kind;
- visible vs remembered knowledge;
- dungeon/theme palette identity as needed.

Keep semantic presentation for nodes, litter, monsters, hero, and marked targets independent from the material layer. Reuse existing `glyphPlan` semantics where they remain the safest characterization boundary rather than reimplementing rule exposure.

Do not parse glyph characters back into tile/game semantics inside Flame.

### Suggested scene layers

The exact class names are local implementation choice, but preserve this ownership:

1. material / terrain layer;
2. remembered-vs-visible treatment;
3. semantic node/litter layer;
4. actor glyph-mark layer;
5. clipped presentation-light treatment;
6. target/transient mark layer.

A different internal split is acceptable if local source recon proves it simpler while preserving the contract.

### Deterministic material function

Use a small pure coordinate/theme/tile hashing function (or equivalently deterministic local presentation seed) for decorative choices.

Requirements:
- same presentation inputs => same marks;
- no global mutable randomness;
- no core RNG stream;
- no time/frame dependence;
- testable without screenshots.

### Wall topology and no-leak rule

Wall edge/masonry treatment may use neighboring **known** terrain to improve continuity.

Unknown neighboring tile type must not influence a visible cue that reveals what lies outside the knowledge boundary. Treat unknown adjacency generically/closed rather than inspecting it for decorative shape.

Decorative drawing should stay inside the known/material mask unless a seam is proven not to leak geometry.

### Lighting mask

Lighting is a presentation transform over authoritative visibility.

A practical approach is:
- construct a visible-region clip/mask from current authoritative visible positions;
- draw a smooth hero-local gradient inside that mask;
- leave remembered geometry unlit;
- leave unknown void untouched.

Do not implement independent line-of-sight, shadowcasting, occlusion, or gameplay visibility in Flame.

### Glyph marks

Replace terminal-looking actor presentation with deliberate graphical marks while preserving exact semantic glyph identity.

The implementation may use custom canvas/text rendering rather than sprite assets. Prefer:
- crisp fill;
- restrained outline/shadow;
- small controlled halo where useful;
- stable alignment and hit-independent rendering.

Target markings retain their shape-based greyscale-safe contract.

## Non-goals

- No core/content/save/economy/balance/generator changes.
- No Unit 3 interaction changes.
- No timeline, duplicate identity, log drawer, character/pack, town, world, or static-art redesign.
- No pinch zoom.
- No second FOV/lighting simulation.
- No gameplay RNG use.
- No bulk generated raster art.
- No final Sea-Cave/Ruined Keep material parity.
- No decorative pseudo-props that look interactable.

## Acceptance criteria

1. On the target phone composition (about 411×923 logical px), the Crypt crawl clearly matches the approved reboot direction: near-black void, continuous dark stone, warm local illumination, graphical glyph actors, and compact/readable map hierarchy.
2. Unknown cells reveal **zero geometry** through texture, wall topology, gradients, cracks, edges, or light bleed.
3. Remembered terrain is visibly distinct from current visibility by value/detail without relying on hue, and remains unlit/quiet.
4. Procedural material is stable across Flutter rebuilds, scene synchronization, camera pan, and equivalent revisit/reprojection. Tests pin deterministic presentation decisions without requiring brittle pixel-perfect snapshots.
5. Nodes/litter/monsters/hero and marked-target exposure/order remain consistent with the accepted Unit 1 / `glyphPlan` behavior; no gameplay outcome or log semantics change.
6. Existing tap movement, distant auto-walk, pan, battle dock, explicit Attack, spells, Wait, contextual controls, exits, and current adjacent-monster tap refusal remain unchanged.
7. No Flame component owns or mutates gameplay/FOV/RNG state and no core/content package gains Flame/Flutter presentation dependencies.
8. App formatting, `flutter analyze`, and full `flutter test` from `packages/app` pass, including new deterministic-material and knowledge-boundary tests.
9. Final Pixel_10/phone-sized AVD evidence includes:
   - normal-color Crypt screenshot;
   - greyscale version;
   - a framing that contains visible, remembered, and unknown regions where practical;
   - evidence that glyphs/marks and knowledge states remain readable without hue.
10. Visual acceptance is directional, not pixel-perfect: compare hierarchy, darkness, material continuity, lighting restraint, and glyph clarity against the approved mock/art bible.

## Verification strategy

Prefer behavior-level and renderer-plan tests over pixel snapshots:

- deterministic hash/material decisions for fixed coordinates;
- unknown-neighbor no-leak cases;
- visible vs remembered material decisions;
- synchronization stability after pan-only updates and equivalent state projections;
- existing dungeon scene interaction/projection characterization;
- full app suite + analyzer;
- final AVD + greyscale acceptance.

Suggested review disposition:
- COR: run — renderer semantics and no-leak/FOV boundary are consequential;
- TTC: run — deterministic and characterization contracts matter;
- CRF: run — new renderer decomposition can easily become coupled/duplicated;
- SEC: skip unless implementation unexpectedly introduces an external/security boundary.

## Risks and traps

- Do not derive game semantics by parsing rendered glyph strings.
- Do not let topology inspect unknown neighbors in a way that encodes hidden geometry.
- Do not make every tile independently ornate; continuous material is the goal.
- Do not use orange warmth as the dominant base palette.
- Do not rebuild a full scene/game instance on Flutter rebuild.
- Preserve Unit 1's pan-only projection reuse and reconciliation behavior unless a source-verified change is required.
- The game is turn-based and the Flame engine is currently effectively static between synchronization events; do not add decorative frame churn merely to make the renderer feel 'game-like'.
- Keep phone acceptance as the gate; tablet composition remains deferred.
