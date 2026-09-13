# Build prompt — m3-fixes (M3F)

## The standing mailbox watch — your first action

Does your harness offer a way to run a background task that re-invokes you
when the task exits (an agent-launched background command, by any name)?
**You evaluate that against your own tool list — nobody resolved this for
you.** If it does, start this watch NOW, before reading the spec, before
recon, before any work — a post-dispatch correction must be able to reach
you from minute zero. Launch it as a background task, run from the unit's
handoff directory
`/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/handoff/m3-fixes`:

```
timeout --foreground 3600 sh -c '[ -f .worker-mail-delivered ] || touch -t 197001010000 .worker-mail-delivered; until [ architect.md -nt .worker-mail-delivered ]; do sleep 30; done; touch .worker-mail-delivered'
```

The script stamps itself at the moment it fires — never stamp by hand. On a
wake: restart the watch FIRST, then read `architect.md` in full and dispose
of the new entry: if it changes the task you are on, stop and adjust; if it
locks or corrects a decision, follow it from here on; otherwise acknowledge
it in your next `worker.md` entry and keep building. A claimed watch carries
a liveness duty: at every task boundary also verify the watch process is
genuinely alive (older than one poll tick). Dead or unverifiable means you
are on the floor — say so in your next entry and fall back to the bounded
poll below. If your harness has no such capability, the floor stands on its
own: check `architect.md` at every task boundary, and use the bounded poll
when blocked (next section).

Every `timeout` you launch for this protocol carries `--foreground`.

## The channel — how you and the architect talk

**Printing is not replying.** Your ordinary output reaches nobody. Every
reply, question, pre-declared deviation, and notice goes into the unit's
mailbox, appended to `worker.md` in
`/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/handoff/m3-fixes`;
you read answers from `architect.md` in the same directory. The architect
checks the mailbox between work units and at every turn start — an instant
read, not a wait — so an actively working architect answers within one work
unit.

Entry format, appended to the bottom of your own file:

```
## <seq> — worker — <ISO timestamp>
<body>
```

Take the timestamp from the clock (`date -Is`), never typed from memory.
Every entry ends with a cursor trailer stating
`disposed through architect entry N` (or `none yet`). "New mail" means the
other side's file holds a header with a higher sequence number than your
cursor — count `## ` headers, never trust file timestamps. An entry, once
appended, is never edited — a correction is a new entry. Append means a
true append primitive (shell `>>`), never an anchored edit; after writing,
confirm your entry is the last header in the file. If your shell mangles
heredocs, write the entry to a temp file and `cat` it onto the mailbox —
repairing your own mangled append by truncating the garbage before retrying
is sanctioned, disclosed in the replacing entry.

**When blocked on a question** (a spec claim looks wrong, an inherited gate
turns out not to be real, the work needs a decision the spec does not
cover): append to `worker.md, then — is your watch verifiably alive? If
alive, end your turn; the wake resumes you. If not, wait with the bounded
foreground poll from the handoff directory (keep the timeout under your
harness's shell-command cap and set the harness's own timeout control to
cover the poll window; if your first poll exits 124 far earlier than asked,
the cap killed it — set the control explicitly):

```
timeout --foreground 570 sh -c 'until [ architect.md -nt .worker-mail-delivered ]; do sleep 15; done; touch .worker-mail-delivered'
```

Exit 0: read the whole file, dispose, record the new cursor in your next
entry. Exit 124: poll again if the wait is still worth it, else stop and
tell your user the architect has not answered. Otherwise: decide, proceed,
report at the end. A correction that changes a locked decision or the spec's
shape is promoted to a ledger decision before you continue — the architect
does that; you keep building against the mailbox.

**Write `BUILD-REPORT.md` in the handoff directory when done, append the
done notice to `worker.md, and stop.** The report mirrors your verification
block — it is what the architect reads first if nobody was listening when
you finished.

## 1. The worktree

