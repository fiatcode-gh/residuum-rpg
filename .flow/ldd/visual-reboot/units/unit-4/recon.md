# Unit 4 — Turn Timeline and Presentation Identity Recon

Date: 2026-09-14
Status: complete; no production code changed.
Base: `4164741` (`main`, Unit 3 merged). The working tree has only the pre-existing untracked `.omp/` directory.

## Authority

- `LEDGER.md` adopts the approved handoff's Unit 4 direction: activation queue, literal repeated fast activations, encounter-local duplicate identity, timeline-to-map inspection, and identity-aware log names.
- The handoff's section 7 locks the player-facing outcome: the queue shows the hero's current activation, each immediate scheduled activation, and the hero's next activation; duplicate labels are presentation identity only; a timeline token must not spend a turn or reveal an unknown actor.
- Unit 3 is present on `main` at `4164741`. Its AVD/greyscale acceptance evidence is still unavailable on this host; that evidence debt is recorded separately and is not a source or contract dependency for Unit 4.

## Verified seams

- `GameViewState.upNext` in `packages/app/lib/game/game_bloc.dart` already calls core `scheduleMonsterTurns` with post-spend hero energy. It returns exact ordered monster instances and deliberately repeats a fast actor. The old `arrivals` projection is estimated travel prose, not an activation sequence.
- Core `scheduleMonsterTurns` in `packages/core/lib/src/engine/energy.dart` stops when the hero is next and guarantees the hero wins a shared threshold. Unit 4 must consume this result, not reproduce clock arithmetic in the app.
- `BattleDock` in `packages/app/lib/game/battle_view.dart` currently combines reach-holder stage cards with `_TurnChips`, which prints `NOW — <raw name>` and `IN n — <raw name>`. The stage/cards and prose are the Unit 4 replacement boundary; the live Flame map remains visible.
- `glyphPlan` projects visible monsters by stable core id into `GlyphCell`s. `DungeonSceneSnapshot.fromViewState` is its sole production caller. The scene already retains components by `(layer, entity id)` and is the safe map-badge/highlight boundary.
- `event_messages.dart` formats events from a pre-step id-to-name map. `GameBloc._describe` owns that call and can supply presentation names without changing core event shapes.
- `GameScreen` delegates map taps to the bloc and only routes inspection presentation. A timeline interaction therefore needs a view-only bloc event; it must never dispatch a core action.
- `GameState` uses stable actor ids only within a floor/encounter: `ghoul-1` can be a different actor after a floor transition. `GameViewState` must own the presentation identity context and reset it on an arrival, never persist it into saves or core.

## Reconciled design decisions

- The queue is the direct projection `[YOU] → upNext → [YOU]`. It ends at the hero's next activation. No `NOW`/`IN n` prose, arrival estimates, or second scheduler is retained.
- The queue contains only the hero and currently known monster actors. An unknown actor truncates the visible queue rather than appearing as an anonymous or named token; no timeline state may disclose unseen simulation state.
- Encounter identities allocate a deterministic superscript index once from the encounter/floor's stable monster-list order, grouped by the same raw glyph and name. The index is stable while the actor lives. A suffix renders only when at least two members of that group are known, so a visible actor does not disclose an unseen duplicate.
- Identity context carries known actor ids and labels through view-state copies. It includes an `ActorNoticed` actor before that event is formatted, allowing the first newly noticed duplicate to receive the same label used everywhere else. It resets on an ascent/descent or new bloc/encounter.
- The map keeps its semantic glyph and renders the identity as a compact badge, rather than replacing the glyph text. A selected timeline actor receives a second shape-based map outline that remains distinct from the existing targeting rectangle in greyscale.
- A visible timeline token sets a view-only selected actor and camera focus. It centers that actor, highlights it, and opens its existing inspect sheet; no turn, target arm, gameplay state, RNG, or log entry changes. Any game action clears the selection and returns camera focus to the hero.

## Scope boundary

No core/content/save/balance/generator change. No log drawer, action-shelf work, camera easing, generic animation loop, battle board restoration, or second visibility computation. Unit 5 owns the log viewport/drawer after Unit 4 makes its strings identity-correct.
