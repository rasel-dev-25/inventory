import 'package:test/test.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/domain/entities/customer.dart';
import 'package:inventory/domain/entities/due.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/domain/entities/fund_source.dart';
import 'package:inventory/domain/entities/investor.dart';
import 'package:inventory/domain/entities/order.dart';
import 'package:inventory/domain/entities/purchase.dart';
import 'package:inventory/domain/entities/rent_transaction.dart';
import 'package:inventory/domain/services/reminder_engine.dart';

Due _due({
  required String id,
  int? promisedDays,
  DueStatus status = DueStatus.pending,
  required DateTime createdAt,
}) {
  return Due(
    id: id,
    customerId: 'customer-1',
    sourceType: DueSourceType.sale,
    sourceId: 'sale-1',
    originalAmount: Money.fromMinor(10000),
    paidAmount: Money.zero(),
    promisedDays: promisedDays,
    status: status,
    createdAt: createdAt,
  );
}

PurchaseTrip _tripFundedBy(String investorId, DateTime date) {
  return PurchaseTrip(
    id: 'trip-$investorId-${date.toIso8601String()}',
    date: date,
    transportCost: Money.zero(),
    cashReturned: Money.zero(),
    items: [
      PurchaseItem(
        id: 'item-$investorId-${date.toIso8601String()}',
        shopName: 'Mokam',
        productId: 'book-a',
        qty: 1,
        unitPrice: Money.fromMinor(10000),
        fundSource: FundSource.investor(investorId),
      ),
    ],
  );
}

RentTransaction _rent({
  required String id,
  required DateTime dueDate,
  RentStatus status = RentStatus.active,
}) {
  return RentTransaction(
    id: id,
    bookProductId: 'book-a',
    customerId: 'customer-1',
    startDate: dueDate.subtract(const Duration(days: 7)),
    dueDate: dueDate,
    deposit: Money.fromMinor(5000),
    rentPrice: Money.fromMinor(3000),
    status: status,
  );
}

Order _order({
  required String id,
  DateTime? neededByDate,
  OrderStatus status = OrderStatus.pending,
}) {
  return Order(
    id: id,
    customerId: 'customer-1',
    itemDescription: 'A red backpack',
    requestedDate: DateTime.utc(2026, 8, 1),
    neededByDate: neededByDate,
    status: status,
  );
}

