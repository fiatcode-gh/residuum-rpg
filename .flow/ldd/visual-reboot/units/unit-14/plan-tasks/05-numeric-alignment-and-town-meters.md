# Task 05 — Numeric Alignment by Layout, and the Town's Two Meters

Owner: one fresh `flow-plan-executor` on the Unit 14 feature checkout.

Read `../CONTRACT.md` (the Typography section's numeric-alignment rule, and
AC6), `../PLAN.md` (finding F7 and the `LabelledValue` part of
"`lib/style/surfaces.dart`"), then
`packages/app/lib/town/town_screen.dart`,
`packages/app/lib/town/character_screen.dart`,
`packages/app/lib/town/town_style.dart`,
`packages/app/lib/style/surfaces.dart`,
`packages/app/test/widget/town_shell_test.dart` and
`packages/app/test/widget/character_screen_test.dart` before editing. Look at
frames 1 and 6 of
`.flow/evidence/visual-reboot/residuum_visual_reboot_approved_mock.png`.

All commands run from `packages/app`.

## Starting condition

- Tasks 01–04 are accepted: the token module, `ResourceMeter`, the crawl and
  town seams and `residuumTheme` at five roots are all in place; no stock
  control on a town screen renders in the M3 default palette;
- `lib/style/surfaces.dart` holds `MeterTint` and `ResourceMeter` and **no
  `LabelledValue`**; `tokens.dart` has **no `labelColumn`**;
- the six padded-label sites of finding F7 are still padded strings, and
  `town_shell_test.dart:190-193` and `character_screen_test.dart:111-118` still
  pin them verbatim, the former with the comment "verbatim including their
  double spaces";
- the town screen and the character screen still print health as text;
- **architect amendment A3, 2026-09-18: `inn_screen.dart:45-46` is authorised
  and the contract's boundary is widened by those two lines.** They convert
  here with the other five sites; residual R6 is closed.

Inspect branch, HEAD and worktree before editing. If a named seam differs
materially, stop and report.

## Behavioral slice

Every value column in the town holds still because a fixed-width slot holds it,
not because a label was padded with spaces — which only ever worked in
monospace, as `town_style.dart`'s own dartdoc has recorded since a device pass
caught it. The town screen and the character screen render health, and the
character screen mana, through the one shared `ResourceMeter`.

## Owned files

- `packages/app/lib/style/tokens.dart` — `labelColumn` only;
- `packages/app/lib/style/surfaces.dart` — append `LabelledValue` only;
- `packages/app/lib/town/town_style.dart` — `Purse` only;
- `packages/app/lib/town/town_screen.dart`;
- `packages/app/lib/town/character_screen.dart`;
- `packages/app/lib/town/inn_screen.dart` — `:45-46` only (**A3**);
- `packages/app/test/widget/town_shell_test.dart`;
- `packages/app/test/widget/character_screen_test.dart`;
- `packages/app/test/widget/craft_rooms_test.dart` — only if the inn's two rows
  are pinned there; see below.

**Do not edit** `lib/world/world_screen.dart:196-198` — Task 06 owns that file
and those three rows go with it.

Also do not edit `bank_screen.dart`, `merchant_screen.dart`,
`alchemist_screen.dart`, `spells_screen.dart`, `skills_screen.dart`,
`gear_screen.dart`, `forge_screen.dart`, `roster_screen.dart`, anything under
`lib/game/`, `packages/core` or `packages/content`.

## Locked decisions

### `labelColumn`

Append to `tokens.dart`, beside the rhythm values:

```dart
const double labelColumn = 96;
```

The widest label in the set is `Skills trained` at 14 characters: in
`textLineDim` at 13 px, Spectral's ~0.47 em mean for mixed case gives ≈ 86 dp,
plus a 10 dp gap. Carry a dartdoc recording that this is the fixed-width slot
the contract requires where a whole column must hold still, and that the padded
strings it replaces aligned only in monospace.

The town's `markColumn` at `town_style.dart:31` stays 28 and stays town-owned.
Two constants, two jobs: `markColumn` is a leading glyph cell, `labelColumn` is
a leading word cell.

### `LabelledValue`

Append to `lib/style/surfaces.dart`:

```dart
class LabelledValue extends StatelessWidget {
  const LabelledValue({required this.label, required this.value, super.key});

  final String label;
  final String value;
}
```

