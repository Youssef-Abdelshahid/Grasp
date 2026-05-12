import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../models/material_model.dart';
import '../../../../services/material_service.dart';
import '../../../permissions/providers/permissions_provider.dart';
import '../../study/material_study_page.dart';

class StudentMaterialsTab extends ConsumerStatefulWidget {
  const StudentMaterialsTab({super.key, required this.courseId});

  final String courseId;

  @override
  ConsumerState<StudentMaterialsTab> createState() => _StudentMaterialsTabState();
}

class _StudentMaterialsTabState extends ConsumerState<StudentMaterialsTab> {
  late Future<List<MaterialModel>> _materialsFuture;
  Set<String> _favoriteIds = const <String>{};

  @override
  void initState() {
    super.initState();
    _materialsFuture = MaterialService.instance.getCourseMaterials(
      widget.courseId,
    );
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final ids = await MaterialService.instance.favoriteMaterialIds();
    if (!mounted) return;
    setState(() => _favoriteIds = ids);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MaterialModel>>(
      future: _materialsFuture,
      builder: (context, snapshot) {
        final materials = snapshot.data ?? [];
        final canDownload =
            ref.watch(permissionsProvider).valueOrDefaults.downloadMaterials;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Course Materials', style: AppTextStyles.h2),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
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
              if (MaterialService.instance.lastCourseMaterialsFromCache) ...[
                _OfflineCacheLabel(
                  label: 'Showing cached data',
                  subtitle: 'Materials metadata is from this device.',
                ),
                const SizedBox(height: 12),
              ],
              if (snapshot.connectionState != ConnectionState.done)
                const Center(child: CircularProgressIndicator())
              else if (materials.isEmpty)
                const EmptyState(
                  icon: Icons.attach_file_rounded,
                  title: 'No materials available',
                  subtitle:
                      'Materials uploaded by your instructor will appear here.',
                )
              else
                ...materials.map(
                  (material) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _StudentMaterialCard(
                      material: material,
                      canOpen: canDownload,
                      isFavorite: _favoriteIds.contains(material.id),
                      onFavoriteChanged: (favorite) async {
                        await MaterialService.instance.setMaterialFavorite(
                          material: material,
                          isFavorite: favorite,
                        );
                        await _loadFavorites();
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StudentMaterialCard extends StatelessWidget {
  const _StudentMaterialCard({
    required this.material,
    required this.canOpen,
    required this.isFavorite,
    required this.onFavoriteChanged,
  });

  final MaterialModel material;
  final bool canOpen;
  final bool isFavorite;
  final ValueChanged<bool> onFavoriteChanged;

  @override
  Widget build(BuildContext context) {
    final color = FileUtils.colorForExtension(material.fileType);
    final icon = FileUtils.iconForExtension(material.fileType);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: canOpen
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MaterialStudyPage(material: material),
                  ),
                )
            : () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'You do not currently have permission to perform this action.',
                    ),
                  ),
                ),
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
                    Text(
                      '${material.fileType} • ${FileUtils.formatDate(material.createdAt)} • ${FileUtils.formatBytes(material.fileSizeBytes)}',
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!canOpen) ...[
                const SizedBox(width: 8),
                Text(
                  'Disabled',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
              FutureBuilder<String?>(
                future: MaterialService.instance.getLocalMaterialPath(material),
                builder: (context, snapshot) {
                  final downloaded = snapshot.data != null;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (downloaded)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Tooltip(
                            message: 'Available offline',
                            child: Icon(
                              Icons.download_done_rounded,
                              color: AppColors.emerald,
                              size: 18,
                            ),
                          ),
                        ),
                      IconButton(
                        tooltip: isFavorite ? 'Unsave material' : 'Save material',
                        icon: Icon(
                          isFavorite
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          color: isFavorite
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                        onPressed: () => onFavoriteChanged(!isFavorite),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfflineCacheLabel extends StatelessWidget {
  const _OfflineCacheLabel({required this.label, required this.subtitle});

  final String label;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.amberLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, size: 16, color: AppColors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label - $subtitle',
              style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
