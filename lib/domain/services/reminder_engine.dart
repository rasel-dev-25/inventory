/// The reminder inbox — every source of "you need to follow up on
/// something" the spec calls out explicitly:
///
/// - §ছ (Due): "প্রতিটা Due-তে promisedDays অনুযায়ী reminder"
/// - §ঙ (Investor): "কবে দিতে হবে ... সারসংক্ষেপ/হোম পেজে reminder আকারে
///   দেখানো"
/// - §জ (Rent): "Customer-এ suspicionFlag টিক দেওয়া থাকলে বারবার
///   owner-কে reminder দেখাবে" + the overdue-rental follow-up itself
///
/// Plus [OrderDeadlineReminder], added after the fact — not named in the
/// spec text above, but M3's "customer orders with working deadline
/// reminders" checklist item always meant this and was previously
/// checked off without it: [Order.neededByDate] was stored and
/// displayed, but nothing ever surfaced an approaching or passed one as
/// an actual reminder anywhere. This closes that gap the same way every
/// other source here works.
///
/// Every function here is pure — no database, no clock read beyond the
/// [now] each one is explicitly handed — matching every other calculator
/// in this directory. `ReminderController` resolves the live lists these
/// take as input and is the only place that touches the database or the
/// real clock.
///
/// [Reminder] is a `sealed class` (same discipline as
/// `core/error/failure.dart`'s [Failure]) so a `switch` building display
/// text for one is exhaustiveness-checked — a new reminder type added
/// here forces every renderer to consciously decide what it looks like,
/// rather than falling through to nothing.
library;

import '../../core/money/money.dart';
import '../entities/customer.dart';
import '../entities/due.dart';
import '../entities/enums.dart';
import '../entities/investor.dart';
import '../entities/order.dart';
import '../entities/purchase.dart';
import '../entities/rent_transaction.dart';
import 'due_lifecycle.dart';
// Prefixed — `rent_lifecycle.dart`'s `isOverdue(RentTransaction, DateTime)`
// and `due_lifecycle.dart`'s `isOverdue(Due, DateTime)` share a name;
// this file needs the rent one, `due_lifecycle.dart`'s unprefixed
// `remainingBalance` is what it needs from that side.
import 'rent_lifecycle.dart' as rent_lifecycle;

sealed class Reminder {
  /// A stable id across recomputations (same entity ⇒ same id every
  /// time) — `ReminderController` uses this to know whether a given
  /// reminder has already triggered a local notification this session.
  String get id;

  /// Null for a reminder with no natural date (a standing "follow up
  /// with this suspicious customer" flag) — always active until the
  /// flag itself is cleared.
  DateTime? get dueDate;

  /// Named `isOverdueAsOf`, not `isOverdue` — [OverdueRentReminder]'s own
  /// override needs to call `rent_lifecycle.dart`'s top-level `isOverdue`
  /// function, and an identically-named instance method would shadow
  /// that unqualified call inside its own body.
  bool isOverdueAsOf(DateTime now);
}

/// An outstanding [Due] past (or approaching) its `promisedDays` deadline.
final class DueBalanceReminder extends Reminder {
  final Due due;
  final String customerName;

  DueBalanceReminder({required this.due, required this.customerName});

  @override
  String get id => 'due-${due.id}';

  @override
  DateTime get dueDate => due.createdAt.add(Duration(days: due.promisedDays!));

  Money get remaining => remainingBalance(due);

  @override
  bool isOverdueAsOf(DateTime now) => now.isAfter(dueDate);
}

/// An investor's capital-return date, per `capitalReturnTermDays` counted
/// from their first-ever investment.
final class InvestorCapitalReturnReminder extends Reminder {
  final Investor investor;
  @override
  final DateTime dueDate;

  InvestorCapitalReturnReminder({
    required this.investor,
    required this.dueDate,
  });

  @override
  String get id => 'investor-capital-${investor.id}';

  @override
  bool isOverdueAsOf(DateTime now) => now.isAfter(dueDate);
}

/// An investor's next profit-share payout date, per `profitPayoutCycle`.
/// Only ever built for [ProfitPayoutCycle.monthly] — see
/// [buildInvestorReminders]'s doc comment for why `daily`/`perContract`
/// don't get one of these.
final class InvestorProfitPayoutReminder extends Reminder {
  final Investor investor;
  @override
  final DateTime dueDate;

  InvestorProfitPayoutReminder({required this.investor, required this.dueDate});

  @override
  String get id => 'investor-payout-${investor.id}';

  @override
  bool isOverdueAsOf(DateTime now) => now.isAfter(dueDate);
}

/// A standing follow-up flag on a [Customer] — always active, per the
/// spec's "বারবার ... reminder দেখাবে" (repeatedly shows a reminder),
/// until the owner unchecks [Customer.suspicionFlag] themselves.
final class SuspiciousCustomerReminder extends Reminder {
  final Customer customer;

  SuspiciousCustomerReminder({required this.customer});

  @override
  String get id => 'suspicious-customer-${customer.id}';

  @override
  DateTime? get dueDate => null;

  @override
  bool isOverdueAsOf(DateTime now) => true;
}

