# Build prompt — M3L `m3-leave`: the suspend door

## 1. Worktree

`/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-leave`
on branch `m3-leave, base `f7bd6b1`. **Already created — do NOT create it.**

## 2. Working directory, first command

Your shell does not reliably inherit the intended directory. First command,
output confirmed before anything else:

```
cd /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-leave && pwd
```

Prefer git invocations from inside the worktree. The parent repository at
`/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg` must never
receive a commit from you. No sibling worktrees exist right now; if one
appears, leave it alone.

## 3. The spec

Read in full before any code:
`/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-leave-spec-M3L.md`

Background (read if a spec claim looks wrong):
`/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-leave-recon.md`

These live under `docs/epic/, which is LOCAL and gitignored. **Never commit
anything under `docs/epic/`.** Cite them by absolute path.

## 4. The work, in one paragraph

Make the suspend machinery reachable by play: the stairs `Leave` control
suspends the run instead of ending it (new core doors `suspendRun`/`resumeRun`
beside `startRun`/`endRun`), the hero lands in town with their own state
synced home, and the town's Enter Dungeon door forks while a camp exists —
Resume (roll-for-roll, no reshuffle, town purchases flow into the pack) or
Delve anew (confirmed abandon, fresh visit-bumped entry). The save document
gains a required per-hero `inside` field so boot can tell mid-crawl kills from
camped heroes, and the TownBloc landmine (transactions erasing the suspended
run from disk) is fixed and pinned by mutation. Baseline 829 tests stay green;
survivability stays EXACTLY 24/40 with the same histogram.

## 5. Attack the spec

Disagreeing in the open is expected behaviour, not a nuisance — build sessions
have corrected the architect in every recent unit, and the record shows them
right most times. The claims most worth attacking:

- The carry-set claim: the spec says `suspendRun` carries exactly what
  `endRun(died: false)` carries. Read `endRun`'s body — if the carry involves
  anything the spec's list misses (energy? the hero Actor itself?), the code
  is normative and the spec defers to it. Say what you found.
- The identity theorem's feasibility: `encodeRun(resumeRun(suspendRun(p, s), s))
  == encodeRun(s)` byte for byte. If any field genuinely cannot round-trip
  (e.g. the injection changes an ordering the codec pins), stop and message —
  that is a design hole, not a test to weaken.
- The invariant `profile.visit == suspended.visit` at resume. Check whether
  any reachable path violates it before you rely on it.
- The autosaver transition claim ("either value for at most one emission") —
  measure what your implementation actually writes during enter/leave and
  report it.
- The boot fork: make sure `run != null && !inside` cannot regress the
  app-kill-mid-crawl path (the existing boot-wiring widget test must stay
  meaningful, not deleted).

**Pre-declare every shape deviation before you write it** — message the
architect with the intended departure while changing course is still free.
An owned mismatch is a correction, not a breach.

## 6. Method

- A written plan first (`writing-plans`), then strict test-driven development
  (red → green → refactor) per unit of behavior. This wave has real logic; do
  not skip the plan.
- Characterization tests FIRST, and they must pass against the UNMODIFIED
  code (spec section "Characterization first"). If one fails at base, your
  understanding of current behavior is wrong: stop and report — do not work
  around it.
- Every commit's exit state is green. No reviewable unit is left red.
- Subagent policy (D9 precedent, argued openly every unit): no unattended
  write-capable subagents; execute inline; the mutation table carries the
  adversarial load. Read-only lookups are fine.
- Commits use the personal persona:, conventional-commit style.
- Test bodies structured `// arrange` / `// act` / `// assert`; no body
  comments in production code; dartdoc only on public API of core/content.

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

The spec's table (spec section "Mutation table") is binding: run EVERY row
against COMMITTED code — a checkout-revert once ate an uncommitted fix — and
report the whole table, greens included, naming which tests each mutation
reddened. Carry the sequencing traps: rows 5–6 run only after the reshape
commit; row 3 is a revert-the-fix mutation (observe the new test red before
the fix, then re-run the row post-commit); the format change and the golden
regeneration are ONE commit. Extend the table where the spec is blind —
extensions have caught real defects in four consecutive units; a weak row is
flagged, never hidden.

