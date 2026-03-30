import 'dart:io';
import 'package:http/http.dart' as http;
import '../grade_enum.dart';

/// Register request DTO matching backend RegisterDto
class RegisterRequestDto {
  final String userName;
  final String password;
  final String email;
  final String phoneNumber;
  final GradeEnum? academicYear;
  final String? confirmPassword;
  final String? parentPhone;
  final File? image;
  final bool? isOnline;
  final String? urologyBoard;
  final String? nationality;
  final String? country;
  final String? hospital;
  final int? sectionId; // Department ID
  final String? gradeId; // Grade ID (Guid as String)

  RegisterRequestDto({
    required this.userName,
    required this.password,
    required this.email,
    required this.phoneNumber,
    this.academicYear,
    this.confirmPassword,
    this.parentPhone,
    this.image,
    this.isOnline,
    this.urologyBoard,
    this.nationality,
    this.country,
    this.hospital,
    this.sectionId,
    this.gradeId,
  });

  /// Convert to multipart request for form data submission
  Future<http.MultipartRequest> toMultipartRequest(String url) async {
    final request = http.MultipartRequest('POST', Uri.parse(url));

    // Add text fields
    request.fields['UserName'] = userName;
    request.fields['Password'] = password;
    request.fields['Email'] = email;
    request.fields['PhoneNumber'] = phoneNumber;
    
    if (academicYear != null) {
      request.fields['AcademicYear'] = academicYear!.toInt().toString();
    }
    
    if (parentPhone != null && parentPhone!.isNotEmpty) {
      request.fields['ParentPhone'] = parentPhone!;
    }
    
    if (sectionId != null) {
      request.fields['SectionId'] = sectionId!.toString();
    }
    
    if (gradeId != null && gradeId!.isNotEmpty) {
      request.fields['GradeId'] = gradeId!;
    }

    if (confirmPassword != null) {
      request.fields['ConfirmPassword'] = confirmPassword!;
    }

    if (isOnline != null) {
      request.fields['IsOnline'] = isOnline.toString();
    }

    if (urologyBoard != null && urologyBoard!.isNotEmpty) {
      request.fields['UrologyBoard'] = urologyBoard!;
    }

    if (nationality != null && nationality!.isNotEmpty) {
      request.fields['Nationality'] = nationality!;
    }

    if (country != null && country!.isNotEmpty) {
      request.fields['Country'] = country!;
    }

    if (hospital != null && hospital!.isNotEmpty) {
      request.fields['Hospital'] = hospital!;
    }

    // Add image file if provided
    if (image != null) {
      final imageFile = await http.MultipartFile.fromPath(
        'Image',
        image!.path,
      );
      request.files.add(imageFile);
    }

    return request;
  }

  /// Convert to Map for debugging
  Map<String, dynamic> toMap() {
    return {
      'UserName': userName,
      'Password': password,
      'Email': email,
      'PhoneNumber': phoneNumber,
      'AcademicYear': academicYear?.toInt(),
      'AcademicYearString': academicYear?.toBackendString(),
      'ConfirmPassword': confirmPassword,
      'ParentPhone': parentPhone,
      'Image': image?.path,
      'IsOnline': isOnline,
      'UrologyBoard': urologyBoard,
      'Nationality': nationality,
      'Country': country,
      'Hospital': hospital,
      'SectionId': sectionId,
      'GradeId': gradeId,
    };
  }

  @override
  String toString() => toMap().toString();
}
