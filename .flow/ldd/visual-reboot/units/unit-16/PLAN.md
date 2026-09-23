# U16 — ASCII Atmospheric Crawl Parity: execution plan

Status: **execution-grade; user pre-approved execution on 2026-09-23, conditional on conformance to the approved contract**. Governing WHAT: [CONTRACT.md](CONTRACT.md), approved 2026-09-23. Source recon: [recon.md](recon.md). Base `374ee775e6fd1c29519dab8fe9d597dd38650593` on `main`, checked 2026-09-23. App source/tests match base; worktree/index contains shared LDD intake/contract changes (user-owned; do not discard), currently staged. A changed revision needs targeted revalidation of touched seams. Main must execute on a suitable feature checkout; no feature work on `main`.

Appearance references (visual, never game facts):

- `.flow/ldd/visual-reboot/external/unit-16-ascii-crawl-parity-handoff/reference/ascii-atmosphere-art-bible.png`
- `.flow/ldd/visual-reboot/external/unit-16-ascii-crawl-parity-handoff/reference/ascii-exploration-mock.png`
- `.flow/ldd/visual-reboot/external/unit-16-ascii-crawl-parity-handoff/reference/ascii-combat-targeting-mock.png`
- `.flow/ldd/visual-reboot/external/unit-16-ascii-crawl-parity-handoff/reference/ascii-expanded-log-mock.png`

The external `IMPLEMENTATION-STRATEGY.md` is partial. Actual seams verified: `glyphPlan` already projects all terrain/actors/nodes/items in ordered, visibility-safe cells; `glyphCellsAboveMaterial` currently discards ordinary terrain; `MaterialComponent` paints every material/image/decoration; `DungeonSceneSnapshot` holds both projections; `GameWidget` supports `backgroundBuilder` beneath its render surface (Flame 1.38.2); `GameScreen` allocates `CrawlStatus`, conditional `BattleDock`, `Expanded` scene, 104dp `LogPeek`, single `CrawlActionRow`, then overlays `LogDrawer`. Road fights share `GameScreen` and regional palettes. Target-device U15 worst chrome is 591.238dp, leaving only 8.762dp before the strict 600dp ceiling. Widget fonts differ from hardware; no headless measurement proves that ceiling.

## Locked architecture and cutover

