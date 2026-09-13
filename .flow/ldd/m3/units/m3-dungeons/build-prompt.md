# Build prompt — M3D `m3-dungeons`: the sea-cave and the ruined keep

## 1. Worktree

`/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-dungeons`
on branch `m3-dungeons, base `bdb190b`. **Already created — do NOT create it.**

## 2. Working directory, first command

Your shell does not reliably inherit the intended directory. First command,
output confirmed before anything else:

```
cd /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-dungeons && pwd
```

The parent repository at
`/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg` must never
receive a commit from you. No sibling worktrees exist right now; if one
appears, leave it alone.

## 3. The spec

Read in full before any code:
`/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-dungeons-spec-M3D.md`

Background (read if a spec claim looks wrong):
`/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-dungeons-recon.md`

These live under `docs/epic/, which is LOCAL and gitignored. **Never commit
anything under `docs/epic/`.** Cite them by absolute path. Your written plan
goes in `docs/plans/` (worktree-relative, tracked); your report mirror goes
to `docs/reports/BUILD-REPORT.md` (worktree-relative, gitignored).

## 4. The work, in one paragraph

Make the sea-cave and the ruined keep real: two new dungeon nodes on the
world map (routes off Northgate, both rumor-hidden), each with its own
bestiary, spawn and drop tables, its own floor stream via a per-node salt
(`worldSeed ^ dungeonSalt(node)`), a named bottom-floor boss placed (never
rolled) guarding one guaranteed rare-or-better trophy, a per-theme palette
as additional signal, and a survivability band run with a mid-progression
fixture kit. A run knows which dungeon it is in: a REQUIRED hero-level
`dungeon` save field (v1 reshape, goldens by hand), events carry the node,
the world screen offers Resume only at the camp's own node and asks before
abandoning a camp elsewhere. The crypt's floors, tables, and figures stay
byte-identical — and the exact `24/40` plus histogram get PROMOTED from a
printed line into code assertions. Core `lib/` diff: EMPTY.

## 5. Attack the spec

Disagreeing in the open is expected behaviour — workers have corrected
architect claims in every recent unit. The claims most worth attacking here:

- **Ruling 1 (hero-level identity).** The spec claims `encodeRun` takes only
  a `GameState` and that hero-level is therefore the honest home. If you
  find the autosaver or resume path cannot carry the field without a race,
  or the run block turns out the better home, pre-declare before code.
- **Contract 3's equivalence claim.** `startDungeonRunAt(cryptNode, p)` must
  be byte-identical to today's `startDungeonRun(p)` — check every argument
  (`dropTables, `lootSeedSalt`) against the current call before you trust
  the pin to say so.
- **The trophy's no-reshuffle claim.** "One extra item spawn cannot move the
  layout or the monsters" leans on `generator.dart:100-102`. Prove it holds
  on the themed path (the two-generators-from-one-seed split), or say it
  does not.
- **The world-screen wiring sketch.** The spec says the fork lives on the
  world screen and the node is in hand at `world_screen.dart:302` — but
  check what state the doors actually read (TownBloc? WorldBloc? boot) and
  whether the camp's dungeon is visible there without a new seam. If the
  spec's sketch is wrong, yours is the correction.
- **The fixture kit's reachability.** Ruling 6 assumes a mid-progression
  profile can be built through existing seams (equipment, skills at level 5)
  and fed to `startDungeonRunAt`. If Profile construction refuses any part
  of it, pre-declare the seam you need.
- **The band arithmetic.** If a first measurement lands outside 0.50–0.95,
  that is a table-tuning loop (new-dungeon tables are free with a trail),
  not a spec failure — but the trail must show every tuning step and its
  re-measurement.

**Pre-declare every shape deviation before you write it.** An owned mismatch
is a correction, not a breach.

## 6. Method

- A written plan first (`writing-plans, into `docs/plans/`), then strict
  test-driven development (red → green → refactor) per unit of behavior.
- Characterization tests FIRST (the spec's list, including the
  `startDungeonRun` crypt pin), passing against the UNMODIFIED code; a base
  failure is a stop-and-report.
- Every commit's exit state is green. The save reshape and its hand-edited
  goldens land in ONE commit.
- Subagent policy (D9 precedent, argued openly): no unattended
  write-capable subagents; execute inline; the mutation table carries the
  adversarial load. Read-only lookups are fine.
- Commits:, conventional style.
- Test bodies `// arrange` / `// act` / `// assert`; no body comments in
  production code; dartdoc only on public API of core/content; ubiquitous
  language — the spec's words exactly (`temper, `affix, `rumor, `residue`; the new nouns are `sea-cave, `ruined keep, `trophy, `boss`).

