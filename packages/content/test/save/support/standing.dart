import 'package:residuum_content/content.dart';
import 'package:residuum_core/core.dart';

/// A hero standing at the crypt, having walked there from home.
///
/// The state any hero inside a crawl must be in: the codec refuses a hero who
/// is "inside" a dungeon while standing in a town, because there is no dungeon
/// under a town to be inside of. Arriving uncovers only the place arrived at,
/// so this hero still knows nothing of the second town.
Whereabouts atTheCrypt() =>
    newWhereabouts().arrivingAt(residuumWorld, cryptNode);

/// A hero standing at the second town, which they had to hear of to reach.
Whereabouts atNorthgate() =>
    newWhereabouts().hearingOf(northgate).arrivingAt(residuumWorld, northgate);
