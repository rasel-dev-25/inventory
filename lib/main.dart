import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'sales_notifier.dart';
import 'models.dart';
import 'quick_capture.dart';
import 'shop_logo.dart';

import 'inventory_screen.dart';
import 'dues_screen.dart';
import 'finance_screen.dart';
import 'investor_screen.dart';
import 'customers.dart';
import 'assets_screen.dart';
import 'lang.dart' as lang;
import 'constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Directory hiveDir;
  try {
    hiveDir = await getApplicationDocumentsDirectory();
    final probe = File('${hiveDir.path}/.hive_write_probe');
    await probe.create();
    await probe.delete();
  } catch (_) {
    hiveDir = await getApplicationSupportDirectory();
  }
  await hiveDir.create(recursive: true);
  Hive.init(hiveDir.path);
  await Hive.openBox('inventoryBox');
  await Hive.openBox('duesBox');
  await Hive.openBox('financeBox');
  await Hive.openBox('investorBox');
  await Hive.openBox('assetsBox');
  await Hive.openBox('salesBox');
  await Hive.openBox('quickBox');
  await Hive.openBox('settingsBox');

  final settingsBox = Hive.box('settingsBox');
  final isDark = settingsBox.get('isDark', defaultValue: false) as bool;

  final salesBox = Hive.box('salesBox');
  final duesBox = Hive.box('duesBox');
  final storedSales = salesBox.get('sales', defaultValue: []);
  double totalCash = 0.0;
  double totalProfit = 0.0;
  double todayDue = 0.0;
  for (var sale in storedSales) {
    totalCash += (sale['amount']?.toDouble() ?? 0.0);
    totalProfit += (sale['profit']?.toDouble() ?? 0.0);
  }

  final storedCustomers = duesBox.get('customers', defaultValue: []);
  String today = DateFormat('dd-MM-yyyy').format(DateTime.now());
  for (var customer in storedCustomers) {
    final ledger = customer['ledger'] ?? [];
    for (var entry in ledger) {
      if (entry['date']?.toString() == today) {
        double amt = (entry['amount']?.toDouble() ?? 0.0);
        todayDue += (entry['type'] == 'payment') ? -amt : amt;
      }
    }
  }

  salesNotifier.value = {'cash': totalCash, 'profit': totalProfit};

  final themeNotifier = ValueNotifier<bool>(isDark);

  runApp(MyApp(todayDue: todayDue, themeNotifier: themeNotifier));
}

class MyApp extends StatelessWidget {
  final double todayDue;
  final ValueNotifier<bool> themeNotifier;
  const MyApp({super.key, this.todayDue = 0.0, required this.themeNotifier});

  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: kTeal,
      colorScheme: ColorScheme.fromSeed(
        seedColor: kTeal,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: kTeal.withValues(alpha: 0.25),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        color: const Color(0xFF1E1E1E),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Color(0xFF00695C),
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kTeal, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        labelStyle: TextStyle(color: Colors.grey.shade400),
        hintStyle: TextStyle(color: Colors.grey.shade600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 1,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: kTeal,
          foregroundColor: Colors.white,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
        backgroundColor: const Color(0xFF2C2C2C),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        elevation: 8,
        selectedItemColor: kTeal,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Color(0xFF1E1E1E),
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
      dividerColor: Colors.grey.shade800,
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: Colors.grey.shade200),
        bodyMedium: TextStyle(color: Colors.grey.shade300),
        titleMedium: TextStyle(color: Colors.grey.shade100),
        labelLarge: TextStyle(color: Colors.grey.shade200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: lang.localeNotifier,
      builder: (context, locale, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: themeNotifier,
          builder: (context, isDark, _) {
            return MaterialApp(
              title: lang.Lang.tr('appTitle'),
              debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primaryColor: kTeal,
            colorScheme: ColorScheme.fromSeed(
              seedColor: kTeal,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            cardTheme: CardThemeData(
              elevation: 2,
              shadowColor: kTeal.withValues(alpha: 0.15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              clipBehavior: Clip.antiAlias,
            ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 8,
            ),
            appBarTheme: const AppBarTheme(
              elevation: 0,
              centerTitle: true,
              backgroundColor: kTeal,
              foregroundColor: Colors.white,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: kTeal, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                elevation: 1,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                backgroundColor: kTeal,
                foregroundColor: Colors.white,
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            chipTheme: ChipThemeData(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: BorderSide.none,
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              elevation: 8,
              selectedItemColor: kTeal,
              unselectedItemColor: Colors.grey,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              unselectedLabelStyle: TextStyle(fontSize: 11),
            ),
          ),
          darkTheme: _buildDarkTheme(),
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          home: MainNavigationScreen(todayDue: todayDue, themeNotifier: themeNotifier),
        );
      },
    );
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  final double todayDue;
  final ValueNotifier<bool> themeNotifier;
  const MainNavigationScreen({super.key, this.todayDue = 0.0, required this.themeNotifier});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime? _lastBackPress;
  bool _showOtherActivities = false;
  DateTime? _selectedDate;

  void _switchTab(int index) { setState(() { _currentIndex = index; }); }

  void _openDrawer() { _scaffoldKey.currentState?.openDrawer(); }

  void _toggleDarkMode(bool val) {
    Hive.box('settingsBox').put('isDark', val);
    widget.themeNotifier.value = val;
  }

  Future<void> _exportData() async {
    Navigator.pop(context);
    try {
      final boxNames = ['salesBox', 'inventoryBox', 'duesBox', 'financeBox', 'investorBox', 'assetsBox', 'quickBox', 'settingsBox'];
      final boxes = <String, Map<String, dynamic>>{};
      for (final name in boxNames) {
        final box = Hive.box(name);
        boxes[name] = Map<String, dynamic>.from(box.toMap().map((k, v) => MapEntry(k.toString(), v)));
      }
      // Collect image files as base64
      final images = <String, String>{};
      final imagePaths = <String>[];

      // Collect from inventory products
      final products = boxes['inventoryBox']?['products'] as List? ?? [];
      for (final p in products) {
        final path = (p as Map)['imagePath']?.toString() ?? '';
        if (path.isNotEmpty && !imagePaths.contains(path)) imagePaths.add(path);
      }

      // Collect from customers
      final customers = boxes['duesBox']?['customers'] as List? ?? [];
      for (final c in customers) {
        final path = (c as Map)['imagePath']?.toString() ?? '';
        if (path.isNotEmpty && !imagePaths.contains(path)) imagePaths.add(path);
      }

      // Collect from assets
      final assets = boxes['assetsBox']?['assets'] as List? ?? [];
      for (final a in assets) {
        final path = (a as Map)['imagePath']?.toString() ?? '';
        if (path.isNotEmpty && !imagePaths.contains(path)) imagePaths.add(path);
      }

      // Collect from expenses (bill images)
      final expenses = boxes['financeBox']?['expenses'] as List? ?? [];
      for (final e in expenses) {
        final path = (e as Map)['billPath']?.toString() ?? '';
        if (path.isNotEmpty && !imagePaths.contains(path)) imagePaths.add(path);
      }

      // Collect from purchases (memo photos)
      final purchases = boxes['financeBox']?['purchases'] as List? ?? [];
      for (final pu in purchases) {
        final path = (pu as Map)['memoPhotoPath']?.toString() ?? '';
        if (path.isNotEmpty && !imagePaths.contains(path)) imagePaths.add(path);
      }

      // Collect from quick captures
      final captures = boxes['quickBox']?['captures'] as List? ?? [];
      for (final cap in captures) {
        final path = (cap as Map)['imagePath']?.toString() ?? '';
        if (path.isNotEmpty && !imagePaths.contains(path)) imagePaths.add(path);
      }

      for (final path in imagePaths) {
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          images[path] = base64Encode(bytes);
        }
      }

      final payload = {
        'version': 2,
        'exportedAt': DateTime.now().toIso8601String(),
        'boxes': boxes,
        'images': images,
      };
      final jsonStr = const JsonEncoder.withIndent('  ').convert(payload);
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(jsonStr);

      // Share file → user can save to Downloads via share sheet
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: lang.Lang.tr('backupCopied')),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.Lang.tr('backupCopied')),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _importData() async {
    Navigator.pop(context);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final files = dir.listSync().where((f) => f.path.endsWith('.json')).toList();
      if (files.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(lang.Lang.tr('importFailed')), backgroundColor: Colors.orange),
        );
        return;
      }
      // Let user pick which backup to restore
      if (!mounted) return;
      final selected = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: Text(lang.Lang.tr('importData')),
          children: files.map((f) {
            final name = f.path.split('\\').last.split('/').last;
            return SimpleDialogOption(
              child: Text(name),
              onPressed: () => Navigator.pop(ctx, f.path),
            );
          }).toList(),
        ),
      );
      if (selected == null) return;
      final jsonStr = await File(selected).readAsString();
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      if (data['version'] == null || (data['version'] as int) < 1) throw Exception('Unsupported backup version');
      final boxes = data['boxes'] as Map<String, dynamic>;

      // Restore images if present (version 2+)
      if (data['images'] != null) {
        final images = data['images'] as Map<String, dynamic>;
        for (final entry in images.entries) {
          try {
            final file = File(entry.key);
            await file.parent.create(recursive: true);
            await file.writeAsBytes(base64Decode(entry.value.toString()));
          } catch (_) {}
        }
      }

