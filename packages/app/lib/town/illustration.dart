import 'package:flutter/material.dart';

import '../art/art_assets.dart';

const townIllustrationKey = Key('town-illustration');
const forgeIllustrationKey = Key('forge-illustration');
const tavernIllustrationKey = Key('tavern-illustration');

const double townIllustrationHeight = 140;
const double roomIllustrationHeight = 120;

/// A cropped, authored environment band: atmosphere, never information.
///
/// [ExcludeSemantics] is the outermost widget because this carries no text
/// meaning of its own — the town's name, status and doors already say
/// everything a screen reader needs. `errorBuilder` leaves a hole rather than
/// a red error widget, because a missing or corrupt asset is production
/// error semantics, not a test accommodation.
class Illustration extends StatelessWidget {
  const Illustration(this.art, {required this.height, super.key});

  final EnvironmentArt art;
  final double height;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Image.asset(
            art.path,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            excludeFromSemantics: true,
            errorBuilder: (_, _, _) => const SizedBox.expand(),
          ),
        ),
      ),
    ),
  );
}
