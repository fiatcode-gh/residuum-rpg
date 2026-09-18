import 'package:flutter/material.dart';

import '../style/tokens.dart';
import 'crawl_style.dart';

/// One tappable crawl surface for every affordance that is not an action
/// chip: a hairline-bordered [Material] with its own [InkWell], so the ink
/// response lands on the pill rather than on whatever sits behind it.
///
/// `icon == null` draws [label] as the word; otherwise the word is the
/// semantic label only and a [crawlTapTarget] square holds [icon] instead.
class CrawlPill extends StatelessWidget {
  const CrawlPill({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final fill = enabled ? crawlRaised : crawlRecessed;
    final child = icon == null
        ? ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: crawlGutter,
                vertical: 8,
              ),
              child: Center(
                child: Text(label, style: enabled ? crawlBody : crawlBodyDim),
              ),
            ),
          )
        : SizedBox(
            width: crawlTapTarget,
            height: crawlTapTarget,
            child: Icon(icon),
          );
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      onTap: onPressed,
      child: ExcludeSemantics(
        child: Material(
          color: fill,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: crawlRule, width: crawlHairline),
            borderRadius: BorderRadius.circular(crawlRadius),
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(crawlRadius),
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
      color: crawlPanel,
      borderRadius: BorderRadius.circular(crawlRadius),
      border: Border.all(color: crawlRule, width: crawlHairline),
    ),
    child: child,
  );
}

/// A region caption — `NOW`, `NEXT`, `MESSAGE LOG` — never per-entry prose.
class CrawlRegionLabel extends StatelessWidget {
  const CrawlRegionLabel(this.word, {super.key});

  final String word;

  @override
  Widget build(BuildContext context) => Text(word, style: crawlRegionLabel);
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
        padding: const EdgeInsets.all(crawlGutter + crawlRhythm),
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
          padding: const EdgeInsets.all(crawlGutter + crawlRhythm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: crawlPanelTitle),
              const SizedBox(height: crawlRhythm * 2),
              Text(body, style: crawlLine),
              const SizedBox(height: crawlRhythm * 3),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: crawlChipSpacing,
                runSpacing: crawlChipRunSpacing,
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