/// A book rental past its due date and not yet returned/escalated.
final class OverdueRentReminder extends Reminder {
  final RentTransaction rent;
  final String customerName;
  final String bookName;

  OverdueRentReminder({
    required this.rent,
    required this.customerName,
    required this.bookName,
  });

  @override
  String get id => 'overdue-rent-${rent.id}';

  @override
  DateTime get dueDate => rent.dueDate;

  int extraDaysAsOf(DateTime now) => rent_lifecycle.computeExtraDays(
    dueDate: rent.dueDate,
    actualReturnDate: now,
  );

  @override
  bool isOverdueAsOf(DateTime now) => rent_lifecycle.isOverdue(rent, now);
}

/// A pending customer [Order] approaching or past [Order.neededByDate].
final class OrderDeadlineReminder extends Reminder {
  final Order order;
  final String customerName;

  OrderDeadlineReminder({required this.order, required this.customerName});

  @override
  String get id => 'order-deadline-${order.id}';

  @override
  DateTime get dueDate => order.neededByDate!;

  @override
  bool isOverdueAsOf(DateTime now) => now.isAfter(dueDate);
}

/// [customerNameOf] must resolve every [dues] entry's `customerId` — a
/// missing mapping falls back to the id itself rather than throwing,
/// same convention `stock_v2`'s `investorName` resolver uses.
///
/// Only [dues] with a set `promisedDays` and a status other than
/// [DueStatus.paid] produce a reminder — a due with no promised days has
/// no deadline to remind about, and a paid due has nothing left to chase.
///
/// [upcomingWithinDays] controls how far into the future a not-yet-due
/// reminder still shows — the inbox is for what needs attention now or
/// soon, not a second copy of the full Dues ledger.
List<DueBalanceReminder> buildDueReminders({
  required List<Due> dues,
  required String Function(String customerId) customerNameOf,
  required DateTime now,
  int upcomingWithinDays = 3,
}) {
  final horizon = now.add(Duration(days: upcomingWithinDays));
  final reminders = <DueBalanceReminder>[];
  for (final due in dues) {
    if (due.promisedDays == null || due.status == DueStatus.paid) continue;
    final dueDate = due.createdAt.add(Duration(days: due.promisedDays!));
    if (dueDate.isAfter(horizon)) continue;
    reminders.add(
      DueBalanceReminder(
        due: due,
        customerName: customerNameOf(due.customerId),
      ),
    );
  }
  return reminders;
}

/// The earliest date [investorId] appears as a [PurchaseItem.fundSource]
/// across [purchaseTrips] — the "first investment date" reference point
/// `investor_metrics.dart`'s own doc comment flags as needed but not yet
/// modeled as a stored field. Derived here rather than added as a new
/// `Investor` column, matching this codebase's "everything derivable
/// from real transaction history is derived, not duplicated" rule
/// (`Products.qty`, `availableCopies`, …). Null when the investor has
/// never actually funded a purchase yet — there is nothing to count a
/// term from.
DateTime? deriveFirstInvestmentDate({
  required String investorId,
  required List<PurchaseTrip> purchaseTrips,
}) {
  DateTime? earliest;
  for (final trip in purchaseTrips) {
    final fundsThisInvestor = trip.items.any(
      (item) => item.fundSource.investorId == investorId,
    );
    if (!fundsThisInvestor) continue;
    if (earliest == null || trip.date.isBefore(earliest)) {
      earliest = trip.date;
    }
  }
  return earliest;
}

/// Builds both investor-related reminder kinds for every investor that
/// has a derivable first-investment date (see
/// [deriveFirstInvestmentDate]) — an investor who hasn't funded anything
/// yet has nothing to remind about.
///
/// [ProfitPayoutCycle.daily] gets no payout reminder — "due every single
/// day" is not an actionable reminder, it's an always-true statement.
/// [ProfitPayoutCycle.perContract] also gets none — a per-contract payout
/// happens at the same moment the capital is returned, i.e. exactly
/// [InvestorCapitalReturnReminder] already covers it; a second reminder
/// for the same date would just be noise.
List<Reminder> buildInvestorReminders({
  required List<Investor> investors,
  required List<PurchaseTrip> purchaseTrips,
  required DateTime now,
  int upcomingWithinDays = 3,
}) {
  final horizon = now.add(Duration(days: upcomingWithinDays));
  final reminders = <Reminder>[];

  for (final investor in investors) {
    final firstInvestmentDate = deriveFirstInvestmentDate(
      investorId: investor.id,
      purchaseTrips: purchaseTrips,
    );
    if (firstInvestmentDate == null) continue;

    final termDays = investor.capitalReturnTermDays;
    if (termDays != null) {
      final dueDate = firstInvestmentDate.add(Duration(days: termDays));
      if (!dueDate.isAfter(horizon)) {
        reminders.add(
          InvestorCapitalReturnReminder(investor: investor, dueDate: dueDate),
        );
      }
    }

    if (investor.profitPayoutCycle == ProfitPayoutCycle.monthly) {
      final nextPayout = _nextMonthlyAnniversary(
        anchor: firstInvestmentDate,
        now: now,
      );
      if (!nextPayout.isAfter(horizon)) {
        reminders.add(
          InvestorProfitPayoutReminder(investor: investor, dueDate: nextPayout),
        );
      }
    }
  }

  return reminders;
}

