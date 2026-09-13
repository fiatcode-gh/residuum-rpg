# Build prompt — unit `m3-heroes` (story M3H "Heroes")

You are the build session for M3H. You write the code; the architect
session ("[arch] residuum-rpg") decides, verifies, and merges via PR.

## 1. Worktree

`/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-heroes`
on branch `m3-heroes, base `f758c3f`. **Already created — do NOT create it.**

## 2. Working directory — first command, no exceptions

```
cd /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-heroes && pwd
```

Confirm the output. The parent repository must never receive a commit from
you. `git rev-parse --show-toplevel` must print the worktree path.

## 3. The spec

Read in full before planning:

- Spec: `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-heroes-spec-M3H.md`
- Recon (background): `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-heroes-recon.md`
- Code conventions (binding, and this unit AMENDS its Testing section per
  the spec): `CLAUDE.md` at the repo root.

`docs/epic/` is gitignored — **never commit anything under it**; cite its
files by absolute path.

## 4. The work, in one paragraph

Give the multi-hero save document its face: a roster door in town to
create (named, rolled seed), switch (a suspended hero resumes into their
crawl), and delete heroes (confirmed, never down to zero) — retiring the
Abandon Hero plumbing entirely. Fix the merchant: purchases persist across
relaunch (today stock resurrects and re-buying duplicates an item id) and
everything sold this visit is buy-backable at the price paid, both carried
as per-hero visit state in the save document (one more in-place v1
reshape, legal while unshipped). Land the D31 testing amendment in
CLAUDE.md and the repository's first widget tests — the three formerly
invisible wiring mutations (canPop, didPop, autosaver attachment) must
now redden. Survivability stays exactly 24/40.

## 5. Be adversarial about the spec

Disagreeing in the open is expected behavior; every prior unit corrected
the architect. Claims most worth attacking:

- **The resurrection defect's mechanics.** The recon says re-buying a
  resurrected item duplicates an id and by-id operations act on the first
  match. Reproduce it once at base (a test or a trace) before building the
  fix, so the fix's test provably pins a real defect.
- **The switch/delete rebuild path.** The spec says "reuse the generation
  key"; if tearing down a session with a suspended-run hero fights the
  autosaver's lifecycle, argue the alternative rather than forcing it.
- **The roster-reads-the-document claim** — verify the document is
  actually reachable from the roster's build context without threading a
  new global; pre-declare whatever shape you need.
- **Widget-test style is unset.** You are establishing it; keep tests
  wiring-level, and if a spec-named test cannot be expressed without a
  golden image, say so instead of writing one.
- **Pre-declare shape deviations before writing code** (house pattern).
  Pubspec rule from M3S: an already-imported same-version declaration may
  ride the final report; a package NEW to the repository is a
  pre-declaration, always.

## 6. Method

- Characterization first (C1/C2 at base, deleted-with-argument later, per
  the spec's sequencing traps).
- Strict TDD (red → green → refactor); `// arrange` / `// act` /
  `// assert`; no mocks in core/content; widget tests use real widgets
  over injected fakes. Every commit's exit state is green everywhere.
- Conventional commits.
- No body comments; dartdoc only on public API, carrying the spec's four
  documentation arguments.
- House method (earned in M3S): mutation rows run against COMMITTED code;
  AVD verification presses the PLATFORM's buttons, not only the app's;
  every identifier in a report is PASTED from command output, never typed.

## 7. Environment traps (verbatim from the ledger)

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
- Cross-session message holds bite BOTH directions: an INTERACTIVE session
  holds incoming messages behind an approval gate that expires. If your
  reply is not acknowledged, assume it was held — BUILD-REPORT.md is the
  fallback and the user will relay.
- NOTE: the Bash sandbox is currently DISABLED machine-wide (user trial).
  The sandbox-shaped traps above are dormant; they stay listed because
  re-enabling is one boolean.

## 8. Mutation table

Run every row of the spec's table (1–10 including the control), against
committed code, and report the WHOLE table — greens included — naming the
reddened tests. Rows 7–9 are the unit's acceptance in miniature: they were
invisible to 768 tests before D31, and if one stays green with its widget
test in place, fix the TEST and say so. Extend the table if you find a
hazard it misses.

## 9. What you must NOT do

- No pushing, no PRs, no merging, no external trackers.
- No commits under `docs/epic/`.
- **Do not touch core.** Content changes are the save feature's
  visit-state fields only — no economy, bestiary, table, price, or xp
  edits. Survivability must print exactly 24/40.
- No golden-image widget tests (the amendment forbids them).
- No new dependencies (flutter_test ships with the SDK).
- No unseeded randomness outside the existing boot/creation clock site.
- The one CLAUDE.md change is the Testing amendment the spec quotes —
  nothing else in that file.

## 10. Verification block — every item evidenced, not asserted

1. `git rev-parse --show-toplevel`; `git log --oneline main..HEAD`
   (hashes pasted).
2. All three suites vs the baseline (395/197/176 = 768, measured fresh by
   the architect 2026-08-21 at `f758c3f` — re-measure before your first
   commit and say so).
3. C1/C2 quoted at base; their deletion arguments.
4. The base-reproduction of the resurrection/id-duplication defect.
5. The full mutation table, both halves; rows 7–9 red.
6. Survivability output: exactly 24/40, stalled 0.
7. `flutter analyze`; `dart format --set-exit-if-changed .`;
   `git diff main --stat -- packages/core` (EMPTY); the content diff
   showing only save-feature files; the CLAUDE.md diff showing only the
   Testing amendment.
8. Hygiene greps (body comments; content free of dart:io/DateTime; the
   clock-roll sites enumerated).
9. AVD acceptance per the spec's definition of done, screenshot-paired,
   pinned to `emulator-5554`.
10. **What the tests cannot prove**, stated plainly.
11. **Every spec claim you checked and found wrong**, with the source.
12. **Which execution phases ran, and why any named phase was skipped.**
13. Every deleted test, each with its argument.

Mirror this block to `BUILD-REPORT.md` in the worktree root (commit it).

## 11. Delegation

Real logic and the repo's first widget tests: write a plan first with the
`writing-plans` skill, then execute test-first with
`test-driven-development`. Inline execution with the mutation table
carrying the adversarial load is the accepted precedent (D9); per-task
reviewer subagents may be skipped, but argue the skip. Any subagent must
`cd` into the worktree and prove it with `pwd`.

## 12. Reporting back

🔴 Printing is not replying. To reach the architect, use the SendMessage
tool addressed to the sender of your kickoff message ("[arch]
residuum-rpg"). Message when: a spec claim looks wrong, the rebuild path
fights the autosaver, a widget test cannot be honest without a golden, or
you are blocked on a decision the spec does not cover. Otherwise decide,
proceed, and report at the end. If held, BUILD-REPORT.md is the channel
and the user will relay.
