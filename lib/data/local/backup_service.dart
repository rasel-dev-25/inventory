import 'package:drift/drift.dart';

import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import 'app_database.dart';

/// One table's worth of backup plumbing, expressed as closures rather than
/// a generic class parameterized over that table's `TableInfo`/row types —
/// Dart can't hold a `List` of `_TableSpec<T1, D1>` and `_TableSpec<T2,
/// D2>` side by side for different `T`/`D`, but a `List<_TableSpec>` of
/// non-generic closures (each one internally, locally generic where it's
/// actually called) works fine and reads just as plainly at the call
/// site below.
class _TableSpec {
  final String key;
  final Future<List<Map<String, dynamic>>> Function() export;
  final Future<void> Function() deleteAll;
  final Future<void> Function(List<Map<String, dynamic>> rows) insertAll;

  const _TableSpec({
    required this.key,
    required this.export,
    required this.deleteAll,
    required this.insertAll,
  });
}

/// Whole-database JSON backup + crash-safe restore for [AppDatabase].
///
/// **"Crash-safe" is the specific improvement over v1's `DataService`**:
/// that importer ran a sequence of separate `await _db.delete(...).go()`
/// calls followed by a *separate* `_db.batch(...)` — if the app were
/// killed between those, the database was left completely empty with no
/// way back. [restoreFromBackup] wraps every delete and every insert for
/// every table in one [AppDatabase.transaction] — either the entire
/// restore lands, or (a crash, an exception, anything) none of it does
/// and the database is exactly as it was before the attempt.
///
/// **Scope, deliberately**: every genuine business table
/// (`Categories` … `AuditLogEntries` — the same set
/// `SyncTableRegistry.syncableTables` names, plus `AppSettings`, which
/// doesn't sync but is still real local business configuration worth
/// backing up). Deliberately excludes `Shops` (identity, not data to
/// overwrite) and the three `Sync*` bookkeeping tables (outbox/cursor
/// machinery, not business data — restoring stale outbox entries could
/// cause duplicate pushes). This is a **single-device safety net**
/// (reinstalling the app, recovering from local corruption), not a
/// cross-device migration tool or a substitute for the real Supabase
/// sync — restored rows are not re-enqueued to the outbox.
///
/// Every table round-trips through its own generated `toJson`/`fromJson`
/// (every Drift-generated row class has both by default) rather than a
/// hand-written field-by-field mapping per table — the exact thing that
/// made v1's importer four hundred lines of `FooCompanion.insert(id:
/// m['id']?.toString() ?? '', ...)` repeated per table, and that would
/// silently go stale the next time a v2 table gained a column.
class BackupService {
  final AppDatabase db;

  /// Bumped only if a future backup payload shape is no longer
  /// compatible with the reader below — [restoreFromBackup] rejects any
  /// other version rather than guessing how to interpret it.
  static const currentVersion = 1;

  BackupService(this.db);

