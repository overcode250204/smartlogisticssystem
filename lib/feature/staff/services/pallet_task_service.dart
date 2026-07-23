import 'package:smartlogisticssystem/core/networking.dart';
import 'package:smartlogisticssystem/data/model/pallet_item_model.dart';
import 'package:smartlogisticssystem/data/model/pallet_model.dart';

/// Client cho luồng pallet của STAFF.
///
/// Contract backend (PalletController.java) — mọi response bọc trong
/// BaseResponse: { statusCode, message, data, timestamp }.
class PalletTaskService {
  final ApiClient _client;

  PalletTaskService({ApiClient? client}) : _client = client ?? ApiClient();

  /// GET /api/pallet/staff/tasks -> `List<PalletResponseDTO>`
  /// Backend chỉ trả pallet isCreatedSystem = true, status ∈ {CREATING, CAN_SEAL}.
  Future<List<PalletModel>> getTasks() async {
    final response = await _client.get('pallet/staff/tasks');
    final data = response.data['data'] as List<dynamic>? ?? const [];
    return data
        .map((item) => PalletModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/pallet/staff/tasks/{palletId} -> PalletResponseDTO (kèm palletItems + order)
  Future<PalletModel> getTaskById(int palletId) async {
    final response = await _client.get('pallet/staff/tasks/$palletId');
    return PalletModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// POST /api/pallet/{palletId}/items/{orderCode}/scan -> PalletItemResponseDTO
  /// Không có request body. Backend yêu cầu pallet đang ở trạng thái CAN_SEAL.
  Future<PalletItemModel> scanOrder({
    required int palletId,
    required String orderCode,
  }) async {
    final encodedOrderCode = Uri.encodeComponent(orderCode);
    final response = await _client.post(
      'pallet/$palletId/items/$encodedOrderCode/scan',
    );
    return PalletItemModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  /// POST /api/pallet/{palletId}/can-seal -> PalletResponseDTO
  /// LƯU Ý: đây KHÔNG phải API kiểm tra điều kiện seal. Backend đổi trạng thái
  /// pallet CREATING -> CAN_SEAL (mở khoá thao tác quét cho staff).
  Future<PalletModel> markCanSeal(int palletId) async {
    final response = await _client.post('pallet/$palletId/can-seal');
    return PalletModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// POST /api/pallet/{palletId}/seal -> PalletResponseDTO
  /// Backend kiểm tra: status = CAN_SEAL, pallet có item, tất cả item đã scan.
  Future<PalletModel> seal(int palletId) async {
    final response = await _client.post('pallet/$palletId/seal');
    return PalletModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// POST /api/pallet/{palletCode}/confirm-arrival -> PalletResponseDTO
  /// Body BẮT BUỘC: {latitude, longitude} (@NotNull). Backend yêu cầu pallet
  /// đang IN_TRANSIT và toạ độ ≤500m kho đích; thành công -> status ARRIVED.
  /// LƯU Ý: KHÔNG tự đổi trạng thái các order trong pallet.
  Future<PalletModel> confirmPalletArrival({
    required String palletCode,
    required double latitude,
    required double longitude,
  }) async {
    final encoded = Uri.encodeComponent(palletCode);
    final response = await _client.post(
      'pallet/$encoded/confirm-arrival',
      data: {'latitude': latitude, 'longitude': longitude},
    );
    return PalletModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// POST /api/pallet/orders/{orderCode}/confirm-arrival -> void (data null)
  /// Body BẮT BUỘC: {latitude, longitude}. Backend yêu cầu order đang
  /// IN_TRANSIT_LINEHAUL và toạ độ ≤500m kho đích; thành công -> ARRIVED_AT_HUB.
  /// KHÔNG tự đổi trạng thái pallet.
  Future<void> confirmOrderArrival({
    required String orderCode,
    required double latitude,
    required double longitude,
  }) async {
    final encoded = Uri.encodeComponent(orderCode);
    await _client.post(
      'pallet/orders/$encoded/confirm-arrival',
      data: {'latitude': latitude, 'longitude': longitude},
    );
  }
}
