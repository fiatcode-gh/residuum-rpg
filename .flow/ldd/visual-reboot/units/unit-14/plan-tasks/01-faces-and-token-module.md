# Task 01 — The Faces, the Token Module, and Proof the Faces Resolve in Both Hosts

Owner: one fresh `flow-plan-executor` on the Unit 14 feature checkout.

Read `../CONTRACT.md`, `../PLAN.md` (findings F1–F9 and the
"Cross-task interfaces" section especially), then
`packages/app/pubspec.yaml`, `packages/app/lib/main.dart`,
`packages/app/lib/game/crawl_style.dart`, `packages/app/lib/town/town_style.dart`,
`packages/app/test/support/phone.dart` and
`packages/app/test/widget/boot_failure_screen_test.dart` before editing.

All commands run from `packages/app`. There is no root pubspec.

## Starting condition

- a non-isolated Unit 14 feature checkout, **not `main`**;
- production source descends from `5ac1a49` on `residuum-visual-reboot-13`;
- the approved contract and plan are present and implementation has explicit
  user approval;
- no Unit 14 production change is present: `lib/style/` does not exist,
  `pubspec.yaml:76-93` is still the commented Flutter `fonts:` template,
  `packages/app/assets/` holds only `visual/`, and `test/flutter_test_config.dart`
  does not exist;
- the working tree is clean apart from user-owned `.flow/` content.

Inspect branch, HEAD and worktree before editing. Never discard, stash or reset
user work. If a named seam differs materially from the above, stop and report
rather than adapting.

## Behavioral slice

The application ships two authored typefaces, one module owns the value ladder,
the type roles, the spacing rhythm and the hairline, and **both faces provably
resolve in the widget-test host as well as on device** — which is the fact every
later task's measurement depends on. The boot failure screen is the first
consumer, and the first screen where no stock Material control renders in
Material 3's default palette.

This task migrates **no other screen**. `crawl_style.dart` and `town_style.dart`
are not edited here.

## Owned files

- new `packages/app/assets/fonts/Spectral-Regular.ttf`;
- new `packages/app/assets/fonts/Spectral-SemiBold.ttf`;
- new `packages/app/assets/fonts/EBGaramond-Variable.ttf`;
- new `packages/app/assets/fonts/OFL-Spectral.txt`;
- new `packages/app/assets/fonts/OFL-EBGaramond.txt`;
- `packages/app/pubspec.yaml` — the `fonts:` block only;
- new `packages/app/lib/style/tokens.dart`;
- `packages/app/lib/main.dart`;
- new `packages/app/test/flutter_test_config.dart`;
- new `packages/app/test/support/fonts.dart`;
- new `packages/app/test/style/type_authority_test.dart`.

Do not touch anything else. In particular: not `crawl_style.dart`, not
`town_style.dart`, not any screen under `lib/game/`, `lib/town/` or
`lib/world/`, not `.github/workflows/ci.yml`, not `packages/core`, not
`packages/content`.

## Locked decisions

### The font files

Fetch from the `google/fonts` repository, `main` branch. Verify each md5 before
committing; a mismatch is an escalation, not something to work around.

| upstream `raw.githubusercontent.com/google/fonts/main/…` | committed as | bytes | md5 |
|---|---|---:|---|
| `ofl/spectral/Spectral-Regular.ttf` | `assets/fonts/Spectral-Regular.ttf` | 261088 | `a183bbc39261b7279df4f8942e95e95c` |
| `ofl/spectral/Spectral-SemiBold.ttf` | `assets/fonts/Spectral-SemiBold.ttf` | 273068 | `7dd411a9cac1ebbd55618d0f0d2c5f4f` |
| `ofl/ebgaramond/EBGaramond%5Bwght%5D.ttf` | `assets/fonts/EBGaramond-Variable.ttf` | 851176 | `90a58d69f647565a751b7400d2493344` |
| `ofl/spectral/OFL.txt` | `assets/fonts/OFL-Spectral.txt` | 4392 | — |
| `ofl/ebgaramond/OFL.txt` | `assets/fonts/OFL-EBGaramond.txt` | 4398 | — |

