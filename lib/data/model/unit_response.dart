enum UnitType {
  WEIGHT,
  DIMENSION,
  QUANTITY,
  VOLUME,
}

class UnitResponse {
  final int id;
  final String code;
  final String name;
  final UnitType type;

  const UnitResponse({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
  });

  factory UnitResponse.fromJson(Map<String, dynamic> json) {
    return UnitResponse(
      id: _parseInt(json['unitId'] ?? json['id']),
      code: (json['unitCode'] ?? json['code'] ?? '').toString(),
      name: (json['unitName'] ?? json['name'] ?? '').toString(),
      type: _parseUnitType(json['unitType'] ?? json['type']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static UnitType _parseUnitType(dynamic value) {
    final raw = value?.toString().trim().toUpperCase();

    return UnitType.values.firstWhere(
      (type) => type.name == raw,
      orElse: () => UnitType.QUANTITY,
    );
  }
}
