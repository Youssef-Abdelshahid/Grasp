import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../routing/app_router.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isLogin = true;
  String _selectedRole = 'Student';
  static const _roles = ['Student', 'Instructor', 'Admin'];
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= AppConstants.mobileBreakpoint;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          if (isWide) _buildSidePanel(),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 48 : 24,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: _buildForm(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidePanel() {
    return Expanded(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.sidebarBg, Color(0xFF312E81)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.school_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    AppConstants.appName,
                    style: AppTextStyles.h3.copyWith(color: Colors.white),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                'Unlock the power\nof AI learning',
                style: AppTextStyles.displayMedium
                    .copyWith(color: Colors.white, height: 1.25),
              ),
              const SizedBox(height: 16),
              Text(
                'Join thousands of students and instructors using AI to transform education.',
                style: AppTextStyles.bodyLarge
                    .copyWith(color: AppColors.sidebarText),
              ),
              const SizedBox(height: 40),
              ...[
                (Icons.check_circle_rounded, 'Generate quizzes with one click'),
                (Icons.check_circle_rounded, 'Smart flashcard creation'),
                (Icons.check_circle_rounded, 'Progress tracking dashboard'),
              ].map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(item.$1,
                            color: AppColors.emerald, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          item.$2,
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.sidebarText),
                        ),
                      ],
                    ),
                  )),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Row(
            children: [
              const Icon(Icons.arrow_back_rounded,
                  size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text('Back', style: AppTextStyles.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Text(
          _isLogin ? 'Welcome back' : 'Create your account',
          style: AppTextStyles.displayMedium,
        ),
        const SizedBox(height: 8),
        Text(
          _isLogin
              ? 'Sign in to continue your learning journey'
              : 'Start your AI-powered learning journey today',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 32),
        _buildToggle(),
        const SizedBox(height: 28),
        _buildRoleSelector(),
        const SizedBox(height: 20),
        if (!_isLogin) ...[
          _buildField(
            controller: _nameController,
            label: 'Full Name',
            hint: 'Dr. Ahmed Ali',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 16),
        ],
        _buildField(
          controller: _emailController,
          label: 'Email Address',
          hint: 'name@university.edu',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _buildPasswordField(
          controller: _passwordController,
          label: 'Password',
          obscure: _obscurePassword,
          onToggle: () =>
              setState(() => _obscurePassword = !_obscurePassword),
        ),
        if (!_isLogin) ...[
          const SizedBox(height: 16),
          _buildPasswordField(
            controller: _confirmController,
            label: 'Confirm Password',
            obscure: _obscureConfirm,
            onToggle: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ],
        if (_isLogin) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: const Text('Forgot password?'),
            ),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _onSubmit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(_isLogin ? 'Sign In' : 'Create Account'),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isLogin
                  ? "Don't have an account? "
                  : 'Already have an account? ',
              style: AppTextStyles.bodySmall,
            ),
            GestureDetector(
              onTap: () => setState(() => _isLogin = !_isLogin),
              child: Text(
                _isLogin ? 'Sign up' : 'Sign in',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: ['Sign In', 'Register'].map((label) {
          final isActive = (label == 'Sign In') == _isLogin;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isLogin = label == 'Sign In'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: isActive
                      ? [
                          const BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          )
                        ]
                      : null,
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.label.copyWith(
                    color: isActive
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: isActive
                        ? FontWeight.w600
                        : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('I am a', style: AppTextStyles.label),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _roles.map((role) {
            final isSelected = _selectedRole == role;
            final isAdmin = role == 'Admin';
            final activeColor =
                isAdmin ? AppColors.rose : AppColors.primary;
            final activeBg =
                isAdmin ? AppColors.roseLight : AppColors.primaryLight;
            final icon = role == 'Student'
                ? Icons.school_outlined
                : role == 'Instructor'
                    ? Icons.person_outline_rounded
                    : Icons.admin_panel_settings_outlined;
            return GestureDetector(
              onTap: () => setState(() => _selectedRole = role),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    vertical: 10, horizontal: 14),
                decoration: BoxDecoration(
                  color: isSelected ? activeBg : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? activeColor : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      color: isSelected
                          ? activeColor
                          : AppColors.textSecondary,
                      size: 17,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      role,
                      style: AppTextStyles.label.copyWith(
                        color: isSelected
                            ? activeColor
                            : AppColors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outline_rounded,
                size: 18, color: AppColors.textMuted),
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
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

  void _onSubmit() {
    final String route;
    if (_selectedRole == 'Student') {
      route = AppRouter.studentDashboard;
    } else if (_selectedRole == 'Admin') {
      route = AppRouter.adminDashboard;
    } else {
      route = AppRouter.dashboard;
    }
    Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
  }
}
