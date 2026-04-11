import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class MaterialStudyPage extends StatefulWidget {
  final String name;
  final String type;
  final String date;
  final String size;
  final Color color;
  final IconData icon;

  const MaterialStudyPage({
    super.key,
    required this.name,
    required this.type,
    required this.date,
    required this.size,
    required this.color,
    required this.icon,
  });

  @override
  State<MaterialStudyPage> createState() => _MaterialStudyPageState();
}

class _MaterialStudyPageState extends State<MaterialStudyPage> {
  final _notesController = TextEditingController();

  static const _keyConcepts = [
    (term: 'Flutter Widget Tree', def: 'A hierarchical structure of widgets describing the UI.'),
    (term: 'State Management', def: 'Techniques to manage and propagate UI state throughout the app.'),
    (term: 'Dart Isolates', def: 'Independent workers for concurrent computation without shared memory.'),
    (term: 'BuildContext', def: 'A handle to the location of a widget in the widget tree.'),
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.name, style: AppTextStyles.label, overflow: TextOverflow.ellipsis, maxLines: 1),
            Text('${widget.type} · ${widget.size}', style: AppTextStyles.caption),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.bookmark_border_rounded), onPressed: () {}),
          IconButton(icon: const Icon(Icons.share_rounded), onPressed: () {}),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPreview(),
            const SizedBox(height: 24),
            _buildSummary(),
            const SizedBox(height: 24),
            _buildKeyConcepts(),
            const SizedBox(height: 24),
            _buildStudyToolsButton(context),
            const SizedBox(height: 24),
            _buildNotesArea(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.color.withValues(alpha: 0.15),
            widget.color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(widget.icon, color: widget.color, size: 36),
          ),
          const SizedBox(height: 14),
          Text(widget.name,
              style: AppTextStyles.label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.open_in_new_rounded, size: 14),
            label: const Text('Open File'),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.cyanLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: AppColors.cyan, size: 16),
            ),
            const SizedBox(width: 10),
            Text('AI Summary', style: AppTextStyles.h3),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This lecture introduces the foundational concepts of mobile development using Flutter. It covers the widget tree, reactive UI paradigm, and the difference between stateful and stateless components.',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 12),
              Text(
                'Key takeaways include understanding the BuildContext lifecycle, when to use setState vs. external state management, and how Flutter\'s rendering pipeline enables 60fps performance.',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.cyanLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: AppColors.cyan, size: 12),
                    const SizedBox(width: 5),
                    Text('Generated by AI · 3 min read',
                        style: AppTextStyles.caption.copyWith(color: AppColors.cyan, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKeyConcepts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.violetLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.lightbulb_rounded, color: AppColors.violet, size: 16),
            ),
            const SizedBox(width: 10),
            Text('Key Concepts', style: AppTextStyles.h3),
          ],
        ),
        const SizedBox(height: 12),
        ..._keyConcepts.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 4,
                      height: 16,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: AppColors.violet,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.term, style: AppTextStyles.label.copyWith(color: AppColors.violet)),
                          const SizedBox(height: 4),
                          Text(c.def, style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildStudyToolsButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.violet.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StudyToolsPage(
                materialName: widget.name,
                materialType: widget.type,
              ),
            ),
          ),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Study Tools', style: AppTextStyles.h3),
                      const SizedBox(height: 3),
                      Text(
                        'Flashcards · Summaries · Practice · Notes',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotesArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.amberLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.edit_note_rounded, color: AppColors.amber, size: 16),
            ),
            const SizedBox(width: 10),
            Text('My Notes', style: AppTextStyles.h3),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: _notesController,
            maxLines: 6,
            style: AppTextStyles.body,
            decoration: InputDecoration(
              hintText: 'Write your notes here...',
              hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.save_rounded, size: 14),
            label: const Text('Save Notes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amber,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

class StudyToolsPage extends StatefulWidget {
  final String materialName;
  final String materialType;
  final int initialTab;

  const StudyToolsPage({
    super.key,
    required this.materialName,
    required this.materialType,
    this.initialTab = 0,
  });

  @override
  State<StudyToolsPage> createState() => _StudyToolsPageState();
}

class _StudyToolsPageState extends State<StudyToolsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = [
    (icon: Icons.style_rounded, label: 'Flashcards'),
    (icon: Icons.summarize_rounded, label: 'Summaries'),
    (icon: Icons.quiz_rounded, label: 'Practice'),
    (icon: Icons.edit_note_rounded, label: 'Notes'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabBar = TabBar(
      controller: _tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      indicatorColor: Colors.white,
      indicatorWeight: 2,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white60,
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
      tabs: _tabs.map((t) => Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(t.icon, size: 15),
            const SizedBox(width: 5),
            Text(t.label),
          ],
        ),
      )).toList(),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.sidebarBg,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Study Tools', style: AppTextStyles.h2.copyWith(color: Colors.white)),
            Text(
              widget.materialName,
              style: AppTextStyles.caption.copyWith(color: Colors.white60),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
        bottom: tabBar,
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _FlashcardsSection(),
          _SummariesSection(),
          _PracticeSection(),
          _NotesSection(),
        ],
      ),
    );
  }
}

