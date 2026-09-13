# Build prompt — unit `m2-loot` — story M2L "Loot"

## 1. Worktree

`/var/home/dhemas/Development/Projects/_temp/residuum/.worktrees/m2-loot,
branch `m2-loot, based on `main` @ `961dc46` —
**already created — do NOT create it.**

## 2. Working directory — first command, before anything else

```
cd /var/home/dhemas/Development/Projects/_temp/residuum/.worktrees/m2-loot && pwd
```

Confirm the output is exactly that path. Your shell does not reliably inherit
it, and the parent checkout `/var/home/dhemas/Development/Projects/_temp/residuum`
(branch `main`) is the worktree's grandparent directory — a commit landing
there is a real failure mode. Prefer `cd <worktree> && git <cmd>`.

## 3. The documents

Read in full, in this order, before writing anything:

1. Story spec (your contract):
   `/var/home/dhemas/Development/Projects/_temp/residuum/docs/epic/m2-loot-spec-M2L.md`
2. The existing code: all of `packages/core` and `packages/content, plus
   `packages/app/lib/game/`. This story extends M2E's real interfaces.
3. Code conventions (binding): `CLAUDE.md` at the worktree root.
4. Game design spec (context): `docs/superpowers/specs/2026-08-20-dungeon-game-design.md`.

**Never commit anything under any `docs/epic/` path.** It is the architect's
gitignored ledger.

## 4. The work

Loot, gear, skills, and healing: items with rarities and affixes drop from
monsters and floors; the hero picks up, carries (cap 20), equips six slots
(two-handers exclude shields), drinks potions, and trains Arms/Might/Bulwark/
Fleetfoot by using them. Damage math gains armor and dodge. A dedicated loot
random stream keeps drops independent of fight order. The binding outcome: a
1→5 descent becomes survivable — proven by a deterministic bot simulation
that must win 50–95% of ≥30 seeded runs. Baseline (fresh 2026-08-21):
212 tests green (156 core + 29 content + 27 app).

## 5. Be adversarial about the spec

Disagreeing in the open is expected behaviour, not a nuisance. Attack these
first:

- **The survivability band (50–95%).** If the bot's simple policy (attack
  adjacent, drink under 40%, path to stairs) is too dumb to ever reach 50%
  regardless of content — or if it trivially cheeses fights the flow field
  cannot punish — say so with numbers and propose the policy amendment; do
  not tune content to fit a broken bot.
- **The hp-clamp-on-unequip rule** ("never kill the hero by undressing,
  floor 1"): check it against DrinkAction and +maxHp affixes for ordering
  bugs (drink at boosted max, then unequip).
- **The dodge-before-armor pipeline:** if the order (dodge roll, then armor
  subtraction) creates degenerate stacking with the Fleetfoot cap, measure
  and report.
- **The starting-kit equivalence claim** (fists 1–2 + rusty sword +2/+3 keeps
  most existing tests green): verify against the real fixtures before
  trusting it; report which tests it fails to save.
- **Numbers everywhere** (item stats, affix magnitudes, xp curve, drop
  chances): the spec binds shapes, not numbers. Draft them, tune them against
  the simulation, report the tables and the tuning trail.

If a spec claim is wrong, message the architect (section 9) — do not silently
work around it.

## 6. Method

- **Characterization layer: the existing 212 tests.** Run them green on the
  unmodified worktree BEFORE your first change; if the baseline is not 212
  green, stop and report. Your plan must list which existing tests you expect
  to modify and why, before modifying them.
- Well past thirty lines with real logic. **Required phases, in order:**
  `superpowers:writing-plans` from the story spec, then execution per your
  session's standing constraints (inline `superpowers:executing-plans` is the
  accepted fallback when dispatching subagents is unavailable to you — argue
  the choice either way), with strict `superpowers:test-driven-development`
  red-green-refactor per task. Per-task spec-then-quality review; where
  dedicated reviewers are unavailable, the mutation table carries the
  adversarial load — and say so in the report.
- Build order: core loot/skills → step integration → content → app.
- **Every commit's exit state is green.** Conventional commits.
- Close with `superpowers:verification-before-completion`.

## 7. Environment notes (from the ledger, 2026-08-21)

- The Bash sandbox is currently DISABLED on this machine (user trial). Do not
  re-enable or change any sandbox configuration.
- Subagents dispatched into a git worktree do not inherit cwd — force an
  explicit `cd <worktree> && pwd` first or they commit in the parent repo.
- No fvm in this repo: plain `flutter` / `dart` (system Flutter 3.47.0).
- Never commit anything under `docs/epic/` (gitignored architect ledger).
- Commits:.
- AVD `Pixel_10` exists; launch via the `emulator` binary directly (`flutter
  emulators` mishandles the installed ps16k system images). First gradle build
  downloads for minutes; not a hang.
- `find` in the Bash tool may be bfs, not GNU findutils — `-newermt` takes
  ISO 8601 only; GNU find is at `/usr/bin/find`.

## 8. Mutation table — run every row at the end, report the whole table

One mutation at a time, reverting each. Report greens as well as reds, naming
which tests each mutation reddened.

| # | Mutation (revert after checking) | Expected to fail | Expected to stay green (control) |
|---|---|---|---|
| 1 | heroArmor never subtracted from monster damage | damage-reduction + survivability tests | movement/descend tests |
| 2 | affix bonuses dropped from effective-stat derivations | stacked-affix derivation tests | base-item-only equip tests |
| 3 | skill xp never awarded | all four training-trigger tests | equip/unequip tests |
| 4 | two-hander no longer unequips the shield | both exclusion-rule tests | one-hand equip tests |
| 5 | drops rolled from combat `rng` instead of `lootRng` (mutate the stream choice, not the API) | the two lootRng determinism pins | floor-layout determinism tests |
| 6 | DrinkAction heals 0 | potion tests + survivability | pick-up/drop tests |

## 9. Communication

Message the architect session — "[arch] residuum", the sender of the message
that pointed you here — using the SendMessage tool, when: a spec claim looks
wrong; you are blocked on a decision the spec does not cover; you are done
(send the verification block).

🔴 **Printing is not replying.** Your ordinary output is invisible to other
sessions; use SendMessage every time. Also mirror your final verification
block to `BUILD-REPORT.md` at the worktree root (uncommitted) — a previous
architect socket went stale mid-epic and the mirror is the recovery path.

## 10. You must NOT

- Push to any remote, open a pull request, request a reviewer, or merge.
- Touch the parent checkout, its `main` branch, or any `docs/epic/` directory.
- Add any dependency beyond what `main` already has (flutter_bloc, equatable,
  bloc_test, flutter_test, test). Anything else needs an architect message
  first.
- Build towns, gold, merchants, death-penalty, jewelry slots, set bonuses, or
  resting — later units. Resist the adjacent feature.
- Write body comments (dartdoc on public API only).
- Change sandbox or any user-level configuration.

## 11. Verification block — every item evidenced, not asserted

Send via SendMessage AND mirror to `BUILD-REPORT.md, each item with the
command output that proves it:

1. `pwd, `git branch --show-current, `git log --oneline main..m2-loot,
   clean `git status --porcelain`.
2. Baseline: 212 green on the unmodified worktree before your first change
   (quote the three suite tails).
3. Final counts from all three suites, plus every pre-existing test modified
   or deleted, each with its reason.
4. `flutter analyze` ×3 and `dart format --set-exit-if-changed .` outputs.
5. The full mutation table with observed results, greens included.
6. **The survivability report:** final win rate over the seed range, the
   content/tuning trail (what you changed and why), and the levers you did
   NOT pull.
7. Loot determinism evidence: both pins quoted.
8. AVD playthrough on `Pixel_10` (quote `adb devices`): pick up, equip, stat
   change visible, potion drunk, dodge logged, level-up logged, and a human
   1→5 descent. State observations; you cannot prove feel.
9. **What the tests cannot prove**, stated plainly.
10. **Every spec claim you checked and found wrong**, with the source — or
    "none".
11. **Which execution phases ran and why any named phase was skipped** — a
    skip is an argument, not an absence.
