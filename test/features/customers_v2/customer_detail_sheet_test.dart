import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:inventory/app/translations/app_translations.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/domain/entities/customer.dart';
import 'package:inventory/domain/entities/due.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:inventory/domain/entities/fund_source.dart';
import 'package:inventory/domain/entities/order.dart';
import 'package:inventory/domain/entities/product.dart';
import 'package:inventory/domain/entities/rent_transaction.dart';
import 'package:inventory/domain/entities/sale.dart';
import 'package:inventory/features/customers_v2/controller/customers_controller.dart';
import 'package:inventory/features/customers_v2/view/customer_detail_sheet.dart';

void main() {
  testWidgets('shows one customer complete transaction history', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final controller = CustomersController(db);
    addTearDown(db.close);

    const customer = Customer(id: 'c1', name: 'Karim');
    controller.products.value = [
      Product(
        id: 'p1',
        name: 'Book One',
        category: 'Book',
        costPrice: Money.fromMinor(5000),
        suggestedSellPrice: Money.fromMinor(7000),
        qty: 3,
        fundSource: FundSource.shop(),
      ),
    ];
    controller.sales.value = [
      Sale(
        id: 's1',
        productId: 'p1',
        qty: 2,
        actualSellPrice: Money.fromMinor(7000),
        costPriceAtSale: Money.fromMinor(5000),
        date: DateTime.utc(2026, 8, 17),
        customerId: customer.id,
        paymentStatus: PaymentStatus.partial,
        paymentMethod: PaymentMethod.cash,
        fundSource: FundSource.shop(),
      ),
    ];
    controller.dues.value = [
      Due(
        id: 'd1',
        customerId: customer.id,
        sourceType: DueSourceType.sale,
        sourceId: 's1',
        originalAmount: Money.fromMinor(4000),
        paidAmount: Money.fromMinor(1000),
        status: DueStatus.partiallyPaid,
        createdAt: DateTime.utc(2026, 8, 17),
      ),
    ];
    controller.rentals.value = [
      RentTransaction(
        id: 'r1',
        bookProductId: 'p1',
        customerId: customer.id,
        startDate: DateTime.utc(2026, 8, 10),
        dueDate: DateTime.utc(2026, 8, 20),
        deposit: Money.zero(),
        rentPrice: Money.fromMinor(500),
        status: RentStatus.active,
      ),
    ];
    controller.orders.value = [
      Order(
        id: 'o1',
        customerId: customer.id,
        itemDescription: 'Special edition',
        requestedDate: DateTime.utc(2026, 8, 16),
        status: OrderStatus.pending,
      ),
    ];

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: Scaffold(
          body: CustomerDetailSheet(
            customer: customer,
            onEdit: () {},
            controllerOverride: controller,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Karim'), findsOneWidget);
    expect(find.text('Book One'), findsNWidgets(2));
    expect(find.text('Special edition'), findsOneWidget);
    expect(find.text('Outstanding due'), findsOneWidget);
    expect(find.text(Money.fromMinor(3000).format()), findsNWidgets(2));
  });
}
