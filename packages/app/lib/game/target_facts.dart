import 'package:residuum_core/core.dart';

/// Upper-cases the first letter only, leaving the rest of the word alone —
/// PLAN.md G11's rule for a target's name and a bolt's damage type, neither
/// of which is otherwise shouted. Safe on an empty string.
String capitaliseFirst(String word) =>
    word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}';

List<String> targetFactLines(Actor target) => [
  'ATK ${target.attackMin}–${target.attackMax}  SPD ${target.speed}',
  target.reach > 1 ? 'Ranged, reach ${target.reach}' : 'Melee only',
  for (final type in target.resists) 'Resists ${type.word}',
  for (final type in target.vulnerableTo) 'Burns at ${type.word}',
];
