import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/data/model/invoice_response_model.dart';
import 'package:smartlogisticssystem/feature/inventory/widgets/api_error_message.dart';
import 'package:smartlogisticssystem/feature/invoice/services/invoice_service.dart';
import 'package:smartlogisticssystem/widgets/dashboard_widgets.dart';

class FinancialDashboardScreen extends StatefulWidget {
  const FinancialDashboardScreen({super.key});

  @override
  State<FinancialDashboardScreen> createState() =>
      _FinancialDashboardScreenState();
}

class _FinancialDashboardScreenState extends State<FinancialDashboardScreen> {
  final InvoiceService _service = InvoiceService();
  late final Future<DashboardStatsResponse> _future =
      _service.getDashboardStats();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardStatsResponse>(
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
                const Icon(Icons.error_outline,
                    color: AppColors.danger, size: 64),
                const SizedBox(height: 16),
                Text(
                  'Lỗi tải dữ liệu: ${apiErrorMessage(snapshot.error!)}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data;
        if (data == null) {
          return const Center(
            child: Text('Không có dữ liệu',
                style: TextStyle(color: AppColors.textSecondary)),
          );
        }

        return _DashboardBody(stats: data);
      },
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final DashboardStatsResponse stats;

  const _DashboardBody({required this.stats});

  @override
  Widget build(BuildContext context) {
    final revenueFormatted = NumberFormat('#,##0', 'vi_VN')
        .format(stats.totalRevenueThisMonth);
    final ratioFormatted =
        stats.damagedInventoryRatio.toStringAsFixed(1);
    final currentMonth =
        DateFormat('MM/yyyy').format(DateTime.now());

    return PageScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section A: KPI Cards ────────────────────────────────────────
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
                    title: 'Doanh thu tháng $currentMonth',
                    value: '$revenueFormatted ₫',
                    subtitle: 'Tổng hóa đơn tháng này',
                    icon: Icons.payments_outlined,
                    color: AppColors.primary,
                  ),
                  StatCard(
                    title: 'Đơn hàng đã giao',
                    value: '${stats.totalDeliveredOrders}',
                    subtitle: 'Delivered',
                    icon: Icons.local_shipping_outlined,
                    color: AppColors.success,
                  ),
                  StatCard(
                    title: 'Hàng hư hỏng',
                    value: '$ratioFormatted%',
                    subtitle: 'Tỉ lệ lô hàng Damaged',
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.warning,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),

          // ── Section B + C: Charts side by side ──────────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 800) {
                return Column(
                  children: [
                    _RevenueBarChart(stats: stats),
                    const SizedBox(height: 16),
                    _InventoryPieChart(stats: stats),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _RevenueBarChart(stats: stats)),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: _InventoryPieChart(stats: stats)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Bar Chart ────────────────────────────────────────────────────────────────

class _RevenueBarChart extends StatelessWidget {
  final DashboardStatsResponse stats;

  const _RevenueBarChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Build last-6-months labels; only the current month has real data
    final months = List.generate(6, (i) {
      final d = DateTime(now.year, now.month - 5 + i, 1);
      return DateFormat('MM/yy').format(d);
    });

    final barGroups = List.generate(6, (i) {
      final isCurrentMonth = i == 5;
      final value = isCurrentMonth ? stats.totalRevenueThisMonth : 0.0;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: value,
            color: isCurrentMonth
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.25),
            width: 28,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });

    final maxY = stats.totalRevenueThisMonth > 0
        ? stats.totalRevenueThisMonth * 1.3
        : 1000000.0;

    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Doanh thu theo tháng'),
          const SizedBox(height: 8),
          const Text(
            'Tháng hiện tại hiển thị dữ liệu thực; các tháng trước chưa có dữ liệu.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                barGroups: barGroups,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.border,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        final label = value >= 1000000
                            ? '${(value / 1000000).toStringAsFixed(0)}M'
                            : '${(value / 1000).toStringAsFixed(0)}K';
                        return Text(
                          label,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= months.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            months[idx],
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) =>
                        AppColors.textPrimary.withValues(alpha: 0.85),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final formatted = NumberFormat('#,##0', 'vi_VN')
                          .format(rod.toY);
                      return BarTooltipItem(
                        '$formatted ₫',
                        const TextStyle(color: Colors.white, fontSize: 12),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pie Chart ────────────────────────────────────────────────────────────────

class _InventoryPieChart extends StatefulWidget {
  final DashboardStatsResponse stats;

  const _InventoryPieChart({required this.stats});

  @override
  State<_InventoryPieChart> createState() => _InventoryPieChartState();
}

class _InventoryPieChartState extends State<_InventoryPieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final damaged = widget.stats.damagedInventoryRatio.clamp(0.0, 100.0);
    final good = (100.0 - damaged).clamp(0.0, 100.0);

    final sections = [
      PieChartSectionData(
        value: good,
        color: AppColors.success,
        title: good > 5 ? '${good.toStringAsFixed(1)}%' : '',
        radius: _touchedIndex == 0 ? 68 : 60,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
      PieChartSectionData(
        value: damaged > 0 ? damaged : 0.001,
        color: AppColors.danger,
        title: damaged > 5 ? '${damaged.toStringAsFixed(1)}%' : '',
        radius: _touchedIndex == 1 ? 68 : 60,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    ];

    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Tình trạng kho hàng'),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    if (event.isInterestedForInteractions &&
                        response?.touchedSection != null) {
                      setState(() {
                        _touchedIndex = response!
                            .touchedSection!.touchedSectionIndex;
                      });
                    } else {
                      setState(() => _touchedIndex = -1);
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: AppColors.success, label: 'Tốt (Good)'),
              const SizedBox(width: 20),
              _LegendDot(color: AppColors.danger, label: 'Hư hỏng (Damaged)'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
