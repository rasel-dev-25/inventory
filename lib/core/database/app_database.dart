import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables/tables.dart';
import 'daos/product_dao.dart';
import 'daos/sale_dao.dart';
import 'daos/customer_dao.dart';
import 'daos/expense_dao.dart';
import 'daos/purchase_dao.dart';
import 'daos/investor_dao.dart';
import 'daos/asset_dao.dart';
import 'daos/rental_dao.dart';
import 'daos/quick_capture_dao.dart';
import 'daos/settings_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Products,
    Sales,
    Customers,
    LedgerEntries,
    CustomerPurchases,
    CustomerOrders,
    Expenses,
    Purchases,
    PurchaseItems,
    TransportCosts,
    OtherCosts,
    Investors,
    Repayments,
    FixedAssets,
    QuickCaptures,
    RentBooks,
    BookRentals,
    Categories,
    CustomerTypes,
    AppSettings,
  ],
  daos: [
    ProductDao,
    SaleDao,
    CustomerDao,
    ExpenseDao,
    PurchaseDao,
    InvestorDao,
    AssetDao,
    RentalDao,
    QuickCaptureDao,
    SettingsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'inventory_db');
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await into(categories).insert(CategoriesCompanion.insert(name: 'Book'));
      await into(categories).insert(CategoriesCompanion.insert(name: 'Date'));
      await into(categories).insert(CategoriesCompanion.insert(name: 'Attar'));
      await into(categories).insert(CategoriesCompanion.insert(name: 'Topi'));
      await into(categories).insert(CategoriesCompanion.insert(name: 'Miswak'));
      await into(categories).insert(CategoriesCompanion.insert(name: 'Other'));
      await into(customerTypes).insert(
        CustomerTypesCompanion.insert(
          id: 'buyer',
          label: 'Buyers',
          iconIndex: const Value(4),
        ),
      );
      await into(customerTypes).insert(
        CustomerTypesCompanion.insert(
          id: 'order_giver',
          label: 'Order Givers',
          iconIndex: const Value(5),
        ),
      );
      await into(customerTypes).insert(
        CustomerTypesCompanion.insert(
          id: 'renter',
          label: 'Renters',
          iconIndex: const Value(3),
        ),
      );
      await into(customerTypes).insert(
        CustomerTypesCompanion.insert(
          id: 'due_taker',
          label: 'Due Takers',
          iconIndex: const Value(6),
        ),
      );
      await into(customerTypes).insert(
        CustomerTypesCompanion.insert(
          id: 'prospective',
          label: 'Prospective',
          iconIndex: const Value(7),
        ),
      );
    },
  );
}
