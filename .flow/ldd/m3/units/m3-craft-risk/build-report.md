# m3-craft-risk — worker report

Worker session, worktree `/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/.worktrees/m3-craft-risk`,
branch `m3-craft-risk`. Dispatched per `docs/epic/m3-craft-risk-build-prompt.md`
against spec `docs/epic/m3-craft-risk-spec-M3CR.md`.

## Worktree proof

`git log --oneline main..HEAD` (run from inside the worktree, cd-then-git):

```
e99025b style: dart format
9515fea docs: plan progress through the mutation table
8a51edc test(core): the tier-1 cannot-fail pin forces a failing roll
3439fa7 feat(content): craftRngState rides the codec omit-on-default
eab8527 test(core): the crawl never feels a craft roll
dedf067 feat(core): a temper or a brew can fail, and it costs one material
55f93dd feat: tempering is paid in iron, not gold
1fd5fbb feat(core): the craft odds table and the craft stream
62cd690 feat(core): craftRngState rides the profile
bb83e68 docs: m3-craft-risk implementation plan
```

Every commit lands on `m3-craft-risk` only. Nothing under `docs/epic/` was
committed. Working tree clean at report time.

## Test counts (strict, hidden-filter arithmetic, measured fresh at close)

Baseline measured fresh on unmodified `e0544f4` at task 1 — **2045 green
(core 835 + content 573 + app 637)**, matching the carried-forward D118
baseline exactly. Final, after the unit's work:

| package | strict green | vs baseline |
|---------|-------------|-------------|
| core    | 860         | +25         |
| content | 579         | +6          |
| app     | 638         | +1          |
| total   | **2077**    | +32         |

Zero failures in every full-suite run. Counts from
`grep '"type":"testDone"' | grep '"result":"success"'` minus `"hidden":true`
over `flutter test --reporter json` result files.

## Characterization proof

Task 1: all three suites ran green against the UNMODIFIED worktree
(`git status --porcelain` empty, `e0544f4`) before the first change. The band
trail and golden save test were green in that same run. Named run: baseline
bg task, result files `/tmp/m3cr-core.json`, `/tmp/m3cr-content.json`,
`/tmp/m3cr-app.json`.

## The mutation table (all seven rows run; reds as named sets)

