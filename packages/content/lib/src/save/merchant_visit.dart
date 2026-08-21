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
  const MerchantVisit({this.bought = const [], this.sold = const []});

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

  /// A hero who has not been to the shop this visit.
  static const MerchantVisit none = MerchantVisit();

  /// Which of [stock] the hero has not already bought.
  List<Item> stillOnTheShelf(List<Item> stock) => [
    for (final item in stock)
      if (!bought.contains(item.id)) item,
  ];

  /// This visit, with the stock item [itemId] bought.
  MerchantVisit withBought(String itemId) =>
      MerchantVisit(bought: [...bought, itemId], sold: sold);

  /// This visit, with [item] sold across the counter.
  MerchantVisit withSold(Item item) =>
      MerchantVisit(bought: bought, sold: [...sold, item]);

  /// This visit, with the sold item [itemId] bought back.
  MerchantVisit withoutSold(String itemId) => MerchantVisit(
    bought: bought,
    sold: [
      for (final item in sold)
        if (item.id != itemId) item,
    ],
  );

  @override
  List<Object?> get props => [bought, sold];

  @override
  String toString() =>
      'MerchantVisit(${bought.length} bought, ${sold.length} sold)';
}
