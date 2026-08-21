/// A save document that cannot be read, raised inside the codec and caught at
/// its edge.
///
/// An exception rather than a returned failure, but only *inside* the codec: a
/// decode is a tree walk twenty levels deep, and threading a failure back up
/// through every level would put a nullable return on every field reader and an
/// early exit at every call site. `decodeSave` catches this and hands back a
/// `SaveFailure`, so nothing throws past the codec's own edge.
class SaveMalformed implements Exception {
  SaveMalformed(this.reason);

  /// Written to be read aloud on the screen, not parsed.
  final String reason;

  @override
  String toString() => 'SaveMalformed($reason)';
}

/// A 64-bit-wide value, written as a quoted string.
///
/// **Seeds and generator states are text; hit points and gold are numbers.** A
/// save file outlives the build that wrote it, and JSON's number is only as wide
/// as whoever reads it decides. On the Dart virtual machine and in ahead-of-time
/// Android builds an `int` is 64-bit and a full-width value does survive as a
/// number — but that is a property of this substrate, not of the format: under
/// `dart2js` an `int` is a double, and so is a number in every tool a person
/// would reach for to look at a save by hand. Writing the wide values as text
/// makes one document mean one thing to every reader.
///
/// [wideAt] accepts nothing but text, which is what makes the format
/// self-enforcing: an encoder that drifted back to numbers could not read its
/// own output, so the drift is a red test rather than a file nobody can open.
String encodeWide(int value) => '$value';

/// The 64-bit-wide value at [key], which must be written as text.
int wideAt(Map<String, Object?> from, String key) {
  final value = _at(from, key);
  if (value is! String) {
    throw SaveMalformed('"$key" must be a quoted whole number and is not');
  }
  final parsed = int.tryParse(value);
  if (parsed == null) throw SaveMalformed('"$key" is not a whole number');
  return parsed;
}

/// The object at [key].
Map<String, Object?> objectAt(Map<String, Object?> from, String key) =>
    _typed<Map<String, Object?>>(from, key, 'an object');

/// The list at [key].
List<Object?> listAt(Map<String, Object?> from, String key) =>
    _typed<List<Object?>>(from, key, 'a list');

/// The counted whole number at [key].
int intAt(Map<String, Object?> from, String key) =>
    _typed<int>(from, key, 'a whole number');

/// The text at [key].
String stringAt(Map<String, Object?> from, String key) =>
    _typed<String>(from, key, 'text');

/// The flag at [key].
bool boolAt(Map<String, Object?> from, String key) =>
    _typed<bool>(from, key, 'true or false');

T _typed<T>(Map<String, Object?> from, String key, String wanted) {
  final value = _at(from, key);
  if (value is! T) throw SaveMalformed('"$key" must be $wanted and is not');
  return value;
}

Object? _at(Map<String, Object?> from, String key) {
  if (!from.containsKey(key)) {
    throw SaveMalformed('the save file is missing "$key"');
  }
  return from[key];
}
