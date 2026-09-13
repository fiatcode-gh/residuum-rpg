# Residuum visual reboot — approved design handoff

Status: **Approved design direction**  
Target: `fiatcode-gh/residuum-rpg` Flutter app  
Primary device: phone portrait, about **411 × 923 logical px**  
Execution model: Flow/LDD; this document is an **external planning handoff**, not an execution ledger  
Approved visual reference: `residuum_visual_reboot_approved_mock.png`

## 1. Purpose

Reboot the presentation and interaction layer of the existing M3 Flutter game without discarding the game that already exists.

The goal is not “make the old UI prettier.” The goal is to establish a coherent phone-first product language around the strongest visual idea from the approved mock:

- a **graphical-glyph dungeon** rather than conventional pixel art;
- near-black negative space;
- smooth local lighting and occluded fog;
- deterministic stone/floor texture below the logical tile level;
- sparse, highly legible glyph actors;
- compact tactical chrome;
- information surfaces that are quiet, dark, engraved, and subordinate to the dungeon.

Interaction rules may change where the reboot clearly improves the phone experience. Existing core rules, content, deterministic simulation, economy, saves, and progression remain product truth unless a later LDD decision explicitly changes them.

## 2. Authority and interpretation

The approved mock is authoritative for **direction, hierarchy, density, visual tone, and interaction intent**. It is not a pixel-perfect implementation specification and it contains placeholder content.

When the mock conflicts with current game content, use the current repository as truth. Do not add gameplay objects, resources, places, classes, items, or actions merely because a mock illustration happens to contain them.

Examples:

- current dungeon terrain is wall / floor / stairs up / stairs down;
- decorative cracks, grit, dampness, stone variation, and stains are acceptable texture;
- a discrete coffin, barrel, pool, torch pickup, key, or other object must not appear as if interactable unless the game actually has that semantic object;
- town remains a destination/menu surface, not a free-roaming town map;
- Flame must not become authoritative game state.

## 3. Product principles to lock

### 3.1 Four-region responsibility rule

> **The map owns space and targets. The timeline owns time. The log owns causality. The action shelf owns verbs.**

Do not duplicate one concern across multiple large UI regions.

- **Map:** where actors and terrain are; direct spatial interaction; targeting marks.
- **Timeline:** who acts now, who acts next, and the immediate activation sequence.
- **Log:** what happened and why.
- **Action shelf:** abilities and contextual verbs that are not naturally expressed by tapping the world.

### 3.2 Tactical HUD rule

Permanent crawl HUD should answer only:

- where am I;
- what floor/depth am I on;
- what resources matter tactically right now.

Baseline persistent HUD:

- dungeon/context name;
- depth / deepest depth where meaningful;
- HP;
- mana where meaningful;
- temporary tactical state such as Ward when present.

Do not permanently spend crawl space on gold, equipment, pack count, enemy count, tutorial affordances, or other management data.

### 3.3 Map-first rule

The map should not become a decorative backdrop beneath controls. It is the primary play surface.

### 3.4 Progressive disclosure rule

Phone space is preserved by showing the immediate answer first and making deeper detail expandable:

- compact turn queue, not scheduling prose;
- 3-line log peek, not a permanent six-line panel;
- 3–4 primary/readied abilities plus overflow, not the entire grimoire at once;
- compact actor identity on-map, full details in inspect surface;
- short town destination rows, deeper transactional screens after selection.

### 3.5 Accessibility rule

No important state may rely on hue alone.

Identity, targetability, wounds, order, refusal, selected state, resistance/vulnerability, and danger must also be communicated by words, markings, position, shape, value, or numeric state.

## 4. Visual language

### 4.1 Dungeon: graphical glyphs

Do **not** pivot to a conventional sprite-tile roguelike.

Actors remain glyph-derived semantic forms:

- hero: `@`;
- monsters: their current creature glyphs;
- stairs retain a strong symbolic mark;
- gathering nodes and litter retain semantics from game state.

However, glyphs are rendered as graphical marks, not terminal text cells. They may have glow, outline, subtle shadow, scale emphasis, hit feedback, and deterministic presentation variation.

Terrain should be procedurally drawn from logical tiles:

- walls: masonry clusters, edge stones, chips, hairline cracks;
- floors: sparse dust, grit, scratches, tiny stones;
- remembered terrain: strongly reduced contrast/saturation;
- unknown terrain: near-black void, no geometry leak;
- visible terrain: full material response to local light.