1. **Semantic foreground.** `glyphPlan(game, palette, …)` remains the *only* active terrain/actor/item/node projection. `DungeonSceneSnapshot` keeps immutable `cells`, columns/rows, focus/pan; removes `material`. `_DungeonScene._synchronizeComponents` consumes *all* `cells`, ordered by `GlyphLayer`, never `glyphCellsAboveMaterial`. Simplify `glyphMarkTreatment(GlyphCell cell)` by deleting the now-obsolete `semanticTerrain` flag; all terrain glyphs keep scale 1.0 while actor hierarchy/halo/outlines remain. `_GlyphComponent` retains 36dp `cameraCellSize`, stable `GlyphRenderId` reuse, badges, halo, square marked outline and circle selected outline. `GridGeometry.camera` alone owns camera origin and tap/long-press positions; no rendering layer installs event handlers or transforms world glyphs. Keep the clipped viewport. Unknown cells have no glyph component; remembered nodes/terrain stay at `rememberedOpacity`, monsters/litter only visible. No image/texture/material component in the active world. Move `dungeonVoid` from the retired material renderer to `dungeon_scene.dart` before deleting its source.
2. **Active decode cutover after foreground (Task 02).** Task 01 may hand off a correct, buildable glyph scene while the pre-existing boot still decodes unused dungeon art; this is a temporary known efficiency debt, not a semantic dependency. Task 02 closes it independently: `main()` still calls `warmUpArt()` to precache the three `EnvironmentArt` illustrations, but warm-up no longer decodes `MaterialArt` or `TerrainOverlayArt`. Move that function and `_precache` into new `art/warm_up.dart`; remove unused `art/dungeon_art.dart`. Move historical `RegionMaterial` from `dungeon_palette.dart` into `art/art_assets.dart` so the historical catalogue remains independently testable. Retain `MaterialArt`/`TerrainOverlayArt` catalogue entries, `assets/visual/dungeon/` manifest entry and image files as historical catalogue entries, not runtime consumers. Replace the material-decode expectation in `warm_up_test.dart` with environment pre-cache/no dungeon-image requests observed through a behavioral bundle-load spy. `art_catalogue_test.dart` retains historical file/path coverage without `DungeonArt.none()` runtime assertion.
3. **Light.** Task 03 adds `terrainPresentationInk(GlyphCell cell, Position hero)` in `glyph_marks.dart`, returning `cell.ink` unchanged for non-terrain or `cell.opacity != fullOpacity`. For visible terrain only, calculate `d² = (x-hx)²+(y-hy)²`, `strength = max(0, 1-d²/25)`, and `Color.lerp(cell.ink, const Color(0xFFE8C58A), 0.38*strength)!`. Preserve opacity; no alpha overlay, no second FOV, no time/RNG. Snapshot adds `heroPosition` from `state.game.hero.position` (not `cameraFocus`, which can follow a selected actor); `_GlyphComponent` uses the resolved ink for glyph text and recomputes it on projection/hero change, not pan-only reuse. Keep actor/node ink and target geometry untouched except strengthen the existing marked square stroke to 2dp and warm-red `0xFFE87C70`, while selected remains the existing circle: two simultaneous outlines still read by shape. Target ink never signals legality outside `marked`.
4. **Depth.** Task 04 adds `game/dungeon_depth.dart::DungeonDepthPainter` behind the Flame surface via `DungeonSceneHost`'s `GameWidget.backgroundBuilder`: an `IgnorePointer`/`ExcludeSemantics` `CustomPaint` filling exactly its viewport. Paint a uniform charcoal base plus broad radial gradients (one cool charcoal-blue haze and one dim warm haze), no text, symbols, grid-aligned points, map state, wall/door/path outlines or noise keyed to topology. `shouldRepaint` is false; shaders/paints are prepared per size in the painter or cached by size, not randomized/per-cell/per-frame; gradients remain subordinate to glyphs. `GameWidget`'s own opaque background remains `dungeonVoid`; backgroundBuilder is behind the transparent game render. **No parallax in U16**: this deliberately eliminates motion ambiguity and preserves projection/tap identity while meeting the contract's optional parallax boundary. If Flame paints an opaque layer above backgroundBuilder in an actual runtime, use the same viewport-only painter before `super.render` inside `_DungeonScene.render` with explicit clip; never place it in world-space or in `game_screen.dart` above hit targets. This conditional is an API placement correction, not freedom to change appearance/meaning.
5. **Chrome.** Task 05 makes `CrawlStatus` a quiet framed factual band *inside its existing allocation*, preserving one location/battle/depth row plus the existing HP/mana row, keys, words, condition/ward and hidden mana behavior. No title/branding/menu/seed/status chip or extra row. Do not increase worst-case status height; keep the `Expanded` map. Task 06 compacts `BattleDock` within its existing envelope: retain `projectActivationQueue` unmodified, NOW/NEXT labels, keyed ordered repeated tokens and actor-inspection semantics, but reduce `crawlTokenCell` from 44 to 36dp and give current hero a heavier value/border than upcoming tokens; keep token width 76dp, horizontal scrolling and at least 44dp interactive token height. No turn counts or invented data. Task 07 uses `LogPeek`'s existing 104dp fixed envelope for a small `RECENT EVENTS` heading above the real newest sentences; expanded `LogDrawer` shows `RECENT EVENTS` plus the truthful full-entry count, its existing category glyph/word and unchanged chronological order/follow/unread/handle transitions. No timestamps (the app does not own them). If the heading prevents a readable recent sentence at the real phone width, reduce interior padding within 104dp rather than grow the peek. Keep drawer overlay, not map reflow.
6. **Action integration without regression.** `CrawlActionRow`, `_fitFor`, `_actionsFor`, `ActionIconImage`, `readiedSpellCount`, stable action IDs, labels, counts, art/no-art behavior and dispatch remain unchanged. This is a deliberate zero-mutation decision: U15's one even chip shelf already occupies the mock's bottom action role, and the worst device state has <9dp slack. The new factual top/log frames and glyph map make that existing shelf part of one hierarchy. No fake `Inspect`, `Auto-walk`, `Help`, `Torch`, `Hungry`, `Clear`, `Seed`, equipment, hit percentages, dotted paths or clock. Selection is the existing circle, marked legal targets the existing square (stronger stroke), armed chip retains word/border. If final device composition cannot meet parity without action layout change, return to plan/design with measured evidence rather than quietly altering action count/fit.

