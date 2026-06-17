import 'package:flutter/foundation.dart';

import 'package:earnjoy/data/datasources/storage_service.dart';
import 'package:earnjoy/data/datasources/supabase_service.dart';
import 'package:earnjoy/domain/usecases/sync_service.dart';

/// Exposes sync state (isSyncing, lastSyncAt, error) and triggers the
/// SyncService from UI and other providers.
class SyncProvider extends ChangeNotifier {
  final SyncService _syncService;
  final StorageService _storage;

  SyncProvider(SupabaseService supabase, this._storage)
      : _syncService = SyncService(supabase);

  bool get isSyncing => _syncService.isSyncing;
  DateTime? get lastSyncAt => _syncService.lastSyncAt;
  String? get error => _syncService.error;

  bool get hasSynced => _syncService.lastSyncAt != null;
  bool get hasError => _syncService.error != null;

  /// Trigger a full sync (push local → pull & merge remote).
  /// Safe to call multiple times — will no-op if already syncing or not signed in.
  Future<void> triggerSync() async {
    if (_syncService.isSyncing) return;
    final success = await _syncService.fullSync(_storage);
    notifyListeners();
    if (!success && _syncService.error != null) {
      // Non-fatal: app continues to work offline
      debugPrint('[SyncProvider] Sync failed: ${_syncService.error}');
    }
  }
}
