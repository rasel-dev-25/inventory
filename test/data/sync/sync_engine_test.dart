import 'package:drift/native.dart';
import 'package:inventory/core/error/failure.dart';
import 'package:inventory/core/error/result.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/local/local_row_upserter.dart';
import 'package:inventory/data/sync/outbox_event.dart';
import 'package:inventory/data/sync/sync_pull_service.dart';
import 'package:inventory/data/sync/sync_push_service.dart';
import 'package:inventory/data/sync/sync_transport.dart';
import 'package:test/test.dart';

const _remoteShopId = 'real-backend-shop-1';

/// A hand-written fake, same reasoning as `_FakeAuthRepository` in the
/// auth tests: the interesting behaviour here is entirely in what gets
/// recorded/returned across calls, not in stubbing a fixed return value,
/// so a small fake this test controls directly is more honest than a
/// mocking framework for this shape.
class _FakeSyncTransport implements SyncTransport {
  final List<({String idempotencyKey, List<TableUpsert> upserts})>
  pushedEvents = [];
  Result<void> nextPushResult = const Result.ok(null);

  final Map<String, List<RemotePage>> pagesByTable = {};

  @override
  Future<Result<void>> pushEvent({
    required String idempotencyKey,
    required List<TableUpsert> upserts,
  }) async {
    pushedEvents.add((idempotencyKey: idempotencyKey, upserts: upserts));
    return nextPushResult;
  }

  @override
  Future<Result<RemotePage>> fetchSince({
    required String table,
    required String shopId,
    required DateTime? afterSyncedAt,
    required String? afterId,
    int limit = 200,
  }) async {
    final queue = pagesByTable[table];
    if (queue == null || queue.isEmpty) {
      return const Result.ok(RemotePage(rows: []));
    }
    return Result.ok(queue.removeAt(0));
  }
}

