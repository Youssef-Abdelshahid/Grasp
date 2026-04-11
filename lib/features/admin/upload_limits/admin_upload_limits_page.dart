import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class AdminUploadLimitsPage extends StatefulWidget {
  const AdminUploadLimitsPage({super.key});

  @override
  State<AdminUploadLimitsPage> createState() => _AdminUploadLimitsPageState();
}

class _AdminUploadLimitsPageState extends State<AdminUploadLimitsPage> {
  final _fileSizeLimitController = TextEditingController(text: '25');
  final _maxFilesController = TextEditingController(text: '5');
  final _storageQuotaController = TextEditingController(text: '10');
  final _studentQuotaController = TextEditingController(text: '500');

  final _allowedTypes = <String>{'PDF', 'PPT', 'DOCX', 'MP4'};
  static const _fileTypeOptions = [
    'PDF', 'PPT', 'PPTX', 'DOCX', 'DOC',
    'MP4', 'ZIP', 'PNG', 'JPG', 'GIF', 'CSV', 'XLSX'
  ];

  bool _virusScan = true;
  bool _previewGeneration = true;
  bool _compressImages = false;

  @override
  void dispose() {
    _fileSizeLimitController.dispose();
    _maxFilesController.dispose();
    _storageQuotaController.dispose();
    _studentQuotaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= AppConstants.mobileBreakpoint;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isWide ? 28 : 16),
      child: isWide
          ? Row(
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
                      _buildProcessingOptions(),
                      const SizedBox(height: 20),
                      _buildStorageOverview(),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              children: [
                _buildFileLimits(),
                const SizedBox(height: 20),
                _buildFileTypes(),
                const SizedBox(height: 20),
                _buildStorageQuota(),
                const SizedBox(height: 20),
                _buildProcessingOptions(),
                const SizedBox(height: 20),
                _buildStorageOverview(),
              ],
            ),
    );
  }

  Widget _buildFileLimits() {
    return _Section(
      title: 'File Upload Limits',
      icon: Icons.upload_rounded,
      iconColor: AppColors.orange,
      iconBg: AppColors.orangeLight,
      child: Row(
        children: [
          Expanded(
            child: _InputTile(
              label: 'Max file size',
              controller: _fileSizeLimitController,
              suffix: 'MB',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              hint: '25',
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _InputTile(
              label: 'Max files per upload',
              controller: _maxFilesController,
              suffix: 'files',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              hint: '5',
            ),
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
          Text('Toggle to allow or restrict specific file types',
              style: AppTextStyles.caption),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _fileTypeOptions.map((type) {
              final isSelected = _allowedTypes.contains(type);
              return GestureDetector(
                onTap: () => setState(() {
                  if (isSelected) {
                    _allowedTypes.remove(type);
                  } else {
                    _allowedTypes.add(type);
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(Icons.check_rounded,
                              size: 12, color: AppColors.primary),
                        ),
                      Text(
                        type,
                        style: AppTextStyles.caption.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(
            '${_allowedTypes.length} of ${_fileTypeOptions.length} types allowed',
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
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
            label: 'Instructor storage quota',
            controller: _storageQuotaController,
            suffix: 'GB',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            hint: '10',
          ),
          const SizedBox(height: 14),
          _InputTile(
            label: 'Student storage quota',
            controller: _studentQuotaController,
            suffix: 'MB',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            hint: '500',
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingOptions() {
    return _Section(
      title: 'Processing Options',
      icon: Icons.tune_rounded,
      iconColor: AppColors.violet,
      iconBg: AppColors.violetLight,
      child: Column(
        children: [
          _ToggleTile(
            label: 'Virus Scan on Upload',
            subtitle: 'Scan all files for threats before storing',
            value: _virusScan,
            onChanged: (v) => setState(() => _virusScan = v),
          ),
          _ToggleTile(
            label: 'Auto-generate Previews',
            subtitle: 'Generate thumbnail previews for documents',
            value: _previewGeneration,
            onChanged: (v) => setState(() => _previewGeneration = v),
          ),
          _ToggleTile(
            label: 'Compress Images',
            subtitle:
                'Auto-compress uploaded images to reduce storage',
            value: _compressImages,
            onChanged: (v) => setState(() => _compressImages = v),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageOverview() {
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
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.pie_chart_rounded,
                    color: AppColors.amber, size: 16),
              ),
              const SizedBox(width: 10),
              Text('Storage Overview', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 16),
          _StorageBar(
              label: 'Videos',
              value: 0.45,
              color: AppColors.primary,
              size: '45.2 GB'),
          const SizedBox(height: 10),
          _StorageBar(
              label: 'Documents',
              value: 0.28,
              color: AppColors.violet,
              size: '28.1 GB'),
          const SizedBox(height: 10),
          _StorageBar(
              label: 'Images',
              value: 0.15,
              color: AppColors.orange,
              size: '15.0 GB'),
          const SizedBox(height: 10),
          _StorageBar(
              label: 'Other',
              value: 0.12,
              color: AppColors.textMuted,
              size: '11.7 GB'),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Total Used', style: AppTextStyles.label),
              const Spacer(),
              Text('100 GB / 500 GB',
                  style: AppTextStyles.label
                      .copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: const LinearProgressIndicator(
              value: 0.20,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 4),
          Text('20% of total capacity used',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _StorageBar extends StatelessWidget {
  final String label, size;
  final double value;
  final Color color;

  const _StorageBar(
      {required this.label,
      required this.value,
      required this.color,
      required this.size});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: AppTextStyles.bodySmall)),
            Text(size,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textMuted)),
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
  final Color iconColor, iconBg;
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
                    color: iconBg, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 10),
              Text(title, style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String label, subtitle;
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
  final String label, suffix, hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _InputTile({
    required this.label,
    required this.controller,
    required this.suffix,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffix,
            suffixStyle: AppTextStyles.caption
                .copyWith(color: AppColors.textMuted),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ],
    );
  }
}
