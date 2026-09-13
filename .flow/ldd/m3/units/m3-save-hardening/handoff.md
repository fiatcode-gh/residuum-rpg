# m3-save-hardening handoff — folded 2026-09-07 (CLOSED)

Folded chronologically from dispatcher.md (11 entries) and worker.md (8 entries). REPORT mirrored as m3-save-hardening-build-report.md; AVD shots mirrored to docs/reports/shots/m3-save-hardening/ (42 files). The unit: M3SH — the save pipeline stops failing silently: write-path reporting (renames inside the failure handling, queue error sink, refuse-to-advance on a failed roster save with a rewired autosaver), guarded boot with the app's first failure screen, thrown-read fallback repair, decode range checks in the SaveMalformed style (speed ≥ 1, energy 0..1000, gear-inclusive hp ceilings per P1, skill ranges, reach as a real check, duplicate item ids refused per the amended D108 ruling), the engine-boundary guard, IoSaveFiles temp-dir coverage, the door in-flight guard, sealed SaveNotice and TownCrawl values, and the TTC-7/TTC-9 riders. Verified and accepted at 44c85cd (D111); merged via GitHub PR #3 as b2c1381 (post-merge verified: 2045 green, bands verbatim). Deviations P1–P8 pre-declared and acked; two mid-build deviations disclosed (RunSuspended carries the dungeon; the town's notice renders at the doors). Channel trap on record: three body lines shaped like entry headers were repaired by one-space indent at the user's direction.

=== FOLDED ENTRIES (chronological) ===

## dispatcher 1 — 2026-09-04T13:53:46+07:00

Dispatch — unit `m3-save-hardening`, story M3SH, branch `m3-save-hardening` off `main` @ `d2b78be`.

Your binding instruction is the build prompt at
`/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/m3-save-hardening-build-prompt.md`.
Read it in full; it carries your standing watch block, the spec path, the
mutation table, the must-not list, and the evidenced verification block.

Key facts: the worktree is already created at
`/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/.worktrees/m3-save-hardening`
(do NOT create it). Baseline: 1974 green (core 835, content 550, app 589),
verified post-merge by the architect; measure your own fresh baseline on
unmodified `d2b78be` before changing anything.

The mailbox tool you must use for every write to this channel:
`/var/home/dhemas/Development/Projects/fiatcode/ai-stack/shared/skills/flow-mailbox/scripts/mailbox`
(append to `worker.md`, read `dispatcher.md`, mirror your verification block
to `REPORT.md` in this directory at the end). Your ordinary printed output
reaches nobody — printing is not replying.

Pre-declare every intended shape deviation in `worker.md` BEFORE building
the affected piece; attack the spec's central claims by measurement and
disagree in the open — that is expected behavior, not a nuisance.

## worker 1 — 2026-09-04T14:11:03+07:00

 ## Kickoff — baseline measured, spec attacked, pre-declarations

Baseline measured FRESH on unmodified `d2b78be`, per package directory:
core 835, content 550, app 589 — 1974 green, all passing. Matches your count.

Worktree confirmed: `git rev-parse --show-toplevel` names
`…/residuum-rpg/.worktrees/m3-save-hardening`. Watch standing as a harness
background task (bg_run id bd887e22d, PID verified alive).

 ## Spec-attack results (measured, sources cited)

1. **Goldens vs every proposed check — re-verified by reading the three
   golden literals in `golden_save_test.dart`.** Town: profile hp 14 ≤ 20,
   levels ≤ 4, xp ≥ 0, ids drop-3/kit-2/drop-1 distinct, reach absent. Run:
   hero 13/20 speed 10 energy 100, ghoul 5/12 speed 10 energy 40, run skill
   levels ≤ 2, pack ids kit-2/kit-3 distinct. Two-heroes: hp 20/20, all
   levels 0, pack ids distinct per hero. **All pass every proposed check —
   nothing would move a golden or a band.** One nuance under "hp ceiling"
   below.
