import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

String cleanStudyNoteText(String value) {
  var clean = value
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .replaceAll(RegExp(r'[ \t]+\n'), '\n')
      .replaceAll(RegExp(r'\n{4,}'), '\n\n\n')
      .trim();
  if (clean.isEmpty) return '';

  final symbolPatterns = <RegExp, String>{
    RegExp(r'\\?\$\s*\\+wedge\s*\\?\$', caseSensitive: false): '∧',
    RegExp(r'\\?\$\s*\\+vee\s*\\?\$', caseSensitive: false): '∨',
    RegExp(r'\\?\$\s*\\+neg\s*\\?\$', caseSensitive: false): '¬',
    RegExp(r'\\?\$\s*\\+rightarrow\s*\\?\$', caseSensitive: false): '→',
    RegExp(r'\\?\$\s*\\+to\s*\\?\$', caseSensitive: false): '→',
    RegExp(r'\\?\$\s*\\+equiv\s*\\?\$', caseSensitive: false): '≡',
    RegExp(r'\\?\$\s*\\+leftrightarrow\s*\\?\$', caseSensitive: false): '↔',
    RegExp(r'\\?\$\s*\\+forall\s*\\?\$', caseSensitive: false): '∀',
    RegExp(r'\\?\$\s*\\+exists\s*\\?\$', caseSensitive: false): '∃',
    RegExp(r'\\?\$\s*\\+in\s*\\?\$', caseSensitive: false): '∈',
    RegExp(r'\\?\$\s*\\+notin\s*\\?\$', caseSensitive: false): '∉',
    RegExp(r'\\?\$\s*\\+land\s*\\?\$', caseSensitive: false): '∧',
    RegExp(r'\\?\$\s*\\+lor\s*\\?\$', caseSensitive: false): '∨',
    RegExp(r'\\+wedge\b', caseSensitive: false): '∧',
    RegExp(r'\\+vee\b', caseSensitive: false): '∨',
    RegExp(r'\\+neg\b', caseSensitive: false): '¬',
    RegExp(r'\\+rightarrow\b', caseSensitive: false): '→',
    RegExp(r'\\+equiv\b', caseSensitive: false): '≡',
    RegExp(r'\\+leftrightarrow\b', caseSensitive: false): '↔',
    RegExp(r'\\+forall\b', caseSensitive: false): '∀',
    RegExp(r'\\+exists\b', caseSensitive: false): '∃',
    RegExp(r'\\+land\b', caseSensitive: false): '∧',
    RegExp(r'\\+lor\b', caseSensitive: false): '∨',
  };
  for (final entry in symbolPatterns.entries) {
    clean = clean.replaceAll(entry.key, entry.value);
  }

  clean = clean
      .replaceAll(r'\`', '`')
      .replaceAll(r'\*', '*')
      .replaceAll(r'\#', '#')
      .replaceAll(r'\_', '_')
      .replaceAll(r'\$', '')
      .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
      .replaceAll(RegExp(r'\n{4,}'), '\n\n\n')
      .trim();

  return clean;
}

class StudyNoteContentView extends StatelessWidget {
  const StudyNoteContentView({super.key, required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    final blocks = _parseBlocks(cleanStudyNoteText(content));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (final block in blocks) _StudyNoteBlockView(block: block)],
    );
  }
}

List<_StudyNoteBlock> _parseBlocks(String content) {
  final blocks = <_StudyNoteBlock>[];
  final paragraph = <String>[];

  void flushParagraph() {
    if (paragraph.isEmpty) return;
    blocks.add(_StudyNoteBlock.paragraph(paragraph.join(' ')));
    paragraph.clear();
  }

  for (final rawLine in content.split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty) {
      flushParagraph();
      continue;
    }

    final heading = RegExp(r'^(#{1,4})\s+(.+)$').firstMatch(line);
    if (heading != null) {
      flushParagraph();
      blocks.add(
        _StudyNoteBlock.heading(
          _stripInlineMarks(heading.group(2) ?? ''),
          heading.group(1)!.length,
        ),
      );
      continue;
    }

    final bullet = RegExp(r'^[-*+]\s+(.+)$').firstMatch(line);
    if (bullet != null) {
      flushParagraph();
      blocks.add(_StudyNoteBlock.bullet(bullet.group(1) ?? ''));
      continue;
    }

    final numbered = RegExp(r'^(\d+)[.)]\s+(.+)$').firstMatch(line);
    if (numbered != null) {
      flushParagraph();
      blocks.add(
        _StudyNoteBlock.numbered(
          int.tryParse(numbered.group(1) ?? '') ?? 1,
          numbered.group(2) ?? '',
        ),
      );
      continue;
    }

    paragraph.add(line);
  }

  flushParagraph();
  return blocks;
}

