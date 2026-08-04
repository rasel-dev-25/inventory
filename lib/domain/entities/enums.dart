/// Enumerations shared across the domain layer, taken directly from the
/// vocabulary `notes/business_logic.md` defines. Kept as real Dart enums
/// (not strings) so a typo can't compile — the v1 schema used raw
/// `TextColumn` strings for all of these (`Sale.type`, `Customer.type`,
/// `Purchase.source`, `Investors.contractType`/`investmentType`), compared
/// by literal string equality throughout the controllers with no
/// compiler-enforced closed set.
library;

/// How a money movement was actually settled. Attached to every cash
/// transaction (sale, due payment, purchase funding, expense, investor
/// repayment) per business_logic.md §PaymentMethod, so the dashboard can
/// break "total cash" into cash / mobile banking / bank sub-balances.
enum PaymentMethod { cash, mobileBanking, bankTransfer }

/// Who actually funded a purchase item or owns a product's stock value:
/// the shop's own cash, or a specific investor. See [FundSource].
enum FundSourceType { shop, investor }

/// The shape of an investor's arrangement with the shop, per
/// business_logic.md §Investor. This governs whether they receive a
/// profit share at all:
/// - [cashLoan]: capital-only return, zero profit share — see
///   `calculateInvestorProfitShare`.
/// - [cashMudaraba] / [cashMusharaka]: profit-sharing arrangements,
///   `profitSharePercent` applies.
/// - [goodsInKind]: the investor supplied stock directly rather than cash;
///   still profit-sharing, but with no cash outlay to reconcile.
enum InvestmentType { cashLoan, cashMudaraba, cashMusharaka, goodsInKind }

/// How often an investor's profit share is paid out.
enum ProfitPayoutCycle { daily, monthly, perContract }

/// Settlement state of a single sale.
enum PaymentStatus { fullCash, partial, fullDue }

/// Lifecycle of an outstanding due (from a credit sale or an unpaid rental
/// charge).
enum DueStatus { pending, partiallyPaid, paid }

/// What created a due — a due is never its own free-standing transaction;
/// it always traces back to the sale or rental that created it.
enum DueSourceType { sale, rent }

/// Lifecycle of a book rental.
enum RentStatus { active, returned, overdue, treatedAsStolen }

/// Lifecycle of a customer pre-order.
enum OrderStatus { pending, fulfilled, cancelled }

/// What a QuickCapture note eventually becomes once triaged.
enum QuickCaptureType { voiceNote, photoNote }

enum QuickCaptureStatus { pending, converted }

/// The two expense categories the spec's cash formula treats specially —
/// both are deducted from Total Cash directly, never from an investor's
/// fund.
enum ExpenseCategory { monthlyRent, dailyOther }

/// Distinguishes a capital return from a profit-share payout on an
/// [InvestorRepayment] — the v1 schema had one flat `amount` with no way
/// to tell these apart after the fact.
enum RepaymentType { capitalReturn, profitShare }

/// How a [FixedAsset] entered the books — see business_logic.md's two
/// creation paths.
enum FixedAssetSource { shopCashPurchase, convertedFromStock }

/// Lifecycle of a [LegacySettlement] — see business_logic.md §৬.
enum LegacySettlementStatus { pending, settled }

/// A signed-in user's permission level on a shop, per the working plan's
/// M1 decision: owner has full read/write access, staff is view-only,
/// with no per-table exceptions. Mirrors Postgres's `shop_member_role`
/// enum (supabase/migrations/0001_foundations.sql) one-for-one — the
/// server-side RLS policies built from `apply_standard_rls`/
/// `apply_append_only_rls` are the real enforcement boundary; this enum
/// only drives client-side UX (which buttons/screens to show), matching
/// `PermissionFailure`'s own doc comment in lib/core/error/failure.dart.
enum ShopMemberRole { owner, staff }
