import 'package:uuid/uuid.dart';

import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../core/money/money.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/rent_transaction.dart';
import '../../domain/services/rent_lifecycle.dart';
import '../local/app_database.dart';
import '../sync/outbox_event.dart';
import 'sync_enqueue_helper.dart';

/// Issues a book rental, per `notes/business_logic.md` §জ.
///
/// [days]/[rentPrice] are looked up from the matching [RentPricingTiers]
/// row via the book's `pageCount` when both are omitted; either can be
/// supplied directly to override that suggestion (the spec's "ম্যানুয়াল
/// ওভাররাইড করা যাবে"), and *must* be supplied when the book has no
/// `pageCount` set or no tier covers it (`suggestTierFor` returns `null`
/// in that case — see its own doc comment).
///
/// Deliberately writes **no** `StockMovements` row and never touches
/// `Product.qty` — see `lib/data/local/tables/rent.dart`'s doc comment
/// for why "copies available to rent" is derived on read
/// (`product.qty − active rental count`), not a cache this use case would
/// otherwise need to maintain.
///
/// The deposit (if positive) is real cash collected right now — it
/// mirrors into `cash_ledger_entries` as an inflow immediately, same as
/// every other cash event in this app. The rental fee itself is *not*
/// collected here; see `ReturnRentUseCase` for why it's settled at return
/// time instead.
class IssueRentUseCase {
  final AppDatabase db;
  static const _uuid = Uuid();

  IssueRentUseCase(this.db);

  Future<Result<void>> call({
    required String bookProductId,
    required String customerId,
    required Money deposit,
    required String shopId,
    required DateTime now,
    DateTime? startDate,
    int? days,
    Money? rentPrice,
  }) async {
    if (deposit.isNegative) {
      return const Result.err(
        ValidationFailure('deposit', 'Deposit cannot be negative'),
      );
    }

    final product = await db.productDao.getById(bookProductId);
    if (product == null) {
      return Result.err(NotFoundFailure('product', bookProductId));
    }
    if (!product.isRentable) {
      return const Result.err(
        BusinessRuleFailure('This product is not marked as rentable'),
      );
    }

    final activeCount = await db.rentDao.countActiveRentals(
      shopId,
      bookProductId,
    );
    final availableCopies = product.qty - activeCount;
    if (availableCopies <= 0) {
      return const Result.err(
        BusinessRuleFailure('No copies of this book are available to rent'),
      );
    }

    var resolvedDays = days;
    var resolvedPrice = rentPrice;
    if (resolvedDays == null || resolvedPrice == null) {
      final tiers = await db.rentDao.getTiers(shopId);
      final suggestion = product.pageCount == null
          ? null
          : suggestTierFor(
              product.pageCount!,
              tiers
                  .map(
                    (t) => (
                      maxPages: t.maxPages,
                      days: t.days,
                      priceMinor: t.priceMinor,
                    ),
                  )
                  .toList(),
            );
      if (suggestion == null &&
          (resolvedDays == null || resolvedPrice == null)) {
        return const Result.err(
          ValidationFailure(
            'days',
            'No pricing tier covers this book — enter days and price manually',
          ),
        );
      }
      resolvedDays ??= suggestion!.days;
      resolvedPrice ??= suggestion!.price;
    }

    final effectiveStart = startDate ?? now;
    final dueDate = computeDueDate(
      startDate: effectiveStart,
      days: resolvedDays,
    );

    final rent = RentTransaction(
      id: _uuid.v7(),
      bookProductId: bookProductId,
      customerId: customerId,
      startDate: effectiveStart,
      dueDate: dueDate,
      deposit: deposit,
      rentPrice: resolvedPrice,
      status: RentStatus.active,
    );

    final dateIso = effectiveStart.toUtc().toIso8601String();
    final upserts = <TableUpsert>[
      TableUpsert(
        table: 'rent_transactions',
        row: {
          'id': rent.id,
          'shop_id': shopId,
          'book_product_id': rent.bookProductId,
          'customer_id': rent.customerId,
          'start_date': dateIso,
          'due_date': dueDate.toUtc().toIso8601String(),
          'deposit_minor': rent.deposit.minorUnits,
          'rent_price_minor': rent.rentPrice.minorUnits,
          'status': rent.status.name,
        },
      ),
    ];

    final ledgerId = _uuid.v7();
    if (deposit.isPositive) {
      upserts.add(
        TableUpsert(
          table: 'cash_ledger_entries',
          row: {
            'id': ledgerId,
            'shop_id': shopId,
            'amount_minor': deposit.minorUnits,
            'payment_method': PaymentMethod.cash.name,
            'source_type': 'rent',
            'source_id': rent.id,
            'description': 'Rental deposit',
            'date': dateIso,
          },
        ),
      );
    }

    await writeAndEnqueue(
      db: db,
      eventType: 'rent_issued',
      upserts: upserts,
      localWrite: () async {
        await db.rentDao.create(rent, shopId: shopId, now: now);
        if (deposit.isPositive) {
          await db.ledgerDao.recordCashLedgerEntry(
            id: ledgerId,
            shopId: shopId,
            amountMinor: deposit.minorUnits,
            paymentMethod: PaymentMethod.cash,
            sourceType: 'rent',
            sourceId: rent.id,
            date: effectiveStart,
            now: now,
            description: 'Rental deposit',
          );
        }
      },
    );

    return const Result.ok(null);
  }
}
