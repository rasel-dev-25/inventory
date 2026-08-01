with open('lib/test_minimal2.dart', 'w', encoding='utf-8') as f:
    f.write('''import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'models.dart';

class DuesScreen extends StatefulWidget {
  final String? prefilledName;
  final double? prefilledAmount;

  const DuesScreen({super.key, this.prefilledName, this.prefilledAmount});

  @override
  State<DuesScreen> createState() => _DuesScreenState();
}

class _DuesScreenState extends State<DuesScreen> {
  final _duesBox = Hive.box('duesBox');
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _paymentController = TextEditingController();
  File? _customerImage;

  double _todayDue = 0.0;
  double _monthlyDue = 0.0;
  double _totalDue = 0.0;
  List<Customer> _customers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final stored = _duesBox.get('customers', defaultValue: []);
    setState(() {
      _customers = List<Map<dynamic, dynamic>>.from(stored).map((c) => Customer(
        id: c['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: c['name']?.toString() ?? '',
        phone: c['phone']?.toString() ?? '',
        image: c['imagePath'] != null ? File(c['imagePath']) : null,
        ledger: List<Map<String, dynamic>>.from(c['ledger'] ?? []),
      )).toList();
      _calculateTotals();
    });
  }

  void _calculateTotals() {
    _todayDue = 0.0;
    _monthlyDue = 0.0;
    _totalDue = 0.0;
    String today = DateFormat('dd-MM-yyyy').format(DateTime.now());
    String currentMonth = DateFormat('MM-yyyy').format(DateTime.now());

    for (var customer in _customers) {
      for (var entry in customer.ledger) {
        if (entry['type'] == 'due') {
          String entryDate = entry['date']?.toString() ?? '';
          if (entryDate == today) {
            _todayDue += (entry['amount']?.toDouble() ?? 0.0);
          }
          if (entryDate.contains(currentMonth)) {
            _monthlyDue += (entry['amount']?.toDouble() ?? 0.0);
          }
          _totalDue += (entry['amount']?.toDouble() ?? 0.0);
        }
      }
    }
  }

  void _showCustomerDetail(Customer customer) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00897B))),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mobile: ${customer.phone}', style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 10),
                    const Text('Ledger:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    if (customer.ledger.isEmpty)
                      const Text('No records', style: TextStyle(color: Colors.grey))
                    else
                      ...customer.ledger.map((entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${entry['date']} - ${entry['type'] == 'due' ? 'Due' : 'Payment'}'),
                            Text('Tk${entry['amount']}', style: TextStyle(color: entry['type'] == 'due' ? Colors.red : Colors.green)),
                          ],
                        ),
                      )),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _paymentController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Payment Amount', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                ElevatedButton(
                  onPressed: () {
                    if (_paymentController.text.isEmpty) return;
                    double payment = double.tryParse(_paymentController.text) ?? 0.0;
                    String today = DateFormat('dd-MM-yyyy').format(DateTime.now());

                    setState(() {
                      customer.ledger.add({'date': today, 'amount': payment, 'type': 'payment'});
                      _calculateTotals();
                      _saveData();
                    });
                    setDialogState(() {});
                    _paymentController.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Payment saved.'), backgroundColor: Colors.green),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Receive Payment'),
                ),
              ],
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00897B),
        title: const Text('Dues Dashboard', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF004D40),
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDueSummary('Today Due', _todayDue),
                _buildDueSummary('Monthly Due', _monthlyDue),
                _buildDueSummary('Total Due', _totalDue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDueSummary(String label, double amount) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text('Tk$amount', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
''')
