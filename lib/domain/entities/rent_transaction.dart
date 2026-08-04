import '../../core/money/money.dart';
import 'enums.dart';

/// A book rental, per `notes/business_logic.md` §RentTransaction/§জ.
///
/// [rentPrice] is the agreed basic rental fee at issue time (tier-
/// suggested or manually overridden) — settled at return time, not
/// collected upfront; see `rent_lifecycle.dart`'s `computeReturnSettlement`
/// for why. [deposit] *is* collected upfront (a refundable security hold),
/// which is what makes it a genuinely separate field from [rentPrice]
/// rather than the same number.
///
/// [extraDayCharge]/[damageCharge] are null until [status] is
/// [RentStatus.returned] — both are only knowable once the book actually
/// comes back.
///
/// There is no `availableCopies` field here or on `Product` — see
/// `lib/data/local/tables/rent.dart`'s table doc comment for why that is
/// deliberately derived on read (`product.qty` minus the count of this
/// shop's active rentals for that product), not cached.
class RentTransaction {
  final String id;
  final String bookProductId;
  final String customerId;

  final DateTime startDate;
  final DateTime dueDate;
  final Money deposit;
  final Money rentPrice;

  final Money? extraDayCharge;
  final Money? damageCharge;

  final RentStatus status;
  final DateTime? returnedDate;

  const RentTransaction({
    required this.id,
    required this.bookProductId,
    required this.customerId,
    required this.startDate,
    required this.dueDate,
    required this.deposit,
    required this.rentPrice,
    required this.status,
    this.extraDayCharge,
    this.damageCharge,
    this.returnedDate,
  });

  RentTransaction copyWith({
    Money? extraDayCharge,
    Money? damageCharge,
    RentStatus? status,
    DateTime? returnedDate,
  }) {
    return RentTransaction(
      id: id,
      bookProductId: bookProductId,
      customerId: customerId,
      startDate: startDate,
      dueDate: dueDate,
      deposit: deposit,
      rentPrice: rentPrice,
      extraDayCharge: extraDayCharge ?? this.extraDayCharge,
      damageCharge: damageCharge ?? this.damageCharge,
      status: status ?? this.status,
      returnedDate: returnedDate ?? this.returnedDate,
    );
  }
}
