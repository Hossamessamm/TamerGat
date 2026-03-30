import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/course_model.dart';
import '../models/order_model.dart';
import '../providers/orders_provider.dart';
import '../screens/payment_gateway_screen.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ordersProvider = Provider.of<OrdersProvider>(context, listen: false);
      ordersProvider.refresh();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final ordersProvider = Provider.of<OrdersProvider>(context, listen: false);
    final pending = ordersProvider.orders.where((o) => o.status == OrderStatus.pending).toList();
    if (pending.isNotEmpty) {
      ordersProvider.pollMyOrdersUntilFinalStatus(orderId: pending.first.id);
    } else {
      ordersProvider.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return ChangeNotifierProvider(
      create: (_) => OrdersProvider(authService: authService),
      child: Consumer<OrdersProvider>(
        builder: (context, orders, _) {
          return Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            appBar: AppBar(
              title: const Text('My Orders'),
            ),
            body: RefreshIndicator(
              onRefresh: () => orders.refresh(),
              child: Builder(
                builder: (context) {
                  if (orders.isLoading && orders.orders.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (orders.error != null && orders.orders.isEmpty) {
                    return ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 52, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        Text(orders.error!, style: const TextStyle(color: Colors.black54)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => orders.refresh(),
                          child: const Text('Retry'),
                        ),
                      ],
                    );
                  }

                  if (orders.orders.isEmpty) {
                    return const Center(
                      child: Text(
                        'No orders yet.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: orders.orders.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final order = orders.orders[index];
                      return _OrderCard(order: order);
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderDto order;

  const _OrderCard({required this.order});

  Future<void> _openPaymentUrl(BuildContext context) async {
    final url = order.paymentUrl;
    if (url == null || url.isEmpty) return;

    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentGatewayScreen(
          paymentUrl: url,
          orderId: order.id,
          title: 'Payment',
          courseOnSuccess: order.courseId != null && order.courseId!.isNotEmpty
              ? Course(
                  id: order.courseId!,
                  courseName: order.courseName ?? 'Course',
                  modificationDate: DateTime.now(),
                )
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusText = (() {
      switch (order.status) {
        case OrderStatus.pending:
          return 'Pending';
        case OrderStatus.completed:
          return 'Completed';
        case OrderStatus.cancelled:
          return 'Cancelled';
        case OrderStatus.refunded:
          return 'Refunded';
      }
    })();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    order.courseName ?? 'Course',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Colors.blue.withValues(alpha: 0.08),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Net: ${order.netPrice.toStringAsFixed(2)} EGP',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 6),
            if (order.promoCode != null && order.promoCode!.isNotEmpty)
              Text('Promo: ${order.promoCode}', style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 6),
            Text(
              'Order: ${order.orderDate.day}/${order.orderDate.month}/${order.orderDate.year}',
              style: const TextStyle(color: Colors.black54),
            ),
            if (order.paymentReference != null && order.paymentReference!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Payment ref: ${order.paymentReference}',
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
            if (order.paymentUrl != null && order.paymentUrl!.isNotEmpty) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () => _openPaymentUrl(context),
                icon: const Icon(Icons.open_in_browser_rounded),
                label: const Text('Open payment'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

