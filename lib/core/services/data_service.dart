import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:get/get.dart' hide Value;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/app_database.dart';

class DataService {
  final AppDatabase _db;
  DataService(this._db);

  Future<void> exportData() async {
    try {
      final products = await _db.select(_db.products).get();
      final sales = await _db.select(_db.sales).get();
      final customers = await _db.select(_db.customers).get();
      final expenses = await _db.select(_db.expenses).get();
      final purchases = await _db.select(_db.purchases).get();
      final investors = await _db.select(_db.investors).get();
      final assets = await _db.select(_db.fixedAssets).get();
      final captures = await _db.select(_db.quickCaptures).get();
      final rentBooks = await _db.select(_db.rentBooks).get();
      final bookRentals = await _db.select(_db.bookRentals).get();

      final payload = {
        'version': 3,
        'exportedAt': DateTime.now().toIso8601String(),
        'products': products.map((p) => p.toJson()).toList(),
        'sales': sales.map((s) => s.toJson()).toList(),
        'customers': customers.map((c) => c.toJson()).toList(),
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'purchases': purchases.map((p) => p.toJson()).toList(),
        'investors': investors.map((i) => i.toJson()).toList(),
        'assets': assets.map((a) => a.toJson()).toList(),
        'captures': captures.map((c) => c.toJson()).toList(),
        'rentBooks': rentBooks.map((r) => r.toJson()).toList(),
        'bookRentals': bookRentals.map((r) => r.toJson()).toList(),
      };

      final jsonStr = const JsonEncoder.withIndent('  ').convert(payload);
      final dir = await getApplicationDocumentsDirectory();
      final fileName =
          'backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(jsonStr);

      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'backupCopied'.tr),
      );
      Get.snackbar(
        '',
        'backupCopied'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar(
        '',
        'Export failed: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> importData() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final files = dir
          .listSync()
          .where((f) => f.path.endsWith('.json'))
          .toList();
      if (files.isEmpty) {
        Get.snackbar(
          '',
          'importFailed'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      final selected = await Get.dialog<String>(
        SimpleDialog(
          title: Text('importData'.tr),
          children: files.map((f) {
            final name = f.path.split(Platform.pathSeparator).last;
            return SimpleDialogOption(
              child: Text(name),
              onPressed: () => Get.back(result: f.path),
            );
          }).toList(),
        ),
      );
      if (selected == null) return;

      final jsonStr = await File(selected).readAsString();
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      // Clear all tables
      await _db.delete(_db.products).go();
      await _db.delete(_db.sales).go();
      await _db.delete(_db.customers).go();
      await _db.delete(_db.ledgerEntries).go();
      await _db.delete(_db.expenses).go();
      await _db.delete(_db.purchases).go();
      await _db.delete(_db.investors).go();
      await _db.delete(_db.fixedAssets).go();
      await _db.delete(_db.quickCaptures).go();
      await _db.delete(_db.rentBooks).go();
      await _db.delete(_db.bookRentals).go();

      // Use raw inserts via customStatement for each table
      final batch = _db.batch((b) {
        for (final p in (data['products'] as List? ?? [])) {
          final m = p as Map<String, dynamic>;
          b.insert(
            _db.products,
            ProductsCompanion.insert(
              id: m['id']?.toString() ?? '',
              name: m['name']?.toString() ?? '',
              category: Value(m['category']?.toString() ?? ''),
              investor: Value(m['investor']?.toString() ?? 'Own Shop'),
              buyQty: Value(_d(m['buyQty'])),
              buyUnit: Value(m['buyUnit']?.toString() ?? 'pcs'),
              buyPrice: Value(_d(m['buyPrice'])),
              sellUnit: Value(m['sellUnit']?.toString() ?? 'pcs'),
              sellPrice: Value(_d(m['sellPrice'])),
              qty: Value(_d(m['qty'])),
              buyConversionFactor: Value(_d(m['buyConversionFactor'], 1)),
              sellConversionFactor: Value(_d(m['sellConversionFactor'], 1)),
              date: m['date']?.toString() ?? '',
              imagePath: Value(m['imagePath']?.toString() ?? ''),
            ),
          );
        }
        for (final s in (data['sales'] as List? ?? [])) {
          final m = s as Map<String, dynamic>;
          b.insert(
            _db.sales,
            SalesCompanion.insert(
              id: m['id']?.toString() ?? '',
              date: m['date']?.toString() ?? '',
              productName: m['productName']?.toString() ?? '',
              amount: _d(m['amount']),
              profit: Value(_d(m['profit'])),
              type: Value(m['type']?.toString() ?? 'cash'),
            ),
          );
        }
        for (final c in (data['customers'] as List? ?? [])) {
          final m = c as Map<String, dynamic>;
          b.insert(
            _db.customers,
            CustomersCompanion.insert(
              id: m['id']?.toString() ?? '',
              name: m['name']?.toString() ?? '',
              phone: Value(m['phone']?.toString() ?? ''),
              whatsapp: Value(m['whatsapp']?.toString() ?? ''),
              imagePath: Value(m['imagePath']?.toString() ?? ''),
              note: Value(m['note']?.toString() ?? ''),
              address: Value(m['address']?.toString() ?? ''),
              type: Value(m['type']?.toString() ?? 'buyer'),
            ),
          );
        }
        for (final e in (data['expenses'] as List? ?? [])) {
          final m = e as Map<String, dynamic>;
          b.insert(
            _db.expenses,
            ExpensesCompanion.insert(
              id: m['id']?.toString() ?? '',
              title: m['title']?.toString() ?? '',
              amount: _d(m['amount']),
              date: m['date']?.toString() ?? '',
              type: Value(m['type']?.toString() ?? 'misc'),
              billPath: Value(m['billPath']?.toString() ?? ''),
              note: Value(m['note']?.toString() ?? ''),
              vendor: Value(m['vendor']?.toString() ?? ''),
              paymentMethod: Value(m['paymentMethod']?.toString() ?? 'Cash'),
              isPaid: Value(m['isPaid'] == true),
              recurringType: Value(m['recurringType']?.toString() ?? 'none'),
            ),
          );
        }
        for (final i in (data['investors'] as List? ?? [])) {
          final m = i as Map<String, dynamic>;
          b.insert(
            _db.investors,
            InvestorsCompanion.insert(
              id: m['id']?.toString() ?? '',
              name: m['name']?.toString() ?? '',
              investedAmount: Value(_d(m['investedAmount'])),
              durationMonths: Value(
                (m['durationMonths'] as num?)?.toInt() ?? 12,
              ),
              profitPercentage: Value(_d(m['profitPercentage'])),
              contractType: Value(
                m['contractType']?.toString() ?? 'profitShare',
              ),
              investmentType: Value(m['investmentType']?.toString() ?? 'cash'),
              startDate: Value(m['startDate']?.toString() ?? ''),
              cashInvested: Value(_d(m['cashInvested'])),
              productInvested: Value(_d(m['productInvested'])),
            ),
          );
        }
        for (final a in (data['assets'] as List? ?? [])) {
          final m = a as Map<String, dynamic>;
          b.insert(
            _db.fixedAssets,
            FixedAssetsCompanion.insert(
              id: m['id']?.toString() ?? '',
              name: m['name']?.toString() ?? '',
              estimatedValue: _d(m['estimatedValue']),
              purchaseDate: m['purchaseDate']?.toString() ?? '',
              imagePath: Value(m['imagePath']?.toString() ?? ''),
            ),
          );
        }
        for (final c in (data['captures'] as List? ?? [])) {
          final m = c as Map<String, dynamic>;
          b.insert(
            _db.quickCaptures,
            QuickCapturesCompanion.insert(
              id: m['id']?.toString() ?? '',
              timestamp: m['timestamp']?.toString() ?? '',
              note: m['note']?.toString() ?? '',
              imagePath: Value(m['imagePath']?.toString() ?? ''),
              source: Value(m['source']?.toString() ?? ''),
            ),
          );
        }
      });
      await batch;

      Get.snackbar(
        '',
        'dataImported'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        '',
        'Import failed: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> seedSampleData() async {
    try {
      final today = DateFormat('dd-MM-yyyy').format(DateTime.now());
      await _db
          .into(_db.products)
          .insert(
            ProductsCompanion.insert(
              id: 'seed_p1',
              name: 'Miswak Premium',
              category: const Value('Miswak'),
              buyQty: const Value(100),
              buyPrice: const Value(20),
              sellPrice: const Value(30),
              qty: const Value(95),
              date: today,
            ),
          );
      await _db
          .into(_db.products)
          .insert(
            ProductsCompanion.insert(
              id: 'seed_p2',
              name: 'Rose Attar',
              category: const Value('Attar'),
              buyQty: const Value(20),
              buyUnit: const Value('litre'),
              buyPrice: const Value(2000),
              sellUnit: const Value('ml'),
              sellPrice: const Value(250),
              qty: const Value(19000),
              buyConversionFactor: const Value(1000),
              date: today,
            ),
          );
      await _db
          .into(_db.products)
          .insert(
            ProductsCompanion.insert(
              id: 'seed_p3',
              name: 'Medjoul Dates',
              category: const Value('Date'),
              buyQty: const Value(50),
              buyUnit: const Value('kg'),
              buyPrice: const Value(300),
              sellUnit: const Value('kg'),
              sellPrice: const Value(450),
              qty: const Value(47),
              date: today,
            ),
          );
      await _db
          .into(_db.sales)
          .insert(
            SalesCompanion.insert(
              id: 'seed_s1',
              date: today,
              productName: 'Miswak Premium',
              amount: 150,
              profit: const Value(50),
            ),
          );
      await _db
          .into(_db.sales)
          .insert(
            SalesCompanion.insert(
              id: 'seed_s2',
              date: today,
              productName: 'Rose Attar',
              amount: 500,
              profit: const Value(150),
            ),
          );
      await _db
          .into(_db.customers)
          .insert(
            CustomersCompanion.insert(
              id: 'seed_c1',
              name: 'Ahmed Khan',
              phone: const Value('03001234567'),
              type: const Value('buyer'),
              note: const Value('Regular buyer'),
            ),
          );
      await _db
          .into(_db.ledgerEntries)
          .insert(
            LedgerEntriesCompanion.insert(
              customerId: 'seed_c1',
              date: today,
              amount: 2000,
              type: 'due',
              itemName: const Value('Assorted Dates'),
            ),
          );
      await _db
          .into(_db.expenses)
          .insert(
            ExpensesCompanion.insert(
              id: 'seed_e1',
              title: 'Shop Rent',
              amount: 15000,
              date: today,
              type: const Value('fixed'),
              vendor: const Value('Landlord'),
              isPaid: const Value(true),
            ),
          );
      await _db
          .into(_db.fixedAssets)
          .insert(
            FixedAssetsCompanion.insert(
              id: 'seed_a1',
              name: 'Display Fridge',
              estimatedValue: 45000,
              purchaseDate: today,
            ),
          );

      Get.snackbar(
        '',
        'seedDone'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar(
        '',
        'Seed failed: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  double _d(dynamic v, [double fallback = 0.0]) =>
      v == null ? fallback : (double.tryParse(v.toString()) ?? fallback);
}
