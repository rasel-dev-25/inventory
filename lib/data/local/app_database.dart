import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

// Dart imports are not transitive: the generated app_database.g.dart part
// file shares this file's import scope, not each table file's — so every enum
// used as a textEnum<T>() type argument anywhere in tables/*.dart must also
// be imported directly here, or codegen produces a part file that
// references an undefined type.
import 'daos/category_dao.dart';
import 'daos/customer_dao.dart';
import 'daos/due_dao.dart';
import 'daos/expense_dao.dart';
import 'daos/investor_dao.dart';
import 'daos/ledger_dao.dart';
import 'daos/product_dao.dart';
import 'daos/purchase_dao.dart';
import 'daos/rent_dao.dart';
import 'daos/sale_dao.dart';
import 'daos/sync_metadata_dao.dart';
import 'default_shop.dart';
import '../../domain/entities/enums.dart';
import 'tables/assets.dart';
import 'tables/audit.dart';
import 'tables/customers.dart';
import 'tables/dues.dart';
import 'tables/expenses.dart';
import 'tables/investors.dart';
import 'tables/ledger.dart';
import 'tables/orders.dart';
import 'tables/products.dart';
import 'tables/purchases.dart';
import 'tables/quick_capture.dart';
import 'tables/rent.dart';
import 'tables/sales.dart';
import 'tables/shared.dart';
import 'tables/sync.dart';

part 'app_database.g.dart';

/// The v2 local Drift database — a clean-slate schema (schemaVersion 1),
/// not a migration path from the v1 app's database. Per the working plan's
/// "clean schema reset" decision, the old `inventory_db` file is deleted
/// once v1 screens are fully retired, not migrated — see
/// `lib/core/db/legacy_cleanup.dart` for that (deliberately not yet
/// invoked from app startup; v1 screens still read/write that file).
///
/// Named `AppDatabaseV2`, not `AppDatabase`, for exactly as long as the v1
/// `lib/core/database/app_database.dart` class of the same short name
/// still exists — both must be importable in the same file (`main.dart`)
/// during the transition. Rename back to `AppDatabase` in the PR that
/// deletes the v1 file.
///
/// Every table declared in `lib/data/local/tables/` is verified against
/// real Drift codegen and a runtime smoke test against an in-memory
/// SQLite database (including actual foreign-key enforcement, the
/// onCreate seed, and every DAO below) — see the PR history for
/// `tables/`. DAOs live in `lib/data/local/daos/`, one per aggregate, each
/// returning domain entities (`lib/domain/entities/`) rather than raw
/// generated row classes — see `tables/products.dart` for why every table
/// row class is renamed via `@DataClassName` to avoid colliding with the
/// domain entity of the same conceptual name (Drift's default naming
/// strips the table class's trailing "s", so `Products` would otherwise
/// generate a class literally named `Product`, identical to
/// `lib/domain/entities/product.dart`'s `Product`).
///
/// See `lib/data/local/tables/ledger.dart` and `tables/audit.dart` for the
/// append-only-vs-maintained-cache design rules that run through this
/// schema, and ARCHITECTURE.md for why they exist.
@DriftDatabase(
  tables: [
    Shops,
    Categories,
    AppSettings,
    Products,
    ProductImages,
    Customers,
    Investors,
    InvestorRepayments,
    LegacySettlements,
    PurchaseTrips,
    PurchaseItems,
    PurchaseOtherCosts,
    Sales,
    Dues,
    DuePayments,
    RentPricingTiers,
    RentTransactions,
    Expenses,
    Orders,
    FixedAssets,
    QuickCaptures,
    CashLedgerEntries,
    StockMovements,
    AuditLogEntries,
    SyncOutboxEntries,
    SyncPendingUploads,
    SyncCursors,
  ],
  daos: [
    ProductDao,
    CustomerDao,
    InvestorDao,
    PurchaseDao,
    SyncMetadataDao,
    CategoryDao,
    LedgerDao,
    SaleDao,
    DueDao,
    ExpenseDao,
    RentDao,
  ],
)
class AppDatabaseV2 extends _$AppDatabaseV2 {
  AppDatabaseV2() : super(_openConnection());

  /// For unit/integration tests — accepts any [QueryExecutor], most often
  /// an in-memory `NativeDatabase`, so tests never touch a real file.
  AppDatabaseV2.forTesting(super.executor);

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'al_ashab_v2');
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _seed(this);
    },
  );
}

/// Seeds a brand-new database with the one [Shops] row every other
/// shop-scoped row needs to exist first (see `default_shop.dart`), plus
/// the two spec-driven default row sets: stock categories (matching v1's
/// seed exactly, so nothing about the category list itself regresses) and
/// the book-rental pricing tiers from `notes/business_logic.md`
/// §RentPricingTier — a real, owner-editable table now, not the v1 app's
/// hardcoded, non-configurable formula.
Future<void> _seed(AppDatabaseV2 db) async {
  final now = DateTime.now().toUtc();

  await db
      .into(db.shops)
      .insert(
        ShopsCompanion.insert(
          id: defaultShopId,
          name: 'My Shop',
          createdAt: now,
        ),
      );

  const defaultCategories = [
    'Book',
    'Date',
    'Attar',
    'Topi',
    'Miswak',
    'Other',
  ];
  for (var i = 0; i < defaultCategories.length; i++) {
    await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: 'category-default-$i',
            shopId: defaultShopId,
            name: defaultCategories[i],
            sortOrder: Value(i),
          ),
        );
  }

  // (maxPages, days, priceMinor) — from business_logic.md's tier table:
  // ৫০/৫/৳৫, ১০০/১০/৳১০, ২০০/১৫/৳২০, ৩০০/২০/৳৩০.
  const defaultTiers = [
    (maxPages: 50, days: 5, priceMinor: 500),
    (maxPages: 100, days: 10, priceMinor: 1000),
    (maxPages: 200, days: 15, priceMinor: 2000),
    (maxPages: 300, days: 20, priceMinor: 3000),
  ];
  for (var i = 0; i < defaultTiers.length; i++) {
    final tier = defaultTiers[i];
    await db
        .into(db.rentPricingTiers)
        .insert(
          RentPricingTiersCompanion.insert(
            id: 'rent-tier-default-$i',
            shopId: defaultShopId,
            maxPages: tier.maxPages,
            days: tier.days,
            priceMinor: tier.priceMinor,
            sortOrder: Value(i),
          ),
        );
  }
}
