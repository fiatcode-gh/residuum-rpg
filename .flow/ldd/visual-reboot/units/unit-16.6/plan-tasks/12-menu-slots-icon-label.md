# 12 — Menu slots show only icon above label, centred

Governing: `../CONTRACT.md` (amended 2026-09-25, commit `87344e7`) scope §1
item 4, acceptance 3; `../PLAN.md` §9 (G13, superseding the G9 metadata
column and the G8 metadata part of `CrawlSlot`), G11. Work from
`packages/app`.

## Starting repository state

App code as of `4de51c3`, or `4de51c3` plus Task 11's commit (the two tasks
are independent; see PLAN §9). Check `git diff --stat 4de51c3 --
lib/game/crawl_slot.dart lib/game/crawl_menu.dart`: it must be empty.

What exists now:

- `lib/game/crawl_slot.dart`: `CrawlSlot({label, mark, onPressed, dimmed,
  armed, metadata = '', width, height})`. Layout: `Padding(top: 6)` →
  `Column(mainAxisAlignment: start)[mark 20, 2, label FittedBox, if metadataText: Text(metadataText, monoSlotMeta)]`,
  `metadataText = armed ? '— armed' : metadata`; semantics label
  `label[ metadata][, unavailable]`.
- `lib/game/crawl_menu.dart`: Quick passes `metadata: '×$potionTotal'` when
  potions are carried; Hero passes `'${inventory.length}/$inventoryCap'`;
  Spells passes `armed: armedSpellId != null` (which renders `— armed`).
  `_MenuSlot` forwards `metadata`.
- Consumers of `CrawlSlot`: `crawl_menu.dart`, and either `log_row.dart`
  (before Task 11) or `action_card.dart` (after it). Neither of those passes
  `metadata`.
- Tests pinning the metadata: `test/widget/suspend_door_test.dart` ~l.236
  (`'${carried + 1}/$inventoryCap'` inside `menu-hero`),
  `test/battle_characterization_test.dart` ~l.124 (`'0/$inventoryCap'`
  inside `menu-hero`), `test/widget/crawl_menu_test.dart` ~l.353
  (`— armed` inside `menu-spells`). The `— armed` texts inside `spell:<id>`
  rows (~l.426, ~l.500) belong to the Spells pop-up and stay.

## Owned files

`lib/game/crawl_slot.dart`, `lib/game/crawl_menu.dart`;
`test/widget/crawl_menu_test.dart`, `test/widget/suspend_door_test.dart`,
`test/battle_characterization_test.dart`, and any other test the full suite
shows reading slot metadata.

Non-goals: pop-up rows (`spells_popup.dart`, `quick_popup.dart` keep their
`monoSlotMeta` meta lines), slot order, dimming rules, pop-up behaviour,
the menu height, tokens.

## Locked decisions

1. `CrawlSlot` loses the `metadata` parameter and field and `metadataText`.
   Content: `Column(mainAxisAlignment: center, mainAxisSize: max)[mark
   (crawlSlotMark 20, opacity rule unchanged), SizedBox(height 2), label
   (Padding horizontal 4, FittedBox scaleDown, one line)]`, centred
   horizontally and vertically in the slot; no top padding. Nothing else is
   rendered in a slot.
2. Armed state keeps its cold glow and `textSlotArmed` label; **the armed
   frame becomes 3 dp `crawlCold`** (was 1.5 dp) so armed reads by shape as
   well as hue (PLAN §9 Q8, user). The `— armed` text is removed with the
   rest of the metadata. Proof: with a spell armed, the Spells slot's border
   width is 3 and the other slots' is not; disarming returns it.
3. Semantics: `button: true`, `enabled: onPressed != null`, label = `label`,
   plus `', unavailable'` when dimmed and `', armed'` on the Spells slot while
   a spell is armed (the word the screen removed stays for screen readers).
   No count.
4. `crawl_menu.dart`: `_MenuSlot.metadata` and `potionTotal` are deleted;
   `kinds` stays (Quick dimming). No other change.
5. No new dartdoc or body comments (G11).

## Proof (Red first)

In `crawl_menu_test.dart`, new cases at `onTheTargetPhone`, with potions
carried, a partly full pack and a spell armed in battle (the state that
today shows `×N`, `n/cap` and `— armed`):

- each of the four slots contains exactly one `Text`, its label
  (`find.descendant(of: slot, matching: find.byType(Text))`), and no text
  containing `×`, `/` or `armed`;
- each slot's semantics label equals its word (`Quick`, `Hero`, …; dimmed
  ones end `, unavailable`);
- geometry per slot: mark centre x and label centre x within 0.5 dp of the
  slot centre x; mark bottom ≤ label top; the gap above the mark and the
  gap below the label differ by ≤ 1 dp (vertically centred), at text
  scale 1.0 and at 1.3.

Expected Red: the one-Text and semantics cases fail on Quick and Hero
(`×2`, `n/cap`) and Spells (`— armed`); the centring case fails (top gap
6 dp, bottom gap larger).

Rewrite, do not re-pin:
- `suspend_door_test.dart`: delete the `n/cap` slot assertion; the resumed
  inventory is already proved by `app.saved!.run!.inventory` in the same
  test. Keep the `Hero` label assertion.
- `battle_characterization_test.dart`: delete the `0/$inventoryCap`
  assertion; keep the `Hero` label one.
- `crawl_menu_test.dart` ~l.353: delete the `— armed` descendant assertion
  under `menu-spells` (armed state is asserted through `armedSpellId` in the
  same test).

Green: `dart format <touched Dart files>`, `flutter analyze`, full
`flutter test`; `grep -rn "metadata" lib/game/crawl_slot.dart lib/game/crawl_menu.dart`
has no hits.

## Executor discretion

Whether the Column uses `MainAxisAlignment.center` or a `Center` wrapper;
test helper shape.

## Escalate when

The label no longer fits at text scale 1.3 in the 56 × 1.3 dp slot; a
test other than those listed depends on slot metadata for a behaviour that
nothing else proves; the armed state becomes indistinguishable in the
widget tree from the available state.

## Commit and receipt

Never `git stash`. Commit only your paths:
`git commit -m 'feat(app): show only icon and label on the menu slots' -- <paths>`.

Receipt: Red output, Green command and exit, format and analyze exits, the
rewritten assertions list, the commit hash.
