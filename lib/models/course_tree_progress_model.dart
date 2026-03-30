import 'package:tamergat_app/utils/quiz_pass_config.dart';

class CourseTreeWithProgress {
  final String id;
  final String? courseName;
  final String? term;
  final bool active;
  final double price;
  final String? grade;
  final String? description;
  final String? imagePath;
  final String? groupLink;
  final DateTime modificationDate;
  final DateTime? enrollmentDate;
  final bool isOpenToAll;
  final List<UnitTree> units;

  CourseTreeWithProgress({
    required this.id,
    this.courseName,
    this.term,
    required this.active,
    required this.price,
    this.grade,
    this.description,
    this.imagePath,
    this.groupLink,
    required this.modificationDate,
    this.enrollmentDate,
    required this.isOpenToAll,
    required this.units,
  });

  factory CourseTreeWithProgress.fromJson(Map<String, dynamic> json) {
    return CourseTreeWithProgress(
      id: json['id'] ?? '',
      courseName: json['courseName'],
      term: json['term'],
      active: json['active'] ?? false,
      price: (json['price'] ?? 0).toDouble(),
      grade: json['grade'],
      description: json['description'],
      imagePath: json['imagePath'],
      groupLink: json['groupLink'],
      modificationDate: DateTime.parse(json['modificationDate']),
      enrollmentDate: json['enrollmentDate'] != null 
          ? DateTime.parse(json['enrollmentDate']) 
          : null,
      isOpenToAll: json['isOpenToAll'] ?? false,
      units: (json['units'] as List<dynamic>?)
              ?.map((u) => UnitTree.fromJson(u))
              .toList() ?? [],
    );
  }
}

class UnitTree {
  final int id;
  final String unitName;
  final String titel;
  final bool active;
  final int order;
  final DateTime creationDate;
  final DateTime? enrollmentDate;
  final List<LessonTree> lessons;

  UnitTree({
    required this.id,
    required this.unitName,
    required this.titel,
    required this.active,
    required this.order,
    required this.creationDate,
    this.enrollmentDate,
    required this.lessons,
  });

  factory UnitTree.fromJson(Map<String, dynamic> json) {
    return UnitTree(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      unitName: json['unitName'] ?? '',
      titel: json['titel'] ?? '',
      active: json['active'] ?? false,
      order: json['order'] is int ? json['order'] : int.tryParse(json['order']?.toString() ?? '0') ?? 0,
      creationDate: DateTime.parse(json['creationDate']),
      enrollmentDate: json['enrollmentDate'] != null 
          ? DateTime.parse(json['enrollmentDate']) 
          : null,
      lessons: (json['lessons'] as List<dynamic>?)
              ?.map((l) => LessonTree.fromJson(l))
              .toList() ?? [],
    );
  }

  // Calculate unit progress percentage
  double get progressPercentage {
    if (lessons.isEmpty) return 0.0;
    
    int completedCount = 0;
    for (var lesson in lessons) {
      if (lesson.type == LessonType.video && lesson.isCompleted == true) {
        completedCount++;
      } else if (lesson.type == LessonType.quiz && lesson.isQuizSubmitted == true) {
        completedCount++;
      } else if (lesson.type == LessonType.file && lesson.isCompleted == true) {
        completedCount++;
      }
    }
    
    return (completedCount / lessons.length) * 100;
  }
}

class LessonTree {
  final int id;
  final String? lessonName;
  final String? titel;
  final int order;
  final bool active;
  final LessonType? type;
  final bool? isCompleted;
  final bool? isQuizSubmitted;
  /// Quiz score 0–100 if returned by API. Used to unlock content after quiz.
  final double? quizScore;

  /// Minimum score % to pass (from course tree API when provided).
  final double? passDegree;

  /// Quiz-only flags from `tree-course-with-progress` (null for non-quiz lessons).
  final bool? isRetake;
  final bool? isScoreDisplayed;
  final bool? isAnswerDisplayed;

  LessonTree({
    required this.id,
    this.lessonName,
    this.titel,
    required this.order,
    required this.active,
    this.type,
    this.isCompleted,
    this.isQuizSubmitted,
    this.quizScore,
    this.passDegree,
    this.isRetake,
    this.isScoreDisplayed,
    this.isAnswerDisplayed,
  });

  factory LessonTree.fromJson(Map<String, dynamic> json) {
    // Parse type - can be int (0, 1, 2) or string ("Video", "Quiz", "File")
    LessonType? parsedType;
    if (json['type'] != null) {
      if (json['type'] is int) {
        parsedType = LessonType.values[json['type']];
      } else if (json['type'] is String) {
        final typeStr = json['type'].toString().toLowerCase();
        if (typeStr == 'video') {
          parsedType = LessonType.video;
        } else if (typeStr == 'quiz') {
          parsedType = LessonType.quiz;
        } else if (typeStr == 'file') {
          parsedType = LessonType.file;
        }
      }
    }

    final score = json['score'] ?? json['quizScore'] ?? json['QuizScore'];
    final scoreNum = score is num ? score.toDouble() : (score != null ? double.tryParse(score.toString()) : null);

    final passDegreeNum = tryPassDegreeFromMap(
      Map<String, dynamic>.from(json),
    );

    return LessonTree(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      lessonName: json['lessonName'],
      titel: json['titel'],
      order: json['order'] is int ? json['order'] : int.tryParse(json['order']?.toString() ?? '0') ?? 0,
      active: json['active'] ?? false,
      type: parsedType,
      isCompleted: json['isCompleted'],
      isQuizSubmitted: json['isQuizSubmitted'],
      quizScore: scoreNum,
      passDegree: passDegreeNum,
      isRetake: parseQuizBoolNullable(json['isRetake'] ?? json['IsRetake']),
      isScoreDisplayed:
          parseQuizBoolNullable(json['isScoreDisplayed'] ?? json['IsScoreDisplayed']),
      isAnswerDisplayed:
          parseQuizBoolNullable(json['isAnswerDisplayed'] ?? json['IsAnswerDisplayed']),
    );
  }

  /// True if this quiz has been passed (score >= threshold from API, cache, or default).
  bool get isQuizPassed {
    if (type != LessonType.quiz) return false;
    if (quizScore == null) return false;
    final threshold = passDegree ??
        QuizPassDegreeCache.forLesson(id) ??
        kDefaultQuizPassDegreePercent;
    return quizScore! >= threshold;
  }

  // Check if lesson is completed (works for video, quiz, and file)
  bool get isDone {
    if (type == LessonType.video) {
      return isCompleted == true;
    } else if (type == LessonType.quiz) {
      return isQuizSubmitted == true;
    } else if (type == LessonType.file) {
      return isCompleted == true;
    }
    return false;
  }

  /// When [isRetake] is false, the user must not open the quiz again after submit.
  /// [isRetake] null is treated as retake allowed (backward compatible).
  bool get isQuizRetakeBlocked =>
      type == LessonType.quiz &&
      isRetake == false &&
      isQuizSubmitted == true;
}

enum LessonType {
  video,  // 0
  quiz,   // 1
  file,   // 2
}

class CourseTreeWithProgressResponse {
  final bool success;
  final String? message;
  final CourseTreeWithProgress? data;

  CourseTreeWithProgressResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory CourseTreeWithProgressResponse.fromJson(Map<String, dynamic> json) {
    return CourseTreeWithProgressResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null 
          ? CourseTreeWithProgress.fromJson(json['data']) 
          : null,
    );
  }
}
