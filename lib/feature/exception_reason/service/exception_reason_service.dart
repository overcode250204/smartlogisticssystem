import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:smartlogisticssystem/core/networking.dart';
import 'package:smartlogisticssystem/data/model/exception_reason_model.dart';

class ExceptionReasonService {
  final ApiClient _client = ApiClient();

  Future<List<ExceptionReasonModel>> getAllExceptionReasons() async {
    try {
      final response = await _client.get('admin/exception-reasons');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((item) => ExceptionReasonModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      developer.log('Error in getAllExceptionReasons', error: e);
      rethrow;
    }
  }

  Future<ExceptionReasonModel> createExceptionReason(ExceptionReasonCreateRequest request) async {
    try {
      final response = await _client.post('admin/exception-reasons', data: request.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ExceptionReasonModel.fromJson(response.data['data']);
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Không thể tạo lý do ngoại lệ',
      );
    } catch (e) {
      developer.log('Error in createExceptionReason', error: e);
      rethrow;
    }
  }

  Future<ExceptionReasonModel> updateExceptionReason(
    int id,
    ExceptionReasonUpdateRequest request,
  ) async {
    try {
      final response = await _client.put(
        'admin/exception-reasons/$id',
        data: request.toJson(),
      );
      if (response.statusCode == 200) {
        return ExceptionReasonModel.fromJson(response.data['data']);
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Không thể cập nhật lý do ngoại lệ',
      );
    } catch (e) {
      developer.log('Error in updateExceptionReason', error: e);
      rethrow;
    }
  }

  Future<void> deleteExceptionReason(int id) async {
    try {
      final response = await _client.delete('admin/exception-reasons/$id');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Không thể xóa lý do ngoại lệ',
        );
      }
    } catch (e) {
      developer.log('Error in deleteExceptionReason', error: e);
      rethrow;
    }
  }
}
