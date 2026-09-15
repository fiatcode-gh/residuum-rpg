# Unit 7 — Town, Transactional Rooms, and Heroes: Execution Plan

Status: **execution-grade; planning only.** This artifact does not authorize
production implementation.

Derived from `CONTRACT.md` (approved by the user as written), `../../RESUME.md`,
the Unit 7 records in `../../LEDGER.md`, `AGENTS.md`, and the approved design
specification at `docs/specs/2026-08-20-dungeon-game-design.md`. The source base
is `319d945cff42a847227e47b8c141090953445a1a` (`319d945`) on `main`, the merged
Unit 6 head. At planning time the worktree was dirty only in architect-owned LDD
authority: modified `LEDGER.md` and `RESUME.md`, plus the untracked
`units/unit-7/` directory. `packages/` was clean relative to `319d945`. Every
line number quoted below was read at that revision and is an evidence anchor,
not an edit instruction. A changed app source revision requires targeted
revalidation of the named seams, not automatic redesign.

## Execution boundary and dependency graph

Implementation must not happen on `main`. Use one non-isolated feature checkout
branched from `319d945`, by house convention `residuum-visual-reboot-7`.
Dispatch one fresh `flow-plan-executor` per brief, sequentially in that same
checkout so repository state and named proof — not executor memory — carry the
handoff:

```text
01-town-grammar-and-shell
  -> 02-counter-rooms        (Merchant, Bank, Inn, Tavern)
  -> 03-crafting-rooms       (Forge, Alchemist)
  -> 04-heroes-roster
  -> Main final gates, acceptance review, and phone evidence
```

1. `plan-tasks/01-town-grammar-and-shell.md` owns `town_style.dart` outright —
   the whole rebooted town vocabulary — and the town shell that is its first
   consumer. It performs the mechanical call-site migrations its own removals
   force, and leaves the tree green.
2. `plan-tasks/02-counter-rooms.md` reboots Merchant, Bank, Inn and Tavern.
3. `plan-tasks/03-crafting-rooms.md` reboots Forge and Alchemist.
4. `plan-tasks/04-heroes-roster.md` reboots `RosterScreen`.

**Why four and not three.** Each of 02, 03 and 04 is a separate Red→Green proof
cluster with its own owning test files, and each reaches a valid repository
handoff on its own:

- 02's cluster is `merchant_screen_test.dart`, `bank_screen_test.dart`,
  `disabled_controls_test.dart` and the tavern group in `world_screen_test.dart`.
  `disabled_controls_test.dart` already spans merchant, inn **and** bank in one
  file, which is the source's own evidence that the four counter rooms are one
  cluster and not four;
- 03's cluster is `craft_rooms_test.dart`, which covers forge and alchemist
  together and nothing else;
- 04's cluster is `roster_screen_test.dart`, `roster_refusal_test.dart` and
  `roster_session_test.dart`, over a screen that reads the live `SaveDocument`
  rather than a bloc and answers with a sealed pop value.

Merging 03 or 04 into 02 would put two unrelated Red→Green clusters in one
brief. Splitting 02 further has no seam to split on.

**Why the grammar is not its own task.** A `town_style.dart`-only task would
have no Red: its whole content is behaviour-preserving extraction. Folding it
into the shell gives task 01 a real behavioural Red (the town screen has no
header and no door says what it is for) and lands each new primitive with its
first consumer.

**Concurrency.** After task 01, tasks 02, 03 and 04 are file-disjoint from each
other and read-only on `town_style.dart` and `town_screen.dart`, so they *may*
be run concurrently in isolated workspaces if Main prefers. Sequential execution
in one checkout is the recommended and assumed shape; the only hard rule is that
no task after 01 may edit `town_style.dart` or `town_screen.dart`.

Each executor owns its behavioural Red/Green, touched-file formatting, focused
file analysis, and focused tests. No executor runs the full analyzer, the full
suite, an app build, an emulator, or an external write. Main owns the broader
gates, the acceptance review, and the device session after task 04.

Only `packages/app` is in scope. `packages/core` and `packages/content` are not
edited by any task, which is how contract boundary 1 is satisfied.

## Revalidated source seams

All paths read at `319d945`.

