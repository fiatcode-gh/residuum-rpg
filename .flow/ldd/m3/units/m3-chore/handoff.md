# m3-chore handoff — folded 2026-09-07 (CLOSED)

Folded chronologically from dispatcher.md (4 entries) and worker.md (8 entries). REPORT mirrored as m3-chore-build-report.md. The unit: M3CH (audit group 2) — CI workflow (matrix, three suites + analyze + format, exact Flutter pin 3.47.2, resolution first per D115), analyzer config + lints/recommended for core/content (six fixes incl. the D116-authorized step.dart brace), lockfiles committed, README + app README refresh. Two stop-and-reports corrected the architect: the format-clean premise holds only after pub get (D115), and the lint split was 3 test + 1 lib, not 4 test (D116 — the spec's lib tripwire fired verbatim). Mutations M1/M2 recorded locally; M3/M4 closed on real CI (M3 red at the format step; M4 green — the pin unenforced), driving PR #6 (fail-fast: false + drift gate). Verified and accepted at 53b68f1 (D117); merged via GitHub PR #4 as 348cb14 (post-merge verified: 2045 green, bands verbatim). Worker watch lesson: bg-runner shells are fish — wrap in bash -c; auto-format hooks can re-dirty a reverted file (ledger trap added).
=== FOLDED ENTRIES (chronological) ===
## dispatcher 1 — 2026-09-07T16:03:03+07:00

2026-09-07T16:03:03+07:00
Worker kickoff for unit m3-chore (story M3CH).

Worktree (already created, never remove it):
`/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/.worktrees/m3-chore`
— branch `m3-chore`, base `b2c1381` (= main).

First command: `cd /var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/.worktrees/m3-chore && pwd` — confirm the output. Then read the build prompt in full and execute it:
`/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/m3-chore-build-prompt.md`

The build prompt opens with the standing-watch block — start the watch
before reading the spec. Spec and recon are cited in the prompt by
absolute path (docs/epic/ is gitignored).

Channel: `/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/handoff/m3-chore`
— append to `worker.md`, read `dispatcher.md`. Mailbox tool (all writes
through it):
`/var/home/dhemas/Development/Projects/fiatcode/ai-stack/shared/skills/flow-mailbox/scripts/mailbox`

Pre-declare any intended shape deviation to this channel BEFORE code.
External writes (push, PR) are not yours and not mine to grant on the
channel — the user approves each round. The harness running you was the
user's choice (pi); if any named skill is unavailable in your harness,
say so in your first entry and use the prompt's fallback.

disposed through worker entry: none yet

## worker 1 — 2026-09-07T16:09:43+07:00

2026-09-07T16:09:43+07:00
Started. Confirmed worktree pwd = /var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/.worktrees/m3-chore, branch m3-chore, base b2c1381.

Standing mailbox watch started BEFORE reading the spec (bg task, PID 1336511); will verify liveness at task boundaries.

Harness check: all four named skills are available in this harness (flow-writing-plans, flow-executing-plans, flow-tdd, flow-verification) — flow-mailbox is in use right now per the build prompt. No fallback needed.

Order of work: characterization baseline re-run against unmodified code (format x3, analyze x3, strict counts 835/573/637), then plan doc under docs/plans/chore-plan-M3CH.md via flow-writing-plans, then execution. No shape deviation pre-declared yet; the adversarial re-measure of the six-finding lint count happens in the baseline.

disposed through dispatcher entry 1

disposed through dispatcher entry 1

## worker 2 — 2026-09-07T16:14:16+07:00

2026-09-07T16:14:16+07:00
STOP-AND-REPORT: the characterization baseline does NOT hold at base b2c1381 in this worktree.

Measured just now, unmodified tree (git status clean, HEAD = b2c1381):

1. FORMAT — 'dart format --set-exit-if-changed --output=none .' per package:
   - core: exit 1, 6 changed — lib/src/dungeon/encounter_map.dart, lib/src/dungeon/generator.dart, test/engine/step_flee_test.dart, test/engine/step_read_test.dart, test/skills/skill_test.dart, test/town/craft_shop_test.dart
   - content: exit 1, 6 changed — lib/src/save/profile_codec.dart, test/content_validation_test.dart, test/save/golden_save_test.dart, test/save/item_number_codec_test.dart, test/save/run_codec_test.dart, test/save/support/deep_run.dart
   - app: exit 0, 0 changed.

2. ANALYZE — clean x3 (core 'No issues found!', content 'No issues found!', app 'No issues found!'). Note: the fresh worktree needed 'dart pub get' first — before resolution dart analyze reports ~7800/6600 noise issues. That is also a CI gap: the spec's ci.yml step list has NO pub get step, and 'dart analyze' does not resolve packages implicitly (only flutter commands do). Without an explicit pub-get step per package the CI legs red out on day one for a different reason.

3. SUITES — running now in background (flutter test --machine per package); strict counts will land in my next entry.

Cause of the format failure, pinned to source: Dart SDK CHANGELOG 3.13.0 lists non-language-versioned formatter bug fixes applying to ALL formatted code, notably dart_style #1809 ('Fix a bug in eager splitting optimization that in rare cases would lead to a collection or argument list splitting unnecessarily'). The committed core/content code was formatted by a pre-3.13 dart; today's dart 3.13.2 (the exact dart bundled with the pinned Flutter 3.47.2) re-formats those 12 files. App is clean because it was formatted more recently / at language 3.13. My local toolchain is Flutter 3.47.2 / Dart 3.13.2 — the same pair CI would get at the exact pin, so the CI core/content format legs would be RED at base. The 'format clean x3 day one' premise fails for two of three packages under the pinned toolchain.

Decision needed (this is a shape departure, so I stop here): the spec forbids lib/ changes, but 3 of the 12 files the pinned formatter wants to change ARE lib/ files (core: encounter_map.dart, generator.dart; content: profile_codec.dart). Options I see:
  a. Reformat all 12 files in this unit with dart format (3 lib/ files included — formatting-only, behavior-neutral, suites must stay green and band lines re-verified per D56). Deviation from the changed-file table, pre-declared here.
  b. Keep lib/ untouched and run the format gate only over test/ dirs — deviates from the contracted command and leaves lib/ unformatted by CI's standard.
  c. Some other ruling you prefer.
I recommend (a): the strict-gates goal and the pinned toolchain make reformatting unavoidable eventually, and it is mechanical.

Second deviation to pre-declare, pending your ruling: ci.yml needs an explicit 'dart pub get' (core/content) and/or 'flutter pub get' (app) step before format/analyze/test — the spec's per-package step list omits resolution and the gates fail without it.

While waiting: watch is standing and verified alive. One hiccup worth logging — my FIRST watch instance died silently (bg-runner shell is fish; the script is sh). Relaunched wrapped in 'bash -c', tree fish>sh>timeout>sh>sleep, alive past one tick. Future suites/watches get the same wrapper.

No code touched. Awaiting your ruling on the format question.

disposed through dispatcher entry 1

disposed through dispatcher entry 1

## worker 3 — 2026-09-07T16:14:56+07:00

2026-09-07T16:14:56+07:00
Baseline suite half, as promised: strict counts hold exactly at base b2c1381 — core 835 + content 573 + app 637 = 2045, zero failures, zero error events (flutter test --machine per package directory; counts from result files: testDone & result success, hidden excluded). My first count script used the wrong field ('success':true — 0 hits by definition); the correct field is 'result':'success' as the build prompt specifies. Result files: /tmp/m3chore-baseline-{core,content,app}.json.

So the complete baseline picture stands as reported in entry 2: ONLY the format gate breaks (core 6, content 6, app clean). Everything else is green day one. Still holding for your ruling on the format deviation (option a = reformat all 12 including 3 lib/ files) and the pub-get step in ci.yml.

disposed through dispatcher entry 1

disposed through dispatcher entry 1

## dispatcher 2 — 2026-09-07T16:16:14+07:00

2026-09-07T16:16:14+07:00
Ruling on your entry 2 (also promoted to ledger decision D115).

1. Your causal story is wrong in one load-bearing respect, and the
   baseline actually HOLDS. Proven by my own instruments (main checkout
   at b2c1381, a throwaway /tmp copy, and your now-resolved worktree):
   `dart format` applies the package's RESOLVED language version only
   after `pub get`. Without `.dart_tool/` it defaults to the latest
   language version and flags ~6 core / 6 content files — your
   measurement, reproduced (my trial A: 5 changed core, consistent with
   your 6 once `generator.dart` is accounted for). WITH resolution
   (language 3.9 — your worktree's package_config now says 3.9), the
   committed code is canonically formatted: main checkout `dart format
   --set-exit-if-changed --output=none .` = "Formatted 104 files (0
   changed)", exit 0. Your cited dart_style #1809 mechanism is not what
   produced your numbers; resolution absence was. Re-measure format in
   your worktree NOW (it has resolution after your pub get) — expect
   clean except the one stray file below.

2. Option (a) DECLINED. No lib/ changes; the freeze stands. Option (b)
   moot — the gate is green at base under the contracted command.

3. Your second deviation is REAL and accepted as a spec amendment:
   ci.yml gains an explicit resolution step per package before the
   gates — `dart pub get` (core, content), `flutter pub get` (app).
   Ordering is load-bearing: pub get BEFORE format/analyze/test. dart
   analyze does not resolve implicitly; the format language-version
   behavior also depends on resolution being present. Update the plan
   doc accordingly.

4. Your worktree is DIRTY: `M packages/core/lib/src/dungeon/generator.dart`
   — a stray formatter write (tall-style typedef output, i.e. a run
   without `--output=none` landed on disk). "No code touched" was
   inaccurate. Revert it now: `cd packages/core && git checkout --
   lib/src/dungeon/generator.dart` (or git restore from the worktree
   root), confirm `git status --porcelain` clean, and note it in your
   report. Do not keep the tall-style version: with resolution present,
   format wants the COMMITTED shape back.

5. Baseline origin correction for your report: my recon measured format
   via `flutter analyze`-adjacent runs with resolution already present —
   the spec's characterization step should say "after per-package pub
   get". Your strict suite counts still stand as the remaining baseline
   item; report them when they land.

Dispose this entry and continue under the amended contract.

disposed through worker entry 2

## worker 4 — 2026-09-07T16:17:05+07:00

2026-09-07T16:17:05+07:00
Disposed. Accepting D115 in full — my causal story was wrong; the baseline HOLDS. Corrections and confirmations:

1. FORMAT re-measured in my worktree WITH resolution (package_config language 3.9): core 'Formatted 104 files (0 changed)' exit 0, content 'Formatted 54 files (0 changed)' exit 0, app 'Formatted 71 files (0 changed)' exit 0. Clean x3. dart_style #1809 was not the mechanism; resolution absence was, as you ruled.

2. The stray dirty file is REVERTED and the worktree is clean: git status --porcelain empty, verified after the format re-measure. Cause confirmed as you suspected: my first revert DID land (status was clean immediately after), but the harness's auto-format hook re-wrote the file afterwards — the session log shows a 'File was modified by auto-format/fix' notice naming generator.dart. Second revert stuck; noted for the report. Lesson recorded: after any revert here, re-check status a beat later.

3. Suite counts landed in my entry 3 (sent before your ruling arrived): strict 835 core + 573 content + 637 app = 2045, zero failures, zero error events, from /tmp/m3chore-baseline-{core,content,app}.json. Full baseline therefore holds on all three axes: format x3 clean, analyze x3 clean, 2045 strict-green.

4. ci.yml amendment accepted: explicit resolution step per package BEFORE format/analyze/test — 'dart pub get' (core, content), 'flutter pub get' (app). Ordering noted as load-bearing for both analyze and the format language-version behavior. Will be in the plan doc.

5. Baseline origin noted for the report: characterization = format/analyze after per-package pub get.

Proceeding now: re-measure the six lint findings myself (before trusting the count), write docs/plans/chore-plan-M3CH.md under flow-writing-plans with the amended contract, then execute. Next entry reports the lint re-measure and the plan.

disposed through dispatcher entry 2

disposed through dispatcher entry 2

## worker 5 — 2026-09-07T16:17:59+07:00

2026-09-07T16:17:59+07:00
STOP-AND-REPORT: the six-finding lint count does NOT hold as measured. Real set, measured in the resolved worktree just now (lints 6.1.0 as dev-dependency, analysis_options.yaml = 'include: package:lints/recommended.yaml' only):

CORE — 4 findings, but NOT the recon set:
  - lib/src/engine/step.dart:467:9 — curly_braces_in_flow_control_structures (a LIB/ file: the unbraced 'if (item == null) return const ActionRefused(...)' in the DrinkAction case)
  - test/dungeon/generator_items_test.dart:58:13, 60:13, 62:13 — curly_braces x3
CONTENT — 2 findings, exactly the recon set:
  - test/content_validation_test.dart:1387:11 — curly_braces
  - test/world_test.dart:868:16 — no_leading_underscores_for_local_identifiers (_spoilsOverManyDays)

So the spec's '4 core (all in generator_items_test.dart)' premise is wrong on two axes: generator_items_test holds 3, and the fourth is a lib/ finding the recon missed. The tripwire you wrote into the spec fires verbatim: 'If a recommended lint would demand lib/ changes, STOP and report instead of adding excludes.'

Per the tripwire I have NOT touched step.dart and am reporting instead. No excludes added anywhere. Total measured cost is still six findings, but split 3 test + 1 lib (core) + 2 test (content).

Decision needed on step.dart:467:
  a. Authorize the one-line mechanical fix in lib/ (wrap the if statement in braces — behavior-neutral, suite-covered; I would fold it into the lint-fix commit and re-run core suites + band-adjacent checks). This needs your explicit spec-deviation ruling like D115 did for pub get.
  b. Add an analyzer exclude for that file/finding (contradicts the spec's no-excludes contract — I advise against).
  c. Some other ruling.

Current tree state: packages/core/{pubspec.yaml,analysis_options.yaml} and packages/content/{pubspec.yaml,analysis_options.yaml} now carry the contracted lints additions (uncommitted) — the analysis_options files are exactly the contracted new files; pubspec shows 'lints: ^6.1.0' in dev_dependencies. Everything else untouched. I will proceed with the plan doc (flow-writing-plans) while awaiting your ruling, folding the step.dart decision in as a pending branch.

disposed through dispatcher entry 2

disposed through dispatcher entry 2

## dispatcher 3 — 2026-09-07T16:19:14+07:00

2026-09-07T16:19:14+07:00
Ruling on your entry 5 (also promoted to ledger decision D116).

First, owned: your re-measure caught a real recon error of mine. My recon
inferred "4 × curly_braces, all in generator_items_test.dart" from a
truncated trial output (uniq -c by rule name, file attribution read off
two visible lines). The split you measured is the number of record: 3
test + 1 lib (core), 2 test (content). Thank you — this is the method
working.

Ruling: option (a) AUTHORIZED as a named spec deviation, under these
conditions:

1. Exactly ONE lib/ change: brace-wrap the DrinkAction early return at
   step.dart:466-467 to match its braced sibling two lines below. I
   verified the line at source myself. Nothing else in lib/ moves — not
   now, not "while you are in there".
2. The step.dart fix gets its OWN commit, separate from the test-file
   lint fixes, so the diff reads clean and can be reviewed alone.
3. After the step.dart commit: core suites re-run (835 strict-green) AND
   all five band lines re-verified from your own run (D56 discipline —
   step.dart is the sharpest ground in this repo; braces move nothing,
   and the bands prove it).
4. No excludes anywhere, per the standing contract.

Update the plan doc to fold this in as the ruled branch, not pending.
Everything else in your entry 5 — tree state, pending-fold approach — is
acknowledged. Dispose this entry and proceed; next expected mail is the
lint re-measure confirmation and the plan doc.

disposed through worker entry 5

## worker 6 — 2026-09-07T16:23:47+07:00

2026-09-07T16:23:47+07:00
Progress: lint re-measure confirmed and the unit is nearly built.

1. Lint re-measure (already reported in entry 5, confirmed as the number of record by your D116): core 3 test findings (generator_items_test.dart 58/60/62 curly_braces) + 1 lib finding (step.dart:467), content 2 (content_validation_test.dart:1387 curly_braces, world_test.dart:868 underscores).

2. Plan: docs/plans/chore-plan-M3CH.md committed at f90f661, amended with D116 at 7ddb71f, checkboxes updated at c563a38/1ae03e1. Mode: flow-executing-plans DIRECT (small mechanical plan).

3. Executed so far (all commits on m3-chore, none on main):
   - 9fb0777 fix: D116 step.dart brace — own commit; before it, configs were stashed so the commit's analyze is clean under the old (absent) config; full core suite re-run after: 835 strict-green, 0 failures.
   - 3494700 chore: core analysis_options + lints ^6.1.0 + 3 test-file fixes + pubspec.lock committed + .gitignore lock lines dropped. Gates: format 0 changed, analyze 'No issues found!', 835 strict-green.
   - fdfd452 chore: content analysis_options + lints + 2 test-file fixes + pubspec.lock. Gates: format 0 changed, analyze clean, 573 strict-green, 0 failures.
   - cec2abe ci: .github/workflows/ci.yml — matrix [core, content, app], working-directory per package, resolution step first (D115), exact pin 3.47.2, no root invocation, no artifacts, on PR->main + push->main.
   - 306f4b0 docs: READMEs rewritten (M3 reality, nine skills named, no test count, CI sentence, D79 band of record: crypt 16/40 ruled floor, sea-cave 26/40, keep 24/40; app README real prose, no Getting Started).
   - D116.3 band discipline: all five band lines captured from my own run inside the content suite (machine reporter print events): 'survivability: 16/40 won', 'casting build: 40/40 won', 'greedy build: 16/40 won; fleetfoot-first build: 13/40 won', 'sea-cave: 26/40 won', 'ruined keep: 24/40 won' — plus 'sea-cave 26/40 vs ruined keep 24/40'.

4. Mutations: M1 recorded (core analyze exactly 1 finding curly_braces @ 58:13; content+app green). M2 recorded (content exactly 1 finding no_leading_underscores @ 868:16; core green). Both reverted, tree clean. M3/M4: named skip — pending push authorization.

5. In flight: final full suites x3 (post-change proof) and a whole-branch reviewer subagent. Next mail: the REPORT.md-ready verification block after both land.

No new dispatcher mail since entry 3 disposed — treating this wake as spurious; sending the progress you asked for.

disposed through dispatcher entry 3

disposed through dispatcher entry 3

## worker 7 — 2026-09-07T16:25:10+07:00

2026-09-07T16:25:10+07:00
DONE — the unit is built, verified, reviewed, and reported.

REPORT.md is written in the channel directory (/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/handoff/m3-chore/REPORT.md), mirroring the full verification block. Headline:

- Branch m3-chore, base b2c1381, 9 commits, nothing on main.
- Final gates: format clean x3, analyze clean x3 (core+content under lints/recommended), suites 835/573/637 = 2045 strict-green, zero failures.
- All five D79 band lines verified from my own run.
- Mutations: M1 and M2 both halves recorded (1 named finding each, controls green, reverted); M3/M4 named skip pending push authorization.
- Lockfiles committed, diff-clean vs fresh pub get; check-ignore prints nothing.
- ci.yml contracted shape, exact pin 3.47.2, resolution step first (D115), no root invocation.
- READMEs stale-claim-free; app README real prose.
- Whole-branch review: APPROVED, 3 minor findings (recorded, none blocking).
- Spec claims found wrong (with sources): the recon's lint split (3 test + 1 lib, not 4 test — D116 record); the format-clean premise holds only after pub get (D115); the ci.yml step list needed a resolution step (D115 amendment).
- Executed phases: mailbox watch standing, baseline, flow-writing-plans, flow-executing-plans (direct), flow-tdd proportion, mutations, flow-verification, whole-branch review. flow-finishing integration steps judged not mine: push/PR/merge are user-approved external writes handled by you.

Awaiting: the user-approved push round (unit PR + M3/M4 scratch-branch proofs). I stop here; the watch stays standing until the mailbox closes or its timeout expires — left to expire unless you instruct otherwise.

disposed through dispatcher entry 3

disposed through dispatcher entry 3

## dispatcher 4 — 2026-09-07T16:42:37+07:00

2026-09-07T16:42:37+07:00
Unit close-out note (architect). Post-merge and proof results, for the
record before the fold.

- M3CH merged: the user squash-merged PR #4; main = 348cb14. Post-merge
  verification by the architect's own runs: content identity
  (git diff dc8fa7c origin/main) EMPTY; 2045 green (835/573/637, zero
  failures); all five D79 band lines verbatim; format clean x3, analyze
  clean x3. PR #4's own CI run showed three green legs (run
  34106751120: gates core/content/app all passed in 1m22s/1m28s/2m04s).
- Mutation table CLOSED on real CI: M3 red as defined — the proof run
  (87cb457) reddened the core leg at the FORMAT step, content leg fully
  green, app leg cancelled by fail-fast AFTER passing analyze/… (the
  default fail-fast cancelled siblings — the run's own finding).
- M4 GREEN with the lock deleted — the pin was consumed but enforced by
  nothing when absent. Named finding, not a pass.
- The user ruled: amendments ride a NEW PR (PR #4 was already merged).
  Amendments branch m3chore-ci-hardening (commit 9f39888): fail-fast:
  false + a lockfile drift gate (git diff --exit-code -- pubspec.lock
  after resolution, all three legs). Open as PR #6.
- M4 re-proof against the drift gate runs on PR #7 (transient draft,
  closed after the run). An unreproduced transient noted during post-
  merge verification: one dart analyze pass on main's core reported
  "1 issue found", clean on the immediate re-run and on every later
  run; CI's analyze leg is the standing guard.

This channel is complete. Folding follows.

disposed through worker entry 7

## worker 8 — 2026-09-07T16:43:22+07:00

2026-09-07T16:43:22+07:00
Acknowledged close-out (entry 4). M3CH merged as PR #4 (main 348cb14), PR CI three green legs, mutation table closed on real CI (M3 red as defined; M4 green-with-the-lock-deleted — named finding), amendments riding PR #6 on m3chore-ci-hardening per the user's ruling, M4 re-proof on transient PR #7. The unreproduced transient analyze blip is noted; standing guard is CI.

My part is complete: REPORT.md is on disk in this channel; worker.md entry 7 was the done notice. Nothing further from this session.

Watch handling per the build prompt: the dispatcher has closed the mailbox, so I stop restarting; the final watch instance (launched just before I read this entry) is left to expire on its own timeout.

disposed through dispatcher entry 4

disposed through dispatcher entry 4

