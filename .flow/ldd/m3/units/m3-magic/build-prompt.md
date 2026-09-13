# Build prompt — M3M `m3-magic`

You are the build session for M3M on branch `m3-magic`. You write all the
production code for this unit. The architect (the session that sent you the
kickoff message) decides, answers, and verifies — reply to THE SENDER of
your kickoff message with the message tool. **Printing to your own
transcript reaches nobody**: a reply is a message-tool send, not output.

## 1. Worktree

`/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-magic`
— **already created on branch `m3-magic` @ `936ca5b` — do NOT create it.**

## 2. Working directory — first command, before anything

```
cd /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-magic && pwd
```

Confirm the output. Every git command thereafter as
`cd <worktree> && git <cmd>`. The parent repository at
`/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg` is NOT yours —
a commit landing there is a real failure mode. No sibling worktrees exist
today; if one appears, do not touch it.

## 3. The spec

Read in full, before any code:
`/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-magic-spec-M3M.md`

Background (read when a spec claim looks wrong):
`/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-magic-recon.md`

Both live in a gitignored planning directory. **Never commit anything under
`docs/epic/`.** Your written plan goes to `docs/plans/` (tracked); your
report mirror and tuning trail go to `docs/reports/` (gitignored).

## 4. The work, in one paragraph

Add magic to Residuum: three new school skills (Wrath, Mending, Binding —
appended to `SkillId` after `fleetfoot`), spell books as consumable items
that teach a spell permanently when read (gated by school level), six first
spells cast in the crawl (Firebolt, Frost Lance, Mend, Ward, Bind, Banish)
spending a hero-only per-floor mana pool, with fire/frost damage types that
creature resistances and vulnerabilities modify. Melee is untouched: **the
measurable effect is that all four survivability band lines return
byte-identical while a hero with books and mana can fight a fundamentally
different way.** Save format bumps to version 2; every pre-M3M save is
refused by design.

## 5. Be adversarial about the spec

Spec defects are expected findings, not nuisances — disagree in the open.
The architect's premises most worth attacking:

- **The band-identity claim (control C1).** The architect argues no
  non-casting path gains or loses an RNG draw, so all four lines hold. If
  your implementation cannot honor that, the defect may be the spec's — say
  so with the draw-site named, before restructuring.
- **The arithmetic**: `heroMaxMana = 4 + (schools summed) ~/ 2, spell
  numbers in contract 3, the book price term (`10 + requiredLevel`). Two
  architect arithmetic errors were caught in M3B alone; check them against
  play math before pinning.
- **The enum-append claim** (golden JSON key order stays stable when the
  three cases append after `fleetfoot`) — verify against the actual golden
  before rewriting it.
- **The glyph `?`** for books — run the collision test before adopting.
- **The targeting rule's determinism** (Chebyshev + `byRowThenColumn`
  tie-break) — if the primitives don't support it cleanly, propose better.
- The resistance starting trail in contract 13 is a proposal — tune with a
  measured trail; the CONTRACT is exclusivity (resist and vulnerable
  disjoint) and that only resistance fields move in the bestiary, never
  hp/attack/pierce/speed/dropChance.

**Pre-declare every shape deviation BEFORE building it** — message the
architect with the intended departure and wait for the answer (answers come
fast; a blocked question beats a rebuilt wrong shape). Blockers and any
tuning-stop condition: stop and message, with your measurements.

## 6. Method

Full workflow, no shortcuts: written plan first (writing-plans) to
`docs/plans/2026-08-24-m3-magic.md, then subagent-driven or direct
execution with strict test-driven development (red → green → refactor per
behavior), verification-before-completion at the end. This unit is L — the
plan document is required.

