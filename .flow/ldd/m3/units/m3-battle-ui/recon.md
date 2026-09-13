# Recon — battle screen UI (`m3-battle-ui, story M3U unit B)

## VERDICT

The battle screen is buildable as a new widget tree over the existing
`GameViewState`/`GameBloc` with no core changes: "holds reach", stage
membership, "who acts next" and turns-to-arrival are all derivable from
public state (`monsters, `visible, `Actor.energy/reach, the exported
`scheduleMonsterTurns` and `computeFlowField`). The real work is app-side:
new derived state, a new gesture model (armed skill + tap-to-target), the
battle view's layout, and the stale mirrored `castRefusal` — which is now
drifted from core and unit B owns it. The app suite's text pins are the
blast radius; the two widget traps and phone sizing bind as always.

## State verified before measuring

- `main` @ `d576d1c` (unit A merged via PR #14), tree clean. Two read-only
  recon agents (view-state/bloc, renderer/layout); sharp claims re-verified
  by the architect at source (`CastPressed` shape, `schoolMarking, `GridGeometry.fit` usage). Prior app-seam recon (unit A's document)
  carried forward only where re-verified.

## The measurement

### View state and bloc (`packages/app/lib/game/game_bloc.dart`)

- `GameViewState` fields: `game, `log, `autoPath, `walkId, `pan, `hasFled` — nothing added by unit A; **app untouched by unit A,
  verified by diff**.
- Existing getters: `enemiesInSight` (the single home of "something is
  watching"), `knownSpells` (school-then-name sorted; each `Spell` carries
  `school.schoolMarking` `✳/✚/⛒, `schoolWord, `manaCost` — the skill-bar
  data is fully derivable today), `mana`/`maxMana`/`warded, `castRefusal`.
- **Stale mirror, now real:** the app's `castRefusal`/`_needsATarget` copy
  predates core's target-name branch; it knows nothing of "you cannot see
  that target". Unit B owns this drift.
- **`CastPressed` does not use the new `targetId`** — event carries only
  `spellId`; the handler constructs `CastSpellAction(event.spellId)`. No
  selection/targeting state exists anywhere in the view state.
- `TileTapped`: adjacent tap = `MoveAction` (bump-attack preserved); far
  tap refused while `enemiesInSight > 0`; walk interruption keys on
  `ActorNoticed`/`AttackHit(targetId == hero)` — ambush swings interrupt
  walks for free.
- Derived-new (nothing exists): adjacency, monsters-holding-reach, stage
  membership, turns-to-arrival, "who acts next". The app never reads
  `monster.hp, `monster.energy, `monster.reach, or `game.bound` today.
- Core's reach rule is private (`_holdsReach, step.dart ~745) but
  expressible from public pieces: `isOrthogonallyAdjacentTo, `chebyshevTo, `state.visible, `Actor.reach`.
- Open/close rule: derivable as a pure getter from `game` alone — no new
  field needed; view-scoped facts stay off `GameState` (the `hasFled`
  precedent); an armed-skill selection, if kept across rebuilds, follows
  the `hasFled` shape with the constructor-drop convention in mind.

### Turn strip — derivable, with two distance notions side by side

- `scheduleMonsterTurns` and `computeFlowField` are exported from core;
  `Actor.energy` is live clock state (post-step:
  `monsterEnergies − actCost` when ambush-charged). "Who acts next" =
  `scheduleMonsterTurns(heroSpeed, heroEnergy, speeds, energies).monsterTurns.first`;
  bound monsters sit out turns (`GameState.bound` applied on top). This is
  the exact call the engine's phase makes, so strip and engine agree by
  construction.
- Turns-to-arrival: flow-field step distance (walkable BFS) × speed.
  Stage membership is Chebyshev + `state.visible` — two different
  distance notions the UI holds side by side. Unreachable monsters have no
  field entry and stand still in the engine.

### Renderer and layout (`glyph_grid/glyph_plan/grid_geometry/game_screen`)

- Map draws via `GlyphGrid` (camera: hero-centred, fixed 36px cells, pan)
  painting `glyphPlan` cells. **No zoom/focus machinery exists**;
  `GridGeometry.fit` is test-only. A battle stage is a NEW widget tree,
  not a re-zoomed grid.
- `GameScreen` = `Stack[Column(map, _HitPoints, _Controls, _MessageLog(104)),
  if (isGameOver) _DeathOverlay]`. The battle view has two precedents:
  conditional layer in the Stack, or section-swapping in the Column.
- `_Controls`: one `Expanded`-divided row (Pick up / Gather / Drink /
  Pack (always — reading is never gated) / Flee / Move on / Ascend /
  Descend / Leave/Finish), with optional underfoot/here/ending rows above.
  Standing doctrine: the control row is full; the sixth control went to the
  status line instead.
- Status line is ONE string in a scale-down box (a device-pass defect made
  it so); pinned by `hud_depth_test, `world_screen_test` (multiple), `boot_wiring_test, `roster_session_test, `suspend_door_test`.
