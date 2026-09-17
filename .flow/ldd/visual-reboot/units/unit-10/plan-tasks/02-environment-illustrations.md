# Task 02 — Environment illustrations

Owner: one fresh `flow-plan-executor` on the Unit 10 feature checkout. Read
`../PLAN.md` and `../CONTRACT.md` before editing. Task 01 has landed and been
accepted; you inherit its repository state, not its session.

## Expected starting repository condition

- The `residuum-visual-reboot-10` checkout, branched from `4bf865c`, with task
  01's changes present and its tests green.
- `packages/app/lib/art/art_assets.dart` exists and exposes
  `EnvironmentArt { stonebridge, forge, tavern }` with a `path` getter.
- `packages/app/assets/visual/environments/{stonebridge,forge,tavern}.jpg`
  exist at 1080x432 and are declared in `packages/app/pubspec.yaml` under
  `assets:`.
- `packages/app/lib/art/dungeon_art.dart` exists; `warmUpArt()` precaches the
  three illustrations and is called from `main()`.
- `packages/app/lib/town/illustration.dart` does not exist.
- `town_screen.dart:83-84` still reads `Notice(state.notice)` then
  `const Spacer()`. `forge_screen.dart:56-57` still reads
  `Notice(state.notice)` then `const Heading('Materials')`.
  `tavern_screen.dart:30-31` still reads `Notice(...)` then
  `const Heading('What they are saying')`.
- Architect-owned `.flow/**` records and the untracked `art/` masters may be
  dirty. Preserve those bytes exactly.

Inspect branch and worktree before editing. Implementation on `main` is
forbidden. If any named seam differs from `../PLAN.md`, stop and report rather
than adapting silently.

Every command below runs from `packages/app`.

## Behavioural slice

Put an authored illustration on Stonebridge, the Forge and the Tavern as
atmosphere: gated on town identity for Stonebridge, ungated for the two rooms,
decorative to the accessibility tree, and height-capped so that not one title,
status line, price, refusal sentence, control or door moves out of reach or out
of order.

Files:

- `packages/app/lib/town/illustration.dart` (new);
- `packages/app/lib/town/town_screen.dart` (one gated child);
- `packages/app/lib/town/forge_screen.dart` (one child);
- `packages/app/lib/town/tavern_screen.dart` (one child);
- `packages/app/test/widget/town_illustration_test.dart` (new).

Do not touch `town_style.dart`, `TownRoom`, `_Door`, `Notice`, `Heading`,
`Purse`, `MaterialRows`, any other town room, `town_bloc.dart`, the world
screens, `lib/game/**`, `lib/art/**`, `pubspec.yaml`, `packages/core`,
`packages/content`, or **any existing test file**.

## Locked implementation

`../PLAN.md` section 4 is the recipe. Where this brief and the plan differ, the
plan wins; where the plan and `../CONTRACT.md` differ, stop and report.

### `lib/town/illustration.dart`

Public surface — exactly this, no more:

```dart
const townIllustrationKey = Key('town-illustration');
const forgeIllustrationKey = Key('forge-illustration');
const tavernIllustrationKey = Key('tavern-illustration');

const double townIllustrationHeight = 140;
const double roomIllustrationHeight = 120;

class Illustration extends StatelessWidget {
  const Illustration(this.art, {required this.height, super.key});

  final EnvironmentArt art;
  final double height;
}
```

`build` is exactly:

```dart
ExcludeSemantics(
  child: Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Image.asset(
          art.path,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, _, _) => const SizedBox.expand(),
        ),
      ),
    ),
  ),
)
```

Imports: `package:flutter/material.dart` and `../art/art_assets.dart`. **Do not
import `flutter_bloc`** — the illustration is a pure leaf that reads nothing.

Binding details a reviewer will check:

- **`ExcludeSemantics` is the outermost widget.** No `semanticLabel` on the
  image, no `Semantics` wrapper, no `Tooltip`, no text of any kind anywhere in
  the subtree. Criterion 5 forbids an image that announces itself; the
  precedent is `world_route_diagram.dart:143`.
- **`BoxFit.cover`, no `alignment` argument** (centre is the default and is
  correct: the shipped 2.5:1 band is already a deliberate crop of the master,
  so the remaining 6-19% trim comes off both edges evenly).
- **No `AspectRatio`.** The height is the budget, so the height is what the
  widget states. A 1:1 source under `AspectRatio` at 371.4 dp is 411 dp tall —
  45% of the phone — and would displace controls.
- **`errorBuilder` returns `const SizedBox.expand()`.** A missing or corrupt
  asset must leave a hole, never a Flutter error widget in the middle of a
  town. This is production error semantics, not a test accommodation.
- **`ClipRRect` radius 2** is the house value (`_Meter`, `_SkillRow`); the 8 dp
  vertical padding keeps the town's existing rhythm.
