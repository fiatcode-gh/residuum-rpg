# Task 01 — Bloc interaction semantics

Owner: sole sequential owner, non-isolated checkout `residuum-visual-reboot-3`.

## Scope

`packages/app/lib/game/game_bloc.dart` and `packages/app/lib/game/grid_geometry.dart`
only. No scene, no screen, no widget changes yet. No core/content edits.

## Change

### Collapse the armed state

- Delete the sealed `ArmedAction` hierarchy (`ArmedAction`, `ArmedAttack`,
  `ArmedSpell`) and `AttackArmed`/`StageCardTapped` events and their handlers
  (`_onAttackArmed`, `_onStageCardTapped`).
- Replace `GameViewState.armedAction` with `final String? armedSpellId;`.
  Constructor param becomes `this.armedSpellId`. Drop the `armedSpellId` getter
  (the field IS the value now).
- Update every `GameViewState(...)` construction that names `armedAction:` to
  name `armedSpellId:` with the surviving spell id (or null). `_onSkillArmed`
  sets `armedSpellId: event.spellId`; pan/back-refusal/walk-refusal carry
  `state.armedSpellId`.
- `armedTargets` becomes: armed spell → all visible monsters by id; null → `{}`.
  (The ArmedAttack branch disappears with the class.)

### Rewrite the tap path

`_onTileTapped(TileTapped event, emit)`:

1. `if (game.isGameOver) return;`
2. If `state.isWalking` → `emit(_stopWalking())`; return (unchanged).
3. If `armedSpellId != null` (armed spell):
   - let `monster = game.monsterAt(event.position)`;
   - if `monster != null && game.visible.contains(monster.position)` →
     `_act(CastSpellAction(spellId, targetId: monster.id), emit)`; return.
   - else → disarm: `emit` a state carrying `armedSpellId: null` plus
     `walkId`/`autoPath`/log unchanged, pan reset to zero (fresh state omits
     pan). No move, no turn. Return.
4. Not armed. If `event.position` is orthogonally adjacent to the hero AND
   `game.monsterAt(event.position) != null`:
   - `final direction = game.hero.position.directionTo(event.position);`
   - `emit(_afterAction(MoveAction(direction)));` return.
   (This is the map-first melee.)
5. Otherwise the existing movement logic is unchanged: direction move, then
   unexplored/walkable guards, watched refusal, auto-walk.

Note: step 4 replaces today's refusal branch that logs `_watchedRefusal` when a
monster sits in sight; the watched refusal now only fires for a *distant*
explored walkable tap while `enemiesInSight > 0`, which the existing code after
step 4 already covers. The adjacent-monster map tap is no longer refused — it
bumps.

### Inspection getter

Add to `GameViewState`:

```dart
Actor? inspectTargetAt(Position position) => game.monsterAt(position);
```

Returned only when a monster is there; the widget decides whether the tap is
inspect-vs-melee-vs-cast (melee/cast precedence lives in `_onTileTapped`, above,
so the widget needs no armed knowledge — it calls `inspectTargetAt` only for the
non-melee, non-armed presentation path; see task 03).

### Recenter

- New `RecenterPressed` event + `_onRecenterPressed`: emit a state with
  `pan: Offset.zero`, carrying `autoPath`/`walkId`/`armedSpellId`/log unchanged.
  Mirror `_onMapPanned`, minus the delta.
- Add `heroOffScreen(Size viewport, GridGeometry geometry, Position focus) → bool`
  to `grid_geometry.dart`: compute `geometry.topLeftOf(focus)` and return true
  when that cell is outside `0..viewport.width` / `0..viewport.height` (with the
  `cameraCellSize` cell extent). Pure, no camera mutation.

## Proof (Red first)

Extend `packages/app/test/game_bloc_test.dart` (and add
`packages/app/test/game/hero_off_screen_test.dart`):

- tap adjacent monster with nothing armed → hero position unchanged, monster hp
  reduced, log has `You hit …` (Red: currently logs the watched refusal).
- tap adjacent monster with armed spell → `CastSpellAction` path: mana spent,
  log has the spell-hit sentence.
- tap non-monster tile while armed → disarmed, hero unmoved, no log growth, turn
  not spent (monster hp/positions unchanged).
- `inspectTargetAt` returns the monster at a tile, null on empty tile.
- `RecenterPressed` zeroes pan and does not disarm (arm first, pan, recenter,
  assert armedSpellId still set).
- `heroOffScreen` true/false for a focus inside/outside a small viewport.

Then fix every existing test that referenced the removed symbols (see
`battle_view_test.dart`, `game_bloc_test.dart`, `autosaver_test.dart`,
`battle_characterization_test.dart`, `game/armed_targets_test.dart`,
`game/dungeon_scene_test.dart`): rewrite to drive melee via `TileTapped` at the
adjacent monster and cast via `SkillArmed` + `TileTapped`, or drop the assertion
if the behavior is now task-03 widget territory. Do NOT re-pin the watched
refusal on an adjacent-monster tap — that behavior is retired.

## Escalate when

- core `_castRefusal` differs from the "visible monster" contract stated here
  (it should not — verified at source).
- `monsterAt` returns a monster the hero cannot see (task 03's inspect gating
  depends on visibility) in a way that contradicts the contract.

## Verification ownership

- Focused proof: `flutter test test/game_bloc_test.dart
  test/game/hero_off_screen_test.dart test/game/armed_targets_test.dart
  test/autosaver_test.dart` from `packages/app`.
- Formatter: `dart format` on the two touched lib files and touched tests.
- Focused static: `flutter analyze` scoped is not supported; run full
  `flutter analyze` from `packages/app` and fix only issues in touched files.
- Main-owned gates: full `flutter test` from `packages/app`, final
  `flutter analyze`, AVD/greyscale acceptance — run after all tasks land.
