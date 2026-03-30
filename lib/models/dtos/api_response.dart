/// Generic API response wrapper matching backend ApiResponse<T>
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    // Get the data field (check both lowercase and PascalCase)
    final rawData = json['data'] ?? json['Data'];
    
    // If fromJsonT is provided, use it to transform the data
    // Otherwise, return the raw data as-is (cast to T)
    final T? data;
    if (rawData != null && fromJsonT != null) {
      data = fromJsonT(rawData);
    } else if (rawData != null) {
      // When fromJsonT is null, return raw data (for List, Map, etc.)
      data = rawData as T?;
    } else {
      data = null;
    }
    
    return ApiResponse<T>(
      success: json['success'] as bool? ?? json['Success'] as bool? ?? false,
      message: json['message'] as String? ?? json['Message'] as String? ?? '',
      data: data,
    );
  }

  /// Factory for success response
  factory ApiResponse.success({
    required String message,
    T? data,
  }) {
    return ApiResponse<T>(
      success: true,
      message: message,
      data: data,
    );
  }

  /// Factory for failure response
  factory ApiResponse.failure({
    required String message,
  }) {
    return ApiResponse<T>(
      success: false,
      message: message,
      data: null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
    };
  }

  @override
  String toString() {
    return 'ApiResponse(success: $success, message: $message, data: $data)';
  }
}
