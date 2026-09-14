# Unit 3 — Crawl Interaction Reboot: Execution Plan

Derived from `units/unit-3/CONTRACT.md` (approved 2026-09-14). Base revision
`affc138` (main HEAD, Unit 2 merged). No production code written at plan time.

## Boundary

Single sequential owner. One non-isolated feature checkout
(`residuum-visual-reboot-3`) from `affc138`. All tasks run in order in that one
workspace; the tree compiles fully only after the last task, because the
armed-attack symbols are removed in task 01 and their last presentation
references retire in task 03.

## Locked decisions (do not drift)

- Melee = `MoveAction(direction)` into the occupied adjacent tile, dispatched
  only when no spell is armed. Core `_moveHero` already turns that into the
  bump attack; no core change.
- Map-targeted cast = `CastSpellAction(spellId, targetId: monster.id)` for any
  **visible** monster (matches core `_castRefusal`; fixes the dock's
  adjacency-only cast path). Dispatched only when a spell is armed and the tap
  lands on a monster in `armedTargets`.
- Armed + tap any tile that is not a legal target → disarm, no move, no turn.
- `armedAction` (`ArmedAction`/`ArmedAttack`/`ArmedSpell`) collapses to a single
  `String? armedSpellId` field on `GameViewState`. The sealed hierarchy has one
  surviving leaf after Attack removal and is deleted, not shimmed.
- `AttackArmed`, `StageCardTapped`, `_onAttackArmed`, `_onStageCardTapped`, and
  `_outOfReach` are removed. Stage cards become inspect-only; the "walk to it"
  sentence is retired with the dock's cast path.
- Readied = first `readiedSpellCount` (3) of `state.knownSpells` (school, then
  name order) + Wait; the rest in overflow. No pinning, no persistence.
- Self-cast (Mend/Ward) still casts immediately from the shelf or overflow;
  target spells (bolt/bind/banish) arm then cast on the map.
- Wait appears exactly once: in the combat shelf when `isBattleOpen`, and in the
  exploration controls when `isEncounter && !isRoadClear && !isBattleOpen`.
- Recenter resets pan to zero without disarming or spending a turn. Ease-back is
  deferred; the camera keeps its instant snap.
- Inspection is presentation-only: never dispatches, never mutates.

## Interfaces

- `GameViewState.inspectTargetAt(Position) → Actor?` — the enemy a map tap should
  open for inspection, else null. Pure; names the sheet, dispatches nothing.
- `RecenterPressed` event + `_onRecenterPressed` — pan to zero, carrying
  `walkId`/`autoPath`/`armedSpellId` (mirrors `_onMapPanned`).
- `heroOffScreen(Size viewport, GridGeometry geometry, Position focus) → bool` in
  `grid_geometry.dart` — pure, testable, uses the clamped camera origin.
- `DungeonSceneHost` gains `onLongPress: ValueChanged<Position>`; `_DungeonScene`
  mixes in `LongPressCallbacks` and emits the tapped position.

## Task order

1. `plan-tasks/01-bloc-interaction.md` — armed-state collapse + `_onTileTapped`
   rewrite + `inspectTargetAt` + `RecenterPressed` + `heroOffScreen`.
2. `plan-tasks/02-scene-input.md` — scene long-press callback + projection type.
3. `plan-tasks/03-shelf-and-screen.md` — combat shelf, overflow sheet, inspect
   gating, long-press wiring, recenter overlay; remove Attack presentation.

## Non-goals

No core/content/save/economy/balance/generator change. No timeline, no
duplicate identity, no log drawer, no pinning/persistence, no pinch zoom, no
ease-back animation, no second FOV/lighting simulation.

## Plan quality gate

- **COR — run.** Melee/cast/disarm precedence in `_onTileTapped` is specified
  branch-by-branch; the visible-vs-adjacent cast contract is reconciled against
  core `_castRefusal`; the inspect getter is pure and side-effect-free; recenter
  mirrors the pan handler's non-disarm rule.
- **TTC — run.** Every behavior change maps to named bloc/widget tests with Red
  evidence listed per task; the retired `_outOfReach` and map-tap-refusal pins
  are identified for rewrite, not silently re-pinned.
- **CRF — run.** The shelf keeps one Wait owner; the armed-sealed-class is
  collapsed rather than kept as a one-leaf hierarchy; the overflow sheet reuses
  `SpellRow` rather than a second spell grammar.
- **SEC — skip.** No external input, persistence, or trust boundary changes.

Residual risk deliberately left to implementation evidence: the exact
`LongPressCallbacks` recognition threshold is Flame's default (Flutter
long-press); if it collides with `DragCallbacks` on the scene the executor
reports it and we adjust — a known, bounded integration point, not a design
fork.
