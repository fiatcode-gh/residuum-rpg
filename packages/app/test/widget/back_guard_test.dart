import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/game_screen.dart';
import 'package:residuum_app/town/town_bloc.dart';
import 'package:residuum_content/content.dart';

/// The crawl route, pushed over a town exactly as the session pushes it.
///
/// Pushed rather than pumped as `home:`, because the guard is a property of a
/// route with something underneath it: a route at the bottom of the stack has
/// nothing to pop to, so a test that pumped one would pass whatever the guard
/// said.
///
/// The real [GameScreen] over a real [GameBloc], because the wiring between them
/// is the whole subject. A fake screen would be testing the test.
///
/// Neither bloc is closed when the test ends, and that is deliberate: a widget
/// test's clock is a fake one, a bloc completes its own close on the event loop,
/// and awaiting that inside `testWidgets` hangs the test forever rather than
/// failing it. The blocs live as long as the test process, which is measured in
/// milliseconds.
Future<GameBloc> _pushCrawl(WidgetTester tester, {bool dead = false}) async {
  final profile = newProfile(worldSeed: 5);
  final run = startDungeonRunAt(cryptNode, profile);
  final town = TownBloc(profile: profile);
  final game = GameBloc(
    game: dead
        ? run.copyWith(hero: run.hero.copyWith(hp: 0), isGameOver: true)
        : run,
    stepDelay: Duration.zero,
  );
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => MultiBlocProvider(
                providers: [
                  BlocProvider.value(value: town),
                  BlocProvider.value(value: game),
                ],
                child: const GameScreen(),
              ),
            ),
          ),
          child: const Text('down'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('down'));
  await tester.pumpAndSettle();
  return game;
}

void main() {
  group('the crawl route and the system back button', () {
    testWidgets('declines the pop and says where the way out is', (
      tester,
    ) async {
      // arrange
      final game = await _pushCrawl(tester);

      // act
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      // assert
      expect(find.byType(GameScreen), findsOneWidget);
      expect(game.state.log, ['You can only leave at the stairs.']);
    });

    testWidgets('says nothing over a death overlay that already says what to '
        'do', (tester) async {
      // arrange
      final game = await _pushCrawl(tester, dead: true);

      // act
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      // assert
      expect(find.byType(GameScreen), findsOneWidget);
      expect(game.state.log, isEmpty);
    });

    testWidgets('a pop the app asked for itself says nothing', (tester) async {
      // arrange
      final game = await _pushCrawl(tester);

      // act
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pumpAndSettle();

      // assert
      expect(find.byType(GameScreen), findsNothing);
      expect(game.state.log, isEmpty);
    });
  });
}
