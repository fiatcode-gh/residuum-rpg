import 'package:equatable/equatable.dart';
import 'package:residuum_core/core.dart';

/// What the merchant remembers of this visit: what came off the shelf, and what
/// went across the counter.
///
/// **It lives in the save document rather than in view state, and that is the
/// whole reason it exists.** The shelf is `merchantStock(worldSeed, visit)` —
/// deterministic in the world and the visit and nothing else — so a shop that
/// remembered a purchase only in memory put the entire shelf back the moment the
/// app was relaunched. That is worse than a free restock: the resurrected item
/// carries the id it was rolled with, so buying it a second time puts two items
/// with one id in the pack, and the town's by-id operations do not agree about
/// what that means. The price is read off the first match while the removal takes
/// every match, so selling one of the two pays for one and destroys both. A
/// purchase is a thing the player paid for, so it is written down.
///
/// Both lists are per visit, because the merchant re-stocks per visit by design:
/// they are cleared when the run ends, at the same moment the shelf is rolled
/// again.
class MerchantVisit extends Equatable {
  const MerchantVisit({
    this.bought = const [],
    this.sold = const [],
    this.town,
  });

  /// The ids of the stock already taken off the shelf this visit.
  ///
  /// Ids rather than items, because the shelf itself is never stored: it is
  /// rolled from the world seed and the visit whenever it is wanted, and all
  /// that has to survive is which of those rolls is gone.
  final List<String> bought;

  /// The items sold across the counter this visit, whole.
  ///
  /// Full references rather than ids, because a sold item is nowhere else in the
  /// document any more — the pack it came from does not hold it — so an id would
  /// name nothing to buy back.
  final List<Item> sold;

  /// Which town's shelf these ids were rolled off, or null when nothing is
  /// remembered.
  ///
  /// **The second half of what makes a remembered purchase mean anything.** The
  /// visit alone stopped being enough the moment there were two shelves: a
  /// bought id names one roll off one town's shelf, and carried to the other
  /// town it names nothing at all. So the block is valid exactly as long as the
  /// visit *and* this — which is the rule the town bloc enforces on arrival, and
  /// the reason it can.
  ///
  /// Null only when there is nothing to remember. A block that named purchases
  /// but not the shop they came from would be a list of ids nobody could match
  /// against a shelf, so the codec refuses that pairing rather than guessing a
  /// town for it.
  final NodeId? town;

  /// A hero who has not been to the shop this visit.
  static const MerchantVisit none = MerchantVisit();

  /// Which of [stock] the hero has not already bought.
  List<Item> stillOnTheShelf(List<Item> stock) => [
    for (final item in stock)
      if (!bought.contains(item.id)) item,
  ];

  /// This visit, with the stock item [itemId] bought at [town].
  MerchantVisit withBought(String itemId, NodeId town) =>
      MerchantVisit(bought: [...bought, itemId], sold: sold, town: town);

  /// This visit, with [item] sold across [town]'s counter.
  MerchantVisit withSold(Item item, NodeId town) =>
      MerchantVisit(bought: bought, sold: [...sold, item], town: town);

  /// This visit, with the sold item [itemId] bought back.
  MerchantVisit withoutSold(String itemId) => MerchantVisit(
    bought: bought,
    sold: [
      for (final item in sold)
        if (item.id != itemId) item,
    ],
    town: town,
  );

  @override
  List<Object?> get props => [bought, sold, town];

  @override
  String toString() =>
      'MerchantVisit(${bought.length} bought, ${sold.length} sold'
      '${town == null ? '' : ' at ${town!.value}'})';
}
