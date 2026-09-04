import 'dart:convert';

import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import 'support/deep_run.dart';

SaveDocument _readOrFail(String written) {
  final read = decodeSave(written);
  return read is SaveDocument
      ? read
      : (throw StateError('expected a document, got $read'));
}

String _reason(String written) {
  final read = decodeSave(written);
  return read is SaveFailure
      ? read.reason
      : (throw StateError('expected a failure, got a document'));
}

Map<String, Object?> _asMap(String written) =>
    jsonDecode(written) as Map<String, Object?>;

/// A one-hero document, which is what every single-hero test here is about.
String _save(Profile profile, {GameState? run}) => encodeSave(
  SaveDocument.one(
    id: 'hero-1',
    label: 'Hero 1',
    profile: profile,
    run: run,
    dungeon: run == null ? null : cryptNode,
    campDay: run == null ? null : 0,
  ),
);

Map<String, Object?> _heroBlock(Map<String, Object?> document) =>
    (document['heroes']! as Map<String, Object?>)['hero-1']!
        as Map<String, Object?>;

Map<String, Object?> _profileBlock(Map<String, Object?> document) =>
    _heroBlock(document)['profile']! as Map<String, Object?>;

Map<String, Object?> _runBlock(Map<String, Object?> document) =>
    _heroBlock(document)['run']! as Map<String, Object?>;

Map<String, Object?> _wornSword(Map<String, Object?> document) =>
    (_profileBlock(document)['equipment']! as Map<String, Object?>)['mainHand']!
        as Map<String, Object?>;

/// A ghoul standing one tile off, with [hp] hit points against a body of 12.
Map<String, Object?> _ghoul({required int hp}) => {
  'id': 'ghoul-1',
  'name': 'the ghoul',
  'glyph': 'g',
  'x': 1,
  'y': 2,
  'hp': hp,
  'maxHp': 12,
  'attackMin': 1,
  'attackMax': 2,
  'speed': 10,
  'energy': 40,
  'dropChance': 0,
  'pierce': 0,
  'resists': <Object?>[],
  'vulnerableTo': <Object?>[],
};

/// The run's war-axe, reworked with of-vigour: the ceiling rises to 26.
Map<String, Object?> _vigourousAxe() => {
  'id': 'drop-3',
  'base': 'war-axe',
  'rarity': 'rare',
  'affixes': ['of-vigour'],
  'temper': 0,
};

/// A leather cap worked with of-vigour, worn on the head: the ceiling rises
/// to 26 for the profile side of the same check.
Map<String, Object?> _vigourousCap() => {
  'id': 'kit-9',
  'base': 'leather-cap',
  'rarity': 'fine',
  'affixes': ['of-vigour'],
  'temper': 0,
};

