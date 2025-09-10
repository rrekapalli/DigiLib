// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_share_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateShareRequest _$UpdateShareRequestFromJson(Map<String, dynamic> json) =>
    UpdateShareRequest(
      permission: $enumDecode(_$SharePermissionEnumMap, json['permission']),
    );

Map<String, dynamic> _$UpdateShareRequestToJson(UpdateShareRequest instance) =>
    <String, dynamic>{
      'permission': _$SharePermissionEnumMap[instance.permission]!,
    };

const _$SharePermissionEnumMap = {
  SharePermission.view: 'view',
  SharePermission.comment: 'comment',
  SharePermission.full: 'full',
};
