# Resume Visual Reboot

## Where the epic stands (verified at source 2026-09-15)

- **Units 0–7 are done and all of Units 1–7 are on `main`.** `main` is at
  `f322d78`, clean and in sync with `origin/main`. PR #13 `650fa7c`, #14
  `15e737a`, #15 `55a226d`, #16 `319d945`, and #17 `f322d78` are all MERGED;
  Units 1–2 landed directly at `5f8db47` / `06a8b9f` / `7cd32f2`; Unit 3 at
  `4164741`.
- **Unit 8 is code-complete, locally accepted, and on a PR.** The whole
  correction round is one commit, `54d6b4b` `fix: close unit eight review
  findings`, on `residuum-visual-reboot-8` over `c85c7f9` and pushed; PR
  **#18** `feat: reboot the world map and regional material` is open against
  `main`. The independent acceptance review had rejected the unit; all four
  findings are closed. U8-AR-3 went to the repository convention rather than the
  brief (no new app **library** Dartdoc; both briefs corrected in place, source
  already complied). U8-AR-1 was the one real defect and is Red-backed. The
  scoped closure review (`agent://U8Closure`) returned ACCEPT WITH FINDINGS,
  zero must-fix, and its three optional craft items are folded in.
- Final architect gates at `54d6b4b` from `packages/app`: full `flutter test`
  **826 passing**, `dart format --set-exit-if-changed` over `lib` and `test`
  100 files 0 changed, `flutter analyze` no issues, `core`/`content` untouched.

## Exact next action

Run Unit 8's deferred device gate (contract criterion 9) on `Medium_Phone`
before Unit 9 opens, then integrate PR #18 on the user's word. Nothing else in
Unit 8 is outstanding, and the working tree is clean.

## Deferred device evidence

The user explicitly deferred Unit 8's AVD/device-size and greyscale validation
to a later session. Do not start an emulator without being asked. Two specific
questions are waiting on it: whether a real screen reader reaches the below-fold
diagram nodes (the 430-pixel diagram sits in `world_screen.dart`'s `ListView`,
and at 800x600 the Crypt and Stonebridge nodes carry `isHidden` — identically at
`c85c7f9`, so it is Task 01 geometry, not a correction defect), and whether the
Sea-Cave strata and Ruined Keep fracture strokes read at phone density.

Unit 7's final evidence at `cb8fcbc`, all architect-run from `packages/app`:
full `flutter test` **816 passing**, `dart format --set-exit-if-changed` over
`lib` and `test` 99 files 0 changed, `flutter analyze` no issues, scope audit
clean (8 library files all under `lib/town/`, 11 test files, zero changes to
`core`/`content`). Acceptance review `agent://U7Acceptance` returned ACCEPT WITH
FINDINGS; its must-fix was a ledger disclosure and F2–F5 are corrected in
`cb8fcbc`. Device gate `agent://U7Device` passed on `Medium_Phone`; both save
slots verified byte-identical to their pre-session backups.

Carried into Unit 8: finding **F6** — `character_screen.dart` is the room behind
door 4 and is still the last old-grammar surface in the town, built from four
full-width `FilledButton` slabs and a `panel` card. Also the town's only hue is
Material's default seed on `FilledButton`; the town has no theme of its own.

Standing locks: no image asset, no `assets/` declaration, no portrait slot, and
**no new mark codepoint**; the art bible stays deferred to the post-Unit-8 art
pass. Greyscale device twins are now required **only** for frames introducing a
new mark codepoint or a non-neutral colour — Unit 8's Sea-Cave and Ruined Keep
palettes qualify.

## Unit 7 recon summary (source-verified, 2026-09-15)

- Town is `packages/app/lib/town/town_screen.dart`: a menu pushed over the
  world screen, seven doors in fixed order (Merchant, Bank, Inn, Character,
  Tavern, Forge, Alchemist), with health, carried/banked gold, the descents
  sentence, `MaterialRows`, and `Notice` above them. Leaving town is the back
  button; dungeon entry lives at the dungeon's world node.
- Every town room is still original M3-era composition on `TownRoom` +
  `town_style.dart` (`ink`/`dim`/`panel`/`rule`, `mono`, `Heading`, `ItemRow`,
  `Purse`, `MaterialRows`, `MaterialsPanel`, `Notice`, `CountStepper`).
  Units 1–6 rebooted the crawl and the Character information architecture only.
  Unit 6's `CharacterScreen` still renders inside the M3 town grammar.
- `TownBloc` (994 lines) owns 23 events across dungeon entry/exit, merchant,
  bank, inn, tavern, forge, alchemist, and wear/read/take-off.
  `TownViewState` exposes the computed refusals (`smeltReason`, `brewReason`,
  `temperReason`, `wearReason`, `takeOffReason`, `readReason`) plus
  `wornSteel` / `carriedSteel` / `temperable` and the camp-overrun predicates.
  Every refusal originates in core; the app only projects it.
- Heroes is `RosterScreen`, pushed from `WorldScreen`, not a town door. It
  reads the live `SaveDocument` through the autosaver rather than a bloc, and
  answers with a sealed `RosterChoice` (`PlayHero`, `MakeHero(replacing)`,
  `DropHero`) that `main.dart` turns into a session rebuild. Deleting the last
  hero is a replacement write, because the game never has zero heroes.
- The game is one active hero with a roster of alts — never a party. Each
  `SavedHero` carries its own profile, suspended run, world whereabouts, and
  merchant visit.
- Full recon: `agent://TownRoomsScout`, `agent://HeroesScout` (this session).

## Traps that can burn the next session

- **A mark codepoint can render as a colour emoji on device and no widget test
  will ever catch it.** Unit 5 shipped `↕` (U+2195), which Android resolved
  through the colour emoji font — hue then carried meaning. It is now `⇅`
  (U+21C5). U+2B65 is tofu on this target. Measure every new mark on device.
- Mark columns are laid out as fixed-width columns, not space-padded strings:
  the device monospace font gives the ingot bar and the ore diamond different
  widths, so padding aligns on desktop and steps sideways on the phone.
- Town rooms already exercise the seven-door overflow: the column overflowed a
  600-pixel screen by 45 pixels once, and a door a player cannot reach is a door
  that is not there.
- Refusal sentences are product prose. Rewording one is a behavior change.
- Suites run per package directory — there is no root pubspec.
- A first delve bumps `visit` to 1, so device scenes must be probed at
  `visit: 1`, never `visit: 0`.
- The AVD is `Medium_Phone` (Android 17). It segfaults when launched from a
  tool shell — ask the user to start it. Copy BOTH device save slots aside
  before any install and verify SHA-256 after.
- The approved mock is untracked evidence at
  `.flow/evidence/visual-reboot/residuum_visual_reboot_approved_mock.png`.

## Locked inherited contracts

Section 18 baseline in `LEDGER.md` (Flame never authoritative game state;
graphical glyphs; map-first melee; four-region rule; accessibility by shape or
word, never hue alone) plus everything in `../m3/LEDGER.md` (save v3, band
lines as controls, house method D113, CI/merge flow).

## Still open

- Does old-wave m3-quests (M3Q, save v4, `../m3/LEDGER.md`) still run, and
  where in the sequence?
- Curated static-art generation (handoff 11.2) needs an owner and a tool
  outside the repo; nothing in Unit 7 depends on it.
- Full decision history: this ledger is young — `../legacy/LEDGER.md`
  (D1–D126) and `../m3/LEDGER.md` hold the product's deep history.
