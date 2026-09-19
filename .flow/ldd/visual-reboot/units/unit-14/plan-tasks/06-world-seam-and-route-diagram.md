# Task 06 — The World Seam and the Route Diagram

Owner: one fresh `flow-plan-executor` on the Unit 14 feature checkout.

Read `../CONTRACT.md`, `../PLAN.md` (findings F6 and F8, the type-role tables,
and the "four root-navigator dialogs" note), then
`packages/app/lib/world/world_screen.dart`,
`packages/app/lib/world/world_route_diagram.dart`,
`packages/app/lib/style/tokens.dart`,
`packages/app/lib/town/town_style.dart` and
`packages/app/test/widget/world_screen_test.dart` before editing.

The world map has **no visual baseline anywhere in this epic** — no mock frame,
no parity pair. `VISUAL-SYSTEM.md` §9 settled that it inherits the vocabulary
and gains an evidence gate in its owning unit, which is this one. Design
nothing new; substitute the family and the tokens and prove nothing clips.

All commands run from `packages/app`.

## Starting condition

- Tasks 01–05 are accepted: the token module, `residuumTheme` at five roots,
  `ResourceMeter`, `LabelledValue`, and both seams on aliases;
- `world_screen.dart` still holds **ten** `fontFamily: 'monospace'` literals
  (`:136`, `:141`, `:148`, `:155`, `:186`, `:479`, `:482`, `:487`, `:491`,
  `:558`) and `world_route_diagram.dart` **six** (`:100`, `:110`, `:116`,
  `:199`, `:207`, `:217`);
- both files import `../town/town_style.dart` and read `ink`, `dim`, `rule`,
  `mono`, `monoDim`, `Heading` and `Notice` from it — all of which are now
  aliases of the shared tokens, so those reads keep working;
- `WorldScreen`'s `Scaffold` at `:56` has no `Theme`, and both `showDialog`
  sites at `:131` and `:476` are unthemed.

Inspect branch, HEAD and worktree before editing. If a named seam differs
materially, stop and report.

## Behavioral slice

The overworld and its route diagram render from the shared tokens, the world
screen root opts into `residuumTheme`, its two dialogs and its one
`FilledButton` render no Material 3 default, and **no label in the route
diagram's fixed-width boxes clips** — which is the one place in the application
where a wider all-caps face meets a hard 120 dp clip.

## Owned files

- `packages/app/lib/world/world_screen.dart`;
- `packages/app/lib/world/world_route_diagram.dart`;
- new `packages/app/test/widget/world_diagram_fit_test.dart`;
- `packages/app/test/widget/world_screen_test.dart` — only if a rewrite is
  forced; see below.

Do not touch `world_bloc.dart`, `travel_messages.dart`, anything under
`lib/town/`, `lib/game/`, `lib/style/`, `packages/core` or `packages/content`.

## Locked decisions

### `world_screen.dart`

**The theme site.** `:56` — wrap the `Scaffold` in
`Theme(data: residuumTheme, child: Scaffold(…))`. `WorldScreen` is the
navigator's bottom route, so this is the last screen root in the application
without a theme.

**The type.** Ten literals, replaced by tokens:

