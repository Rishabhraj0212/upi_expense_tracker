import 'package:drift/drift.dart';

import '../domain/models/parsed_transaction.dart';
import '../domain/models/sync_status.dart';
import '../domain/models/transaction.dart' as domain;
import '../domain/models/transaction_source.dart';
import '../domain/repositories/transaction_repository.dart';
import 'local/app_database.dart';

class DriftTransactionRepository implements TransactionRepository {
  DriftTransactionRepository(this._db);

  final AppDatabase _db;

  @override
  Future<int> insert(ParsedTransaction parsed) async {
    final now = DateTime.now();
    return _db.into(_db.transactions).insert(
          TransactionsCompanion.insert(
            amountPaise: parsed.amountPaise,
            type: parsed.type,
            occurredAt: parsed.occurredAt,
            receivedAt: now,
            mergedSources: parsed.sourceType.name,
            rawText: parsed.rawText,
            createdAt: now,
            updatedAt: now,
            syncStatus: TransactionSyncStatus.pending,
            merchantName: Value(parsed.merchantName),
            upiId: Value(parsed.upiId),
            bankName: Value(parsed.bankName),
            accountHint: Value(parsed.accountHint),
            referenceId: Value(parsed.referenceId),
            sourceApp: Value(parsed.sourceApp),
            sourceAddress: Value(parsed.sourceAddress),
            balancePaise: Value(parsed.balancePaise),
            note: Value(parsed.note),
          ),
        );
  }