The EB Garamond file is **renamed** on commit — upstream ships only a variable
font and its filename contains `[` and `]`. The bytes are unchanged.

Only these three font files. Do not fetch a Medium, a Bold, an Italic or a
second display file; the weight budget and its reason are in `../PLAN.md` and
adding a face is a contract change.

### `pubspec.yaml`

Replace the commented `fonts:` template (currently `:76-93`) with exactly:

```yaml
  fonts:
    - family: Spectral
      fonts:
        - asset: assets/fonts/Spectral-Regular.ttf
          weight: 400
        - asset: assets/fonts/Spectral-SemiBold.ttf
          weight: 600
    - family: EB Garamond
      fonts:
        - asset: assets/fonts/EBGaramond-Variable.ttf
          weight: 500
```

The `assets:` block at `:65-68` is untouched. The two
`OFL-*.txt` files are **not** listed under `assets:` — they are committed
licence text, not a runtime asset. Run `flutter pub get` afterwards and confirm
`git diff --exit-code -- pubspec.lock` is clean; CI gates on exactly that.

### `lib/style/tokens.dart`

A plain file of `const` values plus one `ThemeData`. **No widgets** — they come
in Task 03's `lib/style/surfaces.dart`. Not a `ThemeExtension`, not an
`InheritedWidget`, no change to `MaterialApp.theme`. No dartdoc on members
(`AGENTS.md`: dartdoc only on public API of `core` and `content`) except where a
decision needs its reason recorded, as `crawl_style.dart` already does.

Declare, in this order:

**Families** — the only two strings naming a family anywhere in `lib` when the
unit closes:

```dart
const String textFace = 'Spectral';
const String displayFace = 'EB Garamond';
```

**The value ladder** — exactly the twelve rows in `../PLAN.md`'s
"The value ladder" table. `ground`, `recessed`, `panel`, `raised`,
`disabledRule`, `armedFill`, `rule`, `dim`, `ink`, `scrim`. Copy the hex values
from that table verbatim; every one already exists in the tree and must not
change. **Do not declare `meterHealthFill` or `meterManaFill` here** — they are
Task 03's and a declared-but-unused member is not a valid handoff.

**The spacing rhythm and the hairline** — `gutter` 12, `rhythm` 4, `radius` 6,
`hairline` 1, `tapTarget` 44. **Do not declare `labelColumn`** — Task 05's.

**The eighteen type roles** — exactly the two tables in `../PLAN.md`
("Display roles" and "Text roles"), with every size, tracking, weight, colour
and height as given. Every role, without exception, carries:

- `inherit: false`;
- `fontFamily: displayFace` or `fontFamily: textFace`, explicitly;
- `height:` explicitly;
- `color:` explicitly;
- text roles: `fontFeatures: [FontFeature.tabularFigures()]`;
- display roles: `fontFeatures: [FontFeature.liningFigures(), FontFeature.tabularFigures()]`,
  plus `fontWeight: FontWeight.w500` and
  `fontVariations: [FontVariation('wght', 500)]`.

Carry one dartdoc on the display block recording why the three weight requests
coexist (EB Garamond ships only as a variable font; the request lands on 500
whichever mechanism the host honours) and one on the roles as a whole recording
why `height` is explicit (Spectral's own line box is 1.522 em; inheriting it
would add ~15% to every text row and breach the dp ceiling). Those two reasons
are load-bearing and an executor who deletes them removes the only warning
against "simplifying" a role.

**`residuumTheme`** — a top-level `final ThemeData`, so Dart initialises it once
on first access and no `build` allocates a `ThemeData`. Constructed from
scratch, **never** `Theme.of(context).copyWith(…)`. Set exactly the
`colorScheme` and the fifteen sub-themes in `../PLAN.md`'s
"`residuumTheme`" table, with the values given there.

The `colorScheme` is the load-bearing field: every sub-theme names a control
somebody enumerated, and the scheme is what catches the one nobody did. Record
in a dartdoc why `error: ink` is deliberate.

