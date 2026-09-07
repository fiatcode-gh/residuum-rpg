# m3-craft-risk Implementation Plan

> Execute with flow-executing-plans, task by task.

**Goal:** The forge and alchemist bench become all-workshop: tempering loses its
gold cost, and both tempering and brewing can fail on a tier-based,
level-scaled odds table whose randomness lives on the Profile as a craft
stream.

**Spec:** `/var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/docs/epic/m3-craft-risk-spec-M3CR.md`

## Global constraints

- Save v3 stands: no version bump, no golden rewritten. `craftRngState`
  encodes omit-on-default on the `itemNumber` precedent.
- The crawl's two streams are never touched by a craft draw. The craft stream
  lives on the Profile, seeded `worldSeed ^ craftSeedSalt`.
- One attempt, one advance — 0% tiers included. A refusal is not an attempt.
- A failure costs exactly one material (1 ingot / one brew's 3 herbs), leaves
  the result unchanged, allows an immediate retry, still grants its skill xp.
- Smelting never fails and never draws.
- Failure is a word in the town notice slot, never a colour.
- No changes to the town-ux surface beyond the forge price line's gold term.
- `docs/epic/` is gitignored — never commit it.
- No root pubspec: run suites per package directory (`cd packages/<pkg> &&
  flutter test`).
- `dart pub get` per package before any format or analyze claim.
- git only as `cd <repo> && git <cmd>` (sandbox exclusion patterns).
- No comments in bodies; dartdoc `///` only, on public API of core and
  content. Ubiquitous language: `temper`, `brew`, `smelt`, `ingot`, `tier`.
- Strict TDD in core: red → green → refactor, every behavior. Bodies as
  `// arrange` / `// act` / `// assert`.
- Every commit's exit state is green.

## Rulings declared to the dispatcher before code (mailbox entries 2 and 3)

1. **The failure notice rides a sealed answer, not a third tuple slot.**
   `TownRefusal` keeps its "changes nothing" contract. A new sealed base
   `TownAnswer` (a sentence) gains a second kind, `CraftLoss`, marking a craft
   the bench worked and lost. `temperItem` and `brewPotion` return the new
   `Crafted = (Profile, TownAnswer?)` — still a 2-tuple, so existing call
   sites and tests compile untouched. Records are subtype-componentwise, so
   `Transacted` still feeds `_crafted`.
2. **M1's "+0" prose reads as "the item does not gain its tier."** A tier-2
   attempt starts from an item at +1; an item at +0 is a tier-1 attempt,
   which never fails.
3. **On a failed attempt the loss sentence is the notice**, level-up or not;
   success paths keep today's wording exactly.
4. **The brew odds stand as written** (20% − 2%/level, floor 5%, no gate) and
   **one attempt one advance stands as written** — argued and accepted in
   mailbox entry 2.

## Task 1: Characterization baseline

**Files:** none (run-only).

- [x] From the unmodified worktree (`git status --porcelain` clean), run all
      three suites and record strict counts:
      `cd packages/core && flutter test --reporter json | tee /tmp/m3cr-core.json`
      then
      `grep '"type":"testDone"' /tmp/m3cr-core.json | grep -c '"result":"success"'`
      minus
      `grep '"type":"testDone"' /tmp/m3cr-core.json | grep '"result":"success"' | grep -c '"hidden":true'`.
      Repeat for `packages/content` and `packages/app`. Baseline of record
      from the D118 merge: 2045 green (core 835 + content 573 + app 637);
      measure fresh and state which.
- [x] Run the band trail fresh: `cd packages/content && flutter test
      test/survivability_test.dart` and quote the five lines verbatim.
- [x] Confirm the golden save test and `dungeon_door_characterization_test.dart`
      are green in that run.
- [x] No commit — nothing changed. If any of this reddens on unmodified code,
      STOP and report to the mailbox.

## Task 2: `Profile.craftRngState`

**Files:** `packages/core/test/town/profile_test.dart`,
`packages/core/lib/src/town/profile.dart`.

- [x] Write the failing tests (append a group inside `main` of
      `profile_test.dart`; `_townie()` already exists there):

```dart
    group('the craft stream state', () {
      test('defaults to never-drawn', () {
        // arrange
        final profile = _townie();

        // act
        final state = profile.craftRngState;

        // assert - an old save without the key reads the same as a hero who
        // has never crafted, so lazy seeding needs no migration
        expect(state, 0);
      });

      test('copyWith carries it', () {
        // arrange
        final profile = _townie();

        // act
        final moved = profile.copyWith(craftRngState: 42);

        // assert - copyWith is hand-rolled field by field, and a field it
        // drops is a field every boundary silently loses (the D56 trap)
        expect(moved.craftRngState, 42);
        expect(moved, isNot(profile));
      });

      test('is part of the profile\'s identity', () {
        // arrange
        final profile = _townie();

        // act
        final advanced = profile.copyWith(craftRngState: 7);

        // assert
        expect(advanced == profile, isFalse);
      });
    });
```

- [x] Run `cd packages/core && flutter test test/town/profile_test.dart` —
      confirm red (compile errors count as red for a missing field).
- [x] Minimal implementation in `profile.dart`:
      constructor parameter `this.craftRngState = 0,` after `itemNumber`;
      field with dartdoc:

```dart
  /// The exported state of the craft stream, the hero's own source of craft
  /// rolls.
  ///
  /// **The town's first random decision needed a stream of its own.** A crawl
  /// has two streams and the town none — paying a stated price is not a draw —
  /// so the failure roll tempering and brewing now make draws from this one,
  /// seeded off the world salt and never touched by the dungeon: a craft roll
  /// made while camped cannot shift a resumed crawl off its roll-for-roll
  /// guarantee.
  ///
  /// Starts at zero, which reads as never-drawn: the first draw constructs the
  /// stream from `worldSeed ^ craftSeedSalt` and writes the advanced state
  /// back. An old save without this key decodes to the default and lazy-seeds
  /// — no migration, and every golden document stays byte-identical.
  final int craftRngState;
```

      plus the `copyWith` parameter and passthrough, and `craftRngState`
      appended to `props`.
- [x] Run the file's tests, then the whole core suite — green.
- [x] `cd . && git add packages/core/... ` — commit:
      `cd /var/home/dhemas/Development/Projects/fiatcode-gh/residuum-rpg/.worktrees/m3-craft-risk && git add packages/core && git commit -m "feat(core): craftRngState rides the profile"`

## Task 3: The odds table and the craft draw

**Files:** `packages/core/test/craft/risk_test.dart` (new),
`packages/core/lib/src/craft/risk.dart` (new), `packages/core/lib/core.dart`.

- [x] Write the failing tests:

```dart
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

/// A craft-stream state whose next percent roll lands at or above [floor].
int stateRollingAtLeast(int floor) {
  for (var state = 1; state < 100000; state++) {
    final rng = Rng.fromState(state);
    if (rng.rollRange(0, 99) >= floor) return state;
  }
  throw StateError('no state rolls at or above $floor');
}

/// A craft-stream state whose next percent roll lands below [ceiling].
int stateRollingBelow(int ceiling) {
  for (var state = 1; state < 100000; state++) {
    final rng = Rng.fromState(state);
    if (rng.rollRange(0, 99) < ceiling) return state;
  }
  throw StateError('no state rolls below $ceiling');
}

void main() {
  group('temperFailChance', () {
    test('tier 1 never fails', () {
      expect(temperFailChance(1, 0), 0);
      expect(temperFailChance(1, 100), 0);
    });

    test('tier 2 starts at twenty at its gate', () {
      expect(temperFailChance(2, 5), 20);
    });

    test('tier 3 starts at thirty-five at its gate', () {
      expect(temperFailChance(3, 10), 35);
    });

    test('every level past the gate takes two points off', () {
      expect(temperFailChance(2, 6), 18);
      expect(temperFailChance(3, 13), 29);
    });

    test('the floor clamps at five and never below', () {
      // arrange - the level that would go under
      expect(temperFailChance(2, 12), 6);
      expect(temperFailChance(2, 13), 5);
      expect(temperFailChance(2, 30), 5);
      expect(temperFailChance(3, 25), 5);
      expect(temperFailChance(3, 26), 5);
      expect(temperFailChance(3, 30), 5);
    });
  });

  group('brewFailChance', () {
    test('level 0 brews at twenty, and no gate stands in the way', () {
      expect(brewFailChance(0), 20);
    });

    test('every level takes two points off, floored at five', () {
      expect(brewFailChance(7), 6);
      expect(brewFailChance(8), 5);
      expect(brewFailChance(9), 5);
      expect(brewFailChance(50), 5);
    });
  });

  group('craftDraw', () {
    test('lazy-seeds off the world seed on the first draw', () {
      // arrange
      final profile = Profile(
        hero: hero(const Position(0, 0)),
        worldSeed: 5,
      );

      // act
      final (after, _) = craftDraw(profile, 20);

      // assert
      final rng = Rng(5 ^ craftSeedSalt)..rollRange(0, 99);
      expect(after.craftRngState, rng.state);
    });

    test('advances from the carried state once drawn', () {
      // arrange
      final profile = Profile(
        hero: hero(const Position(0, 0)),
        worldSeed: 5,
        craftRngState: 1234,
      );

      // act
      final (after, _) = craftDraw(profile, 20);

      // assert
      final rng = Rng.fromState(1234)..rollRange(0, 99);
      expect(after.craftRngState, rng.state);
    });

    test('advances exactly once even when the tier cannot fail', () {
      // arrange
      final profile = Profile(
        hero: hero(const Position(0, 0)),
        worldSeed: 5,
        craftRngState: stateRollingAtLeast(1),
      );

      // act
      final (after, failed) = craftDraw(profile, 0);

      // assert - stream consumption is a fact about the attempt, not the
      // outcome; skipping the draw would make it outcome-dependent
      final rng = Rng.fromState(stateRollingAtLeast(1))..rollRange(0, 99);
      expect(failed, isFalse);
      expect(after.craftRngState, rng.state);
    });

    test('answers failure below the odds and success at or above them', () {
      // arrange
      final fails = Profile(
        hero: hero(const Position(0, 0)),
        worldSeed: 5,
        craftRngState: stateRollingBelow(20),
      );
      final holds = Profile(
        hero: hero(const Position(0, 0)),
        worldSeed: 5,
        craftRngState: stateRollingAtLeast(20),
      );

      // act
      final (_, failed) = craftDraw(fails, 20);
      final (_, held) = craftDraw(holds, 20);

      // assert
      expect(failed, isTrue);
      expect(held, isFalse);
    });
  });
}
```

- [x] Red: `cd packages/core && flutter test test/craft/risk_test.dart`.
- [x] Minimal implementation, `packages/core/lib/src/craft/risk.dart`:

```dart
import 'dart:math';

import '../engine/rng.dart';
import '../town/profile.dart';
import 'temper.dart';

/// What the craft stream's seed is offset by, so it never runs in step with
/// the crawl's two streams or the loot stream.
///
/// A literal rather than a derived value, for the reason the loot stream's own
/// salt is one: a world seed has to describe the same craft odds to every
/// player who types it in, including one running a build compiled years apart
/// from another's. Chosen by collision sweep against the loot stream's early
/// sequence on the fixture heroes — the sweep lives in content's test suite,
/// where both salts are visible.
const int craftSeedSalt = 0x0C7A;

/// The percent chance a temper of [tier] fails for a hero at [blacksmithLevel].
///
/// Tier 1 never fails — the teaching tier stays free of the mechanic that
/// would punish the hero it is meant to teach. The other tiers start at their
/// table odds and take off two points per Blacksmith level past the tier's
/// gate, floored at five: training tames the odds and never kills them.
int temperFailChance(int tier, int blacksmithLevel) => switch (tier) {
  1 => 0,
  2 => _tabled(20, blacksmithLevel - temperPrices[1].blacksmith),
  3 => _tabled(35, blacksmithLevel - temperPrices[2].blacksmith),
  _ => throw RangeError.value(tier, 'tier', 'no temper reaches $tier'),
};

/// The percent chance a brew fails for a hero at [herbcraftLevel].
///
/// No gate, because Herbcraft has no tiers a gate could hang on — inventing
/// one would lock the only thing herbs are for behind training a new hero has
/// no reason to have started. Level 0 brews at twenty; the floor arrives at
/// level 8.
int brewFailChance(int herbcraftLevel) => _tabled(20, herbcraftLevel);

int _tabled(int start, int levelsPast) => max(5, start - 2 * levelsPast);

/// Draws the craft roll for one attempt: [profile] with the stream advanced
/// once, and whether the attempt failed.
///
/// **One attempt, one advance**, 0% tiers included — stream consumption is a
/// fact about the attempt, not the outcome. A field still reading its default
/// lazy-seeds off the world seed, so an old save without the key boots clean.
(Profile, bool) craftDraw(Profile profile, int failChance) {
  final rng = profile.craftRngState == 0
      ? Rng(profile.worldSeed ^ craftSeedSalt)
      : Rng.fromState(profile.craftRngState);
  final failed = rng.rollRange(0, 99) < failChance;
  return (profile.copyWith(craftRngState: rng.state), failed);
}
```

      and add `export 'src/craft/risk.dart';` to `core.dart`.
- [x] Green: file test, then the whole core suite.
- [x] Commit: `feat(core): the craft odds table and the craft stream`

## Task 4: Tempering loses its gold

**Files:** `packages/core/test/craft/temper_test.dart`,
`packages/core/lib/src/craft/temper.dart`.

- [x] Write the failing tests. In `temper_test.dart`:
      replace the `gold` column assertion in 'every tier costs more than the
      one below it' (drop the `gold` list and its `expect`), delete
      'refuses when the purse is short', and add:

```dart
    test('a broke hero with the iron in hand is not refused on the purse', () {
      // arrange
      final profile = _hero(
        inventory: [_item('kit-1', _sword)],
        gold: 0,
      );

      // act
      final refusal = temperRefusal(profile, 'kit-1');

      // assert - the balancer is training, not the purse: the bench is a
      // workshop and gold changes hands nowhere
      expect(refusal, isNull);
    });
```

      (keep 'answers the iron before the purse' but drop its `gold: 0`
      significance — rename to 'answers the iron, which is the whole price';
      the sentence stays 'that takes 1 ingot'.)
- [x] Red: `cd packages/core && flutter test test/craft/temper_test.dart`.
- [x] Minimal implementation in `temper.dart`:
      `TemperPrice` loses `gold` (field, constructor parameter, dartdoc);
      `temperPrices` becomes:

```dart
const List<TemperPrice> temperPrices = [
  TemperPrice(blacksmith: 0, ingots: 1),
  TemperPrice(blacksmith: 5, ingots: 2),
  TemperPrice(blacksmith: 10, ingots: 3),
];
```

      `temperRefusal` loses the `if (profile.gold < price.gold)` check; the
      dartdoc's step 5 becomes 'the iron, which is now the whole price', and
      the table's group dartdoc is rewritten to the new economics (twelve ore
      takes a piece all the way — several delves' worth of looking down — with
      no purse in the sentence).
