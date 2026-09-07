import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

const _room = '''
##########
#........#
#........#
##########''';

const _sword = BaseItem(
  id: 'iron-sword',
  name: 'Iron Sword',
  glyph: ')',
  slot: EquipSlot.mainHand,
  hands: WeaponHands.one,
  attackMin: 3,
  attackMax: 5,
);

Dungeon _roomed() =>
    (visit) =>
        (depth) => Floor(
          map: FloorMap.parse(_room),
          heroSpawn: const Position(1, 1),
          monsters: [ghoul('ghoul-1', const Position(8, 2))],
          stairsDown: depth >= deepestDepth ? null : const Position(8, 1),
          stairsUp: depth <= 1 ? null : const Position(1, 1),
        );

Profile _crafter({required int craftRngState}) => Profile(
  hero: hero(const Position(0, 0)),
  worldSeed: 909,
  inventory: [
    Item(id: 'drop-1', base: _sword, rarity: Rarity.common).tempered(1),
  ],
  materials: const {MaterialId.ingot: 3},
  skills: {
    ...untrainedSkills,
    SkillId.blacksmith: const SkillState(level: 5),
  },
  craftRngState: craftRngState,
);

GameState _bumped(GameState run) {
  var state = run;
  for (var turn = 0; turn < 20; turn++) {
    state = step(state, const MoveAction(Direction.north)).$1;
  }
  return state;
}

void main() {
  group("the crawl's streams", () {
    test('run roll for roll whether or not a craft failed in town', () {
      // arrange - two identical heroes; one goes and fails a temper first
      final still = _crafter(craftRngState: stateRollingBelow(20));
      final failing = _crafter(craftRngState: stateRollingBelow(20));

      // act
      final (worked, answer) = temperItem(failing, 'drop-1');
      final quietRun = _bumped(startRun(still, dungeon: _roomed()));
      final craftedRun = _bumped(startRun(worked, dungeon: _roomed()));

      // assert - the attempt failed and cost the ingot, and the dungeon does
      // not know it happened
      expect(answer, isNotNull);
      expect(quietRun.rng.state, craftedRun.rng.state);
      expect(quietRun.lootRng.state, craftedRun.lootRng.state);
      expect(quietRun.monsters.length, craftedRun.monsters.length);
      expect(
        quietRun.monsters.first.position,
        craftedRun.monsters.first.position,
      );
    });

    test('a town craft attempt moves no stream a resume depends on', () {
      // arrange
      final crafter = _crafter(craftRngState: stateRollingBelow(20));
      final run = startRun(crafter, dungeon: _roomed());

      // act
      final after = suspendRun(crafter, run);
      final (worked, _) = temperItem(after, 'drop-1');
      final resumed = resumeRun(worked, run);

      // assert
      expect(resumed.rng.state, run.rng.state);
      expect(resumed.lootRng.state, run.lootRng.state);
      expect(resumed.map, run.map);
    });
  });
}