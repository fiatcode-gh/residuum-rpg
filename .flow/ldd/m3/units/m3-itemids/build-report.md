# REPORT — m3-itemids (story M3I)

Build session report, 2026-09-03. Base `a567c19`, branch `m3-itemids`,
worktree `.worktrees/m3-itemids`. Head at report time: `b06b6de`.

## 1. Where the work landed

- `cd /var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/.worktrees/m3-itemids && pwd`
  → the worktree path, quoted in every analyze/format run below.
- `git branch --show-current` → `m3-itemids`.
- `git log --oneline main..m3-itemids` (9 commits, exist on no other branch —
  the parent repo stayed untouched throughout):

  ```
  b06b6de refactor: lift the mint and temper rationale into dartdoc
  22a5898 test: the app-level pickup pin flips with the mint
  4c56bdc style: format the codec test file
  2075fc2 chore: drop an unused fixture from the ride tests
  8e15785 feat: id-based removals take exactly one item
  f0e6a39 feat: pickup mints hero-unique item ids
  2574d9c feat: itemNumber rides every inventory boundary
  05b8aed feat: itemNumber rides the save codecs omit-on-default
  9d177c2 feat: hero-scoped itemNumber counter and Item.withId
  3819b91 test: duplicate-id characterization for m3-itemids
  ```

- No commits under `docs/` (`git log --name-only main..m3-itemids | grep docs/`
  is empty). Nothing pushed, no PR, no review replies.

## 2. Test counts, fresh baseline vs final

Baseline measured FRESH on unmodified `a567c19` this session
(`/tmp/baseline-{core,content,app}.log`, all exit 0):

| Suite | Baseline a567c19 | Final | Delta |
|---|---|---|---|
| core | 793 | 828 | +35 |
| content | 541 | 550 | +9 (7 codec, 2 road-ride) |
| app | 563 | 563 | 0 (one expectation flipped, count unchanged) |

Final logs: `/tmp/final-core.log` (828, exit 0), `/tmp/final-content.log`
(550, exit 0), app rerun after the one flipped app-level pin: 563, exit 0.
All deltas are this unit's new tests; no pre-existing test was deleted.

## 3. Characterization proof (against UNMODIFIED a567c19)

The three characterization files were written and run green BEFORE the first
change commit (only commit at that point was none — the run predates
`3819b91`, which is the tests alone):

- `packages/core/test/engine/duplicate_id_test.dart` — 4/4 green (remove-ALL
  drink/read/drop, pickup keeps ground id).
- `packages/core/test/town/duplicate_id_test.dart` — 7/7 green (remove-ALL
  sell/deposit/withdraw/readBook, replace-ALL temper both containers,
  first-match pricing).
- `packages/core/test/loot/wear_duplicate_test.dart` — 2/2 green (refusal
  names first match's base; wear removes all).

These defect pins did their job, then flipped WITH the change: they now pin
remove-one, and their file doc-comments record the transition. The pre-flip
green runs are the proof item 3 asks for; the reds they later showed against
the new code are item 4's evidence that the fix bites.

## 4. Mutation table (full, both phases, named)

**Phase 1 — pre-flip (mutations are the current behaviour; new-behaviour tests
must go red against a567c19):**

| Row | Run | Named reds | Named greens (controls) |
|---|---|---|---|
| M1 | mint tests vs a567c19 | `the first pickup becomes item-1`, `the next pickup becomes item-2` (behavioural reds: pack id stayed `floor-*`/`drop-*`) | `dungeon_door_characterization_test` + `themed_floor_characterization_test` + `merchant_shelf_characterization_test` 16/16 green; the pickup characterization test green |
| M2 | remove-one tests vs a567c19 | `drinking a duplicate id takes exactly one…`, `reading…`, `dropping…` (3 reds: every match vanished) | `step_loot_test` + `step_drop_test` 39/39 green (single-potion packs: remove-all ≡ remove-one) |

Honest note on M1: a third mint test (`the ground keeps its litter id`)
also went red pre-flip, but through a test-arrangement bug of mine (I
mis-assumed which twin `here.last` takes), not through the mutation. It was
fixed before the change landed; the two behavioural reds are the M1 evidence.

**Phase 2 — post-flip (M1/M2 meaningless after the flip, per spec; M3–M5
mutate the new code, revert after each):**

| Row | Mutation | Named reds | Named greens |
|---|---|---|---|
| M3 | delete `itemNumber` from suspendRun's copy list | `suspendRun copies the run counter onto the profile` | the other 5 ride tests, incl. both `endRun` halves and both `resumeRun max()` tests — different doors, unaffected |
| M4 | profile codec encode unconditional | `a default profile writes no key at all` + the existing key-set pin `only earned fields are written` | run codec tests green (the 2 reds were profile-side only) |
| M5 (control) | `brewNumber` encode → omit-on-default | 8 reds: 6 in `profile_codec_test` (incl. both round-trip pins) + 2 `golden_save_test` byte-for-byte pins | `version_gate_test` 5/5 green |

M5 is the proof the goldens are wired to the encode shape. Every mutation
was reverted; post-revert runs green each time.

## 5. The five band lines (my own run, post-change)

From `/tmp/final-content.log` (the final content suite on the finished tree):

```
survivability: 16/40 won (40.0%), stalled 0, died at 1:1 2:9 3:8 4:6 5:16
casting build: 40/40 won
greedy build: 16/40 won; fleetfoot-first build: 13/40 won
sea-cave: 26/40 won (65.0%), stalled 0, died at 2:3 3:7 4:14 5:11 6:5
ruined keep: 24/40 won (60.0%), stalled 0, died at 1:5 2:5 3:3 4:2 5:13 6:7 7:5
```

These are byte-identical to the spec's pins (crypt 16/40
`{1:1,2:9,3:8,4:6,5:16}`, casting 40/40, greedy 16 / fleetfoot 13,
sea-cave 26/40, keep 24/40). The pins are exact-count assertions in
`survivability_test.dart`; the run is green on the finished tree.

