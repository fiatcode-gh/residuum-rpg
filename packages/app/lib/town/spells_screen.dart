import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:residuum_content/content.dart';

import '../game/spell_row.dart';
import 'town_bloc.dart';
import 'town_style.dart';

class SpellsScreen extends StatelessWidget {
  const SpellsScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<TownBloc, TownViewState>(
    builder: (context, state) {
      final known = knownSpellsInOrder(state.profile.knownSpells, spellsById);
      return TownRoom(
        title: 'Spells',
        children: [
          if (known.isEmpty)
            const NothingHere('You have not learned any spell yet.')
          else
            for (final spell in known)
              SpellRow(
                spell: spell,
                style: mono,
                dimStyle: monoDim,
                detail: effectOf(spell),
              ),
        ],
      );
    },
  );
}