void main() {
  final now = DateTime.utc(2026, 8, 5);

  group('buildDueReminders', () {
    test('reminds for a due whose promised-days deadline already passed', () {
      final due = _due(
        id: 'due-1',
        promisedDays: 3,
        createdAt: now.subtract(const Duration(days: 10)),
      );
      final reminders = buildDueReminders(
        dues: [due],
        customerNameOf: (_) => 'Karim',
        now: now,
      );
      expect(reminders, hasLength(1));
      expect(reminders.single.customerName, 'Karim');
      expect(reminders.single.isOverdueAsOf(now), isTrue);
    });

    test('includes a due within the upcoming window but not overdue yet', () {
      final due = _due(
        id: 'due-1',
        promisedDays: 3,
        createdAt: now.subtract(const Duration(days: 1)), // due in 2 days
      );
      final reminders = buildDueReminders(
        dues: [due],
        customerNameOf: (_) => 'Karim',
        now: now,
        upcomingWithinDays: 3,
      );
      expect(reminders, hasLength(1));
      expect(reminders.single.isOverdueAsOf(now), isFalse);
    });

    test('excludes a due far outside the upcoming window', () {
      final due = _due(
        id: 'due-1',
        promisedDays: 30,
        createdAt: now, // due in 30 days
      );
      final reminders = buildDueReminders(
        dues: [due],
        customerNameOf: (_) => 'Karim',
        now: now,
        upcomingWithinDays: 3,
      );
      expect(reminders, isEmpty);
    });

    test('excludes a due with no promisedDays set', () {
      final due = _due(id: 'due-1', promisedDays: null, createdAt: now);
      final reminders = buildDueReminders(
        dues: [due],
        customerNameOf: (_) => 'Karim',
        now: now,
      );
      expect(reminders, isEmpty);
    });

    test('excludes an already-paid due even if its deadline passed', () {
      final due = _due(
        id: 'due-1',
        promisedDays: 3,
        status: DueStatus.paid,
        createdAt: now.subtract(const Duration(days: 10)),
      );
      final reminders = buildDueReminders(
        dues: [due],
        customerNameOf: (_) => 'Karim',
        now: now,
      );
      expect(reminders, isEmpty);
    });
  });

  group('deriveFirstInvestmentDate', () {
    test('finds the earliest trip funding this investor', () {
      final trips = [
        _tripFundedBy('investor-1', DateTime.utc(2026, 3, 1)),
        _tripFundedBy('investor-1', DateTime.utc(2026, 1, 15)),
        _tripFundedBy('other-investor', DateTime.utc(2025, 1, 1)),
      ];
      final date = deriveFirstInvestmentDate(
        investorId: 'investor-1',
        purchaseTrips: trips,
      );
      expect(date, DateTime.utc(2026, 1, 15));
    });

    test('null when the investor has never funded a purchase', () {
      final date = deriveFirstInvestmentDate(
        investorId: 'investor-1',
        purchaseTrips: const [],
      );
      expect(date, isNull);
    });
  });

  group('buildInvestorReminders', () {
    test('capital-return reminder counts from the first investment date', () {
      final investor = Investor(
        id: 'investor-1',
        name: 'Uncle Karim',
        investmentType: InvestmentType.cashLoan,
        capitalReturnTermDays: 30,
        // Isolates this test to just the capital-return reminder — the
        // default cycle is `monthly`, which would otherwise also produce
        // a payout reminder here.
        profitPayoutCycle: ProfitPayoutCycle.perContract,
      );
      final trips = [_tripFundedBy('investor-1', DateTime.utc(2026, 7, 8))];

      final reminders = buildInvestorReminders(
        investors: [investor],
        purchaseTrips: trips,
        now: now, // 2026-08-05; due date is 2026-08-07, within 3-day window
      );

      expect(reminders, hasLength(1));
      final reminder = reminders.single as InvestorCapitalReturnReminder;
      expect(reminder.dueDate, DateTime.utc(2026, 8, 7));
      expect(reminder.isOverdueAsOf(now), isFalse);
    });

    test(
      'no reminder for an investor with no capitalReturnTermDays and a non-monthly cycle',
      () {
        final investor = Investor(
          id: 'investor-1',
          name: 'Uncle Karim',
          investmentType: InvestmentType.cashMudaraba,
          profitPayoutCycle: ProfitPayoutCycle.daily,
        );
        final trips = [_tripFundedBy('investor-1', DateTime.utc(2026, 1, 1))];
        final reminders = buildInvestorReminders(
          investors: [investor],
          purchaseTrips: trips,
          now: now,
        );
        expect(reminders, isEmpty);
      },
    );

    test(
      'no reminder for perContract payout (covered by capital return instead)',
      () {
        final investor = Investor(
          id: 'investor-1',
          name: 'Uncle Karim',
          investmentType: InvestmentType.cashMudaraba,
          profitPayoutCycle: ProfitPayoutCycle.perContract,
        );
        final trips = [_tripFundedBy('investor-1', DateTime.utc(2026, 1, 1))];
        final reminders = buildInvestorReminders(
          investors: [investor],
          purchaseTrips: trips,
          now: now,
        );
        expect(reminders, isEmpty);
      },
    );

    test('monthly payout reminder is the next on-or-after anniversary', () {
      final investor = Investor(
        id: 'investor-1',
        name: 'Uncle Karim',
        investmentType: InvestmentType.cashMudaraba,
        profitPayoutCycle: ProfitPayoutCycle.monthly,
      );
      final trips = [_tripFundedBy('investor-1', DateTime.utc(2026, 1, 6))];

      final reminders = buildInvestorReminders(
        investors: [investor],
        purchaseTrips: trips,
        now: now, // 2026-08-05; next 6th is 2026-08-06, within 3-day window
      );

      expect(reminders, hasLength(1));
      final reminder = reminders.single as InvestorProfitPayoutReminder;
      expect(reminder.dueDate, DateTime.utc(2026, 8, 6));
    });

    test(
      'monthly payout reminder rolls to next month once this month\'s anniversary has passed',
      () {
        final investor = Investor(
          id: 'investor-1',
          name: 'Uncle Karim',
          investmentType: InvestmentType.cashMudaraba,
          profitPayoutCycle: ProfitPayoutCycle.monthly,
        );
        final trips = [_tripFundedBy('investor-1', DateTime.utc(2026, 1, 1))];

        final reminders = buildInvestorReminders(
          investors: [investor],
          purchaseTrips: trips,
          now: now, // 2026-08-05; the 1st already passed this month
          upcomingWithinDays: 90,
        );

        final reminder = reminders.single as InvestorProfitPayoutReminder;
        expect(reminder.dueDate, DateTime.utc(2026, 9, 1));
      },
    );

    test('no reminder for an investor who has never actually invested', () {
      final investor = Investor(
        id: 'investor-1',
        name: 'Uncle Karim',
        investmentType: InvestmentType.cashLoan,
        capitalReturnTermDays: 30,
      );
      final reminders = buildInvestorReminders(
        investors: [investor],
        purchaseTrips: const [],
        now: now,
      );
      expect(reminders, isEmpty);
    });
  });

  group('buildSuspiciousCustomerReminders', () {
    test('one reminder per flagged customer, none for the rest', () {
      final customers = [
        const Customer(id: 'c1', name: 'Flagged', suspicionFlag: true),
        const Customer(id: 'c2', name: 'Fine', suspicionFlag: false),
      ];
      final reminders = buildSuspiciousCustomerReminders(customers: customers);
      expect(reminders, hasLength(1));
      expect(reminders.single.customer.id, 'c1');
      expect(reminders.single.dueDate, isNull);
      expect(reminders.single.isOverdueAsOf(now), isTrue);
    });
  });

  group('buildOverdueRentReminders', () {
    test('flags an active rental past its due date', () {
      final rent = _rent(
        id: 'rent-1',
        dueDate: now.subtract(const Duration(days: 2)),
      );
      final reminders = buildOverdueRentReminders(
        rentals: [rent],
        bookNameOf: (_) => 'Book A',
        customerNameOf: (_) => 'Karim',
        now: now,
      );
      expect(reminders, hasLength(1));
      expect(reminders.single.bookName, 'Book A');
      expect(reminders.single.extraDaysAsOf(now), 2);
    });

    test('excludes a rental still within its due date', () {
      final rent = _rent(
        id: 'rent-1',
        dueDate: now.add(const Duration(days: 2)),
      );
      final reminders = buildOverdueRentReminders(
        rentals: [rent],
        bookNameOf: (_) => 'Book A',
        customerNameOf: (_) => 'Karim',
        now: now,
      );
      expect(reminders, isEmpty);
    });

    test('excludes an already-returned rental even if past its due date', () {
      final rent = _rent(
        id: 'rent-1',
        dueDate: now.subtract(const Duration(days: 2)),
        status: RentStatus.returned,
      );
      final reminders = buildOverdueRentReminders(
        rentals: [rent],
        bookNameOf: (_) => 'Book A',
        customerNameOf: (_) => 'Karim',
        now: now,
      );
      expect(reminders, isEmpty);
    });
  });

  group('buildOrderDeadlineReminders', () {
    test('reminds for a pending order whose deadline already passed', () {
      final order = _order(
        id: 'order-1',
        neededByDate: now.subtract(const Duration(days: 1)),
      );
      final reminders = buildOrderDeadlineReminders(
        orders: [order],
        customerNameOf: (_) => 'Karim',
        now: now,
      );
      expect(reminders, hasLength(1));
      expect(reminders.single.customerName, 'Karim');
      expect(reminders.single.isOverdueAsOf(now), isTrue);
    });

    test(
      'includes an order deadline within the upcoming window but not overdue yet',
      () {
        final order = _order(
          id: 'order-1',
          neededByDate: now.add(const Duration(days: 2)),
        );
        final reminders = buildOrderDeadlineReminders(
          orders: [order],
          customerNameOf: (_) => 'Karim',
          now: now,
          upcomingWithinDays: 3,
        );
        expect(reminders, hasLength(1));
        expect(reminders.single.isOverdueAsOf(now), isFalse);
      },
    );

    test('excludes an order deadline far outside the upcoming window', () {
      final order = _order(
        id: 'order-1',
        neededByDate: now.add(const Duration(days: 30)),
      );
      final reminders = buildOrderDeadlineReminders(
        orders: [order],
        customerNameOf: (_) => 'Karim',
        now: now,
        upcomingWithinDays: 3,
      );
      expect(reminders, isEmpty);
    });

    test('excludes an order with no neededByDate set', () {
      final order = _order(id: 'order-1', neededByDate: null);
      final reminders = buildOrderDeadlineReminders(
        orders: [order],
        customerNameOf: (_) => 'Karim',
        now: now,
      );
      expect(reminders, isEmpty);
    });

    test('excludes a fulfilled order even if its deadline already passed', () {
      final order = _order(
        id: 'order-1',
        neededByDate: now.subtract(const Duration(days: 1)),
        status: OrderStatus.fulfilled,
      );
      final reminders = buildOrderDeadlineReminders(
        orders: [order],
        customerNameOf: (_) => 'Karim',
        now: now,
      );
      expect(reminders, isEmpty);
    });

    test('excludes a cancelled order even if its deadline already passed', () {
      final order = _order(
        id: 'order-1',
        neededByDate: now.subtract(const Duration(days: 1)),
        status: OrderStatus.cancelled,
      );
      final reminders = buildOrderDeadlineReminders(
        orders: [order],
        customerNameOf: (_) => 'Karim',
        now: now,
      );
      expect(reminders, isEmpty);
    });
  });

  group('buildReminderInbox', () {
    test(
      'pins the no-date suspicious-customer reminder first, then sorts by date',
      () {
        final overdueDue = _due(
          id: 'due-1',
          promisedDays: 1,
          createdAt: now.subtract(const Duration(days: 5)),
        );
        final upcomingRent = _rent(
          id: 'rent-1',
          dueDate: now.subtract(const Duration(days: 1)),
        );
        final customers = [
          const Customer(id: 'c1', name: 'Flagged', suspicionFlag: true),
        ];

        final inbox = buildReminderInbox(
          dues: [overdueDue],
          customerNameOf: (_) => 'Karim',
          investors: const [],
          purchaseTrips: const [],
          customers: customers,
          rentals: [upcomingRent],
          bookNameOf: (_) => 'Book A',
          orders: const [],
          now: now,
        );

        expect(inbox, hasLength(3));
        expect(inbox.first, isA<SuspiciousCustomerReminder>());
        // The rent (due 1 day ago) sorts before the due (due 4 days ago is
        // *earlier*, so it actually sorts first among the dated ones).
        expect(inbox[1].dueDate!.isBefore(inbox[2].dueDate!), isTrue);
      },
    );

    test('includes an order deadline reminder alongside the others', () {
      final overdueOrder = _order(
        id: 'order-1',
        neededByDate: now.subtract(const Duration(days: 1)),
      );

      final inbox = buildReminderInbox(
        dues: const [],
        customerNameOf: (_) => 'Karim',
        investors: const [],
        purchaseTrips: const [],
        customers: const [],
        rentals: const [],
        bookNameOf: (_) => 'Book A',
        orders: [overdueOrder],
        now: now,
      );

      expect(inbox, hasLength(1));
      expect(inbox.single, isA<OrderDeadlineReminder>());
      expect(inbox.single.isOverdueAsOf(now), isTrue);
    });

    test('empty when nothing needs attention', () {
      final inbox = buildReminderInbox(
        dues: const [],
        customerNameOf: (_) => '',
        investors: const [],
        purchaseTrips: const [],
        customers: const [],
        rentals: const [],
        bookNameOf: (_) => '',
        orders: const [],
        now: now,
      );
      expect(inbox, isEmpty);
    });
  });
}
