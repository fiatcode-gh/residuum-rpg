# Unit 5 — Log Drawer: Execution Plan

Status: **execution-grade; planning only.** This artifact does not authorize
production implementation.

Derived from `CONTRACT.md`, `recon.md`, the three Unit 5 ledger forks
(`LEDGER.md` 2026-09-14), the approved mock at
`.flow/evidence/visual-reboot/residuum_visual_reboot_approved_mock.png`, and
current source read at `864aa6eb` (`864aa6e`, branch `main`, Unit 4 merged).
The working tree was clean at planning time: `git status --porcelain` returned
nothing, so every line number below is the committed one. `recon.md` was
verified at `0eb76d3`; every seam it names was re-read at `864aa6e` and all of
them hold. A changed app source revision requires targeted revalidation of the
named seams, not automatic redesign.

## Execution boundary

Use one non-isolated feature checkout/branch based on `864aa6e`, normally
`residuum-visual-reboot-5`; never implement this unit directly on `main`.
Dispatch one fresh `flow-plan-executor` per brief, sequentially in the same
checkout so repository state — not executor memory — carries the handoff:

1. `plan-tasks/01-log-line-and-categories.md`
2. `plan-tasks/02-drawer-and-follow-state.md` after task 01 is green
3. `plan-tasks/03-peek-drawer-and-glyphs.md` after task 02 is green

Each task owns its focused Red/Green cycle, touched-file formatting, and focused
static checks. Main owns the final whole-app gates (criterion 11) and the phone
AVD colour/greyscale session (criterion 12) after all three tasks land.

Only `packages/app` is in scope. `packages/core`, `packages/content`, the save
document, and the save version are untouched — criterion 10 is satisfied by the
fact that no file outside `packages/app/lib` and `packages/app/test` is edited.

## Source facts this plan is built on

Re-read at `864aa6e`; each is load-bearing.

| Fact | Source |
| --- | --- |
| `GameViewState.log` is `List<String>`; the constructor takes it at `:160` and the field is `:171` | `lib/game/game_bloc.dart` |
| `GameBloc({List<String> log = const []})` at `:536`, passed to the initial state at `:542` | `lib/game/game_bloc.dart` |
| View-only transitions thread `log: state.log` at `:603, 638, 665, 728, 746, 766, 918`; the three append paths are `_act` `:841`, `_onAutoWalkAdvanced` `:891`, `_afterAction` `:909` | `lib/game/game_bloc.dart` |
| Refusals are appended directly: `_watchedRefusal` `:623`, `_backRefusal`/`_roadBackRefusal` `:815-818` | `lib/game/game_bloc.dart` |
| `_presentStep` `:926` builds `({List<String> lines, ActorIdentityContext identity})`; `_describe` `:943`, `_ambushBeat` `:982`, `_beats` `:1036` all produce sentences | `lib/game/game_bloc.dart` |
| `const String roadOpeningLog` `:1105` and `const String bottomOfTheDelve` `:1098` are public; `bottomOfTheDelve` is asserted in `test/game_bloc_test.dart:1226` | `lib/game/game_bloc.dart` |
| `describeEvent` returns `String?` from one exhaustive switch over sealed `GameEvent`, `:15-79`. It is the only place that knows the variant | `lib/game/event_messages.dart` |
| `AttackHit` branches on `attackerId == heroId` at `:25-32`; `AttackDodged` `:39` does not, and does not need to | `lib/game/event_messages.dart` |
| `AttackDodged` and `WardStruck` are emitted only inside `_defend`, which exists only for blows aimed at the hero (`events.add(AttackDodged(attackerId: attacker.id))` at `:859`, `WardStruck` at `:870`) | `packages/core/lib/src/engine/step.dart` |
| `_MessageLog` is a fixed 104-logical-pixel `Container`, `0xFF15181F`, padding `12/8`, holding a `reverse: true` `ListView.builder`; newest `0xFFE6EAF0`, older `0xFF8A919E` | `lib/game/game_screen.dart:682-706` |
| `_MessageLog` renders **after** `_Controls` in the `Column` at `:120-121`; `_DeathOverlay` is the `Stack` sibling at `:124`, a `ColoredBox(0xCC0E1014)` over the whole stack at `:714` | `lib/game/game_screen.dart` |
| `_DungeonSceneHostState._reusesProjection` compares game identity, palette, `armedSpellId`, identity context and `selectedActorId` only — `:165-170` | `lib/game/dungeon_scene.dart` |
| `main.dart` injects `roadOpeningLog` `:421`, `_openingLog()` `:585/:616`, `_asSentence(notice)` `:631`, `_resumed` `:634`; the dartdoc at `:572` fixes that the log is view state that does not survive a suspend | `lib/main.dart` |
| `WorldViewState.log` at `lib/world/world_bloc.dart:79` is a **different** `List<String>` and is out of scope; `test/world_bloc_test.dart`'s eleven `.log` references belong to it | — |
| No test asserts the current peek/controls order: `_MessageLog` and `_Controls` are private and unkeyed, and no widget test references either | `packages/app/test` |

## Locked decision 1 — the entry type

Add `packages/app/lib/game/log_line.dart`. Its only import is
`package:equatable/equatable.dart`: no Flutter, no Flame, no core. It is
app-only presentation state, and nothing in it knows what a `GameEvent` is.

```dart
/// What kind of thing one line of the message log reports.
enum LogCategory {
  struck('←', 'struck'),
  hit('→', 'hit'),
  died('†', 'died'),
  noticed('◎', 'noticed'),
  moved('⇅', 'moved'),
  refused('✕', 'refused'),
  item('■', 'item'),
  raised('▲', 'raised'),
  gathered('◆', 'gathered'),
  reported('§', 'reported');

  const LogCategory(this.mark, this.word);

  /// The non-hue mark the expanded log draws in its leading column.
  final String mark;

  /// What the category is called out loud, for the accessibility label.
  final String word;
}

/// One line of the message log: the sentence, and the one kind it is.
final class LogLine extends Equatable {
  const LogLine(this.sentence, this.category);

  final String sentence;
  final LogCategory category;

  @override
  List<Object?> get props => [sentence, category];
}
```

