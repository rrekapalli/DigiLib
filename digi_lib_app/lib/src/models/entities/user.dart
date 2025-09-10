import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String id; // UUID
  final String email;
  final String? name;
  final String? provider;
  @JsonKey(name: 'provider_id')
  final String? providerId;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    this.name,
    this.provider,
    this.providerId,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? provider,
    String? providerId,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      provider: provider ?? this.provider,
      providerId: providerId ?? this.providerId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.email == email &&
        other.name == name &&
        other.provider == provider &&
        other.providerId == providerId &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      email,
      name,
      provider,
      providerId,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, name: $name, provider: $provider, providerId: $providerId, createdAt: $createdAt)';
  }
}