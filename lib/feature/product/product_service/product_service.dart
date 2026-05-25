import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:smartlogisticssystem/core/networking.dart';
import 'package:smartlogisticssystem/data/model/product_model.dart';

class ProductService {
  final ApiClient _client = ApiClient();

  Future<List<ProductModel>> getAllProducts() async {
    try {
      final response = await _client.get('products');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((item) => ProductModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      developer.log('Error in getAllProducts', error: e);
      if (e is DioException) {
        developer.log('Response Status Code: ${e.response?.statusCode}');
        developer.log('Response Data: ${e.response?.data}');
      }
      rethrow;
    }
  }

  Future<List<ProductModel>> fetchProducts() async {
    try {
      return await getAllProducts();
    } catch (e) {
      return [];
    }
  }

  Future<ProductModel> createProduct(ProductModel product) async {
    try {
      final response = await _client.post('products', data: product.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic data = response.data['data'];
        return ProductModel.fromJson(data);
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Không thể tạo sản phẩm',
      );
    } catch (e) {
      developer.log('Error creating product', error: e);
      if (e is DioException) {
        developer.log('Response Status Code: ${e.response?.statusCode}');
        developer.log('Response Data: ${e.response?.data}');
      }
      rethrow;
    }
  }

  Future<ProductModel> updateProduct(ProductModel product) async {
    try {
      final response = await _client.put(
        'products/${product.productId}',
        data: product.toJson(),
      );
      if (response.statusCode == 200) {
        final dynamic data = response.data['data'];
        return ProductModel.fromJson(data);
      }
      return ProductModel.empty();
    } catch (e) {
      developer.log('Error updating product', error: e);
      return ProductModel.empty();
    }
  }

  Future<ProductModel> deleteProduct(int id) async {
    try {
      final response = await _client.delete('products/$id');
      if (response.statusCode == 200) {
        final dynamic data = response.data['data'];
        return ProductModel.fromJson(data);
      }
      return ProductModel.empty();
    } catch (e) {
      developer.log('Error deleting product', error: e);
      return ProductModel.empty();
    }
  }

  Future<ProductModel> fetchProductById(int id) async {
    try {
      final response = await _client.get('products/$id');
      if (response.statusCode == 200) {
        final dynamic data = response.data['data'];
        return ProductModel.fromJson(data);
      }
      return ProductModel.empty();
    } catch (e) {
      developer.log('Error fetching product', error: e);
      return ProductModel.empty();
    }
  }
}
