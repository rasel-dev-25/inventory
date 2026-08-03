import 'package:get/get.dart' hide Value;
import 'package:drift/drift.dart' hide Column;

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/investor_dao.dart';
import '../../../../core/database/daos/product_dao.dart';
import '../../../../core/database/daos/sale_dao.dart';
import '../../../../core/utils/date_utils.dart';

class InvestorController extends GetxController {
  final _db = Get.find<AppDatabase>();

  final investors = <Investor>[].obs;
  final showForm = false.obs;

  InvestorDao get _dao => _db.investorDao;
  ProductDao get _productDao => _db.productDao;
  SaleDao get _saleDao => _db.saleDao;

  @override
  void onInit() {
    super.onInit();
    loadInvestors();
    showForm.value = true;
    Future.delayed(
      const Duration(milliseconds: 1000),
      () => showForm.value = false,
    );
  }

  Future<void> loadInvestors() async {
    investors.value = await _dao.getAll();
    for (final inv in investors) {
      await recalcFromStockAndSales(inv);
    }
  }

  Future<void> recalcFromStockAndSales(Investor inv) async {
    final products = await _productDao.getByInvestor(inv.name);
    double stockValue = 0, totalBought = 0;
    final productNames = <String>{};

    for (final p in products) {
      final costPerUnit = p.buyConversionFactor > 0
          ? p.buyPrice / p.buyConversionFactor
          : 0.0;
      stockValue += costPerUnit * p.qty;
      totalBought += p.buyQty * p.buyPrice;
      productNames.add(p.name);
    }

    final allSales = await _saleDao.getAll();
    double sold = 0, profit = 0;
    for (final s in allSales) {
      if (productNames.contains(s.productName)) {
        sold += s.amount;
        profit += s.profit;
      }
    }

    final repaid = (await _dao.getRepayments(
      inv.id,
    )).fold(0.0, (s, r) => s + r.amount);
    double remaining;
    if (inv.investmentType == 'products' || inv.contractType == 'consignment') {
      remaining = stockValue;
    } else {
      remaining = inv.investedAmount - repaid;
    }

    await _dao.updateInvestor(
      inv.id,
      InvestorsCompanion(
        productValueTotal: Value(stockValue),
        totalBought: Value(totalBought),
        totalSold: Value(sold),
        totalProfit: Value(profit),
        remainingBalance: Value(remaining),
      ),
    );
  }

  // --- CRUD ---

  Future<void> addInvestor({
    required String name,
    required double investedAmount,
    required int durationMonths,
    required double profitPercentage,
    required String contractType,
    required String investmentType,
    double cashInvested = 0,
    double productInvested = 0,
  }) async {
    await _dao.insertInvestor(
      InvestorsCompanion.insert(
        id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        investedAmount: Value(investedAmount),
        durationMonths: Value(durationMonths),
        profitPercentage: Value(profitPercentage),
        contractType: Value(contractType),
        investmentType: Value(investmentType),
        startDate: Value(AppDateUtils.today()),
        cashInvested: Value(cashInvested),
        productInvested: Value(productInvested),
      ),
    );
    await loadInvestors();
  }

  Future<void> updateInvestor(
    Investor inv, {
    required String name,
    required double investedAmount,
    required int durationMonths,
    required double profitPercentage,
    required String contractType,
    required String investmentType,
    double cashInvested = 0,
    double productInvested = 0,
  }) async {
    await _dao.updateInvestor(
      inv.id,
      InvestorsCompanion(
        name: Value(name),
        investedAmount: Value(investedAmount),
        durationMonths: Value(durationMonths),
        profitPercentage: Value(profitPercentage),
        contractType: Value(contractType),
        investmentType: Value(investmentType),
        cashInvested: Value(cashInvested),
        productInvested: Value(productInvested),
      ),
    );
    await loadInvestors();
  }

  Future<void> deleteInvestor(String id) async {
    await _dao.deleteInvestor(id);
    await loadInvestors();
  }

  // --- Repayments ---

  Future<void> addRepayment(
    String investorId,
    double amount,
    String notes,
  ) async {
    await _dao.addRepayment(
      RepaymentsCompanion.insert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        investorId: investorId,
        amount: amount,
        date: AppDateUtils.today(),
        notes: Value(notes),
      ),
    );
    await loadInvestors();
  }

  Future<List<Repayment>> getRepayments(String investorId) =>
      _dao.getRepayments(investorId);

  // --- Helpers ---

  String contractLabel(String ct) {
    switch (ct) {
      case 'loan':
        return 'cashLoan'.tr;
      case 'consignment':
        return 'productConsignment'.tr;
      case 'profitShare':
        return 'profitSplit'.tr;
      default:
        return ct;
    }
  }

  String investLabel(String it) {
    switch (it) {
      case 'cash':
        return 'cashInvestment'.tr;
      case 'products':
        return 'productConsignment'.tr;
      case 'mixed':
        return 'mixed'.tr;
      default:
        return it;
    }
  }

  Future<double> calcFromStock(String name) async {
    final products = await _productDao.getByInvestor(name);
    double total = 0;
    for (final p in products) {
      total += p.buyQty * p.buyPrice;
    }
    return total;
  }
}
