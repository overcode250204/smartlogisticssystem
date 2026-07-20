// File: lib/feature/trip_dashboard/models/trip_dashboard_models.dart

class LogisticsDashboardData {
  final int totalOrders;
  final double totalOrdersGrowth;
  final double successRate;
  final double successRateGrowth;
  final int activeFleetLinehaul;
  final int activeFleetLocal;
  final int criticalAlerts;
  final OrderFunnelData orderFunnel;
  final FillRateData linehaulFillRate;
  final List<ZoneHeatmapData> zoneHeatmap;
  final List<ShipperLeaderboardData> shipperLeaderboard;
  final List<BacklogZoneData> topBacklogZones;
  final ExceptionPieChartData exceptionPieChart;
  final List<DelayedTripData> delayedTrips;

  LogisticsDashboardData({
    required this.totalOrders,
    required this.totalOrdersGrowth,
    required this.successRate,
    required this.successRateGrowth,
    required this.activeFleetLinehaul,
    required this.activeFleetLocal,
    required this.criticalAlerts,
    required this.orderFunnel,
    required this.linehaulFillRate,
    required this.zoneHeatmap,
    required this.shipperLeaderboard,
    required this.topBacklogZones,
    required this.exceptionPieChart,
    required this.delayedTrips,
  });

  factory LogisticsDashboardData.fromJson(Map<String, dynamic> json) {
    return LogisticsDashboardData(
      totalOrders: json['totalOrders'] != null ? (json['totalOrders'] as num).toInt() : 0,
      totalOrdersGrowth: json['totalOrdersGrowth'] != null ? (json['totalOrdersGrowth'] as num).toDouble() : 0.0,
      successRate: json['successRate'] != null ? (json['successRate'] as num).toDouble() : 0.0,
      successRateGrowth: json['successRateGrowth'] != null ? (json['successRateGrowth'] as num).toDouble() : 0.0,
      activeFleetLinehaul: json['activeFleetLinehaul'] != null ? (json['activeFleetLinehaul'] as num).toInt() : 0,
      activeFleetLocal: json['activeFleetLocal'] != null ? (json['activeFleetLocal'] as num).toInt() : 0,
      criticalAlerts: json['criticalAlerts'] != null ? (json['criticalAlerts'] as num).toInt() : 0,
      orderFunnel: OrderFunnelData.fromJson(json['orderFunnel'] ?? {}),
      linehaulFillRate: FillRateData.fromJson(json['linehaulFillRate'] ?? {}),
      zoneHeatmap: (json['zoneHeatmap'] as List?)
              ?.map((item) => ZoneHeatmapData.fromJson(item))
              .toList() ??
          [],
      shipperLeaderboard: (json['shipperLeaderboard'] as List?)
              ?.map((item) => ShipperLeaderboardData.fromJson(item))
              .toList() ??
          [],
      topBacklogZones: (json['topBacklogZones'] as List?)
              ?.map((item) => BacklogZoneData.fromJson(item))
              .toList() ??
          [],
      exceptionPieChart: ExceptionPieChartData.fromJson(json['exceptionPieChart'] ?? {}),
      delayedTrips: (json['delayedTrips'] as List?)
              ?.map((item) => DelayedTripData.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class OrderFunnelData {
  final int newOrders;
  final int inTransitLinehaul;
  final int sortingAtHub;
  final int outForDelivery;
  final int delivered;

  OrderFunnelData({
    required this.newOrders,
    required this.inTransitLinehaul,
    required this.sortingAtHub,
    required this.outForDelivery,
    required this.delivered,
  });

  factory OrderFunnelData.fromJson(Map<String, dynamic> json) {
    return OrderFunnelData(
      newOrders: json['newOrders'] != null ? (json['newOrders'] as num).toInt() : 0,
      inTransitLinehaul: json['inTransitLinehaul'] != null ? (json['inTransitLinehaul'] as num).toInt() : 0,
      sortingAtHub: json['sortingAtHub'] != null ? (json['sortingAtHub'] as num).toInt() : 0,
      outForDelivery: json['outForDelivery'] != null ? (json['outForDelivery'] as num).toInt() : 0,
      delivered: json['delivered'] != null ? (json['delivered'] as num).toInt() : 0,
    );
  }
}

class FillRateData {
  final double weightAvg;
  final double volumeAvg;

  FillRateData({
    required this.weightAvg,
    required this.volumeAvg,
  });

  factory FillRateData.fromJson(Map<String, dynamic> json) {
    return FillRateData(
      weightAvg: json['weightAvg'] != null ? (json['weightAvg'] as num).toDouble() : 0.0,
      volumeAvg: json['volumeAvg'] != null ? (json['volumeAvg'] as num).toDouble() : 0.0,
    );
  }
}

class ZoneHeatmapData {
  final int zoneId;
  final String zoneName;
  final double successRate;
  final String status;
  final int backlogCount;

  ZoneHeatmapData({
    required this.zoneId,
    required this.zoneName,
    required this.successRate,
    required this.status,
    required this.backlogCount,
  });

  factory ZoneHeatmapData.fromJson(Map<String, dynamic> json) {
    return ZoneHeatmapData(
      zoneId: json['zoneId'] != null ? (json['zoneId'] as num).toInt() : 0,
      zoneName: json['zoneName'] ?? '',
      successRate: json['successRate'] != null ? (json['successRate'] as num).toDouble() : 0.0,
      status: json['status'] ?? 'GREEN',
      backlogCount: json['backlogCount'] != null ? (json['backlogCount'] as num).toInt() : 0,
    );
  }
}

class ShipperLeaderboardData {
  final String shipperName;
  final int deliveredCount;

  ShipperLeaderboardData({
    required this.shipperName,
    required this.deliveredCount,
  });

  factory ShipperLeaderboardData.fromJson(Map<String, dynamic> json) {
    return ShipperLeaderboardData(
      shipperName: json['shipperName'] ?? '',
      deliveredCount: json['deliveredCount'] != null ? (json['deliveredCount'] as num).toInt() : 0,
    );
  }
}

class BacklogZoneData {
  final String zoneName;
  final int backlogCount;

  BacklogZoneData({
    required this.zoneName,
    required this.backlogCount,
  });

  factory BacklogZoneData.fromJson(Map<String, dynamic> json) {
    return BacklogZoneData(
      zoneName: json['zoneName'] ?? '',
      backlogCount: json['backlogCount'] != null ? (json['backlogCount'] as num).toInt() : 0,
    );
  }
}

class ExceptionPieChartData {
  final double noAnswer;
  final double damaged;
  final double vrpError;
  final double linehaulDelay;

  ExceptionPieChartData({
    required this.noAnswer,
    required this.damaged,
    required this.vrpError,
    required this.linehaulDelay,
  });

  factory ExceptionPieChartData.fromJson(Map<String, dynamic> json) {
    return ExceptionPieChartData(
      noAnswer: json['noAnswer'] != null ? (json['noAnswer'] as num).toDouble() : 0.0,
      damaged: json['damaged'] != null ? (json['damaged'] as num).toDouble() : 0.0,
      vrpError: json['vrpError'] != null ? (json['vrpError'] as num).toDouble() : 0.0,
      linehaulDelay: json['linehaulDelay'] != null ? (json['linehaulDelay'] as num).toDouble() : 0.0,
    );
  }
}

class DelayedTripData {
  final String tripCode;
  final String tripType;
  final String driverName;
  final String licensePlate;
  final int delayMinutes;
  final int slaHours;
  final String status;

  DelayedTripData({
    required this.tripCode,
    required this.tripType,
    required this.driverName,
    required this.licensePlate,
    required this.delayMinutes,
    required this.slaHours,
    required this.status,
  });

  factory DelayedTripData.fromJson(Map<String, dynamic> json) {
    return DelayedTripData(
      tripCode: json['tripCode'] ?? '',
      tripType: json['tripType'] ?? 'LINEHAUL',
      driverName: json['driverName'] ?? '',
      licensePlate: json['licensePlate'] ?? '',
      delayMinutes: json['delayMinutes'] != null ? (json['delayMinutes'] as num).toInt() : 0,
      slaHours: json['slaHours'] != null ? (json['slaHours'] as num).toInt() : 0,
      status: json['status'] ?? 'DELAYED',
    );
  }
}
