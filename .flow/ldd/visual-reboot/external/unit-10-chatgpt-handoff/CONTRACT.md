# Unit 10 — Authored Art Integration Contract

Status: **proposal for user approval; not yet authoritative.**

Dependency: Unit 9 must be accepted and merged first. The receiving architect
must bind this contract to the actual merged Unit 9 base before approval/planning.

## Outcome

Integrate the approved authored visual assets into Residuum's existing visual
architecture without giving images authority over gameplay.

After this unit:

- the Flutter app has a deliberate, centralized asset pipeline rather than
  ad-hoc string paths;
- matching town/room surfaces may carry authored environment illustrations as
  atmosphere, while their existing text, controls, and semantics remain primary;
- Crypt, Sea-Cave, and Ruined Keep can use authored material sources inside the
  existing deterministic dungeon renderer while runtime topology, visibility,
  remembered-vs-visible knowledge, local light, and hit testing remain
  authoritative;
- cracks/rubble may enrich known terrain as deterministic decorative overlays
  but never become collision, loot, interactables, or hidden-information leaks;
- selected existing controls may show icons beside their current labels/counts;
  no action/state becomes icon-only or hue-only.

The governing rule is:

**Authored art may change appearance, never topology, knowledge, interaction, or
game-state meaning.**

## Inherited locks

1. Flame is presentation/hit-testing only; authoritative state remains outside
   the renderer.
2. Map = space/targets, timeline = time, log = causality, shelf = verbs.
3. The crawl stays map-first. New visual chrome/art must not materially steal
   play-surface height or create a competing primary focal surface.
4. Presentation is deterministic. Decorative art decisions may use stable
   presentation hashes but must never consume gameplay RNG.
5. Unknown geometry stays unknown. No texture, overlay, lighting, sampling, or
   decoration may reveal a cell outside the authoritative known set.
6. Remembered terrain remains visually distinct from currently visible terrain
   and never receives live local-light treatment.
7. No important state/action is communicated by hue alone.
8. Existing words/counts/refusal sentences remain available when icons or art
   are added.
9. No balance/content/generator/save-shape/rule/event/bloc-ownership piggyback.
10. Phone-first; tablet/landscape work remains deferred.

## Proposed scope

### A. Asset pipeline and ownership

- Add the first active Flutter asset declaration under `packages/app`.
- Use one app-side catalogue/typed vocabulary for asset references rather than
  scattering raw paths through widgets/renderers.
- Production art files live under an app-owned asset root.
- Asset loading/lifetime belongs to presentation code. `packages/core` and
  `packages/content` must not depend on Flutter image types or asset paths.
- Actual paths, formats, dimensions, and preload strategy are planning concerns
  to finalize only after the receiving session inventories the real files.

### B. Environment illustrations

Use authored environment art only on a surface with a matching approved asset.

The working logical set discussed in this session includes:

- Stonebridge environment;
- Forge;
- Tavern.

Rules:

- the image is atmospheric, not an interactable map or information source;
- existing titles, status, prices, reasons, controls, and navigation remain
  authoritative and readable without the image;
- decorative art should be excluded from accessibility semantics unless it
  carries approved textual meaning;
- do not fabricate a Northgate illustration by reusing Stonebridge art;
- do not force an image onto a room that has no matching approved asset;
- preserve phone scroll/reachability of every existing control.

### C. Dungeon authored materials

Integrate authored material sources for the regions that have matching art:

- Crypt;
- Sea-Cave;
- Ruined Keep.

Lowland-road material remains on the existing procedural treatment unless a
matching approved road asset is actually present and explicitly admitted to the
contract.

The authored material layer must consume the same authoritative
`MaterialPlan`/knowledge boundary as the existing renderer:

- tile kind comes from game state, never image analysis;
- known/visible/remembered sets come from game state;
- renderer never infers geometry from texture edges;
- local light stays clipped to current visibility;
- authored images do not modify hit testing or camera geometry.

Non-seamless source material must not simply repeat one full bitmap per cell.
The execution plan must choose a deterministic sampling/cropping strategy keyed
only by presentation-stable inputs (for example coordinate/material/knowledge
salt), with no gameplay-RNG draw and no frame-clock randomness.

### D. Decorative cracks and rubble

Where matching authored overlays exist, they may be used as non-authoritative
decoration.

They must be:

- deterministic for the same presentation inputs;
- clipped to authoritative known/visible geometry;
- absent from unknown cells;
- non-colliding;
- non-loot;
- non-interactive;
- never visually confusable with an existing resource node, item, stairs,
  monster, or target marker.

Prefer sparse placement. Density is a visual acceptance question, not a gameplay
rule.

