/// Custom URL scheme for payment return from hosted gateway (web redirect → app).
///
/// Example: `myapp://payment-result?order_id=<guid>`
class PaymentDeepLinkConfig {
  PaymentDeepLinkConfig._();

  static const String scheme = 'myapp';
  static const String host = 'payment-result';

  /// Query parameter for order id (required).
  static const String orderIdQueryKey = 'order_id';

  static bool isPaymentResultUri(Uri uri) {
    if (uri.scheme != scheme) return false;
    final h = uri.host.toLowerCase();
    return h == host.toLowerCase();
  }

  /// Returns order id or null if missing/invalid.
  static String? parseOrderId(Uri uri) {
    if (!isPaymentResultUri(uri)) return null;
    final raw = uri.queryParameters[orderIdQueryKey] ??
        uri.queryParameters['orderId'] ??
        uri.queryParameters['id'];
    if (raw == null || raw.trim().isEmpty) return null;
    return raw.trim();
  }
}
