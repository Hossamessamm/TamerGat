import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_keys.dart';
import '../config/payment_deep_link_config.dart';
import '../screens/payment_result_screen.dart';
import 'auth_service.dart';

/// Handles `myapp://payment-result?...` safely: logs, dedupes, routes to [PaymentResultScreen].
///
/// Does **not** trust URL for payment success — verification happens on [PaymentResultScreen].
class PaymentDeepLinkController {
  PaymentDeepLinkController._();
  static final PaymentDeepLinkController instance = PaymentDeepLinkController._();

  static const String _prefsPendingOrderId = 'pending_payment_order_id';
  static const String _analyticsEvent = 'payment_redirect_received';

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  /// In-memory debounce: ignore same order id within this window.
  static const Duration _dedupeWindow = Duration(seconds: 3);

  String? _lastHandledOrderId;
  DateTime? _lastHandledAt;

  AuthService? _authService;

  bool _initialized = false;

  Future<void> init({
    required AuthService authService,
  }) async {
    if (_initialized) return;
    _initialized = true;
    _authService = authService;

    // Cold start / killed app
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        _handleUri(initial, source: 'initial_link');
      }
    } catch (e) {
      debugPrint('[PaymentDeepLink] getInitialLink error: $e');
    }

    _sub = _appLinks.uriLinkStream.listen(
      (uri) => _handleUri(uri, source: 'stream'),
      onError: (Object e) => debugPrint('[PaymentDeepLink] stream error: $e'),
    );
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }

  /// Persist order id when user must sign in before verification (optional helper).
  static Future<void> savePendingOrderIdForAuth(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsPendingOrderId, orderId);
  }

  /// Read and clear pending order id (call after successful login).
  static Future<String?> consumePendingOrderIdAfterAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_prefsPendingOrderId);
    if (v != null && v.isNotEmpty) {
      await prefs.remove(_prefsPendingOrderId);
      return v;
    }
    return null;
  }

  static Future<void> clearPendingOrderId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsPendingOrderId);
  }

  void _handleUri(Uri uri, {required String source}) {
    debugPrint('[PaymentDeepLink] Received ($source): $uri');

    if (!PaymentDeepLinkConfig.isPaymentResultUri(uri)) {
      debugPrint('[PaymentDeepLink] Ignored (not payment-result): scheme=${uri.scheme} host=${uri.host}');
      return;
    }

    final orderId = PaymentDeepLinkConfig.parseOrderId(uri);
    debugPrint('[PaymentDeepLink] Extracted order_id: $orderId');

    if (orderId == null || orderId.isEmpty) {
      debugPrint('[PaymentDeepLink] Missing order_id — routing to error screen');
      _pushPaymentScreen(orderId: null);
      return;
    }

    // Analytics (bonus): console in debug; hook Firebase later if needed.
    debugPrint('[PaymentDeepLink] analytics: $_analyticsEvent order_id=$orderId');

    final now = DateTime.now();
    if (_lastHandledOrderId == orderId &&
        _lastHandledAt != null &&
        now.difference(_lastHandledAt!) < _dedupeWindow) {
      debugPrint('[PaymentDeepLink] Deduped duplicate for order_id=$orderId');
      return;
    }
    _lastHandledOrderId = orderId;
    _lastHandledAt = now;

    final auth = _authService;
    if (auth != null && !auth.isAuthenticated) {
      unawaited(savePendingOrderIdForAuth(orderId));
    }

    _pushPaymentScreen(orderId: orderId);
  }

  void _pushPaymentScreen({required String? orderId}) {
    final nav = appNavigatorKey.currentState;
    if (nav == null) {
      debugPrint('[PaymentDeepLink] Navigator not ready — cannot push PaymentResultScreen');
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!nav.mounted) return;
      nav.push(
        MaterialPageRoute<void>(
          fullscreenDialog: false,
          builder: (_) => PaymentResultScreen(orderId: orderId),
        ),
      );
    });
  }
}
