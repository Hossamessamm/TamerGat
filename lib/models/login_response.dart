import 'user_model.dart';

class LoginResponse {
  final String token;
  final User user;

  LoginResponse({
    required this.token,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] ?? '',  // Changed from 'Token' to 'token'
      user: User.fromJson(json['user']),  // Changed from 'User' to 'user'
    );
  }
}
