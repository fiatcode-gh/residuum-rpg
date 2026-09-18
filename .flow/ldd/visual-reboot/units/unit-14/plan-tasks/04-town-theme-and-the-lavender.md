# Task 04 — The Town Seam onto the Tokens, the Theme at Its Roots, the Lavender Gone

Owner: one fresh `flow-plan-executor` on the Unit 14 feature checkout.

Read `../CONTRACT.md` (AC4, AC5 and the "Sibling themes" section),
`../PLAN.md` (finding F9, "The one deliberate interpretation", the
"`residuumTheme`" table and "The stock-control label rule"), then
`packages/app/lib/town/town_style.dart`,
`packages/app/lib/town/town_screen.dart`,
`packages/app/lib/town/character_screen.dart`,
`packages/app/lib/town/forge_screen.dart`,
`packages/app/lib/town/gear_screen.dart`,
`packages/app/lib/town/roster_screen.dart`,
`packages/app/lib/game/pack_screen.dart`,
`packages/app/lib/style/tokens.dart` and
`packages/app/test/widget/pack_screen_test.dart` before editing. Look at frames
1, 6, 8, 9 and 10 of
`.flow/evidence/visual-reboot/residuum_visual_reboot_approved_mock.png` and at
`.flow/evidence/visual-reboot/unit-13-parity/pair-06-character*`,
`pair-08-pack*`, `pair-09-forge*`, `pair-10-tavern*`.

All commands run from `packages/app`.

## Starting condition

- Tasks 01–03 are accepted: `lib/style/tokens.dart` holds the ladder, the
  rhythm, the eighteen roles, `residuumTheme` and the two meter hues;
  `lib/style/surfaces.dart` holds `ResourceMeter`; `crawl_style.dart` is
  aliases only and `crawlTheme` is gone;
- `town_style.dart:9-12` still declares four `Color` literals and `:14-49,67-72`
  still declares seven `TextStyle`s with `fontFamily: 'monospace'`;
- every one of finding F9's ten control families still renders in the Material 3
  default palette;
- the town half of the tree has **never** had a theme.

Inspect branch, HEAD and worktree before editing. If a named seam differs
materially, stop and report.

## Behavioral slice

Every town and pack screen root opts into `residuumTheme`, the town seam renders
from the shared tokens with no colour literal and no `TextStyle` of its own, and
**no stock Material control on any of those screens renders in Material 3's
default palette** — including the four named lavender cases and the six the
audit did not name.

Row anatomy, control geometry, chip geometry and every navigation path are
unchanged. The numeric alignment slots and the town's meters are **Task 05**,
not here.

## Owned files

- `packages/app/lib/town/town_style.dart`;
- `packages/app/lib/town/town_screen.dart`;
- `packages/app/lib/town/character_screen.dart`;
- `packages/app/lib/town/forge_screen.dart`;
- `packages/app/lib/town/gear_screen.dart`;
- `packages/app/lib/town/roster_screen.dart`;
- `packages/app/lib/game/pack_screen.dart`;
- new `packages/app/test/style/material_palette_test.dart`.

**Do not edit** `inn_screen.dart`, `bank_screen.dart`, `merchant_screen.dart`,
`alchemist_screen.dart`, `spells_screen.dart`, `skills_screen.dart`,
`town/pack_screen.dart`, `illustration.dart`, `town_bloc.dart`, `town_crawl.dart`,
`notice/notice.dart`, anything under `lib/game/` except `game/pack_screen.dart`,
anything under `lib/world/`, `tokens.dart`, `surfaces.dart`, `packages/core` or
`packages/content`.

Verified at `5ac1a49`: the nine un-owned town and shared files consume
`mono` / `monoDim` / a style parameter only, so the aliases below carry them
untouched. If one of them turns out to hold an inline style, stop and report —
do not widen the diff.

## Locked decisions

### `town_style.dart` becomes aliases, plus the town's own

Import the token module. Then:

**Colours** — all four are duplicates and become aliases. No `Color(0x` literal
survives:

```dart
const Color ink = tokenInk;    // or the token's own name; see note
const Color dim = tokenDim;
const Color panel = tokenPanel;
const Color rule = tokenRule;
```

