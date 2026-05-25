import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:smartlogisticssystem/core/networking.dart';
import 'package:smartlogisticssystem/data/model/supplier_request_model.dart';
import 'package:smartlogisticssystem/data/model/supplier_response_model.dart';

class SupplierService {
  final ApiClient _client = ApiClient();

  Future<List<SupplierResponse>> getAllSuppliers() async {
    try {
      final response = await _client.get('suppliers');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((item) => SupplierResponse.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      developer.log('Error in getAllSuppliers', error: e);
      if (e is DioException) {
        developer.log('Response Status Code: ${e.response?.statusCode}');
        developer.log('Response Data: ${e.response?.data}');
      }
      rethrow;
    }
  }

  Future<SupplierResponse> createSupplier(SupplierCreateRequest request) async {
    try {
      final response = await _client.post('suppliers', data: request.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        return SupplierResponse.fromJson(response.data['data']);
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Không thể tạo nhà cung cấp',
      );
    } catch (e) {
      developer.log('Error in createSupplier', error: e);
      if (e is DioException) {
        developer.log('Response Status Code: ${e.response?.statusCode}');
        developer.log('Response Data: ${e.response?.data}');
      }
      rethrow;
    }
  }

  Future<SupplierResponse> updateSupplier(int id, SupplierUpdateRequest request) async {
    try {
      final response = await _client.put(
        'suppliers/$id',
        data: request.toJson(),
      );
      if (response.statusCode == 200) {
        return SupplierResponse.fromJson(response.data['data']);
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Không thể cập nhật nhà cung cấp',
      );
    } catch (e) {
      developer.log('Error in updateSupplier', error: e);
      if (e is DioException) {
        developer.log('Response Status Code: ${e.response?.statusCode}');
        developer.log('Response Data: ${e.response?.data}');
      }
      rethrow;
    }
  }

  Future<void> deleteSupplier(int id) async {
    try {
      final response = await _client.delete('suppliers/$id');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Không thể xóa nhà cung cấp',
        );
      }
    } catch (e) {
      developer.log('Error in deleteSupplier', error: e);
      if (e is DioException) {
        developer.log('Response Status Code: ${e.response?.statusCode}');
        developer.log('Response Data: ${e.response?.data}');
      }
      rethrow;
    }
  }
}
