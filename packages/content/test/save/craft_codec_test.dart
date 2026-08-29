import 'dart:convert';

import 'package:residuum_content/content.dart';
import 'package:residuum_content/src/save/craft_codec.dart';
import 'package:residuum_content/src/save/profile_codec.dart';
import 'package:residuum_content/src/save/save_json.dart';
import 'package:residuum_content/src/save/run_codec.dart';
import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

Profile _reread(Profile profile) =>
    decodeProfile({'profile': encodeProfile(profile)}, 'profile');

GameState _rereadRun(GameState run) =>
    loadRun({'run': encodeRun(run)}, 'run', dungeon: cryptNode);

/// A crypt camp with something to carry and something still standing on the
/// floor below.
GameState _camp() {
  final opened = startDungeonRunAt(cryptNode, newProfile(worldSeed: 909));
  return opened.copyWith(
    materials: const {MaterialId.ore: 5, MaterialId.herb: 2},
  );
}

String _reasonFor(Map<String, Object?> profile) {
  try {
    decodeProfile({'profile': profile}, 'profile');
  } on SaveMalformed catch (malformed) {
    return malformed.reason;
  }
  throw StateError('expected a refusal, got a profile');
}

Map<String, Object?> _profileWith(Map<String, Object?> changes) => {
  ...encodeProfile(newProfile(worldSeed: 1)),
  ...changes,
};

