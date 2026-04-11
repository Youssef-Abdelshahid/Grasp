import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../study/material_study_page.dart';

class StudentMaterialsTab extends StatelessWidget {
  const StudentMaterialsTab({super.key});

  static const _materials = [
    (
      icon: Icons.picture_as_pdf_rounded,
      name: 'Lecture 1 - Introduction to the Course',
      type: 'PDF',
      date: 'Mar 1, 2025',
      size: '2.4 MB',
      color: AppColors.rose,
    ),
    (
      icon: Icons.picture_as_pdf_rounded,
      name: 'Lecture 2 - Core Concepts & Fundamentals',
      type: 'PDF',
      date: 'Mar 8, 2025',
      size: '3.1 MB',
      color: AppColors.rose,
    ),
    (
      icon: Icons.slideshow_rounded,
      name: 'Week 3 - Advanced Topics Slides',
      type: 'PPTX',
      date: 'Mar 15, 2025',
      size: '8.7 MB',
      color: AppColors.amber,
    ),
    (
      icon: Icons.video_library_rounded,
      name: 'Demo: Live Coding Session Recording',
      type: 'MP4',
      date: 'Mar 20, 2025',
      size: '145 MB',
      color: AppColors.violet,
    ),
    (
      icon: Icons.description_rounded,
      name: 'Lab Sheet 1 - Hands-on Exercises',
      type: 'DOCX',
      date: 'Mar 22, 2025',
      size: '1.2 MB',
      color: AppColors.cyan,
    ),
    (
      icon: Icons.picture_as_pdf_rounded,
      name: 'Lecture 5 - Advanced Topics',
      type: 'PDF',
      date: 'Mar 28, 2025',
      size: '4.5 MB',
      color: AppColors.rose,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildMaterialsList(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text('Course Materials', style: AppTextStyles.h2),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            '${_materials.length}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMaterialsList(BuildContext context) {
    return Column(
      children: List.generate(_materials.length, (i) {
        final m = _materials[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _StudentMaterialCard(
            icon: m.icon,
            name: m.name,
            type: m.type,
            date: m.date,
            size: m.size,
            color: m.color,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MaterialStudyPage(
                  name: m.name,
                  type: m.type,
                  date: m.date,
                  size: m.size,
                  color: m.color,
                  icon: m.icon,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _StudentMaterialCard extends StatelessWidget {
  final IconData icon;
  final String name;
  final String type;
  final String date;
  final String size;
  final Color color;
  final VoidCallback? onTap;

  const _StudentMaterialCard({
    required this.icon,
    required this.name,
    required this.type,
    required this.date,
    required this.size,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: AppTextStyles.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                type,
                                style: AppTextStyles.caption.copyWith(
                                    color: color, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(date, style: AppTextStyles.caption),
                            const SizedBox(width: 8),
                            Text('· $size', style: AppTextStyles.caption),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _AiActionButton(
                      icon: Icons.summarize_rounded,
                      label: 'Summary',
                      color: AppColors.cyan,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StudyToolsPage(
                            materialName: name,
                            materialType: type,
                            initialTab: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _AiActionButton(
                      icon: Icons.style_rounded,
                      label: 'Flashcards',
                      color: AppColors.violet,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StudyToolsPage(
                            materialName: name,
                            materialType: type,
                            initialTab: 0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _AiActionButton(
                      icon: Icons.quiz_rounded,
                      label: 'Quiz',
                      color: AppColors.emerald,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StudyToolsPage(
                            materialName: name,
                            materialType: type,
                            initialTab: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AiActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded, color: color, size: 12),
              const SizedBox(width: 5),
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTextStyles.buttonSmall.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