void main() {
  late AppDatabaseV2 db;
  late _FakeSyncTransport transport;

  setUp(() {
    db = AppDatabaseV2.forTesting(NativeDatabase.memory());
    transport = _FakeSyncTransport();
  });

  tearDown(() async {
    await db.close();
  });

  group('SyncPushService', () {
    test(
      'a successful push substitutes the real shop id, then marks the entry done',
      () async {
        await db.syncMetadataDao.enqueue(
          id: 'outbox-1',
          eventType: 'category_created',
          idempotencyKey: 'evt-1',
          payloadJson: OutboxEvent(
            idempotencyKey: 'evt-1',
            upserts: const [
              TableUpsert(
                table: 'categories',
                row: {
                  'id': 'cat-1',
                  'shop_id': defaultShopId,
                  'name': 'Test',
                  'sort_order': 0,
                },
              ),
            ],
          ).encodePayload(),
          now: DateTime.now().toUtc(),
        );

        final service = SyncPushService(db.syncMetadataDao, transport);
        final summary = await service.pushPending(remoteShopId: _remoteShopId);

        expect(summary.succeeded, 1);
        expect(summary.failed, 0);
        expect(transport.pushedEvents, hasLength(1));
        expect(transport.pushedEvents.single.idempotencyKey, 'evt-1');
        expect(
          transport.pushedEvents.single.upserts.single.row['shop_id'],
          _remoteShopId,
        );
        expect(await db.syncMetadataDao.pendingEntries(), isEmpty);
      },
    );

    test('converts enum columns to snake_case before pushing', () async {
      await db.syncMetadataDao.enqueue(
        id: 'outbox-2',
        eventType: 'ledger_entry_created',
        idempotencyKey: 'evt-2',
        payloadJson: OutboxEvent(
          idempotencyKey: 'evt-2',
          upserts: const [
            TableUpsert(
              table: 'cash_ledger_entries',
              row: {
                'id': 'led-1',
                'shop_id': defaultShopId,
                'amount_minor': 500,
                'payment_method': 'mobileBanking',
                'source_type': 'sale',
                'source_id': 'led-1',
                'date': '2026-01-01T00:00:00.000Z',
              },
            ),
          ],
        ).encodePayload(),
        now: DateTime.now().toUtc(),
      );

      final service = SyncPushService(db.syncMetadataDao, transport);
      await service.pushPending(remoteShopId: _remoteShopId);

      expect(
        transport.pushedEvents.single.upserts.single.row['payment_method'],
        'mobile_banking',
      );
    });

    test(
      'a failing push increments the attempt count and keeps the entry retryable',
      () async {
        transport.nextPushResult = const Result.err(
          UnknownFailure('network blip'),
        );
        await db.syncMetadataDao.enqueue(
          id: 'outbox-3',
          eventType: 'x',
          idempotencyKey: 'evt-3',
          payloadJson: const OutboxEvent(
            idempotencyKey: 'evt-3',
            upserts: [],
          ).encodePayload(),
          now: DateTime.now().toUtc(),
        );

        final service = SyncPushService(db.syncMetadataDao, transport);
        final summary = await service.pushPending(remoteShopId: _remoteShopId);

        expect(summary.failed, 1);
        final pending = await db.syncMetadataDao.pendingEntries();
        expect(pending, hasLength(1));
        expect(pending.single.status, 'failed');
        expect(pending.single.attemptCount, 1);
        // UnknownFailure.message wraps the cause (see core/error/failure.dart).
        expect(pending.single.lastError, contains('network blip'));
      },
    );

    test('processes multiple pending entries in one call', () async {
      for (final n in [1, 2, 3]) {
        await db.syncMetadataDao.enqueue(
          id: 'outbox-multi-$n',
          eventType: 'x',
          idempotencyKey: 'evt-multi-$n',
          payloadJson: const OutboxEvent(
            idempotencyKey: 'evt',
            upserts: [],
          ).encodePayload(),
          now: DateTime.now().toUtc(),
        );
      }

      final service = SyncPushService(db.syncMetadataDao, transport);
      final summary = await service.pushPending(remoteShopId: _remoteShopId);

      expect(summary.succeeded, 3);
      expect(transport.pushedEvents, hasLength(3));
    });
  });

  group('SyncPullService', () {
    test(
      'pulls a mutable-table row and applies it locally with shop_id rewritten',
      () async {
        transport.pagesByTable['categories'] = [
          const RemotePage(
            rows: [
              {
                'id': 'cat-remote-1',
                'shop_id': _remoteShopId,
                'name': 'Remote Cat',
                'sort_order': 5,
                'synced_at': '2026-01-01T00:00:00.000Z',
              },
            ],
          ),
        ];
        final service = SyncPullService(
          db.syncMetadataDao,
          transport,
          LocalRowUpserter(db),
        );

        final result = await service.pullTable(
          'categories',
          remoteShopId: _remoteShopId,
        );

        expect(result.isOk, isTrue);
        expect(result.valueOrNull, 1);

        final row = await (db.select(
          db.categories,
        )..where((c) => c.id.equals('cat-remote-1'))).getSingle();
        expect(row.shopId, defaultShopId);
        expect(row.name, 'Remote Cat');
        expect(row.sortOrder, 5);

        final cursor = await db.syncMetadataDao.cursorFor('categories');
        expect(cursor?.lastSyncedId, 'cat-remote-1');
      },
    );

    test(
      'LocalRowUpserter silently drops remote-only columns the local table does not have',
      () async {
        // Remote categories has created_at/updated_at/synced_at; local
        // Categories does not track any of the three (see
        // local_row_upserter.dart's doc comment). Passing all three
        // through anyway must not throw "no such column".
        final upserter = LocalRowUpserter(db);

        await upserter.upsert('categories', {
          'id': 'cat-extra-cols',
          'shop_id': defaultShopId,
          'name': 'Has Extra Remote Columns',
          'sort_order': 1,
          'created_at': '2026-01-01T00:00:00.000Z',
          'updated_at': '2026-01-01T00:00:00.000Z',
          'synced_at': '2026-01-01T00:00:00.000Z',
        });

        final row = await (db.select(
          db.categories,
        )..where((c) => c.id.equals('cat-extra-cols'))).getSingle();
        expect(row.name, 'Has Extra Remote Columns');
      },
    );

    test('converts enum columns back to camelCase when pulling', () async {
      transport.pagesByTable['cash_ledger_entries'] = [
        const RemotePage(
          rows: [
            {
              'id': 'led-remote-1',
              'shop_id': _remoteShopId,
              'amount_minor': 1200,
              'payment_method': 'bank_transfer',
              'source_type': 'sale',
              'source_id': 'led-remote-1',
              'date': '2026-01-01T00:00:00.000Z',
              'created_at': '2026-01-01T00:00:00.000Z',
              'synced_at': '2026-01-01T00:00:00.000Z',
            },
          ],
        ),
      ];
      final service = SyncPullService(
        db.syncMetadataDao,
        transport,
        LocalRowUpserter(db),
      );

      await service.pullTable(
        'cash_ledger_entries',
        remoteShopId: _remoteShopId,
      );

      final row = await (db.select(
        db.cashLedgerEntries,
      )..where((t) => t.id.equals('led-remote-1'))).getSingle();
      // Reads back through Drift's typed EnumNameConverter — if the
      // stored string were still "bank_transfer" this would throw
      // (byName lookup failure) rather than compare unequal.
      expect(row.paymentMethod.name, 'bankTransfer');
    });

    test(
      'pulling twice does not duplicate rows and advances past an empty page',
      () async {
        transport.pagesByTable['categories'] = [
          const RemotePage(
            rows: [
              {
                'id': 'cat-remote-2',
                'shop_id': _remoteShopId,
                'name': 'Once',
                'sort_order': 0,
                'synced_at': '2026-01-01T00:00:00.000Z',
              },
            ],
          ),
        ];
        final service = SyncPullService(
          db.syncMetadataDao,
          transport,
          LocalRowUpserter(db),
        );

        await service.pullTable('categories', remoteShopId: _remoteShopId);
        // Second call: the fake's queue for this table is now empty, so
        // fetchSince returns an empty page immediately, exactly like a
        // real "nothing new since your cursor" response.
        final second = await service.pullTable(
          'categories',
          remoteShopId: _remoteShopId,
        );

        expect(second.valueOrNull, 0);
        final rows = await (db.select(
          db.categories,
        )..where((c) => c.id.equals('cat-remote-2'))).get();
        expect(rows, hasLength(1));
      },
    );

    test(
      'append-only table pull does not overwrite an already-applied row',
      () async {
        const remoteRow = {
          'id': 'led-appendonly-1',
          'shop_id': _remoteShopId,
          'amount_minor': 5,
          'payment_method': 'cash',
          'source_type': 'sale',
          'source_id': 'led-appendonly-1',
          'date': '2026-01-01T00:00:00.000Z',
          'created_at': '2026-01-01T00:00:00.000Z',
          'synced_at': '2026-01-01T00:00:00.000Z',
        };
        transport.pagesByTable['cash_ledger_entries'] = [
          const RemotePage(rows: [remoteRow]),
        ];
        final upserter = LocalRowUpserter(db);

        // Simulates the row already having landed locally by some other
        // path (e.g. this exact device pushed it originally) with a
        // different amount_minor than what the fake "remote" page above
        // says.
        await upserter.upsert('cash_ledger_entries', {
          ...remoteRow,
          'shop_id': defaultShopId,
          'amount_minor': 999999,
        });

        final service = SyncPullService(
          db.syncMetadataDao,
          transport,
          upserter,
        );
        await service.pullTable(
          'cash_ledger_entries',
          remoteShopId: _remoteShopId,
        );

        final row = await (db.select(
          db.cashLedgerEntries,
        )..where((t) => t.id.equals('led-appendonly-1'))).getSingle();
        // ON CONFLICT DO NOTHING: the pre-existing 999999 must survive,
        // not be overwritten by the pulled page's amount_minor of 5.
        expect(row.amountMinor, 999999);
      },
    );
  });

  group('SyncPushService + SyncPullService end-to-end', () {
    test(
      'a row pushed by this device round-trips through a pull unchanged',
      () async {
        // What the outbox pusher sends is exactly what a real
        // apply_outbox_event call would receive; feed that same payload
        // back in as if it were the next pull's remote page, simulating
        // "the server now has this row and this device pulls it back".
        await db.syncMetadataDao.enqueue(
          id: 'outbox-roundtrip',
          eventType: 'category_created',
          idempotencyKey: 'evt-roundtrip',
          payloadJson: OutboxEvent(
            idempotencyKey: 'evt-roundtrip',
            upserts: const [
              TableUpsert(
                table: 'categories',
                row: {
                  'id': 'cat-roundtrip',
                  'shop_id': defaultShopId,
                  'name': 'Round Trip',
                  'sort_order': 9,
                },
              ),
            ],
          ).encodePayload(),
          now: DateTime.now().toUtc(),
        );

        final pushService = SyncPushService(db.syncMetadataDao, transport);
        await pushService.pushPending(remoteShopId: _remoteShopId);

        final pushedRow = transport.pushedEvents.single.upserts.single.row;
        expect(pushedRow['shop_id'], _remoteShopId);

        // The real server stamps synced_at via set_created_at()
        // (0001_foundations.sql) on insert — simulate that before treating
        // this payload as "what a later SELECT would return", since the
        // pull side needs synced_at on every raw remote row to advance its
        // cursor.
        final remoteRowAfterInsert = {
          ...pushedRow,
          'synced_at': '2026-01-01T00:00:00.000Z',
        };

        // Simulate a second device (or this one, after a local wipe)
        // pulling that same row back down.
        transport.pagesByTable['categories'] = [
          RemotePage(rows: [remoteRowAfterInsert]),
        ];
        final pullService = SyncPullService(
          db.syncMetadataDao,
          transport,
          LocalRowUpserter(db),
        );
        await pullService.pullTable('categories', remoteShopId: _remoteShopId);

        final row = await (db.select(
          db.categories,
        )..where((c) => c.id.equals('cat-roundtrip'))).getSingle();
        expect(row.shopId, defaultShopId);
        expect(row.name, 'Round Trip');
      },
    );
  });

  group('LocalRowUpserter value coercion', () {
    test(
      'pulling a product coerces its date, boolean, and enum columns correctly',
      () async {
        final upserter = LocalRowUpserter(db);
        await upserter.upsert('products', {
          'id': 'prod-remote-1',
          'shop_id':
              defaultShopId, // already local-shaped for this direct-upserter test
          'name': 'Remote Product',
          'category': 'Book',
          'cost_price_minor': 1000,
          'suggested_sell_price_minor': 1500,
          'qty': 5.0,
          'fund_source_type':
              'shop', // already local-shaped (single-word enum, no case change)
          'is_rentable': true,
          'created_at': '2026-01-01T00:00:00.000Z',
          'updated_at': '2026-01-01T00:00:00.000Z',
          'synced_at': '2026-01-01T00:00:00.000Z',
        });

        final row = await (db.select(
          db.products,
        )..where((p) => p.id.equals('prod-remote-1'))).getSingle();

        // Reading these back through Drift's typed accessors is the
        // real assertion: a wrong storage format would throw while
        // decoding, not merely compare unequal (as happened before this
        // fix — int.parse on the raw ISO-8601 string).
        expect(row.isRentable, isTrue);
        // Drift's epoch-int storage round-trips the correct *instant*,
        // but reads it back as a local-zone DateTime object (see
        // SqlTypes._readDateTime), not necessarily a UTC one — compare
        // the instant, not the zone representation.
        expect(
          row.createdAt.isAtSameMomentAs(DateTime.utc(2026, 1, 1)),
          isTrue,
        );
        expect(
          row.updatedAt.isAtSameMomentAs(DateTime.utc(2026, 1, 1)),
          isTrue,
        );
      },
    );

    test('a false boolean coerces to 0, not left as a Dart bool', () async {
      final upserter = LocalRowUpserter(db);
      await upserter.upsert('products', {
        'id': 'prod-remote-2',
        'shop_id': defaultShopId,
        'name': 'Not Rentable',
        'category': 'Book',
        'cost_price_minor': 100,
        'suggested_sell_price_minor': 150,
        'qty': 1.0,
        'fund_source_type': 'shop',
        'is_rentable': false,
        'created_at': '2026-01-01T00:00:00.000Z',
        'updated_at': '2026-01-01T00:00:00.000Z',
        'synced_at': '2026-01-01T00:00:00.000Z',
      });

      final row = await (db.select(
        db.products,
      )..where((p) => p.id.equals('prod-remote-2'))).getSingle();
      expect(row.isRentable, isFalse);
    });
  });
}
