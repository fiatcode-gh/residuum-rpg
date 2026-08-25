import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

const _room = '''
#######
#.....#
#######''';

const Spell _firebolt = Spell(
  id: 'firebolt',
  name: 'Firebolt',
  school: SkillId.wrath,
  manaCost: 2,
  requiredLevel: 0,
  kind: SpellKind.bolt,
  type: DamageType.fire,
  min: 2,
  max: 4,
);

const Spell _frostLance = Spell(
  id: 'frost-lance',
  name: 'Frost Lance',
  school: SkillId.wrath,
  manaCost: 4,
  requiredLevel: 4,
  kind: SpellKind.bolt,
  type: DamageType.frost,
  min: 4,
  max: 7,
);

const Map<String, Spell> _spells = {
  'firebolt': _firebolt,
  'frost-lance': _frostLance,
};

const BaseItem _boltBook = BaseItem(
  id: 'book-of-firebolt',
  name: 'Book of Firebolt',
  glyph: '?',
  teaches: 'firebolt',
);

const BaseItem _lanceBook = BaseItem(
  id: 'book-of-frost-lance',
  name: 'Book of Frost Lance',
  glyph: '?',
  teaches: 'frost-lance',
);

const BaseItem _potion = BaseItem(
  id: 'healing-potion',
  name: 'Healing Potion',
  glyph: '!',
  heal: 10,
);

Item _carried(String id, BaseItem base) =>
    Item(id: id, base: base, rarity: Rarity.common);

GameState _reader({
  List<Item> inventory = const [],
  Set<String> knownSpells = const {},
  Map<SkillId, SkillState> skills = untrainedSkills,
}) => crawl(
  ascii: _room,
  heroAt: const Position(1, 1),
  inventory: inventory,
  knownSpells: knownSpells,
  skills: skills,
  spells: _spells,
);

String _reasonOf(List<GameEvent> events) =>
    (events.single as ActionRefused).reason;

