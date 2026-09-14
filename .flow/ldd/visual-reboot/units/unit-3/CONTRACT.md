# Unit 3 — Crawl Interaction Reboot

Status: **proposed by architect, 2026-09-14.** User review required before any
production code.

## Goal

Make the common crawl verbs — move, melee, cast, inspect, wait, use, pack —
one-handed on the phone, expressed through the map and one contextual shelf,
without the old armed-attack dock flow. Core rules, content, saves, balance,
and authoritative state do not change.

## Authority

- Follows the accepted Unit 1 Flame boundary and Unit 2 material language.
- Handoff section 18 baseline plus sections 5.2–5.5 and 6.1 are the WHAT
  authority. Recon confirms them against current source.
- `GameBloc` + core `GameState`/`step` stay authoritative. Flame stays
  presentation-only and never owns state, RNG, HP, actions, or persistence.

## Product contract

### Map-first melee

- Tapping an orthogonally adjacent enemy while no targeted ability is armed
  performs the existing bump attack: dispatch `MoveAction(direction)` into the
  occupied tile. Core rule unchanged — the gesture that reaches the bump is the
  map tap now.
- The explicit Attack shelf control and its plumbing (`ArmedAttack`,
  `AttackArmed`, the attack arm of `StageCardTapped`) are removed once direct
  melee is proven by focused tests. No alias, shim, or dead path is retained.

### Targeted abilities

- Arming a target-needing spell (bolt/bind/banish) puts the map in targeting
  mode: legal targets (visible monsters) carry the existing greyscale-safe
  rectangle mark, already driven by `GameViewState.armedTargets`.
- Tapping a marked target casts at it (`CastPressed(spellId, targetId)`).
- Self-cast spells (Mend/Ward) cast immediately from the shelf, unchanged.
- Tapping the armed ability again, or an explicit cancel affordance, disarms.
- **Decision:** while armed, tapping a tile that is not a legal target disarms
  rather than moves the hero. A targeting mode that silently walks on a stray
  tap is a trap. This is a deliberate change from today's "arm then tap empty
  tile moves".

### Inspection

- Long-pressing a visible enemy opens the existing inspect sheet
  (`showEnemyInfo`), costing no turn and mutating nothing.
- Tapping an enemy that is not a legal melee target while no targeted ability
  is armed also opens the inspect sheet — the discoverable alternate to
  long-press, never long-press-only.
- Inspection is presentation-only: no bloc event, no state change, no core
  dispatch.

### Contextual shelf (consolidation)

- One shelf replaces `BattleSkillBar` (full spell wrap + Attack + Wait) and
  merges with the existing exploration controls in `_Controls`.
- Exploration baseline keeps today's verbs unchanged: pick up, mine/gather,
  quick-drink, pack, ascend/descend, flee, move on, leave, and the contextual
  underfoot/bottom text.
- Combat mode: quick-drink + readied abilities + overflow (`+N`) + Wait.
- Wait stays available wherever it is meaningful today — reach held on the hero,
  or a road fight with living monsters — now from the one shelf.
- Overflow opens a full grimoire bottom sheet (school marking, name, cost),
  cost-free, from which any known spell can arm or cast. This is progressive
  disclosure, not a mechanical restriction: every known spell stays reachable.

### Favorites / readied

- **Decision (locked):** the readied set is the first few known spells in the
  existing stable order (school, then name), plus Wait; the rest live in
  overflow. No pinning, no persistence in this unit. Explicit
  favorites/readied assignment is a separate future decision (handoff 6.2),
  not smuggled in here.

### Camera

- A small recenter affordance appears over the map when manual pan has moved the
  hero off-screen; tapping it resets pan to zero.
- **Decision (locked):** ease-back is deferred. The camera keeps the current
  instant snap-to-hero after actions; only the recenter affordance is added
  here. Smooth ease-back is a later polish unit, not Unit 3 scope.

## Presentation architecture