- [x] Green: `temper_test.dart` green; core suite may still redden in
      `craft_shop_test.dart` (pinned gold spending) — that is Task 5's
      territory; do not leave the suite red across a commit, so Task 4 and
      Task 5 commit together if needed. Preferred: make this task's edit
      include the `craft_shop_test.dart` and `town_bloc_test.dart` gold
      updates listed in Task 5 so every commit is green.
- [x] Commit: `feat(core): tempering is paid in iron, not gold`

## Task 5: `temperItem` fails, `brewPotion` fails

**Files:** `packages/core/test/town/town_test.dart` (no change needed),
`packages/core/test/town/craft_shop_test.dart`,
`packages/core/test/craft/temper_test.dart` (failure sentences),
`packages/core/lib/src/town/town.dart`,
`packages/app/test/town_bloc_test.dart`.

- [x] Write the failing tests. New group in `craft_shop_test.dart` (the
      `_hero` helper there already takes `blacksmith`, `materials`,
      `inventory`; add the two state helpers at the top of the file):

```dart
/// A craft-stream state whose next percent roll lands at or above [floor].
int stateRollingAtLeast(int floor) {
  for (var state = 1; state < 100000; state++) {
    final rng = Rng.fromState(state);
    if (rng.rollRange(0, 99) >= floor) return state;
  }
  throw StateError('no state rolls at or above $floor');
}

/// A craft-stream state whose next percent roll lands below [ceiling].
int stateRollingBelow(int ceiling) {
  for (var state = 1; state < 100000; state++) {
    final rng = Rng.fromState(state);
    if (rng.rollRange(0, 99) < ceiling) return state;
  }
  throw StateError('no state rolls below $ceiling');
}
```

