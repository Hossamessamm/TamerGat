import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/contact_model.dart';
import '../utils/http_client_helper.dart';
import 'api_debug_service.dart';

class ContactService {
  static const String _getAllContactsUrl = '${ApiConfig.baseUrl}/api/Contact/getAll';

  /// Get all contacts (including WhatsApp number)
  static Future<ContactResponse?> getAllContacts({
    String? token,
  }) async {
    try {
      ApiDebugService().logRequest(
        method: 'GET',
        url: _getAllContactsUrl,
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      );

      final response = await HttpClientHelper.get(
        Uri.parse(_getAllContactsUrl),
        headers: token != null
            ? {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              }
            : {
                'Content-Type': 'application/json',
              },
      );

      ApiDebugService().logResponse(
        method: 'GET',
        url: _getAllContactsUrl,
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return ContactResponse.fromJson(responseData);
      } else {
        return null;
      }
    } catch (e) {
      ApiDebugService().logError(
        method: 'GET',
        url: _getAllContactsUrl,
        error: e.toString(),
      );
      return null;
    }
  }
}


