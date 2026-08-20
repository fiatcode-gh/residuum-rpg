import 'package:residuum_core/core.dart';

/// The single hand-authored floor of Milestone 1.
///
/// Two rooms, each seven by ten, joined by a four-tile corridor on row five.
/// The corridor is the tactical point of the floor: it is the only place the
/// hero can meet the ghouls one at a time.
const String firstFloorAscii = '''
####################
#.......####.......#
#.......####.......#
#.......####.......#
#.......####.......#
#..................#
#.......####.......#
#.......####.......#
#.......####.......#
#.......####.......#
#.......####.......#
####################''';

/// Where the hero starts: the far corner of the west room.
const Position heroSpawn = Position(2, 9);

/// Where the three ghouls wait, all in the east room and all out of sight.
const List<Position> ghoulSpawns = [
  Position(13, 2),
  Position(17, 3),
  Position(15, 5),
];
