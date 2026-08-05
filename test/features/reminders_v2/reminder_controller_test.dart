import 'package:drift/native.dart';
import 'package:inventory/core/notifications/notification_service.dart';
import 'package:inventory/core/platform/capabilities.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/usecases/customer_usecases.dart';
import 'package:inventory/data/usecases/investor_usecases.dart';
import 'package:inventory/data/usecases/order_usecases.dart';
import 'package:inventory/domain/entities/customer.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/domain/entities/investor.dart';
import 'package:inventory/domain/services/reminder_engine.dart';
import 'package:inventory/features/reminders_v2/controller/reminder_controller.dart';
import 'package:test/test.dart';

/// `hasNotifications: false` so [NotificationService]'s methods are pure
/// no-ops here — a real Android platform channel isn't available under
/// plain `dart test`, and the point of this test file is the reminder
/// computation/wiring, not the notification plugin itself.
const _noNotifications = PlatformCapabilities(
  isWeb: false,
  isAndroid: false,
  isWindows: false,
  isDesktop: false,
  hasCamera: false,
  hasMicrophone: false,
  hasFileSystemAccess: false,
  hasNotifications: false,
);

void main() {
  late AppDatabase db;
  late ReminderController controller;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    controller = ReminderController(db, NotificationService(_noNotifications));
    controller.onInit();
    await Future<void>.delayed(Duration.zero);
  });

  tearDown(() async {
    controller.onClose();
    await db.close();
  });

  test('inbox is empty with no data', () {
    expect(controller.inbox, isEmpty);
  });

  test('a suspicious customer surfaces in the inbox', () async {
    await CustomerUseCases(db).create(
      const Customer(id: 'c1', name: 'Flagged Customer', suspicionFlag: true),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
    await Future<void>.delayed(Duration.zero);

    final inbox = controller.inbox;
    expect(inbox, hasLength(1));
    expect(inbox.single, isA<SuspiciousCustomerReminder>());
  });

  test(
    'overdueOnly only includes reminders that are actually overdue',
    () async {
      await CustomerUseCases(db).create(
        const Customer(id: 'c1', name: 'Fine Customer'),
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.overdueOnly, isEmpty);

      await CustomerUseCases(db).update(
        const Customer(id: 'c1', name: 'Fine Customer', suspicionFlag: true),
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );
      await Future<void>.delayed(Duration.zero);

      // A suspicious-customer reminder is always "overdue" (no date, always
      // active) per its own class doc comment.
      expect(controller.overdueOnly, hasLength(1));
    },
  );

  test(
    'investors with no derivable first-investment date produce no reminder',
    () async {
      await InvestorUseCases(db).create(
        const Investor(
          id: 'investor-1',
          name: 'Uncle Karim',
          investmentType: InvestmentType.cashLoan,
          capitalReturnTermDays: 30,
        ),
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.inbox, isEmpty);
    },
  );

  test('a pending order past its neededByDate surfaces in the inbox', () async {
    await CustomerUseCases(db).create(
      const Customer(id: 'c1', name: 'Karim'),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
    await OrderUseCases(db).create(
      customerId: 'c1',
      itemDescription: 'A red backpack',
      requestedDate: DateTime.now().toUtc().subtract(const Duration(days: 5)),
      neededByDate: DateTime.now().toUtc().subtract(const Duration(days: 1)),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
    await Future<void>.delayed(Duration.zero);

    final inbox = controller.inbox;
    expect(inbox, hasLength(1));
    expect(inbox.single, isA<OrderDeadlineReminder>());
    expect(controller.overdueOnly, hasLength(1));
  });

  test('a fulfilled order past its neededByDate does not surface, even though '
      'the order itself is still in the live list', () async {
    await CustomerUseCases(db).create(
      const Customer(id: 'c1', name: 'Karim'),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
    await OrderUseCases(db).create(
      customerId: 'c1',
      itemDescription: 'A red backpack',
      requestedDate: DateTime.now().toUtc().subtract(const Duration(days: 5)),
      neededByDate: DateTime.now().toUtc().subtract(const Duration(days: 1)),
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
    final orderId = (await (db.select(db.orders)).get()).single.id;
    await OrderUseCases(db).updateStatus(
      orderId: orderId,
      status: OrderStatus.fulfilled,
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
    await Future<void>.delayed(Duration.zero);

    expect(controller.inbox, isEmpty);
  });
}
