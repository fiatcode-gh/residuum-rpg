import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

  group('a roster row', () {
    test('reads out health, gold, visits and where the hero is', () {
      // arrange
      final hero = SavedHero(
        label: 'Ilse',
        profile: newProfile(worldSeed: 111)
            .copyWith(gold: 40, bankedGold: 90, visit: 2),
        run: startDungeonRunAt(cryptNode, newProfile(worldSeed: 111)),
        dungeon: cryptNode,
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
