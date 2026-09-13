# Recon — m3-battle-flow (unit 2 of the D98 wave)

Fresh recon, measured at source 2026-09-03. Scope: V1 (turn strip → chips +
whole-header backing), V2 (armed-target flow, attack as a bar action,
bump-attack retired, bare tap = enemy info, map tap-to-attack retired),
V8 (core wait verb), V9 (two-state battle glyph). All line numbers verified
by the architect directly, not inherited. Paths relative to repo root.

## Core engine

- All `GameAction` subtypes live in `packages/core/lib/src/engine/action.dart`
  (sealed base :9). Current list: `MoveAction` :14, `DescendAction` :21,
  `AscendAction` :31, `PickUpAction` :38, `EquipAction` :46,
  `UnequipAction` :53, `DrinkAction` :65, `ReadAction` :79,
  `CastSpellAction` :101 (named `targetId`), `GatherAction` :126,
  `DropAction` :133. **No wait/pass verb exists** — absence verified by
  grep and by reading the file.
- `step(GameState, GameAction)` at `engine/step.dart:56`. Flow: game-over
  guard :58 → `_refuse` :61 (a refusal costs no turn) → `_flees` :65 →
  hero energy spend :74 → `switch (action)` :91–159 → `_monsterPhase` :170
  for every non-refused, non-stairs action → death/FOV/notice :196–200.
  Stairs actions return early and skip the monster phase (:94, :99).
- **A wait verb's natural slot:** a new action case in the step switch that
  emits its own beat event and changes nothing else; the monster phase then
  ticks the world. Every current event names a concrete change, so wait
  needs ONE new event type — there is no "nothing happened, time passed"
  precedent (`event.dart` events all carry payloads naming a change).
- **Ranged reach is real and would hit a waiting hero.** `Actor.reach`
  (`engine/actor.dart:31, :50–52`), reach check `_holdsReach`
  (`step.dart:743`): orthogonally adjacent, or `reach > 1` while the monster
  is in `state.visible` and within Chebyshev distance. In `_monsterPhase`
  (:590): ambush opening :604–636; owed turns :641 — bound monsters sit out
  :644, adjacent melee :652, a reach-holder at distance "stands its ground
  while it can shoot" :670–672, else flow-field step + lunge :687–700. All
  strikes go through `_defend` :842 (dodge/armour/ward). The spitter
  (`reach: 3, speed: 5`) is `content/lib/src/.../bestiary.dart:168–178`.
  **So a hero who waits at Chebyshev distance ≤ reach is shot on the
  monster's owed turn — V8's semantics are already true of the engine; only
  the verb is missing.**
- One `step`, two entry states: `GameState.isEncounter`
  (`game_state.dart:66, doc :282–286`) changes exactly one rule — a step
  off the grid flees instead of bumping a wall (`_flees`, step.dart:424–427).
  The road encounter is built by `startRoadEncounter` in
  `content/lib/src/world.dart` (~:403, `isEncounter: true` :443) and plays
  through the same `step` via GameBloc. **No second engine path.**
- The D86 turn count is APP-side: `GameViewState.arrivals`
  (`game_bloc.dart:314–332`) — flow-field distance × `speed / monster.speed`,
  ceil; reach-holders excluded (they are on the stage), unreachable excluded.
  `upNext` (:290–309) replays `scheduleMonsterTurns` over
  `hero.energy − actCost`, bound monsters filtered.
- Engaged vs watched are pure getters, nothing stored: `monstersHoldingReach`
  :272–280 (mirrors core `_holdsReachIn` :759–764), `isBattleOpen` :335–341
  ("open when something holds reach"), `enemiesInSight` :368–378 (count of
  monsters in `game.visible`).
- Refusal/beat grammar: events are the only channel
  (`event.dart:12–14`); `describeEvent` (`app/lib/game/event_messages.dart:17`)
  is an exhaustive switch, null = silent; app-only beats exist
  (`_ambushBeat` game_bloc.dart:626–655, `_beats` :681–694,
  `roadOpeningLog` :793). A wait beat can follow either house pattern; the
  second-person sentence shape ("You drink…") is the precedent.
- Tests that MUST stay green for a no-other-behavior wait verb:
  `engine/energy_test.dart`, `engine/step_clock_test.dart`,
  `engine/step_monsters_test.dart`, `engine/step_ranged_test.dart`,
  `engine/step_ambush_test.dart`, `engine/step_flee_test.dart`, the content
  pins (spawn tables, spitter stats, golden saves), and the five band lines.

## Battle dock (app)

- `BattleDock` (`app/lib/game/battle_view.dart:31–49`): stage card per
  `monstersHoldingReach` + `_TurnStrip`. **No dock header and no backing
  panel exist** — each stage card is its own opaque `panel`
  (0xFF15181F) container; the strip is bare `dim` (0xFF8A919E) 12px
  monospace over the map. Dock renders `if (state.isBattleOpen)` as the
  first Column child, map always visible below (`game_screen.dart:57–63`);
  skill bar renders `if (state.isBattleOpen && state.knownSpells.isNotEmpty)`
  (:64).
- `_StageCard` (:54–151): glyph, name, wound bar + counts, `'at range'` when
  `reach > 1`. Tap = `StageCardTapped(monster)` only. **No long-press
  anywhere in app lib** (grep: zero hits) — the enemy-info ruling has no
  incumbent surface to replace.
