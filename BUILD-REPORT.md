# Build report — unit `m3-heroes`, story M3H "Heroes"

Every identifier, count and line of output below is pasted from a command run
in this session. Nothing here is typed from memory.

## 1. Where the work is

```
$ git rev-parse --show-toplevel
/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/.worktrees/m3-heroes

$ git log --oneline main..HEAD
20e3eb3 feat: a Heroes door, and the end of Abandon Hero
6095d34 feat: a roster of heroes, read off the save document
2b2cf75 feat: the four document edits a roster makes
7e9d1c8 test: the autosaver is watching before the first transaction
70ba2ef test: the crawl route declines the platform's back button
484a96e fix: closing the autosaver stops waiting on cancellations it does not need
afad8ab docs: widget tests where a bloc test cannot look (D31)
700b92a feat: the merchant sells back what you sold this visit
228c3cc feat: the merchant's memory of a visit survives a relaunch
447f869 feat: the shelf remembers what was bought, and the counter what was sold
7f34ced feat: a hero entry remembers the merchant's visit
0744a08 test: characterize the merchant's memory at base (C1, C2, C3)
```

Base `f758c3f`. Nothing under `docs/epic/` is committed; screenshots for the AVD
run are left there, outside git, at
`/var/home/dhemas/Development/Projects/fiatcode/residuum-rpg/docs/epic/m3-heroes-shots/`.

## 2. The three suites against the baseline

**The baseline was re-measured in this worktree before the first commit**, at
`f758c3f`, and it matched the architect's fresh 2026-08-21 measurement exactly:

```
core:    00:02 +395: All tests passed!
content: 00:05 +197: All tests passed!
app:     00:07 +176: All tests passed!
```

395 + 197 + 176 = **768**, as stated in the spec.

At `20e3eb3`:

```
core:    00:03 +395: All tests passed!
content: 00:07 +212: All tests passed!
app:     00:06 +222: All tests passed!
```

395 + 212 + 222 = **829**. Net +61 (+15 content, +46 app), after the eight
deletions listed in section 13.

This file replaces M3S's build report, which stays in git history at `f758c3f`.

## 3. C1 and C2 quoted at base

Both were written against UNMODIFIED code and both passed there. Quoted from
commit `0744a08`.

**C1 — `packages/app/test/town_bloc_test.dart`**, group
`characterization: the sale that cannot be undone (C1)`:

```dart
test('a sold item is nowhere the hero can reach afterwards', () async {
  // arrange
  final bloc = TownBloc(profile: _rich());
  final paid = sellPriceOf(_cap('held-1'));

  // act
  bloc.add(const SellPressed('held-1'));
  final after = await bloc.stream.first;

  // assert
  expect(after.profile.gold, 500 + paid);
  expect(after.profile.inventory, isEmpty);
  expect(after.profile.bank, isEmpty);
  expect(after.stock.map((item) => item.id), isNot(contains('held-1')));
  await bloc.close();
});
```

Deleted in `447f869`. **Argument:** C1 pinned that a sold item was nowhere the
hero could reach. `selling puts the item on the counter to be bought back` is
the assertion that replaces it, and the two cannot both be true — the item is
now reachable, at the price it was paid, until the visit ends. C1's other half,
that the gold arrives, is still covered by `selling turns an item into coins at
the selling price`, which stands unchanged.

**C2 — `packages/content/test/save/save_codec_test.dart`**, group
`characterization: a hero entry has no visit state (C2)`:

```dart
test('the entry today is label, profile and run, and decodes', () {
  // arrange
  final written = _asMap(_save(newProfile(worldSeed: 5)));

  // act
  final keys = _heroBlock(written).keys.toList();

  // assert
  expect(keys, ['label', 'profile', 'run']);
  expect(decodeSave(jsonEncode(written)), isA<SaveDocument>());
});
```

Deleted in `7f34ced`. **Argument:** C2 pinned that a hero entry was exactly
`label, profile, run`. That is the shape the format commit replaces, and the
rule replacing it — a v1 entry without the block is a structured failure — is
the opposite assertion. One format, one shape. Superseded by `a hero entry
missing its merchant block is refused by name`.

## 4. The base reproduction of the resurrection defect, and what it actually does

C3, written against unmodified code and **green there**, walking the real
relaunch path (`TownBloc` → `Autosaver` → `SaveStore` → `bootFrom` → new
`TownBloc`). From `0744a08`:

