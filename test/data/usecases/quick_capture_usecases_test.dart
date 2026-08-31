import 'package:drift/native.dart';
import 'package:inventory/core/error/failure.dart';
import 'package:inventory/data/local/app_database.dart';
import 'package:inventory/data/local/default_shop.dart';
import 'package:inventory/data/sync/outbox_event.dart';
import 'package:inventory/data/usecases/quick_capture_usecases.dart';
import 'package:inventory/domain/entities/enums.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late QuickCaptureUseCases useCases;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    useCases = QuickCaptureUseCases(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('create', () {
    test(
      'writes a pending capture and enqueues a matching outbox event',
      () async {
        final result = await useCases.create(
          type: QuickCaptureType.voiceNote,
          note: 'Sold 2 books to the guy from the mosque, forgot to log it',
          shopId: defaultShopId,
          now: DateTime.now().toUtc(),
        );

        expect(result.isOk, isTrue, reason: result.failureOrNull?.toString());

        final captures = await (db.select(db.quickCaptures)).get();
        expect(captures, hasLength(1));
        expect(captures.single.status, QuickCaptureStatus.pending);
        expect(captures.single.type, QuickCaptureType.voiceNote);
        expect(captures.single.convertedToId, isNull);

        final pending = await db.syncMetadataDao.pendingEntries();
        final entry = pending.firstWhere(
          (e) => e.eventType == 'quick_capture_created',
        );
        final upserts = OutboxEvent.decodePayload(entry.payloadJson);
        expect(upserts.single.table, 'quick_captures');
      },
    );

    test('rejects an empty note', () async {
      final result = await useCases.create(
        type: QuickCaptureType.photoNote,
        note: '   ',
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(await (db.select(db.quickCaptures)).get(), isEmpty);
    });

    test('accepts a photo path without requiring a text note', () async {
      final result = await useCases.create(
        type: QuickCaptureType.photoNote,
        note: '',
        fileLocalPath: 'quick_captures/photo.jpg',
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      expect(result.isOk, isTrue, reason: result.failureOrNull?.toString());
      final capture = (await (db.select(db.quickCaptures)).get()).single;
      expect(capture.fileLocalPath, 'quick_captures/photo.jpg');
    });

    test('accepts both a photo path and a quick note together', () async {
      final result = await useCases.create(
        type: QuickCaptureType.photoNote,
        note: 'Bought 5 boxes of pens',
        fileLocalPath: 'quick_captures/photo.jpg',
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      expect(result.isOk, isTrue, reason: result.failureOrNull?.toString());
      final domainCapture = (await db.quickCaptureDao.watchAll(defaultShopId).first).single;
      expect(domainCapture.photoPath, 'quick_captures/photo.jpg');
      expect(domainCapture.note, 'Bought 5 boxes of pens');
    });
  });

  group('markConverted', () {
    test('links the capture to the converted record', () async {
      await useCases.create(
        type: QuickCaptureType.voiceNote,
        note: 'A quick note',
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );
      final captureId = (await (db.select(db.quickCaptures)).get()).single.id;

      final result = await useCases.markConverted(
        captureId: captureId,
        convertedToType: 'expense',
        convertedToId: 'expense-123',
        shopId: defaultShopId,
      );

      expect(result.isOk, isTrue, reason: result.failureOrNull?.toString());
      final capture = await db.quickCaptureDao.getById(captureId);
      expect(capture!.status, QuickCaptureStatus.converted);
      expect(capture.convertedToType, 'expense');
      expect(capture.convertedToId, 'expense-123');

      final pending = await db.syncMetadataDao.pendingEntries();
      final entry = pending.firstWhere(
        (e) => e.eventType == 'quick_capture_converted',
      );
      final upserts = OutboxEvent.decodePayload(entry.payloadJson);
      expect(upserts.single.table, 'quick_captures');
    });

    test('rejects converting the same capture twice', () async {
      await useCases.create(
        type: QuickCaptureType.voiceNote,
        note: 'A quick note',
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );
      final captureId = (await (db.select(db.quickCaptures)).get()).single.id;

      final first = await useCases.markConverted(
        captureId: captureId,
        convertedToType: 'expense',
        convertedToId: 'expense-123',
        shopId: defaultShopId,
      );
      expect(first.isOk, isTrue);

      final second = await useCases.markConverted(
        captureId: captureId,
        convertedToType: 'sale',
        convertedToId: 'sale-456',
        shopId: defaultShopId,
      );

      expect(second.isErr, isTrue);
      expect(second.failureOrNull, isA<BusinessRuleFailure>());
    });

    test('rejects converting a nonexistent capture', () async {
      final result = await useCases.markConverted(
        captureId: 'does-not-exist',
        convertedToType: 'expense',
        convertedToId: 'expense-123',
        shopId: defaultShopId,
      );

      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<NotFoundFailure>());
    });
  });

  group('update', () {
    test('updates note text and enqueues outbox event', () async {
      await useCases.create(
        type: QuickCaptureType.photoNote,
        note: 'Original note',
        fileLocalPath: 'photos/pic1.jpg',
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );
      final captureId = (await (db.select(db.quickCaptures)).get()).single.id;

      final result = await useCases.update(
        id: captureId,
        note: 'Updated note text',
        fileLocalPath: 'photos/pic2.jpg',
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      expect(result.isOk, isTrue);
      final updated = await db.quickCaptureDao.getById(captureId);
      expect(updated!.note, 'Updated note text');
      expect(updated.photoPath, 'photos/pic2.jpg');

      final pending = await db.syncMetadataDao.pendingEntries();
      final entry = pending.firstWhere(
        (e) => e.eventType == 'quick_capture_updated',
      );
      final upserts = OutboxEvent.decodePayload(entry.payloadJson);
      expect(upserts.single.table, 'quick_captures');
    });

    test('rejects updating nonexistent capture', () async {
      final result = await useCases.update(
        id: 'missing-id',
        note: 'Some note',
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<NotFoundFailure>());
    });
  });

  group('delete', () {
    test('deletes capture from local database', () async {
      await useCases.create(
        type: QuickCaptureType.voiceNote,
        note: 'To delete',
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );
      final captureId = (await (db.select(db.quickCaptures)).get()).single.id;

      final result = await useCases.delete(
        id: captureId,
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      expect(result.isOk, isTrue);
      expect(await db.quickCaptureDao.getById(captureId), isNull);
    });

    test('rejects deleting nonexistent capture', () async {
      final result = await useCases.delete(
        id: 'missing-id',
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );

      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<NotFoundFailure>());
    });
  });
}
