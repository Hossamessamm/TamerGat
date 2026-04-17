class Course {
  final String id;
  final String courseName;
  final String? imagePath;
  final String? description;
  final DateTime modificationDate;
  final double? price;
  final String? term;
  final String? grade;
  final String? teacherName;
  final String? teacherId;
  final String? groupLink;

  Course({
    required this.id,
    required this.courseName,
    this.imagePath,
    this.description,
    required this.modificationDate,
    this.price,
    this.term,
    this.grade,
    this.teacherName,
    this.teacherId,
    this.groupLink,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['Id'] ?? json['id'] ?? '',
      courseName: json['CourseName'] ?? json['courseName'] ?? '',
      imagePath: json['ImagePath'] ?? json['imagePath'],
      description: json['Description'] ?? json['description'],
      modificationDate: (json['ModificationDate'] ?? json['modificationDate']) != null
          ? DateTime.parse(json['ModificationDate'] ?? json['modificationDate'])
          : DateTime.now(),
      price: (json['Price'] ?? json['price'])?.toDouble(),
      term: json['Term'] ?? json['term'],
      grade: json['Grade'] ?? json['grade'] ?? json['GradeName'] ?? json['gradeName'],
      teacherName: json['TeacherName'] ?? json['teacherName'],
      teacherId: json['TeacherId'] ?? json['teacherId'],
      groupLink: json['GroupLink'] ?? json['groupLink'],
    );
  }
}

class EnrolledCoursesResponse {
  final int totalCount;
  final int totalPages;
  final int currentPage;
  final int pageSize;
  final List<Course> courses;

  /// Optional message from the API (e.g. when [courses] is empty but the call succeeded).
  final String? apiMessage;

  EnrolledCoursesResponse({
    required this.totalCount,
    required this.totalPages,
    required this.currentPage,
    required this.pageSize,
    required this.courses,
    this.apiMessage,
  });

  factory EnrolledCoursesResponse.fromJson(Map<String, dynamic> json) {
    // Handle nested data structure from /api/Course/filter endpoint
    // Response structure: {success: true, data: {currentPage: 1, data: [...]}}
    dynamic data = json['data'] ?? json;
    
    // If data is a Map and contains another 'data' field, use that for courses
    List<dynamic> coursesList = [];
    int totalCount = 0;
    int totalPages = 0;
    int currentPage = 1;
    int pageSize = 10;
    
    if (data is Map<String, dynamic>) {
      // Extract pagination info
      totalCount = _parseInt(data['TotalCount'] ?? data['totalCount'], 0);
      totalPages = _parseInt(data['TotalPages'] ?? data['totalPages'], 0);
      currentPage = _parseInt(data['CurrentPage'] ?? data['currentPage'], 1);
      pageSize = _parseInt(data['PageSize'] ?? data['pageSize'], 10);
      
      // Check for nested data structure (courses list)
      if (data.containsKey('data') && data['data'] is List) {
        coursesList = data['data'] as List<dynamic>;
      } else if (data.containsKey('Data') && data['Data'] is List) {
        coursesList = data['Data'] as List<dynamic>;
      } else if (data.containsKey('Courses') && data['Courses'] is List) {
        coursesList = data['Courses'] as List<dynamic>;
      } else if (data.containsKey('courses') && data['courses'] is List) {
        coursesList = data['courses'] as List<dynamic>;
      }
    }
    
    return EnrolledCoursesResponse(
      totalCount: totalCount,
      totalPages: totalPages,
      currentPage: currentPage,
      pageSize: pageSize,
      apiMessage: null,
      courses: coursesList
          .map<Course>((c) {
            if (c is Map<String, dynamic>) {
              return Course.fromJson(c);
            } else {
              throw FormatException('Expected Map but got ${c.runtimeType}');
            }
          })
          .toList(),
    );
  }
  
  static int _parseInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    if (value is double) return value.toInt();
    return defaultValue;
  }
}
