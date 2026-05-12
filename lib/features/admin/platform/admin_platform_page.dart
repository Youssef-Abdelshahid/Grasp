import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/platform_settings/providers/platform_settings_provider.dart';
import '../../../models/platform_settings_model.dart';
import '../../../widgets/auth/logout_flow.dart';

class AdminPlatformPage extends ConsumerStatefulWidget {
  const AdminPlatformPage({super.key});

  @override
  ConsumerState<AdminPlatformPage> createState() => _AdminPlatformPageState();
}

class _AdminPlatformPageState extends ConsumerState<AdminPlatformPage> {
  final _platformNameController = TextEditingController(text: 'Grasp');

  bool _landingPageRegistration = true;
  bool _requireStrongPasswords = true;
  bool _allowPasswordChange = true;
  bool _adminUserCreationEnabled = true;
  bool _preventDeletingLastAdmin = true;
  bool _adminNotifications = true;
  bool _newUserNotifications = true;
  bool _courseActivityNotifications = true;
  bool _aiFailureNotifications = true;
  bool _requireReloginAfterPasswordChange = true;
  bool _autoLogoutInactiveUsers = true;
  String _dashboardTimeRange = 'Last 30 days';
  String _defaultListSorting = 'Newest first';
  String _timeoutDuration = '30 min';

  bool _syncedInitialValues = false;
  bool _isSaving = false;
  bool _isResetting = false;
  bool _isForcingLogout = false;

  @override
  void dispose() {
    _platformNameController.dispose();
    super.dispose();
  }

  void _syncFromSettings(PlatformSettingsConfig settings) {
    _platformNameController.text = settings.platformName;
    _landingPageRegistration = settings.landingPageRegistration;
    _dashboardTimeRange = PlatformDashboardRanges.label(
      settings.defaultDashboardTimeRange,
    );
    _defaultListSorting = PlatformListSorting.label(settings.defaultListSorting);
    _requireStrongPasswords = settings.requireStrongPasswords;
    _allowPasswordChange = settings.allowPasswordChange;
    _adminUserCreationEnabled = settings.adminUserCreationEnabled;
    _preventDeletingLastAdmin = settings.preventDeletingLastAdmin;
    _adminNotifications = settings.adminNotifications;
    _newUserNotifications = settings.newUserNotifications;
    _courseActivityNotifications = settings.courseActivityNotifications;
    _aiFailureNotifications = settings.aiGenerationFailureNotifications;
    _requireReloginAfterPasswordChange =
        settings.requireReloginAfterPasswordChange;
    _autoLogoutInactiveUsers = settings.autoLogoutInactiveUsers;
    _timeoutDuration = PlatformTimeoutDurations.label(
      settings.timeoutDurationMinutes,
    );
  }

  PlatformSettingsConfig _currentConfig() {
    return PlatformSettingsConfig(
      platformName: _platformNameController.text.trim(),
      landingPageRegistration: _landingPageRegistration,
      defaultDashboardTimeRange: PlatformDashboardRanges.fromLabel(
        _dashboardTimeRange,
      ),
      defaultListSorting: PlatformListSorting.fromLabel(_defaultListSorting),
      requireStrongPasswords: _requireStrongPasswords,
      allowPasswordChange: _allowPasswordChange,
      adminUserCreationEnabled: _adminUserCreationEnabled,
      preventDeletingLastAdmin: _preventDeletingLastAdmin,
      adminNotifications: _adminNotifications,
      newUserNotifications: _newUserNotifications,
      courseActivityNotifications: _courseActivityNotifications,
      aiGenerationFailureNotifications: _aiFailureNotifications,
      requireReloginAfterPasswordChange: _requireReloginAfterPasswordChange,
      autoLogoutInactiveUsers: _autoLogoutInactiveUsers,
      timeoutDurationMinutes: PlatformTimeoutDurations.fromLabel(
        _timeoutDuration,
      ),
    );
  }

