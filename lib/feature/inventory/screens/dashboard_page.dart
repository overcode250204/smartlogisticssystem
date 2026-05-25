import 'package:flutter/material.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/feature/inventory/services/inventory_service.dart';
import 'package:smartlogisticssystem/widgets/dashboard_widgets.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final InventoryService _service = InventoryService();
  late final Future<InventoryDashboardData> _future = _service.fetchDashboardData();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<InventoryDashboardData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppColors.danger, size: 64),
                const SizedBox(height: 16),
                Text(
                  'Lỗi tải dữ liệu: ${snapshot.error}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data;
        if (data == null) {
          return const Center(
            child: Text('Không có dữ liệu', style: TextStyle(color: AppColors.textSecondary)),
          );
        }

        final totalProducts = data.products.length;
        final totalBatches = data.batches.length;
        
        final lowStockBatches = data.batches.where((b) {
          final minStock = b.product?.minStockLevel ?? 0;
          return b.remainingQuantity <= minStock;
        }).toList();

        final recentTransactions = data.transactions.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final topTransactions = recentTransactions.take(5).toList();

        return PageScroll(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth < 900 ? 1 : 3;
                  return GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: columns == 1 ? 4.5 : 2.2,
                    children: [
                      StatCard(
                        title: 'Tổng sản phẩm',
                        value: '$totalProducts',
                        subtitle: 'Sản phẩm',
                        icon: Icons.inventory_2_outlined,
                        color: AppColors.primary,
                      ),
                      StatCard(
                        title: 'Tổng lô hàng',
                        value: '$totalBatches',
                        subtitle: 'Lô hàng',
                        icon: Icons.all_inbox_outlined,
                        color: AppColors.success,
                      ),
                      StatCard(
                        title: 'Sắp hết hàng',
                        value: '${lowStockBatches.length}',
                        subtitle: 'Sản phẩm',
                        icon: Icons.warning_amber_rounded,
                        color: AppColors.warning,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DashboardCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionTitle('Giao dịch gần đây'),
                          const SizedBox(height: 12),
                          if (topTransactions.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('Chưa có giao dịch', style: TextStyle(color: AppColors.textSecondary)),
                            )
                          else
                            ...topTransactions.map(
                              (item) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text('GD${item.transactionId ?? ''}'),
                                subtitle: Text(
                                  dateTimeFormatter.format(item.createdAt),
                                ),
                                trailing: StatusPill.transaction(item.type),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DashboardCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionTitle('Cảnh báo tồn kho thấp'),
                          const SizedBox(height: 12),
                          if (lowStockBatches.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('Không có cảnh báo', style: TextStyle(color: AppColors.textSecondary)),
                            )
                          else
                            ...lowStockBatches.map(
                              (item) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text('${item.productName} (LH${item.batchId ?? ''})'),
                                subtitle: Text(
                                  'Còn ${item.remainingQuantity} (Tối thiểu: ${item.product?.minStockLevel ?? 0})',
                                ),
                                trailing: const Icon(
                                  Icons.warning_amber_rounded,
                                  color: AppColors.warning,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
