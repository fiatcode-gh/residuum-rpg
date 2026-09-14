# Unit 4 — Turn Timeline and Presentation Identity

Status: **reconciled from the approved visual-reboot handoff, 2026-09-14.**
Implementation requires normal local execution authorization.

## Goal

Replace raw scheduling prose and duplicate-ambiguous actor names with one
interactive, accessible activation timeline. A player facing two same-name
enemies and one fast actor can identify every known actor on the map and state
the immediate activation sequence without reading clock explanation text.

## Authority

- Follows accepted Units 1–2 and merged Unit 3.
- The visual-reboot ledger plus handoff section 7 are the product authority.
- `GameBloc` and core `GameState`/`step` remain authoritative. Flame, labels,
  selection, and camera focus remain app presentation only.

## Product contract

### Activation timeline

- While `isBattleOpen`, a compact token row replaces the stage cards and the
  `NOW` / `IN n` chip prose. The map remains the live primary surface.
- At a hero decision point, the row projects exactly `[YOU] → upNext → [YOU]`:
  the current hero activation, every monster activation the existing core
  scheduler says is owed before the hero acts again, then the hero's next
  activation. A fast actor therefore appears once per owed activation.
- The app consumes `GameViewState.upNext`; it must not copy or approximate the
  energy clock. Shared-threshold and bound-monster behaviour remain core's
  existing behaviour.
- The timeline shows the known prefix only. A monster outside current player
  knowledge truncates subsequent non-hero tokens; it is never named, counted,
  marked, or represented by a mystery placeholder.
- Existing stage cards and `arrivals` / `IN n` prose are removed. Enemy detail
  remains available from map long-press/non-adjacent tap and timeline tokens.

### Encounter-local presentation identity

- Core actor ids and names remain unchanged. Unit 4 introduces no core ids,
  serialization, content fields, or save-format change.
- Every actor gets an app-only identity from its raw `(glyph, name)` group and
  deterministic stable monster-list order for the active floor/encounter.
- Members of a duplicate group have a fixed superscript badge (`g¹`, `g²`) for
  their lifetime. The badge is rendered only after at least two members of its
  group are known, preventing a visible actor from revealing an unseen
  duplicate. A known survivor keeps its assigned index after another dies.
- Identity is used consistently wherever ambiguity matters: map badge,
  timeline token, target mark association, inspect title, and event-log actor
  names. Single known actors retain the unbadged existing presentation.
- The app tracks known actor ids and includes an `ActorNoticed` actor before
  formatting its announcement. This makes a newly noticed duplicate's first
  log entry agree with its map and timeline identity.
- Identity context is view-scoped and resets on each ascent/descent, road
  encounter, or new `GameBloc`. It is never persisted or placed in core state.

### Timeline inspection and map focus

- Tapping a visible monster token selects it without spending a turn. Selection
  centers the map camera on that actor, applies a shape-based selected outline,
  and opens the existing inspect sheet using the same presentation label.
- The token interaction does not dispatch a core action, mutate gameplay/FOV/
  RNG/log state, arm or disarm a spell, or expose an actor outside knowledge.
- A game action clears selection and returns focus to the hero. Manual map pan
  and recenter retain their Unit 3 semantics; recenter returns to the hero.
- The selected outline and targeting outline are distinct shapes, so selected,
  targetable, and selected-targetable actors remain readable in greyscale.

## Presentation architecture

- A small immutable app-only presentation-identity value owns label allocation,
  known-actor tracking, and display names/glyph badges. `GameViewState` carries
  it through view-only transitions and rebuilds it only at the defined
  encounter boundary.
- A pure activation-queue projection consumes `upNext` plus current knowledge.
  It yields typed hero/actor tokens rather than presentation strings.
- `glyphPlan` receives actor presentation facts and preserves semantic glyphs;
  `GlyphCell` carries an optional monster badge and selected flag. Flame renders
  the badge and shape treatment without interpreting core ids or rules.
- `GameBloc._describe` supplies presentation names to `describeEvent`; core
  events remain untouched. `showEnemyInfo` receives the app presentation label
  instead of recomputing actor naming in a widget.

## Non-goals

- No core/content/save/economy/balance/generator change.
- No log drawer, log scrolling, or structured log history (Unit 5).
- No shelf, spell, pack, character, town, or world redesign.
- No battle board, `NOW`/`IN n` compatibility path, arrival estimate, second
  scheduler, second FOV, or generic animation loop.
- No persisted identity, cross-floor identity, pinning, or camera easing.

## Acceptance criteria

1. In a battle with a speed-20 duplicate ghoul and another ghoul, the visible
   row reads hero → first ghoul → first ghoul → second ghoul → hero, with the
   same fixed labels as the map.
2. A duplicate's map badge, timeline token, targeting association, inspect
   title, and combat-log name agree. A singleton remains unbadged.
3. Revealing a second same-name actor adds deterministic badges without
   revealing a hidden actor beforehand; a surviving duplicate keeps its badge
   after the other dies.
4. A hidden due actor produces no token, label, badge, highlight, or count;
   the timeline stops at the visible prefix.
5. Tapping a visible timeline token centers and shape-highlights the matching
   map actor, opens inspect, costs no turn, and leaves gameplay, targeting,
   RNG, and log unchanged.
6. Target and selected shapes remain distinguishable in a greyscale reading.
7. Legacy stage cards, `NOW`/`IN n` prose, and arrival estimates have no
   production path or test contract left.
8. No core/content package gains Flutter/Flame dependencies; no save document
   gains presentation identity.
9. App formatting, `flutter analyze`, and full `flutter test` from
   `packages/app` pass with focused identity, queue, no-leak, and timeline
   interaction proof.
10. Final Pixel_10/phone AVD evidence shows duplicate labels, a repeated fast
    activation, timeline inspect/focus, and greyscale-safe selected/target
    states.

## Verification strategy

- Pure view-state tests: queue order with repeated fast actors; shared-threshold
  and bound preservation; known-prefix truncation; deterministic labels;
  late-revealed duplicate; survivor label stability; floor/encounter reset.
- Event-message tests: pre-step attack/death/notice sentences use the same
  presentation identity as the active map.
- Projection/scene tests: glyph semantics unchanged; labels and selected versus
  target marks are distinct; no hidden actor label reaches the projection.
- Widget tests: activation tokens replace old stage/prose, token interaction
  opens inspect and focuses the visible actor at no turn cost, and a phone-sized
  layout remains exception-free.
- Full `packages/app` suite + analyzer, then Pixel_10 colour and greyscale
  evidence.

## Review disposition

- COR: run — clock projection, knowledge boundary, identity lifetime, and input
  ownership are consequential.
- TTC: run — order, duplicate identity, no-leak, and no-turn-cost contracts need
  behavioural proof.
- CRF: run — identity must have one owner rather than diverging in map/timeline/
  log widgets.
- SEC: skip unless implementation introduces an external or trust boundary.

## Risks and traps

- Do not infer a second scheduler or change core turn order.
- Do not number by the currently filtered list; that renumbers a survivor.
- Do not let a duplicate suffix disclose an unseen actor.
- Do not keep stale raw-name strings or legacy cards as compatibility UI.
- Do not turn token selection into combat input or move a hidden actor into view.
- Do not use hue as the only selected or target state.