2. **Energy bound arithmetic — holds, value 1000 confirmed safe.** Sweep of
   content: monster speeds are {5, 10, 20} (`bestiary.dart`), monsters spawn
   at `energy: actThreshold` (bestiary.dart:82), and standing energy between
   actions is < actThreshold + speed (energy.dart drains exactly actCost when
   ready). Real maximum ≈ 99 + 20 = 119 for monsters; hero with gear ≈
   99 + (10 + 2·n speed affixes) ≈ low hundreds worst case. Bound 1000 =
   10× actThreshold: E/actCost = 10 scheduled turns for a forged document.
   No legal value approaches it. Confirmed the recon's re-pricing: huge
   energy is unbounded work, not an infinite loop; speed ≥ 1 is the hang fix
   (hero speed 0 never reaches actThreshold — infinite loop; monster speed 0
   throws ArgumentError out of `scheduleMonsterTurns` — both refused by
   speed ≥ 1 at decode).
3. **Thrown read:** what can actually throw from `IoSaveFiles.read` today is
   `_path`'s `getApplicationDocumentsDirectory()` (`MissingPlatformDirectoryException`)
   — confirmed outside the try (save_files_io.dart:54–56, read calls _path at
   line 20). `existsSync`/`readAsString` raise `FileSystemException`, already
   caught. **Pre-declared shape:** BOTH fixes, as the spec says — the adapter
   maps every failure to null (the real fix), AND `_readable` gains a try so
   the store honours "read never throws" against ANY SaveFiles
   implementation. The store-side guard is NOT dead code: it is tested via a
   new throw-injection on `MemorySaveFiles` (`throwReadsTo`, following its
   existing `failReadsTo` style — a fake whose read throws is what an
   implementation that ignores the contract looks like). Say if you want only
   the adapter fix and the guard dropped.
4. **Door reentrancy:** will attempt the bloc/widget reproduction (PumpedApp
   harness pumps the real app; a refused resume leaves `firstWhere` pending
   and a later `run != null` emission completes it — that sequence is
   drivable). If the on-device timing window itself stays unproven I will say
   so and pin the guard by the test that IS writable.
5. **Refuse-to-advance strands nobody — BUT there is a second defect hiding
   in that path.** `_openRoster` closes the autosaver BEFORE calling
   `_rosterChose`. If the roster save fails and the session refuses to
   advance, the old session continues with its autosaver PERMANENTLY closed —
   every later change in that session would go unwritten, silently. A refusal
   that only keeps the roster up leaves a session with no save machinery.
   Pre-declared shape below (rewire).
6. **Profile-side hp check — the spec's simple form would refuse LEGAL
   saves.** `decodeProfile` rebuilds the hero from `newProfile` (maxHp 20,
   confirmed), BUT a hero's real hp ceiling is `heroMaxHp` = baseline + worn
   maxHp affixes (`loadout.dart:111`; an affix with `maxHp: 6` exists,
   affix_pool.dart:52), and BOTH `restAtInn` (heals to `profile.maxHp`,
   gear-inclusive) and `endRun(died: true)` (wakes whole at `stripped.maxHp`)
   legitimately put hp ABOVE the bare 20 baseline into the profile — and into
   the run block's hero actor (saved mid-crawl at up to 20+6). A blanket
   `hp ≤ maxHp` on actors, or `hp ≤ rebuilt-baseline` on profiles, would
   refuse a legal save of any hero wearing +maxHp gear above 20 hp.
   **Pre-declared shape:** the hp ceiling check is gear-inclusive everywhere —
   profile: `hp ≤ heroMaxHp(rebuilt hero, decoded equipment)`; run hero
   actor: `hp ≤ heroMaxHp(hero, run block's own equipment)`; monsters: plain
   `hp ≤ maxHp` (no gear, spawn hp = maxHp, hp only falls). `hp ≥ 0` for all.
   This still passes all goldens (14≤20, 13≤20, 20≤20, 5≤12).
7. **Duplicate-id check vs the version gate:** confirmed `decodeSave`
   (save_codec.dart:151–173) checks the version BEFORE `_decodeRoster`, and
   every new check lives in deep decoders — pre-v3 documents stop at the gate
   with the gate's own reason, untouched. **Pre-declared scope for
   uniqueness:** per hero — profile equipment + inventory + bank pairwise
   distinct; run block equipment + inventory pairwise distinct. Bank is
   included (a duplicate across vault and pack breaks deposit/withdraw by id
   the same way a pack repeat does); litter (`groundItems`) and the merchant
   block are never compared, per spec. Run vs profile are not cross-compared
   (the run's pack is a frozen copy; resume takes the profile's side).

 ## Pre-declared shape deviations (awaiting your ack before the affected pieces land)

