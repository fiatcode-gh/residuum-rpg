import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/art/art_assets.dart';
import 'package:residuum_app/game/action_icon.dart';
import 'package:residuum_app/game/crawl_action_row.dart';
import 'package:residuum_app/game/crawl_style.dart';
import 'package:residuum_app/game/dungeon_palette.dart';
import 'package:residuum_app/game/dungeon_scene.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/game_screen.dart';
import 'package:residuum_app/style/tokens.dart';
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

/// An open battle, one potion carried, one spell known.
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

/// A quiet exploring room, no monsters, nothing underfoot, no stairs — the
/// no-notes half of the notes-invariance proof, chrome-identical to
/// [_explorationWorstScene] except for what triggers a note.
GameState _explorationScene() {
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
    inventory: _twoPotions(),
  );
}

/// The exploration stairs landing plus a gather node and the plural `Here:`
/// note — two notes on screen at once.
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

/// A game-over dungeon scene, staged only to prove a disabled Drink slot
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

Future<GameBloc> _openCrawl(WidgetTester tester, GameState game) async {
  final bloc = GameBloc(game: game, stepDelay: Duration.zero);
  addTearDown(bloc.close);
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider.value(
        value: bloc,
        child: const GameScreen(palette: DungeonPalette.crypt),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return bloc;
}

/// The rendered border a slot's [Material] currently carries — read from the
/// widget the crawl actually painted, never a hex literal.
BorderSide _borderOf(WidgetTester tester, Finder slot) {
  final material = tester.widget<Material>(
    find.descendant(of: slot, matching: find.byType(Material)),
  );
  return (material.shape! as RoundedRectangleBorder).side;
}

/// A synthetic, mark-only action for the bar's own geometry proofs — none of
/// these tests care what a real scene would ever offer, only how the bar
/// itself lays fixed slots out.
CrawlAction _plainAction(
  String id, {
  String metadata = '',
  bool armable = false,
  bool armed = false,
  VoidCallback? onPressed,
}) => CrawlAction(
  id: id,
  label: 'Label $id',
  metadata: metadata,
  mark: const FontMark(Icons.circle),
  armable: armable,
  armed: armed,
  onPressed: onPressed ?? () {},
);

List<CrawlAction> _actions(int count) => [
  for (var index = 0; index < count; index++) _plainAction('a$index'),
];

/// The plan's own minimal skeleton replica: a fixed action bar under an
/// `Expanded` map slot, inside `SafeArea` and the crawl's clamped text
/// scaling — enough of PLAN.md G8 to prove the bar's geometry never depends
/// on the map, and vice versa, without needing the real game rules to ever
/// produce a specific action count.
const _mapKey = Key('bar-test-map-slot');

Future<void> _pumpBar(WidgetTester tester, List<CrawlAction> actions) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            child: Column(
              children: [
                const Expanded(key: _mapKey, child: SizedBox.expand()),
                CrawlActionBar(key: actionRowKey, actions: actions),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
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

  testWidgets('stable ids retain slot elements while display fields change', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CrawlActionBar(
            actions: [_plainAction('drink', metadata: '×1')],
          ),
        ),
      ),
    );
    final before = tester.element(find.byKey(const ValueKey('drink')));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CrawlActionBar(
            actions: [
              CrawlAction(
                id: 'drink',
                label: 'Potion',
                metadata: '×9',
                mark: const FontMark(Icons.circle),
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

  testWidgets('ids, semantics and marks stay independent of display text', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CrawlActionBar(
            actions: [
              _plainAction('first'),
              _plainAction('second', metadata: '×2'),
              CrawlAction(
                id: 'spells-overflow',
                label: '+3',
                mark: const ShippedMark(ActionIcon.more),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('first')), findsOneWidget);
    expect(find.byKey(const ValueKey('second')), findsOneWidget);
    expect(find.bySemanticsLabel('Label second ×2'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('spells-overflow')),
        matching: find.byType(Image),
      ),
      findsOneWidget,
      reason: 'the overflow verb carries the shipped "more" mark (PLAN G9)',
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
          body: CrawlActionBar(
            actions: [
              CrawlAction(
                id: 'same',
                label: 'One',
                mark: const FontMark(Icons.circle),
                onPressed: () {},
              ),
              CrawlAction(
                id: 'same',
                label: 'Two',
                mark: const FontMark(Icons.circle),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isA<AssertionError>());
  });

  group('the fixed bar (PLAN.md G8)', () {
    testWidgets(
      'the bar is a fixed 60 dp at scale 1.0 no matter how many actions it holds',
      (tester) async {
        await onTheTargetPhone(tester);
        for (final count in [1, 3, 5, 12]) {
          await _pumpBar(tester, _actions(count));
          expect(
            tester.getSize(find.byKey(actionRowKey)).height,
            closeTo(crawlActionBarHeight, 0.5),
            reason: '$count actions',
          );
        }
      },
    );

    testWidgets(
      'the map slot above the bar does not move when the action count changes',
      (tester) async {
        await onTheTargetPhone(tester);
        await _pumpBar(tester, _actions(1));
        final oneActionMapRect = tester.getRect(find.byKey(_mapKey));

        await _pumpBar(tester, _actions(12));
        final twelveActionMapRect = tester.getRect(find.byKey(_mapKey));

        expect(twelveActionMapRect, oneActionMapRect);
      },
    );

    testWidgets(
      'five slots or fewer share one equal width, and the rest stand as inert frames',
      (tester) async {
        final semanticsHandle = tester.ensureSemantics();
        await onTheTargetPhone(tester);
        final screenWidth =
            tester.view.physicalSize.width / tester.view.devicePixelRatio;
        final barWidth = screenWidth - crawlGutter * 2;
        final expectedSlotWidth = (barWidth - crawlSlotGap * 4) / 5;

        for (final n in [1, 3, 5]) {
          await _pumpBar(tester, _actions(n));

          for (var index = 0; index < n; index++) {
            expect(
              tester.getSize(find.byKey(ValueKey('a$index'))).width,
              closeTo(expectedSlotWidth, 0.5),
              reason: '$n actions, slot $index',
            );
          }
          // Only a real slot paints a Material; an inert frame is a bare
          // DecoratedBox, so this count is exactly the action count.
          expect(
            find
                .descendant(
                  of: find.byKey(actionRowKey),
                  matching: find.byType(Material),
                )
                .evaluate()
                .length,
            n,
            reason: '$n actions',
          );
          // Only a real slot wraps an InkWell, so an inert frame can never
          // respond to a tap.
          expect(
            find
                .descendant(
                  of: find.byKey(actionRowKey),
                  matching: find.byType(InkWell),
                )
                .evaluate()
                .length,
            n,
            reason: '$n actions',
          );
          // Only a real slot carries a button semantics node, so the
          // remaining 5 - n frames are invisible to assistive technology.
          final barNode = tester.getSemantics(find.byKey(actionRowKey));
          var buttonCount = 0;
          void countButtons(SemanticsNode node) {
            if (node.getSemanticsData().flagsCollection.isButton) {
              buttonCount++;
            }
            node.visitChildren((child) {
              countButtons(child);
              return true;
            });
          }

          countButtons(barNode);
          expect(buttonCount, n, reason: '$n actions');
        }
        semanticsHandle.dispose();
      },
    );

    testWidgets(
      'more than five actions scroll: the sixth peeks 18 dp, and dragging to '
      'the end reaches and dispatches the last',
      (tester) async {
        await onTheTargetPhone(tester);
        var lastTapped = false;
        final actions = [
          ..._actions(11),
          CrawlAction(
            id: 'a11',
            label: 'Label a11',
            mark: const FontMark(Icons.circle),
            onPressed: () => lastTapped = true,
          ),
        ];
        await _pumpBar(tester, actions);

        final barRect = tester.getRect(
          find.descendant(
            of: find.byKey(actionRowKey),
            matching: find.byType(SingleChildScrollView),
          ),
        );
        for (var index = 0; index < 5; index++) {
          final rect = tester.getRect(find.byKey(ValueKey('a$index')));
          expect(
            rect.left,
            greaterThanOrEqualTo(barRect.left - 0.5),
            reason: 'slot $index',
          );
          expect(
            rect.right,
            lessThanOrEqualTo(barRect.right + 0.5),
            reason: 'slot $index',
          );
        }
        final sixth = tester.getRect(find.byKey(const ValueKey('a5')));
        expect(barRect.right - sixth.left, closeTo(crawlSlotPeek, 0.5));

        // act - drag the bar to its scroll end
        await tester.drag(find.byKey(actionRowKey), const Offset(-4000, 0));
        await tester.pumpAndSettle();

        final last = tester.getRect(find.byKey(const ValueKey('a11')));
        expect(last.left, greaterThanOrEqualTo(barRect.left - 0.5));
        expect(last.right, lessThanOrEqualTo(barRect.right + 0.5));

        // act - tap the now fully visible last slot
        await tester.tap(find.byKey(const ValueKey('a11')));
        await tester.pumpAndSettle();

        // assert
        expect(lastTapped, isTrue);
      },
    );

    testWidgets(
      'arming a spell turns its frame cold, its label the armed role, and '
      'replaces its metadata with "— armed"; the map above never reflows',
      (tester) async {
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
        final armedLabel = tester.widget<Text>(
          find.descendant(of: firebolt, matching: find.text('✳ Firebolt')),
        );
        expect(armedLabel.style, textSlotArmed);
        expect(
          find.descendant(of: firebolt, matching: find.text('— armed')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: firebolt, matching: find.text('2 mana')),
          findsNothing,
        );
        final armedBorder = _borderOf(tester, firebolt);
        expect(armedBorder.color, crawlCold);
        expect(armedBorder.width, greaterThan(unarmedBorder.width));
        expect(tester.getRect(find.byKey(dungeonSceneSlotKey)), mapRectBefore);

        // act - tapping the armed slot again disarms it
        await tester.tap(firebolt);
        await tester.pumpAndSettle();

        // assert
        expect(
          find.descendant(of: firebolt, matching: find.text('— armed')),
          findsNothing,
        );
        expect(
          find.descendant(of: firebolt, matching: find.text('2 mana')),
          findsOneWidget,
        );
        expect(
          _borderOf(tester, firebolt).width,
          closeTo(unarmedBorder.width, 0.01),
        );
        expect(tester.getRect(find.byKey(dungeonSceneSlotKey)), mapRectBefore);
      },
    );

    testWidgets(
      'every action shows its G9 mark: a shipped icon renders an image, a '
      'font mark a Material glyph',
      (tester) async {
        await onTheTargetPhone(tester);
        await _pumpBar(tester, [
          CrawlAction(
            id: 'shipped',
            label: 'Drink',
            mark: const ShippedMark(ActionIcon.potion),
            onPressed: () {},
          ),
          CrawlAction(
            id: 'font',
            label: 'Pick up',
            mark: const FontMark(Icons.back_hand),
            onPressed: () {},
          ),
        ]);

        expect(
          find.descendant(
            of: find.byKey(const ValueKey('shipped')),
            matching: find.byType(Image),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('font')),
            matching: find.byIcon(Icons.back_hand),
          ),
          findsOneWidget,
        );
      },
    );
  });

  testWidgets('a game-over Drink slot still reads its word and mark, inert', (
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
      find.descendant(of: drink, matching: find.text('Drink')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: drink, matching: find.byType(Image)),
      findsOneWidget,
    );
    final inkWell = tester.widget<InkWell>(
      find.descendant(of: drink, matching: find.byType(InkWell)),
    );
    expect(inkWell.onTap, isNull);
  });

  testWidgets(
    'notes render inside the map rect, which never resizes for them',
    (tester) async {
      // arrange + act - a scene with no notes at all
      await onAPhone(tester);
      await _openCrawl(tester, _explorationScene());
      final mapRectNoNotes = tester.getRect(find.byKey(dungeonSceneSlotKey));

      // arrange + act - a scene with two notes on screen at once
      await _openCrawl(tester, _explorationWorstScene());
      final mapRect = tester.getRect(find.byKey(dungeonSceneSlotKey));

      // assert - the map rect never moved for the notes appearing
      expect(mapRect, mapRectNoNotes);

      final note = find.descendant(
        of: find.byKey(dungeonSceneSlotKey),
        matching: find.textContaining('Underfoot:'),
      );
      expect(note, findsOneWidget);
      final noteRect = tester.getRect(note);
      expect(mapRect.contains(noteRect.topLeft), isTrue);
      expect(mapRect.contains(noteRect.bottomRight), isTrue);
    },
  );
}
