import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/notice/notice.dart';
import 'package:residuum_app/town/roster_screen.dart';
import 'package:residuum_content/content.dart';

SaveDocument _twoHeroes() => SaveDocument(
  active: 'hero-2',
  heroes: {
    'hero-1': SavedHero(
      label: 'Ilse',
      profile: newProfile(worldSeed: 111).copyWith(gold: 40, visit: 2),
      run: startDungeonRunAt(cryptNode, newProfile(worldSeed: 111)),
      dungeon: cryptNode,
      campDay: 0,
    ),
    'hero-2': SavedHero(
      label: 'Bram',
      profile: newProfile(worldSeed: 222).copyWith(bankedGold: 90),
    ),
  },
);

SaveDocument _oneHero() => SaveDocument.one(
  id: 'hero-1',
  label: 'Hero 1',
  profile: newProfile(worldSeed: 111),
);

SaveDocument _threeHeroes() => SaveDocument(
  active: 'hero-2',
  heroes: {
    'hero-1': SavedHero(
      label: 'Ilse',
      profile: newProfile(worldSeed: 111).copyWith(gold: 40, visit: 2),
      run: startDungeonRunAt(cryptNode, newProfile(worldSeed: 111)),
      dungeon: cryptNode,
      campDay: 0,
    ),
    'hero-2': SavedHero(
      label: 'Bram',
      profile: newProfile(worldSeed: 222).copyWith(bankedGold: 90),
    ),
    'hero-3': SavedHero(
      label: 'Cato',
      profile: newProfile(worldSeed: 333).copyWith(gold: 15, visit: 1),
    ),
  },
);

/// The roster, opened over a screen, with whatever it answered kept for the
/// test.
///
/// Opened by a tap rather than pumped as `home:`, because what the roster
/// answers with is the whole of its interface: a screen at the bottom of the
/// stack has nowhere to pop an answer to, so a test that pumped one could not
/// see the answer at all.
class _Opened {
  RosterChoice? chosen;
  bool closed = false;

  Future<void> open(WidgetTester tester, SaveDocument document) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              chosen = await Navigator.of(context).push<RosterChoice>(
                MaterialPageRoute<RosterChoice>(
                  builder: (_) => RosterScreen(document: document),
                ),
              );
              closed = true;
            },
            child: const Text('heroes'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('heroes'));
    await tester.pumpAndSettle();
  }
}

