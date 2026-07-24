import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/data/model/order_response_model.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomerInfoCard extends StatelessWidget {
  final OrderResponse order;

  const CustomerInfoCard({super.key, required this.order});

  Future<void> _callCustomer(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: order.phone);
    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở ứng dụng gọi điện')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final amountFormat = NumberFormat.decimalPattern('vi_VN');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                order.customerName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            IconButton(
              onPressed: () => _callCustomer(context),
              icon: const Icon(Icons.call, color: AppColors.success),
              tooltip: 'Gọi khách hàng',
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          order.deliveryAddress,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(
          '${amountFormat.format(order.totalAmount)} đ • ${order.orderCode}',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
