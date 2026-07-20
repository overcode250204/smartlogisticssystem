import 'dart:convert';

import 'package:smartlogisticssystem/core/networking.dart';
import 'package:smartlogisticssystem/data/model/order_model.dart';
import 'package:smartlogisticssystem/data/model/order_tracking_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class CustomerOrderService {
  final ApiClient _client = ApiClient();

  Future<List<OrderModel>> getMyOrders() async {
    try {
      final response = await _client.get('orders/my-orders');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((item) => OrderModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      if (e is DioException) {
        rethrow;
      }
      rethrow;
    }
  }

  Future<OrderModel> getMyOrderById(int id) async {
    try {
      final response = await _client.get('orders/my-orders/$id');
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

  Future<List<OrderTrackingModel>> getMyOrderTracking(int orderId) async {
    try {
      final response = await _client.get('orders/my-orders/$orderId/tracking');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((item) => OrderTrackingModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<OrderModel> createOrder(OrderCreateRequest request) async {
    try {
      final payload = request.toJson();
      if (kDebugMode) {
        debugPrint('POST /api/orders payload: ${jsonEncode(payload)}');
      }
      final response = await _client.post('orders', data: payload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return OrderModel.fromJson(response.data['data']);
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Không thể tạo đơn hàng',
      );
    } catch (e) {
      rethrow;
    }
  }
}
