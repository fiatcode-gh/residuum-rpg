import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../style/tokens.dart';
import 'crawl_style.dart';

/// The confirm dialog's own button spacing — pulled out of `crawl_style.dart`
/// (the crawl chip vocabulary Unit 16.5 retires) since a dialog's stock
/// button row and the action bar's slots never shared a value on purpose.
const double _dialogButtonSpacing = 6;
const double _dialogButtonRunSpacing = 4;

/// One tappable crawl surface for every affordance that is not an action
/// chip: a hairline-bordered [Material] with its own [InkWell], so the ink
/// response lands on the pill rather than on whatever sits behind it.
///
/// `icon == null` draws [label] as the word; otherwise the word is the
/// semantic label only and a [tapTarget] square holds [icon] instead.
class CrawlPill extends StatelessWidget {
  const CrawlPill({
    required this.label,
    required this.onPressed,
    this.icon,
    this.extent = tapTarget,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double extent;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final fill = enabled ? raised : recessed;
    final child = icon == null
        ? ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: gutter,
                vertical: 8,
              ),
              child: Center(
                child: Text(label, style: enabled ? textBody : textLineDim),
              ),
            ),
          )
        : SizedBox(width: extent, height: extent, child: Icon(icon));
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      onTap: onPressed,
      child: ExcludeSemantics(
        child: Material(
          color: fill,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: rule, width: hairline),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(radius),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A hairline-bordered, filled rectangle for grouping crawl content into a
/// region — the timeline, the log peek. Callers supply their own margin so
/// the surrounding column keeps one rhythm decision per slot.
class CrawlPanel extends StatelessWidget {
  const CrawlPanel({
    required this.child,
    this.padding = const EdgeInsets.all(crawlPanelPadding),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: panel,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: rule, width: hairline),
    ),
    child: child,
  );
}

/// Opens a crawl-themed modal bottom sheet: the crawl's own [CrawlPanel]
/// surface, scrollable, over [showModalBottomSheet]'s own top-rounded shape
/// and scrim, both already set on [residuumTheme].
///
/// The explicit [Theme] wrap is deliberate: it removes any dependence on
/// Flutter's `InheritedTheme` capture for root-navigator routes, so the
/// sheet's appearance is correct by construction rather than by ambient luck.
Future<T?> showCrawlSheet<T>(
  BuildContext context, {
  required List<Widget> Function(BuildContext) children,
}) => showModalBottomSheet<T>(
  context: context,
  builder: (sheetContext) => Theme(
    data: residuumTheme,
    child: SafeArea(
      child: CrawlPanel(
        padding: const EdgeInsets.all(gutter + rhythm),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children(sheetContext),
          ),
        ),
      ),
    ),
  ),
);

/// Asks once, over the crawl's own surface, and answers false when dismissed
/// without an answer — a barrier tap, the system back gesture, anything
/// other than [confirm].
Future<bool> showCrawlConfirm(
  BuildContext context, {
  required String title,
  required String body,
  required String dismiss,
  required String confirm,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => Theme(
      data: residuumTheme,
      child: Dialog(
        child: Padding(
          padding: const EdgeInsets.all(gutter + rhythm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: displayPanel),
              const SizedBox(height: rhythm * 2),
              Text(body, style: textLine),
              const SizedBox(height: rhythm * 3),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: _dialogButtonSpacing,
                runSpacing: _dialogButtonRunSpacing,
                children: [
                  CrawlPill(
                    label: dismiss,
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                  ),
                  CrawlPill(
                    label: confirm,
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return confirmed ?? false;
}

Future<T?> showCrawlPopup<T>(
  BuildContext anchorContext, {
  required WidgetBuilder builder,
}) {
  final anchorBox = anchorContext.findRenderObject()! as RenderBox;
  final anchorTopLeft = anchorBox.localToGlobal(Offset.zero);
  final anchorSize = anchorBox.size;
  final screenSize = MediaQuery.sizeOf(anchorContext);
  final safeTop = MediaQuery.paddingOf(anchorContext).top;
  final width = math.min(
    crawlPopupWidth,
    screenSize.width - crawlPopupEdgeMargin * 2,
  );
  final anchorCentre = anchorTopLeft.dx + anchorSize.width / 2;
  final left = (anchorCentre - width / 2).clamp(
    crawlPopupEdgeMargin,
    screenSize.width - crawlPopupEdgeMargin - width,
  );
  final bottomEdge = anchorTopLeft.dy - crawlPopupGap;
  final maxHeight = math.max(0.0, bottomEdge - safeTop - crawlPopupEdgeMargin);
  return showGeneralDialog<T>(
    context: anchorContext,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: const Color(0x00000000),
    transitionDuration: Duration.zero,
    pageBuilder: (dialogContext, _, _) => Stack(
      children: [
        Positioned(
          left: left,
          width: width,
          bottom: screenSize.height - bottomEdge,
          child: Theme(
            data: residuumTheme,
            child: Material(
              type: MaterialType.transparency,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: DecoratedBox(
                  decoration: crawlFrameDecoration,
                  child: Padding(
                    padding: const EdgeInsets.all(crawlPopupPadding),
                    child: SingleChildScrollView(child: builder(dialogContext)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class LeaderPainter extends CustomPainter {
  const LeaderPainter({required this.from, required this.to});

  final Offset from;
  final Offset to;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = crawlGold.withValues(alpha: 0.7)
      ..strokeWidth = crawlCalloutLeaderWidth
      ..style = PaintingStyle.stroke;
    canvas.drawLine(from, to, line);
    final dot = Paint()
      ..color = crawlGold.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(from, crawlCalloutDotRadius, dot);
  }

  @override
  bool shouldRepaint(covariant LeaderPainter oldDelegate) =>
      oldDelegate.from != from || oldDelegate.to != to;
}