Rationale for each choice, because each is a fork:

- **`LogLine`, not `LogEntry`.** `event_messages.dart:3` already calls this
  concept "One line of the message log"; `game_screen.dart:701` calls the older
  ones "older lines"; `_presentStep` already names the field `lines`. "Entry"
  would be a synonym for a concept the codebase already names, which AGENTS.md
  calls a defect.
- **`LogCategory`, and the word "category".** `CONTRACT.md` uses it throughout
  ("exactly one category from a closed set"). The contract is the authority for
  a concept core does not have.
- **A `final class`, not a record.** A record cannot carry the dartdoc the
  public consts need, cannot be named in `List<LogLine>` signatures without an
  alias, and has no home for `props`. `ActorPresentation`
  (`lib/game/actor_presentation.dart:4`) is the precedent for "an app-only
  presentation value gets a small final class in its own file".
- **Positional constructor.** `describeEvent`'s switch has 34 arms; named
  arguments would double its width for no information. Two fields in the order
  the concept is spoken ("sentence, category") is unambiguous.
- **`Equatable`.** `test/game_bloc_test.dart:1226` asserts
  `bloc.state.log.last == bottomOfTheDelve`, which becomes a `LogLine`
  comparison. `SaveNotice` (`lib/notice/notice.dart:15`) is the app precedent
  for a value object that carries `Equatable`; relying on const canonicalization
  instead would make that assertion break the day someone builds the constant
  non-const.
- **Its own file, not `event_messages.dart` and not `actor_presentation.dart`.**
  `game_bloc.dart`, `main.dart` and the drawer widgets all need the type but not
  the formatter; `actor_presentation.dart` is about actors, and this is about
  lines. AGENTS.md: files stay small, and a large file means a concept wants
  splitting.
- **`mark` and `word` live on the enum, in this file.** They are plain strings,
  so the file stays Flutter-free, and the producer (task 01) and consumer
  (task 03) share one definition rather than a widget-side lookup table that can
  drift from the enum.

The entry carries the sentence and the category and nothing else. No actor id,
severity, timestamp, or turn number: the contract's non-goals rule each out.

## Locked decision 2 — the category set

Ten members, no catch-all. Nine names are words already in a `core` event name;
the tenth, `reported`, names a kind core has no event for and takes its word
from the consuming app code. The design spec has no log vocabulary (verified:
`grep -n log` over `docs/specs/2026-08-20-dungeon-game-design.md` finds only
`dialogue`, `logic` and `logs`), so core event names are the only legitimate
source for everything the rules produce, exactly as the ledger records.

| Member | Means | Name comes from |
| --- | --- | --- |
| `struck` | a blow arriving at the hero | `WardStruck` |
| `hit` | the hero's own blow or bolt landing on a monster | `AttackHit` |
| `died` | an actor ran out of hit points | `ActorDied` |
| `noticed` | something is in sight now that was not | `ActorNoticed` |
| `moved` | where the hero is: a step, a stand, a depth, a road left behind | `ActorMoved` |
| `refused` | the rules would not do what was asked | `ActionRefused` |
| `item` | the line names an item passing through the hero's hands | `ItemDropped`, `ItemPickedUp`, `ItemEquipped`, `ItemUnequipped`, and `PotionDrunk.item` |
| `raised` | the hero's own standing went up | `WardRaised` |
| `gathered` | the hero worked a node for material | `NodeGathered` |
| `reported` | the interface reporting on the session or the launch, not the world acting | `main.dart:617-618` `_reported` and the `_openingLog` dartdoc at `:606`, "The fallback report" |

This set covers every distinction the contract demands: harm arriving on the
hero (`struck`), the hero's offense landing (`hit`), a death (`died`), something
coming into view (`noticed`), movement or a change of depth (`moved`), and a
refusal (`refused`).

### Every arm of `describeEvent`

In source order, `event_messages.dart:19-79`. Thirty-four arms, thirty-two of
which produce a sentence.

| # | Arm | Category |
| --- | --- | --- |
| 1 | `ActorMoved` when `actorId == heroId` | `moved` |
| 2 | `ActorMoved()` → `null` | none |
| 3 | `MoveBlocked` when `actorId == heroId` | `refused` |
| 4 | `MoveBlocked()` → `null` | none |
| 5 | `AttackHit` when `attackerId == heroId` | `hit` |
| 6 | `AttackHit` (afar and claw branches) | `struck` |
| 7 | `ActorDied` when `actorId == heroId` | `died` |
| 8 | `ActorDied` | `died` |
| 9 | `ActorNoticed` | `noticed` |
| 10 | `Descended` | `moved` |
| 11 | `Ascended` | `moved` |
| 12 | `AttackDodged` | `struck` |
| 13 | `ItemDropped` | `item` |
| 14 | `ItemPickedUp` | `item` |
| 15 | `InventoryFull` | `refused` |
| 16 | `ItemEquipped` | `item` |
| 17 | `ItemUnequipped` | `item` |
| 18 | `ActionRefused` | `refused` |
| 19 | `PotionDrunk` when `healed == 0` | `item` |
| 20 | `PotionDrunk` | `item` |
| 21 | `SpellLearned` | `raised` |
| 22 | `SpellHit` | `hit` |
| 23 | `MendCast` when `healed == 0` | `raised` |
| 24 | `MendCast` | `raised` |
| 25 | `WardRaised` | `raised` |
| 26 | `WardStruck` when `remaining == 0` | `struck` |
| 27 | `WardStruck` | `struck` |
| 28 | `MonsterBound` | `hit` |
| 29 | `MonsterBanished` | `hit` |
| 30 | `NodeGathered` | `gathered` |
| 31 | `SkillLevelledUp` | `raised` |
| 32 | `Fled` | `moved` |
| 33 | `HeroWaited` | `moved` |
| 34 | `GameOver()` → `null` | none |

Four assignments need their reasoning recorded because a reviewer will ask:

