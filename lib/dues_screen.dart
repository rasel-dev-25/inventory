import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:io';
import 'package:intl/intl.dart';
import 'models.dart';
import 'shop_logo.dart';
import 'lang.dart' as lang;
import 'constants.dart';

class DuesScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  final String? prefilledName;
  final double? prefilledAmount;
  final String? itemName;
  final File? itemImage;

  const DuesScreen({super.key, this.onMenuTap, this.prefilledName, this.prefilledAmount, this.itemName, this.itemImage});

  @override
  State<DuesScreen> createState() => _DuesScreenState();
}

class _DuesScreenState extends State<DuesScreen> {
  late final Box _duesBox;
  late final Box _inventoryBox;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _paymentController = TextEditingController();
  final _noteController = TextEditingController();
  bool _showForm = false;
  File? _customerImage;
  DateTime? _selectedDate;

  double _todayDue = 0.0;
  double _monthlyDue = 0.0;
  double _totalDue = 0.0;
  List<Customer> _customers = [];

  List<Map<dynamic, dynamic>> _filteredProducts = [];
  Map<dynamic, dynamic>? _selectedProduct;
  final TextEditingController _productSearchController = TextEditingController();

  static Map<String, String> get _cardHints => {
    'Outstanding': lang.Lang.tr('outstandingInfo'),
    'Ledger': lang.Lang.tr('ledgerInfo'),
  };