### 4.2 Lighting and fog

Lighting is a signature feature.

Render conceptually as:

1. unknown void;
2. remembered terrain;
3. currently visible terrain;
4. props/nodes/litter that rules say should be shown;
5. actors;
6. local illumination treatment;
7. targeting and transient effects.

FOV remains rules-driven. Smooth gradients must never reveal unknown geometry outside visibility/knowledge.

Torch/light appearance may be warm and slightly irregular, but must be a presentation effect over authoritative visibility.

### 4.3 Deterministic texture

Procedural visual noise should be stable for a tile/world presentation seed or coordinate-derived hash.

Walking away and back must not visibly regenerate stone placement, scratches, or decorative marks.

### 4.4 Non-dungeon screens

The rest of the game should feel related to the dungeon without copying its glyph grid.

Use:

- near-black surfaces;
- restrained warm ink/gold accents;
- fine rules instead of heavy card borders;
- engraved/etched iconography;
- sparse atmospheric illustration;
- strong typographic hierarchy;
- minimal Material-style elevation/furniture.

Avoid turning every item and destination into a glossy fantasy card.

## 5. Crawl interaction contract

Interaction changes are allowed by this reboot.

### 5.1 Movement

- Tap adjacent walkable tile → move.
- Tap distant explored destination → auto-walk when current rules allow it.
- Drag map → pan camera.
- No pinch zoom in the first reboot unit.
- After a game action, camera should ease back toward the hero unless a deliberate view rule says otherwise.
- If manual pan can leave the hero substantially off-screen, provide a small recenter affordance.

### 5.2 Basic melee

**Remove the explicit Attack action from the phone combat shelf.**

- Tap an adjacent enemy with no targeted ability armed → basic melee attack.
- This can continue to dispatch the existing bump/move-into-occupied-tile rule if appropriate; a core combat redesign is not required.

This makes the commonest combat action spatial and direct.

### 5.3 Inspection

- Long-press an enemy → inspect without spending a turn.
- Tap an enemy that is not a legal direct melee target and no targeted ability is armed → inspect/select it, not attack.
- Tap an actor token in the timeline → highlight that actor on the map and optionally center it; no turn cost.

Do not make long-press the only inspection path. Timeline/name access must provide a discoverable alternative.

### 5.4 Targeted abilities

Flow:

1. tap ability in shelf;
2. UI enters targeting state;
3. valid targets are marked on the map;
4. matching timeline/identity marks use the same selected language;
5. tap a valid target → cast/use ability;
6. tap ability again or cancel affordance → disarm.

Self-cast abilities such as current Mend/Ward may still execute immediately.

Future ground-targeted abilities should use the same grammar with tile targets.

### 5.5 Contextual exploration actions

The lower shelf morphs by context rather than remaining one permanent navigation bar.

Examples:

Exploration baseline:

`Drink ×2 | Pack | More`

Standing on a gathering node:

`Mine/Gather | Drink ×2 | Pack`

At stairs:

`Ascend/Descend | Leave/Finish when valid | Pack`

Road edge / encounter-specific actions remain contextual.

Exact labels must come from actual game semantics, not mock placeholders.

## 6. Abilities and spell scaling

Do **not** use a Skyrim left-hand/right-hand spell metaphor.

Weapons already occupy equipment hands and Residuum's spell system is a learned grimoire, not embodied dual-hand casting.

### 6.1 First implementation: presentation favorites/readied actions

Combat shelf should expose roughly 3–4 frequently used abilities plus overflow and Wait. The approved mock demonstrates this pattern:

`Potion | Mend | Firebolt | +N | Wait`

Important: in the first reboot implementation, this is **progressive disclosure, not a mechanical restriction**.

- all known spells remain accessible;
- `+N` / More opens the complete ability list in a bottom sheet or compact overlay;
- opening the full list costs no game turn;
- selecting a less-used ability from overflow can arm/cast it normally.

The UI may remember favorites/readied slots as presentation state.

### 6.2 Later option: true prepared kit

If playtesting shows that a limited combat kit improves strategy rather than merely saving space, promote readied actions into an explicit game system in a separate LDD unit.

Do not smuggle that gameplay restriction into the visual reboot implementation without a decision.

## 7. Turn timeline redesign

