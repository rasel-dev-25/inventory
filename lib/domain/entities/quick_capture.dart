import 'enums.dart';

/// A quick voice/photo note, per `notes/business_logic.md`'s QuickCapture
/// addition — "মোবাইলের নিজস্ব ভয়েস রেকর্ডার ও নোট/স্ক্রিনশট ফিচার ব্যবহার
/// করে দ্রুত একটা রেকর্ড রাখা, পরে সময় করে ফরমাল এন্ট্রি বানানোর জন্য"
/// (jot it down now with the phone's own voice/photo tools, formalize it
/// into a real Sale/PurchaseTrip/Expense later).
///
/// [fileLocalPath] is a device file path (a recorded voice clip or a
/// photo) on a real deployment — this v2 build has no native voice-
/// recorder/camera platform-channel integration yet (that's a separate,
/// platform-specific piece of work, not a Dart-only change), so the
/// capture screen currently accepts a free-text quick note into this same
/// field instead. The data model is unaffected either way: this is
/// always "a captured reference to convert later," never structured
/// data — see `QuickCaptureUseCases` for why the conversion step itself
/// is still real.
///
/// [convertedToType]/[convertedToId] are only set once
/// [QuickCaptureUseCases.markConverted] runs, after a real Sale/
/// PurchaseTrip/Expense has actually been created — never set eagerly,
/// so a capture can never claim to be converted to a record that doesn't
/// exist.
class QuickCapture {
  final String id;
  final QuickCaptureType type;
  final String fileLocalPath;
  final QuickCaptureStatus status;
  final DateTime createdAt;
  final String? convertedToType;
  final String? convertedToId;

  const QuickCapture({
    required this.id,
    required this.type,
    required this.fileLocalPath,
    required this.status,
    required this.createdAt,
    this.convertedToType,
    this.convertedToId,
  });
}
