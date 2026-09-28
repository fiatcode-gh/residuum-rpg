# 07 — Persistent bottom menu with Spells, Quick and Quests pop-ups; action bar deleted

Governing: `../CONTRACT.md` settled decisions 1–5, scope §1.4, §2, §3,
acceptance 3–6, 12; `../PLAN.md` §2 G6, G9, G11. Work from `packages/app`.

## Starting repository state

Task 06 committed. `_actionsFor` now offers only: battle-only `drink`
(`QuickDrinkPressed`, metadata `×potionCount`), battle-only `spell:<id>`
for `knownSpells.take(readiedSpellCount)` (arm/cast via `_onSpell`),
battle-only `spells-overflow` (`_openSpellsOverflow` sheet with
`_OverflowRow`, keys `overflow-<id>`), exploration `drink`, and `pack`
(pushes `CrawlPackScreen` via `BlocProvider.value`). `CrawlActionBar`
(`crawl_action_row.dart`, `actionRowKey`, `readiedSpellCount`) renders them
with `CrawlSlot`. `GameBloc` has `QuickDrinkPressed`/`_onQuickDrinkPressed`,
`GameViewState.firstPotion`/`potionCount`.

## Owned files

new `lib/game/crawl_menu.dart`, `lib/game/spells_popup.dart`,
`lib/game/quick_popup.dart`; `lib/game/crawl_surfaces.dart`
(`showCrawlPopup`); `lib/game/game_screen.dart`; `lib/game/game_bloc.dart`
(quick-drink deletions only); `lib/game/crawl_style.dart`; delete
`lib/game/crawl_action_row.dart`, `test/widget/crawl_action_row_test.dart`;
`git mv test/widget/crawl_controls_test.dart test/widget/crawl_verbs_test.dart`
(rewritten); new `test/widget/crawl_menu_test.dart`,
`test/game/quick_popup_test.dart`; migrate `battle_view_test`,
`battle_shelf_icons_test`, `battle_characterization_test`,
`crawl_layout_test`, `crawl_surfaces_test`, `log_drawer_test`,
`suspend_door_test`, `pack_screen_test`, `character_screen_test` (only
crawl finders), `game_bloc_test` (quick-drink tests).

Non-goals: callout/card, strip, pack screen contents (Unit 16.7), bloc
handlers other than the quick-drink deletion.

## Locked decisions

1. `CrawlMenu` exactly per PLAN G9 table (keys, labels, marks, dimmed,
   metadata, tap), keyed `crawlMenuKey`, `crawlMenuHeight = 56`,
   `crawlSlotGap = 7`, padding `crawlGutter`; slots are `CrawlSlot` with
   non-null `onPressed`. Order never changes in any state.
2. `showCrawlPopup` exactly per PLAN G9 (`showGeneralDialog`, anchor rect,
   `crawlPopupWidth = 280`, gap 6, transparent barrier, zero transition,
   `Theme(residuumTheme)`, `Material(type: transparency)` over
   `crawlFrameDecoration`, padding 10, scroll when taller than the space).
3. `spells_popup.dart`: `readiedSpellCount = 3` (moved), `openSpellsPopup(BuildContext anchor, GameBloc bloc)`,
   `chooseSpell(GameBloc bloc, Spell spell)` (reads `bloc.state`),
   `openGrimoire(BuildContext, GameBloc)` + `_OverflowRow` (moved verbatim
   from `game_screen.dart`, reading `bloc.state` at tap). Rows, texts,
   styles, keys and choice rule exactly PLAN G9 Spells. Available in every
   state (no `isBattleOpen` guard).
4. `quick_popup.dart`: `PotionKind`, `potionKinds`, `openQuickPopup(BuildContext anchor, GameBloc bloc)`
   exactly PLAN G9 Quick; row tap pops then `DrinkPressed(item.id)`.
5. Quests pop-up inline in `crawl_menu.dart`: title `QUESTS`,
   `Quests are coming soon.`
6. `Hero` slot pushes `CrawlPackScreen` exactly as the `pack` action did.
7. Delete `crawl_action_row.dart` (`CrawlAction`, `CrawlActionBar`,
   `actionRowKey`, `_InertFrame`), `_actionsFor`, `_onSpell`,
   `_openSpellsOverflow`, `_OverflowRow` (moved), `crawlActionBarHeight`,
   `crawlSlotPeek`, `QuickDrinkPressed`, `_onQuickDrinkPressed`,
   `firstPotion`, `potionCount`, and any orphaned token/constant (grep).
   `GameScreen` places `CrawlMenu(key: crawlMenuKey, state, bloc)` where the
   bar was.

## Proof (Red first)

- `quick_popup_test.dart`: `potionKinds` groups by display name in
  first-appearance order, counts, picks the first item; ignores books and
  gear; empty when none.
- `game_bloc_test.dart`: `castRefusal` out of combat — Mend with mana →
  null; Firebolt with nothing in sight → `no enemy in sight`; any spell
  without mana → `not enough mana`. Quick-drink tests become `DrinkPressed`
  tests where the behaviour is not already covered (heals and logs; a
  non-carried id is refused and logged, no turn).
- `crawl_menu_test.dart` at `onTheTargetPhone`: the four slots in order
  Quests, Spells, Quick, Hero in exploration, Watched, battle and armed;
  menu rect identical in all four; Spells dimmed without spells and its tap
  shows `You know no spells yet.`; Quick dimmed without potions → `You carry nothing to drink.`;
  Quests always dimmed → `Quests are coming soon.`; an outside tap closes a
  pop-up without moving the hero; system back closes it; Hero opens
  `CrawlPackScreen` and back returns; **two-tap drink** in exploration and
  in battle (tap slot, tap `Common Healing Potion` row → HP rises, the log
  says so, the pop-up is gone, exactly two taps); Spells out of combat:
  Mend casts (mana falls, log line); Firebolt with a visible monster arms
  (Spells slot shows `— armed` and the cold frame; reticle ticks on the
  monster's cell), then a tap on the monster casts; Firebolt with nothing in
  sight is shown refused and its tap logs `No enemy in sight.` without a
  turn; five known spells show three rows plus `+2 more spells`, which
  opens the grimoire listing all five; choosing the armed spell again
  disarms.
- `crawl_verbs_test.dart` (acceptance 4): for staged scenes, every verb is
  reachable through its named surface — attack (tap adjacent monster),
  move, auto-walk, inspect (callout appears), cast (Spells), drink (Quick),
  wait and flee (log row), pick up, mine, gather, ascend, descend,
  leave/finish, move on (place pop-up), pack (Hero). Delete the old
  "no control is added, removed, renamed or reordered" tests (they pin the
  bar).
Expected Red: `crawlMenuKey` missing; spells absent outside battle; drink is
one tap.
Green: full `flutter test`, `dart format <touched>`, `flutter analyze`.

## Executor discretion

Pop-up row widget decomposition; test staging of spells (known spells and
mana on the fixture `GameState`); whether Quests' pop-up body is a private
widget.

## Escalate when

`showGeneralDialog` positioning breaks under the root navigator's
`MediaQuery` (e.g. padding differs); a test needs the old bar's one-tap
drink; a spell kind exists whose cast/arm split differs from mend/ward vs
the rest; the grimoire sheet needs changes beyond the move.

## Completion receipt

Red output, Green command/exit, format/analyze exits, deleted files and
symbols, migrated test list, the tap count observed for drink. Commit:
`feat(app): replace the action bar with a persistent four-slot menu`.
