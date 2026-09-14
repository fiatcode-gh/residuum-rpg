# Task 03 — Interactive activation timeline and legacy cutover

Owner: third/final fresh sequential executor in the same Unit 4 feature
checkout. Read `../PLAN.md`, `../CONTRACT.md`, `../recon.md`, and inspect landed
task 01/02 interfaces. Planning artifacts do not authorize implementation.

## Preconditions and scope

Tasks 01 and 02 focused proofs are Green. Touch only:

- `packages/app/lib/game/battle_view.dart`;
- `packages/app/lib/game/game_screen.dart`;
- `packages/app/lib/game/game_bloc.dart` only to delete `arrivals` and its stale
  prose;
- `packages/app/test/battle_view_test.dart`;
- `packages/app/test/battle_characterization_test.dart`;
- `packages/app/test/battle_flow_characterization_test.dart` where exact visible
  actor names/interaction expectations change;
- `packages/app/test/game_bloc_test.dart` only to delete the entire obsolete
  `arrivals (turns to arrival, D86 formula)` group and any stage/arrival prose.

Do not alter identity allocation, queue projection, map shape/focus semantics,
combat shelf, core/content/save, or `.omp/`.

## Locked implementation

### Battle dock timeline

Change `BattleDock` to require:

```dart
const BattleDock({
  super.key,
  required this.state,
  required this.onActorSelected,
});

final GameViewState state;
final ValueChanged<Actor> onActorSelected;
```

Keep `dockBacking`; replace its contents with one horizontally scrollable
`Row` rendering `state.activationQueue`, with `›` separators. Remove
`_StageCard` and `_TurnChips` completely.

Token contract:

- current hero: `@ YOU`, noninteractive, semantics label
  `You, current activation`, key `timeline-current-hero`;
- each `ActorActivationToken`: look up `state.presentationOf(actor.id)` and
  render only when non-null (the queue invariant makes it non-null); visible
  text is `presentation.glyphLabel`, semantics label is its exact
  `displayName`, button semantics true, and hit target at least 44×44 logical
  pixels;
- actor key is
  `Key('timeline-actor-${actor.id}-$queueIndex')`, so repeated fast activations
  produce separate tappable widgets;
- next hero when present: `@ YOU`, noninteractive, semantics label
  `You, next activation`, key `timeline-next-hero`.

Do not deduplicate actor tokens, add `NOW`/`IN` explanation, show arrival counts,
or show a mystery/ellipsis token for a truncated queue. Do not add selected
pulse/animation.

### Inspect and selection routing

Change `showEnemyInfo` to require the matching `ActorPresentation` alongside
`Actor`. Header glyph is `presentation.glyphLabel`; title is
`presentation.displayName`; all wounds/attack/reach/speed/resistance facts still
come from the `Actor`.

In `GameScreen`:

- construct `BattleDock(state: state, onActorSelected: ...)`;
- callback rechecks `state.presentationOf(actor.id)`; if absent, do nothing;
  otherwise dispatch `TimelineActorSelected(actor.id)` and open
  `showEnemyInfo(context, actor, presentation)`;
- map non-adjacent tap and map long-press use the same presentation lookup and
  required inspect signature;
- keep armed map tap and adjacent melee precedence exactly as Unit 3 specified;
  no timeline tap calls `TileTapped`, `CastPressed`, `step`, or any core action.

A repeated actor token selects the same actor id. The bloc owns selection and
camera focus; widgets do not calculate positions or mutate FOV.

### Clean cutover

Delete:

- `_StageCard`, `_TurnChips`, stage card keys, stage HP/range rendering, and
  obsolete stage/chip comments from `battle_view.dart`;
- `GameViewState.arrivals` and its flow-field/travel-estimate prose;
- the entire arrivals test group in `game_bloc_test.dart`;
- widget assertions/contracts for stage names, stage HP bars, `at range`,
  `NOW —`, `IN n —`, or arrival counts.

Replace old stage-card inspect tests with timeline-token inspect tests. Do not
re-pin removed UI under new wording or leave an alias/compatibility widget.
Enemy stats remain covered through the inspect sheet opened from map/timeline.
The live map, `BattleShelf`, HP, controls, and current log viewport remain in
their existing screen regions.

## Red/Green behavioral proof

Write/replace tests before production edits and observe the old stage/prose
failure.

In `test/battle_view_test.dart`:

1. A battle with speed-20 `ghoul-1`, due `ghoul-2`, both known, renders keys in
   exact sequence current hero → ghoul-1 occurrence → ghoul-1 occurrence →
   ghoul-2 occurrence → next hero; visible actor labels are `g¹`, `g¹`, `g²`.
   Expected Red: old UI shows one `NOW` line and stage cards, not literal tokens.
