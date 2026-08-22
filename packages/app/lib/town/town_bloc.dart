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
///
/// Death is the only way the interface reaches this now: walking out at the
/// stairs suspends. The alive branch stays because `endRun` keeps both — it is
/// the normative carry set and public core API — and because an event named for
/// an ending should not silently mean one particular ending.
final class RunEnded extends TownBlocEvent {
  const RunEnded(this.state, {required this.died});

  final GameState state;
  final bool died;
}

/// The hero walked out at the stairs and left the crawl standing.
final class RunSuspended extends TownBlocEvent {
  const RunSuspended(this.state);

  final GameState state;
}

/// The hero is going back down into the crawl that is waiting for them.
final class ResumeCrawlPressed extends TownBlocEvent {
  const ResumeCrawlPressed();
}

/// The hero is giving that crawl up for a dungeon laid out afresh.
final class DelveAnewPressed extends TownBlocEvent {
  const DelveAnewPressed();
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
    this.suspended,
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

  /// The crawl to open right now, or null when there is none to open.
  ///
  /// An instruction rather than a fact: the session reads it once, pushes the
  /// crawl, and nothing in town looks at it again.
  final GameState? run;

  /// The crawl waiting to be walked back into, or null when there is no camp.
  ///
  /// **Not [run], and the two must never become one field.** [run] says "open
  /// this now"; this says "there is a dungeon standing three floors down with
  /// your name on it", and it has to survive every transaction in town.
  /// Collapsing them would make walking into a dungeon indistinguishable from
  /// having one to go back to, and the town screen could not tell which door to
  /// draw.
  ///
  /// Carried forward by every handler, for the reason [merchant] is — and the
  /// stakes are higher. A handler that dropped this would have the autosaver
  /// write `run: null` on the next purchase and erase a crawl the player is
  /// standing inside, with nothing on screen to say it had gone.
  ///
  /// Never set at the same time as [run]. Suspending sets this and leaves that
  /// null; both doors out of a camp set that and leave this null.
  final GameState? suspended;

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

/// Owns the hero between runs, and every door into and out of the dungeon.
///
/// The dungeon has its own bloc. This one never touches a [GameState] except to
/// hand one over at a door and take one back at a door, which is the same line
/// `startRun`, `endRun`, `suspendRun` and `resumeRun` draw in the rules.
///
/// There are four doors because leaving stopped meaning one thing. A hero can
/// end a run by dying, walk out of one at the stairs, walk back into the one
/// they walked out of, or give it up for a fresh one — and the last two are the
/// fork that keeps a dungeon which can be left from being a dungeon that is
/// emptied once and never refills.
class TownBloc extends Bloc<TownBlocEvent, TownViewState> {
  TownBloc({
    required Profile profile,
    MerchantVisit merchant = MerchantVisit.none,
    String? notice,
    GameState? suspended,
  }) : super(
         TownViewState(
           profile: profile,
           stock: merchant.stillOnTheShelf(
             merchantStock(profile.worldSeed, profile.visit),
           ),
           merchant: merchant,
           suspended: suspended,
           notice: notice,
         ),
       ) {
    on<EnterDungeonPressed>(_onEnterDungeon);
    on<RunEnded>(_onRunEnded);
    on<RunSuspended>(_onRunSuspended);
    on<ResumeCrawlPressed>(_onResumeCrawl);
    on<DelveAnewPressed>(_onDelveAnew);
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

  /// Brings the hero home and leaves the crawl standing where it is.
  ///
  /// **The visit state goes only if the visit moved.** Suspending carries the
  /// run's visit home, and whether that is a *new* number depends on which door
  /// the hero went in by: entering bumps the visit, so the first walk out lands
  /// on a shelf that has turned over and every remembered id names stock that no
  /// longer exists. Resuming bumps nothing — that is the whole of what resuming
  /// is — so a hero who walks out of a crawl they walked back into comes home to
  /// the very shelf they were shopping at an hour ago.
  ///
  /// Clearing it there would be worse than untidy. `merchantStock` is a pure roll
  /// on the world and the visit, so the same shelf is laid out again from
  /// scratch; drop the record of what was taken off it and the purchase comes
  /// back for sale while the item is still in the pack. Buying it a second time
  /// puts two items under one id, and the town's by-id operations disagree about
  /// what that means — the price is read off the first match while the removal
  /// takes every match, so selling one pays for one and destroys both. That is
  /// the defect the visit block was introduced to kill, and an unconditional
  /// clear here quietly hands it back.
  void _onRunSuspended(RunSuspended event, Emitter<TownViewState> emit) {
    final home = suspendRun(state.profile, event.state);
    final reshuffled = home.visit != state.profile.visit;
    final merchant = reshuffled ? MerchantVisit.none : state.merchant;
    emit(
      TownViewState(
        profile: home,
        stock: merchant.stillOnTheShelf(
          merchantStock(home.worldSeed, home.visit),
        ),
        merchant: merchant,
        suspended: event.state,
      ),
    );
  }

  /// Walks back into the camp, with everything town did since folded in.
  ///
  /// Nothing happens without a camp. The screen only offers this door when there
  /// is one, so an event arriving anyway is a press the player did not make, and
  /// answering it with a fresh crawl would be entering a dungeon nobody asked
  /// to enter.
  void _onResumeCrawl(ResumeCrawlPressed event, Emitter<TownViewState> emit) {
    if (state.suspended case final GameState camp) {
      emit(
        TownViewState(
          profile: state.profile,
          stock: state.stock,
          merchant: state.merchant,
          run: resumeRun(state.profile, camp),
        ),
      );
    }
  }

  /// Gives the camp up and walks into a dungeon laid out afresh.
  ///
  /// **Nothing the hero earned is at stake.** Walking out at the stairs already
  /// brought their hit points, gear, training, pack and purse home, so a camp
  /// holds a floor plan and a pair of stream states and not one thing the player
  /// worked for. What it costs is the depth reached, which is why the interface
  /// asks first rather than why this refuses.
  ///
  /// `startDungeonRun` bumps the visit by construction, and that bump **is** the
  /// reshuffle. It is the whole reason this door exists: with resuming as the
  /// only way back down, floors would be emptied once and never refill, and the
  /// farming loop the economy rests on would quietly die.
  void _onDelveAnew(DelveAnewPressed event, Emitter<TownViewState> emit) =>
      emit(
        TownViewState(
          profile: state.profile,
          stock: state.stock,
          merchant: state.merchant,
          run: startDungeonRun(state.profile),
        ),
      );

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

  /// One settled transaction, with everything not being transacted carried over.
  ///
  /// The carry list is the whole point of this function. A transaction moves
  /// gold or gear and nothing else, so every other fact about the visit has to
  /// arrive on the other side untouched — what the merchant remembers, and the
  /// crawl the hero is camped away from. Both are things the player cannot get
  /// back if a handler forgets them, and neither leaves a mark on screen when it
  /// goes.
  TownViewState _settled(
    Profile profile,
    TownRefusal? refusal, {
    List<Item>? stock,
    MerchantVisit? merchant,
  }) => TownViewState(
    profile: profile,
    stock: stock ?? state.stock,
    merchant: merchant ?? state.merchant,
    suspended: state.suspended,
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
