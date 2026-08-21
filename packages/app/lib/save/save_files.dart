/// The file the game is playing from.
const String currentSlot = 'save.json';

/// The file the game falls back to when the current one cannot be read.
const String previousSlot = 'save-previous.json';

/// Where a save is written before it is allowed to become the current one.
const String pendingSlot = 'save.json.tmp';

/// The four things storage does to files, named so the decisions above them can
/// be tested without a disk.
///
/// The seam is here and not lower down because every interesting question about
/// saving — which slot wins, what happens when a write dies half-way, what the
/// player is told — is a question about the order of these four calls rather
/// than about any one of them. Splitting them out leaves the real edge small
/// enough to check by running the game once on a device.
abstract interface class SaveFiles {
  /// The contents of [name], or null when it is absent or unreadable.
  Future<String?> read(String name);

  /// Puts [contents] in [name], replacing whatever was there.
  Future<void> write(String name, String contents);

  /// Moves [from] onto [to]. Does nothing when [from] is absent.
  Future<void> rename(String from, String to);

  /// Removes [name]. Does nothing when it is already gone.
  Future<void> delete(String name);
}