## 6. Analyze and format (worktree root, pwd quoted)

- `pwd` → `/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/.worktrees/m3-itemids`
- `dart analyze .` → `No issues found!`
- `dart format --output=none --set-exit-if-changed .` → exit 0 (0 changed).

## 7. What the tests cannot prove

- That the user's actual device saves load. The absent-key decode path is
  proven with hand-built documents, not a real playtest save; the unit ran
  no device operations (per the build prompt).
- That the five pinned band lines are the whole of "nothing bot-visible
  moved" — the trail measures what it measures; a behaviour outside its
  seeds is unproven.
- That no id-minting site exists outside the families the recon grepped
  (drops, litter, trophies, market, kit, brew, and now the pack mint) —
  that is a grep-based claim, not an exhaustive proof.
- Playtest feel of remove-one on a legacy duplicate pack.

## 8. Spec claims checked — none found wrong

All four attack targets were verified by measurement and held:

1. Boundary list complete: `grep inventory:` across `run_boundary.dart`
   (5 sites: 86/119/163/234 + death strip at 127 riding via `carried`) and
   `world.dart` (434) found exactly the spec's five doors. Road fights
   return through `endRun` (`town_bloc.dart:458/583`), so no sixth door.
2. Prefix claim verified at the mint sites: no `item-` mint existed anywhere
   in core/content lib before this unit; `market-*`/`kit-*`/`brew-*` are
   distinct prefixes.
3. Remove-first-match determinism: pack order is append-order (first match =
   oldest); rebuys enter with fresh `market-*` ids, so the change mints no
   new duplicates.
4. The bands held byte-identical on the first post-change run.

One channel discrepancy (not a spec claim): the dispatcher note said "YOU
create it" for the worktree; the build prompt said it already existed — the
build prompt was right, and I followed it.

## 9. Execution phases — all ran, none skipped

plan (docs/plans/2026-09-03-m3-itemids.md, uncommitted per the no-docs-
commits rule) → characterization (green on a567c19) → pre-flip mutations
M1/M2 → change (7 commits, every commit green) → post-flip mutations M3–M5
→ full verification → reviewer dispatch. Reviewer verdict:
**APPROVE WITH NITS**; both fixable nits (in-body comments violating the
house rule) were fixed in `b06b6de`. Two nits were scope notes, logged as
follow-ups below.

## Follow-ups found (not this unit — for the ledger)

- `packages/content/lib/src/save/merchant_visit.dart:80` (`withoutSold`,
  the buy-back) still removes ALL matches — from the merchant's stock list,
  whose ids are visit-scoped and unique by construction. Harmless today;
  becomes a defect only if stock ever persists across visits (same trigger
  as follow-up 16's bank stacking).
- `temperItem`'s worn branch replaces every matching SLOT, so two worn slots
  sharing a legacy id would both temper while `heldItem` named only the
  first. Extremely exotic (requires a legacy save with one id worn in two
  slots); noted, not fixed.
- The preserved defect stands per spec: `wear()`'s `firstWhere` on an absent
  id is untouched (unreachable behind the refusal guard).