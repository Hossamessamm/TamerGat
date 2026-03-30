import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/unit_model.dart';
import '../config/api_config.dart';
import '../utils/http_client_helper.dart';

class UnitService {
  /// Enter a unit code to enroll in a unit
  static Future<EnterCodeResponse?> enterUnitCode({
    required String code,
    required String token,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/UnitCode/EnterCode?code=$code');
      
      final response = await HttpClientHelper.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return EnterCodeResponse.fromJson(data);
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        return EnterCodeResponse.fromJson(data);
      } else {
        return EnterCodeResponse(
          success: false,
          message: 'Failed to enter unit code. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      return EnterCodeResponse(
        success: false,
        message: 'Error: $e',
      );
    }
  }

  /// Get student's enrolled units with pagination
  static Future<UnitsResponse?> getMyUnits({
    required String token,
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/api/UnitCode/GetMyUnitCodes?pageNumber=$pageNumber&pageSize=$pageSize',
      );
      
      final response = await HttpClientHelper.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UnitsResponse.fromJson(data);
      } else if (response.statusCode == 400) {
        // No enrolled units found
        return UnitsResponse(
          totalCount: 0,
          totalPages: 1,
          currentPage: 1,
          pageSize: pageSize,
          units: [],
        );
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching units: $e');
      return null;
    }
  }

  /// Get unit lessons with progress
  static Future<Map<String, dynamic>?> getUnitTreeWithProgress({
    required int unitId,
    required String token,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/api/Course/tree-unit-with-progress?unitId=$unitId',
      );
      
      final response = await HttpClientHelper.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else if (response.statusCode == 404) {
        print('Unit not found');
        return null;
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching unit tree: $e');
      return null;
    }
  }
}
