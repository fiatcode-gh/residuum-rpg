# Recon — battle overhaul (`m3-battle, story M3U)

## VERDICT

The battle-screen-as-view model is buildable without touching the engine's
center of gravity: `step()` keeps its shape, and the changes are (1) one
ambush-opening rule in `step(), (2) explicit target on `CastSpellAction,
(3) one new `Actor`/`CreatureSpec` field (`reach`) plus one ranged branch in
`_monsterPhase, (4) one new pure LoS helper, and (5) a new app battle view +
tap-to-target gestures. The bands move only through the ambush rule and the
spitter; the bot survives because it plays actions into `step()`. The unit is
L/XL but bounded — the engine loop, the save shape (v3 stands), and the
suspend theorem all survive.

## State verified before measuring

- `main` @ `8168861` (PRs #1–#13), tree clean. Four recon agents fanned out
  read-only (app/view, core engine, content/bestiary, bot/bands); every claim
  below re-verified by the architect at source unless marked agent-reported.
- Measured 2026-09-02.

## The measurement

### Core engine (`packages/core/lib/src/engine/`)

- `step()` order: refuse → flee-check → hero action switch → `_monsterPhase`
  → death check → FOV/noticings → copyWith return. Confirmed by read.
- **Ambush seam: exactly one.** Between the flee-check and the hero action
  switch. `_monsterPhase` is self-contained and re-runnable; the fresh-clock
  precedent is `_arriveOn` (`hero.energy = actThreshold`) and `_built`
  (fresh monsters at `actThreshold`). An ambush = pre-charged opening monster
  + a pre-hero monster pass; **no new named draws required** — the opening
  swing draws exactly what `_defend` draws today.
- **No `AttackAction` exists.** Melee is `MoveAction` into a monster
  (`_moveHero, `monsters.indexWhere(position == target)`). Bump-as-attack is
  documented contract ("Step the hero one tile, or attack whatever stands
  there").
- `CastSpellAction` carries only `spellId`; targeting is internal via
  `_targetOf` → `nearestVisibleEnemy(...)!` (nearest by Chebyshev, ties by
  row-then-column, **draws nothing**). The app mirrors refusal logic
  independently (`GameViewState.castRefusal` + its own `_needsATarget`) — a
  second copy that must not drift.
- **No point-to-point LoS utility** (grep: none). Only `computeFov` sets +
  `FloorMap.isTransparent`. A ranged reach check can be:
  `state.visible.contains(target) && target.chebyshevTo(hero) <= reach` —
  reuses the per-turn FOV set, draws nothing. No new FOV machinery needed.
- Named-draw inventory (combat stream `rng`; loot stream `lootRng`): hero
  melee roll, bolt roll, banish tile, dodge gate (conditional — "no dodge
  chance does not roll at all"), monster damage roll. Ranged/spitter attack
  adds zero new draws if it reuses the `_defend` pattern.
- Flow field runs every hero action regardless of any "battle" — monsters
  walk during a fight for free. `isEncounter` changes exactly one rule
  (edge-step = flee). `bound` is pruned every `step` (`_stillStanding`) and
  cleared on every arrival — off-stage held monsters are already safe.
- Events: `AttackHit, `AttackDodged, `WardStruck, `SpellHit, `MonsterBound, `MonsterBanished, `ActorDied, `ActorMoved, `ActorNoticed, `Fled, `GameOver` all exist. **Gaps:** no ambush/battle
  lifecycle event; no target-chosen event; monster HP is on `Actor` in state
  (app may read it; nothing does today) but not in any event.
- `Actor` exposes `hp, `maxHp, `attackMin/Max, `speed, `energy, `pierce, `resists, `vulnerableTo` publicly; `copyWith` carries only
  position/hp/energy (a new field rides along automatically).
- House ambush precedent: `encounter_map.dart` — "on the road the ambush has
  already happened" (road monsters spawn in plain sight, never adjacent).

### App / view (`packages/app`)

- `GameViewState` exposes: `isEncounter, `isRoadClear, `enemiesInSight, `visible` (via `game`), underfoot getters, `castRefusal, `knownSpells`
  (school-then-name order), `mana`/`maxMana`/`warded, hero stats.
  **Adjacency is NOT derived anywhere in the app** — a battle view needs a
  new derived getter (e.g. `adjacentMonsters`) beside `enemiesInSight`.
- Road fights render through the *same* `GameScreen`/`GlyphGrid` — no separate
  encounter widget exists. `isEncounter` only swaps Flee/Move-on controls, the
  status word, and the palette. One combat system already; the battle view
  extends it, it does not unify two.
- Tap model: `TileTapped(position)` — adjacent tap = one `MoveAction` (i.e.
  bump-attack); far tap = auto-walk, refused while `enemiesInSight > 0`
  (`_watchedRefusal`). No selection state, no long-press, no targeting layer
  anywhere in `glyph_plan.dart` (fixed draw order, no highlight layer).
  **Tap-to-target is brand-new UI surface.**
- Navigation: pack/character push over `GameScreen` sharing the same
  `GameBloc` by value; road fights push `GameScreen` over the world;
  `PopScope(canPop: false)` converts system back. A `BattleView` as an
  in-`GameScreen` layout state (not a pushed route) matches the death-overlay
  precedent (`Stack[Column, if (isGameOver) _DeathOverlay]`).
- Widget-test conventions: real blocs over `MemorySaveFiles` (nothing faked), `arenaGame` fixture, phone-size helper `_onAPhone` (1080×2424, dpr 2.625).
  Pinned text a battle view may break: status-line strings
  (`world_screen_test, `hud_depth_test, `boot_wiring_test, `roster_session_test, `suspend_door_test`), control labels ('Flee',
  'Move on', …), refusal log sentences, `glyph_plan_test` draw-order pins.

### Content / bestiary (`packages/content`)

- `CreatureSpec` (`bestiary.dart:8`): id, name ("the …"), glyph, hp,
  attackMin/Max, speed, dropChance, pierce, resists, vulnerableTo.
  **No reach field anywhere.** `spawn()` → core `Actor` with
  `energy: actThreshold`.
- Roster: 5 crypt creatures (rat/wolf/ghoul/skeleton/wight), 5 sea-cave
  (crab/drowned/eel/hag + boss drowned-captain), 4 keep (deserter/hound/
  man-at-arms + boss castellan) = 14, pinned `hasLength(5)` / `hasLength(14)`.
- Spawn tables: crypt global map depths 1–5 (`spawn_tables.dart`); themed
  tables in `sea_cave.dart`/`ruined_keep.dart` via `dungeon_spawn.dart`
  (`Weighted<CreatureSpec>` — cannot name a nonexistent creature);
  road tables in `world.dart` (lowland/shore/garrison). Boss replaces the
  last rolled monster, never in a spawn table.
- Validation tests that fire on a new monster: `hasLength(5)` + `hasLength(14)`
  bestiary pins; id/glyph uniqueness + glyph charset; speed-diversity set
  {5,10,20}; **reachability pin** ("every creature can be met somewhere" —
  exact set equality); spawn-table key/count pins; delve-band literals;
  boss-hp-dominance; designed-difficulty test (depth ≥ 3 creatures must beat
  mail by ≥ 2 after pierce; shallow-exempt set pinned by name to
  {rat, wolf, ghoul, crab}); **survivability band pins** (exact death-depth
  maps + exact win counts 20/30/25 of 40 + greedy 20/exploit 14 + 0.45–0.80
  soft bands + stalled 0).
- `Actor`-field touch points: `actor.dart` constructor/copyWith;
  `CreatureSpec.spawn`; `encodeActor`/`decodeActor` (`actor_codec.dart`);
  `run_codec.dart` floor-monster blocks. **Save goldens are byte pins** —
  a new Actor field changes the run document; save v3 is frozen and this unit
  must decide bump-or-default-encode (see hazards).
- D56 boundaries that copy fields: `startRoadEncounter` (`world.dart:403,
  the field-carry list that once wiped spells), actor codec, goldens, `dungeon_door_characterization_test.dart` (`_openingMonsters` seed 4242), `themed_floor_characterization_test.dart` (whole-floor hash goldens).

### Bot / bands / instruments

- Bot = one test file, `packages/content/test/survivability_test.dart`.
  Policy `_decide`: attack adjacent (MoveAction) → drink < 40% → pick up →
  equip upgrade → path to stairs. **Melee-only, no casts, no Read, no flee** —
  follow-up 29 confirmed at source. Knows the whole floor (deliberate).
  Calls `step()` directly, one action per turn, 4000-turn budget, 40 seeds
  per dungeon, `depth >= deepest` = win (follow-up 28 confirmed at
  `_botPlay`'s break).
- Four band lines are **print + assert together**: `expect(wins, 20/30/25), `greedy 20 / exploit 14, exact death-depth maps, soft bands 0.45–0.80,
  stalled 0. Re-run: `cd packages/content && dart test
  test/survivability_test.dart` (quote pwd per follow-up 27).
- M3B re-baseline precedent (`936ca5b`): after every content delta, re-run
  the suite, record all band lines as one trail row, keep failed
  configurations as rows, iterate to the ruling's targets, then re-pin the
  exact figures in test source with each old pin quoted in the dartdoc
  ("The old pin was … and it died by design"). Same method in M3M (five-row
  trail, D56).
- A casting variant is a `_decide` policy branch (state already carries
  `knownSpells`/`mana`) plus a way to acquire books — the bot treats books as
  dead weight today (`survivability_test.dart:67-78`).

## Is each inherited gate real?

- "Bands hold byte-identical" — real but *scoped*: only the ambush opening
  and the spitter move rolls; the view/UI is invisible to the bot. Not
  dissolved, narrowed.
- "Save freeze (follow-up 20)" — real: goldens byte-pin the run document.
  Resolution below.
- "hero-always-acts-first" — a documented engine contract (`step` doc, `step.dart:791` arrival safety); the ambush rule amends it deliberately.
- "No LoS utility" — confirmed by grep (architect-verified).

## Findings that change the spec

1. **Ambush needs no new rng draws** — pure clock arithmetic. Band movement
   is bounded and measurable; the M3B trail method applies unchanged.
2. **Tap-to-target collides with movement semantics.** A tap on a monster
   tile is today a bump/attack; in the battle view the same tap must mean
   "target this". The battle view is a separate gesture surface (its own
   widget tree), so the collision is avoidable by construction — but the
   spec must pin that `TileTapped` in the *crawl* view keeps its meaning.
3. **`isEncounter` monsters never spawn adjacent** (validator) and spawn in
   plain sight — road fights already have ambush-flavored openings; the
   ambush rule must state how it composes with them (or road fights are
   exempt: the ambush already happened — existing doc).
4. **`GameViewState` has no adjacency getter**; the battle view needs one new
   derived getter (`adjacentMonsters`) and, for the strip, a
   turns-to-arrival read (flow-field distance) — both app-side derivations
   over state, like `enemiesInSight`.
5. **Spitter needs:** `CreatureSpec.reach` + `Actor.reach` (default 1 =
   adjacency, preserving every existing creature byte-for-byte in behavior),
   one ranged branch beside the adjacency branch in `_monsterPhase`
   (`visible.contains(monster.position) && chebyshev ≤ reach` → attack, else
   walk), and the LoS-reuse above. Zero new draws.
6. **Save v3 vs the `reach` field:** `encodeActor` enumerates fields; the
   honest options are (a) default-encode `reach: 0/1` without a version bump
   (back-compatible read of v3 documents; new field optional in decoder) or
   (b) bump to v4. Leans (a) — a decode-defaulted field changes no existing
   document; the version-freeze dartdoc governs and the spec must argue it.
7. **The casting bot (follow-up 29) is a small policy change** and this unit
   is the natural home: the ambush rule changes openings and a magic-blind
   bot cannot judge the new fight honestly.
8. **Widget-test pins to restate in the build prompt:** `find.textContaining`
   case-sensitive; `scrollUntilVisible` one-way; phone-size at least one test
   (`_onAPhone` precedent); status/control text pins listed above.

## Proposed shape of the work

**Split into two sequential units** (monorepo dependency rule `app → content
→ core` makes the seam clean; the bot runs headless over core+content, so the
bands are measurable before any UI exists):

- **Unit A `m3-battle` (core + content):** ambush opening; `CastSpellAction`
  explicit target (with nearest-fallback refusal semantics pinned); LoS-reuse
  reach rule in `_monsterPhase`; `reach` field through bestiary/codec/goldens;
  the spitter (stat line = bestiary ruling at spec); designed-difficulty and
  validation-test updates; band re-baseline via a measured trail; casting-bot
  variant as an informational line (follow-up 29).
- **Unit B `m3-battle-ui` (app):** battle view over `GameScreen` (stage =
  reach-holding monsters; strip = arrivals with turn counts; skill bar =
  dock grammar: marking + name + cost, wrap-flow; tap-to-target; refusal
  stays in the log), adjacency + arrival derived state, widget tests
  (phone-sized), the crawl-HUD riders (follow-ups 30/31) if they fit.

## Hazards to carry into the spec

- Golden save tests byte-pin run documents; the reach field must decode
  v3 documents unchanged (goldens re-pinned BY HAND, old value quoted).
- `dungeon_door_characterization_test.dart` pins the crypt's first floor and
  its opening monsters at seed 4242 — any ambush/opening change to spawn
  energy reshuffles it; it is the tripwire for "layout frozen forever".
- The `hasLength(14)` and reachability pins break on ANY new creature — the
  spec must name the exact new pin values, not "update the pins".
- The designed-difficulty shallow-exempt set is pinned by name; a depth-2+
  spitter either beats the mail bar or joins that set by ruling.
- The app's mirrored `_needsATarget`/`castRefusal` copy will drift if the
  action shape changes without it — one file, both sides.
- D56: grep every new field against `startRoadEncounter`'s carry list.
- Widget traps (verbatim in the build prompt): `find.textContaining`
  case-sensitive; `scrollUntilVisible` one-way; size one test like a phone.
- Analyze from the WORKTREE ROOT with pwd quoted; mutation reds as named
  sets; goldens by hand.

## What this recon did NOT check

- The suites were not run (read-only recon); every number is a source read,
  not a fresh measurement. The build prompt re-derives all counts and bands
  on the worker's own account, as always.
- `TUNING-TRAIL.md` is absent from disk (gitignored, lost with M3B's
  worktree); the trail method is known from ledger + commit diff only.
- `event_messages.dart`'s full catalog (only call sites traced) — the new
  log sentences for ambush/ranged hits will need its shape read at spec time.
- World/town bloc interplay with road-fight opening beyond `main.dart`'s
  push site.
- Whether any doc already contains a spitter ruling (none found in
  `docs/epic/` beyond this unit's own entries).