import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  final _nameController = TextEditingController(text: 'System Administrator');
  final _emailController = TextEditingController(text: 'admin@university.edu');
  final _phoneController = TextEditingController(text: '+1 (555) 000-0000');
  final _departmentController = TextEditingController(text: 'IT & Systems');

  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _savingProfile = false;
  bool _savingPassword = false;

  static const _activities = [
    (
      icon: Icons.person_add_rounded,
      color: AppColors.primary,
      label: 'Activated user Sarah Mitchell',
      time: '2 hours ago'
    ),
    (
      icon: Icons.manage_accounts_rounded,
      color: AppColors.violet,
      label: 'Changed role: James Carter → Instructor',
      time: '5 hours ago'
    ),
    (
      icon: Icons.block_rounded,
      color: AppColors.rose,
      label: 'Deactivated user Tom Bradley',
      time: 'Yesterday'
    ),
    (
      icon: Icons.backup_rounded,
      color: AppColors.emerald,
      label: 'Database backup completed',
      time: '2 days ago'
    ),
    (
      icon: Icons.settings_rounded,
      color: AppColors.amber,
      label: 'Updated platform settings',
      time: '3 days ago'
    ),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _savingProfile = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _savingProfile = false);
    _showSnackBar('Profile updated successfully');
  }

  Future<void> _savePassword() async {
    if (_newPassController.text != _confirmPassController.text) {
      _showSnackBar('Passwords do not match', isError: true);
      return;
    }
    if (_newPassController.text.isEmpty) {
      _showSnackBar('New password cannot be empty', isError: true);
      return;
    }
    setState(() => _savingPassword = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _savingPassword = false);
    _currentPassController.clear();
    _newPassController.clear();
    _confirmPassController.clear();
    _showSnackBar('Password changed successfully');
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('My Profile', style: AppTextStyles.h3),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
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
                        _buildProfileCard(),
                        const SizedBox(height: 20),
                        _buildActivitySection(),
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
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  _buildProfileCard(),
                  const SizedBox(height: 20),
                  _buildEditForm(),
                  const SizedBox(height: 20),
                  _buildPasswordSection(),
                  const SizedBox(height: 20),
                  _buildActivitySection(),
                ],
              ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3), width: 2),
                ),
                child: const Icon(Icons.admin_panel_settings_rounded,
                    color: Colors.white, size: 36),
              ),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.rose,
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: const Color(0xFF0F172A), width: 2),
                ),
                child: const Icon(Icons.verified_rounded,
                    size: 10, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('System Administrator',
              style: AppTextStyles.h3.copyWith(color: Colors.white)),
          const SizedBox(height: 4),
          Text('admin@university.edu',
              style: AppTextStyles.caption
                  .copyWith(color: Colors.white.withValues(alpha: 0.7))),
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.rose.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(100),
              border:
                  Border.all(color: AppColors.rose.withValues(alpha: 0.4)),
            ),
            child: Text('SUPER ADMIN',
                style: AppTextStyles.overline.copyWith(
                    color: AppColors.rose, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                _StatItem(
                    label: 'Actions',
                    value: '248',
                    icon: Icons.bolt_rounded),
                Container(
                    width: 1,
                    height: 32,
                    color: Colors.white.withValues(alpha: 0.1)),
                _StatItem(
                    label: 'Users',
                    value: '1,284',
                    icon: Icons.people_rounded),
                Container(
                    width: 1,
                    height: 32,
                    color: Colors.white.withValues(alpha: 0.1)),
                _StatItem(
                    label: 'Days Active',
                    value: '312',
                    icon: Icons.calendar_today_rounded),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    children: [
                      Text('Joined',
                          style: AppTextStyles.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.5))),
                      const SizedBox(height: 2),
                      Text('Mar 2023',
                          style: AppTextStyles.label
                              .copyWith(color: Colors.white)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    children: [
                      Text('Last Active',
                          style: AppTextStyles.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.5))),
                      const SizedBox(height: 2),
                      Text('Today',
                          style: AppTextStyles.label
                              .copyWith(color: AppColors.emerald)),
                    ],
                  ),
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
            hint: 'System Administrator',
          ),
          const SizedBox(height: 14),
          _FormField(
            label: 'Email Address',
            controller: _emailController,
            hint: 'admin@university.edu',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          _FormField(
            label: 'Phone Number',
            controller: _phoneController,
            hint: '+1 (555) 000-0000',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 14),
          _FormField(
            label: 'Department',
            controller: _departmentController,
            hint: 'IT & Systems',
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
                    borderRadius:
                        BorderRadius.circular(AppConstants.buttonRadius)),
              ),
              child: _savingProfile
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text('Save Changes',
                      style:
                          AppTextStyles.label.copyWith(color: Colors.white)),
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
            onToggle: () =>
                setState(() => _obscureCurrent = !_obscureCurrent),
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
            onToggle: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
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
                    borderRadius:
                        BorderRadius.circular(AppConstants.buttonRadius)),
              ),
              child: _savingPassword
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text('Update Password',
                      style:
                          AppTextStyles.label.copyWith(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySection() {
    return _Card(
      title: 'Recent Activity',
      icon: Icons.history_rounded,
      iconColor: AppColors.emerald,
      iconBg: AppColors.emeraldLight,
      child: Column(
        children: List.generate(_activities.length, (i) {
          final a = _activities[i];
          final isLast = i == _activities.length - 1;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: a.color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(a.icon, size: 14, color: a.color),
                  ),
                  if (!isLast)
                    Container(width: 1, height: 28, color: AppColors.border),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.label,
                          style: AppTextStyles.bodySmall
                              .copyWith(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(a.time,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textMuted)),
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

class _StatItem extends StatelessWidget {
  final String label, value;
  final IconData icon;

  const _StatItem(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: AppTextStyles.h3.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 10)),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor, iconBg;
  final Widget child;

  const _Card({
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

class _FormField extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final TextInputType keyboardType;

  const _FormField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType = TextInputType.text,
  });

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
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ],
    );
  }
}

class _PasswordField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.label,
    required this.controller,
    required this.obscure,
    required this.onToggle,
  });

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
            hintText: '••••••••',
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                  obscure
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  size: 18,
                  color: AppColors.textMuted),
              onPressed: onToggle,
            ),
          ),
        ),
      ],
    );
  }
}