### E. Icons on existing actions

Icons may reinforce existing words/counts but may not replace them.

Candidate first surfaces:

- crawl controls such as Drink/Potion, Pack, Wait, Ascend, Descend;
- battle shelf actions where an exact matching asset exists, such as Potion,
  Firebolt, Mend, or overflow/More.

Rules:

- action labels/counts stay visible;
- enabled/disabled/armed state must still read without icon hue;
- no new control exists merely because an icon exists;
- a Melee asset must not create a Melee button while melee remains direct-map
  interaction;
- a broad custom Back-icon sweep is outside the base slice unless separately
  approved, because it touches navigation across many screens.

## Keep existing procedural regional identity initially

Sea-Cave strata, Ruined Keep fracture treatment, structural wall edges, and
runtime light remain in force when authored textures first land.

Implementation may tune their visual strength only if device evidence shows the
combined treatment is too noisy. Removing a previously accepted regional cue is
a material visual-design change and must be escalated rather than silently
"cleaned up."

## Explicit non-goals

- no core/content/save/RNG/rule/event changes;
- no procedural map-generation changes;
- no new gameplay resource, interactable, collision, target, or action;
- no icon-only replacement of labels/counts;
- no portrait system in this initial proposal;
- no tablet/landscape redesign;
- no asset-generated dynamic geometry;
- no automatic image analysis to derive terrain;
- no deletion of accepted procedural identity merely because authored assets
  are available;
- no broad navigation-icon replacement unless separately approved.

## Acceptance criteria

1. The app declares and loads the approved production asset set from one
   app-owned asset root, with one centralized reference vocabulary; no
   `packages/core` or `packages/content` file imports Flutter images or asset
   paths.
2. Environment illustrations appear only on matching approved surfaces and do
   not replace, obscure, or make unreachable any existing title, status,
   purpose, price, reason, control, or navigation affordance.
3. Crypt, Sea-Cave, and Ruined Keep authored material appearance is driven by
   the existing authoritative terrain/knowledge projection. Unknown cells remain
   unpainted; remembered cells remain distinct and unlit; visible local light
   remains clipped to current visibility.
4. For identical game/presentation state, authored material sampling and
   decorative overlay selection are stable across rebuilds/revisits and consume
   no gameplay RNG.
5. Authored textures/overlays do not change collision, map topology, hit testing,
   item/resource-node presentation, target marks, actor identity, stairs, or
   other gameplay facts.
6. Lowland roads remain on their existing procedural material unless the
   contract is explicitly amended for an approved road asset.
7. Every icon-enhanced control retains its existing action word and any live
   count. A state/action remains understandable in greyscale and with the icon
   ignored.
8. No new button/action is introduced solely to use an asset. Direct-map melee
   remains direct-map melee.
9. Existing Sea-Cave/Ruined Keep procedural identity and runtime lighting remain
   present at first integration; any removal/reduction that changes the accepted
   regional reading is explicitly reviewed.
10. Focused tests cover asset routing/catalogue behavior, environment-art
    presence/absence gates, deterministic dungeon asset selection, no
    unknown/remembered lighting regression, and icon-plus-label preservation.
11. From `packages/app`, canonical formatting, `flutter analyze`, and the full
    `flutter test` suite pass on the final tree; `packages/core` and
    `packages/content` remain unchanged unless the approved contract is amended.
12. `Medium_Phone` acceptance covers at minimum:
    - Stonebridge with its environment art;
    - Forge;
    - Tavern;
    - one representative Crypt delve;
    - one Sea-Cave delve;
    - one Ruined Keep delve;
    - a lowland-road encounter proving its procedural fallback is unchanged;
    - crawl controls in a state showing the maximum practical icon+label density;
    - battle shelf with every icon-enhanced action that is actually reachable.
    Greyscale twins cover every screen/state where hue could otherwise become
    meaningful.
13. Device evidence confirms no image-induced clipping/overflow, no important
    label/count loss, no hidden-geometry leak, and no obvious scene-entry or
    crawl-render hitch caused by repeated asset decoding.
14. Both device save slots are backed up before install/device acceptance and
    verified byte-identical afterward, following the existing epic device rule.

## Verification/review disposition

- Contract approval is required before consequential planning.
- This unit warrants execution-grade planning because asset lifetime/loading,
  deterministic sampling, renderer ownership, test seams, and device sequencing
  are consequential HOW.
- Integrated acceptance review is required after implementation.
- Security review is expected to be skipped unless implementation introduces a
  new external/network/file trust boundary.
- Multi-step device evidence should follow the current Flow verifier-capsule
  policy in the receiving stack.
