# Build prompt — unit `m2-town` — story M2T "Town"

## 1. Worktree

`/var/home/dhemas/Development/Projects/_temp/residuum/.worktrees/m2-town,
branch `m2-town, based on `main` @ `69d55e4` —
**already created — do NOT create it.**

## 2. Working directory — first command, before anything else

```
cd /var/home/dhemas/Development/Projects/_temp/residuum/.worktrees/m2-town && pwd
```

Confirm the output is exactly that path. The parent checkout
`/var/home/dhemas/Development/Projects/_temp/residuum` (branch `main`) is the
worktree's grandparent directory — a commit landing there is a real failure
mode. Prefer `cd <worktree> && git <cmd>`.

## 3. The documents

Read in full, in this order, before writing anything:

1. Story spec (your contract):
   `/var/home/dhemas/Development/Projects/_temp/residuum/docs/epic/m2-town-spec-M2T.md`
2. The existing code: all of `packages/core` and `packages/content, plus
   `packages/app/lib/`. M2L's Profile-shaped pieces (Loadout, inventory,
   equipment, skills on GameState) are your extension points.
3. Code conventions (binding): `CLAUDE.md` at the worktree root.
4. Game design spec (context; sections 2 and 9): `docs/superpowers/specs/2026-08-20-dungeon-game-design.md`.

**Never commit anything under any `docs/epic/` path.** It is the architect's
gitignored ledger.

## 4. The work

Close the loop: runs start and end in town. New `Profile` value carries the
hero between runs; `startRun`/`endRun` convert (entry bumps `visit` and
reshuffles; death burns carried items and gold, keeps equipped gear, skills
and the bank). Inside the dungeon: stairs-up tiles and `AscendAction, floors
snapshot and restore exactly within a run, Return-to-town at any stairs. New
town screens: merchant (buy/sell, no arbitrage), bank (items + gold), inn
(rest for gold). Deeper creatures gain `pierce` so armor stops trivializing
depth 3+. `EquipRefused` renamed `ActionRefused`. Baseline (fresh
2026-08-21): 384 tests green (273 core + 69 content + 42 app).

## 5. Be adversarial about the spec

Disagreeing in the open is expected behaviour, not a nuisance. Attack these
first:

- **The floor-snapshot shape.** `FloorMemory` as specced snapshots monsters
  with their energy. Check the speed clock survives a freeze/restore without
  a burst of banked turns on arrival; if the energy field needs zeroing on
  restore, argue it and document it.
- **The explored-per-floor migration.** M2E reset `explored` on descend;
  the spec moves it into snapshots. Check which existing tests pin the old
  reset behaviour and list them as casualties BEFORE modifying.
- **`endRun(died: true)` healing to derived max** — derived max depends on
  equipment; check the ordering against +maxHp affixes so a dead hero cannot
  wake with more hp than a live one who rested.
- **The no-shopping bot.** The survivability band must hold with pierce and
  WITHOUT town help. If pierce cannot be tuned into the band without touching
  forbidden levers (bestiary hp/attack, hero base), stop and message me with
  the numbers rather than bending a rule.
- **Merchant stock via rollDrop.** If reusing the drop machinery for stock
  creates coupling that fights you (e.g. drop tables keyed by depth when
  stock wants breadth), propose the cleaner seam.

If a spec claim is wrong, message the architect (section 9) — do not silently
work around it.

## 6. Method

- **Characterization layer: the existing 384 tests.** Run them green on the
  unmodified worktree BEFORE your first change; if the baseline is not 384
  green, stop and report. Your plan must list which existing tests you expect
  to modify and why, before modifying them.
