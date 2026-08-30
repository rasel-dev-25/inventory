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
import '../../../data/sync/outbox_event.dart';
import '../../../data/sync/storage_upload_transport.dart';
import '../../../data/usecases/category_usecases.dart';
import '../../../data/usecases/product_image_usecases.dart';
import '../../../data/usecases/product_usecases.dart';
import '../../../data/usecases/sync_enqueue_helper.dart';
import '../../../domain/entities/fund_source.dart';
import '../../../domain/entities/investor.dart';
import '../../../domain/entities/product.dart';
import '../../pricing_settings_v2/controller/pricing_settings_controller.dart';

/// Backs the new v2 categories/products screens
/// (`lib/features/catalog/view/`). Reads live from [AppDatabase] via
/// `CategoryDao`/`ProductDao`'s `watch*` streams, and writes through
/// `CategoryUseCases`/`ProductUseCases` so every create/rename/reorder
/// also enqueues its outbox event — see `SYNC.md`.
///
/// Deliberately a single controller for both categories and products,
/// not two: the products screen needs the live category list for its
/// picker regardless, and there is no independent categories screen a
/// user reaches without also caring about products.
class CatalogController extends GetxController {
  final AppDatabase db;

  /// The pricing-engine controller — a permanent, app-wide singleton (see
  /// its own doc comment), injected here rather than looked up ad hoc so
  /// [overheadMarkupPercent] stays plain constructor-injected state like
  /// every other v2 controller dependency.
  final PricingSettingsController pricingSettings;
  final StorageUploadTransport? imageStorage;

  static const _uuid = Uuid();

  CatalogController(this.db, this.pricingSettings, {this.imageStorage});

  late final CategoryUseCases _categoryUseCases = CategoryUseCases(db);
  late final ProductUseCases _productUseCases = ProductUseCases(db);
  late final ProductImageUseCases _productImageUseCases = ProductImageUseCases(
    db,
  );
  final _imagePicker = ImagePicker();

  /// Null exactly when `ProductFormSheet`'s cost-price suggestion should
  /// stay hidden (the pricing engine's bootstrap period, or no usable
  /// revenue estimate yet) — see `computeOverheadMarkupPercent`'s doc
  /// comment for the exact conditions.
  double? get overheadMarkupPercent => pricingSettings.overheadMarkupPercent;

  final categories = <CategoryRow>[].obs;
  final products = <Product>[].obs;
  final productImages = <ProductImageRow>[].obs;
  final signedImageUrls = <String, String>{}.obs;
  final investors = <Investor>[].obs;
  final errorMessage = RxnString();

  final List<StreamSubscription<Object?>> _subscriptions = [];

  @override
  void onInit() {
    super.onInit();
    // Cancelled in onClose(); an uncancelled watch() subscription is a
    // leak in production and, worse, can deadlock a test's
    // `db.close()` call while the subscription is still trying to query
    // a database that's mid-shutdown — caught by a real test hang, not
    // by inspection.
    _subscriptions.add(
      db.categoryDao
          .watchAll(defaultShopId)
          .listen((rows) => categories.assignAll(rows)),
    );
    _subscriptions.add(
      db.productDao
          .watchAll(defaultShopId)
          .listen((rows) => products.assignAll(rows)),
    );
    _subscriptions.add(
      db.productImageDao.watchForShop(defaultShopId).listen((rows) {
        productImages.assignAll(rows);
        _resolveRemoteImages(rows);
      }),
    );
    _subscriptions.add(
      db.investorDao
          .watchAll(defaultShopId)
          .listen((rows) => investors.assignAll(rows)),
    );
  }

