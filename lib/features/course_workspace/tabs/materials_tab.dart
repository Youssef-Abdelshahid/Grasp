import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../pages/material_details_page.dart';

class MaterialsTab extends StatelessWidget {
  const MaterialsTab({super.key});

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
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUploadArea(),
          const SizedBox(height: 24),
          _buildMaterialsList(context),
        ],
      ),
    );
  }

  Widget _buildUploadArea() {
    return const _UploadArea();
  }

  Widget _buildMaterialsList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Uploaded Materials', style: AppTextStyles.h3),
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
        ),
        const SizedBox(height: 16),
        ...List.generate(_materials.length, (i) {
          final m = _materials[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _MaterialCard(
              icon: m.icon,
              name: m.name,
              type: m.type,
              date: m.date,
              size: m.size,
              color: m.color,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MaterialDetailsPage(
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
      ],
    );
  }
}

class _MaterialCard extends StatelessWidget {
  final IconData icon;
  final String name;
  final String type;
  final String date;
  final String size;
  final Color color;
  final VoidCallback? onTap;

  const _MaterialCard({
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
                            style: AppTextStyles.caption
                                .copyWith(color: color, fontWeight: FontWeight.w600),
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
                ),
                const SizedBox(width: 8),
                _AiActionButton(
                  icon: Icons.style_rounded,
                  label: 'Flashcards',
                  color: AppColors.violet,
                ),
                const SizedBox(width: 8),
                _AiActionButton(
                  icon: Icons.quiz_rounded,
                  label: 'Quiz',
                  color: AppColors.emerald,
                ),
                const SizedBox(width: 8),
                _AiActionButton(
                  icon: Icons.assignment_rounded,
                  label: 'Assignment',
                  color: AppColors.amber,
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

  const _AiActionButton({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () {},
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

class _UploadArea extends StatefulWidget {
  const _UploadArea();

  @override
  State<_UploadArea> createState() => _UploadAreaState();
}

class _UploadAreaState extends State<_UploadArea> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = _isHovered ? AppColors.primary : AppColors.primary.withValues(alpha: 0.4);
    final bgColor = _isHovered ? AppColors.primaryLight.withValues(alpha: 0.6) : AppColors.primaryLight.withValues(alpha: 0.2);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {},
        child: CustomPaint(
          painter: _DashedRectPainter(
            color: borderColor,
            strokeWidth: 2.0,
            gap: 8.0,
            dashWidth: 8.0,
            radius: 16.0,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: _isHovered ? 0.2 : 0.05),
                        blurRadius: _isHovered ? 24 : 16,
                        spreadRadius: _isHovered ? 8 : 4,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: AnimatedScale(
                    scale: _isHovered ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.cloud_upload_rounded,
                      color: AppColors.primary,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Upload Course Materials',
                  style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 14, height: 1.6),
                    children: [
                      const TextSpan(text: 'Drag and drop files here, or '),
                      const TextSpan(
                        text: 'click to browse',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: '\nSupported: PDF, DOCX, PPTX, MP4 (Max 200MB)'),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    elevation: _isHovered ? 4 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Select Files', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashWidth;
  final double radius;

  _DashedRectPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
    this.dashWidth = 5.0,
    this.radius = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    var path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(radius)));

    PathMetrics pathMetrics = path.computeMetrics();
    Path dashPath = Path();

    for (PathMetric pathMetric in pathMetrics) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth;
        distance += gap;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
