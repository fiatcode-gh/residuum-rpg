# Task 01 — Two-row crawl status

Owner: one fresh `flow-plan-executor` on the Unit 9 feature checkout. Read
`../PLAN.md` and `../CONTRACT.md` before editing. This is the unit's only
implementation task; there is no prior worker transcript to inherit and none is
needed.

## Expected starting repository condition

- A non-`main` checkout, by house convention `residuum-visual-reboot-9`,
  branched from `2b0e0a4` (the merged Unit 8 head on `main`).
- `packages/` is clean at that base. `packages/app/lib/game/game_screen.dart` is
  916 lines and still contains `_HitPoints` at `:197-329` and `_BattleGlyph` at
  `:344-375`; `game_screen.dart:124` still reads `_HitPoints(state: state)`.
- `packages/app/lib/game/crawl_status.dart` does not exist.
- Architect-owned `.flow/**` records may be dirty or untracked. Preserve those
  bytes exactly: never stash, revert, commit or edit them.

Inspect branch and worktree before editing. Implementation on `main` is
forbidden. If any named seam differs from `../PLAN.md`, stop and report rather
than adapting silently.

The monorepo has **no root pubspec**. Every command below runs from
`packages/app`.

## Behavioural slice

Replace the crawl's single scale-down status string with a whereabouts header
row and a resource row of two labelled monochrome meters, losing no fact the
string carries, deleting the composition it came from, and migrating every test
assertion that observed that string to the observable fact it meant.

Production files:

- `packages/app/lib/game/crawl_status.dart` (new);
- `packages/app/lib/game/game_screen.dart` (delete `_HitPoints`, move
  `_BattleGlyph` out, change one line in `build`).

Test files:

- `packages/app/test/widget/hud_depth_test.dart` → `git mv` to
  `packages/app/test/widget/crawl_status_test.dart`, then rework;
- `packages/app/test/widget/world_screen_test.dart`;
- `packages/app/test/widget/suspend_door_test.dart`;
- `packages/app/test/widget/roster_session_test.dart`;
- `packages/app/test/widget/boot_wiring_test.dart`;
- `packages/app/test/battle_characterization_test.dart`.

Do not edit `game_bloc.dart`, `main.dart`, `skills_screen.dart`,
`town_style.dart`, any other town/world/Character screen, the battle dock or
shelf, the log drawer or peek, `_Controls`, the death overlay, save code,
dependencies, assets, `packages/core`, `packages/content`, or LDD authority.

## Locked implementation

`../PLAN.md` sections "Locked architecture and interfaces" 1–6 are the recipe
and are reproduced here only in outline. Where this brief and the plan differ,
the plan wins; where the plan and `../CONTRACT.md` differ, stop and report.

### New file `lib/game/crawl_status.dart`

Public surface — exactly this, no more:

```dart
const hpMeterKey = Key('hp-meter');
const manaMeterKey = Key('mana-meter');
const depthPairKey = Key('crawl-depth');

class CrawlStatus extends StatelessWidget {
  const CrawlStatus({required this.state, required this.dungeon, super.key});

  final GameViewState state;
  final NodeId? dungeon;
}
```

Imports: `package:flutter/material.dart`, `package:residuum_core/core.dart`,
`package:residuum_content/content.dart`, `game_bloc.dart`, and
`../town/town_style.dart` (`ink`, `rule`, `mono`). **Do not import
`flutter_bloc`** — these rows are a pure projection and read no bloc.

`build` is `Padding(EdgeInsets.symmetric(horizontal: 12, vertical: 4))` over a
`Column(mainAxisSize: MainAxisSize.min)` of `_HeaderRow`, `SizedBox(height: 4)`,
`_ResourceRow`. The 4-px paddings and the 4-px gap are the unit's entire height
budget (contract invariant 5) — do not restore them to 6.