`/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-fixes`
— **already created — do NOT create it.** Branch `m3-fixes, based on
`54ec315` (`main`).

## 2. The working-directory hazard

Your shell does not reliably inherit the intended directory, and the parent
repository (`/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg`)
is on disk beside the worktree. First command, before anything:
`cd /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-fixes && pwd`
— confirm the output before continuing. Prefer git invocations that name
the repository path explicitly. **A commit landing in the parent repository
is a real failure mode.** There are no sibling worktrees today; do not
touch the parent repo's checkout at all beyond reading.

## 3. The spec and the recon

- Spec (read in full, then execute):
  `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-fixes-spec-M3F.md`
- Recon (background; read it if a spec claim looks wrong):
  `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-fixes-recon.md`

The ledger directory `docs/epic/` is gitignored. **Never commit anything
under `docs/epic/, `docs/reports/, or `docs/plans/`** — cite those files by
absolute path.

## 4. The work, in one paragraph

Three items, test-first: (1) `startRoadEncounter`
(`packages/content/lib/src/world.dart`) gains four constructor arguments so
road fights carry the profile's magic and materials instead of wiping them
through `endRun`; (2) gathering nodes in the app's glyph painter render on
the remembered map at the remembered opacity instead of vanishing outside
live FOV, with a new non-golden instrument pinning the paint plan; (3) the
town "Gear" screen becomes a "Character" screen with the dungeon Pack's
shape (stats, spells, worn, full carried pack, materials, skills), driven
by the existing `TownBloc` events. No save-format change, no content-table
change, no band movement.

## 5. Be adversarial about the spec

Disagreeing in the open is expected behaviour, not a nuisance — build
sessions in this epic have caught three architect arithmetic errors and
killed a control by measurement. Attack these claims specifically:

- **The central control: "no band can move."** The spec claims the fix adds
  zero rng draws and the survivability bot never touches road encounters.
  Verify by running the content suite and quoting all four band lines
  before and after — if any line moves, STOP and mail the architect.
- **"endRun needs no core change."** The spec claims core is complete
  because `endRun` already carries `knownSpells` and `materials`. Attack
  it: read `run_boundary.dart:113-124` yourself.
- **The four-argument fix.** Is `mana: heroMaxMana(profile.loadout)` right
  for the road, or should road mana be something else? Is `spellsById` the
  correct source (vs. a road-specific spell set)? Argue from the code.
- **R2's fixture.** The spec warns a spell-less hero has max mana 0. Make
  the fixture hero's schooling explicit field by field.

**Pre-declare any shape deviation BEFORE writing code** — append it to
`worker.md` and wait per the poll rules. Locked decisions (the spec's
per-item contracts) change only through the architect, promoted to the
ledger before you continue.

## 6. Method

Characterization tests FIRST, passing against the UNMODIFIED code (spec
C1, C2) — if they do not pass on the base commit, your understanding of
current behaviour is wrong: stop and report, do not work around. Then
red → green per behavior, `// arrange` / `// act` / `// assert` bodies,
pure tests (state in, state out, no mocks). Every commit's exit state is
green. Treat test code as clean code. Test bodies follow the repo
conventions (`CLAUDE.md` at the worktree root — read it; core is strict
TDD; content is validation-style; app defaults to bloc tests, widget tests
only where a bloc test cannot observe — navigation, doors, dialogs).

## 7. Environment traps — the ledger's block, verbatim

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

## 8. The mutation table

Run every row of the spec's mutation table on the final code, report the
WHOLE table — greens included, each red named as a test, never a count
(follow-up 27: mutation reds are a NAMED SET; analyze from the WORKTREE
ROOT with `pwd` quoted beside the command; prefer constant shifts that
cannot coincide with fixture values). Sequencing: every row runs after the
change; M5 mutates the post-fix node loop by sed and must remain runnable.

## 9. What you must NOT do

- No pushing, no opening a pull request, no requesting reviewers, no
  merging, no replying to review threads, no external trackers, no
  stakeholder-facing writes. The architect handles every external write on
  the user's explicit approval, per round.
- Never commit anything under `docs/epic/, `docs/reports/, or
  `docs/plans/`.
- Do not touch the parent repo's checkout, any other worktree, the user's
  physical phone, or the emulator's save data except through the
  copy-aside ritual above.
- No new dependencies, no format/lint suppressions, no `Random()` anywhere.
- Do not modify any survivability band pin, `dungeon_door_characterization_test.dart,
  or any content table.

## 10. Verification block — every item evidenced, not asserted

Each item names the command output that proves it:

- Proof the work happened in the worktree and the commits are not on the
  main branch (`git log --oneline main..m3-fixes, from the worktree, `pwd`
  quoted).
- Characterization tests quoted passing against the UNMODIFIED base commit
  (C1's group, C2's assertions — run on `54ec315` before your first change).
- Test counts per suite read from result files, compared against the stated
  baseline 1790 (762/530/498, measured fresh on `54ec315` by the architect —
  do not inherit it; re-run and quote your own counts).
- All four band lines byte-identical, quoted verbatim — before and after.
- The full mutation table, greens included.
- The AVD pass: the ritual (copy BOTH save slots aside BEFORE any install, `adb install -r, `-s emulator-5554`), the new door + character screen
  verified, a remembered-node screenshot plus a greyscale variant in
  `docs/reports/shots/m3-fixes/, saves restored, free space checked.
- `dart analyze .` from the worktree root, clean; `dart format
  --set-exit-if-changed .` clean; `flutter analyze` clean.
- What the tests cannot prove, stated plainly (the spec names one: feel).
- Every spec claim you checked and found wrong, with the source.
- Which execution phases ran and why any named phase was skipped — a skip
  is an argument, not an absence.

## 11. Delegation line — sized to this wave

This wave needs a written plan first, then test-first execution:

1. Write the plan (read
   `/var/home/dhemas/Development/Projects/fiatcode/ai-stack/shared/skills/flow-writing-plans/SKILL.md`
   and follow it) to
   `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/plans/2026-08-29-m3-fixes.md`
   — task by task, one red test named per task where a red exists. Commit
   NOTHING for the plan file (git-excluded path); it stays local.
2. Execute task by task test-first (read
   `/var/home/dhemas/Development/Projects/fiatcode/ai-stack/shared/skills/flow-tdd/SKILL.md`
   and
   `.../flow-executing-plans/SKILL.md` and follow them). Check
   `architect.md` at every task boundary.
3. Before claiming done, run the closing self-check (read
   `/var/home/dhemas/Development/Projects/fiatcode/ai-stack/shared/skills/flow-verification/SKILL.md`
   and follow it) — quote the command outputs, never assert them.

Commits: Conventional Commits (`feat:, `fix:, `test:, `refactor:, `docs:, `chore:`) with the persona author above.