import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/auth/app_role.dart';
import '../core/config/app_env.dart';
import '../models/user_model.dart';
import 'permissions_service.dart';
import 'platform_settings_service.dart';

class AuthService extends ChangeNotifier {
  AuthService._();

  static final instance = AuthService._();

  StreamSubscription<AuthState>? _authSubscription;
  UserModel? _currentUser;
  Session? _session;
  bool _isInitializing = true;
  String? _lastError;
  bool _supabaseInitialized = false;
  int _profileLoadVersion = 0;
  LocalStorage? _localStorage;

  UserModel? get currentUser => _currentUser;
  Session? get session => _session;
  bool get isInitializing => _isInitializing;
  bool get isAuthenticated => _session != null;
  String? get lastError => _lastError;
  String? get accessToken => _session?.accessToken;
  bool get isSupabaseConfigured => AppEnv.isSupabaseConfigured;

  Future<void> initialize() async {
    if (_supabaseInitialized) {
      return;
    }

    await dotenv.load(fileName: '.env');
    if (!AppEnv.isSupabaseConfigured) {
      _isInitializing = false;
      notifyListeners();
      return;
    }

    _localStorage = SharedPreferencesLocalStorage(
      persistSessionKey: _persistSessionKey,
    );

    await Supabase.initialize(
      url: AppEnv.supabaseUrl,
      anonKey: AppEnv.supabaseAnonKey,
      authOptions: FlutterAuthClientOptions(localStorage: _localStorage),
    );

    _supabaseInitialized = true;
    _session = Supabase.instance.client.auth.currentSession;
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      event,
    ) async {
      try {
        final session = event.session;
        final loadVersion = ++_profileLoadVersion;
        _session = session;
        if (session == null) {
          _currentUser = null;
          _lastError = null;
          _isInitializing = false;
          notifyListeners();
          return;
        }

        await _loadCurrentProfile(session, loadVersion);
      } catch (error) {
        _lastError = error.toString();
        _isInitializing = false;
        notifyListeners();
      }
    });

    if (_session != null) {
      await _loadCurrentProfile(_session!, ++_profileLoadVersion);
    } else {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required AppRole role,
  }) async {
    _lastError = null;
    notifyListeners();

    try {
      final platformSettings =
          await PlatformSettingsService.instance.getPublicSettings();
      if (!platformSettings.landingPageRegistration) {
        throw const AuthException(
          PlatformSettingsService.publicRegistrationDisabledMessage,
        );
      }
      final passwordError = PlatformSettingsService.instance
          .strongPasswordError(password, platformSettings);
      if (passwordError != null) {
        throw AuthException(passwordError);
      }

      final registrationPermissions = await PermissionsService.instance
          .getPublicRegistrationPermissions();
      if (role == AppRole.student && !registrationPermissions.student) {
        throw AuthException(
          'Student registration is currently disabled.',
        );
      }
      if (role == AppRole.instructor && !registrationPermissions.instructor) {
        throw AuthException(
          'Instructor registration is currently disabled.',
        );
      }
      final response = await Supabase.instance.client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': fullName.trim(), 'role': role.value},
      );

      _session = response.session;
      if (_session != null) {
        await _loadCurrentProfile(_session!, ++_profileLoadVersion);
      } else {
        _isInitializing = false;
        notifyListeners();
      }
    } on AuthException catch (error) {
      _lastError = error.message;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> login({required String email, required String password}) async {
    _lastError = null;
    notifyListeners();

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      _session = response.session;
      if (_session != null) {
        await _loadCurrentProfile(_session!, ++_profileLoadVersion);
      }
    } on AuthException catch (error) {
      _lastError = error.message;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    _profileLoadVersion++;
    _session = null;
    _currentUser = null;
    _isInitializing = false;
    _lastError = null;
    notifyListeners();

    if (!_supabaseInitialized) {
      return;
    }

    unawaited(_removePersistedSession());
  }

  Future<void> _removePersistedSession() async {
    try {
      await _localStorage?.removePersistedSession();
    } catch (error) {
      _lastError = error.toString();
      notifyListeners();
    }
  }

  bool hasRole(AppRole role) {
    return _currentUser?.role == role;
  }

  bool hasAnyRole(List<AppRole> roles) {
    final userRole = _currentUser?.role;
    if (userRole == null) {
      return false;
    }
    return roles.contains(userRole);
  }

  Future<void> reloadProfile() async {
    final session = _session;
    if (session == null) {
      return;
    }
    await _loadCurrentProfile(session, ++_profileLoadVersion);
  }

  Future<void> _loadCurrentProfile(Session session, int loadVersion) async {
    if (loadVersion != _profileLoadVersion) {
      return;
    }

    _isInitializing = true;
    notifyListeners();

    try {
      final userId = session.user.id;
      final platformSettings =
          await PlatformSettingsService.instance.getEffectiveSettings();
      if (PlatformSettingsService.instance.sessionWasInvalidated(
        accessToken: session.accessToken,
        invalidatedAt: platformSettings.platformSessionInvalidatedAt,
      )) {
        await logout();
        _lastError = PlatformSettingsService.forceLogoutMessage;
        notifyListeners();
        return;
      }

      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      if (loadVersion != _profileLoadVersion ||
          _session?.user.id != session.user.id) {
        return;
      }
      _currentUser = UserModel.fromJson(Map<String, dynamic>.from(response));
    } on PostgrestException catch (error) {
      if (loadVersion == _profileLoadVersion) {
        _lastError = error.message;
      }
    } catch (error) {
      if (loadVersion == _profileLoadVersion) {
        _lastError = error.toString();
      }
    } finally {
      if (loadVersion == _profileLoadVersion) {
        _isInitializing = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  String get _persistSessionKey {
    final host = Uri.parse(AppEnv.supabaseUrl).host.split('.').first;
    return 'sb-$host-auth-token';
  }
}
