class StudentProgressStats {
  final String userId;
  final String userName;
  final int totalCoursesEnrolled;
  final int completedLessons;
  final int totalLessons;
  final double completionPercentage;
  final double averageQuizScore;
  final DateTime lastActivity;

  StudentProgressStats({
    required this.userId,
    required this.userName,
    required this.totalCoursesEnrolled,
    required this.completedLessons,
    required this.totalLessons,
    required this.completionPercentage,
    required this.averageQuizScore,
    required this.lastActivity,
  });

  factory StudentProgressStats.fromJson(Map<String, dynamic> json) {
    return StudentProgressStats(
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      totalCoursesEnrolled: json['totalCoursesEnrolled'] ?? 0,
      completedLessons: json['completedLessons'] ?? 0,
      totalLessons: json['totalLessons'] ?? 0,
      completionPercentage: (json['completionPercentage'] ?? 0.0).toDouble(),
      averageQuizScore: (json['averageQuizScore'] ?? 0.0).toDouble(),
      lastActivity: json['lastActivity'] != null
          ? DateTime.parse(json['lastActivity'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'totalCoursesEnrolled': totalCoursesEnrolled,
      'completedLessons': completedLessons,
      'totalLessons': totalLessons,
      'completionPercentage': completionPercentage,
      'averageQuizScore': averageQuizScore,
      'lastActivity': lastActivity.toIso8601String(),
    };
  }
}