| Seam | Current fact | Planned consequence |
| --- | --- | --- |
| `lib/town/town_screen.dart:54-64` | The town name is the `AppBar` title, read from `residuumWorld.nodeAt(town).name` via `_titleFor`. | The name moves into the body as the typographic place header; the `AppBar` keeps `panel`/`ink` and its automatic back button but loses its title. `_titleFor` stays. |
| `town_screen.dart:66-128` | `LayoutBuilder` → `SingleChildScrollView` → `ConstrainedBox(minHeight: room.maxHeight)` → `IntrinsicHeight` → `Padding(20)` → `Column(stretch)` with a `Spacer` before the doors. | This skeleton is **kept byte-for-shape**. It is the fix for the 45-pixel overflow on a 600-pixel screen; only the children change. |
| `town_screen.dart:77-87` | Descents sentence, rule, `Health   h / m`, `Carried  n gold`, `Banked   n gold`, rule, `MaterialRows`, `Notice`. | Same facts, same exact strings, re-hierarchised: descents becomes the header's standing line; the three figures become the status block; materials gain `Heading('Materials')`. |
| `town_screen.dart:89-118, 166-186` | Seven `_Door`s in fixed order, each a full-width `FilledButton` with a label and nothing else. | Same seven labels in the same order, reshaped into ruled destination rows carrying a purpose line. `_Door` stays private to this file. |
| `town_screen.dart:131-136` | `_descentsSoFar` switches 0/1/2/n into four exact sentences. | Unchanged, verbatim, and now the header's second line. |
| `town_screen.dart:149-163` | `_open` captures both blocs and pushes `MultiBlocProvider`. | Unchanged. The tavern needs `WorldBloc`; every door keeps both. |
| `lib/town/town_style.dart:9-24` | `ink`/`dim`/`panel`/`rule`, `mono` (14), `monoDim` (12). | Kept unchanged. Two type-scale constants and one width constant are added beside them. |
| `town_style.dart:31-68` | `Heading` (uppercase, letterspaced, ruled) and `NothingHere`. | **Frozen.** Both are consumed by `world_screen.dart` and `game/pack_screen.dart`; changing them would bleed Unit 7 into Unit 8's world and into the crawl. |
| `town_style.dart:76-150` | `ItemRow`: 28-wide marking column, name + optional reason, 104-wide trailing `FilledButton`. | **Frozen.** Shared with `world_screen.dart:230,260`. Only the literal `28` becomes the named `markColumn`, which is value-identical. |
| `town_style.dart:153-175` | `Purse`: two exact gold rows inside a filled `panel` card with a 4-radius. | Town-only (six rooms). De-carded into a ruled block; the two strings are unchanged. |
| `town_style.dart:190-212` | `MaterialRows`: fixed 28/84 columns, every `MaterialId` even at zero. | **Frozen** except the named `markColumn`. Shared with crawl Pack; the fixed-width columns are a recorded device ruling. |
| `town_style.dart:219-234` | `MaterialsPanel`: `MaterialRows` inside the same filled card. Used only by forge and alchemist. | **Deleted.** Both call sites become `Heading('Materials'), MaterialRows(...)` — the exact pair `game/pack_screen.dart:148-151` already uses, so the town and the crawl name materials the same way. |
| `town_style.dart:241-254` | `Notice` renders `— <sentence>.` in `monoDim`, or `SizedBox.shrink()`. | Unchanged. Its **position** is unified: directly under `Purse` in every room. |
| `town_style.dart:265-361` | `CountStepper`: `−`/value/`+`/`MAX`, dead edges kept and dimmed, 400 ms then 120 ms auto-repeat. | **Frozen.** Contract boundary; `count_stepper_test.dart` pins the cadence. |
| `town_style.dart:364-382` | `TownRoom`: `AppBar(title:)` + `ListView(padding: 12/8)`. | Title moves into the body as the room header; `ListView` padding becomes `20` horizontally to match the shell and the world screen. Every Unit 6 route inherits the reboot without being edited. |
| `lib/town/merchant_screen.dart:46-87` | `Purse`, `Notice`, then `For sale` / `Sold this visit` / `Your pack` with stacked `ItemRow`s and `cannotAfford`. | Order, headings, stacking, prices and refusal all preserved. It inherits the grammar; the sold heading stays conditional. |
| `lib/town/bank_screen.dart:63-132` | `Purse`, `Notice`, `Heading('Gold')`, bank dial + commit + `purseIsShort`, take dial + commit + `vaultIsShort`, then `Carried — lost if you die` and `Banked — safe from death` item lists. | Restructured into two zones: carried gold dial/commit/short-sentence **and** carried item rows under the carried heading; banked ditto under the banked heading. `Heading('Gold')` disappears. Order of steppers is unchanged, so `find.text('+').first` and `find.text('MAX').first` still address the bank side. |
| `lib/town/inn_screen.dart:27-33` | `_why` returns exactly three sentences, health first. | **Frozen, verbatim, including the health-first precedence.** |
| `lib/town/tavern_screen.dart:26-53` | `Purse`, `Heading('What they are saying')`, offer row or the exhausted sentence, **then** `Notice(town.notice ?? world.notice)`, then `Heading('What you have been told')` and `world.log.reversed.take(6)`. | Only the notice moves up under `Purse`, matching every other room. The `?? ` fallback, both headings, the six-line cap and the exhausted sentence are preserved. |
| `tavern_screen.dart:60-68` | `_ask` calls core `buyRumor` once and dispatches `RumorBought` + `RumorHeard` as one synchronous pair. | Unchanged. No widget may split, reorder, or precondition it. |
| `lib/town/forge_screen.dart:46-108` | `Purse`, gap, `MaterialsPanel`, `Notice`, `Smelting` ratio + dial + commit + reason, `The bench` with `Worn steel` / `Carried steel`. | Materials become the shared heading + rows, the notice moves under `Purse`, the two-section bench and every sentence are preserved. |
| `forge_screen.dart:113-114` | `_capitalised` turns a core reason into `Reason.`. | Unchanged. The alchemist has the same inline expression at `alchemist_screen.dart:91-92`; both stay where they are. |
| `forge_screen.dart:129-186` | `_TemperRow`: 26-wide marking, name, `TextButton('Temper')`, then `statLine`, optional reason, optional `Next tier: n ingot(s).` — all indented by 26. | Marking column and indents move to the shared `markColumn` (28) so the bench aligns with `MaterialRows` on the same screen. The `TextButton` and every sentence stay: `craft_rooms_test.dart:433` pins `widgetWithText(TextButton, 'Temper')`. |
| `lib/town/alchemist_screen.dart:52-96` | `Purse`, gap, `MaterialsPanel`, `Notice`, `Brewing` ratio + worth line + dial + commit + `brewReason`. | Same treatment as the forge. `_worth()` keeps reading `buyPriceOf`. |
| `lib/town/town_bloc.dart:326-384` | `smeltReason`, `brewReason`, `temperReason`, `wearReason`, `takeOffReason`, `readReason`, `wornSteel`, `carriedSteel`, `temperable`, camp predicates. | **Not edited by any task.** Widgets project these; they never compute one. |
| `town_bloc.dart:829-900` | `_onBrew` emits `SentenceNotice(_batchLoss(...))` and returns before `_levelled`, so a batch loss wins the notice slot over a level-up. | Unchanged. Task 03 proves only that the alchemist *renders* the winning sentence. |
| `lib/town/roster_screen.dart:15-71` | Sealed `RosterChoice` with `PlayHero`, `MakeHero(label, replacing:)`, `DropHero`, each with value equality. | **Frozen.** `main.dart` pattern-matches it; no case is added, renamed, or given a field. |
| `roster_screen.dart:92-115` | `TownRoom(title: 'Heroes')`, `Notice(notice)`, a `_HeroRow` per `document.heroes` entry in map order, then a `New hero` `FilledButton`. | Ruled roster list; `New hero` becomes the shared `Commit`. Iteration order, `playing` marking and the pop protocol are preserved. |
| `roster_screen.dart:127-160` | `_confirmDelete`: `Delete <label>?`, the composed warning, `Keep this hero` / `Delete this hero`, then either `_create(replacing: id)` for the last hero or `pop(DropHero(id))`. | **Frozen, including `_deletionWarning`'s four composed clauses and the living-crawl clause.** |
| `roster_screen.dart:167-182` | `_create`: `heroLabelFor(document.heroes.length)` prefills the dialog; a blank trimmed answer falls back to the offered label. | **Frozen.** |
| `roster_screen.dart:206-218` | `rosterLine` joins hp, carried, banked, `_visits`, and `below (depth n)` / `in town` with ` · `. | **Frozen, verbatim.** `roster_screen_test.dart:75-76` pins both location clauses. |
| `lib/world/world_screen.dart:56-104, 179-197, 230-263` | The world screen has no `AppBar`, prints its own `RESIDUUM` wordmark plus the same three `Health`/`Carried`/`Banked` strings, and uses shared `Heading`, `ItemRow`, `Notice`, `mono`, `monoDim`. | **Not edited.** Unit 8 owns it. Unit 7 must not extract those three rows into a shared widget, because doing so would either change the world screen or leave a primitive with one consumer. |
| `test/support/phone.dart:9-13` | `onAPhone` sizes the surface 1080×2424 @2.625 — about 923 logical pixels tall. | The 600-pixel reachability proof must **not** call `onAPhone`: the default 800×600 test surface is the exact historical trap. |
| `test/widget/craft_rooms_test.dart:82-125` | Group `the town door column` lives in the forge/alchemist file and proves all seven doors plus the material rows. | Moves to the new `town_shell_test.dart` in task 01; `craft_rooms_test.dart` keeps only forge and alchemist. |
| `test/widget/bank_screen_test.dart:32-45` | `the fixed gold buttons are gone` pins the absence of four retired labels and `findsNWidgets(2)` `CountStepper`s. | The one surviving composition pin in the town suite, and it stays true. Keep it unchanged. |
| `test/widget/craft_rooms_test.dart:446-449, 461, 491` and `:135-141` | Forge and alchemist commits are found as `widgetWithText(FilledButton, 'Smelt'/'Brew')` and their `onPressed` is read. | `Commit` **must** render a real `FilledButton` whose child is a `Text` with the exact label, or these break. |
| `test/widget/disabled_controls_test.dart:24-28`, `character_screen_test.dart:70`, `roster_session_test.dart:107`, `world_screen_test.dart:432` | Every route into a room is `tester.tap(find.text('<Door label>'))`. | Each door label must remain exactly one `Text` on the town screen. No purpose line may repeat a door's label. |
| `test/widget/roster_session_test.dart:50`, `suspend_door_test.dart:93,119`, `world_screen_test.dart:232` | `Carried  n gold` / `Health   n /` are asserted `findsOneWidget` after landing on the **world** screen. | The town's identical strings are offstage under the pushed route, so they never collide — provided the town keeps the same strings, which it does. |

