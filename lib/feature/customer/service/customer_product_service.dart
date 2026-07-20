import 'package:smartlogisticssystem/core/networking.dart';
import 'package:smartlogisticssystem/data/model/product_response_model.dart';
import 'package:smartlogisticssystem/data/model/product_category_model.dart';
import 'package:dio/dio.dart';

class CustomerProductService {
  final ApiClient _client = ApiClient();

  Future<ProductPageResponse> getProductsPage({
    int page = 0,
    int size = 12,
    String? keyword,
    int? categoryId,
    String sortBy = 'productId',
    String sortDirection = 'DESC',
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
        'sortBy': sortBy,
        'sortDirection': sortDirection,
      };
      if (keyword != null && keyword.isNotEmpty) {
        queryParams['keyword'] = keyword;
      }
      if (categoryId != null) {
        queryParams['categoryId'] = categoryId;
      }

      final response = await _client.get(
        'products/page',
        queryParameters: queryParams,
      );
      if (response.statusCode == 200) {
        return ProductPageResponse.fromJson(response.data['data']);
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Không thể lấy danh sách sản phẩm',
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<ProductResponse> getProductById(int id) async {
    try {
      final response = await _client.get('products/$id');
      if (response.statusCode == 200) {
        return ProductResponse.fromJson(response.data['data']);
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Không thể lấy thông tin sản phẩm',
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ProductCategoryResponse>> getCategories() async {
    try {
      final response = await _client.get('categories');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data
            .map((item) => ProductCategoryResponse.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}