  @override
  Future<void> mergeInto(int existingId, ParsedTransaction parsed) async {
    // TODO(phase2-sync): once Google Sheets sync exists, call markPending(existingId)
    // here if this merge actually changes a Sheet-mirrored field — see the
    // doc comment on TransactionRepository.mergeInto for why.
    final existing = await getById(existingId);
    if (existing == null) return;

    final sources = existing.sourceList.toSet()..add(parsed.sourceType.name);

    // Prefer a human-readable merchant name over a bare VPA/UPI id.
    String? mergedMerchant = existing.merchantName;
    final candidateName = parsed.merchantName;
    if (candidateName != null && !candidateName.contains('@')) {
      if (mergedMerchant == null || mergedMerchant.contains('@')) {
        mergedMerchant = candidateName;
      }
    } else {
      mergedMerchant ??= candidateName;
    }

    await (_db.update(_db.transactions)..where((t) => t.id.equals(existingId))).write(
      TransactionsCompanion(
        merchantName: Value(mergedMerchant),
        upiId: Value(existing.upiId ?? parsed.upiId),
        bankName: Value(existing.bankName ?? parsed.bankName),
        accountHint: Value(existing.accountHint ?? parsed.accountHint),
        referenceId: Value(existing.referenceId ?? parsed.referenceId),
        sourceApp: Value(existing.sourceApp ?? parsed.sourceApp),
        sourceAddress: Value(existing.sourceAddress ?? parsed.sourceAddress),
        balancePaise: Value(parsed.balancePaise ?? existing.balancePaise),
        note: Value(existing.note ?? parsed.note),
        mergedSources: Value(sources.join(',')),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<domain.Transaction?> getById(int id) async {
    final row = await (_db.select(_db.transactions)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<List<domain.Transaction>> findByReferenceId(String referenceId) async {
    final rows = await (_db.select(_db.transactions)..where((t) => t.referenceId.equals(referenceId))).get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<List<domain.Transaction>> findByAmountNear(int amountPaise, DateTime around, Duration window) async {
    final from = around.subtract(window);
    final to = around.add(window);
    final rows = await (_db.select(_db.transactions)
          ..where((t) =>
              t.amountPaise.equals(amountPaise) &
              t.occurredAt.isBiggerOrEqualValue(from) &
              t.occurredAt.isSmallerOrEqualValue(to)))
        .get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<List<domain.Transaction>> getAll({TransactionFilter filter = TransactionFilter.none, int limit = 500}) async {
    final rows = await (_buildFilteredQuery(filter)
          ..orderBy([
            (t) => OrderingTerm.desc(t.occurredAt),
            (t) => OrderingTerm.desc(t.id),
          ])
          ..limit(limit))
        .get();
    return rows.map(_toDomain).toList();
  }

  @override
  Stream<List<domain.Transaction>> watchAll({TransactionFilter filter = TransactionFilter.none, int limit = 500}) {
    return (_buildFilteredQuery(filter)
          ..orderBy([
            (t) => OrderingTerm.desc(t.occurredAt),
            (t) => OrderingTerm.desc(t.id),
          ])
          ..limit(limit))
        .watch()
        .map((rows) => rows.map(_toDomain).toList());
  }

  Expression<bool> _buildWhereClause(TransactionFilter filter) {
    Expression<bool> predicate = const Constant(true);
    final t = _db.transactions;
    if (filter.type != null) {
      predicate = predicate & t.type.equalsValue(filter.type!);
    }
    if (filter.from != null) {
      predicate = predicate & t.occurredAt.isBiggerOrEqualValue(filter.from!);
    }
    if (filter.to != null) {
      predicate = predicate & t.occurredAt.isSmallerOrEqualValue(filter.to!);
    }
    if (filter.searchText != null && filter.searchText!.trim().isNotEmpty) {
      final needle = '%${filter.searchText!.trim()}%';
      predicate = predicate & (t.merchantName.like(needle) | t.upiId.like(needle) | t.rawText.like(needle));
    }
    if (filter.category != null) {
      if (filter.category == 'Uncategorized') {
        predicate = predicate & t.category.isNull();
      } else {
        predicate = predicate & t.category.equals(filter.category!);
      }
    }
    return predicate;
  }

  SimpleSelectStatement<$TransactionsTable, TransactionRow> _buildFilteredQuery(TransactionFilter filter) {
    return _db.select(_db.transactions)..where((t) => _buildWhereClause(filter));
  }

  @override
  Future<int> getTotalAmount(TransactionFilter filter) async {
    final amountExpr = _db.transactions.amountPaise.sum();
    final query = _db.selectOnly(_db.transactions)
      ..addColumns([amountExpr])
      ..where(_buildWhereClause(filter));
    final row = await query.getSingle();
    return row.read(amountExpr) ?? 0;
  }

  @override
  Future<int> getTransactionCount(TransactionFilter filter) async {
    final countExpr = _db.transactions.id.count();
    final query = _db.selectOnly(_db.transactions)
      ..addColumns([countExpr])
      ..where(_buildWhereClause(filter));
    final row = await query.getSingle();
    return row.read(countExpr) ?? 0;
  }

  @override
  Future<List<MapEntry<String, int>>> getTopCategories(TransactionFilter filter, {int limit = 5}) async {
    final amountExpr = _db.transactions.amountPaise.sum();
    final categoryExpr = _db.transactions.category;
    final query = _db.selectOnly(_db.transactions)
      ..addColumns([categoryExpr, amountExpr])
      ..where(_buildWhereClause(filter))
      ..groupBy([categoryExpr])
      ..orderBy([OrderingTerm.desc(amountExpr)])
      ..limit(limit);
    final rows = await query.get();
    return rows
        .map((r) => MapEntry(r.read(categoryExpr) ?? 'Uncategorized', r.read(amountExpr) ?? 0))
        .toList();
  }

  @override
  Future<List<MapEntry<String, int>>> getTopMerchants(TransactionFilter filter, {int limit = 5}) async {
    final amountExpr = _db.transactions.amountPaise.sum();
    final merchantExpr = _db.transactions.merchantName;
    final query = _db.selectOnly(_db.transactions)
      ..addColumns([merchantExpr, amountExpr])
      ..where(_buildWhereClause(filter))
      ..groupBy([merchantExpr])
      ..orderBy([OrderingTerm.desc(amountExpr)])
      ..limit(limit);
    final rows = await query.get();
    return rows
        .map((r) => MapEntry(r.read(merchantExpr) ?? 'Unknown', r.read(amountExpr) ?? 0))
        .toList();
  }

  @override
  Future<void> setCategory(int id, String? category, String? note) async {
    await (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        category: Value(category),
        note: Value(note),
        updatedAt: Value(DateTime.now()),
      ),
    );
    // Any change to these fields must be synced to Sheets.
    await markPending(id);
  }

  @override
  Future<void> delete(int id) async {
    await (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> clearAllData() async {
    await _db.delete(_db.transactions).go();
    await _db.delete(_db.rawCaptures).go();
  }

  @override
  Future<List<domain.Transaction>> getTransactionsNeedingSync() async {
    final rows = await (_db.select(_db.transactions)
          ..where((t) =>
              t.syncStatus.equalsValue(TransactionSyncStatus.pending) |
              t.syncStatus.equalsValue(TransactionSyncStatus.failed)))
        .get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<void> markSynced(int id, {String? remoteRowRef, required DateTime syncedAt}) async {
    await (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        syncStatus: const Value(TransactionSyncStatus.synced),
        lastSyncedAt: Value(syncedAt),
        remoteRowRef: Value(remoteRowRef),
        lastSyncError: const Value(null),
      ),
    );
  }

  @override
  Future<void> markSyncFailed(int id, String error) async {
    await (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        syncStatus: const Value(TransactionSyncStatus.failed),
        lastSyncError: Value(error),
      ),
    );
  }

  @override
  Future<void> markPending(int id) async {
    await (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
      const TransactionsCompanion(
        syncStatus: Value(TransactionSyncStatus.pending),
        lastSyncError: Value(null),
      ),
    );
  }

  @override
  Future<TransactionSyncCounts> getSyncCounts() async {
    Future<int> countWhere(TransactionSyncStatus status) async {
      final countExpr = _db.transactions.id.count();
      final query = _db.selectOnly(_db.transactions)
        ..addColumns([countExpr])
        ..where(_db.transactions.syncStatus.equalsValue(status));
      final row = await query.getSingle();
      return row.read(countExpr) ?? 0;
    }

    final synced = await countWhere(TransactionSyncStatus.synced);
    final pending = await countWhere(TransactionSyncStatus.pending);
    final failed = await countWhere(TransactionSyncStatus.failed);
    return TransactionSyncCounts(synced: synced, pending: pending, failed: failed);
  }

  @override
  Future<void> logCapture({
    required String sourceType,
    required String? origin,
    required String text,
    required String result,
    required DateTime at,
  }) async {
    await _db.into(_db.rawCaptures).insert(
          RawCapturesCompanion.insert(
            at: at,
            sourceType: SourceType.fromName(sourceType),
            text_: text,
            result: result,
            origin: Value(origin),
          ),
        );
    // Cap the diagnostic log so it doesn't grow unbounded.
    const cap = 300;
    await _db.customStatement(
      'DELETE FROM raw_captures WHERE id NOT IN (SELECT id FROM raw_captures ORDER BY id DESC LIMIT $cap)',
    );
  }

  @override
  Future<List<CaptureLogEntry>> getCaptures({int limit = 200}) async {
    final rows = await (_db.select(_db.rawCaptures)
          ..orderBy([(t) => OrderingTerm.desc(t.id)])
          ..limit(limit))
        .get();
    return rows
        .map((r) => CaptureLogEntry(
              at: r.at,
              sourceType: r.sourceType.name,
              origin: r.origin,
              text: r.text_,
              result: r.result,
            ))
        .toList();
  }

  @override
  Future<void> clearCaptures() async {
    await _db.delete(_db.rawCaptures).go();
  }

  domain.Transaction _toDomain(TransactionRow row) => domain.Transaction(
        id: row.id,
        amountPaise: row.amountPaise,
        type: row.type,
        occurredAt: row.occurredAt,
        receivedAt: row.receivedAt,
        merchantName: row.merchantName,
        upiId: row.upiId,
        bankName: row.bankName,
        accountHint: row.accountHint,
        referenceId: row.referenceId,
        mergedSources: row.mergedSources,
        sourceApp: row.sourceApp,
        sourceAddress: row.sourceAddress,
        rawText: row.rawText,
        category: row.category,
        note: row.note,
        balancePaise: row.balancePaise,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        syncStatus: row.syncStatus,
        lastSyncedAt: row.lastSyncedAt,
        remoteRowRef: row.remoteRowRef,
        lastSyncError: row.lastSyncError,
      );
}
