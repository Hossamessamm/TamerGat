/// Helper class for working with JSON data
class JsonHelper {
  /// Get a value from a Map with case-insensitive key lookup
  /// 
  /// Example:
  /// ```dart
  /// final data = {'Token': 'abc123', 'User': {...}};
  /// final token = JsonHelper.getValue(data, 'token'); // Returns 'abc123'
  /// ```
  static dynamic getValue(Map<String, dynamic>? map, String key) {
    if (map == null) return null;
    
    // Try exact match first (fastest)
    if (map.containsKey(key)) {
      return map[key];
    }
    
    // Try case-insensitive match
    final lowerKey = key.toLowerCase();
    for (final entry in map.entries) {
      if (entry.key.toLowerCase() == lowerKey) {
        return entry.value;
      }
    }
    
    return null;
  }

  /// Get a String value with case-insensitive key lookup
  static String? getString(Map<String, dynamic>? map, String key) {
    final value = getValue(map, key);
    return value is String ? value : null;
  }

  /// Get a Map value with case-insensitive key lookup
  static Map<String, dynamic>? getMap(Map<String, dynamic>? map, String key) {
    final value = getValue(map, key);
    if (value is Map<String, dynamic>) {
      return value;
    } else if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  /// Get a bool value with case-insensitive key lookup
  static bool? getBool(Map<String, dynamic>? map, String key) {
    final value = getValue(map, key);
    return value is bool ? value : null;
  }

  /// Get a List value with case-insensitive key lookup
  static List<dynamic>? getList(Map<String, dynamic>? map, String key) {
    final value = getValue(map, key);
    return value is List ? value : null;
  }

  /// Normalize a JSON response by converting all keys to lowercase
  /// Useful when backend may return inconsistent casing
  static Map<String, dynamic> normalizeKeys(Map<String, dynamic> map) {
    final normalized = <String, dynamic>{};
    
    for (final entry in map.entries) {
      final key = entry.key.toLowerCase();
      final value = entry.value;
      
      if (value is Map<String, dynamic>) {
        normalized[key] = normalizeKeys(value);
      } else if (value is Map) {
        normalized[key] = normalizeKeys(Map<String, dynamic>.from(value));
      } else if (value is List) {
        normalized[key] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return normalizeKeys(item);
          } else if (item is Map) {
            return normalizeKeys(Map<String, dynamic>.from(item));
          }
          return item;
        }).toList();
      } else {
        normalized[key] = value;
      }
    }
    
    return normalized;
  }
}
