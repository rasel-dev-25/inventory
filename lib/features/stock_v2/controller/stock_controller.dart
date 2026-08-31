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
import '../../../data/usecases/unit_usecases.dart';
import '../../../domain/entities/fund_source.dart';
import '../../../domain/entities/investor.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/product_unit.dart';
import '../../pricing_settings_v2/controller/pricing_settings_controller.dart';

/// Sentinel used for [StockController.selectedFundFilter] to mean
/// "shop-funded only" — distinct from `null`, which means "no fund
/// filter, show everything", since a real investor id could otherwise
/// collide with any other sentinel string.
const shopFundFilterValue = '__shop__';

/// Backs the v2 Stock screen — `notes/business_logic.md` §খ: category and
/// investor filters (both derived from [Product.fundSource]/
/// [Product.category], never stored redundantly), per-category cost/
/// sale-value/profit totals, the "top sellers vs. slow movers" view
/// computed from [StockMovements], and full product CRUD/photo capture.
class StockController extends GetxController {
  final AppDatabase db;
  final PricingSettingsController? pricingSettings;
  final StorageUploadTransport? imageStorage;

  static const _uuid = Uuid();

  StockController(this.db, {this.pricingSettings, this.imageStorage});

  late final CategoryUseCases _categoryUseCases = CategoryUseCases(db);
  late final UnitUseCases _unitUseCases = UnitUseCases(db);
  late final ProductUseCases _productUseCases = ProductUseCases(db);
  late final ProductImageUseCases _productImageUseCases = ProductImageUseCases(
    db,
  );
  final _imagePicker = ImagePicker();

  final products = <Product>[].obs;
  final categories = <CategoryRow>[].obs;
  final units = <ProductUnit>[].obs;
  final investors = <Investor>[].obs;
  final saleMovements = <StockMovementRow>[].obs;
  final productImages = <ProductImageRow>[].obs;
  final signedImageUrls = <String, String>{}.obs;
  final errorMessage = RxnString();

  /// `null` = all categories.
  final selectedCategory = RxnString();

  /// `null` = all fund sources, [shopFundFilterValue] = shop-funded only,
  /// anything else = that investor's id.
  final selectedFundFilter = RxnString();

  final List<StreamSubscription<Object?>> _subscriptions = [];

  double? get overheadMarkupPercent => pricingSettings?.overheadMarkupPercent;

