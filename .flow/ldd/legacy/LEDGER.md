# Residuum — Epic Decision Ledger

Building Residuum, a turn-based offline dungeon crawler in Flutter, from empty
repository to playable game, milestone by milestone. The epic's stories are the
spec's milestones (M1–M5), split further where a milestone is too big for one
build branch.

- **Epic** → no external tracker; this ledger is the tracker.
- **Source of record (canonical)** → `docs/superpowers/specs/2026-08-20-dungeon-game-design.md`
  (the approved game design spec) plus `CLAUDE.md` (code conventions). Corrections
  live here in the decision log, never as silent edits to the spec.
- **Artifacts** → all in this directory, named `<unit>-<type>, where `<unit>`
  is the build branch name (also the build session name).
- **This file** → what was decided, when, and why.

## Session continuity

Before compacting, flush any decided-but-unwritten state into this ledger.
Preferred: start a fresh session at ~half context and re-orient from here.

**The architect handoff ritual (established D17/D18):** the continuation
entry point is `docs/epic/ARCHITECT-HANDOFF.md` — a stable, regenerable file.
Before an architect session ends (or at ~half context): flush state here,
regenerate that file, and hand the user the restart command. A new architect
session reads ARCHITECT-HANDOFF.md first, which routes it back into this
ledger.

### RESUME snapshot — 2026-09-07 late: m3-craft-risk built and verified by the worker, PAUSED before the device pass; watch stopped, session flushed (SUPERSEDED — see D126)

- **The worker is PAUSED on the user's instruction (laptop battery)**,
  just before the device-acceptance pass. All code is DONE and
  committed: 10 commits on `m3-craft-risk`, HEAD `e99025b`, tree clean;
  plan doc committed (`bb83e68`, docs/plans/2026-09-07-m3-craft-risk.md);
  **2077 strict green** (core 860 + content 579 + app 638, fresh, zero
  failures); mutation table M1–M7 complete, reds as named sets (M6's red
  set corrected — D124); all five band lines + v3 goldens byte-identical;
  format/analyze clean ×3 after pub get. REPORT.md fully evidenced in the
  channel. **Resume point (agreed in the channel):** boot Pixel_10 (two
  boot attempts segfaulted, exit 139, scene init — retry) → save ritual
  with checksums (BOTH slots aside FIRST) → build + install → forge-bench
  greyscale shot → restore saves → done notice. No install, no uninstall,
  no save touched so far.
- **Channel open:** `docs/epic/handoff/m3-craft-risk/` — dispatcher
  entries 1–3 sent (dispatch, ruling ratifications, M6 ratification),
  worker entries 1–7 (last: duplicate pause notice). Worker's cursor is
  at dispatcher entry 2; entry 3 (M6 ratified) is UNREAD by the worker —
  it will read it on resume. The dispatcher watch was KILLED at the
  user's word (kill confirmed by process scan); no watch is running. On
  resume: re-orient here, restart the watch
  (`mailbox watch --as dispatcher --home
  /var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/handoff`,
  wrapped in `bash -c`), then check the channel.
- **After the done notice, the architect's phase-6 verification is
  PENDING in full**: own-instrument suite re-runs (strict counts from
  result files), hunk-level diff read, at least one mutation row re-run
  by the architect's own edit, band lines verbatim, shots read in pixels,
  report read LAST. Then PR on user approval (D22 flow, `gh`, squash),
  post-merge verify, close-out per the standing order.
- Next work unchanged: m3-craft-risk (in flight) → `m3-town-ux`
  (V3+V5+V6+V7 — first unit under amended D113) → m3-quests (M3Q, save
  v4). Wave locked (D98, as amended D103).
- Salt `craftSeedSalt = 0x0C7A` recorded (D124). Rulings of record: D123
  (sealed TownAnswer; M1 reads "does not gain its tier"; loss sentence
  wins the notice slot).

### RESUME snapshot — 2026-09-07 evening: M3CH shipped (PR #4 + PR #6); CI live; next unit m3-craft-risk (SUPERSEDED — see the block above)

- **`main` = `e0544f4`** on GitHub — the chore unit (story M3CH, audit
  group 2) shipped across **PR #4 (`348cb14`) + PR #6 (`e0544f4`)**:
  CI workflow (three-way package matrix — format, analyze, test per
  package, resolution first per D115, Flutter pinned exactly 3.47.2,
  fail-fast: false, lockfile drift gate hardened with `ls-files --
  error-unmatch`), analyzer config + `lints/recommended` for
  core/content (six fixes incl. the D116 step.dart brace), core/content
  lockfiles committed, READMEs refreshed. Post-merge verified both
  times (2045 green, bands verbatim, content identity EMPTY); the
  workflow is green on main via the push trigger (run 34109072650).
  **Follow-ups 41/42 CLOSED.** Worktree removed, all scratch branches
  gone (fold-checked by ls-remote), `handoff/` retired, journal logged.
  `handoff/` retired, journal logged.
- **CI is live AND ENFORCED (D121):** branch protection landed — a `main`
  ruleset, active, requiring all three `gates` legs (+ GitGuardian),
  deletion and non-fast-forward barred, pull-request rule on. The user
  set it 2026-09-07 after the evidence rounds.
- **House method amended (D113): UI units are widget-driven** —
  phone-sized widget tests via a shared helper drive implementation;
  the AVD pass remains MANDATORY but is the final acceptance gate only
  (one install + save ritual + scripted taps + greyscale shots at unit
  close). Paint-timing and real-disk classes stay device-pinned.
- **NEXT: `m3-craft-risk` (V4)** → `m3-town-ux` (V3+V5+V6+V7 — the
  FIRST unit under the amended method) → m3-quests (M3Q, save v4). The
  wave's scopes and orders are locked (D98, as amended D103); go
  straight to recon.
- Standing follow-ups: 13, 20, 28, 32–34, 43–46 (43/44 need the author;
  45/46 ride later units). The audit report lives at
  `docs/reports/2026-09-03-audit-residuum-rpg.md` (D102); groups 1 and
  2 are both SHIPPED.
- New traps this session (all in the traps block): harness auto-format
  hooks can re-dirty a reverted file — re-check status a beat later;
  the format-clean premise requires resolution (`dart format` reads the
  resolved language version); a diff-based lockfile guard is blind to
  deletion — `git ls-files --error-unmatch` closes it.
- Date note: D113–D119 carry "2026-09-08" — those decisions were made
  2026-09-07 (WIB); the dating was the architect's error, content is
  unaffected.

### RESUME snapshot — 2026-09-08: M3SH closed; house method amended (D113); the chore unit is next (SUPERSEDED — see the block above)

- **`main` = `b2c1381`** on GitHub — PR #3 (m3-save-hardening, story
  M3SH) squash-merged and verified post-merge (D112): **2045 green**
  (835/573/637, zero failures), all five band lines verbatim from the
  architect's own run, `git diff 57f8ef9 origin/main` EMPTY. Close-out
  done: shots mirrored (42 files) to
  `docs/reports/shots/m3-save-hardening/`, mailbox folded into
  `m3-save-hardening-handoff.md` (CLOSED, 19 entries), `handoff/`
  retired, worktree + branch removed, watch killed and confirmed. No
  unit open, no worker, no watch, no mailbox.
- **HOUSE METHOD AMENDED (D113, user ruling):** UI units are now
  **widget-driven** — screen-shaped widget tests phone-sized via a
  shared helper drive implementation; the AVD pass remains MANDATORY
  but demotes from implementation driver to a **final acceptance gate**
  (one install + save ritual + scripted taps + greyscale shots at unit
  close). Applies from `m3-town-ux` onward; paint-timing and real-disk
  classes stay device-pinned. See D113 for the evidence split.
- **NEXT: the chore unit** (D102 group 2): one CI workflow — three
  suites + analyze + format, required on PRs to main; analyzer config
  for core/content; commit core/content lockfiles; README refresh; app
  README. Recon fresh → spec → build prompt; ask the harness question
  at dispatch. Then `m3-craft-risk` (V4) → `m3-town-ux` (V3+V5+V6+V7,
  first unit under the amended method) → m3-quests (M3Q, save v4).
- Standing follow-ups: 13, 20, 28, 32–34, 41–46 (41–42 ARE the chore
  unit; 43/44 need the author; 45/46 ride later units). The audit
  report lives at `docs/reports/2026-09-03-audit-residuum-rpg.md`
  (D102); group 1 is SHIPPED.
- Ledger repair note: the snapshot below was left un-superseded after
  D112 (the 2026-09-07 session regenerated the handoff but not this
  snapshot); repaired 2026-09-08.

### RESUME snapshot — new day: main re-squashed to d2b78be (content-identical); m3-save-hardening is next (SUPERSEDED — see the block above)

- **`main` = `d2b78be`** — the PR #2 squash was re-pushed with new
  hashes but an IDENTICAL tree (`git diff bf8bcb6 d2b78be` EMPTY;
  `git diff 12f3746 main -- packages` still EMPTY, 0 bytes). Hash
  mapping: `bf8bcb6` → `d2b78be`, `6a1500a` → `ee6c64c`. The D106
  post-merge verification (1974 green, bands byte-identical) stands —
  the verified tree IS the shipped tree. Cite `d2b78be` from here on.
- Both wave units are closed: **M3I** (m3-itemids, GitHub PR #1) and
  **M3BF** (m3-battle-flow, GitHub PR #2) merged and closed out — the
  V10 id bug is dead; the battle interaction is rebuilt (armed-target
  two-tap grammar, the wait verb, dock chips on a whole-header backing,
  the two-state glyph). Shots: `docs/reports/shots/m3-battle-flow/`.
  No unit open, no worker, no watch, no mailbox.
- **NEXT: `m3-save-hardening`** (the D103 amended wave; audit group 1
  from D102): save-write path (discarded `save()` bool, renames outside
  the failure handling, poisonable autosave queue, refuse-to-advance on
  a failed create), unguarded boot + thrown-read fallback bypass,
  semantic decode validation (speed ≥ 1, energy cap, hp ≤ maxHp,
  item-id uniqueness, skill levels — folds TTC-8/TTC-10),
  engine-boundary guard (step ArgumentError → refusal), IoSaveFiles
  coverage, door reentrancy; TownViewState sealed crawl value as rider
  if measurement allows. Recon → spec → build prompt; ask the harness
  question at dispatch. Then the chore unit (CI/analyzer/lockfiles/
  README) → `m3-craft-risk` (V4) → `m3-town-ux` (V3+V5+V6+V7) →
  m3-quests (M3Q, save v4).
- The user's playtest checklist for the next device session: the battle
  flow feel (armed-target two-tap grammar, wait verb, chips, glyph),
  the road-row Wait live, the enemy info sheet (author's eye on the
  bare `1–2` attack line — consider "Attack 1–2"), greyscale shots at
  `docs/reports/shots/m3-battle-flow/`.
- Standing follow-ups: 13, 20, 28, 32, 33, 34, 35–46 (35–40 = the
  save-hardening unit; 41–42 = the chore unit; 43/44 need the author;
  45/46 ride later units). The audit report lives at
  `docs/reports/2026-09-03-audit-residuum-rpg.md` (D102).

### RESUME snapshot — 2026-09-03: m3-battle-flow MERGED as bf8bcb6 (GitHub PR #2) (SUPERSEDED — hashes re-squashed, see the block above)

- **`main` = `bf8bcb6`** on GitHub — PR #2 (m3-battle-flow, story
  M3BF) squash-merged by the user and verified post-merge by the
  architect (D106): **1974 green** (835/550/563→589), the five band
  lines byte-identical to the D79 pins, `git diff 12f3746 main --
  packages` EMPTY (only the plan doc differs). Close-out done: shots
  mirrored to `docs/reports/shots/m3-battle-flow/` (25 files), mailbox
  folded into `m3-battle-flow-handoff.md` (CLOSED), report mirrored,
  `handoff/` retired, worktree removed, branch deleted at `bc3a6af`,
  watch kill confirmed. **Story M3BF CLOSED — the battle interaction is
  rebuilt; waiting is a real verb; watched and engaged read apart.**
  No unit open, no worker, no watch, no mailbox.
- **NEXT: `m3-save-hardening`** (the D103 amended wave) — the 2026-09-03
  audit's group 1: save-write path (discarded `save()` bool, renames
  outside the failure handling, poisonable autosave queue,
  refuse-to-advance on a failed create), unguarded boot + thrown-read
  fallback bypass, semantic decode validation (speed ≥ 1, energy cap,
  hp ≤ maxHp, item-id uniqueness, skill levels — folds TTC-8/TTC-10),
  engine-boundary guard (step ArgumentError → refusal), IoSaveFiles
  coverage, door reentrancy; TownViewState sealed crawl value as rider
  if measurement allows. Recon → spec → build prompt, harness question
  at dispatch. Then the chore unit (CI/analyzer/lockfiles/README) →
  `m3-craft-risk` (V4) → `m3-town-ux` (V3+V5+V6+V7) → m3-quests (M3Q,
  save v4).
- The user's playtest checklist for the next session: the battle flow
  feel (armed-target two-tap grammar, wait verb, chips, glyph), the
  road-row Wait live, the enemy info sheet (author's eye on the bare
  `1–2` attack line — consider "Attack 1–2"), and the greyscale shots
  at `docs/reports/shots/m3-battle-flow/`.
- Standing follow-ups: 13, 20, 28, 32, 33, 34, 35–46 (35–40 = the
  save-hardening unit; 41–42 = the chore unit; 43/44 need the author;
  45/46 ride later units). The audit report lives at
  `docs/reports/2026-09-03-audit-residuum-rpg.md` (D102).

- **`main` = `594bc80`** on GitHub — PR #1 (m3-itemids, story M3I)
  squash-merged by the user, verified post-merge by the architect
  (D101): 1941 green (828/550/563), the five band lines byte-identical
  to the D79 pins, `git diff b06b6de main -- packages` EMPTY. Close-out
  done: mailbox folded into `m3-itemids-handoff.md` (CLOSED), report
  mirrored as `m3-itemids-build-report.md`, `handoff/` retired, worktree
  (found already removed — user-side) pruned, branch `m3-itemids`
  deleted at `6f5bf5e`, no watch running. **Story M3I CLOSED. The V10
  duplicate-id bug is dead; the no-sell/bank/drop advisory on the
  user's Sea-Cave delve has LAPSED.**
- **NEXT: unit 2 of the wave — `m3-battle-flow`** (V1+V2+V8+V9 — D98
  has the locked forks; D97 has the verdicts; D97's battle redesign
  binds it) → `m3-craft-risk` (V4) → `m3-town-ux` (V3+V5+V6+V7) →
  m3-quests (M3Q, save v4). Follow-ups: 13, 20, 28, 32, 33, 34 (23
  CLOSED by M3I; 16's merchant half rides m3-town-ux).
- Fresh trap on the record: this monorepo has NO root pubspec —
  `flutter test packages/<pkg>` from the repo root fails with "No
  pubspec.yaml"; suites run per package directory.
- **2026-09-03, later: the user ran a four-lens code audit** (report:
  `docs/reports/2026-09-03-audit-residuum-rpg.md`, gitignored, at head
  `6a1500a` — the user's `chore: exclude .pi from git` commit on top of
  `594bc80`, pushed; audit state matches `main`). Verdict "Needs
  attention": no verified Critical, ten verified Important. The
  architect spot-verified five load-bearing claims at source — discarded
  `save()` bools at all six call sites, the error-handler-less autosave
  queue chain, unchecked `speed` in the actor codec, unguarded
  `bootFrom` in `main()`, debug-keystore release signing — all hold.
  Routing in D102, amendment adopted D103.
- **2026-09-03, later still: m3-battle-flow built, verified (D104),
  merged as `bf8bcb6` via GitHub PR #2 (D105/D106), and fully closed
  out.** See the CURRENT RESUME snapshot above.

### RESUME snapshot — 2026-09-03: m3-itemids MERGED as 594bc80 (SUPERSEDED by the block above — kept for history)

### RESUME snapshot — 2026-09-03: playtest #2 closed, wave locked; m3-itemids not yet dispatched (SUPERSEDED by the block above — kept for history)

- **`main` = `a567c19`** on GitHub (`git@github.com:fiatcode-gh/residuum-rpg.git`,
  rewritten history — hash mapping in D96; merge flow `gh`, not `tea`).
  1897 green verified post-migration. No unit open, no worker, no watch,
  no mailbox.
- **The user's playtest #2 happened over adb this session; verdicts V1–V10
  are in D97, CLOSED.** Highlights: the battle flow is REDESIGNED (armed
  targets highlight, attack becomes a bar action, bare tap = enemy info,
  map tap-to-attack retires, wait verb added); the dock gets chips +
  backing; free craft benches with failure; the item-id duplication bug
  (V10) was root-caused at source AND confirmed by live prediction on the
  user's phone (worn-test via adb): run-scoped drop counters × persisting
  pack × first-match consumers × every-match removal — one sword already
  lost to it. The phone's save is unreachable (non-debuggable build); adb
  screenshots + taps were the instruments. User's current delve: resumed
  at Sea-Cave depth 1/5, loadout restored, advisory = no sell/bank/drop
  until the id fix.
- **NEXT: the locked wave (D98), in order:** `m3-itemids` (V10, first —
  severity) → `m3-battle-flow` (V1+V2+V8+V9, wait verb and glyph ride it)
  → `m3-craft-risk` (V4) → `m3-town-ux` (V3+V5+V6+V7) → then m3-quests
  (M3Q, save v4). None specced yet; each takes recon → spec → build
  prompt. Standing follow-ups 13, 20, 28, 32 (16's merchant half rides
  m3-town-ux; 23 retires with m3-itemids).
- Traps that bit this wave: fish shells (wrap in `bash -c`); the phone
  build is not debuggable (`run-as` refused, saves unreachable) — adb
  screenshot-reading is the on-device instrument; `adb input swipe` needs
  1200ms; the user may drive the app over adb by consent — install/
  uninstall still forbidden.

### RESUME snapshot — 2026-09-03: m3-dock merged; repo now on GitHub with rewritten history; the next move is the user's playtest (SUPERSEDED by the block above — kept for history)

- **`main` = `a567c19`** (PRs #1–#16 + one docs commit) — on **GitHub**
  now (`git@github.com:fiatcode-gh/residuum-rpg.git`), history REWRITTEN
  in the migration, so every pre-migration hash in this ledger is stale
  (old→new mapping in D96; merge flow now `gh`, not `tea`). Story M3V
  (the dock fix) is COMPLETE and merged via PR #16 — the D90 playtest
  trap (battle view replacing the map, stranding a melee hero against a
  spitter at distance 3) is dead: the map never leaves the screen, the
  battle pieces dock over it, a far stage card tap says walk. 1897 green
  post-merge on the architect's own runs; bands byte-identical (crypt
  16/40 on the 0.40 floor, casting 40/40, greedy 16 / fleetfoot 13,
  sea-cave 26/40, keep 24/40).
- **NEXT: the user's playtest** — carries the still-open M3M
  casting-feel verdict, the M3C gathering-pace re-check, the dock's
  balance feel, and the author's eye on `docs/reports/shots/m3-dock/`
  (8 shots, greyscale variants included). Then **m3-quests (M3Q, save
  v4, per-unit sanctioned)** — D59 doctrine: never declare "the last
  break". Save v3 stands.
- No unit open, no worker session (the user killed it post-fix), no
  watch, no mailbox (`handoff/` retired again after the m3-dock fold).
  Follow-ups 13, 20, 28, 32 standing; 29/30/31 closed.
- New hazard on the record (D93): the actor codec REQUIRES `resists`
  in a hand-built monster document — hand-staged saves without it are
  refused whole (fallback works as designed).
- Standing cautions unchanged: tiered lever rule; D56 carry lesson; no
  instrument measures bosses/the road (28); crypt floor layouts
  byte-frozen; crypt 0.40 floor by ruling (D79). Traps that bit this
  wave: the mailbox watch stamp file hid from `rmdir` (fold-check
catches it); background watch shells are fish — wrap in `bash -c`.

### RESUME snapshot — 2026-09-02: playtest verdicts in; the dock unit `m3-dock` is next (SUPERSEDED by the block above — kept for history)

- **`main` = `fda107f`** (PRs #1–#15), 1894 green, unchanged. The first
  post-battle playtest happened and its verdicts are recorded (D90):
  gathering ENDORSED (M3C provisionally closed), potion stands at 10 by
  ruling (D91), and a REAL DEFECT was found — the battle view replaces
  the map, and with a spitter holding reach at distance 3 the player is
  trapped (tenth device-only catch; full root-cause chain in D90).
- **LOCKED (D91): the battle view docks over the map** — map always
  visible, stage cards + turn strip dock on top, skill bar at the
  bottom, no full swap ever, no AI/trigger/verb changes. Fix unit
  **`m3-dock`** (small, app-side) is NEXT, before m3-quests. It also
  carries fresh greyscale shots for the author's eye and re-opens the
  casting-feel playtest. M3M/M3C re-opens stay open.
- After m3-dock: **m3-quests (M3Q, save v4, per-unit sanctioned)** —
  D59 doctrine: never declare "the last break".
- No unit is open, no worker session exists, no watch runs, no mailbox
  exists (`docs/epic/handoff/` retired). Standing follow-ups: 13, 20,
  28, 32. Standing cautions unchanged (tiered lever rule; D56; no
  instrument measures bosses/the road; crypt floor layouts byte-frozen;
  crypt 0.40 floor by ruling).
- Traps that bit THIS session: none new — but D90's recon confirmed
  widget tests never covered "battle view whose only reach-holder is
  beyond one step"; the m3-dock spec must pin that exact surface.

### RESUME snapshot — 2026-09-02 session close: the battle overhaul is COMPLETE; the playtest is next (SUPERSEDED by the block above — kept for history)

- **`main` = `fda107f`** (PRs #1–#15). 1894 green on the architect's own
  runs post-merge. **Story M3U (the battle overhaul) is COMPLETE** in two
  units: unit A `m3-battle` merged `d576d1c` via PR #14 (D82) — ambush
  openings (first turn, never free damage; snapshot-gated lunge), explicit
  cast targets, the `reach` field, the spitter (glass cannon, hp 4,
  reach 3, crypt d1+d2); unit B `m3-battle-ui` merged `fda107f` via PR
  #15 (D89) — the battle screen (stage cards, turn strip with D86's
  clock-correct arrivals, skill bar with the dock grammar, armed-skill
  tap-to-target), the castRefusal mirror fix, the spell-row extraction,
  ranged verb + ambush beat, riders 30/31 closed.
- **Band baseline of record (D79-pinned, byte-identical through both
  units):** crypt 16/40 (40.0%) `{1:1,2:9,3:8,4:6,5:16}` — the crypt's
  soft floor is 0.40 BY RULING (D79; sea-cave/keep keep 0.45); casting
  build 40/40 (informational, kit door — not apples-to-apples, follow-up
  29 closed); greedy 16 / fleetfoot-first 13; sea-cave 26/40; keep 24/40.
  The trail (unit A) keeps every failed lever: d2-drop 37.5%, hp-4
  no-op, reach-2 boundary — the crypt's difficulty is the ambush rule's
  own weight, ruled deliberately.
- **NEXT: the user's playtest** (emulator or real phone). Verdicts that
  re-open: the M3M casting-feel question (the skill bar is the answer
  candidate), the M3C gathering-pace question, and the battle screen's
  own first verdict. The greyscale shots in
  `docs/reports/shots/m3-battle-ui/` await the author's eye — the
  deuteranomalous author is the final authority. Then verdicts recorded,
  then **m3-quests (M3Q, save v4, per-unit sanctioned)** — the last M3
  unit. Save v3 stands (reach omit-on-default).
- No unit is open, no worker session exists, no watch runs, no mailbox
  exists (`docs/epic/handoff/` retired; both folds are CLOSED files in
  `docs/epic/`). Follow-ups 29/30/31 CLOSED; standing: 13, 20, 28, 32
  (monster exclusive skills/spells with the anti-spam constraint).
- Standing cautions: tiered lever rule; D56 carry lesson; no instrument
  measures magic deeply (casting line is informational), bosses, or the
  road (28); crypt floor layouts byte-frozen. New traps this session:
  **bg-runner shells may be fish (wrap in `bash -c` — killed two watches
  and one suite run)**; **sandbox rm can fail silently (EROFS-shaped) —
  retry removals with errors visible and fold-check the result**;
  squash merges are invisible to merge-base (verify content identity
  before `git branch -D`).
- Blocked on: nothing — the next move is the user's playtest.

### RESUME snapshot — 2026-09-02: hard turn to the battle overhaul; HUD+cast parked (SUPERSEDED by the block above — kept for history)

- **`main` = `8168861`** unchanged. No unit is open, no worker session exists.
- **The user made a hard turn (D71): the HUD+cast design unit is DEFERRED** — its
  locked forks (two fixed status lines; spell dock with wrap; marking + name +
  cost button grammar) are parked, not dead. The dock grammar becomes the
  battle screen's skill bar; the crawl-HUD half stays deferred until the
  battle unit's UI settles. Follow-ups 30/31 stay parked with it.
- **NEXT: the battle mechanism overhaul (D71, in design):** turn-based battle
  as a VIEW over the existing map simulation — battle screen (enemies on
  stage, skill bar below, tap to target), while monsters keep map positions
  and keep walking (turn-advance, not real time). Stage membership = reach on
  the hero (adjacent melee; ranged + LoS when ranged monsters arrive);
  in-transit walkers appear in the turn strip as arrivals with turn counts;
  corridor blocking is emergent map geometry. Flee = walk away (view closes
  when nothing is adjacent); road fights fold in unchanged with edge-flee.
  Energy clock ports (fast actors act more often) with a turn-order strip.
  Ambush = monster earned the first turn (adjacent or ranged-LoS drop), never
  a free hit; hero opens otherwise; player stealth-ambush crits = future work.
  Suspend survives untouched (battle has no own state; v3 may stand); banish
  becomes "drive it off and it walks back"; bolt gains explicit targeting.
- **Pending rulings before spec:** hero ranged reach (architect proposal: LoS,
  stage + strip, so archery thins the pack); whether THIS unit ships one
  ranged monster or the rules only (bestiary ruling required either way);
  the standing new intent: monsters will eventually use exclusive skills and
  spells, attacking and supporting, interacting in group battle (e.g. healing
  allies) — follow-up 32. Bands re-baseline bounded to the rulings that move
  them (ambush opening); bot survives; cast instrument (29) rides.
- Standing: follow-ups 13, 20, 28, 29; tiered lever rule; D56 lesson.
- Blocked on: nothing — the brainstorm walkthrough continues with the user.

### RESUME snapshot — 2026-09-01 night: M3F merged; the HUD+cast brainstorm is next (SUPERSEDED by the block above — kept for history)

- **`main` = `8168861`** (PRs #1–#13). M3F is CLOSED (D70): merged,
  post-merge verified on the architect's own runs (1810 green, four
  band lines byte-identical to D62), worktree/branch/mailbox all
  cleaned up, watch stopped. NO unit is open and NO worker session
  exists — there is nothing to watch and no mailbox to check.
- The journal and the [[Residuum]] weft page are updated through the
  merge (2026-09-01).
- **NEXT: the HUD+cast design unit (D63, locked ordering)** — the
  one-liner HUD revamp and the direct cast affordance TOGETHER, as one
  design unit. It starts with its OWN BRAINSTORM with the user
  (flow-brainstorming: opinionated prose first, then the structured
  question; real visual forks; the greyscale constraint binds every
  fork). Follow-up 30 (status line on a real phone) and follow-up 31
  (skills-row crowding, "Blacksmith0") ride it. The two widget-tooling
  traps (find.textContaining case-sensitive; scrollUntilVisible
  one-way) must be restated verbatim in its build prompt.
- After it: **m3-quests (M3Q, save v4, per-unit sanctioned)** — the
  last M3 unit. The M3M casting-feel and M3C gathering-pace verdicts
  re-open after the HUD+cast playtest.
- Standing: follow-ups 13, 20, 28, 29; tiered lever rule; D56
  carry-list lesson; no instrument measures magic/crafting/the road
  (29) and no band is boss coverage (28).
- Blocked on: nothing — the next move is the HUD+cast brainstorm with
  the user, whenever they are ready.

### RESUME snapshot — 2026-09-01 evening: M3F verified and ACCEPTED at `5dcfaa6`; PR flow awaits the user (SUPERSEDED by the block above — kept for history)

- **`main` = `54ec315`**; unit `m3-fixes` (M3F) is DONE and verified:
  worktree `.worktrees/m3-fixes` @ `5dcfaa6, five commits, tree clean
  (only the untracked `.pi/`). Three worker sessions ran it (two pi,
  one Claude Code — D64/D66/D68); the architect session is now Claude
  Code too (change announced, architect entry 7).
- **Verification is COMPLETE with the architect's own instruments
  (D69):** 1810 green from own result files, four band lines
  byte-identical to D62, mutation rows M4 and M6 reproduced exactly by
  own sed, diff read at hunk level, D65-B commit ordering verified,
  analyze/format clean, AVD evidence read (remembered/visible node
  pair, Character door, greyscale). BUILD-REPORT.md is in the mailbox
  directory and its claims all re-checked true.
- **PR #13 is OPEN** (user-approved, pushed and created 2026-09-01
  evening, no conflicts):
  https://git.fiatcode.dev/fiatcode/residuum-rpg/pulls/13 — user
  squash-merges in the UI, then the architect verifies `main` (suites
  + bands), cleans up worktree/branch/mailbox, records the merge
  decision.
- New follow-up 31 (skills-row crowding, "Blacksmith0") rides the
  HUD+cast unit. The record correction: `01-town-doors.png` is a
  dungeon frame; the Character-door evidence is
  `06-town-character-door.png`.
- After the merge: the **HUD+cast design unit** (own brainstorm,
  greyscale binds, follow-ups 30 + 31 ride), then **m3-quests (v4
  save)** — D63. The M3M casting-feel and M3C gathering-pace verdicts
  re-open after the HUD+cast playtest.
- Standing: follow-ups 13, 20, 28, 29; tiered lever rule; D56
  carry-list lesson.
- Blocked on: the user's squash-merge of PR #13.

### RESUME snapshot — 2026-09-01 pause: M3F continuation dispatched after a worker break; quota pause ordered by the user (SUPERSEDED by the block above — kept for history)

- **`main` = `54ec315`**; open unit `m3-fixes` (M3F), worktree
  `.worktrees/m3-fixes` @ `5dcfaa6` (five commits over the base — items
  1–3 all built: the four-argument road-encounter carry, the glyph-plan
  extraction + remembered nodes, the town Character screen; worktree
  verified CLEAN by the architect at the break, D66). The FIRST worker
  session (pi) broke mid-mutation-table; a continuation brief is
  **architect entry 5** in `docs/epic/handoff/m3-fixes/architect.md`.
  **Whether the fresh worker session was launched is UNKNOWN at pause**
  — the pointer prompt + gesture were handed to the user. First action
  on resume: read `worker.md` (entries 1–2 are the broken session's;
  anything from entry 3 is the replacement's), check whether it is
  alive, and restart the standing watch (`docs/epic/watch-architect.sh`
  as a bg task — it died with the paused session if this session was
  quit).
- What remains in the unit: the AVD pass's LAST steps only (door reads
  Character on device, screen sections on device, remembered-node
  screenshot + greyscale variant in `docs/reports/shots/m3-fixes/`),
  then BUILD-REPORT.md, done notice as worker entry 4. The mutation
  table is DONE (D67: observed named sets supersede the spec's
  predictions; three corrections binding), counts re-derived 1810,
  four band lines byte-identical, static verification clean, install
  trap resolved with saves restored md5-identical. Then architect
  verification with own instruments, PR flow on approval, close-out.
- Rulings in force: D65 (five pre-declarations: glyphPlan(GameState,
  DungeonPalette); extraction-verbatim C2 order; one green fix commit;
  widget duplication threshold; docs/plans untracked discipline) and the
  entry-4 stamp correction (predecessor's 12-min hand-typed drift;
  clock every stamp). Two new widget-tooling traps recorded (find.text
  Containing case-sensitive; scrollUntilVisible one-way).
- After M3F: the **HUD+cast design unit** (own brainstorm, greyscale
  binds, follow-up 30 rides), then **m3-quests (v4 save)** — D63.
- Standing: follow-ups 13, 20, 28, 29, 30; tiered lever rule; D56
  carry-list lesson.
- Blocked on: the user's quota allowance; the M3F worker's return.

### RESUME snapshot — 2026-08-29 session: M3C closed out (D62), playtest verdicts root-caused, m3-fixes dispatched to a pi worker (SUPERSEDED by the block above — kept for history)

- **`main` = `54ec315`** (PRs #1–#12 merged; 1790 green re-run on main, all
  four band lines byte-identical, quoted in D62). Worktree
  `.worktrees/m3-fixes` @ `54ec315, branch `m3-fixes, handed to a
  **pi** build session (`pi -n m3-fixes` — the user's choice, first pi
  worker on the epic; D64). Mailbox:
  `docs/epic/handoff/m3-fixes/` (architect.md = dispatch note entry 1;
  worker.md empty). The architect's standing watch runs as a bg task
  (`docs/epic/watch-architect.sh, 3600s cycle, restart-on-wake protocol).
- The 2026-08-29 playtest (user journal): **balance ENDORSED** — no
  balance ruling unit. Two defects root-caused (both verified at source,
  both untested pre-fix): (1) `startRoadEncounter` (m3-world-era code)
  omits `spells`/`knownSpells`/`materials`/`mana` → any road fight wipes
  the profile's spells and materials through `endRun`; (2) gathering
  nodes render only in live FOV (`glyph_grid.dart`) — remembered nodes
  vanish; spawn itself is sound (1–3/floor, "Never zero" pinned). Three
  UX verdicts: casting needs the inventory; town Gear → Character menu
  (Pack-shaped); HUD one-liner cramped.
- **Unit order locked (D63):** `m3-fixes` (S/M — the three items, no save
  bump, bands controls) → **HUD+cast design unit** (own brainstorm,
  greyscale binds, follow-up 30 rides) → **m3-quests (v4 save, per-unit
  sanctioned)**. M3M casting-feel and M3C gathering-pace verdicts
  RE-OPEN after the HUD+cast unit.
- Artifacts: recon `m3-fixes-recon.md, spec `m3-fixes-spec-M3F.md,
  build prompt `m3-fixes-build-prompt.md` (watch block first; pi-worker
  note: pass shell timeouts explicitly when polling). The user's device
  save holds a wiped hero — no migration, v3 stands; AVD ritual in the
  prompt verbatim.
- Standing: follow-ups 13, 20, 28, 29, 30; tiered lever rule; D56
  carry-list lesson now has its named example.
- Blocked on: the worker's return (mailbox + BUILD-REPORT.md in
  `docs/epic/handoff/m3-fixes/`).

### RESUME snapshot — 2026-08-25 end of day: M3C verified, PR #12 open; the user playtests tonight (SUPERSEDED by the block above — kept for history)

- **`main` = `83b5336`** (PRs #1–#11 merged, 1570 green there — D58).
  **M3C is VERIFIED (D61) and PR #12 is OPEN** —
  https://git.fiatcode.dev/fiatcode/residuum-rpg/pulls/12, no conflicts,
  squash title ready. Branch `m3-craft` @ `ea6f05c` (12 commits, pushed),
  worktree `.worktrees/m3-craft` still on disk. **1790 tests green on
  the branch (my runs, 762/530/498) and ALL FOUR band lines
  byte-identical to the D58 baseline** — the unit's central control
  held. Session `residuum-m3-craft [8d79bf]` is done and may be closed;
  stale `residuum-m3-magic [638a39]` may also still need closing.
- Day's arc (2026-08-25): M3M kickoff → D56 mid-flight (C1 refuted by
  experiment, gates 4/4/3) → D57 verified → merged `83b5336` (D58) →
  D59 M3C forks (saveVersion 3, materials as counters, lean scope,
  gathering-only; "last break" claims retired) → D60 nine
  pre-declarations (GatherKind forced; gatherSalt by collision sweep) →
  built → D61 verified, PR #12 opened on conditional pre-approval.
  1361 → 1570 → 1790 tests. Two architect arithmetic errors caught by
  workers (M3M gates; the ×3 temper term), the 7th and 8th device-only
  catches, and the save copy-aside ritual saved the device saves TWICE.
- **On the user's squash-merge of #12**: pull, re-run suites on `main`
  (expect 1790), all four band lines byte-identical, remove worktree +
  branches (saveslot backups already preserved in the MAIN repo's
  `docs/reports/device-saves/, SHA256-verified), record the close-out
  decision, fold the handoff record, journal.
- **The user playtests TONIGHT** — the double (possibly triple) verdict:
  M3B watch items (crypt armor edge, camp price, bosses, fleetfoot
  14/40, "claws you for 4"), M3M casting feel (mana budget, gates
  4/4/3, bind/banish value, fire-vs-frost), and M3C crafting if #12
  merges first (gathering pace, temper economy, the forge loop). NOTE:
  the emulator's installed build is M3C profile; every pre-M3C save is
  refused (v1 AND v2) — fresh hero.
- After the verdicts: a balance/feel ruling unit if the playtest demands
  one, else **m3-quests (M3Q, S/M)** — the last M3 unit (side-quest
  templates, quest state, payouts, reputation; D34). Quest state WILL
  break the save format again (v4) — sanctioned per-unit per D59's
  corrected doctrine. Then M4.
- Standing: follow-ups 13, 20 (freeze at first ship — the honest form),
  28, 29 (now covers gathering pace + temper economy too), 30; tiered
  lever rule.
- Blocked on: the user's squash-merge of PR #12 and/or the playtest
  verdicts.

### RESUME snapshot — 2026-08-25: M3M merged; the game casts; the double playtest awaits (SUPERSEDED by the block above — kept for history)

- **`main` = `83b5336`**: PRs #1–#11 all merged. **1570 tests**
  (657/472/441) re-run green on `main` post-merge; all four re-pinned
  band lines verbatim, measured this session: crypt `20/40 won (50.0%),
  stalled 0, died at 1:1 2:6 3:6 4:7 5:20, `greedy build: 20/40 won;
  fleetfoot-first build: 14/40 won, sea-cave `30/40 won (75.0%),
  stalled 0, died at 2:1 3:8 4:13 5:9 6:9, ruined keep `25/40 won
  (62.5%), stalled 0, died at 1:4 2:5 3:4 4:2 5:13 6:6 7:6`. Bands
  0.45–0.80, keep < cave. No worktrees, no branches, nothing in
  flight; session `residuum-m3-magic [638a39]` may be closed by the
  user.
- Day's arc (2026-08-24 night → 25): D55 forks → M3M specced →
  launched → D56 mid-flight (worker refuted C1 by experiment; gates
  4/4/3) → built → D57 verified (7th device catch; the count and an
  unrun claim corrected on re-measurement) → merged PR #11 (D58).
  1361 → 1570 tests.
- **The game now:** everything M3B left PLUS magic — three school
  skills, six spells (Firebolt/Frost Lance, Mend/Ward, Bind/Banish),
  spell books found in the dungeons that teach them (starter two on
  the merchant shelf), per-floor mana, fire/frost vs creature
  resistances (melee untyped), save version 2. **Every v1 save is
  refused** — including the user's emulator playtest saves (preserved
  in `docs/reports/device-saves/, unreadable by v2 builds). The spec
  declares v2 the LAST break before ship (follow-up 20).
- **NEXT: the user playtests — a double verdict now**: the M3B watch
  items (crypt armor edge, camp price, bosses, fleetfoot 14/40, "claws
  you for 4") AND how casting feels (mana budget, gates 4/4/3,
  bind/banish worth their cost, fire-vs-frost across dungeons —
  follow-up 29: no instrument measures any of it). Then **m3-craft
  (M)** per D20/D50 ordering; then m3-quests. M4/M5 wait behind M3.
- Standing: follow-ups 13, 20 (v2 freezes at first ship), 28, 29, 30;
  tiered lever rule (content tables free with a trail; bestiary/hero
  stats need a ruling).
- Blocked on: nothing — awaiting playtest verdicts or the m3-craft
  go-ahead.
- UPDATE 2026-08-25 (same session): the user deferred the playtest and
  said continue implementing. **M3C `m3-craft` is READY TO HAND OFF**
  (D59 forks: saveVersion 3, materials as counters, lean scope —
  smelt/temper/brew both towns, gathering-only sources; the "last
  break" finality claim retired). Recon `m3-craft-recon.md, spec
  `m3-craft-spec-M3C.md, prompt `m3-craft-build-prompt.md, worktree
  `.worktrees/m3-craft` @ `83b5336, handoff record open. Launch (user
  runs it):
  `cd <repo>/.worktrees/m3-craft && claude -n residuum-m3-craft --bg`.
  Bands are byte-identical CONTROLS again — and this time the claim
  survived the D56 analysis at recon (no table, no weight, no new
  stream draw, nothing bot-visible). Blocked on: the launch gesture.
- UPDATE: launched — session `residuum-m3-craft [8d79bf]` (bg,
  user-created), kickoff delivered, no ruling vetoed. Status table row →
  building. Blocked on: the build returning. NOTE: the old
  `residuum-m3-magic [638a39]` session still shows in the peer list
  (status "shell") — the user may close it; its wave is folded (D58).
- UPDATE (end-of-day instructions from the user): this is the day's
  last unit. **Conditional pre-approval granted (D47 precedent): if the
  build returns and the architect's verification passes clean, push
  `m3-craft` and open the PR without a further ask.** Then flush the
  ledger and regenerate ARCHITECT-HANDOFF.md for tomorrow's session.
  The user playtests TONIGHT (the double verdict: M3B watch items +
  M3M casting feel — and possibly M3C crafting if they merge first).
  A verification FAILURE stops the chain: record findings, message the
  worker, no push.

### RESUME snapshot — 2026-08-24 night, later: M3M specced and ready to hand off; the playtest runs in parallel (SUPERSEDED by the block above — kept for history)

- **`main` = `936ca5b`**, 1361 green (537/418/406) re-measured by this
  architect this session, all four band lines verbatim. Stale local
  branch `chore/report-layout` verified absorbed and deleted. The old
  interactive architect session closed by the user; this bg architect is
  the only one alive.
- **M3M `m3-magic` is READY TO HAND OFF** (D55 forks: types on spells
  only, hero-only mana, auto-target nearest, three schools; save break
  sanctioned, saveVersion 1 → 2; **the four band lines are CONTROLS —
  must return byte-identical**, not re-pins). Recon
  `m3-magic-recon.md, spec `m3-magic-spec-M3M.md, prompt
  `m3-magic-build-prompt.md, worktree `.worktrees/m3-magic` @
  `936ca5b, handoff record open. Launch (user runs it):
  `cd <repo>/.worktrees/m3-magic && claude -n residuum-m3-magic --bg`.
- Six spells, two per school (Firebolt/Frost Lance, Mend/Ward,
  Bind/Banish); books per-dungeon by drop-table weight (exclusivity
  validated); merchant carries the two starter books; book price term
  fixes the 1-gold hole in `sellPriceOf`; road-danger constant STANDS
  (D55 reasoning: cast xp displaces swing xp). Numbers tune with a
  trail; creature hp/attack/pierce stay closed (tiered rule).
- **The user's playtest of the rebalanced game runs in parallel** —
  verdicts incoming (watch items: crypt armor edge, camp price, bosses,
  fleetfoot 14/40, "claws you for 4"). Verdicts may spawn a balance
  follow-up unit; they do not block M3M.
- Standing: follow-ups 13, 20 (restated in the M3M spec — the v2 break
  must be the last before ship), 28; tiered lever rule.
- UPDATE 2026-08-25: launched — session `residuum-m3-magic [638a39]`
  (bg, user-created), kickoff delivered, no ruling vetoed. Status table
  row → building. Blocked on: the build returning (playtest verdicts
  still welcome in parallel).

### RESUME snapshot — 2026-08-24 night: M3B merged; the rebalanced game awaits its playtest (SUPERSEDED by the block above — kept for history)

- **`main` = `936ca5b`**: PRs #1–#10 all merged. **1361 tests**
  (537/418/406) re-run green on `main` post-merge; all four band lines
  verbatim, measured this session: crypt `20/40 won (50.0%), stalled 0,
  died at 1:1 2:9 3:4 4:6 5:20, `greedy build: 20/40 won;
  fleetfoot-first build: 14/40 won, sea-cave `31/40 won (77.5%),
  stalled 0, died at 2:1 3:7 4:13 5:10 6:9, ruined keep `28/40 won
  (70.0%), stalled 0, died at 1:4 2:6 3:1 4:1 5:13 6:9 7:6`. Bands
  asserted at 0.45–0.80. No worktrees, no branches, nothing in flight;
  session `residuum-m3-balance` may be closed by the user.
- Day's arc (this architect session, 2026-08-22 → 24): PR #7 merge →
  D43/M3D (PR #8) → D46/M3X (PR #9) → the first real playtest (D49) →
  D50 forks → M3B with mid-flight D51/D52 → merged (PR #10, D53/D54).
  1153 → 1361 tests, four waves, two mid-flight rulings, the 5th and
  6th device-only catches, and the tuning-conflict stop that worked
  exactly as designed.
- **The game now:** three themed dungeons with rolled depths and placed
  bosses, an economy where items are scarce and gold matters, camps
  that expire (3 road days, warning at 2), discovery only through
  rumors and travelers (both named in the log), a road that scales with
  the hero, delves that COMPLETE (Finish from the bottom), and disabled
  buttons that say why. **Every pre-M3B save is refused** (campDay
  reshape — the last sanctioned format break before v1 freezes at
  ship).
- **NEXT: the user playtests the rebalanced game.** Watch items handed
  over: the crypt's first half is the only place armor works (design
  edge); the camp price (price or theft?); the bosses (no band measures
  any bottom floor — follow-up 28); the fleetfoot exploit doubled to
  14/40 unasked; does "claws you for 4" read as danger. Then m3-magic
  (L — nine skills, spell books, first spells; the strategic-combat
  answer), informed by the verdicts. Then m3-craft → m3-quests.
- Standing: follow-ups 13 (M2Q viewport playtest), 20 (v1 freezes at
  first ship — restate in every save-touching spec), 28 (bottom floors
  unmeasured); the tiered lever rule (D50's blanket grant EXPIRED with
  M3B — back to content-tables-free-with-trail, bestiary/hero stats
  need a ruling).
- Blocked on: nothing — awaiting the user's playtest verdicts or the
  m3-magic go-ahead.

### RESUME snapshot — 2026-08-24 afternoon: M3D and M3X both merged; next fork awaits the playtest (SUPERSEDED by the block above — kept for history)

- **`main` = `b9d7c21`**: M1 → … → M3W → M3D (PR #8, D45) → M3X (PR #9,
  D48) all merged. **1296 tests** (529/396/371) re-run green on `main`
  post-merge, survivability lines verbatim: crypt
  `24/40 won (60.0%), stalled 0, died at 1:1 2:9 3:6 5:24` (ASSERTED in
  code since M3D), fleetfoot 7/40, sea-cave `34/40 (85.0%),
  3:5 4:15 5:9 6:11, ruined keep `31/40 (77.5%), 2:6 3:3 5:14 6:8 7:9` —
  all measured this session. No worktrees, no branches, nothing in
  flight; sessions `residuum-m3-dungeons` and `residuum-m3-depth` may be
  closed by the user.
- Day's arc: D43 (M3D forks) → M3D built/verified/merged (D44/D45) → D46
  (M3X forks) → M3X built/verified/merged (D47/D48). 1153 → 1296 tests.
  The game now: three themed dungeons with placed bosses and guaranteed
  rares, per-node floor streams, camps that remember their dungeon, and
  delves that roll their own depth (crypt fixed at 5). Journal + Residuum
  page current through both merges.
- Doctrine earned today (follow-up 27 extended): analyze from the
  worktree root with pwd quoted; mutation reds as named sets;
  coincidence-capable mutants under-report (prefer constant shifts);
  acceptance fixtures state their stat delta field by field. New
  environment trap: copy BOTH device save slots aside before pushing
  acceptance saves (the M3X pass destroyed the user's playtest save).
- **NEXT is a fork the user's playtest decides:** m3-magic per D43
  ordering, OR the balance ruling unit fed by playing the three-dungeon
  world (follow-up 24 camp expiry + road-danger teeth, follow-up 25
  discovery giveaway, first human boss verdicts — no bot fights a boss).
  The user's pre-M3X playtest save was lost (see traps); play restarts
  from the acceptance saves or fresh.
- UPDATE 2026-08-24 evening: the playtest RETURNED (D49 — too easy, item
  flood, dead currency, silent discovery, no completion beat, UX gaps;
  the merchant "bug" resolved as intended-but-unexplained). D50 locked
  the forks: **M3B `m3-balance` is the next unit** with the FULL lever
  grant; then m3-magic. Recon done (`m3-balance-recon.md` — smoking gun:
  13 of 14 creatures deal exactly 1 damage to the fixture kit; litter
  20–43/delve vs a 20-slot pack). Spec `m3-balance-spec-M3B.md, prompt,
  worktree `.worktrees/m3-balance` @ `b9d7c21, handoff open. EVERY
  survivability figure re-pins by design. Launch:
  `cd <repo>/.worktrees/m3-balance && claude -n residuum-m3-balance --bg`.
  LAUNCHED: session `residuum-m3-balance [516b70]` (bg, user-created),
  kickoff delivered, no ruling vetoed. Blocked on: the build returning.

### RESUME snapshot — 2026-08-24: M3D merged; M3X specced and ready to hand off (SUPERSEDED by the block above — kept for history)

- **M3D is CLOSED**: merged `59b91f1` via PR #8 (D45); **1259 tests**
  (515/380/364) re-run green on `main` post-merge, all THREE
  survivability lines verbatim (crypt 24/40 asserted in code now,
  sea-cave 35/40, keep 31/40 — bands ratified at merge). Worktree and
  branches removed; session `residuum-m3-dungeons` may be closed by the
  user. `main`: 59b91f1 ← bdb190b ← 958ef98 ← ….
- **M3X `m3-depth` is READY TO HAND OFF** (D43 split + D46 forks): spec
  `m3-depth-spec-M3X.md, prompt `m3-depth-build-prompt.md, recon
  `m3-depth-recon.md, worktree `.worktrees/m3-depth` @ `59b91f1,
  handoff record open. Launch:
  `cd <repo>/.worktrees/m3-depth && claude -n residuum-m3-depth --bg`.
  Sea-cave rolls 4–6, keep 5–7, crypt fixed 5; the roll is DERIVED
  (no save change); HUD shows the rolled total; both themed bands
  re-pin BY DESIGN; the crypt's line + assertions are character-frozen.
- Day's arc: D43 forks → M3D built/verified/merged (PR #8, D44/D45; the
  epic's 5th device-only catch; analyze-scope + histogram-pin doctrine)
  → D46 forks → M3X specced. 1153 → 1259 tests. Journal + Residuum page
  updated in the weft graph (2026_08_24).
- **User playtest of the three-dungeon world is the parallel track** —
  feeds follow-ups 24 (camp expiry), 25 (arrivingAt gives dungeons
  away), and the first human verdict on the bosses (no bot ever fights
  them). A ruling-sized balance unit follows the playtest.
- After M3X: m3-magic → m3-craft → m3-quests (D20/D34/D43 ordering).
- UPDATE: launched — session `residuum-m3-depth [857d3b]` (bg,
  user-created), kickoff delivered, no ruling vetoed. Blocked on: the
  build returning.

### RESUME snapshot — 2026-08-22 evening: PR #7 merged; M3D specced and ready to hand off (SUPERSEDED by the block above — kept for history)

- **`main` = `bdb190b`** (chore PR #7 merged by the user this session;
  BUILD-REPORT.md untracked, `docs/reports/` gitignored — verified).
  Baseline re-measured by this architect on `bdb190b`: 515 core + 300
  content + 338 app = **1153 green**; content suite (survivability band
  assertion) green.
- **M3D `m3-dungeons` is READY TO HAND OFF** (D43 forks + spec rulings
  1–7, user may veto): spec `m3-dungeons-spec-M3D.md, prompt
  `m3-dungeons-build-prompt.md, recon `m3-dungeons-recon.md, worktree
  `.worktrees/m3-dungeons` @ `bdb190b, handoff record open. Launch:
  `cd <repo>/.worktrees/m3-dungeons && claude -n residuum-m3-dungeons --bg`.
  Core diff must be EMPTY; the crypt's 24/40 gets promoted from a printed
  line to code assertions (recon found the exact pin was prose-only).
- **D43 recorded**: content-only boss + trophy; staggered rumor-hidden map
  (sea-cave 1 day off Northgate, keep 2 days, danger 30/40 first guesses);
  promoted pin + progression-kit bot bands; five floors everywhere this
  ring — randomized depth per delve (user's idea) split into its own
  follow-on unit `m3-depth` (M3X, S/M, status table row added). Ordering:
  m3-dungeons → m3-depth → m3-magic → m3-craft → m3-quests.
- Worker mirror for this unit on: `docs/reports/BUILD-REPORT.md`
  (worktree-relative, gitignored); plans in `docs/plans/` (D42).
- User playtests pending: M2Q viewport (13); the full leave/travel/resume
  loop — decides follow-up 24 (camp expiry + road-danger teeth, NOT in
  M3D).
- UPDATE 2026-08-23: launched — session `residuum-m3-dungeons [f509d7]`
  (bg, user-created), kickoff delivered, no ruling vetoed. Blocked on: the
  build returning. Status table row → building.

### RESUME snapshot — 2026-08-22 session close: M3L+M3W merged; chore PR #7 open; M3D next (SUPERSEDED by the block above — kept for history)

- **M3W is CLOSED**: merged `958ef98` via PR #6 (D42); **1153 tests**
  (515/300/338) re-run green on `main` post-merge and survivability
  EXACTLY 24/40 with histogram 1:1 2:9 3:6 5:24, fleetfoot 7/40 — all
  measured this session. All worktrees and branches removed; sessions
  `residuum-m3-leave` and `residuum-m3-world` may be closed by the user.
  `main`: 958ef98 ← 844376f ← f7bd6b1 ← f758c3f ← 0656edb… (see D42).
- **Chore PR #7 OPEN, one file, no code** —
  https://git.fiatcode.dev/fiatcode/residuum-rpg/pulls/7 (`70238be`):
  BUILD-REPORT.md untracked → gitignored `docs/reports/`. The next
  architect verifies its merge trivially at re-orientation. FROM THE NEXT
  UNIT ON: build prompts point the worker mirror at
  `docs/reports/BUILD-REPORT.md`; written plans go to `docs/plans/`.
- Day's arc (this architect session): D34 world forks → D35 three-way
  split + rulings → M3L built/verified/merged (PR #5, D36–D38) → M3W
  built/verified/merged (PR #6, D39–D42), 829 → 1153 tests. Two
  device-only defect classes found (merchant validity on resume; flee
  unreachable by touch). Camp-expiry design discussion recorded as
  follow-up 24.
- **NEXT: spec `m3-dungeons` (M3D)** per D35 — sea-cave + ruined keep
  (bestiaries, tables, palettes), per-node floor salts (crypt salt =
  identity, floors byte-identical), light bottom-floor bosses +
  guaranteed rares on the NEW dungeons only, per-dungeon survivability
  bands, run-block dungeon identity. Recon seeds: `m3-leave-recon.md`
  findings 5–6, 8–10. Then m3-magic → m3-craft → m3-quests.
- User playtests pending: M2Q viewport (follow-up 13) and the full
  leave/travel/resume loop — the latter decides follow-up 24 (camp
  expiry + road-danger teeth, next dev loop, NOT in M3D unless the user
  says so).
- Blocked on: nothing — awaiting the user's #7 merge and the M3D
  go-ahead.

### RESUME snapshot — 2026-08-22, M3W verified; PR #6 open (SUPERSEDED by the block above — kept for history)

- **M3W is VERIFIED (D41) and PR #6 is OPEN** —
  https://git.fiatcode.dev/fiatcode/residuum-rpg/pulls/6, no conflicts,
  squash title ready. User squash-merges. On merge: pull, re-run suites on
  `main` (expect 1153), survivability 24/40 + histogram, remove
  `.worktrees/m3-world` + branches, close `residuum-m3-world [9758de],
  record the close-out, fold the handoff record.
- **THEN the approved chore (user: "chore it")**: untrack BUILD-REPORT.md
  → gitignored `docs/reports/BUILD-REPORT.md`; `.gitignore` gains
  `docs/reports/`; future plans go to `docs/plans/` (existing
  `docs/superpowers/*` history stays put); future build prompts point the
  mirror at `docs/reports/BUILD-REPORT.md`. Own small PR AFTER #6 merges
  (both touch BUILD-REPORT.md). Basis: the user's global CLAUDE.md
  routing rule, surfaced by the M3W worker.
- 1153 tests (515/300/338), 24/40 exact, fleetfoot 7/40 — all
  architect-measured this session in the worktree. Wave findings: flee
  was unreachable by touch (device-found, third AVD-only catch); three
  green mutation rows were real holes, fixed red-first (D41).
- NEXT after merge + chore: spec `m3-dungeons` (M3D) per D35 (sea-cave +
  ruined keep, per-node salts, light bosses, per-dungeon bands, run-block
  dungeon identity). Then m3-magic → m3-craft → m3-quests. Follow-up 24
  (camp expiry + road-danger teeth) decides after the user's playtest.
- Standing: exact baseline 24/40; save-format freeze (follow-up 20; the
  world block was one more sanctioned reshape); user playtests pending:
  M2Q viewport (13) and now the full M3L+M3W loop (24).
- Blocked on: the user's squash merge of PR #6.

### RESUME snapshot — 2026-08-22, M3L merged; M3W ready to hand off (SUPERSEDED by the block above — kept for history)

- **M3L is CLOSED**: merged `844376f` via PR #5 (D38); 897 re-run green on
  `main` post-merge and survivability 24/40 identical (measured this
  session). Worktree and branches removed; session `residuum-m3-leave` may
  be closed. `main`: 844376f ← f7bd6b1 ← f758c3f ← 0656eb1 ← 472e62b ← ….
  The suspend door ships: leave at stairs, resume or delve anew, `inside`
  boot fork, D36 merchant-validity invariant.
- **M3W `m3-world` is ready to hand off** (D34/D35 scope + D39 rulings):
  spec `m3-world-spec-M3W.md, prompt `m3-world-build-prompt.md, worktree
  `.worktrees/m3-world` @ `844376f, handoff record open. Launch:
  `cd <repo>/.worktrees/m3-world && claude -n residuum-m3-world --bg`.
  D39 rulings the user may veto: per-town shelves, one vault, encounters
  never serialized, discovery start state, boot-to-world.
- Baseline: 897 (408/225/264), 24/40 exact, histogram 1:1 2:9 3:6 5:24,
  fleetfoot 7/40 — measured post-merge this session.
- After M3W: m3-dungeons (M3D), then m3-magic → m3-craft → m3-quests
  (D20/D34/D35). User playtest of the M2Q viewport still pending
  (follow-up 13).
- Blocked on: the user's launch gesture for `residuum-m3-world`.

### RESUME snapshot — 2026-08-22, M3L VERIFIED; PR awaits the user (SUPERSEDED by the block above — kept for history)

- **PR #5 is OPEN** — https://git.fiatcode.dev/fiatcode/residuum-rpg/pulls/5
  (pushed + opened this session on the user's go-ahead; no conflicts; squash
  title ready in the PR). User squash-merges in the Forgejo UI.
- **M3L is VERIFIED (D37)** at branch head `92ec156` (14 commits, worktree
  `.worktrees/m3-leave`): 897 tests green (my runs), survivability EXACTLY
  24/40 + histogram + fleetfoot 7/40 (my run), landmine mutation re-run
  with my own sed (9 red, revert clean), analyze/format clean, forbidden
  levers untouched, AVD pass with 53 shots. Session
  `residuum-m3-leave [7aba1c]` is done and may be closed after merge.
- **Blocked on the user:** push `m3-leave` + open the PR (forgejo skill,
  per-round approval, D22), user squash-merges, then: re-run suites on
  `main` (expect 897), remove worktree + branches, record close-out, fold
  the handoff record into Handoff history.
- The wave produced two ledger rulings beyond the build: D36 (merchant
  block valid exactly as long as the visit — every future town↔dungeon
  door must answer whether it moved the visit; restate in the m3-world
  spec) and the D37 line that the AVD pass stays mandatory (second
  device-only catch).
- **NEXT after the merge: spec `m3-world` (M3W)** per D34/D35 — overworld
  node map (2 towns + crypt node), travel days + encounters (open-map
  generator, flee at edge), tavern rumors as discovery, world save block,
  navigation rework, death wakes at the last town, and the leave landing
  moves from town to the overworld. Then m3-dungeons (M3D). The recon that
  feeds M3W is already in `m3-leave-recon.md` (findings 5–9).
- Standing: exact baseline 24/40; save-format freeze (follow-up 20; the
  `inside` reshape was one more sanctioned in-place change); user playtest
  of the M2Q viewport pending (follow-up 13); RunEnded's died parameter —
  M3W reintroduces an alive end (worker note, D37).

### RESUME snapshot — 2026-08-22, M3L building; D34/D35 lock the world plan (SUPERSEDED by the block above — kept for history)

- **M3L `m3-leave` is BUILDING**: session `residuum-m3-leave [7aba1c]`
  (launched BY THE ARCHITECT on the user's advance authorization — D35
  session note; kickoff delivered this session). Worktree
  `.worktrees/m3-leave` @ `f7bd6b1`. Spec `m3-leave-spec-M3L.md, prompt
  `m3-leave-build-prompt.md, recon `m3-leave-recon.md, handoff record
  open.
- **D34 (user forks)**: leave-at-stairs suspend (no heal, no reshuffle on
  resume), flee-via-map-edge travel encounters, 2 towns + 3 dungeons
  (current dungeon = the crypt node), side-quests deferred to `m3-quests`.
  Follow-ups 8 and 22 resolved into it.
- **D35 (recon split + rulings)**: the D34 scope runs as m3-leave (S/M) →
  m3-world (L) → m3-dungeons (M). Key rulings: Enter-Dungeon forks
  Resume/Delve-anew (else the farming loop dies); required per-hero
  `inside` field; suspend clears the merchant block; the TownBloc
  `_settled` landmine fixed and pinned by mutation; inn-heal interim
  accepted until M3W prices it with travel.
- Baseline measured fresh this session on `main` @ `f7bd6b1`: 829 green
  (395/212/222), survivability EXACTLY 24/40, histogram 1:1 2:9 3:6 5:24,
  fleetfoot 7/40, analyze clean, Flutter 3.47.0.
- After M3L: verify per doctrine → user-approved PR → spec m3-world.
  User playtest of the M2Q viewport still pending (follow-up 13).
- Blocked on: the m3-leave build returning (the user is away; external
  writes wait for their return).

### RESUME snapshot — 2026-08-21 end of day, M3H merged; m3-world brainstorm next (SUPERSEDED by the block above — kept for history)

- **M3H is CLOSED**: merged `f7bd6b1` via PR #4 (D33); 829 tests re-run
  green on `main` post-merge (measured this session). All worktrees and
  branches removed; every unit's session may be closed. `main`: f7bd6b1 ←
  f758c3f ← 0656eb1 ← 472e62b ← 8596adb ← … ← be1da0a.
- Day's arc: M2Q → M3R → M3S → M3H, PRs #1–#4, 514 → 829 tests, D19–D33.
  The game persists, suspends roll-for-roll, and has a hero roster.
- **NEXT: the m3-world brainstorm with the user** (overworld node map, 3
  themed dungeons, travel encounters, rumors) — bring follow-up 8
  (mid-dungeon safe point) and follow-up 22 (a way out of a crawl that
  suspends rather than ends; switch-into-crawl is built but unreachable).
  Then m3-magic → m3-craft (D20).
- Standing: exact baseline 24/40; save-format freeze (follow-up 20); user
  playtest of the M2Q viewport pending (follow-up 13); stale architect
  session [114a3e] may still need closing.
- Blocked on: nothing — awaiting the user's return.

### RESUME snapshot — 2026-08-21 late, M3H verified; PR #4 open (SUPERSEDED by the block above — kept for history)

- **M3H is VERIFIED (D32) and PR #4 is OPEN** —
  https://git.fiatcode.dev/fiatcode/residuum-rpg/pulls/4, user
  squash-merges (title ready in the PR). On merge: pull, re-run suites on
  `main` (expect 829), remove `.worktrees/m3-heroes` + branches, close the
  `residuum-m3-heroes` session, record the close-out decision, fold the
  handoff.
- D31 proven by my own instrument: the canPop mutation that left 768
  tests green now reds two widget tests. New follow-ups 21–23 (stallable
  save-files fake; a suspend-not-end way out of a crawl → m3-world
  brainstorm with old follow-up 8; core _find/_without asymmetry).
- `main` = f758c3f, 768 green there; branch m3-heroes = 13 commits, 829
  green, 24/40 identical (all measured this session).
- NEXT after the merge: the **m3-world brainstorm** (overworld node map,
  3 themed dungeons, travel encounters, rumors — plus follow-ups 8 + 22).
  Then m3-magic, m3-craft (D20). User playtest of the M2Q viewport still
  pending (follow-up 13).
- Housekeeping: a stale architect session `[arch] residuum-rpg [114a3e]`
  kept confusing delivery — the user was asked (twice) to close it.
- Blocked on: the user's squash merge of PR #4.

### RESUME snapshot — 2026-08-21, M3H ready to hand off (SUPERSEDED by the block above — kept for history)

- **M3H `m3-heroes` is ready to hand off** (D28 forks + D31 widget-test
  grant): roster door (create named/switch/delete, never zero heroes),
  Abandon Hero retired, merchant buy-back at price paid + the
  stock-resurrection fix via per-hero visit state (one more sanctioned
  in-place v1 reshape), CLAUDE.md Testing amendment, first widget tests —
  mutation rows 7–9 re-run the formerly invisible wiring mutations and
  must redden. Worktree `.worktrees/m3-heroes` @ `f758c3f`. Session
  `residuum-m3-heroes`.
- `main` = f758c3f (M3S, PR #3) — 768 tests green post-merge and
  survivability exactly 24/40, both measured this session. M1→M3S all
  merged; the game persists across launches, suspend proven
  roll-for-roll.
- Standing: follow-up 20 (v1 freezes at first shipped build — every
  save-touching spec restates it); D15 band caution; house method —
  mutation rows on committed code, platform buttons on AVD, identifiers
  pasted never typed.
- After M3H: m3-world (L) → m3-magic (L) → m3-craft (M) per D20. User's
  viewport feel playtest still pending (follow-up 13).
- Blocked on: user gesture to start the build session.

### RESUME snapshot — 2026-08-21, M3S ready to hand off (SUPERSEDED by the block above — kept for history)

- **M3S `m3-saves` is ready to hand off** (D23 scope + D24 inputs): one
  versioned save document; content-owned codec (items as registry refs,
  64-bit values as strings, structured failures); app storage with
  verify-then-rotate two-slot fallback; suspend-save every settled state
  change (cadence measured on device); resume roll-for-roll; rolled world
  seeds; abandon-hero door (scope addition, user may veto). Spec
  `m3-saves-spec-M3S.md, prompt `m3-saves-build-prompt.md, recon
  `m3-saves-recon.md, worktree `.worktrees/m3-saves` @ `0656eb1, handoff
  open. Session `residuum-m3-saves`.
- M3R merged `0656eb1` via PR #2 (D25); 619 green on `main` and exact
  baseline **24/40**, both measured this session.
- Standing for this unit: core untouched; the suspend theorem test is
  non-negotiable; new trap — pin adb/flutter to `emulator-5554, a
  physical phone may be attached.
- After m3-saves: spec m3-world (L), then m3-magic (L), then m3-craft (M),
  per D20. User's viewport feel playtest still pending (follow-up 13).
- Blocked on: user gesture to start the build session.

### RESUME snapshot — 2026-08-21, M3R ready to hand off (SUPERSEDED by the block above — kept for history)

- **M3R `m3-rng` is ready to hand off** (D23: full suspend-save chosen by
  the user, so the PRNG must become state-exportable; M3S split into
  m3-rng → m3-saves). Spec `m3-rng-spec-M3R.md, prompt
  `m3-rng-build-prompt.md, recon `m3-rng-recon.md, worktree
  `.worktrees/m3-rng` @ `472e62b, handoff open. Session `residuum-m3-rng`.
- **The old exact survivability baseline (25/40) dies with this unit by
  design** — the band (50–95%) is the contract; the unit records the new
  X/40 as the future exact baseline. Worker stops and pings if the band
  fails; content tables only, with a trail.
- M2Q merged `472e62b` via PR #1 (D22); 613 green on `main, measured this
  session. PR flow is the standing merge mechanism now.
- After m3-rng: spec m3-saves (L — profile + full-run codecs in content,
  storage + autosave + corrupt fallback in app, rolled world seeds per D23).
- Blocked on: user gesture to start the build session.

### RESUME snapshot — 2026-08-21, M2Q merged; M3S next (SUPERSEDED by the block above — kept for history)

- **M2Q is CLOSED**: merged `472e62b` via PR #1 (new PR-based flow, D22);
  613 tests re-run green on `main` after the merge (measured this session).
  Worktree, local branch, and remote branch all removed. `main`: 472e62b ←
  8596adb ← 0824d8d ← 69d55e4 ← 961dc46 ← be1da0a.
- **NEXT: spec `m3-saves` (M3S)** per D20 — recon started this session:
  `newProfile()` boots with a DEFAULT worldSeed of 1 (every install plays
  the same world — new-game seed rolling belongs in M3S); Profile's variable
  state is hp, gold, bankedGold, visit, skills (level+xp), equipment,
  inventory, bank; items serialize naturally as base id + rarity + affix
  ids + item id, which points at a content-owned codec (core cannot import
  content). Open forks for the user: mid-run app-kill policy
  (save-scumming vs punishing crashes) and new-game world-seed rolling.
- Follow-ups added at D21: 14 (unify equip clamp — needs re-baseline),
  15 (cap-overflow quirk ruling), 16 (merchant/bank stacking), 17 (collapse
  repeated log lines). User's viewport feel playtest still pending
  (follow-up 13 conditional on it).
- Blocked on: the two M3S forks (user), then spec.

### RESUME snapshot — 2026-08-21, M2Q building; M3 split locked (SUPERSEDED by the block above — kept for history)

- **M2Q `m2-qol` is BUILDING**: session `residuum-m2-qol [1fad89], kickoff
  delivered this session. Worktree `.worktrees/m2-qol` @ `8596adb`. Spec
  `m2-qol-spec-M2Q.md, prompt `m2-qol-build-prompt.md, handoff record
  open. Baseline 352/95/67 = 514, measured fresh this session.
- **M3 decided (D20): full-fat, four sequential units, saves first** —
  m3-saves (S) → m3-world (L) → m3-magic (L) → m3-craft (M). Spec m3-saves
  only after m2-qol merges.
- Standing cautions: survivability band cannot detect the game getting
  easier (D15); M2Q must return exactly 25/40; stairs-bounce becomes an
  exploit the day regeneration lands.
- Blocked on: the m2-qol build returning (verify per doctrine, then
  user-approved merge).

### RESUME snapshot — 2026-08-21, M2Q ready to hand off (SUPERSEDED by the block above — kept for history)

- **M2Q `m2-qol` is ready to hand off** (D19 forks locked: camera-follow
  fixed-zoom viewport with free pan + snap-back on next action; inventory
  stats/grouping/stacking/worn-deltas; Engaged chip + refusal log line;
  town equip via two new Profile transactions reusing an extracted wear
  rule; potion count). Spec `m2-qol-spec-M2Q.md, prompt
  `m2-qol-build-prompt.md, recon `m2-qol-recon.md, worktree
  `.worktrees/m2-qol` @ `8596adb, handoff record open. Suggested session
  `residuum-m2-qol` (always `--bg`).
- Baseline measured fresh this session: 352 core + 95 content + 67 app =
  514 green on `main` @ `8596adb`; analyze clean; Flutter 3.47.0.
- Recon findings that bind: equip displacement can already exceed the pack
  cap (preserved quirk, pinned not fixed); walk refusal while watched is
  currently silent (`game_bloc.dart:171`); the watched predicate and the
  Engaged chip must share one home. Survivability must return exactly
  25/40 (no balance levers in this unit).
- Follow-up 6 closed (HP already clamps); follow-up 12 resolved into D19;
  follow-up 13 added (conditional swipe-to-step).
- NEXT after M2Q merges: M3 "The World" appetite discussion (started in
  this session), then M3 recon + split.
- Blocked on: user gesture to start the build session.

### RESUME snapshot — 2026-08-21, M2 COMPLETE (SUPERSEDED by the block above — kept for history)

- **M2 is COMPLETE.** M2T squash-merged as `0824d8d` (D16); `main` = 8596adb
  (README) ← 0824d8d ← 69d55e4 ← 961dc46 ← be1da0a. 514 tests re-run green
  on `main` after the merge (measured this session). All worktrees and
  branches removed.
- The full core loop is playable offline: town → descend → fight → loot →
  train → ascend/leave → bank → die → reshuffled grind.
- Remote exists and main is pushed: `origin` =
  https://git.fiatcode.dev/fiatcode/residuum-rpg.git (user-created repo,
  pushed this session with user approval). Ledger stays local per D1;
  future pushes remain user-approved per round.
- NEXT: collect the QOL backlog (follow-up 12) and triage; then spec M3 "The
  World" (overworld, dungeons, spells, crafting basics, saves). Standing
  caution from D15: the survivability band cannot detect the game getting
  easier — never cite it as regression coverage.
- Blocked on: nothing; awaiting the user's QOL list and/or M3 go-ahead.

### RESUME snapshot — 2026-08-21, M2T staged (SUPERSEDED by the block above — kept for history)

- **M2L playtest verdict: FUN** (D14). User reached floor 5 and got stuck —
  no exit exists yet, which is M2T's job. QOL backlog deferred (follow-up 12,
  collect after M2T).
- **M2T is ready to hand off** (D14 forks: stairs-choice exit + ascend with
  full within-run floor persistence, gold burns on death, creature pierce):
  spec `m2-town-spec-M2T.md, prompt `m2-town-build-prompt.md, worktree
  `.worktrees/m2-town` @ `69d55e4, handoff open. Suggested session name
  `residuum-m2-town`.
- Core architectural line in the spec: town is NOT a GameAction — new
  `Profile` value + pure transactions + `startRun`/`endRun` boundary; step()
  stays dungeon-only.
- Baseline for the build: 384 tests, measured fresh this session.
- After M2T merges: M2 complete → collect the QOL list, then spec M3.
- Blocked on: user gesture to start the build session.

### RESUME snapshot — 2026-08-21, M2L closed (SUPERSEDED by the block above — kept for history)

- **M2L is CLOSED**: squash-merged to `main` as `69d55e4` (D13), 384 tests
  re-run green on `main` after merge (measured this session), worktree and
  branch removed. `main`: 69d55e4 (M2L) ← 961dc46 (M2E) ← be1da0a (M1).
- **PENDING: the user's feel playtest** — especially whether armor dominance
  (follow-up 9) makes mid-depth fights boring. The verdict feeds m2-town's
  spec.
- **NEXT: spec `m2-town` (M2T)** — town screen, merchant, bank, gold, death
  penalty (visit-bump reshuffle), plus decisions queued for it: armor
  soft-cap (follow-up 9), mid-dungeon safe point (follow-up 8),
  ActionRefused rename (follow-up 11).
- Blocked on: user playtest verdict, then spec M2T.

### RESUME snapshot — 2026-08-21 (SUPERSEDED by the block above — kept for history)

- Session resumed after box restart; baseline re-measured fresh: `main` @
  `961dc46, 212 tests green.
- **M2L is ready to hand off** (D11 forks locked: six slots, affixes now,
  potions-only): spec `m2-loot-spec-M2L.md, prompt `m2-loot-build-prompt.md,
  worktree `.worktrees/m2-loot` @ `961dc46, handoff record open. Suggested
  session name `residuum-m2-loot`.
- Spec's centerpiece: the D9 balance mandate is a bot-simulation test —
  1→5 descent must win 50–95% of ≥30 seeded runs.
- Follow-up 8 added: mid-dungeon safe point (user note, D11) → m2-town/M3.
- Blocked on: user gesture to start the build session.

### RESUME snapshot — 2026-08-20, M2E closed (SUPERSEDED by the block above — kept for history)

- **M2E is CLOSED**: squash-merged to `main` as `961dc46` (D10), 212 tests
  re-run green on `main` after merge (measured this session), worktree and
  branch removed. `main` history: 961dc46 (M2E) ← be1da0a (M1).
- **NEXT: spec `m2-loot` (M2L) — ON HOLD at the user's request** (box
  restart). When resuming: recon the merged code fresh, then spec M2L —
  items, affixes, rarities, inventory, equipment slots, 4 melee skills
  (Arms/Might/Bulwark/Fleetfoot), plus the BINDING balance mandate from D9
  (1→5 descent must be survivable with the loot/healing added; depth-1-2
  spawn tables are the fallback lever). Then m2-town last.
- Sandbox is disabled (user trial, D9 note) — the sandbox traps are dormant.
- Channel: SendMessage worked both directions this round; keep the
  BUILD-REPORT.md mirror instruction in future build prompts anyway.

### RESUME snapshot — 2026-08-20, late night (SUPERSEDED by the block above — kept for history)

- M1 fully closed: merged `be1da0a, worktree deleted, branch gone, journal +
  `[[Residuum]]` page written in the weft graph.
- M2 split into three sequential units (D8): M2E engine → M2L loot → M2T town.
- **M2E is ready to hand off**: spec `m2-engine-spec-M2E.md, prompt
  `m2-engine-build-prompt.md, worktree `.worktrees/m2-engine` @ `be1da0a,
  handoff record open. Baseline 93 tests, measured fresh today.
- Suggested session name `residuum-m2-engine`; `--bg` viable again (device
  commands sandbox-excluded, D8). Fallback report file `BUILD-REPORT.md` in
  the worktree covers the undelivered-SendMessage risk (follow-up 7).
- New trap burned twice this session: creating `.git/worktrees/` and deleting
  `.claude` config files inside a worktree both fail under sandbox (EROFS /
  "busy") — run `git worktree add`/`remove` and worktree deletion unsandboxed.
- Blocked on: user gesture to start the build session.

### RESUME snapshot — 2026-08-20, night (SUPERSEDED by the block above — kept for history)

- **M1 is CLOSED**: squash-merged to `main` as `be1da0a, suites re-run green
  on `main` after merge (measured this session). Branch and worktree removed
  (a few files stay pinned until the user closes the `residuum-m1-crawl`
  session — then `rm -rf .worktrees/m1-crawl && git worktree prune`).
- **Playtest verdict: fun.** The glyph crawl works as a game.
- NEXT: spec M2 "The Loop" — seeded floor generation, loot with rarities,
  inventory + equipment, first 4 skills, town screen (merchant + bank), death
  penalty — plus triage of follow-ups 3 (flow-field chase), 5 (actor display
  name, id uniqueness), 6 (HP clamp).
- Open infra question: worker→architect SendMessage held for approval,
  undelivered (follow-up 7).

### RESUME snapshot — 2026-08-20, evening (SUPERSEDED by the block above — kept for history)

- M1 is BUILT and architect-VERIFIED on branch `m1-crawl` (14 commits, worktree
  `.worktrees/m1-crawl`): 93 tests green, analyze/format clean, mutation table
  held (row 3 independently re-run), AVD playthrough done by the build session.
  All numbers measured fresh this session except the 500-seed balance figures
  (worker-measured, not reproduced).
- Known accepted defect: greedy chase freezes on zero-delta + wall (D6);
  flow-field fix is follow-up 3, targeted at M2.
- `equatable` accepted into core at the user's direct request (D6).
- NEXT: user merge approval for `m1-crawl` → `main, then the user's own fun
  playtest; then spec M2.
- Build session `residuum-m1-crawl [004c46]` is done; its SendMessage to the
  architect never delivered (held for approval) — user relayed by hand
  (follow-up 7).

### RESUME snapshot — 2026-08-20, later (SUPERSEDED by the block above — kept for history)

- M1 fully specced and ready to hand off: recon done
  (`RECON-2026-08-20.md`), story spec (`m1-crawl-spec-M1.md`), build prompt
  (`m1-crawl-build-prompt.md`), handoff record open (`m1-crawl-handoff.md`).
- Worktree `.worktrees/m1-crawl` (inside the repo, gitignored) on branch
  `m1-crawl, base `b2256ef` (created this session; moved from `../` per D4).
- Waiting on the user to start the build session:
  `cd /var/home/dhemas/Development/Projects/_temp/residuum/.worktrees/m1-crawl && claude -n m1-crawl --bg`
  then the architect sends the pointer message.
- Toolchain numbers (Flutter 3.47.0, Dart 3.13.0, Chrome-only device, no
  emulators) measured fresh this session — see recon doc.
- Blocked on: user gesture only.

### RESUME snapshot — 2026-08-20 (SUPERSEDED by the block above — kept for history)

- Repository exists at `/var/home/dhemas/Development/Projects/_temp/residuum`
  with spec + conventions committed. **No code yet.**
- Design spec and code conventions are user-approved (measured this session:
  both reviewed in-conversation today).
- Toolchain measured this session: Flutter 3.47.0 stable, Dart 3.13.0, Linux.
  No fvm pinning in this repo yet.
- Next: story spec + build prompt for M1 (`m1-crawl`), then user starts the
  build session.
- Blocked on: nothing.

## Operating model

Architect/build split per the ledger-driven-development skill. This session
(and successors) is the architect: specs, prompts, verification, ledger. Build
sessions write all production code, on named branches, created by the user.
Agents may be spawned freely for read-only work only.

- **House method, UI units (amended D113): widget-driven implementation.**
  Screen-shaped widget tests, phone-sized via a shared helper, drive the
  build loop; the AVD pass stays MANDATORY but is the final acceptance
  gate only — one install + save ritual + scripted taps + greyscale shots
  at unit close, never the inner loop. Paint-timing and real-disk defect
  classes remain device-pinned.

## Epic status

Status markers: `✅` merged · `→` in progress · `▶` ready to hand off ·
`⏸` partial · `⛔` blocked · `🚩` needs a human decision · `⬜` not started.

| Phase | Story | Findings | Effort | Status | Notes |
|---|---|---|---|---|---|
| M1 The Crawl | M1: monorepo scaffold, core engine (move/attack/death), fog of war, glyph renderer, tap input | chase-freeze defect (D6); 93 tests green; playtest: fun | M | ✅ | merged `be1da0a` (D7) |
| M2 The Loop | M2E `m2-engine`: speed clock, flow-field chase, seeded 5 floors, auto-path, 5 monsters | 212 tests; report-artifact mismatch resolved (D9); balance figures for M2L | M | ✅ | merged `961dc46` (D10) |
| M2 The Loop | M2L `m2-loot`: items, affixes, rarities, inventory, equipment, 4 skills, potions, survivability mandate | 384 tests; 70% survivability; row-4 spec error mine (D12) | L | ✅ | merged `69d55e4` (D13); user feel playtest pending |
| M2 The Loop | M2T `m2-town`: Profile/run boundary, ascend + floor persistence, town/merchant/bank/inn, death penalty, pierce | 514 tests; 62.5% band; band-can't-detect-easier caution (D15) | L | ✅ | merged `0824d8d` (D16) — **M2 COMPLETE** |
| M2 The Loop | QOL `m2-qol`: camera-follow viewport, inventory presentation (stats/grouping/compare/stacking), battle indicator, town equip, potion count | 613 tests; 25/40 held; two spec defects mine; clamp divergence ruled (D21) | M | ✅ | merged `472e62b` via PR #1 (D22) |
| M3 The World | M3R `m3-rng`: state-exportable PRNG behind the Rng API, re-pin seeded tests, re-baseline survivability | 619 tests; new baseline 24/40; latent test defect repaired; recon blast-radius wrong (D24) | M | ✅ | merged `0656eb1` via PR #2 (D25) |
| M3 The World | M3S `m3-saves`: multi-hero suspend-save document, content-owned codecs, back guard, corrupt fallback, rolled world seeds | 768 tests; 24/40 identical; suspend proven roll-for-roll; 3 boot defects device-found (D27–D29) | L | ✅ | merged `f758c3f` via PR #3 (D30) |
| M3 The World | M3H `m3-heroes`: roster screen (create/switch/delete heroes), abandon-hero retired, merchant buy-back + stock persistence, first widget tests | 829 tests; rows 7–9 red (D31 proven); recon corrected — silent item loss (D32) | M | ✅ | merged `f7bd6b1` via PR #4 (D33) |
| M3 The World | M3L `m3-leave`: leave-at-stairs suspend, resume/delve-anew door, boot disambiguation, town-bloc run carry fix | 897 tests; 24/40 identical; D36 device-found defect; 4 spec claims corrected (D36/D37) | S/M | ✅ | merged `844376f` via PR #5 (D38) |
| M3 The World | M3W `m3-world`: overworld node map (2 towns + crypt node), travel days + encounters (flee via edge), tavern rumors as discovery | 1153 tests; 24/40 identical; flee unreachable-by-touch device-found; 3 green rows were real holes (D41) | L | ✅ | merged `958ef98` via PR #6 (D42) |
| M3 The World | M3D `m3-dungeons`: sea-cave + ruined keep themes, per-node salts, run-block dungeon identity, light bosses + guaranteed rares, per-dungeon bands, crypt pin promoted to assertion | 1259 tests; core diff EMPTY; 5th device-only catch (phone overflow); analyze-scope + histogram-pin lessons (D44) | M | ✅ | merged `59b91f1` via PR #8 (D45) |
| M3 The World | M3X `m3-depth`: randomized depth per delve (sea-cave 4–6, keep 5–7, crypt fixed 5), per-run deepest threading, derived roll | 1296 tests; crypt character-identical; bot-stall + copyWith-carry defects found by rows; coincidence-mutant + fixture-delta doctrine (D47) | S/M | ✅ | merged `b9d7c21` via PR #9 (D48) |
| M3 The World | M3B `m3-balance`: pierce/litter/drops rebalance, camp expiry, discovery rule, road scaling, delve completion, UX beats + reasons, follow-ups 14/15 | 1361 tests; crypt 50%/cave 77.5%/keep 70% converged via a 20-step trail; instrument defect fixed; 6th device catch; D51/D52 mid-flight rulings | L | ✅ | merged `936ca5b` via PR #10 (D54) |
| M3 The World | M3M `m3-magic`: three school skills, spell books, six first spells, spell-typed damage vs creature resistances, hero-only mana, saveVersion 2 | 1570 tests; bands re-pinned per D56 (50/75/62.5); 7th device catch; worker refuted C1 pre-code and closed a shipped-cast coverage gap (D56/D57) | L | ✅ | merged `83b5336` via PR #11 (D58) |
| M3 The World | M3C `m3-craft`: gathering nodes (state, own stream), materials as counters, Forge (smelt+temper) + Alchemist (brew) both towns, Herbcraft + Blacksmith, saveVersion 3 | 1790 tests; bands held BYTE-IDENTICAL (C1 proven); gatherSalt by collision sweep; 8th device catch (glyph-width columns); ×2 temper term corrected by worker (D60/D61) | M | ✅ | merged `54ec315` via PR #12 (D62) — playtest verdicts landed: balance endorsed, 2 defects + 3 UX verdicts (D63) |
| M3 The World | M3F `m3-fixes`: road-encounter carry (spells/materials/mana), remembered node rendering, town Gear→Character menu | 1810 tests; bands byte-identical; three worker sessions (two pi + one Claude Code, D64/D66/D68); mutation predictions corrected by measurement (D67); node fix proven in device pixels | S/M | ✅ | merged `8168861` via PR #13 (D70) |
| M3 The World | M3Q `m3-quests`: side-quest templates, quest state, payouts, reputation | added D34 | S/M | ⬜ | not specced; ordering now behind the battle overhaul (D71) |
| M3→M4 Battle | Battle overhaul: battle screen as a view over the map fight, ambush openings, turn-order strip, ranged reach | added D71 | XL | ✅ | unit A `m3-battle` merged `d576d1c` (D82); unit B `m3-battle-ui` merged `fda107f` (D89); artifacts: m3-battle-recon/spec/prompt/report/handoff, m3-battle-ui-recon/spec/prompt/report/handoff |
| M3 The World | M3I `m3-itemids`: hero-scoped item-id mint at pickup, remove-one semantics on every id-consuming action, codecs omit-on-default (playtest #2 V10 fix) | 1941 tests; five bands byte-identical; save v3 stands; follow-ups 33/34 filed | S | ✅ | merged `594bc80` via GitHub PR #1 (D101) |
| M3 The World | M3BF `m3-battle-flow`: the battle interaction rebuild — NOW/IN-N chips + whole-header backing, armed-target flow with attack as a bar action, bump-attack + map tap-to-attack retired, bare tap = enemy info, core `WaitAction`, two-state battle glyph (playtest #2 V1+V2+V8+V9) | 1974 tests; five bands byte-identical; 4 pre-declared deviations approved; AVD pass + greyscale shots | M | ✅ | merged `bf8bcb6` via GitHub PR #2 (D106) |
| M3 The World | M3SH `m3-save-hardening`: the save pipeline stops failing silently — write-path reporting (renames in the failure handling, queue sink, refuse-to-advance + autosaver rewire), guarded boot + failure screen, thrown-read fallback, decode refusals (speed/energy/gear-inclusive hp/skills/reach/duplicate ids per D108), engine-boundary guard, IoSaveFiles coverage, door reentrancy guard, sealed SaveNotice + TownCrawl, TTC-7/9 riders (audit group 1) | 2045 tests; goldens byte-identical, bands verbatim; deviations P1–P8 acked + two disclosed; 14-row mutation sweep | L | ✅ | merged `b2c1381` via GitHub PR #3 (D112) |
| M3CH `m3-chore`: CI workflow (matrix, three suites + analyze + format, exact Flutter pin), analyzer config + lints/recommended for core/content, lockfiles committed, README + app README refresh (audit group 2, D114) | 2045 green; bands verbatim; M3 red / M4 green on real CI → PR #6 (fail-fast off + drift gate, CI green); branch protection = user's act | S | ✅ | merged `348cb14` via GitHub PR #4 (D118); follow-up PR #6 open |
| M3CR `m3-craft-risk`: free benches (gold retires), tiered level-scaled craft failure (t1 0% / t2 20% / t3 35%, −2%/level, floor 5%; brew 20% − 2%/level, no gate), lose-1-on-fail, xp on failure, sealed TownAnswer, profile-carried craft stream (salt 0x0C7A, omit-on-default) | 2077 tests; bands verbatim; goldens byte-identical; M6 red set corrected worker-caught (D124) | M | ✅ | merged `bd848f7` via GitHub PR #9 (D125/D126) |
| M3TUX `m3-town-ux`: V3 forge price always visible + refusal word separate, V5 notice town-only, V6 steppers + MAX + tap-and-hold (pending count + one commit) + WORN/CARRIED forge sections, V7 merchant stacking — FIRST D113 widget-driven unit | 2116 tests (860/579/677); bands verbatim; goldens byte-identical; zero core/content diff; M1 re-run by architect; one mid-unit red disclosed + fixed (D127) | M | ✅ | merged `85e7bcc` via GitHub PR #10 (D127/D128); worktree anomaly #2 (D128) |
| M4 The Story | Act 1 beats, sets, bosses, perks | — | L | ⬜ | not specced |
| M5 The Garden | Acts 2–3, recipes, tile renderer, balance | — | ongoing | ⬜ | not specced |

## Environment traps

Each restated verbatim in every build prompt.

- `flutter test packages/<pkg>` from the repo root fails: this monorepo
  has NO root pubspec.yaml. Run suites per package directory
  (`cd packages/<pkg> && flutter test`) — D101.
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
- The AVD's /data can sit at ~92% full (485M free) so a plain install
  fails with INSTALL_FAILED_INSUFFICIENT_STORAGE and a cache trim frees
  almost nothing (M3F, 2026-09-01). Resolution that worked: uninstall the
  OLD build — legal ONLY after BOTH save slots are verified copied aside
  with checksums — then install the new APK (~153,590,984 bytes).
- Restoring device saves via /data/local/tmp push + `run-as cp` fails
  ENOENT under the app domain (SELinux-shaped); stream the bytes through
  `run-as stdin` instead (M3F).
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
- ~~`tea pr create` does not resolve a worktree's `.git` file — run it from
  the MAIN repo root (`cd <repo> && tea pr create ...`), where it reads
  the remote fine.~~ SUPERSEDED (D96): the repo is on GitHub — `gh pr
  create` from the main repo root (gh resolves worktree .git files fine,
  but PRs still come from the main root per flow).
- Cross-session message holds bite BOTH directions: an INTERACTIVE session
  holds incoming messages behind an approval gate that expires — including
  worker→architect replies when the architect is interactive (burned M2T's
  kickoff and M2Q's reply). A worker cannot tell an interactive architect
  from a bg one via kickoff metadata, and a stale same-named session makes
  addressing a coin flip. Keep exactly one architect session alive; the
  BUILD-REPORT.md mirror is the working fallback; expect to relay by hand
  when the architect runs interactive.
- `find.textContaining` in Flutter 3.47 is case-sensitive with no
  `caseSensitive` parameter — match the literal casing or use a regex
  (cost the M3F worker investigation time, recorded D65 era).
- `scrollUntilVisible` computes ONE moveStep from the axis direction, so
  it can never scroll back up — assertion sequences on a long screen must
  be monotonic in document order (M3F worker finding; bind every HUD+cast
  widget pass).
- A worker harness's AUTO-FORMAT hook can re-dirty a file seconds after a
  revert lands (M3CH, D115: `git checkout -- <file>` reported clean, then
  a 'File was modified by auto-format/fix' notice re-wrote it). After any
  revert here, re-check `git status --porcelain` a beat later, not just
  once.

## Open questions

- **Yours to decide** — none currently.
- **Needs someone else** — none; solo project.

## Follow-ups

1. Consider pinning Flutter via fvm once packages exist, so builds reproduce.
2. Rename working title "Residuum" if a better name appears (spec allows).
3. (M2) Breadth-first flow-field monster chase, replacing the freezing greedy
   rule — from D6.
4. (M2, already planned) Speed-clock scheduler, tap-to-auto-path, seeded floor
   generation.
5. (M2) `Actor` needs a display-name field before a second monster type exists;
   monster id uniqueness is unenforced until spawn logic exists.
6. ~~(Polish) HP label shows negative values on death ("-3 / 20") — decide
   whether to clamp at zero.~~ CLOSED (D19): already clamps at
   `game_screen.dart:54, verified live.
7. ~~(Infra) Investigate why build-session → architect SendMessage was "held
   for the recipient user's approval" and never delivered.~~ CLOSED (D9):
   stale architect socket.
8. ~~(m2-town or M3) Mid-dungeon "safe point" — a rest spot partway through a
   long dungeon. User design note from D11.~~ RESOLVED (D34): ships as the
   leave-at-stairs exit in m3-world — an exit, not a heal.
9. (m2-town, needs a decision) Armor soft-cap: once armor exceeds a monster's
   max roll, the floor-of-1 rule makes it harmless — percentage reduction,
   total-armor cap, or armor-piercing monsters. From D12; the worker measured
   depth-3 fights stop being decisions at 2–3 armor pieces.
10. (M3+) Lumpy difficulty: deaths cluster on depths 2–3 (2:42/3:28/4:8 over
   200 seeds); revisit as depth 4–5 content grows.
11. (m2-town spec) Consider renaming EquipRefused → ActionRefused; it already
   carries pick-up refusals. → SANCTIONED into the M2T spec (D14).
12. ~~(after M2T) QOL backlog — the user has a list of quality-of-life
   improvements from the M2L playtest; collect and triage it once M2 is
   complete. Known entries so far: no equip screen in town (gear bought at
   the merchant cannot be worn until floor 1 — from the M2T worker).~~
   RESOLVED (D19): collected, triaged, and scoped into unit `m2-qol`.
13. (post-m2-qol, conditional) Swipe-to-step input — revisit only if
   surrounded combat still feels clumsy on ~36dp cells after the viewport
   rework (D19).
14. (needs an architect ruling + re-baseline) Unify the equip hit-point
   clamp: the dungeon clamps only on take-off, the town on both paths
   (D21). Unifying moves the 25/40 baseline; both sides pinned by test
   meanwhile.
15. (needs an architect ruling) The cap-overflow-on-displacement quirk —
   pinned in both contexts (D21); fixing it is a ruling about the cap.
16. (later QOL) Stacking for merchant stock and bank lists —
   `packSections`/`stackKey` are ready for them.
17. (polish) Collapse immediately repeated message-log lines (a player
   jabbing at a far tile while watched stacks identical refusal lines).
18. (test hygiene, from D24) Audit tests for records carrying a `List`
   compared with `==` or collected into a `Set` — the List compares by
   identity and the assertion silently stops comparing that field.
19. (polish, from M3S) Message-log persistence across suspend — the log is
   app view-state and is deliberately dropped on resume; revisit if the
   one-line "the crawl resumes" feels thin in play.
20. (STANDING, from D29) Save-format freeze: the first shipped build
   freezes document version 1. Any shape change after that is a version
   bump plus a migration path. Nothing in code enforces this — every
   future save-touching spec must restate it.
21. (test hygiene, from D32) A stallable fake save-files that can hold a
   write mid-flight, so the roster's close-before-rebuild await is pinned
   by a test (today, deleting that await reddens nothing).
22. ~~(design, from D32) A way OUT of a crawl that suspends rather than
   ends it — switch-into-a-suspended-crawl is built and tested but
   unreachable by play. Kin to old follow-up 8 (mid-dungeon safe point);
   bring both to the m3-world brainstorm.~~ RESOLVED (D34):
   leave-at-stairs suspend in m3-world.
23. ~~(core ruling, from D32) `_find`/`_without` asymmetry in town.dart:
   first-match pricing with every-match removal silently destroys
   duplicate-id items. Latent while ids stay unique by construction;
   consider an assertion or unified semantics next time core opens.~~
   CLOSED (D99, m3-itemids): the mint at the pack's door makes ids
   hero-unique by construction, and every id-based removal — town's
   `_without` included — is now remove-first via the shared
   `withoutFirst`. The asymmetry is gone, not papered over.
24. (BALANCE, next dev loop after the M3W playtest — user + architect
   discussion 2026-08-22) **Camp expiry:** the leave/resume door stays; its
   price changes. A camp left standing more than K days (start at 3) is
   overrun — residue refills the wound — and the crawl collapses as if
   abandoned (visit-bump reshuffle; gear and bank untouched). Re-prices the
   inn loop (heal trip fits the window, shopping tours do not), keeps
   follow-up 8's relief value, keeps roll-for-roll inside the window (the
   suspend theorem survives byte-identical), and gives the day counter a
   job that M3Q deadlines and M3C gathering can reuse. Companion lever to
   evaluate at the same time: road danger tables have no teeth for a
   strong hero (road fights are currently net income — xp and drops with
   a flee cap on the downside); consider danger scaling by hero
   progression. Also decide: an expiry warning notice (probably yes).
   Rejected in discussion: removing the door (regresses follow-ups 8/22
   and makes suspend unreachable by play again); per-day food/upkeep (new
   subsystem, taxes all travel); inn refusing camped heroes (contrived);
   monster respawn on kept floors (breaks the suspend theorem). NOT in
   M3W — its scope is frozen; ships as a small ruling-sized unit or rides
   M3D, decided after the user plays the full loop.
25. (design, from D44) `arrivingAt` reveals a node's neighbours on
   arrival, so reaching Northgate uncovers both new dungeons free and
   their rumors become unsellable — "rumor-hidden" is weaker than it
   reads. Core behavior, out of M3D's scope. Options when it opens:
   arrival reveals routes but not far nodes; or rumors gate only nodes
   beyond one hop. Decide after the playtest, possibly riding m3-depth.
26. (test hygiene, from D44) The widget suite's default surface is
   800×600 — wider than a phone in portrait; it measured a screen no
   player has, and the status-row overflow was invisible until the
   device pass. New-screen units should size at least one widget test
   like a phone (1080×2424 precedent in world_screen_test).
27. (verification doctrine, from D44, extended D47) Analyze runs from the
   WORKTREE ROOT (`dart analyze .`), never from a package directory — a
   package run does not reach sibling packages' test dirs. Verification
   blocks quote the `pwd` beside the command. Mutation reds are reported
   as a NAMED SET, not a count — the count is a property of the sed.
   D47 additions: a mutant whose replacement range can COINCIDE with the
   original value at a test's fixture seed under-reports its red set —
   prefer constant shifts that cannot coincide; and an acceptance pass
   that seeds a device save states its fixture's stat delta from the
   real starting hero FIELD BY FIELD, then argues each observation past
   the delta ("nothing is synthetic" is never the sentence).
28. (instrument, from D53) The survivability bot never plays the deepest
   floor — arriving is winning — so every dungeon's bottom spawn table,
   bosses included, is unmeasured by every band; a real player meets it.
   A bottom-floor instrument (or a bot that fights what it finds there)
   is future work; until then no band may be cited as boss coverage.
29. (instrument, from D57/D58) ~~No band measures a casting hero — the
   bot is melee-only by design, so spell balance (mana budget, gate
   pacing, bind/banish value) and `heroMaxMana`'s base of 4 are
   human-judged only. A spell-casting bot variant (informational line
   first) is the instrument to build when magic balance needs one.
   Extends follow-up 28's spirit to a whole mechanic.~~ CLOSED (D74/D80):
   the casting build shipped in m3-battle unit A — reads its book, casts
   Firebolt at the fallback target, informational line pinned at 40/40
   with the not-apples-to-apples dartdoc (kit door ≠ greedy door).
30. (device check, from D57) ~~The status line gained `Mana n/m` and
   sometimes `Ward n`; it fits the emulator but has not been seen on a
   real phone. Check at the next device session (label ellipsization is
   a known device-only killer).~~ CLOSED (D87/D89): read at the
   phone-sized surface in the m3-battle-ui AVD pass (shot-01, all fields
   present, no ellipsization). The physical-phone read happens whenever
   the user next plays on theirs — note it, don't gate on it.
31. (polish, from D69) ~~Skills-row crowding on a 360-wide phone: the
   longest skill name touches its level digit ("Blacksmith0" where
   shorter names read "Herbcraft 0"). Legible, contract met, cosmetic —
   rides the HUD+cast unit the next time that row grammar opens.~~
   CLOSED (D85–D89): fixed in m3-battle-ui (8 px seam), pinned by
   `skills_row_spacing_test.dart` at the phone surface; merged in
   `fda107f`.
32. (design intent, from the user, 2026-09-02) Monsters will eventually
   use exclusive skills and spells — both attacking and supporting — and
   interact in group battle: e.g. a shaman healing its allies mid-fight.
   This is the standing direction for the monster-ability lever; every
   monster skill needs named draws (seed contract) and a bestiary ruling
   under the tiered lever rule. The battle overhaul's stage/strip model
   is designed to carry it.
   Anti-spam constraint (user, 2026-09-02, confirmed: monsters have no
   mana today — `Actor` carries no mana field): a monster caster must
   never be able to spam. Candidate mechanisms at ruling time: per-
   encounter charges (the bind-counter precedent — ticks in the monster's
   own turns), or a real Actor mana pool with regen. Architect lean:
   charges, spam-proof by construction; the ruling belongs to the
   bestiary unit that ships the first caster.
33. (from m3-itemids worker review, 2026-09-03) `merchant_visit.dart`
   `withoutSold` still removes ALL matches from the merchant's stock
   list — ids are visit-scoped and unique by construction, so harmless
   today; becomes a defect only if stock persists across visits (same
   trigger as follow-up 16's bank stacking). Ride 16 when it opens.
34. (from m3-itemids worker review, 2026-09-03) `temperItem`'s worn
   branch replaces every matching SLOT — a legacy save with one id worn
   in two slots would temper both while `heldItem` named only the first.
   Extremely exotic; consider when core next opens tempering.
35. (from the 2026-09-03 audit, D102) Save-write path hardening: the
   discarded `save()` bool, renames outside the failure handling, the
   poisonable autosave queue, refuse-to-advance on a failed hero create.
   → the m3-save-hardening unit.
36. (audit, D102) Unguarded boot: a thrown `bootFrom` is a black screen;
   a thrown read bypasses the current→previous slot fallback. →
   m3-save-hardening.
37. (audit, D102) Semantic decode validation: `speed: 0` throws out of
   `step()`, huge `energy` hangs the scheduler, hp > maxHp, item-id
   duplicates, unvalidated skill levels (TTC-8/TTC-10 fold here); plus
   the engine-boundary guard so an ArgumentError becomes a refusal.
   → m3-save-hardening.
38. (audit, D102) `IoSaveFiles` — the only adapter touching real player
   data — has zero coverage; its unspecified exception contract is
   load-bearing. → m3-save-hardening.
39. (audit, D102) Door-opening reentrancy: silent refusal leaves a stale
   `firstWhere` listener; no double-tap guard. → m3-save-hardening.
40. (audit, D102) TownViewState's four coupled crawl fields guarded by
   prose and hand-written carry lists — collapse to one sealed value +
   one table-driven carry test. Rider on m3-save-hardening if
   measurement allows, else its own small unit.
41. (audit, D102) No CI: one workflow (three suites + analyze + format,
   required on PRs to main), plus analyzer config for core/content and
   committing their lockfiles. → the chore unit.
42. (audit, D102) README stale by a full milestone ("M2 complete, 514
   tests"); app README is boilerplate. → chore unit (docs).
43. (audit, D102, NEEDS THE AUTHOR) CLAUDE.md names `combat/` and
   `quest/` (nonexistent) and omits `magic/` and `town/`; and the
   comment-policy direction must be picked — amend the rule to sanction
   rationale-dartdoc (47 private dartdocs exist; step.dart's body blocks
   carry balance data found nowhere else), or enforce the rule and
   relocate the rationale.
44. (audit, D102, PRE-SHIP) Real signing config from gitignored
   `key.properties`, replace the `com.example` application id, declare
   (or explicitly decline) Android auto-backup. Must land before the
   first distributed build; none blocks development.
45. (audit CDH-3) The ambush-opening loop keeps striking a dead hero —
   extra events and rng draws after death. Small core fix; rides the
   next unit that opens step.dart.
46. (audit TTC-9/TTC-7) The codec totality test never reaches a deep
   decoder (10 of 12 fixtures stop at the version gate), and
   `SavedHero`'s two invariants have no test. Test hygiene; ride
   m3-save-hardening's test work.

## Decision log

Append-only. Never rewrite a past entry — supersede it with a new one.

### D1 — 2026-08-20 — Epic runs ledger-driven, local mode, in `docs/epic/`

- Ledger is LOCAL (gitignored), single architect (the user, solo). Decided by
  the user this session.
- Artifact naming locked: `<unit>-<type>` with `<unit>` = branch name. First
  unit: `m1-crawl`. Story IDs are milestone IDs (M1…M5).
- Build prompts cite specs by absolute path (local-mode consequence).
- Rejected: shared/committed ledger — team-shaped overhead with no team.

### D2 — 2026-08-20 — Design and conventions locked before any code

- Game design spec approved by user (turn-based grid, glyphs-then-tiles, phone
  touch-first, persistent hero with death penalty, 13 skills, recipe-capped
  crafting, node-graph overworld, menu towns, AI-written author-steered story,
  JSON snapshot saves). See spec file for full detail.
- Architecture locked: 3-package monorepo (`core`/`content`/`app`), dependency
  rule app→content→core, immutable GameState with
  `step(state, action) → (state, events), Rng carried in state, feature
  folders, BLoC-only tests in app, strict TDD in core.
- Rejected: Flame engine now (no real-time loop needed); full Clean
  Architecture layering and DDD ceremony (vocabulary and boundaries kept,
  ceremony dropped); mutable simulation objects (harder to test/save).
- Locked: nobody re-litigates engine choice or state model inside a build
  session. Changes come back here as decisions.

### D3 — 2026-08-20 — M1 scope forks locked; build runs in a named background session

- User locked four M1 forks: 4-way orthogonal movement; simple alternation
  turn scheduling (speed clock deferred to M2); fog of war IN scope
  (shadowcasting, radius 8, explored-dimmed memory); tap input adjacent-only
  (auto-path deferred to M2).
- Rejected for M1: diagonals (tap ergonomics + corner cases), speed clock now
  (nothing varies speed yet), no-FOV (would make the fun test ambiguous),
  auto-path (needs A* + interrupt rules).
- Handoff mechanism: user-created named session `m1-crawl` in worktree
  `../residuum-m1-crawl`. Running it `--bg` moves authorization from
  per-action to per-session — accepted trade; the user may drop `--bg` to
  watch interactively instead.
- Hero/ghoul stat line (20 hp 3–5 vs 3× ghoul 10 hp 2–4) is explicitly a first
  guess; the build session may tune it and must report the change.

### D4 — 2026-08-20 — Worktrees live inside the repo at `.worktrees/<branch>` (gitignored)

- User decision: worktrees go in `<repo>/.worktrees/, not as sibling
  directories outside the project. `.worktrees/` added to `.gitignore`.
- Supersedes the worktree path in D3's handoff mechanism; branch, base commit
  and session naming are unchanged. Applies to every future unit.

### D5 — 2026-08-20 — M1 visual verification runs on the Android emulator, not Chrome

- User decision: verify M1 visually on AVD `Pixel_10` (exists already —
  measured via `emulator -list-avds` this session), not headless Chrome.
- Two recon corrections behind this: (1) `/dev/kvm` and other device nodes are
  invisible inside sandboxed Bash — the earlier "Chrome is the only viable
  target" verdict was a sandbox artifact, not a host fact; (2) `flutter
  emulators` cannot see/create AVDs with the installed ps16k system images,
  but the `emulator` binary works. Both added to environment traps.
- Consequence: the "do NOT attempt an Android build" hazard is replaced —
  M1's definition of done now includes `flutter run` on the AVD; the first
  gradle build's download cost is accepted.
- The emulator/adb/flutter-run commands need unsandboxed execution and will
  prompt: the user should run the build session interactively (no `--bg`) or
  expect to answer prompts; the AVD itself is best launched by the user.

### D6 — 2026-08-20 — M1 build verified and accepted; chase rule confirmed defective (architect error)

- Branch `m1-crawl, 14 commits, verified by the architect with independent
  instruments (all fresh this session): test suites re-run (66 core + 10
  content + 17 app, all green), analyze/format re-run clean, grep sweeps for
  body comments and unseeded `Random()` empty, mutation row 3 re-executed
  (red under mutation, green after revert, tree clean), `_chaseStep` read
  directly to confirm the freeze mechanism, equatable props lists checked
  field-by-field against all five events.
- **Spec defect confirmed, mine not the worker's:** the greedy chase contract
  has no fallback when one axis delta is zero — a wall-blocked monster on the
  hero's row/column freezes forever. Worker implemented the contract
  faithfully and measured the impact (only 1 of 3 ghouls engages on the real
  floor when the hero walks north; all 3 converge if he holds still). Fix
  (breadth-first flow field, ~20 lines, deterministic) goes to M2 — it changes
  game feel and deserves its own playtest. Locked: M1 ships with the weak
  chase.
- **`equatable ^2.1.0` in core accepted.** The user requested it directly in
  the build session (principal outranks the architect's dependency cap); the
  cross-session ruling request never arrived (delivery failed — see below).
  Core's zero-runtime-dependency property is consciously traded away;
  revert path is `git revert 487e006` if ever wanted.
- Balance kept at spec numbers: worker measured 500 seeds — 78.6% corridor
  win rate, median 3 hp remaining, 0% when surrounded (worker's measurement,
  not independently reproduced).
- Hero stat line, FOV wall-lighting contract, and non-adjacent-tap rule all
  confirmed correct in play on AVD `Pixel_10` (worker's screenshots, includes
  a greyscale accessibility check).
- **Channel defect:** SendMessage from the build session to this architect
  session never arrived ("held for the recipient user's approval"); the user
  relayed both messages by hand. Until understood, assume worker→architect
  messages may be held and check with the user when a build session goes
  quiet.
- Not yet done: merge to `main` (user approval pending) and the user's own
  playtest — the actual "is it fun" answer M1 exists for.

### D7 — 2026-08-20 — M1 squash-merged to main; playtest verdict: fun. Story closed

- User approved squash merge: `m1-crawl` (14 commits) → `main` as `be1da0a`
  "feat: M1 The Crawl — playable glyph dungeon crawl". One `.gitignore`
  conflict resolved by union. All three suites re-run green on `main` after
  the merge (measured this session).
- **Playtest verdict from the user: fun** — "even though it's just a bunch of
  #s, dots, @, and g's." M1's core question is answered; the glyphs-first
  bet paid off. M2 builds on a validated loop.
- Branch `m1-crawl` deleted (was 487e006). Worktree removed except files
  pinned by the still-open `residuum-m1-crawl` session; once the user closes
  it: `rm -rf .worktrees/m1-crawl && git worktree prune`.
- Next unit: spec M2 "The Loop" (seeded generation, loot, inventory, first
  4 skills, town screen, death penalty) plus follow-ups 3–6 triage.

### D8 — 2026-08-20 — M2 split into three sequential units; depth and skills locked

- M2 "The Loop" runs as three units, each specced/built/verified/merged before
  the next is specced: `m2-engine` (speed clock, flow-field chase, seeded
  5-floor generation with stairs, auto-path, 5 monster types, follow-ups 3/5/6), `m2-loot` (items, affixes, rarities, inventory, equipment, 4 skills), `m2-town` (town screen, merchant, bank, death penalty).
- Multi-floor depth (5 floors, difficulty scaling by depth) confirmed IN M2 —
  the bank-or-push-deeper tension is the core loop.
- First 4 skills locked: Arms, Might, Bulwark, Fleetfoot (melee set; magic
  waits for M3 spell books as the game spec schedules).
- Rejected: one big M2 unit (verification and branch-staleness risk), flat
  single-floor M2 (death penalty would have no bite), Herbcraft in the first
  four (drags gathering/crafting forward from M3).
- Trap update (from the user's parallel Claude-config session, journal
  2026-08-20): `emulator, `adb, and the device-facing `flutter` subcommands
  (`run`/`devices`/`emulators`/`install`/`attach`/`logs`/`drive`) are now
  sandbox-EXCLUDED — they run unsandboxed without prompting, so a `--bg` build
  session no longer stalls on the AVD step. `flutter test`/`analyze`/`build`
  and `dart format` stay sandboxed. Other hardware probes still lie under
  sandbox.

### D9 — 2026-08-20 — M2E verified and accepted at `dc58d85`; balance deferred to m2-loot with binding figures

- Branch `m2-engine, 12 commits, verified with independent instruments (all
  fresh this session): suites re-run (156 core + 29 content + 27 app = 212
  green), analyze/format clean, hygiene greps empty, mutation row 1
  re-executed myself (exactly the 4 named tests red, green after revert),
  ActorNoticed contract read and confirmed, dartdoc fix read after landing.
- **Report-vs-artifact mismatch found and resolved:** the worker's report
  claimed a dartdoc correction that had never been applied. Asked per
  doctrine (no breach recorded from mismatch alone); worker owned it, applied
  it for real (`dc58d85`), and amended its report to carry the mistake. The
  corrected argument: anti-oscillation comes from grid bipartiteness (equal
  orthogonal neighbours cannot exist on a 4-way grid); strict comparison's
  real job is the deterministic first-wins tie-break.
- **Worker's substantive findings accepted:** mutation row 5 exposed a
  duplicated interrupt implementation (fixed, test tightened to assert the
  notice is the last log line); my mutation-row-1 rationale was wrong
  (bipartiteness, above); generateFloor takes monsterCount as a parameter
  because reading spawn tables inside core would invert the dependency rule;
  the no-spawn-in-hero-room rule is enforced by construction and validated
  as no-spawn-inside-initial-FOV.
- **Balance: DEFERRED to m2-loot (decision).** Binding inputs for the m2-loot
  spec, measured by the worker on-device: one corridor ghoul costs 16→6 hp;
  depth 2 holds ~40 damage against a 20 hp hero; a dire wolf costs ~10 hp
  (acts twice per hero turn); ~29 monsters across floors 1–5; speed-10
  chasers cannot catch a moving hero, speed-20 wolves always do. m2-loot's
  definition of done must include: a 1→5 descent is survivable with the loot
  and healing it adds; depth-1-2 spawn tables are the fallback lever.
- Execution-phase deviation accepted with reason: subagent-driven-development
  and dedicated per-task reviewers were skipped because the user's standing
  instruction forbids unattended write-capable subagents; the mutation table
  carried the adversarial load (and caught the row-5 defect). Worker argued
  the skip openly, as required.
- **Follow-up 7 closed:** the M1 message-delivery failure was the previous
  architect session's socket going stale, per the worker; this round's
  channel worked both directions. BUILD-REPORT.md mirror stays as belt and
  braces in future prompts.
- Environment note (user's own change, journal 2026-08-20): the Bash sandbox
  is now DISABLED (`sandbox.enabled: false, config kept, 2-week trial). The
  sandbox-shaped traps in this ledger are dormant while it stays off; keep
  them listed — re-enabling is one boolean.
- Not yet done: merge to `main` (user approval pending).

### D11 — 2026-08-21 — M2L forks locked: six slots, affixes now, potions-only healing

- Equipment slots in M2L: mainHand, offHand, head, chest, hands, feet.
  Jewelry (amulet + 2 rings) deferred to M3 where magic affixes exist.
- Affix system built now: small pool, rarity controls affix count. Rejected
  flat rarity multipliers (hollow drops).
- Healing: potions only. Rejected passive regen (softens corridor attrition).
- **User design note to carry forward (not M2L):** a "safe point" partway
  through a long dungeon — a mid-dungeon rest spot. Route it into m2-town's
  rest mechanics or M3's dungeon structure when specced (logged as follow-up
  8).
- Baseline re-measured fresh after the box restart: `main` @ `961dc46,
  212 tests green.

### D12 — 2026-08-21 — M2L verified and accepted at branch head; survivability 70% confirmed live

- Branch `m2-loot, 13 commits, verified with independent instruments (all
  fresh this session): suites re-run (273 core + 69 content + 42 app = 384
  green), analyze/format clean, hygiene greps empty, deps capped. Mutation
  row 1 re-executed myself (one-line sed removing the armor subtraction):
  content's survivability band collapsed red and core reddened EXACTLY the
  five tests the worker named; green after revert, tree clean. Survivability
  test run live: 28/40 = 70.0%, stalled 0; exploit comparison prints
  greedy 28/40 vs fleetfoot-first 12/40 as reported. The zero-dodge
  stream-preservation dartdoc rider verified in place at the skip site.
- **Spec defect (mine): mutation row 4 predicted two red tests; only the
  displacement half is reachable by that mutation** — displacement and
  refusal live in different code paths. Worker proved the refusal half
  independently with its own supplementary row 4b. Better outcome than
  specced.
- **Pre-approved deviations landed as agreed** (see m2-loot-handoff.md):
  Loadout value object, additive stat baseline (exactly ONE pre-existing
  assertion changed, strengthened), zero-dodge skips the roll.
- **Balance mandate met without touching hero or monster stats:** tuning
  trail 22.5% → 70.0% via potion heal 8→10, floor items 4–6, xp curve 4+2L,
  armor values, depth-1-2 spawn softening (sanctioned), and the decisive
  change: potion drop weight 34→14 (healing was NOT the binding constraint —
  a 20x heal probe moved the rate 2.5 points; damage throughput was).
- **Fleetfoot exploit measured strictly worse by 40 points** (70% vs 30%):
  no rule needed in m2-town; revisit only if Fleetfoot's per-level value
  rises or off-gear training appears.
- **Honest shortfalls, accepted:** hand-play reached depth 4 of 5 (descent
  chain proven 3x on device + bot 70% + content test; the last staircase
  left to the user's playtest). One TDD exception argued openly: combat-math
  tests written after the code (step's switch non-exhaustiveness forced one
  compiling commit); mutation rows 1/3 confirm those tests constrain the
  code. Per-task reviewer pair skipped per session constraint (M2E
  precedent); mutation table extended with 4b carried the load.
- Naming note for m2-town spec: EquipRefused also carries pick-up refusals —
  consider ActionRefused rename there, not now.
- Not yet done: merge to `main` (user approval pending) and the user's own
  feel playtest — worker's feel observation: armor dominates once 2–3 pieces
  are on; depth-3 monsters all hit the floor of 1 (see follow-up 9).

### D13 — 2026-08-21 — M2L squash-merged to main as `69d55e4`; story closed

- User approved squash merge; no conflicts. All three suites re-run green on
  `main` after the merge (273/69/42, measured this session). Branch and
  worktree removed.
- The user's feel playtest is deliberately post-merge (their call); its
  verdict — especially on armor dominance (follow-up 9) — feeds the m2-town
  spec.

### D14 — 2026-08-21 — M2L playtest verdict + M2T forks locked

- **M2L playtest: fun.** User reached floor 5 and was stuck — no exit exists
  yet, which is exactly M2T's job. QOL improvements noted and deliberately
  deferred (follow-up 12).
- M2T forks locked by the user:
  - **Exit: choose at every stairs, PLUS ascend.** Stairs landings offer
    Descend / Return-to-town; stairs-up tiles offer Ascend. Consequence
    accepted: floors persist within a run (map, monsters, ground items,
    explored — snapshot per floor, restored exactly on revisit; monsters
    frozen while away). Reshuffle happens per entry and per death (visit++),
    never mid-run.
  - **Death burns unbanked gold too.** Only skills and equipped gear survive
    death; carried items and carried gold are lost. Banked things persist.
  - **Armor dominance fixed via a creature `pierce` stat** (ignores N armor,
    content-only, deeper creatures). Survivability band must be re-tuned to
    stay 50–95%. Rejected: percentage armor rework (invalidates M2L tuning).
- Also sanctioned for M2T: EquipRefused → ActionRefused rename (follow-up 11).
- Mid-dungeon safe point (follow-up 8) NOT in M2T — the ascend/leave-at-stairs
  mechanics already soften long runs; revisit with M3's bigger dungeons.

### D15 — 2026-08-21 — M2T verified and accepted; the loop is closed

- Branch `m2-town, 15 commits, verified with independent instruments (all
  fresh this session): suites re-run (352 core + 95 content + 67 app = 514
  green), analyze/format clean, hygiene greps empty, bestiary diff confirmed
  pierce-only (forbidden levers byte-identical). Survivability run live:
  25/40 = 62.5%, stalled 0, histogram exactly as reported (pierce moved
  deaths to depths 2–3, depth 1 untouched). Mutation row 2 re-run myself
  (death branch skipped): all four core death-matrix tests red plus app
  failures, green after revert. Dartdoc riders confirmed in place (the
  regeneration condition on the stairs bounce; Profile's honest-hp note).
- **Worker finding worth keeping: the survivability band cannot detect the
  game getting EASIER.** Removing pierce lands back inside 50–95%, so my
  mutation row 1 prediction was wrong — a band is a floor and a ceiling, not
  a pin. The four pierce-arithmetic tests are the only guard on pierce.
  Filed as a standing caution: never cite the band as regression coverage.
- Worker extended the mutation table with rows 7–8 targeting the two dartdoc
  hazards; both rows first caught defects in its OWN tests (fixture at
  actThreshold masking re-ready; arrival FOV masking the explored restore) —
  repaired, re-run, then recorded. This is the mutation-table discipline
  working as designed.
- One pre-existing test deleted with argument accepted: the Restart-button
  bloc test (the button no longer exists; the D14 matrix pins its
  replacement). GameStarted event removed with its last caller.
- Pierce values: rat 0, wolf 0, ghoul 1, skeleton 3, wight 4 — one lever,
  one step, 70.0% → 62.5%; drop/spawn tables untouched.
- TDD honesty note: worker caught itself writing test+code together on the
  economy task, deleted the implementation to observe a real red, restored
  it, and recorded the episode.
- AVD playthrough covered the entire definition of done including the
  deliberate death (carried burned, worn+skills+bank kept, reshuffle
  observed). One copy bug found by playing, fixed ("gone down once/twice/N
  times").
- Not yet done: merge to `main` (user approval pending). Merging completes
  M2 — the game's core loop exists end to end.

### D16 — 2026-08-21 — M2T merged as `0824d8d`; M2 COMPLETE; README added for the Forgejo repo

- User approved squash merge; suites re-run green on `main` (514). Branch and
  worktree removed. `main`: 8596adb (README) ← 0824d8d (M2T) ← 69d55e4 (M2L)
  ← 961dc46 (M2E) ← be1da0a (M1).
- README.md written and committed for the upcoming Forgejo repo (user will
  create the repo themselves). Once a remote exists: pushes remain
  user-approved per round, and the ledger stays local (gitignored) per D1.
- NEXT: collect the QOL backlog (follow-up 12), then decide M3 scope.

### D17 — 2026-08-21 — Repo moved to `~/Development/Projects/fiatcode/residuum-rpg`

- User graduated the project out of `_temp`: the repo now lives at
  `/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg` (matching the
  Forgejo repo name and the fiatcode personal-projects home). Everything
  traveled: git history, remote, and this gitignored ledger.
- All FUTURE absolute paths (build prompts, handoffs, session commands) use
  the new root. Historical artifacts are append-only and keep their old
  `_temp/residuum` paths on purpose — they describe where things were.
- Architect sessions from now on should be launched from the new directory;
  the current session continues via explicit paths.

### D18 — 2026-08-21 — Recurring architect-handoff ritual established

- The user will restart the architect session whenever its context grows
  large. `docs/epic/ARCHITECT-HANDOFF.md` is the standing continuation
  artifact: regenerated (not duplicated) at each handoff, it carries the
  operating model, standing cautions, and a one-breath state summary, and
  routes the new session into this ledger for canonical memory.
- This first handoff closes the session that ran the epic from bootstrap
  through M2 completion (D1–D17).

### D19 — 2026-08-21 — QOL unit `m2-qol` scoped and forks locked; follow-up 12 resolved

- The user's QOL list collected post-M2 (resolves follow-up 12): item stats
  visibility, inventory grouping/sorting, equip-compare indicator, battle
  indicator, tap targets too small. Architect additions accepted: town equip
  screen, potion count on the quick-drink button. Rejected from scope: drop
  confirmation (a dropped item lands underfoot and is recoverable).
- **Viewport fork locked: camera-follow zoomed viewport, fixed cell size**
  (~36dp target, worker may tune per device), free pan to inspect the whole
  map, camera returns to the hero on the next hero action. Tap semantics
  unchanged (adjacent tap steps/attacks, far tap auto-paths) — targets grow
  from ~12dp (depth-5 32×20 map fitted whole) to ~36dp. Rejected: pinch zoom
  (YAGNI), d-pad overlay (two input systems, thumb occlusion, leaves 12dp
  glyphs unreadable), swipe-to-step (revisit only if surrounded combat still
  feels clumsy after the rework).
- **Inventory presentation cluster:** per-row stat strings from the existing
  Item getters; carried items grouped Weapons/Armour/Potions, sorted
  slot→rarity→name; equippable carried rows show a signed delta vs the item
  worn in their slot (arrow shape + number, never hue alone); identical items
  (equal base+rarity+affixes) stack into one row with ×N — display-level
  stacking, ids stay unique, row actions apply to one item of the stack.
- **Battle indicator:** derived enemies-in-sight count; an "Engaged (N)"
  word-chip in the HP row; a refused walk emits a log line — fixing the
  silent refusal found at `game_bloc.dart:171` (tap on a far tile while
  watched returns with no feedback at all).
- **Town equip screen** is the only non-app-layer piece: needs a small pure
  equip/unequip transaction on Profile in core.
- Forbidden levers untouched: no bestiary, hero-stat, or drop/spawn-table
  changes anywhere in this unit; the survivability band must not move.
- **Follow-up 6 CLOSED:** the HP label already clamps at zero
  (`game_screen.dart:54, verified this session).

### D20 — 2026-08-21 — M3 runs full-fat as specced, split into four sequential units, saves first

- User decisions: **saves-first** and **full-fat M3** (no trimming — 3 themed
  dungeons, full spell-book system, all of section 12's M3 line).
- Unit split, each specced/built/verified/merged before the next is specced
  (D8 precedent), all branching from the then-current `main`:
  1. `m3-saves` (S): JSON snapshot persistence of Profile with a version
     field from day one (spec section 13), autosave on town entry,
     corrupt-save fallback to previous autosave.
  2. `m3-world` (L): overworld node map, travel encounters, 3 themed
     dungeons, rumors; side-quest templates ride here or defer (decide at
     its spec).
  3. `m3-magic` (L): the remaining 9 skills, spell books, first spells.
  4. `m3-craft` (M): gathering nodes, forge, alchemist, tempering.
- Why saves first: no saves exist at all today (closing the app loses the
  hero — the spec's "saves hardened" wording presumes a base that is not
  there), and the save shape must exist before Profile grows spells,
  recipes, and quest state.
- Why craft last: depends on world gathering nodes (unit 2) and town
  screens.
- Rejected: trimmed M3 (2 dungeons / few spells) — M5 already owns the
  "keep growing" ring, and the user wants the full milestone; speccing
  m3-saves while m2-qol is still in flight — sequential units avoid branch
  staleness (D8).
- M2Q handoff note: kickoff sent to `residuum-m2-qol [1fad89]` this session.

### D21 — 2026-08-21 — M2Q verified and accepted at branch head; two spec defects mine; clamp divergence ruled (a)

- Branch `m2-qol, 12 commits, verified with independent instruments (all
  fresh this session): suites re-run myself in the worktree (389 core + 95
  content + 129 app = 613 green, +99 over the 514 baseline), analyze and
  format clean, hygiene greps empty (arrange/act/assert only; Random hits
  only in the report's own prose), `git diff main -- packages/content`
  empty, core deps still equatable-only. Survivability run live: 25/40,
  stalled 0 — and the informational fleetfoot figure (8/40) is identical on
  `main, a determinism cross-check the worker did not claim. Mutation row 5
  re-run with my own sed (visible filter dropped): exactly three app tests
  red across the shared predicate (engaged count, walk-starts-when-clear,
  walk-stops-on-sight), FOV control green, revert clean. Claimed artifacts
  all grepped real: `enemiesInSight` single home (`_somethingIsWatching`
  deleted), `Drink (N)` with its argued dartdoc, Engaged chip, C2 boundary
  tests, the event-order test from 216e668, the updated second silence test.
- **Spec defects, both mine:** (1) C2's arrange was off by one — overflow
  needs a full pack (20−1+2=21), and `inventoryCap-1` lands exactly AT the
  cap; worker pinned both boundaries. (2) Spec item 4 said "mirror
  `_clampedToMaxHp`" as if the dungeon clamped on equip — it clamps only on
  the unequip path (`step.dart:108`), so the spec silently asked the town to
  diverge.
- **Ruling on the clamp divergence: option (a) ratified** — town clamps on
  both dressing paths, dungeon frozen this unit. Rejected: (b) mirroring the
  dungeon (town screen would print hp above ceiling raw — the crawl screen
  only hides the same state by display-clamping); (c) unifying now (changes
  behavior the survivability re-baseline is frozen against). Unification is
  follow-up 14 and needs an architect ruling plus a fresh 25/40 baseline.
- **Worker deviation accepted: `Drink (N)`** instead of the spec's literal
  `Drink potion (N)` — the mandated string ellipsized to `Drink poti…` on a
  four-control row, destroying the count the item exists to show. Found by
  playthrough, argued in `_Controls` dartdoc.
- **Mutation extension row 11 found a real test gap** (reversing the wear
  displacement order reddened only the rule-level test; the step suite could
  not see order with its one-displacement fixture) — fixed by a step-level
  three-event order test. Rows 12–14 pin snap-back-by-construction, the
  per-axis origin, and stow order. The spec's named canary (existing step
  tests) was wrong about what it could see; the discipline of running the
  table caught it.
- Under-determined contract cases decided by the worker and accepted:
  extent equal to viewport counts as fitting (pan-deaf); panning does not
  cancel an auto-walk.
- Playthrough on Pixel_10 (33 shots) covered the definition of done except
  two argued substitutions (full-pack take-off covered by tests + row 8;
  buy-then-wear done with dungeon loot for want of gold). Greyscale checks
  pass on all four changed screens.
- Per-task reviewer subagents skipped per D9 precedent, argued openly; the
  cost (no fresh eyes on style) noted and accepted — analyze clean, diff
  reads idiomatic.
- **Channel trap confirmed in the reply direction:** the worker's two
  SendMessage replies were held for approval and never delivered because
  this architect session is INTERACTIVE — and a second stale session with
  the same name made it a coin flip. The user relayed by hand;
  BUILD-REPORT.md carried the full block as designed. Trap updated below.
- Not yet done: squash merge to `main` (user approval pending).

### D22 — 2026-08-21 — M2Q merged as `472e62b` via PR #1; story closed; PR flow adopted

- New flow, decided by the user this round: **PR-based merges from now on.**
  Architect pushes the branch and opens the PR (user-approved per round);
  the user squash-merges in Forgejo. First use: PR #1, squash-merged by the
  user as `472e62b` "feat: M2Q Quality of life — camera viewport, pack
  presentation, town gear (#1)".
- Verified on `main` after the merge (all fresh this session): 389 core +
  95 content + 129 app = 613 green. `main`: 472e62b ← 8596adb ← 0824d8d ←
  69d55e4 ← 961dc46 ← be1da0a. Forgejo deleted the remote branch on merge;
  local worktree and branch removed.
- The user's own feel playtest of the new viewport is still theirs to do;
  follow-up 13 (swipe-to-step) stays conditional on it.
- NEXT: recon + spec `m3-saves` (M3S) per D20.

### D23 — 2026-08-21 — M3S forks locked: FULL suspend-save (user override), rolled world seeds; M3S splits into m3-rng + m3-saves

- User decisions: **full suspend-save of a run in progress** (rejected the
  architect's cheaper run-is-lost recommendation — the save-scum door and
  the Android background-kill hazard both die with suspend-save), and **a
  new game rolls a random world seed**, persisted for that hero's life;
  tests and the balance bot keep fixed seeds.
- Consequence: `Rng` wraps `dart:math.Random, whose state cannot be
  exported (recon this session), so suspend-save requires replacing the
  PRNG with a state-exportable one. That re-rolls every seeded artifact:
  floor layouts pinned in tests, seeded rule tests, and the 25/40
  survivability baseline.
- **M3S therefore splits in two, sequential (D8 pattern):**
  1. `m3-rng` (M): swap the PRNG for a state-exportable generator behind
     the same `Rng` API, re-pin seeded tests, re-baseline survivability
     (band 50–95% must hold; free levers only if it falls outside, with a
     before/after trail). Nothing else changes — so any balance movement is
     attributable to the generator alone.
  2. `m3-saves` (L): profile + full-run JSON codecs (content-owned — items
     serialize as base id + rarity + affix ids; the dungeon closure is
     rebuilt from worldSeed + visit, never serialized), storage + autosave
     (town entry, and the run per its spec), corrupt-save fallback to the
     previous snapshot with a report, version field from day one, new-game
     seed rolling.
- Rejected: interrupted-run-counts-as-death (Android background kills would
  burn real runs); run-is-lost profile-only saves (user wants the exploit
  door closed properly, full-fat appetite).
- Effort re-sized: M3S was S, becomes M + L across two units.

### D24 — 2026-08-21 — M3R verified and accepted; new exact baseline 24/40; recon blast-radius prediction was wrong (mine)

- Branch `m3-rng, 2 commits, verified with independent instruments (all
  fresh this session): suites re-run myself in the worktree (395 core + 95
  content + 129 app = 619 green, +6 generator tests over 613), analyze and
  format clean, `git diff main -- packages/content` empty, no `dart:math`
  in rng.dart. Survivability run live: **24/40 (60.0%), fleetfoot 7/40 —
  the new exact baseline, replacing 25/40**; band assertion byte-identical,
  no lever touched. Golden literals reproduced with my OWN Python
  splitmix64 (masked 64-bit): stream and exported state match digit for
  digit, confirming textbook constants. Mutation row 6 re-run with my own
  sed: exactly ONE test red (the golden stream pin), 394 green — proving
  the worker's central argument that the golden test is the sole guard on
  generator identity.
- **Recon claim wrong (mine):** the predicted re-roll blast radius did not
  exist. Exactly one test reddened across 613, and it was a latent defect,
  not a seeded pin. The design insight worth keeping: this suite asserts
  relations (two runs agree, value in range), almost never seed→value
  literals — so it is nearly blind to generator identity, which is exactly
  what the new golden tests now cover (mutation row 4: a stuck generator
  reddens only 11 of 619, 4 of them new).
- **Latent test defect found and repaired** (`step_drop_test.dart`): a
  record containing a raw `List` was collected into a `Set` — records
  compare fields with `==` and a `List` compares by identity, so the
  assertion never compared affixes at all; it passed on main only because
  the old stream happened to drop a potion carrying the shared
  `const []`. Repair: `drops.toSet()` (Item is Equatable) — strictly
  stronger, verified non-vacuous by the worker. **Standing caution: any
  record carrying a List that is compared with `==` or put in a Set has
  this defect** (follow-up 18).
- **Worker design choice accepted:** `Rng(int seed)` mixes the seed once,
  so a seed and a numerically-equal state are different starting points —
  this is what makes mutation row 2 expressible at all (the spec missed
  the dependency); `_mix` is a bijection, pure relabelling. Row 3's
  declared unknown answered: the state advance is span-independent, so the
  state pin survives while the stream pin reds. Extension rows 6–8 added;
  row 6 is the keeper (Euclidean `%` keeps mutated output legal — only the
  golden pin catches it).
- **Input for the m3-saves spec, from the worker:** the exported state is
  a full-width signed 64-bit int and will NOT survive a JSON parser that
  reads numbers as doubles — the save encoding must carry it as a string
  (or split). Deciding this is part of the M3S spec, not optional.
- Smoke run on AVD only; a physical device was attached mid-session and
  the user told the worker directly to leave it alone — all device
  commands were pinned to `emulator-5554`.
- Not yet done: push + PR (user approval pending per round).

### D25 — 2026-08-21 — M3R merged as `0656eb1` via PR #2; story closed

- User squash-merged PR #2 as `0656eb1` "feat: M3R saveable generator —
  splitmix64 behind the Rng API (#2)", author persona correct. All three
  suites re-run green on `main` after the merge (395/95/129 = 619, measured
  this session). Worktree and branches removed. `main`: 0656eb1 ← 472e62b ←
  8596adb ← 0824d8d ← 69d55e4 ← 961dc46 ← be1da0a.
- The epic's exact survivability baseline is now **24/40** (D24).
- NEXT: recon + spec `m3-saves` (M3S) — recon completed this session, see
  `m3-saves-recon.md`.

### D26 — 2026-08-21 — Mid-flight M3S ruling: wide save fields stay strings, enforced by a strict decoder; D24's precision hazard superseded

- The M3S worker proved D24's JSON hazard false on this platform:
  `dart:convert` on VM/AOT round-trips full-width 64-bit ints exactly (the
  parser yields int, not double), so spec mutation row 6 was unfailable as
  written. The hazard is real only under dart2js, which the Rng dartdoc
  already scopes out.
- **Ruling: the string encoding for wide fields (seeds, rng states) is
  KEPT, with a corrected justification and a strict decoder.** The reason
  is not precision on this substrate — it is that a save file outlives the
  build that wrote it, and JSON numbers are only as wide as whoever reads
  them decides (dart2js, jq, any JS tool a save is debugged with). The
  decoder treats a JSON number in a wide field as a structured failure,
  which makes the format self-enforcing and row 6 loudly failable; the
  worker's row 20 (decoder-accepts-int mutation) pins the strictness
  itself.
- Two recon errors confirmed at the cited lines, both mine, both from bad
  instruments: `FloorMap.toAscii()` exists (head-limited read) and
  `baseItemById`/`affixById` exist (case-sensitive grep `byId` cannot
  match `ById` — doctrine rule 2 in the wild). Worker adds OrNull lookup
  variants beside the throwing pair and pins affix-id uniqueness.
- Deferred to story close: recording the design-spec supersessions (spec
  section 11 says three manual save slots and a coarser autosave cadence;
  D23/M3S ship two-slot rotation and save-every-settled-change; named
  slots remain the M5-territory follow-up).
- Full Q&A in `m3-saves-handoff.md`. All shape deviations approved as
  declared; core diff will be empty.

### D27 — 2026-08-21 — M3S verified and accepted; suspend-save proven roll-for-roll; boot wiring named the architecture's blind spot

- Branch `m3-saves, 13 commits, verified with independent instruments (all
  fresh this session): suites re-run myself in the worktree (395 core + 180
  content + 166 app = **741** green, +122 over 619), survivability
  **24/40 identical to base including the death histogram** and fleetfoot
  7/40, analyze/format clean, `git diff main -- packages/core` EMPTY,
  forbidden-lever files untouched (armory/affix_pool changes are the
  approved OrNull lookups only). Hygiene: no dart:io/DateTime in content;
  the one sanctioned clock roll at `app/lib/save/boot.dart:51`; no body
  comments. Mutation row 1 re-run with my own sed (loadRun re-seeded from
  worldSeed): 8 content tests red including the suspend theorem and the
  golden save, PLUS the worker's repaired app autosaver test — the repair
  it made after its own row 1 exposed that test as vacuous (nothing in
  reach at world seed 5 → streams never advanced → re-seed
  indistinguishable). Revert clean, all green after.
- **The unit's claim held under my instruments and the worker's A/B**: the
  same attack replayed from the same document lands identical damage and
  an identical resulting stream state; cadence measurement made the
  fallback unnecessary (0.72ms encode at depth 5, save every settled
  change shipped as specced).
- **Three device-found boot defects, fixed in 71cff0a, one severe:** the
  Autosaver was never attached (a `late final` nothing read — every town
  transaction unwritten, NO run block on disk, while all 166 app tests
  passed); the resume log line fired on fresh entries; the corrupt-save
  report was invisible on the resume-into-crawl path (a spec gap — "the
  town screen shows it" does not cover a boot that lands in the dungeon).
  **Standing insight: boot wiring is this architecture's blind spot** —
  bloc-level tests cannot see a listener nobody attached; the AVD
  acceptance pass is the only instrument that can, and stays mandatory for
  any unit that touches `main.dart`.
- Row 6 settled empirically per D26: as originally specced it stayed green
  under real drift; with the strict decoder it reds 36 content + 18 app
  tests, and row 20 shows the strictness rests on exactly three tests.
- Worker self-corrections accepted: the affix-uniqueness pin already
  existed (its earlier message overstated); weakest extension row (14,
  position-set ordering) flagged rather than hidden.
- `equatable` added to content's pubspec: deliberate, documented in the
  report (section 7), and it FIXED a latent undeclared transitive import.
  Bar stated for future units: already-imported same-version pubspec
  changes belong in the summary message; new-to-repo packages are a
  pre-declaration.
- Design-spec supersessions recorded (spec section 11): "three manual
  slots" → two-slot rotation + M5 follow-up; "autosave on floor change,
  town arrival, app pause" → save every settled change (measured at
  0.72ms). The spec text stays as written per D1 — corrections live here.
- Not yet done: push + PR (user approval pending per round).

### D28 — 2026-08-21 — Hero slots pulled forward: v1 goes multi-hero inside M3S; roster + buy-back become unit `m3-heroes`; back-guard accepted

- User forks locked: **the save format is shaped for multiple heroes NOW,
  inside m3-saves** (rejected: ship single-hero v1 and migrate in the next
  unit — no migration machinery for a days-old format); **same-visit
  buy-back** guards accidental sells (the merchant re-sells what you sold
  this visit at the price they paid; rejected: per-sale confirmation
  dialogs — friction on the core loop's payoff); **uncapped roster** (a cap
  just moves the decision one screen along; rejected: the design spec's
  three slots — supersession to record at close alongside D27's).
- Document v1 becomes {version, active, heroes: {id: {label, profile,
  run|null}}}; per-hero suspended runs; label lives in the document so core
  stays untouched. Task sent to the in-flight worker (contract in
  m3-saves-handoff.md); PR waits on the delta.
- **New unit queued after m3-saves: `m3-heroes` (M3H, S/M)** — roster
  screen (create with label, switch, delete with confirmation), abandon-
  hero button dies there, merchant same-visit buy-back. Specced after
  m3-saves merges, before m3-world.
- **Back-guard delta verified and accepted** (my instruments: suites
  re-run 395/180/170 = 745 green pre-format-change, PopScope + evented log
  line + tests confirmed, tree clean): system back is not a door out of the
  dungeon; silent over the death overlay (ratified); didPop guard correct.
  **Worker-proven blind spot: mutation rows 22/24 (canPop flipped; didPop
  guard dropped) leave all 745 tests green** — widget wiring is invisible
  to the app's bloc-only suite, same class as the four boot defects. Open
  question to the user: whether route-guard wiring earns the app package's
  single, narrow widget-test exception to the no-widget-tests convention.
- House method adopted from the worker's process notes: AVD verification
  must press the PLATFORM's buttons, not only the app's; mutation rows
  require the code under test to be COMMITTED first (a checkout-revert ate
  an uncommitted fix once). Future build prompts carry both.

### D29 — 2026-08-21 — Roster delta verified; M3S accepted in full at 768 tests; format-freeze caution filed

- Roster delta (2 commits, hashes pasted not typed) verified with my
  instruments: 395 core + 197 content + 176 app = **768 green**,
  survivability 24/40 identical, analyze/format clean, core diff empty,
  hygiene clean. Mutation row 27 re-run with my own sed (empty roster
  accepted): exactly the named test red, revert clean.
- **Sign-offs ratified:** `SaveStore.wipe` deleted (no caller once abandon
  replaces the slot; the roster unit rewrites delete when it needs it);
  abandoning now replaces the active entry and rotates normally (the old
  full-wipe evidence marked superseded in the worker's report, re-verified
  on device). Key-ordered roster encoding (one roster → one document) and
  `unusedHeroIdFrom` collision-walking (two heroes in one millisecond
  would otherwise silently collide — unreachable by play, caught by
  design) both accepted.
- Honest-fixture note kept: the on-device two-hero check proves
  PRESERVATION (the idle hero's entry survives a whole session) not
  SEPARATION (unit-tested with distinct seeds); the worker refused to
  hand-edit an impossible document to fake the second proof. Correct call.
- **Standing caution (follow-up 20): version 1 was reshaped in place,
  which is sound ONLY while no build has shipped.** The first shipped
  build freezes the format: from then on any shape change is a version
  bump plus a migration, and nothing in the code enforces this — the
  ledger is the enforcement.
- Second process slip owned (same family as the hash): a `re.sub`
  replacement interpreted `\n` escapes and corrupted a golden literal —
  caught by the byte pin doing its job. Pattern named by the worker
  itself: tooling doing something reasonable, unchecked.
- M3S is COMPLETE on the branch: 17 commits, suspend-save proven
  roll-for-roll, multi-hero v1, back guard, three boot defects fixed.
  Not yet done: push + PR (user approval pending).

### D30 — 2026-08-21 — M3S merged as `f758c3f` via PR #3; story closed; the game persists

- User squash-merged PR #3 as `f758c3f, author persona correct. Worktree,
  local and remote branches removed. `main`: f758c3f ← 0656eb1 ← 472e62b ←
  8596adb ← 0824d8d ← 69d55e4 ← 961dc46 ← be1da0a. Suites re-run on `main`
  post-merge (this session): see status table — 768 expected.
- The game now survives the app closing: multi-hero suspend-save document
  v1, roll-for-roll resume, corrupt fallback, rolled world seeds.
  Follow-up 20 (format freeze on first shipped build) is now live doctrine.
- NEXT: spec `m3-heroes` (M3H) — roster screen (create with name, switch,
  delete with confirmation), Abandon Hero button retired, merchant
  same-visit buy-back at the price paid (recon: buyPriceOf = sellPriceOf
  × 2 is the markup being guarded against). One user ruling pending:
  the narrow widget-test exception for route guards and boot wiring.

### D31 — 2026-08-21 — Widget tests granted IN FULL; M3H specced and ready to hand off

- **User ruling: the app package's no-widget-tests convention is amended
  in full**, not narrowly. BLoC tests stay the default; widget tests are
  permitted wherever a bloc test cannot observe the behavior (route
  guards, boot wiring, navigation, dialogs); golden-image tests stay
  forbidden; look and feel stay manually verified on device. Basis: two
  units proved the cost — M3S mutation rows 22/24 and the detached
  autosaver left every test green. The CLAUDE.md Testing amendment rides
  the m3-heroes unit as a reviewed commit. (The user's global BLoC-only
  preference for other projects is unchanged; this is project scope.)
- **M3H `m3-heroes` is ready to hand off**: roster door in town (create
  named + rolled seed, switch — suspended heroes resume into their crawl,
  delete with confirmation, never zero heroes), Abandon Hero plumbing
  retired, merchant same-visit buy-back at the price paid, and the fix
  for the recon-confirmed resurrection defect (stock rebuilt from tables
  on every boot; re-buying a resurrected item duplicates an item id) via
  per-hero visit state in the save document — one more in-place v1
  reshape, sanctioned while unshipped. Spec `m3-heroes-spec-M3H.md,
  prompt `m3-heroes-build-prompt.md, recon `m3-heroes-recon.md,
  worktree `.worktrees/m3-heroes` @ `f758c3f, handoff open. Session
  `residuum-m3-heroes`.
- Acceptance in miniature: mutation rows 7–9 re-run the three formerly
  invisible wiring mutations and MUST now redden.

### D32 — 2026-08-21 — M3H verified and accepted; D31 proven by my own instrument; recon corrected again (silent item loss, not misidentification)

- Branch `m3-heroes, 13 commits, verified with independent instruments
  (all fresh this session): suites re-run myself (395 core + 212 content +
  222 app = **829** green, +61 over 768, after eight argued deletions),
  survivability 24/40 identical with histogram, analyze/format clean, core
  diff EMPTY, content diff save-feature only, no pubspec change, CLAUDE.md
  diff is exactly the D31 Testing amendment. **Mutation row 7 re-run with
  my own sed (canPop flipped true): the two back-guard widget tests red,
  revert clean — the same mutation left all 768 tests green two units ago.
  D31 accepted as proven.** Rows 8 and 9 red per the worker's table.
- **Recon correction (mine, again), measured by the worker at base:**
  "every by-id operation acts on the first match" is FALSE — core's
  `_find` prices the FIRST match while `_without` removes EVERY match, so
  duplicated ids mean a single sale pays for one item and silently
  destroys both (`depositItem` has the same pair). Characterized green at
  base (C3) before any fix. The resurrection fix removes the only known
  duplication source; the core asymmetry itself is untouched (core is
  frozen for this unit) — follow-up 23.
- **Worker findings ruled:** row 5 split into 5a/5b accepted (never-zero
  has two independent guards; one row per guard, no test weakened). Row 14
  — dropping `await _saver.close()` from the roster flow reddens NOTHING —
  accepted as an honest hole; follow-up 21 (a stallable fake save-files to
  pin the close-before-rebuild await). Switch-into-a-suspended-crawl is
  UNREACHABLE BY PLAY (a crawl ends at stairs or death; back is declined;
  the roster sits under the crawl route) — demonstrated only by hand-
  editing `active` in a real save, said plainly; follow-up 22 (a way out
  that suspends rather than ends — route into the m3-world brainstorm,
  kin to old follow-up 8). The spec's "await the store like _abandon"
  hazard was right-what wrong-how: awaiting bloc/autosaver close
  deadlocks a widget-test clock; fix 484a96e awaits the write queue only
  (the whole promise), cancellations un-awaited. Extension row 11 pins
  boot-vs-live document (the boot document hands back spent gold and
  taken wounds on switch — the live document comes from the autosaver).
- Channel note: the worker reports its messages to ref [0958c2] held and
  [114a3e] delivering, i.e. the ref labels crossed from its side; traffic
  flowed regardless. The stale same-named architect session remains the
  root cause — the user is asked again to close it.
- Not yet done: push + PR (user approval pending per round).

### D33 — 2026-08-21 — M3H merged as `f7bd6b1` via PR #4; story closed; the day ends at 829

- User squash-merged PR #4 as `f7bd6b1, author persona correct. All three
  suites re-run green on `main` post-merge (395/212/222 = 829, measured
  this session). Worktree and branches removed. `main`: f7bd6b1 ← f758c3f
  ← 0656eb1 ← 472e62b ← 8596adb ← 0824d8d ← 69d55e4 ← 961dc46 ← be1da0a.
  The D31 CLAUDE.md testing amendment is now on `main`.
- Session summary: four units decided, specced, built, verified, merged in
  one architect session (M2Q, M3R, M3S, M3H — PRs #1–#4), 514 → 829 tests,
  D19–D33. NEXT: the m3-world brainstorm (bring follow-ups 8 and 22), then
  m3-magic → m3-craft (D20).

### D34 — 2026-08-22 — m3-world forks locked: leave-at-stairs suspend, flee-via-edge encounters, 2 towns + 3 dungeons, side-quests deferred to a fifth M3 unit

- User locked four forks (all on the architect's recommendation):
  - **Crawl exit (resolves follow-ups 8 + 22): Leave at every stairs
    landing.** Leaving suspends the run — the hero returns to the
    overworld; resume is roll-for-roll via the built suspend machinery, NO
    reshuffle on the resume path (reshuffle stays per fresh entry and per
    death, D14), and NO healing (the attrition economy the 24/40 pin is
    frozen against does not move). Follow-up 8's "rest spot" ships as an
    exit, not a heal; healing stays with potions and the town inn.
    Rejected: safe-point rest rooms (more content for the same value,
    balance risk); deferring again.
  - **Combat travel encounters: flee via map edge.** A travel day that
    rolls combat drops into a small single-floor generated open map on
    the existing engine; reaching any map edge flees (no loot, journey
    continues); death on the road carries the normal death penalty and
    the hero wakes in the last visited town. Non-combat events (caravan,
    shrine, rumor traveler) ride along per spec. Rejected: kill-all-only
    (a bad road roll is a death sentence); non-combat-only (trims the
    D20 full-fat line).
  - **World cast: 2 towns + 3 themed dungeons.** The current dungeon's
    bestiary is already crypt-shaped — it becomes the named crypt node
    near the starting town; sea-cave and ruined keep are the two new
    themes (giant camp waits for M5's theme ring). The second town gives
    travel, discovery, and rumors a destination. Towns stay menu screens.
    Rejected: 1 town (star graph, map is a menu with extra steps);
    bigger map (unit grows past L for no new mechanics).
  - **Side-quest templates do NOT ride in m3-world.** Rumors ship here as
    the discovery mechanic only (they reveal nodes and routes). Quest
    templates, quest state, payouts, and reputation become a small fifth
    M3 unit (`m3-quests`) after m3-craft — M3 still ships everything,
    in five units instead of D20's four. D20's split is amended
    accordingly, not superseded elsewhere.
- Save-format note: the document grows overworld state (position,
  discovered nodes, travel day) — one more sanctioned in-place v1
  reshape while nothing has shipped (follow-up 20).
- Follow-ups 8 and 22 are RESOLVED into this decision.

### D35 — 2026-08-22 — Recon splits the D34 scope into three units; suspend-door design ruled; m3-leave specced first

- **Recon finding that reshapes the plan** (`m3-leave-recon.md`): the D34
  scope is three sequential units, per the D8/D23 precedent — verification
  risk, not appetite, drives the split:
  1. `m3-leave` (M3L, S/M): the suspend door (leave at stairs, resume or
     delve-anew from town, boot disambiguation, the town-bloc landmine fix).
     Interim landing is the TOWN — the overworld does not exist yet; D34's
     "returns to the overworld" is honored when M3W lands and moves the pop
     target.
  2. `m3-world` (M3W, L): overworld node map (2 towns + crypt node), travel
     days, road encounters (open-map generator, flee at edge,
     traveler/quiet events), tavern rumors as discovery, world save block,
     navigation rework, death wakes at the last town.
  3. `m3-dungeons` (M3D, M): sea-cave + ruined keep content (bestiaries,
     tables, palettes), per-node floor salts, light bottom-floor bosses +
     guaranteed rares on the NEW dungeons only, per-dungeon survivability
     bands, run-block dungeon identity.
- **Design rulings for M3L (architect authority, from recon findings):**
  - If Leave always suspends, an alive run never ends, resume never
    reshuffles, and the farming loop dies. Therefore the town's Enter
    Dungeon door forks when a camp exists: **Resume** (roll-for-roll) or
    **Delve anew** (abandon the camp behind a confirmation; free of data
    loss because suspend already synced the hero home).
  - Suspend is a homecoming for the hero's own state: `suspendRun` carries
    home exactly what `endRun(died: false)` carries (hp, equipment, skills,
    inventory, gold, visit) while the caller keeps the `GameState`;
    `resumeRun` re-injects the profile's hero-state into the suspended
    state (position/energy/monsters/floors/streams stay the block's). The
    round-trip with no town activity must be identity — the suspend theorem
    extends to the leave path.
  - The document gains a REQUIRED per-hero `inside` field (true only while
    the hero stands in their crawl): boot resumes into the crawl only when
    `run != null && inside`. A derived discriminator exists (mid-crawl
    `profile.visit == run.visit - 1`) and is rejected — a contract must not
    hang off an arithmetic coincidence. One more sanctioned v1 reshape.
  - Suspend clears the merchant visit block (the profile absorbs the run's
    visit, so the shelf rolls; stale buy-back ids would point at dead
    stock).
  - The `TownBloc._settled` landmine (town emissions erase the suspended
    run via the autosaver) is fixed and PINNED BY MUTATION — reverting the
    carry must redden a test that watches the disk.
  - Inn-heal interim accepted: suspend → inn → resume is a paid, riskless
    mid-dungeon heal until M3W adds travel cost. The user chose the
    exit-not-heal fork with the inn in plain sight; the band is blind to
    this either way (the bot never suspends) — never cite it as coverage.
- **Balance:** M3L touches no content numbers, no draw order, no `step()`
  combat path — survivability must stay EXACTLY 24/40 with the same
  histogram, fleetfoot 7/40 (determinism cross-check).
- New unit ordering inside M3: m3-leave → m3-world → m3-dungeons →
  m3-magic → m3-craft → m3-quests.
- **Session note:** the user authorized the architect to create the build
  worktree AND launch the build session directly this round ("prepare the
  worktree and the build session right now... I'll leave it to you") —
  per-session authorization granted by the principal in advance; external
  writes (push, PR, merge) still wait for the user per D22.
- Worktree `.worktrees/m3-leave` created @ `f7bd6b1, branch `m3-leave`.

### D36 — 2026-08-22 — Mid-flight M3L ruling: the merchant clear on suspend is CONDITIONAL on the visit having moved; D35's unconditional clear was wrong

- The M3L worker device-found (shot 31, disk state pasted) that D35's
  "suspend clears the merchant visit block" resurrects sold-out stock on a
  resume→leave cycle: entering bumps the visit, resuming does not — so a
  second walk-out lands on the SAME shelf (`merchantStock(worldSeed,
  visit)` re-rolls identically) with a freshly wiped `bought` list. That is
  the exact resurrection defect the block was built to kill (M3H), in its
  destructive variant: re-buying puts two rows under one id, and core's
  `_find`/`_without` asymmetry (follow-up 23) then destroys both on one
  sale.
- **Ruling: fix accepted as built** (commit 3a0c890): clear only when
  `home.visit != state.profile.visit`; when kept, roll the shelf through
  `merchant.stillOnTheShelf(...)`. Two bloc tests red-first pin the kept
  half; the existing forgets-on-first-suspend test pins the cleared half.
- **The invariant, stated once for every future door** (this class has now
  bitten twice): the merchant visit block is valid exactly as long as the
  visit is. Any future door that moves a hero between town and dungeon —
  M3W's travel doors included — must answer whether it moved the visit,
  and clear or keep accordingly.
- No test caught this; the AVD pass did — one more entry for the D27
  boot-wiring class: cross-screen state validity is partially blind to
  suite-level tests.

### D37 — 2026-08-22 — M3L verified and accepted at `92ec156`; the suspend door is real; the D36 defect is the ledger's second AVD-only catch

- Branch `m3-leave, 14 commits, verified with independent instruments (all
  fresh this session): suites re-run myself in the worktree (408 core + 225
  content + 264 app = **897** green, +68 over 829, nothing deleted or
  weakened); survivability run myself: **24/40 (60.0%), stalled 0, histogram
  1:1 2:9 3:6 5:24 identical, fleetfoot 7/40**; analyze and format clean (my
  runs); forbidden-lever files byte-untouched (`git diff main --name-only`
  over bestiary/spawn/drop/armory/affix/economy/new_game/generator/step:
  empty); no pubspec change; core diff is ONE file (`run_boundary.dart,
  +93); goldens carry `inside` (4 pins); 53 AVD screenshots incl. 5
  greyscale on disk as claimed. **Mutation row 3 (the landmine) re-run with
  my own sed: NINE tests red across both layers** — autosaver disk test,
  four bloc carry tests, two widget resume tests, and the D36 pair — revert
  clean, green after. Stronger than the spec predicted.
- **Worker corrections beyond D36, all verified and accepted:** the spec's
  row 2 "core carry test" red was unreachable in principle (a run's gold is
  always exactly what walked in — `GameState.copyWith` has no gold slot);
  the worker strengthened its own gold-blind carry test and reported it
  rather than quietly fixing it (`f45dbd5`). The identity theorem needed
  the crawl built twice (generators carried by reference) — recorded in the
  test file. The visit invariant proved load-bearing when the worker's own
  fixtures violated it (camps now built through `suspendRun`). The fork
  overflowed a 600-pixel column — caught because overflow throws; the town
  column now scrolls when it does not fit.
- Extension rows that changed things: row 10 (purse missing from the widget
  flow-in proof → closed 34b40ff); row 15 (a fresh delve claiming "The
  crawl resumes." was invisible to all widget tests → closed a02e058);
  row 16 is a truthful weak row (`endRun(died:false)` in place of
  `suspendRun` reddens nothing — the carries are identical six lines, only
  the handler differs). Riders both answered with measurements: the
  exclusivity pin exists (name wraps mid-phrase — grep taught the
  hard-wrap lesson again); two leave/resume cycles = six documents for six
  changes, and the double-write protection is the identity skip, NOT bloc
  closing (rows 18/19 prove which guard does the work).
- **The line the worker asked for, earned:** the D36 defect survived 895
  green tests and a complete 19-row mutation table; only the device pass
  found it, because it needed a button order nobody wrote down. The AVD
  pass stays mandatory for any unit whose state crosses screens.
- One dartdoc nit found by my diff read (an invented "trainer" mechanic on
  public core API) — fixed as `92ec156, verified by grep (zero hits
  repo-wide), suites unchanged at 897.
- Honesty notes accepted: two save-file edits used to reach the death
  scene in bounded taps (both states play produces, said plainly);
  two-camped-heroes round-trips in tests but was not device-walked.
- Follow-up 22's play-value is now REAL: a camped hero is reachable by
  ordinary play at the stairs.
- Not yet done: push + PR (user approval pending per round, D22).

### D38 — 2026-08-22 — M3L merged as `844376f` via PR #5; story closed; the suspend door ships

- User squash-merged PR #5 as `844376f` "feat: M3L Leave — suspend the
  crawl at the stairs, resume or delve anew (#5)", author persona correct.
  All three suites re-run green on `main` post-merge (408/225/264 = 897)
  and survivability EXACTLY 24/40 with the identical histogram — both
  measured this session. Worktree and local branch removed; Forgejo
  deleted the remote branch on merge. `main`: 844376f ← f7bd6b1 ← f758c3f
  ← 0656eb1 ← 472e62b ← 8596adb ← … ← be1da0a.
- The `residuum-m3-leave [7aba1c]` session may be closed by the user.
- NEXT: spec `m3-world` (M3W) per D34/D35 — recon already in
  `m3-leave-recon.md` (findings 5–9).

### D39 — 2026-08-22 — M3W specced and ready to hand off; world rulings recorded

- **M3W `m3-world` is ready to hand off** (D34/D35 scope): core `world/`
  feature (node map, whereabouts, travel), open encounter-map generator
  (second function, not a `generateFloor` bend), flee-at-edge rule (the
  only `step.dart` change), deterministic per-day encounter seed
  (`worldSeed ^ travelSalt, day — no new persistent stream), discovery +
  tavern rumors, required per-hero `world` save block, navigation rework
  (world screen at the stack bottom; the M3L fork moves to the crypt
  node). Spec `m3-world-spec-M3W.md, prompt `m3-world-build-prompt.md,
  recon rides in `m3-leave-recon.md` findings 5–9. Worktree
  `.worktrees/m3-world` @ `844376f`. Session `residuum-m3-world`.
- **New rulings (architect authority; user may veto before launch):**
  per-town merchant shelves (D36 validity extends to visit AND town);
  one bank vault across towns; encounters never serialized (app kill
  mid-encounter re-derives the day); discovery starts with home town +
  crypt, second town hidden; travel-while-camped is legal and is what
  prices the M3L inn-heal interim; boot lands on the world screen except
  mid-crawl kills; `endRun(died: false)` becomes reachable again through
  encounter endings (the D37 worker note honored).
- Baseline for the unit: 897 (408/225/264), 24/40 exact with histogram,
  fleetfoot 7/40 — architect-measured post-merge on `844376f`.
- Known cost accepted: the starting town's shelf re-pins when the town
  salt lands (C3 two-step, argued in its commit); pre-freeze documents
  without a world block demote to fallback then fresh hero (unshipped).
- Blocked on: the user's launch gesture (the D35 direct-launch grant was
  for that round only).

### D40 — 2026-08-22 — Mid-flight M3W rulings: a fight costs the day and none of the distance; travel is chosen leg by leg

- Worker-raised, ruled while the unit is paused (user quota; branch parked
  green at `9abf403` — core 476 / content 234 / app 264, world/ diff only):
  - **A danger day advances time, never the journey.** Quiet and traveler
    days bring the destination one day nearer; a fight costs the day and
    none of the distance — fleeing an encounter buys safety, never
    progress. This is what makes the danger roll a real tax on the road.
    Day counter and leg remainder are two numbers by design; the dartdoc
    carries the argument.
  - **`beginTravel` refuses discovered-but-not-adjacent destinations** ("no
    road runs there from here") — the player picks the legs, because the
    legs are where the days and the fights are. No pathfinding through
    intermediate nodes; a future multi-leg itinerary would be UI sugar
    over the same rule.
- Worker C1 finding worth keeping (the M3R class again): the generator
  suite was relation-only — same seed twice — and would have stayed green
  under a change that moved every layout in the game. Byte literals now
  pin it.
- Riders 1–2 from the pre-declaration stand and are recorded in
  BUILD-REPORT.md section 5, to be honoured when their code lands.

### D41 — 2026-08-22 — M3W verified and accepted at branch head; the world is real; the flee door was unreachable by touch until the device pass

- Branch `m3-world, 15 commits, head `7db533b, verified with independent
  instruments (all fresh this session): suites re-run myself in the
  worktree (515 core + 300 content + 338 app = **1153** green, +256 over
  897); survivability run myself: **24/40 (60.0%), stalled 0, histogram
  1:1 2:9 3:6 5:24 identical, fleetfoot 7/40**; analyze and format clean
  (my runs); forbidden-lever files byte-untouched incl. `new_game.dart`
  and `generator.dart`; no pubspec change; `step.dart` diff read: +18/-0,
  one turn-less `_flees` guard emitting `Fled(), dartdoc argument in
  place; core/lib diff exactly the sanctioned list (world/ ×5,
  encounter_map, event, game_state, step, exports); the Flee control
  routes through `step` via a real `MoveAction` (read at
  `game_bloc.dart:355-357`). **Mutation row E1 (my rider) re-run with my
  own sed (road wrapper bumps the visit): red on BOTH layers** — content
  "walking into a road fight does not bump the visit" and app "coming
  home off the road never moves the visit, so a camp stays resumable" —
  revert clean, green after. Goldens carry the world block (4 pins);
  26 shots + 6 greyscale on disk as claimed; shot 11 shows D40 in play
  (the fight cost the day and none of the distance, in the log); node
  kinds marked [T]/(D) by word, greyscale-safe. M3L pins survived the
  relocation (exclusivity test, landmine disk test, suspend_door 13→15).
- **Row 5's finding, restated as ruled:** the flee RULE is inert in a
  crawl and the core/content greens prove it (border solid by
  construction, 0 leaks in 2000 swept floors); the flee FIELD cannot be
  flipped unnoticed — 8 app tests red because the field decides the
  "Depth 1/5" vs "The road" readout and the back-refusal sentence.
  Narrower and stronger than the spec's prediction.
- **Three of the worker's own mutation rows came back green and were real
  test holes, fixed and re-run red:** row 10 (every test journey started
  at a town that was also home, so wake-at-home was blind — only a
  crypt-origin journey can tell `at` from `home`); E8 (decision 6b —
  camp survives road death — was decided out loud and never tested);
  E9 (nothing asserted a road kill drops anything).
- **The AVD pass found three defects all 1100+ tests missed, one
  serious:** fleeing was UNREACHABLE BY TOUCH — a flee is a step off the
  edge, movement is tapping a tile, and `GridGeometry.positionAt` returns
  null off-grid, so no player could ever flee; the one app test
  dispatched `TileTapped(Position(-1, 5)), a value the real tap handler
  cannot produce — a false green about something nobody could do. Fixed
  with a `Flee` control shown on the outermost ring, dispatching the same
  outward `MoveAction` through `step` (5cadaa6). Also: a journey could
  not continue after an app-kill (world block restored, nothing walked
  the hero — `Walk on` control added, d112d4f); a label ellipsised to
  "Back to the ro…" (ebe3802). Third AVD-only catch this epic; the
  mandatory device pass is now the epic's best-performing instrument.
- Relocation audit accepted: zero tests removed anywhere; suspend_door
  13→15, boot_wiring 4→4 (two renamed to the world landing),
  roster_session 9→9, town_bloc 57→68.
- Honesty section accepted: the road's pricing is argued, not measured
  (the bot never travels — the pin is as blind to the road as to the
  inn; follow-up 24's playtest is the instrument); ambush winnability
  rests on two data points; nobody has played this for fun yet.
- Housekeeping flag surfaced by the worker (for the user, this PR round):
  the user's global CLAUDE.md now routes handover reports to
  `docs/reports/` (git-excluded); BUILD-REPORT.md is tracked in this repo
  by M3L-era precedent. The worker kept repo convention and flagged the
  tension rather than silently switching — correct behaviour; ruling
  belongs to the user.
- Not yet done: push + PR (user approval pending per round, D22).

### D42 — 2026-08-22 — M3W merged as `958ef98` via PR #6; story closed; report-layout chore lands as PR #7; the architect session hands over

- User squash-merged PR #6 as `958ef98` "feat: M3W The World — overworld,
  travel days, road encounters, rumors (#6)". All three suites re-run
  green on `main` post-merge (515/300/338 = **1153**) and survivability
  EXACTLY 24/40 with the identical histogram, fleetfoot 7/40 — measured
  this session. Worktree and branches removed. `main`: 958ef98 ← 844376f
  ← f7bd6b1 ← f758c3f ← 0656eb1 ← 472e62b ← 8596adb ← … ← be1da0a.
- The game now has: a world map, travel in days, road fights with a real
  flee door, rumors, two towns with their own shelves, and a suspend door
  priced (weakly — follow-up 24) by the road.
- **Chore PR #7 OPEN** (user-approved: "chore it") —
  https://git.fiatcode.dev/fiatcode/residuum-rpg/pulls/7, commit
  `70238be`: BUILD-REPORT.md untracked and moved to gitignored
  `docs/reports/`; committed `docs/superpowers/*` history stays put.
  **Operating-model change from the next unit on:** build prompts point
  the worker mirror at `docs/reports/BUILD-REPORT.md` (worktree-relative),
  plans go to `docs/plans/, specs the architect writes stay in
  `docs/epic/` (gitignored) as ever. The next architect verifies #7's
  merge trivially at re-orientation (one file, no code).
- The `residuum-m3-world [9758de]` session may be closed by the user.
- Session summary: this architect session ran D34→D42 — the world
  brainstorm, the three-way split, two full waves (M3L, M3W: PRs #5–#6,
  897 → 1153 tests), two device-found defect classes, the camp-expiry
  design discussion (follow-up 24), and the report-layout chore (#7).
- NEXT: user merges #7 → spec `m3-dungeons` (M3D) per D35. The user's
  playtest of the full leave/travel/resume loop feeds follow-up 24.

### D43 — 2026-08-22 — M3D forks locked; the crypt pin turns out to be prose; randomized delve depth becomes its own follow-on unit

- Recon (`m3-dungeons-recon.md, three read-only agents fanned out, every
  load-bearing claim architect-re-verified at source on `bdb190b`) moved
  the ground twice:
  - **The exact 24/40 crypt pin exists nowhere in code.** The
    survivability test asserts only the 50–95% band and `stalled == 0`;
    the exact figure and histogram are print-only
    (`survivability_test.dart:201-207, architect-read). The pin has been
    procedural — a human reading stdout against plan prose — since M2L.
  - **Run-block dungeon identity is load-bearing, not optional.** A camped
    hero (`inside == false`) stands in a town, so the hero-level
    `world.at` cannot name the camp's dungeon; nothing else on disk can.
    Without the field, a camp in a second dungeon is unrecoverable.
- **User locked four forks (first three on the architect's
  recommendation):**
  1. **Content-only boss.** One named creature per theme, placed by the
     new dungeon's own bottom-floor builder (swaps one rolled spawn); one
     guaranteed rare-or-better item as floor litter the boss guards. No
     core changes, no crypt changes, no victory event — boss machinery
     waits for M4. Rejected: core boss flag + event now (pulls M4
     forward); no boss (drops the design-spec promise).
  2. **Staggered, rumor-hidden map.** Sea-cave 1 day from Northgate
     (the second town gains a purpose); ruined keep 2 days out on the far
     side, highest danger. Both start undiscovered; tavern rumors reveal
     them. Difficulty ordering crypt < sea-cave < keep, carried entirely
     by the new bestiaries and tables. Rejected: both near Stonebridge
     (Northgate stays shelf-only); visible-from-start (guts the rumor
     mechanic).
  3. **Promote the pin + progression-kit bot.** The same commit that adds
     per-dungeon bands promotes the crypt's exact 24/40 and histogram
     into real assertions. New dungeons: the bot runs with a defined
     mid-progression kit (gear a crypt-graduate plausibly owns), the
     worker measures first figures, the architect ratifies exact pins
     plus 50–95% bands. Rejected: fresh-kit bot everywhere (the band
     stops meaning "survivable"); deferring new-dungeon bands.
  4. **Depth: five floors everywhere in M3D; randomized depth per delve
     becomes its own small unit right after** (user's idea, architect
     recommended the split). Design sketch for that unit: sea-cave rolls
     4–6 and keep rolls 5–7 per visit, deterministic from
     `worldSeed ^ nodeSalt` + visit and recomputable on load; the crypt
     stays fixed at 5 forever. Cost that drove the split: per-run
     `deepest` threads through generator, GameState, HUD, bot win
     condition, and tables above depth 5 — verification risk, not
     appetite (D8/D23/D35 precedent). Unit ordering becomes:
     m3-dungeons → m3-depth → m3-magic → m3-craft → m3-quests.
- Baseline for the unit, architect-measured this session on `bdb190b`
  (post-#7 merge): 515 core + 300 content + 338 app = **1153 green**; the
  content suite (band assertion) green. The spec's verification block
  must require the printed line
  `24/40 won (60.0%), stalled 0, died at 1:1 2:9 3:6 5:24` verbatim.
- NEXT: story spec `m3-dungeons-spec-M3D.md, build prompt, worktree;
  launch waits for the user's gesture (the D35 direct-launch grant was
  per-round).

### D44 — 2026-08-23 — M3D verified and accepted at `19ebf6b`; the world has three dungeons; the 24/40 pin is finally code

- Branch `m3-dungeons, 11 commits, verified with independent instruments
  (all fresh this session): suites re-run myself in the worktree (515 core
  + 380 content + 364 app = **1259** green, +106 over 1153, nothing
  deleted); all four survivability lines verbatim in MY runs —
  crypt `24/40 won (60.0%), stalled 0, died at 1:1 2:9 3:6 5:24,
  fleetfoot 7/40, sea-cave `35/40 (87.5%), died at 3:5 5:35, ruined keep
  `31/40 (77.5%), died at 2:6 3:3 5:31`; **core `lib/` diff EMPTY** (the
  headline gate held); six forbidden files byte-untouched; `new_game.dart`
  = one code deletion + one architect-sanctioned dartdoc repoint (strip-
  the-docs diff proves code identity, re-proven by me); analyze clean from
  the worktree ROOT (my run) and format clean; **mutation row 2 re-run
  with my own sed: 8 content tests red, core green at 515, revert clean**;
  artifacts grepped (phone-size widget tests, litter pins, 40 shots incl.
  4 greyscale on disk).
- **The crypt's exact figure is now a code assertion** (wins, full death
  histogram, fleetfoot — `survivability_test.dart`), per D43. The worker's
  row-10a/10b extension proved the histogram is the real pin: a moved
  crypt kept wins at 24 while the histogram shifted — a wins-only
  promotion would have been a false guard.
- **Worker findings accepted, three of the architect's claims corrected:**
  (1) themed spawn tables could not be `Map<int, SpawnTable>` — the type
  resolves creatures through the forbidden global bestiary; shipped as
  `DungeonSpawnTable` over `Weighted<CreatureSpec>` (spec defect, mine);
  (2) no crawl app bar exists — the dungeon name lives in the HUD row
  (spec defect, mine); (3) the orphan-test "reds on themed creatures"
  hazard was false under the new shape — landed green-to-green with an
  extension row that reds it properly.
- **G2 was a real hole, found by the worker's own green row:** nothing
  read what a themed drop table decides for ordinary floor litter; closed
  by pinning each golden floor's litter by id and display name (2870194).
- **Report-vs-artifact mismatch, owned and repaired (M2E class, no
  breach):** "analyze clean project-wide" had been run from
  `packages/app, which does not reach other packages' test directories —
  4 branch-introduced warnings (dead null-guards in test fixtures) were
  invisible to it. Fixed (19ebf6b); the lesson is the command: **analyze
  runs from the worktree root, and the verification block quotes the
  `pwd`.** The worker flagged that its earlier in-flight messages carried
  the same mis-quoted gate — recorded here so no earlier claim is cited
  as a root-run.
- **Row-2 count lesson (worker's reconcile):** a mutation's red COUNT is a
  property of the sed, not only of the tests (`^ 0x1` reds 7, `^ 0xFFFF`
  reds 8) — name the set, not the number; the named set was stable.
- **Undeclared-but-ratified deviation:** the keep's drop curve reads two
  notches richer where the spec said one — four days a round trip must
  out-pay the cave; same rule applied twice, trail complete (four tuning
  steps, one revert to keep pierce figures standing).
- **Fifth device-only catch:** naming the dungeon overflowed the status
  row on a real phone by 64 px — invisible to every widget test because
  the default test surface is 800×600, wider than a phone in portrait.
  Fixed in a scale-down box + two tests at 1080×2424. **Ledger note (the
  worker's, earned): the widget suite has been measuring a screen no
  player has** — new-screen units should size at least one test like a
  phone.
- **Honesty accepted:** three of sixteen AVD steps loaded seeded saves
  (bounded-tap reality); NO band measures the bosses — the bot wins by
  arriving at the bottom floor, true of the crypt's 24/40 too; boss
  winnability is untested by anything but a person.
- **Known weakness surfaced for the user:** `arrivingAt` uncovers a
  node's neighbours (core, shipped M3W behavior, verified
  `whereabouts.dart:171-176`), so the first walk to Northgate reveals
  both new dungeons free and their rumors become unsellable. D43's
  "rumor-hidden" is honored as built-but-weaker. Follow-up 25.
- Bands 35/40 and 31/40 provisionally ratified by the architect;
  user confirmation pending with the PR round.
- Not yet done: push + PR (user approval pending per round, D22).
- UPDATE 2026-08-24: user approved ("open PR"); branch pushed, **PR #8
  opened** — https://git.fiatcode.dev/fiatcode/residuum-rpg/pulls/8, no
  conflicts, squash title in the description. Bands ratified implicitly
  by the approval; on merge: pull, re-run suites on `main` (expect 1259),
  survivability all three lines + fleetfoot, remove worktree + branches,
  record the close-out, fold the handoff record.

### D45 — 2026-08-24 — M3D merged as `59b91f1` via PR #8; story closed; the world has three dungeons

- User squash-merged PR #8 as `59b91f1` "feat: M3D Dungeons — the
  sea-cave and the ruined keep (#8)". All three suites re-run green on
  `main` post-merge (515/380/364 = **1259**) and all three survivability
  lines verbatim — crypt `24/40 (60.0%), 1:1 2:9 3:6 5:24, sea-cave
  `35/40 (87.5%), 3:5 5:35, ruined keep `31/40 (77.5%), 2:6 3:3 5:31` —
  measured this session. Bands ratified with the merge.
- Worktree and local branch removed; Forgejo deleted the remote branch on
  merge. `main`: 59b91f1 ← bdb190b ← 958ef98 ← 844376f ← ….
- The `residuum-m3-dungeons` session (current ref `[dd4e6d]`) may be
  closed by the user.
- NEXT per D43 ordering: spec `m3-depth` (M3X) — randomized depth per
  delve. The user's playtest of the full loop still feeds follow-up 24;
  the three-dungeon world is now the thing to playtest.

### D46 — 2026-08-24 — M3X forks locked: depth totals shown, ranges 4–6/5–7, the roll is derived not stored

- Recon (`m3-depth-recon.md, one agent + architect re-verification):
  `step()` never reads `deepestDepth` — the bottom rule lives entirely in
  the floor builder and validator, so the unit is S/M as split. Traps
  found: depth 6 today generates a SILENT dead-end floor (no stairs, no
  diagnostic — the `FloorProblem` typedef has no bottom input and must
  widen); `themedFloor`'s `>=` bottom check would place a boss and trophy
  on every floor from 5 down in a 7-deep keep (becomes `==` the delve's
  deepest).
- **User locked two forks (both on the architect's recommendation):**
  1. **The HUD shows the rolled total** ("The Sea-Cave — depth 3/6") —
     deterministic and knowable; the player judges the commitment before
     entering, which is the tension follow-up 24 wants. Rejected: hidden
     "depth 3/?" until the bottom is reached (costs a discovered flag and
     the pre-entry judgment).
  2. **Ranges: sea-cave 4–6, keep 5–7, uniform; crypt fixed at 5
     forever** (restates D43). The cave can roll shorter than the crypt —
     the farming dungeon; the keep never rolls shorter — the commitment.
     Rejected: wider (3–6/5–8, an extra tier + 38×23 maps) and narrower
     (4–5/5–6, less felt variety).
- **Architect rulings:** the roll is DERIVED, never stored —
  `deepest = lowest + mix(worldSeed ^ dungeonSalt(node), visit) % span,
  a floorSeed-style mix in a purpose slot; the save document stays
  byte-identical and `loadRun` recomputes it exactly as it recomputes
  `buildFloor` and `dropTables`. Rolling from the crawl's rng is rejected
  (new save key, goldens move, the depth draw would perturb floor
  streams). `GameState` gains optional-with-default `deepest`
  (the `isEncounter` pattern); the generator and validator widen by an
  optional bottom input defaulting to today's behavior.
- **Sanctioned costs, stated up front:** this unit EDITS CORE (generator
  seam, GameState) — the crypt's guards are the promoted 24/40 + histogram
  assertions, the characterization goldens, and a crypt path that never
  passes the new parameter. **Both themed bands and histograms re-pin by
  design** (the M3R precedent); the sea-cave needs depth-6 tables, the
  keep 6 and 7.
- NEXT: spec `m3-depth-spec-M3X.md, prompt, worktree; launch on the
  user's gesture.

### D47 — 2026-08-24 — M3X verified and accepted at `f57e647`; PR #9 opened on the user's conditional pre-approval; two doctrine lessons earned

- Branch `m3-depth, 6 commits, verified with independent instruments (all
  fresh this session): suites re-run myself (529 core + 396 content + 371
  app = **1296**, +37 over 1259; declaration counts match run counts);
  crypt survivability line CHARACTER-IDENTICAL in my runs (24/40,
  histogram, fleetfoot 7/40 — the identity guard never fired); re-pinned
  bands in my runs: sea-cave **34/40 (85.0%), died at 3:5 4:15 5:9 6:11**,
  ruined keep **31/40 (77.5%), died at 2:6 3:3 5:14 6:8 7:9**, ordering
  held; core diff exactly the three sanctioned files; must-not files
  untouched; golden saves byte-identical (diff zero); analyze clean from
  the worktree ROOT and format clean (my runs); 19 AVD shots on disk,
  two spot-READ (02: player hero 20/20 at "depth 1/6"; 17: greyscale
  "depth 3/6"); derived-not-stored proven ON DEVICE (`grep -c deepest
  save.json` → 0 on the app's own file).
- **My mutation re-run:** shifting the crypt early-return constant reds
  THREE named tests (rider-1 sweep, door-path agreement, crypt-camp
  codec). The worker's E5a mutant had claimed a single guard — it re-ran
  my sed, reproduced my set, WITHDREW the claim, and diagnosed its own
  instrument: E5a's replacement expression returned the ORIGINAL value at
  the fixture seed (5 at worldSeed 4242), so two guards never saw a
  change. **Doctrine: a mutant whose replacement range can coincide with
  the original at a test's fixture under-reports its red set — prefer
  constant shifts that cannot coincide.**
- **Worker's rows found two real defects and a harness hole mid-build:**
  the bot stalled on short delves before the win-condition threading (15
  of 40 cave runs walked circles hunting a fifth floor — row 8's
  condition was live, and its two halves are caught by DIFFERENT tests,
  reported split); copyWith's deepest carry lost on descend (a 6-floor
  cave read "depth 2/6" then "depth 2/5" after the stairs — closed at the
  bloc); PumpedApp never reached loadRun (boots the handed document —
  fixed by encode/decode-before-pump, the path a relaunch takes).
- **Three spec claims corrected (mine):** row 3 as written was a no-op
  (>= and == identical on reachable inputs — the real trap is against the
  CONSTANT, reported as 3a/3b); G2's "goldens green" now includes a
  themed-bottom red (that golden reads depth six, the tuned table —
  better coverage than M3D had, and the band alone would have let the
  retune through); four goldens predicted, two moved (first-floor pins
  are bottom-independent).
- **Report-accuracy arc, resolved:** shots initially lived only in the
  worker's scratch directory (not artifacts) — retaken/pulled, 19 listed;
  the AVD disclosure conflated two saves — the combat and entry
  observations were on a PLAYER-SHAPED hero (20/20, verified in shot 02),
  while the two camped saves used a god fixture differing in exactly
  three fields (hp/maxHp/attack; movement and save path identical). No
  load-bearing observation depends on the delta (each argued in the
  report); the depth-7 claim honestly narrowed to "walkable, renders,
  pans" — survivability at new depths is the bands' job. One visible
  fixture artifact: shot 08's town screen reads "Health 99976 / 20" —
  fixture-caused, not a defect. **Doctrine: an acceptance pass that seeds
  a save states its fixture's stat delta from the real starting hero
  field by field, then argues each observation past it.**
- The save-overwrite trap (user's 2026-08-23 emulator playtest save +
  backup lost) recorded in environment traps at disclosure time.
- **PR #9 OPENED on the user's conditional pre-approval** ("open PR once
  the reconciliation comes back clean" — it did):
  https://git.fiatcode.dev/fiatcode/residuum-rpg/pulls/9, squash title in
  the description. Bands ratified at the merge gesture unless vetoed.
- Not yet done: the user's squash merge; then close-out per ritual.

### D48 — 2026-08-24 — M3X merged as `b9d7c21` via PR #9; story closed; a delve rolls how deep it goes

- User squash-merged PR #9 as `b9d7c21` "feat: M3X Depth — a delve rolls
  how deep it goes (#9)". All three suites re-run green on `main`
  post-merge (529/396/371 = **1296**) and all three survivability lines
  verbatim — crypt character-identical, sea-cave 34/40, keep 31/40 —
  measured this session. Bands ratified with the merge.
- Worktree and local branch removed; remote branch gone on merge.
  `main`: b9d7c21 ← 59b91f1 ← bdb190b ← ….
- The `residuum-m3-depth [857d3b]` session may be closed by the user.
- Journal + Residuum page updated in the weft graph (2026_08_24, second
  entry).
- NEXT per D43 ordering: `m3-magic` — OR the playtest-fed balance ruling
  unit (follow-ups 24/25 + boss verdicts) if the user has played. The
  user's playtest of the three-dungeon world remains the standing
  parallel track (their 2026-08-23 emulator save was lost to the M3X
  acceptance pass — the playtest restarts from the acceptance saves or
  fresh).

### D49 — 2026-08-24 — The playtest verdicts land: the game is too easy, too generous, and combat is shallow; the parked balance questions activate

- The user played the three-dungeon world (crypt → Northgate → sea-cave,
  beat the drowned captain "in a breeze" after two delves). Verdicts, each
  verified against source where checkable:
  1. **The leave/travel/resume loop is cheap, and the CAUSE is the
     economy**: selling one or two drops funds the inn; items are so
     plentiful the currency is near-useless. Follow-up 24's camp-expiry
     design is confirmed needed, but the deeper lever is item volume and
     prices.
  2. **Discovery has no felt moment.** Undiscovered nodes draw as `[?]`
     rows from the start (intended — `_Unheard, world_screen.dart:237-251,
     architect-read) and `arrivingAt` reveals silently: NO activity-log
     line, no notification exists for discovery. The user read the new
     dungeons as "listed from the start". Follow-up 25 confirmed painful
     in play.
  3. **Too easy across the board** — every enemy trivial for a
     mid-progression hero; the drowned captain fell without resistance.
     The bands measured a kitted BOT at 85%; a human with judgment
     crushes it. The difficulty curve needs a ruling-level rebalance
     (touches the forbidden-lever tier — needs the user's explicit grant).
  4. **Rolled depth: no problem.** New observation: floors are always
     roughly rectangular (BSP inside a w×h box) — theme-shaped generators
     are the design spec's own M5 promise; logged, not now.
  5. **Combat is "brainless turn-based hack-n-slash"** — the user wants
     strategic decisions. The design's answer is layered: spells/skills
     (m3-magic) and damage types/resistances (spec section 5, entirely
     unimplemented — CreatureSpec carries only pierce).
  6. **Floor litter is too much**; the user prefers loot from kills and
     possibly chests. Litter-vs-drop weight is pure table numbers; chests
     need a new tile (save-format change — still sanctioned pre-ship, but
     new machinery).
  7. **The bottom floor has no completion beat**: no message, no dialog;
     the exit is the stairs and the game then still offers to continue
     the delve. Reaching the bottom should FEEL like a completed delve.
  8. **General UX needs work** — "common sense", not tutorials.
  9. **Bug report resolved as intended-but-unexplained**: the merchant's
     "Sold this visit" persists across town-screen re-entry (D36
     semantics, correct) and buy-back disables only on
     `gold < sellPriceOf(item)` (merchant_screen.dart:52-54,
     architect-read) — the UX never says why. Disabled controls need
     reasons.
- Nothing here moves without the next unit's forks; the split and
  ordering go to the user (balance-first vs magic-first, lever grants,
  chests now vs deferred, discovery-rule change vs beats-only).

### D50 — 2026-08-24 — m3-balance forks locked: full lever grant, litter-to-kills loot shift, discovery reveal-rule change; unit ordering re-set

- **User locked four forks (all on the architect's recommendation):**
  1. **`m3-balance` is the next unit** — one rebalance wave: litter cut,
     loot shifted to kills, economy re-priced, camp expiry (follow-up 24's
     ~3-day design), road-danger scaling, difficulty retune, and the
     three UX beats folded in (discovery log line + moment,
     delve-complete beat, disabled-buttons-say-why). Then m3-magic
     (spells + damage types/resistances answer "brainless"), accepting a
     small second retune after it. Rejected: magic-first (broken economy
     lingers); a separate m3-feel wave (more waves, slower).
  2. **FULL LEVER GRANT for this unit**: existing creature stats,
     spawn/drop tables, prices, and the starting kit are all open, each
     change with a trail. **Every survivability figure re-pins; the
     crypt's 24/40 dies by design** (M3R precedent). Follow-ups 14/15
     (clamp unification, cap-overflow quirk) should be ruled inside this
     unit's re-baseline window.
  3. **Loot: litter down, kill drops up — pure table numbers. Chests
     DEFERRED** (new tile + save reshape for a feel the drop-shift buys).
  4. **Discovery: beats AND the reveal-rule change** — arrival uncovers
     connected ROUTES, not the nodes behind them; rumors become the real
     door (resolves follow-up 25). Core world edit sanctioned.
- New follow-ups from D49 to carry: theme-shaped generators (rectangular
  floors — spec's M5 promise); chests (deferred here).
- Design question for the spec (architect ruling after recon): the
  delve-complete beat may want reaching the bottom to CHANGE the run's
  ending (leaving from a completed bottom ends the run alive rather than
  suspending) — recon must map what that touches before ruling.
- NEXT: recon → spec `m3-balance-spec-M3B.md` → prompt → worktree.

### D51 — 2026-08-24 — Mid-flight M3B ruling: the core fence extends to `wear.dart` and `step.dart` for follow-ups 14/15; the death path adopts the conditional merchant keep

- The M3B worker's blocker was correct and the spec's ruling 8 was
  unbuildable inside its own file fence: the TOWN already clamps both
  equip paths (`town.dart:159-165 _dressed`) — the asymmetric side is the
  DUNGEON (`step.dart:102-105` EquipAction does not clamp), and the
  displacement gate for follow-up 15 lives in shared `loot/wear.dart,
  whose own dartdoc forbids a one-sided fix.
- **Ruling: the fence extends to `loot/wear.dart` and `engine/step.dart,
  confined to exactly two hunks** — the EquipAction clamp line and the
  cap-aware `wearRefusal` branch — plus their moved pins (red-first, old
  assertions quoted). Everything else in both files byte-untouched,
  verified at the hunk level. Rationale recorded: this unit re-baselines
  every survivability figure anyway, so the one window where a step.dart
  edit costs nothing extra is open now — which is what D50's "ruled
  inside this window" meant. Both fixes land BEFORE the tuning converges
  or the trail is invalid (worker's own sequencing, adopted).
- **Second ruling (worker's finding C, adopted): death after a RESUME
  keeps the merchant visit memory** under the conditional keep — the
  visit did not move, the shelf did not turn over, and a burned pack does
  not restock a shelf. A deliberate behavior change on the death path,
  pinned by its own test. (Death after a fresh entry still clears: that
  visit moved.)
- Worker corrections accepted into the record: the recon's smoking gun is
  10 of 14 creatures at the floor of one, not 13 (the wight deals 2, the
  man-at-arms 3, the bosses more); spec mutation row 10 was a no-op at
  shipped values (the wight already clears the pin — architect
  arithmetic error; run verbatim, green reported as the finding,
  boundary-creature extensions added); the two "duplicated" discovery
  scans answer different questions (`rumorOnOffer` vs `_untold`) — the
  DEFINITION of undiscovered is what gets pinned per layer.
- Six shape deviations approved (derived-armor pin + extracted kit
  fixture; `dangerFor` function parameter; `roadSpawnTable` →
  `DungeonSpawnTable` with an old-roads stream-identity pin required;
  `campDay` on SavedHero; two expiry sites not three — days pass only on
  the road, so no boot check; bank dim-lines instead of ItemRow.reason).
- Crypt-band hazard mapped by the worker (finding E): pierce is inert
  against a fresh hero's armor 0, so the crypt's risk is falling out the
  BOTTOM of 45–70 as the litter cut bites; sanctioned counter-levers are
  the crypt's own litter floor and drop chances, never the hero side.

### D52 — 2026-08-24 — Mid-flight M3B ruling: the spawn tables open (the D50 grant carried through); the ghoul confines to the crypt's shallows; cave counts rise

- The worker stopped on the tuning exactly as the spec instructs, with a
  MEASURED proof (six-step trail, every configuration on all four lines,
  mirrored in the worktree's TUNING-TRAIL.md) that the ruling-11 targets
  fight each other under the levers the spec listed:
  - The designed-difficulty pin forces `pierce >= 6, maxRoll >= 4`-class
    creatures, and any such creature deals AT LEAST 4 to the armour-five
    hero a fresh crypt run actually is by depth three — the optimum is
    provable, not sampled. The crypt lands at 20–30% against a 45% floor;
    the loot lever end-to-end is worth four runs (8→12/40).
  - The sea-cave sat at 32–35/40 through EVERY configuration — litter,
    drops, pierce, deep ceilings — because the graduate kit out-trades it
    regardless of what it hits for; damage was never the cave's lever.
- **Root cause, stated for the record: the crypt and the themed dungeons
  are measured with different heroes (fresh vs graduate), and pierce is
  one dial that reaches both.** No single-dial setting satisfies two
  bands anchored to two heroes.
- **Ruling: the spawn tables are inside the unit's fence** —
  `spawn_tables.dart` and both themed spawn tables. This is not a new
  grant: D50's user grant said "spawn/drop tables all open"; the spec's
  changed-files list failed to carry it (architect defect). Approved
  edits, per the worker's own recommendation:
  1. The ghoul confines to crypt depths 1–2. It exits the pin's
     population by SCOPE (the exemption list stays {rat, crab}); its
     pierce re-tunes downward with a trail now that the pin no longer
     binds it. Step-5 evidence predicts the crypt near 50%.
  2. The sea-cave's monster counts rise a notch per depth — the one
     lever the cave has left; second-order effect (more bodies = more
     kill-drop healing income) to be measured, with the cave's own drop
     chances the next sanctioned lever before its hit points.
- The band targets STAND (no widening, no pin re-scoping — the depth-5
  alternative carries a stalled run, a hard suite failure, and widening
  the band makes it stop meaning anything).
- Landed meanwhile, all exits green: rulings 1–4, 7–10 (six commits,
  537/414/406 at the last); ruling 8 moved NO survivability figure (the
  bot never swaps its ceiling down nor displaces at the cap). The worker
  also self-corrected its three-scans claim (the spec's duplicate pair
  was real; all three scans pinned red-first), and the completion
  sentence shipped as moment/status/dialog across three surfaces after
  the worker caught the five-control row ellipsis pre-device.

### D53 — 2026-08-24 — M3B verified and accepted; the rebalance converges at crypt 50%, cave 77.5%, keep 70%; the instrument itself got fixed

- Branch `m3-balance, 9 commits, verified with independent instruments
  (all fresh this session): suites re-run myself (537 core + 418 content
  + 406 app = **1361**, +65 over 1296; declaration counts match); all
  four band lines verbatim in MY runs — crypt
  `20/40 (50.0%), 1:1 2:9 3:4 4:6 5:20, fleetfoot 14/40, sea-cave
  `31/40 (77.5%), keep `28/40 (70.0%), keep < cave, nothing stalled,
  bands tightened to 0.45–0.80 — ALL INSIDE THE D50 TARGETS; core diff
  exactly five files (step.dart +1 line ONLY, wear.dart the two scoped
  hunks — read at hunk level; town.dart needed NO change, the town
  already clamped both paths); must-nots absent; pubspec unchanged;
  analyze clean from the ROOT and format clean (my runs); goldens carry
  campDay; **my own sed (E11: kit Bulwark 5→8) reds three named tests**
  — the designed-difficulty pin (its armor is DERIVED) and both themed
  bands — revert clean. Shot 04 spot-read: "The Sea-Cave — depth 6/6",
  the status line, and "Finish" rendering complete beside three other
  controls.
- **The twenty-step tuning trail is the artifact of the unit** (mirrored
  in TUNING-TRAIL.md): includes the D52 resolution (ghoul AND wolf
  confined to crypt 1–2 — the wolf extension ratified: same lever, same
  direction, openly reasoned "the wolf simply took the ghoul's place as
  the thing that kills first-time players"; the crypt is now two
  dungeons with the line between depths 2 and 3), the failed
  configurations kept as proof, and step 20's one-run give-back (a wight
  at weight 1 on depth 3 so no floor is one monster on repeat).
- **The measuring instrument itself had a defect, found and fixed:** the
  bot dropped its first non-potion when full, the drop landed underfoot,
  and the pick-up rule took it straight back — an infinite loop at high
  loot densities (three stalls at raised cave counts, traced by action
  tail at named seeds). Rule removed; E9 GREEN proves the final figures
  are identical with and without it. It would have bitten whoever next
  raised loot densities.
- **Sixth device-only catch of the epic:** "Leave — done" (the worker's
  own approved wording) rendered "Leave — do…" on the phone — the
  five-control row. Shipped as "Finish" + the status line + the dialog;
  the three-surface split absorbed the fix without design change.
- **Migration fact for the user, device-proven:** EVERY pre-M3B save is
  refused by the campDay reshape (never-repair codec, specified
  behavior) — fallback chain works, "a new hero begins". Anyone holding
  a save loses that hero at this merge. Sanctioned while unshipped
  (follow-up 20), recorded loudly.
- Honesty accepted: the numbers say a fixed-policy bot wins half the
  time; whether the crypt is tense rather than punishing, the camp price
  reads as price not theft, and "claws you for 4" reads as danger — the
  user's next playtest. Two watch items: the crypt's first half is now
  the ONLY place armor works (sharp edge by design), and the
  fleetfoot-first exploit DOUBLED (7→14/40) as a side effect nobody
  asked for.
- New follow-up 28: the bot never plays the deepest floor (arriving is
  winning), so every bottom spawn table — bosses included — is
  unmeasured by every band; a real player meets it.
- AVD pass: both save slots copied aside FIRST and restored, SHA256-
  verified (the M3X trap honored); 11 shots + 7 greyscale; fixture
  deltas stated field by field; crawls reached by stairs, not by
  document edits.
- Not yet done: push + PR (user approval pending per round, D22).
- UPDATE: user approved ("open PR"); branch pushed, **PR #10 opened** —
  https://git.fiatcode.dev/fiatcode/residuum-rpg/pulls/10, no conflicts,
  squash title in the description. Bands ratified with the merge unless
  vetoed. On merge: pull, re-run suites on `main` (expect 1361), all four
  band lines, remove worktree + branches, record close-out, fold the
  handoff, journal.

### D54 — 2026-08-24 — M3B merged as `936ca5b` via PR #10; story closed; the game answers its first playtest

- User squash-merged PR #10 as `936ca5b` "feat: M3B Balance — pierce,
  scarcity, camps that expire, a world that talks (#10)". All three
  suites re-run green on `main` post-merge (537/418/406 = **1361**) and
  all four band lines verbatim — crypt `20/40 (50.0%), stalled 0, died
  at 1:1 2:9 3:4 4:6 5:20, fleetfoot 14/40, sea-cave `31/40 (77.5%),
  keep `28/40 (70.0%)` — measured this session. Bands ratified with the
  merge.
- Worktree and local branch removed; remote branch gone on merge.
  `main`: 936ca5b ← b9d7c21 ← 59b91f1 ← ….
- The `residuum-m3-balance [516b70]` session may be closed by the user.
- Journal + Residuum page updated (2026_08_24, third entry).
- NEXT: the user playtests the rebalanced game (watch items: the crypt's
  armor edge, the camp price, boss verdicts, the doubled fleetfoot
  exploit, whether "claws you for 4" reads as danger). Then m3-magic per
  D50 ordering, informed by the verdicts. Follow-up 28 (no band measures
  a bottom floor) stands.

### D55 — 2026-08-24 — m3-magic forks locked: types on spells only, hero-only mana, auto-target, three schools; the bands become controls

- Recon `m3-magic-recon.md` done first (four read-only agents, sharpest
  claims re-read at source by the architect; baseline re-measured: 1361
  green, all four band lines verbatim on `936ca5b`).
- **User locked four forks (all on the architect's recommendation, via
  the structured question):**
  1. **Damage types ride the spells only.** Spells carry a type; creatures
     gain resistance/vulnerability fields (defaulted empty); melee stays
     untyped this ring. Full section-5 weapon typing deferred to M4/M5.
     Rejected: two-unit full typing (M3M+M3E); no types at all.
  2. **Cast cost is a hero-only mana pool** — an int beside `gold` on
     `GameState`/`Profile, never on `Actor` (monsters do not cast).
     Maximum derives from school skill levels; restores at stairwells and
     the inn. Rejected: cooldowns; per-delve charges.
  3. **Ranged spells auto-target the nearest visible enemy**
     (deterministic tie-break, existing visibility primitives). No
     tap-to-target mode this unit.
  4. **Only the three schools enter `SkillId` now** (Wrath, Mending,
     Binding — appended AFTER `fleetfoot` so golden key order stays
     stable). The other six skills arrive with their mechanics.
- **Standing assumptions stated to the user and not vetoed:** one more
  save-format break is sanctioned (known spells + mana + school skills +
  creature resistance fields; **every pre-M3M save is refused, the user's
  playtest hero included**; follow-up 20 restated — this replaces D53's
  "campDay was the last break" line, and the spec restates that THIS must
  be the last break before ship). `saveVersion` bumps 1 → 2 (the
  clean statement; a v1 document would otherwise silently read the new
  schools as level 0, which the never-repair doctrine forbids).
- **Correction to what the architect first told the user:** the four band
  lines are now expected to HOLD IDENTICALLY, not re-pin. The bot stays
  melee-only by design (the bands measure melee survivability; the fresh
  and kit heroes know no spells and casting never fires), so all four
  lines become CONTROLS proving the spell system leaves the melee game
  untouched. Any moved line is a defect (an added or removed RNG draw on
  a non-casting path), not a re-baseline. Less destruction than the
  re-pin the user was told to expect — no new sanction needed.
- **Road-danger constant stands, with reasoning recorded:** each action
  trains at most one skill, so a caster's total skill-sum growth per
  delve is roughly unchanged (cast xp displaces swing xp; defence
  training is unchanged) — `roadTierLevels = 8` keeps its calibration
  and its four pins. Recon finding 7's recalibration fear dissolved on
  this argument; revisit only if the playtest says roads outpace heroes.
- Spec proposal accepted as the working spell list (worker may refine
  with a trail): six spells, two per school — Wrath: Firebolt (fire) +
  Frost Lance (frost); Mending: Mend (heal) + Ward (absorb pool);
  Binding: Bind (root) + Banish (relocate). Books as base items with a
  `teaches` field, distributed per-dungeon via drop-table weights
  (weight 0 elsewhere), validation-enforced.
- NEXT: spec `m3-magic-spec-M3M.md` → build prompt → worktree → user
  launches `residuum-m3-magic`.

### D56 — 2026-08-25 — Mid-flight M3M ruling: the C1 band-identity control was impossible and is struck; books ride the depth tables and all four bands re-pin; the spell gates drop to 4/4/3

- The M3M worker refuted spec control C1 WITH AN EXPERIMENT before any
  code: one drop-table weight flipped 0→1 moved the crypt line 20→19 and
  fleetfoot 14→12 (reverted clean). Two mechanisms, either fatal:
  `_draw` sums weights into the roll's range, so changing the total
  changes the drawn VALUE at the same stream state (every floor's litter
  and every kill drop re-rolls for every seed); and the bot picks up any
  item underfoot, so an extra book on its route costs a turn and shifts
  the combat stream. D55's "bands hold byte-identical" was the
  architect's construction and it cannot coexist with books in dungeons.
  Architect defect, owned.
- **Ruling 1: option C — the design wins over the control.** Books ride
  the per-dungeon depth tables exactly as contract 9 says ("specific
  books drop in specific dungeons" is the design spec's own promise and
  the discovery texture the last three units built); **all four band
  lines re-pin with a measured trail** (the user sanctioned re-pins in
  the original brainstorm; D55's hold-identical claim was a later
  architect refinement, now dead). Requirements: the 0.45–0.80 soft
  bands and `keep < cave` must still hold at convergence (tune book
  weights/litter with the trail if not); movement must be argued from
  table composition and pickup turns, never combat math; C2
  (designed-difficulty pin) and C3 (crypt LAYOUT goldens — M3B precedent
  says layout bytes survive table changes) stay as the melee-untouched
  controls, plus hunk-level diff on both formula copies. C4 stands
  (bands never cast regardless). Rejected: worker's option A
  (merchant-only books — kills the found-in-dungeon goal loop) and B
  (trophy-table books — pollutes the guaranteed-rare promise with
  Common-forced books and pays winners in duplicates).
- **Ruling 2: gates were unreachable — architect arithmetic error**
  (level L costs L²+3L casts at 1 xp/cast: Wrath 15 = 270 casts ≈ 82
  floors). New gates: **frost-lance Wrath 4, banish Binding 4, ward
  Mending 3** (28/28/18 casts — a one-to-two-delve goal). Contract 1
  stands (1 xp per cast, same as a swing); `heroMaxMana`'s base of 4 is
  confirmed tunable UPWARD with a trail.
- **Worker defect fixes adopted (pre-declared):** mana refills only on
  first arrival at a never-built depth (`floors[depth] == null`) — the
  spec's `_arriveOn` refill recreated the stairs-bounce healing loop the
  code's own dartdoc predicts; `bound` clears on every floor arrival —
  monster ids are unique per FLOOR, so a bind must not survive a
  stairway. Contract 4 governs `resumeRun` mana (restore, never refill);
  the spec's changed-files bullet saying otherwise is wrong.
- **Deviations approved:** `byRowThenColumn` moves from content's
  actor_codec into core `engine/position.dart` (content imports core —
  one comparator, one home); books ride `armory.dart`; seven events as
  specced with `SpellHit` carrying type + resisted/vulnerable marker so
  the log never re-derives from content.
- Worker verifications accepted: enum append keeps golden key order
  (confirmed at source); glyph `?` free; book price arithmetic sound
  (rarity multiplier inert on Common-forced books — noted).

### D57 — 2026-08-25 — M3M verified and accepted at `20c030c`; the game casts; the seventh device-only catch; four worker decisions ratified

- Branch `m3-magic, 9 commits, verified with independent instruments
  (all fresh this session): suites re-run myself — **657 core + 472
  content + 441 app = 1570** (baseline 1361; the report's 1569/440 was
  stale by exactly the one widget test its own final commit `20c030c`
  added — my declaration count also reads 441; asked, not recorded as a
  breach). All four re-pinned band lines verbatim in MY runs: crypt
  `20/40 (50.0%), 1:1 2:6 3:6 4:7 5:20, fleetfoot 14/40, sea-cave
  `30/40 (75.0%), keep `25/40 (62.5%)` — every asserted rate inside
  0.45–0.80, keep strictly below cave. Diff read at hunk level:
  `wear.dart` and `designed_difficulty_test.dart` (the second formula
  copy) UNTOUCHED; exactly two new `state.rng` draws in step.dart, both
  on cast paths (bolt roll, banish landing); the ward sits after the
  floor-of-one with no roll, argued in dartdoc; skills enum appended
  with the reorder warning written down; `saveVersion = 2` declares
  itself the last break. No creature stat line moved (my grep over the
  three bestiary diffs); pubspec untouched; analyze/format clean (my
  runs, worktree root). **My own sed** (firebolt 2–4 → 3–5, a
  non-coinciding constant shift) reds exactly the named pin `the six
  spells carry the numbers they were tuned to, revert clean. Claimed
  artifacts grepped real: the cross-floor bind test (bind `ghoul-1,
  descend, the OTHER `ghoul-1` swings), the V1 golden capture file, the
  device-save copies, old golden strings in `3fe43d8`'s message. Shot 09
  read: "Firebolt burns the giant rat for 4." with mana 5/7 — matches
  the disclosure.
- **Worker decisions ratified:** (1) C4 restated — the control's claim
  is "the bands never cast", not "the content suite stays green"; the
  worker's own shipped-cast test rightly reds under free casting. (2)
  Commit `3c89261` closed a REAL coverage gap the mutation table found —
  no test had put the shipped spells through the real cast path (core
  builds its own Spell constants; content pins numbers only). (3) Row 9b
  (tie-break comparison reversed) added — row 9 could never red the
  tie-break tests; architect table defect. (4) Books named only where
  they drop (absence = weight 0, the house idiom — verified:
  `roadDropTable` names 8 of 14) with a validation test treating both
  identically; `SpellLearned` carries the Item and Spell
  (PotionDrunk idiom).
- **Seventh device-only catch:** the shared read rule truthfully told a
  potion "Healing Potion is not something to read" and the Potions
  section printed it under a Drink button — invisible to every suite,
  fixed with a pinning widget test (`20c030c`).
- **The save-slot ritual earned its keep:** `flutter install` destroyed
  the app data directory (uninstall-then-fail on a missing APK); both
  playtest slots were recoverable only from the pre-pass copies,
  restored SHA256-identical, second copy in
  `docs/reports/device-saves/`. **User-facing consequence: the
  emulator's two saves are version-1 documents; the M3M build refuses
  them by design ("a new hero begins" — proven on device against the
  real save, not a fixture).**
- Tuning trail: five rows, two kept as failures; row 0a (rules half
  with no table touched → four lines byte-identical) attributes every
  later movement to table composition; converged at book weights
  1/1/2 (keep needs 2 or it ties the cave). Row 4 proves resistances
  move nothing a sword does.
- Honest gaps carried: no band measures a casting hero (follow-up 28
  widened — magic feel is human-judged only); `heroMaxMana` base 4 is
  untuned (no instrument exists); the status line's new clauses have
  not been seen on a real phone.
- Not yet done: push + PR (user approval pending per round, D22).
- UPDATE (same day): the worker confirmed both flags by re-measurement.
  The count is 1570 (its app figure was taken one commit before its own
  potion fix added a test) — report corrected in place. And its row-1
  note ("also reddens the shipped-cast tests") was a claim it never ran:
  both shifts red ONLY the content pin. The shipped-cast assertions are
  deliberately relational (they pin the WIRING — shipped registry
  through the real cast path, real resistances reaching it); the exact
  numbers are the pin's job alone. Precision restored on what `3c89261`
  fixed: rows 2/3 used to red core only, now red both packages; row 1
  correctly reds the content pin alone. No code changed; tree clean at
  `20c030c`.
- UPDATE: user approved ("open PR"); branch pushed, **PR #11 opened** —
  https://git.fiatcode.dev/fiatcode/residuum-rpg/pulls/11, no conflicts,
  squash title in the description. Bands ratified with the merge unless
  vetoed. On merge: pull, re-run suites on `main` (expect 1570), all
  four band lines, remove worktree + branches, record close-out, fold
  the handoff, journal.

### D58 — 2026-08-25 — M3M merged as `83b5336` via PR #11; story closed; the game casts

- User squash-merged PR #11 as `83b5336` "feat: M3M Magic — three
  schools, six spells, and a save that casts v2 (#11)". All three suites
  re-run green on `main` post-merge (657/472/441 = **1570**) and all
  four band lines verbatim — crypt `20/40 (50.0%), stalled 0, died at
  1:1 2:6 3:6 4:7 5:20, fleetfoot 14/40, sea-cave `30/40 (75.0%),
  keep `25/40 (62.5%)` — measured this session. Re-pinned bands
  ratified with the merge.
- Worktree and local branch removed; remote branch deleted by the
  merge. `main`: 83b5336 ← 936ca5b ← b9d7c21 ← ….
- The `residuum-m3-magic [638a39]` session may be closed by the user.
  The emulator still carries an M3M debug build; the user's version-1
  emulator saves are refused by it (preserved in
  `docs/reports/device-saves/` — unreadable by any v2 build).
- New follow-ups from the wave: 29 (a spell-casting bot band, so magic
  balance gets an instrument — until then spell feel and heroMaxMana's
  base of 4 are human-judged only); 30 (the status line's new
  `Mana n/m` clause has not been seen on a real phone — check at the
  next device session).
- NEXT: the user playtests — now judging BOTH the M3B rebalance watch
  items AND how casting feels (mana budget, gates at 4/4/3, bind/banish
  worth their cost, fire-vs-frost across dungeons). Then m3-craft (M)
  per D20/D50 ordering, informed by the verdicts; then m3-quests.

### D59 — 2026-08-25 — m3-craft forks locked: saveVersion 3, materials as counters, lean scope, gathering-only sources; the "last break" doctrine corrected

- Recon `m3-craft-recon.md` done first (four read-only agents; sharpest
  claims re-read at source; baseline = D58's, measured this session on
  this exact commit).
- **User locked four forks (all on the architect's recommendation):**
  1. **saveVersion bumps 2 → 3.** Two new skills reproduce exactly the
     situation that forced v2, and v2's own dartdoc forbids the
     silent-zero alternative. Zero v2 saves with progress exist (the
     playtest was deferred), so the bump is free today. **Doctrine
     correction recorded: no dartdoc claims "the last break" again** —
     that claim has failed twice (D53 campDay, D55 v2) and m3-quests
     will break the format a third time for quest state. The honest
     rule is follow-up 20 as written: the version freezes at the first
     SHIPPED build; pre-ship breaks are sanctioned per-unit.
  2. **Materials are counters** (`Map<MaterialId, int>` on Profile +
     GameState), mirroring gold: carried into the dungeon, lost on
     death, not banked and not sold this unit. Rejected: materials as
     items (six pack-cap collisions, the Drink-button fall-through,
     the 1-gold price hole, the bot, and every band via table weights).
  3. **Lean scope**: Forge (smelt ore→ingot; temper +1/+2/+3 for
     ingots + gold, gated by Blacksmith, hp re-clamped through
     `_dressed`) and Alchemist (brew herbs→healing potion) as
     town-blind doors in BOTH towns. Deferred with reasons: basic gear
     forging (merchant overlap + the crafting-serves-loot guard; M5
     recipes own it), camp brewing (section 7.1 parenthetical; the
     world-screen camp-door seam is mapped for it), material banking.
  4. **Materials come from gathering nodes only.** Ore veins + herb
     nodes as `Map<Position, NodeKind>` state (never a Tile, never an
     Item) on a separate salted stream; Mine/Gather as underfoot
     refused actions training Blacksmith/Herbcraft one xp per success;
     nodes deplete per floor per run. No drop table is touched, no new
     draw on `rng`/`lootRng` — **all four band lines are CONTROLS
     again, and this time the claim survives the D56 analysis** (the
     failure mechanism — table weight totals and bot-visible items —
     is absent by construction). Kill-drop/chest materials deferred
     (chests do not exist; permission not requirement).
- Standing rulings for the spec: road danger keeps its unfiltered
  skill-level sum (a tempered hero IS further along), pinned explicit
  by a new test; `heroMaxMana` immunity pinned (school filter); temper
  must reach `props, `stackKey, `displayName`-or-column (marking must
  not collide with the Fine `+` / Rare `++` glyphs), and `sellPriceOf`
  (the one consumer reading `base.*` — a temper price term beside the
  book term); enum appended after `binding, never inserted.
- NEXT: spec `m3-craft-spec-M3C.md` → prompt → worktree → user launches
  `residuum-m3-craft`.

### D60 — 2026-08-25 — Mid-flight M3C ruling: nine pre-declarations approved; the node type is `GatherKind`; the step.dart fence gains one delegation line

- All nine approved before code (architect verified the forced one at
  source):
  1. **`GatherKind` replaces the spec's `NodeKind`** — forced:
     `world/node.dart:42` already declares `NodeKind { town, dungeon }`
     (used by the save codec); a second `NodeKind` in the barrel is a
     compile error in all three packages. Spec vocabulary otherwise
     unchanged (`nodes, `gatherSalt, `NodeGathered`).
  2. Craft transactions live in `town/town.dart` (they need `_dressed`
     and `Transacted`); `craft/` holds rules + data so widgets read
     refusals without the town layer (readRefusal precedent). One
     `craft.dart` for smelt+brew rules (duplicate-twice rule).
  3. **Town-side training mechanism:** public `trainedIn(...)` in
     `skills/skill.dart`; the three transactions call it; **the
     step.dart fence extends by exactly one line** — `_train`'s body
     delegates to it so the grant rule has one copy. The level-up
     sentence surfaces via the town notice reusing the existing
     wording; `SkillLevelledUp` stays a GameEvent.
  4. `gatherSalt = 0x6A1E, chosen by MEASUREMENT: the worker swept the
     30-bit seed space (12 worlds × 3 dungeons × depths × 2000 visits)
     and two plausible constants COLLIDED with real floor seeds (0x5B1F:
     40 hits; 0x3C0F: 10) — the disjointness pin would have reddened.
     The salt table goes in the trail.
  5. Placement helper + counts in new `content/lib/src/gathering.dart`.
  6. Glyphs `*` (ore vein) / `"` (herb patch); 7. temper marking `‡`
     rendered `‡+2 temper`; 9. material markings `◆`/`▮`/`✿` — all
     checked against the live glyph sets, not the spec.
  8. `brewNumber` on Profile confirmed (no cheaper uniqueness exists;
     `nextDropNumber` is run state, town cannot reach it).
- The worker attacked control C1 as instructed and found no path,
  naming its search sites; one subtle catch: the bot's skill map DOES
  gain the two appended skills (`survivability_test:331` builds over
  `SkillId.values`) but no band assertion reads them.
- Contract 6's `_dressed` note taken as written: dartdoc + route, no
  unobservable clamp test.

### D61 — 2026-08-25 — M3C verified and accepted at `ea6f05c`; the bands held byte-identical; PR opened on the user's conditional pre-approval

- Branch `m3-craft, 12 commits, verified with independent instruments
  (all fresh this session): suites re-run myself — **762 core + 530
  content + 498 app = 1790** (+220 over 1570; matches the report
  exactly). **All four band lines byte-identical to the D58 baseline in
  MY runs** — the unit's central control (C1) held under the claim that
  survived the D56 analysis at recon; C2–C5 green per the report. Diff
  read at hunk level: `wear.dart, the second formula copy, every drop
  and spawn table, `marketTable, all pubspecs — ZERO diff lines;
  **zero** new `rollRange` draws in step.dart; the step.dart fence held
  at exactly the declared four places (the `_train` delegation hunk
  read — one rule, `trainedIn, both surfaces); the economy term shipped
  as `temperWorth = 2` with the argued dartdoc (the worker's tenth
  pre-declaration — the spec's ×3 was the architect's third arithmetic
  error this epic). **My own sed** (smeltCost 2→5, non-coinciding) reds
  five named `smeltOre` tests, revert clean. Fixture-order claim
  verified structurally: `90b9245` is the branch's first commit and
  touches only the plan and the version-gate test. Artifacts grepped
  real: `trainedIn, the tuning trail, the saveslots copies, nine shots
  + greyscale. Shot 07 read: the forge bench with three distinct
  dead-row reasons in words, `‡+2 temper, fixed-column materials —
  matches the disclosure.
- Wave notes: the worker attacked C1 as instructed and pinned it by
  measurement anyway (21-floor layout digests captured on pre-gathering
  code — row 1's green half); the `gatherSalt` was chosen by a
  collision sweep that found two plausible constants would have
  reddened the disjointness pin; the AVD pass caught the `▮`-width
  column defect (text-padding layout, fixed in `ea6f05c`) and the
  copy-aside ritual saved the device saves AGAIN (the autosaver's
  fallback rotated the originals off the device; `adb install -r` used
  instead of the destructive `flutter install`). Backups now ALSO in
  the main repo at `docs/reports/device-saves/` (SHA256-verified) so
  worktree deletion cannot take them.
- Honest gaps carried: gathering pace and the temper economy are
  human-judged (no instrument — follow-up 29's class); the `_dressed`
  temper route is documentation-only today; one AVD at one size.
- UPDATE: pushed and **PR #12 opened** on the user's conditional
  pre-approval (recorded this morning; D47 precedent) —
  https://git.fiatcode.dev/fiatcode/residuum-rpg/pulls/12, no conflicts,
  squash title in the description. Bands (unchanged) ratified with the
  merge. On merge: pull, re-run suites on `main` (expect 1790), all four
  band lines byte-identical, remove worktree + branches (the saveslots
  copies are ALREADY preserved in the main repo's
  `docs/reports/device-saves/`), record close-out, fold the handoff,
  journal, close session `residuum-m3-craft [8d79bf]`.

### D62 — 2026-08-29 — M3C merged as `54ec315` via PR #12; story closed; the playtest verdicts land

- User squash-merged PR #12 as `54ec315` "feat: M3C Craft — mine it,
  smelt it, temper what you found (#12)". All three suites re-run
  green on `main` post-merge (762/530/498 = **1790**) and all four
  band lines verbatim in my runs — crypt `20/40 won (50.0%), stalled 0,
  died at 1:1 2:6 3:6 4:7 5:20, `greedy build: 20/40 won;
  fleetfoot-first build: 14/40 won, sea-cave `30/40 won (75.0%),
  stalled 0, died at 2:1 3:8 4:13 5:9 6:9, ruined keep `25/40 won
  (62.5%), stalled 0, died at 1:4 2:5 3:4 4:2 5:13 6:6 7:6` —
  byte-identical to the D58 baseline. Bands ratified.
- Worktree `.worktrees/m3-craft` and local branch removed; remote
  branch already deleted by the merge. Saveslot backups confirmed in
  the main repo's `docs/reports/device-saves/`. Handoff record folded
  (closed). Session `residuum-m3-craft [8d79bf]` may be closed by the
  user. The user journaled the merge themselves (2026-08-29).
- **The playtest verdicts (2026-08-29 journal):** balance ENDORSED
  ("more scarce items, monster drop, fights slightly harder and
  consume more potion in single delve") — the M3B watch items need no
  balance ruling. Two suspected defects: (1) a learned spell
  disappeared after travel + entering a new dungeon; (2) no ores or
  herbs found at all while delving. Three feel/UX verdicts: casting
  requires opening the inventory; the town "Gear" menu wants to be a
  character menu like the dungeon "Pack"; the HUD one-liner is
  cramped and uninformative. Root-cause recon on both defects
  dispatched (read-only) before any speccing; brainstorm fork next —
  fixes+feel unit vs straight to m3-quests.

### D63 — 2026-08-29 — Post-playtest forks locked (user, structured question): m3-fixes first, then a HUD+cast design unit, then m3-quests

- The balance verdict needs no ruling (D62); the work is two defects
  plus three UX asks. **User locked the ordering on the architect's
  recommendation:**
  1. **`m3-fixes` (S):** (a) `startRoadEncounter`
     (`packages/content/lib/src/world.dart:390`) carries `knownSpells, `spells, `materials, and sets `mana` so road fights are
     magic-aware and stop wiping profile state through `endRun`
     (root-caused 2026-08-29, architect-verified at source; written in
     the m3-world era, never updated when M3M/M3C added fields);
     (b) remembered gathering nodes render at `_rememberedOpacity`
     (`glyph_grid.dart:179` fence — the worker's own "part of the
     place" dartdoc already demands it; nodes today render only in
     live FOV, which is why the playtest found "no ores or herbs" —
     spawn is NOT defective: 1–3 nodes/floor, every dungeon, "Never
     zero" pinned); (c) the town "Gear" menu becomes a character menu
     mirroring the dungeon "Pack" (gear + stats + spells + skills +
     materials), per the playtest verdict. No save bump — v3 stands.
     Bands stay controls (nothing bot-visible moves; to be argued at
     recon, not assumed).
  2. **A HUD+cast design unit (M):** the HUD one-liner revamp and the
     direct cast affordance TOGETHER — where the cast control lives is
     a HUD decision; doing them apart guarantees rework. Own brainstorm
     with real visual forks (the author's greyscale constraint binds).
  3. **Then m3-quests (M3Q, S/M)** — the last M3 unit; save v4 per-unit
     sanctioned (D59 doctrine).
- The M3M casting-feel verdict ("casting requires opening the
  inventory") and the M3C crafting verdicts (gathering pace, temper
  economy, forge loop) RE-OPEN after the HUD+cast unit — the playtest
  could not honestly judge gathering or casting through these
  defects; follow-up 29's class (human-judged) still stands. Follow-up
  30 (status line on a real phone) rides the HUD unit.
- Rejected: one big feel unit (slows the defect fix behind a design
  brainstorm); defects-only with UX deferred past m3-quests (the user
  keeps playtesting on the cramped HUD and inventory casting).

### D64 — 2026-08-29 — m3-fixes dispatched: worktree off `54ec315, mailbox open, the epic's first pi build session

- Recon done fresh on `54ec315` (two read-only agents + architect
  reads; `m3-fixes-recon.md`): both defects verified at source and both
  UNTESTED pre-fix — the red tests are free; no band, no fingerprint, no
  save shape can move (road seeds are separate; the fix adds zero rng
  draws; the bot never enters a road fight). Spec `m3-fixes-spec-M3F.md`:
  three item contracts, characterization-first test plan, seven-row
  mutation table with controls, AVD ritual restated.
- Worktree `.worktrees/m3-fixes` @ `54ec315, branch `m3-fixes`.
  Mailbox `docs/epic/handoff/m3-fixes/` opened with the dispatch note as
  architect entry 1; the architect's standing watch runs as a bg task
  (`docs/epic/watch-architect.sh, restart-on-wake, stamp seeded AFTER
  worker.md creation to avoid the spurious first fire).
- **The user chose `pi` as the worker harness** (per-dispatch choice,
  structured question). First pi worker on this epic — the 2026-08-31
  cross-harness field trial (comm probe 4) proved the pair; its recorded
  caution is restated in the prompt: pass shell-command timeouts
  explicitly when polling (the cap reads as a quiet timeout). The
  launch gesture: `cd .worktrees/m3-fixes && pi -n m3-fixes, then the
  pointer prompt. Creating the session pre-approves its writes —
  recorded here per the protocol.
- The worker's deviation/question channel and the pre-declaration duty are
  in the build prompt; expect a kickoff acknowledgment in worker.md.

### D65 — 2026-09-01 — Mid-flight M3F ruling: five pre-declarations approved; the spec's mana-0 claim corrected; the extraction-first C2 order is the honest form

- Worker kickoff (mailbox entry 1) re-measured the baseline itself (1790,
  bands verbatim — matches D62) and attacked every claim the prompt named.
  **Spec error found and owned (the 5th arithmetic/claim error of the
  epic, this one the architect's recon):** R2's warning said a spell-less
  hero has max mana 0 — `heroMaxMana` carries baseMana = 4 (`mana.dart:4-6`),
  so an unschooled hero observes 4. Fixture schooled anyway; no test
  change needed. The spec's warning line is corrected by this entry.
- **Five pre-declared shape deviations, all approved BEFORE code**
  (architect entry 2):
  A. Item 2 instrument is `glyph_plan.dart`: pure
      `List<GlyphCell> glyphPlan(GameState, DungeonPalette)` + exported
      `rememberedOpacity`; the painter consumes the plan. (GameState, not
      GameViewState — the plan needs no bloc; palette, because terrain
      ink is themed and the plan must be fully observable.)
  B. C2 sequencing: the plan seam does not exist on the base commit, so
      C2 runs against the refactor, not the base. Order locked: (1) the
      extraction as a pure refactor commit — every loop lifted VERBATIM,
      none rewritten, all 1790 green, quoted; (2) C2 written and quoted
      passing BEFORE the node branch changes. C1 stays on the true base.
      This is the honest form of "characterization passes against
      unmodified code" when the instrument itself is new.
  C. R1–R4 reds watched in the working tree, then the four-argument fix,
      then ONE green commit (reds + fix together, old values quoted in
      the body) — every commit's exit state green, as the doctrine binds.
  D. Pack's private stats/skills widgets duplicated (second occurrence,
      at the extraction threshold — a third extracts); NO potion action
      in town (no Drink event exists; the spec forbids new events).
  E. `docs/plans/` is NOT actually gitignored in this repo (recon/trap
      error, benign): the plan file stays UNTRACKED and every commit
      stages explicit paths only. No plan file may be committed.
- The worker starts on the architect's ack; A and B were the only holds.

### D66 — 2026-09-01 — The m3-fixes worker session broke mid-mutation-table; re-dispatched to a fresh pi session on the same unit

- The user reported the worker session broken mid-way, after its entry-2
  progress report and before any entry 3. **Worktree verified by the
  architect at the break: clean** — zero diff, no mutation left
  half-applied (the unknown is which rows ran, not whether one stuck),
  five commits on `m3-fixes` over `54ec315` (`1ae269a`..`5dcfaa6` — items
  1-3 all built per entry 2). No BUILD-REPORT yet; the plan file is on
  disk in the main repo's `docs/plans/`. No orphaned worker-watch
  process (pgrep clean).
- Continuation brief appended as architect entry 5: the record re-binds
  the replacement (mailbox entries 1-5 + build prompt + spec + plan);
  the mutation table restarts from row 1 (an unknown number of rows ran
  — none trustworthy); then the verification block, the AVD ritual, the
  report, the done notice. Entry numbering continues at worker entry 3;
  entry 4's stamp correction (the predecessor's 12-min hand-typed drift)
  binds the replacement from the start.
- The re-dispatch is the user's gesture again — creating the fresh
  session pre-approves its writes (D64 precedent, same unit, same
  channel). No ledger state was lost: the mailbox IS the continuity
  mechanism and it held every ruling.

### D67 — 2026-09-01 — Replacement worker's return: mutation table done with three spec-prediction corrections; M7 instrument substitution accepted; the M5 false-green handled by doctrine; AVD pass half-done, paused on quota

- The replacement worker re-bound from the mailbox (entry 3), re-derived
  its own counts (762/533/515 = 1810 on `5dcfaa6`), re-quoted all four
  band lines byte-identical, C1 green (17 tests).
- **The observed mutation table supersedes the spec's predictions**
  (three corrections, worker's, now binding): M1 reddened wider than
  predicted (R2/R3 join, same root cause); M2 left R4 green (R4 asserts
  only knownSpells/materials); M3 left R3 green (an empty carry satisfies
  death-clears-materials); M5 is insensitive for R5c/R5d (never-seen
  absence and visible-ordering both hold under either loop). The
  doctrine holds: a prediction is not a measurement.
- **M7 substitution accepted:** the scripted mutation target did not
  compile (`List` indexing by `PackSection`); the equivalent-intent
  `packSections(const [])` compiles and named its reds. Pre-declaration
  landed in the same entry as the run — accepted once because the code
  was frozen; instrument fixes should still pre-declare before running.
- **M5 false-green disclosure:** the worker's first attempt omitted
  `sed -i` — the mutation never touched disk and 7 tests "passed"
  against unmutated code; caught because the green contradicted the
  predecessor's watched red; re-run with the mutation verified by
  `git diff` first. Exactly the doctrine's stop-and-rerun; no broken
  result entered the table.
- Static verification clean: `dart analyze .` (worktree root), `dart format --set-exit-if-changed .` (0 of 200), `flutter analyze,
  tree clean at `5dcfaa6, five commits over main.
- AVD pass, half done (user's quota pause honored): ritual in order,
  BOTH slots copied aside (md5s) BEFORE the install; storage trap hit
  (/data 92% full) and resolved by uninstalling the old pre-fix build
  after the aside-copies verified; new APK installed (153,590,984 B);
  saves RESTORED and md5-matched byte-identical (via `run-as stdin`
  after the push+cp path failed ENOENT). Town screenshot captured
  (`docs/reports/shots/m3-fixes/01-town-doors.png`). Both new device
  traps recorded in the traps block.
- **Remaining (next worker session):** the Character-door visual read,
  screen sections on device, remembered-node screenshot + greyscale
  variant, BUILD-REPORT.md, done notice as entry 4. Then architect
  verification with own instruments, PR flow on approval.

### D68 — 2026-09-01 — Second M3F continuation: the AVD tail dispatched to a fresh Claude Code worker session

- The paused pi worker is not resumed; **the user chose a fresh Claude
  Code session** for the remaining work (per-dispatch harness choice,
  D64 rule). Creating the session pre-approves its writes — recorded
  per the protocol, D64/D66 precedent.
- Continuation brief appended as **architect entry 8**: the record
  re-binds the replacement (worker entries 1–3, architect entries 1–8,
  build prompt, spec, untracked plan). Worktree re-verified CLEAN at
  `5dcfaa6` by this architect session before dispatch (zero diff, five
  commits over `54ec315, only the untracked `.pi/`).
- Scope of the remainder is the AVD tail plus the report: door reads
  Character on device, Character-screen sections on device,
  remembered-node screenshot + greyscale variant into
  `docs/reports/shots/m3-fixes/, then BUILD-REPORT.md and the done
  notice as worker entry 4. Bound extras: the worker re-derives the
  three suite counts and four band lines itself once before reporting
  (own numbers, never inherited); the mutation table is NOT re-run
  (D67 accepted it); a reinstall, if ever needed, re-runs the full
  save-aside ritual.
- The architect session changed harness at the same pause (pi → Claude
  Code; change announced as architect entry 7, watch restarted). The
  mailbox protocol is unchanged — the channel is the directory, not a
  session address.

### D69 — 2026-09-01 — M3F verified and accepted at `5dcfaa6`; the third worker session closed the unit; PR flow awaits the user

- The Claude Code replacement worker (D68) returned its done notice as
  worker entry 4 within the hour: AVD tail done, BUILD-REPORT.md
  written, counts and bands re-derived on its own account, nothing held.
- **Architect verification, own instruments, all passed:**
  - Three suites re-run from my own `--file-reporter=json` result
    files: 762 core + 533 content + 515 app = **1810 green, zero
    failures**, +20 over the 1790 baseline.
  - All four band lines extracted from my own run's print events,
    byte-identical to the D62 baseline.
  - Two mutation rows re-run via my own sed on committed code, tree
    reverted and verified clean after each: **M4** (`mana → 0`)
    reddened R2 only, town_bloc 106 green — exact match; **M6**
    (node-branch remembered opacity → `0.0`) reddened R5b only —
    exact match.
  - Diff read at hunk level, all 11 files; the D65-B ordering verified
    at commit level (1920a86 lifts the loops verbatim, be428a1 quotes
    C2 passing, 05a2296 changes only the node branch).
  - `dart analyze .` and `dart format --set-exit-if-changed .` from the
    worktree root: clean, 0 of 200 changed.
  - AVD evidence read with my own eyes: the remembered/visible node
    pair (02a/04a) shows the same `"` glyph at the same cell, faded vs
    full; 06 shows the Character door in the Stonebridge list; 08/09
    show every section; 03a still reads in greyscale by glyph alone;
    01 confirmed to be a Crypt frame, exactly as the worker's own
    record correction states.
- **Instrument note, mine:** my first M6 attempt mutated the shared
  `rememberedOpacity` constant instead of the node-branch use — that
  variant reddens C2's literal `0.4` pin and leaves R5b green (R5b
  asserts symbolically). The spec's M6 means the node branch ("where
  the fix paints it"), so the worker's named set is correct for the
  spec's row; the accidental variant proves the constant drift is
  separately pinned by C2. Layered coverage, no hole.
- Two report findings ratified: the `01-town-doors.png` mislabel
  (S3's own record correction — the file is a dungeon frame; the door
  evidence is 06) and the skills-row crowding on a 360-wide phone
  (`Blacksmith0`), filed as follow-up 31 for the HUD+cast unit.
- Unit ACCEPTED. Worker acked and stood down (architect entry 9); the
  worker's farewell (entry 5) retired its watch and left a spare
  byte-exact device-save copy at `docs/reports/m3-fixes-avd-saves/`
  (gitignored, deletable at will).
- **PR #13 opened on the user's word** ("open PR and journal this"):
  branch pushed, PR created via `tea pr create` from the MAIN repo
  root, no conflicts —
  https://git.fiatcode.dev/fiatcode/residuum-rpg/pulls/13. Awaiting
  the user's squash-merge, then post-merge verification and close-out.

### D70 — 2026-09-01 — M3F merged as `8168861` via PR #13; story closed; the playtest's wounds are healed

- User squash-merged PR #13 as `8168861` "fix: M3F Fixes — the road
  carries your magic, the map keeps its veins (#13)". Post-merge
  verification on `main, architect's own runs: 762 core + 533 content
  + 515 app = **1810 green, zero failures**; all four band lines
  byte-identical to the D62 baseline; `git diff 5dcfaa6 main` EMPTY —
  the squash content is exactly the verified branch head.
- Close-out, in order: the worktree's gitignored shots mirror (four
  unique S2-era captures, not duplicates of the numbered set) copied
  to `docs/reports/shots/m3-fixes/worktree-mirror/` BEFORE removal —
  the M3C loss lesson applied; mailbox folded chronologically (14
  entries, 9 architect + 5 worker) into `m3-fixes-handoff.md`
  (CLOSED); BUILD-REPORT moved to `m3-fixes-build-report.md`; the
  mailbox directory removed; worktree and local branch removed; remote
  branch already deleted by the merge; the standing watch stopped
  (unit closed, no channel to watch).
- The worker's spare device-save copy
  (`docs/reports/m3-fixes-avd-saves/`) is left in place — the user
  may delete it at will.
- Next per D63: the **HUD+cast design unit** (own brainstorm, real
  visual forks, greyscale binds, follow-ups 30 + 31 ride), then
  **m3-quests (M3Q, save v4)** — the last M3 unit. The M3M
  casting-feel and M3C gathering-pace verdicts re-open after the
  HUD+cast playtest.

### D71 — 2026-09-02 — Hard turn: the HUD+cast unit is parked; the next unit is the battle mechanism overhaul, designed as a view over the map fight

- The user parked the HUD+cast design unit mid-brainstorm (its forks stay
  locked and ride the battle unit's UI: the spell dock grammar becomes the
  battle skill bar; the crawl-HUD half stays deferred with follow-ups
  30/31). The new direction: **"battle mechanism overhaul — turn-based
  battle in a different screen"**, the user's words, worked through in
  brainstorm prose with the architect.
- **The model, as locked in discussion (rulings recorded, spec pending):**
  1. The battle screen is a **view over the existing map simulation**, not
     a separate encounter sim. Monsters keep map positions; the flow field
     keeps running; far monsters spend their turns walking closer while the
     fight runs (turn-advance, not real time — user confirmed). Corridor
     blocking is emergent map geometry, no new rule.
  2. **Stage membership = reach on the hero.** Adjacent monsters (melee
     reach) and, when they arrive, ranged monsters within line of sight are
     on stage; everyone in transit shows in the turn strip as arrivals with
     a turn count. The turn strip names the next actor (user: "an indicator
     showing which actor will be acting").
  3. **Openings:** the hero opens by default; an **ambush** (monster
     adjacent, or a ranged monster that had line of sight) grants the
     monster the first turn on the fresh clock — a turn, never a free hit.
     Player stealth-ambush with a critical first hit is explicitly future
     work (user, verbatim intent recorded).
  4. **Flee = walk away.** The battle view closes when nothing is adjacent;
     the chase plays on the crawl view. No flee action, no cooldown; road
     fights fold in unchanged (same system, edge-flee intact).
  5. **Turn order:** the energy clock ports (fast actors act more often);
     a battle opens on a fresh clock, per the stairs-arrival precedent.
  6. **Suspending mid-battle needs nothing new** — battle state IS map
     state; the suspend theorem survives; save v3 likely stands.
  7. **Spells survive:** banish becomes "drive it off the stage and it
     walks back" (newly meaningful); bolt gains explicit tap targeting;
     bind holds turns unchanged.
- Consequences recorded: bands move only as far as the rulings move them
  (the ambush opening is the known mover); the bot survives because it
  plays actions, not screens; the re-baseline trail is bounded. This unit
  will supersede the on-map-combat chapters of the design spec at spec
  time (D27/D28 supersession precedent).
- Open at record time: hero ranged reach (architect proposal: LoS —
  stage plus in-transit arrivals, so archery thins the pack before it
  closes); whether this unit ships one ranged monster to prove the stage
  rule or the rules only (bestiary ruling either way); the monster
  exclusive-skills intent (follow-up 32) shapes the bestiary unit after.

### D72 — 2026-09-02 — Battle overhaul: ranged reach ruled LoS; the unit ships one proof monster (a spitter)

- **Hero ranged reach = line of sight**, stage or strip: ranged attacks and
  long spells may target anything the hero can see — on-stage combatants and
  in-transit walkers alike. Melee stays adjacent-only. Rationale locked: an
  enemy spitter that outranges the whole game is unfair by construction, and
  thinning the pack before it closes is the honest archery fantasy. The turn
  strip doubles as the target list for off-stage targets.
- **The unit ships one ranged monster** to prove the stage rule end to end —
  the architect's lean, accepted by the user ("prove it with a spitter").
  Stats, dungeon placement and drop behavior are the bestiary ruling at spec
  time (tiered lever rule — a ruling is required and is hereby asked); the
  spitter's reach stat exercises stage membership, LoS ambush and the
  strip-as-target-list in one creature.

### D73 — 2026-09-02 — Battle overhaul recon complete: the model is bounded; the unit splits in two; four forks go to the user

- Four read-only recon agents (app/view, core engine, content/bestiary,
  bot/bands) fanned out on `8168861`; the architect re-verified the sharp
  claims at source (LoS grep empty, `encounter_map.dart` ambush doc, `CreatureSpec` fields, `_monsterPhase` adjacency branch, bot `_decide,
  print+assert band pins). Recon document:
  `docs/epic/m3-battle-recon.md`.
- **Verdict:** battle-screen-as-view is buildable without touching the
  engine's center of gravity. One ambush-opening rule (pure clock
  arithmetic — pre-charged monster + pre-hero monster pass, ZERO new named
  draws), explicit target on `CastSpellAction` (nearest-fallback pinned), a
  `reach` field (`CreatureSpec` + `Actor, default 1 preserves every
  existing creature's behavior byte-for-byte) with one ranged branch beside
  the adjacency branch in `_monsterPhase, and a pure LoS-reuse reach test
  (`state.visible` + Chebyshev). The bot survives; bands move only through
  the ambush rule and the spitter; the M3B trail method applies.
- **Proposed split, awaiting the user:** unit A `m3-battle` (core +
  content: ambush, targeting, reach, spitter, band trail, casting-bot
  informational line per follow-up 29), then unit B `m3-battle-ui` (app:
  battle view, stage/strip/skill bar, tap-to-target, widget tests, HUD
  riders 30/31).
- Sharp findings carried: tap-to-target must not silently change crawl-view
  `TileTapped` semantics; `GameViewState` has no adjacency getter (new
  derived state needed); goldens byte-pin run documents so the reach field
  must decode v3 unchanged (default-encode, no version bump — to be argued
  in the spec against the version-freeze doctrine); `hasLength(14),
  reachability, designed-difficulty shallow-exempt set, and
  `dungeon_door_characterization_test.dart` (seed 4242) are the tripwires.

### D74 — 2026-09-02 — Battle overhaul forks locked (user, structured question): two units, modest spitter, v3 stands, casting bot rides

- **Two sequential units** (user-locked): unit A `m3-battle` (core +
  content — ambush opening, explicit cast targeting, the reach field, the
  spitter, the band trail, the casting bot) then unit B `m3-battle-ui`
  (app only: battle view, stage/strip/skill bar, tap-to-target, widget
  tests, parked HUD riders 30/31).
- **Spitter ruling (bestiary, user-approved):** id `spitter, name
  `the spitter, glyph `p` (verified unused), hp 7, attack 2–3, speed 5,
  drop 40, pierce 0, **reach 3**, no resist/vulnerability sets. Crypt d1
  gains weight 1, crypt d2 gains weight 1; counts unchanged. Depths 1–2
  only — outside the designed-difficulty requirement, shallow-exempt set
  untouched.
- **Save:** reach encodes omit-on-default, decodes absent→1; v3 documents
  decode unchanged; golden save documents stay byte-identical (asserted
  control, not hoped). The real version bump waits for follow-up 32 or
  m3-quests.
- **Casting bot in unit A** (follow-up 29): a third `_Build.casting` with a
  Firebolt book in its kit, one informational line beside the four band
  lines, pinned to its measured trail value.
- Spec written: `docs/epic/m3-battle-spec-M3U.md` (unit A). Unit B spec
  follows after A lands. No AVD pass in unit A (headless); the device
  ritual belongs to unit B. Next: user review of the spec, then build
  prompt + dispatch (harness chosen per dispatch).

### D75 — 2026-09-02 — M3U unit A dispatched: spec approved, worktree cut, mailbox open, pi worker chosen

- **The user approved the spec** (`m3-battle-spec-M3U.md`) after a review
  round; during review the user raised the anti-spam constraint for
  follow-up 32 (monsters have no mana today — recorded on the follow-up;
  unit A adds no mana anywhere).
- Worktree `.worktrees/m3-battle` cut at `8168861, branch `m3-battle`
  (created by the architect per convention — D4).
- Build prompt `m3-battle-build-prompt.md` written per the current mailbox
  protocol (watch block before the spec section; channel mechanics verbatim;
  mutation table with both halves; must-not list; evidenced verification
  block; written-plan-first delegation line). Environment traps restated
  verbatim; headless unit — no AVD pass, no device work.
- Mailbox `docs/epic/handoff/m3-battle/` opened; dispatch note appended as
  dispatcher entry 1 (13:39, `date -Is, via the shipped `mailbox` tool).
- **The user chose `pi` as the worker harness** (per-dispatch choice).
  Launch gesture: `cd .worktrees/m3-battle && pi -n m3-battle, then the
  pointer prompt. Creating the session pre-approves its writes — recorded
  per the protocol (D64 precedent).
- The architect's standing watch is RUNNING as bg task `architect-watch`
  (`watch-architect.sh`), restarted at dispatch per the protocol — the
  dispatch is complete with the watch live.

### D76 — 2026-09-02 — M3U worker kickoff: baseline fresh (1810, matches), two non-hold deviations approved; one spec claim corrected

- Worker entry 1: kickoff ack, worktree confirmed, watch running (with a
  harness note — its background runner shell is fish, wrapped in
  `bash -c`). Fresh baseline from own JSON result files: core 762 +
  content 533 + app 515 = 1810 on `8168861, matching the expected shape.
  Characterization proven against unmodified code before any change
  (goldens 6/6, step/target suites 53, a new adjacent-arrival pin as the
  characterization commit).
- **Deviation 1 APPROVED (spec claim corrected):**
  `designed_difficulty_test.dart`'s shallow-exempt set is COMPUTED
  (`_allCreatures().difference(_deepCreatures())`) with the four names as
  an exact-set pin — so adding the spitter to crypt d1/d2 necessarily
  changes the computed set. The spec's "the shallow-exempt set is not
  edited" cannot hold with every commit green. Ruling: the named pin
  becomes `{'rat', 'wolf', 'ghoul', 'crab', 'spitter'}` with the old value
  quoted in the same commit; the mail-bar mechanism is untouched; the
  spec's requested no-depth-≥3 assertion stands. This is the epic's sixth
  architect claim error caught by a worker (recon read the pin as
  hand-named; it is computed).
- **Deviation 2 APPROVED (attribution on the record):** the casting build
  measures the crypt through the `survivabilityKit` door
  (`startDungeonRunAt`) because it is the only kit that can carry a book —
  the greedy bot's `newGame` door cannot. The casting line is therefore
  NOT apples-to-apples with the greedy 20/40 line (different door and
  kit); its dartdoc must say so.
- Worker note accepted: `startRoadEncounter` builds road monsters through
  `creature.spawn(...), so the new `reach` field rides along — the D56
  carry hazard is satisfied by the codec + spawn path, no world.dart edit.
- Worker proceeding: codec → spitter → ambush → ranged → targeting →
  trail. Architect ack sent as dispatcher entry 2.

### D77 — 2026-09-02 — M3U mid-flight hold ruled: the spitter narrows to crypt d1-only; the 0.45 fairness floor does not move

- **Worker HOLD (entry 4), accepted as exactly the right stop:** the
  measured trail put ambush + the ruled spitter below the content suite's
  own guardrail. Trail rows (worker's own runs): ambush alone crypt 19/40
  (47.5%, bands held); spitter content crypt 18/40 (45.0%, on the floor);
  with the ranged branch live crypt 16/40 (40.0%) — below the 0.45 floor.
  Sea-cave 26/40 and keep 24/40 unchanged throughout. Failed rows kept:
  uncharged lunge 11/40; charged lunge ungated by the snapshot 17/40 — the
  adopted lunge gates on newly-created reach (spec goal's own words) and is
  pinned by `step_ambush_test`; row 1 re-measured gate-invariant.
- The ranged branch itself is spec-shaped and pinned (shoot from Chebyshev
  ≤ reach on the hero's turn-start LoS, stand its ground, `_defend`
  verbatim, one draw, lunge pays actCost, unowed in-reach spitter stands
  silent); it sat uncommitted in the working tree while the hold waited —
  the last commit (`f73a2ed`) is green, no red commit exists. Correct per
  the green-commit rule.
- **The user's ruling (structured question): DROP THE D2 WEIGHT** — the
  spitter becomes crypt d1-only (d2 weight 1 → 0); the stat line stands
  exactly as ruled (hp 7, atk 2–3, speed 5, drop 40, pierce 0, reach 3);
  **the 0.45 soft floor does NOT move** — a guardrail is not bent to fit
  content. The "crypt depths 1–2" placement of D72/D74 narrows to d1 by
  the suite's own measurements, recorded here as the supersession.
- Worker to proceed: apply the table change, re-run the trail row, re-pin
  with old values quoted; if the crypt still reads below the floor on the
  worker's own re-measurement, return to the mailbox rather than adjusting
  any other lever.
- Architect note for the record: the spec's prediction ("the trail
  re-pins the bands") is superseded in part — the trail's job this unit
  includes reporting a ruled combination as a failed configuration, which
  it did, and the guardrail did its job.

### D78 — 2026-09-02 — Second M3U hold ruled: the spitter becomes a glass cannon (hp 7 → 4); placement and floor unchanged

- **Worker HOLD (entry 6), again the right stop:** the D77 lever (d2
  weight 1 → 0) measured BACKWARDS — crypt 15/40 (37.5%), harder than with
  the spitter on d2 (16/40), because the surrendered weight rolls back
  onto the ghoul/rat/wolf mix and a trading ghoul costs the melee bot more
  than a slow shooter. Worker reverted the table edit (tree back to
  D72/D74 state: spitter d1+d2 at 16/40, ranged branch green in core,
  784/784), kept the failed configuration as trail row 4, no lever
  touched. Deaths cluster at depth 5 ({1:1, 2:9, 3:6, 4:9, 5:15}) — the
  ambush rule meeting the deep tables, not the spitter.
- **The user's ruling (structured question): GLASS-CANNON SPITTER** —
  hp 7 → 4; everything else stands as ruled (attack 2–3, speed 5,
  dropChance 40, pierce 0, reach 3, crypt d1 AND d2 at weight 1 each; the
  D77 d2-drop stays a failed trail row, not applied). The shooter becomes
  a one-swing kill — a nuisance, not an attrition engine — while every
  mechanic it proves (LoS ambush, reach shots, stage membership) stays
  fully intact. The 0.45 floor does not move; the guardrail held.
- Rationale on the record: the spec's own intent was a spitter that proves
  the mechanics "without wrecking the shallow game" — 40% on the tutorial
  dungeon failed that test by the epic's own definition. hp is the one
  stat the trail had not measured, and a one-swing shooter recovers the
  ranged-branch cost while keeping the d1–d2 presence.
- Worker to proceed: stat change as the next trail row, re-measure all
  lines, re-pin with old values quoted. If the crypt STILL reads below the
  floor, stop and report numbers — remaining levers after this ruling are
  reach, weight, or floor, in that order of architectural preference.

### D79 — 2026-09-02 — Third M3U hold ruled: the crypt's soft floor moves to 0.40; the spitter stands as D78 ruled it

- **Worker HOLD (entry 8), with the decisive measurement:** the hp lever
  moved the crypt number ZERO (16/40 at hp 7 and at hp 4 — the bot kills
  the shooter in one or two swings either way; the cost is the ambush
  openings and lunges, not the shooter's resilience). The architect's
  stated next lever (reach 3 → 2) was measured as a disclosed experiment:
  crypt 18/40 — exactly 45.0%, on the boundary, one seed from red. Row
  kept as a kept-failure experiment, tree reverted to D78 as written.
  Sea-cave 26/40 and keep 24/40 unchanged throughout. Last commit
  `f73a2ed` green; core 784/784 with the ranged branch in the working
  tree.
- **The user's ruling (structured question): CRYPT-SPECIFIC FLOOR 0.40.**
  The spitter stands exactly as D78 ruled (hp 4, attack 2–3, speed 5,
  drop 40, pierce 0, reach 3, crypt d1 AND d2 weight 1 each); the crypt's
  soft floor moves 0.45 → 0.40 (crypt only — sea-cave and keep keep 0.45);
  exact pins become crypt 16/40 with its measured death histogram,
  re-pinned by hand with old values quoted.
- Rationale on the record: the crypt's drop is mostly the ambush rule's
  own deliberate weight (D71: "the chase gets teeth"); three content
  levers measured insufficient or backwards (d2-drop harder, hp no-op,
  reach-2 a boundary coin flip); a guardrail that one seed can violate is
  not a guardrail. The global floor keeps its teeth everywhere else. The
  architect recommended against a floor move twice and reversed on the
  third measurement — the reversal is the data's, not the doctrine's.
- Worker to proceed: the floor change and exact re-pins as the final
  trail row; then commit the ranged branch; then targeting → trail
  completion → verification block.

### D80 — 2026-09-02 — M3U unit A verified and ACCEPTED at `25b2e38`; PR flow awaits the user

- **Architect verification, own instruments, all passed:**
  - Three suites re-run from my own JSON result files (the first bg run
    died to the fish-shell `$?` trap — same one the worker hit at kickoff;
    re-launched `bash -c`-wrapped): core 793 + content 541 + app 515 =
    **1849 green, zero failures**, +39 over the fresh 1810 baseline.
  - All five band lines verbatim from my own run: crypt 16/40 (40.0%,
    floor 0.40 per D79), casting 40/40, greedy 16 / fleetfoot 13,
    sea-cave 26/40, keep 24/40.
  - Two mutation rows re-run by my own sed: M1's lunge gate (`true ||`)
    reddened exactly the gate-pinning test; M6 (reach 3 → 1) reddened
    only content_validation's spitter stat pin — and the report's
    structural explanation held (core shoot tests use fixture Actors;
    core cannot import content; layered coverage, not a hole).
  - Diff read at hunk level, all 16 files; ambush arithmetic (snapshot
    gate, charged actCost, pending-turn removal), codec omit-on-default,
    targeting refusal order, floor change and every re-pinned value
    verified against D76–D79.
  - Two findings sent back to the worker (rule 14, asked before
    recording): the stale "seven hit points" dartdoc, and the reach pin
    covering five of fourteen creatures under an overstated comment.
    Worker (still alive, entry 11) fixed both in `25b2e38`; re-verified
    content 541 green + analyze/format clean myself; the pin now covers
    all fifteen creatures by id with an honest comment.
- **Unit A ACCEPTED at `25b2e38`** (9 commits over `8168861`). The trail
  (seven rows, every failed configuration kept) and the mutation table
  (six rows, both halves, plus the two pins the table demanded in
  `a84e096`) are the unit's artifacts. Casting line 40/40 pinned with the
  not-apples-to-apples dartdoc (follow-up 29 answered).
- Spec claims the worker found wrong or imprecise (ratified): the
  shallow-exempt set is computed (D76); two gathering digests carried
  rosters and moved with the tables (re-pinned, not enumerated by the
  spec); asymmetric sight in the shadowcaster is real (40 one-way pairs
  probed) and the pinned test errs hero-safe — bounded, documented, not
  fixed; the spec's band prediction was too optimistic (D77–D79 tell it).
- Next: PR flow on the user's approval (push + `tea pr create` from the
  main repo root), then unit B (`m3-battle-ui`) recon and spec.

### D81 — 2026-09-02 — M3U unit A: PR #14 opened on the user's approval

- Branch `m3-battle` pushed; PR created via `tea pr create` from the main
  repo root, no conflicts — https://git.fiatcode.dev/fiatcode/residuum-rpg/pulls/14.
  Awaiting the user's review and squash-merge in the Forgejo UI; then
  post-merge verification on `main` (own suites + band lines), worktree
  and branch cleanup, mailbox fold, merge decision recorded.
- Worker session may be closed by the user; the mailbox carries the record
  (REPORT.md updated with `25b2e38`).

### D82 — 2026-09-02 — M3U unit A merged as `d576d1c` via PR #14; story closed; the ambush has teeth

- User squash-merged PR #14 as `d576d1c` "feat: M3U Battle unit A — the
  ambush opening, explicit cast targets, and a creature that shoots
  (#14)". Post-merge verification on `main, architect's own runs: 793 +
  541 + 515 = **1849 green, zero failures**; all five band lines
  byte-identical to the verified branch head (crypt 16/40 on the 0.40
  floor, casting 40/40, greedy 16 / fleetfoot 13, sea-cave 26, keep 24);
  `git diff 25b2e38 main` EMPTY — the squash content is exactly the
  verified head. Remote branch already deleted by the merge.
- Close-out, in order: no worktree mirror needed (headless unit, no
  shots; the plan file lives in the main repo's `docs/plans/`); mailbox
  folded chronologically (17 entries, 6 dispatcher + 11 worker) into
  `m3-battle-handoff.md` (CLOSED); REPORT moved to
  `m3-battle-build-report.md`; mailbox directory removed; worktree and
  local branch removed (the branch needed `-D` — squash merges are
  invisible to merge-base; content verified identical on `main` first);
  remote branch already deleted by the merge; the standing watch stopped
  (kill confirmed, unit closed, no channel to watch).
- The band story of record: the crypt is now a 40%-crawl for the melee
  bot BY RULING (D79), with every failed lever on the trail record;
  casting answers at 40/40 through the kit door. The battle's rules now
  exist; unit B gives them their screen.
- Next per D63-as-superseded and D71: **unit B `m3-battle-ui`** — recon
  and spec for the battle screen (stage, strip, skill bar, tap-to-target,
  widget tests, parked HUD riders 30/31). m3-quests (M3Q, save v4)
  follows. The M3M casting-feel and M3C gathering-pace verdicts re-open
  after unit B's playtest.

### D83 — 2026-09-02 — Unit B recon complete: no core changes needed; forks locked (ranged verb + ambush beat; riders 30/31 ride)

- Two read-only recon agents (view-state/bloc, renderer/layout) on
  `d576d1c`; sharp claims re-verified at source. Recon document:
  `docs/epic/m3-battle-ui-recon.md`.
- **Verdict:** the battle screen needs NO core changes — "holds reach",
  stage membership, up-next and turns-to-arrival are all derivable from
  public state (`scheduleMonsterTurns` and `computeFlowField` are
  exported; the strip uses the engine's own call, so they agree by
  construction). The open/close rule is a pure getter (the `hasFled`
  precedent keeps view facts off `GameState`). Real work is app-side:
  derived state, the gesture model, the layout, the drifted
  `castRefusal` mirror (now real — it predates the target branch), and
  the spell-row extraction (fourth copy forbidden; three private copies
  already ship).
- **Forks locked (user, structured question):** (1) log flavor — reach > 1
  monsters get a RANGED VERB instead of the generic "claws", PLUS an
  ambush beat sentence when a monster's opening swing opens the fight;
  (2) riders — follow-up 31 (skills-row crowding) and follow-up 30
  (status line on a phone, via the mandatory AVD pass) both ride.
- Battle view layout is NOT a fork: the user's original sketch (enemies
  on stage at top, battle UI at bottom, different screen while the fight
  runs) is the D71-locked model; the crawl view returns when nothing
  holds reach; the Pack stays reachable (reading is never gated).

### D84 — 2026-09-02 — M3U unit B spec approved; dispatched as `m3-battle-ui`

- The user approved `m3-battle-ui-spec-M3U.md` after review.
- Worktree `.worktrees/m3-battle-ui` cut at `d576d1c, branch
  `m3-battle-ui` (architect-created per convention).
- Build prompt `m3-battle-ui-build-prompt.md` written: watch block before
  the spec section, channel mechanics verbatim, mutation table (6 rows,
  both halves), must-not list (AVD now IN scope with the full save-aside
  ritual), evidenced verification block, written-plan-first delegation.
- Mailbox `docs/epic/handoff/m3-battle-ui/` opened; dispatch note as
  dispatcher entry 1. Standing watch restarted at dispatch.

### D85 — 2026-09-02 — M3U unit B: PR flow for unit A closed; pi chosen for unit B's worker

- The user squash-merged PR #14 as `d576d1c` (D82) and approved unit B's
  spec; unit B dispatched to a **pi** worker (per-dispatch choice).
  Launch gesture: `cd .worktrees/m3-battle-ui && pi -n m3-battle-ui, then
  the pointer prompt. Creating the session pre-approves its writes
  (D64 precedent).
- The architect's standing watch is RUNNING as bg task `architect-watch`
  — the dispatch is complete with the watch live.
- Playtest after unit B (user, 2026-09-02); the M3M casting-feel and M3C
  gathering-pace verdicts re-open at that playtest.

### D86 — 2026-09-02 — M3U-B worker kickoff: adversarial pass; arrivals formula ruled (ceil(distance × heroSpeed ÷ monsterSpeed)); five pre-declarations approved

- Worker entry 1: clean kickoff, fresh baseline 1849 matching the shape,
  watch alive (fish trap caught and verified on its own).
- Worker entry 2: the adversarial pass. **HOLD ruled (the seventh
  architect claim error caught by a worker, this one the spec's):** the
  spec's arrivals formula (flow distance ÷ speed, rounded up) is
  clock-wrong — the recon's × was wrong too. Adopted: **ceil(distance ×
  heroSpeed ÷ monsterSpeed)**, reducing to plain distance at equal
  speeds; every actor moves one tile per own turn and a monster's turns
  arrive every `heroSpeed / speed` hero actions. The worker measured the
  consequence (a speed-10 monster five tiles out would read "1 turn")
  and held rather than build the wrong instrument.
- Five pre-declarations APPROVED (all non-holds, proceeding):
  1. `upNext` passes `heroEnergy: hero.energy − actCost` — the engine's
     phase schedules on the POST-spend hero; a settled state's hero
     energy is always ≥ threshold, so the un-spent call returns an empty
     schedule every time. The spec's "the exact call the engine's phase
     makes", made precise.
  2. Strip divergence documented: an opening triggered by the hero's own
     move is invisible to any schedule over the current state; the strip
     stays a forward view; the boundary pinned by a fixture test.
  3. Armed-skill reset enumerated per handler: survives the
     same-state emitters (pan, back-press, watched-refusal, walk-start,
     stop-walking), resets via constructor-drop on every new game state
     (the M3 mutation's attack surface).
  4. Ambush beat: AttackHit OR AttackDodged with a non-hero attacker and
     the hero as target; one beat per step; the beat is a preamble before
     the first monster-attack sentence, not a trailing aside; two
     accepted stateless mis-reads documented (hero-closed openings,
     re-caught chases) rather than a stateful flag; the hero's own
     bump-attack never fires it (start-state snapshot rule).
  5. The extraction: TWO widget copies (pack, character), not three —
     the recon's second character_screen hit is a sentence, not a row;
     the shared piece takes styles/optionality as parameters so both
     call sites render byte-identically; the battle skill bar consumes
     the shared facts, not the row widget.
- Worker proceeding; the arrivals formula is D86-ruled and binding.

### D87 — 2026-09-02 — M3U unit B verified and ACCEPTED at `27fa659`; PR flow awaits the user

- **Architect verification, own instruments, all passed:**
  - Three suites re-run from my own JSON result files: core 793 + content
    541 + app 560 = **1894 green, zero failures** (+45 app tests, each
    accounted; core/content byte-unchanged).
  - All five band lines verbatim from my own run — byte-identical
    controls, as the app-only scope demanded.
  - Two mutation rows re-run by my own sed: M2 (reach branch killed in
    `_holdsReachIn`) reddened exactly the worker's 6 named tests; M5
    (ranged verb killed) reddened exactly 1. My first M2 sed mis-aimed at
    the verb's adjacency filter (one red, the verb test) — caught by
    matching the row's definition, reverted, re-aimed; the D69 lesson
    applied in both directions.
  - Diff read at hunk level, all 11 files; shots read with my own eyes:
    shot-01 (stage, strip, bar, status line at phone surface),
    grey-shot-01 (marking legible by glyph alone — hue is decoration,
    never the carrier), shot-06 (the beat as preamble on device, the
    hero-closed case reading true).
  - Save ritual verified in the report: both slots' md5s quoted before
    install and after restore, matching; storage trap resolved per
    ritual; `flutter install` never used.
- **One refinement ratified:** the ranged verb fires only when the blow
  is delivered from outside arm's length — a reach monster standing
  adjacent claws. Better physics than the spec's letter ("reach > 1"),
  documented in the dartdoc, within the D83 fork's spirit.
- **Unit B ACCEPTED at `27fa659`** (8 commits over `d576d1c`). Riders 30
  and 31 closed (30 on-device in shot-01; 31 pinned by
  `skills_row_spacing_test.dart` at the phone surface). The report's
  honest limits recorded: the dodged-beat branch pinned only by the hit
  path; the strip's forward-view boundary; the deuteranomalous author's
  eye is the final greyscale authority — the playtest reads the shots.
- Next: PR flow on the user's word; then the user's playtest, where the
  M3M casting-feel and M3C gathering-pace verdicts re-open.

### D88 — 2026-09-02 — M3U unit B: PR #15 opened on the user's approval

- Branch `m3-battle-ui` pushed; PR created via `tea pr create` from the
  main repo root, no conflicts — https://git.fiatcode.dev/fiatcode/residuum-rpg/pulls/15.
  Awaiting the user's review and squash-merge; then post-merge
  verification on `main, cleanup (worktree, branch, mailbox fold, watch
  stop), merge decision recorded.
- The worker session may be closed by the user; the mailbox and REPORT.md
  carry the record.

### D89 — 2026-09-02 — M3U unit B merged as `fda107f` via PR #15; the battle overhaul story is COMPLETE

- User squash-merged PR #15 as `fda107f` "feat: M3U Battle unit B — the
  battle screen: stage, turn strip, skill bar, tap-to-target (#15)".
  Post-merge verification on `main, architect's own runs: 793 + 541 +
  560 = **1894 green, zero failures**; all five band lines byte-identical
  to the verified branch head; `git diff 27fa659 main` EMPTY. Remote
  branch already deleted by the merge.
- Close-out, in order: no worktree mirror needed (the shots went straight
  to the main repo's `docs/reports/shots/m3-battle-ui/`); mailbox folded
  (8 entries) into `m3-battle-ui-handoff.md` (CLOSED), REPORT mirrored as
  `m3-battle-ui-build-report.md`; BOTH channel directories removed — the
  first attempt failed silently to the sandbox EROFS trap, retried with
  errors visible (a fold-check caught that unit A's `handoff/m3-battle`
  directory had also survived its close-out; both cleaned now, `handoff/`
  directory retired); worktree and local branch removed (`-D, squash
  invisible to merge-base, content verified identical first); the
  standing watch stopped (kill confirmed).
- **The battle overhaul story (M3U) is COMPLETE**: unit A gave the fight
  its rules (ambush openings, explicit targets, reach, the spitter),
  unit B gave it its screen (stage, strip, skill bar, tap-to-target).
  Fourteen commits across two units, 1894 tests, every failed lever on
  the trail record. Riders 30 and 31 closed.
- **NEXT: the user's playtest** — on the emulator or a real phone. The
  verdicts that re-open: the M3M casting-feel question (now answered by
  the skill bar), the M3C gathering-pace question, and the battle
  screen's own first verdict — including the greyscale shots, where the
  deuteranomalous author's eye is the final authority (the report says
  so itself).
- After the playtest: verdicts recorded, then m3-quests (M3Q, save v4,
  per-unit sanctioned) — the last M3 unit.

### D90 — 2026-09-02 — First post-battle playtest verdicts recorded; a device-found trap in unit B; the fight/map fork opens

- **The user playtested** (first session after the battle overhaul merged).
  Verdicts, from the journal plus the architect's recon:
  - **Gathering (M3C re-open): ENDORSED for now.** "Ores and herbs is on
    the map and I can collect them" — no pace complaint. The M3C
    re-open question is answered provisionally positive; revisit only if
    a later playtest complains.
  - **Potion feel (new balance verdict): too weak.** "Potion now only
    heals 10? I think it'll be too hard even in first dungeon, first
    floor." Recon: `healingPotion` heal 10 (`armory.dart:129-133`)
    UNCHANGED since M2L — nothing shipped moved it. What changed is the
    fight around it (ambush teeth ruled deliberate in D71/D79). The
    feeling is real; the cause is the company the potion keeps.
  - **Spitter standoff: STUCK — a real defect, the TENTH device-only
    catch.** The user could not defeat or escape a spitter. Root cause
    chain (architect recon, all verified in code): (1) a spitter holds
    reach at Chebyshev ≤3 through the hero's FOV, so `isBattleOpen`
    stays true and the battle view REPLACES the map
    (`game_screen.dart:51-68`); (2) the spitter AI never retreats — while
    it holds reach it stands and shoots (`step.dart:665-675`), so it
    never walks adjacent; (3) in the battle view the ONLY tappable thing
    is the spitter's stage card, which fires `TileTapped(spitter.position)`;
    (4) `_onTileTapped` (`game_bloc.dart:516`) returns a silent no-op:
    `directionTo` is null beyond one step, and the monster's own tile is
    not walkable. The RULES allow closing (two hero moves to adjacency,
    one swing kills at hp 4) — the UI removes every door. Unit B's widget
    tests never caught it: nothing tested the view with its only
    reach-holder beyond one step.
  - **The user's fork proposal: combine the fight and map screens** —
    "get the best of both." The architect endorses the instinct: D71's
    own design language says battle is "a VIEW over the map fight", and
    unit B interpreted "view" as a full swap. The swap is what builds
    the trap.
- **M3M casting feel: no verdict yet** (the playtest hero knew no
  spells). Greyscale shots: not yet seen by the author. Both stay open.
- **Next: brainstorm the fight/map fork with the user** (this session,
  structured question), then a small fix unit rides the verdict — before
  m3-quests. D59 doctrine stands: never declare "the last break".

### D91 — 2026-09-02 — Locked: the battle view docks over the map; the potion stands at 10

- **The user ruled (structured question): DOCK OVER MAP.** The map is
  always visible. The battle pieces — stage cards, turn strip, skill
  bar — dock over it as panels. Tapping the map walks as before; tapping
  a stage card targets as before; the battle "closes" when nothing
  holds reach and the panels disappear. This restores D71's own design
  language ("battle is a VIEW over the map fight") and kills the D90
  trap by construction: there is always a door, because there is always
  a map to walk on.
- **Potion: LEAVE AT 10.** The user chose to treat "too hard on floor
  one" as the ambush teeth being felt; re-judge difficulty after the
  dock unit ships. `healingPotion` heal 10 is unchanged (it never moved;
  D90 recon). If a later playtest still reads too hard, the potion is a
  free content lever with a trail row and a band re-measure.
- **The fix unit is `m3-dock`** — small, app-side, before m3-quests.
  It also carries the still-open verdicts: fresh greyscale shots of the
  dock layout for the author's eye, and a casting-feel playtest once it
  ships. M3M and M3C re-opens stay open until then.
- Locked forks for the spec: map always visible during battle (no full
  swap, ever); stage cards + turn strip dock at the top of the map slot;
  skill bar docks at the bottom; stage-card tap keeps the D89 grammar
  (tap arms/casts at a named target, never at a guess); the ambush beat,
  arrivals strip and dock grammar are untouched; the spitter standoff
  fix is the map's visibility itself — no new approach verb, no AI
  change, no trigger narrowing (D71's ambush-first-turn rule stands).

### D92 — 2026-09-02 — m3-dock: the worker corrects D90's step 5 — the far card tap is a lying refusal, not silence; two deviations approved

- **Worker's measured correction (pre-code, entry 2):** the spec and
  recon claimed a far stage-card tap is a SILENT no-op because a
  monster's tile is not walkable. `FloorMap.isWalkable`
  (`floor_map.dart:71-72`) is terrain-only — a monster stands on floor.
  Measured against unmodified `fda107f` with a real GameBloc: the far
  tap reaches the `enemiesInSight > 0` branch and emits the
  watched-refusal "Something is watching. You stay put." — a state
  change, repeated forever, naming no monster, and actively advising
  the player to STAY PUT while the correct move is to walk in. The D90
  trap is worse than recorded: not a dead door, a lying one.
- **Architect root cause of the miss, on the record:** the recon
  verified `directionTo` at source but INHERITED the isWalkable
  premise from the read-only recon agent without re-checking it —
  doctrine rule 7, the exact failure mode the rule names. The worker's
  measurement supersedes (D67 lineage).
- **Ratified:** C2 is re-pinned to the measured behaviour (hero stays,
  no blow, the log gains exactly the watched-refusal line); T3 retires
  that sentence for far card taps as the spec intended — the intent is
  unchanged, only the "before" picture was wrong.
- **Deviation 1 APPROVED:** `game_bloc.dart` gains one app-side event
  (`StageCardTapped, carrying the monster) whose handler appends the
  guidance sentence — the log is bloc state; a widget cannot write it.
  No core change.
- **Deviation 2 APPROVED:** no new file — `battle_view.dart` keeps the
  dock widgets (`BattleView` replaced by a docked header + skill bar);
  `game_screen.dart` owns row placement.
- Baseline fresh in the worktree: core 793 + content 541 + app 560,
  all pass; analyze clean. Worker cleared to proceed on the amended
  spec.

### D93 — 2026-09-02 — m3-dock verified and ACCEPTED at `8cc5316`; PR flow awaits the user

- **Architect verification, own instruments, all passed:**
  - Suites re-run from my own JSON result files: core 793 + content 541
    + app 563 = **1897 green, zero failures**, against the fresh
    `fda107f` baseline (793/541/560) the worker measured.
  - All five band lines verbatim from my own run of
    `survivability_test.dart`: crypt 16/40 (40.0%)
    `{1:1, 2:9, 3:8, 4:6, 5:16}`; casting 40/40; greedy 16 /
    fleetfoot-first 13; sea-cave 26/40; keep 24/40 — byte-identical to
    the D79/D89 pins. `git diff main -- packages/core packages/content`
    EMPTY (confirmed twice).
  - Mutation row re-run by my own sed: M3 exactly as defined reddened
    exactly {T3}, 14 green; reverted, tree clean.
  - `dart analyze .` from the worktree root (pwd quoted): no issues;
    format 0 changed; `git branch -r` holds no m3-dock — nothing
    pushed. Diff read at hunk level, all four files; drive shots read
    (dock over live map, the walk, the guidance sentence naming the
    spitter).
- **One finding sent back and fixed:** an orphaned duplicate of
  `_outOfReach`'s dartdoc in `game_bloc.dart` (a rebase artifact of the
  worker's two-part edit) — fixed in `8cc5316` (7 deletions,
  comment-only), re-verified by my own runs: analyze clean, format
  clean, app suite 563/0 from my own result file.
- **Worker's D92 findings ratified in the report:** C2's original
  silent-no-op claim failed against unmodified code exactly as D92
  records; the D89 armed-cast test was rewritten to the adjacent card
  (under contract 4 a far card is the walk sentence), preserving the
  named-target nuance with two holders on stage.
- **AVD pass honoured in full:** save slots copied aside and restored
  byte-identical (md5s match the battle-ui records); the drive ran on a
  temporary acceptance save; 8 shots with greyscale variants in the main
  repo's `docs/reports/shots/m3-dock/`. The measured fight cost on
  device: two moves, one shot taken for 2, one swing for 5 — a balance
  verdict for the user's next playtest.
- **New hazard for the record:** the actor codec REQUIRES `resists` in
  a hand-built monster document — a hand-staged acceptance save without
  it is refused whole and the app falls back to the older slot (by
  design; the codec never repairs). Anyone hand-staging a save must
  include `resists`.
- **Unit m3-dock (story M3V) is COMPLETE at `8cc5316`** — 7 commits over
  `fda107f, tree clean. NEXT: PR flow on the user's approval (push +
  `tea pr create` from the MAIN repo root), then post-merge verify,
  mailbox fold, and the user's next playtest — which also carries the
  still-open M3M casting-feel verdict and the greyscale shots' author
  eye.

### D94 — 2026-09-02 — m3-dock: PR #16 opened on the user's approval

- Branch `m3-dock` pushed; PR created via `tea pr create` from the main
  repo root (forgejo skill), no conflicts —
  https://git.fiatcode.dev/fiatcode/residuum-rpg/pulls/16.
  Awaiting the user's review and squash-merge in the Forgejo UI; then
  post-merge verification on `main` (own suites + band lines), worktree
  and branch cleanup, mailbox fold, merge decision recorded.
- The worker session may be closed by the user; the mailbox carries the
  record (REPORT.md amended at head `8cc5316`).

### D95 — 2026-09-03 — m3-dock merged as `b675d33` via PR #16; story M3V closed

- User squash-merged PR #16 as `b675d33` "feat: M3V m3-dock — the
  battle dock: the map never leaves the screen during a fight (#16)".
  Post-merge verification on `main, architect's own runs: core 793 +
  content 541 + app 563 = **1897 green, zero failures**; all five band
  lines byte-identical from my own run (crypt 16/40 on the 0.40 floor,
  casting 40/40, greedy 16 / fleetfoot 13, sea-cave 26/40, keep 24/40);
  `git diff 8cc5316 main` EMPTY — the squash content is exactly the
  verified head. Remote branch deleted by the merge.
- Close-out, in order: mailbox folded chronologically (10 entries) into
  `m3-dock-handoff.md` (CLOSED), REPORT mirrored as
  `m3-dock-build-report.md`; channel directory removed — the first
  `rmdir` failed on the watch's stamp file, the fold-check caught it and
  the removal completed (`handoff/` directory retired again);
  worktree removed (`--force`; only the harness's untracked `.pi/`
  inside), local branch `-D` after content identity was proven; the
  standing watch killed (kill confirmed by process list, after the
  worker had reported its own watch killed externally overnight).
- The user killed the worker session after the fix commit; the mailbox
  carried the record throughout (worker entry 7 disclosed the external
  watch kill rather than guessing — protocol held).
- **Story M3V (the dock fix) is COMPLETE.** The D90 trap is dead: the
  map never leaves the screen during a fight; a far card tap names the
  monster and says walk. The spitter standoff that stalled the
  playtest cannot recur.
- **NEXT: the user's next playtest** — carries the still-open M3M
  casting-feel verdict, the M3C gathering-pace re-check, the dock's
  balance feel (the measured fight: two moves, one shot for 2, one
  swing for 5), and the author's eye on the greyscale shots in
  `docs/reports/shots/m3-dock/`. Then **m3-quests (M3Q, save v4,
  per-unit sanctioned)** — D59 doctrine: never declare "the last
  break".

### D96 — 2026-09-03 — Repo migrated to GitHub; history rewritten; every ledger hash citation stale

- The user moved the repo from git.fiatcode.dev (Forgejo) to **GitHub**:
  `git@github.com:fiatcode-gh/residuum-rpg.git` (ssh), `gh` CLI authenticated
  as `fiatcode-gh` with ADMIN on the repo, `main == origin/main` at
  `a567c19`.
- **The history was rewritten during the migration** (the 2026-09-03
  author-leak purge: commits re-authored to
  `fiatcode <fiatcode@noreply.git.fiatcode.dev>`). EVERY pre-migration hash
  cited anywhere in this ledger or in `ARCHITECT-HANDOFF.md` is stale — the
  merge-base/content-identity discipline still applies, but against the NEW
  hashes only. Old→new mapping for the PR-merge commits the ledger cites:
  PR #1 `472e62b`→`3cb5c3d`, #2 `0656eb1`→`e21f46a`, #3 `f758c3f`→`a2f73d9`,
  #4 `f7bd6b1`→`f430250`, #5 `844376f`→`41ccf75`, #6 `958ef98`→`bd2499c`,
  #8 `59b91f1`→`6544371`, #9 `b9d7c21`→`d969cbf`, #10 `936ca5b`→`7acfb6d`,
  #11 `83b5336`→`823c052`, #12 `54ec315`→`712d5e4`, #13 `8168861`→`6e70375`,
  #14 `d576d1c`→`67dcb9c`, #15 `fda107f`→`194fd29`, #16 `b675d33`→`f2f746d`.
  One post-merge commit rides on top: `a567c19` (docs-only: removes the
  hard-coded `--author` flag from docs/plans; no code touched).
- **Merge flow is unchanged (D22) but the forge is `gh`, not `tea`:** push
  from the main repo root, `gh pr create` on user approval, user
  squash-merges in the GitHub UI, architect verifies content identity
  (`git diff <verified-head> main` EMPTY) before `git branch -D`. The
  forgejo skill is retired for this repo; GitHub repos use `gh` (doctrine).
  The old `tea pr create` worktree trap line in Environment traps is
  superseded by this decision.
- Content spot-check of the rewrite: `main` log matches the ledger's merge
  sequence PR-for-PR; `a567c19` touches only `docs/plans/`; the working
  tree is clean against `origin/main`. **Post-migration suite re-run on the
  rewritten history, the architect's own runs: core 793 + content 541 +
  app 563 = 1897 green, zero failures** — identical to the D95 pre-migration
  counts. The rewrite carried no content change.

### D97 — 2026-09-03 — Playtest #2 verdicts (CLOSED — see the PLAYTEST CLOSED entry at the end of this block and D98 for the wave)

- **V1 (battle screen, first verdict): the dock is hard to see, and
  "N turns out" is unreadable.** Architect confirmed at source
  (`battle_view.dart:153-185`): the turn strip is 12px dim monospace
  floating over the live map, and the arrivals line reads
  "Spitter — 3 turns out" — intended as "3 turns out in the corridor",
  but it parses as the idiom "turns out (that…)". Two defects named:
  wording (a language bug, not the user's miss) and visibility
  (low-contrast overlay on the map). Fix forks under discussion; scope
  to be locked with the user before any unit opens.
- **V1 forks LOCKED (user):** (a) the turn strip is REBUILT into
  turn-order chips — NOW / IN N marked by position and word, not dim
  text; (b) a translucent dark backing panel covers the WHOLE dock
  header (stage cards row included), so every dock string reads over
  any map tile. App-side only, no core/AI/trigger change. The wording
  decision ("arrives in N" vs chip labels) lands with the chip design
  in the unit spec. No unit dispatched yet — more playtest verdicts
  are arriving first.
- **V2 (casting feel, M3M re-open): the user proposes target
  selection** — tap an enemy to select it, highlighted in BOTH map and
  dock, then choose the action (attack, spell) — or the reverse
  (action first, then target; today's order). Architect confirmed at
  source: today there is NO selection state — armed skill + card tap
  casts; bare card tap is the bump-attack; far card tap says walk.
- **V2 forks LOCKED (user), superseding part of D71's dock grammar:**
  (a) **action-first + armed-target highlighting** — arming any action
  highlights its legal targets on stage cards AND the map; tapping a
  highlighted card applies the action. (b) **the regular attack
  becomes a bar action like the spells — two taps, uniform UX** — the
  bump-attack gesture on a bare card tap RETIRES. Ruling details for
  the unit spec: what a bare (nothing-armed) card tap does once the
  bump-attack retires — **RULED (user): enemy info** — a bare card tap
  shows the monster's info (replaces the long-press candidate for
  inspection); the D92 walk-sentence guidance MOVES to the armed path
  — tapping an UNLIT card while an action is armed speaks the walk
  sentence; armed-target marks
  are by outline/marking/word, never hue alone, in map and dock.
  (c) **RULED (user): map tap-to-attack RETIRES — all fights go
  through the dock.** The map stays a movement surface; tapping a
  monster tile with nothing armed no longer attacks. Spec detail: a
  map tap onto a monster tile falls back to the walk-refusal sentence
  (the enemiesInSight branch) rather than silence.
- **V3 (forge, M3C re-open): the temper cost is not written.**
  Architect confirmed at source (`forge_screen.dart:136-143`): the row
  renders `reason ?? price` in one slot, so the price ("Next tier: N
  ingots and X gold") shows ONLY on workable rows — every refused row
  (Blacksmith gate, no ingots, no gold) hides the cost of the tier it
  is pointing at. Real rendering defect; fix shape: the price line
  always renders (with the ceiling case saying so), and the refusal
  word appears separately. No unit dispatched yet.
- **V4 (craft economy, M3C re-open, user proposal): make the forge and
  alchemy shelf FREE, balanced by failure** — tempering loses its
  gold cost (brewing is ALREADY free: 3 herbs, no gold —
  `craft.dart:29`); a temper can fail and lose some of the ingots;
  same for alchemy. Architect endorsement in prose: unifies the
  doctrine (benches trade gathered materials for work), makes skill
  training the balancer instead of the purse. Open rulings: fail-odds
  model, loss amount on failure, xp on failure. Randomness discipline
  binds: state-carried Rng draws, determinism tests re-pinned, salt by
  collision sweep if a new stream, band trail required (bot never
  crafts — expected byte-identical, proven not assumed). Save v3
  untouched (temper counts live on the item).
- **V4 rulings LOCKED (user):** (a) fail odds TIER-BASED,
  LEVEL-SCALED — tier 1: 0% (the teaching tier never fails), tier 2:
  20%, tier 3: 35%; each skill level above the gate subtracts 2%
  (floor 5%). (b) A failed attempt costs EXACTLY ONE material (1
  ingot / 1 brew's herbs), the result is unchanged, retry allowed.
  (c) Failure still grants its skill xp (practice is practice). Spec
  detail flagged: brew has no tiers — its odds mapping (base 20% minus
  2% per Herbcraft level above some gate, floor 5%) settles at spec
  time. The forge's gold-based dartdoc arithmetic and `temperPrices`'
  gold field retire with this — content-table change with a trail per
  the tiered lever rule.
- **V5 (character screen, M3C re-open): "Herbcraft rises to 1" at the
  top of the character screen — bug or intentional?** Architect
  confirmed at source: INTENTIONAL mechanism, poor placement — the
  town notice slot (town_bloc.dart:763, set on any skill-raising
  craft) renders on the character screen (character_screen.dart:52)
  and persists until the next town action overwrites it. Architect
  lean: the notice belongs to the bench that earned it — character
  screen drops the notice bar (skills are already listed in the
  skills row); town screens keep it. **RULED (user): town screens
  only** — the character screen's notice bar retires; the notice slot
  and its town placement stay as designed. Rides the craft-economy
  unit (the failure-xp work touches this same notice path).
- **V6 (UX batch, M3C re-open, user asks): (1) multi-smelt, (2)
  multi-brew, (3) custom gold bank amount, (4) forge worn grouping.**
  1-3: manual numeric input capped at actual resources (ore, herbs,
  gold on each side of the vault). 3 OVERRIDES a written design
  rationale: the bank screen's dartdoc argues for fixed buttons over
  a phone number pad — retired by user ruling. Current shapes at
  source: smelt/brew are one-press operations; bank is
  Bank-10/Bank-all/Take-10/Take-all; forge bench is one merged list
  with a "(worn)" name suffix. **Rulings LOCKED (user):** input shape
  is a STEPPER (− / value / +) plus a MAX button, with tap-and-hold
  auto-repeat on the stepper buttons — no keyboard, cap clamps at
  actual resources; the forge bench splits into WORN STEEL and
  CARRIED STEEL sections and the "(worn)" suffix retires (position
  carries worn-ness, bank's position grammar). Applies to smelt,
  brew, and both sides of the vault gold.
- **V7 (merchant, M3C/M3H re-open): counter for duplicate items** —
  e.g. three healing potions on the shelf render as one stacked row,
  not three. This ACTIVATES standing follow-up 16 ("stacking for
  merchant stock and bank lists — packSections/stackKey are ready for
  them"): the stacking machinery already exists from m2-qol and needs
  zero core work. Architect lean: apply it to all three merchant
  lists (For sale / Sold this visit / Your pack) for one grammar;
  a stacked Buy/Sell tap moves one item per tap. Bank list stacking
  stays open (follow-up 16's other half).
- **V8 (engine, user proposal): a "stand still" action when enemies
  are encountered** — the user wants to hold position instead of being
  forced to move (fight or flee are today's only doors on the road).
  Architect confirmation at source: no wait verb exists anywhere in
  the engine; a turn only advances when the hero moves or acts, and
  the road encounter screen offers Flee / Move on only. **Ruling
  LOCKED (user): a general wait verb, every fight** — road encounter
  row and the crawl alike. Shape: `WaitPressed` passes the hero's turn
  (you stand, the world ticks — ranged monsters shoot a waiting hero,
  by design), no regen, no discount. Spec details: the wait beat's
  log line (candidate "You hold your ground."), crawl surface for the
  control (dock vs controls row), and a fresh look at the
  watched-refusal grammar for consistency.
- **V9 (crawl HUD, user proposal): the battle indicator stops being
  text-only.** Today: the word `Engaged N` appended to the one-string
  status line (game_screen.dart:149), under the D71 no-split ruling —
  this IS that ruling. Architect finding: the line conflates two
  facts — something in SIGHT (ambush risk, walk refused) vs something
  holding REACH (dock open, fight live). **Rulings LOCKED (user):**
  (a) a fixed-size two-state GLYPH cell beside the status string —
  eye for watched, crossed marks for engaged — the string keeping its
  scale-down behavior; (b) watched and engaged become distinguishable
  at a glance ("Engaged" no longer claims fights that have not
  started). Word stays beside the glyph as the greyscale backstop;
  phone-surface overflow test re-pinned. Spec details: exact glyph
  shapes, whether the "Engaged N" count persists for both states,
  dock-interaction wording.
- **V10 (BUG, open): after equipping a two-handed weapon and taking it
  off, a one-handed weapon cannot be equipped.** Architect recon:
  core rules verified clean at source AND by experiment — the exact
  sequence (wear two-hander → take off → equip one-hander) passes in
  core (scratch repro test, run and deleted). Core paths (engine
  step, town equipItem/unequipItem, wear.dart) share one home and
  behave. Remaining suspects: app UI state, save/load path, or an
  unobserved precondition. Awaiting the user's observation: exact
  refusal sentence or dead-button, which screen, whether a
  save/suspend/resume happened between the two steps, where the
  one-hander was (pack vs bank).
- **V10 ROOT CAUSE CONFIRMED (screenshot + source): duplicate item ids
  across delves.** Evidence: the phone's log shows the refused taps —
  four "Healing Potion is not worn." lines before "You put on Fine
  Vicious Maul (main hand)" — the Wear taps reached core and were
  refused NAMING A POTION the user never touched. Mechanism at
  source: drop ids mint `drop-N` from run-scoped `nextDropNumber`,
  which DEFAULTS TO 1 on every new GameState
  (game_state.dart:64; run_boundary.dart:86 passes no value on
  enterDungeon) — while the pack rides the PROFILE and persists
  across delves. Second delve mints fresh `drop-1…N` into a pack that
  may already hold `drop-1…N` from an earlier delve; `_find` matches
  the FIRST, so Wear/Sell/Bank on the newer item act on the older
  one (or refuse). Follow-up 23's "latent while ids stay unique by
  construction" hazard is LIVE — and its destructive half too:
  every-match removal (town `_without`) can silently destroy BOTH
  same-id items on a sell/bank. ALSO EXPOSED: merchant buy-back,
  bank withdraw, and road-fight drops (the road encounter mints
  `drop-N` from its own fresh GameState) — every first-match id
  consumer. Fix direction (needs a ruling): mint ALL item ids from a
  HERO-SCOPED counter on the Profile (the brewNumber precedent —
  never resets, one namespace), with the codec's omit-on-default
  treatment so the v3 goldens hold (D56 lesson verbatim); suspended
  runs resume with max(profile, suspended) to not regress the
  suspend theorem. Fix is CORE + codec — a proper unit, strict TDD.
  USER ADVISORY given: in the current playtest session, avoid
  selling/banking duplicate-suspect items until the fix lands.
  **RULED (user): fix AFTER the playtest verdicts close** (folded into
  the post-playtest wave, not a hotfix unit); the current delve
  CONTINUES with the broken one-hander accepted as known-broken.
- **V10 AMENDMENT (user report: the one-hander may be LOST —
  confirmed mechanism): every id-consuming action removes EVERY
  same-id item.** At source: DrinkAction (step.dart:130-133) heals
  from the first match and deletes all; ReadAction (139) the same;
  DropAction (167-170) drops the first match and deletes all; town
  sell/bank `_without` (town.dart:357) removes all. The user's pack
  went Drink(2)→1 potion between screenshots — a single Drink tap is
  the likely deletion event for the collided sword; unrecoverable
  (the save is unreachable in the non-debuggable build, and the item
  no longer exists in any document). The fix unit therefore carries
  BOTH halves: hero-scoped id mint AND remove-one semantics on every
  id-consuming action (follow-up 23's full retirement).
- **V10 PREDICTION CONFIRMED LIVE (on-device, adb-driven):** after the
  user finished the delve and resumed a fresh one, the architect wore
  the previously-refused Rare Vicious War Axe of Fury over adb — it
  EQUIPPED (its collision partner was the potion the user drank; the
  id's first match is now the axe itself). Greatsword restored after;
  loadout unchanged, nothing consumed. Root cause proven end-to-end:
  run-scoped drop counters × persisting pack × first-match id
  consumers × every-match removal.
- **PLAYTEST CLOSED.** Verdicts on record: V1 dock visibility + chip
  rebuild + whole-header backing; V2 action-first flow + armed-target
  highlighting + attack as a bar action (bump-attack retired); bare
  tap = enemy info; walk sentence moves to the armed path; map
  tap-to-attack retires (V2 cluster); V3 forge price always visible;
  V4 free benches + tiered level-scaled failure, lose-1-on-fail, xp
  on failure; V5 notice town-screens-only; V6 steppers + MAX +
  tap-and-hold, Worn/Carried forge sections; V7 merchant stacking
  (follow-up 16 activated); V8 general wait verb, every fight; V9
  two-state battle glyph, watched/engaged split; V10 the id-collision
  fix (root cause + destructive family confirmed live). The user
  ruled: the V10 fix rides the post-playtest wave, not a hotfix.
  No unit dispatched yet — more playtest verdicts are arriving first.

### D98 — 2026-09-03 — Playtest #2 closed; the post-playtest wave is LOCKED (four units, order fixed)

- The user closed the playtest after the V10 on-device confirmation.
  Wave plan brainstormed and LOCKED with the user:
  1. **`m3-itemids`** (V10) — FIRST, severity: hero-scoped item-id mint
     (brewNumber precedent, codec omit-on-default per D56), remove-one
     semantics on every id-consuming action, suspend-theorem guard
     (resume adopts max(profile, suspended)). Core + codec, strict TDD.
  2. **`m3-battle-flow`** (V1 + V2 + V8 + V9) — the user ruled BOTH the
     wait verb and the battle glyph RIDE this unit: the dock chips +
     whole-header backing, armed-target highlighting, attack as a bar
     action (bump-attack retired), bare-tap enemy info, walk sentence on
     the armed path, map tap-to-attack retired, the core `WaitPressed`
     verb (turn passes, world ticks, log line candidate "You hold your
     ground."), and the two-state watched/engaged status glyph. App +
     one core verb; one AVD pass.
  3. **`m3-craft-risk`** (V4) — free benches, tiered level-scaled
     failure (t1 0% / t2 20% / t3 35%, −2% per level above the gate,
     floor 5%), lose-1 on fail, xp on failure; brew odds mapping
     (architect lean: base 20% − 2%/level, floor 5%) rules at spec
     time. Core + Rng discipline + band trail.
  4. **`m3-town-ux`** (V3 + V5 + V6 + V7) — AFTER craft so the forge
     price line renders the material-only costs once: always-visible
     price + separate refusal word, notice town-only, steppers + MAX +
     tap-and-hold (smelt/brew/vault gold), Worn/Carried forge sections,
     merchant stacking. App-side only.
  Then **m3-quests (M3Q, save v4, per-unit sanctioned)** — the id mint
  fix lands first, so quest payout items inherit a sound namespace.
  Not yet specced; each unit takes recon → spec → build prompt per the
  operating model.

### D99 — 2026-09-03 — m3-itemids verified and ACCEPTED at `b06b6de`; PR flow awaits the user

- **Architect verification, own instruments, all passed:**
  - Diff read at hunk level across step.dart, wear.dart, item.dart,
    profile.dart, run_boundary.dart, town.dart, both codecs, world.dart —
    shape exactly the spec's: `Item.withId` (narrow, tempered's reason),
    `withoutFirst` shared helper with the one-tap-one-item dartdoc, mint
    at pickup (`_minted` with the floor-freeze rationale), temperItem
    replace-first on heldItem's scan order, both codecs omit-on-default
    on the reach precedent, resume reconciles max(profile, suspended)
    with the drift argument written down.
  - Suites re-run from the worktree, my own result files: core 828 +
    content 550 + app 563 = **1941 green, zero failures** (baseline
    793/541/563 = 1897, measured fresh by the worker AND the counts
    match my pre-migration runs).
  - All five band lines verbatim from my own run of the content
    suite's survivability trail — byte-identical to the D79 pins
    (crypt 16/40 `{1:1,2:9,3:8,4:6,5:16}`, casting 40/40, greedy 16 /
    fleetfoot 13, sea-cave 26/40, keep 24/40).
  - Mutation row M2 re-run by my own sed (drink rebuild reverted to
    remove-all): reddened exactly the two duplicate-pair drink tests
    (`duplicate_id_test` "the first twin is drunk, the sibling survives";
    `item_remove_one_test` "drinking a duplicate id takes exactly one,
    the sibling survives"), 14 green; reverted, tree clean.
  - `dart analyze .` from the worktree root (pwd quoted): no issues;
    format 0 changed; no commits under docs/; nothing pushed.
- **Worker's honest disclosure, ratified:** an M1 pre-flip red came from
  the worker's own test-arrangement mistake (mis-assumed which twin
  `here.last` takes), fixed before the change landed — disclosed in the
  report rather than buried. The reviewer dispatch found two house-rule
  nits (fixed in `b06b6de`) and two scope notes, now ledger follow-ups:
  merchant_visit `withoutSold` still remove-ALL (visit-scoped ids,
  harmless today, same trigger as 16) and temperItem's worn branch on a
  legacy two-slots-one-id save (extremely exotic).
- One channel discrepancy on the record, mine: the kickoff note said
  "you create the worktree", the build prompt said it already existed —
  the build prompt was right (I created it after writing the note).
  Corrected in the dispatch flow; noted here so the fold carries it.
- **Unit m3-itemids (story M3I) is COMPLETE at `b06b6de`** — 10 commits
  over `a567c19`, tree clean. NEXT: PR flow on the user's approval
  (commit the plan doc, push, `gh pr create`), then post-merge verify,
  mailbox fold, worktree/branch cleanup.

### D100 — 2026-09-03 — m3-itemids: PR #1 opened on the user's approval; architect session handed off

- Plan doc committed on the branch (`6f5bf5e`), branch pushed, PR opened
  with `gh` from the worktree (it resolves worktree checkouts fine — the
  old `tea` trap is truly retired):
  **https://github.com/fiatcode-gh/residuum-rpg/pull/1** — the first PR
  on GitHub, so forge numbering restarts at #1. Cite GitHub numbers from
  here on; the ledger's pre-migration PR numbers #1–#16 are Forgejo-era.
- Awaiting the user's review and squash-merge in the GitHub UI; then
  post-merge verification on `main`, mailbox fold into
  `m3-itemids-handoff.md`, worktree and branch cleanup, watch stop.
- The architect session handed off right after opening the PR: the
  dispatcher watch expires with this session; the next session re-binds
  from ARCHITECT-HANDOFF.md, re-checks the mailbox (worker side is quiet
  — the unit is complete on the worker's side, disposed through
  dispatcher entry 2), and runs the post-merge close-out.

### D101 — 2026-09-03 — m3-itemids merged as `594bc80` via GitHub PR #1; story M3I CLOSED

- The user squash-merged PR #1 in the GitHub UI. `main` = `594bc80`
  ("fix: M3I item ids — a pack item's id is minted once, and one tap
  removes one item (#1)"). GitHub PR #1 is the m3-itemids PR; Forgejo-era
  PR #1–#16 citations in this ledger stay superseded (D96).
- **Post-merge verification, the architect's own runs, all passed:**
  suites run per package directory on `594bc80`: core **828** + content
  **550** + app **563** = **1941 green, zero failures**. All five band
  lines verbatim from my own content-suite run, byte-identical to the
  D79 pins: crypt 16/40 (40.0%) `{1:1,2:9,3:8,4:6,5:16}`, casting
  40/40, greedy 16 / fleetfoot 13, sea-cave 26/40 (65.0%), ruined keep
  24/40 (60.0%). Content identity: `git diff b06b6de main -- packages`
  is **EMPTY** (0 bytes); the merge adds only
  `docs/plans/2026-09-03-m3-itemids.md` (tracked, rides the branch).
- **Close-out done in order:** mailbox folded chronologically into
  `m3-itemids-handoff.md` (CLOSED) from the raw channel files; REPORT
  mirrored as `m3-itemids-build-report.md`; channel directory removed
  with errors visible and fold-checked; `handoff/` retired (stamp file
  removed, directory gone); worktree — found ALREADY REMOVED on disk
  (user-side cleanup between sessions), metadata pruned with
  `git worktree prune`; branch `m3-itemids` deleted at `6f5bf5e` after
  the content-identity gate passed. The re-bound dispatcher watch was
  found not running at kill time (confirmed via pgrep — no mailbox
  watch process); with the unit closed it is not needed. No mail was
  missed: the worker produced nothing after its disposed entry 2.
- **The V10 duplicate-id bug is dead on the user's save.** The absent-
  key decode path (both codecs omit-on-default, save v3) means the
  existing Sea-Cave delve loads unchanged; every future pickup mints a
  hero-unique id. **The no-sell/bank/drop advisory has LAPSED** — the
  user may sell, bank, and drop again.
- New environment trap for the list: this monorepo has NO root
  pubspec — `flutter test packages/<pkg>` from the repo root fails with
  "No pubspec.yaml file found"; suites run per package directory
  (`cd packages/<pkg> && flutter test`). The architect's first v2 run
  burned on exactly this.
- **Story M3I COMPLETE. NEXT: unit 2 of the wave — `m3-battle-flow`
  (V1+V2+V8+V9), then `m3-craft-risk` (V4), then `m3-town-ux`
  (V3+V5+V6+V7), then m3-quests (M3Q, save v4).**

### D102 — 2026-09-03 — Code audit received and triaged; routing proposed, wave amendment awaits the user

- The user dispatched a four-lens code audit (CDH/TTC/SEC/DST, blind to
  one another, controller re-verified). Report:
  `docs/reports/2026-09-03-audit-residuum-rpg.md` (gitignored, cite by
  absolute path). Head audited: `6a1500a` (the user's `.pi`-exclude
  chore on top of `594bc80`) — the audit's test counts (1941) match the
  D101 post-merge verification.
- **Architect spot-verification of the top claims, own instruments, all
  hold:** `SaveStore.save` returns a bool that all six call sites discard
  (grep-verified: autosaver.dart:174, boot.dart:76/99/110/122/148 — all
  bare awaits); the autosave queue chains `_queue.then` with no error
  handler (autosaver.dart:171–176) — one throw poisons the session's
  saves; the actor codec reads `speed: intAt(from, 'speed')` with no
  range check (actor_codec.dart:113–116); `main()` awaits `bootFrom`
  unguarded (main.dart:18–22); the release build signs with the debug
  keystore (build.gradle.kts:33–37). The audit's honest-severity notes
  (TTC-1 demoted from Critical; CDH-5/TTC-4 conflict resolved to
  Important) are accepted as recorded.
- **Accepted findings, grouped for routing:**
  1. SAVE HARDENING (one unit): write-path reporting (save() bool
     ignored; renames outside the failure handling; poisonable queue;
     refuse-to-advance on a create that did not land), unguarded boot +
     thrown-read fallback bypass, semantic decode validation (speed ≥ 1
     first, energy cap, hp ≤ maxHp, item-id uniqueness, skill levels —
     folds TTC-8 and TTC-10), engine-boundary guard (a step ArgumentError
     becomes a refusal, not an unhandled error), IoSaveFiles test
     coverage, and the door-opening reentrancy guard (silent refusal +
     stale `firstWhere` listener + double-tap). TownViewState's four
     coupled crawl fields → one sealed value + table-driven carry test is
     the rider if measurement allows, else its own small unit.
  2. CHORE (small unit or PR): CI workflow (three test suites + analyze +
     format per package, required on PRs to main), analyzer config for
     core/content, commit core/content lockfiles, README refresh, app
     README. Lockfiles and analyzer config pair with CI.
  3. AUTHOR DECISIONS (backlog, not units): CLAUDE.md module list repair
     (`combat/`/`quest/` do not exist; `magic/`/`town/` do) + the
     comment-policy direction (the codebase has voted against "none in
     bodies" — 47 private dartdocs and three rationale blocks in
     step.dart that carry measured balance data found nowhere else);
     pre-ship items — real signing config, `com.example` application id,
     auto-backup declaration — must land before the first distributed
     build, none blocks development.
  4. SMALL/BACKLOG: dead-hero ambush strikes (CDH-3, extra rng draws
     after death) rides the next unit that opens step.dart;
     vacuous totality test (TTC-9) + SavedHero guard tests (TTC-7) ride
     the save-hardening unit's test work; step.dart splitting (CDH-6)
     stays on watch; Gradle checksum pinning (SEC-9) on watch.
- **Proposed wave amendment (awaits the user's ruling):** m3-battle-flow
  (spec written, awaiting sign-off) → **m3-save-hardening (NEW, from
  group 1)** → chore unit (group 2, small) → m3-craft-risk (V4) →
  m3-town-ux (V3+V5+V6+V7) → m3-quests (M3Q, save v4 — hardened decode
  and write path land before v4 ships). Rationale: the user is actively
  playing; the silent-failure save path is live risk to real progress,
  and m3-quests (save v4) should build on hardened codec ground.

### D103 — 2026-09-03 — The user adopts the wave amendment; m3-battle-flow spec ratified; harness = pi

- **Wave amendment ADOPTED:** m3-battle-flow (spec ready) →
  **m3-save-hardening (NEW)** → chore unit (CI/analyzer/lockfiles/README)
  → m3-craft-risk (V4) → m3-town-ux (V3+V5+V6+V7) → m3-quests (M3Q,
  save v4).
- **The m3-battle-flow spec's five spec-time rulings are RATIFIED by the
  user** (chip wording `NOW — name` / `IN n — name`, attack as a bar
  action with adjacency targets, core `WaitAction`/`HeroWaited` + app
  `WaitPressed` with "You hold your ground.", glyph `◉`/`✖` with the
  drawn-glyph fallback, bare card tap = word-only enemy info panel).
  Spec of record: `docs/epic/m3-battle-flow-spec-M3BF.md`; recon:
  `docs/epic/m3-battle-flow-recon.md`.
- **Harness for this dispatch: pi** (user's choice, per-dispatch rule).
  The build prompt is the next artifact; worktree `.worktrees/
m3-battle-flow` created by the architect before dispatch; unit channel
  `docs/epic/handoff/m3-battle-flow/`; the dispatcher watch re-binds at
  channel creation.

### D104 — 2026-09-03 — m3-battle-flow verified and ACCEPTED at `12f3746`; PR flow awaits the user

- **Architect verification, own instruments, all passed:**
  - History: 11 commits `5bc47c2..12f3746` on `m3-battle-flow` only;
    parent repo untouched; nothing under `docs/` committed (plan doc
    uncommitted as instructed).
  - Diff read at hunk level — core is exactly the spec's 28 insertions
    (`WaitAction` + `HeroWaited` + the emit-and-fall-through case +
    `_refuse` returns null); app lands every contract: the monster-tile
    map gate in `directionTo`'s branch, armed null → view-side info
    sheet, sealed `ArmedAction` with the `armedSpellId` compat getter,
    `armedTargets` (attack = orthogonal adjacency, spell = sight), chips
    `NOW — x` / `IN n — x` in ink on `dockBacking` 0xB30E1015,
    `_BattleGlyph` fixed 18px cell (`✖` engaged / `◉` watched / empty)
    with the word in the fitted string, road-row Wait
    (`isEncounter && !isRoadClear`), bar renders for every hero when the
    dock is open with Attack/Wait.
  - Suites re-run per package directory from the worktree: core **835**
    + content **550** + app **589** = **1974 green, zero failures**
    (fresh baseline 828/550/563 = 1941 matches the worker's and the
    D101 counts).
  - All five band lines verbatim from my own run — byte-identical to the
    D79 pins.
  - Mutation row M2 re-run by my own sed (gate reverted in
    `game_bloc.dart`): reddened exactly `a map tap on an adjacent
    monster tile refuses like watched ground` (1 red, only failure);
    reverted, tree clean (the uncommitted plan doc the only dirty path).
  - `dart analyze .` + format exit 0 from the worktree root, pwd quoted.
  - Shots read in pixels: chips + backing (13), armed marks card + map
    outline + `Attack — armed` (14), info sheet words-only (18), map
    refusal sentence (19), watched `◉`/`Watched 1` (05), wait beat +
    chips advanced (20), armed bump killed the rat (15), greyscale
    variant (13-grey) — all read as claimed.
- **Read the report LAST; its disclosures ratified:** the road-row Wait
  surface is widget-tested but unshot (no road fight this run — honest);
  one watch lapse disclosed and restarted (worker entry 2); M5's first
  attempt was a compile error, redone behaviorally. Two edge nuances
  measured, both sound against the diff I read myself: (1) an
  adjacent-but-unseen monster is still reachable by the armed bump
  (adjacency is the rule, sight is not) while an armed spell there
  refuses — unchanged from today; (2) a tap on an adjacent INVISIBLE
  monster tile with nothing in sight falls past the watched-refusal
  branch (its guard is `enemiesInSight > 0`) into walk-start, whose
  first-step guard stops on the monster tile — silent, no swing. Marginal
  cosmetic wart, noted for the next UX unit that opens the tap grammar.
- **Unit m3-battle-flow (story M3BF) is COMPLETE at `12f3746`.**

### D105 — 2026-09-03 — m3-battle-flow: PR #2 opened on the user's approval

- The plan doc committed on the branch (`bc3a6af`), branch pushed, PR
  opened with `gh` from the worktree:
  **https://github.com/fiatcode-gh/residuum-rpg/pull/2**. GitHub PR
  numbering: #1 m3-itemids, #2 m3-battle-flow.
- Awaiting the user's review and squash-merge in the GitHub UI; then
  post-merge verification on `main`, mailbox fold, worktree and branch
  cleanup, watch stop.

### D106 — 2026-09-03 — m3-battle-flow merged as `bf8bcb6` via GitHub PR #2; story M3BF CLOSED

- The user squash-merged PR #2 in the GitHub UI. `main` = `bf8bcb6`
  ("feat: M3BF the battle flow — armed-target actions, the wait verb,
  dock chips, the battle glyph (#2)").
- **Post-merge verification, the architect's own runs, all passed:**
  suites per package directory on `bf8bcb6`: core **835** + content
  **550** + app **589** = **1974 green, zero failures**. All five band
  lines verbatim from my own content-suite run, byte-identical to the
  D79 pins. Content identity: `git diff 12f3746 main -- packages` is
  **EMPTY**; the merge adds only the plan doc.
- **Close-out done in order:** shots mirrored (25 files) to
  `docs/reports/shots/m3-battle-flow/`; mailbox folded chronologically
  into `m3-battle-flow-handoff.md` (CLOSED) from the raw channel files;
  REPORT mirrored as `m3-battle-flow-build-report.md`; channel removed
  with errors visible and fold-checked; `handoff/` retired; worktree
  removed, metadata pruned, branch `m3-battle-flow` deleted at
  `bc3a6af`; the dispatcher watch killed with the kill's confirmed
  result (pgrep clean after). No mail missed.
- **Story M3BF COMPLETE. NEXT: `m3-save-hardening`** (D103 amendment),
  then the chore unit, then `m3-craft-risk`, `m3-town-ux`, m3-quests.
- HASH UPDATE (D107): the squash was later re-pushed as `d2b78be` with
  an identical tree; cite `d2b78be` from D107 on.

### D107 — new day — main re-squashed to `d2b78be` (content-identical); architect handoff prepared

- The PR #2 squash was re-pushed with new hashes: `main` moved
  `bf8bcb6` → `d2b78be`, parent `6a1500a` → `ee6c64c`. Both diffs are
  EMPTY — the D106 post-merge verification stands unchanged; cite
  `d2b78be` as `main` from here on.
- The architect handoff (`ARCHITECT-HANDOFF.md`) is regenerated per the
  ritual: no open unit, no worker, no mailbox, no watch. Next work is
  `m3-save-hardening` recon.

### D108 — new day — m3-save-hardening recon done; forks locked (the user's rulings)

- **Recon measured all of D102 group 1 at `d2b78be`** (four read-only
  agents + the architect's own re-read of `energy.dart:75–105`,
  `item.dart:275–281`, `save_store.dart:39–58`). Every group-1 claim
  HOLDS except two. Recon of record:
  `docs/epic/m3-save-hardening-recon.md`.
- **Energy correction (re-priced, not dropped):** huge energy does not
  infinitely loop — each scheduler turn drains `actCost`; only
  `speed < 1` loops forever (`hero += heroSpeed` never reaches the
  threshold). An energy bound stays in the unit as defense-in-depth
  against unbounded schedule work, not as the hang fix.
- **ITEM-ID UNIQUENESS CHECK IS IN — the user overrode the recon
  recommendation and AMENDED the m3-itemids tolerance ruling (D99):**
  decode now refuses a document whose pack/worn ids repeat, with a
  SaveMalformed sentence, instead of tolerating duplicates with
  remove-one semantics. `item.dart:275–281`'s "legacy saves can hold
  duplicate ids" doc gets updated alongside. Consequence accepted by the
  user: a pre-mint save that somehow carries duplicate ids fails to
  load (the current→previous fallback chain still runs, and a refused
  save reads as malformed, not absent). Worker must add the check so
  every golden still passes (recon verified they do).
- **TownViewState sealed crawl value RIDES this unit** (user overrode
  the "own unit later" recommendation): 9 construction sites, no
  copyWith today, ~204 test lines touch the four fields; the
  run-XOR-suspended distinction and the `SavedHero` document invariants
  must survive the sealed-value design.
- **Sealed notice type INTRODUCED** (user's pick over reusing
  `String? notice`): the epic's first sealed notice type, with variants
  for load failure, save-write failure, and resume refusal; the
  existing string sentences become its payloads; `Notice` widget reads
  words off it. Boot failure screen: sentence + Begin-fresh action,
  fallback chain runs first (the architect's recommendation, adopted).
- Scope locked for the build prompt: write path (renames inside the
  failure handling, queue error sink, discarded bool consumed,
  refuse-to-advance in `_rosterChose`), boot guard + thrown-read
  fallback bypass + failure screen, decode validation (speed ≥ 1,
  energy bound, hp ≤ maxHp, skill level/xp ranges, Actor.reach as a
  real check, item-id uniqueness per the amended ruling), engine-boundary
  guard (step ArgumentError → refusal), IoSaveFiles injectable base dir
  + temp-dir coverage, door reentrancy guard, sealed notice type,
  TownViewState sealed crawl value rider, TTC-9 deep-decoder fixtures +
  TTC-7 SavedHero invariant tests. Save format stays v3; no golden or
  band moves (recon verified the goldens pass every proposed check).

### D109 — 2026-09-04 — m3-save-hardening dispatched; worker kickoff acked (P1–P8); two spec-shape corrections promoted

- **Unit dispatched:** worktree `.worktrees/m3-save-hardening` off
  `d2b78be` (branch `m3-save-hardening`); channel
  `docs/epic/handoff/m3-save-hardening/` (dispatch = entry 1, ack =
  entry 2); harness **pi** (user's choice); build prompt
  `docs/epic/m3-save-hardening-build-prompt.md`; spec M3SH + recon of
  record cited by absolute path. Dispatcher watch standing.
- **Worker kickoff verified fresh baseline 1974 green (835/550/589),
  matches the D106 count.** Worker spec-attack found two real errors in
  the architect's spec; both verified by the architect's own grep
  before ack:
  1. **HP ceiling is gear-inclusive — the spec's blanket `hp ≤ maxHp`
     would refuse LEGAL saves.** `heroMaxHp(hero, loadout)`
     (`town/profile.dart:121`) makes the profile ceiling gear-inclusive;
     an affix carries `maxHp: 6` (`affix_pool.dart:52`); `restAtInn`
     heals to the gear-inclusive ceiling and a run hero saved mid-crawl
     can sit above the bare 20 baseline. Contract (P1, accepted): profile
     `hp ≤ heroMaxHp(rebuilt hero, decoded equipment)`; run hero actor
     `hp ≤ heroMaxHp(hero, run equipment)`; monsters plain `hp ≤ maxHp`;
     `hp ≥ 0` everywhere. Still passes all goldens.
  2. **The refuse-to-advance path had a second defect hiding under it:
     `_openRoster` closes the autosaver (`main.dart:314`) before
     `_rosterChose` can refuse — a refused roster advance left the
     session with NO save machinery.** Fix (P3, accepted): on a failed
     roster save, build a FRESH Autosaver seeded from the live document
     before close, re-attach watchers, re-push the roster with the
     failure notice; `_saver` non-final; no session rebuild (the boot
     copy is stale — it would hand the hero back spent gold).
- **Pre-declarations ACKED (worker entries 1–2; build before ack was
  forbidden and none happened):** P1 above; P2 `Boot?` returns from
  boot.dart roster functions; P3 above; P4 sealed notice named
  `SaveNotice` with FOUR variants (load, saveWriteFailed, resumeRefused,
  generic sentence carrier named `SentenceNotice` — refusal AND
  announcement sentences ride it, e.g. the forge level-up); P5 `TownCrawl?` sealed value with
  `CrawlOpening(run, dungeon)` / `CampStanding(crawl, dungeon, campDay)`
  + derived getters (binding note: one-shot run semantics stated on
  `CrawlOpening`'s dartdoc); P6 in-flight guard ignores a second door
  event, wait on `run != null || notice != null`, bail on notice-only
  resolution (binding note: no `_openCrawl` without a run); P7
  `throwReadsTo` failure injection on `MemorySaveFiles` (store-side
  thrown-read guard STAYS — it honours the read-never-throws contract
  against any implementation); P8 `guardedBoot` returning
  `Future<Widget>` from `main.dart`. Energy bound 1000 confirmed by the
  worker's content sweep (real max ≈ 119–low hundreds); uniqueness
  scope per hero (profile equipment+inventory+bank; run
  equipment+inventory), after the version gate.

### D110 — 2026-09-04 — m3-save-hardening build COMPLETE at `e4081ce`; worker paused on quota

- **The worker's build is DONE** (worker entry 2, 16:29): 12 commits
  `d2b78be..e4081ce` on `m3-save-hardening`, working tree clean, all
  three suites green — **core 835 (unchanged), content 573 (+23), app
  636 (+47) = 2044**. The mutation sweep is complete: all 14 rows run,
  named reds and green controls both observed. Two measurement notes
  from the worker: M10's red was only observable after the boundary
  test measured its own premise (a plain `stream.first` test passed
  under the mutation — fixed in `e4081ce`); M13's unreadable-slot test
  needed a genuinely refused read (a directory where the file was),
  same commit. No deviations beyond the acked P1–P8.
- **Worker PAUSED on user quota**; remaining on resume: `dart analyze`
  + format from the worktree root, the AVD pass (copy-aside ritual,
  emulator-5554, greyscale variants), REPORT.md + final evidence
  entry. Dispatcher watch stood down per the worker's pause note and
  the user's standing instruction.
- **Channel trap (third occurrence, user-sanctioned repair each
  time):** a markdown `##` heading inside an entry BODY is read as an
  entry header and the tool refuses the whole file. Worker entries 1
  and 2 both tripped it (`## Kickoff…`, `## Spec-attack results…`,
  `## Pre-declared shape deviations…`, `## Paused — quota…`); each was
  repaired by indenting the line one space. Standing rule passed to
  the worker in dispatcher entry 4: indent body headings by one space.

### D111 — 2026-09-07 — m3-save-hardening verified and ACCEPTED at `44c85cd`; PR flow awaits the user

- The worker resumed after the quota pause and finished: 14 commits
  `d2b78be..44c85cd` (analyze/format run, AVD pass done, REPORT.md
  mirrored). **Architect verification, own instruments, all passed:**
  suites per package directory, strict counts from result files — core
  **835** + content **573** + app **637** = **2045 green, zero
  failures**; goldens + version-gate test files diff EMPTY, saveVersion
  still 3; band lines verbatim from the architect's own run (casting
  40/40, greedy 16 / fleetfoot 13, sea-cave 26/40, keep 24/40; crypt
  16/40 holds by its code assertion); mutation row M1 re-run by the
  architect's own edit — reddened exactly the two speed-zero
  deep-decoder fixtures, all else green, reverted; analyze + format
  exit 0 from the worktree root, pwd quoted; diff read at hunk level
  for every lib file; AVD shots read in pixels.
- **44c85cd reviewed and accepted** (the worker's post-pause fix found
  by the AVD pass): the resume-refusal and save-write notices landed on
  the TOWN state but the doors live on the world screen, which rendered
  only the world's notice — the sentence existed in a state nobody
  could see. The door column now renders the town's notice. Sound
  against the diff; the `RunSuspended`-carries-dungeon deviation is
  sound against the sealed shape (a crawlless dungeon is
  unrepresentable).
- **Disclosures ratified:** the disabled-door-buttons shot withdrawn
  honestly (a 217-frame bugreport screenrecord shows the press→answer
  window never paints; the widget tests + M11's named red are the
  pinning evidence); staging builds (forced boot throw, inverted resume
  gate) disclosed and reverted; the save-failure shot staged with a REAL
  disk failure (slot names replaced by directories, no code hook). The
  save ritual held both directions — both slots copied aside and
  restored byte-identical, and the real playtest save decodes whole
  under the new checks.
- **Story M3SH COMPLETE at `44c85cd`.** Verdict in dispatcher entry 6.
  Next: PR on the user's approval, then the chore unit (D102 group 2).
- **PR #3 opened on the user's approval (D105 flow):** plan doc
  committed on the branch (`57f8ef9`), branch pushed, PR opened with
  `gh` from the worktree —
  https://github.com/fiatcode-gh/residuum-rpg/pull/3. Awaiting the
  user's review and squash-merge in the GitHub UI; then post-merge
  verification on `main`, shots/report mirroring, mailbox fold,
  worktree + branch cleanup, watch stop.

### D112 — 2026-09-07 — m3-save-hardening merged as `b2c1381` via GitHub PR #3; story M3SH CLOSED

- The user squash-merged PR #3. `main` = `b2c1381` ("feat: M3SH the
  save pipeline stops failing silently (#3)").
- **Post-merge verification, the architect's own runs, all passed:**
  content identity `git diff 57f8ef9 origin/main` EMPTY (the shipped
  tree is the verified tree, plan doc included); suites per package
  directory on `main` — core **835** + content **573** + app **637**
  = **2045 green, zero failures**; all five band lines verbatim from
  the architect's own run on `main` (crypt 16/40, casting 40/40,
  greedy 16 / fleetfoot 13, sea-cave 26/40, keep 24/40).
- **Close-out done in order:** shots mirrored (42 files) to
  `docs/reports/shots/m3-save-hardening/`; REPORT mirrored as
  `m3-save-hardening-build-report.md`; mailbox folded chronologically
  into `m3-save-hardening-handoff.md` (CLOSED, 19 entries) — one fold
  bug found and fixed (the fold's `strip()` ate the one-space indent
  on repaired body headings; redone with newline-only stripping);
  channel removed and `handoff/` retired (fold-checked); worktree
  removed, metadata pruned, branch deleted at `57f8ef9`; dispatcher
  watch killed with the kill confirmed and a clean process scan.
- **Story M3SH SHIPPED. NEXT: the chore unit** (D102 group 2: CI
  workflow — three suites + analyze + format required on PRs to main,
  analyzer config for core/content, commit their lockfiles, README
  refresh), then `m3-craft-risk` (V4) → `m3-town-ux` (V3+V5+V6+V7) →
  m3-quests (M3Q, save v4).

### D113 — 2026-09-08 — house method amended: widget-driven implementation, the AVD pass as final acceptance gate (user ruling)

- The user found the AVD-driven implementation loop too slow (build →
  install dance → save ritual → screenshot per iteration) and asked
  whether widget tests can drive UI work instead. The architect reconned
  the evidence and the user ruled: **UI units become widget-driven** —
  screen-shaped widget tests, phone-sized via a shared helper, drive the
  build loop; the AVD pass remains MANDATORY but demotes from
  implementation driver to a **final acceptance gate** run once at unit
  close (one install + save ritual + scripted taps + greyscale shots for
  the author's eye). Applies from `m3-town-ux` onward; the chore unit
  proceeds first regardless (it is not a UI unit).
- **The evidence split behind the ruling** (recon this session): of the
  epic's ten device-only catches, the layout classes — status-row
  overflow (M3D), truncated potion label (M2Q), wording ellipsising
  (M3B), flee unreachable by touch (M3W, as hit-test reachability) —
  are reproducible in phone-sized widget tests. The `_onAPhone` helper
  (1080×2424 @ 2.625) exists but in exactly one file
  (`packages/app/test/widget/world_screen_test.dart`); the app suite
  already carries 202 `testWidgets` across 18 files. The genuinely
  device-only classes stay device-pinned: paint timing (the press→
  answer window never painting, M3SH, proven by a 217-frame
  screenrecord), real path_provider/disk behavior, real font/density
  rendering beyond hit tests, and the author's greyscale eye (manual
  regardless).
- **Concrete shape for every future UI unit:** one shared phone-sizing
  test helper; screen-mounted widget tests phone-sized by default; the
  build loop runs `flutter test` per package directory (D101), never
  the emulator; the AVD sweep at close covers what only a device can
  see. The D37 line that the AVD pass stays mandatory reads through
  this amendment — the pass's role changed, its existence did not.
- Side benefit: the chore unit's CI runs the three suites on every PR;
  widget tests run in CI for free, and AVD time never can.

### D114 — 2026-09-08 — the chore unit (M3CH) recon done; four forks locked

- Recon fresh per doctrine (`m3-chore-recon.md`): no CI (no `.github`);
  all three packages already format/analyze-clean, so strict gates can
  land day one; `lints/recommended` on core/content costs exactly SIX
  trivial test-file findings (4 core `curly_braces`, 1 content
  `curly_braces`, 1 content underscore-local — no lib/ changes); the
  include cannot resolve until `lints` is a dev-dependency; content
  reaches core via the `../core` path dependency so CI must check out
  whole and run per package (D101); README stale on every number ("Four
  skills" vs a nine-member enum, "514 tests" vs 2045); app README pure
  boilerplate. One recon non-finding: a `dead_code` warning seen in a
  broken /tmp trial does NOT exist against the real tree.
- **Forks ruled by the user:** (1) CI shape = one workflow, single job,
  three-way package matrix, flutter-action pinned EXACTLY 3.47.2;
  (2) core/content get `package:lints/recommended.yaml` with the six
  measured fixes; (3) "required on PRs to main" lands as branch
  protection enabled by the USER in the GitHub settings UI after the
  unit's PR shows the three checks — the architect may NOT touch repo
  settings; (4) the README's test-count line is replaced by the command,
  never a hardcoded count again.
- Spec written: `m3-chore-spec-M3CH.md` (story M3CH, unit m3-chore).
  Out of scope, standing: follow-ups 43 (needs the author) and 44
  (pre-ship). This unit has no AVD pass (no UI change).

### D115 — 2026-09-08 — M3CH mid-flight: the format premise is conditional on resolution; ci.yml gains explicit pub get; the lib/ freeze stands

- The worker STOP-AND-REPORTED at the characterization baseline: format
  measured 12 files wanting changes (6 core, 6 content) in the fresh
  worktree, three of them lib/ files, and asked for a ruling (worker
  entries 1–2). Its proposed cause (dart_style bugfixes make CI red at
  base) was tested by the architect with its own instruments and is
  WRONG in one load-bearing respect:
- **The real mechanism:** `dart format` applies the package's resolved
  language version only AFTER resolution. Without `.dart_tool/` (a fresh
  worktree, no `pub get` yet) it defaults to the latest language version
  and flags ~6 core / 6 content files; WITH resolution (language 3.9,
  measured in both the main checkout and the resolved worktree), the
  committed code at `b2c1381` is canonically formatted — 0 changed, exit
  0. The recon's "format clean day one" premise HOLDS, conditional on
  CI resolving first. Throwaway-copy trial reproduced both numbers.
- **Rulings relayed to the worker (dispatcher entry 2):** (1) option (a)
  DECLINED — no lib/ changes; the lib/ freeze stands; the format gate is
  green at base under the contracted command once resolution exists.
  (2) The pub-get gap is REAL and accepted as a spec amendment: ci.yml
  adds an explicit `dart pub get` (core, content) / `flutter pub get`
  (app) step before format/analyze/test — dart analyze does not resolve
  implicitly. (3) The worktree's dirty `generator.dart` is a stray
  formatter write (tall-style output from a run without `--output=none`);
  the worker reverts it to HEAD and re-verifies format clean at base.
  (4) The CI format step MUST run after the pub-get step — the ordering
  is load-bearing, and the spec's verification block now pins it.

### D116 — 2026-09-08 — M3CH mid-flight: the recon's lint-count split was wrong (architect error, worker-caught); one mechanical lib/ fix authorized

- The worker's adversarial re-measure (dispatcher entry 2's standing
  instruction) caught the recon's core lint split WRONG: the recon
  inferred "4 × curly_braces, all in test/dungeon/generator_items_test.dart"
  from a truncated trial output. The real set at lints ^6.1.0 in the
  resolved worktree: **3 × curly_braces in generator_items_test.dart + 1
  × curly_braces in lib/src/engine/step.dart:466-467** (the unbraced
  `if (item == null) return const ActionRefused(...)` in the DrinkAction
  case) + content's 2 unchanged. The architect verified the step.dart
  finding at source before ruling; the sibling `if` two lines below is
  already braced. Architect recon error, caught by the worker — the
  method working as designed.
- The spec's tripwire fired verbatim ("if a recommended lint would
  demand lib/ changes, STOP and report"); the worker touched nothing in
  lib/ and added no excludes.
- **Ruling (dispatcher entry 3): option (a) AUTHORIZED as a named spec
  deviation** — exactly ONE lib/ change: brace-wrap the DrinkAction
  early return at step.dart:466-467. Conditions: its own commit
  (separate from the test-file lint fixes, so the diff reads clean);
  core suites re-run after (835 strict-green); all five band lines
  re-verified (D56 discipline — step.dart is the sharpest ground in the
  repo); no excludes anywhere; nothing else in lib/ moves. Option (b)
  (an exclude) declined — a permanent config scar for one mechanical
  finding poisons the no-excludes precedent.

### D117 — 2026-09-08 — M3CH verified and ACCEPTED at `53b68f1`; PR flow awaits the user

- **Architect verification, own instruments, all passed:** suites per
  package directory on the worktree — core **835** + content **573** +
  app **637** = **2045 green, zero failures** (strict counts from JSON
  reporters, hidden excluded); all five band lines verbatim from the
  architect's own content run (crypt 16/40, casting 40/40, greedy 16 /
  fleetfoot 13, sea-cave 26/40, keep 24/40); format clean ×3, analyze
  clean ×3 (core/content under lints/recommended); `git check-ignore`
  empty on both locks and both diff-clean vs a fresh `dart pub get`;
  diff read at hunk level for all 15 files; ci.yml read in full (matrix,
  resolution first per D115, exact pin 3.47.2, no root invocation).
- **Mutation row M1 re-run by the architect's own edit** — un-braced the
  fixed `if` at generator_items_test.dart:58 → core analyze reddened
  exactly 1 named finding (`curly_braces` at that line), content + app
  green; reverted (status re-checked after per the new auto-format-hook
  trap), analyze back to clean. M2 verified by the worker; M3/M4 remain
  NAMED SKIPS pending the user-approved push (scratch-branch CI proofs).
- **Report read LAST** after all instruments; its claims all held. Two
  cosmetic items for PR prep (architect's): ci.yml lacks a trailing
  newline (valid YAML, reviewer-noted) and the plan doc sits dirty
  (Task-7 untick after the DONE entry) — both fold into the prep commit
  before the push. Report's "9 commits" line undercounts by the final
  review-minors commit (10 in its own log block) — noted, no action.
- **Story M3CH COMPLETE at `53b68f1`** (9 commits + plan doc). Whole-
  branch review APPROVED with 3 minor findings (recorded in the plan
  doc). Next: user-approved push round — prep commit, push, `gh pr
  create` from the main repo root, M3/M4 scratch-branch proofs after the
  push, then the user enables branch protection once the PR shows three
  green legs (D114 ruling).

### D118 — 2026-09-07 — M3CH merged as `348cb14` via GitHub PR #4; mutation table closed on real CI; amendments riding PR #6

- The user squash-merged PR #4. `main` = `348cb14`. **Post-merge
  verification, the architect's own runs, all passed:** content identity
  `git diff dc8fa7c origin/main` EMPTY; suites per package directory —
  core **835** + content **573** + app **637** = **2045 green, zero
  failures**; all five band lines verbatim from the architect's own run;
  format clean ×3, analyze clean ×3. PR #4's own CI run (34106751120):
  **three green legs** (core 1m22s / content 1m28s / app 2m04s).
- **M3/M4 closed on real CI** (transient draft PR, closed after):
  **M3 RED AS DEFINED** — the proof run reddened the core leg at the
  FORMAT step (checkout ✓ → flutter-action ✓ → pub get ✓ → format ✗);
  content leg fully green; app leg cancelled by the DEFAULT FAIL-FAST
  after passing analyze — its own finding. **M4 GREEN with the lock
  deleted** — the pin was consumed but enforced by nothing when absent;
  a named finding, not a pass.
- **The user ruled:** PR #4 was already merged, so the two proof
  findings ride a NEW PR — `m3chore-ci-hardening` (commit `9f39888`):
  `fail-fast: false` on the matrix + a **lockfile drift gate**
  (`git diff --exit-code -- pubspec.lock` after resolution, all three
  legs). Open as **PR #6**; its CI run completed SUCCESS.
- **Close-out done in order:** REPORT mirrored as
  `m3-chore-build-report.md`; mailbox folded chronologically into
  `m3-chore-handoff.md` (CLOSED, 12 entries — 4 dispatcher, 8 worker);
  channel removed and `handoff/` retired (fold-checked, gone); PR #7
  proof closed; branches `m3chore-m4proof` + `m3-chore` deleted (local +
  remote where they existed). The worktree stays until PR #6 resolves
  (it holds the amendment branch). No shots this unit (no UI change);
  the AVD pass is N/A by the D113 method (no UI, no device work).
- One unreproduced transient on record: a single `dart analyze` pass on
  main's core reported "1 issue found"; clean on the immediate re-run
  and every later run. CI's analyze leg is the standing guard.
- **Branch protection** remains the user's settings-UI act (D114) once
  they choose to flip it; the three-green-legs evidence is on the
  record.

### D119 — 2026-09-07 — the drift gate hardened and proven; M3CH fully closed, PR #6 merge-ready

- **M4 re-proof round 1 (green, a hole found):** with the lock deleted,
  the drift gate v1 (`git diff --exit-code`) PASSED — `pub get`
  regenerates the deleted lock and the regenerated file is untracked,
  invisible to `git diff`. Gate v1 caught content drift against the
  committed pin but not deletion.
- **Strengthened (`78a3ee5`):** the gate now runs
  `git ls-files --error-unmatch pubspec.lock` before the diff — a
  deleted (or never-committed) lock reds the leg.
- **Proof 2 (RED AS DEFINED):** the deletion probe reddened the core
  leg at the lockfile-drift step (format/analyze/test skipped), content
  and app legs success — and the fail-fast fix visibly worked (the
  sibling legs completed instead of being cancelled). The M4 arc is
  closed end to end: v1 green-hole → `ls-files` check → v2 reds exactly
  on the probe.
- **PR #6 is merge-ready:** its own CI run at `78a3ee5` completed
  SUCCESS (all legs). Awaiting the user's squash-merge; then the M3CH
  worktree (on `m3chore-ci-hardening`) is removed and the branch
  dropped.

### D120 — 2026-09-07 — PR #6 merged as `e0544f4`; M3CH fully closed; session flushed

- The user squash-merged PR #6. `main` = `e0544f4`; content identity
  `git diff 78a3ee5 origin/main` EMPTY (the shipped tree is the verified
  tree). The push-to-main CI run for `e0544f4` is the first-ever main-
  branch run of the workflow (push trigger).
- **Close-out done:** worktree `.worktrees/m3-chore` removed; branches
  `m3chore-ci-hardening` (local; remote auto-deleted on merge) and
  `m3chore-m4proof2` deleted; the stale `m3chore-proof` found by the
  fold-check ls-remote and deleted; remote is `main` only; local
  branches pruned. No shots (no UI change); the AVD pass N/A per D113.
- **Chore unit (M3CH) fully shipped across PR #4 (`348cb14`) + PR #6
  (`e0544f4`).** Follow-ups 41/42 CLOSED. Journal logged to the weft
  graph.
- Session flush follows: new RESUME snapshot + regenerated
  ARCHITECT-HANDOFF.md.

### D121 — 2026-09-07 — branch protection SET: the `main` ruleset requires the three `gates` legs

- The user flipped the GitHub ruleset after the session's evidence rounds
  (D114's ruling executed). Verified by the architect via the rulesets
  API: enforcement **active**, `required_status_checks` = `gates (app)`,
  `gates (content)`, `gates (core)` (+ GitGuardian), rules include
  `pull_request`, `required_status_checks`, `deletion`,
  `non_fast_forward`. Check names match the matrix legs exactly.
- Standing caution promoted to the handoff: the workflow must never
  rename the job (`gates`) or the check names, or the required checks
  silently stop matching — a required check that no longer fires is a
  stuck PR, not a red. Any ci.yml change renames checks only with that
  risk named and the ruleset updated in the same round.
- The weft TODO (journal 2026-09-07, [[Residuum]]) is CLOSED with the
  result sub-bullet.

### D122 — 2026-09-07 — m3-craft-risk recon + spec done; unit DISPATCHED (harness: pi)

- Recon fresh on `e0544f4` (`docs/epic/m3-craft-risk-recon.md`): the
  central finding is that town transactions are pure functions over
  `Profile` (`run_boundary.dart`) with no `Rng` in reach — V4's failure
  roll is the first town-side draw in the game.
- **Spec `m3-craft-risk-spec-M3CR.md`, user-APPROVED.** Central contract:
  the craft stream lives on the Profile (`craftRngState`, lazy-seeded
  `worldSeed ^ craftSeedSalt`, salt by collision sweep, omit-on-default in
  the codec on the `itemNumber` precedent) — town stays pure, save v3
  stands, goldens untouched. One attempt = one stream advance, 0% tier
  included. Spec-time brew ruling (D98's architect lean, settled): 20% −
  2% per Herbcraft level, floor 5%, no gate. `TemperPrice.gold` retires;
  the forge price line's gold term retires THIS unit (full rework stays
  m3-town-ux's).
- Dispatched: worktree `.worktrees/m3-craft-risk` on `m3-craft-risk` off
  `e0544f4` (architect-created); build prompt
  `m3-craft-risk-build-prompt.md` (traps verbatim, mutation table M1–M7,
  plan-doc at `docs/plans/2026-09-07-m3-craft-risk.md` rides the branch);
  channel `docs/epic/handoff/m3-craft-risk/` open, dispatch note entry 1;
  harness: **pi** (user's choice). Dispatcher watch running and verified
  past one tick. Awaiting the worker.

### D123 — 2026-09-07 — m3-craft-risk: the worker's three pre-declared rulings RATIFIED

- The worker pre-declared before code (mailbox entries 2–3), then
  self-corrected entry 2 before anything landed. All three ratified:
- **CraftLoss rides as a sealed answer (entry 3 is the ruling of record,
  superseding entry 2's third tuple slot):** `TownAnswer` (a sentence) with
  `TownRefusal` and `CraftLoss` as its two kinds; `Crafted = (Profile,
  TownAnswer?)` stays a 2-tuple so every existing destructure compiles.
  The spec's "transaction signatures do not change" is read as the pure
  parameter shape (profile in, profile out) — the return type widens to
  the sealed answer. `TownRefusal`'s changes-nothing contract stays
  intact; a failed craft is a different kind of answer, not a refusal.
- **M1's "+0" prose corrected (worker-caught, mine):** odds key on the
  tier being bought, so a tier-2 attempt starts from an item at +1; the
  mutation row's literal "+0" was impossible. Read as "the item does not
  gain its tier": item at +1, forced-fail state, Blacksmith 5 → item
  still +1, exactly 1 ingot lost, skill trained.
- **On a failed attempt the loss sentence wins the notice slot** over the
  level-up sentence (the loss is the news; the skills row shows the
  level). Success paths keep today's wording exactly.
- The worker attacked and accepted the two named claims (brew gate-less
  odds; one-attempt-one-advance) as written.

### D124 — 2026-09-07 — m3-craft-risk mid-flight: the M6 named red set corrected (architect error, worker-caught); worker paused by the user before the device pass

- **The spec's M6 row was unrepresentable as written.** It predicted that
  a mutation drawing from the crawl's `rng` would redden the roll-for-roll
  test. With the craft stream profile-carried (the spec's own central
  contract), a pure profile-in/profile-out transaction cannot reach the
  crawl's streams at all — the corruption M6 guards against is
  unreachable from inside the boundary, so the roll-for-roll test stays
  green under any mutation expressible there. The worker's actual
  mutation (a throwaway `Rng(profile.worldSeed)` with no write-back)
  reddened the four `craftDraw` unit tests; the roll-for-roll and resume
  tests stand as the tripwire for any future change that widens the
  boundary. Ratified as the row's named red set of record.
- Worker pause report (user's instruction, laptop battery): all nine plan
  tasks committed (10 commits, HEAD `e99025b`, tree clean), 2077 strict
  green (core 860 + content 579 + app 638, fresh), mutation table
  complete, bands + goldens byte-identical, format/analyze clean ×3 after
  pub get. Device pass NOT started (first emulator boot segfaulted; save
  ritual never began). Resume point: boot Pixel_10 → save ritual with
  checksums → build + install → forge-bench greyscale shot → restore
  saves. Architect's full verification (phase 6) waits for the done
  notice.
- Salt `craftSeedSalt = 0x0C7A` recorded — sweep passed first run across
  7 fixture seeds × 64 early rolls.

### D125 — 2026-09-08 — m3-craft-risk verified and ACCEPTED at `a119643` (+ `300f7ed` docs tidy); PR flow awaits the user

- **Architect verification, own instruments, all passed:**
  - Worktree proof: 11 commits `e0544f4..a119643` on `m3-craft-risk`
    only; nothing under `docs/epic/` committed. One discrepancy found and
    settled: the plan doc carried whitespace-only formatting drift after
    the worker's final commit (tree not clean at report time, cosmetic);
    folded as `300f7ed` `docs:` commit by the architect (a planning
    artifact) — tree clean now.
  - Diff read at hunk level — core is exactly the ratified shape:
    `risk.dart` (salt 0x0C7A, tier table keyed on `temperPrices`' gates,
    brew gate-less, floor via `max(5, …)`, one-draw-per-attempt, lazy seed
    on default 0, `rollRange(0,99)`), `TownAnswer` sealed base with
    `TownRefusal`/`CraftLoss`, `Crafted = (Profile, TownAnswer?)`, failure
    loses exactly 1 ingot / brewCost herbs and trains, success unchanged
    minus gold, `_clamped` on the success path (failure touches no gear);
    codec omit-on-default with the wide-int treatment; forge price line
    ingots-only; `town_bloc._crafted` — an answer yields the level-up
    sentence, ruling 3 exactly.
  - Suites re-run per package from the worktree, own result files: core
    **860** + content **579** + app **638** = **2077 strict green, zero
    failures** (worker's fresh baseline 2045 = carried D118, matched).
  - All five band lines verbatim from my own run — byte-identical to the
    D79 pins; golden save test and the crypt tripwire green in the same
    run.
  - Mutation row M5 re-run by my own edit (failure branch spends
    `-price.ingots`): reddened EXACTLY the named set — {'a temper that
    fails loses exactly one ingot, not the tier's price'} — 37 green
    beside it; reverted, tree re-checked clean a beat later.
  - Format clean ×3, analyze clean ×3 (own runs, after pub get).
  - Greyscale shot read in pixels: "Next tier: 1 ingot." — no gold term;
    state by word and marking; dead row says the transaction's sentence;
    "(worn)" still present (retires in m3-town-ux, correctly not here).
- **Device acceptance (worker's pass, user-assisted AVD boot):** four
  sandbox boot segfaults → user started the AVD; save ritual FIRST (both
  slots aside, sha256-verified), `install -r` kept data (731 MB free — no
  uninstall dance), acceptance save pushed via run-as stdin, saves
  restored byte-exact. The user's playtest crawl untouched.
- **The unit m3-craft-risk (story M3CR) is COMPLETE at `a119643`** — 12
  commits with the docs tidy. **PR #9 OPEN** (user approved the round):
  pushed and `gh pr create` — https://github.com/fiatcode-gh/residuum-rpg/pull/9
  — three `gates` legs required by the D121 ruleset; the user squash-merges
  in the UI.

### D126 — 2026-09-08 — PR #9 merged as `bd848f7`; m3-craft-risk CLOSED; close-out done

- The user squash-merged PR #9. `main` = `bd848f7`; **tree diff between
  the verified head `300f7ed` and `origin/main` EMPTY** — the shipped
  tree is the verified tree. Local main fast-forwarded to `bd848f7`.
- **Close-out done in order:** shot mirrored to
  `docs/reports/shots/m3-craft-risk/forge-bench-greyscale.png`; REPORT
  mirrored as `m3-craft-risk-build-report.md`; mailbox folded
  chronologically into `m3-craft-risk-handoff.md` (CLOSED, 12 entries —
  6 dispatcher, 6 worker); channel removed and `handoff/` retired
  (fold-check: gone); local branch `m3-craft-risk` deleted (was
  `300f7ed`); remote branch auto-deleted on merge; `ls-remote` shows
  `main` only; dispatcher watch killed, kill confirmed by process scan.
- **One anomaly on record, unexplained but harmless:** the worktree
  `.worktrees/m3-craft-risk` was already GONE when the close-out ran —
  directory and git metadata both (not removed by the architect; the
  worker's done notice did not claim it). By then the content was
  verified (D125) and shipped (tree diff empty), so nothing was lost.
  Note for the next unit: re-verify the worktree exists right after
  creating it and again at dispatch.
- **Unit m3-craft-risk (story M3CR) is SHIPPED.** Follow-up ledger: none
  new (M6's lesson is a standing doctrine note: a mutation row's red set
  must be expressible at the boundary the contract draws).
- NEXT: `m3-town-ux` (V3+V5+V6+V7 — the FIRST unit under the amended D113
  widget-driven method) → m3-quests (M3Q, save v4). Wave locked (D98, as
  amended D103); go straight to recon.

### D127 — 2026-09-08 — m3-town-ux verified and ACCEPTED at `a44fa33`; PR flow awaits the user

- **Fork rulings locked pre-spec (user, 2026-09-08):** (1) counted benches
  commit by PENDING COUNT + one commit press — tap-and-hold never fires
  repeated transactions; (2) the brew cap clamps at herbs AND free pack room;
  (3) the shared `_onAPhone` helper is adopted only by test files the unit
  touches. All three landed exactly as ruled.
- **Architect verification, own instruments, all passed:**
  - Worktree proof: 12 commits `bd848f7..a44fa33` on `m3-town-ux` only;
    `packages/core` + `packages/content` diff EMPTY (the scope gate held);
    parent repo untouched; nothing under `docs/epic/` committed; plan doc
    rides the branch (`7d1800a`). Tree clean, re-checked a beat later.
  - Diff read at hunk level — exactly the spec's shape: two-line
    price/refusal grammar in `_TemperRow` (ceiling renders the sentence and
    no price line), WORN/CARRIED sections from the named halves with the
    id-based `_isWorn` and "(worn)" retired, `SmeltPressed(count)` /
    `BrewPressed(count)` looping the existing transactions (one advance per
    unit), `_batchLoss` verbatim at f=1 and "f of n brews fail and take
    3·f herbs" at f>1 with loss-wins-over-level-up (D123 ruling 3) as an
    early return, `_levelled` one comparison per batch, bank's two dials
    with the retired argument rewritten honestly ("by ruling, not by
    argument"), merchant's three lists through `stacked` with per-item
    price and the row acting through its first item's id, the character
    screen's one-line notice retirement, `CountStepper` (−/value/+/MAX,
    400ms first repeat, 120ms cadence, constants dartdoc'd as part of the
    widget's contract).
  - One file the spec's changed-list missed: `item_presentation.dart`
    (+30/−3) — `_stacked` made public as `stacked`, body identical; the
    spec named the machinery but not the visibility change. Architect's
    miss, owned; no shape impact.
  - Suites re-run per package from the worktree, own result files: core
    **860** + content **579** + app **677** = **2116 strict green, zero
    failures** (worker's fresh baseline re-measure at `bd848f7` = 2077,
    matched the carried D126 record; +39 new tests).
  - All five band lines verbatim from my own content run — byte-identical
    to the D79 pins; golden save tests green inside the same run; save v3
    stands; no profile field added.
  - Mutation row M1 re-run by my own edit (the row's definition exactly —
    the row reverted to the `reason ??` single slot): reddened EXACTLY the
    named set {a refused forge row keeps the price of its next tier
    visible} — 21 green beside it, both named controls (ceiling; open
    price) green; reverted, tree re-checked clean a beat later.
  - Format clean, analyze clean (own runs, worktree root, pwd quoted, pub
    get first).
  - Shots read in pixels: forge stepper + WORN/CARRIED + price line (05),
    the tempered refused row rendering BOTH "that needs Blacksmith 5" AND
    "Next tier: 2 ingots." (21 — V3 live), merchant `Common Healing Potion
    ×3` at per-item `Buy 20` (13), bank's two dials with the dead take
    side's sentence (17), character screen with NO notice row (19), and
    the greyscale forge — everything reads by word, mark, position.
- **Disclosures ratified (report read LAST):** commit `bd3d583` landed
  with 2 wiring tests red (`boot_wiring_test`, `roster_session_test` still
  drove the retired fixed buttons; the worker's per-file runs missed them)
  — fixed in `3ba67f9`, final branch state fully green (verified by my own
  suite runs at HEAD). A rule-10 breach moment, disclosed before anyone
  asked. The worker's two test-layer discoveries stand for the record:
  inside a scroll view, `onTapDown` waits out the recogniser's 100 ms press
  timeout, so on-screen hold cadence is 100 ms + 400 ms to the first repeat
  (device-verified live, correct); and brew-batch assertions must count
  `brew-`-prefixed ids because the fresh hero starts with 2 healing
  potions. The M7 wording nuance ("LAST attempt" reads as "last FAILED
  attempt") was the only spec-word note — no spec claim found wrong.
- **Worktree anomaly (D126):** `.worktrees/m3-town-ux` verified at creation,
  again at dispatch, and through the build — it never vanished. The check
  ritual worked; keep it.
- **The unit m3-town-ux (story M3TUX) is COMPLETE at `a44fa33`.** PR flow
  awaits the user (D22 flow, `gh`, squash). The AVD pass ran as the final
  acceptance gate (one install, save ritual with sha256 both directions,
  scripted taps, greyscale shots) — the first unit under the amended D113,
  and the widget-driven loop carried it end to end.

### D128 — 2026-09-08 — PR #10 merged as `85e7bcc`; m3-town-ux CLOSED; close-out done; the worktree anomaly REPEATED

- The user squash-merged PR #10. `main` = `85e7bcc`; **tree diff between
  the verified head `a44fa33` and `origin/main` EMPTY** — the shipped tree
  is the verified tree. Local main fast-forwarded.
- **Close-out done in order:** four greyscale shots mirrored to
  `docs/reports/shots/m3-town-ux/`; REPORT mirrored as
  `m3-town-ux-build-report.md`; mailbox folded chronologically into
  `m3-town-ux-handoff.md` (CLOSED, 5 entries — 2 dispatcher, 3 worker);
  channel removed and `handoff/` retired (fold-check: gone, errors
  visible); local branch `m3-town-ux` deleted (was `a44fa33`, `-D` —
  squash merges are invisible to `-d` ancestry, tree diff was the proof);
  `ls-remote` shows `main` only; dispatcher watch killed, kill confirmed
  by process scan (zero `mailbox watch` processes).
- **The D126 worktree anomaly REPEATED:** `.worktrees/m3-town-ux` was
  found already removed at close-out — directory and git metadata both,
  by no recorded hand. Pattern across both occurrences: the worktree
  vanished AFTER the worker session closed (this time the `.worktrees`
  dir mtime reads 09:09, the worker's done notice was 08:53), never
  during a build, and never with content lost (verified and shipped
  first, both times). Standing rule stays: verify at creation, at
  dispatch, and never trust it to persist through the unit; the architect
  must not rely on the worktree existing after the worker's done notice
  reads.
- **Unit m3-town-ux (story M3TUX) is SHIPPED.** The wave of D98/D103 is
  now fully merged (V1–V10 all shipped). **NEXT: m3-quests (M3Q, save
  v4)** — recon fresh per the operating model; read
  `m3-save-hardening-spec-M3SH.md` first; the hardened codec is its
  foundation.

### RESUME snapshot — 2026-09-08: m3-town-ux SHIPPED (PR #10, `85e7bcc`); the D98 wave is COMPLETE; next unit m3-quests (CURRENT)

- **`main` = `85e7bcc`** on GitHub — **m3-town-ux shipped via PR #10**
  (story M3TUX, verdicts V3+V5+V6+V7), post-merge verified (tree diff vs
  verified head EMPTY; local main ff'd). **The D98/D103 wave is COMPLETE:
  all of V1–V10 shipped** (battle flow, itemids, save hardening, chore,
  craft risk, town ux). Suites of record: **2116 strict green
  (860/579/677)**, bands byte-identical, save v3 stands. First D113
  widget-driven unit; `CountStepper`, the shared `onAPhone` helper
  (`packages/app/test/support/phone.dart`), and public `stacked` are
  standing shapes for later UI units.
- **Worktree anomaly (D126, now twice — D128):** the unit worktree was
  found already removed at close-out, again by no recorded hand, again
  after the worker session closed. Verify at creation, at dispatch — and
  do not rely on the worktree existing after the done notice.
- **NEXT: m3-quests (M3Q, save v4)** — the codec work reads
  `m3-save-hardening-spec-M3SH.md` first; recon fresh; spec → user
  approval → build prompt → dispatch (ask the harness).
- Standing follow-ups: 13, 20, 28, 32–34, 43–46 (43/44 need the author;
  45/46 ride later units). Open questions: none.
- Dispatcher watch: KILLED (kill confirmed by process scan). Channel:
  folded into `m3-town-ux-handoff.md`; `handoff/` retired.

### RESUME snapshot — 2026-09-08: m3-town-ux on its branch, verified; PR #10 open (SUPERSEDED — see the block above)

- **`main` = `bd848f7`** (m3-craft-risk, PR #9). **Unit `m3-town-ux`
  (story M3TUX, verdicts V3+V5+V6+V7) is COMPLETE on its branch at
  `a44fa33`** — 12 commits, zero core/content diff, verified this session
  by the architect's own instruments (D127): **2116 strict green
  (860/579/677)**, five bands byte-identical from
  the architect's own run, goldens byte-identical, M1 re-run by the
  architect's own edit, format/analyze clean, shots read in pixels.
  **PR #10 OPEN:** https://github.com/fiatcode-gh/residuum-rpg/pull/10
  (pushed on the user's approval, 2026-09-08); the user squash-merges in
  the UI.
- The worker's one correction of record: `bd3d583` landed with 2 wiring
  tests red, fixed in `3ba67f9` — final branch state green (D127).
- **FIRST unit under the amended D113 widget-driven method — the loop
  worked**: widget tests drove the build; the AVD pass ran ONCE as the
  final acceptance gate (save ritual sha256 both directions, scripted
  taps, greyscale shots), zero device findings. CountStepper, the shared
  `onAPhone` helper (`packages/app/test/support/phone.dart`), and the
  merchant stacking machinery (`stacked`, made public in
  item_presentation.dart) are now standing shapes for later UI units.
- **NEXT: m3-quests (M3Q, save v4)** — the wave's last unit, builds on
  the hardened codec (D59 doctrine). Recon fresh per the operating model;
  read `m3-save-hardening-spec-M3SH.md` first. Standing follow-ups: 13,
  20, 28, 32–34, 43–46 (43/44 need the author; 45/46 ride later units).
- Dispatcher watch: RUNNING (restarted after each wake; kill with
  confirmation + process scan at close-out). Channel:
  `docs/epic/handoff/m3-town-ux/` — OPEN until the PR merge + close-out.

### RESUME snapshot — 2026-09-08: m3-craft-risk SHIPPED (PR #9, `bd848f7`); next unit m3-town-ux (SUPERSEDED — see the block above)

- **`main` = `bd848f7`** on GitHub — the m3-craft-risk unit (story M3CR,
  verdict V4) shipped via **PR #9**, post-merge verified (tree diff vs
  verified head EMPTY; local main ff'd). Free benches, tiered level-scaled
  craft failure (t1 0% / t2 20% / t3 35%, −2%/level past the gate, floor
  5%; brew 20% − 2%/level, floor 5%, no gate), lose-1-on-fail, xp on
  failure, profile-carried craft stream (`craftRngState`, salt `0x0C7A`,
  omit-on-default — save v3 stands, goldens byte-identical), sealed
  `TownAnswer` with `CraftLoss`. 2077 strict green at verification; bands
  verbatim. Close-out done: shots mirrored, mailbox folded (12 entries),
  `handoff/` retired, branch deleted, watch killed+confirmed.
- **Worktree anomaly (D126):** `.worktrees/m3-craft-risk` was found
  already removed at close-out, by no recorded hand — content was shipped
  and verified first, nothing lost. Next unit: re-verify the worktree at
  creation AND at dispatch.
- **NEXT: `m3-town-ux` (V3+V5+V6+V7)** — always-visible price + separate
  refusal word, notice town-only (character-screen bar retires), steppers
  + MAX + tap-and-hold (smelt/brew/vault gold), Worn/Carried forge
  sections, merchant stacking. THE FIRST UNIT under the amended D113
  widget-driven method — the recon must read `m3-battle-flow`'s
  `_onAPhone` helper shape first. Then m3-quests (M3Q, save v4).
- Standing follow-ups: 13, 20, 28, 32–34, 43–46 (43/44 need the author;
  45/46 ride later units).
- Standing cautions that bind m3-town-ux: D113 widget method; D56 field
  discipline (no new profile fields expected); the forge price-line
  grammar was left partially built by M3CR on purpose — the always-visible
  price + separate refusal word completes it; V5's notice work touches the
  same `TownAnswer`/notice path M3CR just reshaped.

## Artifact index

| Unit (branch) | Stories | Spec | Build prompt | Handoff | State |
|---|---|---|---|---|---|
| m1-crawl | M1 | m1-crawl-spec-M1.md | m1-crawl-build-prompt.md | m1-crawl-handoff.md (closed) | ✅ merged |
| m2-engine | M2E | m2-engine-spec-M2E.md | m2-engine-build-prompt.md | m2-engine-handoff.md (closed) | ✅ merged |
| m2-loot | M2L | m2-loot-spec-M2L.md | m2-loot-build-prompt.md | m2-loot-handoff.md (closed) | ✅ merged |
| m2-town | M2T | m2-town-spec-M2T.md | m2-town-build-prompt.md | m2-town-handoff.md (closed) | ✅ merged |
| m2-qol | M2Q | m2-qol-spec-M2Q.md | m2-qol-build-prompt.md | m2-qol-handoff.md (closed) | ✅ merged |
| m3-rng | M3R | m3-rng-spec-M3R.md | m3-rng-build-prompt.md | m3-rng-handoff.md (closed) | ✅ merged |
| m3-saves | M3S | m3-saves-spec-M3S.md | m3-saves-build-prompt.md | m3-saves-handoff.md (closed) | ✅ merged |
| m3-heroes | M3H | m3-heroes-spec-M3H.md | m3-heroes-build-prompt.md | m3-heroes-handoff.md (closed) | ✅ merged |
| m3-leave | M3L | m3-leave-spec-M3L.md | m3-leave-build-prompt.md | m3-leave-handoff.md (closed) | ✅ merged |
| m3-world | M3W | m3-world-spec-M3W.md | m3-world-build-prompt.md | m3-world-handoff.md (closed) | ✅ merged |
| m3-dungeons | M3D | m3-dungeons-spec-M3D.md | m3-dungeons-build-prompt.md | m3-dungeons-handoff.md (closed) | ✅ merged |
| m3-depth | M3X | m3-depth-spec-M3X.md | m3-depth-build-prompt.md | m3-depth-handoff.md (closed) | ✅ merged |
| m3-balance | M3B | m3-balance-spec-M3B.md | m3-balance-build-prompt.md | m3-balance-handoff.md (closed) | ✅ merged |
| m3-magic | M3M | m3-magic-spec-M3M.md | m3-magic-build-prompt.md | m3-magic-handoff.md (closed) | ✅ merged |
| m3-craft | M3C | m3-craft-spec-M3C.md | m3-craft-build-prompt.md | m3-craft-handoff.md (closed) | ✅ merged |
| m3-fixes | M3F | m3-fixes-spec-M3F.md | m3-fixes-build-prompt.md | m3-fixes-handoff.md (closed; build report m3-fixes-build-report.md) | ✅ merged |
| m3-battle (unit A) | M3U | m3-battle-spec-M3U.md | m3-battle-build-prompt.md | m3-battle-handoff.md (closed; build report m3-battle-build-report.md) | ✅ merged |
| m3-itemids | M3I | m3-itemids-spec-M3I.md | m3-itemids-build-prompt.md | m3-itemids-handoff.md (closed; build report m3-itemids-build-report.md) | ✅ merged |
| m3-battle-flow | M3BF | m3-battle-flow-spec-M3BF.md | m3-battle-flow-build-prompt.md | m3-battle-flow-handoff.md (closed; build report m3-battle-flow-build-report.md) | ✅ merged |
| m3-save-hardening | M3SH | m3-save-hardening-spec-M3SH.md (recon: m3-save-hardening-recon.md) | m3-save-hardening-build-prompt.md | m3-save-hardening-handoff.md (closed; build report m3-save-hardening-build-report.md) | ✅ merged |
| m3-chore | M3CH | m3-chore-spec-M3CH.md (recon: m3-chore-recon.md) | m3-chore-build-prompt.md | m3-chore-handoff.md (closed; build report m3-chore-build-report.md) | ✅ merged (PR #4 + #6) |
| m3-craft-risk | M3CR | m3-craft-risk-spec-M3CR.md (recon: m3-craft-risk-recon.md) | m3-craft-risk-build-prompt.md | m3-craft-risk-handoff.md (closed; build report m3-craft-risk-build-report.md) | ✅ merged (PR #9) |
| m3-town-ux | M3TUX | m3-town-ux-spec-M3TUX.md (recon: m3-town-ux-recon.md) | m3-town-ux-build-prompt.md | handoff/m3-town-ux/ (folded: m3-town-ux-handoff.md CLOSED; build report m3-town-ux-build-report.md) | ✅ merged `85e7bcc` via PR #10 (D128) |

## Handoff history

- M1 / `m1-crawl` / session `residuum-m1-crawl [004c46]`: returned 14 commits,
  93 tests, one confirmed spec defect (chase freeze, D6), verified D6, squash-
  merged as `be1da0a` (D7). Worker→architect SendMessage failed delivery;
  user relayed by hand (follow-up 7).
- M2E / `m2-engine` / session `residuum-m2-engine [a28cac]`: returned 12
  commits, 212 tests, report-artifact mismatch owned and fixed (`dc58d85`),
  verified D9, squash-merged as `961dc46` (D10). Channel worked both ways;
  follow-up 7 closed (stale socket).
- M2L / `m2-loot` / session `residuum-m2-loot [59f9a2]`: pre-declared three
  shape deviations (approved), returned 13 commits, 384 tests, 70%
  survivability, exploit measured harmless, verified D12, squash-merged as
  `69d55e4` (D13).
- M2T / `m2-town` / session `residuum-m2-town [b1dd7c]` (relaunched bg after
  the interactive approval gate expired the first handoff): pre-declared four
  deviations (approved — two fixed real spec defects), returned 15 commits,
  514 tests, 62.5% band with pierce, extended the mutation table with two
  rows that caught its own blind tests, verified D15, squash-merged as
  `0824d8d` (D16). M2 complete.
- M2Q / `m2-qol` / session `residuum-m2-qol [1fad89]`: pre-declared five
  deviations (all shipped as declared), returned 12 commits, 613 tests,
  25/40 held, four findings (two spec defects mine — C2 off-by-one, clamp
  asymmetry; one device find — truncated potion label; one sequencing-trap
  extension), mutation extension row 11 caught a real step-suite blind spot,
  verified D21, merged `472e62b` via PR #1 (D22). Worker replies were held
  (interactive architect); user relayed — trap recorded.
- M3R / `m3-rng` / session `residuum-m3-rng [667379]`: returned 2 commits,
  619 tests, new baseline 24/40, three architect errors corrected (recon
  blast-radius, vacuous mutation row 2, latent record-List test defect on
  main), extension row 6 proved the golden pin is the sole guard on
  generator identity, verified D24, merged `0656eb1` via PR #2 (D25).
  Channel worked worker→architect this round.
- M3S / `m3-saves` / session `residuum-m3-saves [51b7fd]`: the epic's
  largest unit — 17 commits over three deltas (base + back guard + roster),
  768 tests, suspend proven roll-for-roll, four architect errors corrected
  pre-code (D26) and three boot defects device-found (D27), one fabricated
  hash owned (no breach) and one re.sub slip caught by the golden pin,
  verified D27/D29, merged `f758c3f` via PR #3 (D30). Channel held once
  early (interactive architect), then worked for all five later messages.
- M3W / `m3-world` / session `residuum-m3-world [9758de]`: pre-declared
  nine items before code (two were architect defects — the literal
  "897 stays green" and the roster stale-route blind spot, whose fix
  moved the Heroes door to the world screen), survived a mid-unit quota
  pause parked green, corrected the spec with two travel rulings (D40),
  found three real holes via its own green mutation rows, and the AVD
  pass found flee-unreachable-by-touch (a false green about something
  nobody could do). Returned 15 commits, 1153 tests, 21 mutation rows,
  verified D41, merged `958ef98` via PR #6 (D42). Surfaced the
  report-layout tension rather than silently switching — resolved as
  chore PR #7.
- M3L / `m3-leave` / session `residuum-m3-leave [7aba1c]` (launched by the
  architect on the user's advance authorization — D35): pre-declared seven
  shape items before code (all approved; two were spec defects of the
  architect's — the whole-Actor carry, the copyWith gold slot), device-found
  the D36 merchant-validity defect that survived 895 green tests and a full
  mutation table, corrected four spec claims total, returned 14 commits,
  897 tests, 21-row mutation table, riders answered with measurements
  (six documents for six changes across two leave/resume cycles; the
  identity skip, not bloc closing, prevents double-writes), verified D37,
  merged `844376f` via PR #5 (D38). Channel flawless both directions all
  round — first wave with a bg architect on both ends.
- M3D / `m3-dungeons` / session `residuum-m3-dungeons [f509d7]→[dd4e6d]`
  (restarted once near close; report mirror was the designed fallback):
  pre-declared three deviations before code (all approved; two were
  architect spec defects — the SpawnTable/bestiary coupling, a
  nonexistent app bar), corrected the orphan-test hazard, found a real
  hole via its own green row G2 (themed litter read by nothing), proved
  the histogram is the real crypt pin (row 10a/10b), owned an
  analyze-scope report mismatch (M2E class, no breach) and its
  undercounted row-2 red set, device-found the phone status-row overflow
  (5th AVD-only catch). Returned 11 commits, 1259 tests, 12+8-row
  mutation table, core diff EMPTY, verified D44, merged `59b91f1` via
  PR #8 (D45). Bands 35/40 + 31/40 ratified at merge.
- M3B / `m3-balance` / session `residuum-m3-balance [516b70]`: the
  epic's best worker round. Raised a correct BLOCKER pre-code (spec
  ruling 8 unbuildable in its own fence → D51 extended it to two hunks
  in step.dart/wear.dart), pre-declared six deviations (all approved),
  corrected five spec/recon claims (incl. two architect arithmetic
  errors), self-corrected its own three-scans analysis unprompted,
  STOPPED on the tuning with a measured six-step proof that the targets
  fought each other (→ D52 opened the spawn tables; ghoul+wolf confined
  to crypt 1–2), found and fixed a defect in the measuring instrument
  itself (bot drop/pick-up infinite loop, proven figure-neutral), caught
  its own approved wording ellipsising on device (6th device-only
  catch → "Finish"), honored the M3X save-copy trap with SHA256 proof,
  and converged a twenty-step trail to crypt 50%/cave 77.5%/keep 70%.
  Returned 9 commits, 1361 tests, 14+11-row table, verified D53, merged
  `936ca5b` via PR #10 (D54).
- M3X / `m3-depth` / session `residuum-m3-depth [857d3b]`: pre-declared
  FIVE deviations before code (all approved; the DelveDepth typedef and
  the crypt early-return both improved architect rulings), brought four
  measured findings pre-code (uniformity, coverage, two-goldens-not-four
  — an architect overcount, band direction predictions half right with
  the mechanism for the miss), found two real defects and a harness hole
  via its own rows (bot stall on short delves, lost copyWith carry,
  PumpedApp never reaching loadRun), corrected three spec claims (row-3
  no-op, G2's improved coverage, the golden count), withdrew its own E5
  single-guard claim after re-running the architect's sed and diagnosed
  the coincidence-mutant mechanism, closed a shots artifact gap and a
  god-fixture disclosure conflation (two saves; delta named field by
  field; no load-bearing observation touched), and disclosed the
  emulator-save overwrite that became a standing trap. Returned 6
  commits, 1296 tests, 15+2-row table, verified D47, merged `b9d7c21`
  via PR #9 (D48).
- M3H / `m3-heroes` / session `residuum-m3-heroes [af0b75]`: pre-declared
  11 shape items (all approved; two improved the spec), returned 13
  commits, 829 tests, rows 7–9 red proving D31, recon corrected (silent
  item loss), three honest holes filed as follow-ups 21–23, verified D32,
  merged `f7bd6b1` via PR #4 (D33). Ref labels crossed on the stale-
  architect trap; traffic flowed regardless.
- M3M / `m3-magic` / session `residuum-m3-magic [638a39]`: matched
  M3B's bar and set a new one for pre-code work. Refuted the spec's
  central control (C1 band-identity) BY EXPERIMENT before any code (one
  weight flip, measured, reverted → D56 struck it), caught the
  architect's gate arithmetic (L²+3L: Wrath 15 = 270 casts → gates
  4/4/3), caught two spec defects pre-code (stairs-bounce mana loop;
  cross-floor bind leak via per-floor monster ids), pre-declared three
  deviations (all approved), found via its own mutation table that no
  test cast the SHIPPED spells (closed it, 3c89261) and that row 9
  could not red the tie-breaks (added 9b), took the 7th device-only
  catch (a potion told it cannot be read), survived `flutter install`
  destroying both device saves BECAUSE the copy-aside ritual ran first
  (SHA256-identical restore), corrected its own report twice on the
  architect's re-measurement (stale count 1569→1570; an unrun row-1
  claim retracted — the second unit in a row where a claim survived
  only because someone re-ran it). Returned 9 commits, 1570 tests,
  12+2-row table, five-row tuning trail, verified D57, merged
  `83b5336` via PR #11 (D58).
- M3F / `m3-fixes` / THREE worker sessions over one mailbox (the fold
  is `m3-fixes-handoff.md`): S1 (pi, D64) pre-declared five deviations
  (all approved as D65), caught the architect's mana-0 spec claim (5th
  claim error of the epic), built all three items in five commits,
  broke mid-mutation-table; S2 (pi, D66 re-dispatch) re-bound from the
  mailbox alone, re-derived every count, ran the full 7-row table and
  corrected the spec's predicted-red sets by measurement (D67),
  disclosed its own M5 false-green and re-ran it, resolved the
  92%-full-/data install trap with both save slots verified aside;
  S3 (Claude Code, D68) finished the AVD tail with pixel-measured
  node-opacity evidence, corrected the record's own 01-shot mislabel,
  wrote the report, stood down clean. Verified D69 (bands
  byte-identical, M4/M6 re-run by the architect's own sed), merged
  `8168861` via PR #13 (D70). The unit that proved the mailbox
  re-binds a worker across session death — twice, across harnesses.
- M3I / `m3-itemids` / session `residuum-m3-itemids` (one worker
  session): ZERO pre-declared deviations — the recon held at every
  adversarial check (five boundary doors, prefix freedom, remove-first
  determinism). Returned 10 commits + the plan doc (11 over `a567c19`),
  1941 tests, five bands byte-identical, save v3 stands with both
  codecs omit-on-default and zero golden churn (the D56 lesson's worked
  example). Disclosed its own M1 test-arrangement red honestly; reviewer
  APPROVE WITH NITS (two house-rule nits fixed in `b06b6de`, two scope
  notes filed as follow-ups 33/34). One channel discrepancy owned
  (kickoff vs build prompt on worktree creation — the build prompt was
  right). Verified D99 by the architect's own instruments (including
  mutation row M2 re-run by own sed); merged `594bc80` via GitHub PR #1
  (D100/D101) — the first GitHub-era PR.
- M3BF / `m3-battle-flow` / session `m3-battle-flow` (pi, one worker
  session): attacked all five named spec claims by measurement BEFORE
  code (bump dispatch sites — found and closed the auto-walk third-path
  question itself; `directionTo` geometry; bot-visibility; NOW-chip
  clock-correctness; the full `armedSpellId` consumer enumeration),
  pre-declared four shape deviations (all approved — the sealed
  `ArmedAction` forked the spec's enum-or-sentinel choice on the
  naked-string rule), baseline matched the ledger exactly, returned 11
  commits + the plan doc, 1974 tests, five bands byte-identical, a
  7-row mutation table with named sets, and an AVD pass with both saves
  copied aside and restored MD5-identical. Disclosed its own watch
  lapse and an unshot surface (road-row Wait — widget-tested, no road
  fight occurred) rather than staging it. Verified D104 by the
  architect's own instruments (M2 re-run by own sed, shots read in
  pixels); merged `bf8bcb6` via GitHub PR #2 (D105/D106).
