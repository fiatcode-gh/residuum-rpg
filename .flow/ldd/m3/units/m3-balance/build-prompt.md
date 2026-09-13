# Build prompt — M3B `m3-balance`: the rebalance

## 1. Worktree

`/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-balance`
on branch `m3-balance, base `b9d7c21`. **Already created — do NOT create it.**

## 2. Working directory, first command

Your shell does not reliably inherit the intended directory. First command,
output confirmed before anything else:

```
cd /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-balance && pwd
```

The parent repository at
`/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg` must never
receive a commit from you. No sibling worktrees exist right now; if one
appears, leave it alone.

## 3. The spec

Read in full before any code:
`/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-balance-spec-M3B.md`

Background (read if a spec claim looks wrong):
`/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-balance-recon.md`

These live under `docs/epic/, which is LOCAL and gitignored. **Never
commit anything under `docs/epic/`.** Cite them by absolute path. Your
written plan goes in `docs/plans/` (worktree-relative, tracked); your
report mirror goes to `docs/reports/BUILD-REPORT.md` (worktree-relative,
gitignored).

## 4. The work, in one paragraph

Kill the playtest's five verdicts in one wave. Difficulty: pierce and deep
attack ceilings re-scale so the floor-of-one stops being universal, pinned
by a new depth-scoped designed-difficulty test (every depth-3+ creature's
best blow must beat the fixture kit's armor by ≥2; the shallow nuisances
are named exemptions). Loot: litter cut hard (crypt 1–2, cave 0–2, keep
1–2 per floor), drop chances +10, merchant gear 1–3 — prices, inn, bank
all UNCHANGED (income scarcity heals the currency). Camps expire: a new
hero-level `campDay` save key (v1 reshape, goldens by hand), overrun at
world.day − campDay ≥ 3 with a warning at 2, checked lazily at the fork.
Discovery: `arrivingAt` stops revealing neighbours — rumors and the
traveler become the only doors, and buying a rumor finally NAMES the place
in the log. The road scales: `dangerOn(route, profile)` adds a progression
tier, and the two new roads get themed spawn tables. A delve COMPLETES:
leaving from the bottom ends the run alive behind a confirm (preserving
the D36 merchant keep), the bottom arrival and a boss kill get composed
log beats (id prefix `boss-, NO core events). Disabled controls say why
(`ItemRow.reason`). Follow-ups 14/15 (clamp unification, cap-overflow fix)
land too. EVERY survivability figure re-pins by design; the crypt's
LAYOUT stays byte-identical.

## 5. Attack the spec

Disagreeing in the open is expected behaviour — workers have corrected
architect claims in every unit of this epic. The claims most worth
attacking here:

- **The designed-difficulty pin's arithmetic.** `pierce >= 10 − maxRoll`
  assumes the fixture's armor is exactly 8 and stays 8. Verify against
  the actual `_kitted` loadout and `heroArmor`; if the fixture or the pin
  should be derived from the loadout rather than a literal 8, pre-declare
  the shape.
- **The band targets (ruling 11).** Crypt 45–70% fresh-hero after pierce
  rescaling AND litter cuts (fewer potions found!) may be unreachable in
  the first-guess space. The tuning loop is yours with a trail — but if
  the targets fight each other, STOP and message the architect with the
  measured trail rather than inventing mechanisms.
- **Ruling 1's blast radius.** Dropping the adjacency union touches
  whereabouts tests, world_bloc tests, world_screen tests, and travel
  tests (the recon names lines). Verify the two duplicated
  undiscovered-scans (`rumorOnOffer` / `_firstUntold`) stay agreeing, and
  check death-on-road (`arrivingAt(home)`) for anything that silently
  depended on the re-reveal.
- **Ruling 2's merchant keep.** The spec claims `_onRunEnded` can adopt
  suspend's conditional keep without breaking the death path (death DOES
  move the visit, so death still clears). Check the death flow before
  building.
- **The expiry check's laziness.** "Checked wherever the fork is offered
  or resume attempted" — enumerate those sites yourself (world screen
  fork, ResumeCrawlPressed, boot into a camped hero?) and pre-declare the
  list. A camp that expires while the app is closed must be caught at
  boot too, or the fork lies once.
- **`dangerOn`'s threading.** Core must not see a Profile. If the value
  cannot reach `travelOneDay` cleanly through the existing app call site,
  pre-declare the seam you need.

**Pre-declare every shape deviation before you write it.** An owned
mismatch is a correction, not a breach.

## 6. Method

- A written plan first (`writing-plans, into `docs/plans/`), then strict
  test-driven development (red → green → refactor) per unit of behavior.
- Characterization net FIRST (the full existing net, quoted), passing
  against UNMODIFIED code; a base failure is a stop-and-report. Every
  re-pin lands in the SAME commit as its replacement, old value quoted in
  the commit message.
- Every commit's exit state is green. The `campDay` reshape and its
  hand-edited goldens land in ONE commit.
- The tuning loop is measured: after every content delta, re-run the
  bands; keep the whole trail (the M3D four-step trail is the format).
- Subagent policy (D9): no unattended write-capable subagents; execute
  inline; the mutation table carries the adversarial load.