  @override
  void onInit() {
    super.onInit();
    _subscriptions.add(
      db.productDao
          .watchAll(defaultShopId)
          .listen((rows) => products.assignAll(rows)),
    );
    _subscriptions.add(
      _unitUseCases
          .watchAll(defaultShopId)
          .listen((rows) => units.assignAll(rows)),
    );
    _subscriptions.add(
      db.categoryDao
          .watchAll(defaultShopId)
          .listen((rows) => categories.assignAll(rows)),
    );
    _subscriptions.add(
      db.investorDao
          .watchAll(defaultShopId)
          .listen((rows) => investors.assignAll(rows)),
    );
    _subscriptions.add(
      db.ledgerDao
          .watchSaleMovements(defaultShopId)
          .listen((rows) => saleMovements.assignAll(rows)),
    );
    _subscriptions.add(
      db.productImageDao.watchForShop(defaultShopId).listen((rows) {
        productImages.assignAll(rows);
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

  List<Product> get filteredProducts {
    return products.where((p) {
      if (selectedCategory.value != null &&
          p.category != selectedCategory.value) {
        return false;
      }
      final filter = selectedFundFilter.value;
      if (filter == null) return true;
      if (filter == shopFundFilterValue) return p.fundSource.isShop;
      return p.fundSource.investorId == filter;
    }).toList();
  }

  /// `Σ(qty × costPrice)` over [filteredProducts] — "মোট cost value".
  Money get totalCostValue => filteredProducts.fold(
    Money.zero(),
    (sum, p) => sum + p.costPrice * p.qty,
  );

  /// `Σ(qty × suggestedSellPrice)` — "সম্ভাব্য sale value".
  Money get potentialSaleValue => filteredProducts.fold(
    Money.zero(),
    (sum, p) => sum + p.suggestedSellPrice * p.qty,
  );

  /// "সম্ভাব্য profit" — the spread between the two totals above.
  Money get potentialProfit => potentialSaleValue - totalCostValue;

  Map<String, Money> get categoryCostTotals {
    final totals = <String, Money>{};
    for (final product in products) {
      totals[product.category] =
          (totals[product.category] ?? Money.zero()) +
          product.costPrice * product.qty;
    }
    return Map.fromEntries(
      totals.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  Map<String, double> get soldQtyByProduct {
    final totals = <String, double>{};
    for (final movement in saleMovements) {
      totals[movement.productId] =
          (totals[movement.productId] ?? 0) + (-movement.deltaQty);
    }
    return totals;
  }

  List<Product> get topSellers {
    final sold = soldQtyByProduct;
    final withSales = filteredProducts
        .where((p) => (sold[p.id] ?? 0) > 0)
        .toList();
    withSales.sort((a, b) => (sold[b.id] ?? 0).compareTo(sold[a.id] ?? 0));
    return withSales.take(5).toList();
  }

  List<Product> get slowMovers {
    final sold = soldQtyByProduct;
    final noSales = filteredProducts
        .where((p) => (sold[p.id] ?? 0) == 0 && p.qty > 0)
        .toList();
    noSales.sort((a, b) => b.qty.compareTo(a.qty));
    return noSales.take(5).toList();
  }

  String investorName(String id) {
    for (final investor in investors) {
      if (investor.id == id) return investor.name;
    }
    return id;
  }

  int countForCategory(String? categoryName) {
    if (categoryName == null) return products.length;
    return products.where((p) => p.category == categoryName).length;
  }

  int countForFundSource(String? fundFilter) {
    if (fundFilter == null) return products.length;
    if (fundFilter == shopFundFilterValue) {
      return products.where((p) => p.fundSource.isShop).length;
    }
    return products.where((p) => p.fundSource.investorId == fundFilter).length;
  }

  ProductImageRow? primaryImageFor(String productId) {
    for (final image in productImages) {
      if (image.productId == productId) return image;
    }
    return null;
  }

  String? imageSourceFor(ProductImageRow image) {
    final local = image.localPath;
    if (local != null && File(local).existsSync()) return local;
    final remote = image.remoteUrl;
    if (remote != null) {
      return signedImageUrls[image.id] ?? signedImageUrls[remote] ?? remote;
    }
    return null;
  }

  Future<bool> createCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    final highestSort = categories.fold<int>(
      0,
      (max, c) => c.sortOrder > max ? c.sortOrder : max,
    );
    try {
      await _categoryUseCases.create(
        id: _uuid.v7(),
        shopId: defaultShopId,
        name: trimmed,
        sortOrder: highestSort + 1,
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
    String unit = 'pcs',
    String sellUnit = 'pcs',
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
        unit: unit,
        sellUnit: sellUnit,
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

  Future<bool> updateProduct(
    Product existing, {
    String? name,
    String? category,
    Money? costPrice,
    Money? suggestedSellPrice,
    double? qty,
    FundSource? fundSource,
    String? unit,
    String? sellUnit,
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
        unit: unit,
        sellUnit: sellUnit,
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
          final movementId = _uuid.v7();
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

  Future<bool> softDeleteProduct(String id) async {
    try {
      final imageRow = primaryImageFor(id);
      if (imageRow != null) {
        await _productImageUseCases.delete(
          imageId: imageRow.id,
          storage: imageStorage,
        );
      }
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

  Future<void> deleteProductImage(String imageId) async {
    await _productImageUseCases.delete(
      imageId: imageId,
      storage: imageStorage,
    );
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
