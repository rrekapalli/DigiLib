import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/account_settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/entities/account_settings.dart';
import '../../widgets/settings_section.dart';
import '../../widgets/settings_tile.dart';
import '../../widgets/profile_edit_dialog.dart';
import '../../widgets/change_password_dialog.dart';
import '../../widgets/two_factor_setup_dialog.dart';
import '../../widgets/trusted_devices_dialog.dart';
import '../../widgets/session_timeout_dialog.dart';
import '../../widgets/data_sharing_dialog.dart';
import '../../widgets/export_data_dialog.dart';
import '../../widgets/delete_account_dialog.dart';

/// Account and security settings screen
class AccountSecurityScreen extends ConsumerWidget {
  const AccountSecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountSettings = ref.watch(accountSettingsProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account & Security'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Section
          SettingsSection(
            title: 'Profile',
            icon: Icons.person,
            children: [
              SettingsTile(
                title: 'Display Name',
                subtitle: user?.name ?? (accountSettings.profile.displayName.isEmpty 
                    ? 'Not set' 
                    : accountSettings.profile.displayName),
                leading: const Icon(Icons.badge),
                onTap: () => _showProfileEditDialog(context, ref),
              ),
              SettingsTile(
                title: 'Email',
                subtitle: user?.email ?? accountSettings.profile.email,
                leading: const Icon(Icons.email),
                onTap: () => _showProfileEditDialog(context, ref),
              ),
              SettingsTile(
                title: 'Language',
                subtitle: _getLanguageName(accountSettings.profile.preferredLanguage),
                leading: const Icon(Icons.language),
                onTap: () => _showLanguageDialog(context, ref),
              ),
              SettingsTile(
                title: 'Timezone',
                subtitle: accountSettings.profile.timezone,
                leading: const Icon(Icons.schedule),
                onTap: () => _showTimezoneDialog(context, ref),
              ),
              SettingsTile(
                title: 'Show Profile in Sharing',
                subtitle: 'Allow others to see your profile when sharing',
                leading: const Icon(Icons.visibility),
                trailing: Switch(
                  value: accountSettings.profile.showProfileInSharing,
                  onChanged: (value) => _updateShowProfileInSharing(ref, value),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Security Section
          SettingsSection(
            title: 'Security',
            icon: Icons.security,
            children: [
              SettingsTile(
                title: 'Change Password',
                subtitle: accountSettings.security.lastPasswordChange != null
                    ? 'Last changed ${_formatDate(accountSettings.security.lastPasswordChange!)}'
                    : 'Never changed',
                leading: const Icon(Icons.lock),
                onTap: () => _showChangePasswordDialog(context, ref),
              ),
              SettingsTile(
                title: 'Two-Factor Authentication',
                subtitle: accountSettings.security.twoFactorEnabled
                    ? 'Enabled'
                    : 'Disabled',
                leading: const Icon(Icons.verified_user),
                trailing: Switch(
                  value: accountSettings.security.twoFactorEnabled,
                  onChanged: (value) => _toggleTwoFactor(context, ref, value),
                ),
              ),
              SettingsTile(
                title: 'Biometric Authentication',
                subtitle: 'Use fingerprint or face unlock',
                leading: const Icon(Icons.fingerprint),
                trailing: Switch(
                  value: accountSettings.security.biometricAuthEnabled,
                  onChanged: (value) => _updateBiometricAuth(ref, value),
                ),
              ),
              SettingsTile(
                title: 'Session Timeout',
                subtitle: '${accountSettings.security.sessionTimeoutMinutes} minutes',
                leading: const Icon(Icons.timer),
                onTap: () => _showSessionTimeoutDialog(context, ref),
              ),
              SettingsTile(
                title: 'Auto Lock',
                subtitle: accountSettings.security.autoLockEnabled
                    ? '${accountSettings.security.autoLockMinutes} minutes'
                    : 'Disabled',
                leading: const Icon(Icons.lock_clock),
                trailing: Switch(
                  value: accountSettings.security.autoLockEnabled,
                  onChanged: (value) => _updateAutoLock(ref, value),
                ),
              ),
              SettingsTile(
                title: 'Trusted Devices',
                subtitle: '${accountSettings.security.trustedDevices.length} devices',
                leading: const Icon(Icons.devices),
                onTap: () => _showTrustedDevicesDialog(context, ref),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Privacy Section
          SettingsSection(
            title: 'Privacy',
            icon: Icons.privacy_tip,
            children: [
              SettingsTile(
                title: 'Data Sharing Level',
                subtitle: _getDataSharingLevelText(accountSettings.privacy.dataSharingLevel),
                leading: const Icon(Icons.share),
                onTap: () => _showDataSharingDialog(context, ref),
              ),
              SettingsTile(
                title: 'Usage Analytics',
                subtitle: 'Help improve the app by sharing usage data',
                leading: const Icon(Icons.analytics),
                trailing: Switch(
                  value: accountSettings.privacy.allowAnalytics,
                  onChanged: (value) => _updateAllowAnalytics(ref, value),
                ),
              ),
              SettingsTile(
                title: 'Crash Reports',
                subtitle: 'Automatically send crash reports',
                leading: const Icon(Icons.bug_report),
                trailing: Switch(
                  value: accountSettings.privacy.shareCrashReports,
                  onChanged: (value) => _updateShareCrashReports(ref, value),
                ),
              ),
              SettingsTile(
                title: 'Show Online Status',
                subtitle: 'Let others see when you\'re online',
                leading: const Icon(Icons.circle),
                trailing: Switch(
                  value: accountSettings.privacy.showOnlineStatus,
                  onChanged: (value) => _updateShowOnlineStatus(ref, value),
                ),
              ),
              SettingsTile(
                title: 'Contact Discovery',
                subtitle: 'Allow others to find you by email',
                leading: const Icon(Icons.contacts),
                trailing: Switch(
                  value: accountSettings.privacy.allowContactDiscovery,
                  onChanged: (value) => _updateAllowContactDiscovery(ref, value),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Data Management Section
          SettingsSection(
            title: 'Data Management',
            icon: Icons.storage,
            children: [
              SettingsTile(
                title: 'Export Data',
                subtitle: 'Download a copy of your data',
                leading: const Icon(Icons.download),
                onTap: () => _showExportDataDialog(context, ref),
              ),
              SettingsTile(
                title: 'Export Format',
                subtitle: accountSettings.data.preferredExportFormat.name.toUpperCase(),
                leading: const Icon(Icons.file_copy),
                onTap: () => _showExportFormatDialog(context, ref),
              ),
              SettingsTile(
                title: 'Include Metadata',
                subtitle: 'Include file metadata in exports',
                leading: const Icon(Icons.info),
                trailing: Switch(
                  value: accountSettings.data.includeMetadataInExport,
                  onChanged: (value) => _updateIncludeMetadata(ref, value),
                ),
              ),
              SettingsTile(
                title: 'Include Annotations',
                subtitle: 'Include bookmarks and comments in exports',
                leading: const Icon(Icons.note),
                trailing: Switch(
                  value: accountSettings.data.includeAnnotationsInExport,
                  onChanged: (value) => _updateIncludeAnnotations(ref, value),
                ),
              ),
              SettingsTile(
                title: 'Auto Backup',
                subtitle: accountSettings.data.autoBackupEnabled
                    ? 'Every ${accountSettings.data.backupRetentionDays} days'
                    : 'Disabled',
                leading: const Icon(Icons.backup),
                trailing: Switch(
                  value: accountSettings.data.autoBackupEnabled,
                  onChanged: (value) => _updateAutoBackup(ref, value),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Danger Zone Section
          SettingsSection(
            title: 'Danger Zone',
            icon: Icons.warning,
            children: [
              SettingsTile(
                title: 'Delete Account',
                subtitle: 'Permanently delete your account and all data',
                leading: Icon(
                  Icons.delete_forever,
                  color: Theme.of(context).colorScheme.error,
                ),
                onTap: () => _showDeleteAccountDialog(context, ref),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'es':
        return 'Spanish';
      case 'fr':
        return 'French';
      case 'de':
        return 'German';
      default:
        return code.toUpperCase();
    }
  }

  String _getDataSharingLevelText(DataSharingLevel level) {
    switch (level) {
      case DataSharingLevel.none:
        return 'None';
      case DataSharingLevel.minimal:
        return 'Minimal';
      case DataSharingLevel.standard:
        return 'Standard';
      case DataSharingLevel.full:
        return 'Full';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Dialog methods
  void _showProfileEditDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => ProfileEditDialog(
        currentProfile: ref.read(accountSettingsProvider).profile,
        onProfileUpdated: (profile) => ref.read(accountSettingsProvider.notifier).updateProfileSettings(profile),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    // Implementation for language selection dialog
  }

  void _showTimezoneDialog(BuildContext context, WidgetRef ref) {
    // Implementation for timezone selection dialog
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => ChangePasswordDialog(
        onPasswordChanged: (current, newPassword) => 
            ref.read(accountSettingsProvider.notifier).changePassword(current, newPassword),
      ),
    );
  }

  void _toggleTwoFactor(BuildContext context, WidgetRef ref, bool enable) {
    if (enable) {
      showDialog(
        context: context,
        builder: (context) => TwoFactorSetupDialog(
          onSetupComplete: (code) => 
              ref.read(accountSettingsProvider.notifier).toggleTwoFactor(true, code),
        ),
      );
    } else {
      ref.read(accountSettingsProvider.notifier).toggleTwoFactor(false, null);
    }
  }

  void _showSessionTimeoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => SessionTimeoutDialog(
        currentTimeout: ref.read(accountSettingsProvider).security.sessionTimeoutMinutes,
        onTimeoutChanged: (timeout) => _updateSessionTimeout(ref, timeout),
      ),
    );
  }

  void _showTrustedDevicesDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => TrustedDevicesDialog(
        trustedDevices: ref.read(accountSettingsProvider).security.trustedDevices,
        onDeviceRemoved: (deviceId) => 
            ref.read(accountSettingsProvider.notifier).removeTrustedDevice(deviceId),
      ),
    );
  }

  void _showDataSharingDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => DataSharingDialog(
        currentLevel: ref.read(accountSettingsProvider).privacy.dataSharingLevel,
        onLevelChanged: (level) => _updateDataSharingLevel(ref, level),
      ),
    );
  }

  void _showExportDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => ExportDataDialog(
        onExport: () => ref.read(accountSettingsProvider.notifier).exportUserData(),
      ),
    );
  }

  void _showExportFormatDialog(BuildContext context, WidgetRef ref) {
    // Implementation for export format selection dialog
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => DeleteAccountDialog(
        onAccountDeleted: (password) => 
            ref.read(accountSettingsProvider.notifier).deleteAccount(password),
      ),
    );
  }

  // Update methods
  void _updateShowProfileInSharing(WidgetRef ref, bool value) {
    final currentProfile = ref.read(accountSettingsProvider).profile;
    final updatedProfile = currentProfile.copyWith(showProfileInSharing: value);
    ref.read(accountSettingsProvider.notifier).updateProfileSettings(updatedProfile);
  }

  void _updateBiometricAuth(WidgetRef ref, bool value) {
    final currentSecurity = ref.read(accountSettingsProvider).security;
    final updatedSecurity = currentSecurity.copyWith(biometricAuthEnabled: value);
    ref.read(accountSettingsProvider.notifier).updateSecuritySettings(updatedSecurity);
  }

  void _updateAutoLock(WidgetRef ref, bool value) {
    final currentSecurity = ref.read(accountSettingsProvider).security;
    final updatedSecurity = currentSecurity.copyWith(autoLockEnabled: value);
    ref.read(accountSettingsProvider.notifier).updateSecuritySettings(updatedSecurity);
  }

  void _updateSessionTimeout(WidgetRef ref, int timeout) {
    final currentSecurity = ref.read(accountSettingsProvider).security;
    final updatedSecurity = currentSecurity.copyWith(sessionTimeoutMinutes: timeout);
    ref.read(accountSettingsProvider.notifier).updateSecuritySettings(updatedSecurity);
  }

  void _updateAllowAnalytics(WidgetRef ref, bool value) {
    final currentPrivacy = ref.read(accountSettingsProvider).privacy;
    final updatedPrivacy = currentPrivacy.copyWith(allowAnalytics: value);
    ref.read(accountSettingsProvider.notifier).updatePrivacySettings(updatedPrivacy);
  }

  void _updateShareCrashReports(WidgetRef ref, bool value) {
    final currentPrivacy = ref.read(accountSettingsProvider).privacy;
    final updatedPrivacy = currentPrivacy.copyWith(shareCrashReports: value);
    ref.read(accountSettingsProvider.notifier).updatePrivacySettings(updatedPrivacy);
  }

  void _updateShowOnlineStatus(WidgetRef ref, bool value) {
    final currentPrivacy = ref.read(accountSettingsProvider).privacy;
    final updatedPrivacy = currentPrivacy.copyWith(showOnlineStatus: value);
    ref.read(accountSettingsProvider.notifier).updatePrivacySettings(updatedPrivacy);
  }

  void _updateAllowContactDiscovery(WidgetRef ref, bool value) {
    final currentPrivacy = ref.read(accountSettingsProvider).privacy;
    final updatedPrivacy = currentPrivacy.copyWith(allowContactDiscovery: value);
    ref.read(accountSettingsProvider.notifier).updatePrivacySettings(updatedPrivacy);
  }

  void _updateDataSharingLevel(WidgetRef ref, DataSharingLevel level) {
    final currentPrivacy = ref.read(accountSettingsProvider).privacy;
    final updatedPrivacy = currentPrivacy.copyWith(dataSharingLevel: level);
    ref.read(accountSettingsProvider.notifier).updatePrivacySettings(updatedPrivacy);
  }

  void _updateIncludeMetadata(WidgetRef ref, bool value) {
    final currentData = ref.read(accountSettingsProvider).data;
    final updatedData = currentData.copyWith(includeMetadataInExport: value);
    ref.read(accountSettingsProvider.notifier).updateDataSettings(updatedData);
  }

  void _updateIncludeAnnotations(WidgetRef ref, bool value) {
    final currentData = ref.read(accountSettingsProvider).data;
    final updatedData = currentData.copyWith(includeAnnotationsInExport: value);
    ref.read(accountSettingsProvider.notifier).updateDataSettings(updatedData);
  }

  void _updateAutoBackup(WidgetRef ref, bool value) {
    final currentData = ref.read(accountSettingsProvider).data;
    final updatedData = currentData.copyWith(autoBackupEnabled: value);
    ref.read(accountSettingsProvider.notifier).updateDataSettings(updatedData);
  }
}