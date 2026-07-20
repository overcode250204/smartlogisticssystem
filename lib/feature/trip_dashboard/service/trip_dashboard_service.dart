// File: lib/feature/trip_dashboard/service/trip_dashboard_service.dart
import 'package:smartlogisticssystem/core/networking.dart';
import 'package:smartlogisticssystem/feature/trip_dashboard/models/trip_dashboard_models.dart';
import 'package:dio/dio.dart';

class LogisticsDashboardService {
  final ApiClient _client = ApiClient();

  Future<LogisticsDashboardData> getDashboardStats({
    required String timeFilter,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'timeFilter': timeFilter,
      };

      final response = await _client.get(
        'admin/logistics-dashboard/stats',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;
        // The API returns wrapped in BaseResponse, so we read the 'data' key
        final Map<String, dynamic> data = responseData['data'] ?? {};
        return LogisticsDashboardData.fromJson(data);
      }
      
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Không thể lấy thông tin thống kê vận chuyển',
      );
    } catch (e) {
      if (e is DioException) {
        print('Error fetching logistics dashboard: ${e.response?.data}');
      }
      rethrow;
    }
  }
}
