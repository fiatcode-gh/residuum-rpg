// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/style/surfaces.dart';
import 'package:residuum_app/style/tokens.dart';
import 'package:residuum_app/town/town_style.dart';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('empty and marked medallions keep the same measurable host', (
    tester,
  ) async {
    const emptyKey = Key('empty-medallion');
    const markedKey = Key('marked-medallion');

    await tester.pumpWidget(
      _app(
        const Column(
          children: [
            FramedRow(title: 'Empty', medallionKey: emptyKey),
            FramedRow(
              title: 'Marked',
              medallion: Text('!'),
              medallionKey: markedKey,
            ),
          ],
        ),
      ),
    );

    expect(tester.getSize(find.byKey(emptyKey)), const Size(44, 44));
    expect(tester.getSize(find.byKey(markedKey)), const Size(44, 44));
    expect(
      tester.getTopLeft(find.byKey(emptyKey)).dx,
      tester.getTopLeft(find.byKey(markedKey)).dx,
    );
    expect(
      tester.getTopLeft(find.byKey(emptyKey)).dy,
      lessThan(tester.getTopLeft(find.byKey(markedKey)).dy),
    );

    final wells = find.descendant(
      of: find.byKey(emptyKey),
      matching: find.byType(SizedBox),
    );
    final innerWell = wells.evaluate().firstWhere(
      (element) => tester.getSize(find.byWidget(element.widget)).width == 36,
    );
    expect(tester.getSize(find.byWidget(innerWell.widget)), const Size(36, 36));

    final decoration =
        tester
                .widget<DecoratedBox>(
                  find.descendant(
                    of: find.byKey(emptyKey),
                    matching: find.byType(DecoratedBox),
                  ),
                )
                .decoration
            as BoxDecoration;
    expect(decoration.color, Colors.transparent);
    expect(decoration.shape, BoxShape.circle);
    expect(decoration.border, Border.all(color: rule, width: hairline));
    expect(
      find.descendant(of: find.byKey(emptyKey), matching: find.byType(Image)),
      findsNothing,
    );
    expect(
      find.descendant(of: find.byKey(emptyKey), matching: find.byType(Icon)),
      findsNothing,
    );
    expect(
      find.descendant(of: find.byKey(emptyKey), matching: find.byType(Text)),
      findsNothing,
    );
  });

  testWidgets('the outer surface uses the shared panel grammar', (
    tester,
  ) async {
    const rowKey = Key('surface-row');
    await tester.pumpWidget(
      _app(const FramedRow(key: rowKey, title: 'Surface')),
    );

    final material = tester.widget<Material>(
      find.descendant(of: find.byKey(rowKey), matching: find.byType(Material)),
    );
    expect(material.color, panel);
    expect(material.elevation, 0);
    final shape = material.shape as RoundedRectangleBorder;
    expect(shape.borderRadius, BorderRadius.circular(radius));
    expect(shape.side, BorderSide(color: rule, width: hairline));
  });

  testWidgets('a whole-row callback has button semantics, static rows do not', (
    tester,
  ) async {
    var presses = 0;
    const activeKey = Key('active-row');
    const staticKey = Key('static-row');
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            FramedRow(
              key: activeKey,
              title: 'Active',
              onPressed: () => presses++,
            ),
            const FramedRow(key: staticKey, title: 'Static'),
          ],
        ),
      ),
    );

    final activeSemantics = tester.getSemantics(
      find
          .descendant(
            of: find.byKey(activeKey),
            matching: find.byType(Semantics),
          )
          .first,
    );
    expect(activeSemantics.hasFlag(SemanticsFlag.isButton), isTrue);
    expect(activeSemantics.hasFlag(SemanticsFlag.isEnabled), isTrue);
    await tester.tap(find.byKey(activeKey));
    expect(presses, 1);

    final staticSemantics = tester.getSemantics(
      find
          .descendant(
            of: find.byKey(staticKey),
            matching: find.byType(Semantics),
          )
          .first,
    );
    expect(staticSemantics.hasFlag(SemanticsFlag.isButton), isFalse);
  });

  testWidgets('ItemRow keeps details, refusal, action and callback behavior', (
    tester,
  ) async {
    var presses = 0;
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            ItemRow(
              marking: '[!]',
              name: 'Enabled item',
              details: const ['normal detail'],
              action: 'Use',
              onPressed: () => presses++,
              reason: 'should stay hidden',
            ),
            const ItemRow(
              marking: '[?]',
              name: 'Disabled item',
              details: ['first detail', 'second detail'],
              action: 'Buy',
              onPressed: null,
              reason: 'not enough gold',
            ),
          ],
        ),
      ),
    );

    expect(find.text('normal detail'), findsOneWidget);
    expect(find.text('should stay hidden'), findsNothing);
    expect(find.text('first detail'), findsOneWidget);
    expect(find.text('second detail'), findsOneWidget);
    expect(find.text('not enough gold'), findsOneWidget);
    final detailPositions = [
      tester.getTopLeft(find.text('first detail')).dy,
      tester.getTopLeft(find.text('second detail')).dy,
      tester.getTopLeft(find.text('not enough gold')).dy,
    ];
    expect(detailPositions[0], lessThan(detailPositions[1]));
    expect(detailPositions[1], lessThan(detailPositions[2]));

    await tester.tap(find.text('Use'));
    expect(presses, 1);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Buy'))
          .onPressed,
      isNull,
    );
  });
}