void main() {
  group('the save document', () {
    test('a hero in town round-trips with no run block', () {
      // arrange
      final profile = newProfile(worldSeed: 12345).copyWith(gold: 77, visit: 2);

      // act
      final document = _readOrFail(_save(profile));

      // assert
      expect(document.profile, profile);
      expect(document.run, isNull);
    });

    test('a suspended crawl round-trips beside its profile', () {
      // arrange
      final profile = newProfile(worldSeed: 7);
      final run = deepRun();

      // act
      final document = _readOrFail(_save(profile, run: run));

      // assert
      expect(document.profile, profile);
      expect(document.run, isNotNull);
      expect(document.run!.depth, run.depth);
      expect(document.run!.rng.state, run.rng.state);
      expect(document.run!.floors.keys.toList()..sort(), [1, 2, 3, 4]);
    });

    test('the version is the first field written', () {
      // arrange
      final profile = newProfile();

      // act
      final written = _asMap(_save(profile));

      // assert
      expect(written.keys.first, 'version');
      expect(written['version'], saveVersion);
    });

    test('being in town is written out, not left out', () {
      // arrange
      final profile = newProfile();

      // act
      final written = _asMap(_save(profile));

      // assert
      expect(_heroBlock(written).containsKey('run'), isTrue);
      expect(_heroBlock(written)['run'], isNull);
    });

    test('malformed JSON is refused with a sentence', () {
      // arrange
      const written = '{"version": 2, "profile":';

      // act
      final reason = _reason(written);

      // assert
      expect(reason, contains('could not be read'));
    });

    test('a document that is not an object is refused', () {
      // arrange
      const written = '[1, 2, 3]';

      // act
      final reason = _reason(written);

      // assert
      expect(reason, isNotEmpty);
    });

    test('a version this build does not know is refused by number', () {
      // arrange
      final written = _asMap(_save(newProfile()));
      written['version'] = 99;

      // act
      final reason = _reason(jsonEncode(written));

      // assert - ninety-nine rather than one past this build's own number, so
      // the next sanctioned break does not have to come back and edit this
      expect(reason, contains('99'));
      expect(reason, contains('version'));
    });

    test('a document with no version at all is refused', () {
      // arrange
      final written = _asMap(_save(newProfile()))..remove('version');

      // act
      final reason = _reason(jsonEncode(written));

      // assert
      expect(reason, contains('version'));
    });

    test('the version is checked before any other field is touched', () {
      // arrange
      const written = '{"version": 99, "heroes": "nonsense"}';

      // act
      final reason = _reason(written);

      // assert
      expect(reason, contains('version'));
      expect(reason, isNot(contains('heroes')));
    });

    test('a missing field is refused by name', () {
      // arrange
      final written = _asMap(_save(newProfile()));
      _profileBlock(written).remove('bankedGold');

      // act
      final reason = _reason(jsonEncode(written));

      // assert
      expect(reason, contains('bankedGold'));
    });

    test('an unknown base item id is refused by name', () {
      // arrange
      final written = _asMap(_save(newProfile()));
      _wornSword(written)['base'] = 'mithril-sword';

      // act
      final reason = _reason(jsonEncode(written));

      // assert
      expect(reason, contains('mithril-sword'));
    });

    test('an unknown affix id is refused by name', () {
      // arrange
      final written = _asMap(_save(newProfile()));
      _wornSword(written)['affixes'] = <Object?>['of-frost'];

      // act
      final reason = _reason(jsonEncode(written));

      // assert
      expect(reason, contains('of-frost'));
    });

    test('a wide field written as a number is refused', () {
      // arrange
      final written = _asMap(_save(newProfile()));
      _profileBlock(written)['worldSeed'] = 9007199254740993;

      // act
      final reason = _reason(jsonEncode(written));

      // assert
      expect(reason, contains('worldSeed'));
    });

    test("a run's stream state written as a number is refused", () {
      // arrange
      final written = _asMap(_save(newProfile(), run: deepRun(depth: 1)));
      _runBlock(written)['rngState'] = -8613303245920329199;

      // act
      final reason = _reason(jsonEncode(written));

      // assert
      expect(reason, contains('rngState'));
    });

    test('a full-width seed and both stream states survive exactly', () {
      // arrange
      final profile = newProfile(worldSeed: 9007199254740993);
      final run = deepRun(worldSeed: 9007199254740993, depth: 2);

      // act
      final document = _readOrFail(_save(profile, run: run));

      // assert
      expect(document.profile.worldSeed, 9007199254740993);
      expect(document.run!.worldSeed, 9007199254740993);
      expect(document.run!.rng.state, -8613303245920329199);
      expect(document.run!.lootRng.state, 2420599403871909411);
    });

    test('small counted fields stay numbers', () {
      // arrange
      final profile = newProfile().copyWith(gold: 41, bankedGold: 380);

      // act
      final written = _profileBlock(_asMap(_save(profile)));

      // assert
      expect(written['gold'], isA<int>());
      expect(written['bankedGold'], isA<int>());
      expect(written['hp'], isA<int>());
      expect(written['visit'], isA<int>());
    });

    test('nothing throws past the codec, whatever it is handed', () {
      // arrange
      const nonsense = [
        '',
        'null',
        '{}',
        '{"version": 2}',
        '{"version": "2"}',
        '{"version": 2, "profile": {}}',
        '{"version": 2, "active": "hero-1"}',
        '{"version": 2, "active": "hero-1", "heroes": {}}',
        '{"version": 2, "active": "hero-1", "heroes": null}',
        '{"version": 2, "active": "hero-1", "heroes": {"hero-1": {}}}',
        '{"version": 2, "active": 7, "heroes": {"hero-1": {}}}',
        '{"version": 2, "heroes": {"hero-1": {"label": "x"}}}',
      ];

      // act
      final reads = [for (final written in nonsense) decodeSave(written)];

      // assert
      expect(reads, everyElement(isA<SaveFailure>()));
    });

    test('a hero at speed zero is refused with a sentence', () {
      // arrange
      final run = deepRun(depth: 1);
      final written = _asMap(_save(newProfile(), run: run));
      (_runBlock(written)['hero']! as Map<String, Object?>)['speed'] = 0;

      // act
      final reason = _reason(jsonEncode(written));

      // assert
      expect(
        reason,
        'the save file has an actor with speed 0, and the clock would never '
        'move them',
      );
    });

    test('a monster at speed zero is refused with the same sentence', () {
      // arrange
      final run = deepRun(depth: 1);
      final written = _asMap(_save(newProfile(), run: run));
      (_runBlock(written)['monsters']! as List<Object?>).add(_ghoul(hp: 5));
      final monster =
          (_runBlock(written)['monsters']! as List<Object?>).last
              as Map<String, Object?>;
      monster['speed'] = 0;

      // act
      final reason = _reason(jsonEncode(written));

      // assert
      expect(
        reason,
        'the save file has an actor with speed 0, and the clock would never '
        'move them',
      );
    });

    test('an actor holding past the energy bound is refused', () {
      // arrange
      final run = deepRun(depth: 1);
      final written = _asMap(_save(newProfile(), run: run));
      (_runBlock(written)['hero']! as Map<String, Object?>)['energy'] =
          maxSaveEnergy + 1;

      // act
      final reason = _reason(jsonEncode(written));

      // assert
      expect(
        reason,
        'the save file has an actor holding ${maxSaveEnergy + 1} energy, and '
        'energy never leaves the range 0 to $maxSaveEnergy',
      );
    });

    test('an actor holding negative energy is refused', () {
      // arrange
      final run = deepRun(depth: 1);
      final written = _asMap(_save(newProfile(), run: run));
      (_runBlock(written)['hero']! as Map<String, Object?>)['energy'] = -1;

      // act
      final reason = _reason(jsonEncode(written));

      // assert
      expect(
        reason,
        'the save file has an actor holding -1 energy, and energy never '
        'leaves the range 0 to $maxSaveEnergy',
      );
    });

    test('a monster holding more than its body is refused', () {
      // arrange
      final run = deepRun(depth: 1);
      final written = _asMap(_save(newProfile(), run: run));
      (_runBlock(written)['monsters']! as List<Object?>).add(_ghoul(hp: 13));

      // act
      final reason = _reason(jsonEncode(written));

      // assert
      expect(
        reason,
        'the save file has the ghoul holding 13 hit points, and a body holds '
        'at most 12',
      );
    });

    test('a hero holding more than their gear allows is refused', () {
      // arrange — the run's hero wears no max-hp affix, so the ceiling is the
      // bare body: 20.
      final run = deepRun(depth: 1);
      final written = _asMap(_save(newProfile(), run: run));
      (_runBlock(written)['hero']! as Map<String, Object?>)['hp'] = 21;

      // act
      final reason = _reason(jsonEncode(written));

      // assert
      expect(
        reason,
        'the save file has the hero holding 21 hit points, and their gear '
        'holds at most 20',
      );
    });

    test('a hero holding what their gear allows decodes', () {
      // arrange — of-vigour lifts the ceiling to 26, and the hero stands at it.
      final run = deepRun(depth: 1);
      final written = _asMap(_save(newProfile(), run: run));
      final hero = _runBlock(written)['hero']! as Map<String, Object?>;
      hero['hp'] = 26;
      hero['maxHp'] = 20;
      (_runBlock(written)['equipment']! as Map<String, Object?>)['mainHand'] =
          _vigourousAxe();

      // act
      final read = decodeSave(jsonEncode(written));

      // assert
      expect(read, isA<SaveDocument>());
    });

    test('a hero holding one over their gear is refused', () {
      // arrange
      final run = deepRun(depth: 1);
      final written = _asMap(_save(newProfile(), run: run));
      final hero = _runBlock(written)['hero']! as Map<String, Object?>;
      hero['hp'] = 27;
      (_runBlock(written)['equipment']! as Map<String, Object?>)['mainHand'] =
          _vigourousAxe();

      // act
      final reason = _reason(jsonEncode(written));

      // assert
      expect(
        reason,
        'the save file has the hero holding 27 hit points, and their gear '
        'holds at most 26',
      );
    });

    test('an actor at negative hit points is refused', () {
      // arrange
      final run = deepRun(depth: 1);
      final written = _asMap(_save(newProfile(), run: run));
      (_runBlock(written)['hero']! as Map<String, Object?>)['hp'] = -1;

      // act
      final reason = _reason(jsonEncode(written));

      // assert
      expect(
        reason,
        'the save file has the hero holding -1 hit points, and nobody holds '
        'fewer than none',
      );
    });

    test('a profile above its ceiling is refused', () {
      // arrange
      final written = _asMap(_save(newProfile()));
      _profileBlock(written)['hp'] = 21;

      // act
      final reason = _reason(jsonEncode(written));

      // assert
      expect(
        reason,
        'the save file has a hero standing at 21 hit points, and their gear '
        'holds at most 20',
      );
    });

    test('a profile holding what its gear allows decodes', () {
      // arrange
      final written = _asMap(_save(newProfile()));
      _profileBlock(written)['hp'] = 26;
      (_profileBlock(written)['equipment']! as Map<String, Object?>)['head'] =
          _vigourousCap();

      // act
      final read = decodeSave(jsonEncode(written));

      // assert
      expect(read, isA<SaveDocument>());
    });

    test('a skill past the highest level is refused', () {
      // arrange
      final written = _asMap(_save(newProfile()));
      (_profileBlock(written)['skills']! as Map<String, Object?>)['arms'] = {
        'level': maxSkillLevel + 1,
        'xp': 0,
      };

      // act
      final reason = _reason(jsonEncode(written));

      // assert
      expect(
        reason,
        'the save file has the skill "arms" trained to level 101, and a '
        'skill goes to $maxSkillLevel',
      );
    });

    test('a skill holding negative experience is refused', () {
      // arrange
      final written = _asMap(_save(newProfile()));
      (_profileBlock(written)['skills']! as Map<String, Object?>)['arms'] =
          const {'level': 2, 'xp': -1};

      // act
      final reason = _reason(jsonEncode(written));

      // assert
      expect(
        reason,
        'the save file has the skill "arms" holding -1 experience, and '
        'nobody holds less than none',
      );
    });

    test('an actor reaching less than one tile is refused', () {
      // arrange
      final run = deepRun(depth: 1);
      final written = _asMap(_save(newProfile(), run: run));
      (_runBlock(written)['hero']! as Map<String, Object?>)['reach'] = 0;

      // act
      final reason = _reason(jsonEncode(written));

      // assert
      expect(
        reason,
        'the save file has an actor that strikes 0 tiles away, and nobody '
        'reaches less than one',
      );
    });

    test('two pack items under one id are refused', () {
      // arrange
      final written = _asMap(_save(newProfile()));
      final inventory = _profileBlock(written)['inventory']! as List<Object?>;
      inventory.add(inventory.first);

      // act
      final reason = _reason(jsonEncode(written));

      // assert
      expect(reason, 'the save file has two items named "kit-2"');
    });

    test('an id repeated across the bank and the pack is refused', () {
      // arrange
      final written = _asMap(_save(newProfile()));
      final bank = _profileBlock(written)['bank']! as List<Object?>;
      bank.add(
        (_profileBlock(written)['inventory']! as List<Object?>)[0]
            as Map<String, Object?>,
      );

      // act
      final reason = _reason(jsonEncode(written));

      // assert
      expect(reason, 'the save file has two items named "kit-2"');
    });

    test('a valid document still decodes whole', () {
      // arrange — the totality control: everything the new checks look at,
      // holding exactly what a real play produces.
      final run = deepRun();

      // act
      final document = _readOrFail(_save(newProfile(), run: run));

      // assert
      expect(document.run!.depth, run.depth);
      expect(document.run!.monsters, isNotEmpty);
    });

    test('a broken map in the run block is refused rather than parsed', () {
      // arrange
      final written = _asMap(_save(newProfile(), run: deepRun(depth: 1)));
      _runBlock(written)['map'] = '###\n##';

      // act
      final reason = _reason(jsonEncode(written));

      // assert
      expect(reason, contains('map'));
    });
  });
}
