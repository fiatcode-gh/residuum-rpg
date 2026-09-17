# Unit 11 — Dungeon Scene Recomposition

Status: **approved by the user on 2026-09-17.** This approval authorizes
execution-grade planning only. Production implementation still requires a
separate approval of `PLAN.md`.

Dependency: Unit 10 merged to `main` as PR #20 at merge commit
`0692bbcce7570df988f6daab9b357a2557e58b39`.

## Outcome

Bring the crawl viewport materially closer to the approved visual reboot mock
at normal phone gameplay scale while preserving the authoritative game model.

After this unit:

- floors recede and walls read as dark structural mass rather than equally lit
  textured cells;
- visible / remembered / unknown terrain form a deliberate value hierarchy;
- authored material reads as stone surface, not wallpaper or a collage of
  source-image crops;
- cracks and rubble read as sparse grounded surface detail rather than pasted
  objects;
- actors, stairs, targeting, selection and other semantic marks remain the
  strongest readable layer without oversized glyph spill;
- Crypt, Sea-Cave and Ruined Keep retain distinct regional identity;
- lowland roads remain procedural and recognizably continuous with their
  accepted identity.

The approved mock is the authority for hierarchy, density, darkness, structural
readability and semantic prominence. It is not a literal topology template.

The governing invariant remains:

> Authored art may change appearance, never topology, knowledge, interaction,
> or game-state meaning.

## Inherited locks

1. Flame stays presentation and hit-testing only. Authoritative state remains
   outside the renderer.
2. `MaterialPlan`, map topology, collision, FOV, targeting, camera geometry,
   stairs and actor identity remain authoritative.
3. Unknown geometry stays unknown and unpainted.
4. Remembered terrain stays unlit and materially flatter than visible terrain.
5. No important state may rely on hue alone.
6. Presentation stays deterministic and consumes no gameplay RNG.
7. Map-first melee, arm-then-map targeting, timeline identity and all existing
   interaction semantics remain unchanged.
8. No save-format, content, balance, generator or core rule change.
9. Phone-first. Tablet, landscape and pinch zoom remain deferred.
10. Unit 10's one-time decode ownership remains intact; no image decode moves
    onto a per-frame or per-cell hot path.

## Scope

### A. Structural dungeon presentation

The renderer may derive visual structure only from the authoritative known
material projection.

- Walls must read as materially darker, heavier and more architectural than
  floors at phone gameplay density.
- Existing wall-face / edge facts may drive face shading, inset shadow,
  boundary treatment and corner/junction emphasis.
- Structural treatment must not inspect unknown cells to infer hidden geometry.
- The presentation may add no collision, cover, interactable or semantic fact.

### B. Value hierarchy and local light

Recompose the visible material response so local light creates focus rather
than exposing the entire visible polygon at one near-uniform value.

The intended hierarchy is:

1. unknown / void: near black;
2. remembered terrain: dark, flat, unlit;
3. visible walls: dark structural mass;
4. visible floors: navigable but restrained;
5. local light core: selective highlight;
6. actors / targets / stairs / interaction marks: strongest semantic contrast.

Crypt, Sea-Cave and Ruined Keep may retain different hue families, but the
hierarchy must survive greyscale.

### C. Authored material scale and compositing

The existing approved masters remain the source.

- No new hand-authored dungeon master is introduced in Unit 11.
- The renderer may change world-space sampling scale, authored-layer strength,
  composition order and reproducible derived treatment.
- Adjacent cells must still read as one continuous material field.
- Full source bitmaps are never repeated per tile.
- Mirror tiling or another seam-safe deterministic strategy remains required.
- Authored material stays subordinate to topology, wall mass and lighting.

### D. Decorative overlay integration

Existing crack / fracture / rubble art may be re-scaled, re-positioned,
mirrored / quarter-turned, opacity-adjusted and grounded using deterministic
presentation facts.

- Placement should prefer plausible structural context where that context is
  available from known geometry.
- Density must be visibly sparse.
- Decoration remains clipped to authoritative known geometry.
- It remains non-colliding, non-loot, non-interactive and semantically silent.
- Decoration must not resemble stairs, actors, items, resource nodes or target
  marks.

### E. Semantic glyph treatment

Keep the graphical-glyph identity while bringing it into the same visual
composition.

