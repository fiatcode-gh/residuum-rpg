# Unit 8 — World Graph and Theme Parity Contract

Status: **draft for user approval; planning and implementation are separate authorization steps.**

## Outcome

Replace the world screen's vertical place menu with a portrait-first spatial route
diagram for the shipped five-node world. Make the Sea-Cave, Ruined Keep, and
their road encounters read as places with distinct deterministic material and
lighting treatment, while preserving every existing world, travel, encounter,
crawl-entry, save, and roster behavior.

After this unit:

- the world reads as a small geography: routes, distance, discovery, and the
  hero's current location are visible together instead of distributed through
  list rows;
- a discovered place is still a labelled, reachable control; selecting it still
  asks before days are spent and uses the existing travel pipeline unchanged;
- the Sea-Cave is water-worn and tidal; the Ruined Keep is fractured masonry
  and iron-stained earth; their road fights share the regional material rather
  than falling back to the Crypt's look;
- a road fight still states its road-only exit, and a dungeon still enters,
  resumes, abandons, and persists exactly as source defines today.

This unit changes presentation and composition only. It must not change rules,
world content, travel timing, encounter odds, prices, discovery state, save
shape, or core/app ownership.

## Locked product decisions

### Spatial route diagram, not a reskinned menu

The world is a fixed, phone-first diagram of the current five-node graph:
Stonebridge, Northgate, The Crypt, The Sea-Cave, and The Ruined Keep. It is not
a procedural map system and must not imply terrain, paths, or destinations
outside source content.

Each discovered node is a large labelled touch target. Its town/dungeon kind,
name, current-location state, and reachability are carried by shape, word,
position, and value contrast, never by hue alone. A route shows its day cost
and current danger. Only a legal one-road destination can begin travel; the
existing confirmation remains the only action that spends a day.

An unheard location remains an inert `?` at its fixed diagram position. It
reveals neither its name nor kind; its route does not expose cost or danger.
This preserves the existing discovery gate while retaining the approved
spatial-map reading. A rumor still changes discovery only through `WorldBloc`
and the existing content-derived result.

The header keeps the standing-place, day or journey state, health, carried
gold, and banked gold. Heroes remains a distinct global world action, not a
town door or map node. The current-location action area continues to own town
entry, dungeon entry, the resume/delve-abandon fork, camp warning/loss, and
road-resume control. Its sentences, pending-door behavior, and route-stack
semantics stay unchanged.

### Route-linked regional material

Presentation receives explicit, ephemeral route/dungeon theme context. Core
`GameState`, content graph data, RNG streams, save documents, and `WorldBloc`
remain authoritative and unchanged. Theme context is derived from the existing
node or route at the app boundary; it is never inferred from glyphs, serialized,
or used to make a gameplay decision.

The Crypt keeps its approved cold-charcoal stone and restrained warm-light
baseline. The new regional identities are:

- **Sea-Cave:** water-worn slate and stratified wet stone, sparse tide-washed
  wear, and cool reflected light. Its visual identity is also carried by
  texture, edge treatment, and value hierarchy, not blue/green hue.
- **Ruined Keep:** broken ashlar, fractured masonry, and restrained
  iron-stained earth with warm, local light. Its visual identity is also carried
  by squared broken structure, cracks, and value hierarchy, not brown/red hue.
- **Roads:** lowland roads use a neutral worn track. The Sea-Cave spur uses the
  Sea-Cave material and the Ruined Keep spur uses the Keep material. A road
  fight receives its route's presentation context, without changing its
  creatures, geometry, loot, exit rule, log, or encounter outcome.

The unit extends the existing deterministic material system rather than adding
assets, animation, a second field-of-view calculation, or global randomness.
Unknown and remembered geometry retain the Unit 2 knowledge boundary; lighting
is clipped to authoritative visible space. The material must stay legible in
greyscale and retain the Unit 2 value ladder: unknown, remembered, visible,
structural/selected, then actors and important symbols.

### Road encounters remain the same game

Road fights continue to open over the world and return through the existing
`RoadFightOver` seam. `The road`, edge-only escape, no stairs, battle/flee/clear
outcomes, carry-over, autosave exclusion, and resumed journey behavior remain
source-true. A regional presentation label may name the road's setting, but it
must not alter or hide the existing road-only exit explanation.

### No art pass or HUD chrome

No static image asset, `assets/` declaration, portrait slot, generated
background, or full icon language is introduced. The post-Unit-8 art bible
remains deferred.

Unit 9 owns the crawl depth header, labelled HP/Mana bars, and icon control
chips. Unit 8 must not take any of them. No new text mark codepoint is needed;
if one becomes unavoidable, it requires device proof that Android renders it as
text rather than colour emoji or tofu.

