/// Utility class for translating API error messages to Arabic
class ErrorMessages {
  /// Map of English error messages to Arabic translations
  static final Map<String, String> _errorTranslations = {
    // 400 Bad Request errors
    'Invalid credentials': 'بيانات الدخول غير صحيحة',
    'Device ID is required.': 'معرف الجهاز مطلوب.',
    'Please confirm your email first.': 'يرجى تأكيد بريدك الإلكتروني أولاً.',
    
    // 403 Forbidden errors
    'Your account is inactive. Please contact support.': 'حسابك غير نشط. يرجى التواصل مع الدعم.',
    "You can't log in from more than two devices.": 'لا يمكنك تسجيل الدخول من أكثر من جهازين.',
    
    // Generic errors
    'Login failed': 'فشل تسجيل الدخول',
    'Login failed. Please try again.': 'فشل تسجيل الدخول. يرجى المحاولة مرة أخرى.',
    'Network error': 'خطأ في الشبكة',
    'Failed to save login data. Please try again.': 'فشل حفظ بيانات تسجيل الدخول. يرجى المحاولة مرة أخرى.',
  };

  /// Translate an error message from English to Arabic
  /// If the exact message is not found, it tries to find a partial match
  /// If no match is found, returns the original message
  static String translate(String errorMessage) {
    // First, try exact match
    if (_errorTranslations.containsKey(errorMessage)) {
      return _errorTranslations[errorMessage]!;
    }

    // Try to find partial match (case-insensitive)
    final lowerMessage = errorMessage.toLowerCase();
    for (final entry in _errorTranslations.entries) {
      if (lowerMessage.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }

    // Handle network errors with dynamic content
    if (errorMessage.startsWith('Network error:')) {
      return 'خطأ في الشبكة: ${errorMessage.substring('Network error:'.length).trim()}';
    }

    // If no translation found, return original message
    return errorMessage;
  }

  /// Get a user-friendly error title in Arabic
  static String getErrorTitle(String errorMessage) {
    if (errorMessage.contains('Invalid credentials') || 
        errorMessage.contains('بيانات الدخول غير صحيحة')) {
      return 'خطأ في تسجيل الدخول';
    }
    
    if (errorMessage.contains('inactive') || 
        errorMessage.contains('غير نشط')) {
      return 'حساب غير نشط';
    }
    
    if (errorMessage.contains('confirm your email') || 
        errorMessage.contains('تأكيد بريدك الإلكتروني')) {
      return 'تأكيد البريد الإلكتروني';
    }
    
    if (errorMessage.contains('devices') || 
        errorMessage.contains('جهازين')) {
      return 'تجاوز عدد الأجهزة';
    }
    
    if (errorMessage.toLowerCase().contains('network')) {
      return 'خطأ في الاتصال';
    }
    
    return 'خطأ';
  }
}
