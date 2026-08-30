import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/platform/capabilities.dart';
import '../../../core/utils/image_compressor.dart';
import '../../../data/local/app_database.dart';
import '../../../data/local/default_shop.dart';
import '../../../data/sync/storage_upload_transport.dart';
import '../../../data/usecases/customer_image_usecases.dart';
import '../../../data/usecases/customer_usecases.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/due.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/rent_transaction.dart';
import '../../../domain/entities/sale.dart';

/// Backs the Customers screen — list/create/edit/soft-delete plus the
/// flagged (suspicion/blocked) filter view from `notes/business_logic.md`
/// §জ, via [CustomerUseCases]. Embedded directly in `ShellScreen` — see
/// that class's own doc comment.
class CustomersController extends GetxController {
  final AppDatabase db;
  final StorageUploadTransport? imageStorage;
  static const _uuid = Uuid();

  CustomersController(this.db, {this.imageStorage});

  late final CustomerUseCases _useCases = CustomerUseCases(db);
  late final CustomerImageUseCases _imageUseCases = CustomerImageUseCases(db);
  final _imagePicker = ImagePicker();

  final customers = <Customer>[].obs;
  final customerImages = <CustomerImageRow>[].obs;
  final sales = <Sale>[].obs;
  final dues = <Due>[].obs;
  final rentals = <RentTransaction>[].obs;
  final orders = <Order>[].obs;
  final products = <Product>[].obs;
  final signedImageUrls = <String, String>{}.obs;
  final searchQuery = ''.obs;
  final showFlaggedOnly = false.obs;
  final errorMessage = RxnString();

  final List<StreamSubscription<Object?>> _subscriptions = [];

  @override
  void onInit() {
    super.onInit();
    _subscriptions.add(
      db.customerDao
          .watchAll(defaultShopId)
          .listen((rows) => customers.assignAll(rows)),
    );
    _subscriptions.add(
      db.customerImageDao.watchForShop(defaultShopId).listen((rows) {
        customerImages.assignAll(rows);
        _resolveRemoteImages(rows);
      }),
    );
    _subscriptions.add(
      db.saleDao.watchAll(defaultShopId).listen(sales.assignAll),
    );
    _subscriptions.add(
      db.dueDao.watchAll(defaultShopId).listen(dues.assignAll),
    );
    _subscriptions.add(
      db.rentDao.watchAll(defaultShopId).listen(rentals.assignAll),
    );
    _subscriptions.add(
      db.orderDao.watchAll(defaultShopId).listen(orders.assignAll),
    );
    _subscriptions.add(
      db.productDao.watchAll(defaultShopId).listen(products.assignAll),
    );
  }

  @override
  void onClose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.onClose();
  }

  /// Applies the search query (name/contact, case-insensitive) and the
  /// flagged-only toggle together — a customer must satisfy both to show,
  /// same combinable-filter approach `InventoryController`'s filter bar
  /// uses.
  List<Customer> get visibleCustomers {
    final query = searchQuery.value.trim().toLowerCase();
    return customers.where((c) {
      if (showFlaggedOnly.value && !c.suspicionFlag && !c.isBlocked) {
        return false;
      }
      if (query.isEmpty) return true;
      return c.name.toLowerCase().contains(query) ||
          (c.contact?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  Future<bool> createCustomer({
    required String name,
    String? address,
    String? contact,
    bool suspicionFlag = false,
    bool isBlocked = false,
    String? photoLocalPath,
  }) async {
    errorMessage.value = null;
    if (name.trim().isEmpty) {
      errorMessage.value = 'nameRequired'.tr;
      return false;
    }
    try {
      final customer = Customer(
        id: _uuid.v7(),
        name: name.trim(),
        address: address,
        contact: contact,
        suspicionFlag: suspicionFlag,
        isBlocked: isBlocked,
      );
      final now = DateTime.now().toUtc();
      await db.transaction(() async {
        await _useCases.create(customer, shopId: defaultShopId, now: now);
        if (photoLocalPath != null) {
          await _imageUseCases.add(
            customerId: customer.id,
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

  /// [existing] must be the customer as currently stored (from
  /// [customers]) — every field this doesn't explicitly change is carried
  /// over unchanged, same rule `CatalogController.updateProduct`
  /// documents for products.
  Future<bool> updateCustomer(
    Customer existing, {
    String? name,
    String? address,
    String? contact,
    bool? suspicionFlag,
    bool? isBlocked,
    String? photoLocalPath,
  }) async {
    errorMessage.value = null;
    try {
      final updated = existing.copyWith(
        name: name,
        address: address,
        contact: contact,
        suspicionFlag: suspicionFlag,
        isBlocked: isBlocked,
      );
      final now = DateTime.now().toUtc();
      await db.transaction(() async {
        await _useCases.update(updated, shopId: defaultShopId, now: now);
        if (photoLocalPath != null &&
            !customerImages.any(
              (image) =>
                  image.customerId == existing.id &&
                  image.localPath == photoLocalPath,
            )) {
          await _imageUseCases.add(
            customerId: existing.id,
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

  Future<bool> deleteCustomer(String id) async {
    errorMessage.value = null;
    try {
      await _useCases.softDelete(
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

  CustomerImageRow? primaryImageFor(String customerId) {
    return customerImages
        .where((image) => image.customerId == customerId)
        .firstOrNull;
  }

  List<Sale> salesFor(String customerId) =>
      sales.where((sale) => sale.customerId == customerId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  List<Due> duesFor(String customerId) =>
      dues.where((due) => due.customerId == customerId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<RentTransaction> rentalsFor(String customerId) =>
      rentals.where((rent) => rent.customerId == customerId).toList()
        ..sort((a, b) => b.startDate.compareTo(a.startDate));

  List<Order> ordersFor(String customerId) =>
      orders.where((order) => order.customerId == customerId).toList()
        ..sort((a, b) => b.requestedDate.compareTo(a.requestedDate));

  Product? productFor(String productId) =>
      products.where((product) => product.id == productId).firstOrNull;

  String? imageSourceFor(CustomerImageRow image) {
    final localPath = image.localPath;
    if (localPath != null && File(localPath).existsSync()) return localPath;
    return signedImageUrls[image.id];
  }

  Future<String?> captureCustomerPhoto() async {
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
      final directory = Directory(path.join(documents.path, 'customer_images'));
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

  Future<void> _resolveRemoteImages(List<CustomerImageRow> rows) async {
    final storage = imageStorage;
    if (storage == null) return;
    for (final image in rows) {
      if (image.remoteUrl == null || signedImageUrls.containsKey(image.id)) {
        continue;
      }
      final result = await storage.createSignedUrl(
        bucketName: CustomerImageUseCases.bucketName,
        storagePath: image.remoteUrl!,
      );
      result.fold(
        onOk: (url) => signedImageUrls[image.id] = url,
        onErr: (_) {},
      );
    }
  }
}
