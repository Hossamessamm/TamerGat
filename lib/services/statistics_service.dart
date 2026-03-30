import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/student_progress_stats.dart';
import '../models/api_response.dart';
import 'api_debug_service.dart';
import '../utils/http_client_helper.dart';
import '../utils/authenticated_api_client.dart';
import 'auth_service.dart';
import 'course_service.dart';

class StatisticsService {
  /// Compute average score from quizzes progress API results array.
  /// Each item: { lessonId, lessonName, score, submittedAt }.
  static double _computeAverageFromResults(dynamic results) {
    if (results == null || results is! List || results.isEmpty) return 0;
    double sum = 0;
    int count = 0;
    for (final e in results) {
      if (e is! Map) continue;
      final score = e['score'];
      if (score != null) {
        sum += (score is num ? score : double.tryParse(score.toString()) ?? 0).toDouble();
        count++;
      }
    }
    return count > 0 ? sum / count : 0;
  }

  /// Get student progress statistics for home screen.
  ///
  /// Uses the dedicated student progress endpoints:
  /// - GET /api/Student/GetStudentLessonsProgress/{studentId}
  /// - GET /api/Student/GetStudentQuizzesProgress/{studentId}
  static Future<StudentProgressStats?> getStudentProgress({
    required String userId,
    required String token,
    AuthService? authService,
  }) async {
    try {
      // --- Lessons progress ---
      final lessonsUrl =
          '${ApiConfig.baseUrl}${ApiConfig.studentLessonsProgressEndpoint}/$userId';
      ApiDebugService().logRequest(
        method: 'GET',
        url: lessonsUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      http.Response lessonsResponse;
      if (authService != null) {
        final apiClient = AuthenticatedApiClient(authService);
        lessonsResponse = await apiClient.get(
          Uri.parse(lessonsUrl),
          headers: {
            'Content-Type': 'application/json',
          },
        );
      } else {
        lessonsResponse = await HttpClientHelper.get(
          Uri.parse(lessonsUrl),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
      }

      ApiDebugService().logResponse(
        method: 'GET',
        url: lessonsUrl,
        statusCode: lessonsResponse.statusCode,
        responseBody: lessonsResponse.body,
      );

      if (lessonsResponse.statusCode != 200) {
        print(
            'Failed to load lessons progress. Status: ${lessonsResponse.statusCode}');
        return null;
      }

      final lessonsJson = json.decode(lessonsResponse.body);
      final lessonsApi =
          ApiResponse<Map<String, dynamic>>.fromJson(lessonsJson, (data) {
        return data as Map<String, dynamic>;
      });

      if (!lessonsApi.success || lessonsApi.data == null) {
        print('Lessons progress API error: ${lessonsApi.message}');
        return null;
      }

      final lessonsData = lessonsApi.data!;

      // API returns: totalVideos, watchedVideos, progress (0-100)
      final completedLessons = (lessonsData['completedLessons'] ??
              lessonsData['completedCount'] ??
              lessonsData['watchedVideos'] ??
              0) as int;
      final totalLessons =
          (lessonsData['totalLessons'] ?? lessonsData['totalCount'] ?? lessonsData['totalVideos'] ?? 0) as int;
      final completionPercentage = (lessonsData['completionPercentage'] ??
              lessonsData['percentage'] ??
              lessonsData['progress'] ??
              0)
          .toDouble();

      // --- Quizzes progress ---
      final quizzesUrl =
          '${ApiConfig.baseUrl}${ApiConfig.studentQuizzesProgressEndpoint}/$userId';
      ApiDebugService().logRequest(
        method: 'GET',
        url: quizzesUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      http.Response quizzesResponse;
      if (authService != null) {
        final apiClient = AuthenticatedApiClient(authService);
        quizzesResponse = await apiClient.get(
          Uri.parse(quizzesUrl),
          headers: {
            'Content-Type': 'application/json',
          },
        );
      } else {
        quizzesResponse = await HttpClientHelper.get(
          Uri.parse(quizzesUrl),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
      }

      ApiDebugService().logResponse(
        method: 'GET',
        url: quizzesUrl,
        statusCode: quizzesResponse.statusCode,
        responseBody: quizzesResponse.body,
      );

      if (quizzesResponse.statusCode != 200) {
        print(
            'Failed to load quizzes progress. Status: ${quizzesResponse.statusCode}');
        // We can still return lessons progress if available
      }

      double averageQuizScore = 0;
      if (quizzesResponse.statusCode == 200 &&
          quizzesResponse.body.trim().isNotEmpty) {
        final quizzesJson = json.decode(quizzesResponse.body);
        final quizzesApi =
            ApiResponse<Map<String, dynamic>>.fromJson(quizzesJson, (data) {
          return data as Map<String, dynamic>;
        });

        if (quizzesApi.success && quizzesApi.data != null) {
          final quizzesData = quizzesApi.data!;
          // API may return averageScore/averageQuizScore/percentage, or a results array
          averageQuizScore = (quizzesData['averageScore'] ??
                  quizzesData['averageQuizScore'] ??
                  quizzesData['percentage']) != null
              ? ((quizzesData['averageScore'] ??
                      quizzesData['averageQuizScore'] ??
                      quizzesData['percentage'])
                  as num)
                  .toDouble()
              : _computeAverageFromResults(quizzesData['results']);
        }
      }

      // Fetch enrolled courses count for "Courses Enrolled" card
      int totalCoursesEnrolled = 0;
      try {
        final enrolledResponse = await CourseService.getEnrolledCourses(
          studentId: userId,
          token: token,
          authService: authService,
          pageNumber: 1,
          pageSize: 1,
        );
        if (enrolledResponse != null) {
          totalCoursesEnrolled = enrolledResponse.totalCount;
        }
      } catch (_) {
        // Keep 0 if enrolled courses API fails
      }

      // Build a combined stats object for the home UI.
      return StudentProgressStats(
        userId: userId,
        userName: '',
        totalCoursesEnrolled: totalCoursesEnrolled,
        completedLessons: completedLessons,
        totalLessons: totalLessons,
        completionPercentage: completionPercentage,
        averageQuizScore: averageQuizScore,
        lastActivity: DateTime.now(),
      );
    } catch (e) {
      ApiDebugService().logError(
        method: 'GET',
        url:
            '${ApiConfig.baseUrl}${ApiConfig.studentLessonsProgressEndpoint}/$userId',
        error: e.toString(),
      );
      print('Error fetching student progress: $e');
      return null;
    }
  }
}