The current scheduling prose (`NOW`, `IN n`, etc.) is too difficult to parse quickly. Replace explanation with the activation sequence itself.

### 7.1 Baseline presentation

At the hero's decision point:

`NOW  [@ YOU] › [r¹] › [r²] › [@ YOU]`

The player should be able to answer immediately:

- whose turn is it now;
- who acts next;
- who acts after that;
- when do I regain control.

Show the immediate useful horizon, normally through the hero's next activation plus a small amount of look-ahead if room remains.

### 7.2 Fast actors

Repeated activations should be shown literally:

`[@] › [k¹] › [k¹] › [r¹] › [@]`

Do not replace this with text explaining that the hound is fast.

### 7.3 Duplicate enemy identity

Multiple enemies with the same name/glyph need stable encounter-local identity.

Example:

- `r¹` = first relevant rat;
- `r²` = second relevant rat.

Use the same identity consistently across:

- map glyph/badge;
- turn timeline;
- targeting marks;
- inspect title;
- combat log where actor identity matters.

The label is presentation identity, not new core entity identity. Derive it deterministically from stable actor IDs/order for the current scene/encounter and keep it stable while the actor lives.

If only one actor of that ambiguous type is relevant, the numeric badge may be omitted to reduce clutter. When duplicates exist, show it everywhere that ambiguity would otherwise occur.

### 7.4 Timeline interaction

Tapping a timeline token should:

- highlight/pulse the corresponding actor on the map;
- center/reveal it if appropriate and permitted by current knowledge;
- never spend a turn.

Do not reveal an actor the hero does not currently know/see merely because it exists in simulation state.

## 8. Log redesign

Two lines are too little; six permanent lines steal too much map. Use a compact scrollable peek plus an overlay drawer.

### 8.1 Peek state

Default crawl log:

- about **3 visible lines** at the phone target;
- fixed compact height;
- vertically scrollable in-place for recent history;
- no timestamps by default;
- newest events at bottom/latest position;
- one clear handle/chevron for expansion.

The peek must remain useful during battle without dominating the screen.

### 8.2 Expanded states

Use an overlay, not a layout reflow that permanently shrinks the dungeon.

Suggested states:

- **peek:** ~3 lines;
- **half:** ~40–50% height, scrollable history;
- **full:** near-full-screen journal/history when deliberately opened.

Because the game is turn-based, covering the dungeon while reading history is acceptable.

### 8.3 Auto-follow behavior

- When the user is at the newest entry, new events keep the view following latest.
- If the user scrolls upward, auto-follow stops.
- New entries accumulate without yanking the viewport.
- Show a `↓ N new` affordance; tapping it returns to latest.

### 8.4 Structured identity concern

Current app log storage is `List<String>`, but current `describeEvent(...)` already receives actor IDs and a names map before rendering text (`packages/app/lib/game/event_messages.dart`). This is a useful seam.

For duplicate-enemy labels, prefer decorating `names` with encounter-local presentation identities before message formatting rather than changing core events solely for display.

Do not make tappable log-to-actor navigation a first-unit requirement. If later desired, consider a structured presentation log entry instead of parsing strings.

## 9. Screen-by-screen direction

The approved mock family establishes ten main surfaces. Their exact placeholder text/items are not authoritative.

### 9.1 Stonebridge / town

Current behavioral truth: town is a destination menu, not a walkable scene.

Visual direction:

- atmospheric Stonebridge header/illustration;
- compact hero status where useful;
- destination rows with strong labels and short purpose text;
- actual current destinations only;
- no decorative pseudo-actions that duplicate real rooms.

Current destinations to reconcile during recon include Market, Bank, Forge, Alchemist, Inn, Tavern, and Heroes. Preserve current navigation semantics.

### 9.2 Dungeon exploration

This is the flagship screen.

Priority order:

1. readable map;
2. fog/light/material treatment;
3. immediate HP/mana/depth;
4. 3-line log peek;
5. contextual action shelf.

No large character/equipment deck beneath the map.

### 9.3 Combat

Combat is a mode layered onto the crawl, not a replacement screen.

Add:

- compact activation timeline;
- duplicate actor identity where needed;
- map-first melee and target selection;
- combat ability shelf.

Do not restore a full-screen battle board.

### 9.4 Targeting

Targeted ability state should be visually unmistakable:

