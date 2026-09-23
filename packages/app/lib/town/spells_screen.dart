import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:residuum_content/content.dart';

import '../game/spell_row.dart';
import '../style/surfaces.dart';
import '../style/tokens.dart';
import 'town_bloc.dart';
import 'town_style.dart';

class SpellsScreen extends StatelessWidget {
  const SpellsScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<TownBloc, TownViewState>(
    builder: (context, state) {
      final known = knownSpellsInOrder(state.profile.knownSpells, spellsById);
      final lockedCount = spellsById.length - known.length;
      return TownRoom(
        title: 'Spells',
        children: [
          const Heading('Known spells'),
          if (known.isEmpty)
            const NothingHere('You have not learned any spell yet.')
          else
            for (final spell in known)
              SpellRow(
                spell: spell,
                style: textBody,
                dimStyle: textLineDim,
                detail: effectOf(spell),
              ),
          const Heading('Locked spells'),
          if (lockedCount == 0)
            const NothingHere('No spells remain locked.')
          else
            FramedRow(
              key: const Key('spells-locked-summary'),
              title: lockedCount == 1
                  ? '1 spell remains locked'
                  : '$lockedCount spells remain locked',
              details: const ['Unknown until learned.'],
            ),
        ],
      );
    },
  );
}
