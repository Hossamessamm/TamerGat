import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/course_model.dart';
import '../models/order_model.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import '../utils/app_theme.dart';
import 'course_details_screen.dart';
import 'home_screen.dart';

/// In-app payment WebView. Polls [GET /api/Order/{orderId}] every 10s until final status.
class PaymentGatewayScreen extends StatefulWidget {
  final String paymentUrl;
  final String? title;

  /// Required for status polling while this screen is open.
  final String orderId;

  /// Used after successful payment to open [CourseDetailsScreen]. If null, success goes to [HomeScreen] with a message.
  final Course? courseOnSuccess;

  const PaymentGatewayScreen({
    super.key,
    required this.paymentUrl,
    required this.orderId,
    this.title,
    this.courseOnSuccess,
  });

  @override
  State<PaymentGatewayScreen> createState() => _PaymentGatewayScreenState();
}

class _PaymentGatewayScreenState extends State<PaymentGatewayScreen> {
  late final WebViewController _controller;
  int _progress = 0;
  String? _lastUrl;

  Timer? _pollTimer;
  bool _pollInFlight = false;
  bool _handledFinalStatus = false;

  static const Duration _pollInterval = Duration(seconds: 10);

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppTheme.backgroundColor)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) {
            if (!mounted) return;
            setState(() => _progress = p);
          },
          onUrlChange: (change) {
            _lastUrl = change.url;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));

    WidgetsBinding.instance.addPostFrameCallback((_) => _startOrderStatusPolling());
  }

  void _startOrderStatusPolling() {
    if (widget.orderId.isEmpty) return;
    _schedulePoll();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _schedulePoll());
  }

  void _schedulePoll() {
    if (_handledFinalStatus || !mounted) return;
    unawaited(_pollOrderOnce());
  }

  Future<void> _pollOrderOnce() async {
    if (_handledFinalStatus || !mounted || _pollInFlight) return;
    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.token == null) return;

    _pollInFlight = true;
    try {
      final response = await OrderService.getOrderById(
        authService: auth,
        orderId: widget.orderId,
      );
      if (!mounted || _handledFinalStatus) return;

      if (!response.success || response.data == null) {
        return;
      }

      final status = response.data!.status;
      switch (status) {
        case OrderStatus.completed:
          _handledFinalStatus = true;
          _pollTimer?.cancel();
          _pollTimer = null;
          await _showSuccessAndNavigate();
          return;
        case OrderStatus.cancelled:
        case OrderStatus.refunded:
          _handledFinalStatus = true;
          _pollTimer?.cancel();
          _pollTimer = null;
          await _showFailureAndGoHome();
          return;
        case OrderStatus.pending:
          break;
      }
    } catch (_) {
      // Transient errors: keep polling on next tick.
    } finally {
      _pollInFlight = false;
    }
  }

  Future<void> _showSuccessAndNavigate() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 48),
        title: const Text('Payment successful'),
        content: const Text('Your enrollment is confirmed.'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (!mounted) return;

    final course = widget.courseOnSuccess;
    if (course != null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => CourseDetailsScreen(course: course),
        ),
        (route) => route.isFirst,
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _showFailureAndGoHome() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 48),
        title: const Text('Payment not completed'),
        content: const Text('This payment was cancelled or refunded.'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pollTimer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          Material(
            color: AppTheme.primaryColor,
            elevation: 2,
            child: SizedBox(
              height: kToolbarHeight + topInset,
              child: Padding(
                padding: EdgeInsets.only(top: topInset),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context, _lastUrl),
                    ),
                    Expanded(
                      child: Text(
                        widget.title ?? 'Payment',
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),
          if (_progress < 100)
            LinearProgressIndicator(
              value: _progress / 100,
              minHeight: 2,
            ),
          const SizedBox(height: 1),
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }
}
