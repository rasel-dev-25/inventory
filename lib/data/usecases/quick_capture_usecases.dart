import 'package:uuid/uuid.dart';

import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/quick_capture.dart';
import '../local/app_database.dart';
import '../sync/outbox_event.dart';
import 'sync_enqueue_helper.dart';

/// Create + convert for [QuickCapture], per `notes/business_logic.md`'s
/// QuickCapture addition. [markConverted] is the "later, when you have
/// time" half of the flow — see the class doc comment on
/// `QuickCaptureController` for how a real Sale/PurchaseTrip/Expense gets
/// created first (via the same use cases the dedicated v2 screens use),
/// with this call only ever running *after* that succeeds.
class QuickCaptureUseCases {
  final AppDatabase db;
  static const _uuid = Uuid();

  QuickCaptureUseCases(this.db);

  Future<Result<void>> create({
    required QuickCaptureType type,
    required String note,
    required String shopId,
    required DateTime now,
    String? fileLocalPath,
  }) async {
    final capturedPath = fileLocalPath?.trim();
    if (note.trim().isEmpty && (capturedPath == null || capturedPath.isEmpty)) {
      return const Result.err(
        ValidationFailure('note', 'Write or attach something to capture'),
      );
    }

    final capture = QuickCapture(
      id: _uuid.v7(),
      type: type,
      fileLocalPath: capturedPath?.isNotEmpty == true
          ? capturedPath!
          : note.trim(),
      status: QuickCaptureStatus.pending,
      createdAt: now,
    );

    await writeAndEnqueue(
      db: db,
      eventType: 'quick_capture_created',
      upserts: [
        TableUpsert(
          table: 'quick_captures',
          row: {
            'id': capture.id,
            'shop_id': shopId,
            'type': capture.type.name,
            'file_local_path': capture.fileLocalPath,
            'status': capture.status.name,
          },
        ),
      ],
      localWrite: () =>
          db.quickCaptureDao.create(capture, shopId: shopId, now: now),
    );

    return const Result.ok(null);
  }

  /// Marks [captureId] as converted to the record at ([convertedToType],
  /// [convertedToId]) — that record must already exist; this method
  /// never creates one itself. Rejects converting a capture twice, so a
  /// double-tap in the UI can never point one capture at two different
  /// records.
  Future<Result<void>> markConverted({
    required String captureId,
    required String convertedToType,
    required String convertedToId,
    required String shopId,
  }) async {
    final capture = await db.quickCaptureDao.getById(captureId);
    if (capture == null) {
      return Result.err(NotFoundFailure('quickCapture', captureId));
    }
    if (capture.status == QuickCaptureStatus.converted) {
      return const Result.err(
        BusinessRuleFailure('This capture has already been converted'),
      );
    }

    await writeAndEnqueue(
      db: db,
      eventType: 'quick_capture_converted',
      upserts: [
        TableUpsert(
          table: 'quick_captures',
          row: {
            'id': captureId,
            'shop_id': shopId,
            'status': QuickCaptureStatus.converted.name,
            'converted_to_type': convertedToType,
            'converted_to_id': convertedToId,
          },
        ),
      ],
      localWrite: () => db.quickCaptureDao.markConverted(
        id: captureId,
        convertedToType: convertedToType,
        convertedToId: convertedToId,
      ),
    );

    return const Result.ok(null);
  }
}
