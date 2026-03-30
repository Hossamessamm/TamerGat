import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/course_model.dart';
import '../models/course_tree_model.dart';
import '../models/api_response.dart';
import '../models/course_tree_progress_model.dart';
import '../models/lesson_content_model.dart';
import 'api_debug_service.dart';
import '../utils/http_client_helper.dart';
import '../utils/authenticated_api_client.dart';
import 'auth_service.dart';

class CourseService {
  /// Get student's enrolled courses with pagination
  static Future<EnrolledCoursesResponse?> getEnrolledCourses({
    required String studentId,
    required String token,
    AuthService? authService,
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    try {
      final url = '${ApiConfig.enrolledCoursesUrl}?studentId=$studentId&pagenumber=$pageNumber&pagesize=$pageSize';

      // Log request
      ApiDebugService().logRequest(
        method: 'GET',
        url: url,
        headers: {'Authorization': 'Bearer $token'},
      );

      // Use AuthenticatedApiClient if authService is provided for automatic token refresh
      http.Response response;
      if (authService != null) {
        final client = AuthenticatedApiClient(authService);
        response = await client.get(Uri.parse(url));
      } else {
        response = await HttpClientHelper.get(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );
      }

      // Log response
      ApiDebugService().logResponse(
        method: 'GET',
        url: url,
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return EnrolledCoursesResponse.fromJson(responseData);
      } else {
        return null;
      }
    } catch (e) {
      ApiDebugService().logError(
        method: 'GET',
        url: ApiConfig.enrolledCoursesUrl,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Get courses filtered by teacher and grade
  static Future<EnrolledCoursesResponse?> getFilteredCourses({
    required String teacherId,
    required String gradeId,
    required String token,
    AuthService? authService,
    int pageNumber = 1,
    int pageSize = 10,
    bool? active,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{
        'TeacherId': teacherId,
        'GradeId': gradeId,
        'PageNumber': pageNumber.toString(),
        'PageSize': pageSize.toString(),
      };
      
      if (active != null) {
        queryParams['Active'] = active.toString();
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/Course/all').replace(
        queryParameters: queryParams,
      );

      // Log request
      ApiDebugService().logRequest(
        method: 'GET',
        url: uri.toString(),
        headers: {'Authorization': 'Bearer $token'},
      );

      // Use AuthenticatedApiClient if authService is provided for automatic token refresh
      http.Response response;
      if (authService != null) {
        final client = AuthenticatedApiClient(authService);
        response = await client.get(uri);
      } else {
        response = await HttpClientHelper.get(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
          },
        );
      }

      // Log response
      ApiDebugService().logResponse(
        method: 'GET',
        url: uri.toString(),
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return EnrolledCoursesResponse.fromJson(responseData);
      } else {
        return null;
      }
    } catch (e) {
      ApiDebugService().logError(
        method: 'GET',
        url: '${ApiConfig.baseUrl}/api/Course/all',
        error: e.toString(),
      );
      return null;
    }
  }

  /// Get courses filtered by subject (for subject-detail screen).
  /// GET /api/Course/all?SubjectId=...&PageNumber=1&PageSize=50
  static Future<EnrolledCoursesResponse?> getCoursesBySubjectId({
    required String subjectId,
    String? token,
    AuthService? authService,
    int pageNumber = 1,
    int pageSize = 50,
  }) async {
    try {
      final queryParams = <String, String>{
        'SubjectId': subjectId,
        'PageNumber': pageNumber.toString(),
        'PageSize': pageSize.toString(),
      };
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.coursesFilterEndpoint}').replace(
        queryParameters: queryParams,
      );

      final headers = <String, String>{};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      // Log request
      ApiDebugService().logRequest(
        method: 'GET',
        url: uri.toString(),
        headers: headers.isNotEmpty ? headers : null,
      );

      // Use AuthenticatedApiClient if authService is provided for automatic token refresh
      http.Response response;
      if (authService != null) {
        final client = AuthenticatedApiClient(authService);
        response = await client.get(uri);
      } else {
        response = await HttpClientHelper.get(uri, headers: headers.isNotEmpty ? headers : null);
      }

      // Log response
      ApiDebugService().logResponse(
        method: 'GET',
        url: uri.toString(),
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      if (response.statusCode != 200) return null;

      final responseData = json.decode(response.body);
      return EnrolledCoursesResponse.fromJson(responseData);
    } catch (e) {
      ApiDebugService().logError(
        method: 'GET',
        url: '${ApiConfig.baseUrl}${ApiConfig.coursesFilterEndpoint}',
        error: e.toString(),
      );
      return null;
    }
  }

  /// Get course tree (curriculum) with units and lessons
  /// Includes retry logic for intermittent failures
  static Future<CourseTreeResponse?> getCourseTree({
    required String courseId,
    String? token,
    AuthService? authService,
  }) async {
    const maxAttempts = 3;
    const delays = [Duration.zero, Duration(milliseconds: 500), Duration(milliseconds: 1200)];

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        if (attempt > 0) await Future.delayed(delays[attempt]);

        final uri = Uri.parse('${ApiConfig.baseUrl}/api/Course/tree?courseid=$courseId');

        ApiDebugService().logRequest(method: 'GET', url: uri.toString());

        http.Response response;
        if (authService != null) {
          final client = AuthenticatedApiClient(authService);
          response = await client.get(uri);
        } else if (token != null && token.isNotEmpty) {
          response = await HttpClientHelper.get(
            uri,
            headers: {'Authorization': 'Bearer $token'},
          );
        } else {
          response = await HttpClientHelper.get(uri);
        }

        ApiDebugService().logResponse(
          method: 'GET',
          url: uri.toString(),
          statusCode: response.statusCode,
          responseBody: response.body,
        );

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body) as Map<String, dynamic>?;
          if (responseData != null) {
            return CourseTreeResponse.fromJson(responseData);
          }
        }
        if (response.statusCode >= 500 && attempt < maxAttempts - 1) continue;
        return null;
      } catch (e) {
        ApiDebugService().logError(
          method: 'GET',
          url: '${ApiConfig.baseUrl}/api/Course/tree',
          error: 'Attempt ${attempt + 1}/$maxAttempts: $e',
        );
        if (attempt == maxAttempts - 1) return null;
      }
    }
    return null;
  }

  /// Check if student is enrolled in a course
  /// Includes retry logic for intermittent failures
  static Future<bool> isEnrolled({
    required String studentId,
    required String courseId,
    required String token,
    AuthService? authService,
  }) async {
    const maxAttempts = 3;
    const delays = [Duration.zero, Duration(milliseconds: 800), Duration(milliseconds: 1500)];

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        if (attempt > 0) {
          await Future.delayed(delays[attempt]);
        }

        final url = '${ApiConfig.baseUrl}/api/AdminStudent/IsEnrolled?studentId=$studentId&courseId=$courseId';

        ApiDebugService().logRequest(method: 'GET', url: url);

        http.Response response;
        if (authService != null) {
          final apiClient = AuthenticatedApiClient(authService);
          response = await apiClient.get(Uri.parse(url));
        } else {
          response = await HttpClientHelper.get(
            Uri.parse(url),
            headers: {'Authorization': 'Bearer $token'},
          );
        }

        ApiDebugService().logResponse(
          method: 'GET',
          url: url,
          statusCode: response.statusCode,
          responseBody: response.body,
        );

        if (response.statusCode == 200) {
          return response.body.toLowerCase().trim() == 'true';
        }
        if (response.statusCode >= 500 && attempt < maxAttempts - 1) {
          continue; // Retry on server error
        }
        return false;
      } catch (e) {
        ApiDebugService().logError(
          method: 'GET',
          url: '${ApiConfig.baseUrl}/api/AdminStudent/IsEnrolled',
          error: 'Attempt ${attempt + 1}/$maxAttempts: $e',
        );
        if (attempt == maxAttempts - 1) return false;
      }
    }
    return false;
  }

  /// Enroll in a course using a code
  static Future<ApiResponse<void>> enrollInCourse({
    required String studentId,
    required String code,
    required String token,
    AuthService? authService,
  }) async {
    try {
      final url = '${ApiConfig.baseUrl}${ApiConfig.enrollEndpoint}?Code=$code&StudentId=$studentId';

      // Log request
      ApiDebugService().logRequest(
        method: 'POST',
        url: url,
      );

      // Use AuthenticatedApiClient if authService is provided for automatic token refresh
      http.Response response;
      if (authService != null) {
        final client = AuthenticatedApiClient(authService);
        response = await client.post(Uri.parse(url));
      } else {
        response = await HttpClientHelper.post(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );
      }

      // Log response
      ApiDebugService().logResponse(
        method: 'POST',
        url: url,
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      final responseData = json.decode(response.body);
      return ApiResponse<void>.fromJson(
        responseData,
        null,
      );
    } catch (e) {
      ApiDebugService().logError(
        method: 'POST',
        url: '${ApiConfig.baseUrl}${ApiConfig.enrollEndpoint}',
        error: e.toString(),
      );
      return ApiResponse<void>(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Get course tree with student progress
  static Future<CourseTreeWithProgressResponse?> getCourseTreeWithProgress({
    required String courseId,
    String? token,
    AuthService? authService,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.courseTreeProgressEndpoint}?courseid=$courseId');

      ApiDebugService().logRequest(method: 'GET', url: uri.toString());

      http.Response response;
      if (authService != null) {
        final client = AuthenticatedApiClient(authService);
        response = await client.get(uri);
      } else if (token != null && token.isNotEmpty) {
        response = await HttpClientHelper.get(
          uri,
          headers: {'Authorization': 'Bearer $token'},
        );
      } else {
        response = await HttpClientHelper.get(uri);
      }

      // Log response
      ApiDebugService().logResponse(
        method: 'GET',
        url: uri.toString(),
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return CourseTreeWithProgressResponse.fromJson(responseData);
      }
      return null;
    } catch (e) {
      ApiDebugService().logError(
        method: 'GET',
        url: '${ApiConfig.baseUrl}${ApiConfig.courseTreeProgressEndpoint}',
        error: e.toString(),
      );
      return null;
    }
  }

  /// Get lesson content (Video or Quiz)
  static Future<dynamic> getLessonContent({
    required int lessonId,
    required String token,
    AuthService? authService,
  }) async {
    try {
      final url = '${ApiConfig.baseUrl}${ApiConfig.lessonContentEndpoint}/$lessonId';

      // Log request
      ApiDebugService().logRequest(
        method: 'GET',
        url: url,
        headers: {'Authorization': 'Bearer $token'},
      );

      // Use AuthenticatedApiClient if authService is provided for automatic token refresh
      http.Response response;
      if (authService != null) {
        final client = AuthenticatedApiClient(authService);
        response = await client.get(Uri.parse(url));
      } else {
        response = await HttpClientHelper.get(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );
      }

      // Log response
      ApiDebugService().logResponse(
        method: 'GET',
        url: url,
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Quiz: legacy `data` as list of questions, or `data: { questions, passDegree, ... }`
        final data = responseData['data'];
        if (data is List) {
          return QuizLessonResponse.fromJson(responseData);
        }
        if (data is Map) {
          final m = data as Map<String, dynamic>;
          if (m['questions'] != null || m['Questions'] != null) {
            return QuizLessonResponse.fromJson(responseData);
          }
          if (m['filePath1'] != null) {
            return FileLessonResponse.fromJson(responseData);
          }
          return VideoLessonResponse.fromJson(responseData);
        }
      } else {
        return null;
      }
    } catch (e) {
      ApiDebugService().logError(
        method: 'GET',
        url: '${ApiConfig.baseUrl}${ApiConfig.lessonContentEndpoint}/$lessonId',
        error: e.toString(),
      );
      return null;
    }
  }

  /// Get courses by gradeId using /api/Course/filter endpoint
  static Future<EnrolledCoursesResponse?> getCoursesByGradeId({
    required String gradeId,
    required String token,
    AuthService? authService,
    bool? isSuggested,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/AdminStudent/CourseActive?grade=$gradeId&pagenumber=$pageNumber&pagesize=$pageSize',
      );

      // Log request
      ApiDebugService().logRequest(
        method: 'GET',
        url: uri.toString(),
        headers: {'Authorization': 'Bearer $token'},
      );

      // Use AuthenticatedApiClient if authService is provided for automatic token refresh
      http.Response response;
      if (authService != null) {
        final client = AuthenticatedApiClient(authService);
        response = await client.get(uri);
      } else {
        response = await HttpClientHelper.get(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
          },
        );
      }

      // Log response
      ApiDebugService().logResponse(
        method: 'GET',
        url: uri.toString(),
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        // Backend expected to wrap in ApiResponse with data field
        if (jsonData is Map && jsonData.containsKey('success') && jsonData.containsKey('data')) {
          final apiResponse = jsonData as Map<String, dynamic>;
          if (apiResponse['success'] == true && apiResponse['data'] != null) {
            final dataMap = apiResponse['data'] as Map<String, dynamic>;
            return EnrolledCoursesResponse.fromJson(dataMap);
          }
        } else if (jsonData is Map<String, dynamic>) {
          // Fallback to direct response format
          return EnrolledCoursesResponse.fromJson(jsonData);
        }
      }
      return null;
    } catch (e) {
      ApiDebugService().logError(
        method: 'GET',
        url: '${ApiConfig.baseUrl}${ApiConfig.coursesByGradeFilterEndpoint}',
        error: e.toString(),
      );
      return null;
    }
  }

  /// Submit quiz result
  static Future<ApiResponse<String>> submitQuiz({
    required int lessonId,
    required double score,
    String? notes,
    required String token,
    AuthService? authService,
  }) async {
    try {
      final url = '${ApiConfig.baseUrl}/api/QuizResult/submit';
      
      final requestBody = {
        'lessonId': lessonId,
        'score': score,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      // Log request
      ApiDebugService().logRequest(
        method: 'POST',
        url: url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      // Use AuthenticatedApiClient if authService is provided for automatic token refresh
      http.Response response;
      if (authService != null) {
        final client = AuthenticatedApiClient(authService);
        response = await client.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode(requestBody),
        );
      } else {
        response = await HttpClientHelper.post(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode(requestBody),
        );
      }

      // Log response
      ApiDebugService().logResponse(
        method: 'POST',
        url: url,
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      final responseData = json.decode(response.body);
      
      return ApiResponse<String>(
        success: responseData['success'] ?? false,
        message: responseData['message'],
        data: responseData['data'],
      );
    } catch (e) {
      ApiDebugService().logError(
        method: 'POST',
        url: '${ApiConfig.baseUrl}/api/QuizResult/submit',
        error: e.toString(),
      );
      return ApiResponse<String>(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: null,
      );
    }
  }
}
