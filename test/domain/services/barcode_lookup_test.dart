import 'package:test/test.dart';
import 'package:inventory/core/money/money.dart';
import 'package:inventory/domain/entities/fund_source.dart';
import 'package:inventory/domain/entities/product.dart';
import 'package:inventory/domain/services/barcode_lookup.dart';

Product _product({required String id, String? barcode}) {
  return Product(
    id: id,
    name: 'Product $id',
    category: 'Book',
    costPrice: Money.fromMinor(10000),
    suggestedSellPrice: Money.fromMinor(15000),
    qty: 5,
    fundSource: FundSource.shop(),
    barcode: barcode,
  );
}

void main() {
  group('findProductByBarcode', () {
    test('finds the product with a matching barcode', () {
      final products = [
        _product(id: 'a', barcode: '111'),
        _product(id: 'b', barcode: '222'),
      ];
      final result = findProductByBarcode(products, '222');
      expect(result?.id, 'b');
    });

    test('null when no product has that barcode', () {
      final products = [_product(id: 'a', barcode: '111')];
      expect(findProductByBarcode(products, '999'), isNull);
    });

    test(
      'null when the barcode is blank, even if a product has an empty barcode',
      () {
        final products = [_product(id: 'a', barcode: '')];
        expect(findProductByBarcode(products, ''), isNull);
        expect(findProductByBarcode(products, '   '), isNull);
      },
    );

    test('trims whitespace from a scanned code before matching', () {
      final products = [_product(id: 'a', barcode: '12345')];
      expect(findProductByBarcode(products, '  12345  ')?.id, 'a');
    });

    test('ignores products with no barcode at all', () {
      final products = [_product(id: 'a', barcode: null)];
      expect(findProductByBarcode(products, '12345'), isNull);
    });

    test('empty product list never matches', () {
      expect(findProductByBarcode(const [], '12345'), isNull);
    });
  });
}
