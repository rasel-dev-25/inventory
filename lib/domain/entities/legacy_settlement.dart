import '../../core/money/money.dart';
import 'enums.dart';

/// A one-time opening-balance settlement for capital invested before this
/// app existed, per `notes/business_logic.md` §৬ — "আব্বার ৫ বছরের খাতার
/// হিসাব" (five years of ledger-book accounting for a specific investor,
/// with no granular per-purchase/per-sale entries to import).
///
/// Deliberately **not** a normal [Investor] history record: it never mixes
/// into `InvestorMetrics`/the cash ledger/stock — see
/// `LegacySettlementUseCases`'s doc comment for why. It exists purely as a
/// one-time, immutable-after-creation memo (`totalHistoricalInvestment`,
/// `totalAlreadyReturned`, `notes` are filled in exactly once) that flips
/// from [LegacySettlementStatus.pending] to
/// [LegacySettlementStatus.settled] when the owner actually hands over
/// [netSettlementAmount] — after which the investor's normal tracking
/// starts fresh from zero.
class LegacySettlement {
  final String id;
  final String investorId;

  /// Total investment computed by hand from the old paper ledger.
  final Money totalHistoricalInvestment;

  /// Whatever has already been returned against that old investment, if
  /// anything — zero when nothing was ever returned.
  final Money totalAlreadyReturned;

  /// What must still be handed over now to close the old account —
  /// always `totalHistoricalInvestment - totalAlreadyReturned`, computed
  /// once at creation time by `LegacySettlementUseCases.create` rather
  /// than accepted as free user input (matches the spec's "হিসাব করে"
  /// annotation on this field).
  final Money netSettlementAmount;

  final DateTime settlementDate;

  /// Free-text reference to the old ledger book / summary, preserved
  /// verbatim per the spec's own note field.
  final String? notes;

  final LegacySettlementStatus status;

  const LegacySettlement({
    required this.id,
    required this.investorId,
    required this.totalHistoricalInvestment,
    required this.totalAlreadyReturned,
    required this.netSettlementAmount,
    required this.settlementDate,
    this.notes,
    this.status = LegacySettlementStatus.pending,
  });

  LegacySettlement copyWith({LegacySettlementStatus? status}) {
    return LegacySettlement(
      id: id,
      investorId: investorId,
      totalHistoricalInvestment: totalHistoricalInvestment,
      totalAlreadyReturned: totalAlreadyReturned,
      netSettlementAmount: netSettlementAmount,
      settlementDate: settlementDate,
      notes: notes,
      status: status ?? this.status,
    );
  }
}
