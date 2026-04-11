import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/section_header.dart';

class MaterialDetailsPage extends StatelessWidget {
  final String name;
  final String type;
  final String date;
  final String size;
  final Color color;
  final IconData icon;

  const MaterialDetailsPage({
    super.key,
    required this.name,
    required this.type,
    required this.date,
    required this.size,
    required this.color,
    required this.icon,
  });

  static const _topics = [
    'Core Concepts', 'Introduction', 'Best Practices',
    'Architecture', 'State Management', 'Performance',
    'Testing', 'Deployment',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(type, style: AppTextStyles.h3),
        actions: [
          IconButton(icon: const Icon(Icons.download_rounded), onPressed: () {}, tooltip: 'Download'),
          IconButton(icon: const Icon(Icons.share_rounded), onPressed: () {}, tooltip: 'Share'),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildPreview(),
          const SizedBox(height: 20),
          _buildTopics(),
          const SizedBox(height: 20),
          _buildAiActions(context),
          const SizedBox(height: 20),
          _buildGeneratedContent(),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: AppTextStyles.h3, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 4, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(type, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w600)),
            ),
            Text(date, style: AppTextStyles.caption),
            Text('· $size', style: AppTextStyles.caption),
          ]),
        ])),
      ]),
    );
  }

  Widget _buildPreview() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.08), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 40),
        ),
        const SizedBox(height: 16),
        Text('File Preview', style: AppTextStyles.h3),
        const SizedBox(height: 6),
        Text('Tap to open the full file', style: AppTextStyles.bodySmall),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.open_in_new_rounded, size: 15),
          label: const Text('Open File'),
        ),
      ])),
    );
  }

  Widget _buildTopics() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(title: 'Extracted Topics'),
      const SizedBox(height: 12),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Wrap(spacing: 8, runSpacing: 8, children: _topics.map((t) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(t, style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w500)),
        )).toList()),
      ),
    ]);
  }

  Widget _buildAiActions(BuildContext context) {
    final actions = [
      (icon: Icons.summarize_rounded, label: 'Summary', desc: 'AI-powered content summary', color: AppColors.cyan, bg: AppColors.cyanLight),
      (icon: Icons.style_rounded, label: 'Flashcards', desc: 'Auto-generate study cards', color: AppColors.violet, bg: AppColors.violetLight),
      (icon: Icons.quiz_rounded, label: 'Quiz', desc: 'Generate quiz questions', color: AppColors.emerald, bg: AppColors.emeraldLight),
      (icon: Icons.assignment_rounded, label: 'Assignment', desc: 'Build an assignment', color: AppColors.amber, bg: AppColors.amberLight),
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(title: 'AI Actions'),
      const SizedBox(height: 12),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          mainAxisExtent: 112,
        ),
        itemCount: actions.length,
        itemBuilder: (_, i) {
          final a = actions[i];
          return Material(
            color: a.bg,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: () => _showAiSheet(context, a.label),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.auto_awesome_rounded, size: 12, color: a.color),
                    const SizedBox(width: 4),
                    Icon(a.icon, size: 16, color: a.color),
                  ]),
                  const SizedBox(height: 8),
                  Text(a.label, style: AppTextStyles.label.copyWith(color: a.color)),
                  const SizedBox(height: 2),
                  Text(a.desc, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ),
            ),
          );
        },
      ),
    ]);
  }

  void _showAiSheet(BuildContext context, String action) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AiSheet(action: action),
    );
  }

  Widget _buildGeneratedContent() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(title: 'Generated Content'),
      const SizedBox(height: 12),
      _ExpandableContent(
        icon: Icons.summarize_rounded,
        title: 'Summary',
        color: AppColors.cyan,
        bg: AppColors.cyanLight,
        content: 'This material introduces fundamental concepts and methodologies, covering core principles with practical examples. Key areas include theoretical foundations, real-world applications, and hands-on exercises designed to reinforce understanding.',
      ),
      const SizedBox(height: 10),
      _ExpandableContent(
        icon: Icons.style_rounded,
        title: 'Flashcards (8 cards)',
        color: AppColors.violet,
        bg: AppColors.violetLight,
        content: 'Q: What is the primary purpose?\nA: To provide a structured approach to understanding the subject matter.\n\nQ: Name 3 key concepts.\nA: Theory, Application, and Practice.',
      ),
    ]);
  }
}

class _AiSheet extends StatelessWidget {
  final String action;
  const _AiSheet({required this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
          child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 32),
        ),
        const SizedBox(height: 16),
        Text('Generate $action', style: AppTextStyles.h3, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('AI is analyzing the material and generating content for you...', style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
        const SizedBox(height: 20),
        const LinearProgressIndicator(),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        )),
      ]),
    );
  }
}

class _ExpandableContent extends StatefulWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Color bg;
  final String content;

  const _ExpandableContent({
    required this.icon,
    required this.title,
    required this.color,
    required this.bg,
    required this.content,
  });

  @override
  State<_ExpandableContent> createState() => _ExpandableContentState();
}

class _ExpandableContentState extends State<_ExpandableContent> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(color: widget.bg, borderRadius: BorderRadius.circular(7)),
                child: Icon(widget.icon, color: widget.color, size: 15),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(widget.title, style: AppTextStyles.label)),
              Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: AppColors.textSecondary, size: 20),
            ]),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(children: [
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                child: Text(widget.content, style: AppTextStyles.bodySmall),
              ),
            ]),
          ),
      ]),
    );
  }
}
