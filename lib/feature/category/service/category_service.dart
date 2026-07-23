import 'package:smartlogisticssystem/core/networking.dart';
import 'package:smartlogisticssystem/data/model/product_category_model.dart';
import 'package:dio/dio.dart';

class CategoryService {
  final ApiClient _client = ApiClient();

  Future<List<ProductCategoryResponse>> getAllCategories() async {
    try {
      final response = await _client.get('categories');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((item) => ProductCategoryResponse.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      if (e is DioException) {
        print('Error fetching categories: ${e.response?.data}');
      }
      rethrow;
    }
  }

  Future<ProductCategoryResponse> createCategory(ProductCategoryCreateRequest request) async {
    try {
      final response = await _client.post('categories', data: request.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ProductCategoryResponse.fromJson(response.data['data']);
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Không thể tạo danh mục',
      );
    } catch (e) {
      if (e is DioException) {
        print('Error creating category: ${e.response?.data}');
      }
      rethrow;
    }
  }

  Future<ProductCategoryResponse?> updateCategory(int id, ProductCategoryCreateRequest request) async {
    try {
      final response = await _client.put('categories/$id', data: request.toJson());
      if (response.statusCode == 200) {
        return ProductCategoryResponse.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteCategory(int id) async {
    try {
      final response = await _client.delete('categories/$id');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
