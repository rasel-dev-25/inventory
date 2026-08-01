import 'dart:io';

class Customer {
  final String id;
  String name;
  String phone;
  String? whatsapp;
  File? image;
  String note;
  String address;
  String type;
  List<Map<String, dynamic>> ledger;
  List<Map<String, dynamic>> purchases;
  List<Map<String, dynamic>> orders;
  List<Map<String, dynamic>> rentals;

  Customer({
    required this.id,
    required this.name,
    this.phone = '',
    this.whatsapp,
    this.image,
    this.note = '',
    this.address = '',
    this.type = 'buyer',
    List<Map<String, dynamic>>? ledger,
    List<Map<String, dynamic>>? purchases,
    List<Map<String, dynamic>>? orders,
    List<Map<String, dynamic>>? rentals,
  })  : ledger = ledger ?? <Map<String, dynamic>>[],
        purchases = purchases ?? <Map<String, dynamic>>[],
        orders = orders ?? <Map<String, dynamic>>[],
        rentals = rentals ?? <Map<String, dynamic>>[];

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'whatsapp': whatsapp ?? '',
        'imagePath': image?.path ?? '',
        'note': note,
        'address': address,
        'type': type,
        'ledger': ledger,
        'purchases': purchases,
        'orders': orders,
        'rentals': rentals,
      };

  factory Customer.fromMap(Map<String, dynamic> m) {
    List<Map<String, dynamic>> cleanList(dynamic raw) {
      if (raw is List) {
        return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    }
    return Customer(
      id: m['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: m['name']?.toString() ?? '',
      phone: m['phone']?.toString() ?? '',
      whatsapp: m['whatsapp']?.toString(),
      image: m['imagePath'] != null && m['imagePath'].toString().isNotEmpty
          ? File(m['imagePath'].toString())
          : null,
      note: m['note']?.toString() ?? '',
      address: m['address']?.toString() ?? '',
      type: m['type']?.toString() ?? 'buyer',
      ledger: cleanList(m['ledger']),
      purchases: cleanList(m['purchases']),
      orders: cleanList(m['orders']),
      rentals: cleanList(m['rentals']),
    );
  }
}

class Expense {
  final String id;
  final String type;
  final String title;
  final double amount;
  final String date;
  final File? billImage;
  final int? dueDay;
  final String note;
  final String vendor;
  final String paymentMethod;
  final bool isPaid;
  final String recurringType;

  Expense({
    required this.id,
    required this.type,
    required this.title,
    required this.amount,
    required this.date,
    this.billImage,
    this.dueDay,
    this.note = '',
    this.vendor = '',
    this.paymentMethod = '',
    this.isPaid = false,
    this.recurringType = 'none',
  });
}

class PurchaseItem {
  final String shopName;
  final String itemName;
  final double quantity;
  final double unitPrice;

  PurchaseItem({
    required this.shopName,
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;

  Map<String, dynamic> toMap() => {
        'shopName': shopName,
        'itemName': itemName,
        'quantity': quantity,
        'unitPrice': unitPrice,
      };

  factory PurchaseItem.fromMap(Map<String, dynamic> m) => PurchaseItem(
        shopName: m['shopName']?.toString() ?? '',
        itemName: m['itemName']?.toString() ?? '',
        quantity: (m['quantity']?.toDouble() ?? 0.0),
        unitPrice: (m['unitPrice']?.toDouble() ?? 0.0),
      );
}

class TransportCost {
  final String vehicle;
  final double cost;

  TransportCost({required this.vehicle, required this.cost});

  Map<String, dynamic> toMap() => {'vehicle': vehicle, 'cost': cost};

  factory TransportCost.fromMap(Map<String, dynamic> m) => TransportCost(
        vehicle: m['vehicle']?.toString() ?? '',
        cost: (m['cost']?.toDouble() ?? 0.0),
      );
}

class OtherCost {
  final String description;
  final double cost;

  OtherCost({required this.description, required this.cost});

  Map<String, dynamic> toMap() => {'description': description, 'cost': cost};

  factory OtherCost.fromMap(Map<String, dynamic> m) => OtherCost(
        description: m['description']?.toString() ?? '',
        cost: (m['cost']?.toDouble() ?? 0.0),
      );
}

class Purchase {
  final String id;
  final String date;
  final String source;
  final double cashTaken;
  final String? investorId;
  final List<PurchaseItem> items;
  final List<TransportCost> transportCosts;
  final List<OtherCost> otherCosts;
  final double returnedCash;
  final String? memoPhotoPath;
  final String notes;

  Purchase({
    required this.id,
    required this.date,
    required this.source,
    this.cashTaken = 0.0,
    this.investorId,
    required this.items,
    required this.transportCosts,
    this.otherCosts = const [],
    this.returnedCash = 0.0,
    this.memoPhotoPath,
    this.notes = '',
  });

  double get itemsTotal => items.fold(0.0, (s, i) => s + i.total);
  double get transportTotal => transportCosts.fold(0.0, (s, t) => s + t.cost);
  double get otherTotal => otherCosts.fold(0.0, (s, o) => s + o.cost);
  double get netUsed => cashTaken - returnedCash;
  double get totalSpent => itemsTotal + transportTotal + otherTotal;
  double get balanceDiff => netUsed - totalSpent;
  bool get isBalanced => balanceDiff.abs() < 0.01;
  double get grandTotal => itemsTotal + transportTotal + otherTotal;

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date,
        'source': source,
        'cashTaken': cashTaken,
        'investorId': investorId ?? '',
        'notes': notes,
        'memoPhotoPath': memoPhotoPath ?? '',
        'items': items.map((i) => i.toMap()).toList(),
        'transportCosts': transportCosts.map((t) => t.toMap()).toList(),
        'otherCosts': otherCosts.map((o) => o.toMap()).toList(),
        'returnedCash': returnedCash,
      };

  factory Purchase.fromMap(Map<String, dynamic> m) {
    if (m['items'] == null && m['goodsDetails'] != null) {
      return Purchase(
        id: m['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        date: m['date']?.toString() ?? '',
        source: 'cash',
        cashTaken: (m['cashTaken']?.toDouble() ?? 0.0),
        items: [
          PurchaseItem(
            shopName: '',
            itemName: m['goodsDetails']?.toString() ?? '',
            quantity: 1,
            unitPrice: (m['cashTaken']?.toDouble() ?? 0.0),
          ),
        ],
        transportCosts: [],
        memoPhotoPath: m['memoPhotoPath']?.toString(),
      );
    }
    return Purchase(
      id: m['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      date: m['date']?.toString() ?? '',
      source: m['source']?.toString() ?? 'cash',
      cashTaken: (m['cashTaken']?.toDouble() ?? 0.0),
      investorId: m['investorId']?.toString(),
      notes: m['notes']?.toString() ?? '',
      memoPhotoPath: m['memoPhotoPath']?.toString(),
      items: (m['items'] as List<dynamic>?)
              ?.map((e) => PurchaseItem.fromMap(Map<String, dynamic>.from(e)))
              .toList() ?? [],
      transportCosts: (m['transportCosts'] as List<dynamic>?)
              ?.map((e) => TransportCost.fromMap(Map<String, dynamic>.from(e)))
              .toList() ?? [],
      otherCosts: (m['otherCosts'] as List<dynamic>?)
              ?.map((e) => OtherCost.fromMap(Map<String, dynamic>.from(e)))
              .toList() ?? [],
      returnedCash: (m['returnedCash']?.toDouble() ?? 0.0),
    );
  }
}

class Repayment {
  final String id;
  final double amount;
  final String date;
  final String notes;

  Repayment({
    required this.id,
    required this.amount,
    required this.date,
    this.notes = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'amount': amount,
        'date': date,
        'notes': notes,
      };

  factory Repayment.fromMap(Map<String, dynamic> m) => Repayment(
        id: m['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        amount: (m['amount']?.toDouble() ?? 0.0),
        date: m['date']?.toString() ?? '',
        notes: m['notes']?.toString() ?? '',
      );
}

class Investor {
  final String id;
  final String name;
  double investedAmount;
  final int durationMonths;
  final double profitPercentage;
  double dailyEarnings;
  double monthlyEarnings;

  // New tracking fields
  String contractType;   // 'loan' | 'consignment' | 'profitShare'
  String investmentType; // 'cash' | 'products' | 'mixed'
  bool isActive;
  String startDate;
  double totalBought;
  double totalSold;
  double totalProfit;
  double remainingBalance;
  double productValueTotal;
  double cashInvested;
  double productInvested;
  List<Repayment> repayments;

  Investor({
    required this.id,
    required this.name,
    this.investedAmount = 0.0,
    this.durationMonths = 12,
    this.profitPercentage = 0.0,
    this.dailyEarnings = 0.0,
    this.monthlyEarnings = 0.0,
    this.contractType = 'profitShare',
    this.investmentType = 'cash',
    this.isActive = true,
    this.startDate = '',
    this.totalBought = 0.0,
    this.totalSold = 0.0,
    this.totalProfit = 0.0,
    this.remainingBalance = 0.0,
    this.productValueTotal = 0.0,
    this.cashInvested = 0.0,
    this.productInvested = 0.0,
    this.repayments = const [],
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'investedAmount': investedAmount,
        'durationMonths': durationMonths,
        'profitPercentage': profitPercentage,
        'dailyEarnings': dailyEarnings,
        'monthlyEarnings': monthlyEarnings,
        'contractType': contractType,
        'investmentType': investmentType,
        'isActive': isActive,
        'startDate': startDate,
        'totalBought': totalBought,
        'totalSold': totalSold,
        'totalProfit': totalProfit,
        'remainingBalance': remainingBalance,
        'productValueTotal': productValueTotal,
        'cashInvested': cashInvested,
        'productInvested': productInvested,
        'repayments': repayments.map((r) => r.toMap()).toList(),
      };

  factory Investor.fromMap(Map<String, dynamic> m) => Investor(
        id: m['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: m['name']?.toString() ?? '',
        investedAmount: (m['investedAmount']?.toDouble() ?? 0.0),
        durationMonths: (m['durationMonths']?.toInt() ?? 12),
        profitPercentage: (m['profitPercentage']?.toDouble() ?? 0.0),
        dailyEarnings: (m['dailyEarnings']?.toDouble() ?? 0.0),
        monthlyEarnings: (m['monthlyEarnings']?.toDouble() ?? 0.0),
        contractType: m['contractType']?.toString() ?? 'profitShare',
        investmentType: m['investmentType']?.toString() ?? 'cash',
        isActive: (m['isActive'] ?? true) == true,
        startDate: m['startDate']?.toString() ?? '',
        totalBought: (m['totalBought']?.toDouble() ?? 0.0),
        totalSold: (m['totalSold']?.toDouble() ?? 0.0),
        totalProfit: (m['totalProfit']?.toDouble() ?? 0.0),
        remainingBalance: (m['remainingBalance']?.toDouble() ?? 0.0),
        productValueTotal: (m['productValueTotal']?.toDouble() ?? 0.0),
        cashInvested: (m['cashInvested']?.toDouble() ?? 0.0),
        productInvested: (m['productInvested']?.toDouble() ?? 0.0),
        repayments: (m['repayments'] as List<dynamic>?)
                ?.map((e) => Repayment.fromMap(Map<String, dynamic>.from(e)))
                .toList() ?? [],
      );
}

class FixedAsset {
  final String id;
  final String name;
  final double estimatedValue;
  final String purchaseDate;
  final File? image;

  FixedAsset({
    required this.id,
    required this.name,
    required this.estimatedValue,
    required this.purchaseDate,
    this.image,
  });
}

class Sale {
  final String id;
  final String date;
  final String productName;
  final double amount;
  final double profit;
  final String type;

  Sale({
    required this.id,
    required this.date,
    required this.productName,
    required this.amount,
    required this.profit,
    required this.type,
  });
}