## Locked architecture and interfaces

### 1. What `town_style.dart` is after Unit 7

The town's presentation vocabulary is exactly this, and no room may restate any
of it privately:

| Member | Fate | Consumers |
| --- | --- | --- |
| `ink`, `dim`, `panel`, `rule` | unchanged | town, world, crawl |
| `mono`, `monoDim` | unchanged | town, world, crawl |
| `placeName` | **new** `TextStyle` | the town shell header |
| `roomName` | **new** `TextStyle` | `TownRoom` |
| `markColumn` | **new** `double` | `ItemRow`, `MaterialRows`, `_TemperRow` |
| `Heading` | unchanged (shared with world/crawl) | everywhere |
| `NothingHere` | unchanged (shared with crawl) | everywhere |
| `ItemRow` | unchanged but for `markColumn` | merchant, bank, tavern, world |
| `Purse` | **reshaped**: no card | merchant, bank, inn, tavern, forge, alchemist |
| `MaterialRows` | unchanged but for `markColumn` | town shell, forge, alchemist, crawl Pack |
| `MaterialsPanel` | **deleted** | — |
| `Notice` | unchanged | every room, world |
| `CountStepper` | unchanged | bank ×2, forge, alchemist |
| `Commit` | **new** widget | bank ×2, inn, forge, alchemist, roster |
| `TownRoom` | **reshaped**: body header | all twelve town routes |

