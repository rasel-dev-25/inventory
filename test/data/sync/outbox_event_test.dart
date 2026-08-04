import 'package:inventory/data/sync/outbox_event.dart';
import 'package:test/test.dart';

void main() {
  group('OutboxEvent payload encoding', () {
    test('encodePayload then decodePayload round-trips a batch of upserts', () {
      final upserts = [
        const TableUpsert(
          table: 'purchase_trips',
          row: {
            'id': 'trip-1',
            'shop_id': 'shop-default',
            'transport_cost_minor': 500,
          },
        ),
        const TableUpsert(
          table: 'purchase_items',
          row: {
            'id': 'item-1',
            'trip_id': 'trip-1',
            'qty': 3,
            'is_in_kind': false,
          },
        ),
      ];
      final event = OutboxEvent(idempotencyKey: 'evt-1', upserts: upserts);

      final decoded = OutboxEvent.decodePayload(event.encodePayload());

      expect(decoded, hasLength(2));
      expect(decoded[0].table, 'purchase_trips');
      expect(decoded[0].row['id'], 'trip-1');
      expect(decoded[0].row['transport_cost_minor'], 500);
      expect(decoded[1].table, 'purchase_items');
      expect(decoded[1].row['is_in_kind'], false);
    });

    test('round-trips a null value inside a row correctly', () {
      const upsert = TableUpsert(
        table: 'products',
        row: {'id': 'p1', 'barcode': null},
      );
      final event = OutboxEvent(idempotencyKey: 'evt-2', upserts: [upsert]);

      final decoded = OutboxEvent.decodePayload(event.encodePayload());

      expect(decoded.single.row['barcode'], isNull);
      expect(decoded.single.row.containsKey('barcode'), isTrue);
    });

    test('an empty upsert list round-trips to an empty list', () {
      final event = OutboxEvent(idempotencyKey: 'evt-3', upserts: const []);
      final decoded = OutboxEvent.decodePayload(event.encodePayload());
      expect(decoded, isEmpty);
    });
  });
}
