import 'package:drift/native.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/features/expense_v2/controller/expense_controller.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabaseV2 db;
  late ExpenseController controller;

  setUp(() {
    db = AppDatabaseV2.forTesting(NativeDatabase.memory());
    controller = ExpenseController(db);
    controller.onInit();
  });

  tearDown(() async {
    controller.onClose();
    await db.close();
  });

  test(
    'addExpense adds a visible expense and clears any prior error',
    () async {
      final ok = await controller.addExpense(
        category: ExpenseCategory.monthlyRent,
        amount: Money.fromMinor(500000),
        paymentMethod: PaymentMethod.cash,
        description: 'August rent',
      );
      await Future<void>.delayed(Duration.zero);

      expect(ok, isTrue);
      expect(controller.errorMessage.value, isNull);
      expect(controller.expenses, hasLength(1));
      expect(controller.expenses.single.category, ExpenseCategory.monthlyRent);
      expect(controller.expenses.single.description, 'August rent');
    },
  );

  test('addExpense rejects a zero amount and surfaces the error', () async {
    final ok = await controller.addExpense(
      category: ExpenseCategory.dailyOther,
      amount: Money.zero(),
      paymentMethod: PaymentMethod.cash,
    );
    await Future<void>.delayed(Duration.zero);

    expect(ok, isFalse);
    expect(controller.errorMessage.value, isNotNull);
    expect(controller.expenses, isEmpty);
  });

  test('deleteExpense removes it from the visible list', () async {
    await controller.addExpense(
      category: ExpenseCategory.dailyOther,
      amount: Money.fromMinor(1000),
      paymentMethod: PaymentMethod.cash,
    );
    await Future<void>.delayed(Duration.zero);
    expect(controller.expenses, hasLength(1));

    await controller.deleteExpense(controller.expenses.single.id);
    await Future<void>.delayed(Duration.zero);

    expect(controller.expenses, isEmpty);
  });
}
