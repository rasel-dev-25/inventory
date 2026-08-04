import 'package:drift/drift.dart';

import '../../../domain/entities/enums.dart';
import 'shared.dart';

/// Per `notes/business_logic.md` §Expense: "এই খরচ বেচা-কেনা থেকে আসা ক্যাশ
/// থেকেই দেওয়া হয়" — every expense here reduces Total Cash directly and
/// never draws from a specific investor's fund. Mirrored into
/// [CashLedgerEntries] as an outflow when recorded.
@DataClassName('ExpenseRow')
class Expenses extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text().references(Shops, #id)();
  TextColumn get category => textEnum<ExpenseCategory>()();
  IntColumn get amountMinor => integer()();
  DateTimeColumn get date => dateTime()();
  TextColumn get description => text().nullable()();
  TextColumn get paymentMethod => textEnum<PaymentMethod>()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
