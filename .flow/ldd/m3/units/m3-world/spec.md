# Story spec — M3W `m3-world`: the overworld

Unit: branch `m3-world, worktree
`/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-world`
@ base `844376f`. Decisions D34, D35, D36 bind. Recon:
`m3-leave-recon.md` (findings 5–9 are this unit's; the environment and codec
hazards apply unchanged). All under `docs/epic/, gitignored — never commit
anything there.

## Goal

The game gets a world: a node map with two towns and the crypt, roads with a
travel cost in days, a per-day encounter roll that can drop the hero into a
small open fight on the existing engine (flee by stepping off any map edge),
discovery (the map starts partly hidden; arrival and tavern rumors reveal
it), and death on the road waking the hero at their home town. The M3L leave
landing moves from the town to the overworld, and the resume/delve-anew fork
moves to the crypt node. Measurable effect: 897 baseline tests stay green,
crypt survivability stays EXACTLY 24/40 with the identical histogram, and a
hero can camp mid-crawl, walk two days to the second town, shop a DIFFERENT
shelf, walk back, and resume roll-for-roll.

## Scope fence (what this unit is NOT)

Sea-cave, ruined keep, new creatures, bosses, per-node floor salts, and the
run-block dungeon identity are M3D. Quest templates and payouts are M3Q.
Caravan and shrine encounter mechanics are deferred (follow-up) — this unit's
non-combat events are the rumor traveler and the quiet day. All dungeons stay
5 floors. Water/trap/chest tiles do not exist and are not added.

## Shape — precedents to follow (read them, do not reason by analogy)

- **Core owns rules, content owns numbers:** `DropTable` (core type,
  content-filled) and `buildFloor`/`residuumDungeon` (content assembles, core
  consumes via closure) are the pattern for the world map, route danger, and
  road encounters. Core never imports content.
- **The two-door discipline** (`run_boundary.dart`): road encounters enter
  through a content wrapper mirroring `startDungeonRun` and end through
  `endRun` — which makes `endRun(died: false)` reachable again (the D37
  worker note, honored here).
