import 'package:json_annotation/json_annotation.dart';
import '../entities/share.dart';

part 'update_share_request.g.dart';

@JsonSerializable()
class UpdateShareRequest {
  final SharePermission permission;

  const UpdateShareRequest({
    required this.permission,
  });

  factory UpdateShareRequest.fromJson(Map<String, dynamic> json) => _$UpdateShareRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateShareRequestToJson(this);

  UpdateShareRequest copyWith({
    SharePermission? permission,
  }) {
    return UpdateShareRequest(
      permission: permission ?? this.permission,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UpdateShareRequest && other.permission == permission;
  }

  @override
  int get hashCode => permission.hashCode;

  @override
  String toString() => 'UpdateShareRequest(permission: $permission)';
}