  void _showCardHint(String label) {
    final msg = _cardHints[label];
    if (msg == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 12)),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: kTeal,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _duesBox = Hive.box('duesBox');
    _inventoryBox = Hive.box('inventoryBox');
    _loadData();
    _showForm = true;
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _showForm = false);
    });
    if (widget.prefilledName != null) {
      _nameController.text = widget.prefilledName!;
    }
    if (widget.prefilledAmount != null) {
      _amountController.text = widget.prefilledAmount!.toString();
    }
  }

  void _loadData() {
    final stored = _duesBox.get('customers', defaultValue: []);
    setState(() {
      _customers = List<Map<dynamic, dynamic>>.from(stored)
          .map((c) => Customer.fromMap(Map<String, dynamic>.from(c)))
          .toList();
      _calculateTotals(filterDate: _selectedDate != null ? DateFormat('dd-MM-yyyy').format(_selectedDate!) : null);
    });
  }

  void _saveData() {
    _duesBox.put('customers', _customers.map((c) => c.toMap()).toList());
  }

  void _calculateTotals({String? filterDate}) {
    _todayDue = 0.0;
    _monthlyDue = 0.0;
    _totalDue = 0.0;
    String today = DateFormat('dd-MM-yyyy').format(DateTime.now());
    String currentMonth = DateFormat('MM-yyyy').format(DateTime.now());

    for (var customer in _customers) {
      for (var entry in customer.ledger) {
        String entryDate = entry['date']?.toString() ?? '';
        if (filterDate != null && entryDate != filterDate) continue;
        double amt = (entry['amount']?.toDouble() ?? 0.0);
        double sign = (entry['type'] == 'payment') ? -1.0 : 1.0;
        if (entryDate == today) {
          _todayDue += amt * sign;
        }
        if (entryDate.contains(currentMonth)) {
          _monthlyDue += amt * sign;
        }
        _totalDue += amt * sign;
      }
    }
  }

  double _getMonthlyPayback(Customer customer) {
    final now = DateTime.now();
    final currentMonth = DateFormat('MM-yyyy').format(now);
    double monthlyPayback = 0.0;
    for (final entry in customer.ledger) {
      final entryDate = entry['date']?.toString() ?? '';
      if (entryDate.length >= 7) {
        final entryMonth = entryDate.substring(3); // dd-MM-yyyy -> MM-yyyy
        if (entryMonth == currentMonth && entry['type'] == 'payment') {
          monthlyPayback += (entry['amount']?.toDouble() ?? 0.0);
        }
      }
    }
    return monthlyPayback;
  }

  Future<void> _pickCustomerImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 30,
      maxWidth: 600,
      maxHeight: 600,
    );
    if (pickedFile != null) {
      setState(() => _customerImage = File(pickedFile.path));
    }
  }

  void _addDueCustomer() {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) return;
    double amt = double.tryParse(_amountController.text) ?? 0.0;
    String today = DateFormat('dd-MM-yyyy').format(DateTime.now());

    setState(() {
      _customers.add(Customer(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        phone: _phoneController.text,
        image: _customerImage,
        note: _noteController.text,
        type: 'due_taker',
        ledger: [{
          'date': today, 
          'amount': amt, 
          'type': 'due',
          'itemName': _selectedProduct?['name']?.toString() ?? '',
          'imagePath': _selectedProduct?['imagePath']?.toString() ?? '',
          'note': _noteController.text,
        }],
      ));
      _calculateTotals(filterDate: _selectedDate != null ? DateFormat('dd-MM-yyyy').format(_selectedDate!) : null);
      _saveData();

      _nameController.clear();
      _phoneController.clear();
      _amountController.clear();
      _noteController.clear();
      _customerImage = null;
      _productSearchController.clear();
      _selectedProduct = null;
      _filteredProducts = [];
    });
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
      _amountController.text = (double.tryParse(product['sellPrice']?.toString() ?? '0') ?? 0.0).toString();
    });
  }

  void _editCustomer(int index) {
    final customer = _filteredCustomers[index];
    final nameCtrl = TextEditingController(text: customer.name);
    final phoneCtrl = TextEditingController(text: customer.phone);
    File? editImage = customer.image;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Iconsax.edit, color: kTeal, size: 22),
            const SizedBox(width: 10),
            Text(lang.Lang.tr('editCustomer')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 30, maxWidth: 600, maxHeight: 600);
                  if (picked != null) {
                    editImage = File(picked.path);
                    if (ctx.mounted) Navigator.pop(ctx);
                    _editCustomer(index);
                  }
                },
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: kTeal.withValues(alpha: 0.12),
                  backgroundImage: editImage != null ? FileImage(editImage!) : null,
                  child: editImage == null ? const Icon(Iconsax.camera, color: kTeal) : null,
                ),
              ),
              const SizedBox(height: 12),
              TextField(controller: nameCtrl, decoration: InputDecoration(labelText: lang.Lang.tr('customerName'), border: const OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: lang.Lang.tr('mobile'), border: const OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(lang.Lang.tr('cancel'), style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kTeal, foregroundColor: Colors.white),
            onPressed: () {
              if (nameCtrl.text.isEmpty) return;
              setState(() {
                final idx = _customers.indexOf(customer);
                if (idx >= 0) {
                  _customers[idx] = Customer(
                    id: customer.id,
                    name: nameCtrl.text,
                    phone: phoneCtrl.text,
                    type: customer.type,
                    image: editImage,
                    ledger: customer.ledger,
                    orders: customer.orders,
                    purchases: customer.purchases,
                  );
                  _saveData();
                  _calculateTotals();
                }
              });
              Navigator.pop(ctx);
            },
            child: Text(lang.Lang.tr('save')),
          ),
        ],
      ),
    );
  }

  void _showCustomerDetail(Customer customer) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            double totalDue = customer.ledger
                .where((e) => e['type'] == 'due')
                .fold(0.0, (sum, e) => sum + (e['amount']?.toDouble() ?? 0.0));
            double totalPaid = customer.ledger
                .where((e) => e['type'] == 'payment')
                .fold(0.0, (sum, e) => sum + (e['amount']?.toDouble() ?? 0.0));
            double balance = totalDue - totalPaid;

            return AlertDialog(
              titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: kTeal)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Iconsax.call, size: 13, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(customer.phone, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                    ],
                  ),
                  if (customer.note.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Iconsax.note, size: 13, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Flexible(child: Text(customer.note, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic))),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: balance <= 0 ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: balance <= 0 ? Colors.green.shade200 : Colors.red.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(balance <= 0 ? Iconsax.tick_circle : Iconsax.warning_2, size: 16, color: balance <= 0 ? Colors.green : Colors.red),
                        const SizedBox(width: 6),
                        Text(
                          balance <= 0 ? lang.Lang.tr('allSettled') : '${lang.Lang.tr('outstanding')}৳${balance.toStringAsFixed(2)}',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: balance <= 0 ? Colors.green.shade700 : Colors.red.shade700),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _showCardHint('Outstanding'),
                          child: Icon(Iconsax.info_circle, size: 12, color: (balance <= 0 ? Colors.green : Colors.red).withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        border: Border(left: BorderSide(color: kTeal, width: 3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Iconsax.receipt, size: 16, color: kTeal),
                          const SizedBox(width: 6),
                          Text(lang.Lang.tr('ledgerEntries'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey[800])),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => _showCardHint('Ledger'),
                            child: Icon(Iconsax.info_circle, size: 12, color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (customer.ledger.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Iconsax.info_circle, color: Colors.grey[400], size: 18),
                              const SizedBox(width: 8),
                              Text(lang.Lang.tr('noLedgerEntries'), style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                            ],
                          ),
                        ),
                      )
                    else
                      ...customer.ledger.map((entry) => Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: entry['type'] == 'due' ? Colors.red.shade50 : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: entry['type'] == 'due' ? Colors.red.shade100 : Colors.green.shade100, width: 0.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: entry['type'] == 'due' ? Colors.red.shade100 : Colors.green.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                entry['type'] == 'due' ? Icons.arrow_upward : Icons.arrow_downward,
                                color: entry['type'] == 'due' ? Colors.red : Colors.green,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(entry['date']?.toString() ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                                      if (entry['itemName'] != null && entry['itemName'].toString().isNotEmpty) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(entry['itemName'].toString(), style: TextStyle(fontSize: 10, color: Colors.grey[700])),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (entry['note'] != null && entry['note'].toString().isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(entry['note'].toString(), style: TextStyle(fontSize: 11, color: Colors.grey[500], fontStyle: FontStyle.italic)),
                                    ),
                                  if (entry['commitmentDate'] != null && entry['commitmentDate'].toString().isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Row(
                                        children: [
                                          Icon(Iconsax.calendar, size: 10, color: Colors.red.shade400),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${lang.Lang.tr('repayBy')}: ${entry['commitmentDate']}',
                                            style: TextStyle(fontSize: 10, color: Colors.red.shade400, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '৳${(entry['amount']?.toDouble() ?? 0.0).toStringAsFixed(2)}',
                              style: TextStyle(
                                color: entry['type'] == 'due' ? Colors.red.shade700 : Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )),
                    const SizedBox(height: 12),
                    // Monthly Payback row
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade100, width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Icon(Iconsax.calendar, size: 16, color: Colors.blue.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${lang.Lang.tr('monthlyPayback')}:',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blue.shade800),
                            ),
                          ),
                          Text(
                            '৳${_getMonthlyPayback(customer).toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12                    ),
                    TextField(
                      controller: _paymentController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: lang.Lang.tr('paymentAmount'),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Iconsax.money, size: 20),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(lang.Lang.tr('commitmentDate'),
                              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() {
                                customer.ledger.last['commitmentDate'] = DateFormat('dd-MM-yyyy').format(picked);
                                _saveData();
                              });
                            }
                          },
                          icon: const Icon(Iconsax.calendar, size: 16),
                          label: Text(lang.Lang.tr('setDate'), style: const TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(lang.Lang.tr('close')),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_paymentController.text.isEmpty) return;
                    double payment = double.tryParse(_paymentController.text) ?? 0.0;
                    String today = DateFormat('dd-MM-yyyy').format(DateTime.now());

                    setState(() {
                      customer.ledger.add({'date': today, 'amount': payment, 'type': 'payment'});
                      _calculateTotals(filterDate: _selectedDate != null ? DateFormat('dd-MM-yyyy').format(_selectedDate!) : null);
                      _saveData();
                    });
                    setDialogState(() {});
                    _paymentController.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Iconsax.tick_circle, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(lang.Lang.tr('paymentSaved')),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                    // Animate the payment effect
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (mounted) {
                        setState(() {
                          _calculateTotals(filterDate: _selectedDate != null ? DateFormat('dd-MM-yyyy').format(_selectedDate!) : null);
                        });
                      }
                    });
                  },
                  icon: const Icon(Iconsax.card, size: 18),
                  label: Text(lang.Lang.tr('receivePayment')),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<Customer> get _filteredCustomers {
    if (_selectedDate == null) return _customers;
    final dateStr = DateFormat('dd-MM-yyyy').format(_selectedDate!);
    return _customers.where((c) =>
      c.ledger.any((e) => e['date']?.toString() == dateStr)
    ).toList();
  }

  Future<void> _showDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _calculateTotals(filterDate: DateFormat('dd-MM-yyyy').format(picked));
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    _paymentController.dispose();
    _noteController.dispose();
    _productSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Iconsax.menu_1, color: Colors.white), onPressed: widget.onMenuTap),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            shopLogo(size: 18, color: Colors.white),
            if (_selectedDate != null)
              Text('Filtering: ${DateFormat('dd-MM-yyyy').format(_selectedDate!)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.calendar, color: Colors.white),
            onPressed: _showDatePicker,
          ),
          if (_selectedDate != null)
            IconButton(
              icon: const Icon(Iconsax.close_circle, color: Colors.white),
              onPressed: () => setState(() {
                _selectedDate = null;
                _calculateTotals(filterDate: _selectedDate != null ? DateFormat('dd-MM-yyyy').format(_selectedDate!) : null);
              }),
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                decoration: BoxDecoration(
                  color: kTealDark,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 6, offset: const Offset(0, 3)),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildDueSummary(lang.Lang.tr('todayDue'), _todayDue),
                    _buildDueSummary(lang.Lang.tr('monthlyDue'), _monthlyDue),
                    _buildDueSummary(_selectedDate != null ? lang.Lang.tr('filteredDue') : lang.Lang.tr('totalDue'), _totalDue),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: kTeal, width: 3)),
                ),
                child: Row(
                  children: [
                    Icon(Iconsax.people, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text('${lang.Lang.tr('customers')} (${_filteredCustomers.length})', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                  ],
                ),
              ),
              Expanded(
                child: _filteredCustomers.isEmpty
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
                              child: const Icon(Iconsax.people, size: 40, color: kTeal),
                            ),
                            const SizedBox(height: 16),
                            Text(lang.Lang.tr('noCustomers'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[600])),
                            const SizedBox(height: 6),
                            Text(_selectedDate != null ? lang.Lang.tr('noDuesOnDate') : lang.Lang.tr('addFirstCustomer'), style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12).copyWith(bottom: 16),
                        itemCount: _filteredCustomers.length,
                        itemBuilder: (context, index) {
                          final c = _filteredCustomers[index];
                          double currentDue = c.ledger.where((e) => e['type'] == 'due').fold(0.0, (sum, e) => sum + (e['amount']?.toDouble() ?? 0.0));
                          double payment = c.ledger.where((e) => e['type'] == 'payment').fold(0.0, (sum, e) => sum + (e['amount']?.toDouble() ?? 0.0));
                          double outstanding = currentDue - payment;

                          Color dueColor;
                          Color iconBgColor;
                          if (outstanding <= 0) {
                            dueColor = Colors.green;
                            iconBgColor = Colors.green;
                          } else if (outstanding < 500) {
                            dueColor = Colors.orange;
                            iconBgColor = Colors.orange;
                          } else if (outstanding < 1000) {
                            dueColor = Colors.deepOrange;
                            iconBgColor = Colors.deepOrange;
                          } else {
                            dueColor = Colors.red;
                            iconBgColor = Colors.red;
                          }

                          Color cardBgColor = outstanding <= 0 ? Colors.green.shade50 : outstanding < 500 ? Colors.orange.shade50 : outstanding < 1000 ? Colors.deepOrange.shade50 : Colors.red.shade50;

                          return Card(
                            elevation: 2,
                            shadowColor: dueColor.withValues(alpha: 0.15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _showCustomerDetail(c),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: cardBgColor,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: iconBgColor,
                                        borderRadius: BorderRadius.circular(10),
                                        image: c.image != null
                                            ? DecorationImage(image: FileImage(c.image!), fit: BoxFit.cover)
                                            : null,
                                      ),
                                      child: c.image == null
                                          ? const Icon(Iconsax.profile, color: Colors.white, size: 22)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Icon(Iconsax.call, size: 11, color: Colors.grey[500]),
                                              const SizedBox(width: 4),
                                              Text(c.phone, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: outstanding <= 0 ? Colors.green.shade100 : Colors.red.shade100,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              outstanding <= 0 ? lang.Lang.tr('settled') : lang.Lang.tr('due'),
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: outstanding <= 0 ? Colors.green.shade800 : Colors.red.shade800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('৳${outstanding.toStringAsFixed(2)}', style: TextStyle(color: dueColor, fontWeight: FontWeight.bold, fontSize: 16)),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Iconsax.edit, size: 16, color: kTeal),
                                              onPressed: () => _editCustomer(index),
                                              tooltip: lang.Lang.tr('edit'),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                            ),
                                            IconButton(
                                              icon: const Icon(Iconsax.eye, size: 16, color: kTeal),
                                              onPressed: () => _showCustomerDetail(c),
                                              tooltip: lang.Lang.tr('ledger'),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
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
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Card(
                    elevation: 2,
                    shadowColor: kTeal.withAlpha(40),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _pickCustomerImage,
                              child: CircleAvatar(
                                radius: 25,
                                backgroundColor: kTeal.withValues(alpha: 0.12),
                                backgroundImage: _customerImage != null ? FileImage(_customerImage!) : null,
                                child: _customerImage == null ? const Icon(Iconsax.camera, color: kTeal) : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                children: [
                                  TextField(controller: _nameController, decoration: InputDecoration(labelText: lang.Lang.tr('customerName'), border: const OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10))),
                                  const SizedBox(height: 6),
                                  TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: lang.Lang.tr('mobile'), border: const OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10))),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _productSearchController,
                          onChanged: _searchProducts,
                          decoration: InputDecoration(
                            hintText: lang.Lang.tr('searchProductAdd'),
                            prefixIcon: const Icon(Iconsax.search_normal),
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          ),
                        ),
                        if (_filteredProducts.isNotEmpty)
                          Container(
                            constraints: const BoxConstraints(maxHeight: 150),
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: _filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product = _filteredProducts[index];
                                final name = product['name']?.toString() ?? 'Unknown';
                                final sell = product['sellPrice']?.toString() ?? '0';
                                return ListTile(
                                  dense: true,
                                  leading: product['imagePath'] != null && product['imagePath'].toString().isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: Image.file(File(product['imagePath'].toString()), width: 32, height: 32, fit: BoxFit.cover),
                                        )
                                      : Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                                          child: Icon(Iconsax.box, size: 16, color: Colors.grey[600]),
                                        ),
                                  title: Text(name, style: const TextStyle(fontSize: 13)),
                                  subtitle: Text('${lang.Lang.tr('sell')}: ৳${(double.tryParse(sell) ?? 0.0).toStringAsFixed(2)}', style: const TextStyle(fontSize: 11)),
                                  onTap: () => _selectProduct(product),
                                );
                              },
                            ),
                          ),
                        if (_selectedProduct != null)
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: kTeal.withAlpha(15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: kTeal.withAlpha(50)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Iconsax.tick_circle, size: 16, color: kTeal),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text('${lang.Lang.tr('selected')}${_selectedProduct!['name']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: kTeal)),
                                ),
                                IconButton(
                                  icon: const Icon(Iconsax.close_circle, size: 16, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      _selectedProduct = null;
                                      _productSearchController.clear();
                                    });
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
                        TextField(controller: _amountController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: lang.Lang.tr('dueAmount'), border: const OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10))),
                        const SizedBox(height: 8),
                        TextField(controller: _noteController, decoration: InputDecoration(labelText: lang.Lang.tr('noteOptional'), border: const OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10))),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _addDueCustomer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kTeal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(lang.Lang.tr('addToDues'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
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
        onPressed: () => setState(() => _showForm = !_showForm),
        child: Icon(_showForm ? Iconsax.close_circle : Iconsax.add),
      ),
    );
  }

  Widget _buildDueSummary(String label, double amount) {
    Color amountColor;
    if (amount <= 0) {
      amountColor = Colors.green;
    } else if (amount < 100) {
      amountColor = Colors.green;
    } else if (amount < 500) {
      amountColor = Colors.orange;
    } else if (amount < 1000) {
      amountColor = Colors.deepOrange;
    } else {
      amountColor = Colors.red;
    }

    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        Text('৳${amount.toStringAsFixed(2)}', style: TextStyle(color: amountColor, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
