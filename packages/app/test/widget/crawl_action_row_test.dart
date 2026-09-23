import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/crawl_action_row.dart';
import 'package:residuum_app/game/crawl_style.dart';
import 'package:residuum_app/game/dungeon_palette.dart';
import 'package:residuum_app/game/dungeon_scene.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/game_screen.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../support/phone.dart';

const _arena = '''
#######
#.....#
#.....#
#######''';

Actor _hero(Position at) => Actor(
  id: 'hero',
  name: 'you',
  glyph: '@',
  position: at,
  hp: 20,
  maxHp: 20,
  attackMin: 4,
  attackMax: 4,
  speed: 10,
  energy: actThreshold,
);

Actor _ghoulAt(Position at) => Actor(
  id: 'ghoul-1',
  name: 'the ghoul',
  glyph: 'g',
  position: at,
  hp: 10,
  maxHp: 10,
  attackMin: 3,
  attackMax: 3,
  speed: 10,
  energy: actThreshold,
);

List<Item> _twoPotions() => const [
  Item(id: 'potion-1', base: healingPotion, rarity: Rarity.common),
  Item(id: 'potion-2', base: healingPotion, rarity: Rarity.common),
];

/// An open battle, one potion carried, one spell known — AC3's minimal proof
/// scene.
GameState _battleScene() {
  final map = FloorMap.parse(_arena);
  const heroAt = Position(1, 1);
  final visible = computeFov(map, heroAt, fovRadius);
  return GameState(
    map: map,
    hero: _hero(heroAt),
    monsters: [_ghoulAt(const Position(1, 2))],
    rng: Rng(1),
    lootRng: Rng(2),
    visible: visible,
    explored: {...visible},
    buildFloor: (depth) => throw StateError('no floor below'),
    spells: spellsById,
    knownSpells: const {'firebolt'},
    mana: 10,
    inventory: const [
      Item(id: 'potion-1', base: healingPotion, rarity: Rarity.common),
    ],
  );
}

/// The bottom-floor stairs scene: exploration's own typical density —
/// `Pick up`, `Drink`, `Pack`, `Ascend <`, `Finish` with count metadata.
GameState _explorationTypicalScene() {
  final map = FloorMap.parse(_arena);
  const heroAt = Position(1, 1);
  final visible = computeFov(map, heroAt, fovRadius);
  return GameState(
    map: map,
    hero: _hero(heroAt),
    monsters: const [],
    rng: Rng(1),
    lootRng: Rng(2),
    visible: visible,
    explored: {...visible},
    buildFloor: (depth) => throw StateError('no floor below'),
    depth: deepestDepth,
    stairsUp: heroAt,
    groundItems: {
      heroAt: [
        const Item(id: 'floor-loot', base: ironSword, rarity: Rarity.common),
      ],
    },
    inventory: _twoPotions(),
  );
}

/// A four-spell combat scene *without* `Frost Lance` — kept only to prove
/// the visible `✳ Firebolt` label and separate `2 mana` metadata remain
/// whole at four columns; the old composed text could hide broken words.
GameState _combatSplitWordScene() {
  final map = FloorMap.parse(_arena);
  const heroAt = Position(1, 1);
  final visible = computeFov(map, heroAt, fovRadius);
  return GameState(
    map: map,
    hero: _hero(heroAt),
    monsters: [_ghoulAt(const Position(1, 2))],
    rng: Rng(1),
    lootRng: Rng(2),
    visible: visible,
    explored: {...visible},
    buildFloor: (depth) => throw StateError('no floor below'),
    spells: spellsById,
    knownSpells: const {'firebolt', 'mend', 'ward', 'bind'},
    mana: 10,
    stairsUp: heroAt,
    nodes: {heroAt: GatherKind.oreVein},
    groundItems: {
      heroAt: [
        const Item(id: 'floor-loot', base: ironSword, rarity: Rarity.common),
      ],
    },
    inventory: _twoPotions(),
  );
}

