import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/teacher_link_model.dart';
import '../models/api_response.dart';
import '../models/subject_model.dart';
import 'api_debug_service.dart';
import '../utils/http_client_helper.dart';
import '../utils/authenticated_api_client.dart';
import 'auth_service.dart';

class TeacherService {
  /// Enter teacher code to link with a teacher
  static Future<String?> enterTeacherCode({
    required int teacherCode,
    required String token,
    AuthService? authService,
  }) async {
    try {
      final requestBody = json.encode({
        'TeacherCode': teacherCode,
      });

      // Log request
      ApiDebugService().logRequest(
        method: 'POST',
        url: ApiConfig.enterTeacherCodeUrl,
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: requestBody,
      );

      http.Response response;
      if (authService != null) {
        // Use authenticated client for automatic token refresh on 401
        final apiClient = AuthenticatedApiClient(authService);
        response = await apiClient.post(
          Uri.parse(ApiConfig.enterTeacherCodeUrl),
          headers: {
            'Content-Type': 'application/json',
          },
          body: requestBody,
        );
      } else {
        // Fallback to manual token handling
        response = await HttpClientHelper.post(
          Uri.parse(ApiConfig.enterTeacherCodeUrl),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: requestBody,
        );
      }

      // Log response
      ApiDebugService().logResponse(
        method: 'POST',
        url: ApiConfig.enterTeacherCodeUrl,
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
          json.decode(response.body),
          (data) => data as Map<String, dynamic>,
        );

        if (apiResponse.success) {
          return null; // Success
        } else {
          return apiResponse.message;
        }
      } else {
        try {
          final errorData = json.decode(response.body);
          return errorData['message'] ?? 'Failed to connect with teacher';
        } catch (e) {
          return 'Failed to connect with teacher';
        }
      }
    } catch (e) {
      ApiDebugService().logError(
        method: 'POST',
        url: ApiConfig.enterTeacherCodeUrl,
        error: e.toString(),
      );
      return 'Network error: ${e.toString()}';
    }
  }

  /// Get all teachers connected to the student
  static Future<StudentTeachersResponse?> getStudentTeachers({
    required String token,
    AuthService? authService,
  }) async {
    try {
      // Log request
      ApiDebugService().logRequest(
        method: 'GET',
        url: ApiConfig.studentTeachersUrl,
        headers: {'Authorization': 'Bearer $token'},
      );

      http.Response response;
      if (authService != null) {
        // Use authenticated client for automatic token refresh on 401
        final apiClient = AuthenticatedApiClient(authService);
        response = await apiClient.get(
          Uri.parse(ApiConfig.studentTeachersUrl),
        );
      } else {
        // Fallback to manual token handling
        response = await HttpClientHelper.get(
          Uri.parse(ApiConfig.studentTeachersUrl),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );
      }

      // Log response
      ApiDebugService().logResponse(
        method: 'GET',
        url: ApiConfig.studentTeachersUrl,
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return StudentTeachersResponse.fromJson(responseData);
      } else {
        return null;
      }
    } catch (e) {
      ApiDebugService().logError(
        method: 'GET',
        url: ApiConfig.studentTeachersUrl,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Get subjects for a specific teacher
  static Future<TeacherSubjectsResponse?> getSubjectsForTeacher({
    required String teacherId,
    required String token,
    AuthService? authService,
  }) async {
    try {
      final url = ApiConfig.getSubjectsForTeacherUrl(teacherId);
      
      // Log request
      ApiDebugService().logRequest(
        method: 'GET',
        url: url,
        headers: {'Authorization': 'Bearer $token'},
      );

      http.Response response;
      if (authService != null) {
        // Use authenticated client for automatic token refresh on 401
        final apiClient = AuthenticatedApiClient(authService);
        response = await apiClient.get(
          Uri.parse(url),
        );
      } else {
        // Fallback to manual token handling
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
        return TeacherSubjectsResponse.fromJson(responseData);
      } else {
        return null;
      }
    } catch (e) {
      ApiDebugService().logError(
        method: 'GET',
        url: ApiConfig.getSubjectsForTeacherUrl(teacherId),
        error: e.toString(),
      );
      return null;
    }
  }
}
