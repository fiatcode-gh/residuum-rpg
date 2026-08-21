import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'save_files.dart';

/// The real files, in the directory the platform gives the app for its own
/// documents.
///
/// Deliberately the thinnest thing that could work: four calls and no decisions.
/// Every decision lives in [SaveStore], which is tested against a map, so what
/// is left here is small enough to verify by running the game once on a device.
/// The directory is asked for rather than built, because an emulator's path and
/// a phone's are not the same and neither of them is ours to guess.
class IoSaveFiles implements SaveFiles {
  Directory? _home;

  @override
  Future<String?> read(String name) async {
    final file = File(await _path(name));
    try {
      if (!file.existsSync()) return null;
      return await file.readAsString();
    } on FileSystemException {
      return null;
    }
  }

  @override
  Future<void> write(String name, String contents) async {
    final handle = await File(await _path(name)).open(mode: FileMode.writeOnly);
    try {
      await handle.writeString(contents);
      await handle.flush();
    } finally {
      await handle.close();
    }
  }

  @override
  Future<void> rename(String from, String to) async {
    final file = File(await _path(from));
    if (!file.existsSync()) return;
    await file.rename(await _path(to));
  }

  @override
  Future<void> delete(String name) async {
    final file = File(await _path(name));
    if (!file.existsSync()) return;
    await file.delete();
  }

  Future<String> _path(String name) async {
    final home = _home ??= await getApplicationDocumentsDirectory();
    return '${home.path}/$name';
  }
}
