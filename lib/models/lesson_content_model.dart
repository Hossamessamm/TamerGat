import 'package:tamergat_app/utils/quiz_pass_config.dart';
import 'package:tamergat_app/models/course_tree_progress_model.dart';

// File Lesson Model
class FileLessonDto {
  final int id;
  final String? lessonName;
  final String? titel;
  final int? unitId;
  final bool? active;
  final int? order;
  final String? type;
  final String? filePath1;
  final String? filePath2;
  final bool isCompleted;

  FileLessonDto({
    required this.id,
    this.lessonName,
    this.titel,
    this.unitId,
    this.active,
    this.order,
    this.type,
    this.filePath1,
    this.filePath2,
    this.isCompleted = false,
  });

  factory FileLessonDto.fromJson(Map<String, dynamic> json) {
    return FileLessonDto(
      id: json['id'] ?? 0,
      lessonName: json['lessonName'],
      titel: json['titel'],
      unitId: json['unitId'],
      active: json['active'],
      order: json['order'],
      type: json['type'],
      filePath1: json['filePath1'],
      filePath2: json['filePath2'],
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}

class FileLessonResponse {
  final bool success;
  final String? message;
  final FileLessonDto? data;

  FileLessonResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory FileLessonResponse.fromJson(Map<String, dynamic> json) {
    return FileLessonResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null 
          ? FileLessonDto.fromJson(json['data']) 
          : null,
    );
  }
}

// Video Lesson Model
class VideoLessonDto {
  final int id;
  final String? videoUrl;
  final String? attachmentUrl;
  final String? attachmentTitle;
  final bool isCompleted;

  VideoLessonDto({
    required this.id,
    this.videoUrl,
    this.attachmentUrl,
    this.attachmentTitle,
    required this.isCompleted,
  });

  factory VideoLessonDto.fromJson(Map<String, dynamic> json) {
    return VideoLessonDto(
      id: json['id'] ?? 0,
      videoUrl: json['videoUrl'],
      attachmentUrl: json['attachmentUrl'],
      attachmentTitle: json['attachmentTitle'],
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}

class VideoLessonResponse {
  final bool success;
  final String? message;
  final VideoLessonDto? data;

  VideoLessonResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory VideoLessonResponse.fromJson(Map<String, dynamic> json) {
    return VideoLessonResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null 
          ? VideoLessonDto.fromJson(json['data']) 
          : null,
    );
  }
}

// Quiz Lesson Models
enum QuestionType {
  multipleChoice, // 0
  trueFalse,      // 1
  oneAnswer,      // "OneAnswer" - Flashcard type
}

class AnswerDto {
  final String text;
  final bool isCorrect;

  AnswerDto({
    required this.text,
    required this.isCorrect,
  });

  factory AnswerDto.fromJson(Map<String, dynamic> json) {
    return AnswerDto(
      text: json['text'] ?? '',
      isCorrect: json['isCorrect'] ?? false,
    );
  }
}

class QuestionDto {
  final String text;
  final QuestionType type;
  final List<AnswerDto> answers;
  final String? imageUrl; // Image URL for the question
  final String? reason; // Explanation/reason for the correct answer

  QuestionDto({
    required this.text,
    required this.type,
    required this.answers,
    this.imageUrl,
    this.reason,
  });

  factory QuestionDto.fromJson(Map<String, dynamic> json) {
    // Parse type - can be int (0, 1) or string ("MultipleChoice", "TrueFalse", "OneAnswer")
    QuestionType parsedType = QuestionType.multipleChoice;
    final typeValue = json['type'];
    
    if (typeValue is int) {
      parsedType = typeValue == 0 ? QuestionType.multipleChoice : QuestionType.trueFalse;
    } else if (typeValue is String) {
      final typeStr = typeValue.toLowerCase();
      if (typeStr == 'multiplechoice') {
        parsedType = QuestionType.multipleChoice;
      } else if (typeStr == 'truefalse') {
        parsedType = QuestionType.trueFalse;
      } else if (typeStr == 'oneanswer') {
        parsedType = QuestionType.oneAnswer;
      }
    }
    
    return QuestionDto(
      text: json['text'] ?? '',
      type: parsedType,
      answers: (json['answers'] as List<dynamic>?)
              ?.map((a) => AnswerDto.fromJson(a))
              .toList() ?? [],
      imageUrl: json['imageUrl'] ?? json['image'] ?? json['imagePath'],
      reason: json['reason'],
    );
  }
}

class QuizLessonResponse {
  final bool success;
  final String? message;
  final List<QuestionDto>? data;

