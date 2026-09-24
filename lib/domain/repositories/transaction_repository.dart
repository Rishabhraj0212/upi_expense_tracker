import '../models/parsed_transaction.dart';
import '../models/transaction.dart';
import '../models/transaction_type.dart';

/// Optional filters for [TransactionRepository.watchAll]/[TransactionRepository.getAll].
class TransactionFilter {
  const TransactionFilter({
    this.type,
    this.from,
    this.to,
    this.searchText,
    this.category,
  });

  final TransactionType? type;
  final DateTime? from;
  final DateTime? to;
  final String? searchText;
  final String? category; // If "Uncategorized", use special constant or match null

  static const none = TransactionFilter();

  /// [clearType]/[clearSearchText]/[clearCategory] let the UI explicitly reset a field back
  /// to null, since passing null itself to a named parameter here just means
  /// "keep the current value".
  TransactionFilter copyWith({
    TransactionType? type,
    bool clearType = false,
    DateTime? from,
    DateTime? to,
    String? searchText,
    bool clearSearchText = false,
    String? category,
    bool clearCategory = false,
  }) {
    return TransactionFilter(
      type: clearType ? null : (type ?? this.type),
      from: from ?? this.from,
      to: to ?? this.to,
      searchText: clearSearchText ? null : (searchText ?? this.searchText),
      category: clearCategory ? null : (category ?? this.category),
    );
  }
}

abstract class TransactionRepository {
  /// Inserts a brand-new transaction and returns its generated id.
  Future<int> insert(ParsedTransaction parsed);

  /// Merges a newly-parsed duplicate into an existing transaction: fills gaps
  /// in nullable fields and records the additional source.
  ///
  /// Phase 2 requirement, not yet wired (tracked here so it isn't lost — see
  /// [markPending]): a merge can improve data on a row that was *already
  /// synced* (e.g. filling in a bank name from the second-arriving source).
  /// Once sync exists, this method must call [markPending] for [existingId]
  /// whenever it actually changes a Sheet-mirrored field, so that
  /// improvement reaches the sheet on the next sync instead of the sheet
  /// silently going stale. No such call happens yet — this is documentation
  /// of an obligation the future sync implementation must pick up, not a
  /// description of current behavior.
  Future<void> mergeInto(int existingId, ParsedTransaction parsed);

  Future<Transaction?> getById(int id);

  /// Candidates for duplicate matching: same reference id.
  Future<List<Transaction>> findByReferenceId(String referenceId);

  /// Candidates for duplicate matching: same amount within a time window.
  Future<List<Transaction>> findByAmountNear(int amountPaise, DateTime around, Duration window);

  Future<List<Transaction>> getAll({TransactionFilter filter = TransactionFilter.none, int limit = 500});

  /// Reactive stream that emits whenever matching rows change.
  Stream<List<Transaction>> watchAll({TransactionFilter filter = TransactionFilter.none, int limit = 500});

  /// Updates the user-editable category/note.
  ///
  /// Phase 2 requirement, not yet wired (see [markPending]): category and
  /// note are both required Sheets columns, so once sync exists this method
  /// must call [markPending] for [id] afterward — a previously synced row
  /// that's edited locally must be written again on the next sync, not left
  /// silently out of date in the sheet. The same obligation applies to any
  /// other field that becomes locally editable in the future.
  Future<void> setCategory(int id, String? category, String? note);

  Future<void> delete(int id);

  /// Rows with sync status pending or failed — what a sync run needs to
  /// write/retry. Matching by [Transaction.id] (never [Transaction.remoteRowRef])
  /// is the caller's responsibility once it has these.
  Future<List<Transaction>> getTransactionsNeedingSync();

  Future<void> markSynced(int id, {String? remoteRowRef, required DateTime syncedAt});

  Future<void> markSyncFailed(int id, String error);

  /// Used when a locally edited transaction needs to be written again.
  ///
  /// This is the mechanism [setCategory] and [mergeInto] — and any future
  /// editable-field path — must call once Google Sheets sync exists: any
  /// local change to a field the sheet mirrors flips a previously synced row
  /// back to pending, so it's written again rather than the sheet silently
  /// drifting out of date. The method is ready; those call sites don't
  /// invoke it yet (see their doc comments) — no Google/sync logic exists
  /// yet for it to feed into.
  Future<void> markPending(int id);

  /// Aggregate counts by sync status, for Settings/dashboard sync summaries
  /// (e.g. "230 synced, 15 pending, 3 failed"). Pure local aggregation — no
  /// Google/network call is involved in computing this.
  Future<TransactionSyncCounts> getSyncCounts();

  /// Debug/tuning log of every raw SMS/notification seen, parsed or not.
  Future<void> logCapture({
    required String sourceType,
    required String? origin,
    required String text,
    required String result,
    required DateTime at,
  });

  Future<List<CaptureLogEntry>> getCaptures({int limit = 200});

  Future<void> clearCaptures();
}

class TransactionSyncCounts {
  const TransactionSyncCounts({required this.synced, required this.pending, required this.failed});

  final int synced;
  final int pending;
  final int failed;

  int get total => synced + pending + failed;
}

class CaptureLogEntry {
  const CaptureLogEntry({
    required this.at,
    required this.sourceType,
    required this.origin,
    required this.text,
    required this.result,
  });

  final DateTime at;
  final String sourceType;
  final String? origin;
  final String text;
  final String result;
}
