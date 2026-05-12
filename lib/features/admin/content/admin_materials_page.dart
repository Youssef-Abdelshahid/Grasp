import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/admin_content_models.dart';
import '../../../services/admin_content_service.dart';
import '../../../services/material_service.dart';

class AdminMaterialsPage extends StatefulWidget {
  const AdminMaterialsPage({super.key});

  @override
  State<AdminMaterialsPage> createState() => _AdminMaterialsPageState();
}

class _AdminMaterialsPageState extends State<AdminMaterialsPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String? _fileType;
  Future<List<AdminMaterialItem>>? _future;
  List<AdminCourseItem> _courses = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _load() {
    setState(() {
      _future = AdminContentService.instance.listMaterials(
        search: _searchController.text,
        fileType: _fileType,
      );
    });
    AdminContentService.instance.listCourses().then((courses) {
      if (mounted) setState(() => _courses = courses);
    });
  }

  void _search(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  void _snack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide =
        MediaQuery.of(context).size.width >= AppConstants.mobileBreakpoint;

    return FutureBuilder<List<AdminMaterialItem>>(
      future: _future,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <AdminMaterialItem>[];
        return SingleChildScrollView(
          padding: EdgeInsets.all(isWide ? 28 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                title: 'Materials',
                count: items.length,
                onRefresh: _load,
                onUpload: _uploadMaterial,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                onChanged: _search,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Search materials, files, or courses...',
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [null, 'PDF', 'PPTX', 'DOCX', 'MP4', 'PNG']
                    .map(
                      (type) => ChoiceChip(
                        label: Text(type ?? 'All'),
                        selected: _fileType == type,
                        onSelected: (_) {
                          _fileType = type;
                          _load();
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              if (snapshot.hasError)
                _Retry(onRetry: _load)
              else if (snapshot.connectionState != ConnectionState.done)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (items.isEmpty)
                const _Empty('No materials found')
              else
                _Panel(
                  child: Column(
                    children: items.map((item) {
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        leading: Icon(
                          Icons.description_rounded,
                          color: AppColors.primary,
                        ),
                        title: Text(item.title, style: AppTextStyles.label),
                        subtitle: Text(
                          '${item.courseCode} - ${item.instructorName} - ${item.fileType} - ${item.sizeLabel}',
                          style: AppTextStyles.caption,
                        ),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              tooltip: 'View details',
                              onPressed: () => _showDetails(item),
                              icon: Icon(Icons.visibility_rounded),
                            ),
                            IconButton(
                              tooltip: 'Open file',
                              onPressed: () => _openFile(item),
                              icon: Icon(Icons.open_in_new_rounded),
                            ),
                            IconButton(
                              tooltip: 'Edit',
                              onPressed: () => _showEdit(item),
                              icon: Icon(Icons.edit_rounded),
                            ),
                            IconButton(
                              tooltip: 'Remove',
                              onPressed: () => _remove(item),
                              icon: Icon(
                                Icons.delete_rounded,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _showDetails(item),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openFile(AdminMaterialItem item) async {
    try {
      final url = await AdminContentService.instance.createMaterialUrl(item);
      if (url == null) {
        _snack('This material has no storage file.', isError: true);
        return;
      }
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (error) {
      _snack(error.toString(), isError: true);
    }
  }

  void _showDetails(AdminMaterialItem item) {
    _showRows(item.title, {
      'Course': '${item.courseTitle} - ${item.courseCode}',
      'Instructor': item.instructorName,
      'Uploader': item.uploadedByName,
      'File': item.fileName,
      'Type': item.fileType,
      'Size': item.sizeLabel,
      'Uploaded': item.createdLabel,
      'Description': item.description.isEmpty
          ? 'No description'
          : item.description,
    });
  }

  void _showEdit(AdminMaterialItem item) {
    final title = TextEditingController(text: item.title);
    final description = TextEditingController(text: item.description);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Edit Material', style: AppTextStyles.h2),
            const SizedBox(height: 16),
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: description,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await AdminContentService.instance.updateMaterial(
                          materialId: item.id,
                          title: title.text,
                          description: description.text,
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        _snack('Material updated');
                        _load();
                      } catch (error) {
                        _snack(error.toString(), isError: true);
                      }
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _remove(AdminMaterialItem item) async {
    final ok = await _confirm('Remove Material', 'Remove ${item.title}?');
    if (!ok) return;
    try {
      await AdminContentService.instance.deleteMaterial(item);
      if (!mounted) return;
      _snack('Material removed');
      _load();
    } catch (error) {
      _snack(error.toString(), isError: true);
    }
  }

  Future<bool> _confirm(String title, String body) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showRows(String title, Map<String, String> rows) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: AppTextStyles.h2),
              const SizedBox(height: 16),
              ...rows.entries.map(
                (row) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 110,
                        child: Text(row.key, style: AppTextStyles.caption),
                      ),
                      Expanded(
                        child: Text(row.value, style: AppTextStyles.label),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _uploadMaterial() async {
    if (_courses.isEmpty) {
      _snack('Create a course before uploading materials.', isError: true);
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    if (!mounted) return;

    final selected = result.files.single;
    var courseId = _courses.first.id;
    final title = TextEditingController(text: selected.name.split('.').first);
    final description = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Upload Material', style: AppTextStyles.h2),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: courseId,
                  decoration: const InputDecoration(labelText: 'Course'),
                  items: _courses
                      .map(
                        (course) => DropdownMenuItem(
                          value: course.id,
                          child: Text('${course.title} - ${course.code}'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setSheet(() => courseId = value ?? courseId),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: description,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            await MaterialService.instance.uploadMaterial(
                              courseId: courseId,
                              file: selected,
                              title: title.text,
                              description: description.text,
                            );
                            await AdminContentService.instance.logAdminAction(
                              action: 'material_uploaded',
                              summary:
                                  'Uploaded material from admin: ${title.text}',
                              metadata: {'course_id': courseId},
                            );
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            _snack('Material uploaded');
                            _load();
                          } catch (error) {
                            _snack(error.toString(), isError: true);
                          }
                        },
                        child: const Text('Upload'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.count,
    required this.onRefresh,
    required this.onUpload,
  });
  final String title;
  final int count;
  final VoidCallback onRefresh;
  final VoidCallback onUpload;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppTextStyles.h1)),
        Text(
          '$count',
          style: AppTextStyles.label.copyWith(color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        IconButton.filledTonal(
          onPressed: onRefresh,
          icon: Icon(Icons.refresh_rounded),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: onUpload,
          icon: Icon(Icons.upload_rounded, size: 16),
          label: const Text('Upload'),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: child,
  );
}

class _Empty extends StatelessWidget {
  const _Empty(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => _Panel(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Center(child: Text(title, style: AppTextStyles.h3)),
    ),
  );
}

class _Retry extends StatelessWidget {
  const _Retry({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
  );
}
