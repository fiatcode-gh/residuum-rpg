# U16.6 — Crawl Controls and Layout Revamp: execution plan

Status: **execution-grade; Tasks 01–12 implemented and accepted; §10
amendment (Tasks 13–14, 2026-09-28) awaiting user plan approval.** Governing WHAT/WHY:
[CONTRACT.md](CONTRACT.md), approved via `flow_gate` (sha256 `d0bae5fa…`).
Evidence: [recon.md](recon.md), `.flow/evidence/4b8bd10/UXW-EXP/`,
`.flow/evidence/4b8bd10/UXW-BAT/`. Decisions: LEDGER "Unit 16.6 intake".

Derived from head `4b8bd1092696caf24a942f437ee550f5df938942` on branch
`residuum-visual-reboot-16.6`. Dirty state at planning: `.flow/ldd/visual-reboot/`
LEDGER/RESUME modified and the 16.6 contract, recon and mock brief staged
(architect-owned; no task touches them). `packages/`, `docs/`, `AGENTS.md`,
`.github/` clean. A head change before a task needs targeted revalidation of
the seams its brief names, not replanning.

Unit 16.5 plan locks are superseded where this plan contradicts them (16×20
cell, fixed chrome by mode, 45 %/35 % floors, five-slot bar, three-column
panels, wordmark header, notes overlay, top-right recenter).

## 1. Planning figures (target phone, full-screen)

vivo I2505, 1080×2392 px @ 2.75 = **392.7 × 869.8 dp**, Android 16, gesture
navigation. With the system bars hidden, `MediaQuery.padding` is the cut-out
safe inset only (engine: `FlutterView` takes `max(systemBars, cutout.safeInset)`,
and hidden bars report 0). Planning figure: **top 24.0 dp, bottom 0**. Main
replaces the top figure with the Checkpoint A reading before Task 04.

Body = 869.8 − 24.0 − 18 (gesture clearance, G1) = **827.8 dp**.

| region (top → bottom) | dp at text scale 1.0 | same in every state |
|---|---:|---|
| HUD | 80 | yes |
| map (`Expanded`) | **568.8** (≈ 18.96 rows × 16.36 columns) | yes |
| gap | 6 | yes |
| log row (peek + side controls) | 104 | yes |
| gap | 7 | yes |
| bottom menu | 56 | yes |
| bottom gap | 6 | yes |

Device before (UXW-BAT): map 452 exploration / 360 battle. Every chrome
height is `base × crawlScale(context)` (existing clamp 1.0–1.3). These are
widget-level figures; **widget-test dp are not device dp** (U13.1 trap). The
device figure is measured at Checkpoint A and the final gate.

## 2. Locked global decisions (every task inherits these)

### G1 Full-screen (Task 01)

- Native, in `packages/app/android/app/src/main/kotlin/com/example/residuum_app/MainActivity.kt`.
  Flutter's own `SystemChrome.setEnabledSystemUIMode(immersiveSticky)` is
  **not** used: the app targets API 36 (`flutter.targetSdkVersion = 36`) and
  the engine documents immersive modes as ignored there, and its
  `onPostResume` re-applies `DEFAULT_SYSTEM_UI` legacy flags anyway.
- `onCreate`: after `super`, on API ≥ 28 set
  `window.attributes.layoutInDisplayCutoutMode = LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES`.
- `hideSystemBars()`: API ≥ 30 → `window.insetsController?.apply { systemBarsBehavior = WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE; hide(WindowInsets.Type.systemBars()) }`;
  API < 30 → `@Suppress("DEPRECATION")` decor-view flags
  `IMMERSIVE_STICKY | LAYOUT_STABLE | LAYOUT_HIDE_NAVIGATION | LAYOUT_FULLSCREEN | HIDE_NAVIGATION | FULLSCREEN`.
