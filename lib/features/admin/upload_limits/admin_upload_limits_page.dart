import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/file_utils.dart';
import '../../../features/upload_limits/providers/upload_limits_provider.dart';
import '../../../models/upload_limits_model.dart';
import '../../../services/upload_limits_service.dart';

class AdminUploadLimitsPage extends ConsumerStatefulWidget {
  const AdminUploadLimitsPage({super.key});

  @override
  ConsumerState<AdminUploadLimitsPage> createState() =>
      _AdminUploadLimitsPageState();
}

class _AdminUploadLimitsPageState extends ConsumerState<AdminUploadLimitsPage> {
  final _materialFileSizeController = TextEditingController(text: '50');
  final _assignmentFileSizeController = TextEditingController(text: '25');
  final _maxMaterialFilesController = TextEditingController(text: '10');
  final _maxSubmissionFilesController = TextEditingController(text: '5');
  final _instructorMaterialQuotaController = TextEditingController(text: '10');
  final _studentSubmissionQuotaController = TextEditingController(text: '750');
  final _adminUploadQuotaController = TextEditingController(text: '50');

  final _allowedMaterialTypes = <String>{
    'PDF',
    'PPT',
    'PPTX',
    'DOCX',
    'DOC',
    'TXT',
    'PNG',
    'JPG',
    'JPEG',
  };
  final _allowedSubmissionTypes = <String>{
    'PDF',
    'DOCX',
    'DOC',
    'TXT',
    'PNG',
    'JPG',
    'JPEG',
    'ZIP',
  };

  static const _materialTypes = ['PDF', 'PPT', 'PPTX', 'DOCX', 'DOC', 'TXT'];
  static const _imageTypes = ['PNG', 'JPG', 'JPEG'];
  static const _submissionTypes = [
    'PDF',
    'DOCX',
    'DOC',
    'TXT',
    'PNG',
    'JPG',
    'JPEG',
    'ZIP',
  ];

  bool _allowMultipleUploads = true;
  bool _allowFileReplacement = true;
  bool _requireFileTypeValidation = true;
  bool _hasHydrated = false;

