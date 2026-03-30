class Subject {
  final String id;
  final String name;
  final String? description;
  final String code;
  final bool active;
  final DateTime? createdDate;
  final DateTime? modificationDate;
  final String? gradeId;
  final String? gradeName;
  final int teacherCount;
  final int courseCount;

  Subject({
    required this.id,
    required this.name,
    this.description,
    required this.code,
    this.active = true,
    this.createdDate,
    this.modificationDate,
    this.gradeId,
    this.gradeName,
    this.teacherCount = 0,
    this.courseCount = 0,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: (json['id'] ?? json['Id'])?.toString() ?? '',
      name: (json['name'] ?? json['Name'])?.toString() ?? '',
      description: (json['description'] ?? json['Description'])?.toString(),
      code: (json['code'] ?? json['Code'])?.toString() ?? '',
      active: json['active'] ?? json['Active'] ?? true,
      createdDate: _parseDate(json['createdDate'] ?? json['CreatedDate']),
      modificationDate: _parseDate(json['modificationDate'] ?? json['ModificationDate']),
      gradeId: (json['gradeId'] ?? json['GradeId'])?.toString(),
      gradeName: (json['gradeName'] ?? json['GradeName'])?.toString(),
      teacherCount: _parseInt(json['teacherCount'] ?? json['TeacherCount'], 0),
      courseCount: _parseInt(json['courseCount'] ?? json['CourseCount'], 0),
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  static int _parseInt(dynamic v, int def) {
    if (v == null) return def;
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? def;
    if (v is double) return v.toInt();
    return def;
  }
}

class TeacherSubjectsResponse {
  final bool success;
  final String message;
  final List<Subject> data;

  TeacherSubjectsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory TeacherSubjectsResponse.fromJson(Map<String, dynamic> json) {
    return TeacherSubjectsResponse(
      success: json['success'],
      message: json['message'],
      data: (json['data'] as List).map((e) => Subject.fromJson(e)).toList(),
    );
  }
}
