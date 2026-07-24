// File: lib/feature/trip_dashboard/screens/trip_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:smartlogisticssystem/core/app_theme.dart';
import 'package:smartlogisticssystem/widgets/dashboard_widgets.dart';
import 'package:smartlogisticssystem/widgets/api_error_message.dart';
import 'package:smartlogisticssystem/feature/trip_dashboard/models/trip_dashboard_models.dart';
import 'package:smartlogisticssystem/feature/trip_dashboard/service/trip_dashboard_service.dart';

class TripDashboardPage extends StatefulWidget {
  const TripDashboardPage({super.key});

  @override
  State<TripDashboardPage> createState() => _TripDashboardPageState();
}

class _TripDashboardPageState extends State<TripDashboardPage> {
  final LogisticsDashboardService _service = LogisticsDashboardService();
  
  // State filters
  String _timeFilter = 'MONTH'; // TODAY, WEEK, MONTH
  
  late Future<LogisticsDashboardData> _statsFuture;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  void _fetchStats() {
    setState(() {
      _statsFuture = _service.getDashboardStats(
        timeFilter: _timeFilter,
      );
    });
  }

  LatLng _getMapCenter() {
    return const LatLng(10.762622, 106.660172); // HCMC (Center for Last-Mile heatmap)
  }

  double _getMapZoom() {
    return 11.5;
  }

