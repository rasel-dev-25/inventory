import 'package:drift/native.dart';
import 'package:inventory/core/error/failure.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/usecases/issue_rent_usecase.dart';
import 'package:inventory/data/usecases/mark_rent_stolen_usecase.dart';
import 'package:inventory/data/usecases/product_usecases.dart';
import 'package:inventory/data/usecases/return_rent_usecase.dart';
import 'package:inventory/domain/entities/customer.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/domain/entities/fund_source.dart';
import 'package:inventory/domain/entities/product.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late MarkRentStolenUseCase useCase;
  late String rentId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    useCase = MarkRentStolenUseCase(db);

    await db.customerDao.create(
      const Customer(id: 'cust-1', name: 'Test Customer'),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
    await ProductUseCases(db).create(
      Product(
        id: 'book-a',
        name: 'Book A',
        category: 'Book',
        costPrice: Money.fromMinor(10000),
        suggestedSellPrice: Money.fromMinor(15000),
        qty: 1,
        fundSource: FundSource.shop(),
        isRentable: true,
      ),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
    await IssueRentUseCase(db).call(
      bookProductId: 'book-a',
      customerId: 'cust-1',
      deposit: Money.zero(),
      days: 15,
      rentPrice: Money.fromMinor(2000),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
      startDate: DateTime.utc(2026, 1, 1),
    );
    rentId = (await (db.select(db.rentTransactions)).get()).single.id;
  });

  tearDown(() async {
    await db.close();
  });

  test('marks the rental stolen and blocks the customer', () async {
    final result = await useCase.call(
      rentId: rentId,
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    expect(result.isOk, isTrue, reason: result.failureOrNull?.toString());

    final rent = (await (db.select(db.rentTransactions)).get()).single;
    expect(rent.status, RentStatus.treatedAsStolen);

    final customer = await db.customerDao.getById('cust-1');
    expect(customer!.isBlocked, isTrue);
  });

  test('rejects marking an already-returned rental as stolen', () async {
    await ReturnRentUseCase(db).call(
      rentId: rentId,
      actualReturnDate: DateTime.utc(2026, 1, 16),
      amountReceivedNow: Money.fromMinor(2000),
      paymentMethod: PaymentMethod.cash,
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    final result = await useCase.call(
      rentId: rentId,
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    expect(result.isErr, isTrue);
    expect(result.failureOrNull, isA<BusinessRuleFailure>());
  });

  test('rejects marking an already-stolen rental again', () async {
    final first = await useCase.call(
      rentId: rentId,
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
    expect(first.isOk, isTrue);

    final second = await useCase.call(
      rentId: rentId,
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    expect(second.isErr, isTrue);
    expect(second.failureOrNull, isA<BusinessRuleFailure>());
  });

  test('rejects a nonexistent rental', () async {
    final result = await useCase.call(
      rentId: 'does-not-exist',
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );

    expect(result.isErr, isTrue);
    expect(result.failureOrNull, isA<NotFoundFailure>());
  });
}
