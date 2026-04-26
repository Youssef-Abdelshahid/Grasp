import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/auth/app_role.dart';
import '../core/config/app_env.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  AuthService._();

  static final instance = AuthService._();

  StreamSubscription<AuthState>? _authSubscription;
  UserModel? _currentUser;
  Session? _session;
  bool _isInitializing = true;
  String? _lastError;
  bool _supabaseInitialized = false;

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

    await Supabase.initialize(
      url: AppEnv.supabaseUrl,
      anonKey: AppEnv.supabaseAnonKey,
    );

    _supabaseInitialized = true;
    _session = Supabase.instance.client.auth.currentSession;
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      event,
    ) async {
      _session = event.session;
      if (_session == null) {
        _currentUser = null;
        _lastError = null;
        notifyListeners();
        return;
      }

      await _loadCurrentProfile();
    });

    if (_session != null) {
      await _loadCurrentProfile();
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
      final response = await Supabase.instance.client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': fullName.trim(), 'role': role.value},
      );

      _session = response.session;
      if (_session != null) {
        await _loadCurrentProfile();
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
      await _loadCurrentProfile();
    } on AuthException catch (error) {
      _lastError = error.message;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    if (!_supabaseInitialized) {
      _session = null;
      _currentUser = null;
      notifyListeners();
      return;
    }

    await Supabase.instance.client.auth.signOut();
    _session = null;
    _currentUser = null;
    notifyListeners();
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
    if (_session == null) {
      return;
    }
    await _loadCurrentProfile();
  }

  Future<void> _loadCurrentProfile() async {
    _isInitializing = true;
    notifyListeners();

    try {
      final userId = _session?.user.id;
      if (userId == null) {
        _currentUser = null;
      } else {
        final response = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', userId)
            .single();
        _currentUser = UserModel.fromJson(Map<String, dynamic>.from(response));
      }
    } on PostgrestException catch (error) {
      _lastError = error.message;
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