- **`AttackDodged` is `struck` with no hero branch.** Core emits it only from
  `_defend` (`step.dart:859`), which runs only for a blow aimed at the hero, so
  the attacker is never the hero. The dodged swing is a blow arriving; it simply
  did not land. Direction is available without new knowledge, exactly as the
  contract notes for `AttackHit`.
- **`MoveBlocked` and `InventoryFull` are `refused`, not `moved`/`item`.** Both
  are the rules declining: core's own dartdoc for `InventoryFull` is "The hero
  is carrying all it can and left the item where it lay." The contract requires
  refusal to be distinguishable from movement, and this is where that line is
  drawn.
- **`MonsterBound` and `MonsterBanished` are `hit`.** They are the hero's spell
  landing on a monster. Grouping them with `raised` would say the hero gained
  something; grouping them with `struck` would reverse the direction.
- **`PotionDrunk` is `item`, not `raised`.** The event carries an `Item` and the
  sentence names it. `raised` is for gains that are not things in the hero's
  hands.

`HeroWaited` sits in `moved` because `moved` is "where the hero is", and core's
own dartdoc for the event is "The hero held ground: the turn passed and nothing
else changed" — a statement about position, made deliberately.

### Every line the app injects itself

| Site | Sentence | Category |
| --- | --- | --- |
| `game_bloc.dart:1072` `_watchedRefusal` | `Something is watching. You stay put.` | `refused` |
| `game_bloc.dart:1078` `_backRefusal` | `You can only leave at the stairs.` | `refused` |
| `game_bloc.dart:1113` `_roadBackRefusal` | `You can only leave by walking off the edge of the road.` | `refused` |
| `game_bloc.dart:1105` `roadOpeningLog` | `Something is on the road. …` | `noticed` |
| `game_bloc.dart:1098` `bottomOfTheDelve` | `This is the bottom of the delve.` | `moved` |
| `game_bloc.dart:999` `_ambushBeat` | `… gets the drop on you.` | `struck` |
| `game_bloc.dart:1042` `_beats` boss line | `… is slain. The delve is yours.` | `died` |
| `main.dart:634` `_resumed` | `The crawl resumes.` | `reported` |
| `main.dart:631` `_asSentence(notice)` | the `SaveNotice` sentence | `reported` |

`_ambushBeat` and `_beats` are injection sites the contract's list does not name
but which produce lines; they are covered here rather than discovered during
implementation. `_theDungeonRefusedThat` (`game_bloc.dart:1081`) needs no
assignment of its own: it rides an `ActionRefused` event and takes arm 18.

**Why these two are `reported` and not `moved`/`refused`.** They are the only
lines in the log that the interface speaks about itself rather than about the
world, and source rules out both alternatives:

- `_asSentence` cannot be `refused`. `SaveNotice` is a channel, not a verdict:
  `LoadNotice` is documented as "What booting found, **or failed to find**, on
  disk" (`lib/notice/notice.dart:25`) and `SentenceNotice` is the generic
  variant that carries "the town's transactions … and the forge['s] level-up
  announcements" (`:63-69`). A neutral find and an outright gain would both be
  marked `✕`, the most negative mark in the set. Only `ResumeRefusedNotice`
  (`:52`) and `SaveWriteFailedNotice` (`:36`) are refusals, and the call site
  cannot tell which variant it holds.
- `_resumed` cannot be `moved`. "The crawl resumes." is not a step, a stand, a
  depth, or a road left behind, so `⇅` would assert a spatial event that did not
  happen — on the first line every resumed crawl shows, which makes it the
  most-read line in the set. `_openingLog`'s own dartdoc says it plainly
  (`main.dart:613`): "The notice is a fact about the launch, not about this
  crawl."

`reported` is that one real kind and it covers exactly these two sites; every
other app injection stays where the table puts it. The name is not `notice`:
`notice` beside `noticed` in one enum is a readability hazard. `§` is its mark —
U+00A7, Latin-1 Supplement, so font coverage is as wide as it gets; it is
neither an arrow nor the saltire, and its silhouette does not collide with
`† ◎ ■ ▲ ◆`.

### How the compiler enforces exhaustiveness

`describeEvent` switches over the sealed `GameEvent` hierarchy with no default
arm, so a new core variant is a compile error at that switch today and stays one
after the return type changes. Because the category is produced **inside the
same arm as the sentence**, no variant can acquire a sentence without acquiring
a category in the same edit.

The compiler cannot prove every `LogCategory` member is reachable, and the
members have two producers, so two tests cover `LogCategory.values` between
them:

- nine members are event-reachable. Task 01 proof 3 maps one instance of every
  sentence-producing variant through `describeEvent` and asserts the resulting
  set equals `LogCategory.values.toSet()` minus `{LogCategory.reported}`. It
  fails if a member goes dead, if a new member arrives without an event mapping,
  or if someone quietly maps an event to `reported`.
- `reported` is app-injected only, from two private members of `_SessionState`.
  Task 01 proves it end to end through the real boot path by extending
  `test/widget/boot_wiring_test.dart:50-70`, whose resumed-crawl case already
  asserts `find.text('The crawl resumes.')`: it additionally reads the live bloc
  and asserts the log contains the exact
  `LogLine('The crawl resumes.', LogCategory.reported)`.

Together the two assertions are total over `LogCategory.values` without either
one pretending to cover a producer it cannot reach.

## Locked decision 3 — where the mapping lives

`describeEvent` changes its return type to `LogLine?` and keeps its one switch:

```dart
LogLine? describeEvent(
  GameEvent event,
  Map<String, String> names, {
  Set<String> strikesFromAfar = const {},
}) => switch (event) { … };
```

Each sentence-producing arm becomes `LogLine('…', LogCategory.x)`. There is no
sibling `categoryOf(GameEvent)` function and no second switch: two switches over
the same sealed type is exactly the drift the contract forbids, and a sibling
switch would let a future variant get a sentence from one and a wrong default
from the other.

Consequential signature changes that follow, all in `game_bloc.dart`:

- `_describe(before, events, names)` → `List<LogLine>`;
- `_ambushBeat(before, events, names)` → `LogLine?`;
- `_beats(before, events, names)` → `Iterable<LogLine>`;
- `_presentStep(...)` → `({List<LogLine> lines, ActorIdentityContext identity})`;
- `GameViewState.log` → `List<LogLine>`, constructor parameter unchanged in name;
- `GameBloc({List<LogLine> log = const []})`;
- `const LogLine roadOpeningLog` and `const LogLine bottomOfTheDelve` replace the
  two public `String` consts; `_watchedRefusal`, `_backRefusal`,
  `_roadBackRefusal` become `const LogLine` too, so no call site composes a
  category.

In `main.dart`: `_openingLog()` → `List<LogLine>`, `_asSentence(String)` →
`LogLine`, `_resumed` → `const LogLine`. The documented property at `:572` — the
log is view state that does not survive a suspend, a resumed crawl opens with
one explanatory line, a fresh crawl opens empty — is preserved exactly; only the
element type changes. No save document, autosaver field, or save version is
touched.

No `List<String>` view of the log survives anywhere in `lib/`.

## Locked decision 4 — follow and drawer state ownership

**The bloc owns follow and drawer state. The drawer widget owns scroll position
only, and reports crossings as events.**

Why this way round. Criteria 5, 6 and 8 are behaviors the contract requires to
be bloc-provable — the exact unread count, its clearing, and the collapse on
game-over — and the only thing that knows how many lines a transition appended
is the transition itself, inside the bloc. A widget-owned count would have to
re-derive "how many arrived" from list lengths across rebuilds, which is exactly
the drift into total-history-length the contract warns about. Conversely, only
the widget knows where the reader is, so scroll position stays there and crosses
the boundary as two facts: follow broke, follow resumed.

### State added to `GameViewState`

```dart
enum LogDrawerExtent { peek, half, full }
```

`LogDrawerExtent` lives in `lib/game/log_line.dart` beside `LogCategory`: it is
view state the bloc carries, so it must not live in a Flutter file that
`game_bloc.dart` would then have to import.

```dart
GameViewState({
  required this.game,
  required this.log,
  this.autoPath = const [],
  this.walkId = 0,
  this.pan = Offset.zero,
  this.hasFled = false,
  this.armedSpellId,
  ActorIdentityContext? actorIdentity,
  this.selectedActorId,
  LogDrawerExtent logDrawerExtent = LogDrawerExtent.peek,
  bool logFollowing = true,
  int logUnread = 0,
}) : actorIdentity = actorIdentity ?? ActorIdentityContext.fromGame(game),
     logDrawerExtent = game.isGameOver ? LogDrawerExtent.peek : logDrawerExtent,
     logFollowing = _followsAt(game, logDrawerExtent, logFollowing),
     logUnread = _followsAt(game, logDrawerExtent, logFollowing) ? 0 : logUnread;

static bool _followsAt(
  GameState game,
  LogDrawerExtent extent,
  bool following,
) => following || game.isGameOver || extent == LogDrawerExtent.peek;

final LogDrawerExtent logDrawerExtent;
final bool logFollowing;
final int logUnread;
```

Three invariants are therefore **enforced by construction**, which is the
convention this file already documents for `pan` (`game_bloc.dart:181-188`):

1. game-over collapses the drawer to `peek` — decision 8, unforgettable;
2. game-over and `peek` both imply follow is on, because the peek is anchored to
   the newest entry by construction and a peek with follow off would be the
   state lying about what the player is looking at;
3. following implies zero unread, so no path can show `↓ N new` while the reader
   is at the newest entry.

### The unread count

One private helper on `GameBloc`, used by every append path and nowhere else:

```dart
int _unreadAfter(int appended) =>
    state.logFollowing ? 0 : state.logUnread + appended;
```

`appended` is always the literal number of lines this transition added:
`presentation.lines.length` in `_act`, `_afterAction` and `_onAutoWalkAdvanced`;
`1` at the watched refusal (`:623`) and the system-back refusal (`:815`). It is
never `log.length`, never a difference of lengths, and never recomputed from the
list. That is how the count cannot drift into total history length: the only
number it ever sees is the size of one append.

### Carrying through a turn

The three append paths deliberately **drop** `armedSpellId`, `pan` and
`selectedActorId` by not naming them. Drawer and follow state must be carried:
taking a turn with the drawer open must not close it. So `_act`, `_afterAction`
and `_onAutoWalkAdvanced` each name `logDrawerExtent: state.logDrawerExtent`,
`logFollowing: state.logFollowing`, `logUnread: _unreadAfter(...)`, and every
view-only transition (`:603, 623, 638, 665, 728, 746, 766, 815, 918`) names all
three carried unchanged. This is a hazard rather than a detail: the default-drop
convention would otherwise collapse the drawer on every turn, and no existing
test would notice.

### The four drawer events

Added to `game_bloc.dart` and registered in the constructor's `on<…>` block
(`:545-564`):

```dart
final class LogDrawerHandlePulled extends GameBlocEvent { const LogDrawerHandlePulled(); }
final class LogDrawerClosed extends GameBlocEvent { const LogDrawerClosed(); }
final class LogFollowBroken extends GameBlocEvent { const LogFollowBroken(); }
final class LogFollowResumed extends GameBlocEvent { const LogFollowResumed(); }
```

Handler semantics, all view-only:

- `_onLogDrawerHandlePulled` — returns without emitting when
  `state.game.isGameOver`. Otherwise advances `peek → half → full → peek` and
  emits a state carrying `game`, the identical `log` list, `autoPath`, `walkId`,
  `pan`, `armedSpellId`, `hasFled`, `actorIdentity`, `selectedActorId`,
  `logFollowing` and `logUnread` unchanged. Arriving at `peek` resumes follow and
  clears the count through the constructor invariant, not through handler code.
- `_onLogDrawerClosed` — emits nothing when the extent is already `peek`;
  otherwise emits the same shape with `logDrawerExtent: LogDrawerExtent.peek`.
- `_onLogFollowBroken` — emits nothing when `!state.logFollowing`; otherwise the
  same shape with `logFollowing: false` (the invariant leaves `logUnread` at 0,
  so the count starts from zero the moment follow stops).
