# Build prompt — M3X `m3-depth`: randomized depth per delve

## 1. Worktree

`/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-depth`
on branch `m3-depth, base `59b91f1`. **Already created — do NOT create it.**

## 2. Working directory, first command

Your shell does not reliably inherit the intended directory. First command,
output confirmed before anything else:

```
cd /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-depth && pwd
```

The parent repository at
`/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg` must never
receive a commit from you. No sibling worktrees exist right now; if one
appears, leave it alone.

## 3. The spec

Read in full before any code:
`/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-depth-spec-M3X.md`

Background (read if a spec claim looks wrong):
`/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-depth-recon.md`

These live under `docs/epic/, which is LOCAL and gitignored. **Never commit
anything under `docs/epic/`.** Cite them by absolute path. Your written plan
goes in `docs/plans/` (worktree-relative, tracked); your report mirror goes
to `docs/reports/BUILD-REPORT.md` (worktree-relative, gitignored).

## 4. The work, in one paragraph

Make a delve's depth part of its roll: the sea-cave lays out 4–6 floors and
the ruined keep 5–7, uniform, deterministic per (world, dungeon, visit) via
`delveDepth` (a purpose-slot mix over `worldSeed ^ dungeonSalt(node)`), and
recomputable on load — NOTHING new is written to disk. Core widens by one
optional parameter (`generateFloor`/validator/`FloorProblem` gain
`deepest, defaulting to today's constant) and one optional-with-default
`GameState.deepest`; the HUD shows the rolled total ("The Sea-Cave — depth
3/6"); the boss and trophy land on the rolled bottom and ONLY there; the
bot's win condition reads the run's own deepest. Both themed bands re-pin
by design; the crypt — its path, its goldens, its printed line, and its
promoted assertions — stays character-identical.

## 5. Attack the spec

Disagreeing in the open is expected behaviour — workers have corrected
architect claims in every unit of this epic. The claims most worth
attacking here:

- **The derived-roll purity.** The spec claims `delveDepth` can ride
  `floorSeed`'s mix in a new purpose slot without colliding with the
  ground/fight/market slots or any floor stream. Prove disjointness the
  way `world_test.dart` does, or flag the collision.
- **"Defaults reproduce today's behavior byte-for-byte."** Check every
  existing `generateFloor` caller and the validator's default path against
  the characterization goldens BEFORE trusting the claim — if any caller
  must change its call shape, pre-declare.
- **The resumeRun carry.** The spec says `resumeRun` carries `deepest`
  from the suspended state. Read `run_boundary.dart:171` — it is built
  field-by-field because copyWith has no gold slot; a missed field there
  is silent. Say which fields you touch.
- **The bot threading.** `_Outcome.won` reading the opening state's
  deepest must not change the CRYPT's measured outcomes at all — if the
  crypt's histogram moves by even one key, stop; that is the identity
  guard firing.
- **The uniform roll's modulo.** `mix % span` over a 30-bit hash — check
  the distribution is actually uniform enough over 40 visits per dungeon
  that the range-bounds and variance tests are stable, and that visit
  ranges the game reaches (1..thousands) hit all three values.

**Pre-declare every shape deviation before you write it.** An owned
mismatch is a correction, not a breach.

## 6. Method

- A written plan first (`writing-plans, into `docs/plans/`), then strict
  test-driven development (red → green → refactor) per unit of behavior.
- Characterization net FIRST (the crypt goldens, promoted assertions, M3D
  themed pins), passing against UNMODIFIED code; a base failure is a
  stop-and-report. The two themed bottom-floor goldens re-pin BY HAND when
  the roll lands, old pin quoted in the commit message.
- Every commit's exit state is green.
- Subagent policy (D9): no unattended write-capable subagents; execute
  inline; the mutation table carries the adversarial load. Read-only
  lookups fine.
- Commits:, conventional style.
- Test bodies `// arrange` / `// act` / `// assert`; no body comments in
  production code; dartdoc only on public API of core/content; ubiquitous
  language — `delve, `deepest, the spec's words exactly.

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
  worker→architect replies when the architect is interactive. Keep exactly
  one architect session alive; the report mirror is the working fallback.
- (Note: the machine-wide sandbox is currently DISABLED — the sandbox-shaped
  traps above are dormant, but keep the habits; re-enabling is one boolean.)