void main() {
  group('the materials block', () {
    test('is written in enum order, whatever order the map is in', () {
      // arrange
      final profile = newProfile().copyWith(
        materials: const {
          MaterialId.herb: 1,
          MaterialId.ingot: 2,
          MaterialId.ore: 3,
        },
      );

      // act
      final written = encodeMaterials(profile.materials);

      // assert - one hero encodes to one document, which is what makes the
      // golden a pin rather than a coincidence
      expect(written.keys, ['ore', 'ingot', 'herb']);
    });

    test('leaves out every material the hero has none of', () {
      // arrange
      final profile = newProfile().copyWith(
        materials: const {MaterialId.ingot: 1},
      );

      // act
      final written = encodeMaterials(profile.materials);

      // assert
      expect(written, {'ingot': 1});
    });

    test('a hero who has gathered nothing writes an empty block', () {
      // arrange
      final profile = newProfile();

      // act
      final written = jsonEncode(encodeProfile(profile));

      // assert - written out empty rather than left out, so the key is required
      // and a document missing it is refused rather than read as "probably none"
      expect(written, contains('"materials":{}'));
    });

    test('round-trips every counter the hero carries', () {
      // arrange
      final profile = newProfile().copyWith(
        materials: const {
          MaterialId.ore: 7,
          MaterialId.ingot: 2,
          MaterialId.herb: 11,
        },
      );

      // act
      final back = _reread(profile);

      // assert
      expect(back.materials, profile.materials);
    });

    test('a material this build does not have is refused by name', () {
      // arrange
      final written = _profileWith({
        'materials': {'mithril': 2},
      });

      // act
      final reason = _reasonFor(written);

      // assert - a counter quietly dropped is a hero who came home short with
      // no way to find out which
      expect(reason, contains('mithril'));
    });

    test('a counter of zero is refused rather than read as none', () {
      // arrange
      final written = _profileWith({
        'materials': {'ore': 0},
      });

      // act
      final reason = _reasonFor(written);

      // assert - the encoder writes none by leaving the key out, so a zero in a
      // document is a document that was not written by this game
      expect(reason, contains('ore'));
    });

    test('a counter that is not a whole number is refused', () {
      // arrange
      final written = _profileWith({
        'materials': {'ore': 'plenty'},
      });

      // act
      final reason = _reasonFor(written);

      // assert
      expect(reason, contains('whole numbers'));
    });

    test('a missing block is refused rather than filled in', () {
      // arrange
      final written = _profileWith({})..remove('materials');

      // act
      final reason = _reasonFor(written);

      // assert
      expect(reason, contains('materials'));
    });

    test('a crawl carries its own counters through the run block', () {
      // arrange
      final camped = _camp();

      // act
      final back = _rereadRun(camped);

      // assert
      expect(back.materials, const {MaterialId.ore: 5, MaterialId.herb: 2});
    });
  });

  group('the brew counter', () {
    test('round-trips, so two brews never share an id', () {
      // arrange
      final profile = newProfile().copyWith(brewNumber: 14);

      // act
      final back = _reread(profile);

      // assert
      expect(back.brewNumber, 14);
    });

    test('a hero who has never brewed still writes the counter', () {
      // arrange
      final profile = newProfile();

      // act
      final written = jsonEncode(encodeProfile(profile));

      // assert
      expect(written, contains('"brewNumber":1'));
    });

    test('a missing counter is refused rather than started over at one', () {
      // arrange
      final written = _profileWith({})..remove('brewNumber');

      // act
      final reason = _reasonFor(written);

      // assert - a counter restarted on load would hand out an id the hero is
      // already carrying
      expect(reason, contains('brewNumber'));
    });
  });

  group('the nodes block', () {
    test('is sorted by row and then column', () {
      // arrange
      final nodes = {
        const Position(9, 4): GatherKind.oreVein,
        const Position(1, 1): GatherKind.herbPatch,
        const Position(2, 4): GatherKind.oreVein,
      };

      // act
      final written = encodeNodes(nodes);

      // assert
      expect(written, [
        {'x': 1, 'y': 1, 'kind': 'herbPatch'},
        {'x': 2, 'y': 4, 'kind': 'oreVein'},
        {'x': 9, 'y': 4, 'kind': 'oreVein'},
      ]);
    });

    test('the floor the hero is standing on round-trips its nodes', () {
      // arrange
      final camped = _camp();

      // act
      final back = _rereadRun(camped);

      // assert
      expect(back.nodes, camped.nodes);
      expect(back.nodes, isNotEmpty);
    });

    test('a floor the hero walked away from round-trips its nodes', () {
      // arrange
      final camped = _camp();
      final onTheStairs = camped.copyWith(
        hero: camped.hero.copyWith(position: camped.stairsDown),
      );

      // act
      final (deeper, _) = step(onTheStairs, const DescendAction());
      final back = _rereadRun(deeper);

      // assert - the floor above is a FloorMemory now, and its nodes are the
      // ones the hero left standing on it
      expect(deeper.depth, 2);
      expect(back.floors[1]!.nodes, camped.nodes);
      expect(back.floors[1]!.nodes, isNotEmpty);
    });

    test('a worked floor comes back worked, not regrown', () {
      // arrange
      final camped = _camp();
      final stripped = camped.copyWith(nodes: const {});

      // act
      final back = _rereadRun(stripped);

      // assert - a floor the hero stripped stays stripped until the next entry
      // reshuffles the dungeon, which is exactly groundItems' lifetime
      expect(back.nodes, isEmpty);
    });

    test('a kind this build does not have is refused by name', () {
      // arrange
      final written = {
        'nodes': [
          {'x': 1, 'y': 1, 'kind': 'gemSeam'},
        ],
      };

      // act
      String reason;
      try {
        decodeNodes(written, 'nodes');
        reason = '';
      } on SaveMalformed catch (malformed) {
        reason = malformed.reason;
      }

      // assert
      expect(reason, contains('gemSeam'));
    });
  });

  group('the temper on an item', () {
    test('round-trips on a carried item', () {
      // arrange
      final profile = newProfile().copyWith(
        inventory: [
          Item(
            id: 'drop-1',
            base: ironSword,
            rarity: Rarity.common,
          ).tempered(2),
        ],
      );

      // act
      final back = _reread(profile);

      // assert
      expect(back.inventory.single.temper, 2);
    });

    test('round-trips on a worn item', () {
      // arrange
      final profile = newProfile().copyWith(
        equipment: {
          EquipSlot.chest: const Item(
            id: 'drop-1',
            base: mailHauberk,
            rarity: Rarity.fine,
            affixes: [sturdy],
          ).tempered(3),
        },
      );

      // act
      final back = _reread(profile);

      // assert
      expect(back.equipment[EquipSlot.chest]!.temper, 3);
      expect(
        back.equipment[EquipSlot.chest]!.armor,
        profile.equipment[EquipSlot.chest]!.armor,
      );
      expect(
        back.equipment[EquipSlot.chest]!.armor,
        mailHauberk.armor + sturdy.armor + 3,
      );
    });

    test('a temper past the forge\'s ceiling is refused', () {
      // arrange
      final written = _profileWith({
        'inventory': [
          {
            'id': 'drop-1',
            'base': 'iron-sword',
            'rarity': 'common',
            'affixes': <Object?>[],
            'temper': maxTemper + 1,
          },
        ],
      });

      // act
      final reason = _reasonFor(written);

      // assert - reading it as three would hand the player a weaker sword than
      // their own save file says they own
      expect(reason, contains('${maxTemper + 1}'));
    });

    test('a missing temper is refused rather than read as unworked', () {
      // arrange
      final written = _profileWith({
        'inventory': [
          {
            'id': 'drop-1',
            'base': 'iron-sword',
            'rarity': 'common',
            'affixes': <Object?>[],
          },
        ],
      });

      // act
      final reason = _reasonFor(written);

      // assert
      expect(reason, contains('temper'));
    });
  });

  group('the skills block at nine', () {
    test('writes every skill in the enum, in enum order', () {
      // arrange
      final profile = newProfile();

      // act
      final written = jsonEncode(encodeProfile(profile));

      // assert
      for (final skill in SkillId.values) {
        expect(written, contains('"${skill.name}":{"level":0,"xp":0}'));
      }
    });

    test('a craft skill round-trips like any other', () {
      // arrange
      final profile = newProfile().copyWith(
        skills: {
          ...untrainedSkills,
          SkillId.blacksmith: const SkillState(level: 6, xp: 3),
        },
      );

      // act
      final back = _reread(profile);

      // assert
      expect(
        back.skills[SkillId.blacksmith],
        const SkillState(level: 6, xp: 3),
      );
    });
  });
}