```dart
// assert
expect(relaunched.profile.inventory.where((i) => i.id == offered.id),
    hasLength(1));
expect(resurrected, contains(offered.id));
expect(bought.profile.inventory.where((i) => i.id == offered.id),
    hasLength(2));
expect(sold.profile.gold, bought.profile.gold + sellPriceOf(offered));
expect(sold.profile.inventory.where((i) => i.id == offered.id), isEmpty);
```

All five assertions held at base. In words: the bought item was on the shelf
again after the relaunch, buying it a second time put **two items with one id**
in the pack, and then selling once **paid for one and removed both**.

**This is worse than the recon predicted, and it is a correction to the ledger.**
The recon says "every by-id operation acts on the first match". It does not.
`packages/core/lib/src/town/town.dart:201-211`:

```dart
Item? _find(List<Item> items, String itemId) {
  for (final item in items) {
    if (item.id == itemId) return item;
  }
  return null;
}

List<Item> _without(List<Item> items, String itemId) => [
  for (final item in items)
    if (item.id != itemId) item,
];
```

`_find` returns the first match and prices it; `_without` removes **every**
match. So a duplicated id is not an item being misidentified — it is an item
being silently destroyed, at the price of one. `depositItem` has the same pair
of calls, so banking one of the two would have destroyed the other as well.

Deleted in `228c3cc`. **Argument:** keeping C3 would be keeping a test that
asserts the defect is still present. Replaced by `a purchase is still gone from
the shelf after a relaunch`, which walks the same path and asserts the opposite:
the bought id is absent from the rebuilt shelf and the pack holds exactly one.

## 5. The mutation table, both halves

Every row was applied to **committed** code, run, and reverted; the tree was
verified clean between rows. Rows are the spec's 1–10, plus six extensions (5b, 11, 12, 13, 14, 16).

| # | Mutation | Went red | Stayed green (control) |
|---|---|---|---|
| 1 | buy-back charges `buyPriceOf` | `buying back costs exactly what the sale paid`, `buying back is cheaper than buying the same thing off the shelf` (`00:01 +40 -2`) | content `test/economy_test.dart` `00:00 +14: All tests passed!` |
| 2 | `bought` not persisted (stock from tables alone) | `a purchase is still gone from the shelf after a relaunch` (`00:01 +15 -1`) | `buying writes the purchase into the visit` — the spec's named in-session control — green. (`a hero who already bought does not see it on the shelf` also reddened; it is a second test of this same mutation, not the named control.) |
| 3 | the visit bump keeps `sold` | `coming home clears what the merchant remembered`, `the visit is cleared on disk when the run ends` (`00:01 +56 -2`) | `buying back costs exactly what the sale paid` (mid-visit buy-back) green |
| 4 | delete skips the confirmation | six roster tests, led by `deleting asks first, and a refusal answers nothing` (`00:02 +8 -6`) | content `test/save/roster_test.dart` `00:00 +24: All tests passed!` |
| 5a | `without()` returns an empty roster instead of null | content `deleting the only hero is refused, so no roster is ever empty` (`+23 -1`); app `deleting the only hero is refused rather than written` (`+16 -1`) | `deleting a hero who is not being played keeps the played one` green; **and the roster session widget test stayed green — see the note below** |
| 5b (extension) | the roster forgets which delete is the last one (`heroes.length == 1` → `false`) | `deleting the only hero flows into creating the next`, `backing out of the name leaves the only hero alone` (`+12 -2`), and `the last hero deleted is replaced, never removed` (`+7 -1`) | content roster rules `00:00 +24: All tests passed!` |
| 6 | switch edits `active` in memory but never saves | `switching lands on the other hero, crawl and visit and all`, `switching lands on the other hero and writes it down`, `switching to a suspended hero lands in their crawl` (`00:03 +22 -3`) | content `playing another hero moves nothing but which one is played` green |
| 7 | crawl route `canPop` flipped to true (M3S row 22) | `declines the pop and says where the way out is`, `says nothing over a death overlay that already says what to do` (`00:01 +1 -2`) | `test/game_bloc_test.dart` `00:02 +55: All tests passed!` |
| 8 | `didPop` guard dropped (M3S row 24) | `a pop the app asked for itself says nothing` (`00:01 +2 -1`) | `test/game_bloc_test.dart` `00:02 +55: All tests passed!` including `is refused, and the log says where the way out is` |
| 9 | autosaver never attached (the M3S boot defect, reintroduced) | `the first transaction in town is written down` (`00:02 +2 -1`) | content codec suites `00:00 +49: All tests passed!`; app bloc suites `00:01 +58: All tests passed!` |
| 10 | CONTROL — no mutation | — | `core 395`, `content 212`, `app 222`, all green; survivability `24/40 won (60.0%), stalled 0` |
| 11 (extension) | the roster reads the boot document instead of the live one | `switching away carries what the hero spent since booting` (`00:02 +7 -1`) | the other seven session tests green |
| 12 (extension) | a settled transaction drops the visit (`merchant ?? MerchantVisit.none`) | `a transaction with nothing to do with the shop carries the visit`, `a buy-back the purse cannot cover leaves it on the counter` (`00:01 +40 -2`) | the rest of the town bloc suite green |
| 13 (extension) | the decoder defaults a missing `merchant` block instead of refusing | `a hero entry missing its merchant block is refused by name` (`00:00 +23 -1`) | the rest of the content roster suite green |
| 14 (extension) | the rebuild does not wait for the pending write (`await _saver.close()` dropped from `_openRoster`) | **NOTHING. `00:06 +222: All tests passed!`** — reported as a gap, not a pass; see section 10 | — |
| 16 (extension) | deleting the played hero keeps naming them as `active` | content `deleting the hero being played moves play to the first one left` (`+23 -1`); app `deleting the played hero lands on the first one left` and `deleting the hero being played lands on the one left` (`00:04 +23 -2`) | the rest of both suites green |

