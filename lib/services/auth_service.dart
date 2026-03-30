import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/dtos/login_request_dto.dart';
import '../models/dtos/register_request_dto.dart';
import '../models/dtos/login_response_dto.dart';
import '../models/dtos/api_response.dart';
import '../models/dtos/user_info_dto.dart';
import '../models/grade_enum.dart';
import 'device_service.dart';
import 'api_debug_service.dart';
import '../utils/http_client_helper.dart';
import '../utils/json_helper.dart';
import '../utils/quiz_pass_config.dart';

class AuthService extends ChangeNotifier {
  UserInfoDto? _currentUser;
  String? _token;
  bool _isLoading = false;

  UserInfoDto? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated {
    final hasUser = _currentUser != null;
    final hasToken = _token != null && _token!.isNotEmpty;
    final hasValidUserId = hasUser && _currentUser!.id.isNotEmpty;
    final authenticated = hasUser && hasToken && hasValidUserId;
    
    if (!authenticated) {
      print('🔍 Auth check: hasUser=$hasUser, hasToken=$hasToken, hasValidUserId=$hasValidUserId');
    }
    
    return authenticated;
  }

  /// Initialize and check if user is already logged in
  Future<void> init() async {
    print('🔄 AuthService.init() - Starting initialization...');
    _isLoading = true;
    // Don't notify listeners yet - we're still in initialization

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Don't reload - it's slow and not necessary on first load
      // await prefs.reload();
      
      // Load token
      _token = prefs.getString(ApiConfig.tokenKey);
      
      // Load user data
      final userJson = prefs.getString(ApiConfig.userKey);
      
      if (userJson != null && userJson.isNotEmpty) {
        try {
          final userData = json.decode(userJson);
          _currentUser = UserInfoDto.fromJson(userData);
          
          // Verify we have both token and user
          if (_token == null || _token!.isEmpty) {
            print('⚠️ Token is missing, clearing user data');
            _currentUser = null;
            _token = null;
            await prefs.remove(ApiConfig.tokenKey);
            await prefs.remove(ApiConfig.userKey);
          } else {
            print('✅ Session restored successfully for: ${_currentUser!.name}');
          }
        } catch (e) {
          print('❌ Error parsing user data: $e');
          _currentUser = null;
          _token = null;
          await prefs.remove(ApiConfig.tokenKey);
          await prefs.remove(ApiConfig.userKey);
        }
      } else {
        print('ℹ️ No saved session found');
      }
    } catch (e) {
      print('❌ Error initializing auth: $e');
      _currentUser = null;
      _token = null;
    }