The exact new declarations:

```dart
/// The width of every leading mark column in the town.
///
/// One constant rather than a number repeated per row, because the markings are
/// not all one cell wide in the device's monospace font and a column that drifts
/// by two pixels steps sideways on the phone.
const double markColumn = 28;

/// The type a place announces itself in.
const TextStyle placeName = TextStyle(
  fontFamily: 'monospace',
  fontSize: 20,
  letterSpacing: 5,
  color: ink,
);

/// The type a room inside a place announces itself in.
const TextStyle roomName = TextStyle(
  fontFamily: 'monospace',
  fontSize: 15,
  letterSpacing: 4,
  color: ink,
);

/// The one control that commits a room's work.
class Commit extends StatelessWidget {
  const Commit({required this.label, required this.onPressed, super.key});

  final String label;

  /// Null leaves the control on the row and dead, which is the town's rule.
  final VoidCallback? onPressed;
}
```

`Commit`'s build is exactly a `Padding(vertical: 6)` around a `FilledButton`
with `FilledButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16))` whose
child is `Text(label, style: TextStyle(fontFamily: 'monospace', fontSize: 15))`.
It introduces no key, no semantics wrapper, no icon, and no busy state. Its six
adopters previously hand-rolled that same button at font size 14 or 15 and
vertical padding 14 or 16; unifying them on 15/16 is the point.

`TownRoom` after the reboot:

```dart
Scaffold(
  appBar: AppBar(backgroundColor: panel, foregroundColor: ink),
  body: ListView(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
    children: [
      Text(title, style: roomName),
      const Divider(color: rule, height: 22),
      ...children,
      const SizedBox(height: 24),
    ],
  ),
)
```

The `AppBar` keeps no `title`; it exists for the automatically inserted back
button, which `tester.pageBack()` and the player both depend on. **The title is
rendered verbatim — never upper-cased** — because `character_screen_test.dart`
and every room test find the room by `find.text('<Title>')`.

`Purse` after the reboot is a `Column(crossAxisAlignment: start)` of the two
unchanged `Text` rows followed by `Divider(color: rule, height: 20)`. The
`Container`, `BoxDecoration`, fill and radius are gone.

### 2. The town shell

`TownScreen` keeps its class name, its `const` constructor, `_titleFor`,
`_descentsSoFar`, `_open`, and the whole scroll skeleton at `:66-76`. Its
`Column` children become, in this exact order:

1. `Text(_titleFor(state.town), style: placeName)`
2. `SizedBox(height: 4)`
3. `Text(_descentsSoFar(state.profile.visit), style: monoDim)`
4. `Divider(color: rule, height: 28)`
5. `Text('Health   ${state.hp} / ${state.maxHp}', style: mono)`
6. `Text('Carried  ${state.gold} gold', style: mono)`
7. `Text('Banked   ${state.bankedGold} gold', style: mono)`
8. `Heading('Materials')`
9. `MaterialRows(materials: state.materials)`
10. `Notice(state.notice)`
11. `Spacer()`
12. the seven `_Door`s

Strings 5–7 and the four `_descentsSoFar` sentences are reproduced **character
for character**, including their internal double spaces. They are the same
strings the world screen prints, and several suites assert them exactly.

`_Door` becomes:

```dart
class _Door extends StatelessWidget {
  const _Door({
    required this.label,
    required this.purpose,
    required this.onPressed,
    super.key,
  });

  final String label;
  final String purpose;
  final VoidCallback? onPressed;
}
```

Its build is a `Column` of `Divider(color: rule, height: 1)` and a `TextButton`
with `TextButton.styleFrom(alignment: Alignment.centerLeft, padding:
EdgeInsets.symmetric(horizontal: 8, vertical: 12), foregroundColor: ink)` whose
child is a left-aligned `Column(mainAxisSize: min)` of `Text(label, style: mono)`,
`SizedBox(height: 2)` and `Text(purpose, style: monoDim)`.

A `TextButton` rather than a bare `InkWell` because the row must keep a button
role for accessibility; `FilledButton` is retired here because seven identical
filled slabs are precisely the "heavy uniform card furniture" the contract
replaces. Both `Text`s carry explicit colours, so the button's foreground never
decides them.

Each door takes `key: Key('town-door-<lowercase label>')`.

**The seven doors and their locked purpose lines**, in the locked order. Each
line is short enough for a 360-pixel-wide phone in one line of `monoDim` and
every content word already exists in source:

| # | Label | Purpose line | Source of the words |
| --- | --- | --- | --- |
| 1 | `Merchant` | `Buy, sell, and buy back` | the three action labels, `merchant_screen.dart:58,70,84` |
| 2 | `Bank` | `Gold and gear, safe from death` | `Heading('Banked — safe from death')`, `bank_screen.dart:122` |
| 3 | `Inn` | `A bed for the night` | `Heading('A bed for the night')`, `inn_screen.dart:44`, verbatim |
| 4 | `Character` | `Gear, spells, skills, and pack` | the four Unit 6 route labels, `character_screen.dart` |
| 5 | `Tavern` | `Ask about the roads` | the offer row's own name, `tavern_screen.dart:39`, verbatim |
| 6 | `Forge` | `Smelt ore, temper steel` | `'$smeltCost ore makes 1 ingot.'` `:54`, `'Temper'` `:158`, `Heading('Worn steel')` `:88` |
| 7 | `Alchemist` | `Brew herbs into potions` | `'$brewCost herbs make 1 healing potion.'`, `alchemist_screen.dart:60` |

No purpose line contains another door's label, the word `Heroes`, or any
material `word` (`Ore`, `Ingot`, `Herb` are capitalised in content; the purpose
lines use lower-case prose), so no existing finder changes meaning.

**No new mark codepoint is introduced anywhere in this unit.** The door rows
carry no chevron, arrow, or bullet; separation is a rule, hierarchy is type
size, and the affordance is the button. This is a deliberate decision against
the Unit 5 trap (`↕` U+2195 resolved through Android's colour emoji font, and
U+2B65 is tofu on this target): a mark that no widget test can see is a mark
this unit will not ship. An executor who believes a mark is required must
escalate rather than add one.

### 3. What every room keeps

These are contract obligations restated as implementation constraints. No task
may reword, relocate into a dialog, hide behind a disclosure, or make
conditional any of them.

**Merchant.** `For sale`, the conditional `Sold this visit`, `Your pack`, in
that order; all three lists through `stacked(...)` with `stack.label` and the
per-item price on the button; `Buy n` / `Buy back n` / `Sell n`; buy-back priced
at `sellPriceOf`; `cannotAfford` printed under the name of a dead row and
nowhere else; `The shelf is bare until you come back.` and
`You are carrying nothing.`; every tap dispatching `BuyPressed` / `BuyBackPressed`
/ `SellPressed` with `stack.item.id`.

**Bank.** `purseIsShort` and `vaultIsShort` verbatim, each beside its own dead
commit and only while that side is empty; two `CountStepper`s, carried side
first, capped at `state.gold` and `state.bankedGold` and re-clamped on every
rebuild; `DepositGoldPressed`/`WithdrawGoldPressed` dispatched once with the
dialled amount and the local pending count reset to zero; item rows never dead;
`Carried — lost if you die` above `Banked — safe from death`; `The vault is
empty.`