## Boundaries and invariants

1. `packages/core` and `packages/content` are untouched. World nodes, routes,
   days, danger, discovery, rumors, encounter tables, dungeon identity, loot,
   saves, and deterministic RNG output do not change.
2. `WorldBloc` continues to be the sole owner of `Whereabouts`, journey days,
   notices, road log, road fights, and rumor-driven discovery. `TownBloc`
   continues to own the profile, crawl camp, and entry/refusal answers.
3. `WorldScreen` remains presentation and input only. The session in `main.dart`
   remains the only cross-bloc wiring boundary for town arrival, road fights,
   roster choices, and crawl entry.
4. Every current control remains reachable with the same observable result:
   travel confirmation/cancellation, resumed travel, town entry, dungeon entry,
   resume, delve anew, cross-dungeon abandonment confirmation, camp warning and
   loss, Heroes, and road-fight continuation.
5. The world map exposes no gameplay fact unavailable through the approved
   world surface except the explicitly approved route day cost and current
   danger. Undiscovered places expose no name, kind, cost, or danger.
6. The four-region crawl rule and all Unit 2 material locks remain binding.
   Theme treatment is rendering-only and cannot reveal unknown geometry,
   displace actors, change grid hit-testing, or consume game RNG.
7. Accessibility is non-negotiable: every location, route condition, discovery
   state, and regional identity reads in greyscale through shape, word, position,
   texture, and/or value. No meaning is hue-only.
8. Replaced world-menu composition is deleted. Do not retain a hidden list-view
   fallback, compatibility API, or duplicate graph projection.

## Explicit non-goals

- No new world nodes, routes, town, dungeon, rumor, road creature, encounter
  table, travel cost, danger rule, or balance change.
- No map pan/zoom, tablet layout, generated overworld terrain, walkable world,
  or generic future-map layout engine.
- No core/content model, save format, RNG, game-rule, BLoC ownership, or
  navigation-stack change.
- No static art, asset pipeline, portraits, background art, animation,
  particle effects, or new icon family.
- No crawl HUD chrome, depth-header, HP/Mana bar, or icon-control work (Unit 9).
- No town-room or Character interior reboot beyond preserving their existing
  world entry routes.

## Acceptance criteria

1. On a phone-sized portrait surface, the world presents the five-node shipped
   graph as a spatial route diagram. Discovered nodes are labelled interactive
   targets; unheard nodes are fixed inert `?` markers with no leaked name, kind,
   cost, or danger.
2. Each displayed known route communicates its day cost and current danger.
   Only a one-road discovered destination can be selected, and travel still asks
   before any day is spent.
3. The header/context area preserves standing or journey status, day, health,
   carried gold, banked gold, current notices, road log, town entry, dungeon
   entry, the full camp fork, resume travel, and Heroes as a world action.
4. Travel, rumors, discovery, town arrival, save writes, road-fight pause and
   return, road death, dungeon entry, camp loss, and cross-dungeon abandonment
   retain their current observable behavior and source wording.
5. The Sea-Cave and Ruined Keep each have a materially distinct deterministic
   terrain and light treatment beyond a palette swap. Their own road encounters
   inherit the matching regional treatment; lowland roads remain visually
   distinct and neutral.
6. The material pipeline remains deterministic, consumes no gameplay RNG,
   preserves existing tile/input geometry, and draws no unknown geometry or
   light outside authoritative visibility.
7. No important state, category, regional identity, or interactable control is
   hue-only. No new mark codepoint is introduced without Android rendering proof.
8. Focused world, palette/material, and road-encounter tests prove the preserved
   transitions and new presentation boundary. `dart format --set-exit-if-changed`
   on touched files, `flutter analyze`, and full `flutter test` pass from
   `packages/app`.
9. On `Medium_Phone`, colour evidence shows a fresh/discovery-gated world,
   fully discovered world, active journey, Sea-Cave and Ruined Keep delves, and
   road fights on the lowland, Sea-Cave, and Ruined Keep routes. Greyscale twins
   cover every frame with a non-neutral regional palette. Both device save slots
   are backed up before install and byte-identical afterward. Tablet work stays
   out of scope until the phone composition is accepted.

## Verification and review disposition

- **Acceptance review:** required after the integrated implementation. It must
  check plan conformance, ownership boundaries, discovery leakage, travel and
  road-fight preservation, deterministic material constraints, and accessibility.
- **Device gate:** required after acceptance-review findings are closed. The
  AVD must be user-started; preserve and verify both save slots around install.
- **Security review:** skip by default. This is local Flutter presentation over
  existing state with no new external boundary.