## Placeholder-slot register (tracked in this plan)

| Candidate | Decision and real consumer |
|---|---|
| Action pictogram | **No new slot.** `action_icon.dart::ActionIconImage` already hosts shipped matching icons at 18×18dp, untinted, medium filter, excluded from semantics; `CrawlActionRow` reserves the same 18dp icon height for word-only controls. Action label carries meaning. |
| Recent-event category | **No new slot.** `log_drawer.dart::_LogRow` already uses a 24dp column with a 20×20dp inset mark well and `LogCategory.mark`/accessible `.word`. Keep glyph, do not add an image well or alter the category vocabulary. |
| Status/utility | **No new slot.** `_BattleGlyph` is an 18dp factual glyph/word pair and `ResourceMeter` is text/fill. No fake utility consumer exists. |
| Timeline | **No new slot.** `_TimelineCell` is a glyph/word token, not future art; Task 06's 36dp circle remains glyph-only. |

**Introduced future-art consumers: zero.** Thus no final-art envelope, safe area, alpha/tint/filter, alignment, fallback or image hit target is invented. Existing shipped image host and glyph wells above are actual geometry, not U16 future-art promises; U15's unrelated `FramedRow` 44×44/36×36 medallion stays untouched. On device, capture action/log/status/timeline wells as evidence that none is a blank future-art dependency. Any newly proposed art consumer is a contract/plan change requiring its complete exact slot table *before* implementation; no asset generation in this unit.

## Fresh executor graph

Sequential in one suitable feature checkout, **one fresh executor session per capsule**, no overlapping writers; each task reaches a valid tested handoff state:

`01-ascii-renderer` → `02-dungeon-decode-cutover` → `03-visibility-light` → `04-nonsemantic-depth` → `05-factual-status` → `06-compact-timeline` → `07-recent-events` → Main integration/review/device gate.

Task 01's foreground and Task 02's boot decode have separate Red→Green proof and valid intermediate handoffs (a usable ASCII scene temporarily retaining the old startup decode), so they are split. Tasks 03/04 independently prove light/backdrop; Tasks 05/06/07 independently alter status/timeline/log. Task 01 retires material-only painter/plan/tests and `glyph_marks_test.dart`'s material-only assertions, while Task 02 retires now-unneeded runtime art decode/catalogue wrapper. No setup-only task. File-level ownership is in each brief.

## Verification ownership and final gates

Each executor records a failing behavioral proof first, makes the slice green, formats touched Dart (`dart format <touched paths>`), then runs `flutter test <owned test files>` and `flutter analyze` from `packages/app` on its stable handoff tree. Do not suppress focused self-verification because Main will verify. If deletion affects stale tests, replace only tests that protect observable active behavior and remove tests devoted solely to retired material implementation; do not re-pin incidental private wiring. Main independently inspects actual changes/receipts, then runs **once on final tree** from `packages/app`:

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Main additionally checks `git diff` scope against contract; no `core`, `content`, save schema, authored asset or UI outside crawl changes, no runtime dungeon decode/material references, old catalogue masters retained, U15 action identities/fit and gesture paths untouched. Run one independent acceptance review/closure of coherent final tree **before** device installation. A subsequent production/asset/build correction reopens scoped acceptance and affected proofs. The U15 591.238dp device figure is baseline, not a substitute for new measurement.