Do **not** set `appBarTheme.backgroundColor` or `appBarTheme.foregroundColor` —
the three `AppBar` call sites keep theirs, and
`crawl_surfaces_test.dart:297-300` reads the constructor argument.

Do **not** set `fontFamilyFallback` on any role or in the theme.

### `test/support/fonts.dart` and `test/flutter_test_config.dart`

`flutter test` always passes `--use-test-fonts` to `flutter_tester`
(`flutter_tools/lib/src/test/flutter_tester_device.dart:119`), so the test host
defaults every **unresolved** family to Ahem — every glyph a solid em square,
advance and line box exactly 1.000 em. Pubspec-declared fonts are **not**
registered there automatically. Without this registration the whole unit's dp
arithmetic is fiction.

```dart
// test/support/fonts.dart
Future<void> loadResiduumFonts() async {
  for (final (family, assets) in const [
    (textFace, ['assets/fonts/Spectral-Regular.ttf', 'assets/fonts/Spectral-SemiBold.ttf']),
    (displayFace, ['assets/fonts/EBGaramond-Variable.ttf']),
  ]) {
    final loader = FontLoader(family);
    for (final asset in assets) {
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  }
}
```

```dart
// test/flutter_test_config.dart
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await loadResiduumFonts();
  await testMain();
}
```

The family strings come from `tokens.dart`, never retyped, so they cannot drift
from `pubspec.yaml`. `flutter_test_config.dart` must sit at `test/`, not in a
subdirectory: the tool wraps every test file **under** the directory holding it.

### `lib/main.dart`

Five edits, and nothing else:

1. `:83` and `:171` — `scaffoldBackgroundColor: const Color(0xFF0E1014)` becomes
   `scaffoldBackgroundColor: ground`. **Both `MaterialApp.theme` arguments stay
   the bare `ThemeData(brightness: dark, scaffoldBackgroundColor: ground,
   useMaterial3: true)` they are today.** Do not pass `residuumTheme` to either
   `MaterialApp`; `MaterialApp.theme` restyling stock controls application-wide
   is prohibited and that prohibition is not negotiable.
2. `:112` — wrap `_screen()`'s `Scaffold` in
   `Theme(data: residuumTheme, child: Scaffold(…))`. This is `BootFailureScreen`'s
   screen-root opt-in, and it is why the boot screen does not need its
   `MaterialApp.theme` touched.
3. `:120-123` — the `'The crawl is unreachable.'` style becomes `textHeadline`.
4. `:127-136` — the `FilledButton` keeps `onPressed: _beginFresh` and its
   `styleFrom(padding: EdgeInsets.symmetric(vertical: 16))`, and its child
   becomes **`const Text('Begin fresh')` with no `style:` at all**. The label's
   metrics come from `filledButtonTheme.textStyle` and its colour from
   `foregroundColor`/`disabledForegroundColor`; a call-site `inherit: false`
   style would win outright and freeze a disabled label at full ink. This rule
   holds for every stock `FilledButton`, `TextButton` and `ChoiceChip` in the
   application.
5. `:144-145` — `monoLike` is deleted. `:125`'s `Text(_bootFailed, style: monoLike)`
   becomes `style: textLine`. The dartdoc at `:144` goes with it; the word
   "monospace" must not survive anywhere in `lib`.

`guardedBoot`, `_bootFailed`, `_beginFresh`, `_retrying`, the `FutureBuilder`,
`ResiduumApp`, `_Session` and every string are unchanged.

## Executor discretion

Yours without asking:

- the internal ordering and grouping of declarations inside `tokens.dart`, and
  whether the `ColorScheme` is a private `const` or inlined;
- how the fonts are fetched (`curl`, `git`, the browser) so long as the md5s
  match;
- the exact wording of the two required dartdocs, so long as each still
  records its reason;
- the shape of the `type_authority_test.dart` helpers, the sample strings used
  for the width inequality, and how the expected-absent mark set is expressed;
- whether `loadResiduumFonts` iterates a `const` list or is written out twice.

