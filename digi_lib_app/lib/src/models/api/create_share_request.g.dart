// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_share_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateShareRequest _$CreateShareRequestFromJson(Map<String, dynamic> json) =>
    CreateShareRequest(
      subjectId: json['subject_id'] as String,
      subjectType: $enumDecode(_$ShareSubjectTypeEnumMap, json['subject_type']),
      granteeEmail: json['grantee_email'] as String,
      permission: $enumDecode(_$SharePermissionEnumMap, json['permission']),
    );

Map<String, dynamic> _$CreateShareRequestToJson(CreateShareRequest instance) =>
    <String, dynamic>{
      'subject_id': instance.subjectId,
      'subject_type': _$ShareSubjectTypeEnumMap[instance.subjectType]!,
      'grantee_email': instance.granteeEmail,
      'permission': _$SharePermissionEnumMap[instance.permission]!,
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
