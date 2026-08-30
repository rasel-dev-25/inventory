import 'package:drift/native.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/sync/outbox_event.dart';
import 'package:inventory/data/usecases/customer_usecases.dart';
import 'package:inventory/data/usecases/edit_sale_usecase.dart';
import 'package:inventory/data/usecases/product_usecases.dart';
import 'package:inventory/data/usecases/save_sale_usecase.dart';
import 'package:inventory/domain/entities/customer.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/domain/entities/fund_source.dart';
import 'package:inventory/domain/entities/product.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late EditSaleUseCase editUseCase;
  late SaveSaleUseCase saveSaleUseCase;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    editUseCase = EditSaleUseCase(db);
    saveSaleUseCase = SaveSaleUseCase(db);

    await ProductUseCases(db).create(
      Product(
        id: 'prod-1',
        name: 'Item 1',
        category: 'General',
        costPrice: Money.fromMinor(5000),
        suggestedSellPrice: Money.fromMinor(8000),
        qty: 10,
        fundSource: FundSource.shop(),
      ),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    await CustomerUseCases(db).create(
      Customer(
        id: 'cust-1',
        name: 'Rahim',
        contact: '01700000000',
        address: 'Dhaka',
      ),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('editing a sale updates quantity, adjusts stock, updates cash, and enqueues outbox event', () async {
    final now = DateTime.now().toUtc();
    final saveResult = await saveSaleUseCase.call(
      productId: 'prod-1',
      qty: 2,
      actualSellPrice: Money.fromMinor(8000),
      amountReceivedNow: Money.fromMinor(16000),
      paymentMethod: PaymentMethod.cash,
      date: now,
      shopId: defaultShopId,
      now: now,
    );
    expect(saveResult.isOk, isTrue);
    final saleId = saveResult.valueOrNull!;

    // Verify stock after initial sale of 2 units
    var product = await db.productDao.getById('prod-1');
    expect(product?.qty, 8.0); // 10 - 2

    // Edit sale: change qty from 2 to 5 units, price from 8000 to 9000
    final editResult = await editUseCase.call(
      saleId: saleId,
      qty: 5,
      actualSellPrice: Money.fromMinor(9000),
      amountReceivedNow: Money.fromMinor(45000),
      paymentMethod: PaymentMethod.cash,
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
    expect(editResult.isOk, isTrue);

    // Verify stock reflects new qty of 5 (10 initial - 5 = 5)
    product = await db.productDao.getById('prod-1');
    expect(product?.qty, 5.0);

    // Verify sale entity updated
    final updatedSale = await db.saleDao.getById(saleId);
    expect(updatedSale?.qty, 5.0);
    expect(updatedSale?.actualSellPrice, Money.fromMinor(9000));
    expect(updatedSale?.paymentStatus, PaymentStatus.fullCash);

    // Verify outbox entry
    final outboxRows = await db.syncMetadataDao.pendingEntries();
    final editOutbox = outboxRows.firstWhere((r) => r.eventType == 'sale_updated');
    final upserts = OutboxEvent.decodePayload(editOutbox.payloadJson);
    expect(upserts.any((u) => u.table == 'sales'), isTrue);
    expect(upserts.any((u) => u.table == 'stock_movements'), isTrue);
  });

  test('editing a sale to partial payment creates a due record', () async {
    final now = DateTime.now().toUtc();
    final saveResult = await saveSaleUseCase.call(
      productId: 'prod-1',
      qty: 2,
      actualSellPrice: Money.fromMinor(8000),
      amountReceivedNow: Money.fromMinor(16000),
      paymentMethod: PaymentMethod.cash,
      date: now,
      shopId: defaultShopId,
      now: now,
    );
    final saleId = saveResult.valueOrNull!;

    // Edit to partial sale: total 20000, received 12000, due 8000
    final editResult = await editUseCase.call(
      saleId: saleId,
      qty: 2,
      actualSellPrice: Money.fromMinor(10000),
      amountReceivedNow: Money.fromMinor(12000),
      paymentMethod: PaymentMethod.cash,
      customerId: 'cust-1',
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
    expect(editResult.isOk, isTrue);

    final due = await db.dueDao.getBySource('sale', saleId);
    expect(due, isNotNull);
    expect(due?.originalAmount, Money.fromMinor(8000));
    expect(due?.customerId, 'cust-1');
  });

  test('rejects edit when requested qty exceeds available stock', () async {
    final now = DateTime.now().toUtc();
    final saveResult = await saveSaleUseCase.call(
      productId: 'prod-1',
      qty: 2,
      actualSellPrice: Money.fromMinor(8000),
      amountReceivedNow: Money.fromMinor(16000),
      paymentMethod: PaymentMethod.cash,
      date: now,
      shopId: defaultShopId,
      now: now,
    );
    final saleId = saveResult.valueOrNull!;

    // Available was 10. Edit asking for 20 should fail.
    final editResult = await editUseCase.call(
      saleId: saleId,
      qty: 20,
      actualSellPrice: Money.fromMinor(8000),
      amountReceivedNow: Money.fromMinor(160000),
      paymentMethod: PaymentMethod.cash,
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
    expect(editResult.isErr, isTrue);
  });
}