```dart
  group('a temper that fails', () {
    test('loses exactly one ingot, not the tier\'s price', () {
      // arrange - tier 3 prices at 3 ingots; a failure still costs 1
      final profile = _hero(
        inventory: [_item('drop-1', _sword, temper: 2)],
        materials: const {MaterialId.ingot: 3},
        blacksmith: 10,
      ).copyWith(craftRngState: stateRollingBelow(35));

      // act
      final (after, answer) = temperItem(profile, 'drop-1');

      // assert
      expect(answer, const CraftLoss('the temper fails and takes 1 ingot'));
      expect(after.materials, const {MaterialId.ingot: 2});
    });

    test('leaves the item where it was', () {
      // arrange
      final profile = _hero(
        inventory: [_item('drop-1', _sword, temper: 1)],
        materials: const {MaterialId.ingot: 2},
        blacksmith: 5,
      ).copyWith(craftRngState: stateRollingBelow(20));

      // act
      final (after, _) = temperItem(profile, 'drop-1');

      // assert
      expect(after.inventory.single.temper, 1);
      expect(after.inventory.single.attackMin, _sword.attackMin);
    });

    test('trains Blacksmith anyway — practice is practice', () {
      // arrange
      final profile = _hero(
        inventory: [_item('drop-1', _sword, temper: 1)],
        materials: const {MaterialId.ingot: 2},
        blacksmith: 5,
      ).copyWith(craftRngState: stateRollingBelow(20));

      // act
      final (after, _) = temperItem(profile, 'drop-1');

      // assert
      expect(after.skills[SkillId.blacksmith], const SkillState(level: 5, xp: 1));
    });

    test('advances the craft stream exactly once', () {
      // arrange
      final before = _hero(
        inventory: [_item('drop-1', _sword, temper: 1)],
        materials: const {MaterialId.ingot: 2},
        blacksmith: 5,
      ).copyWith(craftRngState: stateRollingBelow(20));

      // act
      final (after, _) = temperItem(before, 'drop-1');

      // assert
      final rng = Rng.fromState(before.craftRngState)..rollRange(0, 99);
      expect(after.craftRngState, rng.state);
    });

    test('a tier-1 temper cannot fail and spends its full ingot', () {
      // arrange - M2: the teaching tier stays free of the mechanic
      final profile = _hero(
        inventory: [_item('drop-1', _sword)],
        materials: const {MaterialId.ingot: 1},
        blacksmith: 0,
      ).copyWith(craftRngState: stateRollingAtLeast(1));

      // act
      final (after, answer) = temperItem(profile, 'drop-1');

      // assert
      expect(answer, isNull);
      expect(after.inventory.single.temper, 1);
      expect(after.materials, isEmpty);
    });

    test('a failed temper takes no gold, because there is no gold to take', () {
      // arrange
      final profile = _hero(
        inventory: [_item('drop-1', _sword, temper: 1)],
        materials: const {MaterialId.ingot: 2},
        blacksmith: 5,
        gold: 40,
      ).copyWith(craftRngState: stateRollingBelow(20));

      // act
      final (after, _) = temperItem(profile, 'drop-1');

      // assert
      expect(after.gold, 40);
    });
  });

  group('a brew that fails', () {
    test('takes the brew\'s herbs and makes no potion', () {
      // arrange
      final profile = _hero(
        materials: const {MaterialId.herb: 3},
        herbcraft: 0,
      ).copyWith(craftRngState: stateRollingBelow(20));

      // act
      final (after, answer) = brewPotion(profile, _potion);

      // assert
      expect(answer, const CraftLoss('the brew fails and takes 3 herbs'));
      expect(after.materials, isEmpty);
      expect(after.inventory, isEmpty);
      expect(after.brewNumber, profile.brewNumber);
    });

    test('trains Herbcraft anyway', () {
      // arrange
      final profile = _hero(
        materials: const {MaterialId.herb: 3},
        herbcraft: 0,
      ).copyWith(craftRngState: stateRollingBelow(20));

      // act
      final (after, _) = brewPotion(profile, _potion);

      // assert
      expect(after.skills[SkillId.herbcraft], const SkillState(xp: 1));
    });

    test('a refusal draws nothing — a refusal is not an attempt', () {
      // arrange
      final profile = _hero(materials: const {MaterialId.herb: 2});

      // act
      final (after, refusal) = brewPotion(profile, _potion);

      // assert
      expect(refusal, const TownRefusal('that takes 3 herbs'));
      expect(after, profile);
      expect(after.craftRngState, 0);
    });
  });
```

      In the existing groups of `craft_shop_test.dart`, update the gold pins
      so the suite tells the new truth: 'spends the tier's ingots and gold'
      becomes 'spends the tier's ingots' (drop `after.gold, 90`, add
      `expect(after.gold, 100)`), 'the second tier costs more than the first'
      drops its `after.gold, 75`, 'three tempers in a row reach the ceiling'
      drops `worked.gold, 1000 - 85` and its gold wording in the assert
      comment, and 'a refused temper spends nothing' keeps its assertions
      (gold untouched still holds). In `town_bloc_test.dart`, 'tempers a
      carried weapon, spending the iron and the gold' drops the
      `expect(bloc.state.profile.gold, 90)` line and is renamed 'tempers a
      carried weapon, spending the iron'.
