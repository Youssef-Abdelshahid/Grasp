enum AppRole {
  student('student'),
  instructor('instructor'),
  admin('admin');

  const AppRole(this.value);

  final String value;

  static AppRole fromValue(String value) {
    return AppRole.values.firstWhere(
      (role) => role.value == value.toLowerCase(),
      orElse: () => AppRole.student,
    );
  }

  String get label {
    switch (this) {
      case AppRole.student:
        return 'Student';
      case AppRole.instructor:
        return 'Instructor';
      case AppRole.admin:
        return 'Admin';
    }
  }
}