- `_onLogFollowResumed` — emits nothing when `state.logFollowing`; otherwise the
  same shape with `logFollowing: true`, which clears the count.

**`pan` is carried by all four, and only by these and the pan/arm handlers.**
Criterion 7 names `pan` explicitly. A drawer tap is not a new game state, and
snapping the camera underneath an overlay the player just opened would be a
visible jump nobody asked for.

Emitting nothing on a no-op matters: the drawer's scroll listener fires on every
frame of a drag, and a bloc that re-emitted an identical state each time would
rebuild the whole screen at scroll rate.

## Locked decision 5 — drawer composition

Add `packages/app/lib/game/log_drawer.dart` holding the two public widgets and
their keys. `battle_view.dart` (`BattleDock`, `BattleShelf`) is the precedent:
`game_screen.dart` is already 935 lines and owns composition, not chrome.

```dart
const logPeekKey = Key('log-peek');
const logHandleKey = Key('log-handle');
const logDrawerKey = Key('log-drawer');
const logCloseKey = Key('log-close');
const logUnreadKey = Key('log-unread');

class LogPeek extends StatelessWidget { const LogPeek({required this.state, required this.bloc, super.key}); … }
class LogDrawer extends StatefulWidget { const LogDrawer({required this.state, required this.bloc, super.key}); … }
```

`_MessageLog` is deleted from `game_screen.dart`. `game_screen.dart` also gains
`const controlsKey = Key('crawl-controls')` beside the existing `recenterKey`,
`shelfKey`, `overflowKey`, `shelfWaitKey` (`:17-20`), so the peek-above-controls
order is assertable. `_Controls` takes no key today (`:371` is
`const _Controls({required this.state});`) and widens to
`const _Controls({required this.state, super.key});` — one parameter, existing
solely so the order can be proved.

The `Stack` at `game_screen.dart:57` becomes:

```dart
Stack(
  children: [
    Column(
      children: [
        if (state.isBattleOpen) BattleDock(…),
        Expanded(key: dungeonSceneSlotKey, child: …),
        if (state.isBattleOpen) BattleShelf(state: state, bloc: bloc),
        _HitPoints(state: state),
        LogPeek(key: logPeekKey, state: state, bloc: bloc),
        _Controls(key: controlsKey, state: state),
      ],
    ),
    if (state.logDrawerExtent != LogDrawerExtent.peek)
      LogDrawer(key: logDrawerKey, state: state, bloc: bloc),
    if (state.game.isGameOver) _DeathOverlay(state: state),
  ],
)
```

This is the whole of decision 5 and decision 6:

- The `Column` never changes shape when the drawer opens, so the map is never
  reflowed and collapsing restores the pre-expansion arrangement because there
  was nothing to restore. Criterion 3's "byte-for-byte the same widget
  arrangement" is structural, not animated back into place.
- `LogDrawer` sits **before** `_DeathOverlay` in the stack, so the overlay is
  always painted and hit-tested above any drawer chrome. Combined with the
  constructor invariant that collapses at game-over, the drawer cannot be in the
  tree at all when the overlay is.
- A drawer-extent change leaves `game`, `palette`, `armedSpellId`,
  `actorIdentity` and `selectedActorId` identical, so
  `_DungeonSceneHostState._reusesProjection` (`dungeon_scene.dart:165-170`) is
  true and the host takes the `withViewport` path: no re-projection, no Flame
  scene rebuild. The host's `State` is preserved because its position in the
  tree does not move.

### `LogPeek`

Keeps the exact container the contract says to preserve: `height: 104`,
`width: double.infinity`, `color: 0xFF15181F`, padding
`EdgeInsets.symmetric(horizontal: 12, vertical: 8)`. Inside it, a `Column`:

1. a 12-logical-pixel row containing a centred 32×4 rounded pill in
   `0xFF8A919E` — the mock's drag handle;
2. `Expanded` holding the existing `reverse: true` `ListView.builder` with the
   existing `fontFamily: 'monospace'`, `fontSize: 13`, and
   `Color(index == 0 ? 0xFFE6EAF0 : 0xFF8A919E)` newest/older contrast,
   rendering `log[log.length - 1 - index].sentence`.

The whole strip is the hit target: a `GestureDetector` with
`behavior: HitTestBehavior.opaque` and
`onTap: state.game.isGameOver ? null : () => bloc.add(const LogDrawerHandlePulled())`,
wrapped in `Semantics(button: true, enabled: !state.game.isGameOver, label: 'Open the message log')`
and keyed `logPeekKey`. Vertical drags still reach the list, so the peek keeps
scrolling in place. No glyph column: the mock's peek has none, and the contract
puts the glyph column in the expanded log only.

Total height stays exactly 104, so "fixed compact height" is preserved as a
number and not as an approximation.

### `LogDrawer`

```dart
Align(
  alignment: Alignment.bottomCenter,
  child: FractionallySizedBox(
    widthFactor: 1,
    heightFactor: state.logDrawerExtent == LogDrawerExtent.full ? 1.0 : 0.45,
    child: ColoredBox(color: const Color(0xFF15181F), child: … ),
  ),
)
```

`0.45` is the half fraction — the middle of the contract's 40–50% band.

**Not `Positioned.fill`.** A `Positioned` must be a direct child of a `Stack`,
and `LogDrawer` is a widget that *returns* its root rather than being one, so
`Positioned.fill` would throw. A non-positioned `Stack` child is laid out under
loose constraints, `Align` with null factors expands to the bounded maximum, and
`FractionallySizedBox` then takes the full width and the chosen fraction of the
height, anchored to the bottom. `_DeathOverlay` (`game_screen.dart:714`) is the
existing precedent for a non-positioned overlay child.

Contents, in the mock's panel composition:

1. the handle: a 20-logical-pixel row with the same centred pill, keyed
   `logHandleKey`, `GestureDetector` dispatching `LogDrawerHandlePulled` so
   half → full → peek;
2. a title row: `Text('MESSAGE LOG')` in `0xFFE6EAF0` monospace, `Spacer()`, and
   `IconButton(key: logCloseKey, icon: Icon(Icons.close), tooltip: 'Close the message log', onPressed: () => bloc.add(const LogDrawerClosed()))`;