## 9. What you must NOT do

- No pushing, no pull request, no reviewer request, no merging, no review
  replies, no external trackers. The architect handles every external write,
  on the user's approval, per round.
- No changes to `bestiary.dart, `spawn_tables.dart, `drop_tables.dart, `armory.dart, `affix_pool.dart, economy numbers, or the hero's starting
  kit. No changes to floor generation, `floorSeed, or `buildFloor`'s draw
  order. No changes to `step.dart`'s combat/movement/monster phase — leaving
  is NOT a `GameAction`.
- Core diff confined to `town/run_boundary.dart` (plus exports if needed).
- No new dependencies. No save-version bump (sanctioned in-place v1 reshape;
  the first shipped build freezes v1 — restated per follow-up 20).
- No golden-literal edits via tooling (sed/re.sub corrupted one once) — by
  hand, from real encoder output.
- Never commit anything under `docs/epic/`. Never touch the physical phone.

## 10. Verification block — every item evidenced, not asserted

Report, with command output quoted for each:

1. `pwd` output proving the worktree, and `cd <worktree> && git log --oneline
   main..m3-leave` proving the commits are on the branch, not `main`.
2. Proof the characterization tests passed against UNMODIFIED code (run
   before your first change; quote counts).
3. All three suites in the worktree, counts vs the stated baseline
   (395 core + 212 content + 222 app = 829 — measured fresh by the architect
   on 2026-08-22, `main` @ `f7bd6b1`).
4. Survivability printed lines: must read EXACTLY
   `24/40 won (60.0%), stalled 0, died at 1:1 2:9 3:6 5:24` and
   `greedy build: 24/40 won; fleetfoot-first build: 7/40 won`.
5. `flutter analyze` clean; `dart format --set-exit-if-changed .` clean,
   project-wide.
6. The FULL mutation table, both halves, per row: mutation applied (the sed),
   tests reddened by name, controls green by name, revert clean.
7. `cd <worktree> && git diff main -- packages/core/lib` showing only
   `town/run_boundary.dart` (+ `core.dart` exports);
   `git diff main -- packages/content/lib` confined to `src/save/`;
   no pubspec changes (`git diff main -- '**/pubspec.yaml'` empty).
   Test additions are free anywhere their package's conventions put them.
8. Hygiene greps: no body comments in changed production files, no unseeded
   `Random(, arrange/act/assert in new tests.
9. AVD acceptance on `Pixel_10` via `-s emulator-5554, platform buttons
   included, per the spec's definition of done (leave/shop/resume;
   app-kill camped → town with camp; app-kill mid-crawl → crawl; death
   clears camp; delve-anew confirm; greyscale reading of changed screens).
   Screenshots pulled and listed.
10. **What the tests cannot prove**, stated plainly.
11. **Every spec claim you checked and found wrong**, with the source line.
12. Which execution phases ran, and an argument for any skipped one — a
    silent skip is the one disagreement the method does not allow.

Every identifier in the report (hashes, counts, filenames) is PASTED from
command output, never typed from memory.

## 11. Reporting back

- **Printing is not replying.** Your ordinary output is invisible to other
  sessions. When you are done, blocked, or a spec claim looks wrong, use the
  cross-session message tool (SendMessage) addressed to **the sender of your
  kickoff message** — reply to that session, not to any similarly-named one.
- Message the architect when: a spec claim looks wrong; an inherited gate is
  not real; you are blocked on a decision the spec does not cover; you want
  to pre-declare a shape deviation. Otherwise decide, proceed, and report at
  the end.
- **Mirror the full verification block to `BUILD-REPORT.md` in your worktree
  regardless of messaging** — the channel has failed before; the file is the
  fallback the architect reads off disk.
