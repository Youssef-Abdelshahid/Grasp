import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/file_utils.dart';
import '../../../models/material_model.dart';
import '../../../services/material_service.dart';

class MaterialDetailsPage extends StatefulWidget {
  const MaterialDetailsPage({super.key, required this.material});

  final MaterialModel material;

  @override
  State<MaterialDetailsPage> createState() => _MaterialDetailsPageState();
}

class _MaterialDetailsPageState extends State<MaterialDetailsPage> {
  bool _isOpening = false;

  @override
  Widget build(BuildContext context) {
    final color = FileUtils.colorForExtension(widget.material.fileType);
    final icon = FileUtils.iconForExtension(widget.material.fileType);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.material.fileType, style: AppTextStyles.h3),
        actions: [
          IconButton(
            icon: Icon(Icons.download_rounded),
            onPressed: _isOpening ? null : _openFile,
            tooltip: 'Open',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.material.title,
                          style: AppTextStyles.h3,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.material.fileName,
                          style: AppTextStyles.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              widget.material.fileType,
                              style: AppTextStyles.caption,
                            ),
                            Text(
                              FileUtils.formatDate(widget.material.createdAt),
                              style: AppTextStyles.caption,
                            ),
                            Text(
                              FileUtils.formatBytes(
                                widget.material.fileSizeBytes,
                              ),
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Description', style: AppTextStyles.h3),
                  const SizedBox(height: 8),
                  Text(
                    widget.material.description.isEmpty
                        ? 'No material description provided.'
                        : widget.material.description,
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  Text('Uploaded By', style: AppTextStyles.h3),
                  const SizedBox(height: 8),
                  Text(
                    widget.material.uploadedByName.isEmpty
                        ? 'Unknown instructor'
                        : widget.material.uploadedByName,
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isOpening ? null : _openFile,
                      icon: _isOpening
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.open_in_new_rounded, size: 16),
                      label: Text(_isOpening ? 'Opening...' : 'Open File'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openFile() async {
    setState(() => _isOpening = true);
    try {
      final url = await MaterialService.instance.createSignedUrl(
        widget.material,
      );
      if (url == null) {
        _showMessage('No file URL found for this material.');
        return;
      }
      final uri = Uri.parse(url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        _showMessage('Unable to open the file.');
      }
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isOpening = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
