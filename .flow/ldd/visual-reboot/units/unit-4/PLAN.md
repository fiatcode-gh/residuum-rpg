# Unit 4 — Turn Timeline and Presentation Identity: Execution Plan

Status: **execution-grade; planning only.** This artifact does not authorize
production implementation.

Derived from `CONTRACT.md`, `recon.md`, the approved visual-reboot handoff
section 7, and current `packages/app` source/tests at `41647416e93c`
(`4164741`, `main`, Unit 3 merged). At planning time no `packages/app` path is
dirty. Architect-owned `.flow/ldd/visual-reboot/{LEDGER.md,RESUME.md}` and the
untracked Unit 4 authority files are in flight; untracked `.omp/` is user-owned
and must not be touched. A changed app source revision requires targeted
revalidation of the named seams, not automatic redesign.

## Execution boundary

Use one non-isolated feature checkout/branch based on `4164741`, normally
`residuum-visual-reboot-4`; never implement this unit directly on `main`.
Dispatch one fresh `flow-plan-executor` per brief, sequentially in the same
checkout so repository state—not executor memory—carries the handoff:

1. `plan-tasks/01-identity-queue-and-bloc.md`
2. `plan-tasks/02-map-badges-selection-and-focus.md` after task 01 is green
3. `plan-tasks/03-timeline-and-legacy-cutover.md` after task 02 is green

Each task owns its focused Red/Green cycle, touched-file formatting, and focused
static checks. Main owns the final whole-app gates and device acceptance after
all three tasks land.

## Locked data model and ownership

### Encounter identity

Add `packages/app/lib/game/actor_presentation.dart` with two immutable app-only
values:

```dart
final class ActorPresentation {
  const ActorPresentation({
    required this.actorId,
    required this.displayName,
    required this.glyph,
    this.badge,
  });

  final String actorId;
  final String displayName;
  final String glyph;       // raw semantic glyph
  final String? badge;      // superscript ordinal only, e.g. ¹
  String get glyphLabel;    // glyph + badge, e.g. g¹
}

final class ActorIdentityContext {
  factory ActorIdentityContext.fromGame(GameState game);

  final Map<String, ActorPresentation> knownActors; // unmodifiable
  ActorPresentation? operator [](String actorId);
  ActorIdentityContext noticeAll(Iterable<String> actorIds);
  Map<String, String> eventNames(Actor hero);
}
```

`ActorIdentityContext` privately retains the allocation for every monster that
exists when the floor/road encounter context is created, plus the set/map of
actors known so far. It is never placed in `GameState`, save documents, core,
or content.

Allocation is deterministic and fixed for the context lifetime:

- group by the exact raw `(monster.glyph, monster.name)` pair;
- walk the context's initial `game.monsters` list once in its stable order;
- assign each member its one-based ordinal within that group;
- encode every decimal digit with `⁰¹²³⁴⁵⁶⁷⁸⁹`, so ordinals above nine remain
  deterministic rather than colliding;
- initial known ids are only monsters whose current positions are in
  `game.visible`—reuse this FOV result; never compute visibility again;
- `noticeAll` unions only allocated ids, returns the same context when the set
  does not change, and never exposes an unknown id. A notice for an unallocated
  id safely remains unnamed (`describeEvent`'s existing “something in the
  dark” fallback) and is an escalation-worthy engine/context contradiction,
  not a reason to reveal the raw actor.

A badge is rendered only when at least two ids in the same raw group are in the
context's known set. The ordinal itself never changes. Exact strings are:

- singleton/only-known member: `displayName == raw name`, `badge == null`,
  `glyphLabel == raw glyph`;
- ambiguous known member: `displayName == '$rawName$superscript'`,
  `badge == superscript`, `glyphLabel == '$rawGlyph$superscript'` (no inserted
  space).

Known dead or currently out-of-sight actors remain in the context so a death
sentence and a surviving duplicate keep their allocated suffix. They do not
become map/timeline/inspect candidates: those surfaces independently require
current visibility.

