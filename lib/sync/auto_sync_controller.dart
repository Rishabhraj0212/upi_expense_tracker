import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/models/sync_settings.dart';
import '../domain/models/sync_status.dart';
import '../domain/models/transaction.dart';
import 'transaction_sync_service.dart';

/// Reacts to new/changed local transactions and triggers a debounced,
/// non-blocking sync whenever auto-sync is enabled and conditions allow.
///
/// Lifecycle:
///   1. Created once at app start (via [autoSyncControllerProvider]).
///   2. Watches two streams: transaction list + sync settings.
///   3. On any change, if auto-sync is ON and conditions are met, schedules
///      a sync after [debounceDelay] (coalesces rapid bursts of inserts into
///      one run).
///   4. Exactly one sync run is active at a time — a pending run is
///      rescheduled rather than stacked if a new change arrives while one
///      is already running.
///   5. [dispose] cancels all subscriptions and timers.
///
/// Rules:
///   - Never blocks the ingestion pipeline (fire-and-forget via unawaited).
///   - No sync when: autoSyncEnabled==false, not connected, no spreadsheet.
///   - On any network/auth failure the transaction stays PENDING/FAILED for
///     the next opportunity; local data is never lost.
class AutoSyncController {
  AutoSyncController({
    required Stream<List<Transaction>> transactionStream,
    required Stream<SyncSettings> settingsStream,
    required TransactionSyncService syncService,
    this.debounceDelay = const Duration(seconds: 3),
  })  : _syncService = syncService {
    _settingsSub = settingsStream.listen(
      (s) {
        _lastSettings = s;
        _onTransactionChange();
      },
      onError: (Object e) => debugPrint('[AutoSync] settings stream error: $e'),
    );
    _transactionSub = transactionStream.listen(
      (_) => _onTransactionChange(),
      onError: (Object e) => debugPrint('[AutoSync] transaction stream error: $e'),
    );
  }

  final TransactionSyncService _syncService;
  final Duration debounceDelay;

  StreamSubscription<SyncSettings>? _settingsSub;
  StreamSubscription<List<Transaction>>? _transactionSub;
  Timer? _debounceTimer;

  SyncSettings? _lastSettings;

  /// True while a sync run is in progress.
  bool _running = false;

  /// Signals that another sync was requested while _running was true.
  bool _pendingAfterRun = false;

  // ---------------------------------------------------------------------------
  // Internal

  bool _shouldSync() {
    final s = _lastSettings;
    if (s == null) return false;
    if (!s.autoSyncEnabled) return false;
    if (!s.isConnected) return false;
    if (s.spreadsheetId == null) return false;
    if (s.syncPreference != SyncPreference.googleSheets) return false;
    return true;
  }

  void _onTransactionChange() {
    if (!_shouldSync()) return;

    if (_running) {
      // A sync is already active — flag it so we retry immediately after.
      _pendingAfterRun = true;
      return;
    }

    // Debounce: cancel any earlier pending timer and restart.
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDelay, _triggerSync);
  }

  Future<void> _triggerSync() async {
    if (!_shouldSync()) return;
    if (_running) {
      _pendingAfterRun = true;
      return;
    }

    _running = true;
    _pendingAfterRun = false;

    try {
      debugPrint('[AutoSync] starting sync run');
      final outcome = await _syncService.syncPendingTransactions();
      debugPrint('[AutoSync] sync run finished: $outcome');
    } catch (e, st) {
      // Unexpected crash in the sync layer: log and leave transactions as-is.
      debugPrint('[AutoSync] sync run threw: $e\n$st');
    } finally {
      _running = false;
    }

    // If another transaction arrived while we were running, do one more pass.
    if (_pendingAfterRun && _shouldSync()) {
      _pendingAfterRun = false;
      _debounceTimer?.cancel();
      _debounceTimer = Timer(debounceDelay, _triggerSync);
    }
  }

  // ---------------------------------------------------------------------------
  // Public

  /// Whether the controller is currently executing a sync run.
  bool get isSyncing => _running;

  void dispose() {
    _debounceTimer?.cancel();
    _settingsSub?.cancel();
    _transactionSub?.cancel();
  }
}
