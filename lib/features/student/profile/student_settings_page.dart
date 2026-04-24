import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/profile_service.dart';

class StudentSettingsPage extends StatefulWidget {
  const StudentSettingsPage({super.key});

  @override
  State<StudentSettingsPage> createState() => _StudentSettingsPageState();
}

class _StudentSettingsPageState extends State<StudentSettingsPage> {
  late Future<UserModel> _future;
  bool _didPopulate = false;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _assignmentReminders = true;
  bool _quizReminders = true;
  bool _announcementAlerts = true;
  bool _gradeAlerts = true;
  bool _deadlineReminder24h = true;
  bool _deadlineReminder1h = false;
  bool _studyReminders = true;
  bool _compactView = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _future = ProfileService.instance.getCurrentProfile();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= AppConstants.mobileBreakpoint;

    return FutureBuilder<UserModel>(
      future: _future,
      builder: (context, snapshot) {
        final profile = snapshot.data;
        if (snapshot.connectionState != ConnectionState.done && profile == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (profile != null && !_didPopulate) {
          _apply(profile.preferences);
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(isWide ? 28 : 16),
          child: Column(
            children: [
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _notificationSection()),
                    const SizedBox(width: 20),
                    Expanded(child: _reminderSection()),
                  ],
                )
              else ...[
                _notificationSection(),
                const SizedBox(height: 20),
                _reminderSection(),
              ],
              const SizedBox(height: 20),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _appearanceSection()),
                    const SizedBox(width: 20),
                    Expanded(child: _accountSection()),
                  ],
                )
              else ...[
                _appearanceSection(),
                const SizedBox(height: 20),
                _accountSection(),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Settings'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _apply(Map<String, dynamic> prefs) {
    _didPopulate = true;
    _emailNotifications = prefs['email_notifications'] as bool? ?? true;
    _pushNotifications = prefs['push_notifications'] as bool? ?? true;
    _assignmentReminders = prefs['assignment_reminders'] as bool? ?? true;
    _quizReminders = prefs['quiz_reminders'] as bool? ?? true;
    _announcementAlerts = prefs['announcement_alerts'] as bool? ?? true;
    _gradeAlerts = prefs['grade_alerts'] as bool? ?? true;
    _deadlineReminder24h = prefs['deadline_reminder_24h'] as bool? ?? true;
    _deadlineReminder1h = prefs['deadline_reminder_1h'] as bool? ?? false;
    _studyReminders = prefs['study_reminders'] as bool? ?? true;
    _compactView = prefs['compact_view'] as bool? ?? false;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ProfileService.instance.updatePreferences({
      'email_notifications': _emailNotifications,
      'push_notifications': _pushNotifications,
      'assignment_reminders': _assignmentReminders,
      'quiz_reminders': _quizReminders,
      'announcement_alerts': _announcementAlerts,
      'grade_alerts': _gradeAlerts,
      'deadline_reminder_24h': _deadlineReminder24h,
      'deadline_reminder_1h': _deadlineReminder1h,
      'study_reminders': _studyReminders,
      'compact_view': _compactView,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved.')),
    );
  }

  Widget _notificationSection() => _SettingsSection(
        title: 'Notification Preferences',
        children: [
          _toggle('Email Notifications', _emailNotifications,
              (value) => setState(() => _emailNotifications = value)),
          _toggle('Push Notifications', _pushNotifications,
              (value) => setState(() => _pushNotifications = value)),
          _toggle('Assignment Alerts', _assignmentReminders,
              (value) => setState(() => _assignmentReminders = value)),
          _toggle('Quiz Alerts', _quizReminders,
              (value) => setState(() => _quizReminders = value)),
          _toggle('Announcement Alerts', _announcementAlerts,
              (value) => setState(() => _announcementAlerts = value)),
          _toggle('Grade Alerts', _gradeAlerts,
              (value) => setState(() => _gradeAlerts = value)),
        ],
      );

  Widget _reminderSection() => _SettingsSection(
        title: 'Reminder Preferences',
        children: [
          _toggle('24-hour Deadline Reminder', _deadlineReminder24h,
              (value) => setState(() => _deadlineReminder24h = value)),
          _toggle('1-hour Deadline Reminder', _deadlineReminder1h,
              (value) => setState(() => _deadlineReminder1h = value)),
          _toggle('Study Reminders', _studyReminders,
              (value) => setState(() => _studyReminders = value)),
        ],
      );

  Widget _appearanceSection() => _SettingsSection(
        title: 'Appearance',
        children: [
          _toggle('Compact View', _compactView,
              (value) => setState(() => _compactView = value)),
        ],
      );

  Widget _accountSection() => _SettingsSection(
        title: 'Account',
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.logout_rounded, color: AppColors.error),
            title: const Text('Sign Out'),
            onTap: () async => AuthService.instance.logout(),
          ),
        ],
      );

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: AppTextStyles.label),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

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
          Text(title, style: AppTextStyles.h3),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
