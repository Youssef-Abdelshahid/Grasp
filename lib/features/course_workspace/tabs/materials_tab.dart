import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/file_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../models/material_model.dart';
import '../../../services/material_service.dart';
import '../../permissions/providers/permissions_provider.dart';
import '../pages/material_details_page.dart';
import '../providers/course_workspace_providers.dart';

class MaterialsTab extends ConsumerStatefulWidget {
  const MaterialsTab({super.key, required this.courseId});

  final String courseId;

  @override
  ConsumerState<MaterialsTab> createState() => _MaterialsTabState();
}

class _MaterialsTabState extends ConsumerState<MaterialsTab> {
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final materialsAsync = ref.watch(courseMaterialsProvider(widget.courseId));
    final canUpload =
        ref.watch(permissionsProvider).valueOrDefaults.uploadMaterials;
    return materialsAsync.when(
      loading: () => _buildContent(const [], canUpload, isLoading: true),
      error: (_, _) => _buildContent(const [], canUpload, hasError: true),
      data: (materials) => _buildContent(materials, canUpload),
    );
  }

  Widget _buildContent(
    List<MaterialModel> materials,
    bool canUpload, {
    bool isLoading = false,
    bool hasError = false,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canUpload) ...[
            _UploadArea(
              isUploading: _isUploading,
              onTap: _pickAndUploadMaterial,
            ),
            const SizedBox(height: 24),
          ],
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
                  '${materials.length}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (hasError)
            EmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Unable to load materials',
              subtitle: 'Please try again.',
              actionLabel: 'Retry',
              onAction: _refresh,
            )
          else if (materials.isEmpty)
            const EmptyState(
              icon: Icons.attach_file_rounded,
              title: 'No materials uploaded',
              subtitle:
                  'Upload PDFs, slides, documents, or videos to build your course library.',
            )
          else
            ...materials.map(
              (material) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _MaterialCard(
                  material: material,
                  onOpen: () => _openMaterial(material),
                  onEdit: canUpload ? () => _editMaterial(material) : null,
                  onDelete: canUpload ? () => _deleteMaterial(material) : null,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadMaterial() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }

    final selected = result.files.single;
    final meta = await _showMaterialMetadataDialog(
      initialTitle: selected.name.split('.').first,
    );
    if (meta == null) {
      return;
    }

    setState(() => _isUploading = true);
    try {
      await MaterialService.instance.uploadMaterial(
        courseId: widget.courseId,
        file: selected,
        title: meta.title,
        description: meta.description,
      );
      _refresh();
    } on MaterialUploadException catch (error) {
      _showMessage(error.message);
    } on PostgrestException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _openMaterial(MaterialModel material) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MaterialDetailsPage(material: material),
      ),
    );
    _refresh();
  }

  Future<void> _editMaterial(MaterialModel material) async {
    final meta = await _showMaterialMetadataDialog(
      initialTitle: material.title,
      initialDescription: material.description,
    );
    if (meta == null) {
      return;
    }

    try {
      await MaterialService.instance.updateMaterial(
        materialId: material.id,
        title: meta.title,
        description: meta.description,
      );
      _refresh();
    } on PostgrestException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> _deleteMaterial(MaterialModel material) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete Material'),
            content: Text('Delete "${material.title}" from this course?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    await MaterialService.instance.deleteMaterial(material);
    _refresh();
  }

  Future<_MaterialFormResult?> _showMaterialMetadataDialog({
    String initialTitle = '',
    String initialDescription = '',
  }) {
    final titleController = TextEditingController(text: initialTitle);
    final descriptionController = TextEditingController(
      text: initialDescription,
    );

    return showDialog<_MaterialFormResult>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Material Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(
              context,
              _MaterialFormResult(
                title: titleController.text.trim(),
                description: descriptionController.text.trim(),
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    ).whenComplete(() {
      titleController.dispose();
      descriptionController.dispose();
    });
  }

  void _refresh() {
    ref.invalidate(courseMaterialsProvider(widget.courseId));
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _MaterialCard extends StatelessWidget {
  const _MaterialCard({
    required this.material,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final MaterialModel material;
  final VoidCallback onOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final color = FileUtils.colorForExtension(material.fileType);
    final icon = FileUtils.iconForExtension(material.fileType);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
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
                      material.title,
                      style: AppTextStyles.label,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(material.fileType, style: AppTextStyles.caption),
                        Text(
                          FileUtils.formatDate(material.createdAt),
                          style: AppTextStyles.caption,
                        ),
                        Text(
                          FileUtils.formatBytes(material.fileSizeBytes),
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'open':
                      onOpen();
                      break;
                    case 'edit':
                      onEdit?.call();
                      break;
                    case 'delete':
                      onDelete?.call();
                      break;
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'open', child: Text('Open')),
                  if (onEdit != null)
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  if (onDelete != null)
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadArea extends StatefulWidget {
  const _UploadArea({required this.onTap, required this.isUploading});

  final VoidCallback onTap;
  final bool isUploading;

  @override
  State<_UploadArea> createState() => _UploadAreaState();
}

class _UploadAreaState extends State<_UploadArea> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = _isHovered
        ? AppColors.primary
        : AppColors.primary.withValues(alpha: 0.4);
    final bgColor = _isHovered
        ? AppColors.primaryLight.withValues(alpha: 0.6)
        : AppColors.primaryLight.withValues(alpha: 0.2);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.isUploading ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Column(
            children: [
              Icon(
                Icons.cloud_upload_rounded,
                color: AppColors.primary,
                size: 36,
              ),
              const SizedBox(height: 18),
              Text(
                widget.isUploading
                    ? 'Uploading material...'
                    : 'Upload Course Materials',
                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text(
                'Select a file and store its metadata directly in Supabase.',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: widget.isUploading ? null : widget.onTap,
                child: Text(
                  widget.isUploading ? 'Uploading...' : 'Select File',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaterialFormResult {
  const _MaterialFormResult({required this.title, required this.description});

  final String title;
  final String description;
}
