import 'package:flutter/services.dart';

import '../domain/models/raw_event.dart';
import '../domain/models/transaction_source.dart';

/// Converts one raw SMS event payload (as sent by Kotlin's SmsEventBridge)
/// into a domain [RawEvent]. Pure and unit-testable without a platform
/// channel: missing/malformed fields degrade to sensible defaults rather
/// than throwing, since a bad payload shouldn't crash the app.
RawEvent smsRawEventFromPayload(Object? payload) {
  final map = Map<Object?, Object?>.from(payload as Map);
  final receivedAtMillis = (map['receivedAt'] as num?)?.toInt();
  return RawEvent(
    sourceType: SourceType.sms,
    origin: map['origin'] as String? ?? '',
    text: map['text'] as String? ?? '',
    receivedAt:
        receivedAtMillis == null ? DateTime.now() : DateTime.fromMillisecondsSinceEpoch(receivedAtMillis),
  );
}

/// Converts one raw notification event payload (as sent by Kotlin's
/// NotificationEventBridge) into a domain [RawEvent]. Title and text are
/// combined into the single "title | text" form the notification parsers
/// expect, skipping whichever half is blank rather than leaving a stray "|".
RawEvent notificationRawEventFromPayload(Object? payload) {
  final map = Map<Object?, Object?>.from(payload as Map);
  final title = map['title'] as String? ?? '';
  final text = map['text'] as String? ?? '';
  final combined = [title, text].where((s) => s.isNotEmpty).join(' | ');
  final receivedAtMillis = (map['receivedAt'] as num?)?.toInt();
  return RawEvent(
    sourceType: SourceType.notification,
    origin: map['packageName'] as String? ?? '',
    text: combined,
    receivedAt:
        receivedAtMillis == null ? DateTime.now() : DateTime.fromMillisecondsSinceEpoch(receivedAtMillis),
  );
}

/// Dispatches a headless-mode payload (sent by Kotlin's HeadlessEngineManager,
/// which tags each payload with a `kind` so a single background entrypoint
/// can handle both SMS and notification events) to the matching converter
/// above. Returns null for an unrecognized/missing kind rather than
/// throwing — the caller can simply skip processing that event.
RawEvent? headlessRawEventFromArguments(Object? arguments) {
  final map = Map<Object?, Object?>.from(arguments as Map);
  return switch (map['kind'] as String?) {
    'sms' => smsRawEventFromPayload(map),
    'notification' => notificationRawEventFromPayload(map),
    _ => null,
  };
}

/// Wraps the native event channels that stream captured SMS/notification
/// text from Kotlin into Dart. Kotlin does capture only — no parsing.
class NativeBridge {
  static const _smsEventsChannel = EventChannel('upi_tracker/sms_events');
  static const _notificationEventsChannel = EventChannel('upi_tracker/notification_events');

  Stream<RawEvent> get smsEvents => _smsEventsChannel.receiveBroadcastStream().map(smsRawEventFromPayload);

  Stream<RawEvent> get notificationEvents =>
      _notificationEventsChannel.receiveBroadcastStream().map(notificationRawEventFromPayload);
}
