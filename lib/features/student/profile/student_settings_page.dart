import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../routing/app_router.dart';

class StudentSettingsPage extends StatefulWidget {
  const StudentSettingsPage({super.key});

  @override
  State<StudentSettingsPage> createState() => _StudentSettingsPageState();
}

class _StudentSettingsPageState extends State<StudentSettingsPage> {
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _assignmentReminders = true;
  bool _quizReminders = true;
  bool _announcementAlerts = true;
  bool _gradeAlerts = true;
  bool _deadlineReminder24h = true;
  bool _deadlineReminder1h = false;
  bool _studyReminders = true;
  bool _darkMode = false;
  bool _compactView = false;

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
                  flex: 1,
                  child: Column(
                    children: [
                      _buildNotificationPrefs(),
                      const SizedBox(height: 20),
                      _buildReminderPrefs(),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildAppearance(),
                      const SizedBox(height: 20),
                      _buildAccountSettings(),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              children: [
                _buildNotificationPrefs(),
                const SizedBox(height: 20),
                _buildReminderPrefs(),
                const SizedBox(height: 20),
                _buildAppearance(),
                const SizedBox(height: 20),
                _buildAccountSettings(),
              ],
            ),
    );
  }

  Widget _buildNotificationPrefs() {
    return _Section(
      title: 'Notification Preferences',
      icon: Icons.notifications_rounded,
      iconColor: AppColors.amber,
      iconBg: AppColors.amberLight,
      child: Column(
        children: [
          _ToggleTile(
            label: 'Email Notifications',
            subtitle: 'Receive updates via email',
            value: _emailNotifications,
            onChanged: (v) => setState(() => _emailNotifications = v),
          ),
          _ToggleTile(
            label: 'Push Notifications',
            subtitle: 'In-app alerts and banners',
            value: _pushNotifications,
            onChanged: (v) => setState(() => _pushNotifications = v),
          ),
          _ToggleTile(
            label: 'Assignment Alerts',
            subtitle: 'New assignments and grade updates',
            value: _assignmentReminders,
            onChanged: (v) => setState(() => _assignmentReminders = v),
          ),
          _ToggleTile(
            label: 'Quiz Alerts',
            subtitle: 'When new quizzes open or results are out',
            value: _quizReminders,
            onChanged: (v) => setState(() => _quizReminders = v),
          ),
          _ToggleTile(
            label: 'Announcements',
            subtitle: 'Course announcements from instructors',
            value: _announcementAlerts,
            onChanged: (v) => setState(() => _announcementAlerts = v),
          ),
          _ToggleTile(
            label: 'Grade Alerts',
            subtitle: 'When grades are published',
            value: _gradeAlerts,
            onChanged: (v) => setState(() => _gradeAlerts = v),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderPrefs() {
    return _Section(
      title: 'Reminder Preferences',
      icon: Icons.alarm_rounded,
      iconColor: AppColors.violet,
      iconBg: AppColors.violetLight,
      child: Column(
        children: [
          _ToggleTile(
            label: '24-hour Deadline Reminder',
            subtitle: 'Remind me 1 day before assignment/quiz closes',
            value: _deadlineReminder24h,
            onChanged: (v) => setState(() => _deadlineReminder24h = v),
          ),
          _ToggleTile(
            label: '1-hour Deadline Reminder',
            subtitle: 'Remind me 1 hour before deadline',
            value: _deadlineReminder1h,
            onChanged: (v) => setState(() => _deadlineReminder1h = v),
          ),
          _ToggleTile(
            label: 'Study Reminders',
            subtitle: 'Daily study session suggestions',
            value: _studyReminders,
            onChanged: (v) => setState(() => _studyReminders = v),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearance() {
    return _Section(
      title: 'Appearance',
      icon: Icons.palette_rounded,
      iconColor: AppColors.emerald,
      iconBg: AppColors.emeraldLight,
      child: Column(
        children: [
          _ToggleTile(
            label: 'Dark Mode',
            subtitle: 'Switch to dark theme',
            value: _darkMode,
            onChanged: (v) => setState(() => _darkMode = v),
          ),
          _ToggleTile(
            label: 'Compact View',
            subtitle: 'Show more content with less spacing',
            value: _compactView,
            onChanged: (v) => setState(() => _compactView = v),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSettings() {
    return _Section(
      title: 'Account Settings',
      icon: Icons.security_rounded,
      iconColor: AppColors.primary,
      iconBg: AppColors.primaryLight,
      child: Column(
        children: [
          _ActionTile(
            icon: Icons.lock_rounded,
            label: 'Change Password',
            subtitle: 'Last changed 2 months ago',
            color: AppColors.primary,
            onTap: () {},
          ),
          const Divider(height: 1, color: AppColors.border),
          _ActionTile(
            icon: Icons.shield_rounded,
            label: 'Two-Factor Authentication',
            subtitle: 'Not enabled',
            color: AppColors.amber,
            onTap: () {},
          ),
          const Divider(height: 1, color: AppColors.border),
          _ActionTile(
            icon: Icons.bar_chart_rounded,
            label: 'Academic Progress Report',
            subtitle: 'Download your progress summary',
            color: AppColors.cyan,
            onTap: () {},
          ),
          const Divider(height: 1, color: AppColors.border),
          _ActionTile(
            icon: Icons.logout_rounded,
            label: 'Sign Out',
            subtitle: 'Sign out of your account',
            color: AppColors.error,
            onTap: () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRouter.landing,
              (_) => false,
            ),
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
                    color: iconBg, borderRadius: BorderRadius.circular(8)),
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
            activeThumbColor: AppColors.cyan,
            activeTrackColor: AppColors.cyanLight,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
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
      trailing: const Icon(Icons.chevron_right_rounded,
          size: 16, color: AppColors.textMuted),
      onTap: onTap,
    );
  }
}