2. Put a currently hidden due actor before a visible actor. Assert only the
   known prefix keys render: no hidden actor key/text/semantics, no later actor,
   no next hero, no mystery/ellipsis/count. Expected Red: old arrival/prose can
   name/count simulation actors and has no prefix contract.
3. A singleton renders unbadged `g`; two known duplicates render `g¹`/`g²`.
   Reveal the second through a real bloc step and assert both timeline labels
   update; after one dies the survivor keeps its suffix.
4. Tap either repeated token for one visible actor. After pump, assert:
   `selectedActorId` is that id; `GameState` object, hero/monster energy and HP,
   RNG/loot RNG states, log, armed spell/targets are unchanged; inspect sheet
   opens with matching suffixed glyph/title and stats; a scene snapshot focuses
   that actor. No combat sentence is added.
5. Dismiss inspect, perform a real game action, and assert selection clears and
   camera focus returns to hero. Recenter behavior remains covered by task 02.
6. Arm a target spell while a duplicate is selected and assert the same map
   actor cell carries its suffix, circular selected outline, and square target
   outline; timeline inspect itself does not arm/disarm.
7. Map tap/long-press inspect titles use the same singleton/duplicate
   presentation as timeline; adjacent tap still melees and armed tap still
   casts rather than inspects.
8. On the existing `_phone` dimensions the dock/timeline, live map, shelf, HP,
   controls, and log render without exception. Use a sufficiently long repeated
   queue to exercise horizontal scrolling rather than allowing overflow.
9. Assert old stage keys, stage HP/range text, `NOW —`, and `IN ` are absent.
   These are behavioral absence assertions in the replacement widget test, not
   source-text tests.

Update `battle_characterization_test.dart` comments/assertions so the current
contract describes a live map plus timeline, not a stage. Preserve its map,
engaged/watched, and singleton combat-log behavior. Update
`battle_flow_characterization_test.dart` only where token semantics or
presentation labels affect an existing flow; do not broaden Unit 4 into shelf or
log-drawer work.

Delete, do not rewrite, `game_bloc_test.dart`'s obsolete arrival-estimate cases.
Keep `upNext`, bound scheduling, battle-open, action, and identity tests Green.

## Proof commands

From `packages/app`, after Green/refactor:

```sh
flutter test test/battle_view_test.dart \
  test/battle_characterization_test.dart \
  test/battle_flow_characterization_test.dart test/game_bloc_test.dart \
  test/game/dungeon_scene_test.dart test/game/armed_targets_test.dart
dart format lib/game/battle_view.dart lib/game/game_screen.dart \
  lib/game/game_bloc.dart test/battle_view_test.dart \
  test/battle_characterization_test.dart \
  test/battle_flow_characterization_test.dart test/game_bloc_test.dart
dart analyze lib/game/battle_view.dart
dart analyze lib/game/game_screen.dart
dart analyze lib/game/game_bloc.dart
dart analyze test/battle_view_test.dart
dart analyze test/battle_characterization_test.dart
dart analyze test/battle_flow_characterization_test.dart
dart analyze test/game_bloc_test.dart
```

Re-run the focused test command after formatting/static corrections. Do not run
full suite/full analyzer; Main owns the final commands and current-phone-AVD gate in
`PLAN.md`.

## Executor discretion

Token padding, border radius, spacing, and separator styling are discretionary
inside the minimum hit target, horizontal-scroll, existing palette, and
accessible semantics constraints. Private timeline widget names are local.
Do not introduce a generic timeline controller, animation system, or second
selection owner.

## Escalate when

- task 01 queue/presentation interfaces cannot express the exact ordered keys;
- a token would need to render an actor not currently visible-known;
- opening the sheet and dispatching view-only selection cannot coexist without
  a core action or lost actor identity;
- map inspect precedence would change from Unit 3;
- phone layout cannot remain exception-free with a horizontal row and 44×44
  token targets;
- removing arrivals/stage code leaves a caller outside the named app files;
- required device evidence needs a production/content fixture rather than an
  existing deterministic encounter.

## Handoff state

Task 03 is complete only when the focused command is Green, all touched files
are formatted/static-clean, every inspect caller uses `ActorPresentation`, and
no production/test contract for stage cards, `NOW`, `IN n`, or arrivals remains.
Return the tree to Main for the full formatter check, `flutter analyze`, full
`flutter test`, acceptance review, and current-phone-AVD normal/greyscale gate. Do not
commit, push, publish, or edit LDD authority from this task unless Main separately
authorizes that action.
