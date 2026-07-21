import 'package:smartlogisticssystem/core/networking.dart';
import 'package:smartlogisticssystem/data/model/pallet_item_model.dart';
import 'package:smartlogisticssystem/data/model/pallet_model.dart';

class PalletTaskService {
  final ApiClient _client = ApiClient();

  Future<List<PalletModel>> getTasks() async {
    final response = await _client.get('pallet/staff/tasks');
    final data = response.data['data'] as List<dynamic>? ?? const [];
    return data
        .map((item) => PalletModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<PalletModel> getTaskById(int palletId) async {
    final response = await _client.get('pallet/staff/tasks/$palletId');
    return PalletModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

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

  Future<PalletModel> markCanSeal(int palletId) async {
    final response = await _client.post('pallet/$palletId/can-seal');
    return PalletModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<PalletModel> seal(int palletId) async {
    final response = await _client.post('pallet/$palletId/seal');
    return PalletModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
