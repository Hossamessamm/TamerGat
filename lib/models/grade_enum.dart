/// Academic grade/year enumeration matching backend GradeEnum
/// Maps to integers 0-11 for API communication
enum GradeEnum {
  primary1,    // 0
  primary2,    // 1
  primary3,    // 2
  primary4,    // 3
  primary5,    // 4
  primary6,    // 5
  prep1,       // 6
  prep2,       // 7
  prep3,       // 8
  secondary1,  // 9
  secondary2,  // 10
  secondary3,  // 11
}

extension GradeEnumExtension on GradeEnum {
  /// Convert enum to integer for API
  int toInt() {
    return index;
  }

  /// Convert enum to display string (Arabic)
  String toDisplayString() {
    switch (this) {
      case GradeEnum.primary1:
        return 'الصف الأول الابتدائي';
      case GradeEnum.primary2:
        return 'الصف الثاني الابتدائي';
      case GradeEnum.primary3:
        return 'الصف الثالث الابتدائي';
      case GradeEnum.primary4:
        return 'الصف الرابع الابتدائي';
      case GradeEnum.primary5:
        return 'الصف الخامس الابتدائي';
      case GradeEnum.primary6:
        return 'الصف السادس الابتدائي';
      case GradeEnum.prep1:
        return 'الصف الأول الإعدادي';
      case GradeEnum.prep2:
        return 'الصف الثاني الإعدادي';
      case GradeEnum.prep3:
        return 'الصف الثالث الإعدادي';
      case GradeEnum.secondary1:
        return 'الصف الأول الثانوي';
      case GradeEnum.secondary2:
        return 'الصف الثاني الثانوي';
      case GradeEnum.secondary3:
        return 'الصف الثالث الثانوي';
    }
  }

  /// Convert enum to backend string format
  String toBackendString() {
    switch (this) {
      case GradeEnum.primary1:
        return 'Primary1';
      case GradeEnum.primary2:
        return 'Primary2';
      case GradeEnum.primary3:
        return 'Primary3';
      case GradeEnum.primary4:
        return 'Primary4';
      case GradeEnum.primary5:
        return 'Primary5';
      case GradeEnum.primary6:
        return 'Primary6';
      case GradeEnum.prep1:
        return 'Prep1';
      case GradeEnum.prep2:
        return 'Prep2';
      case GradeEnum.prep3:
        return 'Prep3';
      case GradeEnum.secondary1:
        return 'Secondary1';
      case GradeEnum.secondary2:
        return 'Secondary2';
      case GradeEnum.secondary3:
        return 'Secondary3';
    }
  }

  /// Get student role name for authorization
  String toRoleName() {
    switch (this) {
      case GradeEnum.primary1:
        return 'Prim1Student';
      case GradeEnum.primary2:
        return 'Prim2Student';
      case GradeEnum.primary3:
        return 'Prim3Student';
      case GradeEnum.primary4:
        return 'Prim4Student';
      case GradeEnum.primary5:
        return 'Prim5Student';
      case GradeEnum.primary6:
        return 'Prim6Student';
      case GradeEnum.prep1:
        return 'Prep1Student';
      case GradeEnum.prep2:
        return 'Prep2Student';
      case GradeEnum.prep3:
        return 'Prep3Student';
      case GradeEnum.secondary1:
        return 'Sec1Student';
      case GradeEnum.secondary2:
        return 'Sec2Student';
      case GradeEnum.secondary3:
        return 'Sec3Student';
    }
  }
}

/// Helper class to parse grade from various formats
class GradeEnumHelper {
  /// Parse from integer (0-11)
  static GradeEnum fromInt(int value) {
    if (value < 0 || value >= GradeEnum.values.length) {
      throw ArgumentError('Invalid grade value: $value');
    }
    return GradeEnum.values[value];
  }

  /// Parse from backend string format (e.g., "Primary1", "Prep2", "Secondary3")
  static GradeEnum? fromBackendString(String value) {
    switch (value) {
      case 'Primary1':
        return GradeEnum.primary1;
      case 'Primary2':
        return GradeEnum.primary2;
      case 'Primary3':
        return GradeEnum.primary3;
      case 'Primary4':
        return GradeEnum.primary4;
      case 'Primary5':
        return GradeEnum.primary5;
      case 'Primary6':
        return GradeEnum.primary6;
      case 'Prep1':
        return GradeEnum.prep1;
      case 'Prep2':
        return GradeEnum.prep2;
      case 'Prep3':
        return GradeEnum.prep3;
      case 'Secondary1':
        return GradeEnum.secondary1;
      case 'Secondary2':
        return GradeEnum.secondary2;
      case 'Secondary3':
        return GradeEnum.secondary3;
      default:
        return null;
    }
  }

  /// Get all grades as list for dropdowns
  static List<GradeEnum> getAllGrades() {
    return GradeEnum.values;
  }
}
