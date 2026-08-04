import 'package:drift/drift.dart';

import '../../../domain/entities/enums.dart';
import 'shared.dart';

@DataClassName('InvestorRow')
class Investors extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text().references(Shops, #id)();
  TextColumn get name => text()();
  TextColumn get contact => text().nullable()();

  TextColumn get investmentType => textEnum<InvestmentType>()();

  /// 0–100. Zero-share enforcement for [InvestmentType.cashLoan] happens
  /// in `calculateInvestorProfitShare`, not here — this column stores
  /// whatever was entered, by design (see that function's doc comment for
  /// why it does not trust this value alone).
  RealColumn get profitSharePercent => real().withDefault(const Constant(0))();

  IntColumn get capitalReturnTermDays => integer().nullable()();
  TextColumn get profitPayoutCycle => textEnum<ProfitPayoutCycle>()();
  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A payment made *to* an investor — capital return or profit-share payout.
/// Append-only: a repayment is a ledger fact once made. A mistaken entry is
/// corrected with a reversal row, never an edit or delete — same rule as
/// [CashLedgerEntries] in `ledger.dart`, since every repayment also mirrors
/// into that table.
@DataClassName('InvestorRepaymentRow')
class InvestorRepayments extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text().references(Shops, #id)();
  TextColumn get investorId => text().references(Investors, #id)();

  IntColumn get amountMinor => integer()();
  TextColumn get type => textEnum<RepaymentType>()();
  TextColumn get paymentMethod => textEnum<PaymentMethod>()();
  DateTimeColumn get date => dateTime()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A one-time opening-balance settlement for capital invested before this
/// app existed (business_logic.md §৬ — "আব্বার ৫ বছরের খাতার হিসাব").
/// Deliberately outside the normal Purchase/Sale history — it is a single
/// note, not a stream of transactions, and once `status == settled` the
/// investor's normal tracking starts fresh from zero.
@DataClassName('LegacySettlementRow')
class LegacySettlements extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text().references(Shops, #id)();
  TextColumn get investorId => text().references(Investors, #id)();

  IntColumn get totalHistoricalInvestmentMinor => integer()();
  IntColumn get totalAlreadyReturnedMinor =>
      integer().withDefault(const Constant(0))();
  IntColumn get netSettlementAmountMinor => integer()();
  DateTimeColumn get settlementDate => dateTime()();
  TextColumn get notes => text().nullable()();
  TextColumn get status => textEnum<LegacySettlementStatus>()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
