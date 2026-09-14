import 'package:residuum_core/core.dart';

/// The app-only presentation facts for one actor in an encounter.
final class ActorPresentation {
  const ActorPresentation({
    required this.actorId,
    required this.displayName,
    required this.glyph,
    this.badge,
  });

  final String actorId;
  final String displayName;
  final String glyph;
  final String? badge;

  String get glyphLabel => badge == null ? glyph : '$glyph$badge';
}

/// Stable, encounter-local identity and knowledge for monster presentation.
final class ActorIdentityContext {
  factory ActorIdentityContext.fromGame(GameState game) {
    final ordinals = <(String, String), int>{};
    final allocations = <String, _ActorAllocation>{};
    final knownIds = <String>{};
    for (final monster in game.monsters) {
      final group = (monster.glyph, monster.name);
      final ordinal = (ordinals[group] ?? 0) + 1;
      ordinals[group] = ordinal;
      allocations[monster.id] = _ActorAllocation(
        actorId: monster.id,
        name: monster.name,
        glyph: monster.glyph,
        group: group,
        ordinal: ordinal,
      );
      if (game.visible.contains(monster.position)) knownIds.add(monster.id);
    }
    return ActorIdentityContext._(allocations, knownIds);
  }

  ActorIdentityContext._(
    Map<String, _ActorAllocation> allocations,
    Set<String> knownIds,
  ) : _allocations = Map.unmodifiable(allocations),
      _knownIds = Set.unmodifiable(knownIds),
      knownActors = _presentations(allocations, knownIds);

  final Map<String, _ActorAllocation> _allocations;
  final Set<String> _knownIds;
  final Map<String, ActorPresentation> knownActors;

  ActorPresentation? operator [](String actorId) => knownActors[actorId];

  ActorIdentityContext noticeAll(Iterable<String> actorIds) {
    final noticed = {..._knownIds};
    for (final actorId in actorIds) {
      if (_allocations.containsKey(actorId)) noticed.add(actorId);
    }
    if (noticed.length == _knownIds.length) return this;
    return ActorIdentityContext._(_allocations, noticed);
  }

  Map<String, String> eventNames(Actor hero) => {
    hero.id: hero.name,
    for (final presentation in knownActors.values)
      presentation.actorId: presentation.displayName,
  };

  static Map<String, ActorPresentation> _presentations(
    Map<String, _ActorAllocation> allocations,
    Set<String> knownIds,
  ) {
    final knownByGroup = <(String, String), int>{};
    for (final actorId in knownIds) {
      final allocation = allocations[actorId];
      if (allocation == null) continue;
      knownByGroup[allocation.group] =
          (knownByGroup[allocation.group] ?? 0) + 1;
    }

    final presentations = <String, ActorPresentation>{};
    for (final actorId in knownIds) {
      final allocation = allocations[actorId];
      if (allocation == null) continue;
      presentations[actorId] = _presentationFor(allocation, knownByGroup);
    }
    return Map.unmodifiable(presentations);
  }

  static ActorPresentation _presentationFor(
    _ActorAllocation allocation,
    Map<(String, String), int> knownByGroup,
  ) {
    final ambiguous = (knownByGroup[allocation.group] ?? 0) >= 2;
    final badge = ambiguous ? _superscript(allocation.ordinal) : null;
    return ActorPresentation(
      actorId: allocation.actorId,
      displayName: ambiguous ? '${allocation.name}$badge' : allocation.name,
      glyph: allocation.glyph,
      badge: badge,
    );
  }
}

final class _ActorAllocation {
  const _ActorAllocation({
    required this.actorId,
    required this.name,
    required this.glyph,
    required this.group,
    required this.ordinal,
  });

  final String actorId;
  final String name;
  final String glyph;
  final (String, String) group;
  final int ordinal;
}

String _superscript(int value) {
  const digits = '⁰¹²³⁴⁵⁶⁷⁸⁹';
  return value
      .toString()
      .split('')
      .map((digit) => digits[int.parse(digit)])
      .join();
}
