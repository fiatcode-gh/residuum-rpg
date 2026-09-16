# Unit 9 recon — crawl HUD chrome

Source-verified on 2026-09-16 at `main` `2b0e0a4`, clean worktree. Scouts:
`agent://CrawlHudScout`, `agent://CrawlStateScout`, `agent://GrammarScout`.
Every line reference below was re-read by the architect; `CrawlHudScout`'s own
line numbers drift by roughly 20 lines and were not trusted directly.

## What the crawl screen is today

`packages/app/lib/game/game_screen.dart:47-139` — `GameScreen` is a `PopScope`
over a `Scaffold`/`SafeArea`/`BlocBuilder` holding a `Stack` of one `Column`
plus two overlays. The column, top to bottom:

| Slot | Source | Height behaviour |
|---|---|---|
| `BattleDock`, only while engaged | `:66-75` | intrinsic |
| dungeon viewport | `:76-121` | **`Expanded`** — absorbs every change |
| `BattleShelf`, only while engaged | `:122-123` | intrinsic `Wrap` |
| `_HitPoints` status row | `:124` | intrinsic, one row |
| `LogPeek` | `:125` | fixed `height: 104` (`log_drawer.dart:68`) |
| `_Controls` | `:126` | intrinsic, 1–4 rows |

Overlays: `LogDrawer` when the drawer is not at peek (`:129-130`) and
`_DeathOverlay` on game over (`:131`).

**The map is `Expanded`, so added chrome never overflows the crawl — it silently
shrinks the play surface.** That is the real cost to weigh against the handoff's
map-first rule (handoff section 3.3).

## The status row, and why it looks like that

`_HitPoints` (`game_screen.dart:197-329`) is one `Row`: a 56-pixel
`LinearProgressIndicator` (`minHeight: 14`, track `0xFF23262E`, fill
`0xFFDDE1E7`), the fixed 18-pixel `_BattleGlyph`, then an `Expanded`
`FittedBox(BoxFit.scaleDown)` holding the **entire status as a single string**
(`_line`, `:259-269`):

```
14 / 20  Wounded  The Crypt — depth 3/5  Watched 2  Mana 3/5  Ward 2
```

Composition: `_condition` (`:323-328`) gives `Dead`/`Critical`/`Wounded`/
`Steady`; `_whereabouts` (`:315-321`) gives `The road` for encounters, else
`<node name> — depth <depth>/<deepest>`; `_battleWord` (`:276-280`) gives
`Engaged n`/`Watched n`; `_magic` (`:296-300`) gives `Mana m/max` only when
`knownSpells` is non-empty, plus `Ward n` only while one stands.

The Dartdoc at `:246-258` records the device history: the row **used to be** a
stretched bar plus three fixed labels, which fitted only while the middle label
read `Depth 3/5`. Naming the dungeon added fifteen characters and a floor with
something in sight **overflowed a phone by sixty-four pixels**, invisible to
widget tests because their surface is wider than a phone. One scaled string was
the fix. `:569-593` records two further device passes that killed ellipsised
control labels (`Leave — the delve is done` → `Leave — t…`), which is why
`doneControl` is six characters and `doneAtTheBottom` lives on its own row.

**Therefore the mock's shape is not unbuilt — an earlier form of it was built
and beaten by hardware.** Any Unit 9 layout must be measured on device, not on
the 800x600 test surface.

## The mock, and the gap that is actually left

Read from `.flow/evidence/visual-reboot/residuum_visual_reboot_approved_mock.png`:
a header row with `THE CRYPT` left and `3 / 5` right; beneath it two
side-by-side labelled bars, `HP 14/20` filled red and `Mana 3/5` filled blue;
at the bottom four rectangular chips, each an icon above a small text label
(Potion, Mend, Firebolt, Wait).

Measured against handoff section 3.2 (`:54-66`), which asks the permanent HUD to
answer where am I, what depth, and what resources matter — plus dungeon name,
depth/deepest, HP, mana where meaningful, and Ward when present — **the live
screen already carries every required fact.** The gap Unit 9 closes is
presentation only: the facts are crammed into one shrinking line, HP has an
unlabelled 56-pixel bar, and Mana has no bar at all.