- Commits:, conventional
  style. Test bodies `// arrange` / `// act` / `// assert`; no body
  comments in production code; dartdoc only on public API of
  core/content; ubiquitous language — `residue, `rumor, `camp, `delve, `overrun, the spec's words exactly.

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
  correctly. Tooling artifact, not an app bug.
- A physical phone may be attached alongside the AVD: pin every adb and
  flutter command to the emulator serial (`-s emulator-5554`); never
  install to or touch the phone.
- Device saves are playtest state: before pushing any acceptance save to
  the emulator, copy `save.json` AND `save-previous.json` aside
  (`run-as … cat > /tmp/…`) and restore after. The M3X pass overwrote the
  user's playtest save and its backup, unrecoverably.
- Cross-session message holds bite BOTH directions: an INTERACTIVE session
  holds incoming messages behind an approval gate that expires. Keep
  exactly one architect session alive; the report mirror is the fallback.
- (The machine-wide sandbox is currently DISABLED — sandbox-shaped traps
  are dormant, but keep the habits.)
- `dart analyze .` runs from the WORKTREE ROOT — a package-directory run
  does not reach sibling packages' test dirs. Quote the `pwd` beside the
  analyze output.
- Mutation reds are reported as a NAMED SET of tests, never a bare count.
  A mutant whose replacement value can COINCIDE with the original at a
  test's fixture seed under-reports its red set — prefer constant shifts
  that cannot coincide (D47).
- Any seeded acceptance save states its fixture's stat delta from the
  real starting hero FIELD BY FIELD, then argues each observation past
  the delta (D47).

## 8. The mutation table

The spec's 14-row table (rows 1–12 plus greens G1–G2) is binding: run
EVERY row against COMMITTED code with your own sed and report the whole
table, greens included, reds as named sets. G2 (core green under pierce
changes) is the truthful weak half — report the green as the finding.
Sequencing: rows 2–3 after campDay lands; row 10 after the new pin; the
survivability re-pins land only after the tuning converges. Extend the
table where the spec is blind — extensions have caught real defects in
eight consecutive units.

## 9. What you must NOT do

- No pushing, no pull request, no merging, no review replies, no external
  trackers. The architect handles every external write, on the user's
  approval, per round.
- Core edits confined to `world/whereabouts.dart, `world/travel.dart, `town/town.dart` (+ the `skills/skill.dart` dartdoc prose fix).
  `step.dart, `generator.dart, `game_state.dart, `run_boundary.dart, `loadout.dart, `event.dart` byte-untouched. Anything else is a
  stop-and-pre-declare.
- No edit to `dungeons.dart, `dungeon_spawn.dart, `armory.dart, `affix_pool.dart, `new_game.dart`. No hero formula, kit, price, or
  layout-generator change. No save-version bump. No new core events.
- The crypt's floor LAYOUTS are byte-frozen (floorSeed/generateFloor
  untouched); what stands and lies on them may change per the spec.
- Never commit under `docs/epic/` or `docs/reports/`. Never touch a
  physical phone. No hue-only signal; no tooling on goldens; no unseeded
  Random; no body comments.

## 10. Verification block — every item evidenced, not asserted

Report, with command output quoted for each:

1. `pwd` proving the worktree; `git log --oneline main..m3-balance`.
2. The characterization net against UNMODIFIED code (counts + all four
   survivability lines quoted before your first change).
3. All three suites vs the baseline (529 + 396 + 371 = **1296**, measured
   fresh by the architect 2026-08-24 on `main` @ `b9d7c21`); the
   declaration-count cross-check; deletions confined to the spec's
   re-pin ledger, each replacement in the same commit with the old value
   quoted.
4. Survivability: all re-pinned lines quoted, inside the ruling-11
   targets, with the FULL tuning trail (every delta and its
   re-measurement). The designed-difficulty pin quoted from source with
   its named exemptions.
5. `dart analyze .` from the WORKTREE ROOT with the pwd quoted;
   `dart format --set-exit-if-changed .` clean project-wide.
6. The FULL mutation table, both halves per row, reds as named sets,
   extensions included.
7. Diff scope: core confined to the three named files + the one dartdoc;
   the section-9 must-not list untouched (`git diff main --name-only`
   quoted); generator layout goldens byte-identical; no pubspec change.
8. Save: campDay refusal rows named; goldens hand-regenerated (diff
   quoted); the expiry round-trip proven (suspend day N → +3 days →
   overrun at the fork → fresh entry bumps the visit).
9. Hygiene greps: no body comments in changed production files, no
   unseeded `Random(, arrange/act/assert in new tests, the spec's nouns
   exact.
10. AVD acceptance on `Pixel_10` via `-s emulator-5554` — BOTH device
    save slots copied aside first and restored after: the spec's
    definition-of-done walk in full; screenshots pulled to
    `docs/reports/shots/` and listed; greyscale shots of the new
    reason/beat lines; any seeded save's fixture delta stated field by
    field.
11. **What the tests cannot prove**, stated plainly (whether the new
    numbers are FUN is the user's next playtest, not yours — say it).
12. **Every spec claim you checked and found wrong**, with the source.
13. Which execution phases ran, and an argument for any skipped one.

Every identifier PASTED, never typed.

## 11. Reporting back

- **Printing is not replying.** Your ordinary output is invisible to
  other sessions. Use SendMessage addressed to **the sender of your
  kickoff message**. Message when: a spec claim looks wrong; an inherited
  gate is not real; the tuning targets fight each other; you pre-declare
  a deviation. Otherwise decide, proceed, and report at the end.
- **Mirror the full verification block to `docs/reports/BUILD-REPORT.md`
  in your worktree regardless of messaging.**