- [x] Red: `cd packages/core && flutter test test/town/craft_shop_test.dart`.
- [x] Minimal implementation in `town.dart`:

```dart
/// The sentence a transaction answers in, refusal or loss alike.
///
/// **Two kinds, because they point opposite ways.** A [TownRefusal] changes
/// nothing at all; a [CraftLoss] marks a craft the bench worked and lost —
/// the profile it answers with is not the profile it arrived on. The screen
/// reads only the sentence, which is why the pair shares one shape.
sealed class TownAnswer extends Equatable {
  const TownAnswer(this.reason);

  /// Written to be read aloud on the screen, not parsed.
  final String reason;

  @override
  List<Object?> get props => [reason];

  @override
  String toString() => '$runtimeType($reason)';
}

/// The town's answer to [ActionRefused]... (existing dartdoc, unchanged)
class TownRefusal extends TownAnswer {
  const TownRefusal(this.reason);
}
```

      (TownRefusal loses its own `props`/`toString` — the base carries them.)
      Add:

```dart
/// A craft the bench worked and lost: the material is gone, the result is not.
///
/// **Not a refusal, and the difference is the whole point.** A refusal changes
/// nothing at all; a loss took exactly one material and trained the skill
/// anyway, so a caller that treated it as a refusal would believe the pack
/// unchanged. The bench says the sentence in the town slot, worded with the
/// loss, never a colour.
class CraftLoss extends TownAnswer {
  const CraftLoss(this.reason);
}

/// A profile after a craft, and the sentence that answers for it, or null.
///
/// The craft transactions' shape, identical to [Transacted] but for the
/// answer's kind: a craft can be refused before any work, or worked and lost.
typedef Crafted = (Profile, TownAnswer?);
```

      `temperItem` becomes:

```dart
Crafted temperItem(Profile profile, String itemId) {
  final refusal = temperRefusal(profile, itemId);
  if (refusal != null) return (profile, TownRefusal(refusal));
  final item = heldItem(profile, itemId)!;
  final price = temperPriceFrom(item.temper);
  final level = profile.skills[SkillId.blacksmith]?.level ?? 0;
  final (drawn, failed) = craftDraw(
    profile,
    temperFailChance(item.temper + 1, level),
  );
  if (failed) {
    return (
      drawn.copyWith(
        materials: withMaterial(drawn.materials, MaterialId.ingot, -1),
        skills: trainedIn(drawn.skills, SkillId.blacksmith),
      ),
      const CraftLoss('the temper fails and takes 1 ingot'),
    );
  }
  final worked = item.tempered(item.temper + 1);
  final at = drawn.inventory.indexWhere((carried) => carried.id == itemId);
  final inventory = at < 0
      ? drawn.inventory
      : ([...drawn.inventory]..[at] = worked);
  final equipment = at >= 0
      ? drawn.equipment
      : {
          for (final slot in drawn.equipment.keys)
            slot: drawn.equipment[slot]!.id == itemId
                ? worked
                : drawn.equipment[slot]!,
        };
  return (
    _clamped(
      drawn.copyWith(
        inventory: inventory,
        equipment: equipment,
        materials: withMaterial(
          drawn.materials,
          MaterialId.ingot,
          -price.ingots,
        ),
        skills: trainedIn(drawn.skills, SkillId.blacksmith),
      ),
    ),
    null,
  );
}
```

      (the `gold:` term is gone; the dartdoc loses 'Spends the tier's ingots
      and gold' wording and gains the failure branch's description). And
      `brewPotion` becomes:

```dart
Crafted brewPotion(Profile profile, BaseItem potion) {
  final refusal = brewRefusal(profile);
  if (refusal != null) return (profile, TownRefusal(refusal));
  final level = profile.skills[SkillId.herbcraft]?.level ?? 0;
  final (drawn, failed) = craftDraw(profile, brewFailChance(level));
  if (failed) {
    return (
      drawn.copyWith(
        materials: withMaterial(drawn.materials, MaterialId.herb, -brewCost),
        skills: trainedIn(drawn.skills, SkillId.herbcraft),
      ),
      const CraftLoss('the brew fails and takes $brewCost herbs'),
    );
  }
  final brewed = Item(
    id: 'brew-${drawn.brewNumber}',
    base: potion,
    rarity: Rarity.common,
  );
  return (
    drawn.copyWith(
      inventory: [...drawn.inventory, brewed],
      materials: withMaterial(drawn.materials, MaterialId.herb, -brewCost),
      brewNumber: drawn.brewNumber + 1,
      skills: trainedIn(drawn.skills, SkillId.herbcraft),
    ),
    null,
  );
}
```

      `const CraftLoss('the brew fails and takes $brewCost herbs')` — a
      const constructor cannot take an interpolated literal, so this one is
      `CraftLoss('the brew fails and takes $brewCost herbs')` (non-const).
- [x] Green: whole core suite green.
- [x] Commit: `feat(core): a temper or a brew can fail, and it costs one material`

## Task 6: The crawl is never touched (stream discipline)

**Files:** `packages/core/test/town/craft_stream_test.dart` (new).

