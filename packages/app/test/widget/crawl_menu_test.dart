import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/action_icon.dart';
import 'package:residuum_app/game/crawl_menu.dart';
import 'package:residuum_app/game/dungeon_palette.dart';
import 'package:residuum_app/game/dungeon_scene.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/game_screen.dart';
import 'package:residuum_app/game/grid_geometry.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../support/phone.dart';

const _arena = '''
#######
#.....#
#.....#
#.....#
#######''';

const _heroAt = Position(2, 2);
const _adjacentToHero = Position(3, 2);
const _distantTile = Position(5, 2);

Actor _actor(
  String id,
  Position at, {
  String glyph = '@',
  int hp = 10,
  int speed = 10,
}) => Actor(
  id: id,
  name: id,
  glyph: glyph,
  position: at,
  hp: hp,
  maxHp: 20,
  attackMin: 4,
  attackMax: 4,
  speed: speed,
  energy: actThreshold,
);

GameState _crawl({
  List<Actor> monsters = const [],
  List<Item> inventory = const [],
  Set<String> knownSpells = const {},
  int mana = 0,
  int heroHp = 20,
  Set<Position>? visible,
}) {
  final map = FloorMap.parse(_arena);
  final seen = visible ?? computeFov(map, _heroAt, fovRadius);
  return GameState(
    map: map,
    hero: _actor('hero', _heroAt, hp: heroHp),
    monsters: monsters,
    rng: Rng(1),
    lootRng: Rng(2),
    visible: seen,
    explored: {...seen},
    buildFloor: (depth) => throw StateError('this arena has no floor below'),
    spells: spellsById,
    knownSpells: knownSpells,
    mana: mana,
    inventory: inventory,
  );
}

/// A quiet room with nothing nearby, so `isBattleOpen` is false and nothing
/// is Watched.
GameState _exploringGame({
  List<Item> inventory = const [],
  Set<String> knownSpells = const {},
  int mana = 0,
  int heroHp = 20,
}) => _crawl(
  inventory: inventory,
  knownSpells: knownSpells,
  mana: mana,
  heroHp: heroHp,
);

/// A visible ghoul two cells away, outside engagement range — known but not
/// adjacent, so the hero is Watched rather than engaged.
GameState _watchedGame() =>
    _crawl(monsters: [_actor('ghoul-1', _distantTile, glyph: 'g')]);

/// The hero and one live ghoul stand adjacent, so `isBattleOpen` is true.
GameState _battleGame({
  Set<String> knownSpells = const {},
  int mana = 0,
  List<Item> inventory = const [],
  int heroHp = 20,
}) => _crawl(
  monsters: [_actor('ghoul-1', _adjacentToHero, glyph: 'g')],
  knownSpells: knownSpells,
  mana: mana,
  inventory: inventory,
  heroHp: heroHp,
);

