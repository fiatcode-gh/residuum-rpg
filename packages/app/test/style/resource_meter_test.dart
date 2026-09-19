import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/style/surfaces.dart';
import 'package:residuum_app/style/tokens.dart';

/// The WCAG 2.x relative-contrast reading: `(max(La, Lb) + 0.05) / (min(La,
/// Lb) + 0.05)`. Named explicitly because this plan carries exactly one
/// surviving contrast threshold and it must not be confused with the
/// fill-versus-surface ratio architect amendment A6 struck from AC4.
double _contrast(Color a, Color b) {
  final lighter = [a.computeLuminance(), b.computeLuminance()]..sort();
  return (lighter[1] + 0.05) / (lighter[0] + 0.05);
}

Future<void> _pumpMeter(WidgetTester tester, ResourceMeter meter) =>
    tester.pumpWidget(
      MaterialApp(
        theme: residuumTheme,
        home: Scaffold(
          body: Center(child: SizedBox(width: 300, child: meter)),
        ),
      ),
    );

void main() {
  group('the greyscale reading loses nothing — as arithmetic', () {
    test(
      'the two fills are indistinguishable from each other in greyscale',
      () {
        final delta =
            (meterHealthFill.computeLuminance() -
                    meterManaFill.computeLuminance())
                .abs();

        expect(delta, lessThan(0.02));
      },
    );

    test('the health fill clears the WCAG floor against the track', () {
      expect(_contrast(meterHealthFill, rule), greaterThanOrEqualTo(4.5));
    });

    test('the mana fill clears the WCAG floor against the track', () {
      expect(_contrast(meterManaFill, rule), greaterThanOrEqualTo(4.5));
    });
  });

  group('hue is reinforcement, not the carrier', () {
    testWidgets('the health meter carries its meaning in text alone', (
      tester,
    ) async {
      await _pumpMeter(
        tester,
        const ResourceMeter(
          label: 'HP',
          value: 14,
          ceiling: 20,
          tint: MeterTint.health,
          note: 'Steady',
        ),
      );

      expect(find.text('HP 14 / 20'), findsOneWidget);
      expect(find.text('Steady'), findsOneWidget);
      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(indicator.value, 14 / 20);
    });

    testWidgets('the mana meter carries its meaning in text alone', (
      tester,
    ) async {
      await _pumpMeter(
        tester,
        const ResourceMeter(
          label: 'Mana',
          value: 2,
          ceiling: 4,
          tint: MeterTint.mana,
          note: 'Ward 2',
        ),
      );

      expect(find.text('Mana 2 / 4'), findsOneWidget);
      expect(find.text('Ward 2'), findsOneWidget);
      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(indicator.value, 2 / 4);
    });
  });

  group('the two meters differ by more than their hue', () {
    testWidgets('render different label words and different numbers', (
      tester,
    ) async {
      const hpKey = Key('hp');
      const manaKey = Key('mana');
      await tester.pumpWidget(
        MaterialApp(
          theme: residuumTheme,
          home: Scaffold(
            body: Column(
              children: const [
                ResourceMeter(
                  key: hpKey,
                  label: 'HP',
                  value: 14,
                  ceiling: 20,
                  tint: MeterTint.health,
                ),
                ResourceMeter(
                  key: manaKey,
                  label: 'Mana',
                  value: 2,
                  ceiling: 4,
                  tint: MeterTint.mana,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('HP 14 / 20'), findsOneWidget);
      expect(find.text('Mana 2 / 4'), findsOneWidget);
    });
  });

  group('boundaries', () {
    testWidgets('a zero ceiling renders a zero-fill bar and throws nothing', (
      tester,
    ) async {
      await _pumpMeter(
        tester,
        const ResourceMeter(
          label: 'HP',
          value: 0,
          ceiling: 0,
          tint: MeterTint.health,
        ),
      );

      expect(tester.takeException(), isNull);
      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(indicator.value, 0.0);
    });

    testWidgets(
      'a value over its ceiling clamps the fill but keeps the number true',
      (tester) async {
        await _pumpMeter(
          tester,
          const ResourceMeter(
            label: 'HP',
            value: 25,
            ceiling: 20,
            tint: MeterTint.health,
          ),
        );

        expect(find.text('HP 25 / 20'), findsOneWidget);
        final indicator = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(indicator.value, 1.0);
      },
    );

    testWidgets('an empty note holds the same track width as a present one', (
      tester,
    ) async {
      await _pumpMeter(
        tester,
        const ResourceMeter(
          label: 'HP',
          value: 14,
          ceiling: 20,
          tint: MeterTint.health,
        ),
      );
      final withoutNote = tester.getRect(find.byType(LinearProgressIndicator));

      await _pumpMeter(
        tester,
        const ResourceMeter(
          label: 'HP',
          value: 14,
          ceiling: 20,
          tint: MeterTint.health,
          note: 'Steady',
        ),
      );
      final withNote = tester.getRect(find.byType(LinearProgressIndicator));

      expect(withoutNote, withNote);
    });
  });
}
