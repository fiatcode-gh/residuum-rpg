# Resume Visual Reboot

**Units 1–14 are integrated on `main`. Unit 15 — Row, Control and Chip
Grammar — is the active unit.**

## Exact state

- `main` is `4033de53f96470bfc75dabba6b28bc0ae67816a6`, the PR #23 merge.
- U14's code, automated gates, acceptance review and thirteen-capsule device
  pass are integrated. Its U15 follow-ups are the Character mana presentation
  and the Tavern affordability cue.
- The `unit-15-chatgpt-handoff` bundle is an untracked, user-owned external
  planning artifact. Its v1 manifest and SHA-256 receipts validated locally;
  it observes this exact `main` revision, settles U15 WHAT, carries only a
  partial implementation strategy, and carries no authorization.
- Unit 15 implementation, automated gates, scoped acceptance, and all required
  target-device evidence are complete. Every device capsule restored both
  canonical save slots with SHA-256 plus `cmp` MATCH.
- The final crawl correction reduced private chip padding only. Fresh package
  proof passed: formatter-clean, analyzer-clean, and 1,127 tests. Corrected
  worst legal target-device chrome is 591.238 dp, strictly below the locked
  600 dp ceiling. Corrected armed spell evidence preserved the exact
  `Rect.fromLTRB(0,470,1080,1192)` map slot and the fixed 36 dp camera.

## Exact next action — integration decision

Unit 15 is locally complete. Present the user with the concrete keep, commit,
or publish/PR integration choices. Do not commit, push, or open/update a pull
request until the user explicitly chooses that action.

## Unit 15 inherited locks

- Preserve current game vocabulary, transactions, action dispatch and
  information boundaries. The mock cannot create Craft, Tavern Rest/Listen/
  Leave, a current-mana town fact, or undiscovered spell identities.
- U15 creates no authored production art. Its medallion hosts are measured,
  empty-ready consumers for U16.
- The action shelf retains measure-all-candidates / shortest-legal-layout,
  the eleven-action ceiling, fixed 36 dp cells and an `Expanded` map.
- No important state relies on hue; every changed surface must remain legible
  in greyscale. The target device gate uses actual device measurements, never
  widget-test dp figures.
- Run formatter, analyzer and tests from `packages/app`; no root pubspec.

## Historical Unit 14 detail

## What Unit 14 landed, task by task

| task | commit | what |
|---|---|---|
| 01 | `b8d934b` | Spectral and EB Garamond bundled with their licences; `lib/style/tokens.dart`; the test-host `FontLoader` without which every measurement is Ahem; boot screen migrated |
| 02 | `8e1efbd` | `crawl_style.dart` to aliases, `crawlTheme` deleted, three theme sites, chrome re-measured and the caps re-derived |
| A8 | `d959f23` | `textDetailDim` and `textMicroDim`; the `copyWith` rule struck outright |
| 03 | `0f1882d` | `ResourceMeter` and the epic's first hue, geometry moved verbatim |
| 04 | `7090866` | the town, pack and roster dialogs under `residuumTheme`; ten control families proved off the M3 palette; A9's `textBaseline` on all twenty roles |
| 05 | `67513bb` | `labelColumn` and `LabelledValue`; six padded columns converted including the Inn's two; town, character and inn meters |
| 06 | `fb55622` | the world screen and its route diagram under the theme; the last unthemed screen root; three status rows to the shared meter and value rows; ten pinned test literals rewritten to behaviour |
| 07 | `2763663` | the two map glyph paints onto `textFace`; the prose sweep; **AC2 closed** and guarded by a CI step and an `AGENTS.md` rule |
| 08 | `bbd18b4` | the rename leaf: 35 alias declarations deleted, every consumer on the shared name, **AC3 closed** |

## Fourteen amendments, all one class

