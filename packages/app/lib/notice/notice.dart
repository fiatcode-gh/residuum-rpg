import 'package:equatable/equatable.dart';

/// One thing the interface owes the player a sentence about.
///
/// Sealed rather than a plain `String?` so a notice cannot exist without
/// saying WHICH kind of thing happened — the load that fell back, the save
/// that did not land, the resume the rules refused, or the transaction the
/// rules refused — and so the next variant this game needs is a type change,
/// not a second field everyone forgets to carry. The sentence is a payload:
/// the widget renders it, and nothing parses it.
///
/// The variants render identically today — `— sentence.` in the town's frame —
/// and exist as types so the day they must render differently, they can,
/// without anyone having to work out which string meant what.
sealed class SaveNotice extends Equatable {
  const SaveNotice();

  /// Written to be read aloud on the screen, not parsed.
  String get sentence;

  @override
  String toString() => '$runtimeType(${sentence.length} chars)';
}

/// What booting found, or failed to find, on disk.
final class LoadNotice extends SaveNotice {
  const LoadNotice(this.sentence);

  @override
  final String sentence;

  @override
  List<Object?> get props => [sentence];
}

/// A save write that did not land.
///
/// The first failure of a streak, carried once: the queue's error sink emits
/// one of these per streak, and the streak ends at the first save that
/// succeeds. What happened is already said by the sentence — what the player
/// can rely on is that the game kept running and the last good save stands.
final class SaveWriteFailedNotice extends SaveNotice {
  const SaveWriteFailedNotice(this.sentence);

  @override
  final String sentence;

  @override
  List<Object?> get props => [sentence];
}

/// A walk back into a camp that the rules refused.
final class ResumeRefusedNotice extends SaveNotice {
  const ResumeRefusedNotice(this.sentence);

  @override
  final String sentence;

  @override
  List<Object?> get props => [sentence];
}

/// A sentence the interface owes with no kind of its own.
///
/// The generic variant: the town's transactions carry their refusals as
/// sentences (`TownRefusal.reason`) and the forge carries its level-up
/// announcements, and the notice channel is where both are read out. They ride
/// here rather than gaining a variant apiece — only the channel was sealed,
/// not every sentence a rule can produce.
final class SentenceNotice extends SaveNotice {
  const SentenceNotice(this.sentence);

  @override
  final String sentence;

  @override
  List<Object?> get props => [sentence];
}
