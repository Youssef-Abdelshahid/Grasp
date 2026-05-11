import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/platform_settings/providers/platform_settings_provider.dart';
import '../../../routing/app_router.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _NavBar(context),
            _Hero(context),
            _Features(context),
            _Footer(),
          ],
        ),
      ),
    );
  }
}

class _NavBar extends ConsumerWidget {
  final BuildContext parentContext;
  const _NavBar(this.parentContext);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(publicPlatformSettingsProvider).valueOrNull;
    final platformName = settings?.platformName ?? AppConstants.appName;
    final registrationEnabled = settings?.landingPageRegistration ?? true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            platformName,
            style: AppTextStyles.h3.copyWith(color: AppColors.primary),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.pushNamed(parentContext, AppRouter.auth),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text('Sign In'),
          ),
          const SizedBox(width: 6),
          if (registrationEnabled) ...[
            const SizedBox(width: 6),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pushNamed(parentContext, AppRouter.auth),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Get Started'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Hero extends ConsumerWidget {
  final BuildContext parentContext;
  const _Hero(this.parentContext);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(publicPlatformSettingsProvider).valueOrNull;
    final registrationEnabled = settings?.landingPageRegistration ?? true;
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= AppConstants.mobileBreakpoint;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 80 : 20,
        vertical: isWide ? 80 : 40,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryLight, AppColors.surface],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: Color(0x4D4F46E5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primary,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'AI-Powered Learning Platform',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Learn Smarter,\nNot Harder',
            style:
                (isWide
                        ? AppTextStyles.displayLarge
                        : AppTextStyles.displayMedium)
                    .copyWith(color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Text(
            'An AI-powered platform that helps instructors create engaging content and students master their courses effortlessly.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              if (registrationEnabled)
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pushNamed(parentContext, AppRouter.auth),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 14,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Get Started Free'),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
                  ),
                ),
              OutlinedButton(
                onPressed: () =>
                    Navigator.pushNamed(parentContext, AppRouter.auth),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                ),
                child: const Text('Sign In'),
              ),
            ],
          ),
          const SizedBox(height: 36),
          _StatsRow(),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final _stats = const [
    ('10K+', 'Students'),
    ('500+', 'Courses'),
    ('95%', 'Satisfaction'),
    ('2M+', 'AI Queries'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cols = constraints.maxWidth >= 380 ? 4 : 2;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              mainAxisExtent: 58,
            ),
            itemCount: _stats.length,
            itemBuilder: (_, i) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _stats[i].$1,
                  style: AppTextStyles.h2.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 2),
                Text(
                  _stats[i].$2,
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Features extends StatelessWidget {
  final BuildContext parentContext;
  const _Features(this.parentContext);

  static const _items = [
    (
      icon: Icons.quiz_rounded,
      title: 'AI Quizzes',
      desc: 'Generate smart quizzes from your materials in seconds',
      color: AppColors.primary,
      bg: AppColors.primaryLight,
    ),
    (
      icon: Icons.style_rounded,
      title: 'Flashcards',
      desc: 'Auto-create flashcards for effective spaced repetition',
      color: AppColors.cyan,
      bg: AppColors.cyanLight,
    ),
    (
      icon: Icons.assignment_rounded,
      title: 'Assignments',
      desc: 'AI-assisted assignment creation and instant feedback',
      color: AppColors.violet,
      bg: AppColors.violetLight,
    ),
    (
      icon: Icons.insights_rounded,
      title: 'Analytics',
      desc: 'Track learning progress with smart performance insights',
      color: AppColors.emerald,
      bg: AppColors.emeraldLight,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= AppConstants.mobileBreakpoint;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 80 : 20,
        vertical: isWide ? 64 : 40,
      ),
      color: AppColors.background,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondaryLight,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              'FEATURES',
              style: AppTextStyles.overline.copyWith(
                color: AppColors.secondary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Everything you need to succeed',
            style: AppTextStyles.h1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Powerful AI tools for instructors and students',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= 560 ? 4 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  mainAxisExtent: 185,
                ),
                itemCount: _items.length,
                itemBuilder: (context, i) {
                  final item = _items[i];
                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: item.bg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(item.icon, color: item.color, size: 20),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          item.title,
                          style: AppTextStyles.h3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.desc,
                          style: AppTextStyles.bodySmall,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      color: AppColors.sidebarBg,
      child: Center(
        child: Text(
          '© 2025 ${AppConstants.appName}. AI-powered education for everyone.',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.sidebarTextMuted,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
