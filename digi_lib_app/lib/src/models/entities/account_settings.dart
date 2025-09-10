import 'package:json_annotation/json_annotation.dart';

part 'account_settings.g.dart';

/// Account and security settings model
@JsonSerializable()
class AccountSettings {
  final ProfileSettings profile;
  final SecuritySettings security;
  final PrivacySettings privacy;
  final DataSettings data;

  const AccountSettings({
    required this.profile,
    required this.security,
    required this.privacy,
    required this.data,
  });

  factory AccountSettings.fromJson(Map<String, dynamic> json) =>
      _$AccountSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$AccountSettingsToJson(this);

  AccountSettings copyWith({
    ProfileSettings? profile,
    SecuritySettings? security,
    PrivacySettings? privacy,
    DataSettings? data,
  }) {
    return AccountSettings(
      profile: profile ?? this.profile,
      security: security ?? this.security,
      privacy: privacy ?? this.privacy,
      data: data ?? this.data,
    );
  }

  /// Default account settings
  static AccountSettings get defaultSettings => const AccountSettings(
        profile: ProfileSettings.defaultSettings,
        security: SecuritySettings.defaultSettings,
        privacy: PrivacySettings.defaultSettings,
        data: DataSettings.defaultSettings,
      );
}

/// Profile management settings
@JsonSerializable()
class ProfileSettings {
  final String displayName;
  final String email;
  final String? avatarUrl;
  final bool showProfileInSharing;
  final String preferredLanguage;
  final String timezone;

  const ProfileSettings({
    required this.displayName,
    required this.email,
    this.avatarUrl,
    required this.showProfileInSharing,
    required this.preferredLanguage,
    required this.timezone,
  });

  factory ProfileSettings.fromJson(Map<String, dynamic> json) =>
      _$ProfileSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileSettingsToJson(this);

  ProfileSettings copyWith({
    String? displayName,
    String? email,
    String? avatarUrl,
    bool? showProfileInSharing,
    String? preferredLanguage,
    String? timezone,
  }) {
    return ProfileSettings(
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      showProfileInSharing: showProfileInSharing ?? this.showProfileInSharing,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      timezone: timezone ?? this.timezone,
    );
  }

  static const ProfileSettings defaultSettings = ProfileSettings(
    displayName: '',
    email: '',
    avatarUrl: null,
    showProfileInSharing: true,
    preferredLanguage: 'en',
    timezone: 'UTC',
  );
}

/// Security settings
@JsonSerializable()
class SecuritySettings {
  final bool twoFactorEnabled;
  final bool biometricAuthEnabled;
  final int sessionTimeoutMinutes;
  final bool autoLockEnabled;
  final int autoLockMinutes;
  final bool requireAuthForSensitiveActions;
  final List<String> trustedDevices;
  final DateTime? lastPasswordChange;

  const SecuritySettings({
    required this.twoFactorEnabled,
    required this.biometricAuthEnabled,
    required this.sessionTimeoutMinutes,
    required this.autoLockEnabled,
    required this.autoLockMinutes,
    required this.requireAuthForSensitiveActions,
    required this.trustedDevices,
    this.lastPasswordChange,
  });

  factory SecuritySettings.fromJson(Map<String, dynamic> json) =>
      _$SecuritySettingsFromJson(json);

  Map<String, dynamic> toJson() => _$SecuritySettingsToJson(this);

  SecuritySettings copyWith({
    bool? twoFactorEnabled,
    bool? biometricAuthEnabled,
    int? sessionTimeoutMinutes,
    bool? autoLockEnabled,
    int? autoLockMinutes,
    bool? requireAuthForSensitiveActions,
    List<String>? trustedDevices,
    DateTime? lastPasswordChange,
  }) {
    return SecuritySettings(
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      biometricAuthEnabled: biometricAuthEnabled ?? this.biometricAuthEnabled,
      sessionTimeoutMinutes: sessionTimeoutMinutes ?? this.sessionTimeoutMinutes,
      autoLockEnabled: autoLockEnabled ?? this.autoLockEnabled,
      autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
      requireAuthForSensitiveActions:
          requireAuthForSensitiveActions ?? this.requireAuthForSensitiveActions,
      trustedDevices: trustedDevices ?? this.trustedDevices,
      lastPasswordChange: lastPasswordChange ?? this.lastPasswordChange,
    );
  }

