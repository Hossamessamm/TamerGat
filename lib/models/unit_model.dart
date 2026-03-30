class Unit {
  final int unitId;
  final String unitName;
  final String? unitTitle;
  final String courseId;
  final String courseName;
  final String grade;
  final String? term;
  final bool active;
  final DateTime? enrollmentDate;

  Unit({
    required this.unitId,
    required this.unitName,
    this.unitTitle,
    required this.courseId,
    required this.courseName,
    required this.grade,
    this.term,
    required this.active,
    this.enrollmentDate,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      unitId: json['unitId'] as int,
      unitName: json['unitName'] as String,
      unitTitle: json['unitTitle'] as String?,
      courseId: json['courseId'] as String,
      courseName: json['courseName'] as String,
      grade: json['grade'] as String,
      term: json['term'] as String?,
      active: json['active'] as bool? ?? true,
      enrollmentDate: json['enrollmentDate'] != null
          ? DateTime.parse(json['enrollmentDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'unitId': unitId,
      'unitName': unitName,
      'unitTitle': unitTitle,
      'courseId': courseId,
      'courseName': courseName,
      'grade': grade,
      'term': term,
      'active': active,
      'enrollmentDate': enrollmentDate?.toIso8601String(),
    };
  }
}

class UnitsResponse {
  final int totalCount;
  final int totalPages;
  final int currentPage;
  final int pageSize;
  final List<Unit> units;

  UnitsResponse({
    required this.totalCount,
    required this.totalPages,
    required this.currentPage,
    required this.pageSize,
    required this.units,
  });

  factory UnitsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    
    return UnitsResponse(
      totalCount: data['totalCount'] as int? ?? 0,
      totalPages: data['totalPages'] as int? ?? 1,
      currentPage: data['currentPage'] as int? ?? 1,
      pageSize: data['pageSize'] as int? ?? 10,
      units: (data['units'] as List<dynamic>?)
              ?.map((item) => Unit.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class EnterCodeResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  EnterCodeResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory EnterCodeResponse.fromJson(Map<String, dynamic> json) {
    return EnterCodeResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>?,
    );
  }
}