**Rows 7, 8 and 9 are red.** Each was invisible to 768 tests before D31, and each
is now caught by exactly the widget test the exception was granted for.

**Row 5a's honest result, reported rather than smoothed over.** The spec expects
the "never-zero widget/bloc test" to redden. The content and bloc tests did. The
roster **session** widget test did not, and that is correct rather than a hole:
the never-zero rule has two independent guards, and 5a only breaks the document
one. The roster's own flow routes the last delete into creation before
`without()` is ever called, so the widget test never reaches the mutated line.
Row 5b is the mutation that breaks the other guard, and it reddens the session
test. I did not weaken either test to make one row cover both, because two
guards genuinely need two rows.

## 6. Survivability

Measured at `20e3eb3`:

```
survivability: 24/40 won (60.0%), stalled 0, died at 1:1 2:9 3:6 5:24
greedy build: 24/40 won; fleetfoot-first build: 7/40 won
00:07 +5: All tests passed!
```

Exactly 24/40, stalled 0 — identical to the baseline line measured at `f758c3f`
before any commit.

## 7. Analyzer, formatter, and the scope of the diff

```
$ flutter analyze
Analyzing m3-heroes...
No issues found! (ran in 3.1s)

$ dart format --set-exit-if-changed .
Formatted 123 files (0 changed) in 0.25 seconds.

$ git diff main --stat -- packages/core
(no output — core is untouched)

$ git diff main --stat -- packages/content
 packages/content/lib/content.dart                  |   1 +
 packages/content/lib/src/save/merchant_visit.dart  |  70 ++++++++
 packages/content/lib/src/save/save_codec.dart      |  32 ++++
 packages/content/lib/src/save/save_read.dart       |  94 +++++++++--
 packages/content/test/save/golden_save_test.dart   |  69 ++++----
 .../content/test/save/merchant_visit_test.dart     |  73 +++++++++
 packages/content/test/save/roster_test.dart        | 179 ++++++++++++++++++++-
 7 files changed, 476 insertions(+), 42 deletions(-)

$ git diff main --stat -- '*pubspec*'
(no output — no dependency added or moved; flutter_test was already a
dev_dependency of packages/app)
```

Every content file touched is a save-feature file. No economy, bestiary, table,
price or xp file appears.

The CLAUDE.md diff is the Testing amendment and nothing else:

```diff
-- **app:** BLoC-level tests only (events → states). No widget or page tests; verify UI
-  manually on device.
+- **app:** BLoC-level tests (events → states) are the default. Widget tests are
+  permitted wherever a bloc test cannot observe the behavior — route guards, boot
+  wiring, navigation, dialogs. No golden-image tests; look and feel are still
+  verified manually on device.
```

## 8. Hygiene greps

```
$ grep -rn "dart:io\|DateTime" packages/content/lib packages/core/lib
none

$ grep -rn "DateTime.now\|Random(" packages/app/lib packages/content/lib packages/core/lib
packages/app/lib/save/boot.dart:142:int rollWorldSeedFromClock() => DateTime.now().millisecondsSinceEpoch;

$ grep -rn "^\s*//[^/]" packages/app/lib packages/content/lib packages/core/lib | grep -v "// ignore"
none
```

