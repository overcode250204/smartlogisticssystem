import 'package:smartlogisticssystem/core/networking.dart';
import 'package:smartlogisticssystem/data/model/order_model.dart';
import 'package:dio/dio.dart';

class OrderService {
  final ApiClient _client = ApiClient();

  Future<List<OrderModel>> getAllOrders() async {
    try {
      final response = await _client.get('orders');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((item) => OrderModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      if (e is DioException) {
        print('Error fetching orders: ${e.response?.data}');
      }
      rethrow;
    }
  }

  Future<OrderModel> getOrderById(int id) async {
    try {
      final response = await _client.get('orders/$id');
      if (response.statusCode == 200) {
        return OrderModel.fromJson(response.data['data']);
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Không thể lấy thông tin đơn hàng',
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<OrderModel> updateOrder(int id, OrderCreateRequest request) async {
    try {
      final response = await _client.put('orders/$id', data: request.toJson());
      if (response.statusCode == 200) {
        return OrderModel.fromJson(response.data['data']);
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Không thể cập nhật đơn hàng',
      );
    } catch (e) {
      if (e is DioException) {
        print('Error updating order: ${e.response?.data}');
      }
      rethrow;
    }
  }

  Future<OrderModel> cancelOrder(int id) async {
    try {
      final response = await _client.put('orders/$id/cancel');
      if (response.statusCode == 200) {
        return OrderModel.fromJson(response.data['data']);
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Không thể hủy đơn hàng',
      );
    } catch (e) {
      if (e is DioException) {
        print('Error cancelling order: ${e.response?.data}');
      }
      rethrow;
    }
  }
}
