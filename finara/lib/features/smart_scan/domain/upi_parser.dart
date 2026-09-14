class UpiParser {
  static Map<String, String>? parseUri(String uriString) {
    if (!uriString.startsWith('upi://pay')) {
      return null;
    }
    try {
      final uri = Uri.parse(uriString);
      final pa = uri.queryParameters['pa']; // Payee Address
      final pn = uri.queryParameters['pn']; // Payee Name
      final am = uri.queryParameters['am']; // Amount
      
      if (pa == null) return null;

      return {
        'pa': pa,
        'pn': pn ?? '',
        'am': am ?? '',
      };
    } catch (e) {
      return null;
    }
  }
}
