import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/order_model.dart';
import '../services/api_debug_service.dart';
import '../services/auth_service.dart';
import '../utils/authenticated_api_client.dart';

class OrderService {
  /// Create an order for a single course (optionally with a promocode).
  ///
  /// Backend: `POST /api/Order/create`
  /// Request: `{ courseId, promoCode?, paymentReference? }`
  static Future<ApiResponse<OrderDto?>> createOrder({
    required AuthService authService,
    required String courseId,
    String? promoCode,
    String? paymentReference,
  }) async {
    final requestBody = <String, dynamic>{
      'courseId': courseId,
      if (promoCode != null && promoCode.trim().isNotEmpty) 'promoCode': promoCode.trim(),
      if (paymentReference != null && paymentReference.trim().isNotEmpty)
        'paymentReference': paymentReference.trim(),
    };

    final url = ApiConfig.createOrderUrl;
    ApiDebugService().logRequest(
      method: 'POST',
      url: url,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    try {
      final client = AuthenticatedApiClient(authService);
      http.Response response = await client.post(
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
          return ApiResponse<OrderDto?>.fromJson(
            jsonData,
            (data) => OrderDto.fromJson(data as Map<String, dynamic>),
          );
        }
      }

      // Non-200: return failure wrapper
      final message = _extractMessage(response);
      return ApiResponse<OrderDto?>(
        success: false,
        message: message,
        data: null,
      );
    } catch (e) {
      ApiDebugService().logError(method: 'POST', url: url, error: e.toString());
      return ApiResponse<OrderDto?>(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Fetch the current user's orders (paginated).
  ///
  /// Backend: `GET /api/Order/my-orders?pageNumber=1&pageSize=10`
  static Future<ApiResponse<MyOrdersResponse?>> getMyOrders({
    required AuthService authService,
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    final url = '${ApiConfig.myOrdersUrl}?pageNumber=$pageNumber&pageSize=$pageSize';
    ApiDebugService().logRequest(method: 'GET', url: url);

    try {
      final client = AuthenticatedApiClient(authService);
      final response = await client.get(Uri.parse(url));

      ApiDebugService().logResponse(
        method: 'GET',
        url: url,
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData is Map<String, dynamic>) {
          return ApiResponse<MyOrdersResponse?>.fromJson(
            jsonData,
            (data) => MyOrdersResponse.fromJson(data as Map<String, dynamic>),
          );
        }
      }

      return ApiResponse<MyOrdersResponse?>(
        success: false,
        message: _extractMessage(response),
        data: null,
      );
    } catch (e) {
      ApiDebugService().logError(method: 'GET', url: url, error: e.toString());
      return ApiResponse<MyOrdersResponse?>(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: null,
      );
    }
  }

  /// Fetch an order by id (for polling after hosted payment).
  ///
  /// Backend: `GET /api/Order/{id}`
  static Future<ApiResponse<OrderDto?>> getOrderById({
    required AuthService authService,
    required String orderId,
  }) async {
    final url = ApiConfig.orderByIdUrl(orderId);
    ApiDebugService().logRequest(method: 'GET', url: url);

    try {
      final client = AuthenticatedApiClient(authService);
      final response = await client.get(Uri.parse(url));

      ApiDebugService().logResponse(
        method: 'GET',
        url: url,
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData is Map<String, dynamic>) {
          return ApiResponse<OrderDto?>.fromJson(
            jsonData,
            (data) => OrderDto.fromJson(data as Map<String, dynamic>),
          );
        }
      }

      return ApiResponse<OrderDto?>(
        success: false,
        message: _extractMessage(response),
        data: null,
      );
    } catch (e) {
      ApiDebugService().logError(method: 'GET', url: url, error: e.toString());
      return ApiResponse<OrderDto?>(
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
    } catch (_) {
      // ignore
    }
    return 'Request failed with status: ${response.statusCode}';
  }
}

