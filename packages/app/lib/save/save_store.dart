import 'package:residuum_content/content.dart';

import 'save_files.dart';

/// What booting found on disk, and what to tell the player about it.
class LoadedSave {
  const LoadedSave({this.document, this.report});

  /// The save to play from, or null when there is nothing readable.
  final SaveDocument? document;

  /// What went wrong on the way here, in a sentence, or null when nothing did.
  final String? report;
}

/// The two save slots, and the rules for moving between them.
///
/// Every decision here is a decision about the order of [SaveFiles] calls, so
/// the whole class is testable against a map standing in for a disk. The real
/// file system appears only in the adapter handed to the constructor.
class SaveStore {
  const SaveStore(this._files);

  final SaveFiles _files;

  /// Writes the whole [roster], answering whether the save landed.
  ///
  /// The whole document every time, never one hero's slice of it. A save layer
  /// that patched a single entry in place would have to know the file's byte
  /// layout, and the moment it was wrong it would leave a document that decodes
  /// but describes a hero nobody has.
  ///
  /// **Verify then rotate, never rotate then write.** The new document goes to a
  /// pending file and is read back before either real slot is touched, so a
  /// write that dies half-way — no room left, the process killed, the bytes
  /// short — has damaged nothing and both existing slots still hold what they
  /// held. Rotating first would mean the moment a save is most likely to fail is
  /// also the moment the game is holding only one good copy, which is exactly
  /// backwards. The window that remains is between the two renames, where the
  /// current slot is briefly absent and the previous slot holds the last good
  /// save; the load chain reads that as a fallback and loses nothing.
  ///
  /// **Both renames are inside the failure handling.** The rotate is the part
  /// of a save most exposed to the disk — a locked target, a full volume — and
  /// a rename that threw used to escape as a crash, contradicting everything
  /// this dartdoc promises. Any failure anywhere in the write, the read-back or
  /// either rename forgets the pending slot and answers false: the save did
  /// not land, the previous slots stand exactly as they were, and the caller
  /// is the one who decides what the player is told.
  Future<bool> save(SaveDocument roster) async {
    final document = encodeSave(roster);
    try {
      await _files.write(pendingSlot, document);
      if (await _files.read(pendingSlot) != document) {
        await _forget(pendingSlot);
        return false;
      }
      await _files.rename(currentSlot, previousSlot);
      await _files.rename(pendingSlot, currentSlot);
      return true;
    } on Object {
      await _forget(pendingSlot);
      return false;
    }
  }

  /// The best readable save, and what had to be given up to reach it.
  ///
  /// Current, then previous, then nothing. A step down is always reported, and a
  /// fresh install is not a step down: nothing was lost, so nothing is said.
  Future<LoadedSave> load() async {
    if (await _readable(currentSlot) case final SaveDocument document) {
      return LoadedSave(document: document);
    }
    final somethingWasThere =
        await _hasContent(currentSlot) || await _hasContent(previousSlot);
    if (await _readable(previousSlot) case final SaveDocument document) {
      return LoadedSave(
        document: document,
        report: 'your last save could not be read; an older one was restored',
      );
    }
    return LoadedSave(
      report: somethingWasThere
          ? 'your last save could not be read; a new hero begins'
          : null,
    );
  }

  /// Whether a file with [slot]'s name stands on the disk, unreadable or not.
  ///
  /// [read] never throws by contract, and this is what makes that contract
  /// honest in the other direction: an implementation that throws anyway is
  /// describing a file that is *there* — unreadable is not absent — so the
  /// fallback chain treats it as content and says what it gave up.
  Future<bool> _hasContent(String slot) async {
    try {
      return await _files.read(slot) != null;
    } on Object {
      return true;
    }
  }

  Future<SaveDocument?> _readable(String slot) async {
    final String? written;
    try {
      written = await _files.read(slot);
    } on Object {
      return null;
    }
    if (written == null) return null;
    return switch (decodeSave(written)) {
      SaveDocument document => document,
      SaveFailure() => null,
    };
  }

  Future<void> _forget(String slot) async {
    try {
      await _files.delete(slot);
    } on Object {
      return;
    }
  }
}
