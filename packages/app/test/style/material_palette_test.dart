import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/pack_screen.dart';
import 'package:residuum_app/style/tokens.dart' as tokens;
import 'package:residuum_app/town/character_screen.dart';
import 'package:residuum_app/town/forge_screen.dart';
import 'package:residuum_app/town/gear_screen.dart';
import 'package:residuum_app/town/roster_screen.dart';
import 'package:residuum_app/town/tavern_screen.dart';
import 'package:residuum_app/town/town_bloc.dart';
import 'package:residuum_app/world/world_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../support/phone.dart';

/// Built once, from a bare Material 3 dark theme with nothing else set — the
/// same shape `main.dart` builds today. No lavender hex is ever written down
/// here: if the framework's default palette ever moves, this reference moves
/// with it and the "must not equal" assertions below stay honest.
final ThemeData m3 = ThemeData(brightness: Brightness.dark, useMaterial3: true);

const _arena = '''
#######
#.....#
#.....#
#######''';

Item _item(String id, BaseItem base) =>
    Item(id: id, base: base, rarity: Rarity.common);

Profile _hero({
  List<Item> inventory = const [],
  Equipment equipment = const {},
  Map<MaterialId, int> materials = const {},
  int gold = 0,
}) => newProfile(worldSeed: 4).copyWith(
  inventory: inventory,
  equipment: equipment,
  materials: materials,
  gold: gold,
);

GameState _crawl({List<Item> inventory = const []}) {
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
      hp: 20,
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
    inventory: inventory,
    equipment: const {},
    materials: const {},
    skills: untrainedSkills,
    spells: spellsById,
    knownSpells: const {},
    mana: 10,
  );
}

SaveDocument _twoHeroes() => SaveDocument(
  active: 'hero-2',
  heroes: {
    'hero-1': SavedHero(label: 'Ilse', profile: newProfile(worldSeed: 111)),
    'hero-2': SavedHero(label: 'Bram', profile: newProfile(worldSeed: 222)),
  },
);

/// The `Material` every stock button and dialog paints itself onto:
/// [Material.color] is the rendered fill and [Material.textStyle]'s colour
/// is the rendered foreground, both resolved by the framework from the
/// active theme rather than typed in by this test.
Material _materialOf(WidgetTester tester, Finder control) =>
    tester.widget<Material>(
      find.descendant(of: control, matching: find.byType(Material)).first,
    );

Color _fillOf(WidgetTester tester, Finder control) =>
    _materialOf(tester, control).color!;

Color _foregroundOf(WidgetTester tester, Finder control) =>
    _materialOf(tester, control).textStyle!.color!;

/// A chip's fill is painted by its own `Ink`, not by a `Material.color` —
/// unlike every button and dialog in this table.
Color? _chipFillOf(WidgetTester tester, Finder control) {
  final decoration =
      tester
              .widget<Ink>(
                find.descendant(of: control, matching: find.byType(Ink)).first,
              )
              .decoration
          as ShapeDecoration?;
  return decoration?.color;
}

Future<TownBloc> _pumpCharacterScreen(
  WidgetTester tester,
  Profile profile,
) async {
  await onAPhone(tester);
  final town = TownBloc(profile: profile);
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider.value(value: town, child: const CharacterScreen()),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(town.close);
  return town;
}

/// One town room, under a real town bloc and a real world bloc — the same
/// shape every town room is actually mounted in.
Future<TownBloc> _pumpTownRoom(
  WidgetTester tester,
  Widget room,
  Profile profile,
) async {
  await onAPhone(tester);
  final town = TownBloc(profile: profile);
  final world = WorldBloc(
    world: newWhereabouts(),
    worldSeed: profile.worldSeed,
  );
  await tester.pumpWidget(
    MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: town),
          BlocProvider.value(value: world),
        ],
        child: room,
      ),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(town.close);
  addTearDown(world.close);
  return town;
}

Future<GameBloc> _pumpPack(WidgetTester tester, GameState game) async {
  final bloc = GameBloc(game: game, stepDelay: Duration.zero);
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider.value(value: bloc, child: const CrawlPackScreen()),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(bloc.close);
  return bloc;
}

Future<void> _pumpRoster(WidgetTester tester, SaveDocument document) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push<RosterChoice>(
            MaterialPageRoute<RosterChoice>(
              builder: (_) => RosterScreen(document: document),
            ),
          ),
          child: const Text('open roster'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open roster'));
  await tester.pumpAndSettle();
}