Every amendment was a claim about what a file contains, what a formula
yields, or what a tool reports — the class a plan cannot settle by reasoning,
and none catchable by reading the plan. They are indexed in `PLAN.md`
§"Architect amendments A1–A14"; A6 through A9 are described in the Task 01–05
ledger entries, A10 through A14 in the Task 06–08 entries.

The five ruled in this wave:

- **A10** — four test files pinned the world screen's padded rows, not the
  two brief 06 named. Ten assertions rewritten to behaviour.
- **A11** — brief 07's prose-sweep list was stale; the surviving mentions sat
  in dartdoc Tasks 01 and 05 had written themselves, and the CI gate Task 07
  introduces greps comments, so the gate could not pass until they went.
- **A12** — brief 06's "passes before and after" was wrong. An unregistered
  family is measured as Ahem by the widget-test host, so the no-clipping
  proof was Red before the change and Green after, at 98.79 dp against a
  120 dp box.
- **A13** — brief 08's counts were pre-A7 (27 deleted / 4 kept, not 26 / 5).
  Ruled before dispatch so a low-reasoning agent would not read three stale
  numbers as contract violations.
- **A14** — a deleted name inside a `testWidgets` description follows the
  rename; it is a stale name, not a laundered behavioural change.

## Two execution lessons worth carrying

- **`sonic` stalled on Task 08 and left a defect.** A rename that eats a word
  out of a string literal turned `import '../style/tokens.dart'` into
  `import '../style/dart'`. The routing was defensible — A7 had removed the
  keep-list trap that justified a reasoning agent — but the deeper rule is
  that **an analyzer-driven repair loop is not a mechanical leaf**, however
  exhaustively the names are enumerated, because the worklist is discovered
  by running a tool and reading what it says. A fresh `flow-plan-executor`
  finished it, worked 62 issues to zero, and reconciled every substitution
  against the alias's own former right-hand side.
- **Gate A's figures are not printed by the suite.** `reason:` renders only
  on failure. They were taken from an **untracked copy** of
  `crawl_action_row_test.dart` with three `debugPrint`s injected, run once and
  deleted. Never mutate the tracked test to read its own numbers.

## Suite count, read honestly

907 before Task 01, **1115** now. The growth is overwhelmingly
parameterisation — twenty roles times six invariants, plus the per-mark glyph
sweep and the ten-row palette table. Task 06's diagram-fit group is the last
six. Do not read 1115 as coverage growth and do not try to keep the number up.

## Unit 13.1, closed 2026-09-18

Root cause: Flame's default `MaxViewport.clip()` is an explicit no-op
(`flame-1.38.2/.../max_viewport.dart:26`) and `GameRenderBox` never clips on
its behalf, so the viewport's reported size only ever positioned the camera
while the world's whole `visible ∪ explored` tile set painted straight
through onto the chrome above. Fixed by `_ClippedMaxViewport`
(`dungeon_scene.dart:187-213`), which adds the clip `MaxViewport` omits and
inherits its size tracking.

**Carry this measurement trap:** `flutter_test`'s font fallback wrapped the
same 11 chips into 4 runs where the device fits 3, giving 208.43 dp / 5.79
rows against the device's 285.33 dp / 7.93. Widget-test dp figures are not
device dp figures. Never copy one into the ledger as the other. A12 is the
same trap in a second costume.

## Settled by the user, 2026-09-18

1. **Fonts: Spectral for text, EB Garamond for display.** Every density
   failure in the audit is at 12–13 px, which is where a decorative face
   breaks.
2. **The shared style seam is approved** — one token module plus sibling
   per-screen themes. "Never an application-wide design system" is superseded
   **to exactly that extent**; a `MaterialApp`-wide restyle of stock Material
   controls stays prohibited, and Gate B verified both `theme:` arguments are
   still bare.
3. **Frame 4's three intermediate cells are a mock flourish.** No range or
   path feedback will be built.
4. **The world map and the roster inherit the vocabulary and gain an evidence
   gate** — U14 owes the first device shot of each, capsules F and G.
