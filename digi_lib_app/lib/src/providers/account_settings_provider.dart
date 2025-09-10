import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/entities/account_settings.dart';
import '../services/account_settings_service.dart';
import '../services/secure_storage_service.dart';

/// Provider for secure storage service
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

/// Provider for account settings service
final accountSettingsServiceProvider = Provider<AccountSettingsService>((ref) {
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return AccountSettingsService(secureStorage: secureStorage);
});

/// Provider for account settings state
final accountSettingsProvider = StateNotifierProvider<AccountSettingsNotifier, AccountSettings>((ref) {
  final accountSettingsService = ref.watch(accountSettingsServiceProvider);
  return AccountSettingsNotifier(accountSettingsService);
});

/// Account settings state notifier
class AccountSettingsNotifier extends StateNotifier<AccountSettings> {
  final AccountSettingsService _accountSettingsService;

  AccountSettingsNotifier(this._accountSettingsService) : super(AccountSettings.defaultSettings) {
    _initialize();
  }

  /// Initialize account settings
  Future<void> _initialize() async {
    await _accountSettingsService.initialize();
    state = _accountSettingsService.currentSettings;
  }

  /// Update profile settings
  Future<void> updateProfileSettings(ProfileSettings profileSettings) async {
    await _accountSettingsService.updateProfileSettings(profileSettings);
    state = _accountSettingsService.currentSettings;
  }

  /// Update security settings
  Future<void> updateSecuritySettings(SecuritySettings securitySettings) async {
    await _accountSettingsService.updateSecuritySettings(securitySettings);
    state = _accountSettingsService.currentSettings;
  }

  /// Update privacy settings
  Future<void> updatePrivacySettings(PrivacySettings privacySettings) async {
    await _accountSettingsService.updatePrivacySettings(privacySettings);
    state = _accountSettingsService.currentSettings;
  }

  /// Update data settings
  Future<void> updateDataSettings(DataSettings dataSettings) async {
    await _accountSettingsService.updateDataSettings(dataSettings);
    state = _accountSettingsService.currentSettings;
  }

  /// Reset to default settings
  Future<void> resetToDefaults() async {
    await _accountSettingsService.resetToDefaults();
    state = _accountSettingsService.currentSettings;
  }

  /// Export settings
  String exportSettings() {
    return _accountSettingsService.exportSettings();
  }

  /// Import settings
  Future<void> importSettings(String settingsJson) async {
    await _accountSettingsService.importSettings(settingsJson);
    state = _accountSettingsService.currentSettings;
  }

  /// Change password
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    final success = await _accountSettingsService.changePassword(currentPassword, newPassword);
    if (success) {
      state = _accountSettingsService.currentSettings;
    }
    return success;
  }

  /// Toggle two-factor authentication
  Future<bool> toggleTwoFactor(bool enable, String? verificationCode) async {
    final success = await _accountSettingsService.toggleTwoFactor(enable, verificationCode);
    if (success) {
      state = _accountSettingsService.currentSettings;
    }
    return success;
  }

  /// Add trusted device
  Future<void> addTrustedDevice(String deviceId) async {
    await _accountSettingsService.addTrustedDevice(deviceId);
    state = _accountSettingsService.currentSettings;
  }

  /// Remove trusted device
  Future<void> removeTrustedDevice(String deviceId) async {
    await _accountSettingsService.removeTrustedDevice(deviceId);
    state = _accountSettingsService.currentSettings;
  }

  /// Export user data
  Future<String> exportUserData() async {
    return await _accountSettingsService.exportUserData();
  }

  /// Delete account
  Future<bool> deleteAccount(String password) async {
    return await _accountSettingsService.deleteAccount(password);
  }
}

/// Provider for profile settings
final profileSettingsProvider = Provider<ProfileSettings>((ref) {
  final accountSettings = ref.watch(accountSettingsProvider);
  return accountSettings.profile;
});

/// Provider for security settings
final securitySettingsProvider = Provider<SecuritySettings>((ref) {
  final accountSettings = ref.watch(accountSettingsProvider);
  return accountSettings.security;
});

/// Provider for privacy settings
final privacySettingsProvider = Provider<PrivacySettings>((ref) {
  final accountSettings = ref.watch(accountSettingsProvider);
  return accountSettings.privacy;
});

/// Provider for data settings
final dataSettingsProvider = Provider<DataSettings>((ref) {
  final accountSettings = ref.watch(accountSettingsProvider);
  return accountSettings.data;
});