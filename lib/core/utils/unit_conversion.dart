class UnitConversion {
  static const Map<String, double> factors = {
    'pcs': 1,
    'kg': 1000,
    'box': 1,
    'pack': 1,
    'litre': 1000,
    'pair': 2,
    'set': 1,
    'roll': 1,
    'dozen': 12,
  };

  static const List<String> units = ['pcs', 'kg', 'box', 'pack', 'litre', 'pair', 'set', 'roll', 'dozen'];

  static double factorFor(String unit) => factors[unit] ?? 1;

  /// Convert buy price per buy-unit to price per sell-unit.
  /// e.g. buy at 2000/litre, sell per ml → 2000/1000 = 2 per ml
  static double buyPricePerSellUnit(double buyPrice, String buyUnit, String sellUnit) {
    final buyFactor = factorFor(buyUnit);
    final sellFactor = factorFor(sellUnit);
    if (sellFactor == 0) return buyPrice;
    return buyPrice * sellFactor / buyFactor;
  }

  /// Convert a quantity in sell-units to buy-units.
  static double sellQtyToBuyQty(double qty, String buyUnit, String sellUnit) {
    final buyFactor = factorFor(buyUnit);
    final sellFactor = factorFor(sellUnit);
    if (buyFactor == 0) return qty;
    return qty * sellFactor / buyFactor;
  }
}
