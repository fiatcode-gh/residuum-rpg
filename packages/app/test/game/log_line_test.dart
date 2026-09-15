import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/event_messages.dart';
import 'package:residuum_app/game/log_line.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

void main() {
  group('describeEvent and LogCategory', () {
    test('direction is read from the variant, not the words', () {
      // arrange
      const names = {'ghoul-1': 'the ghoul'};
      const hit = AttackHit(attackerId: heroId, targetId: 'ghoul-1', damage: 4);
      const struck = AttackHit(
        attackerId: 'ghoul-1',
        targetId: heroId,
        damage: 3,
      );
      const dodged = AttackDodged(attackerId: 'ghoul-1');

      // act
      final hitLine = describeEvent(hit, names);
      final struckLine = describeEvent(struck, names);
      final dodgedLine = describeEvent(dodged, names);

      // assert
      expect(
        hitLine,
        const LogLine('You hit the ghoul for 4.', LogCategory.hit),
      );
      expect(
        struckLine,
        const LogLine('The ghoul claws you for 3.', LogCategory.struck),
      );
      expect(
        dodgedLine,
        const LogLine('The ghoul swings and misses.', LogCategory.struck),
      );
    });

    test('refusal is distinguished from movement', () {
      // arrange
      const moved = ActorMoved(
        actorId: heroId,
        from: Position(1, 1),
        to: Position(2, 1),
      );
      const blocked = MoveBlocked(actorId: heroId, at: Position(2, 1));
      const descended = Descended(newDepth: 2);
      const ascended = Ascended(newDepth: 1);
      const full = InventoryFull();
      const refused = ActionRefused(reason: 'you cannot do that');

      // act
      final categories = <GameEvent>[
        moved,
        blocked,
        descended,
        ascended,
        full,
        refused,
      ].map((event) => describeEvent(event, const {})?.category).toList();

      // assert
      expect(categories, [
        LogCategory.moved,
        LogCategory.refused,
        LogCategory.moved,
        LogCategory.moved,
        LogCategory.refused,
        LogCategory.refused,
      ]);
    });

    test(
      'the event mapping is total and no event-reachable member is dead',
      () {
        // arrange
        const names = {'ghoul-1': 'the ghoul'};
        final sword = Item(
          id: 'sword-1',
          base: ironSword,
          rarity: Rarity.common,
        );
        final potion = Item(
          id: 'potion-1',
          base: healingPotion,
          rarity: Rarity.common,
        );
        final book = Item(
          id: 'book-1',
          base: bookOfFirebolt,
          rarity: Rarity.common,
        );
        final events = <GameEvent>[
          const ActorMoved(
            actorId: heroId,
            from: Position(1, 1),
            to: Position(2, 1),
          ),
          const MoveBlocked(actorId: heroId, at: Position(2, 1)),
          const AttackHit(attackerId: heroId, targetId: 'ghoul-1', damage: 4),
          const AttackHit(attackerId: 'ghoul-1', targetId: heroId, damage: 3),
          const ActorDied(actorId: heroId),
          const ActorDied(actorId: 'ghoul-1'),
          const ActorNoticed(actorId: 'ghoul-1', at: Position(2, 1)),
          const Descended(newDepth: 2),
          const Ascended(newDepth: 1),
          const AttackDodged(attackerId: 'ghoul-1'),
          ItemDropped(item: sword, at: const Position(1, 1)),
          ItemPickedUp(item: sword),
          const InventoryFull(),
          ItemEquipped(item: sword, slot: EquipSlot.mainHand),
          ItemUnequipped(item: sword, slot: EquipSlot.mainHand),
          const ActionRefused(reason: 'you cannot do that'),
          PotionDrunk(item: potion, healed: 0),
          PotionDrunk(item: potion, healed: 8),
          SpellLearned(book: book, spell: firebolt),
          SpellHit(
            spell: firebolt,
            targetId: 'ghoul-1',
            damage: 5,
            bite: SpellBite.plain,
          ),
          const MendCast(healed: 0),
          const MendCast(healed: 5),
          const WardRaised(absorbs: 5),
          const WardStruck(absorbed: 2, remaining: 0),
          const WardStruck(absorbed: 2, remaining: 3),
          const MonsterBound(targetId: 'ghoul-1', turns: 3),
          const MonsterBanished(
            targetId: 'ghoul-1',
            from: Position(1, 1),
            to: Position(2, 2),
          ),
          NodeGathered(
            kind: GatherKind.oreVein,
            at: const Position(1, 1),
            material: MaterialId.ore,
          ),
          const SkillLevelledUp(skill: SkillId.arms, level: 1),
          const Fled(),
          const HeroWaited(),
        ];

        // act
        final categories = {
          for (final event in events)
            if (describeEvent(event, names) case final LogLine line)
              line.category,
        };

        // assert
        expect(
          categories,
          LogCategory.values.toSet()..remove(LogCategory.reported),
        );
      },
    );

    test('the three silent variants stay silent', () {
      // arrange
      const monsterMoved = ActorMoved(
        actorId: 'ghoul-1',
        from: Position(1, 1),
        to: Position(2, 1),
      );
      const monsterBlocked = MoveBlocked(
        actorId: 'ghoul-1',
        at: Position(2, 1),
      );
      const gameOver = GameOver();

      // act + assert
      expect(describeEvent(monsterMoved, const {}), isNull);
      expect(describeEvent(monsterBlocked, const {}), isNull);
      expect(describeEvent(gameOver, const {}), isNull);
    });

    test('every category has a distinct mark and a distinct word', () {
      // act
      final marks = LogCategory.values.map((category) => category.mark).toSet();
      final words = LogCategory.values.map((category) => category.word).toSet();

      // assert
      expect(marks, hasLength(LogCategory.values.length));
      expect(words, hasLength(LogCategory.values.length));
      expect(marks.every((mark) => mark.isNotEmpty), isTrue);
      expect(words.every((word) => word.isNotEmpty), isTrue);
    });
  });
}
