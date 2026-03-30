enum AcademicYear {
  primary1(0, 'Primary1', 'الصف الأول الابتدائي'),
  primary2(1, 'Primary2', 'الصف الثاني الابتدائي'),
  primary3(2, 'Primary3', 'الصف الثالث الابتدائي'),
  primary4(3, 'Primary4', 'الصف الرابع الابتدائي'),
  primary5(4, 'Primary5', 'الصف الخامس الابتدائي'),
  primary6(5, 'Primary6', 'الصف السادس الابتدائي'),
  prep1(6, 'Prep1', 'الصف الأول الإعدادي'),
  prep2(7, 'Prep2', 'الصف الثاني الإعدادي'),
  prep3(8, 'Prep3', 'الصف الثالث الإعدادي'),
  secondary1(9, 'Secondary1', 'الصف الأول الثانوي'),
  secondary2(10, 'Secondary2', 'الصف الثاني الثانوي'),
  secondary3(11, 'Secondary3', 'الصف الثالث الثانوي');

  const AcademicYear(this.value, this.apiValue, this.displayName);
  
  final int value;
  final String apiValue; // English value for API communication
  final String displayName; // Arabic display name for UI
  
  static AcademicYear fromValue(int value) {
    return AcademicYear.values.firstWhere(
      (year) => year.value == value,
      orElse: () => AcademicYear.primary1,
    );
  }
  
  static AcademicYear fromApiValue(String apiValue) {
    return AcademicYear.values.firstWhere(
      (year) => year.apiValue == apiValue,
      orElse: () => AcademicYear.primary1,
    );
  }
}
