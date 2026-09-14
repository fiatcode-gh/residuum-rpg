import 'package:residuum_core/core.dart';

sealed class ActivationToken {
  const ActivationToken();
}

final class HeroActivationToken extends ActivationToken {
  const HeroActivationToken({required this.isCurrent});

  final bool isCurrent;
}

final class ActorActivationToken extends ActivationToken {
  const ActorActivationToken(this.actor);

  final Actor actor;
}

List<ActivationToken> projectActivationQueue({
  required List<Actor> upNext,
  required Set<String> visibleKnownActorIds,
}) {
  final tokens = <ActivationToken>[const HeroActivationToken(isCurrent: true)];
  for (final actor in upNext) {
    if (!visibleKnownActorIds.contains(actor.id)) {
      return List.unmodifiable(tokens);
    }
    tokens.add(ActorActivationToken(actor));
  }
  tokens.add(const HeroActivationToken(isCurrent: false));
  return List.unmodifiable(tokens);
}