Renders:

```text
Row(
  SizedBox(width: labelColumn, child: Text(label, style: textLineDim)),
  Expanded(child: Text(value, style: textBody)),
)
```

`textBody` already carries `FontFeature.tabularFigures()`, so the digits in the
value cell cannot jitter between frames. The label takes the dim rung and the
value the ink rung, which is the mock's own split — grey label, white value,
right of it.

It adds no medallion, no chevron, no border, no hairline and no control, so it
is **not** the row anatomy U15 owns. It is the fixed-width slot the contract
mandates, the same mechanism `markColumn` already uses in the town.

Carry one dartdoc recording why the slot exists: a padded string aligns only in
a monospaced face, and the face is no longer monospaced.

### `town_screen.dart`

`:76-80` — the three rows become, in the same order and inside the same
`Column`:

```text
ResourceMeter(key: townHealthMeterKey, label: 'Health',
    value: state.hp, ceiling: state.maxHp, tint: MeterTint.health)
LabelledValue(label: 'Carried', value: '${state.gold} gold')
LabelledValue(label: 'Banked',  value: '${state.bankedGold} gold')
```

Add `const townHealthMeterKey = Key('town-health-meter');` beside the file's
other keys, so the rewritten test has a handle.

**Health only.** The town screen shows no mana today, and mana is crawl-only
game state (`GameState.mana`; `TownViewState` has no mana getter) — adding one
would invent information. The `Divider(color: rule, height: 28)` at `:75`, the
`Heading('Materials')`, `MaterialRows`, `Notice`, `Illustration`, `Spacer`, the
seven doors and the whole `LayoutBuilder`/`ConstrainedBox`/`IntrinsicHeight`
spine are unchanged.

### `character_screen.dart`

`_Stats` at `:118-156` — the six rows in the panel become four `LabelledValue`s
and two `ResourceMeter`s, in the same order:

```text
LabelledValue(label: 'Attack', value: '$attackMin-$attackMax')
LabelledValue(label: 'Armour', value: '$armour')
LabelledValue(label: 'Dodge',  value: '$dodge%')
LabelledValue(label: 'Speed',  value: '$speed')
ResourceMeter(key: characterHealthMeterKey, label: 'Health',
    value: hp, ceiling: maxHp, tint: MeterTint.health)
ResourceMeter(key: characterManaMeterKey, label: 'Mana',
    value: mana, ceiling: mana, tint: MeterTint.mana)
```

**The mana meter reads `value: mana, ceiling: mana` — a full bar — and that is
honest, not a fiction.** `mana` here is `heroMaxMana(profile.loadout)`
(`:37`), and entering a crawl refills mana to exactly that
(`core/lib/src/town/run_boundary.dart:95`), so in town current mana *is* max
mana. The rendered string changes from `Mana     8` to `Mana 8 / 8`, which
states one more true fact than before. Record that reason in the receipt; do
not invent a current-mana source and do not add a getter to `TownViewState`.

`_Stats`' `Container` with `color: panel` and `BorderRadius.circular(4)` at
`:140-143` is **unchanged** — the fenced panel is gap 6.5 and belongs to U15.

`:40-44` — the two rows below the panel become:

```text
LabelledValue(label: 'Spells known',   value: '${profile.knownSpells.length}')
LabelledValue(label: 'Skills trained', value: '$trained/${SkillId.values.length}')
```

Add `const characterHealthMeterKey = Key('character-health-meter');` and
`const characterManaMeterKey = Key('character-mana-meter');`.

`heroAttack`, `heroArmor`, `heroDodgePercent`, `heroSpeed`, `heroMaxMana`,
`trained`, the four route buttons, their keys, `_open`, `TownRoom` and every
`SizedBox` are unchanged.

### `Purse`

`town_style.dart:186-187` — the two rows become:

```text
LabelledValue(label: 'Carried', value: '$carried gold')
LabelledValue(label: 'Banked',  value: '$banked gold')
```

The `Divider(color: rule, height: 20)` at `:188` and the
`crossAxisAlignment: CrossAxisAlignment.start` stay.

`Purse` is consumed by the forge, tavern, merchant, bank **and inn**, so this
one change fixes five screens' columns without touching their files.

### `inn_screen.dart` — architect amendment A3

`:45-46` — the two rows become:

```text
ResourceMeter(key: innHealthMeterKey, label: 'Health',
    value: state.hp, ceiling: state.maxHp, tint: MeterTint.health)
LabelledValue(label: 'Price', value: '$innPrice gold')
```

Add `const innHealthMeterKey = Key('inn-health-meter');`. Health only — the inn
shows no mana and mana is crawl-only state.

`Purse`, `Notice`, `Heading('A bed for the night')`, the `Commit(label: 'Rest')`
with its `state.canRest && state.gold >= innPrice` guard, `RestPressed`,
`_why(state)` and every string are **unchanged**. Two lines, one key, nothing
else — this file is inside Boundaries only by A3 and only by those two lines.

## Executor discretion

Yours without asking:

- whether `LabelledValue`'s value cell is an `Expanded` or a `Flexible`, so
  long as a long value cannot push the label column;
- the exact wording of the `labelColumn` and `LabelledValue` dartdocs, so long
  as each keeps its reason;
- the three new key names, so long as each is stable and screen-scoped;
- how the rewritten assertions reach a `LabelledValue`'s label and value —
  by `find.descendant` under `find.byType(LabelledValue)`, by
  `find.widgetWithText`, or by key;
- whether the column-holds-still assertion is one loop or one expectation per
  row.

Not yours: `labelColumn`'s value without reporting the measurement, which
sites convert, health-only on the town and world screens, the mana meter's
`value == ceiling`, `_Stats`' panel `Container`, or any derived stat function.

## Red proof

Rewrite first, then implement. Both rewrites are genuine: they replace a pinned
padded string with the behaviour it defended.

### `town_shell_test.dart:179-196`

The test is "the status block states the figures and the notice", and its
comment says "the three figures, verbatim including their double spaces".
**The double spaces were a monospace alignment device and the comment goes with
them.** Rewrite to:

- under `townHealthMeterKey`, the rendered text carries the hero's `hp` and
  their `maxHp`, and the meter's `LinearProgressIndicator.value` equals
  `hp / maxHp`;
- a `LabelledValue` renders the label `Carried` with the value `12 gold`, and
  another renders `Banked` with `40 gold` — asserted as label and value
  separately, under the same row;
- `find.text('— the well runs cold.')` is **unchanged**.

Add, in the same file: **the label column holds still.** For the two
`LabelledValue` rows, `tester.getTopLeft(value).dx` is identical. That is what a
fixed-width slot means, and what a padded string never delivered in a
proportional face.

**Expected Red:** the meter and `LabelledValue` finders find nothing, and the
column assertion cannot run.

### `character_screen_test.dart:83-140`

Rewrite the six pinned strings at `:96-118` and the two at `:119-123`:

- `Attack`, `Armour`, `Dodge`, `Speed`, `Spells known`, `Skills trained` each
  render as a label with their computed value beside them, the values still
  derived from `heroAttack` / `heroArmor` / `heroDodgePercent` / `heroSpeed` /
  `knownSpells.length` / `SkillId.values.length` exactly as today, so the test
  still fails if the screen shows the wrong number;
- health becomes the meter assertion under `characterHealthMeterKey`: the
  rendered text carries `profile.hero.hp` and `profile.maxHp`, and the
  indicator's `value` equals `hp / maxHp`;
- mana becomes the meter assertion under `characterManaMeterKey`: the rendered
  text carries `heroMaxMana(profile.loadout)` twice, and the indicator's
  `value` equals `1.0`.

Everything else in that test — `find.byType(TabBar), findsNothing`, the four
route keys, and the six `findsNothing` assertions for `Rusty Sword`,
`Leather Jerkin`, `Firebolt`, `Ore`, `Wrath` and the notice — is **unchanged**.
Those are the test's real contract: the character screen shows facts and four
routes and nothing else.

Add: **the label column holds still** for the six `LabelledValue` rows, and
`tester.takeException()` is null at `onAPhone` (the panel gained no height it
cannot afford).

**Expected Red:** the eight string finders fail because the padding is gone, and
the meter finders find nothing.

### `town_illustration_test.dart:164-170`

Three more pins on the **town screen's** rows, found by grep and easy to miss
because the test is about the illustration: `find.text('Health   n / n')`,
`find.text('Carried  12 gold')`, `find.text('Banked   0 gold')`. Rewrite the
three exactly as `town_shell_test.dart`'s — the meter assertion for health,
label-and-value for the other two. `find.text('Stonebridge')`,
`find.byType(Notice)`, the door scroll loop and the `takeException` check at
`:177` are **unchanged**.

