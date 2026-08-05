import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/local/app_database.dart';
import '../../../data/local/backup_service.dart';

/// Drives [BackupService.buildBackupPayload]/[BackupService.restoreFromBackup]
/// from the drawer's "Backup Data"/"Restore Data" actions, handling the
/// file I/O and file-picking [BackupService] itself deliberately stays
/// free of (it's data-layer, and layer-boundary rules forbid
/// `lib/data/**` importing Flutter — see `tool/check_layer_boundaries.sh`).
///
/// Filenames are prefixed `backup_v2_` — a naming leftover from before
/// this was the app's only backup format (the v1 app this was rewritten
/// from had its own, incompatible `backup_*.json` export, since deleted
/// along with the rest of v1). Left as-is rather than renamed: an
/// existing backup file on a real device already carries this prefix,
/// and [listBackupFiles] just needs to keep matching whatever prefix new
/// backups are actually written with.
///
/// Uses `Get.snackbar`/`Get.dialog` rather than this file's own
/// `BuildContext`, unlike every other v2 controller's inline
/// `errorMessage` convention — deliberately, since this is invoked from
/// the drawer, which closes (and can invalidate its own context) the
/// instant an item is tapped, before any feedback about a *result* that
/// only exists after an async operation completes.
class BackupController extends GetxController {
  final AppDatabase db;
  static const _filePrefix = 'backup_v2_';

  BackupController(this.db);

  late final BackupService _backupService = BackupService(db);

  final isBusy = false.obs;
  final errorMessage = RxnString();

  Future<void> exportAndShare() async {
    isBusy.value = true;
    errorMessage.value = null;
    try {
      final payload = await _backupService.buildBackupPayload();
      final jsonStr = const JsonEncoder.withIndent('  ').convert(payload);

      final dir = await getApplicationDocumentsDirectory();
      final fileName =
          '$_filePrefix${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(jsonStr);

      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'backupCopiedV2'.tr),
      );

      Get.snackbar(
        '',
        'backupCopiedV2'.tr,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        '',
        '${'backupFailedV2'.tr}$e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<List<File>> listBackupFiles() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir
        .listSync()
        .whereType<File>()
        .where(
          (f) =>
              f.path
                  .split(Platform.pathSeparator)
                  .last
                  .startsWith(_filePrefix) &&
              f.path.endsWith('.json'),
        )
        .toList();
  }

  /// Reads and restores [file] — the caller (the drawer's onTap handler)
  /// is responsible for picking [file] and confirming with the owner
  /// first, since both of those genuinely need a `BuildContext`/dialog,
  /// unlike this method.
  Future<bool> restoreFrom(File file) async {
    isBusy.value = true;
    errorMessage.value = null;
    try {
      final jsonStr = await file.readAsString();
      final payload = jsonDecode(jsonStr) as Map<String, dynamic>;
      final result = await _backupService.restoreFromBackup(payload);
      return result.fold(
        onOk: (_) {
          Get.snackbar(
            '',
            'restoreSucceededV2'.tr,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 4),
          );
          return true;
        },
        onErr: (failure) {
          errorMessage.value = failure.message;
          Get.snackbar(
            '',
            '${'restoreFailedV2'.tr}${failure.message}',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 4),
          );
          return false;
        },
      );
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        '',
        '${'restoreFailedV2'.tr}$e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
      return false;
    } finally {
      isBusy.value = false;
    }
  }
}
