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

/// The player wants a sale back.
final class BuyBackPressed extends TownBlocEvent {
  const BuyBackPressed(this.itemId);

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
    this.merchant = MerchantVisit.none,
    this.run,
    this.notice,
  });

  final Profile profile;

  /// What the merchant is still holding this visit.
  final List<Item> stock;

  /// What the merchant remembers of this visit: what was bought off the shelf,
  /// and what was sold across the counter and can still be bought back.
  ///
  /// Carried forward by every handler. A purchase is a fact about the visit that
  /// the player paid for, so a handler that quietly dropped it would put a bought
  /// item back on the shelf the next time anything at all happened in town.
  final MerchantVisit merchant;

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
  TownBloc({
    required Profile profile,
    MerchantVisit merchant = MerchantVisit.none,
    String? notice,
  }) : super(
         TownViewState(
           profile: profile,
           stock: merchant.stillOnTheShelf(
             merchantStock(profile.worldSeed, profile.visit),
           ),
           merchant: merchant,
           notice: notice,
         ),
       ) {
    on<EnterDungeonPressed>(_onEnterDungeon);
    on<RunEnded>(_onRunEnded);
    on<BuyPressed>(_onBuy);
    on<SellPressed>(_onSell);
    on<BuyBackPressed>(_onBuyBack);
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
      merchant: state.merchant,
      run: startDungeonRun(state.profile),
    ),
  );

  /// Brings the run home, and forgets the visit with it.
  ///
  /// The merchant re-stocks per visit by design, so the shelf is rolled again
  /// here — and what was bought off the old shelf names ids that no longer
  /// exist, while what is on the counter was sold to a shop that has since
  /// turned over its stock. Both lists are left off the new state, which is what
  /// clears them.
  void _onRunEnded(RunEnded event, Emitter<TownViewState> emit) {
    final home = endRun(state.profile, event.state, died: event.died);
    emit(
      TownViewState(
        profile: home,
        stock: merchantStock(home.worldSeed, home.visit),
      ),
    );
  }

  /// Takes an item off the shelf, and writes down that it is gone.
  ///
  /// The purchase goes into the visit as well as off the stock list, because the
  /// stock list is thrown away when the app closes while the visit is saved. A
  /// shop that only cleared the list put the whole shelf back on the next launch,
  /// and buying the same roll twice gave the pack two items under one id.
  void _onBuy(BuyPressed event, Emitter<TownViewState> emit) {
    final offered = _find(state.stock, event.itemId);
    if (offered == null) return;
    final (after, refusal) = buyItem(
      state.profile,
      offered,
      buyPriceOf(offered),
    );
    if (refusal != null) {
      emit(_settled(after, refusal));
      return;
    }
    emit(
      _settled(
        after,
        null,
        stock: _without(state.stock, event.itemId),
        merchant: state.merchant.withBought(event.itemId),
      ),
    );
  }

  void _onSell(SellPressed event, Emitter<TownViewState> emit) {
    final carried = _find(state.profile.inventory, event.itemId);
    if (carried == null) return;
    final (after, refusal) = sellItem(
      state.profile,
      event.itemId,
      sellPriceOf(carried),
    );
    emit(
      _settled(
        after,
        refusal,
        merchant: refusal == null
            ? state.merchant.withSold(carried)
            : state.merchant,
      ),
    );
  }

  /// Undoes a sale at the price it paid.
  ///
  /// **[sellPriceOf], not [buyPriceOf].** Buying back is an undo, not a trade:
  /// the merchant made no margin on a misplaced tap, so charging the markup would
  /// turn the player's mistake into a fine. It is not a loop either — only what
  /// this hero sold this visit is on the counter, and every item there was
  /// already theirs.
  ///
  /// The gold and the pack cap are [buyItem]'s rules, unchanged, so a hero who
  /// has filled their pack since the sale genuinely cannot take it back yet and
  /// is told so in the same sentence as any other refused purchase.
  void _onBuyBack(BuyBackPressed event, Emitter<TownViewState> emit) {
    final counter = _find(state.merchant.sold, event.itemId);
    if (counter == null) return;
    final (after, refusal) = buyItem(
      state.profile,
      counter,
      sellPriceOf(counter),
    );
    emit(
      _settled(
        after,
        refusal,
        merchant: refusal == null
            ? state.merchant.withoutSold(event.itemId)
            : state.merchant,
      ),
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
    MerchantVisit? merchant,
  }) => TownViewState(
    profile: profile,
    stock: stock ?? state.stock,
    merchant: merchant ?? state.merchant,
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
