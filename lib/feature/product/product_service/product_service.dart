import 'dart:convert';
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

  Future<ProductPageResponse> getProductsPage({
    int page = 0,
    int size = 10,
    String? keyword,
    int? categoryId,
    int? supplierId,
  }) async {
    try {
      final queryParameters = {
        'page': page,
        'size': size,
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
        if (categoryId != null) 'categoryId': categoryId,
        if (supplierId != null) 'supplierId': supplierId,
      };
      
      final response = await _client.get(
        'products/page',
        queryParameters: queryParameters,
      );
      
      if (response.statusCode == 200) {
        final dynamic data = response.data['data'];
        return ProductPageResponse.fromJson(data);
      }
      throw Exception('Failed to load product page');
    } catch (e) {
      developer.log('Error in getProductsPage', error: e);
      rethrow;
    }
  }

  Future<ProductResponse> createProduct(
    ProductCreateRequest request, {
    File? imageFile,
  }) async {
    try {
      final formData = FormData();

      // Backend đang dùng:
      // @RequestPart("data") ProductCreateRequest request
      //
      // Vì vậy toàn bộ request JSON phải được gửi trong part tên "data".
      formData.files.add(
        MapEntry(
          'data',
          MultipartFile.fromString(
            jsonEncode(request.toJson()),
            contentType: DioMediaType.parse('application/json'),
          ),
        ),
      );

      // Backend đang dùng:
      // @RequestPart(value = "image", required = false) MultipartFile image
      if (imageFile != null) {
        formData.files.add(
          MapEntry(
            'image',
            await MultipartFile.fromFile(
              imageFile.path,
              filename: imageFile.path.split(Platform.pathSeparator).last,
            ),
          ),
        );
      }

      final response = await _client.post(
        'products',
        data: formData,

        // Không set Headers.multipartFormDataContentType thủ công.
        // Dio tự thêm Content-Type multipart/form-data kèm boundary chính xác.
        options: Options(
          headers: {
            // Chỉ giữ 2 header này nếu ApiClient của bạn CHƯA tự thêm.
            // 'X-Role-Id': currentRoleId.toString(),
            // 'X-User-Id': currentUserId.toString(),
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;

        final dynamic productData =
            responseData is Map<String, dynamic> && responseData['data'] != null
            ? responseData['data']
            : responseData;

        if (productData is! Map) {
          throw StateError(
            'Product API trả về dữ liệu không hợp lệ: $productData',
          );
        }

        return ProductResponse.fromJson(Map<String, dynamic>.from(productData));
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
