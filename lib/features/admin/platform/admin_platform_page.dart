import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/auth/logout_flow.dart';

class AdminPlatformPage extends ConsumerStatefulWidget {
  const AdminPlatformPage({super.key});

  @override
  ConsumerState<AdminPlatformPage> createState() => _AdminPlatformPageState();
}

class _AdminPlatformPageState extends ConsumerState<AdminPlatformPage> {
  bool _registrationsOpen = true;
  bool _emailVerification = true;
  bool _adminApproval = false;
  bool _maintenanceMode = false;
  bool _twoFactorAdmin = true;
  bool _sessionTimeout = true;
  bool _systemAlerts = true;
  bool _auditLogs = true;
  bool _notifyEmail = true;
  bool _notifyPush = true;
  bool _notifyNewUser = true;
  bool _notifyLowStorage = false;
  String _digestFreq = 'Weekly';

  final _loadingActions = <String>{};
  final _doneActions = <String>{};

  void _confirmAction({
    required String id,
    required String title,
    required String message,
    required String successMessage,
    bool isDangerous = false,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message, style: AppTextStyles.bodySmall),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _runAction(id, successMessage);
            },
            style: isDangerous
                ? ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                  )
                : null,
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _runAction(String id, String successMessage) async {
    setState(() => _loadingActions.add(id));
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() {
      _loadingActions.remove(id);
      _doneActions.add(id);
    });
    _showSnackBar(successMessage);
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    setState(() => _doneActions.remove(id));
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
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= AppConstants.mobileBreakpoint;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isWide ? 28 : 16),
      child: isWide
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
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildSystemActions(),
                      const SizedBox(height: 20),
                      _buildDangerZone(),
                    ],
                  ),
                ),
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
                _buildSystemActions(),
                const SizedBox(height: 20),
                _buildDangerZone(),
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
        children: [
          _ToggleTile(
            label: 'Open Registrations',
            subtitle: 'Allow new users to register on the platform',
            value: _registrationsOpen,
            onChanged: (v) => setState(() => _registrationsOpen = v),
          ),
          _ToggleTile(
            label: 'Email Verification',
            subtitle: 'Require email confirmation on sign-up',
            value: _emailVerification,
            onChanged: (v) => setState(() => _emailVerification = v),
          ),
          _ToggleTile(
            label: 'Admin Approval for Instructors',
            subtitle: 'Manually approve instructor registrations',
            value: _adminApproval,
            onChanged: (v) => setState(() => _adminApproval = v),
          ),
          _ToggleTile(
            label: 'Maintenance Mode',
            subtitle: 'Take platform offline for maintenance',
            value: _maintenanceMode,
            onChanged: (v) => setState(() => _maintenanceMode = v),
            dangerColor: true,
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
            label: 'Two-Factor for Admins',
            subtitle: 'Require 2FA for all admin accounts',
            value: _twoFactorAdmin,
            onChanged: (v) => setState(() => _twoFactorAdmin = v),
          ),
          _ToggleTile(
            label: 'Auto Session Timeout',
            subtitle: 'Sign out inactive sessions after 30 minutes',
            value: _sessionTimeout,
            onChanged: (v) => setState(() => _sessionTimeout = v),
          ),
          _ToggleTile(
            label: 'System Alerts',
            subtitle: 'Send alerts for unusual platform activity',
            value: _systemAlerts,
            onChanged: (v) => setState(() => _systemAlerts = v),
          ),
          _ToggleTile(
            label: 'Audit Logs',
            subtitle: 'Log all admin actions for compliance',
            value: _auditLogs,
            onChanged: (v) => setState(() => _auditLogs = v),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ToggleTile(
            label: 'Email Notifications',
            subtitle: 'Receive admin alerts via email',
            value: _notifyEmail,
            onChanged: (v) => setState(() => _notifyEmail = v),
          ),
          _ToggleTile(
            label: 'Push Notifications',
            subtitle: 'In-app and browser push alerts',
            value: _notifyPush,
            onChanged: (v) => setState(() => _notifyPush = v),
          ),
          _ToggleTile(
            label: 'New User Registrations',
            subtitle: 'Alert when new users sign up',
            value: _notifyNewUser,
            onChanged: (v) => setState(() => _notifyNewUser = v),
          ),
          _ToggleTile(
            label: 'Low Storage Alert',
            subtitle: 'Notify when storage drops below 20%',
            value: _notifyLowStorage,
            onChanged: (v) => setState(() => _notifyLowStorage = v),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          Text('Digest Frequency', style: AppTextStyles.label),
          const SizedBox(height: 4),
          Text(
            'How often to receive summary reports',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _digestFreq,
                isExpanded: true,
                style: AppTextStyles.body,
                items: ['Daily', 'Weekly', 'Monthly', 'Never']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _digestFreq = v ?? _digestFreq),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemActions() {
    return _Section(
      title: 'System Actions',
      icon: Icons.terminal_rounded,
      iconColor: AppColors.rose,
      iconBg: AppColors.roseLight,
      child: Column(
        children: [
          _SystemActionTile(
            id: 'backup',
            icon: Icons.backup_rounded,
            label: 'Backup Database',
            subtitle: 'Last backup: 2 hours ago',
            color: AppColors.primary,
            isLoading: _loadingActions.contains('backup'),
            isDone: _doneActions.contains('backup'),
            onTap: () => _confirmAction(
              id: 'backup',
              title: 'Backup Database',
              message:
                  'This will create a full backup of all platform data. Continue?',
              successMessage: 'Backup completed successfully',
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          _SystemActionTile(
            id: 'export',
            icon: Icons.bar_chart_rounded,
            label: 'Export Reports',
            subtitle: 'Download platform usage reports',
            color: AppColors.violet,
            isLoading: _loadingActions.contains('export'),
            isDone: _doneActions.contains('export'),
            onTap: () => _confirmAction(
              id: 'export',
              title: 'Export Reports',
              message:
                  'Generate and download a full usage report for this month?',
              successMessage: 'Report export started — check your email',
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          _SystemActionTile(
            id: 'cache',
            icon: Icons.cleaning_services_rounded,
            label: 'Clear Cache',
            subtitle: 'Free up system cache memory',
            color: AppColors.amber,
            isLoading: _loadingActions.contains('cache'),
            isDone: _doneActions.contains('cache'),
            onTap: () => _confirmAction(
              id: 'cache',
              title: 'Clear Cache',
              message:
                  'Clear all system and user session caches? Active sessions may be affected.',
              successMessage: 'Cache cleared successfully',
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          _SystemActionTile(
            id: 'restart',
            icon: Icons.restart_alt_rounded,
            label: 'Restart Services',
            subtitle: 'Restart background services',
            color: AppColors.error,
            isLoading: _loadingActions.contains('restart'),
            isDone: _doneActions.contains('restart'),
            onTap: () => _confirmAction(
              id: 'restart',
              title: 'Restart Services',
              message:
                  'Restarting will briefly interrupt service for all users. Proceed?',
              successMessage: 'Services restarted successfully',
              isDangerous: true,
            ),
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
                child: const Icon(
                  Icons.warning_rounded,
                  color: AppColors.error,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Danger Zone',
                style: AppTextStyles.h3.copyWith(color: AppColors.error),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 16),
          _DangerTile(
            label: 'Reset All User Passwords',
            subtitle: 'Force all users to reset their passwords on next login',
            icon: Icons.lock_reset_rounded,
            onTap: () => _confirmAction(
              id: 'reset_passwords',
              title: 'Reset All Passwords',
              message:
                  'This will force all users to reset their password. This cannot be undone.',
              successMessage: 'Password reset emails sent to all users',
              isDangerous: true,
            ),
          ),
          const SizedBox(height: 10),
          _DangerTile(
            label: 'Purge All Session Data',
            subtitle: 'Sign out every active user on the platform',
            icon: Icons.logout_rounded,
            onTap: () => _confirmAction(
              id: 'purge_sessions',
              title: 'Purge Sessions',
              message:
                  'This will immediately sign out all active users. Proceed?',
              successMessage: 'All sessions purged successfully',
              isDangerous: true,
            ),
          ),
          const SizedBox(height: 10),
          _DangerTile(
            label: 'Logout & Return to Landing',
            subtitle: 'End your admin session',
            icon: Icons.exit_to_app_rounded,
            onTap: () => logoutAndReturnToAuthGate(context, ref),
          ),
        ],
      ),
    );
  }
}

class _DangerTile extends StatelessWidget {
  final String label, subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _DangerTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
            const Icon(
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

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor, iconBg;
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
              Text(title, style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String label, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool dangerColor;

  const _ToggleTile({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.dangerColor = false,
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
                Text(
                  label,
                  style: AppTextStyles.label.copyWith(
                    color: dangerColor && value
                        ? AppColors.error
                        : AppColors.textPrimary,
                  ),
                ),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: dangerColor ? AppColors.error : AppColors.primary,
            activeTrackColor: dangerColor
                ? AppColors.errorLight
                : AppColors.primaryLight,
          ),
        ],
      ),
    );
  }
}

class _SystemActionTile extends StatelessWidget {
  final String id, label, subtitle;
  final IconData icon;
  final Color color;
  final bool isLoading, isDone;
  final VoidCallback onTap;

  const _SystemActionTile({
    required this.id,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.isLoading,
    required this.isDone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
      title: Text(label, style: AppTextStyles.label),
      subtitle: Text(subtitle, style: AppTextStyles.caption),
      trailing: isLoading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          : isDone
          ? const Icon(
              Icons.check_circle_rounded,
              size: 18,
              color: AppColors.success,
            )
          : const Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: AppColors.textMuted,
            ),
      onTap: isLoading ? null : onTap,
    );
  }
}
