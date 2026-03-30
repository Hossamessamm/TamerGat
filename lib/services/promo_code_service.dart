import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/promo_validation_model.dart';
import 'api_debug_service.dart';
import 'auth_service.dart';
import '../utils/authenticated_api_client.dart';

class PromoCodeService {
  /// Validate a promo code for a specific course.
  ///
  /// Backend: `POST /api/PromoCode/validate`
  /// Request: `{ promoCode, courseId }`
  static Future<ApiResponse<PromoValidationResponse?>> validatePromoCode({
    required AuthService authService,
    required String promoCode,
    required String courseId,
  }) async {
    final url = ApiConfig.validatePromoCodeUrl;

    final requestBody = <String, dynamic>{
      'promoCode': promoCode.trim(),
      'courseId': courseId,
    };

    ApiDebugService().logRequest(
      method: 'POST',
      url: url,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    try {
      final client = AuthenticatedApiClient(authService);
      final http.Response response = await client.post(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      ApiDebugService().logResponse(
        method: 'POST',
        url: url,
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData is Map<String, dynamic>) {
          return ApiResponse<PromoValidationResponse?>.fromJson(
            jsonData,
            (data) => PromoValidationResponse.fromJson(data as Map<String, dynamic>),
          );
        }
      }

      return ApiResponse<PromoValidationResponse?>(
        success: false,
        message: _extractMessage(response),
        data: null,
      );
    } catch (e) {
      ApiDebugService().logError(method: 'POST', url: url, error: e.toString());
      return ApiResponse<PromoValidationResponse?>(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: null,
      );
    }
  }

  static String _extractMessage(http.Response response) {
    try {
      final jsonData = json.decode(response.body);
      if (jsonData is Map<String, dynamic>) {
        final msg = jsonData['message'];
        if (msg != null && msg.toString().isNotEmpty) return msg.toString();
      }
    } catch (_) {}
    return 'Request failed with status: ${response.statusCode}';
  }
}

