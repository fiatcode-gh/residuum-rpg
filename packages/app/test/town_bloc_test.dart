import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/town/town_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

Item _cap(String id) => Item(id: id, base: leatherCap, rarity: Rarity.common);

Profile _fresh() => newProfile(worldSeed: 4);

Profile _rich() => _fresh().copyWith(gold: 500, inventory: [_cap('held-1')]);

/// The shelf as it stood before the run, so the restock can be compared to it.
/// A `blocTest` gives `act` and `verify` no other way to share a value.
List<String> _shelfBefore = const [];

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
      act: (bloc) => bloc.add(const EnterDungeonPressed()),
      verify: (bloc) {
        expect(bloc.state.run, isNotNull);
        expect(bloc.state.run!.visit, 1);
        expect(bloc.state.run!.depth, 1);
      },
    );

    blocTest<TownBloc, TownViewState>(
      'the run carries the pack and the purse down with it',
      build: () => TownBloc(profile: _rich()),
      act: (bloc) => bloc.add(const EnterDungeonPressed()),
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
        bloc.add(const EnterDungeonPressed());
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
        bloc.add(const EnterDungeonPressed());
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
        bloc.add(const EnterDungeonPressed());
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
        bloc.add(const EnterDungeonPressed());
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
        bloc.add(const EnterDungeonPressed());
        await bloc.stream.first;
        bloc.add(RunEnded(bloc.state.run!, died: true));
        await bloc.stream.first;
        bloc.add(const EnterDungeonPressed());
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
        bloc.add(const EnterDungeonPressed());
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
          isNot(contains('market-0-potion-1')),
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
        bloc.add(const EnterDungeonPressed());
        await bloc.stream.firstWhere((state) => state.run != null);
        bloc.add(RunEnded(bloc.state.run!, died: true));
      },
      verify: (bloc) =>
          expect((bloc.state.gold, bloc.state.bankedGold), (0, 400)),
    );
  });
}