  @override
  void dispose() {
    _materialFileSizeController.dispose();
    _assignmentFileSizeController.dispose();
    _maxMaterialFilesController.dispose();
    _maxSubmissionFilesController.dispose();
    _instructorMaterialQuotaController.dispose();
    _studentSubmissionQuotaController.dispose();
    _adminUploadQuotaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(adminUploadLimitsProvider);
    final overviewAsync = ref.watch(uploadStorageOverviewProvider);
    configAsync.whenData((config) {
      if (!_hasHydrated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _hasHydrated) return;
          _applyConfig(config);
        });
      }
    });

    final width = MediaQuery.of(context).size.width;
    final isWide = width >= AppConstants.mobileBreakpoint;

    if (configAsync.isLoading && !_hasHydrated) {
      return const Center(child: CircularProgressIndicator());
    }

    if (configAsync.hasError && !_hasHydrated) {
      return _ErrorState(
        message: _friendlyError(configAsync.error),
        onRetry: () => ref.invalidate(adminUploadLimitsProvider),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isWide ? 28 : 16),
      child: Column(
        children: [
          _buildSaveBar(configAsync.isLoading),
          const SizedBox(height: 20),
          if (isWide)
            Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        _buildFileLimits(),
                        const SizedBox(height: 20),
                        _buildFileTypes(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildStorageQuota(),
                        const SizedBox(height: 20),
                        _buildUploadBehavior(),
                        const SizedBox(height: 20),
                        _buildStorageOverview(overviewAsync),
                      ],
                    ),
                  ),
                ],
              )
          else
            Column(
                children: [
                  _buildFileLimits(),
                  const SizedBox(height: 20),
                  _buildFileTypes(),
                  const SizedBox(height: 20),
                  _buildStorageQuota(),
                  const SizedBox(height: 20),
                  _buildUploadBehavior(),
                  const SizedBox(height: 20),
                  _buildStorageOverview(overviewAsync),
                ],
              ),
        ],
      ),
    );
  }

  void _applyConfig(UploadLimitsConfig config) {
    setState(() {
      _materialFileSizeController.text =
          config.maxMaterialFileSizeMb.toString();
      _assignmentFileSizeController.text =
          config.maxAssignmentSubmissionFileSizeMb.toString();
      _maxMaterialFilesController.text =
          config.maxFilesPerMaterialUpload.toString();
      _maxSubmissionFilesController.text =
          config.maxFilesPerAssignmentSubmission.toString();
      _instructorMaterialQuotaController.text =
          config.instructorMaterialStorageQuotaGb.toString();
      _studentSubmissionQuotaController.text =
          config.studentSubmissionStorageQuotaMb.toString();
      _adminUploadQuotaController.text =
          config.adminUploadStorageQuotaGb.toString();
      _allowedMaterialTypes
        ..clear()
        ..addAll({...config.materialFileTypes, ...config.imageFileTypes});
      _allowedSubmissionTypes
        ..clear()
        ..addAll(config.assignmentSubmissionFileTypes);
      _allowMultipleUploads = config.allowMultipleFileUploads;
      _allowFileReplacement = config.allowFileReplacement;
      _requireFileTypeValidation = config.requireFileTypeValidation;
      _hasHydrated = true;
    });
  }

  UploadLimitsConfig _configFromInputs() {
    int read(TextEditingController controller, int fallback) {
      return int.tryParse(controller.text.trim()) ?? fallback;
    }

    final defaults = UploadLimitsConfig.defaults();
    final imageTypes = _allowedMaterialTypes.intersection(_imageTypes.toSet());
    final materialTypes =
        _allowedMaterialTypes.difference(_imageTypes.toSet());
    return UploadLimitsConfig(
      maxMaterialFileSizeMb: read(
        _materialFileSizeController,
        defaults.maxMaterialFileSizeMb,
      ),
      maxAssignmentSubmissionFileSizeMb: read(
        _assignmentFileSizeController,
        defaults.maxAssignmentSubmissionFileSizeMb,
      ),
      maxFilesPerMaterialUpload: read(
        _maxMaterialFilesController,
        defaults.maxFilesPerMaterialUpload,
      ),
      maxFilesPerAssignmentSubmission: read(
        _maxSubmissionFilesController,
        defaults.maxFilesPerAssignmentSubmission,
      ),
      materialFileTypes: materialTypes,
      imageFileTypes: imageTypes,
      assignmentSubmissionFileTypes: _allowedSubmissionTypes,
      instructorMaterialStorageQuotaGb: read(
        _instructorMaterialQuotaController,
        defaults.instructorMaterialStorageQuotaGb,
      ),
      studentSubmissionStorageQuotaMb: read(
        _studentSubmissionQuotaController,
        defaults.studentSubmissionStorageQuotaMb,
      ),
      adminUploadStorageQuotaGb: read(
        _adminUploadQuotaController,
        defaults.adminUploadStorageQuotaGb,
      ),
      allowMultipleFileUploads: _allowMultipleUploads,
      allowFileReplacement: _allowFileReplacement,
      requireFileTypeValidation: _requireFileTypeValidation,
    );
  }

  Future<void> _save() async {
    try {
      final saved = await ref
          .read(adminUploadLimitsProvider.notifier)
          .save(_configFromInputs());
      _applyConfig(saved);
      _showSnackBar('Upload limits saved successfully');
    } catch (error) {
      _showSnackBar(_friendlyError(error), isError: true);
    }
  }

  Future<void> _reset() async {
    try {
      final saved = await ref.read(adminUploadLimitsProvider.notifier).reset();
      _applyConfig(saved);
      _showSnackBar('Upload limits reset to defaults');
    } catch (error) {
      _showSnackBar(_friendlyError(error), isError: true);
    }
  }

  Widget _buildSaveBar(bool isSaving) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Upload limits are saved platform-wide and checked before files are stored.',
              style: AppTextStyles.caption,
            ),
          ),
          TextButton(onPressed: isSaving ? null : _reset, child: const Text('Reset')),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: isSaving ? null : _save,
            icon: isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.save_rounded, size: 16),
            label: Text(isSaving ? 'Saving...' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _friendlyError(Object? error) {
    if (error is UploadLimitsException) return error.message;
    return 'Unable to update upload limits right now. Please try again.';
  }

  Widget _buildFileLimits() {
    return _Section(
      title: 'File Upload Limits',
      icon: Icons.upload_rounded,
      iconColor: AppColors.orange,
      iconBg: AppColors.orangeLight,
      child: Column(
        children: [
          _ResponsiveInputRow(
            children: [
              _InputTile(
                label: 'Max material file size',
                description: 'Maximum file size for course material uploads',
                controller: _materialFileSizeController,
                suffix: 'MB',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                hint: '50',
              ),
              _InputTile(
                label: 'Max assignment submission file size',
                description:
                    'Maximum file size students can upload for assignments',
                controller: _assignmentFileSizeController,
                suffix: 'MB',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                hint: '25',
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ResponsiveInputRow(
            children: [
              _InputTile(
                label: 'Max files per material upload',
                description:
                    'Maximum number of files an instructor/admin can upload at once',
                controller: _maxMaterialFilesController,
                suffix: 'files',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                hint: '10',
              ),
              _InputTile(
                label: 'Max files per assignment submission',
                description:
                    'Maximum number of files a student can submit for one assignment',
                controller: _maxSubmissionFilesController,
                suffix: 'files',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                hint: '5',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFileTypes() {
    return _Section(
      title: 'Allowed File Types',
      icon: Icons.description_rounded,
      iconColor: AppColors.primary,
      iconBg: AppColors.primaryLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Toggle the file extensions allowed for materials and assignment submissions',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 14),
          _FileTypeGroup(
            title: 'Material file types',
            types: _materialTypes,
            selectedTypes: _allowedMaterialTypes,
            onToggle: _toggleMaterialType,
          ),
          const SizedBox(height: 16),
          _FileTypeGroup(
            title: 'Image types',
            types: _imageTypes,
            selectedTypes: _allowedMaterialTypes,
            onToggle: _toggleMaterialType,
          ),
          const SizedBox(height: 16),
          _FileTypeGroup(
            title: 'Assignment submission types',
            types: _submissionTypes,
            selectedTypes: _allowedSubmissionTypes,
            onToggle: _toggleSubmissionType,
          ),
        ],
      ),
    );
  }

  void _toggleMaterialType(String type) {
    setState(() {
      if (_allowedMaterialTypes.contains(type)) {
        _allowedMaterialTypes.remove(type);
      } else {
        _allowedMaterialTypes.add(type);
      }
    });
  }

  void _toggleSubmissionType(String type) {
    setState(() {
      if (_allowedSubmissionTypes.contains(type)) {
        _allowedSubmissionTypes.remove(type);
      } else {
        _allowedSubmissionTypes.add(type);
      }
    });
  }

  Widget _buildStorageQuota() {
    return _Section(
      title: 'Storage Quotas',
      icon: Icons.storage_rounded,
      iconColor: AppColors.emerald,
      iconBg: AppColors.emeraldLight,
      child: Column(
        children: [
          _InputTile(
            label: 'Instructor material storage quota',
            description:
                'Maximum storage an instructor can use for course materials',
            controller: _instructorMaterialQuotaController,
            suffix: 'GB',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            hint: '10',
          ),
          const SizedBox(height: 14),
          _InputTile(
            label: 'Student submission storage quota',
            description:
                'Maximum storage a student can use for assignment submissions',
            controller: _studentSubmissionQuotaController,
            suffix: 'MB',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            hint: '750',
          ),
          const SizedBox(height: 14),
          _InputTile(
            label: 'Admin upload storage quota',
            description: 'Maximum storage available for admin-managed uploads',
            controller: _adminUploadQuotaController,
            suffix: 'GB',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            hint: '50',
          ),
        ],
      ),
    );
  }

  Widget _buildUploadBehavior() {
    return _Section(
      title: 'Upload Behavior',
      icon: Icons.tune_rounded,
      iconColor: AppColors.violet,
      iconBg: AppColors.violetLight,
      child: Column(
        children: [
          _ToggleTile(
            label: 'Allow multiple file uploads',
            subtitle: 'Allow uploading more than one file at a time',
            value: _allowMultipleUploads,
            onChanged: (v) => setState(() => _allowMultipleUploads = v),
          ),
          _ToggleTile(
            label: 'Allow file replacement',
            subtitle:
                'Allow replacing an uploaded material or assignment attachment',
            value: _allowFileReplacement,
            onChanged: (v) => setState(() => _allowFileReplacement = v),
          ),
          _ToggleTile(
            label: 'Require file type validation',
            subtitle: 'Check file type before upload',
            value: _requireFileTypeValidation,
            onChanged: (v) => setState(() => _requireFileTypeValidation = v),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageOverview(AsyncValue<UploadStorageOverview> overviewAsync) {
    final overview =
        overviewAsync.valueOrNull ?? UploadStorageOverview.empty();
    final total = overview.totalStorageBytes;
    final value = total <= 0 ? 0.0 : (total / (100 * 1024 * 1024 * 1024)).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.amberLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.pie_chart_rounded,
                  color: AppColors.amber,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text('Storage Overview', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 16),
          _StorageBar(
            label: 'Materials storage used',
            value: _storageShare(overview.materialsStorageBytes, total),
            color: AppColors.primary,
            size: FileUtils.formatBytes(overview.materialsStorageBytes),
          ),
          const SizedBox(height: 10),
          _StorageBar(
            label: 'Assignment submissions storage used',
            value: _storageShare(
              overview.assignmentSubmissionsStorageBytes,
              total,
            ),
            color: AppColors.violet,
            size: FileUtils.formatBytes(
              overview.assignmentSubmissionsStorageBytes,
            ),
          ),
          const SizedBox(height: 10),
          _StorageBar(
            label: 'Profile images storage used',
            value: _storageShare(overview.profileImagesStorageBytes, total),
            color: AppColors.orange,
            size: FileUtils.formatBytes(overview.profileImagesStorageBytes),
          ),
          const SizedBox(height: 10),
          _StorageBar(
            label: 'Total storage used',
            value: value,
            color: AppColors.emerald,
            size: FileUtils.formatBytes(overview.totalStorageBytes),
          ),
          const SizedBox(height: 16),
          Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Total Used', style: AppTextStyles.label),
              const Spacer(),
              Text(
                '${FileUtils.formatBytes(overview.totalStorageBytes)} known',
                style: AppTextStyles.label.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Known usage from stored upload metadata',
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  double _storageShare(int part, int total) {
    if (total <= 0) return 0;
    return (part / total).clamp(0.0, 1.0);
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(message, style: AppTextStyles.body, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileTypeGroup extends StatelessWidget {
  final String title;
  final List<String> types;
  final Set<String> selectedTypes;
  final ValueChanged<String> onToggle;

  const _FileTypeGroup({
    required this.title,
    required this.types,
    required this.selectedTypes,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.label),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: types.map((type) {
            final isSelected = selectedTypes.contains(type);
            return GestureDetector(
              onTap: () => onToggle(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          Icons.check_rounded,
                          size: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    Text(
                      type,
                      style: AppTextStyles.caption.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
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
}

class _ResponsiveInputRow extends StatelessWidget {
  final List<Widget> children;

  const _ResponsiveInputRow({required this.children});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 720;
    if (!isWide) {
      return Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) const SizedBox(height: 14),
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          Expanded(child: children[i]),
          if (i != children.length - 1) const SizedBox(width: 14),
        ],
      ],
    );
  }
}

class _StorageBar extends StatelessWidget {
  final String label;
  final String size;
  final double value;
  final Color color;

  const _StorageBar({
    required this.label,
    required this.value,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: AppTextStyles.bodySmall)),
            Text(
              size,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 5,
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Widget child;

  const _Section({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: AppTextStyles.h3)),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.label),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primaryLight,
          ),
        ],
      ),
    );
  }
}

class _InputTile extends StatelessWidget {
  final String label;
  final String? description;
  final String suffix;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _InputTile({
    required this.label,
    required this.controller,
    required this.suffix,
    required this.hint,
    this.description,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        if (description != null) ...[
          const SizedBox(height: 3),
          Text(description!, style: AppTextStyles.caption),
        ],
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffix,
            suffixStyle: AppTextStyles.caption.copyWith(
              color: AppColors.textMuted,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ],
    );
  }
}