- NEW since D44: `dart analyze .` runs from the WORKTREE ROOT — a
  package-directory run does not reach sibling packages' test dirs. Quote
  the `pwd` beside the analyze output. Mutation reds are reported as a
  NAMED SET of tests, never a bare count.

## 8. The mutation table

The spec's 10-row table (rows 1–8 plus greens G1–G2) is binding: run EVERY
row against COMMITTED code with your own sed and report the whole table,
greens included, naming the reddened tests as a set. G1 is the
truthful-weak proof that the default IS 5 — report the green as the
finding. Carry the sequencing traps (rows 1–2 after the roll lands; row 3
needs a keep table at 7; G2 reverts after measuring). Extend the table
where the spec is blind — extensions have caught real defects in seven
consecutive units.

## 9. What you must NOT do

- No pushing, no pull request, no reviewer request, no merging, no review
  replies, no external trackers. The architect handles every external
  write, on the user's approval, per round.
- Core edits are confined to the three sanctioned files (generator.dart,
  game_state.dart, run_boundary.dart). Anything else in core is a
  stop-and-pre-declare.
- No edit to `newGame, `buildFloor, `residuumDungeon, `step.dart, `economy.dart, `bestiary.dart, `spawn_tables.dart, `drop_tables.dart`.
- No save key, no golden-save change, no version bump. The crypt's
  survivability printed line and assertions are character-frozen.
- No hue-only signal; no tooling on golden literals; no unseeded
  `Random()`; no body comments. Never commit anything under `docs/epic/`
  or `docs/reports/`. Never touch a physical phone.

## 10. Verification block — every item evidenced, not asserted

Report, with command output quoted for each:

1. `pwd` proving the worktree; `git log --oneline main..m3-depth` proving
   the commits are on the branch.
2. Proof the characterization net passed against UNMODIFIED code (quote
   counts and the four survivability lines before your first change).
3. All three suites vs the baseline (515 + 380 + 364 = **1259**, measured
   fresh by the architect 2026-08-24 on `main` @ `59b91f1`). Deletions
   only where the spec names re-pins; run the declaration-count
   cross-check (grep `test(`/`testWidgets(`/`blocTest<` declarations) as
   the second instrument on "nothing removed".
4. Survivability: the crypt's printed line and assertions
   CHARACTER-IDENTICAL to baseline (quote both); the new themed lines
   with wins + histograms + the ordering assertion; the roll's visit
   coverage (which visits hit which depths in the band runs).
5. `dart analyze .` from the WORKTREE ROOT with the `pwd` quoted; `dart
   format --set-exit-if-changed .` clean project-wide.
6. The FULL mutation table, both halves per row, reds as named sets,
   extensions included.
7. Diff scope: `git diff main --name-only -- packages/core/lib` shows
   exactly the three sanctioned files; the section-9 must-not list empty;
   golden saves byte-identical (quote the encode assertion run); no
   pubspec change.
8. Hygiene greps: no body comments in changed production files, no
   unseeded `Random(, arrange/act/assert in new tests, `delve`/`deepest`
   used exactly (no synonyms).
9. The two themed bottom-floor re-pins: old and new literals quoted in
   the commit message, edited by hand from real output.
10. AVD acceptance on `Pixel_10` via `-s emulator-5554`: enter the
    sea-cave on a visit whose roll ≠ 5 (paste the derivation), HUD shows
    the rolled total, walk a deep keep floor, camp in a 6-deep delve,
    kill the app, resume, same bottom; greyscale HUD shot; platform back
    button used.
11. **What the tests cannot prove**, stated plainly.
12. **Every spec claim you checked and found wrong**, with the source.
13. Which execution phases ran, and an argument for any skipped one.

Every identifier PASTED, never typed.

## 11. Reporting back

- **Printing is not replying.** Your ordinary output is invisible to other
  sessions. Use SendMessage addressed to **the sender of your kickoff
  message**. Message when: a spec claim looks wrong; an inherited gate is
  not real; you are blocked on a decision the spec does not cover; you
  pre-declare a deviation. Otherwise decide, proceed, and report at the
  end.
- **Mirror the full verification block to `docs/reports/BUILD-REPORT.md`
  in your worktree regardless of messaging.**
