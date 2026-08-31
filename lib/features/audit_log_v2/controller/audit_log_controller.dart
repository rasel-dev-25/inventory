import 'dart:async';

import 'package:get/get.dart';

import '../../../data/local/app_database.dart';
import '../../../data/local/default_shop.dart';
import '../../auth/controller/auth_controller.dart';

/// Backs the modernized Audit Log screen — a searchable, filterable view over
/// [AuditLogEntries] with real-time reactive streams, color-coded action tagging,
/// and smart human-readable change diffing.
class AuditLogController extends GetxController {
  final AppDatabase db;
  final AuthController? authController;

  AuditLogController(this.db, {this.authController});

  final allEntries = <AuditLogEntryRow>[].obs;
  final searchQuery = ''.obs;
  final selectedEntity = 'all'.obs;
  final selectedAction = 'all'.obs;
  final isSearchOpen = false.obs;

  StreamSubscription<Object?>? _subscription;
  StreamSubscription<Object?>? _authSubscription;

  // Legacy accessor for backward compatibility with tests
  RxList<AuditLogEntryRow> get entries => allEntries;

  @override
  void onInit() {
    super.onInit();
    _subscribeToLogs();

    // Re-subscribe if user switches shop or authenticates
    final auth = authController ?? (Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null);
    if (auth != null) {
      _authSubscription = auth.session.listen((_) => _subscribeToLogs());
    }
  }

  void _subscribeToLogs() {
    _subscription?.cancel();
    final auth = authController ?? (Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null);
    final shopId = auth?.session.value?.shopId ?? defaultShopId;

    _subscription = db.auditLogDao
        .watchAll(shopId)
        .listen((rows) => allEntries.assignAll(rows));
  }

  List<AuditLogEntryRow> get filteredEntries {
    final query = searchQuery.value.trim().toLowerCase();
    final entityFilter = selectedEntity.value;
    final actionFilter = selectedAction.value;

    return allEntries.where((entry) {
      // 1. Filter by Entity/Table
      if (entityFilter != 'all' && entry.changedTableName.toLowerCase() != entityFilter.toLowerCase()) {
        return false;
      }

      // 2. Filter by Action
      if (actionFilter != 'all') {
        final normalizedAction = _normalizeAction(entry.action);
        if (normalizedAction != actionFilter) {
          return false;
        }
      }

      // 3. Filter by Search Query
      if (query.isNotEmpty) {
        final matchesRecordId = entry.recordId.toLowerCase().contains(query);
        final matchesTable = entry.changedTableName.toLowerCase().contains(query);
        final matchesAction = entry.action.toLowerCase().contains(query);
        final matchesOldJson = entry.oldValueJson?.toLowerCase().contains(query) ?? false;
        final matchesNewJson = entry.newValueJson?.toLowerCase().contains(query) ?? false;

        if (!matchesRecordId && !matchesTable && !matchesAction && !matchesOldJson && !matchesNewJson) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  int get totalCount => allEntries.length;
  int get deleteCount => allEntries.where((e) => _normalizeAction(e.action) == 'delete').length;
  int get updateCount => allEntries.where((e) => _normalizeAction(e.action) == 'update').length;
  int get insertCount => allEntries.where((e) => _normalizeAction(e.action) == 'insert').length;
  int get restoreCount => allEntries.where((e) => _normalizeAction(e.action) == 'restore').length;

  void setSearchQuery(String text) {
    searchQuery.value = text;
  }

  void setEntityFilter(String entity) {
    selectedEntity.value = entity;
  }

  void setActionFilter(String action) {
    selectedAction.value = action;
  }

  void toggleSearch() {
    isSearchOpen.value = !isSearchOpen.value;
    if (!isSearchOpen.value) {
      searchQuery.value = '';
    }
  }

  void resetFilters() {
    searchQuery.value = '';
    selectedEntity.value = 'all';
    selectedAction.value = 'all';
    isSearchOpen.value = false;
  }

  String _normalizeAction(String action) {
    final act = action.toLowerCase();
    if (act == 'create' || act == 'insert') return 'insert';
    if (act == 'edit' || act == 'update') return 'update';
    if (act == 'delete' || act == 'trash') return 'delete';
    if (act == 'restore') return 'restore';
    return act;
  }

  @override
  void onClose() {
    _subscription?.cancel();
    _authSubscription?.cancel();
    super.onClose();
  }
}
