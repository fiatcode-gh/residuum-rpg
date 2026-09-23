# 09 — Combat panel and the single target focus

Governing: `../CONTRACT.md` scope item 4 (Battle / targeting), scope item 2
(target geometry); `../PLAN.md` §2 G6, G8 (combat panel internals), G11
(target, damage, spell), §7 E5. Work from `packages/app`.

## Starting repository state

Task 08 committed: `HeroPanel` in every mode above the peek; meters keyed
there. `DungeonSceneSnapshot.fromViewState` passes
`selectedActorId: state.selectedActor?.id` to `glyphPlan`; the renderer
draws brackets on `GlyphCell.selected`. `GameViewState.selectedActor`
(timeline selection) drives `cameraFocus`.

## Owned files

new `lib/game/combat_panel.dart`; `lib/game/game_bloc.dart`
(`GameViewState.targetActor` getter only); `lib/game/dungeon_scene.dart`
(snapshot selected id + `_reusesProjection`); `lib/game/game_screen.dart`
(panel switch); `lib/game/crawl_style.dart` (`crawlCombatPanelHeight = 124`);
new `test/widget/combat_panel_test.dart`; `test/game/dungeon_scene_test.dart`,
`test/game_bloc_test.dart` (targetActor), `test/widget/crawl_status_test.dart`
(battle meter finders).

Non-goals: inspect/callout state (Task 12 prepends `inspectedActor` to
`targetActor`); timeline; header. No to-hit value anywhere.

## Locked decisions

1. `Actor? get targetActor => selectedActor ?? (isBattleOpen ? _nearestKnownVisible : null);`
   where `_nearestKnownVisible` = among `game.monsters` with
   `inspectTargetAt(m.position) != null`, minimum
   `m.position.chebyshevTo(game.hero.position)`, ties `byRowThenColumn`,
   then id. `cameraFocus` stays `selectedActor?.position ?? hero`.
2. Snapshot passes `selectedActorId: state.targetActor?.id`;
   `_reusesProjection` compares that id instead of `selectedActorId`.
3. `CombatPanel({required GameViewState state})` keyed `combatPanelKey`,
   height `124 × crawlScale`, `crawlFrameDecoration`, internals PLAN G8
   "Combat panel internals", facts PLAN G11 (target, damage, spell; YOU
   vitals keyed `hpMeterKey` / `manaMeterKey`). No target →
   `TARGET` label + `No target in sight` (`textLineDim`). Spell mark via
   `ActionMarkView(spellMark(spell), size: 18)`. Target name: first letter
   upper-cased `presentationOf(id)!.displayName`, one line,
   `FittedBox(scaleDown)`. Fact line B joins `Reach r`/`Adjacent` and
   `Resists <word>` / `Burns at <word>` with ` · `, `maxLines: 1`,
   ellipsis.
4. `GameScreen`: panel slot = `state.isBattleOpen ? CombatPanel : HeroPanel`;
   gaps unchanged.

## Proof (Red first)

`test/game_bloc_test.dart` (or `test/game/armed_targets_test.dart`):
`targetActor` — selected visible actor wins; in battle with no selection the
nearest known visible monster (tie → upper-left) is the target; an unknown
or out-of-sight monster is never the target (negative, AC2); outside battle
with no selection → null.
`test/widget/combat_panel_test.dart` on `onTheTargetPhone`:
- battle opens → combat panel (124 dp) replaces the hero panel; the map rect
  is identical unarmed vs armed (arm a spell by tapping its slot);
- TARGET shows the nearest monster's capitalised name, `HP a/b`,
  `ATK a–b  SPD s`, reach/resist words;
- DAMAGE shows `state.attack` + `melee` unarmed and the bolt's
  `min–max` + `spell` when Firebolt is armed; arming Bind shows the melee
  range again;
- SPELL shows `READIED SPELL` + first readied spell unarmed, `ARMED SPELL`
  + armed spell, `Mana Cost N`, effect line and tags (`Fire | Wrath | Targeted`
  for Firebolt, `Mending | Self` for Mend); no spells → `No spell known`;
- YOU shows `HP a/b` (and `Mana a/b` with spells) under the meter keys;
- negatives: no `%`, no `TO HIT`, no flavour text.
`test/game/dungeon_scene_test.dart`: in battle the target monster's cell
carries `brackets`; with a spell armed other visible monsters carry `ticks`.
Expected Red: `targetActor`/`CombatPanel` missing.
Green: `flutter test test/widget/combat_panel_test.dart test/game test/game_bloc_test.dart test/widget/crawl_status_test.dart test/battle_view_test.dart`,
`dart format <touched>`, `flutter analyze`.

## Executor discretion

Private widget split; test fixtures; whether tag capitalisation uses a small
private helper.

## Escalate when

`Spell` lacks a field G11 names; `targetActor` changes any bloc transition
or camera behaviour; a battle test relied on brackets only for the
timeline selection in a way G6/G11 contradicts.

## Completion receipt

Red output, Green command/exit, analyzer/format exits, measured panel rect
and armed/unarmed map rects. Commit:
`feat(app): add the combat panel and one target focus`.
