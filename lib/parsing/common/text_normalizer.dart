final RegExp _lineBreaksAndRuns = RegExp(r'[\r\n]+|\s{2,}');

/// Collapses newlines, carriage returns (some senders use \r\n, some bare
/// \r), and runs of repeated whitespace into single spaces, so end-of-string
/// and whitespace-based regex assertions behave consistently regardless of
/// which line-ending style a message happened to use.
String normalizeMessageText(String text) => text.replaceAll(_lineBreaksAndRuns, ' ').trim();