- 140 dp in the town and 120 dp in a room are locked numbers. Do not tune them
  to taste; if one of them cannot work, that is an escalation.

### `lib/town/town_screen.dart`

Insert between `:83` `Notice(state.notice)` and `:84` `const Spacer()`:

```dart
if (state.town == stonebridge)
  const Illustration(
    EnvironmentArt.stonebridge,
    height: townIllustrationHeight,
    key: townIllustrationKey,
  ),
```

`stonebridge` comes from `package:residuum_content/content.dart`, already
imported at `:3`. Add `import 'illustration.dart';` and
`import '../art/art_assets.dart';` in the existing import order.

**Northgate gets nothing.** No empty box, no placeholder, no substitute
illustration, no reserved height. The `if` is absent, not falsy-rendered.
Nothing else in this file changes: not the header, the descents line, the
divider, the three status lines, the materials block, the notice, the `Spacer`,
any door, `_titleFor`, `_descentsSoFar` or `_open`.

### `lib/town/forge_screen.dart`

Insert between `:56` `Notice(state.notice)` and `:57`
`const Heading('Materials')`:

```dart
const Illustration(
  EnvironmentArt.forge,
  height: roomIllustrationHeight,
  key: forgeIllustrationKey,
),
```

Ungated — decision D3 makes the room illustration room-typed, so it renders in
both towns. Add the two imports. Nothing else changes: not the smelter, the
stepper, the `Smelt` commit, the reason sentence, the bench, or `_TemperRow`.

### `lib/town/tavern_screen.dart`

Insert between `:30` `Notice(town.notice ?? world.notice)` and `:31`
`const Heading('What they are saying')`:

```dart
const Illustration(
  EnvironmentArt.tavern,
  height: roomIllustrationHeight,
  key: tavernIllustrationKey,
),
```

Ungated, same reason. Add the two imports. Nothing else changes: not the purse,
the offer row, the exhausted line, the six-newest-lines loop, or `_ask`.

## Red/Green proof

Establish Red before the production edits: write
`test/widget/town_illustration_test.dart` against the interface above first and
watch every test fail on `findsNothing` for keys and a type that do not exist.

### New focused suite — `packages/app/test/widget/town_illustration_test.dart`

Follow `test/widget/town_shell_test.dart`'s harness shape: a real `TownBloc`
and a real `WorldBloc` under a `MultiBlocProvider` inside a `MaterialApp`, with
`addTearDown` on both blocs. Pump Northgate with `TownBloc(profile: ..., town:
northgate)` — the named parameter already exists
(`town_bloc.dart:424-425, 456-472`). Bodies structured `// arrange` / `// act` /
`// assert`.

1. **Stonebridge carries its illustration** — `find.byKey(townIllustrationKey)`
   findsOneWidget; the widget's `height` is `townIllustrationHeight`; the
   rendered box height equals it.
2. **Northgate carries none, and nothing stands in for it** — with
   `town: northgate`: `find.byKey(townIllustrationKey)` findsNothing,
   `find.byType(Illustration)` findsNothing, and `find.byType(Image)`
   findsNothing anywhere on the screen. The last finder is the one that catches
   a substitute.
3. **the forge and the tavern are illustrated in both towns** — for
   `town: stonebridge` and again for `town: northgate`, open the room and
   assert `find.byKey(forgeIllustrationKey)` / `find.byKey(tavernIllustrationKey)`
   findsOneWidget with height `roomIllustrationHeight`.
4. **an illustration displaces nothing in the town** — Stonebridge at `onAPhone`
   (`test/support/phone.dart`): `find.text('Stonebridge')`, the three status
   lines, the notice and all seven door labels are present (scrolling to the
   later doors exactly as `town_shell_test.dart:133-137` does), and
   `tester.takeException()` is null.
5. **an illustration sits between the notice and the first heading** — for the
   forge and for the tavern:
   `getTopLeft(find.byType(Notice)).dy < getTopLeft(illustration).dy <
   getTopLeft(find.text('MATERIALS' | 'WHAT THEY ARE SAYING')).dy`.
6. **an illustration says nothing** — with `tester.ensureSemantics()` active on
   all three screens,
   `find.descendant(of: <illustration key>, matching: find.byType(Semantics))`
   findsNothing. The plausible bug this catches is a `semanticLabel` or a
   `Semantics` wrapper added to the image; the full accessibility reading is the
   device gate's TalkBack pass, which the plan states rather than proxies.

Use real blocs and the real screens, never a mock. Do not assert source text,
widget counts as a layout proxy, or pixel content. No golden images
(`AGENTS.md`).

### Existing tests: zero changes, all must stay green

