import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_keys.dart';
import '../config/payment_deep_link_config.dart';
import '../models/order_model.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import '../services/payment_deep_link_controller.dart';
import '../utils/app_theme.dart';
import 'home_screen.dart';

enum _PaymentUiPhase {
  verifying,
  failed,
  pending,
  missingOrderId,
  authRequired,
  networkError,
}

/// Shown when app opens via `myapp://payment-result?order_id=...`.
///
/// **Security:** Payment success is determined only from `GET /api/Order/{id}` — never from the URL.
class PaymentResultScreen extends StatefulWidget {
  /// `null` means the deep link had no valid `order_id`.
  final String? orderId;

  const PaymentResultScreen({super.key, required this.orderId});

  @override
  State<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends State<PaymentResultScreen> {
  static final Map<String, Future<void>> _inFlightByOrderId = {};

  _PaymentUiPhase _phase = _PaymentUiPhase.verifying;
  String? _errorMessage;
  int _pollAttempts = 0;
  static const int _maxPendingPolls = 5;
  static const Duration _verifyTimeout = Duration(seconds: 30);
  static const Duration _pendingPollDelay = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    if (widget.orderId == null || widget.orderId!.isEmpty) {
      _phase = _PaymentUiPhase.missingOrderId;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _startVerification());
  }

  Future<void> _startVerification() async {
    final id = widget.orderId;
    if (id == null || id.isEmpty) return;

    final auth = Provider.of<AuthService>(context, listen: false);
    if (!auth.isAuthenticated) {
      setState(() => _phase = _PaymentUiPhase.authRequired);
      return;
    }

    await PaymentDeepLinkController.clearPendingOrderId();

    final existing = _inFlightByOrderId[id];
    if (existing != null) {
      await existing;
      return;
    }

    final future = _verifyOnce(id, auth);
    _inFlightByOrderId[id] = future;
    try {
      await future;
    } finally {
      _inFlightByOrderId.remove(id);
    }
  }

  Future<void> _verifyOnce(String orderId, AuthService auth) async {
    setState(() {
      _phase = _PaymentUiPhase.verifying;
      _errorMessage = null;
    });

    debugPrint('[PaymentResult] Verifying order_id=$orderId via GET /api/Order/{id}');

    try {
      final response = await OrderService.getOrderById(
        authService: auth,
        orderId: orderId,
      ).timeout(_verifyTimeout);

      debugPrint(
        '[PaymentResult] API success=${response.success} message=${response.message} data=${response.data?.status}',
      );

      if (!mounted) return;

      if (!response.success || response.data == null) {
        setState(() {
          _phase = _PaymentUiPhase.networkError;
          _errorMessage = response.message.isNotEmpty
              ? response.message
              : 'Could not verify payment.';
        });
        return;
      }

      final status = response.data!.status;
      switch (status) {
        case OrderStatus.completed:
          await _goHomeWithSuccessSnack();
          return;
        case OrderStatus.cancelled:
        case OrderStatus.refunded:
          setState(() {
            _phase = _PaymentUiPhase.failed;
            _errorMessage = 'Payment was not completed.';
          });
          return;
        case OrderStatus.pending:
          if (_pollAttempts < _maxPendingPolls) {
            _pollAttempts++;
            setState(() => _phase = _PaymentUiPhase.pending);
            await Future<void>.delayed(_pendingPollDelay);
            if (!mounted) return;
            await _verifyOnce(orderId, auth);
          } else {
            setState(() {
              _phase = _PaymentUiPhase.pending;
              _errorMessage =
                  'Payment is still processing. Please check My orders later.';
            });
          }
          return;
      }
    } catch (e, st) {
      debugPrint('[PaymentResult] Verification error: $e\n$st');
      if (!mounted) return;
      setState(() {
        _phase = _PaymentUiPhase.networkError;
        _errorMessage = e is TimeoutException
            ? 'Request timed out. Please try again.'
            : 'Network error. Please try again.';
      });
    }
  }

  Future<void> _goHomeWithSuccessSnack() async {
    appNavigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      (route) => false,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      appScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Payment completed successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case _PaymentUiPhase.verifying:
        return _buildCentered(
          icon: Icons.verified_user_outlined,
          title: 'Verifying your payment...',
          subtitle: 'Please wait while we confirm with the server.',
          showSpinner: true,
        );
      case _PaymentUiPhase.pending:
        return _buildCentered(
          icon: Icons.hourglass_top_rounded,
          title: 'Payment pending',
          subtitle: _errorMessage ??
              'We are still confirming your payment. You can retry or open orders later.',
          showSpinner: false,
          actions: [
            FilledButton(
              onPressed: () {
                _pollAttempts = 0;
                _startVerification();
              },
              child: const Text('Retry'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      case _PaymentUiPhase.failed:
        return _buildCentered(
          icon: Icons.error_outline,
          title: 'Payment failed',
          subtitle: _errorMessage ?? 'Payment failed. Please try again.',
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      case _PaymentUiPhase.missingOrderId:
        return _buildCentered(
          icon: Icons.link_off,
          title: 'Invalid link',
          subtitle:
              'Missing ${PaymentDeepLinkConfig.orderIdQueryKey}. Open the app from the payment completion link.',
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      case _PaymentUiPhase.authRequired:
        return _buildCentered(
          icon: Icons.lock_outline,
          title: 'Sign in required',
          subtitle:
              'Sign in to verify your payment with the server. Your order was saved for after login.',
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Sign in'),
            ),
          ],
        );
      case _PaymentUiPhase.networkError:
        return _buildCentered(
          icon: Icons.wifi_off_outlined,
          title: 'Could not verify',
          subtitle: _errorMessage ?? 'Please try again.',
          actions: [
            FilledButton(
              onPressed: () {
                _pollAttempts = 0;
                _startVerification();
              },
              child: const Text('Retry'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
    }
  }

  Widget _buildCentered({
    required IconData icon,
    required String title,
    required String subtitle,
    bool showSpinner = false,
    List<Widget>? actions,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: AppTheme.primaryColor),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
            if (showSpinner) ...[
              const SizedBox(height: 28),
              const CircularProgressIndicator(),
            ],
            if (actions != null && actions.isNotEmpty) ...[
              const SizedBox(height: 28),
              ...actions.map((w) => Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: w,
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
