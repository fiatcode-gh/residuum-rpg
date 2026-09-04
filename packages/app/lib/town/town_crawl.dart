import 'package:residuum_core/core.dart';

/// The crawl a town stands beside, in the shapes the town can actually hold.
///
/// **One sealed value where four nullable fields used to be.** `run`,
/// `suspended`, `dungeon` and `campDay` were one fact written as four fields,
/// and the rule that only legal combinations exist — the run-XOR-suspended
/// rule — lived in prose on each field. Now the type is the rule: a town can
/// be about to open a crawl, be standing next to a camp, or hold no crawl at
/// all, and nothing else is representable.
sealed class TownCrawl {
  const TownCrawl();
}

/// The crawl to open right now: [run], in [dungeon].
///
/// **An instruction, not a fact.** The session reads [run] once, pushes the
/// crawl, and nothing in town looks at it again — it is an instruction rather
/// than a fact, and it never survives into the save document as "the crawl is
/// open": whether the hero is standing in the crawl is the document's own
/// `inside` field, set by the save and read at boot. A state carrying a
/// [CrawlOpening] is a town whose next emission says "open this"; it is not a
/// claim that anything is open yet, and no handler may treat it as one.
final class CrawlOpening extends TownCrawl {
  const CrawlOpening(this.run, this.dungeon);

  /// The crawl to open now.
  final GameState run;

  /// The dungeon [run] is a crawl of.
  final NodeId dungeon;
}

/// The camp standing: a crawl waiting to be walked back into.
///
/// This is the fact [CrawlOpening] is not: a camp survives every transaction
/// in town, rides every carry list, and dies only when the hero walks back
/// into it, gives it up, or the residue takes it. [campDay] is required here
/// and null exactly where there is no camp — the save document's pairing rule,
/// now unrepresentable to break.
final class CampStanding extends TownCrawl {
  const CampStanding(this.crawl, this.dungeon, this.campDay);

  /// The crawl waiting to be walked back into.
  final GameState crawl;

  /// The dungeon [crawl] is standing in.
  final NodeId dungeon;

  /// The day the hero walked out at the stairs and pitched it.
  final int campDay;
}
