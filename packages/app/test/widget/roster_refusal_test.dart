import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/save/save_files.dart';
import 'package:residuum_content/content.dart';

import '../support/pumped_app.dart';

SaveDocument _twoHeroes() => SaveDocument(
  active: 'hero-2',
  heroes: {
    'hero-1': SavedHero(label: 'Ilse', profile: newProfile(worldSeed: 111)),
    'hero-2': SavedHero(
      label: 'Bram',
      profile: newProfile(worldSeed: 222).copyWith(gold: 7),
    ),
  },
);

Future<void> _openRoster(WidgetTester tester) async {
  await tester.tap(find.text('Heroes'));
  await tester.pumpAndSettle();
}

void main() {
  group('a roster edit the disk refuses', () {
    testWidgets('creating a hero keeps the session and says so', (
      tester,
    ) async {
      // arrange — the rotate cannot land: the write succeeds, the read-back
      // passes, the rename does not. The save did not land.
      final app = PumpedApp(_twoHeroes());
      await app.pump(tester);
      app.files.failRenamesFrom.add(currentSlot);

      // act
      await _openRoster(tester);
      await tester.tap(find.text('New hero'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Cato');
      await tester.tap(find.text('Begin'));
      await tester.pumpAndSettle();

      // assert — the roster is back with the sentence on it, the hero being
      // played is unchanged, and the disk holds what it held. The session
      // refused to advance.
      expect(
        find.textContaining('the new hero could not be saved'),
        findsOneWidget,
      );
      expect(find.text('New hero'), findsOneWidget);
      expect(find.text('Ilse'), findsOneWidget);
      expect(app.saved!.hero.label, 'Bram');
      expect(app.saved!.heroes, hasLength(2));
    });

    testWidgets('switching hero refuses the same way', (tester) async {
      // arrange
      final app = PumpedApp(_twoHeroes());
      await app.pump(tester);
      app.files.failRenamesFrom.add(currentSlot);

      // act
      await _openRoster(tester);
      await tester.tap(find.text('Ilse'));
      await tester.pumpAndSettle();

      // assert — the roster is back with the switch's own sentence, and the
      // hero being played did not change.
      expect(
        find.textContaining('the hero could not be switched'),
        findsOneWidget,
      );
      expect(app.saved!.hero.label, 'Bram');
    });

    testWidgets('a roster edit that lands still rebuilds the session', (
      tester,
    ) async {
      // arrange — the control: no injected failure.
      final app = PumpedApp(_twoHeroes());
      await app.pump(tester);

      // act
      await _openRoster(tester);
      await tester.tap(find.text('New hero'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Cato');
      await tester.tap(find.text('Begin'));
      await tester.pumpAndSettle();

      // assert
      expect(app.saved!.hero.label, 'Cato');
      expect(find.text('Carried  0 gold'), findsOneWidget);
    });

    testWidgets('a retry after a refusal can still land', (tester) async {
      // arrange
      final app = PumpedApp(_twoHeroes());
      await app.pump(tester);
      app.files.failRenamesFrom.add(currentSlot);

      // act — refuse once, then let the disk work, then create again.
      await _openRoster(tester);
      await tester.tap(find.text('Ilse'));
      await tester.pumpAndSettle();
      app.files.failRenamesFrom.remove(currentSlot);
      await tester.tap(find.text('Ilse'));
      await tester.pumpAndSettle();

      // assert — the second edit landed on the disk and the session rebuilt.
      expect(app.saved!.hero.label, 'Ilse');
      expect(find.text('Carried  0 gold'), findsOneWidget);
    });
  });
}