File-private: `_HeaderRow`, `_ResourceRow`, `_Meter`, `_BattleGlyph`,
`_placeName`, `_battleWord`, `_condition`. Copy the exact widget bodies from
`../PLAN.md` sections 2 and 3.

Binding details, all of which a reviewer will check:

- `_placeName`: `'THE ROAD'` when `state.isEncounter`; `''` when `dungeon` is
  null; else `residuumWorld.nodeAt(dungeon).name.toUpperCase()`.
- the depth pair `'${state.depth} / ${state.deepest}'` sits in a
  `SizedBox(key: depthPairKey, width: 64)` that is **absent** on the road, not
  empty.
- `_BattleGlyph` keeps `SizedBox(width: 18)`, `TextAlign.center` and its exact
  `✖`/`◉`/`null` selection; only its inline `TextStyle` becomes `mono`.
- the battle word is a bare `Text(_battleWord(state), style: mono)` between the
  glyph and the depth pair; the place cell is the row's only `Expanded`.
- `_Meter` renders `Text('$label $value / $ceiling', style: mono)` at flex 8, the
  bar at flex 6, `Text(note, style: mono)` at flex 6, with 6-px gaps; bar is
  `ClipRRect(borderRadius: BorderRadius.circular(2))` over
  `LinearProgressIndicator(value: fill, minHeight: 8, backgroundColor: rule,
  valueColor: AlwaysStoppedAnimation(ink))`; `fill = ceiling == 0 ? 0.0 :
  (value / ceiling).clamp(0, 1).toDouble()`.
- `_ResourceRow` keeps `ceiling = state.maxHp`,
  `fraction = ceiling == 0 ? 0.0 : hero.hp / ceiling`, and
  `shown = hero.hp.clamp(0, ceiling)` **verbatim** from `game_screen.dart:205-207`.
  The condition takes the unclamped `fraction`.
- the HP cell is always present and `Expanded`; the Mana cell plus its 12-px gap
  exist **iff `state.game.knownSpells.isNotEmpty`**; its note is
  `'Ward ${state.warded}'` iff `state.warded > 0`, else `''`.
- every text cell is wrapped in `FittedBox(fit: BoxFit.scaleDown)` with
  `Alignment.centerLeft` or `centerRight` as the plan specifies. **No `Text` on
  either row may set `overflow`, `maxLines` or `softWrap`.** An ellipsis at any
  width is the defect this unit exists to avoid.
- `#DDE1E7` and `#23262E` do not appear in the new file; the town vocabulary
  replaces them.

No Dartdoc is required on these widgets — the repository limits Dartdoc to the
public API of `core` and `content`. You may carry the device-history rationale
from `game_screen.dart:246-258` onto the new row widget as a comment if you
judge it worth keeping; that is your call, not an obligation. No comments inside
function bodies (`AGENTS.md`).

### `lib/game/game_screen.dart`

1. delete `_HitPoints` (`:197-329`) whole, including `_line`, `_magic`,
   `_whereabouts`, `_condition` and `_battleWord`;
2. delete `_BattleGlyph` (`:344-375`) and its doc comment — it moves to the new
   file;
3. replace `:124` with `CrawlStatus(state: state, dungeon: bloc.dungeon)` —
   `bloc` is already in scope at `:61`;
4. add `import 'crawl_status.dart';` in the existing import order;
5. **keep `import '../town/town_style.dart' show ink, dim;`** — both are still
   used by the battle shelf at `:766, :776, :800, :873, :893, :897, :904, :911`.

Nothing else in this file changes: not the `PopScope`, the scene host, the
recenter affordance, `BattleDock`/`BattleShelf`, `LogPeek`, `_Controls`,
`doneAtTheBottom`, `_DeathOverlay`, or any sentence.

After the edit, a repository-wide search must find no `_HitPoints`, no `_line`,
no `_magic`, no `_whereabouts` and no `'Depth '` fallback anywhere in
`packages/app/lib`.

## Red/Green proof

