import 'package:drift/native.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/usecases/audit_log_usecases.dart';
import 'package:inventory/data/usecases/customer_usecases.dart';
import 'package:inventory/data/usecases/order_usecases.dart';
import 'package:inventory/data/usecases/product_usecases.dart';
import 'package:inventory/domain/entities/customer.dart';
import 'package:inventory/domain/entities/due.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/domain/entities/fund_source.dart';
import 'package:inventory/domain/entities/product.dart';
import 'package:inventory/domain/entities/rent_transaction.dart';
import 'package:inventory/domain/entities/sale.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabaseV2 db;
  late RetentionPolicyUseCase useCase;

  setUp(() {
    db = AppDatabaseV2.forTesting(NativeDatabase.memory());
    useCase = RetentionPolicyUseCase(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('recordAuditLog', () {
    test('writes a row with every provided field', () async {
      await recordAuditLog(
        db: db,
        shopId: defaultShopId,
        action: 'delete',
        changedTableName: 'customers',
        recordId: 'cust-1',
        oldValueJson: '{"name":"Karim"}',
        now: DateTime.now().toUtc(),
      );

      final entries = await db.auditLogDao.watchAll(defaultShopId).first;
      expect(entries, hasLength(1));
      expect(entries.single.action, 'delete');
      expect(entries.single.changedTableName, 'customers');
      expect(entries.single.recordId, 'cust-1');
      expect(entries.single.oldValueJson, '{"name":"Karim"}');
      expect(entries.single.newValueJson, isNull);
    });
  });

  group('RetentionPolicyUseCase.pruneAll', () {
    test(
      'hard-deletes audit log entries older than the cutoff, keeps recent ones',
      () async {
        await recordAuditLog(
          db: db,
          shopId: defaultShopId,
          action: 'delete',
          changedTableName: 'customers',
          recordId: 'old-1',
          now: DateTime.utc(2026, 1, 1),
        );
        await recordAuditLog(
          db: db,
          shopId: defaultShopId,
          action: 'delete',
          changedTableName: 'customers',
          recordId: 'recent-1',
          now: DateTime.utc(2026, 8, 1),
        );

        final result = await useCase.pruneAll(
          shopId: defaultShopId,
          now: DateTime.utc(2026, 8, 5),
          auditLogRetentionDays: 30,
        );

        expect(result.auditLogRowsDeleted, 1);
        final remaining = await db.auditLogDao.watchAll(defaultShopId).first;
        expect(remaining, hasLength(1));
        expect(remaining.single.recordId, 'recent-1');
      },
    );

    test(
      'hard-deletes soft-deleted customers/orders/expenses older than the cutoff',
      () async {
        await CustomerUseCases(db).create(
          const Customer(id: 'cust-old', name: 'Old'),
          shopId: defaultShopId,
          now: DateTime.utc(2026, 1, 1),
        );
        await CustomerUseCases(db).softDelete(
          'cust-old',
          shopId: defaultShopId,
          now: DateTime.utc(2026, 1, 1),
        );

        await CustomerUseCases(db).create(
          const Customer(id: 'cust-recent', name: 'Recent'),
          shopId: defaultShopId,
          now: DateTime.utc(2026, 8, 1),
        );
        await CustomerUseCases(db).softDelete(
          'cust-recent',
          shopId: defaultShopId,
          now: DateTime.utc(2026, 8, 1),
        );

        final result = await useCase.pruneAll(
          shopId: defaultShopId,
          now: DateTime.utc(2026, 8, 5),
          recycleBinRetentionDays: 30,
        );

        expect(result.customersDeleted, 1);

        final remainingCustomers = await (db.select(db.customers)).get();
        expect(remainingCustomers.map((c) => c.id).toList(), ['cust-recent']);
      },
    );

    test(
      'never touches a row that was never soft-deleted, regardless of age',
      () async {
        await CustomerUseCases(db).create(
          const Customer(id: 'cust-active', name: 'Still Active'),
          shopId: defaultShopId,
          now: DateTime.utc(2020, 1, 1),
        );

        final result = await useCase.pruneAll(
          shopId: defaultShopId,
          now: DateTime.utc(2026, 8, 5),
          recycleBinRetentionDays: 30,
        );

        expect(result.customersDeleted, 0);
        expect(await db.customerDao.getById('cust-active'), isNotNull);
      },
    );

    test(
      'prunes across customers, orders, and expenses independently',
      () async {
        await CustomerUseCases(db).create(
          const Customer(id: 'cust-1', name: 'Order Customer'),
          shopId: defaultShopId,
          now: DateTime.utc(2026, 1, 1),
        );
        await OrderUseCases(db).create(
          customerId: 'cust-1',
          itemDescription: 'Old order',
          requestedDate: DateTime.utc(2026, 1, 1),
          shopId: defaultShopId,
          now: DateTime.utc(2026, 1, 1),
        );
        final orderId = (await (db.select(db.orders)).get()).single.id;
        await OrderUseCases(db).softDelete(
          orderId,
          shopId: defaultShopId,
          now: DateTime.utc(2026, 1, 1),
        );

        final result = await useCase.pruneAll(
          shopId: defaultShopId,
          now: DateTime.utc(2026, 8, 5),
          recycleBinRetentionDays: 30,
          // The order's own softDelete call also wrote an audit log entry
          // dated 2026-01-01 — isolate this assertion to the recycle-bin
          // side of the policy by keeping every audit entry in this run.
          auditLogRetentionDays: 100000,
        );

        expect(result.ordersDeleted, 1);
        expect(result.customersDeleted, 0);
        expect(result.expensesDeleted, 0);
        expect(result.auditLogRowsDeleted, 0);
        expect(result.totalDeleted, 1);
      },
    );

    // Customers.id is a foreign-key target for Dues/Orders/
    // RentTransactions/Sales (see CustomerDao.hardDeleteOlderThan's own
    // doc comment) — a real DELETE on a customer with any row in one of
    // those four tables would throw a FK-constraint violation. These
    // four tests each exercise one of those tables directly, confirming
    // pruneAll skips the customer (leaves it soft-deleted) rather than
    // crashing or corrupting the delete.
    group(
      'skips (does not crash, does not hard-delete) a soft-deleted customer '
      'with linked history',
      () {
        Future<void> createOldSoftDeletedCustomer(String id) async {
          await CustomerUseCases(db).create(
            Customer(id: id, name: 'Customer $id'),
            shopId: defaultShopId,
            now: DateTime.utc(2026, 1, 1),
          );
          await CustomerUseCases(db).softDelete(
            id,
            shopId: defaultShopId,
            now: DateTime.utc(2026, 1, 1),
          );
        }

        test('a linked Due', () async {
          await createOldSoftDeletedCustomer('cust-due');
          await db.dueDao.create(
            Due(
              id: 'due-1',
              customerId: 'cust-due',
              sourceType: DueSourceType.sale,
              sourceId: 'sale-1',
              originalAmount: Money.fromMinor(5000),
              paidAmount: Money.zero(),
              status: DueStatus.pending,
              createdAt: DateTime.utc(2026, 1, 1),
            ),
            shopId: defaultShopId,
            now: DateTime.utc(2026, 1, 1),
          );

          final result = await useCase.pruneAll(
            shopId: defaultShopId,
            now: DateTime.utc(2026, 8, 5),
            recycleBinRetentionDays: 30,
          );

          expect(result.customersDeleted, 0);
          expect(
            await (db.select(db.customers)).get(),
            hasLength(1),
            reason: 'a customer with a linked due must not be hard-deleted',
          );
        });

        test('a linked Order', () async {
          await createOldSoftDeletedCustomer('cust-order');
          await OrderUseCases(db).create(
            customerId: 'cust-order',
            itemDescription: 'A red backpack',
            requestedDate: DateTime.utc(2026, 1, 1),
            shopId: defaultShopId,
            now: DateTime.utc(2026, 1, 1),
          );

          final result = await useCase.pruneAll(
            shopId: defaultShopId,
            now: DateTime.utc(2026, 8, 5),
            recycleBinRetentionDays: 30,
          );

          expect(result.customersDeleted, 0);
          expect(await (db.select(db.customers)).get(), hasLength(1));
        });

        test('a linked RentTransaction', () async {
          await createOldSoftDeletedCustomer('cust-rent');
          await ProductUseCases(db).create(
            Product(
              id: 'book-1',
              name: 'Rentable Book',
              category: 'Book',
              costPrice: Money.fromMinor(10000),
              suggestedSellPrice: Money.fromMinor(15000),
              qty: 1,
              fundSource: FundSource.shop(),
              isRentable: true,
              pageCount: 100,
            ),
            shopId: defaultShopId,
            now: DateTime.utc(2026, 1, 1),
          );
          await db.rentDao.create(
            RentTransaction(
              id: 'rent-1',
              bookProductId: 'book-1',
              customerId: 'cust-rent',
              startDate: DateTime.utc(2026, 1, 1),
              dueDate: DateTime.utc(2026, 1, 8),
              deposit: Money.zero(),
              rentPrice: Money.fromMinor(2000),
              status: RentStatus.active,
            ),
            shopId: defaultShopId,
            now: DateTime.utc(2026, 1, 1),
          );

          final result = await useCase.pruneAll(
            shopId: defaultShopId,
            now: DateTime.utc(2026, 8, 5),
            recycleBinRetentionDays: 30,
          );

          expect(result.customersDeleted, 0);
          expect(await (db.select(db.customers)).get(), hasLength(1));
        });

        test('a linked Sale', () async {
          await createOldSoftDeletedCustomer('cust-sale');
          await ProductUseCases(db).create(
            Product(
              id: 'prod-1',
              name: 'Notebook',
              category: 'Stationery',
              costPrice: Money.fromMinor(5000),
              suggestedSellPrice: Money.fromMinor(8000),
              qty: 1,
              fundSource: FundSource.shop(),
            ),
            shopId: defaultShopId,
            now: DateTime.utc(2026, 1, 1),
          );
          await db.saleDao.create(
            Sale(
              id: 'sale-1',
              productId: 'prod-1',
              qty: 1,
              actualSellPrice: Money.fromMinor(8000),
              costPriceAtSale: Money.fromMinor(5000),
              date: DateTime.utc(2026, 1, 1),
              customerId: 'cust-sale',
              paymentStatus: PaymentStatus.fullCash,
              paymentMethod: PaymentMethod.cash,
              fundSource: FundSource.shop(),
            ),
            shopId: defaultShopId,
            now: DateTime.utc(2026, 1, 1),
          );

          final result = await useCase.pruneAll(
            shopId: defaultShopId,
            now: DateTime.utc(2026, 8, 5),
            recycleBinRetentionDays: 30,
          );

          expect(result.customersDeleted, 0);
          expect(await (db.select(db.customers)).get(), hasLength(1));
        });
      },
    );

    test('prunes a customer with no linked history while skipping one that has '
        'some, in the same run', () async {
      await CustomerUseCases(db).create(
        const Customer(id: 'cust-clean', name: 'Clean'),
        shopId: defaultShopId,
        now: DateTime.utc(2026, 1, 1),
      );
      await CustomerUseCases(db).softDelete(
        'cust-clean',
        shopId: defaultShopId,
        now: DateTime.utc(2026, 1, 1),
      );

      await CustomerUseCases(db).create(
        const Customer(id: 'cust-with-order', name: 'Has History'),
        shopId: defaultShopId,
        now: DateTime.utc(2026, 1, 1),
      );
      await OrderUseCases(db).create(
        customerId: 'cust-with-order',
        itemDescription: 'A red backpack',
        requestedDate: DateTime.utc(2026, 1, 1),
        shopId: defaultShopId,
        now: DateTime.utc(2026, 1, 1),
      );
      await CustomerUseCases(db).softDelete(
        'cust-with-order',
        shopId: defaultShopId,
        now: DateTime.utc(2026, 1, 1),
      );

      final result = await useCase.pruneAll(
        shopId: defaultShopId,
        now: DateTime.utc(2026, 8, 5),
        recycleBinRetentionDays: 30,
      );

      expect(
        result.customersDeleted,
        1,
        reason: 'only the customer with no linked history is deletable',
      );
      final remaining = await (db.select(db.customers)).get();
      expect(remaining.map((c) => c.id).toList(), ['cust-with-order']);
    });
  });
}
