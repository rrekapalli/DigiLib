import 'package:json_annotation/json_annotation.dart';
import '../entities/share.dart';

part 'create_share_request.g.dart';

@JsonSerializable()
class CreateShareRequest {
  @JsonKey(name: 'subject_id')
  final String subjectId;
  @JsonKey(name: 'subject_type')
  final ShareSubjectType subjectType;
  @JsonKey(name: 'grantee_email')
  final String granteeEmail;
  final SharePermission permission;

  const CreateShareRequest({
    required this.subjectId,
    required this.subjectType,
    required this.granteeEmail,
    required this.permission,
  });

  factory CreateShareRequest.fromJson(Map<String, dynamic> json) => _$CreateShareRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateShareRequestToJson(this);

  CreateShareRequest copyWith({
    String? subjectId,
    ShareSubjectType? subjectType,
    String? granteeEmail,
    SharePermission? permission,
  }) {
    return CreateShareRequest(
      subjectId: subjectId ?? this.subjectId,
      subjectType: subjectType ?? this.subjectType,
      granteeEmail: granteeEmail ?? this.granteeEmail,
      permission: permission ?? this.permission,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreateShareRequest &&
        other.subjectId == subjectId &&
        other.subjectType == subjectType &&
        other.granteeEmail == granteeEmail &&
        other.permission == permission;
  }

  @override
  int get hashCode {
    return Object.hash(
      subjectId,
      subjectType,
      granteeEmail,
      permission,
    );
  }

  @override
  String toString() {
    return 'CreateShareRequest(subjectId: $subjectId, subjectType: $subjectType, granteeEmail: $granteeEmail, permission: $permission)';
  }
}