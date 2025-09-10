import 'package:json_annotation/json_annotation.dart';

part 'render_response.g.dart';

@JsonSerializable()
class RenderResponse {
  @JsonKey(name: 'signed_url')
  final String signedUrl;
  @JsonKey(name: 'expires_at')
  final DateTime expiresAt;

  const RenderResponse({
    required this.signedUrl,
    required this.expiresAt,
  });

  factory RenderResponse.fromJson(Map<String, dynamic> json) => _$RenderResponseFromJson(json);
  Map<String, dynamic> toJson() => _$RenderResponseToJson(this);

  RenderResponse copyWith({
    String? signedUrl,
    DateTime? expiresAt,
  }) {
    return RenderResponse(
      signedUrl: signedUrl ?? this.signedUrl,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RenderResponse &&
        other.signedUrl == signedUrl &&
        other.expiresAt == expiresAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      signedUrl,
      expiresAt,
    );
  }

  @override
  String toString() {
    return 'RenderResponse(signedUrl: $signedUrl, expiresAt: $expiresAt)';
  }
}