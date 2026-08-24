import 'dart:convert';

import 'package:residuum_core/core.dart';

import '../dungeons.dart';
import '../world.dart';
import 'item_codec.dart';
import 'merchant_visit.dart';
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
/// A hero's `run` of null is what having no crawl *is*. It is written out rather
/// than left out, so an entry always says which of the two states it describes
/// and a key that went missing is never read as "probably town".
///
/// The `world` block is required beside them, and says where in the world the
/// hero is standing, what day it is for them and what of the map they have
/// uncovered. Required rather than defaulted, for the reason `merchant` is: this
/// codec never repairs, so a document written by anything that did not answer
/// the question is refused rather than quietly told it is standing at home.
///
/// `run` and `inside` are two fields because they are two questions. A hero with
/// a crawl written down is either standing in it — the app was killed mid-fight —
/// or camped away from it in town, having walked out at the stairs; those boot
/// into opposite screens, and no amount of reading the run block answers which.
/// Both are required, so an entry written by anything that did not answer both is
/// refused rather than guessed at.
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

/// One hero, written down.
///
/// `dungeon` sits directly after `run` because it is the run's other half: the
/// two are written and read as a pair, and a reader scanning the document finds
/// the place named beside the crawl rather than three keys away from it. Null
/// exactly when `run` is null, and written out rather than left out for the
/// reason `run` itself is — a key that went missing is never read as "probably
/// the crypt".
///
/// `campDay` sits directly after `inside` for the reason `dungeon` sits after
/// `run`: it is the camp's other half. `run` says there is a crawl, `inside`
/// says whether the hero is standing in it, and this says what day they walked
/// out — the three are read together and a reader scanning the document finds
/// them together. Null exactly when the hero is not camped, and written out
/// rather than left out, so a key that went missing is never read as "probably
/// pitched today".
Map<String, Object?> _encodeHero(SavedHero hero) => {
  'label': hero.label,
  'profile': encodeProfile(hero.profile),
  'run': hero.run == null ? null : encodeRun(hero.run!),
  'dungeon': hero.dungeon?.value,
  'inside': hero.inside,
  'campDay': hero.campDay,
  'world': _encodeWorld(hero.world),
  'merchant': _encodeMerchant(hero.merchant),
};

/// Where the hero is in the world, written down.
///
/// `journey` is written out as null rather than left out when the hero is
/// standing still, following `run`: a key that went missing is never read as
/// "probably not travelling", and an entry always says which of the two states
/// it describes.
///
/// The discovered set is sorted, for the reason the roster's keys and the run's
/// position sets are: one hero always encodes to one document however the set
/// happened to be assembled, which is what makes the golden a pin rather than a
/// coincidence.
Map<String, Object?> _encodeWorld(Whereabouts world) => {
  'at': world.at.value,
  'home': world.home.value,
  'day': world.day,
  'discovered': [
    for (final node
        in world.discovered.map((node) => node.value).toList()..sort())
      node,
  ],
  'journey': world.journey == null
      ? null
      : {
          'from': world.journey!.from.value,
          'to': world.journey!.to.value,
          'daysLeft': world.journey!.daysLeft,
        },
};

Map<String, Object?> _encodeMerchant(MerchantVisit merchant) => {
  'bought': [...merchant.bought],
  'sold': encodeItems(merchant.sold),
  'town': merchant.town?.value,
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
  final dungeon = _decodeDungeon(id, written);
  final crawling = written['run'] != null;
  if (crawling && dungeon == null) {
    throw SaveMalformed(
      'the hero "$id" in the save file has a crawl without saying which '
      'dungeon it is in',
    );
  }
  if (!crawling && dungeon != null) {
    throw SaveMalformed(
      'the hero "$id" in the save file names a dungeon it has no crawl in: '
      '"${dungeon.value}"',
    );
  }
  final run = crawling ? loadRun(written, 'run', dungeon: dungeon!) : null;
  final inside = boolAt(written, 'inside');
  if (inside && run == null) {
    throw SaveMalformed(
      'the hero "$id" in the save file is "inside" a crawl it does not have',
    );
  }
  final campDay = _decodeCampDay(id, written, camped: run != null && !inside);
  final world = _decodeWorld(id, written);
  if (inside && residuumWorld.nodeAt(world.at).kind != NodeKind.dungeon) {
    throw SaveMalformed(
      'the hero "$id" in the save file is "inside" a crawl while standing at '
      '"${world.at.value}", which has no dungeon under it',
    );
  }
  if (inside && world.isTravelling) {
    throw SaveMalformed(
      'the hero "$id" in the save file is "inside" a crawl and on the road at '
      'the same time',
    );
  }
  return SavedHero(
    label: stringAt(written, 'label'),
    profile: decodeProfile(written, 'profile'),
    world: world,
    run: run,
    dungeon: dungeon,
    merchant: _decodeMerchant(id, written),
    inside: inside,
    campDay: campDay,
  );
}

/// The day the hero pitched their camp, from the required key beside `inside`.
///
/// **Required, and required to agree with the camp.** The whole of what the key
/// is for is answering how long the camp has stood, so a document that left it
/// out describes a camp of unknown age — and a decoder that filled in today
/// would hand the player a fresh camp every time they relaunched, which is the
/// one thing the expiry rule exists to stop. A day written down for a hero with
/// no camp is the same fault the other way round, and is refused rather than
/// ignored, because this codec never repairs.
int? _decodeCampDay(
  String id,
  Map<String, Object?> hero, {
  required bool camped,
}) {
  if (!hero.containsKey('campDay')) {
    throw SaveMalformed('the save file is missing "campDay"');
  }
  final written = hero['campDay'];
  if (written == null) {
    if (camped) {
      throw SaveMalformed(
        'the hero "$id" in the save file has a camp without saying what day '
        'it was pitched',
      );
    }
    return null;
  }
  if (!camped) {
    throw SaveMalformed(
      'the hero "$id" in the save file names the day a camp was pitched '
      'without having one',
    );
  }
  final day = intAt(hero, 'campDay');
  if (day < 0) {
    throw SaveMalformed(
      'the hero "$id" in the save file pitched a camp on day $day, and the '
      'world starts on day zero',
    );
  }
  return day;
}

