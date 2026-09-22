# Unit 12.5 device checkpoint

Date: 2026-09-18
Written before the first device action of the unit.

## Authorization

- Unit 12.5 contract approved by the user on 2026-09-18, as drafted: seven
  capsules A–G, colour and greyscale each, measured chrome/map dp against the
  360 / 460 / 600 dp escalation thresholds, at most one constants-only tuning
  pass, the four contract-level remedies reserved to the user.
- The user directed the work onto the existing Unit 12 branch. Unit 12 stays
  **unpublished**; no push, pull request, review or merge is authorized.

## Tree and ownership

- Branch: `residuum-visual-reboot-12`
- HEAD: `8314beb02f6820e64c58c49ac0c3fd72643c3a25`
  (`259322b` the `packages/app` change, `a34e11e` and `8314beb` the records)
- Worktree clean at checkpoint time. There is no dirty user-owned state to
  preserve; anything appearing later is user-owned and must not be reset,
  stashed or overwritten.
- Base is `main` at `60909e60ec3150cf9b590e6641a8ae51efca775c` (PR #21).

## Accepted automated evidence carried in

- Architect-run final gate on this tree, from `packages/app`:
  `dart format` 120 files / 0 changed, `flutter analyze` clean,
  `flutter test` **906 passing** (884 before the unit).
- Integrated acceptance review: ACCEPT WITH FINDINGS, one must-fix, closed.
- Scoped closure review after the must-fix: ACCEPT WITH FINDINGS, no must-fix.
- `packages/core`, `packages/content` and `main.dart` untouched by Unit 12.
- The acceptance barrier is therefore clear and device evidence may start.

## Device and app state

- Device: user-started `Medium_Phone`, `emulator-5554`,
  `sdk_gphone16k_x86_64`, 1080x2400 at density 420 — **411.4 x 914.3 dp**.
  Agent-shell emulator launch remains prohibited; the emulator was already
  running and must be left running.
- Package: `com.example.residuum_app`. The installed build predates Unit 12
  (`res_timestamp` of 2026-09-17 11:04, the Unit 11 pass), so the Unit 12
  tree must be built and reinstalled before any capture.
- Save slots present before any install:
  `app_flutter/save.json` 4882 bytes and `app_flutter/save-previous.json`
  5031 bytes, both dated 2026-09-17 11:39.
- The phone build is not debuggable. `adb exec-out screencap` is the
  instrument; greyscale twins are produced with ImageMagick
  `-colorspace Gray`.

## Remaining acceptance criteria

All eight of the contract's criteria are open. Concretely:

1. Both slots backed up with SHA-256 before install, restored byte-identically
   after the last capsule, verified under the same scheme.
2. Seven capsules captured in colour and greyscale under
   `.flow/evidence/visual-reboot/unit-12.5-device/`.
3. Measured chrome and map height in dp for exploration, typical combat and
   worst legal combat, compared against 360 / 460 / 600 dp.
4. Unit 12's AC5 greyscale, AC12 by eye and AC14 device figures settled.
5. No label ellipsis, no word break, no hidden verb at worst legal density.
6. Any forced correction is the one allowed constants-only pass, or a user
   decision among the four recorded remedies.
7. Any production/asset/build change reruns affected suite proof and takes a
   scoped closure review before the unit closes.
8. AC17 recorded: whether the dungeon viewport is now the dominant remaining
   parity gap.

Per-capsule reporting duty for A, B and G, from `PLAN.md` Correction C1:
measured chrome and map height in dp, observed chip width and height, run
count, greatest label line count, whether any word splits across lines,
whether any label touches its border, and the `Drink`/`Pack` counts and
known-spell set the scene actually had.

## Restore obligation

- Backups live at
  `.flow/evidence/visual-reboot/unit-12.5-device/before-save.json` and
  `before-save-previous.json`, hashed with SHA-256 locally and on device via
  `run-as com.example.residuum_app sha256sum`.
- Scene capsules stage fixtures over `app_flutter/save.json` and do **not**
  restore; the final capsule restores both slots from those backups and
  records before/after SHA-256 with MATCH/MISMATCH/UNKNOWN. A receipt whose
  rendered before/after values disagree is not MATCH evidence.

## Fixture provenance available

Reusable codec-valid saves from earlier device passes:
`unit-10-device/fixture-stairs-landing.json`, `fixture-battle-shelf.json`,
`fixture-disabled-drink.json`, `fixture-crypt-scene.json`,
`fixture-sea-cave-walk14.json`, `fixture-sea-cave-stairs.json`,
`fixture-ruined-keep-*.json`, `fixture-road-journey.json`, and
`unit-11-device/u11-sea-target-fixture.json`. Derived fixtures must stay
codec-valid and must record what they changed.

## Progress, and the state at the pause of 2026-09-18

Paused by the user mid-unit. Nothing is in flight; no agent is running.

- `U12.5-setup` — **PASS.** Both slots backed up
  (`before-save.json` `18995c4c…b46d3`, `before-save-previous.json`
  `8909f70c…a9b11`), current-tree debug APK built and reinstalled
  data-preserving, installed base APK SHA-256
  `38e9520f3891e6de64686d7f5ad672754150ad6a5522e79387d09add13723b78`,
  save hashes unchanged by the install. Architect re-verified all three
  hashes independently.
- **Capsule A, exploration at worst exploration density — PASS.** Chrome
  **331.1 dp** against the 360 dp threshold (28.9 dp margin), map
  **535.2 dp** ≈ 14.9 rows at `cameraCellSize` 36. Two chip runs, every
  label one line, no word split, no ellipsis, no border touch. Scene: THE
  CRYPT 5/5, six live verbs, loot and a herb patch underfoot. Greyscale
  twin verified by the architect to be a pixel-exact `-colorspace Gray`
  conversion (`compare -metric AE` = 0). Log peek measured 273 px = 104.0 dp,
  matching `crawlLogPeekHeight` exactly — the strongest internal check that
  the region detection is right.
- **Capsule B, typical combat — PASS.** Chrome **438.1 dp** against the
  460 dp threshold — only **21.9 dp of margin**, under one chip run — map
  **428.2 dp** ≈ 11.9 rows, timeline 107.1 dp. The seven-chip row rendered
  as modelled; `Frost Lance 4` wraps to two lines, the greatest label line
  count seen so far. Chip width 91.43 dp, identical to capsule A's, so the
  chip grid is shared across scenes. The plan modelled ~418 dp here, so the
  device is ~20 dp *worse* than the model, not better.
- **Capsule C, armed targeting — PASS**, re-dispatched after the resume of
  2026-09-18 over `u125-b-fixture.json` unchanged, so the armed frame is the
  same scene as capsule B's unarmed one.
  - **No reflow, proved quantitatively.** The map viewport's hairlines sit at
    rows 512 and 1636 px (195.05 / 623.24 dp, height 428.19 dp) in *both* the
    unarmed and armed frames, and the action row measures 414 px in both.
  - **The armed cues are four, and none is a hue.** Border single-hairline
    `crawlRule` #2A2E38 → double-width `crawlInk` #E6EAF0; fill `crawlRaised`
    #1B1F27 → `crawlArmedFill` #262B35; label weight w500 → w600; and the
    reserved caption line renders the literal `— armed`. All four confirmed
    pixel-exact and all four survive greyscale.
  - **Target marks** are 1 dp square outlines on each visible monster's own
    cell, drawn in that monster's existing glyph ink rather than a new hue,
    bounded strictly to the actor cells.
  - **Stray tap disarms with no turn taken**, evidenced twice: the disarm path
    passes the same unmutated `game` reference, and the unarmed and disarmed
    captures differ by **0 pixels** over the whole map, log and action row.
  - Architect re-verification: the greyscale twin is a pixel-exact
    `-colorspace Gray` conversion; the armed-versus-unarmed map difference is
    **2,314 px of 1,213,920**, bounded to a 187x92 box over exactly the two
    monster cells, recomputed independently.
  - **Tooling trap worth carrying forward:** this workstation's ImageMagick
    reports an anomalous `compare -metric AE` of ~2.3e7 on that 1.2e6-pixel
    crop — about 19x the total pixel count — while returning a correct 0 on
    identical crops. Main reproduced both. Pixel counts in this unit come from
    a difference/threshold/mean route instead, and capsule D onward is warned.
- **Capsule D, the message log drawer — PASS.** Peek **104.0 dp** (matching
  `crawlLogPeekHeight` exactly), half **389.71 dp**, full **866.29 dp** — the
  whole content box. The extent cycle `peek → half → full → peek` was walked
  on the handle and returned. The log was *played* into existence with real
  taps, not injected: sixteen lines across **eight** of the ten
  `LogCategory` marks (`§ → ▲ ← ⇅ † ■ ✕`), each a distinct shape in its own
  inset well.
  - **Newest versus older is value, not hue**: `crawlInk` #E6EAF0 against
    `crawlDim` #8A919E, same neutral family, and the gap survives greyscale.
  - **Follow and unread were exercised for real**: scrolling to the top broke
    follow, an appended line raised a `↓ 2 new` pill with a true count, and
    tapping it jumped to the newest entry and cleared the pill.
  - Architect re-verification: both greyscale twins are pixel-exact
    `-colorspace Gray` conversions (0 differing pixels), and the full-extent
    capture was read by eye — title, handle, close pill, hairline, category
    wells and the newest-line brightness all legible without hue.
  - **Accepted observation, not a defect:** at full extent the drawer covers
    the status block, timeline and map, so no persistent place/HP/mana
    readout survives and the log's own prose carries state. That is the
    pre-existing full-drawer behaviour AC8 requires to be *unchanged*, and
    Unit 12 did not change it.
  - Capsule D's real play autosaved over the staged slot, so the live device
    saves are now fixture-derived play state. The backups are untouched and
    the restoring capsule still restores from them.
- **Capsule E, the sheets and overlays — PASS on all four, AC11 settled, and
  AC5's disabled half settled with it.**
  - **Spells overflow sheet**, opened by a real `+1` tap: a `CrawlPanel`
    surface (#15181F fill, 1 dp #2A2E38 hairline, 6 dp radius) in a sheet
    themed by `crawlTheme` with no drag handle, 284.19 dp tall. Not stock
    `BottomSheet`/`ListTile` chrome. Dismissed by barrier tap; the post-dismiss
    frame hashed byte-identical to the pre-open one, so nothing was cast.
  - **Enemy info sheet**, opened from the rat's own timeline token: same
    `CrawlPanel` family, 159.24 dp, stats as plain monospace lines.
    **The inspect cost no turn** — HP, mana, `Engaged 2`, timeline order and
    log content are identical before and after, and the handler emits a state
    copy that only sets `selectedActorId` and never touches `state.game`.
  - **Completion confirm**, opened by a real `Finish` tap on the bottom-floor
    stairs landing: a dialog with an explicit 1 dp `crawlRule` border, which
    stock Material does not draw, and stacked full-width `CrawlPill` actions
    rather than inline text buttons; 330.29 x 248.76 dp, centred. Dismissed
    with **Stay down here**, and the frame hashed byte-identical to the
    pre-`Finish` baseline, so the delve was not completed.
  - **Death overlay**, reached by *dying* — a one-field fixture delta
    (`hero.hp` 14 → 1, verified by `jq -S` diff) and then a real `Wait` that
    let the adjacent rat land the killing blow. No `isGameOver` flag was
    hand-edited. It is a full-bleed `crawlScrim` over the content box with a
    `crawlHeadline` title, dim body line and one pill — the barest of the four
    surfaces, with no bordered panel, which is the intended reading: AC11 asks
    that nothing render as stock Material, not that everything wear a panel.
  - **AC5's disabled half — PASS, and the cues are not hue.** The disabled
    `Drink` reads by **label weight and value** (w400 mid-grey #8A919E against
    w500/w600 near-white on every live chip) and by **icon opacity** (0.45
    against full). Its inertness was proved by tapping it and showing nothing
    changed. **Worth recording:** the seam's fill/border cues
    (`crawlRecessed`/`crawlDisabledRule`) compress to a few RGB levels beneath
    the death scrim, so in the only state where a disabled chip is reachable,
    weight and icon opacity are what actually carry the distinction. They do
    carry it, in colour and in greyscale alike.
  - Architect re-verification: all four greyscale twins are pixel-exact
    conversions (0 differing pixels each); the death fixture's delta really is
    the single `hp` field; the death overlay was read by eye and the dimmed
    `Drink` is separable from `Wait` and `Pack` beside it.
  - **Device-path trap, recorded for later capsules:** the live save is
    `app_flutter/save.json`, *not* `files/app_flutter/save.json`. Capsule E
    mis-staged to the wrong path first, caught it because the launched scene
    was capsule D's leftover ending rather than the fixture, and removed the
    bogus subtree. Architect confirmed `files/` now holds only
    `profileInstalled`. Every later capsule hash-checks the copy on device
    before launching.
- **Capsule F, the town-side sweep — PASS on all six screens and both pack
  routes. AC12 is settled.** Reached by dying and taking `Return to town`,
  then World → Stonebridge → Town → Character → Spells → Pack, back to World
  → Heroes, and finally a road encounter for the crawl-reached pack.
  - **No crawl-seam leakage anywhere**, established two ways: by eye, and by
    grepping `packages/app/lib/town/` and `packages/app/lib/world/` for every
    crawl-owned token (`crawlPanel`, `crawlRule`, `CrawlPanel`, `CrawlPill`,
    `crawlChip`, `crawlScrim`, `crawlHeadline`, `crawlBodyDim`) — **zero
    matches in either directory**. The only crossing runs the other way, and
    it is the one Unit 12's suite already pins: `CrawlPackScreen` imports
    `panel`, `ink`, `mono`, `monoDim`, `Heading` and `MaterialRows` from
    `town_style.dart`, so the crawl borrows the town's ink on purpose.
  - **The baselines predate the build**, coming from units 6, 7, 8 and 10, so
    the per-screen pixel diffs (town 16.8%, character 27.0%, pack 11.7%,
    world 1.5%, spells 1.4%) measure build-age drift and real progression
    content, not Unit 12. That is a limit of the comparison and it is stated
    rather than smoothed: the load-bearing claim here is the leakage result,
    which is independent of baseline age.
  - Roster has **no baseline anywhere in the epic's evidence**; it is judged
    PASS on internal consistency with the town's own type and row style, and
    UNKNOWN against any prior build.
  - Stonebridge's `Alchemist` door sits one scroll below the fold because a
    later illustration widget added height. Source-confirmed pre-existing,
    not a Unit 12 regression.
  - Architect re-verification: all seven greyscale twins are pixel-exact
    conversions.
- **Unrelated defect candidate, observed and deliberately not chased here.**
  On capsule F's first cold launch the app itself displayed *"your last save
  could not be read; an older one was restored"* and fell back to the
  previous slot. The unreadable file was capsule E's own post-death autosave,
  whose hash matched what capsule E recorded, so the file existed and was
  byte-readable — the **codec** refused it. `decodeSave` refuses a document
  whole rather than repairing it (`save_codec.dart` lines 144–172), and
  `SaveStore.load` then steps down a slot by design, so the fallback
  behaviour worked exactly as written. What is *not* established is why a
  post-death save was refused. The bytes are gone — later real play in the
  same capsule overwrote them — and capsule F never pulled them, which it
  reported plainly rather than reconstructing a plausible story.
  - **Scope:** Unit 12.5's non-goals exclude the save schema, `core` and
    `content`, so this is not repaired here. It wants its own contract and a
    reproduction under `flow-debugging`: stage a hero at 1 HP, die, then try
    to reload the resulting `save.json` through `decodeSave` directly.
  - **Note the hazard honestly:** if a post-death autosave is genuinely
    unreadable, a player who dies loses a slot and silently falls back one
    save. The user's own two slots are unaffected — they are backed up, were
    restored once already during the pause, and every fixture write in this
    unit targeted the disposable current slot.
- **Capsule G, the density ceiling — both thresholds PASS, and one real
  defect found.** The eleven-chip row rendered exactly as Main derived it
  from source: `Drink (10)` · `Firebolt 2` · `Frost Lance 4` · `Mend 3` ·
  `+3` · `Wait` · `Pick up` · `Gather` · `Pack (19)` · `Ascend <` ·
  `Finish` — three runs, greatest label line count 2, no word split, no
  ellipsis, no label touching a border, **no verb hidden**. The engine
  refused no part of the fixture.
  - **Chrome 580.95 dp against the 600 dp threshold — PASS** with 19.05 dp of
    margin, the tightest in the unit. The plan modelled ~561 dp, so again the
    device is ~20 dp worse than the model and the same way.
  - **Map 285.33 dp against the 244 dp floor — PASS** with 41.33 dp of
    margin: **7.93 rows of sight**, about four tiles each way. The plan
    modelled ~283 dp, so this figure lands almost exactly on the model.
  - **The map plays.** Hero and monster glyphs are legible, the room shape
    reads, and the stairs question is moot because the hero is standing on
    them. Correction C1's four contract-level remedies are **not** needed.
  - **AC6's truncation logic is correct and silent**: two ring tokens, then
    the queue stops at the first unseen actor with no placeholder, ellipsis
    or trailing hero token. The unseen actors came from `u125-a-fixture.json`'s
    own unmodified engine data, not from forcing.
  - **The defect, and it is Unit 12's:** at this density the dungeon map's
    Flame canvas is **not clipped to its `Expanded` box**. It paints roughly
    144 px (~55 dp) *above* its own top hairline, and because the map slot is
    a later sibling in the `Column` than `BattleDock` it paints opaquely over
    the dock — cutting both ring tokens in half and hiding the actor words
    `You` and `the wight¹` entirely. Two captures three seconds apart are
    byte-identical, so it is a settled render rather than a transition frame.
    Architect confirmed it by eye in `u125-g-battledock-bleed-color.png`.
    Source confirms the shape of it: `game_screen.dart` lines 80–136 wrap the
    map in a foreground-decorated box and a `Stack` with **no `ClipRect`**.
    - So **AC6 fails visually at maximum density** while its logic passes.
      A player at the ceiling cannot tell from the timeline which named actor
      `NEXT` refers to.
    - The reported 8.76 dp shortfall in the log peek's box is best read as a
      measurement artifact of the same bleed — the peek's top border is
      covered — not as a second defect. Capsule B measured the peek at
      exactly its coded 104.0 dp.
    - **A `ClipRect` is the obvious patch and may be the wrong one.** If the
      Flame viewport is rendering more rows than its box, clipping hides the
      overflow but leaves the camera showing a viewport the box does not own,
      which would quietly invalidate the rows-of-sight figure this capsule
      just measured. The fix wants a root-cause diagnosis of why the canvas
      exceeds its constraints, not a cosmetic clip.
    - **Authority:** this is past the contract's "one constants-only tuning
      pass", so the correction is contract-level and the user's call. Any fix
      reopens the stability barrier: rerun the `packages/app` suite, take a
      scoped closure review on the changed tree, and re-capture capsule G,
      whose evidence is the only capsule the fix would invalidate.
- **Save slots restored after capsule G and verified.** `save.json`
  `18995c4c…b46d3` MATCH and `save-previous.json` `8909f70c…a9b11` MATCH
  against the recorded backups, same SHA-256 scheme. Note that
  `save-previous.json` had drifted to `6e56f999…a9b6` during the capsules'
  real play — the app's own save rotation moves current to previous — which
  is exactly why both slots were backed up before any install and why
  restoration reads from the backups rather than from the device.
- **Save slots restored at the pause.** Both slots were restored from the
  recorded backups and re-verified under the same SHA-256 scheme:
  `save.json` `18995c4c…b46d3` MATCH, `save-previous.json`
  `8909f70c…a9b11` MATCH. The device therefore holds the user's own saves,
  not a fixture. `/data/local/tmp/save10.json` dated 2026-09-15 is
  pre-existing residue from an earlier session and was left alone.
- Repository is clean apart from this untracked checkpoint. The emulator was
  left running and untouched.

## Open findings for the architect to route on resume

- **AC5's disabled half is unreachable in every scene captured so far, by
  construction.** Spell chips are never disabled — an unaffordable spell
  stays live and is refused with a message — and `Drink` disables only on
  game-over. So the only disabled chip in the whole crawl is `Drink` with a
  potion carried on a dead hero. Capsule E must therefore stage a game-over
  hero *carrying a potion*, or AC5's disabled half closes on suite evidence
  alone. Recorded by capsule A, confirmed by Main at source
  (`game_screen.dart` lines 239–257, 280–287).
- **AC6's silent-truncation clause was not exercised** by capsule B: both
  monsters in that scene were already known, so the queue rendered in full.
  Either a later scene must hold an unseen actor deeper in the schedule, or
  that clause rests on the suite.
- **Spell chips do not all carry an icon, and that is by design.** Settled by
  Main at source: `ActionIcon.forSpell` (`art_assets.dart` line 31) maps only
  `firebolt` and `mend` and returns null for everything else — the dartdoc
  says "null when no asset matches it exactly". Unit 12 ships no new assets,
  so `Frost Lance`, `Banish`, `Ward` and `Bind` render word-only with their
  school marking glyph. AC4's family claim survives it: widths, heights,
  border and label type are shared; the icon slot is optional, not missing.
  Recorded as a known consequence of the Unit 10 master set's coverage, not
  a defect, and not a reason to expand scope here.

## Exact next action — none; superseded 2026-09-18 by Unit 13's intake

**Unit 12.5 is closed.** Capsules A through G all ran, the restoring capsule
ran after them, and both device save slots were verified byte-identically:
`save.json` `18995c4c…b46d3` MATCH and `save-previous.json`
`8909f70c…a9b11` MATCH under SHA-256. The three dp gates passed as measured —
exploration 331.1, typical combat 438.1, worst legal combat 580.95 against
600 — and the full result is in `LEDGER.md` under "Unit 12.5 — the crawl
device gate, closed".

The text that stood here was a mid-pass forward pointer written while
capsule D was in flight. It described dispatches that have since completed
and live device state that no longer exists. It is removed rather than
rewritten, because a closed unit has no next action.