void main() {
  group('reading a book in the dungeon', () {
    test('learns the spell, spends the book and says so', () {
      // arrange
      final game = _reader(inventory: [_carried('kit-4', _boltBook)]);

      // act
      final (after, events) = step(game, const ReadAction('kit-4'));

      // assert
      expect(after.knownSpells, {'firebolt'});
      expect(after.inventory, isEmpty);
      expect(
        events,
        contains(
          SpellLearned(book: _carried('kit-4', _boltBook), spell: _firebolt),
        ),
      );
    });

    test('costs the turn, exactly as drinking does', () {
      // arrange
      final game = _reader(inventory: [_carried('kit-4', _boltBook)]);

      // act
      final (after, _) = step(game, const ReadAction('kit-4'));

      // assert - reading is a turn spent standing still with a book open
      expect(after.hero.energy, game.hero.energy);
      expect(after.hero.position, game.hero.position);
    });

    test('refuses a book the hero is not carrying', () {
      // arrange
      final game = _reader();

      // act
      final (after, events) = step(game, const ReadAction('kit-4'));

      // assert
      expect(_reasonOf(events), 'you are not carrying that');
      expect(after, same(game));
    });

    test('refuses something that is not a book, and names it', () {
      // arrange
      final game = _reader(inventory: [_carried('kit-2', _potion)]);

      // act
      final (_, events) = step(game, const ReadAction('kit-2'));

      // assert
      expect(_reasonOf(events), 'Healing Potion is not something to read');
    });

    test('refuses a spell the hero already knows', () {
      // arrange
      final game = _reader(
        inventory: [_carried('kit-4', _boltBook)],
        knownSpells: const {'firebolt'},
      );

      // act
      final (_, events) = step(game, const ReadAction('kit-4'));

      // assert
      expect(_reasonOf(events), 'you already know Firebolt');
    });

    test('refuses a book past the school gate, and names the gate', () {
      // arrange
      final game = _reader(inventory: [_carried('kit-5', _lanceBook)]);

      // act
      final (_, events) = step(game, const ReadAction('kit-5'));

      // assert - a sentence, never a greyed-out row
      expect(_reasonOf(events), 'needs Wrath 4');
    });

    test('lets the book through the moment the school reaches the gate', () {
      // arrange
      final game = _reader(
        inventory: [_carried('kit-5', _lanceBook)],
        skills: {...untrainedSkills, SkillId.wrath: const SkillState(level: 4)},
      );

      // act
      final (after, _) = step(game, const ReadAction('kit-5'));

      // assert
      expect(after.knownSpells, {'frost-lance'});
    });

    test('does NOT refuse a book the hero could have saved for later', () {
      // arrange - nothing to cast at, no mana worth spending, no reason to read
      // it now rather than at the camp
      final game = _reader(inventory: [_carried('kit-4', _boltBook)]);

      // act
      final (after, events) = step(game, const ReadAction('kit-4'));

      // assert - the Drink doctrine: a wasteful use is the player's mistake to
      // make, and not the rules' to undo
      expect(events.whereType<ActionRefused>(), isEmpty);
      expect(after.knownSpells, {'firebolt'});
    });

    test('spends only the book that was read', () {
      // arrange
      final game = _reader(
        inventory: [
          _carried('kit-2', _potion),
          _carried('kit-4', _boltBook),
          _carried('kit-5', _lanceBook),
        ],
      );

      // act
      final (after, _) = step(game, const ReadAction('kit-4'));

      // assert
      expect(after.inventory.map((item) => item.id), ['kit-2', 'kit-5']);
    });

    test('refuses a book of a spell this build does not cast', () {
      // arrange
      final game = crawl(
        ascii: _room,
        heroAt: const Position(1, 1),
        inventory: [_carried('kit-4', _boltBook)],
      );

      // act
      final (_, events) = step(game, const ReadAction('kit-4'));

      // assert
      expect(
        _reasonOf(events),
        'Book of Firebolt is written in a hand you cannot read',
      );
    });
  });

  group('reading a book in town', () {
    Profile townie({
      List<Item> inventory = const [],
      Set<String> knownSpells = const {},
      Map<SkillId, SkillState> skills = untrainedSkills,
    }) => Profile(
      hero: hero(const Position(0, 0)),
      worldSeed: 1,
      inventory: inventory,
      knownSpells: knownSpells,
      skills: skills,
    );

    test('learns the spell and spends the book, and costs no gold', () {
      // arrange
      final profile = townie(
        inventory: [_carried('kit-4', _boltBook)],
      ).copyWith(gold: 30);

      // act
      final (after, refusal) = readBook(profile, 'kit-4', _spells);

      // assert - the hero deciding what to know, not a transaction with anyone
      expect(refusal, isNull);
      expect(after.knownSpells, {'firebolt'});
      expect(after.inventory, isEmpty);
      expect(after.gold, 30);
    });

    test('refuses past the gate in the dungeon\'s own words', () {
      // arrange
      final profile = townie(inventory: [_carried('kit-5', _lanceBook)]);

      // act
      final (after, refusal) = readBook(profile, 'kit-5', _spells);

      // assert - one rule, one set of words, two wrappers
      expect(refusal, const TownRefusal('needs Wrath 4'));
      expect(after, profile);
    });

    test('refuses a spell already known in the dungeon\'s own words', () {
      // arrange
      final profile = townie(
        inventory: [_carried('kit-4', _boltBook)],
        knownSpells: const {'firebolt'},
      );

      // act
      final (_, refusal) = readBook(profile, 'kit-4', _spells);

      // assert
      expect(refusal, const TownRefusal('you already know Firebolt'));
    });

    test('refuses what the hero is not carrying', () {
      // arrange
      final profile = townie();

      // act
      final (_, refusal) = readBook(profile, 'kit-4', _spells);

      // assert
      expect(refusal, const TownRefusal('you are not carrying that'));
    });

    test('refuses something that is not a book', () {
      // arrange
      final profile = townie(inventory: [_carried('kit-2', _potion)]);

      // act
      final (_, refusal) = readBook(profile, 'kit-2', _spells);

      // assert
      expect(
        refusal,
        const TownRefusal('Healing Potion is not something to read'),
      );
    });
  });
}
