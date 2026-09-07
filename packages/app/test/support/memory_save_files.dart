import 'package:residuum_app/save/save_files.dart';

/// A working file system in a map, so the decisions above the file operations
/// can be tested without a disk.
///
/// Not a mock: it really stores what it is given and really hands it back, and
/// no test asserts on which calls it received. A test that wants a disk to fail
/// names the file in [failWritesTo] or [failReadsTo], which is what a full disk
/// and an unreadable file look like from up here.
class MemorySaveFiles implements SaveFiles {
  final Map<String, String> contents = {};

  /// Names whose writes throw, standing in for a disk that will not take them.
  final Set<String> failWritesTo = {};

  /// Names whose reads come back as nothing, standing in for a file that is
  /// there but cannot be read.
  final Set<String> failReadsTo = {};

  /// Names whose reads throw, standing in for an implementation that does not
  /// honour the "read never throws" contract the interface documents.
  final Set<String> throwReadsTo = {};

  /// Names whose renames throw, standing in for a target the disk will not
  /// take the move onto.
  final Set<String> failRenamesFrom = {};

  @override
  Future<String?> read(String name) async {
    if (throwReadsTo.contains(name)) {
      throw StateError('the file $name could not be read');
    }
    return failReadsTo.contains(name) ? null : contents[name];
  }

  @override
  Future<void> write(String name, String contents) async {
    if (failWritesTo.contains(name)) throw StateError('no room for $name');
    this.contents[name] = contents;
  }

  @override
  Future<void> rename(String from, String to) async {
    if (failRenamesFrom.contains(from)) {
      throw StateError('the disk refused the move onto $to');
    }
    final moved = contents.remove(from);
    if (moved == null) return;
    contents[to] = moved;
  }

  @override
  Future<void> delete(String name) async {
    contents.remove(name);
  }
}