Not yours: any value in `../PLAN.md`'s tables, the family strings, the file
names, the `pubspec.yaml` shape, or which sites `main.dart` touches.

## Red proof

Write `test/style/type_authority_test.dart` **first**, before `tokens.dart` is
consumed anywhere. Four groups:

### 1. The faces resolve in the test host

```text
a TextPainter over 'iiiiiiiiii' in textLabel is strictly narrower than
one over 'MMMMMMMMMM' in textLabel
```

and the same for `displayTitle`. Under Ahem every glyph is the same em square,
so the two widths are **exactly equal**; in Spectral `i` is 0.313 em and `M` is
0.959 em, and in EB Garamond 0.245 em and 0.901 em. Dispose every painter.

**Expected Red: the two widths are equal.** This one inequality is the whole of
finding F4 reduced to a host-agnostic assertion, and it is what stops the suite
silently reverting to Ahem metrics if `flutter_test_config.dart` is ever lost or
moved.

### 2. Glyph coverage, per mark

Under `--use-test-fonts` the only fallback is the test font, whose advance is
exactly `fontSize`. So lay each mark out alone in `textFace` at
`fontSize: 100` and assert:

- `painter.width != 100.0` for every mark the application draws **except** the
  twelve below;
- `painter.width == 100.0` for exactly those twelve.

Covered, and each must measure ≠ 100.0:
`← → † ■ ▲ ▼ ◆ § ‡ · − ? < > › ↓ × — –` and `⁰ ¹ ² ³ ⁴ ⁵ ⁶ ⁷ ⁸ ⁹` and
`△ ◇` and the ASCII set `@ * < > . # 0123456789`.

Known absent from both faces, and each must measure == 100.0:
`◎` U+25CE, `⇅` U+21C5, `✕` U+2715, `✖` U+2716, `◉` U+25C9, `※` U+203B,
`★` U+2605, `▮` U+25AE, `✿` U+273F, `✳` U+2733, `✚` U+271A, `⛒` U+26D2.