These three are **load-bearing and correct**. They are criterion 4's whole
widget-level content, and none of them may be weakened, retitled, relaxed or
scrolled-around to make art fit:

- `test/widget/town_shell_test.dart` — `seven doors, in order, and no eighth`
  (`:97-123`, door order by ascending Y) and `the last door is reachable on a
  600-pixel-tall screen` (`:125-139`, scrolls to each of seven, asserts no
  exception). The file deliberately uses the default 800x600 surface
  (`:27-29`).
- `test/widget/craft_rooms_test.dart:483-517` — `lays out purse, notice,
  materials, smelting and the bench in that order`, ten rows by ascending Y.
- `test/widget/tavern_screen_test.dart:85-132, 142-187` — `the last six lines,
  newest first` and `the notice comes from either bloc, and sits above the
  offer`.

Inserting a child between `Notice` and the first `Heading` preserves every
pairwise Y relation all three assert, and both town and room surfaces already
scroll. If any of them fails, **the illustration is wrong** — stop and report.

Also confirm green unchanged: `test/widget/craft_surfaces_test.dart`,
`test/widget/world_screen_test.dart`, every `*_bloc_test.dart`.

## Proof commands

From `packages/app`, after Red and after Green:

```sh
flutter test test/widget/town_illustration_test.dart \
  test/widget/town_shell_test.dart \
  test/widget/craft_rooms_test.dart \
  test/widget/tavern_screen_test.dart \
  test/widget/craft_surfaces_test.dart

dart format --set-exit-if-changed --output=none \
  lib/town/illustration.dart lib/town/town_screen.dart \
  lib/town/forge_screen.dart lib/town/tavern_screen.dart \
  test/widget/town_illustration_test.dart

flutter analyze
flutter test
```

`flutter analyze` and the final full `flutter test` are in scope: you are the
only writer at this point in the sequence, and adding a child to three screens
has a blast radius wider than the focused list. Main re-runs the same gate
afterwards; that is acceptance, not duplication. Do not run an app build, an
emulator, a device install, a `git commit`, a `git push`, or any external write.

## Executor discretion

Yours: private helper and test-helper names; the exact fixture staging (profile
seeds, notices, `copyWith` shape) for the new tests; how the Northgate pump is
factored; import ordering; whether `Illustration` carries dartdoc.

Not yours: `Illustration`'s constructor signature or the three key constants and
two height constants; the widget tree inside `build` (`ExcludeSemantics`,
padding, `ClipRRect` radius, `SizedBox`, `BoxFit.cover`, `filterQuality`,
`errorBuilder`); the 140/120 dp heights; the three insertion points; the
`state.town == stonebridge` gate and the fact that the two room illustrations
are ungated; the decision that Northgate gets no substitute; any verdict in the
"existing tests" section; any frozen wording on any screen.

## Escalate when

- an illustration cannot hold its height budget without displacing a title,
  status line, price, refusal sentence, control or door;
- `town_shell_test.dart`'s 600 dp door test, `craft_rooms_test.dart`'s forge
  order or `tavern_screen_test.dart`'s notice-above-heading fails — report the
  failure, never adjust the test;
- `Image.asset` throws into `tester.takeException()` despite `errorBuilder`, or
  the declared JPEG cannot be resolved in the widget harness;
- `TownViewState.town` cannot be read without a bloc change, a new state field
  or a content edit;
- the forge or tavern seam is not between `Notice` and the first `Heading` at
  the current revision;
- the accessibility tree cannot be kept silent for the illustration;
- an existing test fails for a preserved behaviour rather than an obsolete
  assumption;
- a fix would require `town_style.dart`, `town_bloc.dart`, `packages/core`,
  `packages/content`, `pubspec.yaml`, a new asset, a `git commit`, or
  implementation on `main`.

Report; do not redesign the contract.

## Handoff state and completion receipt

The task is complete when: `illustration.dart` exists with exactly the locked
surface; the three insertions are the only changes to the three screens; the six
focused tests are green; the three load-bearing layout suites are green
**unchanged**; `flutter analyze` is clean; the full `flutter test` passes with
no suite regressed; formatting is clean on touched files; and nothing outside
the named files changed.

Report to Main in at most eight prose lines:

- branch and base revision, and the Red you observed;
- the new file's public surface and the three insertion points as line numbers
  after the edit;
- which of the six focused tests cover criteria 3, 4 and 5;
- explicit confirmation that `town_shell_test.dart`, `craft_rooms_test.dart` and
  `tavern_screen_test.dart` are byte-unchanged and green;
- the results of the four proof commands;
- the measured rendered heights of the town and room illustrations at
  `onAPhone`;
- anything a device pass must settle (whether 140/120 dp reads, whether the
  crop composition lands, TalkBack silence);
- any escalation left open for Main's acceptance review.
