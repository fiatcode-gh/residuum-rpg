import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

sealed class TownBlocEvent {
  const TownBlocEvent();
}

final class EnterDungeonPressed extends TownBlocEvent {
  const EnterDungeonPressed();
}

/// The run is over, one way or the other.
final class RunEnded extends TownBlocEvent {
  const RunEnded(this.state, {required this.died});

  final GameState state;
  final bool died;
}

final class BuyPressed extends TownBlocEvent {
  const BuyPressed(this.itemId);

  final String itemId;
}

final class SellPressed extends TownBlocEvent {
  const SellPressed(this.itemId);

  final String itemId;
}

final class RestPressed extends TownBlocEvent {
  const RestPressed();
}

final class DepositItemPressed extends TownBlocEvent {
  const DepositItemPressed(this.itemId);

  final String itemId;
}

final class WithdrawItemPressed extends TownBlocEvent {
  const WithdrawItemPressed(this.itemId);

  final String itemId;
}

final class WearPressed extends TownBlocEvent {
  const WearPressed(this.itemId);

  final String itemId;
}

final class TakeOffPressed extends TownBlocEvent {
  const TakeOffPressed(this.slot);

  final EquipSlot slot;
}

final class DepositGoldPressed extends TownBlocEvent {
  const DepositGoldPressed(this.amount);

  final int amount;
}

final class WithdrawGoldPressed extends TownBlocEvent {
  const WithdrawGoldPressed(this.amount);

  final int amount;
}

class TownViewState {
  const TownViewState({
    required this.profile,
    required this.stock,
    this.run,
    this.notice,
  });

  final Profile profile;

  /// What the merchant is still holding this visit.
  final List<Item> stock;

  /// The crawl in progress, or null while the hero is in town.
  final GameState? run;

  /// The last refusal, for the screen to read out. Cleared by the next thing
  /// that works.
  final String? notice;

  int get gold => profile.gold;

  int get bankedGold => profile.bankedGold;

  int get hp => profile.hero.hp;

  int get maxHp => profile.maxHp;

  /// Whether a bed would do the hero any good.
  bool get canRest => profile.hero.hp < profile.maxHp;
}

/// Owns the hero between runs, and the two doors into and out of the dungeon.
///
/// The dungeon has its own bloc. This one never touches a [GameState] except to
/// hand one over at the door and take one back at the end, which is the same
/// line `startRun` and `endRun` draw in the rules.
class TownBloc extends Bloc<TownBlocEvent, TownViewState> {
  TownBloc({required Profile profile})
    : super(
        TownViewState(
          profile: profile,
          stock: merchantStock(profile.worldSeed, profile.visit),
        ),
      ) {
    on<EnterDungeonPressed>(_onEnterDungeon);
    on<RunEnded>(_onRunEnded);
    on<BuyPressed>(_onBuy);
    on<SellPressed>(_onSell);
    on<RestPressed>(_onRest);
    on<DepositItemPressed>(_onDepositItem);
    on<WithdrawItemPressed>(_onWithdrawItem);
    on<WearPressed>(_onWear);
    on<TakeOffPressed>(_onTakeOff);
    on<DepositGoldPressed>(_onDepositGold);
    on<WithdrawGoldPressed>(_onWithdrawGold);
  }

  void _onEnterDungeon(
    EnterDungeonPressed event,
    Emitter<TownViewState> emit,
  ) => emit(
    TownViewState(
      profile: state.profile,
      stock: state.stock,
      run: startDungeonRun(state.profile),
    ),
  );

  void _onRunEnded(RunEnded event, Emitter<TownViewState> emit) {
    final home = endRun(state.profile, event.state, died: event.died);
    emit(
      TownViewState(
        profile: home,
        stock: merchantStock(home.worldSeed, home.visit),
      ),
    );
  }

  void _onBuy(BuyPressed event, Emitter<TownViewState> emit) {
    final offered = _find(state.stock, event.itemId);
    if (offered == null) return;
    final (after, refusal) = buyItem(
      state.profile,
      offered,
      buyPriceOf(offered),
    );
    emit(
      _settled(
        after,
        refusal,
        stock: refusal == null
            ? _without(state.stock, event.itemId)
            : state.stock,
      ),
    );
  }

  void _onSell(SellPressed event, Emitter<TownViewState> emit) {
    final carried = _find(state.profile.inventory, event.itemId);
    if (carried == null) return;
    emit(
      _transacted(sellItem(state.profile, event.itemId, sellPriceOf(carried))),
    );
  }

  void _onRest(RestPressed event, Emitter<TownViewState> emit) =>
      emit(_transacted(restAtInn(state.profile, innPrice)));

  void _onDepositItem(DepositItemPressed event, Emitter<TownViewState> emit) =>
      emit(_transacted(depositItem(state.profile, event.itemId)));

  void _onWithdrawItem(
    WithdrawItemPressed event,
    Emitter<TownViewState> emit,
  ) => emit(_transacted(withdrawItem(state.profile, event.itemId)));

  void _onWear(WearPressed event, Emitter<TownViewState> emit) =>
      emit(_transacted(equipItem(state.profile, event.itemId)));

  void _onTakeOff(TakeOffPressed event, Emitter<TownViewState> emit) =>
      emit(_transacted(unequipItem(state.profile, event.slot)));

  void _onDepositGold(DepositGoldPressed event, Emitter<TownViewState> emit) =>
      emit(_transacted(depositGold(state.profile, event.amount)));

  void _onWithdrawGold(
    WithdrawGoldPressed event,
    Emitter<TownViewState> emit,
  ) => emit(_transacted(withdrawGold(state.profile, event.amount)));

  TownViewState _transacted(Transacted result) =>
      _settled(result.$1, result.$2);

  TownViewState _settled(
    Profile profile,
    TownRefusal? refusal, {
    List<Item>? stock,
  }) => TownViewState(
    profile: profile,
    stock: stock ?? state.stock,
    notice: refusal?.reason,
  );

  static Item? _find(List<Item> items, String itemId) {
    for (final item in items) {
      if (item.id == itemId) return item;
    }
    return null;
  }

  static List<Item> _without(List<Item> items, String itemId) => [
    for (final item in items)
      if (item.id != itemId) item,
  ];
}