  List<Polygon> _getMockZonePolygons(List<ZoneHeatmapData> heatmapData) {
    final List<Polygon> list = [];
    
    // We construct distinct polygons for Hanoi, Da Nang, and HCM 
    // to map to the zone status returned by the database.
    for (int i = 0; i < heatmapData.length; i++) {
      final zone = heatmapData[i];
      final colorHex = zone.status == 'GREEN' 
          ? const Color(0x33059669) 
          : (zone.status == 'ORANGE' ? const Color(0x33D97706) : const Color(0x33DC2626));
      final borderHex = zone.status == 'GREEN' 
          ? AppColors.success 
          : (zone.status == 'ORANGE' ? AppColors.warning : AppColors.danger);

      List<LatLng> points = [];
      
      // Select appropriate coordinates depending on zone name
      final name = zone.zoneName.toLowerCase();
      if (name.contains('ba đình') || zone.zoneId == 1) {
        points = [
          const LatLng(21.035, 105.815),
          const LatLng(21.045, 105.830),
          const LatLng(21.030, 105.845),
          const LatLng(21.020, 105.825),
        ];
      } else if (name.contains('hoàn kiếm') || zone.zoneId == 2) {
        points = [
          const LatLng(21.025, 105.840),
          const LatLng(21.032, 105.860),
          const LatLng(21.015, 105.865),
          const LatLng(21.010, 105.845),
        ];
      } else if (name.contains('cầu giấy') || zone.zoneId == 3) {
        points = [
          const LatLng(21.038, 105.780),
          const LatLng(21.045, 105.795),
          const LatLng(21.025, 105.805),
          const LatLng(21.020, 105.785),
        ];
      } else if (name.contains('quận 1') || zone.zoneId == 4) {
        points = [
          const LatLng(10.775, 106.690),
          const LatLng(10.785, 106.705),
          const LatLng(10.765, 106.710),
          const LatLng(10.760, 106.695),
        ];
      } else if (name.contains('bình tân') || zone.zoneId == 5) {
        points = [
          const LatLng(10.745, 106.595),
          const LatLng(10.765, 106.615),
          const LatLng(10.740, 106.625),
          const LatLng(10.725, 106.605),
        ];
      } else if (name.contains('hải châu') || zone.zoneId == 6) {
        points = [
          const LatLng(16.065, 108.210),
          const LatLng(16.075, 108.225),
          const LatLng(16.050, 108.230),
          const LatLng(16.045, 108.215),
        ];
      } else {
        // Fallback offset polygon to keep it visible
        final double offsetLat = 0.02 * (zone.zoneId % 3);
        final double offsetLng = 0.02 * (zone.zoneId % 4);
        final LatLng center = _getMapCenter();
        points = [
          LatLng(center.latitude + 0.01 + offsetLat, center.longitude - 0.01 + offsetLng),
          LatLng(center.latitude + 0.02 + offsetLat, center.longitude + 0.01 + offsetLng),
          LatLng(center.latitude - 0.01 + offsetLat, center.longitude + 0.02 + offsetLng),
          LatLng(center.latitude - 0.02 + offsetLat, center.longitude - 0.02 + offsetLng),
        ];
      }

      list.add(
        Polygon(
          points: points,
          color: colorHex,
          borderColor: borderHex,
          borderStrokeWidth: 2,
          isFilled: true,
        ),
      );
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageScroll(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SectionTitle('Thống kê & Giám sát Vận chuyển'),
                Text(
                  'Cập nhật lúc: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 1. GLOBAL FILTERS BAR
            _buildGlobalFilters(),
            const SizedBox(height: 20),

            // Main Content Area with Future Builder
            FutureBuilder<LogisticsDashboardData>(
              future: _statsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(64),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.danger, size: 56),
                        const SizedBox(height: 14),
                        Text(
                          'Lỗi kết nối máy chủ: ${apiErrorMessage(snapshot.error!)}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _fetchStats,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Thử lại'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final data = snapshot.data;
                if (data == null) {
                  return const Center(
                    child: Text('Không tải được dữ liệu thống kê.'),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. TOP ROW SCORECARDS
                    _buildScorecards(data),
                    const SizedBox(height: 20),

                    // Grid layout for Module 1 & Module 2
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact = constraints.maxWidth < 1100;
                        if (isCompact) {
                          return Column(
                            children: [
                              _buildModuleOrderFunnel(data),
                              const SizedBox(height: 20),
                              _buildModuleLinehaulPerformance(data),
                            ],
                          );
                        } else {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 5, child: _buildModuleOrderFunnel(data)),
                              const SizedBox(width: 20),
                              Expanded(flex: 6, child: _buildModuleLinehaulPerformance(data)),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // Module 3: Last-Mile Zone Heatmap
                    _buildModuleLastMileHeatmap(data),
                    const SizedBox(height: 20),

                    // Module 4: Exceptions & SLAs
                    _buildModuleExceptionAnalysis(data),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // 1. GLOBAL FILTERS BAR WIDGET
  Widget _buildGlobalFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Filter 1: Time range
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('Thời gian:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              _buildFilterChip('Hôm nay', 'TODAY'),
              _buildFilterChip('Tuần này', 'WEEK'),
              _buildFilterChip('Tháng này', 'MONTH'),
            ],
          ),

          IconButton(
            onPressed: () {
              setState(() {
                _timeFilter = 'MONTH';
              });
              _fetchStats();
            },
            icon: const Icon(Icons.refresh_outlined),
            color: AppColors.textSecondary,
            tooltip: 'Tải lại bộ lọc',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String filterValue) {
    final isSelected = _timeFilter == filterValue;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textSecondary,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        selectedColor: AppColors.primary,
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _timeFilter = filterValue;
            });
            _fetchStats();
          }
        },
      ),
    );
  }

