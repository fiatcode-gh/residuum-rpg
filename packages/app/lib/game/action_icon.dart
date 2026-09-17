import 'package:flutter/material.dart';

import '../art/art_assets.dart';

/// The side length every action icon renders at, on the crawl control row
/// and on the battle shelf alike.
const double actionIconSize = 18;

/// One action icon, untinted, at [actionIconSize].
///
/// Deliberately `Image.asset`, never `ImageIcon`: the shipped icons are
/// multitone masters, and `ImageIcon` would replace every pixel with the
/// surrounding `IconTheme` colour and reduce them to a silhouette.
/// `excludeFromSemantics: true` keeps the image out of the semantics tree;
/// the label beside this widget carries the announcement instead.
class ActionIconImage extends StatelessWidget {
  const ActionIconImage(this.icon, {super.key});

  final ActionIcon icon;

  @override
  Widget build(BuildContext context) => Image.asset(
    icon.path,
    width: actionIconSize,
    height: actionIconSize,
    filterQuality: FilterQuality.medium,
    excludeFromSemantics: true,
  );
}