/// Combat's typical density: four known spells including `Frost Lance`, one
/// potion carried, no stairs, no gather node, nothing underfoot — seven
/// chips, no notes.
GameState _combatTypicalScene() {
  final map = FloorMap.parse(_arena);
  const heroAt = Position(1, 1);
  final visible = computeFov(map, heroAt, fovRadius);
  return GameState(
    map: map,
    hero: _hero(heroAt),
    monsters: [_ghoulAt(const Position(1, 2))],
    rng: Rng(1),
    lootRng: Rng(2),
    visible: visible,
    explored: {...visible},
    buildFloor: (depth) => throw StateError('no floor below'),
    spells: spellsById,
    knownSpells: const {'firebolt', 'frost-lance', 'mend', 'ward'},
    mana: 20,
    inventory: const [
      Item(id: 'potion-1', base: healingPotion, rarity: Rarity.common),
    ],
  );
}

/// The worst *legal* combat scene the game's own rules can produce — chosen
/// by rule, not by which fixture happens to pass. Maximise every
/// independently maximisable term of the row's own arithmetic, at a density
/// the rules can actually reach:
///
/// every spell in the game known (forcing the readied three to `Firebolt`,
/// `Frost Lance` and `Mend`, and the overflow chip to `+3`), a monster
/// holding reach, an item underfoot with the pack short of its cap, a
/// gather node underfoot with the longer verb (`Gather`), the hero on the
/// deepest floor's up stairs so `Finish`/`Ascend <`/the bottom notice all
/// hold, and the widest legal `Drink`/`Pack` counts.
GameState _combatWorstLegalScene() {
  final map = FloorMap.parse(_arena);
  const heroAt = Position(1, 1);
  final visible = computeFov(map, heroAt, fovRadius);
  return GameState(
    map: map,
    hero: _hero(heroAt),
    monsters: [_ghoulAt(const Position(1, 2))],
    rng: Rng(1),
    lootRng: Rng(2),
    visible: visible,
    explored: {...visible},
    buildFloor: (depth) => throw StateError('no floor below'),
    depth: deepestDepth,
    spells: spellsById,
    knownSpells: spellsById.keys.toSet(),
    mana: 20,
    stairsUp: heroAt,
    nodes: {heroAt: GatherKind.herbPatch},
    groundItems: {
      heroAt: [
        const Item(id: 'floor-loot-1', base: ironSword, rarity: Rarity.common),
        const Item(
          id: 'floor-loot-2',
          base: bookOfFrostLance,
          rarity: Rarity.common,
        ),
      ],
    },
    inventory: [
      for (var index = 0; index < 12; index++)
        Item(id: 'potion-$index', base: healingPotion, rarity: Rarity.common),
      for (var index = 0; index < 7; index++)
        Item(id: 'gear-$index', base: ironSword, rarity: Rarity.common),
    ],
  );
}

/// The exploration stairs landing plus a gather node and the plural `Here:`
/// note — six chips, three notes, exploration's own worst density.
GameState _explorationWorstScene() {
  final map = FloorMap.parse(_arena);
  const heroAt = Position(1, 1);
  final visible = computeFov(map, heroAt, fovRadius);
  return GameState(
    map: map,
    hero: _hero(heroAt),
    monsters: const [],
    rng: Rng(1),
    lootRng: Rng(2),
    visible: visible,
    explored: {...visible},
    buildFloor: (depth) => throw StateError('no floor below'),
    depth: deepestDepth,
    stairsUp: heroAt,
    nodes: {heroAt: GatherKind.herbPatch},
    groundItems: {
      heroAt: [
        const Item(id: 'floor-loot-1', base: ironSword, rarity: Rarity.common),
        const Item(id: 'floor-loot-2', base: maul, rarity: Rarity.common),
      ],
    },
    inventory: _twoPotions(),
  );
}

