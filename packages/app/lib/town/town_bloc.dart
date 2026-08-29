import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../game/event_messages.dart';

sealed class TownBlocEvent {
  const TownBlocEvent();
}

/// The hero is walking into the dungeon under [node].
///
/// **The node travels with the press, because nothing downstream can work it
/// out.** The town bloc is keyed on a *town* — that is whose shelf it is
/// drawing — and a hero standing at a dungeon is at no town at all, so the one
/// place that knows which dungeon is being entered is the screen the hero
/// pressed it from.
final class EnterDungeonPressed extends TownBlocEvent {
  const EnterDungeonPressed(this.node);

  final NodeId node;
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
///
/// [day] is the world's day, carried on the press because the town does not
/// have one. A camp has a shelf life measured in days walked, and the only
/// thing that counts days is the road — so the number comes from the world at
/// the moment the hero climbs out, which is the one moment it means "now".
final class RunSuspended extends TownBlocEvent {
  const RunSuspended(this.state, {required this.day});

  final GameState state;
  final int day;
}

/// The hero is going back down into the crawl that is waiting for them.
///
/// [day] is the world's day, for [RunSuspended]'s reason and to answer the same
/// question from the other end: a camp older than [campLife] days is not there
/// to walk back into, and the rule that says so has to be checked where the
/// crawl is handed over rather than only where the door is drawn.
final class ResumeCrawlPressed extends TownBlocEvent {
  const ResumeCrawlPressed({required this.day});

  final int day;
}

/// The hero is giving that crawl up for the dungeon under [node], laid out
/// afresh.
///
/// [node] need not be the camp's own dungeon: pressing this at another node is
/// how a hero abandons a camp to enter somewhere else, and the world screen asks
/// them first.
final class DelveAnewPressed extends TownBlocEvent {
  const DelveAnewPressed(this.node);

  final NodeId node;
}

/// A road fight is over, and the hero is coming home from it.
final class EncounterEnded extends TownBlocEvent {
  const EncounterEnded(this.state, {required this.died});

  final GameState state;
  final bool died;
}

/// The hero asked at the tavern, and core has answered.
///
/// Carries the whole of [Rumored] so this bloc takes the half that is its own —
/// the purse — while the world takes the half that is its own. Neither works out
/// the other's, and the rule itself lives in `buyRumor` where both halves are
/// decided together.
final class RumorBought extends TownBlocEvent {
  const RumorBought(this.told);

  final Rumored told;
}

/// The hero walked into a town, which may or may not be the one they left.
///
/// Sent by the world, because the world is where the hero's whereabouts live.
/// The town's business is what arriving *means* for the shop, which is the
/// whole of the handler.
final class ArrivedInTown extends TownBlocEvent {
  const ArrivedInTown(this.town);

  final NodeId town;
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

/// Read the carried spell book with this id, at a camp or in a town.
///
/// **The same rule the corridor uses**, wrapped the town's way: [readBook]
/// calls the shared `readRefusal`, so a gate refuses in the same sentence
/// wherever the hero opens the page.
final class ReadBookPressed extends TownBlocEvent {
  const ReadBookPressed(this.itemId);

  final String itemId;
}

final class TakeOffPressed extends TownBlocEvent {
  const TakeOffPressed(this.slot);

  final EquipSlot slot;
}

/// The player asked the forge to smelt.
final class SmeltPressed extends TownBlocEvent {
  const SmeltPressed();
}

/// The player asked the alchemist to brew.
final class BrewPressed extends TownBlocEvent {
  const BrewPressed();
}

/// The player asked the forge to work the item with this id up one tier.
final class TemperPressed extends TownBlocEvent {
  const TemperPressed(this.itemId);

  final String itemId;
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
    required this.town,
    this.merchant = MerchantVisit.none,
    this.run,
    this.suspended,
    this.dungeon,
    this.campDay,
    this.notice,
  });

  final Profile profile;

  /// Which town's doors these are.
  ///
  /// The shelf is rolled per town, so every screen under this bloc is drawing
  /// one particular shop and this is which. It is told to the bloc rather than
  /// read off the world, because the hero's whereabouts belong to the world and
  /// two owners of one fact is how the two of them start to disagree.
  final NodeId town;

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

  /// Which dungeon [run] or [suspended] is a crawl of, or null when there is
  /// neither.
  ///
  /// **Carried by every handler that carries either of them, and the two must
  /// never drift apart.** The save document requires a crawl and a place
  /// together, so a handler that kept the camp and dropped this would write a
  /// document the decoder refuses — and the player would find out on the next
  /// launch, with a fallback notice and no crawl. It is the same carry list
  /// [suspended] is on, for higher stakes.
  ///
  /// Never a town, and never set while both crawl fields are null.
  final NodeId? dungeon;