- Re-entry: call `hideSystemBars()` **after** `super` in `onPostResume()`
  (so it runs after Flutter's overlay re-application) and in
  `onWindowFocusChanged(hasFocus)` when `hasFocus`. Transient reveal by edge
  swipe auto-hides (system behaviour). No platform channel, no Dart call.
- Cut-out: every screen already sits in `SafeArea` or under an `AppBar`
  (`game_screen`, `town_screen`, `world_screen`, `main.dart` boot failure,
  `pack_screen`/`town_style` AppBars); with bars hidden those pad the cut-out
  only. Town, world and roster Dart code is unchanged.
- Gesture handle: the crawl `SafeArea` gains
  `minimum: EdgeInsets.only(bottom: crawlGestureClear)`, `crawlGestureClear = 18`
  (I2219 reported a 17.8 dp gesture bar). `SafeArea.minimum` is a max, so a
  visible three-button bar is not double-counted.
- Side edges: no native gesture-exclusion rects (see §7 Q3).

### G2 Map cell and glyph scale (Task 02)

- `grid_geometry.dart`: `mapCellWidth = 24`, `mapCellHeight = 30`.
- `tokens.dart`: `mapGlyphStyle` fontSize **31.5** (the 16.5 line-box ratio
  1.05 × cell height), `mapBadgeStyle` fontSize **15**. The line box may
  exceed the cell by ≤ 1.2 dp per side (16.5 ruling; 0.75 dp here).
- `dungeon_scene.dart` reticle: `_rect = Rect.fromLTWH(0.75, 0.75, mapCellWidth - 1.5, mapCellHeight - 1.5)`,
  `_armLength = 6.5`; strokes unchanged. Glyph centre and badge anchor are
  already derived from the constants.
- Atmosphere: torch pool `6 · mapCellWidth` (144 dp) and bloom
  `1.6 · mapCellWidth` (38.4 dp) stay derived; fog lattice, vignette and
  parallax factor/limit unchanged (screen space). Palette, glyph set, value
  hierarchy, determinism unchanged.

### G3 Camera and pan (Task 02)

`GridGeometry` stays the single projection authority.

```dart
static double _centred(double viewport, int focus, double cellExtent) =>
    viewport / 2 - (focus + 0.5) * cellExtent;
static double _clampAxisPan(double viewport, int cells, int focus, double pan, double cellExtent) {
  final centred = _centred(viewport, focus, cellExtent);
  return pan.clamp(viewport / 2 - cellExtent * cells - centred, viewport / 2 - centred);
}
static Offset clampPan(Size size, int columns, int rows, Position focus, Offset pan) => Offset(
  _clampAxisPan(size.width, columns, focus.x, pan.dx, mapCellWidth),
  _clampAxisPan(size.height, rows, focus.y, pan.dy, mapCellHeight),
);
```
Origin per axis = `_centred(...) + _clampAxisPan(...)`. Consequences: at zero
pan the focus cell is centred on **every** floor size, near edges too (the
void shows); the "axis that fits centres its extent and ignores pan" rule is
deleted; pan is bounded so the viewport centre always stays over the floor.
`_DungeonScene.onDragUpdate` keeps `Offset _dragPan` (reset to
`snapshot.pan` in `synchronize`), computes
`allowed = GridGeometry.clampPan(size, cols, rows, focus, _dragPan + delta)`,
dispatches `onPan(allowed - _dragPan)` only when non-zero, then sets
`_dragPan = allowed` — no dead travel after dragging past a bound.
`cameraFocus` (`selectedActor?.position ?? hero`) is unchanged (§7 Q6).
Recenter: `CrawlPill` gains `double extent = tapTarget` for its icon branch;
the recenter pill uses `extent: crawlTouchTarget` (48) and moves to the map's
**bottom-right** (`right: 8, bottom: 8`) — the top edge belongs to the
turn-order strip. Shown iff `_heroOffScreen` (unchanged predicate).

### G4 Touch resolution (Task 03, `map_touch.dart`)

`mapTouchRadius = 24` (monster targets, 48 dp disc) unchanged. New
`const double mapStepReach = 48;`. Unarmed tap rules 1–3 unchanged (monster
under finger; orthogonal step-cell guard; nearest known monster ≤ 24 dp).
Rule 4 becomes:

> `d = local − geometry.centreOf(hero)`; if `under != null` (the tap maps to a cell inside the floor bounds) `&& d.dx.abs() <= mapStepReach && d.dy.abs() <= mapStepReach && d != Offset.zero`:
> `u = d.dx / mapCellWidth`, `v = d.dy / mapCellHeight`; `u.abs() >= v.abs()` → east/west by sign of `u`, else south/north by sign of `v`;
> target `hero.step(direction)`; in bounds → `MapTouchCell(target)`, else fall through.

Rule 5/6 and armed and long-press rules unchanged. Effect: the hero's own cell
(except its exact centre), the four neighbours, the four diagonal cells (split
along their diagonal) and the near 12 dp (horizontal) / 3 dp (vertical) of the
two-away cells step one cell by dominant axis; every step target spans
≥ 48 dp along its axis and ≥ 48 dp across at the neighbour's centre.
Consequences accepted: a tap in a diagonal cell steps orthogonally instead of
auto-walking two cells; a tap on the near part of a two-away cell steps once;
an off-centre tap on the hero glyph steps. Taps beyond the box
auto-walk as today; the Watched walk refusal (`_watchedRefusal`) is unchanged
and never fires inside the box because those taps are single steps.

**Amendment (2026-09-24, from review of a discarded first execution):** the
`under != null` guard is required. Without it a tap on the visible void past
a floor edge (an edge diagonal) chose an in-bounds direction and stepped.
Far-cell auto-walk keeps exact tapped-cell selection; the contract records
that 24×30 dp target as an accepted exception to the 48 dp rule.

### G5 Screen composition (`GameScreen`)

```
PopScope → BlocListener(hasFled) → Theme → Scaffold(body: SafeArea(minimum: bottom 18,
  child: withClampedTextScaling(1.3, BlocBuilder(
    Stack[
      Column[
        CrawlHud                                           80·s   (T04)
        Expanded(Stack[
          Column[
            Expanded(key: dungeonSceneSlotKey, LayoutBuilder → Stack[
              DungeonSceneHost, MapOverlays(state, size)])
            SizedBox(crawlPanelGap 6)
            LogRow(key: logRowKey)                         104·s  (T05)
            SizedBox(crawlGap 7)
          ],
          if drawer != peek: LogDrawer overlay (unchanged rules)
        ]),
        CrawlMenu(key: crawlMenuKey)                       56·s   (T07)
        SizedBox(crawlBottomGap 6)
      ],
      if game over: _DeathOverlay
    ]))))
```
Removed from the crawl: wordmark, `HeroPanel`, `CombatPanel`, `CrawlActionBar`,
`BattleDock` row, `_NotesOverlay`. The map rectangle depends on nothing that
differs between exploration, Watched, battle and armed.

### G6 Verb ownership — one source of truth

Every guard is read from exactly one function; no widget re-derives one.

| verb | surface | availability owner | dispatch |
|---|---|---|---|
| attack, move, auto-walk | map tap | `resolveMapTap` + `GameBloc._onTileTapped` | `TileTapped` |
| inspect | map tap / long-press | `resolveMapTap` / `resolveMapLongPress` | `ActorInspected` |
| cast | Spells pop-up, then map tap when armed | `GameViewState.castRefusal` + `chooseSpell` | `CastPressed` / `SkillArmed` |
| drink | Quick pop-up | `potionKinds(state.game.inventory)` | `DrinkPressed(id)` |
| wait | log row | `GameViewState.offersWait` (new) | `WaitPressed` |
| flee | log row | `GameViewState.canFlee` | `FleePressed` |
| pick up, mine/gather, move on, ascend, descend, leave/finish | place pop-up | `placeVerbsFor(state)` over the existing `canPickUp`, `canGather`, `isRoadClear`, `canAscend`, `canDescend`, `canLeave` | unchanged events / `leaveEncounter` / `suspendDungeon` / `confirmCompletion` |
| pack (inventory, equip, drop, read) | `Hero` slot | always | push `CrawlPackScreen` |
| select actor | turn-order strip token | `activationQueue` | `TimelineActorSelected` |
| recenter | map overlay | `_heroOffScreen` | `RecenterPressed` |

`offersWait => !game.isGameOver && (isBattleOpen || enemiesInSight > 0)`
("Watched" is the header chip's own predicate `enemiesInSight > 0`). Core
never refuses `WaitAction`; spells outside combat reach core's
`_castRefusal`, which has no battle check — the rules decide.

Stable ids and labels are preserved as `ValueKey`s and words on the new
surfaces: `wait` "Wait", `flee` "Flee", `pick-up` "Pick up", `gather`
(`node.verb`), `move-on` "Move on", `ascend` "Ascend <", `descend`
"Descend >", `leave-dungeon` "Leave" / `doneControl` ("Finish"),
`spell:<id>`, `spells-overflow`, `overflow-<id>`. Marks are the U16.5 G9
marks for those verbs.

### G7 HUD (Task 04, `crawl_hud.dart`, renamed from `crawl_header.dart`)

`CrawlHud(state, dungeon, day)` keyed `crawlHudKey`, height
`crawlHudHeight (80) × crawlScale`, horizontal padding `crawlGutter`:
top 6; **row one** (24): `Expanded(flex 38)` HP `CrawlMeter` (`hpMeterKey`,
`crawlEnemy`, value `hero.hp.clamp(0, maxHp)`), gap 12, `Expanded(flex 38)`
mana `CrawlMeter` (`manaMeterKey`, `crawlCold`) or an empty box when
`knownSpells.isEmpty` (the column is always reserved), gap 12,
`SizedBox(width 72)` gold: `Row(end)[Icon(Icons.paid, 14, crawlGold), 4, Text('${game.gold}', monoData)]`
keyed `crawlGoldKey`, semantics `Gold N`; gap 6; meta line (existing
`_MetaLine`, 14); gap 4; chips row (existing `_ChipsRow`, 20); bottom 6.
`CrawlMeter` (new `crawl_meter.dart`, public): `label a/b` in `monoData`,
gap 3, bar of `barHeight` (default 6) `LinearProgressIndicator` on
`crawlMeterTrack`, radius 3 — the body of today's `_CrawlMeter`.
No wordmark, no gold rule, no hero name. `GameBloc.heroLabel` and its two
`main.dart` arguments are deleted (no consumer remains).

### G8 Log row and side controls (Task 05, `log_row.dart`)

`LogRow(state, bloc)` keyed `logRowKey`, height `crawlLogRowHeight (104) × s`,
padding horizontal `crawlGutter`: `Row[Expanded(LogPeek), if side: SizedBox(6), SideControls]`.
`side = state.offersWait || state.canFlee`. `SideControls` is 64 wide:
`Column[Wait slot or SizedBox, SizedBox(6), Flee slot or SizedBox]`, each slot
`(rowHeight − 6)/2` tall (49 dp), Wait always the top slot, Flee the bottom.
The log narrows when the side column appears; the row height never changes.
`LogPeek` loses its own horizontal padding and fills its box (existing
internals, key `logPeekKey`, truthful `N entries`, expand behaviour
unchanged).

Slots use `CrawlSlot` (new `crawl_slot.dart`, extracted from today's
`_ActionSlot`): `CrawlSlot({required String label, required ActionMark mark, required VoidCallback? onPressed, bool dimmed = false, bool armed = false, String metadata = '', required double width, required double height})`;
visual state = armed ? armed : (dimmed || onPressed == null) ? disabled
visuals : available (U16.5 G8 fills/frames/label roles); semantics
`button: true, enabled: onPressed != null`, label `label[ metadata]`, plus
`', unavailable'` when dimmed; layout top 6, mark 20 (`crawlSlotMark = 20`),
gap 2, label `textSlot` role in single-line `FittedBox(scaleDown)` (14),
optional metadata `monoSlotMeta` (10); `— armed` replaces metadata when armed.

### G9 Bottom menu and pop-ups (Task 07)

`CrawlMenu(state, bloc)` keyed `crawlMenuKey`, height `crawlMenuHeight (56) × s`,
four equal `CrawlSlot`s, gap 7, padding `crawlGutter`, **always** in this order:

| key | label | mark | dimmed when | metadata | tap |
|---|---|---|---|---|---|
| `menu-quests` | Quests | `FontMark(Icons.assignment)` | always | — | pop-up: `Quests are coming soon.` |
| `menu-spells` | Spells | `FontMark(Icons.auto_awesome)` | `knownSpells.isEmpty` | armed → `— armed` | Spells pop-up |
| `menu-quick` | Quick | `ShippedMark(ActionIcon.potion)` | no potion carried | `×N` potions when N > 0 | Quick pop-up |
| `menu-hero` | Hero | `FontMark(Icons.person)` | never | `${inventory.length}/$inventoryCap` | push `CrawlPackScreen` (existing route) |

Every slot's `onPressed` is non-null; a dimmed slot opens its pop-up, which
says why. Armed = `armedSpellId != null` on the Spells slot (cold frame,
glow, `— armed`).

`showCrawlPopup(BuildContext anchorContext, {required WidgetBuilder builder})`
in `crawl_surfaces.dart`: anchor rect from the slot's `RenderBox`
(`localToGlobal`), width `min(crawlPopupWidth 280, screenWidth − 16)`, left
`clamp(anchorCentre − w/2, 8, screenWidth − 8 − w)`, bottom edge
`anchor.top − 6`, max height `anchor.top − 6 − padding.top − 8` (content
scrolls). Route: `showGeneralDialog<void>(barrierDismissible: true, barrierLabel: 'Close', barrierColor: Color(0x00000000), transitionDuration: Duration.zero, …)`
— an outside tap closes it and never reaches the map; system back closes it.
Body: `Theme(residuumTheme)`, `Material(transparency)` in
`crawlFrameDecoration`, padding 10, title `displaySection`, rows ≥ 48 dp
tall. Pop-up bodies get the bloc explicitly
(`BlocProvider.value(value: bloc, child: BlocBuilder<GameBloc, GameViewState>(…))`)
and every choice reads **`bloc.state` at tap time**, then pops the route,
then dispatches.

- **Spells** (`spells_popup.dart`, owns `readiedSpellCount = 3`):
  title `SPELLS`; no spells → `You know no spells yet.` (`textLineDim`);
  else one row per `knownSpells.take(readiedSpellCount)` keyed
  `spell:<id>`: `spellMark(spell)` 22, gap 8, name
  `'${school.schoolMarking} ${name}'` (`textSlot`, `textSlotArmed` when
  armed, `textSlotDisabled` when refused), meta `monoSlotMeta`:
  armed → `— armed`; refused → the refusal capitalised; else
  `'${manaCost} mana · ${effectOf(spell)}'`. Beyond three: row
  `spells-overflow` `+N more spells` (`ShippedMark(ActionIcon.more)`) opens
  `openGrimoire` — today's `_openSpellsOverflow` sheet and `_OverflowRow`,
  moved verbatim. `chooseSpell(bloc, spell)` (moved `_onSpell`, reading
  `bloc.state`): `castRefusal(spell) != null` → `CastPressed(spell.id)` (the
  rules refuse, the log shows the refusal, no turn is spent); mend/ward →
  `CastPressed`; else `SkillArmed(armed == spell.id ? null : spell.id)`.
  Available in and out of combat; the armed flow (reticles, tap to cast,
  stray tap disarms) is unchanged.
- **Quick** (`quick_popup.dart`): `typedef PotionKind = ({Item item, int count});`
  `List<PotionKind> potionKinds(List<Item> inventory)` — items with
  `base.isPotion`, grouped by `displayName` in first-appearance order,
  `item` = first of its group. Title `QUICK`; none → `You carry nothing to drink.`;
  else a row per kind keyed `drink:<item.id>`: potion mark, `displayName`,
  meta `'×$count · heals ${item.base.heal}'`; tap → pop, `DrinkPressed(item.id)`.
  Two taps: slot, row. `QuickDrinkPressed`, `_onQuickDrinkPressed`,
  `firstPotion`, `potionCount` are deleted.
- **Quests**: title `QUESTS`, line `Quests are coming soon.` No quest state.

### G10 Map overlays (`map_overlays.dart`, `map_overlay_layout.dart`)

`MapOverlays(state, size)` is the only widget that positions anything over
the map. Children, in paint order: turn-order strip (T09), place pop-up (T06),
target card (T08), recenter pill (T06 moves it in).

Pure placement (`map_overlay_layout.dart`):
```dart
Rect heroBlock(Rect hero) => Rect.fromLTRB(hero.left - hero.width - 4, hero.top - hero.height - 4, hero.right + hero.width + 4, hero.bottom + hero.height + 4);
Rect placeMapOverlay({required Size map, required Size size, required Rect hero, required List<Offset> preferred, List<Rect> avoid = const []});
```
Candidates = `preferred` then the four corners (TL, TR, BL, BR at margin
`crawlOverlayMargin = 8`); each top-left is clamped per axis into
`[8, max(8, map − 8 − size)]`. Return the first clamped rect that: pass 1
overlaps neither `heroBlock(hero)` nor any `avoid`; pass 2 misses
`heroBlock(hero)`; pass 3 misses `hero`; pass 4 has the smallest overlap area
with `hero` (ties by candidate order). `Rect.overlaps` (touching edges do not
overlap). At the target map (392.7 × 568.8) pass 2 always succeeds for both
overlays, so neither ever covers the hero or its four neighbours there.

- **Place pop-up** (T06, `place_actions.dart` + `place_popup.dart`):
  `enum PlaceVerb { pickUp, gather, moveOn, ascend, descend, leave }` with
  `List<PlaceVerb> placeVerbsFor(GameViewState)` in that order (the old bar's
  relative order) from the existing getters, and
  `List<String> placeFacts(GameViewState)` — today's `_notesFor` texts and
  order verbatim (`doneAtTheBottom`, `Underfoot: …`, `Here: … and N more`).
  Shown iff `placeVerbsFor` or `placeFacts` is non-empty (a full pack keeps
  the `Here:` fact without a button — §7 Q4). Width
  `min(map.width − 16, crawlPlacePopupWidth 300)`; padding 10; fact lines
  `monoMeta`, 1 line each, ellipsis, `crawlCalloutLineHeight × s`; gap 6
  when both; buttons 48 tall: one verb → full width, two or more → two
  columns `(w − 20 − 6)/2`, row gap 6. Height =
  `20 + facts × 14·s + (facts>0 && verbs>0 ? 6 : 0) + rows × 48 + max(rows − 1, 0) × 6`.
  Button: `Material(crawlSlotFill, 1 dp crawlFrame, radius 6)` + `InkWell`,
  `Row(center)[ActionMarkView 18, 6, FittedBox(scaleDown) label textSlot]`,
  keyed `ValueKey(verb id)`, semantics button + label. Dispatch per G6
  (unchanged handlers; `doneControl`, `doneAtTheBottom`, `leaveDungeon`,
  `suspendDungeon`, `_confirmCompletion` (made public as `confirmCompletion`), `leaveEncounter` move from
  `game_screen.dart` to `crawl_exits.dart`). Preferred positions: below the
  hero block `(hc.dx − w/2, block.bottom + 6)`, then above
  `(hc.dx − w/2, block.top − 6 − h)`; avoid: strip rect (T09), recenter
  rect when shown. Card-like fill `crawlCalloutFill`, frame `crawlFrame`.
  Positioned child → input only inside its bounds; the map receives every
  tap and drag outside it.
- **Target card** (T08, `target_card.dart`, renamed from `map_callout.dart`):
  actor = `state.inspectedActor ?? (state.isBattleOpen ? state.targetActor : null)`;
  hidden when its cell rect does not overlap the map. Content: name
  (`displayName` role), `CrawlMeter(label 'HP', barHeight 5, crawlEnemy)`,
  then `targetFactLines(actor)`. Reach wording in `target_facts.dart`:
  reach 1 → `Melee only`, reach r > 1 → `Ranged, reach r`. Width 172; height
  `20 + 17·s + 4 + 13·s + 3 + 5 + 4 + lines × 14·s`. Preferred: right-above
  `(t.right + 14, t.top − 6 − h)`, left-above `(t.left − 14 − w, t.top − 6 − h)`,
  right-below `(t.right + 14, t.bottom + 6)`, left-below `(t.left − 14 − w, t.bottom + 6)`;
  avoid: target cell `t`, place pop-up rect, strip rect, recenter rect.
  Leader line and dot as today, from the cell corner facing the card to the
  card's nearest corner. The card absorbs taps inside its bounds (as the
  callout does). Timeline tap = `TimelineActorSelected` only; the enemy
  sheet (`showEnemyInfo`, `_EnemyInfoLine`) is deleted.
- **Turn-order strip** (T09, `turn_order_strip.dart`, renamed from
  `battle_view.dart`): shown iff `isBattleOpen`; full map width, height
  `crawlStripHeight (48) × s`; fill `crawlCalloutFill`, 1 dp `crawlFrame`
  bottom (top when flipped); one line: padding 8, `NOW` `displayLabel`, 6,
  NOW pill, divider 1×24 `crawlDivider` margin 8, `NEXT` label, 6, visible
  NEXT pills (spacing 6), then a `+N` cue pill (`monoToken`, 1 dp
  `crawlChipBorder`, key `turnOrderMoreKey`, semantics `N more in the turn order`)
  when tokens are hidden. No scrolling. Pill internals, identity, ordinals,
  hero/actor keys and secrecy (`activationQueue`) unchanged; each token's hit
  box is the full strip height and ≥ 48 wide. Fit:
  `int tokensThatFit(List<double> widths, double available, double spacing, double Function(int hidden) cueWidth)`
  over the NEXT pills (`available` = strip width − padding − the NOW group
  − divider − `NEXT` label): all `n` when `Σwidths + spacing·(n−1) ≤ available`;
  otherwise the largest `k` (≥ 0) with
  `Σwidths[0..k) + spacing·k + cueWidth(n − k) ≤ available`. Widths measured with `TextPainter` in
  `monoToken`/`monoTokenHostile` under `MediaQuery.textScalerOf` (each width =
  `max(48, glyph + 5 + word + 16 + 2)`, the hit box). Flip: when the hero cell overlaps the top strip
  rect, the strip sits at the map bottom with a 64 dp right inset (clear of
  the recenter pill).

### G11 Conventions and cutover

- No comments in bodies and **no new dartdoc in `packages/app`** (AGENTS: dartdoc
  only on core/content public API). Stale dartdoc on a touched symbol is
  deleted, not rewritten. `fontFamily` only in `tokens.dart`; no `copyWith`
  of tokens; new styles are existing roles.
- Deleted by the unit: `hero_panel.dart`, `combat_panel.dart`,
  `crawl_action_row.dart` (`CrawlAction`, `CrawlActionBar`, `actionRowKey`),
  `ColumnDivider`, `crawlHeaderHeight`, `crawlHeroPanelHeight`,
  `crawlCombatPanelHeight`, `crawlEventsHeight`, `crawlActionBarHeight`,
  `crawlSlotPeek`, `crawlTimelineHeight`, `_actionsFor`, `_notesFor`,
  `_NotesOverlay`, `_onSpell` (moved), `showEnemyInfo`, `QuickDrinkPressed`,
  `firstPotion`, `potionCount`, `GameBloc.heroLabel`, and every token left
  with no `lib` consumer (expected `displayWordmark`, `crawlGoldRule`,
  `monoFigure`, `monoFigureCold`, `displayNameCold` — grep; remove from
  `type_authority_test`'s role table).
- `packages/core` and `packages/content` are untouched
  (`git diff --stat 4b8bd10 -- packages/core packages/content` empty).
- Tests: bloc/state tests for availability; pure unit tests for pure
  functions; widget tests only for what a bloc test cannot observe (layout,
  pop-ups, notices, overlays, full-screen clearance). No goldens. A test that
  pins retired presentation is deleted or rewritten to the behaviour it
  defended, never re-pinned. Layout assertions compare rects across states
  (equality/containment), never device figures.
- Device-only facts (system bars, cut-out, gesture nav, finger feel) are
  proved on the device, not by wiring tests.

## 3. Task graph

Sequential, one fresh `flow-plan-executor` per brief, non-isolated on this
branch, one writer at a time, one local Conventional Commit per accepted task
(no push). Each handoff leaves the full app suite green.

```
01 full-screen                (native immersive, gesture clearance)
 → 02 map-cell-camera         (24×30, glyph scale, hero-centred camera, bounded pan, recenter)
 → 03 touch-step-zone         (48 dp step box)
 ══ CHECKPOINT A (Main): device — bars, cut-out inset, cell pitch, camera, pan/recenter,
    optional early user finger check; Main updates `onTheTargetPhone` top inset ══
 → 04 hud                     (HUD; hero/combat panels + wordmark removed; layout test rewrite)
 → 05 log-row-wait-flee       (offersWait; Wait/Flee beside the log; CrawlSlot)
 → 06 place-popups            (placeVerbsFor/placeFacts; MapOverlays; placement; crawl_exits)
 → 07 bottom-menu             (menu; Spells/Quick/Quests pop-ups; bar deleted; verb-reachability test)
 → 08 target-card             (callout → card; HP bar; reach wording; sheet removed)
 → 09 turn-order-strip        (strip overlay; +N cue; dock row removed; final layout invariants)
 → 10 docs-supersession       (VISUAL-SYSTEM.md)
 → Main: LEDGER locked section + RESUME, final gates, acceptance review, device gate, sign-off
```

Why this order: full-screen and the map are independent of chrome and carry
the unit's biggest device risk, so Checkpoint A sees them before any chrome
time is spent. Chrome migrates one surface at a time from the top down so
every intermediate state keeps every verb reachable: Wait/Flee leave the bar
(05), then place verbs (06), then the bar itself goes when the menu and its
pop-ups exist (07). The card (08) precedes the strip (09) so removing the
enemy sheet never leaves a selected actor without facts; 09 removes the last
state-dependent chrome and so owns the final map-rect invariant.

Task 07 holds three proof clusters (menu, Spells, Quick) because the bar can
only be deleted once both pop-ups exist and keeping both surfaces would break
G6 single ownership; no valid intermediate handoff exists.

## 4. Checkpoint A (Main, after Task 03 is accepted)

1. Write `.flow/checkpoints/<head>.md` before the first ADB command; record
   it in the ledger.
2. From `packages/app`: `flutter build apk --debug`.
3. Save protocol (§6.2) backup, then
   `adb -s 192.168.18.149:42999 install -r build/app/outputs/flutter-apk/app-debug.apk`.
4. One capsule (CP-A): cold launch → bars hidden on world, town, crawl;
   home → resume, app switch → resume, edge swipe → transient bars re-hide,
   pack screen push/pop and any modal the capsule reaches (a town dialog or
   the world "Set out" confirm) → bars stay hidden;
   no content under the cut-out on world, town, crawl. Read the cut-out
   safe inset (`adb shell dumpsys window | grep -iE "cutout|safeInset"`) and
   the gesture-bar height (`dumpsys window` `navigationBars` frame) → dp.
   Measure glyph pitch (expect 66 × 82.5 px), hero centred at depth 1 near
   each floor edge, drag pans on depth 1, recenter appears bottom-right and
   works. Screenshots + receipt under `.flow/evidence/<head>/CP-A/`.
5. Offer the user an early physical-finger pass on the four neighbours
   (acceptance 10 is final; this catches a wrong cell early).
6. Restore (§6.2), verify MATCH.
7. Verdict in the ledger. On track → set `test/support/phone.dart::onTheTargetPhone`
   top inset in Task 04's brief to the measured figure (and
   `crawlGestureClear` if the gesture bar differs by > 2 dp), dispatch 04.
   Off track → scoped correction task against 01–03 with fresh proof.
   If bars are not hidden: escalate to the user before any chrome task
   (the fallback is design, not execution).

## 5. Verification ownership and final gates

Executors (from `packages/app`): record the Red, implement, then
`dart format <touched Dart files>`, `flutter analyze`, and the full
`flutter test` at handoff (sequential single writer; cutover tasks touch
shared widgets). Task 01 also runs `flutter build apk --debug`.

Main, once, on the final tree, from `packages/app`:
```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```
plus the CI type-gate block from `.github/workflows/ci.yml` run locally,
`git diff --stat 4b8bd10 -- packages/core packages/content` (empty), and a
grep that no deleted symbol (G11) remains. Widget-test layout figures, if
wanted for the ledger, are read from an **untracked** probe copy of
`crawl_layout_test.dart` (e.g. `test/widget/zz_gate_probe_test.dart` with
prints), deleted afterwards with `git status` clean — never by editing a
tracked test — and labelled widget dp, not device dp. Main updates the
LEDGER locked section and RESUME (contract §8), runs one independent
acceptance review against this plan and the contract, then the device gate
(§6). Any production change after acceptance reopens scoped acceptance and
the affected device capsules.

| AC | proof |
|---|---|
| 1 map rect identical | T04/T05/T07 partial, **T09 `crawl_layout_test`** (4 states), device DEV-EXP/DEV-BAT measurement |
| 2 HUD identical, no wordmark | T04 `crawl_hud_test` + layout test; device |
| 3 menu order, dimmed notices, Quests | T07 `crawl_menu_test`; device |
| 4 every verb reachable | **T07 `crawl_verbs_test`** (rewritten `crawl_controls_test`), T08/T09 migrate their slices |
| 5 spells | T07 widget + state tests (untargeted out of combat, arm/reticle/cast, refusals) |
| 6 two-tap drink | T07 widget tests in and out of combat |
| 7 Watched Wait | T05 state + bloc tests (`offersWait`, Wait advances the stall), device DEV-BAT |
| 8 place pop-ups | T06 unit + widget tests; device |
| 9 strip + card | T08 card/reach tests, T09 fit/cue tests (≥ 4 actors); device |
| 10 cell, finger, pan | T02/T03 geometry + resolver tests; CP-A; **user finger check** DEV-FINGER |
| 11 full-screen | T01 clearance widget test + build; CP-A + DEV-FS |
| 12 gates | executors per task; Main final |
| 13 device review, saves | §6 |

## 6. Device acceptance (Main, after final gates and acceptance review)

### 6.1 Capsules (vivo I2505, serial `192.168.18.149:42999`, colour-first, synthetic ADB input unless stated)

- **DEV-FS**: G1 re-entry matrix (as CP-A step 4) on the final APK;
  bottom menu slots tap correctly with gesture navigation; an upward swipe
  from the menu reveals and then re-hides the bars without triggering a
  slot; nothing under the cut-out in crawl, town, world.
- **DEV-EXP**: fresh game (saves backed up). Exploration and Watched: HUD
  (HP/mana/gold same place, no wordmark), menu order, the three dimmed
  notices, Hero → pack → back, place pop-ups (items, ore/herb, stairs down,
  stairs up, Leave, Finish at the bottom if reached), pop-up never over the
  hero, taps/drag outside it reach the map, auto-walk, pan and recenter on
  depth 1 and on the deepest floor reached. Map rect measured (HUD bottom
  edge to the log frame's top border, px ÷ 2.75) in exploration and Watched.
- **DEV-BAT**: road and dungeon fights: map rect in battle and armed (when a
  targeted spell is available) equal to exploration; strip with 1 and ≥ 4
  actors (`+N` cue, no clipping); target card beside the target, never over
  the hero, `Melee only` / `Ranged, reach r`; Wait while Watched in a
  dungeon ends the UXW-BAT 27–32 stall; Flee at a road edge; Move on;
  two-tap drink in battle; spells in/out of combat if the hero knows any.
- **DEV-FINGER (user)**: on a depth-1 floor the user taps each of the four
  floor cells next to the hero with a finger and the hero steps there; drags
  to pan; uses recenter; repeats pan/recenter on the deepest floor available
  (§7 Q5). Main records the user's words verbatim.
- Screenshots + one receipt per capsule under `.flow/evidence/<head>/<capsule>/`;
  an independent reviewer scores them against the contract; the user signs
  off.

### 6.2 Save backup and restore (every install, every capsule)

1. `adb -s $DEV shell am force-stop com.example.residuum_app`.
2. Back up both slots from the live path `app_flutter/` (not
   `files/app_flutter/`):
   `adb -s $DEV exec-out run-as com.example.residuum_app cat app_flutter/save.json > .flow/evidence/<head>/save-backup/save.json`
   (same for `save-previous.json`); record sha256 of both. Compare with
   `.flow/evidence/4b8bd10/save-backup/` hashes (`b23d9787…`, `b5214b48…`):
   differing means the user played since — the fresh pull is the truth.
3. After the capsule: force-stop; `adb -s $DEV push <backup> /data/local/tmp/restore-save.json`
   (and `restore-save-previous.json`), `adb -s $DEV shell chmod 666 /data/local/tmp/restore-*.json`,
   then the whole run-as command as **one single-quoted argument**:
   `adb -s $DEV shell 'run-as com.example.residuum_app sh -c "cat /data/local/tmp/restore-save.json > app_flutter/save.json"'`
   (same for previous). Direct stdin piping into `run-as` fails on this
   device.
4. Verify: `exec-out run-as … cat app_flutter/save.json | sha256sum` equals
   the backup hash for both slots (same scheme on both sides → `MATCH`);
   delete `/data/local/tmp/restore-*.json` and confirm absence. Restore from
   the backups, never from the device (the save rotation drifts the
   previous slot).
5. The app stays installed on the final APK with the user's saves restored.

## 7. Contract questions for Main (WHAT decisions) — resolved

**The user accepted every default below on 2026-09-24** (Q1 follow the
contract, Q2 keep `Finish`, Q3 no gesture exclusion, Q4 fact without Pick
up, Q5 verifier plays down, Q6 keep). These are locked; do not reopen.

- **Q1 Road Wait before engagement.** Today a road fight offers Wait before
  anything holds reach, even with no monster in sight. The contract limits
  Wait to combat and Watched. *Default: follow the contract* (`offersWait`
  as G6); on a road with no monster in sight the player walks or flees. If
  the user wants road Wait kept, `offersWait` gains `|| (isEncounter && !isRoadClear)` — one line in Task 05.
- **Q2 "Leave or Done".** The contract names "Done"; the control says
  `Finish` today. *Default: keep `Finish`* (and its confirm dialog).
- **Q3 Side edges under gesture navigation.** A drag starting inside the
  system back-gesture zone triggers back (refused in the crawl with a log
  line) instead of panning. *Default: no native gesture exclusion*; no
  control sits in the edge zone and interior drags pan. The alternative is
  native `setSystemGestureExclusionRects` over the map band (Android caps it
  at 200 dp per edge) through a platform channel.
- **Q4 Items underfoot with a full pack.** *Default: the pop-up still shows
  the `Here:` fact without a Pick up button* (today's note), a superset of
  "appears exactly when its action applies".
- **Q5 Deepest-floor device evidence.** Acceptance 10 asks for pan/recenter
  on a deepest floor. *Default: the DEV-EXP verifier plays a fresh game down
  (saves backed up)*; if it cannot reach depth 5 in the capsule, Main asks
  the user (their own save, or an explicitly approved synthetic save).
  Headless proof for the deepest floor size exists in T02 regardless.
- **Q6 Timeline selection moves the camera.** Selecting a turn-order token
  focuses the camera on that monster (existing, tested); recenter returns
  to the hero. *Default: keep* as an explicit look-at like a pan.

## 8. Escalations and residual risks

- Native immersive behaviour on this vivo build (OEM overlays, transient-bar
  timing, IME) is proved only on the device (CP-A, DEV-FS).
- The cut-out inset and gesture-bar height are planning figures until CP-A.
- ATK/ARM, weapon and armour names and the hero's name leave the crawl until
  Unit 16.7's Hero screen (pack screen still shows gear); contract-accepted.
- Long item names ellipsize in the place pop-up `Here:` line; the full name
  is in the pack. At text scale 1.3 `doneAtTheBottom` may ellipsize.
- Strip fit uses `TextPainter` widths; school markings and `✳ ✚ ⛒` render
  from fallback fonts on some hosts, so widget-test widths may differ from
  device widths (strip tokens use monster glyphs and Plex-covered ordinals,
  which is why the risk is small).
- A walk in progress continues while a menu pop-up is open; the choice acts
  on the live state.
- Finger feel of the 48 dp step box is only proved by DEV-FINGER.

## Plan quality gate

- **COR — PASS.** One projection authority (G3) for renderer, atmosphere,
  input and every overlay; one availability owner per verb (G6) with stable
  ids; `offersWait` defined on the header's Watched predicate; spells outside
  combat and Wait-while-Watched reach core, which decides; refusals route
  through `CastPressed` so they are logged and cost nothing; pop-up choices
  read live `bloc.state`; placement has a total, deterministic fallback
  chain that provably keeps the hero block clear at the target size; pan is
  bounded with no dead travel; secrecy unchanged (card uses
  `inspectedActor`/`targetActor` guards, strip uses `activationQueue`);
  full-screen re-entry ordered after Flutter's own `onPostResume`
  re-application; every intermediate task state keeps every verb reachable.
- **TTC — PASS.** Each task names its first failing proof and expected Red:
  camera centring/pan clamp/visible FOV band, 47.9/48.1 dp step-box edges and
  tie/diagonal/centre cases, `offersWait` matrix and the Watched-stall bloc
  test, `placeVerbsFor`/`placeFacts`/`placeMapOverlay`/`potionKinds`/
  `tokensThatFit` unit tests, pop-up/notice/two-tap/arm/refusal widget
  tests, layout rect equality across four states, ≥ 4-actor cue, reach
  wording, hero-avoidance for every overlay, gesture clearance. Device-only
  claims are CP-A and §6.
- **CRF — PASS.** Retires the bar, both panels, the dock row, the notes
  overlay, the enemy sheet, quick-drink, the hero label plumbing and orphan
  tokens instead of shimming; extracts `CrawlSlot`/`CrawlMeter` only because
  each has three consumers; one overlay-layout owner; no per-frame
  allocation beyond a handful of `TextPainter`s for the strip (disposed);
  Task 07's three clusters are justified as inseparable.
- **SEC — SKIP (no new trust boundary).** Offline presentation and one
  native window call; the only secrecy boundary (hidden actors and map
  knowledge) is covered under COR/TTC.
- Residual risks deliberately left to device evidence: §8; open WHAT
  questions: §7.

## 9. Amendment 2026-09-25 — action card and icon-only menu slots

Governing: contract amended at `f1db13f` (action card: settled decisions 6
and 8, scope §1 item 3, §4, acceptance 7 and 8) and `87344e7` (scope §1
item 4: menu slots icon above label, no metadata). Derived from head
`87344e7`; app code last changed at `4de51c3` (`git diff --stat 4de51c3 --
packages` empty). Dirty state assumed: none outside `.flow/`. Tasks 01–10
and the `4de51c3` correction stay as implemented and accepted; this section
supersedes only the locks named here.

### Superseded locks

- G5: `LogRow` is the log only (no side controls); composition otherwise
  unchanged.
- G6 rows `wait`, `flee` and the place-verb row: surface is the **action
  card**; availability owner is `cardVerbsFor(state)` over the unchanged
  `canPickUp`, `canGather`, `isRoadClear`, `canAscend`, `canDescend`,
  `canLeave`, `canFlee`, `offersWait`. Ids and labels unchanged.
- G8: the side-controls paragraph is retired. `CrawlSlot` loses metadata
  (G13).
- G9: the metadata column of the menu table is retired (Spells armed keeps
  its frame and glow, not the `— armed` text).
- G10: the place pop-up bullet is replaced by G12; the target card's
  `avoid` loses the pop-up rect and gains an `area`; the recenter pill may
  lift above the card.
- §6 capsules for this amendment: §9.4.

### G12 Action card (Task 11)

- **Content and order:** `cardVerbsFor` = Pick up, Mine/Gather, Move on,
  Ascend `<`, Descend `>`, Leave/Finish, Flee, Wait (the place order Task
  06 shipped, then Flee, then Wait last). Facts above the buttons as the
  pop-up had them. Shown iff any verb or fact applies (Q4 kept; Q7).
- **Buttons:** `CrawlSlot`, 48 dp tall, four per row, fixed width
  `(W − 16 − 20 − 18) / 4` (≈ 84.7 dp at 392.7 dp), rows start-aligned.
  Four per row keeps every realistic combat set on one row: in combat at
  most Wait + Flee + Pick up (road) or Wait + Pick up + stairs + Leave
  (dungeon).
- **Height:** `20 + facts × 14·s + (facts && verbs ? 6 : 0) + rows × 48 +
  (rows − 1) × 6`, `rows = ⌈verbs / 4⌉`. Examples (widget dp, test profile,
  map ≈ 561.9 at s 1.0, ≈ 489.9 at s 1.3; executor re-reads by probe):
  Wait alone 68; 2 facts + 4 verbs at 1.3: 110.4; largest reachable (3
  facts + 5 verbs) 170 at 1.0, 182.6 at 1.3.
- **Placement:** bottom edge, `left = 8`, `width = W − 16`,
  `bottom = H − 8` (above a flipped strip: `strip.top − 8`). If that rect
  overlaps `heroBlock(hero)` (hero cell, four neighbours, diagonals, +4 dp),
  top edge: `top = 8`, or `strip.bottom + 8` under the top strip. If both
  overlap, the smaller block overlap wins, ties to the bottom.
  **Guarantee** (proved by sweep): never over the hero block at s 1.0 for
  every reachable content, and at s 1.3 for up to four buttons, with or
  without the strip. Beyond that (five buttons at s ≥ ~1.2 in battle) a
  ≈ 15 dp band of hero positions exists where both edges touch the block;
  see §9.6.
- **Leader line:** `LeaderPainter` shared with the target card (gold at
  0.7 alpha, 1 dp, 2.5 dp dot at the hero end), vertical from the centre of
  the hero cell's edge facing the card to the card's facing edge, the card
  end clamped 6 dp inside the card's corners. Hidden when the hero cell is
  outside the map (panned away); the card stays.
- **Frame:** `crawlCalloutDecoration`, shared by both cards.
- **Coexistence:** strip (unchanged rule; the card sits clear of it on
  either edge); target card placed only inside the map band the action card
  leaves free (`placeMapOverlay(area:)`), so they never overlap on any pass;
  recenter pill lifts to `card.top − 8` when it would overlap; armed
  targeting unchanged (a tap inside the card is absorbed and does not
  disarm; a spell target under the card needs a pan); the half and full
  log drawer still cover the lower map and the card, as they covered
  Wait/Flee (one tap closes).
- **Map rectangle:** unchanged; the log row keeps 104 × s, now full-width
  peek.

### G13 Menu slots (Task 12)

`CrawlSlot` renders mark above label, centred both ways, nothing else;
semantics label is the word (`, unavailable` when dimmed). The menu drops
`×N`, `n/cap` and `— armed`.

### 9.1 Task graph

```
(accepted 01–10, correction 4de51c3, DEV-FS/EXP/BAT/FINGER at 9db8ea5)
 → 11 action-card        (CardVerb/cardVerbsFor, ActionCard, placement, leader,
                          target-card area, log row full width, VISUAL-SYSTEM)
 → 12 menu-slots         (CrawlSlot icon+label only; menu metadata removed)
 → Main: LEDGER/RESUME, final gates, scoped acceptance, §9.4 device re-check,
         user sign-off
```

11 and 12 share no file (`crawl_slot.dart` is used, not edited, by 11) and
either order leaves a valid handoff; run them one at a time in this
checkout, 11 first, one fresh `flow-plan-executor` each. Task 11 holds the
card, the log row and the target-card area together: removing Wait/Flee
from the log row without the card (or the pop-up without the card) leaves
a verb unreachable, and the card cannot land without the target card
avoiding it (contract §4), so no valid intermediate handoff exists.

### 9.2 Proof map (amended rows)

| AC | proof |
|---|---|
| 3 menu | T12 `crawl_menu_test` (one Text per slot, semantics word, centring at 1.0/1.3); DEV-EXP-2 |
| 4 every verb | T11 `crawl_verbs_test` (card-scoped finders) |
| 7 Watched Wait | existing bloc stall test; T11 `action_card_test` Wait case; DEV-EXP-2 |
| 8 action card | T11 `action_card_verbs_test`, `map_overlay_layout_test` (rules, sweep, leader, area), `action_card_test` (edge-pinned rect, top fallback, below strip, leader, no overflow at 1.3, map still tappable), `log_row_test` (peek full width); mutation witnesses M1–M5; DEV-EXP-2, DEV-BAT-2 |
| 9 strip + card | T11 `target_card_test` (no overlap with the action card) |

### 9.3 Gates

Main, once after Task 12, from `packages/app`: format check, analyze, full
suite (§5), `git diff --stat 4b8bd10 -- packages/core packages/content`
empty, zero-hit grep for Task 11 item 8 and Task 12's `metadata`. The
acceptance at `4de51c3` is reopened for the changed surface: one scoped
`flow-acceptance-reviewer` pass over Tasks 11–12 against this section and
contract items 1.3, 1.4, §4, AC 3, 4, 7, 8, 9, including a placement probe
(untracked) over three map sizes like the `4de51c3` closure.

### 9.4 Device re-check (Main, vivo I2219)

Serial `DEV='adb-10DF1Q03JJ000HK-LUqZxk (2)._adb-tls-connect._tcp'` (quote
it). Checkpoint file `.flow/checkpoints/<head>.md` before the first ADB
command; `flutter build apk --debug`; §6.2 backup (the app is installed
from DEV-FS/EXP/BAT; any saves on it are the verifier's or the user's —
back up and restore whatever is there), `adb -s "$DEV" install -r …`.

- **DEV-EXP-2** (fresh game, synthetic input): no card on a bare floor;
  card at the map's bottom edge, full width, leader to the hero, for Pick
  up, Mine or Gather, Descend + Leave, Ascend + Leave; the hero and its
  four neighbours clear; drag the hero low → card moves to the top edge;
  taps and drags outside the card reach the map; Watched → Wait in the card,
  one tap advances the game; the log row is the full-width log in
  exploration and Watched; menu slots show icon above word, no `×N`/`n/cap`
  with potions carried; map rectangle measured (px ÷ 2.75) equal across
  states and to the `9db8ea5` figure.
- **DEV-BAT-2**: road fight: Wait (and Flee when at the ring edge) in the
  card, strip at the top, card at the bottom; pan the hero low in battle →
  card below the strip; inspected target card never overlapping the action
  card; cleared road → Move on in the card and the area around the hero
  open (the user's complaint); Spells slot armed shows frame/glow only;
  half drawer open → note that it covers the card, close it, Wait works.
- Reused with rationale: **DEV-FS** (no native, `SafeArea` or menu hit-box
  change: slot rects are unchanged by G13) and **DEV-FINGER** steps 1–5
  (`map_touch.dart`, camera and step box unchanged; the card never covers
  the hero block at s 1.0). The user's sign-off round re-checks feel.
- Evidence under `.flow/evidence/<head>/DEV-EXP-2/` and `/DEV-BAT-2/`;
  independent scoring against contract §4 and AC 3, 7, 8; §6.2 restore with
  `MATCH`; at unit end the app is uninstalled (the phone had none before).
- **User sign-off** on the device: card position and leader, Wait/Flee
  placement, cleared-road exploring, menu slots. Record verbatim.

### 9.5 Contract questions for Main (WHAT) — resolved by the user, 2026-09-25

- **Q7 Fact-only card: show the fact, and say the pack is full.** With a
  full pack and an item underfoot, the card shows the `Here:` fact with no
  Pick up button, plus the fact line `You cannot carry any more.` (the
  existing `InventoryFull` log sentence in `event_messages.dart`, reused
  verbatim so the two cannot drift). The line appears only when
  `itemsUnderfoot` is non-empty and the inventory is at `inventoryCap`.
- **Q8 Armed Spells slot: heavier frame, no text.** The `— armed` text is
  removed; while a spell is armed the Spells slot's frame is 3 dp (twice the
  1.5 dp armed frame) in `crawlCold`, plus the existing glow, so armed reads
  by shape, not hue alone.

### 9.6 Residual risks

- Five or more buttons at text scale ≥ ~1.2 in battle with the hero panned
  into a narrow band: both edges touch the hero block and the smaller
  overlap is taken. Reaching five buttons in combat needs loot and a node on
  a stairs cell; accepted as residual unless Main asks otherwise.
  In that regime the target card can also land on the hero block's
  neighbour cell holding the adjacent target (review N1), so a tap on that
  target meets its own card until the player pans. 0 cases at text scale
  1.0 on either phone in the review's probe.
- **Text scale 1.3 in battle (D1 follow-up, accepted by Main 2026-09-26):**
  after `844cba1` and `7d99bea` the target card never covers the strip,
  the action card or the hero cell at any scale, and never covers the
  adjacent target at scale 1.0 (full grid swept). At scale 1.3 with tall
  cards it can still cover the adjacent target's cell for some hero
  positions: 34 of 90 swept (map × facts × button rows × target lines)
  combinations, mostly with 2 button rows and 3–4-line targets. A centred
  hero on a 392.7 dp map leaves no side room for the 172 dp card, and at
  1.3 there is not always vertical room. The player pans once to reach the
  target. The exact set is asserted in `map_overlay_layout_test.dart`.
- The card covers the lower map band (≈ 76–190 dp) while it shows; a
  distant monster there needs a pan to be tapped. The target cell's card
  may draw its leader across the action card.
- The open log drawer covers the card (as it covered Wait/Flee).
- Button labels shrink to fit in 84.7 dp at s 1.3 (`Descend >` the
  longest); readability is a device check.

### Plan quality gate (amendment)

- **COR — PASS.** One availability owner (`cardVerbsFor`) over unchanged
  getters; one placement owner (`map_overlay_layout.dart`) with a total,
  deterministic two-edge rule; target card confined to the free band so no
  pass can overlap the card; recenter lifted; every overlay child
  `Positioned`; map rect and log row height unchanged; no bloc change; every
  intermediate commit keeps every verb reachable.
- **TTC — PASS.** Rules, sweep guarantees, leader and area are unit-tested
  with literal expectations; widget tests derive expectations from the map
  rect and margins, not the implementation; value-level Red on peek width
  and menu slot content/centring; M1–M5 mutation witnesses prove the
  geometric assertions can fail; retired presentation tests are rewritten
  to behaviour (log row, menu metadata), not re-pinned.
- **CRF — PASS.** Renames instead of aliases; deletes the pop-up, side
  controls, their constants, the private painter and duplicated decoration;
  shares one painter and one decoration between two cards; no block-action
  hook; `CrawlSlot` narrows to what the menu and card use.
- **SEC — SKIP.** Offline presentation only; no trust boundary or secrecy
  surface changes (the card shows only the hero's own cell).
- Residual risks left to device evidence: §9.6; WHAT questions: §9.5.

## 10. Amendment 2026-09-28 — action bar row, events strip, full log page

Governing: contract amended at `75d8330` (settled decisions 8 and 12, scope
§1 items 2–3, §4, new §4a, the protected-boundary exception for the hero's
step line, acceptance 7–8). Derived from head `75d8330`; app code last
changed at `7d99bea` (`git diff --stat 7d99bea 75d8330 -- packages` empty).
Dirty state assumed: only the user's untracked `tmp1.png` at the repo root
(not touched, not staged). Tasks 01–12 and the `844cba1`/`7d99bea` D1
corrections stay as accepted; this section supersedes only the locks named
here.

### Superseded locks

- **G5 composition** → G14 (Task 13, intermediate) and G15.1 (Task 14, final).
- **G8 log row** is retired by Task 14 (the events strip and the log page
  replace `LogRow`, `LogPeek` and the half/full drawer).
- **G10**: the recenter pill lifts above the events strip; the flipped
  turn-order strip sits on the events strip's top edge; the target card's
  `area` loses the action-card carve-out (Task 13) and gains the events
  strip carve-out (Task 14).
- **G12 action card** is retired entirely: no on-map card, no pinning, no
  leader for it, no recenter lift over it, no target-card carve-out for it.
  Its verbs, ids, labels, marks, dispatch, `cardVerbsFor`/`placeFacts`
  ownership and the Q7 full-pack line carry over unchanged to the bar.
- **§9.6 residuals** tied to the card (five buttons in battle, the target
  card on the adjacent target at 1.3, the card covering the lower map band,
  the drawer covering the card) lapse with the card; the target-card sweep
  is re-run in Tasks 13–14 without the card.

### G14 Action bar (Task 13)

- **Row.** `ActionBar(key: actionBarKey, bloc, state)` in its own fixed row
  between the map and the bottom menu, full width, `crawlGutter` (8) side
  padding, frame `crawlFrameDecoration` (panel fill, 1 dp `crawlFrame`,
  radius 6), inner padding `crawlActionBarPadding` (6) on all sides. It is
  not on the map, absorbs nothing on the map, and has no leader.
- **Constant height** `actionBarHeight(s) = 2·6 + 16·s + 4 + 3·14·s + 6 + 48
  = 70 + 58·s` → **128.0 dp at s 1.0, 145.4 dp at s 1.3**, in every state.
  It is sized for the worst reachable content: 3 fact lines (e.g.
  `doneAtTheBottom` + `Here:` + the full-pack line, or `Underfoot:` +
  `Here:` + full-pack; a node never sits on stairs, `GatherKind` docs) and
  one row of up to 4 buttons (dungeon: Pick up, Ascend or Descend, Leave,
  Wait; road: Pick up, Move on or Flee, Wait — Move on excludes Wait).
- **Body, top to bottom:** title row `16·s` with `ACTIONS` in
  `displaySection` (the display role, letter-spaced capitals, the role the
  old `RECENT EVENTS` peek title used); gap 4; the fact lines actually
  present (`monoMeta`, one line each, ellipsis, `crawlCalloutLineHeight × s`
  tall, at most 3) or, when `cardVerbsFor` and `placeFacts` are both empty,
  the quiet line `actionBarIdle = 'Nothing to do here.'` (`monoMeta`); gap 6
  only when a fact line was drawn; then the button row, 48 tall. **Amendment
  (user, 2026-09-28):** the button row sits directly below the last drawn
  text line; the unused fact space falls to the bottom of the bar as
  padding. The bar's outer height stays `actionBarHeight(s)` in every state.
- **Amendment 2 (user, 2026-09-28): one fact line.** The fact zone holds a
  single line: `placeFacts` joined with ` · ` (or the quiet line), one line,
  ellipsis. `actionBarHeight(s) = 2·6 + 16·s + 4 + 14·s + 6 + 48 = 70 + 30·s`
  → **100.0 dp at s 1.0, 109.0 at s 1.3**; the map gains 28 dp (36.4 at
  1.3) and is still identical in every state. The line's semantics label
  carries the full, un-ellipsized joined text. This supersedes the
  three-line zone above and the "more than 3 facts" rule below; D10's
  128 dp figure is superseded. Tests and sweeps that used the old bar or
  map heights are updated to the new measured figures; the target-card
  sweep reruns at both scales on the new map.
- **Fact lines total over fixtures:** more than 3 facts (only reachable in a
  fixture with a node on stairs) render as `facts[0]`, `facts[1]`, and
  `facts.sublist(2).join(' · ')` on the third line.
- **Buttons:** one row, `n = max(4, verbs.length)` equal slots,
  `buttonWidth = (inner − (n − 1) × 6) / n` (inner = row width − 16 − 12;
  ≈ 86.7 dp at 392.7 dp for n 4, ≈ 68.1 for the fixture-only n 5), start
  aligned, `CrawlSlot(height: crawlTouchTarget)`; labels, marks and
  dispatch exactly as `ActionCard._button` today.
- **Map rectangle**: Task 13 shrinks it by the new row (intermediate state),
  Task 14 grows it back by the removed log row; at each handoff it is
  identical across exploration, Watched, battle and armed, with or without
  verbs, and (Task 14) with the log page open or closed.

### G15 Events strip, full log page, no step line (Task 14)

1. **Final composition** (inside the existing `SafeArea` →
   `withClampedTextScaling(1.3)` → `BlocBuilder`):
   ```
   Stack[
     Column[ CrawlHud; Expanded(key: dungeonSceneSlotKey, LayoutBuilder →
               Stack[DungeonSceneHost, MapOverlays]);
             SizedBox(crawlPanelGap 6); ActionBar(key: actionBarKey);
             SizedBox(crawlGap 7); CrawlMenu; SizedBox(crawlBottomGap 6) ],
     if (state.logOpen) Positioned.fill(LogPage(key: logPageKey, …)),
     if (game over) _DeathOverlay ]
   ```
   The inner drawer `LayoutBuilder`/`Stack`, `LogRow` and its gaps are gone.
2. **Log state** (`game_bloc.dart`): `LogDrawerExtent` is deleted;
   `GameViewState.logOpen` (`bool`, default false, forced false on
   game-over by construction) replaces `logDrawerExtent` at every
   construction site; `_followsAt(game, logOpen, following) => following
   || game.isGameOver || !logOpen` (same invariant: closed anchors to
   newest). Events: `LogOpened` (inert on game-over, silent when already
   open; like today's handle it carries pan/walk/arm/selection and clears
   inspection) replaces `LogDrawerHandlePulled`; `LogClosed` (silent when
   closed) replaces `LogDrawerClosed`; `LogFollowBroken`/`LogFollowResumed`
   and `_unreadAfter` unchanged.
3. **Events strip** (`EventsStrip`, `event_log.dart`, key `eventsStripKey =
   Key('events-strip')`): map-local rect `eventsStripRect(map, s) =
   Rect.fromLTWH(0, H − h, W, h)`, `h = 6 + 3 × crawlLogLine(15) × s + 4`
   → **55.0 dp at 1.0, 68.5 at 1.3**. Content: the last `min(3, n)` log
   lines, oldest first, bottom-aligned (newest always in the bottom slot),
   each `crawlLogLine × s` tall, `maxLines: 1`, ellipsis, style
   `logTint(category)` (mono role, category tint), opacity by age
   `[1.0, 0.7, 0.45]` (newest first); horizontal padding 8; decoration
   `crawlEventsStripDecoration` = a vertical gradient from `Color(0x000B1215)`
   (top) to `crawlCalloutFill` (bottom), **no border, no title, no count**.
   `GestureDetector(behavior: opaque, onTap: game over ? null : LogOpened)`
   in `Semantics(button, enabled: !gameOver, label: 'Open the message log')`,
   placed as `Positioned.fromRect` inside `MapOverlays`, so every gesture
   inside its rect is its own and every gesture outside reaches the map.
   **Empty log → no strip widget at all** (nothing painted, no hit area);
   its rect still drives the geometry below so nothing jumps when the first
   line arrives.
4. **Placement** (`map_overlay_layout.dart`, pure; `events` is always
   `eventsStripRect`):
   - `recenterRect(Size map, {required Rect events})` =
     `Rect.fromLTWH(W − 8 − 48, events.top − 8 − 48, 48, 48)`.
   - `({Rect rect, bool flipped}) turnOrderStripRect({required Size map,
     required double height, required Rect hero, required Rect events})`:
     top band `Rect.fromLTWH(0, 0, W, height)`; flipped iff it overlaps
     `hero` (unchanged rule); flipped rect `Rect.fromLTWH(0, events.top −
     height, W − 64, height)` (the 64 dp inset keeps the recenter column
     clear, as today). Replaces the inline computation in `MapOverlays`.
   - `targetCardArea({required Size map, required Rect events, Rect? strip})`
     = `Rect.fromLTRB(0, top, W, bottom)`, `top = strip at top ? strip.bottom
     : 0`, `bottom = strip flipped ? strip.top : events.top`
     (`stripAtTop = strip.center.dy < H / 2`, as today). Both strips are
     hard area constraints (D1 lesson); the recenter stays a soft `avoid`,
     as accepted in G10.
5. **`MapOverlays` children, paint order, each `Positioned`**: turn-order
   strip (battle); events strip (log non-empty); `Positioned.fill(TargetCard(
   area: targetCardArea(…), avoid: [?recenter]))`; recenter pill.
6. **Full log page** (`LogPage`, today's `LogDrawer` body): full SafeArea
   body, `BlockSemantics(Material(color: crawlPanelFill))`, horizontal
   padding `gutter`; header row `crawlTouchTarget` (48) tall:
   `RECENT EVENTS` (`displaySheetTitle`), spacer, `N entries` (`monoMeta`),
   gap, close control `logCloseKey` 48 × 48 (`Icons.close` 18,
   `crawlTextDim`, `Semantics(button, 'Close the message log')`) →
   `LogClosed`; hairline divider; the list, scrollbar, `_LogRow`
   (pictogram + mono sentence, category word in semantics), unread pill
   `logUnreadKey` and the follow/jump logic **moved verbatim**. No handle,
   no pill, no resize. It is an in-screen full page, not a pushed
   `Navigator` route (see 10.6 D9).
7. **System back** (`GameScreen` `PopScope`): `didPop` → nothing; else
   `state.logOpen ? LogClosed() : SystemBackPressed()`. Back while the page
   is open closes it and appends nothing.
8. **Step line** (`event_messages.dart`): the hero arm of `ActorMoved` is
   deleted so `ActorMoved() => null` covers every actor; `_bearing` is
   deleted (no other caller). Every other sentence and category unchanged.

### 10.1 Planning figures (widget dp, `onTheTargetPhone`; executor re-reads by untracked probe)

| state | map @ s 1.0 | map @ s 1.3 |
|---|---:|---:|
| today (`7d99bea`, measured in the D1 sweep) | 557.9 | 520.8 |
| after Task 13 (log row + bar) ≈ −bar −6 | 423.9 | 369.4 |
| after Task 14 (bar only) ≈ today + 104·s − bar | **533.9** | **510.6** |

Device estimate at s 1.0: 569.8 → ≈ 545.8 dp (≈ 18.2 rows of 30 dp); the
events strip covers the bottom 55 dp of it. These are estimates, not
assertions: tests compare rects across states and use the literal row
heights of G14/G15 only.

### 10.2 Task graph

```
(accepted 01–12, D1 corrections 844cba1/7d99bea, DEV-BAT-3 at e913b8d)
 → 13 action-bar-row      (ActionBar row between map and menu; on-map card, its
                           placement, leader and target-card carve-out deleted;
                           VISUAL-SYSTEM "action card" → "action bar")
 → 14 events-strip-log-page (events strip over the map bottom; full log page;
                           logOpen/LogOpened/LogClosed; log row and drawer deleted;
                           recenter/flipped strip/target area avoid the strip;
                           back closes the page; step line removed)
 → Main: LEDGER/RESUME, gates 10.4, scoped acceptance, device re-check 10.5,
         user sign-off
```

Strictly sequential, one fresh `flow-plan-executor` per brief, this
checkout, no isolation. 13 then 14: the reverse order would make Task 14
re-place the on-map card around the strip only for Task 13 to delete it.
Task 13's handoff (map, log row, bar, menu) is a valid, fully tested state
with every verb reachable. Task 14 keeps the strip, page, bloc rename and
back rule together because deleting the drawer without the page (or the
page without `logOpen`) leaves the log unreachable or the follow/unread
invariant keyed on a deleted extent; no valid intermediate handoff exists.
The step-line removal is a separate Red→Green cluster folded into Task 14
because it is a one-arm deletion plus three test edits, not a task.

### 10.3 Proof map (amended rows)

| AC | proof |
|---|---|
| 1 map rect identical | T13/T14 `crawl_layout_test` (4 states, with/without verbs, page open/closed); device 10.5 |
| 4 every verb | T13 `crawl_verbs_test` scoped to `actionBarKey` |
| 7 Watched Wait | existing bloc stall test; T13 `action_bar_test` Wait case; DEV-EXP-3 |
| 8 bar + strip + page + steps | T13 `action_bar_test` (title, quiet line, facts, full-pack, constant rect at 1.0/1.3, between map and menu, no verb inside the map slot, 1.3 largest content), `map_overlay_layout_test` (area, recenter); T14 `event_log_test` (strip rect/lines/order/fade/tint/no frame, empty log, taps inside/outside, page open/close/back/follow/unread), `event_log_state_test`, `map_overlay_layout_test` (strip, recenter, flip, area, sweep), `game_bloc_test`/`log_line_test` (no step line); mutation witnesses; DEV-EXP-3, DEV-BAT-4 |
| 9 strip + target card | T13/T14 sweeps and `target_card_test` (never over either strip or the hero) |

### 10.4 Gates

Main, once after Task 14, from `packages/app`: format check, analyze, full
suite (§5), `git diff --stat 4b8bd10 -- packages/core packages/content`
empty, and a zero-hit grep in `lib` and `test` for every symbol Tasks 13–14
delete. The `7d99bea` acceptance is reopened for the changed surface: one
scoped `flow-acceptance-reviewer` pass over Tasks 13–14 against this
section and contract §1.2–1.3, §4, §4a, AC 1, 4, 7, 8, 9, including an
untracked placement probe over the real target-card heights (2–4 fact
lines at s 1.0 and 1.3) on the final widget map sizes and the device
estimate, with both strips present.

### 10.5 Device re-check (Main)

Device: the vivo I2505 `DEV='adb-10DG1E044B000B4-t0c6h3._adb-tls-connect._tcp'`
(quote it), the user's own phone holding the user's saves; if it is off ADB
and the user directs, the AVD `emulator-5554` (its own saves are backed up
at `.flow/evidence/e913b8d/avd-save-backup/` and still owed a restore).

1. Write `.flow/checkpoints/<head>.md` before the first ADB command; build
   `flutter build apk --debug`; record the APK sha256.
2. §6.2 backup to `.flow/evidence/<head>/save-backup/` **before install**;
   compare with `.flow/evidence/6971881/i2505-save-backup/`
   (`save.json` `bff83295…`, `save-previous.json` `b23d9787…`). A difference
   means the user has played since: the fresh pull is the truth and the one
   restored. `adb -s "$DEV" install -r …` (keeps app data).
3. **DEV-EXP-3** (fresh game, synthetic input): the `ACTIONS` bar between the
   map and the menu; the quiet line on bare floor; Pick up, Mine or Gather,
   Descend + Leave, Ascend + Leave with their facts; Watched → Wait in the
   bar, one tap advances; bar rect (px) identical in bare, loot, Watched
   states; map rect (px ÷ dpr) identical in exploration and Watched; no
   action overlay on the map; events strip over the map's bottom edge, three
   lines, newest at the bottom, older fading, no frame/title/count; a
   five-cell walk adds no log line; tap on the strip opens the full page
   (pictograms, sentences, close), close returns, system back closes it,
   system back on the crawl still refuses with its line; taps and drags just
   above the strip reach the map; recenter shows above the strip.
4. **DEV-BAT-4**: a road fight: turn-order strip at the top, events strip at
   the bottom, target card never over either strip or the hero; hero panned
   to the top edge → the turn-order strip flips onto the events strip's top
   edge, clear of the recenter; Wait (and Flee at the ring edge if reached)
   in the bar; map rect equal to exploration; the page opens and closes in
   battle.
5. Reused with rationale: **DEV-FS** (no native, `SafeArea` or menu change;
   the menu row keeps its rect) and **DEV-FINGER** steps 1–5 (`map_touch.dart`,
   the camera and the step box are unchanged; the hero sits at the map centre
   far above the strip at zero pan). The user's sign-off round re-checks feel.
6. Evidence under `.flow/evidence/<head>/DEV-EXP-3/` and `/DEV-BAT-4/`;
   independent scoring against contract §4, §4a and AC 1, 7, 8, 9; §6.2
   restore from this round's backup with `MATCH` on both slots; the app
   stays installed on the I2505 (it is the user's phone).
7. **User sign-off** on the device: bar placement and height, quiet line,
   strip legibility over the map, the full log page, steps not logged.
   Record verbatim. Still owed outside this plan: the AVD restore, and the
   I2219 restore and uninstall (checkpoint `6971881`).

### 10.6 Decisions — resolved 2026-09-28

The user chose D10 128 dp with the title on its own line, D11 the soft
fade, and D13 keeping the title and count on the page. Main kept D9
(in-screen page) and D12 (no strip on an empty log) as defaults, since
neither changes what the player sees. All five are locked.

- **D9 In-screen full page, not a pushed route.** The page is a full-body
  layer driven by `logOpen`: game-over closes it by construction, the
  follow/unread invariant stays keyed on bloc state, back is routed by the
  existing `PopScope`, no second `BlocProvider`. Visually it is a full page
  with no transition. If a `Navigator` route (with a slide-in) is wanted,
  G15 items 1, 6, 7 change and Task 14 needs re-planning of those items.
- **D10 Bar height 128 dp at s 1.0** (map ≈ −24 dp versus today, +104 from
  the log row, −128 for the bar) so the worst reachable content (title,
  three fact lines, four buttons) shows without truncation. Cheaper
  alternative: `ACTIONS` to the left of the facts instead of above them →
  108 dp (map ≈ −4 dp), but `doneAtTheBottom` then ellipsizes by about one
  character at s 1.0. Default: 128 dp, title above.
- **D11 Strip legibility backdrop.** A soft top-to-bottom gradient (clear to
  the callout fill), no border, keeps the three lines readable over bright
  glyphs. Default: yes; the device capsule records legibility.
- **D12 Empty log → no strip** (and no tap area). Default: yes.
- **D13 The page keeps `RECENT EVENTS` and `N entries`** (today's expanded
  style); only the strip drops the title and count. Default: yes.

### 10.7 Residual risks

- While the player has panned the hero into the bottom 55 dp, the hero's
  lower neighbours sit under the strip and a tap there opens the log rather
  than stepping; a drag starting on the strip does not pan. Recenter (above
  the strip) or a pan fixes it; at zero pan the hero is at the map centre.
- Strip lines ellipsize at one line each; long sentences read in full on
  the page.
- The bar's empty zones (no facts, no buttons) are the common exploring
  state; its height is the contract's constant-height rule, not waste to
  trim.
- Target-card placement at s 1.3 on the final map is expected clear of the
  target cell (the old dirty sets arose only with an action card on the
  map; `0,*,*` rows were clean), but it is proved by the Task 14 sweep, not
  assumed; a non-empty set escalates to Main.
- `LogOpened` still clears inspection (today's handle does). Unchanged
  behaviour, now reached by one tap on the strip.

### Plan quality gate (amendment 2026-09-28)

- **COR — PASS.** One availability owner (`cardVerbsFor`/`placeFacts`,
  unchanged); the bar's height is a pure function of text scale only, sized
  to the reachable maxima and total over fixtures (fact join, `n = max(4,
  count)`); one placement owner with both strips as hard target-card area
  constraints and recenter/flipped strip derived from the events rect; the
  follow/unread invariant keeps its shape on `logOpen`; game-over closes
  the page by construction; back closes the page before it refuses; every
  overlay child `Positioned`; empty log adds no hit area; Task 13's handoff
  keeps every verb and the log reachable.
- **TTC — PASS.** Value-level Red at the prior head for each cluster
  (literal finders for the bar title, quiet line, verbs outside the map
  slot, strip key, page key, log row absent; the step bloc test);
  geometric expectations from the map slot rect and the plan's literal
  heights, never from `actionBarHeight`/`eventsStripRect`; sweeps over the
  real target-card heights at both scales; mutation witnesses in both
  briefs; retired presentation (card pinning, leader, drawer cycle, peek
  count, log row) deleted or rewritten to behaviour, not re-pinned.
- **CRF — PASS.** Deletes the on-map card path, the drawer extents, the
  handle, the log row and the step line's helper instead of shimming;
  renames where the old name would lie (`ActionBar`, `LogPage`,
  `event_log.dart`, `logOpen`); keeps `cardVerbsFor`/`CardVerb` because
  they name the verb set Main and the contract cite; `turnOrderStripRect`
  extracted only because the sweep and `MapOverlays` both need it.
- **SEC — SKIP.** Offline presentation; no trust boundary. The only secrecy
  surface (hidden actors) is untouched: the strip shows lines the log
  already holds.
- Residual risks: 10.7; decisions with defaults: 10.6.