**Characterization first.** Before any change: re-run all three suites from
their package directories and quote the four band lines verbatim from YOUR
run as the baseline block of your report (expected: 537 core + 418 content +
406 app = 1361; crypt `20/40 won (50.0%), stalled 0, died at 1:1 2:9 3:4
4:6 5:20`; `greedy build: 20/40 won; fleetfoot-first build: 14/40 won`;
sea-cave `31/40 won (77.5%), stalled 0, died at 2:1 3:7 4:13 5:10 6:9`;
ruined keep `28/40 won (70.0%), stalled 0, died at 1:4 2:6 3:1 4:1 5:13
6:9 7:6`). If your baseline differs, STOP and message the architect.
Capture the version-1 golden fixture string BEFORE any codec change (the
spec's sequencing trap). Every commit exits green — no reviewable unit is
left red. Test bodies: `// arrange` / `// act` / `// assert`. Commits:
conventional, authored.

Numbers you tune (spell damage/cost/gates, book weights and price term,
resistance assignments) get a MEASURED TRAIL in
`docs/reports/TUNING-TRAIL.md`: every delta re-measured on all four band
lines (they must not move — that is the point), failed configurations kept
as proof. M3B's twenty-step trail is the format.

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
- Cross-session message holds bite BOTH directions: an INTERACTIVE session
  holds incoming messages behind an approval gate that expires — including
  worker→architect replies when the architect is interactive (burned M2T's
  kickoff and M2Q's reply). A worker cannot tell an interactive architect
  from a bg one via kickoff metadata, and a stale same-named session makes
  addressing a coin flip. Keep exactly one architect session alive; the
  BUILD-REPORT.md mirror is the working fallback; expect to relay by hand
  when the architect runs interactive.

(Note: the machine currently runs with the sandbox DISABLED — the sandbox
traps are dormant, but honor the command shapes anyway.)

## 8. The mutation table

Run every row on COMMITTED code from the worktree root (pwd quoted beside
each run), report reds as NAMED TEST SETS never counts, revert clean, and
report the WHOLE table, greens included. Prefer constant shifts that cannot
coincide with fixture values (D47).

| # | Mutation | Expected |
|---|---|---|
| 1 | `firebolt` min/max +2 in `spells.dart` | REDS the spell content pin and the bolt damage test |
| 2 | resistance halving branch deleted in the bolt path | REDS the resist test |
| 3 | vulnerability doubling deleted | REDS the vulnerability test |
| 4 | mana decrement deleted (casting is free) | REDS the mana-spend test |
| 5 | `requiredLevel` clause deleted from `readRefusal` | REDS the locked-book refusals, dungeon AND town (report both halves) |
| 6 | `_train` call on cast deleted | REDS the school-training test |
| 7 | ward absorb deleted from `_defend` | REDS the ward tests |
| 8 | bound decrement deleted | REDS the bind-expiry test |
| 9 | targeting takes the FARTHEST visible enemy | REDS the targeting + tie-break tests |
| 10 | `knownSpells` dropped from `encodeProfile` | REDS the profile round-trip and the town golden |
| 11 | Common-forcing reverted to `isPotion` | REDS the book-rarity unit test on `rollDrop` |
| 12 | book term deleted from `sellPriceOf` | REDS the book-price test |
| C1 | — (no mutation) all four band lines re-run on the final commit | GREEN AND BYTE-IDENTICAL to your baseline block |
| C2 | — designed-difficulty pin re-run | GREEN (melee formula untouched) |
| C3 | — crypt floor characterization goldens | GREEN (generator untouched) |
| C4 | mutation 4 re-run against the CONTENT suite only | GREEN there (the bands never cast) — report both halves of row 4 |

Sequencing traps: rows 1–12 mutate code this unit writes — run them only
after the behavior ships, on committed code. The v1 golden fixture for the
version-refusal test must be captured BEFORE the goldens are rewritten.

## 9. What you must NOT do

- No pushing. No opening a pull request. No requesting reviewers. No
  merging. No replying to review threads. No external trackers. The
  architect handles every external write on the user's per-round approval.
- No commits under `docs/epic/`. No edits to the parent repository or any
  sibling worktree.
- No creature hp/attack/pierce/speed/dropChance changes; no hero starting
  kit or fresh-hero stat changes; no melee formula changes (either copy);
  no bot policy changes; no generator/floor-layout changes; no changes to
  the crypt's frozen files (`floorSeed, `generateFloor, `newGame`'s
  layout path, `buildFloor, `residuumDungeon, `dungeonFor`'s early
  return). Resistance/vulnerability fields and the new spell/book content
  are your only bestiary/table openings, each with a trail.
- No `pubspec.yaml` dependency changes. No unseeded `Random()` anywhere.
- Do not touch the device's save slots without the copy-aside ritual
  (trap above).

## 10. Verification block (every item evidenced — name the command and
quote its output)

1. `cd <worktree> && pwd` output, and `git log --oneline main..m3-magic`
   showing every commit on the branch, none on `main`.
2. Baseline proof: the pre-change suite runs (counts + all four band lines
   verbatim) — stated as measured fresh by YOU, not carried forward.
3. Final suite runs from each package directory: counts (must exceed 1361;
   state the delta and the declaration count), and the four band lines
   from the FINAL commit, byte-identical to your baseline block.
4. `dart analyze .` from the worktree ROOT with pwd quoted; `dart format
   --set-exit-if-changed .` — both clean.
5. The full mutation table with named red sets and clean-revert proof;
   both halves of rows 4/5.
6. The v1-refusal test green, with proof its fixture predates the golden
   rewrite (commit order or file history).
7. Suspend theorem extension: the mid-run suspend with mana spent, ward
   up, monster bound — resume roll-for-roll, quoted.
8. Goldens: the OLD golden strings quoted beside the new (same commit or
   report).
9. The tuning trail: every configuration tried, measured on all four
   lines, failures kept.
10. AVD pass (mandatory — six device-only catches to date): shots of the
    Spells section, a locked book's reason row, the mana readout, a cast
    beat in the log, a bind/banish beat, plus greyscale copies; v1 save
    refusal proven on device ("a new hero begins"); both device save
    slots copied aside first and SHA256-verified restored. Shots to
    `docs/reports/shots/`.
11. What the tests cannot prove, stated plainly (at minimum: no band
    measures a casting hero — spell balance is human-judged; bottom
    floors remain unmeasured, follow-up 28).
12. Every spec claim you checked and found wrong, with the source.
13. Which execution phases ran (plan → TDD → verification) and why any
    named phase was skipped — a skip is an argument, not an absence.

Mirror this block to `docs/reports/BUILD-REPORT.md` in your worktree AS YOU
FINISH IT (the channel can fail; the file is the designed fallback), then
message the architect (the kickoff sender) that you are done.
