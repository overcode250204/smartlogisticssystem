import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:smartlogisticssystem/core/networking.dart';
import 'package:smartlogisticssystem/data/model/invoice_request_model.dart';
import 'package:smartlogisticssystem/data/model/invoice_response_model.dart';

class InvoiceService {
  final ApiClient _client = ApiClient();

  Future<List<InvoiceResponse>> getAllInvoices() async {
    try {
      final response = await _client.get('invoices');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((item) => InvoiceResponse.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      developer.log('Error in getAllInvoices', error: e);
      if (e is DioException) {
        developer.log('Response Status Code: ${e.response?.statusCode}');
        developer.log('Response Data: ${e.response?.data}');
      }
      rethrow;
    }
  }

  Future<InvoiceResponse> createInvoice(InvoiceCreateRequest request) async {
    try {
      final response = await _client.post('invoices', data: request.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        return InvoiceResponse.fromJson(response.data['data']);
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Không thể tạo hóa đơn',
      );
    } catch (e) {
      developer.log('Error in createInvoice', error: e);
      if (e is DioException) {
        developer.log('Response Status Code: ${e.response?.statusCode}');
        developer.log('Response Data: ${e.response?.data}');
      }
      rethrow;
    }
  }

  Future<InvoiceResponse> updateInvoice(
      int id, InvoiceUpdateRequest request) async {
    try {
      final response =
          await _client.put('invoices/$id', data: request.toJson());
      if (response.statusCode == 200) {
        return InvoiceResponse.fromJson(response.data['data']);
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Không thể cập nhật hóa đơn',
      );
    } catch (e) {
      developer.log('Error in updateInvoice', error: e);
      if (e is DioException) {
        developer.log('Response Status Code: ${e.response?.statusCode}');
        developer.log('Response Data: ${e.response?.data}');
      }
      rethrow;
    }
  }

  Future<void> deleteInvoice(int id) async {
    try {
      final response = await _client.delete('invoices/$id');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Không thể xóa hóa đơn',
        );
      }
    } catch (e) {
      developer.log('Error in deleteInvoice', error: e);
      if (e is DioException) {
        developer.log('Response Status Code: ${e.response?.statusCode}');
        developer.log('Response Data: ${e.response?.data}');
      }
      rethrow;
    }
  }

  Future<DashboardStatsResponse> getDashboardStats() async {
    try {
      final response = await _client.get('invoices/dashboard');
      if (response.statusCode == 200) {
        return DashboardStatsResponse.fromJson(response.data['data']);
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Không thể tải dữ liệu dashboard',
      );
    } catch (e) {
      developer.log('Error in getDashboardStats', error: e);
      if (e is DioException) {
        developer.log('Response Status Code: ${e.response?.statusCode}');
        developer.log('Response Data: ${e.response?.data}');
      }
      rethrow;
    }
  }
}