- **P1 — hp ceiling gear-inclusive** (from finding 6): the three-part check
  above instead of one blanket `hp ≤ maxHp`. Affects the codec piece.
- **P2 — boot.dart roster functions return `Boot?`**: `createHero`,
  `switchHero`, `replaceOnlyHero` return null when the save did not land
  (parallel to `deleteHero`'s null); `bootFrom` keeps booting with the
  failure carried on `Boot.notice` (composed with the load report when both
  exist). Affects item 1.
- **P3 — roster refusal keeps the session alive by rewiring the autosaver**:
  on a failed roster save, `_openRoster` builds a FRESH `Autosaver` seeded
  from the live document (`Boot(document: _saver.document)` before close),
  re-attaches `watchTown`/`watchWorld`, and re-pushes the roster screen with
  the failure notice on it. The session is not rebuilt (the boot copy is
  stale — rebuilding would hand the hero back their spent gold). Consequences:
  `_SessionState._saver` becomes non-final; `_rosterChose` returns the
  `Boot?` outcome; `RosterScreen` gains an optional `notice` sentence
  rendered as its first child (a `Notice` widget). The roster "stays" as a
  re-push with the notice; the player can retry or back out. Affects item 1.
- **P4 — sealed notice named `SaveNotice` with FOUR variants**, not three:
  `load` (boot/fallback sentences), `saveWriteFailed`, `resumeRefused`, and
  `refused` — the generic sentence variant the spec itself offers, needed
  because the town/world `notice` fields carry existing transactional
  refusal sentences (`TownRefusal.reason`) on the same channel; converting
  only the notice channel per spec means those sentences need a variant to
  ride in. Renders identically (`— sentence.`); the sealed type exists so
  illegal shapes are unrepresentable and future variants can differ. Affects
  item 7.
- **P5 — TownViewState crawl value named `TownCrawl?`** with variants
  `CrawlOpening(run, dungeon)` (the one-shot instruction) and
  `CampStanding(crawl, dungeon, campDay)` (the fact); `null` is "none". The
  four named convenience getters (`run`, `suspended`, `dungeon`, `campDay`)
  remain as derived getters so reader sites and ~204 test lines stay
  readable; the 9 construction sites are rewritten onto the sealed value.
  Affects item 8.
- **P6 — door in-flight guard IGNORES a second door event while an opening
  is pending** (no refusal notice): the buttons are disabled while pending
  (spec item 6), so the guard is belt-and-braces against a race the screen
  already refuses to show. `_openAnswer` waits on
  `firstWhere((s) => s.run != null || s.notice != null)` so the
  resume-refusal emission resolves the wait; the subscription is cancelled on
  unmount. Affects item 6.
- **P7 — MemorySaveFiles gains `throwReadsTo`** (read throws instead of
  returning null) to test the store-side thrown-read fallback. Follows the
  fake's existing failure-injection style. Affects item 2.
- **P8 — `BootFailureScreen` + guarded boot live in `main.dart`** as a
  testable `Future<Widget> guardedBoot(...)` that `main()` awaits; the test
  pumps its result directly. Fixed safe sentence, one **Begin fresh** action
  that re-runs the guarded boot; a second throw re-renders the screen with
  the same sentence. Affects item 2.

Nothing is built against P1–P8 until your ack. Everything else follows the
spec literally. Plan document next (uncommitted, `docs/plans/`), then
characterization tests against unmodified `d2b78be`.

## dispatcher 2 — 2026-09-04T14:12:06+07:00

Ack — P1 through P8 all accepted. Build the affected pieces.

- P1 ACCEPTED (hp ceiling gear-inclusive). I re-verified your finding 6 with
  my own grep: `heroMaxHp(hero, loadout)` at `town/profile.dart:121` makes
  the profile ceiling gear-inclusive, and `affix_pool.dart:52` carries
  `maxHp: 6` — the spec's blanket `hp <= maxHp` would refuse legal saves of
  any hero wearing +maxHp gear. Your three-part check (profile gear-inclusive,
  run hero gear-inclusive, monsters plain) is the contract; the spec's simple
  form is superseded. This correction is being promoted to the ledger.
- P2 ACCEPTED. `Boot?` returns, boot keeps booting with the failure on
  `Boot.notice`.
- P3 ACCEPTED, and I verified the underlying defect myself: `_openRoster`
  closes the autosaver at `main.dart:314` before `_rosterChose` can refuse —
  your rewiring (fresh Autosaver seeded from the live document before close,
  re-attached watchers, re-pushed roster with the notice, `_saver` non-final,
  no session rebuild) is the right minimal fix. Your stale-boot-copy argument
  is correct.
- P4 ACCEPTED — `SaveNotice` with the fourth generic `refused` variant; the
  spec offered exactly this.
- P5 ACCEPTED — `TownCrawl?` with `CrawlOpening`/`CampStanding`, convenience
  getters remain, 9 construction sites rewritten. One binding note: the
  one-shot semantics of `run` ("an instruction rather than a fact") must be
  stated on `CrawlOpening`'s dartdoc — it must survive the type change.
- P6 ACCEPTED with one binding note: when the firstWhere resolves on a
  NOTICE-ONLY emission (no `run`), `_openAnswer` must bail — no
  `_openCrawl`, no push. State that in the `_openAnswer` dartdoc. The
  spurious-resolution risk (an unrelated refusal notice landing between the
  door event and the resume emission) is acceptable under the in-flight
  guard — pin whatever you build with the door test.
- P7 ACCEPTED — `throwReadsTo` on the fake, store-side guard stays (your
  argument that it honours the contract against ANY SaveFiles implementation
  is the right reason).
- P8 ACCEPTED — `guardedBoot` in `main.dart`, test pumps its result.

Your spec-attack results 1, 2, and 7 (goldens pass; energy bound 1000 with
the real-max sweep; uniqueness sits after the version gate) are all confirmed
against the recon — no further ruling needed. Proceed: plan document next,
characterizations green on unmodified `d2b78be`, refusal fixtures as their
own commit before the codec change.

## dispatcher 3 — 2026-09-04T15:26:46+07:00

Noted and accepted: the fourth `SaveNotice` variant is named
`SentenceNotice` (not a `refused`/`RefusedNotice` name) — the forge
level-up announcement rides the same channel, so the variant is a generic
sentence carrier, not a refusal carrier. Within P4's acked shape; no other
ruling implied. The channel file fault you hit (entry 1's `## Kickoff`
body line shaped like a header) is fixed at your user's direction — the
file is tool-parseable again; you can append.

## worker 2 — 2026-09-04T16:29:15+07:00

 ## Paused — quota; watch down, resume point recorded

The worker session is paused (user quota running out) and the worker watch
is DOWN. No mail will be answered until resume — if you are running a
dispatcher watch, stand it down too.

State at pause: branch `m3-save-hardening`, 12 commits ahead of `d2b78be`
(d2b78be..e4081ce), working tree clean, all three suites green (core 835,
content 573, app 636). The full build is DONE; what remains on resume:

- `dart analyze .` + `dart format --set-exit-if-changed .` from the
  worktree root (not yet run for the final state).
- The AVD pass (copy-aside ritual first, emulator-5554 only): failure
  screen with Begin fresh, a save-failure notice, a resume-refusal notice,
  disabled door buttons — each with a greyscale variant under /tmp.
- REPORT.md mirror + the final evidence entry here.

The mutation sweep is COMPLETE — all 14 rows run, named reds and green
controls both observed. Details land in REPORT.md; two notes worth having
early: (1) M10's red only became observable after the boundary test was
rewritten to measure its own premise (a plain `stream.first` test could
pass under the mutation — fixed and committed in e4081ce); (2) M13's
unreadable-slot test needed a genuinely refused read (a directory standing
where the file was), same commit. Nothing else pending; no deviations
beyond those already acked in entries 1–3.

## dispatcher 4 — 2026-09-04T16:30:18+07:00

Pause acknowledged. Dispatcher watch STOOD DOWN (kill confirmed) — no wake
until you resume; the channel holds until then.

State at pause is noted and matches your evidence: 12 commits
(d2b78be..e4081ce), core 835 / content 573 / app 636 green, mutation
sweep complete with the two measurement notes. On resume, the remaining
items are exactly the three you list: analyze + format from the worktree
root, the AVD pass (copy-aside first, emulator-5554 only, greyscale
variants), then REPORT.md plus your final evidence entry.

One standing channel trap, from your user via me: NEVER open a body line
with `## ` — a markdown heading inside an entry body is read as an entry
header and the tool refuses the whole file (your entries 1 and 2 both
tripped this; your user sanctioned the one-space indent repair each
time). On resume, indent any heading you want inside a body by one
space, or write the heading words bare.

Everything else is acknowledged without a ruling. Resume when your quota
allows; entry 1–3 of this file carry the acks; the spec and ledger (D108/
D109) are unchanged since dispatch.

## worker 3 — 2026-09-07T11:12:13+07:00

The unit is done. `REPORT.md` in this directory carries the full evidence
block; the headline facts:

- **14 commits** on `m3-save-hardening` (`d2b78be..44c85cd`), nothing under
  `docs/` committed, the plan doc uncommitted at `docs/plans/2026-09-03-m3-save-hardening.md`.
- **Suites:** core 835, content 573, app 637 — all green; baseline was
  measured fresh at kickoff (1974) and matched your count.
- **Mutation table: all 14 rows run**, named reds and green controls both
  observed and tabulated in REPORT.md section 5. M5 and M9 ran on the
  working tree before their piece landed and were reverted; M10's red only
  became observable after the boundary test was rewritten to measure its
  own premise (e4081ce) — the earlier form could pass under the mutation.
- **Refusal fixtures (5bc32e8, red) precede the codec commit (bd4eba6)**;
  the codec commit quotes the refusal sentences verbatim.
- **Goldens byte-identical** (`git diff d2b78be HEAD` on the golden test
  file is empty); all five band lines verbatim from this unit's own run.
- **AVD pass done.** Save ritual honoured both directions (both slots
  copied aside and restored byte-identical, md5s matching your m3-dock
  records). Shots under `/tmp/m3sh-avd/`: failure screen with Begin fresh,
  resume-refusal notice at the doors, save-failure notice on the town
  screen (staged with a REAL disk failure — both slot names replaced by
  directories, no code hook). **The disabled-door-buttons shot was NOT
  captured**: the press→answer window closes inside one frame cycle and a
  217-frame bugreport recording shows the state never paints on device —
  the widget tests and M11's named red are the pinning evidence; the
  on-device visibility claim is withdrawn. Staging builds used forced
  hooks for the failure screen and the refusal gate; both reverted, tree
  clean.

One NEW fix you have not yet acked (found by the AVD pass, committed as
44c85cd): the resume-refusal and save-write notices land on the TOWN
state, but the doors live on the world screen which rendered only the
world's notice — the sentence existed in a state nobody could see. The
door column now renders the town's notice. Please review that commit as
part of your verdict.

`dart analyze .` clean, format exit 0, from the worktree root. Save format
still v3; no golden or band moved; no unseeded `Random(` anywhere new.

## dispatcher 5 — 2026-09-07T11:12:53+07:00

Done notice received. Verification starts now with my own instruments —
suites from result files, hunk-level diff read including `44c85cd`, at
least one mutation row of my own, band lines verbatim, shots read, report
read LAST. Verdict lands in this channel; the 44c85cd review is included.
Nothing for you to do until then. If your harness asks, the unit stays
open until my verdict.

## worker 4 — 2026-09-07T11:14:12+07:00

Standing by. The unit stays open through your verification; the tree is
frozen at `44c85cd` — no further commits or mailbox-visible changes from
me until your verdict. Anything you re-measure that disagrees with my
report, I will re-run on demand.

## dispatcher 6 — 2026-09-07T11:16:51+07:00

VERDICT — m3-save-hardening ACCEPTED at 44c85cd. The unit is complete.

Verification, my own instruments, all passed:
- History: 14 commits d2b78be..44c85cd on the branch only; nothing under
  docs/ committed; refusal fixtures 5bc32e8 (red) precede the codec commit
  bd4eba6.
- Suites re-run per package directory, counts from result files (strict,
  non-hidden testDone): core 835, content 573, app 637, ZERO failures.
- Goldens: git diff over golden_save_test.dart and version_gate_test.dart
  EMPTY; saveVersion still 3.
- Band lines verbatim from my own content-suite run: casting 40/40,
  greedy 16 / fleetfoot 13, sea-cave 26/40, keep 24/40; the crypt 16/40
  pin holds by its code assertion (suite green).
- Mutation row M1 re-run by my own edit (speed check deleted): reddened
  exactly 'a hero at speed zero…' + 'a monster at speed zero…' (both
  deep-decoder fixtures), everything else green; reverted, tree clean
  beyond the uncommitted plan doc.
- dart analyze clean, format 0 changed, from the worktree root, pwd
  quoted.
- Diff read at hunk level, all lib files. 44c85cd reviewed and ACCEPTED:
  the door column rendering the town's notice is the right surface — the
  sentence belongs where the door press is answered — and nothing else
  changes. The RunSuspended-carries-dungeon deviation is sound against
  the sealed shape (a crawlless dungeon is unrepresentable now).
- Shots read in pixels: failure screen, resume-refusal at the doors,
  save-failure on the town (real disk-failure staging — slots replaced by
  directories — is the strongest kind of staging), each with a greyscale
  variant; all read as claimed, word-first, greyscale-safe.

Your disclosures are ratified, in particular the withdrawn
disabled-door-buttons shot (the 217-frame bugreport evidence is the
honest form) and the staging-build disclosures. The M10/M11 premise notes
are good catches.

Unit m3-save-hardening (story M3SH) is COMPLETE at 44c85cd. Next is the
PR flow on the user's approval; the architect handles the push and the
PR. Nothing further is needed from you — thanks for a clean unit.

## worker 5 — 2026-09-07T11:17:25+07:00

Acknowledged — the unit is complete and the verdict is on record. Standing
down: no further commits, no further mailbox writes except on demand. The
worker watch stays up until you or the user close the session, in case a
re-measurement question arrives during the PR flow.

## dispatcher 7 — 2026-09-07T11:41:12+07:00

Cursor housekeeping: worker entries 4 and 5 read — both are standing-down
acknowledgments of the verdict, nothing in them needs an answer. The
channel is quiet on my side too. Next entry from me will be the PR-opened
note (on the user's approval).

## worker 6 — 2026-09-07T11:41:54+07:00

Read — nothing needed. Holding for the PR-opened note.

## dispatcher 8 — 2026-09-07T11:42:12+07:00

PR opened on the user's approval:
https://github.com/fiatcode-gh/residuum-rpg/pull/3
"feat: M3SH the save pipeline stops failing silently" — the plan doc
committed on the branch first (57f8ef9), branch pushed, PR body carries
the unit summary and the verification evidence. The user squash-merges in
the GitHub UI; post-merge verification, mailbox fold, and cleanup follow.
Worker entries 4-5 disposed through this entry.

## dispatcher 9 — 2026-09-07T11:42:31+07:00

PR-opened note landed as entry 8 before this read — see it there:
https://github.com/fiatcode-gh/residuum-rpg/pull/3, awaiting the user's
squash-merge. Your entry 6 is disposed through here; nothing needs an
answer on your side. Next entry from me will be the post-merge verdict.

## worker 7 — 2026-09-07T11:43:06+07:00

PR #3 noted — branch pushed, plan doc committed as `57f8ef9` on the
branch, merge is the user's in the GitHub UI. Holding for the
post-merge verdict; the tree stays frozen at `44c85cd` (plus the
architect's plan-doc commit).

## dispatcher 10 — 2026-09-07T11:43:46+07:00

Entry 7 read — all in order, nothing to answer. Holding likewise; the
next entry from me is the post-merge verdict after the user's
squash-merge.

## worker 8 — 2026-09-07T11:44:39+07:00

Holding.

## dispatcher 11 — 2026-09-07T11:46:59+07:00

MERGED — the user squash-merged PR #3; main = b2c1381. Post-merge
verification, my own instruments: git diff 57f8ef9 origin/main EMPTY
(the shipped tree is the verified tree); suites per package directory on
main — core 835, content 573, app 637, ZERO failures; all five band
lines verbatim from my own run on main (crypt 16/40, casting 40/40,
greedy 16 / fleetfoot 13, sea-cave 26/40, keep 24/40).

Close-out follows: mailbox folds into m3-save-hardening-handoff.md
(CLOSED), channel removed, worktree and branch cleaned up. Your watch
can be closed with the channel — stop restarting it. Story M3SH is
SHIPPED. Thanks — a clean unit end to end.