- Monster data for stage cards: `Actor.name` ("the ghoul"), `glyph, `hp`/`maxHp` (never read by the app yet); `namesIn` in
  `event_messages.dart` maps ids to names.
- Spell-row grammar exists three times already (pack `_SpellRow,
  character_screen ×2), all private — a fourth in the battle view is the
  extraction threshold (D65-D's rule: a third extracts).

### Events and sentences

- Unit A emitted **no new event types** (event.dart absent from its diff);
  ambush/lunge/spitter shots render through `AttackHit`/`AttackDodged` —
  the log's monster verb is the generic "claws", so a spitter shot reads
  "The spitter claws you for 2." A ranged-flavored verb or an ambush beat
  sentence is app-side work (`_beats`/`describeEvent` shape) or new core
  events (unit B's call).

### Widget tests

- Fixtures: `arenaGame` (7×5 ASCII map, monster helpers, spells/mana
  params), `PumpedApp` over `MemorySaveFiles, blocs never closed in
  widget tests; `_pushCrawl`/`_pushRoadFight` push the route over a
  button; `_onAPhone` = 1080×2424 @ dpr 2.625.
- Pinned text at risk: status-line strings (many files, listed in §4 of
  the render recon), control labels ('Flee', 'Move on', 'Pack (n)',
  'Cast', 'Drink (n)'), refusal sentences, `magic_surfaces_test`'s spell
  surface strings, `glyph_plan_test` draw-order pins.
- Traps (verbatim in build prompt): `find.textContaining` case-sensitive;
  `scrollUntilVisible` one-way; at least one phone-sized test.

## Is each inherited gate real?

- "Bands as controls" — real and easy here: unit B is app-only; the bot
  never reads widgets; all five band lines must hold byte-identical
  (re-run on the worker's own account anyway).
- "App untouched by unit A" — verified by diff (agent + architect).
- The mirrored `castRefusal` drift — verified real; unit B owns it.

## Findings that change the spec

1. **No core changes are required** — the battle view derives everything
   from public state. The one core-side temptation (exposing
   `_holdsReach`) should be resisted or made a deliberate export; the
   reach rule is three lines over public pieces.
2. **The stage needs a hero-sight asymmetry caveat:** stage membership via
   `state.visible` can disagree with the engine's `_holdsReach` in
   one-way-sight corner pairs (unit A's probe: 40 asymmetric pairs, hero-
   safe direction). The UI should mirror the engine's rule exactly and
   accept the bounded corner case, or pin which side wins.
3. **The extraction threshold is already crossed** — the spell-row grammar
   ships in three private copies; the battle skill bar is the fourth
   user. The spec should order the extraction (a shared spell-row/skill
   bar piece), not a fourth copy.
4. **Ambush flavor is a real gap in the log** — "The spitter claws you"
   undersells the unit's own mechanic; a ranged verb or an ambush-opening
   beat is cheap app-side and worth ruling.
5. **The Pack stays reachable in the battle view** (reading is never
   gated); the battle skill bar casts, the Pack reads.
6. **Walk-refusal interplay:** with the battle view open, auto-walk is
   already refused (`enemiesInSight > 0`); the battle view closing on
   disengage composes with that for free.

## Proposed shape of the work

Single unit `m3-battle-ui, app-only:

1. Derived state: `monstersHoldingReach, `arrivals` (turns-to-arrival), `upNext` (who acts before the hero again) as pure getters; the battle
   view's open/close rule derived, no persisted field.
2. The battle view: stage (holding-reach monsters as cards: glyph, name,
   HP bar, reach marking — greyscale-safe), turn strip (up next +
   arrivals), skill bar (marking + name + cost, wrap-flow, from the
   parked dock fork), tap-to-target; Pack stays; log stays.
3. Gestures: skill button arms a spell; tapping a stage card casts at it
   (`CastPressed(spellId, targetId: …)`); tapping without an armed skill
   is the regular attack; tapping the map area is unchanged.
4. The mirrored `castRefusal` updated to core's contract (target branch
   included); the spell-row grammar extracted to a shared piece (fourth
   copy forbidden).
5. Riders: follow-up 31 (skills-row crowding, "Blacksmith0") and
   follow-up 30 (status line on a phone — the AVD pass covers it).
6. Widget tests: battle view open/close, stage cards, skill bar, targeting
   gesture, refusals; phone-sized; the traps restated.

## Hazards

- Every text pin listed above; the status line is one string by design.
- `GameViewState` constructor-drop convention: a field not named in a
  handler's rebuild silently resets (the `pan` dartdoc is the warning).
- The AVD pass is mandatory for this unit (UI): full save-aside ritual,
  storage trap, `run-as stdin` restore, greyscale variant of acceptance
  shots.
- Environment traps restated verbatim in the build prompt (as always).

## What this recon did NOT check

- The app suite was not run (read-only recon); the worker re-derives all
  counts.
- The full `glyph_plan_test`/`grid_geometry_test` pin inventory.
- Whether any engine path leaves a monster in-reach-but-invisible beyond
  the documented asymmetry (bounded, probed by the worker's report).
- The town screens beyond `character_screen`'s spell rows.