- **M1 — failure unreachable** (`craftDraw` returns `failed: false`): RED in
  `craft_shop_test.dart` — {'takes the brew's herbs and makes no potion',
  'advances the craft stream exactly once', 'leaves the item where it was',
  'loses exactly one ingot, not the tier's price'}. GREEN restored.
- **M2 — tier 1 exposed** (`1 => _tabled(20, blacksmithLevel)`): RED in
  `craft_shop_test.dart` — {'a tier-1 temper cannot fail and spends its full
  ingot'}. The original test's forced state rolled high, so it was
  strengthened to `stateRollingUnder(20)` (commit 8a51edc) before the
  mutation bit. GREEN restored.
- **M3 — floor dropped** (`_tabled` without the `max`): RED in
  `risk_test.dart` — {'every level takes two points off, floored at five',
  'the floor clamps at five and never below'}. GREEN restored.
- **M4 — brew gated** (`herbcraftLevel < 5 ? 0 : ...`): RED in
  `risk_test.dart` — {'level 0 brews at twenty, and no gate stands in the
  way'}. GREEN restored.
- **M5 — full price on failure** (failure branch spends `-price.ingots`):
  RED in `craft_shop_test.dart` — {'loses exactly one ingot, not the tier's
  price'}. GREEN restored.
- **M6 — crawl stream touched** (`craftDraw` draws `Rng(profile.worldSeed)`
  and writes nothing back): RED in `risk_test.dart` — all four `craftDraw`
  tests ('lazy-seeds off the world seed', 'advances from the carried state',
  'advances exactly once even when the tier cannot fail', 'answers failure
  below the odds'). **The spec's named red set did not redden**: the
  roll-for-roll test stayed green, because a `Profile` carries no crawl
  stream — a craft draw from a throwaway `Rng(worldSeed)` cannot shift a
  resumed crawl, so at this boundary the mutation is unrepresentable in the
  shape the spec describes. The corruption the hazard warns about (drawing
  from the live run's `rng` while camped) is unreachable from a pure
  profile-in/profile-out transaction; the roll-for-roll and resume tests
  (`craft_stream_test.dart`) stand as the tripwire for any future change
  that widens the boundary. Spec-claim finding; see below.
- **M7 — gold sneaks back** (`gold: drawn.gold - 10` in the temper success
  path; `profile.gold < 10` check back in `temperRefusal`): RED in
  `craft_shop_test.dart` — {'spends the tier's ingots, and gold changes
  hands nowhere'} — and in `temper_test.dart` — {'a broke hero with the iron
  in hand is not refused on the purse'}. The forge price line cannot render
  a gold term (the app compiles against `TemperPrice` without a gold field),
  and its widget pin ('Next tier: 1 ingot.') is green. GREEN restored.

After every restore: `git status --porcelain` re-checked a beat later —
clean (no auto-format re-dirty).

## Band trail + goldens

Fresh run at close, byte-identical to the Task 1 baseline:

```
survivability: 16/40 won (40.0%), stalled 0, died at 1:1 2:9 3:8 4:6 5:16
casting build: 40/40 won
greedy build: 16/40 won; fleetfoot-first build: 13/40 won
sea-cave: 26/40 won (65.0%), stalled 0, died at 2:3 3:7 4:14 5:11 6:5
ruined keep: 24/40 won (60.0%), stalled 0, died at 1:5 2:5 3:3 4:2 5:13 6:7 7:5
sea-cave 26/40 vs ruined keep 24/40
```

Crypt 16/40, casting 40/40, greedy 16 / fleetfoot 13, sea-cave 26/40, keep
24/40 — all five lines match. The bot never crafts; this is the proof.
Golden save test (`golden_save_test.dart`) green throughout — the three
pinned v3 documents are string constants; the green test is the
byte-identity proof. `dungeon_door_characterization_test.dart` green
throughout (the crypt tripwire never reddened).

## Format/analyze

`dart pub get` per package first (caught the app and content stale-resolution
trap twice — D115 is real), then `dart format --output=none
--set-exit-if-changed lib test` and `dart analyze`: **clean ×3** after one
formatting pass landed 7 files (5 core, 2 content) in commit e99025b.

## Execution phases

All plan tasks ran: 1 characterization baseline, 2 profile field, 3 odds +
draw, 4 gold retirement, 5 failure paths, 6 stream discipline, 7 codec +
salt sweep, 8 bench notice + price line, 9 verification. Two notes: (a) Task
8's code rode earlier commits because the type change forced the bloc
widening and the gold retirement forced the price line — each landed with
its own red; (b) the salt sweep (`craftSeedSalt = 0x0C7A`) passed on its
first run — it is the salt's evidence, not a red-green target. Direct mode
throughout (no implementer dispatches): small, tightly interlocked tasks on
shared files, judged by flow-executing-plans' complexity rule.

## What the tests cannot prove

- The device pass (below) is the only thing that exercises the real forge
  screen on real Android; bloc/widget tests cover the notice line and price
  line at test-viewport size.
- The collision sweep covers 7 fixture seeds × 64 early rolls — it proves
  the craft stream does not run in step with the loot stream on the seeds
  the pins stand on, not for every possible world seed.
- The codec round-trip proves state survival through encode/decode, not
  through an OS-level process kill (the device save ritual covers that path
  manually).

## Spec claims checked and found wrong

1. **M6's named red set is unrepresentable** (see the mutation table): a
   profile-carried craft stream means the crawl's streams are not in reach
   of a craft draw, so "draw from the crawl's rng" cannot corrupt a resume
   from inside the transaction. The red set is the craftDraw unit tests;
   the roll-for-roll test guards the boundary regardless. (Source: spec
   test plan, M6 row; measured against the actual code.)
2. **M1's "leaves the item at +0"** cannot be literal — an item at +0 is a
   tier-1 attempt, which never fails. Read as "the item does not gain its
   tier"; the test works from +1. Pre-declared in mailbox entries 2–3.
3. Nothing else. The central contract held under attack: no boundary drops
   `craftRngState` (copyWith carries it; `endRun`/`suspendRun` go through
   copyWith; `resumeRun` is town-side by design and the grep confirmed the
   field survives every profile copy).

## Pre-declared rulings (mailbox entries 2–4, before any code)

1. Failure rides a sealed `TownAnswer` base (`TownRefusal` | `CraftLoss`),
   keeping `Crafted` a 2-tuple; entry 3 corrected entry 2's third-slot
   design before any code existed.
2. M1's "+0" reading (above).
3. On a failed attempt the loss sentence wins the notice slot over a
   simultaneous level-up.
4. The brew odds and one-attempt-one-advance accepted as written, with the
   argument recorded.

## Device acceptance — DONE

The sandbox could not boot the AVD (four SIGSEGVs, exit 139, during guest
boot — the known unsandboxed-commands trap); the user started the AVD
themselves and the pass ran against it, pinned to `emulator-5554`.

- **Save ritual**: both slots (`app_flutter/save.json`,
  `app_flutter/save-previous.json`) copied aside via `run-as cat` BEFORE any
  install — sha256 `18dbf676…` and `4b6f8e29…`, re-verified on device after
  the copy. Install used `adb install -r` (kept data; no uninstall needed —
  /data had 731 MB free at 88%).
- **Build**: debug APK 153,656,716 bytes, `flutter build apk --debug`.
- **Acceptance save**: the launch itself resumed the user's live crawl
  (wounded hero engaged) — force-stopped with no game action taken, saves
  verified unchanged. The acceptance state was then crafted FROM the user's
  own hero (town at home node, `run` null, 2 ingots added) and pushed via
  `run-as` stdin; the v3 codec read it cleanly.
- **The shot**: `forge-bench-greyscale.png` in this directory — the forge
  bench on the acceptance state, worn Rusty Sword row, price line
  **"Next tier: 1 ingot."** with no gold term anywhere; rarity as a mark,
  worn as a word, counts beside markings — legible in greyscale.
- **Restore**: app force-stopped, both slots restored byte-exact
  (sha256 `18dbf676…` / `4b6f8e29…` — identical to the pre-touch readings),
  staging files removed from /data/local/tmp. The user's playtest crawl
  resumes exactly where it stood; the app is left closed, as it was found.