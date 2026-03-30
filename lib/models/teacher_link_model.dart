class TeacherLink {
  final String id;
  final String teacherId;
  final String teacherName;
  final String teacherEmail;
  final String? phoneNumber;
  final String? biography;
  final String? qualifications;
  final String? department;
  final int? yearsOfExperience;
  final String? imagePath;
  final String? whatsApp;
  final String? youTube;
  final String? tikTok;
  final String? facebook;
  final int teacherCode;
  final DateTime linkedDate;
  final bool isActive;
  final String? notes;

  TeacherLink({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.teacherEmail,
    this.phoneNumber,
    this.biography,
    this.qualifications,
    this.department,
    this.yearsOfExperience,
    this.imagePath,
    this.whatsApp,
    this.youTube,
    this.tikTok,
    this.facebook,
    required this.teacherCode,
    required this.linkedDate,
    required this.isActive,
    this.notes,
  });

  factory TeacherLink.fromJson(Map<String, dynamic> json) {
    return TeacherLink(
      id: json['Id'] ?? json['id'] ?? '',
      teacherId: json['TeacherId'] ?? json['teacherId'] ?? '',
      teacherName: json['TeacherName'] ?? json['teacherName'] ?? '',
      teacherEmail: json['TeacherEmail'] ?? json['teacherEmail'] ?? '',
      phoneNumber: json['PhoneNumber'] ?? json['phoneNumber'],
      biography: json['Biography'] ?? json['biography'],
      qualifications: json['Qualifications'] ?? json['qualifications'],
      department: json['Department'] ?? json['department'],
      yearsOfExperience: json['YearsOfExperience'] ?? json['yearsOfExperience'],
      imagePath: json['ImagePath'] ?? json['imagePath'],
      whatsApp: (json['WhatsApp']?.toString().isNotEmpty == true ? json['WhatsApp'] : null) ??
          (json['whatsApp']?.toString().isNotEmpty == true ? json['whatsApp'] : null) ??
          (json['whatsApp_Number']?.toString().isNotEmpty == true ? json['whatsApp_Number'] : null) ??
          (json['WhatsApp_Number']?.toString().isNotEmpty == true ? json['WhatsApp_Number'] : null),
      youTube: json['YouTube'] ?? json['youTube'],
      tikTok: json['TikTok'] ?? json['tikTok'],
      facebook: json['Facebook'] ?? json['facebook'],
      teacherCode: json['TeacherCode'] ?? json['teacherCode'] ?? 0,
      linkedDate: (json['LinkedDate'] ?? json['linkedDate']) != null
          ? DateTime.parse(json['LinkedDate'] ?? json['linkedDate'])
          : DateTime.now(),
      isActive: json['IsActive'] ?? json['isActive'] ?? true,
      notes: json['Notes'] ?? json['notes'],
    );
  }
}

class StudentTeachersResponse {
  final String studentId;
  final String studentName;
  final int totalTeachers;
  final List<TeacherLink> teachers;

  StudentTeachersResponse({
    required this.studentId,
    required this.studentName,
    required this.totalTeachers,
    required this.teachers,
  });

  factory StudentTeachersResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return StudentTeachersResponse(
      studentId: data['StudentId'] ?? data['studentId'] ?? '',
      studentName: data['StudentName'] ?? data['studentName'] ?? '',
      totalTeachers: data['TotalTeachers'] ?? data['totalTeachers'] ?? 0,
      teachers: (data['Teachers'] ?? data['teachers'] ?? [])
          .map<TeacherLink>((t) => TeacherLink.fromJson(t))
          .toList(),
    );
  }
}
