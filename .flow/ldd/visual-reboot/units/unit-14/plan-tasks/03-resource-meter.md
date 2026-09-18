# Task 03 — One Resource Meter, and the Crawl Status Adopting It

Owner: one fresh `flow-plan-executor` on the Unit 14 feature checkout.

Read `../CONTRACT.md` (the "meter pair" section and AC6), `../PLAN.md`
("`lib/style/surfaces.dart` — the shared widgets" especially), then
`packages/app/lib/game/crawl_status.dart`,
`packages/app/lib/style/tokens.dart`,
`packages/app/lib/town/skills_screen.dart` and
`packages/app/test/widget/crawl_status_test.dart` before editing. Look at
frames 2, 3 and 6 of
`.flow/evidence/visual-reboot/residuum_visual_reboot_approved_mock.png`.

All commands run from `packages/app`.

## Starting condition

- Tasks 01 and 02 are accepted: `lib/style/tokens.dart` exports the ladder, the
  rhythm and the seventeen roles but **no meter hue and no `labelColumn`**;
  `lib/style/surfaces.dart` does not exist; `crawl_style.dart` is aliases only;
  the three crawl chrome caps are re-derived;
- `crawl_status.dart:118-170` still holds the private `_Meter`, and `:8-10`
  still exports `hpMeterKey`, `manaMeterKey` and `depthPairKey`;
- `crawl_status.dart` is the **only** real meter in the application.

Inspect branch, HEAD and worktree before editing. If a named seam differs
materially, stop and report.

## Behavioral slice

One meter component exists, shared, carrying a label, a monochrome-safe track,
a hue fill and the number — and the crawl status renders through it. The hue is
reinforcement: the label word, the value, the ceiling and the fill fraction each
carry the meaning on their own, so a greyscale render loses nothing, and the two
hues are indistinguishable from each other in greyscale so neither meter reads
as fuller than the other at equal fraction.

The character screen and the town screen adopt the same component in **Task
05**, not here. This task's proof is the component and the crawl.

## Owned files

- new `packages/app/lib/style/surfaces.dart`;
- `packages/app/lib/style/tokens.dart` — the two meter hues only;
- `packages/app/lib/game/crawl_status.dart`;
- new `packages/app/test/style/resource_meter_test.dart`;
- `packages/app/test/widget/crawl_status_test.dart`.

Do not touch `skills_screen.dart`, `character_screen.dart`, `town_screen.dart`,
`inn_screen.dart`, `world_screen.dart`, `crawl_style.dart`, `game_screen.dart`,
any renderer file, `packages/core` or `packages/content`.

## Locked decisions

### The two hues

Append to `tokens.dart`, beside the value ladder:

```dart
const Color meterHealthFill = Color(0xFFD99A3D);
const Color meterManaFill = Color(0xFF7FA8D9);
```

Warm amber for health, cold blue for mana. Relative luminance 0.3820 and
0.3753 — `|ΔL| = 0.0067`, so in greyscale the two fills are indistinguishable
from each other, and each sits 5.5 : 1 above the `rule` track. **That symmetry
is the point**: a red-and-blue pair at different luminance would make one meter
look fuller than the other in a greyscale capture at the same fraction.

Warm amber rather than the mock's red is deliberate and must not be "corrected"
toward the mock: `VISUAL-SYSTEM.md` §2 reserves hot red for mortal danger and
the armed target reticle, and permits warm amber for light, fire and gold.
Record that reason in a dartdoc on the two constants. No red-versus-green pair
exists anywhere in the result, and none may be introduced.

These are the epic's **first permitted hue**. Nothing else in this unit gains
one.

### `lib/style/surfaces.dart` — `ResourceMeter` only

The file carries widgets and no values, mirroring `crawl_surfaces.dart`'s
relationship to `crawl_style.dart`. Declare **only** `MeterTint` and
`ResourceMeter`; Task 05 appends `LabelledValue`.

```dart
enum MeterTint { health, mana }

class ResourceMeter extends StatelessWidget {
  const ResourceMeter({
    required this.label,
    required this.value,
    required this.ceiling,
    required this.tint,
    this.note = '',
    super.key,
  });

  final String label;
  final int value;
  final int ceiling;
  final MeterTint tint;
  final String note;
}
```

**The geometry is `crawl_status.dart:118-170`'s `_Meter`, moved verbatim.**
Nothing about it is redesigned — the crawl's geometry is already measured,
already covered by `crawl_status_test.dart`, and control geometry is U15's:

```text
Row(
  Expanded(flex: 8, FittedBox(scaleDown, centerLeft,
      Text('$label $value / $ceiling', style: textBody))),
  SizedBox(width: 6),
  Expanded(flex: 6, ClipRRect(BorderRadius.circular(2),
      LinearProgressIndicator(value: fill, minHeight: 8,
        backgroundColor: rule,
        valueColor: AlwaysStoppedAnimation(fill_colour)))),
  SizedBox(width: 6),
  Expanded(flex: 6, FittedBox(scaleDown, centerRight,
      Text(note, style: textBody))),
)
```

