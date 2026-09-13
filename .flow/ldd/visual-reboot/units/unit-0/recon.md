# Unit 0 — Design Baseline and Recon

Date: 2026-09-13
Status: complete; no production code changed.

## Authority reconciliation

- The approved mock at
  `.flow/evidence/visual-reboot/residuum_visual_reboot_approved_mock.png` is
  present and was inspected. It is visual and interaction direction, not
  literal game content.
- The external markdown handoff has no `FLOW-HANDOFF.json`; the current
  planning-handoff validator rejects the directory for that missing manifest.
  It is therefore retained as legacy external evidence. The existing ledger
  and current user instruction provide the approved design authority.
- Current source is authoritative for existing behavior and semantics. The
  locked visual-reboot decisions define intended changes.
- The durable product spec now lives at
  `docs/specs/2026-08-20-dungeon-game-design.md`.

## Behavior matrix

| Surface | Current source truth | Reboot disposition | First owning unit |
| --- | --- | --- | --- |
| Simulation, saves, content, balance, RNG | `core` owns immutable `GameState` and `step`; `app → content → core`; save v3 and M3 band controls bind | Preserve exactly. Flame never owns state, RNG, HP, actions, or persistence. | Every unit |
| Crawl projection and FOV | `glyphPlan` draws explored terrain, then nodes, visible litter, visible monsters, then hero; `visible` and `explored` govern knowledge | Preserve the source projection and no-geometry-leak rule. Replace renderer in Unit 1; graphical-glyph texture, fog, and light arrive in Unit 2. | 1, then 2 |
| Camera and map input | `GridGeometry.camera` uses fixed 36 logical-pixel cells, hero focus, clamped pan, and tile hit-testing; no zoom | Preserve tap/pan and camera bounds in Unit 1. Ease-back and an explicit recenter affordance are later interaction work; no pinch zoom. | 1, then 3 |
| Basic melee | Adjacent monster map taps are deliberately refused; explicit `Attack` arms the existing bump action in the battle shelf | Change to direct adjacent map melee and remove the explicit Attack shelf control only after it is proven. Rules remain the existing bump action. | 3 |
| Targeted abilities | Target spells arm in `GameViewState`; legal targets are currently stage-card targets; self spells cast immediately | Preserve arm/disarm and target legality. Move target selection and greyscale-safe marks onto the map. | 3 |
| Ability availability | `BattleSkillBar` wraps every known spell plus Attack and Wait; Pack exposes casts separately | Change presentation only: compact favorites plus overflow retains access to every known spell. No prepared-kit rule. | 3 |
| Battle time | `BattleDock` overlays the live map for reach holders; `_TurnChips` prints raw-name `NOW` / `IN n` prose | Replace prose with an interactive activation queue. Do not restore a full-screen battle board. | 4 |
| Actor identity | Core actor IDs are stable; UI and logs render raw names, so same-name enemies collide | Preserve core IDs. Derive deterministic encounter-local presentation labels shared by map, timeline, targeting, inspect, and log. | 4 |
| Event log | `GameViewState.log` is `List<String>`; `_MessageLog` is a fixed 104-pixel reverse list; `describeEvent` has pre-step actor IDs and names | Preserve exact history and causal ordering. Change viewport to about three scrollable lines with half/full overlay and non-disruptive new-entry return. | 5 |
| Character and Pack | `InventoryScreen` and town `CharacterScreen` duplicate long stats/spells/gear/materials/skills sections while sharing presentation helpers | Consolidate information architecture without changing item, spell, or transaction semantics. | 6 |
| Town, rooms, and roster | Town is a menu; Merchant, Bank, Inn, Character, Tavern, Forge, Alchemist are seven town doors. Heroes is a world action. Transactions/refusals are bloc/core-backed. | Reskin and simplify composition only. Preserve all door, count, price, refusal, camp, save, and roster semantics. | 7 |
| World and themes | Five-node content graph and day/danger travel economy; Flutter world screen owns route interaction | Reskin graph and add theme presentation parity only. Preserve discovery, travel, roads, encounters, and node semantics. | 8 |

## Current architectural seam inventory

### Crawl and scene boundary

- `packages/app/lib/game/game_screen.dart` — `GameScreen` composes the crawl
  route: `BattleDock`, `GlyphGrid`, `BattleSkillBar`, status, contextual
  controls, fixed log, and exit/death overlays. It is the Flutter shell seam
  around a future dungeon `GameWidget`.
- `packages/app/lib/game/game_bloc.dart` — `GameViewState` owns the immutable
  core `GameState` plus view-only `log`, `autoPath`, `walkId`, `pan`,
  `hasFled`, and `ArmedAction`. `GameBloc` maps UI events to core actions via
  `_act` and `_afterAction`, then formats core events with `_describe`.
- `packages/app/lib/game/glyph_grid.dart` — current `GestureDetector` maps
  taps and pan deltas through `GridGeometry`, while `_GlyphPainter` consumes
  a read-only `GameViewState` and target IDs. This is the renderer replacement
  seam.
- `packages/app/lib/game/glyph_plan.dart` — pure projection from `GameState`
  and marked IDs to draw-order `GlyphCell`s. It is the source projection to
  keep renderer-independent at Unit 1.
