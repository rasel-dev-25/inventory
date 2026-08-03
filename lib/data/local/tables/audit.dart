import 'package:drift/drift.dart';

import 'shared.dart';

/// "Who changed the selling price?" — an external review's suggestion,
/// justified here by the fact this is a financial app with staff accounts
/// (see the owner/staff permission split in the working plan). Append-only,
/// same reasoning as the ledger tables.
///
/// [oldValue]/[newValue] are JSON-encoded snapshots of the changed row,
/// not individual field diffs — simpler to write correctly, and sufficient
/// for "what did this look like before/after", which is the actual
/// question an owner asks.
///
/// **Needs a retention policy before this ships to real users** (tracked
/// as an M4 task) — on a phone, an unbounded audit log is the single
/// fastest-growing table in the database.
class AuditLogEntries extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text().references(Shops, #id)();
  TextColumn get userId => text().nullable()();
  TextColumn get deviceId => text().nullable()();

  TextColumn get action => text()(); // 'insert' | 'update' | 'delete'
  // Named changedTableName, not tableName: Drift tables have their own
  // `tableName` override slot for customizing the underlying SQL table
  // name, and a column literally named `tableName` collides with that
  // convention (drift_dev warns about exactly this).
  TextColumn get changedTableName => text()();
  TextColumn get recordId => text()();
  TextColumn get oldValueJson => text().nullable()();
  TextColumn get newValueJson => text().nullable()();

  DateTimeColumn get timestamp => dateTime()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
