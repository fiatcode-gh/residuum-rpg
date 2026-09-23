import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/main.dart';
import 'package:residuum_app/save/save_store.dart';
import 'package:residuum_app/style/tokens.dart';

import '../support/memory_save_files.dart';

double _widthOf(String text, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

/// Whether the `cmap` table of a TrueType/OpenType font maps [codepoint] to
/// a real glyph, parsed straight from the font's own bytes rather than
/// inferred from a `TextPainter` width.
///
/// A width-based check was tried first and rejected: several marks Spectral
/// genuinely covers (the digits, `§`, `−`, `<`, `>`, `×`, `–`) happen to
/// share Spectral's own `.notdef` advance of exactly 0.500 em, so a covered
/// glyph and a truly absent one can be numerically indistinguishable by
/// width alone. Parsing `cmap` directly is also how PLAN.md's F3 established
/// the twelve-mark absent set in the first place, so this reproduces that
/// finding's own method rather than a proxy for it.
bool _cmapContains(Uint8List font, int codepoint) {
  final data = ByteData.sublistView(font);
  int u16(int o) => data.getUint16(o);
  int u32(int o) => data.getUint32(o);
  int i16(int o) => data.getInt16(o);

  final numTables = u16(4);
  var cmapOffset = -1;
  for (var i = 0; i < numTables; i++) {
    final entry = 12 + i * 16;
    final tag = String.fromCharCodes(font.sublist(entry, entry + 4));
    if (tag == 'cmap') {
      cmapOffset = u32(entry + 8);
      break;
    }
  }
  if (cmapOffset < 0) {
    throw StateError('font carries no cmap table');
  }

  final subtableCount = u16(cmapOffset + 2);
  var bestOffset = -1;
  var bestScore = -1;
  for (var i = 0; i < subtableCount; i++) {
    final recordOffset = cmapOffset + 4 + i * 8;
    final platformId = u16(recordOffset);
    final encodingId = u16(recordOffset + 2);
    final subtableOffset = cmapOffset + u32(recordOffset + 4);
    final format = u16(subtableOffset);
    final score = switch ((platformId, encodingId, format)) {
      (3, 10, 12) => 4,
      (0, 4, 12) || (0, 6, 12) => 3,
      (3, 1, 4) => 2,
      (0, _, 4) => 1,
      _ => 0,
    };
    if (score > bestScore) {
      bestScore = score;
      bestOffset = subtableOffset;
    }
  }
  if (bestOffset < 0) {
    throw StateError('font carries no usable cmap subtable');
  }

  final format = u16(bestOffset);
  if (format == 4) {
    final segCountX2 = u16(bestOffset + 6);
    final segCount = segCountX2 ~/ 2;
    final endCodeStart = bestOffset + 14;
    final startCodeStart = endCodeStart + segCountX2 + 2;
    final idDeltaStart = startCodeStart + segCountX2;
    final idRangeOffsetStart = idDeltaStart + segCountX2;
    for (var i = 0; i < segCount; i++) {
      final endCode = u16(endCodeStart + i * 2);
      final startCode = u16(startCodeStart + i * 2);
      if (codepoint < startCode || codepoint > endCode) {
        continue;
      }
      final idDelta = i16(idDeltaStart + i * 2);
      final idRangeOffset = u16(idRangeOffsetStart + i * 2);
      int glyphId;
      if (idRangeOffset == 0) {
        glyphId = (codepoint + idDelta) & 0xFFFF;
      } else {
        final glyphIndexAddress =
            idRangeOffsetStart +
            i * 2 +
            idRangeOffset +
            2 * (codepoint - startCode);
        glyphId = u16(glyphIndexAddress);
        if (glyphId != 0) {
          glyphId = (glyphId + idDelta) & 0xFFFF;
        }
      }
      return glyphId != 0;
    }
    return false;
  } else if (format == 12) {
    final numGroups = u32(bestOffset + 12);
    var offset = bestOffset + 16;
    for (var i = 0; i < numGroups; i++) {
      final startCharCode = u32(offset);
      final endCharCode = u32(offset + 4);
      final startGlyphId = u32(offset + 8);
      if (codepoint >= startCharCode && codepoint <= endCharCode) {
        return startGlyphId + (codepoint - startCharCode) != 0;
      }
      offset += 12;
    }
    return false;
  }
  throw StateError('unsupported cmap format $format');
}

void main() {
  group('the faces resolve in the test host', () {
    test('textLabel measures i and M at different widths', () {
      final iWidth = _widthOf('iiiiiiiiii', textLabel);
      final mWidth = _widthOf('MMMMMMMMMM', textLabel);
      // Under the Ahem fallback every glyph is the same em square, so this
      // inequality is exactly what breaks if `flutter_test_config.dart` is
      // ever lost or moved and the suite reverts to Ahem metrics.
      expect(iWidth, lessThan(mWidth));
    });

    test('displayTitle measures i and M at different widths', () {
      final iWidth = _widthOf('iiiiiiiiii', displayTitle);
      final mWidth = _widthOf('MMMMMMMMMM', displayTitle);
      expect(iWidth, lessThan(mWidth));
    });

    test('monoData advances a fixed 0.6 em per glyph', () {
      final mWidth = _widthOf('MMMMMMMMMM', monoData);
      final iWidth = _widthOf('iiiiiiiiii', monoData);
      // Under the Ahem fallback every glyph measures the full 11.5 dp em
      // square: 115.0. IBM Plex Mono's fixed 0.6 em advance yields 69.0
      // regardless of glyph shape, unlike the proportional faces above.
      expect(mWidth, closeTo(69.0, 0.5));
      expect(iWidth, closeTo(69.0, 0.5));
    });
  });

  group('glyph coverage, per mark', () {
    final spectralBytes = File('assets/fonts/Spectral-Regular.ttf')
        .readAsBytesSync();

    // Every mark the application draws in `textFace`, except the twelve
    // below.
    const covered = {
      '←',
      '→',
      '†',
      '■',
      '▲',
      '▼',
      '◆',
      '§',
      '‡',
      '·',
      '−',
      '?',
      '<',
      '>',
      '›',
      '↓',
      '×',
      '—',
      '–',
      '⁰',
      '¹',
      '²',
      '³',
      '⁴',
      '⁵',
      '⁶',
      '⁷',
      '⁸',
      '⁹',
      '△',
      '◇',
      '@',
      '*',
      '.',
      '#',
      '0',
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
    };

    // Confirmed absent from both Spectral and EB Garamond (PLAN.md F3).
    // Two of the nine are `lib/game/crawl_status.dart` marks, staying until
    // Task 10 retires that file; seven are `const` markings in
    // `packages/core`, which this unit may not touch — U16 retires them.
    const absent = {
      '✖', // U+2716 — lib/game/crawl_status.dart, engaged
      '◉', // U+25C9 — lib/game/crawl_status.dart, watched
      '※', // U+203B — core/lib/src/loot/rarity.dart, Epic
      '★', // U+2605 — core/lib/src/loot/rarity.dart, Legendary
      '▮', // U+25AE — core/lib/src/craft/material.dart, ingot
      '✿', // U+273F — core/lib/src/craft/material.dart, gather_node.dart, herb patch
      '✳', // U+2733 — core/lib/src/magic/spell.dart, spell chip labels
      '✚', // U+271A — core/lib/src/magic/spell.dart, spell chip labels
      '⛒', // U+26D2 — core/lib/src/magic/spell.dart, spell chip labels
    };

    for (final mark in covered) {
      test('$mark is covered', () {
        expect(_cmapContains(spectralBytes, mark.runes.first), isTrue);
      });
    }

    for (final mark in absent) {
      test('$mark is absent from Spectral\'s cmap', () {
        expect(_cmapContains(spectralBytes, mark.runes.first), isFalse);
      });
    }
  });

  group('Plex Mono glyph coverage', () {
    final monoRegularBytes = File('assets/fonts/IBMPlexMono-Regular.ttf')
        .readAsBytesSync();
    final monoSemiBoldBytes = File('assets/fonts/IBMPlexMono-SemiBold.ttf')
        .readAsBytesSync();

    // The crawl marks beyond printable ASCII that the mono role must carry:
    // middle dot, en/em dash, multiplication sign, superscript digits,
    // arrows, dagger, section mark and single guillemet.
    const extraMarks = [
      '·',
      '–',
      '—',
      '×',
      '⁰',
      '¹',
      '²',
      '³',
      '⁴',
      '⁵',
      '⁶',
      '⁷',
      '⁸',
      '⁹',
      '←',
      '→',
      '↓',
      '†',
      '§',
      '›',
    ];

    for (final entry in {
      'Regular': monoRegularBytes,
      'SemiBold': monoSemiBoldBytes,
    }.entries) {
      test(
        '${entry.key} covers every printable ASCII code point and the crawl marks',
        () {
          final missing = <String>[];
          for (var codepoint = 0x20; codepoint <= 0x7E; codepoint++) {
            if (!_cmapContains(entry.value, codepoint)) {
              final hex = codepoint.toRadixString(16).padLeft(4, '0');
              missing.add('U+$hex (${String.fromCharCode(codepoint)})');
            }
          }
          for (final mark in extraMarks) {
            if (!_cmapContains(entry.value, mark.runes.first)) {
              missing.add(mark);
            }
          }
          expect(missing, isEmpty, reason: 'missing glyphs: $missing');
        },
      );
    }
  });

  group('every exported role satisfies the invariants', () {
    const roles = {
      'displayTitle': displayTitle,
      'displayPlace': displayPlace,
      'displayRoom': displayRoom,
      'displayPanel': displayPanel,
      'displayCaption': displayCaption,
      'textHeadline': textHeadline,
      'textAction': textAction,
      'textBody': textBody,
      'textLine': textLine,
      'textLineDim': textLineDim,
      'textLabel': textLabel,
      'textLabelDim': textLabelDim,
      'textLabelStrong': textLabelStrong,
      'textCaption': textCaption,
      'textDetail': textDetail,
      'textDetailDim': textDetailDim,
      'textGlyph': textGlyph,
      'textGlyphDim': textGlyphDim,
      'textMicro': textMicro,
      'textMicroDim': textMicroDim,
      'monoMeta': monoMeta,
      'monoMetaCold': monoMetaCold,
      'monoChip': monoChip,
      'monoData': monoData,
      'monoDataDim': monoDataDim,
      'monoItem': monoItem,
      'monoLog': monoLog,
      'monoLogHostile': monoLogHostile,
      'monoLogCold': monoLogCold,
      'monoLogTorch': monoLogTorch,
      'monoFigure': monoFigure,
      'monoFigureCold': monoFigureCold,
      'monoToken': monoToken,
      'monoTokenHostile': monoTokenHostile,
      'monoSlotMeta': monoSlotMeta,
    };

    for (final entry in roles.entries) {
      final name = entry.key;
      final style = entry.value;
      final isDisplay = name.startsWith('display');
      final isMono = name.startsWith('mono');

      test('$name does not inherit', () {
        expect(style.inherit, isFalse);
      });

      test('$name names its own family', () {
        expect(
          style.fontFamily,
          isDisplay ? displayFace : (isMono ? monoFace : textFace),
        );
      });

      test('$name sets an explicit height', () {
        expect(style.height, isNotNull);
      });

      test('$name sets an explicit textBaseline', () {
        expect(style.textBaseline, isNotNull);
      });

      test('$name sets an explicit color', () {
        expect(style.color, isNotNull);
      });

      test('$name carries the right figure features', () {
        final features = style.fontFeatures ?? const [];
        expect(features, contains(const FontFeature.tabularFigures()));
        if (isDisplay) {
          expect(features, contains(const FontFeature.liningFigures()));
        }
      });
    }
  });

  group('mapGlyphStyle and mapBadgeStyle satisfy the same invariants', () {
    const suppliedInk = Color(0xFF123456);

    for (final entry in {
      'mapGlyphStyle': mapGlyphStyle(suppliedInk),
      'mapBadgeStyle': mapBadgeStyle(suppliedInk),
    }.entries) {
      final name = entry.key;
      final style = entry.value;

      test('$name does not inherit', () {
        expect(style.inherit, isFalse);
      });

      test('$name names the mono family', () {
        expect(style.fontFamily, monoFace);
      });

      test('$name sets an explicit height', () {
        expect(style.height, isNotNull);
      });

      test('$name sets an explicit textBaseline', () {
        expect(style.textBaseline, isNotNull);
      });

      test('$name carries the supplied colour', () {
        expect(style.color, suppliedInk);
      });

      test('$name carries tabular figures', () {
        final features = style.fontFeatures ?? const [];
        expect(features, contains(const FontFeature.tabularFigures()));
      });
    }
  });

  group('the boot failure screen renders no Material 3 default', () {
    testWidgets('the Begin-fresh fill is off the M3 palette', (tester) async {
      final m3 = ThemeData(brightness: Brightness.dark, useMaterial3: true);

      await tester.pumpWidget(
        BootFailureScreen(
          store: SaveStore(MemorySaveFiles()),
          rollWorldSeed: () => 0,
        ),
      );
      await tester.pump();

      final material = tester.widget<Material>(
        find
            .descendant(
              of: find.widgetWithText(FilledButton, 'Begin fresh'),
              matching: find.byType(Material),
            )
            .first,
      );
      final fill = material.color!;

      expect(fill, raised);
      expect(fill, isNot(m3.colorScheme.primary));
    });
  });
}
