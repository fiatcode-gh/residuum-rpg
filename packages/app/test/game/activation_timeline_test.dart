import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/activation_timeline.dart';
import 'package:residuum_core/core.dart';

Actor _actor(String id) => Actor(
  id: id,
  name: id,
  glyph: 'g',
  position: const Position(1, 1),
  hp: 10,
  maxHp: 10,
  attackMin: 1,
  attackMax: 1,
  speed: 10,
  energy: actThreshold,
);

void main() {
  test('preserves repeated actor occurrences and closes at the next hero', () {
    final fast = _actor('fast');
    final other = _actor('other');

    final queue = projectActivationQueue(
      upNext: [fast, fast, other],
      visibleKnownActorIds: {'fast', 'other'},
    );

    expect(queue, hasLength(5));
    expect(
      queue[0],
      isA<HeroActivationToken>().having(
        (token) => token.isCurrent,
        'current',
        isTrue,
      ),
    );
    expect((queue[1] as ActorActivationToken).actor, same(fast));
    expect((queue[2] as ActorActivationToken).actor, same(fast));
    expect((queue[3] as ActorActivationToken).actor, same(other));
    expect(
      queue[4],
      isA<HeroActivationToken>().having(
        (token) => token.isCurrent,
        'current',
        isFalse,
      ),
    );
  });

  test('stops at the first hidden or unknown actor', () {
    final fast = _actor('fast');
    final hidden = _actor('hidden');
    final later = _actor('later');

    final queue = projectActivationQueue(
      upNext: [fast, hidden, later],
      visibleKnownActorIds: {'fast', 'later'},
    );

    expect(queue, hasLength(2));
    expect((queue[1] as ActorActivationToken).actor, same(fast));
  });

  test('empty schedules still show current and next hero activations', () {
    final queue = projectActivationQueue(
      upNext: const [],
      visibleKnownActorIds: const {},
    );

    expect(queue, hasLength(2));
    expect(
      queue[0],
      isA<HeroActivationToken>().having(
        (token) => token.isCurrent,
        'current',
        isTrue,
      ),
    );
    expect(
      queue[1],
      isA<HeroActivationToken>().having(
        (token) => token.isCurrent,
        'current',
        isFalse,
      ),
    );
  });

  test('returns an unmodifiable queue', () {
    final queue = projectActivationQueue(
      upNext: [_actor('fast')],
      visibleKnownActorIds: {'fast'},
    );

    expect(
      () => queue.add(const HeroActivationToken(isCurrent: false)),
      throwsUnsupportedError,
    );
  });
}
