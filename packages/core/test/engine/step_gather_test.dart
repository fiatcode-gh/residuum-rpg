import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

const _room = '''
##########
#........#
#........#
##########''';

const _here = Position(3, 1);
const _elsewhere = Position(6, 2);

GameState _standingOn(
  GatherKind kind, {
  Map<MaterialId, int> materials = const {},
  Map<SkillId, SkillState> skills = untrainedSkills,
  List<Actor> monsters = const [],
  List<Item> inventory = const [],
}) => crawl(
  ascii: _room,
  heroAt: _here,
  monsters: monsters,
  materials: materials,
  skills: skills,
  inventory: inventory,
).copyWith(nodes: {_here: kind, _elsewhere: GatherKind.herbPatch});

GameState _standingOnNothing() => crawl(
  ascii: _room,
  heroAt: _here,
).copyWith(nodes: {_elsewhere: GatherKind.oreVein});

void main() {
  group('GatherAction with nothing underfoot', () {
    test('is refused in a sentence', () {
      // arrange
      final state = _standingOnNothing();

      // act
      final (_, events) = step(state, const GatherAction());

      // assert
      expect(events, const [
        ActionRefused(reason: 'there is nothing here to gather'),
      ]);
    });

    test('costs nothing at all', () {
      // arrange
      final state = _standingOnNothing();

      // act
      final (after, _) = step(state, const GatherAction());

      // assert - refused rather than blocked, following PickUpAction: the
      // control only appears on a node, so a stray tap must cost no turn
      expect(after.hero.energy, state.hero.energy);
      expect(after.materials, isEmpty);
      expect(after.nodes, state.nodes);
    });
  });

  group('mining a vein', () {
    test('puts one ore in the hero\'s hands', () {
      // arrange
      final state = _standingOn(GatherKind.oreVein);

      // act
      final (after, _) = step(state, const GatherAction());

      // assert - a flat one, drawn from nothing: a rolled yield would need a
      // stream, and no stream on this path is the whole point
      expect(after.materials, const {MaterialId.ore: 1});
    });

    test('adds to a counter the hero already had', () {
      // arrange
      final state = _standingOn(
        GatherKind.oreVein,
        materials: const {MaterialId.ore: 4, MaterialId.herb: 1},
      );

      // act
      final (after, _) = step(state, const GatherAction());

      // assert
      expect(after.materials, const {MaterialId.ore: 5, MaterialId.herb: 1});
    });

    test('says what was worked', () {
      // arrange
      final state = _standingOn(GatherKind.oreVein);

      // act
      final (_, events) = step(state, const GatherAction());

      // assert
      expect(
        events.whereType<NodeGathered>().single,
        const NodeGathered(
          kind: GatherKind.oreVein,
          at: _here,
          material: MaterialId.ore,
        ),
      );
    });

    test('trains Blacksmith and nothing else', () {
      // arrange
      final state = _standingOn(GatherKind.oreVein);

      // act
      final (after, _) = step(state, const GatherAction());

      // assert
      expect(after.skills[SkillId.blacksmith], const SkillState(xp: 1));
      expect(after.skills[SkillId.herbcraft], const SkillState());
      expect(after.skills[SkillId.arms], const SkillState());
    });

    test('takes the vein off the floor for the rest of the run', () {
      // arrange
      final state = _standingOn(GatherKind.oreVein);

      // act
      final (after, _) = step(state, const GatherAction());

      // assert
      expect(after.nodes, {_elsewhere: GatherKind.herbPatch});
    });

    test('a second try on the worked tile is refused', () {
      // arrange
      final state = _standingOn(GatherKind.oreVein);

      // act
      final (worked, _) = step(state, const GatherAction());
      final (_, again) = step(worked, const GatherAction());

      // assert - the node is gone, so the refusal is the ordinary
      // nothing-here one rather than a rule of its own
      expect(again, const [
        ActionRefused(reason: 'there is nothing here to gather'),
      ]);
    });

    test('costs the turn, so the monsters get theirs', () {
      // arrange
      final state = _standingOn(
        GatherKind.oreVein,
        monsters: [ghoul('ghoul-1', const Position(8, 2))],
      );

      // act
      final (after, events) = step(state, const GatherAction());

      // assert - working a seam takes time, and the room is not going to wait
      expect(after.monsters.single.position, isNot(const Position(8, 2)));
      expect(events.whereType<ActorMoved>(), isNotEmpty);
    });

    test('announces a level when the swing of a pick earns one', () {
      // arrange
      final state = _standingOn(
        GatherKind.oreVein,
        skills: {
          ...untrainedSkills,
          SkillId.blacksmith: SkillState(xp: xpToNext(0) - 1),
        },
      );

      // act
      final (after, events) = step(state, const GatherAction());

      // assert
      expect(after.skills[SkillId.blacksmith]!.level, 1);
      expect(
        events.whereType<SkillLevelledUp>().single,
        const SkillLevelledUp(skill: SkillId.blacksmith, level: 1),
      );
    });
  });

  group('gathering a patch', () {
    test('puts one herb in the hero\'s hands and trains Herbcraft', () {
      // arrange
      final state = _standingOn(GatherKind.herbPatch);

      // act
      final (after, _) = step(state, const GatherAction());

      // assert
      expect(after.materials, const {MaterialId.herb: 1});
      expect(after.skills[SkillId.herbcraft], const SkillState(xp: 1));
      expect(after.skills[SkillId.blacksmith], const SkillState());
    });

    test('says a patch was gathered, not a vein mined', () {
      // arrange
      final state = _standingOn(GatherKind.herbPatch);

      // act
      final (_, events) = step(state, const GatherAction());

      // assert
      expect(
        events.whereType<NodeGathered>().single,
        const NodeGathered(
          kind: GatherKind.herbPatch,
          at: _here,
          material: MaterialId.herb,
        ),
      );
    });
  });

  group('what gathering must never touch', () {
    test('draws nothing from either of the crawl\'s streams', () {
      // arrange
      final state = _standingOn(GatherKind.oreVein);
      final streams = (state.rng.state, state.lootRng.state);

      // act
      step(state, const GatherAction());

      // assert - the D56 lesson as a test rather than a comment: one draw here
      // would shift every fight and every drop after it on every seed, and the
      // four survivability bands would have to be re-pinned instead of trusted
      expect((state.rng.state, state.lootRng.state), streams);
    });

    test('draws nothing even when the refusal comes back', () {
      // arrange
      final state = _standingOnNothing();
      final streams = (state.rng.state, state.lootRng.state);

      // act
      step(state, const GatherAction());

      // assert
      expect((state.rng.state, state.lootRng.state), streams);
    });

    test('leaves the terrain exactly as it was', () {
      // arrange
      final state = _standingOn(GatherKind.oreVein);

      // act
      final (after, _) = step(state, const GatherAction());

      // assert - a node is state over a tile and never the tile, so working one
      // cannot move a single byte of the map
      expect(after.map.toAscii(), state.map.toAscii());
      expect(after.map.tileAt(_here), Tile.floor);
    });

    test('leaves the pack and the litter alone', () {
      // arrange
      final state = _standingOn(GatherKind.oreVein);

      // act
      final (after, _) = step(state, const GatherAction());

      // assert
      expect(after.inventory, state.inventory);
      expect(after.groundItems, state.groundItems);
    });

    test('works with a full pack, because ore is not carried in it', () {
      // arrange
      final state = _standingOn(
        GatherKind.oreVein,
        inventory: [
          for (var made = 0; made < inventoryCap; made++)
            Item(id: 'kit-$made', base: _potion, rarity: Rarity.common),
        ],
      );

      // act
      final (after, events) = step(state, const GatherAction());

      // assert - the pack cap is a decision about gear, and a currency that ran
      // into it would tax the wrong choice
      expect(after.inventory, hasLength(inventoryCap));
      expect(after.materials, const {MaterialId.ore: 1});
      expect(events.whereType<InventoryFull>(), isEmpty);
    });

    test('a dead hero gathers nothing', () {
      // arrange
      final state = _standingOn(GatherKind.oreVein).copyWith(isGameOver: true);

      // act
      final (after, events) = step(state, const GatherAction());

      // assert
      expect(events, isEmpty);
      expect(after.materials, isEmpty);
      expect(after.nodes, state.nodes);
    });
  });
}

const _potion = BaseItem(
  id: 'healing-potion',
  name: 'Healing Potion',
  glyph: '!',
  heal: 8,
);
