import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:smartlogisticssystem/core/networking.dart';
import 'package:smartlogisticssystem/data/model/product_request_model.dart';
import 'package:smartlogisticssystem/data/model/product_response_model.dart';

class ProductService {
  final ApiClient _client = ApiClient();

  String _messageFromDio(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return e.message ?? fallback;
  }

  ProductResponse _parseProductResponse(dynamic responseData) {
    final dynamic productData =
        responseData is Map<String, dynamic> && responseData['data'] != null
        ? responseData['data']
        : responseData;

    if (productData is Map<String, dynamic>) {
      return ProductResponse.fromJson(productData);
    }
    if (productData is Map) {
      return ProductResponse.fromJson(Map<String, dynamic>.from(productData));
    }

    throw StateError('Product API trả về dữ liệu không hợp lệ: $productData');
  }

  Future<List<ProductResponse>> getAllProducts() async {
    try {
      final response = await _client.get('products');
      if (response.statusCode == 200) {
        final rawData = response.data is Map<String, dynamic>
            ? response.data['data']
            : response.data;
        if (rawData is! List) {
          throw StateError('Danh sách sản phẩm trả về không hợp lệ');
        }
        return rawData
            .map(
              (item) => ProductResponse.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList();
      }
      throw Exception('Không thể tải danh sách sản phẩm');
    } catch (e) {
      developer.log('Error in getAllProducts', error: e);
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
      final response = await _client.get(
        'products/page',
        queryParameters: {
          'page': page,
          'size': size,
          if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
          if (categoryId != null) 'categoryId': categoryId,
          if (supplierId != null) 'supplierId': supplierId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data is Map<String, dynamic>
            ? response.data['data']
            : response.data;
        if (data is Map<String, dynamic>) {
          return ProductPageResponse.fromJson(data);
        }
        if (data is Map) {
          return ProductPageResponse.fromJson(Map<String, dynamic>.from(data));
        }
        throw StateError('Product page response is invalid: $data');
      }

      throw Exception('Không thể tải trang sản phẩm');
    } catch (e) {
      developer.log('Error in getProductsPage', error: e);
      rethrow;
    }
  }

  Future<ProductResponse> getProductById(int id) async {
    try {
      final response = await _client.get('products/$id');
      if (response.statusCode == 200) {
        return _parseProductResponse(response.data);
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Không thể tải chi tiết sản phẩm',
      );
    } on DioException catch (e) {
      developer.log('Error fetching product', error: e);
      throw Exception(_messageFromDio(e, 'Không thể tải chi tiết sản phẩm'));
    }
  }

  Future<ProductResponse?> fetchProductById(int id) async {
    try {
      return await getProductById(id);
    } catch (_) {
      return null;
    }
  }

  Future<ProductResponse> createProduct(
    ProductCreateRequest request, {
    File? imageFile,
  }) async {
    try {
      final formData = FormData();
      formData.files.add(
        MapEntry(
          'data',
          MultipartFile.fromString(
            jsonEncode(request.toJson()),
            contentType: DioMediaType.parse('application/json'),
          ),
        ),
      );

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

      final response = await _client.post('products', data: formData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return _parseProductResponse(response.data);
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Không thể tạo sản phẩm',
      );
    } on DioException catch (e, stackTrace) {
      developer.log('Error creating product', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<ProductResponse> updateProduct(
    int id,
    ProductUpdateRequest request, {
    File? imageFile,
    bool removeImage = false,
  }) async {
    try {
      late final Response<dynamic> response;

      if (imageFile != null || removeImage) {
        final formData = FormData();
        formData.files.add(
          MapEntry(
            'data',
            MultipartFile.fromString(
              jsonEncode(request.toJson()),
              contentType: DioMediaType.parse('application/json'),
            ),
          ),
        );

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

        response = await _client.put(
          'products/$id',
          data: formData,
          queryParameters: {'removeImage': removeImage},
        );
      } else {
        response = await _client.put(
          'products/$id',
          data: request.toJson(),
        );
      }

      if (response.statusCode == 200) {
        return _parseProductResponse(response.data);
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Không thể cập nhật sản phẩm',
      );
    } on DioException catch (e) {
      developer.log('Error updating product', error: e);
      throw Exception(_messageFromDio(e, 'Không thể cập nhật sản phẩm'));
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      final response = await _client.delete('products/$id');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Không thể xóa sản phẩm',
        );
      }
    } on DioException catch (e) {
      developer.log('Error deleting product', error: e);
      throw Exception(_messageFromDio(e, 'Không thể xóa sản phẩm'));
    }
  }
}