- Input boundary keeps its shape: Flame hit-tests and emits raw intents; app
  state decides meaning.
  - `onTap(position)`: the widget first asks a pure state getter whether the
    position holds an inspect-only enemy; if so it opens the sheet, otherwise it
    dispatches `TileTapped(position)`. The bloc then decides melee / cast /
    move / refusal.
  - `onLongPress(position)` (new, via `LongPressCallbacks`): the widget inspects
    the visible monster at that position directly.
  - `onPan(delta)`: `MapPanned(delta)`, unchanged.
- `BattleDock` stage cards become inspect-only (tap = inspect, never cast or
  attack). Stage cards and turn chips remain the time surface until Unit 4 owns
  the timeline.
- Target marks remain glyph/outline driven (greyscale-safe), now applied by map
  taps rather than stage-card taps.

## Non-goals

- No core/content/save/economy/balance/generator changes.
- No turn timeline or duplicate-enemy identity (Unit 4).
- No log drawer (Unit 5).
- No character/spells/pack information-architecture work (Unit 6).
- No town/world/transactional work (Units 7–8).
- No pinch zoom.
- No true prepared-kit gameplay restriction.
- No second FOV/lighting simulation or gameplay RNG use.

## Acceptance criteria

1. Tapping an adjacent enemy with nothing armed performs the bump attack; the
   explicit Attack control is gone from the shelf.
2. Arming a target-needing spell marks visible monsters on the map and a marked
   tap casts at that monster; tapping the armed ability again or the cancel
   affordance disarms; self-cast spells still cast immediately.
3. While armed, tapping a non-target tile disarms and does not move the hero.
4. Long-pressing a visible enemy, and tapping a non-adjacent enemy with nothing
   armed, both open the inspect sheet at no turn cost; neither mutates state.
5. The combat shelf shows quick-drink + readied abilities + overflow + Wait; the
   overflow sheet lists every known spell and arming/casting from it works; no
   known spell is unreachable.
6. Exploration verbs (pick up, gather, drink, pack, stairs, flee, move on,
   leave) behave exactly as they do today.
7. Movement, distant auto-walk, pan, and the watched auto-path refusal are
   unchanged; the adjacent-monster watched refusal is replaced by melee.
8. No Flame component owns or mutates gameplay/FOV/RNG state; no core/content
   package gains a Flutter/Flame dependency.
9. App formatting, `flutter analyze`, and full `flutter test` from
   `packages/app` pass, including new map-melee, map-targeting, disarm,
   inspect-gating, and shelf-consolidation tests.
10. Final Pixel_10/phone AVD evidence shows the one-handed flow (melee, arm →
    target → cast, inspect, shelf) reading in normal colour and greyscale.

## Verification strategy

Prefer bloc-level and pure-state tests over pixel snapshots:

- map tap adjacent enemy → bump `MoveAction`; map tap with armed spell on a
  marked monster → `CastPressed`; map tap with armed spell on a non-target →
  disarm and no move;
- the pure inspect-target getter: adjacent enemy (melee) vs distant enemy
  (inspect) vs armed marked enemy (cast) vs empty tile (none);
- shelf consolidation: combat vs exploration verb sets; overflow lists all
  known spells; Wait gating preserved;
- widget-level: long-press opens the sheet, overflow opens the grimoire, stage
  card tap inspects, recenter resets pan;
- full app suite + analyzer;
- final AVD + greyscale acceptance.

## Review disposition

- COR: run — interaction semantics and the input boundary are consequential.
- TTC: run — melee/targeting/disarm/inspect contracts and their tests matter.
- CRF: run — shelf consolidation and scene input can become coupled/duplicated.
- SEC: skip unless implementation unexpectedly introduces an external/security
  boundary.

## Risks and traps

- Do not move the hero on a stray tap while armed — that is the disarm decision
  above.
- Do not let the map tap become a second place that decides core meaning; keep
  the decide-in-bloc boundary.
- Do not drop Wait from the road-fight path while consolidating shelves.
- Do not make the stage card cast again; targeting lives on the map now.
- Do not add pinning/persistence for favorites in this unit.
- Keep the scene's pan-only projection reuse; recenter must not rebuild the
  whole scene.

## Resolved decisions (2026-09-14)

- Camera ease-back is deferred; Unit 3 ships only the recenter affordance over
  the current instant snap.
- Readied slots are the fixed school-order first few known spells plus Wait; no
  pinning, no persistence.