  static const SecuritySettings defaultSettings = SecuritySettings(
    twoFactorEnabled: false,
    biometricAuthEnabled: false,
    sessionTimeoutMinutes: 60,
    autoLockEnabled: false,
    autoLockMinutes: 15,
    requireAuthForSensitiveActions: true,
    trustedDevices: [],
    lastPasswordChange: null,
  );
}

/// Privacy settings
@JsonSerializable()
class PrivacySettings {
  final bool shareUsageData;
  final bool shareCrashReports;
  final bool allowAnalytics;
  final bool showOnlineStatus;
  final bool allowContactDiscovery;
  final DataSharingLevel dataSharingLevel;
  final bool personalizedRecommendations;

  const PrivacySettings({
    required this.shareUsageData,
    required this.shareCrashReports,
    required this.allowAnalytics,
    required this.showOnlineStatus,
    required this.allowContactDiscovery,
    required this.dataSharingLevel,
    required this.personalizedRecommendations,
  });

  factory PrivacySettings.fromJson(Map<String, dynamic> json) =>
      _$PrivacySettingsFromJson(json);

  Map<String, dynamic> toJson() => _$PrivacySettingsToJson(this);

  PrivacySettings copyWith({
    bool? shareUsageData,
    bool? shareCrashReports,
    bool? allowAnalytics,
    bool? showOnlineStatus,
    bool? allowContactDiscovery,
    DataSharingLevel? dataSharingLevel,
    bool? personalizedRecommendations,
  }) {
    return PrivacySettings(
      shareUsageData: shareUsageData ?? this.shareUsageData,
      shareCrashReports: shareCrashReports ?? this.shareCrashReports,
      allowAnalytics: allowAnalytics ?? this.allowAnalytics,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      allowContactDiscovery: allowContactDiscovery ?? this.allowContactDiscovery,
      dataSharingLevel: dataSharingLevel ?? this.dataSharingLevel,
      personalizedRecommendations:
          personalizedRecommendations ?? this.personalizedRecommendations,
    );
  }

  static const PrivacySettings defaultSettings = PrivacySettings(
    shareUsageData: false,
    shareCrashReports: true,
    allowAnalytics: false,
    showOnlineStatus: true,
    allowContactDiscovery: true,
    dataSharingLevel: DataSharingLevel.minimal,
    personalizedRecommendations: false,
  );
}

/// Data management settings
@JsonSerializable()
class DataSettings {
  final bool enableDataExport;
  final ExportFormat preferredExportFormat;
  final bool includeMetadataInExport;
  final bool includeAnnotationsInExport;
  final bool autoBackupEnabled;
  final int backupRetentionDays;
  final bool deleteDataOnAccountDeletion;

  const DataSettings({
    required this.enableDataExport,
    required this.preferredExportFormat,
    required this.includeMetadataInExport,
    required this.includeAnnotationsInExport,
    required this.autoBackupEnabled,
    required this.backupRetentionDays,
    required this.deleteDataOnAccountDeletion,
  });

  factory DataSettings.fromJson(Map<String, dynamic> json) =>
      _$DataSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$DataSettingsToJson(this);

  DataSettings copyWith({
    bool? enableDataExport,
    ExportFormat? preferredExportFormat,
    bool? includeMetadataInExport,
    bool? includeAnnotationsInExport,
    bool? autoBackupEnabled,
    int? backupRetentionDays,
    bool? deleteDataOnAccountDeletion,
  }) {
    return DataSettings(
      enableDataExport: enableDataExport ?? this.enableDataExport,
      preferredExportFormat: preferredExportFormat ?? this.preferredExportFormat,
      includeMetadataInExport:
          includeMetadataInExport ?? this.includeMetadataInExport,
      includeAnnotationsInExport:
          includeAnnotationsInExport ?? this.includeAnnotationsInExport,
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      backupRetentionDays: backupRetentionDays ?? this.backupRetentionDays,
      deleteDataOnAccountDeletion:
          deleteDataOnAccountDeletion ?? this.deleteDataOnAccountDeletion,
    );
  }

  static const DataSettings defaultSettings = DataSettings(
    enableDataExport: true,
    preferredExportFormat: ExportFormat.json,
    includeMetadataInExport: true,
    includeAnnotationsInExport: true,
    autoBackupEnabled: false,
    backupRetentionDays: 30,
    deleteDataOnAccountDeletion: true,
  );
}

/// Data sharing level enumeration
enum DataSharingLevel {
  none,
  minimal,
  standard,
  full,
}

/// Export format enumeration
enum ExportFormat {
  json,
  csv,
  xml,
}