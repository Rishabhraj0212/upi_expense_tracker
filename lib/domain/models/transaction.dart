import 'sync_status.dart';
import 'transaction_type.dart';

/// A persisted, deduplicated transaction as read back from the database.
class Transaction {
  const Transaction({
    required this.id,
    required this.amountPaise,
    required this.type,
    required this.occurredAt,
    required this.receivedAt,
    required this.mergedSources,
    required this.rawText,
    required this.createdAt,
    required this.updatedAt,
    this.merchantName,
    this.upiId,
    this.bankName,
    this.accountHint,
    this.referenceId,
    this.sourceApp,
    this.sourceAddress,
    this.category,
    this.note,
    this.balancePaise,
    this.syncStatus = TransactionSyncStatus.pending,
    this.lastSyncedAt,
    this.remoteRowRef,
    this.lastSyncError,
  });

  final int id;
  final int amountPaise;
  final TransactionType type;

  final DateTime occurredAt;
  final DateTime receivedAt;

  final String? merchantName;
  final String? upiId;
  final String? bankName;
  final String? accountHint;
  final String? referenceId;

  /// Comma-separated list of SourceType names, e.g. "sms,notification",
  /// tracking every channel this transaction was seen through after merges.
  final String mergedSources;
  final String? sourceApp;
  final String? sourceAddress;

  final String rawText;

  /// Reserved for a future phase; unused by Phase 1 UI.
  final String? category;
  final String? note;

  /// Account balance reported in the SMS (e.g. "Avl Bal Rs.12,345.00"),
  /// in paise. Null if the message didn't include balance info.
  final int? balancePaise;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Phase 2: Google Sheets sync state for this row. [id] is the stable
  /// identity written into the sheet; [remoteRowRef] is only a locate-faster
  /// hint (e.g. a last-known row number) and is never trusted as identity —
  /// if it's stale, sync re-locates by [id] and repairs it.
  final TransactionSyncStatus syncStatus;
  final DateTime? lastSyncedAt;
  final String? remoteRowRef;
  final String? lastSyncError;

  String get displayName => merchantName ?? upiId ?? 'UPI transaction';

  List<String> get sourceList => mergedSources.split(',').where((s) => s.isNotEmpty).toList();
}