| line | today | becomes |
|---|---|---|
| `:183-191` | `RESIDUUM`` 22/ls6/ink | `displayTitle` |
| `:135-137` | travel-dialog title, default size | deleted — `dialogTheme.titleTextStyle` |
| `:138-142` | travel-dialog body 13 | deleted — `dialogTheme.contentTextStyle` |
| `:144-157` | `'Stay here'` / `'Set out'` | deleted — `textButtonTheme.textStyle` |
| `:479` | `_ask` title | deleted — `dialogTheme.titleTextStyle` |
| `:480-483` | `_ask` body 13 | deleted — `dialogTheme.contentTextStyle` |
| `:485-492` | `_ask`'s two actions | deleted — `textButtonTheme.textStyle` |
| `:551-560` | `WorldDoor`'s label 15 | deleted — `filledButtonTheme.textStyle` |

Per the stock-control label rule: each of those six `TextButton`s and the one
`FilledButton` gets `Text(label)` or `const Text('Stay here')` with **no
`style:`**, so `foregroundColor` / `disabledForegroundColor` still carry
enabled and disabled. `WorldDoor` keeps its
`styleFrom(padding: EdgeInsets.symmetric(vertical: 14))`.

**The two dialogs wrap their own theme.** `showDialog` at `:131` and `:476`
defaults to `useRootNavigator: true`, so each `AlertDialog` is a sibling of
`WorldScreen`, not a descendant of its `Theme`. Wrap each in
`Theme(data: residuumTheme, child: AlertDialog(…))`, exactly as
`showCrawlConfirm` does (`crawl_surfaces.dart:145-146`) and as Task 04 did for
the two roster dialogs. Do **not** switch either to `useRootNavigator: false`:
that changes navigation behaviour and is a non-goal.

**The three padded rows at `:196-198`.** `Health   ${town.hp} / ${town.maxHp}`,
`Carried  ${town.gold} gold`, `Banked   ${town.bankedGold} gold` become, using
Task 05's shared widgets:

```text
ResourceMeter(key: worldHealthMeterKey, label: 'Health',
    value: town.hp, ceiling: town.maxHp, tint: MeterTint.health)
