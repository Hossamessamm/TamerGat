/// Grade model matching backend GradeDto
class Grade {
  final String id;
  final String name;
  final String? description;
  final int level;
  final String? code;
  final String? roleName;
  final bool active;
  final DateTime? createdDate;
  final DateTime? modificationDate;
  final int subjectCount;
  final int? sectionId;
  final String? sectionName;

  Grade({
    required this.id,
    required this.name,
    this.description,
    required this.level,
    this.code,
    this.roleName,
    this.active = true,
    this.createdDate,
    this.modificationDate,
    this.subjectCount = 0,
    this.sectionId,
    this.sectionName,
  });

  factory Grade.fromJson(Map<String, dynamic> json) {
    // Handle both camelCase and PascalCase field names
    return Grade(
      id: (json['id'] ?? json['Id']) as String,
      name: (json['name'] ?? json['Name']) as String,
      description: (json['description'] ?? json['Description']) as String?,
      level: (json['level'] ?? json['Level']) as int,
      code: (json['code'] ?? json['Code']) as String?,
      roleName: (json['roleName'] ?? json['RoleName']) as String?,
      active: (json['active'] ?? json['Active']) as bool? ?? true,
      createdDate: (json['createdDate'] ?? json['CreatedDate']) != null
          ? DateTime.parse((json['createdDate'] ?? json['CreatedDate']) as String)
          : null,
      modificationDate: (json['modificationDate'] ?? json['ModificationDate']) != null
          ? DateTime.parse((json['modificationDate'] ?? json['ModificationDate']) as String)
          : null,
      subjectCount: (json['subjectCount'] ?? json['SubjectCount']) as int? ?? 0,
      sectionId: (json['sectionId'] ?? json['SectionId']) as int?,
      sectionName: (json['sectionName'] ?? json['SectionName']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'level': level,
      'code': code,
      'roleName': roleName,
      'active': active,
      'createdDate': createdDate?.toIso8601String(),
      'modificationDate': modificationDate?.toIso8601String(),
      'subjectCount': subjectCount,
      'sectionId': sectionId,
      'sectionName': sectionName,
    };
  }
}

/// Minimal grade info from "grades with courses" API: [{"id": 11, "name": "Secondary3"}]
class GradeWithCourses {
  final int id;
  final String name;

  GradeWithCourses({required this.id, required this.name});

  factory GradeWithCourses.fromJson(Map<String, dynamic> json) {
    final id = json['id'] ?? json['Id'];
    int parsedId = 0;
    if (id != null) {
      if (id is int) {
        parsedId = id;
      } else {
        parsedId = int.tryParse(id.toString()) ?? 0;
      }
    }
    final nameRaw = json['name'] ?? json['Name'];
    final name = nameRaw is String
        ? nameRaw
        : (nameRaw?.toString() ?? '').trim();
    return GradeWithCourses(
      id: parsedId,
      name: name.isEmpty ? 'Unnamed' : name,
    );
  }
}