The token module's own names for these are `ink`, `dim`, `panel`, `rule`
(`../PLAN.md`'s ladder table), which collide with `town_style.dart`'s exports of
the same name. Resolve with an import prefix — `import '../style/tokens.dart' as
tokens;` — and alias `const Color ink = tokens.ink;`. **Do not rename the
token** and **do not rename the town's export**: ~20 files and a dozen tests
read `ink`, `dim`, `panel`, `rule`, and `crawl_surfaces_test.dart:298-299`
reads them under a `town.` prefix. A prefix at one import site is the whole
cost.

**Type** — the seven declarations become aliases:

| was | becomes |
|---|---|
| `mono` (14) | `textBody` |
| `monoDim` (12/dim) | `textLineDim` |
| `placeName` (20/ls5) | `displayPlace` |
| `roomName` (15/ls4) | `displayRoom` |
| `Heading`'s inline style at `:67-72` (11/ls2/dim) | `displayCaption` |
| `ItemRow`'s button style at `:166` (12) | deleted — see the label rule |
| `Commit`'s style at `:382` (15) | deleted — see the label rule |

`markColumn` at `:31` is **town-owned and unchanged at 28**. Its dartdoc at
`:26-31` and `MaterialRows`' at `:202-205` both contain the word "monospace":
reword both so the word does not survive while the warning does —
"the markings are not all one cell wide in the text face, and a column that
drifts by two pixels steps sideways on the phone. A device pass caught exactly
that." **That warning is a Trap the contract protects; deleting it is a
defect.**

`NothingHere`, `ItemRow`'s body, `Purse`, `MaterialRows`, `Notice`,
`CountStepper`, `Commit`'s structure and `TownRoom`'s structure are otherwise
unchanged. `Purse` is **Task 05's**.

### The three theme sites

- `town_style.dart:396` — wrap `TownRoom`'s `Scaffold` in
  `Theme(data: residuumTheme, child: Scaffold(…))`. One site covers twelve
  screens: alchemist, bank, character, forge, gear, inn, merchant, roster,
  skills, spells, tavern and the town pack route;
- `town_screen.dart:59` — the same wrap around `TownScreen`'s own `Scaffold`;
- `game/pack_screen.dart:15` — the same wrap around `CrawlPackScreen`'s
  `Scaffold`. It is pushed on the root navigator from the crawl
  (`game_screen.dart:293-300`) and so is a sibling of `GameScreen`, not a
  descendant of its `Theme`; this wrap is what gives it a theme at all.

All three `AppBar`s keep their explicit `backgroundColor: panel,
foregroundColor: ink` (`town_style.dart:397`, `town_screen.dart:60`,
`game/pack_screen.dart:18-19`). Those are token-sourced, not literals, and
`crawl_surfaces_test.dart:297-300` asserts the constructor argument. Do not move
them into `appBarTheme`.

### The four root-navigator dialogs

`roster_screen.dart:131` and `:175` and — in Task 06 — `world_screen.dart:131`
and `:476` call `showDialog`, which defaults to `useRootNavigator: true`. Each
is therefore mounted **outside** the `Theme` its screen opted into. Wrap each
builder's `AlertDialog` in `Theme(data: residuumTheme, child: AlertDialog(…))`,
exactly as `showCrawlConfirm` already does (`crawl_surfaces.dart:145-146`), so
appearance is correct by construction rather than by reasoning about
`InheritedTheme` capture.

Do **not** switch them to `useRootNavigator: false`: the roster dialogs are
opened from a screen the session can replace, and moving them off the root
navigator changes navigation behaviour, which is a non-goal.

### The stock-control label rule — applied at every site

For a stock `FilledButton`, `TextButton` or `ChoiceChip`, the label's metrics
come from the control's theme and **the call site passes `Text(label)` with no
`style:`**. `ButtonStyleButton` resolves `foregroundColor` /
`disabledForegroundColor` over the theme's `textStyle`; a call-site
`inherit: false` style carrying a colour would win outright and freeze a
disabled label at full ink, losing the dimming that
`disabled_controls_test.dart` and the inn's and bank's dead-control rule depend
on.

Site by site:

| file:line | change |
|---|---|
| `character_screen.dart:50-57,64-71,78-85,92-99` | four `FilledButton`s: child becomes `const Text('Gear')` / `'Spells'` / `'Skills'` / `'Pack'`, no `style:`. Keys, `onPressed`, `_open`, the `SizedBox(width: double.infinity)` and the `Padding(vertical: 4)` unchanged |
| `town_style.dart:157-169` (`ItemRow`) | child becomes `Text(action, maxLines: 1, overflow: TextOverflow.ellipsis)`; the `styleFrom` gains `textStyle: textLabel` beside its existing `padding`, because a 104 dp trailing control wants the label rung, not the action rung |
| `town_style.dart:375-385` (`Commit`) | child becomes `Text(label)`, no `style:`; `styleFrom(padding: vertical 16)` unchanged. `filledButtonTheme.textStyle` gives it `textAction` |
| `gear_screen.dart:73-87` | child becomes `const Text('Take off', maxLines: 1)`; the `styleFrom` gains `textStyle: textLabel` beside its existing `padding` |
| `forge_screen.dart:161-168` | child becomes `const Text('Temper')`; **delete** `style: TextButton.styleFrom(foregroundColor: ink)` — `textButtonTheme` carries it now |
| `roster_screen.dart:311-318` | child becomes `const Text('Delete', maxLines: 1)`; **delete** `styleFrom(foregroundColor: ink)` |
| `roster_screen.dart:133-157` | dialog: delete the title, content and both action styles; `dialogTheme.titleTextStyle` / `contentTextStyle` and `textButtonTheme.textStyle` carry them. Wrap in `Theme` |
| `roster_screen.dart:238-259` | the same, plus the `TextField` at `:243-247`: delete `style: mono` and the `decoration: InputDecoration(border: OutlineInputBorder())` — `inputDecorationTheme` carries both. Keep `controller`, `autofocus` |
| `game/pack_screen.dart:16-20` | `AppBar` title becomes `const Text('Pack')`; `appBarTheme.titleTextStyle` carries `displayPanel` |
| `game/pack_screen.dart:103-113` | `ChoiceChip`: unchanged. `chipTheme` carries fill, border, label and checkmark. **Keep `showCheckmark: true` at the call site** — it is the non-hue cue that carries selection |
| `game/pack_screen.dart:286-296` | `_actionButton`: child becomes `Text(label)`, no `style:`; `styleFrom(padding:)` unchanged |
| `town_screen.dart:201-215` (`_Door`) | **delete** `foregroundColor: ink` from the `styleFrom`; keep `alignment` and `padding`. The two child `Text`s keep their explicit `mono` / `monoDim` styles, because a door's title and purpose are not a button label — they are two rows of content inside a tap target |

`town_screen.dart`'s `placeName` / `monoDim` / `Heading` / `MaterialRows` /
`Notice` / `Illustration` / `Spacer` / seven doors / `_titleFor` /
`_descentsSoFar` / `_open` and the `LayoutBuilder` + `ConstrainedBox` +
`IntrinsicHeight` + `SingleChildScrollView` spine are **unchanged**. The
`Health` / `Carried` / `Banked` rows at `:76-80` are Task 05's.

### What this task does not do

- no `LabelledValue`, no fixed-width label slot, no meter — Task 05;
- no framed row, no medallion, no chevron, no chip redesign, no Forge door
  split, no locked spells section, no hidden empty section — U15;
- no illustration header, no portrait, no status-block relocation — U17;
- no change to `inn_screen.dart` — **architect amendment A3 authorised its two
  padded rows at `:45-46`, and they belong to Task 05** with the other five
  sites. Nothing in that file is this task's;
- no alias deleted from either seam. The alias strategy stays load-bearing
  until Task 08 retires it in one reviewable commit (A4).

## Executor discretion

Yours without asking:

- the import-prefix name for the token collision (`tokens`, `t`, anything
  readable) and where the alias block sits in `town_style.dart`;
- whether the two `Theme` wraps in `town_style.dart` and `town_screen.dart`
  are written inline or through a tiny local helper — but do not add a public
  widget for it;
- the grouping and naming of `material_palette_test.dart`'s groups and
  helpers, and whether the eight rows are eight `testWidgets` or fewer with
  shared pumps, so long as the four named cases are findable by name;
- how each screen is pumped in that test — reuse the existing helpers in
  `character_screen_test.dart`, `pack_screen_test.dart`, `craft_rooms_test.dart`
  and `tavern_screen_test.dart` rather than writing new ones;
- which tuning constant to reach for first if a `takeException` fires, inside
  `../PLAN.md`'s envelopes.

Not yours: which name aliases which role, the three theme sites, the two
dialog wraps, the stock-control label rule, the two `textStyle` overrides, the
`AppBar` colours staying at their call sites, or `showCheckmark: true`.

## Red proof

Write `test/style/material_palette_test.dart` **first**. This is AC4's test and
the unit's most important new one.

Build the reference **inside the test**, so no lavender hex is ever written down
and a framework palette change cannot make the test lie:

```dart
final m3 = ThemeData(brightness: Brightness.dark, useMaterial3: true);
```

Read every rendered value from the tree, never from a constructor argument:

```dart
Color fillOf(WidgetTester tester, Finder control) => tester
    .widget<Material>(
      find.descendant(of: control, matching: find.byType(Material)).first,
    )
    .color!;
```

For each row below, in a real pumped screen, assert **two things and only two**:
the rendered fill or foreground **equals** the token named, and it is **not**
the `m3` colour named.

**There is no third, fill-versus-surface contrast assertion — architect
amendment A6, 2026-09-18.** An earlier version of this brief asked each row to
prove its fill's luminance differed from its surface by ≥ 1.5 : 1. **It is
struck, not retuned.** The arithmetic against this ladder:

| pair | WCAG `(L+0.05)/(l+0.05)` | plain `Lmax/Lmin` |
|---|---:|---:|
| `raised` vs `ground` | 1.153 : 1 | 2.643 : 1 |
| `raised` vs `panel` | 1.076 : 1 | **1.491 : 1** |
| `recessed` vs `panel` | 1.038 : 1 | 1.313 : 1 |

Rows 1, 3, 4, 5 and 7 all sit on `panel`, so the threshold fails under either
reading, and the only way to make it pass is to lower it — which turns the
assertion into decoration. **If you find yourself tuning a contrast threshold
in this test, stop: the assertion does not belong here.** This value ladder is
deliberately low-contrast and a control's boundary comes from its 1 dp `rule`
border, not from its fill. The two assertions above are host-independent,
cannot be satisfied by accident and cannot be satisfied by tuning a number, and
they carry all of AC4's content. See `../PLAN.md` §"Why there is no third,
fill-versus-surface contrast assertion (A6)".

| # | control, and how to reach it | token | must not equal |
|---|---|---|---|
| 1 | the four `character-route-*` `FilledButton`s | `raised` | `m3.colorScheme.primary` |
| 2 | `pack-filter-all` selected, `pack-filter-potions` unselected | `armedFill`, `raised` | `m3.colorScheme.secondaryContainer`, `m3.colorScheme.surfaceContainerLow` |
| 3 | the Forge's `Smelt` (`Commit`) | `raised` | `m3.colorScheme.primary` |
| 4 | the Tavern's `Ask …` (`ItemRow`) | `raised` | `m3.colorScheme.primary` |
| 5 | gear's `gear-take-off-*` | `raised` | `m3.colorScheme.primary` |
| 6 | a pack row action (`pack-drop-*`) — foreground | `ink` | `m3.colorScheme.primary` |
| 7 | the roster delete dialog's surface, and both its actions' foreground | `panel`, `ink` | `m3.colorScheme.surface`, `m3.colorScheme.primary` |
| 8 | the roster name dialog's `TextField` — the focused border's colour and the cursor colour | `ink` | `m3.colorScheme.primary` |

Rows 1–4 are the contract's four named cases and must be named as such in the
test's own group names, so a reader can find them.

Add, in the same file:

- **the selected chip still carries its checkmark** — `pack-filter-all`
  selected renders a check, because `armedFill` against `raised` is only a
  1.163 : 1 WCAG (1.763 : 1 plain) value step and shape is what carries
  selection in greyscale. The filter chip's own form is U15's gap 8.1 and is
  not improved here, and **that weak step is not a defect to fix with a
  threshold** (A6);
- **a disabled control reads dimmer than an enabled one** — the Forge's `Smelt`
  at a pending count of zero has a rendered fill of lower luminance than at a
  pending count of one, and its label's rendered colour is dimmer. This is the
  assertion that catches the stock-control label rule being broken by a
  call-site `style:`.

**Expected Red:** for all eight rows the "must not equal" assertion fails,
because every one of them renders the M3 default today, and the "equals the
token" assertion fails because the tokens are not applied. Those two are the
whole of it — there is no third to fail, and no row's Red depends on a ratio.
Record the observed failure for rows 1–4 verbatim.

### Run

```text
flutter test test/style/material_palette_test.dart
```

### Must stay green

```text
flutter test test/widget/town_shell_test.dart test/widget/character_screen_test.dart test/widget/pack_screen_test.dart test/widget/bank_screen_test.dart test/widget/merchant_screen_test.dart test/widget/tavern_screen_test.dart test/widget/craft_rooms_test.dart test/widget/craft_surfaces_test.dart test/widget/roster_screen_test.dart test/widget/roster_refusal_test.dart test/widget/roster_session_test.dart test/widget/count_stepper_test.dart test/widget/town_illustration_test.dart test/widget/crawl_surfaces_test.dart test/town/town_crawl_carry_test.dart
```

These twenty-six widget-type finders are why the theme-not-replace decision was
made, and each must keep working:
`character_screen_test.dart:218` (`widget<FilledButton>`),
`pack_screen_test.dart:96-97,171,452,455,528,647,692` (`widget<ChoiceChip>`,
`widget<TextButton>`),
`bank_screen_test.dart:145,153,181,185,206,220,236,250`,
`craft_rooms_test.dart:136,290,505,549,679`,
`crawl_surfaces_test.dart:298-299` (`appBar.backgroundColor == town.panel`).

Two known-at-risk sites, both `takeException(), isNull` overflow tripwires under
the new metrics:

- `town_shell_test.dart:138` and `:148` — "the last door is reachable on a
  600-pixel-tall screen", which scrolls to every door. Spectral is 20–30%
  narrower in mixed case, so the purposes get shorter, but `placeName` in
  `displayPlace` is all-caps and 12% wider per glyph;
- `pack_screen_test.dart:572` and `:731`, and `character_screen_test.dart:302`.

Any of these firing is a **real overflow** at phone width, not a test problem.
Fix it inside the tuning envelopes in `../PLAN.md`'s dp gate.

`town_shell_test.dart:190-193`'s padded-string assertions and
`character_screen_test.dart:111-118`'s are expected to keep passing here,
because `mono` still composes the same strings; they become Task 05's rewrite.

## Green proof and package gates

```text
flutter test test/style/material_palette_test.dart
dart format --set-exit-if-changed --output=none lib test
flutter analyze
flutter test
```

Then the scoped audit, recorded in the receipt:

```text
grep -n  "Color(0x"          lib/town/town_style.dart
grep -n  "TextStyle("        lib/town/town_style.dart
grep -rn "fontFamily"        lib/town lib/game/pack_screen.dart
grep -rn "monospace"         lib/town lib/game/pack_screen.dart
grep -rn "residuumTheme"     lib
```

Expected: the first four return nothing; the fifth returns `tokens.dart`,
`main.dart`, `game_screen.dart`, `crawl_surfaces.dart` (×2),
`town_style.dart`, `town_screen.dart`, `game/pack_screen.dart`,
`roster_screen.dart` (×2).

## Acceptance

- `town_style.dart` declares no colour literal and no `TextStyle`; `ink`, `dim`,
  `panel`, `rule`, `mono`, `monoDim`, `placeName` and `roomName` all still
  export as aliases; `markColumn` is still 28 and both device-metric dartdocs
  keep their warning without the word;
- `TownRoom`, `TownScreen` and `CrawlPackScreen` each wrap their `Scaffold` in
  `Theme(data: residuumTheme, …)`; both roster dialogs wrap their own;
- every control in the eight-row table renders its token and is not the M3
  default — **two assertions per row, and no third**, proved by
  `material_palette_test.dart`, with the four named cases in their own named
  groups;
- **no contrast or luminance-ratio threshold appears anywhere in
  `material_palette_test.dart`** (A6);
- the selected filter chip still renders a checkmark; a disabled `Commit` still
  reads dimmer than an enabled one;
- no stock control was replaced by a custom one, and the diff proves it;
- the fifteen-file must-stay-green list passes;
- all three package gates green.

## Escalate, do not decide

- a `takeException` overflow you cannot clear inside the type envelopes in
  `../PLAN.md`'s dp gate;
- any need to replace a stock control with a custom one, or to change a row's
  anatomy, a control's geometry, a chip's shape or a padding — all U15's;
- any need to edit `inn_screen.dart` — its two authorised rows are Task 05's —
  or any file in the do-not-edit list;
- **any temptation to add a contrast or luminance-ratio assertion, or to
  restore the one A6 struck.** If a control's boundary seems to need proving,
  say so and stop: the answer is the 1 dp `rule` border, and it is a device
  judgement, not a threshold;
- an un-owned town file turning out to hold an inline `TextStyle` or colour
  literal;
- a test in the must-stay-green list whose rewrite would change **what it
  defends** rather than which value it names;
- the selected-vs-unselected chip step reading as one state in greyscale — that
  is real, and its remedy is U15's filter chip, not a hue.

## Receipt

Report: the observed Red for the four named cases; every control in the
eight-row table with its rendered token and the `m3` colour it no longer
equals; **an explicit statement that no contrast threshold was added** (A6);
the five audit greps; which import prefix was used for the token collision; any
type-envelope tuning and its reason; the must-stay-green list's result; and the
three package gates.