- **Seed derivation without a new stream:** `floorSeed`'s mix and the salt
  precedent (`lootStreamSalt, `_marketSalt`). The travel day's roll derives
  from `(worldSeed ^ travelSalt, day)` — deterministic, nothing new
  persisted, reload cannot re-roll a day.
- **Save reshape:** the M3L `inside` field — required block, refusal by name,
  goldens by hand in the same commit.
- **Event → text:** `describeEvent`/`namesIn` in `event_messages.dart` and
  the `_MessageLog` widget — both deliberately reusable for travel lines.

## Design rulings (architect authority; the user may veto before launch)

1. **Per-town merchant shelves.** Each town rolls its own stock
   (`merchantStock` gains a town salt; stock ids carry the town). The D36
   invariant extends: the merchant visit block is valid exactly as long as
   the visit AND the town it was rolled for — arriving at the other town
   clears it, walking out of a resumed crawl to the same town keeps it.
   Rejected: one shared shelf (two towns selling the same iron helm reads
   wrong and makes the second town pointless for trade).
2. **One bank vault.** Banked gold and items are reachable from either
   town's bank door. A vault is the hero's, not a building's basement.
   The inn price stays one number.
3. **The world screen is the navigator's bottom.** Town screens push over it
   at town nodes; the crawl pushes over it at the crypt node; `leaveDungeon`
   and the M3L suspend pop back to it. Boot lands on the world screen at the
   hero's node (town is one tap), except `inside == true` boots into the
   crawl as today.
4. **Encounters are never serialized.** An app kill mid-encounter re-derives
   the same day deterministically on boot (same seed, same monsters, fresh
   fight). The `enRoute` state IS serialized, so the journey survives; the
   fight does not need to.
5. **Discovery start state:** the home town, the crypt, and the routes
   between them are discovered from the first save; the second town starts
   hidden. Arrival at a node reveals its adjacent nodes and routes. A tavern
   rumor (bought with gold) reveals one undiscovered location, never a
   discovered one; when nothing is left to reveal the tavern says so and
   charges nothing.
6. **Travel while camped is legal and is the point** — the camp stays at the
   crypt node; the resume/delve fork appears when the hero stands at that
   node. The M3L town-door fork moves there; entering the dungeon is only
   offered at the dungeon's node.

## New and changed files

New (core): `packages/core/lib/src/world/` — the world feature folder
(`world_map.dart, `whereabouts.dart, `travel.dart` — names indicative);
`packages/core/lib/src/dungeon/encounter_map.dart` (the open-map generator);
tests beside them.
New (content): world map + routes + danger tables + rumor pool + road
encounter assembly (`src/world.dart` or similar); validation tests.
New (app): `packages/app/lib/world/` — `world_bloc.dart, `world_screen.dart,
tavern screen under `town/`; widget tests.
Changed: `run_boundary` untouched; `step.dart` gains ONLY the flee-at-edge
rule; `event.dart` gains `Fled` (and travel events if core-homed);
`game_state.dart` gains the encounter-mode field; save codec + `save_read`
gain the required per-hero `world` block; `main.dart` navigation rework;
`town_bloc`/`town_screen` (tavern door, per-town stock, fork relocation);
`autosaver`/`boot` carry the world block; goldens regenerate.

Pre-declare any different split before code.

## Per-item contracts

### 1. Core world model (`world/`)

- `NodeId` is a value object (no naked strings). `WorldNode` = id, kind
  (town | dungeon), display name. `Route` joins two node ids with
  `days >= 1` and a per-day encounter chance. `WorldMap` is immutable and
  self-validating: every route references real nodes, the graph is
  connected, ids unique.
- `Whereabouts` = where the hero is (at a node, or en route with a
  destination and days left), the day counter, the discovered set, and
  `home` (the last town stood in). Self-validating where it can be;
  map-dependent checks live in the functions that take both.
- Travel transitions are pure functions with the `Transacted`-style shape
  town uses (value + refusal): beginning travel requires a discovered,
  adjacent destination; each travel day advances the day counter and either
  passes quietly, meets a traveler (a free rumor: reveals as ruling 5), or
  rolls an encounter; arrival sets `at, updates `home` when the node is a
  town, and reveals adjacencies. The encounter decision draws from an Rng
  seeded by `(worldSeed ^ travelSalt, day)` — no persistent stream, and the
  dartdoc carries the reload-cannot-reroll argument.

### 2. The open encounter map (core)

- A second generator function, NOT a parameter bend on `generateFloor`
  (recon finding 7). Small fixed-size open ground with scattered
  obstructions, walkable border, hero placed away from the edge, monsters
  placed visible-allowed and reachable, no stairs. Its own validator, its
  own tests, its own golden seed pins. `generateFloor` and its tests are
  byte-untouched.

### 3. Flee at the edge (core engine)

- `GameState` gains an encounter-mode field (default false — a crawl).
  In encounter mode, a hero step that would leave the grid emits `Fled`
  and ends the encounter turn-lessly; in a crawl the field is inert
  because the crypt's border is solid wall (pinned) — say this in the
  dartdoc, and the mutation table carries it as a truthful weak row.
- The run codec does NOT serialize the field: encounters are never saved
  (ruling 4), and a decoded crawl gets the default. State this in the
  codec's dartdoc so nobody "fixes" the asymmetry.
- Kill-all ends the encounter through the bloc observing no monsters;
  loot picked up mid-fight rides home through `endRun(died: false)` —
  both endings (flee, cleared) go through it; death goes through
  `endRun(died: true)` and the hero wakes at `home` (D34).

### 4. Content: the world, the roads, the rumors

- Three nodes (two towns, the crypt), three routes (a triangle, so
  adjacency reveal and rumors both have work to do). Names, day costs,
  and encounter chances are content's choice — with the trail recorded.
- Road encounter assembly mirrors `startDungeonRun`: existing bestiary
  creatures only (rats and wolves read as road creatures; crypt-undead on
  roads needs a flavor argument if used). NEW tables, never edits to the
  crypt's — the exact 24/40 depends on the crypt's draw order
  (recon finding 9).
- The rumor pool: flavor line + reveal target per entry; the tavern sells
  one per purchase at a content-priced fee (ruling 5 covers the exhausted
  case).
- Validation tests: map connected, route days >= 1, every danger-table
  creature id exists, every rumor target is a real node, both towns'
  shelves derive distinct stock for the same visit.

### 5. Save document: the per-hero `world` block

- REQUIRED block beside `label`/`profile`/`run`/`inside`/`merchant`:
  the node the hero is at (or the route legs when en route), the day
  counter, the discovered set (sorted on encode — one roster, one
  document), and `home`. Refusal by name when missing or malformed;
  `inside: true` additionally requires the hero's node to be the dungeon's
  (state the cross-field rule and pin it).
- The merchant block gains the town it was rolled for (ruling 1); its
  validity rule (D36 extended) is enforced where the block is consumed,
  and the codec stays a codec — it validates shape, not commerce.
- Wide fields stay strings; day counters and the like are small ints.
- All goldens regenerate BY HAND in the same commit as the reshape.
  One more sanctioned v1 reshape (follow-up 20 restated: the first
  shipped build freezes v1).

### 6. App: world screen, travel, navigation

- `WorldBloc` follows the house bloc shape (plain-value constructor
  seeded from `Boot, sealed events, whole-state emissions with a
  `notice, rules delegated to core functions). Profile custody stays
  single-homed — whichever bloc owns the hero between runs, there is
  exactly one, and the autosaver watches it; pre-declare the chosen shape.
- The world screen renders nodes as labeled shapes with words — kind is
  never hue alone; discovered vs hidden reads in greyscale; the hero's
  node is marked by shape/position. Tapping a discovered adjacent node
  shows the day cost and confirms; travel then advances day by day with
  log lines through the existing message-log widget; an encounter pushes
  the existing `GameScreen` over the world and its end (fled, cleared,
  died) pops back and continues or ends the journey.
- The crypt node offers Enter (fresh), and when a camp exists, the M3L
  fork verbatim: Resume or Delve anew behind its confirmation. The town's
  Enter Dungeon door is retired; the tavern door joins the town.
- Boot per ruling 3. The autosaver's document trio grows the world block
  through `replacingActive`/`broughtUpToDate`; on-disk invariants extend
  M3L's: en-route heroes save their journey, camped heroes keep `inside:
  false, and a mid-crawl kill still boots into the crawl.

## Behaviour arguments that must land in documentation

- The travel-seed derivation (reload cannot re-roll a day) and why no new
  persistent stream exists.
- Encounters-are-never-serialized, on the codec and the autosaver.
- The extended merchant validity rule (visit AND town), where consumed.
- The flee field's inertness in crawls (solid border pins it).
- The discovery start state and why the second town starts hidden.
- Travel-while-camped as the intended pricing of the M3L inn-heal interim
  (this closes the D35 note: the road is the cost).

## Test plan

Baseline, measured fresh by the architect this session on `main` @
`844376f`: 408 core + 225 content + 264 app = 897 green; survivability
24/40 exact, histogram 1:1 2:9 3:6 5:24, fleetfoot 7/40; analyze clean.

### Characterization first (must pass against UNMODIFIED code)

- C1: `generateFloor`'s golden seed pins and the border-is-solid-wall test
  at base — these must be untouched by the encounter generator's arrival.
- C2: the M3L suspend theorem and the boot fork tests at base — the world
  block rides beside them, and they must not weaken.
- C3: today's merchant stock for a fixed (worldSeed, visit) — pinned before
  the town salt lands, then updated IN THE SAME commit as the salt with the
  old pin's value recorded in the test's dartdoc (the starting town's shelf
  WILL change when its salt lands; that is a sanctioned re-pin, argued in
  the commit, not a silent drift).

### Unit and integration tests (new, indicative not exhaustive)

- Core: map validation refusals; travel transitions (refusals, day
  advance, arrival reveal, home update); encounter-seed determinism (same
  day same world → same decision); open-map generator guarantees + golden
  seeds; `Fled` at every edge, only in encounter mode.
- Content: world validation suite (contract 4); distinct shelves; road
  encounter assembly determinism.
- App bloc: travel flows including interrupt-by-encounter; fork-at-node;
  tavern purchase paths; D36-extended merchant clears.
- App widget (PumpedApp): boot to world; boot camped; boot mid-crawl
  (unchanged); travel to town B and back with a camp intact on disk;
  flee by edge returns to the journey; death on the road wakes at home
  with the penalty applied; greyscale-liable screens covered by structure
  not color.

### Mutation table (run on COMMITTED code; both halves; extend it)

| # | Mutation | Expected RED | Expected GREEN (control) |
|---|---|---|---|
| 1 | beginTravel ignores the discovered gate | discovery-gate test | arrival adjacency tests |
| 2 | travel day forgets `day++` | day-advance + encounter-determinism tests | — |
| 3 | encounter chance short-circuited to quiet | the seeded travel test that expects an encounter on a named (seed, day) | quiet-day test stays green |
| 4 | `Fled` branch dropped (edge step becomes MoveBlocked) | flee bloc + widget tests | **crypt border tests stay green** — crawls cannot reach the branch |
| 5 | encounter-mode default flipped true | TRUTHFUL WEAK ROW expected: nothing reddens via crawls (solid border); report it as the proof the field is inert in crawls, per contract 3 | crypt suite green IS the result |
| 6 | arrival adjacency-reveal dropped | discovery tests | rumor tests green |
| 7 | tavern rumor may reveal a discovered node | picks-undiscovered test | — |
| 8 | town salt dropped from merchantStock | shelves-differ test (content) + town-shelf widget test | crypt survivability green — the shelf is not a balance lever |
| 9 | merchant block survives a town change | D36-extended clear test | resumed-crawl same-town keep test stays green (the D36 pair's other half) |
| 10 | road death wakes at the current node | wake-at-home test | dungeon death path tests green |
| 11 | codec defaults a missing world block | refused-by-name test | goldens green (they carry it) |
| 12 | en-route legs encoded but decoder reads `at` only | round-trip + golden tests | — |

Sequencing traps: rows 11–12 exist only after the reshape commit (goldens
and reshape are ONE commit); C3's re-pin is a two-step whose second step
rides the salt commit; row 4's control depends on C1 having pinned the
border first.

## Hazards

- Environment traps: restated verbatim in the build prompt.
- `main.dart` navigation rework — the architecture's named blind spot
  (D27): the AVD pass is MANDATORY and presses platform buttons.
- The codec never repairs; goldens by hand (D29 burn).
- Widget tests never await bloc close (D32).
- The autosaver choke point (`replacingActive`) grows again — M3L's
  on-disk invariant tests are the regression net; do not weaken them.
- The message log is view state; travel log lines drop on kill like crawl
  lines do (follow-up 19 unchanged).
- Old documents without the world block will demote to the corrupt
  fallback and then a fresh hero — acceptable while unshipped, worth one
  line in the report.

## Must-not list

- No edits to the crypt's spawn/drop tables, bestiary stats, armory,
  affixes, hero kit, `floorSeed, `generateFloor, or `buildFloor`'s draw
  order. New content rides in NEW tables and NEW functions beside them.
- `step.dart` gains the flee rule and nothing else; no combat, movement,
  or monster-phase changes.
- No new dependencies, no version bump, nothing committed under
  `docs/epic/, no golden edits via tooling, no touching a physical phone.

## Follow-ups to log (do not do them)

- Caravan and shrine encounter mechanics (deferred from the spec's
  section 8 list).
- A road-survivability instrument if road deaths feel wrong in play.
- M3D takes: per-node salts, dungeon identity in the run block, themed
  bestiaries/palettes, light bosses + guaranteed rares.

## Definition of done

- All suites green in the worktree; analyze clean; format clean
  project-wide.
- Crypt survivability EXACTLY 24/40, histogram 1:1 2:9 3:6 5:24,
  fleetfoot 7/40 (paste the lines).
- Mutation table on committed code, both halves quoted, extensions run.
- Goldens regenerated by hand, same commit as the reshape.
- AVD `Pixel_10` acceptance pinned to `emulator-5554, platform buttons
  included: boot to world; travel with a quiet day, a traveler, and a
  combat encounter (flee by edge AND a cleared fight); death on the road
  waking at home with the penalty; tavern rumor revealing the second
  town; both towns' shelves visibly different; camp at the crypt → travel
  to town B → return → Resume roll-for-roll; delve-anew confirm; app-kill
  en route → journey resumes; app-kill mid-crawl → crawl (regression);
  greyscale reading of every changed screen.
- BUILD-REPORT.md mirror; identifiers pasted, never typed.
