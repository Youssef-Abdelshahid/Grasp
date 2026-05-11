class UploadLimitsConfig {
  const UploadLimitsConfig({
    required this.maxMaterialFileSizeMb,
    required this.maxAssignmentSubmissionFileSizeMb,
    required this.maxFilesPerMaterialUpload,
    required this.maxFilesPerAssignmentSubmission,
    required this.materialFileTypes,
    required this.imageFileTypes,
    required this.assignmentSubmissionFileTypes,
    required this.instructorMaterialStorageQuotaGb,
    required this.studentSubmissionStorageQuotaMb,
    required this.adminUploadStorageQuotaGb,
    required this.allowMultipleFileUploads,
    required this.allowFileReplacement,
    required this.requireFileTypeValidation,
  });

  factory UploadLimitsConfig.defaults() => const UploadLimitsConfig(
        maxMaterialFileSizeMb: 50,
        maxAssignmentSubmissionFileSizeMb: 25,
        maxFilesPerMaterialUpload: 10,
        maxFilesPerAssignmentSubmission: 5,
        materialFileTypes: {'PDF', 'PPT', 'PPTX', 'DOCX', 'DOC', 'TXT'},
        imageFileTypes: {'PNG', 'JPG', 'JPEG'},
        assignmentSubmissionFileTypes: {
          'PDF',
          'DOCX',
          'DOC',
          'TXT',
          'PNG',
          'JPG',
          'JPEG',
          'ZIP',
        },
        instructorMaterialStorageQuotaGb: 10,
        studentSubmissionStorageQuotaMb: 750,
        adminUploadStorageQuotaGb: 50,
        allowMultipleFileUploads: true,
        allowFileReplacement: true,
        requireFileTypeValidation: true,
      );

  factory UploadLimitsConfig.fromJson(Map<String, dynamic> json) {
    final defaults = UploadLimitsConfig.defaults();
    int readInt(String key, int fallback) {
      final value = json[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? fallback;
    }

    bool readBool(String key, bool fallback) => json[key] as bool? ?? fallback;
    Set<String> readTypes(String key, Set<String> fallback) {
      final value = json[key];
      if (value is List) {
        return value.map((item) => item.toString().toUpperCase()).toSet();
      }
      return fallback;
    }

    return UploadLimitsConfig(
      maxMaterialFileSizeMb: readInt(
        UploadLimitKeys.maxMaterialFileSizeMb,
        defaults.maxMaterialFileSizeMb,
      ),
      maxAssignmentSubmissionFileSizeMb: readInt(
        UploadLimitKeys.maxAssignmentSubmissionFileSizeMb,
        defaults.maxAssignmentSubmissionFileSizeMb,
      ),
      maxFilesPerMaterialUpload: readInt(
        UploadLimitKeys.maxFilesPerMaterialUpload,
        defaults.maxFilesPerMaterialUpload,
      ),
      maxFilesPerAssignmentSubmission: readInt(
        UploadLimitKeys.maxFilesPerAssignmentSubmission,
        defaults.maxFilesPerAssignmentSubmission,
      ),
      materialFileTypes: readTypes(
        UploadLimitKeys.materialFileTypes,
        defaults.materialFileTypes,
      ),
      imageFileTypes: readTypes(
        UploadLimitKeys.imageFileTypes,
        defaults.imageFileTypes,
      ),
      assignmentSubmissionFileTypes: readTypes(
        UploadLimitKeys.assignmentSubmissionFileTypes,
        defaults.assignmentSubmissionFileTypes,
      ),
      instructorMaterialStorageQuotaGb: readInt(
        UploadLimitKeys.instructorMaterialStorageQuotaGb,
        defaults.instructorMaterialStorageQuotaGb,
      ),
      studentSubmissionStorageQuotaMb: readInt(
        UploadLimitKeys.studentSubmissionStorageQuotaMb,
        defaults.studentSubmissionStorageQuotaMb,
      ),
      adminUploadStorageQuotaGb: readInt(
        UploadLimitKeys.adminUploadStorageQuotaGb,
        defaults.adminUploadStorageQuotaGb,
      ),
      allowMultipleFileUploads: readBool(
        UploadLimitKeys.allowMultipleFileUploads,
        defaults.allowMultipleFileUploads,
      ),
      allowFileReplacement: readBool(
        UploadLimitKeys.allowFileReplacement,
        defaults.allowFileReplacement,
      ),
      requireFileTypeValidation: readBool(
        UploadLimitKeys.requireFileTypeValidation,
        defaults.requireFileTypeValidation,
      ),
    );
  }

  final int maxMaterialFileSizeMb;
  final int maxAssignmentSubmissionFileSizeMb;
  final int maxFilesPerMaterialUpload;
  final int maxFilesPerAssignmentSubmission;
  final Set<String> materialFileTypes;
  final Set<String> imageFileTypes;
  final Set<String> assignmentSubmissionFileTypes;
  final int instructorMaterialStorageQuotaGb;
  final int studentSubmissionStorageQuotaMb;
  final int adminUploadStorageQuotaGb;
  final bool allowMultipleFileUploads;
  final bool allowFileReplacement;
  final bool requireFileTypeValidation;

  Set<String> get allowedMaterialUploadTypes => {
        ...materialFileTypes,
        ...imageFileTypes,
      };

  Set<String> get allowedAssignmentUploadTypes => {
        ...assignmentSubmissionFileTypes,
        ...imageFileTypes,
      };

  Map<String, dynamic> toJson() => {
        UploadLimitKeys.maxMaterialFileSizeMb: maxMaterialFileSizeMb,
        UploadLimitKeys.maxAssignmentSubmissionFileSizeMb:
            maxAssignmentSubmissionFileSizeMb,
        UploadLimitKeys.maxFilesPerMaterialUpload: maxFilesPerMaterialUpload,
        UploadLimitKeys.maxFilesPerAssignmentSubmission:
            maxFilesPerAssignmentSubmission,
        UploadLimitKeys.materialFileTypes: materialFileTypes.toList()..sort(),
        UploadLimitKeys.imageFileTypes: imageFileTypes.toList()..sort(),
        UploadLimitKeys.assignmentSubmissionFileTypes:
            assignmentSubmissionFileTypes.toList()..sort(),
        UploadLimitKeys.instructorMaterialStorageQuotaGb:
            instructorMaterialStorageQuotaGb,
        UploadLimitKeys.studentSubmissionStorageQuotaMb:
            studentSubmissionStorageQuotaMb,
        UploadLimitKeys.adminUploadStorageQuotaGb: adminUploadStorageQuotaGb,
        UploadLimitKeys.allowMultipleFileUploads: allowMultipleFileUploads,
        UploadLimitKeys.allowFileReplacement: allowFileReplacement,
        UploadLimitKeys.requireFileTypeValidation: requireFileTypeValidation,
      };
}

class UploadStorageOverview {
  const UploadStorageOverview({
    required this.materialsStorageBytes,
    required this.assignmentSubmissionsStorageBytes,
    required this.profileImagesStorageBytes,
    required this.totalStorageBytes,
  });

  factory UploadStorageOverview.empty() => const UploadStorageOverview(
        materialsStorageBytes: 0,
        assignmentSubmissionsStorageBytes: 0,
        profileImagesStorageBytes: 0,
        totalStorageBytes: 0,
      );

  factory UploadStorageOverview.fromJson(Map<String, dynamic> json) {
    int read(String key) {
      final value = json[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return UploadStorageOverview(
      materialsStorageBytes: read('materials_storage_bytes'),
      assignmentSubmissionsStorageBytes:
          read('assignment_submissions_storage_bytes'),
      profileImagesStorageBytes: read('profile_images_storage_bytes'),
      totalStorageBytes: read('total_storage_bytes'),
    );
  }

  final int materialsStorageBytes;
  final int assignmentSubmissionsStorageBytes;
  final int profileImagesStorageBytes;
  final int totalStorageBytes;
}

class UploadSources {
  const UploadSources._();

  static const material = 'material';
  static const adminMaterial = 'admin_material';
  static const assignmentSubmission = 'assignment_submission';
  static const assignmentAttachment = 'assignment_attachment';
  static const questionImage = 'question_image';
  static const profileImage = 'profile_image';
}

class UploadLimitKeys {
  const UploadLimitKeys._();

  static const maxMaterialFileSizeMb = 'max_material_file_size_mb';
  static const maxAssignmentSubmissionFileSizeMb =
      'max_assignment_submission_file_size_mb';
  static const maxFilesPerMaterialUpload = 'max_files_per_material_upload';
  static const maxFilesPerAssignmentSubmission =
      'max_files_per_assignment_submission';
  static const materialFileTypes = 'material_file_types';
  static const imageFileTypes = 'image_file_types';
  static const assignmentSubmissionFileTypes =
      'assignment_submission_file_types';
  static const instructorMaterialStorageQuotaGb =
      'instructor_material_storage_quota_gb';
  static const studentSubmissionStorageQuotaMb =
      'student_submission_storage_quota_mb';
  static const adminUploadStorageQuotaGb = 'admin_upload_storage_quota_gb';
  static const allowMultipleFileUploads = 'allow_multiple_file_uploads';
  static const allowFileReplacement = 'allow_file_replacement';
  static const requireFileTypeValidation = 'require_file_type_validation';
}
