// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'share.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Share _$ShareFromJson(Map<String, dynamic> json) => Share(
      id: json['id'] as String,
      subjectId: json['subject_id'] as String,
      subjectType: $enumDecode(_$ShareSubjectTypeEnumMap, json['subject_type']),
      ownerId: json['owner_id'] as String,
      granteeEmail: json['grantee_email'] as String?,
      permission: $enumDecode(_$SharePermissionEnumMap, json['permission']),
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$ShareToJson(Share instance) => <String, dynamic>{
      'id': instance.id,
      'subject_id': instance.subjectId,
      'subject_type': _$ShareSubjectTypeEnumMap[instance.subjectType]!,
      'owner_id': instance.ownerId,
      'grantee_email': instance.granteeEmail,
      'permission': _$SharePermissionEnumMap[instance.permission]!,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$ShareSubjectTypeEnumMap = {
  ShareSubjectType.document: 'document',
  ShareSubjectType.folder: 'folder',
};

const _$SharePermissionEnumMap = {
  SharePermission.view: 'view',
  SharePermission.comment: 'comment',
  SharePermission.full: 'full',
};
