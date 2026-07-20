import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

class Province {
  final int code;
  final String name;

  const Province({required this.code, required this.name});

  factory Province.fromJson(Map<String, dynamic> json) {
    return Province(
      code: json['code'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }
}

class LocationService {
  final Dio _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 15), receiveTimeout: const Duration(seconds: 15)));

  Future<List<Province>> getProvinces() async {
    try {
      final response = await _dio.get('https://provinces.open-api.vn/api/v2/p/');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((e) => Province.fromJson(e)).toList();
      }
      throw Exception('Không thể tải danh sách tỉnh/thành phố');
    } catch (e) {
      throw Exception('Lỗi kết nối API tỉnh/thành phố: $e');
    }
  }

  Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Dịch vụ vị trí đang bị tắt trên thiết bị.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Quyền truy cập vị trí bị từ chối.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Quyền truy cập vị trí bị từ chối vĩnh viễn, vui lòng cấp quyền trong cài đặt thiết bị.');
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 10)),
    );
  }

  Future<Map<String, String?>> reverseGeocode(double lat, double lng) async {
    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'jsonv2',
          'lat': lat,
          'lon': lng,
          'accept-language': 'vi',
        },
        options: Options(headers: {
          'User-Agent': 'SmartLogisticsApp/1.0', // Nominatim requires User-Agent
        }),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final addressObj = data['address'] as Map<String, dynamic>?;
        
        String? displayName = data['display_name'];
        String? rawProvince = addressObj?['city'] ?? addressObj?['province'] ?? addressObj?['state'];

        return {
          'display_name': displayName,
          'province': rawProvince,
        };
      }
      return {};
    } catch (e) {
      return {}; // Non-fatal, just return empty
    }
  }

  /// Normalizes a province string to try matching with the API province list
  static String normalizeProvinceName(String? name) {
    if (name == null) return '';
    String n = name.toLowerCase();
    n = n.replaceAll('thành phố', '');
    n = n.replaceAll('tỉnh', '');
    n = n.replaceAll('tp.', '');
    return n.trim();
  }
}
