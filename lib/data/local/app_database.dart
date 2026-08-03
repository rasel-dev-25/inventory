import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

// Dart imports are not transitive: the generated database.g.dart part file
// shares this file's import scope, not each table file's — so every enum
// used as a textEnum<T>() type argument anywhere in tables/*.dart must also
// be imported directly here, or codegen produces a part file that
// references an undefined type.
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

part 'database.g.dart';

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
)
/// The v2 local Drift database — a clean-slate schema (schemaVersion 1),
/// not a migration path from the v1 app's database. Per the working plan's
/// "clean schema reset" decision, the old `inventory_db` file is deleted
/// on first launch of a v2 build rather than migrated (see the app-startup
/// wiring, next PR).
///
/// This PR defines the schema only — every table declared in
/// `lib/data/local/tables/`, verified against real Drift codegen and a
/// runtime smoke test against an in-memory SQLite database (including
/// actual foreign-key enforcement). DAOs, repositories, and the onCreate
/// seed migration are the next PR's scope; this class deliberately has no
/// `daos: [...]` yet.
///
/// See `lib/data/local/tables/ledger.dart` and `tables/audit.dart` for the
/// append-only-vs-maintained-cache design rules that run through this
/// schema, and ARCHITECTURE.md for why they exist.
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// For unit/integration tests — accepts any [QueryExecutor], most often
  /// an in-memory `NativeDatabase`, so tests never touch a real file.
  AppDatabase.forTesting(super.executor);

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'al_ashab_v2');
  }

  @override
  int get schemaVersion => 1;
}
