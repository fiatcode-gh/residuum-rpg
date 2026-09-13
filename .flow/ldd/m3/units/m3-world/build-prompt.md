# Build prompt — M3W `m3-world`: the overworld

## 1. Worktree

`/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-world`
on branch `m3-world, base `844376f`. **Already created — do NOT create it.**

## 2. Working directory, first command

Your shell does not reliably inherit the intended directory. First command,
output confirmed before anything else:

```
cd /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-world && pwd
```

The parent repository at
`/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg` must never
receive a commit from you. No sibling worktrees exist right now; if one
appears, leave it alone.

## 3. The spec

Read in full before any code:
`/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-world-spec-M3W.md`

Background (read if a spec claim looks wrong):
`/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-leave-recon.md`
— findings 5–9 are this unit's recon; the rest is context.

These live under `docs/epic/, which is LOCAL and gitignored. **Never commit
anything under `docs/epic/`.** Cite them by absolute path.

## 4. The work, in one paragraph

Build the overworld: a node map (two towns + the crypt) in a new core
`world/` feature with content-owned numbers, travel in days with a
deterministic per-day encounter roll (seeded from `worldSeed ^ travelSalt`
and the day — no new persistent stream), road encounters on a NEW small
open-map generator with flee-by-stepping-off-any-edge, discovery (arrival
reveals adjacency; tavern rumors bought with gold reveal hidden places),
per-town merchant shelves with the D36 validity rule extended to (visit AND
town), a required per-hero `world` save block, and the navigation rework
that puts the world screen at the navigator's bottom — the M3L leave landing
and the resume/delve-anew fork move to the crypt node. Baseline 897 stays
green; crypt survivability stays EXACTLY 24/40 with the identical histogram.

## 5. Attack the spec

Disagreeing in the open is expected behaviour — the record shows the worker
right most times, and last unit corrected four architect claims. The claims
most worth attacking here:

- **The navigation rework's blast radius.** The spec claims the world screen
  can become the stack bottom while the crawl's one-pop-home shape survives.
  Count the real pushes and pops before you believe it; if the town-under-
  crawl assumption is load-bearing somewhere the spec missed (bloc
  provision, the death overlay's pop target, the roster's return), say so
  before code.
- **Profile custody.** The spec requires it single-homed but does not pick
  the home. Pick one, argue it, pre-declare it.
- **The flee rule's reachability claim** — "inert in crawls because the
  border is solid wall." Verify no crawl map can put a walkable tile on the
  grid edge (generated AND the encounter generator's own outputs), or the
  weak row is not weak.
- **The C3 re-pin** — the starting town's shelf changes when the town salt
  lands. If any existing test pins today's shelf indirectly (autosaver
  fixtures, widget fixtures), find them BEFORE the salt commit.
- **The travel-seed derivation** — check that `(worldSeed ^ travelSalt, day)`
  through the floorSeed-style mix cannot collide with dungeon floor seeds in
  a way that correlates floors with road encounters (it should not matter;
  prove it does not, or flag it).

**Pre-declare every shape deviation before you write it.** An owned mismatch
is a correction, not a breach.

## 6. Method

- A written plan first (`writing-plans`), then strict test-driven
  development (red → green → refactor) per unit of behavior.
- Characterization tests FIRST (spec: C1–C3), passing against the
  UNMODIFIED code; a base failure is a stop-and-report.
- Every commit's exit state is green.
- Subagent policy (D9 precedent, argued openly): no unattended
  write-capable subagents; execute inline; the mutation table carries the
  adversarial load. Read-only lookups are fine.
- Commits:, conventional style.
- Test bodies `// arrange` / `// act` / `// assert`; no body comments in
  production code; dartdoc only on public API of core/content; ubiquitous
  language — the spec's words exactly (`rumor, never a synonym).

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
  BUILD-REPORT.md mirror is the working fallback; expect to relay by hand
  when the architect runs interactive.
- (Note: the machine-wide sandbox is currently DISABLED — the sandbox-shaped
  traps above are dormant, but keep the habits; re-enabling is one boolean.)

## 8. The mutation table

The spec's 12-row table is binding: run EVERY row against COMMITTED code and
report the whole table, greens included, naming which tests each mutation
reddened. Row 5 is declared a truthful weak row — run it anyway and report
what stayed green; that green IS the finding. Carry the sequencing traps
(rows 11–12 post-reshape; C3's two-step re-pin; row 4 depends on C1).
Extend the table where the spec is blind — extensions have caught real
defects in five consecutive units.

## 9. What you must NOT do

- No pushing, no pull request, no reviewer request, no merging, no review
  replies, no external trackers. The architect handles every external
  write, on the user's approval, per round.
- No edits to the crypt's spawn/drop tables, bestiary stats, armory,
  affixes, economy numbers (the inn price, existing prices), the hero's
  starting kit, `floorSeed, `generateFloor, or `buildFloor`'s draw order.
  New content lands in NEW tables and NEW functions beside them.
- `step.dart` gains the flee rule and nothing else.
- No new dependencies. No save-version bump (sanctioned in-place v1
  reshape; the first shipped build freezes v1 — follow-up 20 restated).
- No golden-literal edits via tooling — by hand, from real encoder output.
- Never commit anything under `docs/epic/`. Never touch a physical phone.

## 10. Verification block — every item evidenced, not asserted

Report, with command output quoted for each:

1. `pwd` proving the worktree; `git log --oneline main..m3-world` proving
   the commits are on the branch.
2. Proof C1–C3 passed against UNMODIFIED code (run before your first
   change; quote counts), and C3's re-pin argued in its commit.
3. All three suites in the worktree vs the baseline (408 core + 225
   content + 264 app = 897 — measured fresh by the architect 2026-08-22 on
   `main` @ `844376f`).
4. Survivability printed lines EXACTLY:
   `24/40 won (60.0%), stalled 0, died at 1:1 2:9 3:6 5:24` and
   `greedy build: 24/40 won; fleetfoot-first build: 7/40 won`.
5. `flutter analyze` clean; `dart format --set-exit-if-changed .` clean,
   project-wide.
6. The FULL mutation table, both halves per row, extensions included.
7. Diff scope: `git diff main -- packages/core/lib` confined to `world/, `dungeon/encounter_map.dart` (or your pre-declared name), the flee rule
   in `engine/` (`step.dart, `event.dart, `game_state.dart`), and
   `core.dart` exports; `git diff main --name-only` over the forbidden
   files in section 9 EMPTY; no pubspec change. Test additions free.
8. Hygiene greps: no body comments in changed production files, no
   unseeded `Random(, arrange/act/assert in new tests, no synonym for
   `rumor`.
9. AVD acceptance on `Pixel_10` via `-s emulator-5554, platform buttons
   included, covering the spec's definition of done list in full;
   screenshots pulled and listed (greyscale shots included).
10. **What the tests cannot prove**, stated plainly.
11. **Every spec claim you checked and found wrong**, with the source.
12. Which execution phases ran, and an argument for any skipped one.

Every identifier PASTED, never typed.

## 11. Reporting back

- **Printing is not replying.** Use SendMessage addressed to **the sender
  of your kickoff message**. Message when: a spec claim looks wrong; an
  inherited gate is not real; you are blocked on a decision the spec does
  not cover; you pre-declare a deviation. Otherwise decide, proceed, and
  report at the end.
- **Mirror the full verification block to `BUILD-REPORT.md` in your
  worktree regardless of messaging.**