5. **Roadmap approved as ordered**, U13.1 first.

## The recut roadmap, in one table

| Unit | Frames | Ownership | Depends on |
|---|---|---|---|
| U14 Type, palette and surface authority | all ten | CODE + ASSET | **implemented; Gate B review open** |
| U15 Row, control and chip grammar | 1–4, 6–10 | CODE | U14 |
| U16 Authored icon and art families | 1, 5–10 | ASSET + thin CODE | U15's empty medallion slot |
| U17 Illustration headers and hero portrait | 1, 6, 9, 10 | CODE + ASSET | U14 |
| U18 Dungeon light and stone value | 2, 3, 4 | CODE | nothing |
| U19 Dungeon structure and props | 2, 3 | CODE + ASSET | U18 |
| U20 Actor representation | 2, 3, 4 | CODE + ASSET | U18 |
| U21 Combat chrome density | 2–5 | CODE | U14, U15 |
| U13.1 map bleed (defect) | 2, 3 | CODE | **done** — `e8bcf29` |

## Carried debt

- **The map-bleed fix carries one open obligation**: hardware confirmation at
  U14's device gate, capsule J. Until that pass it is proved headlessly and
  on no real screen.
- **Save-read defect candidate, unproven and out of the epic.** The app
  reported *"your last save could not be read; an older one was restored"*
  for a post-death autosave whose bytes were readable — the codec refused the
  document. Reproduce directly: stage a hero at 1 HP, die, feed the resulting
  `save.json` to `decodeSave`. If real, a player who dies loses a slot. Needs
  its own contract; it blocks no visual unit and must not be diagnosed inside
  one.
- **O3, a follow-up, not a defect.** Chips are keyed by their composed label,
  so a mana rebalance in `packages/content` would break `packages/app` widget
  tests for a presentational reason. U15 may retire the label-keyed handles.
- **Twelve marks are uncovered by both faces**, seven of them const markings
  in `packages/core`, which stays untouched. They render from platform
  fallback today, so nothing regresses; U16 retires them. `✳ ✚ ⛒` sit inside
  crawl chip labels that `_fitFor` measures, so their host-dependent advance
  is the one real threat to the widget-test versus device agreement claim.

## Carry-forward locks

`units/unit-13/VISUAL-SYSTEM.md` is the authority for appearance. These are
the ones a future session will trip over if it does not know them.

- **Superseded by Unit 13:** monospace-only identity; colour avoidance;
  Material-derived geometry and stock controls; "compositions are near-fixed";
  "authored assets are a late optional possibility"; Unit 12.5 AC17's
  conclusion about dungeon dominance. Do not resurrect them from older ledger
  text. **Monospace is now retired by CI**, not merely by convention.
- **Standing:** no important state by hue alone and every screen legible in
  greyscale — but that never meant monochrome. Hue is redundant
  reinforcement; **no red-versus-green pair anywhere**.
- Ornament is prohibited. The mock reads rich because of art and type.
- Four-region rule: map = space and targets, timeline = time, log =
  causality, action shelf = verbs. Combat has one action row.
- `readiedSpellCount` is 3, so eleven chips is the true row ceiling, and
  `Flee` never appears inside a crawl because `wayOut` is null there.
- The map is `Expanded`: chrome is paid for in map height. Trust measured
  figures over the model; on device the model ran ~20 dp optimistic on chrome
  in both combat rows.
- `cameraCellSize` stays fixed at **36 dp**. Fitting the floor shrank cells to
  ~12 dp against a 48 dp touch guideline, and a tap that must be aimed is not
  a tap.
- Chip and caption styles carry `inherit: false`; the chip fit rule measures
  then picks the shortest legal layout, and wrap count is **not** monotonic in
  width. **Every type role also carries an explicit `textBaseline`** (A9) —
  an `inherit: false` style with a null baseline crashes any `TextField` under
  the theme.
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
