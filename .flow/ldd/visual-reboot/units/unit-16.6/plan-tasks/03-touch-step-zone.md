# 03 — Touch resolution: 48 dp step box around the hero

Governing: `../CONTRACT.md` settled decision 11, scope §6 ("touch-by-intent
rules stay … radii re-checked … effective touch target ≥ 48 dp"),
acceptance 7 and 10; `../PLAN.md` §2 G4. Work from `packages/app`.

## Starting repository state

Task 02 committed (cells 24 × 30, hero-centred camera). `lib/game/map_touch.dart::resolveMapTap`
unarmed rule 4 steps only when `dist(hero) <= mapTouchRadius (24)` and
`under != hero`, dominant axis by `u = dx / mapCellWidth`,
`v = dy / mapCellHeight`, ties horizontal. `GameBloc._onTileTapped` refuses a
non-adjacent walk while `enemiesInSight > 0` (`_watchedRefusal`).

## Owned files

`lib/game/map_touch.dart`, `test/game/map_touch_test.dart`,
`test/widget/map_touch_wiring_test.dart` (only if a case breaks).

Non-goals: armed rules, long-press, monster radius, the bloc.

## Locked decisions

1. Add `const double mapStepReach = 48;`. `mapTouchRadius = 24` unchanged.
2. Replace unarmed rule 4 exactly per PLAN G4 (box `|dx| ≤ 48 && |dy| ≤ 48`,
   `d != Offset.zero`, dominant normalised axis, ties horizontal, in-bounds
   check, else fall through). Rules 1–3, 5, 6, armed and long-press rules
   are byte-identical.
3. Stale dartdoc describing the 24 dp step disc is deleted.
4. The step fires only when `under != null` (`geometry.positionAt(local)`
   lands inside the floor bounds). A tap on the void past a floor edge never
   steps; it falls through to rules 5/6 (nothing). PLAN G4 amendment.

## Proof (Red first)

`map_touch_test.dart` (replace the 23.9/24.1 dp *hero-diagonal* step cases;
keep the monster-radius 23.9/24.1 cases, which still hold):
- offsets from the hero centre `(47.9, 0)` → east, `(−47.9, 0)` → west,
  `(0, 47.9)` → south, `(0, −47.9)` → north; `(48.1, 0)` with no monster →
  `MapTouchCell(under)` (the two-away cell, i.e. auto-walk as before);
- `(24, 30)` (diagonal cell centre, u = v = 1) → east; `(13, 44)` (inside the
  south-east diagonal cell, v dominant) → south; `(5, 0)` inside the hero
  cell → east; the exact centre → `MapTouchCell(hero)`;
- a known monster within 24 dp of the tap still wins over the step (rule 3
  precedence), and a monster under the finger still wins (rule 1);
- a tap on an orthogonal neighbour cell's far corner still steps there
  (rule 2);
- Watched fixture (a visible monster 4 cells away): a tap at `(20, 40)`
  (inside the south-east diagonal cell, v dominant) resolves to the south
  neighbour, and dispatching it through `GameBloc` moves the hero (no
  `Something is watching` line) — the tap half of the walkthrough stall
  (bloc-level assertion on the emitted state).
- floor-edge fixture (hero on the floor's west edge column, camera centred so
  void shows west of it): taps at `(−24, −30)` and `(−40, 0)` from the hero
  centre (both on the void, `under == null`) → `MapTouchNothing` and the hero
  does not move; the mirrored offsets east of the hero still step east.
Expected Red: `(47.9, 0)`, `(24, 30)` and the Watched case resolve to a
non-adjacent cell today (auto-walk or refusal).
Green: full `flutter test`, `dart format <touched>`, `flutter analyze`.

## Executor discretion

Test grouping and fixture helpers; whether the Watched case lives in
`map_touch_test.dart` or `game_bloc_test.dart` (either observes the bloc
state).

## Escalate when

A wiring or battle test depends on a tap inside the new box auto-walking;
the dominant-axis rule produces a step toward a wall that a test treats as a
defect (the bloc's wall bump is existing behaviour, not a defect).

## Completion receipt

Red output, Green command/exit, format/analyze exits, the list of replaced
tests with the retired rule each pinned. Commit:
`feat(app): step toward any tap within 48 dp of the hero`.