## Data availability — app-only, verified

Every value the two-row HUD needs is already on `GameViewState`
(`packages/app/lib/game/game_bloc.dart`): `depth` `:328`, `deepest` `:336`,
`isEncounter` `:339`, `isBattleOpen` `:436`, `enemiesInSight` `:495`, `mana`
`:500`, `maxMana` `:503`, `warded` `:506`, `maxHp` `:575`. The dungeon name comes
from `GameBloc.dungeon` through `residuumWorld.nodeAt(node).name`
(`game_screen.dart:318-320`).

**No change to `packages/core` or `packages/content` is required or permitted.**

## Grammar already in the repository

- **Only two Material icons ship in the whole app**: `Icons.center_focus_strong`
  (`game_screen.dart:112`) and `Icons.close` (`log_drawer.dart:228`). Neither
  carries game meaning. There is **no icon-labelled control pattern anywhere**,
  so the mock's icon chips would be a net-new icon language — which is exactly
  what the epic defers to the post-Unit-8 art pass.
- **A labelled-meter grammar already exists**: `_SkillRow`
  (`packages/app/lib/town/skills_screen.dart:38-60`) is a label `SizedBox`, a
  level number, an `Expanded` `LinearProgressIndicator` (`minHeight: 8`, track
  `rule`, fill `ink`), then `xp/cost` in `monoDim`. Monochrome fill, word label,
  numbers beside the bar. **Unit 9's bars should be this row, twice.**
- Shared style vocabulary is `packages/app/lib/town/town_style.dart`: `ink`
  `E6EAF0`, `dim` `8A919E`, `panel` `15181F`, `rule` `2A2E38`, and `mono`,
  `monoDim`, `placeName`, `roomName`. `game_screen.dart:17` already imports
  `ink` and `dim` from it.
- Non-hue encoding precedents: `_BattleGlyph` (`game_screen.dart:350-375`) pairs
  a glyph with the repeated word; `ItemRow` (`town_style.dart:93-127`) uses a
  marking column plus the tier word; `glyph_marks.dart:30-69` uses outline shape
  (square = targeted, circle = selected) and a scale hierarchy.
- The existing text mark inventory is large and fixed (log categories
  `log_line.dart:4-14`, temper/stat marks `item_presentation.dart:10,123-124`,
  superscript duplicate badges `actor_presentation.dart:122-126`, core material,
  rarity, school and damage-type markings). **No new codepoint is needed for a
  two-row HUD**, and the epic forbids one without device proof.
- Town and world both present health as text, `Health   X / Y`
  (`town_screen.dart:76`, `world_screen.dart:196`). Those are not Unit 9's.

## Traps this unit will hit

1. **Fourteen tests across five files pin the concatenated whereabouts string**
   `<name> — depth <n>/<n>`: `test/widget/world_screen_test.dart` (7),
   `hud_depth_test.dart` (3), `suspend_door_test.dart` (2),
   `roster_session_test.dart` (1), `boot_wiring_test.dart` (1). Splitting the
   name and the depth into a header row breaks every one of them. Several are
   pinning *string composition*, not observable behaviour — notably
   `world_screen_test.dart:1752-1754`, which asserts one `line` contains
   `20 / 20`, `Steady` and `The Sea-Cave — depth 1/4` together.
2. **`battle_characterization_test.dart:115-148` pins `Engaged n`/`Watched n`
   via `textContaining` against the same single line**, alongside the `✖`/`◉`
   glyphs.
3. **The widget-test surface is wider than a phone.** It cannot see the overflow
   class of defect this row has already suffered twice. Device measurement is
   the only proof for layout.
4. **Red HP and blue Mana are the epic's first hue-only encoding.** The author
   is deuteranomalous; the bars must read in greyscale, which means the label
   word and the numbers carry the meaning and the fills stay monochrome.
5. Vertical budget: every pixel of new chrome comes out of the `Expanded`
   viewport, silently.
6. `LogPeek`'s 104 pixels and `_Controls`' up-to-four rows already sit below the
   status row; on the bottom floor with something underfoot, `_Controls` renders
   two prose rows plus five `Expanded` controls (`:393-431`, `:432-519`).