      for (final entry in boxes.entries) {
        final box = Hive.box(entry.key);
        final boxData = entry.value as Map<String, dynamic>;
        await box.clear();
        for (final kv in boxData.entries) {
          await box.put(kv.key, kv.value);
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.Lang.tr('dataImported')), backgroundColor: Colors.green),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _seedSampleData() async {
    Navigator.pop(context);
    try {
      final today = DateFormat('dd-MM-yyyy').format(DateTime.now());
      final yesterday = DateFormat('dd-MM-yyyy').format(DateTime.now().subtract(const Duration(days: 1)));
      final salesBox = Hive.box('salesBox');
      final inventoryBox = Hive.box('inventoryBox');
      final duesBox = Hive.box('duesBox');
      final financeBox = Hive.box('financeBox');
      final investorBox = Hive.box('investorBox');
      final assetsBox = Hive.box('assetsBox');
      final quickBox = Hive.box('quickBox');

      // --- PRODUCTS (inventoryBox) ---
      final products = [
        {'id': 'seed_p1', 'category': 'Miswak', 'investor': 'Own Shop', 'name': 'Miswak Premium', 'buyQty': 100.0, 'buyUnit': 'pcs', 'buyPrice': 20.0, 'sellUnit': 'pcs', 'sellPrice': 30.0, 'qty': 95.0, 'buyConversionFactor': 1.0, 'sellConversionFactor': 1.0, 'date': today, 'imagePath': ''},
        {'id': 'seed_p2', 'category': 'Attar', 'investor': 'Own Shop', 'name': 'Rose Attar', 'buyQty': 20.0, 'buyUnit': 'litre', 'buyPrice': 2000.0, 'sellUnit': 'ml', 'sellPrice': 250.0, 'qty': 19000.0, 'buyConversionFactor': 1000.0, 'sellConversionFactor': 1.0, 'date': today, 'imagePath': ''},
        {'id': 'seed_p3', 'category': 'Date', 'investor': 'Own Shop', 'name': 'Medjoul Dates', 'buyQty': 50.0, 'buyUnit': 'kg', 'buyPrice': 300.0, 'sellUnit': 'kg', 'sellPrice': 450.0, 'qty': 47.0, 'buyConversionFactor': 1.0, 'sellConversionFactor': 1.0, 'date': today, 'imagePath': ''},
        {'id': 'seed_p4', 'category': 'Topi', 'investor': 'Own Shop', 'name': 'White Cotton Topi', 'buyQty': 30.0, 'buyUnit': 'pcs', 'buyPrice': 80.0, 'sellUnit': 'pcs', 'sellPrice': 150.0, 'qty': 30.0, 'buyConversionFactor': 1.0, 'sellConversionFactor': 1.0, 'date': today, 'imagePath': ''},
        {'id': 'seed_p5', 'category': 'Book', 'investor': 'Own Shop', 'name': 'Quran (Medium)', 'buyQty': 15.0, 'buyUnit': 'pcs', 'buyPrice': 350.0, 'sellUnit': 'pcs', 'sellPrice': 500.0, 'qty': 15.0, 'buyConversionFactor': 1.0, 'sellConversionFactor': 1.0, 'date': today, 'imagePath': ''},
        {'id': 'seed_p6', 'category': 'Date', 'investor': 'Consignment Partner', 'name': 'Ajdwa Dates Premium', 'buyQty': 40.0, 'buyUnit': 'kg', 'buyPrice': 500.0, 'sellUnit': 'kg', 'sellPrice': 700.0, 'qty': 40.0, 'buyConversionFactor': 1.0, 'sellConversionFactor': 1.0, 'date': today, 'imagePath': ''},
      ];
      await inventoryBox.put('products', products);
      await inventoryBox.put('categories', ['Book', 'Date', 'Attar', 'Topi', 'Miswak', 'Other']);

      // --- SALES (salesBox) ---
      final sales = [
        {'id': 'seed_s1', 'date': today, 'productName': 'Miswak Premium', 'amount': 150.0, 'profit': 50.0, 'type': 'cash'},
        {'id': 'seed_s2', 'date': today, 'productName': 'Rose Attar', 'amount': 500.0, 'profit': 150.0, 'type': 'cash'},
        {'id': 'seed_s3', 'date': today, 'productName': 'Medjoul Dates', 'amount': 1200.0, 'profit': 300.0, 'type': 'credit'},
        {'id': 'seed_s4', 'date': yesterday, 'productName': 'White Cotton Topi', 'amount': 300.0, 'profit': 140.0, 'type': 'cash'},
      ];
      await salesBox.put('sales', sales);

      // --- RENT BOOK DEFINITIONS (salesBox) ---
      final rentBooks = [
        {'id': 'seed_rb1', 'name': 'Tafsir Ibn Kathir', 'pageCount': 500, 'copies': 3},
        {'id': 'seed_rb2', 'name': 'Riyad us Saliheen', 'pageCount': 300, 'copies': 5},
        {'id': 'seed_rb3', 'name': 'Sahih Bukhari', 'pageCount': 800, 'copies': 2},
      ];
      await salesBox.put('rentBooks', rentBooks);

      // --- BOOK RENTALS (salesBox) ---
      final bookRentals = [
        {'id': 'seed_br1', 'bookName': 'Tafsir Ibn Kathir', 'pageCount': 500, 'customerName': 'Ahmed Khan', 'dateTaken': today, 'expectedReturn': DateFormat('dd-MM-yyyy').format(DateTime.now().add(const Duration(days: 7))), 'dateReturned': '', 'cost': 70.0, 'isPaid': false},
        {'id': 'seed_br2', 'bookName': 'Riyad us Saliheen', 'pageCount': 300, 'customerName': 'Usman Ali', 'dateTaken': yesterday, 'expectedReturn': DateFormat('dd-MM-yyyy').format(DateTime.now().add(const Duration(days: 5))), 'dateReturned': '', 'cost': 30.0, 'isPaid': true},
        {'id': 'seed_br3', 'bookName': 'Sahih Bukhari', 'pageCount': 800, 'customerName': 'Mohammad Imran', 'dateTaken': today, 'expectedReturn': DateFormat('dd-MM-yyyy').format(DateTime.now().add(const Duration(days: 10))), 'dateReturned': '', 'cost': 100.0, 'isPaid': false},
      ];
      await salesBox.put('bookRentals', bookRentals);

      // --- CUSTOMERS WITH DUES (duesBox) ---
      final customers = [
        {
          'id': 'seed_c1', 'name': 'Ahmed Khan', 'phone': '03001234567', 'whatsapp': '', 'imagePath': '', 'note': 'Regular buyer', 'address': 'Gulshan-e-Maymar, Karachi', 'type': 'buyer',
          'ledger': [
            {'date': today, 'amount': 2000.0, 'type': 'due', 'itemName': 'Assorted Dates', 'imagePath': '', 'note': 'Bulk order'},
            {'date': today, 'amount': 500.0, 'type': 'payment', 'itemName': '', 'imagePath': '', 'note': 'Partial payment'},
          ],
          'purchases': [
            {'id': 'seed_cp1', 'productName': 'Assorted Dates', 'price': 2000.0, 'date': today},
          ],
          'orders': [
            {'id': 'seed_co1', 'description': '10 kg premium dates', 'dateGiven': today, 'dateNeeded': DateFormat('dd-MM-yyyy').format(DateTime.now().add(const Duration(days: 3))), 'status': 'pending', 'dateTaken': ''},
          ],
          'rentals': [],
        },
        {
          'id': 'seed_c2', 'name': 'Fatima Bibi', 'phone': '03007654321', 'whatsapp': '', 'imagePath': '', 'note': 'Home delivery customer', 'address': 'North Nazimabad, Karachi', 'type': 'due_taker',
          'ledger': [
            {'date': yesterday, 'amount': 1500.0, 'type': 'due', 'itemName': 'Attar Gift Set', 'imagePath': '', 'note': 'Gift set on credit'},
          ],
          'purchases': [
            {'id': 'seed_cp2', 'productName': 'Attar Gift Set', 'price': 1500.0, 'date': yesterday},
          ],
          'orders': [],
          'rentals': [],
        },
        {
          'id': 'seed_c3', 'name': 'Usman Ali', 'phone': '03005551234', 'whatsapp': '03005551234', 'imagePath': '', 'note': 'Book renter', 'address': 'Clifton, Karachi', 'type': 'renter',
          'ledger': [],
          'purchases': [],
          'orders': [],
          'rentals': [],
        },
      ];
      await duesBox.put('customers', customers);
      await duesBox.put('customerTypes', [
        {'id': 'buyer', 'label': 'Buyers', 'icon': 4},
        {'id': 'order_giver', 'label': 'Order Givers', 'icon': 5},
        {'id': 'renter', 'label': 'Renters', 'icon': 3},
        {'id': 'due_taker', 'label': 'Due Takers', 'icon': 6},
        {'id': 'prospective', 'label': 'Prospective', 'icon': 7},
      ]);

      // --- EXPENSES (financeBox) ---
      final expenses = [
        {'id': 'seed_e1', 'type': 'fixed', 'title': 'Shop Rent', 'amount': 15000.0, 'date': today, 'billPath': '', 'dueDay': 1, 'note': 'July 2026 rent', 'vendor': 'Landlord', 'paymentMethod': 'Cash', 'isPaid': true, 'recurringType': 'monthly'},
        {'id': 'seed_e2', 'type': 'misc', 'title': 'Electricity Bill', 'amount': 3200.0, 'date': today, 'billPath': '', 'dueDay': null, 'note': 'K-Electric June bill', 'vendor': 'K-Electric', 'paymentMethod': 'Cash', 'isPaid': true, 'recurringType': 'none'},
        {'id': 'seed_e3', 'type': 'misc', 'title': 'Office Supplies', 'amount': 850.0, 'date': yesterday, 'billPath': '', 'dueDay': null, 'note': 'Stationery items', 'vendor': 'Naeem Stationers', 'paymentMethod': 'Cash', 'isPaid': true, 'recurringType': 'none'},
      ];
      await financeBox.put('expenses', expenses);

      // --- PURCHASES (financeBox) ---
      final purchases = [
        {
          'id': 'seed_pu1', 'date': today, 'source': 'cash', 'cashTaken': 3000.0, 'investorId': '', 'notes': 'Weekly date purchase',
          'memoPhotoPath': '', 'returnedCash': 0.0,
          'items': [{'shopName': 'Date Wholesale Mart', 'itemName': 'Medjoul Dates', 'quantity': 10.0, 'unitPrice': 280.0}],
          'transportCosts': [{'vehicle': 'Rickshaw', 'cost': 150.0}],
          'otherCosts': [{'description': 'Loading', 'cost': 50.0}],
        },
        {
          'id': 'seed_pu2', 'date': today, 'source': 'cash', 'cashTaken': 1000.0, 'investorId': '', 'notes': 'Attar restock',
          'memoPhotoPath': '', 'returnedCash': 0.0,
          'items': [{'shopName': 'Attar House', 'itemName': 'Rose Attar', 'quantity': 1.0, 'unitPrice': 800.0}],
          'transportCosts': [],
          'otherCosts': [],
        },
      ];
      await financeBox.put('purchases', purchases);

      // --- TRANSPORT COSTS (financeBox) ---
      final transportCosts = [
        {'vehicle': 'Rickshaw', 'cost': 150.0},
        {'vehicle': 'Pickup', 'cost': 500.0},
      ];
      await financeBox.put('transportCosts', transportCosts);

      // --- INVESTORS (investorBox) ---
      final investors = [
        {
          'id': 'seed_i1', 'name': 'Abdul Rahman', 'investedAmount': 500000.0, 'durationMonths': 12, 'profitPercentage': 20.0,
          'dailyEarnings': 500.0, 'monthlyEarnings': 15000.0, 'contractType': 'profitShare', 'investmentType': 'mixed',
          'isActive': true, 'startDate': DateFormat('dd-MM-yyyy').format(DateTime.now().subtract(const Duration(days: 90))),
          'totalBought': 0.0, 'totalSold': 0.0, 'totalProfit': 0.0, 'remainingBalance': 500000.0,
          'productValueTotal': 0.0, 'cashInvested': 300000.0, 'productInvested': 200000.0,
          'repayments': [
            {'id': 'seed_r1', 'amount': 10000.0, 'date': today, 'notes': 'Monthly profit share'},
            {'id': 'seed_r2', 'amount': 5000.0, 'date': yesterday, 'notes': 'Extra payment'},
          ],
        },
        {
          'id': 'seed_i2', 'name': 'Muhammad Ali', 'investedAmount': 200000.0, 'durationMonths': 6, 'profitPercentage': 15.0,
          'dailyEarnings': 200.0, 'monthlyEarnings': 6000.0, 'contractType': 'loan', 'investmentType': 'cash',
          'isActive': true, 'startDate': DateFormat('dd-MM-yyyy').format(DateTime.now().subtract(const Duration(days: 30))),
          'totalBought': 0.0, 'totalSold': 0.0, 'totalProfit': 0.0, 'remainingBalance': 195000.0,
          'productValueTotal': 0.0, 'cashInvested': 200000.0, 'productInvested': 0.0,
          'repayments': [
            {'id': 'seed_r3', 'amount': 5000.0, 'date': today, 'notes': 'Partial repayment'},
          ],
        },
        {
          'id': 'seed_i3', 'name': 'Consignment Partner', 'investedAmount': 300000.0, 'durationMonths': 3, 'profitPercentage': 30.0,
          'dailyEarnings': 0.0, 'monthlyEarnings': 0.0, 'contractType': 'consignment', 'investmentType': 'products',
          'isActive': true, 'startDate': DateFormat('dd-MM-yyyy').format(DateTime.now().subtract(const Duration(days: 60))),
          'totalBought': 20000.0, 'totalSold': 8000.0, 'totalProfit': 2800.0, 'remainingBalance': 300000.0,
          'productValueTotal': 20000.0, 'cashInvested': 0.0, 'productInvested': 300000.0,
          'repayments': [
            {'id': 'seed_r4', 'amount': 2000.0, 'date': today, 'notes': 'Share of sold stock'},
          ],
        },
      ];
      await investorBox.put('investors', investors);

      // --- FIXED ASSETS (assetsBox) ---
      final assets = [
        {'id': 'seed_a1', 'name': 'Display Fridge', 'estimatedValue': 45000.0, 'purchaseDate': today, 'imagePath': ''},
        {'id': 'seed_a2', 'name': 'Furniture & Shelving', 'estimatedValue': 35000.0, 'purchaseDate': today, 'imagePath': ''},
        {'id': 'seed_a3', 'name': 'Cash Register', 'estimatedValue': 15000.0, 'purchaseDate': yesterday, 'imagePath': ''},
      ];
      await assetsBox.put('assets', assets);

      // --- QUICK CAPTURES (quickBox) ---
      final captures = [
        {'id': 'seed_q1', 'timestamp': DateTime.now().toIso8601String(), 'note': 'Meeting with supplier about new attar collection - they will deliver next week', 'imagePath': '', 'source': 'Quick Note'},
        {'id': 'seed_q2', 'timestamp': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(), 'note': 'Price update: Miswap premium now Rs 35 per piece from next month', 'imagePath': '', 'source': 'Quick Note'},
        {'id': 'seed_q3', 'timestamp': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(), 'note': 'Customer requested bulk order of 50 Quran copies for mosque', 'imagePath': '', 'source': 'Customer'},
      ];
      await quickBox.put('captures', captures);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.Lang.tr('seedDone')),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Seed failed: $e'), backgroundColor: Colors.red));
    }
  }

  Widget _buildDrawer(BuildContext context) {
    final isDark = widget.themeNotifier.value;
    final locale = lang.localeNotifier.value;
    final items = <Widget>[
      DrawerHeader(
        decoration: const BoxDecoration(color: kTeal),
        child: SizedBox(width: double.infinity, child: shopLogo(size: 24, color: Colors.white)),
      ),
      ListTile(leading: const Icon(Iconsax.category), title: Text(lang.Lang.tr('overview')), onTap: () { Navigator.pop(context); _switchTab(0); }),
      ListTile(leading: const Icon(Iconsax.hashtag), title: Text(lang.Lang.tr('dailySales')), onTap: () { Navigator.pop(context); _switchTab(1); }),
      ListTile(leading: const Icon(Iconsax.shop), title: Text(lang.Lang.tr('stockAndAssets')), onTap: () { Navigator.pop(context); _switchTab(2); }),
      ListTile(leading: const Icon(Iconsax.book), title: Text(lang.Lang.tr('dues')), onTap: () { Navigator.pop(context); _switchTab(3); }),
      ListTile(leading: const Icon(Iconsax.receipt), title: Text(lang.Lang.tr('expensesAndPurchases')), onTap: () { Navigator.pop(context); _switchTab(4); }),
      ListTile(leading: const Icon(Iconsax.chart), title: Text(lang.Lang.tr('investor')), onTap: () { Navigator.pop(context); _switchTab(5); }),
      ListTile(leading: const Icon(Iconsax.people), title: Text(lang.Lang.tr('customers')), onTap: () { Navigator.pop(context); _switchTab(6); }),
      const Divider(),
      Padding(padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4), child: Text(lang.Lang.tr('utilities'), style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600))),
      ListTile(leading: const Icon(Iconsax.bookmark), title: Text(lang.Lang.tr('quickCaptures')), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const QuickCaptureGallery())); }),
      ListTile(leading: const Icon(Iconsax.building), title: Text(lang.Lang.tr('fixedAssets')), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const AssetsScreen())); }),
      const Divider(),
      Padding(padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4), child: Text(lang.Lang.tr('data'), style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600))),
      ListTile(leading: const Icon(Iconsax.export_1), title: Text(lang.Lang.tr('exportData')), onTap: _exportData),
      ListTile(leading: const Icon(Iconsax.import_1), title: Text(lang.Lang.tr('importData')), onTap: _importData),
      ListTile(leading: const Icon(Iconsax.microscope), title: Text(lang.Lang.tr('seedSampleData')), onTap: _seedSampleData),
      const Divider(),
      SwitchListTile(
        secondary: Icon(isDark ? Iconsax.moon : Iconsax.sun, color: kTeal),
        title: Text(lang.Lang.tr('darkTheme')),
        value: isDark,
        onChanged: _toggleDarkMode,
      ),
      SwitchListTile(
        secondary: Icon(locale == 'bn' ? Iconsax.global : Iconsax.global, color: kTeal),
        title: Text(lang.Lang.tr('language')),
        subtitle: Text(locale == 'bn' ? lang.Lang.tr('bangla') : lang.Lang.tr('english')),
        value: locale == 'bn',
        onChanged: (val) { lang.localeNotifier.value = val ? 'bn' : 'en'; },
      ),
    ];

    return Drawer(
      child: ListView(padding: EdgeInsets.zero, children: items),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        } else {
          final now = DateTime.now();
          if (_lastBackPress != null && now.difference(_lastBackPress!).inSeconds < 2) {
            SystemNavigator.pop();
          } else {
            _lastBackPress = now;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(lang.Lang.tr('exitPressAgain')), duration: const Duration(seconds: 2)),
            );
          }
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
      drawer: _buildDrawer(context),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: _screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) { setState(() { _currentIndex = index; }); },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: kTeal,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: const Icon(Iconsax.category), label: lang.Lang.tr('overview')),
          BottomNavigationBarItem(icon: const Icon(Iconsax.hashtag), label: lang.Lang.tr('dailySales')),
          BottomNavigationBarItem(icon: const Icon(Iconsax.shop), label: lang.Lang.tr('stock')),
          BottomNavigationBarItem(icon: const Icon(Iconsax.book), label: lang.Lang.tr('dues')),
          BottomNavigationBarItem(icon: const Icon(Iconsax.receipt), label: lang.Lang.tr('expenses')),
          BottomNavigationBarItem(icon: const Icon(Iconsax.chart), label: lang.Lang.tr('investor')),
          BottomNavigationBarItem(icon: const Icon(Iconsax.people), label: lang.Lang.tr('customers')),
        ],
      ),
      ),
    );
  }

  List<Widget> get _screens => [
        _buildOverviewScreen(),
        DailySalesScreen(todayDue: widget.todayDue, onMenuTap: _openDrawer),
        InventoryEntryScreen(onMenuTap: _openDrawer),
        DuesScreen(onMenuTap: _openDrawer),
        FinanceScreen(onMenuTap: _openDrawer),
        InvestorScreen(onMenuTap: _openDrawer),
        CustomersScreen(onMenuTap: _openDrawer),
      ];

  Widget _buildOverviewScreen() {
    final dateStr = _selectedDate != null ? DateFormat('dd-MM-yyyy').format(_selectedDate!) : DateFormat('dd-MM-yyyy').format(DateTime.now());
    final salesBox = Hive.box('salesBox');
    final inventoryBox = Hive.box('inventoryBox');
    final financeBox = Hive.box('financeBox');
    final duesBox = Hive.box('duesBox');
    final investorBox = Hive.box('investorBox');

    // --- BOOK RENTALS ---
    final bookRentals = List<Map<String, dynamic>>.from(
        (salesBox.get('bookRentals', defaultValue: []) as List)
            .map((e) => Map<String, dynamic>.from(e as Map)));

    // --- 1. SALES ---
    final allSales = List<Map<dynamic, dynamic>>.from(salesBox.get('sales', defaultValue: []));
    double totalSell = 0.0, cumulativeCashSales = 0.0, netResult = 0.0;
    for (var sale in allSales) {
      double amt = (sale['amount'] as num?)?.toDouble() ?? 0.0;
      double pft = (sale['profit'] as num?)?.toDouble() ?? 0.0;
      String type = sale['type']?.toString() ?? 'cash';
      totalSell += amt;
      netResult += pft;
      if (type == 'cash') cumulativeCashSales += amt;
    }

    // --- 2. STOCK ---
    final allProducts = List<Map<dynamic, dynamic>>.from(inventoryBox.get('products', defaultValue: []));
    double stockValue = 0.0;
    for (var p in allProducts) {
      double buyPrice = double.tryParse(p['buyPrice']?.toString() ?? '0') ?? 0.0;
      double qty = double.tryParse(p['qty']?.toString() ?? '0') ?? 0.0;
      double buyConversionFactor = double.tryParse(p['buyConversionFactor']?.toString() ?? '1') ?? 1.0;
      stockValue += (buyConversionFactor > 0 ? buyPrice / buyConversionFactor : 0) * qty;
    }

    // --- 3. EXPENSES & PURCHASES ---
    final allExpenses = List<Map<dynamic, dynamic>>.from(
        (financeBox.get('expenses', defaultValue: []) as List)
            .map((e) => Map<String, dynamic>.from(e as Map)));
    double totalExpense = 0.0;
    for (var e in allExpenses) {
      double amt = (e['amount'] as num?)?.toDouble() ?? 0.0;
      totalExpense += amt;
    }

    final allPurchases = List<Map<dynamic, dynamic>>.from(
        (financeBox.get('purchases', defaultValue: []) as List)
            .map((p) => Map<String, dynamic>.from(p as Map)));
    double totalBuy = 0.0, cumulativeCashPurchases = 0.0;
    for (var p in allPurchases) {
      double amt = (p['amount'] as num?)?.toDouble() ?? 0.0;
      totalBuy += amt;
      if (p['source']?.toString() == 'cash') cumulativeCashPurchases += amt;
    }

    // --- 4. DUES ---
    final allCustomers = List<Map<dynamic, dynamic>>.from(duesBox.get('customers', defaultValue: []));
    double totalDue = 0.0, totalDuePaid = 0.0;
    for (var customer in allCustomers) {
      final ledger = customer['ledger'] as List? ?? [];
      for (var entry in ledger) {
        double amt = (entry['amount'] as num?)?.toDouble() ?? 0.0;
        if (entry['type'] == 'due') totalDue += amt;
        if (entry['type'] == 'payment') totalDuePaid += amt;
      }
    }
    double outstandingDue = totalDue - totalDuePaid;

    // --- 5. RENT ---
    double cumulativeRentIncome = 0.0;
    double totalRentDue = 0.0;
    for (var r in bookRentals) {
      double cost = (r['cost'] as num?)?.toDouble() ?? 0.0;
      if (r['isPaid'] != true) totalRentDue += cost;
      if (r['isPaid'] == true) cumulativeRentIncome += cost;
    }

    // --- 6. INVESTORS ---
    final allInvestors = List<Map<dynamic, dynamic>>.from(investorBox.get('investors', defaultValue: []));
    double toGiveAway = 0.0;
    for (var inv in allInvestors) {
      final reps = inv['repayments'] as List? ?? [];
      for (var r in reps) {
        double amt = (r['amount'] as num?)?.toDouble() ?? 0.0;
        toGiveAway += amt;
      }
    }

    double totalCash = (cumulativeCashSales + cumulativeRentIncome + totalDuePaid) - (cumulativeCashPurchases + totalExpense + toGiveAway);
    final now = DateTime.now();
    final dayName = DateFormat('EEEE').format(now);
    final formattedDate = DateFormat('dd MMM yyyy').format(now);

    // --- 7. TOTAL ASSETS ---
    final assetsBox = Hive.box('assetsBox');
    final allAssets = List<Map<dynamic, dynamic>>.from(assetsBox.get('assets', defaultValue: []));
    double totalAssetValue = 0.0;
    for (var a in allAssets) {
      totalAssetValue += (a['estimatedValue'] as num?)?.toDouble() ?? 0.0;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kTeal,
        leading: IconButton(icon: const Icon(Iconsax.menu), onPressed: _openDrawer),
        title: Row(
          children: [
            shopLogo(size: 20, color: Colors.white),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lang.Lang.tr('appTitle'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('$dayName, $formattedDate', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w300)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.calendar, color: Colors.white),
            onPressed: _showDatePicker,
          ),
          IconButton(
            icon: Icon(_showOtherActivities ? Iconsax.category : Iconsax.activity, color: Colors.white),
            onPressed: () => setState(() => _showOtherActivities = !_showOtherActivities),
            tooltip: lang.Lang.tr('toggleView'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_showOtherActivities)
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.85,
                children: [
                  // Row 1
                  _ovCard(icon: Iconsax.wallet, iconColor: const Color(0xFF1565C0), label: lang.Lang.tr('totalCash'), amount: totalCash, amountColor: const Color(0xFF0D47A1), brightText: true),
                  _ovCard(icon: Iconsax.box, iconColor: const Color(0xFF283593), label: lang.Lang.tr('stockValue'), amount: stockValue, amountColor: const Color(0xFF1A237E), brightText: true),
                  // Row 2
                  _ovCard(icon: netResult >= 0 ? Iconsax.trend_up : Iconsax.trend_down, iconColor: netResult >= 0 ? const Color(0xFF2E7D32) : const Color(0xFFC62828), label: netResult >= 0 ? lang.Lang.tr('netProfit') : lang.Lang.tr('netLoss'), amount: netResult, amountColor: netResult >= 0 ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C), brightText: true),
                  _ovCard(icon: Iconsax.money_recive, iconColor: const Color(0xFFE65100), label: lang.Lang.tr('expense'), amount: totalExpense, amountColor: const Color(0xFFD32F2F), brightText: true),
                  // Row 3
                  _ovCard(icon: Iconsax.bag, iconColor: const Color(0xFFBF360C), label: lang.Lang.tr('totalBuy'), amount: totalBuy, amountColor: const Color(0xFF871F00), brightText: true),
                  _ovCard(icon: Iconsax.shop, iconColor: const Color(0xFF00695C), label: lang.Lang.tr('totalSell'), amount: totalSell, amountColor: const Color(0xFF004D40), brightText: true),
                  // Row 4
                  _ovCard(icon: Iconsax.add_circle, iconColor: outstandingDue > 0 ? const Color(0xFFF57F17) : const Color(0xFF757575), label: lang.Lang.tr('due'), amount: outstandingDue, amountColor: outstandingDue > 0 ? const Color(0xFFE65100) : const Color(0xFF424242), brightText: true),
                  _ovCard(icon: Iconsax.tick_circle, iconColor: const Color(0xFF558B2F), label: lang.Lang.tr('duePaid'), amount: totalDuePaid, amountColor: const Color(0xFF388E3C), brightText: true),
                  // Row 5
                  _ovCard(icon: Iconsax.wallet, iconColor: totalRentDue > 0 ? const Color(0xFFB71C1C) : const Color(0xFF2E7D32), label: lang.Lang.tr('rentDue'), amount: totalRentDue, amountColor: totalRentDue > 0 ? const Color(0xFFE57373) : const Color(0xFF66BB6A), brightText: true),
                  _ovCard(icon: Iconsax.book, iconColor: const Color(0xFF1B5E20), label: lang.Lang.tr('rentPaid'), amount: cumulativeRentIncome, amountColor: const Color(0xFF144D14), brightText: true),
                  // Row 6
                  _ovCard(icon: Iconsax.buildings, iconColor: const Color(0xFF4E342E), label: lang.Lang.tr('totalAssets'), amount: totalAssetValue, amountColor: const Color(0xFF3E2723), brightText: true),
                  _ovCard(icon: Iconsax.export_1, iconColor: const Color(0xFF4A148C), label: lang.Lang.tr('toGiveAway'), amount: toGiveAway, amountColor: const Color(0xFF311B92), brightText: true),
                ],
              )
            else
              _buildOtherActivitiesOverview(dateStr),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kTeal,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuickCaptureGallery())),
        child: const Icon(Iconsax.bookmark, size: 22),
      ),
    );
  }

  void _showDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Widget _buildOtherActivitiesOverview(String dateStr) {
    final financeBox = Hive.box('financeBox');
    final investorBox = Hive.box('investorBox');
    final duesBox = Hive.box('duesBox');
    final salesBox = Hive.box('salesBox');

    final expenses = List<Map<dynamic, dynamic>>.from(financeBox.get('expenses', defaultValue: []));
    final purchases = List<Map<dynamic, dynamic>>.from(financeBox.get('purchases', defaultValue: []));
    final investors = List<Map<dynamic, dynamic>>.from(investorBox.get('investors', defaultValue: []));
    final customers = List<Map<dynamic, dynamic>>.from(duesBox.get('customers', defaultValue: []));

    final dateExpenses = expenses.where((e) => e['date']?.toString() == dateStr).toList();
    final datePurchases = purchases.where((p) => p['date']?.toString() == dateStr).toList();

    final dateInvestorRepayments = <Map<String, dynamic>>[];
    for (final inv in investors) {
      final reps = inv['repayments'] as List? ?? [];
      for (final r in reps) {
        if ((r as Map)['date']?.toString() == dateStr) {
          dateInvestorRepayments.add({
            'investor': inv['name']?.toString() ?? '',
            'amount': (r['amount'] as num?)?.toDouble() ?? 0.0,
          });
        }
      }
    }

    final dateCustomerActivity = <Map<String, dynamic>>[];
    for (final cu in customers) {
      final name = cu['name']?.toString() ?? '';
      final purchasesList = cu['purchases'] as List? ?? [];
      for (final p in purchasesList) {
        if ((p as Map)['date']?.toString() == dateStr) {
          dateCustomerActivity.add({
            'customer': name,
            'type': 'purchase',
            'detail': '${p['productName']} (৳${((p['price'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0)})',
          });
        }
      }
      final ordersList = cu['orders'] as List? ?? [];
      for (final o in ordersList) {
        if ((o as Map)['dateGiven']?.toString() == dateStr) {
          dateCustomerActivity.add({
            'customer': name,
            'type': 'order',
            'detail': o['description']?.toString() ?? '',
          });
        }
      }
    }
    final allBookRentals = List<Map<String, dynamic>>.from(
        (salesBox.get('bookRentals', defaultValue: []) as List)
            .map((e) => Map<String, dynamic>.from(e as Map)));
    for (final r in allBookRentals) {
      if (r['dateTaken']?.toString() == dateStr) {
        dateCustomerActivity.add({
          'customer': r['customerName']?.toString() ?? '',
          'type': 'rental_taken',
          'detail': r['bookName']?.toString() ?? '',
        });
      }
      if (r['dateReturned']?.toString() == dateStr) {
        dateCustomerActivity.add({
          'customer': r['customerName']?.toString() ?? '',
          'type': 'rental_returned',
          'detail': '${r['bookName']} returned',
        });
      }
    }

    final sections = <_OverviewSection>[];
    if (dateExpenses.isNotEmpty) {
      sections.add(_OverviewSection(
        icon: Iconsax.money_recive, color: Colors.red, title: lang.Lang.tr('expenses'),
        lines: dateExpenses.map((e) =>
            '${e['category'] ?? ''}: ৳${((e['amount'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0)}${(e['note']?.toString() ?? '').isNotEmpty ? ' (${e['note']})' : ''}').toList(),
      ));
    }
    if (datePurchases.isNotEmpty) {
      sections.add(_OverviewSection(
        icon: Iconsax.bag, color: Colors.orange, title: lang.Lang.tr('stockPurchases'),
        lines: datePurchases.map((p) =>
            '${p['itemName'] ?? ''} × ${p['quantity'] ?? 1}: ৳${((p['amount'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0)}').toList(),
      ));
    }
    if (dateInvestorRepayments.isNotEmpty) {
      sections.add(_OverviewSection(
        icon: Iconsax.building, color: Colors.teal, title: lang.Lang.tr('investorRepayments'),
        lines: dateInvestorRepayments.map((r) =>
            '${r['investor']}: ৳${(r['amount'] ?? 0.0).toStringAsFixed(0)}').toList(),
      ));
    }
    if (dateCustomerActivity.isNotEmpty) {
      sections.add(_OverviewSection(
        icon: Iconsax.people, color: Colors.blue, title: lang.Lang.tr('customerActivity'),
        lines: dateCustomerActivity.map((a) {
          final prefix = a['type'] == 'purchase' ? '[Purchase]' :
              a['type'] == 'order' ? '[Order]' :
              a['type'] == 'rental_taken' ? '[Rental]' : '[Return]';
          return '$prefix ${a['customer']}: ${a['detail']}';
        }).toList(),
      ));
    }

    if (sections.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.activity, size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(lang.Lang.tr('noActivitiesToday'), style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
          ],
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.grey.shade200 : Colors.black87;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: const Border(left: BorderSide(color: kTeal, width: 3)),
        boxShadow: [
          BoxShadow(color: kTeal.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 1)),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            padding: const EdgeInsets.only(left: 8),
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: kTeal, width: 3)),
            ),
            child: Text(lang.Lang.tr('otherActivities'),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ),
          const SizedBox(height: 8),
          ...sections.map((s) => Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: kTeal, width: 3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: s.color)),
                const SizedBox(height: 4),
                ...s.lines.map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(l, style: TextStyle(fontSize: 11, color: textColor)),
                )),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _ovCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required double amount,
    required Color amountColor,
    bool brightText = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF2D2D2D) : Colors.white;
    final gradientColors = isDark
        ? [iconColor.withValues(alpha: 0.22), bgColor]
        : [iconColor.withValues(alpha: 0.08), bgColor];
    final labelColor = brightText && isDark ? Colors.white70 : iconColor;
    final valueColor = brightText && isDark ? Colors.white : amountColor;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: iconColor.withValues(alpha: isDark ? 0.35 : 0.25)),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: brightText && isDark ? Colors.white70 : iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    style: TextStyle(fontSize: 13, color: labelColor, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('\u09F3 ${amount.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: valueColor),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class DailySalesScreen extends StatefulWidget {
  final double todayDue;
  final VoidCallback? onMenuTap;
  const DailySalesScreen({super.key, this.todayDue = 0.0, this.onMenuTap});

  @override
  State<DailySalesScreen> createState() => _DailySalesScreenState();
}

class _OverviewSection {
  final IconData icon;
  final Color color;
  final String title;
  final List<String> lines;
  _OverviewSection({
    required this.icon,
    required this.color,
    required this.title,
    required this.lines,
  });
}

class _DailySalesScreenState extends State<DailySalesScreen> with SingleTickerProviderStateMixin {


  final _salesBox = Hive.box('salesBox');
  final _inventoryBox = Hive.box('inventoryBox');
  final _duesBox = Hive.box('duesBox');
  final _financeBox = Hive.box('financeBox');
  late final TabController _tabCtrl;
  final TextEditingController _salesSearchController = TextEditingController();
  final TextEditingController _productSearchController = TextEditingController();
  final TextEditingController _quickSaleController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _salesSearchQuery = "";
  List<Map<dynamic, dynamic>> _filteredProducts = [];
  Map<dynamic, dynamic>? _selectedProduct;
  List<Customer> _buyerCustomers = [];
  String? _selectedBuyerName;
  bool _showForm = false;

  // Rent section state
  List<Map<String, dynamic>> _rentBooks = [];
  List<Map<String, dynamic>> _bookRentals = [];
  final TextEditingController _bookNameCtrl = TextEditingController();
  final TextEditingController _pageCountCtrl = TextEditingController();
  final TextEditingController _copiesCtrl = TextEditingController(text: '1');
  final TextEditingController _rentCustomerCtrl = TextEditingController();
  final TextEditingController _rentDaysCtrl = TextEditingController(text: '10');
  String? _selectedRentBookName;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadBuyers();
    _loadRentData();
    _showForm = true;
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _showForm = false);
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _salesSearchController.dispose();
    _productSearchController.dispose();
    _quickSaleController.dispose();
    _bookNameCtrl.dispose();
    _pageCountCtrl.dispose();
    _copiesCtrl.dispose();
    _rentCustomerCtrl.dispose();
    _rentDaysCtrl.dispose();
    super.dispose();
  }

  void _loadRentData() {
    _rentBooks = List<Map<String, dynamic>>.from(
        (_salesBox.get('rentBooks', defaultValue: []) as List)
            .map((e) => Map<String, dynamic>.from(e as Map)));
    _bookRentals = List<Map<String, dynamic>>.from(
        (_salesBox.get('bookRentals', defaultValue: []) as List)
            .map((e) => Map<String, dynamic>.from(e as Map)));
  }

  void _saveRentBooks() {
    _salesBox.put('rentBooks', _rentBooks);
  }

  void _saveBookRentals() {
    _salesBox.put('bookRentals', _bookRentals);
  }

  double _rentPrice(int pageCount, int days) {
    final rate = ((pageCount - 1) ~/ 100 + 1) * 10.0;
    final periods = ((days - 1) ~/ 10 + 1);
    return rate * periods;
  }

  void _addRentBook() {
    final name = _bookNameCtrl.text.trim();
    final pages = int.tryParse(_pageCountCtrl.text) ?? 0;
    final copies = int.tryParse(_copiesCtrl.text) ?? 1;
    if (name.isEmpty || pages <= 0) return;
    setState(() {
      _rentBooks.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': name,
        'pageCount': pages,
        'copies': copies,
      });
      _saveRentBooks();
      _bookNameCtrl.clear();
      _pageCountCtrl.clear();
      _copiesCtrl.text = '1';
    });
  }

  void _deleteRentBook(String id) {
    setState(() {
      _rentBooks.removeWhere((b) => b['id'] == id);
      _saveRentBooks();
    });
  }

  void _rentOutBook() {
    final bookName = _selectedRentBookName;
    final customer = _rentCustomerCtrl.text.trim();
    final days = int.tryParse(_rentDaysCtrl.text) ?? 10;
    if (bookName == null || customer.isEmpty) return;
    final book = _rentBooks.cast<Map<String, dynamic>?>().firstWhere(
        (b) => b?['name'] == bookName, orElse: () => null);
    if (book == null) return;
    final rentCost = _rentPrice(book['pageCount'] as int, days);
    final dateStr = DateFormat('dd-MM-yyyy').format(_selectedDate);
    setState(() {
      _bookRentals.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'bookName': bookName,
        'pageCount': book['pageCount'],
        'customerName': customer,
        'dateTaken': dateStr,
        'expectedReturn': DateFormat('dd-MM-yyyy')
            .format(_selectedDate.add(Duration(days: days))),
        'dateReturned': '',
        'cost': rentCost,
        'isPaid': false,
      });
      _saveBookRentals();
      _rentCustomerCtrl.clear();
      _selectedRentBookName = null;
      _ensureRenterCustomer(customer);
    });
  }

  void _returnBook(int idx) {
    setState(() {
      _bookRentals[idx]['dateReturned'] =
          DateFormat('dd-MM-yyyy').format(_selectedDate);
      _saveBookRentals();
    });
  }

  void _toggleRentPaid(int idx) {
    setState(() {
      _bookRentals[idx]['isPaid'] = !(_bookRentals[idx]['isPaid'] == true);
      _saveBookRentals();
    });
  }

  void _ensureRenterCustomer(String name) {
    final allCustomers = List<Map<String, dynamic>>.from(
        (_duesBox.get('customers', defaultValue: []) as List)
            .map((e) => Map<String, dynamic>.from(e as Map)));
    final exists = allCustomers.any(
        (c) => c['name']?.toString().toLowerCase() == name.toLowerCase());
    if (!exists) {
      final newCust = Customer(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        type: 'renter',
      ).toMap();
      allCustomers.add(newCust);
      _duesBox.put('customers', allCustomers);
    }
  }

  void _loadBuyers() {
    final stored = _duesBox.get('customers', defaultValue: []);
    _buyerCustomers = List<Map<dynamic, dynamic>>.from(stored)
        .map((c) => Customer.fromMap(Map<String, dynamic>.from(c)))
        .where((c) => c.type == 'buyer')
        .toList();
  }

  void _searchProducts(String query) {
    setState(() {
      final allProducts = List<Map<dynamic, dynamic>>.from(_inventoryBox.get('products', defaultValue: []));
      if (query.isEmpty) {
        _filteredProducts = [];
      } else {
        _filteredProducts = allProducts.where((product) {
          final name = product['name']?.toString().toLowerCase() ?? '';
          return name.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _selectProduct(Map<dynamic, dynamic> product) {
    setState(() {
      _selectedProduct = product;
      _productSearchController.text = product['name']?.toString() ?? '';
      _filteredProducts = [];
    });
  }

  void _addQuickSale() {
    if (_quickSaleController.text.isEmpty || _selectedProduct == null) return;
    double qty = double.tryParse(_quickSaleController.text) ?? 0.0;
    if (qty <= 0) return;
    double sellPrice = double.tryParse(_selectedProduct!['sellPrice']?.toString() ?? '0') ?? 0.0;
    double amount = qty * sellPrice;
    double buyPrice = double.tryParse(_selectedProduct!['buyPrice']?.toString() ?? '0') ?? 0.0;
    double buyConversionFactor = double.tryParse(_selectedProduct!['buyConversionFactor']?.toString() ?? '1') ?? 1.0;
    double sellConversionFactor = double.tryParse(_selectedProduct!['sellConversionFactor']?.toString() ?? '1') ?? 1.0;
    double costPerBaseUnit = buyConversionFactor > 0 ? buyPrice / buyConversionFactor : 0;
    double baseQtySold = qty * sellConversionFactor;
    double costOfGoodsSold = costPerBaseUnit * baseQtySold;
    double profit = amount - costOfGoodsSold;
    String today = DateFormat('dd-MM-yyyy').format(DateTime.now());

    final existingSales = List<Map<dynamic, dynamic>>.from(_salesBox.get('sales', defaultValue: []));
    existingSales.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'date': today,
      'productName': _selectedProduct!['name']?.toString() ?? 'Quick Sale',
      'amount': amount,
      'profit': profit,
      'type': _selectedBuyerName != null ? 'credit' : 'cash',
    });
    _salesBox.put('sales', existingSales);

    double buyQty = double.tryParse(_selectedProduct!['qty']?.toString() ?? '0') ?? 0.0;
    double remainingQty = buyQty - (qty * sellConversionFactor);
    _selectedProduct!['qty'] = remainingQty.toString();
    final products = List<Map<dynamic, dynamic>>.from(_inventoryBox.get('products', defaultValue: []));
    final idx = products.indexWhere((p) => p['id'] == _selectedProduct!['id']);
    if (idx >= 0) {
      products[idx] = _selectedProduct!;
      _inventoryBox.put('products', products);
    }

    _quickSaleController.clear();
    _productSearchController.clear();
    _selectedProduct = null;
    _filteredProducts = [];

    final isCredit = _selectedBuyerName != null;
    salesNotifier.value = {
      'cash': isCredit ? salesNotifier.value['cash']! : salesNotifier.value['cash']! + amount,
      'profit': salesNotifier.value['profit']! + profit,
    };

    if (_selectedBuyerName != null) {
      final allCustomers = List<Map<dynamic, dynamic>>.from(_duesBox.get('customers', defaultValue: []));
      final buyerIdx = allCustomers.indexWhere((c) =>
          c['name']?.toString() == _selectedBuyerName && c['type']?.toString() == 'buyer');
      if (buyerIdx >= 0) {
        final customer = Customer.fromMap(Map<String, dynamic>.from(allCustomers[buyerIdx]));
        customer.purchases.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'productName': _selectedProduct?['name']?.toString() ?? '',
          'price': amount,
          'date': today,
        });
        allCustomers[buyerIdx] = customer.toMap();
        _duesBox.put('customers', allCustomers);
      }
      _selectedBuyerName = null;
    }
  }

  void _deleteSale(Map<dynamic, dynamic>? sale) {
    if (sale == null) return;
    final allSales = List<Map<dynamic, dynamic>>.from(_salesBox.get('sales', defaultValue: []));
    allSales.removeWhere((s) => s['id'] == sale['id']);
    _salesBox.put('sales', allSales);

    double amount = sale['amount']?.toDouble() ?? 0.0;
    double profit = sale['profit']?.toDouble() ?? 0.0;
    final isCredit = sale['type']?.toString() == 'credit';
    salesNotifier.value = {
      'cash': salesNotifier.value['cash']! - (isCredit ? 0 : amount),
      'profit': salesNotifier.value['profit']! - profit,
    };
  }

  Widget _buildDailyOverview(String dateStr) {
    final financeBox = Hive.box('financeBox');
    final investorBox = Hive.box('investorBox');
    final duesBox = Hive.box('duesBox');

    final expenses = List<Map<dynamic, dynamic>>.from(
        financeBox.get('expenses', defaultValue: []));
    final purchases = List<Map<dynamic, dynamic>>.from(
        financeBox.get('purchases', defaultValue: []));
    final investors = List<Map<dynamic, dynamic>>.from(
        investorBox.get('investors', defaultValue: []));
    final customers = List<Map<dynamic, dynamic>>.from(
        duesBox.get('customers', defaultValue: []));

    final dateExpenses = expenses.where((e) =>
        e['date']?.toString() == dateStr).toList();
    final datePurchases = purchases.where((p) =>
        p['date']?.toString() == dateStr).toList();

    final dateInvestorRepayments = <Map<String, dynamic>>[];
    for (final inv in investors) {
      final reps = inv['repayments'] as List? ?? [];
      for (final r in reps) {
        if ((r as Map)['date']?.toString() == dateStr) {
          dateInvestorRepayments.add({
            'investor': inv['name']?.toString() ?? '',
            'amount': (r['amount'] as num?)?.toDouble() ?? 0.0,
            'date': r['date']?.toString() ?? '',
          });
        }
      }
    }

    final dateCustomerActivity = <Map<String, dynamic>>[];
    for (final cu in customers) {
      final name = cu['name']?.toString() ?? '';
      final purchasesList = cu['purchases'] as List? ?? [];
      for (final p in purchasesList) {
        if ((p as Map)['date']?.toString() == dateStr) {
          dateCustomerActivity.add({
            'customer': name,
            'type': 'purchase',
            'detail': '${p['productName']} (৳${((p['price'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0)})',
            'date': p['date'],
          });
        }
      }
      final ordersList = cu['orders'] as List? ?? [];
      for (final o in ordersList) {
        if ((o as Map)['dateGiven']?.toString() == dateStr) {
          dateCustomerActivity.add({
            'customer': name,
            'type': 'order',
            'detail': o['description']?.toString() ?? '',
            'date': o['dateGiven'],
          });
        }
      }
    }
    // Customer rentals from unified bookRentals (outside customer loop)
    final allBookRentals = List<Map<String, dynamic>>.from(
        (_salesBox.get('bookRentals', defaultValue: []) as List)
            .map((e) => Map<String, dynamic>.from(e as Map)));
    for (final r in allBookRentals) {
      if (r['dateTaken']?.toString() == dateStr) {
        dateCustomerActivity.add({
          'customer': r['customerName']?.toString() ?? '',
          'type': 'rental_taken',
          'detail': r['bookName']?.toString() ?? '',
          'date': r['dateTaken'],
        });
      }
      if (r['dateReturned']?.toString() == dateStr) {
        dateCustomerActivity.add({
          'customer': r['customerName']?.toString() ?? '',
          'type': 'rental_returned',
          'detail': '${r['bookName']} returned',
          'date': r['dateReturned'],
        });
      }
    }

    final sections = <_OverviewSection>[];
    if (dateExpenses.isNotEmpty) {
      sections.add(_OverviewSection(
        icon: Iconsax.money_recive, color: Colors.red, title: lang.Lang.tr('expenses'),
        lines: dateExpenses.map((e) =>
            '${e['category'] ?? ''}: ৳${((e['amount'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0)}${(e['note']?.toString() ?? '').isNotEmpty ? ' (${e['note']})' : ''}').toList(),
      ));
    }
    if (datePurchases.isNotEmpty) {
      sections.add(_OverviewSection(
        icon: Iconsax.bag, color: Colors.orange, title: lang.Lang.tr('stockPurchases'),
        lines: datePurchases.map((p) =>
            '${p['itemName'] ?? ''} × ${p['quantity'] ?? 1}: ৳${((p['amount'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0)}').toList(),
      ));
    }
    if (dateInvestorRepayments.isNotEmpty) {
      sections.add(_OverviewSection(
        icon: Iconsax.building, color: Colors.teal, title: lang.Lang.tr('investorRepayments'),
        lines: dateInvestorRepayments.map((r) =>
            '${r['investor']}: ৳${(r['amount'] ?? 0.0).toStringAsFixed(0)}').toList(),
      ));
    }
    if (dateCustomerActivity.isNotEmpty) {
      sections.add(_OverviewSection(
        icon: Iconsax.people, color: Colors.blue, title: lang.Lang.tr('customerActivity'),
        lines: dateCustomerActivity.map((a) {
          final prefix = a['type'] == 'purchase' ? '[Purchase]' :
              a['type'] == 'order' ? '[Order]' :
              a['type'] == 'rental_taken' ? '[Rental]' : '[Return]';
          return '$prefix ${a['customer']}: ${a['detail']}';
        }).toList(),
      ));
    }

    if (sections.isEmpty) return const SizedBox.shrink();
    return const SizedBox.shrink();
  }

  void _showDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.day,
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showEditSaleBottomSheet(int saleIndex, Map<dynamic, dynamic>? sale) {
    if (sale == null) return;

    final editNameController = TextEditingController(text: sale['productName']?.toString() ?? '');
    final editAmountController = TextEditingController(text: sale['amount']?.toString() ?? '');
    String editType = sale['type']?.toString() ?? 'cash';
    Map<dynamic, dynamic>? matchedProduct;
    List<Map<dynamic, dynamic>> editFilteredProducts = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          void searchProducts(String query) {
            setSheetState(() {
              final allProducts = List<Map<dynamic, dynamic>>.from(_inventoryBox.get('products', defaultValue: []));
              if (query.isEmpty) {
                editFilteredProducts = [];
              } else {
                editFilteredProducts = allProducts.where((product) {
                  final name = product['name']?.toString().toLowerCase() ?? '';
                  return name.contains(query.toLowerCase());
                }).toList();
              }
            });
          }

          void selectProduct(Map<dynamic, dynamic> product) {
            setSheetState(() {
              matchedProduct = product;
              editNameController.text = product['name']?.toString() ?? '';
              editFilteredProducts = [];
            });
          }

          void saveSale() {
            double amount = double.tryParse(editAmountController.text) ?? 0.0;
            double profit = 0.0;

            if (matchedProduct != null) {
              double buyPrice = double.tryParse(matchedProduct!['buyPrice']?.toString() ?? '0') ?? 0.0;
              double sellPrice = double.tryParse(matchedProduct!['sellPrice']?.toString() ?? '0') ?? 0.0;
              double buyConv = double.tryParse(matchedProduct!['buyConversionFactor']?.toString() ?? '1') ?? 1.0;
              double sellConv = double.tryParse(matchedProduct!['sellConversionFactor']?.toString() ?? '1') ?? 1.0;
              if (amount <= 0) amount = sellPrice;
              double qty = sellPrice > 0 ? (amount / sellPrice) : 1;
              double costPerBase = buyConv > 0 ? buyPrice / buyConv : 0;
              double baseQty = qty * sellConv;
              double costOfGoodsSold = costPerBase * baseQty;
              profit = amount - costOfGoodsSold;
            } else {
              profit = amount * 0.10;
            }

            final allSales = List<Map<dynamic, dynamic>>.from(_salesBox.get('sales', defaultValue: []));
            final idx = allSales.indexWhere((s) => s['id'] == sale['id']);
            if (idx < 0) return;
            allSales[idx] = {
              'id': sale['id'],
              'date': sale['date'],
              'productName': editNameController.text,
              'amount': amount,
              'profit': profit,
              'type': editType,
            };
            _salesBox.put('sales', allSales);

            double oldAmount = sale['amount']?.toDouble() ?? 0.0;
            double oldProfit = sale['profit']?.toDouble() ?? 0.0;
            bool oldIsCredit = sale['type']?.toString() == 'credit';
            bool newIsCredit = editType == 'credit';
            double cashDelta = (newIsCredit ? 0 : amount) - (oldIsCredit ? 0 : oldAmount);
            salesNotifier.value = {
              'cash': salesNotifier.value['cash']! + cashDelta,
              'profit': salesNotifier.value['profit']! - oldProfit + profit,
            };

            Navigator.pop(context);
          }

          final sheetBg = Theme.of(context).colorScheme.surface;
          return Container(
            decoration: BoxDecoration(
              color: sheetBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(
              left: 16, right: 16, top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(lang.Lang.tr('editSale'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTeal)),
                const SizedBox(height: 16),
                TextField(
                  controller: editNameController,
                  onChanged: searchProducts,
                  decoration: InputDecoration(
                    labelText: lang.Lang.tr('productName'),
                    prefixIcon: const Icon(Iconsax.box, size: 20),
                  ),
                ),
                if (editFilteredProducts.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: editFilteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = editFilteredProducts[index];
                        final name = product['name']?.toString() ?? 'Unknown';
                        final sell = product['sellPrice']?.toString() ?? '0';
                        return ListTile(
                          dense: true,
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text('${lang.Lang.tr('sellLabel')}৳${(double.tryParse(sell) ?? 0.0).toStringAsFixed(0)}'),
                          trailing: const Icon(Iconsax.add_circle, color: kTeal, size: 20),
                          onTap: () => selectProduct(product),
                        );
                      },
                    ),
                  ),
                if (matchedProduct != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: kTeal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kTeal.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Iconsax.tick_circle, color: kTeal, size: 18),
                        const SizedBox(width: 8),
                        Text('${lang.Lang.tr('matched')}${matchedProduct!['name']}',
                            style: const TextStyle(color: kTeal, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: editAmountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: lang.Lang.tr('amountTaka'),
                    prefixIcon: const Icon(Iconsax.money, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: Text(lang.Lang.tr('cash')),
                        selected: editType == 'cash',
                        onSelected: (v) => setSheetState(() => editType = 'cash'),
                        selectedColor: kTeal,
                        labelStyle: TextStyle(color: editType == 'cash' ? Colors.white : null),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ChoiceChip(
                        label: Text(lang.Lang.tr('credit')),
                        selected: editType == 'credit',
                        onSelected: (v) => setSheetState(() => editType = 'credit'),
                        selectedColor: Colors.orange,
                        labelStyle: TextStyle(color: editType == 'credit' ? Colors.white : null),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: saveSale,
                    icon: const Icon(Iconsax.tick_circle, size: 18),
                    label: Text(lang.Lang.tr('updateSale')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: kTeal,
          leading: IconButton(
            icon: const Icon(Iconsax.menu),
            onPressed: widget.onMenuTap,
          ),
          title: shopLogo(size: 20, color: Colors.white),
          actions: [
            TextButton(
              onPressed: _showDatePicker,
              child: Text(DateFormat('dd-MM-yyyy').format(_selectedDate),
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
            ),
            IconButton(
              icon: const Icon(Iconsax.calendar, color: Colors.white),
              onPressed: _showDatePicker,
            ),
          ],
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: lang.Lang.tr('sales')),
              Tab(text: lang.Lang.tr('rent')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildSalesTab(),
            _buildRentTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: kTeal,
          foregroundColor: Colors.white,
          onPressed: () => setState(() => _showForm = !_showForm),
          child: Icon(_showForm ? Iconsax.close_circle : Iconsax.add),
        ),
      ),
    );
  }

  Widget _buildSalesTab() {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: ValueListenableBuilder(
            valueListenable: _salesBox.listenable(),
            builder: (context, Box box, child) {
              // Also listen to financeBox so purchases update Total Buy
              return ValueListenableBuilder(
                valueListenable: _financeBox.listenable(),
                builder: (context, _, a) {
              final List<dynamic> allSales = box.get('sales', defaultValue: []);
          final List<dynamic> dateFiltered = allSales.where((item) {
            final saleDate = (item as Map<dynamic, dynamic>?)?['date']?.toString() ?? '';
            return saleDate == DateFormat('dd-MM-yyyy').format(_selectedDate);
          }).toList();
          final List<dynamic> filteredSales = _salesSearchQuery.isEmpty
              ? dateFiltered
              : dateFiltered.where((item) {
                  final name = (item as Map<dynamic, dynamic>?)?['productName']?.toString().toLowerCase() ?? '';
                  return name.contains(_salesSearchQuery.toLowerCase());
                }).toList();

          final dateStr = DateFormat('dd-MM-yyyy').format(_selectedDate);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                        const SizedBox(height: 10),
                        _buildDailyOverview(dateStr),
                        const SizedBox(height: 15),


                       TextField(
                        controller: _salesSearchController,
                        onChanged: (value) {
                          setState(() {
                            _salesSearchQuery = value;
                          });
                        },
                        decoration: InputDecoration(hintText: lang.Lang.tr('searchSales'), prefixIcon: Icon(Iconsax.search_normal)),
                      ),
                     const SizedBox(height: 10),
                      if (filteredSales.isEmpty && _salesSearchQuery.isNotEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 32,
                                  backgroundColor: Colors.grey.shade200,
                                  child: const Icon(Iconsax.search_normal, size: 32, color: Colors.grey),
                                ),
                                const SizedBox(height: 12),
                                Text(lang.Lang.tr('noMatchingSales'),
                                    style: TextStyle(fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        )
                     else
                       ListView.builder(
                         shrinkWrap: true,
                         physics: const NeverScrollableScrollPhysics(),
                         itemCount: filteredSales.length,
                         itemBuilder: (context, index) {
                           final sale = filteredSales[index] as Map<dynamic, dynamic>?;
                           final productName = sale?['productName']?.toString() ?? 'Unknown';
                           final amount = sale?['amount']?.toString() ?? '0';
                           final profit = sale?['profit']?.toString() ?? '0';
                           final date = sale?['date']?.toString() ?? '';
                           final type = sale?['type']?.toString() ?? 'cash';
                           final isCredit = type == 'credit';

                           return Card(
                             margin: const EdgeInsets.only(bottom: 8),
                             elevation: 1,
                             shape: RoundedRectangleBorder(
                               borderRadius: BorderRadius.circular(10),
                               side: isCredit
                                   ? BorderSide(color: Colors.red.shade200)
                                   : BorderSide.none,
                             ),
                             child: Padding(
                               padding: const EdgeInsets.all(12),
                               child: Row(
                                 children: [
                                   Container(
                                     width: 40,
                                     height: 40,
                                     decoration: BoxDecoration(
                                       color: isCredit ? Colors.red.shade50 : Colors.teal.shade50,
                                       borderRadius: BorderRadius.circular(10),
                                     ),
                                     child: Icon(
                                       isCredit ? Iconsax.card : Iconsax.bag,
                                       size: 20,
                                        color: isCredit ? Colors.red : kTeal,
                                     ),
                                   ),
                                   const SizedBox(width: 12),
                                   Expanded(
                                     child: Column(
                                       crossAxisAlignment: CrossAxisAlignment.start,
                                       children: [
                                         Text(productName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                         const SizedBox(height: 2),
                                          Text('$date  •  ${isCredit ? lang.Lang.tr('credit') : lang.Lang.tr('cash')}',
                                             style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                       ],
                                     ),
                                   ),
                                   Column(
                                     crossAxisAlignment: CrossAxisAlignment.end,
                                     children: [
                                       Text('৳${(double.tryParse(amount) ?? 0.0).toStringAsFixed(0)}',
                                           style: TextStyle(fontWeight: FontWeight.bold, color: isCredit ? Colors.red : Colors.green.shade700, fontSize: 14)),
                                       Text('+ ৳${(double.tryParse(profit) ?? 0.0).toStringAsFixed(0)}',
                                           style: TextStyle(fontSize: 11, color: Colors.teal.shade600)),
                                     ],
                                   ),
                                   const SizedBox(width: 4),
                                   PopupMenuButton<String>(
                                     icon: const Icon(Iconsax.more, size: 18, color: Colors.grey),
                                     onSelected: (v) {
                                       if (v == 'edit') _showEditSaleBottomSheet(index, sale);
                                       if (v == 'delete') _deleteSale(sale);
                                     },
                                      itemBuilder: (_) => [
                                        PopupMenuItem(value: 'edit', child: Text(lang.Lang.tr('edit'), style: TextStyle(fontSize: 13))),
                                        PopupMenuItem(value: 'delete', child: Text(lang.Lang.tr('delete'), style: TextStyle(fontSize: 13, color: Colors.red))),
                                      ],
                                   ),
                                  ],
         ),
       ),
    );
                          },
                         ),
                    ],
                 ),
                );
              },
             );
           },
         ),
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          bottom: _showForm ? 0 : -600,
          left: 0,
          right: 0,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 80,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kTeal.withValues(alpha: 0.15)),
                ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _productSearchController,
                    onChanged: _searchProducts,
                    decoration: InputDecoration(
                      hintText: lang.Lang.tr('searchProduct'),
                      prefixIcon: Icon(Iconsax.search_normal),
                    ),
                  ),
                  if (_filteredProducts.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          final name = product['name']?.toString() ?? 'Unknown';
                          final sell = product['sellPrice']?.toString() ?? '0';
                          final stock = product['qty']?.toString() ?? '0';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 6),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: kTeal.withValues(alpha: 0.1)),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor: kTeal.withValues(alpha: 0.1),
                                child: const Icon(Iconsax.box, color: kTeal, size: 18),
                              ),
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              subtitle: Text('${lang.Lang.tr('sellLabel')}৳${(double.tryParse(sell) ?? 0.0).toStringAsFixed(0)}  •  ${lang.Lang.tr('stockLabel')}$stock',
                                  style: const TextStyle(fontSize: 11)),
                              trailing: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: kTeal.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Iconsax.add_circle, color: kTeal, size: 20),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              onTap: () => _selectProduct(product),
                            ),
                          );
                        },
                      ),
                    ),
                  if (_selectedProduct != null)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kTeal.withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: kTeal.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: kTeal.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Iconsax.tick_circle, size: 16, color: kTeal),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text('${_selectedProduct!['name']}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: kTeal.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${lang.Lang.tr('sellPriceLabel')}৳${(double.tryParse(_selectedProduct!['sellPrice']?.toString() ?? '0') ?? 0.0).toStringAsFixed(0)}  •  ${lang.Lang.tr('stockLabel2')}${_selectedProduct!['qty']}',
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedBuyerName ?? '',
                            decoration: InputDecoration(
                              labelText: lang.Lang.tr('buyerOptional'),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            isExpanded: true,
                            items: [
                              DropdownMenuItem(value: '', child: Text(lang.Lang.tr('none'), style: TextStyle(color: Colors.grey))),
                              ..._buyerCustomers.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))),
                            ],
                            onChanged: (v) => setState(() => _selectedBuyerName = v?.isNotEmpty == true ? v : null),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _quickSaleController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: lang.Lang.tr('quantity'),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: _addQuickSale,
                                icon: const Icon(Iconsax.shopping_cart, size: 18),
                                label: const Text('Sell', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kTeal,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        ),
      ],
    );
    }

  Widget _buildRentTab() {
    final dateStr = DateFormat('dd-MM-yyyy').format(_selectedDate);
    final activeRentals = _bookRentals.where((r) =>
        (r['dateReturned']?.toString() ?? '').isEmpty).toList();
    final returnedRentals = _bookRentals.where((r) =>
        (r['dateReturned']?.toString() ?? '').isNotEmpty &&
        r['dateTaken']?.toString() == dateStr).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          // Add book to rent inventory
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            padding: const EdgeInsets.only(left: 8),
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: kTeal, width: 3)),
            ),
            child: Text(lang.Lang.tr('addBookToRent'),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                    controller: _bookNameCtrl,
                    decoration: InputDecoration(
                        labelText: lang.Lang.tr('bookName'),
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 10))),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 80,
                child: TextField(
                    controller: _pageCountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: lang.Lang.tr('pages'),
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 10))),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 60,
                child: TextField(
                    controller: _copiesCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: lang.Lang.tr('copies'),
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 10))),
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                onPressed: _addRentBook,
                style: ElevatedButton.styleFrom(
                    backgroundColor: kTeal, foregroundColor: Colors.white),
                child: Text(lang.Lang.tr('add')),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Book list
          if (_rentBooks.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              padding: const EdgeInsets.only(left: 8),
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: kTeal, width: 3)),
              ),
              child: Text(lang.Lang.tr('availableBooks'),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 110,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _rentBooks.map((b) {
                  final price = _rentPrice(
                      b['pageCount'] as int, 10);
                  final isSelected = _selectedRentBookName == b['name'];
                  return GestureDetector(
                    onTap: () => setState(() =>
                        _selectedRentBookName = b['name'] as String?),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 140,
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? kTeal.withValues(alpha: 0.1)
                            : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                        border: isSelected
                            ? Border.all(color: kTeal, width: 1.5)
                            : Border.all(color: Colors.grey.shade200),
                        boxShadow: isSelected
                            ? [BoxShadow(color: kTeal.withValues(alpha: 0.15), blurRadius: 6, offset: const Offset(0, 2))]
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Iconsax.book, size: 14, color: isSelected ? kTeal : Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(b['name'] as String,
                                    style: TextStyle(
                                        fontSize: 11, fontWeight: FontWeight.bold,
                                        color: isSelected ? kTeal : null),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Text('${b['pageCount']}p',
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.grey)),
                              const Spacer(),
                              Text('x${b['copies']}',
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.black54)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text('\u09F3${price.toStringAsFixed(0)}/10d',
                                  style: TextStyle(
                                      fontSize: 10, color: kTeal, fontWeight: FontWeight.w600)),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => _deleteRentBook(b['id'] as String),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(Iconsax.trash,
                                      size: 12, color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Rent out form
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            padding: const EdgeInsets.only(left: 8),
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: kTeal, width: 3)),
            ),
            child: Text(lang.Lang.tr('rentOutBook'),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ),
          if (_selectedRentBookName != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: kTeal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('${lang.Lang.tr('selected')}$_selectedRentBookName',
                  style: const TextStyle(
                      fontSize: 12, color: kTeal, fontWeight: FontWeight.bold)),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                    controller: _rentCustomerCtrl,
                    decoration: InputDecoration(
                        labelText: lang.Lang.tr('customerName'),
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 10))),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 80,
                child: TextField(
                    controller: _rentDaysCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: lang.Lang.tr('days'),
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 10))),
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                onPressed: _rentOutBook,
                style: ElevatedButton.styleFrom(
                    backgroundColor: kTeal, foregroundColor: Colors.white),
                child: Text(lang.Lang.tr('rent')),
              ),
            ],
          ),

          // Active rentals
          if (activeRentals.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              padding: const EdgeInsets.only(left: 8),
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: Colors.blue, width: 3)),
              ),
              child: Text(lang.Lang.tr('activeRentals'),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.blue)),
            ),
            ...activeRentals.map((r) {
              final idx = _bookRentals.indexOf(r);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Iconsax.book, size: 18, color: Colors.blue),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${r['bookName']}  →  ${r['customerName']}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(
                              'Taken: ${r['dateTaken']}  |  Due: ${r['expectedReturn']}',
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                          Row(
                            children: [
                              Icon(Iconsax.money, size: 12, color: r['isPaid'] == true ? Colors.green : Colors.orange),
                              const SizedBox(width: 4),
                              Text('\u09F3${((r['cost'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0)}',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: r['isPaid'] == true ? Colors.green : Colors.orange)),
                              Text(r['isPaid'] == true ? ' (Paid)' : ' (Unpaid)',
                                  style: TextStyle(fontSize: 10, color: r['isPaid'] == true ? Colors.green : Colors.orange)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        if (r['isPaid'] != true)
                          Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: const Icon(Iconsax.money, size: 16, color: Colors.orange),
                              onPressed: () => _toggleRentPaid(idx),
                              tooltip: 'Mark paid',
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: const Icon(Iconsax.refresh, size: 16, color: Colors.green),
                            onPressed: () => _returnBook(idx),
                            tooltip: 'Return',
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ] else ...[
            const SizedBox(height: 12),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.grey.shade200,
                      child: const Icon(Iconsax.book_1, size: 28, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Text('No active rentals',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ],

          // Today's returned rentals
          if (returnedRentals.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              padding: const EdgeInsets.only(left: 8),
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: Colors.green, width: 3)),
              ),
              child: Text('Returned Today',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.green)),
            ),
            ...returnedRentals.map((r) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                          r['isPaid'] == true ? Iconsax.tick_circle : Iconsax.close_circle,
                          size: 18,
                          color: r['isPaid'] == true ? Colors.green : Colors.red),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${r['bookName']} → ${r['customerName']}',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: r['isPaid'] == true ? null : Colors.red)),
                          const SizedBox(height: 2),
                          Text('\u09F3${((r['cost'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0)} ${r['isPaid'] == true ? '(Paid)' : '(Unpaid)'}',
                              style: TextStyle(fontSize: 11, color: r['isPaid'] == true ? Colors.green : Colors.red, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          // All rentals for the day
          if (_bookRentals.any(
              (r) => r['dateTaken']?.toString() == dateStr)) ...[
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              padding: const EdgeInsets.only(left: 8),
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: kTeal, width: 3)),
              ),
              child: Text('All Rentals on This Date',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ),
            ..._bookRentals
                .where((r) => r['dateTaken']?.toString() == dateStr)
                .map((r) {
              final idx = _bookRentals.indexOf(r);
              final returned =
                  (r['dateReturned']?.toString() ?? '').isNotEmpty;
              final color = returned ? Colors.green : Colors.orange;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: color.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                          returned ? Iconsax.tick_circle : Iconsax.clock,
                          size: 18,
                          color: color),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${r['bookName']} → ${r['customerName']}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text(
                              'Taken: ${r['dateTaken']}  |  \u09F3${((r['cost'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0)}'
                              '${returned ? '  |  Returned: ${r['dateReturned']}' : '  |  Active'}',
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: r['isPaid'] == true
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(
                            r['isPaid'] == true ? Iconsax.money : Iconsax.money_recive,
                            size: 16,
                            color: r['isPaid'] == true ? Colors.green : Colors.orange),
                        onPressed: () => _toggleRentPaid(idx),
                        tooltip: r['isPaid'] == true ? 'Mark unpaid' : 'Mark paid',
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