**The clock-roll sites, enumerated.** Exactly one, unchanged from M3S:
`rollWorldSeedFromClock` in `packages/app/lib/save/boot.dart`. It is now read
from three call sites instead of one — `createHero`, `replaceOnlyHero`, and the
existing `bootFrom` — all of them in `main.dart`'s roster handler or boot. No new
site was created; the roll is passed in as a function everywhere, so every one of
those functions is deterministic in a test.

## 9. AVD acceptance, screenshot-paired

Pinned to `emulator-5554` throughout. No physical device was attached
(`adb devices` listed only `emulator-5554 device`). Debug APK installed with
`adb -s emulator-5554 install -r`, storage cleared first with `pm clear`, killed
between relaunches with `am force-stop`, and every tap sent with
`adb -s emulator-5554 shell input tap`. Screenshots in
`docs/epic/m3-heroes-shots/`.

| Definition-of-done item | Shot | What it shows |
|---|---|---|
| Create a second named hero | `02`–`06` | Prefill `Hero 2`, typed `Ilse`, roster shows `Hero 1` and `Ilse playing` |
| Switch to another hero | `07`, `08` | Tapped `Hero 1`'s row; roster then reads `Hero 1 playing` |
| Suspend and resume | `09`, `10` | Entered the dungeon, force-stopped, relaunched into the crawl with `The crawl resumes.` |
| Switch to a suspended hero and land in their crawl | `11`, `13` | Roster reads `Hero 1 … below (depth 1)`; tapping the row lands in the crawl |
| The delete confirmation names the crawl | `12` | "The crawl they are standing in, depth 1 down, dies with them." |
| Delete a hero | `21`, `22` | Deleted the suspended non-active hero; session rebuilt onto Ilse with her 12 gold intact |
| Delete the active hero | `24`, `25` | `Delete Bram?` with no crawl clause; after confirming, play is on Ilse and the document holds only her |
| Delete down to the last hero and get the creation flow | `26`, `27`, `28` | Dialog adds "A new hero begins in a new world."; confirming opens the naming dialog; the document then holds exactly one hero on a new world seed |
| Sell an item, kill, relaunch, buy it back at the paid price | `15`, `16`, `17` | Sold a potion for 10; after force-stop and relaunch the `SOLD THIS VISIT` row still offers `Buy back 10`; buying back moved gold 10 → 0 and returned the potion |
| Buy an item, relaunch, confirm it stays gone from stock | `19`, `20` | Bought `Common Iron Greaves` for 8; after relaunch the shelf shows five items instead of six, the greaves are in the pack, and both sold potions are still buy-backable |
| Greyscale check | `g1`, `g2` | Roster and merchant, `-colorspace Gray` |

The document on disk was read back at each step with
`adb -s emulator-5554 shell run-as com.example.residuum_app cat …/app_flutter/save.json`.
The pasted state after buying the greaves:

```
label: Ilse gold: 12
merchant.bought: ['market-0-gear-3']
merchant.sold ids: ['kit-3', 'kit-2']
inventory: [('market-0-gear-3', 'iron-greaves')]
```

and after the last-hero replacement:

```
active: hero-1787314819497
heroes: [('hero-1787314819497', 'Hero 2', 0, '1787314819497')]
count: 1
```

**Greyscale verdict.** Both screens read. On the roster, the hero being played
is the word `playing`, and where each hero stands is the clause `in town` or
`below (depth 1)`. On the merchant, the three lists are told apart by their
headings and their fixed order, the rarity marking is a glyph (`·`, `+`), and a
price the purse cannot cover is a dim button, which survives the conversion as
value contrast rather than hue.

**One setup step was not ordinary play, and it matters.** To reach "a hero is
suspended below while another is being played" I entered the dungeon with Hero 1,
force-stopped the app, and then changed **one field** of the real save file —
`active` — from Hero 1's id to Ilse's, before relaunching. I did that because
**that state cannot currently be created by playing.** A crawl can only be left
at the stairs or by dying, both of which end the run; the crawl route declines
the back button by design, and the roster is only reachable from the town, which
is underneath the crawl. So the hero in a crawl is always the active hero, and
switching *away* from a suspended hero has no in-game path.

