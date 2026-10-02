/// Where a [RawEvent] (and later a stored transaction) originated from.
enum SourceType {
  sms,
  notification,
  manual;

  static SourceType fromName(String name) =>
      SourceType.values.firstWhere((t) => t.name == name);
}
