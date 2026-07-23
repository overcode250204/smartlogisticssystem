import 'package:geolocator/geolocator.dart';

/// Requests a high-accuracy GPS fix, prompting for permission/location
/// services as needed. Throws a plain [Exception] with a Vietnamese
/// message on failure (permission denied, GPS off).
Future<Position> getCurrentHighAccuracyPosition() async {
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw Exception('Vui lòng bật định vị (GPS) trên thiết bị');
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    throw Exception('Cần quyền truy cập vị trí để xác nhận đã đến điểm giao');
  }

  return Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
  );
}
