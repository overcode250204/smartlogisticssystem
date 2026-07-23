import 'package:dio/dio.dart';
import 'package:smartlogisticssystem/core/networking.dart';
import 'package:smartlogisticssystem/data/model/driver_response_model.dart';

class DriverProfileService {
  final ApiClient _client = ApiClient();

  /// Resolves the Driver record linked to a logged-in user's [userId].
  /// Throws a [DioException] (404) if the user has no linked Driver record.
  Future<DriverResponse> getDriverByUserId(int userId) async {
    final response = await _client.get('drivers/by-user/$userId');
    final body = response.data;
    final data = body is Map<String, dynamic> ? body['data'] : body;
    return DriverResponse.fromJson(data as Map<String, dynamic>);
  }
}
