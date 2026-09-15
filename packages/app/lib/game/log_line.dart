import 'package:equatable/equatable.dart';

/// What kind of thing one line of the message log reports.
enum LogCategory {
  struck('←', 'struck'),
  hit('→', 'hit'),
  died('†', 'died'),
  noticed('◎', 'noticed'),
  moved('⇅', 'moved'),
  refused('✕', 'refused'),
  item('■', 'item'),
  raised('▲', 'raised'),
  gathered('◆', 'gathered'),
  reported('§', 'reported');

  const LogCategory(this.mark, this.word);

  /// The non-hue mark the expanded log draws in its leading column.
  final String mark;

  /// What the category is called out loud, for the accessibility label.
  final String word;
}

/// How much of the message log the drawer is showing.
enum LogDrawerExtent { peek, half, full }

/// One line of the message log: the sentence, and the one kind it is.
final class LogLine extends Equatable {
  const LogLine(this.sentence, this.category);

  final String sentence;
  final LogCategory category;

  @override
  List<Object?> get props => [sentence, category];
}
