# Resume Visual Reboot

**Units 1–12 are merged to `main`, Unit 12.5's device gate is closed, Unit 13
is complete and accepted, and Unit 13.1 — the map bleed — is fixed and closed.
U14's contract and plan are approved. **Tasks 01 through 05 of 08 are
implemented, verified and committed.** The user paused here deliberately,
intending to resume in the same session.**

## Exact state

- `main` is `907a4a83e7c592d4f6dd0c55e6f30c3b1b8bc49b`, the PR #22 merge
  (2026-09-18T08:49:20Z). The earlier record that PR #22 was open and
  unmerged is superseded.
- Branch **`residuum-visual-reboot-13`** off `907a4a8`, working tree clean,
  nothing pushed, no pull request. Eleven commits: `9c2d66e` Unit 13's
  records, `e8bcf29` Unit 13.1's fix, `03e8c0c` its record, `5ac1a49` U14's
  contract approval, `14a7bed` U14's plan, `b8d934b` Task 01, `a09efc2`
  amendment A6, `8e1efbd` Task 02, `7ade1c9` amendments A7 and the task
  records, `d959f23` amendment A8's leaf, `b8fe4f1` A8's plan edit, `0f1882d`
  Task 03, `7090866` Task 04, `de89acc` its record, `67513bb` Task 05.
- **Architect-run gates at the pause point**, on the committed tree:
  `dart format` 128 files / 0 changed, `flutter analyze` no issues, full
  `flutter test` **1109 passing**.
- **Crawl chrome is 331 / 429 / 578 dp** and has not moved through five
  tasks. Caps are 360 / 450 / 600, the last being the contract's own ceiling.
- Unit 13's canonical records are in `units/unit-13/`: `CONTRACT.md`,
  `recon.md`, `PARITY-AUDIT.md`, `PARITY-MATRIX.md`, `VISUAL-SYSTEM.md`,
  `ROADMAP.md`. The external ChatGPT bundle it came from sits beside them and
  validated clean (`sha256sum -c`, `validate-planning-handoff.py`).
- Evidence: `.flow/evidence/visual-reboot/unit-13-parity/` — ten isolated mock
  frames, ten side-by-side pairs, ten greyscale pairs.
- Two stale records were corrected: Unit 12's contract status (it said
  "drafted, awaiting explicit user approval") and Unit 12.5's checkpoint tail
  (a mid-pass forward pointer for a closed unit).

## Exact next action — paused by the user, resume here

**Dispatch one fresh `flow-plan-executor` on
`units/unit-14/plan-tasks/06-world-seam-and-route-diagram.md`.** Hand it the
artifact path, not pasted content. Then 07, then 08, one fresh executor each,
one writer at a time, non-isolated on this checkout. No architect decision is
open.

**Task 08 goes to `sonic`, not to a plan executor.** A7 deleted the only
keep-list trap that justified the heavier agent, and the brief says so.

**Hand Task 06 this, because its brief does not list it.** `world_screen.dart`
still renders the padded `Carried  ${gold} gold` at `:197`, and four test
files pin that exact string: `roster_refusal_test.dart`,
`roster_session_test.dart`, `suspend_door_test.dart` and
`world_screen_test.dart`. Task 05 converted the town's six padded columns and
left these because the world screen is Task 06's. They will break the moment
the conversion lands, and each must be rewritten to the behaviour it defends,
never re-pinned to a new string.

After 08: **Gate A** (dp re-confirmation on the final tree), **Gate B**
(integrated gates, diff audit, acceptance review), **Gate C** (the
`Medium_Phone` pass, thirteen capsules). Main owns all three.

Three duties U14 inherits and must not lose:

- **Capsule J is the ceiling-density crawl**, carrying U13.1's hardware
  confirmation. If the `BattleDock` is covered there, U13.1 reopens.
- **Capsules F and G are the world map's and the roster's first visual
  baselines** in this epic.
- **The dp budget is re-measured** at three densities. Worst legal combat over
  600 dp on device is a stop-and-escalate, not an executor's call and not a
  tuning target — every remedy belongs to U15 or a contract amendment.

Nothing remote is authorized. Push and pull request are each their own gate.

## What tasks 01–05 landed

