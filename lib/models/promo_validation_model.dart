/// Promo validation response model matching BackendIbrahim `ValidatePromoCodeResponseDto`.
class PromoValidationResponse {
  final bool isValid;
  final String? errorMessage;

  final double originalPrice;
  final double discountAmount;
  final double netPrice;

  final String? promoCodeDetails;

  const PromoValidationResponse({
    required this.isValid,
    this.errorMessage,
    required this.originalPrice,
    required this.discountAmount,
    required this.netPrice,
    this.promoCodeDetails,
  });

  factory PromoValidationResponse.fromJson(Map<String, dynamic> json) {
    return PromoValidationResponse(
      isValid: (json['IsValid'] ?? json['isValid'] ?? false) == true,
      errorMessage: json['ErrorMessage']?.toString() ?? json['errorMessage']?.toString(),
      originalPrice: _toDouble(json['OriginalPrice'] ?? json['originalPrice'], defaultValue: 0),
      discountAmount: _toDouble(json['DiscountAmount'] ?? json['discountAmount'], defaultValue: 0),
      netPrice: _toDouble(json['NetPrice'] ?? json['netPrice'], defaultValue: 0),
      promoCodeDetails: json['PromoCodeDetails']?.toString() ?? json['promoCodeDetails']?.toString(),
    );
  }

  static double _toDouble(dynamic value, {required double defaultValue}) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }
}

