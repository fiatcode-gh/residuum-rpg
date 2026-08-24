import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/game_screen.dart';
import 'package:residuum_app/town/town_bloc.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

/// The world seed whose sea-cave rolls six floors on visit one and whose keep
/// rolls seven, so the status line has something to say that the crypt's fixed
/// five would have hidden.
const int _pinnedSeed = 4242;

/// A [GameScreen] over a real crawl in the dungeon at [node].
///
/// The real screen over a real bloc, for the reason `back_guard_test` gives:
/// the wiring between them is the whole subject, and the status line is a
/// private static a bloc test cannot reach. Neither bloc is closed, also for
/// that file's reason — a widget test's clock is a fake one and awaiting a
/// bloc's close inside `testWidgets` hangs rather than fails.
Future<void> _pumpCrawlAt(WidgetTester tester, NodeId node) async {
  final profile = newProfile(worldSeed: _pinnedSeed);
  final town = TownBloc(profile: profile);
  final game = GameBloc(
    game: startDungeonRunAt(node, profile),
    dungeon: node,
    stepDelay: Duration.zero,
  );
  await tester.pumpWidget(
    MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: town),
          BlocProvider.value(value: game),
        ],
        child: const GameScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('the status line and how deep the delve goes', () {
    testWidgets('names the sea-cave and the six floors it rolled', (
      tester,
    ) async {
      // arrange
      final rolled = delveDepth(seaCave, _pinnedSeed, 1);

      // act
      await _pumpCrawlAt(tester, seaCave);

      // assert
      expect(rolled, 6);
      expect(rolled, isNot(deepestDepth));
      expect(find.textContaining('The Sea-Cave — depth 1/6'), findsOne);
    });

    testWidgets('names the keep and the seven floors it rolled', (
      tester,
    ) async {
      // arrange
      final rolled = delveDepth(ruinedKeep, _pinnedSeed, 1);

      // act
      await _pumpCrawlAt(tester, ruinedKeep);

      // assert
      expect(rolled, 7);
      expect(find.textContaining('The Ruined Keep — depth 1/7'), findsOne);
    });

    testWidgets('still reads depth 1/5 in the crypt', (tester) async {
      // act
      await _pumpCrawlAt(tester, cryptNode);

      // assert
      expect(find.textContaining('The Crypt — depth 1/5'), findsOne);
    });
  });
}
