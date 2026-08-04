import 'package:drift/drift.dart';

import '../../../domain/entities/enums.dart';
import 'customers.dart';
import 'products.dart';
import 'shared.dart';

/// Mirrors `domain/entities/sale.dart`'s [Sale] — see that file for why
/// [costPriceMinorAtSale] is copied at sale time rather than looked up
/// live from [Products].
@DataClassName('SaleRow')
class Sales extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text().references(Shops, #id)();
  TextColumn get productId => text().references(Products, #id)();

  RealColumn get qty => real()();
  IntColumn get actualSellPriceMinor => integer()();
  IntColumn get costPriceMinorAtSale => integer()();

  DateTimeColumn get date => dateTime()();
  TextColumn get customerId => text().nullable().references(Customers, #id)();
  TextColumn get paymentStatus => textEnum<PaymentStatus>()();
  TextColumn get paymentMethod => textEnum<PaymentMethod>()();

  TextColumn get fundSourceType => textEnum<FundSourceType>()();
  TextColumn get fundSourceInvestorId => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
