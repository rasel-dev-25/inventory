import 'package:drift/drift.dart';

import '../../../core/money/money.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/fund_source.dart';
import '../../../domain/entities/sale.dart' as domain;
import '../app_database.dart';
import '../tables/sales.dart';

part 'sale_dao.g.dart';

extension _SaleRowMapping on SaleRow {
  domain.Sale toDomain() {
    return domain.Sale(
      id: id,
      productId: productId,
      qty: qty,
      actualSellPrice: Money.fromMinor(actualSellPriceMinor),
      costPriceAtSale: Money.fromMinor(costPriceMinorAtSale),
      date: date,
      customerId: customerId,
      paymentStatus: paymentStatus,
      paymentMethod: paymentMethod,
      fundSource: fundSourceType == FundSourceType.shop
          ? FundSource.shop()
          : FundSource.investor(fundSourceInvestorId!),
    );
  }
}

/// Data access for [Sales] — a single-statement insert, unlike
/// [PurchaseDao]'s multi-table transaction, since a sale has no line
/// items of its own. The transaction discipline for "sale + stock
/// movement + cash ledger + due" lives one layer up, in
/// `SaveSaleUseCase`, the same split `ProductDao`/`PurchaseDao` already
/// establish between "the storage primitive" and "the use case that
/// pairs it with everything else that must happen alongside it".
@DriftAccessor(tables: [Sales])
class SaleDao extends DatabaseAccessor<AppDatabase> with _$SaleDaoMixin {
  SaleDao(super.db);

  Future<domain.Sale?> getById(String id) async {
    final row = await (select(
      sales,
    )..where((s) => s.id.equals(id) & s.deletedAt.isNull())).getSingleOrNull();
    return row?.toDomain();
  }

  Stream<List<domain.Sale>> watchRecent(String shopId, {int limit = 50}) {
    final query = select(sales)
      ..where((s) => s.shopId.equals(shopId) & s.deletedAt.isNull())
      ..orderBy([(s) => OrderingTerm.desc(s.date)])
      ..limit(limit);
    return query.watch().map((rows) => rows.map((r) => r.toDomain()).toList());
  }

  /// Every [Sales] row for [shopId], unlimited — [watchRecent] intentionally
  /// caps at [limit] for a scrolling list UI; the v2 Dashboard's totals need
  /// every sale in whatever `DateRange` it's filtering by (day or all-time),
  /// so a capped stream would silently under-count once a shop passes that
  /// limit's worth of history.
  Stream<List<domain.Sale>> watchAll(String shopId) {
    final query = select(sales)
      ..where((s) => s.shopId.equals(shopId) & s.deletedAt.isNull());
    return query.watch().map((rows) => rows.map((r) => r.toDomain()).toList());
  }

  Future<void> create(
    domain.Sale sale, {
    required String shopId,
    required DateTime now,
  }) {
    return into(sales).insert(
      SalesCompanion.insert(
        id: sale.id,
        shopId: shopId,
        productId: sale.productId,
        qty: sale.qty,
        actualSellPriceMinor: sale.actualSellPrice.minorUnits,
        costPriceMinorAtSale: sale.costPriceAtSale.minorUnits,
        date: sale.date,
        customerId: Value(sale.customerId),
        paymentStatus: sale.paymentStatus,
        paymentMethod: sale.paymentMethod,
        fundSourceType: sale.fundSource.type,
        fundSourceInvestorId: Value(sale.fundSource.investorId),
        createdAt: now,
        updatedAt: now,
        syncedAt: now,
      ),
    );
  }
}