class _FlashcardsSection extends StatefulWidget {
  const _FlashcardsSection();

  @override
  State<_FlashcardsSection> createState() => _FlashcardsSectionState();
}

class _FlashcardsSectionState extends State<_FlashcardsSection> {
  int _current = 0;
  bool _flipped = false;

  static const _cards = [
    (q: 'What is a StatelessWidget?', a: 'A widget that does not require mutable state. Rebuilds only when its parent changes.'),
    (q: 'What is hot reload?', a: 'A Flutter feature that updates the running app instantly without restarting the full app.'),
    (q: 'What does the Scaffold widget provide?', a: 'A Material Design layout structure: AppBar, Body, FAB, Drawer, SnackBar, BottomSheet.'),
    (q: 'What does setState() do?', a: 'Notifies the framework that the internal state has changed, causing a rebuild of this widget.'),
    (q: 'What is a BuildContext?', a: 'A handle to the location of a widget in the widget tree, used to access theme, media, navigator, etc.'),
    (q: 'What is the difference between hot reload and hot restart?', a: 'Hot reload preserves state; hot restart resets the app state from scratch.'),
  ];

  @override
  Widget build(BuildContext context) {
    final card = _cards[_current];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Text('${_current + 1} / ${_cards.length}',
                  style: AppTextStyles.bodySmall),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() { _current = 0; _flipped = false; }),
                icon: const Icon(Icons.refresh_rounded, size: 14),
                label: const Text('Restart'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_current + 1) / _cards.length,
              backgroundColor: AppColors.border,
              color: AppColors.violet,
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => setState(() => _flipped = !_flipped),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Container(
                key: ValueKey(_flipped),
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 220),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _flipped
                        ? [AppColors.emerald, const Color(0xFF059669)]
                        : [AppColors.primary, const Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (_flipped ? AppColors.emerald : AppColors.primary).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        _flipped ? 'ANSWER' : 'QUESTION',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _flipped ? card.a : card.q,
                      style: AppTextStyles.h3.copyWith(color: Colors.white, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Tap to flip',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_flipped) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      if (_current < _cards.length - 1) {
                        setState(() { _current++; _flipped = false; });
                      }
                    },
                    icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.rose),
                    label: const Text('Again', style: TextStyle(color: AppColors.rose)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.rose),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_current < _cards.length - 1) {
                        setState(() { _current++; _flipped = false; });
                      }
                    },
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Got it'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emerald,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _current > 0
                      ? () => setState(() { _current--; _flipped = false; })
                      : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => setState(() => _flipped = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.violet,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  ),
                  child: const Text('Reveal Answer'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _current < _cards.length - 1
                      ? () => setState(() { _current++; _flipped = false; })
                      : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SummariesSection extends StatelessWidget {
  const _SummariesSection();

  static const _summaries = [
    (
      readTime: '3 min read',
      preview: 'This lecture introduces the foundational concepts of mobile development using Flutter. It covers the widget tree, reactive UI paradigm, and the difference between stateful and stateless components.',
      date: 'Mar 1, 2025',
    ),
    (
      readTime: '2 min read',
      preview: 'The second half covers how Flutter\'s rendering pipeline compares to native rendering. Understanding the layer tree, compositing, and how repaint boundaries optimize performance.',
      date: 'Mar 1, 2025',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AI-Generated Summaries', style: AppTextStyles.h2),
          const SizedBox(height: 4),
          Text('${_summaries.length} summaries for this material', style: AppTextStyles.bodySmall),
          const SizedBox(height: 16),
          ..._summaries.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(color: AppColors.cyanLight, borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.auto_awesome_rounded, color: AppColors.cyan, size: 14),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text('AI Summary · ${s.date}', style: AppTextStyles.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          Text(s.readTime, style: AppTextStyles.caption.copyWith(color: AppColors.cyan, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(s.preview, style: AppTextStyles.bodySmall, maxLines: 3, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Read Full Summary'),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, size: 13),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _PracticeSection extends StatefulWidget {
  const _PracticeSection();

  @override
  State<_PracticeSection> createState() => _PracticeSectionState();
}

class _PracticeSectionState extends State<_PracticeSection> {
  final Map<int, int> _selected = {};

  static const _questions = [
    (
      q: 'Which widget is best for rendering a large list efficiently?',
      options: ['Column', 'ListView.builder', 'GridView', 'Stack'],
      correct: 1,
    ),
    (
      q: 'What does the "const" keyword accomplish in Flutter widget trees?',
      options: ['Speeds up animations', 'Prevents unnecessary rebuilds', 'Enables tree shaking', 'None of the above'],
      correct: 1,
    ),
    (
      q: 'Which of the following correctly describes a Future in Dart?',
      options: ['A synchronous value', 'A completed computation', 'An async computation result', 'A stream of values'],
      correct: 2,
    ),
    (
      q: 'What is the purpose of the "key" parameter in Flutter?',
      options: ['Styling the widget', 'Preserving state during rebuilds', 'Encrypting data', 'Routing navigation'],
      correct: 1,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final answered = _selected.length;
    final correct = _selected.entries.where((e) => _questions[e.key].correct == e.value).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Practice Questions', style: AppTextStyles.h2),
                    Text('${_questions.length} questions · tap to select', style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              if (answered > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.emeraldLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.emerald.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '$correct/$answered',
                    style: AppTextStyles.label.copyWith(color: AppColors.emerald),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          ..._questions.asMap().entries.map((entry) {
            final i = entry.key;
            final q = entry.value;
            final chosen = _selected[i];

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Question ${i + 1}', style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(q.q, style: AppTextStyles.label),
                    const SizedBox(height: 12),
                    ...q.options.asMap().entries.map((opt) {
                      final isChosen = chosen == opt.key;
                      final isCorrect = q.correct == opt.key;
                      final showResult = chosen != null;

                      Color borderColor = AppColors.border;
                      Color bgColor = AppColors.background;
                      Color textColor = AppColors.textPrimary;

                      if (showResult) {
                        if (isCorrect) { borderColor = AppColors.success; bgColor = AppColors.successLight; textColor = AppColors.success; }
                        else if (isChosen) { borderColor = AppColors.rose; bgColor = AppColors.roseLight; textColor = AppColors.rose; }
                      } else if (isChosen) {
                        borderColor = AppColors.primary;
                        bgColor = AppColors.primaryLight;
                      }

                      return GestureDetector(
                        onTap: chosen == null
                            ? () => setState(() => _selected[i] = opt.key)
                            : null,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: showResult && isCorrect
                                      ? AppColors.success
                                      : (showResult && isChosen ? AppColors.rose : Colors.transparent),
                                  border: Border.all(
                                    color: showResult && isCorrect
                                        ? AppColors.success
                                        : (showResult && isChosen ? AppColors.rose : AppColors.border),
                                  ),
                                ),
                                child: showResult && (isCorrect || isChosen)
                                    ? Icon(isCorrect ? Icons.check_rounded : Icons.close_rounded, size: 12, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Text(opt.value, style: AppTextStyles.bodySmall.copyWith(color: textColor))),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          }),
          if (answered == _questions.length)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF6366F1)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Practice Complete!', style: AppTextStyles.label.copyWith(color: Colors.white)),
                        Text('Score: $correct out of ${_questions.length}',
                            style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _selected.clear()),
                    child: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _NotesSection extends StatefulWidget {
  const _NotesSection();

  @override
  State<_NotesSection> createState() => _NotesSectionState();
}

class _NotesSectionState extends State<_NotesSection> {
  final List<Map<String, String>> _notes = [
    {'title': 'Widget lifecycle notes', 'body': 'Remember: initState → build → setState → build → dispose.', 'date': 'Mar 5'},
    {'title': 'Key rendering concepts', 'body': 'Flutter uses a three-tree architecture: widget tree, element tree, and render tree.', 'date': 'Mar 8'},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My Notes', style: AppTextStyles.h2),
                    Text('${_notes.length} saved notes', style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddNoteSheet(context),
                icon: const Icon(Icons.add_rounded, size: 14),
                label: const Text('Add Note'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._notes.asMap().entries.map((entry) {
            final n = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(color: AppColors.amberLight, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.sticky_note_2_rounded, color: AppColors.amber, size: 14),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n['title']!, style: AppTextStyles.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(n['date']!, style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.textMuted),
                          onPressed: () => setState(() => _notes.removeAt(entry.key)),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(n['body']!, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showAddNoteSheet(BuildContext context) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New Note', style: AppTextStyles.h3),
              const SizedBox(height: 16),
              TextField(controller: titleCtrl, decoration: const InputDecoration(hintText: 'Title')),
              const SizedBox(height: 12),
              TextField(controller: bodyCtrl, maxLines: 4, decoration: const InputDecoration(hintText: 'Write your note...')),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleCtrl.text.isNotEmpty) {
                      setState(() => _notes.insert(0, {
                        'title': titleCtrl.text,
                        'body': bodyCtrl.text,
                        'date': 'Today',
                      }));
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Save Note'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