  /// The day [suspended] was pitched, or null exactly when there is no camp.
  ///
  /// On the carry list beside [suspended] and [dungeon], and for the same
  /// reason: the save document requires all three to agree, so a handler that
  /// kept the camp and dropped this would write a document the decoder refuses.
  /// It is also what the world screen reads to say how long the camp has left.
  final int? campDay;

  /// The last refusal, for the screen to read out. Cleared by the next thing
  /// that works.
  final String? notice;

  int get gold => profile.gold;

  int get bankedGold => profile.bankedGold;

  int get hp => profile.hero.hp;

  int get maxHp => profile.maxHp;

  /// Whether a bed would do the hero any good.
  bool get canRest => profile.hero.hp < profile.maxHp;

  /// What the hero has gathered, every material present even at zero.
  ///
  /// A fixed order with no gaps, for the pack panel's reason: the position of a
  /// row is information the player relies on.
  Map<MaterialId, int> get materials => {
    for (final id in MaterialId.values) id: countOf(profile.materials, id),
  };

  /// Why the forge will not smelt right now, or null when it will.
  String? get smeltReason => smeltRefusal(profile);

  /// Why the alchemist will not brew right now, or null when they will.
  String? get brewReason => brewRefusal(profile);

  /// Why the forge will not work [itemId], or null when it will.
  ///
  /// **The screen asks the rules rather than deciding for itself.** A dead row
  /// that greyed itself out on its own arithmetic would eventually refuse
  /// something the rules would have allowed, and the sentence it shows is the
  /// one the transaction would have refused with.
  String? temperReason(String itemId) => temperRefusal(profile, itemId);

  /// Everything the forge could work, carried or worn, in a stated order.
  ///
  /// Worn pieces first and then carried ones, because the piece most worth
  /// working is usually the one the hero has on — and within each half the
  /// slot's own order, so a row keeps its place from one visit to the next.
  List<Item> get temperable => [
    for (final slot in EquipSlot.values)
      if (profile.equipment[slot] case final Item worn)
        if (worn.base.takesTemper) worn,
    for (final item in profile.inventory)
      if (item.base.takesTemper) item,
  ];

  /// Whether the camp has stood long enough on [day] for the residue to have
  /// taken it back.
  ///
  /// False when there is no camp, so a caller can ask without asking twice.
  bool isCampOverrunOn(int day) {
    final pitched = campDay;
    if (pitched == null) return false;
    return isCampOverrun(day: day, campDay: pitched);
  }

