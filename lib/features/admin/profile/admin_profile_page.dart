import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/user_utils.dart';
import '../../../features/theme/providers/theme_mode_provider.dart';
import '../../../models/admin_models.dart';
import '../../../models/dashboard_models.dart';
import '../../../services/admin_service.dart';

class AdminProfilePage extends ConsumerStatefulWidget {
  const AdminProfilePage({super.key});

  @override
  ConsumerState<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends ConsumerState<AdminProfilePage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _departmentController = TextEditingController();
  final _bioController = TextEditingController();

  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _savingProfile = false;
  bool _savingPassword = false;
  Future<AdminProfileData>? _profileFuture;
  AdminProfileData? _profileData;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    _bioController.dispose();
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  void _loadProfile() {
    _profileFuture = AdminService.instance.getCurrentAdminProfile();
  }

  void _syncControllers(AdminProfileData data) {
    final profile = data.profile;
    _nameController.text = profile.name;
    _emailController.text = profile.email;
    _phoneController.text = profile.phone;
    _departmentController.text = profile.department;
    _bioController.text = profile.bio;
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Full name is required', isError: true);
      return;
    }

    setState(() => _savingProfile = true);
    try {
      final updated = await AdminService.instance.updateOwnProfile(
        fullName: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        department: _departmentController.text,
        bio: _bioController.text,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _profileData = updated;
        _profileFuture = Future.value(updated);
        _savingProfile = false;
      });
      _syncControllers(updated);
      _showSnackBar('Profile updated successfully');
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _savingProfile = false);
      _showSnackBar(error.toString(), isError: true);
    }
  }

  Future<void> _savePassword() async {
    if (_currentPassController.text.trim().isEmpty) {
      _showSnackBar('Current password is required.', isError: true);
      return;
    }
    if (_newPassController.text.trim().isEmpty) {
      _showSnackBar('New password is required.', isError: true);
      return;
    }
    if (_confirmPassController.text.trim().isEmpty) {
      _showSnackBar('Confirm password is required.', isError: true);
      return;
    }
    if (_newPassController.text != _confirmPassController.text) {
      _showSnackBar('Passwords do not match.', isError: true);
      return;
    }
    if (_newPassController.text.trim().length < 6) {
      _showSnackBar('Password must be at least 6 characters.', isError: true);
      return;
    }

    setState(() => _savingPassword = true);
    try {
      await AdminService.instance.updatePassword(
        currentPassword: _currentPassController.text,
        newPassword: _newPassController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      setState(() => _savingPassword = false);
      _currentPassController.clear();
      _newPassController.clear();
      _confirmPassController.clear();
      _showSnackBar('Password updated successfully.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _savingPassword = false);
      _showSnackBar(_friendlyPasswordError(error), isError: true);
    }
  }

  String _friendlyPasswordError(Object error) {
    final message = error
        .toString()
        .replaceFirst('AdminServiceException: ', '')
        .replaceFirst('PlatformSettingsException: ', '')
        .replaceFirst('Exception: ', '');
    if (message.toLowerCase().contains('invalid login') ||
        message.toLowerCase().contains('incorrect')) {
      return 'Current password is incorrect.';
    }
    if (message.toLowerCase().contains('password')) {
      return message;
    }
    return 'Password could not be updated.';
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
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
    ref.watch(themeModeProvider);
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= AppConstants.mobileBreakpoint;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('My Profile', style: AppTextStyles.h3),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () => setState(_loadProfile),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: FutureBuilder<AdminProfileData>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done &&
              _profileData == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError && _profileData == null) {
            return _ErrorState(onRetry: () => setState(_loadProfile));
          }

          final incoming = snapshot.data;
          if (incoming != null && incoming != _profileData && !_savingProfile) {
            _profileData = incoming;
            _syncControllers(incoming);
          }

          final data = _profileData!;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isWide ? 28 : 16),
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildProfileCard(data.profile),
                            const SizedBox(height: 20),
                            _buildActivitySection(data.activity),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            _buildEditForm(),
                            const SizedBox(height: 20),
                            _buildPasswordSection(),
                            const SizedBox(height: 20),
                            const _ThemePreferenceCard(),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _buildProfileCard(data.profile),
                      const SizedBox(height: 20),
                      _buildEditForm(),
                      const SizedBox(height: 20),
                      _buildPasswordSection(),
                      const SizedBox(height: 20),
                      const _ThemePreferenceCard(),
                      const SizedBox(height: 20),
                      _buildActivitySection(data.activity),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(AdminUser profile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            child: Text(
              UserUtils.initials(profile.name),
              style: AppTextStyles.h2.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            profile.name,
            style: AppTextStyles.h3.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            profile.email,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.rose.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: AppColors.rose.withValues(alpha: 0.4)),
            ),
            child: Text(
              '${profile.roleLabel.toUpperCase()} - ${profile.statusLabel.toUpperCase()}',
              style: AppTextStyles.overline.copyWith(
                color: AppColors.rose,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                _StatItem(
                  label: 'Actions',
                  value: '${profile.adminActionsCount}',
                ),
                _Divider(),
                _StatItem(
                  label: 'Users',
                  value: '${profile.managedUsersCount}',
                ),
                _Divider(),
                _StatItem(
                  label: 'Joined',
                  value: profile.joinedLabel.split(',').first,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SmallInfo(
                  label: 'Department',
                  value: profile.department.isEmpty
                      ? 'Not set'
                      : profile.department,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SmallInfo(
                  label: 'Last Active',
                  value: profile.lastActiveLabel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return _Card(
      title: 'Edit Profile',
      icon: Icons.edit_rounded,
      iconColor: AppColors.primary,
      iconBg: AppColors.primaryLight,
      child: Column(
        children: [
          _FormField(
            label: 'Full Name',
            controller: _nameController,
            hint: 'Full name',
          ),
          const SizedBox(height: 14),
          _FormField(
            label: 'Email Address',
            controller: _emailController,
            hint: 'admin@example.com',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          _FormField(
            label: 'Phone Number',
            controller: _phoneController,
            hint: '+20 000 000 0000',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 14),
          _FormField(
            label: 'Department',
            controller: _departmentController,
            hint: 'IT & Systems',
          ),
          const SizedBox(height: 14),
          _FormField(
            label: 'Bio',
            controller: _bioController,
            hint: 'Short admin bio',
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _savingProfile ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.buttonRadius,
                  ),
                ),
              ),
              child: _savingProfile
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Save Changes',
                      style: AppTextStyles.label.copyWith(color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordSection() {
    return _Card(
      title: 'Change Password',
      icon: Icons.lock_rounded,
      iconColor: AppColors.violet,
      iconBg: AppColors.violetLight,
      child: Column(
        children: [
          _PasswordField(
            label: 'Current Password',
            controller: _currentPassController,
            obscure: _obscureCurrent,
            onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
          ),
          const SizedBox(height: 14),
          _PasswordField(
            label: 'New Password',
            controller: _newPassController,
            obscure: _obscureNew,
            onToggle: () => setState(() => _obscureNew = !_obscureNew),
          ),
          const SizedBox(height: 14),
          _PasswordField(
            label: 'Confirm New Password',
            controller: _confirmPassController,
            obscure: _obscureConfirm,
            onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _savingPassword ? null : _savePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.violet,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.buttonRadius,
                  ),
                ),
              ),
              child: _savingPassword
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Update Password',
                      style: AppTextStyles.label.copyWith(color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySection(List<DashboardActivityItem> activities) {
    return _Card(
      title: 'Recent Activity',
      icon: Icons.history_rounded,
      iconColor: AppColors.emerald,
      iconBg: AppColors.emeraldLight,
      child: activities.isEmpty
          ? Text(
              'No admin activity recorded yet.',
              style: AppTextStyles.bodySmall,
            )
          : Column(
              children: List.generate(activities.length, (i) {
                final activity = activities[i];
                final isLast = i == activities.length - 1;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.emerald.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.history_rounded,
                            size: 14,
                            color: AppColors.emerald,
                          ),
                        ),
                        if (!isLast)
                          Container(
                            width: 1,
                            height: 28,
                            color: AppColors.border,
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity.title,
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              activity.timestampLabel,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: Colors.white.withValues(alpha: 0.1),
    );
  }
}

class _ThemePreferenceCard extends ConsumerWidget {
  const _ThemePreferenceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode =
        ref.watch(themeModeProvider).valueOrNull ?? ThemeMode.light;
    final value = themeMode == ThemeMode.dark ? themeModeDark : themeModeLight;

    return _Card(
      title: 'Appearance',
      icon: Icons.dark_mode_rounded,
      iconColor: AppColors.primary,
      iconBg: AppColors.primaryLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: value,
            decoration: const InputDecoration(labelText: 'Theme'),
            items: const [
              DropdownMenuItem(value: themeModeLight, child: Text('Light')),
              DropdownMenuItem(value: themeModeDark, child: Text('Dark')),
            ],
            onChanged: (newValue) {
              if (newValue == null) return;
              ref
                  .read(themeModeProvider.notifier)
                  .setThemeMode(
                    newValue == themeModeDark
                        ? ThemeMode.dark
                        : ThemeMode.light,
                  );
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Applies immediately and is saved on this device.',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SmallInfo extends StatelessWidget {
  const _SmallInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.label.copyWith(color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
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
          Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  final String label;
  final String hint;
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
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
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
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: 'Password',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
              onPressed: onToggle,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 36),
          const SizedBox(height: 12),
          Text('Failed to load admin profile', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
