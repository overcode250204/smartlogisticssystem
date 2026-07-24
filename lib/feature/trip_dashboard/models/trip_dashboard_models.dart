// File: lib/feature/trip_dashboard/models/trip_dashboard_models.dart

class LogisticsDashboardData {
  final int totalOrders;
  final double totalOrdersGrowth;
  final double successRate;
  final double successRateGrowth;
  final int activeFleetLinehaul;
  final int activeFleetLocal;
  final int criticalAlerts;
  final double criticalAlertsGrowth;
  final OrderFunnelData orderFunnel;
  final List<RouteFillRate> routeFillRates;
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
    required this.criticalAlertsGrowth,
    required this.orderFunnel,
    required this.routeFillRates,
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
      criticalAlertsGrowth: json['criticalAlertsGrowth'] != null ? (json['criticalAlertsGrowth'] as num).toDouble() : 0.0,
      orderFunnel: OrderFunnelData.fromJson(json['orderFunnel'] ?? {}),
      routeFillRates: (json['routeFillRates'] as List?)
              ?.map((item) => RouteFillRate.fromJson(item))
              .toList() ??
          [],
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

class RouteFillRate {
  final String routeName;
  final double weightPercentage;
  final double volumePercentage;

  RouteFillRate({
    required this.routeName,
    required this.weightPercentage,
    required this.volumePercentage,
  });

  factory RouteFillRate.fromJson(Map<String, dynamic> json) {
    return RouteFillRate(
      routeName: json['routeName'] ?? '',
      weightPercentage: json['weightPercentage'] != null ? (json['weightPercentage'] as num).toDouble() : 0.0,
      volumePercentage: json['volumePercentage'] != null ? (json['volumePercentage'] as num).toDouble() : 0.0,
    );
  }
}

class ZoneHeatmapData {
  final int zoneId;
  final String zoneName;
  final double successRate;
  final String status;
  final int backlogCount;
  final double latitude;
  final double longitude;
  final double radius;

  ZoneHeatmapData({
    required this.zoneId,
    required this.zoneName,
    required this.successRate,
    required this.status,
    required this.backlogCount,
    required this.latitude,
    required this.longitude,
    required this.radius,
  });

  factory ZoneHeatmapData.fromJson(Map<String, dynamic> json) {
    return ZoneHeatmapData(
      zoneId: json['zoneId'] != null ? (json['zoneId'] as num).toInt() : 0,
      zoneName: json['zoneName'] ?? '',
      successRate: json['successRate'] != null ? (json['successRate'] as num).toDouble() : 0.0,
      status: json['status'] ?? 'GREEN',
      backlogCount: json['backlogCount'] != null ? (json['backlogCount'] as num).toInt() : 0,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : 0.0,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : 0.0,
      radius: json['radius'] != null ? (json['radius'] as num).toDouble() : 0.0,
    );
  }
}

class ShipperLeaderboardData {
  final int rank;
  final String shipperName;
  final String zone;
  final int deliveredCount;
  final double rating;

  ShipperLeaderboardData({
    required this.rank,
    required this.shipperName,
    required this.zone,
    required this.deliveredCount,
    required this.rating,
  });

  factory ShipperLeaderboardData.fromJson(Map<String, dynamic> json) {
    return ShipperLeaderboardData(
      rank: json['rank'] != null ? (json['rank'] as num).toInt() : 0,
      shipperName: json['shipperName'] ?? '',
      zone: json['zone'] ?? '',
      deliveredCount: json['deliveredCount'] != null ? (json['deliveredCount'] as num).toInt() : 0,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : 0.0,
    );
  }
}

class BacklogZoneData {
  final String zoneName;
  final int backlogCount;
  final String status;

  BacklogZoneData({
    required this.zoneName,
    required this.backlogCount,
    required this.status,
  });

  factory BacklogZoneData.fromJson(Map<String, dynamic> json) {
    return BacklogZoneData(
      zoneName: json['zoneName'] ?? '',
      backlogCount: json['backlogCount'] != null ? (json['backlogCount'] as num).toInt() : 0,
      status: json['status'] ?? '',
    );
  }
}

class ExceptionPieChartData {
  final double noAnswer;
  final double damaged;
  final double vrpError;
  final double linehaulDelay;
  final double errorRate;

  ExceptionPieChartData({
    required this.noAnswer,
    required this.damaged,
    required this.vrpError,
    required this.linehaulDelay,
    required this.errorRate,
  });

  factory ExceptionPieChartData.fromJson(Map<String, dynamic> json) {
    return ExceptionPieChartData(
      noAnswer: json['noAnswer'] != null ? (json['noAnswer'] as num).toDouble() : 0.0,
      damaged: json['damaged'] != null ? (json['damaged'] as num).toDouble() : 0.0,
      vrpError: json['vrpError'] != null ? (json['vrpError'] as num).toDouble() : 0.0,
      linehaulDelay: json['linehaulDelay'] != null ? (json['linehaulDelay'] as num).toDouble() : 0.0,
      errorRate: json['errorRate'] != null ? (json['errorRate'] as num).toDouble() : 0.0,
    );
  }
}

class DelayedTripData {
  final String tripCode;
  final String tripType;
  final String routeOrZone;
  final String driverName;
  final String licensePlate;
  final String delayTime;
  final int delayMinutes;
  final int slaHours;
  final String status;

  DelayedTripData({
    required this.tripCode,
    required this.tripType,
    required this.routeOrZone,
    required this.driverName,
    required this.licensePlate,
    required this.delayTime,
    required this.delayMinutes,
    required this.slaHours,
    required this.status,
  });

  factory DelayedTripData.fromJson(Map<String, dynamic> json) {
    return DelayedTripData(
      tripCode: json['tripCode'] ?? '',
      tripType: json['tripType'] ?? 'LINEHAUL',
      routeOrZone: json['routeOrZone'] ?? '',
      driverName: json['driverName'] ?? '',
      licensePlate: json['licensePlate'] ?? '',
      delayTime: json['delayTime'] ?? '',
      delayMinutes: json['delayMinutes'] != null ? (json['delayMinutes'] as num).toInt() : 0,
      slaHours: json['slaHours'] != null ? (json['slaHours'] as num).toInt() : 0,
      status: json['status'] ?? 'DELAYED',
    );
  }
}
