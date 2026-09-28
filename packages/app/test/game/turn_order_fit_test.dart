import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/game/turn_order_strip.dart';

void main() {
  group('tokensThatFit', () {
    test('zero NEXT tokens fit trivially, with no cue', () {
      expect(
        tokensThatFit(const [], 200, 6, (hidden) => fail('no cue expected')),
        0,
      );
    });

    test('every pill fits when their total, plus the gaps between them, '
        'clears the available width', () {
      const widths = [48.0, 60.0, 52.0];
      // 48+60+52 + 6*2 = 172
      expect(
        tokensThatFit(widths, 172, 6, (hidden) => fail('no cue expected')),
        3,
      );
    });

    test('one pill too many drops to the largest count whose pills, gaps and '
        'cue all still fit', () {
      const widths = [48.0, 48.0, 48.0, 48.0];
      // all four: 4*48 + 6*3 = 210, one dp over budget.
      const available = 209.0;
      double cueWidth(int hidden) => 48;
      // three pills + cue: 3*48 + 6*3 + 48 = 210, still over.
      // two pills + cue: 2*48 + 6*2 + 48 = 156, fits.
      expect(tokensThatFit(widths, available, 6, cueWidth), 2);
    });

    test("a cue that grows with the hidden count never lets the row's total "
        'width exceed the available width', () {
      // Ten equal-width pills, none of which individually would starve
      // the cue: the cue's own width grows from a one-digit to a
      // two-digit number as fewer pills are kept, and the chosen count
      // must still respect whichever cue width that count implies.
      final widths = List<double>.filled(10, 48.0);
      const available = 260.0;
      double cueWidth(int hidden) => hidden >= 10 ? 60 : 48;

      final visible = tokensThatFit(widths, available, 6, cueWidth);
      final hidden = widths.length - visible;
      final rowWidth =
          visible * 48.0 + 6 * visible + (hidden > 0 ? cueWidth(hidden) : 0);

      expect(hidden, greaterThan(0));
      expect(rowWidth, lessThanOrEqualTo(available));
    });

    test('a cue is only measured for the hidden count that is actually '
        'chosen, from the widest count down', () {
      const widths = [48.0, 48.0, 48.0];
      final measuredFor = <int>[];
      double cueWidth(int hidden) {
        measuredFor.add(hidden);
        return 1000; // never fits, forces the search all the way to zero.
      }

      // All three fit on their own (144 + 12 = 156); 150 forces the search
      // past that shortcut and into the per-count loop below it.
      final visible = tokensThatFit(widths, 150, 6, cueWidth);

      expect(visible, 0);
      expect(measuredFor, [1, 2, 3]);
    });
  });
}