  Future<void> _saveSettings() async {
    final config = _currentConfig();
    if (config.platformName.trim().isEmpty) {
      _showSnackBar('Platform name is required.', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final saved = await ref
          .read(adminPlatformSettingsProvider.notifier)
          .save(config);
      if (!mounted) return;
      setState(() {
        _syncFromSettings(saved);
        _isSaving = false;
      });
      _showSnackBar('Platform settings saved.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnackBar(error.toString(), isError: true);
    }
  }

  Future<void> _resetSettings() async {
    setState(() => _isResetting = true);
    try {
      final reset = await ref
          .read(adminPlatformSettingsProvider.notifier)
          .reset();
      if (!mounted) return;
      setState(() {
        _syncFromSettings(reset);
        _isResetting = false;
      });
      _showSnackBar('Platform settings reset to defaults.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _isResetting = false);
      _showSnackBar(error.toString(), isError: true);
    }
  }

  Future<void> _confirmForceLogoutAllUsers() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Force Logout All Users'),
        content: Text(
          'All active sessions will be marked invalid. Everyone, including you, will need to sign in again.',
          style: AppTextStyles.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _forceLogoutAllUsers();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _forceLogoutAllUsers() async {
    setState(() => _isForcingLogout = true);
    try {
      await ref
          .read(adminPlatformSettingsProvider.notifier)
          .forceLogoutAllUsers();
      if (!mounted) return;
      _showSnackBar('All sessions were invalidated. Please sign in again.');
      if (!mounted) return;
      logoutAndReturnToAuthGate(context, ref);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isForcingLogout = false);
      _showSnackBar(error.toString(), isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(adminPlatformSettingsProvider);
    final loadedSettings = settingsAsync.valueOrNull;
    if (!_syncedInitialValues && loadedSettings != null) {
      _syncedInitialValues = true;
      _syncFromSettings(loadedSettings);
    }

    final width = MediaQuery.of(context).size.width;
    final isWide = width >= AppConstants.mobileBreakpoint;

    if (settingsAsync.isLoading && loadedSettings == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (settingsAsync.hasError && !_syncedInitialValues) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text('Unable to load platform settings', style: AppTextStyles.h3),
              const SizedBox(height: 6),
              Text(
                settingsAsync.error.toString(),
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(adminPlatformSettingsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isWide ? 28 : 16),
      child: Column(
        children: [
          _buildSaveBar(),
          const SizedBox(height: 20),
          isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          _buildPlatformSettings(),
                          const SizedBox(height: 20),
                          _buildSecuritySettings(),
                          const SizedBox(height: 20),
                          _buildNotificationSettings(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(flex: 2, child: _buildDangerZone()),
                  ],
                )
              : Column(
                  children: [
                    _buildPlatformSettings(),
                    const SizedBox(height: 20),
                    _buildSecuritySettings(),
                    const SizedBox(height: 20),
                    _buildNotificationSettings(),
                    const SizedBox(height: 20),
                    _buildDangerZone(),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildSaveBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Platform settings are saved platform-wide and applied across auth, branding, sessions, and admin user controls.',
              style: AppTextStyles.bodySmall,
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: (_isSaving || _isResetting) ? null : _resetSettings,
            icon: _isResetting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.restore_rounded, size: 16),
            label: const Text('Reset'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveSettings,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.save_rounded, size: 16),
            label: Text(_isSaving ? 'Saving...' : 'Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformSettings() {
    return _Section(
      title: 'Platform Settings',
      icon: Icons.settings_rounded,
      iconColor: AppColors.primary,
      iconBg: AppColors.primaryLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TextInputTile(
            label: 'Platform Name',
            description: 'Display name shown in the app header/sidebar',
            controller: _platformNameController,
            hint: 'Grasp',
          ),
          const SizedBox(height: 14),
          _ToggleTile(
            label: 'Landing Page Registration',
            subtitle:
                'Show or hide registration access from the public landing/auth page',
            value: _landingPageRegistration,
            onChanged: (v) => setState(() => _landingPageRegistration = v),
          ),
          const SizedBox(height: 8),
          Text('Default Dashboard Time Range', style: AppTextStyles.label),
          const SizedBox(height: 3),
          Text(
            'Default time window used by dashboard summaries',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 8),
          _DropdownTile(
            value: _dashboardTimeRange,
            items: const [
              'Last 7 days',
              'Last 30 days',
              'This semester',
              'All time',
            ],
            onChanged: (v) =>
                setState(() => _dashboardTimeRange = v ?? _dashboardTimeRange),
          ),
          const SizedBox(height: 14),
          Text('Default List Sorting', style: AppTextStyles.label),
          const SizedBox(height: 3),
          Text(
            'Default ordering for admin management lists',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 8),
          _DropdownTile(
            value: _defaultListSorting,
            items: const ['Newest first', 'Oldest first', 'A-Z'],
            onChanged: (v) => setState(
              () => _defaultListSorting = v ?? _defaultListSorting,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySettings() {
    return _Section(
      title: 'Security',
      icon: Icons.security_rounded,
      iconColor: AppColors.emerald,
      iconBg: AppColors.emeraldLight,
      child: Column(
        children: [
          _ToggleTile(
            label: 'Require Strong Passwords',
            subtitle: 'Encourage stronger passwords during account creation',
            value: _requireStrongPasswords,
            onChanged: (v) => setState(() => _requireStrongPasswords = v),
          ),
          _ToggleTile(
            label: 'Allow Password Change',
            subtitle:
                'Allow users to change their password from profile/settings pages',
            value: _allowPasswordChange,
            onChanged: (v) => setState(() => _allowPasswordChange = v),
          ),
          _ToggleTile(
            label: 'Admin User Creation Enabled',
            subtitle: 'Allow admins to create users manually from the Users page',
            value: _adminUserCreationEnabled,
            onChanged: (v) => setState(() => _adminUserCreationEnabled = v),
          ),
          _ToggleTile(
            label: 'Prevent Deleting Last Admin',
            subtitle: 'Keep at least one admin account active in the platform',
            value: _preventDeletingLastAdmin,
            onChanged: (v) => setState(() => _preventDeletingLastAdmin = v),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return _Section(
      title: 'Notifications',
      icon: Icons.notifications_rounded,
      iconColor: AppColors.amber,
      iconBg: AppColors.amberLight,
      child: Column(
        children: [
          _ToggleTile(
            label: 'Admin Notifications',
            subtitle: 'Show admin notifications in the notification menu',
            value: _adminNotifications,
            onChanged: (v) => setState(() => _adminNotifications = v),
          ),
          _ToggleTile(
            label: 'New User Notifications',
            subtitle: 'Notify admins when a new user account is created',
            value: _newUserNotifications,
            onChanged: (v) => setState(() => _newUserNotifications = v),
          ),
          _ToggleTile(
            label: 'Course Activity Notifications',
            subtitle: 'Notify admins about major course changes',
            value: _courseActivityNotifications,
            onChanged: (v) => setState(() => _courseActivityNotifications = v),
          ),
          _ToggleTile(
            label: 'AI Generation Failure Notifications',
            subtitle: 'Notify admins when AI generation fails',
            value: _aiFailureNotifications,
            onChanged: (v) => setState(() => _aiFailureNotifications = v),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.warning_rounded,
                  color: AppColors.error,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Danger Zone',
                  style: AppTextStyles.h3.copyWith(color: AppColors.error),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 16),
          _ToggleTile(
            label: 'Require Re-login After Password Change',
            subtitle: 'Users must sign in again after changing their password',
            value: _requireReloginAfterPasswordChange,
            onChanged: (v) =>
                setState(() => _requireReloginAfterPasswordChange = v),
          ),
          _ToggleTile(
            label: 'Auto Logout Inactive Users',
            subtitle: 'Automatically logs users out after inactivity',
            value: _autoLogoutInactiveUsers,
            onChanged: (v) => setState(() => _autoLogoutInactiveUsers = v),
          ),
          const SizedBox(height: 8),
          Text('Timeout Duration', style: AppTextStyles.label),
          const SizedBox(height: 3),
          Text(
            'How long users can be inactive before logout',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 8),
          _DropdownTile(
            value: _timeoutDuration,
            items: const ['15 min', '30 min', '1 hour', '2 hours'],
            onChanged: (v) =>
                setState(() => _timeoutDuration = v ?? _timeoutDuration),
          ),
          const SizedBox(height: 16),
          _DangerTile(
            label: 'Force Logout All Users',
            subtitle: 'Signs out all active users from the platform',
            icon: Icons.logout_rounded,
            isLoading: _isForcingLogout,
            isDone: false,
            onTap: _confirmForceLogoutAllUsers,
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Widget child;

  const _Section({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: AppTextStyles.h3)),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _TextInputTile extends StatelessWidget {
  final String label;
  final String description;
  final TextEditingController controller;
  final String hint;

  const _TextInputTile({
    required this.label,
    required this.description,
    required this.controller,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 3),
        Text(description, style: AppTextStyles.caption),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownTile extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownTile({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          style: AppTextStyles.body,
          items: items
              .map((v) => DropdownMenuItem<String>(value: v, child: Text(v)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.label),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primaryLight,
          ),
        ],
      ),
    );
  }
}

class _DangerTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool isLoading;
  final bool isDone;
  final VoidCallback onTap;

  const _DangerTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.isLoading,
    required this.isDone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 14, color: AppColors.error),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.label.copyWith(color: AppColors.error),
                  ),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            if (isLoading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.error,
                ),
              )
            else if (isDone)
              Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: AppColors.success,
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: AppColors.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}