| task | commit | what |
|---|---|---|
| 01 | `b8d934b` | Spectral and EB Garamond bundled with their licences; `lib/style/tokens.dart`; the test-host `FontLoader` without which every measurement is Ahem; boot screen migrated |
| 02 | `8e1efbd` | `crawl_style.dart` to aliases, `crawlTheme` deleted, three theme sites, chrome re-measured and the caps re-derived |
| A8 | `d959f23` | `textDetailDim` and `textMicroDim`; the `copyWith` rule struck outright |
| 03 | `0f1882d` | `ResourceMeter` and the epic's first hue, geometry moved verbatim |
| 04 | `7090866` | the town, pack and roster dialogs under `residuumTheme`; ten control families proved off the M3 palette; A9's `textBaseline` on all twenty roles |
| 05 | `67513bb` | `labelColumn` and `LabelledValue`; six padded columns converted including the Inn's two; town, character and inn meters |

## Four amendments ruled during execution, all the same class

Every one was a claim about what compiles, what a formula yields, or what the
framework does — the class a plan cannot settle by reasoning. None was
catchable by reading the plan. They are indexed in `PLAN.md` §"Architect
amendments A1–A9".

- **A6** — AC4's fill-versus-surface contrast of 1.5:1 is unsatisfiable
  against this ladder: `raised` on `panel` is 1.076:1 WCAG and 1.491:1 plain.
  Struck, not retuned. **Standing rule:** every luminance claim here must be a
  strict ordering or an accent-against-ladder contrast, and must say which
  reading it uses.
- **A7** — `crawlChevron` as a `final copyWith` does not compile; all four
  consumers sit in `const` contexts and the plan named three. Became a `const`
  alias of `textGlyphDim`.
- **A8** — the `copyWith` rule itself was the defect, with three more mandates
  waiting in Task 06. Struck outright; `textDetail` and `textMicro` flipped to
  ink primaries with `Dim` siblings. **Twenty roles.**
- **A9** — an `inherit: false` style with a null `textBaseline` crashes any
  `TextField` under the theme: `TextStyle.merge` returns a non-inheriting
  style verbatim (`text_style.dart:1079`) and `InputDecorator` reads
  `labelStyle.textBaseline!` (`input_decorator.dart:2327`). All twenty roles
  carry `TextBaseline.alphabetic`; the invariant sweep has a sixth check.

**The remaining claim of that class is already tested.** Brief 06's estimate
that `TRAVEL IN PROGRESS` measures ≈108 dp at 9 px against a 120 dp box is
checked by that task's own no-clipped-label proof. Task 05's `labelColumn =
96` was the other, and it held: measured widest label 76.34 dp.

## Suite count, read honestly

907 before Task 01, **1109** now. The growth is overwhelmingly
parameterisation — twenty roles times six invariants, plus the per-mark glyph
sweep and the ten-row palette table. Task 01 added four behavioural groups,
Task 03 nine cases, Task 04 twelve. Do not read 1109 as coverage growth and do
not try to keep the number up.

## U14's plan, in the ten facts a resume needs

Full text: `units/unit-14/PLAN.md` (1756 lines) plus eight briefs in
`plan-tasks/` (4440 lines total). Do not re-read it to resume; read the brief
for the task you are dispatching.

1. **Graph:** 01 faces and token module → 02 crawl seam and dp re-measurement
   → 03 resource meter → 04 town theme and the lavender → 05 numeric
   alignment and town meters → 06 world seam and route diagram → 07 map glyph
   sweep and guard → 08 the rename leaf → Gate A → Gate B → Gate C. **Nothing
   is parallelisable**; 02–08 all consume Task 01's `tokens.dart`, and Task 01
   changes the measured metrics of every widget test at once.
2. **`flutter test` passes `--use-test-fonts` AND `--disable-asset-fonts`**
   (`flutter_tools/lib/src/test/flutter_tester_device.dart:119-120`, verified
   at source). Ahem is 1.000 em in both advance and line box — that is the
   whole of U13.1's dp divergence. **Bundling the faces does not close it:**
   Task 01 ships `test/flutter_test_config.dart` plus a `FontLoader`, and that
   is not optional.
3. **Spectral's line box is 1.5220 em.** Inherited, that is +15% per text row
   and ~668 dp of worst-legal chrome against a 600 dp ceiling. **Every one of
   the seventeen roles carries an explicit `height`** — that single decision
   holds the budget.
4. **Fonts:** `Spectral-Regular.ttf`, `Spectral-SemiBold.ttf`,
   `EBGaramond-Variable.ttf` from `google/fonts` with both `OFL.txt`, 1.39 MB.
   Spectral 400 + 600; EB Garamond one variable instance at wght 500,
   requested three ways, degrading to 400.
