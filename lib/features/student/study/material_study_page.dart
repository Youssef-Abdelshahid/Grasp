import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/file_utils.dart';
import '../../../models/material_model.dart';
import '../../../services/material_service.dart';
import '../../../services/permissions_service.dart';

class MaterialStudyPage extends StatefulWidget {
  const MaterialStudyPage({super.key, required this.material});

  final MaterialModel material;

  @override
  State<MaterialStudyPage> createState() => _MaterialStudyPageState();
}

class _MaterialStudyPageState extends State<MaterialStudyPage> {
  bool _isOpening = false;
  bool _isDownloading = false;
  String? _localPath;

  @override
  void initState() {
    super.initState();
    MaterialService.instance.trackMaterialOpened(widget.material);
    _loadLocalPath();
  }

  Future<void> _loadLocalPath() async {
    final path = await MaterialService.instance.getLocalMaterialPath(
      widget.material,
    );
    if (!mounted) return;
    setState(() => _localPath = path);
  }

  @override
  Widget build(BuildContext context) {
    final color = FileUtils.colorForExtension(widget.material.fileType);
    final icon = FileUtils.iconForExtension(widget.material.fileType);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.material.title,
              style: AppTextStyles.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${widget.material.fileType} • ${FileUtils.formatBytes(widget.material.fileSizeBytes)}',
              style: AppTextStyles.caption,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.open_in_new_rounded),
            onPressed: _isOpening ? null : _openFile,
          ),
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.16),
                    color.withValues(alpha: 0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 36),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.material.fileName,
                    style: AppTextStyles.label,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _isOpening ? null : _openFile,
                    icon: _isOpening
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(Icons.open_in_new_rounded, size: 14),
                    label: Text(_isOpening ? 'Opening...' : 'Open File'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _isDownloading ? null : _downloadForOffline,
                    icon: _isDownloading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _localPath == null
                                ? Icons.download_rounded
                                : Icons.download_done_rounded,
                            size: 16,
                          ),
                    label: Text(
                      _localPath == null
                          ? 'Download for Offline'
                          : 'Available Offline',
                    ),
                  ),
                  if (_localPath != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'This material is downloaded on this device.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.emerald,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            _InfoCard(
              title: 'Description',
              child: Text(
                widget.material.description.isEmpty
                    ? 'No description was provided for this material.'
                    : widget.material.description,
                style: AppTextStyles.bodySmall,
              ),
            ),
            const SizedBox(height: 16),
            _InfoCard(
              title: 'Material Details',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoLine(label: 'Type', value: widget.material.fileType),
                  _InfoLine(
                    label: 'Uploaded',
                    value: FileUtils.formatDateTime(widget.material.createdAt),
                  ),
                  _InfoLine(
                    label: 'Size',
                    value: FileUtils.formatBytes(widget.material.fileSizeBytes),
                  ),
                  _InfoLine(
                    label: 'Uploaded By',
                    value: widget.material.uploadedByName.isEmpty
                        ? 'Unknown instructor'
                        : widget.material.uploadedByName,
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
      final localPath = await MaterialService.instance.getLocalMaterialPath(
        widget.material,
      );
      if (localPath != null) {
        final result = await OpenFilex.open(
          localPath,
          type: widget.material.mimeType.trim().isEmpty
              ? null
              : widget.material.mimeType,
        );
        if (result.type != ResultType.done) {
          final openedRemote = await _openRemoteFile();
          if (!openedRemote) {
            _showMessage(
              result.message.trim().isEmpty
                  ? 'No app is available to open this downloaded file.'
                  : result.message,
            );
          }
        }
        return;
      }

      await _openRemoteFile(showErrors: true);
    } on PermissionsException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Unable to open the file.');
    } finally {
      if (mounted) {
        setState(() => _isOpening = false);
      }
    }
  }

  Future<bool> _openRemoteFile({bool showErrors = false}) async {
    final url = await MaterialService.instance.createRemoteSignedUrl(
      widget.material,
    );
    if (url == null) {
      if (showErrors) _showMessage('No file URL found for this material.');
      return false;
    }

    final launched = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!launched && showErrors) {
      _showMessage('Unable to open the file.');
    }
    return launched;
  }

  Future<void> _downloadForOffline() async {
    setState(() => _isDownloading = true);
    try {
      final path = await MaterialService.instance.downloadMaterialForOffline(
        widget.material,
      );
      if (!mounted) return;
      setState(() => _localPath = path);
      _showMessage('Material is available offline on this device.');
    } on PermissionsException catch (error) {
      _showMessage(error.message);
    } on MaterialUploadException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Unable to download this material for offline use.');
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.h3),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text('$label:', style: AppTextStyles.caption),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodySmall)),
        ],
      ),
    );
  }
}