/// Which dungeon the hero's crawl is in, from the required key beside it.
///
/// **Required, and checked against the world this build ships.** The id is what
/// picks the floor builder a resumed crawl walks on down through, so a document
/// naming a place that is not here — or naming a town, which has nothing under
/// it — describes a crawl whose second floor cannot be laid out at all. That
/// would surface as a crash on the stairs, several screens after the mistake.
/// Refusing it here by name is what keeps it a sentence on the town screen.
///
/// Whether it agrees with `run` is the caller's check rather than this one's,
/// because the answer is about the pair and this only knows one half.
NodeId? _decodeDungeon(String id, Map<String, Object?> hero) {
  if (!hero.containsKey('dungeon')) {
    throw SaveMalformed('the save file is missing "dungeon"');
  }
  final written = hero['dungeon'];
  if (written == null) return null;
  final node = _node(id, written);
  if (!isDungeonNode(node)) {
    throw SaveMalformed(
      'the hero "$id" in the save file is crawling "${node.value}", which has '
      'no dungeon under it',
    );
  }
  return node;
}

/// Where the hero stands, from the required block on a hero entry.
///
/// **Every id is checked against the world this build ships.** A document naming
/// a place that does not exist describes a hero standing nowhere, and every rule
/// that reads a whereabouts — the day's road, the shelf, the place death wakes
/// them at — would fail somewhere further in with nothing to say. Refusing it
/// here by name is what keeps that a sentence on the screen.
///
/// [Whereabouts] checks the rest for itself, and its complaints are translated
/// rather than repeated: it is the one that knows a hero cannot stand somewhere
/// they have not heard of, and stating that twice is how the two copies start to
/// disagree.
Whereabouts _decodeWorld(String id, Map<String, Object?> hero) {
  final written = objectAt(hero, 'world');
  final at = _node(id, written['at']);
  final home = _node(id, written['home']);
  if (residuumWorld.nodeAt(home).kind != NodeKind.town) {
    throw SaveMalformed(
      'the hero "$id" in the save file calls "${home.value}" home, which is not '
      'a town',
    );
  }
  final journey = written['journey'];
  try {
    return Whereabouts(
      at: at,
      home: home,
      discovered: {
        for (final node in listAt(written, 'discovered')) _node(id, node),
      },
      day: intAt(written, 'day'),
      journey: journey == null ? null : _decodeJourney(id, journey),
    );
  } on ArgumentError catch (bad) {
    throw SaveMalformed('the hero "$id" in the save file ${bad.message}');
  }
}

Journey _decodeJourney(String id, Object? written) {
  if (written is! Map<String, Object?>) {
    throw SaveMalformed(
      'the road the hero "$id" is on in the save file is not an object',
    );
  }
  final from = _node(id, written['from']);
  final to = _node(id, written['to']);
  if (residuumWorld.routeBetween(from, to) == null) {
    throw SaveMalformed(
      'the hero "$id" in the save file is on a road from "${from.value}" to '
      '"${to.value}", which this world does not have',
    );
  }
  try {
    return Journey(from: from, to: to, daysLeft: intAt(written, 'daysLeft'));
  } on ArgumentError catch (bad) {
    throw SaveMalformed('the hero "$id" in the save file ${bad.message}');
  }
}

NodeId _node(String id, Object? written) {
  if (written is! String) {
    throw SaveMalformed(
      'a place the hero "$id" names in the save file is not written as text',
    );
  }
  final NodeId node;
  try {
    node = NodeId(written);
  } on ArgumentError {
    throw SaveMalformed(
      'the hero "$id" in the save file names a place with no name',
    );
  }
  try {
    residuumWorld.nodeAt(node);
  } on ArgumentError {
    throw SaveMalformed(
      'the hero "$id" in the save file names "$written", which is nowhere in '
      'this world',
    );
  }
  return node;
}

/// What the merchant remembers, from the required block on a hero entry.
///
/// Required, not defaulted. Version 1 never shipped without this block, so a
/// hero entry has exactly one shape — and a decoder that filled in an empty
/// visit for a document missing it would be repairing, which this codec does not
/// do.
MerchantVisit _decodeMerchant(String id, Map<String, Object?> hero) {
  final written = objectAt(hero, 'merchant');
  if (!written.containsKey('town')) {
    throw SaveMalformed('the save file is missing "town"');
  }
  final where = written['town'];
  final town = where == null ? null : _node(id, where);
  final bought = [
    for (final name in listAt(written, 'bought')) _boughtId(name),
  ];
  final sold = decodeItems(written, 'sold');
  if (town == null && (bought.isNotEmpty || sold.isNotEmpty)) {
    throw SaveMalformed(
      'the hero "$id" in the save file remembers a shop without remembering '
      'which town it was in',
    );
  }
  return MerchantVisit(bought: bought, sold: sold, town: town);
}

String _boughtId(Object? written) {
  if (written is! String) {
    throw SaveMalformed(
      'a "bought" item in the save file is not named by text',
    );
  }
  return written;
}