void main() {
  group("AC4's named case: character navigation", () {
    testWidgets('all four route buttons render raised, not M3 primary', (
      tester,
    ) async {
      await _pumpCharacterScreen(tester, _hero());

      for (final key in [
        'character-route-gear',
        'character-route-spells',
        'character-route-skills',
        'character-route-pack',
      ]) {
        final button = find.byKey(Key(key));
        final fill = _fillOf(tester, button);
        expect(fill, tokens.raised, reason: key);
        expect(fill, isNot(m3.colorScheme.primary), reason: key);
      }
    });
  });

  group("AC4's named case: the pack filter chips", () {
    testWidgets(
      'the selected filter renders armedFill, not M3 secondaryContainer',
      (tester) async {
        await _pumpPack(tester, _crawl());

        final fill = _chipFillOf(
          tester,
          find.byKey(const Key('pack-filter-all')),
        );
        expect(fill, tokens.armedFill);
        expect(fill, isNot(m3.colorScheme.secondaryContainer));
      },
    );

    testWidgets(
      'an unselected filter renders raised, not M3 surfaceContainerLow',
      (tester) async {
        await _pumpPack(tester, _crawl());

        final fill = _chipFillOf(
          tester,
          find.byKey(const Key('pack-filter-potions')),
        );
        expect(fill, tokens.raised);
        expect(fill, isNot(m3.colorScheme.surfaceContainerLow));
      },
    );
  });

  group("AC4's named case: the Forge's Smelt", () {
    testWidgets('an enabled Smelt renders raised, not M3 primary', (
      tester,
    ) async {
      await _pumpTownRoom(
        tester,
        const ForgeScreen(),
        _hero(materials: const {MaterialId.ore: 4}),
      );
      await tester.tap(find.text('+'));
      await tester.pump();

      final smelt = find.widgetWithText(FilledButton, 'Smelt');
      final fill = _fillOf(tester, smelt);
      expect(fill, tokens.raised);
      expect(fill, isNot(m3.colorScheme.primary));
    });
  });

  group("AC4's named case: the Tavern's Ask", () {
    testWidgets('renders raised, not M3 primary', (tester) async {
      await _pumpTownRoom(tester, const TavernScreen(), _hero(gold: 100));

      final ask = find.widgetWithText(FilledButton, 'Ask $rumorPrice');
      final fill = _fillOf(tester, ask);
      expect(fill, tokens.raised);
      expect(fill, isNot(m3.colorScheme.primary));
    });
  });

  group('F9 row 6 (not named): gear take-off', () {
    testWidgets('renders raised, not M3 primary', (tester) async {
      await _pumpTownRoom(
        tester,
        const GearScreen(),
        _hero(equipment: {EquipSlot.chest: _item('jerkin-1', leatherJerkin)}),
      );

      final takeOff = find.byKey(const Key('gear-take-off-chest'));
      final fill = _fillOf(tester, takeOff);
      expect(fill, tokens.raised);
      expect(fill, isNot(m3.colorScheme.primary));
    });
  });

  group('F9 row 7 (not named): a pack row action, foreground', () {
    testWidgets('drop renders ink, not M3 primary', (tester) async {
      await _pumpPack(
        tester,
        _crawl(inventory: [_item('potion-1', healingPotion)]),
      );

      final drop = find.byKey(const Key('pack-drop-potion-1'));
      final foreground = _foregroundOf(tester, drop);
      expect(foreground, tokens.ink);
      expect(foreground, isNot(m3.colorScheme.primary));
    });
  });

  group('F9 row 8 (not named): the roster delete dialog', () {
    testWidgets('the surface renders panel, not M3 surface', (tester) async {
      await _pumpRoster(tester, _twoHeroes());
      await tester.tap(find.text('Delete').first);
      await tester.pumpAndSettle();

      final fill = _fillOf(tester, find.byType(Dialog));
      expect(fill, tokens.panel);
      expect(fill, isNot(m3.colorScheme.surface));
    });

    testWidgets('both actions render ink foreground, not M3 primary', (
      tester,
    ) async {
      await _pumpRoster(tester, _twoHeroes());
      await tester.tap(find.text('Delete').first);
      await tester.pumpAndSettle();

      for (final label in ['Keep this hero', 'Delete this hero']) {
        final action = find.widgetWithText(TextButton, label);
        final foreground = _foregroundOf(tester, action);
        expect(foreground, tokens.ink, reason: label);
        expect(foreground, isNot(m3.colorScheme.primary), reason: label);
      }
    });
  });

  group('F9 row 9 (not named): the roster name dialog', () {
    testWidgets(
      "the TextField's focused border and cursor render ink, not M3 primary",
      (tester) async {
        await _pumpRoster(tester, _twoHeroes());
        await tester.tap(find.text('New hero'));
        await tester.pumpAndSettle();

        final decorator = tester.widget<InputDecorator>(
          find.byType(InputDecorator),
        );
        final borderColor =
            decorator.decoration.focusedBorder?.borderSide.color;
        final editable = tester.widget<EditableText>(find.byType(EditableText));
        final cursorColor = editable.cursorColor;

        expect(borderColor, tokens.ink);
        expect(borderColor, isNot(m3.colorScheme.primary));
        expect(cursorColor, tokens.ink);
        expect(cursorColor, isNot(m3.colorScheme.primary));
      },
    );
  });

  group('neither state is told apart by hue alone', () {
    testWidgets('the selected filter chip still renders a checkmark', (
      tester,
    ) async {
      await _pumpPack(tester, _crawl());

      expect(
        find.byKey(const Key('pack-filter-all')),
        paints..something((method, arguments) {
          if (method != #drawPath) return false;
          final paint = arguments[1] as Paint;
          return paint.style == PaintingStyle.stroke &&
              isSameColorAs(tokens.ink).matches(paint.color, {});
        }),
      );
    });

    testWidgets('a disabled Smelt reads dimmer than an enabled one', (
      tester,
    ) async {
      await _pumpTownRoom(
        tester,
        const ForgeScreen(),
        _hero(materials: const {MaterialId.ore: 4}),
      );
      final smelt = find.widgetWithText(FilledButton, 'Smelt');

      final disabledFill = _fillOf(tester, smelt);
      final disabledLabel = _foregroundOf(tester, smelt);

      await tester.tap(find.text('+'));
      await tester.pump();

      final enabledFill = _fillOf(tester, smelt);
      final enabledLabel = _foregroundOf(tester, smelt);

      expect(
        disabledFill.computeLuminance(),
        lessThan(enabledFill.computeLuminance()),
      );
      expect(
        disabledLabel.computeLuminance(),
        lessThan(enabledLabel.computeLuminance()),
      );
    });
  });
}
