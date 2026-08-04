import 'enums.dart';

/// An investor, per `notes/business_logic.md` §Investor.
///
/// `profitSharePercent` is stored as a plain percentage (e.g. `30.0` means
/// 30%), matching how the spec and any future settings form talk about it
/// — the conversion to a fraction happens once, inside
/// `calculateInvestorProfitShare`, not scattered across call sites.
class Investor {
  final String id;
  final String name;
  final String? contact;
  final InvestmentType investmentType;

  /// 0–100. Only meaningful when [investmentType] is
  /// [InvestmentType.cashMudaraba], [InvestmentType.cashMusharaka], or
  /// [InvestmentType.goodsInKind] — a [InvestmentType.cashLoan] investor's
  /// share is always zero regardless of this value; see
  /// `calculateInvestorProfitShare`.
  final double profitSharePercent;

  /// Contractual term for capital return, in days from investment date.
  /// Null when there's no fixed term (open-ended arrangement).
  final int? capitalReturnTermDays;

  final ProfitPayoutCycle profitPayoutCycle;

  /// Free-text contract details the spec explicitly wants preserved
  /// verbatim rather than forced into structured fields — see
  /// business_logic.md's `notes` field on Investor.
  final String? notes;

  const Investor({
    required this.id,
    required this.name,
    this.contact,
    required this.investmentType,
    this.profitSharePercent = 0,
    this.capitalReturnTermDays,
    this.profitPayoutCycle = ProfitPayoutCycle.monthly,
    this.notes,
  });

  Investor copyWith({
    String? name,
    String? contact,
    InvestmentType? investmentType,
    double? profitSharePercent,
    int? capitalReturnTermDays,
    ProfitPayoutCycle? profitPayoutCycle,
    String? notes,
  }) {
    return Investor(
      id: id,
      name: name ?? this.name,
      contact: contact ?? this.contact,
      investmentType: investmentType ?? this.investmentType,
      profitSharePercent: profitSharePercent ?? this.profitSharePercent,
      capitalReturnTermDays:
          capitalReturnTermDays ?? this.capitalReturnTermDays,
      profitPayoutCycle: profitPayoutCycle ?? this.profitPayoutCycle,
      notes: notes ?? this.notes,
    );
  }
}
