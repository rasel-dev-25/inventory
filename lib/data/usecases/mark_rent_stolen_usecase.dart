import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../domain/entities/enums.dart';
import '../local/app_database.dart';
import '../sync/outbox_event.dart';
import 'customer_usecases.dart';
import 'sync_enqueue_helper.dart';

/// The escalation `notes/business_logic.md` §জ describes: "নির্দিষ্ট
/// সময়ে ফেরত না দিলে ও ফলোআপেও সাড়া না দিলে → status =
/// treated_as_stolen, Customer.isBlocked = true". The spec's condition
/// ("বহুদিন ধরে overdue, ফলোআপেও সাড়া নেই") is an owner judgment call, not
/// a precise rule a background job could evaluate — so this is an
/// explicit action the owner takes from the Rent screen on a specific
/// overdue rental, never an automatic time-based transition. Flagged,
/// not silently modeled as automatic.
///
/// Writes the rent status and the customer's `isBlocked` flag as two
/// separate outbox events (via [RentDao.markStolen] and
/// [CustomerUseCases.update] respectively) rather than one shared
/// transaction — acceptable here because this is a rare, manually-
/// triggered action, unlike the high-frequency cash/stock writes
/// elsewhere in this directory that share a transaction to guarantee
/// atomicity.
class MarkRentStolenUseCase {
  final AppDatabase db;

  MarkRentStolenUseCase(this.db);

  Future<Result<void>> call({
    required String rentId,
    required String shopId,
    required DateTime now,
  }) async {
    final rent = await db.rentDao.getById(rentId);
    if (rent == null) {
      return Result.err(NotFoundFailure('rentTransaction', rentId));
    }
    if (rent.status == RentStatus.returned) {
      return const Result.err(
        BusinessRuleFailure('This rental was already returned'),
      );
    }
    if (rent.status == RentStatus.treatedAsStolen) {
      return const Result.err(
        BusinessRuleFailure('This rental is already marked as stolen'),
      );
    }

    await writeAndEnqueue(
      db: db,
      eventType: 'rent_marked_stolen',
      upserts: [
        TableUpsert(
          table: 'rent_transactions',
          row: {
            'id': rentId,
            'shop_id': shopId,
            'status': RentStatus.treatedAsStolen.name,
          },
        ),
      ],
      localWrite: () => db.rentDao.markStolen(rentId, now),
    );

    final customer = await db.customerDao.getById(rent.customerId);
    if (customer != null && !customer.isBlocked) {
      await CustomerUseCases(
        db,
      ).update(customer.copyWith(isBlocked: true), shopId: shopId, now: now);
    }

    return const Result.ok(null);
  }
}
