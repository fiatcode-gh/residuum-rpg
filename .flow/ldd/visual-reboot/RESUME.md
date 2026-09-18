# Resume Visual Reboot

**Units 1–12 are merged to `main`, Unit 12.5's device gate is closed, Unit 13
— the visual parity re-baseline — is complete and accepted, and Unit 13.1,
the map bleed, is fixed and closed. The recut roadmap is approved as ordered.
U14 is next and has no implementation authority yet.**

## Exact state

- `main` is `907a4a83e7c592d4f6dd0c55e6f30c3b1b8bc49b`, the PR #22 merge
  (2026-09-18T08:49:20Z). The earlier record that PR #22 was open and
  unmerged is superseded.
- Branch **`residuum-visual-reboot-13`** off `907a4a8` carries two commits:
  `9c2d66e` `docs:` (Unit 13's records, `.flow/` only) and `e8bcf29` `fix:`
  (Unit 13.1 — `dungeon_scene.dart` +30/-1 plus its new test). Nothing is
  pushed; there is no pull request.
- Unit 13's canonical records are in `units/unit-13/`: `CONTRACT.md`,
  `recon.md`, `PARITY-AUDIT.md`, `PARITY-MATRIX.md`, `VISUAL-SYSTEM.md`,
  `ROADMAP.md`. The external ChatGPT bundle it came from sits beside them and
  validated clean (`sha256sum -c`, `validate-planning-handoff.py`).
- Evidence: `.flow/evidence/visual-reboot/unit-13-parity/` — ten isolated mock
  frames, ten side-by-side pairs, ten greyscale pairs.
- Two stale records were corrected: Unit 12's contract status (it said
  "drafted, awaiting explicit user approval") and Unit 12.5's checkpoint tail
  (a mid-pass forward pointer for a closed unit).

## Exact next action

**Open U14 — Type, palette and surface authority.** Draft its contract from
`units/unit-13/VISUAL-SYSTEM.md` sections 1–4 and 9, present the completed
WHAT for approval, then dispatch `flow-planner` for the execution-grade plan,
then get plan approval, then execute. It is the largest unit in the epic and
every later one consumes its tokens.

Three things U14 inherits and must not lose:

- **The ceiling-density crawl belongs in its device capsule list.** U13.1's
  AC7 was amended to drop its own emulator pass; its confirmation on hardware
  is owed here. If the dock is covered at the ceiling, U13.1 reopens.
- **The world map and the roster owe their first device shot**, colour and
  greyscale. They are the epic's only unevidenced surfaces.
- **The crawl's dp budget must be re-measured**, because type metrics move
  chrome height and the 600 dp ceiling is the real constraint.

Nothing remote is authorized. Push and pull request are each their own gate.

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