- [x] Write the failing test (M6's roll-for-roll core):

```dart
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

const _room = '''
##########
#........#
#........#
##########''';

const _sword = BaseItem(
  id: 'iron-sword',
  name: 'Iron Sword',
  glyph: ')',
  slot: EquipSlot.mainHand,
  hands: WeaponHands.one,
  attackMin: 3,
  attackMax: 5,
);

Dungeon _roomed() => (visit) => (depth) => Floor(
  map: FloorMap.parse(_room),
  heroSpawn: const Position(1, 1),
  monsters: [ghoul('ghoul-1', const Position(8, 2))],
  stairsDown: depth >= deepestDepth ? null : const Position(8, 1),
  stairsUp: depth <= 1 ? null : const Position(1, 1),
);

Profile _crafter({required int craftRngState}) => Profile(
  hero: hero(const Position(0, 0)),
  worldSeed: 909,
  inventory: [
    Item(id: 'drop-1', base: _sword, rarity: Rarity.common).tempered(1),
  ],
  materials: const {MaterialId.ingot: 3},
  skills: {
    ...untrainedSkills,
    SkillId.blacksmith: const SkillState(level: 5),
  },
  craftRngState: craftRngState,
);

GameState _bumped(GameState run) {
  var state = run;
  for (var turn = 0; turn < 20; turn++) {
    state = step(state, const MoveAction(Direction.up)).$1;
  }
  return state;
}

void main() {
  group('the crawl\'s streams', () {
    test('run roll for roll whether or not a craft failed in town', () {
      // arrange - two identical heroes; one goes and fails a temper first
      final still = _crafter(craftRngState: 1);
      final failing = _crafter(craftRngState: 1);

      // act
      final (worked, answer) = temperItem(failing, 'drop-1');
      final quietRun = _bumped(startRun(still, dungeon: _roomed()));
      final craftedRun = _bumped(startRun(worked, dungeon: _roomed()));

      // assert - the attempt failed and cost the ingot, and the dungeon does
      // not know it happened
      expect(answer, isNotNull);
      expect(quietRun.rng.state, craftedRun.rng.state);
      expect(quietRun.lootRng.state, craftedRun.lootRng.state);
      expect(quietRun.monsters.length, craftedRun.monsters.length);
    });

    test('a town craft attempt moves no stream a resume depends on', () {
      // arrange
      final hero = _crafter(craftRngState: 1);
      final run = startRun(hero, dungeon: _roomed());

      // act
      final after = suspendRun(hero, run);
      final (worked, _) = temperItem(after, 'drop-1');
      final resumed = resumeRun(worked, run);

      // assert
      expect(resumed.rng.state, run.rng.state);
      expect(resumed.lootRng.state, run.lootRng.state);
      expect(resumed.map, run.map);
    });
  });
}
```

- [x] Red first — `cd packages/core && flutter test
      test/town/craft_stream_test.dart` — then confirm these pass with the
      Task 5 implementation (they are the contract the mutation table
      M6 guards; if they pass immediately, they are still the named red set
      for M6). If either reddens against the Task 5 code, that is a bug in
      the implementation — fix before proceeding.
- [x] Green: whole core suite.
- [x] Commit: `test(core): the crawl never feels a craft roll`

## Task 7: The codec — omit-on-default, and the salt sweep

**Files:** `packages/content/test/save/craft_rng_codec_test.dart` (new),
`packages/content/test/craft_stream_test.dart` (new),
`packages/content/lib/src/save/profile_codec.dart`.

- [x] Write the failing codec tests (mirroring `item_number_codec_test.dart`, whose imports and `_reread` helper are copied as they stand):

```dart
import 'package:residuum_content/content.dart';
import 'package:residuum_content/src/save/profile_codec.dart';
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

Profile _reread(Profile profile) =>
    decodeProfile({'profile': encodeProfile(profile)}, 'profile');

void main() {
  group('craftRngState rides the profile codec omit-on-default', () {
    test('a hero who has never crafted writes no key at all', () {
      // arrange
      final fresh = newProfile(worldSeed: 9007199254740993);

      // act
      final written = encodeProfile(fresh);

      // assert - an unconditional encode would rewrite every golden document
      expect(written.containsKey('craftRngState'), isFalse);
    });

    test('an advanced stream state is written as text', () {
      // arrange
      final advanced = newProfile(
        worldSeed: 9007199254740993,
      ).copyWith(craftRngState: -8613303245920329199);

      // act
      final written = encodeProfile(advanced);

      // assert - generator states are text; a number would not survive a
      // narrow reader
      expect(written['craftRngState'], '-8613303245920329199');
    });

    test('an absent key reads as never-drawn — the legacy shape loads', () {
      // arrange
      final fresh = newProfile(worldSeed: 9007199254740993);
      final written = encodeProfile(fresh)..remove('craftRngState');

      // act
      final back = decodeProfile({'profile': written}, 'profile');

      // assert
      expect(back.craftRngState, 0);
      expect(back, fresh);
    });

    test('a written state round-trips', () {
      // arrange
      final advanced = newProfile(
        worldSeed: 9007199254740993,
      ).copyWith(craftRngState: -8613303245920329199);

      // act
      final back = _reread(advanced);

      // assert
      expect(back.craftRngState, -8613303245920329199);
      expect(back, advanced);
    });
  });
}
```

- [x] Write the failing salt sweep (`packages/content/test/craft_stream_test.dart`):

```dart
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

/// The house sweep list — every fixture hero the pins stand on.
const List<int> _sweptSeeds = [1, 5, 77, 909, 4242, 123456, 1755800000000];

List<int> _earlyRolls(Rng rng) =>
    [for (var roll = 0; roll < 64; roll++) rng.rollRange(0, 99)];

bool _same(List<int> left, List<int> right) {
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

void main() {
  group('the craft stream', () {
    test('never runs in step with the loot stream', () {
      // arrange
      final collisions = <String>[];

      // act
      for (final worldSeed in _sweptSeeds) {
        final craftRolls = _earlyRolls(Rng(worldSeed ^ craftSeedSalt));
        final lootRolls = _earlyRolls(Rng(worldSeed ^ lootStreamSalt));
        if (_same(craftRolls, lootRolls)) {
          collisions.add('world $worldSeed: craft runs with loot');
        }
      }

      // assert
      expect(collisions, isEmpty);
    });

    test('its salt is its own', () {
      expect(craftSeedSalt, isNot(lootStreamSalt));
    });
  });
}
```

      Run it: it should PASS already against the chosen salt `0x0C7A` — it is
      the salt's evidence, not a red-green target; if it reddens, the salt
      collides and a new literal is chosen and the sweep re-run. Record the
      result either way.
- [x] Red: the codec tests redden before the codec change.
- [x] Minimal implementation in `profile_codec.dart`:
      encode gains, after `'brewNumber': profile.brewNumber,`:

```dart
  if (profile.craftRngState != 0) 'craftRngState': encodeWide(profile.craftRngState),
```

      decode gains, after the `itemNumber:` line:

```dart
    craftRngState: written.containsKey('craftRngState')
        ? wideAt(written, 'craftRngState')
        : 0,
```

- [x] Green: content save suite green — including `golden_save_test.dart`
      byte-identical and `suspend_theorem_test.dart` untouched.
- [x] Commit: `feat(content): craftRngState rides the codec omit-on-default`

## Task 8: The bench says so — town_bloc and the forge price line

**Files:** `packages/app/lib/town/town_bloc.dart`,
`packages/app/lib/town/forge_screen.dart`,
`packages/app/test/town_bloc_test.dart`,
`packages/app/test/widget/craft_rooms_test.dart`.

- [x] Write the failing bloc test (in `town_bloc_test.dart`, forge group;
      `_fresh()` and `_gear` already exist; add the state helper at the top):

```dart
/// A craft-stream state whose next percent roll lands below [ceiling].
int stateRollingBelow(int ceiling) {
  for (var state = 1; state < 100000; state++) {
    final rng = Rng.fromState(state);
    if (rng.rollRange(0, 99) < ceiling) return state;
  }
  throw StateError('no state rolls below $ceiling');
}
```

```dart
    blocTest<TownBloc, TownViewState>(
      'says the loss in the town slot when the temper fails',
      build: () => TownBloc(
        profile: _fresh()
            .copyWith(
              inventory: [_gear('drop-1', ironSword, temper: 1)],
              materials: const {MaterialId.ingot: 2},
              skills: {
                ...untrainedSkills,
                SkillId.blacksmith: const SkillState(level: 5),
              },
            )
            .copyWith(craftRngState: stateRollingBelow(20)),
      ),
      act: (bloc) => bloc.add(const TemperPressed('drop-1')),
      verify: (bloc) {
        expect(bloc.state.notice?.sentence, 'the temper fails and takes 1 ingot');
        expect(bloc.state.profile.materials, const {MaterialId.ingot: 1});
        expect(bloc.state.profile.inventory.single.temper, 1);
      },
    );
```

- [x] Red: `cd packages/app && flutter test test/town_bloc_test.dart`.
- [x] Minimal implementation. In `town_bloc.dart`, `_crafted` widens:

```dart
  TownViewState _crafted(Crafted result, SkillId trained) {
    final settled = _settled(result.$1, result.$2);
    if (result.$2 != null) return settled;
    final before = state.profile.skills[trained]?.level ?? 0;
    final after = result.$1.skills[trained]?.level ?? 0;
    if (after <= before) return settled;
    return _noticed(
      settled,
      SentenceNotice('${skillName(trained)} rises to $after'),
    );
  }
```

      `_settled`'s second parameter widens to `TownAnswer?` (its body reads
      only `answer == null ? null : SentenceNotice(answer.reason)`); the
      dartdoc gains the loss sentence: a refusal trained nothing and a loss's
      sentence is the news the bench owes, level-up or not. `_onSmelt` keeps
      passing `smeltOre`'s `Transacted` — a record of a subtype tuple, which
      `Crafted` accepts.
      In `forge_screen.dart`, the price line becomes:

