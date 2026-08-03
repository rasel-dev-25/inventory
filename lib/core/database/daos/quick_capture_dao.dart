import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tables.dart';

part 'quick_capture_dao.g.dart';

@DriftAccessor(tables: [QuickCaptures])
class QuickCaptureDao extends DatabaseAccessor<AppDatabase> with _$QuickCaptureDaoMixin {
  QuickCaptureDao(super.db);

  Future<List<QuickCapture>> getAll() {
    return (select(quickCaptures)
      ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
    ).get();
  }

  Stream<List<QuickCapture>> watchAll() {
    return (select(quickCaptures)
      ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
    ).watch();
  }

  Future<void> insertCapture(QuickCapturesCompanion entry) =>
      into(quickCaptures).insert(entry);

  Future<void> deleteCapture(String id) {
    return (delete(quickCaptures)..where((t) => t.id.equals(id))).go();
  }

  Future<void> deleteAll() => delete(quickCaptures).go();
}