void main() {
  group('the roster', () {
    testWidgets('every hero is a row, in words and numbers', (tester) async {
      // arrange
      final opened = _Opened();

      // act
      await opened.open(tester, _twoHeroes());

      // assert
      expect(find.text('Ilse'), findsOneWidget);
      expect(find.text('Bram'), findsOneWidget);
      expect(find.textContaining('below (depth 1)'), findsOneWidget);
      expect(find.textContaining('in town'), findsOneWidget);
      expect(find.text('playing'), findsOneWidget);
    });

    testWidgets('tapping another hero answers with them', (tester) async {
      // arrange
      final opened = _Opened();
      await opened.open(tester, _twoHeroes());

      // act
      await tester.tap(find.text('Ilse'));
      await tester.pumpAndSettle();

      // assert
      expect(opened.chosen, const PlayHero('hero-1'));
      expect(opened.closed, isTrue);
    });

    testWidgets('tapping the hero already being played answers nothing', (
      tester,
    ) async {
      // arrange
      final opened = _Opened();
      await opened.open(tester, _twoHeroes());

      // act
      await tester.tap(find.text('Bram'));
      await tester.pumpAndSettle();

      // assert
      expect(opened.chosen, isNull);
      expect(opened.closed, isFalse);
    });

    testWidgets('deleting asks first, and a refusal answers nothing', (
      tester,
    ) async {
      // arrange
      final opened = _Opened();
      await opened.open(tester, _twoHeroes());

      // act
      await tester.tap(find.text('Delete').first);
      await tester.pumpAndSettle();

      // assert
      expect(find.text('Delete Ilse?'), findsOneWidget);
      expect(opened.chosen, isNull);
      expect(opened.closed, isFalse);

      // act
      await tester.tap(find.text('Keep this hero'));
      await tester.pumpAndSettle();

      // assert
      expect(opened.chosen, isNull);
      expect(opened.closed, isFalse);
      expect(find.text('Ilse'), findsOneWidget);
    });

    testWidgets('a confirmed delete answers with the hero to drop', (
      tester,
    ) async {
      // arrange
      final opened = _Opened();
      await opened.open(tester, _twoHeroes());

      // act
      await tester.tap(find.text('Delete').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete this hero'));
      await tester.pumpAndSettle();

      // assert
      expect(opened.chosen, const DropHero('hero-1'));
    });

    testWidgets('the dialog says the suspended crawl dies with the hero', (
      tester,
    ) async {
      // arrange
      final opened = _Opened();
      await opened.open(tester, _twoHeroes());

      // act
      await tester.tap(find.text('Delete').first);
      await tester.pumpAndSettle();

      // assert
      expect(find.textContaining('crawl they are standing in'), findsOneWidget);
    });

    testWidgets('the dialog says nothing about a crawl for a hero in town', (
      tester,
    ) async {
      // arrange
      final opened = _Opened();
      await opened.open(tester, _twoHeroes());

      // act
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      // assert
      expect(find.text('Delete Bram?'), findsOneWidget);
      expect(find.textContaining('crawl'), findsNothing);
    });

    testWidgets('deleting the only hero flows into creating the next', (
      tester,
    ) async {
      // arrange
      final opened = _Opened();
      await opened.open(tester, _oneHero());

      // act
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // assert
      expect(find.textContaining('A new hero begins'), findsOneWidget);

      // act
      await tester.tap(find.text('Delete this hero'));
      await tester.pumpAndSettle();

      // assert
      expect(find.text('Name your hero'), findsOneWidget);
      expect(opened.chosen, isNull);

      // act
      await tester.tap(find.text('Begin'));
      await tester.pumpAndSettle();

      // assert
      expect(opened.chosen, const MakeHero('Hero 2', replacing: 'hero-1'));
    });

    testWidgets('backing out of the name leaves the only hero alone', (
      tester,
    ) async {
      // arrange
      final opened = _Opened();
      await opened.open(tester, _oneHero());

      // act
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete this hero'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Not yet'));
      await tester.pumpAndSettle();

      // assert
      expect(opened.chosen, isNull);
      expect(opened.closed, isFalse);
      expect(find.text('Hero 1'), findsOneWidget);
    });

    testWidgets('creating asks a name, prefilled with the next number', (
      tester,
    ) async {
      // arrange
      final opened = _Opened();
      await opened.open(tester, _twoHeroes());

      // act
      await tester.tap(find.text('New hero'));
      await tester.pumpAndSettle();

      // assert
      expect(find.text('Hero 3'), findsOneWidget);

      // act
      await tester.enterText(find.byType(TextField), 'Cato');
      await tester.tap(find.text('Begin'));
      await tester.pumpAndSettle();

      // assert
      expect(opened.chosen, const MakeHero('Cato'));
    });

    testWidgets('a name of nothing falls back to the one offered', (
      tester,
    ) async {
      // arrange
      final opened = _Opened();
      await opened.open(tester, _twoHeroes());

      // act
      await tester.tap(find.text('New hero'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.text('Begin'));
      await tester.pumpAndSettle();

      // assert
      expect(opened.chosen, const MakeHero('Hero 3'));
    });
  });

  group('a keyed roster row', () {
    testWidgets(
      "each hero's row is keyed, and its facts belong to that hero alone",
      (tester) async {
        // arrange
        final opened = _Opened();
        final document = _threeHeroes();

        // act
        await opened.open(tester, document);

        // assert
        for (final id in document.heroes.keys) {
          final hero = document.heroes[id]!;
          final row = find.byKey(Key('roster-hero-$id'));
          expect(row, findsOneWidget);
          expect(
            find.descendant(of: row, matching: find.text(hero.label)),
            findsOneWidget,
          );
          expect(
            find.descendant(of: row, matching: find.text(rosterLine(hero))),
            findsOneWidget,
          );
        }
        expect(
          find.descendant(
            of: find.byKey(const Key('roster-hero-hero-2')),
            matching: find.text('playing'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('roster-hero-hero-1')),
            matching: find.text('playing'),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('roster-hero-hero-3')),
            matching: find.text('playing'),
          ),
          findsNothing,
        );
      },
    );

    testWidgets('the rows appear in document.heroes.keys order', (
      tester,
    ) async {
      // arrange
      final opened = _Opened();
      final document = _threeHeroes();

      // act
      await opened.open(tester, document);

      // assert
      final tops = [
        for (final id in document.heroes.keys)
          tester.getTopLeft(find.byKey(Key('roster-hero-$id'))).dy,
      ];
      for (var i = 1; i < tops.length; i++) {
        expect(tops[i], greaterThan(tops[i - 1]));
      }
    });

    testWidgets("a row's delete belongs to that hero, not its position", (
      tester,
    ) async {
      // arrange
      final opened = _Opened();
      final document = _threeHeroes();
      await opened.open(tester, document);

      // act — hero-3 is neither first nor active, so a positional coincidence
      // cannot pass this.
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('roster-hero-hero-3')),
          matching: find.text('Delete'),
        ),
      );
      await tester.pumpAndSettle();

      // assert
      expect(find.text('Delete Cato?'), findsOneWidget);
    });

    testWidgets(
      "the played hero's own row still answers nothing, another's answers "
      'with them',
      (tester) async {
        // arrange
        final opened = _Opened();
        final document = _threeHeroes();
        await opened.open(tester, document);

        // act
        await tester.tap(
          find.descendant(
            of: find.byKey(const Key('roster-hero-hero-2')),
            matching: find.text('Bram'),
          ),
        );
        await tester.pumpAndSettle();

        // assert
        expect(opened.chosen, isNull);
        expect(opened.closed, isFalse);

        // act
        await tester.tap(
          find.descendant(
            of: find.byKey(const Key('roster-hero-hero-3')),
            matching: find.text('Cato'),
          ),
        );
        await tester.pumpAndSettle();

        // assert
        expect(opened.chosen, const PlayHero('hero-3'));
      },
    );

    testWidgets('the notice renders above the first row', (tester) async {
      // arrange
      final document = _twoHeroes();

      // act
      await tester.pumpWidget(
        MaterialApp(
          home: RosterScreen(
            document: document,
            notice: const SentenceNotice('a wandering hero was found'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // assert
      final noticeY = tester
          .getTopLeft(find.textContaining('a wandering hero was found'))
          .dy;
      final firstRowY = tester
          .getTopLeft(find.byKey(const Key('roster-hero-hero-1')))
          .dy;
      expect(noticeY, lessThan(firstRowY));
    });

    testWidgets(
      "a row for a hero standing in a crawl reads depth, never 'crawl'",
      (tester) async {
        // arrange
        final opened = _Opened();
        final document = _threeHeroes();

        // act
        await opened.open(tester, document);

        // assert
        expect(
          find.descendant(
            of: find.byKey(const Key('roster-hero-hero-1')),
            matching: find.textContaining('below (depth 1)'),
          ),
          findsOneWidget,
        );
        expect(find.textContaining('crawl'), findsNothing);
      },
    );
  });

  group('a roster row', () {
    test('reads out health, gold, visits and where the hero is', () {
      // arrange
      final hero = SavedHero(
        label: 'Ilse',
        profile: newProfile(worldSeed: 111)
            .copyWith(gold: 40, bankedGold: 90, visit: 2),
        run: startDungeonRunAt(cryptNode, newProfile(worldSeed: 111)),
        dungeon: cryptNode,
        campDay: 0,
      );

      // act
      final line = rosterLine(hero);

      // assert
      expect(
        line,
        '20/20 hp · 40 carried · 90 banked · 2 visits · below (depth 1)',
      );
    });

    test('a hero in town says so rather than saying nothing', () {
      // arrange
      final hero = SavedHero(
        label: 'Bram',
        profile: newProfile(worldSeed: 222),
      );

      // act
      final line = rosterLine(hero);

      // assert
      expect(line, '20/20 hp · 0 carried · 0 banked · no visits yet · in town');
    });

    test('one visit is one visit, not one visits', () {
      // arrange
      final hero = SavedHero(
        label: 'Bram',
        profile: newProfile(worldSeed: 222).copyWith(visit: 1),
      );

      // act
      final line = rosterLine(hero);

      // assert
      expect(line, contains('1 visit ·'));
    });
  });
}