Write the expected-absent set out as a literal set in the test, with a comment
naming where each is defined (see `../PLAN.md` F3's table) and noting that seven
of the twelve are `const` markings in `packages/core` which this unit may not
touch. A font swap that **loses** a covered mark then fails, and one that
**gains** `✳` also fails — and that second failure is welcome news, not a
defect.

Record the one caveat in the test: a covered glyph whose advance were exactly
1.000 em would read as absent. The widest glyph in Spectral is `W` at 0.981 em,
so none is.

**Expected Red: the file does not exist.** Written against the committed assets
it is green on first run. Its value is the day someone changes a font file.

### 3. Every exported role satisfies the invariants

Over a list of all eighteen roles: `inherit` is `false`, `fontFamily` is
`textFace` or `displayFace`, `height` is non-null, `color` is non-null, and
`fontFeatures` contains `tabularFigures` for text roles and both
`liningFigures` and `tabularFigures` for display roles.

A role added later without a family would fall back to Ahem in tests and to the
platform default on device, silently. This is the only thing that catches it.

### 4. The boot failure screen renders no Material 3 default

```text
final m3 = ThemeData(brightness: Brightness.dark, useMaterial3: true);
```

Build that reference **inside the test**, then pump `BootFailureScreen` and read
the rendered fill of `Begin fresh` from the `Material` the `FilledButton`
builds:

- the fill equals `raised`;
- the fill is **not** `m3.colorScheme.primary`.

Computing the reference live means no lavender hex is ever written down and a
framework palette change cannot make the test lie.

**Two assertions, not three — architect amendment A6, 2026-09-18.** An earlier
version of this brief asked for a third: that the fill's luminance differ from
`ground`'s by a ratio ≥ 1.5 : 1. **It is struck.** This task's own execution
found it unsatisfiable under the WCAG reading (`raised` `#1B1F27` on `ground`
`#0E1014` is 1.153 : 1, because the `+0.05` flare dominates at these
luminances) and cleared 1.5 only by switching to a plain `Lmax/Lmin` reading
(2.643 : 1). That switch works on this one screen and fails everywhere else —
a `raised` control on `panel` is 1.491 : 1 plain — so Task 04 would have
inherited a threshold whose only remedy is lowering itself.

**Do not add a fill-versus-surface contrast assertion, and do not restore the
one that was here.** This value ladder is deliberately low-contrast; a
control's boundary comes from its 1 dp `rule` border. The two assertions above
are host-independent, cannot be satisfied by accident and cannot be satisfied
by tuning a number, and they carry all of AC4's content. See `../PLAN.md`
§"Why there is no third, fill-versus-surface contrast assertion (A6)" for the
full arithmetic.

**Expected Red: the fill equals `m3.colorScheme.primary`.**

### Run

```text
flutter test test/style/type_authority_test.dart
```

### Must stay green

```text
flutter test test/widget/boot_failure_screen_test.dart
```

It asserts only strings, so it passes before and after and is the regression
proving the three style folds and the theme wrap changed no reading.

## Green proof and package gates

Implement only this slice, rerun the focused commands until green, then from
`packages/app`:

```text
flutter pub get
git diff --exit-code -- pubspec.lock
dart format --set-exit-if-changed --output=none lib test
flutter analyze
flutter test
```

**The full suite is this task's real risk, and it is expected to move.** The
moment the `FontLoader` lands, every `RenderParagraph` in every widget test is
measured in Spectral instead of Ahem — narrower in mixed case, 12% wider in
caps, and with a line box governed by the font until each style moves onto a
token. Two consequences to expect and handle correctly:

- **a `takeException(), isNull` failure is a real overflow, not a test problem.**
  Sixteen such tripwires exist across the suite. If one fires, the row it
  guards genuinely overflows at phone width under the new metrics. It may not
  be fixable in this task, because the screen it guards has not moved onto the
  tokens yet;
- **a geometry or wrap-count failure in an unmigrated screen is expected.**

If a suite failure is confined to a screen a later task owns, and the failure is
a metric shift rather than a broken behaviour, **record it in the receipt with
the file, the test name and the observed figure, and hand it to the owning
task** — do not migrate that screen here and do not loosen its assertion. If a
suite failure lands in a screen no later task owns, stop and report.

## Acceptance

- three font files and two `OFL.txt` committed under `assets/fonts/`, each md5
  matching the table above;
- `pubspec.yaml` declares both families with exactly the three assets and the
  weights 400 / 600 / 500; `pubspec.lock` unchanged;
- `lib/style/tokens.dart` exports the two families, the ten ladder colours, the
  five rhythm values, the eighteen roles and `residuumTheme`, and declares
  **nothing** that this task does not consume — no `meterHealthFill`, no
  `meterManaFill`, no `labelColumn`;
- `test/flutter_test_config.dart` and `test/support/fonts.dart` register both
  families from `tokens.dart`'s own family constants;
- `test/style/type_authority_test.dart` green, with the observed Red for groups
  1 and 4 recorded verbatim in the receipt;
- `main.dart` contains no `Color(0x` literal, no `fontFamily`, no `monoLike` and
  no occurrence of the word "monospace"; both `MaterialApp.theme` arguments are
  still bare;
- `boot_failure_screen_test.dart` green;
- all three package gates green, with any unmigrated-screen metric shift listed
  in the receipt by file, test name and figure.

## Escalate, do not decide

- an md5 mismatch on a fetched font file;
- `google/fonts` no longer shipping one of the named files;
- a suite failure in a screen no later Unit 14 task owns;
- needing a third font face, a Medium weight, an italic, or `fontFamilyFallback`;
- `FontLoader` failing to register a family, or group 1 still failing after
  registration — that would mean `--use-test-fonts` overrides registered
  families too, which would invalidate finding F4 and the whole dp gate;
- needing to change a role's size, weight, tracking or family from
  `../PLAN.md`'s tables.

## Receipt

Report: the md5 of each committed font file; the observed Red for groups 1 and
4; the twelve absent marks confirmed and any thirteenth discovered; whether
`pubspec.lock` moved; the full-suite result with every unmigrated-screen metric
shift named by file, test and figure; and the three package gates.
