import 'package:residuum_core/core.dart';

/// Upper-cases the first letter only, leaving the rest of the word alone —
/// PLAN.md G11's rule for a target's name and a bolt's damage type, neither
/// of which is otherwise shouted. Safe on an empty string.
String capitaliseFirst(String word) =>
    word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}';

/// The facts the combat panel's TARGET column and the map callout's card
/// both show about [target], in the same order (PLAN.md G11 "target"): its
/// attack and speed, its stated reach or its adjacency, then every
/// resistance and every vulnerability it carries.
List<String> targetFactLines(Actor target) => [
  'ATK ${target.attackMin}–${target.attackMax}  SPD ${target.speed}',
  target.reach > 1 ? 'Reach ${target.reach}' : 'Adjacent',
  for (final type in target.resists) 'Resists ${type.word}',
  for (final type in target.vulnerableTo) 'Burns at ${type.word}',
];
