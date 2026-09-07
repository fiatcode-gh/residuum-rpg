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
/// a phone's are not the same and neither of them is ours to guess — and when
/// one is injected the class is pure Dart, so it can be verified against a real
/// temp directory without a platform at all.
///
/// **The exception contract is the interface's, and this is where it is kept.**
/// [read] maps every failure — an absent file, an unreadable one, a platform
/// that refuses to name its documents directory — to null, because the caller
/// above is deciding what to do about "absent or unreadable" and must not also
/// have to catch platform exceptions. [write], [rename] and [delete] throw when
/// the disk refuses them; their no-ops are documented on the interface.
class IoSaveFiles implements SaveFiles {
  /// The directory the files live in, or null to fetch it from the platform.
  ///
  /// Injectable so a test can hand in a real `Directory.systemTemp` and drive
  /// every failure the platform can produce; production always passes nothing.
  IoSaveFiles([this._homeOverride]);

  final Directory? _homeOverride;

  Directory? _home;

  @override
  Future<String?> read(String name) async {
    try {
      final file = File(await _path(name));
      if (!file.existsSync()) return null;
      return await file.readAsString();
    } on Object {
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
    final home = _home ??=
        _homeOverride ?? await getApplicationDocumentsDirectory();
    return '${home.path}/$name';
  }
}
