# m3-battle (unit A) — build report

Worker session for story M3U, unit A of the battle overhaul. Branch
`m3-battle, baseline `8168861, 8 commits, all landed on the branch only.
The spec is the contract; rulings D76–D79 (delivered mid-build through the
mailbox) are folded in and cited where they moved a pin.

## Verification block

**1. Place.** `cd /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-battle && pwd`
→ `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-battle`;
`git rev-parse --show-toplevel` → same. `git log main..HEAD --oneline` (8):

    25b2e38 docs: the spitter's dartdoc follows the D78 ruling, and the
      reach pin covers every creature
    a84e096 test: two pins the mutation table demanded
    6bef5fb feat: the casting bot judges the new fight
    8e8f18c feat: a cast may name its target
    0a03867 feat: monsters with reach shoot from line of sight
    f73a2ed feat: the spitter stands in the crypt's shallow floors
    076bc7d feat: the ambush opening
    6c19148 feat: the reach field rides the save only when it is not one
    61a5898 test: pin arrival safety beside an adjacent monster

Nine commits; nothing on `main`. Tree clean at close (`git status --short` → only `.pi/,
the harness's own task directory, never staged). Working tree at the ranged
branch's mid-build state existed only between commits and was never committed
red; the final tree is clean.

**2. Baseline, measured fresh** (2026-09-02, on unmodified `8168861, my own
JSON result files via `--file-reporter=json, counts from non-hidden
`testDone` events): **core 762 + content 533 + app 515 = 1810**, all three
exit 0. Measured fresh, not inherited — matches the expected shape exactly.

**3. Characterization first**, quoted passing against unmodified `8168861`
before any change landed:

- `golden_save_test.dart`: 6/6 green (the v3 byte-identity control) — run
  again green immediately before and again inside the codec commit.
- `step_monsters_test.dart` + `step_cast_test.dart` + `target_test.dart`:
  53 green (adjacent-claw, nearest-enemy, row-then-column ties, refusal
  order unknown → mana → empty room).
- `step_descend_test.dart`: 17 green, including a new adjacent-arrival pin
  (`arrival runs no monster phase, even with a monster adjacent`), committed
  first as `61a5898`.

**4. Final counts** (final runs, own result files, non-hidden `testDone,
all three exit 0, zero failures):

    core 793 (baseline 762, +31: ambush 9 + arrival pin 1 + ranged 12 +
      targeting 8 + the unknown-before-mana order pin 1)
    content 541 (baseline 533, +8: spitter stat pin, d1/d2 table pins,
      no-depth-≥3 pin, reach-by-id pin, casting group 2)
    app 515 (baseline 515, +0: app untouched, as scoped)

Every delta is explained by the spec's new tests; the four existing band
lines' assertions moved only where the trail re-pinned them.

**5. Band lines**, quoted verbatim from my own runs at the final state:

    survivability: 16/40 won (40.0%), stalled 0, died at 1:1 2:9 3:8 4:6 5:16
    greedy build: 16/40 won; fleetfoot-first build: 13/40 won
    sea-cave: 26/40 won (65.0%), stalled 0, died at 2:3 3:7 4:14 5:11 6:5
    ruined keep: 24/40 won (60.0%), stalled 0, died at 1:5 2:5 3:3 4:2 5:13 6:7 7:5
    casting build: 40/40 won