- `packages/app/lib/game/grid_geometry.dart` — camera math: fixed
  `cameraCellSize = 36`, hero-centering on overflowing axes, clamped pan, and
  `positionAt` hit-testing. This is the authoritative interaction geometry.
- `packages/app/lib/game/battle_view.dart` — current dock over map, stage-card
  inspect/targeting, `NOW` / `IN n` prose, explicit Attack, full spell wrap,
  and Wait. Timeline, compact shelf, and map-first targeting replace parts of
  this surface in later units.
- `packages/app/lib/game/event_messages.dart` — `describeEvent` formats core
  events with a pre-step actor ID-to-name map. This is the safe future seam for
  presentation labels; core event shape need not change for duplicate names.
- `packages/app/lib/game/inventory_screen.dart` and `spell_row.dart` — Pack
  and reusable spell presentation; there is no current favorites or overflow
  model.
- `packages/app/test/game/glyph_plan_test.dart`, `grid_geometry_test.dart`,
  `game_bloc_test.dart`, `battle_view_test.dart`,
  `battle_characterization_test.dart`, and
  `battle_flow_characterization_test.dart` characterize projection, geometry,
  BLoC behavior, dock behavior, and the current map-tap refusal.

### App, world, town, and management boundary

- `packages/app/lib/main.dart` — `_Session` owns `TownBloc`, `WorldBloc`, the
  autosaver, and route stack. `_openCrawl` is the sole dungeon entry;
  `_openRoadFight` opens a separate unsaved encounter route.
- `packages/app/lib/world/world_screen.dart` and `world_bloc.dart` — world
  menu, route day/danger, travel/refusal notices, road fight instructions,
  rumors, and the world-to-town/crawl navigation seam.
- `packages/content/lib/src/world.dart` — authoritative five-node graph:
  Stonebridge, Northgate, Crypt, Sea-Cave, and Ruined Keep.
- `packages/app/lib/town/town_screen.dart` and `town_bloc.dart` — the town menu
  and all profile-backed management state. The seven town doors are Merchant,
  Bank, Inn, Character, Tavern, Forge, and Alchemist.
- `packages/app/lib/town/merchant_screen.dart`, `bank_screen.dart`,
  `forge_screen.dart`, `alchemist_screen.dart`, `inn_screen.dart`,
  `tavern_screen.dart`, and `roster_screen.dart` own the current transaction
  and roster presentations. Their bloc/core results and refusals are product
  behavior, not decoration.
- `packages/app/lib/town/character_screen.dart`,
  `packages/app/lib/game/inventory_screen.dart`, and
  `packages/app/lib/game/item_presentation.dart` expose the Character/Pack
  duplication and existing shared presentation helpers.
- Widget proof is concentrated in `packages/app/test/widget/`, including
  `world_screen_test.dart`, `craft_rooms_test.dart`, `merchant_screen_test.dart`,
  `bank_screen_test.dart`, `character_screen_test.dart`,
  `disabled_controls_test.dart`, and roster refusal coverage.

## Corrections to inherited assumptions

1. The approved mock is present at the requested evidence path. Mock placement
   is not an open question.
2. The external markdown handoff is not a protocol-valid manifest bundle. Its
   approved design remains accepted through the current ledger/user direction;
   its implementation claims were independently rechecked.
3. The handoff's `CrawlScreen` / Flame scene is conceptual. Current source uses
   `GameScreen`, `GlyphGrid`, `CustomPainter`, and `TextPainter`; no Flame
   dependency or `GameWidget` exists.
4. Current adjacent monster map taps do not bump-attack. The characterization
   test pins the watched refusal. Direct melee is a later approved behavior
   change, not an existing seam to preserve in Unit 1.
5. Current battle time is only raw-name `NOW` / `IN n` prose, not a timeline;
   no timeline interaction or duplicate identity layer exists.
6. Current camera snaps pan to the hero after state changes. It does not ease
   back or offer recentering.
7. Current log is `List<String>` with a fixed 104-pixel reverse viewport. It
   has neither structured entries nor drawer, auto-follow state, or new-entry
   count.
8. `describeEvent` already receives actor IDs and a pre-step name map. It is a
   viable label-decoration seam; changing core event contracts is unnecessary
   for the reboot.
9. The handoff's concrete town destination `Market` is stale. Source names the
   destination and screen `Merchant`; Heroes is a WorldScreen action, not a
   town door.
10. Character and Pack duplication is real UI composition duplication, not
    duplicate core ownership. `Profile` remains town-owned; live `GameState`
    remains crawl-owned.

## Recommended execution ordering

Keep the proposed order: **1 → 2 → 3 → 4 → 5 → 6 → 7 → 8**.

Recon confirms the dependencies rather than requiring a reorder:

- Unit 1 establishes a renderer/input bridge over the existing projection.
- Unit 2 makes that renderer visually distinctive without interaction churn.
- Unit 3 moves interaction and action ownership to the map/shelf.
- Unit 4 then binds map, targeting, timeline, inspect, and event formatting to
  the same presentation identities.
- Unit 5 follows Unit 4 so the expanded history starts with identity-correct
  text, while retaining the existing string history.
- Units 6–8 remain management, town, and world presentation work after the
  crawl grammar is stable.

Units 4 and 5 are conceptually separable after Unit 3, but both touch
`GameScreen` and log/event presentation. Keep them sequential to avoid
competing writers and to land identity before the drawer.
