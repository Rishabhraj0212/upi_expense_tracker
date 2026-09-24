/// Maps an SMS sender id (e.g. "AD-HDFCBK-S", "JD-SBIINB") to a readable
/// bank name. New banks are a one-line addition here.
class BankDirectory {
  BankDirectory._();

  static const Map<String, String> _markers = {
    'HDFC': 'HDFC Bank',
    'SBI': 'State Bank of India',
    'ICICI': 'ICICI Bank',
    'AXIS': 'Axis Bank',
    'KOTAK': 'Kotak Mahindra Bank',
    'IDFC': 'IDFC FIRST Bank',
    'PNB': 'Punjab National Bank',
    'BARODA': 'Bank of Baroda',
    'BOB': 'Bank of Baroda',
    'CANBK': 'Canara Bank',
    'CANARA': 'Canara Bank',
    'UNIONB': 'Union Bank of India',
    'UBIN': 'Union Bank of India',
    'YESBNK': 'Yes Bank',
    'YESBANK': 'Yes Bank',
    'INDUS': 'IndusInd Bank',
    'BOI': 'Bank of India',
    'CENTBK': 'Central Bank of India',
    'IDBI': 'IDBI Bank',
    'RBLBNK': 'RBL Bank',
    'FEDBNK': 'Federal Bank',
  };

  static String? fromSenderId(String origin) {
    final upper = origin.toUpperCase();
    for (final entry in _markers.entries) {
      if (upper.contains(entry.key)) return entry.value;
    }
    return null;
  }
}
