import 'dart:developer' as developer;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:smartlogisticssystem/core/networking.dart';
import 'package:smartlogisticssystem/data/model/product_request_model.dart';
import 'package:smartlogisticssystem/data/model/product_response_model.dart';

class ProductService {
  final ApiClient _client = ApiClient();

  Future<List<ProductResponse>> getAllProducts() async {
    try {
      final response = await _client.get('products');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((item) => ProductResponse.fromJson(item)).toList();
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

  Future<List<ProductResponse>> fetchProducts() async {
    try {
      return await getAllProducts();
    } catch (e) {
      return [];
    }
  }

  Future<ProductResponse> createProduct(
    ProductCreateRequest request, {
    File? imageFile,
  }) async {
    try {
      final formData = FormData.fromMap({
        ...request.toJson(),

        // Tên key phải trùng với @RequestParam / @RequestPart bên Backend.
        if (imageFile != null)
          'image': await MultipartFile.fromFile(
            imageFile.path,
            filename: imageFile.path.split('/').last,
          ),
      });

      final response = await _client.post(
        'products',
        data: formData,
        options: Options(contentType: Headers.multipartFormDataContentType),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;

        // Hỗ trợ cả API format { data: {...} } và response trả object trực tiếp.
        final dynamic productData =
            responseData is Map<String, dynamic> && responseData['data'] != null
            ? responseData['data']
            : responseData;

        return ProductResponse.fromJson(
          Map<String, dynamic>.from(productData as Map),
        );
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Không thể tạo sản phẩm',
      );
    } on DioException catch (e, stackTrace) {
      developer.log('Error creating product', error: e, stackTrace: stackTrace);
      developer.log('Response Status Code: ${e.response?.statusCode}');
      developer.log('Response Data: ${e.response?.data}');
      rethrow;
    } catch (e, stackTrace) {
      developer.log(
        'Unexpected error creating product',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<ProductResponse?> updateProduct(
    int id,
    ProductUpdateRequest request,
  ) async {
    try {
      final response = await _client.put(
        'products/$id',
        data: request.toJson(),
      );
      if (response.statusCode == 200) {
        final dynamic data = response.data['data'];
        return ProductResponse.fromJson(data);
      }
      return null;
    } catch (e) {
      developer.log('Error updating product', error: e);
      return null;
    }
  }

  Future<ProductResponse?> deleteProduct(int id) async {
    try {
      final response = await _client.delete('products/$id');
      if (response.statusCode == 200) {
        final dynamic data = response.data['data'];
        return ProductResponse.fromJson(data);
      }
      return null;
    } catch (e) {
      developer.log('Error deleting product', error: e);
      return null;
    }
  }

  Future<ProductResponse?> fetchProductById(int id) async {
    try {
      final response = await _client.get('products/$id');
      if (response.statusCode == 200) {
        final dynamic data = response.data['data'];
        return ProductResponse.fromJson(data);
      }
      return null;
    } catch (e) {
      developer.log('Error fetching product', error: e);
      return null;
    }
  }
}