- Actor and terrain-semantic glyphs must fit inside their owning cell with
  visible negative space.
- Hero / monster / node / litter hierarchy may change in scale and halo
  treatment.
- Duplicate-actor badges remain stable and attributable.
- Targeting stays square; selection stays circular.
- Target and selection states remain readable without hue.
- No glyph treatment changes hit testing or actor identity.

### F. Performance and render-plan ownership

Expensive path / paint / transform / decoration placement work belongs on plan
adoption or component synchronization, not the frame loop.

No new image decoding is permitted during crawl rendering.

## Asset decision

**Unit 11 uses the existing approved dungeon art only.**

Do not generate a structural sprite kit, new corners, new wall tiles or new
decorative masters in this unit.

If the accepted renderer still lacks structural vocabulary after device
evidence, record that as evidence for a later asset-expansion decision rather
than quietly expanding Unit 11.

## Non-goals

- Crawl status, timeline, log, action controls and bottom-sheet styling.
- The lavender Material-style controls seen in Unit 10 evidence.
- Town / Forge / Tavern / management screen composition.
- Portraits.
- New Melee or Back controls.
- New gameplay light sources.
- New dungeon topology or content.
- A new road art family.
- A whole-app Flame migration.

## Acceptance criteria

1. On `Medium_Phone`, Crypt, Sea-Cave and Ruined Keep each read as a dungeon
   made of floors bounded by darker structural walls without requiring the
   viewer to trace cell rectangles manually.
2. A frame containing visible, remembered and unknown terrain shows three
   distinct value states in both colour and greyscale; remembered terrain is
   never lit and unknown terrain is never painted.
3. Local illumination creates a clear focal region while substantial visible
   terrain remains dark enough for semantic marks to dominate.
4. Authored floor / wall material is visibly present but subordinate to
   geometry and lighting. It must not present obvious per-cell crop boundaries
   or a dominant mirror/repeat rhythm at gameplay density.
5. Crack / rubble decoration is deterministic, sparse, cell-contained and
   visually grounded. It carries no gameplay meaning and never changes
   collision, targeting or interaction.
6. Hero, monster, node, litter and stair marks remain inside their owning cell
   with visible breathing room. No glyph needs cross-cell spill to be legible.
7. Selection remains circular and targeting remains square. Both remain
   distinguishable in greyscale and do not rely on hue.
8. Duplicate actor badges remain consistent with the map / timeline / inspect
   identity contract.
9. Lowland-road presentation remains procedural and recognizably preserves its
   accepted regional identity. A regression capture is required if shared
   renderer code changes it.
10. Identical game + presentation state yields identical material, wall,
    decoration and glyph presentation across rebuilds / revisits / pans and
    consumes no gameplay RNG.
11. No source under `packages/core` or `packages/content` changes.
12. No save-format, balance, generator, hit-test, FOV, topology, camera or
    interaction behavior changes.
13. Focused tests cover at minimum: floor-vs-wall light treatment; no unknown
    structural inference; remembered-unlit preservation; deterministic
    decoration placement; glyph containment; square-target / circle-selection
    preservation; and road fallback.
14. `dart format --set-exit-if-changed`, `flutter analyze` and the full
    `packages/app` test suite pass on the final tree.
15. Integrated acceptance review runs before device evidence; all must-fix
    findings are closed.
16. `Medium_Phone` device evidence contains:
    - Crypt wall-heavy scene with visible + remembered + unknown states;
    - Crypt stair landing regression reference;
    - Sea-Cave combat with multiple actors;
    - armed targeted spell with visible square target marks;
    - Ruined Keep wall-heavy scene;
    - lowland-road regression;
    - greyscale twin for every frame where hue could otherwise carry state.
17. Device evidence is reviewed side-by-side with the approved mock for
    structural readability, darkness/value hierarchy, material subordination,
    decoration integration and semantic prominence. Pixel matching is not
    required.
18. Both device save slots are backed up before install and restored
    byte-identically afterward under the standing epic rule.

## Verification disposition

- Contract approved before planning.
- Execution-grade plan requires fresh source recon at the Unit 10 merged tree.
- Expected review lenses: correctness, test-contract quality and code/readability
  / maintainability. Security review remains skipped unless a new trust
  boundary appears.
- Device evidence is a final bounded gate, not a substitute for automated
  invariants.
