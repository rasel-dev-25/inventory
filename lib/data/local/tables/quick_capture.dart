import 'package:drift/drift.dart';

import '../../../domain/entities/enums.dart';
import 'shared.dart';

/// A quick voice/photo note, per `notes/business_logic.md`'s QuickCapture
/// addition. [convertedToType]/[convertedToId] are only set once triaged
/// into a real Sale/PurchaseTrip/Expense — the v1 schema had no conversion
/// tracking at all (create/list/delete only), so this is new, not a
/// rename of an existing column.
@DataClassName('QuickCaptureRow')
class QuickCaptures extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text().references(Shops, #id)();
  TextColumn get type => textEnum<QuickCaptureType>()();
  TextColumn get fileLocalPath => text()();
  TextColumn get status => textEnum<QuickCaptureStatus>()();

  TextColumn get convertedToType => text().nullable()();
  TextColumn get convertedToId => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
