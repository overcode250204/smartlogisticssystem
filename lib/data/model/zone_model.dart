class ZoneModel {
  final int id;
  final String name;
  final Map<String, dynamic> coverageArea;
  final DateTime? createAt;

  const ZoneModel({
    required this.id,
    required this.name,
    required this.coverageArea,
    this.createAt,
  });

  factory ZoneModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['createAt'] != null) {
      try {
        parsedDate = DateTime.parse(json['createAt'].toString());
      } catch (_) {
        // ignore
      }
    }
    return ZoneModel(
      id: json['id'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      coverageArea: Map<String, dynamic>.from(json['coverageArea'] ?? {}),
      createAt: parsedDate,
    );
  }
}

class ZoneCreateRequest {
  final String name;
  final Map<String, dynamic> coverageArea;

  const ZoneCreateRequest({
    required this.name,
    required this.coverageArea,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'coverageArea': coverageArea,
    };
  }
}
