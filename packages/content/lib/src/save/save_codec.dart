import 'dart:convert';

import 'profile_codec.dart';
import 'run_codec.dart';
import 'save_json.dart';
import 'save_read.dart';

/// The version this build writes, and the only one it reads.
///
/// First field of every document and checked before anything else is touched, so
/// a save from a future build is refused as a version rather than misread as a
/// shape. The fallback chain above the codec is what turns that refusal into the
/// previous snapshot.
const int saveVersion = 1;

/// One save document: every hero, and which of them is being played.
///
/// A hero's `run` of null is what being in town *is*. It is written out rather
/// than left out, so an entry always says which of the two states it describes
/// and a key that went missing is never read as "probably town".
///
/// Heroes are written in key order rather than in the map's own order, so one
/// roster always encodes to one document however it was assembled — the same
/// reason the position sets are sorted, and what makes the golden fixture a pin
/// rather than a coincidence.
String encodeSave(SaveDocument document) {
  final ids = document.heroes.keys.toList()..sort();
  return jsonEncode({
    'version': saveVersion,
    'active': document.active,
    'heroes': {for (final id in ids) id: _encodeHero(document.heroes[id]!)},
  });
}

Map<String, Object?> _encodeHero(SavedHero hero) => {
  'label': hero.label,
  'profile': encodeProfile(hero.profile),
  'run': hero.run == null ? null : encodeRun(hero.run!),
};

/// One save document, read back, or the reason it could not be.
///
/// A total function: malformed text, an unknown version, a missing field and an
/// id this build has never heard of all come back as a [SaveFailure] with a
/// sentence in it. Nothing throws past here.
///
/// **It never repairs.** A document that is wrong in any way is refused whole,
/// because the alternative is a hero who quietly lost a skill level or a floor —
/// and a save that half-loaded is worse than one that did not load at all: the
/// player cannot see what is missing, so they never get to choose the older slot
/// instead.
SaveRead decodeSave(String document) {
  final Object? parsed;
  try {
    parsed = jsonDecode(document);
  } on FormatException {
    return const SaveFailure('the save file could not be read at all');
  }
  if (parsed is! Map<String, Object?>) {
    return const SaveFailure('the save file is not a save');
  }
  try {
    final version = intAt(parsed, 'version');
    if (version != saveVersion) {
      return SaveFailure(
        'the save file is version $version and this build reads version '
        '$saveVersion',
      );
    }
    return _decodeRoster(parsed);
  } on SaveMalformed catch (malformed) {
    return SaveFailure(malformed.reason);
  }
}

/// The roster at the top of a version-1 document.
///
/// Two invariants are checked here rather than trusted, because both are things
/// a hand-edited or half-written file can break and neither can be recovered
/// from further down: a document with no heroes has nothing to play, and an
/// `active` id naming no hero would make the document say it is playing somebody
/// who does not exist. Refusing both by name is what lets [SaveDocument.hero]
/// be non-null everywhere above.
SaveRead _decodeRoster(Map<String, Object?> parsed) {
  final active = stringAt(parsed, 'active');
  final written = objectAt(parsed, 'heroes');
  if (written.isEmpty) {
    return const SaveFailure('the save file has no heroes in it');
  }
  final heroes = {
    for (final entry in written.entries)
      entry.key: _decodeHero(entry.key, entry.value),
  };
  if (!heroes.containsKey(active)) {
    return SaveFailure(
      'the save file is set to play a hero it does not contain: "$active"',
    );
  }
  return SaveDocument(active: active, heroes: heroes);
}

SavedHero _decodeHero(String id, Object? written) {
  if (written is! Map<String, Object?>) {
    throw SaveMalformed('the hero "$id" in the save file is not an object');
  }
  return SavedHero(
    label: stringAt(written, 'label'),
    profile: decodeProfile(written, 'profile'),
    run: written['run'] == null ? null : loadRun(written, 'run'),
  );
}