  @override
  void onClose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.onClose();
  }

  Future<bool> createCategory(String name) async {
    if (name.trim().isEmpty) {
      errorMessage.value = 'nameRequired'.tr;
      return false;
    }
    try {
      final nextSortOrder = categories.isEmpty
          ? 0
          : categories.map((c) => c.sortOrder).reduce((a, b) => a > b ? a : b) +
                1;
      await _categoryUseCases.create(
        id: _uuid.v7(),
        shopId: defaultShopId,
        name: name.trim(),
        sortOrder: nextSortOrder,
      );
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    }
  }

  Future<bool> renameCategory(String id, String name) async {
    if (name.trim().isEmpty) return false;
    try {
      await _categoryUseCases.rename(
        id: id,
        shopId: defaultShopId,
        name: name.trim(),
      );
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    }
  }

  Future<bool> moveCategory(CategoryRow category, {required bool up}) async {
    final sorted = [...categories]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final index = sorted.indexWhere((c) => c.id == category.id);
    final swapIndex = up ? index - 1 : index + 1;
    if (index < 0 || swapIndex < 0 || swapIndex >= sorted.length) return false;

    final other = sorted[swapIndex];
    try {
      await _categoryUseCases.reorder(
        id: category.id,
        shopId: defaultShopId,
        sortOrder: other.sortOrder,
      );
      await _categoryUseCases.reorder(
        id: other.id,
        shopId: defaultShopId,
        sortOrder: category.sortOrder,
      );
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    }
  }

  Future<bool> createProduct({
    required String name,
    required String category,
    required Money costPrice,
    required Money suggestedSellPrice,
    required FundSource fundSource,
    bool isRentable = false,
    double initialQty = 0,
    String? barcode,
    String? sku,
    int? pageCount,
    String? photoLocalPath,
  }) async {
    try {
      final product = Product(
        id: _uuid.v7(),
        name: name.trim(),
        category: category,
        costPrice: costPrice,
        suggestedSellPrice: suggestedSellPrice,
        qty: initialQty,
        fundSource: fundSource,
        isRentable: isRentable,
        barcode: barcode,
        sku: sku,
        pageCount: pageCount,
      );
      final now = DateTime.now().toUtc();
      await db.transaction(() async {
        await _productUseCases.create(product, shopId: defaultShopId, now: now);
        if (initialQty > 0) {
          final movementId = _uuid.v7();
          await writeAndEnqueue(
            db: db,
            eventType: 'stock_movement_created',
            upserts: [
              TableUpsert(
                table: 'stock_movements',
                row: {
                  'id': movementId,
                  'shop_id': defaultShopId,
                  'product_id': product.id,
                  'delta_qty': initialQty,
                  'source_type': 'opening_stock',
                  'source_id': product.id,
                  'date': now.toIso8601String(),
                },
              ),
            ],
            localWrite: () => db.ledgerDao.recordStockMovement(
              id: movementId,
              shopId: defaultShopId,
              productId: product.id,
              deltaQty: initialQty,
              sourceType: 'opening_stock',
              sourceId: product.id,
              date: now,
              now: now,
            ),
          );
        }
        if (photoLocalPath != null) {
          await _productImageUseCases.add(
            productId: product.id,
            localPath: photoLocalPath,
            now: now,
          );
        }
      });
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    }
  }

  /// [existing] must be the product as currently stored (from
  /// [products]) — every field this doesn't explicitly change is carried
  /// over unchanged, including `qty`, which this screen never edits
  /// directly (see `ProductUseCases`' class doc comment).
  Future<bool> updateProduct(
    Product existing, {
    String? name,
    String? category,
    Money? costPrice,
    Money? suggestedSellPrice,
    double? qty,
    FundSource? fundSource,
    bool? isRentable,
    String? barcode,
    String? sku,
    int? pageCount,
    String? photoLocalPath,
  }) async {
    try {
      final updated = existing.copyWith(
        name: name,
        category: category,
        costPrice: costPrice,
        suggestedSellPrice: suggestedSellPrice,
        qty: qty,
        fundSource: fundSource,
        isRentable: isRentable,
        barcode: barcode,
        sku: sku,
        pageCount: pageCount,
      );
      final now = DateTime.now().toUtc();
      await db.transaction(() async {
        await _productUseCases.update(updated, shopId: defaultShopId, now: now);

        if (qty != null && qty != existing.qty) {
          final delta = qty - existing.qty;
          final movementId = 'sm-${const Uuid().v4()}';
          final movementRow = {
            'id': movementId,
            'shop_id': defaultShopId,
            'product_id': existing.id,
            'delta_qty': delta,
            'source_type': 'adjustment',
            'source_id': movementId,
            'date': now.toIso8601String(),
          };
          await writeAndEnqueue(
            db: db,
            eventType: 'stock_movement_created',
            upserts: [
              TableUpsert(table: 'stock_movements', row: movementRow),
            ],
            localWrite: () => db.ledgerDao.recordStockMovement(
              id: movementId,
              shopId: defaultShopId,
              productId: existing.id,
              deltaQty: delta,
              sourceType: 'adjustment',
              sourceId: movementId,
              date: now,
              now: now,
            ),
          );
        }

        if (photoLocalPath != null &&
            !productImages.any(
              (image) =>
                  image.productId == existing.id &&
                  image.localPath == photoLocalPath,
            )) {
          await _productImageUseCases.add(
            productId: existing.id,
            localPath: photoLocalPath,
            now: now,
          );
        }
      });
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    }
  }

  /// Soft-deletes — see `ProductUseCases.softDelete`'s own doc comment
  /// for why this is safe to offer with no extra confirmation logic here
  /// (the screen itself still confirms with the owner before calling
  /// this, same as `CustomersController.deleteCustomer`'s call site).
  Future<bool> deleteProduct(String id) async {
    errorMessage.value = null;
    try {
      await _productUseCases.softDelete(
        id,
        shopId: defaultShopId,
        now: DateTime.now().toUtc(),
      );
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    }
  }

  ProductImageRow? primaryImageFor(String productId) {
    return productImages
        .where((image) => image.productId == productId)
        .firstOrNull;
  }

  String? imageSourceFor(ProductImageRow image) {
    final localPath = image.localPath;
    if (localPath != null && File(localPath).existsSync()) return localPath;
    return signedImageUrls[image.id];
  }

  Future<String?> captureProductPhoto() async {
    errorMessage.value = null;
    try {
      XFile? selected;
      if (PlatformCapabilities.detect().hasCamera) {
        selected = await _imagePicker.pickImage(
          source: ImageSource.camera,
          maxWidth: AppImageCompressor.defaultMaxDimension.toDouble(),
          maxHeight: AppImageCompressor.defaultMaxDimension.toDouble(),
          imageQuality: AppImageCompressor.defaultQuality,
        );
      } else if (PlatformCapabilities.detect().hasFileSystemAccess) {
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
      final directory = Directory(path.join(documents.path, 'product_images'));
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

  Future<void> _resolveRemoteImages(List<ProductImageRow> rows) async {
    final storage = imageStorage;
    if (storage == null) return;
    for (final image in rows) {
      if (image.remoteUrl == null || signedImageUrls.containsKey(image.id)) {
        continue;
      }
      final result = await storage.createSignedUrl(
        bucketName: ProductImageUseCases.bucketName,
        storagePath: image.remoteUrl!,
      );
      result.fold(
        onOk: (url) => signedImageUrls[image.id] = url,
        onErr: (_) {},
      );
    }
  }
}
