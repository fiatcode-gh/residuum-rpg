import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/town/town_style.dart';

/// Pumps one stepper and returns a handle that reads and moves the value.
class _Dial {
  _Dial(this.tester, {required this.cap});

  final WidgetTester tester;
  final int cap;
  int value = 0;

  Future<void> pump() async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: StatefulBuilder(
              builder: (context, setState) => CountStepper(
                value: value,
                cap: cap,
                onChanged: (next) => setState(() => value = next),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> tap(String glyph) async {
    await tester.tap(find.text(glyph));
    await tester.pump();
  }
}

void main() {
  testWidgets('+ moves the value by one', (tester) async {
    // arrange
    final dial = _Dial(tester, cap: 4)..value = 2;
    await dial.pump();

    // act
    await dial.tap('+');

    // assert
    expect(dial.value, 3);
  });

  testWidgets('− moves the value down by one', (tester) async {
    final dial = _Dial(tester, cap: 4)..value = 2;
    await dial.pump();

    await dial.tap('−');

    expect(dial.value, 1);
  });

  testWidgets('MAX takes the value to the cap', (tester) async {
    final dial = _Dial(tester, cap: 4)..value = 2;
    await dial.pump();

    await dial.tap('MAX');

    expect(dial.value, 4);
  });

  testWidgets('the dial reads its value back', (tester) async {
    final dial = _Dial(tester, cap: 4)..value = 2;
    await dial.pump();

    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('+ is dead at the cap', (tester) async {
    final dial = _Dial(tester, cap: 4)..value = 4;
    await dial.pump();

    await dial.tap('+');

    expect(dial.value, 4);
  });

  testWidgets('MAX is dead at the cap', (tester) async {
    final dial = _Dial(tester, cap: 4)..value = 4;
    await dial.pump();

    await dial.tap('MAX');

    expect(dial.value, 4);
  });

  testWidgets('− is dead at 0', (tester) async {
    final dial = _Dial(tester, cap: 4)..value = 0;
    await dial.pump();

    await dial.tap('−');

    expect(dial.value, 0);
  });

  testWidgets('the value never leaves 0 to cap, even on a wild hold', (
    tester,
  ) async {
    final dial = _Dial(tester, cap: 3)..value = 0;
    await dial.pump();

    // act - a hold long enough to repeat far past the cap
    final plus = tester.getCenter(find.text('+'));
    final gesture = await tester.startGesture(plus);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 1200));
    await gesture.up();
    await tester.pump();

    // assert - the dial clamps, and so does the callback it hands out
    expect(dial.value, dial.cap);
  });

  testWidgets('holding + advances the count past one step', (tester) async {
    final dial = _Dial(tester, cap: 10)..value = 0;
    await dial.pump();

    // act - press down (one step), then pump the repeat cadence: the first
    // repeat lands at 400ms, the next at 120ms after it
    final plus = tester.getCenter(find.text('+'));
    final gesture = await tester.startGesture(plus);
    await tester.pump();
    expect(dial.value, 1, reason: 'the press-down itself steps once');
    await tester.pump(const Duration(milliseconds: 400));
    expect(dial.value, 2, reason: 'the first repeat');
    await tester.pump(const Duration(milliseconds: 120));
    expect(dial.value, 3, reason: 'the cadence');
    await gesture.up();
    await tester.pump();
    expect(dial.value, 3, reason: 'releasing steps nothing more');
  });

  testWidgets('a quick tap steps exactly once', (tester) async {
    final dial = _Dial(tester, cap: 10)..value = 0;
    await dial.pump();

    // act - down and up within the hold window
    await tester.tap(find.text('+'));
    await tester.pump();

    // assert
    expect(dial.value, 1);
  });
}