/// Section (Department) model matching backend SectionDto
class Section {
  final int id;
  final String sectionName;
  final bool active;
  final DateTime? createdDate;
  final DateTime? modificationDate;
  final int gradeCount;

  Section({
    required this.id,
    required this.sectionName,
    required this.active,
    this.createdDate,
    this.modificationDate,
    this.gradeCount = 0,
  });

  factory Section.fromJson(Map<String, dynamic> json) {
    // Handle both camelCase and PascalCase field names
    return Section(
      id: (json['id'] ?? json['Id']) as int,
      sectionName: (json['sectionName'] ?? json['SectionName']) as String,
      active: (json['active'] ?? json['Active']) as bool? ?? true,
      createdDate: (json['createdDate'] ?? json['CreatedDate']) != null
          ? DateTime.parse((json['createdDate'] ?? json['CreatedDate']) as String)
          : null,
      modificationDate: (json['modificationDate'] ?? json['ModificationDate']) != null
          ? DateTime.parse((json['modificationDate'] ?? json['ModificationDate']) as String)
          : null,
      gradeCount: (json['gradeCount'] ?? json['GradeCount']) as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sectionName': sectionName,
      'active': active,
      'createdDate': createdDate?.toIso8601String(),
      'modificationDate': modificationDate?.toIso8601String(),
      'gradeCount': gradeCount,
    };
  }
}
