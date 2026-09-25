import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../town/town_bloc.dart';
import '../world/world_bloc.dart';
import 'crawl_surfaces.dart';
import 'game_bloc.dart';

const String doneControl = 'Finish';

const String doneAtTheBottom = 'The delve is done. Leaving here ends it.';

void leaveDungeon(
  BuildContext context,
  GameViewState state, {
  required bool died,
}) {
  context.read<TownBloc>().add(RunEnded(state.game, died: died));
  Navigator.of(context).pop();
}

void suspendDungeon(BuildContext context, GameViewState state) {
  context.read<TownBloc>().add(
    RunSuspended(
      state.game,
      day: context.read<WorldBloc>().state.world.day,
      dungeon: context.read<GameBloc>().dungeon!,
    ),
  );
  Navigator.of(context).pop();
}

Future<void> confirmCompletion(
  BuildContext context,
  GameViewState state,
) async {
  final done = await showCrawlConfirm(
    context,
    title: 'The delve is done. Leave with your spoils?',
    body:
        'There is nothing below this floor, so walking out ends the delve '
        'rather than leaving it standing. Everything you carry comes with '
        'you.',
    dismiss: 'Stay down here',
    confirm: 'Leave with them',
  );
  if (!done || !context.mounted) return;
  leaveDungeon(context, state, died: false);
}

void leaveEncounter(
  BuildContext context,
  GameViewState state,
  EncounterEnding ending,
) {
  context.read<TownBloc>().add(
    EncounterEnded(state.game, died: ending == EncounterEnding.died),
  );
  context.read<WorldBloc>().add(RoadFightOver(ending));
  Navigator.of(context).pop();
}