Every moved pin re-set by hand with its old value quoted in the same commit:
crypt depths `{1:1,2:6,3:6,4:7,5:20}`@20 → `{2:7,3:6,4:8,5:19}`@19 (row 1) →
`{1:1,2:8,3:9,4:4,5:18}`@18 (row 2) → final `{1:1,2:9,3:8,4:6,5:16}`@16;
sea-cave `{2:1,3:8,4:13,5:9,6:9}`@30 → `{2:3,3:7,4:14,5:11,6:5}`@26; keep
`{1:4,2:5,3:4,4:2,5:13,6:6,7:6}`@25 → `{1:5,2:5,3:3,4:2,5:13,6:7,7:5}`@24;
fleetfoot-first 14 → 9 → 11 → 13; the crypt soft floor 0.45 → 0.40 (crypt
only, D79, reason written into the assertion); the casting line is new and
pinned at 40/40 with the not-apples-to-apples dartdoc living where the pin
lives. `hasLength(5)`→6, `hasLength(14)`→15; shallow-exempt computed set
`{'rat','wolf','ghoul','crab'}` → +`'spitter'` (D76); door roster
`['rat-1','wolf-2','rat-3']` → `['rat-1','rat-2','rat-3']` (seed 4242, same
commit as the table change); three gathering digests re-pinned with old
values (crypt 1 1, 1 2, 909 2 — the digest covers rosters; every other floor
digest-identical).

**6. The trail** (full table in the untracked plan
`docs/plans/2026-09-02-m3-battle-unit-a.md`; every row re-measured on my own
runs):

| Row | Delta | crypt |
|---|---|---|
| baseline | 8168861 | 20/40 |
| 1 | ambush opening | 19/40 (47.5%) |
| 2 | + spitter d1+d2 (hp 7) | 18/40 (45.0%, exactly on the floor) |
| 3 — failed, kept | ranged branch, hp 7 | 16/40 (40.0%) |
| 4 — failed, kept | D77 d2-drop | 15/40 (37.5%) — harder, reverted |
| 5 — failed, kept | D78 hp 4 | 16/40 (40.0%) |
| experiment — kept, reverted | reach 3→2 | 18/40 (45.0%, boundary) |
| final | D78+D79 landed | 16/40, floor 0.40 |

Sea-cave 26/40 and keep 24/40 from row 1 onward, unmoved by later rows
(verified each time — no reach monsters in those dungeons).

**7. Mutation table**, both halves, named sets, tree verified clean after
each row (`git status --short` quoted after every revert; final tree clean):

- **M1** (delete the ambush swing path — opening pass and lunge): reds 5 —
  the two opening-swing tests, the adjacency-lunge test, and the two ranged
  lunge tests (their lunge pins ride the same path). Controls green:
  `step_monsters_test` adjacent-claw, all arrival-safety pins, the
  no-second-swing and bound pins.
- **M2** (`<= reach` → `< reach`): reds 4 — the two exactly-distance-3 shot
  tests and the two lunge tests (their shot lands at exactly reach). Controls
  green: the distance-2 shot test, adjacency-attack tests.
- **M3** (drop `visible.contains` from the reach test): reds 1 — the
  cannot-shoot-without-LoS test. Controls green: all open-LoS shot tests.
  *Note:* the first form of this pin reddened nothing (a hole, fixed in
  `a84e096`) because its fixture let the spitter sit beyond post-action
  reach; the pin now holds the walk itself.
- **M4** (codec: encode reach unconditionally): reds 2 — the golden save
  byte-identity test and the codec's decode-default test. Control green: the
  spitter reach-3 round-trip.