  /// When `false`, user must not see a "Retake" action (config from API).
  final bool isRetake;

  /// When `false`, hide numeric score on results (config from API).
  final bool isScoreDisplayed;

  /// When `false`, hide correct/incorrect review and explanations after submit (config from API).
  final bool isAnswerDisplayed;

  /// Minimum percentage (0–100) required to count as passed for unlocking next lessons (e.g. 50.0 = 50%).
  final double passDegree;

  QuizLessonResponse({
    required this.success,
    this.message,
    this.data,
    this.isRetake = true,
    this.isScoreDisplayed = true,
    this.isAnswerDisplayed = true,
    this.passDegree = kDefaultQuizPassDegreePercent,
  });

  factory QuizLessonResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    List<QuestionDto>? questions;
    var isRetake = true;
    var isScoreDisplayed = true;
    var isAnswerDisplayed = true;
    var passDegree = kDefaultQuizPassDegreePercent;

    if (rawData is List) {
      questions = rawData
          .map((q) => QuestionDto.fromJson(q as Map<String, dynamic>))
          .toList();
      passDegree = tryPassDegreeFromMap(Map<String, dynamic>.from(json)) ??
          kDefaultQuizPassDegreePercent;
    } else if (rawData is Map) {
      final m = Map<String, dynamic>.from(rawData);
      final list = m['questions'] ?? m['Questions'];
      if (list is List) {
        questions = list
            .map((q) => QuestionDto.fromJson(q as Map<String, dynamic>))
            .toList();
      }
      isRetake = parseQuizBool(m['isRetake'] ?? m['IsRetake'], true);
      isScoreDisplayed =
          parseQuizBool(m['isScoreDisplayed'] ?? m['IsScoreDisplayed'], true);
      isAnswerDisplayed =
          parseQuizBool(m['isAnswerDisplayed'] ?? m['IsAnswerDisplayed'], true);
      passDegree = tryPassDegreeFromMap(m) ??
          tryPassDegreeFromMap(Map<String, dynamic>.from(json)) ??
          kDefaultQuizPassDegreePercent;
    }

    return QuizLessonResponse(
      success: json['success'] ?? false,
      message: json['message']?.toString(),
      data: questions,
      isRetake: isRetake,
      isScoreDisplayed: isScoreDisplayed,
      isAnswerDisplayed: isAnswerDisplayed,
      passDegree: passDegree,
    );
  }

  /// Tree-with-progress can supply flags before lesson-content merge; non-null [o] fields win.
  QuizLessonResponse mergeWithTreeOverrides(QuizLessonTreeOverrides? o) {
    if (o == null) return this;
    return QuizLessonResponse(
      success: success,
      message: message,
      data: data,
      isRetake: o.isRetake ?? isRetake,
      isScoreDisplayed: o.isScoreDisplayed ?? isScoreDisplayed,
      isAnswerDisplayed: o.isAnswerDisplayed ?? isAnswerDisplayed,
      passDegree: o.passDegree ?? passDegree,
    );
  }
}

/// Optional quiz UI flags from [LessonTree] / unit JSON (course tree API).
class QuizLessonTreeOverrides {
  final bool? isRetake;
  final bool? isScoreDisplayed;
  final bool? isAnswerDisplayed;
  final double? passDegree;

  const QuizLessonTreeOverrides({
    this.isRetake,
    this.isScoreDisplayed,
    this.isAnswerDisplayed,
    this.passDegree,
  });

  factory QuizLessonTreeOverrides.fromLessonTree(LessonTree lesson) {
    return QuizLessonTreeOverrides(
      isRetake: lesson.isRetake,
      isScoreDisplayed: lesson.isScoreDisplayed,
      isAnswerDisplayed: lesson.isAnswerDisplayed,
      passDegree: lesson.passDegree,
    );
  }

  factory QuizLessonTreeOverrides.fromLessonMap(Map<String, dynamic> json) {
    return QuizLessonTreeOverrides(
      isRetake: parseQuizBoolNullable(json['isRetake'] ?? json['IsRetake']),
      isScoreDisplayed:
          parseQuizBoolNullable(json['isScoreDisplayed'] ?? json['IsScoreDisplayed']),
      isAnswerDisplayed:
          parseQuizBoolNullable(json['isAnswerDisplayed'] ?? json['IsAnswerDisplayed']),
      passDegree: tryPassDegreeFromMap(Map<String, dynamic>.from(json)),
    );
  }
}
