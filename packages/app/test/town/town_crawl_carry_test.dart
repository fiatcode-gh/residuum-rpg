import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/town/town_bloc.dart';
import 'package:residuum_app/town/town_crawl.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../support/standing.dart';

/// A town whose hero is camped away from a crawl at the crypt.
TownBloc _camped() => TownBloc(
  profile: newProfile(worldSeed: 5).copyWith(gold: 500),
  crawl: CampStanding(
    startDungeonRunAt(cryptNode, newProfile(worldSeed: 5)),
    cryptNode,
    3,
  ),
);

/// Whether the camp is exactly where it was: same crawl, same place, same day.
void _campSurvived(TownBloc bloc) {
  expect(bloc.state.suspended, isNotNull);
  expect(bloc.state.dungeon, cryptNode);
  expect(bloc.state.campDay, 3);
}

/// The town's stock item, for a purchase.
Item _onTheShelf(TownBloc bloc) => bloc.state.stock.first;

/// The hero's first carried item.
Item _firstCarried(TownBloc bloc) => bloc.state.profile.inventory.first;

void main() {
  group('every town handler preserves an arriving camp', () {
    final rows = <(String, TownBlocEvent Function(TownBloc bloc))>[
      ('a purchase', (bloc) => BuyPressed(_onTheShelf(bloc).id)),
      ('a sale', (bloc) => SellPressed(_firstCarried(bloc).id)),
      ('a rest at the inn', (bloc) => const RestPressed()),
      (
        'a deposit into the vault',
        (bloc) => DepositItemPressed(_firstCarried(bloc).id),
      ),
      ('a deposit of gold', (bloc) => const DepositGoldPressed(10)),
      ('a withdrawal of gold', (bloc) => const WithdrawGoldPressed(10)),
      ('wearing a piece', (bloc) => WearPressed(_firstCarried(bloc).id)),
      (
        'taking a piece off',
        (bloc) => const TakeOffPressed(EquipSlot.mainHand),
      ),
      ('reading a book', (bloc) => ReadBookPressed(_firstCarried(bloc).id)),
      ('a smelt', (bloc) => const SmeltPressed()),
      ('a brew', (bloc) => const BrewPressed()),
      ('a temper', (bloc) => TemperPressed(_firstCarried(bloc).id)),
      (
        'a rumor bought',
        (bloc) => RumorBought(
          buyRumor(bloc.state.profile, atTheCrypt(), rumorPool, rumorPrice),
        ),
      ),
      (
        'a road fight ended',
        (bloc) => EncounterEnded(
          startRoadEncounter(bloc.state.profile, day: 4),
          died: false,
        ),
      ),
      (
        'arriving at the town they were in',
        (bloc) => ArrivedInTown(bloc.state.town),
      ),
    ];

    for (final (String what, TownBlocEvent Function(TownBloc) eventOf)
        in rows) {
      blocTest<TownBloc, TownViewState>(
        '$what keeps the camp',
        build: _camped,
        act: (bloc) => bloc.add(eventOf(bloc)),
        verify: _campSurvived,
      );
    }
  });
}