The code that handles the state is correct, and the switch-into-crawl path is
covered by a widget test with an authored document plus the device run above. But
the feature is currently unreachable by a player, and that is a finding for the
ledger rather than a defect in this unit: it becomes reachable the moment
anything lets a player leave a crawl suspended, and it should be listed as a
follow-up ("a way out of a crawl that suspends rather than ends it") beside the
rename and ordering follow-ups.

## 10. What the tests cannot prove

- **Look and feel.** The amendment forbids golden images, so nothing asserts
  layout, spacing, or that a row is legible at a real font scale. The
  screenshots above are the evidence, and they are read by a person.
- **A real disk.** Every save test uses `MemorySaveFiles`. Partial writes, a
  full disk, a kill between the two renames — the store's own reasoning about
  those is tested against a map, not against a file system. The AVD run
  exercised the real `IoSaveFiles` path but only in the happy case.
- **The write race the spec's hazard names.** `_openRoster` awaits
  `_saver.close()` before the document is edited, so no queued write can land
  after. I mutated exactly that — dropped the await — and ran the whole app
  suite: `00:06 +222: All tests passed!`. **Nothing in this unit protects that
  await.** With a map for a disk every write completes effectively instantly, so
  no test forces the interleaving that would lose a switch. It is recorded as
  extension row 14 with a green result on purpose: a mutation row that reddens
  nothing is the most useful row in the table, because it names the one thing the
  suite does not hold. Making it redden needs a store that can be told to stall a
  write mid-flight, which is a `MemorySaveFiles` capability this unit did not
  need for anything else.
- **The clock.** `rollWorldSeedFromClock` is called with the real clock only in
  `main`. Every test injects a fixed roll, so the one unseeded line in the game
  is verified by the device run and by reading it, not by a test.
- **Two heroes created inside one millisecond.** `unusedHeroIdFrom` is tested
  directly and by `a created hero never takes an id already in the roster`, but
  a real double-tap fast enough to collide has never been performed.
- **Concurrency between sessions.** Nothing tests two `Autosaver`s writing at
  once, which is what a generation bump briefly creates. The ordering argument
  is in the dartdoc and rests on `close()` being awaited first.
- **That the sold list is the right length forever.** Nothing bounds `sold`. A
  hero who sells twenty items this visit gets a twenty-row section. It clears on
  the next visit, so it cannot grow without bound, but no test says the screen
  stays usable at that size.

## 11. Every spec claim I checked and found wrong

1. **The recon's mechanics for the duplicated id.** "Every by-id operation acts
   on the first match" — measured false. `_find` prices the first match while
   `_without` removes every match, so one sale pays for one item and destroys
   both. Evidence: C3 in `0744a08`, and `town.dart:201-211` quoted in section 4.
2. **The spec's name for the visit-state block.** The spec's `visit` would have
   collided with `profile.visit` inside the same hero entry. Renamed `merchant`,
   pre-declared, approved as a spec correction.
3. **"Deleting or switching away must not race a pending autosaver write —
   await the store like `_abandon` does today."** The precedent is right about
   *what* to await and was wrong about *how*, and following it literally would
   have made the unit's own acceptance untestable. `Autosaver.close()` awaited
   each `StreamSubscription.cancel()`; a bloc completes a cancellation on the
   event loop, and a widget test's clock never reaches the event loop, so
   `await _saver.close()` inside a tap handler hangs a widget test forever —
   past its own timeout, because that timer is faked too. Measured: `await
   bloc.close()` and `await Autosaver.close()` both hang a `testWidgets` body;
   `tester.runAsync(() => bloc.close())` returns at once. Fixed in `484a96e` by
   asking for the cancellations without awaiting them and still awaiting the
   queue, which is the whole of what closing has to promise.
4. **"The roster shows data from EVERY hero while blocs exist only for the
   active one — read the document, not the blocs."** True, and incomplete. The
   boot document is *also* wrong to read: it is as old as the launch, so the
   active hero's spent gold and taken wounds would be handed back on the way
   out. The document has to come from the autosaver, which holds the live hero.
   Extension mutation row 11 exists because of this, and it reddens a test.
5. **"Switch/delete rebuild path — the spec says reuse the generation key."**
   Correct, and it needed one thing the spec does not mention: the roster is a
   *pushed route*, so the generation bump does not remove it — bumping the key
   rebuilds the home route's subtree and leaves anything pushed above it
   standing. The roster therefore pops itself with its answer, and the session
   acts after the pop.
