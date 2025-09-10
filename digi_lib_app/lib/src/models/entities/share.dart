import 'package:json_annotation/json_annotation.dart';

part 'share.g.dart';

enum ShareSubjectType {
  @JsonValue('document')
  document,
  @JsonValue('folder')
  folder,
}

enum SharePermission {
  @JsonValue('view')
  view,
  @JsonValue('comment')
  comment,
  @JsonValue('full')
  full,
}

@JsonSerializable()
class Share {
  final String id; // UUID
  @JsonKey(name: 'subject_id')
  final String subjectId;
  @JsonKey(name: 'subject_type')
  final ShareSubjectType subjectType;
  @JsonKey(name: 'owner_id')
  final String ownerId;
  @JsonKey(name: 'grantee_email')
  final String? granteeEmail;
  final SharePermission permission;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const Share({
    required this.id,
    required this.subjectId,
    required this.subjectType,
    required this.ownerId,
    this.granteeEmail,
    required this.permission,
    required this.createdAt,
  });

  factory Share.fromJson(Map<String, dynamic> json) => _$ShareFromJson(json);
  Map<String, dynamic> toJson() => _$ShareToJson(this);

  Share copyWith({
    String? id,
    String? subjectId,
    ShareSubjectType? subjectType,
    String? ownerId,
    String? granteeEmail,
    SharePermission? permission,
    DateTime? createdAt,
  }) {
    return Share(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      subjectType: subjectType ?? this.subjectType,
      ownerId: ownerId ?? this.ownerId,
      granteeEmail: granteeEmail ?? this.granteeEmail,
      permission: permission ?? this.permission,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Share &&
        other.id == id &&
        other.subjectId == subjectId &&
        other.subjectType == subjectType &&
        other.ownerId == ownerId &&
        other.granteeEmail == granteeEmail &&
        other.permission == permission &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      subjectId,
      subjectType,
      ownerId,
      granteeEmail,
      permission,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'Share(id: $id, subjectId: $subjectId, subjectType: $subjectType, ownerId: $ownerId, granteeEmail: $granteeEmail, permission: $permission, createdAt: $createdAt)';
  }
}