```dart
            child: Text(
              reason ??
                  'Next tier: ${price!.ingots} '
                      '${price.ingots == 1 ? 'ingot' : 'ingots'}.',
              style: monoDim,
            ),
```

- [x] Update the widget pin: 'names the price of the next tier when it is
      open' expects `find.text('Next tier: 1 ingot.')`.
- [x] Green: app suite green.
- [x] Commit: `feat(app): the bench says the loss, and the price line is ingots-only`

## Task 9: Verification — mutation table, band trail, goldens, hygiene

**Files:** none (evidence-only; REPORT.md in the handoff directory).

- [x] **Mutation table** — one temporary edit at a time, named red set each
      time, `git checkout -- <file>` after each, and re-check
      `git status --porcelain` a beat later (auto-format re-dirty trap).
      Wrap suite commands in `bash -c` (the background runner may be fish).
      - M1 make the draw never fail: in `risk.dart`, `craftDraw` returns
        `failed: false`. Run core `craft_shop_test.dart`. Expect red:
        'a temper that fails' group — the loss tests named there ('loses
        exactly one ingot', 'leaves the item where it was', 'trains
        Blacksmith anyway', 'advances the craft stream exactly once', 'a
        failed temper takes no gold').
      - M2 apply tier-2 odds to tier 1: in `risk.dart`,
        `temperFailChance` case `1 => _tabled(20, blacksmithLevel - 0)`.
        Run core `craft_shop_test.dart`. Expect red: 'a tier-1 temper cannot
        fail and spends its full ingot'.
      - M3 drop the floor: `_tabled` returns `start - 2 * levelsPast` with no
        `max`. Run core `risk_test.dart`. Expect red: 'the floor clamps at
        five and never below' and 'every level takes two points off, floored
        at five'.
      - M4 gate the brew odds: `brewFailChance` returns `0` at
        `herbcraftLevel < 5` (invent a gate). Run core `risk_test.dart`.
        Expect red: 'level 0 brews at twenty, and no gate stands in the way'.
      - M5 full price on failure: in `town.dart`, the failure branch spends
        `-price.ingots` instead of `-1`. Run core `craft_shop_test.dart`.
        Expect red: 'loses exactly one ingot, not the tier's price'.
      - M6 draw from the crawl stream: in `risk.dart`, `craftDraw` uses
        `Rng(profile.worldSeed)` and writes nothing back. Run core
        `craft_stream_test.dart` and `risk_test.dart`. Expect red:
        'run roll for roll whether or not a craft failed in town' plus
        'lazy-seeds off the world seed on the first draw' and 'advances from
        the carried state once drawn'.
      - M7 gold sneaks back: in `town.dart`, the success path of
        `temperItem` adds `gold: drawn.gold - price.gold`, and
        `temperRefusal` regains the purse check. Run core
        `craft_shop_test.dart` + `temper_test.dart` and app
        `craft_rooms_test.dart`. Expect red: broke-hero test, gold-untouched
        pins, and 'names the price of the next tier when it is open'.
      Report the whole table with greens named.
- [x] **Band trail**: `cd packages/content && flutter test
      test/survivability_test.dart` — quote all five lines verbatim; they
      must be byte-identical to the Task 1 run (the bot never crafts).
- [ ] **Goldens**: `golden_save_test.dart` green; the three pinned documents
      byte-identical (they are string constants — the green test is the
      proof).
- [ ] **Counts**: all three packages green with strict counts from result
      files (hidden-filter arithmetic), compared against the Task 1 baseline.
- [ ] **Format/analyze** ×3: per package, `dart pub get` then
      `dart format --output=none --set-exit-if-changed lib test` then
      `dart analyze` — clean.
- [ ] Write `REPORT.md` in the handoff directory mirroring the verification
      block, append the done notice to `worker.md`, and stop.