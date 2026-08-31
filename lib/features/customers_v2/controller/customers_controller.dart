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
import '../../../data/usecases/customer_image_usecases.dart';
import '../../../data/usecases/customer_usecases.dart';
import '../../../data/usecases/pay_due_usecase.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/due.dart';
import '../../../domain/entities/due_payment.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/rent_transaction.dart';
import '../../../domain/entities/sale.dart';
import '../../../domain/services/due_lifecycle.dart';

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
  late final PayDueUseCase _payDueUseCase = PayDueUseCase(db);
  final _imagePicker = ImagePicker();

  final customers = <Customer>[].obs;
  final customerImages = <CustomerImageRow>[].obs;
  final sales = <Sale>[].obs;
  final dues = <Due>[].obs;
  final duePayments = <DuePayment>[].obs;
  final rentals = <RentTransaction>[].obs;
  final orders = <Order>[].obs;
  final products = <Product>[].obs;
  final signedImageUrls = <String, String>{}.obs;
  final searchQuery = ''.obs;
  final showBuyersOnly = false.obs;
  final showWithDuesOnly = false.obs;
  final showWithOrdersOnly = false.obs;
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
      db.dueDao.watchAllPayments().listen(duePayments.assignAll),
    );
    _subscriptions.add(
      db.rentDao.watchAll(defaultShopId).listen(rentals.assignAll),
    );
    _subscriptions.add(
      db.orderDao.watchAll(defaultShopId).listen(orders.assignAll),
    );
    _subscriptions.add(
      db.productDao.watchAllWithDeleted(defaultShopId).listen(products.assignAll),
    );
  }

  @override
  void onClose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.onClose();
  }

  int outstandingDueFor(String customerId) {
    return dues.where((d) => d.customerId == customerId).fold(
      0,
      (sum, due) =>
          sum + (due.originalAmount.minorUnits - due.paidAmount.minorUnits),
    );
  }

  Money totalPurchasedFor(String customerId) {
    return sales
        .where((s) => s.customerId == customerId)
        .fold(Money.zero(), (sum, s) => sum + (s.actualSellPrice * s.qty));
  }

  int purchasesCountFor(String customerId) {
    return sales.where((s) => s.customerId == customerId).length;
  }

  int ordersCountFor(String customerId) {
    return orders.where((o) => o.customerId == customerId).length;
  }

  int pendingOrdersCountFor(String customerId) {
    return orders
        .where((o) =>
            o.customerId == customerId && o.status == OrderStatus.pending)
        .length;
  }

  int get totalCustomersCount => customers.length;
  int get buyersCount =>
      customers.where((c) => totalPurchasedFor(c.id).isPositive || purchasesCountFor(c.id) > 0).length;
  int get withDuesCustomersCount =>
      customers.where((c) => outstandingDueFor(c.id) > 0).length;
  int get withOrdersCustomersCount =>
      customers.where((c) => ordersCountFor(c.id) > 0).length;
  int get flaggedCustomersCount =>
      customers.where((c) => c.suspicionFlag || c.isBlocked).length;

  Money get totalReceivables => Money.fromMinor(
        dues.fold(0, (sum, d) => sum + (d.originalAmount.minorUnits - d.paidAmount.minorUnits)),
      );

  void resetFilters() {
    searchQuery.value = '';
    showBuyersOnly.value = false;
    showWithDuesOnly.value = false;
    showWithOrdersOnly.value = false;
    showFlaggedOnly.value = false;
  }

  /// Applies the search query (name/contact/address, case-insensitive) and the
  /// filter toggles together.
  List<Customer> get visibleCustomers {
    final query = searchQuery.value.trim().toLowerCase();
    return customers.where((c) {
      if (showBuyersOnly.value &&
          totalPurchasedFor(c.id) <= Money.zero() &&
          purchasesCountFor(c.id) == 0) {
        return false;
      }
      if (showWithDuesOnly.value && outstandingDueFor(c.id) <= 0) {
        return false;
      }
      if (showWithOrdersOnly.value && ordersCountFor(c.id) == 0) {
        return false;
      }
      if (showFlaggedOnly.value && !c.suspicionFlag && !c.isBlocked) {
        return false;
      }
      if (query.isEmpty) return true;
      return c.name.toLowerCase().contains(query) ||
          (c.contact?.toLowerCase().contains(query) ?? false) ||
          (c.address?.toLowerCase().contains(query) ?? false);
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
      final imageRow = primaryImageFor(id);
      if (imageRow != null) {
        await _imageUseCases.delete(
          imageId: imageRow.id,
          storage: imageStorage,
        );
      }
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

  Future<void> deleteCustomerImage(String imageId) async {
    await _imageUseCases.delete(
      imageId: imageId,
      storage: imageStorage,
    );
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

  List<DuePayment> paymentsForDue(String dueId) {
    final list = duePayments.where((p) => p.dueId == dueId).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  List<DuePayment> paymentsForCustomer(String customerId) {
    final customerDueIds = dues
        .where((d) => d.customerId == customerId)
        .map((d) => d.id)
        .toSet();
    final list = duePayments
        .where((p) => customerDueIds.contains(p.dueId))
        .toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Money totalCollectedForCustomer(String customerId) {
    return paymentsForCustomer(customerId).fold(
      Money.zero(),
      (acc, p) => acc + p.amount,
    );
  }

  Future<bool> payCustomerDue({
    required String dueId,
    required Money paymentAmount,
    required PaymentMethod paymentMethod,
  }) async {
    errorMessage.value = null;
    final result = await _payDueUseCase.call(
      dueId: dueId,
      paymentAmount: paymentAmount,
      paymentMethod: paymentMethod,
      shopId: defaultShopId,
      date: DateTime.now(),
      now: DateTime.now().toUtc(),
    );
    return result.fold(
      onOk: (_) => true,
      onErr: (f) {
        errorMessage.value = f.message;
        return false;
      },
    );
  }

  Future<bool> payCustomerBalance({
    required String customerId,
    required Money paymentAmount,
    required PaymentMethod paymentMethod,
  }) async {
    errorMessage.value = null;
    final openDues = dues
        .where((d) => d.customerId == customerId && d.status != DueStatus.paid)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    if (openDues.isEmpty) {
      errorMessage.value = 'No outstanding dues for this customer';
      return false;
    }

    var remainingToPay = paymentAmount;
    final now = DateTime.now().toUtc();
    final today = DateTime.now();

    for (final due in openDues) {
      if (remainingToPay <= Money.zero()) break;
      final dueRemaining = remainingBalance(due);
      final payThis = remainingToPay <= dueRemaining ? remainingToPay : dueRemaining;

      final result = await _payDueUseCase.call(
        dueId: due.id,
        paymentAmount: payThis,
        paymentMethod: paymentMethod,
        shopId: defaultShopId,
        date: today,
        now: now,
      );

      if (result.isErr) {
        errorMessage.value = result.failureOrNull?.message;
        return false;
      }
      remainingToPay = remainingToPay - payThis;
    }
    return true;
  }

  List<RentTransaction> rentalsFor(String customerId) =>
      rentals.where((rent) => rent.customerId == customerId).toList()
        ..sort((a, b) => b.startDate.compareTo(a.startDate));

  int activeRentalsCountFor(String customerId) =>
      rentals
          .where((r) =>
              r.customerId == customerId &&
              (r.status == RentStatus.active || r.status == RentStatus.overdue))
          .length;

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
