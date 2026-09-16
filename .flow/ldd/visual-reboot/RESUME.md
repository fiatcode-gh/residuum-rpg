# Resume Visual Reboot

**Unit 8's deferred device gate is closed and Unit 9 is locally accepted as of
2026-09-16.** This branch is ready for the user's integration decision. Read
this file, then the final Unit 9 records at `LEDGER.md:1301-1478`; do not
reconstruct evidence from old worker transcripts.

## Exact state of the working tree

- Branch **`residuum-visual-reboot-9`**, branched from `2b0e0a4` (the merged
  Unit 8 head on `main`). **Nothing is committed on this branch.** No remote
  branch exists; no push and no pull request are authorized.
- Modified, all Unit 9 implementation: `packages/app/lib/game/game_screen.dart`
  (916 → 750 lines), `test/widget/world_screen_test.dart`,
  `test/widget/suspend_door_test.dart`, `test/widget/roster_session_test.dart`,
  `test/widget/boot_wiring_test.dart`, `test/battle_characterization_test.dart`.
- Renamed: `test/widget/hud_depth_test.dart` →
  `test/widget/crawl_status_test.dart` (recorded as `RM` by git).
- **Untracked and load-bearing:** `packages/app/lib/game/crawl_status.dart`. A
  `git checkout`/`clean` would destroy the unit. Do not clean the tree.
- Also modified/untracked: architect-owned `.flow/ldd/visual-reboot/LEDGER.md`,
  `RESUME.md`, and `units/unit-9/`.
- `packages/core` and `packages/content` have zero changes.

## Fresh evidence accepted (do not re-earn)

Architect-run from `packages/app` at this exact tree, 2026-09-16:

- `dart format --set-exit-if-changed --output=none lib test` — 101 files, 0 changed
- `flutter analyze` — no issues
- full `flutter test` — **834 passing** (826 at Unit 8's close)

`agent://U9AcceptanceResume` then independently reviewed the actual patch and
untracked `crawl_status.dart` against the approved contract and plan: **PASS**,
no Critical or Important findings, no tree mutation. Its source inspection
confirmed fact preservation, deletion of the old formatter, no ellipsis path,
monochrome accessibility, migrated behavioural tests, height-budget structure
and app-only scope. The review barrier is closed; this proof remains fresh.

## Final acceptance

Unit 9's two-row crawl status passed the exact-tree format/analyze/full-suite
gate (101 files unchanged, analyzer clean, 834 tests passing), independent
acceptance review, and all contracted `Medium_Phone` frames. The current/base
comparison measured the map cost at 52 px — exactly one text row. All staged
device captures restored both `app_flutter` save slots byte-identically.

Unit 8's folded gate also passed: discovery/full/journey worlds, both regional
delves, all three road variants and their greyscale reading, plus the user's
physical TalkBack traversal to both below-fold dungeon nodes. The inherited
five-control `Drink (…)` truncation appears identically at `2b0e0a4` and is not
part of Unit 9's frozen control change.

## Exact next action

Ask the user how to integrate the locally accepted uncommitted Unit 9 branch.
No commit, push or pull request has been made or authorized.

## What Unit 9 built

The crawl's single scale-down status string became two rows in the new
`packages/app/lib/game/crawl_status.dart`: a header (place name upper-cased
left, battle glyph and word centre, `depth / deepest` right; `THE ROAD` with the
depth-pair `SizedBox` **absent** on the road) and a resource row of two labelled
monochrome meters in the `_SkillRow` grammar. The Mana cell exists only when
`knownSpells.isNotEmpty`; `Ward n` is that cell's note only while a ward stands.
`_line`, `_magic` and `_whereabouts` are deleted; `_condition` and `_battleWord`
survive verbatim; `_BattleGlyph` moved. `GameScreen` now calls
`CrawlStatus(state: state, dungeon: bloc.dungeon)` at `game_screen.dart:124`.

User-locked, and not reopenable without them: the mock's red HP / blue Mana
fills are **rejected**; its icon control chips are **deferred** to the
post-Unit-8 art pass; the control row stays text-only.

## Epic state

- **Units 1–8 are merged to `main`** at `2b0e0a4`, which is in sync with
  `origin/main`. PRs #13–#18 all MERGED.
- **Unit 8's acceptance criterion 9 is still open** and, by the user's decision,
  **folds into Unit 9's device pass**. Unit 8 stays formally open until it
  passes. Its two waiting questions: whether a real screen reader reaches the
  below-fold world-diagram nodes, and whether the Sea-Cave strata and Ruined
  Keep fracture strokes read at phone density.
- Unit 9 is the last unit in the locked order 1 → … → 9.

## Traps that can burn the next session

- **`crawl_status.dart` is untracked.** Any clean/checkout/stash loses the unit.
- **The mock's layout was already built once and beaten by hardware.**
  Pre-change `game_screen.dart:246-258` recorded a stretched bar plus three
  fixed labels that overflowed a phone by 64 pixels once the dungeon was named,
  invisible to widget tests because the default surface is wider than a phone.
  Nothing on the new rows may ellipsise.
- **The widget harness can now reach phone width**: `test/support/phone.dart`
  `onAPhone` gives 411.4 x 923.4 logical pixels. But `flutter_test`'s bundled
  font is not the device's, so glyph advances and scaled-cell legibility remain
  device facts.
- **The map is `Expanded` (`game_screen.dart:76`)** — new chrome never overflows
  the crawl, it silently shrinks the play surface. Criterion 5 caps the cost at
  one extra text row, measured on device.
- **A mark codepoint can render as a colour emoji on device and no widget test
  will catch it.** Unit 5 shipped `↕` (U+2195), resolved through the colour
  emoji font; it is now `⇅` (U+21C5). U+2B65 is tofu on this target. Unit 9 adds
  no codepoint.
- Suites run per package directory; there is no root pubspec.
- A first delve bumps `visit` to 1, so device scenes must be probed at
  `visit: 1`, never `visit: 0`.
- The AVD is `Medium_Phone` (Android 17); ask the user to start it. Copy BOTH
  device save slots aside before any install and verify SHA-256 after; read
  `app_flutter/save.json`, never `files/save.json`.
- The approved mock is untracked evidence at
  `.flow/evidence/visual-reboot/residuum_visual_reboot_approved_mock.png`.

## Locked inherited contracts

Section 18 baseline in `LEDGER.md:69-116` (Flame never authoritative game state;
graphical glyphs; map-first melee; four-region rule; accessibility by shape or
word, never hue alone) plus everything in `../m3/LEDGER.md` (save v3, band lines
as controls, house method D113, CI/merge flow). Standing locks: no image asset,
no `assets/` declaration, no portrait slot, no new mark codepoint; the art bible
stays deferred to the post-Unit-8 art pass.

## Still open beyond Unit 9

- The post-Unit-8 art pass (portraits, bulk static art, room-background ratios,
  the full non-dungeon icon language) has no owning unit.
- Does old-wave m3-quests (M3Q, save v4, `../m3/LEDGER.md`) still run, and where
  in the sequence?
- Curated static-art generation (handoff 11.2) needs an owner and a tool outside
  the repo; nothing in Unit 9 depends on it.
- Deep history: `../legacy/LEDGER.md` (D1–D126) and `../m3/LEDGER.md`.