/// The next on-or-after-[now] occurrence of [anchor]'s day-of-month.
/// `DateTime`'s constructor rolling an out-of-range day (e.g. day 31 in
/// a 30-day month) into the following month is accepted as-is here — an
/// approximate reminder date, not a financial calculation that needs
/// exact clamping.
DateTime _nextMonthlyAnniversary({
  required DateTime anchor,
  required DateTime now,
}) {
  var candidate = DateTime.utc(now.year, now.month, anchor.day);
  if (!candidate.isAfter(now)) {
    candidate = DateTime.utc(now.year, now.month + 1, anchor.day);
  }
  return candidate;
}

List<SuspiciousCustomerReminder> buildSuspiciousCustomerReminders({
  required List<Customer> customers,
}) {
  return customers
      .where((c) => c.suspicionFlag)
      .map((c) => SuspiciousCustomerReminder(customer: c))
      .toList();
}

/// [bookNameOf]/[customerNameOf] fall back to the raw id, same convention
/// as [buildDueReminders]'s `customerNameOf`. Only rentals
/// `rent_lifecycle.dart`'s `isOverdue` function actually flags produce a
/// reminder — an active rental still within its due date has nothing to
/// chase yet.
List<OverdueRentReminder> buildOverdueRentReminders({
  required List<RentTransaction> rentals,
  required String Function(String productId) bookNameOf,
  required String Function(String customerId) customerNameOf,
  required DateTime now,
}) {
  return rentals
      .where((r) => rent_lifecycle.isOverdue(r, now))
      .map(
        (r) => OverdueRentReminder(
          rent: r,
          customerName: customerNameOf(r.customerId),
          bookName: bookNameOf(r.bookProductId),
        ),
      )
      .toList();
}

/// [customerNameOf] falls back to the raw id, same convention as
/// [buildDueReminders]/[buildOverdueRentReminders]. Only [orders] that are
/// still [OrderStatus.pending] *and* have a [Order.neededByDate] set
/// produce a reminder — a fulfilled or cancelled order has nothing left
/// to chase, and an order with no promised date has no deadline to remind
/// about, same reasoning [buildDueReminders] gives for a [Due] with no
/// `promisedDays`.
///
/// [upcomingWithinDays] is the same "needs attention now or soon" horizon
/// every other reminder source here uses — see [buildDueReminders]'s own
/// doc comment.
List<OrderDeadlineReminder> buildOrderDeadlineReminders({
  required List<Order> orders,
  required String Function(String customerId) customerNameOf,
  required DateTime now,
  int upcomingWithinDays = 3,
}) {
  final horizon = now.add(Duration(days: upcomingWithinDays));
  final reminders = <OrderDeadlineReminder>[];
  for (final order in orders) {
    if (order.status != OrderStatus.pending) continue;
    final neededByDate = order.neededByDate;
    if (neededByDate == null) continue;
    if (neededByDate.isAfter(horizon)) continue;
    reminders.add(
      OrderDeadlineReminder(
        order: order,
        customerName: customerNameOf(order.customerId),
      ),
    );
  }
  return reminders;
}

/// The whole inbox, sorted overdue-first, then soonest-due, with the
/// always-active (no-date) reminders — currently only
/// [SuspiciousCustomerReminder] — pinned at the very top: they need
/// attention regardless of any date math.
List<Reminder> buildReminderInbox({
  required List<Due> dues,
  required String Function(String customerId) customerNameOf,
  required List<Investor> investors,
  required List<PurchaseTrip> purchaseTrips,
  required List<Customer> customers,
  required List<RentTransaction> rentals,
  required String Function(String productId) bookNameOf,
  required List<Order> orders,
  required DateTime now,
  int upcomingWithinDays = 3,
}) {
  final reminders = <Reminder>[
    ...buildSuspiciousCustomerReminders(customers: customers),
    ...buildDueReminders(
      dues: dues,
      customerNameOf: customerNameOf,
      now: now,
      upcomingWithinDays: upcomingWithinDays,
    ),
    ...buildInvestorReminders(
      investors: investors,
      purchaseTrips: purchaseTrips,
      now: now,
      upcomingWithinDays: upcomingWithinDays,
    ),
    ...buildOverdueRentReminders(
      rentals: rentals,
      bookNameOf: bookNameOf,
      customerNameOf: customerNameOf,
      now: now,
    ),
    ...buildOrderDeadlineReminders(
      orders: orders,
      customerNameOf: customerNameOf,
      now: now,
      upcomingWithinDays: upcomingWithinDays,
    ),
  ];

  reminders.sort((a, b) {
    final aDate = a.dueDate;
    final bDate = b.dueDate;
    if (aDate == null && bDate == null) return 0;
    if (aDate == null) return -1;
    if (bDate == null) return 1;
    return aDate.compareTo(bDate);
  });
  return reminders;
}