- selected ability remains visibly armed;
- legal targets receive consistent marks;
- invalid/unseen targets are not misleadingly highlighted;
- cancel/disarm path is obvious;
- targeting marks must remain readable in greyscale/value alone.

### 9.5 Expanded combat log

Use a dark overlay drawer with clear reading hierarchy. It should feel like opening history over a paused board, not navigating away from the crawl.

### 9.6 Character

Reduce the current "everything on one long page" feel.

Character should be the hero overview:

- identity;
- HP/mana/current derived combat stats;
- concise progression summary;
- links/modes for gear, magic, skills/progress as appropriate.

Reuse presentation components with Pack rather than duplicating every section independently.

### 9.7 Spells

Dedicated grimoire/list surface:

- school marking/name;
- spell name;
- concise effect/cost;
- known vs unavailable/locked only if current content supports that distinction;
- affordance for assigning favorites/readied presentation slots if implemented.

Do not introduce fictional spell categories/classes from the mock.

### 9.8 Pack

Pack is carried-object management, not another full Character page.

Use focused categories/sections if they improve scanning, but preserve actual item/material semantics and context-sensitive actions.

In crawl, Pack may offer actions valid in crawl. In town, Character/Pack should not invent actions the current rules do not support unless separately redesigned.

### 9.9 Forge

Keep current transactional grammar:

- smelting is counted work;
- quantity is selected before commit;
- exact costs/results visible;
- tempering keeps explicit refusal/reason;
- no crafting minigame.

Atmosphere belongs around a compact workbench interaction.

### 9.10 Tavern

Use a quiet atmospheric surface for the actual tavern functions: rumors/discovery and any current room-specific actions.

Do not substitute generic RPG "rest" functionality if the Inn owns sleeping/recovery in the current product.

## 10. Derived screens not fully approved by the latest mock

These must inherit the same system but should receive their own quick design pass before implementation if they materially diverge.

### World

Preserve the actual five-node/two-town/three-dungeon graph and route day/danger economy.

Direction:

- stylized etched/inked node-and-road map;
- discrete nodes, not free roaming;
- discovered/undiscovered treatment must preserve discovery semantics;
- selected route exposes days, danger, camp/resume implications, and travel action;
- do not invent geographic mechanics from decorative art.

### Merchant

Keep Buy / Sell / Buy Back semantics, stacked items, explicit prices, and refusal reasons. Reduce heavy card furniture.

### Bank

Use a clear carried-vs-safe two-zone composition for items and gold transfers. Preserve explicit transfer semantics.

### Alchemist

Compact counted recipe/workbench surface, analogous to Forge. No minigame.

### Inn

Intentionally spare, single-purpose screen. Price, effect, and current refusal/reason should be obvious.

### Heroes

Roster must clearly show active/suspended/fallen or other actual current states, location/crawl state, switching/resuming, creation, and irreversible deletion confirmation. Do not copy placeholder portraits/names/classes from the mock into game data.

## 11. Asset strategy

### 11.1 Procedural/runtime art

Render in Flame/Canvas, not as generated scene bitmaps:

- dungeon wall/floor material;
- fog/knowledge state;
- lighting;
- glyph actors;
- target marks;
- stairs and semantic tile marks;
- gathering/litter presentation;
- combat flashes/movement/death effects.

This keeps visuals state-aware, deterministic, scalable, and compatible with FOV.

### 11.2 Authored static art

Good candidates for generated-and-curated static assets:

- Stonebridge header/background;
- Forge background;
- Tavern/Inn/Alchemist atmosphere;
- hero portraits if roster/character design keeps portraits;
- world-map background treatment;
- occasional non-interactive decorative illustrations.

Generate assets as isolated production-oriented art at required aspect ratios, **without baked UI text/buttons**.

### 11.3 Icons

Prefer consistent vector/procedural/hand-authored iconography for high-frequency UI symbols. Generated raster icons are harder to keep legible and stylistically consistent at small phone sizes.

### 11.4 Art bible before bulk generation

Lock before producing a large asset set:

- palette/value range;
- warm-vs-cool lighting rules;
- line/engraving treatment;
- degree of realism;
- texture density;
- prohibited motifs that look interactable;
- portrait framing;
- room-background aspect ratios;
- icon stroke/weight language;
- accessibility contrast targets.

## 12. Architecture boundaries

### 12.1 Keep the existing dependency truth