- Well past thirty lines with real logic. **Required phases, in order:**
  `superpowers:writing-plans` from the story spec, then execution per your
  session's standing constraints (inline `superpowers:executing-plans` is the
  accepted fallback when dispatching subagents is unavailable to you — argue
  the choice either way), with strict
  `superpowers:test-driven-development` red-green-refactor per task. Where
  dedicated per-task reviewers are unavailable, the mutation table carries
  the adversarial load — say so in the report, and extend the table where you
  find it thin (precedent: M2L's row 4b).
- Suggested order: rename → pierce → Profile/transactions → run boundary →
  stairs-up generation → snapshots/ascend → economy content → app screens →
  retune survivability.
- **Every commit's exit state is green.** Conventional commits.
- Close with `superpowers:verification-before-completion`.

## 7. Environment notes (from the ledger, 2026-08-21)

- The Bash sandbox is DISABLED on this machine (user trial). Do not change
  sandbox or any user-level configuration.
- Subagents dispatched into a git worktree do not inherit cwd — force
  `cd <worktree> && pwd` first, or work inline as previous units did.
- No fvm: plain `flutter` / `dart` (system Flutter 3.47.0).
- Never commit anything under `docs/epic/`.
- Commits:.
- AVD `Pixel_10` exists; launch via the `emulator` binary directly (`flutter
  emulators` mishandles the installed ps16k system images). First gradle
  build downloads for minutes; not a hang.
- `find` in the Bash tool may be bfs — `-newermt` takes ISO 8601 only;
  GNU find at `/usr/bin/find`.

## 8. Mutation table — run every row at the end, report the whole table

One mutation at a time, reverting each. Report greens as well as reds, naming
which tests each mutation reddened.

| # | Mutation (revert after checking) | Expected to fail | Expected to stay green (control) |
|---|---|---|---|
| 1 | pierce ignored in `_defend` | pierce arithmetic tests + retuned survivability | armor-only damage tests |
| 2 | endRun(died: true) keeps inventory and gold | death-penalty matrix tests | leave-alive matrix tests |
| 3 | startRun stops bumping visit | reshuffle-on-entry tests | floor-persistence round-trip tests |
| 4 | AscendAction regenerates instead of restoring the snapshot | persistence round-trip tests | descend-to-NEW-floor generation tests |
| 5 | sellPriceOf returns buyPriceOf (arbitrage) | no-arbitrage pin | bank round-trip tests |
| 6 | depositItem drops the item instead of banking it | bank round-trip tests | merchant tests |

## 9. Communication

Message the architect session — "[arch] residuum", the sender of the message
that pointed you here — using the SendMessage tool, when: a spec claim looks
wrong; you are blocked on a decision the spec does not cover; you intend a
shape deviation (pre-declare it, as M2L did — that pattern worked well); you
are done (send the verification block).

🔴 **Printing is not replying.** Your ordinary output is invisible to other
sessions; use SendMessage every time. Also mirror your final verification
block to `BUILD-REPORT.md` at the worktree root (uncommitted).

## 10. You must NOT

- Push to any remote, open a pull request, request a reviewer, or merge.
- Touch the parent checkout, its `main` branch, or any `docs/epic/` directory.
- Add any dependency beyond what `main` already has. Anything else needs an
  architect message first.
- Build quests, rumors, saves, overworld, multiple towns/dungeons, safe
  points, sets, or perks — later stories. Resist the adjacent feature.
- Touch bestiary hp/attack/speed or hero base stats when retuning
  survivability — pierce values, drop tables and spawn tables are the
  sanctioned levers; anything else needs an architect message first.
- Write body comments (dartdoc on public API only).
- Change sandbox or any user-level configuration.

## 11. Verification block — every item evidenced, not asserted

Send via SendMessage AND mirror to `BUILD-REPORT.md, each item with the
command output that proves it:

1. `pwd, `git branch --show-current, `git log --oneline main..m2-town,
   clean `git status --porcelain`.
2. Baseline: 384 green on the unmodified worktree before your first change.
3. Final counts from all three suites, plus every pre-existing test modified
   or deleted, each with its reason (the rename's mechanical sweep may be
   summarized as one line with a count).
4. `flutter analyze` ×3 and `dart format --set-exit-if-changed .` outputs.
5. The full mutation table with observed results, greens included.
6. **The survivability report with pierce:** final rate in band, the pierce
   values chosen, the retuning trail, levers not pulled.
7. Persistence evidence: the round-trip test quoted (wounded monster +
   dropped item + explored restored exactly).
8. AVD playthrough on `Pixel_10` (quote `adb devices`): the full loop from
   the spec's definition of done, including the deliberate death and the
   carried-vs-banked outcome, stated as observations.
9. **What the tests cannot prove**, stated plainly.
10. **Every spec claim you checked and found wrong**, with the source — or
    "none".
11. **Which execution phases ran and why any named phase was skipped** — a
    skip is an argument, not an absence.
