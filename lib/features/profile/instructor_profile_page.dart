import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/app_role.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/file_utils.dart';
import '../../models/dashboard_models.dart';
import '../../models/notification_model.dart';
import '../../models/user_model.dart';
import '../../services/dashboard_service.dart';
import '../../services/notification_service.dart';
import '../../services/profile_service.dart';

class InstructorProfilePage extends StatefulWidget {
  const InstructorProfilePage({super.key});

  @override
  State<InstructorProfilePage> createState() => _InstructorProfilePageState();
}

class _InstructorProfilePageState extends State<InstructorProfilePage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _departmentController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _bioController = TextEditingController();

  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _savingProfile = false;
  bool _savingPassword = false;
  bool _didPopulate = false;

  late Future<_InstructorProfileData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _departmentController.dispose();
    _employeeIdController.dispose();
    _bioController.dispose();
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= AppConstants.mobileBreakpoint;

    return FutureBuilder<_InstructorProfileData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done &&
            !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data;
        if (data == null) {
          return const Scaffold(
            body: Center(child: Text('Unable to load profile.')),
          );
        }

        if (!_didPopulate) {
          _didPopulate = true;
          _nameController.text = data.profile.name;
          _emailController.text = data.profile.email;
          _departmentController.text = data.profile.department;
          _employeeIdController.text = data.profile.employeeId;
          _bioController.text = data.profile.bio;
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            title: Text('My Profile', style: AppTextStyles.h3),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: AppColors.border),
            ),
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(isWide ? 28 : 16),
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _InstructorHeader(
                              profile: data.profile,
                              summary: data.summary,
                              onUploadAvatar: _uploadAvatar,
                            ),
                            const SizedBox(height: 20),
                            _RecentActivity(notifications: data.notifications),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            _InstructorProfileForm(
                              nameController: _nameController,
                              emailController: _emailController,
                              departmentController: _departmentController,
                              employeeIdController: _employeeIdController,
                              bioController: _bioController,
                              isSaving: _savingProfile,
                              onSave: _saveProfile,
                            ),
                            const SizedBox(height: 20),
                            _InstructorPasswordForm(
                              currentController: _currentPassController,
                              newController: _newPassController,
                              confirmController: _confirmPassController,
                              obscureCurrent: _obscureCurrent,
                              obscureNew: _obscureNew,
                              obscureConfirm: _obscureConfirm,
                              isSaving: _savingPassword,
                              onToggleCurrent: () => setState(
                                () => _obscureCurrent = !_obscureCurrent,
                              ),
                              onToggleNew: () =>
                                  setState(() => _obscureNew = !_obscureNew),
                              onToggleConfirm: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                              onSave: _savePassword,
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _InstructorHeader(
                        profile: data.profile,
                        summary: data.summary,
                        onUploadAvatar: _uploadAvatar,
                      ),
                      const SizedBox(height: 20),
                      _InstructorProfileForm(
                        nameController: _nameController,
                        emailController: _emailController,
                        departmentController: _departmentController,
                        employeeIdController: _employeeIdController,
                        bioController: _bioController,
                        isSaving: _savingProfile,
                        onSave: _saveProfile,
                      ),
                      const SizedBox(height: 20),
                      _InstructorPasswordForm(
                        currentController: _currentPassController,
                        newController: _newPassController,
                        confirmController: _confirmPassController,
                        obscureCurrent: _obscureCurrent,
                        obscureNew: _obscureNew,
                        obscureConfirm: _obscureConfirm,
                        isSaving: _savingPassword,
                        onToggleCurrent: () =>
                            setState(() => _obscureCurrent = !_obscureCurrent),
                        onToggleNew: () =>
                            setState(() => _obscureNew = !_obscureNew),
                        onToggleConfirm: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                        onSave: _savePassword,
                      ),
                      const SizedBox(height: 20),
                      _RecentActivity(notifications: data.notifications),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Future<_InstructorProfileData> _load() async {
    final profile = await ProfileService.instance.getCurrentProfile();
    final summary = await DashboardService.instance.getInstructorSummary();
    final notifications = await NotificationService.instance.getNotifications();
    return _InstructorProfileData(
      profile: profile,
      summary: summary,
      notifications: notifications.take(5).toList(),
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _savingProfile = true);
    try {
      await ProfileService.instance.updateProfile(
        role: AppRole.instructor,
        fullName: _nameController.text,
        email: _emailController.text,
        department: _departmentController.text,
        employeeId: _employeeIdController.text,
        bio: _bioController.text,
      );
      _showMessage('Profile updated successfully.');
      _refresh();
    } on AuthException catch (error) {
      _showMessage(error.message, isError: true);
    } on PostgrestException catch (error) {
      _showMessage(error.message, isError: true);
    } finally {
      if (mounted) {
        setState(() => _savingProfile = false);
      }
    }
  }

  Future<void> _savePassword() async {
    if (_newPassController.text != _confirmPassController.text) {
      _showMessage('Passwords do not match.', isError: true);
      return;
    }
    if (_newPassController.text.trim().length < 6) {
      _showMessage('Password must be at least 6 characters.', isError: true);
      return;
    }

    setState(() => _savingPassword = true);
    try {
      await ProfileService.instance.updatePassword(
        _newPassController.text.trim(),
      );
      _currentPassController.clear();
      _newPassController.clear();
      _confirmPassController.clear();
      _showMessage('Password updated successfully.');
    } on AuthException catch (error) {
      _showMessage(error.message, isError: true);
    } finally {
      if (mounted) {
        setState(() => _savingPassword = false);
      }
    }
  }

  Future<void> _uploadAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }

    try {
      await ProfileService.instance.uploadAvatar(result.files.single);
      _showMessage('Profile image updated.');
      _refresh();
    } on ProfileException catch (error) {
      _showMessage(error.message, isError: true);
    }
  }

  void _refresh() {
    setState(() {
      _didPopulate = false;
      _future = _load();
    });
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }
}

