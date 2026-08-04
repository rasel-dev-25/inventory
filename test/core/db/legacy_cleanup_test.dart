import 'dart:io';

import 'package:test/test.dart';
import 'package:verify_core/core/db/legacy_cleanup.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('legacy_cleanup_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('deletes the base file when present', () async {
    final file = File('${tempDir.path}/inventory_db');
    await file.writeAsString('fake sqlite data');

    final deleted = await LegacyDatabaseCleanup.deleteFrom(tempDir);

    expect(await file.exists(), isFalse);
    expect(deleted, contains(file.path));
  });

  test('deletes every WAL/SHM sidecar variant that exists', () async {
    final files = [
      File('${tempDir.path}/inventory_db.sqlite'),
      File('${tempDir.path}/inventory_db.sqlite-wal'),
      File('${tempDir.path}/inventory_db.sqlite-shm'),
    ];
    for (final f in files) {
      await f.writeAsString('fake');
    }

    final deleted = await LegacyDatabaseCleanup.deleteFrom(tempDir);

    for (final f in files) {
      expect(await f.exists(), isFalse);
    }
    expect(deleted, hasLength(3));
  });

  test('is a no-op, not an error, when nothing exists', () async {
    final deleted = await LegacyDatabaseCleanup.deleteFrom(tempDir);
    expect(deleted, isEmpty);
  });

  test('does not touch unrelated files in the same directory', () async {
    final unrelated = File('${tempDir.path}/some_other_file.txt');
    await unrelated.writeAsString('do not touch me');

    await LegacyDatabaseCleanup.deleteFrom(tempDir);

    expect(await unrelated.exists(), isTrue);
  });

  test('supports a custom base name for testing/flexibility', () async {
    final file = File('${tempDir.path}/custom_name.db');
    await file.writeAsString('fake');

    final deleted = await LegacyDatabaseCleanup.deleteFrom(
      tempDir,
      baseName: 'custom_name',
    );

    expect(await file.exists(), isFalse);
    expect(deleted, contains(file.path));
  });
}
