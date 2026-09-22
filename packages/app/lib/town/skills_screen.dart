import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:residuum_app/game/event_messages.dart' show skillName;
import 'package:residuum_core/core.dart';

import '../style/tokens.dart';
import 'town_bloc.dart';
import 'town_style.dart';

class SkillsScreen extends StatelessWidget {
  const SkillsScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<TownBloc, TownViewState>(
    builder: (context, state) => TownRoom(
      title: 'Skills',
      children: [
        for (final skill in SkillId.values)
          _SkillRow(
            key: Key('skill-${skill.name}'),
            skill: skill,
            state: state.profile.skills[skill] ?? const SkillState(),
          ),
      ],
    ),
  );
}

class _SkillRow extends StatelessWidget {
  const _SkillRow({required this.skill, required this.state, super.key});

  final SkillId skill;
  final SkillState state;

  @override
  Widget build(BuildContext context) {
    final cost = xpToNext(state.level);
    final progress = cost == 0 ? 0.0 : (state.xp / cost).clamp(0, 1).toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 88, child: Text(skillName(skill), style: textBody)),
          const SizedBox(width: 12),
          SizedBox(width: 24, child: Text('${state.level}', style: textBody)),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: rule,
                valueColor: const AlwaysStoppedAnimation(ink),
              ),
            ),
          ),
          SizedBox(
            width: 56,
            child: Text('${state.xp}/$cost', style: textLineDim),
          ),
        ],
      ),
    );
  }
}
