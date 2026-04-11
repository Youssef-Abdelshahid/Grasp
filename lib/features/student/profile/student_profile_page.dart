import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  final _nameController = TextEditingController(text: 'Ahmed Hassan');
  final _emailController = TextEditingController(text: 'ahmed.hassan@student.university.edu');
  final _studentIdController = TextEditingController(text: 'STU-2022-0142');
  final _programController = TextEditingController(text: 'B.Sc. Computer Science');
  final _yearController = TextEditingController(text: 'Year 3 · Semester 6');

  bool _savingProfile = false;

  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _savingPassword = false;

  static const _activities = [
    (
      icon: Icons.assignment_turned_in_rounded,
      color: AppColors.emerald,
      label: 'Submitted Assignment: Modern UI design',
      time: '2 hours ago'
    ),
    (
      icon: Icons.quiz_rounded,
      color: AppColors.amber,
      label: 'Completed Quiz: Dart basics',
      time: '5 hours ago'
    ),
    (
      icon: Icons.local_activity_rounded,
      color: AppColors.cyan,
      label: 'Earned "Fast Learner" badge',
      time: 'Yesterday'
    ),
    (
      icon: Icons.menu_book_rounded,
      color: AppColors.primary,
      label: 'Enrolled in Mobile Dev',
      time: '2 days ago'
    ),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _studentIdController.dispose();
    _programController.dispose();
    _yearController.dispose();
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
          colors: [AppColors.cyan, Color(0xFF0891B2)],
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
                child: Center(
                  child: Text(
                    'AH',
                    style: AppTextStyles.h2.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: AppColors.cyan, width: 2),
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    size: 10, color: AppColors.cyan),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Ahmed Hassan',
              style: AppTextStyles.h2.copyWith(color: Colors.white)),
          const SizedBox(height: 4),
          Text('ahmed.hassan@student.university.edu',
              style: AppTextStyles.caption
                  .copyWith(color: Colors.white.withValues(alpha: 0.7))),
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(100),
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.4)),
            ),
            child: Text('STUDENT',
                style: AppTextStyles.overline.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w700)),
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
                    label: 'Courses',
                    value: '5',
                    icon: Icons.menu_book_rounded),
                Container(
                    width: 1,
                    height: 32,
                    color: Colors.white.withValues(alpha: 0.1)),
                _StatItem(
                    label: 'Avg Score',
                    value: '78%',
                    icon: Icons.analytics_rounded),
                Container(
                    width: 1,
                    height: 32,
                    color: Colors.white.withValues(alpha: 0.1)),
                _StatItem(
                    label: 'Badges',
                    value: '12',
                    icon: Icons.military_tech_rounded),
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
                      Text('Sep 2022',
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
                              .copyWith(color: Colors.white)),
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
    return _Section(
      title: 'Edit Profile',
      icon: Icons.edit_rounded,
      iconColor: AppColors.cyan,
      iconBg: AppColors.cyanLight,
      child: Column(
        children: [
          _FormField(
            label: 'Full Name',
            controller: _nameController,
            hint: 'Ahmed Hassan',
          ),
          const SizedBox(height: 14),
          _FormField(
            label: 'Email Address',
            controller: _emailController,
            hint: 'ahmed.hassan@student.university.edu',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          _FormField(
            label: 'Student ID',
            controller: _studentIdController,
            hint: 'STU-2022-0142',
          ),
          const SizedBox(height: 14),
          _FormField(
            label: 'Program',
            controller: _programController,
            hint: 'B.Sc. Computer Science',
          ),
          const SizedBox(height: 14),
          _FormField(
            label: 'Year',
            controller: _yearController,
            hint: 'Year 3 · Semester 6',
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _savingProfile ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
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
    return _Section(
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
    return _Section(
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
