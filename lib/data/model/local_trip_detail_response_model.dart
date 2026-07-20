import 'local_trip_detail_status.dart';
import 'order_response_model.dart';

class LocalTripDetailResponse {
  final int id;
  final String localTripDetailCode;
  final OrderResponse order;
  final int stopOrder;
  final String? proofUrl;
  final bool barcodeScanned;
  final LocalTripDetailStatus status;

  const LocalTripDetailResponse({
    required this.id,
    required this.localTripDetailCode,
    required this.order,
    required this.stopOrder,
    this.proofUrl,
    required this.barcodeScanned,
    required this.status,
  });

  factory LocalTripDetailResponse.fromJson(Map<String, dynamic> json) {
    return LocalTripDetailResponse(
      id: _parseInt(json['id']) ?? 0,
      localTripDetailCode: json['localTripDetailCode']?.toString() ?? '',
      order: OrderResponse.fromJson(
        json['order'] as Map<String, dynamic>? ?? const {},
      ),
      stopOrder: _parseInt(json['stopOrder']) ?? 0,
      proofUrl: json['proofUrl']?.toString(),
      barcodeScanned: json['barcodeScanned'] as bool? ?? false,
      status: LocalTripDetailStatusX.fromApiValue(
        json['status']?.toString() ?? 'PENDING',
      ),
    );
  }
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
