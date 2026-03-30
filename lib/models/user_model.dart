import 'academic_year.dart';

class User {
  final String id;
  final String userName;
  final String email;
  final String phoneNumber;
  final String parentPhone;
  final String? imagePath;
  final AcademicYear academicYear;
  final DateTime registrationDate;

  User({
    required this.id,
    required this.userName,
    required this.email,
    required this.phoneNumber,
    required this.parentPhone,
    this.imagePath,
    required this.academicYear,
    required this.registrationDate,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle both PascalCase (from toJson) and lowercase (from API) keys
    return User(
      id: json['Id'] ?? json['id'] ?? '',
      userName: json['Name'] ?? json['name'] ?? json['userName'] ?? '',
      email: json['Email'] ?? json['email'] ?? '',
      phoneNumber: json['PhoneNumber'] ?? json['phoneNumber'] ?? '',
      parentPhone: json['ParentPhone'] ?? json['parentPhone'] ?? '',
      imagePath: json['ImagePath'] ?? json['imagePath'],
      academicYear: AcademicYear.values.firstWhere(
        (year) => year.apiValue == (json['AcademicYear'] ?? json['academicYear']), // Use apiValue for API compatibility
        orElse: () => AcademicYear.primary1,
      ),
      registrationDate: (json['RegistrationDate'] ?? json['registrationDate']) != null
          ? DateTime.parse(json['RegistrationDate'] ?? json['registrationDate'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'Name': userName,
      'Email': email,
      'PhoneNumber': phoneNumber,
      'ParentPhone': parentPhone,
      'ImagePath': imagePath,
      'AcademicYear': academicYear.apiValue, // Use apiValue for API communication
      'RegistrationDate': registrationDate.toIso8601String(),
    };
  }
}
