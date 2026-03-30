/// Single-course checkout order model matching BackendIbrahim `OrderDto`.
class OrderDto {
  final String id;
  final String? studentId;
  final String? studentName;
  final String? studentPhoneNumber;

  final String? courseId;
  final String? courseName;

  final String? promoCodeId;
  final String? promoCode;

  final double originalPrice;
  final double discountAmount;
  final double netPrice;

  final DateTime orderDate;
  final OrderStatus status;

  final String? paymentReference;
  final DateTime? paymentDate;

  /// Set when a hosted payment session is started.
  final String? paymentUrl;

  /// Expiry in the same timezone as `orderDate` (Backend normalizes).
  final DateTime? paymentSessionExpiresAt;

  const OrderDto({
    required this.id,
    this.studentId,
    this.studentName,
    this.studentPhoneNumber,
    this.courseId,
    this.courseName,
    this.promoCodeId,
    this.promoCode,
    required this.originalPrice,
    required this.discountAmount,
    required this.netPrice,
    required this.orderDate,
    required this.status,
    this.paymentReference,
    this.paymentDate,
    this.paymentUrl,
    this.paymentSessionExpiresAt,
  });

  factory OrderDto.fromJson(Map<String, dynamic> json) {
    return OrderDto(
      id: (json['Id'] ?? json['id'] ?? '').toString(),
      studentId: json['StudentId']?.toString() ?? json['studentId']?.toString(),
      studentName: json['StudentName']?.toString() ?? json['studentName']?.toString(),
      studentPhoneNumber: json['StudentPhoneNumber']?.toString() ?? json['studentPhoneNumber']?.toString(),
      courseId: json['CourseId']?.toString() ?? json['courseId']?.toString(),
      courseName: json['CourseName']?.toString() ?? json['courseName']?.toString(),
      promoCodeId: json['PromoCodeId']?.toString() ?? json['promoCodeId']?.toString(),
      promoCode: json['PromoCode']?.toString() ?? json['promoCode']?.toString(),

      originalPrice: _toDouble(json['OriginalPrice'] ?? json['originalPrice'], defaultValue: 0),
      discountAmount: _toDouble(json['DiscountAmount'] ?? json['discountAmount'], defaultValue: 0),
      netPrice: _toDouble(json['NetPrice'] ?? json['netPrice'], defaultValue: 0),

      orderDate: _parseDate(json['OrderDate'] ?? json['orderDate']) ?? DateTime.now(),
      status: OrderStatusX.fromJson(json['Status'] ?? json['status']),

      paymentReference: json['PaymentReference']?.toString() ?? json['paymentReference']?.toString(),
      paymentDate: _parseDate(json['PaymentDate'] ?? json['paymentDate']),
      paymentUrl: json['PaymentUrl']?.toString() ?? json['paymentUrl']?.toString(),
      paymentSessionExpiresAt: _parseDate(
        json['PaymentSessionExpiresAt'] ?? json['paymentSessionExpiresAt'],
      ),
    );
  }

  static double _toDouble(dynamic value, {required double defaultValue}) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

enum OrderStatus { pending, completed, cancelled, refunded }

class OrderStatusX {
  static OrderStatus fromJson(dynamic value) {
    if (value == null) return OrderStatus.pending;

    // Backend uses integer values by default.
    if (value is num) return _fromInt(value.toInt());
    if (value is String) {
      final trimmed = value.trim();
      final parsedInt = int.tryParse(trimmed);
      if (parsedInt != null) return _fromInt(parsedInt);

      switch (trimmed.toLowerCase()) {
        case 'pending':
          return OrderStatus.pending;
        case 'completed':
          return OrderStatus.completed;
        case 'cancelled':
          return OrderStatus.cancelled;
        case 'refunded':
          return OrderStatus.refunded;
      }
    }

    return OrderStatus.pending;
  }

  static OrderStatus _fromInt(int value) {
    switch (value) {
      case 1:
        return OrderStatus.pending;
      case 2:
        return OrderStatus.completed;
      case 3:
        return OrderStatus.cancelled;
      case 4:
        return OrderStatus.refunded;
      default:
        return OrderStatus.pending;
    }
  }
}

class MyOrdersResponse {
  final int totalCount;
  final int totalPages;
  final int currentPage;
  final int pageSize;
  final List<OrderDto> orders;

  const MyOrdersResponse({
    required this.totalCount,
    required this.totalPages,
    required this.currentPage,
    required this.pageSize,
    required this.orders,
  });

  factory MyOrdersResponse.fromJson(Map<String, dynamic> json) {
    // Backend uses pagination object with keys:
    // { Data: [...], TotalCount, PageNumber, PageSize, TotalPages }
    final dataListRaw = (json['Data'] ?? json['data']);
    final ordersList = (dataListRaw is List ? dataListRaw : const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(OrderDto.fromJson)
        .toList();

    int parseInt(dynamic v, int defaultValue) {
      if (v == null) return defaultValue;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? defaultValue;
      return defaultValue;
    }

    return MyOrdersResponse(
      totalCount: parseInt(json['TotalCount'] ?? json['totalCount'], 0),
      totalPages: parseInt(json['TotalPages'] ?? json['totalPages'], 0),
      currentPage: parseInt(json['PageNumber'] ?? json['pageNumber'], 1),
      pageSize: parseInt(json['PageSize'] ?? json['pageSize'], 10),
      orders: ordersList,
    );
  }
}