6. **The spec's expectation that row 5 reddens a widget test.** Half right; see
   section 5. Two guards, two rows.
7. **The switch-into-crawl feature is unreachable by play.** Section 9. The code
   is right; the state it serves has no in-game route to it yet.

## 12. Which execution phases ran, and which were skipped

Ran: recon reading (spec, recon, build prompt, and every file they name, read in
full); a written plan via the `writing-plans` skill, committed at
`docs/superpowers/plans/2026-08-21-m3h-heroes.md`; pre-declaration of eleven
shape deviations to the architect **before any code**, all approved; strict
test-first execution of eleven commits; the mutation table against committed
code; the AVD acceptance; this report.

**Skipped: per-task reviewer subagents.** The build prompt permits the skip and
asks for the argument, so here it is. Two reasons, one general and one specific
to this unit. The general one is the D9 precedent: the mutation table carries
the adversarial load, and it does it better than a reading reviewer can, because
every row is a claim about behaviour that either reddens a named test or does
not. Fifteen rows ran here; five of them are extensions I added because I
thought the spec's ten missed a hazard, and four of those five reddened tests
that the spec's ten would have left unproven. The specific reason is that the
genuinely new ground in this unit was not logic a reviewer would catch by
reading — it was a test-harness deadlock that only appeared by running the
thing, and no amount of review of a correct-looking `await` would have found it.

Also skipped: the `superpowers:brainstorming` skill, because the design decisions
were already made in ledger entries D28 and D31 and written into the spec; there
was nothing to explore, only shape to pre-declare and argue.

## 13. Every deleted test, with its argument

Eight tests deleted across the unit.

1. **`characterization: the sale that cannot be undone (C1)` / `a sold item is
   nowhere the hero can reach afterwards`** (`447f869`). Superseded by `selling
   puts the item on the counter to be bought back`; the two are contradictory by
   design, and the gold half is still covered by `selling turns an item into
   coins at the selling price`.
2. **`characterization: a hero entry has no visit state (C2)` / `the entry today
   is label, profile and run, and decodes`** (`7f34ced`). Pinned the shape the
   format commit replaces. Superseded by `a hero entry missing its merchant
   block is refused by name`.
3. **`characterization: the shelf resurrects across a relaunch (C3)`**
   (`228c3cc`). Asserted the defect is present. Superseded by `a purchase is
   still gone from the shelf after a relaunch`, which walks the same relaunch
   path and asserts the opposite.
4. **`abandoning the hero` / `no other event ever gives a hero up`**
   (`20e3eb3`). The invariant is now structural rather than testable: there is
   no `abandoned` flag to set, and deleting a hero is a document edit the bloc
   cannot reach.
5. **`abandoning the hero` / `the confirmation gives the hero up and touches
   nothing else`** (`20e3eb3`). Describes an event that no longer exists.
6. **`giving the hero up writes nothing more`** (`20e3eb3`). The autosaver's
   abandoned-state guard existed because the town emitted a state meaning "wipe
   me". Nothing emits that now — the roster's edits happen after `close()` — so
   the guard and its test both describe a path that no longer exists. The
   ordering it protected is covered by `switching lands on the other hero and
   writes it down`.
7. **`giving a hero up keeps every other hero`** (`20e3eb3`). Targeted
   `abandonActiveHero`, which is retired. The property could not survive the
   retirement: `replaceOnlyHero`, which replaced it, exists only when there are
   no other heroes to keep. `deleting the played hero lands on the first one
   left` is what covers a roster with others in it.
8. **`a hero given up is written down before being played`** (`20e3eb3`). Same
   retired function. Replaced by `the only hero is replaced by a named one on
   their own world`, which asserts the same write-before-play through the
   function that now does it.

One assertion, not a whole test, was also removed: `expect(bloc.state.abandoned,
isFalse);` from `a report from the save layer is the first thing the town says`.
The field is gone; the rest of that test stands unchanged.

## Follow-ups to log

- Hero rename after creation (from the spec).
- Roster ordering, most-recently-played first, once heroes accumulate (from the
  spec).
- **New:** a way out of a crawl that suspends rather than ends it. Without one,
  a hero can never be suspended while another is played, so the switch-into-crawl
  path — built, tested, and demonstrated on the device — has no route to it in
  ordinary play. See section 9.
- **New:** nothing bounds the sold-back list within a visit. It clears on the
  next visit so it cannot grow without bound, but a hero who sells twenty items
  gets a twenty-row section and no test says that stays usable.