Establish Red before production edits. Write the new focused tests against the
interface above first and watch them fail on the missing `CrawlStatus`, the
missing keys and the missing `THE …` / `HP n / m` strings. The migrated
assertions in the table below go Red the moment `_line` changes, which is
expected and is part of the same single cutover — the suite cannot be green
halfway through this task, so do not try to stage it in two green halves.

### New focused suite

`git mv packages/app/test/widget/hud_depth_test.dart
packages/app/test/widget/crawl_status_test.dart`, keep its `_pinnedSeed`
(`4242`), its `_pumpCrawlAt` harness, its `// arrange` / `// act` / `// assert`
bodies and its no-close-bloc rationale, and extend the harness with whatever
optional parameters the states below need (your choice of shape). The file then
carries exactly these tests:

1. **names the sea-cave and the six floors it rolled** — `find.text('THE SEA-CAVE')`
   and `find.text('1 / 6')`; keep `expect(rolled, 6)` and
   `expect(rolled, isNot(deepestDepth))`.
2. **names the keep and the seven floors it rolled** — `find.text('THE RUINED KEEP')`,
   `find.text('1 / 7')`; keep `expect(rolled, 7)`.
3. **still reads one of five in the crypt** — `find.text('THE CRYPT')`,
   `find.text('1 / 5')`.
4. **a road fight names the road and shows no depth** — a state with
   `isEncounter` true: `find.text('THE ROAD')` findsOne and
   `find.byKey(depthPairKey)` findsNothing.
5. **the hit points read as a labelled meter with the condition** — a fresh
   crawl: `find.text('HP 20 / 20')`, `find.text('Steady')`, and the
   `hpMeterKey` subtree's `LinearProgressIndicator.value == 1.0`.
6. **a hurt hero's meter and word follow the hit points** — `hero.hp` 4 of 20:
   `find.text('HP 4 / 20')`, `find.text('Critical')`, indicator value `0.2`.
   Use 4, not 5: `5 / 20` is exactly `0.25` and `_condition` reads `Wounded` there.
7. **no mana meter until the hero knows a spell** — empty `knownSpells`:
   `find.byKey(manaMeterKey)` findsNothing, `find.textContaining('Mana')`
   findsNothing, `find.byKey(hpMeterKey)` findsOneWidget.
8. **the mana meter reads its own pool** — `knownSpells: {'firebolt'}` with a
   mana fraction deliberately different from the hit-point fraction:
   `find.text('Mana <m> / <max>')`, the `manaMeterKey` indicator value equals
   `mana / maxMana`, and **differs from** the `hpMeterKey` value. The differing
   values are the point: one pool wired into both bars is the plausible bug.
9. **the ward reads beside the pool while one stands** — caster with
   `warded: 2`: `find.text('Ward 2')` findsOneWidget.
10. **no ward when none stands** — the same fixture with `warded: 0`:
    `find.textContaining('Ward')` findsNothing.
11. **the worst case fits a phone without squeezing anything** — `onAPhone`
    (`test/support/phone.dart`), the ruined keep, `depth == deepest`, two
    monsters visible with at least one holding reach, `knownSpells` non-empty,
    `warded: 2`, `hero.hp` 4. Assert `tester.takeException()` is null, that
    `THE RUINED KEEP`, `✖`, `Engaged 2`, `HP 4 / 20`, `Critical` and `Ward 2`
    are all present, and the no-squeeze loop:

    ```dart
    final paragraphs = tester.renderObjectList<RenderParagraph>(
      find.descendant(of: find.byType(CrawlStatus), matching: find.byType(Text)),
    );
    for (final paragraph in paragraphs) {
      expect(
        paragraph.size.width + 0.5,
        greaterThanOrEqualTo(paragraph.getMaxIntrinsicWidth(double.infinity)),
      );
    }
    ```

