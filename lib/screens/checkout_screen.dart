import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/course_model.dart';
import '../models/order_model.dart';
import '../models/promo_validation_model.dart';
import '../providers/checkout_provider.dart';
import '../screens/payment_gateway_screen.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';

class CheckoutScreen extends StatefulWidget {
  final Course course;

  const CheckoutScreen({super.key, required this.course});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> with WidgetsBindingObserver {
  final TextEditingController _promoController = TextEditingController();
  bool _completionHandled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _promoController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    if (!mounted) return;
    final checkoutProvider = Provider.of<CheckoutProvider>(context, listen: false);
    final order = checkoutProvider.currentOrder;
    if (order == null) return;

    // If order isn't final yet, resume polling.
    final st = order.status;
    final isFinal = st == OrderStatus.completed || st == OrderStatus.cancelled || st == OrderStatus.refunded;
    if (!isFinal) {
      checkoutProvider.startPollingOrderStatus(orderId: order.id);
    }
  }

  Future<void> _openPaymentUrl(String paymentUrl, String orderId) async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentGatewayScreen(
          paymentUrl: paymentUrl,
          orderId: orderId,
          title: 'Payment',
          courseOnSuccess: widget.course,
        ),
      ),
    );
  }

  bool _isFinalOrderStatus(OrderStatus status) =>
      status == OrderStatus.completed || status == OrderStatus.cancelled || status == OrderStatus.refunded;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return ChangeNotifierProvider(
      create: (_) => CheckoutProvider(authService: authService),
      child: Consumer<CheckoutProvider>(
        builder: (context, checkout, _) {
          // Auto-complete navigation when the order becomes final.
          final order = checkout.currentOrder;
          final isFinal = order != null && _isFinalOrderStatus(order.status);
          if (isFinal && !_completionHandled) {
            _completionHandled = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              final completed = order.status == OrderStatus.completed;
              Navigator.pop(context, completed);
            });
          }

          final price = widget.course.price;
          final basePrice = price ?? 0;

          final originalPrice = checkout.promoValidation?.originalPrice ?? basePrice;
          final discountAmount = checkout.promoValidation?.discountAmount ?? 0;
          final netPrice = checkout.promoValidation?.netPrice ?? basePrice;

          return Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            appBar: AppBar(
              title: const Text('Checkout'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () {
                  checkout.stopPolling();
                  Navigator.pop(context, false);
                },
              ),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCourseSummaryCard(originalPrice: basePrice),
                    const SizedBox(height: 16),
                    _buildPromoCard(
                      promoController: _promoController,
                      isValidating: checkout.isValidatingPromo,
                      errorText: checkout.promoError,
                      onValidate: () async {
                        final text = _promoController.text.trim();
                        if (text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Enter a promo code')),
                          );
                          return;
                        }
                        await checkout.validatePromoCode(
                          courseId: widget.course.id,
                          promoCode: text,
                        );
                      },
                      onClear: () {
                        _promoController.clear();
                        checkout.clearPromo();
                      },
                      promoValidation: checkout.promoValidation,
                    ),
                    const SizedBox(height: 16),
                    _buildPriceSummaryCard(
                      originalPrice: originalPrice,
                      discountAmount: discountAmount,
                      netPrice: netPrice,
                    ),
                    const SizedBox(height: 18),

                    if (checkout.checkoutError != null) ...[
                      Text(
                        checkout.checkoutError!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                      const SizedBox(height: 8),
                    ],

                    if (checkout.currentOrder == null) ...[
                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: checkout.isCreatingOrder
                              ? null
                              : () async {
                                  if (authService.token == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please login first')),
                                    );
                                    return;
                                  }
                                  final promo = _promoController.text.trim();
                                  await checkout.createOrder(
                                    courseId: widget.course.id,
                                    promoCode: promo.isNotEmpty ? promo : null,
                                  );

                                  final order = checkout.currentOrder;
                                  if (order == null) return;

                                  if (order.paymentUrl != null && order.paymentUrl!.isNotEmpty) {
                                    await _openPaymentUrl(order.paymentUrl!, order.id);
                                  }

                                  checkout.startPollingOrderStatus(orderId: order.id);
                                },
                          child: checkout.isCreatingOrder
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 3),
                                )
                              : const Text('Pay & enroll'),
                        ),
                      ),
                    ] else ...[
                      _buildOrderStatusCard(order: checkout.currentOrder!),
                      const SizedBox(height: 12),
                      if (checkout.isPollingOrder)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      const SizedBox(height: 6),
                      if (!checkout.isPollingOrder && !_isFinalOrderStatus(checkout.currentOrder!.status))
                        TextButton.icon(
                          onPressed: () {
                            checkout.startPollingOrderStatus(orderId: checkout.currentOrder!.id);
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Check payment status'),
                        ),
                    ],
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCourseSummaryCard({required double originalPrice}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.course.courseName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  widget.course.price != null && (widget.course.price ?? 0) > 0
                      ? Icons.payment_rounded
                      : Icons.lightbulb_outline_rounded,
                ),
                const SizedBox(width: 8),
                Text(
                  'Base price: ${originalPrice.toStringAsFixed(2)} EGP',
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoCard({
    required TextEditingController promoController,
    required bool isValidating,
    required String? errorText,
    required VoidCallback onClear,
    required Future<void> Function() onValidate,
    required PromoValidationResponse? promoValidation,
  }) {
    final discount = promoValidation?.discountAmount ?? 0;
    final net = promoValidation?.netPrice ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Promo code',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: promoController,
                    decoration: InputDecoration(
                      labelText: 'Enter code',
                      suffixIcon: promoController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                onClear();
                              },
                              icon: const Icon(Icons.clear_rounded),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: isValidating ? null : onValidate,
                    child: isValidating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          )
                        : const Text('Validate'),
                  ),
                ),
              ],
            ),
            if (errorText != null) ...[
              const SizedBox(height: 8),
              Text(
                errorText,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ],
            if (promoValidation != null && promoValidation.isValid) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Discount: ${discount.toStringAsFixed(2)} EGP',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'New net price: ${net.toStringAsFixed(2)} EGP',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSummaryCard({
    required double originalPrice,
    required double discountAmount,
    required double netPrice,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Price summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            _row('Original', '${originalPrice.toStringAsFixed(2)} EGP'),
            _row(
              'Discount',
              '${discountAmount.toStringAsFixed(2)} EGP',
            ),
            const Divider(),
            _row(
              'Total',
              '${netPrice.toStringAsFixed(2)} EGP',
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.black54)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusCard({required OrderDto order}) {
    final statusText = (() {
      switch (order.status) {
        case OrderStatus.pending:
          return 'Pending payment';
        case OrderStatus.completed:
          return 'Completed';
        case OrderStatus.cancelled:
          return 'Cancelled';
        case OrderStatus.refunded:
          return 'Refunded';
      }
    })();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text('Status: $statusText'),
            const SizedBox(height: 10),
            Text('Net price: ${order.netPrice.toStringAsFixed(2)} EGP'),
            if (order.promoCode != null && order.promoCode!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Promo: ${order.promoCode}'),
            ],
            const SizedBox(height: 6),
            Text('Order id: ${order.id}'),
            if (order.paymentSessionExpiresAt != null) ...[
              const SizedBox(height: 6),
              Text(
                'Payment session expires: ${order.paymentSessionExpiresAt}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
            if (order.paymentUrl != null && order.paymentUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => _openPaymentUrl(order.paymentUrl!, order.id),
                icon: const Icon(Icons.open_in_browser_rounded),
                label: const Text('Open payment again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

