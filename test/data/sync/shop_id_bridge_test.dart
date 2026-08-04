import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/sync/shop_id_bridge.dart';
import 'package:test/test.dart';

void main() {
  group('ShopIdBridge.toRemote', () {
    test('rewrites shop_id from the local id to the given remote id', () {
      final row = {'id': 'row-1', 'shop_id': defaultShopId, 'name': 'X'};
      final result = ShopIdBridge.toRemote(
        row,
        localKey: 'shop_id',
        remoteShopId: 'real-uuid-1',
      );

      expect(result['shop_id'], 'real-uuid-1');
      expect(result['id'], 'row-1');
      expect(result['name'], 'X');
    });

    test('leaves a row whose shop_id is not the local default untouched', () {
      final row = {'id': 'row-1', 'shop_id': 'something-else'};
      final result = ShopIdBridge.toRemote(
        row,
        localKey: 'shop_id',
        remoteShopId: 'real-uuid-1',
      );

      expect(result['shop_id'], 'something-else');
    });

    test('does not mutate the original map', () {
      final row = {'id': 'row-1', 'shop_id': defaultShopId};
      ShopIdBridge.toRemote(
        row,
        localKey: 'shop_id',
        remoteShopId: 'real-uuid-1',
      );

      expect(row['shop_id'], defaultShopId);
    });
  });

  group('ShopIdBridge.toLocal', () {
    test(
      'rewrites shop_id from the real remote id back to the local default',
      () {
        final row = {'id': 'row-1', 'shop_id': 'real-uuid-1', 'name': 'X'};
        final result = ShopIdBridge.toLocal(
          row,
          remoteKey: 'shop_id',
          remoteShopId: 'real-uuid-1',
        );

        expect(result['shop_id'], defaultShopId);
      },
    );

    test('leaves a row belonging to a different shop untouched', () {
      final row = {'id': 'row-1', 'shop_id': 'some-other-shop'};
      final result = ShopIdBridge.toLocal(
        row,
        remoteKey: 'shop_id',
        remoteShopId: 'real-uuid-1',
      );

      expect(result['shop_id'], 'some-other-shop');
    });

    test('toRemote then toLocal round-trips back to the original row', () {
      final original = {'id': 'row-1', 'shop_id': defaultShopId, 'amount': 500};
      final pushed = ShopIdBridge.toRemote(
        original,
        localKey: 'shop_id',
        remoteShopId: 'real-uuid-1',
      );
      final pulledBack = ShopIdBridge.toLocal(
        pushed,
        remoteKey: 'shop_id',
        remoteShopId: 'real-uuid-1',
      );

      expect(pulledBack, original);
    });
  });
}
