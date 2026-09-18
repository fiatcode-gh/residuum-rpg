# Unit 12 recon — crawl interface, at `60909e6`

Three read-only scouts (`agent://CrawlShellRecon`, `agent://CrawlInfoRecon`,
`agent://CrawlActionRecon`) mapped the crawl; every load-bearing line below was
re-read by the architect, because the scouts disagreed with each other about
`game_screen.dart` line numbers. Trust these numbers, not theirs.

## The crawl is one screen, one column, six slots

`GameScreen` (`game_screen.dart:27-142`) is stateless: `PopScope` →
`BlocListener` → `Scaffold` → `SafeArea` → `BlocBuilder` → `Stack`. The `Stack`
carries a `Column` plus two overlays — `LogDrawer` when the extent is not peek
(`:131`) and `_DeathOverlay` on game over (`:133`).

The `Column`, in order (`:66-129`):

1. `BattleDock` — the activation timeline, only while `isBattleOpen` (`:68`);
2. `Expanded` map slot, `EdgeInsets.all(8)`, hosting `DungeonSceneHost` and the
   recenter FAB (`:78-123`);
3. `BattleShelf`, only while `isBattleOpen` (`:124`);
4. `CrawlStatus` (`:126`);
5. `LogPeek` (`:127`);
6. `_Controls` (`:128`).

**This order is the largest single divergence from the approved mock.** The
mock puts place/depth and the meters at the very top, the timeline directly
under them, the map next, the log peek under the map and exactly one action row
at the bottom. Today the status sits *below* the map and combat renders **two**
action rows — `BattleShelf` above the status and `_Controls` at the bottom.
Only Drink is rendered twice: the control row's Wait is gated
`!state.isBattleOpen` (`game_screen.dart:302-304`), so it hides while a battle
is open. One duplicated verb is still a breach of the four-region rule.

The map is `Expanded`, so every row of chrome is paid for out of map height.
Unit 9 measured one status row at 52 px on `Medium_Phone`.

## Style authority today

`packages/app/lib/town/town_style.dart` is the whole design system: a plain
file of `const` colours and `TextStyle`s plus a handful of shared widgets. It
is **not** a `ThemeExtension`, not an `InheritedWidget`, not a Material theme.

- colours (`:9-12`): `ink 0xFFE6EAF0`, `dim 0xFF8A919E`, `panel 0xFF15181F`,
  `rule 0xFF2A2E38`;
- type (`:14-47`): `mono` 14, `monoDim` 12, `placeName` 20 with letterSpacing
  5, `roomName` 15 with letterSpacing 4 — every one `fontFamily: 'monospace'`;
- `markColumn = 28` (`:31`), the fixed glyph gutter.

The crawl reaches into it from four files: `crawl_status.dart:5` (whole file),
`game_screen.dart:19` (`show ink, dim`), `battle_view.dart:3`,
`pack_screen.dart:6`.

The global theme is three lines in `main.dart` — dark brightness,
`scaffoldBackgroundColor 0xFF0E1014`, `useMaterial3: true`. No `colorScheme`,
no `textTheme`, no extensions. Every Material widget in the crawl therefore
renders with stock Material 3 defaults, which is exactly the "conspicuous
stock-Material break" the unit exists to remove.

**There is no font asset.** `pubspec.yaml` declares three image asset
directories and no `fonts:` section; `'monospace'` is the device font.

## What each region actually is

**Status** — `crawl_status.dart`, Unit 9's two-row design: `_HeaderRow` (place
name, battle glyph `✖`/`◉`, battle word, `depth / deepest`) and `_ResourceRow`
(HP meter, Mana meter when meaningful, Ward count). `_Meter` is a label, the
numbers, a monochrome `LinearProgressIndicator` on the `rule` track, and a
condition note. Styling is `mono`/`monoDim` throughout; no `Theme.of` anywhere.

**Timeline** — `battle_view.dart:17-127`. A horizontal scroller of 44×44
`_TimelineToken`s joined by dim `›` glyphs. `projectActivationQueue`
(`activation_timeline.dart:8-24`) yields current hero, then each *visible*
actor, then the next hero, and **stops at the first unseen actor** — that
silence is the information-hiding rule. Repeated activations are literal
repeated tokens; duplicates carry superscript badges. Tapping a token opens
`showEnemyInfo` (`battle_view.dart:128-155`), a read-only sheet that spends no
turn. The current hero is distinguished only by widget key and semantic label,
never visually.