class _InstructorProfileData {
  const _InstructorProfileData({
    required this.profile,
    required this.summary,
    required this.notifications,
  });

  final UserModel profile;
  final InstructorDashboardSummary summary;
  final List<NotificationModel> notifications;
}

class _InstructorHeader extends StatelessWidget {
  const _InstructorHeader({
    required this.profile,
    required this.summary,
    required this.onUploadAvatar,
  });

  final UserModel profile;
  final InstructorDashboardSummary summary;
  final VoidCallback onUploadAvatar;

  @override
  Widget build(BuildContext context) {
    final initials = profile.name.isEmpty
        ? 'IN'
        : profile.name
              .split(' ')
              .take(2)
              .map((part) => part.isEmpty ? '' : part[0].toUpperCase())
              .join();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF6366F1)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                backgroundImage: profile.avatarUrl == null
                    ? null
                    : NetworkImage(profile.avatarUrl!),
                child: profile.avatarUrl == null
                    ? Text(
                        initials,
                        style: AppTextStyles.h2.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : null,
              ),
              IconButton(
                onPressed: onUploadAvatar,
                icon: const Icon(Icons.camera_alt_rounded, size: 16),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            profile.name,
            style: AppTextStyles.h2.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            profile.email,
            style: AppTextStyles.caption.copyWith(color: Colors.white70),
          ),
          if (profile.department.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              profile.department,
              style: AppTextStyles.caption.copyWith(color: Colors.white70),
            ),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              'INSTRUCTOR',
              style: AppTextStyles.overline.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _HeaderStat(label: 'Courses', value: '${summary.coursesCount}'),
              _HeaderStat(label: 'Students', value: '${summary.studentsCount}'),
              _HeaderStat(
                label: 'Avg Score',
                value: '${summary.averageScore.toStringAsFixed(0)}%',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.h3.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _InstructorProfileForm extends StatelessWidget {
  const _InstructorProfileForm({
    required this.nameController,
    required this.emailController,
    required this.departmentController,
    required this.employeeIdController,
    required this.bioController,
    required this.isSaving,
    required this.onSave,
  });

  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController departmentController;
  final TextEditingController employeeIdController;
  final TextEditingController bioController;
  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Edit Profile',
      icon: Icons.edit_rounded,
      iconColor: AppColors.primary,
      child: Column(
        children: [
          _Field(label: 'Full Name', controller: nameController),
          const SizedBox(height: 14),
          _Field(
            label: 'Email Address',
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          _Field(label: 'Department', controller: departmentController),
          const SizedBox(height: 14),
          _Field(label: 'Employee ID', controller: employeeIdController),
          const SizedBox(height: 14),
          _Field(label: 'Bio', controller: bioController, maxLines: 4),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSaving ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructorPasswordForm extends StatelessWidget {
  const _InstructorPasswordForm({
    required this.currentController,
    required this.newController,
    required this.confirmController,
    required this.obscureCurrent,
    required this.obscureNew,
    required this.obscureConfirm,
    required this.isSaving,
    required this.onToggleCurrent,
    required this.onToggleNew,
    required this.onToggleConfirm,
    required this.onSave,
  });

  final TextEditingController currentController;
  final TextEditingController newController;
  final TextEditingController confirmController;
  final bool obscureCurrent;
  final bool obscureNew;
  final bool obscureConfirm;
  final bool isSaving;
  final VoidCallback onToggleCurrent;
  final VoidCallback onToggleNew;
  final VoidCallback onToggleConfirm;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Change Password',
      icon: Icons.lock_rounded,
      iconColor: AppColors.violet,
      child: Column(
        children: [
          _PasswordField(
            label: 'Current Password',
            controller: currentController,
            obscure: obscureCurrent,
            onToggle: onToggleCurrent,
          ),
          const SizedBox(height: 14),
          _PasswordField(
            label: 'New Password',
            controller: newController,
            obscure: obscureNew,
            onToggle: onToggleNew,
          ),
          const SizedBox(height: 14),
          _PasswordField(
            label: 'Confirm New Password',
            controller: confirmController,
            obscure: obscureConfirm,
            onToggle: onToggleConfirm,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSaving ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.violet,
                foregroundColor: Colors.white,
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Update Password'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({required this.notifications});

  final List<NotificationModel> notifications;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Recent Activity',
      icon: Icons.history_rounded,
      iconColor: AppColors.emerald,
      child: notifications.isEmpty
          ? Text('No recent activity found.', style: AppTextStyles.bodySmall)
          : Column(
              children: notifications
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.brightness_1_rounded,
                            size: 10,
                            color: AppColors.emerald,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.title, style: AppTextStyles.label),
                                Text(item.body, style: AppTextStyles.bodySmall),
                                Text(
                                  FileUtils.formatDateTime(item.createdAt),
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

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
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: const InputDecoration(),
        ),
      ],
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.label,
    required this.controller,
    required this.obscure,
    required this.onToggle,
  });

  final String label;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            suffixIcon: IconButton(
              onPressed: onToggle,
              icon: Icon(
                obscure
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
