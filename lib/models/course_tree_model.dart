class Lesson {
  final int id;
  final String lessonName;
  final String titel;
  final int order;
  final bool active;
  final String type; // "Video", "Quiz", etc.

  Lesson({
    required this.id,
    required this.lessonName,
    required this.titel,
    required this.order,
    required this.active,
    required this.type,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] ?? json['Id'] ?? 0,
      lessonName: json['lessonName'] ?? json['LessonName'] ?? '',
      titel: json['titel'] ?? json['Titel'] ?? '',
      order: json['order'] ?? json['Order'] ?? 0,
      active: json['active'] ?? json['Active'] ?? false,
      type: json['type']?.toString() ?? json['Type']?.toString() ?? 'Video',
    );
  }

  bool get isQuiz => type.toLowerCase() == 'quiz';
  bool get isVideo => type.toLowerCase() == 'video';
}

class Unit {
  final int id;
  final String unitName;
  final String titel;
  final bool active;
  final int order;
  final DateTime creationDate;
  final DateTime? enrollmentDate;
  final List<Lesson> lessons;

  Unit({
    required this.id,
    required this.unitName,
    required this.titel,
    required this.active,
    required this.order,
    required this.creationDate,
    this.enrollmentDate,
    required this.lessons,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id'] ?? json['Id'] ?? 0,
      unitName: json['unitName'] ?? json['UnitName'] ?? '',
      titel: json['titel'] ?? json['Titel'] ?? '',
      active: json['active'] ?? json['Active'] ?? false,
      order: json['order'] ?? json['Order'] ?? 0,
      creationDate: json['creationDate'] != null || json['CreationDate'] != null
          ? DateTime.parse(json['creationDate'] ?? json['CreationDate'])
          : DateTime.now(),
      enrollmentDate: json['enrollmentDate'] != null || json['EnrollmentDate'] != null
          ? DateTime.parse(json['enrollmentDate'] ?? json['EnrollmentDate'])
          : null,
      lessons: (json['lessons'] ?? json['Lessons'] ?? [])
          .map<Lesson>((l) => Lesson.fromJson(l))
          .toList(),
    );
  }
}

class CourseTree {
  final String id;
  final String courseName;
  final String? term;
  final bool active;
  final double? price;
  final String? grade;
  final String? description;
  final String? imagePath;
  final DateTime modificationDate;
  final bool isOpenToAll;
  final DateTime? enrollmentDate;
  final List<Unit> units;

  CourseTree({
    required this.id,
    required this.courseName,
    this.term,
    required this.active,
    this.price,
    this.grade,
    this.description,
    this.imagePath,
    required this.modificationDate,
    required this.isOpenToAll,
    this.enrollmentDate,
    required this.units,
  });

  factory CourseTree.fromJson(Map<String, dynamic> json) {
    return CourseTree(
      id: json['id'] ?? json['Id'] ?? '',
      courseName: json['courseName'] ?? json['CourseName'] ?? '',
      term: json['term'] ?? json['Term'],
      active: json['active'] ?? json['Active'] ?? false,
      price: (json['price'] ?? json['Price'])?.toDouble(),
      grade: json['grade'] ?? json['Grade'],
      description: json['description'] ?? json['Description'],
      imagePath: json['imagePath'] ?? json['ImagePath'],
      modificationDate: json['modificationDate'] != null || json['ModificationDate'] != null
          ? DateTime.parse(json['modificationDate'] ?? json['ModificationDate'])
          : DateTime.now(),
      isOpenToAll: json['isOpenToAll'] ?? json['IsOpenToAll'] ?? false,
      enrollmentDate: json['enrollmentDate'] != null || json['EnrollmentDate'] != null
          ? DateTime.parse(json['enrollmentDate'] ?? json['EnrollmentDate'])
          : null,
      units: (json['units'] ?? json['Units'] ?? [])
          .map<Unit>((u) => Unit.fromJson(u))
          .toList(),
    );
  }
}

class CourseTreeResponse {
  final bool success;
  final String? message;
  final CourseTree? data;

  CourseTreeResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory CourseTreeResponse.fromJson(Map<String, dynamic> json) {
    CourseTree? tree;
    var dataJson = json['data'] ?? json['Data'];
    if (dataJson != null && dataJson is Map<String, dynamic>) {
      try {
        tree = CourseTree.fromJson(dataJson);
      } catch (_) {
        tree = null;
      }
    }
    // Fallback: API may return course tree at root level
    if (tree == null && (json['units'] != null || json['Units'] != null)) {
      try {
        tree = CourseTree.fromJson(json);
      } catch (_) {}
    }
    return CourseTreeResponse(
      success: json['success'] ?? json['Success'] ?? false,
      message: json['message']?.toString() ?? json['Message']?.toString(),
      data: tree,
    );
  }
}
