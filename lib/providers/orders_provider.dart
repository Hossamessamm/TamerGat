import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/order_model.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';

/// Provider for fetching and refreshing the current user's orders list.
class OrdersProvider extends ChangeNotifier {
  final AuthService authService;

  bool _isLoading = false;
  String? _error;
  MyOrdersResponse? _response;

  Timer? _pollTimer;

  OrdersProvider({required this.authService});

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<OrderDto> get orders => _response?.orders ?? const <OrderDto>[];
  MyOrdersResponse? get response => _response;

  Future<void> refresh({int pageNumber = 1, int pageSize = 10}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await OrderService.getMyOrders(
      authService: authService,
      pageNumber: pageNumber,
      pageSize: pageSize,
    );

    _isLoading = false;
    if (result.success && result.data != null) {
      _response = result.data;
    } else {
      _response = null;
      _error = result.message.isNotEmpty ? result.message : 'Failed to load orders';
    }
    notifyListeners();
  }

  /// Poll `my-orders` until `orderId` becomes final, or until max attempts.
  Future<void> pollMyOrdersUntilFinalStatus({
    String? orderId,
    Duration interval = const Duration(seconds: 8),
    int maxAttempts = 18,
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    _pollTimer?.cancel();

    var attempts = 0;
    _pollTimer = Timer.periodic(interval, (_) async {
      attempts++;
      await refresh(pageNumber: pageNumber, pageSize: pageSize);

      final list = _response?.orders ?? const <OrderDto>[];
      final matchOrder = orderId == null
          ? null
          : list.cast<OrderDto?>().firstWhere(
                (o) => o?.id == orderId,
                orElse: () => null,
              );

      final ordersToCheck = <OrderDto>[];
      if (matchOrder != null) {
        ordersToCheck.add(matchOrder);
      } else {
        ordersToCheck.addAll(list);
      }

      final hasFinal = ordersToCheck.any((o) =>
          o.status == OrderStatus.completed ||
          o.status == OrderStatus.cancelled ||
          o.status == OrderStatus.refunded);

      if (hasFinal || attempts >= maxAttempts) {
        _pollTimer?.cancel();
        _pollTimer = null;
      }
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}

