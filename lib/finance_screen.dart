import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'models.dart';
import 'shop_logo.dart';
import 'lang.dart' as lang;
import 'constants.dart';

class FinanceScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  const FinanceScreen({super.key, this.onMenuTap});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen>
    with SingleTickerProviderStateMixin {
  final _financeBox = Hive.box('financeBox');

  final _expAmount = TextEditingController();
  final _expNote = TextEditingController();
  final _expVendor = TextEditingController();
  String _expPaymentMethod = 'Cash';
  String _expCategory = 'Other';
  bool _expIsPaid = false;
  String _expRecurring = 'none';
  final _purItemShop = TextEditingController();
  final _purItemName = TextEditingController();
  final _purItemQty = TextEditingController();
  final _purItemPrice = TextEditingController();
  final _purCashTaken = TextEditingController();
  final _purVehicle = TextEditingController();
  final _purCost = TextEditingController();
  final _purNotes = TextEditingController();
  final _purOtherDesc = TextEditingController();
  final _purOtherCost = TextEditingController();
  final _purReturnedCash = TextEditingController();
  File? _billFile;
  File? _purMemoFile;

  List<Expense> _expenses = [];
  List<Purchase> _purchases = [];
  final List<PurchaseItem> _tempItems = [];
  final List<TransportCost> _tempTransport = [];
  final List<OtherCost> _tempOtherCosts = [];
  String _purSource = 'cash';
  int _purFieldCounter = 0;
  List<Investor> _investors = [];
  List<String> _investorNames = [];
  List<String> _categories = [];
  List<String> _shopHistory = [];
  List<String> _itemHistory = [];
  DateTime? _selectedDate;
  DateTime _expEntryDate = DateTime.now();
  DateTime _purEntryDate = DateTime.now();


  late TabController _tabController;
  bool _showForm = false;

  final _transportVehicle = TextEditingController();
  final _transportCost = TextEditingController();
  List<TransportCost> _transportCosts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _loadInvestorNames();
    _loadCategories();
    _loadShopHistory();
    _loadItemHistory();
    _checkRecurringPayments();
    _loadTransportCosts();
    _showForm = true;
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _showForm = false);
    });
  }

  void _loadData() {
    final storedExpenses = _financeBox.get('expenses', defaultValue: []);
    final storedPurchases = _financeBox.get('purchases', defaultValue: []);

    setState(() {
      _expenses = List<Map<dynamic, dynamic>>.from(storedExpenses)
          .map(
            (e) => Expense(
              id:
                  e['id']?.toString() ??
                  DateTime.now().millisecondsSinceEpoch.toString(),
              type: e['type']?.toString() ?? 'misc',
              title: e['title']?.toString() ?? '',
              amount: (e['amount']?.toDouble() ?? 0.0),
              date: e['date']?.toString() ?? '',
              billImage: e['billPath'] != null && e['billPath'].toString().isNotEmpty ? File(e['billPath'].toString()) : null,
              dueDay: e['dueDay']?.toInt(),
              note: e['note']?.toString() ?? '',
              vendor: e['vendor']?.toString() ?? '',
              paymentMethod: e['paymentMethod']?.toString() ?? '',
              isPaid: e['isPaid'] == true,
              recurringType: e['recurringType']?.toString() ?? 'none',
            ),
          )
          .toList();

      _purchases = List<Map<dynamic, dynamic>>.from(storedPurchases)
          .map(
            (p) => Purchase.fromMap(Map<String, dynamic>.from(p)),
          )
          .toList();

    });
  }

  void _saveExpenses() {
    final data = _expenses
        .map(
          (e) => {
            'id': e.id,
            'type': e.type,
            'title': e.title,
            'amount': e.amount,
            'date': e.date,
            'billPath': e.billImage?.path ?? '',
            'dueDay': e.dueDay,
            'note': e.note,
            'vendor': e.vendor,
            'paymentMethod': e.paymentMethod,
            'isPaid': e.isPaid,
            'recurringType': e.recurringType,
          },
        )
        .toList();
    _financeBox.put('expenses', data);
  }

  void _savePurchases() {
    final data = _purchases.map((p) => p.toMap()).toList();
    _financeBox.put('purchases', data);
  }

  void _checkRecurringPayments() {
    final now = DateTime.now();
    final currentMonth = DateFormat('MM-yyy').format(now);
    final currentDay = now.day;

    final rentBills = _expenses.where((e) {
      final title = e.title.toLowerCase();
      return e.type == 'fixed' && (title.contains('rent') || title.contains('bill')) && e.dueDay != null;
    }).toList();

    if (rentBills.isEmpty) return;

    final Map<String, bool> paidThisMonth = {};
    for (final expense in _expenses) {
      final title = expense.title.toLowerCase();
      if (expense.type == 'fixed' && (title.contains('rent') || title.contains('bill'))) {
        final expDate = DateFormat('dd-MM-yyyy').parse(expense.date);
        if (DateFormat('MM-yyy').format(expDate) == currentMonth) {
          paidThisMonth[expense.title.toLowerCase()] = true;
        }
      }
    }

    final unpaid = <Expense>[];
    for (final item in rentBills) {
      if (!paidThisMonth.containsKey(item.title.toLowerCase())) {
        unpaid.add(item);
      }
    }

    if (unpaid.isEmpty) return;

    final highest = unpaid.reduce((a, b) => a.dueDay! > b.dueDay! ? a : b);
    final dueDay = highest.dueDay!;
    final daysDiff = dueDay - currentDay;

    String message;
    Color cardColor;
    if (daysDiff < 0) {
      message = 'Overdue! ${highest.title} was due on day $dueDay. Please pay immediately.';
      cardColor = Colors.red;
    } else if (daysDiff <= 3) {
      message = 'Urgent! ${highest.title} is due in $daysDiff day(s). Due day: $dueDay.';
      cardColor = Colors.deepOrange;
    } else if (currentDay <= 10) {
      message = 'Reminder: ${highest.title} is due on day $dueDay. Plan early.';
      cardColor = Colors.orange;
    } else if (currentDay <= 20) {
      message = 'Reminder: ${highest.title} due day $dueDay is approaching.';
      cardColor = Colors.orange;
    } else {
      message = 'Last reminder: ${highest.title} due day $dueDay is this month.';
      cardColor = Colors.red;
    }

    if (mounted) {
      Future.delayed(Duration.zero, () {
        SystemSound.play(SystemSoundType.alert);
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Iconsax.warning_2, color: cardColor),
                  const SizedBox(width: 8),
                  Text(lang.Lang.tr('paymentDue'), style: TextStyle(color: cardColor, fontWeight: FontWeight.w600)),
                ],
              ),
              content: Text(message),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: cardColor),
                  child: const Text('OK', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }
      });
    }
  }

  Future<void> _showDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    setState(() {
      _selectedDate = picked;
    });
  }

  Future<void> _pickBillImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 30,
      maxWidth: 600,
      maxHeight: 600,
    );
    if (file != null) setState(() => _billFile = File(file.path));
  }

  void _addExpense(String type) {
    if (_expCategory.isEmpty || _expAmount.text.isEmpty) return;

    final isRentOrBill = type == 'fixed' && (_expCategory == 'Rent' || _expCategory == 'Bill');

    if (isRentOrBill) {
      _showDueDayDialog(type);
    } else {
      _createExpense(type, null);
    }
  }

  void _showDueDayDialog(String type) {
    final dueDayController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.Lang.tr('setMonthlyDueDay'), style: TextStyle(color: kTeal, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: dueDayController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: lang.Lang.tr('enterDueDay'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(kButtonRadius)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(lang.Lang.tr('cancel'), style: TextStyle(color: Colors.grey.shade600))),
          ElevatedButton(
            onPressed: () {
              final day = int.tryParse(dueDayController.text);
              if (day != null && day >= 1 && day <= 31) {
                Navigator.pop(context);
                _createExpense(type, day);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kButtonRadius)),
            ),
            child: Text(lang.Lang.tr('save')),
          ),
        ],
      ),
    );
  }

  Future<void> _pickExpenseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expEntryDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _expEntryDate = picked);
    }
  }

  void _createExpense(String type, int? dueDay) {
    setState(() {
      _expenses.add(
        Expense(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: type,
          title: _expCategory,
          amount: double.parse(_expAmount.text),
          date: DateFormat('dd-MM-yyyy').format(_expEntryDate),
          billImage: _billFile,
          dueDay: dueDay,
          note: _expNote.text,
          vendor: _expVendor.text,
          paymentMethod: _expPaymentMethod,
          isPaid: _expIsPaid,
          recurringType: _expRecurring,
        ),
      );
      _expAmount.clear();
      _expNote.clear();
      _expVendor.clear();
      _billFile = null;
      _expEntryDate = DateTime.now();
      _expCategory = 'Other';
      _expPaymentMethod = 'Cash';
      _expIsPaid = false;
      _expRecurring = 'none';
      _saveExpenses();
    });
  }

  void _togglePaid(int index) {
    final exp = _expenses[index];
    final nowPaid = !exp.isPaid;
    setState(() {
      _expenses[index] = Expense(
        id: exp.id,
        type: exp.type,
        title: exp.title,
        amount: exp.amount,
        date: exp.date,
        billImage: exp.billImage,
        dueDay: exp.dueDay,
        note: exp.note,
        vendor: exp.vendor,
        paymentMethod: exp.paymentMethod,
        isPaid: nowPaid,
        recurringType: exp.recurringType,
      );
      _saveExpenses();
    });

    if (nowPaid && exp.recurringType != 'none') {
      _createNextRecurringExpense(index);
    }
  }

  void _createNextRecurringExpense(int index) {
    final exp = _expenses[index];
    final deadline = DateFormat('dd-MM-yyyy').parse(exp.date);
    DateTime nextDate;

    if (exp.recurringType == 'daily') {
      nextDate = deadline.add(const Duration(days: 1));
    } else {
      nextDate = DateTime(deadline.year, deadline.month + 1, deadline.day);
    }

    final nextDateStr = DateFormat('dd-MM-yyyy').format(nextDate);

    setState(() {
      _expenses.insert(
        index + 1,
        Expense(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: exp.type,
          title: exp.title,
          amount: exp.amount,
          date: nextDateStr,
          billImage: null,
          dueDay: exp.dueDay,
          note: exp.note,
          vendor: exp.vendor,
          paymentMethod: exp.paymentMethod,
          isPaid: false,
          recurringType: exp.recurringType,
        ),
      );
      _saveExpenses();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Next ${exp.recurringType} expense: $nextDateStr'),
        action: SnackBarAction(label: lang.Lang.tr('edit'), onPressed: () {
          _editExpense(index + 1, _expenses[index + 1]);
        }),
      ),
    );
  }

  Future<void> _pickPurchaseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purEntryDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _purEntryDate = picked);
    }
  }

  void _addTempItem() {
    if (_purItemShop.text.isEmpty || _purItemName.text.isEmpty) return;
    setState(() {
      _tempItems.add(PurchaseItem(
        shopName: _purItemShop.text,
        itemName: _purItemName.text,
        quantity: double.tryParse(_purItemQty.text) ?? 1,
        unitPrice: double.tryParse(_purItemPrice.text) ?? 0,
      ));
      _purItemShop.clear();
      _purItemName.clear();
      _purItemQty.clear();
      _purItemPrice.clear();
      _purFieldCounter++;
    });
  }

  void _removeTempItem(int index) {
    setState(() => _tempItems.removeAt(index));
  }

  void _addTempTransport() {
    if (_purVehicle.text.isEmpty) return;
    setState(() {
      _tempTransport.add(TransportCost(
        vehicle: _purVehicle.text,
        cost: double.tryParse(_purCost.text) ?? 0,
      ));
      _purVehicle.clear();
      _purCost.clear();
    });
  }

  void _removeTempTransport(int index) {
    setState(() => _tempTransport.removeAt(index));
  }

  void _addTempOtherCost() {
    if (_purOtherDesc.text.isEmpty) return;
    setState(() {
      _tempOtherCosts.add(OtherCost(
        description: _purOtherDesc.text,
        cost: double.tryParse(_purOtherCost.text) ?? 0,
      ));
      _purOtherDesc.clear();
      _purOtherCost.clear();
    });
  }

  void _removeTempOtherCost(int index) {
    setState(() => _tempOtherCosts.removeAt(index));
  }

  Future<void> _pickPurMemo() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() => _purMemoFile = File(picked.path));
    }
  }

  void _savePurchase() {
    if (_tempItems.isEmpty) return;
    final cashTaken = double.tryParse(_purCashTaken.text) ?? 0.0;
    final returnedCash = double.tryParse(_purReturnedCash.text) ?? 0.0;
    final netUsed = cashTaken - returnedCash;
    String? investorId;
    if (_purSource.startsWith('investor:')) {
      investorId = _purSource.substring(9);
    }
    setState(() {
      _purchases.add(Purchase(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateFormat('dd-MM-yyyy').format(_purEntryDate),
        source: _purSource,
        cashTaken: cashTaken,
        investorId: investorId,
        items: List.from(_tempItems),
        transportCosts: List.from(_tempTransport),
        otherCosts: List.from(_tempOtherCosts),
        returnedCash: returnedCash,
        memoPhotoPath: _purMemoFile?.path,
        notes: _purNotes.text,
      ));
      _tempItems.clear();
      _tempTransport.clear();
      _tempOtherCosts.clear();
      _purMemoFile = null;
      _purCashTaken.clear();
      _purReturnedCash.clear();
      _purNotes.clear();
      _purOtherDesc.clear();
      _purOtherCost.clear();
      _purEntryDate = DateTime.now();
      _savePurchases();
      _updateInvestorBalance(investorId, netUsed);
    });
  }

  void _loadInvestorNames() {
    final box = Hive.box('investorBox');
    final stored = box.get('investors', defaultValue: []);
    setState(() {
      _investors = List<Map<dynamic, dynamic>>.from(stored).map((inv) => Investor.fromMap(Map<String, dynamic>.from(inv))).toList();
      _investorNames = _investors.map((i) => i.name).where((s) => s.isNotEmpty).toList();
    });
  }

  void _loadCategories() {
    final box = Hive.box('inventoryBox');
    final stored = box.get('categories', defaultValue: ['Book', 'Date', 'Attar', 'Topi', 'Miswak']);
    setState(() {
      _categories = List<String>.from(stored).where((s) => s.isNotEmpty).toList();
    });
  }

  void _loadShopHistory() {
    final stored = _financeBox.get('shopHistory', defaultValue: []);
    setState(() {
      _shopHistory = List<String>.from(stored);
    });
  }

  void _saveShopName(String shop) {
    if (shop.isEmpty || _shopHistory.contains(shop)) return;
    setState(() {
      _shopHistory.insert(0, shop);
      if (_shopHistory.length > 50) _shopHistory.removeLast();
    });
    _financeBox.put('shopHistory', _shopHistory);
  }

  void _loadItemHistory() {
    final stored = _financeBox.get('itemHistory', defaultValue: []);
    setState(() {
      _itemHistory = List<String>.from(stored);
    });
  }

  void _saveItemName(String name) {
    if (name.isEmpty || _itemHistory.contains(name)) return;
    setState(() {
      _itemHistory.insert(0, name);
      if (_itemHistory.length > 50) _itemHistory.removeLast();
    });
    _financeBox.put('itemHistory', _itemHistory);
  }

  void _updateInvestorBalance(String? investorId, double amount) {
    if (investorId == null || amount <= 0) return;
    final box = Hive.box('investorBox');
    final stored = List<Map<dynamic, dynamic>>.from(box.get('investors', defaultValue: []));
    bool found = false;
    final updated = stored.map((inv) {
      if (inv['id']?.toString() == investorId) {
        found = true;
        final current = (inv['investedAmount']?.toDouble() ?? 0.0);
        return {...inv, 'investedAmount': current + amount};
      }
      return inv;
    }).toList();
    if (found) {
      box.put('investors', updated);
    }
  }

  void _editExpense(int index, Expense exp) {
    final titleController = TextEditingController(text: exp.vendor);
    final amountController = TextEditingController(text: exp.amount.toString());
    final noteController = TextEditingController(text: exp.note);
    String editType = exp.type;
    int? editDueDay = exp.dueDay;
    DateTime editDate = DateFormat('dd-MM-yyyy').parse(exp.date);
    String editCategory = exp.title;
    String editVendor = exp.vendor;
    String editNote = exp.note;
    String editPayment = exp.paymentMethod;
    bool editIsPaid = exp.isPaid;
    String editRecurring = exp.recurringType;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(lang.Lang.tr('editExpense'), style: TextStyle(color: kTeal, fontWeight: FontWeight.w600)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    key: ValueKey(editCategory),
                    initialValue: editCategory,
                    decoration: InputDecoration(
                      labelText: lang.Lang.tr('category'),
                      prefixIcon: Icon(Iconsax.category),
                    ),
                    items: [
                      DropdownMenuItem(value: 'Rent', child: Text(lang.Lang.tr('rentCat'))),
                      DropdownMenuItem(value: 'Bill', child: Text(lang.Lang.tr('billCat'))),
                      DropdownMenuItem(value: 'Utilities', child: Text(lang.Lang.tr('utilitiesCat'))),
                      DropdownMenuItem(value: 'Groceries', child: Text(lang.Lang.tr('groceriesCat'))),
                      DropdownMenuItem(value: 'Transport', child: Text(lang.Lang.tr('transportCat'))),
                      DropdownMenuItem(value: 'Office Supplies', child: Text(lang.Lang.tr('officeSuppliesCat'))),
                      DropdownMenuItem(value: 'Marketing', child: Text(lang.Lang.tr('marketingCat'))),
                      DropdownMenuItem(value: 'Staff Salary', child: Text(lang.Lang.tr('staffSalaryCat'))),
                      DropdownMenuItem(value: 'Maintenance', child: Text(lang.Lang.tr('maintenanceCat'))),
                      DropdownMenuItem(value: 'Other', child: Text(lang.Lang.tr('otherCat'))),
                    ],
                    onChanged: (v) {
                      if (v != null) setDialogState(() => editCategory = v);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(labelText: lang.Lang.tr('vendorPayee')),
                    onChanged: (v) => editVendor = v,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: lang.Lang.tr('amountTaka')),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    maxLines: 2,
                    decoration: InputDecoration(labelText: lang.Lang.tr('descriptionNote')),
                    controller: noteController,
                    onChanged: (v) => editNote = v,
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: editDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setDialogState(() => editDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: lang.Lang.tr('date'),
                        prefixIcon: Icon(Iconsax.calendar),
                      ),
                      child: Text(DateFormat('dd-MM-yyyy').format(editDate)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    key: ValueKey(editPayment),
                    initialValue: editPayment,
                    decoration: InputDecoration(
                      labelText: lang.Lang.tr('paymentMethod'),
                      prefixIcon: Icon(Iconsax.wallet),
                    ),
                    items: [
                      DropdownMenuItem(value: 'Cash', child: Text(lang.Lang.tr('cash'))),
                      DropdownMenuItem(value: 'Bank', child: Text(lang.Lang.tr('bank'))),
                      DropdownMenuItem(value: 'BKash', child: Text(lang.Lang.tr('bKash'))),
                      DropdownMenuItem(value: 'Card', child: Text(lang.Lang.tr('card'))),
                    ],
                    onChanged: (v) {
                      if (v != null) setDialogState(() => editPayment = v);
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: Text(lang.Lang.tr('fixed')),
                          selected: editType == 'fixed',
                          onSelected: (v) => setDialogState(() => editType = 'fixed'),
                          selectedColor: Colors.blue,
                          labelStyle: TextStyle(color: editType == 'fixed' ? Colors.white : Colors.black),
                                  ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                        child: ChoiceChip(
                          label: Text(lang.Lang.tr('other')),
                          selected: editType == 'misc',
                          onSelected: (v) => setDialogState(() => editType = 'misc'),
                          selectedColor: Colors.orange,
                          labelStyle: TextStyle(color: editType == 'misc' ? Colors.white : Colors.black),
                        ),
                      ),
                    ],
                  ),
                  if (editType == 'fixed')
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: lang.Lang.tr('dueDay')),
                        onChanged: (v) => editDueDay = int.tryParse(v),
                      ),
                    ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    key: ValueKey(editRecurring),
                    initialValue: editRecurring,
                    decoration: InputDecoration(
                      labelText: lang.Lang.tr('recurring'),
                      prefixIcon: Icon(Iconsax.repeat),
                    ),
                    items: [
                      DropdownMenuItem(value: 'none', child: Text(lang.Lang.tr('none'))),
                      DropdownMenuItem(value: 'daily', child: Text(lang.Lang.tr('daily'))),
                      DropdownMenuItem(value: 'monthly', child: Text(lang.Lang.tr('monthly'))),
                      DropdownMenuItem(value: 'custom', child: Text(lang.Lang.tr('custom'))),
                    ],
                    onChanged: (v) {
                      if (v != null) setDialogState(() => editRecurring = v);
                    },
                  ),
                  if (editRecurring == 'custom') ...[
                    const SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(labelText: lang.Lang.tr('customInterval')),
                      onChanged: (v) => editRecurring = v,
                    ),
                  ],
                  SwitchListTile(
                    title: Text(lang.Lang.tr('markAsPaid')),
                    value: editIsPaid,
                    onChanged: (v) => setDialogState(() => editIsPaid = v),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(lang.Lang.tr('cancel'), style: TextStyle(color: Colors.grey.shade600)),
              ),
              ElevatedButton(
                onPressed: () {
                  final newAmount = double.tryParse(amountController.text);
                  if (newAmount == null) return;

                  setState(() {
                    _expenses[index] = Expense(
                      id: exp.id,
                      type: editType,
                      title: editCategory,
                      amount: newAmount,
                      date: DateFormat('dd-MM-yyyy').format(editDate),
                      billImage: exp.billImage,
                      dueDay: editDueDay,
                      note: editNote,
                      vendor: editVendor,
                       paymentMethod: editPayment,
                       isPaid: editIsPaid,
                       recurringType: editRecurring,
                     );
                    _saveExpenses();
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kButtonRadius)),
                ),
                child: Text(lang.Lang.tr('save')),
              ),
            ],
          );
        },
      ),
    );
  }

   void _deleteExpense(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.Lang.tr('deleteExpense'), style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600)),
        content: Text('Are you sure you want to delete "${_expenses[index].title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.Lang.tr('cancel'), style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _expenses.removeAt(index);
                _saveExpenses();
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kButtonRadius)),
            ),
            child: Text(lang.Lang.tr('delete')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Iconsax.menu_1, color: Colors.white), onPressed: widget.onMenuTap),
          backgroundColor: kTeal,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              shopLogo(size: 18, color: Colors.white),
              if (_selectedDate != null)
                Text(
                  DateFormat('dd-MM-yyyy').format(_selectedDate!),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Iconsax.calendar, color: Colors.white),
              onPressed: _showDatePicker,
              tooltip: lang.Lang.tr('filterByDate'),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: kTeal,
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicator: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.white, width: 3),
                  ),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: [
                  Tab(icon: Icon(Iconsax.money_recive), text: lang.Lang.tr('expenses')),
                  Tab(icon: Icon(Iconsax.bag), text: lang.Lang.tr('purchases')),
                  Tab(icon: Icon(Iconsax.truck), text: lang.Lang.tr('transport')),
                ],
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            TabBarView(
              controller: _tabController,
              children: [
                _buildExpenseTab(),
                _buildPurchaseTab(),
                _buildTransportTab(),
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
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                  ),
                  child: _showForm ? _buildCurrentTabForm() : const SizedBox.shrink(),
                ),
              ),
            ),
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

  Widget get expenseFormContent => Padding(
    padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
    child: Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kTeal50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.add_circle_outline, color: Colors.teal.shade700, size: 20),
                ),
                const SizedBox(width: 10),
                Text(lang.Lang.tr('newExpense'),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                const Spacer(),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _pickBillImage,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _billFile == null ? kTeal50 : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _billFile == null ? Iconsax.camera : Iconsax.gallery,
                      size: 20,
                      color: _billFile == null ? Colors.teal.shade600 : Colors.green.shade600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => setState(() => _expIsPaid = !_expIsPaid),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _expIsPaid ? Colors.green.shade50 : Colors.orange.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _expIsPaid ? Iconsax.tick_circle : Icons.radio_button_unchecked,
                      size: 22,
                      color: _expIsPaid ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _expVendor,
              decoration: InputDecoration(
                labelText: lang.Lang.tr('vendor'),
                prefixIcon: Icon(Icons.person_outline, color: Colors.teal.shade600, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _expAmount,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: lang.Lang.tr('amount'),
                      prefixIcon: Icon(Iconsax.money, color: Colors.teal.shade600, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                    child: DropdownButtonFormField<String>(
                      key: ValueKey(_expCategory),
                      initialValue: _expCategory,
                      decoration: InputDecoration(
                        labelText: lang.Lang.tr('category'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        isDense: true,
                    ),
                    items: [
                      DropdownMenuItem(value: 'Rent', child: Text(lang.Lang.tr('rentCat'), style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 'Bill', child: Text(lang.Lang.tr('billCat'), style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 'Utilities', child: Text(lang.Lang.tr('utilitiesCat'), style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 'Groceries', child: Text(lang.Lang.tr('groceriesCat'), style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 'Transport', child: Text(lang.Lang.tr('transportCat'), style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 'Office Supplies', child: Text(lang.Lang.tr('officeSuppliesCat'), style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 'Marketing', child: Text(lang.Lang.tr('marketingCat'), style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 'Staff Salary', child: Text(lang.Lang.tr('staffSalaryCat'), style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 'Maintenance', child: Text(lang.Lang.tr('maintenanceCat'), style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 'Other', child: Text(lang.Lang.tr('otherCat'), style: TextStyle(fontSize: 13))),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _expCategory = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickExpenseDate(),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: lang.Lang.tr('deadline'),
                        prefixIcon: Icon(Icons.event, color: Colors.teal.shade600, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      child: Text(DateFormat('dd-MM-yyyy').format(_expEntryDate),
                        style: const TextStyle(fontSize: 14)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(_expRecurring),
                    initialValue: _expRecurring,
                    decoration: InputDecoration(
                      labelText: lang.Lang.tr('recurring'),
                      prefixIcon: Icon(Iconsax.repeat, color: Colors.teal.shade600, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    items: [
                      DropdownMenuItem(value: 'none', child: Text(lang.Lang.tr('none'), style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 'daily', child: Text(lang.Lang.tr('daily'), style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 'monthly', child: Text(lang.Lang.tr('monthly'), style: TextStyle(fontSize: 13))),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _expRecurring = v);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _addExpense('fixed'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(lang.Lang.tr('fixedExpense'),
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildExpenseTab() {
    return Column(
      children: [
        _buildStatusNotificationCards(),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          child: Container(
            padding: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: kTeal, width: 3)),
            ),
            child: Row(
              children: [
                Icon(Iconsax.money_recive, size: 16, color: kTeal),
                const SizedBox(width: 6),
                Text('Recent Expenses (${_expenses.length})',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTeal),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _buildExpensesListView(),
        ),
      ],
    );
  }

  Widget _buildStatusNotificationCards() {
    final now = DateTime.now();
    final overdue = _expenses.where((e) {
      if (e.isPaid) return false;
      try {
        return DateFormat('dd-MM-yyyy').parse(e.date).isBefore(now);
      } catch (_) {
        return false;
      }
    }).toList();

    if (overdue.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: overdue.map((e) {
          final index = _expenses.indexOf(e);
          final dueDate = DateFormat('dd-MM-yyyy').parse(e.date);
          final daysOverdue = now.difference(dueDate).inDays;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade50, Colors.red.shade100],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade300),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Iconsax.warning_2, color: Colors.red.shade700, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Text(lang.Lang.tr('overduePayment'),
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.red.shade800),
                      ),
                      const Spacer(),
                      Text('\u09F3 ${e.amount.toStringAsFixed(2)}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red.shade800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(e.vendor.isNotEmpty ? e.vendor : e.title,
                    style: TextStyle(fontSize: 13, color: Colors.red.shade600),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text('${lang.Lang.tr('due')}: ${e.date}',
                        style: TextStyle(fontSize: 11, color: Colors.red.shade500),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.red.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('$daysOverdue days overdue',
                          style: TextStyle(fontSize: 10, color: Colors.red.shade800, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _togglePaid(index),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text(lang.Lang.tr('payNow'),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExpensesListView() {
    final displayList = _selectedDate != null
        ? _expenses.where((e) => e.date == DateFormat('dd-MM-yyyy').format(_selectedDate!)).toList()
        : _expenses;

    if (displayList.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kTeal.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Iconsax.money_recive, size: 48, color: kTeal.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 16),
            Text('No expenses yet',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
            const SizedBox(height: 4),
            Text('Tap + to add one',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
          ],
        ),
      );
    }

    if (_selectedDate != null) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: displayList.length,
        itemBuilder: (context, index) {
          final exp = displayList[index];
          return _buildExpenseListTile(exp, _expenses.indexOf(exp));
        },
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _expenses.length,
      onReorderItem: (oldIndex, newIndex) {
        setState(() {
          final item = _expenses.removeAt(oldIndex);
          _expenses.insert(newIndex, item);
          _saveExpenses();
        });
      },
      itemBuilder: (context, index) {
        final exp = _expenses[index];
        return _buildExpenseListTile(exp, index);
      },
    );
  }

  Widget _buildExpenseListTile(Expense exp, int originalIndex) {
    final isRecurring = exp.recurringType != 'none';
    final now = DateTime.now();
    bool isOverdue = false;
    try {
      isOverdue = !exp.isPaid && DateFormat('dd-MM-yyyy').parse(exp.date).isBefore(now);
    } catch (_) {}

    Color statusColor;
    IconData statusIcon;
    String statusLabel;
    if (exp.isPaid) {
      statusColor = Colors.green;
      statusIcon = Iconsax.tick_circle;
      statusLabel = 'Paid';
    } else if (isOverdue) {
      statusColor = Colors.red;
      statusIcon = Icons.error_outline;
      statusLabel = 'Overdue';
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.schedule;
      statusLabel = 'Pending';
    }

    return Card(
      key: ValueKey(exp.id),
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shadowColor: kTeal.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kCardRadius),
        side: BorderSide(color: statusColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exp.vendor.isNotEmpty ? exp.vendor : exp.title,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '\u09F3 ${exp.amount.toStringAsFixed(2)}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: statusColor),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            exp.date,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                          if (isRecurring) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: kTeal50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(exp.recurringType,
                                style: TextStyle(fontSize: 9, color: Colors.teal.shade700)),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (exp.billImage != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(Iconsax.gallery, size: 18, color: Colors.teal.shade400),
                  ),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _togglePaid(originalIndex),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: () => _editExpense(originalIndex, exp),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: kTeal50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_outlined, size: 12, color: Colors.teal.shade600),
                        const SizedBox(width: 3),
                        Text(lang.Lang.tr('edit'), style: TextStyle(fontSize: 10, color: Colors.teal.shade600)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => _deleteExpense(originalIndex),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Iconsax.trash, size: 12, color: Colors.red.shade400),
                        const SizedBox(width: 3),
                        Text(lang.Lang.tr('delete'), style: TextStyle(fontSize: 10, color: Colors.red.shade400)),
                      ],
                    ),
                  ),
                ),
                ],
              ),
            ],
          ),
        ),
        );
  }

  Widget get purchaseFormContent {
    final sourceItems = <DropdownMenuItem<String>>[
      DropdownMenuItem(value: 'cash', child: Text(lang.Lang.tr('ownShop'), style: TextStyle(fontSize: 13))),
    ];
    for (final name in _investorNames) {
      final inv = _investors.where((i) => i.name == name).firstOrNull;
      sourceItems.add(DropdownMenuItem(
        value: 'investor:${inv?.id ?? name}',
        child: Text(name, style: TextStyle(fontSize: 13, color: Colors.red.shade700)),
      ));
    }

    final isInvestorSource = _purSource.startsWith('investor:');
    final amountColor = isInvestorSource ? Colors.red : Colors.green;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kCardRadius)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blue.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(lang.Lang.tr('newPurchase'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                  Flexible(
                    child: InkWell(
                      onTap: () => _pickPurchaseDate(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Iconsax.calendar, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(DateFormat('dd-MM-yyyy').format(_purEntryDate),
                              style: const TextStyle(fontSize: 11, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                      key: ValueKey('source_${_purSource}_${_investorNames.length}'),
                      initialValue: _purSource,
                      decoration: InputDecoration(
                        labelText: lang.Lang.tr('cashFrom'),
                        prefixIcon: Icon(Icons.account_balance_wallet, color: amountColor, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      items: sourceItems,
                      onChanged: (v) {
                        if (v != null) setState(() => _purSource = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _purCashTaken,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                      labelText: lang.Lang.tr('amount'),
                        prefixIcon: Icon(Iconsax.money, color: amountColor, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1),
              ),
              Text(lang.Lang.tr('items'),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Autocomplete<String>(
                      key: ValueKey('item_ac_$_purFieldCounter'),
                      optionsBuilder: (textEditingValue) {
                        if (textEditingValue.text.isEmpty) return [];
                        final allItems = <String>{..._categories, ..._itemHistory}.toList();
                        return allItems.where((item) =>
                          item.toLowerCase().contains(textEditingValue.text.toLowerCase())).take(10);
                      },
                      onSelected: (v) => _purItemName.text = v,
                      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                        controller.addListener(() => _purItemName.text = controller.text);
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: lang.Lang.tr('item'),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            isDense: true,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Autocomplete<String>(
                      key: ValueKey('shop_ac_$_purFieldCounter'),
                      optionsBuilder: (textEditingValue) {
                        if (textEditingValue.text.isEmpty) return [];
                        final q = textEditingValue.text.toLowerCase();
                        return _shopHistory.where((s) => s.toLowerCase().contains(q)).take(10);
                      },
                      onSelected: (v) => _purItemShop.text = v,
                      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                        controller.addListener(() => _purItemShop.text = controller.text);
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            hintText: lang.Lang.tr('shopHint'),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            isDense: true,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 50,
                    child: TextField(
                      controller: _purItemQty,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: lang.Lang.tr('qty'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 60,
                    child: TextField(
                      controller: _purItemPrice,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: lang.Lang.tr('price'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () {
                      _saveShopName(_purItemShop.text);
                      _saveItemName(_purItemName.text);
                      _addTempItem();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Iconsax.add, size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
              if (_tempItems.isNotEmpty) ...[
                const SizedBox(height: 6),
                ..._tempItems.asMap().entries.map((e) {
                  final i = e.value;
                  final idx = e.key;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('${i.shopName} / ${i.itemName}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text('${i.quantity.toInt()} x ${i.unitPrice.toStringAsFixed(0)} = \u09F3${i.total.toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => _removeTempItem(idx),
                          child: Icon(Iconsax.close_circle, size: 16, color: Colors.red.shade400),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              const SizedBox(height: 4),
              Row(
                children: [
                  const Spacer(),
                  Text('${lang.Lang.tr('itemsTotal')}:  ',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  Text('\u09F3 ${_tempItems.fold(0.0, (s, i) => s + i.total).toStringAsFixed(2)}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue.shade700),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1),
              ),
              Text(lang.Lang.tr('otherCosts'),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _purOtherDesc,
                      decoration: InputDecoration(
                        labelText: lang.Lang.tr('description'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: _purOtherCost,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: lang.Lang.tr('cost'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: _addTempOtherCost,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.brown.shade600,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Iconsax.add, size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
              if (_tempOtherCosts.isNotEmpty) ...[
                const SizedBox(height: 6),
                ..._tempOtherCosts.asMap().entries.map((e) {
                  final o = e.value;
                  final idx = e.key;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.brown.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(o.description,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        Text('\u09F3 ${o.cost.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 12, color: Colors.brown.shade700, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => _removeTempOtherCost(idx),
                          child: Icon(Iconsax.close_circle, size: 16, color: Colors.red.shade400),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              const SizedBox(height: 4),
              Row(
                children: [
                  const Spacer(),
                  Text('${lang.Lang.tr('otherCostsTotal')}:  ',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  Text('\u09F3 ${_tempOtherCosts.fold(0.0, (s, o) => s + o.cost).toStringAsFixed(2)}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.brown.shade700),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1),
              ),
              Text(lang.Lang.tr('transportCosts'),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _purVehicle,
                      decoration: InputDecoration(
                        labelText: lang.Lang.tr('vehicle'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: _purCost,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: lang.Lang.tr('cost'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: _addTempTransport,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Iconsax.add, size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
              if (_tempTransport.isNotEmpty) ...[
                const SizedBox(height: 6),
                ..._tempTransport.asMap().entries.map((e) {
                  final t = e.value;
                  final idx = e.key;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(t.vehicle,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        Text('\u09F3 ${t.cost.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => _removeTempTransport(idx),
                          child: Icon(Iconsax.close_circle, size: 16, color: Colors.red.shade400),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              const SizedBox(height: 4),
              Row(
                children: [
                  const Spacer(),
                  Text('${lang.Lang.tr('transportTotal')}:  ',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  Text('\u09F3 ${_tempTransport.fold(0.0, (s, t) => s + t.cost).toStringAsFixed(2)}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue.shade700),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.deepPurple.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Iconsax.refresh, size: 16, color: Colors.deepPurple.shade600),
                    const SizedBox(width: 6),
                    Text(lang.Lang.tr('returnedCash'),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.deepPurple.shade700),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 120,
                      child: TextField(
                        controller: _purReturnedCash,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: lang.Lang.tr('amount'),
                          hintStyle: TextStyle(color: Colors.deepPurple.shade300),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.deepPurple.shade300),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Spacer(),
                  Text('${lang.Lang.tr('grandTotal')}:  ',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                  Text('\u09F3 ${(_tempItems.fold(0.0, (s, i) => s + i.total) + _tempTransport.fold(0.0, (s, t) => s + t.cost) + _tempOtherCosts.fold(0.0, (s, o) => s + o.cost)).toStringAsFixed(2)}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue.shade700),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickPurMemo,
                      icon: Icon(
                        _purMemoFile == null ? Iconsax.camera : Iconsax.gallery,
                        size: 18,
                        color: _purMemoFile == null ? Colors.blue : Colors.green,
                      ),
                      label: Text(
                        _purMemoFile == null ? lang.Lang.tr('addPhoto') : lang.Lang.tr('photoTaken'),
                        style: TextStyle(fontSize: 12, color: _purMemoFile == null ? Colors.blue : Colors.green),
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _savePurchase,
                      icon: const Icon(Icons.save, size: 18),
                      label: Text(lang.Lang.tr('savePurchase'), style: TextStyle(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
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
    );
  }

  Widget _buildPurchaseTab() {
    return Column(
      children: [
        Expanded(
          child: _purchases.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: kTeal.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Iconsax.bag, size: 48, color: kTeal.withValues(alpha: 0.5)),
                      ),
                      const SizedBox(height: 16),
                      Text('No purchases yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                      const SizedBox(height: 4),
                      Text('Tap + to add one',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
                    ],
                  ),
                )
              : SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Container(
                    padding: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      border: Border(left: BorderSide(color: Colors.blue.shade400, width: 3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.history, size: 16, color: Colors.blue.shade400),
                        const SizedBox(width: 6),
                        Text('${lang.Lang.tr('savedPurchases')} (${_purchases.length})',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blue.shade700),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                ..._purchases.reversed.toList().asMap().entries.map((entry) {
                  final p = entry.value;
                  final idx = _purchases.length - 1 - entry.key;
                  return InkWell(
                    onTap: () => _showEditPurchaseBottomSheet(p, idx),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border(
                          left: BorderSide(
                            color: p.isBalanced ? Colors.green.shade400 : Colors.orange.shade400,
                            width: 4,
                          ),
                        ),
                      ),
                      child: Card(
                    margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: p.source == 'investor' || p.source.startsWith('investor:') ? Colors.orange.shade50 : Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  p.source == 'cash' ? lang.Lang.tr('cash') : lang.Lang.tr('investor'),
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                                    color: p.source == 'cash' ? Colors.blue.shade700 : Colors.orange.shade700),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Iconsax.calendar, size: 12, color: Colors.grey.shade500),
                              const SizedBox(width: 3),
                              Text(p.date,
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                              ),
                              const Spacer(),
                              Text('\u09F3 ${p.grandTotal.toStringAsFixed(2)}',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue.shade700),
                              ),
                            ],
                          ),
                          if (p.cashTaken > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text('Cash taken: \u09F3${p.cashTaken.toStringAsFixed(2)}',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                                  color: p.source.startsWith('investor:') ? Colors.red.shade600 : Colors.green.shade600),
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text('${p.items.length} item(s)${p.transportTotal > 0 ? '  |  Transport: \u09F3${p.transportTotal.toStringAsFixed(0)}' : ''}${p.otherTotal > 0 ? '  |  Other: \u09F3${p.otherTotal.toStringAsFixed(0)}' : ''}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                          if (p.returnedCash > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                children: [
                                  Icon(Iconsax.refresh, size: 12, color: Colors.deepPurple.shade400),
                                  const SizedBox(width: 4),
                                  Text('Returned: \u09F3${p.returnedCash.toStringAsFixed(2)}  |  Net: \u09F3${p.netUsed.toStringAsFixed(2)}',
                                    style: TextStyle(fontSize: 10, color: Colors.deepPurple.shade600),
                                  ),
                                ],
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: p.isBalanced ? Colors.green.shade50 : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: p.isBalanced ? Colors.green.shade300 : Colors.red.shade300),
                                  ),
                                  child: Text(
                                    p.isBalanced ? 'OK' : 'Fix: \u09F3${p.balanceDiff.toStringAsFixed(2)}',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                                      color: p.isBalanced ? Colors.green.shade700 : Colors.red.shade700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (p.memoPhotoPath != null && p.memoPhotoPath!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Icon(Iconsax.gallery, size: 14, color: Colors.green.shade600),
                                  const SizedBox(width: 4),
                                  Text('Cash memo attached',
                                    style: TextStyle(fontSize: 10, color: Colors.green.shade600)),
                                ],
                              ),
                            ),
                        ],
                    ),
                    ),
                    ),
                  ),
                );
              }),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _loadTransportCosts() {
    final stored = _financeBox.get('transportCosts', defaultValue: []);
    setState(() {
      _transportCosts = List<Map<dynamic, dynamic>>.from(stored)
          .map((e) => TransportCost.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    });
  }

  void _saveTransportCosts() {
    _financeBox.put('transportCosts', _transportCosts.map((e) => e.toMap()).toList());
  }

  void _addTransportCost() {
    if (_transportVehicle.text.isEmpty) return;
    setState(() {
      _transportCosts.add(TransportCost(
        vehicle: _transportVehicle.text,
        cost: double.tryParse(_transportCost.text) ?? 0,
      ));
      _transportVehicle.clear();
      _transportCost.clear();
      _saveTransportCosts();
    });
  }

  void _removeTransportCost(int index) {
    setState(() {
      _transportCosts.removeAt(index);
      _saveTransportCosts();
    });
  }

  Widget _buildCurrentTabForm() {
    switch (_tabController.index) {
      case 0: return expenseFormContent;
      case 1: return purchaseFormContent;
      case 2: return transportFormContent;
      default: return const SizedBox.shrink();
    }
  }

  Widget get transportFormContent => Padding(
    padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
    child: Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kTeal50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Iconsax.truck, color: Colors.teal.shade700, size: 20),
                ),
                const SizedBox(width: 10),
                const Text('New Transport Cost',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _transportVehicle,
              decoration: InputDecoration(
                labelText: lang.Lang.tr('vehicle'),
                prefixIcon: Icon(Icons.directions_car, color: Colors.teal.shade600, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _transportCost,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: lang.Lang.tr('cost'),
                prefixIcon: Icon(Iconsax.money, color: Colors.teal.shade600, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addTransportCost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Add Transport Cost',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildTransportTab() {
    return _buildTransportListView();
  }

  Widget _buildTransportListView() {
    if (_transportCosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kTeal.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Iconsax.truck, size: 48, color: kTeal.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 16),
            Text('No transport costs yet',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
            const SizedBox(height: 4),
            Text('Tap + to add one',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _transportCosts.length,
      itemBuilder: (context, index) {
        final tc = _transportCosts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kTeal50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Iconsax.truck, color: Colors.teal.shade700, size: 20),
            ),
            title: Text(tc.vehicle,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('\u09F3 ${tc.cost.toStringAsFixed(2)}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal.shade700),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _removeTransportCost(index),
                  child: Icon(Iconsax.trash, size: 20, color: Colors.red.shade400),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditPurchaseBottomSheet(Purchase p, int index) {
    final cashTakenCtrl = TextEditingController(text: p.cashTaken.toStringAsFixed(2));
    final returnedCtrl = TextEditingController(text: p.returnedCash.toStringAsFixed(2));
    final notesCtrl = TextEditingController(text: p.notes);
    double editCashTaken = p.cashTaken;
    double editReturned = p.returnedCash;
    String editNotes = p.notes;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          void save() {
            editCashTaken = double.tryParse(cashTakenCtrl.text) ?? p.cashTaken;
            editReturned = double.tryParse(returnedCtrl.text) ?? p.returnedCash;
            editNotes = notesCtrl.text;
            final updated = Purchase(
              id: p.id,
              date: p.date,
              source: p.source,
              cashTaken: editCashTaken,
              investorId: p.investorId,
              items: p.items,
              transportCosts: p.transportCosts,
              otherCosts: p.otherCosts,
              returnedCash: editReturned,
              memoPhotoPath: p.memoPhotoPath,
              notes: editNotes,
            );
            setState(() => _purchases[index] = updated);
            _savePurchases();
            Navigator.pop(ctx);
          }

          void deletePurchase() {
            setState(() => _purchases.removeAt(index));
            _savePurchases();
            Navigator.pop(ctx);
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Iconsax.edit, size: 18, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(lang.Lang.tr('editPurchase'),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.blue.shade700),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(p.date, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          const SizedBox(height: 14),
                          Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: cashTakenCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: lang.Lang.tr('cashTaken'),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: returnedCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: lang.Lang.tr('returnedCash'),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${p.items.length} item(s) | Transport: \u09F3${p.transportTotal.toStringAsFixed(2)} | Other: \u09F3${p.otherTotal.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: lang.Lang.tr('notes'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: deletePurchase,
                        icon: const Icon(Iconsax.trash, size: 16),
                        label: Text(lang.Lang.tr('delete'), style: TextStyle(fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: save,
                        icon: const Icon(Icons.save, size: 16),
                        label: Text(lang.Lang.tr('save'), style: TextStyle(fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            ),
          );
        },
      ),
    );
  }
}

