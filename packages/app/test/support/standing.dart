import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

/// A hero standing at the crypt, having walked there from home.
///
/// Where every hero with a crawl is: the crypt is the only node with a dungeon
/// under it, so it is the only place a crawl can be entered from and the only
/// place a camp can be walked back into. The codec refuses a hero who is
/// "inside" a crawl while standing in a town, because there is nothing under a
/// town to be inside of.
Whereabouts atTheCrypt() =>
    newWhereabouts().arrivingAt(residuumWorld, cryptNode);

/// A hero standing at the second town, which they had to hear of to reach.
Whereabouts atNorthgate() =>
    newWhereabouts().hearingOf(northgate).arrivingAt(residuumWorld, northgate);
