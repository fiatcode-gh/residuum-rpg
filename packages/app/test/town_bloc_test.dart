import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/town/town_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

Item _cap(String id) => Item(id: id, base: leatherCap, rarity: Rarity.common);

Item _gear(String id, BaseItem base) =>
    Item(id: id, base: base, rarity: Rarity.common);

Profile _fresh() => newProfile(worldSeed: 4);

Profile _rich() => _fresh().copyWith(gold: 500, inventory: [_cap('held-1')]);

/// A hero schooled in two spells and stocked from the floors, for the road
/// carry tests.
Profile _schooled() => _rich().copyWith(
  knownSpells: {firebolt.id, mend.id},
  materials: const {MaterialId.ore: 3, MaterialId.herb: 1},
);

/// The shelf as it stood before the run, so the restock can be compared to it.
/// A `blocTest` gives `act` and `verify` no other way to share a value.
List<String> _shelfBefore = const [];

/// The id bought in `act`, for `verify` to look for. Same reason.
String _boughtId = '';

/// A crawl to hand a suspend event when the bloc has not opened one yet.
GameState _anyRun() => startDungeonRunAt(cryptNode, _fresh());

void main() {
  group('TownBloc', () {
    test('starts in town on a fresh profile with a stocked shelf', () {
      // arrange
      final bloc = TownBloc(profile: _fresh());

      // act
      final opening = (bloc.state.run, bloc.state.profile.visit);

      // assert
      expect(opening, (null, 0));
      expect(bloc.state.stock, isNotEmpty);
    });

    blocTest<TownBloc, TownViewState>(
      'entering the dungeon starts a run on the bumped visit',
      build: () => TownBloc(profile: _fresh()),
      act: (bloc) => bloc.add(EnterDungeonPressed(cryptNode)),
      verify: (bloc) {
        expect(bloc.state.run, isNotNull);
        expect(bloc.state.run!.visit, 1);
        expect(bloc.state.run!.depth, 1);
      },
    );

    blocTest<TownBloc, TownViewState>(
      'the run carries the pack and the purse down with it',
      build: () => TownBloc(profile: _rich()),
      act: (bloc) => bloc.add(EnterDungeonPressed(cryptNode)),
      verify: (bloc) {
        expect(bloc.state.run!.gold, 500);
        expect(
          bloc.state.run!.inventory.map((item) => item.id),
          contains('held-1'),
        );
      },
    );

    blocTest<TownBloc, TownViewState>(
      'leaving alive brings the haul home and clears the run',
      build: () => TownBloc(profile: _fresh()),
      act: (bloc) async {
        bloc.add(EnterDungeonPressed(cryptNode));
        await bloc.stream.first;
        bloc.add(
          RunEnded(
            bloc.state.run!.copyWith(inventory: [_cap('loot-1')]),
            died: false,
          ),
        );
      },
      verify: (bloc) {
        expect(bloc.state.run, isNull);
        expect(
          bloc.state.profile.inventory.map((item) => item.id),
          contains('loot-1'),
        );
      },
    );

    blocTest<TownBloc, TownViewState>(
      'leaving alive does not heal the wounds the run left',
      build: () => TownBloc(profile: _fresh()),
      act: (bloc) async {
        bloc.add(EnterDungeonPressed(cryptNode));
        await bloc.stream.first;
        final run = bloc.state.run!;
        bloc.add(
          RunEnded(run.copyWith(hero: run.hero.copyWith(hp: 3)), died: false),
        );
      },
      verify: (bloc) => expect(bloc.state.hp, 3),
    );

    blocTest<TownBloc, TownViewState>(
      'dying strips the pack and the purse but not the vault',
      build: () => TownBloc(
        profile: _fresh().copyWith(bank: [_cap('vault-1')], bankedGold: 90),
      ),
      act: (bloc) async {
        bloc.add(EnterDungeonPressed(cryptNode));
        await bloc.stream.first;
        bloc.add(
          RunEnded(
            bloc.state.run!.copyWith(inventory: [_cap('loot-1')]),
            died: true,
          ),
        );
      },
      verify: (bloc) {
        expect(bloc.state.profile.inventory, isEmpty);
        expect(bloc.state.profile.gold, 0);
        expect(bloc.state.profile.bank.single.id, 'vault-1');
        expect(bloc.state.profile.bankedGold, 90);
      },
    );

    blocTest<TownBloc, TownViewState>(
      'dying keeps the gear the hero was wearing and wakes it whole',
      build: () => TownBloc(profile: _fresh()),
      act: (bloc) async {
        bloc.add(EnterDungeonPressed(cryptNode));
        await bloc.stream.first;
        final run = bloc.state.run!;
        bloc.add(
          RunEnded(run.copyWith(hero: run.hero.copyWith(hp: 0)), died: true),
        );
      },
      verify: (bloc) {
        expect(
          bloc.state.profile.equipment[EquipSlot.mainHand]!.base.id,
          'rusty-sword',
        );
        expect(bloc.state.hp, bloc.state.maxHp);
      },
    );

    blocTest<TownBloc, TownViewState>(
      're-entering after a death reshuffles the dungeon',
      build: () => TownBloc(profile: _fresh()),
      act: (bloc) async {
        bloc.add(EnterDungeonPressed(cryptNode));
        await bloc.stream.first;
        bloc.add(RunEnded(bloc.state.run!, died: true));
        await bloc.stream.first;
        bloc.add(EnterDungeonPressed(cryptNode));
      },
      verify: (bloc) => expect(bloc.state.run!.visit, 2),
    );

    blocTest<TownBloc, TownViewState>(
      'coming home restocks the shelf',
      build: () => TownBloc(profile: _fresh()),
      act: (bloc) async {
        _shelfBefore = bloc.state.stock
            .map((item) => item.displayName)
            .toList();
        bloc.add(EnterDungeonPressed(cryptNode));
        await bloc.stream.first;
        bloc.add(RunEnded(bloc.state.run!, died: false));
      },
      verify: (bloc) {
        expect(bloc.state.stock, isNotEmpty);
        expect(
          bloc.state.stock.map((item) => item.displayName).toList(),
          isNot(_shelfBefore),
        );
      },
    );

    blocTest<TownBloc, TownViewState>(
      'buying takes the gold, stocks the pack and clears the shelf slot',
      build: () => TownBloc(profile: _rich()),
      act: (bloc) => bloc.add(BuyPressed(bloc.state.stock.first.id)),
      verify: (bloc) {
        expect(bloc.state.profile.gold, lessThan(500));
        expect(bloc.state.profile.inventory.length, 2);
        expect(
          bloc.state.stock.map((item) => item.id),
          isNot(contains('market-stonebridge-0-potion-1')),
        );
        expect(
          merchantStock(
            bloc.state.profile.worldSeed,
            bloc.state.profile.visit,
            bloc.state.town,
          ).map((item) => item.id),
          contains('market-stonebridge-0-potion-1'),
        );
      },
    );

    blocTest<TownBloc, TownViewState>(
      'a purchase the purse cannot cover changes nothing and says why',
      build: () => TownBloc(profile: _fresh()),
      act: (bloc) => bloc.add(BuyPressed(bloc.state.stock.first.id)),
      verify: (bloc) {
        expect(bloc.state.profile.gold, 0);
        expect(bloc.state.notice, 'you cannot afford that');
        expect(bloc.state.stock.length, greaterThan(0));
      },
    );

    blocTest<TownBloc, TownViewState>(
      'selling turns an item into coins at the selling price',
      build: () => TownBloc(profile: _rich()),
      act: (bloc) => bloc.add(const SellPressed('held-1')),
      verify: (bloc) {
        expect(bloc.state.profile.gold, 500 + sellPriceOf(_cap('held-1')));
        expect(
          bloc.state.profile.inventory.map((item) => item.id),
          isNot(contains('held-1')),
        );
      },
    );

    blocTest<TownBloc, TownViewState>(
      'buying then selling the same thing back loses money',
      build: () => TownBloc(profile: _rich()),
      act: (bloc) async {
        final offered = bloc.state.stock.first;
        bloc.add(BuyPressed(offered.id));
        await bloc.stream.first;
        bloc.add(SellPressed(offered.id));
      },
      verify: (bloc) => expect(bloc.state.profile.gold, lessThan(500)),
    );

    blocTest<TownBloc, TownViewState>(
      'resting heals to the ceiling and takes the fee',
      build: () => TownBloc(
        profile: _rich().copyWith(hero: _fresh().hero.copyWith(hp: 5)),
      ),
      act: (bloc) => bloc.add(const RestPressed()),
      verify: (bloc) {
        expect(bloc.state.hp, bloc.state.maxHp);
        expect(bloc.state.profile.gold, 500 - innPrice);
      },
    );

    blocTest<TownBloc, TownViewState>(
      'a hero with nothing wrong with it is not sold a bed',
      build: () => TownBloc(profile: _rich()),
      act: (bloc) => bloc.add(const RestPressed()),
      verify: (bloc) {
        expect(bloc.state.profile.gold, 500);
        expect(bloc.state.notice, 'there is nothing wrong with you');
      },
    );

    blocTest<TownBloc, TownViewState>(
      'banking an item moves it out of reach of death',
      build: () => TownBloc(profile: _rich()),
      act: (bloc) => bloc.add(const DepositItemPressed('held-1')),
      verify: (bloc) {
        expect(bloc.state.profile.inventory, isEmpty);
        expect(bloc.state.profile.bank.single.id, 'held-1');
      },
    );

    blocTest<TownBloc, TownViewState>(
      'a banked item comes back out on request',
      build: () => TownBloc(profile: _rich()),
      act: (bloc) {
        bloc.add(const DepositItemPressed('held-1'));
        bloc.add(const WithdrawItemPressed('held-1'));
      },
      verify: (bloc) {
        expect(bloc.state.profile.bank, isEmpty);
        expect(bloc.state.profile.inventory.single.id, 'held-1');
      },
    );

    blocTest<TownBloc, TownViewState>(
      'gold goes into the vault and comes back out',
      build: () => TownBloc(profile: _rich()),
      act: (bloc) {
        bloc.add(const DepositGoldPressed(200));
        bloc.add(const WithdrawGoldPressed(50));
      },
      verify: (bloc) =>
          expect((bloc.state.gold, bloc.state.bankedGold), (350, 150)),
    );

    blocTest<TownBloc, TownViewState>(
      'a withdrawal the vault cannot cover changes nothing and says why',
      build: () => TownBloc(profile: _rich()),
      act: (bloc) => bloc.add(const WithdrawGoldPressed(50)),
      verify: (bloc) {
        expect(bloc.state.bankedGold, 0);
        expect(bloc.state.notice, 'the vault does not hold that much');
      },
    );

    blocTest<TownBloc, TownViewState>(
      'banked gold survives a death in the dungeon',
      build: () => TownBloc(profile: _rich()),
      act: (bloc) async {
        bloc.add(const DepositGoldPressed(400));
        bloc.add(EnterDungeonPressed(cryptNode));
        await bloc.stream.firstWhere((state) => state.run != null);
        bloc.add(RunEnded(bloc.state.run!, died: true));
      },
      verify: (bloc) =>
          expect((bloc.state.gold, bloc.state.bankedGold), (0, 400)),
    );
  });

  group('TownBloc dressing the hero', () {
    blocTest<TownBloc, TownViewState>(
      'wearing a carried piece moves it into its slot',
      build: () => TownBloc(
        profile: _fresh().copyWith(
          inventory: [_gear('held-1', kiteShield)],
          equipment: const {},
        ),
      ),
      act: (bloc) => bloc.add(const WearPressed('held-1')),
      verify: (bloc) {
        expect(bloc.state.profile.equipment[EquipSlot.offHand]?.id, 'held-1');
        expect(bloc.state.profile.inventory, isEmpty);
        expect(bloc.state.notice, isNull);
      },
    );

    blocTest<TownBloc, TownViewState>(
      'wearing what the hero is not carrying says why and changes nothing',
      build: () => TownBloc(profile: _fresh()),
      act: (bloc) => bloc.add(const WearPressed('nowhere-1')),
      verify: (bloc) {
        expect(bloc.state.notice, 'you are not carrying that');
        expect(bloc.state.profile.inventory, _fresh().inventory);
      },
    );

    blocTest<TownBloc, TownViewState>(
      'wearing something that is not gear at all says why',
      build: () => TownBloc(
        profile: _fresh().copyWith(inventory: [_gear('held-1', healingPotion)]),
      ),
      act: (bloc) => bloc.add(const WearPressed('held-1')),
      verify: (bloc) {
        expect(bloc.state.notice, 'Healing Potion is not worn');
        expect(bloc.state.profile.equipment[EquipSlot.offHand], isNull);
      },
    );

    blocTest<TownBloc, TownViewState>(
      'a shield is refused while both hands are on the weapon',
      build: () => TownBloc(
        profile: _fresh().copyWith(
          inventory: [_gear('held-1', kiteShield)],
          equipment: {EquipSlot.mainHand: _gear('worn-1', maul)},
        ),
      ),
      act: (bloc) => bloc.add(const WearPressed('held-1')),
      verify: (bloc) {
        expect(bloc.state.notice, 'both hands are on the weapon');
        expect(bloc.state.profile.equipment[EquipSlot.offHand], isNull);
      },
    );

    blocTest<TownBloc, TownViewState>(
      'taking a piece off stows it in the pack',
      build: () => TownBloc(
        profile: _fresh().copyWith(
          inventory: const [],
          equipment: {EquipSlot.head: _cap('worn-1')},
        ),
      ),
      act: (bloc) => bloc.add(const TakeOffPressed(EquipSlot.head)),
      verify: (bloc) {
        expect(bloc.state.profile.equipment[EquipSlot.head], isNull);
        expect(bloc.state.profile.inventory.single.id, 'worn-1');
        expect(bloc.state.notice, isNull);
      },
    );

    blocTest<TownBloc, TownViewState>(
      'taking off an empty slot says why',
      build: () => TownBloc(profile: _fresh().copyWith(equipment: const {})),
      act: (bloc) => bloc.add(const TakeOffPressed(EquipSlot.head)),
      verify: (bloc) => expect(bloc.state.notice, 'nothing is on your head'),
    );

    blocTest<TownBloc, TownViewState>(
      'a full pack refuses the take-off rather than dropping the gear',
      build: () => TownBloc(
        profile: _fresh().copyWith(
          inventory: [
            for (var index = 0; index < inventoryCap; index++)
              _cap('held-$index'),
          ],
          equipment: {EquipSlot.head: _cap('worn-1')},
        ),
      ),
      act: (bloc) => bloc.add(const TakeOffPressed(EquipSlot.head)),
      verify: (bloc) {
        expect(bloc.state.notice, 'your hands are too full to stow it');
        expect(bloc.state.profile.equipment[EquipSlot.head]?.id, 'worn-1');
      },
    );

    blocTest<TownBloc, TownViewState>(
      'a piece worn in town is worn in the dungeon',
      build: () => TownBloc(
        profile: _fresh().copyWith(
          inventory: [_gear('held-1', kiteShield)],
          equipment: const {},
        ),
      ),
      act: (bloc) async {
        bloc.add(const WearPressed('held-1'));
        await bloc.stream.first;
        bloc.add(EnterDungeonPressed(cryptNode));
      },
      verify: (bloc) =>
          expect(bloc.state.run!.equipment[EquipSlot.offHand]?.id, 'held-1'),
    );

    blocTest<TownBloc, TownViewState>(
      'a wear that works clears the notice a refusal left behind',
      build: () => TownBloc(
        profile: _fresh().copyWith(
          inventory: [_gear('held-1', kiteShield)],
          equipment: const {},
        ),
      ),
      act: (bloc) async {
        bloc.add(const TakeOffPressed(EquipSlot.chest));
        await bloc.stream.first;
        bloc.add(const WearPressed('held-1'));
      },
      verify: (bloc) => expect(bloc.state.notice, isNull),
    );
  });

  group('the boot notice', () {
    test('a report from the save layer is the first thing the town says', () {
      // arrange
      const report =
          'your last save could not be read; an older one was restored';

      // act
      final bloc = TownBloc(profile: _fresh(), notice: report);

      // assert
      expect(bloc.state.notice, report);
    });

    test('the next thing that works clears it', () async {
      // arrange
      final bloc = TownBloc(profile: _rich(), notice: 'something went wrong');

      // act
      bloc.add(const DepositGoldPressed(10));
      final after = await bloc.stream.first;

      // assert
      expect(after.notice, isNull);
    });
  });

  group('coming home off the road', () {
    blocTest<TownBloc, TownViewState>(
      'brings the spells and the materials home too',
      build: () => TownBloc(profile: _schooled()),
      act: (bloc) => bloc.add(
        EncounterEnded(
          startRoadEncounter(bloc.state.profile, day: 4),
          died: false,
        ),
      ),
      verify: (bloc) {
        expect(bloc.state.profile.knownSpells, {firebolt.id, mend.id});
        expect(bloc.state.profile.materials[MaterialId.ore], 3);
        expect(bloc.state.profile.materials[MaterialId.herb], 1);
      },
    );

    blocTest<TownBloc, TownViewState>(
      'brings back what was picked up out there',
      build: () => TownBloc(profile: _rich()),
      act: (bloc) {
        final fight = startRoadEncounter(bloc.state.profile, day: 4);
        bloc.add(
          EncounterEnded(
            fight.copyWith(
              inventory: [
                ...fight.inventory,
                const Item(id: 'road-1', base: leatherCap, rarity: Rarity.fine),
              ],
            ),
            died: false,
          ),
        );
      },
      verify: (bloc) => expect(
        bloc.state.profile.inventory.map((item) => item.id),
        contains('road-1'),
      ),
    );

    blocTest<TownBloc, TownViewState>(
      'dying out there costs the pack and the purse and nothing else',
      build: () => TownBloc(profile: _rich()),
      act: (bloc) => bloc.add(
        EncounterEnded(
          startRoadEncounter(bloc.state.profile, day: 4),
          died: true,
        ),
      ),
      verify: (bloc) {
        expect(bloc.state.profile.gold, 0);
        expect(bloc.state.profile.inventory, isEmpty);
        expect(bloc.state.profile.equipment, isNotEmpty);
        expect(bloc.state.profile.hero.hp, bloc.state.profile.maxHp);
      },
    );

    blocTest<TownBloc, TownViewState>(
      'dying out there leaves the camp standing at the crypt',
      build: () => TownBloc(
        profile: _rich(),
        suspended: startDungeonRunAt(cryptNode, _rich()).copyWith(depth: 3),
        dungeon: cryptNode,
        campDay: 0,
      ),
      act: (bloc) => bloc.add(
        EncounterEnded(
          startRoadEncounter(bloc.state.profile, day: 4),
          died: true,
        ),
      ),
      verify: (bloc) {
        expect(bloc.state.suspended, isNotNull);
        expect(bloc.state.suspended!.depth, 3);
      },
    );

    blocTest<TownBloc, TownViewState>(
      'walking away from a fight leaves the camp standing too',
      build: () => TownBloc(
        profile: _rich(),
        suspended: startDungeonRunAt(cryptNode, _rich()).copyWith(depth: 2),
        dungeon: cryptNode,
        campDay: 0,
      ),
      act: (bloc) => bloc.add(
        EncounterEnded(
          startRoadEncounter(bloc.state.profile, day: 4),
          died: false,
        ),
      ),
      verify: (bloc) => expect(bloc.state.suspended!.depth, 2),
    );

    blocTest<TownBloc, TownViewState>(
      'never moves the visit, so a camp stays resumable',
      build: () {
        final camped = suspendRun(
          _rich(),
          startDungeonRunAt(cryptNode, _rich()),
        );
        return TownBloc(
          profile: camped,
          suspended: startDungeonRunAt(cryptNode, _rich()),
          dungeon: cryptNode,
          campDay: 0,
        );
      },
      act: (bloc) => bloc.add(
        EncounterEnded(
          startRoadEncounter(bloc.state.profile, day: 4),
          died: false,
        ),
      ),
      verify: (bloc) =>
          expect(bloc.state.profile.visit, bloc.state.suspended!.visit),
    );

    blocTest<TownBloc, TownViewState>(
      'leaves the shelf and what the merchant remembers alone',
      build: () => TownBloc(profile: _rich()),
      act: (bloc) async {
        bloc.add(BuyPressed(bloc.state.stock.first.id));
        await bloc.stream.first;
        bloc.add(
          EncounterEnded(
            startRoadEncounter(bloc.state.profile, day: 4),
            died: false,
          ),
        );
      },
      verify: (bloc) {
        expect(bloc.state.merchant.bought, hasLength(1));
        expect(bloc.state.town, stonebridge);
      },
    );
  });

  group('walking into a town', () {
    blocTest<TownBloc, TownViewState>(
      'the other town puts a different shelf on the counter',
      build: () => TownBloc(profile: _rich(), town: stonebridge),
      act: (bloc) => bloc.add(ArrivedInTown(northgate)),
      verify: (bloc) {
        expect(bloc.state.town, northgate);
        expect(
          bloc.state.stock.map((item) => item.id),
          merchantStock(
            bloc.state.profile.worldSeed,
            bloc.state.profile.visit,
            northgate,
          ).map((item) => item.id),
        );
      },
    );

    blocTest<TownBloc, TownViewState>(
      'the other town forgets what this one remembered',
      build: () => TownBloc(profile: _rich(), town: stonebridge),
      act: (bloc) async {
        bloc.add(BuyPressed(bloc.state.stock.first.id));
        await bloc.stream.first;
        bloc.add(ArrivedInTown(northgate));
      },
      verify: (bloc) {
        expect(bloc.state.merchant, MerchantVisit.none);
        expect(bloc.state.stock, hasLength(greaterThan(0)));
      },
    );

    blocTest<TownBloc, TownViewState>(
      'coming back to the same town remembers everything it did',
      build: () => TownBloc(profile: _rich(), town: stonebridge),
      act: (bloc) async {
        bloc.add(BuyPressed(bloc.state.stock.first.id));
        await bloc.stream.first;
        bloc.add(ArrivedInTown(stonebridge));
      },
      verify: (bloc) {
        expect(bloc.state.merchant.bought, hasLength(1));
        expect(
          bloc.state.stock.map((item) => item.id),
          isNot(contains(bloc.state.merchant.bought.single)),
        );
      },
    );

    blocTest<TownBloc, TownViewState>(
      'a bought item stays bought while the hero is away and back',
      build: () => TownBloc(profile: _rich(), town: stonebridge),
      act: (bloc) async {
        bloc.add(BuyPressed(bloc.state.stock.first.id));
        await bloc.stream.first;
        bloc.add(ArrivedInTown(northgate));
        await bloc.stream.first;
        bloc.add(ArrivedInTown(stonebridge));
      },
      verify: (bloc) {
        expect(bloc.state.town, stonebridge);
        expect(bloc.state.merchant, MerchantVisit.none);
      },
    );

    blocTest<TownBloc, TownViewState>(
      'arriving anywhere leaves the camp exactly where it is',
      build: () => TownBloc(
        profile: _rich(),
        town: stonebridge,
        suspended: startDungeonRunAt(cryptNode, _rich()),
        dungeon: cryptNode,
        campDay: 0,
      ),
      act: (bloc) => bloc.add(ArrivedInTown(northgate)),
      verify: (bloc) {
        expect(bloc.state.suspended, isNotNull);
        expect(bloc.state.run, isNull);
      },
    );
  });

  group('the merchant remembers this visit', () {
    test('a hero who already bought does not see it on the shelf', () {
      // arrange
      final all = merchantStock(4, 0, stonebridge);

      // act
      final bloc = TownBloc(
        profile: _fresh(),
        merchant: MerchantVisit(bought: [all.first.id], town: stonebridge),
      );

      // assert
      expect(
        bloc.state.stock.map((item) => item.id),
        isNot(contains(all.first.id)),
      );
      expect(bloc.state.stock, hasLength(all.length - 1));
    });

    blocTest<TownBloc, TownViewState>(
      'buying writes the purchase into the visit',
      build: () => TownBloc(profile: _rich()),
      act: (bloc) => bloc.add(BuyPressed(bloc.state.stock.first.id)),
      verify: (bloc) {
        expect(bloc.state.merchant.bought, hasLength(1));
        expect(
          bloc.state.stock.map((item) => item.id),
          isNot(contains(bloc.state.merchant.bought.single)),
        );
      },
    );

    blocTest<TownBloc, TownViewState>(
      'a refused purchase remembers nothing',
      build: () => TownBloc(profile: _fresh()),
      act: (bloc) => bloc.add(BuyPressed(bloc.state.stock.first.id)),
      verify: (bloc) {
        expect(bloc.state.merchant.bought, isEmpty);
        expect(bloc.state.notice, 'you cannot afford that');
      },
    );

    blocTest<TownBloc, TownViewState>(
      'selling puts the item on the counter to be bought back',
      build: () => TownBloc(profile: _rich()),
      act: (bloc) => bloc.add(const SellPressed('held-1')),
      verify: (bloc) {
        expect(bloc.state.merchant.sold.single.id, 'held-1');
        expect(bloc.state.profile.inventory, isEmpty);
      },
    );

    blocTest<TownBloc, TownViewState>(
      'buying back costs exactly what the sale paid',
      build: () => TownBloc(profile: _rich()),
      act: (bloc) async {
        bloc.add(const SellPressed('held-1'));
        await bloc.stream.first;
        bloc.add(const BuyBackPressed('held-1'));
      },
      verify: (bloc) {
        expect(bloc.state.profile.gold, 500);
        expect(bloc.state.profile.inventory.single.id, 'held-1');
        expect(bloc.state.merchant.sold, isEmpty);
      },
    );

    blocTest<TownBloc, TownViewState>(
      'buying back is cheaper than buying the same thing off the shelf',
      build: () => TownBloc(profile: _rich()),
      act: (bloc) async {
        bloc.add(const SellPressed('held-1'));
        await bloc.stream.first;
        bloc.add(const BuyBackPressed('held-1'));
      },
      verify: (bloc) {
        final paid =
            500 + sellPriceOf(_cap('held-1')) - bloc.state.profile.gold;
        expect(paid, sellPriceOf(_cap('held-1')));
        expect(paid, lessThan(buyPriceOf(_cap('held-1'))));
      },
    );

    blocTest<TownBloc, TownViewState>(
      'buying back what is not on the counter does nothing',
      build: () => TownBloc(profile: _rich()),
      act: (bloc) => bloc.add(const BuyBackPressed('held-1')),
      verify: (bloc) {
        expect(bloc.state.merchant.sold, isEmpty);
        expect(bloc.state.profile.inventory.single.id, 'held-1');
        expect(bloc.state.profile.gold, 500);
      },
    );

    blocTest<TownBloc, TownViewState>(
      'a buy-back the purse cannot cover leaves it on the counter',
      build: () =>
          TownBloc(profile: _fresh().copyWith(inventory: [_cap('held-1')])),
      act: (bloc) async {
        bloc.add(const SellPressed('held-1'));
        await bloc.stream.first;
        bloc.add(DepositGoldPressed(bloc.state.profile.gold));
        await bloc.stream.first;
        bloc.add(const BuyBackPressed('held-1'));
      },
      verify: (bloc) {
        expect(bloc.state.notice, 'you cannot afford that');
        expect(bloc.state.merchant.sold.single.id, 'held-1');
      },
    );

    blocTest<TownBloc, TownViewState>(
      'coming home clears what the merchant remembered',
      build: () => TownBloc(profile: _rich()),
      act: (bloc) async {
        bloc.add(BuyPressed(bloc.state.stock.first.id));
        await bloc.stream.first;
        bloc.add(const SellPressed('held-1'));
        await bloc.stream.first;
        bloc.add(EnterDungeonPressed(cryptNode));
        await bloc.stream.first;
        bloc.add(RunEnded(bloc.state.run!, died: false));
      },
      verify: (bloc) {
        expect(bloc.state.merchant, MerchantVisit.none);
        expect(bloc.state.stock, isNotEmpty);
      },
    );

    blocTest<TownBloc, TownViewState>(
      'walking in keeps the visit, because the shelf has not been rolled again',
      build: () => TownBloc(profile: _rich()),
      act: (bloc) async {
        bloc.add(const SellPressed('held-1'));
        await bloc.stream.first;
        bloc.add(EnterDungeonPressed(cryptNode));
      },
      verify: (bloc) => expect(bloc.state.merchant.sold.single.id, 'held-1'),
    );

    blocTest<TownBloc, TownViewState>(
      'a transaction with nothing to do with the shop carries the visit',
      build: () => TownBloc(profile: _rich()),
      act: (bloc) async {
        bloc.add(const SellPressed('held-1'));
        await bloc.stream.first;
        bloc.add(const DepositGoldPressed(10));
      },
      verify: (bloc) => expect(bloc.state.merchant.sold.single.id, 'held-1'),
    );
  });

  group('leaving the crawl standing', () {
    blocTest<TownBloc, TownViewState>(
      'suspending brings the hero home and keeps the crawl',
      build: () => TownBloc(profile: _fresh()),
      act: (bloc) async {
        bloc.add(EnterDungeonPressed(cryptNode));
        await bloc.stream.first;
        final run = bloc.state.run!;
        bloc.add(
          RunSuspended(
            run.copyWith(
              hero: run.hero.copyWith(hp: 3),
              inventory: [_cap('loot-1')],
              depth: 2,
            ),
            day: 0,
          ),
        );
      },
      verify: (bloc) {
        expect(bloc.state.run, isNull);
        expect(bloc.state.suspended!.depth, 2);
        expect(bloc.state.profile.hero.hp, 3);
        expect(
          bloc.state.profile.inventory.map((item) => item.id),
          contains('loot-1'),
        );
        expect(bloc.state.profile.visit, bloc.state.suspended!.visit);
      },
    );

    blocTest<TownBloc, TownViewState>(
      'suspending forgets the visit the merchant remembered',
      build: () => TownBloc(profile: _rich()),
      act: (bloc) async {
        bloc.add(BuyPressed(bloc.state.stock.first.id));
        await bloc.stream.first;
        bloc.add(EnterDungeonPressed(cryptNode));
        await bloc.stream.first;
        bloc.add(RunSuspended(bloc.state.run!, day: 0));
      },
      verify: (bloc) {
        expect(bloc.state.merchant, MerchantVisit.none);
        expect(bloc.state.suspended, isNotNull);
      },
    );

    blocTest<TownBloc, TownViewState>(
      'the shelf a camped hero shops at is the one their visit rolled',
      build: () => TownBloc(profile: _fresh()),
      act: (bloc) async {
        bloc.add(EnterDungeonPressed(cryptNode));
        await bloc.stream.first;
        bloc.add(RunSuspended(bloc.state.run!, day: 0));
      },
      verify: (bloc) {
        expect(
          bloc.state.stock.map((item) => item.id),
          merchantStock(
            bloc.state.profile.worldSeed,
            bloc.state.profile.visit,
            bloc.state.town,
          ).map((item) => item.id),
        );
      },
    );

    blocTest<TownBloc, TownViewState>(
      'shopping while camped does not lose the camp',
      build: () => TownBloc(
        profile: _rich(),
        suspended: startDungeonRunAt(cryptNode, _rich()),
        dungeon: cryptNode,
        campDay: 0,
      ),
      act: (bloc) async {
        bloc.add(BuyPressed(bloc.state.stock.first.id));
        await bloc.stream.first;
        bloc.add(const RestPressed());
        await bloc.stream.first;
        bloc.add(const DepositGoldPressed(10));
      },
      verify: (bloc) => expect(bloc.state.suspended, isNotNull),
    );

    blocTest<TownBloc, TownViewState>(
      'selling while camped keeps the camp, streams and all',
      build: () => TownBloc(
        profile: _rich(),
        suspended: startDungeonRunAt(cryptNode, _rich()),
        dungeon: cryptNode,
        campDay: 0,
      ),
      act: (bloc) => bloc.add(const SellPressed('held-1')),
      verify: (bloc) {
        expect(
          bloc.state.suspended!.rng.state,
          startDungeonRunAt(cryptNode, _rich()).rng.state,
        );
      },
    );

    blocTest<TownBloc, TownViewState>(
      'a refused transaction does not lose the camp either',
      build: () => TownBloc(
        profile: _fresh(),
        suspended: startDungeonRunAt(cryptNode, _fresh()),
        dungeon: cryptNode,
        campDay: 0,
      ),
      act: (bloc) => bloc.add(const WithdrawGoldPressed(9999)),
      verify: (bloc) {
        expect(bloc.state.notice, isNotNull);
        expect(bloc.state.suspended, isNotNull);
      },
    );

    blocTest<TownBloc, TownViewState>(
      'resuming hands back the crawl with the town business in it',
      build: () => TownBloc(
        profile: _rich(),
        suspended: startDungeonRunAt(cryptNode, _fresh()),
        dungeon: cryptNode,
        campDay: 0,
      ),
      act: (bloc) async {
        bloc.add(BuyPressed(bloc.state.stock.first.id));
        await bloc.stream.first;
        bloc.add(const ResumeCrawlPressed(day: 0));
      },
      verify: (bloc) {
        expect(bloc.state.suspended, isNull);
        expect(bloc.state.run, isNotNull);
        expect(bloc.state.run!.gold, bloc.state.profile.gold);
        expect(
          bloc.state.run!.inventory.map((item) => item.id),
          bloc.state.profile.inventory.map((item) => item.id),
        );
      },
    );

    blocTest<TownBloc, TownViewState>(
      'resuming does not reshuffle the dungeon',
      build: () => TownBloc(
        profile: _fresh().copyWith(visit: 1),
        suspended: startDungeonRunAt(cryptNode, _fresh()),
        dungeon: cryptNode,
        campDay: 0,
      ),
      act: (bloc) => bloc.add(const ResumeCrawlPressed(day: 0)),
      verify: (bloc) {
        expect(bloc.state.run!.visit, 1);
        expect(
          bloc.state.run!.map.toAscii(),
          startDungeonRunAt(cryptNode, _fresh()).map.toAscii(),
        );
      },
    );

    blocTest<TownBloc, TownViewState>(
      'suspending writes down the day the camp was pitched',
      build: () => TownBloc(profile: _fresh()),
      act: (bloc) async {
        bloc.add(EnterDungeonPressed(cryptNode));
        await bloc.stream.first;
        bloc.add(RunSuspended(bloc.state.run!, day: 9));
      },
      verify: (bloc) => expect(bloc.state.campDay, 9),
    );

    blocTest<TownBloc, TownViewState>(
      'a camp three days old is overrun and cannot be walked back into',
      build: () => TownBloc(
        profile: _fresh(),
        suspended: startDungeonRunAt(cryptNode, _fresh()),
        dungeon: cryptNode,
        campDay: 4,
      ),
      act: (bloc) => bloc.add(const ResumeCrawlPressed(day: 7)),
      expect: () => [],
    );

    blocTest<TownBloc, TownViewState>(
      'a camp two days old is still there to walk back into',
      build: () => TownBloc(
        profile: _fresh(),
        suspended: startDungeonRunAt(cryptNode, _fresh()),
        dungeon: cryptNode,
        campDay: 4,
      ),
      act: (bloc) => bloc.add(const ResumeCrawlPressed(day: 6)),
      verify: (bloc) => expect(bloc.state.run, isNotNull),
    );

    blocTest<TownBloc, TownViewState>(
      'walking back down forgets the day the camp was pitched',
      build: () => TownBloc(
        profile: _fresh(),
        suspended: startDungeonRunAt(cryptNode, _fresh()),
        dungeon: cryptNode,
        campDay: 0,
      ),
      act: (bloc) => bloc.add(const ResumeCrawlPressed(day: 0)),
      verify: (bloc) => expect(bloc.state.campDay, isNull),
    );

    blocTest<TownBloc, TownViewState>(
      'giving the camp up forgets the day it was pitched',
      build: () => TownBloc(
        profile: _fresh(),
        suspended: startDungeonRunAt(cryptNode, _fresh()),
        dungeon: cryptNode,
        campDay: 0,
      ),
      act: (bloc) => bloc.add(DelveAnewPressed(cryptNode)),
      verify: (bloc) => expect(bloc.state.campDay, isNull),
    );

    blocTest<TownBloc, TownViewState>(
      'a transaction in town leaves the day the camp was pitched alone',
      build: () => TownBloc(
        profile: _rich(),
        suspended: startDungeonRunAt(cryptNode, _fresh()),
        dungeon: cryptNode,
        campDay: 6,
      ),
      act: (bloc) => bloc.add(BuyPressed(bloc.state.stock.first.id)),
      verify: (bloc) => expect(bloc.state.campDay, 6),
    );

    blocTest<TownBloc, TownViewState>(
      'resuming a crawl nobody camped in does nothing at all',
      build: () => TownBloc(profile: _fresh()),
      act: (bloc) => bloc.add(const ResumeCrawlPressed(day: 0)),
      expect: () => [],
    );

    blocTest<TownBloc, TownViewState>(
      'delving anew gives the camp up and reshuffles',
      build: () => TownBloc(
        profile: _fresh().copyWith(visit: 1),
        suspended: startDungeonRunAt(cryptNode, _fresh()),
        dungeon: cryptNode,
        campDay: 0,
      ),
      act: (bloc) => bloc.add(DelveAnewPressed(cryptNode)),
      verify: (bloc) {
        expect(bloc.state.suspended, isNull);
        expect(bloc.state.run!.visit, 2);
        expect(bloc.state.run!.depth, 1);
      },
    );

    blocTest<TownBloc, TownViewState>(
      'dying in a resumed crawl leaves no camp behind',
      build: () => TownBloc(
        profile: _fresh(),
        suspended: startDungeonRunAt(cryptNode, _fresh()),
        dungeon: cryptNode,
        campDay: 0,
      ),
      act: (bloc) async {
        bloc.add(const ResumeCrawlPressed(day: 0));
        await bloc.stream.first;
        final run = bloc.state.run!;
        bloc.add(
          RunEnded(
            run.copyWith(hero: run.hero.copyWith(hp: 0), isGameOver: true),
            died: true,
          ),
        );
      },
      verify: (bloc) {
        expect(bloc.state.suspended, isNull);
        expect(bloc.state.run, isNull);
      },
    );

    blocTest<TownBloc, TownViewState>(
      'entering fresh from town leaves no camp behind either',
      build: () => TownBloc(profile: _fresh()),
      act: (bloc) => bloc.add(EnterDungeonPressed(cryptNode)),
      verify: (bloc) {
        expect(bloc.state.suspended, isNull);
        expect(bloc.state.run, isNotNull);
      },
    );

    blocTest<TownBloc, TownViewState>(
      'walking out of a resumed crawl keeps the visit the merchant remembers',
      build: () {
        final camp = startDungeonRunAt(cryptNode, _rich());
        return TownBloc(
          profile: suspendRun(_rich(), camp),
          suspended: camp,
          dungeon: cryptNode,
          campDay: 0,
        );
      },
      act: (bloc) async {
        _boughtId = bloc.state.stock.first.id;
        bloc.add(BuyPressed(_boughtId));
        await bloc.stream.first;
        bloc.add(const ResumeCrawlPressed(day: 0));
        await bloc.stream.first;
        bloc.add(RunSuspended(bloc.state.run!, day: 0));
      },
      verify: (bloc) {
        expect(bloc.state.merchant.bought, [_boughtId]);
        expect(
          bloc.state.stock.map((item) => item.id),
          isNot(contains(_boughtId)),
        );
        expect(
          bloc.state.profile.inventory.where((item) => item.id == _boughtId),
          hasLength(1),
        );
      },
    );

    blocTest<TownBloc, TownViewState>(
      'completing a resumed delve keeps the visit the merchant remembers',
      build: () {
        final camp = startDungeonRunAt(cryptNode, _rich());
        return TownBloc(
          profile: suspendRun(_rich(), camp),
          suspended: camp,
          dungeon: cryptNode,
          campDay: 0,
        );
      },
      act: (bloc) async {
        _boughtId = bloc.state.stock.first.id;
        bloc.add(BuyPressed(_boughtId));
        await bloc.stream.first;
        bloc.add(const ResumeCrawlPressed(day: 0));
        await bloc.stream.first;
        bloc.add(RunEnded(bloc.state.run!, died: false));
      },
      verify: (bloc) {
        expect(bloc.state.merchant.bought, [_boughtId]);
        expect(
          bloc.state.stock.map((item) => item.id),
          isNot(contains(_boughtId)),
        );
        expect(
          bloc.state.profile.inventory.where((item) => item.id == _boughtId),
          hasLength(1),
        );
        expect(bloc.state.suspended, isNull);
      },
    );

    blocTest<TownBloc, TownViewState>(
      'dying in a resumed crawl keeps it too, because the visit did not move',
      build: () {
        final camp = startDungeonRunAt(cryptNode, _rich());
        return TownBloc(
          profile: suspendRun(_rich(), camp),
          suspended: camp,
          dungeon: cryptNode,
          campDay: 0,
        );
      },
      act: (bloc) async {
        _boughtId = bloc.state.stock.first.id;
        bloc.add(BuyPressed(_boughtId));
        await bloc.stream.first;
        bloc.add(const ResumeCrawlPressed(day: 0));
        await bloc.stream.first;
        bloc.add(RunEnded(bloc.state.run!, died: true));
      },
      verify: (bloc) {
        expect(bloc.state.merchant.bought, [_boughtId]);
        expect(
          bloc.state.stock.map((item) => item.id),
          isNot(contains(_boughtId)),
        );
        expect(bloc.state.suspended, isNull);
      },
    );

    blocTest<TownBloc, TownViewState>(
      'walking out of a resumed crawl keeps what is on the counter too',
      build: () {
        final camp = startDungeonRunAt(cryptNode, _rich());
        return TownBloc(
          profile: suspendRun(_rich(), camp),
          suspended: camp,
          dungeon: cryptNode,
          campDay: 0,
        );
      },
      act: (bloc) async {
        bloc.add(const SellPressed('held-1'));
        await bloc.stream.first;
        bloc.add(const ResumeCrawlPressed(day: 0));
        await bloc.stream.first;
        bloc.add(RunSuspended(bloc.state.run!, day: 0));
      },
      verify: (bloc) => expect(bloc.state.merchant.sold.single.id, 'held-1'),
    );

    test('a crawl to enter and a crawl to go back to are never both '
        'waiting', () async {
      // arrange
      final bloc = TownBloc(
        profile: _fresh(),
        suspended: startDungeonRunAt(cryptNode, _fresh()),
        dungeon: cryptNode,
        campDay: 0,
      );
      final seen = <(bool, bool)>[];

      // act
      bloc.add(const ResumeCrawlPressed(day: 0));
      final resumed = await bloc.stream.first;
      bloc.add(RunSuspended(resumed.run!, day: 0));
      final camped = await bloc.stream.first;
      for (final state in [bloc.state, resumed, camped]) {
        seen.add((state.run != null, state.suspended != null));
      }

      // assert
      expect(seen, everyElement(isNot((true, true))));
      await bloc.close();
    });
  });

  group('which dungeon the town opens', () {
    blocTest<TownBloc, TownViewState>(
      'entering at the sea-cave starts the sea-cave, not the crypt',
      build: () => TownBloc(profile: _fresh()),
      act: (bloc) => bloc.add(EnterDungeonPressed(seaCave)),
      verify: (bloc) {
        expect(bloc.state.dungeon, seaCave);
        expect(
          bloc.state.run!.map.toAscii(),
          startDungeonRunAt(seaCave, _fresh()).map.toAscii(),
        );
      },
    );

    blocTest<TownBloc, TownViewState>(
      'entering at the ruined keep starts the ruined keep',
      build: () => TownBloc(profile: _fresh()),
      act: (bloc) => bloc.add(EnterDungeonPressed(ruinedKeep)),
      verify: (bloc) {
        expect(bloc.state.dungeon, ruinedKeep);
        expect(
          bloc.state.run!.map.toAscii(),
          startDungeonRunAt(ruinedKeep, _fresh()).map.toAscii(),
        );
      },
    );

    blocTest<TownBloc, TownViewState>(
      'delving anew at a node gives the camp up for that node',
      build: () => TownBloc(
        profile: _fresh(),
        suspended: startDungeonRunAt(cryptNode, _fresh()),
        dungeon: cryptNode,
        campDay: 0,
      ),
      act: (bloc) => bloc.add(DelveAnewPressed(seaCave)),
      verify: (bloc) {
        expect(bloc.state.dungeon, seaCave);
        expect(bloc.state.suspended, isNull);
        expect(
          bloc.state.run!.map.toAscii(),
          startDungeonRunAt(seaCave, _fresh()).map.toAscii(),
        );
      },
    );

    blocTest<TownBloc, TownViewState>(
      'walking out at the stairs leaves the camp with its dungeon on it',
      build: () => TownBloc(profile: _fresh()),
      act: (bloc) async {
        bloc.add(EnterDungeonPressed(seaCave));
        final entered = await bloc.stream.first;
        bloc.add(RunSuspended(entered.run!, day: 0));
      },
      verify: (bloc) {
        expect(bloc.state.suspended, isNotNull);
        expect(bloc.state.dungeon, seaCave);
      },
    );

    blocTest<TownBloc, TownViewState>(
      'a transaction while camped carries the camp\'s dungeon forward',
      build: () => TownBloc(
        profile: _rich(),
        suspended: startDungeonRunAt(seaCave, _rich()),
        dungeon: seaCave,
        campDay: 0,
      ),
      act: (bloc) => bloc.add(const RestPressed()),
      verify: (bloc) {
        expect(bloc.state.suspended, isNotNull);
        expect(bloc.state.dungeon, seaCave);
      },
    );

    blocTest<TownBloc, TownViewState>(
      'arriving in a town carries the camp\'s dungeon forward',
      build: () => TownBloc(
        profile: _rich(),
        suspended: startDungeonRunAt(ruinedKeep, _rich()),
        dungeon: ruinedKeep,
        campDay: 0,
      ),
      act: (bloc) => bloc.add(ArrivedInTown(northgate)),
      verify: (bloc) {
        expect(bloc.state.suspended, isNotNull);
        expect(bloc.state.dungeon, ruinedKeep);
      },
    );

    blocTest<TownBloc, TownViewState>(
      'a fight on the road leaves the camp\'s dungeon where it was',
      build: () => TownBloc(
        profile: _rich(),
        suspended: startDungeonRunAt(seaCave, _rich()),
        dungeon: seaCave,
        campDay: 0,
      ),
      act: (bloc) => bloc.add(
        EncounterEnded(startRoadEncounter(_rich(), day: 3), died: true),
      ),
      verify: (bloc) {
        expect(bloc.state.suspended, isNotNull);
        expect(bloc.state.dungeon, seaCave);
      },
    );

    blocTest<TownBloc, TownViewState>(
      'the run ending takes the dungeon with it',
      build: () => TownBloc(profile: _fresh()),
      act: (bloc) async {
        bloc.add(EnterDungeonPressed(seaCave));
        final entered = await bloc.stream.first;
        bloc.add(RunEnded(entered.run!, died: true));
      },
      verify: (bloc) {
        expect(bloc.state.run, isNull);
        expect(bloc.state.suspended, isNull);
        expect(bloc.state.dungeon, isNull);
      },
    );

    blocTest<TownBloc, TownViewState>(
      'walking back into a camp keeps saying which dungeon it is',
      build: () => TownBloc(
        profile: _fresh(),
        suspended: startDungeonRunAt(ruinedKeep, _fresh()),
        dungeon: ruinedKeep,
        campDay: 0,
      ),
      act: (bloc) => bloc.add(const ResumeCrawlPressed(day: 0)),
      verify: (bloc) {
        expect(bloc.state.run, isNotNull);
        expect(bloc.state.dungeon, ruinedKeep);
      },
    );

    blocTest<TownBloc, TownViewState>(
      'entering a new dungeon bumps the visit and turns the shelf over',
      build: () => TownBloc(profile: _rich()),
      act: (bloc) async {
        bloc.add(BuyPressed(bloc.state.stock.first.id));
        await bloc.stream.first;
        bloc.add(EnterDungeonPressed(seaCave));
        final entered = await bloc.stream.first;
        bloc.add(RunEnded(entered.run!, died: false));
      },
      verify: (bloc) {
        expect(bloc.state.profile.visit, 1);
        expect(bloc.state.merchant, MerchantVisit.none);
        expect(bloc.state.stock, isNotEmpty);
      },
    );
  });

  group('reading a book in town', () {
    Profile carrying(BaseItem book, {Map<SkillId, SkillState>? skills}) =>
        _fresh().copyWith(
          inventory: [_gear('held-9', book)],
          skills: skills ?? untrainedSkills,
        );

    blocTest<TownBloc, TownViewState>(
      'learns the spell and spends the page, and no gold changes hands',
      build: () => TownBloc(profile: carrying(bookOfFirebolt)),
      act: (bloc) => bloc.add(const ReadBookPressed('held-9')),
      verify: (bloc) {
        expect(bloc.state.profile.knownSpells, {'firebolt'});
        expect(bloc.state.profile.inventory, isEmpty);
        expect(bloc.state.profile.gold, _fresh().gold);
        expect(bloc.state.notice, isNull);
      },
    );

    blocTest<TownBloc, TownViewState>(
      'a book past its gate is refused in the dungeon\'s own sentence',
      build: () => TownBloc(profile: carrying(bookOfFrostLance)),
      act: (bloc) => bloc.add(const ReadBookPressed('held-9')),
      verify: (bloc) {
        expect(bloc.state.profile.knownSpells, isEmpty);
        expect(bloc.state.profile.inventory, hasLength(1));
        expect(bloc.state.notice, 'needs Wrath 4');
      },
    );

    blocTest<TownBloc, TownViewState>(
      'the same book goes through once the school reaches the gate',
      build: () => TownBloc(
        profile: carrying(
          bookOfFrostLance,
          skills: {
            ...untrainedSkills,
            SkillId.wrath: const SkillState(level: 4),
          },
        ),
      ),
      act: (bloc) => bloc.add(const ReadBookPressed('held-9')),
      verify: (bloc) {
        expect(bloc.state.profile.knownSpells, {'frost-lance'});
      },
    );

    blocTest<TownBloc, TownViewState>(
      'a spell already known is refused rather than charged for twice',
      build: () => TownBloc(
        profile: carrying(bookOfFirebolt)
            .copyWith(knownSpells: const {'firebolt'}),
      ),
      act: (bloc) => bloc.add(const ReadBookPressed('held-9')),
      verify: (bloc) {
        expect(bloc.state.profile.inventory, hasLength(1));
        expect(bloc.state.notice, 'you already know Firebolt');
      },
    );

    blocTest<TownBloc, TownViewState>(
      'what was learned in town walks into the dungeon',
      build: () => TownBloc(profile: carrying(bookOfMend)),
      act: (bloc) {
        bloc.add(const ReadBookPressed('held-9'));
        bloc.add(EnterDungeonPressed(cryptNode));
      },
      verify: (bloc) {
        expect(bloc.state.run!.knownSpells, {'mend'});
        expect(bloc.state.run!.mana, heroMaxMana(bloc.state.profile.loadout));
      },
    );
  });

  group('the forge', () {
    blocTest<TownBloc, TownViewState>(
      'smelts ore into an ingot and trains Blacksmith',
      build: () => TownBloc(
        profile: _fresh().copyWith(materials: const {MaterialId.ore: 2}),
      ),
      act: (bloc) => bloc.add(const SmeltPressed()),
      verify: (bloc) {
        expect(bloc.state.profile.materials, const {MaterialId.ingot: 1});
        expect(bloc.state.profile.skills[SkillId.blacksmith]!.xp, 1);
      },
    );

    blocTest<TownBloc, TownViewState>(
      'refuses in a sentence when there is not enough ore',
      build: () => TownBloc(
        profile: _fresh().copyWith(materials: const {MaterialId.ore: 1}),
      ),
      act: (bloc) => bloc.add(const SmeltPressed()),
      verify: (bloc) {
        expect(bloc.state.notice, 'that takes 2 ore');
        expect(bloc.state.profile.materials, const {MaterialId.ore: 1});
      },
    );

    blocTest<TownBloc, TownViewState>(
      'says so on the notice line when a craft level arrives',
      build: () => TownBloc(
        profile: _fresh().copyWith(
          materials: const {MaterialId.ore: 2},
          skills: {
            ...untrainedSkills,
            SkillId.blacksmith: SkillState(xp: xpToNext(0) - 1),
          },
        ),
      ),
      act: (bloc) => bloc.add(const SmeltPressed()),
      verify: (bloc) {
        expect(bloc.state.notice, 'Blacksmith rises to 1');
        expect(bloc.state.profile.skills[SkillId.blacksmith]!.level, 1);
      },
    );

    blocTest<TownBloc, TownViewState>(
      'tempers a carried weapon, spending the iron and the gold',
      build: () => TownBloc(
        profile: _fresh().copyWith(
          gold: 100,
          inventory: [_gear('drop-1', ironSword)],
          materials: const {MaterialId.ingot: 2},
        ),
      ),
      act: (bloc) => bloc.add(const TemperPressed('drop-1')),
      verify: (bloc) {
        expect(bloc.state.profile.inventory.single.temper, 1);
        expect(bloc.state.profile.gold, 90);
        expect(bloc.state.profile.materials, const {MaterialId.ingot: 1});
      },
    );

    blocTest<TownBloc, TownViewState>(
      'tempers the piece the hero is wearing',
      build: () => TownBloc(
        profile: _fresh().copyWith(
          gold: 100,
          equipment: {EquipSlot.chest: _gear('drop-2', mailHauberk)},
          materials: const {MaterialId.ingot: 1},
        ),
      ),
      act: (bloc) => bloc.add(const TemperPressed('drop-2')),
      verify: (bloc) {
        expect(bloc.state.profile.equipment[EquipSlot.chest]!.temper, 1);
      },
    );

    blocTest<TownBloc, TownViewState>(
      'refuses a potion in the forge\'s own words',
      build: () => TownBloc(
        profile: _fresh().copyWith(materials: const {MaterialId.ingot: 4}),
      ),
      act: (bloc) => bloc.add(const TemperPressed('kit-2')),
      verify: (bloc) {
        expect(bloc.state.notice, 'only steel takes a temper');
      },
    );

    test('offers only the steel, worn pieces first', () {
      // arrange
      final bloc = TownBloc(
        profile: _fresh().copyWith(
          equipment: {EquipSlot.chest: _gear('drop-2', mailHauberk)},
          inventory: [
            _gear('drop-1', ironSword),
            _gear('kit-2', healingPotion),
          ],
        ),
      );

      // act
      final workable = bloc.state.temperable.map((item) => item.id);

      // assert - the piece most worth working is usually the one they have on
      expect(workable, ['drop-2', 'drop-1']);
      addTearDown(bloc.close);
    });

    test(
      'hands the screen the same reason the transaction would refuse with',
      () {
        // arrange
        final bloc = TownBloc(
          profile: _fresh().copyWith(
            inventory: [_gear('drop-1', ironSword)],
            materials: const {},
          ),
        );

        // act
        final shown = bloc.state.temperReason('drop-1');

        // assert - a button that greyed itself out on its own arithmetic would
        // eventually disagree with the rules
        expect(shown, temperRefusal(bloc.state.profile, 'drop-1'));
        expect(shown, isNotNull);
        addTearDown(bloc.close);
      },
    );
  });

  group('the alchemist', () {
    blocTest<TownBloc, TownViewState>(
      'brews a potion into the pack and trains Herbcraft',
      build: () => TownBloc(
        profile: _fresh().copyWith(materials: const {MaterialId.herb: 3}),
      ),
      act: (bloc) => bloc.add(const BrewPressed()),
      verify: (bloc) {
        expect(bloc.state.profile.inventory.last.base, healingPotion);
        expect(bloc.state.profile.inventory.last.id, 'brew-1');
        expect(bloc.state.profile.skills[SkillId.herbcraft]!.xp, 1);
        expect(bloc.state.profile.materials, isEmpty);
      },
    );

    blocTest<TownBloc, TownViewState>(
      'refuses in a sentence when there are not enough herbs',
      build: () => TownBloc(profile: _fresh()),
      act: (bloc) => bloc.add(const BrewPressed()),
      verify: (bloc) {
        expect(bloc.state.notice, 'that takes 3 herbs');
      },
    );

    blocTest<TownBloc, TownViewState>(
      'refuses a full pack in the merchant\'s exact words',
      build: () => TownBloc(
        profile: _fresh().copyWith(
          materials: const {MaterialId.herb: 3},
          inventory: [
            for (var made = 0; made < inventoryCap; made++)
              _gear('kit-$made', healingPotion),
          ],
        ),
      ),
      act: (bloc) => bloc.add(const BrewPressed()),
      verify: (bloc) {
        expect(bloc.state.notice, 'you cannot carry any more');
      },
    );
  });

  group('what the craft handlers must not drop', () {
    blocTest<TownBloc, TownViewState>(
      'smelting keeps the camp, the dungeon and the day it was pitched',
      build: () => TownBloc(
        profile: _fresh().copyWith(materials: const {MaterialId.ore: 2}),
      ),
      act: (bloc) {
        bloc.add(EnterDungeonPressed(cryptNode));
        bloc.add(RunSuspended(bloc.state.run ?? _anyRun(), day: 4));
        bloc.add(const SmeltPressed());
      },
      verify: (bloc) {
        expect(bloc.state.suspended, isNotNull);
        expect(bloc.state.dungeon, cryptNode);
        expect(bloc.state.campDay, 4);
      },
    );

    blocTest<TownBloc, TownViewState>(
      'brewing keeps what the merchant remembers of this visit',
      build: () => TownBloc(
        profile: _fresh().copyWith(
          gold: 500,
          materials: const {MaterialId.herb: 3},
        ),
      ),
      act: (bloc) {
        _boughtId = bloc.state.stock.first.id;
        bloc.add(BuyPressed(_boughtId));
        bloc.add(const BrewPressed());
      },
      verify: (bloc) {
        expect(bloc.state.merchant.bought, [_boughtId]);
        expect(
          bloc.state.stock.map((item) => item.id),
          isNot(contains(_boughtId)),
        );
      },
    );

    blocTest<TownBloc, TownViewState>(
      'tempering keeps the camp too',
      build: () => TownBloc(
        profile: _fresh().copyWith(
          gold: 100,
          inventory: [_gear('drop-1', ironSword)],
          materials: const {MaterialId.ingot: 1},
        ),
      ),
      act: (bloc) {
        bloc.add(EnterDungeonPressed(cryptNode));
        bloc.add(RunSuspended(bloc.state.run ?? _anyRun(), day: 2));
        bloc.add(const TemperPressed('drop-1'));
      },
      verify: (bloc) {
        expect(bloc.state.suspended, isNotNull);
        expect(bloc.state.campDay, 2);
      },
    );
  });
}
