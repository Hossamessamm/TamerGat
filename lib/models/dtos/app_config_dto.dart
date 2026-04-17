/// DTO for the app configuration response from /api/appconfig.
class AppConfigDto {
  final String? inReviewVersion;
  final String? forceUpdateVersion;

  AppConfigDto({this.inReviewVersion, this.forceUpdateVersion});

  factory AppConfigDto.fromJson(Map<String, dynamic> json) {
    return AppConfigDto(
      inReviewVersion: _toNullableString(json['inReviewVersion']),
      forceUpdateVersion: _toNullableString(json['ForceUpdateVersion']),
    );
  }

  static String? _toNullableString(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }
}