  // 2. DÃY KPI LÕI (Top-row Scorecards) WIDGET
  Widget _buildScorecards(LogisticsDashboardData data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        // Adjust column sizes dynamically
        int crossAxisCount = 4;
        if (width < 600) {
          crossAxisCount = 1;
        } else if (width < 1100) {
          crossAxisCount = 2;
        }

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: crossAxisCount == 1 ? 5.0 : 2.5,
          children: [
            // Card 1: Total Orders
            _buildScorecardItem(
              title: 'Tổng Đơn Hàng',
              value: currencyFormatter.format(data.totalOrders),
              trend: data.totalOrdersGrowth,
              icon: Icons.inventory_2_outlined,
              color: AppColors.info,
              subtitle: 'Đơn mới nhận',
            ),

            // Card 2: SLA Success Rate
            _buildScorecardItem(
              title: 'Tỷ lệ Giao Thành Công',
              value: '${data.successRate}%',
              trend: data.successRateGrowth,
              icon: Icons.track_changes,
              color: AppColors.success,
              subtitle: 'SLA tối thiểu: 92%',
              showPulse: true,
            ),

            // Card 3: Active Fleet
            _buildScorecardItem(
              title: 'Xe Đang Chạy (Active)',
              value: '${data.activeFleetLinehaul + data.activeFleetLocal} Xe',
              icon: Icons.local_shipping_outlined,
              color: AppColors.primary,
              subtitle: '${data.activeFleetLinehaul} Linehaul | ${data.activeFleetLocal} Local',
            ),

            // Card 4: Critical Alerts
            _buildScorecardItem(
              title: 'Cảnh Báo Đỏ (Alerts)',
              value: '${data.criticalAlerts} Sự cố',
              icon: Icons.warning_amber_outlined,
              color: AppColors.danger,
              subtitle: 'Xe hỏng / Trễ chuyến / Quá tải',
              showPulse: data.criticalAlerts > 0,
            ),
          ],
        );
      },
    );
  }

  Widget _buildScorecardItem({
    required String title,
    required String value,
    double? trend,
    required IconData icon,
    required Color color,
    required String subtitle,
    bool showPulse = false,
  }) {
    Widget trendWidget = const SizedBox.shrink();
    if (trend != null) {
      final isPos = trend >= 0;
      trendWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPos ? Icons.trending_up : Icons.trending_down,
            color: isPos ? AppColors.success : AppColors.danger,
            size: 14,
          ),
          const SizedBox(width: 2),
          Text(
            '${isPos ? '+' : ''}$trend% so với hôm qua',
            style: TextStyle(
              color: isPos ? AppColors.success : AppColors.danger,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    return DashboardCard(
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    trendWidget.toString() != const SizedBox.shrink().toString() 
                        ? trendWidget 
                        : Text(
                            subtitle,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                  ],
                ),
              ),
            ],
          ),
          if (showPulse)
            Positioned(
              top: 0,
              right: 0,
              child: BlinkingAlert(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: color, blurRadius: 4, spreadRadius: 1),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 3. MODULE 1: ORDER FUNNEL (Phễu dòng chảy đơn hàng) WIDGET
  Widget _buildModuleOrderFunnel(LogisticsDashboardData data) {
    final funnel = data.orderFunnel;
    
    // Determine bottleneck status (Sorting at hub >= 5000)
    final bool isBottleneck = funnel.sortingAtHub >= 5000;
    
    final List<_FunnelStage> stages = [
      _FunnelStage('NEW (Mới nhận)', funnel.newOrders, AppColors.info),
      _FunnelStage('IN_TRANSIT_LINEHAUL (Đang trên xe tải)', funnel.inTransitLinehaul, AppColors.primary),
      _FunnelStage('SORTING_AT_HUB (Rã Pallet ở Hub)', funnel.sortingAtHub, isBottleneck ? AppColors.danger : AppColors.warning),
      _FunnelStage('OUT_FOR_DELIVERY (Shipper đi giao)', funnel.outForDelivery, Colors.cyan),
      _FunnelStage('DELIVERED (Đã giao xong)', funnel.delivered, AppColors.success),
    ];

    // Determine max width reference
    final double maxCount = stages.map((s) => s.count).fold(1.0, (m, c) => c > m ? c.toDouble() : m);

    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionTitle('Phễu Dòng Chảy Đơn Hàng'),
              if (isBottleneck)
                BlinkingAlert(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.danger),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error, color: AppColors.danger, size: 16),
                        const SizedBox(width: 6),
                        const Text(
                          'CỔ CHAI Ở HUB HÀ NỘI',
                          style: TextStyle(
                            color: AppColors.danger,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Phân tích luồng đơn hàng và phát hiện tắc nghẽn cục bộ',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // Render stages
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stages.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final stage = stages[index];
              final double ratio = maxCount > 0 ? (stage.count / maxCount) : 0.0;
              final isTargetHub = stage.label.contains('SORTING_AT_HUB');

              Widget barWidget = Container(
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      stage.color,
                      stage.color.withValues(alpha: 0.65),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: stage.color.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              );

              // If it's a bottleneck, make the bar flash/blink!
              if (isTargetHub && isBottleneck) {
                barWidget = BlinkingAlert(child: barWidget);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            stage.label,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          if (isTargetHub && isBottleneck) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.warning, color: AppColors.danger, size: 16),
                          ],
                        ],
                      ),
                      Text(
                        '${currencyFormatter.format(stage.count)} đơn',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        flex: (ratio * 100).toInt(),
                        child: barWidget,
                      ),
                      Expanded(
                        flex: ((1.0 - ratio) * 100).toInt(),
                        child: const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),

          if (isBottleneck) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.danger, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Cảnh báo: Lượng tồn phân loại tại Hub Hà Nội vượt ngưỡng an toàn (5,000 đơn). Vui lòng điều động thêm nhân sự chi viện để thông kho.',
                      style: TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 4. MODULE 2: LINEHAUL PERFORMANCE (Hiệu suất tuyến dài) WIDGET
  Widget _buildModuleLinehaulPerformance(LogisticsDashboardData data) {
    final fill = data.linehaulFillRate;

    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Hiệu suất Tuyến Đường Dài'),
          const SizedBox(height: 6),
          const Text(
            'Tỷ lệ lấp đầy container trung bình theo khối lượng và thể tích',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // Bar Chart showing fill rates
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.center,
                maxY: 100,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.textPrimary,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY}%',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        const style = TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        );
                        String text = '';
                        switch (value.toInt()) {
                          case 0:
                            text = 'Theo Khối Lượng (Weight)';
                            break;
                          case 1:
                            text = 'Theo Thể Tích (Volume)';
                            break;
                        }
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 8,
                          child: Text(text, style: style),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 20,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 4,
                          child: Text(
                            '${value.toInt()}%',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: fill.weightAvg,
                        color: AppColors.primary,
                        width: 45,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: fill.volumeAvg,
                        color: AppColors.success,
                        width: 45,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Insight card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: AppColors.info, size: 18),
                    const SizedBox(width: 6),
                    const Text(
                      'PHÂN TÍCH TỐI ƯU CHI PHÍ',
                      style: TextStyle(
                        color: AppColors.info,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Xe luôn đầy Thể tích (92%) nhưng Khối lượng chỉ đạt 50-80% -> Khuyên dùng: Cần điều chỉnh thuật toán VRP/gom Pallet ghép hàng nặng (sắt, gỗ) với hàng nhẹ (nhựa, linh kiện) để tối ưu tải trọng xe, tránh lãng phí cước xe.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 5. MODULE 3: LAST-MILE ZONE HEATMAP (Bản đồ vùng giao hàng) WIDGET
  Widget _buildModuleLastMileHeatmap(LogisticsDashboardData data) {
    final polygons = _getMockZonePolygons(data.zoneHeatmap);

    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Nhiệt độ Vùng Giao Hàng & Leaderboard'),
          const SizedBox(height: 6),
          const Text(
            'Bản đồ nhiệt phản ánh hiệu năng giao hàng từng Zone ( wards ) và năng lực đội Shipper',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),

          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 1000;
              
              final mapWidget = ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 380,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                  ),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: _getMapCenter(),
                      initialZoom: _getMapZoom(),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.overcode250204.smartlogisticssystem',
                      ),
                      PolygonLayer(
                        polygons: polygons,
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _getMapCenter(),
                            width: 140,
                            height: 40,
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.primary, width: 1.5),
                              ),
                              child: const Text(
                                'Hub Vận Hành Trung Tâm',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );

              final leaderboardWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🏆 TOP 5 SHIPPER XUẤT SẮC',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: data.shipperLeaderboard.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final shipper = data.shipperLeaderboard[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.darkest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: AppColors.success.withValues(alpha: 0.15),
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: AppColors.success,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  shipper.shipperName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                            Text(
                              '${shipper.deliveredCount} đơn',
                              style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    '🚨 TOP 5 ZONE TỒN ĐỌNG (BACKLOG)',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: data.topBacklogZones.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final backlog = data.topBacklogZones[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.darkest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              backlog.zoneName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              '${backlog.backlogCount} đơn tồn',
                              style: const TextStyle(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              );

              if (isCompact) {
                return Column(
                  children: [
                    mapWidget,
                    const SizedBox(height: 20),
                    leaderboardWidget,
                  ],
                );
              } else {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: mapWidget),
                    const SizedBox(width: 20),
                    Expanded(flex: 2, child: leaderboardWidget),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // 6. MODULE 4: EXCEPTION & SLA ANALYSIS (Tỷ lệ trễ hạn & Lý do hủy) WIDGET
  Widget _buildModuleExceptionAnalysis(LogisticsDashboardData data) {
    final exc = data.exceptionPieChart;

    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Tỷ Lệ Trễ Hạn & Lý Do Hủy'),
          const SizedBox(height: 6),
          const Text(
            'Phân tích cấu trúc nguyên nhân giao hàng thất bại và danh sách chuyến xe vi phạm SLA thời gian',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),

          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 1000;

              final pieWidget = Column(
                children: [
                  const Text(
                    'Lý do giao thất bại ( % )',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 180,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: [
                          PieChartSectionData(
                            value: exc.noAnswer,
                            color: AppColors.primary,
                            title: '${exc.noAnswer.toInt()}%',
                            radius: 50,
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          PieChartSectionData(
                            value: exc.damaged,
                            color: AppColors.danger,
                            title: '${exc.damaged.toInt()}%',
                            radius: 50,
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          PieChartSectionData(
                            value: exc.vrpError,
                            color: AppColors.warning,
                            title: '${exc.vrpError.toInt()}%',
                            radius: 50,
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          PieChartSectionData(
                            value: exc.linehaulDelay,
                            color: AppColors.info,
                            title: '${exc.linehaulDelay.toInt()}%',
                            radius: 50,
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  
                  // Legend
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildPieLegend('Khách không nghe máy', AppColors.primary),
                      _buildPieLegend('Hàng bị vỡ/hỏng dỡ Pallet', AppColors.danger),
                      _buildPieLegend('VRP sai đường/Shipper lạc', AppColors.warning),
                      _buildPieLegend('Trễ chuyến Linehaul', AppColors.info),
                    ],
                  ),
                ],
              );

              final tableWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⚠️ CẢNH BÁO XE TRỄ (DELAYED TRIPS)',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  DarkTable(
                    columns: const [
                      DataColumn(label: Text('Mã chuyến')),
                      DataColumn(label: Text('Loại')),
                      DataColumn(label: Text('Tài xế')),
                      DataColumn(label: Text('Biển kiểm soát')),
                      DataColumn(label: Text('Thời gian trễ')),
                      DataColumn(label: Text('SLA Dự kiến')),
                    ],
                    rows: data.delayedTrips
                        .map(
                          (trip) => DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  trip.tripCode,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: trip.tripType == 'LINEHAUL' 
                                        ? AppColors.primary.withValues(alpha: 0.15) 
                                        : Colors.cyan.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    trip.tripType,
                                    style: TextStyle(
                                      color: trip.tripType == 'LINEHAUL' ? AppColors.primary : Colors.cyan[800],
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(Text(trip.driverName)),
                              DataCell(Text(trip.licensePlate)),
                              DataCell(
                                Text(
                                  '+${trip.delayMinutes} phút',
                                  style: const TextStyle(
                                    color: AppColors.danger,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataCell(Text('${trip.slaHours}h')),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ],
              );

              if (isCompact) {
                return Column(
                  children: [
                    pieWidget,
                    const SizedBox(height: 28),
                    tableWidget,
                  ],
                );
              } else {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: pieWidget),
                    const SizedBox(width: 24),
                    Expanded(flex: 5, child: tableWidget),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPieLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _FunnelStage {
  final String label;
  final int count;
  final Color color;

  _FunnelStage(this.label, this.count, this.color);
}

class BlinkingAlert extends StatefulWidget {
  final Widget child;
  const BlinkingAlert({super.key, required this.child});

  @override
  State<BlinkingAlert> createState() => _BlinkingAlertState();
}

class _BlinkingAlertState extends State<BlinkingAlert> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: 0.2 + (_controller.value * 0.8),
          child: widget.child,
        );
      },
    );
  }
}