3. `Expanded` holding a `Stack`: the list, and — when
   `!state.logFollowing && state.logUnread > 0` — a
   `Positioned(right: 12, bottom: 12, child: FilledButton(key: logUnreadKey, child: Text('↓ ${state.logUnread} new'), onPressed: …))`.
   The affordance dispatches `LogFollowResumed` and jumps the controller to
   `maxScrollExtent`. It shows the number, never a dot.

**The title is `MESSAGE LOG`, not the mock's `COMBAT LOG`.** The mock is the
authority for composition — the pill, the title row, the `✕` in the corner — but
ubiquitous language is binding on the words, and this log is not combat-scoped:
it carries road, town, save, gather and depth lines. The codebase's own name for
it is the message log (`event_messages.dart:3`, `main.dart:572`, `_MessageLog`).
Capitals are the mock's typographic treatment and are kept.

### The list and the follow boundary

The drawer's list is **oldest-first and not reversed**, unlike the peek. This is
the decision that makes "new lines accumulate without yanking the viewport" true
rather than approximately true: in an oldest-first list, items are laid out from
offset zero and an append lands beyond the far edge, so every offset the reader
is parked at keeps showing the same words. A `reverse: true` list anchors the
newest end at offset zero, so each append would push the reader's content away
by the height of the new line — the exact yank the contract forbids.

`LogDrawer` is a `StatefulWidget` owning a `ScrollController`:

- "at the newest entry" is
  `position.maxScrollExtent - position.pixels <= _followTolerance`, with
  `static const double _followTolerance = 8`;
- a scroll that leaves that window while `widget.state.logFollowing` dispatches
  `LogFollowBroken`; one that re-enters it while `!widget.state.logFollowing`
  dispatches `LogFollowResumed`. Criterion 6 is therefore the same code path as
  the affordance, not a second one;
- after any build in which `widget.state.logFollowing` is true **and** either the
  log grew or follow just turned on, a post-frame callback jumps to
  `maxScrollExtent`, guarded by `_controller.hasClients`;
- a log shorter than the viewport has `maxScrollExtent == 0` and
  `pixels == 0`, so it is always "at newest", follow never breaks, and the jump
  is a no-op. That is criterion 9's empty and one-line cases, satisfied by the
  same arithmetic rather than by a special case.

Each row:

```dart
Semantics(
  label: '${line.category.word}. ${line.sentence}',
  child: ExcludeSemantics(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 20, child: Text(line.category.mark, style: rowStyle)),
        Expanded(child: Text(line.sentence, style: rowStyle)),
      ],
    ),
  ),
)
```

`rowStyle` is monospace 13 with
`Color(index == log.length - 1 ? 0xFFE6EAF0 : 0xFF8A919E)` — the same
value-only newest/older contrast the peek keeps, now with the newest line at the
end of an oldest-first list.

## Locked decision 6 — the peek reorder

`game_screen.dart:120-121` today reads:

```dart
_Controls(state: state),
_MessageLog(log: state.log),
```

and becomes:

```dart
LogPeek(key: logPeekKey, state: state, bloc: bloc),
_Controls(key: controlsKey, state: state),
```

**No existing test asserts the old order.** `_MessageLog` and `_Controls` are
private and unkeyed and no widget test references either; the order is
unasserted today. Task 03 adds the first assertion of it. Nothing to migrate.

## Locked decision 7 — the glyph column

Each category's `mark` is one BMP character drawn in the same colour as its
sentence, in the same monospace family. Nothing is imported: the app already
ships non-hue marks as text — `✳ ✚ ⛒` for spell schools
(`packages/core/lib/src/magic/spell.dart:94-99`) and superscript ordinals in log
sentences from Unit 4 — so this is the existing vocabulary, not an asset
pipeline.

| Category | Mark | Shape |
| --- | --- | --- |
| `struck` | `←` | left arrow — a blow arriving |
| `hit` | `→` | right arrow — a blow going out |
| `died` | `†` | dagger |
| `noticed` | `◎` | ringed circle — an opened eye |
| `moved` | `⇅` | vertical double arrow — a depth, a step |
| `refused` | `✕` | saltire |
| `item` | `■` | filled square |
| `raised` | `▲` | filled triangle |
| `gathered` | `◆` | filled diamond |
| `reported` | `§` | section mark — a note about the session |

Hue carries nothing at all here: every mark is drawn in the row's own text
colour, so the column reads identically in greyscale. The distinctions are
orientation (`←` `→` `⇅`), stroke (`†` `✕` `§`), and silhouette
(`◎` `■` `▲` `◆`),
which is shape and position exactly as AGENTS.md requires. The category is also
a word in every row's accessibility label, so a screen reader hears
"struck. The ghoul claws you for 3."

The newest/older value contrast survives because the mark takes its row's colour:
the newest row's mark is `0xFFE6EAF0` and every older mark is `0xFF8A919E`, the
same two values the peek has always used.

## Locked decision 8 — death interaction

Two mechanisms, both provable, neither relying on z-order:

1. **Collapse is a constructor invariant.** `game.isGameOver` forces
   `logDrawerExtent` to `peek` and follow to on in every `GameViewState` ever
   built (decision 4). A lethal step therefore collapses the drawer no matter
   which handler produced the state, and the assertion is a bloc assertion:
   `expect(bloc.state.logDrawerExtent, LogDrawerExtent.peek)`.
2. **The handle is inert by its own guard.** `_onLogDrawerHandlePulled` returns
   without emitting when `state.game.isGameOver`, mirroring `_onWaitPressed`
   (`:789-792`) and `_onTileTapped` (`:590`); and `LogPeek` passes
   `onTap: null` with `Semantics(enabled: false)` at game-over, so the handle is
   inert to a tap and to a screen reader, not merely covered.

Because the drawer is collapsed, `LogDrawer` is not in the tree at all when
`_DeathOverlay` is, so no drawer chrome can sit over the overlay's control. The
overlay stays the last `Stack` child and keeps its single working button. A
widget test taps that button with a log seeded and the drawer having been open
before the lethal step.

