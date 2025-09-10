import 'package:json_annotation/json_annotation.dart';

part 'auth_result.g.dart';

@JsonSerializable()
class AuthResult {
  @JsonKey(name: 'access_token')
  final String accessToken;
  @JsonKey(name: 'refresh_token')
  final String refreshToken;
  @JsonKey(name: 'expires_in')
  final int expiresIn;
  @JsonKey(name: 'token_type')
  final String tokenType;

  const AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.tokenType,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) => _$AuthResultFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResultToJson(this);

  AuthResult copyWith({
    String? accessToken,
    String? refreshToken,
    int? expiresIn,
    String? tokenType,
  }) {
    return AuthResult(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresIn: expiresIn ?? this.expiresIn,
      tokenType: tokenType ?? this.tokenType,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthResult &&
        other.accessToken == accessToken &&
        other.refreshToken == refreshToken &&
        other.expiresIn == expiresIn &&
        other.tokenType == tokenType;
  }

  @override
  int get hashCode {
    return Object.hash(
      accessToken,
      refreshToken,
      expiresIn,
      tokenType,
    );
  }

  @override
  String toString() {
    return 'AuthResult(accessToken: $accessToken, refreshToken: $refreshToken, expiresIn: $expiresIn, tokenType: $tokenType)';
  }
}