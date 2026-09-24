const String _visualRoot = 'assets/visual/';

enum EnvironmentArt {
  stonebridge('environments/stonebridge.jpg'),
  forge('environments/forge.jpg'),
  tavern('environments/tavern.jpg');

  const EnvironmentArt(this._file);
  final String _file;
  String get path => '$_visualRoot$_file';
}

enum ActionIcon {
  potion('icons/potion.png'),
  pack('icons/pack.png'),
  wait('icons/wait.png'),
  ascend('icons/ascend.png'),
  descend('icons/descend.png'),
  more('icons/more.png'),
  firebolt('icons/firebolt.png'),
  mend('icons/mend.png');

  const ActionIcon(this._file);
  final String _file;
  String get path => '$_visualRoot$_file';

  /// The icon a readied spell carries, or null when no asset matches it
  /// exactly.
  static ActionIcon? forSpell(String spellId) => switch (spellId) {
    'firebolt' => ActionIcon.firebolt,
    'mend' => ActionIcon.mend,
    _ => null,
  };
}

enum RegionMaterial { cryptStone, seaCaveStone, ruinedKeepMasonry, lowlandRoad }

enum MaterialSurface { floor, wall }

enum MaterialArt {
  cryptFloor(
    RegionMaterial.cryptStone,
    MaterialSurface.floor,
    'dungeon/crypt_floor.png',
  ),
  cryptWall(
    RegionMaterial.cryptStone,
    MaterialSurface.wall,
    'dungeon/crypt_wall.png',
  ),
  seaCaveFloor(
    RegionMaterial.seaCaveStone,
    MaterialSurface.floor,
    'dungeon/sea_cave_floor.png',
  ),
  seaCaveWall(
    RegionMaterial.seaCaveStone,
    MaterialSurface.wall,
    'dungeon/sea_cave_wall.png',
  ),
  ruinedKeepFloor(
    RegionMaterial.ruinedKeepMasonry,
    MaterialSurface.floor,
    'dungeon/ruined_keep_floor.png',
  ),
  ruinedKeepWall(
    RegionMaterial.ruinedKeepMasonry,
    MaterialSurface.wall,
    'dungeon/ruined_keep_wall.png',
  );

  const MaterialArt(this.region, this.surface, this._file);
  final RegionMaterial region;
  final MaterialSurface surface;
  final String _file;
  String get path => '$_visualRoot$_file';

  static MaterialArt? of(RegionMaterial region, MaterialSurface surface) {
    for (final entry in values) {
      if (entry.region == region && entry.surface == surface) return entry;
    }
    return null;
  }
}

enum OverlayKind { crackA, crackB, rubbleSmall, rubbleMedium }

enum TerrainOverlayArt {
  cryptCrackA(
    RegionMaterial.cryptStone,
    OverlayKind.crackA,
    'dungeon/crypt_crack_a.png',
  ),
  cryptCrackB(
    RegionMaterial.cryptStone,
    OverlayKind.crackB,
    'dungeon/crypt_crack_b.png',
  ),
  cryptRubbleSmall(
    RegionMaterial.cryptStone,
    OverlayKind.rubbleSmall,
    'dungeon/crypt_rubble_small.png',
  ),
  cryptRubbleMedium(
    RegionMaterial.cryptStone,
    OverlayKind.rubbleMedium,
    'dungeon/crypt_rubble_medium.png',
  ),
  seaCaveCrackA(
    RegionMaterial.seaCaveStone,
    OverlayKind.crackA,
    'dungeon/sea_cave_crack_a.png',
  ),
  seaCaveCrackB(
    RegionMaterial.seaCaveStone,
    OverlayKind.crackB,
    'dungeon/sea_cave_crack_b.png',
  ),
  seaCaveRubbleSmall(
    RegionMaterial.seaCaveStone,
    OverlayKind.rubbleSmall,
    'dungeon/sea_cave_rubble_small.png',
  ),
  seaCaveRubbleMedium(
    RegionMaterial.seaCaveStone,
    OverlayKind.rubbleMedium,
    'dungeon/sea_cave_rubble_medium.png',
  ),
  ruinedKeepCrackA(
    RegionMaterial.ruinedKeepMasonry,
    OverlayKind.crackA,
    'dungeon/ruined_keep_crack_a.png',
  ),
  ruinedKeepCrackB(
    RegionMaterial.ruinedKeepMasonry,
    OverlayKind.crackB,
    'dungeon/ruined_keep_crack_b.png',
  ),
  ruinedKeepRubbleSmall(
    RegionMaterial.ruinedKeepMasonry,
    OverlayKind.rubbleSmall,
    'dungeon/ruined_keep_rubble_small.png',
  ),
  ruinedKeepRubbleMedium(
    RegionMaterial.ruinedKeepMasonry,
    OverlayKind.rubbleMedium,
    'dungeon/ruined_keep_rubble_medium.png',
  );

  const TerrainOverlayArt(this.region, this.kind, this._file);
  final RegionMaterial region;
  final OverlayKind kind;
  final String _file;
  String get path => '$_visualRoot$_file';

  static TerrainOverlayArt? of(RegionMaterial region, OverlayKind kind) {
    for (final entry in values) {
      if (entry.region == region && entry.kind == kind) return entry;
    }
    return null;
  }
}
