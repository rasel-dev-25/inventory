import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/money/money.dart';
import '../../../core/platform/capabilities.dart';
import '../../../core/utils/image_compressor.dart';
import '../../../data/local/app_database.dart';
import '../../../data/local/default_shop.dart';
import '../../../data/sync/storage_upload_transport.dart';
import '../../../data/usecases/fixed_asset_image_usecases.dart';
import '../../../data/usecases/fixed_asset_usecases.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/fixed_asset.dart';
import '../../../domain/entities/product.dart';

/// Backs the Fixed Asset screen — the two creation paths per
/// `notes/business_logic.md`'s "দুইভাবে যোগ করার ব্যবস্থা", via
/// [FixedAssetUseCases].
class FixedAssetController extends GetxController {
  final AppDatabase db;
  final StorageUploadTransport? imageStorage;
  static const _uuid = Uuid();

  FixedAssetController(this.db, {this.imageStorage});

  late final FixedAssetUseCases _useCases = FixedAssetUseCases(db);
  late final FixedAssetImageUseCases _imageUseCases = FixedAssetImageUseCases(
    db,
  );
  final _imagePicker = ImagePicker();

  final assets = <FixedAsset>[].obs;
  final assetImages = <FixedAssetImageRow>[].obs;
  final signedImageUrls = <String, String>{}.obs;
  final products = <Product>[].obs;

  final errorMessage = RxnString();

  final List<StreamSubscription<Object?>> _subscriptions = [];

  @override
  void onInit() {
    super.onInit();
    _subscriptions.add(
      db.fixedAssetDao
          .watchAll(defaultShopId)
          .listen((rows) => assets.assignAll(rows)),
    );
    _subscriptions.add(
      db.productDao
          .watchAll(defaultShopId)
          .listen((rows) => products.assignAll(rows)),
    );
    _subscriptions.add(
      db.fixedAssetImageDao.watchForShop(defaultShopId).listen((rows) {
        assetImages.assignAll(rows);
        _resolveRemoteImages(rows);
      }),
    );
  }

  @override
  void onClose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.onClose();
  }

  int get totalCount => assets.length;
  Money get totalValue =>
      assets.fold(Money.zeroBdt, (sum, a) => sum + a.value);

  int get directPurchaseCount => assets
      .where((a) => a.sourceType == FixedAssetSource.shopCashPurchase)
      .length;
  Money get directPurchaseValue => assets
      .where((a) => a.sourceType == FixedAssetSource.shopCashPurchase)
      .fold(Money.zeroBdt, (sum, a) => sum + a.value);

  int get convertedCount => assets
      .where((a) => a.sourceType == FixedAssetSource.convertedFromStock)
      .length;
  Money get convertedValue => assets
      .where((a) => a.sourceType == FixedAssetSource.convertedFromStock)
      .fold(Money.zeroBdt, (sum, a) => sum + a.value);

  Product? productById(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<bool> createFromCashPurchase({
    required String name,
    required Money value,
    required DateTime dateAcquired,
    String? photoLocalPath,
  }) async {
    errorMessage.value = null;
    final result = await _useCases.createFromCashPurchase(
      name: name,
      value: value,
      dateAcquired: dateAcquired,
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
    if (result.isErr) {
      errorMessage.value = result.failureOrNull!.message;
      return false;
    }
    if (photoLocalPath != null) {
      try {
        await _imageUseCases.add(
          assetId: result.valueOrNull!,
          localPath: photoLocalPath,
          now: DateTime.now().toUtc(),
        );
      } catch (error) {
        errorMessage.value = error.toString();
        return false;
      }
    }
    return true;
  }

  Future<bool> createFromStock({
    required String productId,
    required double qty,
    String? name,
    String? photoLocalPath,
  }) async {
    errorMessage.value = null;
    final result = await _useCases.createFromStock(
      productId: productId,
      qty: qty,
      name: name,
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
    if (result.isErr) {
      errorMessage.value = result.failureOrNull!.message;
      return false;
    }
    if (photoLocalPath != null) {
      try {
        await _imageUseCases.add(
          assetId: result.valueOrNull!,
          localPath: photoLocalPath,
          now: DateTime.now().toUtc(),
        );
      } catch (error) {
        errorMessage.value = error.toString();
        return false;
      }
    }
    return true;
  }

  /// See `FixedAssetUseCases.delete`'s own doc comment for the
  /// source-type-branching reversal this triggers, and for why there is
  /// no matching `restoreAsset` — deleting an asset is a one-way trip
  /// today, same as an expense.
  Future<bool> deleteAsset(String id) async {
    errorMessage.value = null;
    final imageRow = primaryImageFor(id);
    if (imageRow != null) {
      await _imageUseCases.delete(
        imageId: imageRow.id,
        storage: imageStorage,
      );
    }
    final result = await _useCases.delete(
      id: id,
      shopId: defaultShopId,
      now: DateTime.now().toUtc(),
    );
    return result.fold(
      onOk: (_) => true,
      onErr: (failure) {
        errorMessage.value = failure.message;
        return false;
      },
    );
  }

  FixedAssetImageRow? primaryImageFor(String assetId) {
    return assetImages.where((image) => image.assetId == assetId).firstOrNull;
  }

  String? imageSourceFor(FixedAssetImageRow image) {
    final localPath = image.localPath;
    if (localPath != null && File(localPath).existsSync()) return localPath;
    return signedImageUrls[image.id];
  }

  Future<String?> captureFixedAssetPhoto() async {
    errorMessage.value = null;
    try {
      XFile? selected;
      final capabilities = PlatformCapabilities.detect();
      if (capabilities.hasCamera) {
        selected = await _imagePicker.pickImage(
          source: ImageSource.camera,
          maxWidth: AppImageCompressor.defaultMaxDimension.toDouble(),
          maxHeight: AppImageCompressor.defaultMaxDimension.toDouble(),
          imageQuality: AppImageCompressor.defaultQuality,
        );
      } else if (capabilities.hasFileSystemAccess) {
        selected = await openFile(
          acceptedTypeGroups: const [
            XTypeGroup(
              label: 'Images',
              extensions: ['jpg', 'jpeg', 'png', 'webp'],
            ),
          ],
        );
      }
      if (selected == null) return null;

      final sourceFile = File(selected.path);
      if (await sourceFile.length() > 10 * 1024 * 1024) {
        errorMessage.value = 'photoTooLarge'.tr;
        return null;
      }

      final documents = await getApplicationDocumentsDirectory();
      final directory = Directory(
        path.join(documents.path, 'fixed_asset_images'),
      );
      await directory.create(recursive: true);
      final extension = path.extension(selected.path).toLowerCase();
      final destination = path.join(
        directory.path,
        '${_uuid.v7()}${extension.isEmpty ? '.jpg' : extension}',
      );
      await AppImageCompressor.compressAndSave(
        sourceFile: sourceFile,
        destinationPath: destination,
      );
      return destination;
    } catch (error) {
      errorMessage.value = error.toString();
      return null;
    }
  }

  Future<void> _resolveRemoteImages(List<FixedAssetImageRow> rows) async {
    final storage = imageStorage;
    if (storage == null) return;
    for (final image in rows) {
      if (image.remoteUrl == null || signedImageUrls.containsKey(image.id)) {
        continue;
      }
      final result = await storage.createSignedUrl(
        bucketName: FixedAssetImageUseCases.bucketName,
        storagePath: image.remoteUrl!,
      );
      result.fold(
        onOk: (url) => signedImageUrls[image.id] = url,
        onErr: (_) {},
      );
    }
  }
}
