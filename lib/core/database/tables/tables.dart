import 'package:drift/drift.dart';

class Products extends Table {
  TextColumn get id => text()();
  TextColumn get category => text().withDefault(const Constant(''))();
  TextColumn get investor => text().withDefault(const Constant('Own Shop'))();
  TextColumn get name => text()();
  RealColumn get buyQty => real().withDefault(const Constant(0))();
  TextColumn get buyUnit => text().withDefault(const Constant('pcs'))();
  RealColumn get buyPrice => real().withDefault(const Constant(0))();
  TextColumn get sellUnit => text().withDefault(const Constant('pcs'))();
  RealColumn get sellPrice => real().withDefault(const Constant(0))();
  RealColumn get qty => real().withDefault(const Constant(0))();
  RealColumn get buyConversionFactor => real().withDefault(const Constant(1))();
  RealColumn get sellConversionFactor => real().withDefault(const Constant(1))();
  TextColumn get date => text()();
  TextColumn get imagePath => text().withDefault(const Constant(''))();
  @override
  Set<Column> get primaryKey => {id};
}

class Sales extends Table {
  TextColumn get id => text()();
  TextColumn get date => text()();
  TextColumn get productName => text()();
  RealColumn get amount => real()();
  RealColumn get profit => real().withDefault(const Constant(0))();
  TextColumn get type => text().withDefault(const Constant('cash'))();
  @override
  Set<Column> get primaryKey => {id};
}

class Customers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().withDefault(const Constant(''))();
  TextColumn get whatsapp => text().withDefault(const Constant(''))();
  TextColumn get imagePath => text().withDefault(const Constant(''))();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get address => text().withDefault(const Constant(''))();
  TextColumn get type => text().withDefault(const Constant('buyer'))();
  @override
  Set<Column> get primaryKey => {id};
}

class LedgerEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get customerId => text()();
  TextColumn get date => text()();
  RealColumn get amount => real()();
  TextColumn get type => text()();
  TextColumn get itemName => text().withDefault(const Constant(''))();
  TextColumn get imagePath => text().withDefault(const Constant(''))();
  TextColumn get note => text().withDefault(const Constant(''))();
}

class CustomerPurchases extends Table {
  TextColumn get id => text()();
  TextColumn get customerId => text()();
  TextColumn get productName => text()();
  RealColumn get price => real()();
  TextColumn get date => text()();
  @override
  Set<Column> get primaryKey => {id};
}

class CustomerOrders extends Table {
  TextColumn get id => text()();
  TextColumn get customerId => text()();
  TextColumn get description => text()();
  TextColumn get dateGiven => text()();
  TextColumn get dateNeeded => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get dateTaken => text().withDefault(const Constant(''))();
  @override
  Set<Column> get primaryKey => {id};
}

class Expenses extends Table {
  TextColumn get id => text()();
  TextColumn get type => text().withDefault(const Constant('misc'))();
  TextColumn get title => text()();
  RealColumn get amount => real()();
  TextColumn get date => text()();
  TextColumn get billPath => text().withDefault(const Constant(''))();
  IntColumn get dueDay => integer().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get vendor => text().withDefault(const Constant(''))();
  TextColumn get paymentMethod => text().withDefault(const Constant('Cash'))();
  BoolColumn get isPaid => boolean().withDefault(const Constant(false))();
  TextColumn get recurringType => text().withDefault(const Constant('none'))();
  @override
  Set<Column> get primaryKey => {id};
}

class Purchases extends Table {
  TextColumn get id => text()();
  TextColumn get date => text()();
  TextColumn get source => text().withDefault(const Constant('cash'))();
  RealColumn get cashTaken => real().withDefault(const Constant(0))();
  TextColumn get investorId => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get memoPhotoPath => text().withDefault(const Constant(''))();
  RealColumn get returnedCash => real().withDefault(const Constant(0))();
  @override
  Set<Column> get primaryKey => {id};
}

class PurchaseItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get purchaseId => text()();
  TextColumn get shopName => text().withDefault(const Constant(''))();
  TextColumn get itemName => text()();
  RealColumn get quantity => real()();
  RealColumn get unitPrice => real()();
}

class TransportCosts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get purchaseId => text()();
  TextColumn get vehicle => text()();
  RealColumn get cost => real()();
}

class OtherCosts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get purchaseId => text()();
  TextColumn get description => text()();
  RealColumn get cost => real()();
}

class Investors extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get investedAmount => real().withDefault(const Constant(0))();
  IntColumn get durationMonths => integer().withDefault(const Constant(12))();
  RealColumn get profitPercentage => real().withDefault(const Constant(0))();
  RealColumn get dailyEarnings => real().withDefault(const Constant(0))();
  RealColumn get monthlyEarnings => real().withDefault(const Constant(0))();
  TextColumn get contractType => text().withDefault(const Constant('profitShare'))();
  TextColumn get investmentType => text().withDefault(const Constant('cash'))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get startDate => text().withDefault(const Constant(''))();
  RealColumn get totalBought => real().withDefault(const Constant(0))();
  RealColumn get totalSold => real().withDefault(const Constant(0))();
  RealColumn get totalProfit => real().withDefault(const Constant(0))();
  RealColumn get remainingBalance => real().withDefault(const Constant(0))();
  RealColumn get productValueTotal => real().withDefault(const Constant(0))();
  RealColumn get cashInvested => real().withDefault(const Constant(0))();
  RealColumn get productInvested => real().withDefault(const Constant(0))();
  @override
  Set<Column> get primaryKey => {id};
}

class Repayments extends Table {
  TextColumn get id => text()();
  TextColumn get investorId => text()();
  RealColumn get amount => real()();
  TextColumn get date => text()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  @override
  Set<Column> get primaryKey => {id};
}

class FixedAssets extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get estimatedValue => real()();
  TextColumn get purchaseDate => text()();
  TextColumn get imagePath => text().withDefault(const Constant(''))();
  @override
  Set<Column> get primaryKey => {id};
}

class QuickCaptures extends Table {
  TextColumn get id => text()();
  TextColumn get timestamp => text()();
  TextColumn get note => text()();
  TextColumn get imagePath => text().withDefault(const Constant(''))();
  TextColumn get source => text().withDefault(const Constant(''))();
  @override
  Set<Column> get primaryKey => {id};
}

class RentBooks extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get pageCount => integer().withDefault(const Constant(0))();
  IntColumn get copies => integer().withDefault(const Constant(1))();
  @override
  Set<Column> get primaryKey => {id};
}

class BookRentals extends Table {
  TextColumn get id => text()();
  TextColumn get bookName => text()();
  IntColumn get pageCount => integer().withDefault(const Constant(0))();
  TextColumn get customerName => text()();
  TextColumn get dateTaken => text()();
  TextColumn get expectedReturn => text()();
  TextColumn get dateReturned => text().withDefault(const Constant(''))();
  RealColumn get cost => real().withDefault(const Constant(0))();
  BoolColumn get isPaid => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
}

class CustomerTypes extends Table {
  TextColumn get id => text()();
  TextColumn get label => text()();
  IntColumn get iconIndex => integer().withDefault(const Constant(0))();
  @override
  Set<Column> get primaryKey => {id};
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}
