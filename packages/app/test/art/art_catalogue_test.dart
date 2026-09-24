import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:residuum_app/art/art_assets.dart';

const _otherRegions = [
  RegionMaterial.cryptStone,
  RegionMaterial.seaCaveStone,
  RegionMaterial.ruinedKeepMasonry,
];

List<String> _allCataloguePaths() => [
  for (final art in EnvironmentArt.values) art.path,
  for (final art in ActionIcon.values) art.path,
  for (final art in MaterialArt.values) art.path,
  for (final art in TerrainOverlayArt.values) art.path,
];

List<String> _declaredAssetDirectories() {
  final lines = File('pubspec.yaml').readAsLinesSync();
  final declaration = lines.indexWhere((line) => line.trim() == 'assets:');
  final directories = <String>[];
  for (final line in lines.skip(declaration + 1)) {
    final trimmed = line.trim();
    if (!trimmed.startsWith('- ')) break;
    directories.add(trimmed.substring(2));
  }
  return directories;
}

String _normalize(String path) =>
    path.replaceAll(r'\', '/').replaceAll('//', '/');

void main() {
  group('the art catalogue', () {
    test('every catalogue entry names a file that exists', () {
      // arrange
      final paths = _allCataloguePaths();

      // act + assert
      for (final path in paths) {
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    });

    test('every catalogue path is declared once', () {
      // arrange
      final directories = _declaredAssetDirectories();
      final paths = _allCataloguePaths();

      // act
      final undeclared = paths.where(
        (path) => !directories.any(path.startsWith),
      );

      expect(undeclared, isEmpty);
      expect(paths.toSet(), hasLength(paths.length));
    });

    test('the shipped directories carry exactly the catalogue', () {
      // arrange
      final directories = _declaredAssetDirectories();
      final paths = _allCataloguePaths().map(_normalize).toSet();

      // act + assert
      for (final directory in directories) {
        final onDisk = Directory(directory)
            .listSync()
            .whereType<File>()
            .map((file) => _normalize(file.path))
            .toSet();
        final catalogued = paths.where(
          (path) => path.startsWith(_normalize(directory)),
        );
        expect(onDisk, catalogued.toSet(), reason: directory);
      }
    });

    test('masters are not shipped', () async {
      // arrange
      final paths = _allCataloguePaths();
      final images = <String, ui.Image>{};

      // act
      for (final path in paths) {
        final bytes = await File(path).readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        images[path] = frame.image;
      }
      addTearDown(() {
        for (final image in images.values) {
          image.dispose();
        }
      });
      final totalBytes = paths.fold<int>(
        0,
        (sum, path) => sum + File(path).lengthSync(),
      );

      // assert
      for (final entry in images.entries) {
        expect(
          entry.value.width != 1254 || entry.value.height != 1254,
          isTrue,
          reason: entry.key,
        );
      }
      for (final art in EnvironmentArt.values) {
        expect(images[art.path]!.width, 1080, reason: art.path);
        expect(images[art.path]!.height, 432, reason: art.path);
      }
      for (final art in MaterialArt.values) {
        expect(images[art.path]!.width, 576, reason: art.path);
        expect(images[art.path]!.height, 576, reason: art.path);
      }
      for (final art in TerrainOverlayArt.values) {
        expect(images[art.path]!.width, 144, reason: art.path);
        expect(images[art.path]!.height, 144, reason: art.path);
      }
      for (final art in ActionIcon.values) {
        expect(images[art.path]!.width, 72, reason: art.path);
        expect(images[art.path]!.height, 72, reason: art.path);
      }
      expect(totalBytes, lessThan(8 * 1024 * 1024));
      expect(paths.any((path) => path.contains('DNG-')), isFalse);
      expect(paths.any((path) => path.contains('UI-P0-')), isFalse);
    });

    test('no icon exists for melee or back', () {
      // act
      final names = ActionIcon.values.map((icon) => icon.name).toSet();

      // assert
      expect(ActionIcon.values, hasLength(8));
      expect(names.contains('melee'), isFalse);
      expect(names.contains('back'), isFalse);
    });

    test('forSpell matches exactly and only firebolt and mend', () {
      // act + assert
      expect(ActionIcon.forSpell('firebolt'), ActionIcon.firebolt);
      expect(ActionIcon.forSpell('mend'), ActionIcon.mend);
      for (final spellId in [
        'frost-lance',
        'ward',
        'bind',
        'banish',
        'not-a-spell',
      ]) {
        expect(ActionIcon.forSpell(spellId), isNull, reason: spellId);
      }
    });

    test('the road has no authored material', () {
      // act + assert — the road itself
      for (final surface in MaterialSurface.values) {
        expect(MaterialArt.of(RegionMaterial.lowlandRoad, surface), isNull);
      }
      for (final kind in OverlayKind.values) {
        expect(TerrainOverlayArt.of(RegionMaterial.lowlandRoad, kind), isNull);
      }

      // act + assert — every other region carries every combination
      for (final region in _otherRegions) {
        for (final surface in MaterialSurface.values) {
          expect(
            MaterialArt.of(region, surface),
            isNotNull,
            reason: '$region $surface',
          );
        }
        for (final kind in OverlayKind.values) {
          expect(
            TerrainOverlayArt.of(region, kind),
            isNotNull,
            reason: '$region $kind',
          );
        }
      }
    });
  });
}