Preserve the current architectural direction:

`app → content → core`

Core remains the rules/simulation authority.

### 12.2 Flame boundary

Use Flame for the dungeon viewport/scene, not for the whole application.

Conceptual structure:

```text
Flutter app
├── navigation / routes
├── town / world / inventory / management screens
├── GameBloc / presentation state
└── CrawlScreen
    ├── tactical HUD
    ├── turn timeline
    ├── GameWidget(ResiduumDungeonGame)
    ├── log peek/drawer
    └── action shelf

Pure Dart GameState
      ↓
GameViewState / presentation projection
      ↓
Flame scene
```

Hard rule:

> **Flame is never authoritative game state.**

A monster component represents an actor already present in game state. It does not independently own HP, RNG, combat timing, inventory, or rules decisions.

### 12.3 Input boundary

Flame may hit-test and emit interaction intents. Flutter/app state decides what those intents mean and dispatches core actions.

Examples:

- tile tap → existing movement/auto-walk pipeline;
- adjacent enemy tap → existing bump attack path where possible;
- enemy long-press → presentation inspect surface;
- targeted spell → existing `CastPressed`/equivalent with target ID;
- map drag → view-state pan/camera intent.

### 12.4 Existing useful seams

Recon these before changing them:

- `packages/app/lib/game/glyph_grid.dart` — current CustomPainter renderer;
- `packages/app/lib/game/grid_geometry.dart` — current phone-friendly fixed logical cell/camera behavior;
- `packages/app/lib/game/game_bloc.dart` — pan, auto-walk, armed targeting, contextual action/view state;
- `packages/app/lib/game/battle_view.dart` — current battle dock, turn chips, known-spell bar, enemy inspection;
- `packages/app/lib/game/event_messages.dart` — event→message formatting with actor IDs available before rendering;
- current town/world/character/inventory/merchant/bank/forge/alchemist/inn/tavern/heroes screens.

Do a fresh local recon before implementation; paths and details in this handoff are evidence, not permission to skip repo inspection.

## 13. Motion language

Keep motion restrained and turn-readable.

Suggested classes:

- immediate state change: 0 ms where clarity requires it;
- actor movement: ~100–160 ms;
- emphasis/hit/selection: ~180–250 ms.

Examples:

- hero/monster move: short positional interpolation;
- hit: small directional nudge/flash/mark;
- death: brief fade/collapse, then authoritative state disappears;
- target selection: pulse/frame, not a large arcade animation;
- camera: soft follow/ease, not constant floating motion;
- torch: mostly stable; very subtle variation only if it does not impair reading.

The simulation remains discrete even when presentation interpolates between states.

## 14. Explicit non-goals for the reboot

Unless a new decision is made, do not use this project to add:

- new monsters/items/dungeons;
- combat balance changes;
- generator redesign;
- new crafting recipes;
- story/M4 content;
- free-roaming towns;
- conventional sprite-sheet replacement of the glyph identity;
- decorative interactable-looking dungeon props unsupported by rules;
- full-app Flame migration;
- mandatory two-spell/hand casting;
- true prepared-spell gameplay restriction in the first pass;
- manual pinch zoom in the first pass.

## 15. Proposed LDD execution sequence

Create an active epic such as:

`.flow/ldd/visual-reboot/`

Store this document under that epic's `external/` directory as proposal/evidence if using the migrated Flow structure.

### Unit 0 — design baseline and recon

- ingest approved mock and this handoff;
- inventory current crawl/town/world/management screens;
- record current behavior contracts that must survive or be explicitly replaced;
- identify exact seams for Flame insertion;
- create a short interaction-preservation/change matrix.

No production code.

### Unit 1 — dungeon scene foundation

Goal: prove Flame-in-Flutter without changing game rules.

- add Flame dependency;
- embed `GameWidget` in existing crawl;
- project current game state into scene;
- render crypt terrain, hero, monsters, stairs, knowledge/FOV;
- preserve tap/pan movement behavior through existing app interaction layer;
- retain fallback/removable path until the proof is accepted.

Acceptance: a crypt floor is fully playable through the new scene with no simulation divergence.

### Unit 2 — graphical dungeon language

- deterministic wall/floor texture;
- remembered vs visible treatment;
- warm local lighting;
- fog/unknown void;
- actor emphasis;
- crypt-specific material identity;
- no invented semantic props.