  /// Parent tables first — every table here is inserted in this order on
  /// restore, and the tables list is walked in *reverse* for the
  /// pre-restore delete pass, so a child table's rows are always gone
  /// before its parent, and always re-inserted after its parent. See the
  /// class doc comment for why order matters at all (this schema runs
  /// with SQLite foreign-key enforcement on).
  List<_TableSpec> get _tables => [
    _spec('categories', db.categories, CategoryRow.fromJson, (r) => r.toJson()),
    _spec('units', db.units, UnitRow.fromJson, (r) => r.toJson()),
    _spec(
      'app_settings',
      db.appSettings,
      AppSettingRow.fromJson,
      (r) => r.toJson(),
    ),
    _spec('customers', db.customers, CustomerRow.fromJson, (r) => r.toJson()),
    _spec(
      'customer_images',
      db.customerImages,
      CustomerImageRow.fromJson,
      (r) => r.toJson(),
    ),
    _spec('investors', db.investors, InvestorRow.fromJson, (r) => r.toJson()),
    _spec('products', db.products, ProductRow.fromJson, (r) => r.toJson()),
    _spec(
      'product_images',
      db.productImages,
      ProductImageRow.fromJson,
      (r) => r.toJson(),
    ),
    _spec(
      'investor_repayments',
      db.investorRepayments,
      InvestorRepaymentRow.fromJson,
      (r) => r.toJson(),
    ),
    _spec(
      'legacy_settlements',
      db.legacySettlements,
      LegacySettlementRow.fromJson,
      (r) => r.toJson(),
    ),
    _spec(
      'purchase_trips',
      db.purchaseTrips,
      PurchaseTripRow.fromJson,
      (r) => r.toJson(),
    ),
    _spec(
      'rent_pricing_tiers',
      db.rentPricingTiers,
      RentPricingTierRow.fromJson,
      (r) => r.toJson(),
    ),
    _spec(
      'quick_captures',
      db.quickCaptures,
      QuickCaptureRow.fromJson,
      (r) => r.toJson(),
    ),
    _spec(
      'cash_ledger_entries',
      db.cashLedgerEntries,
      CashLedgerEntryRow.fromJson,
      (r) => r.toJson(),
    ),
    _spec(
      'audit_log_entries',
      db.auditLogEntries,
      AuditLogEntryRow.fromJson,
      (r) => r.toJson(),
    ),
    _spec('expenses', db.expenses, ExpenseRow.fromJson, (r) => r.toJson()),
    _spec('dues', db.dues, DueRow.fromJson, (r) => r.toJson()),
    _spec('orders', db.orders, OrderRow.fromJson, (r) => r.toJson()),
    _spec(
      'fixed_assets',
      db.fixedAssets,
      FixedAssetRow.fromJson,
      (r) => r.toJson(),
    ),
    _spec(
      'fixed_asset_images',
      db.fixedAssetImages,
      FixedAssetImageRow.fromJson,
      (r) => r.toJson(),
    ),
    _spec(
      'purchase_items',
      db.purchaseItems,
      PurchaseItemRow.fromJson,
      (r) => r.toJson(),
    ),
    _spec(
      'purchase_other_costs',
      db.purchaseOtherCosts,
      PurchaseOtherCostRow.fromJson,
      (r) => r.toJson(),
    ),
    _spec('sales', db.sales, SaleRow.fromJson, (r) => r.toJson()),
    _spec(
      'due_payments',
      db.duePayments,
      DuePaymentRow.fromJson,
      (r) => r.toJson(),
    ),
    _spec(
      'stock_movements',
      db.stockMovements,
      StockMovementRow.fromJson,
      (r) => r.toJson(),
    ),
    _spec(
      'rent_transactions',
      db.rentTransactions,
      RentTransactionRow.fromJson,
      (r) => r.toJson(),
    ),
  ];

  _TableSpec _spec<T extends Table, D extends Insertable<D>>(
    String key,
    TableInfo<T, D> table,
    D Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic> Function(D) toJson,
  ) {
    return _TableSpec(
      key: key,
      export: () async {
        final rows = await db.select(table).get();
        return rows.map(toJson).toList();
      },
      deleteAll: () async {
        await db.delete(table).go();
      },
      insertAll: (rows) async {
        if (rows.isEmpty) return;
        final parsed = rows.map(fromJson).toList();
        await db.batch((b) => b.insertAll(table, parsed));
      },
    );
  }

  /// Builds the full backup payload — every table listed in [_tables], in
  /// order, plus a version marker and a timestamp. Callers write this to
  /// a file (see `BackupController`); this method itself does no file
  /// I/O, matching every other data-layer class that stays testable
  /// without a real filesystem.
  Future<Map<String, dynamic>> buildBackupPayload() async {
    final tables = <String, List<Map<String, dynamic>>>{};
    for (final spec in _tables) {
      tables[spec.key] = await spec.export();
    }
    return {
      'version': currentVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'tables': tables,
    };
  }

  /// Restores every table in [payload] atomically — see the class doc
  /// comment for exactly what "atomically" buys here. Rejects a payload
  /// with an unrecognized [currentVersion] or a missing `tables` map
  /// rather than guessing; does not otherwise validate row shape beyond
  /// whatever `fromJson` itself already throws on.
  Future<Result<void>> restoreFromBackup(Map<String, dynamic> payload) async {
    final version = payload['version'];
    if (version != currentVersion) {
      return Result.err(
        ValidationFailure(
          'version',
          'Unrecognized backup version: $version (expected $currentVersion)',
        ),
      );
    }
    final tables = payload['tables'];
    if (tables is! Map) {
      return const Result.err(
        ValidationFailure(
          'tables',
          'Backup payload is missing its "tables" map',
        ),
      );
    }
    final tablesMap = tables.cast<String, dynamic>();

    try {
      await db.transaction(() async {
        // Children first, so a delete never trips a still-present
        // foreign key pointing at a parent row about to be deleted too.
        for (final spec in _tables.reversed) {
          await spec.deleteAll();
        }
        // Parents first, mirroring the delete pass in reverse, so every
        // foreign key a child row about to be inserted needs already
        // exists.
        for (final spec in _tables) {
          final raw = tablesMap[spec.key];
          if (raw is! List) continue;
          await spec.insertAll(raw.cast<Map<String, dynamic>>());
        }
      });
      return const Result.ok(null);
    } catch (e, stackTrace) {
      return Result.err(UnknownFailure(e, stackTrace: stackTrace));
    }
  }
}
