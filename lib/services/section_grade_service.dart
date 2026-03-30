import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/section_model.dart';
import '../models/grade_model.dart';
import '../models/dtos/api_response.dart';
import '../utils/http_client_helper.dart';
import 'api_debug_service.dart';

class SectionGradeService {
  /// Get all sections (departments) with retry logic for transient failures
  Future<List<Section>> getSections({int maxRetries = 3}) async {
    int attempt = 0;
    
    while (attempt < maxRetries) {
      try {
        attempt++;
        print('🔍 Fetching sections from: ${ApiConfig.sectionsUrl} (attempt $attempt/$maxRetries)');
        final response = await HttpClientHelper.get(Uri.parse(ApiConfig.sectionsUrl));
        
        print('📡 Response status: ${response.statusCode}');

        if (response.statusCode == 200) {
          final jsonData = json.decode(response.body);
          print('📦 Parsed JSON: $jsonData');
          
          final apiResponse = ApiResponse.fromJson(jsonData, null);
          print('✅ API Response success: ${apiResponse.success}');
          print('📝 API Response message: ${apiResponse.message}');

          if (apiResponse.success && apiResponse.data != null) {
            final List<dynamic> sectionsJson = apiResponse.data as List<dynamic>;
            print('📋 Found ${sectionsJson.length} sections in response');
            
            final sections = sectionsJson
                .map((json) {
                  try {
                    return Section.fromJson(json as Map<String, dynamic>);
                  } catch (e) {
                    print('❌ Error parsing section: $e');
                    print('   JSON: $json');
                    rethrow;
                  }
                })
                .toList();
            
            // Filter active sections, but log if we're filtering any out
            final activeSections = sections.where((section) => section.active).toList();
            if (activeSections.length < sections.length) {
              print('⚠️ Filtered out ${sections.length - activeSections.length} inactive sections');
            }
            
            print('✅ Returning ${activeSections.length} active sections');
            return activeSections;
          } else {
            final errorMsg = apiResponse.message ?? 'Failed to fetch sections';
            print('❌ API returned error: $errorMsg');
            
            // Check if it's a transient error that we should retry
            if (_isTransientError(errorMsg) && attempt < maxRetries) {
              print('🔄 Transient error detected, retrying in ${attempt * 2} seconds...');
              await Future.delayed(Duration(seconds: attempt * 2));
              continue;
            }
            
            throw Exception(errorMsg);
          }
        } else if (response.statusCode >= 500 && attempt < maxRetries) {
          // Server error - retry
          final errorMsg = 'Server error (${response.statusCode})';
          print('❌ HTTP error: $errorMsg - Retrying in ${attempt * 2} seconds...');
          await Future.delayed(Duration(seconds: attempt * 2));
          continue;
        } else {
          final errorMsg = 'Failed to load sections: ${response.statusCode}';
          print('❌ HTTP error: $errorMsg');
          throw Exception(errorMsg);
        }
      } catch (e, stackTrace) {
        print('❌ Exception in getSections (attempt $attempt): $e');
        
        // If it's the last attempt or not a transient error, throw
        if (attempt >= maxRetries || !_isTransientError(e.toString())) {
          print('📚 Stack trace: $stackTrace');
          throw Exception('Error fetching sections: ${e.toString()}');
        }
        
        // Wait before retrying
        print('🔄 Retrying in ${attempt * 2} seconds...');
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
    
    throw Exception('Failed to fetch sections after $maxRetries attempts');
  }
  
  /// Check if an error is transient and worth retrying
  bool _isTransientError(String error) {
    final transientKeywords = [
      'transient',
      'timeout',
      'connection',
      'network',
      'temporarily',
      'retry',
      'EnableRetryOnFailure',
    ];
    
    final lowerError = error.toLowerCase();
    return transientKeywords.any((keyword) => lowerError.contains(keyword));
  }

  /// Get grades for a specific section
  Future<List<Grade>> getGradesBySection(int sectionId) async {
    try {
      final url = ApiConfig.getSectionGradesUrl(sectionId);
      final response = await HttpClientHelper.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final apiResponse = ApiResponse.fromJson(jsonData, null);

        if (apiResponse.success && apiResponse.data != null) {
          final List<dynamic> gradesJson = apiResponse.data as List<dynamic>;
          return gradesJson
              .map((json) => Grade.fromJson(json as Map<String, dynamic>))
              .where((grade) => grade.active) // Only return active grades
              .toList();
        } else {
          throw Exception(apiResponse.message ?? 'Failed to fetch grades');
        }
      } else {
        throw Exception('Failed to load grades: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching grades: ${e.toString()}');
    }
  }

  /// Get all grades (optionally filtered by section)
  Future<List<Grade>> getAllGrades({int? sectionId}) async {
    try {
      final url = ApiConfig.getGradesBySectionUrl(sectionId);
      final response = await HttpClientHelper.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final apiResponse = ApiResponse.fromJson(jsonData, null);

        if (apiResponse.success && apiResponse.data != null) {
          final List<dynamic> gradesJson = apiResponse.data as List<dynamic>;
          return gradesJson
              .map((json) => Grade.fromJson(json as Map<String, dynamic>))
              .where((grade) => grade.active) // Only return active grades
              .toList();
        } else {
          throw Exception(apiResponse.message ?? 'Failed to fetch grades');
        }
      } else {
        throw Exception('Failed to load grades: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching grades: ${e.toString()}');
    }
  }

  /// Get all grades that have at least one course. API returns [{"id": 11, "name": "Secondary3"}, ...].
  Future<List<GradeWithCourses>> getGradesWithCourses() async {
    try {
      final url = ApiConfig.gradesWithCoursesUrl;
      ApiDebugService().logRequest(
        method: 'GET',
        url: url,
      );

      final response = await HttpClientHelper.get(Uri.parse(url));

      ApiDebugService().logResponse(
        method: 'GET',
        url: url,
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        final success = jsonData['success'] == true;
        final message = jsonData['message']?.toString() ?? 'Failed to fetch grades with courses';
        final data = jsonData['data'];

        if (success && data is List) {
          final gradesJson = data as List<dynamic>;
          final result = <GradeWithCourses>[];
          for (final e in gradesJson) {
            if (e is! Map) continue;
            try {
              result.add(GradeWithCourses.fromJson(Map<String, dynamic>.from(e)));
            } catch (_) {
              // skip malformed item, keep the rest
            }
          }
          return result;
        } else {
          throw Exception(message);
        }
      } else {
        throw Exception('Failed to load grades with courses: ${response.statusCode}');
      }
    } catch (e) {
      ApiDebugService().logError(
        method: 'GET',
        url: ApiConfig.gradesWithCoursesUrl,
        error: e.toString(),
      );
      throw Exception('Error fetching grades with courses: ${e.toString()}');
    }
  }
}
