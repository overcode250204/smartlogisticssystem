import 'package:smartlogisticssystem/core/networking.dart';
import 'package:smartlogisticssystem/data/model/customer_address_model.dart';

class CustomerAddressService {
  final ApiClient _client = ApiClient();

  Future<List<CustomerAddressModel>> getAddresses() async {
    final response = await _client.get('customer-addresses');
    final data = response.data['data'] as List<dynamic>? ?? const [];
    return data
        .map(
          (item) => CustomerAddressModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<CustomerAddressModel?> getDefaultAddress() async {
    final response = await _client.get('customer-addresses/default');
    final data = response.data['data'];
    if (data == null) return null;
    return CustomerAddressModel.fromJson(data as Map<String, dynamic>);
  }

  Future<CustomerAddressModel> createAddress(
    CustomerAddressRequest request,
  ) async {
    final response = await _client.post(
      'customer-addresses',
      data: request.toJson(),
    );
    return CustomerAddressModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<CustomerAddressModel> updateAddress(
    int id,
    CustomerAddressRequest request,
  ) async {
    final response = await _client.put(
      'customer-addresses/$id',
      data: request.toJson(),
    );
    return CustomerAddressModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<void> deleteAddress(int id) async {
    await _client.delete('customer-addresses/$id');
  }

  Future<CustomerAddressModel> setDefaultAddress(int id) async {
    final response = await _client.patch('customer-addresses/$id/default');
    return CustomerAddressModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }
}
