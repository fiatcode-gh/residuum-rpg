# Build prompt — M3C `m3-craft`

You are the build session for M3C on branch `m3-craft`. You write all the
production code for this unit. The architect (the session that sent your
kickoff message) decides, answers, and verifies — reply to THE SENDER of
your kickoff with the message tool. **Printing to your own transcript
reaches nobody**: a reply is a message-tool send, not output.

## 1. Worktree

`/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-craft`
— **already created on branch `m3-craft` @ `83b5336` — do NOT create it.**

## 2. Working directory — first command, before anything

```
cd /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-craft && pwd
```

Confirm the output. Every git command as `cd <worktree> && git <cmd>`. The
parent repository is NOT yours. No sibling worktrees exist; if one appears,
do not touch it.

## 3. The spec

Read in full, before any code:
`/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-craft-spec-M3C.md`

Background (read when a spec claim looks wrong):
`/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-craft-recon.md`

Both are in a gitignored planning directory. **Never commit anything under
`docs/epic/`.** Your plan goes to `docs/plans/`; your report mirror and
reasoning trail to `docs/reports/` (gitignored).

## 4. The work, in one paragraph

Add crafting to Residuum: ore veins and herb patches appear in dungeons
(state on their own salted stream — never tiles, never items), an underfoot
Gather action harvests them into material COUNTERS (ore/ingot/herb,
mirroring gold: carried, lost on death), and two new town rooms in both
towns spend them — the Forge (smelt ore into ingots; temper a found
weapon's or armour's stats by +1/+2/+3, gated by Blacksmith, costing ingots
and gold) and the Alchemist (brew herbs into healing potions). Herbcraft
and Blacksmith join the skill enum and train by doing. Save format bumps to
version 3. **The measurable effect: a hero can mine, smelt, temper, and
brew — while all four band lines, the merchant shelf golden, the crypt
layout goldens, and both rng-state integer pins return BYTE-IDENTICAL,
because nothing touches a drop table, a weight, or the combat/loot
streams.**

## 5. Be adversarial about the spec

Spec defects are expected findings — the last two units each proved the
architect wrong before code, by measurement. The premises most worth
attacking here:

