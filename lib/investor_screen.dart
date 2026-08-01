import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'models.dart';
import 'shop_logo.dart';
import 'lang.dart' as lang;
import 'constants.dart';

class InvestorScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  const InvestorScreen({super.key, this.onMenuTap});

  @override
  State<InvestorScreen> createState() => _InvestorScreenState();
}

class _InvestorScreenState extends State<InvestorScreen> {
  final _investorBox = Hive.box('investorBox');
  final _inventoryBox = Hive.box('inventoryBox');
  final _salesBox = Hive.box('salesBox');

  List<Investor> _investors = [];
  DateTime? _selectedDate;
  bool _showForm = false;
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _cashCtrl = TextEditingController();
  final _productCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _profitCtrl = TextEditingController();
  String _contractType = 'profitShare';
  String _investType = 'cash';

  @override
  void initState() {
    super.initState();
    _loadData();
    _showForm = true;
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _showForm = false);
    });
  }

  void _loadData() {
    final stored = _investorBox.get('investors', defaultValue: []);
    setState(() {
      _investors = List<Map<dynamic, dynamic>>.from(stored)
          .map((inv) => Investor.fromMap(Map<String, dynamic>.from(inv)))
          .toList();
      for (final inv in _investors) {
        _recalcFromStockAndSales(inv);
      }
      _saveData();
    });
  }

  void _saveData() {
    _investorBox.put('investors', _investors.map((inv) => inv.toMap()).toList());
  }

  void _recalcFromStockAndSales(Investor inv) {
    final products = List<Map<dynamic, dynamic>>.from(
        _inventoryBox.get('products', defaultValue: []));
    final invProds =
        products.where((p) => p['investor']?.toString() == inv.name).toList();

    double stockValue = 0.0;
    double totalBought = 0.0;
    final productNames = <String>{};

    for (final p in invProds) {
      final qty = double.tryParse(p['qty']?.toString() ?? '0') ?? 0.0;
      final buyPrice = double.tryParse(p['buyPrice']?.toString() ?? '0') ?? 0.0;
      final buyQty = double.tryParse(p['buyQty']?.toString() ?? '1') ?? 1.0;
      final buyConversionFactor = double.tryParse(p['buyConversionFactor']?.toString() ?? '1') ?? 1.0;
      final name = p['name']?.toString() ?? '';
      productNames.add(name);
      stockValue += (buyConversionFactor > 0 ? buyPrice / buyConversionFactor : 0) * qty;
      totalBought += buyQty * buyPrice;
    }

    final allSales = List<Map<dynamic, dynamic>>.from(
        _salesBox.get('sales', defaultValue: []));
    double sold = 0.0;
    double profit = 0.0;
    for (final s in allSales) {
      final pn = s['productName']?.toString() ?? '';
      if (productNames.contains(pn)) {
        sold += s['amount']?.toDouble() ?? 0.0;
        profit += s['profit']?.toDouble() ?? 0.0;
      }
    }

    inv.productValueTotal = stockValue;
    inv.totalBought = totalBought;
    inv.totalSold = sold;
    inv.totalProfit = profit;

    final repaid = inv.repayments.fold(0.0, (s, r) => s + r.amount);
    if (inv.investmentType == 'products' || inv.contractType == 'consignment') {
      inv.remainingBalance = stockValue;
    } else {
      inv.remainingBalance = inv.investedAmount - repaid;
    }
  }

  String _contractLabel(String ct) {
    switch (ct) {
      case 'loan':
        return lang.Lang.tr('cashLoan');
      case 'consignment':
        return lang.Lang.tr('productConsignment');
      case 'profitShare':
        return lang.Lang.tr('profitSplit');
      default:
        return ct;
    }
  }

  String _investLabel(String it) {
    switch (it) {
      case 'cash':
        return lang.Lang.tr('cashInvestment');
      case 'products':
        return lang.Lang.tr('productConsignment');
      case 'mixed':
        return lang.Lang.tr('mixed');
      default:
        return it;
    }
  }

  // ---- ADD / EDIT DIALOG ----
  void _showAddDialog({Investor? edit}) {
    final nameCtrl = TextEditingController(text: edit?.name ?? '');
    final amountCtrl = TextEditingController(
        text: edit != null ? edit.cashInvested.toString() : '');
    final cashCtrl = TextEditingController(
        text: edit != null ? edit.cashInvested.toString() : '');
    final productCtrl = TextEditingController(
        text: edit != null ? (edit.productInvested > 0 ? edit.productInvested.toString() : '') : '');
    final durationCtrl = TextEditingController(
        text: edit != null ? edit.durationMonths.toString() : '');
    final profitCtrl = TextEditingController(
        text: edit != null ? edit.profitPercentage.toString() : '');
    String contractType = edit?.contractType ?? 'profitShare';
    String investType = edit?.investmentType ?? 'cash';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          Widget contractDropdown() => DropdownButtonFormField<String>(
                initialValue: contractType,
                decoration: InputDecoration(
                  labelText: lang.Lang.tr('contractType'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(kButtonRadius)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: [
                  DropdownMenuItem(value: 'loan', child: Text(lang.Lang.tr('cashLoan'))),
                  DropdownMenuItem(
                      value: 'consignment', child: Text(lang.Lang.tr('productConsignment'))),
                  DropdownMenuItem(
                      value: 'profitShare', child: Text(lang.Lang.tr('profitSplit'))),
                ],
                onChanged: (v) => setDlgState(() {
                  contractType = v ?? 'profitShare';
                  if (contractType == 'consignment') investType = 'products';
                }),
              );

          Widget investTypeDropdown() => DropdownButtonFormField<String>(
                initialValue: investType == 'mixed' ? 'mixed' : 'cash',
                decoration: InputDecoration(
                  labelText: lang.Lang.tr('investmentType'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(kButtonRadius)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: [
                  DropdownMenuItem(value: 'cash', child: Text(lang.Lang.tr('cashInvestment'))),
                  DropdownMenuItem(
                      value: 'mixed', child: Text(lang.Lang.tr('mixed'))),
                ],
                onChanged: (v) => setDlgState(() => investType = v ?? 'cash'),
              );

          void calcFromStock() {
            final products = List<Map<dynamic, dynamic>>.from(
                _inventoryBox.get('products', defaultValue: []));
            final matched = products
                .where((p) =>
                    p['investor']?.toString().toLowerCase() ==
                    nameCtrl.text.toLowerCase())
                .toList();
            double total = 0.0;
            for (final p in matched) {
              final qty = double.tryParse(p['buyQty']?.toString() ?? '1') ?? 1.0;
              final price =
                  double.tryParse(p['buyPrice']?.toString() ?? '0') ?? 0.0;
              total += qty * price;
            }
            productCtrl.text = total.toStringAsFixed(2);
            if (matched.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${lang.Lang.tr('foundProducts')} ${matched.length}${lang.Lang.tr('totalTaka')}$total'),
                backgroundColor: Colors.green,
              ));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(lang.Lang.tr('noProductsForInvestor')),
                backgroundColor: Colors.orange,
              ));
            }
          }

          void save() {
            if (nameCtrl.text.isEmpty) return;
            double invested = 0.0;
            double cashPart = 0.0;
            double productPart = 0.0;

            if (investType == 'cash') {
              cashPart = double.tryParse(amountCtrl.text) ?? 0.0;
              invested = cashPart;
            } else if (investType == 'products') {
              productPart = double.tryParse(productCtrl.text) ?? 0.0;
              invested = productPart;
            } else {
              cashPart = double.tryParse(cashCtrl.text) ?? 0.0;
              productPart = double.tryParse(productCtrl.text) ?? 0.0;
              invested = cashPart + productPart;
            }

            if (invested <= 0 && investType == 'cash') {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(lang.Lang.tr('enterInvestment')),
                backgroundColor: Colors.red,
              ));
              return;
            }

            setState(() {
              if (edit != null) {
                final idx = _investors.indexWhere((i) => i.id == edit.id);
                if (idx >= 0) {
                  _investors[idx] = Investor(
                    id: edit.id,
                    name: nameCtrl.text,
                    investedAmount: invested,
                    durationMonths: int.tryParse(durationCtrl.text) ?? 12,
                    profitPercentage: double.tryParse(profitCtrl.text) ?? 0.0,
                    contractType: contractType,
                    investmentType: investType,
                    isActive: true,
                    startDate: edit.startDate.isEmpty
                        ? DateFormat('dd-MM-yyyy').format(DateTime.now())
                        : edit.startDate,
                    cashInvested: cashPart,
                    productInvested: productPart,
                    repayments: edit.repayments,
                  );
                  _recalcFromStockAndSales(_investors[idx]);
                }
              } else {
                _investors.add(Investor(
                  id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameCtrl.text,
                  investedAmount: invested,
                  durationMonths: int.tryParse(durationCtrl.text) ?? 12,
                  profitPercentage: double.tryParse(profitCtrl.text) ?? 0.0,
                  contractType: contractType,
                  investmentType: investType,
                  isActive: true,
                  startDate:
                      DateFormat('dd-MM-yyyy').format(DateTime.now()),
                  cashInvested: cashPart,
                  productInvested: productPart,
                ));
                _recalcFromStockAndSales(_investors.last);
              }
              _saveData();
            });
            Navigator.pop(ctx);
          }

          return AlertDialog(
            title: Text(
              edit != null ? lang.Lang.tr('editInvestor') : lang.Lang.tr('addInvestor'),
              style: const TextStyle(fontWeight: FontWeight.bold, color: kTeal),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: nameCtrl,
                      decoration:
                          InputDecoration(labelText: lang.Lang.tr('investorName')),
                  ),
                    const SizedBox(height: 14),
                    contractDropdown(),
                    const SizedBox(height: 14),
                    if (contractType != 'consignment') ...[
                      investTypeDropdown(),
                      const SizedBox(height: 14),
                    ],
                    if (investType == 'cash' && contractType != 'consignment')
                      TextField(
                        controller: amountCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            InputDecoration(labelText: lang.Lang.tr('cashAmount')),
                      ),
                    if (investType == 'mixed') ...[
                      TextField(
                        controller: cashCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            InputDecoration(labelText: lang.Lang.tr('cashAmount')),
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (investType == 'products' || investType == 'mixed') ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: productCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                  labelText: lang.Lang.tr('productValue')),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Iconsax.trend_up, color: kTeal),
                            tooltip: lang.Lang.tr('calcFromStock'),
                            onPressed: calcFromStock,
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                    TextField(
                      controller: durationCtrl,
                      keyboardType: TextInputType.number,
                      decoration:
                          InputDecoration(labelText: lang.Lang.tr('durationMonths')),
                    ),
                    const SizedBox(height: 14),
                  TextField(
                    controller: profitCtrl,
                    keyboardType: TextInputType.number,
                    decoration:
                        InputDecoration(labelText: lang.Lang.tr('profitShare')),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(lang.Lang.tr('cancel'))),
              ElevatedButton(
                onPressed: save,
                style: ElevatedButton.styleFrom(
                    backgroundColor: kTeal, foregroundColor: Colors.white),
                child: Text(lang.Lang.tr('save')),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---- FORM HELPERS ----
  void _clearForm() {
    _nameCtrl.clear();
    _amountCtrl.clear();
    _cashCtrl.clear();
    _productCtrl.clear();
    _durationCtrl.clear();
    _profitCtrl.clear();
    _contractType = 'profitShare';
    _investType = 'cash';
  }

  void _saveFromForm() {
    if (_nameCtrl.text.isEmpty) return;
    double invested = 0.0;
    double cashPart = 0.0;
    double productPart = 0.0;

    if (_investType == 'cash') {
      cashPart = double.tryParse(_amountCtrl.text) ?? 0.0;
      invested = cashPart;
    } else if (_investType == 'products') {
      productPart = double.tryParse(_productCtrl.text) ?? 0.0;
      invested = productPart;
    } else {
      cashPart = double.tryParse(_cashCtrl.text) ?? 0.0;
      productPart = double.tryParse(_productCtrl.text) ?? 0.0;
      invested = cashPart + productPart;
    }

    if (invested <= 0 && _investType == 'cash') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(lang.Lang.tr('enterInvestment')),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() {
      _investors.add(Investor(
        id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameCtrl.text,
        investedAmount: invested,
        durationMonths: int.tryParse(_durationCtrl.text) ?? 12,
        profitPercentage: double.tryParse(_profitCtrl.text) ?? 0.0,
        contractType: _contractType,
        investmentType: _investType,
        isActive: true,
        startDate: DateFormat('dd-MM-yyyy').format(DateTime.now()),
        cashInvested: cashPart,
        productInvested: productPart,
      ));
      _recalcFromStockAndSales(_investors.last);
      _saveData();
      _showForm = false;
      _clearForm();
    });
  }

  void _calcFromStock() {
    final products = List<Map<dynamic, dynamic>>.from(
        _inventoryBox.get('products', defaultValue: []));
    final matched = products
        .where((p) =>
            p['investor']?.toString().toLowerCase() ==
            _nameCtrl.text.toLowerCase())
        .toList();
    double total = 0.0;
    for (final p in matched) {
      final qty = double.tryParse(p['buyQty']?.toString() ?? '1') ?? 1.0;
      final price =
          double.tryParse(p['buyPrice']?.toString() ?? '0') ?? 0.0;
      total += qty * price;
    }
    setState(() {
      _productCtrl.text = total.toStringAsFixed(2);
    });
    if (matched.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${lang.Lang.tr('foundProducts')} ${matched.length}${lang.Lang.tr('totalTaka')}$total'),
        backgroundColor: Colors.green,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(lang.Lang.tr('noProductsForInvestor')),
        backgroundColor: Colors.orange,
      ));
    }
  }

  Widget _contractDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _contractType,
      decoration: InputDecoration(
        labelText: lang.Lang.tr('contractType'),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(kButtonRadius)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: [
        DropdownMenuItem(value: 'loan', child: Text(lang.Lang.tr('cashLoan'))),
        DropdownMenuItem(value: 'consignment', child: Text(lang.Lang.tr('productConsignment'))),
        DropdownMenuItem(value: 'profitShare', child: Text(lang.Lang.tr('profitSplit'))),
        DropdownMenuItem(value: 'mudaraba', child: Text(lang.Lang.tr('mudaraba'))),
        DropdownMenuItem(value: 'musharaka', child: Text(lang.Lang.tr('musharaka'))),
      ],
      onChanged: (v) {
        setState(() {
          _contractType = v ?? 'profitShare';
          if (_contractType == 'consignment') _investType = 'products';
        });
      },
    );
  }

  Widget _investTypeDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _investType == 'mixed' ? 'mixed' : 'cash',
      decoration: InputDecoration(
        labelText: lang.Lang.tr('investmentType'),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(kButtonRadius)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: [
        DropdownMenuItem(value: 'cash', child: Text(lang.Lang.tr('cashInvestment'))),
        DropdownMenuItem(value: 'mixed', child: Text(lang.Lang.tr('mixed'))),
      ],
      onChanged: (v) {
        setState(() => _investType = v ?? 'cash');
      },
    );
  }

  // ---- REPAYMENT DIALOG ----
  void _showRepaymentDialog(Investor inv) {
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lang.Lang.tr('addRepayment'),
            style: TextStyle(fontWeight: FontWeight.bold, color: kTeal)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amtCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: lang.Lang.tr('repaymentAmount')),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: noteCtrl,
              decoration:
                  InputDecoration(labelText: lang.Lang.tr('noteOptional')),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(lang.Lang.tr('cancel'))),
          ElevatedButton(
            onPressed: () {
              final amt = double.tryParse(amtCtrl.text) ?? 0.0;
              if (amt <= 0) return;
              setState(() {
                inv.repayments = [
                  ...inv.repayments,
                  Repayment(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    amount: amt,
                    date: DateFormat('dd-MM-yyyy').format(DateTime.now()),
                    notes: noteCtrl.text,
                  ),
                ];
                if (inv.contractType != 'consignment') {
                  inv.remainingBalance -= amt;
                }
                _saveData();
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: kTeal, foregroundColor: Colors.white),
            child: Text(lang.Lang.tr('add')),
          ),
        ],
      ),
    );
  }

  // ---- DETAILS BOTTOM SHEET ----
  void _showDetails(Investor inv) {
    final repaid = inv.repayments.fold(0.0, (s, r) => s + r.amount);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollCtrl) => Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scrollCtrl,
            children: [
              Text(inv.name,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const Divider(),
              _detailRow(lang.Lang.tr('contract'), _contractLabel(inv.contractType)),
              _detailRow(lang.Lang.tr('investType'), _investLabel(inv.investmentType)),
              if (inv.cashInvested > 0)
                _detailRow(
                    lang.Lang.tr('cashInvested'), '৳${inv.cashInvested.toStringAsFixed(2)}'),
              if (inv.productInvested > 0)
                _detailRow(lang.Lang.tr('productsValue'),
                    '৳${inv.productInvested.toStringAsFixed(2)}'),
              _detailRow(lang.Lang.tr('totalInvested'),
                  '৳${inv.investedAmount.toStringAsFixed(2)}'),
              _detailRow(lang.Lang.tr('duration'), '${inv.durationMonths} months'),
              _detailRow(lang.Lang.tr('profitShare'), '${inv.profitPercentage}%'),
              _detailRow(lang.Lang.tr('startDate'), inv.startDate),
              _detailRow(
                  lang.Lang.tr('active'), inv.isActive ? lang.Lang.tr('yes') : lang.Lang.tr('no')),
              const Divider(),
              _detailRow(
                  lang.Lang.tr('totalBought'), '৳${inv.totalBought.toStringAsFixed(2)}'),
              _detailRow(
                  lang.Lang.tr('totalSold'), '৳${inv.totalSold.toStringAsFixed(2)}'),
              _detailRow(
                  lang.Lang.tr('totalProfit'), '৳${inv.totalProfit.toStringAsFixed(2)}'),
              _detailRow(lang.Lang.tr('stockValue'),
                  '৳${inv.productValueTotal.toStringAsFixed(2)}'),
              _detailRow(lang.Lang.tr('remainingBalance'),
                  '৳${inv.remainingBalance.toStringAsFixed(2)}'),
              _detailRow(
                  lang.Lang.tr('totalRepaid'), '৳${repaid.toStringAsFixed(2)}'),
              const Divider(),
              Text(lang.Lang.tr('repayments'),
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              if (inv.repayments.isEmpty)
                Text(lang.Lang.tr('noRepayments'),
                    style: TextStyle(color: Colors.grey))
              else
                ...inv.repayments.map((r) => ListTile(
                      dense: true,
                      title: Text('৳${r.amount.toStringAsFixed(2)}'),
                      subtitle: Text(
                          '${r.date}${r.notes.isNotEmpty ? ' - ${r.notes}' : ''}'),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ---- DATE PICKER ----
  Future<void> _showDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.day,
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${lang.Lang.tr('filteringBy')} ${DateFormat('dd-MM-yyyy').format(picked)}'),
        backgroundColor: kTeal,
      ));
    }
  }

  // ---- BUILD ----
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Iconsax.menu_1, color: Colors.white), onPressed: widget.onMenuTap),
        backgroundColor: kTeal,
        title: shopLogo(size: 20, color: Colors.white),
        actions: [
          if (_selectedDate != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  DateFormat('dd-MM-yyyy').format(_selectedDate!),
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Iconsax.calendar, color: Colors.white),
            onPressed: _showDatePicker,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: kTeal50,
                child: Row(
                  children: [
                    Icon(Iconsax.info_circle, color: kTeal, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        lang.Lang.tr('autoTracked'),
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 12, top: 12, bottom: 4),
                padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8, right: 8),
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: kTeal, width: 3)),
                ),
                child: Text(
                  'All Investors',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold, color: kTealDark),
                ),
              ),
              Expanded(
                child: _investors.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: kTeal50,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Iconsax.building,
                                  size: 32, color: kTeal),
                            ),
                            const SizedBox(height: 12),
                            Text(lang.Lang.tr('noInvestors'),
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ))
                    : ListView.builder(
                        itemCount: _investors.length,
                        itemBuilder: (_, i) => _buildCard(_investors[i]),
                      ),
              ),
            ],
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
                padding: EdgeInsets.fromLTRB(12, 12, 12, MediaQuery.of(context).viewInsets.bottom + 12),
                child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        lang.Lang.tr('addInvestor'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kTeal,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(labelText: lang.Lang.tr('investorName')),
                      ),
                      const SizedBox(height: 14),
                      _contractDropdown(),
                      const SizedBox(height: 14),
                      if (_contractType != 'consignment') ...[
                        _investTypeDropdown(),
                        const SizedBox(height: 14),
                      ],
                      if (_investType == 'cash' && _contractType != 'consignment')
                        TextField(
                          controller: _amountCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: lang.Lang.tr('cashAmount')),
                        ),
                      if (_investType == 'mixed') ...[
                        TextField(
                          controller: _cashCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: lang.Lang.tr('cashAmount')),
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (_investType == 'products' || _investType == 'mixed') ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _productCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(labelText: lang.Lang.tr('productValue')),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Iconsax.trend_up, color: kTeal),
                              tooltip: lang.Lang.tr('calcFromStock'),
                              onPressed: _calcFromStock,
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),
                      TextField(
                        controller: _durationCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: lang.Lang.tr('durationMonths')),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _profitCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: lang.Lang.tr('profitShare')),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveFromForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kTeal,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(lang.Lang.tr('saveInvestor')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kTeal,
        foregroundColor: Colors.white,
        onPressed: () {
          setState(() {
            if (!_showForm) _clearForm();
            _showForm = !_showForm;
          });
        },
        child: Icon(_showForm ? Iconsax.close_square : Iconsax.add),
      ),
    );
  }

  Widget _buildCard(Investor inv) {
    final repaid = inv.repayments.fold(0.0, (s, r) => s + r.amount);
    final contractColor = inv.contractType == 'loan'
        ? Colors.orange
        : inv.contractType == 'consignment'
            ? Colors.blue
            : Colors.green;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kCardRadius)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name + badges
            Row(
              children: [
                Expanded(
                  child: Text(inv.name,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kTealDark)),
                ),
                _badge(_contractLabel(inv.contractType),
                    contractColor.withValues(alpha: 0.15), contractColor),
                const SizedBox(width: 4),
                _badge(_investLabel(inv.investmentType),
                    kTeal50, kTeal),
              ],
            ),
            const SizedBox(height: 6),

            // Invested summary
            Text(
              '${lang.Lang.tr('investedLabel')}৳${inv.investedAmount.toStringAsFixed(2)}'
              '${inv.investmentType == 'mixed' ? ' (Cash: ৳${inv.cashInvested.toStringAsFixed(1)} + Products: ৳${inv.productInvested.toStringAsFixed(1)})' : ''}'
              ' | Share: ${inv.profitPercentage}%',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
            const Divider(height: 12),

            // Stats row: Bought / Sold / Profit
            Row(
              children: [
                _statBox(lang.Lang.tr('bought'),
                    '৳${inv.totalBought.toStringAsFixed(0)}', Colors.blue),
                const SizedBox(width: 4),
                _statBox(lang.Lang.tr('sold'),
                    '৳${inv.totalSold.toStringAsFixed(0)}', Colors.green),
                const SizedBox(width: 4),
                _statBox(lang.Lang.tr('profit'),
                    '৳${inv.totalProfit.toStringAsFixed(0)}', Colors.orange),
              ],
            ),
            const SizedBox(height: 4),
            // Profit split
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade100, width: 0.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${lang.Lang.tr('investorProfitSplit')}:',
                      style: TextStyle(fontSize: 11, color: Colors.brown.shade700, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Text(
                    '${lang.Lang.tr('investor')}: ৳${(inv.totalProfit * inv.profitPercentage / 100).toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '| ${lang.Lang.tr('shop')}: ৳${(inv.totalProfit * (100 - inv.profitPercentage) / 100).toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 11, color: Colors.teal.shade700, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Stock value + remaining balance
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${lang.Lang.tr('inStockLabel')}৳${inv.productValueTotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
                Expanded(
                  child: Text(
                    "${inv.contractType == 'consignment' ? lang.Lang.tr('remaining') : lang.Lang.tr('balance')}: " 
                    '৳${inv.remainingBalance.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: inv.remainingBalance > 0
                            ? Colors.red.shade700
                            : Colors.green.shade700),
                  ),
                ),
              ],
            ),
            if (repaid > 0)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '${lang.Lang.tr('repaidLabel')}৳${repaid.toStringAsFixed(2)} (${inv.repayments.length})',
                  style: const TextStyle(fontSize: 11, color: Colors.green),
                ),
              ),

            // Daily / Monthly earnings
            const Divider(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      children: [
                        Text(lang.Lang.tr('daily'),
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                        Text(
                            '৳${inv.dailyEarnings.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.green)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: kTeal50,
                        borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      children: [
                        Text(lang.Lang.tr('monthly'),
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                        Text(
                            '৳${inv.monthlyEarnings.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: kTeal)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (inv.contractType != 'consignment')
                  TextButton.icon(
                    onPressed: () => _showRepaymentDialog(inv),
                    icon: const Icon(Iconsax.wallet, size: 16),
                    label: Text(lang.Lang.tr('repay'),
                        style: TextStyle(fontSize: 12)),
                  ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: () => _showDetails(inv),
                  icon: const Icon(Iconsax.info_circle, size: 16),
                  label: Text(lang.Lang.tr('details'),
                      style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: () => _showAddDialog(edit: inv),
                  icon: const Icon(Iconsax.edit, size: 16),
                  label:
                      Text(lang.Lang.tr('edit'), style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(text,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _cashCtrl.dispose();
    _productCtrl.dispose();
    _durationCtrl.dispose();
    _profitCtrl.dispose();
    super.dispose();
  }
}
