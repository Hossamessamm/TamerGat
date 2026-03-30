class Teacher {
  final String id;
  final String name;
  final String? subject; // Made optional
  final String bio;
  final String imageUrl;
  final double rating;
  final int studentsCount;
  final bool isOnline;
  final bool isPremium;

  Teacher({
    required this.id,
    required this.name,
    this.subject, // Now optional
    required this.bio,
    required this.imageUrl,
    required this.rating,
    required this.studentsCount,
    this.isOnline = false,
    this.isPremium = false,
  });
}
