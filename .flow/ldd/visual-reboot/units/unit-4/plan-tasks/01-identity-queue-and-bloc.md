# Task 01 — Encounter identity, activation projection, and bloc lifetime

Owner: first fresh sequential executor in the Unit 4 feature checkout. Read
`../PLAN.md`, `../CONTRACT.md`, and `../recon.md` first. Planning artifacts do
not authorize implementation.

## Preconditions and scope

Start from app source equivalent to `4164741`; task 02/03 changes must not yet
be present. Touch only:

- add `packages/app/lib/game/actor_presentation.dart`;
- add `packages/app/lib/game/activation_timeline.dart`;
- update `packages/app/lib/game/game_bloc.dart` and
  `packages/app/lib/game/event_messages.dart`;
- add `packages/app/test/game/actor_presentation_test.dart` and
  `packages/app/test/game/activation_timeline_test.dart`;
- update `packages/app/test/game_bloc_test.dart`.

Do not touch scene, glyph, battle widget, screen, core, content, save, or `.omp/`
files. Leave `GameViewState.arrivals` temporarily intact so the current UI keeps
compiling; task 03 owns its clean deletion with the legacy dock.

## Locked implementation

### `actor_presentation.dart`

Implement `ActorPresentation` and `ActorIdentityContext` exactly as specified in
`PLAN.md`:

- allocate one-based ordinals by initial `game.monsters` order inside exact raw
  `(glyph, name)` groups;
- store allocation facts privately even for unknown actors; expose an
  unmodifiable `knownActors` map only;
- seed known ids from current `game.visible` positions;
- exact ambiguous strings are attached superscripts (`the ghoul¹`, `g¹`), with
  all decimal digits supported;
- ambiguity means at least two ever-known ids in that group, not two currently
  alive or visible ids;
- `noticeAll` ignores unallocated ids without revealing them and returns `this`
  when it adds nothing;
- retain dead/out-of-sight known presentations until context reset;
- `eventNames(hero)` returns hero id/name plus only known presentation names.

Do not make the type serializable, Equatable, mutable, global, or dependent on
Flutter/Flame. Do not infer ordinals from actor-id spelling.

### `activation_timeline.dart`

Implement the sealed `ActivationToken`, `HeroActivationToken(isCurrent:)`,
`ActorActivationToken(actor)`, and `projectActivationQueue` interface from
`PLAN.md`. Preserve every `upNext` occurrence. Start with current hero; append
next hero only if every scheduled actor is visible-known. The first unknown id
terminates the entire remaining projection, including the next-hero token.
Return an unmodifiable list.

### `GameViewState`

Add optional constructor input/field `actorIdentity` and `selectedActorId`.
Remove `const` from the constructor; when identity is omitted initialize from
that constructor's `game`. Add:

- `ActorPresentation? presentationOf(String actorId)`;
- `Actor? get selectedActor`, requiring live + current `game.visible` + known;
- `Position get cameraFocus` using selected actor or hero;
- `List<ActivationToken> get activationQueue`, passing `upNext` and ids that are
  both current-visible and known;
- tighten `inspectTargetAt` to return only current-visible, known actors.

Do not alter `upNext` arithmetic or its bound filtering.

### Bloc event and state propagation

Add/register `TimelineActorSelected(actorId)`. A valid event emits state with:

- the identical `GameState` and log list;
- identical actor identity;
- unchanged `autoPath`, `walkId`, `armedSpellId`, and `hasFled`;
- selected id set and pan reset to zero.

Hidden, dead, stale, or unknown ids emit nothing. Manual pan carries selection.
Skill arming/disarming, non-stepping tile branches, watched/walk bookkeeping,
system-back refusal, and `_stopWalking` carry both selection and identity.
`RecenterPressed` carries identity but deliberately clears selection and pan.
Every path that calls `_step` clears selection and pan in its emitted state.

Introduce one private step-presentation routine used by `_act`, `_afterAction`,
and `_onAutoWalkAdvanced`:

1. union all `ActorNoticed` ids into current identity before formatting;
2. create one names map from that event context and pre-step hero;
3. pass the same map into `_describe`, `_ambushBeat`, and `_beats`;
4. format all events;
5. if any event is `Ascended` or `Descended`, return
   `ActorIdentityContext.fromGame(after)` for the emitted state; otherwise
   return the event context.

Change `_describe`/`_beats` signatures as needed to accept that names map.
Delete `namesIn(GameState)` from `event_messages.dart`; retain
`describeEvent`'s unknown-id fallback. Do not add a raw-name fallback in bloc or
widgets.

## Red/Green behavioral proof

Write the tests first and observe failures caused by missing behavior, not
compile-only placeholders.

`test/game/actor_presentation_test.dart`:

1. Initial order `[ghoul-b, spitter, ghoul-a]` with both ghouls known assigns
   `ghoul-b → the ghoul¹/g¹` and `ghoul-a → the ghoul²/g²` despite id spelling.
2. With only the first ghoul known, it is unbadged and the hidden second id is
   absent from `knownActors`; after `noticeAll(['ghoul-a'])`, both expose their
   fixed suffixes.
3. Removing/killing the first actor from a later `GameState` does not renumber
   the retained second presentation; `noticeAll` of an already-known id returns
   the same context.
4. A group ordinal at least 10 encodes all digits (`¹⁰`) rather than colliding.
5. An unallocated noticed id remains absent and never contributes a raw name to
   `eventNames`.

Expected Red: no context/API exists; a naive visible-list numbering
implementation also fails cases 2–4.

`test/game/activation_timeline_test.dart`:

1. `[fast, fast, other]`, all visible-known, yields current hero, the same fast
   actor twice, other, next hero in exact order.
2. A hidden/unknown actor between known actors yields only the current hero and
   preceding known actor(s); hidden actor, later actor, and next hero are absent.
3. Empty `upNext` yields current hero then next hero.
4. Returned list is unmodifiable.

Expected Red: no typed projection exists; filter-only implementations fail the
known-prefix case by leaking later order or the closing horizon.

`test/game_bloc_test.dart`:

- preserve existing `upNext` repeated-fast and bound tests unchanged;
- add a `GameViewState.activationQueue` integration using a speed-20 duplicate
  plus another due duplicate, asserting literal ids and actor presentation
  suffixes;
- add a currently hidden due actor ahead of a visible actor and assert the
  queue stops before both, without a closing hero;
- drive a step that reveals a second ghoul after one is known; assert the notice
  is exactly `The ghoul² comes into view.` and the resulting first/second
  presentations are `the ghoul¹`/`the ghoul²`;
- with two known duplicates, drive attack/death and monster attack paths and
  assert attacker/target/death sentences use the same suffixed names;
- select a current-visible actor and assert identical `GameState`, log, RNG
  state, target arm, walk fields, and actor identity; selection id is set and
  pan is zero;
- selecting hidden/stale ids emits no state;
- pan and arming preserve selection; recenter clears it without a turn or
  disarm; a real `WaitPressed` step clears it and changes only normal game/log
  facts;
- descend/ascend into a floor whose actor ids/order reuse prior-looking ids and
  assert the emitted identity is rebuilt from the arrived monster order rather
  than carried across the boundary.

Expected Red: current state has no identity/selection/queue; current pre-step
formatter names raw actors and view-state constructors cannot preserve the new
lifetime.

Do not add tests that inspect source text or merely assert a field was copied.
The propagation tests must observe stable suffix, focus/selection behavior, or
no-turn game/log/RNG invariants.

## Proof commands

From `packages/app`, after Green/refactor:

```sh
flutter test test/game/actor_presentation_test.dart \
  test/game/activation_timeline_test.dart test/game_bloc_test.dart
dart format lib/game/actor_presentation.dart \
  lib/game/activation_timeline.dart lib/game/game_bloc.dart \
  lib/game/event_messages.dart test/game/actor_presentation_test.dart \
  test/game/activation_timeline_test.dart test/game_bloc_test.dart
dart analyze lib/game/actor_presentation.dart
dart analyze lib/game/activation_timeline.dart
dart analyze lib/game/game_bloc.dart
dart analyze lib/game/event_messages.dart
dart analyze test/game/actor_presentation_test.dart
dart analyze test/game/activation_timeline_test.dart
dart analyze test/game_bloc_test.dart
```

Re-run the focused test command after formatting/static corrections. Do not run
the full suite or full analyzer; Main owns those after task 03.

## Executor discretion

Private seed/group helper names, internal collection construction, and test
fixture placement are discretionary. Prefer one allocation pass and return
existing immutable objects on no-op notices. Do not create a generic identity
service or a `GameViewState.copyWith` solely for this unit.

## Escalate when

- `upNext` differs from recon or cannot preserve repeated actor instances;
- core can introduce a new actor id without a context boundary;
- `ActorNoticed` can refer to an actor absent from pre-step monsters;
- ascent/descent shares actor-bearing events from both floors in one list;
- a view-only constructor cannot carry identity/selection without violating an
  existing Unit 3 pan/arm/walk contract;
- any required proof needs core/content/save changes or a second visibility or
  scheduling computation.

## Handoff state

Task 01 is complete only when the new identity/queue files and bloc/event
integration are Green under the focused command, every view-only path carries
identity, action/recenter selection resets are proven, and scene/widget files
remain behaviorally unchanged and compiling. Task 02 starts from those public
interfaces, not from this executor's session memory.