5. **Tabular figures verified in the binaries.** Spectral's digits are
   already uniform-width and lining; EB Garamond carries `tnum` but defaults
   to oldstyle, so display roles also carry `liningFigures()`.
6. **One `residuumTheme` at six roots** — not three siblings; three would
   differ in no field. `MaterialApp.theme` restyles nothing; every root opts
   in. Reversal cost is two lines.
7. **Ten unthemed stock control families, not four.** AC4's test reads the
   *rendered* fill from the `Material` each control builds and asserts it is
   not the corresponding colour of a `ThemeData(brightness: dark,
   useMaterial3: true)` built live inside the test, so no lavender hex is ever
   written down.
8. **Meter hues:** health `#D99A3D` warm amber — deliberately not the mock's
   red, which section 2 reserves for mortal danger and the armed reticle —
   and mana `#7FA8D9`. The two sit 0.0067 apart in lightness so neither reads
   as fuller in greyscale.
9. **Aliases are transitional.** Tasks 02 and 04 alias the seams to keep the
   cutover compiling; **Task 08 deletes the 34 that only re-name a token** and
   keeps the seam vocabulary that says something of its own — the chip state
   ladder, `crawlChevron` (which looks like an alias and is not: it is a
   hoisted `copyWith` so no build allocates), the 14 crawl metrics,
   `markColumn`. Task 08 closes AC3, not Task 07. It is **rename-then-delete,
   not an `lsp` rename** — the target name already exists — and the language
   server repoints identifiers but not imports, so `flutter analyze` is the
   worklist and analyze-clean is the completion signal.
10. **Twelve marks are uncovered by both faces** — seven of them const
    markings in `packages/core`, which stays untouched. They already render
    from platform fallback today, so nothing regresses; U16 retires them.
    `✳ ✚ ⛒` sit inside crawl chip labels that `_fitFor` measures, so their
    host-dependent advance is the one real threat to the widget-test versus
    device agreement claim.

## Unit 13.1, closed 2026-09-18

Root cause: Flame's default `MaxViewport.clip()` is an explicit no-op
(`flame-1.38.2/.../max_viewport.dart:26`) and `GameRenderBox` never clips on
its behalf, so the viewport's reported size only ever positioned the camera
while the world's whole `visible ∪ explored` tile set painted straight
through onto the chrome above. Fixed by `_ClippedMaxViewport`
(`dungeon_scene.dart:187-213`), which adds the clip `MaxViewport` omits and
inherits its size tracking. The contract's `ClipRect` trap turned out moot —
the camera window already equalled its box — but it is what forced the
diagnosis that proved it moot.

Proved red at `9c2d66e` in a throwaway worktree and green on the fixed tree;
architect gate `dart format` 121/0, `flutter analyze` clean, full suite
**907 passing**. Visible row count unchanged; 7.93 rows of sight stands.

**Carry this measurement trap:** `flutter_test`'s font fallback wraps the same
11 chips into 4 runs where the device fits 3, giving 208.43 dp / 5.79 rows
against the device's 285.33 dp / 7.93. Widget-test dp figures are not device
dp figures. Never copy one into the ledger as the other.

## Settled by the user, 2026-09-18

1. **Fonts: Spectral for text, EB Garamond for display.** Every density
   failure in the audit is at 12–13 px, which is where a decorative face
   breaks.
2. **The shared style seam is approved** — one token module plus sibling
   per-screen themes, the shape `crawlTheme` already has. "Never an
   application-wide design system" is superseded **to exactly that extent**;
   a `MaterialApp`-wide restyle of stock Material controls stays prohibited.
3. **Frame 4's three intermediate cells are a mock flourish.** No range or
   path feedback will be built; the map marks the legal targets, as today.
4. **The world map and the roster inherit the vocabulary and gain an evidence
   gate.** No frame commissioned; U14 owes the first device shot of each in
   colour and greyscale, and U15 and U17 re-shoot them when their changes
   land.
5. **Roadmap approved as ordered**, U13.1 first.

## The recut roadmap, in one table

