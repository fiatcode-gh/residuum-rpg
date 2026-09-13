# Unit 1 — Flame Dungeon-Scene Foundation

Status: accepted on 2026-09-13.

## Goal

Replace the crawl's `CustomPainter` viewport with a Flame `GameWidget` embedded
inside the existing Flutter `GameScreen`, proving a crypt floor remains fully
playable without changing any authoritative game rule or current interaction
behavior.

## Product contract

- Flame renders only the dungeon viewport. Flutter continues to own routing,
  HUD, battle dock, controls, log, sheets, overlays, and all non-dungeon
  screens.
- `GameBloc` remains the sole app-side action boundary. Core `GameState` and
  `step` remain the sole gameplay authority.
- The scene consumes an immutable app-owned presentation snapshot derived from
  `GameViewState`. It must not own independent HP, actors, fog knowledge, RNG,
  turn timing, inventory, actions, or persistence.
- The snapshot contains only render/input facts required by the current crawl:
  map dimensions and tiles; visible/explored knowledge; nodes; visible litter
  and monsters; hero; marked target IDs; palette; hero focus; and pan.
- Scene hit-testing emits existing `TileTapped(Position)` and
  `MapPanned(Offset)` intents through callbacks. It never decides movement,
  pathing, combat, target legality, or action dispatch.
- Preserve the existing Unit 1 interaction behavior exactly:
  - fixed 36 logical-pixel camera cells, hero-focused clamped pan, and no
    pinch zoom;
  - adjacent empty-tile movement and distant explored-tile auto-walk;
  - adjacent monster map taps retain the current watched refusal;
  - current armed action, battle dock, explicit Attack shelf control, spell
    behavior, Wait, contextual controls, exits, and log behavior remain;
  - a stepped action resets pan and armed state as it does today.
- Preserve existing rendering semantics before Unit 2: logical terrain glyphs,
  remembered versus visible knowledge, node/litter/monster visibility, current
  draw order, dungeon palette, and greyscale-safe target marking. Unit 1 is not
  the graphical-texture, lighting, fog-treatment, timeline, or shelf redesign.

## Implementation boundary

- Add Flame only to `packages/app`; `core` and `content` retain zero Flutter or
  Flame imports.
- `GameScreen` replaces its `GlyphGrid` slot with a dedicated stateful dungeon
  scene host. That host owns one Flame game instance across Flutter rebuilds;
  it synchronizes the latest immutable snapshot rather than constructing a game
  in `build`.
- Keep the current pure `glyphPlan` and camera geometry rules as the verified
  source projection. Extract only renderer-neutral geometry/projection code
  where Flame needs it; do not duplicate or reinterpret game rules inside
  components.
- Flame components are disposable views of snapshot facts. A scene sync removes
  actors/items no longer in the snapshot and updates the rest from the latest
  snapshot. Animation is optional and must never delay or alter the next
  authoritative state.
- Do not add an end-user renderer switch. The old painter may remain only as a
  short-lived comparison aid during development and must be removed, with its
  temporary wiring, before this unit is accepted.

## Non-goals

- No core/content/rules/save/economy/balance/generator changes.
- No direct map melee, map target selection, favorites/overflow, timeline,
  duplicate labels, log drawer, camera easing/recenter control, visual texture,
  dynamic lighting, fog redesign, or non-dungeon redesign.
- No full-app Flame migration, sprites, pinch zoom, static art, or asset
  pipeline.

## Acceptance criteria

1. A crypt floor renders through Flame inside the existing `GameScreen`; no
   `CustomPainter` crawl path remains after acceptance.
2. On the current phone widget surface, tap movement, distant auto-walk,
   clamped pan, battle docking, armed targeting through the existing dock,
   explicit Attack, spells, Wait, contextual crawl controls, and exits produce
   the same core state and log outcomes as before the renderer replacement.
3. The scene shows exactly the same knowledge boundary as `glyphPlan`: unknown
   cells reveal no geometry; remembered terrain/nodes remain distinguishable;
   current actors and litter are visible only when the rules expose them.
4. Scene input is observable as existing BLoC events/actions; no Flame
   component dispatches core actions or mutates `GameState` directly.
5. App-focused widget tests preserve the interaction and projection contracts;
   affected tests migrate away from assertions that require `GlyphGrid` as an
   implementation detail. Existing behavior-characterization tests change only
   where their renderer probe must target the scene host instead.
6. Formatter, app analysis, and `flutter test` run from `packages/app` pass.
   Final acceptance includes the M3 phone-sized AVD pass and greyscale evidence
   under `.flow/evidence/visual-reboot/` without installing on a user device.

## Risks and traps

- Preserve the one-way boundary: a Flame hit is an intent, never a rule.
- Do not recreate camera math in a second, drifting coordinate system.
- `GameWidget` must keep its game instance across Flutter rebuilds. Flame's
  documentation explicitly warns against constructing the game in `build`;
  use state-owned lifecycle or the managed constructor.
- The current test suite deliberately pins adjacent monster map-tap refusal.
  Do not advance the Unit 3 melee decision while proving Unit 1.
- M3 environment traps bind: no root pubspec, device save protection before any
  install, and the AVD is a final acceptance gate.