For staging monsters, visibility, mana and known spells, follow the existing
precedents at `test/battle_characterization_test.dart:39-71` and
`test/battle_view_test.dart:73-105`; `GameState.copyWith`
(`packages/core/lib/src/engine/game_state.dart:301-359`) accepts `hero`,
`monsters`, `visible`, `depth`, `knownSpells`, `mana` and `warded` but **not**
`deepest`, which is carried — use `copyWith(depth: game.deepest)` for the bottom
floor. Do not edit core to make staging easier.

Use real blocs and the real `GameScreen`, never a mock. No golden images
(`AGENTS.md`). Do not assert source text, widget counts as a layout proxy, or a
field copy.

### Migration table — every existing assertion that observed the old string

Twenty-five sites change; the last two rows list six more that must stay green
unchanged. Apply exactly these verdicts; do not invent a new concatenated
string to re-pin.

| File:line | Becomes |
| --- | --- |
| `widget/world_screen_test.dart:1022, 1051, 1080` | `find.text('THE ROAD')` findsOneWidget |
| `widget/world_screen_test.dart:1023, 1052, 1081` | `find.byKey(depthPairKey)` findsNothing (import `crawl_status.dart`) — the old `textContaining('Depth')` negative is vacuous once nothing renders `Depth` |
| `widget/world_screen_test.dart:1340` | `find.text('THE SEA-CAVE')` |
| `widget/world_screen_test.dart:1368` | `find.text('THE RUINED KEEP')` |
| `widget/world_screen_test.dart:1626, 1649` | `find.text('THE SEA-CAVE')` |
| `widget/world_screen_test.dart:1687` | `find.text('THE RUINED KEEP')`; keep the `takeException` assertion verbatim |
| `widget/world_screen_test.dart:1725` | `find.text('2 / 6')`; keep `expect(delveDepth(seaCave, worldSeed, camp.visit), 6)` |
| `widget/world_screen_test.dart:1728-1756` | **rewrite**: delete the `widgetList<Text>(...).single.data!` extraction entirely; assert `find.text('HP 20 / 20')`, `find.text('Steady')`, `find.text('THE SEA-CAVE')`, `find.text('1 / 4')`; keep `onAPhone` and `expect(delveDepth(seaCave, 909, 1), 4)`; retitle to `shows the hit points, the condition and the place at once` |
| `widget/suspend_door_test.dart:281` | `find.text('THE CRYPT')` and `find.text('2 / 5')` |
| `widget/suspend_door_test.dart:355` | `find.text('THE CRYPT')` and `find.text('1 / 5')` |
| `widget/suspend_door_test.dart:189` | `find.byType(GameScreen)` findsNothing (replaces the now-vacuous `textContaining('Depth')`); this file does not reference `GameScreen` yet, so add `import 'package:residuum_app/game/game_screen.dart';` |
| `widget/roster_session_test.dart:71` | `find.text('THE CRYPT')` |
| `widget/boot_wiring_test.dart:76` | `find.text('THE CRYPT')`; keep `find.text('The crawl resumes.')` |
| `widget/boot_wiring_test.dart:145, 161` | `find.byType(GameScreen)` findsNothing |
| `battle_characterization_test.dart:116, 132` | tighten to `find.text('Engaged 1')` / `find.text('Watched 1')`; also fix the stale `// assert` comment at `:113` that says the word is "in the line" — it is now its own cell on the header row |
| `battle_characterization_test.dart:117, 133, 147, 148` | unchanged; must stay green |
| `battle_view_test.dart:290, 557` | **unchanged**; confirm green |

If `2 / 5` is not the crypt's pair in a `suspend_door_test` fixture, assert the
pair the fixture's own `deepest` produces rather than forcing the literal.

Every other test file must pass **with its assertions unchanged**, including
`game_bloc_test.dart`, `world_bloc_test.dart`, `craft_surfaces_test.dart`
(a crawl with a null `dungeon` — the header shows no place and keeps the depth
pair), `log_drawer_test.dart`, `pack_screen_test.dart`, `back_guard_test.dart`
and `character_screen_test.dart`.

## Proof commands

From `packages/app`, after Red and after Green:

```sh
flutter test test/widget/crawl_status_test.dart \
  test/widget/world_screen_test.dart \
  test/widget/suspend_door_test.dart \
  test/widget/roster_session_test.dart \
  test/widget/boot_wiring_test.dart \
  test/battle_characterization_test.dart \
  test/battle_view_test.dart \
  test/widget/log_drawer_test.dart \
  test/widget/craft_surfaces_test.dart \
  test/widget/pack_screen_test.dart \
  test/widget/back_guard_test.dart

dart format --set-exit-if-changed --output=none \
  lib/game/crawl_status.dart lib/game/game_screen.dart \
  test/widget/crawl_status_test.dart test/widget/world_screen_test.dart \
  test/widget/suspend_door_test.dart test/widget/roster_session_test.dart \
  test/widget/boot_wiring_test.dart test/battle_characterization_test.dart

flutter analyze
flutter test
```

`flutter analyze` and the final full `flutter test` are in scope for this task —
you are the unit's only writer, no sibling is editing concurrently, and deleting
a widget observed by six suites has a blast radius wider than the focused list.
Main re-runs the same integrated gate afterwards; that is acceptance, not
duplication. Do not run an app build, an emulator, a device install, or any
external write.

## Executor discretion

Yours: private helper and test-helper names; whether `_placeName`,
`_battleWord` and `_condition` are top-level privates or statics; the exact
fixture staging (seeds, monster positions, `copyWith` shape) for the new tests;
import ordering; whether to carry the device-history rationale as a comment.

Not yours: the public `CrawlStatus` signature or the three key constants; the
file split; row structure, flex weights, gaps or paddings; styles and colours;
the upper-casing rule; the `<value> / <ceiling>` numeric grammar; the
known-spells and ward rules; which helpers die; any verdict in the migration
table; any frozen wording (`doneControl`, `doneAtTheBottom`, `Underfoot:`,
`Here:`, refusal and explanatory sentences).

## Escalate when

- a fact on the current status line has nowhere to land without a third row, a
  new codepoint, or reopening frozen prose;
- the node name cannot be read through `residuumWorld.nodeAt(dungeon).name`
  without touching `core`/`content` or adding bloc/serialized state;
- a rules path is found that sets `warded` for a hero with no known spell (the
  plan's ward rule assumes `step.dart:296-303` is the only source);
- the two rows cannot hold to one extra text row of height without dropping
  below the locked styles or moving a fact off the rows;
- `getMaxIntrinsicWidth` or `takeException` cannot express the no-squeeze proof
  — fall back to exception-plus-presence assertions and **report the weakened
  proof**, do not silently drop it;
- an existing test fails for a preserved behaviour rather than an obsolete
  composition assumption;
- a fix would require `packages/core`, `packages/content`, `main.dart`,
  `skills_screen.dart`, a save/dependency/asset change, a new control or
  relabelling, or implementation on `main`.

Report; do not redesign the contract.

## Handoff state and completion receipt

The task is complete when: `crawl_status.dart` exists with exactly the locked
surface; `_HitPoints`, `_line`, `_magic` and `_whereabouts` are gone;
`game_screen.dart:124`'s replacement is the only change to that file's
composition; the eleven focused tests are green; all twenty-five migrated
assertions are green; `flutter analyze` is clean; the full `flutter test` passes;
formatting is clean on touched files; and nothing outside the named files
changed.

Report to Main in at most eight prose lines:

- branch and base revision, and the Red you observed before the cutover;
- the new file's public surface and confirmation that the old helpers are gone;
- which of the eleven focused tests cover criteria 1–3 and the two gates;
- the migration outcome, naming any assertion whose verdict you had to change
  and why;
- the results of the four proof commands;
- whether the no-squeeze proof landed as planned or fell back;
- anything a device pass must settle (row legibility at the scaled worst case,
  the height delta versus `2b0e0a4`);
- any escalation left open for Main's acceptance review.