Future<GameBloc> _openCrawl(
  WidgetTester tester,
  GameState game, {
  TextScaler? textScaler,
}) async {
  await onTheTargetPhone(tester);
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

Finder _slot(String id) => find.byKey(ValueKey(id));

/// Taps one tile of the arena, through the scene's own geometry — the same
/// camera every crawl test taps through.
Future<void> _tapTile(WidgetTester tester, Position tile) async {
  final scene = find.byKey(dungeonSceneKey);
  final size = tester.getSize(scene);
  final geometry = GridGeometry.camera(size, 7, 5, _heroAt);
  final local = geometry.centreOf(tile);
  await tester.tapAt(tester.getTopLeft(scene) + local);
}

/// The armed-state frame width painted on [slot]'s `Material`, read from the
/// widget the crawl actually painted, never a hex/width literal.
BorderSide _frameOf(WidgetTester tester, Finder slot) =>
    (tester
                .widget<Material>(
                  find.descendant(of: slot, matching: find.byType(Material)),
                )
                .shape!
            as RoundedRectangleBorder)
        .side;

/// Fails unless [slot]'s mark sits centred above its label, both centred on
/// the slot's own horizontal centre.
void _expectCentred(WidgetTester tester, Finder slot) {
  final slotRect = tester.getRect(slot);
  final markRect = tester.getRect(
    find.descendant(of: slot, matching: find.byType(ActionMarkView)),
  );
  final labelRect = tester.getRect(
    find.descendant(of: slot, matching: find.byType(Text)),
  );
  final centreX = slotRect.center.dx;
  expect(markRect.center.dx, closeTo(centreX, 0.5));
  expect(labelRect.center.dx, closeTo(centreX, 0.5));
  expect(markRect.bottom, lessThanOrEqualTo(labelRect.top));
  final gapAbove = markRect.top - slotRect.top;
  final gapBelow = slotRect.bottom - labelRect.bottom;
  expect((gapAbove - gapBelow).abs(), lessThanOrEqualTo(1.0));
}

void main() {
  testWidgets(
    'the four slots read Quests, Spells, Quick, Hero in that order, with an '
    'identical menu rect, in exploration, Watched, battle and armed',
    (tester) async {
      await _openCrawl(
        tester,
        _exploringGame(knownSpells: const {'firebolt'}, mana: 10),
      );
      final menuRect = tester.getRect(find.byKey(crawlMenuKey));
      final order = [
        for (final id in [
          'menu-quests',
          'menu-spells',
          'menu-quick',
          'menu-hero',
        ])
          tester.getTopLeft(_slot(id)).dx,
      ];
      expect(order, [order[0], order[1], order[2], order[3]]..sort());

      await _openCrawl(tester, _watchedGame());
      expect(tester.getRect(find.byKey(crawlMenuKey)), menuRect);

      await _openCrawl(
        tester,
        _battleGame(knownSpells: const {'firebolt'}, mana: 10),
      );
      expect(tester.getRect(find.byKey(crawlMenuKey)), menuRect);

      final armedBloc = await _openCrawl(
        tester,
        _battleGame(knownSpells: const {'firebolt'}, mana: 10),
      );
      armedBloc.add(const SkillArmed('firebolt'));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(crawlMenuKey)), menuRect);
    },
  );

  testWidgets('Spells is dimmed with no known spells and its tap says so', (
    tester,
  ) async {
    await _openCrawl(tester, _exploringGame());

    await tester.tap(_slot('menu-spells'));
    await tester.pumpAndSettle();

    expect(find.text('You know no spells yet.'), findsOneWidget);
  });

  testWidgets('Quick is dimmed with nothing carried and its tap says so', (
    tester,
  ) async {
    await _openCrawl(tester, _exploringGame());

    await tester.tap(_slot('menu-quick'));
    await tester.pumpAndSettle();

    expect(find.text('You carry nothing to drink.'), findsOneWidget);
  });

  testWidgets('Quests is always dimmed and shows the coming-soon notice', (
    tester,
  ) async {
    await _openCrawl(tester, _exploringGame());

    await tester.tap(_slot('menu-quests'));
    await tester.pumpAndSettle();

    expect(find.text('Quests are coming soon.'), findsOneWidget);
  });

  testWidgets('an outside tap closes a pop-up without moving the hero', (
    tester,
  ) async {
    final bloc = await _openCrawl(tester, _exploringGame());
    final heroBefore = bloc.state.game.hero.position;

    await tester.tap(_slot('menu-quests'));
    await tester.pumpAndSettle();
    expect(find.text('Quests are coming soon.'), findsOneWidget);

    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();

    expect(find.text('Quests are coming soon.'), findsNothing);
    expect(bloc.state.game.hero.position, heroBefore);
  });

  testWidgets('the system back gesture closes an open pop-up', (tester) async {
    await _openCrawl(tester, _exploringGame());

    await tester.tap(_slot('menu-quests'));
    await tester.pumpAndSettle();
    expect(find.text('Quests are coming soon.'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Quests are coming soon.'), findsNothing);
  });

  testWidgets('Hero opens the pack screen and back returns to the crawl', (
    tester,
  ) async {
    await _openCrawl(tester, _exploringGame());

    await tester.tap(_slot('menu-hero'));
    await tester.pumpAndSettle();
    expect(find.text('Pack'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(crawlMenuKey), findsOneWidget);
  });

  Future<void> expectTwoTapDrink(WidgetTester tester, GameState game) async {
    final bloc = await _openCrawl(tester, game);
    final hpBefore = bloc.state.game.hero.hp;

    await tester.tap(_slot('menu-quick'));
    await tester.pumpAndSettle();
    await tester.tap(_slot('drink:potion-1'));
    await tester.pumpAndSettle();

    expect(bloc.state.game.hero.hp, greaterThan(hpBefore));
    expect(
      bloc.state.log.map((line) => line.sentence),
      contains(contains('drink')),
    );
    expect(find.text('Common Healing Potion'), findsNothing);
  }

  testWidgets('drinking in exploration takes exactly two taps', (tester) async {
    await expectTwoTapDrink(
      tester,
      _exploringGame(
        heroHp: 10,
        inventory: const [
          Item(id: 'potion-1', base: healingPotion, rarity: Rarity.common),
        ],
      ),
    );
  });

  testWidgets('drinking in battle takes exactly two taps', (tester) async {
    await expectTwoTapDrink(
      tester,
      _battleGame(
        heroHp: 10,
        inventory: const [
          Item(id: 'potion-1', base: healingPotion, rarity: Rarity.common),
        ],
      ),
    );
  });

  testWidgets(
    'a potion drunk while Quick is open updates the row without closing it',
    (tester) async {
      final bloc = await _openCrawl(
        tester,
        _exploringGame(
          inventory: const [
            Item(id: 'potion-1', base: healingPotion, rarity: Rarity.common),
            Item(id: 'potion-2', base: healingPotion, rarity: Rarity.common),
          ],
        ),
      );

      await tester.tap(_slot('menu-quick'));
      await tester.pumpAndSettle();
      expect(find.text('×2 · heals 10'), findsOneWidget);

      bloc.add(const DrinkPressed('potion-1'));
      await tester.pumpAndSettle();

      expect(find.text('×2 · heals 10'), findsNothing);
      expect(find.text('×1 · heals 10'), findsOneWidget);
    },
  );

  testWidgets('Mend casts straight from the row outside combat', (
    tester,
  ) async {
    final bloc = await _openCrawl(
      tester,
      _exploringGame(knownSpells: const {'mend'}, mana: 10),
    );
    final manaBefore = bloc.state.game.mana;

    await tester.tap(_slot('menu-spells'));
    await tester.pumpAndSettle();
    await tester.tap(_slot('spell:mend'));
    await tester.pumpAndSettle();

    expect(bloc.state.game.mana, lessThan(manaBefore));
    expect(bloc.state.armedSpellId, isNull);
    expect(
      bloc.state.log.map((line) => line.sentence),
      contains(contains('mend')),
    );
  });

  testWidgets(
    'Firebolt with a visible monster arms from the Spells slot, and a map '
    'tap on the monster casts it',
    (tester) async {
      final bloc = await _openCrawl(
        tester,
        _battleGame(knownSpells: const {'firebolt'}, mana: 10),
      );

      await tester.tap(_slot('menu-spells'));
      await tester.pumpAndSettle();
      await tester.tap(_slot('spell:firebolt'));
      await tester.pumpAndSettle();

      expect(bloc.state.armedSpellId, 'firebolt');
      expect(bloc.state.armedTargets, contains('ghoul-1'));

      final hpBefore = bloc.state.game.monsters.single.hp;
      await _tapTile(tester, _adjacentToHero);
      await tester.pumpAndSettle();

      expect(bloc.state.armedSpellId, isNull);
      expect(bloc.state.game.monsters.single.hp, lessThan(hpBefore));
    },
  );

  testWidgets('an armed cast fires at the tile actually tapped, not simply the '
      'nearest legal target', (tester) async {
    final game = _crawl(
      monsters: [
        _actor('ghoul-1', _adjacentToHero, glyph: 'g'),
        _actor('ghoul-2', _distantTile, glyph: 'g'),
      ],
      knownSpells: const {'firebolt'},
      mana: 10,
    );
    final bloc = await _openCrawl(tester, game);

    await tester.tap(_slot('menu-spells'));
    await tester.pumpAndSettle();
    await tester.tap(_slot('spell:firebolt'));
    await tester.pumpAndSettle();

    expect(bloc.state.armedTargets, {'ghoul-1', 'ghoul-2'});

    await _tapTile(tester, _distantTile);
    await tester.pumpAndSettle();

    Actor monster(String id) =>
        bloc.state.game.monsters.firstWhere((actor) => actor.id == id);
    expect(monster('ghoul-2').hp, lessThan(10));
    expect(monster('ghoul-1').hp, 10);
    expect(bloc.state.armedSpellId, isNull);
  });

  testWidgets('arming a second spell disarms the first', (tester) async {
    final bloc = await _openCrawl(
      tester,
      _battleGame(knownSpells: const {'firebolt', 'bind'}, mana: 10),
    );

    await tester.tap(_slot('menu-spells'));
    await tester.pumpAndSettle();
    await tester.tap(_slot('spell:firebolt'));
    await tester.pumpAndSettle();
    expect(bloc.state.armedSpellId, 'firebolt');

    await tester.tap(_slot('menu-spells'));
    await tester.pumpAndSettle();
    await tester.tap(_slot('spell:bind'));
    await tester.pumpAndSettle();

    expect(bloc.state.armedSpellId, 'bind');
    await tester.tap(_slot('menu-spells'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: _slot('spell:bind'), matching: find.text('— armed')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: _slot('spell:firebolt'),
        matching: find.text('— armed'),
      ),
      findsNothing,
    );
  });

  testWidgets(
    'Firebolt with nothing in sight is shown refused, and its tap logs the '
    'refusal without spending a turn',
    (tester) async {
      final bloc = await _openCrawl(
        tester,
        _exploringGame(knownSpells: const {'firebolt'}, mana: 10),
      );
      final gameBefore = bloc.state.game;

      await tester.tap(_slot('menu-spells'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: _slot('spell:firebolt'),
          matching: find.text('No enemy in sight'),
        ),
        findsOneWidget,
      );

      await tester.tap(_slot('spell:firebolt'));
      await tester.pumpAndSettle();

      expect(bloc.state.game, same(gameBefore));
      expect(bloc.state.armedSpellId, isNull);
      expect(
        bloc.state.log.map((line) => line.sentence),
        contains('No enemy in sight.'),
      );
    },
  );

  testWidgets(
    'five known spells show three readied rows and an overflow that opens '
    'the grimoire listing all five, and choosing the armed spell again '
    'disarms it',
    (tester) async {
      final bloc = await _openCrawl(
        tester,
        _battleGame(
          knownSpells: const {'firebolt', 'mend', 'ward', 'bind', 'banish'},
          mana: 20,
        ),
      );

      await tester.tap(_slot('menu-spells'));
      await tester.pumpAndSettle();
      expect(find.text('+2 more spells'), findsOneWidget);

      await tester.tap(_slot('spells-overflow'));
      await tester.pumpAndSettle();
      for (final id in ['firebolt', 'mend', 'ward', 'bind', 'banish']) {
        expect(find.byKey(Key('overflow-$id')), findsOneWidget, reason: id);
      }
      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();

      await tester.tap(_slot('menu-spells'));
      await tester.pumpAndSettle();
      await tester.tap(_slot('spell:firebolt'));
      await tester.pumpAndSettle();
      expect(bloc.state.armedSpellId, 'firebolt');

      await tester.tap(_slot('menu-spells'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: _slot('spell:firebolt'),
          matching: find.text('— armed'),
        ),
        findsOneWidget,
      );
      await tester.tap(_slot('spell:firebolt'));
      await tester.pumpAndSettle();

      expect(bloc.state.armedSpellId, isNull);
    },
  );

  testWidgets(
    'the overflow sheet arms a spell that has no row on the shelf itself',
    (tester) async {
      final bloc = await _openCrawl(
        tester,
        _battleGame(
          knownSpells: const {'firebolt', 'mend', 'ward', 'bind'},
          mana: 10,
        ),
      );

      await tester.tap(_slot('menu-spells'));
      await tester.pumpAndSettle();
      expect(_slot('spell:bind'), findsNothing);

      await tester.tap(_slot('spells-overflow'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('overflow-bind')));
      await tester.pumpAndSettle();

      expect(bloc.state.armedSpellId, 'bind');
    },
  );

  testWidgets(
    'each slot shows only its mark and label, with no metadata text and no '
    'count in its semantics label',
    (tester) async {
      final bloc = await _openCrawl(
        tester,
        _battleGame(
          knownSpells: const {'firebolt'},
          mana: 10,
          inventory: const [
            Item(id: 'potion-1', base: healingPotion, rarity: Rarity.common),
            Item(id: 'potion-2', base: healingPotion, rarity: Rarity.common),
          ],
        ),
      );
      await tester.tap(_slot('menu-spells'));
      await tester.pumpAndSettle();
      await tester.tap(_slot('spell:firebolt'));
      await tester.pumpAndSettle();
      expect(bloc.state.armedSpellId, 'firebolt');

      const expectedLabels = {
        'menu-quests': 'Quests, unavailable',
        'menu-spells': 'Spells, armed',
        'menu-quick': 'Quick',
        'menu-hero': 'Hero',
      };
      final handle = tester.ensureSemantics();
      try {
        for (final entry in expectedLabels.entries) {
          final slot = _slot(entry.key);
          expect(
            find.descendant(of: slot, matching: find.byType(Text)),
            findsOneWidget,
            reason: entry.key,
          );
          for (final needle in ['×', '/', 'armed']) {
            expect(
              find.descendant(of: slot, matching: find.textContaining(needle)),
              findsNothing,
              reason: '${entry.key} contains "$needle"',
            );
          }
          expect(
            tester.getSemantics(slot).label,
            entry.value,
            reason: entry.key,
          );
        }
      } finally {
        handle.dispose();
      }
    },
  );

  testWidgets(
    'the mark sits above the label, both centred in the slot, at text scale '
    '1.0 and 1.3',
    (tester) async {
      final game = _battleGame(
        knownSpells: const {'firebolt'},
        mana: 10,
        inventory: const [
          Item(id: 'potion-1', base: healingPotion, rarity: Rarity.common),
          Item(id: 'potion-2', base: healingPotion, rarity: Rarity.common),
        ],
      );
      const slotIds = ['menu-quests', 'menu-spells', 'menu-quick', 'menu-hero'];

      await _openCrawl(tester, game);
      for (final id in slotIds) {
        _expectCentred(tester, _slot(id));
      }

      await _openCrawl(tester, game, textScaler: const TextScaler.linear(1.3));
      for (final id in slotIds) {
        _expectCentred(tester, _slot(id));
      }
    },
  );

  testWidgets(
    'the armed Spells slot frame is 3 dp; the other slots and disarming '
    'stay thinner',
    (tester) async {
      final bloc = await _openCrawl(
        tester,
        _battleGame(knownSpells: const {'firebolt'}, mana: 10),
      );

      await tester.tap(_slot('menu-spells'));
      await tester.pumpAndSettle();
      await tester.tap(_slot('spell:firebolt'));
      await tester.pumpAndSettle();
      expect(bloc.state.armedSpellId, 'firebolt');

      expect(_frameOf(tester, _slot('menu-spells')).width, 3);
      for (final id in ['menu-quests', 'menu-quick', 'menu-hero']) {
        expect(_frameOf(tester, _slot(id)).width, isNot(3), reason: id);
      }

      await tester.tap(_slot('menu-spells'));
      await tester.pumpAndSettle();
      await tester.tap(_slot('spell:firebolt'));
      await tester.pumpAndSettle();
      expect(bloc.state.armedSpellId, isNull);
      expect(_frameOf(tester, _slot('menu-spells')).width, isNot(3));
    },
  );
}
