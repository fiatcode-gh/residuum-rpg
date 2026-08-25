import 'package:residuum_core/core.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

const _room = '''
#########
#.......#
#.......#
#########''';

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

const Spell _mend = Spell(
  id: 'mend',
  name: 'Mend',
  school: SkillId.mending,
  manaCost: 3,
  requiredLevel: 0,
  kind: SpellKind.mend,
  min: 8,
  max: 8,
);

const Spell _ward = Spell(
  id: 'ward',
  name: 'Ward',
  school: SkillId.mending,
  manaCost: 3,
  requiredLevel: 0,
  kind: SpellKind.ward,
  min: 6,
  max: 6,
);

const Spell _bind = Spell(
  id: 'bind',
  name: 'Bind',
  school: SkillId.binding,
  manaCost: 3,
  requiredLevel: 0,
  kind: SpellKind.bind,
  min: 3,
  max: 3,
);

const Spell _banish = Spell(
  id: 'banish',
  name: 'Banish',
  school: SkillId.binding,
  manaCost: 4,
  requiredLevel: 0,
  kind: SpellKind.banish,
  min: 0,
  max: 0,
);

const Map<String, Spell> _spells = {
  'firebolt': _firebolt,
  'mend': _mend,
  'ward': _ward,
  'bind': _bind,
  'banish': _banish,
};

GameState _caster({
  List<Actor> monsters = const [],
  int mana = 10,
  int heroHp = 20,
  int warded = 0,
  Map<String, int> bound = const {},
  Set<String> knownSpells = const {
    'firebolt',
    'mend',
    'ward',
    'bind',
    'banish',
  },
  int seed = 1,
  Map<int, DropTable> dropTables = const {},
}) => crawl(
  ascii: _room,
  heroAt: const Position(1, 1),
  monsters: monsters,
  heroHp: heroHp,
  seed: seed,
  spells: _spells,
  knownSpells: knownSpells,
  mana: mana,
  warded: warded,
  bound: bound,
  dropTables: dropTables,
);

String _reasonOf(List<GameEvent> events) =>
    (events.single as ActionRefused).reason;

SpellHit _hitIn(List<GameEvent> events) => events.whereType<SpellHit>().single;

