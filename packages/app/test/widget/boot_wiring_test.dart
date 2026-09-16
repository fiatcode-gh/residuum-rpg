import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/game_bloc.dart';
import 'package:residuum_app/game/game_screen.dart';
import 'package:residuum_app/game/log_line.dart';
import 'package:residuum_app/main.dart';
import 'package:residuum_app/notice/notice.dart';
import 'package:residuum_app/save/boot.dart';
import 'package:residuum_app/save/save_store.dart';
import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

import '../support/memory_save_files.dart';
import '../support/pumped_app.dart';
import '../support/standing.dart';
import '../support/world_nav.dart';

SaveDocument _oneHero(
  Profile profile, {
  GameState? run,
  NodeId? dungeon,
  bool inside = false,
}) => SaveDocument.one(
  id: 'hero-1',
  label: 'Hero 1',
  profile: profile,
  world: run == null ? null : atTheCrypt(),
  run: run,
  dungeon: run == null ? null : (dungeon ?? cryptNode),
  campDay: run == null || inside ? null : 0,
  inside: inside,
);

void main() {
  group('booting the app', () {
    testWidgets('the first transaction in town is written down', (
      tester,
    ) async {
      // arrange
      final app = PumpedApp(
        _oneHero(newProfile(worldSeed: 5).copyWith(gold: 40)),
      );
      await app.pump(tester);

      // act
      await enterTown(tester, 'Stonebridge');
      await openTownDoor(tester, 'Bank');
      await tester.tap(find.text('MAX').first);
      await tester.pump();
      await tester.tap(find.text('Bank gold'));
      await tester.pumpAndSettle();

      // assert
      expect(app.saved!.profile.bankedGold, 40);
      expect(app.saved!.profile.gold, 0);
    });

    testWidgets('a document the hero is inside opens in the crawl', (
      tester,
    ) async {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final app = PumpedApp(
        _oneHero(
          profile,
          run: startDungeonRunAt(cryptNode, profile),
          dungeon: cryptNode,
          inside: true,
        ),
      );

      // act
      await app.pump(tester);

      // assert
      expect(find.text('THE CRYPT'), findsOneWidget);
      expect(find.text('The crawl resumes.'), findsOneWidget);
      final crawl = BlocProvider.of<GameBloc>(
        tester.element(find.byType(GameScreen)),
      );
      expect(
        crawl.state.log,
        contains(const LogLine('The crawl resumes.', LogCategory.reported)),
      );
    });

    testWidgets(
      'a resumed crawl reports a save notice under its own sentence',
      (tester) async {
        // arrange
        final profile = newProfile(worldSeed: 909);
        final document = _oneHero(
          profile,
          run: startDungeonRunAt(cryptNode, profile),
          dungeon: cryptNode,
          inside: true,
        );
        final store = SaveStore(MemorySaveFiles());
        await store.save(document);
        const notice = LoadNotice(
          'your last save could not be read; an older one was restored',
        );

        // act
        await tester.pumpWidget(
          ResiduumApp(
            store: store,
            boot: Boot(document: document, notice: notice),
          ),
        );
        await tester.pumpAndSettle();

        // assert
        final crawl = BlocProvider.of<GameBloc>(
          tester.element(find.byType(GameScreen)),
        );
        expect(
          crawl.state.log,
          contains(
            const LogLine(
              'Your last save could not be read; an older one was '
              'restored.',
              LogCategory.reported,
            ),
          ),
        );
      },
    );

    testWidgets('a document with a crawl the hero left opens on the world', (
      tester,
    ) async {
      // arrange
      final profile = newProfile(worldSeed: 909);
      final camp = startDungeonRunAt(cryptNode, profile);
      final app = PumpedApp(_oneHero(suspendRun(profile, camp), run: camp));

      // act
      await app.pump(tester);

      // assert
      expect(find.text('RESIDUUM'), findsOneWidget);
      expect(find.text('At The Crypt'), findsOneWidget);
      expect(find.textContaining('Resume the crawl'), findsOneWidget);
      expect(find.byType(GameScreen), findsNothing);
    });

    testWidgets('a document without one opens on the world, at home', (
      tester,
    ) async {
      // arrange
      final app = PumpedApp(_oneHero(newProfile(worldSeed: 909)));

      // act
      await app.pump(tester);

      // assert
      expect(find.text('RESIDUUM'), findsOneWidget);
      expect(find.text('At Stonebridge'), findsOneWidget);
      expect(find.text('Enter Stonebridge'), findsOneWidget);
      expect(find.byType(GameScreen), findsNothing);
    });
  });
}