- **M5** (swap mana/unknown order in `_castRefusal, behaviorally): reds 2 —
  the unknown-before-mana order pin and the targeting group's ordering pin.
  Control green: every happy-path cast test. *Note:* no test pinned
  unknown-vs-mana when both applied; the missing characterization pin was
  added in `a84e096` and quoted green before the mutation ran.
- **M6** (spitter `reach: 3` → `1`): reds 1 — the content stat pin. The
  engine-side shoot tests did NOT red, and that is structural, not a hole:
  they pin the branch with their own fixture Actors (core cannot import
  content — the package dependency rule), so a content mutation cannot reach
  them. The spitter's declared reach is pinned content-side, where the
  mutation lives. `hasLength` pins green as ordered.

**8. Save format.** Golden save tests green before the codec change
(characterization) and green inside the codec commit; the omit-on-default
contract holds — the three v3 golden documents decode and re-encode
byte-identically with no `reach` key. A spitter round-trip pins `reach: 3`
written, `reach: 3` read back; a no-key document decodes `reach == 1`.

**9. Static.** From the worktree root, `pwd` quoted:

    /var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-battle
    dart analyze .   → No issues found! (run from the root over all packages)
    dart format --set-exit-if-changed .  → "Formatted 202 files (0 changed)",
        exit 0

Analyze and format run as ordered, from the root, tree clean before and
after (`git status --short` → only `.pi/`).

**10. What the tests cannot prove.** The bands measure a melee bot and a
casting bot on a headless engine over core+content — they cannot say anything
about the battle screen's look or feel, and no test here proves the UI is
good; that is unit B's work and the device ritual belongs to it. The casting
line is not apples-to-apples with the greedy line (different door, different
kit — stated where the pin lives, per the dispatcher's binding addition).
The LoS reach test reuses the hero's turn-start FOV as the sight proxy:
one-way sight pairs exist in the shadowcaster (verified by an exhaustive
symmetry probe on a fixture map — 40 asymmetric pairs), and the pinned test
can grant a spitter a shot from a tile the hero can see but the spitter
itself could not see the hero from. The test always errs toward the hero
seeing its shooter, never the reverse; the corner case is bounded to the
hero's one step per turn. The crypt floor sits exactly on its 0.40 floor at
16/40 — green by the ruling, one seed from red, and the trail says why.

**11. Spec claims checked and found wrong (or imprecise), with sources:**

- "the shallow-exempt set is not edited" — false as written; the set is
  computed (`_allCreatures().difference(_deepCreatures())`), so the named pin
  had to gain `'spitter'`. Ruled and promoted as D76.
- The crypt floor LAYOUTS stay frozen — true of terrain, but two pins the
  spec did not enumerate include the monster roster in their digest: the
  seed-4242 door pin was predicted, the three gathering digests (crypt 1 1,
  1 2, 909 2) were not. Enumerated and re-pinned with old values quoted.
- The LoS-reuse claim (`state.visible` + Chebyshev ≤ reach is a correct
  "can shoot" test) — asymmetric sight is real in the shadowcaster
  (40 one-way pairs found by probe, some at Chebyshev 3). The pinned test
  uses hero-sight, which errs safely (the hero always sees its shooter);
  the hole is bounded and documented, not fixed — the shape is the spec's.
- The spec's band prediction was too optimistic, per the trail: ambush +
  the ruled spitter landed below the suite's own fairness floor, and three
  content levers (D77 d2-drop, D78 hp-4, reach-2) measured insufficient or
  backwards before the user ruled the crypt-specific floor (D79).

**12. Phases.** Plan: ran (untracked file, main repo). Red: ran for every
behavior (ambush 3-red set, ranged 7-red set, targeting compile-red,
casting instrument-check red proven by policy-off toggle). Green: ran.
Refactor: light — the monster-swing branches were extracted into
`_monsterStrikes`/`_Strike` when the third caller (the lunge) appeared;
no other refactor warranted. Verification: ran (this block). Mutation: ran,
all six rows, both halves, tree verified clean after each. Trail: ran, seven
rows including every failed configuration. Skipped: none. One honest
deviation from the letter of TDD inside the casting-bot task: the policy and
its tests landed in the same editing session (the unused-element warning
stood in for red), so I proved red afterwards by disabling the policy and
re-running — the wrath pin reds `[0,0,0,0,0]` without the policy and greens
with it. The mutation table exists to catch exactly this kind of slip; it
ran after everything landed.

## Holds and rulings (all through the mailbox)

Three holds, all answered by the architect from the user: D76 (shallow pin —
approved), D77 (d2-drop — measured backwards, kept as a failed row), D78
(hp 7→4 — measured no movement), D79 (crypt floor 0.40, spitter stands as
D78). No lever was touched without a ruling; the trail keeps every failed
configuration as a row.

## Scope kept

No pushes, no PRs, no `tea, no device/emulator work, no app-package changes,
no commits under `docs/, bestiary changes limited to the spitter and its
ruled table rows. The app package's mirrored `castRefusal` is untouched; the
optional `targetId` keeps every call site compiling.