`GameViewState` becomes non-`const` and accepts
`ActorIdentityContext? actorIdentity`, initializing it with
`ActorIdentityContext.fromGame(game)` only when omitted. It carries this value
through every view-only state transition. A new `GameBloc` therefore creates a
new context, including every road encounter. An `Ascended` or `Descended` step
formats that step with the old context, then resets the emitted state's context
from the arrived `GameState`; no actor id or ordinal crosses a floor boundary.

### Pre-step event naming

For each `_step` result, form one event context by unioning **all**
`ActorNoticed.actorId` values into the current context before formatting any
event. Use that one context's `eventNames(before.hero)` for `describeEvent`,
`_ambushBeat`, and `_beats`. This ensures two duplicates noticed in the same
step are suffixed in every sentence, and the first notice sentence already
matches the resulting map/timeline identity. It also preserves pre-step names
for actors removed by death. Remove the raw `namesIn(GameState)` production
path; unknown actor ids retain `describeEvent`'s safe fallback.

### Activation queue

Add `packages/app/lib/game/activation_timeline.dart` with typed, non-string
projection data:

```dart
sealed class ActivationToken { const ActivationToken(); }
final class HeroActivationToken extends ActivationToken {
  const HeroActivationToken({required this.isCurrent});
  final bool isCurrent;
}
final class ActorActivationToken extends ActivationToken {
  const ActorActivationToken(this.actor);
  final Actor actor;
}

List<ActivationToken> projectActivationQueue({
  required List<Actor> upNext,
  required Set<String> visibleKnownActorIds,
});
```

The projection starts with `HeroActivationToken(isCurrent: true)`, then walks
`upNext` without deduplication. Each visible-known occurrence becomes an
`ActorActivationToken`, so a speed-20 actor may occur twice. On the first actor
outside `visibleKnownActorIds`, stop immediately: omit that actor, every later
actor, and the closing hero token. This is the truthful known prefix; appending
the closing hero after an omitted activation would display a false sequence and
leak that the hidden interval ends there. Only when every scheduled actor is
visible-known append `HeroActivationToken(isCurrent: false)`. Return an
unmodifiable list.

`GameViewState.activationQueue` passes its existing `upNext` unchanged and a
set of ids satisfying both `game.visible.contains(monster.position)` and
`actorIdentity[monster.id] != null`. It does not reproduce energy arithmetic,
filter bound actors a second time, or compute a second FOV.

### View-only selection and camera focus

Add `TimelineActorSelected(String actorId)`. `GameBloc` accepts it only when the
id names a live monster whose current position is visible and whose identity is
known. A valid selection emits a view-only state with the identical `GameState`
and log, unchanged walk/arm/identity, `selectedActorId` set, and `pan` reset to
zero. An invalid, stale, or hidden id emits nothing.

`GameViewState` owns:

- `final String? selectedActorId`;
- `Actor? get selectedActor`, returning only a live, currently visible,
  known-identity monster;
- `Position get cameraFocus => selectedActor?.position ?? game.hero.position`.

A real game step (`_act`, `_afterAction`, or `_onAutoWalkAdvanced`) clears
selection by construction and resets pan, returning focus to the hero.
View-only handlers preserve selection and identity, including pan, arming,
disarming, walk bookkeeping/refusal, and system-back refusal.
`RecenterPressed` is the explicit exception: it preserves identity, arm, walk,
and log, but clears selection and pan so focus returns to the hero. Manual pan
preserves the selected focus and adds its delta exactly as in Unit 3.

## Locked map and presentation interfaces

`GlyphCell` gains `String? badge` and `bool selected`; semantic `glyph`,
`marked`, layer, and render id remain unchanged. `glyphPlan` gains named inputs
`Map<String, ActorPresentation> actorPresentations = const {}` and
`String? selectedActorId`; for currently visible monster cells it copies only
the presentation badge and selection fact. Targeting stays `markedIds`; badge,
selected, and target facts coexist on the same stable `(monster layer, actor
id)` cell.

