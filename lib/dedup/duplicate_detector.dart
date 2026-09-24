import '../domain/models/parsed_transaction.dart';
import '../domain/models/transaction.dart' as domain;
import '../domain/repositories/transaction_repository.dart';

/// Decides whether a newly-parsed transaction is the same real-world payment
/// as one already stored, or a genuinely new one.
///
/// The same payment usually arrives twice — once as a bank SMS, once as a
/// UPI app notification — and occasionally a notification listener fires
/// twice for the same event. Matching rules, in priority order:
///  1. Same reference id (UTR/RRN) -> always the same payment.
///  2. Same amount, seen through a *different* channel, within [mergeWindow]
///     -> the same payment arriving via its other channel.
///  3. Same amount, same channel, same payee, within [repeatWindow]
///     -> a duplicate delivery of the same event.
///
/// Pure Dart, works only against [TransactionRepository], so it's
/// unit-testable with a fake/mock repository.
class DuplicateDetector {
  DuplicateDetector(
    this._repository, {
    Duration mergeWindow = const Duration(minutes: 5),
    Duration repeatWindow = const Duration(seconds: 60),
  })  : _mergeWindow = mergeWindow,
        _repeatWindow = repeatWindow;

  final TransactionRepository _repository;
  final Duration _mergeWindow;
  final Duration _repeatWindow;

  /// Returns the existing transaction [parsed] should be merged into, or
  /// null if it's new and should be inserted as its own row.
  Future<domain.Transaction?> findDuplicate(ParsedTransaction parsed) async {
    final refId = parsed.referenceId;
    if (refId != null && refId.isNotEmpty) {
      final byRef = await _repository.findByReferenceId(refId);
      if (byRef.isNotEmpty) return _closestInTime(byRef, parsed.occurredAt);
    }

    final candidates = await _repository.findByAmountNear(
      parsed.amountPaise,
      parsed.occurredAt,
      _mergeWindow,
    );
    if (candidates.isEmpty) return null;

    final crossSource = candidates.where((c) => !c.sourceList.contains(parsed.sourceType.name)).toList();
    if (crossSource.isNotEmpty) return _closestInTime(crossSource, parsed.occurredAt);

    final sameChannelRepeats = candidates.where((c) {
      if (!c.sourceList.contains(parsed.sourceType.name)) return false;
      if (parsed.occurredAt.difference(c.occurredAt).abs() > _repeatWindow) return false;
      return _samePayee(c, parsed);
    }).toList();
    if (sameChannelRepeats.isNotEmpty) return _closestInTime(sameChannelRepeats, parsed.occurredAt);

    return null;
  }

  bool _samePayee(domain.Transaction existing, ParsedTransaction parsed) {
    final existingKey = (existing.upiId ?? existing.merchantName)?.toLowerCase();
    final parsedKey = (parsed.upiId ?? parsed.merchantName)?.toLowerCase();
    return existingKey == parsedKey;
  }

  domain.Transaction _closestInTime(List<domain.Transaction> candidates, DateTime around) {
    final sorted = [...candidates]
      ..sort((a, b) => a.occurredAt.difference(around).abs().compareTo(b.occurredAt.difference(around).abs()));
    return sorted.first;
  }
}
