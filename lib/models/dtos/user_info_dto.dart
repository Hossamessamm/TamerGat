/// User information DTO matching backend UserInfoDto
class UserInfoDto {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String parentPhone;
  final String? imagePath;
  final String academicYear;
  final String? gradeId; // Grade ID from login response
  final DateTime registrationDate;

  UserInfoDto({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.parentPhone,
    this.imagePath,
    required this.academicYear,
    this.gradeId,
    required this.registrationDate,
  });

  // Backward compatibility alias
  String get userName => name;

  factory UserInfoDto.fromJson(Map<String, dynamic> json) {
    return UserInfoDto(
      id: json['id'] as String? ?? json['Id'] as String? ?? '',
      name: json['name'] as String? ?? json['Name'] as String? ?? '',
      email: json['email'] as String? ?? json['Email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? json['PhoneNumber'] as String? ?? '',
      parentPhone: json['parentPhone'] as String? ?? json['ParentPhone'] as String? ?? '',
      imagePath: json['imagePath'] as String? ?? json['ImagePath'] as String?,
      academicYear: json['academicYear'] as String? ?? json['AcademicYear'] as String? ?? '',
      gradeId: json['gradeId'] as String? ?? json['GradeId'] as String?,
      registrationDate: json['registrationDate'] != null
          ? DateTime.parse(json['registrationDate'] as String)
          : (json['RegistrationDate'] != null
              ? DateTime.parse(json['RegistrationDate'] as String)
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'parentPhone': parentPhone,
      'imagePath': imagePath,
      'academicYear': academicYear,
      'gradeId': gradeId,
      'registrationDate': registrationDate.toIso8601String(),
    };
  }

  /// Get full image URL
  String? getImageUrl(String baseUrl) {
    if (imagePath == null || imagePath!.isEmpty) return null;
    if (imagePath!.startsWith('http')) return imagePath;
    return '$baseUrl/$imagePath';
  }

  @override
  String toString() {
    return 'UserInfoDto(id: $id, name: $name, email: $email, academicYear: $academicYear)';
  }
}
