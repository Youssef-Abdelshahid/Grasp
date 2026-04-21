import 'package:flutter/material.dart';

import '../../../core/auth/app_role.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../routing/app_router.dart';
import '../../../services/auth_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isLogin = true;
  AppRole _selectedRole = AppRole.student;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;

  final _formKey = GlobalKey<FormState>();
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
                'Backend-ready\nlearning platform',
                style: AppTextStyles.displayMedium
                    .copyWith(color: Colors.white, height: 1.25),
              ),
              const SizedBox(height: 16),
              Text(
                'Secure auth, role-based access, and real Supabase-backed dashboards are now built into the foundation.',
                style: AppTextStyles.bodyLarge
                    .copyWith(color: AppColors.sidebarText),
              ),
              const SizedBox(height: 40),
              ...const [
                'Role-based access for students, instructors, and admins',
                'Persistent sessions with Supabase Auth',
                'Real dashboard summaries backed by the database',
              ].map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: AppColors.emerald, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item,
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.sidebarText),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    final auth = AuthService.instance;

    return Form(
      key: _formKey,
      child: Column(
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
                ? 'Sign in and we will route you to the right dashboard automatically.'
                : 'Create a student or instructor account. Admin accounts are managed separately.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 32),
          _buildToggle(),
          const SizedBox(height: 28),
          if (!_isLogin) ...[
            _buildRoleSelector(),
            const SizedBox(height: 20),
          ],
          if (!_isLogin) ...[
            _buildField(
              controller: _nameController,
              label: 'Full Name',
              hint: 'Dr. Ahmed Ali',
              icon: Icons.person_outline_rounded,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your full name.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],
          _buildField(
            controller: _emailController,
            label: 'Email Address',
            hint: 'name@university.edu',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email address.';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email address.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildPasswordField(
            controller: _passwordController,
            label: 'Password',
            obscure: _obscurePassword,
            onToggle: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password.';
              }
              if (!_isLogin && value.length < 8) {
                return 'Password must be at least 8 characters.';
              }
              return null;
            },
          ),
          if (!_isLogin) ...[
            const SizedBox(height: 16),
            _buildPasswordField(
              controller: _confirmController,
              label: 'Confirm Password',
              obscure: _obscureConfirm,
              onToggle: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Passwords do not match.';
                }
                return null;
              },
            ),
          ],
          if (_isLogin) ...[
            const SizedBox(height: 8),
            Text(
              'Your role is detected after sign in from your profile record.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (auth.lastError != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.roseLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.rose.withValues(alpha: 0.3)),
              ),
              child: Text(
                auth.lastError!,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.rose),
              ),
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _onSubmit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isLogin ? 'Sign In' : 'Create Account'),
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
      ),
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
                          ),
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
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
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
    final roles = [AppRole.student, AppRole.instructor];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Account Type', style: AppTextStyles.label),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: roles.map((role) {
            final isSelected = _selectedRole == role;
            final activeColor = role == AppRole.student
                ? AppColors.primary
                : AppColors.emerald;
            final activeBg = role == AppRole.student
                ? AppColors.primaryLight
                : AppColors.emeraldLight;
            final icon = role == AppRole.student
                ? Icons.school_outlined
                : Icons.person_outline_rounded;

            return GestureDetector(
              onTap: () => setState(() => _selectedRole = role),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
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
                      color:
                          isSelected ? activeColor : AppColors.textSecondary,
                      size: 17,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      role.label,
                      style: AppTextStyles.label.copyWith(
                        color:
                            isSelected ? activeColor : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
    required String? Function(String?) validator,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
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
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          decoration: InputDecoration(
            hintText: '........',
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

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    final auth = AuthService.instance;

    try {
      if (_isLogin) {
        await auth.login(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await auth.register(
          email: _emailController.text,
          password: _passwordController.text,
          fullName: _nameController.text,
          role: _selectedRole,
        );
      }

      if (!mounted) {
        return;
      }

      final user = auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Account created. If email confirmation is enabled, confirm your email before signing in.',
            ),
          ),
        );
        setState(() {
          _isLogin = true;
          _isSubmitting = false;
        });
        return;
      }

      final route = AppRouter.defaultRouteForRole(user.role);
      Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
    } catch (_) {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