**Inn.** `Health   h / m`, `Price    n gold`, a `Rest` commit enabled exactly
when `state.canRest && state.gold >= innPrice`, and `_why`'s three sentences
with health checked first.

**Tavern.** Both headings; the offer as an `ItemRow` with marking `[!]`, name
`Ask about the roads` and action `Ask $rumorPrice`; the exhausted sentence in
full; `world.log.reversed.take(6)` in `monoDim`; `Nothing yet.`; the notice
resolved as `town.notice ?? world.notice`; `_ask` unchanged.

**Forge.** `$smeltCost ore makes 1 ingot.`; the dial capped at
`countOf(materials, ore) ~/ smeltCost`; a `Smelt` commit dispatching
`SmeltPressed(pending)`; `The fire is hot and the ore is ready.` or the
capitalised `smeltReason`; `The bench`; `You have no steel for the bench.`;
`Worn steel` above `Carried steel` with their two empty sentences; per row the
stat line, the `temperReason` when non-null, and `Next tier: n ingot(s).`
whenever `item.temper < maxTemper` — including on a refused row.

**Alchemist.** `$brewCost herbs make 1 healing potion.`; `The shelf asks n gold
for one.`; the dial capped at `min(herbs ~/ brewCost, inventoryCap - inventory.length)`;
a `Brew` commit dispatching `BrewPressed(pending)`; `The pot is on and you have
what it takes.` or the capitalised `brewReason`; the bloc's notice rendered
unmodified, so a batch-loss sentence reaches the screen ahead of a level-up one.

**Heroes.** Every hero row states `rosterLine` verbatim; the played hero carries
the word `playing`; tapping another hero pops `PlayHero(id)` and tapping the
played hero pops nothing; `Delete` opens the confirmation; `Keep this hero`
answers nothing; `Delete this hero` pops `DropHero(id)` unless this is the last
hero, in which case it flows into `_create(replacing: id)` and pops
`MakeHero(label, replacing: id)`; the name dialog is prefilled with
`heroLabelFor(document.heroes.length)` and a blank trimmed answer falls back to
that offered label; `Not yet` answers nothing.

### 4. What no task may do

No task adds a room framework, a generic room/section/action model, a route
registry, a view model, a controller, a `State` that holds a game fact, a
persisted filter or selection, a theme extension, an `assets/` declaration, an
image, an icon family, a portrait slot, a semantics label that repeats a visible
word, or a second way to reach any existing transaction. No widget computes a
price, a cap the bloc already computes, a refusal, or a rule sentence.

## Migration and removal inventory

Task 01:

- rewrite `lib/town/town_style.dart`: add `markColumn`, `placeName`, `roomName`,
  `Commit`; reshape `Purse` and `TownRoom`; delete `MaterialsPanel`;
- rewrite `lib/town/town_screen.dart`: header, status, materials heading, notice,
  seven keyed purpose rows, unchanged scroll skeleton, `_Door` reshaped;
- mechanical call-site migrations forced by the above, and nothing else in those
  files: `MaterialsPanel(...)` → `Heading('Materials'), MaterialRows(...)` in
  `forge_screen.dart` and `alchemist_screen.dart`; the six hand-rolled commit
  buttons → `Commit(...)` in `bank_screen.dart` (×2), `inn_screen.dart`,
  `forge_screen.dart`, `alchemist_screen.dart`, `roster_screen.dart`;
- add `test/widget/town_shell_test.dart` and move the `the town door column`
  group out of `test/widget/craft_rooms_test.dart` into it.

Task 02: rewrite the bodies of `merchant_screen.dart`, `bank_screen.dart`,
`inn_screen.dart`, `tavern_screen.dart`; extend `bank_screen_test.dart`; add
`test/widget/tavern_screen_test.dart`.

Task 03: rewrite the bodies of `forge_screen.dart` and `alchemist_screen.dart`,
including `_TemperRow`'s columns; extend `craft_rooms_test.dart`.

Task 04: rewrite `RosterScreen.build` and `_HeroRow`; extend
`roster_screen_test.dart`.

Nothing is left behind: no `MaterialsPanel`, no hand-rolled commit button, no
second material block, no filled purse card, no `AppBar` room title, no
compatibility constructor, no deprecated alias, and no test asserting the
retired composition.

## Explicit non-goals and forbidden expansion

- No edit under `packages/core` or `packages/content`, and none to save code,
  the save document, the save version, RNG, balance, item ids, prices, recipes,
  or rules.
