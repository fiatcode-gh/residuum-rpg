# Task 03 — Combat shelf, overflow, inspect gating, recenter

Owner: sole sequential owner, non-isolated checkout `residuum-visual-reboot-3`.
Final task; the tree compiles fully only after this one.

## Scope

`packages/app/lib/game/battle_view.dart`, `packages/app/lib/game/game_screen.dart`
and their tests (`battle_view_test.dart`, `battle_characterization_test.dart`,
`battle_flow_characterization_test.dart`, plus any new widget test). No
core/content edits. `inventory_screen.dart` (Pack) is unchanged — its
`CastPressed(spellId)` nearest-fallback path stays.

## Change

### Battle dock (battle_view.dart)

- Remove `BattleSkillBar` entirely (the full spell wrap + Attack + Wait bar).
- Remove the `Attack`/`AttackArmed` presentation; stage cards become
  inspect-only: `_StageCard.onTap` always calls `showEnemyInfo(context, monster)`.
  The `marked`/`armedTargets` border on stage cards is removed (targeting marks
  live on the map now).
- Keep `_StageCard`, `_TurnChips`, `_EnemyInfoLine`, `showEnemyInfo`, `dockBacking`
  unchanged in form and wording. The dock now renders reach-holders + turn chips
  only.
- Delete `_BarButton` (now unused).

### Combat shelf (new)

Add a `BattleShelf` widget (in `battle_view.dart` or `game_screen.dart` — the
local implementation choice; prefer keeping shelf widgets beside the screen that
composes them). It renders when `state.isBattleOpen`:

- readied spells: first `readiedSpellCount` (3) of `state.knownSpells`, each as
  a `SpellRow`-style button (marking + name + cost) that:
  - target spell → `SkillArmed(spell.id)` (arm; tap again to disarm is the
    `SkillArmed(null)` path if already armed — reuse the existing toggle);
  - self-cast (Mend/Ward) → `CastPressed(spell.id)` immediately;
- `+N` overflow button (N = `knownSpells.length - readiedSpellCount`) opening a
  bottom sheet listing **every** known spell (school marking, name, cost,
  effect via `effectOf`), each arming/casting exactly as the readied row does;
- quick-drink control (reuse the `_Controls` quick-drink behavior) when a potion
  is carried;
- Wait control → `WaitPressed()`.

The armed state must be visible by border + word (`— armed`), same
greyscale-safe grammar the old bar used.

### Game screen (game_screen.dart)

- Replace the `if (state.isBattleOpen) BattleSkillBar(...)` slot with the new
  `BattleShelf`.
- Remove the `if (state.isEncounter && !state.isRoadClear)` Wait control from
  `_Controls`; Wait now lives in `BattleShelf` (combat) and stays in `_Controls`
  only for the road fight with `!state.isBattleOpen`. Verify the gate:
  `isBattleOpen` is false in a cleared fight, so `Move on` still shows.
- Inspect gating on the map: `DungeonSceneHost.onTap` in `GameScreen` becomes a
  closure that:
  - if `state.armedSpellId != null` → `bloc.add(TileTapped(position))` (bloc
    decides cast vs disarm);
  - else if `state.inspectTargetAt(position) case final Actor monster` when that
    monster is **not** orthogonally adjacent → `showEnemyInfo(context, monster)`
    (inspect, no dispatch);
  - else → `bloc.add(TileTapped(position))` (melee / move / refusal).
  This keeps all meaning in the bloc and only routes inspect, which is
  presentation-only.
- Long-press wiring: `DungeonSceneHost.onLongPress` →
  `state.inspectTargetAt(position) case final Actor monster` →
  `showEnemyInfo(context, monster)`; else ignore.
- Recenter overlay: when `heroOffScreen(...)` is true for the current viewport,
  render a small `Recenter` affordance over the map that dispatches
  `RecenterPressed`. Compute with `GridGeometry.camera(size, w, h,
  hero.position, state.pan)` and `state.game.hero.position`.

## Proof (Red first)

- Widget tests: combat shelf shows readied spells + overflow + Wait and no
  `Attack` text; overflow sheet lists all known spells; tapping a target-spell
  row arms (map shows marks); tapping a non-adjacent monster with nothing armed
  opens the inspect sheet and does not dispatch; long-press opens the sheet;
  tapping an adjacent monster melees; recenter appears only when the hero is
  off-screen and resets pan.
- Update `battle_view_test.dart` and `battle_characterization_test.dart`: the
  old `AttackArmed`/`StageCardTapped` drives become `TileTapped`-based melee and
  `SkillArmed` + `TileTapped` casts; assertions on `Attack — armed` and the
  `_outOfReach` walk sentence are removed (both retired). Do not re-pin them.
- Keep the Pack (`inventory_screen`) cast tests green — they use
  `CastPressed(spellId)` without a target and must still pass unchanged.

## Escalate when

- A reach-holder's stage card tap must cast/inspect in a way that contradicts
  "inspect-only" in this contract.
- The `isBattleOpen`/`isEncounter`/`isRoadClear` Wait gating leaves a road fight
  with no Wait affordance in any reach state; that would be a contract gap, not
  an implementation detail.

## Verification ownership

- Focused proof: `flutter test test/battle_view_test.dart
  test/battle_characterization_test.dart
  test/battle_flow_characterization_test.dart` from `packages/app`, plus any new
  shelf/inspect/recenter widget test.
- Formatter: `dart format` on `battle_view.dart`, `game_screen.dart`, and
  touched tests.
- Focused static: `flutter analyze` from `packages/app`, fix only touched files.
- Main-owned gates: full `flutter test` from `packages/app`, final
  `flutter analyze`, AVD/greyscale acceptance — run after all tasks land.
