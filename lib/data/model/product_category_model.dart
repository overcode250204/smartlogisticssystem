class ProductCategoryResponse {
  final int categoryId;
  final String categoryCode;
  final String categoryName;
  final String? description;

  const ProductCategoryResponse({
    required this.categoryId,
    required this.categoryCode,
    required this.categoryName,
    this.description,
  });

  factory ProductCategoryResponse.fromJson(Map<String, dynamic> json) {
    return ProductCategoryResponse(
      categoryId: json['categoryId'] as int? ?? 0,
      categoryCode: json['categoryCode']?.toString() ?? '',
      categoryName: json['categoryName']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }
}

class ProductCategoryCreateRequest {
  final String categoryCode;
  final String categoryName;
  final String? description;

  const ProductCategoryCreateRequest({
    required this.categoryCode,
    required this.categoryName,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'categoryCode': categoryCode,
      'categoryName': categoryName,
      'description': description,
    };
  }
}
