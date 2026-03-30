/// Default only when the API omits a pass threshold (keeps one place to change behavior).
const double kDefaultQuizPassDegreePercent = 50;

/// In-memory cache: lesson content API returns [passDegree]; course tree may not.
/// Ensures lock UI and [LessonTree.isQuizPassed] use the same dynamic threshold.
class QuizPassDegreeCache {
  QuizPassDegreeCache._();

  static final Map<int, double> _byLessonId = {};

  static void remember(int lessonId, double passDegree) {
    _byLessonId[lessonId] = passDegree.clamp(0, 100);
  }

  static double? forLesson(int lessonId) => _byLessonId[lessonId];

  static void remove(int lessonId) => _byLessonId.remove(lessonId);

  static void clear() => _byLessonId.clear();
}

double? _tryParsePassDegreeDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble().clamp(0, 100);
  return double.tryParse(v.toString())?.clamp(0, 100);
}

/// Reads the first non-null pass threshold from common API key spellings.
double? tryPassDegreeFromMap(Map<String, dynamic> json) {
  const keys = [
    'passDegree',
    'PassDegree',
    'passingDegree',
    'PassingDegree',
    'minPassPercent',
    'MinPassPercent',
    'minimumPassPercentage',
    'MinimumPassPercentage',
    'passPercent',
    'PassPercent',
    'requiredPassPercent',
    'RequiredPassPercent',
    'passingScore',
    'PassingScore',
  ];
  for (final k in keys) {
    final d = _tryParsePassDegreeDouble(json[k]);
    if (d != null) return d;
  }
  return null;
}

/// Shared quiz flag parsing (lesson content + course tree JSON).
bool parseQuizBool(dynamic v, [bool defaultValue = true]) {
  if (v == null) return defaultValue;
  if (v is bool) return v;
  if (v is String) {
    final s = v.toLowerCase();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
  }
  if (v is num) return v != 0;
  return defaultValue;
}

/// When the value is absent, returns null; when present, parses a bool.
bool? parseQuizBoolNullable(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;
  if (v is String) {
    final s = v.toLowerCase();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
  }
  if (v is num) return v != 0;
  return null;
}
