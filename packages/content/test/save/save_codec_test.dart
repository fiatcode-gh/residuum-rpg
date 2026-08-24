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
      expect(written['version'], 1);
      expect(saveVersion, 1);
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
      const written = '{"version": 1, "profile":';

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
      written['version'] = 2;

      // act
      final reason = _reason(jsonEncode(written));

      // assert
      expect(reason, contains('2'));
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
      const written = '{"version": 2, "heroes": "nonsense"}';

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
        '{"version": 1}',
        '{"version": "1"}',
        '{"version": 1, "profile": {}}',
        '{"version": 1, "active": "hero-1"}',
        '{"version": 1, "active": "hero-1", "heroes": {}}',
        '{"version": 1, "active": "hero-1", "heroes": null}',
        '{"version": 1, "active": "hero-1", "heroes": {"hero-1": {}}}',
        '{"version": 1, "active": 7, "heroes": {"hero-1": {}}}',
        '{"version": 1, "heroes": {"hero-1": {"label": "x"}}}',
      ];

      // act
      final reads = [for (final written in nonsense) decodeSave(written)];

      // assert
      expect(reads, everyElement(isA<SaveFailure>()));
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
