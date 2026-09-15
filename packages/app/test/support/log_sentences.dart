import 'package:residuum_app/game/game_bloc.dart';

List<String> logSentences(GameViewState state) => [
  for (final line in state.log) line.sentence,
];