void main() {
  group('what casting refuses', () {
    test('a spell the hero has never learned', () {
      // arrange
      final game = _caster(knownSpells: const {});

      // act
      final (after, events) = step(game, const CastSpellAction('firebolt'));

      // assert
      expect(_reasonOf(events), 'you do not know that spell');
      expect(after, same(game));
    });

    test('a spell this build does not cast at all', () {
      // arrange
      final game = _caster(knownSpells: const {'telekinesis'});

      // act
      final (_, events) = step(game, const CastSpellAction('telekinesis'));

      // assert
      expect(_reasonOf(events), 'you do not know that spell');
    });

    test('a spell the pool is short of', () {
      // arrange
      final game = _caster(
        mana: 1,
        monsters: [ghoul('ghoul-1', const Position(4, 1))],
      );

      // act
      final (_, events) = step(game, const CastSpellAction('firebolt'));

      // assert
      expect(_reasonOf(events), 'not enough mana');
    });

    test('a bolt with nothing in sight to throw it at', () {
      // arrange
      final game = _caster();

      // act
      final (_, events) = step(game, const CastSpellAction('firebolt'));

      // assert
      expect(_reasonOf(events), 'no enemy in sight');
    });

    test('a bind with nothing in sight, and a banish likewise', () {
      // arrange
      final game = _caster();

      // act
      final (_, bindEvents) = step(game, const CastSpellAction('bind'));
      final (_, banishEvents) = step(game, const CastSpellAction('banish'));

      // assert
      expect(_reasonOf(bindEvents), 'no enemy in sight');
      expect(_reasonOf(banishEvents), 'no enemy in sight');
    });

    test('an empty pool before it complains about the empty room', () {
      // arrange
      final game = _caster(mana: 0);

      // act
      final (_, events) = step(game, const CastSpellAction('firebolt'));

      // assert - the order is the contract: the hero could not have cast it
      // even with a target
      expect(_reasonOf(events), 'not enough mana');
    });
  });

  group('what casting does not refuse', () {
    test('mending at full health, which wastes the turn and the mana', () {
      // arrange
      final game = _caster(heroHp: 20);

      // act
      final (after, events) = step(game, const CastSpellAction('mend'));

      // assert - the Drink doctrine: a wasteful use is the player's to make
      expect(events.whereType<ActionRefused>(), isEmpty);
      expect(events, contains(const MendCast(healed: 0)));
      expect(after.mana, game.mana - _mend.manaCost);
    });

    test('warding when a ward already stands', () {
      // arrange
      final game = _caster(warded: 2);

      // act
      final (after, events) = step(game, const CastSpellAction('ward'));

      // assert - it replaces rather than stacking, so a quiet corridor can
      // never be spent building invulnerability
      expect(after.warded, 6);
      expect(events, contains(const WardRaised(absorbs: 6)));
    });

    test('mending or warding with no enemy anywhere', () {
      // arrange
      final game = _caster(heroHp: 10);

      // act
      final (after, _) = step(game, const CastSpellAction('mend'));

      // assert
      expect(after.hero.hp, 18);
    });
  });

  group('a bolt', () {
    test('deals its rolled damage to the nearest thing in sight', () {
      // arrange
      final game = _caster(
        monsters: [
          ghoul('near', const Position(4, 1)),
          ghoul('far', const Position(7, 2)),
        ],
      );

      // act
      final (after, events) = step(game, const CastSpellAction('firebolt'));
      final hit = _hitIn(events);

      // assert
      expect(hit.targetId, 'near');
      expect(hit.damage, inInclusiveRange(_firebolt.min, _firebolt.max));
      expect(hit.bite, SpellBite.plain);
      expect(
        after.monsters.firstWhere((one) => one.id == 'near').hp,
        10 - hit.damage,
      );
    });

    test('rolls exactly the number this seed has always rolled', () {
      // arrange
      final game = _caster(
        seed: 1,
        monsters: [ghoul('near', const Position(4, 1))],
      );

      // act
      final (_, events) = step(game, const CastSpellAction('firebolt'));

      // assert - an exact pin, so a change to the spell's range cannot pass
      expect(_hitIn(events).damage, 2);
    });

    test('draws exactly one number from the combat stream', () {
      // arrange
      final game = _caster(monsters: [ghoul('near', const Position(4, 1))]);
      final expected = Rng(1)..rollRange(_firebolt.min, _firebolt.max);

      // act
      final (after, _) = step(game, const CastSpellAction('firebolt'));

      // assert - the whole game's spine is this stream; a second draw here
      // would move every seeded fight ever recorded
      expect(after.rng.state, expected.state);
    });

    test('is halved against a target that resists the type', () {
      // arrange
      final plain = _caster(monsters: [ghoul('near', const Position(4, 1))]);
      final tough = _caster(
        monsters: [
          ghoul('near', const Position(4, 1), resists: {DamageType.fire}),
        ],
      );

      // act
      final (_, plainEvents) = step(plain, const CastSpellAction('firebolt'));
      final (_, toughEvents) = step(tough, const CastSpellAction('firebolt'));

      // assert
      expect(_hitIn(toughEvents).damage, _hitIn(plainEvents).damage ~/ 2);
      expect(_hitIn(toughEvents).bite, SpellBite.resisted);
    });

    test('never falls below one, however well the target resists', () {
      // arrange - a roll of one halves to nothing without the floor
      final game = _caster(
        seed: 5,
        monsters: [
          ghoul('near', const Position(4, 1), resists: {DamageType.fire}),
        ],
      );

      // act
      final (_, events) = step(game, const CastSpellAction('firebolt'));

      // assert - resistance can dull a spell and must never make it harmless,
      // for the reason armour has a floor of one
      expect(_hitIn(events).damage, greaterThanOrEqualTo(1));
    });

    test('is doubled against a target that burns at the type', () {
      // arrange
      final plain = _caster(monsters: [ghoul('near', const Position(4, 1))]);
      final dry = _caster(
        monsters: [
          ghoul('near', const Position(4, 1), vulnerableTo: {DamageType.fire}),
        ],
      );

      // act
      final (_, plainEvents) = step(plain, const CastSpellAction('firebolt'));
      final (_, dryEvents) = step(dry, const CastSpellAction('firebolt'));

      // assert
      expect(_hitIn(dryEvents).damage, _hitIn(plainEvents).damage * 2);
      expect(_hitIn(dryEvents).bite, SpellBite.vulnerable);
    });

    test('ignores a resistance to a type it is not made of', () {
      // arrange
      final game = _caster(
        monsters: [
          ghoul('near', const Position(4, 1), resists: {DamageType.frost}),
        ],
      );

      // act
      final (_, events) = step(game, const CastSpellAction('firebolt'));

      // assert
      expect(_hitIn(events).bite, SpellBite.plain);
    });

    test('kills, and the kill spills loot off the loot stream', () {
      // arrange
      final table = DropTable(
        items: const [Weighted(_potionBase, 1)],
        rarities: const [Weighted(Rarity.common, 1)],
        weaponAffixes: const [],
        armourAffixes: const [],
        minFloorItems: 0,
        maxFloorItems: 0,
      );
      final game = _caster(
        monsters: [ghoul('near', const Position(4, 1), hp: 1, dropChance: 100)],
        dropTables: {1: table},
      );

      // act
      final (after, events) = step(game, const CastSpellAction('firebolt'));

      // assert - a spell kill is a kill: the same death path, the same spoils,
      // drawn from the same stream a swung kill draws from
      expect(events, contains(const ActorDied(actorId: 'near')));
      expect(after.monsters, isEmpty);
      expect(after.itemsAt(const Position(4, 1)), hasLength(1));
      expect(after.nextDropNumber, 2);
    });
  });

  group('mend', () {
    test('gives back its healing, capped at what is missing', () {
      // arrange
      final game = _caster(heroHp: 15);

      // act
      final (after, events) = step(game, const CastSpellAction('mend'));

      // assert
      expect(after.hero.hp, 20);
      expect(events, contains(const MendCast(healed: 5)));
    });

    test('draws nothing at all', () {
      // arrange
      final game = _caster(heroHp: 4);

      // act
      final (after, _) = step(game, const CastSpellAction('mend'));

      // assert
      expect(after.rng.state, game.rng.state);
    });
  });

  group('bind', () {
    test('holds the nearest thing in sight for the spell\'s own count', () {
      // arrange
      final game = _caster(monsters: [ghoul('near', const Position(4, 1))]);

      // act
      final (after, events) = step(game, const CastSpellAction('bind'));

      // assert - the beat announces three, and one of them is spent by the
      // monster phase of this very turn, so two are left standing
      expect(events, contains(const MonsterBound(targetId: 'near', turns: 3)));
      expect(after.bound, {'near': 2});
    });

    test('draws nothing at all', () {
      // arrange
      final game = _caster(monsters: [ghoul('near', const Position(4, 1))]);

      // act
      final (after, _) = step(game, const CastSpellAction('bind'));

      // assert
      expect(after.rng.state, game.rng.state);
    });
  });

  group('banish', () {
    test('moves the target somewhere else it could stand', () {
      // arrange
      final game = _caster(monsters: [ghoul('near', const Position(4, 1))]);

      // act
      final (after, events) = step(game, const CastSpellAction('banish'));
      final beat = events.whereType<MonsterBanished>().single;

      // assert - the beat says where the spell put it, which is not where the
      // monster stands by the end of the turn: it gets its own move afterwards
      expect(beat.from, const Position(4, 1));
      expect(beat.to, isNot(const Position(4, 1)));
      expect(after.map.isWalkable(beat.to), isTrue);
      expect(beat.to, isNot(game.hero.position));
    });

    test('draws exactly one number from the combat stream', () {
      // arrange - read the stream before stepping: it is carried by reference,
      // so the state on the crawl is the state after the turn ran
      final game = _caster(monsters: [ghoul('near', const Position(4, 1))]);
      final before = game.rng.state;

      // act
      final (after, _) = step(game, const CastSpellAction('banish'));

      // assert
      expect(_advances(before, after.rng.state), 1);
    });

    test('never lands a monster on a tile another monster holds', () {
      // arrange - the whole lower row is taken
      final crowd = [
        for (var x = 1; x <= 7; x++) ghoul('crowd-$x', Position(x, 2)),
        ghoul('near', const Position(4, 1)),
      ];
      final game = _caster(monsters: crowd);

      // act
      final (_, events) = step(game, const CastSpellAction('banish'));
      final beat = events.whereType<MonsterBanished>().single;

      // assert
      final held = [for (var x = 1; x <= 7; x++) Position(x, 2)];
      expect(held, isNot(contains(beat.to)));
      expect(beat.to, isNot(game.hero.position));
    });
  });

  group('every successful cast', () {
    test('spends the spell\'s mana and no more', () {
      // arrange
      final game = _caster(mana: 10, heroHp: 10);

      // act
      final (after, _) = step(game, const CastSpellAction('mend'));

      // assert
      expect(after.mana, 7);
    });

    test('trains the school it belongs to, and only that one', () {
      // arrange
      final game = _caster(monsters: [ghoul('near', const Position(4, 1))]);

      // act
      final (after, _) = step(game, const CastSpellAction('firebolt'));

      // assert - one point, exactly what a landed swing is worth
      expect(after.skills[SkillId.wrath], const SkillState(xp: 1));
      expect(after.skills[SkillId.mending], const SkillState());
      expect(after.skills[SkillId.arms], const SkillState());
    });

    test('trains Mending for a mend and Binding for a bind', () {
      // arrange
      final game = _caster(
        heroHp: 10,
        monsters: [ghoul('near', const Position(4, 1))],
      );

      // act
      final (mended, _) = step(game, const CastSpellAction('mend'));
      final (bound, _) = step(game, const CastSpellAction('bind'));

      // assert
      expect(mended.skills[SkillId.mending], const SkillState(xp: 1));
      expect(bound.skills[SkillId.binding], const SkillState(xp: 1));
    });

    test('costs the turn, so the monsters get theirs', () {
      // arrange
      final game = _caster(monsters: [ghoul('near', const Position(2, 1))]);

      // act
      final (after, _) = step(game, const CastSpellAction('firebolt'));

      // assert - the thing standing beside the hero swings back
      expect(after.hero.hp, lessThan(game.hero.hp));
    });

    test('a refused cast spends nothing and passes no turn', () {
      // arrange
      final game = _caster(
        mana: 0,
        monsters: [ghoul('n', const Position(4, 1))],
      );

      // act
      final (after, _) = step(game, const CastSpellAction('firebolt'));

      // assert
      expect(after.mana, 0);
      expect(after.skills, game.skills);
      expect(after.rng.state, game.rng.state);
    });
  });
}

const BaseItem _potionBase = BaseItem(
  id: 'healing-potion',
  name: 'Healing Potion',
  glyph: '!',
  heal: 10,
);

/// How many times a generator advanced between two exported states.
int _advances(int from, int to) {
  final walk = Rng.fromState(from);
  for (var steps = 1; steps <= 4; steps++) {
    walk.rollRange(0, 1);
    if (walk.state == to) return steps;
  }
  return from == to ? 0 : -1;
}
