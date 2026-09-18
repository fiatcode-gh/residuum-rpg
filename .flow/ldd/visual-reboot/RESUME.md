# Resume Visual Reboot

**Units 1–12 are merged to `main`, Unit 12.5's device gate is closed, and
Unit 13 — the visual parity re-baseline — is complete and accepted. The recut
roadmap is approved as ordered: U13.1, then U14 through U21. Nothing is
implemented yet and no unit has implementation authority.**

## Exact state

- `main` is `907a4a83e7c592d4f6dd0c55e6f30c3b1b8bc49b`, the PR #22 merge
  (2026-09-18T08:49:20Z). The earlier record that PR #22 was open and
  unmerged is superseded.
- Unit 13's records are committed on branch **`residuum-visual-reboot-13`**
  off `907a4a8`, as a `docs:` commit. Unit 13 changed `.flow/` only — no
  production file, no production asset. Nothing is pushed.
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

**Open U13.1, the map-bleed defect.** It is first in the approved order.
Draft its contract, present the completed WHAT for approval, and only then
work — under `flow-debugging`, because it needs root-cause diagnosis rather
than a patch. Do not reach for a `ClipRect` first (see Carried debt).

Then U14: contract, approval, `flow-planner`, plan approval, execution.

The roadmap approval authorizes the roadmap's shape and Unit 13's decisions.
It is **not** implementation authority for any unit, and nothing remote is
authorized. Push and pull request are each their own gate.

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
| U13.1 map bleed (defect) | 2, 3 | CODE | **runs first** |

## Carried debt

- **The map-bleed defect**, still open and now scheduled as U13.1. At
  worst-legal-battle density the Flame canvas paints ~144 px (~55 dp) above
  its own top hairline and, being a later sibling in the `Column` than
  `BattleDock`, covers the dock opaquely; both ring tokens are cut in half and
  the actor words are hidden, so Unit 12's AC6 fails visually at the ceiling
  while its logic passes. `game_screen.dart` lines 80–136 wrap the map in a
  `Stack` with no `ClipRect`. Evidence:
  `.flow/evidence/visual-reboot/unit-12.5-device/u125-g-battledock-bleed-color.png`.
  - **Do not reach for a `ClipRect` first.** If the viewport renders more rows
    than its box owns, a clip hides the overflow while the camera keeps
    showing rows the box does not own, which silently invalidates the
    7.93-rows-of-sight figure. Diagnose why the canvas exceeds its
    constraints.
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
