# Resume Visual Reboot

**Units 1–11 are merged to `main`. Unit 12 is locally accepted and committed
on its branch, unpublished. Unit 12.5 carries its device debt.**

## Exact state

- Base is `main` at `60909e60ec3150cf9b590e6641a8ae51efca775c` (Unit 11's
  PR #21 merge). Unit 12 is committed on `residuum-visual-reboot-12` as
  `259322b` (the `packages/app` change) and `a34e11e` (the LDD records).
  The worktree is clean.
- **Architect-run final gate:** `dart format` 120 files / 0 changed,
  `flutter analyze` clean, full `flutter test` **906 passing**, against 884
  before the unit. `packages/core`, `packages/content` and `main.dart` are
  untouched.
- Reviews: integrated acceptance ACCEPT WITH FINDINGS (one must-fix, closed),
  then scoped closure ACCEPT WITH FINDINGS (no must-fix). Nothing outstanding
  that code can close.
- **No device evidence exists.** By the user's decision of 2026-09-17 the
  `Medium_Phone` pass is Unit 12.5's, not this unit's.
- **Nothing remote has happened or been authorized.** The commits are local;
  no push, pull request, review or merge. The branch exists only on this
  workstation.

## Exact next action

Ask the user for the **publication decision** on Unit 12: push and open a
pull request now, or hold the branch until Unit 12.5's device pass. If they
publish before 12.5, say plainly that the crawl would merge having never been
seen on glass.

Then Unit 12.5: present `units/unit-12.5/CONTRACT.md` for approval, and on
approval run its capsules through bounded `flow-evidence-verifier` sessions
after writing the device checkpoint.

## Carried debt

- **Unit 12.5 owns** Unit 12's AC5 greyscale, AC12 by eye, AC14 device
  figures, AC16 in full and AC17, plus three closure findings a device must
  settle: the hairline is proved by paint *order* only and never seen
  (OPT-1); the rule now paints over the outermost 1 dp row of Flame's output
  top and bottom (OPT-2); and a second hairline from `CrawlStatus`'s own
  `Divider` now sits 4 dp above the map's, newly visible because the map's
  rule was invisible until the must-fix (OPT-3).
- **O3, a follow-up, not a defect:** chips are keyed by their composed label,
  so a spell chip's test handle is `ValueKey('✳ Frost Lance 4')` and a mana
  rebalance in `packages/content` would break `packages/app` widget tests for
  a presentational reason. Fixing it means an `id` on `CrawlAction` — a
  locked interface — and a second churn of every test handle. No collision is
  reachable today.
- **The number to watch on device:** worst legal combat is modelled at ~561 dp
  of chrome leaving **~283 dp of map**, about seven rows of sight. If capsule
  G judges that unplayable the remedy is contract-level, not a bigger cap, and
  the four options are recorded in `PLAN.md` Correction C1.

## Carry-forward locks

- The crawl seam is a sibling of `town/town_style.dart` in shape — never a
  global `MaterialApp` theme change, never an application-wide design system.
- Four-region rule: map = space, timeline = time, log = causality, action row
  = verbs, no concern duplicated. Combat has one action row now; keep it.
- No state by hue alone; every surface reads in greyscale. Monochrome meters
  stand. Armed reads by border, fill value, type weight and the word, with the
  word on its own reserved line so arming cannot reflow the map.
- The map is `Expanded`: chrome is paid for in map height.
- `ActionIconImage` stays an untinted `Image.asset`; the Unit 10 masters are
  multitone.
- The chip fit rule measures and then picks the shortest legal layout. Wrap
  count is **not** monotonic in width — a first-fit search there is unsound
  and produced an 808 dp row once already.
- Chip and caption styles carry `inherit: false` in the seam. Without it
  `Text.build` merges Material 3's ambient `DefaultTextStyle` and renders
  taller than `_fitFor` measured.
- Tests that pin presentation implementation are rewritten to the behaviour
  they defend, never re-pinned to new literals.
- `Medium_Phone` must be user-started. Back up both device save slots under
  `app_flutter/` before any install and restore them byte-identically.
- Run formatter, analyzer and tests from `packages/app`; there is no root
  pubspec.
