import 'package:inventory/data/sync/enum_case_bridge.dart';
import 'package:test/test.dart';

void main() {
  group('EnumCaseBridge.toRemote', () {
    test('converts a registered enum column from camelCase to snake_case', () {
      final row = {'id': 'x1', 'payment_method': 'mobileBanking'};
      final result = EnumCaseBridge.toRemote('cash_ledger_entries', row);
      expect(result['payment_method'], 'mobile_banking');
    });

    test('converts every registered enum column on a multi-enum table', () {
      final row = {
        'id': 'sale-1',
        'payment_status': 'partiallyPaid',
        'payment_method': 'bankTransfer',
        'fund_source_type': 'investor',
      };
      final result = EnumCaseBridge.toRemote('sales', row);

      expect(result['payment_status'], 'partially_paid');
      expect(result['payment_method'], 'bank_transfer');
      // Already-lowercase single-word enum values are unaffected.
      expect(result['fund_source_type'], 'investor');
    });

    test(
      'leaves non-enum columns untouched, including camelCase-looking free text',
      () {
        final row = {
          'id': 'x1',
          'payment_method': 'cash',
          'name': 'AlAshabShop',
        };
        final result = EnumCaseBridge.toRemote('cash_ledger_entries', row);
        expect(result['name'], 'AlAshabShop');
      },
    );

    test('is a no-op for a table with no registered enum columns', () {
      final row = {'id': 'c1', 'name': 'Books'};
      final result = EnumCaseBridge.toRemote('categories', row);
      expect(result, row);
    });

    test('does not mutate the original map', () {
      final row = {'id': 'x1', 'payment_method': 'mobileBanking'};
      EnumCaseBridge.toRemote('cash_ledger_entries', row);
      expect(row['payment_method'], 'mobileBanking');
    });
  });

  group('EnumCaseBridge.toLocal', () {
    test(
      'converts a registered enum column from snake_case back to camelCase',
      () {
        final row = {'id': 'x1', 'payment_method': 'mobile_banking'};
        final result = EnumCaseBridge.toLocal('cash_ledger_entries', row);
        expect(result['payment_method'], 'mobileBanking');
      },
    );

    test('converts a three-part snake_case value correctly', () {
      final row = {'id': 'a1', 'source_type': 'shop_cash_purchase'};
      final result = EnumCaseBridge.toLocal('fixed_assets', row);
      expect(result['source_type'], 'shopCashPurchase');
    });

    test(
      'toRemote then toLocal round-trips every real enum value used in the schema',
      () {
        const camelValues = [
          'cash', 'mobileBanking', 'bankTransfer', // PaymentMethod
          'shop', 'investor', // FundSourceType
          'cashLoan',
          'cashMudaraba',
          'cashMusharaka',
          'goodsInKind', // InvestmentType
          'daily', 'monthly', 'perContract', // ProfitPayoutCycle
          'fullCash', 'partial', 'fullDue', // PaymentStatus
          'pending', 'partiallyPaid', 'paid', // DueStatus
          'sale', 'rent', // DueSourceType
          'active', 'returned', 'overdue', 'treatedAsStolen', // RentStatus
          'fulfilled', 'cancelled', // OrderStatus
          'voiceNote', 'photoNote', // QuickCaptureType
          'converted', // QuickCaptureStatus
          'monthlyRent', 'dailyOther', // ExpenseCategory
          'capitalReturn', 'profitShare', // RepaymentType
          'shopCashPurchase', 'convertedFromStock', // FixedAssetSource
          'settled', // LegacySettlementStatus
        ];

        for (final value in camelValues) {
          final pushed = EnumCaseBridge.toRemote('cash_ledger_entries', {
            'payment_method': value,
          });
          final pulledBack = EnumCaseBridge.toLocal(
            'cash_ledger_entries',
            pushed,
          );
          expect(
            pulledBack['payment_method'],
            value,
            reason:
                '$value should round-trip through snake_case and back unchanged',
          );
        }
      },
    );
  });
}