**Expected Red: the three string finders fail.**

### The inn's two rows

Grep shows no test pins `'Price    $innPrice gold'` or the inn's health line,
so A3's two rows need no test rewrite. **Verify that by grep rather than
trusting it**, and if `craft_rooms_test.dart` turns out to pin either, rewrite
it the same way and list it in the receipt. Add one assertion to the inn's own
coverage if none exists: under `innHealthMeterKey` the rendered text carries
`state.hp` and `state.maxHp`. Do not add a second test file for two lines.

### Run

```text
flutter test test/widget/town_shell_test.dart test/widget/character_screen_test.dart
```

### Must stay green

```text
flutter test test/widget/craft_rooms_test.dart test/widget/craft_surfaces_test.dart test/widget/bank_screen_test.dart test/widget/merchant_screen_test.dart test/widget/tavern_screen_test.dart test/widget/town_illustration_test.dart test/widget/roster_screen_test.dart test/style/material_palette_test.dart test/style/resource_meter_test.dart
```

`Purse` is consumed by five screens, so `craft_rooms_test.dart:498-507,669-680`
and `bank_screen_test.dart:179-186` read its rows' vertical order. **Those are
`getTopLeft(...).dy` ordering assertions, not string pins**, so they survive the
`LabelledValue` conversion — but any that reaches `find.byType(Purse)` or
`find.text('Carried  12 gold')` needs re-pointing. Check
`craft_rooms_test.dart:498` and `:669` (`find.byType(Purse)`) first: those are
type finders on `Purse` itself, which still exists, so they hold.

`tavern_screen_test.dart:123`'s reading-order list and
`town_illustration_test.dart:188-205`'s are also `dy` ordering and hold — it is
only `:164-170`'s three string pins in that file that change.

## Green proof and package gates

```text
flutter test test/widget/town_shell_test.dart test/widget/character_screen_test.dart
dart format --set-exit-if-changed --output=none lib test
flutter analyze
flutter test
```

Then, recorded in the receipt:

```text
grep -rn "'Health   \|'Carried  \|'Banked   \|'Attack   \|'Armour   \|'Dodge    \|'Speed    \|'Mana     \|'Price    \|Spells known    \|Skills trained  " lib
```

Expected: only `lib/world/world_screen.dart:196-198`, which is Task 06's.
Nothing else — after A3 there is no out-of-boundary exception left.

## Acceptance

- `labelColumn` declared once, with its reason;
- `LabelledValue` appended to `surfaces.dart` and nothing else added there;
- the town screen renders a health meter and two `LabelledValue`s; the
  character screen renders four `LabelledValue`s, two meters and two more
  `LabelledValue`s; `Purse` renders two;
- the value column's rendered `left` is identical within each screen, proved by
  test;
- the inn renders a health meter and one `LabelledValue`, and nothing else in
  that file changed (**A3**);
- all three test rewrites assert the behaviour the padded strings defended —
  the facts and their ceilings — and none is re-pinned to a new padded literal;
- `_Stats`' panel `Container`, every derived stat function, every key and every
  `findsNothing` assertion are unchanged;
- the nine-file must-stay-green list passes;
- all three package gates green.

## Escalate, do not decide

- any need to edit `inn_screen.dart` beyond `:45-46` — A3 widened the boundary
  by two lines, not by a file;
- any need to add a current-mana source to `TownViewState` or `packages/core`;
- any need to change `_Stats`' panel, add a hairline row, a medallion or a
  chevron — U15's gap 6.5;
- any need to move the town's numeric block out of the title region — U17's
  gap 1.5;
- a `Purse` consumer test whose rewrite would change what it defends;
- `labelColumn` at 96 being too narrow for a label — report the measured width
  rather than widening past 110, because a wider slot eats the value cell on a
  411 dp phone.

## Receipt

Report: the observed Red for both rewrites; every rewritten assertion with its
before and after, and one sentence per rewrite naming what it now defends
(this list feeds AC9); the mana-meter reasoning as rendered
(`Mana n / n`); the measured `left` of the value column on both screens; the
final grep; and the three package gates.
