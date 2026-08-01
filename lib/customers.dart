import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:io';
import 'models.dart';
import 'shop_logo.dart';
import 'lang.dart' as lang;
import 'constants.dart';

class CustomersScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  const CustomersScreen({super.key, this.onMenuTap});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _duesBox = Hive.box('duesBox');
  final _salesBox = Hive.box('salesBox');
  List<Customer> _customers = [];
  bool _showForm = false;
  final _formNameCtrl = TextEditingController();
  final _formPhoneCtrl = TextEditingController();
  final _formNoteCtrl = TextEditingController();
  String _formType = 'buyer';
  String _selectedType = 'buyer';

  static final Map<String, String> _cardHints = {
    'Purchases': lang.Lang.tr('hintPurchases'),
    'Orders': lang.Lang.tr('hintOrders'),
    'Rentals': lang.Lang.tr('hintRentals'),
    'Due': lang.Lang.tr('hintDue'),
    'Ledger': lang.Lang.tr('hintLedger'),
  };
  List<Map<String, dynamic>> _customerTypes = [];

  static const _allIcons = [
    Iconsax.folder, Iconsax.people, Iconsax.shop, Iconsax.book,
    Iconsax.bag, Iconsax.task, Iconsax.card,
    Iconsax.profile_add, Iconsax.buildings, Iconsax.teacher, Iconsax.home,
    Iconsax.briefcase, Iconsax.shop, Iconsax.truck,
    Iconsax.call, Iconsax.monitor, Iconsax.music,
    Iconsax.heart,
  ];

  static final _defaultTypes = [
    {'id': 'buyer', 'label': lang.Lang.tr('buyers'), 'icon': 4},
    {'id': 'order_giver', 'label': lang.Lang.tr('orderGivers'), 'icon': 5},
    {'id': 'renter', 'label': lang.Lang.tr('renters'), 'icon': 3},
    {'id': 'due_taker', 'label': lang.Lang.tr('dueTakers'), 'icon': 6},
    {'id': 'prospective', 'label': lang.Lang.tr('prospective'), 'icon': 7},
  ];

  static const _typeIcons = {
    'buyer': Iconsax.bag,
    'order_giver': Iconsax.task,
    'renter': Iconsax.book,
    'due_taker': Iconsax.card,
    'prospective': Iconsax.profile_add,
  };

  IconData _iconFor(String id) {
    return _typeIcons[id] ?? Iconsax.folder;
  }

  IconData _dynamicIcon(Map<String, dynamic> t) {
    final idx = t['icon'] as int? ?? 0;
    if (idx >= 0 && idx < _allIcons.length) return _allIcons[idx];
    return Iconsax.folder;
  }

  String _labelFor(String id) {
    const map = {
      'buyer': 'buyers',
      'order_giver': 'orderGivers',
      'renter': 'renters',
      'due_taker': 'dueTakers',
      'prospective': 'prospective',
    };
    final key = map[id] ?? id;
    return lang.Lang.tr(key);
  }

  @override
  void initState() {
    super.initState();
    _loadTypes();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkOrderDeadlines());
    _showForm = true;
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _showForm = false);
    });
  }

  void _loadTypes() {
    final stored = _duesBox.get('customerTypes', defaultValue: []);
    if (stored is List && stored.isNotEmpty) {
      _customerTypes = stored.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      _customerTypes = _defaultTypes.map((e) => Map<String, dynamic>.from(e)).toList();
      _duesBox.put('customerTypes', _customerTypes);
    }
  }

  void _saveTypes() {
    _duesBox.put('customerTypes', _customerTypes);
  }

  List<Customer> get _filtered =>
      _customers.where((c) => c.type == _selectedType).toList();

  void _loadData() {
    final stored = _duesBox.get('customers', defaultValue: []);
    setState(() {
      _customers = List<Map<dynamic, dynamic>>.from(stored)
          .map((c) => Customer.fromMap(Map<String, dynamic>.from(c)))
          .toList();
    });
  }

  void _saveData() {
    _duesBox.put('customers', _customers.map((c) => c.toMap()).toList());
  }

  void _showAddTypeDialog() {
    final nameCtrl = TextEditingController();
    int selectedIcon = 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          return AlertDialog(
            title: Text(lang.Lang.tr('addCustomerSection'),
                style: TextStyle(fontWeight: FontWeight.bold, color: kTeal)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                        labelText: lang.Lang.tr('sectionName'),
                        border: OutlineInputBorder())),
                const SizedBox(height: 12),
                Text(lang.Lang.tr('pickIcon'), style: TextStyle(fontSize: 13)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6, mainAxisSpacing: 4, crossAxisSpacing: 4),
                    itemCount: _allIcons.length,
                    itemBuilder: (_, i) {
                      final ic = _allIcons[i];
                      final isSelected = i == selectedIcon;
                      return GestureDetector(
                        onTap: () => setDlgState(() => selectedIcon = i),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? kTeal.withValues(alpha: 0.15) : null,
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected
                                ? Border.all(color: kTeal, width: 2)
                                : null,
                          ),
                          child: Icon(ic, color: isSelected ? kTeal : Colors.grey, size: 24),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(lang.Lang.tr('cancel'))),
              ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.isEmpty) return;
                  final id = nameCtrl.text.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
                  setState(() {
                    _customerTypes.add({
                      'id': id,
                      'label': nameCtrl.text,
                      'icon': selectedIcon,
                    });
                    _saveTypes();
                    _selectedType = id;
                  });
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: kTeal, foregroundColor: Colors.white),
                child: Text(lang.Lang.tr('addSection')),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddCustomerDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final waCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    File? image;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          Future<void> pickImage() async {
            final picked = await ImagePicker().pickImage(
              source: ImageSource.camera,
              imageQuality: 30,
              maxWidth: 300,
              maxHeight: 300,
            );
            if (picked != null) {
              setDlgState(() => image = File(picked.path));
            }
          }

          void save() {
            if (nameCtrl.text.isEmpty) return;
            setState(() {
              _customers.add(Customer(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameCtrl.text,
                phone: phoneCtrl.text,
                whatsapp: waCtrl.text.isNotEmpty ? waCtrl.text : null,
                image: image,
                note: noteCtrl.text,
                address: addressCtrl.text,
                type: _selectedType,
              ));
              _saveData();
            });
            Navigator.pop(ctx);
          }

          return AlertDialog(
            title: Text('${lang.Lang.tr('addCustomer')} ${_labelFor(_selectedType)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: kTeal)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: pickImage,
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: kTeal50,
                          backgroundImage:
                              image != null ? FileImage(image!) : null,
                          child: image == null
                              ? const Icon(Iconsax.camera, size: 24)
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                          labelText: lang.Lang.tr('name'), border: OutlineInputBorder())),
                  const SizedBox(height: 8),
                  TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                          labelText: lang.Lang.tr('phone'), border: OutlineInputBorder())),
                  const SizedBox(height: 8),
                  TextField(
                      controller: waCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                          labelText: lang.Lang.tr('whatsappNo'),
                          border: OutlineInputBorder())),
                  if (_selectedType == 'renter') ...[
                    const SizedBox(height: 8),
                    TextField(
                        controller: addressCtrl,
                        decoration: InputDecoration(
                            labelText: lang.Lang.tr('address'),
                            border: const OutlineInputBorder())),
                  ],
                  const SizedBox(height: 8),
                  TextField(
                      controller: noteCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                          labelText: lang.Lang.tr('notes'), border: const OutlineInputBorder())),
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

  void _saveCustomerFromForm() {
    if (_formNameCtrl.text.isEmpty) return;
    setState(() {
      _customers.add(Customer(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _formNameCtrl.text,
        phone: _formPhoneCtrl.text,
        note: _formNoteCtrl.text,
        type: _formType,
      ));
      _saveData();
      _showForm = false;
      _formNameCtrl.clear();
      _formPhoneCtrl.clear();
      _formNoteCtrl.clear();
    });
  }

  void _showEditCustomerDialog(Customer c) {
    final nameCtrl = TextEditingController(text: c.name);
    final phoneCtrl = TextEditingController(text: c.phone);
    final waCtrl = TextEditingController(text: c.whatsapp ?? '');
    final noteCtrl = TextEditingController(text: c.note);
    final addressCtrl = TextEditingController(text: c.address);
    File? image = c.image;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          Future<void> pickImage() async {
            final picked = await ImagePicker().pickImage(
              source: ImageSource.camera,
              imageQuality: 30,
              maxWidth: 300,
              maxHeight: 300,
            );
            if (picked != null) {
              setDlgState(() => image = File(picked.path));
            }
          }

          void save() {
            if (nameCtrl.text.isEmpty) return;
            setState(() {
              c.name = nameCtrl.text;
              c.phone = phoneCtrl.text;
              c.whatsapp = waCtrl.text.isNotEmpty ? waCtrl.text : null;
              c.image = image;
              c.note = noteCtrl.text;
              c.address = addressCtrl.text;
              _saveData();
            });
            Navigator.pop(ctx);
          }

          return AlertDialog(
            title: Text('${lang.Lang.tr('edit')} ${c.name}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: kTeal)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: pickImage,
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: kTeal50,
                          backgroundImage:
                              image != null ? FileImage(image!) : null,
                          child: image == null
                              ? const Icon(Iconsax.camera, size: 24)
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                          labelText: lang.Lang.tr('name'), border: OutlineInputBorder())),
                  const SizedBox(height: 8),
                  TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                          labelText: lang.Lang.tr('phone'), border: OutlineInputBorder())),
                  const SizedBox(height: 8),
                  TextField(
                      controller: waCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                          labelText: lang.Lang.tr('whatsappNo'),
                          border: OutlineInputBorder())),
                  const SizedBox(height: 8),
                  TextField(
                      controller: addressCtrl,
                      decoration: InputDecoration(
                          labelText: lang.Lang.tr('address'),
                          border: const OutlineInputBorder())),
                  const SizedBox(height: 8),
                  TextField(
                      controller: noteCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                          labelText: lang.Lang.tr('notes'), border: const OutlineInputBorder())),
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

  void _confirmDeleteCustomer(Customer c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lang.Lang.tr('deleteCustomer'),
            style: const TextStyle(fontWeight: FontWeight.bold, color: kTeal)),
        content: Text('${lang.Lang.tr('delete')} "${c.name}"? ${lang.Lang.tr('cannotBeUndone')}.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(lang.Lang.tr('cancel'))),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _customers.removeWhere((x) => x.id == c.id);
                _saveData();
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(lang.Lang.tr('delete')),
          ),
        ],
      ),
    );
  }

  void _showAddPurchase(Customer c) {
    final prodCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final dateCtrl = TextEditingController(
        text: DateFormat('dd-MM-yyyy').format(DateTime.now()));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lang.Lang.tr('addPurchase'),
            style: const TextStyle(fontWeight: FontWeight.bold, color: kTeal)),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: prodCtrl,
                  decoration: InputDecoration(
                      labelText: lang.Lang.tr('productName'),
                      border: const OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      labelText: lang.Lang.tr('priceTaka'), border: const OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(
                  controller: dateCtrl,
                  decoration: InputDecoration(
                      labelText: lang.Lang.tr('dateDdMmYyyy'),
                      border: const OutlineInputBorder())),
            ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(lang.Lang.tr('cancel'))),
          ElevatedButton(
            onPressed: () {
              if (prodCtrl.text.isEmpty) return;
              setState(() {
                c.purchases.add({
                  'id': DateTime.now().millisecondsSinceEpoch.toString(),
                  'productName': prodCtrl.text,
                  'price': double.tryParse(priceCtrl.text) ?? 0.0,
                  'date': dateCtrl.text,
                });
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

  void _showAddOrder(Customer c) {
    final descCtrl = TextEditingController();
    final dateNeededCtrl = TextEditingController(
        text: DateFormat('dd-MM-yyyy').format(DateTime.now()));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lang.Lang.tr('addOrder'),
            style: const TextStyle(fontWeight: FontWeight.bold, color: kTeal)),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: descCtrl,
                  decoration: InputDecoration(
                      labelText: lang.Lang.tr('orderDescription'),
                      border: const OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(
                  controller: dateNeededCtrl,
                  decoration: InputDecoration(
                      labelText: lang.Lang.tr('dateNeeded'),
                      border: const OutlineInputBorder())),
            ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(lang.Lang.tr('cancel'))),
          ElevatedButton(
            onPressed: () {
              if (descCtrl.text.isEmpty) return;
              setState(() {
                c.orders.add({
                  'id': DateTime.now().millisecondsSinceEpoch.toString(),
                  'description': descCtrl.text,
                  'dateGiven':
                      DateFormat('dd-MM-yyyy').format(DateTime.now()),
                  'dateNeeded': dateNeededCtrl.text,
                  'status': 'pending',
                  'dateTaken': '',
                });
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

  Widget _rentalStatusBadge(bool returned, bool paid, bool overdue) {
    if (returned && paid) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(lang.Lang.tr('returnedAndPaid'),
            style: const TextStyle(
                fontSize: 9,
                color: Colors.green,
                fontWeight: FontWeight.bold)),
      );
    }
    if (returned && !paid) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(lang.Lang.tr('returnedUnpaid'),
            style: const TextStyle(
                fontSize: 9,
                color: Colors.orange,
                fontWeight: FontWeight.bold)),
      );
    }
    if (overdue) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(lang.Lang.tr('overdue'),
            style: const TextStyle(
                fontSize: 9,
                color: Colors.red,
                fontWeight: FontWeight.bold)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(lang.Lang.tr('active'),
          style: const TextStyle(
              fontSize: 9,
              color: Colors.blue,
              fontWeight: FontWeight.bold)),
    );
  }

  String _orderStatus(Map o) {
    return o['status']?.toString() ??
        (o['isTaken'] == true ? 'fulfilled' : 'pending');
  }

  void _markOrderFulfilled(Customer c, int idx) {
    setState(() {
      c.orders[idx] = {
        ...c.orders[idx],
        'status': 'fulfilled',
        'dateTaken': DateFormat('dd-MM-yyyy').format(DateTime.now()),
      };
      _saveData();
    });
  }

  void _markOrderCancelled(Customer c, int idx) {
    setState(() {
      c.orders[idx] = {
        ...c.orders[idx],
        'status': 'cancelled',
        'dateTaken': DateFormat('dd-MM-yyyy').format(DateTime.now()),
      };
      _saveData();
    });
  }

  void _checkOrderDeadlines() {
    final now = DateTime.now();
    final List<String> reminders = [];
    for (final c in _customers) {
      for (final o in c.orders) {
        if (_orderStatus(o) != 'pending') continue;
        final dateNeededStr = o['dateNeeded']?.toString() ?? '';
        if (dateNeededStr.isEmpty) continue;
        try {
          final needed = DateFormat('dd-MM-yyyy').parseStrict(dateNeededStr);
          final diff = needed.difference(now);
          if (diff.inDays < 0) {
            reminders.add('${c.name}: ${o['description']} overdue by ${-diff.inDays}d');
          } else if (diff.inDays == 0) {
            reminders.add('${c.name}: ${o['description']} due TODAY');
          } else if (diff.inDays <= 2) {
            reminders.add('${c.name}: ${o['description']} due in ${diff.inDays}d');
          }
        } catch (_) {}
      }
    }
    if (reminders.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(reminders.length == 1
                ? reminders.first
                : '${reminders.length} orders need attention'),
            backgroundColor: Colors.orange.shade700,
            duration: const Duration(seconds: 5),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Iconsax.menu_1, color: Colors.white), onPressed: widget.onMenuTap),
        backgroundColor: kTeal,
        title: shopLogo(size: 20, color: Colors.white),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ..._customerTypes.map((t) {
                        final id = t['id']?.toString() ?? '';
                        final isSelected = _selectedType == id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(_labelFor(id),
                                style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal)),
                            selected: isSelected,
                            selectedColor: kTeal,
                            backgroundColor: Colors.grey.shade100,
                            avatar: Icon(_dynamicIcon(t),
                                size: 16,
                                color: isSelected ? Colors.white : kTeal),
                            onSelected: (_) =>
                                setState(() => _selectedType = id),
                          ),
                        );
                      }),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: _showAddTypeDialog,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: kTeal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Iconsax.add, size: 16, color: kTeal),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: kTeal50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(_iconFor(_selectedType),
                                  size: 40, color: kTeal.withValues(alpha: 0.5)),
                            ),
                            const SizedBox(height: 16),
                            Text('${lang.Lang.tr('no')} ${_labelFor(_selectedType)} ${lang.Lang.tr('yet')}',
                                style: TextStyle(
                                    color: Colors.grey.shade500, fontSize: 15)),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _showAddCustomerDialog,
                              icon: const Icon(Iconsax.add, size: 16),
                              label: Text(lang.Lang.tr('addOne')),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 80),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => _buildCard(_filtered[i]),
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
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lang.Lang.tr('addCustomer'),
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: kTeal)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _formNameCtrl,
                        decoration: InputDecoration(
                            labelText: lang.Lang.tr('customerName'),
                            border: const OutlineInputBorder()),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _formPhoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                            labelText: lang.Lang.tr('phone'),
                            border: const OutlineInputBorder()),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _formType,
                        decoration: InputDecoration(
                            labelText: lang.Lang.tr('customerType'),
                            border: const OutlineInputBorder()),
                        isExpanded: true,
                        items: _customerTypes.map((t) {
                          final id = t['id']?.toString() ?? '';
                          final label = t['label']?.toString() ?? id;
                          return DropdownMenuItem(
                              value: id, child: Text(label));
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _formType = v);
                        },
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _formNoteCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                            labelText: lang.Lang.tr('note'),
                            border: const OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveCustomerFromForm,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: kTeal,
                              foregroundColor: Colors.white),
                        child: Text(lang.Lang.tr('save')),
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
        onPressed: () => setState(() => _showForm = !_showForm),
        child: Icon(_showForm ? Iconsax.close_circle : Iconsax.add),
      ),
    );
  }

  Widget _buildCard(Customer c) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      elevation: 2,
      shadowColor: kTeal.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: kTeal50,
                    borderRadius: BorderRadius.circular(10),
                    image: c.image != null
                        ? DecorationImage(
                            image: FileImage(c.image!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: c.image == null
                      ? Icon(_iconFor(c.type), color: kTeal, size: 22)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(c.name,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: kTeal.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(_labelFor(c.type),
                                style: TextStyle(
                                    fontSize: 9,
                                    color: kTeal,
                                    fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (c.whatsapp != null && c.whatsapp!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(children: [
                            Icon(Iconsax.message,
                                size: 12, color: Colors.green.shade400),
                            const SizedBox(width: 4),
                            Text(c.whatsapp!,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black54)),
                          ]),
                        ),
                      if (c.phone.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(children: [
                            Icon(Iconsax.call,
                                size: 12, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(c.phone,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black54)),
                          ]),
                        ),
                      if (c.address.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(children: [
                            Icon(Iconsax.location,
                                size: 12, color: Colors.grey.shade400),
                            const SizedBox(width: 4),
                            Expanded(
                                child: Text(c.address,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54))),
                          ]),
                        ),
                      if (c.note.isNotEmpty)
                        Text(c.note,
                            style: const TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey)),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _showEditCustomerDialog(c),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Iconsax.edit,
                            size: 14, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => _confirmDeleteCustomer(c),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Iconsax.trash,
                            size: 14, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (c.type == 'buyer') _buildPurchases(c),
            if (c.type == 'order_giver') _buildOrders(c),
            if (c.type == 'renter') _buildRentals(c),
            if (c.type == 'due_taker') _buildDues(c),
          ],
        ),
      ),
    );
  }

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

  Widget _sectionHeader(String title, {String? hint}) {
    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: kTeal, width: 3)),
      ),
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          if (hint != null)
            GestureDetector(
              onTap: () => _showCardHint(hint),
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(Iconsax.info_circle, size: 12, color: Colors.grey.shade400),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPurchases(Customer c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 12),
        Row(
          children: [
            _sectionHeader(lang.Lang.tr('purchases'), hint: lang.Lang.tr('purchases')),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _showAddPurchase(c),
              icon: const Icon(Iconsax.add, size: 14),
              label: Text(lang.Lang.tr('add'), style: const TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                  foregroundColor: kTeal,
                  padding: const EdgeInsets.symmetric(horizontal: 4)),
            ),
          ],
        ),
        if (c.purchases.isEmpty)
          Text(lang.Lang.tr('noPurchases'),
              style: const TextStyle(color: Colors.grey, fontSize: 11))
        else
          ...c.purchases.map((p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Row(children: [
                  Expanded(
                      child: Text(
                          p['productName']?.toString() ?? '',
                          style: const TextStyle(fontSize: 12))),
                  Text(
                      '৳${(p['price']?.toDouble() ?? 0.0).toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 8),
                  Text(p['date']?.toString() ?? '',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey)),
                ]),
              )),
      ],
    );
  }

  Widget _buildOrders(Customer c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 12),
        Row(
          children: [
            _sectionHeader(lang.Lang.tr('orders'), hint: lang.Lang.tr('orders')),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _showAddOrder(c),
              icon: const Icon(Iconsax.add, size: 14),
              label: Text(lang.Lang.tr('add'), style: const TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                  foregroundColor: kTeal,
                  padding: const EdgeInsets.symmetric(horizontal: 4)),
            ),
          ],
        ),
        if (c.orders.isEmpty)
          Text(lang.Lang.tr('noOrders'),
              style: const TextStyle(color: Colors.grey, fontSize: 11))
        else
          ...c.orders.asMap().entries.map((entry) {
            final o = entry.value;
            final idx = entry.key;
            final status = _orderStatus(o);
            final dateGiven = o['dateGiven']?.toString() ?? '';
            final dateNeeded = o['dateNeeded']?.toString() ?? '';
            final dateTaken = o['dateTaken']?.toString() ?? '';
            final isPending = status == 'pending';
            int daysUntilDeadline = 0;
            bool overdue = false;
            if (isPending && dateNeeded.isNotEmpty) {
              try {
                final needed = DateFormat('dd-MM-yyyy').parseStrict(dateNeeded);
                final diff = needed.difference(DateTime.now());
                daysUntilDeadline = diff.inDays;
                overdue = daysUntilDeadline < 0;
              } catch (_) {}
            }
            Color deadlineColor = Colors.grey;
            String deadlineText = '';
            if (isPending && dateNeeded.isNotEmpty) {
              if (overdue) {
                deadlineColor = Colors.red;
                deadlineText = '${lang.Lang.tr('overdueBy')} ${-daysUntilDeadline}d';
              } else if (daysUntilDeadline == 0) {
                deadlineColor = Colors.red;
                deadlineText = lang.Lang.tr('dueToday');
              } else if (daysUntilDeadline <= 2) {
                deadlineColor = Colors.orange;
                deadlineText = '${lang.Lang.tr('dueIn')} ${daysUntilDeadline}d';
              } else {
                deadlineColor = Colors.green;
                deadlineText = '${lang.Lang.tr('dueIn')} ${daysUntilDeadline}d';
              }
            }
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isPending && overdue
                    ? Colors.red.shade50
                    : isPending && daysUntilDeadline <= 2
                        ? Colors.orange.shade50
                        : null,
                borderRadius: BorderRadius.circular(8),
                border: isPending && overdue
                    ? Border.all(color: Colors.red.shade200)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(o['description']?.toString() ?? '',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                decoration: status == 'fulfilled'
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: status == 'cancelled'
                                    ? Colors.grey
                                    : null)),
                      ),
                      const SizedBox(width: 6),
                      _statusBadge(status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Iconsax.check,
                        size: 12, color: Colors.grey),
                    const SizedBox(width: 3),
                    Text('${lang.Lang.tr('given')}: $dateGiven',
                        style: const TextStyle(
                            fontSize: 10, color: Colors.grey)),
                  ]),
                  if (isPending && dateNeeded.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(children: [
                      Icon(Iconsax.calendar, size: 12, color: deadlineColor),
                      const SizedBox(width: 3),
                      Text('${lang.Lang.tr('deadline')}: $dateNeeded',
                          style: TextStyle(
                              fontSize: 10, color: deadlineColor)),
                      const SizedBox(width: 8),
                      Text(deadlineText,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: deadlineColor)),
                    ]),
                  ],
                  if (status == 'fulfilled' && dateTaken.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Iconsax.tick_circle,
                          size: 12, color: Colors.green),
                      const SizedBox(width: 3),
                      Text('${lang.Lang.tr('taken')}: $dateTaken',
                          style: const TextStyle(
                              fontSize: 10, color: Colors.green)),
                    ]),
                  ],
                  if (status == 'cancelled' && dateTaken.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Iconsax.close_circle,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 3),
                      Text('${lang.Lang.tr('cancelled')}: $dateTaken',
                          style: const TextStyle(
                              fontSize: 10, color: Colors.grey)),
                    ]),
                  ],
                  if (isPending) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _markOrderFulfilled(c, idx),
                          icon: const Icon(Iconsax.tick_circle,
                              size: 14, color: Colors.green),
                          label: Text(lang.Lang.tr('fulfilled'),
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.green)),
                          style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 4)),
                        ),
                        const SizedBox(width: 4),
                        TextButton.icon(
                          onPressed: () => _markOrderCancelled(c, idx),
                          icon: const Icon(Iconsax.close_circle,
                              size: 14, color: Colors.grey),
                          label: Text(lang.Lang.tr('cancel'),
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                          style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 4)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _statusBadge(String status) {
    switch (status) {
      case 'fulfilled':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(lang.Lang.tr('fulfilled'),
              style: const TextStyle(
                  fontSize: 9,
                  color: Colors.green,
                  fontWeight: FontWeight.bold)),
        );
      case 'cancelled':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(lang.Lang.tr('cancelled'),
              style: const TextStyle(
                  fontSize: 9,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold)),
        );
      default:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(lang.Lang.tr('pending'),
              style: TextStyle(
                  fontSize: 9,
                  color: Colors.orange,
                  fontWeight: FontWeight.bold)),
        );
    }
  }

  Widget _buildRentals(Customer c) {
    final allRentals = List<Map<String, dynamic>>.from(
        (_salesBox.get('bookRentals', defaultValue: []) as List)
            .map((e) => Map<String, dynamic>.from(e as Map)));
    final customerRentals =
        allRentals.where((r) => r['customerName']?.toString() == c.name).toList();
    final allBooks = List<Map<String, dynamic>>.from(
        (_salesBox.get('rentBooks', defaultValue: []) as List)
            .map((e) => Map<String, dynamic>.from(e as Map)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 12),
        Row(
          children: [
            _sectionHeader(lang.Lang.tr('rentals'), hint: lang.Lang.tr('rentals')),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _showBookRentalDialog(c, allBooks),
              icon: const Icon(Iconsax.add, size: 14),
              label: Text(lang.Lang.tr('add'), style: const TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                  foregroundColor: kTeal,
                  padding: const EdgeInsets.symmetric(horizontal: 4)),
            ),
          ],
        ),
        if (customerRentals.isEmpty)
          Text(lang.Lang.tr('noRentals'),
              style: const TextStyle(color: Colors.grey, fontSize: 11))
        else
          ...customerRentals.asMap().entries.map((entry) {
            final r = entry.value;
            final dateTaken = r['dateTaken']?.toString() ?? '';
            final dateReturned = r['dateReturned']?.toString() ?? '';
            final returned = dateReturned.isNotEmpty;
            final paid = r['isPaid'] == true;
            final cost = (r['cost'] as num?)?.toDouble() ?? 0.0;
            final overdue = !returned && dateTaken.isNotEmpty
                ? DateTime.now()
                        .difference(
                            DateFormat('dd-MM-yyyy').tryParse(dateTaken) ??
                                DateTime.now())
                        .inDays >
                    7
                : false;

            Color bgColor = Colors.transparent;
            Color borderColor = Colors.transparent;
            if (returned && paid) {
              bgColor = Colors.green.shade50;
              borderColor = Colors.green.shade200;
            } else if (returned && !paid) {
              bgColor = Colors.orange.shade50;
              borderColor = Colors.orange.shade200;
            } else if (overdue) {
              bgColor = Colors.red.shade50;
              borderColor = Colors.red.shade200;
            } else {
              bgColor = Colors.blue.shade50;
              borderColor = Colors.blue.shade200;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(r['bookName']?.toString() ?? '',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(width: 6),
                      _rentalStatusBadge(returned, paid, overdue),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Iconsax.calendar,
                        size: 12, color: Colors.grey),
                    const SizedBox(width: 3),
                    Text('${lang.Lang.tr('taken')}: $dateTaken',
                        style: const TextStyle(
                            fontSize: 10, color: Colors.grey)),
                  ]),
                  if (returned) ...[
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Iconsax.calendar_tick,
                          size: 12, color: Colors.green),
                      const SizedBox(width: 3),
                      Text('${lang.Lang.tr('returned')}: $dateReturned',
                          style: const TextStyle(
                              fontSize: 10, color: Colors.green)),
                    ]),
                  ],
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Iconsax.money,
                        size: 12, color: Colors.black54),
                    const SizedBox(width: 3),
                    Text('${lang.Lang.tr('cost')}: ৳${cost.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold, color: kTeal)),
                  ]),
                  const SizedBox(height: 2),
                  Row(children: [
                    Icon(
                        paid ? Iconsax.tick_circle : Iconsax.close_circle,
                        size: 12,
                        color: paid ? Colors.green : Colors.red),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _toggleSharedRentalPaid(r, c.name),
                      child: Text(paid ? lang.Lang.tr('paid') : lang.Lang.tr('unpaid'),
                          style: TextStyle(
                              fontSize: 11,
                              color: paid ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold)),
                    ),
                  ]),
                  if (!returned) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _returnSharedRental(r, c.name),
                        icon: const Icon(Iconsax.refresh,
                            size: 14, color: kTeal),
                        label: Text(lang.Lang.tr('return'),
                            style: const TextStyle(
                                fontSize: 11, color: kTeal)),
                        style: TextButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4)),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }

  void _toggleSharedRentalPaid(Map<String, dynamic> rental, String customerName) {
    final allRentals = List<Map<String, dynamic>>.from(
        (_salesBox.get('bookRentals', defaultValue: []) as List)
            .map((e) => Map<String, dynamic>.from(e as Map)));
    final target = allRentals.firstWhere(
        (r) => r['customerName']?.toString() == customerName &&
            r['bookName']?.toString() == rental['bookName']?.toString() &&
            r['dateTaken']?.toString() == rental['dateTaken']?.toString(),
        orElse: () => <String, dynamic>{});
    if (target.isNotEmpty) {
      setState(() {
        target['isPaid'] = !(target['isPaid'] == true);
        _salesBox.put('bookRentals', allRentals);
      });
    }
  }

  void _returnSharedRental(Map<String, dynamic> rental, String customerName) {
    final allRentals = List<Map<String, dynamic>>.from(
        (_salesBox.get('bookRentals', defaultValue: []) as List)
            .map((e) => Map<String, dynamic>.from(e as Map)));
    final target = allRentals.firstWhere(
        (r) => r['customerName']?.toString() == customerName &&
            r['bookName']?.toString() == rental['bookName']?.toString() &&
            r['dateTaken']?.toString() == rental['dateTaken']?.toString(),
        orElse: () => <String, dynamic>{});
    if (target.isNotEmpty) {
      setState(() {
        target['dateReturned'] =
            DateFormat('dd-MM-yyyy').format(DateTime.now());
        _salesBox.put('bookRentals', allRentals);
      });
    }
  }

  void _showBookRentalDialog(Customer c, List<Map<String, dynamic>> books) {
    String? selectedBook;
    final daysCtrl = TextEditingController(text: '10');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          return AlertDialog(
            title: Text(lang.Lang.tr('rentABook'),
                style: const TextStyle(fontWeight: FontWeight.bold, color: kTeal)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (books.isEmpty)
                  Text(lang.Lang.tr('noBooksAvailable'),
                      style: const TextStyle(color: Colors.grey, fontSize: 12))
                else ...[
                  DropdownButtonFormField<String>(
                    initialValue: selectedBook,
                    decoration: InputDecoration(
                        labelText: lang.Lang.tr('selectBook'), border: const OutlineInputBorder()),
                    isExpanded: true,
                    items: books.map((b) {
                      final price = ((b['pageCount'] as int? ?? 0) - 1) ~/ 100 + 1;
                      return DropdownMenuItem(
                        value: b['name']?.toString() ?? '',
                        child: Text(
                            '${b['name']} (${b['pageCount']}p - ৳${price * 10}/10d)'),
                      );
                    }).toList(),
                    onChanged: (v) => setDlgState(() => selectedBook = v),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                      controller: daysCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          labelText: lang.Lang.tr('days'), border: const OutlineInputBorder())),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(lang.Lang.tr('cancel'))),
              ElevatedButton(
                onPressed: () {
                  if (selectedBook == null) return;
                  final days = int.tryParse(daysCtrl.text) ?? 10;
                  final book = books.firstWhere(
                      (b) => b['name']?.toString() == selectedBook);
                  final pageCount = book['pageCount'] as int? ?? 0;
                  final rate = ((pageCount - 1) ~/ 100 + 1) * 10;
                  final periods = ((days - 1) ~/ 10 + 1);
                  final cost = rate * periods;
                  final dateStr = DateFormat('dd-MM-yyyy').format(DateTime.now());
                  final newRental = <String, dynamic>{
                    'id': DateTime.now().millisecondsSinceEpoch.toString(),
                    'bookName': selectedBook,
                    'pageCount': pageCount,
                    'customerName': c.name,
                    'dateTaken': dateStr,
                    'expectedReturn':
                        DateFormat('dd-MM-yyyy').format(
                            DateTime.now().add(Duration(days: days))),
                    'dateReturned': '',
                    'cost': cost.toDouble(),
                    'isPaid': false,
                  };
                  setState(() {
                    final all = List<Map<String, dynamic>>.from(
                        (_salesBox.get('bookRentals', defaultValue: []) as List)
                            .map((e) => Map<String, dynamic>.from(e as Map)));
                    all.add(newRental);
                    _salesBox.put('bookRentals', all);
                    // Update customer type to renter if needed
                    if (c.type != 'renter') {
                      c.type = 'renter';
                      _saveData();
                    }
                  });
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: kTeal, foregroundColor: Colors.white),
                child: Text(lang.Lang.tr('rent')),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDues(Customer c) {
    final dues =
        c.ledger.where((e) => e['type'] == 'due').toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 12),
        _sectionHeader(lang.Lang.tr('dues'), hint: lang.Lang.tr('due')),
        if (dues.isEmpty)
          Text(lang.Lang.tr('noDues'),
              style: TextStyle(color: Colors.grey, fontSize: 11))
        else
          ...dues.map((d) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Row(children: [
                  Expanded(
                      child: Text(
                          d['itemName']?.toString() ??
                              d['note']?.toString() ?? '',
                          style: const TextStyle(fontSize: 12))),
                  Text(
                      '৳${(d['amount']?.toDouble() ?? 0.0).toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 8),
                  Text(d['date']?.toString() ?? '',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey)),
                ]),
              )),
      ],
    );
  }

  @override
  void dispose() {
    _formNameCtrl.dispose();
    _formPhoneCtrl.dispose();
    _formNoteCtrl.dispose();
    super.dispose();
  }
}
