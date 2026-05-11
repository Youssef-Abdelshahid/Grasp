class PlatformSettingsConfig {
  const PlatformSettingsConfig({
    required this.platformName,
    required this.landingPageRegistration,
    required this.defaultDashboardTimeRange,
    required this.defaultListSorting,
    required this.requireStrongPasswords,
    required this.allowPasswordChange,
    required this.adminUserCreationEnabled,
    required this.preventDeletingLastAdmin,
    required this.adminNotifications,
    required this.newUserNotifications,
    required this.courseActivityNotifications,
    required this.aiGenerationFailureNotifications,
    required this.requireReloginAfterPasswordChange,
    required this.autoLogoutInactiveUsers,
    required this.timeoutDurationMinutes,
    this.platformSessionInvalidatedAt,
  });

  factory PlatformSettingsConfig.defaults() => const PlatformSettingsConfig(
        platformName: 'Grasp',
        landingPageRegistration: true,
        defaultDashboardTimeRange: PlatformDashboardRanges.last30Days,
        defaultListSorting: PlatformListSorting.newestFirst,
        requireStrongPasswords: true,
        allowPasswordChange: true,
        adminUserCreationEnabled: true,
        preventDeletingLastAdmin: true,
        adminNotifications: true,
        newUserNotifications: true,
        courseActivityNotifications: true,
        aiGenerationFailureNotifications: true,
        requireReloginAfterPasswordChange: true,
        autoLogoutInactiveUsers: true,
        timeoutDurationMinutes: 30,
      );

  factory PlatformSettingsConfig.fromJson(Map<String, dynamic> json) {
    final defaults = PlatformSettingsConfig.defaults().toJson();
    bool readBool(String key) => json[key] as bool? ?? defaults[key] as bool;
    String readString(String key) =>
        json[key]?.toString() ?? defaults[key] as String;
    int readInt(String key) {
      final value = json[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      return defaults[key] as int;
    }

    final invalidatedAt = json['platform_session_invalidated_at'];

    return PlatformSettingsConfig(
      platformName: readString(PlatformSettingKeys.platformName),
      landingPageRegistration:
          readBool(PlatformSettingKeys.landingPageRegistration),
      defaultDashboardTimeRange: PlatformDashboardRanges.normalize(
        readString(PlatformSettingKeys.defaultDashboardTimeRange),
      ),
      defaultListSorting: PlatformListSorting.normalize(
        readString(PlatformSettingKeys.defaultListSorting),
      ),
      requireStrongPasswords:
          readBool(PlatformSettingKeys.requireStrongPasswords),
      allowPasswordChange: readBool(PlatformSettingKeys.allowPasswordChange),
      adminUserCreationEnabled:
          readBool(PlatformSettingKeys.adminUserCreationEnabled),
      preventDeletingLastAdmin:
          readBool(PlatformSettingKeys.preventDeletingLastAdmin),
      adminNotifications: readBool(PlatformSettingKeys.adminNotifications),
      newUserNotifications: readBool(PlatformSettingKeys.newUserNotifications),
      courseActivityNotifications:
          readBool(PlatformSettingKeys.courseActivityNotifications),
      aiGenerationFailureNotifications:
          readBool(PlatformSettingKeys.aiGenerationFailureNotifications),
      requireReloginAfterPasswordChange:
          readBool(PlatformSettingKeys.requireReloginAfterPasswordChange),
      autoLogoutInactiveUsers:
          readBool(PlatformSettingKeys.autoLogoutInactiveUsers),
      timeoutDurationMinutes: PlatformTimeoutDurations.normalize(
        readInt(PlatformSettingKeys.timeoutDurationMinutes),
      ),
      platformSessionInvalidatedAt: invalidatedAt == null
          ? null
          : DateTime.tryParse(invalidatedAt.toString())?.toUtc(),
    );
  }

  final String platformName;
  final bool landingPageRegistration;
  final String defaultDashboardTimeRange;
  final String defaultListSorting;
  final bool requireStrongPasswords;
  final bool allowPasswordChange;
  final bool adminUserCreationEnabled;
  final bool preventDeletingLastAdmin;
  final bool adminNotifications;
  final bool newUserNotifications;
  final bool courseActivityNotifications;
  final bool aiGenerationFailureNotifications;
  final bool requireReloginAfterPasswordChange;
  final bool autoLogoutInactiveUsers;
  final int timeoutDurationMinutes;
  final DateTime? platformSessionInvalidatedAt;

  Map<String, dynamic> toJson() => {
        PlatformSettingKeys.platformName: platformName.trim(),
        PlatformSettingKeys.landingPageRegistration: landingPageRegistration,
        PlatformSettingKeys.defaultDashboardTimeRange: defaultDashboardTimeRange,
        PlatformSettingKeys.defaultListSorting: defaultListSorting,
        PlatformSettingKeys.requireStrongPasswords: requireStrongPasswords,
        PlatformSettingKeys.allowPasswordChange: allowPasswordChange,
        PlatformSettingKeys.adminUserCreationEnabled: adminUserCreationEnabled,
        PlatformSettingKeys.preventDeletingLastAdmin: preventDeletingLastAdmin,
        PlatformSettingKeys.adminNotifications: adminNotifications,
        PlatformSettingKeys.newUserNotifications: newUserNotifications,
        PlatformSettingKeys.courseActivityNotifications:
            courseActivityNotifications,
        PlatformSettingKeys.aiGenerationFailureNotifications:
            aiGenerationFailureNotifications,
        PlatformSettingKeys.requireReloginAfterPasswordChange:
            requireReloginAfterPasswordChange,
        PlatformSettingKeys.autoLogoutInactiveUsers: autoLogoutInactiveUsers,
        PlatformSettingKeys.timeoutDurationMinutes: timeoutDurationMinutes,
      };

  PlatformSettingsConfig copyWith({
    String? platformName,
    bool? landingPageRegistration,
    String? defaultDashboardTimeRange,
    String? defaultListSorting,
    bool? requireStrongPasswords,
    bool? allowPasswordChange,
    bool? adminUserCreationEnabled,
    bool? preventDeletingLastAdmin,
    bool? adminNotifications,
    bool? newUserNotifications,
    bool? courseActivityNotifications,
    bool? aiGenerationFailureNotifications,
    bool? requireReloginAfterPasswordChange,
    bool? autoLogoutInactiveUsers,
    int? timeoutDurationMinutes,
    DateTime? platformSessionInvalidatedAt,
  }) {
    return PlatformSettingsConfig(
      platformName: platformName ?? this.platformName,
      landingPageRegistration:
          landingPageRegistration ?? this.landingPageRegistration,
      defaultDashboardTimeRange:
          defaultDashboardTimeRange ?? this.defaultDashboardTimeRange,
      defaultListSorting: defaultListSorting ?? this.defaultListSorting,
      requireStrongPasswords:
          requireStrongPasswords ?? this.requireStrongPasswords,
      allowPasswordChange: allowPasswordChange ?? this.allowPasswordChange,
      adminUserCreationEnabled:
          adminUserCreationEnabled ?? this.adminUserCreationEnabled,
      preventDeletingLastAdmin:
          preventDeletingLastAdmin ?? this.preventDeletingLastAdmin,
      adminNotifications: adminNotifications ?? this.adminNotifications,
      newUserNotifications: newUserNotifications ?? this.newUserNotifications,
      courseActivityNotifications:
          courseActivityNotifications ?? this.courseActivityNotifications,
      aiGenerationFailureNotifications: aiGenerationFailureNotifications ??
          this.aiGenerationFailureNotifications,
      requireReloginAfterPasswordChange: requireReloginAfterPasswordChange ??
          this.requireReloginAfterPasswordChange,
      autoLogoutInactiveUsers:
          autoLogoutInactiveUsers ?? this.autoLogoutInactiveUsers,
      timeoutDurationMinutes:
          timeoutDurationMinutes ?? this.timeoutDurationMinutes,
      platformSessionInvalidatedAt:
          platformSessionInvalidatedAt ?? this.platformSessionInvalidatedAt,
    );
  }
}

class PlatformSettingKeys {
  static const platformName = 'platform_name';
  static const landingPageRegistration = 'landing_page_registration';
  static const defaultDashboardTimeRange = 'default_dashboard_time_range';
  static const defaultListSorting = 'default_list_sorting';
  static const requireStrongPasswords = 'require_strong_passwords';
  static const allowPasswordChange = 'allow_password_change';
  static const adminUserCreationEnabled = 'admin_user_creation_enabled';
  static const preventDeletingLastAdmin = 'prevent_deleting_last_admin';
  static const adminNotifications = 'admin_notifications';
  static const newUserNotifications = 'new_user_notifications';
  static const courseActivityNotifications = 'course_activity_notifications';
  static const aiGenerationFailureNotifications =
      'ai_generation_failure_notifications';
  static const requireReloginAfterPasswordChange =
      'require_relogin_after_password_change';
  static const autoLogoutInactiveUsers = 'auto_logout_inactive_users';
  static const timeoutDurationMinutes = 'timeout_duration_minutes';
}

class PlatformDashboardRanges {
  static const last7Days = 'last_7_days';
  static const last30Days = 'last_30_days';
  static const thisSemester = 'this_semester';
  static const allTime = 'all_time';
  static const allowed = [last7Days, last30Days, thisSemester, allTime];

  static String normalize(String value) {
    return allowed.contains(value) ? value : last30Days;
  }

  static String label(String value) {
    return switch (normalize(value)) {
      last7Days => 'Last 7 days',
      last30Days => 'Last 30 days',
      thisSemester => 'This semester',
      allTime => 'All time',
      _ => 'Last 30 days',
    };
  }

  static String fromLabel(String label) {
    return switch (label) {
      'Last 7 days' => last7Days,
      'This semester' => thisSemester,
      'All time' => allTime,
      _ => last30Days,
    };
  }
}

class PlatformListSorting {
  static const newestFirst = 'newest_first';
  static const oldestFirst = 'oldest_first';
  static const aZ = 'a_z';
  static const allowed = [newestFirst, oldestFirst, aZ];

  static String normalize(String value) {
    return allowed.contains(value) ? value : newestFirst;
  }

  static String label(String value) {
    return switch (normalize(value)) {
      newestFirst => 'Newest first',
      oldestFirst => 'Oldest first',
      aZ => 'A-Z',
      _ => 'Newest first',
    };
  }

  static String fromLabel(String label) {
    return switch (label) {
      'Oldest first' => oldestFirst,
      'A-Z' => aZ,
      _ => newestFirst,
    };
  }
}

class PlatformTimeoutDurations {
  static const allowed = [15, 30, 60, 120];

  static int normalize(int value) {
    return allowed.contains(value) ? value : 30;
  }

  static String label(int value) {
    return switch (normalize(value)) {
      15 => '15 min',
      60 => '1 hour',
      120 => '2 hours',
      _ => '30 min',
    };
  }

  static int fromLabel(String label) {
    return switch (label) {
      '15 min' => 15,
      '1 hour' => 60,
      '2 hours' => 120,
      _ => 30,
    };
  }
}