**Log** — `log_drawer.dart`. `LogPeek` is a fixed 104 dp reverse list, newest
last, whole strip tappable to cycle the extent; it shows no category marks.
`LogDrawer` is the half (0.45) / full (1.0) overlay with a drag handle, a
`MESSAGE LOG` title, a close button, per-row category mark in a 20 dp gutter,
and the `↓ N new` affordance shown iff `!logFollowing && logUnread > 0`. Follow
breaks and resumes on scroll within an 8 px tolerance (`:163`). Extent, follow
and unread live on `GameViewState` (`game_bloc.dart:216, 221, 225`).
`log_drawer.dart:13-15` re-declares `ink`/`dim` locally as `_logNewest` /
`_logOlder` — duplication the crawl seam should absorb.

**Controls** — `_Controls` (`game_screen.dart:212-348`), a `Wrap` of
`FilledButton`s built from `_Control` (`:488-524`): Pick up, Gather (label is
`node.verb`), Drink (n), Pack (n), Wait, Flee, Move on, Ascend `<`, Descend
`>`, Leave/Finish. A control appears only when it applies — the doctrine is
written out at `:199-210` — and Pack is the deliberate always-on exception.
Above the buttons sit up to three dim monospace-12 rows: `Underfoot:`, `Here:`,
and `doneAtTheBottom`.

**Shelf** — `BattleShelf` (`game_screen.dart:579-707`): three readied spells,
a `+n` overflow chip, Drink and Wait. Armed reads as a `BorderSide(color: ink)`
plus a literal ` — armed` suffix (`:579-707`, doctrine at `:577`). Overflow
opens a `showModalBottomSheet` with a `Spells` heading and one `_OverflowRow`
per known spell — the most stock-Material surface in the crawl.

**Targeting** — the shelf arms (`SkillArmed`), `state.armedSpellId` records it,
`armedTargets` (`game_bloc.dart:273-276`) marks every *visible* monster, the
map reports a tap, and `_onTileTapped` (`game_bloc.dart:640-660`) either casts
or disarms on a stray tap. No melee button exists; melee is the bump.

**Icons** — `action_icon.dart`: `ActionIconImage` is a deliberate
`Image.asset` at `actionIconSize = 18`, never `ImageIcon`, because the Unit 10
masters are multitone and `IconTheme` would flatten them to silhouettes. Any
chip redesign must keep that and must not tint them.

## Traps for planning

1. **`log_drawer_test.dart:253` asserts the literal `Color(0xFFE6EAF0)`** on a
   row's `TextStyle`, and the sibling assertions do the same for the older
   row and both marks. The behaviour it defends — newest reads brighter,
   a mark shares its sentence's colour — is worth keeping; the literal hex is
   not. Re-express it as a relative-contrast assertion. Do not re-pin it to a
   new hex.
2. **`crawl_controls_test.dart` freezes the control set and order** across
   three scenes, asserts `FilledButton` by type, asserts `Image` presence per
   control, and checks un-ellipsised fit through `RenderParagraph` intrinsic
   width. A chip redesign changes the widget type and the fit maths.
3. **`battle_shelf_icons_test.dart` asserts `TextButton`, the exact
   `✳ Firebolt 2` label and the ` — armed` suffix**, and that a border exists
   when armed. Keep the border-and-word grammar; the widget type is free.
4. **`crawl_status_test.dart` pins `HP 20 / 20`, `THE SEA-CAVE`, `1 / 6`, the
   meter keys and the progress values.** Moving the block above the map does
   not break these; changing the strings would.
5. **Phone overflow has bitten this screen three times** (`game_screen.dart:
   199-210, 392-416`; ledger Unit 9). Labels are short *because* of device
   passes. Any richer chip must be measured on `Medium_Phone`, not judged in a
   widget test, whose surface is wider than a phone.
6. **Every row of chrome costs map height** — the map is `Expanded`. Budget it.

## Mock alignment gaps, frames 2–5

| Mock | Today |
|---|---|
| Status block at the top | below the map |
| One action row at the bottom | two rows in combat, Drink/Wait duplicated |
| Timeline in a bordered panel, `NOW`/`NEXT` captions, ringed tokens, names beneath | flat 44×44 glyph tokens, `›` separators, no captions, no names |
| Icon-above-label chips, rounded, hairline border, even widths | `FilledButton`/`TextButton` wrap, icon beside label |
| Log peek on a panel with a `›` expand affordance | 104 dp strip, no affordance mark |
| Expanded log: handle, title, hairline rule, pictorial per-line icons | handle, title, close, Unicode mark gutter |
| Serif body type, letterspaced caps labels | monospace everywhere, no font asset |
| Red HP / blue Mana fills | monochrome meters (Unit 9 rejected hue fills) |
| Map bleeds to the frame edges | 8 px padding on all sides |
