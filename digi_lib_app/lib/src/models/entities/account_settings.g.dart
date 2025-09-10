// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccountSettings _$AccountSettingsFromJson(Map<String, dynamic> json) =>
    AccountSettings(
      profile:
          ProfileSettings.fromJson(json['profile'] as Map<String, dynamic>),
      security:
          SecuritySettings.fromJson(json['security'] as Map<String, dynamic>),
      privacy:
          PrivacySettings.fromJson(json['privacy'] as Map<String, dynamic>),
      data: DataSettings.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AccountSettingsToJson(AccountSettings instance) =>
    <String, dynamic>{
      'profile': instance.profile,
      'security': instance.security,
      'privacy': instance.privacy,
      'data': instance.data,
    };

ProfileSettings _$ProfileSettingsFromJson(Map<String, dynamic> json) =>
    ProfileSettings(
      displayName: json['displayName'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      showProfileInSharing: json['showProfileInSharing'] as bool,
      preferredLanguage: json['preferredLanguage'] as String,
      timezone: json['timezone'] as String,
    );

Map<String, dynamic> _$ProfileSettingsToJson(ProfileSettings instance) =>
    <String, dynamic>{
      'displayName': instance.displayName,
      'email': instance.email,
      'avatarUrl': instance.avatarUrl,
      'showProfileInSharing': instance.showProfileInSharing,
      'preferredLanguage': instance.preferredLanguage,
      'timezone': instance.timezone,
    };

SecuritySettings _$SecuritySettingsFromJson(Map<String, dynamic> json) =>
    SecuritySettings(
      twoFactorEnabled: json['twoFactorEnabled'] as bool,
      biometricAuthEnabled: json['biometricAuthEnabled'] as bool,
      sessionTimeoutMinutes: (json['sessionTimeoutMinutes'] as num).toInt(),
      autoLockEnabled: json['autoLockEnabled'] as bool,
      autoLockMinutes: (json['autoLockMinutes'] as num).toInt(),
      requireAuthForSensitiveActions:
          json['requireAuthForSensitiveActions'] as bool,
      trustedDevices: (json['trustedDevices'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      lastPasswordChange: json['lastPasswordChange'] == null
          ? null
          : DateTime.parse(json['lastPasswordChange'] as String),
    );

Map<String, dynamic> _$SecuritySettingsToJson(SecuritySettings instance) =>
    <String, dynamic>{
      'twoFactorEnabled': instance.twoFactorEnabled,
      'biometricAuthEnabled': instance.biometricAuthEnabled,
      'sessionTimeoutMinutes': instance.sessionTimeoutMinutes,
      'autoLockEnabled': instance.autoLockEnabled,
      'autoLockMinutes': instance.autoLockMinutes,
      'requireAuthForSensitiveActions': instance.requireAuthForSensitiveActions,
      'trustedDevices': instance.trustedDevices,
      'lastPasswordChange': instance.lastPasswordChange?.toIso8601String(),
    };

PrivacySettings _$PrivacySettingsFromJson(Map<String, dynamic> json) =>
    PrivacySettings(
      shareUsageData: json['shareUsageData'] as bool,
      shareCrashReports: json['shareCrashReports'] as bool,
      allowAnalytics: json['allowAnalytics'] as bool,
      showOnlineStatus: json['showOnlineStatus'] as bool,
      allowContactDiscovery: json['allowContactDiscovery'] as bool,
      dataSharingLevel:
          $enumDecode(_$DataSharingLevelEnumMap, json['dataSharingLevel']),
      personalizedRecommendations: json['personalizedRecommendations'] as bool,
    );

Map<String, dynamic> _$PrivacySettingsToJson(PrivacySettings instance) =>
    <String, dynamic>{
      'shareUsageData': instance.shareUsageData,
      'shareCrashReports': instance.shareCrashReports,
      'allowAnalytics': instance.allowAnalytics,
      'showOnlineStatus': instance.showOnlineStatus,
      'allowContactDiscovery': instance.allowContactDiscovery,
      'dataSharingLevel': _$DataSharingLevelEnumMap[instance.dataSharingLevel]!,
      'personalizedRecommendations': instance.personalizedRecommendations,
    };

const _$DataSharingLevelEnumMap = {
  DataSharingLevel.none: 'none',
  DataSharingLevel.minimal: 'minimal',
  DataSharingLevel.standard: 'standard',
  DataSharingLevel.full: 'full',
};

DataSettings _$DataSettingsFromJson(Map<String, dynamic> json) => DataSettings(
      enableDataExport: json['enableDataExport'] as bool,
      preferredExportFormat:
          $enumDecode(_$ExportFormatEnumMap, json['preferredExportFormat']),
      includeMetadataInExport: json['includeMetadataInExport'] as bool,
      includeAnnotationsInExport: json['includeAnnotationsInExport'] as bool,
      autoBackupEnabled: json['autoBackupEnabled'] as bool,
      backupRetentionDays: (json['backupRetentionDays'] as num).toInt(),
      deleteDataOnAccountDeletion: json['deleteDataOnAccountDeletion'] as bool,
    );

Map<String, dynamic> _$DataSettingsToJson(DataSettings instance) =>
    <String, dynamic>{
      'enableDataExport': instance.enableDataExport,
      'preferredExportFormat':
          _$ExportFormatEnumMap[instance.preferredExportFormat]!,
      'includeMetadataInExport': instance.includeMetadataInExport,
      'includeAnnotationsInExport': instance.includeAnnotationsInExport,
      'autoBackupEnabled': instance.autoBackupEnabled,
      'backupRetentionDays': instance.backupRetentionDays,
      'deleteDataOnAccountDeletion': instance.deleteDataOnAccountDeletion,
    };

const _$ExportFormatEnumMap = {
  ExportFormat.json: 'json',
  ExportFormat.csv: 'csv',
  ExportFormat.xml: 'xml',
};
