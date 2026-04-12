import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/dio_client.dart';
import '../data/auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  static const Object _unset = Object();

  final AuthStatus status;
  final String? token;
  final String? userId;
  final String? email;
  final String? rol;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.token,
    this.userId,
    this.email,
    this.rol,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && (token?.isNotEmpty ?? false);
  bool get isInitialized => status != AuthStatus.unknown;

  AuthState copyWith({
    Object? status = _unset,
    Object? token = _unset,
    Object? userId = _unset,
    Object? email = _unset,
    Object? rol = _unset,
    Object? isLoading = _unset,
    Object? error = _unset,
  }) {
    return AuthState(
      status: identical(status, _unset) ? this.status : status as AuthStatus,
      token: identical(token, _unset) ? this.token : token as String?,
      userId: identical(userId, _unset) ? this.userId : userId as String?,
      email: identical(email, _unset) ? this.email : email as String?,
      rol: identical(rol, _unset) ? this.rol : rol as String?,
      isLoading:
          identical(isLoading, _unset) ? this.isLoading : isLoading as bool,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user_id';
  static const _emailKey = 'auth_email';
  static const _rolKey = 'auth_rol';

  @override
  AuthState build() {
    Future<void>.microtask(_restoreSession);
    return const AuthState(status: AuthStatus.unknown, isLoading: true);
  }

  Future<void> _restoreSession() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null || token.isEmpty) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }

    final userId = await _storage.read(key: _userKey);
    final email = await _storage.read(key: _emailKey);
    final rol = await _storage.read(key: _rolKey);

    state = AuthState(
      status: AuthStatus.authenticated,
      token: token,
      userId: userId,
      email: email,
      rol: rol,
    );
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final previousState = state;
    final repository = ref.read(authRepositoryProvider);

    state = state.copyWith(isLoading: true, error: null);

    try {
      final token = await repository.login(
        email: email.trim(),
        password: password,
      );
      final user = await repository.getMe(token);
      await _persistSession(
        token: token,
        userId: user.id,
        email: user.email,
        rol: user.rol,
      );
    } on AuthException catch (error) {
      state = previousState.copyWith(
        status: previousState.isAuthenticated
            ? previousState.status
            : AuthStatus.unauthenticated,
        isLoading: false,
        error: error.message,
      );
    } catch (_) {
      state = previousState.copyWith(
        status: previousState.isAuthenticated
            ? previousState.status
            : AuthStatus.unauthenticated,
        isLoading: false,
        error: 'No se pudo iniciar sesion. Intenta nuevamente.',
      );
    }
  }

  Future<void> logout() async {
    state = const AuthState(status: AuthStatus.unauthenticated);
    await _deletePersistedSession();
  }

  Future<void> handleUnauthorized() async {
    state = const AuthState(status: AuthStatus.unauthenticated);
    await _deletePersistedSession();
  }

  void clearError() {
    if (state.error == null) {
      return;
    }

    state = state.copyWith(error: null);
  }

  Future<void> _persistSession({
    required String token,
    required String userId,
    required String email,
    required String rol,
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userKey, value: userId);
    await _storage.write(key: _emailKey, value: email);
    await _storage.write(key: _rolKey, value: rol);
    state = AuthState(
      status: AuthStatus.authenticated,
      token: token,
      userId: userId,
      email: email,
      rol: rol,
    );
  }

  Future<void> _deletePersistedSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _rolKey);
  }
}

final appDioProvider = Provider<Dio>((ref) {
  final dio = createDioClient(
    tokenProvider: () async => ref.read(authStateProvider).token,
    onUnauthorized: () =>
        ref.read(authStateProvider.notifier).handleUnauthorized(),
  );
  ref.onDispose(() => dio.close(force: true));
  return dio;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(appDioProvider);
  return AuthRepository(dio);
});

final authStateProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
