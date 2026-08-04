import 'dart:io';

/// Deletes the v1 app's local database file (and its SQLite WAL/SHM
/// sidecar files) once v1 screens are fully retired.
///
/// **Not yet called from app startup.** v1 screens still read and write
/// this exact file during the M1–M3 transition — deleting it now would
/// destroy data still in active use. The call site for this function
/// belongs in the PR that removes the last v1 screen, not this one. See
/// `AppDatabaseV2`'s doc comment in `lib/data/local/app_database.dart` for
/// the same note from the other side.
///
/// The v1 database's base name, as configured in the old
/// `lib/core/database/app_database.dart`'s
/// `driftDatabase(name: 'inventory_db')`. `drift_flutter`'s exact on-disk
/// naming convention (extension, if any) was not independently confirmed
/// against a real device in this environment — [candidateFileNames] is
/// deliberately defensive (checks every plausible extension/sidecar
/// combination) rather than assuming one. Deleting a file that was never
/// there is a no-op, not an error, so over-including candidates here is
/// safe.
abstract final class LegacyDatabaseCleanup {
  static const legacyDatabaseBaseName = 'inventory_db';

  /// Every filename this cleanup will attempt to delete from a given
  /// directory, given the uncertainty noted above about the exact
  /// extension drift_flutter used on disk.
  static List<String> candidateFileNames({
    String baseName = legacyDatabaseBaseName,
  }) {
    const suffixes = [
      '',
      '.sqlite',
      '.sqlite-wal',
      '.sqlite-shm',
      '.db',
      '.db-wal',
      '.db-shm',
    ];
    return [for (final suffix in suffixes) '$baseName$suffix'];
  }

  /// Deletes every candidate legacy file found directly inside
  /// [directory]. Returns the list of paths actually deleted, so the
  /// caller can log what happened rather than deleting silently.
  static Future<List<String>> deleteFrom(
    Directory directory, {
    String baseName = legacyDatabaseBaseName,
  }) async {
    final deleted = <String>[];
    for (final name in candidateFileNames(baseName: baseName)) {
      final file = File('${directory.path}/$name');
      if (await file.exists()) {
        await file.delete();
        deleted.add(file.path);
      }
    }
    return deleted;
  }
}
