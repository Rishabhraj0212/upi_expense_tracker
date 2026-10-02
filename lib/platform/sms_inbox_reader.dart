import 'package:flutter/services.dart';

import '../domain/models/raw_event.dart';
import '../domain/models/transaction_source.dart';

/// Reads historical SMS from the Android SMS inbox via a MethodChannel.
/// Each message is returned as a [RawEvent] identical to what the real-time
/// [SmsReceiver] would produce, so the same parser/ingestion pipeline
/// handles both paths.
class SmsInboxReader {
  static const _channel = MethodChannel('upi_tracker/platform');

  /// Returns the total number of inbox SMS within the given time window.
  Future<int> getCount({required DateTime since, required DateTime until}) async {
    final count = await _channel.invokeMethod<int>('getSmsInboxCount', {
      'sinceMs': since.millisecondsSinceEpoch,
      'untilMs': until.millisecondsSinceEpoch,
    });
    return count ?? 0;
  }

  /// Returns a batch of SMS messages as [RawEvent]s.
  ///
  /// [offset] and [limit] control pagination; messages are ordered by date
  /// ascending so offset is stable across pages.
  Future<List<RawEvent>> readBatch({
    required DateTime since,
    required DateTime until,
    required int offset,
    int limit = 100,
  }) async {
    final results = await _channel.invokeMethod<List<Object?>>('readSmsInbox', {
      'sinceMs': since.millisecondsSinceEpoch,
      'untilMs': until.millisecondsSinceEpoch,
      'offset': offset,
      'limit': limit,
    });
    if (results == null) return [];

    return results.map((item) {
      final map = Map<Object?, Object?>.from(item as Map);
      final dateMs = (map['dateMs'] as num?)?.toInt();
      return RawEvent(
        sourceType: SourceType.sms,
        origin: map['address'] as String? ?? '',
        text: map['body'] as String? ?? '',
        receivedAt: dateMs == null
            ? DateTime.now()
            : DateTime.fromMillisecondsSinceEpoch(dateMs),
      );
    }).toList();
  }
}