/// A game-over dungeon scene, staged only to prove a disabled Drink chip
/// still reads.
GameState _gameOverScene() {
  final map = FloorMap.parse(_arena);
  const heroAt = Position(1, 1);
  final visible = computeFov(map, heroAt, fovRadius);
  return GameState(
    map: map,
    hero: Actor(
      id: 'hero',
      name: 'you',
      glyph: '@',
      position: heroAt,
      hp: 0,
      maxHp: 20,
      attackMin: 4,
      attackMax: 4,
      speed: 10,
      energy: actThreshold,
    ),
    monsters: const [],
    rng: Rng(1),
    lootRng: Rng(2),
    visible: visible,
    explored: {...visible},
    buildFloor: (depth) => throw StateError('no floor below'),
    isGameOver: true,
    inventory: _twoPotions(),
  );
}

Future<GameBloc> _openCrawl(
  WidgetTester tester,
  GameState game, {
  TextScaler? textScaler,
}) async {
  final bloc = GameBloc(game: game, stepDelay: Duration.zero);
  addTearDown(bloc.close);
  final app = MaterialApp(
    home: BlocProvider.value(
      value: bloc,
      child: const GameScreen(palette: DungeonPalette.crypt),
    ),
  );
  await tester.pumpWidget(
    textScaler == null
        ? app
        : MediaQuery(
            data: MediaQueryData(textScaler: textScaler),
            child: app,
          ),
  );
  await tester.pumpAndSettle();
  return bloc;
}

/// The rendered border a chip's [Material] currently carries — read from the
/// widget the crawl actually painted, never a hex literal.
BorderSide _borderOf(WidgetTester tester, Finder chip) {
  final material = tester.widget<Material>(
    find.descendant(of: chip, matching: find.byType(Material)),
  );
  return (material.shape! as RoundedRectangleBorder).side;
}

/// Every chip-label [RenderParagraph] under [actionRowKey] lays out
/// legally: within its line cap, never rendered narrower than the widest
/// unbreakable word it carries — which is what "no word is broken and
/// nothing ellipsises" means once a label may wrap — and clear of any
/// `RenderFlex` overflow the row's own layout could hide.
///
/// The `didExceedMaxLines` check below is a degenerate-path tripwire, not
/// the clipping proof — `_fitFor`'s own candidate search already discards
/// every column count that would exceed `crawlChipMaxLabelLines`, so it
/// cannot fail on any candidate the search accepts. It only guards the one
/// path that search does not cover: the no-legal-candidate fallback, which
/// lays out at the full available width with no line-count check of its
/// own. The real no-squeeze proof is the intrinsic-width check after it.
void _expectLegalRow(WidgetTester tester, {required String reason}) {
  final paragraphs = tester.renderObjectList<RenderParagraph>(
    find.descendant(
      of: find.descendant(
        of: find.byKey(actionRowKey),
        matching: find.byType(Wrap),
      ),
      matching: find.byType(Text),
    ),
  );
  for (final paragraph in paragraphs) {
    expect(paragraph.didExceedMaxLines, isFalse, reason: reason);
    expect(
      paragraph.size.width + 0.5,
      greaterThanOrEqualTo(paragraph.getMinIntrinsicWidth(double.infinity)),
      reason: reason,
    );
  }
  expect(tester.takeException(), isNull, reason: reason);
}

/// Every run of chips except the last holds as many chips as the row's own
/// column count allows, and the last run holds no more — a row that leaves
/// a run short of what its chosen width allows is paying for a run it did
/// not need.
void _expectRunCapacity(WidgetTester tester) {
  // Grouped by each chip's own container, never its label paragraph: a
  // taller (multi-line) label shifts its centred text within a
  // uniform-height chip, so two chips sharing a run can report label tops a
  // few dp apart even though the row itself is perfectly aligned.
  final chips = find.descendant(
    of: find.descendant(
      of: find.byKey(actionRowKey),
      matching: find.byType(Wrap),
    ),
    matching: find.byWidgetPredicate(
      (widget) => widget.key is ValueKey<String>,
    ),
  );
  final count = chips.evaluate().length;
  final tops = [
    for (var index = 0; index < count; index++)
      tester.getTopLeft(chips.at(index)).dy,
  ]..sort();
  final runs = <int>[];
  var lastTop = double.negativeInfinity;
  for (final top in tops) {
    if (runs.isNotEmpty && (top - lastTop).abs() < 1) {
      runs[runs.length - 1] += 1;
    } else {
      runs.add(1);
    }
    lastTop = top;
  }
  expect(runs, isNotEmpty);
  final chipsPerRun = runs.first;
  for (final run in runs.take(runs.length - 1)) {
    expect(run, chipsPerRun);
  }
  expect(runs.last, lessThanOrEqualTo(chipsPerRun));
}

