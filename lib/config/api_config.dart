class ApiConfig {
  // Base URL for the API
  static const String baseUrl = 'https://api.ibrahim-magdy.com';

  /// Tenant ID for multi-tenant API (e.g. tenant3, tenant10)
  static const String tenantId = 'tenant11';
  
  // Auth endpoints
  static const String registerEndpoint = '/api/Auth/register';
  static const String loginEndpoint = '/api/Auth/login';
  static const String logoutEndpoint = '/api/Auth/logout';
  static const String refreshTokenEndpoint = '/api/Auth/refresh-token';
  static const String changePasswordEndpoint = '/api/Auth/ChangePassword';
  static const String forgotPasswordEndpoint = '/api/Auth/forgot-password';
  static const String resetPasswordEndpoint = '/api/Auth/reset-password';
  
  // Student endpoints
  static const String studentEnrolledCoursesEndpoint = '/api/Student/Student-Enrolled-Courses';
  static const String addCourseByCodeEndpoint = '/api/Student/add-course-by-code';
  static const String addUnitByCodeEndpoint = '/api/Student/add-Unit-by-code';
  static const String lessonContentEndpoint = '/api/Student/contentlesson'; // /{lessonId}
  static const String lessonCompletionStatusEndpoint = '/api/Student/contentlessonCompletionStatus'; // /{lessonId}
  static const String studentLessonsProgressEndpoint = '/api/Student/GetStudentLessonsProgress'; // /{studentId}
  static const String studentQuizzesProgressEndpoint = '/api/Student/GetStudentQuizzesProgress'; // /{studentId}

  // Course endpoints
  static const String courseTreeEndpoint = '/api/Course/tree';
  static const String courseTreeProgressEndpoint = '/api/Course/tree-course-with-progress';
  static const String unitTreeProgressEndpoint = '/api/Course/tree-unit-with-progress';
  static const String freeCoursesEndpoint = '/api/Course/free-courses';
  static const String coursesByGradeFilterEndpoint = '/api/Course/filter';
  static const String coursesFilterEndpoint = '/api/Course/all';
  
  // Orders (checkout)
  static const String createOrderEndpoint = '/api/Order/create';
  static const String myOrdersEndpoint = '/api/Order/my-orders';
  static String orderByIdEndpoint(String id) => '/api/Order/$id';

  // Promo codes (coupons)
  static const String validatePromoCodeEndpoint = '/api/PromoCode/validate';

  // Teacher endpoints (Existing - verifying if they exist in backend, kept for safety)
  static const String enterTeacherCodeEndpoint = '/api/Teacher/enter-code';
  static const String studentTeachersEndpoint = '/api/Teacher/student/teachers';
  
  // Section (Department) endpoints
  static const String sectionsEndpoint = '/api/Section';
  static String getSectionGradesEndpoint(int sectionId) => '/api/Section/$sectionId/grades';
  
  // Grade endpoints
  static const String gradesEndpoint = '/api/Grade';
  static const String gradesWithCoursesEndpoint = '/api/Grade/with-courses';
  static String getGradesBySectionEndpoint(int? sectionId) => sectionId != null 
      ? '/api/Grade?sectionId=$sectionId' 
      : '/api/Grade';

  // Subject endpoints (by gradeId from login)
  static const String subjectsEndpoint = '/api/Subject';
  static String subjectsByGradeUrl(String gradeId) =>
      '$baseUrl$subjectsEndpoint?gradeId=$gradeId';
  
  // Aliases for backward compatibility
  static const String enrollEndpoint = addCourseByCodeEndpoint;
  static const String enrolledCoursesEndpoint = studentEnrolledCoursesEndpoint;

  // Full URLs
  static String get registerUrl => '$baseUrl$registerEndpoint';
  static String get loginUrl => '$baseUrl$loginEndpoint';
  static String get logoutUrl => '$baseUrl$logoutEndpoint';
  static String get refreshTokenUrl => '$baseUrl$refreshTokenEndpoint';
  static String get forgotPasswordUrl => '$baseUrl$forgotPasswordEndpoint';
  static String get resetPasswordUrl => '$baseUrl$resetPasswordEndpoint';
  
  static String get studentEnrolledCoursesUrl => '$baseUrl$studentEnrolledCoursesEndpoint';
  
  // Backward compatibility getters
  static String get enrolledCoursesUrl => '$baseUrl$enrolledCoursesEndpoint';
  static String get enterTeacherCodeUrl => '$baseUrl$enterTeacherCodeEndpoint';
  static String get studentTeachersUrl => '$baseUrl$studentTeachersEndpoint';
  
  static String getSubjectsForTeacherUrl(String teacherId) => '$baseUrl/api/TeacherSubject/subjects-for-teacher/$teacherId';

  // Orders
  static String get createOrderUrl => '$baseUrl$createOrderEndpoint';

  // App config endpoint
  static const String appConfigEndpoint = '/api/appconfig';
  static String get appConfigUrl => '$baseUrl$appConfigEndpoint';
  static String get myOrdersUrl => '$baseUrl$myOrdersEndpoint';
  static String orderByIdUrl(String id) => '$baseUrl${orderByIdEndpoint(id)}';

  // Promo codes
  static String get validatePromoCodeUrl => '$baseUrl$validatePromoCodeEndpoint';
  
  // Section and Grade URLs
  static String get sectionsUrl => '$baseUrl$sectionsEndpoint';
  static String getSectionGradesUrl(int sectionId) => '$baseUrl${getSectionGradesEndpoint(sectionId)}';
  static String get gradesUrl => '$baseUrl$gradesEndpoint';
  static String getGradesBySectionUrl(int? sectionId) => '$baseUrl${getGradesBySectionEndpoint(sectionId)}';
  static String get gradesWithCoursesUrl => '$baseUrl$gradesWithCoursesEndpoint';
  
  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String deviceIdKey = 'device_id';
  
  /// Get full image URL from relative path
  /// Handles both relative paths (starting with /) and full URLs
  static String getImageUrl(String? path) {
    if (path == null || path.isEmpty) {
      return '';
    }
    
    // If already a full URL, return as is
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    
    // If starts with /, prepend base URL
    if (path.startsWith('/')) {
      return '$baseUrl$path';
    }
    
    // If doesn't start with /, assume it's a relative path and add /
    return '$baseUrl/$path';
  }
}
