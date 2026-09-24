import 'transaction_source.dart';

/// The unprocessed payload handed from the native side (Kotlin) to Dart.
///
/// This is deliberately minimal: Kotlin does no parsing, so this is just
/// "here is some text and where it came from".
class RawEvent {
  const RawEvent({
    required this.sourceType,
    required this.origin,
    required this.text,
    required this.receivedAt,
  });

  final SourceType sourceType;

  /// SMS sender address (e.g. "HDFCBK") or notification package/app label
  /// (e.g. "com.google.android.apps.nbu.paisa.user").
  final String origin;

  /// Raw SMS body, or "title | text" for a notification.
  final String text;

  final DateTime receivedAt;
}
