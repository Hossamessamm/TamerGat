import 'user_info_dto.dart';

/// Login response DTO matching backend LoginResponseDto
class LoginResponseDto {
  final String token;
  final UserInfoDto user;

  LoginResponseDto({
    required this.token,
    required this.user,
  });

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
    return LoginResponseDto(
      token: json['token'] as String? ?? json['Token'] as String? ?? '',
      user: UserInfoDto.fromJson(
        json['user'] as Map<String, dynamic>? ??
            json['User'] as Map<String, dynamic>? ??
            {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user': user.toJson(),
    };
  }

  @override
  String toString() {
    return 'LoginResponseDto(token: ${token.substring(0, 20)}..., user: $user)';
  }
}