  /// Whether one more day on the road would take the camp back.
  bool isCampNearlyOverrunOn(int day) {
    final pitched = campDay;
    if (pitched == null) return false;
    return isCampNearlyOverrun(day: day, campDay: pitched);
  }
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
    NodeId? town,
    MerchantVisit merchant = MerchantVisit.none,
    String? notice,
    GameState? suspended,
    NodeId? dungeon,
    int? campDay,
  }) : super(
         _opening(
           profile: profile,
           town: town ?? newWhereabouts().at,
           merchant: merchant,
           suspended: suspended,
           dungeon: dungeon,
           campDay: campDay,
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
    on<ReadBookPressed>(_onReadBook);
    on<SmeltPressed>(_onSmelt);
    on<BrewPressed>(_onBrew);
    on<TemperPressed>(_onTemper);
    on<DepositGoldPressed>(_onDepositGold);
    on<WithdrawGoldPressed>(_onWithdrawGold);
    on<ArrivedInTown>(_onArrivedInTown);
    on<RumorBought>(_onRumorBought);
    on<EncounterEnded>(_onEncounterEnded);
  }

  /// The state a town opens on: this town's shelf, less what is already bought.
  ///
  /// [town] falls back to where a fresh hero stands rather than being required,
  /// because seventy-odd rule tests build a bloc to ask one question about gold
  /// and none of them is about which town it is. The wiring that matters — the
  /// session telling the bloc where the hero actually is — is an integration
  /// fact, and it is pinned by a widget test rather than by making every
  /// unrelated test say so.
  static TownViewState _opening({
    required Profile profile,
    required NodeId town,
    required MerchantVisit merchant,
    required GameState? suspended,
    required NodeId? dungeon,
    required int? campDay,
    required String? notice,
  }) => TownViewState(
    profile: profile,
    town: town,
    stock: merchant.stillOnTheShelf(
      merchantStock(profile.worldSeed, profile.visit, town),
    ),
    merchant: merchant,
    suspended: suspended,
    dungeon: dungeon,
    campDay: campDay,
    notice: notice,
  );

  void _onEnterDungeon(
    EnterDungeonPressed event,
    Emitter<TownViewState> emit,
  ) => emit(
    TownViewState(
      profile: state.profile,
      town: state.town,
      stock: state.stock,
      merchant: state.merchant,
      run: startDungeonRunAt(event.node, state.profile),
      dungeon: event.node,
    ),
  );

  /// Brings the run home, and the camp with it.
  ///
  /// **The visit state goes only if the visit moved, exactly as suspending
  /// decides it.** The two doors used to disagree: suspending kept what the
  /// merchant remembered when the visit had not moved, and this dropped it
  /// unconditionally. That was harmless while death was the only way through
  /// here, because dying after a fresh entry does move the visit. It stopped
  /// being harmless the moment a delve could be *completed*: a hero who walked
  /// back into a camp and then finished it at the bottom comes home on the very
  /// visit they were shopping on, and an unconditional clear would put a bought
  /// item back on the shelf while it sat in their pack — the D36 defect, handed
  /// back in reverse.
  ///
  /// **So death after a resume now keeps the shelf too**, and that is the rule
  /// rather than an oversight: the visit did not move, so the shelf did not turn
  /// over, and burning the pack does not restock anybody's shop. What was bought
  /// is still bought.
  ///
  /// The camp goes either way. A run that ended is a run nobody can walk back
  /// into, whichever way it ended.
  void _onRunEnded(RunEnded event, Emitter<TownViewState> emit) {
    final home = endRun(state.profile, event.state, died: event.died);
    final reshuffled = home.visit != state.profile.visit;
    final merchant = reshuffled ? MerchantVisit.none : state.merchant;
    emit(
      TownViewState(
        profile: home,
        town: state.town,
        stock: merchant.stillOnTheShelf(
          merchantStock(home.worldSeed, home.visit, state.town),
        ),
        merchant: merchant,
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
        town: state.town,
        stock: merchant.stillOnTheShelf(
          merchantStock(home.worldSeed, home.visit, state.town),
        ),
        merchant: merchant,
        suspended: event.state,
        dungeon: state.dungeon,
        campDay: event.day,
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
    if (state.isCampOverrunOn(event.day)) return;
    if (state.suspended case final GameState camp) {
      emit(
        TownViewState(
          profile: state.profile,
          town: state.town,
          stock: state.stock,
          merchant: state.merchant,
          run: resumeRun(state.profile, camp),
          dungeon: state.dungeon,
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
  /// **The camp given up may be somebody else's dungeon.** Entering anywhere
  /// gives up the one camp a hero has, because one run slot per hero is a fact
  /// about the save format rather than a choice the interface made — and the
  /// world screen is where that is said out loud, before the press gets here.
  ///
  /// `startDungeonRunAt` bumps the visit by construction, and that bump **is**
  /// the reshuffle. It is the whole reason this door exists: with resuming as the
  /// only way back down, floors would be emptied once and never refill, and the
  /// farming loop the economy rests on would quietly die.
  void _onDelveAnew(DelveAnewPressed event, Emitter<TownViewState> emit) =>
      emit(
        TownViewState(
          profile: state.profile,
          town: state.town,
          stock: state.stock,
          merchant: state.merchant,
          run: startDungeonRunAt(event.node, state.profile),
          dungeon: event.node,
        ),
      );

  /// Brings the hero home off the road, alive or otherwise.
  ///
  /// **`endRun`, the same door a crawl comes home through** — which is what makes
  /// `endRun(died: false)` a reachable door again after the leave unit left death
  /// as the only thing coming through it. Walking off the edge and killing the
  /// last creature both arrive here alive, carrying whatever was picked up
  /// mid-fight; dying arrives here having lost the pack and the purse and woken
  /// whole, which is the same price a crawl charges.
  ///
  /// **The visit does not move, so nothing about the shop or the camp does.** A
  /// road fight is not an entry, `startRoadEncounter` carries the profile's own
  /// visit through, and `endRun` brings that same number home — so the shelf the
  /// hero was shopping at is still theirs and a camp waiting at the crypt is
  /// still resumable. Both ride through on the carry list rather than by luck.
  ///
  /// **The camp survives a death on the road.** Dying costs the pack and the
  /// purse; a dungeon standing at the crypt with the hero's name on it is
  /// progress they made, not goods they were carrying, and they did not die in
  /// it.
  void _onEncounterEnded(EncounterEnded event, Emitter<TownViewState> emit) =>
      emit(
        _settled(endRun(state.profile, event.state, died: event.died), null),
      );

  /// Pays for what the tavern said, or says why the purse could not.
  ///
  /// The profile comes from core already debited, which is [RunEnded]'s shape
  /// the other way round: there, this bloc hands a state to `endRun` and takes
  /// the profile back; here the caller has already been to `buyRumor` because
  /// the answer had to be split between two owners, and this takes the half that
  /// is a hero. A refusal leaves the profile exactly as it went in, because that
  /// is what core returns on one.
  void _onRumorBought(RumorBought event, Emitter<TownViewState> emit) =>
      emit(_settled(event.told.profile, event.told.refusal));

  /// Opens the shop of the town the hero just walked into.
  ///
  /// **Arriving at the other town clears what the merchant remembered, and
  /// arriving back at the same one does not.** That is the D36 rule with the
  /// town added to it: the visit block is valid exactly as long as the visit
  /// *and* the town it was rolled for. What the merchant remembers is a list of
  /// stock ids, and those ids name rolls off one particular shelf — carry them
  /// to the other town and they name nothing there, so a bought item would come
  /// back for sale while it sat in the hero's pack.
  ///
  /// Walking home to the town a resumed crawl started from keeps the shelf, and
  /// that is the other half of the same pair: the visit did not move and neither
  /// did the town, so nothing about the shop has changed.
  ///
  /// The camp is carried through, because arriving somewhere is not giving up a
  /// dungeon.
  void _onArrivedInTown(ArrivedInTown event, Emitter<TownViewState> emit) {
    final elsewhere = event.town != state.town;
    final merchant = elsewhere ? MerchantVisit.none : state.merchant;
    emit(
      TownViewState(
        profile: state.profile,
        town: event.town,
        stock: merchant.stillOnTheShelf(
          merchantStock(
            state.profile.worldSeed,
            state.profile.visit,
            event.town,
          ),
        ),
        merchant: merchant,
        suspended: state.suspended,
        dungeon: state.dungeon,
        campDay: state.campDay,
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
        merchant: state.merchant.withBought(event.itemId, state.town),
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
            ? state.merchant.withSold(carried, state.town)
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

  void _onReadBook(ReadBookPressed event, Emitter<TownViewState> emit) =>
      emit(_transacted(readBook(state.profile, event.itemId, spellsById)));

  void _onSmelt(SmeltPressed event, Emitter<TownViewState> emit) =>
      emit(_crafted(smeltOre(state.profile), SkillId.blacksmith));

  void _onBrew(BrewPressed event, Emitter<TownViewState> emit) => emit(
    _crafted(brewPotion(state.profile, healingPotion), SkillId.herbcraft),
  );

  void _onTemper(TemperPressed event, Emitter<TownViewState> emit) => emit(
    _crafted(temperItem(state.profile, event.itemId), SkillId.blacksmith),
  );

  /// One settled craft, with a level-up said out loud where a refusal would be.
  ///
  /// **The level-up is worked out here rather than carried out of the rules**,
  /// and that is the only place it can be. `SkillLevelledUp` is a `GameEvent`,
  /// and a town transaction has no event list — inventing one for three
  /// handlers would give the town a second, thinner copy of the crawl's whole
  /// announcement machinery. What the rules owe is the training; what the screen
  /// owes is the sentence, and this compares the one skill the transaction could
  /// have moved before and after.
  ///
  /// The sentence is `describeEvent`'s own wording for the same event, so the
  /// forge says exactly what the message log would have said in the dungeon.
  ///
  /// A refusal wins over a level-up, because a refusal trained nothing.
  TownViewState _crafted(Transacted result, SkillId trained) {
    final settled = _settled(result.$1, result.$2);
    if (result.$2 != null) return settled;
    final before = state.profile.skills[trained]?.level ?? 0;
    final after = result.$1.skills[trained]?.level ?? 0;
    if (after <= before) return settled;
    return _noticed(settled, '${skillName(trained)} rises to $after');
  }

  /// [settled] with [notice] on it, and nothing else moved.
  ///
  /// Built by hand rather than through [_settled] because that one takes its
  /// notice from a refusal, and this notice is the opposite of one.
  TownViewState _noticed(TownViewState settled, String notice) => TownViewState(
    profile: settled.profile,
    town: settled.town,
    stock: settled.stock,
    merchant: settled.merchant,
    suspended: settled.suspended,
    dungeon: settled.dungeon,
    campDay: settled.campDay,
    notice: notice,
  );

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
    town: state.town,
    stock: stock ?? state.stock,
    merchant: merchant ?? state.merchant,
    suspended: state.suspended,
    dungeon: state.dungeon,
    campDay: state.campDay,
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