Acceptance: screenshot at target phone size unmistakably matches approved graphical-glyph direction.

### Unit 3 — crawl interaction reboot

- map-first direct melee;
- long-press/alternate inspection;
- targeted spell marks on map;
- compact tactical HUD;
- contextual exploration shelf;
- favorites/readied presentation + overflow;
- remove explicit Attack shelf control when direct melee is proven.

Acceptance: common movement, melee, spell targeting, wait, potion/pack/context actions are one-handed and understandable without the old large dock.

### Unit 4 — turn timeline + duplicate identity

- activation queue presentation;
- repeated fast-actor activations;
- encounter-local duplicate labels;
- timeline→map highlight/center;
- identity-aware log naming where ambiguity exists.

Acceptance: with two same-name enemies and one fast actor, player can unambiguously state the next activation sequence and identify each actor on the map.

### Unit 5 — log drawer

- 3-line scrollable peek;
- half/full overlay states;
- auto-follow pause while reading history;
- `N new` return-to-latest affordance;
- exact history retained.

Acceptance: player can review older events during combat without permanently reducing map size or losing new messages.

### Unit 6 — character / spells / pack

- consolidate duplicated information architecture;
- hero overview;
- focused gear/magic/skills/progress destinations;
- pack categories only where they improve scanning;
- context-valid actions.

### Unit 7 — town + transactional rooms + heroes

- Stonebridge shell;
- Market, Bank, Forge, Alchemist, Inn, Tavern, Heroes;
- shared dark/engraved design system;
- preserve transactional/refusal semantics;
- integrate curated static art only after art bible is locked.

### Unit 8 — world + theme parity

- world graph redesign;
- Sea-Cave and Ruined Keep material/lighting identity;
- road encounters;
- final accessibility and device-size pass;
- tablet work starts only after phone composition is accepted.

## 16. Acceptance heuristics for the whole reboot

The reboot is succeeding when:

- the map is visually dominant and still immediately readable;
- a screenshot is recognizably Residuum rather than generic dark fantasy;
- the player can distinguish unknown / remembered / visible space without explanation;
- duplicate enemies are never ambiguous in turn order or targeting;
- the player can predict the immediate activation order at a glance;
- the log remains useful without permanently consuming a large fraction of the screen;
- basic melee is faster than the old arm-then-target flow;
- spells scale beyond the width of the phone without hiding the full grimoire mechanically;
- town/management screens feel related to the dungeon but remain quieter than it;
- no presentation component becomes a second source of game truth;
- color is never the sole carrier of important information;
- deterministic gameplay remains deterministic.

## 17. OMP kickoff prompt

Use the following as the first local instruction after the docs/LDD migration is applied:

> Start a new Flow/LDD epic for the Residuum Flutter visual reboot. Treat `.flow/ldd/visual-reboot/external/residuum-visual-reboot-handoff.md` and the approved visual mock as external proposal/evidence, not as an execution plan. First perform fresh recon of the current `fiatcode-gh/residuum-rpg` codebase and ledger/spec authority, especially the crawl renderer, GameBloc view state, battle dock/skills, event log, world/town navigation, character/pack duplication, and transactional town screens. Reconcile the handoff against current code and record conflicts explicitly. Then write the active ledger/decision record and propose Unit 1 (Flame dungeon scene foundation) as the first bounded implementation contract. Do not modify production code until that contract is reviewed.

## 18. Approved baseline summary

Lock these unless a later LDD decision supersedes them:

- phone-first Flutter; tablet later;
- Flame only for dungeon scene;
- graphical-glyph dungeon;
- procedural deterministic terrain texture;
- smooth lighting over rules-driven FOV;
- compact permanent HUD;
- direct tap adjacent enemy for melee;
- long-press / tactical token for inspect;
- targeted abilities arm then select map target;
- no explicit Attack shelf button;
- full spell access with compact favorites/readied presentation + overflow;
- activation queue replaces `NOW / IN n` prose;
- stable duplicate actor labels across map/timeline/log/targeting;
- 3-line scrollable log peek plus half/full overlay history;
- map = space/targets;
- timeline = time;
- log = causality;
- shelf = verbs;
- no pinch zoom initially;
- no semantic fake props;
- non-dungeon UI stays restrained and subordinate to the map;
- approved mock is visual direction, not literal game content.
