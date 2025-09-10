import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/entities/account_settings.dart';
import 'secure_storage_service.dart';

/// Service for managing account and security settings
class AccountSettingsService {
  static const String _accountSettingsKey = 'account_settings';
  
  final SecureStorageService _secureStorage;
  AccountSettings _currentSettings = AccountSettings.defaultSettings;
  
  AccountSettingsService({
    required SecureStorageService secureStorage,
  }) : _secureStorage = secureStorage;

  /// Get current account settings
  AccountSettings get currentSettings => _currentSettings;

  /// Initialize account settings service and load saved settings
  Future<void> initialize() async {
    try {
      final settingsJson = await _secureStorage.read(_accountSettingsKey);
      if (settingsJson != null) {
        final settingsMap = jsonDecode(settingsJson) as Map<String, dynamic>;
        _currentSettings = AccountSettings.fromJson(settingsMap);
      }
    } catch (e) {
      debugPrint('Failed to load account settings: $e');
      // Use default settings if loading fails
      _currentSettings = AccountSettings.defaultSettings;
    }
  }

  /// Save account settings to secure storage
  Future<void> saveSettings(AccountSettings settings) async {
    try {
      _currentSettings = settings;
      final settingsJson = jsonEncode(settings.toJson());
      await _secureStorage.write(_accountSettingsKey, settingsJson);
    } catch (e) {
      debugPrint('Failed to save account settings: $e');
      rethrow;
    }
  }

  /// Update profile settings
  Future<void> updateProfileSettings(ProfileSettings profileSettings) async {
    final updatedSettings = _currentSettings.copyWith(profile: profileSettings);
    await saveSettings(updatedSettings);
  }

  /// Update security settings
  Future<void> updateSecuritySettings(SecuritySettings securitySettings) async {
    final updatedSettings = _currentSettings.copyWith(security: securitySettings);
    await saveSettings(updatedSettings);
  }

  /// Update privacy settings
  Future<void> updatePrivacySettings(PrivacySettings privacySettings) async {
    final updatedSettings = _currentSettings.copyWith(privacy: privacySettings);
    await saveSettings(updatedSettings);
  }

  /// Update data settings
  Future<void> updateDataSettings(DataSettings dataSettings) async {
    final updatedSettings = _currentSettings.copyWith(data: dataSettings);
    await saveSettings(updatedSettings);
  }

  /// Reset account settings to defaults
  Future<void> resetToDefaults() async {
    await saveSettings(AccountSettings.defaultSettings);
  }

  /// Export account settings as JSON string
  String exportSettings() {
    return jsonEncode(_currentSettings.toJson());
  }

  /// Import account settings from JSON string
  Future<void> importSettings(String settingsJson) async {
    try {
      final settingsMap = jsonDecode(settingsJson) as Map<String, dynamic>;
      final settings = AccountSettings.fromJson(settingsMap);
      await saveSettings(settings);
    } catch (e) {
      debugPrint('Failed to import account settings: $e');
      rethrow;
    }
  }

  /// Change password (placeholder for actual implementation)
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    // In real implementation, this would call the auth API
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      // Update last password change date
      final updatedSecurity = _currentSettings.security.copyWith(
        lastPasswordChange: DateTime.now(),
      );
      await updateSecuritySettings(updatedSecurity);
      
      return true;
    } catch (e) {
      debugPrint('Failed to change password: $e');
      return false;
    }
  }

  /// Enable/disable two-factor authentication
  Future<bool> toggleTwoFactor(bool enable, String? verificationCode) async {
    // In real implementation, this would call the auth API
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      final updatedSecurity = _currentSettings.security.copyWith(
        twoFactorEnabled: enable,
      );
      await updateSecuritySettings(updatedSecurity);
      
      return true;
    } catch (e) {
      debugPrint('Failed to toggle two-factor authentication: $e');
      return false;
    }
  }

  /// Add trusted device
  Future<void> addTrustedDevice(String deviceId) async {
    final trustedDevices = List<String>.from(_currentSettings.security.trustedDevices);
    if (!trustedDevices.contains(deviceId)) {
      trustedDevices.add(deviceId);
      final updatedSecurity = _currentSettings.security.copyWith(
        trustedDevices: trustedDevices,
      );
      await updateSecuritySettings(updatedSecurity);
    }
  }

  /// Remove trusted device
  Future<void> removeTrustedDevice(String deviceId) async {
    final trustedDevices = List<String>.from(_currentSettings.security.trustedDevices);
    trustedDevices.remove(deviceId);
    final updatedSecurity = _currentSettings.security.copyWith(
      trustedDevices: trustedDevices,
    );
    await updateSecuritySettings(updatedSecurity);
  }

  /// Export user data
  Future<String> exportUserData() async {
    // In real implementation, this would gather all user data
    try {
      // Simulate data export
      await Future.delayed(const Duration(seconds: 2));
      
      final exportData = {
        'profile': _currentSettings.profile.toJson(),
        'settings': _currentSettings.toJson(),
        'exportDate': DateTime.now().toIso8601String(),
        'format': _currentSettings.data.preferredExportFormat.name,
      };
      
      return jsonEncode(exportData);
    } catch (e) {
      debugPrint('Failed to export user data: $e');
      rethrow;
    }
  }

  /// Delete account and all associated data
  Future<bool> deleteAccount(String password) async {
    // In real implementation, this would call the auth API
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      if (_currentSettings.data.deleteDataOnAccountDeletion) {
        // Clear all local data
        await _secureStorage.deleteAll();
      }
      
      return true;
    } catch (e) {
      debugPrint('Failed to delete account: $e');
      return false;
    }
  }

  /// Check if session timeout is enabled
  bool get isSessionTimeoutEnabled => _currentSettings.security.sessionTimeoutMinutes > 0;

  /// Get session timeout in milliseconds
  int get sessionTimeoutMs => _currentSettings.security.sessionTimeoutMinutes * 60 * 1000;

  /// Check if auto lock is enabled
  bool get isAutoLockEnabled => _currentSettings.security.autoLockEnabled;

  /// Get auto lock timeout in milliseconds
  int get autoLockTimeoutMs => _currentSettings.security.autoLockMinutes * 60 * 1000;

  /// Check if biometric authentication is available and enabled
  bool get isBiometricAuthEnabled => _currentSettings.security.biometricAuthEnabled;

  /// Check if two-factor authentication is enabled
  bool get isTwoFactorEnabled => _currentSettings.security.twoFactorEnabled;
}