- No edit to `lib/town/town_bloc.dart`, `lib/world/world_bloc.dart`,
  `lib/world/world_screen.dart`, `lib/main.dart`, `lib/notice/notice.dart`,
  `lib/save/**`, `lib/game/**`, or the Unit 6 routes `character_screen.dart`,
  `gear_screen.dart`, `spells_screen.dart`, `skills_screen.dart`,
  `town/pack_screen.dart`.
- No change to `Heading`, `NothingHere`, `ItemRow`, `MaterialRows`,
  `CountStepper` or `Notice` beyond the named `markColumn` substitution.
- No asset, image, portrait, icon family, `assets/` declaration, colour-carried
  state, or new mark codepoint.
- No world, travel, discovery, or Heroes-entry-point work; no crawl, Flame,
  timeline, log drawer, shelf, targeting, or HUD work.
- No new room, door, currency, action, price, recipe, stacking rule, sorting
  rule, or rewording of any refusal, price, or explanatory sentence.
- No new package dependency, analytics, telemetry, or external write.

## Integrated proof ownership

The task briefs name exact Red/Green and focused commands. After task 04 is
green, Main runs from `packages/app`:

```sh
dart format --set-exit-if-changed --output=none \
  lib/town/town_style.dart lib/town/town_screen.dart \
  lib/town/merchant_screen.dart lib/town/bank_screen.dart \
  lib/town/inn_screen.dart lib/town/tavern_screen.dart \
  lib/town/forge_screen.dart lib/town/alchemist_screen.dart \
  lib/town/roster_screen.dart \
  test/widget/town_shell_test.dart test/widget/tavern_screen_test.dart \
  test/widget/merchant_screen_test.dart test/widget/bank_screen_test.dart \
  test/widget/craft_rooms_test.dart test/widget/roster_screen_test.dart
flutter analyze
flutter test
```

Main then verifies the final diff is confined to `packages/app/lib/town`,
`packages/app/test/widget` and architect-owned Unit 7 LDD records, with no
`packages/core`, `packages/content`, save, generated, or dependency-file change,
and no new asset path. Main runs one integrated acceptance review against
`CONTRACT.md`; plan compliance is not a substitute for correctness.

For contract criterion 11, Main uses the current user-started `Medium_Phone`
AVD (it segfaults when launched from a tool shell; ask the user to start it).
Before any install or save-clearing action, copy both device `save.json` and
`save-previous.json` into the untracked Unit 7 evidence directory, record their
SHA-256 values, and afterwards restore both exact byte streams and verify both
hashes. Probe scenes at `visit: 1` or higher, never `visit: 0`, because a first
delve bumps the counter.

The normal-colour and greyscale evidence set must show: the town shell with the
header, the status block, the materials rows, and all seven purpose rows,
including the last door reached by scrolling; each of Merchant, Bank, Inn,
Tavern, Forge and Alchemist with at least one live control and at least one dead
control beside its reason; and Heroes with a multi-hero roster, the `playing`
word, and the delete confirmation. Confirm that the forge shows the material
rows and the bench rows on one mark column, and that no glyph on any of these
screens renders in colour or as tofu. Every mark on these screens is a codepoint
that already shipped, so this pass is a confirmation rather than a first
reading; a colour or tofu glyph is an escalation, not a fix-in-place.

## Global escalation boundary

Stop the affected task and return to the architect if:

- current app source no longer matches a revalidated seam, or another writer has
  changed a planned file;
- a preserved sentence, price, count, heading, or refusal cannot be produced
  from the existing bloc/core value without composing or rewording it;
- a locked composition cannot be delivered without editing `town_bloc.dart`,
  `world_screen.dart`, a Unit 6 route, a shared primitive marked frozen, or
  anything under `packages/core` / `packages/content`;
- the seven-door column cannot be reached on a 600-pixel-tall surface without
  hiding, grouping, or shortening a door;
- a rebooted screen cannot be made legible without a new mark codepoint, a hue
  distinction, or an asset;
- an existing town test fails for a reason other than a composition it pinned,
  which means behaviour moved;
- `Commit` cannot replace a hand-rolled button without changing what a test can
  find or what a press dispatches;
- the roster's pop protocol, replacement write, or prefilled-name fallback
  cannot be preserved as written.

Executor discretion across all tasks is limited to private helper and
file-private widget names, local widget splitting, padding and spacing within
the vocabulary this plan locks, and test fixture placement. It does not include
public class, constructor, parameter, constant or key names, the door order or
labels, the purpose lines, displayed strings, control types a test finds by
type, action or refusal ownership, file ownership, or the removals above.

## Plan quality gate