double _chromeHeight(WidgetTester tester) {
  final surfaceHeight =
      tester.view.physicalSize.height / tester.view.devicePixelRatio;
  final mapHeight = tester.getRect(find.byKey(dungeonSceneSlotKey)).height;
  return surfaceHeight - mapHeight;
}

void main() {
  testWidgets(
    'exactly one action row renders, and Drink and Wait each render once',
    (tester) async {
      // arrange
      await onAPhone(tester);
      final game = _battleScene();

      // act
      await _openCrawl(tester, game);

      expect(find.byKey(const ValueKey('drink')), findsOneWidget);
      expect(find.text('Drink'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('drink')),
          matching: find.text('×1'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('wait')), findsOneWidget);
      expect(find.text('Wait'), findsOneWidget);
      expect(find.byKey(actionRowKey), findsOneWidget);
      expect(find.byKey(const Key('battle-shelf')), findsNothing);
    },
  );
  testWidgets('stable ids retain chip elements while display fields change', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CrawlActionRow(
            notes: const [],
            actions: [
              CrawlAction(
                id: 'drink',
                label: 'Drink',
                metadata: '×1',
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
    final before = tester.element(find.byKey(const ValueKey('drink')));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CrawlActionRow(
            notes: const [],
            actions: [
              CrawlAction(
                id: 'drink',
                label: 'Potion',
                metadata: '×9',
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.element(find.byKey(const ValueKey('drink'))), same(before));
    expect(find.text('Potion'), findsOneWidget);
    expect(find.text('×9'), findsOneWidget);
  });

  testWidgets('ids, semantics and overflow stay independent of display text', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CrawlActionRow(
            notes: const [],
            actions: [
              CrawlAction(id: 'first', label: 'Same', onPressed: () {}),
              CrawlAction(
                id: 'second',
                label: 'Same',
                metadata: '×2',
                onPressed: () {},
              ),
              CrawlAction(id: 'spells-overflow', label: '+3', onPressed: () {}),
            ],
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('first')), findsOneWidget);
    expect(find.byKey(const ValueKey('second')), findsOneWidget);
    expect(find.bySemanticsLabel('Same ×2'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('spells-overflow')),
        matching: find.byType(Image),
      ),
      findsNothing,
    );
    expect(find.text('+3'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('duplicate action ids assert even when labels differ', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CrawlActionRow(
            notes: const [],
            actions: [
              CrawlAction(id: 'same', label: 'One', onPressed: () {}),
              CrawlAction(id: 'same', label: 'Two', onPressed: () {}),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isA<AssertionError>());
  });

  testWidgets(
    'every chip in a row shares one width and height, icon over word',
    (tester) async {
      // arrange
      await onAPhone(tester);
      final game = _explorationTypicalScene();

      // act
      await _openCrawl(tester, game);

      // assert - even widths and heights across the whole row
      const ids = ['pick-up', 'drink', 'pack', 'ascend', 'leave-dungeon'];
      final rects = [
        for (final id in ids) tester.getRect(find.byKey(ValueKey(id))),
      ];
      for (final rect in rects.skip(1)) {
        expect(rect.width, closeTo(rects.first.width, 0.01));
        expect(rect.height, closeTo(rects.first.height, 0.01));
      }

      // assert - every icon-bearing chip carries its icon above its word
      for (final entry in {
        'Drink': 'drink',
        'Pack': 'pack',
        'Ascend <': 'ascend',
      }.entries) {
        final chip = find.byKey(ValueKey(entry.value));
        final imageTop = tester
            .getTopLeft(find.descendant(of: chip, matching: find.byType(Image)))
            .dy;
        final textTop = tester
            .getTopLeft(
              find.descendant(of: chip, matching: find.text(entry.key)),
            )
            .dy;
        expect(imageTop, lessThan(textTop), reason: entry.key);
      }
    },
  );

  test('the chip-state table separates available, disabled and armed without a hue', () {
    // arrange
    final available = crawlChipSkin(CrawlChipState.available);
    final disabled = crawlChipSkin(CrawlChipState.disabled);
    final armed = crawlChipSkin(CrawlChipState.armed);

    // assert - fill luminance orders disabled below available below armed
    expect(
      disabled.fill.computeLuminance(),
      lessThan(available.fill.computeLuminance()),
    );
    expect(
      available.fill.computeLuminance(),
      lessThan(armed.fill.computeLuminance()),
    );

    // assert - the armed border is heavier and a different colour
    expect(armed.borderWidth, greaterThan(available.borderWidth));
    expect(armed.border, isNot(available.border));

    // assert - the disabled label reads dimmer, the armed label heavier
    expect(
      disabled.label.color!.computeLuminance(),
      lessThan(available.label.color!.computeLuminance()),
    );
    expect(
      armed.label.fontWeight!.value,
      greaterThan(available.label.fontWeight!.value),
    );
  });

  testWidgets('arming and disarming a spell chip never reflows the map', (
    tester,
  ) async {
    // arrange
    await onAPhone(tester);
    final game = _battleScene();
    await _openCrawl(tester, game);
    final mapRectBefore = tester.getRect(find.byKey(dungeonSceneSlotKey));
    final firebolt = find.byKey(const ValueKey('spell:firebolt'));
    final wait = find.byKey(const ValueKey('wait'));
    final unarmedBorder = _borderOf(tester, wait);

    // act
    await tester.tap(firebolt);
    await tester.pumpAndSettle();

    // assert
    expect(find.text('✳ Firebolt'), findsOneWidget);
    expect(find.text('2 mana'), findsOneWidget);
    expect(_borderOf(tester, firebolt).width, greaterThan(unarmedBorder.width));
    expect(tester.getRect(find.byKey(dungeonSceneSlotKey)), mapRectBefore);

    // act - tapping the armed chip again disarms it.
    await tester.tap(firebolt);
    await tester.pumpAndSettle();

    // assert
    expect(find.text('— armed'), findsNothing);
    expect(
      _borderOf(tester, firebolt).width,
      closeTo(unarmedBorder.width, 0.01),
    );
    expect(tester.getRect(find.byKey(dungeonSceneSlotKey)), mapRectBefore);
  });

  testWidgets(
    'the chrome stays within its revised exploration and combat caps',
    (tester) async {
      // arrange + act - exploration's own worst density
      await onAPhone(tester);
      await _openCrawl(tester, _explorationWorstScene());
      final explorationWorst = _chromeHeight(tester);

      // assert
      expect(
        explorationWorst,
        lessThanOrEqualTo(360),
        reason:
            'measured exploration-worst chrome: $explorationWorst dp '
            '(re-derived cap: 331.0 dp measured, rounded up to 340, '
            '+20 dp headroom)',
      );
      _expectLegalRow(tester, reason: 'exploration worst');

      // arrange + act - combat's typical density
      await _openCrawl(tester, _combatTypicalScene());
      final combatTypical = _chromeHeight(tester);

      // assert
      expect(
        combatTypical,
        lessThanOrEqualTo(450),
        reason:
            'measured combat-typical chrome: $combatTypical dp '
            '(re-derived cap: 429.0 dp measured, rounded up to 430, '
            '+20 dp headroom)',
      );
      _expectLegalRow(tester, reason: 'combat typical');

      // arrange + act - the worst *legal* combat scene, chosen by rule
      await _openCrawl(tester, _combatWorstLegalScene());
      final combatWorstLegal = _chromeHeight(tester);
      // The widget fixture excludes verified Android system insets, which
      // contributed 4.43 dp to the measured device chrome. Keep that same
      // 600 dp total ceiling by limiting app-owned chrome to 595 dp.
      expect(
        combatWorstLegal,
        lessThanOrEqualTo(595),
        reason:
            'worst-legal app chrome must leave at least 4.43 dp for the '
            'verified Android inset contribution under the unchanged 600 dp '
            'total ceiling; measured $combatWorstLegal dp',
      );

      // assert
      expect(
        combatWorstLegal,
        lessThanOrEqualTo(600),
        reason:
            'measured combat-worst-legal chrome: $combatWorstLegal dp '
            '(re-derived cap: 578.0 dp measured, rounded up to 580, '
            '+20 dp headroom)',
      );
      _expectLegalRow(tester, reason: 'combat worst legal');
      _expectRunCapacity(tester);
      const worstIds = [
        'drink',
        'spell:firebolt',
        'spell:frost-lance',
        'spell:mend',
        'spells-overflow',
        'wait',
        'pick-up',
        'gather',
        'pack',
        'ascend',
        'leave-dungeon',
      ];
      expect(
        find
            .descendant(
              of: find.byKey(actionRowKey),
              matching: find.byWidgetPredicate(
                (widget) => widget.key is ValueKey<String>,
              ),
            )
            .evaluate(),
        hasLength(11),
      );
      for (final id in worstIds) {
        expect(find.byKey(ValueKey(id)), findsOneWidget);
      }
      expect(find.text('Flee'), findsNothing);
      expect(find.text('+3'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('spells-overflow')),
          matching: find.byType(Image),
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'the row is laid out legally: no broken word, no clip, no overflow',
    (tester) async {
      // arrange + act - the scene whose split word the old first-fit rule
      // let through
      await onAPhone(tester);
      await _openCrawl(tester, _combatSplitWordScene());

      // assert
      _expectLegalRow(tester, reason: 'combat split-word scene');

      // arrange + act - the worst legal scene
      await _openCrawl(tester, _combatWorstLegalScene());

      // assert
      _expectLegalRow(tester, reason: 'combat worst legal scene');
    },
  );

  testWidgets('a longer verb costs the row at most one chip run', (
    tester,
  ) async {
    // arrange + act
    await onAPhone(tester);
    await _openCrawl(tester, _combatSplitWordScene());
    final splitWordChrome = _chromeHeight(tester);
    await _openCrawl(tester, _combatWorstLegalScene());
    final worstLegalChrome = _chromeHeight(tester);

    // assert - one chip run at the line ceiling, never a whole extra branch
    // of the column search
    final difference = (worstLegalChrome - splitWordChrome).abs();
    expect(
      difference,
      lessThanOrEqualTo(96),
      reason:
          'split-word chrome $splitWordChrome dp, worst-legal chrome '
          '$worstLegalChrome dp, difference $difference dp',
    );
  });

  testWidgets('the reservation honours the ambient text scale', (tester) async {
    // arrange + act
    await onAPhone(tester);
    await _openCrawl(
      tester,
      _combatTypicalScene(),
      textScaler: TextScaler.linear(1.3),
    );

    // assert
    expect(tester.takeException(), isNull);
    _expectLegalRow(tester, reason: 'combat typical at 1.3x text scale');
  });

  testWidgets('a game-over Drink chip still reads its word and icon, inert', (
    tester,
  ) async {
    // arrange
    await onAPhone(tester);
    final game = _gameOverScene();

    // act
    await _openCrawl(tester, game);

    // assert
    final drink = find.byKey(const ValueKey('drink'));
    expect(drink, findsOneWidget);
    expect(
      find.descendant(of: drink, matching: find.byType(Image)),
      findsOneWidget,
    );
    final inkWell = tester.widget<InkWell>(
      find.descendant(of: drink, matching: find.byType(InkWell)),
    );
    expect(inkWell.onTap, isNull);
  });
}
