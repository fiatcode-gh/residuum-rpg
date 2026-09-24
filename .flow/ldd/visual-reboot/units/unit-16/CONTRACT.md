# Unit 16 Contract — ASCII Atmospheric Crawl Parity

Status: approved by user on 2026-09-23; physical-device target and the
fresh-install/absent-data recovery branch were explicitly approved by the user
on 2026-09-23.

Observed head: `374ee775e6fd1c29519dab8fe9d597dd38650593`.
Source proposal: `external/unit-16-ascii-crawl-parity-handoff/proposed-units/unit-16.md`.
Source recon: `units/unit-16/recon.md`.

## Outcome

The primary crawl screen reads as a deliberate, atmospheric ASCII roguelike, substantially closer in composition and value hierarchy to the four approved U16 references. The map stays a readable semantic grid. Light, darkness, depth and restrained motion add atmosphere without becoming another source of gameplay information.

## In scope

- Render active dungeon terrain as glyphs: `#` walls, `.` walkable floor, `<`/`>` stairs, and existing actor, item, and material marks. No active map image, textured terrain, rubble overlay, or sprite may carry terrain or actor identity.
- Preserve authoritative knowledge state: visible terrain may be fully lit; remembered terrain remains dim; unknown terrain reveals nothing. Actors/items retain their current visibility and secrecy rules.
- Add code-driven, deterministic presentation lighting and a clearly non-semantic depth/backdrop field behind the glyph map. Lighting respects current game visibility and never computes a second FOV. The backdrop contains no topology, props, or interactable-looking shapes and cannot alter projection or hit testing.
- Bring exploration, combat/targeting, recent-event, and expanded-log compositions toward their matching supplied mock while using only real game facts and actions. Parallax may move only the depth field; omit or reduce it if it harms readability or gesture/projection clarity.
- Use neutral exact-geometry placeholders only where a real consumer needs a future asset. Record each introduced slot's consumer, purpose, final envelope, safe area, alignment, transparency/tint/filter behavior, fallback, and evidence in a tracked placeholder-slot table. Existing shipped UI icons remain usable where appropriate. No generated art.

## Protected boundaries

No gameplay/core/content/save-schema, encounter-generation, map-topology, FOV, RNG-outcome, balance, action-vocabulary/count/dispatch, information-secrecy, or save behavior changes. Preserve:

- the 36 dp `cameraCellSize` and `GridGeometry.camera` as the coordinate/hit-test authority;
- existing tap, pan, long-press, map-first melee, and arm → target → tap behavior;
- stable U15 action ids, measure-all-candidates/shortest-legal fitting, and armed/unarmed map-rectangle equality;
- existing timeline schedule/identity semantics, `LogCategory`, event ordering, log follow/unread behavior, and causal text;
- the crawl map as an `Expanded` allocation and target-device worst-case chrome strictly below 600 dp;
- accessibility: important state/category distinctions never depend on hue alone; no red-versus-green-only distinction;
- OS-level greyscale capture is not an acceptance gate; visual proof uses colour device evidence with redundant non-hue cues.
- existing town/environment illustrations and historical dungeon-art masters.

The mock does not authorize adding `Torch`, `Hungry`, `Clear`, `Seed`, `Auto-walk`, `Help`, fake settings/menu controls, dotted range/path mechanics, or sample inventory/stats unless the current product already exposes an equivalent authoritative fact or action. `RESIDUUM` branding is optional only if its real layout cost fits the locked density boundary and it does not introduce fake controls.

## Excluded

- Image generation, semantic image editing, new dungeon/UI icon families, creature sprites, dungeon textures, tile/prop/stair art, and generated backgrounds.
- Deleting historical asset masters or broad asset-pipeline cleanup beyond an implementation-plan-proven active decode/warm-up cutover.
- Changes to gameplay, state/content models, or interaction geometry.
- Redesign of non-crawl screens or environment art.

## Acceptance

1. The active dungeon is understood from glyphs alone; no textured image or graphic overlay supplies terrain topology or actor identity.
2. Terrain glyph identity and visible/remembered/unknown behavior remain correct; no hidden cell, actor, item, or topology leaks through light/backdrop.
3. Lighting and backdrop create visible value/depth separation while remaining subordinate and non-semantic. Repeating the same state/camera inputs gives the same presentation decisions.
4. If parallax ships, only the backdrop moves; world/grid projection, target geometry, taps, long-presses, and map allocation remain unchanged.
5. Exploration, combat/targeting, recent events, and expanded log are materially closer to their corresponding reviewed references without borrowing mock-only facts or mechanics.
6. Existing action semantics/count/dispatch, selection/target distinction, timeline secrecy, event/log behavior, armed state visibility, and accessibility cues remain intact.
7. Armed/unarmed states preserve map allocation; the 36 dp camera cell remains fixed; interaction resolves to the same logical positions.
8. Worst legal target-device crawl chrome remains below 600 dp measured on the
   user-attached physical Android phone over wireless ADB, not the usual AVD.
9. Every new future-art consumer has documented final geometry and a neutral fallback; no authored production asset is created or semantically edited.
10. Device state returns to its exact pre-capture condition. Use byte-identical
    backups/restoration when an existing app/data state is present. For the
    user-confirmed never-installed package case, record package/save absence
    before install, then remove the test installation and verify absence again.
11. Formatter, analyzer, and full `packages/app` tests pass; target-device evidence covers exploration, combat, targeting, expanded log, and worst legal density.
12. The accepted record identifies any old dungeon-art pipeline path made unused and separates historical asset cleanup from this unit.

## Evidence boundary

References establish appearance and composition, not game truth. The source repository governs every displayed fact and interaction. Automated widget/test dimensions do not substitute for device measurements. Visual acceptance uses target-device captures compared against the four references for map dominance, glyph readability, value/light hierarchy, backdrop separation, compactness, timeline/log/action rhythm, and target clarity.

## Next gate

The user explicitly pre-approved execution of the completed plan on
2026-09-23, contingent on conformance to this contract. On 2026-09-23, the user
also explicitly approved the fresh-install device path after confirming the
package has never held app data; restore the phone to its prior absent-package
state after capture. This authorized amendment is recorded in the canonical
ledger and resume pointer. Further material deviations return for approval.
No commits, publication, integration or release are authorized.