String _stripInlineMarks(String value) {
  return value
      .replaceAll(RegExp(r'(^[*_`]+)|([*_`]+$)'), '')
      .replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1')
      .replaceAll(RegExp(r'`([^`]+)`'), r'$1')
      .trim();
}

class _StudyNoteBlock {
  const _StudyNoteBlock._({
    required this.type,
    required this.text,
    this.level = 1,
    this.number = 0,
  });

  factory _StudyNoteBlock.heading(String text, int level) =>
      _StudyNoteBlock._(type: _BlockType.heading, text: text, level: level);

  factory _StudyNoteBlock.paragraph(String text) =>
      _StudyNoteBlock._(type: _BlockType.paragraph, text: text);

  factory _StudyNoteBlock.bullet(String text) =>
      _StudyNoteBlock._(type: _BlockType.bullet, text: text);

  factory _StudyNoteBlock.numbered(int number, String text) =>
      _StudyNoteBlock._(type: _BlockType.numbered, text: text, number: number);

  final _BlockType type;
  final String text;
  final int level;
  final int number;
}

enum _BlockType { heading, paragraph, bullet, numbered }

class _StudyNoteBlockView extends StatelessWidget {
  const _StudyNoteBlockView({required this.block});

  final _StudyNoteBlock block;

  @override
  Widget build(BuildContext context) {
    switch (block.type) {
      case _BlockType.heading:
        final style = switch (block.level) {
          1 => AppTextStyles.h2,
          2 => AppTextStyles.h3,
          _ => AppTextStyles.label.copyWith(fontSize: 16),
        };
        return Padding(
          padding: EdgeInsets.only(top: block.level == 1 ? 22 : 18, bottom: 8),
          child: SelectableText(
            block.text,
            style: style.copyWith(color: AppColors.textPrimary),
          ),
        );
      case _BlockType.paragraph:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SelectableText.rich(
            _inlineTextSpan(block.text),
            style: AppTextStyles.body.copyWith(height: 1.58, fontSize: 15.5),
          ),
        );
      case _BlockType.bullet:
        return _ListLine(marker: '•', text: block.text);
      case _BlockType.numbered:
        return _ListLine(marker: '${block.number}.', text: block.text);
    }
  }
}

class _ListLine extends StatelessWidget {
  const _ListLine({required this.marker, required this.text});

  final String marker;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Text(
              marker,
              style: AppTextStyles.body.copyWith(
                height: 1.55,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: SelectableText.rich(
              _inlineTextSpan(text),
              style: AppTextStyles.body.copyWith(height: 1.55, fontSize: 15.5),
            ),
          ),
        ],
      ),
    );
  }
}

TextSpan _inlineTextSpan(String text) {
  final spans = <TextSpan>[];
  final pattern = RegExp(r'(\*\*[^*]+\*\*|`[^`]+`)');
  var index = 0;
  for (final match in pattern.allMatches(text)) {
    if (match.start > index) {
      spans.add(TextSpan(text: text.substring(index, match.start)));
    }
    final token = match.group(0) ?? '';
    if (token.startsWith('**')) {
      spans.add(
        TextSpan(
          text: token.substring(2, token.length - 2),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
    } else if (token.startsWith('`')) {
      spans.add(
        TextSpan(
          text: token.substring(1, token.length - 1),
          style: const TextStyle(
            fontFamily: 'monospace',
            backgroundColor: AppColors.background,
          ),
        ),
      );
    }
    index = match.end;
  }
  if (index < text.length) {
    spans.add(TextSpan(text: text.substring(index)));
  }
  return TextSpan(children: spans);
}