- `fill = ceiling == 0 ? 0.0 : (value / ceiling).clamp(0, 1).toDouble()` —
  copied exactly from `:134`, including the `ceiling == 0` guard and the clamp;
- `fill_colour = switch (tint) { MeterTint.health => meterHealthFill,
  MeterTint.mana => meterManaFill }`;
- the `LinearProgressIndicator` keeps its **explicit** `backgroundColor` and
  `valueColor`. `residuumTheme.progressIndicatorTheme` is a floor, not a
  replacement, and `crawl_status_test.dart` reads `indicator.value`;
- the label-and-number string composes as `'$label $value / $ceiling'`. The
  crawl passes `'HP'` and `'Mana'`; Task 05's town consumers pass `'Health'`
  and `'Mana'`. The component never knows which screen it is on;
- `note` defaults to `''` and renders an empty `Text`, exactly as `_Meter` does
  today, so the flex-6 cell holds its width whether or not there is a note.

No dartdoc on the fields (`AGENTS.md`: dartdoc only on public API of `core` and
`content`), but **do** carry one on the class recording why the hue is
reinforcement and what a greyscale render must still show, because that is the
accessibility contract and a later unit will read it.

### `crawl_status.dart`

- delete the private `_Meter` class at `:118-170` and import
  `../style/surfaces.dart`;
- `_ResourceRow` at `:79-116` builds `ResourceMeter(key: hpMeterKey,
  label: 'HP', value: shown, ceiling: ceiling, tint: MeterTint.health,
  note: _condition(fraction))` and, under the same
  `if (state.game.knownSpells.isNotEmpty)` guard and the same
  `SizedBox(width: 12)`, `ResourceMeter(key: manaMeterKey, label: 'Mana',
  value: state.mana, ceiling: state.maxMana, tint: MeterTint.mana,
  note: state.warded > 0 ? 'Ward ${state.warded}' : '')`;
- `hpMeterKey`, `manaMeterKey`, `depthPairKey`, `_HeaderRow`, `_BattleGlyph`,
  `_placeName`, `_battleWord`, `_condition`, the `Divider`, the padding, the
  18 dp glyph cell, the 64 dp depth cell, every `FittedBox` and every string are
  **unchanged**;
- the `hero.hp.clamp(0, ceiling)` at `:89` and the `fraction` at `:88` stay in
  `_ResourceRow` — the component takes the already-clamped value, exactly as
  `_Meter` does today.

**The mana meter's visibility rule does not change.** Mana appears only when
`knownSpells.isNotEmpty`. The audit's gap 2.8 notes the mock shows both meters
always; that half of the gap is assigned to **U21**, not here, and adding an
always-present mana meter would be new information on the crawl status row.

### What does not get a hue

`skills_screen.dart:49-53`'s `LinearProgressIndicator` is a skill XP bar, not a
resource meter. It keeps `ink` on `rule` and is not edited. Hue is reserved for
the two resources; tinting a third meaning would spend the epic's first
permitted hue on something the contract did not authorise.

## Executor discretion

Yours without asking:

- whether `MeterTint` resolves to a colour through a `switch` expression, a
  getter on the enum, or a private map;
- how `_ResourceRow` names its locals;
- the exact wording of the `ResourceMeter` and hue dartdocs, so long as the
  reinforcement rule and the reserved-red reason survive;
- the shape of `resource_meter_test.dart`'s pump helper and its contrast
  helper;
- whether the four boundary cases are four `testWidgets` or one with four
  `pump`s.

Not yours: the geometry — the 8/6/6 flexes, the 8 dp track, the 2 dp radius,
the two 6 dp gaps, the `FittedBox`es — the two hue values, the composed
`'$label $value / $ceiling'` string, the `ceiling == 0` guard, the clamp, the
mana visibility rule, or the explicit `backgroundColor`/`valueColor` on the
indicator.

## Red proof

Write `test/style/resource_meter_test.dart` **first**. Four groups.

### 1. The greyscale reading loses nothing — as arithmetic

```text
|meterHealthFill.computeLuminance() - meterManaFill.computeLuminance()| < 0.02
contrast(meterHealthFill, rule) >= 4.5
contrast(meterManaFill,   rule) >= 4.5
```

with `contrast(a, b) = (max(La, Lb) + 0.05) / (min(La, Lb) + 0.05)` — the
**WCAG** reading, named explicitly because this plan now carries exactly one
surviving contrast threshold and it must not be confused with the one
architect amendment A6 struck. This is the accessibility contract stated as
numbers a later unit cannot accidentally violate: the two fills are
indistinguishable from each other in greyscale, and both are clearly
distinguishable from their own track.