- **COR — PASS.** Ownership is explicit and unchanged: core owns rules and
  sentences, `TownBloc` owns transactions and computed refusals, screens project.
  No task edits a bloc. Every transaction keeps its event, its id argument and
  its room. Dead-control semantics are stated per room, notice placement is
  unified without changing which notice wins, and the bank's restructure keeps
  stepper order so existing ordinal finders stay correct. The scroll skeleton
  that fixed the 45-pixel overflow is preserved verbatim, and the reachability
  proof is moved onto the 600-pixel surface where the defect actually lived. The
  one cross-unit hazard — `Heading`, `ItemRow`, `MaterialRows`, `NothingHere`
  being shared with `world_screen.dart` and the crawl Pack — is resolved by
  freezing them, so Unit 7 cannot bleed into Unit 8 or the crawl.
- **TTC — PASS.** Task 01 has behavioural Red for absent purpose lines and an
  absent body header, plus a 600-pixel reachability guard and a door-to-room
  navigation proof. Task 02 has Red for the bank's interleaved gold section and
  the tavern's stray notice, and adds the first coverage of the tavern's six-line
  cap, exhausted line and world-bloc notice fallback. Task 03 has Red for the
  misaligned bench column and adds the first widget-level proof that a batch-loss
  sentence reaches the alchemist's notice slot. Task 04 has Red for an unruled
  roster and re-proves the pop protocol, the confirmation, the living-crawl
  warning and the never-empty replacement. Every other preserved behaviour is
  proved by an **existing** town suite passing **unchanged**, which is the
  strongest available evidence that the reboot was presentation-only: source
  inspection confirms the current town widget tests assert text and bloc state,
  not composition, with the single exception of `bank_screen_test.dart:32-45`,
  which stays true and stays untouched. No test is rewritten merely because a
  screen changed shape.
- **CRF — PASS.** One town grammar, extracted once: a new `Commit` replaces six
  hand-rolled buttons, `MaterialsPanel` is deleted in favour of the material
  block the crawl Pack already uses, and `markColumn` gives the three mark
  columns one owner. Nothing is wrapped, aliased, or left beside its replacement.
  No generic room framework, action model, or view model is planned; the door
  row and the place header stay private to the one screen that has doors and the
  one screen that is a place. The three primitives with consumers outside the
  town are deliberately not touched, which is the anti-duplication decision as
  well as the scope decision.
- **SEC — SKIP (no new trust boundary).** Unit 7 is local Flutter presentation
  over existing immutable state and existing core transactions. It adds no
  network, deserialization, persistence, privilege, external input, secret, or
  asset boundary. Refusal text is produced by existing rule functions and
  rendered, never parsed into authority. The roster continues to read the live
  `SaveDocument` and to answer with a value the session interprets; no task
  changes what is written to disk.

Residual risks deliberately left to implementation and device evidence:

1. **A mark codepoint can render as a colour emoji or tofu on device and no
   widget test will ever see it.** Mitigated structurally — this unit introduces
   no new codepoint — and confirmed by the device pass. Any executor who wants
   one must escalate.
2. **Mark columns must be laid out as fixed-width columns, never space-padded
   strings**, because the device monospace gives the ingot bar and the ore
   diamond different widths. `markColumn` makes that a single constant; the
   forge's bench alignment is the visible test and is a named device-evidence
   item.
3. **The seven-door column must stay reachable on a 600-pixel-tall screen.** The
   purpose lines make the column taller than it is today. The scroll skeleton is
   preserved and task 01 owns an explicit 600-pixel reachability proof, but the
   final word is the phone.
4. **`TownRoom`'s horizontal padding widens from 12 to 20**, narrowing every
   room row by 16 pixels. `ItemRow` clips with `maxLines: 2` and an ellipsis and
   `world_screen.dart` already runs `ItemRow` at padding 20, so this is expected
   to be safe; the room tests run under `onAPhone` and the device pass confirms.
5. **`Commit` unifies two font sizes and two paddings.** No test reads either,
   but a control that grew four pixels taller on six screens is a fit question
   the device pass answers.

None of these requires an unresolved product decision.

## Planner receipt

- **STATUS:** READY — execution-grade; implementation remains separately
  authorized.
- **Source/dirty assumption:** `319d945` on `main`; `packages/` clean;
  architect-owned `LEDGER.md`, `RESUME.md` and `units/unit-7/` dirty or
  untracked and preserved. Implementation must branch to
  `residuum-visual-reboot-7`, never write on `main`.
- **Tasks:** `01-town-grammar-and-shell.md` → `02-counter-rooms.md` →
  `03-crafting-rooms.md` → `04-heroes-roster.md` → Main gates. 02, 03 and 04 are
  file-disjoint and may be run concurrently if Main prefers isolation.
- **Quality:** COR/TTC/CRF PASS; SEC SKIP for no trust-boundary change.
- **Next action:** Main validates this receipt, presents the plan for explicit
  user approval, and only then dispatches task 01 to a fresh non-isolated
  `flow-plan-executor` on a Unit 7 feature checkout.
