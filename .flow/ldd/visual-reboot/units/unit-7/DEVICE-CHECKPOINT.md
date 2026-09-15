# Unit 7 — Device Gate Recovery Checkpoint

Written before the first device action, 2026-09-15. If this session dies mid-gate,
resume from here.

## Exact state

- Branch `residuum-visual-reboot-7`, head **`cb8fcbc`**, base `main` at
  `319d945`. Commits: `105dea2` records, `45b44e8` grammar + shell, `340980c`
  rooms + heroes, `cb8fcbc` review corrections.
- `packages/` is clean and committed. The only dirty paths are architect-owned
  LDD records (`LEDGER.md`, `RESUME.md`, `units/unit-7/`). Nothing user-owned is
  at risk.
- Nothing is pushed. No pull request exists for Unit 7. Publication is not
  authorized.

## Fresh evidence already accepted at `cb8fcbc`

Run by the architect from `packages/app`:

- full `flutter test` — **816 passing**
- `dart format --set-exit-if-changed --output=none lib test` — 99 files, 0 changed
- `flutter analyze` — no issues
- scope audit — 8 library files, all under `lib/town/`, plus 11 test files;
  zero changes under `packages/core`, `packages/content`, `packages/app/lib/game`,
  `lib/save`, `lib/notice`, `main.dart`, `town_bloc.dart`, `world_screen.dart`,
  or any Unit 6 route. `merchant_screen.dart` is deliberately unchanged: it
  already sat on the rebooted grammar and inherits the reshaped `TownRoom` and
  `Purse`.
- integrated acceptance review `agent://U7Acceptance` — ACCEPT WITH FINDINGS;
  its one must-fix was a ledger disclosure, and F2–F5 are corrected in
  `cb8fcbc`. F6 is recorded as Unit 8 input, not a Unit 7 defect.

## What the device gate still owes (contract criterion 11)

1. Town shell, all six rooms, and Heroes captured in normal colour **and**
   greyscale.
2. The last door (Alchemist) reachable on the phone — the column is now within
   roughly 8 pixels of a 600-pixel fold, so this is the highest-value frame.
3. Forge bench rows aligned with the material rows above them. Both now read the
   same `markColumn`, but fixed-width alignment is a device question by design:
   the plan bans pixel-geometry widget assertions, which Unit 6 already deleted
   once.
4. Confirmation that Unit 7 introduced **no new mark codepoint** — the only
   non-ASCII character added anywhere is U+2014, already shipping.
5. Bank's two zones, the tavern's moved notice, and the roster's keyed rows
   readable in greyscale.

## External and device state

- AVD is `Medium_Phone` (Android 17, 1080x2400). **It segfaults when launched
  from a tool shell — the user must start it.**
- Both device save slots must be copied aside before any install and verified
  SHA-256 identical afterwards. Known good hashes from the Unit 6 session:
  `save.json` `18995c4…b46d3`, `save-previous.json` `8909f70c…a9b11`.
- Scenes must be probed at `visit >= 1`; a first delve bumps `visit` to 1, so a
  `visit: 0` save shows the wrong standing line.
- Evidence goes to `.flow/evidence/visual-reboot/unit-7-device/` as `ev-*.png`
  with a `-greyscale.png` twin of every frame, matching Units 4–6.

## Next action

Ask the user to start the AVD, then delegate environment operation and capture
to a fresh bounded `flow-evidence-verifier`. The architect owns the checkpoint,
the acceptance brief, inspection of the returned frames, and the final judgement.