| Unit | Frames | Ownership | Depends on |
|---|---|---|---|
| U14 Type, palette and surface authority | all ten | CODE + ASSET | nothing outstanding |
| U15 Row, control and chip grammar | 1–4, 6–10 | CODE | U14 |
| U16 Authored icon and art families | 1, 5–10 | ASSET + thin CODE | U15's empty medallion slot |
| U17 Illustration headers and hero portrait | 1, 6, 9, 10 | CODE + ASSET | U14 |
| U18 Dungeon light and stone value | 2, 3, 4 | CODE | nothing |
| U19 Dungeon structure and props | 2, 3 | CODE + ASSET | U18 |
| U20 Actor representation | 2, 3, 4 | CODE + ASSET | U18 |
| U21 Combat chrome density | 2–5 | CODE | U14, U15 |
| U13.1 map bleed (defect) | 2, 3 | CODE | **done** — `e8bcf29` |

## Carried debt

- **The map-bleed defect is fixed** (U13.1, `e8bcf29`) and carries exactly one
  open obligation: hardware confirmation at U14's device gate. Until that
  pass, the fix is proved headlessly and on no real screen.
- **Save-read defect candidate, unproven and out of the epic.** The app
  reported *"your last save could not be read; an older one was restored"*
  for a post-death autosave whose bytes were readable — the codec refused the
  document. Reproduce directly: stage a hero at 1 HP, die, feed the resulting
  `save.json` to `decodeSave`. If real, a player who dies loses a slot. Needs
  its own contract; it blocks no visual unit and must not be diagnosed inside
  one.
- **O3, a follow-up, not a defect.** Chips are keyed by their composed label,
  so a mana rebalance in `packages/content` would break `packages/app` widget
  tests for a presentational reason. U15 touches the same chips and may retire
  the label-keyed handles in passing. No collision is reachable today.
- **The world map and the roster have no visual baseline** anywhere in the
  epic. Open question 4.

## Carry-forward locks

Unit 13 settled the visual system; `units/unit-13/VISUAL-SYSTEM.md` is now
the authority for appearance, and these are the ones a future session will
trip over if it does not know them.

- **Superseded by Unit 13:** monospace-only identity; colour avoidance;
  Material-derived geometry and stock controls; "compositions are near-fixed";
  "authored assets are a late optional possibility"; Unit 12.5 AC17's
  conclusion about dungeon dominance. Do not resurrect them from older ledger
  text.
- **Standing:** no important state by hue alone and every screen legible in
  greyscale — but that never meant monochrome. Hue is redundant
  reinforcement; **no red-versus-green pair anywhere**.
- Ornament is prohibited. The mock reads rich because of art and type.
- Four-region rule: map = space and targets, timeline = time, log =
  causality, action shelf = verbs. Combat has one action row.
- `readiedSpellCount` is 3, so eleven chips is the true row ceiling, and
  `Flee` never appears inside a crawl because `wayOut` is null there.
- The map is `Expanded`: chrome is paid for in map height. The measured
  budget is exploration 331.1 dp, typical combat 438.1 dp, worst legal combat
  580.95 dp against a 600 dp ceiling, leaving 285.3 dp of map — 7.93 rows of
  sight. Trust measured figures over the model; on device the model ran ~20 dp
  optimistic on chrome in both combat rows.
- `cameraCellSize` stays fixed at **36 dp**. Fitting the floor shrank cells to
  ~12 dp against a 48 dp touch guideline on the deepest floor, and a tap that
  must be aimed is not a tap.
- Chip and caption styles carry `inherit: false`; the chip fit rule measures
  then picks the shortest legal layout, and wrap count is **not** monotonic in
  width.
- `ActionIconImage` stays an untinted `Image.asset`; the Unit 10 masters are
  multitone.
- Determinism: decoration is hashed from coordinate and theme salt, never
  gameplay `Rng`. Same seed, same floor, same rolls.
- Tests that pin presentation implementation are rewritten to the behaviour
  they defend, never re-pinned to new literals.
- `Medium_Phone` must be user-started. Back up both device save slots under
  `app_flutter/` before any install and restore them byte-identically. The
  live path is `app_flutter/save.json`, not `files/app_flutter/save.json`, and
  the app's save rotation moves current to previous, so the previous slot
  drifts during play — restore from the backups, never from the device.
- This workstation's ImageMagick returns an anomalous `compare -metric AE` on
  some content (~19x the pixel count) while correct on identical inputs.
  Count differing pixels with a difference/threshold/mean route.
- Run formatter, analyzer and tests from `packages/app`; there is no root
  pubspec.
- **Publication discipline, learned the hard way in Unit 12:** deciding what
  to do about a finding is not authorization for the remote actions that
  follow from it. Push, pull request and merge are separate gates, each
  needing its own explicit word.