- `_TurnStrip` (:153–187): `'Next: ${state.upNext.first.name}'` and per
  arrival `'${monster.name} — $turns turns out'` — the V1 wording defect
  ("turns out") and the dim-12px visibility defect, both verified verbatim.
- `BattleSkillBar` (:196–240): one `TextButton` per known spell;
  mend/ward cast straight from the bar (`CastPressed(spell.id)`), the rest
  arm (`SkillArmed(spell.id)`). Armed marking = `BorderSide(color: ink)` +
  `' — armed'` suffix. The bar does not read `castRefusal`.
- Bump-attack and walk sentence are BLOC-side, not view-side:
  `_onStageCardTapped` (`game_bloc.dart:571–589`) — adjacent bare tap
  dispatches `TileTapped(monster.position)` (the bump via a blocked move),
  armed tap dispatches `CastPressed(..., targetId: monster.id)`, far tap
  emits the log-only `_outOfReach(monster.name)` sentence
  (:914: `'$name is out of reach. Walk to it.'`).
- Map tap path `_onTileTapped` (:530–566): `directionTo` branch :538–541
  dispatches `MoveAction(direction)` — an adjacent monster tile is therefore
  the map bump-attack (core turns the blocked move into a swing); non-adjacent
  walkable tiles hit the watched-refusal branch :545–554
  (`_watchedRefusal` :906: `'Something is watching. You stay put.'`).
  **Map tap-to-attack has no dedicated branch — retiring it means gating the
  `directionTo` dispatch on the target tile holding no monster.**
- Armed state: `armedSpellId: String?` on bloc state (:188–197), set by
  `SkillArmed` (:641–648), disarmed by every step (`_act` builds fresh
  state :714–726). Spell target legality = SIGHT only (visible enemy), app
  mirror `castRefusal` :439–463, core `_castRefusal` step.dart:221–242;
  **no reach term in cast legality anywhere.** Attack legality = adjacency
  (the dispatch gate).
- Status line: `_line` (`game_screen.dart:142–155`) appends
  `'  Engaged ${state.enemiesInSight}'` whenever anything is in sight — the
  V9 conflation (watched counted as engaged), verified. The row is
  `_HitPoints` (:82–127): fixed 56px HP bar, then an `Expanded(FittedBox(
  fit: BoxFit.scaleDown))` over the one string (:111–124). **A fixed-size
  glyph cell slots between the bar and the FittedBox.**
- Road encounter row `_Controls` (`game_screen.dart:269–369`): `Flee` (when
  `canFlee`) dispatches `FleePressed` → `MoveAction(wayOut)`; `Move on`
  (when `isRoadClear`) is direct navigation, not a bloc event. A Wait
  control joins this row as another conditional `Expanded(_Control(...))`.
- Map is CustomPaint: `GlyphGrid` → `_GlyphPainter` over `glyphPlan` cells
  (`glyph_grid.dart:106–132`, `glyph_plan.dart:60–108`; draw order terrain →
  nodes → litter → monsters → hero). **No per-cell widgets — a target
  highlight on the map means extending the plan/painter with an outline
  pass, not overlaying widgets.** Fog precedent: per-cell opacity
  (`rememberedOpacity` 0.4). Non-hue marking precedents: fog opacity, armed
  `BorderSide(ink)` + `' — armed'` word, school markings; dartdoc rule
  "Nothing is told apart by hue" (battle_view.dart:22–23).
- Enemy data available for info: the whole `Actor`
  (`engine/actor.dart`) — name, glyph, hp/maxHp, attackMin/Max, speed,
  reach, `resists` (Set<DamageType>), `vulnerableTo`; `Actor.toString`
  already renders resist words.

## Test pins that flip with this unit (verified at source)

- `battle_view_test.dart`: far card tap → `'the spitter is out of reach.
  Walk to it.'` (:190–192); turn strip pins `'Next: the ghoul'` /
  `'the ghoul — 4 turns out'` (:315–316); bump-attack on bare card tap
  (:433–451, `'You hit the ghoul for 4.'`); armed cast at card names target
  (:398–431); phone overflow test at 1080×2424 @ 2.625 (:220–261) pinning
  `'✳ Firebolt 2'` and `find.textContaining('Engaged')`; stage card
  contents (:262–292); non-caster no bar (:369–378) — flips when Attack
  becomes a bar action for every hero.
- `battle_characterization_test.dart`: `'Engaged 1'` pin :215; bump verb
  pins :219–228.
- `game_bloc_test.dart`: watched-refusal sentence pin :510–524
  (`'Something is watching. You stay put.'`); armed-skill lifecycle group
  :2039; cast refusal mirror :1641; arrivals D86 group :1900–2033;
  reach/upNext/dead-monster groups :1713–1902.
- `hud_depth_test.dart` status-line composition :58–80 (Engaged suffix).

## What the recon did NOT check

- Device rendering of any new glyph codepoint (monospace font coverage for
  the chosen marks is unproven — the AVD pass must read them in pixels).
- Whether any OTHER call site dispatches a bump-shaped `MoveAction` beyond
  `_onTileTapped`/`_onStageCardTapped` (grep found the two; the worker
  re-greps).
- Greyscale legibility of the chip design — the author's eye is the final
  authority, checked on device.
- The band lines are expected byte-identical (app-only + one no-op verb);
  expected is not proven — the trail runs in verification.