## 7. Environment traps (verbatim from the ledger — every one has burned a session)

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
- Cross-session message holds bite BOTH directions: an INTERACTIVE session
  holds incoming messages behind an approval gate that expires — including
  worker→architect replies when the architect is interactive (burned M2T's
  kickoff and M2Q's reply). A worker cannot tell an interactive architect
  from a bg one via kickoff metadata, and a stale same-named session makes
  addressing a coin flip. Keep exactly one architect session alive; the
  report mirror is the working fallback; expect to relay by hand when the
  architect runs interactive.
- (Note: the machine-wide sandbox is currently DISABLED — the sandbox-shaped
  traps above are dormant, but keep the habits; re-enabling is one boolean.)

## 8. The mutation table

The spec's 12-row table (rows 1–10 plus greens G1–G2) is binding: run EVERY
row against COMMITTED code with your own sed, and report the whole table,
greens included, naming which tests each mutation reddened. Row 2's core
goldens staying green is a truthful weak half — report it as the finding it
is. Row 10 is a sequencing trap: it reddens nothing before the promotion
commit exists; run it after, and say so. G1/G2 require reverting the tune
after measuring. Extend the table where the spec is blind — extensions have
caught real defects in six consecutive units.

## 9. What you must NOT do

- No pushing, no pull request, no reviewer request, no merging, no review
  replies, no external trackers. The architect handles every external
  write, on the user's approval, per round.
- **No core `lib/` change of any kind.** If a step seems to need one, stop
  and pre-declare — do not build it.
- No edit to `generator.dart, `step.dart, `economy.dart, the crypt
  bestiary, `spawn_tables.dart, or `drop_tables.dart`. In `new_game.dart`
  exactly one change — the deletion of `startDungeonRun`; `buildFloor, `newGame, `residuumDungeon, `lootStreamSalt` stay byte-untouched.
- The crypt bot stays `newGame` at visit 0. No draw-order change anywhere on
  the crypt's path.
- No save-version bump (sanctioned in-place v1 reshape; the first shipped
  build freezes v1 — follow-up 20 restated). No golden-literal edits via
  tooling — by hand, from real encoder output.
- No hue-only distinction anywhere (deuteranomalous author; greyscale must
  read). No new dependencies. No unseeded `Random()`. No body comments.
- Never commit anything under `docs/epic/` or `docs/reports/`. Never touch
  a physical phone.

## 10. Verification block — every item evidenced, not asserted

Report, with command output quoted for each:

1. `pwd` proving the worktree; `git log --oneline main..m3-dungeons`
   proving the commits are on the branch.
2. Proof the characterization net passed against UNMODIFIED code (run
   before your first change; quote counts), including the
   `startDungeonRun` crypt pin that outlives the door.
3. All three suites in the worktree vs the baseline (515 core + 300
   content + 338 app = **1153** — measured fresh by the architect
   2026-08-22 on `main` @ `bdb190b`). Nothing deleted or weakened except
   what the spec names (the orphan-test generalization).
4. Survivability, three parts: the crypt's printed line EXACTLY
   `24/40 won (60.0%), stalled 0, died at 1:1 2:9 3:6 5:24` and
   `greedy build: 24/40 won; fleetfoot-first build: 7/40 won`; the
   PROMOTED assertions quoted from the test source; the two new bands'
   printed lines with their measured figures and the tuning trail if any.
5. `flutter analyze` clean; `dart format --set-exit-if-changed .` clean,
   project-wide.
6. The FULL mutation table, both halves per row, extensions included.
7. Diff scope: `git diff main -- packages/core/lib` EMPTY;
   `git diff main --name-only` over the section-9 forbidden files empty;
   the `new_game.dart` diff shown to be the one deletion; no pubspec
   change. Test additions free.
8. Hygiene greps: no body comments in changed production files, no
   unseeded `Random(, arrange/act/assert in new tests, no synonym for the
   spec's nouns, new glyphs absent from the taken set (`r w g s W, tiles, `@, item glyphs).
9. Golden saves: the three regenerated documents shown hand-edited (diff
   quoted), the refusal rows named, a camp round-trip in EACH new dungeon
   proven roll-for-roll.
10. AVD acceptance on `Pixel_10` via `-s emulator-5554, platform buttons
    included, covering the spec's definition-of-done list in full: rumor →
    travel → enter sea-cave → boss floor → trophy → camp → walk home →
    resume from the world screen; the abandon-elsewhere confirmation
    exercised; the ruined keep entered; screenshots pulled and listed,
    greyscale shots proving palettes and glyphs read without hue.
11. **What the tests cannot prove**, stated plainly (the bands' meaning for
    real play is one; say the rest).
12. **Every spec claim you checked and found wrong**, with the source.
13. Which execution phases ran, and an argument for any skipped one.

Every identifier PASTED, never typed.

## 11. Reporting back

- **Printing is not replying.** Your ordinary output is invisible to other
  sessions. Use SendMessage addressed to **the sender of your kickoff
  message**. Message when: a spec claim looks wrong; an inherited gate is
  not real; you are blocked on a decision the spec does not cover; you
  pre-declare a deviation. Otherwise decide, proceed, and report at the end.
- **Mirror the full verification block to `docs/reports/BUILD-REPORT.md` in
  your worktree regardless of messaging** (gitignored; the architect reads
  it off disk if the channel fails).