## Locked decision 9 — the test migration

The precise scope, measured at `864aa6e`:

| File | `.log` sites | Need editing |
| --- | --- | --- |
| `test/game_bloc_test.dart` | 75 | the sentence assertions only |
| `test/battle_view_test.dart` | 14 | 4 (`:300, 673, 820, 843`) |
| `test/world_bloc_test.dart` | 11 | 0 — this is `WorldViewState.log` |
| `test/game/dungeon_scene_test.dart` | 7 | 0 |
| `test/game/armed_targets_test.dart` | 4 | 0 |
| `test/widget/world_screen_test.dart` | 4 | 1 (`:802`) |
| `test/widget/back_guard_test.dart` | 3 | 2 (`:73`, and `:87/:100` need none) |
| `test/game/engine_boundary_test.dart` | 1 | 1 (`:92`) |

Two facts collapse most of the churn:

- **`log: const []` needs no edit.** Downward inference makes `const []` a
  `const <LogLine>[]` in a `List<LogLine>` parameter position. Every
  construction site in `dungeon_scene_test.dart`, `armed_targets_test.dart`,
  `world_screen_test.dart:750` and the `GameViewState(...)` fixtures in
  `game_bloc_test.dart` compiles untouched.
- **`log: state.log`, `log: initial.log`, `expect(x.log, same(y.log))`,
  `log.length` and `isEmpty` need no edit.** They are about the list, not its
  elements.

What is left is the sentence assertions. Add one test-support projection:

```dart
// packages/app/test/support/log_sentences.dart
import 'package:residuum_app/game/game_bloc.dart';

List<String> logSentences(GameViewState state) => [
  for (final line in state.log) line.sentence,
];
```

and rewrite each sentence assertion mechanically: `bloc.state.log` →
`logSentences(bloc.state)`, `.having((s) => s.log, 'log', …)` →
`.having(logSentences, 'log', …)`. Every string literal stays where it is.

This is a test-local projection, not a compatibility accessor: production has no
`List<String>` view of the log, `GameViewState` grows no sentence getter, and
nothing in `lib/` can reach it. It exists because the surviving assertions are
about words rather than categories, and rewriting fifty of them by hand is the
one way a sentence could silently change.

**It is not `sonic`-suitable and it is not its own task.** The element-type
change breaks compilation across production and tests in one edit; splitting the
migration out would require either a shim the contract forbids or a
non-compiling handoff state. It belongs to task 01, whose Green is the whole
tree compiling with no sentence changed.

**What proves no sentence changed.** From the repository root, after task 01:

```sh
for f in packages/app/test/game_bloc_test.dart \
         packages/app/test/battle_view_test.dart \
         packages/app/test/game/engine_boundary_test.dart \
         packages/app/test/widget/back_guard_test.dart \
         packages/app/test/widget/world_screen_test.dart; do
  diff <(git show 864aa6e:$f | grep -oE "'[^']*'" | sort) \
       <(grep -oE "'[^']*'" $f | sort) | grep '^<' && echo "LITERAL REMOVED IN $f"
done
```

Expected output: nothing. Any `<` line is a single-quoted literal that existed
at `864aa6e` and does not exist now, which is either a changed sentence or a
removed import and must be justified line by line before the task is green.

## Locked decision 10 — empty and one-line logs

A road encounter builds a fresh `GameBloc` whose log holds exactly
`[roadOpeningLog]` (`main.dart:421`); `GameBloc(game: …)` with no `log` starts
empty. Both must read as deliberate.

- The peek's fixed 104-pixel container and its handle pill render identically at
  zero lines and at one: the `ListView.builder` simply builds nothing, the box
  keeps its colour and its handle, and nothing collapses or jumps. It looks like
  an empty log rather than a broken box because the handle and the panel ground
  are always drawn.
- The drawer at half and at full with zero or one line has
  `maxScrollExtent == 0`, so the follow arithmetic reports "at newest", the
  post-frame jump is a no-op, `↓ N new` can never appear, and no unbounded
  constraint reaches the `ListView` because it is inside `Expanded`.
- Proof is a widget test that pumps a fresh road-encounter-shaped `GameBloc`
  with an empty log and with a one-line log at the phone surface, opens the
  drawer to half and to full, and asserts `tester.takeException()` is null at
  each step with the handle and the panel present.

## Migrations and removals

- add `lib/game/log_line.dart` (`LogCategory`, `LogLine`, `LogDrawerExtent`);
- add `lib/game/log_drawer.dart` (`LogPeek`, `LogDrawer`, the five keys);
- update `lib/game/event_messages.dart`, `lib/game/game_bloc.dart`,
  `lib/game/game_screen.dart`, `lib/main.dart`;
- delete `_MessageLog` from `game_screen.dart`; move `_Controls` above nothing
  and `LogPeek` above it;
- change `roadOpeningLog` and `bottomOfTheDelve` from `String` to `LogLine`;
  no aliased `String` form remains;
- add `test/support/log_sentences.dart`, `test/game/log_line_test.dart`,
  `test/game/log_drawer_state_test.dart`, `test/widget/log_drawer_test.dart`;
- migrate the sentence assertions listed in decision 9, and extend
  `test/widget/boot_wiring_test.dart:50-70` with the `reported` value
  assertion that proves the app-injected category through the real boot path.

Forbidden in this unit: any `List<String>` accessor or adapter on
`GameViewState`; a parallel category list; a `copyWith`; a second switch over
`GameEvent`; a category derived from sentence text; any `packages/core`,
`packages/content`, save, autosaver, balance, generator or world change; a
tap-to-actor handler on a log row; severity, timestamps, filters, search or
category toggles; an unread badge on the collapsed peek; an `assets:` block;
any HUD chrome change beyond moving the peek above the controls; an animation
controller or scheduler for the drawer.

## Integrated verification ownership

Task briefs name exact focused Red/Green and static commands. After all three
tasks, Main runs from `packages/app`:

```sh
dart format --set-exit-if-changed --output=none \
  lib/game/log_line.dart lib/game/log_drawer.dart \
  lib/game/event_messages.dart lib/game/game_bloc.dart \
  lib/game/game_screen.dart lib/main.dart \
  test/support/log_sentences.dart test/game/log_line_test.dart \
  test/game/log_drawer_state_test.dart test/widget/log_drawer_test.dart \
  test/game_bloc_test.dart test/battle_view_test.dart \
  test/game/engine_boundary_test.dart test/widget/back_guard_test.dart \
  test/widget/world_screen_test.dart test/widget/boot_wiring_test.dart
flutter analyze
flutter test
```

Then Main verifies that `git status` shows changes only under `packages/app`,
runs the no-literal-removed check from decision 9, performs one integrated
acceptance review against `CONTRACT.md`, and runs the criterion 12 phone AVD
session in colour and greyscale on an emulator id from `adb devices`
(`flutter run -d <emulator-id>`; never an attached user phone). Device scenes are
sourced by probing `buildFloor(depth, worldSeed:, visit: 1)` and
`startRoadEncounter`/`roadSeed` for a world and day that already contain the
required cast, then playing it — never by adding a fixture or bending
generation. Criterion 12 is the architect's gate and no executor task owns it.

## Escalation boundary

Stop the affected task and return to the architect if:

- a `GameEvent` variant produces a sentence for which no category in decision 2
  is honest, or a new variant has appeared at the `describeEvent` switch;
- an app injection site not listed in decision 2 is found producing a log line;
- the constructor invariant in decision 4 cannot hold because some path needs a
  game-over state with an open drawer, or a peek with follow off;
- an append path cannot report how many lines it appended without consulting
  `log.length`;
- `_reusesProjection` turns out to be sensitive to a field the drawer changes,
  so an extent change would re-project the Flame scene;
- the overlay cannot reach half/full without reflowing the `Column`, or the
  collapsed composition is not identical to the pre-expansion one;
- a locked mark renders as a missing glyph in the widget test's font, or the
  oldest-first list cannot hold a reader's offset across an append;
- the migration cannot be completed without changing an asserted sentence, or
  the no-literal-removed check reports a removal that is not a moved import;
- any required behavior would need a `core`, `content`, save, or save-version
  change.

Private helper names, padding and spacing values other than the locked `104`,
`0.45`, `1.0` and `8`, pill dimensions, the exact spelling of the boolean
normalization in the constructor initializer list, and test fixture placement are
executor discretion, provided the locked heights, fractions, colours, keys,
public interfaces, category mapping and proofs are preserved.

## Plan quality gate

- **COR — PASS.** Category provenance is fixed at the one switch that knows the
  variant, with every arm and every injection site assigned; the two lines the
  interface speaks about itself rather than about the world are `reported`
  rather than borrowing a world-event mark. Exhaustiveness is a compile error
  for variants and, because the members have two producers, two tests that are
  total over `LogCategory.values` between them. Follow/drawer ownership is
  split at a named boundary — the bloc counts, the widget scrolls — and the
  unread count only ever sees the size of one append. Game-over collapse, peek
  follow-consistency, and zero-unread-while-following are constructor
  invariants, not handler discipline. The overlay is a `Stack` sibling so the
  column never reflows and `_reusesProjection` stays true. `pan` is explicitly
  carried by the drawer handlers because criterion 7 names it.
- **TTC — PASS.** Every contract criterion maps to a named proof: 1 and 4 to
  `log_line_test.dart` plus the drawer widget test; 2, 3, 9 to the composition
  and rect-identity widget tests; 5, 6, 7 to `log_drawer_state_test.dart` and the
  scroll widget test; 8 to the bloc invariant plus the overlay reachability test;
  10 to the "only `packages/app` changed" check; 11 to Main's final gate. Each
  brief states the expected Red symptom, and the migration carries its own
  negative proof that no asserted sentence changed.
- **CRF — PASS.** One type owns a line, one enum owns categories and their marks
  and words, one switch owns the mapping, one helper owns the count, one widget
  owns scroll position. `_MessageLog` is deleted rather than wrapped; the two
  public sentence consts change type rather than growing a `String` twin; no
  `copyWith`, no adapter, no second switch, no animation scheduler, no generic
  "log service" is planned. The one convenience introduced — `logSentences` —
  lives in `test/support` and cannot be reached from `lib/`.
- **SEC — SKIP (no external trust boundary).** Unit 5 adds no network,
  persistence, deserialization, privilege, or untrusted-input surface; it moves
  app-owned view state that is documented never to be written down
  (`main.dart:572`). The `SaveNotice` sentence already reaching the log is
  unchanged in content and is not parsed by anything this unit adds; the
  `reported` category is chosen at the injection site and never from the notice
  variant, so a sentence's words still decide nothing.

Residual risks, deliberately left to evidence:

1. **Mark font coverage — discharged, with one correction.** The criterion 12
   device session on `emulator-5554` measured all ten marks at 13px monospace.
   Nine rendered monochrome. `↕` (U+2195) did not: Android resolved it through
   the colour emoji font, painting a blue-cyan box at saturation 0.51
   (`rgb(65,117,134)`) that ignored the row's `style.color`, so hue carried part
   of the category and the mark lost the newest/older value contrast. Per this
   plan's own escalation rule the codepoint was swapped, not the shape
   vocabulary: `moved` is now `⇅` (U+21C5, ARROWS UP AND DOWN), which renders as
   a real monochrome two-headed vertical arrow. Re-measured after the fix, the
   mark column contains no coloured pixel and the mark takes its row's colour
   exactly — older `rgb(138,145,158)`, newest `rgb(230,234,240)`. U+2B65 was
   also probed and is tofu on this target; avoid it. A widget test cannot catch
   this class of defect, because the test font resolves every codepoint and
   `find.text` matches regardless of emoji fallback — the device gate owns it.
2. **`0.45` at half on a tall phone.** The band is 40–50% and the fraction is
   inside it, but whether half reads as "enough log, still my map" is a device
   judgement.
3. **Follow tolerance of 8 logical pixels** is chosen to survive scroll jitter
   without feeling sticky; only a device pass can confirm it does not break
   follow on a light touch.
