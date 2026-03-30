import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/order_model.dart';
import '../models/promo_validation_model.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import '../services/promo_code_service.dart';

/// Checkout state for a single-course purchase flow:
/// - validate promo
/// - create order
/// - poll order status until it is finalized by the backend webhook
class CheckoutProvider extends ChangeNotifier {
  final AuthService authService;

  bool _isValidatingPromo = false;
  bool _isCreatingOrder = false;
  bool _isPollingOrder = false;

  PromoValidationResponse? promoValidation;
  String? promoError;

  OrderDto? currentOrder;
  String? checkoutError;

  Timer? _pollTimer;
  bool _pollRequestInFlight = false;
  int _pollAttempts = 0;

  CheckoutProvider({required this.authService});

  bool get isValidatingPromo => _isValidatingPromo;
  bool get isCreatingOrder => _isCreatingOrder;
  bool get isPollingOrder => _isPollingOrder;

  Future<void> validatePromoCode({
    required String courseId,
    required String promoCode,
  }) async {
    _isValidatingPromo = true;
    promoError = null;
    promoValidation = null;
    notifyListeners();

    try {
      final response = await PromoCodeService.validatePromoCode(
        authService: authService,
        promoCode: promoCode,
        courseId: courseId,
      );

      if (response.success && response.data != null) {
        promoValidation = response.data;
      } else {
        promoError = response.message.isNotEmpty ? response.message : 'Invalid promo code';
      }
    } catch (e) {
      promoError = e.toString();
    } finally {
      _isValidatingPromo = false;
      notifyListeners();
    }
  }

  void clearPromo() {
    promoValidation = null;
    promoError = null;
    notifyListeners();
  }

  Future<void> createOrder({
    required String courseId,
    String? promoCode,
    String? paymentReference,
  }) async {
    _isCreatingOrder = true;
    checkoutError = null;
    currentOrder = null;
    notifyListeners();

    try {
      final response = await OrderService.createOrder(
        authService: authService,
        courseId: courseId,
        promoCode: promoCode,
        paymentReference: paymentReference,
      );

      if (response.success && response.data != null) {
        currentOrder = response.data;
      } else {
        checkoutError = response.message.isNotEmpty ? response.message : 'Failed to create order';
      }
    } catch (e) {
      checkoutError = e.toString();
    } finally {
      _isCreatingOrder = false;
      notifyListeners();
    }
  }

  /// Poll an order until its status becomes final.
  /// Final statuses: completed, cancelled, refunded.
  Future<void> startPollingOrderStatus({
    required String orderId,
    Duration interval = const Duration(seconds: 6),
    int maxAttempts = 25,
  }) async {
    stopPolling();

    _isPollingOrder = true;
    _pollAttempts = 0;
    notifyListeners();

    _pollTimer = Timer.periodic(interval, (_) async {
      if (_pollRequestInFlight) return;
      _pollRequestInFlight = true;
      try {
        _pollAttempts++;
        final response = await OrderService.getOrderById(
          authService: authService,
          orderId: orderId,
        );

        if (response.success && response.data != null) {
          currentOrder = response.data;
          final st = currentOrder!.status;
          final isFinal = st == OrderStatus.completed ||
              st == OrderStatus.cancelled ||
              st == OrderStatus.refunded;
          notifyListeners();

          if (isFinal || _pollAttempts >= maxAttempts) {
            stopPolling();
          }
        }

        if (_pollAttempts >= maxAttempts) {
          stopPolling();
        }
      } catch (_) {
        // Keep polling; transient failures may recover.
      } finally {
        _pollRequestInFlight = false;
      }
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _pollRequestInFlight = false;
    _pollAttempts = 0;
    if (_isPollingOrder) {
      _isPollingOrder = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}

