import 'dart:convert';

/// Login request DTO matching backend LoginDto
class LoginRequestDto {
  final String? emailOrMobile;  // For student login
  final String? email;           // For moderator login
  final String password;

  LoginRequestDto({
    this.emailOrMobile,
    this.email,
    required this.password,
  }) : assert(
          emailOrMobile != null || email != null,
          'Either emailOrMobile or email must be provided',
        );

  /// Factory for student login
  factory LoginRequestDto.student({
    required String emailOrMobile,
    required String password,
  }) {
    return LoginRequestDto(
      emailOrMobile: emailOrMobile,
      password: password,
    );
  }

  /// Factory for moderator login
  factory LoginRequestDto.moderator({
    required String email,
    required String password,
  }) {
    return LoginRequestDto(
      email: email,
      password: password,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (emailOrMobile != null) 'EmailOrMobile': emailOrMobile,
      if (email != null) 'Email': email,
      'Password': password,
    };
  }

  String toJsonString() => json.encode(toJson());
}