`GlyphMarkTreatment` gains explicit outline decisions using
`GlyphOutlineShape.square` for a target and `GlyphOutlineShape.circle` for a
selection. Both can be present. Flame renders the target as the existing inset
square and selection as a separate circular stroke; neither depends on hue.
The semantic glyph remains the main text component, and the optional
superscript is a separate small top-right text component. Synchronization
updates/removes badge and outline children on the retained actor component; it
does not replace components, allocate per frame, resume Flame's loop, or add an
animation scheduler.

`DungeonSceneSnapshot.fromViewState` passes the identity map, armed targets,
and selected id to `glyphPlan`, and uses `state.cameraFocus`. Projection reuse
must include identity-context identity and `selectedActorId`; a pure pan may
reuse cells, while a badge/selection change must resynchronize them.
`GameScreen._heroOffScreen` computes geometry from `state.cameraFocus`, then
checks the hero position. Thus selecting a distant actor offers the existing
recenter affordance, and recenter returns to the hero.

`showEnemyInfo` changes to require the matching `ActorPresentation`. Its header
renders `presentation.glyphLabel` and `presentation.displayName`; combat stats
still come from `Actor`. Map tap, map long-press, and timeline callers all pass
the same context-owned value and do nothing if no currently known presentation
exists. No widget recomputes suffixes or falls back to an unknown actor's raw
name.

## Locked timeline UI and cutover

`BattleDock` remains the battle-only top dock but becomes one compact activation
row. It accepts `GameViewState state` and
`ValueChanged<Actor> onActorSelected`. Remove `_StageCard` and `_TurnChips`
entirely. Remove `GameViewState.arrivals` and its D86 tests; no travel estimate,
`NOW`, `IN n`, stage HP card, or compatibility presentation survives.

Render `state.activationQueue` in a horizontally scrollable `Row` on
`dockBacking`, separated by `›`:

- current hero: visible `@ YOU`, noninteractive, semantics “You, current
  activation”, key `timeline-current-hero`;
- actor occurrence: visible `ActorPresentation.glyphLabel`, semantics with its
  exact `displayName`, a minimum 44×44 logical hit target, and unique key
  `timeline-actor-<actorId>-<queueIndex>` (repeated actor occurrences therefore
  remain separate widgets);
- next hero, when the known prefix reaches it: visible `@ YOU`, noninteractive,
  semantics “You, next activation”, key `timeline-next-hero`.

`GameScreen` supplies the actor callback. It dispatches
`TimelineActorSelected(actor.id)` and opens `showEnemyInfo` with the same current
`ActorPresentation`; it dispatches no core action. Existing map inspection
callers migrate to the required presentation argument. The combat shelf remains
unchanged and below the live map.

## Migrations and removals

Production paths touched across the unit:

- add `lib/game/actor_presentation.dart` and
  `lib/game/activation_timeline.dart`;
- update `lib/game/game_bloc.dart`, `event_messages.dart`, `glyph_plan.dart`,
  `glyph_marks.dart`, `dungeon_scene.dart`, `battle_view.dart`, and
  `game_screen.dart`;
- remove `namesIn`, `GameViewState.arrivals`, `_StageCard`, `_TurnChips`, their
  obsolete comments/imports, and every production reference to stage cards,
  `NOW`, `IN n`, and arrival estimates;
- migrate every `GameViewState(...)` construction in production to carry
  `actorIdentity` on view-only transitions and the three step paths to use the
  single event-context/reset routine;
- migrate all `showEnemyInfo` and `BattleDock` call sites; no overload, alias,
  deprecated path, or raw-name fallback remains;
- delete obsolete arrival/stage assertions rather than rewording them, and
  replace only the behavioral coverage that the new contract owns.

No `packages/core`, `packages/content`, save, balance, generator, RNG, shelf,
log-drawer, or world/town file is in scope. No second scheduler/FOV, persisted
identity, animation loop, pulse/easing, or battle-board restoration is allowed.

## Integrated verification ownership

Task briefs name exact focused Red/Green and static commands. After all tasks,
Main runs from `packages/app`:

```sh
dart format --set-exit-if-changed --output=none \
  lib/game/actor_presentation.dart \
  lib/game/activation_timeline.dart \
  lib/game/game_bloc.dart lib/game/event_messages.dart \
  lib/game/glyph_plan.dart lib/game/glyph_marks.dart \
  lib/game/dungeon_scene.dart lib/game/battle_view.dart \
  lib/game/game_screen.dart \
  test/game/actor_presentation_test.dart \
  test/game/activation_timeline_test.dart \
  test/game/glyph_plan_test.dart test/game/glyph_marks_test.dart \
  test/game/dungeon_scene_test.dart test/game/armed_targets_test.dart \
  test/game_bloc_test.dart test/battle_view_test.dart \
  test/battle_characterization_test.dart \
  test/battle_flow_characterization_test.dart
flutter analyze
flutter test
```

Then Main performs one final acceptance review against `CONTRACT.md`, verifies
only `packages/app` changed, and runs the Pixel_10/phone AVD gate on an emulator
id obtained from `adb devices` (`flutter run -d <emulator-id>`; never select an
attached user phone). Use a real generated floor/road encounter containing two
same-group speed-20 actors; do not add production fixture/scaffold. Capture
normal-colour and greyscale evidence showing literal repeated activation,
matching map/timeline/inspect/log suffixes, timeline tap focus, the recenter path,
and simultaneous circular selection plus square target outlines. If this host
cannot boot Pixel_10 or no reachable deterministic content seed can produce the
required scene, report the exact evidence blocker; do not weaken the gate or
change content/generation to manufacture it.

## Escalation boundary

Stop the affected task and return to the architect if:

- `GameViewState.upNext` no longer exposes core scheduler order/repetitions;
- an actor can be created mid-context without an ascent/descent/new bloc,
  invalidating initial-list allocation;
- `ActorNoticed` can name an id absent from the pre-step monster list;
- a floor transition emits actor-bearing events whose actor belongs to the new
  floor in the same event list, requiring mixed old/new naming contexts;
- required behavior would expose an actor not both currently visible and known;
- selection/focus requires a core action, FOV change, RNG read, save field, or a
  second scheduler/animation loop;
- Flame cannot retain the semantic glyph plus separate badge and both outline
  shapes without changing stable render identity;
- the 44×44 tokens plus horizontal scrolling cannot remain exception-free on
  the phone target.

Local spacing, stroke width, badge font size/offset, and private helper names are
executor discretion if they preserve the locked shapes, value contrast,
hit-target size, public interfaces, and proofs.

## Plan quality gate

- **COR — PASS.** Scheduler ownership stays in `upNext`; the known-prefix end
  rule, current-visibility gate, identity allocation/lifetime, notice-before-
  format ordering, death/floor behavior, selection validation, focus reset, and
  every view-state propagation path are decided. Unknown ids fail closed.
- **TTC — PASS.** Each contract behavior maps to named pure/bloc/projection/
  widget proofs with expected Red symptoms in the briefs. Shared-threshold and
  bound behavior remain pinned through `upNext`; hidden-prefix, late duplicate,
  survivor, pre-step log, no-turn selection, combined outlines, legacy removal,
  phone layout, full-suite/analyzer, and device evidence are all owned.
- **CRF — PASS.** One context owns identity strings; one typed projection owns
  timeline order; widgets consume facts. Stable Flame components are updated in
  place, legacy stage/arrival code is deleted, and no second scheduler, FOV,
  compatibility layer, generic loop, or persistence model is planned.
- **SEC — SKIP (no external trust boundary).** Unit 4 adds no network,
  persistence, deserialization, privilege, or untrusted-input surface. The
  consequential simulation-state disclosure boundary is nevertheless resolved
  under COR: map/timeline/inspect selection requires current visibility plus
  known identity, and unknown naming fails closed instead of exposing raw data.

Residual evidence risk: actual superscript font fallback, badge placement, and
circle/square legibility cannot be proven by Dart tests; the mandatory
Pixel_10 normal/greyscale gate owns them. Unit 3's outstanding AVD evidence is a
separate ledger debt and does not change this plan's source or behavior contract.
