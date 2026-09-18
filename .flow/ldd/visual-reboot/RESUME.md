# Resume Visual Reboot

**Units 1–11 are merged to `main`. Unit 12 is accepted and Unit 12.5, its
device gate, is closed. Unit 12's publication is authorized and is the action
in flight.**

## Exact state

- Base is `main` at `60909e60ec3150cf9b590e6641a8ae51efca775c` (Unit 11's
  PR #21 merge). Unit 12 is `259322b` (the `packages/app` change) plus the
  LDD records on `residuum-visual-reboot-12`.
- **Unit 12.5 closed 2026-09-18 on device evidence.** Contract approved as
  drafted; seven capsules plus setup ran on a user-started `Medium_Phone`
  through bounded `flow-evidence-verifier` sessions. Full result in
  `LEDGER.md` under "Unit 12.5 — the crawl device gate, closed" and in
  `units/unit-12.5/DEVICE-CHECKPOINT.md`.
- **The three dp gates pass, measured:** exploration 331.1 dp chrome against
  360; typical combat 438.1 dp against 460; worst legal combat **580.95 dp
  against 600**, leaving **285.3 dp of map — 7.93 rows of sight**, which reads
  as a playable dungeon. Correction C1's four contract-level remedies are not
  needed.
- The eleven-chip ceiling renders with no ellipsis, no word split and no
  hidden verb. Unit 12's AC5, AC6 (logic), AC8, AC11, AC12, AC14, AC16 and
  AC17 are all settled — see the ledger for each verdict.
- **Architect-run gate on the merge tree:** `dart format` 120 files / 0
  changed, `flutter analyze` no issues, full `flutter test` **906 passing**.
  Unit 12.5 wrote no production code.
- **Both device save slots restored and verified byte-identically** after the
  pass: `save.json` `18995c4c…b46d3` MATCH, `save-previous.json`
  `8909f70c…a9b11` MATCH under SHA-256.

## Exact next action

Publish Unit 12 as the user authorized on 2026-09-18: push
`residuum-visual-reboot-12`, open the pull request, and merge — the same route
units 10 and 11 took (PRs #20, #21). Then the next unit is the map-bleed
defect below, which outranks Dungeon Structural Asset Expansion.

## Carried debt

- **The map-bleed defect, accepted knowingly.** At worst-legal-battle density
  the dungeon map's Flame canvas is not clipped to its `Expanded` box: it
  paints ~144 px (~55 dp) above its own top hairline and, being a later
  sibling in the `Column` than `BattleDock`, covers the dock opaquely. Both
  ring tokens are cut in half and the actor words are hidden, so **AC6 fails
  visually at the ceiling while its logic passes**. `game_screen.dart` lines
  80–136 wrap the map in a `Stack` with no `ClipRect`. The architect
  recommended fixing it before merge; the user chose to merge as-is and fix it
  later. Evidence:
  `.flow/evidence/visual-reboot/unit-12.5-device/u125-g-battledock-bleed-color.png`.
  - **Do not reach for a `ClipRect` first.** If the Flame viewport renders
    more rows than its box owns, a clip hides the overflow and quietly
    invalidates the 7.93-rows-of-sight figure. Diagnose why the canvas exceeds
    its constraints.
- **Save-read defect candidate, unproven.** The app reported *"your last save
  could not be read; an older one was restored"* for a post-death autosave
  whose bytes were readable — the codec refused the document. Reproduce
  directly: stage a hero at 1 HP, die, feed the resulting `save.json` to
  `decodeSave`. If real, a player who dies loses a slot. Needs its own
  contract; Unit 12.5's non-goals excluded the save schema.
- **O3, a follow-up, not a defect:** chips are keyed by their composed label,
  so a mana rebalance in `packages/content` would break `packages/app` widget
  tests for a presentational reason. Fixing it means an `id` on `CrawlAction`,
  a locked interface, and a second churn of every test handle. No collision is
  reachable today.
- **Roster has no visual baseline** anywhere in the epic's evidence. It passed
  Unit 12.5 on internal consistency only.

## Carry-forward locks

- The crawl seam is a sibling of `town/town_style.dart` in shape — never a
  global `MaterialApp` theme change, never an application-wide design system.
- Four-region rule: map = space, timeline = time, log = causality, action row
  = verbs, no concern duplicated. Combat has one action row; keep it.
- No state by hue alone; every surface reads in greyscale. Monochrome meters
  stand. The crawl's only disabled chip is `Drink` at game-over, and it reads
  by label weight and icon opacity — the fill/border cues compress under the
  death scrim.
- The map is `Expanded`: chrome is paid for in map height. On device the
  model ran ~20 dp optimistic on chrome in both combat rows; trust measured
  figures over the model.
- `readiedSpellCount` is 3, so knowing every spell yields three chips plus a
  `+N` overflow. Eleven chips is the true row ceiling, and `Flee` never
  appears inside a crawl because `wayOut` is null there.
- `ActionIcon.forSpell` maps only `firebolt` and `mend`; the other four spells
  render word-only by design, and the chip family survives it.
- `ActionIconImage` stays an untinted `Image.asset`; the Unit 10 masters are
  multitone.
- The chip fit rule measures and then picks the shortest legal layout. Wrap
  count is **not** monotonic in width.
- Chip and caption styles carry `inherit: false` in the seam.
- Tests that pin presentation implementation are rewritten to the behaviour
  they defend, never re-pinned to new literals.
- `Medium_Phone` must be user-started. Back up both device save slots under
  `app_flutter/` before any install and restore them byte-identically. The
  live path is `app_flutter/save.json`, not `files/app_flutter/save.json`, and
  the app's save rotation moves current to previous, so the previous slot
  drifts during play — restore from the backups, never from the device.
- This workstation's ImageMagick returns an anomalous `compare -metric AE` on
  some content (~19x the pixel count) while correct on identical inputs. Count
  differing pixels with a difference/threshold/mean route.
- Run formatter, analyzer and tests from `packages/app`; there is no root
  pubspec.