- **The band-identity claim (control C1) — attack it exactly as M3M's
  worker attacked the last one.** The architect argues the D56 failure
  mechanism is absent by construction (no weight total moves, no new
  draw on `rng`/`lootRng, nothing bot-visible). If you find ANY path
  where node placement, materials, or temper reaches an existing stream
  or the bot's inputs, measure it and stop — do not build around it.
- **The starting numbers** (smelt 2:1, brew 3:1, temper gates 0/5/10 and
  costs 1+10/2+25/3+50, node counts 0–2, `sellPriceOf` temper term ×3) —
  all worker-tunable with a reasoned trail; the SHAPES are fixed, the
  numbers are proposals from an architect with two arithmetic errors on
  record.
- **Town-side skill training has no precedent** — the spec asks you to
  pre-declare its mechanism before building it. Do.
- **The temper marking** must not collide with the rarity column's `+`
  and `++` — check the actual widgets before choosing.
- **The brewed-item id mechanism** (`brew-<brewNumber>` on Profile) —
  if you find a cheaper uniqueness scheme, pre-declare it.

**Pre-declare every shape deviation BEFORE building it.** Blockers and any
stop condition: stop and message, with measurements. Answers come fast.

## 6. Method

Full workflow: written plan first (writing-plans) to
`docs/plans/2026-08-25-m3-craft.md, then strict test-driven development
(red → green → refactor per behavior), verification-before-completion at
the end. This unit is M with a wide test surface — the plan is required.

**Characterization first.** Before any change: re-run all three suites
from their package directories and quote the four band lines verbatim from
YOUR run as the baseline block (expected: 657 + 472 + 441 = 1570; crypt
`20/40 won (50.0%), stalled 0, died at 1:1 2:6 3:6 4:7 5:20`;
`greedy build: 20/40 won; fleetfoot-first build: 14/40 won`; sea-cave
`30/40 won (75.0%), stalled 0, died at 2:1 3:8 4:13 5:9 6:9`; ruined keep
`25/40 won (62.5%), stalled 0, died at 1:4 2:5 3:4 4:2 5:13 6:6 7:6`). If
your baseline differs, STOP and message the architect. **Capture the
version-2 golden fixture string BEFORE any codec change** (the sequencing
trap that bit twice). Every commit exits green. Test bodies
`// arrange` / `// act` / `// assert`. Conventional commits.

Numbers you tune (node counts, yields, ratios, gates, costs, the price
term) get a REASONED TRAIL in `docs/reports/TUNING-TRAIL.md` — here the
trail records choices and pacing arguments, because no band may move; any
moved line is a defect to chase, never a re-pin.

## 7. Environment traps (restated verbatim from the ledger)

- Sandbox: `git -C <repo> <cmd>` does NOT match the sandbox exclusion patterns —
  always write git as `cd <repo> && git <cmd>`.
- `find` inside the Bash tool is bfs 4.1.1, not GNU findutils: `-newermt` takes
  ISO 8601 only; relative strings like `'15 minutes ago'` error (and read as
  empty with stderr suppressed). GNU find is at `/usr/bin/find`.
- Subagents dispatched into a git worktree do not inherit cwd — force an
  explicit `cd <worktree> && pwd` first or they commit in the parent repo.
- No fvm in this repo: plain `flutter` / `dart` (system Flutter 3.47.0).
- The ledger directory `docs/epic/` is gitignored — build sessions must never
  commit anything under `docs/epic/` and cite its files by absolute path.
- Commits use the personal persona:.
- Device nodes are hidden inside sandboxed Bash: `/dev/kvm` reads as missing
  while it exists on the host — hardware probes lie under sandbox. Emulator,
  adb, and `flutter run` need unsandboxed commands (permission prompt; a
  `--bg` session stalls on it silently).
- AVD `Pixel_10` exists (`emulator -list-avds`); `flutter emulators` and
  `flutter emulators --create` mishandle the installed ps16k system images —
  use the `emulator` binary directly.
- UPDATE 2026-08-20 (D8): `emulator, `adb, and device-facing `flutter`
  subcommands (`run`/`devices`/`emulators`/`install`/`attach`/`logs`/`drive`)
  are now sandbox-excluded — no prompt. Other hardware probes still lie.
- `git worktree add`/`remove` and deleting a worktree's `.claude` files fail
  under sandbox (EROFS on `.git/worktrees/, "busy" on protected config
  paths) — run worktree lifecycle commands unsandboxed.
- `adb shell input swipe` at 400ms emits too few motion samples for
  Flutter's pan recogniser and looks like a broken pan; 1200ms pans
  correctly. Tooling artifact, not an app bug (cost the M2Q worker three
  screenshots).
- A physical phone may be attached alongside the AVD: pin every adb and
  flutter command to the emulator serial (`-s emulator-5554`); never
  install to or touch the phone (user instruction during M3R).
- Device saves are playtest state: before pushing any acceptance save to
  the emulator, copy `save.json` AND `save-previous.json` aside
  (`run-as … cat > /tmp/…`) and restore after. The M3X pass overwrote the
  user's 2026-08-23 playtest save and its backup, unrecoverably.
- `flutter install` can DESTROY the app's whole data directory: it prints
  "Uninstalling old version..." and may then fail on a missing APK,
  leaving no app and no data. The M3M pass lost both save slots this way;
  the copy-aside ritual (previous trap) was the only recovery — treat it
  as mandatory before ANY install/uninstall, not only before pushing
  saves. The debug APK is ~153 MB; check emulator free space first.
- `tea pr create` does not resolve a worktree's `.git` file — run it from
  the MAIN repo root (`cd <repo> && tea pr create ...`), where it reads
  the remote fine.
- Cross-session message holds bite BOTH directions: an INTERACTIVE session
  holds incoming messages behind an approval gate that expires — including
  worker→architect replies when the architect is interactive (burned M2T's
  kickoff and M2Q's reply). A worker cannot tell an interactive architect
  from a bg one via kickoff metadata, and a stale same-named session makes
  addressing a coin flip. Keep exactly one architect session alive; the
  BUILD-REPORT.md mirror is the working fallback; expect to relay by hand
  when the architect runs interactive.

(The machine currently runs with the sandbox DISABLED — those traps are
dormant, but honor the command shapes.)

## 8. The mutation table

Run every row on COMMITTED code from the worktree root (pwd quoted beside
each run), reds as NAMED TEST SETS never counts, revert clean, report the
WHOLE table greens included. Prefer constant shifts that cannot coincide
(D47).

| # | Mutation | Expected |
|---|---|---|
| 1 | `gatherSalt` constant changed | REDS the node-placement determinism pins; the layout-identity control stays GREEN (report both halves) |
| 2 | `_train`-grant deleted from the gather path | REDS the gather-training tests |
| 3 | node removal deleted (gathering never depletes) | REDS the depletion test |
| 4 | materials death-clear deleted | REDS the death test |
| 5 | `smeltCost` 2 → 1 | REDS the smelt pin |
| 6 | tier-gate clause deleted from `temperRefusal` | REDS gate refusals in core AND the widget reason test (both halves) |
| 7 | temper term deleted from the Item stat getters | REDS the temper stat tests and the worn-delta test |
| 8 | temper term deleted from `sellPriceOf` | REDS the temper price test |
| 9 | `maxTemper` ceiling check deleted | REDS the ceiling test |
| 10 | temper dropped from `stackKey` | REDS the stack-separation test |
| 11 | `materials` dropped from `encodeProfile` | REDS the round-trip and the town golden |
| 12 | `nodes` dropped from the floors codec | REDS the suspended-nodes round-trip |
| C1 | — all four band lines, final commit | GREEN AND BYTE-IDENTICAL to your baseline block |
| C2 | — designed-difficulty pin | GREEN |
| C3 | — crypt layout goldens + BOTH rng-state integer pins | GREEN |
| C4 | — merchant shelf characterization | GREEN |
| C5 | mutation 5 re-run against `survivability_test.dart` only | GREEN (the bot never smelts) — both halves of row 5 |

Sequencing traps: rows 1–12 mutate code this unit writes — run only after
it ships, on committed code. The v2 refusal fixture must be captured
BEFORE the goldens are rewritten (prove by commit order). Row 1's green
half is the unit's central claim — report it beside its red half.

## 9. What you must NOT do

- No pushing, no PR, no reviewers, no merging, no external trackers. The
  architect handles external writes on the user's per-round approval.
- No commits under `docs/epic/`; no edits outside your worktree.
- **No change to any drop table, any `Weighted` list, any spawn table, `marketTable, any bestiary stat, the hero's starting kit, either
  damage-formula copy, the survivability bot, the generator's existing
  draw order, `dungeonFor, or the crypt's frozen layout functions.** No
  new draw from `state.rng` or `state.lootRng` anywhere in this unit.
- No `pubspec.yaml` changes. No unseeded `Random()`.
- No device install without the copy-aside ritual (trap above).

## 10. Verification block (every item evidenced — name the command, quote
the output)

1. `cd <worktree> && pwd`; `git log --oneline main..m3-craft` (all commits
   on the branch, none on `main`).
2. Baseline proof: pre-change suite counts + all four band lines verbatim,
   measured fresh by YOU.
3. Final suite runs from each package dir: counts above 1570 with the
   delta and declaration cross-check; the four band lines from the FINAL
   commit, byte-identical to your baseline block.
4. `dart analyze .` from the worktree ROOT (pwd quoted); `dart format
   --set-exit-if-changed .` — both clean.
5. The full mutation table with named red sets and clean-revert proof;
   both halves of rows 1, 5, 6.
6. The v2-refusal test green with proof its fixture predates the golden
   rewrite; the v1 fixture test still green.
7. Suspend theorem extension quoted (nodes + materials roll-for-roll).
8. Goldens: old strings quoted beside new (commit message or report),
   with a structural old-vs-new diff (the M3M format: added/changed keys
   enumerated, nothing removed).
9. The reasoned trail for every tuned number.
10. AVD pass (mandatory): shots of a node on the floor, the Gather
    control, the Materials panel, the Forge (a temper with its gate
    reason), the Alchemist, all SEVEN town doors reachable, nine skill
    rows, greyscale copies of each; v2 save refusal proven on device;
    both save slots copied aside FIRST and SHA256-verified restored.
    Shots to `docs/reports/shots/`.
11. What the tests cannot prove, stated plainly (at minimum: gathering
    pace and temper economy are human-judged — no instrument exists;
    bottom floors and casting remain unmeasured).
12. Every spec claim you checked and found wrong, with the source.
13. Which execution phases ran and why any named phase was skipped — a
    skip is an argument, not an absence.

Mirror this block to `docs/reports/BUILD-REPORT.md` in your worktree AS
YOU FINISH IT, then message the architect (the kickoff sender) that you
are done.
