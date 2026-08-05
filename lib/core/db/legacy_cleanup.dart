import 'dart:io';

/// Deletes the old v1 app's local database file (and its SQLite WAL/SHM
/// sidecar files) — now actually invoked from `main.dart` on every
/// startup, since every v1 screen has been removed (this app was new
/// enough that there was no real production data to preserve, so v1 was
/// deleted outright rather than migrated — see `AppDatabase`'s own doc
/// comment in `lib/data/local/app_database.dart`).
///
/// The v1 database's base name, as it was configured in the old (now
/// deleted) `lib/core/database/app_database.dart`'s
/// `driftDatabase(name: 'inventory_db')`. `drift_flutter`'s exact on-disk
/// naming convention (extension, if any) was not independently confirmed
/// against a real device in this environment — [candidateFileNames] is
/// deliberately defensive (checks every plausible extension/sidecar
/// combination) rather than assuming one. Deleting a file that was never
/// there is a no-op, not an error, so over-including candidates here is
/// safe — a device that never had v1 installed just finds nothing to
/// delete, every time, forever. (A one-time "already ran" flag was
/// considered and rejected for exactly that reason: the no-op cost of
/// checking is lower than the complexity of tracking whether it's needed.)
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