**Both thresholds have real headroom — verify, do not tune.** Measured:
`|ΔL| = 0.0067` against a 0.02 ceiling, and 5.587 : 1 and 5.500 : 1 against a
4.5 : 1 floor. If either misses, a hue value was mistyped; **fix the value, not
the threshold.**

**Why A6 does not reach this group.** A6 struck AC4's fill-versus-surface ratio
because the value ladder's adjacent steps cannot clear any useful threshold
(`raised` on `panel` is 1.076 : 1 WCAG). This is a different claim: a bright
accent (`L` 0.382 and 0.375) against a dark track (`L` 0.027), which clears
4.5 : 1 by 24%. And the `|ΔL|` assertion is a *sameness* claim, not a contrast
claim at all — neither meter may read as fuller than the other at equal
fraction. Both stand.

**Expected Red: the constants do not exist** — the test does not compile.

### 2. Hue is reinforcement, not the carrier

Pump a `ResourceMeter(label: 'HP', value: 14, ceiling: 20, tint: health,
note: 'Steady')` and assert:

- the rendered text contains the label word, the value and the ceiling;
- the rendered note renders;
- the `LinearProgressIndicator`'s `value` equals `14 / 20`.

Every one of those assertions still holds with the fill colour removed, which is
precisely what AC6 asks for. Add the same three for `tint: mana`.

**Expected Red: `ResourceMeter` does not exist.**

### 3. The two meters differ by more than their hue

In one pumped tree holding both, assert the two meters render different label
words and different numbers — asserting the **words and numbers**, so the test
would still pass with both fills identical. That is the test admitting, in its
own structure, that hue is not what it reads.

### 4. Boundaries

- `ceiling: 0` renders a zero-fill bar and throws nothing — the live guard at
  `crawl_status.dart:134`;
- `value: 25, ceiling: 20` clamps the fill to `1.0` and still prints `25`, so
  the number stays true when the bar saturates;
- `note: ''` renders the cell and changes no other cell's width — compare the
  track's rendered rect with and without a note.

### Run

```text
flutter test test/style/resource_meter_test.dart
```

### Must stay green

```text
flutter test test/widget/crawl_status_test.dart test/widget/crawl_layout_test.dart test/widget/crawl_action_row_test.dart test/battle_view_test.dart
```

`crawl_status_test.dart` is the whole regression for the crawl half: it reads
`hpMeterKey`, `manaMeterKey`, `indicator.value`, every status string, the
condition words and the worst-case no-squeeze loop. **If it needs an edit, the
only permitted edit is re-pointing an assertion from the deleted `_Meter` to
`ResourceMeter` by the same unchanged key.** A string, a key, a progress value
or the no-squeeze loop changing is a defect, not a test update.

`crawl_action_row_test.dart` must stay within its Task 02 caps: the meter's
geometry is unchanged, so the status row's height must not move. If it does, the
geometry was not moved verbatim.

## Green proof and package gates

```text
flutter test test/style/resource_meter_test.dart test/widget/crawl_status_test.dart
dart format --set-exit-if-changed --output=none lib test
flutter analyze
flutter test
```

## Acceptance

- `lib/style/surfaces.dart` exists and declares exactly `MeterTint` and
  `ResourceMeter` — nothing else;
- `tokens.dart` gains exactly two constants, with the reserved-red reason
  recorded;
- `crawl_status.dart` holds no private `_Meter`, and every key, string,
  condition word, guard, flex, `FittedBox` and cell width is unchanged;
- `resource_meter_test.dart` green, with the observed Red for groups 1 and 2
  recorded in the receipt;
- `crawl_status_test.dart` green with at most key-re-pointing edits, each listed
  in the receipt;
- the crawl's three chrome figures unchanged from Task 02's, recorded to prove
  the geometry moved verbatim;
- all three package gates green.

## Escalate, do not decide

- any need to change the meter's geometry — the flexes, the 8 dp track, the
  2 dp radius, the `FittedBox`es or the two 6 dp gaps. That is U15's;
- any need to make mana always visible on the crawl status row — U21's, per
  gap 2.8;
- any need for a third hue, for a red or green fill, or for a hue anywhere
  outside these two meters;
- a `crawl_status_test.dart` assertion that cannot be re-pointed by key and
  would need its defended behaviour changed;
- the crawl's chrome moving at any density, which would mean the geometry did
  not move verbatim.

## Receipt

Report: the two hue values with their measured luminances and track contrast
ratios; the observed Red for groups 1 and 2; every `crawl_status_test.dart` edit
with the assertion before and after; the crawl's three chrome figures against
Task 02's; and the three package gates.
