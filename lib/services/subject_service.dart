import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/subject_model.dart';
import '../utils/http_client_helper.dart';
import '../utils/authenticated_api_client.dart';
import 'auth_service.dart';
import 'api_debug_service.dart';

class SubjectService {
  /// Get subjects for a grade (using gradeId from login).
  /// GET /api/Subject?gradeId={guid}
  static Future<List<Subject>> getSubjectsByGradeId({
    required String gradeId,
    required String token,
    AuthService? authService,
  }) async {
    try {
      final url = ApiConfig.subjectsByGradeUrl(gradeId);
      final uri = Uri.parse(url);

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
        response = await client.get(uri);
      } else {
        response = await HttpClientHelper.get(
          uri,
          headers: {'Authorization': 'Bearer $token'},
        );
      }

      // Log response
      ApiDebugService().logResponse(
        method: 'GET',
        url: url,
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load subjects: ${response.statusCode}');
      }

      final jsonData = json.decode(response.body);
      if (jsonData is! Map<String, dynamic>) {
        throw Exception('Invalid subjects response');
      }

      final rawData = jsonData['data'] ?? jsonData['Data'];
      if (rawData == null) return [];

      List<dynamic> list;
      if (rawData is List) {
        list = rawData;
      } else if (rawData is Map && (rawData['data'] != null || rawData['Data'] != null)) {
        list = rawData['data'] ?? rawData['Data'] ?? [];
      } else {
        return [];
      }

      return list
          .whereType<Map<String, dynamic>>()
          .map((e) => Subject.fromJson(e))
          .toList();
    } catch (e) {
      ApiDebugService().logError(
        method: 'GET',
        url: ApiConfig.subjectsByGradeUrl(gradeId),
        error: e.toString(),
      );
      rethrow;
    }
  }
}
