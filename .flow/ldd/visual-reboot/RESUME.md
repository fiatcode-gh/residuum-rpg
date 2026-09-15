# Resume Visual Reboot

## Where the epic stands (verified at source 2026-09-15)

- **Units 0–6 are done and all of Units 1–6 are on `main`.** `main` is at
  `319d945`, clean and in sync with `origin/main`. PR #13 `650fa7c`, #14
  `15e737a`, #15 `55a226d`, #16 `319d945` are all MERGED; Units 1–2 landed
  directly at `5f8db47` / `06a8b9f` / `7cd32f2`; Unit 3 at `4164741`. Any older
  text calling Unit 4 "interrupted" or Unit 6 "uncommitted" is stale — it was
  corrected here after checking the forge and the branch graph.
- **Unit 7 (town + transactional rooms + heroes) is the active unit. Its
  contract is approved by the user as written** — `units/unit-7/CONTRACT.md`,
  including the no-static-art lock. That approval authorizes planning only;
  no production-writing worker may run before the plan is approved too.
- Unit 8 is world + theme parity. **Unit 9 is new**: the leftover crawl HUD
  chrome (depth header, labelled HP/Mana bars, icon control chips), placed
  after Unit 8 by the user's decision so Unit 8 stays focused.

## Exact next action

`flow-planner` is producing the execution-grade `units/unit-7/PLAN.md` plus
`units/unit-7/plan-tasks/NN-*.md` briefs. When it returns: verify the plan
against the contract, present its dependency shape, locked decisions, proof
strategy, and residual risks, and obtain **explicit plan approval** before
dispatching the first `flow-plan-executor`.

Standing lock the plan must respect: Unit 7 delivers typographic and
procedural treatment only — no image asset, no `assets/` declaration, no
portrait slot. Portrait framing, room-background ratios, bulk static-art
composition, and the icon-stroke language stay deferred to the post-Unit-8 art
pass.

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