The user explicitly pre-approved execution on 2026-09-23, contingent on this plan remaining inside the approved contract. This authorization applies only to the plan and checkout named here; material plan/contract deviations require escalation. It does not authorize commit, push, pull request, merge, release, or other publication.

**Target-device gate (Main, not task executors):** The user directs all U16
device capture on their attached physical Android phone over wireless ADB,
replacing the usual AVD/`Medium_Phone`. Do not launch or substitute an AVD.
Before the first ADB command/device action, Main writes a durable recovery
checkpoint under `.flow/checkpoints/` and records it in the ledger. Follow
`.flow/ldd/visual-reboot/units/unit-12.5/DEVICE-CHECKPOINT.md` without carrying
forward that emulator's identity.

Read-only discovery found the attached vivo I2219 (Android 16/API 36,
1080x2408 px, density 440) and confirmed `com.example.residuum_app` is not
installed (`pm path` has no result; package listing has no match; `run-as`
cannot enter it). No app or save state has been changed. The user explicitly
selected and authorized the following branch, confirming this package has
never held app data: record the app as absent and both save slots as absent
before a fresh installation; install the accepted tree and capture; then
uninstall the test app and verify the package is absent again. Do not claim
byte backups or hashes for save files that did not exist. Preserve all
unrelated phone state. If pre-install package presence contradicts the
recorded absence, or uninstall cannot restore absence, stop without clearing
data or using an emulator.

Record the user's confirmation, package absence, both absent save-slot states
and the safe uninstall restore path in `.flow/evidence/visual-reboot/unit-16-device/`
before installation. Confirm no app-specific external files exist for this
package before proceeding. Only after that receipt is complete may Main build
and install the accepted tree.

Capture colour evidence for exploration with visible/remembered/unknown,
combat timeline with repeat/hidden schedule fixture if available, armed target
and selected actor, half/full log with unread/follow, road encounter, and worst
legal 11-action density. Compare frames to four named references for glyph
readability, visual depth, map dominance, status/log/action rhythm and target
clarity, not mock text. Measure real screen chrome and map rectangle in dp
(exploration, typical combat, worst legal), **strict worst <600dp**, 36dp cell,
same armed/unarmed map rectangle and unchanged logical tap/long-press
positions. Check camera pan/recenter, backdrop topology independence, no
canvas bleed, and no clipped action word. Record active dungeon decode
path/count (expected zero) and retained historical files. At the end uninstall
the test package and verify package absence, confirming restoration of the
user-authorized pre-capture state. This user direction authorizes only U16's
local device evidence; it does not authorize commit, external publication,
merge or release.

## Plan quality gate

- **COR — PASS:** one source for glyph/knowledge truth; explicit scene/decode migration, hero-centered visible-only lighting, viewport-only nonsemantic depth, fixed input and map geometry, road palette, chrome/drawer/action interfaces and sequential ownership. Parallax omitted deliberately.
- **TTC — PASS:** each brief specifies a first failing behavioral proof, focused Green commands, negative secrecy/geometry/identity and density cases; Main's final app gates plus target-device measurements address hardware-only visual/font risk.
- **CRF — PASS:** obsolete active material painter/plan and subsequent boot decode retired in separate proven boundaries, historical catalogue retained, no generic effect engine/placeholder hosts/new art, no per-frame cell-wise allocation, independent proof clusters separated.
- **SEC — SKIP (no new trust boundary):** offline presentation only. FOV and hidden-actor secrecy remain explicit correctness/security boundaries, covered by negative proof. Device saves use exact backup/restore, never altered as implementation data.

Residual **evidence risks**, not open product decisions: Spectral device metrics may force smaller *existing* chrome padding rather than any additional row; backdrop legibility and category rhythm need real captures; `GameWidget.backgroundBuilder` translucency must be confirmed in a live render; target device may not naturally show every duplicate/hidden queue case (automated proof remains mandatory). If any 600dp, secrecy, parity or target geometry criterion cannot be met within the locked design, stop and return measured contradiction to Main/user rather than redesign in the executor.
