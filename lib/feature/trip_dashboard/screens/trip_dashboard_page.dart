// File: lib/feature/trip_dashboard/screens/trip_dashboard_page.dart
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
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
  String _timeframe = 'MONTH'; // TODAY, WEEK, MONTH
  String _region = 'ALL'; // ALL, HN, HCM, DN
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;
  
  late Future<LogisticsDashboardData> _statsFuture;

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  void _fetchStats() {
    setState(() {
      _statsFuture = _service.getDashboardStats(
        timeframe: _timeframe,
        region: _region,
        month: _month,
        year: _year,
      );
    });
  }

  LatLng _getMapCenter() {
    switch (_region) {
      case 'HN':
        return const LatLng(21.0285, 105.8542);
      case 'DN':
        return const LatLng(16.0544, 108.2022);
      case 'HCM':
      default:
        return const LatLng(10.7769, 106.7009);
    }
  }

  double _getMapZoom() {
    if (_region == 'ALL') {
      return 6.0; // zoom out to see all of Vietnam
    }
    return 12.5; // close up for specific city
  }

  // Helper to safely format numbers with thousands separators
  final NumberFormat _numberFormat = NumberFormat('#,###', 'vi_VN');

  @override
  Widget build(BuildContext context) {
    // Force Map to re-center when region changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_region != 'ALL') {
        _mapController.move(_getMapCenter(), _getMapZoom());
      } else {
        _mapController.move(const LatLng(16.0544, 108.2022), 5.5);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: PageScroll(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TOP HEADER & FILTERS BAR
              _buildHeader(),
              const SizedBox(height: 24),

              // Main FutureBuilder content
              FutureBuilder<LogisticsDashboardData>(
                future: _statsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(100),
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 3,
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.danger, size: 64),
                            const SizedBox(height: 16),
                            Text(
                              'Không thể tải dữ liệu: ${apiErrorMessage(snapshot.error!)}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _fetchStats,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Tải lại dữ liệu'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final data = snapshot.data;
                  if (data == null) {
                    return const Center(
                      child: Text('Không có dữ liệu hiển thị.'),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2. SCORECARDS SECTION
                      _buildScorecards(data),
                      const SizedBox(height: 24),

                      // 3. ROW 2: Phễu Dòng Chảy & Hiệu suất Tuyến Đường Dài
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth < 1100) {
                            return Column(
                              children: [
                                _buildOrderFlowFunnel(data),
                                const SizedBox(height: 24),
                                _buildLonghaulPerformance(data),
                              ],
                            );
                          } else {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 5, child: _buildOrderFlowFunnel(data)),
                                const SizedBox(width: 24),
                                Expanded(flex: 6, child: _buildLonghaulPerformance(data)),
                              ],
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 24),

                      // 4. ROW 3: Last-Mile & Vùng Giao Hàng (Map, Shippers, Backlog)
                      _buildLastMileSection(data),
                      const SizedBox(height: 24),

                      // 5. ROW 4: Phân tích Trễ Hạn & Cảnh báo Sự cố (Exception)
                      _buildExceptionSection(data),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 1. TOP HEADER & FILTERS BAR
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left Title
        
        // Right Filters
        Row(
          children: [
            const Icon(Icons.filter_alt_outlined, size: 18, color: Color(0xFF64748B)),
            const SizedBox(width: 6),
            const Text(
              'Bộ lọc:',
              style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(width: 12),

            // Dropdown 1: Timeframe Filter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _timeframe,
                  icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
                  style: const TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w600, fontSize: 13),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _timeframe = newValue;
                      });
                      _fetchStats();
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: 'TODAY', child: Text('Hôm nay')),
                    DropdownMenuItem(value: 'WEEK', child: Text('Tuần này')),
                    DropdownMenuItem(value: 'MONTH', child: Text('Tháng này')),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Dropdown 2: Region Filter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _region,
                  icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
                  style: const TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w600, fontSize: 13),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _region = newValue;
                      });
                      _fetchStats();
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: 'ALL', child: Text('Khu vực: Toàn quốc')),
                    DropdownMenuItem(value: 'HN', child: Text('Khu vực: Hà Nội')),
                    DropdownMenuItem(value: 'HCM', child: Text('Khu vực: TP.HCM')),
                    DropdownMenuItem(value: 'DN', child: Text('Khu vực: Đà Nẵng')),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 2. SCORECARDS SECTION
  Widget _buildScorecards(LogisticsDashboardData data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        int crossAxisCount = 4;
        if (width < 600) {
          crossAxisCount = 1;
        } else if (width < 1000) {
          crossAxisCount = 2;
        }

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: crossAxisCount == 1 ? 4.5 : (crossAxisCount == 2 ? 2.8 : 2.5),
          children: [
            // Card 1: Tổng Đơn Hàng
            _buildScorecardItem(
              title: 'Tổng Đơn Hàng',
              value: _numberFormat.format(data.totalOrders),
              trend: data.totalOrdersGrowth,
              icon: Icons.inventory_2_outlined,
              color: const Color(0xFF2563EB),
              trendLabel: 'so với hôm qua',
            ),

            // Card 2: Tỷ lệ Giao Thành Công
            _buildScorecardItem(
              title: 'Tỷ lệ Giao Thành Công (SLA)',
              value: '${data.successRate.toStringAsFixed(1)}%',
              trend: data.successRateGrowth,
              icon: Icons.check_circle_outline_rounded,
              color: const Color(0xFF10B981),
              trendLabel: 'so với hôm qua',
            ),

            // Card 3: Xe Đang Chạy
            _buildScorecardItem(
              title: 'Xe Đang Chạy (Active Fleet)',
              value: '${data.activeFleetLinehaul + data.activeFleetLocal} / 120',
              icon: Icons.local_shipping_outlined,
              color: const Color(0xFF6366F1),
              customSubtitle: const Text(
                'Linehaul  |  Local',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Card 4: Cảnh Báo Đỏ
            _buildScorecardItem(
              title: 'Cảnh Báo Sự cố',
              value: data.criticalAlerts.toString(),
              trend: data.criticalAlertsGrowth,
              icon: Icons.warning_amber_rounded,
              color: const Color(0xFFEF4444),
              trendLabel: 'cần xử',
              isAlertCard: true,
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
    String? trendLabel,
    Widget? customSubtitle,
    bool isAlertCard = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isAlertCard ? const Color(0xFFFEF2F2) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAlertCard ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isAlertCard ? const Color(0xFF991B1B) : const Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    color: isAlertCard ? const Color(0xFF991B1B) : const Color(0xFF1E293B),
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                if (customSubtitle != null)
                  customSubtitle
                else if (trend != null)
                  Row(
                    children: [
                      Icon(
                        Icons.trending_up_rounded,
                        color: isAlertCard ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${trend > 0 ? '+' : ''}${trend.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: isAlertCard ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trendLabel ?? '',
                        style: TextStyle(
                          color: isAlertCard ? const Color(0xFFF87171) : const Color(0xFF94A3B8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isAlertCard 
                  ? const Color(0xFFFEE2E2) 
                  : color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isAlertCard ? const Color(0xFFEF4444) : color,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  // 3. ROW 2: Phễu Dòng Chảy Đơn Hàng WIDGET
  // 3. ROW 2: Phễu Dòng Chảy Đơn Hàng WIDGET
  Widget _buildOrderFlowFunnel(LogisticsDashboardData data) {
    final funnel = data.orderFunnel;
    final List<_FunnelStage> stages = [
      _FunnelStage('Mới nhận', funnel.newOrders, const Color(0xFF2563EB)),
      _FunnelStage('Đang trên xe tải', funnel.inTransitLinehaul, const Color(0xFF6366F1)),
      _FunnelStage('Đang rã Pallet ở Hub', funnel.sortingAtHub, const Color(0xFFA855F7)),
      _FunnelStage('Shipper đang đi giao', funnel.outForDelivery, const Color(0xFFF97316)),
      _FunnelStage('Đã giao xong', funnel.delivered, const Color(0xFF10B981)),
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phễu Dòng Chảy Đơn Hàng',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 280,
            width: double.infinity,
            child: CustomPaint(
              painter: FunnelPainter(
                stages: stages,
                numberFormat: _numberFormat,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3. ROW 2: Hiệu suất Tuyến Đường Dài (Longhaul Route Performance)
  Widget _buildLonghaulPerformance(LogisticsDashboardData data) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hiệu suất Tuyến Đường Dài',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tỷ lệ lấp đầy Khối lượng (Weight) vs Thể tích (Volume)',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF1E293B),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toStringAsFixed(1)}%',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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
                        final index = value.toInt();
                        if (index >= 0 && index < data.routeFillRates.length) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 8,
                            child: Text(
                              data.routeFillRates[index].routeName,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 25,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 4,
                          child: Text(
                            '${value.toInt()}',
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return const FlLine(
                      color: Color(0xFFF1F5F9),
                      strokeWidth: 1.5,
                      dashArray: [5, 5],
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(data.routeFillRates.length, (index) {
                  final item = data.routeFillRates[index];
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: item.weightPercentage,
                        color: const Color(0xFF2563EB),
                        width: 14,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                      BarChartRodData(
                        toY: item.volumePercentage,
                        color: const Color(0xFF10B981),
                        width: 14,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Legend for fill rates
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendIndicator('Khối lượng (%)', const Color(0xFF2563EB)),
              const SizedBox(width: 24),
              _buildLegendIndicator('Thể tích (%)', const Color(0xFF10B981)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendIndicator(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // 4. ROW 3: Last-Mile & Vùng Giao Hàng WIDGET
  Widget _buildLastMileSection(LogisticsDashboardData data) {
    final circles = data.zoneHeatmap.map((zone) {
      Color circleColor = const Color(0x3310B981);
      Color outlineColor = const Color(0xFF10B981);
      if (zone.status == 'RED') {
        circleColor = const Color(0x33EF4444);
        outlineColor = const Color(0xFFEF4444);
      } else if (zone.status == 'ORANGE') {
        circleColor = const Color(0x33F97316);
        outlineColor = const Color(0xFFF97316);
      }
      return CircleMarker(
        point: LatLng(zone.latitude, zone.longitude),
        color: circleColor,
        borderColor: outlineColor,
        borderStrokeWidth: 1.5,
        radius: zone.radius,
        useRadiusInMeter: true,
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Last-Mile & Vùng Giao Hàng',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 1100;

              final mapWidget = Container(
                height: 380,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _getMapCenter(),
                        initialZoom: _getMapZoom(),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.overcode250204.smartlogisticssystem',
                        ),
                        CircleLayer(
                          circles: circles,
                        ),
                        MarkerLayer(
                          markers: data.zoneHeatmap.map((zone) {
                            return Marker(
                              point: LatLng(zone.latitude, zone.longitude),
                              width: 90,
                              height: 30,
                              child: Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: zone.status == 'RED' 
                                        ? const Color(0xFFEF4444) 
                                        : (zone.status == 'ORANGE' ? const Color(0xFFF97316) : const Color(0xFF10B981)),
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  '${zone.zoneName} (${zone.backlogCount})',
                                  style: const TextStyle(
                                    color: Color(0xFF1E293B),
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
                        ),
                        child: const Text(
                          'Bản đồ Nhiệt (Live Map)',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF334155)),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildMapLegendItem('Tốt', const Color(0xFF10B981)),
                            const SizedBox(width: 14),
                            _buildMapLegendItem('Tải cao', const Color(0xFFF97316)),
                            const SizedBox(width: 14),
                            _buildMapLegendItem('Quá tải', const Color(0xFFEF4444)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );

              final leaderboardWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Top 5 Shipper',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: data.shipperLeaderboard.length,
                      separatorBuilder: (context, index) => const Divider(color: Color(0xFFF1F5F9), height: 1),
                      itemBuilder: (context, index) {
                        final shipper = data.shipperLeaderboard[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Text(
                                '${shipper.rank}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      shipper.shipperName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      shipper.zone,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF94A3B8),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${shipper.deliveredCount} đơn',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                      const SizedBox(width: 2),
                                      Text(
                                        shipper.rating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );

              final backlogWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Top Zone Tồn Đọng',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: data.topBacklogZones.length,
                      separatorBuilder: (context, index) => const Divider(color: Color(0xFFF1F5F9), height: 1),
                      itemBuilder: (context, index) {
                        final backlog = data.topBacklogZones[index];
                        final isCritical = backlog.status == 'Nghiêm trọng';
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    backlog.zoneName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isCritical 
                                          ? const Color(0xFFFEF2F2) 
                                          : const Color(0xFFFFF7ED),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      backlog.status,
                                      style: TextStyle(
                                        color: isCritical 
                                            ? const Color(0xFFEF4444) 
                                            : const Color(0xFFF97316),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${backlog.backlogCount} đơn',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: isCritical ? const Color(0xFFEF4444) : const Color(0xFFF97316),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Cần chi viện',
                                    style: TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );

              if (isCompact) {
                return Column(
                  children: [
                    mapWidget,
                    const SizedBox(height: 24),
                    leaderboardWidget,
                    const SizedBox(height: 24),
                    backlogWidget,
                  ],
                );
              } else {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: mapWidget),
                    const SizedBox(width: 24),
                    Expanded(flex: 4, child: leaderboardWidget),
                    const SizedBox(width: 24),
                    Expanded(flex: 4, child: backlogWidget),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMapLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // 5. ROW 4: Phân tích Trễ Hạn & Cảnh báo Sự cố (Exception)
  Widget _buildExceptionSection(LogisticsDashboardData data) {
    final exc = data.exceptionPieChart;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phân tích Trễ Hạn & Cảnh báo Sự cố (Exception)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 1000;

              final pieChartWidget = Column(
                children: [
                  const Text(
                    'Lý do giao thất bại / Hoàn hàng',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 180,
                    child: Stack(
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 55,
                            sections: [
                              PieChartSectionData(
                                value: exc.noAnswer,
                                color: const Color(0xFFF97316),
                                title: '${exc.noAnswer.toInt()}%',
                                radius: 24,
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                              PieChartSectionData(
                                value: exc.damaged,
                                color: const Color(0xFFEF4444),
                                title: '${exc.damaged.toInt()}%',
                                radius: 24,
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                              PieChartSectionData(
                                value: exc.vrpError,
                                color: const Color(0xFFEAB308),
                                title: '${exc.vrpError.toInt()}%',
                                radius: 24,
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                              PieChartSectionData(
                                value: exc.linehaulDelay,
                                color: const Color(0xFF2563EB),
                                title: '${exc.linehaulDelay.toInt()}%',
                                radius: 24,
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${exc.errorRate.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const Text(
                                'Tỷ lệ lỗi',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildPieLegendItem('Khách không nghe máy', const Color(0xFFF97316)),
                      _buildPieLegendItem('Hàng bị vỡ/hỏng', const Color(0xFFEF4444)),
                      _buildPieLegendItem('Thuật toán VRP sai', const Color(0xFFEAB308)),
                      _buildPieLegendItem('Trễ chuyến Linehaul', const Color(0xFF2563EB)),
                    ],
                  ),
                ],
              );

              final tableWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Danh sách Chuyến Trễ Hạn (Delayed Trips)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Xem tất cả',
                          style: TextStyle(color: Color(0xFF2563EB), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: DataTable(
                      horizontalMargin: 16,
                      columnSpacing: 12,
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                      columns: const [
                        DataColumn(label: Text('MÃ CHUYẾN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF475569)))),
                        DataColumn(label: Text('LOẠI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF475569)))),
                        DataColumn(label: Text('TUYẾN / ZONE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF475569)))),
                        DataColumn(label: Text('TÀI XẾ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF475569)))),
                        DataColumn(label: Text('THỜI GIAN TRỄ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF475569)))),
                      ],
                      rows: data.delayedTrips.map((trip) {
                        final isLinehaul = trip.tripType == 'LINEHAUL';
                        return DataRow(
                          cells: [
                            DataCell(Text(trip.tripCode, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF1E293B)))),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isLinehaul ? const Color(0xFFEEF2FF) : const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isLinehaul ? 'Linehaul' : 'Local',
                                  style: TextStyle(
                                    color: isLinehaul ? const Color(0xFF4F46E5) : const Color(0xFF059669),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(Text(trip.routeOrZone, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)))),
                            DataCell(Text(trip.driverName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF334155)))),
                            DataCell(
                              Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, color: Color(0xFFEF4444), size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    trip.delayTime,
                                    style: const TextStyle(
                                      color: Color(0xFFEF4444),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );

              if (isCompact) {
                return Column(
                  children: [
                    pieChartWidget,
                    const SizedBox(height: 32),
                    tableWidget,
                  ],
                );
              } else {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 4, child: pieChartWidget),
                    const SizedBox(width: 32),
                    Expanded(flex: 7, child: tableWidget),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPieLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600),
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

class FunnelPainter extends CustomPainter {
  final List<_FunnelStage> stages;
  final NumberFormat numberFormat;

  FunnelPainter({required this.stages, required this.numberFormat});

  @override
  void paint(Canvas canvas, Size size) {
    final double labelWidth = 130.0;
    final double funnelWidth = size.width - labelWidth;
    final double cx = labelWidth + funnelWidth / 2;
    final double maxHalfWidth = (funnelWidth - 32) / 2;
    final int n = stages.length;
    final double h = size.height / n;
    final double gap = 4.0;
    final double maxCount = stages.map((s) => s.count).fold(1.0, (m, c) => c > m ? c.toDouble() : m);

    for (int i = 0; i < n; i++) {
      final stage = stages[i];
      final double yTop = i * h;
      final double yBottom = (i + 1) * h;

      final double yDrawTop = yTop + gap / 2;
      final double yDrawBottom = yBottom - gap / 2;

      final double ratio = maxCount > 0 ? (stage.count / maxCount) : 0.0;
      final double scale = 0.35 + 0.65 * ratio;

      // Linear equation for funnel slope, modulated by value ratio to allow bulging
      final double wHalfTop = maxHalfWidth * (1.0 - (yDrawTop / size.height) * 0.95) * scale;
      final double wHalfBottom = maxHalfWidth * (1.0 - (yDrawBottom / size.height) * 0.95) * scale;

      final path = ui.Path()
        ..moveTo(cx - wHalfTop, yDrawTop)
        ..lineTo(cx + wHalfTop, yDrawTop)
        ..lineTo(cx + wHalfBottom, yDrawBottom)
        ..lineTo(cx - wHalfBottom, yDrawBottom)
        ..close();

      final paint = Paint()
        ..color = stage.color
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, paint);

      // Draw label on the left side
      final double yMid = (yTop + yBottom) / 2;
      final labelSpan = TextSpan(
        text: stage.label,
        style: const TextStyle(
          color: Color(0xFF475569),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      );
      final labelPainter = TextPainter(
        text: labelSpan,
        textDirection: ui.TextDirection.ltr,
        textAlign: TextAlign.right,
      )..layout(maxWidth: labelWidth - 12);
      
      labelPainter.paint(
        canvas,
        Offset(
          labelWidth - 12 - labelPainter.width,
          yMid - labelPainter.height / 2,
        ),
      );

      // Draw value text inside the segment
      final valueSpan = TextSpan(
        text: numberFormat.format(stage.count),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      );
      final valuePainter = TextPainter(
        text: valueSpan,
        textDirection: ui.TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();

      valuePainter.paint(
        canvas,
        Offset(
          cx - valuePainter.width / 2,
          yMid - valuePainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant FunnelPainter oldDelegate) {
    return oldDelegate.stages != stages;
  }
}