    _isLoading = false;
    // Don't notify listeners during init - the UI will pick up the state after build
  }

  /// Register a new user
  Future<String?> register(RegisterRequestDto requestDto) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Log request
      ApiDebugService().logRequest(
        method: 'POST',
        url: ApiConfig.registerUrl,
        body: requestDto.toString(),
      );

      // Create multipart request using the DTO helper
      final request = await requestDto.toMultipartRequest(ApiConfig.registerUrl);

      // Send request using custom client
      final streamedResponse = await HttpClientHelper.send(request);
      final response = await http.Response.fromStream(streamedResponse);
    
      // Log response
      ApiDebugService().logResponse(
        method: 'POST',
        url: ApiConfig.registerUrl,
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      // Parse response
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final apiResponse = ApiResponse<void>.fromJson(jsonData, null);

        _isLoading = false;
        notifyListeners();
        
        if (apiResponse.success) {
          return null; // Success
        } else {
          return apiResponse.message;
        }
      } else {
        _isLoading = false;
        notifyListeners();
        
        try {
          final errorResponse = json.decode(response.body);
          if (errorResponse is Map && errorResponse.containsKey('message')) {
            return errorResponse['message'] as String;
          }
        } catch (_) {}
        
        return 'Registration failed. Please try again.';
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Network error: ${e.toString()}';
    }
  }

  /// Login user
  Future<String?> login(LoginRequestDto loginDto) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Get device ID
      final deviceId = await DeviceService.getDeviceId();
      final requestBody = loginDto.toJsonString();

      // Log request
      ApiDebugService().logRequest(
        method: 'POST',
        url: ApiConfig.loginUrl,
        headers: {'Content-Type': 'application/json', 'DeviceId': deviceId},
        body: requestBody,
      );

      // Send request
      final response = await HttpClientHelper.post(
        Uri.parse(ApiConfig.loginUrl),
        headers: {
          'Content-Type': 'application/json',
          'DeviceId': deviceId,
        },
        body: requestBody,
      );
      
      // Log response
      ApiDebugService().logResponse(
        method: 'POST',
        url: ApiConfig.loginUrl,
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      if (response.statusCode == 200) {
        try {
          // Check if response is directly the LoginResponseDto or wrapped in ApiResponse
          final jsonData = json.decode(response.body);
          
          LoginResponseDto loginResponse;
          
          // Case 1: Direct LoginResponseDto (common in this backend based on analysis)
          if (jsonData.containsKey('token') || jsonData.containsKey('Token')) {
            loginResponse = LoginResponseDto.fromJson(jsonData);
          } 
          // Case 2: Wrapped in ApiResponse
          else if (jsonData.containsKey('data') || jsonData.containsKey('Data')) {
            final apiResponse = ApiResponse<LoginResponseDto>.fromJson(
              jsonData, 
              (data) => LoginResponseDto.fromJson(data as Map<String, dynamic>)
            );
            
            if (!apiResponse.success || apiResponse.data == null) {
              _isLoading = false;
              notifyListeners();
              return apiResponse.message;
            }
            loginResponse = apiResponse.data!;
          }
          // Case 3: Unknown format
          else {
             throw FormatException('Unknown response format');
          }

          // Save to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(ApiConfig.tokenKey, loginResponse.token);
          await prefs.setString(ApiConfig.userKey, json.encode(loginResponse.user.toJson()));
          
          // Force commit
          await prefs.reload();
          
          _token = loginResponse.token;
          _currentUser = loginResponse.user;
          _isLoading = false;
          
          notifyListeners();
          return null; // Success
          
        } catch (e, stackTrace) {
          _isLoading = false;
          notifyListeners();
          print('Error parsing login response: $e');
          print('Stack trace: $stackTrace');
          return 'Error processing server response';
        }
      } else {
        _isLoading = false;
        notifyListeners();
        
        // Try to parse error message
        try {
          final errorBody = response.body;
          // Check if it's a JSON error
          if (errorBody.trim().startsWith('{')) {
             final jsonError = json.decode(errorBody);
             if (jsonError is Map && jsonError.containsKey('message')) {
               return jsonError['message'];
             }
          }
          return errorBody.isNotEmpty ? errorBody : 'Login failed';
        } catch (_) {
          return 'Login failed. Please try again.';
        }
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Network error: ${e.toString()}';
    }
  }

  /// Refresh access token
  Future<String?> refreshToken() async {
    try {
      print('🔄 Attempting to refresh access token...');
      final deviceId = await DeviceService.getDeviceId();
      
      // Log request
      ApiDebugService().logRequest(
        method: 'POST',
        url: ApiConfig.refreshTokenUrl,
        headers: {'DeviceId': deviceId, 'Content-Type': 'application/json'},
      );
      
      final response = await HttpClientHelper.post(
        Uri.parse(ApiConfig.refreshTokenUrl),
        headers: {
          'DeviceId': deviceId,
          'Content-Type': 'application/json',
        },
      );
      
      // Log response
      ApiDebugService().logResponse(
        method: 'POST',
        url: ApiConfig.refreshTokenUrl,
        statusCode: response.statusCode,
        responseBody: response.body,
      );
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('📦 Refresh token response keys: ${jsonData.keys.toList()}');
        
        // Use JsonHelper for case-insensitive parsing
        final success = JsonHelper.getBool(jsonData, 'success') ?? false;
        
        if (!success) {
          print('❌ Refresh token response indicates failure');
          return 'Token refresh failed';
        }
        
        // Try to get token from data wrapper first, then from root
        String? newToken;
        UserInfoDto? newUser;
        
        final data = JsonHelper.getMap(jsonData, 'data');
        if (data != null) {
          // Token is inside data object
          newToken = JsonHelper.getString(data, 'token');
          final userData = JsonHelper.getMap(data, 'user');
          if (userData != null) {
            newUser = UserInfoDto.fromJson(userData);
          }
        } else {
          // Token might be at root level
          newToken = JsonHelper.getString(jsonData, 'token');
          final userData = JsonHelper.getMap(jsonData, 'user');
          if (userData != null) {
            newUser = UserInfoDto.fromJson(userData);
          }
        }

        if (newToken != null && newToken.isNotEmpty) {
          print('✅ Token refreshed successfully');
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(ApiConfig.tokenKey, newToken);
          if (newUser != null) {
            await prefs.setString(ApiConfig.userKey, json.encode(newUser.toJson()));
            _currentUser = newUser;
          }
          await prefs.reload();
          
          _token = newToken;
          notifyListeners();
          return null; // Success
        } else {
          print('❌ No token found in refresh response');
          return 'No token in response';
        }
      } else {
        print('❌ Refresh token failed with status: ${response.statusCode}');
        return 'Failed to refresh token: ${response.statusCode}';
      }
    } catch (e, stackTrace) {
      print('❌ Error refreshing token: $e');
      print('Stack trace: $stackTrace');
      return 'Network error: ${e.toString()}';
    }
  }

  /// Logout user
  Future<void> logout() async {
    // Call backend to invalidate session if token exists
    if (_token != null) {
      try {
        await HttpClientHelper.post(
          Uri.parse(ApiConfig.logoutUrl),
          headers: {
            'Authorization': 'Bearer $_token',
            'Content-Type': 'application/json',
          },
        );
      } catch (e) {
        print('Warning: Backend logout failed: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConfig.tokenKey);
    await prefs.remove(ApiConfig.userKey);
    _currentUser = null;
    _token = null;
    QuizPassDegreeCache.clear();

    // Clear cookies
    try {
      final cookieJar = HttpClientHelper.cookieJar;
      await cookieJar.delete(Uri.parse(ApiConfig.baseUrl));
    } catch (_) {}
    
    notifyListeners();
  }

  /// Update student profile
  Future<ApiResponse<void>> updateProfile({
    required String studentId,
    GradeEnum? academicYear,
    String? userName,
    String? phoneNumber,
    String? parentPhone,
    String? email,
    required String token,
  }) async {
    // Implementation would go here - keeping it minimal for now as requested task was Login/Reg
    // But structure would be similar to above, using DTOs
    return ApiResponse<void>(success: false, message: "Not implemented yet");
  }
}