LabelledValue(label: 'Carried', value: '${town.gold} gold')
LabelledValue(label: 'Banked',  value: '${town.bankedGold} gold')
```

Add `const worldHealthMeterKey = Key('world-health-meter');`. Health only — the
world screen shows no mana today and mana is crawl-only state.

`_Standing`'s `where` sentence in `mono`, `_dayLine` in `monoDim`, the
`Divider(color: rule, height: 20)` at `:195`, `_Here`, `_CampLost`,
`_CampWarning`, `_confirmTravel`'s `routeBetween` guard and day arithmetic,
`_ask`'s return semantics, every `Heading`, the `ListView`, the `Expanded`, and
every callback and string are **unchanged**.

### `world_route_diagram.dart`

**The type.** Six literals, replaced by tokens. `_nodeWidth = 120.0` and
`_nodeHeight = 72.0` at `:25-26` are **unchanged**, as is every
`overflow: TextOverflow.clip`, every `maxLines: 1`, `_offset`, `_nodeCenter`,
`_routeOrder`, `_kindLabel`, `_kindWord`, `_stateLabel`, `_MarkerShape`,
`_UnknownMarker` and every `Semantics` label and `OrdinalSortKey`.

| line | today | becomes |
|---|---|---|
| `:99-103` | `'n DAY(S)'` 10/ink | `textMicro` |
| `:109-111` | `'ON THIS ROAD'` 9/ink | `textMicro` |
| `:115-119` | `'DANGER n/100'` 10/dim | `textMicroDim` |
| `:198-202` | node kind word 9/dim | `textMicroDim` |
| `:206-210` | node name 11/ink | `textDetail` |
| `:216-220` | node state 9/dim | `textMicroDim` |

**Every one of these is a plain alias — no `copyWith` anywhere.** An earlier
version of this brief mandated `textMicro.copyWith(color: ink)` at the first
two rows and `textDetail.copyWith(color: ink)` at the node name. Architect
amendment **A8** struck that: `copyWith` is not const-evaluable, `:109-111`
is a `const Text`, and the other two allocate per build in a diagram that
rebuilds on every world state change. `textDetail` and `textMicro` are now
**ink primaries** with `textDetailDim` and `textMicroDim` beside them, landed
before this task starts. If you find yourself reaching for `copyWith` on a
token here, the role you want already exists.

**`textMicro` is 9 px and stays 9 px.** The two 10 px rungs come *down* to 9,
and that direction is deliberate: `TRAVEL IN PROGRESS` is 16 letters and 2
spaces, and at Spectral's 0.707 em caps advance it measures ≈ 108 dp at 9 px
against the 120 dp box — but ≈ 118 dp at 10 px, inside 2 dp of clipping. The
node name comes down from 11 to `textDetail`'s 11 unchanged.

`_UnknownMarker` at `:373-389` draws `Text('?', style: mono)` — the alias
carries it; do not edit it. The `?` is covered by Spectral (verified in Task
01's coverage test).

Legibility note for the receipt, not a change: caps at 9 px in Spectral have a
cap height of 5.94 px against monospace's ~6.3 px, so the diagram's micro labels
read comparably. Mixed-case at 9 px would not, which is why the node *name*
takes the 11 px rung.

## Executor discretion

Yours without asking:

- whether the two dialog `Theme` wraps are written inline or share a tiny
  local helper inside `world_screen.dart`;
- the new key name for the world health meter;
- how `world_diagram_fit_test.dart` stages "every node discovered with a
  journey in progress" — reuse `test/support/world_nav.dart` and the existing
  `world_screen_test.dart` helpers rather than writing new ones;
- whether group 1 walks paragraphs in one loop or asserts per node;
- the `reason:` strings, so long as the widest measured width is recorded.

Not yours: `textMicro` staying at 9 px, `_nodeWidth`, `_nodeHeight`, any
`TextOverflow.clip` or `maxLines`, any `Semantics` label or `OrdinalSortKey`,
the `useRootNavigator` defaults, health-only on the world screen, or which
token each of the six diagram sites takes.

## Red proof

Write `test/widget/world_diagram_fit_test.dart` **first**.

### 1. No diagram label is clipped

At `onAPhone`, with every node discovered **and** a journey in progress, so that
`TRAVEL IN PROGRESS`, `NO ROAD FROM HERE`, `ON THIS ROAD`, `HERE` and
`REACHABLE` all render somewhere, and with the longest node name in
`residuumWorld` on screen:

- every `RenderParagraph` under a `world-node-*-shape` key has
  `didExceedMaxLines == false`;
- every route-label `RenderParagraph` has `didExceedMaxLines == false`;
- `tester.takeException()` is null.

Reach the paragraphs with `tester.renderObjectList<RenderParagraph>(
find.descendant(of: find.byKey(…), matching: find.byType(RichText)))`, the same
idiom `crawl_action_row_test.dart:315-322` and `crawl_status_test.dart:358` use.

**This test is expected to pass before and after**, and that is the point: it
is the regression that proves the 9 px micro rung was the right choice and that
nothing in the diagram clips at phone width under a face whose caps are 12%
wider per glyph. Record in the receipt that it passed on both sides, with the
widest measured paragraph width against the 120 dp box.

If it fails **Green**, the escalation is to keep 9 px and shorten nothing: the
state strings are the game's own words and `VISUAL-SYSTEM.md` §7 locks the
game's words over the mock's.

### 2. The world screen renders no Material 3 default

Build the reference inside the test, exactly as
`test/style/material_palette_test.dart` does:

```dart
final m3 = ThemeData(brightness: Brightness.dark, useMaterial3: true);
```

- `WorldDoor`'s rendered fill equals `raised` and is not
  `m3.colorScheme.primary`;
- the travel dialog's rendered surface equals `panel` and is not
  `m3.colorScheme.surface`; both its actions' rendered foreground equals `ink`
  and is not `m3.colorScheme.primary`;
- the `_ask` dialog, reached through the give-up-the-camp door, the same.

**Expected Red: all of them equal the M3 default**, because the world screen
has never had a theme.

### 3. The world's health meter and two value rows

- under `worldHealthMeterKey` the rendered text carries `town.hp` and
  `town.maxHp`, and the indicator's `value` equals `hp / maxHp`;
- `Carried` and `Banked` each render as a label and a value, and the two
  values' rendered `left` is identical.

**Expected Red: the finders find nothing.**

### Run

```text
flutter test test/widget/world_diagram_fit_test.dart
```

### Must stay green

```text
flutter test test/widget/world_screen_test.dart test/world_bloc_test.dart test/widget/roster_session_test.dart test/widget/back_guard_test.dart test/widget/suspend_door_test.dart test/widget/door_reentry_test.dart test/widget/town_shell_test.dart test/style/material_palette_test.dart
```

`world_screen_test.dart` is large and is the whole regression for this task:
every travel confirmation, every camp fork, every refusal sentence, the roster
door, `:324`'s and `:1689`'s `takeException` checks and `:666`/`:733`'s
`scrollUntilVisible` calls. It contains no type or colour literal, so it should
pass unedited.

**Two expected rewrites, both on the world screen's three status rows:**

1. `suspend_door_test.dart:119` asserts
   `find.textContaining('Health   6 /')` after tapping `Leave` out of a crawl,
   which lands on the world screen. It becomes the meter assertion: under
   `worldHealthMeterKey` the rendered text carries `6` and the hero's ceiling.
   `expect(app.saved!.profile.hero.hp, 6)` on the next line is **unchanged** —
   that is the save assertion and it is the point of the test;
2. if `world_screen_test.dart` pins `find.text('Health   n / n')`,
   `find.text('Carried  n gold')` or `find.text('Banked   n gold')`, rewrite
   those the same way — the meter assertion for health, label-and-value for the
   other two.

Record each before and after. Nothing else in either file changes, and neither
rewrite changes what the test defends: that the world screen states the hero's
health against its ceiling, and that leaving a crawl preserves it.

## Green proof and package gates

```text
flutter test test/widget/world_diagram_fit_test.dart test/widget/world_screen_test.dart
dart format --set-exit-if-changed --output=none lib test
flutter analyze
flutter test
```

Then, recorded in the receipt:

```text
grep -rn "fontFamily"    lib/world
grep -rn "monospace"     lib/world
grep -rn "TextStyle("    lib/world
grep -rn "'Health   \|'Carried  \|'Banked   " lib/world
grep -rn "residuumTheme" lib/world
```

Expected: the first four return nothing; the fifth returns `world_screen.dart`
three times — the `Scaffold` wrap and the two dialog wraps.

## Acceptance

- `world_screen.dart` and `world_route_diagram.dart` hold no `fontFamily`, no
  `TextStyle` and no occurrence of "monospace";
- `WorldScreen`'s `Scaffold` and both `AlertDialog`s wrap `residuumTheme`, and
  neither `showDialog` call changed its `useRootNavigator` default;
- `WorldDoor` and both dialogs render tokens, not M3 defaults;
- the world screen renders a health meter and two `LabelledValue`s;
- no diagram paragraph exceeds its box, proved at `onAPhone` with a journey in
  progress and every node discovered, and the widest measured width recorded;
- `_nodeWidth`, `_nodeHeight`, every `TextOverflow.clip`, every `maxLines`,
  every `Semantics` label, every `OrdinalSortKey` and every string in the
  diagram are unchanged;
- `world_screen_test.dart` and `suspend_door_test.dart` pass with only the two named status-row rewrites, each recorded before and after;
- all three package gates green.

## Escalate, do not decide

- a diagram paragraph clipping at 9 px — shortening a state string, widening
  `_nodeWidth` or dropping a label are all out of scope; report the measured
  width and the string;
- any need to redesign the diagram, its marker shapes, its node geometry or its
  route layout — nothing in this epic has assigned that work, and the world map
  has no approved frame;
- any need to add mana to the world screen;
- any `world_screen_test.dart` rewrite beyond the three padded strings, or one
  that would change what a test defends.

## Receipt

Report: the observed Red for groups 2 and 3, and the pass-on-both-sides result
for group 1 with the widest measured paragraph width against 120 dp; the two
status-row rewrites with before and after and one sentence each naming what
they now defend; the five audit greps; and the three package gates.
